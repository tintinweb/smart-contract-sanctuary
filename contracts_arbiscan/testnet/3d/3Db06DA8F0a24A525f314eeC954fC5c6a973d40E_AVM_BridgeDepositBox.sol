/**
 *Submitted for verification at arbiscan.io on 2021-10-07
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts-ovm/insured-bridge/external/Legacy_Timer.sol

// Temp contract until we can use the canonical UMA testable once Optimism support solidity 0.8.


pragma solidity >=0.7.6;

contract Legacy_Timer {
    uint256 private currentTime;

    constructor() {
        currentTime = block.timestamp; // solhint-disable-line not-rely-on-time
    }

    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}


// File contracts-ovm/insured-bridge/external/Legacy_Testable.sol

// Temp contract until we can use the canonical UMA testable once Optimism support solidity 0.8.
// No code was changed here. It is a direct copy paste from the UMA testable, simply with a modified solidity version.


pragma solidity >=0.7.6;

abstract contract Legacy_Testable {
    address public timerAddress;

    constructor(address _timerAddress) {
        timerAddress = _timerAddress;
    }

    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    function setCurrentTime(uint256 time) external onlyIfTest {
        Legacy_Timer(timerAddress).setCurrentTime(time);
    }

    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Legacy_Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp; // solhint-disable-line not-rely-on-time
        }
    }
}


// File contracts-ovm/insured-bridge/external/Legacy_Lockable.sol

// Temp contract until we can use the canonical UMA lockable once Optimism support solidity 0.8.
// No code was changed here. It is a direct copy paste from the UMA lockable, simply with a modified solidity version.


pragma solidity >=0.7.6;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Legacy_Lockable {
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


// File contracts-ovm/insured-bridge/implementation/BridgeDepositBox.sol


library TokenHelper {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TokenHelper::transferFrom: transferFrom failed"
        );
    }
}

interface TokenLike {
    function balanceOf(address guy) external returns (uint256 wad);
}

/**
 * @title OVM Bridge Deposit Box.
 * @notice Accepts deposits on Optimism L2 to relay to Ethereum L1 as part of the UMA insured bridge system.
 */

