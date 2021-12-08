/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract LOLLIPOP
{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balances;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowed;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* This notifies clients about the amount approval */
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint256 initialSupply, string memory tokenName, uint8 decimalUnits, string memory tokenSymbol, address contractOwner)
    {
        balances[contractOwner] = initialSupply;           // Give the owner all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		owner = contractOwner;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        require(_to != address(0), 'ERR: Unable to transfer to 0x0 address. Use burn() instead'); // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0, 'ERR: Invalid transfer value'); 
        require(balances[msg.sender] >= _value, 'ERR: Not enough balance');            // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to], 'ERR: Overflow check');      // Check for overflows

        balances[msg.sender] = safeSub(balances[msg.sender], _value);        // Subtract from the sender
        balances[_to] = safeAdd(balances[_to], _value);                      // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                                              // Notify anyone listening that this transfer took place

        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) external returns (bool success)
    {
		require(_value > 0, 'ERR: Invalid amount'); 

        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address delegate) external view returns (uint256) 
    {
        return allowed[_owner][delegate];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = safeAdd(allowed[msg.sender][spender], addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = safeSub(allowed[msg.sender][spender], subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function balanceOf(address tokenOwner) external view returns (uint256) 
    {
        return balances[tokenOwner];
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success)
    {
        require(_to != address(0), 'ERR: Unable to transfer to 0x0 address. Use burn() instead');      // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0, 'ERR: Invalid transfer value');                                     
        require(balances[_from] >= _value, 'ERR: Not enough balance');                         // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to], 'ERR: Overflow check');              // Check for overflows
        require(_value <= allowed[_from][msg.sender], 'ERR: Insufficient allowance');         // Check allowance

        balances[_from] = safeSub(balances[_from], _value);                          // Subtract from the sender
        balances[_to] = safeAdd(balances[_to], _value);                              // Add the same to the recipient
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) external returns (bool success) 
    {
        require(balances[msg.sender] >= _value, 'ERR: Not enough balance');        // Check if the sender has enough
		require(_value > 0, 'ERR: Invalid burn value'); 

        balances[msg.sender] = safeSub(balances[msg.sender], _value);    // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value);                         // Updates totalSupply

        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address account, uint256 _value) external returns (bool success)
    {
        require(msg.sender == owner, 'ERR: Forbidden');
        
        require(account != address(0), "ERR: Cannot mint to the zero address");
        require(_value > 0, 'ERR: Invalid mint value');

        totalSupply = safeAdd(totalSupply, _value);
        balances[account] = safeAdd(balances[account], _value);

        emit Transfer(address(0), account, _value);
        return true;
    }
	
	function freeze(uint256 _value) external returns (bool success) 
    {
        require(balances[msg.sender] >= _value, 'ERR: Not enough balance');        // Check if the sender has enough
        require(_value > 0, 'ERR: Invalid freeze value'); 
        balances[msg.sender] = safeSub(balances[msg.sender], _value);    // Subtract from the sender
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], _value);      // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) external returns (bool success) 
    {
        require(freezeOf[msg.sender] >= _value, 'ERR: Not enough frozen balance');  // Check if the sender has enough
		require(_value > 0, 'ERR: Invalid unfreeze value'); 
        freezeOf[msg.sender] = safeSub(freezeOf[msg.sender], _value);      // Subtract from the sender
		balances[msg.sender] = safeAdd(balances[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function setOwner(address newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        owner = newValue;
        return true;
    }


    //Safe Math Functions
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "ERR: multiplication overflow");

        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b > 0, "ERR: division by zero");
        
        uint256 c = a / b;
        require(a == b * c + a % b, "ERR: division overflow");

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b <= a, "ERR: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "ERR: addition overflow");

        return c;
    }
}