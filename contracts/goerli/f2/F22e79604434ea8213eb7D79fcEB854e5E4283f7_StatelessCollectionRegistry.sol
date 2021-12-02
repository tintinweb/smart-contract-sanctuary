//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./CollectionProxy.sol";

contract StatelessCollectionRegistry is Ownable {
    mapping(bytes32 => address) public collectionToProxy;

    event CollectionCreated(bytes32 indexed collection, address proxy);
    event CollectionArchived(bytes32 indexed collection);
    event ElementAdded(bytes32 indexed collection, bytes32 newElement);
    event ElementRemoved(bytes32 indexed collection, bytes32 oldElement);
    event ElementUpdated(bytes32 indexed collection, bytes32 oldElement, bytes32 newElement);

    error MustBeCalledByOwnerOrProxy();

    function createCollection(bytes32 collection) external returns (address proxy) {
        proxy = address(new CollectionProxy{ salt: bytes32(0) }(collection));
        collectionToProxy[collection] = proxy;

        emit CollectionCreated(collection, proxy);
    }

    function update(bytes32 collection, bytes32 oldElement, bytes32 newElement) external {
        if (msg.sender != owner && msg.sender != collectionToProxy[collection]) {
            revert MustBeCalledByOwnerOrProxy();
        }

        if (oldElement == bytes32(0)) {
            emit ElementAdded(collection, newElement);
        } else if (newElement == bytes32(0)) {
            emit ElementRemoved(collection, oldElement);
        } else {
            emit ElementUpdated(collection, oldElement, newElement);
        }
    }

    function archiveCollection(bytes32 collection) external {
        if (msg.sender != owner && msg.sender != collectionToProxy[collection]) {
            revert MustBeCalledByOwnerOrProxy();
        }

        emit CollectionArchived(collection);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed newOwner);

  error MustBeCalledByOwner();

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(msg.sender);
  }

  modifier onlyOwner {
    if (msg.sender != owner) {
      revert MustBeCalledByOwner();
    }
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    owner = newOwner;
    emit OwnershipTransferred(newOwner);
  }
}

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