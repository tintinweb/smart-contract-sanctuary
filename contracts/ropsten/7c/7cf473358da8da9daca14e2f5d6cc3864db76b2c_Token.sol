/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract Token {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    string public name = "DemoCoin";
    string public symbol = "DC";
    
    uint public decimals = 8;
    
    // totalSupply = 10 000 000 tokens
    uint public totalSupply = 10000000 * (uint256(10) ** decimals);
    
    // currently circulating supply (tokens added to circulation when bought)
    uint public circulatingSupply;
    
    address public owner;
    
    event Transfer(address from, address to, uint256 value);
    
    constructor() {
        // assign address owner to contract creator
        owner = msg.sender;
    }

    // function modifier (extension)
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // inherit requirement and return collectedEth if successful
    function collectedEth() public view onlyOwner returns (uint) {
        return address(this).balance;
    }
    
    // endICO, send gathered ETH to contract creator
    function endICO(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }
    
    function buyTokens() public payable {
        // amount in wei
        require(msg.value > 0, "No funds send.");
        // tokens for 1 ETH = 10 000 
        uint tokens = msg.value/10e13;
        
        // add tokens to circulatingSupply
        circulatingSupply += tokens;
        
        // add tokens to sender's balance
        balanceOf[msg.sender] += tokens;
        
        // emit Transfer on blockchain
        emit Transfer(address(this), msg.sender, tokens);
    }
}