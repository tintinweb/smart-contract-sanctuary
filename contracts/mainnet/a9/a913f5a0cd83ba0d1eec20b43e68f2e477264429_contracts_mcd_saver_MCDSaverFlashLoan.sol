pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../exchange/SaverExchangeCore.sol";

contract MCDSaverFlashLoan is MCDSaverProxy, AdminAuth, FlashLoanReceiverBase {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    struct SaverData {
        uint cdpId;
        uint gasCost;
        uint loanAmount;
        uint fee;
        address joinAddr;
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (
            bytes memory exDataBytes,
            uint cdpId,
            uint gasCost,
            address joinAddr,
            bool isRepay
        )
         = abi.decode(_params, (bytes,uint256,uint256,address,bool));

        ExchangeData memory exchangeData = unpackExchangeData(exDataBytes);

        SaverData memory saverData = SaverData({
            cdpId: cdpId,
            gasCost: gasCost,
            loanAmount: _amount,
            fee: _fee,
            joinAddr: joinAddr
        });

        if (isRepay) {
            repayWithLoan(exchangeData, saverData);
        } else {
            boostWithLoan(exchangeData, saverData);
        }

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function boostWithLoan(
        ExchangeData memory _exchangeData,
        SaverData memory _saverData
    ) internal {

        address user = getOwner(manager, _saverData.cdpId);

        // Draw users Dai
        uint maxDebt = getMaxDebt(_saverData.cdpId, manager.ilks(_saverData.cdpId));
        uint daiDrawn = drawDai(_saverData.cdpId, manager.ilks(_saverData.cdpId), maxDebt);

        // Calc. fees
        uint dsfFee = getFee((daiDrawn + _saverData.loanAmount), _saverData.gasCost, user);
        uint afterFee = (daiDrawn + _saverData.loanAmount) - dsfFee;

        // Swap
        _exchangeData.srcAmount = afterFee;
        (, uint swapedAmount) = _sell(_exchangeData);

        // Return collateral
        addCollateral(_saverData.cdpId, _saverData.joinAddr, swapedAmount);

        // Draw Dai to repay the flash loan
        drawDai(_saverData.cdpId,  manager.ilks(_saverData.cdpId), (_saverData.loanAmount + _saverData.fee));

        logger.Log(address(this), msg.sender, "MCDFlashBoost", abi.encode(_saverData.cdpId, owner, _exchangeData.srcAmount, swapedAmount));
    }

    function repayWithLoan(
        ExchangeData memory _exchangeData,
        SaverData memory _saverData
    ) internal {

        address user = getOwner(manager, _saverData.cdpId);
        bytes32 ilk = manager.ilks(_saverData.cdpId);

        // Draw collateral
        uint maxColl = getMaxCollateral(_saverData.cdpId, ilk, _saverData.joinAddr);
        uint collDrawn = drawCollateral(_saverData.cdpId, _saverData.joinAddr, maxColl);

        // Swap
        _exchangeData.srcAmount = (_saverData.loanAmount + collDrawn);
        (, uint swapedAmount) = _sell(_exchangeData);

        uint paybackAmount = (swapedAmount - getFee(swapedAmount, _saverData.gasCost, user));
        paybackAmount = limitLoanAmount(_saverData.cdpId, ilk, paybackAmount, user);

        // Payback the debt
        paybackDebt(_saverData.cdpId, ilk, paybackAmount, user);

        // Draw collateral to repay the flash loan
        drawCollateral(_saverData.cdpId, _saverData.joinAddr, (_saverData.loanAmount + _saverData.fee));

        logger.Log(address(this), msg.sender, "MCDFlashRepay", abi.encode(_saverData.cdpId, owner, _exchangeData.srcAmount, swapedAmount));
    }

    /// @notice Handles that the amount is not bigger than cdp debt and not dust
    function limitLoanAmount(uint _cdpId, bytes32 _ilk, uint _paybackAmount, address _owner) internal returns (uint256) {
        uint debt = getAllDebt(address(vat), manager.urns(_cdpId), manager.urns(_cdpId), _ilk);

        if (_paybackAmount > debt) {
            ERC20(DAI_ADDRESS).transfer(_owner, (_paybackAmount - debt));
            return debt;
        }

        uint debtLeft = debt - _paybackAmount;

        (,,,, uint dust) = vat.ilks(_ilk);
        dust = dust / 10**27;

        // Less than dust value
        if (debtLeft < dust) {
            uint amountOverDust = (dust - debtLeft);

            ERC20(DAI_ADDRESS).transfer(_owner, amountOverDust);

            return (_paybackAmount - amountOverDust);
        }

        return _paybackAmount;
    }

    receive() external override(FlashLoanReceiverBase, SaverExchangeCore) payable {}

}
