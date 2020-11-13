pragma solidity 0.5.17;

import {DepositLiquidation} from "./DepositLiquidation.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {DepositFunding} from "./DepositFunding.sol";
import {DepositRedemption} from "./DepositRedemption.sol";
import {DepositStates} from "./DepositStates.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";
import {IERC721} from "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";

import "../system/DepositFactoryAuthority.sol";

// solium-disable function-order
// Below, a few functions must be public to allow bytes memory parameters, but
// their being so triggers errors because public functions should be grouped
// below external functions. Since these would be external if it were possible,
// we ignore the issue.

/// @title  tBTC Deposit
/// @notice This is the main contract for tBTC. It is the state machine that
///         (through various libraries) handles bitcoin funding, bitcoin-spv
///         proofs, redemption, liquidation, and fraud logic.
/// @dev This contract presents a public API that exposes the following
///      libraries:
///
///       - `DepositFunding`
///       - `DepositLiquidaton`
///       - `DepositRedemption`,
///       - `DepositStates`
///       - `DepositUtils`
///       - `OutsourceDepositLogging`
///       - `TBTCConstants`
///
///      Where these libraries require deposit state, this contract's state
///      variable `self` is used. `self` is a struct of type
///      `DepositUtils.Deposit` that contains all aspects of the deposit state
///      itself.
contract Deposit is DepositFactoryAuthority {

    using DepositRedemption for DepositUtils.Deposit;
    using DepositFunding for DepositUtils.Deposit;
    using DepositLiquidation for DepositUtils.Deposit;
    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;

    DepositUtils.Deposit self;

    /// @dev Deposit should only be _constructed_ once. New deposits are created
    ///      using the `DepositFactory.createDeposit` method, and are clones of
    ///      the constructed deposit. The factory will set the initial values
    ///      for a new clone using `initializeDeposit`.
    constructor () public {
        // The constructed Deposit will never be used, so the deposit factory
        // address can be anything. Clones are updated as per above.
        initialize(address(0xdeadbeef));
    }

    /// @notice Deposits do not accept arbitrary ETH.
    function () external payable {
        require(msg.data.length == 0, "Deposit contract was called with unknown function selector.");
    }

//----------------------------- METADATA LOOKUP ------------------------------//

    /// @notice Get this deposit's BTC lot size in satoshis.
    /// @return uint64 lot size in satoshis.
    function lotSizeSatoshis() external view returns (uint64){
        return self.lotSizeSatoshis;
    }

    /// @notice Get this deposit's lot size in TBTC.
    /// @dev This is the same as lotSizeSatoshis(), but is multiplied to scale
    ///      to 18 decimal places.
    /// @return uint256 lot size in TBTC precision (max 18 decimal places).
    function lotSizeTbtc() external view returns (uint256){
        return self.lotSizeTbtc();
    }

    /// @notice Get the signer fee for this deposit, in TBTC.
    /// @dev This is the one-time fee required by the signers to perform the
    ///      tasks needed to maintain a decentralized and trustless model for
    ///      tBTC. It is a percentage of the deposit's lot size.
    /// @return Fee amount in TBTC.
    function signerFeeTbtc() external view returns (uint256) {
        return self.signerFeeTbtc();
    }

    /// @notice Get the integer representing the current state.
    /// @dev We implement this because contracts don't handle foreign enums
    ///      well. See `DepositStates` for more info on states.
    /// @return The 0-indexed state from the DepositStates enum.
    function currentState() external view returns (uint256) {
        return uint256(self.currentState);
    }

    /// @notice Check if the Deposit is in ACTIVE state.
    /// @return True if state is ACTIVE, false otherwise.
    function inActive() external view returns (bool) {
        return self.inActive();
    }

    /// @notice Get the contract address of the BondedECDSAKeep associated with
    ///         this Deposit.
    /// @dev The keep contract address is saved on Deposit initialization.
    /// @return Address of the Keep contract.
    function keepAddress() external view returns (address) {
        return self.keepAddress;
    }

    /// @notice Retrieve the remaining term of the deposit in seconds.
    /// @dev The value accuracy is not guaranteed since block.timestmap can be
    ///      lightly manipulated by miners.
    /// @return The remaining term of the deposit in seconds. 0 if already at
    ///         term.
    function remainingTerm() external view returns(uint256){
        return self.remainingTerm();
    }

    /// @notice Get the current collateralization level for this Deposit.
    /// @dev This value represents the percentage of the backing BTC value the
    ///      signers currently must hold as bond.
    /// @return The current collateralization level for this deposit.
    function collateralizationPercentage() external view returns (uint256) {
        return self.collateralizationPercentage();
    }

    /// @notice Get the initial collateralization level for this Deposit.
    /// @dev This value represents the percentage of the backing BTC value
    ///      the signers hold initially. It is set at creation time.
    /// @return The initial collateralization level for this deposit.
    function initialCollateralizedPercent() external view returns (uint16) {
        return self.initialCollateralizedPercent;
    }

    /// @notice Get the undercollateralization level for this Deposit.
    /// @dev This collateralization level is semi-critical. If the
    ///      collateralization level falls below this percentage the Deposit can
    ///      be courtesy-called by calling `notifyCourtesyCall`. This value
    ///      represents the percentage of the backing BTC value the signers must
    ///      hold as bond in order to not be undercollateralized. It is set at
    ///      creation time. Note that the value for new deposits in TBTCSystem
    ///      can be changed by governance, but the value for a particular
    ///      deposit is static once the deposit is created.
    /// @return The undercollateralized level for this deposit.
    function undercollateralizedThresholdPercent() external view returns (uint16) {
        return self.undercollateralizedThresholdPercent;
    }

    /// @notice Get the severe undercollateralization level for this Deposit.
    /// @dev This collateralization level is critical. If the collateralization
    ///      level falls below this percentage the Deposit can get liquidated.
    ///      This value represents the percentage of the backing BTC value the
    ///      signers must hold as bond in order to not be severely
    ///      undercollateralized. It is set at creation time. Note that the
    ///      value for new deposits in TBTCSystem can be changed by governance,
    ///      but the value for a particular deposit is static once the deposit
    ///      is created.
    /// @return The severely undercollateralized level for this deposit.
    function severelyUndercollateralizedThresholdPercent() external view returns (uint16) {
        return self.severelyUndercollateralizedThresholdPercent;
    }

    /// @notice Get the value of the funding UTXO.
    /// @dev This call will revert if the deposit is not in a state where the
    ///      UTXO info should be valid. In particular, before funding proof is
    ///      successfully submitted (i.e. in states START,
    ///      AWAITING_SIGNER_SETUP, and AWAITING_BTC_FUNDING_PROOF), this value
    ///      would not be valid.
    /// @return The value of the funding UTXO in satoshis.
    function utxoValue() external view returns (uint256){
        require(
            ! self.inFunding(),
            "Deposit has not yet been funded and has no available funding info"
        );

        return self.utxoValue();
    }

    /// @notice Returns information associated with the funding UXTO.
    /// @dev This call will revert if the deposit is not in a state where the
    ///      funding info should be valid. In particular, before funding proof
    ///      is successfully submitted (i.e. in states START,
    ///      AWAITING_SIGNER_SETUP, and AWAITING_BTC_FUNDING_PROOF), none of
    ///      these values are set or valid.
    /// @return A tuple of (uxtoValueBytes, fundedAt, uxtoOutpoint).
    function fundingInfo() external view returns (bytes8 utxoValueBytes, uint256 fundedAt, bytes memory utxoOutpoint) {
        require(
            ! self.inFunding(),
            "Deposit has not yet been funded and has no available funding info"
        );

        return (self.utxoValueBytes, self.fundedAt, self.utxoOutpoint);
    }

    /// @notice Calculates the amount of value at auction right now.
    /// @dev This call will revert if the deposit is not in a state where an
    ///      auction is currently in progress.
    /// @return The value in wei that would be received in exchange for the
    ///         deposit's lot size in TBTC if `purchaseSignerBondsAtAuction`
    ///         were called at the time this function is called.
    function auctionValue() external view returns (uint256) {
        require(
            self.inSignerLiquidation(),
            "Deposit has no funds currently at auction"
        );

        return self.auctionValue();
    }

    /// @notice Get caller's ETH withdraw allowance.
    /// @dev Generally ETH is only available to withdraw after the deposit
    ///      reaches a closed state. The amount reported is for the sender, and
    ///      can be withdrawn using `withdrawFunds` if the deposit is in an end
    ///      state.
    /// @return The withdraw allowance in wei.
    function withdrawableAmount() external view returns (uint256) {
        return self.getWithdrawableAmount();
    }

//------------------------------ FUNDING FLOW --------------------------------//

    /// @notice Notify the contract that signing group setup has timed out if
    ///         retrieveSignerPubkey is not successfully called within the
    ///         allotted time.
    /// @dev This is considered a signer fault, and the signers' bonds are used
    ///      to make the deposit setup fee available for withdrawal by the TDT
    ///      holder as a refund. The remainder of the signers' bonds are
    ///      returned to the bonding pool and the signers are released from any
    ///      further responsibilities. Reverts if the deposit is not awaiting
    ///      signer setup or if the signing group formation timeout has not
    ///      elapsed.
    function notifySignerSetupFailed() external {
        self.notifySignerSetupFailed();
    }

    /// @notice Notify the contract that the ECDSA keep has generated a public
    ///         key so the deposit contract can pull it in.
    /// @dev Stores the pubkey as 2 bytestrings, X and Y. Emits a
    ///      RegisteredPubkey event with the two components. Reverts if the
    ///      deposit is not awaiting signer setup, if the generated public key
    ///      is unset or has incorrect length, or if the public key has a 0
    ///      X or Y value.
    function retrieveSignerPubkey() external {
        self.retrieveSignerPubkey();
    }

    /// @notice Notify the contract that the funding phase of the deposit has
    ///         timed out if `provideBTCFundingProof` is not successfully called
    ///         within the allotted time. Any sent BTC is left under control of
    ///         the signer group, and the funder can use `requestFunderAbort` to
    ///         request an at-signer-discretion return of any BTC sent to a
    ///         deposit that has been notified of a funding timeout.
    /// @dev This is considered a funder fault, and the funder's payment for
    ///      opening the deposit is not refunded. Emits a SetupFailed event.
    ///      Reverts if the funding timeout has not yet elapsed, or if the
    ///      deposit is not currently awaiting funding proof.
    function notifyFundingTimedOut() external {
        self.notifyFundingTimedOut();
    }

    /// @notice Requests a funder abort for a failed-funding deposit; that is,
    ///         requests the return of a sent UTXO to _abortOutputScript. It
    ///         imposes no requirements on the signing group. Signers should
    ///         send their UTXO to the requested output script, but do so at
    ///         their discretion and with no penalty for failing to do so. This
    ///         can be used for example when a UTXO is sent that is the wrong
    ///         size for the lot.
    /// @dev This is a self-admitted funder fault, and is only be callable by
    ///      the TDT holder. This function emits the FunderAbortRequested event,
    ///      but stores no additional state.
    /// @param _abortOutputScript The output script the funder wishes to request
    ///        a return of their UTXO to.
    function requestFunderAbort(bytes memory _abortOutputScript) public { // not external to allow bytes memory parameters
        require(
            self.depositOwner() == msg.sender,
            "Only TDT holder can request funder abort"
        );

        self.requestFunderAbort(_abortOutputScript);
    }

    /// @notice Anyone can provide a signature corresponding to the signers'
    ///         public key to prove fraud during funding. Note that during
    ///         funding no signature has been requested from the signers, so
    ///         any signature is effectively fraud.
    /// @dev Calls out to the keep to verify if there was fraud.
    /// @param _v Signature recovery value.
    /// @param _r Signature R value.
    /// @param _s Signature S value.
    /// @param _signedDigest The digest signed by the signature (v,r,s) tuple.
    /// @param _preimage The sha256 preimage of the digest.
    function provideFundingECDSAFraudProof(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public { // not external to allow bytes memory parameters
        self.provideFundingECDSAFraudProof(_v, _r, _s, _signedDigest, _preimage);
    }

    /// @notice Anyone may submit a funding proof to the deposit showing that
    ///         a transaction was submitted and sufficiently confirmed on the
    ///         Bitcoin chain transferring the deposit lot size's amount of BTC
    ///         to the signer-controlled private key corresopnding to this
    ///         deposit. This will move the deposit into an active state.
    /// @dev Takes a pre-parsed transaction and calculates values needed to
    ///      verify funding.
    /// @param _txVersion Transaction version number (4-byte little-endian).
    /// @param _txInputVector All transaction inputs prepended by the number of
    ///        inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector All transaction outputs prepended by the number
    ///         of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime Final 4 bytes of the transaction.
    /// @param _fundingOutputIndex Index of funding output in _txOutputVector
    ///        (0-indexed).
    /// @param _merkleProof The merkle proof of transaction inclusion in a
    ///        block.
    /// @param _txIndexInBlock Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders Single bytestring of 80-byte bitcoin headers,
    ///        lowest height first.
    function provideBTCFundingProof(
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public { // not external to allow bytes memory parameters
        self.provideBTCFundingProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _fundingOutputIndex,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );
    }

//---------------------------- LIQUIDATION FLOW ------------------------------//

    /// @notice Notify the contract that the signers are undercollateralized.
    /// @dev This call will revert if the signers are not in fact
    ///      undercollateralized according to the price feed. After
    ///      TBTCConstants.COURTESY_CALL_DURATION, courtesy call times out and
    ///      regular abort liquidation occurs; see
    ///      `notifyCourtesyTimedOut`.
    function notifyCourtesyCall() external {
        self.notifyCourtesyCall();
    }

    /// @notice Notify the contract that the signers' bond value has recovered
    ///         enough to be considered sufficiently collateralized.
    /// @dev This call will revert if collateral is still below the
    ///      undercollateralized threshold according to the price feed.
    function exitCourtesyCall() external {
        self.exitCourtesyCall();
    }

    /// @notice Notify the contract that the courtesy period has expired and the
    ///         deposit should move into liquidation.
    /// @dev This call will revert if the courtesy call period has not in fact
    ///      expired or is not in the courtesy call state. Courtesy call
    ///      expiration is treated as an abort, and is handled by seizing signer
    ///      bonds and putting them up for auction for the lot size amount in
    ///      TBTC (see `purchaseSignerBondsAtAuction`). Emits a
    ///      LiquidationStarted event. The caller is captured as the liquidation
    ///      initiator, and is eligible for 50% of any bond left after the
    ///      auction is completed.
    function notifyCourtesyCallExpired() external {
        self.notifyCourtesyCallExpired();
    }

    /// @notice Notify the contract that the signers are undercollateralized.
    /// @dev Calls out to the system for oracle info.
    /// @dev This call will revert if the signers are not in fact severely
    ///      undercollateralized according to the price feed. Severe
    ///      undercollateralization is treated as an abort, and is handled by
    ///      seizing signer bonds and putting them up for auction in exchange
    ///      for the lot size amount in TBTC (see
    ///      `purchaseSignerBondsAtAuction`). Emits a LiquidationStarted event.
    ///      The caller is captured as the liquidation initiator, and is
    ///      eligible for 50% of any bond left after the auction is completed.
    function notifyUndercollateralizedLiquidation() external {
        self.notifyUndercollateralizedLiquidation();
    }

    /// @notice Anyone can provide a signature corresponding to the signers'
    ///         public key that was not requested to prove fraud. A redemption
    ///         request and a redemption fee increase are the only ways to
    ///         request a signature from the signers.
    /// @dev This call will revert if the underlying keep cannot verify that
    ///      there was fraud. Fraud is handled by seizing signer bonds and
    ///      putting them up for auction in exchange for the lot size amount in
    ///      TBTC (see `purchaseSignerBondsAtAuction`). Emits a
    ///      LiquidationStarted event. The caller is captured as the liquidation
    ///      initiator, and is eligible for any bond left after the auction is
    ///      completed.
    /// @param  _v Signature recovery value.
    /// @param  _r Signature R value.
    /// @param  _s Signature S value.
    /// @param _signedDigest The digest signed by the signature (v,r,s) tuple.
    /// @param _preimage The sha256 preimage of the digest.
    function provideECDSAFraudProof(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public { // not external to allow bytes memory parameters
        self.provideECDSAFraudProof(_v, _r, _s, _signedDigest, _preimage);
    }

    /// @notice Notify the contract that the signers have failed to produce a
    ///         signature for a redemption request in the allotted time.
    /// @dev This is considered an abort, and is punished by seizing signer
    ///      bonds and putting them up for auction. Emits a LiquidationStarted
    ///      event and a Liquidated event and sends the full signer bond to the
    ///      redeemer. Reverts if the deposit is not currently awaiting a
    ///      signature or if the allotted time has not yet elapsed. The caller
    ///      is captured as the liquidation initiator, and is eligible for 50%
    ///      of any bond left after the auction is completed.
    function notifyRedemptionSignatureTimedOut() external {
        self.notifyRedemptionSignatureTimedOut();
    }

    /// @notice Notify the contract that the deposit has failed to receive a
    ///         redemption proof in the allotted time.
    /// @dev This call will revert if the deposit is not currently awaiting a
    ///      signature or if the allotted time has not yet elapsed. This is
    ///      considered an abort, and is punished by seizing signer bonds and
    ///      putting them up for auction for the lot size amount in TBTC (see
    ///      `purchaseSignerBondsAtAuction`). Emits a LiquidationStarted event.
    ///      The caller is captured as the liquidation initiator, and
    ///      is eligible for 50% of any bond left after the auction is
    ///     completed.
    function notifyRedemptionProofTimedOut() external {
        self.notifyRedemptionProofTimedOut();
    }

    /// @notice Closes an auction and purchases the signer bonds by transferring
    ///         the lot size in TBTC to the redeemer, if there is one, or to the
    ///         TDT holder if not. Any bond amount that is not currently up for
    ///         auction is either made available for the liquidation initiator
    ///         to withdraw (for fraud) or split 50-50 between the initiator and
    ///         the signers (for abort or collateralization issues).
    /// @dev The amount of ETH given for the transferred TBTC can be read using
    ///      the `auctionValue` function; note, however, that the function's
    ///      value is only static during the specific block it is queried, as it
    ///      varies by block timestamp.
    function purchaseSignerBondsAtAuction() external {
        self.purchaseSignerBondsAtAuction();
    }

//---------------------------- REDEMPTION FLOW -------------------------------//

    /// @notice Get TBTC amount required for redemption by a specified
    ///         _redeemer.
    /// @dev This call will revert if redemption is not possible by _redeemer.
    /// @param _redeemer The deposit redeemer whose TBTC requirement is being
    ///        requested.
    /// @return The amount in TBTC needed by the `_redeemer` to redeem the
    ///         deposit.
    function getRedemptionTbtcRequirement(address _redeemer) external view returns (uint256){
        (uint256 tbtcPayment,,) = self.calculateRedemptionTbtcAmounts(_redeemer, false);
        return tbtcPayment;
    }

    /// @notice Get TBTC amount required for redemption assuming _redeemer
    ///         is this deposit's owner (TDT holder).
    /// @param _redeemer The assumed owner of the deposit's TDT .
    /// @return The amount in TBTC needed to redeem the deposit.
    function getOwnerRedemptionTbtcRequirement(address _redeemer) external view returns (uint256){
        (uint256 tbtcPayment,,) = self.calculateRedemptionTbtcAmounts(_redeemer, true);
        return tbtcPayment;
    }

    /// @notice Requests redemption of this deposit, meaning the transmission,
    ///         by the signers, of the deposit's UTXO to the specified Bitocin
    ///         output script. Requires approving the deposit to spend the
    ///         amount of TBTC needed to redeem.
    /// @dev The amount of TBTC needed to redeem can be looked up using the
    ///      `getRedemptionTbtcRequirement` or `getOwnerRedemptionTbtcRequirement`
    ///      functions.
    /// @param  _outputValueBytes The 8-byte little-endian output size. The
    ///         difference between this value and the lot size of the deposit
    ///         will be paid as a fee to the Bitcoin miners when the signed
    ///         transaction is broadcast.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output
    ///         script.
    function requestRedemption(
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript
    ) public { // not external to allow bytes memory parameters
        self.requestRedemption(_outputValueBytes, _redeemerOutputScript);
    }

    /// @notice Anyone may provide a withdrawal signature if it was requested.
    /// @dev The signers will be penalized if this function is not called
    ///      correctly within `TBTCConstants.REDEMPTION_SIGNATURE_TIMEOUT`
    ///      seconds of a redemption request or fee increase being received.
    /// @param _v Signature recovery value.
    /// @param _r Signature R value.
    /// @param _s Signature S value. Should be in the low half of secp256k1
    ///        curve's order.
    function provideRedemptionSignature(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        self.provideRedemptionSignature(_v, _r, _s);
    }

    /// @notice Anyone may request a signature for a transaction with an
    ///         increased Bitcoin transaction fee.
    /// @dev This call will revert if the fee is already at its maximum, or if
    ///      the new requested fee is not a multiple of the initial requested
    ///      fee. Transaction fees can only be bumped by the amount of the
    ///      initial requested fee. Calling this sends the deposit back to
    ///      the `AWAITING_WITHDRAWAL_SIGNATURE` state and requires the signers
    ///      to `provideRedemptionSignature` for the new output value in a
    ///      timely fashion.
    /// @param _previousOutputValueBytes The previous output's value.
    /// @param _newOutputValueBytes The new output's value.
    function increaseRedemptionFee(
        bytes8 _previousOutputValueBytes,
        bytes8 _newOutputValueBytes
    ) external {
        self.increaseRedemptionFee(_previousOutputValueBytes, _newOutputValueBytes);
    }

    /// @notice Anyone may submit a redemption proof to the deposit showing that
    ///         a transaction was submitted and sufficiently confirmed on the
    ///         Bitcoin chain transferring the deposit lot size's amount of BTC
    ///         from the signer-controlled private key corresponding to this
    ///         deposit to the requested redemption output script. This will
    ///         move the deposit into a redeemed state.
    /// @dev Takes a pre-parsed transaction and calculates values needed to
    ///      verify funding. Signers can have their bonds seized if this is not
    ///      called within `TBTCConstants.REDEMPTION_PROOF_TIMEOUT` seconds of
    ///      a redemption signature being provided.
    /// @param _txVersion Transaction version number (4-byte little-endian).
    /// @param _txInputVector All transaction inputs prepended by the number of
    ///        inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector All transaction outputs prepended by the number
    ///         of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime Final 4 bytes of the transaction.
    /// @param _merkleProof The merkle proof of transaction inclusion in a
    ///        block.
    /// @param _txIndexInBlock Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders Single bytestring of 80-byte bitcoin headers,
    ///        lowest height first.
    function provideRedemptionProof(
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public { // not external to allow bytes memory parameters
        self.provideRedemptionProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );
    }

//--------------------------- MUTATING HELPERS -------------------------------//

    /// @notice This function can only be called by the deposit factory; use
    ///         `DepositFactory.createDeposit` to create a new deposit.
    /// @dev Initializes a new deposit clone with the base state for the
    ///      deposit.
    /// @param _tbtcSystem `TBTCSystem` contract. More info in `TBTCSystem`.
    /// @param _tbtcToken `TBTCToken` contract. More info in TBTCToken`.
    /// @param _tbtcDepositToken `TBTCDepositToken` (TDT) contract. More info in
    ///        `TBTCDepositToken`.
    /// @param _feeRebateToken `FeeRebateToken` (FRT) contract. More info in
    ///        `FeeRebateToken`.
    /// @param _vendingMachineAddress `VendingMachine` address. More info in
    ///        `VendingMachine`.
    /// @param _lotSizeSatoshis The minimum amount of satoshi the funder is
    ///                         required to send. This is also the amount of
    ///                         TBTC the TDT holder will be eligible to mint:
    ///                         (10**7 satoshi == 0.1 BTC == 0.1 TBTC).
    function initializeDeposit(
        ITBTCSystem _tbtcSystem,
        TBTCToken _tbtcToken,
        IERC721 _tbtcDepositToken,
        FeeRebateToken _feeRebateToken,
        address _vendingMachineAddress,
        uint64 _lotSizeSatoshis
    ) public onlyFactory payable {
        self.tbtcSystem = _tbtcSystem;
        self.tbtcToken = _tbtcToken;
        self.tbtcDepositToken = _tbtcDepositToken;
        self.feeRebateToken = _feeRebateToken;
        self.vendingMachineAddress = _vendingMachineAddress;
        self.initialize(_lotSizeSatoshis);
    }

    /// @notice This function can only be called by the vending machine.
    /// @dev Performs the same action as requestRedemption, but transfers
    ///      ownership of the deposit to the specified _finalRecipient. Used as
    ///      a utility helper for the vending machine's shortcut
    ///      TBTC->redemption path.
    /// @param  _outputValueBytes The 8-byte little-endian output size.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _finalRecipient     The address to receive the TDT and later be recorded as deposit redeemer.
    function transferAndRequestRedemption(
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _finalRecipient
    ) public { // not external to allow bytes memory parameters
        require(
            msg.sender == self.vendingMachineAddress,
            "Only the vending machine can call transferAndRequestRedemption"
        );
        self.transferAndRequestRedemption(
            _outputValueBytes,
            _redeemerOutputScript,
            _finalRecipient
        );
    }

    /// @notice Withdraw the ETH balance of the deposit allotted to the caller.
    /// @dev Withdrawals can only happen when a contract is in an end-state.
    function withdrawFunds() external {
        self.withdrawFunds();
    }
}
