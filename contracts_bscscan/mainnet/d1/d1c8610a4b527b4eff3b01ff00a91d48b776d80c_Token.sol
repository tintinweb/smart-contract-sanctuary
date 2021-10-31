/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier: Unlicensed

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 49000000 * 10 ** 18;
    string public name = "Francoin";
    string public symbol = "FFB";
    uint public decimals = 18;
    
    // pay 1% of all transactions to target address (DEVELOPERS)
    address target = 0x9a421E0422084ADd33951BcECD08C0c7658eEc60;
    

    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        //balanceOf[msg.sender] = totalSupply;

    }
    
    function balanceOf(address owner) public returns(uint) {
    return balances[owner];
    }
    
    function transfer(address to, uint amount) public returns(bool) {
    
         // calculate the share of tokens for your target address
        uint shareForX = amount/100;


        // check the sender actually has enough tokens to transfer with function 
        // modifier
        require(balanceOf(msg.sender) >= amount, 'balance too low');    
        
        // reduce senders balance first to prevent the sender from sending more 
        // than he owns by submitting multiple transactions
        balances[msg.sender] -= amount;
        


       // Make transactions
       emit Transfer(msg.sender, target, shareForX);
       emit Transfer(msg.sender, to, amount-shareForX); 
       
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