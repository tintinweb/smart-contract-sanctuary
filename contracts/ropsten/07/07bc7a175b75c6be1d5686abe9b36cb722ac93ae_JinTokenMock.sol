pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}



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












/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

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
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}





/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



/* Inheritance:
 *
 * * [JinToken]
 *    * [StandardToken]
 *        * [BasicToken]
 *        * [ERC20]
 *            * [ERC20Basic]
 *    * [Ownable]
 */
contract JinToken is StandardToken, Ownable {
  using SafeMath for uint256;
  using Math for uint256;

  /* Unique identify for our token */
  string public name = "JINYITONG";
  string public symbol = "JIN";
  /* The degree to which this token can be subdivided */
  uint8 public decimals = 5;
  /* The number of tokens created when this contract
   * is deployed */
  uint256 public INITIAL_SUPPLY =
    314000000
  * (10 ** uint256(decimals));
  // 三億一千四百萬 (314000000)

  enum LockingType {
    PRESALE1, PRESALE2, PRESALE3, PRESALE4, PRESALE5,
    CROWDSALE,
    STARTUP, ANGELFUND, TECHTEAM,
    COUNT
  }

  mapping (uint256 => mapping (address => uint256)) private lockedAmount;
  mapping (uint256 => mapping (address => uint256)) private alreadyClaim;

  mapping (uint256 => uint256) private cliffs;
  // uint256 baseRatio;
  // uint256 incrRatio;
  uint256 fullRatio = 100;
  uint256 aMonth = 30 days;

  constructor () public {
    /* StandardToken.sol :
     *    mapping(address => uint256) balances;
     *    uint256 totalSupply_;
     */
    balances[msg.sender] = INITIAL_SUPPLY;
    totalSupply_ = INITIAL_SUPPLY;

    cliffs[uint256(LockingType.PRESALE1)] = 1543622400; // &#39;2018-12-01&#39;
    cliffs[uint256(LockingType.PRESALE2)] = 1548979200; // &#39;2019-02-01&#39;
    cliffs[uint256(LockingType.PRESALE3)] = 1554076800; // &#39;2019-04-01&#39;
    cliffs[uint256(LockingType.PRESALE4)] = 1559347200; // &#39;2019-06-01&#39;
    cliffs[uint256(LockingType.PRESALE5)] = 1564617600; // &#39;2019-08-01&#39;
    cliffs[uint256(LockingType.CROWDSALE)] = 1567296000; // &#39;2019-09-01&#39;
    cliffs[uint256(LockingType.STARTUP)] = 1577836800; // &#39;2020-01-01&#39;
    cliffs[uint256(LockingType.ANGELFUND)] = 1567296000; // &#39;2019-09-01&#39;
    cliffs[uint256(LockingType.TECHTEAM)] = 1567296000; // &#39;2019-09-01&#39;

    // cliffs[2] = 1543622400; // &#39;2018-12-01&#39; // presale: stage 1
    // cliffs[3] = 1548979200; // &#39;2019-02-01&#39; // presale: stage 2
    // cliffs[4] = 1554076800; // &#39;2019-04-01&#39; // presale: stage 3
    // cliffs[5] = 1559347200; // &#39;2019-06-01&#39; // presale: stage 4
    // cliffs[6] = 1564617600; // &#39;2019-08-01&#39; // presale: stage 5
    // cliffs[1] = 1567296000; // &#39;2019-09-01&#39; // crowdsale
    // cliffs[11] = 1577836800; // &#39;2020-01-01&#39; // startup team
    // cliffs[12] = 1567296000; // &#39;2019-09-01&#39; // angel fund
    // cliffs[13] = 1567296000; // &#39;2019-09-01&#39; // tech team
  }

  event TransferToLock(
    address indexed from,
    address indexed to,
    uint256 value,
    uint256 lockingType,
    uint256 totalLocked
  );

  modifier hasTransferToLockPermission() {
    require(msg.sender == owner);
    _;
  }

  function transferToLock (
    address receiver,
    uint256 amount,
    uint256 lockingType
  ) public hasTransferToLockPermission returns (bool) {
    address _from = msg.sender;
    address _to = receiver;
    uint256 _value = amount;
    mapping (address => uint256) locked = lockedAmount[lockingType];

    // require(lockingType >= 1);
    // require(lockingType <= 2);
    require(lockingType < uint256(LockingType.COUNT));

    balances[_from] = balances[_from].sub(_value);
    locked[_to] = locked[_to].add(_value);

    emit TransferToLock(_from, _to, _value, lockingType, locked[_to]);

    return true;

    //if (lockType == 1) { // crowdSale Lock
    //  balances[_from] = balances[_from].sub(amount);
    //  lockedAmount[1][receiver] = lockedAmount[1][receiver].add(amount);
    //  return true;
    //}

    //if (lockType == 2) { // private sale round 1
    //  balances[_from] = balances[_from].sub(amount);
    //  lockedAmount[2][receiver] = lockedAmount[2][receiver].add(amount);
    //  return true;
    //}

    // return false;
  }

  function claimToken (address user, uint256 lockingType) public returns (bool) {
    uint256 _now = getTime();
    uint256 _cliff = cliffs[lockingType];

    require(lockingType < uint256(LockingType.COUNT));
    require(_now >= _cliff);

    if (lockingType == uint256(LockingType.CROWDSALE)) {
      require (amountInLock(user, lockingType) > 0);
      balances[user] = balances[user].add(lockedAmount[lockingType][user]);
      alreadyClaim[lockingType][user] = lockedAmount[lockingType][user];
      return true;
    } else if (lockingType == uint256(LockingType.PRESALE1)
      || lockingType == uint256(LockingType.PRESALE2)
      || lockingType == uint256(LockingType.PRESALE3)
      || lockingType == uint256(LockingType.PRESALE4)
      || lockingType == uint256(LockingType.PRESALE5)) {
      uint256 approved = approvedRatio(_now, _cliff, 20, 10);
      uint256 availableToClaim =
        lockedAmount[lockingType][user].mul(approved).div(fullRatio);
      uint256 amountToClaim = availableToClaim.sub(alreadyClaim[lockingType][user]);
      require (amountToClaim > 0);

      balances[user] = balances[user].add(amountToClaim);
      alreadyClaim[lockingType][user] = availableToClaim;

      return true;
    }

    return false;
  }

  function approvedRatio (
    uint256 _now,
    uint256 _cliff,
    uint256 baseRatio,
    uint256 incrRatio
  ) public view returns (uint256) {
      baseRatio = 20;
      incrRatio = 10;
      return Math.min256(
        fullRatio,
        _now
        .sub( _cliff )
        .div( aMonth )
        .mul( incrRatio )
        .add( baseRatio )
      );
  }

  function amountInLock (address user, uint256 lockType) public view returns (uint256) {
    return lockedAmount[lockType][user].sub(alreadyClaim[lockType][user]);
  }

  function getTime () public view returns (uint256) {
    return now;
  }

  function getLockingTypeCount () public pure returns (uint256) {
    return uint256(LockingType.COUNT);
  }
}

contract JinTokenMock is JinToken {
	uint256 public time = 10;

	function getTime () public view returns (uint256) {
		return time;
	}

	function setTime (uint256 _time) public returns (bool) {
		time = _time;
		return true;
	}
}