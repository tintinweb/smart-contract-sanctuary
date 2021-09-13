// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";


contract TheTigersGuildComics is ERC721, Ownable {
    using Strings for uint256;

    string _baseMetadataUri;
    uint256 _maxSupply = 88;

    constructor(string memory baseMetadataUri) ERC721("TheTigersGuildComics", "TTGCM") {
        setBaseMetadataUri(baseMetadataUri);
    }

    function setBaseMetadataUri(string memory baseMetadataUri) public onlyOwner {
        _baseMetadataUri = baseMetadataUri;
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(_baseMetadataUri, tokenId.toString()));
    }
    
    function releaseComics(address to) public onlyOwner {
        uint256 totalSupply = totalSupply();
        uint256 comicsId = totalSupply + 1;
        require(comicsId <= _maxSupply, "Purchase would exceed max supply of comics");
        _safeMint(to, comicsId);
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}