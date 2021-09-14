// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract NewCollectionEvt {
    event NewCollection(
        uint256 indexed _collectionId,
        uint256 indexed _subCollectionId,
        uint256 indexed _requestId,
        uint256 _maxEdition,
        address _collectionAddr
    );

    constructor() {
    }

    function emitEvent(
        uint256 _collectionId,
        uint256 _subCollectionId,
        uint256 _requestId,
        uint256 _maxEdition,
        address _collectionAddr
    ) external {
        emit NewCollection(_collectionId, _subCollectionId, _requestId, _maxEdition, _collectionAddr);
    }
}

{
  "optimizer": {
    "enabled": false,
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