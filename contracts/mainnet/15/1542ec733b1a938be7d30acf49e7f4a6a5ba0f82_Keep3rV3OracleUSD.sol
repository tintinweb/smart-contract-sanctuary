/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

interface IKeep3rV1Oracle {
    function quote(address tokenIn, uint amountIn, address tokenOut, uint granularity) external view returns (uint);
    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint);
}


interface ISushiswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;
}

library SushiswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SushiswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SushiswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function sushiPairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))));
    }
    
    // calculates the CREATE2 address for a pair without making any external calls
    function uniPairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }


    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISushiswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}

interface IChainLinkFeedsRegistry {
    function getPriceETH(address tokenIn) external view returns (uint);
}

interface ISwapV2Router02 {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract Keep3rV3OracleUSD  {
    
    struct LiquidityParams {
        uint sReserveA;
        uint sReserveB;
        uint uReserveA;
        uint uReserveB;
        uint sLiquidity;
        uint uLiquidity;
    }
    
    struct QuoteParams {
        uint quoteOut;
        uint amountOut;
        uint currentOut;
        uint sTWAP;
        uint uTWAP;
        uint sCUR;
        uint uCUR;
        uint cl;
    }
    
    IKeep3rV1Oracle private constant sushiswapV1Oracle = IKeep3rV1Oracle(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa);
    IKeep3rV1Oracle private constant uniswapV1Oracle = IKeep3rV1Oracle(0x73353801921417F465377c8d898c6f4C0270282C);
    
    ISwapV2Router02 private constant sushiswapV2Router = ISwapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ISwapV2Router02 private constant uniswapV2Router = ISwapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
    uint private constant DECIMALS = 10 ** 18;
    
    IChainLinkFeedsRegistry private constant chainlink = IChainLinkFeedsRegistry(0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a);

    function assetToUsd(address tokenIn, uint amountIn, uint granularity) public view returns (QuoteParams memory q) {
        q = assetToEth(tokenIn, amountIn, granularity);
        return ethToUsd(q.amountOut, granularity);
    }
    
    function ethToUsd(uint amountIn, uint granularity) public view returns (QuoteParams memory q) {
        return assetToAsset(WETH, amountIn, DAI, granularity);
    }
    
    function assetToEth(address tokenIn, uint amountIn, uint granularity) public view returns (QuoteParams memory q) {
        q.sTWAP = sushiswapV1Oracle.quote(tokenIn, amountIn, WETH, granularity);
        q.uTWAP = uniswapV1Oracle.quote(tokenIn, amountIn, WETH, granularity);
        address[] memory _path = new address[](2);
        _path[0] = tokenIn;
        _path[1] = WETH;
        q.sCUR = sushiswapV2Router.getAmountsOut(amountIn, _path)[1];
        q.uCUR = uniswapV2Router.getAmountsOut(amountIn, _path)[1];
        
        q.cl = chainlink.getPriceETH(tokenIn) * amountIn / 10 ** IERC20(tokenIn).decimals();
        
        q.amountOut = Math.min(q.sTWAP, q.uTWAP);
        q.currentOut = Math.min(q.sCUR, q.uCUR);
        q.quoteOut = Math.min(Math.min(q.amountOut, q.currentOut), q.cl);
    }
    
    function ethToAsset(uint amountIn, address tokenOut, uint granularity) public view returns (QuoteParams memory q) {
        q.sTWAP = sushiswapV1Oracle.quote(WETH, amountIn, tokenOut, granularity);
        q.uTWAP = uniswapV1Oracle.quote(WETH, amountIn, tokenOut, granularity);
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = tokenOut;
        q.sCUR = sushiswapV2Router.getAmountsOut(amountIn, _path)[1];
        q.uCUR = uniswapV2Router.getAmountsOut(amountIn, _path)[1];
        
        q.cl = amountIn * 10 ** IERC20(tokenOut).decimals() / chainlink.getPriceETH(tokenOut);
        
        q.amountOut = Math.min(q.sTWAP, q.uTWAP);
        q.currentOut = Math.min(q.sCUR, q.uCUR);
        q.quoteOut = Math.min(Math.min(q.amountOut, q.currentOut), q.cl);
    }
    
    function pairFor(address tokenA, address tokenB) external pure returns (address sPair, address uPair) {
        sPair = SushiswapV2Library.sushiPairFor(tokenA, tokenB);
        uPair = SushiswapV2Library.uniPairFor(tokenA, tokenB);
    }
    
    function sPairFor(address tokenA, address tokenB) external pure returns (address sPair) {
        sPair = SushiswapV2Library.sushiPairFor(tokenA, tokenB);
    }
    
    function uPairFor(address tokenA, address tokenB) external pure returns (address uPair) {
        uPair = SushiswapV2Library.uniPairFor(tokenA, tokenB);
    }
    
    function getLiquidity(address tokenA, address tokenB) external view returns (LiquidityParams memory l) {
        address sPair = SushiswapV2Library.sushiPairFor(tokenA, tokenB);
        address uPair = SushiswapV2Library.uniPairFor(tokenA, tokenB);
        (l.sReserveA, l.sReserveB) =  SushiswapV2Library.getReserves(sPair, tokenA, tokenB);
        (l.uReserveA, l.uReserveB) =  SushiswapV2Library.getReserves(uPair, tokenA, tokenB);
        l.sLiquidity = l.sReserveA * l.sReserveB;
        l.uLiquidity = l.uReserveA * l.uReserveB;
    }
    
    function assetToAsset(address tokenIn, uint amountIn, address tokenOut, uint granularity) public view returns (QuoteParams memory q) {
        if (tokenIn == WETH) {
            return ethToAsset(amountIn, tokenOut, granularity);
        } else if (tokenOut == WETH) {
            return assetToEth(tokenIn, amountIn, granularity);
        } else {
            q = assetToEth(tokenIn, amountIn, granularity);
            return ethToAsset(q.quoteOut, tokenOut, granularity);
        }
        
    }
}