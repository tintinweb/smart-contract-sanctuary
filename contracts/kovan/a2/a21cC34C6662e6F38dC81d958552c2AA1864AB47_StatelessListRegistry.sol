//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ListProxy.sol";

contract StatelessListRegistry is Ownable {
    mapping(bytes32 => address) public listToProxy;

    event ListCreated(bytes32 indexed list, address proxy);
    event ElementAdded(bytes32 indexed list, bytes32 newElement);
    event ElementRemoved(bytes32 indexed list, bytes32 oldElement);
    event ElementUpdated(bytes32 indexed list, bytes32 oldElement, bytes32 newElement);

    error MustBeCalledByOwnerOrProxy();

    function createList(bytes32 list) external returns (address proxy) {
        proxy = address(new ListProxy{ salt: bytes32(0) }(list));
        listToProxy[list] = proxy;

        emit ListCreated(list, proxy);
    }

    function update(bytes32 list, bytes32 oldElement, bytes32 newElement) external {
        if (msg.sender != owner && msg.sender != listToProxy[list]) {
            revert MustBeCalledByOwnerOrProxy();
        }

        if (oldElement == bytes32(0)) {
            emit ElementAdded(list, newElement);
        } else if (newElement == bytes32(0)) {
            emit ElementRemoved(list, oldElement);
        } else {
            emit ElementUpdated(list, oldElement, newElement);
        }
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

interface IStatelessListRegistry {
    function owner() external view returns (address);
    function update(bytes32 list, bytes32 oldElement, bytes32 newElement) external;
}

contract ListProxy {
    IStatelessListRegistry private immutable listRegistry;
    bytes32 public immutable list;

    error MustBeCalledByOwner();
    error MismatchedLength();

    constructor(bytes32 _list) {
        list = _list;
        listRegistry = IStatelessListRegistry(msg.sender);
    }

    modifier onlyOwner {
        if (msg.sender != listRegistry.owner()) {
            revert MustBeCalledByOwner();
        }
        _;
    }

    function update(bytes32 oldElement, bytes32 newElement) external onlyOwner {
        listRegistry.update(list, oldElement, newElement);
    }

    function batchUpdate(bytes32[] calldata oldElements, bytes32[] calldata newElements) external onlyOwner {
        if (oldElements.length != newElements.length) {
            revert MismatchedLength();
        }

        for (uint256 i = 0; i < oldElements.length; i += 1) {
            listRegistry.update(list, oldElements[i], newElements[i]);
        }
    }
}