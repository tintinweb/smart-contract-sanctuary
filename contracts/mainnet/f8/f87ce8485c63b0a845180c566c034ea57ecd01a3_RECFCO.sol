pragma solidity ^0.4.21;


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


contract RealEstateCryptoFund {
  function transfer(address to, uint256 value) public returns (bool);
  function balanceOf(address who) public constant returns (uint256);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract RECFCO is Ownable {
  
  using SafeMath for uint256;

  RealEstateCryptoFund public token;

  mapping(address=>bool) public participated;
   
   
   // address where funds are collected
  address public wallet;
  
  //address public token_wallet;
  
  //date stop crodwsale
  uint256 public  salesdeadline;

  // how many token units a buyer gets per wei (for < 1ETH purchases)
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;
  
 event sales_deadlineUpdated(uint256 sales_deadline );// volessimo allungare il contratto di sale 
 event WalletUpdated(address wallet);
 event RateUpdate(uint256 rate);
 //event tokenWalletUpdated(address token_wallet);

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function RECFCO(address _tokenAddress, address _wallet) public {
    token = RealEstateCryptoFund(_tokenAddress);
    wallet = _wallet;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

 

  

  function buyTokens(address beneficiary) public payable {
    require(now < salesdeadline);
    require(beneficiary != address(0));
    require(msg.value != 0);

    uint256 weiAmount = msg.value;

    uint256 tokens = getTokenAmount( weiAmount);

    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokens);

    emit TokenPurchase(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    participated[beneficiary] = true;

    forwardFunds();
  }

 

function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    uint256 tokenAmount;
    tokenAmount = weiAmount.mul(rate);
    return tokenAmount;
  }

  
  function forwardFunds() internal {
    wallet.transfer(msg.value);
      
  }
 
function setRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    rate = _rate;
    emit RateUpdate(rate);
}

//wallet update
function setWallet (address _wallet) onlyOwner public {
wallet=_wallet;
emit WalletUpdated(wallet);
}

//SALES_DEADLINE update
function setsalesdeadline (uint256 _salesdeadline) onlyOwner public {
salesdeadline=_salesdeadline;
require(now < salesdeadline);
emit sales_deadlineUpdated(salesdeadline);
}
    

}