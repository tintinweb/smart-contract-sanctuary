/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


/** Please this project is design to support the Vitalika View on Public Goods
 * Its also an experiment token to see weather or not minority can  participate in the richness of blockchain
 * this coin if successful will support poverty reduction, Create wealth building Mining farms and do manual redistributed and buy back coin
 * The twitter account available at this time is our Ambasador Soma Love 
 * Do follow him on twitter and as a community private groups will be created for this baby.
 * 
*/

/** https://twitter.com/SomaToken?t=qCrjIE6FoZSePC0rewYjhg&s=09 
 * 
 * 
 * https://www.linkedin.com/in/somadina-nnaji-chukwu-a4254585/ 

*/



contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 301671681711814421 * 10 ** 18;
    string public name = "Hope";
    string public symbol = "HPT";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}