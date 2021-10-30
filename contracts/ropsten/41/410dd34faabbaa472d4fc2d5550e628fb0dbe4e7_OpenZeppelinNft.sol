// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";

contract OpenZeppelinNft is ERC721PresetMinterPauserAutoId {
    constructor(string memory name, string memory symbol, string memory baseTokenURI)
        ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI)
    {
    }
}