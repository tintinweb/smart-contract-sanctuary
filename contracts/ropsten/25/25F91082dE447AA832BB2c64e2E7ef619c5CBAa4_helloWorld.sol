// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract helloWorld{
  //state variables
  //functions to manioulate the state
  //events
  event updateMessage(string oldStr,string newStr);

  string public message;
  
  constructor(string memory initMsg){
    message = initMsg;
  }

function update(string memory newMsg)public {
  message = newMsg;
  string memory oldMessage = message;
  emit updateMessage(oldMessage, newMsg);
}

}