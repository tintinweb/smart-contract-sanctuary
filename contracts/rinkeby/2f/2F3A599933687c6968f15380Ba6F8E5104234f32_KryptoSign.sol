// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract KryptoSign {
    
    event DocumentPublished(uint256 id);

    mapping (uint256 => string) documentMetadata;

    uint256 latestDocumentId;

    constructor () { 
        latestDocumentId = 1;
    }
    
    function publishDocument(string memory metadata) external {
        documentMetadata[latestDocumentId] = metadata;
        emit DocumentPublished(latestDocumentId);
        latestDocumentId++;
    }

    function getDocument(uint256 documentId) external view returns (string memory) {
        return documentMetadata[documentId];
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