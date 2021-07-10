/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

pragma solidity ^0.8.2;

//SPDX-License-Identifier: UNLICENSED

contract HypeTest {
    mapping(address => uint) public balances;
    mapping(address => mapping (address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "HypeTest";
    string public symbol = "HT";
    uint public decimals = 18;
    uint256 public _burnFee = 2; // percentage of liquidityFee that is burned
    
    address public constant BURN_ADDRESS = 0x14fdcb4c9028fF2149E69820674E5640E78b3C21;
   
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
   
    constructor() {
        balances[msg.sender] = totalSupply;
    }
   
    function balanceOf(address owner) public view returns(uint) {
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
   
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
   
}