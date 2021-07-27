// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("NFT", "WOO") {}

    function safeMint(address to) public {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
}