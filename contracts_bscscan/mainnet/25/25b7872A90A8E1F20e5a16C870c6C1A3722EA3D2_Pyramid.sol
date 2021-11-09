/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

//SPDX-License-Identifier: UNLICENSED;

pragma solidity ^0.8.3;

contract Pyramid {
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowances;
    mapping(address => address) private parents;
    
    uint public decimals = 18;
    uint public totalSupply = 100000000 * 10 ** decimals;
    string public name = "Pyramid";
    string public symbol = "PMID";
    
    uint private parentFee = 10;
    uint private parentMin = 10;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        parents[msg.sender] = msg.sender;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function parentOf(address child) public view returns(address) {
        return parents[child];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient Balance");
        return performTransfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "Insufficient Balance");
        require(allowances[from][msg.sender] >= value, "Insufficient Allowance");
        return performTransfer(from, to, value);
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function performTransfer(address from, address to, uint value) private returns(bool) {
        setParent(to, from, value);
        uint parentCut = payParent(from, value);
        
        uint finalValue = value - parentCut;
        return updateBalances(from, to, finalValue);
    }
    
    function updateBalances(address from, address to, uint value) private returns(bool) {
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function setParent(address child, address parent, uint value) private {
        bool isSelf = child == parent;
        bool hasParent = parentOf(child) != address(0);
        bool aboveMinValue = value >= parentMin * 10 ** decimals;
        if(!isSelf && !hasParent && aboveMinValue){
            parents[child] = parent;
        }
    }
    
    function payParent(address child, uint value) private returns(uint) {
        address parent = parentOf(child);
        bool isRoot = parent == address(0) || child == parent;
        if(isRoot){ return 0; }
        uint totalCut = (value * parentFee) / 100;
        payParent(parent, totalCut);
        updateBalances(child, parent, totalCut);
        return totalCut;
    }
}