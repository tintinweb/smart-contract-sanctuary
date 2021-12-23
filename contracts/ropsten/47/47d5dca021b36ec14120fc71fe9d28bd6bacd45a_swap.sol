/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.6.2;

interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswap {
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
  function WETH() external pure returns (address);
  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

}

/**
 * @title Swap
 * @dev Swap Contract to swap exact token in reference to ETH  
 */
contract swap {

  //variable to store uniswap router contract address
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  uint256[] private amount;

  //address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  IUniswap public uniswap;

  constructor() public {
    uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
  }

  function ethAmount(uint amounts, address token) public view returns(uint256[] memory){
    address[] memory path = new address[](2);
    path[0] = uniswap.WETH();
    path[1] = token;
    return uniswap.getAmountsIn(amounts,path);
  }

  function testSwapExactETHForTokens(uint amountOut, address token) external payable {
    require(token != address(0),"Invalid Token Address, Please Try Again!!!"); 
    require(amountOut > 0,"Amount is invalid or zero, Please Try Again!!!");
    //IERC20(token).transferFrom(msg.sender, address(this), amountOut);
    //IERC20(token).approve(UNISWAP_ROUTER_ADDRESS, amountOut);
    address[] memory path = new address[](2);
    path[0] = uniswap.WETH();
    path[1] = token;
    //amount = uniswap.getAmountsIn(amountOut,path);
    uniswap.swapExactETHForTokens{value: msg.value}(amountOut, path, msg.sender, now+3600);
  }

  receive() external payable {}
  fallback() external payable {}
  
}