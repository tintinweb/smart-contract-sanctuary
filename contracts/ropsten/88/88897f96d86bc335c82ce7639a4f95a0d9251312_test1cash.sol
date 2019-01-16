pragma solidity ^0.5;

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

  
}
contract test1cash is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address payable public  owner;

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
     constructor() public {

        balanceOf[msg.sender] = 500000000000000000000000;              // Give the creator all initial tokens
        totalSupply = 500000000000000000000000;                        // Update total supply
        name = "TEST1CASH";                                   // Set the name for display purposes
        symbol = "TEST1CASH";                               // Set the symbol for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
	owner = msg.sender;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        if (_to == address(0)) revert(&#39;transfer&#39;);                               // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) revert(&#39;transfer&#39;); 
        if (balanceOf[msg.sender] < _value) revert(&#39;transfer&#39;);           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(&#39;transfer&#39;); // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		if (_value <= 0) revert(&#39;approve&#39;); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)  {
        if (_to == address(0)) revert(&#39;transferFrom&#39;);                                // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) revert(&#39;transferFrom&#39;); 
        if (balanceOf[_from] < _value) revert(&#39;transferFrom&#39;);                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(&#39;transferFrom&#39;);  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert(&#39;transferFrom&#39;);     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert(&#39;burn&#39;);            // Check if the sender has enough
		if (_value <= 0) revert(&#39;burn&#39;); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert(&#39;freeze&#39;);            // Check if the sender has enough
		if (_value <= 0) revert(&#39;freeze&#39;); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert(&#39;unfreeze&#39;);            // Check if the sender has enough
		if (_value <= 0) revert(&#39;unfreeze&#39;); 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	// transfer balance to owner
	function withdrawEther(uint256 amount) public {
		if(msg.sender != owner) revert(&#39;withdrawEther&#39;);
		owner.transfer(amount);
	}
	
// can accept ether
	function () external payable {} 
}