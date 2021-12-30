// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";

contract NFT is ERC721Enumerable, Pausable {
    using Strings for uint256;

    string public baseURI;
    mapping(uint256 => string) _tokenURIs;

    mapping(address => bool) public hasMinted;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    // public
    function mint(string memory _tokenURI) public WhenNotPaused {
        require(!hasMinted[msg.sender], "duplicated");

        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        hasMinted[msg.sender] = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
}