pragma solidity ^0.4.11;

contract Freewatch {
	string public name;
	string public symbol;
	uint8 public decimals;
	
    /* Creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	
	/* Initializes contract with initial supply tokens to the creator of the contract */
	function Freewatch (
		uint256 initialSupply,
		string tokenName,
		uint8 decimalUnits,
		string tokenSymbol
		) {
		balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
		name = tokenName;                                   // Set the name for display purposes
		symbol = tokenSymbol;                               // Set the symbol for display purposes
		decimals = decimalUnits;                            // Amount of decimals for display purposes
}
	
	/* Send coins */
	function transfer(address _to, uint256 _value) {
		if(msg.data.length < (2 * 32) + 4) { revert(); }
		/* Check if sender has balance and for overflows */
		if (balanceOf[msg.sender] < _value || balanceOf[_to] + _value < balanceOf[_to])
			revert();
		/* Add and subtract new balances */
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
			/* Notify anyone listening that this transfer took place */
		Transfer(msg.sender, _to, _value);
		}
}