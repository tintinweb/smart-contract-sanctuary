pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: zeppelin-solidity/contracts/lifecycle/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  constructor() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/token/ERC223/ERC223Basic.sol

/**
 * @title ERC223Basic extends ERC20 interface and supports ERC223
 */
contract ERC223Basic is ERC20Basic {
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

// File: contracts/token/ERC223/ERC223ReceivingContract.sol

/**
 * @title ERC223ReceivingContract contract that will work with ERC223 tokens.
 */
contract ERC223ReceivingContract {
  /**
  * @dev Standard ERC223 function that will handle incoming token transfers.
  *
  * @param _from  Token sender address.
  * @param _value Amount of tokens.
  * @param _data  Transaction metadata.
  */
  function tokenFallback(address _from, uint256 _value, bytes _data) public returns (bool);
}

// File: contracts/Adminable.sol

/**
 * @title Adminable
 * @dev The Adminable contract has the simple protection logic, and provides admin based access control
 */
contract Adminable is Ownable {
	address public admin;
	event AdminDesignated(address indexed previousAdmin, address indexed newAdmin);

  /**
    * @dev Throws if called the non admin.
    */
	modifier onlyAdmin() {
		require(msg.sender == admin);
		_;
	}

  /**
    * @dev Throws if called the non owner and non admin.
    */
  modifier onlyOwnerOrAdmin() {
		require(msg.sender == owner || msg.sender == admin);
		_;
	}

  /**
    * @dev Designate new admin for the address
    * @param _address address The address you want to be a new admin
    */
	function designateAdmin(address _address) public onlyOwner {
		require(_address != address(0) && _address != owner);
		emit AdminDesignated(admin, _address);
		admin = _address;
	}
}

// File: contracts/Lockable.sol

/**
 * @title Lockable
 * @dev The Lockable contract has an locks address map, and provides lockable control
 * functions, this simplifies the implementation of "lock transfers".
 *
 */
contract Lockable is Adminable, ERC20Basic {
  using SafeMath for uint256;
  // EPOCH TIMESTAMP OF "Tue Sept 24 2019 00:00:00 GMT+0000"
  // @see https://www.unixtimestamp.com/index.php
  uint public globalUnlockTime = 1569355060;
  uint public constant decimals = 18;

  event UnLock(address indexed unlocked);
  event Lock(address indexed locked, uint until, uint256 value, uint count);
  event UpdateGlobalUnlockTime(uint256 epoch);

  struct LockMeta {
    uint256 value;
    uint until;
  }

  mapping(address => LockMeta[]) internal locksMeta;
  mapping(address => bool) locks;

  /**
    * @dev Lock tokens for the address
    * @param _address address The address you want to lock tokens
    * @param _days uint The days count you want to lock untill from now
    * @param _value uint256 the amount of tokens to be locked
    */
  function lock(address _address, uint _days, uint256 _value) onlyOwnerOrAdmin public {
    _value = _value*(10**decimals);
    require(_value > 0);
    require(_days > 0);
    require(_address != owner);
    require(_address != admin);

    uint untilTime = block.timestamp + _days * 1 days;
    locks[_address] = true;
    // check if we have locks
    locksMeta[_address].push(LockMeta(_value, untilTime));
    // fire lock event
    emit Lock(_address, untilTime, _value, locksMeta[_address].length);
  }

  /**
    * @dev Unlock tokens for the address
    * @param _address address The address you want to unlock tokens
    */
  function unlock(address _address) onlyOwnerOrAdmin public {
    locks[_address] = false;
    delete locksMeta[_address];
    emit UnLock(_address);
  }

  /**
    * @dev Gets the locked balance of the specified address and time
    * @param _owner The address to query the locked balance of.
    * @param _time The timestamp seconds to query the locked balance of.
    * @return An uint256 representing the locked amount owned by the passed address.
    */
  function lockedBalanceOf(address _owner, uint _time) public view returns (uint256) {
    LockMeta[] memory locked = locksMeta[_owner];
    uint length = locked.length;
    // if no locks or even not created (takes bdefault) return 0
    if (length == 0) {
      return 0;
    }
    // sum all available locks
    uint256 _result = 0;
    for (uint i = 0; i < length; i++) {
      if (_time <= locked[i].until) {
        _result = _result.add(locked[i].value);
      }
    }
    return _result;
  }

  /**
    * @dev Gets the locked balance of the specified address of the current time
    * @param _owner The address to query the locked balance of.
    * @return An uint256 representing the locked amount owned by the passed address.
    */
  function lockedNowBalanceOf(address _owner) public view returns (uint256) {
    return this.lockedBalanceOf(_owner, block.timestamp);
  }

  /**
    * @dev Gets the unlocked balance of the specified address and time
    * @param _owner The address to query the unlocked balance of.
    * @param _time The timestamp seconds to query the unlocked balance of.
    * @return An uint256 representing the unlocked amount owned by the passed address.
    */
  function unlockedBalanceOf(address _owner, uint _time) public view returns (uint256) {
    return this.balanceOf(_owner).sub(lockedBalanceOf(_owner, _time));
  }

  /**
    * @dev Gets the unlocked balance of the specified address of the current time
    * @param _owner The address to query the unlocked balance of.
    * @return An uint256 representing the unlocked amount owned by the passed address.
    */
  function unlockedNowBalanceOf(address _owner) public view returns (uint256) {
    return this.unlockedBalanceOf(_owner, block.timestamp);
  }

  function updateGlobalUnlockTime(uint256 _epoch) public onlyOwnerOrAdmin returns (bool) {
    require(_epoch >= 0);
    globalUnlockTime = _epoch;
    emit UpdateGlobalUnlockTime(_epoch);
    // Gives owner the ability to update lockup period for all wallets.
    // Owner can pass an epoch timecode into the function to:
    // 1. Extend lockup period,
    // 2. Unlock all wallets by passing &#39;0&#39; into the function
  }

  /**
    * @dev Throws if the value less than the current unlocked balance of.
    */
  modifier onlyUnlocked(uint256 _value) {
    if(block.timestamp > globalUnlockTime) {
      _;
    } else {
      if (locks[msg.sender] == true) {
        require(this.unlockedNowBalanceOf(msg.sender) >= _value);
      }
      _;
    }
  }

  /**
    * @dev Throws if the value less than the current unlocked balance of the given address.
    */
  modifier onlyUnlockedOf(address _address, uint256 _value) {
    if(block.timestamp > globalUnlockTime) {
      _;
    } else {
      if (locks[_address] == true) {
        require(this.unlockedNowBalanceOf(_address) >= _value);
      } else {

      }
      _;
    }
  }
}

// File: contracts/StandardLockableToken.sol

/**
 * @title StandardLockableToken
 *
 */
contract StandardLockableToken is Lockable, /**/ERC223Basic, /*ERC20*/StandardToken {

  /**
    * @dev Check address is to be a contract based on extcodesize (must be nonzero to be a contract)
    * @param _address The address to check.
    */
  function isContract(address _address) private constant returns (bool) {
    uint256 codeLength;
    assembly {
      codeLength := extcodesize(_address)
    }
    return codeLength > 0;
  }

  /**
    * @dev Transfer token for a specified address
    * ERC20 support
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
  function transfer(address _to, uint256 _value) onlyUnlocked(_value) public returns (bool) {
    bytes memory empty;
    return _transfer(_to, _value, empty);
  }

  /**
    * @dev Transfer token for a specified address
    * ERC223 support
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The additional data.
    */
  function transfer(address _to, uint256 _value, bytes _data) onlyUnlocked(_value) public returns (bool) {
    return _transfer(_to, _value, _data);
  }

  /**
    * @dev Transfer token for a specified address
    * ERC223 support
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The additional data.
    */
  function _transfer(address _to, uint256 _value, bytes _data) internal returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value > 0);
    // catch overflow loosing tokens
    // require(balances[_to] + _value > balances[_to]);

    // safety update balances
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    // determine if the contract given
    if (isContract(_to)) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, _data);
    }

    // emit ERC20 transfer event
    emit Transfer(msg.sender, _to, _value);
    // emit ERC223 transfer event
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
  function transferFrom(address _from, address _to, uint256 _value) onlyUnlockedOf(_from, _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_value > 0);

    // make balances manipulations first
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    bytes memory empty;
    if (isContract(_to)) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, empty);
    }

    // emit ERC20 transfer event
    emit Transfer(_from, _to, _value);
    // emit ERC223 transfer event
    emit Transfer(_from, _to, _value, empty);
    return true;
  }
}

