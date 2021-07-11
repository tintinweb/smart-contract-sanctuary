// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";


contract eGINFT is Ownable, ERC721("eGame","eGI"){
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() {
    }

    function awardNFT(address player, string memory tokenURI) onlyOwner public returns (uint256){
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}