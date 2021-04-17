//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


contract SimpleStorageUpgradeV2 {

    uint storedData;
    bytes storedKey;

    event Change(string message, uint newVal);

    function set(uint x) public {
        require(x < 10000, "Should be less than 10000");
        storedData = x;
        emit Change("set", x);
    }

    function get() public view returns (uint) {
        return storedData;
    }

    function setKey(bytes memory key) public {
        storedKey = key;
    }

    function getKey() public view returns (bytes memory) {
        return storedKey;
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