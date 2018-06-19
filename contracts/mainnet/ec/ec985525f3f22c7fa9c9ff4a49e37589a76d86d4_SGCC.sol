pragma solidity ^0.4.8;

/* Math operations with safety checks */
contract SafeMath {
	function safeMul(uint256 a, uint256 b) internal returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
		assert(b > 0);
		uint256 c = a / b;
		assert(a == b * c + a % b);
		return c; 
	}
	function safeSub(uint256 a, uint256 b) internal returns (uint256) {
		assert(b <= a);
		return a - b; 
	}
	function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
		uint256 c = a + b;
		assert(c>=a && c>=b);
		return c;
	}
	function assert(bool assertion) internal {
		if (!assertion) {
			throw; 
		}
	}
}

/* SGCC ERC20 Token */
contract SGCC is SafeMath { 
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	address public owner;
	
	/* This creates an array with all balances */
	mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
	mapping (address => mapping (address => uint256)) public allowance;
	
	/* This generates a public event for notifying clients of transfers */ 
	event Transfer(address indexed from, address indexed to, uint256 value);
	/* This notifies clients about the amount burnt */ 
	event Burn(address indexed from, uint256 value);
	/* This notifies clients about the amount frozen */ 
	event Freeze(address indexed from, uint256 value);
	/* This notifies clients about the amount unfrozen */ 
	event Unfreeze(address indexed from, uint256 value);

	/* Initializes contract with initial supply of tokens to the creator of the contract */ 
	function SGCC() public {
		decimals = 18;
		balanceOf[msg.sender] = 20000000000 * (10 ** uint256(decimals)); // Give the creator all initial tokens
		totalSupply = 20000000000 * (10 ** uint256(decimals)); // Update total supply
		name = &#39;SGCC&#39;; // Set the name for display purposes
		symbol = &#39;SGCC&#39;; // Set the symbol for display purposes
		owner = msg.sender;
	}

	/* Send coins from the caller&#39;s account */
	function transfer(address _to, uint256 _value) public {
		if (_to == 0x0) throw; // Prevent transfer to 0x0 address. Use burn() instead 
		if (_value <= 0) throw;
		if (balanceOf[msg.sender] < _value) throw; // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows 
		balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
		balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value); // Add the same to the recipient
		Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
	}
	
	/* Allow another account to withdraw up to some number of coins from the caller */
	function approve(address _spender, uint256 _value) public returns (bool success) {
		if (_value <= 0) throw;
		allowance[msg.sender][_spender] = _value;
		return true;
	}
	
	/* Send coins from an account that previously approved this caller to do so */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		if (_to == 0x0) throw; // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw;
		if (balanceOf[_from] < _value) throw; // Check if the sender has enough 
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
		if (_value > allowance[_from][msg.sender]) throw; // Check allowance 
		balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value); // Subtract from the sender
		balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value); // Add the same to the recipient
		allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value); 
		Transfer(_from, _to, _value); // emit event
		return true;
	}
	
	/* Permanently delete some number of coins that are in the caller&#39;s account */
	function burn(uint256 _value) public returns (bool success) {
		if (balanceOf[msg.sender] < _value) throw; // Check if the sender has enough
		if (_value <= 0) throw;
		balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
		totalSupply = SafeMath.safeSub(totalSupply,_value); // Reduce the total supply too
		Burn(msg.sender, _value); // emit event
		return true;
	}

	/* Make some of the caller&#39;s coins temporarily unavailable */
	function freeze(uint256 _value) public returns (bool success) {
		if (balanceOf[msg.sender] < _value) throw; // Check if the sender has enough
		if (_value <= 0) throw;
		balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
		freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value); // Add to sender&#39;s frozen balance
		Freeze(msg.sender, _value); // emit event
		return true;
	}

	/* Frozen coins can be made available again by unfreezing them */
	function unfreeze(uint256 _value) public returns (bool success) {
		if (freezeOf[msg.sender] < _value) throw; // Check if the sender has enough
		if (_value <= 0) throw;
		freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value); // Subtract from sender&#39;s frozen balance
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value); // Add to the sender
		Unfreeze(msg.sender, _value); // emit event
		return true; 
	}

	function withdrawEther(uint256 amount) public {
		// disabled
	}
	function() public payable {}
}