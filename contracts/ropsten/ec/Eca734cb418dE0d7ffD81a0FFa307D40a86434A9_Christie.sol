// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./erc721.sol";

contract Christie is ERC721, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() public ERC721("Christie", "CT") {}

    function mintArt(string memory tokenURI, address artist)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(artist, newItemId);
        _setTokenURI(newItemId, tokenURI);
        
        return newItemId;
    }
    
    function updateURI(string memory __tokenURI, uint256 __tokenId) public {
        require(_msgSender() == ownerOf(__tokenId) || isApprovedForAll(ownerOf(__tokenId), _msgSender()), "Not an authority of token");
        require(_exists(__tokenId), "ERC721: operator query for nonexistent token");
        _setTokenURI(__tokenId,__tokenURI);
    }
    
    function deleteToken(uint256 __tokenId) public {
        require(_msgSender() == ownerOf(__tokenId) || isApprovedForAll(ownerOf(__tokenId), _msgSender()), "Not an authority of the token");
        require(_exists(__tokenId), "ERC721: operator query for nonexistent token");
        _burn(__tokenId);
    }
    
}