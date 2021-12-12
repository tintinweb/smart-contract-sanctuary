/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0);
    c = a / b;
  }
}

contract bowContract {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 10000000 * 10 ** 18;
    string public name = "Crystals CODO";
    string public symbol = "CDO";
    uint256 public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint256) {
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
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}