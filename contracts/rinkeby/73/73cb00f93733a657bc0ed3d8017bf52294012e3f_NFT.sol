// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './ERC721.sol';

contract NFT is ERC721 {
  constructor() ERC721('AirDrop', 'ANFT') {
    _mint(msg.sender, 0);
    _mint(msg.sender, 1);
    _mint(msg.sender, 2);
  }
}