pragma solidity ^0.4.22;

// File: contracts/zeppelin/math/SafeMath.sol

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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20 interface
 * @dev GangTokenSale contract using this function to send tokens to buyer
 */
contract ERC20 {
  function transfer(address to, uint256 value) public returns (bool);
  function balanceOf(address _owner) public view returns (uint256 balance);
}

//standard contract to identify owner
contract Ownable {

  address public owner;

  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}



// File: contracts/GangTokensale.sol

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
contract GangTokenSale is Ownable{
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param etherValue weis paid for purchase
   * @param tokenAmount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 indexed etherValue, uint256 tokenAmount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor (address _token, address _wallet, address _owner, uint256 _rate) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    owner = _owner;

    rate = _rate;
    wallet = _wallet;
    token = ERC20(_token);
  }



  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    require(buyTokens(msg.sender, msg.value));
  }

  function buyTokens(address _beneficiary, uint _value) internal returns(bool) {
    require(_value > 0);

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(_value);

    // update state
    weiRaised = weiRaised.add(_value);

    // send tokens
    token.transfer(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, _value, tokens);

    //send ether to wallet
    wallet.transfer(address(this).balance);

    return true;
  }

  // -----------------------------------------
  // Public interface (extensible)
  // -----------------------------------------

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  function getRemainingTokens () public view returns(uint) {
    return token.balanceOf(address(this));
  }
  
  function setNewRate (uint _rate) onlyOwner public {
    require(_rate > 0);
    rate = _rate;
  }

  function destroyContract () onlyOwner public {
    uint tokens = token.balanceOf(address(this));
    token.transfer(wallet, tokens);

    selfdestruct(wallet);
  }
}