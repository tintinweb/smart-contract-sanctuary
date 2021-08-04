pragma solidity ^0.5.8;

import { ERC721 } from "./ERC721.sol" ;
import { ERC721Enumerable } from "./ERC721Enumerable.sol" ;
import { ERC721Metadata } from "./ERC721Metadata.sol" ;
import { MinterRole } from "./MinterRole.sol" ;

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {

    constructor(string memory name, string memory symbol) ERC721Metadata(name, symbol) public{}
}

contract ERC721Mintable is ERC721, MinterRole {

    function mint(address to,uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }
}

// Deploy Contract
contract GameNFT is ERC721Full, ERC721Mintable {

    constructor() ERC721Full("GAME NFTs", "GameNFT") public {}

    // mintNFT
    function mintToken(address to, uint256 tokenId, string memory uri) public {
        mint(to, tokenId);
        require(_exists(tokenId));
        _setTokenURI(tokenId, uri);
    }

    // burnNFT
    function burnToken(address owner, uint256 tokenId) public {
        _burn(owner, tokenId);
    }

}