// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDarknodeRegistry {
    function numDarknodes() external view returns (uint256);

    function getDarknodes(address _start, uint256 _count) external view returns (address[] memory);

    function getDarknodeOperator(address _darknodeID) external view returns (address payable);
}

contract GetOperatorDarknodes {
    IDarknodeRegistry public darknodeRegistry;

    constructor(address _darknodeRegistry) {
        darknodeRegistry = IDarknodeRegistry(_darknodeRegistry);
    }

    function getOperatorDarknodes(address _operator) public view returns (address[] memory) {
        uint256 numDarknodes = darknodeRegistry.numDarknodes();
        address[] memory nodesPadded = new address[](numDarknodes);

        address[] memory allNodes = darknodeRegistry.getDarknodes(address(0), 0);

        uint256 j = 0;
        for (uint256 i = 0; i < allNodes.length; i++) {
            if (darknodeRegistry.getDarknodeOperator(allNodes[i]) == _operator) {
                nodesPadded[j] = (allNodes[i]);
                j++;
            }
        }

        address[] memory nodes = new address[](j);
        for (uint256 i = 0; i < j; i++) {
            nodes[i] = nodesPadded[i];
        }

        return nodes;
    }
}

{
  "evmVersion": "berlin",
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