pragma solidity ^0.4.23;

contract owned {

	address private owner;
	address private newOwner;

	constructor() public {
		owner = msg.sender;
	}
    
	modifier onlyOwner {
		require(owner == msg.sender);
		_;
	}

	function changeOwner(address _owner) onlyOwner public {
		require(_owner != 0);
		newOwner = _owner;
	}
    
	function confirmOwner() public {
		require(newOwner == msg.sender);
		owner = newOwner;
		delete newOwner;
	}
	
}

contract WeddingContract is owned {
	
	string public partner_1_name;
	string public partner_2_name;
	string public contract_date;
	string public declaration;
	bool public is_active;
	
	constructor(string _partner_1_name, string _partner_2_name, string _contract_date, string _declaration) public {
		partner_1_name = _partner_1_name;
		partner_2_name = _partner_2_name;
		contract_date = _contract_date;
		declaration = _declaration;
		is_active = true;
	}
	
	function updateStatus(bool _status) public onlyOwner {
		is_active = _status;
		emit StatusChanged(is_active);
	}
	
	event StatusChanged(bool NewStatus);
	
}