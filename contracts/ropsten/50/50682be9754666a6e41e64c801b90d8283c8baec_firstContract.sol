/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.4.22 <0.9.0;

contract firstContract{
  string public message;

  constructor (string memory newMessage){
    message = newMessage;
  }

  function setMessage(string memory newMessage) public{
    message = newMessage;
  }

  function getMessage() public view returns(string memory){
    return message;
  }

  function Payment() payable public returns(string memory){
    require(msg.value > 1 ether);
    return "money deposited";
  }
  

}