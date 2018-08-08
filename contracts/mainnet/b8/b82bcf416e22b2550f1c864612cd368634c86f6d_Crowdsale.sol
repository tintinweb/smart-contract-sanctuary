pragma solidity ^0.4.19;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override 
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */

contract Crowdsale is Pausable {
  using SafeMath for uint256;

  // The token being sold VIVID
  // 0x7d8467f9621535c71bdab07529b33e4bd0d3f0ef
  ERC20 public token;

  //Wallet where funds will be 
  //0xe5DfC8b68d3473c41435bE29bea9D991BfB70895
  address public tokenWallet;

  // Address where funds are collected
  // 0x8330E12E1Be12D4302440AE351eF4385342b397A
  address public wallet;

  // How many token units a buyer gets per wei
  // should be set to 10000
  uint256 public baseRate;

  // Amount of wei raised
  uint256 public weiRaised;

  uint256 public cap;

  uint256 public openingTime;

  uint256 firstTierRate = 20;
  uint256 secondTierRate = 10;
  uint256 thirdTierRate = 5;

  mapping(address => uint256) public balances;

  modifier onlyWhileOpen {
    require(now >= openingTime && weiRaised < cap);
    _;
  }
  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _openingTime, uint256 _rate, address _wallet, ERC20 _token, uint256 _cap, address _tokenWallet) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    require(_cap > 0);
    require(_tokenWallet != address(0));

    openingTime = _openingTime;
    baseRate = _rate;
    wallet = _wallet;
    token = _token;
    cap = _cap;
    tokenWallet = _tokenWallet;
  }

  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   */
  function withdrawTokens() public {
    require(capReached());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
  }

  /**
   * @dev Withdraw tokens or other users.
   */
  function withdrawTokensFor(address _accountToWithdrawFor) public onlyOwner {
    uint256 amount = balances[_accountToWithdrawFor];
    require(amount > 0);
    balances[_accountToWithdrawFor] = 0;
    _deliverTokens(_accountToWithdrawFor, amount);
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external whenNotPaused payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    
    _forwardFunds();
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen {
    require(_beneficiary != address(0));
    //Minimum Purchase is going to be .01 Ether
    //.01 = 10000000000000000
    require(_weiAmount > 10000000000000000);
    require(weiRaised.add(_weiAmount) <= cap);
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
      uint256 bonusRate;
      uint256 realRate;
	  if (weiRaised <= 450 ether) {
		   bonusRate = baseRate.mul(firstTierRate).div(100);
		   realRate = baseRate.add(bonusRate);
		  return _weiAmount.mul(realRate);
	  } else if (weiRaised <= 800 ether) {
		   bonusRate = baseRate.mul(secondTierRate).div(100);
		   realRate = baseRate.add(bonusRate);
		  return _weiAmount.mul(realRate);
	  } else if (weiRaised <= 3000 ether) {
		   bonusRate = baseRate.mul(thirdTierRate).div(100);
		   realRate = baseRate.add(bonusRate);
		  return _weiAmount.mul(realRate);
	  } else {
		  return _weiAmount.mul(baseRate);
	  }
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}