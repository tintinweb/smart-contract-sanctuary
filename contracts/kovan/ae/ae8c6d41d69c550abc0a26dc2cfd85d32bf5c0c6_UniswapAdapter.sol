// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import {IERC20} from "./IERC20.sol";
import {SafeMath} from "./SafeMath.sol";
import {SafeERC20} from "./SafeERC20.sol";

import {IUniswapV2Pair} from "./IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "./IUniswapV2Router.sol";

contract UniswapAdapter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant ethAddress = address(0);
    address public immutable wethAddress;
    address public immutable wbtcAddress;
    address public immutable diggAddress;
    string private constant _name = "UNISWAP";
    bool private constant _nonFungible = true;
    IUniswapV2Router02 public immutable sushiswapRouter;
    IUniswapV2Pair public immutable wbtcDiggSushiswap;
    IERC20 public immutable wbtcToken;
    IERC20 public immutable diggToken;
    uint256 private constant deadlineBuffer = 150;

    constructor(
        address _sushiswapRouter,
        address _wbtcAddress,
        address _wethAddress,
        address _wbtcDiggSushiswap,
        address _diggAddress
    ) {
        require(_sushiswapRouter != address(0), "!_sushiswapRouter");
        require(_wethAddress != address(0), "!_weth");
        require(_wbtcAddress != address(0), "!_wbtc");
        require(_wbtcDiggSushiswap != address(0), "!_wbtcDiggSushiswap");
        require(_diggAddress != address(0), "!_diggAddress");

        wbtcAddress = _wbtcAddress;
        wethAddress = _wethAddress;
        diggAddress = _diggAddress;
        sushiswapRouter = IUniswapV2Router02(_sushiswapRouter);
        wbtcDiggSushiswap = IUniswapV2Pair(_wbtcDiggSushiswap);
        wbtcToken = IERC20(_wbtcAddress);
        diggToken = IERC20(_diggAddress);
    }

    receive() external payable {}

    function protocolName() public pure returns (string memory) {
        return _name;
    }

    function nonFungible() external pure returns (bool) {
        return _nonFungible;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Code from Alpha Homora
    // The core math involved in getting optimal swap amt to provide amm liquidity
    function getSwapAmt(uint256 amtA, uint256 resA)
        internal
        pure
        returns (uint256)
    {
        return
            sqrt(amtA.mul(resA.mul(3988000) + amtA.mul(3988009))).sub(
                amtA.mul(1997)
            ) / 1994;
    }

    function expectedWbtcOut(uint256 ethAmt) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = wbtcAddress;
        uint256 wbtcOut = sushiswapRouter.getAmountsOut(ethAmt, path)[1];
        return wbtcOut;
    }

    //this function returns both the expected digg amount out as well as the input trade amt of wbtc used
    //these are both needed as inputs to buyLp
    function expectedDiggOut(uint256 wbtcAmt)
        public
        view
        returns (uint256 diggOut, uint256 tradeAmt)
    {
        (uint112 reserveAmt, , ) =
            IUniswapV2Pair(wbtcDiggSushiswap).getReserves();
        tradeAmt = getSwapAmt(reserveAmt, wbtcAmt);
        address[] memory path = new address[](2);
        path[0] = wbtcAddress;
        path[1] = diggAddress;
        diggOut = sushiswapRouter.getAmountsOut(tradeAmt, path)[1];
    }

    function convertEthToToken(
        uint256 inputAmount,
        address addr,
        uint256 amountOutMin
    ) internal returns (uint256) {
        uint256 amtOut =
            _convertEthToToken(
                inputAmount,
                addr,
                amountOutMin,
                sushiswapRouter
            );
        return amtOut;
    }

    function convertTokenToToken(
        address addr1,
        address addr2,
        uint256 amount,
        uint256 amountOutMin
    ) internal returns (uint256) {
        uint256 amtOut =
            _convertTokenToToken(
                addr1,
                addr2,
                amount,
                amountOutMin,
                sushiswapRouter
            );
        return amtOut;
    }

    function addLiquidity(
        address token1,
        address token2,
        uint256 amount1,
        uint256 amount2
    ) internal returns (uint256) {
        uint256 lpAmt =
            _addLiquidity(token1, token2, amount1, amount2, sushiswapRouter);
        return lpAmt;
    }

    function _convertEthToToken(
        uint256 inputAmount,
        address addr,
        uint256 amountOutMin,
        IUniswapV2Router02 router
    ) internal returns (uint256) {
        uint256 deadline = block.timestamp + deadlineBuffer;
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = addr;
        uint256 amtOut =
            router.swapExactETHForTokens{value: inputAmount}(
                amountOutMin,
                path,
                address(this),
                deadline
            )[1];
        return amtOut;
    }

    function _convertTokenToToken(
        address addr1,
        address addr2,
        uint256 amount,
        uint256 amountOutMin,
        IUniswapV2Router02 router
    ) internal returns (uint256) {
        uint256 deadline = block.timestamp + deadlineBuffer;
        address[] memory path = new address[](2);
        path[0] = addr1;
        path[1] = addr2;
        if (wbtcToken.allowance(address(this), address(router)) == 0) {
            wbtcToken.safeApprove(address(router), type(uint256).max);
        }
        uint256 amtOut =
            router.swapExactTokensForTokens(
                amount,
                amountOutMin,
                path,
                address(this),
                deadline
            )[1];
        return amtOut;
    }

    function _addLiquidity(
        address token1,
        address token2,
        uint256 amount1,
        uint256 amount2,
        IUniswapV2Router02 router
    ) internal returns (uint256) {
        uint256 deadline = block.timestamp + deadlineBuffer;
        if (wbtcToken.allowance(address(this), address(router)) < amount1) {
            wbtcToken.safeApprove(address(router), type(uint256).max);
        }
        if (diggToken.allowance(address(this), address(router)) < amount2) {
            diggToken.safeApprove(address(router), type(uint256).max);
        }
        (, , uint256 lpAmt) =
            router.addLiquidity(
                token1,
                token2,
                amount1,
                amount2,
                0,
                0,
                address(this),
                deadline
            );
        return lpAmt;
    }

    //By the time this function is called the user bal should be in wbtc
    //calculates optimal swap amt for minimal leftover funds and buys Digg
    // Provides liquidity and transfers lp token to msg.sender
    function _buyLp(
        uint256 userWbtcBal,
        address traderAccount,
        uint256 tradeAmt,
        uint256 minDiggAmtOut
    ) internal {
        uint256 diggAmt =
            convertTokenToToken(
                wbtcAddress,
                diggAddress,
                tradeAmt,
                minDiggAmtOut
            );
        uint256 lpAmt =
            addLiquidity(wbtcAddress, diggAddress, userWbtcBal, diggAmt);
        require(
            wbtcDiggSushiswap.transfer(traderAccount, lpAmt),
            "transfer failed"
        );
    }

    // token input should be either wbtc or eth
    // valid exchange venues are sushiswap and uniswap
    // the minWbtcAmtOut param isnt used when users pass in wbtc directly
    // use the  expectedWbtcAmtOut and expectedDiggAmtOut functions off chain to calculate trade_amt, minWbtcAmtOut and minDiggAmtOut
    function buyLp(
        uint256 amt,
        uint256 tradeAmt,
        uint256 minWbtcAmtOut,
        uint256 minDiggAmtOut
    ) public payable {
        require(msg.value >= amt, "not enough funds");
        uint256 wbtcAmt = convertEthToToken(amt, wbtcAddress, minWbtcAmtOut);
        _buyLp(wbtcAmt, msg.sender, tradeAmt, minDiggAmtOut);
    }
}