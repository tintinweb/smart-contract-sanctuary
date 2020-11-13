pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../saver/MCDSaverProxy.sol";
import "../../exchange/SaverExchangeCore.sol";
import "../../utils/GasBurner.sol";

abstract contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external virtual;
}

contract MCDSaverTaker is MCDSaverProxy, GasBurner {

    address payable public constant MCD_SAVER_FLASH_LOAN = 0x28e444b53a9e7E3F6fFe50E93b18dCce7838551F;
    address public constant AAVE_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    function boostWithLoan(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr
    ) public payable burnGas(25) {
        uint256 maxDebt = getMaxDebt(_cdpId, manager.ilks(_cdpId));

        if (maxDebt >= _exchangeData.srcAmount) {
            boost(_exchangeData, _cdpId, _gasCost, _joinAddr);
            return;
        }

        MCD_SAVER_FLASH_LOAN.transfer(msg.value); // 0x fee

        uint256 loanAmount = sub(_exchangeData.srcAmount, maxDebt);
        uint maxLiq = getAvailableLiquidity(_joinAddr);

        loanAmount = loanAmount > maxLiq ? maxLiq : loanAmount;

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(packExchangeData(_exchangeData), _cdpId, _gasCost, _joinAddr, false);

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, DAI_ADDRESS, loanAmount, paramsData);

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 0);
    }

    function repayWithLoan(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr
    ) public payable burnGas(25) {
        uint256 maxColl = getMaxCollateral(_cdpId, manager.ilks(_cdpId), _joinAddr);

        if (maxColl >= _exchangeData.srcAmount) {
            repay(_exchangeData, _cdpId, _gasCost, _joinAddr);
            return;
        }

        MCD_SAVER_FLASH_LOAN.transfer(msg.value); // 0x fee

        uint256 loanAmount = sub(_exchangeData.srcAmount, maxColl);
        uint maxLiq = getAvailableLiquidity(_joinAddr);

        loanAmount = loanAmount > maxLiq ? maxLiq : loanAmount;

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(packExchangeData(_exchangeData), _cdpId, _gasCost, _joinAddr, true);

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, getAaveCollAddr(_joinAddr), loanAmount, paramsData);

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 0);
    }


    /// @notice Gets the maximum amount of debt available to generate
    /// @param _cdpId Id of the CDP
    /// @param _ilk Ilk of the CDP
    function getMaxDebt(uint256 _cdpId, bytes32 _ilk) public override view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    function getAaveCollAddr(address _joinAddr) internal view returns (address) {
        if (_joinAddr == 0x2F0b23f53734252Bda2277357e97e1517d6B042A
            || _joinAddr == 0x775787933e92b709f2a3C70aa87999696e74A9F8) {
            return KYBER_ETH_ADDRESS;
        } else {
            return getCollateralAddr(_joinAddr);
        }
    }

    function getAvailableLiquidity(address _joinAddr) internal view returns (uint liquidity) {
        address tokenAddr = getAaveCollAddr(_joinAddr);

        if (tokenAddr == KYBER_ETH_ADDRESS) {
            liquidity = AAVE_POOL_CORE.balance;
        } else {
            liquidity = ERC20(tokenAddr).balanceOf(AAVE_POOL_CORE);
        }
    }

     function _packData(
        uint _cdpId,
        uint _gasCost,
        address _joinAddr,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[6] memory numData, address[5] memory addrData, bytes memory callData) {

        numData = [
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x,
            _cdpId,
            _gasCost
        ];

        addrData = [
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr,
            exchangeData.wrapper,
            _joinAddr
        ];

        callData = exchangeData.callData;
    }

}
