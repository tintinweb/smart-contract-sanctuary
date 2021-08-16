// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Pausable.sol";
import "Ownable.sol";
import "ERC721Burnable.sol";
import "Counters.sol";

contract MeikeNFT is ERC721, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MeikeNFT", "MEIKE") {}

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://raw.githubusercontent.com/Meike99/NFT/main/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}