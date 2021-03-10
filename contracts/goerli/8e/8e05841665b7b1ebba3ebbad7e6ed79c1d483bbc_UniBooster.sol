/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IUniswapV2Router02 {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external pure returns (uint[] memory amounts);
  function WETH() external pure returns (address);
  function factory() external view returns (address);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}
interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
}
contract UniBooster {
  address payable private owner;
  IUniswapV2Router02 private uniswapRouter;
  constructor() {
    owner = msg.sender;
    uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  }
  function run(IERC20 tokenA, IERC20 tokenB, uint256 reserve) public {
    uint256 maxAmount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint deadline = block.timestamp + (24 * 60 * 60);
    uint tokenAmount = tokenA.balanceOf(address(this));
    uint tokenAllowance = tokenA.allowance(address(this), address(uniswapRouter));
    if(tokenAllowance < tokenAmount) {
      tokenA.approve(address(uniswapRouter), maxAmount);
    }
    address[] memory path = new address[](2);
    path[0] = address(tokenA);
    path[1] = address(tokenB);
    uniswapRouter.swapExactTokensForTokens(tokenAmount, 1, path, address(this), deadline);
    path[0] = address(tokenB);
    path[1] = address(tokenA);
    tokenAmount = tokenB.balanceOf(address(this)) - reserve;
    require(tokenAmount > 0, "buyback failed");
    tokenAllowance = tokenB.allowance(address(this), address(uniswapRouter));
    if(tokenAllowance < tokenAmount) {
      tokenB.approve(address(uniswapRouter), maxAmount);
    }
    uniswapRouter.swapExactTokensForTokens(tokenAmount, 1, path, address(this), deadline);

  }
  function withdraw(IERC20 token) public {
    require(owner == msg.sender, "permission denied");
    uint amount = token.balanceOf(address(this));
    require(amount > 0, "zero balance");
    token.transfer(owner, amount);
  }
  function getAmountOut(uint amountIn, IERC20 tokenA, IERC20 tokenB) public view returns (uint) {
    IUniswapV2Factory uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
    address poolAddress = uniswapFactory.getPair(address(tokenA), address(tokenB));
    if(poolAddress == address(0)) {
      return uint(0);
    }
    uint tokenABalance = tokenA.balanceOf(poolAddress);
    uint tokenBBalance = tokenB.balanceOf(poolAddress);
    return uniswapRouter.getAmountOut(amountIn, tokenABalance, tokenBBalance);
  }
  function destroy() public {
    selfdestruct(owner);
  }
}