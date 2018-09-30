pragma solidity ^0.4.23;


// Authorization control functions
contract Ownable {
	
	// The administrator of the contract
	address private owner;
	
	// Set the owner to the original creator of the contract
	constructor() public {
		owner = msg.sender;
	}
	
	// Parameters like status can only be changed by the contract owner
	modifier onlyOwner() {
		require( 
			msg.sender == owner,
			&#39;Only the administrator can change this&#39;
		);
		_;
	}
	
}


// Primary contract
contract Blockchainedlove is Ownable {
	
	// Partner details and other contract parameters
    string public partner_1_name;
    string public partner_2_name;
	string public contract_date;
	string public declaration;
	bool public is_active;
	
	// Main function, executed once upon deployment
	constructor() public {
		// Custom variables
		partner_1_name = &#39;Александр Иванов&#39;;
		partner_2_name = &#39;Мария Иванова&#39;;
		contract_date = &#39;19 Сентября 2018&#39;;
		// Standard variables
		declaration = &#39;This smart contract has been prepared and deployed by Blockchained.Love - it is stored permanently on the Ethereum blockchain and cannot be deleted. The status of the smart contract, represented by the value of the is_active variable, an only be changed by Blockchained.Love following explicit consent from both persons mentioned in the document.&#39;;
		is_active = true;
	}
	
	// Change the status of the contract
	function updateStatus(bool _status) public onlyOwner {
		is_active = _status;
		emit StatusChanged(is_active);
	}
	
	// Record the status change event
	event StatusChanged(bool NewStatus);
	
}