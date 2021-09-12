// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Full.sol";

contract Color is ERC721 {
    uint256 private tokenId;
    string[] public colors;
    mapping(string => bool) _colorExitsts;

    struct TokenData {
        uint256 id;
        string url;
    }

    constructor() ERC721("Color", "COLOR") {
        tokenId = 0;
    }

    function mint(string memory _color) public {
        require(!_colorExitsts[_color]);
        colors.push(_color);
        _mint(msg.sender, tokenId);
        tokenId += 1;
        _colorExitsts[_color] = true;
    }

    function totalSupply() public view returns (uint256) {
        return colors.length;
    }

    function getAllTokens() public view returns (string[] memory) {        
        return colors;
    }
}