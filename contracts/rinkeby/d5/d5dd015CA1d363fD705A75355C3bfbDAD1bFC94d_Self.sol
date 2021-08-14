// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

address payable constant level7 = payable(
    0xE1Ec04a91cCd5686b053eA8892FF6fBeE141f3C1
);

contract Self {
    function end() public {
        selfdestruct(level7);
    }

    receive() external payable {}
}

{
  "evmVersion": "london",
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