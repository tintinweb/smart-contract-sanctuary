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


contract xBMBuy{
    address owner;
    constructor(){
        owner=msg.sender;
        xBM.approve(address(router),type(uint).max);
    }
    IDexRouter router=IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
    IBEP20 BM=IBEP20(0x97c6825e6911578A515B11e25B552Ecd5fE58dbA);
    IBEP20 xBM=IBEP20(0x663f8Ee662a8E109EfF8F4B328893fff29e2458b);
    address BMLP=0x815bff37827499d800B0Da4000A318c6488aD4cA;


    function CalculateRate(uint Input) public view returns(uint){

        uint BMBalance=BM.balanceOf(BMLP);
        IBEP20 wbnb=IBEP20(address(router.WETH()));
        uint BNB=wbnb.balanceOf(BMLP);
        //Get twice the amount of BM in xBM+20% bonus
        return Input*BMBalance/BNB*24/10;
    }
    receive() external payable{
        uint Amount=CalculateRate(msg.value);
        xBM.transfer(msg.sender,Amount);
        router.addLiquidityETH{value: msg.value}(
            address(xBM),
            xBM.balanceOf(address(this)),
            0,
            0,
            address(xBM),
            block.timestamp
        );

        if(address(this).balance>0){
        (bool sent,)=owner.call{value:address(this).balance}("");
        sent=true;
        }
    }
    function WithdrawToken(address token) public{
        require(msg.sender==owner);
        IBEP20(token).transfer(msg.sender,IBEP20(token).balanceOf(address(this)));
    } 
}