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
   string cliffStr;
   uint256 cliff;
   uint256 baseRatio; /* 第一個月解鎖 */
   uint256 incrRatio; /* 第二個月開始每月解鎖 */
 }
//  Rule[] public rules;
  // uint256 public ruleCount;
  mapping(string => Rule) rurus;

  uint256 public crowdsaleStart; // Crowdsale

  constructor () public {
    //rules.push(Rule(&#39;PRESALE1&#39;,  &#39;2018-12-01&#39;, 1543622400, 20, 10)); // /* 私人配售 */
    //rules.push(Rule(&#39;PRESALE2&#39;,  &#39;2019-02-01&#39;, 1548979200, 20, 10)); //
    //rules.push(Rule(&#39;PRESALE3&#39;,  &#39;2019-04-01&#39;, 1554076800, 20, 10)); //
    //rules.push(Rule(&#39;PRESALE4&#39;,  &#39;2019-06-01&#39;, 1559347200, 20, 10)); //
    //rules.push(Rule(&#39;PRESALE5&#39;,  &#39;2019-08-01&#39;, 1564617600, 20, 10)); //
    //rules.push(Rule(&#39;CROWDSALE&#39;, &#39;2019-09-01&#39;, 1567296000, 100, 0)); // /* 公開預售 */
    //rules.push(Rule(&#39;STARTUP&#39;,   &#39;2020-01-01&#39;, 1577836800, 10, 10)); // /* 創始團隊 */
    //rules.push(Rule(&#39;ANGELFUND&#39;, &#39;2019-09-01&#39;, 1567296000, 10, 10)); // /* 天始投資 */
    //rules.push(Rule(&#39;TECHTEAM&#39;,  &#39;2019-09-01&#39;, 1567296000, 10, 10)); // /* 技術平台 */
    //ruleCount = rules.length;

    crowdsaleStart = 1527897600; // &#39;2018-06-02&#39;

    //////////////////
    rurus[&#39;PRESALE1&#39;] = Rule(&#39;PRESALE1&#39;,  &#39;2018-12-01&#39;, 1543622400, 20, 10); // /* 私人配售 */
    rurus[&#39;PRESALE2&#39;] = Rule(&#39;PRESALE2&#39;,  &#39;2019-02-01&#39;, 1548979200, 20, 10); //
    rurus[&#39;PRESALE3&#39;] = Rule(&#39;PRESALE3&#39;,  &#39;2019-04-01&#39;, 1554076800, 20, 10); //
    rurus[&#39;PRESALE4&#39;] = Rule(&#39;PRESALE4&#39;,  &#39;2019-06-01&#39;, 1559347200, 20, 10); //
    rurus[&#39;PRESALE5&#39;] = Rule(&#39;PRESALE5&#39;,  &#39;2019-08-01&#39;, 1564617600, 20, 10); //
    rurus[&#39;CROWDSALE&#39;]= Rule(&#39;CROWDSALE&#39;, &#39;2019-09-01&#39;, 1567296000, 100, 0); // /* 公開預售 */
    rurus[&#39;STARTUP&#39;]  = Rule(&#39;STARTUP&#39;,   &#39;2020-01-01&#39;, 1577836800, 10, 10); // /* 創始團隊 */
    rurus[&#39;ANGELFUND&#39;]= Rule(&#39;ANGELFUND&#39;, &#39;2019-09-01&#39;, 1567296000, 10, 10); // /* 天始投資 */
    rurus[&#39;TECHTEAM&#39;] = Rule(&#39;TECHTEAM&#39;,  &#39;2019-09-01&#39;, 1567296000, 10, 10); // /* 技術平台 */
  }

  modifier validateType(string key) {
    require(bytes(rurus[key].name).length != 0);
    _;
  }

  function getRurus (string key)
  public view
  validateType(key)
  returns (
    string name,
    string cliffStr,
    uint256 cliff,
    uint256 baseRatio,
    uint256 incrRatio
  ) {
    return (
      rurus[key].name,
      rurus[key].cliffStr,
      rurus[key].cliff,
      rurus[key].baseRatio,
      rurus[key].incrRatio
    );
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









// import &#39;./JinTokenLock.sol&#39;;

// library StringUtils {
  // function equal(string _self, string _x) public pure returns (bool) {
    // return keccak256(abi.encodePacked(_self)) == keccak256(abi.encodePacked(_x));
  // }
// }

//contract JinTokenLock {
//  function getAllBalances (address user)
//    public view returns (uint[1+9]);
//}

contract JinToken is
  StandardToken,
  DetailedERC20,
  Ownable,
  JinVestingRule {
  // JinTokenLock {
  using SafeMath for uint;
  using Math for uint;
  // using StringUtils for string;

  uint public INITIAL_SUPPLY;

  mapping (address => mapping (string => uint)) private lockedAmount;
  mapping (address => mapping (string => uint)) private alreadyClaim;

  // How many token units a buyer gets per microether.
  // The rate is the conversion between
  //    microeather and
  //    the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with 5 decimals called KIM
  // 1 microether will give you 1 unit, or 0.00001 KIM.
  uint public rate;  // Crowdsale

  constructor (
    address _startup,
    address _angelfund,
    address _techteam
  )
  DetailedERC20(
    "jinyitong" /* name */,
    "JIN" /* symbol */,
    5 /* decimals */
  )
  JinVestingRule()
  public {
    INITIAL_SUPPLY = 3.14e8; // 三億一千四百萬 (314000000)
    totalSupply_ = INITIAL_SUPPLY.mul(10 ** uint(decimals)); // BasicToken
    balances[msg.sender] = totalSupply_;                       // BasicToken

    rate = 0;

    /* initial transferToLock */
    uint jins = 0;

    jins = totalSupply_.div(100).mul(20);
    _transferToLock(_startup, jins, &#39;STARTUP&#39;);

    jins = totalSupply_.div(100).mul(15);
    _transferToLock(_angelfund, jins, &#39;ANGELFUND&#39;);

    jins = totalSupply_.div(100).mul(5);
    _transferToLock(_techteam, jins, &#39;TECHTEAM&#39;);
  }

  event TransferToLock(
    address indexed to,
    uint value,
    string lockingType,
    uint totalLocked
  );

  modifier onlyOwner() {
    require(msg.sender == owner); // Ownable
    _;
  }

  /* Crowdsale */
  function () external payable {
    uint _now = getTime();
    require(_now >= crowdsaleStart);

    address user = msg.sender;
    uint jins = _getTokenAmount(msg.value);

    require(jins >= 0);

    _transferToLock(user, jins, &#39;CROWDSALE&#39;);
  }

  function _getTokenAmount(uint weiAmount) internal view returns (uint) {
    uint _microAmount = weiAmount.div(10 ** 12);
    return _microAmount.mul(rate);
  }

  function setCrowdsaleRate(uint _rate) public onlyOwner() returns (bool) {
    rate = _rate;
    return true;
  }

  function transferToLock (
    address user,
    uint amount,
    string _type
  ) public
  onlyOwner()
  validateType(_type)
  returns (bool) {
    _transferToLock(user, amount, _type);
    return true;
  }

  function _transferToLock (
    address _to,
    uint _value,
    string _type
  ) internal
  returns (bool) {
    address _from = owner;

    require(_value > 0);
    require(_value <= balances[_from]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    lockedAmount[_to][_type] = lockedAmount[_to][_type].add(_value);

    emit TransferToLock(_to, _value, _type, lockedAmount[_to][_type]);

    return true;
  }

  function claimToken (
    address user,
    string _type
  ) public
  validateType(_type)
  returns (bool) {
    uint approved = approvedRatio(_type);
    uint availableToClaim =
      lockedAmount[user][_type].mul(approved).div(100);
    uint amountToClaim = availableToClaim.sub(alreadyClaim[user][_type]);

    require (amountToClaim > 0);

    balances[user] = balances[user].add(amountToClaim);
    alreadyClaim[user][_type] = availableToClaim;

    return true;
  }

  function approvedRatio (
    string _type
  ) internal view returns (uint) {
      uint _now = getTime();
      uint cliff = rurus[_type].cliff;

      require(_now >= cliff);

      uint baseRatio = rurus[_type].baseRatio;
      uint incrRatio = rurus[_type].incrRatio;

      return Math.min256(
        100,
        _now
        .sub( cliff )
        .div( 30 days ) // a month
        .mul( incrRatio )
        .add( baseRatio )
      );
  }

  function getAllBalances (address user) public view returns (uint[1+9]) {
    uint[1+9] memory records;

    records[0] = balances[user];
    records[1] = lockedAmount[user][&#39;PRESALE1&#39;];
    records[2] = lockedAmount[user][&#39;PRESALE2&#39;];
    records[3] = lockedAmount[user][&#39;PRESALE3&#39;];
    records[4] = lockedAmount[user][&#39;PRESALE4&#39;];
    records[5] = lockedAmount[user][&#39;PRESALE5&#39;];
    records[6] = lockedAmount[user][&#39;CROWDSALE&#39;];

    records[7] = lockedAmount[user][&#39;STARTUP&#39;];
    records[8] = lockedAmount[user][&#39;ANGELFUND&#39;];
    records[9] = lockedAmount[user][&#39;TECHTEAM&#39;];

    return records;
  }

  function getTime () public view returns (uint) {
    return block.timestamp; // now
  }

  // function isStringEq(string _y, string _x) public pure returns (bool) {
    // return keccak256(abi.encodePacked(_y)) == keccak256(abi.encodePacked(_x));
  // }
}


contract HookTokenCrowdsale is
  StandardToken,
  DetailedERC20,
  Ownable {
  using SafeMath for uint;
  using Math for uint;

  JinToken public hook;

  uint public INITIAL_SUPPLY;

  constructor (
    JinToken _hook
  )
  DetailedERC20(
    "jinyitong-Crowdsale", /* name */
    "JIN", /* symbol */
    5 /* decimals */
  )
  public {
    INITIAL_SUPPLY = 0;
    totalSupply_ = INITIAL_SUPPLY.mul(10 ** uint(decimals)); // TODO
    balances[msg.sender] = totalSupply_; // TODO
    hook = _hook;
  }

  function setToken(JinToken _hook) public onlyOwner() returns (bool) {
    hook = _hook;
  }

  modifier onlyOwner() {
    require(msg.sender == owner); // Ownable
    _;
  }

  /* override */
  function transfer(address _to, uint256 _value) public onlyOwner() returns (bool) {
    return super.transfer(_to, _value);
  }

  /* override */
  function balanceOf(address _user) public view returns (uint256) {
    uint[1+9] memory records;
    records = hook.getAllBalances(_user);
    return records[6];
  }

}