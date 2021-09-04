// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ITheDogeWorldNFT.sol";

contract TheDogeWorldNFT is ERC721, ITheDogeWorldNFT, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(string => uint8) hashes;
    mapping(uint256 => Artwork) private artworks;
    mapping(address => uint8) private creators;

    string public baseURI;

    constructor() ERC721("TheDogeWorldNFT", "TDWNFT") {
        baseURI = "https://ipfs.io/ipfs/";
    }

    function mintNFT( address recipient, string memory artwork, string memory metadata, uint256 royalty ) public override returns (uint256) {
        require(hashes[metadata] != 1);
        require(hashes[artwork] != 1);
        require(creators[msg.sender] == 1, "TheDogeWorldNFT: be a creator");
        require(royalty <= 50, "TheDogeWorldNFT: Royalty cannot be more than 50%");

        hashes[metadata] = 1;
        hashes[artwork] = 1;

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        artworks[newItemId] = Artwork(
            block.timestamp,
            msg.sender,
            artwork,
            metadata,
            royalty
        );
        _mint(recipient, newItemId);
        emit Mint(recipient, newItemId, artwork);
        return newItemId;
    }

    function mintAndApproveNFT( address recipient, string memory artwork, string memory metadata, uint256 royalty,address marketContract) public override returns (uint256) {
        require(hashes[metadata] != 1);
        require(hashes[artwork] != 1);
        require(creators[msg.sender] == 1, "TheDogeWorldNFT: be a creator");
        require(royalty <= 50, "TheDogeWorldNFT: Royalty cannot be more than 50%" );
        
        hashes[metadata] = 1;
        hashes[artwork] = 1;

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        artworks[newItemId] = Artwork(
            block.timestamp,
            msg.sender,
            artwork,
            metadata,
            royalty
        );
        _mint(recipient, newItemId);

        emit Mint(recipient, newItemId, artwork);
        _approve(marketContract, newItemId);

        return newItemId;
    }

    function burnNFT(uint256 tokenId) public override returns (bool) {
        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721Burnable: caller is not owner nor approved");
        Artwork memory artwork = artworks[tokenId];
        delete artworks[tokenId];
        delete hashes[artwork.metadata];
        delete hashes[artwork.artwork];
        _burn(tokenId);
        return true;
    }

    function getArtwork(uint256 tokenId) public view override returns (Artwork memory){
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return artworks[tokenId];
    }

    function isCreator(address creator) public view override returns (bool) {
        return creators[creator] == 1;
    }

    function addCreator(address creator) public override onlyOwner returns (bool) {
        require(creators[creator] != 1, "TheDogeWorldNFT: creator already exist");
        creators[creator] = 1;
        return true;
    }

    function removeCreator(address creator) public  override onlyOwner returns (bool) {
        require(creators[creator] == 1, "TheDogeWorldNFT: creator doesn't exist");
        creators[creator] = 0;
        return true;
    }

    function tokenURI(uint256 tokenId) public  view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token" );
        return string(abi.encodePacked(baseURI, artworks[tokenId].metadata));
    }

    function setBaseURI(string memory uri)  public onlyOwner returns (string memory) {
        baseURI = uri;
        return baseURI;
    }

}