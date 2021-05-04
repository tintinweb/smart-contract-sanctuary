/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.4.26;

/**
 * @title SafeMath
 * @dev Mathematical functions to check for overflows
 */
contract SafeMath {
	function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);

		return c;
	}

	function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		uint256 c = a - b;

		return c;
	}
}

contract TetherToken is SafeMath {
	// Public variables of the token
	string public name = "Tether USD";									// Token name
	string public symbol = "USDT";										// Token symbol
	uint8 public decimals = 6;											// Token amount of decimals
	uint256 public totalSupply = 24416147047969263;						// Token supply
	address public Tether = this;										// Token address

	// Creates array with balances
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowances;

	/**
	 * Constructor function
	 *
	 * @dev Constructor function - Deploy the contract
	 */
	constructor() public {
		// Give the creator all initial tokens
		balances[msg.sender] = totalSupply;
	}

	/**
	 * @param _owner The address from which the balance will be retrieved
	 * @return The balance
	 */
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	/**
	 * @notice Allows `_spender` to spend no more than `_value` tokens in msg.sender behalf
	 * @param _owner The address of the account owning tokens
	 * @param _spender The address of the account able to transfer the tokens
	 * @return Amount of remaining tokens allowed to spent
	 */	
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}

	/**
	 * @notice send `_value` token to `_to` from `msg.sender`
	 * @param _to The address of the recipient
	 * @param _value The amount of token to be transferred
	 * @return Whether the transfer was successful or not
	 */	
	function transfer(address _to, uint256 _value) public returns (bool success) {
		// Prevent transfer to 0x0 (empty) address, use burn() instead
		require(_to != 0x0);

		// Prevent empty transactions
		require(_value > 0);

		// Check if sender has enough
		require(balances[msg.sender] >= _value);

		// Subtract the amount from the sender
		balances[msg.sender] = safeSub(balances[msg.sender], _value);

		// Add the same amount to the recipient
		balances[_to] = safeAdd(balances[_to], _value);

		// Generate the public transfer event and return success
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	 * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
	 * @param _from The address of the sender
	 * @param _to The address of the recipient
	 * @param _value The amount of token to be transferred
	 * @return Whether the transfer was successful or not
	 */	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		// Prevent transfer to 0x0 (empty) address
		require(_to != 0x0);

		// Prevent empty transactions
		require(_value > 0);

		// Check if sender is allowed to spend the amount
		require(allowances[_from][msg.sender] >= _value);

		// Check if token owner has enough
		require(balances[_from] >= _value);

		// Subtract the amount from the sender
		allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);

		// Subtract the amount from the token owner
		balances[_from] = safeSub(balances[_from], _value);

		// Add the same amount to the recipient
		balances[_to] = safeAdd(balances[_to], _value);

		// Generate the public transfer event and return success
		emit Transfer(_from, _to, _value);
		return true;
	}

	/**
	 * @notice `msg.sender` approves `_spender` to spend `_value` tokens
	 * @param _spender The address of the account able to transfer the tokens
	 * @param _value The amount of tokens to be approved for transfer
	 * @return Whether the approval was successful or not
	 */	
	function approve(address _spender, uint256 _value) public returns (bool success) {
		// The amount has to be bigger or equal to 0
		require(_value >= 0);

		allowances[msg.sender][_spender] = _value;

		// Generate the public approval event and return success
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	 * @notice Remove `_value` tokens from the system irreversibly
	 * @param _value the amount of money to burn
	 */
	function burn(uint256 _value) public returns (bool success) {
		// Check if value is less than 0
		require(_value > 0);

		// Check if the owner has enough tokens
		require(balances[msg.sender] >= _value);

		// Subtract the value from the owner
		balances[msg.sender] = safeSub(balances[msg.sender], _value);

		// Subtract the value from the Total Balance
		totalSupply = safeSub(totalSupply, _value);

		// Generate the public burn event and return success
		emit Burn(msg.sender, _value);
		return true;
	}

	// Public events on the blockchain to notify clients
	event Transfer(address indexed _owner, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed _owner, uint256 _value);
}