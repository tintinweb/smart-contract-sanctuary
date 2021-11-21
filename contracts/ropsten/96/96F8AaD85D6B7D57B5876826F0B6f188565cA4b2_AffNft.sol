// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";

contract AffNft is ERC721PresetMinterPauserAutoId {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) ERC721PresetMinterPauserAutoId(name_, symbol_, baseTokenURI_) {}
}