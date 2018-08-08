pragma solidity ^0.4.16;

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

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    //function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen); // This generates a public event on the blockchain that will notify clients
    event TokenFrozen(uint256 _frozenUntilBlock, string _reason);
    
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract kBit is Token, owned {
    
     
    /* Public variables of the token */
    uint256 public tokenFrozenUntilBlock;  
    uint256 public totalSupply;

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = &#39;H1.0&#39;;    


    /* This creates an array with all balances */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;


    function kBit(
        ) {
        balances[msg.sender] = 555000 * 1000000000000000000;    // Give the creator all initial tokens, 18 zero is 18 Decimals
        totalSupply = 555000 * 1000000000000000000;             // Update total supply, , 18 zero is 18 Decimals
        name = "kBit";                            				// Token Name
        decimals = 18;                            				// Amount of decimals for display purposes
        symbol = "KBIT";                          				// Token Symbol
    }
    
    function () {
        //if ether is sent to this address, send it back.
        throw;
    }        

    /* Set allowance for other address and notify */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value);               // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balances[_from] -= _value;                         // Subtract from the sender
        balances[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }
    
    /* Transfer tokens */
    function transfer(address _to, uint256 _value) public {
        if (block.number < tokenFrozenUntilBlock) throw;	// Throw is token is frozen in case of emergency
        _transfer(msg.sender, _to, _value);
    }

    /* Transfer tokens from other address */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (block.number < tokenFrozenUntilBlock) throw;	// Throw is token is frozen in case of emergency
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Set allowance for other address */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        if (block.number < tokenFrozenUntilBlock) throw;	// Throw is token is frozen in case of emergency    
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
        
   /* Destroy tokens */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
    
     /* Destroy tokens from account */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowed
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    
    /* Create Tokens and send it to specific address */
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
    /* Freeze specific account from sending & receiving tokens */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    /* Stops all token transfers in case of emergency */     
	function freezeTransfersUntil(uint256 _frozenUntilBlock, string _reason) onlyOwner {     	
		tokenFrozenUntilBlock = _frozenUntilBlock;     	
		TokenFrozen(_frozenUntilBlock, _reason);     
	}     
}