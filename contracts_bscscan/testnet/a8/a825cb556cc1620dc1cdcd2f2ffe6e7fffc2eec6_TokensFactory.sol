// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Token.sol";

contract TokensFactory {
    
    ERC20Token[] public children;
    
    event CreatedToken(address tokenAddress, address tokenOwner, string name, string symbol, uint8 decimals, uint256 totalSupply);
    
    function createERC20Token(
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        uint256 totalSupply) public {
        
        ERC20Token token = new ERC20Token(name, symbol, decimals, totalSupply, msg.sender);
        children.push(token);
        
        emit CreatedToken(address(token), msg.sender, name, symbol, decimals, totalSupply);
    }
}