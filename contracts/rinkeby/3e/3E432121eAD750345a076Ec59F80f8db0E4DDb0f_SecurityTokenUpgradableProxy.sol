// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import './lib/Proxy.sol';

/**
 * @title SecurityTokenUpgradableProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract SecurityTokenUpgradableProxy is Proxy {
  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant implementationPosition = keccak256("org.zeppelinos.proxy.implementation");

  // Storage position of the owner of the contract
  bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
   * @dev Constructor function
   */
  constructor(address _implementation) {
    setImplementation(_implementation);
    setProxyOwner(msg.sender);
  }

  /**
   * @dev Tells the address of the owner
   * @return owner the address of the owner
   */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }
  /**
   * @dev Tells the address of the current implementation
   * @return impl address of the current implementation
   */
  function implementation() public view override returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param _implementation address representing the new implementation to be set
   */
  function setImplementation(address _implementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, _implementation)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param _proxyOwner address representing the new implementation to be set
   */
  function setProxyOwner(address _proxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, _proxyOwner)
    }
  }

  /**
   * @dev Upgrades the implementation address
   * @param _implementation representing the address of the new implementation to be set
   */
  function upgradeTo(address _implementation) external onlyProxyOwner {
    require(_implementation != address(0));
    address currentImplementation = implementation();
    require(currentImplementation != _implementation);
    setImplementation(_implementation);
    emit Upgraded(_implementation);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public virtual view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback () payable external {
    address _impl = implementation();
    require(_impl != address(0));
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

