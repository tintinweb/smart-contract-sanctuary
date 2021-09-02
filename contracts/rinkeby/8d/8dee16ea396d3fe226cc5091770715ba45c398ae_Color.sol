// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

contract Color is ERC721Enumerable {
    string[] public tokens;
    mapping(string => bool) tokens_existence;

    constructor() ERC721("Color", "COL") {}

    function mint(string memory token) public {
        require(!tokens_existence[token]);
        tokens.push(token);
        _mint(msg.sender, tokens.length);
        tokens_existence[token] = true;
    }
}