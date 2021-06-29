pragma solidity ^0.8.5;

contract Whitelist {
    mapping(address => bool) public addresses;

    function join() public {
        addresses[msg.sender] = true;
    }

    function isAddressWhitelisted(address address_) public view returns (bool) {
        return addresses[address_];
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "berlin",
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