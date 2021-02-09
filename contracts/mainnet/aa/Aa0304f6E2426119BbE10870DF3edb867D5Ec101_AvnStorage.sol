/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// File: contracts\interfaces\IAvnStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IAvnStorage {
  event LogStoragePermissionUpdated(address indexed publisher, bool status);

  function setStoragePermission(address publisher, bool status) external;
  function storeT2TransactionId(uint256 _t2TransactionId) external;
  function storeT2TransactionIdAndRoot(uint256 _t2TransactionId, bytes32 rootHash) external;
  function confirmLeaf(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
}

// File: contracts\Owned.sol


pragma solidity 0.7.5;

contract Owned {

  address public owner = msg.sender;

  event LogOwnershipTransferred(address indexed owner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner");
    _;
  }

  function setOwner(address _owner)
    external
    onlyOwner
  {
    require(_owner != address(0), "Owner cannot be zero address");
    emit LogOwnershipTransferred(owner, _owner);
    owner = _owner;
  }
}

// File: ..\contracts\AvnStorage.sol


pragma solidity 0.7.5;

contract AvnStorage is IAvnStorage, Owned {

  mapping (bytes32 => bool) public roots;
  mapping (uint256 => bool) public t2TransactionIds;
  mapping (address => bool) public isPermitted;

  modifier onlyPermitted() {
    require(isPermitted[msg.sender], "Storage access not permitted");
    _;
  }

  function setStoragePermission(address _address, bool _status)
    onlyOwner
    external
    override
  {
    isPermitted[_address] = _status;
    emit LogStoragePermissionUpdated(_address, _status);
  }

  function storeT2TransactionId(uint256 _t2TransactionId)
    onlyPermitted
    external
    override
  {
    doStoreT2TransactionId(_t2TransactionId);
  }

  function storeT2TransactionIdAndRoot(uint256 _t2TransactionId, bytes32 _root)
    onlyPermitted
    external
    override
  {
    doStoreT2TransactionId(_t2TransactionId);
    require(!roots[_root], "Root already exists");
    roots[_root] = true;
  }

  function confirmLeaf(bytes32 _leafHash, bytes32[] memory _merklePath)
    external
    view
    override
    returns (bool)
  {
    bytes32 rootHash = _leafHash;

    for (uint256 i; i < _merklePath.length; i++) {
      bytes32 node = _merklePath[i];
      if (rootHash < node)
        rootHash = keccak256(abi.encode(rootHash, node));
      else
        rootHash = keccak256(abi.encode(node, rootHash));
    }

    return roots[rootHash];
  }

  function doStoreT2TransactionId(uint256 _t2TransactionId)
    private
  {
    require(!t2TransactionIds[_t2TransactionId], "T2 transaction must be unique");
    t2TransactionIds[_t2TransactionId] = true;
  }
}