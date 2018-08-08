pragma solidity ^0.4.11;

contract SafeMath{
	function safeMul(uint a, uint b) internal returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeDiv(uint a, uint b) internal returns (uint) {
		assert(b > 0);
		uint c = a / b;
		assert(a == b * c + a % b);
		return c;
	}

	function safeSub(uint a, uint b) internal returns (uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) internal returns (uint) {
		uint c = a + b;
		assert(c >= a);
		return c;
	}
	function assert(bool assertion) internal {
		if (!assertion) {
			revert();
		}
	}
}

// Contract that defines administrative actions
contract admined {

	// Define adminitrator address
	address public admin;

	// Entry function sets the admin as the sender
	function admined(){
		admin = msg.sender;
	}

	// Check if the sender is the admin
	modifier onlyAdmin(){
		require(msg.sender == admin);
		_;
	}

	// Transfer the admin role to a new address
	function transferAdminship(address newAdmin) onlyAdmin {
		admin = newAdmin;
	}
}

// Contract that creates the Token
contract Token is SafeMath {

	// Contract balance
	mapping (address => uint256) public balanceOf;
	// Token name
	string public name = "MoralityAI";
	// Token symbol
	string public symbol = "Mo";
	// Decimals to use
	uint8 public decimal = 18; 
	// Total initial suppy
	uint256 public totalSupply = 1000000000000000000000000;
	// Transfer function interface
	event Transfer(address indexed from, address indexed to, uint256 value);

	// Token creation function
	function Token(){
		// set the balance of the creator to the initial supply
		balanceOf[msg.sender] = totalSupply;
	}

	// Transfer function used to send tokens to an address
	function transfer(address _to, uint256 _value){
		// Check if the creator actually has the required balance
		require(balanceOf[msg.sender] >= _value);
		// Check if the amount sent will not overflow
		require(safeAdd(balanceOf[_to], _value) >= balanceOf[_to]);
		// Substract tokens from the creator
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
		// Add tokens to the transfer address
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);
		// Execute the transfer
		Transfer(msg.sender, _to, _value);
	}
}

// Contract that creates a token which inherits
// the administrator contract properties and token contract properties
contract MoralityAI is admined, Token{

	// Create the token
	function MoralityAI() Token(){
		admin = msg.sender;
		balanceOf[admin] = totalSupply;
	}

	// Minting function that can only be called by the admin
	function mintToken(address target, uint256 mintedAmount) onlyAdmin{
		// Increase the balance of the target address with the amount of minted tokens
		balanceOf[target] = safeAdd(balanceOf[target], mintedAmount);
		// Increase the total supply of tokens
		totalSupply = safeAdd(totalSupply, mintedAmount);
		// Transfer the amount to this contract
		Transfer(0, this, mintedAmount);
		// Then transfer the amount to the target address
		Transfer(this, target, mintedAmount);
	}

	// Toekn transfer function
	function transfer(address _to, uint256 _value) public{
		// Check if balance of the sender is not negative
		require(balanceOf[msg.sender] > 0);
		// Check if balance of the sender is greater than or equal than the amount transfered
		require(balanceOf[msg.sender] >= _value);
		// Check for overflow
		require(safeAdd(balanceOf[_to], _value) >= balanceOf[_to]);

		// Substract the amount of tokens from the creator
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
		// And add the amount of tokens to the target address
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);
		// Execute the transfer
		Transfer(msg.sender, _to, _value);
	}
}