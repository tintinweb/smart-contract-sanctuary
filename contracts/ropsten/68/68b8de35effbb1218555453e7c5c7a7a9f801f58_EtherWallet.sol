/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherWallet {
  address payable public owner;

  constructor(address payable _owner) {
    owner = _owner;
  }

  function deposit() payable public {
  }

  function send(address payable to, uint amount) public {
    if(msg.sender == owner) {
      to.transfer(amount);
      return;
    } 
    revert('sender is not allowed');
  }

  function balanceOf() view public returns(uint) {
    return address(this).balance;
  }
}