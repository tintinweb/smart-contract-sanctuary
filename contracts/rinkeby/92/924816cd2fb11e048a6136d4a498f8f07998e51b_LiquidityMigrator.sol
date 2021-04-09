// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import "./imports.sol";


contract LiquidityMigrator {
    
    using SafeMath for uint;

    IUniswapV2Router02 router;
    address token;
    uint constant MIN_ETH = 5e17;

    constructor(address _token,address _router) public {
        token = _token;
        router = IUniswapV2Router02(_router);
    }

    function migrate(address pair,uint amount, uint slippage,uint deadline) external returns (uint,uint) {
        require(IUniswapV2Pair(pair).token0() == router.WETH() || IUniswapV2Pair(pair).token1() == router.WETH());
        SafeERC20.safeTransferFrom(IERC20(pair),msg.sender,address(this),amount);
        removeLiquidity(pair,amount);
        uint samount0;
        uint samount1;
        address changeToken = IUniswapV2Pair(pair).token0() == router.WETH() ? (IUniswapV2Pair(pair).token1()) : (IUniswapV2Pair(pair).token0());
        (uint ethAmount,uint changeAmount) = (IERC20(router.WETH()).balanceOf(address(this)),IERC20(changeToken).balanceOf(address(this)));
        if (checkReserves(changeToken,router.WETH(),changeAmount) && swapPrice(changeToken,router.WETH(),changeAmount) >= MIN_ETH) {
            samount0 = swap(router.WETH(),token,ethAmount,slippage,deadline);
            samount1 = swap(changeToken,router.WETH(),changeAmount,slippage,deadline);
        } else {
            samount0 = swap(router.WETH(),token,ethAmount.div(2),slippage,deadline);
            samount1 = ethAmount.div(2);
            SafeERC20.safeTransfer(IERC20(changeToken), msg.sender, changeAmount);
        }
        addLiquidity(token,router.WETH(),samount0,samount1,msg.sender);
        
        return (samount0, samount1);
    }
    
    function removeLiquidity(address pair,uint amount) internal returns (uint,uint) {
        SafeERC20.safeTransfer(IERC20(pair),pair,amount);
        return IUniswapV2Pair(pair).burn(address(this));
    }
    
    function addLiquidity(address token0,address token1,uint amount0,uint amount1,address to) internal returns (uint) {
        (amount0,amount1) = shapeReservesChange(token,router.WETH(),amount0,amount1);
        address pair = UniswapV2Library.pairFor(router.factory(),token0,token1);
        SafeERC20.safeTransfer(IERC20(token0),pair,amount0);
        SafeERC20.safeTransfer(IERC20(token1),pair,amount1);
        return IUniswapV2Pair(pair).mint(to);
    }
    
    function swap(address tokenIn,address tokenOut,uint amount,uint slippagePercent,uint deadline) internal returns (uint) {
        address pair = UniswapV2Library.pairFor(router.factory(),tokenIn,tokenOut);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        (uint reserveIn,uint reserveOut) = UniswapV2Library.getReserves(router.factory(),tokenIn,tokenOut);
        uint out = slippage(UniswapV2Library.getAmountOut(IERC20(tokenIn).balanceOf(pair),reserveIn,reserveOut),slippagePercent);
        SafeERC20.safeApprove(IERC20(tokenIn),address(router),amount);
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount,out,path,address(this),deadline);
        return IERC20(tokenOut).balanceOf(address(this));
    }

    function checkReserves(address tokenIn,address tokenOut,uint amount) internal view returns (bool) {
        (,uint reserveOut) = UniswapV2Library.getReserves(router.factory(),tokenIn,tokenOut);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint out = UniswapV2Library.getAmountsOut(router.factory(),amount,path)[1];
        if (reserveOut >= out) {
            return true;
        }
        
        return false;
    }
    
    function checkReserves(address tokenIn,address tokenOut,uint amount,uint reserveOut) internal view returns (bool) {
        if (tokenIn == tokenOut) {
            return true;
        }
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint out = UniswapV2Library.getAmountsOut(router.factory(),amount,path)[1];
        if (reserveOut >= out) {
            return true;
        }
        
        return false;
    }

    function slippage(uint amount,uint percent) internal pure returns (uint) {
        return amount.sub(amount.mul(percent).div(100));
}

    function shapeReservesChange(address token0,address token1,uint amount0,uint amount1) internal returns (uint,uint) {
        (uint reserve0,uint reserve1) = UniswapV2Library.getReserves(router.factory(),token0,token1);
        if (amount0 > amount1.mul(reserve0).div(reserve1)) {
            SafeERC20.safeTransfer(IERC20(token0),msg.sender,amount0.sub(amount1.mul(reserve0).div(reserve1)));
            amount0 = amount1.mul(reserve0).div(reserve1);
        } else if (amount1 > amount0.mul(reserve1).div(reserve0)) {
            SafeERC20.safeTransfer(IERC20(token1),msg.sender,amount1.sub(amount0.mul(reserve1).div(reserve0)));
            amount1 = amount0.mul(reserve1).div(reserve0);
        }
        return (amount0,amount1);
    }

    function shapeReserves(address token0,address token1,uint amount0,uint amount1) internal view returns (uint,uint) {
        (uint reserve0,uint reserve1) = UniswapV2Library.getReserves(router.factory(),token0,token1);
        if (amount0 > amount1.mul(reserve0).div(reserve1)) {
            amount0 = amount1.mul(reserve0).div(reserve1);
        } else if (amount1 > amount0.mul(reserve1).div(reserve0)) {
            amount1 = amount0.mul(reserve1).div(reserve0);
        }
        return (amount0,amount1);
    }

    function fromPair(address pair,uint amount) external view returns (uint) {
        require(IUniswapV2Pair(pair).token0() == router.WETH() || IUniswapV2Pair(pair).token1() == router.WETH());
        (uint amount0,uint amount1) = UniswapV2LiquidityMathLibrary.getLiquidityValue(router.factory(),IUniswapV2Pair(pair).token0(),IUniswapV2Pair(pair).token1(),amount);
        uint samount0;
        uint samount1;
        address changeToken = IUniswapV2Pair(pair).token0() == router.WETH() ? (IUniswapV2Pair(pair).token1()) : (IUniswapV2Pair(pair).token0());
        (uint ethAmount,uint changeAmount) = IUniswapV2Pair(pair).token0() == router.WETH() ? (amount0,amount1) : (amount1,amount0);
        (,uint reserve) = UniswapV2Library.getReserves(router.factory(),changeToken,router.WETH());
        (uint reserveIn,uint reserveOut) = UniswapV2Library.getReserves(router.factory(),changeToken,router.WETH());
        (uint reserve0,uint reserve1) = UniswapV2Library.getReserves(router.factory(),token,router.WETH());
        if (checkReserves(changeToken,router.WETH(),changeAmount,reserve.sub(ethAmount)) && UniswapV2Library.getAmountOut(changeAmount,reserveIn.sub(changeAmount),reserveOut.sub(ethAmount)) >= MIN_ETH) {
            samount0 = swapPrice(router.WETH(),token,ethAmount);
            reserve0 = reserve0.sub(samount0);
            reserve1 = reserve1.add(ethAmount);
            samount1 = UniswapV2Library.getAmountOut(changeAmount,reserveIn.sub(changeAmount),reserveOut.sub(ethAmount));
        } else {
            samount0 = swapPrice(router.WETH(),token,ethAmount.div(2));
            reserve0 = reserve0.sub(samount0);
            reserve1 = reserve1.add(ethAmount.div(2));
            samount1 = ethAmount.div(2);
        }
        (samount0,samount0) = shapeReserves(token,router.WETH(),samount0,samount1);
        return calculateLiquidity(pair,samount0,samount1,reserve0,reserve1);
    }
    
    function calculateLiquidity(address pair,uint samount0,uint samount1,uint _reserve0,uint _reserve1) internal view returns (uint) {
        uint _totalSupply = IERC20(pair).totalSupply();
        uint liquidity;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(samount0.mul(samount1)).sub(10**3);
        } else {
            liquidity = Math.min(samount0.mul(_totalSupply) / _reserve0, samount1.mul(_totalSupply) / _reserve1);
        }
        return liquidity;
    }
    
    function swapPrice(address tokenIn,address tokenOut,uint amount) internal view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return UniswapV2Library.getAmountsOut(router.factory(),amount,path)[1];
    }
    

    function getTokenPrice(address pair) external view returns (uint) {
        require(IUniswapV2Pair(pair).token0() == router.WETH() || IUniswapV2Pair(pair).token1() == router.WETH());
        address pairtoken = IUniswapV2Pair(pair).token0() == router.WETH() ? (IUniswapV2Pair(pair).token1()) : (IUniswapV2Pair(pair).token0());
        (uint reserve0,uint reserve1) = UniswapV2Library.getReserves(router.factory(),IUniswapV2Pair(pair).token0(),IUniswapV2Pair(pair).token1());
        uint price = IUniswapV2Pair(pair).token0() == router.WETH() ? (reserve0.mul(1e18).div(reserve1)) : (reserve1.mul(1e18).div(reserve0));
        return price.div(1 ** IERC20(pairtoken).decimals());
    }
    
    function getTokenSymbol(address pair) external view returns (string memory) {
        require(IUniswapV2Pair(pair).token0() == router.WETH() || IUniswapV2Pair(pair).token1() == router.WETH());
        address pairtoken = IUniswapV2Pair(pair).token0() == router.WETH() ? (IUniswapV2Pair(pair).token1()) : (IUniswapV2Pair(pair).token0());
        return IERC20(pairtoken).symbol();
    }
}