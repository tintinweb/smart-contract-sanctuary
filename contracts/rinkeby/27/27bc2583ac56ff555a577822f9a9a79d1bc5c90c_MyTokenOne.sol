/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;

contract MyTokenOne {
  mapping(address => uint256) public balaceOf;

  constructor(uint initSupply) public {
  balaceOf[msg.sender] = initSupply;
  }

  function transfer(address _to, uint256 _value) public returns(bool success){
    require(balaceOf[msg.sender] >= _value) ;
    require(balaceOf[_to] + _value >= balaceOf[_to]);
    balaceOf[_to];
    balaceOf[msg.sender] -= _value;
    balaceOf[_to] += _value;
    return true;
  }
}