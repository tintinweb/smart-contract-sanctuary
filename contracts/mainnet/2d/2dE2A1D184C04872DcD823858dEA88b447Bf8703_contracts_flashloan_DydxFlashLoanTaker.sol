pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../auth/ProxyPermission.sol";
import "../utils/DydxFlashLoanBase.sol";
import "../loggers/DefisaverLogger.sol";
import "../interfaces/ERC20.sol";


/// @title Takes flash loan
contract DyDxFlashLoanTaker is DydxFlashLoanBase, ProxyPermission {

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    /// @notice Takes flash loan for _receiver
    /// @dev Receiver must send back WETH + 2 wei after executing transaction
    /// @dev Method is meant to be called from proxy and proxy will give authorization to _receiver
    /// @param _receiver Address of funds receiver
    /// @param _ethAmount ETH amount that needs to be pulled from dydx    
    /// @param _encodedData Bytes with packed data
    function takeLoan(address _receiver, uint256 _ethAmount, bytes memory _encodedData) public {
        ISoloMargin solo = ISoloMargin(SOLO_MARGIN_ADDRESS);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(WETH_ADDR);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_ethAmount);
        ERC20(WETH_ADDR).approve(SOLO_MARGIN_ADDRESS, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _ethAmount, _receiver);
        operations[1] = _getCallAction(
            _encodedData,
            _receiver
        );
        operations[2] = _getDepositAction(marketId, repayAmount, address(this));

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        givePermission(_receiver);
        solo.operate(accountInfos, operations);
        removePermission(_receiver);

        DefisaverLogger(DEFISAVER_LOGGER).Log(address(this), msg.sender, "DyDxFlashLoanTaken", abi.encode(_receiver, _ethAmount, _encodedData));
    }
}