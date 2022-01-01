/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$         /$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$$$
| $$      | $$  \ $$| $$      | $$            |_  $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           | $$
| $$__/   | $$__  $$| $$__/   | $$__/           | $$
| $$      | $$  \ $$| $$      | $$              | $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$       /$$$$$$
|__/      |__/  |__/|________/|________/      |______/



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

contract Free1 {
  IFree public immutable free;

  uint public mintCount;
  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr) {
    free = IFree(freeAddr);
  }

  function claim(uint free0TokenId) public {
    require(mintCount < 1000, 'Cannot mint more than 1000');
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free1');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    free0TokenIdUsed[free0TokenId] = true;
    mintCount++;
    free.appendAttributeToToken(free0TokenId, 'Used For Free1 Mint', 'true');

    free.mint(1, msg.sender);
  }
}