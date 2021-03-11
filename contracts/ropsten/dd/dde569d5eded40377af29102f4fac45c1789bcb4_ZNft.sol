// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract ZNft is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() public ERC721("ZNFTToken", "ZNFT") {}

    function mintNft(address receiver, string memory tokenURI) external onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);

        return newNftTokenId;
    }
}