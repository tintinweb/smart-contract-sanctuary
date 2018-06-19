pragma solidity ^0.4.11;

/**
 * Authors: Justin Jones, Marshall Stokes
 * Published: 2017 by Sprux LLC
 */


/* Contract provides functions so only contract owner can execute a function */
contract owned {
    address public owner; //the contract owner

    function owned() {
        owner = msg.sender; //constructor initializes the creator as the owner on initialization
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw; // functions with onlyOwner will throw and exception if not the contract owner
        _;
    }

    function transferOwnership(address newOwner) onlyOwner { // transfer contract owner to new owner
        owner = newOwner;
    }
}


contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

/**
 * Centrally issued Ethereum token.
 *
 * Token supply is created in the token contract creation and allocated to one owner for distribution. This token is mintable, so more tokens
 * can be added to the total supply and assigned to an address supplied at contract execution.
 *
 */

contract StandardMintableToken is owned{ 
    /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name;                     // the token name 
    string public symbol;                   // the ticker symbol
    uint8 public decimals;                  // amount of decimal places in the token
    uint256 public totalSupply;             // total tokens
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    /* This creates an array with all frozen accounts */
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    
    /* This generates a public event on the blockchain that will notify clients */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function StandardMintableToken(
        string tokenName,               // the token name
        uint8 decimalUnits,             // amount of decimal places in the token
        string tokenSymbol,             // the token symbol
        uint256 initialSupply            // the initial distro amount
        ) {

        balanceOf[msg.sender] = initialSupply;                   // Give the creator all initial tokens
        totalSupply = initialSupply;                             // Update total supply
        name = tokenName;                                        // Set the name for display purposes
        symbol = tokenSymbol;                                    // Set the symbol for display purposes
        decimals = decimalUnits;                                 // Amount of decimals for display purposes
    }

    /* Send tokens */
    function transfer(address _to, uint256 _value) returns (bool success){
        if (_value == 0) return false; 				             // Don&#39;t waste gas on zero-value transaction
        if (balanceOf[msg.sender] < _value) return false;    // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        if (frozenAccount[msg.sender]) throw;                // Check if sender frozen
        if (frozenAccount[_to]) throw;                       // Check if recipient frozen                 
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens on your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;            // Update allowance first
        Approval(msg.sender, _spender, _value);              // Notify of new Approval
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                        // Check if sender frozen       
        if (frozenAccount[_to]) throw;                          // Check if recipient frozen                 
        if (balanceOf[_from] < _value) return false;          	// Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;    // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;       // Check allowance
        balanceOf[_from] -= _value;                             // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;                 // Update sender&#39;s allowance 
        Transfer(_from, _to, _value);                           // Perform the transfer
        return true;
    }
    
    /* A function to freeze or un-freeze accounts, to and from */
    
    function freezeAccount(address target, bool freeze ) onlyOwner {    
        frozenAccount[target] = freeze;                       // set the array object to the value of bool freeze
        FrozenFunds(target, freeze);                          // notify event
    }
    

    /* A function to burn tokens and remove from supply */
    
    function burn(uint256 _value) returns (bool success) {
        if (frozenAccount[msg.sender]) throw;                 // Check if sender frozen       
        if (_value == 0) return false; 				          // Don&#39;t waste gas on zero-value transaction
        if (balanceOf[msg.sender] < _value) return false;     // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        Transfer(msg.sender,0, _value);	                      // Burn _value tokens
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success) {
        if (frozenAccount[msg.sender]) throw;                // Check if sender frozen       
        if (frozenAccount[_from]) throw;                     // Check if recipient frozen 
        if (_value == 0) return false; 			             // Don&#39;t waste gas on zero-value transaction
        if (balanceOf[_from] < _value) return false;         // Check if the sender has enough
        if (_value > allowance[_from][msg.sender]) throw;    // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        totalSupply -= _value;                               // Updates totalSupply
        allowance[_from][msg.sender] -= _value;				 // Updates allowance
        Transfer(_from, 0, _value);                          // Burn tokens by Transfer to incinerator
        return true;
    }
    
    /* A function to add more tokens to the total supply, accessible only to owner*/
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        if (balanceOf[target] + mintedAmount < balanceOf[target]) throw; // Check for overflows
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, target, mintedAmount);

    }
    
}