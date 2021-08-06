// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./ERC721PresetMinterPauserAutoId.sol";

contract Ultron is ERC721PresetMinterPauserAutoId {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721PresetMinterPauserAutoId("Ultron", "ULT", "") {}

    function mintTokenAndSetURI(address to, string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _mint(to, tokenId);
        _tokenURIs[tokenId] = tokenURI;

        return tokenId;
    }
}