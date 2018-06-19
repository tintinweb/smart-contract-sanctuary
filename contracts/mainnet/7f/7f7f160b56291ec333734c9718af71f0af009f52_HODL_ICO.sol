pragma solidity ^0.4.24;

/**
 * SmartEth.co
 * ERC20 Token and ICO smart contracts development, smart contracts audit, ICO websites.
 * contact@smarteth.co
 */

/**
 * @title SafeMath
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = 0xD8F2FCbeDC3a1434a4B82b330765ff0Ada9d0D10;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title ERC20Basic
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HODL_ICO is Pausable {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // Max supply of tokens offered in the crowdsale
  uint256 public supply;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;
  
  // Min amount of wei an investor can send
  uint256 public minInvest;
  
  // Crowdsale opening time
  uint256 public openingTime;
  
  // Crowdsale closing time
  uint256 public closingTime;

  // Crowdsale duration in days
  uint256 public duration;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor() public {
    rate = 1000;
    wallet = owner;
    token = ERC20(0x2F21116ABbb4A91D916bE8c665B461AEa00eb568);
    minInvest = 0.1 * 1 ether;
    duration = 45 days;
    openingTime = 1591920321;  // Determined by start()
    closingTime = openingTime + duration;  // Determined by start()
  }
  
  /**
   * @dev called by the owner to start the crowdsale
   */
  function start() public onlyOwner {
    openingTime = now;       
    closingTime =  now + duration;
  }

  /**
   * @dev Returns the rate of tokens per wei at the present time.
   */
  function getCurrentRate() public view returns (uint256) {
    if (now <= openingTime.add(15 days)) return rate.add(rate);   // PRE-ICO bonus 100% 15 days
    if (now > openingTime.add(15 days) && now <= openingTime.add(18 days)) return rate.add(rate*3/4);   // ICO bonus 75% 1st three days
    if (now > openingTime.add(18 days) && now <= openingTime.add(21 days)) return rate.add(rate*7/10);   // ICO bonus 70% 2nd three days
    if (now > openingTime.add(21 days) && now <= openingTime.add(24 days)) return rate.add(rate*13/20);   // ICO bonus 65% 3rd three days
    if (now > openingTime.add(24 days) && now <= openingTime.add(27 days)) return rate.add(rate*3/5);   // ICO bonus 60% 4th three days
    if (now > openingTime.add(27 days) && now <= openingTime.add(30 days)) return rate.add(rate*11/20);   // ICO bonus 55% 5th three days
    if (now > openingTime.add(30 days) && now <= openingTime.add(33 days)) return rate.add(rate/2);   // ICO bonus 50% 6th three days
    if (now > openingTime.add(33 days) && now <= openingTime.add(36 days)) return rate.add(rate*9/20);   // ICO bonus 45% 7th three days
    if (now > openingTime.add(36 days) && now <= openingTime.add(39 days)) return rate.add(rate*2/5);   // ICO bonus 40% 8th three days
    if (now > openingTime.add(39 days) && now <= openingTime.add(42 days)) return rate.add(rate*7/20);   // ICO bonus 35% 9th three days
    if (now > openingTime.add(42 days)) return rate.add(rate*3/10);   // ICO bonus 30% 10th three days
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
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
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
    require(_beneficiary != address(0));
    require(_weiAmount >= minInvest);
    require(now >= openingTime && now <= closingTime);
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 currentRate = getCurrentRate();
    return currentRate.mul(_weiAmount);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }

  /**
   * @dev called by the owner to withdraw unsold tokens
   */
  function withdrawTokens() public onlyOwner {
    uint256 unsold = token.balanceOf(this);
    token.transfer(owner, unsold);
  }

}