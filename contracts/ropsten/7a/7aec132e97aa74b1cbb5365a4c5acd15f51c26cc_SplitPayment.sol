/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.5.0;

contract SplitPayment {
  
  constructor() public  {
     
  }
  
  function send(address payable to) 
    payable 
    public {
    to.transfer(msg.value);
  }
}