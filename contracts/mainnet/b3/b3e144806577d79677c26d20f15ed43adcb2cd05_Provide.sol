/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


/// @title Proxy
/// @dev Proxy contract which supports upgrading a singleton implementation delegate.
abstract contract Proxy {

  /// @dev retrieve the address of the current implementation contract
  /// @return impl address of the current implementation
  function __implementation() public virtual view returns (address impl);

  /// @dev delegatecall is issued against the current implementation delegate;
  /// any return data is forwarded to the caller.
  fallback() external payable {
    address _impl = __implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0x0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0x0, 0x0)
      let size := returndatasize()
      returndatacopy(ptr, 0x0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

  /// @dev no-op receipt of ETH
  receive() external payable {}
}

/// @title UpgradableProxy
/// @dev proxy contract with upgradable implementation delegate address
contract UpgradableProxy is Proxy {

  // storage address of the implementation delegate contract address
  bytes32 private constant implStorageAddress = keccak256("network.provide.proxy.implementation");

  /// @dev event emitted upon upgrade of the implementation address
  /// @param implementation address of the upgraded implementation delegate
  event Upgraded(address indexed implementation);

  /// @dev retrieve the address of the current implementation contract
  /// @return impl address of the current implementation
  function __implementation() public override view returns (address impl) {
    bytes32 _saddr = implStorageAddress;
    assembly {
      impl := sload(_saddr)
    }
  }

  /// @dev set the address of the current implementation contract
  /// @param _implementation address representing the new implementation to be set
  function __setImplementation(address _implementation) internal {
    address _current = __implementation();
    require(_current != _implementation, 'given implementation contract address is already set');

    bytes32 _saddr = implStorageAddress;
    assembly {
      sstore(_saddr, _implementation)
    }

    emit Upgraded(_implementation);
  }
}

/// @title UpgradableNetwork
/// @dev provide.network upgradable contracts suite entrypoint
contract UpgradableNetwork is UpgradableProxy {

  // storage address of the contract owner
  bytes32 private constant ownerStorageAddress = keccak256("network.provide.proxy.owner");

  /// @dev event emitted upon a transfer of ownership
  /// @param from address of the previous owner
  /// @param to address of the new owner
  event OwnershipTransferred(address from, address to);

  /// initialize the contract owner to the sender
  constructor() {
    __setOwner(msg.sender);
  }

  /// @dev require `msg.sender == owner`
  modifier onlyOwner() {
    require(msg.sender == __owner());
    _;
  }

  /// @dev read the address of the owner
  /// @return owner_ the address of the owner
  function __owner() public view returns (address owner_) {
    bytes32 _position = ownerStorageAddress;
    assembly {
      owner_ := sload(_position)
    }
  }

  /// @dev internally set the owner
  /// @param _owner address of the new owner
  function __setOwner(address _owner) internal {
    bytes32 _position = ownerStorageAddress;
    assembly {
      sstore(_position, _owner)
    }
  }

  /// @dev transfer ownership to the given address
  /// @param _owner address to which ownership will be transferred
  function __transferOwnership(address _owner) public onlyOwner {
    require(_owner != address(0), 'ownership cannot be transferred to 0x');
    emit OwnershipTransferred(__owner(), _owner);
    __setOwner(_owner);
  }

  /// @dev allows the proxy owner to upgrade the proxy by modifying the implementation contract address
  /// @param _implementation representing the address of the new implementation to be set.
  function __upgrade(address _implementation) public onlyOwner {
    __setImplementation(_implementation);
  }

  /// @dev upgrade the current implementation delegate contract by modifying the address
  /// and passing calldata to the new implementation for initialization
  /// @param _implementation representing the address of the new implementation to be set.
  /// @param _data represents the msg.data to bet sent in the low level call. This parameter may include the function
  /// signature of the implementation to be called with the needed payload
  function __upgradeInit(address _implementation, bytes calldata _data) public payable onlyOwner {
    __upgrade(_implementation);
    (bool _success,  ) = address(this).call{value: msg.value}(_data);
    require(_success, 'failed to upgrade implementation contract');
  }
}

/// @title Provide
/// @dev provide.network upgradable entrypoint
contract Provide is UpgradableNetwork {

  /// @dev initialize the upgradable proxy entrypoint with
  /// the initial network implementation contract
  constructor(address _network) {
    __setOwner(msg.sender);

    if (_network != address(0)) {
      __upgrade(_network);
    }
  }
}