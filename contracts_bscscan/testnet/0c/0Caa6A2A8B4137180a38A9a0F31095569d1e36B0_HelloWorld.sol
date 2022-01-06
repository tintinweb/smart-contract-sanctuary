/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

pragma solidity 0.8.11;

contract HelloWorld {
  string private message = "hello world";

  function getMessage() public view returns(string memory) {
    return message;
  }

  function setMessage(string memory newMessage) public {
    message = newMessage;
  }
}