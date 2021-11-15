// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract UCContract{
  mapping(address=>uint) public balances;

  constructor(){}

  function balanceOf( address owner ) public view returns (uint){
    if( owner == address(0) ){}

    return balances[owner];
  }

  function setBalance( uint newBalance ) public {
    balances[msg.sender] = newBalance;
  }
}

