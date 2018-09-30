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


contract JinVestingRule {
  struct Rule {
    string name;
    uint256 cliff;
    uint256 baseRatio; /* 第一個月解鎖 */
    uint256 incrRatio; /* 第二個月開始每月解鎖 */
  }
  Rule[] public rules;
  uint256 public ruleCount;

  uint256 public crowdsaleStart; // Crowdsale

  constructor () public {
    rules.push(Rule(&#39;PRESALE1&#39;,  1543622400, 20, 10)); // &#39;2018-12-01&#39; /* 私人配售 */
    rules.push(Rule(&#39;PRESALE2&#39;,  1548979200, 20, 10)); // &#39;2019-02-01&#39;
    rules.push(Rule(&#39;PRESALE3&#39;,  1554076800, 20, 10)); // &#39;2019-04-01&#39;
    rules.push(Rule(&#39;PRESALE4&#39;,  1559347200, 20, 10)); // &#39;2019-06-01&#39;
    rules.push(Rule(&#39;PRESALE5&#39;,  1564617600, 20, 10)); // &#39;2019-08-01&#39;
    rules.push(Rule(&#39;CROWDSALE&#39;, 1567296000, 100, 0)); // &#39;2019-09-01&#39; /* 公開預售 */
    rules.push(Rule(&#39;STARTUP&#39;,   1577836800, 10, 10)); // &#39;2020-01-01&#39; /* 創始團隊 */
    rules.push(Rule(&#39;ANGELFUND&#39;, 1567296000, 10, 10)); // &#39;2019-09-01&#39; /* 天始投資 */
    rules.push(Rule(&#39;TECHTEAM&#39;,  1567296000, 10, 10)); // &#39;2019-09-01&#39; /* 技術平台 */
    ruleCount = rules.length;

    crowdsaleStart = 1527897600; // &#39;2018-06-02&#39;
  }
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
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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




// library StringUtils {
  // function equal(string _self, string _x) public pure returns (bool) {
    // return keccak256(abi.encodePacked(_self)) == keccak256(abi.encodePacked(_x));
  // }
// }

contract JinToken is
  StandardToken,
  DetailedERC20,
  Ownable,
  JinVestingRule {
  using SafeMath for uint256;
  using Math for uint256;
  // using StringUtils for string;

  uint256 public INITIAL_SUPPLY;

  mapping (uint256 => mapping (address => uint256)) private lockedAmount;
  mapping (uint256 => mapping (address => uint256)) private alreadyClaim;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public crowdsaleRate;  // Crowdsale
  // ASSUME 300 USD/1 ETH
  // XXX: 1 gwei = 10^9 wei
  // 100 gwei = 10^11 wei => 3 jin
  // 1000 gwei = 1kgwei = 1 szabo = 1 microether = 1 muether = 30 jin ****
  // 10^16 wei = 10 milliether = 0.01 ether = 300000 jin = 3 JIN

  constructor (
    address _startup,
    address _angelfund,
    address _techteam
  )
    DetailedERC20(
      "KimVi" /* name */,
      "KIM" /* symbol */,
      5 /* decimals */
    )
    JinVestingRule()
    public {
    INITIAL_SUPPLY = 314000000; // 三億一千四百萬 (314000000)
    totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals)); // BasicToken
    balances[msg.sender] = totalSupply_;                       // BasicToken

    crowdsaleRate = 0;

    /* initial transferToLock */
    uint256 jins = 0;

    jins = totalSupply_.div(100).mul(20);
    assert(isStringEq(rules[6].name, &#39;STARTUP&#39;));
    _transferToLock(_startup, jins, 6);

    jins = totalSupply_.div(100).mul(15);
    assert(isStringEq(rules[7].name, &#39;ANGELFUND&#39;));
    _transferToLock(_angelfund, jins, 7);

    jins = totalSupply_.div(100).mul(5);
    assert(isStringEq(rules[8].name, &#39;TECHTEAM&#39;));
    _transferToLock(_techteam, jins, 8);
  }

  event TransferToLock(
    address indexed to,
    uint256 value,
    uint256 lockingType,
    uint256 totalLocked
  );

  modifier onlyOwner() {
    require(msg.sender == owner); // Ownable
    _;
  }

  modifier validate(address _address, uint256 _type) {
    require(_address != address(0));
    require(_type < ruleCount);
    _;
  }

  /* Crowdsale */
  function () external payable {
    uint256 _now = getTime();
    require(_now >= crowdsaleStart);

    address user = msg.sender;
    uint256 jins = _getTokenAmount(msg.value);
    uint256 _type = 5;

    require(jins >= 0);
    // assert(isStringEq(rules[_type].name, &#39;CROWDSALE&#39;));

    _transferToLock(user, jins, _type);
  }

  // function howManyTokens(uint256 weiAmount) public view returns (uint256) {
    // return _getTokenAmount(weiAmount);
  // }

  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    uint256 _microAmount = weiAmount.div(10 ** 12);
    return _microAmount.mul(crowdsaleRate);
  }

  function setCrowdsaleRate(uint256 _rate) public onlyOwner() returns (bool) {
    crowdsaleRate = _rate;
    return true;
  }

  function transferToLock (
    address user,
    uint256 amount,
    uint256 _type
  ) public
  validate(user, _type)
  onlyOwner()
  returns (bool) {
    _transferToLock(user, amount, _type);
    return true;
  }

  function _transferToLock (
    address user,
    uint256 amount,
    uint256 _type
  ) internal
  returns (bool) {
    address _from = owner;
    address _to = user;
    uint256 _value = amount;
    mapping (address => uint256) locked = lockedAmount[_type];

    require(0 < _value);
    require(_value <= balances[_from]);

    balances[_from] = balances[_from].sub(_value);
    locked[_to] = locked[_to].add(_value);

    emit TransferToLock(_to, _value, _type, locked[_to]);

    return true;
  }

  function claimToken (
    address user,
    uint256 _type
  ) public validate(user, _type)
  returns (bool) {
    // if (isStringEq(rules[_type].name, &#39;CROWDSALE&#39;)
      // || isStringEq(rules[_type].name, &#39;PRESALE1&#39;)
      // || isStringEq(rules[_type].name, &#39;PRESALE2&#39;)
      // || isStringEq(rules[_type].name, &#39;PRESALE3&#39;)
      // || isStringEq(rules[_type].name, &#39;PRESALE4&#39;)
      // || isStringEq(rules[_type].name, &#39;PRESALE5&#39;)
      // || isStringEq(rules[_type].name, &#39;STARTUP&#39;)) {

      uint256 approved = approvedRatio(_type);
      uint256 availableToClaim =
        lockedAmount[_type][user].mul(approved).div(100);
      uint256 amountToClaim = availableToClaim.sub(alreadyClaim[_type][user]);

      require (amountToClaim > 0);

      balances[user] = balances[user].add(amountToClaim);
      alreadyClaim[_type][user] = availableToClaim;

      return true;
    // }

    // return false;
  }

  function approvedRatio (
    uint256 _type
  ) public view returns (uint256) {
      uint256 _now = getTime();
      uint256 cliff = rules[_type].cliff;

      require(_now >= cliff);

      uint256 baseRatio = rules[_type].baseRatio;
      uint256 incrRatio = rules[_type].incrRatio;

      return Math.min256(
        100,
        _now
        .sub( cliff )
        .div( 30 days ) // a month
        .mul( incrRatio )
        .add( baseRatio )
      );
  }

  function amountInLock (address user, uint256 lockType) public view returns (uint256) {
    return lockedAmount[lockType][user].sub(alreadyClaim[lockType][user]);
  }

  function getTime () public view returns (uint256) {
    return block.timestamp; // now
  }

  function isStringEq(string _y, string _x) public pure returns (bool) {
    return keccak256(abi.encodePacked(_y)) == keccak256(abi.encodePacked(_x));
  }
}


contract JinTokenMock is JinToken {
	uint256 public time = 51;

  constructor (
    address _startup,
    address _angelfund,
    address _techteam
  ) JinToken(
    _startup,
    _angelfund,
    _techteam
  ) public {}

	function getTime () public view returns (uint256) {
		return time;
	}

	function setTime (uint256 _time) public returns (bool) {
		time = _time;
		return true;
	}
}