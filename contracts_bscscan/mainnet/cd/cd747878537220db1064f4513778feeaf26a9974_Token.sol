/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.8.2;

// THIS COIN IS NOTHING WORTH.
// THIS COIN IS CREATED IN HONOUR OF SCRUNCH.
// "Thou shalt sell on 13 as thou shalt buy on 9" - Scrunch 13:9
// Scrunch is/was part of the DOBO community. This coin is created to honour him. Check out the DOBO community.
// DOGEBONK.COM FOR REAL MEME COIN.
// DOGEBONK.COM FOR REAL MEME COIN.
// DOGEBONK.COM FOR REAL MEME COIN.
// DOGEBONK.COM FOR REAL MEME COIN.

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 91313991313991399 * 10 ** 18;
    string public name = "Scrunch Token";
    string public symbol = "SCRUNCH";
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