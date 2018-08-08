pragma solidity ^0.4.6;

contract Owned {

    // The address of the account that is the current owner 
    address public owner;

    // The publiser is the inital owner
    function Owned() {
        owner = msg.sender;
    }

    /**
     * Access is restricted to the current owner
     */
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner 
     */
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
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

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
 *
 * Modified version of https://github.com/ConsenSys/Tokens that implements the 
 * original Token contract, an abstract contract for the full ERC 20 Token standard
 */
contract StandardToken is Token {

    // Token starts if the locked state restricting transfers
    bool public locked;

    // DCORP token balances
    mapping (address => uint256) balances;

    // DCORP token allowances
    mapping (address => mapping (address => uint256)) allowed;
    

    /** 
     * Get balance of `_owner` 
     * 
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    /** 
     * Send `_value` token to `_to` from `msg.sender`
     * 
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) returns (bool success) {

        // Unable to transfer while still locked
        if (locked) {
            throw;
        }

        // Check if the sender has enough tokens
        if (balances[msg.sender] < _value) { 
            throw;
        }        

        // Check for overflows
        if (balances[_to] + _value < balances[_to])  { 
            throw;
        }

        // Transfer tokens
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        // Notify listners
        Transfer(msg.sender, _to, _value);
        return true;
    }


    /** 
     * Send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * 
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

         // Unable to transfer while still locked
        if (locked) {
            throw;
        }

        // Check if the sender has enough
        if (balances[_from] < _value) { 
            throw;
        }

        // Check for overflows
        if (balances[_to] + _value < balances[_to]) { 
            throw;
        }

        // Check allowance
        if (_value > allowed[_from][msg.sender]) { 
            throw;
        }

        // Transfer tokens
        balances[_to] += _value;
        balances[_from] -= _value;

        // Update allowance
        allowed[_from][msg.sender] -= _value;

        // Notify listners
        Transfer(_from, _to, _value);
        return true;
    }


    /** 
     * `msg.sender` approves `_spender` to spend `_value` tokens
     * 
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) returns (bool success) {

        // Unable to approve while still locked
        if (locked) {
            throw;
        }

        // Update allowance
        allowed[msg.sender][_spender] = _value;

        // Notify listners
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /** 
     * Get the amount of remaining tokens that `_spender` is allowed to spend from `_owner`
     * 
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}


/**
 * @title SCL (Social) token
 *
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20 with the addition 
 * of ownership, a lock and issuing.
 *
 * #created 05/03/2017
 * #author Frank Bonnet
 */
contract SCLToken is Owned, StandardToken {

    // Ethereum token standaard
    string public standard = "Token 0.1";

    // Full name
    string public name = "SOCIAL";        
    
    // Symbol
    string public symbol = "SCL";

    // No decimal points
    uint8 public decimals = 8;


    /**
     * Starts with a total supply of zero and the creator starts with 
     * zero tokens (just like everyone else)
     */
    function SCLToken() {  
        balances[msg.sender] = 0;
        totalSupply = 0;
        locked = true;
    }


    /**
     * Unlocks the token irreversibly so that the transfering of value is enabled 
     *
     * @return Whether the unlocking was successful or not
     */
    function unlock() onlyOwner returns (bool success)  {
        locked = false;
        return true;
    }


    /**
     * Issues `_value` new tokens to `_recipient` (_value < 0 guarantees that tokens are never removed)
     *
     * @param _recipient The address to which the tokens will be issued
     * @param _value The amount of new tokens to issue
     * @return Whether the approval was successful or not
     */
    function issue(address _recipient, uint256 _value) onlyOwner returns (bool success) {

        // Guarantee positive 
        if (_value < 0) {
            throw;
        }

        // Create tokens
        balances[_recipient] += _value;
        totalSupply += _value;

        // Notify listners
        Transfer(0, owner, _value);
        Transfer(owner, _recipient, _value);

        return true;
    }


    /**
     * Prevents accidental sending of ether
     */
    function () {
        throw;
    }
}