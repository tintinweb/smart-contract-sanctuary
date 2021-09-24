/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract ERC20Interface {
    
    function totalSupply() virtual view public returns (uint64 _totalSupply);
    function balanceOf(address tokenOwner) virtual public view returns (uint64 balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint64 remaining);
    function transfer(address to, uint64 tokens) virtual public returns (bool success);
    function approve(address spender, uint64 tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint64 tokens) virtual public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint64 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint64 tokens);
    
}

contract uTodayToken is ERC20Interface {
    
    string public constant symbol = "XUT";
    string public constant name = "U Today Token";
    uint8 public constant decimals = 18;
    
    uint64 private constant __totalSupply = 1000000;
    mapping (address => uint64) private __balanceOf;
    mapping (address => mapping(address => uint64)) private __allowance;
    
    constructor() public {
        __balanceOf[msg.sender] = __totalSupply;
    }
    
    function totalSupply() override view public returns (uint64 _totalSupply) {
        _totalSupply = __totalSupply;
    }
    
    function balanceOf(address _addr) override view public returns (uint64 balance) {
        return __balanceOf [_addr];
    }
    
    function transfer(address _to, uint64 _value) override public returns (bool succes) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            return true;
        }
        return false;
    }
    
    
    function transferFrom(address from, address to, uint64 tokens) override public returns (bool success) {
        if (__allowance[from][msg.sender] > 0 && tokens > 0 && __allowance[from][msg.sender] >= tokens) {
            __balanceOf[from] -= tokens;
            __balanceOf[to] += tokens;
            return true;
        }
        return false;
    }
    
    function approve(address spender, uint64 tokens) override public returns (bool success) {
        __allowance[msg.sender][spender] = tokens;
        return true;
    }
    
    function allowance(address tokenOwner, address spender) override view public returns (uint64 remaining) {
        return __allowance[tokenOwner][spender];
    }
    
}