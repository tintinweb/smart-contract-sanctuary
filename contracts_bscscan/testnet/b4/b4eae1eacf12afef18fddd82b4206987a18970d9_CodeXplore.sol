/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

pragma solidity ^0.8.10;

//SPDX-License-Identifier: UNLICENSED

contract CodeXplore {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(uint => Item) public items;

    struct Item {
        address addr;
        uint item_id;
    }

    uint public totalSupply = 21000000 * 10 ** 18;
    string public name = "CodeXplore";
    string public symbol = "CDX";
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

    function storeItem(address spender, uint item_id) public {
        items[item_id] = Item(spender, item_id);
    }

    function getItem(uint item_id) public returns (address) {
        return items[item_id].addr;
    }
}