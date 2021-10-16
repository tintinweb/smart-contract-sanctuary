/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Token {
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;
     uint public totalsupply = 9000000000 * 10 ** 9;
     string public name = "Quantom Token";
     string public symbol = "QTC";
     uint public decimals = 9;
     
     event transfer(address indexed from, address indexed to, uint value);
     event approval(address indexed owner, address indexed spender, uint value);
     
     constructor() {
         balances[msg.sender] = totalsupply;
     }
     
    function balanceof(address owner) public view returns(uint) {
        return balances[owner];
        }
        
        function transfers(address to, uint value) public returns(bool) {
            require(balanceof(msg.sender) >= value, 'balance too low');
            balances[to] += value;
            balances[msg.sender] -= value;
            emit transfer(msg.sender, to, value);
            return true;
        }
        
        function transferFrom(address from, address to, uint value) public returns(bool) {
            require(balanceof(from) >= value, 'balance too low');
            require(allowance[from][msg.sender] >= value, 'allowance too low');
            balances[to] += value;
            balances[from] -= value;
            emit transfer(from, to, value);
            return true;
        }
        
        function approve(address spender, uint value) public returns(bool) {
            allowance[msg.sender][spender] = value;
            emit approval(msg.sender, spender, value);
            return true;
        }
}