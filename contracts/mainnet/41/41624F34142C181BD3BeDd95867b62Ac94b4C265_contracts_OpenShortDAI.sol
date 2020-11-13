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

contract OpenShortDAI is ICallee, DydxFlashloanBase, DssActionsBase {
    // LeveragedShortDAI Params
    struct OSDParams {
        uint256 cdpId; // CDP Id to leverage
        uint256 mintAmountDAI; // Amount of DAI to mint
        uint256 flashloanAmountWETH; // Amount of WETH flashloaned
        address curvePool;
    }

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        OSDParams memory osdp = abi.decode(data, (OSDParams));

        // Step 1. Have Flashloaned WETH
        // Open WETH CDP in Maker, then Mint out some DAI
        uint256 wethCdp = _openLockGemAndDraw(
            Constants.MCD_JOIN_ETH_A,
            Constants.ETH_A_ILK,
            osdp.flashloanAmountWETH,
            osdp.mintAmountDAI
        );

        // Step 2.
        // Converts Flashloaned DAI to USDC on CurveFi
        // DAI = 0 index, USDC = 1 index
        require(
            IERC20(Constants.DAI).approve(osdp.curvePool, osdp.mintAmountDAI),
            "!curvepool-approved"
        );
        ICurveFiCurve(osdp.curvePool).exchange_underlying(
            int128(0),
            int128(1),
            osdp.mintAmountDAI,
            0
        );

        // Step 3.
        // Locks up USDC and borrow just enough DAI to repay WETH CDP
        uint256 supplyAmount = IERC20(Constants.USDC).balanceOf(address(this));
        _lockGemAndDraw(
            Constants.MCD_JOIN_USDC_A,
            osdp.cdpId,
            supplyAmount,
            osdp.mintAmountDAI
        );

        // Step 4.
        // Repay DAI loan back to WETH CDP and FREE WETH
        _wipeAllAndFreeGem(
            Constants.MCD_JOIN_ETH_A,
            wethCdp,
            osdp.flashloanAmountWETH
        );
    }

    function flashloanAndOpen(
        address _sender,
        address _solo,
        address _curvePool,
        uint256 _cdpId,
        uint256 _initialMarginUSDC,
        uint256 _mintAmountDAI,
        uint256 _flashloanAmountWETH
    ) external payable {
        require(msg.value == 2, "!fee");

        require(
            IERC20(Constants.WETH).balanceOf(_solo) >= _flashloanAmountWETH,
            "!weth-supply"
        );

        // Gets USDC
        require(
            IERC20(Constants.USDC).transferFrom(
                msg.sender,
                address(this),
                _initialMarginUSDC
            ),
            "initial-margin-transferFrom-failed"
        );

        ISoloMargin solo = ISoloMargin(_solo);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(_solo, Constants.WETH);

        // Wrap ETH into WETH
        WETH(Constants.WETH).deposit{value: msg.value}();
        WETH(Constants.WETH).approve(
            _solo,
            _flashloanAmountWETH.add(msg.value)
        );

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _flashloanAmountWETH);
        operations[1] = _getCallAction(
            // Encode OSDParams for callFunction
            abi.encode(
                OSDParams({
                    mintAmountDAI: _mintAmountDAI,
                    flashloanAmountWETH: _flashloanAmountWETH,
                    cdpId: _cdpId,
                    curvePool: _curvePool
                })
            )
        );
        operations[2] = _getDepositAction(
            marketId,
            _flashloanAmountWETH.add(msg.value)
        );

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);

        // Refund user any ERC20 leftover
        IERC20(Constants.DAI).transfer(
            _sender,
            IERC20(Constants.DAI).balanceOf(address(this))
        );
        IERC20(Constants.USDC).transfer(
            _sender,
            IERC20(Constants.USDC).balanceOf(address(this))
        );
    }
}
