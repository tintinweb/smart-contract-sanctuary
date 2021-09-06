/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.2;

contract Test01 {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000 * 10 ** 18;
    string public name = "Test01";
    string public symbol = "Test1";
    uint public decimals = 18;
    address public _owner;
    
    uint256 public _maxWalletToken = 35000000000000 * 10 ** 18; // can't buy or accumulate more than this
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        _owner = msg.sender;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        if (to == 0x000000000000000000000000000000000000dEaD) {      //Burn address excluded from max token amount
            balances[to] += value;
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value);
            return true;
        } else if (to == 0x6f80CddaC2f43950f5c4b10632f4d19c77794A70) {   //Dev wallet excluded from max token amount
            balances[to] += value;
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            require(balanceOf(to) + value <= _maxWalletToken, "Exceeds maximum wallet token amount."); //Every other wallet has limited max token amount
            balances[to] += value;
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value);
            return true;
        }
        
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function setMaxWallet(uint256 newMaxAmount) public {
        require(msg.sender == _owner, 'only contract owner is allowed to change max token per wallet');
        _maxWalletToken = newMaxAmount;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}