/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.6.0;

interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract UniSwapExampleFactory {
    address private factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private dai = 0xa29cD8EcC47262073DA4B12F390CD392632e6860;
    address private weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    function getTokenReserve() external view returns (uint, uint){
        address pair = UniswapV2Factory(factory).getPair(dai,weth);
        (uint reserve0, uint reserve1,) = UniswapV2Pair(pair).getReserves();
        return (reserve0, reserve1);
    }
    
    function getTokenPair() external view returns (address){
        return UniswapV2Factory(factory).getPair(dai,weth);
    }
}