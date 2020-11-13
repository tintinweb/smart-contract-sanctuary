pragma solidity ^0.6.0;

import "../../utils/GasBurner.sol";
import "../../auth/ProxyPermission.sol";

import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ILendingPool.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ProxyRegistryInterface.sol";

import "../helpers/CreamSaverHelper.sol";

/// @title Imports cream position from the account to DSProxy
contract CreamImportTaker is CreamSaverHelper, ProxyPermission, GasBurner {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant CREAM_IMPORT_FLASH_LOAN = 0x24F4aC0Fe758c45cf8425D8Fbdd608cca9A7dBf8;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must approve cream_IMPORT_FLASH_LOAN to pull _cCollateralToken
    /// @param _cCollateralToken Collateral we are moving to DSProxy
    /// @param _cBorrowToken Borrow token we are moving to DSProxy
    function importLoan(address _cCollateralToken, address _cBorrowToken) external burnGas(20) {
        address proxy = getProxy();

        uint loanAmount = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(msg.sender);
        bytes memory paramsData = abi.encode(_cCollateralToken, _cBorrowToken, msg.sender, proxy);

        givePermission(CREAM_IMPORT_FLASH_LOAN);

        lendingPool.flashLoan(CREAM_IMPORT_FLASH_LOAN, getUnderlyingAddr(_cBorrowToken), loanAmount, paramsData);

        removePermission(CREAM_IMPORT_FLASH_LOAN);

        logger.Log(address(this), msg.sender, "CreamImport", abi.encode(loanAmount, 0, _cCollateralToken));
    }

    /// @notice Gets proxy address, if user doesn't has DSProxy build it
    /// @return proxy DsProxy address
    function getProxy() internal returns (address proxy) {
        proxy = ProxyRegistryInterface(PROXY_REGISTRY_ADDRESS).proxies(msg.sender);

        if (proxy == address(0)) {
            proxy = ProxyRegistryInterface(PROXY_REGISTRY_ADDRESS).build(msg.sender);
        }

    }
}
