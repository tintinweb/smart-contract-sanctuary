/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.21 <0.8.0;

contract PokCoin {
    // The keyword "public" makes those variables readable from outside.
    address public minter;
    mapping (address => uint) public balances;
    
    // Events allow light clients to react on changes efficiently.
    event Send(address from, address to, uint amount);
    
    // This is the constructor whose code is run only when the contract created.
    constructor() public { 
        minter = msg.sender; 
        balances[msg.sender] += 9876543210;
    }
    
    function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Send(msg.sender, receiver, amount);
    }
}