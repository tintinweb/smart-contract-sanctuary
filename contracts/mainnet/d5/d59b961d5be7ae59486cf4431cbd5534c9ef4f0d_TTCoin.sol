pragma solidity ^0.4.12;


//Compiler Version:	v0.4.12+commit.194ff033
/**
 * Math operations with safety checks
 */
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

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract TTCoin is SafeMath,owned{
    string public name;
    string public symbol;
    uint8 public decimals=8;
    uint256 public totalSupply;
    uint256 public soldToken;
	//address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    
  
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function TTCoin(
        
        ) {
                    // Give the creator all initial tokens
        
        totalSupply = 10000000000 *10**uint256(decimals);                        // Update total supply
        balanceOf[msg.sender] = totalSupply; 
        name = "TongTong Coin";                                   // Set the name for display purposes
        symbol = "TTCoin";                               // Set the symbol for display purposes
                                  // Amount of decimals for display purposes
		soldToken=0;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw; 
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();// Check for overflows
       
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        soldToken+=_value;
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
		if (_value <= 0) throw; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw; 
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        soldToken +=_value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
		if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(address _freeze,uint256 _value) onlyOwner returns (bool success) {
        if (balanceOf[_freeze] < _value) throw;            // Check if the sender has enough
	    if (_value <= 0) throw; 
        balanceOf[_freeze] = SafeMath.safeSub(balanceOf[_freeze], _value);                      // Subtract from the sender
        freezeOf[_freeze] = SafeMath.safeAdd(freezeOf[_freeze], _value);                                // Updates totalSupply
        Freeze(_freeze, _value);
        return true;
    }
	
	function unfreeze(address _unfreeze,uint256 _value) onlyOwner returns (bool success) {
        if (freezeOf[_unfreeze] < _value) throw;            // Check if the sender has enough
		if (_value <= 0) throw; 
        freezeOf[_unfreeze] = SafeMath.safeSub(freezeOf[_unfreeze], _value);                      // Subtract from the sender
		balanceOf[_unfreeze] = SafeMath.safeAdd(balanceOf[_unfreeze], _value);
        Unfreeze(_unfreeze, _value);
        return true;
    }
    
    
     function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
	
	

	
// can accept ether
	function() payable {
    }
}