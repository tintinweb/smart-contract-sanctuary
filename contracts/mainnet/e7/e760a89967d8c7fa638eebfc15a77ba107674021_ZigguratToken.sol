pragma solidity ^0.4.13;


contract admined {
	address public admin;
    address public coAdmin;

	function admined() {
		admin = msg.sender;
        coAdmin = msg.sender;
	}

	modifier onlyAdmin(){
		require((msg.sender == admin) || (msg.sender == coAdmin)) ;
		_;
	}

	function transferAdminship(address newAdmin) onlyAdmin {
		admin = newAdmin;
	}

    function transferCoadminship(address newCoadmin) onlyAdmin {
		coAdmin = newCoadmin;
	}


} 

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
}

/*
You should inherit from StandardToken 
(This implements ONLY the standard functions and NOTHING else.
If you deploy this, you won&#39;t have anything useful.)
Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
*/

contract StandardToken is Token {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);

        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        
        require(_value > 0);
        
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        
        uint256 allowance = allowed[_from][msg.sender];
        // Check if the sender has enough     
        require(balances[_from] >= _value && allowance >= _value);
        // Add the same to the recipient
        balances[_to] += _value;
        // Subtract from the sender
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) returns (bool success) {
    		
    		require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    // This creates an array with all balances
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.

In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.

1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.

.*/


contract ZigguratToken is admined, StandardToken {

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Ziggurat Token
    uint8 public decimals = 18;           //How many decimals to show. ie. 18 decimals is the strongly suggested default, avoid changing it
    string public symbol;                 //An identifier: eg ZIG
    string public version = "1.0";       //1 standard. Just an arbitrary versioning scheme.
    uint256 public totalMaxSupply = 5310000000 * 10 ** 17; // 531M Limit
    
    function ZigguratToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    //Supply may be increased at any time and by any amount by minting new tokens and transferring them to a desired address. 
    //Adding ownership modifiers and restricting privileges would prove useful in most cases.

    function mintToken(address target, uint256 mintedAmount) onlyAdmin returns (bool success) {
         // Maximum supply set and minting would break the limit
        require ((totalMaxSupply == 0) || ((totalMaxSupply != 0) && (safeAdd (totalSupply, mintedAmount) <= totalMaxSupply )));

        balances[target] = safeAdd(balances[target], mintedAmount);
        totalSupply = safeAdd(totalSupply, mintedAmount);
		Transfer(0, this, mintedAmount);
		Transfer(this, target, mintedAmount);
        return true;
	} 

    function safeAdd(uint a, uint b) internal returns (uint) {
        require (a + b >= a); 
        return a + b;
    }

    //Supply may be decreased at any time by subtracting from a desired address. 
    //There is one caveat: the token balance of the provided party must be at least equal to the amount being subtracted from total supply.

    function decreaseSupply(uint _value, address _from) onlyAdmin returns (bool success) {
    	  require(_value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        totalSupply = safeSub(totalSupply, _value);  
        Transfer(_from, 0, _value);
        return true;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require (b <= a); 
        return a - b;
    }

    /* Approves and then calls the receiving contract */
        /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
    		require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed when one does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}