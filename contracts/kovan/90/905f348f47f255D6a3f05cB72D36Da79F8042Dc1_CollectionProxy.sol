//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStatelessCollectionRegistry {
    function owner() external view returns (address);
    function update(bytes32 collection, bytes32 oldElement, bytes32 newElement) external;
}

contract CollectionProxy {
    IStatelessCollectionRegistry private immutable collectionRegistry;
    bytes32 public immutable collection;

    error MustBeCalledByOwner();
    error MismatchedLength();

    constructor(bytes32 _collection) {
        collection = _collection;
        collectionRegistry = IStatelessCollectionRegistry(msg.sender);
    }

    modifier onlyOwner {
        if (msg.sender != collectionRegistry.owner()) {
            revert MustBeCalledByOwner();
        }
        _;
    }

    function update(bytes32 oldElement, bytes32 newElement) external onlyOwner {
        collectionRegistry.update(collection, oldElement, newElement);
    }

    // Helper to reduce calldata
    function add(bytes32 newElement) external onlyOwner {
        collectionRegistry.update(collection, bytes32(0), newElement);
    }

    function batchUpdate(bytes32[] calldata oldElements, bytes32[] calldata newElements) external onlyOwner {
        if (oldElements.length != newElements.length) {
            revert MismatchedLength();
        }

        for (uint256 i = 0; i < oldElements.length; i += 1) {
            collectionRegistry.update(collection, oldElements[i], newElements[i]);
        }
    }

    // Helper to reduce calldata
    function batchAdd(bytes32[] calldata newElements) external onlyOwner {
        for (uint256 i = 0; i < newElements.length; i += 1) {
            collectionRegistry.update(collection, bytes32(0), newElements[i]);
        }
    }
}