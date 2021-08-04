// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721PresetMinterPauserAutoId.sol';

contract Jarvis is ERC721PresetMinterPauserAutoId {
    constructor() ERC721PresetMinterPauserAutoId("Jarvis Token", "JVT", "")  {}
}