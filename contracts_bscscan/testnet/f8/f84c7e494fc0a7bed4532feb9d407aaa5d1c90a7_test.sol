/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

pragma solidity ^0.5.0;

contract test {
uint256 public value;
  constructor() public {
   
  }
 function sendEther() public payable {
  value = msg.value ** 6; 
}
 function withdraw() public { //withdraw all ETH previously sent to this contract
    // msg.sender.transfer(address(this).(value/1000000000000000000));
}

}