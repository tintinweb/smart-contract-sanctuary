pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ILendingPool.sol";
import "../../exchange/SaverExchangeCore.sol";

contract MCDCreateTaker {

    address payable public constant MCD_CREATE_FLASH_LOAN = 0xb09bCc172050fBd4562da8b229Cf3E45Dc3045A6;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant ETH_JOIN_ADDRESS = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // solhint-disable-next-line const-name-snakecase
    Manager public constant manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    // solhint-disable-next-line const-name-snakecase
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    struct CreateData {
        uint collAmount;
        uint daiAmount;
        address joinAddr;
    }

    function openWithLoan(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        CreateData memory _createData
    ) public payable {

        MCD_CREATE_FLASH_LOAN.transfer(msg.value); //0x fee


        if (_createData.joinAddr != ETH_JOIN_ADDRESS) {
            ERC20(getCollateralAddr(_createData.joinAddr)).transferFrom(msg.sender, address(this), _createData.collAmount);
            ERC20(getCollateralAddr(_createData.joinAddr)).transfer(MCD_CREATE_FLASH_LOAN, _createData.collAmount);
        }

        (uint[6] memory numData, address[5] memory addrData, bytes memory callData)
                                            = _packData(_createData, _exchangeData);
        bytes memory paramsData = abi.encode(numData, addrData, callData, address(this));

        lendingPool.flashLoan(MCD_CREATE_FLASH_LOAN, DAI_ADDRESS, _createData.daiAmount, paramsData);

        logger.Log(address(this), msg.sender, "MCDCreate", abi.encode(manager.last(address(this)), _createData.collAmount, _createData.daiAmount));
    }

    function getCollateralAddr(address _joinAddr) internal view returns (address) {
        return address(Join(_joinAddr).gem());
    }

    function _packData(
        CreateData memory _createData,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[6] memory numData, address[5] memory addrData, bytes memory callData) {

        numData = [
            _createData.collAmount,
            _createData.daiAmount,
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x
        ];

        addrData = [
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr,
            exchangeData.wrapper,
            _createData.joinAddr
        ];

        callData = exchangeData.callData;
    }
}
