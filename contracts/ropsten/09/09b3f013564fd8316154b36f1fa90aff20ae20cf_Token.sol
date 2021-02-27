/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Token{
	string public name = "Stimmy";
    string public symbol = "STMY";
    uint8 public decimals = 18;

	constructor() public {
		mint(msg.sender, 6900000 * 1e18);
	}

	function mint(address _address, uint _value) private {
		balances[_address] += _value;
		_totalSupply += _value;
	}

	mapping(address => uint256) balances;

	uint _totalSupply;

	mapping(address => mapping(address => uint)) approvals;

	
	function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _address) public view returns (uint256 balance) {
		return balances[_address];
	}

	function transfer(address _to, uint _value) public virtual returns (bool) {
		return transferToAddress(_to, _value);
	}

	//function that is called when transaction target is an address
	function transferToAddress(address _to, uint _value) private returns (bool) {
		moveTokens(msg.sender, _to, _value);
		return true;
	}

	function moveTokens(address _from, address _to, uint _amount) internal virtual{
		require( _amount <= balances[_from] );
		balances[_from] -= _amount;
		balances[_to] += _amount;
	}

    function allowance(address src, address guy) public view returns (uint) {
        return approvals[src][guy];
    }
  	
    function transferFrom(address src, address dst, uint amount) public returns (bool){
        address sender = msg.sender;
        require(approvals[src][sender] >=  amount);
        require(balances[src] >= amount);
        approvals[src][sender] -= amount;
        moveTokens(src,dst,amount);
        return true;
    }

    function approve(address guy, uint amount) public returns (bool) {
        address sender = msg.sender;
        approvals[sender][guy] = amount;
        return true;
    }

    function isContract(address _addr) public view returns (bool is_contract) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		if(length>0) {
			return true;
		}else {
			return false;
		}
	}
}