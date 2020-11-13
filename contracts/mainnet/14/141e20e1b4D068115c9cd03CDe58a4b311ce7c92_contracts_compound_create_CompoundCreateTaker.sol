pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/ILendingPool.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../auth/ProxyPermission.sol";
import "../../exchange/SaverExchangeCore.sol";
import "../../utils/SafeERC20.sol";

/// @title Opens compound positions with a leverage
contract CompoundCreateTaker is ProxyPermission {
    using SafeERC20 for ERC20;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    struct CreateInfo {
        address cCollAddress;
        address cBorrowAddress;
        uint depositAmount;
    }

    /// @notice Main function which will take a FL and open a leverage position
    /// @dev Call through DSProxy, if _exchangeData.destAddr is a token approve DSProxy
    /// @param _createInfo [cCollAddress, cBorrowAddress, depositAmount]
    /// @param _exchangeData Exchange data struct
    function openLeveragedLoan(
        CreateInfo memory _createInfo,
        SaverExchangeCore.ExchangeData memory _exchangeData,
        address payable _compReceiver
    ) public payable {
        uint loanAmount = _exchangeData.srcAmount;

        // Pull tokens from user
        if (_exchangeData.destAddr != ETH_ADDRESS) {
            ERC20(_exchangeData.destAddr).safeTransferFrom(msg.sender, address(this), _createInfo.depositAmount);
        } else {
            require(msg.value >= _createInfo.depositAmount, "Must send correct amount of eth");
        }

        // Send tokens to FL receiver
        sendDeposit(_compReceiver, _exchangeData.destAddr);

        // Pack the struct data
        (uint[4] memory numData, address[6] memory cAddresses, bytes memory callData)
                                            = _packData(_createInfo, _exchangeData);
        bytes memory paramsData = abi.encode(numData, cAddresses, callData, address(this));

        givePermission(_compReceiver);

        lendingPool.flashLoan(_compReceiver, _exchangeData.srcAddr, loanAmount, paramsData);

        removePermission(_compReceiver);

        logger.Log(address(this), msg.sender, "CompoundLeveragedLoan",
            abi.encode(_exchangeData.srcAddr, _exchangeData.destAddr, _exchangeData.srcAmount, _exchangeData.destAmount));
    }

    function sendDeposit(address payable _compoundReceiver, address _token) internal {
        if (_token != ETH_ADDRESS) {
            ERC20(_token).safeTransfer(_compoundReceiver, ERC20(_token).balanceOf(address(this)));
        }

        _compoundReceiver.transfer(address(this).balance);
    }

    function _packData(
        CreateInfo memory _createInfo,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[4] memory numData, address[6] memory cAddresses, bytes memory callData) {

        numData = [
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x
        ];

        cAddresses = [
            _createInfo.cCollAddress,
            _createInfo.cBorrowAddress,
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr,
            exchangeData.wrapper
        ];

        callData = exchangeData.callData;
    }
}
