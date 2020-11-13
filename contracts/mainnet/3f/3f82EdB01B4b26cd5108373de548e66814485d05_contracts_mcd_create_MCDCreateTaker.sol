pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ILendingPool.sol";
import "../../exchangeV3/DFSExchangeData.sol";
import "../../utils/SafeERC20.sol";

contract MCDCreateTaker {

    using SafeERC20 for ERC20;

    address payable public constant MCD_CREATE_FLASH_LOAN = 0x78aF7A2Ee6C2240c748aDdc42aBc9A693559dcaF;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

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
        DFSExchangeData.ExchangeData memory _exchangeData,
        CreateData memory _createData
    ) public payable {

        MCD_CREATE_FLASH_LOAN.transfer(msg.value); //0x fee


        if (!isEthJoinAddr(_createData.joinAddr)) {
            ERC20(getCollateralAddr(_createData.joinAddr)).safeTransferFrom(msg.sender, address(this), _createData.collAmount);
            ERC20(getCollateralAddr(_createData.joinAddr)).safeTransfer(MCD_CREATE_FLASH_LOAN, _createData.collAmount);
        }

        bytes memory packedData = _packData(_createData, _exchangeData);
        bytes memory paramsData = abi.encode(address(this), packedData);

        lendingPool.flashLoan(MCD_CREATE_FLASH_LOAN, DAI_ADDRESS, _createData.daiAmount, paramsData);

        logger.Log(address(this), msg.sender, "MCDCreate", abi.encode(manager.last(address(this)), _createData.collAmount, _createData.daiAmount));
    }

    function getCollateralAddr(address _joinAddr) internal view returns (address) {
        return address(Join(_joinAddr).gem());
    }

    /// @notice Checks if the join address is one of the Ether coll. types
    /// @param _joinAddr Join address to check
    function isEthJoinAddr(address _joinAddr) internal view returns (bool) {
        // if it's dai_join_addr don't check gem() it will fail
        if (_joinAddr == 0x9759A6Ac90977b93B58547b4A71c78317f391A28) return false;

        // if coll is weth it's and eth type coll
        if (address(Join(_joinAddr).gem()) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            return true;
        }

        return false;
    }

    function _packData(
        CreateData memory _createData,
        DFSExchangeData.ExchangeData memory _exchangeData
    ) internal pure returns (bytes memory) {

        return abi.encode(_createData, _exchangeData);
    }
}
