pragma solidity 0.5.17;

import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {IBondedECDSAKeep} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {DepositStates} from "./DepositStates.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";
import {OutsourceDepositLogging} from "./OutsourceDepositLogging.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";

library DepositLiquidation {

    using BTCUtils for bytes;
    using BytesLib for bytes;
    using SafeMath for uint256;
    using SafeMath for uint64;

    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;
    using OutsourceDepositLogging for DepositUtils.Deposit;

    /// @notice Notifies the keep contract of fraud. Reverts if not fraud.
    /// @dev Calls out to the keep contract. this could get expensive if preimage
    ///      is large.
    /// @param  _d Deposit storage pointer.
    /// @param  _v Signature recovery value.
    /// @param  _r Signature R value.
    /// @param  _s Signature S value.
    /// @param _signedDigest The digest signed by the signature vrs tuple.
    /// @param _preimage The sha256 preimage of the digest.
    function submitSignatureFraud(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.submitSignatureFraud(_v, _r, _s, _signedDigest, _preimage);
    }

    /// @notice     Determines the collateralization percentage of the signing group.
    /// @dev        Compares the bond value and lot value.
    /// @param _d   Deposit storage pointer.
    /// @return     Collateralization percentage as uint.
    function collateralizationPercentage(DepositUtils.Deposit storage _d) public view returns (uint256) {

        // Determine value of the lot in wei
        uint256 _satoshiPrice = _d.fetchBitcoinPrice();
        uint64 _lotSizeSatoshis = _d.lotSizeSatoshis;
        uint256 _lotValue = _lotSizeSatoshis.mul(_satoshiPrice);

        // Amount of wei the signers have
        uint256 _bondValue = _d.fetchBondAmount();

        // This converts into a percentage
        return (_bondValue.mul(100).div(_lotValue));
    }

    /// @dev              Starts signer liquidation by seizing signer bonds.
    ///                   If the deposit is currently being redeemed, the redeemer
    ///                   receives the full bond value; otherwise, a falling price auction
    ///                   begins to buy 1 TBTC in exchange for a portion of the seized bonds;
    ///                   see purchaseSignerBondsAtAuction().
    /// @param _wasFraud  True if liquidation is being started due to fraud, false if for any other reason.
    /// @param _d         Deposit storage pointer.
    function startLiquidation(DepositUtils.Deposit storage _d, bool _wasFraud) internal {
        _d.logStartedLiquidation(_wasFraud);

        uint256 seized = _d.seizeSignerBonds();
        address redeemerAddress = _d.redeemerAddress;

        // Reclaim used state for gas savings
        _d.redemptionTeardown();

        // If we see fraud in the redemption flow, we shouldn't go to auction.
        // Instead give the full signer bond directly to the redeemer.
        if (_d.inRedemption() && _wasFraud) {
            _d.setLiquidated();
            _d.enableWithdrawal(redeemerAddress, seized);
            _d.logLiquidated();
            return;
        }

        _d.liquidationInitiator = msg.sender;
        _d.liquidationInitiated = block.timestamp;  // Store the timestamp for auction

        if(_wasFraud){
            _d.setFraudLiquidationInProgress();
        }
        else{
            _d.setLiquidationInProgress();
        }
    }

    /// @notice                 Anyone can provide a signature that was not requested to prove fraud.
    /// @dev                    Calls out to the keep to verify if there was fraud.
    /// @param  _d              Deposit storage pointer.
    /// @param  _v              Signature recovery value.
    /// @param  _r              Signature R value.
    /// @param  _s              Signature S value.
    /// @param _signedDigest    The digest signed by the signature vrs tuple.
    /// @param _preimage        The sha256 preimage of the digest.
    function provideECDSAFraudProof(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public { // not external to allow bytes memory parameters
        require(
            !_d.inFunding(),
            "Use provideFundingECDSAFraudProof instead"
        );
        require(
            !_d.inSignerLiquidation(),
            "Signer liquidation already in progress"
        );
        require(!_d.inEndState(), "Contract has halted");
        submitSignatureFraud(_d, _v, _r, _s, _signedDigest, _preimage);

        startLiquidation(_d, true);
    }


    /// @notice     Closes an auction and purchases the signer bonds. Payout to buyer, funder, then signers if not fraud.
    /// @dev        For interface, reading auctionValue will give a past value. the current is better.
    /// @param  _d  Deposit storage pointer.
    function purchaseSignerBondsAtAuction(DepositUtils.Deposit storage _d) external {
        bool _wasFraud = _d.inFraudLiquidationInProgress();
        require(_d.inSignerLiquidation(), "No active auction");

        _d.setLiquidated();
        _d.logLiquidated();

        // Send the TBTC to the redeemer if they exist, otherwise to the TDT
        // holder. If the TDT holder is the Vending Machine, burn it to maintain
        // the peg. This is because, if there is a redeemer set here, the TDT
        // holder has already been made whole at redemption request time.
        address tbtcRecipient = _d.redeemerAddress;
        if (tbtcRecipient == address(0)) {
            tbtcRecipient = _d.depositOwner();
        }
        uint256 lotSizeTbtc = _d.lotSizeTbtc();

        require(_d.tbtcToken.balanceOf(msg.sender) >= lotSizeTbtc, "Not enough TBTC to cover outstanding debt");

        if(tbtcRecipient == _d.vendingMachineAddress){
            _d.tbtcToken.burnFrom(msg.sender, lotSizeTbtc);  // burn minimal amount to cover size
        }
        else{
            _d.tbtcToken.transferFrom(msg.sender, tbtcRecipient, lotSizeTbtc);
        }

        // Distribute funds to auction buyer
        uint256 valueToDistribute = _d.auctionValue();
        _d.enableWithdrawal(msg.sender, valueToDistribute);

        // Send any TBTC left to the Fee Rebate Token holder
        _d.distributeFeeRebate();

        // For fraud, pay remainder to the liquidation initiator.
        // For non-fraud, split 50-50 between initiator and signers. if the transfer amount is 1,
        // division will yield a 0 value which causes a revert; instead,
        // we simply ignore such a tiny amount and leave some wei dust in escrow
        uint256 contractEthBalance = address(this).balance;
        address payable initiator = _d.liquidationInitiator;

        if (initiator == address(0)){
            initiator = address(0xdead);
        }
        if (contractEthBalance > valueToDistribute + 1) {
            uint256 remainingUnallocated = contractEthBalance.sub(valueToDistribute);
            if (_wasFraud) {
                _d.enableWithdrawal(initiator, remainingUnallocated);
            } else {
                // There will always be a liquidation initiator.
                uint256 split = remainingUnallocated.div(2);
                _d.pushFundsToKeepGroup(split);
                _d.enableWithdrawal(initiator, remainingUnallocated.sub(split));
            }
        }
    }

    /// @notice     Notify the contract that the signers are undercollateralized.
    /// @dev        Calls out to the system for oracle info.
    /// @param  _d  Deposit storage pointer.
    function notifyCourtesyCall(DepositUtils.Deposit storage _d) external  {
        require(_d.inActive(), "Can only courtesy call from active state");
        require(collateralizationPercentage(_d) < _d.undercollateralizedThresholdPercent, "Signers have sufficient collateral");
        _d.courtesyCallInitiated = block.timestamp;
        _d.setCourtesyCall();
        _d.logCourtesyCalled();
    }

    /// @notice     Goes from courtesy call to active.
    /// @dev        Only callable if collateral is sufficient and the deposit is not expiring.
    /// @param  _d  Deposit storage pointer.
    function exitCourtesyCall(DepositUtils.Deposit storage _d) external {
        require(_d.inCourtesyCall(), "Not currently in courtesy call");
        require(collateralizationPercentage(_d) >= _d.undercollateralizedThresholdPercent, "Deposit is still undercollateralized");
        _d.setActive();
        _d.logExitedCourtesyCall();
    }

    /// @notice     Notify the contract that the signers are undercollateralized.
    /// @dev        Calls out to the system for oracle info.
    /// @param  _d  Deposit storage pointer.
    function notifyUndercollateralizedLiquidation(DepositUtils.Deposit storage _d) external {
        require(_d.inRedeemableState(), "Deposit not in active or courtesy call");
        require(collateralizationPercentage(_d) < _d.severelyUndercollateralizedThresholdPercent, "Deposit has sufficient collateral");
        startLiquidation(_d, false);
    }

    /// @notice     Notifies the contract that the courtesy period has elapsed.
    /// @dev        This is treated as an abort, rather than fraud.
    /// @param  _d  Deposit storage pointer.
    function notifyCourtesyCallExpired(DepositUtils.Deposit storage _d) external {
        require(_d.inCourtesyCall(), "Not in a courtesy call period");
        require(block.timestamp >= _d.courtesyCallInitiated.add(TBTCConstants.getCourtesyCallTimeout()), "Courtesy period has not elapsed");
        startLiquidation(_d, false);
    }
}
