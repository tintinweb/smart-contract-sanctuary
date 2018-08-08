pragma solidity ^0.4.16;


/**
 * @title Contract owner definition
 */
contract Owned {

    /* Owner&#39;s address */
    address owner;

    /**
     * @dev Constructor, records msg.sender as contract owner
     */
    function Owned() {
        owner = msg.sender;
    }

    /**
     * @dev Validates if msg.sender is an owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

/** 
 * @title Standard token interface (ERC 20)
 * 
 * https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
    
// Functions:
    
    /**
     * @return total amount of tokens
     */
    function totalSupply() constant returns (uint256);

    /** 
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) constant returns (uint256);

    /** 
     * @notice send `_value` token to `_to` from `msg.sender`
     * 
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) returns (bool);

    /** 
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * 
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

    /** 
     * @notice `msg.sender` approves `_addr` to spend `_value` tokens
     * 
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of wei to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) returns (bool);

    /** 
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) constant returns (uint256);

// Events:

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title Implementation of ERC 20 interface with holders list
 */
contract Token is ERC20 {

    /// Name of the token
    string public name;
    /// Token symbol
    string public symbol;

    /// Fixed point description
    uint8 public decimals;

    /// Qty of supplied tokens
    uint256 public totalSupply;

    /// Token holders list
    address[] public holders;
    /* address => index in array of hodlers, index starts from 1 */
    mapping(address => uint256) index;

    /* Token holders map */
    mapping(address => uint256) balances;
    /* Token transfer approvals */
    mapping(address => mapping(address => uint256)) allowances;

    /**
     * @dev Constructs Token with given `_name`, `_symbol` and `_decimals`
     */
    function Token(string _name, string _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
     * @dev Get balance of given address
     *
     * @param _owner The address to request balance from
     * @return The balance
     */
    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Transfer own tokens to given address
     * @notice send `_value` token to `_to` from `msg.sender`
     *
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) returns (bool) {

        // balance check
        if (balances[msg.sender] >= _value) {

            // transfer
            balances[msg.sender] -= _value;
            balances[_to] += _value;

            // push new holder if _value > 0
            if (_value > 0 && index[_to] == 0) {
                index[_to] = holders.push(_to);
            }

            Transfer(msg.sender, _to, _value);

            return true;
        }

        return false;
    }

    /**
     * @dev Transfer tokens between addresses using approvals
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {

        // approved balance check
        if (allowances[_from][msg.sender] >= _value &&
            balances[_from] >= _value ) {

            // hit approved amount
            allowances[_from][msg.sender] -= _value;

            // transfer
            balances[_from] -= _value;
            balances[_to] += _value;

            // push new holder if _value > 0
            if (_value > 0 && index[_to] == 0) {
                index[_to] = holders.push(_to);
            }

            Transfer(_from, _to, _value);

            return true;
        }

        return false;
    }

    /**
     * @dev Approve token transfer with specific amount
     * @notice `msg.sender` approves `_addr` to spend `_value` tokens
     *
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of wei to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) returns (bool) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Get amount of tokens approved for transfer
     *
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowances[_owner][_spender];
    }

    /**
     * @dev Convenient way to reset approval for given address, not a part of ERC20
     *
     * @param _spender the address
     */
    function unapprove(address _spender) {
        allowances[msg.sender][_spender] = 0;
    }

    /**
     * @return total amount of tokens
     */
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

    /**
     * @dev Returns count of token holders
     */
    function holderCount() constant returns (uint256) {
        return holders.length;
    }
}


/**
 * @title Cat&#39;s Token, miaow!!!
 *
 * @dev Defines token with name "Cat&#39;s Token", symbol "CTS"
 * and 3 digits after the point
 */
contract Cat is Token("Cat&#39;s Token", "CTS", 3), Owned {

    /**
     * @dev Emits specified number of tokens. Only owner can emit.
     * Emitted tokens are credited to owner&#39;s account
     *
     * @param _value number of emitting tokens
     * @return true if emission succeeded, false otherwise
     */
    function emit(uint256 _value) onlyOwner returns (bool) {

        // overflow check
        assert(totalSupply + _value >= totalSupply);

        // emission
        totalSupply += _value;
        balances[owner] += _value;

        return true;
    }
}