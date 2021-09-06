// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract GameItem is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("GameItem", "ITM") {}

    function awardItem(address player, string memory tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}