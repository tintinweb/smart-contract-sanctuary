pragma solidity ^0.4.11;

//------------------------------------------------------------------------------------------------
// ERC20 Standard Token Implementation, based on ERC Standard:
// https://github.com/ethereum/EIPs/issues/20
// With some inspiration from ConsenSys HumanStandardToken as well
// Copyright 2017 BattleDrome
//------------------------------------------------------------------------------------------------

contract ERC20Standard {
	uint public totalSupply;
	
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;
	
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;

	//Fix for short address attack against ERC20
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

	function balanceOf(address _owner) constant returns (uint balance) {
		return balances[_owner];
	}

	function transfer(address _recipient, uint _value) onlyPayloadSize(2*32) {
		require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] -= _value;
	    balances[_recipient] += _value;
	    Transfer(msg.sender, _recipient, _value);        
    }

	function transferFrom(address _from, address _to, uint _value) {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

	function approve(address _spender, uint _value) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) constant returns (uint balance) {
		return allowed[_owner][_spender];
	}

	//Event which is triggered to log all transfers to this contract&#39;s event log
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
	//Event which is triggered whenever an owner approves a new allowance for a spender.
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);

}

//------------------------------------------------------------------------------------------------
// FAME ERC20 Token, based on ERC20Standard interface
// Copyright 2017 BattleDrome
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
// LICENSE
//
// This file is part of BattleDrome.
// 
// BattleDrome is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// BattleDrome is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with BattleDrome.  If not, see <http://www.gnu.org/licenses/>.
//------------------------------------------------------------------------------------------------

contract FAMEToken is ERC20Standard {

	function FAMEToken() {
		totalSupply = 2100000 szabo;			//Total Supply (including all decimal places!)
		name = "Fame";							//Pretty Name
		decimals = 12;							//Decimal places (with 12 decimal places 1 szabo = 1 token in uint256)
		symbol = "FAM";							//Ticker Symbol (3 characters, upper case)
		version = "FAME1.0";					//Version Code
		balances[msg.sender] = totalSupply;		//Assign all balance to creator initially for distribution from there.
	}

	//Burn _value of tokens from your balance.
	//Will destroy the tokens, removing them from your balance, and reduce totalSupply accordingly.
	function burn(uint _value) {
		require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
	}

	//Event to log any time someone burns tokens to the contract&#39;s event log:
	event Burn(
		address indexed _owner,
		uint _value
		);

}