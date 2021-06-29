// contracts/SimpleKeyValueStore.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

contract SimpleKeyValueStore{

    mapping(uint256 => address) public store;
    uint256 entryCount;

    constructor() {

    }

    function fill(uint256 startKey, uint256 count, address value) public returns(bool){
        for(uint256 i = startKey; i < startKey + count; i++){
            set(i, value);
        }
        return true;
    }

    function set(uint256 key, address value) public returns(bool){
        if(store[key] == address(0)){
            entryCount++;
        }
        store[key] = value;
        return true;
    }

    function get(uint256 key) public view returns(address){
        return store[key];
    }

    function storeSize() public view returns (uint256) {
        return entryCount;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}