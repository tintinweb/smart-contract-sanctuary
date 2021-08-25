// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract ERCminter_NFT {
    mapping(address => mapping(string => ERC721)) public NFTmap;
    mapping(address => mapping(string => uint)) public NFTcounter;
    uint256 public tokenCounter;
    uint mintingPrice;
    address public contractCreator;

    
    constructor () {
        tokenCounter = 0;
        mintingPrice = 0.001 ether;
        contractCreator = msg.sender;
    }

    function createERC721(string memory name, string memory symbol) public {
        //require(msg.value == mintingPrice, "Pay for minting");
        NFTmap[msg.sender][name] = new ERC721(name, symbol);
        tokenCounter++;
    }

    function createNFT(string memory tokenURI, string memory tokenName) public {
         uint newItemId = NFTcounter[msg.sender][tokenName];
         NFTmap[msg.sender][tokenName]._safeMint(msg.sender, newItemId);
         NFTmap[msg.sender][tokenName]._setTokenURI(newItemId, tokenURI);   
         NFTcounter[msg.sender][tokenName]++;     
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