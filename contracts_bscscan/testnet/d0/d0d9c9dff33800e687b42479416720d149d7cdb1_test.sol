/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

pragma solidity ^0.5.0;

contract test {
  
  constructor() public {
   
  }
 function sendEther() public payable {
 
}
 function withdraw() public { //withdraw all ETH previously sent to this contract
    msg.sender.transfer(address(this).balance);
}
}