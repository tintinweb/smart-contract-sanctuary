pragma solidity ^0.4.19;

/**
 * This is the official Ethbet Token smart contract (EBET) - https://ethbet.io/
 */

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


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title EthbetToken
 */
contract EthbetToken is StandardToken {

  string public constant name = "Ethbet";
  string public constant symbol = "EBET";
  uint8 public constant decimals = 2; // only two deciminals, token cannot be divided past 1/100th

  uint256 public constant INITIAL_SUPPLY = 1000000000; // 10 million + 2 decimals

  /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
  function EthbetToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}


// Import newer SafeMath version under new name to avoid conflict with the version included in EthbetToken

// SafeMath Library https://github.com/OpenZeppelin/zeppelin-solidity/blob/49b42e86963df7192e7024e0e5bd30fa9d7ccbef/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath2 {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ethbet {
  using SafeMath2 for uint256;

  /*
  * Events
  */

  event Deposit(address indexed user, uint amount, uint balance);

  event Withdraw(address indexed user, uint amount, uint balance);

  event LockedBalance(address indexed user, uint amount);

  event UnlockedBalance(address indexed user, uint amount);

  event ExecutedBet(address indexed winner, address indexed loser, uint amount);

  event RelayAddressChanged(address relay);


  /*
   * Storage
   */
  address public relay;

  EthbetToken public token;

  mapping(address => uint256) balances;

  mapping(address => uint256) lockedBalances;

  /*
  * Modifiers
  */

  modifier isRelay() {
    require(msg.sender == relay);
    _;
  }

  /*
  * Public functions
  */

  /**
  * @dev Contract constructor
  * @param _relay Relay Address
  * @param _tokenAddress Ethbet Token Address
  */
  function Ethbet(address _relay, address _tokenAddress) public {
    // make sure relay address set
    require(_relay != address(0));

    relay = _relay;
    token = EthbetToken(_tokenAddress);
  }

  /**
  * @dev set relay address
  * @param _relay Relay Address
  */
  function setRelay(address _relay) public isRelay {
    // make sure address not null
    require(_relay != address(0));

    relay = _relay;

    RelayAddressChanged(_relay);
  }

  /**
   * @dev deposit EBET tokens into the contract
   * @param _amount Amount to deposit
   */
  function deposit(uint _amount) public {
    require(_amount > 0);

    // token.approve needs to be called beforehand
    // transfer tokens from the user to the contract
    require(token.transferFrom(msg.sender, this, _amount));

    // add the tokens to the user&#39;s balance
    balances[msg.sender] = balances[msg.sender].add(_amount);

    Deposit(msg.sender, _amount, balances[msg.sender]);
  }

  /**
   * @dev withdraw EBET tokens from the contract
   * @param _amount Amount to withdraw
   */
  function withdraw(uint _amount) public {
    require(_amount > 0);
    require(balances[msg.sender] >= _amount);

    // subtract the tokens from the user&#39;s balance
    balances[msg.sender] = balances[msg.sender].sub(_amount);

    // transfer tokens from the contract to the user
    require(token.transfer(msg.sender, _amount));

    Withdraw(msg.sender, _amount, balances[msg.sender]);
  }


  /**
   * @dev Lock user balance to be used for bet
   * @param _userAddress User Address
   * @param _amount Amount to be locked
   */
  function lockBalance(address _userAddress, uint _amount) public isRelay {
    require(_amount > 0);
    require(balances[_userAddress] >= _amount);

    // subtract the tokens from the user&#39;s balance
    balances[_userAddress] = balances[_userAddress].sub(_amount);

    // add the tokens to the user&#39;s locked balance
    lockedBalances[_userAddress] = lockedBalances[_userAddress].add(_amount);

    LockedBalance(_userAddress, _amount);
  }

  /**
   * @dev Unlock user balance
   * @param _userAddress User Address
   * @param _amount Amount to be locked
   */
  function unlockBalance(address _userAddress, uint _amount) public isRelay {
    require(_amount > 0);
    require(lockedBalances[_userAddress] >= _amount);

    // subtract the tokens from the user&#39;s locked balance
    lockedBalances[_userAddress] = lockedBalances[_userAddress].sub(_amount);

    // add the tokens to the user&#39;s  balance
    balances[_userAddress] = balances[_userAddress].add(_amount);

    UnlockedBalance(_userAddress, _amount);
  }

  /**
  * @dev Get user balance
  * @param _userAddress User Address
  */
  function balanceOf(address _userAddress) constant public returns (uint) {
    return balances[_userAddress];
  }

  /**
  * @dev Get user locked balance
  * @param _userAddress User Address
  */
  function lockedBalanceOf(address _userAddress) constant public returns (uint) {
    return lockedBalances[_userAddress];
  }

  /**
   * @dev Execute bet
   * @param _maker Maker Address
   * @param _caller Caller Address
   * @param _makerWon Did the maker win
   * @param _amount amount
   */
  function executeBet(address _maker, address _caller, bool _makerWon, uint _amount) isRelay public {
    //The caller must have enough locked balance
    require(lockedBalances[_caller] >= _amount);

    //The maker must have enough locked balance
    require(lockedBalances[_maker] >= _amount);

    // unlock maker balance
    unlockBalance(_caller, _amount);

    // unlock maker balance
    unlockBalance(_maker, _amount);

    var winner = _makerWon ? _maker : _caller;
    var loser = _makerWon ? _caller : _maker;

    // add the tokens to the winner&#39;s balance
    balances[winner] = balances[winner].add(_amount);
    // remove the tokens from the loser&#39;s  balance
    balances[loser] = balances[loser].sub(_amount);

    //Log the event
    ExecutedBet(winner, loser, _amount);
  }

}