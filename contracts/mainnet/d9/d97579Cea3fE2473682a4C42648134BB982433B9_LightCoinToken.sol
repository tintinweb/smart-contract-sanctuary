pragma solidity ^0.4.11;
contract LightCoinToken{
	mapping (address => uint256) balances;
	address public owner;
	address public lockOwner;
    string public name;
    string public symbol;
    uint8 public decimals;
	uint256 public lockAmount ;
    uint256 public startTime ;
	// total amount of tokens
    uint256 public totalSupply;
	// `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;
    function LightCoinToken() public { 
        owner = 0x9a64fE62837d8E2C0Bd0C2a96bbDdEA609Ab2F19;          // Set owner of contract 
		lockOwner = 0x821C05372425709a68090A17075A855dd20371c7;
		startTime = 1515686400;
        name = "Lightcoin";                                   // Set the name for display purposes
        symbol = "Light";                                           // Set the symbol for display purposes
        decimals =8;                                            // Amount of decimals for display purposes
		totalSupply = 21000000000000000000;               // Total supply
		balances[owner] = totalSupply * 90 /100 ;
		balances[0x6CC0BE3c4ad8306526506CB602591AA029896B46]=2000000;
		lockAmount = totalSupply / 10 ;
    }
	
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance) {
		 return balances[_owner];
	}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {
	    require(_value > 0 );                                      // Check send token value > 0;
		require(balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
	}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	    require(balances[_from] >= _value);                 // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to]);   // Check for overflows
        require(_value <= allowed[_from][msg.sender]);      // Check allowance
		balances[_from] -= _value;
        balances[_to] += _value;
		allowed[_from][_to] -= _value;
        Transfer(_from, _to, _value);
        return true;
	}

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value);
		allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
		return true;
	}
	
    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
	}
	
	/* This unnamed function is called whenever someone tries to send ether to it */
    function () private {
        revert();     // Prevents accidental sending of ether
    }
	
	function releaseToken() public{
	   require(now >= startTime +2 years);	   
       uint256 i = ((now  - startTime -2 years) / (0.5 years));
	   uint256  releasevalue = totalSupply /40 ;
	   require(lockAmount > (4 - i - 1) * releasevalue); 	   
	   lockAmount -= releasevalue ;
	   balances[lockOwner] +=  releasevalue ;
    }
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}