//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

contract LendingPoolAddressesProvider{

    address lendingPool;

    constructor (address _lendingPool){
        lendingPool = _lendingPool;
    }

    function getLendingPool() public view returns(address){
        return lendingPool;
    }

}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
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