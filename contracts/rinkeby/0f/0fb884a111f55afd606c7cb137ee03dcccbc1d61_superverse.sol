// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";


contract superverse is ERC721URIStorage, Ownable {
    
    constructor() ERC721("superverse", "superverse") {
 
    }
    
    function mint(address to, uint256 tokenId, string memory tokenURI) public onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }
    
    function burn(uint256 tokenId) public onlyOwner {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function batch_mint(address[] memory tos, uint256[] memory tokenIds, string[] memory tokenURIs) public onlyOwner {
        
        require(tos.length >=1 && tos.length == tokenIds.length && tokenIds.length == tokenURIs.length, "check the array");

        for (uint256 i=0; i<tos.length; i++){
            mint(tos[i], tokenIds[i], tokenURIs[i]);
        }
    }
    
}