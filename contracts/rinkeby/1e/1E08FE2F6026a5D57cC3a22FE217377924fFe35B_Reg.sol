// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Reg {
  event RegLog(uint id, address owner, string displayName, string imageUrl);
 
  function NewReg(uint _id, string memory _displayName, string memory _imageUrl) public {
    emit RegLog(_id, msg.sender, _displayName, _imageUrl);
  }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
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