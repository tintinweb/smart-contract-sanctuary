/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Owner {

    address private owner;
    address private bot;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event BotSet(address indexed oldBot, address indexed newBot);
    event BotTip(address from, address miner, uint256 tip);
    
    modifier isOwner() { 
        require(msg.sender == owner, "Caller is not owner");
        _;
    } 

    modifier isBot() { 
        require(msg.sender == bot, "Caller is not bot");
        _;
    } 
    
    constructor(address _bot) {
        owner = msg.sender;  
        bot = _bot;
        emit OwnerSet(address(0), owner);
    } 

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
 
    function getOwner() external view returns (address) {
        return owner;
    } 

    function changeBot(address newBot) public isOwner {
        emit BotSet(bot, newBot);
        bot = newBot;
    }
 
    function getBot() external view returns (address) {
        return bot;
    } 

    function tip() public payable isBot {
        block.coinbase.transfer(msg.value);
        emit BotTip(bot, block.coinbase, msg.value);
    }
}