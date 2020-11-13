// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./weth/WETH.sol";

import "./dydx/DydxFlashloanBase.sol";
import "./dydx/IDydx.sol";

import "./maker/IDssCdpManager.sol";
import "./maker/IDssProxyActions.sol";
import "./maker/DssActionsBase.sol";

import "./curve/ICurveFiCurve.sol";

import "./Constants.sol";

contract CloseShortDAI is ICallee, DydxFlashloanBase, DssActionsBase {
    struct CSDParams {
        uint256 cdpId; // CdpId to close
        address curvePool; // Which curve pool to use
        uint256 mintAmountDAI; // Amount of DAI to mint
        uint256 withdrawAmountUSDC; // Amount of USDC to withdraw from vault
        uint256 flashloanAmountWETH; // Amount of WETH flashloaned
    }

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        CSDParams memory csdp = abi.decode(data, (CSDParams));

        // Step 1. Have Flashloaned WETH
        // Open WETH CDP in Maker, then Mint out some DAI
        uint256 wethCdp = _openLockGemAndDraw(
            Constants.MCD_JOIN_ETH_A,
            Constants.ETH_A_ILK,
            csdp.flashloanAmountWETH,
            csdp.mintAmountDAI
        );

        // Step 2.
        // Use flashloaned DAI to repay entire vault and withdraw USDC
        _wipeAllAndFreeGem(
            Constants.MCD_JOIN_USDC_A,
            csdp.cdpId,
            csdp.withdrawAmountUSDC
        );

        // Step 3.
        // Converts USDC to DAI on CurveFi (To repay loan)
        // DAI = 0 index, USDC = 1 index
        ICurveFiCurve curve = ICurveFiCurve(csdp.curvePool);
        // Calculate amount of USDC needed to exchange to repay flashloaned DAI
        // Allow max of 5% slippage (otherwise no profits lmao)
        uint256 usdcBal = IERC20(Constants.USDC).balanceOf(address(this));
        require(
            IERC20(Constants.USDC).approve(address(curve), usdcBal),
            "erc20-approve-curvepool-failed"
        );
        curve.exchange_underlying(int128(1), int128(0), usdcBal, 0);

        // Step 4.
        // Repay DAI loan back to WETH CDP and FREE WETH
        _wipeAllAndFreeGem(
            Constants.MCD_JOIN_ETH_A,
            wethCdp,
            csdp.flashloanAmountWETH
        );
    }

    function flashloanAndClose(
        address _sender,
        address _solo,
        address _curvePool,
        uint256 _cdpId,
        uint256 _ethUsdRatio18 // 1 ETH = <X> DAI?
    ) external payable {
        require(msg.value == 2, "!fee");

        ISoloMargin solo = ISoloMargin(_solo);

        uint256 marketId = _getMarketIdFromTokenAddress(_solo, Constants.WETH);

        // Supplied = How much we want to withdraw
        // Borrowed = How much we want to loan
        (
            uint256 withdrawAmountUSDC,
            uint256 mintAmountDAI
        ) = _getSuppliedAndBorrow(Constants.MCD_JOIN_USDC_A, _cdpId);

        // Given, ETH price, calculate how much WETH we need to flashloan
        // Dividing by 2 to gives us 200% col ratio
        uint256 flashloanAmountWETH = mintAmountDAI.mul(1 ether).div(
            _ethUsdRatio18.div(2)
        );

        require(
            IERC20(Constants.WETH).balanceOf(_solo) >= flashloanAmountWETH,
            "!weth-supply"
        );

        // Wrap ETH into WETH
        WETH(Constants.WETH).deposit{value: msg.value}();
        WETH(Constants.WETH).approve(_solo, flashloanAmountWETH.add(msg.value));

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, flashloanAmountWETH);
        operations[1] = _getCallAction(
            abi.encode(
                CSDParams({
                    mintAmountDAI: mintAmountDAI,
                    withdrawAmountUSDC: withdrawAmountUSDC,
                    flashloanAmountWETH: flashloanAmountWETH,
                    cdpId: _cdpId,
                    curvePool: _curvePool
                })
            )
        );
        operations[2] = _getDepositAction(
            marketId,
            flashloanAmountWETH.add(msg.value)
        );

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);

        // Convert DAI leftovers to USDC
        uint256 daiBal = IERC20(Constants.DAI).balanceOf(address(this));
        require(
            IERC20(Constants.DAI).approve(_curvePool, daiBal),
            "erc20-approve-curvepool-failed"
        );
        ICurveFiCurve(_curvePool).exchange_underlying(
            int128(0),
            int128(1),
            daiBal,
            0
        );

        // Refund leftovers
        IERC20(Constants.USDC).transfer(
            _sender,
            IERC20(Constants.USDC).balanceOf(address(this))
        );
    }
}
