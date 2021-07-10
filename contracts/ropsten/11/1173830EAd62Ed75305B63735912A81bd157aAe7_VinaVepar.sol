// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract VinaVepar is ERC721{
    
    uint256 public tokenCounter;
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    constructor() public ERC721 ("Vina Vepar", "VEPAR"){
        tokenCounter=0;
    }
    
     //ST
    // Optional mapping for token URIs
    mapping (uint256 => bytes) private _tokenData;

    function _createNFT (string memory tokenURI, bytes memory data) public virtual {
        uint256 newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId, data);
        _setTokenURI(newItemId, tokenURI);
        _tokenData[newItemId] = data;
        tokenCounter = tokenCounter + 1;
        
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
            require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
            _tokenURIs[tokenId] = _tokenURI;
    }
    
    function _getTokenURI(uint256 tokenId) public view virtual returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            string memory _tokenURI = _tokenURIs[tokenId];
            return _tokenURI;
    }

    function _getTokenData(uint256 tokenId) public view virtual returns (bytes memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            return _tokenData[tokenId];
    }
   //ST
        
}