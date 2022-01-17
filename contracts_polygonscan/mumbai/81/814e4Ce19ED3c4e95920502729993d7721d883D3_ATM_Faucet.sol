/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Token {
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract ATM_Faucet {
    address public owner;
    mapping(string=>address) pool;
    mapping(address=>uint256) water;
    
    uint256 constant amount = 10;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "onlyOwner");
        _;
    }
    
    constructor(){
        owner = msg.sender;
    }
    
    function setPool(string memory symbol, address addr, uint256 drop) external onlyOwner{
       pool[symbol] = addr;
       water[addr] = drop;
    }
    
    function getToken(string memory symbol) external{
        require(pool[symbol] != address(0), "not this Token!");
        Token(pool[symbol]).transfer(msg.sender, water[pool[symbol]] );
    }
}