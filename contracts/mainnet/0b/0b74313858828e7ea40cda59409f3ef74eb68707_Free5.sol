/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$       /$$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/      | $$____/
| $$      | $$  \ $$| $$      | $$            | $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$         | $$$$$$$
| $$__/   | $$__  $$| $$__/   | $$__/         |_____  $$
| $$      | $$  \ $$| $$      | $$             /$$  \ $$
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

contract Free5 {
  IFree public immutable free;
  IArtBlocks public immutable artBlocks;

  mapping(uint256 => bool) public free0tokenIdUsed;
  mapping(uint256 => bool) public cgkTokenIdUsed;
  mapping(uint256 => bool) public isidTokenIdUsed;
  mapping(uint256 => bool) public fimTokenIdUsed;

  constructor(address freeAddr, address abAddr) {
    free = IFree(freeAddr);
    artBlocks = IArtBlocks(abAddr);
  }

  function claim(uint256 free0TokenId, uint256 cgkTokenId, uint256 isidTokenId, uint256 fimTokenId) public {
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0tokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free5');
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');

    require(artBlocks.tokenIdToProjectId(cgkTokenId) == 44, 'Invalid CGK');
    require(!cgkTokenIdUsed[cgkTokenId], 'This CGK has already been used to mint a Free5');
    require(artBlocks.ownerOf(cgkTokenId) == msg.sender, 'You must be the owner of this CGK');

    require(artBlocks.tokenIdToProjectId(isidTokenId) == 102, 'Invalid ISID');
    require(!isidTokenIdUsed[isidTokenId],  'This ISID has already been used to mint a Free5');
    require(artBlocks.ownerOf(isidTokenId) == msg.sender, 'You must be the owner of this ISID');

    require(artBlocks.tokenIdToProjectId(fimTokenId) == 152, 'Invalid FIM');
    require(!fimTokenIdUsed[fimTokenId], 'This FIM has already been used to mint a Free5');
    require(artBlocks.ownerOf(fimTokenId) == msg.sender, 'You must be the owner of this FIM');


    free0tokenIdUsed[free0TokenId] = true;
    cgkTokenIdUsed[cgkTokenId] = true;
    isidTokenIdUsed[isidTokenId] = true;
    fimTokenIdUsed[fimTokenId] = true;


    free.appendAttributeToToken(free0TokenId, 'Used For Free5 Mint', 'true');
    free.mint(5, msg.sender);
  }
}