pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
 
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
    /// @return total amount of tokens
    uint public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract BDToken is ERC20 {
    using SafeMath for uint;
	
    uint constant private MAX_UINT256 = 2**256 - 1;
	uint8 constant public decimals = 18;
    string public name;
    string public symbol;
	address public owner;
	// True if transfers are allowed
	bool public transferable = true;
    /* This creates an array with all balances */
	mapping (address => uint) freezes;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    modifier onlyOwner {
        require(msg.sender == owner);//"Only owner can call this function."
        _;
    }
	
	modifier canTransfer() {
		require(transferable == true);
		_;
	}
	
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint value);
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint value);
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function BDToken() public {
		totalSupply = 100*10**26; // Update total supply with the decimal amount
		name = "BaoDe Token";
		symbol = "BDT";
		balances[msg.sender] = totalSupply; // Give the creator all initial tokens
		owner = msg.sender;
		emit Transfer(address(0), msg.sender, totalSupply);
    }

    /* Send coins */
    function transfer(address _to, uint _value) public canTransfer returns (bool success) {
		require(_to != address(0));// Prevent transfer to 0x0 address.
		require(_value > 0);
        require(balances[msg.sender] >= _value); // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to]); // Check for overflows
		
		balances[msg.sender] = balances[msg.sender].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value);  // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);   // Notify anyone listening that this transfer took place
		return true;
    }

	/* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint _value) public canTransfer returns (bool success) {
        uint allowance = allowed[_from][msg.sender];
		require(_to != address(0));// Prevent transfer to 0x0 address.
		require(_value > 0);
		require(balances[_from] >= _value); // Check if the sender has enough
		require(allowance >= _value); // Check allowance
        require(balances[_to] + _value >= balances[_to]); // Check for overflows     
        
        balances[_from] = balances[_from].sub(_value);      // Subtract from the sender
        balances[_to] = balances[_to].add(_value);          // Add the same to the recipient
		if (allowance < MAX_UINT256) {
			allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		}
        emit Transfer(_from, _to, _value);
        return true;
    }
	
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint _value) public canTransfer returns (bool success) {
		require(_value >= 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
	function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

	function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
	
	function freezeOf(address _owner) public view returns (uint freeze) {
        return freezes[_owner];
    }
	
    function burn(uint _value) public canTransfer returns (bool success) {
		require(balances[msg.sender] >= _value); // Check if the sender has enough
		require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                    // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint _value) public canTransfer returns (bool success) {
		require(balances[msg.sender] >= _value); // Check if the sender has enough
		require(_value > 0);
		require(freezes[msg.sender] + _value >= freezes[msg.sender]); // Check for overflows
		
        balances[msg.sender] = balances[msg.sender].sub(_value);  // Subtract from the sender
        freezes[msg.sender] = freezes[msg.sender].add(_value);  
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint _value) public canTransfer returns (bool success) {
		require(freezes[msg.sender] >= _value);  // Check if the sender has enough          
		require(_value > 0);
		require(balances[msg.sender] + _value >= balances[msg.sender]); // Check for overflows
		
        freezes[msg.sender] = freezes[msg.sender].sub(_value);  // Subtract from the sender
		balances[msg.sender] = balances[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	/**
	* @dev Transfer tokens to multiple addresses
	* @param _addresses The addresses that will receieve tokens
	* @param _amounts The quantity of tokens that will be transferred
	* @return True if the tokens are transferred correctly
	*/
	function transferForMultiAddresses(address[] _addresses, uint[] _amounts) public canTransfer returns (bool) {
		for (uint i = 0; i < _addresses.length; i++) {
		  require(_addresses[i] != address(0)); // Prevent transfer to 0x0 address.
		  require(_amounts[i] > 0);
		  require(balances[msg.sender] >= _amounts[i]); // Check if the sender has enough
          require(balances[_addresses[i]] + _amounts[i] >= balances[_addresses[i]]); // Check for overflows

		  // SafeMath.sub will throw if there is not enough balance.
		  balances[msg.sender] = balances[msg.sender].sub(_amounts[i]);
		  balances[_addresses[i]] = balances[_addresses[i]].add(_amounts[i]);
		  emit Transfer(msg.sender, _addresses[i], _amounts[i]);
		}
		return true;
	}
	
	function stop() public onlyOwner {
        transferable = false;
    }

    function start() public onlyOwner {
        transferable = true;
    }
	
	function transferOwnership(address newOwner) public onlyOwner {
		owner = newOwner;
	}
	
	// transfer balance to owner
	function withdrawEther(uint amount) public onlyOwner {
		require(amount > 0);
		owner.transfer(amount);
	}
	
	// can accept ether
	function() public payable {
    }
	
}