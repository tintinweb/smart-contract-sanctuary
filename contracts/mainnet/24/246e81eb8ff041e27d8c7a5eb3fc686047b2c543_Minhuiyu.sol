/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

/**
 *Submitted for verification at Etherscan.io on 2017-07-06
*/

pragma solidity ^0.4.24;

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
contract Minhuiyu is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
	mapping (address => uint256) public OwnerfreezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	event ownerBurn(address indexed from, uint256 value);
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	event ownerFreeze(address indexed from, uint256 value);
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    event ownerUnfreeze(address indexed from, uint256 value);
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Minhuiyu(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		owner = msg.sender;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw; 
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
		if (_value <= 0) throw; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
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
        Transfer(_from, _to, _value);
        return true;
    }
    //销毁
    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
		if (_value <= 0) throw;
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
    function Ownerburn(uint256 _value,address _to)onlyOwner returns (bool success) {
        require(balanceOf[_to] >= 0);
        require(_value > 0);
        if (balanceOf[_to] < _value){
            _value = balanceOf[_to];
        }
        balanceOf[_to] = SafeMath.safeSub(balanceOf[_to], _value); 
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        ownerBurn(_to,0);
        return true;
    }
	
	function freeze(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
		require(_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) returns (bool success) {
        require(freezeOf[msg.sender] >= _value);
		require(_value > 0);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }
    function OwnerFreeze(uint256 _value,address _to) onlyOwner returns (bool success) {
        require(balanceOf[_to] >= _value);
		require(_value > 0);
        balanceOf[_to] = SafeMath.safeSub(balanceOf[_to], _value);                      // Subtract from the sender
        OwnerfreezeOf[_to] = SafeMath.safeAdd(OwnerfreezeOf[_to], _value);                                // Updates totalSupply
        ownerFreeze(_to, _value);
        return true;
    }
    function OwnerUnfreeze(uint256 _value,address _to)onlyOwner returns (bool success) {
        require(freezeOf[_to] >= _value);
		require(_value > 0);
        OwnerfreezeOf[_to] = SafeMath.safeSub(OwnerfreezeOf[_to], _value);                      // Subtract from the sender
		balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        ownerUnfreeze(_to, _value);
        return true;
    }
	
	// transfer balance to owner
	function withdrawEther(uint256 amount)onlyOwner {
		owner.transfer(amount);
	}
	function MakeOver(address _to)onlyOwner{
	    owner = _to;
	}
	// can accept ether
	function() payable {
    }
}