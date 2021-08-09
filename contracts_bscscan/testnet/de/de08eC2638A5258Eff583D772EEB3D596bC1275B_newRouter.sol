/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;


contract newRouter{
    
   uint256  public recBnb =0;
   
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline )  external  virtual   payable 
    {
        recBnb = recBnb + msg.value;
    }
    
    function wihtdrawToUser(uint256 amount) public {
        payable(msg.sender).transfer(amount); 
    }
    function WETH() public pure returns (address){
        return 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    }
    
    function thisBalance () public view returns(uint256){
        return address(this).balance;
    }
}