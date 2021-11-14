// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/BridgeAdminInterface.sol";
import "./interfaces/BridgePoolInterface.sol";

import "../oracle/interfaces/SkinnyOptimisticOracleInterface.sol";
import "../oracle/interfaces/StoreInterface.sol";
import "../oracle/interfaces/FinderInterface.sol";
import "../oracle/implementation/Constants.sol";

import "../common/implementation/AncillaryData.sol";
import "../common/implementation/Testable.sol";
import "../common/implementation/FixedPoint.sol";
import "../common/implementation/Lockable.sol";
import "../common/implementation/MultiCaller.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface WETH9Like {
    function withdraw(uint256 wad) external;

    function deposit() external payable;
}

/**
 * @notice Contract deployed on L1 that provides methods for "Relayers" to fulfill deposit orders that originated on L2.
 * The Relayers can either post capital to fulfill the deposit (instant relay), or request that the funds are taken out
 * of a passive liquidity provider pool following a challenge period (slow relay). This contract ingests liquidity from
 * passive liquidity providers and returns them claims to withdraw their funds. Liquidity providers are incentivized
 * to post collateral by earning a fee per fulfilled deposit order.
 * @dev A "Deposit" is an order to send capital from L2 to L1, and a "Relay" is a fulfillment attempt of that order.
 */
