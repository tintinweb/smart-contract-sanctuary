/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity ^0.5.0;

contract EventTester {
   event Deposit(address indexed _from, bytes32 indexed _id, uint _value);
   function deposit(bytes32 _id) public payable {      
      emit Deposit(msg.sender, _id, msg.value);
   }
}