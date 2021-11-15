/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


contract Catcoin1 {
	address public owner = msg.sender;
  // event to be emitted on transfer
	
	uint256 constant initialsupply = 50000;
    uint256 constant cappedsupply = 1000000;
	mapping (address => uint) public balances;
    uint256 currentsupply = initialsupply;
    mapping (address => mapping(address => uint)) public allowances;
    address public minter;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // event created_coin(address indexed _from, uint256 _value);
    event MintershipTransfer(address indexed _from, address indexed _to);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	constructor(){
		balances[msg.sender] = initialsupply;
		minter = msg.sender;
	}
	
	function mint(address recipient, uint256 amount) public {
	    require(msg.sender == minter);
	    require(initialsupply + amount >= initialsupply);
	    require(currentsupply + amount <= cappedsupply);
	    
	    currentsupply += amount;
	    balances[recipient] += amount;
	    emit Transfer(msg.sender, recipient, amount);
	}
	
	function burn(uint256 amount) public {
	    require(amount <= balances[msg.sender]);
	    require(msg.sender == minter);
	    require(currentsupply-amount >=0);
	    currentsupply -= amount;
	    balances[msg.sender] -= amount;
	    emit Transfer(msg.sender, address(0), amount);
	}
	
	
	function Transferminter(address newminter) public returns (bool){
    require(msg.sender == minter, "Error");
    minter = newminter;
    emit MintershipTransfer(msg.sender, newminter);
    return true;
	}
	
	function transfer(address _to, uint256 _value) public returns (bool) {
    // TODO: transfer `_value` tokens from sender to `_to`
   // NOTE: sender needs to have enough tokens
	require(balances[msg.sender]-1 >= _value);
	require(currentsupply+1 <= cappedsupply);
	balances[msg.sender] -= (_value+1);
 	balances[_to] += _value;
 	balances[minter] += 1;
 	currentsupply +=1;
    emit Transfer(msg.sender, _to, _value);
    return true;
    }

    
      function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    // TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        require(msg.sender == minter, "Error");
        require(balances[_from]-1 >= _value, "balances too low");
        require(currentsupply+1 <= cappedsupply);
        balances[_from] -= (_value+1);
        balances[_to] += _value;
        balances[msg.sender] += 1;
        emit Transfer(_from, _to, _value);
        return true; 
      }
      
      
      function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
      }

    function checkcurrentamount() public view returns (uint256){
        return currentsupply;
    }
    
      function balanceOf(address _owner) public view returns (uint256) {
    // TODO: return the balance of _owner
    return balances[_owner];
  }
  
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
    remaining = allowances[_owner][_spender];
    return remaining;
  }
}