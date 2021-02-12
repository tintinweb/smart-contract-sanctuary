// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "./Math.sol";
import {Ownable} from "./Ownable.sol";
import {SafeERC20, SafeMath, IERC20, Address} from "./SafeERC20.sol";

import {ICurveFi} from "./curve.sol";
import {IUniswapV2Router02} from "./uniswap.sol";
import {ISynthetix, IExchanger, ISynth} from "./synthetix.sol";

interface IYVault is IERC20 {
    function deposit(uint256 amount, address recipient) external;

    function withdraw(uint256 shares, address recipient) external;

    function pricePerShare() external view returns (uint256);
}

contract ZapYvecrvSusd is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant sushiswapRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    IYVault public yVault = IYVault(address(0x0e880118C29F095143dDA28e64d95333A9e75A47));
    ICurveFi public curveStableSwap = ICurveFi(address(0xc5424B857f758E906013F3555Dad202e4bdB4567)); // Curve ETH/sEth StableSwap pool contract
    IUniswapV2Router02 public swapRouter;
    // IAddressResolver public SynthetixResolver = IAddressResolver(address(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83)); // synthetix AddressResolver contract
    ISynthetix public synthetix = ISynthetix(address(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)); // synthetix ProxyERC20
    IExchanger public synthetixExchanger = IExchanger(address(0x0bfDc04B38251394542586969E2356d0D731f7DE));

    IERC20 public want = IERC20(address(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c)); // Curve.fi ETH/sEth (eCRV)
    IERC20 public weth = IERC20(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    ISynth public sEth = ISynth(address(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb)); // synthetix ProxysETH
    ISynth public sUsd = ISynth(address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51)); // synthetix ProxyERC20sUSD

    // uint256 public constant DEFAULT_SLIPPAGE = 50; // slippage allowance out of 10000: 5%
    bool private _noReentry = false;
    address[] public swapPathZapIn;
    address[] public swapPathZapOut;

    constructor() public Ownable() {
        swapRouter = IUniswapV2Router02(sushiswapRouter);

        swapPathZapIn = new address[](2);
        swapPathZapIn[0] = address(weth);
        swapPathZapIn[1] = address(sUsd);

        swapPathZapOut = new address[](2);
        swapPathZapOut[0] = address(sUsd);
        swapPathZapOut[1] = address(weth);

        // In approves
        // Route: ETH ->(swapRouter)-> sUsd ->(synthetix)-> sEth ->(curveStableSwap)-> eCRV/want ->(yVault)-> yveCRV
        sUsd.approve(address(synthetix), uint256(-1));
        sEth.approve(address(curveStableSwap), uint256(-1));
        want.safeApprove(address(yVault), uint256(-1));

        // Out approves
        // Route: yveCRV ->(yVault)-> eCRV/want ->(curveStableSwap)-> sEth ->(synthetix)-> sUsd ->(swapRouter)-> ETH
        want.safeApprove(address(curveStableSwap), uint256(-1));
        sEth.approve(address(synthetix), uint256(-1));
        sUsd.approve(address(swapRouter), uint256(-1));
    }

    // Accept ETH and zap in with no token swap
    receive() external payable {
        if (_noReentry) {
            return;
        }
        _zapIn(0);
    }

    //
    // Zap In
    //

    // Zap In - Step 1
    function estimateZapInWithSwap(uint256 ethAmount, uint256 percentSwapSeth) external view returns (uint256) {
        require(percentSwapSeth >= 0 && percentSwapSeth <= 100, "INVALID PERCENTAGE VALUE");

        uint256 estimatedSethAmount = 0;
        if (percentSwapSeth > 0) {
            uint256 swappingEthAmount = ethAmount.mul(percentSwapSeth).div(100);
            ethAmount = ethAmount.sub(swappingEthAmount);

            uint256[] memory amounts = swapRouter.getAmountsOut(swappingEthAmount, swapPathZapIn);
            uint256 estimatedSusdAmount = amounts[amounts.length - 1];
            (estimatedSethAmount, , ) = synthetixExchanger.getAmountsForExchange(estimatedSusdAmount, "sUSD", "sETH");
        }

        return curveStableSwap.calc_token_amount([ethAmount, estimatedSethAmount], true);
    }

    // Zap In - Step 2 (optional)
    // Requires user to run: DelegateApprovals.approveExchangeOnBehalf(<zap_contract_address>)
    // synthetix DelegateApprovals contract: 0x15fd6e554874B9e70F832Ed37f231Ac5E142362f
    function swapEthToSeth() external payable {
        uint256 swappingEthAmount = address(this).balance;
        swapRouter.swapExactETHForTokens{value: swappingEthAmount}(swappingEthAmount, swapPathZapIn, address(this), now);

        uint256 susdAmount = sUsd.balanceOf(address(this));
        sUsd.transfer(msg.sender, susdAmount);
        synthetix.exchangeOnBehalf(msg.sender, "sUSD", susdAmount, "sETH");
    }

    // Zap In - Step 3
    // Requires user to run: sEth.approve(<zap_contract_address>, <seth_amount>)
    // synthetix ProxysETH contract: 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb
    function zapIn(uint256 sethAmount) external payable {
        if (_noReentry) {
            return;
        }
        // if (slippageAllowance == 0) {
        //     slippageAllowance = DEFAULT_SLIPPAGE;
        // }
        _zapIn(sethAmount);
    }

    function _zapIn(uint256 sethAmount) internal {
        uint256 ethBalance = address(this).balance;
        sethAmount = Math.min(sethAmount, sEth.balanceOf(msg.sender));
        require(ethBalance > 0 || sethAmount > 0, "INSUFFICIENT FUNDS");

        if (sethAmount > 0) {
            // uint256 waitLeft = synthetixExchanger.maxSecsLeftInWaitingPeriod(msg.sender, "sEth")
            sEth.transferFromAndSettle(msg.sender, address(this), sethAmount);
        }
        curveStableSwap.add_liquidity{value: ethBalance}([ethBalance, sethAmount], 0);

        uint256 outAmount = want.balanceOf(address(this));
        // require(outAmount.mul(slippageAllowance.add(10000)).div(10000) >= ethBalance.add(sethBalance), "TOO MUCH SLIPPAGE");

        yVault.deposit(outAmount, msg.sender);
    }

    //
    // Zap Out
    //

    // Zap Out - Step 1
    function estimateZapOutWithSwap(uint256 yvTokenAmount, uint256 percentSwapSusd) external view returns (uint256) {
        require(percentSwapSusd >= 0 && percentSwapSusd <= 100, "INVALID PERCENTAGE VALUE");

        uint256 wantAmount = yvTokenAmount.mul(yVault.pricePerShare());

        uint256 estimatedSwappedEthAmount = 0;
        if (percentSwapSusd > 0) {
            uint256 swappingWantAmount = wantAmount.mul(percentSwapSusd).div(100);
            wantAmount = wantAmount.sub(swappingWantAmount);

            uint256 sethAmount = curveStableSwap.calc_withdraw_one_coin(swappingWantAmount, 1);
            (uint256 susdAmount, , ) = synthetixExchanger.getAmountsForExchange(sethAmount, "sETH", "sUSD");
            uint256[] memory amounts = swapRouter.getAmountsOut(susdAmount, swapPathZapOut);
            estimatedSwappedEthAmount = amounts[amounts.length - 1];
        }

        uint256 estimatedEthAmount = curveStableSwap.calc_withdraw_one_coin(wantAmount, 0);

        return estimatedEthAmount.add(estimatedSwappedEthAmount);
    }

    // Zap Out - Step 2
    // Requires user to run: DelegateApprovals.approveExchangeOnBehalf(<zap_contract_address>)
    // synthetix DelegateApprovals contract: 0x15fd6e554874B9e70F832Ed37f231Ac5E142362f
    function zapOut(uint256 yvTokenAmount, uint256 percentSwapSusd) external {
        require(percentSwapSusd >= 0 && percentSwapSusd <= 100, "INVALID PERCENTAGE VALUE");

        uint256 yvTokenBalance = Math.min(yvTokenAmount, yVault.balanceOf(msg.sender));
        require(yvTokenBalance > 0, "INSUFFICIENT FUNDS");

        yVault.withdraw(yvTokenBalance, address(this));
        uint256 wantBalance = want.balanceOf(address(this));

        _noReentry = true;
        curveStableSwap.remove_liquidity_one_coin(wantBalance.mul(percentSwapSusd).div(100), 0, 0);
        wantBalance = want.balanceOf(address(this));
        curveStableSwap.remove_liquidity_one_coin(wantBalance, 0, 0);
        _noReentry = false;

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            msg.sender.transfer(ethBalance);
        }

        uint256 sethBalance = sEth.balanceOf(address(this));
        if (sethBalance > 0) {
            sEth.transfer(msg.sender, sethBalance);
            synthetix.exchangeOnBehalf(msg.sender, "sETH", sethBalance, "sUSD");
        }

        uint256 leftover = yVault.balanceOf(address(this));
        if (leftover > 0) {
            yVault.transfer(msg.sender, leftover);
        }
    }

    // Zap Out - Step 3 (Optional)
    // Requires user to run: sUsd.approve(<zap_contract_address>, <susd_amount>)
    // synthetix ProxysETH contract: 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb
    function swapSusdToEth(uint256 susdAmount) external {
        uint256 susdBalance = Math.min(susdAmount, sUsd.balanceOf(msg.sender));
        require(susdBalance > 0, "INSUFFICIENT FUNDS");

        // uint256 waitLeft = synthetixExchanger.maxSecsLeftInWaitingPeriod(msg.sender, "sUsd");
        sUsd.transferFromAndSettle(msg.sender, address(this), susdBalance);
        susdBalance = sUsd.balanceOf(address(this));
        swapRouter.swapExactTokensForETH(susdBalance, 0, swapPathZapOut, address(this), now);

        uint256 ethBalance = address(this).balance;
        msg.sender.transfer(ethBalance);
    }

    //
    // Misc external functions
    //

    //There should never be any tokens in this contract
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        if (token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            amount = Math.min(address(this).balance, amount);
            msg.sender.transfer(amount);
        } else {
            IERC20 want = IERC20(token);
            amount = Math.min(want.balanceOf(address(this)), amount);
            want.safeTransfer(msg.sender, amount);
        }
    }

    function updateVaultAddress(address _vault) external onlyOwner {
        yVault = IYVault(_vault);
        want.safeApprove(_vault, uint256(-1));
    }

    function setSwapRouter(
        bool isUniswap,
        address[] calldata _swapPathZapIn,
        address[] calldata _swapPathZapOut
    ) external onlyOwner {
        if (isUniswap) {
            swapRouter = IUniswapV2Router02(uniswapRouter);
        } else {
            swapRouter = IUniswapV2Router02(sushiswapRouter);
        }

        swapPathZapIn = _swapPathZapIn;
        swapPathZapIn = _swapPathZapOut;

        sUsd.approve(address(swapRouter), uint256(-1)); // For zap out
    }
}