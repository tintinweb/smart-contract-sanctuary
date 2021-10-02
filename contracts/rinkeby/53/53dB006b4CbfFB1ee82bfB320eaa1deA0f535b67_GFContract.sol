// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GFContract{
  mapping(address=>uint) public balances;

  constructor(){}

  function groupBalances( uint256 id, address owner ) public view returns (uint){
    if( id == 0 || owner == address(0) ){}

    return balances[owner];
  }

  function setBalance( uint newBalance ) public {
    balances[msg.sender] = newBalance;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}