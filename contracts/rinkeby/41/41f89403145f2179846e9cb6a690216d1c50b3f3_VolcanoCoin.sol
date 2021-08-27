/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Volcano Coin Contract 

contract VolcanoCoin {
    
    uint totalSupply = 10000 * 10 * 18;
    address owner;
    mapping(address => uint) public balances;
    struct Payment {
        address recipient;
        uint amount;
    }
    mapping(address => Payment[]) payments;
    
    
    modifier onlyOwner() {
        require((msg.sender == owner), 'Only owner can do this');
        _;
    }
    
    event newTotalSupply(uint totalSupply);
    event Transfer(address indexed sender, address indexed recipient, uint amount);
    
    constructor(){
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function totalSupplyCoins() public onlyOwner view returns (uint) {
        return totalSupply;
    }
    
    function increaseSupply() private returns (uint){
        totalSupply += 1000 * 10e18;
        emit newTotalSupply(totalSupply);
        return totalSupply;
    }
    
    function transfer(address receiver, uint amount) public {
        require((balances[msg.sender] >= amount), "Insuficient account balance");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
    }
}