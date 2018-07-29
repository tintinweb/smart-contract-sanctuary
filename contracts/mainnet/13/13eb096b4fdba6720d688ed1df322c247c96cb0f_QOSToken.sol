pragma solidity ^0.4.24;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
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

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
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

contract QOSToken is StandardToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalFrozen;
    uint256 internal unlockedAt;
    mapping(address => uint256) frozenAccount;

    address internal sellerAddr = 0x0091426938dFb8F5052F790C4bC40F65eA4aF456;
    address internal prvPlacementAddr = 0x00B76C436e0784501012e2c436b54c1DA4E82434;
    address internal communitAddr = 0x00e0916090A85258fb645d58E654492361a853fe;
    address internal develAddr = 0x0077779160989a61A24ee7D1ed0f87d217e1d30C;
    address internal fundationAddr = 0x00879858d5ed1Cf4082C1f58064565B0633A3b97;
    address internal teamAddr = 0x008A3fA7815daBbc02d7517BA083f19D5d6d2aBB;


    event Frozen(address indexed from, uint256 value);
    event UnFrozen(address indexed from, uint256 value);

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        uint256 decimalValue = 10 ** uint256(decimals);
        totalSupply_ = SafeMath.mul(4900000000, decimalValue);
        unlockedAt = now + 12 * 30 days;

        balances[sellerAddr] = SafeMath.mul(500000000, decimalValue); //for r transaction market
        balances[prvPlacementAddr] = SafeMath.mul(500000000, decimalValue);//  for private placement
        balances[communitAddr] = SafeMath.mul(500000000, decimalValue);// for communit operation
        balances[develAddr] = SafeMath.mul(900000000, decimalValue);// for development
        balances[fundationAddr] = SafeMath.mul(1500000000, decimalValue); // for foundation

        emit Transfer(this, sellerAddr, balances[sellerAddr]);
        emit Transfer(this, prvPlacementAddr, balances[prvPlacementAddr]);
        emit Transfer(this, communitAddr, balances[communitAddr]);
        emit Transfer(this, develAddr, balances[develAddr]);
        emit Transfer(this, fundationAddr, balances[fundationAddr]);

        frozenAccount[teamAddr] = SafeMath.mul(1000000000, decimalValue); // 10% for team
        totalFrozen = frozenAccount[teamAddr];
        emit Frozen(teamAddr, totalFrozen);
    }

    function unFrozen() external {
        require(now > unlockedAt);
        require(msg.sender == teamAddr);

        uint256 frozenBalance = frozenAccount[msg.sender];
        require(frozenBalance > 0);

        uint256 nmonth = SafeMath.div(now - unlockedAt, 30 * 1 days) + 1;
        if (nmonth > 23) {
            balances[msg.sender] += frozenBalance;
            frozenAccount[msg.sender] = 0;
            emit UnFrozen(msg.sender, frozenBalance);
            return;
        }

        //23*4166666+4166682 = 100000000
        uint256 decimalValue = 10 ** uint256(decimals);
        uint256 oneMonthBalance = SafeMath.mul(4166666, decimalValue);
        uint256 unfrozenBalance = SafeMath.mul(nmonth, oneMonthBalance);
        frozenAccount[msg.sender] = totalFrozen - unfrozenBalance;
        uint256 toTransfer = frozenBalance - frozenAccount[msg.sender];

        require(toTransfer > 0);
        balances[msg.sender] += toTransfer;
        emit UnFrozen(msg.sender, toTransfer);
    }
}