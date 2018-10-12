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

contract BouncyCoinSelfdrop is StandardToken {

  string public name = &#39;BouncyCoinToken&#39;;
  string public symbol = &#39;BOUNCY&#39;;
  uint8 public decimals = 18;

  // Total Supply: 15,000,000,000
  uint256 public constant MAX_TOKENS_SOLD = 15000000000 * 10**18;

  event TokensSold(address buyer, uint256 tokensAmount, uint256 ethAmount);

  // Token Price: 0.0000001 ETH = 1 BOUNCY <=> 1 ETH = 10,000,000 Million BOUNCY
  uint256 public constant PRICE = 0.0000001 * 10**18;

  address public owner;

  address public wallet;

  uint256 public tokensSold;

  ERC20 public bouncyCoinToken;

  uint256 public softCap = 250; // units in ETH
  uint256 public hardCap = 500; // units in ETH

  // Unix time values taken from https://www.unixtimestamp.com/
  // October 12-16, 2018
  // 1539302400 Is equivalent to: 10/12/2018 @ 12:00am (UTC)
  uint oct_12 = 1539302400;

  // October 17-21, 2018
  // 1539734400 Is equivalent to: 10/17/2018 @ 12:00am (UTC)
  uint oct_17 = 1539734400;

  // October 22-31, 2018
  // 1540166400 Is equivalent to: 10/22/2018 @ 12:00am (UTC)
  uint oct_22 = 1540166400;

  // 1541030400 Is equivalent to: 11/01/2018 @ 12:00am (UTC)
  // ** END TIME **
  uint nov_01 = 1541030400;

  // Round Multipliers
  uint256 public multiplier;
  uint256 public first_Round = 50; //  50 % Bonus
  uint256 public second_Round = 30; //  30 % Bonus
  uint256 public third_Round = 10; //  10 % Bonus

  uint256 public first_Round_smaller = 40; //  40 % Bonus
  uint256 public second_Round_smaller = 20; //  20 % Bonus
  uint256 public third_Round_smaller = 0; //  No Bonus

  /* Current stage */
  Stages public stage;

  enum Stages {
    Deployed,
    Started,
    Ended
  }

  /* Modifiers */

  modifier atStage(Stages _stage) {
    require(stage == _stage);
    _;
  }

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  /* Multiplier depends on money user will spend. */

  modifier multiply() {
    require(msg.value > 0);
    if (now > nov_01) {
      finalize();
    } else if (now > oct_22) {
      if (msg.value >= 1)
        multiplier = third_Round;
      else
        multiplier = third_Round_smaller;
    } else if (now > oct_17) {
      if (msg.value >= 1)
        multiplier = second_Round;
      else
        multiplier = second_Round_smaller;
    } else if (now > oct_12) {
      if (msg.value >= 1)
        multiplier = first_Round;
      else
        multiplier = first_Round_smaller;
    } else {
      //revert();

      if (msg.value >= 1)
        multiplier = first_Round;
      else
        multiplier = first_Round_smaller;

    }
    _;
  }

  /* Constructor */
  function x_constructor(address _wallet)
    public {
    require(_wallet != 0x0);

    owner = msg.sender;
    wallet = _wallet;

    totalSupply_ = MAX_TOKENS_SOLD;
    balances[msg.sender] = totalSupply_;
    stage = Stages.Deployed;
  }

  /* Constructor */
  constructor()
    public {

    owner = msg.sender;
    wallet = owner;

    totalSupply_ = MAX_TOKENS_SOLD;
    balances[msg.sender] = totalSupply_;
    stage = Stages.Deployed;
  }

  /* Public functions */

  function()
    public
    multiply
    payable {
    if (stage == Stages.Started) {
      buyTokens();
    } else {
      revert();
    }
  }

  function buyTokens()
    public
    multiply
    payable
    atStage(Stages.Started) {
    require(msg.value > 0);

    uint256 amountRemaining = msg.value;

    uint256 tokensAvailable = MAX_TOKENS_SOLD - tokensSold;
    uint256 maxTokensByAmount = amountRemaining * 10**18 / PRICE;

    // adjust for bonus period
    maxTokensByAmount = maxTokensByAmount + maxTokensByAmount * multiplier;

    uint256 tokensToReceive = 0;
    if (maxTokensByAmount > tokensAvailable) {
      tokensToReceive = tokensAvailable;
      amountRemaining -= (PRICE * tokensToReceive) / 10**18;
    } else {
      tokensToReceive = maxTokensByAmount;
      amountRemaining = 0;
    }
    tokensSold += tokensToReceive;

    assert(tokensToReceive > 0);
    assert(transfer(msg.sender, tokensToReceive));

    if (amountRemaining != 0) {
      msg.sender.transfer(amountRemaining);
    }

    uint256 amountAccepted = msg.value - amountRemaining;
    wallet.transfer(amountAccepted);

    if (tokensSold == MAX_TOKENS_SOLD) {
      finalize();
    }

    emit TokensSold(msg.sender, tokensToReceive, amountAccepted);
  }

  function start()
    public
    isOwner {
    stage = Stages.Started;
  }

  function stop()
    public
    isOwner {
    finalize();
  }

  function finalize()
    private {
    stage = Stages.Ended;
  }

  // In case of accidental ether lock on contract
  function withdraw()
    public
    isOwner {
    owner.transfer(address(this).balance);
  }

  // In case of accidental token transfer to this address, owner can transfer it elsewhere
  function transferERC20Token(address _tokenAddress, address _to, uint256 _value)
    public
    isOwner {
    ERC20 token = ERC20(_tokenAddress);
    assert(token.transfer(_to, _value));
  }

  /**
    Allow the admin to burn tokens
  */
  function burn(uint256 _value) isOwner public {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);

    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
  }

  event Burn(address indexed burner, uint256 value);

}