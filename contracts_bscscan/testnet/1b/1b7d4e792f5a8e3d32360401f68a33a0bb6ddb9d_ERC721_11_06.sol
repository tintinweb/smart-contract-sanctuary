// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract ERC721_11_06 is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("MyToken", "MTK") {}
    string private baseURI;
    function setbaseURI(string memory _URI)public{
        baseURI=_URI;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
        return super.tokenURI(tokenId);
    }
    mapping(address=>mapping(uint256=>uint256)) public Backpack;
    mapping(address=>mapping(uint256=>uint256)) public Backpack_t;
    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal override{
        uint256 x = balanceOf(from);
        uint256 y = Backpack_t[from][tokenId];
        uint256 z = Backpack[from][x];
        if(x!=y){
            Backpack[from][y] = z;
            Backpack_t[from][z] = y;
            delete Backpack[from][x];
        }else{
            delete Backpack[from][y];
        }
        delete Backpack_t[from][tokenId];
        z = balanceOf(to)+1;
        Backpack_t[to][tokenId]=z;
        Backpack[to][z] = tokenId;
    }
}