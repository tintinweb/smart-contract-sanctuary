// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract CRONFT is ERC721{
    mapping (address => uint) public OwnerID;
    uint256 public tokenCounter;
    uint mintingPrice;
    address public contractCreator;
    
    constructor () ERC721 ("CRONFT", "NFT"){
        tokenCounter = 0;
        mintingPrice = 0.001 ether;
        contractCreator = msg.sender;
    }

    function createNFT(string memory tokenURI) public returns (uint256) {
        OwnerID[msg.sender] = tokenCounter;
        _safeMint(msg.sender, tokenCounter, "");
        _setTokenURI(tokenCounter, tokenURI);
        tokenCounter++;
        return tokenCounter;
    }

    function setMintingPrice(uint price) public{
        require(msg.sender == contractCreator, "only creator can set price");
        mintingPrice = price;
    }

    function withDrawEth(uint amount) public {
        require(msg.sender==contractCreator);
        payable(contractCreator).transfer(amount);
    }
}