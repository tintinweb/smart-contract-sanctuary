/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
  interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IDexRouter {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


contract SGGSBuy{
    address owner;
    constructor(){
        owner=msg.sender;
    }
    IDexRouter router=IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
    IBEP20 SGGS=IBEP20(0x464cEec72A5331b1478b101D2203EEed05dFf1F6);
    receive() external payable{
        address[] memory path = new address[](2);
        path[0] = router.WETH();
                path[1] = address(SGGS);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}(
            0,
            path,
            msg.sender,
            block.timestamp);
    }
    function WithdrawToken(address token) public{
        require(msg.sender==owner);
        IBEP20(token).transfer(msg.sender,IBEP20(token).balanceOf(address(this)));
    } 
}