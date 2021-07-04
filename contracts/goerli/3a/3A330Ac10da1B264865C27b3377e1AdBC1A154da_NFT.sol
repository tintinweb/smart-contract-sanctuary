// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./erc.sol";

contract NFT is ERC721{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    event TokenDeleted(uint256 indexed _tokenId);
    event UpdatedURI(uint256 indexed _tokenId, string tokenURI_);

    
    constructor() public ERC721("TEST", "TTT") {
    }
    
    
    function mint(string memory tokenURI_)
        external
        onlyOwner()
        returns (uint256)
    {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(owner(), newItemId);
            _setTokenURI(newItemId,tokenURI_);
            return newItemId;
    }
    
}