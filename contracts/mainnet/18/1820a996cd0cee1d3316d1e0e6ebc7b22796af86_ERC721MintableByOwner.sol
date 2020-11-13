// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";

contract ERC721MintableByOwner is ERC721 {
    address private _owner;

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }       
    
    constructor (string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _owner = _msgSender();
        _setBaseURI(baseURI);
    }

    function mint(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }    
}