// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract FakePancakeRouter {

  function quote(uint amountA, uint reserveA, uint reserveB) public returns(uint) {

    return 10;
  }

  function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) public payable returns(uint, uint, uint) {

    return (10, 10, 10);
  }

  function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) public returns(uint, uint, uint) {

    return (10, 10, 10);
  }

  function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) public returns (uint, uint) {
    return (10, 10);
  }

  function removeLiquidityETH(address token, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) public returns (uint, uint) {
    return (10, 10);
  }

  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public returns (uint) {
    return 10;
  }
  
}