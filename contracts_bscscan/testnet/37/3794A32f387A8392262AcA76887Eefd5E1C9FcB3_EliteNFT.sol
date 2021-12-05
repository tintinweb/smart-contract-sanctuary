// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";

import "./IEliteNFT.sol";

import "./ERC721URIStorage.sol";
import "./Whitelist.sol";


contract EliteNFT is IEliteNFT, ERC721URIStorage, Whitelist {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter public override totalMinted;
    
    string public uri;
	
    constructor(uint _mintLimit, uint _mintPrice, address _paymentToken, string memory _uri) ERC721(
        "FunctionCard", "CARD", _mintLimit, _mintPrice, _paymentToken
    ) {
        uri = _uri;
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    // Mint an item
    function mint(address player) public returns (uint256) {
        _tokenIds.increment();
        totalMinted.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, uri);

        return newItemId;
    }
}