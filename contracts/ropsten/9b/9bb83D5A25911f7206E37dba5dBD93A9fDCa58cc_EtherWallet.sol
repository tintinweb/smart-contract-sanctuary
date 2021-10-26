// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EtherWallet {
  address payable public owner;

  constructor(address payable _owner) {
    owner = _owner;
  }

  function costs(uint _amount) payable public {
    payable(msg.sender).transfer(1 ether - _amount);
  }
  
  function getEthBalance(address _addr) view public returns(uint) {
    return _addr.balance;
  }

  function send(address payable to) public payable {
    if(msg.sender == owner) {
      to.transfer(msg.value);
      return;
    } 
    revert('sender is not allowed');
  }

  function balanceOf() view public returns(uint) {
    return address(this).balance;
  }
}