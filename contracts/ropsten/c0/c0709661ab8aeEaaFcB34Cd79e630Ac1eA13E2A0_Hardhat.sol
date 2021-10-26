// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

contract Hardhat {
  uint number;

  constructor(){
    number = 0;
  }

  function setNum(uint _num) public {
    number = _num;
  }

  function getNum() public view returns(uint){
    return number;
  }
}

// npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"