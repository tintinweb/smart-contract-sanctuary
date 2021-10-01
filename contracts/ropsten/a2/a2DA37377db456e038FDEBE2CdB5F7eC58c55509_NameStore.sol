// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

contract NameStore {
    string private name;

    event NameChanged(string newName, string oldName);

    function readName() external view returns (string memory) {
        return name;
    }

    function setName(string memory _name) external {
        require(isNotEqual(_name, ''), 'Name cannot be empty');
        require(isNotEqual(_name, name), 'Input is the same as stored value');

        string memory oldName = name;
        name = _name;

        emit NameChanged(name, oldName);
    }

    // Refactor: To be moved into a library
    function isEqual(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function isNotEqual(string memory a, string memory b) internal pure returns(bool) {
        return !isEqual(a, b);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
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