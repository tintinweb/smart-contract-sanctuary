/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.7.0;

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

contract NewAlokDefiProject {
  IUniswap uniswap;

  constructor(address _uniswap) {
    uniswap = IUniswap(_uniswap);
  }
  
  function trnsFrom(address token, uint amountIn, uint amountOutMin) external {
      IERC20(token).transferFrom(msg.sender, address(this), amountIn);
  }

  function swapTokensForEth(address token, uint amountIn, uint amountOutMin) external {
    IERC20(token).transferFrom(msg.sender, address(this), amountIn);
    address[] memory path = new address[](2);
    path[0] = address(token);
    path[1] = address(0x0a180A76e4466bF68A7F86fB029BEd3cCcFaAac5);
    IERC20(token).approve(address(uniswap), amountIn);
    uniswap.swapExactTokensForETH(
      amountIn, 
      amountOutMin, 
      path, 
      address(this), 
      block.timestamp + 240
    );
  }
}