// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract FOTONFT is ERC721{
    uint256 public tokenCounter;
    address public minter;
    constructor () ERC721 ("FOTO_NFT2", "FOTO2"){
        tokenCounter = 0;
        minter = msg.sender;
    }

    function createNFT(string memory tokenURI) public returns (uint256) {
        //require(msg.sender==minter, "Only initial contract creator can mint new NFTs")
        uint256 newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }
}