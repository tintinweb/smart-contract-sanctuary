/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

interface tok {
  function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes calldata _params)  external ; 
    
}
 
  contract  Flashloan   {
    address ownr;
    constructor()  public {
        ownr = msg.sender;
    }
       mapping(address => uint256) balances;
       address dc=0x580D4Fdc4BF8f9b5ae2fb9225D584fED4AD5375c; // LendingPool
       bytes  params='';
       address asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // kovan eth
       //uint256 amount=1000000000000000000;
       function deposit () public payable{
           balances[msg.sender] += msg.value;
      }
   
    function flashloan(address _receiver,uint256 _amount) public {
tok(dc).flashLoan(_receiver,asset,_amount,params);
    }
}