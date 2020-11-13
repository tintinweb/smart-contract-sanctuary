pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../auth/AdminAuth.sol";
import "../../auth/ProxyPermission.sol";
import "../../utils/DydxFlashLoanBase.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/TokenInterface.sol";
import "../../interfaces/ERC20.sol";

// take weth
// send weth to AaveImport
// approve AaveImport to manage proxy position
// call flashloan
// remove AaveImport
// log

/// @title Import Aave position from account to wallet
/// @dev Contract needs to have enough wei in WETH for all transactions (2 WETH wei per transaction)
contract AaveImportTaker is DydxFlashLoanBase, ProxyPermission {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable public constant AAVE_IMPORT = 0x56AC1EFC17ecDe083889520137B0cfb30d2cF384;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must send 2 wei with this transaction
    /// @dev User must approve AaveImport to pull _aCollateralToken
    /// @param _collateralToken Collateral token we are moving to DSProxy
    /// @param _borrowToken Borrow token we are moving to DSProxy
    /// @param _ethAmount ETH amount that needs to be pulled from dydx
    function importLoan(address _collateralToken, address _borrowToken, uint _ethAmount) public {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_ethAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _ethAmount, AAVE_IMPORT);
        operations[1] = _getCallAction(
            abi.encode(_collateralToken, _borrowToken, _ethAmount, msg.sender, address(this)),
            AAVE_IMPORT
        );
        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        givePermission(AAVE_IMPORT);
        solo.operate(accountInfos, operations);
        removePermission(AAVE_IMPORT);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "AaveImport", abi.encode(_collateralToken, _borrowToken));
    }
}