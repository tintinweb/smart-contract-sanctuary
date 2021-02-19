/**
 *Submitted for verification at Etherscan.io on 2021-02-18
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

contract Keep3rV1OracleUSD  {
    
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
    
    IKeep3rV1Oracle public constant sushiswapV1Oracle = IKeep3rV1Oracle(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa);
    IKeep3rV1Oracle public constant uniswapV1Oracle = IKeep3rV1Oracle(0x73353801921417F465377c8d898c6f4C0270282C);
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IChainLinkFeedsRegistry constant chainlink = IChainLinkFeedsRegistry(0x271bf4568fb737cc2e6277e9B1EE0034098cDA2a);

    function assetToUsd(address tokenIn, uint amountIn, uint granularity) public view returns (QuoteParams memory q, LiquidityParams memory l) {
        (q,) = assetToEth(tokenIn, amountIn, granularity);
        return ethToUsd(q.amountOut, granularity);
    }
    
    function assetToEth(address tokenIn, uint amountIn, uint granularity) public view returns (QuoteParams memory q, LiquidityParams memory l) {
        q.sTWAP = sushiswapV1Oracle.quote(tokenIn, amountIn, WETH, granularity);
        q.uTWAP = uniswapV1Oracle.quote(tokenIn, amountIn, WETH, granularity);
        q.sCUR = sushiswapV1Oracle.current(tokenIn, amountIn, WETH);
        q.uCUR = uniswapV1Oracle.current(tokenIn, amountIn, WETH);
        q.cl = chainlink.getPriceETH(tokenIn) * amountIn / 10 ** 18;
        l = getLiquidity(tokenIn, WETH);
        
        q.amountOut = (q.sTWAP * l.sLiquidity + q.uTWAP * l.uLiquidity) / (l.sLiquidity + l.uLiquidity);
        q.currentOut = (q.sCUR * l.sLiquidity + q.uCUR * l.uLiquidity) / (l.sLiquidity + l.uLiquidity);
        q.quoteOut = Math.min(Math.min(q.amountOut, q.currentOut), q.cl);
    }
    
    function ethToAsset(uint amountIn, address tokenOut, uint granularity) public view returns (QuoteParams memory q, LiquidityParams memory l) {
        q.sTWAP = sushiswapV1Oracle.quote(WETH, amountIn, tokenOut, granularity);
        q.uTWAP = uniswapV1Oracle.quote(WETH, amountIn, tokenOut, granularity);
        q.sCUR = sushiswapV1Oracle.current(WETH, amountIn, tokenOut);
        q.uCUR = uniswapV1Oracle.current(WETH, amountIn, tokenOut);
        q.cl = amountIn * 10 ** 18 / chainlink.getPriceETH(tokenOut);
        l = getLiquidity(WETH, tokenOut);
        
        q.amountOut = (q.sTWAP * l.sLiquidity + q.uTWAP * l.uLiquidity) / (l.sLiquidity + l.uLiquidity);
        q.currentOut = (q.sCUR * l.sLiquidity + q.uCUR * l.uLiquidity) / (l.sLiquidity + l.uLiquidity);
        q.quoteOut = Math.min(q.amountOut, q.currentOut);
        q.quoteOut = Math.min(Math.min(q.amountOut, q.currentOut), q.cl);
    }
    
    function ethToUsd(uint amountIn, uint granularity) public view returns (QuoteParams memory q, LiquidityParams memory l) {
        return assetToAsset(WETH, amountIn, DAI, granularity);
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
    
    function getLiquidity(address tokenA, address tokenB) public view returns (LiquidityParams memory l) {
        address sPair = SushiswapV2Library.sushiPairFor(tokenA, tokenB);
        address uPair = SushiswapV2Library.uniPairFor(tokenA, tokenB);
        (l.sReserveA, l.sReserveB) =  SushiswapV2Library.getReserves(sPair, tokenA, tokenB);
        (l.uReserveA, l.uReserveB) =  SushiswapV2Library.getReserves(uPair, tokenA, tokenB);
        l.sLiquidity = l.sReserveA * l.sReserveB;
        l.uLiquidity = l.uReserveA * l.uReserveB;
    }
    
    function assetToAsset(address tokenIn, uint amountIn, address tokenOut, uint granularity) public view returns (QuoteParams memory q, LiquidityParams memory l) {
        if (tokenIn == WETH) {
            return ethToAsset(amountIn, tokenOut, granularity);
        } else if (tokenOut == WETH) {
            return assetToEth(tokenIn, amountIn, granularity);
        } else {
            (q,) = assetToEth(tokenIn, amountIn, granularity);
            return ethToAsset(q.quoteOut, tokenOut, granularity);
        }
        
    }
}