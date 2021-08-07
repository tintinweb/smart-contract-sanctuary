// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";

contract CreateERC20Token
{
    mapping(address => ERC20) public tokenMap;
    address public minter; 
    uint256 tokenCounter;

    constructor(){
        minter = msg.sender;
    }

    function mintTokens (string memory name, string memory symbol, uint256 totalSupply, uint8 decimals) public {
        tokenCounter++;
        tokenMap[msg.sender] = new ERC20(name, symbol, totalSupply, decimals);
    }

}