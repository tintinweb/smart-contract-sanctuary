/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Reg {
  event NewReg(uint id, address owner, string displayName, string imageUrl);
 
  function createGravatar(uint _id, string memory _displayName, string memory _imageUrl) public {
    emit NewReg(_id, msg.sender, _displayName, _imageUrl);
  }

}