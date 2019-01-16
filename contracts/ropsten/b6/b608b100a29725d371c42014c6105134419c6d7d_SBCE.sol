pragma solidity ^0.4.19;
/*
 * Standard token contract with ability to hold some amount on some balances before single initially specified deadline
 * Which is useful for example for holding unsold tokens for a year for next step of project management
 *
 * Implements initial supply and does not allow to supply more tokens later
 *
 */ 

contract SBCE {
	/* Public variables of the token */	
	string public constant name = "SBC token";
	string public constant symbol = "SBCE";	
	uint8 public constant decimals = 8;
	address public owner;
	uint256 public totalSupply_;

	address public airdrop;
	uint256 public airdropAmount;
	bool public airdropConjured;

	/* This creates an array with all balances */
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);	
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed from, uint256 value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function SBCE(uint256 initialSupply) public {
		owner=msg.sender;
		balances[owner] = initialSupply * 100000000;							// Give the creator all initial tokens
		totalSupply_ = initialSupply * 100000000;								// Update total supply
		airdropAmount = totalSupply_ / 37 * 100;
	}
    /*This returns total number of tokens in existence*/
	function totalSupply() public view returns (uint256) {
    	return totalSupply_;
  	}
	
	/* Send coins */
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
    	require(balances[msg.sender] >=_value);
		
		require(balances[msg.sender] >= _value);
		require(balances[_to] + _value >= balances[_to]);

		balances[msg.sender] -= _value;					 
		balances[_to] += _value;					
		Transfer(msg.sender, _to, _value);				  
		return true;
	}

	/*This pulls the allowed tokens amount from address to another*/
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));						  
		require(_value <= balances[_from]);			
		require(_value <= allowed[_from][msg.sender]);

		require(balances[msg.sender] >= _value);
		require(balances[_to] + _value >= balances[_to]);		
		require(allowed[_from][msg.sender] >= _value);			// Check allowance

		balances[_from] -= _value;						   			// Subtract from the sender
		balances[_to] += _value;							 		// Add the same to the recipient
		allowed[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
    	return balances[_owner];
	}

	/* Allow another contract to spend some tokens in your behalf. 
	Changing an allowance brings the risk of double spending, when both old and new values will be used */
	function approve(address _spender, uint256 _value) public returns (bool) {
    	allowed[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);		
		return true;
	}	
	
	/* This returns the amount of tokens that an owner allowed to a spender. */
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	/* This function is used to increase the amount of tokens allowed to spend by spender.*/
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    	require(allowed[msg.sender][_spender] + _addedValue >= allowed[msg.sender][_spender]);
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
    	Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    	return true;
  	}

	/* This function is used to decrease the amount of tokens allowed to spend by spender.*/
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} 
		else {
			allowed[msg.sender][_spender] = oldValue - _subtractedValue;
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
  	}

	function burn(uint256 _value) public returns (bool) {		
		require(balances[msg.sender] >= _value ); 							// value > totalSupply is impossible because it means that sender balance is greater than totalSupply.				
		balances[msg.sender] -= _value;					  					// Subtract from the sender
		totalSupply_ -= _value;												// Updates totalSupply
		Burn(msg.sender, _value);											// Fires the event about token burn
		return true;
	}

	function burnFrom(address _from, uint256 _value) public returns (bool) {
		require(balances[_from] >= _value );								// Check if the sender has enough
		require(allowed[_from][msg.sender] >= _value);					// Check allowance
		balances[_from] -= _value;						  					// Subtract from the sender
		totalSupply_ -= _value;							   					// Updates totalSupply
		Burn(_from, _value);												// Fires the event about token burn
		return true;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
    	owner = newOwner;
	}

	function setAirdropReceiver(address _airdrop) public onlyOwner {
		require(_airdrop != address(0));
		airdrop = _airdrop;
	}

	function conjureAirdrop() public onlyOwner {			
		require(totalSupply_ + airdropAmount >= balances[airdrop]);
		require(airdrop != address(0));
		balances[airdrop] += airdropAmount;
		totalSupply_ += airdropAmount;		
	}
}