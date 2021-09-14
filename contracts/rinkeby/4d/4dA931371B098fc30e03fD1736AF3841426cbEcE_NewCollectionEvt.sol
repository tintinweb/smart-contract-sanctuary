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
    event CollectionMintSingle(
        address indexed _to,
        address indexed _nft,
        uint256 _id
    );
    event CollectionMintBatch(
        address indexed _to,
        address indexed _nft,
        uint256[] _ids,
        uint256 _amount
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

    function emitMintSingle(
        address _to,
        address _nft,
        uint256 _id
    ) external {
        emit CollectionMintSingle(_to, _nft, _id);
    }

    function emitMintBatch(
        address _to,
        address _nft,
        uint256[] calldata _ids,
        uint256 _amount
    ) external {
        emit CollectionMintBatch(_to, _nft, _ids, _amount);
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