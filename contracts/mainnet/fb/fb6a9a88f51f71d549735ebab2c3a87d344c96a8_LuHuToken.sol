pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

// File: zeppelin-solidity/contracts/token/ERC20/PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: contracts/act/LuHuToken.sol

// ----------------------------------------------------------------------------
// Vingochain Token smart contract - ERC20 Token Interface
//
// The MIT Licence.
// ----------------------------------------------------------------------------
interface tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract LuHuToken is PausableToken {

  using SafeERC20 for ERC20;
  using SafeMath for uint;

  /*
  NOTE:
  The following variables are OPTIONAL vanities. One does not have to include them.
  They allow one to customise the token contract & in no way influences the core functionality.
  Some wallets/interfaces might not even bother to look at this information.
  */

  // token number for 1 ether
  uint public constant TOKEN_PER_ETHER = 60000;
    
    // ------------------------------------------------------------------------
    // Individual transaction contribution min and max amounts
    // Set to 0 to switch off, or `x ether`
    // ------------------------------------------------------------------------
  uint private CONTRIBUTIONS_MIN = 1 ether;

  uint constant public OFFSET = 420;

  uint constant public MIN_CROWSALE_TIME = 600;

  uint8 public constant DECIMALS = 18;
    
  uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);

  uint public constant TOKENS_TOTAL = 100 * 10 ** 8 * DECIMALSFACTOR;

  uint public constant TOKENS_CAP_ICO = 25 * 10 ** 8 * DECIMALSFACTOR;

  string public name = "LuHuToken";
  
  uint8 public decimals = DECIMALS;

  uint public divider = 10 ** uint(18 - decimals);
  
  string public symbol;

  mapping(address => uint256) public weiBalances;

    // ------------------------------------------------------------------------
    // Tranche 1 token sale start date and end date
    // Do not use the `now` function here
    // ICO start - Mar 1st 2018 @ 8:00 a.m.
    // ICO end - 30 days later after ICO started.
    // ------------------------------------------------------------------------
  uint public period = 30 days;
  uint public startDate = 1519862400;
  uint public endDate = startDate + period;

  function setStartDate(uint _startDate) public onlyOwner {
    uint nowTime = getNow();
    require(startDate > nowTime);
    require(_startDate > nowTime);
    startDate = _startDate;
    uint tempEndDate = startDate.add(MIN_CROWSALE_TIME);
    if (endDate < tempEndDate) {
      endDate = tempEndDate;
    }
  }

  function setEndDate(uint _endDate) public onlyOwner {
    uint nowTime = getNow();
    require(endDate > nowTime);
    require(_endDate > nowTime);
    endDate = _endDate;
  }

  address public wallet;

  uint public fakeNow = 0;

  uint public crowsaleShare = 0;

  function getNow() internal view returns (uint) {
    if (fakeNow == 0) {
      return now;
    }
    return fakeNow;
  }

  modifier validAddress(address addr) {
    require(addr != address(0x0));
    _;
  }

  mapping(address => bool) userWhitelist;

  function whitelist(address user) onlyOwner public {
    userWhitelist[user] = true;
  }

  function unWhitelist(address user) onlyOwner public {
    userWhitelist[user] = false;
  }

  function isInWhitelist(address user) internal view returns (bool) {
    return userWhitelist[user];
  }

  function LuHuToken(string _symbol, address _wallet) validAddress(_wallet) public {
    symbol = _symbol;
    totalSupply_ = TOKENS_TOTAL;
    wallet = _wallet;
    balances[wallet] = totalSupply_;
  }

  // ------------------------------------------------------------------------
  // Accept ethers to buy tokens during the crowdsale(ICO)
  // ------------------------------------------------------------------------
  function () external payable {
    proxyPayment(msg.sender);
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return getNow() > endDate;
  }

  // ------------------------------------------------------------------------
  // Accept ethers from one account for tokens to be created for another
  // account. Can be used by exchanges to purchase tokens on behalf of
  // it&#39;s user
  // ------------------------------------------------------------------------
  function proxyPayment(address participant) public payable {
    
    require(participant != address(0x0));

    uint nowTime = getNow();
    require(nowTime >= startDate && nowTime <= endDate);

    require(isInWhitelist(msg.sender));
    require(isInWhitelist(participant));

    uint weiRaised = msg.value;

    require(weiRaised >= CONTRIBUTIONS_MIN);

    uint tokens = TOKEN_PER_ETHER.mul(weiRaised);
    crowsaleShare = crowsaleShare.add(tokens);

    require(crowsaleShare <= TOKENS_CAP_ICO);
    
    weiBalances[participant] = weiBalances[participant].add(weiRaised);

    balances[participant] = balances[participant].add(tokens);
    balances[wallet] = balances[wallet].sub(tokens);

    wallet.transfer(weiRaised);
    TokenPurchase(wallet, msg.sender, participant, weiRaised, tokens);

  }

  function changeWallet(address _wallet) onlyOwner public {
    
    require(_wallet != address(0x0));
    
    require(_wallet != wallet);

      balances[_wallet] = balances[wallet];
      balances[wallet] = 0;
      wallet = _wallet;
      WalletUpdated(wallet);
  }
  
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
    returns (bool success) 
  {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);            
          return true;
      }
      return false;
  }

  event TokenPurchase(address indexed wallet, address indexed purchaser, address indexed beneficiary, 
    uint256 value, uint256 amount);

  event WalletUpdated(address newWallet);

}

// File: contracts/mocks/TokenMock.sol

// @dev TokenMock mocks current time

contract TokenMock is LuHuToken {

  function TokenMock(string symbol, address wallet) LuHuToken(symbol, wallet) public {
  }

  //this function will never be used in production env.
  function setNow(uint _now) public onlyOwner {
    fakeNow = _now;
  }

  function getNowFromOwner() public view returns (uint time) {
    return getNow();
  }

}