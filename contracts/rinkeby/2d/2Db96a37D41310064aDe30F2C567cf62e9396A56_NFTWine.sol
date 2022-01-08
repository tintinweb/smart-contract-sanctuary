// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract NFTWine is ERC721Enumerable, Ownable {
    string public baseURI;
    mapping(uint256 => string) private _hashIPFS;

 constructor(string memory _name, string memory _symbol)
    ERC721(_name, _symbol)
 {
     baseURI = "https://ipfs.io/ipfs/";
 }
function mint(address _to, string[] memory _hashes) public onlyOwner {
    uint256 supply = totalSupply();

    for (uint256 i = 0; i < _hashes.length; i++) {
        _safeMint(_to, supply + i);
        _hashIPFS[supply + i] = _hashes[i];
    }

}
function walletOfOwner(address _owner)
   public
   view
   returns (uint256[] memory)  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
}


function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
{
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexists token");

    string memory currentBaseURI = _baseURI();
    return
      (bytes(currentBaseURI).length > 0 && bytes(_hashIPFS[tokenId]).length > 0)
      ? string(abi.encodePacked(currentBaseURI, _hashIPFS[tokenId]))
      : "";
      
}

function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
}
function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
}
}