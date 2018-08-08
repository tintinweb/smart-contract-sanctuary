pragma solidity ^0.4.18;

library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TestToken is ERC20 {
	using SafeMath for uint256;
	
	/* Public variables of the token */
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public _totalSupply;
		
	modifier onlyPayloadSize(uint256 numwords) {                                         //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
		assert(msg.data.length == numwords * 32 + 4);
		_;
	}
	
	/* This creates an array with all balances */
	mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;

	/* Initializes contract with initial supply tokens to the creator of the contract */
	constructor() public {
		name = "TestToken";                                   	// Set the name for display purposes
		symbol = "TEST";                               				// Set the symbol for display purposes
		decimals = 18;                            					// Amount of decimals for display purposes
		_totalSupply = 10000000000000000000000000000 ;     			
		balances[msg.sender] = _totalSupply;
	}

	function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool _success) {
		return _transfer(msg.sender, _to, _value);
	}
	
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(_value <= allowed[_from][msg.sender]);     								// Check allowance
        
		_transfer(_from, _to, _value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		
		return true;
    }
	
	/* Internal transfer, only can be called by this contract */
	function _transfer(address _from, address _to, uint256 _value) internal returns (bool _success) {
		require (_to != address(0x0));														// Prevent transfer to 0x0 address.
		require(_value >= 0);
		require (balances[_from] >= _value);                								// Check if the sender has enough
		require (balances[_to].add(_value) > balances[_to]); 								// Check for overflows
		
		uint256 previousBalances = balances[_from].add(balances[_to]);					// Save this for an assertion in the future
		
		balances[_from] = balances[_from].sub(_value);        				   				// Subtract from the sender
		balances[_to] = balances[_to].add(_value);                            				// Add the same to the recipient
		
		emit Transfer(_from, _to, _value);
		
		// Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances); //add safeMath
		
		return true;
	}

	function increaseApproval(address _spender, uint256 _addedValue) onlyPayloadSize(2) public returns (bool _success) {
		require(allowed[msg.sender][_spender].add(_addedValue) <= balances[msg.sender]);
		
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		
		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) onlyPayloadSize(2) public returns (bool _success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		
		return true;
	}
	
	function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool _success) {
		require(_value <= balances[msg.sender]);
		
		allowed[msg.sender][_spender] = _value;
		
		emit Approval(msg.sender, _spender, _value);
		
		return true;
	}
  
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}
	
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
	
	function allowance(address _owner, address _spender) public view returns (uint256 _remaining) {
		return allowed[_owner][_spender];
	}
}