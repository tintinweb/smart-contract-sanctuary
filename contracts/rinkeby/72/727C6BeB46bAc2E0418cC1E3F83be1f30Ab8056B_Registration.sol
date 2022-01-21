//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
  @title Registration
  @dev Implementation of a registration contracts that node operators can register node operator addresses to
*/
contract Registration {
  address[] public registeredNodes;
  mapping(address => bool) public isNodeRegistered;

  event OracleRegistered(address indexed _nodeAddress);

  /// @notice Register a node operator address to the contract
  /// @param _nodeAddress The node address to register
  function register(address _nodeAddress) external {
    require(_nodeAddress != address(0), "Registration: cannot register zero address");
    registeredNodes.push(_nodeAddress);
    isNodeRegistered[_nodeAddress] = true;
    emit OracleRegistered(_nodeAddress);
  }

  /// @notice Returns the addresses of registered nodes
  /// @return _registeredNodes An array of registered node addresses
  function getRegisteredNodes() external view returns (address[] memory) {
    return registeredNodes;
  }

  /// @notice Returns the number of registered nodes
  /// @return _numRegisteredNodes The number of registered nodes
  function getNumRegisteredNodes() external view returns (uint256) {
    return registeredNodes.length;
  }
}