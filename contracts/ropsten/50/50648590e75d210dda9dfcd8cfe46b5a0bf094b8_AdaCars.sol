// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721.sol";
import "Ownable.sol";
import "Counters.sol";

/// @custom:security-contact [email protected]
contract AdaCars is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("adaCars", "ADS") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.beaglebiker.com/adaCars/";
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}