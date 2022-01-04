/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// File: contracts/ShibaWealth.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract ShibaWealth {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => bool) private excludedFromFees;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Shiba Wealth";
    string public symbol = "SHIBAWEALTH";
    uint public decimals = 18;

    uint256 MKTG_FEE = 3;

    address payable public mktgAddress = payable(0x8c3926Dc1082D599aa8B62cDacF6547864505693);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        excludedFromFees[msg.sender] = true;
        excludedFromFees[mktgAddress] = true;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        if (excludedFromFees[msg.sender] == true || excludedFromFees[to] == true) {
            balances[to] += value;
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value);
        } else {
            uint256 mktgAmount = (value * MKTG_FEE) / 100;

            balances[mktgAddress] += mktgAmount;
            balances[to] += (value - mktgAmount);
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value - mktgAmount);
        }
        
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        if (excludedFromFees[msg.sender] == true) {
            balances[to] += value;
            balances[from] -= value;
            emit Transfer(from, to, value);
        } else {
            uint256 mktgAmount = (value * MKTG_FEE) / 100;

            balances[mktgAddress] += mktgAmount;
            balances[to] += (value - mktgAmount);
            balances[from] -= value;
            emit Transfer(from, to, value - mktgAmount);
        }
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}