abstract contract BridgeDepositBox is Legacy_Testable, Legacy_Lockable {
    /*************************************
     *  OVM DEPOSIT BOX DATA STRUCTURES  *
     *************************************/

    // ChainID of the L2 this deposit box is deployed on.
    uint256 chainId;

    // Track the total number of deposits. Used as a unique identifier for bridged transfers.
    uint256 public numberOfDeposits;

    struct L2TokenRelationships {
        address l1Token;
        address l1BridgePool;
        uint64 lastBridgeTime;
        bool depositsEnabled;
    }

    // Mapping of whitelisted L2Token to L2TokenRelationships. Contains L1 TokenAddress and the last time this token
    // type was bridged. Used to rate limit bridging actions to rate limit withdraws to L1.
    mapping(address => L2TokenRelationships) public whitelistedTokens;

    // Minimum time that must elapse between bridging actions for a given token. Used to rate limit bridging back to L1.
    uint64 public minimumBridgingDelay;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event SetMinimumBridgingDelay(uint64 newMinimumBridgingDelay);
    event WhitelistToken(address l1Token, address l2Token, uint64 lastBridgeTime, address bridgePool);
    event DepositsEnabled(address l2Token, bool depositsEnabled);
    // TODO: change the order of these to match the way they are used in the bridge pool.
    event FundsDeposited(
        uint256 chainId,
        uint256 depositId,
        address l1Recipient,
        address l2Sender,
        address l1Token,
        uint256 amount,
        uint64 slowRelayFeePct,
        uint64 instantRelayFeePct,
        uint64 quoteTimestamp
    );
    event TokensBridged(address l2Token, uint256 numberOfTokensBridged, uint256 l1Gas, address caller);

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    modifier onlyIfDepositsEnabled(address l2Token) {
        require(whitelistedTokens[l2Token].depositsEnabled, "Contract is disabled");
        _;
    }

    /**
     * @notice Construct the Bridge Deposit Box
     * @param _minimumBridgingDelay Minimum second that must elapse between L2->L1 token transfer to prevent dos.
     * @param _chainId Chain identifier for the Bridge deposit box.
     * @param timerAddress Timer used to synchronize contract time in testing. Set to 0x000... in production.
     */
    constructor(
        uint64 _minimumBridgingDelay,
        uint256 _chainId,
        address timerAddress
    ) Legacy_Testable(timerAddress) {
        _setMinimumBridgingDelay(_minimumBridgingDelay);
        chainId = _chainId;
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Changes the minimum time in seconds that must elapse between withdraws from L2->L1.
     * @param newMinimumBridgingDelay the new minimum delay.
     */
    function _setMinimumBridgingDelay(uint64 newMinimumBridgingDelay) internal {
        minimumBridgingDelay = newMinimumBridgingDelay;
        emit SetMinimumBridgingDelay(minimumBridgingDelay);
    }

    /**
     * @notice Enables L1 owner to whitelist a L1 Token <-> L2 Token pair for bridging.
     * @param l1Token Address of the canonical L1 token. This is the token users will receive on Ethereum.
     * @param l2Token Address of the L2 token representation. This is the token users would deposit on optimism.
     * @param l1BridgePool Address of the L1 withdrawal pool linked to this L2+L1 token.
     */
    function _whitelistToken(
        address l1Token,
        address l2Token,
        address l1BridgePool
    ) internal {
        whitelistedTokens[l2Token] = L2TokenRelationships({
            l1Token: l1Token,
            l1BridgePool: l1BridgePool,
            lastBridgeTime: uint64(getCurrentTime()),
            depositsEnabled: true
        });

        emit WhitelistToken(l1Token, l2Token, uint64(getCurrentTime()), l1BridgePool);
    }

    /**
     * @notice L1 owner can enable/disable deposits for a whitelisted tokens.
     * @param l2Token address of L2 token to enable/disable deposits for.
     * @param depositsEnabled bool to set if the deposit box should accept/reject deposits.
     */
    function _setEnableDeposits(address l2Token, bool depositsEnabled) internal {
        whitelistedTokens[l2Token].depositsEnabled = depositsEnabled;
        emit DepositsEnabled(l2Token, depositsEnabled);
    }

    /**************************************
     *         DEPOSITOR FUNCTIONS        *
     **************************************/

    /**
     * @notice Called by L2 user to bridge funds between L2 and L1.
     * @dev Emits the `FundsDeposited` event which relayers listen for as part of the bridging action.
     * @dev The caller must first approve this contract to spend `amount` of `l2Token`.
     * @param l1Recipient L1 address that should receive the tokens.
     * @param l2Token L2 token to deposit.
     * @param amount How many L2 tokens should be deposited.
     * @param slowRelayFeePct Max fraction of `amount` that the depositor is willing to pay as a slow relay fee.
     * @param instantRelayFeePct Fraction of `amount` that the depositor is willing to pay as a instant relay fee.
     * @param quoteTimestamp Timestamp, at which the depositor will be quoted for L1 liquidity. This enables the
     *    depositor to know the L1 fees before submitting their deposit. Must be within 10 mins of the current time.
     */
    function deposit(
        address l1Recipient,
        address l2Token,
        uint256 amount,
        uint64 slowRelayFeePct,
        uint64 instantRelayFeePct,
        uint64 quoteTimestamp
    ) public onlyIfDepositsEnabled(l2Token) nonReentrant() {
        require(isWhitelistToken(l2Token), "deposit token not whitelisted");
        // We limit the sum of slow and instant relay fees to 50% to prevent the user spending all their funds on fees.
        // The realizedLPFeePct on L1 is limited to 50% so the total spent on fees does not ever exceed 100%.
        require(slowRelayFeePct <= 0.25e18, "slowRelayFeePct can not exceed 25%");
        require(instantRelayFeePct <= 0.25e18, "instantRelayFeePct can not exceed 25%");

        // Note that the OVM's notion of `block.timestamp` is different to the main ethereum L1 EVM. The OVM timestamp
        // corresponds to the L1 timestamp of the last confirmed L1 ⇒ L2 transaction. The quoteTime must be within 10
        // mins of the current time to allow for this variance.
        require(
            getCurrentTime() >= quoteTimestamp - 10 minutes && getCurrentTime() <= quoteTimestamp + 10 minutes,
            "deposit mined after deadline"
        );

        emit FundsDeposited(
            chainId,
            numberOfDeposits, // depositId: the current number of deposits acts as a deposit ID (nonce).
            l1Recipient,
            msg.sender,
            whitelistedTokens[l2Token].l1Token,
            amount,
            slowRelayFeePct,
            instantRelayFeePct,
            quoteTimestamp
        );

        numberOfDeposits += 1;

        TokenHelper.safeTransferFrom(l2Token, msg.sender, address(this), amount);
    }

    /**************************************
     *           VIEW FUNCTIONS           *
     **************************************/

    /**
     * @notice Checks if a given L2 token is whitelisted.
     * @param l2Token L2 token to check against the whitelist.
     */
    function isWhitelistToken(address l2Token) public view returns (bool) {
        return whitelistedTokens[l2Token].l1Token != address(0);
    }

    /**
     * @notice Checks if enough time has elapsed from the previous bridge transfer to execute another bridge transfer.
     * @param l2Token L2 token to check against last bridge time delay.
     */
    function hasEnoughTimeElapsedToBridge(address l2Token) public view returns (bool) {
        return getCurrentTime() > whitelistedTokens[l2Token].lastBridgeTime + minimumBridgingDelay;
    }
}


// File contracts-ovm/insured-bridge/external/AVM_CrossDomainEnabled.sol

pragma solidity >=0.7.6;

abstract contract AVM_CrossDomainEnabled {
    modifier onlyFromCrossDomainAccount(address l1Counterpart) {
        require(msg.sender == applyL1ToL2Alias(l1Counterpart), "ONLY_COUNTERPART_GATEWAY");
        _;
    }

    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    // l1 addresses are transformed during l1->l2 calls. see https://developer.offchainlabs.com/docs/l1_l2_messages#address-aliasing for more information.
    function applyL1ToL2Alias(address l1Address) public pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }
}


