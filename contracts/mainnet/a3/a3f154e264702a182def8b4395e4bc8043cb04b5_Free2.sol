/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$        /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$__  $$
| $$      | $$  \ $$| $$      | $$            |__/  \ $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$           /$$$$$$/
| $$__/   | $$__  $$| $$__/   | $$__/          /$$____/
| $$      | $$  \ $$| $$      | $$            | $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$      | $$$$$$$$
|__/      |__/  |__/|________/|________/      |________/



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

// 0x4f857a92269dc9b42edb7fab491679decb46e848
interface INVCMinter {
  function usedIOUs(uint256 iouId) external returns (bool used);
}

interface IIOU {
  function ownerOf(uint256 tokenId) external returns (address owner);
}

interface IFree1 {
  function free0TokenIdUsed(uint256 tokenId) external returns (bool used);
}

contract Free2 {
  IFree public immutable free;
  IFree1 public immutable free1Contract;
  INVCMinter public immutable nvcMinter;
  IIOU public immutable iouContract;

  mapping (uint256 => bool) public usedIOUs;
  mapping(uint256 => bool) public free0TokenIdUsed;

  constructor(address freeAddr, address free1Addr, address iouAddr, address nvcMinterAddr) {
    free = IFree(freeAddr);
    free1Contract = IFree1(free1Addr);
    nvcMinter = INVCMinter(nvcMinterAddr);
    iouContract = IIOU(iouAddr);
  }

  function claim(uint256 iouId, uint256 free0TokenId) public {
    require(iouContract.ownerOf(iouId) == msg.sender, 'You must be the owner of this IOU');
    require(nvcMinter.usedIOUs(iouId), 'You must use an IOU that has minted a NVC');
    require(!usedIOUs[iouId], 'This IOU has already minted a Free2');

    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(
      free1Contract.free0TokenIdUsed(free0TokenId) == true,
      'You must use a Free0 that has already minted a Free1'

    );
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free2');
    free.appendAttributeToToken(free0TokenId, 'Used For Free2 Mint', 'true');


    usedIOUs[iouId] = true;
    free0TokenIdUsed[free0TokenId] = true;

    free.mint(2, msg.sender);
  }
}