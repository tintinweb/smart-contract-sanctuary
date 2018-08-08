pragma solidity ^0.4.16;

/**
 * @title Provides overflow safe arithmetic
 */
library SafeMath {

    /**
     * @dev Does subtract in safe manner
     *
     * @return result of (_subtrahend - _subtractor) or 0 if overflow occurs
     */
    function sub(uint256 _subtrahend, uint256 _subtractor) internal returns (uint256) {

        // overflow check
        if (_subtractor > _subtrahend)
            return 0;

        return _subtrahend - _subtractor;
    }
}

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

/**
 * @title Drives Cat&#39;s Token ICO
 */
contract CatICO {

    using SafeMath for uint256;

    /// Starts at 21 Sep 2017 05:00:00 UTC
    uint256 public start = 1505970000;
    /// Ends at 21 Nov 2017 05:00:00 UTC
    uint256 public end = 1511240400;

    /// Keeps supplied ether
    address public wallet;

    /// Cat&#39;s Token
    Cat public cat;

    struct Stage {
        /* price in weis for one milliCTS */
        uint256 price;
        /* supply cap in milliCTS */
        uint256 cap;
    }

    /* Stage 1: Cat Simulator */
    Stage simulator = Stage(0.01 ether / 1000, 900000000);
    /* Stage 2: Cats Online */
    Stage online = Stage(0.0125 ether / 1000, 2500000000);
    /* Stage 3: Cat Sequels */
    Stage sequels = Stage(0.016 ether / 1000, 3750000000);

    /**
     * @dev Cat&#39;s ICO constructor. It spawns a Cat contract.
     *
     * @param _wallet the address of the ICO wallet
     */
    function CatICO(address _wallet) {
        cat = new Cat();
        wallet = _wallet;
    }

    /**
     * @dev Fallback function, works only if ICO is running
     */
    function() payable onlyRunning {

        var supplied = cat.totalSupply();
        var tokens = tokenEmission(msg.value, supplied);

        // revert if nothing to emit
        require(tokens > 0);

        // emit tokens
        bool success = cat.emit(tokens);
        assert(success);

        // transfer new tokens to its owner
        success = cat.transfer(msg.sender, tokens);
        assert(success);

        // send value to the wallet
        wallet.transfer(msg.value);
    }

    /**
     * @dev Calculates number of tokens to emit
     *
     * @param _value received ETH
     * @param _supplied tokens qty supplied at the moment
     * @return tokens count which is accepted for emission
     */
    function tokenEmission(uint256 _value, uint256 _supplied) private returns (uint256) {

        uint256 emission = 0;
        uint256 stageTokens;

        Stage[3] memory stages = [simulator, online, sequels];

        /* Stage 1 and 2 */
        for (uint8 i = 0; i < 2; i++) {
            (stageTokens, _value, _supplied) = stageEmission(_value, _supplied, stages[i]);
            emission += stageTokens;
        }

        /* Stage 3, spend remainder value */
        emission += _value / stages[2].price;

        return emission;
    }

    /**
     * @dev Calculates token emission in terms of given stage
     *
     * @param _value consuming ETH value
     * @param _supplied tokens qty supplied within tokens supplied for prev stages
     * @param _stage the stage
     *
     * @return tokens emitted in the stage, returns 0 if stage is passed or not enough _value
     * @return valueRemainder the value remaining after emission in the stage
     * @return newSupply total supplied tokens after emission in the stage
     */
    function stageEmission(uint256 _value, uint256 _supplied, Stage _stage)
        private
        returns (uint256 tokens, uint256 valueRemainder, uint256 newSupply)
    {

        /* Check if there is space left in the stage */
        if (_supplied >= _stage.cap) {
            return (0, _value, _supplied);
        }

        /* Check if there is enough value for at least one milliCTS */
        if (_value < _stage.price) {
            return (0, _value, _supplied);
        }

        /* Potential emission */
        var _tokens = _value / _stage.price;

        /* Adjust to the space left in the stage */
        var remainder = _stage.cap.sub(_supplied);
        _tokens = _tokens > remainder ? remainder : _tokens;

        /* Update value and supply */
        var _valueRemainder = _value.sub(_tokens * _stage.price);
        var _newSupply = _supplied + _tokens;

        return (_tokens, _valueRemainder, _newSupply);
    }

    /**
     * @dev Checks if ICO is still running
     *
     * @return true if ICO is running, false otherwise
     */
    function isRunning() constant returns (bool) {

        /* Timeframes */
        if (now < start) return false;
        if (now >= end) return false;

        /* Total cap, held by Stage 3 */
        if (cat.totalSupply() >= sequels.cap) return false;

        return true;
    }

    /**
     * @dev Validates ICO timeframes and total cap
     */
    modifier onlyRunning() {

        /* Check timeframes */
        require(now >= start);
        require(now < end);

        /* Check Stage 3 cap */
        require(cat.totalSupply() < sequels.cap);

        _;
    }
}