contract BridgePool is MultiCaller, Testable, BridgePoolInterface, ERC20, Lockable {
    using SafeERC20 for IERC20;
    using FixedPoint for FixedPoint.Unsigned;
    using Address for address;

    // Token that this contract receives as LP deposits.
    IERC20 public override l1Token;

    // Track the total number of relays and uniquely identifies relays.
    uint32 public numberOfRelays;

    // Reserves that are unutilized and withdrawable.
    uint256 public liquidReserves;

    // Reserves currently utilized due to L2-L1 transactions in flight.
    int256 public utilizedReserves;

    // Reserves that are not yet utilized but are pre-allocated for a pending relay.
    uint256 public pendingReserves;

    // True If this pool houses WETH. If the withdrawn token is WETH then unwrap and send ETH when finalizing
    // withdrawal.
    bool public isWethPool;

    // Exponential decay exchange rate to accumulate fees to LPs over time.
    uint64 public lpFeeRatePerSecond;

    // Last timestamp that LP fees were updated.
    uint32 public lastLpFeeUpdate;

    // Store local instances of contract params to save gas relaying.
    uint64 public proposerBondPct;
    uint32 public optimisticOracleLiveness;

    // Store local instance of the reserve currency final fee. This is a gas optimization to not re-call the store.
    uint256 l1TokenFinalFee;

    // Cumulative undistributed LP fees. As fees accumulate, they are subtracted from this number.
    uint256 public undistributedLpFees;

    // Total bond amount held for pending relays. Bonds are released following a successful relay or after a dispute.
    uint256 public bonds;

    // Administrative contract that deployed this contract and also houses all state variables needed to relay deposits.
    BridgeAdminInterface public bridgeAdmin;

    // Store local instances of the contract instances to save gas relaying. Can be sync with the Finder at any time via
    // the syncUmaEcosystemParams() public function.
    StoreInterface public store;
    SkinnyOptimisticOracleInterface public optimisticOracle;

    // DVM price request identifier that is resolved based on the validity of a relay attempt.
    bytes32 public identifier;

    // A Relay represents an attempt to finalize a cross-chain transfer that originated on an L2 DepositBox contract.
    // The flow chart between states is as follows:
    // - Begin at Uninitialized.
    // - When relayDeposit() is called, a new relay is created with state Pending and mapped to the L2 deposit hash.
    // - If the relay is disputed, the RelayData gets deleted and the L2 deposit hash has no relay mapped to it anymore.
    // - The above statements enable state to transfer between the Uninitialized and Pending states.
    // - When settleRelay() is successfully called, the relay state gets set to Finalized and cannot change from there.
    // - It is impossible for a relay to be deleted when in Finalized state (and have its state set to Uninitialized)
    //   because the only way for settleRelay() to succeed is if the price has resolved on the OptimisticOracle.
    // - You cannot dispute an already resolved request on the OptimisticOracle. Moreover, the mapping from
    //   a relay's ancillary data hash to its deposit hash is deleted after a successful settleRelay() call.
    enum RelayState { Uninitialized, Pending, Finalized }

    // Data from L2 deposit transaction.
    struct DepositData {
        uint256 chainId;
        uint64 depositId;
        address payable l1Recipient;
        address l2Sender;
        uint256 amount;
        uint64 slowRelayFeePct;
        uint64 instantRelayFeePct;
        uint32 quoteTimestamp;
    }

    // Each L2 Deposit can have one Relay attempt at any one time. A Relay attempt is characterized by its RelayData.
    struct RelayData {
        RelayState relayState;
        address slowRelayer;
        uint32 relayId;
        uint64 realizedLpFeePct;
        uint32 priceRequestTime;
        uint256 proposerBond;
        uint256 finalFee;
    }

    // Associate deposits with pending relay data. When the mapped relay hash is empty, new relay attempts can be made
    // for this deposit. The relay data contains information necessary to pay out relayers on successful relay.
    // Relay hashes are deleted when they are disputed on the OptimisticOracle.
    mapping(bytes32 => bytes32) public relays;

    // Map hash of deposit and realized-relay fee to instant relayers. This mapping is checked at settlement time
    // to determine if there was a valid instant relayer.
    mapping(bytes32 => address) public instantRelays;

    event LiquidityAdded(uint256 amount, uint256 lpTokensMinted, address indexed liquidityProvider);
    event LiquidityRemoved(uint256 amount, uint256 lpTokensBurnt, address indexed liquidityProvider);
    event DepositRelayed(
        bytes32 indexed depositHash,
        DepositData depositData,
        RelayData relay,
        bytes32 relayAncillaryDataHash
    );
    event RelaySpedUp(bytes32 indexed depositHash, address indexed instantRelayer, RelayData relay);

    // Note: the difference between a dispute and a cancellation is that a cancellation happens in the case where
    // something changes in the OO between request and dispute that causes calls to it to fail. The most common
    // case would be an increase in final fee. However, things like whitelisting can also cause problems.
    event RelayDisputed(bytes32 indexed depositHash, bytes32 indexed relayHash, address indexed disputer);
    event RelayCanceled(bytes32 indexed depositHash, bytes32 indexed relayHash, address indexed disputer);
    event RelaySettled(bytes32 indexed depositHash, address indexed caller, RelayData relay);
    event BridgePoolAdminTransferred(address oldAdmin, address newAdmin);

    /**
     * @notice Construct the Bridge Pool.
     * @param _lpTokenName Name of the LP token to be deployed by this contract.
     * @param _lpTokenSymbol Symbol of the LP token to be deployed by this contract.
     * @param _bridgeAdmin Admin contract deployed alongside on L1. Stores global variables and has owner control.
     * @param _l1Token Address of the L1 token that this bridgePool holds. This is the token LPs deposit and is bridged.
     * @param _lpFeeRatePerSecond Interest rate payment that scales the amount of pending fees per second paid to LPs.
     * @param _isWethPool Toggles if this is the WETH pool. If it is then can accept ETH and wrap to WETH for the user.
     * @param _timer Timer used to synchronize contract time in testing. Set to 0x000... in production.
     */
    constructor(
        string memory _lpTokenName,
        string memory _lpTokenSymbol,
        address _bridgeAdmin,
        address _l1Token,
        uint64 _lpFeeRatePerSecond,
        bool _isWethPool,
        address _timer
    ) Testable(_timer) ERC20(_lpTokenName, _lpTokenSymbol) {
        require(bytes(_lpTokenName).length != 0 && bytes(_lpTokenSymbol).length != 0, "Bad LP token name or symbol");
        bridgeAdmin = BridgeAdminInterface(_bridgeAdmin);
        l1Token = IERC20(_l1Token);
        lastLpFeeUpdate = uint32(getCurrentTime());
        lpFeeRatePerSecond = _lpFeeRatePerSecond;
        isWethPool = _isWethPool;

        syncUmaEcosystemParams(); // Fetch OptimisticOracle and Store addresses and L1Token finalFee.
        syncWithBridgeAdminParams(); // Fetch ProposerBondPct OptimisticOracleLiveness, Identifier from the BridgeAdmin.
    }

    /*************************************************
     *          LIQUIDITY PROVIDER FUNCTIONS         *
     *************************************************/

    /**
     * @notice Add liquidity to the bridge pool. Pulls l1Token from the caller's wallet. The caller is sent back a
     * commensurate number of LP tokens (minted to their address) at the prevailing exchange rate.
     * @dev The caller must approve this contract to transfer `l1TokenAmount` amount of l1Token if depositing ERC20.
     * @dev The caller can deposit ETH which is auto wrapped to WETH. This can only be done if: a) this is the Weth pool
     * and b) the l1TokenAmount matches to the transaction msg.value.
     * @dev Reentrancy guard not added to this function because this indirectly calls sync() which is guarded.
     * @param l1TokenAmount Number of l1Token to add as liquidity.
     */
    function addLiquidity(uint256 l1TokenAmount) public payable nonReentrant() {
        // If this is the weth pool and the caller sends msg.value then the msg.value must match the l1TokenAmount.
        // Else, msg.value must be set to 0.
        require((isWethPool && msg.value == l1TokenAmount) || msg.value == 0, "Bad add liquidity Eth value");

        // Since `exchangeRateCurrent()` reads this contract's balance and updates contract state using it,
        // we must call it first before transferring any tokens to this contract.
        uint256 lpTokensToMint = (l1TokenAmount * 1e18) / _exchangeRateCurrent();
        _mint(msg.sender, lpTokensToMint);
        liquidReserves += l1TokenAmount;

        if (msg.value > 0 && isWethPool) WETH9Like(address(l1Token)).deposit{ value: msg.value }();
        else l1Token.safeTransferFrom(msg.sender, address(this), l1TokenAmount);

        emit LiquidityAdded(l1TokenAmount, lpTokensToMint, msg.sender);
    }

    /**
     * @notice Removes liquidity from the bridge pool. Burns lpTokenAmount LP tokens from the caller's wallet. The caller
     * is sent back a commensurate number of l1Tokens at the prevailing exchange rate.
     * @dev The caller does not need to approve the spending of LP tokens as this method directly uses the burn logic.
     * @dev Reentrancy guard not added to this function because this indirectly calls sync() which is guarded.
     * @param lpTokenAmount Number of lpTokens to redeem for underlying.
     * @param sendEth Enable the liquidity provider to remove liquidity in ETH, if this is the WETH pool.
     */
    function removeLiquidity(uint256 lpTokenAmount, bool sendEth) public nonReentrant() {
        // Can only send eth on withdrawing liquidity iff this is the WETH pool.
        require(!sendEth || isWethPool, "Cant send eth");
        uint256 l1TokensToReturn = (lpTokenAmount * _exchangeRateCurrent()) / 1e18;

        // Check that there is enough liquid reserves to withdraw the requested amount.
        require(liquidReserves >= (pendingReserves + l1TokensToReturn), "Utilization too high to remove");

        _burn(msg.sender, lpTokenAmount);
        liquidReserves -= l1TokensToReturn;

        if (sendEth) _unwrapWETHTo(payable(msg.sender), l1TokensToReturn);
        else l1Token.safeTransfer(msg.sender, l1TokensToReturn);

        emit LiquidityRemoved(l1TokensToReturn, lpTokenAmount, msg.sender);
    }

    /**************************************
     *          RELAYER FUNCTIONS         *
     **************************************/

    /**
     * @notice Called by Relayer to execute a slow + fast relay from L2 to L1, fulfilling a corresponding deposit order.
     * @dev There can only be one pending relay for a deposit. This method is effectively the relayDeposit and
     * speedUpRelay methods concatenated. This could be refactored to just call each method, but there
     * are some gas savings in combining the transfers and hash computations.
     * @dev Caller must have approved this contract to spend the total bond + amount - fees for `l1Token`.
     * @param depositData the deposit data struct containing all the user's deposit information.
     * @param realizedLpFeePct LP fee calculated off-chain considering the L1 pool liquidity at deposit time, before
     *      quoteTimestamp. The OO acts to verify the correctness of this realized fee. Cannot exceed 50%.
     */
    function relayAndSpeedUp(DepositData memory depositData, uint64 realizedLpFeePct) public nonReentrant() {
        // If no pending relay for this deposit, then associate the caller's relay attempt with it.
        uint32 priceRequestTime = uint32(getCurrentTime());

        // The realizedLPFeePct should never be greater than 0.5e18 and the slow and instant relay fees should never be
        // more than 0.25e18 each. Therefore, the sum of all fee types can never exceed 1e18 (or 100%).
        require(
            depositData.slowRelayFeePct <= 0.25e18 &&
                depositData.instantRelayFeePct <= 0.25e18 &&
                realizedLpFeePct <= 0.5e18,
            "Invalid fees"
        );

        // Check if there is a pending relay for this deposit.
        bytes32 depositHash = _getDepositHash(depositData);

        // Note: A disputed relay deletes the stored relay hash and enables this require statement to pass.
        require(relays[depositHash] == bytes32(0), "Pending relay exists");

        uint256 proposerBond = _getProposerBond(depositData.amount);

        // Save hash of new relay attempt parameters.
        // Note: The liveness for this relay can be changed in the BridgeAdmin, which means that each relay has a
        // potentially variable liveness time. This should not provide any exploit opportunities, especially because
        // the BridgeAdmin state (including the liveness value) is permissioned to the cross domained owner.
        RelayData memory relayData =
            RelayData({
                relayState: RelayState.Pending,
                slowRelayer: msg.sender,
                relayId: numberOfRelays++, // Note: Increment numberOfRelays at the same time as setting relayId to its current value.
                realizedLpFeePct: realizedLpFeePct,
                priceRequestTime: priceRequestTime,
                proposerBond: proposerBond,
                finalFee: l1TokenFinalFee
            });
        bytes32 relayHash = _getRelayHash(depositData, relayData);
        relays[depositHash] = _getRelayDataHash(relayData);

        bytes32 instantRelayHash = _getInstantRelayHash(depositHash, relayData);
        require(
            // Can only speed up a pending relay without an existing instant relay associated with it.
            instantRelays[instantRelayHash] == address(0),
            "Relay cannot be sped up"
        );

        // Sanity check that pool has enough balance to cover relay amount + proposer reward. Reward amount will be
        // paid on settlement after the OptimisticOracle price request has passed the challenge period.
        // Note: liquidReserves should always be <= balance - bonds.
        require(liquidReserves - pendingReserves >= depositData.amount, "Insufficient pool balance");

        // Compute total proposal bond and pull from caller so that the OptimisticOracle can pull it from here.
        uint256 totalBond = proposerBond + l1TokenFinalFee;

        // Pull relay amount minus fees from caller and send to the deposit l1Recipient. The total fees paid is the sum
        // of the LP fees, the relayer fees and the instant relay fee.
        uint256 feesTotal =
            _getAmountFromPct(
                relayData.realizedLpFeePct + depositData.slowRelayFeePct + depositData.instantRelayFeePct,
                depositData.amount
            );
        // If the L1 token is WETH then: a) pull WETH from instant relayer b) unwrap WETH c) send ETH to recipient.
        uint256 recipientAmount = depositData.amount - feesTotal;

        bonds += totalBond;
        pendingReserves += depositData.amount; // Book off maximum liquidity used by this relay in the pending reserves.

        instantRelays[instantRelayHash] = msg.sender;

        l1Token.safeTransferFrom(msg.sender, address(this), recipientAmount + totalBond);

        // If this is a weth pool then unwrap and send eth.
        if (isWethPool) {
            _unwrapWETHTo(depositData.l1Recipient, recipientAmount);
            // Else, this is a normal ERC20 token. Send to recipient.
        } else l1Token.safeTransfer(depositData.l1Recipient, recipientAmount);

        emit DepositRelayed(depositHash, depositData, relayData, relayHash);
        emit RelaySpedUp(depositHash, msg.sender, relayData);
    }

    /**
     * @notice Called by Disputer to dispute an ongoing relay.
     * @dev The result of this method is to always throw out the relay, providing an opportunity for another relay for
     * the same deposit. Between the disputer and proposer, whoever is incorrect loses their bond. Whoever is correct
     * gets it back + a payout.
     * @dev Caller must have approved this contract to spend the total bond + amount - fees for `l1Token`.
     * @param depositData the deposit data struct containing all the user's deposit information.
     * @param relayData RelayData logged in the disputed relay.
     */
    function disputeRelay(DepositData memory depositData, RelayData memory relayData) public nonReentrant() {
        require(relayData.priceRequestTime + optimisticOracleLiveness > getCurrentTime(), "Past liveness");
        require(relayData.relayState == RelayState.Pending, "Not disputable");
        // Validate the input data.
        bytes32 depositHash = _getDepositHash(depositData);
        _validateRelayDataHash(depositHash, relayData);

        // Submit the proposal and dispute to the OO.
        bytes32 relayHash = _getRelayHash(depositData, relayData);

        // Note: in some cases this will fail due to changes in the OO and the method will refund the relayer.
        bool success =
            _requestProposeDispute(
                relayData.slowRelayer,
                msg.sender,
                relayData.proposerBond,
                relayData.finalFee,
                _getRelayAncillaryData(relayHash)
            );

        // Drop the relay and remove the bond from the tracked bonds.
        bonds -= relayData.finalFee + relayData.proposerBond;
        pendingReserves -= depositData.amount;
        delete relays[depositHash];
        if (success) emit RelayDisputed(depositHash, _getRelayDataHash(relayData), msg.sender);
        else emit RelayCanceled(depositHash, _getRelayDataHash(relayData), msg.sender);
    }

    /**
     * @notice Called by Relayer to execute a slow relay from L2 to L1, fulfilling a corresponding deposit order.
     * @dev There can only be one pending relay for a deposit.
     * @dev Caller must have approved this contract to spend the total bond + amount - fees for `l1Token`.
     * @param depositData the deposit data struct containing all the user's deposit information.
     * @param realizedLpFeePct LP fee calculated off-chain considering the L1 pool liquidity at deposit time, before
     *      quoteTimestamp. The OO acts to verify the correctness of this realized fee. Cannot exceed 50%.
     */
    function relayDeposit(DepositData memory depositData, uint64 realizedLpFeePct) public nonReentrant() {
        // The realizedLPFeePct should never be greater than 0.5e18 and the slow and instant relay fees should never be
        // more than 0.25e18 each. Therefore, the sum of all fee types can never exceed 1e18 (or 100%).
        require(
            depositData.slowRelayFeePct <= 0.25e18 &&
                depositData.instantRelayFeePct <= 0.25e18 &&
                realizedLpFeePct <= 0.5e18,
            "Invalid fees"
        );

        // Check if there is a pending relay for this deposit.
        bytes32 depositHash = _getDepositHash(depositData);

        // Note: A disputed relay deletes the stored relay hash and enables this require statement to pass.
        require(relays[depositHash] == bytes32(0), "Pending relay exists");

        // If no pending relay for this deposit, then associate the caller's relay attempt with it.
        uint32 priceRequestTime = uint32(getCurrentTime());

        uint256 proposerBond = _getProposerBond(depositData.amount);

        // Save hash of new relay attempt parameters.
        // Note: The liveness for this relay can be changed in the BridgeAdmin, which means that each relay has a
        // potentially variable liveness time. This should not provide any exploit opportunities, especially because
        // the BridgeAdmin state (including the liveness value) is permissioned to the cross domained owner.
        RelayData memory relayData =
            RelayData({
                relayState: RelayState.Pending,
                slowRelayer: msg.sender,
                relayId: numberOfRelays++, // Note: Increment numberOfRelays at the same time as setting relayId to its current value.
                realizedLpFeePct: realizedLpFeePct,
                priceRequestTime: priceRequestTime,
                proposerBond: proposerBond,
                finalFee: l1TokenFinalFee
            });
        relays[depositHash] = _getRelayDataHash(relayData);

        bytes32 relayHash = _getRelayHash(depositData, relayData);

        // Sanity check that pool has enough balance to cover relay amount + proposer reward. Reward amount will be
        // paid on settlement after the OptimisticOracle price request has passed the challenge period.
        // Note: liquidReserves should always be <= balance - bonds.
        require(liquidReserves - pendingReserves >= depositData.amount, "Insufficient pool balance");

        // Compute total proposal bond and pull from caller so that the OptimisticOracle can pull it from here.
        uint256 totalBond = proposerBond + l1TokenFinalFee;
        pendingReserves += depositData.amount; // Book off maximum liquidity used by this relay in the pending reserves.
        bonds += totalBond;

        l1Token.safeTransferFrom(msg.sender, address(this), totalBond);
        emit DepositRelayed(depositHash, depositData, relayData, relayHash);
    }

    /**
     * @notice Instantly relay a deposit amount minus fees to the l1Recipient. Instant relayer earns a reward following
     * the pending relay challenge period.
     * @dev We assume that the caller has performed an off-chain check that the deposit data they are attempting to
     * relay is valid. If the deposit data is invalid, then the instant relayer has no recourse to receive their funds
     * back after the invalid deposit data is disputed. Moreover, no one will be able to resubmit a relay for the
     * invalid deposit data because they know it will get disputed again. On the other hand, if the deposit data is
     * valid, then even if it is falsely disputed, the instant relayer will eventually get reimbursed because someone
     * else will be incentivized to resubmit the relay to earn slow relayer rewards. Once the valid relay is finalized,
     * the instant relayer will be reimbursed. Therefore, the caller has the same responsibility as the disputer in
     * validating the relay data.
     * @dev Caller must have approved this contract to spend the deposit amount of L1 tokens to relay. There can only
     * be one instant relayer per relay attempt. You cannot speed up a relay that is past liveness.
     * @param depositData Unique set of L2 deposit data that caller is trying to instantly relay.
     * @param relayData Parameters of Relay that caller is attempting to speedup. Must hash to the stored relay hash
     * for this deposit or this method will revert.
     */
    function speedUpRelay(DepositData memory depositData, RelayData memory relayData) public nonReentrant() {
        bytes32 depositHash = _getDepositHash(depositData);
        _validateRelayDataHash(depositHash, relayData);
        bytes32 instantRelayHash = _getInstantRelayHash(depositHash, relayData);
        require(
            // Can only speed up a pending relay without an existing instant relay associated with it.
            getCurrentTime() < relayData.priceRequestTime + optimisticOracleLiveness &&
                relayData.relayState == RelayState.Pending &&
                instantRelays[instantRelayHash] == address(0),
            "Relay cannot be sped up"
        );
        instantRelays[instantRelayHash] = msg.sender;

        // Pull relay amount minus fees from caller and send to the deposit l1Recipient. The total fees paid is the sum
        // of the LP fees, the relayer fees and the instant relay fee.
        uint256 feesTotal =
            _getAmountFromPct(
                relayData.realizedLpFeePct + depositData.slowRelayFeePct + depositData.instantRelayFeePct,
                depositData.amount
            );
        // If the L1 token is WETH then: a) pull WETH from instant relayer b) unwrap WETH c) send ETH to recipient.
        uint256 recipientAmount = depositData.amount - feesTotal;
        if (isWethPool) {
            l1Token.safeTransferFrom(msg.sender, address(this), recipientAmount);
            _unwrapWETHTo(depositData.l1Recipient, recipientAmount);
            // Else, this is a normal ERC20 token. Send to recipient.
        } else l1Token.safeTransferFrom(msg.sender, depositData.l1Recipient, recipientAmount);

        emit RelaySpedUp(depositHash, msg.sender, relayData);
    }

    /**
     * @notice Reward relayers if a pending relay price request has a price available on the OptimisticOracle. Mark
     * the relay as complete.
     * @dev We use the relayData and depositData to compute the ancillary data that the relay price request is uniquely
     * associated with on the OptimisticOracle. If the price request passed in does not match the pending relay price
     * request, then this will revert.
     * @param depositData Unique set of L2 deposit data that caller is trying to settle a relay for.
     * @param relayData Parameters of Relay that caller is attempting to settle. Must hash to the stored relay hash
     * for this deposit.
     */
    function settleRelay(DepositData memory depositData, RelayData memory relayData) public nonReentrant() {
        bytes32 depositHash = _getDepositHash(depositData);
        _validateRelayDataHash(depositHash, relayData);
        require(relayData.relayState == RelayState.Pending, "Already settled");
        uint32 expirationTime = relayData.priceRequestTime + optimisticOracleLiveness;
        require(expirationTime <= getCurrentTime(), "Not settleable yet");

        // Note: this check is to give the relayer a small, but reasonable amount of time to complete the relay before
        // before it can be "stolen" by someone else. This is to ensure there is an incentive to settle relays quickly.
        require(
            msg.sender == relayData.slowRelayer || getCurrentTime() > expirationTime + 15 minutes,
            "Not slow relayer"
        );

        // Update the relay state to Finalized. This prevents any re-settling of a relay.
        relays[depositHash] = _getRelayDataHash(
            RelayData({
                relayState: RelayState.Finalized,
                slowRelayer: relayData.slowRelayer,
                relayId: relayData.relayId,
                realizedLpFeePct: relayData.realizedLpFeePct,
                priceRequestTime: relayData.priceRequestTime,
                proposerBond: relayData.proposerBond,
                finalFee: relayData.finalFee
            })
        );

        // Reward relayers and pay out l1Recipient.
        // At this point there are two possible cases:
        // - This was a slow relay: In this case, a) pay the slow relayer their reward and b) pay the l1Recipient of the
        //      amount minus the realized LP fee and the slow Relay fee. The transfer was not sped up so no instant fee.
        // - This was an instant relay: In this case, a) pay the slow relayer their reward and b) pay the instant relayer
        //      the full bridging amount, minus the realized LP fee and minus the slow relay fee. When the instant
        //      relayer called speedUpRelay they were docked this same amount, minus the instant relayer fee. As a
        //      result, they are effectively paid what they spent when speeding up the relay + the instantRelayFee.

        uint256 instantRelayerOrRecipientAmount =
            depositData.amount -
                _getAmountFromPct(relayData.realizedLpFeePct + depositData.slowRelayFeePct, depositData.amount);

        // Refund the instant relayer iff the instant relay params match the approved relay.
        bytes32 instantRelayHash = _getInstantRelayHash(depositHash, relayData);
        address instantRelayer = instantRelays[instantRelayHash];

        // If this is the WETH pool and the instant relayer is is address 0x0 (i.e the relay was not sped up) then:
        // a) withdraw WETH to ETH and b) send the ETH to the recipient.
        if (isWethPool && instantRelayer == address(0)) {
            _unwrapWETHTo(depositData.l1Recipient, instantRelayerOrRecipientAmount);
            // Else, this is a normal slow relay being finalizes where the contract sends ERC20 to the recipient OR this
            // is the finalization of an instant relay where we need to reimburse the instant relayer in WETH.
        } else
            l1Token.safeTransfer(
                instantRelayer != address(0) ? instantRelayer : depositData.l1Recipient,
                instantRelayerOrRecipientAmount
            );

        // There is a fee and a bond to pay out. The fee goes to whoever settles. The bond always goes back to the
        // slow relayer.
        // Note: for gas efficiency, we use an if so we can combine these transfers in the event that they are the same
        // address.
        uint256 slowRelayerReward = _getAmountFromPct(depositData.slowRelayFeePct, depositData.amount);
        uint256 totalBond = relayData.finalFee + relayData.proposerBond;
        if (relayData.slowRelayer == msg.sender)
            l1Token.safeTransfer(relayData.slowRelayer, slowRelayerReward + totalBond);
        else {
            l1Token.safeTransfer(relayData.slowRelayer, totalBond);
            l1Token.safeTransfer(msg.sender, slowRelayerReward);
        }

        uint256 totalReservesSent = instantRelayerOrRecipientAmount + slowRelayerReward;

        // Update reserves by amounts changed and allocated LP fees.
        pendingReserves -= depositData.amount;
        liquidReserves -= totalReservesSent;
        utilizedReserves += int256(totalReservesSent);
        bonds -= totalBond;
        _updateAccumulatedLpFees();
        _allocateLpFees(_getAmountFromPct(relayData.realizedLpFeePct, depositData.amount));

        emit RelaySettled(depositHash, msg.sender, relayData);

        // Clean up state storage and receive gas refund. This also prevents `priceDisputed()` from being able to reset
        // this newly Finalized relay state.
        delete instantRelays[instantRelayHash];
    }

    /**
     * @notice Synchronize any balance changes in this contract with the utilized & liquid reserves. This would be done
     * at the conclusion of an L2 -> L1 token transfer via the canonical token bridge.
     */
    function sync() public nonReentrant() {
        _sync();
    }

    /**
     * @notice Computes the exchange rate between LP tokens and L1Tokens. Used when adding/removing liquidity.
     * @return The updated exchange rate between LP tokens and L1 tokens.
     */
    function exchangeRateCurrent() public nonReentrant() returns (uint256) {
        return _exchangeRateCurrent();
    }

    /**
     * @notice Computes the current liquidity utilization ratio.
     * @dev Used in computing realizedLpFeePct off-chain.
     * @return The current utilization ratio.
     */
    function liquidityUtilizationCurrent() public nonReentrant() returns (uint256) {
        return _liquidityUtilizationPostRelay(0);
    }

    /**
     * @notice Computes the liquidity utilization ratio post a relay of known size.
     * @dev Used in computing realizedLpFeePct off-chain.
     * @param relayedAmount Size of the relayed deposit to factor into the utilization calculation.
     * @return The updated utilization ratio accounting for a new `relayedAmount`.
     */
    function liquidityUtilizationPostRelay(uint256 relayedAmount) public nonReentrant() returns (uint256) {
        return _liquidityUtilizationPostRelay(relayedAmount);
    }

    /**
     * @notice Return both the current utilization value and liquidity utilization post the relay.
     * @dev Used in computing realizedLpFeePct off-chain.
     * @param relayedAmount Size of the relayed deposit to factor into the utilization calculation.
     * @return utilizationCurrent The current utilization ratio.
     * @return utilizationPostRelay The updated utilization ratio accounting for a new `relayedAmount`.
     */
    function getLiquidityUtilization(uint256 relayedAmount)
        public
        nonReentrant()
        returns (uint256 utilizationCurrent, uint256 utilizationPostRelay)
    {
        return (_liquidityUtilizationPostRelay(0), _liquidityUtilizationPostRelay(relayedAmount));
    }

    /**
     * @notice Updates the address stored in this contract for the OptimisticOracle and the Store to the latest versions
     * set in the the Finder. Also pull finalFee Store these as local variables to make relay methods gas efficient.
     * @dev There is no risk of leaving this function public for anyone to call as in all cases we want the addresses
     * in this contract to map to the latest version in the Finder and store the latest final fee.
     */
    function syncUmaEcosystemParams() public nonReentrant() {
        FinderInterface finder = FinderInterface(bridgeAdmin.finder());
        optimisticOracle = SkinnyOptimisticOracleInterface(
            finder.getImplementationAddress(OracleInterfaces.SkinnyOptimisticOracle)
        );

        store = StoreInterface(finder.getImplementationAddress(OracleInterfaces.Store));
        l1TokenFinalFee = store.computeFinalFee(address(l1Token)).rawValue;
    }

    /**
     * @notice Updates the values of stored constants for the proposerBondPct, optimisticOracleLiveness and identifier
     * to that set in the bridge Admin. We store these as local variables to make the relay methods more gas efficient.
     * @dev There is no risk of leaving this function public for anyone to call as in all cases we want these values
     * in this contract to map to the latest version set in the BridgeAdmin.
     */
    function syncWithBridgeAdminParams() public nonReentrant() {
        proposerBondPct = bridgeAdmin.proposerBondPct();
        optimisticOracleLiveness = bridgeAdmin.optimisticOracleLiveness();
        identifier = bridgeAdmin.identifier();
    }

    /************************************
     *          ADMIN FUNCTIONS         *
     ************************************/

    /**
     * @notice Enable the current bridge admin to transfer admin to to a new address.
     * @param _newAdmin Admin address of the new admin.
     */
    function changeAdmin(address _newAdmin) public override nonReentrant() {
        require(msg.sender == address(bridgeAdmin));
        bridgeAdmin = BridgeAdminInterface(_newAdmin);
        emit BridgePoolAdminTransferred(msg.sender, _newAdmin);
    }

    /************************************
     *           VIEW FUNCTIONS         *
     ************************************/

    /**
     * @notice Computes the current amount of unallocated fees that have accumulated from the previous time this the
     * contract was called.
     */
    function getAccumulatedFees() public view nonReentrantView() returns (uint256) {
        return _getAccumulatedFees();
    }

    /**
     * @notice Returns ancillary data containing all relevant Relay data that voters can format into UTF8 and use to
     * determine if the relay is valid.
     * @dev Helpful method to test that ancillary data is constructed properly. We should consider removing if we don't
     * anticipate off-chain bots or users to call this method.
     * @param depositData Contains L2 deposit information used by off-chain validators to validate relay.
     * @param relayData Contains relay information used by off-chain validators to validate relay.
     * @return bytes New ancillary data that can be decoded into UTF8.
     */
    function getRelayAncillaryData(DepositData memory depositData, RelayData memory relayData)
        public
        view
        nonReentrantView()
        returns (bytes memory)
    {
        return _getRelayAncillaryData(_getRelayHash(depositData, relayData));
    }

    /**************************************
     *    INTERNAL & PRIVATE FUNCTIONS    *
     **************************************/

    function _liquidityUtilizationPostRelay(uint256 relayedAmount) internal returns (uint256) {
        _sync(); // Fetch any balance changes due to token bridging finalization and factor them in.

        // liquidityUtilizationRatio :=
        // (relayedAmount + pendingReserves + max(utilizedReserves,0)) / (liquidReserves + max(utilizedReserves,0))
        // UtilizedReserves has a dual meaning: if it's greater than zero then it represents funds pending in the bridge
        // that will flow from L2 to L1. In this case, we can use it normally in the equation. However, if it is
        // negative, then it is already counted in liquidReserves. This occurs if tokens are transferred directly to the
        // contract. In this case, ignore it as it is captured in liquid reserves and has no meaning in the numerator.
        uint256 flooredUtilizedReserves = utilizedReserves > 0 ? uint256(utilizedReserves) : 0;
        uint256 numerator = relayedAmount + pendingReserves + flooredUtilizedReserves;
        uint256 denominator = liquidReserves + flooredUtilizedReserves;

        // If the denominator equals zero, return 1e18 (max utilization).
        if (denominator == 0) return 1e18;

        // In all other cases, return the utilization ratio.
        return (numerator * 1e18) / denominator;
    }

    function _sync() internal {
        // Check if the l1Token balance of the contract is greater than the liquidReserves. If it is then the bridging
        // action from L2 -> L1 has concluded and the local accounting can be updated.
        uint256 l1TokenBalance = l1Token.balanceOf(address(this)) - bonds;
        if (l1TokenBalance > liquidReserves) {
            // utilizedReserves can go to less than zero. This will happen if the accumulated fees exceeds the current
            // outstanding utilization. In other words, if outstanding bridging transfers are 0 then utilizedReserves
            // will equal the total LP fees accumulated over all time.
            utilizedReserves -= int256(l1TokenBalance - liquidReserves);
            liquidReserves = l1TokenBalance;
        }
    }

    function _exchangeRateCurrent() internal returns (uint256) {
        if (totalSupply() == 0) return 1e18; // initial rate is 1 pre any mint action.

        // First, update fee counters and local accounting of finalized transfers from L2 -> L1.
        _updateAccumulatedLpFees(); // Accumulate all allocated fees from the last time this method was called.
        _sync(); // Fetch any balance changes due to token bridging finalization and factor them in.

        // ExchangeRate := (liquidReserves + utilizedReserves - undistributedLpFees) / lpTokenSupply
        uint256 numerator = liquidReserves - undistributedLpFees;
        if (utilizedReserves > 0) numerator += uint256(utilizedReserves);
        else numerator -= uint256(utilizedReserves * -1);
        return (numerator * 1e18) / totalSupply();
    }

    // Return UTF8-decodable ancillary data for relay price request associated with relay hash.
    function _getRelayAncillaryData(bytes32 relayHash) private pure returns (bytes memory) {
        return AncillaryData.appendKeyValueBytes32("", "relayHash", relayHash);
    }

    // Returns hash of unique relay and deposit event. This is added to the relay request's ancillary data.
    function _getRelayHash(DepositData memory depositData, RelayData memory relayData) private view returns (bytes32) {
        return keccak256(abi.encode(depositData, relayData.relayId, relayData.realizedLpFeePct, address(l1Token)));
    }

    // Return hash of relay data, which is stored in state and mapped to a deposit hash.
    function _getRelayDataHash(RelayData memory relayData) private pure returns (bytes32) {
        return keccak256(abi.encode(relayData));
    }

    // Reverts if the stored relay data hash for `depositHash` does not match `_relayData`.
    function _validateRelayDataHash(bytes32 depositHash, RelayData memory relayData) private view {
        require(
            relays[depositHash] == _getRelayDataHash(relayData),
            "Hashed relay params do not match existing relay hash for deposit"
        );
    }

    // Return hash of unique instant relay and deposit event. This is stored in state and mapped to a deposit hash.
    function _getInstantRelayHash(bytes32 depositHash, RelayData memory relayData) private pure returns (bytes32) {
        // Only include parameters that affect the "correctness" of an instant relay. For example, the realized LP fee
        // % directly affects how many tokens the instant relayer needs to send to the user, whereas the address of the
        // instant relayer does not matter for determining whether an instant relay is "correct".
        return keccak256(abi.encode(depositHash, relayData.realizedLpFeePct));
    }

    function _getAccumulatedFees() internal view returns (uint256) {
        // UnallocatedLpFees := min(undistributedLpFees*lpFeeRatePerSecond*timeFromLastInteraction,undistributedLpFees)
        // The min acts to pay out all fees in the case the equation returns more than the remaining a fees.
        uint256 possibleUnpaidFees =
            (undistributedLpFees * lpFeeRatePerSecond * (getCurrentTime() - lastLpFeeUpdate)) / (1e18);
        return possibleUnpaidFees < undistributedLpFees ? possibleUnpaidFees : undistributedLpFees;
    }

    // Update internal fee counters by adding in any accumulated fees from the last time this logic was called.
    function _updateAccumulatedLpFees() internal {
        // Calculate the unallocatedAccumulatedFees from the last time the contract was called.
        uint256 unallocatedAccumulatedFees = _getAccumulatedFees();

        // Decrement the undistributedLpFees by the amount of accumulated fees.
        undistributedLpFees = undistributedLpFees - unallocatedAccumulatedFees;

        lastLpFeeUpdate = uint32(getCurrentTime());
    }

    // Allocate fees to the LPs by incrementing counters.
    function _allocateLpFees(uint256 allocatedLpFees) internal {
        // Add to the total undistributed LP fees and the utilized reserves. Adding it to the utilized reserves acts to
        // track the fees while they are in transit.
        undistributedLpFees += allocatedLpFees;
        utilizedReserves += int256(allocatedLpFees);
    }

    function _getAmountFromPct(uint64 percent, uint256 amount) private pure returns (uint256) {
        return (percent * amount) / 1e18;
    }

    function _getProposerBond(uint256 amount) private view returns (uint256) {
        return _getAmountFromPct(proposerBondPct, amount);
    }

    function _getDepositHash(DepositData memory depositData) private view returns (bytes32) {
        return keccak256(abi.encode(depositData, address(l1Token)));
    }

    // Proposes new price of True for relay event associated with `customAncillaryData` to optimistic oracle. If anyone
    // disagrees with the relay parameters and whether they map to an L2 deposit, they can dispute with the oracle.
    function _requestProposeDispute(
        address proposer,
        address disputer,
        uint256 proposerBond,
        uint256 finalFee,
        bytes memory customAncillaryData
    ) private returns (bool) {
        uint256 totalBond = finalFee + proposerBond;
        l1Token.safeApprove(address(optimisticOracle), totalBond);
        try
            optimisticOracle.requestAndProposePriceFor(
                identifier,
                uint32(getCurrentTime()),
                customAncillaryData,
                IERC20(l1Token),
                // Set reward to 0, since we'll settle proposer reward payouts directly from this contract after a relay
                // proposal has passed the challenge period.
                0,
                // Set the Optimistic oracle proposer bond for the price request.
                proposerBond,
                // Set the Optimistic oracle liveness for the price request.
                optimisticOracleLiveness,
                proposer,
                // Canonical value representing "True"; i.e. the proposed relay is valid.
                int256(1e18)
            )
        returns (uint256 bondSpent) {
            if (bondSpent < totalBond) {
                // If the OO pulls less (due to a change in final fee), refund the proposer.
                uint256 refund = totalBond - bondSpent;
                l1Token.safeTransfer(proposer, refund);
                l1Token.safeApprove(address(optimisticOracle), 0);
                totalBond = bondSpent;
            }
        } catch {
            // If there's an error in the OO, this means something has changed to make this request undisputable.
            // To ensure the request does not go through by default, refund the proposer and return early, allowing
            // the calling method to delete the request, but with no additional recourse by the OO.
            l1Token.safeTransfer(proposer, totalBond);
            l1Token.safeApprove(address(optimisticOracle), 0);

            // Return early noting that the attempt at a proposal + dispute did not succeed.
            return false;
        }

        SkinnyOptimisticOracleInterface.Request memory request =
            SkinnyOptimisticOracleInterface.Request({
                proposer: proposer,
                disputer: address(0),
                currency: IERC20(l1Token),
                settled: false,
                proposedPrice: int256(1e18),
                resolvedPrice: 0,
                expirationTime: getCurrentTime() + optimisticOracleLiveness,
                reward: 0,
                finalFee: totalBond - proposerBond,
                bond: proposerBond,
                customLiveness: uint256(optimisticOracleLiveness)
            });

        // Note: don't pull funds until here to avoid any transfers that aren't needed.
        l1Token.safeTransferFrom(msg.sender, address(this), totalBond);
        l1Token.safeApprove(address(optimisticOracle), totalBond);
        // Dispute the request that we just sent.
        optimisticOracle.disputePriceFor(
            identifier,
            uint32(getCurrentTime()),
            customAncillaryData,
            request,
            disputer,
            address(this)
        );

        // Return true to denote that the proposal + dispute calls succeeded.
        return true;
    }

    // Unwraps ETH and does a transfer to a recipient address. If the recipient is a smart contract then sends WETH.
    function _unwrapWETHTo(address payable to, uint256 amount) internal {
        if (address(to).isContract()) {
            l1Token.safeTransfer(to, amount);
        } else {
            WETH9Like(address(l1Token)).withdraw(amount);
            to.transfer(amount);
        }
    }

    // Added to enable the BridgePool to receive ETH. used when unwrapping Weth.
    receive() external payable {}
}

