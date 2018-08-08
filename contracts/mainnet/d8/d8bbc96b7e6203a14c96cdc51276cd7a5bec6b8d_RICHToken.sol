pragma solidity ^0.4.6;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {

    // The address of the account that is the current owner
    address public owner;

    // The publiser is the inital owner
    function Owned() {
        owner = msg.sender;
    }

    /**
     * Restricted access to the current owner
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
 * @title RICH token
 *
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20 with the addition
 * of ownership, a lock and issuing.
 *
 * #created 05/03/2017
 * #author Frank Bonnet
 */
contract RICHToken is Owned, Token {

    using SafeMath for uint256;

    // Ethereum token standaard
    string public standard = "Token 0.1";

    // Full name
    string public name = "RICH";

    // Symbol
    string public symbol = "RICH";

    // No decimal points
    uint8 public decimals = 8;

    // Token starts if the locked state restricting transfers
    bool public locked;

    uint256 public crowdsaleStart; // Reference to time of first crowd sale
    uint256 public icoPeriod = 10 days;
    uint256 public noIcoPeriod = 10 days;
    mapping (address => mapping (uint256 => uint256)) balancesPerIcoPeriod;

    uint256 public burnPercentageDefault = 1; // 0.01%
    uint256 public burnPercentage10m = 5; // 0.05%
    uint256 public burnPercentage100m = 50; // 0.5%
    uint256 public burnPercentage1000m = 100; // 1%

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
     * Get burning line. All investors that own less than burning line
     * will lose some tokens if they don&#39;t invest each round 20% more tokens
     *
     * @return burnLine
     */
    function getBurnLine() returns (uint256 burnLine) {
        if (totalSupply < 10**7 * 10**8) {
            return totalSupply * burnPercentageDefault / 10000;
        }

        if (totalSupply < 10**8 * 10**8) {
            return totalSupply * burnPercentage10m / 10000;
        }

        if (totalSupply < 10**9 * 10**8) {
            return totalSupply * burnPercentage100m / 10000;
        }

        return totalSupply * burnPercentage1000m / 10000;
    }

    /**
     * Return ICO number (PreIco has index 0)
     *
     * @return ICO number
     */
    function getCurrentIcoNumber() returns (uint256 icoNumber) {
        uint256 timeBehind = now - crowdsaleStart;

        if (now < crowdsaleStart) {
            return 0;
        }

        return 1 + ((timeBehind - (timeBehind % (icoPeriod + noIcoPeriod))) / (icoPeriod + noIcoPeriod));
    }

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
     * Start of the crowd sale can be set only once
     *
     * @param _start start of the crowd sale
     */
    function setCrowdSaleStart(uint256 _start) onlyOwner {
        if (crowdsaleStart > 0) {
            return;
        }

        crowdsaleStart = _start;
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

        balancesPerIcoPeriod[_to][getCurrentIcoNumber()] = balances[_to];
        balancesPerIcoPeriod[msg.sender][getCurrentIcoNumber()] = balances[msg.sender];
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

        balancesPerIcoPeriod[_to][getCurrentIcoNumber()] = balances[_to];
        balancesPerIcoPeriod[_from][getCurrentIcoNumber()] = balances[_from];
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

    /**
     * Starts with a total supply of zero and the creator starts with
     * zero tokens (just like everyone else)
     */
    function RICHToken() {
        balances[msg.sender] = 0;
        totalSupply = 0;
        locked = false;
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
     * Restricted access to the current owner
     */
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    /**
     * Issues `_value` new tokens to `_recipient`
     *
     * @param _recipient The address to which the tokens will be issued
     * @param _value The amount of new tokens to issue
     * @return Whether the approval was successful or not
     */
    function issue(address _recipient, uint256 _value) onlyOwner returns (bool success) {

        // Create tokens
        balances[_recipient] += _value;
        totalSupply += _value;

        balancesPerIcoPeriod[_recipient][getCurrentIcoNumber()] = balances[_recipient];

        return true;
    }

    /**
     * Check if investor has invested enough to avoid burning
     *
     * @param _investor Investor
     * @return Whether investor has invested enough or not
     */
    function isIncreasedEnough(address _investor) returns (bool success) {
        uint256 currentIcoNumber = getCurrentIcoNumber();

        if (currentIcoNumber - 2 < 0) {
            return true;
        }

        uint256 currentBalance = balances[_investor];
        uint256 icosBefore = balancesPerIcoPeriod[_investor][currentIcoNumber - 2];

        if (icosBefore == 0) {
            for(uint i = currentIcoNumber; i >= 2; i--) {
                icosBefore = balancesPerIcoPeriod[_investor][i-2];

                if (icosBefore != 0) {
                    break;
                }
            }
        }

        if (currentBalance < icosBefore) {
            return false;
        }

        if (currentBalance - icosBefore > icosBefore * 12 / 10) {
            return true;
        }

        return false;
    }

    /**
     * Function that everyone can call and burn for other tokens if they can
     * be burned. In return, 10% of burned tokens go to executor of function
     *
     * @param _investor Address of investor which tokens are subject of burn
     */
    function burn(address _investor) public {

        uint256 burnLine = getBurnLine();

        if (balances[_investor] > burnLine || isIncreasedEnough(_investor)) {
            return;
        }

        uint256 toBeBurned = burnLine - balances[_investor];
        if (toBeBurned > balances[_investor]) {
            toBeBurned = balances[_investor];
        }

        // 10% for executor
        uint256 executorReward = toBeBurned / 10;

        balances[msg.sender] = balances[msg.sender].add(executorReward);
        balances[_investor] = balances[_investor].sub(toBeBurned);
        totalSupply = totalSupply.sub(toBeBurned - executorReward);
        Burn(_investor, toBeBurned);
    }

    event Burn(address indexed burner, uint indexed value);

    /**
     * Prevents accidental sending of ether
     */
    function () {
        throw;
    }
}