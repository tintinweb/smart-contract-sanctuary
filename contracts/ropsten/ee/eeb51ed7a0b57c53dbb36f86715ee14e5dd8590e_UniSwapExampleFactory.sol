/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.6.0;

interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IUniswap {
  function swapExactTokensForETH(
    uint amountIn, 
    uint amountOutMin, 
    address[] calldata path, 
    address to, 
    uint deadline)
    external
    returns (uint[] memory amounts);
  function WETH() external pure returns (address);
}
interface IERC20 {
  function transferFrom(
    address sender, 
    address recipient, 
    uint256 amount) 
    external 
    returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract UniSwapExampleFactory {
    address private router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswap iuniswap;
    
    function getTokenReserve() external view returns (uint, uint){
        address pair = UniswapV2Factory(factory).getPair(dai,weth);
        (uint reserve0, uint reserve1,) = UniswapV2Pair(pair).getReserves();
        return (reserve0, reserve1);
    }
    
    function swapTokensForEther(uint256 amountIn,uint256 amountOutMin) external {
        IERC20(dai).transferFrom(msg.sender, address(this), amountIn);
        address[] memory path = new address[](2);
        path[0] = dai;
        path[1] = weth;
        IERC20(dai).approve(address(router), amountIn);
        iuniswap.swapExactTokensForETH(
          amountIn, 
          amountOutMin, 
          path, 
          address(this), 
          block.timestamp + 240
        );
    }
    
    function getTokenPair() external view returns (address){
        return UniswapV2Factory(factory).getPair(dai,weth);
    }
}