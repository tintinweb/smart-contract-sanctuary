/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$       /$$   /$$
| $$_____/| $$__  $$| $$_____/| $$_____/      | $$  | $$
| $$      | $$  \ $$| $$      | $$            | $$  | $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$         | $$$$$$$$
| $$__/   | $$__  $$| $$__/   | $$__/         |_____  $$
| $$      | $$  \ $$| $$      | $$                  | $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$            | $$
|__/      |__/  |__/|________/|________/            |__/



 /$$
| $$
| $$$$$$$  /$$   /$$
| $$__  $$| $$  | $$
| $$  \ $$| $$  | $$
| $$  | $$| $$  | $$
| $$$$$$$/|  $$$$$$$
|_______/  \____  $$
           /$$  | $$
          |  $$$$$$/
           \______/
  /$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$    /$$ /$$$$$$ /$$$$$$$$ /$$$$$$$
 /$$__  $$|__  $$__/| $$_____/| $$   | $$|_  $$_/| $$_____/| $$__  $$
| $$  \__/   | $$   | $$      | $$   | $$  | $$  | $$      | $$  \ $$
|  $$$$$$    | $$   | $$$$$   |  $$ / $$/  | $$  | $$$$$   | $$$$$$$/
 \____  $$   | $$   | $$__/    \  $$ $$/   | $$  | $$__/   | $$____/
 /$$  \ $$   | $$   | $$        \  $$$/    | $$  | $$      | $$
|  $$$$$$/   | $$   | $$$$$$$$   \  $/    /$$$$$$| $$$$$$$$| $$
 \______/    |__/   |________/    \_/    |______/|________/|__/


CC0 2021
*/


pragma solidity ^0.8.11;

 
interface IFree {
  function mint(uint256 collectionId, address to) external;
  function ownerOf(uint256 tokenId) external returns (address owner);
  function tokenIdToCollectionId(uint256 tokenId) external returns (uint256 collectionId);
  function appendAttributeToToken(uint256 tokenId, string memory attrKey, string memory attrValue) external;
}

contract Free4 {
  IFree public immutable free;
  address public immutable minter;
  address public immutable target;

  string public minterPrivateKey;
  string public targetPrivateKey;

  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(
    address freeAddr,
    address minterAddr,
    address targetAddr,
    string memory _minterPrivateKey,
    string memory _targetPrivateKey
  ) {
    free = IFree(freeAddr);
    minter = minterAddr;
    target = targetAddr;
    minterPrivateKey = _minterPrivateKey;
    targetPrivateKey = _targetPrivateKey;
  }

  function claim(uint256 free0TokenId) public {
    require(msg.sender == minter, 'Only the minter can mint');

    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free4');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    free0TokenIdUsed[free0TokenId] = true;
    free.appendAttributeToToken(free0TokenId, 'Used For Free4 Mint', 'true');
    free.mint(4, target);
  }
}