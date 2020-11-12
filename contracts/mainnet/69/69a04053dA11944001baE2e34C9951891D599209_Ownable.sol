// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IOwnershipTransferrable.sol";

abstract contract Ownable is IOwnershipTransferrable {
  address private _owner;

  constructor(address owner) {
    _owner = owner;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) override external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
