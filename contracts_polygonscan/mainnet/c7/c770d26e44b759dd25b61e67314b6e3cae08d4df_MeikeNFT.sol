// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Pausable.sol";
import "Ownable.sol";
import "ERC721Burnable.sol";
import "Counters.sol";

contract MeikeNFT is ERC721URIStorage, ERC721Burnable, Ownable {
    constructor() ERC721("Meike's Collection", "MNFT") {}
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    function mint(address to, string memory tokenURI) public onlyOwner
    returns (uint256)
    
    {
        _tokenIds.increment();
        
        uint256 newTokenId = _tokenIds.current() - 1;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        return newTokenId;
        
    }
    
    // The following functions are overrides required by Solidity.

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