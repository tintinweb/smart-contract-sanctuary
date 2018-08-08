pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Token {

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

//------------------------------------------------------------------------
// This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.
//
// In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
// Imagine coins, currencies, shares, voting weight, etc.
// Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.
//
// 1) Initial Finite Supply (upon creation one specifies how much is minted).
// 2) In the absence of a token registry: Optional Decimal, Symbol & Name.
// 3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.
// ------------------------------------------------------------------------
contract DIDOToken is ERC20Token {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    /// ------------------------------------------------------------------------
    ///  Public variables of the token
    ///
    /// NOTE:
    /// The following variables are OPTIONAL vanities. One does not have to include them.
    /// They allow one to customise the token contract & in no way influences the core functionality.
    /// Some wallets/interfaces might not even bother to look at this information.
    /// ------------------------------------------------------------------------
    string public name;                   //fancy name: eg Simon Bucks
    uint8  public decimals;               //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.
    uint   public totalSupply;

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function() external payable {
        revert();
    }
    
    constructor() public {
        symbol   = "DIDO";                              // Set the symbol for display purposes
        name     = "Doitdo Axis";                       // Set the name for display purposes
        decimals = 18;                                  // Amount of decimals for display purposes

        totalSupply = 3 * 10**26;                      // Update total supply
        balances[msg.sender] = totalSupply;            // Give the creator all initial tokens
    }

    function transfer(address _to, uint _value) public returns (bool) {
        /// Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        /// If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        /// Replace the if with this one instead.
        /// if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (_value > 0 && balances[msg.sender] >= _value) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        /// same as above. Replace this line with the following if you want to protect against wrapping uints.
        /// if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (_value > 0 && balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_to].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    //// Approves and then calls the receiving contract
    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }
}