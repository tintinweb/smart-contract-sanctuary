pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
contract Ownable {
	// Makes the token ownable to provide security features
	// Account-Address that owns the contract
	address public owner;

	/* This notifies clients about a change of ownership */
	event OwnershipChange(address indexed _owner);

	// Initializes the contract and sets the owner to the contract creator
	constructor() public {
		owner = msg.sender;
	}

	// This modifier is used to execute functions only by the owner of the contract
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	// Transfers the ownership of the contract to another address
	function transferOwnership(address _newOwner) public onlyOwner returns (bool success) {
		require(_newOwner != address(0));
		owner = _newOwner;
		emit OwnershipChange(owner);
		return true;
	}
}

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
contract ERC20 {
	// ERC Token Standard #20 Interface
	// https://github.com/ethereum/EIPs/issues/20
	// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20
	
	// Readable properties of the token
	bytes32 internal version;
	bytes32 public name;
	bytes32 public symbol;
	uint8 public decimals;
	
	// Get the total token supply
    function totalSupply() public view returns (uint256);

	// Get the account balance of an account
    function balanceOf(address _who) public view returns (uint256);

	// Send _value amount of tokens to address _to
	function transfer(address _to, uint256 _value) public returns (bool);

	// Send _value amount of tokens from address _from to address _to
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

	// Returns the amount which _spender is still allowed to withdraw from _owner
	function allowance(address _owner, address _spender) public view returns (uint256);

	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
	function approve(address _spender, uint256 _value) public returns (bool);

    // Events 
	// Triggered when tokens are transferred.
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	// Triggered whenever approve(address _spender, uint256 _value) is called.
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
contract Token is ERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 internal tokenSupply;
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) private allowed;
    
	/* Initializes contract with initial supply tokens to the creator of the contract */
	constructor(
		bytes32 _version,
		bytes32 _name,
		bytes32 _symbol,
		uint8  _decimals,
		uint256 _totalSupply
		) public {
		version = _version;									// Set the version for display purposes
		name = _name;                                   	// Set the name for display purposes
		symbol = _symbol;                               	// Set the symbol for display purposes
		decimals = _decimals;                           	// Amount of decimals for display purposes
		tokenSupply = _totalSupply;                         // Update total supply
		balances[msg.sender] = _totalSupply;                // Give the creator all initial tokens
	}
	
    // @dev total number of tokens in existence
    function totalSupply() public view returns (uint256) {
        return tokenSupply;
    }
    
    /// @dev Gets the balance of the specified address.
    /// @param _who The address to query the the balance of.
    function balanceOf(address _who) public view returns (uint256) {
        return balances[_who];
    }

	/// @notice Send `_value` tokens to `_to` from your account
	/// @param _to The address of the recipient
	/// @param _value the amount to send
	function transfer(address _to, uint256 _value) public returns (bool) {
	    _transfer(msg.sender, _to, _value);
		return true;
	}

	/// @notice Send `_value` tokens to `_to` in behalf of `_from`
	/// @param _from The address of the sender
	/// @param _to The address of the recipient
	/// @param _value the amount to send
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_value <= allowed[_from][msg.sender]);	  // Check allowance
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		_transfer(_from, _to, _value);
		return true;
	}

	/* Internal transfer, only can be called by this or inherited contracts  */
	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != address(0));						    // Prevent transfer to 0x0 address. Use burn() instead
		require(_value <= balances[msg.sender]);			// Check if the sender has enough
		
		balances[_from] = balances[_from].sub(_value);      // Subtract from the sender
        balances[_to] = balances[_to].add(_value);          // Add the same to the recipient
        						
		emit Transfer(_from, _to, _value);					// Notify anyone listening that this transfer took place
	}

    /// @dev Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner address The address which owns the funds.
    /// @param _spender address The address which will spend the funds.
    /// @return A uint256 specifying the amount of tokens still available for the spender.
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
	/// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
	/// @param _spender The address authorized to spend
	/// @param _value the max amount they can spend
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
    
    /// @dev Increase the amount of tokens that an owner allowed to a spender.
    /// @param _spender The address which will spend the funds.
    /// @param _addedValue The amount of tokens to increase the allowance by.
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /// @dev Decrease the amount of tokens that an owner allowed to a spender.
    /// @param _spender The address which will spend the funds.
    /// @param _subtractedValue The amount of tokens to decrease the allowance by.
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
contract Mintable is Token {
    /* If minting is disabled no more tokens can be created */
    bool public mintingEnabled = true;
    
    /** List of agents that are allowed to create new tokens */
    mapping (address => bool) public mintAgents;
    
    /* This notifies clients about the amount minted */
    event Mint(address indexed _to, uint256 _value);
    event MintDisabled(address indexed _from);
    event MintEnabled(address indexed _from);
    event MintingAgentApproved(address indexed _agentAddress, bool _approved);

    // Initializes the contract and sets the owner as minting agent
	constructor() public {
		mintAgents[owner] = true;
	}

    // Only crowdsale contracts are allowed to mint new tokens
    modifier onlyMintAgent() {
        require(mintAgents[msg.sender]);
        _;
    }
    // Make sure minting is still possible.
    modifier canMint() {
        require(mintingEnabled);
        _;
    }

	/* Creates more token supply and sends it to the specified account */
	function mint(address _to, uint256 _value) public onlyMintAgent canMint returns (bool success) {
		tokenSupply = tokenSupply.add(_value);                // Updates totalSupply
        balances[_to] = balances[_to].add(_value);            // Add to the _receiver
		
        // This will make the mint transaction apper in EtherScan.io
        // We can remove this after there is a standardized minting event
		emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
		return true;
	}

	// Owner can allow a crowdsale contract to mint new tokens.
    function approveMintAgent(address _agentAddress, bool _approved) public onlyOwner canMint {
        mintAgents[_agentAddress] = _approved;
        emit MintingAgentApproved(_agentAddress, _approved);
    }

    // Owner can disable minting of new tokens
    function disableMinting() public onlyOwner {
        mintingEnabled = false;
        emit MintDisabled(owner);
    }
    
    // Owner can enable minting of new tokens
    function enableMinting() public onlyOwner {
        mintingEnabled = true;
        emit MintEnabled(owner);
    }
}


// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
contract Burnable is Token {
	/* This notifies clients about the amount burnt */
	event Burn(address indexed _burner, uint256 _value);

	/// @notice Remove `_value` tokens from the system irreversibly
	/// @param _value the amount of money to burn
	function burn(uint256 _value) public returns (bool) {
		require(_value <= balances[msg.sender]);		  // Check if the sender has enough
		require(tokenSupply - _value >= 0); 		      // Check if there&#39;s enough supply
		
		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);  // Subtract from the owner
		tokenSupply = tokenSupply.sub(_value);		      // Updates totalSupply
		
		emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
		return true;
	}
}


// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
contract Frozable is Token {
	mapping (address => bool) public frozenAccount;

	/* This notifies clients about the account frozen */
	event FrozenFunds(address indexed _target, bool _frozen);

	/* Frozes an account to disable transfers */
	function freezeAccount(address _target, bool _freeze) public onlyOwner returns (bool success) {
		frozenAccount[_target] = _freeze;
		emit FrozenFunds(_target, _freeze);
		return true;
	}

	// Overrides the internal _transfer function with Frozable attributes
	function _transfer(address _from, address _to, uint _value) internal {
		require(!frozenAccount[_from]);					    // Check that both accounts
		require(!frozenAccount[_to]);						// are not currently frozen
		super._transfer(_from, _to, _value);                // Performs the normal transfer from Basic Token
	}
}


// ----------------------------------------------------------------------------------------------------------------------------------------------------------------
contract BitzToken is Token, Mintable, Burnable, Frozable {
    
    // Basic Token Properties
    bytes32 private _version = &#39;0.2.1&#39;;
    bytes32 private _name = &#39;Bitz&#39;;
    bytes32 private _symbol = &#39;bitz&#39;;
    uint8  private _decimals = 18;
    uint256 private _totalSupply = 0;

    constructor() public Token (
        _version,
        _name,
        _symbol,
        _decimals,
        _totalSupply
    ) {}
}