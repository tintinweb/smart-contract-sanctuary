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
       address dc=0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe; // LendingPool
       // new Kovan LendingPool 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe
       // mainet 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9
       bytes  params='';
       address asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // kovan eth
       //uint256 amount=1000000000000000000;
    receive() external payable {
        // custom function code
    }
   
    function flashloan(address _receiver,uint256 _amount) public {
tok(dc).flashLoan(_receiver,asset,_amount,params);
    }
}