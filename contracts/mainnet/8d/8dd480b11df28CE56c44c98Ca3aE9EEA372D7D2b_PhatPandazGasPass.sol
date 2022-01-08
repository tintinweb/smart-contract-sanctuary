// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC1155.sol";
import "Ownable.sol";

contract PhatPandazGasPass is ERC1155, Ownable {

    uint public passesMinted = 50; // 50 minted for giveaways
    uint public constant gasPassLimit = 500;
    bool public isActive = false;

    constructor() ERC1155("ipfs://QmT5fno7nuyKTTVR6XPMT6JeUFQFycZj14Jtk3NxD35V6s") {
        _mint(msg.sender, 1, 50, "");
    }

    event MintedGasPass(address _to, uint passesMinted);

    modifier checkMint(address _to) {
        require(isActive, "Sale not active.");
        require(block.timestamp >= 1641682800, "Sale not started.");
        require(passesMinted < gasPassLimit, "Sold out.");
        require(msg.value == .05 ether, "Incorrect ether sent.");
        require(balanceOf(_to, 1) < 1, "One per wallet.");
        _;
    }

    function toggleActive() external onlyOwner {
        isActive = !isActive;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function mint() public payable checkMint(msg.sender) {
        address _to = msg.sender;
        passesMinted++;
        _mint(_to, 1, 1, "");
        emit MintedGasPass(_to, passesMinted);
    }
}