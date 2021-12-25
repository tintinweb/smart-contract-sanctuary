/**
 *Submitted for verification at polygonscan.com on 2021-12-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test{
    event Transact(
    address sender,
    string message
  );

  function emitter(string memory _msg) public {
      emit Transact(msg.sender,_msg);
  }
}