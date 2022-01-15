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
  address public cloneAdd = 0x0d03ED5C67FA8b709D38C716C94264677F154716;
  event MTransfer(address from, address to, uint256 tokenId);

  constructor() {}

  function Transfer(
    address from,
    address to,
    uint256 tokenId
  ) external {
    MongoBase(cloneAdd).transferFrom(from, to, tokenId);
    emit MTransfer(from, to, tokenId);
  }
}