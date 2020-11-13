pragma solidity 0.5.17;

import {ValidateSPV} from "@summa-tx/bitcoin-spv-sol/contracts/ValidateSPV.sol";
import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {IBondedECDSAKeep} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {IERC721} from "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {DepositStates} from "./DepositStates.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";

library DepositUtils {

    using SafeMath for uint256;
    using SafeMath for uint64;
    using BytesLib for bytes;
    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using ValidateSPV for bytes;
    using ValidateSPV for bytes32;
    using DepositStates for DepositUtils.Deposit;

    struct Deposit {

        // SET DURING CONSTRUCTION
        ITBTCSystem tbtcSystem;
        TBTCToken tbtcToken;
        IERC721 tbtcDepositToken;
        FeeRebateToken feeRebateToken;
        address vendingMachineAddress;
        uint64 lotSizeSatoshis;
        uint8 currentState;
        uint16 signerFeeDivisor;
        uint16 initialCollateralizedPercent;
        uint16 undercollateralizedThresholdPercent;
        uint16 severelyUndercollateralizedThresholdPercent;
        uint256 keepSetupFee;

        // SET ON FRAUD
        uint256 liquidationInitiated;  // Timestamp of when liquidation starts
        uint256 courtesyCallInitiated; // When the courtesy call is issued
        address payable liquidationInitiator;

        // written when we request a keep
        address keepAddress;  // The address of our keep contract
        uint256 signingGroupRequestedAt;  // timestamp of signing group request

        // written when we get a keep result
        uint256 fundingProofTimerStart;  // start of the funding proof period. reused for funding fraud proof period
        bytes32 signingGroupPubkeyX;  // The X coordinate of the signing group's pubkey
        bytes32 signingGroupPubkeyY;  // The Y coordinate of the signing group's pubkey

        // INITIALLY WRITTEN BY REDEMPTION FLOW
        address payable redeemerAddress;  // The redeemer's address, used as fallback for fraud in redemption
        bytes redeemerOutputScript;  // The redeemer output script
        uint256 initialRedemptionFee;  // the initial fee as requested
        uint256 latestRedemptionFee; // the fee currently required by a redemption transaction
        uint256 withdrawalRequestTime;  // the most recent withdrawal request timestamp
        bytes32 lastRequestedDigest;  // the digest most recently requested for signing

        // written when we get funded
        bytes8 utxoValueBytes;  // LE uint. the size of the deposit UTXO in satoshis
        uint256 fundedAt; // timestamp when funding proof was received
        bytes utxoOutpoint;  // the 36-byte outpoint of the custodied UTXO

        /// @dev Map of ETH balances an address can withdraw after contract reaches ends-state.
        mapping(address => uint256) withdrawableAmounts;

        /// @dev Map of timestamps representing when transaction digests were approved for signing
        mapping (bytes32 => uint256) approvedDigests;
    }

    /// @notice Closes keep associated with the deposit.
    /// @dev Should be called when the keep is no longer needed and the signing
    /// group can disband.
    function closeKeep(DepositUtils.Deposit storage _d) internal {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.closeKeep();
    }

    /// @notice         Gets the current block difficulty.
    /// @dev            Calls the light relay and gets the current block difficulty.
    /// @return         The difficulty.
    function currentBlockDifficulty(Deposit storage _d) public view returns (uint256) {
        return _d.tbtcSystem.fetchRelayCurrentDifficulty();
    }

    /// @notice         Gets the previous block difficulty.
    /// @dev            Calls the light relay and gets the previous block difficulty.
    /// @return         The difficulty.
    function previousBlockDifficulty(Deposit storage _d) public view returns (uint256) {
        return _d.tbtcSystem.fetchRelayPreviousDifficulty();
    }

    /// @notice                     Evaluates the header difficulties in a proof.
    /// @dev                        Uses the light oracle to source recent difficulty.
    /// @param  _bitcoinHeaders     The header chain to evaluate.
    /// @return                     True if acceptable, otherwise revert.
    function evaluateProofDifficulty(Deposit storage _d, bytes memory _bitcoinHeaders) public view {
        uint256 _reqDiff;
        uint256 _current = currentBlockDifficulty(_d);
        uint256 _previous = previousBlockDifficulty(_d);
        uint256 _firstHeaderDiff = _bitcoinHeaders.extractTarget().calculateDifficulty();

        if (_firstHeaderDiff == _current) {
            _reqDiff = _current;
        } else if (_firstHeaderDiff == _previous) {
            _reqDiff = _previous;
        } else {
            revert("not at current or previous difficulty");
        }

        uint256 _observedDiff = _bitcoinHeaders.validateHeaderChain();

        require(_observedDiff != ValidateSPV.getErrBadLength(), "Invalid length of the headers chain");
        require(_observedDiff != ValidateSPV.getErrInvalidChain(), "Invalid headers chain");
        require(_observedDiff != ValidateSPV.getErrLowWork(), "Insufficient work in a header");

        require(
            _observedDiff >= _reqDiff.mul(TBTCConstants.getTxProofDifficultyFactor()),
            "Insufficient accumulated difficulty in header chain"
        );
    }

    /// @notice                 Syntactically check an SPV proof for a bitcoin transaction with its hash (ID).
    /// @dev                    Stateless SPV Proof verification documented elsewhere (see https://github.com/summa-tx/bitcoin-spv).
    /// @param _d               Deposit storage pointer.
    /// @param _txId            The bitcoin txid of the tx that is purportedly included in the header chain.
    /// @param _merkleProof     The merkle proof of inclusion of the tx in the bitcoin block.
    /// @param _txIndexInBlock  The index of the tx in the Bitcoin block (0-indexed).
    /// @param _bitcoinHeaders  An array of tightly-packed bitcoin headers.
    function checkProofFromTxId(
        Deposit storage _d,
        bytes32 _txId,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public view{
        require(
            _txId.prove(
                _bitcoinHeaders.extractMerkleRootLE().toBytes32(),
                _merkleProof,
                _txIndexInBlock
            ),
            "Tx merkle proof is not valid for provided header and txId");
        evaluateProofDifficulty(_d, _bitcoinHeaders);
    }

    /// @notice                     Find and validate funding output in transaction output vector using the index.
    /// @dev                        Gets `_fundingOutputIndex` output from the output vector and validates if it is
    ///                             a p2wpkh output with public key hash matching this deposit's public key hash.
    /// @param _d                   Deposit storage pointer.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC outputs.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector.
    /// @return                     Funding value.
    function findAndParseFundingOutput(
        DepositUtils.Deposit storage _d,
        bytes memory _txOutputVector,
        uint8 _fundingOutputIndex
    ) public view returns (bytes8) {
        bytes8 _valueBytes;
        bytes memory _output;

        // Find the output paying the signer PKH
        _output = _txOutputVector.extractOutputAtIndex(_fundingOutputIndex);

        require(
            keccak256(_output.extractHash()) == keccak256(abi.encodePacked(signerPKH(_d))),
            "Could not identify output funding the required public key hash"
        );
        require(
            _output.length == 31 &&
                _output.keccak256Slice(8, 23) == keccak256(abi.encodePacked(hex"160014", signerPKH(_d))),
            "Funding transaction output type unsupported: only p2wpkh outputs are supported"
        );

        _valueBytes = bytes8(_output.slice(0, 8).toBytes32());
        return _valueBytes;
    }

    /// @notice                     Validates the funding tx and parses information from it.
    /// @dev                        Takes a pre-parsed transaction and calculates values needed to verify funding.
    /// @param  _d                  Deposit storage pointer.
    /// @param _txVersion           Transaction version number (4-byte LE).
    /// @param _txInputVector       All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime          Final 4 bytes of the transaction.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector (0-indexed).
    /// @param _merkleProof         The merkle proof of transaction inclusion in a block.
    /// @param _txIndexInBlock      Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders      Single bytestring of 80-byte bitcoin headers, lowest height first.
    /// @return                     The 8-byte LE UTXO size in satoshi, the 36byte outpoint.
    function validateAndParseFundingSPVProof(
        DepositUtils.Deposit storage _d,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public view returns (bytes8 _valueBytes, bytes memory _utxoOutpoint){ // not external to allow bytes memory parameters
        require(_txInputVector.validateVin(), "invalid input vector provided");
        require(_txOutputVector.validateVout(), "invalid output vector provided");

        bytes32 txID = abi.encodePacked(_txVersion, _txInputVector, _txOutputVector, _txLocktime).hash256();

        _valueBytes = findAndParseFundingOutput(_d, _txOutputVector, _fundingOutputIndex);

        require(bytes8LEToUint(_valueBytes) >= _d.lotSizeSatoshis, "Deposit too small");

        checkProofFromTxId(_d, txID, _merkleProof, _txIndexInBlock, _bitcoinHeaders);

        // The utxoOutpoint is the LE txID plus the index of the output as a 4-byte LE int
        // _fundingOutputIndex is a uint8, so we know it is only 1 byte
        // Therefore, pad with 3 more bytes
        _utxoOutpoint = abi.encodePacked(txID, _fundingOutputIndex, hex"000000");
    }

    /// @notice Retreive the remaining term of the deposit
    /// @dev    The return value is not guaranteed since block.timestmap can be lightly manipulated by miners.
    /// @return The remaining term of the deposit in seconds. 0 if already at term
    function remainingTerm(DepositUtils.Deposit storage _d) public view returns(uint256){
        uint256 endOfTerm = _d.fundedAt.add(TBTCConstants.getDepositTerm());
        if(block.timestamp < endOfTerm ) {
            return endOfTerm.sub(block.timestamp);
        }
        return 0;
    }

    /// @notice     Calculates the amount of value at auction right now.
    /// @dev        We calculate the % of the auction that has elapsed, then scale the value up.
    /// @param _d   Deposit storage pointer.
    /// @return     The value in wei to distribute in the auction at the current time.
    function auctionValue(Deposit storage _d) external view returns (uint256) {
        uint256 _elapsed = block.timestamp.sub(_d.liquidationInitiated);
        uint256 _available = address(this).balance;
        if (_elapsed > TBTCConstants.getAuctionDuration()) {
            return _available;
        }

        // This should make a smooth flow from base% to 100%
        uint256 _basePercentage = getAuctionBasePercentage(_d);
        uint256 _elapsedPercentage = uint256(100).sub(_basePercentage).mul(_elapsed).div(TBTCConstants.getAuctionDuration());
        uint256 _percentage = _basePercentage.add(_elapsedPercentage);

        return _available.mul(_percentage).div(100);
    }

    /// @notice         Gets the lot size in erc20 decimal places (max 18)
    /// @return         uint256 lot size in 10**18 decimals.
    function lotSizeTbtc(Deposit storage _d) public view returns (uint256){
        return _d.lotSizeSatoshis.mul(TBTCConstants.getSatoshiMultiplier());
    }

    /// @notice         Determines the fees due to the signers for work performed.
    /// @dev            Signers are paid based on the TBTC issued.
    /// @return         Accumulated fees in 10**18 decimals.
    function signerFeeTbtc(Deposit storage _d) public view returns (uint256) {
        return lotSizeTbtc(_d).div(_d.signerFeeDivisor);
    }

    /// @notice             Determines the prefix to the compressed public key.
    /// @dev                The prefix encodes the parity of the Y coordinate.
    /// @param  _pubkeyY    The Y coordinate of the public key.
    /// @return             The 1-byte prefix for the compressed key.
    function determineCompressionPrefix(bytes32 _pubkeyY) public pure returns (bytes memory) {
        if(uint256(_pubkeyY) & 1 == 1) {
            return hex"03";  // Odd Y
        } else {
            return hex"02";  // Even Y
        }
    }

    /// @notice             Compresses a public key.
    /// @dev                Converts the 64-byte key to a 33-byte key, bitcoin-style.
    /// @param  _pubkeyX    The X coordinate of the public key.
    /// @param  _pubkeyY    The Y coordinate of the public key.
    /// @return             The 33-byte compressed pubkey.
    function compressPubkey(bytes32 _pubkeyX, bytes32 _pubkeyY) public pure returns (bytes memory) {
        return abi.encodePacked(determineCompressionPrefix(_pubkeyY), _pubkeyX);
    }

    /// @notice    Returns the packed public key (64 bytes) for the signing group.
    /// @dev       We store it as 2 bytes32, (2 slots) then repack it on demand.
    /// @return    64 byte public key.
    function signerPubkey(Deposit storage _d) external view returns (bytes memory) {
        return abi.encodePacked(_d.signingGroupPubkeyX, _d.signingGroupPubkeyY);
    }

    /// @notice    Returns the Bitcoin pubkeyhash (hash160) for the signing group.
    /// @dev       This is used in bitcoin output scripts for the signers.
    /// @return    20-bytes public key hash.
    function signerPKH(Deposit storage _d) public view returns (bytes20) {
        bytes memory _pubkey = compressPubkey(_d.signingGroupPubkeyX, _d.signingGroupPubkeyY);
        bytes memory _digest = _pubkey.hash160();
        return bytes20(_digest.toAddress(0));  // dirty solidity hack
    }

    /// @notice    Returns the size of the deposit UTXO in satoshi.
    /// @dev       We store the deposit as bytes8 to make signature checking easier.
    /// @return    UTXO value in satoshi.
    function utxoValue(Deposit storage _d) external view returns (uint256) {
        return bytes8LEToUint(_d.utxoValueBytes);
    }

    /// @notice     Gets the current price of Bitcoin in Ether.
    /// @dev        Polls the price feed via the system contract.
    /// @return     The current price of 1 sat in wei.
    function fetchBitcoinPrice(Deposit storage _d) external view returns (uint256) {
        return _d.tbtcSystem.fetchBitcoinPrice();
    }

    /// @notice     Fetches the Keep's bond amount in wei.
    /// @dev        Calls the keep contract to do so.
    /// @return     The amount of bonded ETH in wei.
    function fetchBondAmount(Deposit storage _d) external view returns (uint256) {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        return _keep.checkBondAmount();
    }

    /// @notice         Convert a LE bytes8 to a uint256.
    /// @dev            Do this by converting to bytes, then reversing endianness, then converting to int.
    /// @return         The uint256 represented in LE by the bytes8.
    function bytes8LEToUint(bytes8 _b) public pure returns (uint256) {
        return abi.encodePacked(_b).reverseEndianness().bytesToUint();
    }

    /// @notice         Gets timestamp of digest approval for signing.
    /// @dev            Identifies entry in the recorded approvals by keep ID and digest pair.
    /// @param _digest  Digest to check approval for.
    /// @return         Timestamp from the moment of recording the digest for signing.
    ///                 Returns 0 if the digest was not approved for signing.
    function wasDigestApprovedForSigning(Deposit storage _d, bytes32 _digest) external view returns (uint256) {
        return _d.approvedDigests[_digest];
    }

    /// @notice         Looks up the Fee Rebate Token holder.
    /// @return         The current token holder if the Token exists.
    ///                 address(0) if the token does not exist.
    function feeRebateTokenHolder(Deposit storage _d) public view returns (address payable) {
        address tokenHolder = address(0);
        if(_d.feeRebateToken.exists(uint256(address(this)))){
            tokenHolder = address(uint160(_d.feeRebateToken.ownerOf(uint256(address(this)))));
        }
        return address(uint160(tokenHolder));
    }

    /// @notice         Looks up the deposit beneficiary by calling the tBTC system.
    /// @dev            We cast the address to a uint256 to match the 721 standard.
    /// @return         The current deposit beneficiary.
    function depositOwner(Deposit storage _d) public view returns (address payable) {
        return address(uint160(_d.tbtcDepositToken.ownerOf(uint256(address(this)))));
    }

    /// @notice     Deletes state after termination of redemption process.
    /// @dev        We keep around the redeemer address so we can pay them out.
    function redemptionTeardown(Deposit storage _d) public {
        _d.redeemerOutputScript = "";
        _d.initialRedemptionFee = 0;
        _d.withdrawalRequestTime = 0;
        _d.lastRequestedDigest = bytes32(0);
    }


    /// @notice     Get the starting percentage of the bond at auction.
    /// @dev        This will return the same value regardless of collateral price.
    /// @return     The percentage of the InitialCollateralizationPercent that will result
    ///             in a 100% bond value base auction given perfect collateralization.
    function getAuctionBasePercentage(Deposit storage _d) internal view returns (uint256) {
        return uint256(10000).div(_d.initialCollateralizedPercent);
    }

    /// @notice     Seize the signer bond from the keep contract.
    /// @dev        we check our balance before and after.
    /// @return     The amount seized in wei.
    function seizeSignerBonds(Deposit storage _d) internal returns (uint256) {
        uint256 _preCallBalance = address(this).balance;

        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.seizeSignerBonds();

        uint256 _postCallBalance = address(this).balance;
        require(_postCallBalance > _preCallBalance, "No funds received, unexpected");
        return _postCallBalance.sub(_preCallBalance);
    }

    /// @notice     Adds a given amount to the withdraw allowance for the address.
    /// @dev        Withdrawals can only happen when a contract is in an end-state.
    function enableWithdrawal(DepositUtils.Deposit storage _d, address _withdrawer, uint256 _amount) internal {
        _d.withdrawableAmounts[_withdrawer] = _d.withdrawableAmounts[_withdrawer].add(_amount);
    }

    /// @notice     Withdraw caller's allowance.
    /// @dev        Withdrawals can only happen when a contract is in an end-state.
    function withdrawFunds(DepositUtils.Deposit storage _d) internal {
        uint256 available = _d.withdrawableAmounts[msg.sender];

        require(_d.inEndState(), "Contract not yet terminated");
        require(available > 0, "Nothing to withdraw");
        require(address(this).balance >= available, "Insufficient contract balance");

        // zero-out to prevent reentrancy
        _d.withdrawableAmounts[msg.sender] = 0;

        /* solium-disable-next-line security/no-call-value */
        (bool ok,) = msg.sender.call.value(available)("");
        require(
            ok,
            "Failed to send withdrawable amount to sender"
        );
    }

    /// @notice     Get the caller's withdraw allowance.
    /// @return     The caller's withdraw allowance in wei.
    function getWithdrawableAmount(DepositUtils.Deposit storage _d) internal view returns (uint256) {
        return _d.withdrawableAmounts[msg.sender];
    }

    /// @notice     Distributes the fee rebate to the Fee Rebate Token owner.
    /// @dev        Whenever this is called we are shutting down.
    function distributeFeeRebate(Deposit storage _d) internal {
        address rebateTokenHolder = feeRebateTokenHolder(_d);

        // exit the function if there is nobody to send the rebate to
        if(rebateTokenHolder == address(0)){
            return;
        }

        // pay out the rebate if it is available
        if(_d.tbtcToken.balanceOf(address(this)) >= signerFeeTbtc(_d)) {
            _d.tbtcToken.transfer(rebateTokenHolder, signerFeeTbtc(_d));
        }
    }

    /// @notice             Pushes ether held by the deposit to the signer group.
    /// @dev                Ether is returned to signing group members bonds.
    /// @param  _ethValue   The amount of ether to send.
    function pushFundsToKeepGroup(Deposit storage _d, uint256 _ethValue) internal {
        require(address(this).balance >= _ethValue, "Not enough funds to send");
        if(_ethValue > 0){
            IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
            _keep.returnPartialSignerBonds.value(_ethValue)();
        }
    }

    /// @notice Calculate TBTC amount required for redemption by a specified
    ///         _redeemer. If _assumeRedeemerHoldTdt is true, return the
    ///         requirement as if the redeemer holds this deposit's TDT.
    /// @dev Will revert if redemption is not possible by the current owner and
    ///      _assumeRedeemerHoldsTdt was not set. Setting
    ///      _assumeRedeemerHoldsTdt only when appropriate is the responsibility
    ///      of the caller; as such, this function should NEVER be publicly
    ///      exposed.
    /// @param _redeemer The account that should be treated as redeeming this
    ///        deposit  for the purposes of this calculation.
    /// @param _assumeRedeemerHoldsTdt If true, the calculation assumes that the
    ///        specified redeemer holds the TDT. If false, the calculation
    ///        checks the deposit owner against the specified _redeemer. Note
    ///        that this parameter should be false for all mutating calls to
    ///        preserve system correctness.
    /// @return A tuple of the amount the redeemer owes to the deposit to
    ///         initiate redemption, the amount that is owed to the TDT holder
    ///         when redemption is initiated, and the amount that is owed to the
    ///         FRT holder when redemption is initiated.
    function calculateRedemptionTbtcAmounts(
        DepositUtils.Deposit storage _d,
        address _redeemer,
        bool _assumeRedeemerHoldsTdt
    ) internal view returns (
        uint256 owedToDeposit,
        uint256 owedToTdtHolder,
        uint256 owedToFrtHolder
    ) {
        bool redeemerHoldsTdt =
            _assumeRedeemerHoldsTdt || depositOwner(_d) == _redeemer;
        bool preTerm = remainingTerm(_d) > 0 &&  !_d.inCourtesyCall();

        require(
            redeemerHoldsTdt || !preTerm,
            "Only TDT holder can redeem unless deposit is at-term or in COURTESY_CALL"
        );

        bool frtExists = feeRebateTokenHolder(_d) != address(0);
        bool redeemerHoldsFrt = feeRebateTokenHolder(_d) == _redeemer;
        uint256 signerFee = signerFeeTbtc(_d);

        uint256 feeEscrow = calculateRedemptionFeeEscrow(
            signerFee,
            preTerm,
            frtExists,
            redeemerHoldsTdt,
            redeemerHoldsFrt
        );

        // Base redemption + fee = total we need to have escrowed to start
        // redemption.
        owedToDeposit =
            calculateBaseRedemptionCharge(
                lotSizeTbtc(_d),
                redeemerHoldsTdt
            ).add(feeEscrow);

        // Adjust the amount owed to the deposit based on any balance the
        // deposit already has.
        uint256 balance = _d.tbtcToken.balanceOf(address(this));
        if (owedToDeposit > balance) {
            owedToDeposit = owedToDeposit.sub(balance);
        } else {
            owedToDeposit = 0;
        }

        // Pre-term, the FRT rebate is payed out, but if the redeemer holds the
        // FRT, the amount has already been subtracted from what is owed to the
        // deposit at this point (by calculateRedemptionFeeEscrow). This allows
        // the redeemer to simply *not pay* the fee rebate, rather than having
        // them pay it only to have it immediately returned.
        if (preTerm && frtExists && !redeemerHoldsFrt) {
            owedToFrtHolder = signerFee;
        }

        // The TDT holder gets any leftover balance.
        owedToTdtHolder =
            balance.add(owedToDeposit).sub(signerFee).sub(owedToFrtHolder);

        return (owedToDeposit, owedToTdtHolder, owedToFrtHolder);
    }

    /// @notice                    Get the base TBTC amount needed to redeem.
    /// @param _lotSize   The lot size to use for the base redemption charge.
    /// @param _redeemerHoldsTdt   True if the redeemer is the TDT holder.
    /// @return                    The amount in TBTC.
    function calculateBaseRedemptionCharge(
        uint256 _lotSize,
        bool _redeemerHoldsTdt
    ) internal pure returns (uint256){
        if (_redeemerHoldsTdt) {
            return 0;
        }
        return _lotSize;
    }

    /// @notice  Get fees owed for redemption
    /// @param signerFee The value of the signer fee for fee calculations.
    /// @param _preTerm               True if the Deposit is at-term or in courtesy_call.
    /// @param _frtExists     True if the FRT exists.
    /// @param _redeemerHoldsTdt     True if the the redeemer holds the TDT.
    /// @param _redeemerHoldsFrt     True if the redeemer holds the FRT.
    /// @return                      The fees owed in TBTC.
    function calculateRedemptionFeeEscrow(
        uint256 signerFee,
        bool _preTerm,
        bool _frtExists,
        bool _redeemerHoldsTdt,
        bool _redeemerHoldsFrt
    ) internal pure returns (uint256) {
        // Escrow the fee rebate so the FRT holder can be repaids, unless the
        // redeemer holds the FRT, in which case we simply don't require the
        // rebate from them.
        bool escrowRequiresFeeRebate =
            _preTerm && _frtExists && ! _redeemerHoldsFrt;

        bool escrowRequiresFee =
            _preTerm ||
            // If the FRT exists at term/courtesy call, the fee is
            // "required", but should already be escrowed before redemption.
            _frtExists ||
            // The TDT holder always owes fees if there is no FRT.
            _redeemerHoldsTdt;

        uint256 feeEscrow = 0;
        if (escrowRequiresFee) {
            feeEscrow += signerFee;
        }
        if (escrowRequiresFeeRebate) {
            feeEscrow += signerFee;
        }

        return feeEscrow;
    }
}
