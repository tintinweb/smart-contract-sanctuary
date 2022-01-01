/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$        /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$__  $$
| $$      | $$  \ $$| $$      | $$            | $$  \__/
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$         | $$$$$$$
| $$__/   | $$__  $$| $$__/   | $$__/         | $$__  $$
| $$      | $$  \ $$| $$      | $$            | $$  \ $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$      |  $$$$$$/
|__/      |__/  |__/|________/|________/       \______/



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

interface IArtBlocks {
  function tokenIdToProjectId(uint256 tokenId) external returns (uint256 projectId);
  function ownerOf(uint256 tokenId) external returns (address owner);
}

interface IFastCashMoneyPlus {
  function balanceOf(address owner) external returns (uint256 balance);
}

contract Free6 {
  IFree public immutable free;
  IArtBlocks public immutable artBlocks;
  IFastCashMoneyPlus public immutable fastCashMoneyPlus;

  mapping(uint256 => bool) public free0tokenIdUsed;
  mapping(uint256 => bool) public fimTokenIdUsed;

  constructor(address freeAddr, address abAddr, address fastCashMoneyPlusAddr) {
    free = IFree(freeAddr);
    artBlocks = IArtBlocks(abAddr);
    fastCashMoneyPlus = IFastCashMoneyPlus(fastCashMoneyPlusAddr);
  }

  function claim(uint256 free0TokenId, uint256 fimTokenId) public {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0tokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free6');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(artBlocks.tokenIdToProjectId(fimTokenId) == 152, 'Invalid FIM');
    require(!fimTokenIdUsed[fimTokenId], 'This FIM has already been used to mint a Free6');
    require(artBlocks.ownerOf(fimTokenId) == msg.sender, 'You must be the owner of this FIM');

    require(fimTokenId % 152000000 <= 125, 'You must use a FIM that was minted with FastCash');
    require(fastCashMoneyPlus.balanceOf(msg.sender) >= 1000000000000000000, 'You must have a balance of at least 1 FastCash');

    free0tokenIdUsed[free0TokenId] = true;
    fimTokenIdUsed[fimTokenId] = true;

    free.appendAttributeToToken(free0TokenId, 'Used For Free6 Mint', 'true');
    free.mint(6, msg.sender);
  }
}