//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract NinjalertsNFT is ERC1155, Ownable {
    uint256 public tokensRemaining = 3333;
    uint256 public maxMintAmount = 20;
    uint256 public cost = 0.1 ether;
    bool public paused = false;
    
    constructor() ERC1155("https://rocketship-images.s3.amazonaws.com/images/{id}.json") {}
    
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function mint(uint256 amount) public payable {
        require(!paused);
        require(msg.value >= amount * cost);
        require(amount <= tokensRemaining);
        require(amount <= maxMintAmount);
        
        _mint(msg.sender, 0, amount, "");
        tokensRemaining -= amount;
    }
    
    function mintByOwner(uint256 amount) public onlyOwner {
        require(tokensRemaining >= amount);
        require(amount <= maxMintAmount);
        _mint(msg.sender, 0, amount, "");
        tokensRemaining -= amount;
    }
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function setConst(uint _newCost) public onlyOwner {
        cost = _newCost;
    }
}