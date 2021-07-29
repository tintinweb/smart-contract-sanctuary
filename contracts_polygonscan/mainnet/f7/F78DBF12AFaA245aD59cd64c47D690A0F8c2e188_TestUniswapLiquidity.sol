/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

pragma solidity ^0.8;

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

contract TestUniswapLiquidity {
    address private constant FACTORY = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    function getLiquidity(address tokenA, address tokenB) external view returns (address pairAddress){
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
    
        pairAddress = IUniswapV2Factory(FACTORY).getPair(token0, token1);
    }
}