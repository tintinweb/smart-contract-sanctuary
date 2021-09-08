/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// File: contracts\interfaces\IAvnFTSMStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IAvnFTSMStorage {
  event LogFTSMStoragePermissionUpdated(address indexed publisher, bool status);

  function setStoragePermission(address publisher, bool status) external;
  function storeLiftProof(bytes32 proof) external;
  function storeLoweredLeafHash(bytes32 leafHash) external;
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

// File: ..\contracts\AvnFTSMStorage.sol


pragma solidity 0.7.5;

contract AvnFTSMStorage is IAvnFTSMStorage, Owned {

  mapping (bytes32 => bool) public hasLowered;
  mapping (bytes32 => bool) public erc20LiftProofs;
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
    emit LogFTSMStoragePermissionUpdated(_address, _status);
  }

  function storeLiftProof(bytes32 _proof)
    onlyPermitted
    external
    override
  {
    require(!erc20LiftProofs[_proof], "Lift proof already used");
    erc20LiftProofs[_proof] = true;
  }

  function storeLoweredLeafHash(bytes32 _leafHash)
    onlyPermitted
    external
    override
  {
    require(!hasLowered[_leafHash], "Already lowered");
    hasLowered[_leafHash] = true;
  }
}