// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract Test1155 is ERC1155Supply, Ownable  {
    bool public saleIsActive = false;
    uint constant TOKEN_ID = 123;
    uint constant NUM_RESERVED_TOKENS = 5;
    uint constant MAX_TOKENS_PER_PURCHASE = 5;
    uint constant MAX_TOKENS = 1000;
    uint constant TOKEN_PRICE = 0.01 ether;

    constructor(string memory uri) ERC1155(uri) {
    }

    function reserve() public onlyOwner {
       _mint(msg.sender, TOKEN_ID, NUM_RESERVED_TOKENS, "");
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_TOKENS_PER_PURCHASE, "Exceeded max token purchase");
        require(totalSupply(TOKEN_ID) + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        _mint(msg.sender, TOKEN_ID, numberOfTokens, "");
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}