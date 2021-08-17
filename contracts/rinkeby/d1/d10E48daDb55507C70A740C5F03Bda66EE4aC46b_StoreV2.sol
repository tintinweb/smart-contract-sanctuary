//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "@openzeppelin/contracts/access/Ownable.sol";

interface StoreInterfaceV2 {
    function getValue() external returns(uint256);
    function incrementValue() external;
}

contract StoreV2 is StoreInterfaceV2{
    //State Variables
    uint256 private value;

    //Events
    event Stored(uint256 indexed _value);

    //Functions
    function storeValue(uint256 _value) external {
        value = _value;
        emit Stored(_value);
    }

    function getValue() external view override returns(uint256) {
        return value;
    }

    function incrementValue() external override {
        value += 1;
        emit Stored(value);
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