/**
 * @notice This is the BridgePool contract that should be deployed on live networks. It is exactly the same as the
 * regular BridgePool contract, but it overrides getCurrentTime to make the call a simply return block.timestamp with
 * no branching or storage queries. This is done to save gas.
 */
contract BridgePoolProd is BridgePool {
    constructor(
        string memory _lpTokenName,
        string memory _lpTokenSymbol,
        address _bridgeAdmin,
        address _l1Token,
        uint64 _lpFeeRatePerSecond,
        bool _isWethPool,
        address _timer
    ) BridgePool(_lpTokenName, _lpTokenSymbol, _bridgeAdmin, _l1Token, _lpFeeRatePerSecond, _isWethPool, _timer) {}

    function getCurrentTime() public view virtual override returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice Helper view methods designed to be called by BridgePool contracts.
 */
interface BridgeAdminInterface {
    event SetDepositContracts(
        uint256 indexed chainId,
        address indexed l2DepositContract,
        address indexed l2MessengerContract
    );
    event SetCrossDomainAdmin(uint256 indexed chainId, address indexed newAdmin);
    event SetRelayIdentifier(bytes32 indexed identifier);
    event SetOptimisticOracleLiveness(uint32 indexed liveness);
    event SetProposerBondPct(uint64 indexed proposerBondPct);
    event WhitelistToken(uint256 chainId, address indexed l1Token, address indexed l2Token, address indexed bridgePool);
    event SetMinimumBridgingDelay(uint256 indexed chainId, uint64 newMinimumBridgingDelay);
    event DepositsEnabled(uint256 indexed chainId, address indexed l2Token, bool depositsEnabled);
    event BridgePoolsAdminTransferred(address[] bridgePools, address indexed newAdmin);

    function finder() external view returns (address);

    struct DepositUtilityContracts {
        address depositContract; // L2 deposit contract where cross-chain relays originate.
        address messengerContract; // L1 helper contract that can send a message to the L2 with the mapped network ID.
    }

    function depositContracts(uint256) external view returns (DepositUtilityContracts memory);

    struct L1TokenRelationships {
        mapping(uint256 => address) l2Tokens; // L2 Chain Id to l2Token address.
        address bridgePool;
    }

    function whitelistedTokens(address, uint256) external view returns (address l2Token, address bridgePool);

    function optimisticOracleLiveness() external view returns (uint32);

    function proposerBondPct() external view returns (uint64);

    function identifier() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface BridgePoolInterface {
    function l1Token() external view returns (IERC20);

    function changeAdmin(address newAdmin) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/OptimisticOracleInterface.sol";

/**
 * @title Interface for the gas-cost-reduced version of the OptimisticOracle.
 * @notice Differences from normal OptimisticOracle:
 * - refundOnDispute: flag is removed, by default there are no refunds on disputes.
 * - customizing request parameters: In the OptimisticOracle, parameters like `bond` and `customLiveness` can be reset
 *   after a request is already made via `requestPrice`. In the SkinnyOptimisticOracle, these parameters can only be
 *   set in `requestPrice`, which has an expanded input set.
 * - settleAndGetPrice: Replaced by `settle`, which can only be called once per settleable request. The resolved price
 *   can be fetched via the `Settle` event or the return value of `settle`.
 * - general changes to interface: Functions that interact with existing requests all require the parameters of the
 *   request to modify to be passed as input. These parameters must match with the existing request parameters or the
 *   function will revert. This change reflects the internal refactor to store hashed request parameters instead of the
 *   full request struct.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract SkinnyOptimisticOracleInterface {
    // Struct representing a price request. Note that this differs from the OptimisticOracleInterface's Request struct
    // in that refundOnDispute is removed.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
    // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
    // to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
     * @param customLiveness custom proposal liveness to set for request.
     * @return totalBond default bond + final fee that the proposer and disputer will be required to pay.
     */
    function requestPrice(
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward,
        uint256 bond,
        uint256 customLiveness
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param request price request parameters whose hash must match the request that the caller wants to
     * propose a price for.
     * @param proposer address to set as the proposer.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address requester,
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        Request memory request,
        address proposer,
        int256 proposedPrice
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Proposes a price value where caller is the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param request price request parameters whose hash must match the request that the caller wants to
     * propose a price for.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        Request memory request,
        int256 proposedPrice
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Combines logic of requestPrice and proposePrice while taking advantage of gas savings from not having to
     * overwrite Request params that a normal requestPrice() => proposePrice() flow would entail. Note: The proposer
     * will receive any rewards that come from this proposal. However, any bonds are pulled from the caller.
     * @dev The caller is the requester, but the proposer can be customized.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
     * @param customLiveness custom proposal liveness to set for request.
     * @param proposer address to set as the proposer.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function requestAndProposePriceFor(
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward,
        uint256 bond,
        uint256 customLiveness,
        address proposer,
        int256 proposedPrice
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param request price request parameters whose hash must match the request that the caller wants to
     * dispute.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePriceFor(
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        Request memory request,
        address disputer,
        address requester
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal where caller is the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param request price request parameters whose hash must match the request that the caller wants to
     * dispute.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        Request memory request
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param request price request parameters whose hash must match the request that the caller wants to
     * settle.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     * @return resolvedPrice the price that the request settled to.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        Request memory request
    ) external virtual returns (uint256 payout, int256 resolvedPrice);

    /**
     * @notice Computes the current state of a price request. See the State enum for more details.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param request price request parameters.
     * @return the State.
     */
    function getState(
        address requester,
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        Request memory request
    ) external virtual returns (OptimisticOracleInterface.State);

    /**
     * @notice Checks if a given request has resolved, expired or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param request price request parameters. The hash of these parameters must match with the request hash that is
     * associated with the price request unique ID {requester, identifier, timestamp, ancillaryData}, or this method
     * will revert.
     * @return boolean indicating true if price exists and false if not.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint32 timestamp,
        bytes memory ancillaryData,
        Request memory request
    ) public virtual returns (bool);

    /**
     * @notice Generates stamped ancillary data in the format that it would be used in the case of a price dispute.
     * @param ancillaryData ancillary data of the price being requested.
     * @param requester sender of the initial price request.
     * @return the stamped ancillary bytes.
     */
    function stampAncillaryData(bytes memory ancillaryData, address requester)
        public
        pure
        virtual
        returns (bytes memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that allows financial contracts to pay oracle fees for their use of the system.
 */
interface StoreInterface {
    /**
     * @notice Pays Oracle fees in ETH to the store.
     * @dev To be used by contracts whose margin currency is ETH.
     */
    function payOracleFees() external payable;

    /**
     * @notice Pays oracle fees in the margin currency, erc20Address, to the store.
     * @dev To be used if the margin currency is an ERC20 token rather than ETH.
     * @param erc20Address address of the ERC20 token used to pay the fee.
     * @param amount number of tokens to transfer. An approval for at least this amount must exist.
     */
    function payOracleFeesErc20(address erc20Address, FixedPoint.Unsigned calldata amount) external;

    /**
     * @notice Computes the regular oracle fees that a contract should pay for a period.
     * @param startTime defines the beginning time from which the fee is paid.
     * @param endTime end time until which the fee is paid.
     * @param pfc "profit from corruption", or the maximum amount of margin currency that a
     * token sponsor could extract from the contract through corrupting the price feed in their favor.
     * @return regularFee amount owed for the duration from start to end time for the given pfc.
     * @return latePenalty for paying the fee after the deadline.
     */
    function computeRegularFee(
        uint256 startTime,
        uint256 endTime,
        FixedPoint.Unsigned calldata pfc
    ) external view returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty);

    /**
     * @notice Computes the final oracle fees that a contract should pay at settlement.
     * @param currency token used to pay the final fee.
     * @return finalFee amount due.
     */
    function computeFinalFee(address currency) external view returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
}

/**
 * @title Commonly re-used values for contracts associated with the OptimisticOracle.
 */
library OptimisticOracleConstraints {
    // Any price request submitted to the OptimisticOracle must contain ancillary data no larger than this value.
    // This value must be <= the Voting contract's `ancillaryBytesLimit` constant value otherwise it is possible
    // that a price can be requested to the OptimisticOracle successfully, but cannot be resolved by the DVM which
    // refuses to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Library for encoding and decoding ancillary data for DVM price requests.
 * @notice  We assume that on-chain ancillary data can be formatted directly from bytes to utf8 encoding via
 * web3.utils.hexToUtf8, and that clients will parse the utf8-encoded ancillary data as a comma-delimitted key-value
 * dictionary. Therefore, this library provides internal methods that aid appending to ancillary data from Solidity
 * smart contracts. More details on UMA's ancillary data guidelines below:
 * https://docs.google.com/document/d/1zhKKjgY1BupBGPPrY_WOJvui0B6DMcd-xDR8-9-SPDw/edit
 */
library AncillaryData {
    // This converts the bottom half of a bytes32 input to hex in a highly gas-optimized way.
    // Source: the brilliant implementation at https://gitter.im/ethereum/solidity?at=5840d23416207f7b0ed08c9b.
    function toUtf8Bytes32Bottom(bytes32 bytesIn) private pure returns (bytes32) {
        unchecked {
            uint256 x = uint256(bytesIn);

            // Nibble interleave
            x = x & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
            x = (x | (x * 2**64)) & 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
            x = (x | (x * 2**32)) & 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
            x = (x | (x * 2**16)) & 0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
            x = (x | (x * 2**8)) & 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
            x = (x | (x * 2**4)) & 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;

            // Hex encode
            uint256 h = (x & 0x0808080808080808080808080808080808080808080808080808080808080808) / 8;
            uint256 i = (x & 0x0404040404040404040404040404040404040404040404040404040404040404) / 4;
            uint256 j = (x & 0x0202020202020202020202020202020202020202020202020202020202020202) / 2;
            x = x + (h & (i | j)) * 0x27 + 0x3030303030303030303030303030303030303030303030303030303030303030;

            // Return the result.
            return bytes32(x);
        }
    }

    /**
     * @notice Returns utf8-encoded bytes32 string that can be read via web3.utils.hexToUtf8.
     * @dev Will return bytes32 in all lower case hex characters and without the leading 0x.
     * This has minor changes from the toUtf8BytesAddress to control for the size of the input.
     * @param bytesIn bytes32 to encode.
     * @return utf8 encoded bytes32.
     */
    function toUtf8Bytes(bytes32 bytesIn) internal pure returns (bytes memory) {
        return abi.encodePacked(toUtf8Bytes32Bottom(bytesIn >> 128), toUtf8Bytes32Bottom(bytesIn));
    }

    /**
     * @notice Returns utf8-encoded address that can be read via web3.utils.hexToUtf8.
     * Source: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string/8447#8447
     * @dev Will return address in all lower case characters and without the leading 0x.
     * @param x address to encode.
     * @return utf8 encoded address bytes.
     */
    function toUtf8BytesAddress(address x) internal pure returns (bytes memory) {
        return
            abi.encodePacked(toUtf8Bytes32Bottom(bytes32(bytes20(x)) >> 128), bytes8(toUtf8Bytes32Bottom(bytes20(x))));
    }

    /**
     * @notice Converts a uint into a base-10, UTF-8 representation stored in a `string` type.
     * @dev This method is based off of this code: https://stackoverflow.com/a/65707309.
     */
    function toUtf8BytesUint(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) {
            return "0";
        }
        uint256 j = x;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (x != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(x - (x / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            x /= 10;
        }
        return bstr;
    }

    function appendKeyValueBytes32(
        bytes memory currentAncillaryData,
        bytes memory key,
        bytes32 value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8Bytes(value));
    }

    /**
     * @notice Adds "key:value" to `currentAncillaryData` where `value` is an address that first needs to be converted
     * to utf8 bytes. For example, if `utf8(currentAncillaryData)="k1:v1"`, then this function will return
     * `utf8(k1:v1,key:value)`, and if `currentAncillaryData` is blank, then this will return `utf8(key:value)`.
     * @param currentAncillaryData This bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param key Again, this bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param value An address to set as the value in the key:value pair to append to `currentAncillaryData`.
     * @return Newly appended ancillary data.
     */
    function appendKeyValueAddress(
        bytes memory currentAncillaryData,
        bytes memory key,
        address value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8BytesAddress(value));
    }

    /**
     * @notice Adds "key:value" to `currentAncillaryData` where `value` is a uint that first needs to be converted
     * to utf8 bytes. For example, if `utf8(currentAncillaryData)="k1:v1"`, then this function will return
     * `utf8(k1:v1,key:value)`, and if `currentAncillaryData` is blank, then this will return `utf8(key:value)`.
     * @param currentAncillaryData This bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param key Again, this bytes data should ideally be able to be utf8-decoded, but its OK if not.
     * @param value A uint to set as the value in the key:value pair to append to `currentAncillaryData`.
     * @return Newly appended ancillary data.
     */
    function appendKeyValueUint(
        bytes memory currentAncillaryData,
        bytes memory key,
        uint256 value
    ) internal pure returns (bytes memory) {
        bytes memory prefix = constructPrefix(currentAncillaryData, key);
        return abi.encodePacked(currentAncillaryData, prefix, toUtf8BytesUint(value));
    }

    /**
     * @notice Helper method that returns the left hand side of a "key:value" pair plus the colon ":" and a leading
     * comma "," if the `currentAncillaryData` is not empty. The return value is intended to be prepended as a prefix to
     * some utf8 value that is ultimately added to a comma-delimited, key-value dictionary.
     */
    function constructPrefix(bytes memory currentAncillaryData, bytes memory key) internal pure returns (bytes memory) {
        if (currentAncillaryData.length > 0) {
            return abi.encodePacked(",", key, ":");
        } else {
            return abi.encodePacked(key, ":");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run in production, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view virtual returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp; // solhint-disable-line not-rely-on-time
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an uint, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// This contract is taken from Uniswaps's multi call implementation (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol)
// and was modified to be solidity 0.8 compatible. Additionally, the method was restricted to only work with msg.value
// set to 0 to avoid any nasty attack vectors on function calls that use value sent with deposits.
pragma solidity ^0.8.0;

/// @title MultiCaller
/// @notice Enables calling multiple methods in a single call to the contract
contract MultiCaller {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        require(msg.value == 0, "Only multicall with 0 value");
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleInterface {
    // Struct representing the state of a price request.
    enum State {
        Invalid, // Never requested.
        Requested, // Requested, no other actions taken.
        Proposed, // Proposed, but not expired or disputed yet.
        Expired, // Proposed, not disputed, past liveness.
        Disputed, // Disputed, but no DVM price returned yet.
        Resolved, // Disputed and DVM price is available.
        Settled // Final price has been set in the contract (can get here from Expired or Resolved).
    }

    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
    // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
    // to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
     * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
     * bond, so there is still profit to be made even if the reward is refunded.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setRefundOnDispute(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual;

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external virtual;

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param proposer address to set as the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was value (the proposal was incorrect).
     */
    function disputePriceFor(
        address disputer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function settleAndGetPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (int256);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 payout);

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (Request memory);

    /**
     * @notice Returns the state of a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the State enum value.
     */
    function getState(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (State);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return true if price has resolved or settled, false otherwise.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (bool);

    function stampAncillaryData(bytes memory ancillaryData, address requester)
        public
        view
        virtual
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() {
        currentTime = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the currentTime variable set in the Timer.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}