// File: contracts/StandardBurnableLockableToken.sol

/**
 * @title StandardBurnableLockableToken
 *
 */
contract StandardBurnableLockableToken is StandardLockableToken, BurnableToken {
  /**
    * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param _from address The address which you want to send tokens from
    * @param _value uint256 The amount of token to be burned
    */
  function burnFrom(address _from, uint256 _value) onlyOwner onlyUnlockedOf(_from, _value) public {
    require(_value <= allowed[_from][msg.sender]);
    require(_value > 0);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    _burn(_from, _value);

    bytes memory empty;
    // emit ERC223 transfer event also
    emit Transfer(msg.sender, address(0), _value, empty);
  }

  /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
  function burn(uint256 _value) onlyOwner onlyUnlocked(_value) public {
    require(_value > 0);
    _burn(msg.sender, _value);

    bytes memory empty;
      // emit ERC223 transfer event also
    emit Transfer(msg.sender, address(0), _value, empty);
  }
}


contract EngageToken is StandardBurnableLockableToken, Destructible {
  string public constant name = "Engage";
	uint public constant decimals = 18;
	string public constant symbol = "NGAGE";

  constructor() public {
    // set the owner
    owner = msg.sender;
    admin = 0x613b42D781c59237fb51c304A5b037cDDD0dC48c;

    uint256 INITIAL_SUPPLY = 1000000000 * (10**decimals);

    totalSupply_ = INITIAL_SUPPLY;

    bytes memory empty;

    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY, empty);
  }
}