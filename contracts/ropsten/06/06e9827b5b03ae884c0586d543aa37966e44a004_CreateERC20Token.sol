// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";

contract CreateERC20Token
{
    mapping(address => ERC20) public tokenMap;
    address public contractCreator; 
    uint256 tokenCounter;
    uint mintingPrice;

    constructor() {
        contractCreator = msg.sender;
        mintingPrice = 0.01 ether;
    }

    function mintTokens (string memory name, string memory symbol, uint256 totalSupply, uint8 decimals) payable public {
        require(msg.value == mintingPrice, "Pay for minting");
        tokenMap[msg.sender] = new ERC20(name, symbol, 0, decimals);
        tokenMap[msg.sender].mint(msg.sender ,totalSupply);
    }

    function setMintingPrice(uint price) public{
        require(msg.sender == contractCreator, "only creator can set price");
        mintingPrice = price;
    }

    function withDrawEth(uint amount) public {
        require(msg.sender==contractCreator);
        payable(contractCreator).transfer(amount);
    }

    function getTokenContract(address owner) public view returns(ERC20) 
    {
        return tokenMap[owner];
    }
}