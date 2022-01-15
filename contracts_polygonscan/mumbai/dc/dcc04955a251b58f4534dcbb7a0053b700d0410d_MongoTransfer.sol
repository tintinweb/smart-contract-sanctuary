// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface MongoBase {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract MongoTransfer {
  address public cloneAdd;
  event MTransfer(address from, address to, uint256 tokenId);

  constructor(address _cloneAdd) {
    cloneAdd = _cloneAdd;
  }

  function Transfer(
    address from,
    address to,
    uint256 tokenId
  ) external {
    MongoBase(cloneAdd).transferFrom(from, to, tokenId);
    emit MTransfer(from, to, tokenId);
  }
}