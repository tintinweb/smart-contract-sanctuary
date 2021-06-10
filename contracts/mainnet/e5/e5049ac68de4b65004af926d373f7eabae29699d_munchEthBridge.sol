// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "./multiOwnable.sol";
import "./munchTokenETH.sol";

contract munchEthBridge is Multiownable {
    MUNCH private token;

    mapping(address => uint256) public tokensSent;
    mapping(address => uint256) public tokensRecieved;
    mapping(address => uint256) public tokensRecievedButNotSent;
 
    constructor (address payable _token) public {
        token = MUNCH(_token);
    }
 
    uint256 amountToSent;
    bool transferStatus;
    
    bool avoidReentrancy = false;
 
    function sendTokens(uint256 amount) public {
        require(msg.sender != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more than 0");
        require(token.balanceOf(msg.sender) >= amount,"Not enough balance");
        
        transferStatus = token.transferFrom(msg.sender, address(this), amount);
        if (transferStatus == true) {
            tokensRecieved[msg.sender] += amount;
        }
    }
 
    function writeTransaction(address user, uint256 amount) public onlyManyOwners {
        require(user != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more than 0");
        require(!avoidReentrancy);
        
        avoidReentrancy = true;
        tokensRecievedButNotSent[user] += amount;
        avoidReentrancy = false;
    }

    function recieveTokens(uint256[] memory commissions) public payable {
        if (tokensRecievedButNotSent[msg.sender] != 0) {
            require(commissions.length == owners.length, "The number of commissions and owners does not match");
            uint256 sum;
            for(uint i = 0; i < commissions.length; i++) {
                sum += commissions[i];
            }
            require(msg.value >= sum, "Not enough ETH (The amount of ETH is less than the amount of commissions.)");
            require(msg.value >= owners.length * 150000 * 10**9, "Not enough ETH (The amount of ETH is less than the internal commission.)");
        
            for (uint i = 0; i < owners.length; i++) {
                address payable owner = payable(owners[i]);
                uint256 commission = commissions[i];
                owner.transfer(commission);
            }
            
            amountToSent = tokensRecievedButNotSent[msg.sender] - tokensSent[msg.sender];
            token.transfer(msg.sender, amountToSent);
            tokensSent[msg.sender] += amountToSent;
        }
    }
 
    function withdrawTokens(uint256 amount, address reciever) public onlyManyOwners {
        require(amount > 0,"Amount of tokens should be more than 0");
        require(reciever != address(0), "Zero account");
        require(token.balanceOf(address(this)) >= amount,"Not enough balance");
        
        token.transfer(reciever, amount);
    }
    
    function withdrawEther(uint256 amount, address payable reciever) public onlyManyOwners {
        require(amount > 0,"Amount of tokens should be more than 0");
        require(reciever != address(0), "Zero account");
        require(address(this).balance >= amount,"Not enough balance");

        reciever.transfer(amount);
    }
}