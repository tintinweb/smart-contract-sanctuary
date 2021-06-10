/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/**

The word quasar stands for quasi-stellar radio source. 
Quasars got that name because they looked starlike when astronomers first began to notice them in the late 1950s and early 60s. 
But quasars aren’t stars. They’re now known as young galaxies, located at vast distances from us, with their numbers increasing towards the edge of the visible universe.
How can they be so far away and yet still visible? The answer is that quasars are extremely bright, up to 1,000 times brighter than our Milky Way galaxy. 
We know, therefore, that they’re highly active, emitting staggering amounts of radiation across the entire electromagnetic spectrum.

*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.2;

contract Quasar {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    
    uint256 public totalSupply = 10 * 10**11 * 10**18;
    string public name = "Quasar";
    string public symbol = "QUASAR";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        return true;
        
    }
}