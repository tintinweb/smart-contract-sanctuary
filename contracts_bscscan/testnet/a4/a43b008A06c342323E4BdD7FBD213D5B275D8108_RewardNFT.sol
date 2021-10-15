// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";

contract RewardNFT is ERC1155 {
    uint256 public constant BRONZE = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant GOLD = 2;
    uint256 public constant PLATINUM = 3;
    uint256 public constant OBSIDIAN = 4;
    

    constructor(address _dev) ERC1155("https://ipfs.io/ipfs/QmXahvNNu7EbgUTSgHJivdtq3kjeUc6HsX8ePVhX1afJt6/{id}.json", _dev) {

        _mint(msg.sender, BRONZE, 10000, "");
        /* _mint(msg.sender, SILVER, 1000, "");
        _mint(msg.sender, GOLD, 100, "");
        _mint(msg.sender, PLATINUM, 50, "");
        _mint(msg.sender, OBSIDIAN, 20, ""); */
        
    }
}