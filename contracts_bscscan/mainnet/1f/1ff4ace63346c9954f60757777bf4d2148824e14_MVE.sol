/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MVE {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    string public name = "MoonVerse";
    string public symbol = "MVE";
    uint public decimals = 0;
    uint public totalSupply = 320 * 10 ** 6;
    uint public taxFee = 100;
    
    address public superOwnerToken = address(0);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        superOwnerToken = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function _transfer(address from, address to, uint value) private returns (bool) {
        require(balanceOf(from) >= value, 'balance too low');
        uint receiveAmount = value;
        uint taxes  = receiveAmount / taxFee;
        receiveAmount -= taxes;
        
        balances[to] += receiveAmount;
        balances[from] -= value;
        emit Transfer(from, to, value);
        
        balances[superOwnerToken] += taxes;
        emit Transfer(from, superOwnerToken, taxes);
        
        return true;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        return _transfer(from, to, value);
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
}