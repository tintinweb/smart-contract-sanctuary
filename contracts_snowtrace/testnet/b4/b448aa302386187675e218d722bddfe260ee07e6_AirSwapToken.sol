/**
 *Submitted for verification at Etherscan.io on 2017-10-10
*/

pragma solidity ^0.4.11;

// See the Github at github.com/airswap/contracts

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances; // *added public
    mapping (address => mapping (address => uint256)) public allowed; // *added public
}




/** @title The AirSwap Token
  * An ERC20-compliant token that is only transferable after a
  * specified time. Holders also have the ability to lock an amount of tokens
  * for a period of time for applications that reference this locked amount
  * for example for licensing features.
  */
contract AirSwapToken is StandardToken, Pausable {

    string public constant name = "AirSwap Token";
    string public constant symbol = "AST";
    uint8 public constant decimals = 4;
    uint256 public constant totalSupply = 5000000000000;

    // The time after which AirSwap tokens become transferable.
    // Current value is October 17, 2017 10:10:10 Eastern Time.
    uint256 becomesTransferable = 1508249410;

    // The time that tokens are to be locked before becoming unlockable.
    // Current value is 7 days.
    uint256 lockingPeriod = 604800;

    // Prevents premature execution.
    modifier onlyAfter(uint256 _time) {
        require(now >= _time);
        _;
    }

    // Prevent premature execution for anyone but the owner.
    modifier onlyAfterOrOwner(uint256 _time, address _from) {
        if (_from != owner) {
            require(now >= _time);
        }
        _;
    }

    // Holds the amount and date of a given balance lock.
    struct BalanceLock {
        uint256 amount;
        uint256 unlockDate;
    }

    // A mapping of balance lock to a given address.
    mapping (address => BalanceLock) public balanceLocks;

    // An event to notify that _owner has locked a balance.
    event BalanceLocked(address indexed _owner, uint256 _oldLockedAmount,
    uint256 _newLockedAmount, uint256 _expiry);

    /** @dev Constructor for the contract.
      * @param _deployer The address that will initially hold all tokens.
      * @param _owner The address that will be able to transfer early.
      * @param _balance The initial balance for the owner.
      */
    function AirSwapToken(address _deployer, address _owner, uint256 _balance)
        Pausable() {
        transferOwnership(_owner);
        balances[_deployer] = totalSupply - _balance;
        balances[_owner] = _balance;
        Transfer(0x0, _deployer, totalSupply);
        Transfer(_deployer, _owner, _balance);
    }

    /** @dev Sets a token balance to be locked by the sender, on the condition
      * that the amount is equal or greater than the previous amount, or if the
      * previous lock time has expired.
      * @param _value The amount be locked.
      */
    function lockBalance(uint256 _value) {

        // Check if the lock on previously locked tokens is still active.
        if (balanceLocks[msg.sender].unlockDate > now) {
            // Only allow confirming the lock or adding to it.
            require(_value >= balanceLocks[msg.sender].amount);
        }
        // Ensure that no more than the balance can be locked.
        require(balances[msg.sender] >= _value);

        // Lock tokens and notify.
        uint256 _expiry = now + lockingPeriod;
        BalanceLocked(msg.sender, balanceLocks[msg.sender].amount, _value, _expiry);
        balanceLocks[msg.sender] = BalanceLock(_value, _expiry);
    }

    /** @dev Returns the balance that a given address has available for transfer.
      * @param _owner The address of the token owner.
      */
    function availableBalance(address _owner) constant returns(uint256) {
        if (balanceLocks[_owner].unlockDate < now) {
            return balances[_owner];
        } else {
            assert(balances[_owner] >= balanceLocks[_owner].amount);
            return balances[_owner] - balanceLocks[_owner].amount;
        }
    }

    /** @dev Send `_value` token to `_to` from `msg.sender`, on the condition
      * that there are enough unlocked tokens in the `msg.sender` account.
      * @param _to The address of the recipient.
      * @param _value The amount of token to be transferred.
      * @return Whether the transfer was successful or not.
      */
    function transfer(address _to, uint256 _value)
        onlyAfter(becomesTransferable) whenNotPaused
        returns (bool success) {
        require(availableBalance(msg.sender) >= _value);
        return super.transfer(_to, _value);
    }

    /** @dev Send `_value` token to `_to` from `_from` on the condition
      * that there are enough unlocked tokens in the `_from` account.
      * @param _from The address of the sender.
      * @param _to The address of the recipient.
      * @param _value The amount of token to be transferred.
      * @return Whether the transfer was successful or not.
      */
    function transferFrom(address _from, address _to, uint256 _value)
        onlyAfterOrOwner(becomesTransferable, _from) whenNotPaused
        returns (bool success) {
        require(availableBalance(_from) >= _value);
        return super.transferFrom(_from, _to, _value);
    }
}