// File contracts-ovm/insured-bridge/implementation/AVM_BridgeDepositBox.sol


pragma solidity >=0.7.6;


interface StandardBridgeLike {
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable returns (bytes memory);
}

contract AVM_BridgeDepositBox is BridgeDepositBox, AVM_CrossDomainEnabled {
    // Address of the L1 contract that acts as the owner of this Bridge deposit box.
    address public crossDomainAdmin;

    // Address of the Arbitrum L2 token gateway.
    address public l2GatewayRouter;

    event SetXDomainAdmin(address newAdmin);

    /**
     * @notice Construct the Arbitrum Bridge Deposit Box
     * @param _l2GatewayRouter Address of the Arbitrum L2 token gateway router for sending tokens from L2->L1.
     * @param _crossDomainAdmin Address of the L1 contract that can call admin functions on this contract from L1.
     * @param _minimumBridgingDelay Minimum second that must elapse between L2->L1 token transfer to prevent dos.
     * @param _chainId L2 Chain identifier this deposit box is deployed on.
     * @param timerAddress Timer used to synchronize contract time in testing. Set to 0x000... in production.
     */
    constructor(
        address _l2GatewayRouter,
        address _crossDomainAdmin,
        uint64 _minimumBridgingDelay,
        uint256 _chainId,
        address timerAddress
    ) BridgeDepositBox(_minimumBridgingDelay, _chainId, timerAddress) {
        l2GatewayRouter = _l2GatewayRouter;
        _setCrossDomainAdmin(_crossDomainAdmin);
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Changes the L1 contract that can trigger admin functions on this L2 deposit deposit box.
     * @dev This should be set to the address of the L1 contract that ultimately relays a cross-domain message, which
     * is expected to be the ArbitrumMessenger.
     * @dev Only callable by the existing crossDomainAdmin via the Arbitrum cross domain messenger.
     * @param newCrossDomainAdmin address of the new L1 admin contract.
     */
    function setCrossDomainAdmin(address newCrossDomainAdmin) public onlyFromCrossDomainAccount(crossDomainAdmin) {
        _setCrossDomainAdmin(newCrossDomainAdmin);
    }

    /**
     * @notice Changes the minimum time in seconds that must elapse between withdraws from L2->L1.
     * @dev Only callable by the existing crossDomainAdmin via the Arbitrum cross domain messenger.
     * @param newMinimumBridgingDelay the new minimum delay.
     */
    function setMinimumBridgingDelay(uint64 newMinimumBridgingDelay)
        public
        onlyFromCrossDomainAccount(crossDomainAdmin)
    {
        _setMinimumBridgingDelay(newMinimumBridgingDelay);
    }

    /**
     * @notice Enables L1 owner to whitelist a L1 Token <-> L2 Token pair for bridging.
     * @dev Only callable by the existing crossDomainAdmin via the Arbitrum cross domain messenger.
     * @param l1Token Address of the canonical L1 token. This is the token users will receive on Ethereum.
     * @param l2Token Address of the L2 token representation. This is the token users would deposit on Arbitrum.
     * @param l1BridgePool Address of the L1 withdrawal pool linked to this L2+L1 token.
     */
    function whitelistToken(
        address l1Token,
        address l2Token,
        address l1BridgePool
    ) public onlyFromCrossDomainAccount(crossDomainAdmin) {
        _whitelistToken(l1Token, l2Token, l1BridgePool);
    }

    /**
     * @notice L1 owner can enable/disable deposits for a whitelisted tokens.
     * @dev Only callable by the existing crossDomainAdmin via the Arbitrum cross domain messenger.
     * @param l2Token address of L2 token to enable/disable deposits for.
     * @param depositsEnabled bool to set if the deposit box should accept/reject deposits.
     */
    function setEnableDeposits(address l2Token, bool depositsEnabled)
        public
        onlyFromCrossDomainAccount(crossDomainAdmin)
    {
        _setEnableDeposits(l2Token, depositsEnabled);
    }

    /**************************************
     *          RELAYER FUNCTIONS         *
     **************************************/

    /**
     * @notice Called by relayer (or any other EOA) to move a batch of funds from the deposit box, through the canonical
     *      token bridge, to the L1 Withdraw box.
     * @dev The frequency that this function can be called is rate limited by the `minimumBridgingDelay` to prevent spam
     *      on L1 as the finalization of a L2->L1 tx is quite expensive.
     * @param l2Token L2 token to relay over the canonical bridge.
     * @param l1Gas Unused by Arbitrum, but included for potential forward compatibility considerations.
     */
    function bridgeTokens(address l2Token, uint32 l1Gas) public {
        uint256 bridgeDepositBoxBalance = TokenLike(l2Token).balanceOf(address(this));
        require(bridgeDepositBoxBalance > 0, "can't bridge zero tokens");
        require(isWhitelistToken(l2Token), "can't bridge non-whitelisted token");
        require(hasEnoughTimeElapsedToBridge(l2Token), "not enough time has elapsed from previous bridge");

        whitelistedTokens[l2Token].lastBridgeTime = uint64(getCurrentTime());

        StandardBridgeLike(l2GatewayRouter).outboundTransfer(
            whitelistedTokens[l2Token].l1Token, // _l1Token. Address of the L1 token to bridge over.
            whitelistedTokens[l2Token].l1BridgePool, // _to. Withdraw, over the bridge, to the l1 withdraw contract.
            bridgeDepositBoxBalance, // _amount. Send the full balance of the deposit box to bridge.
            "" // _data. We dont need to send any data for the bridging action.
        );

        emit TokensBridged(l2Token, bridgeDepositBoxBalance, l1Gas, msg.sender);
    }

    /**************************************
     *         INTERNAL FUNCTIONS         *
     **************************************/

    function _setCrossDomainAdmin(address newCrossDomainAdmin) internal {
        require(newCrossDomainAdmin != address(0), "Empty address");
        crossDomainAdmin = newCrossDomainAdmin;
        emit SetXDomainAdmin(crossDomainAdmin);
    }
}