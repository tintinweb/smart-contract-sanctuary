/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-14
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract MessageLogger {

  string private _message;

  event MessageSet(string message);

  constructor(string memory message_){
    _message = message_;
  }

  function setMessage(string memory message_) public {
    _message = message_;
    emit MessageSet(message_);
  }

  function getMessage() public view returns (string memory) {
    return _message;
  }
}