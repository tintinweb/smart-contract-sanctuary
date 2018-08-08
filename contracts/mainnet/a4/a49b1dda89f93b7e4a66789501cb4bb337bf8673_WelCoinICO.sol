pragma solidity ^0.4.19;


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



contract WelCoinICO is Ownable {

  using SafeMath for uint256;

  // start and end timestamps where main-investments are allowed (both inclusive)
  uint256 public mainSaleStartTime;
  uint256 public mainSaleEndTime;

  // maximum amout of wei for  main sale
  //uint256 public mainSaleWeiCap;

  // maximum amout of wei to allow for investors
  uint256 public mainSaleMinimumWei;

  // address where funds are collected
  address public wallet;

  // address of erc20 token contract
  address public token;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // bonus percent to apply
  uint256 public percent;

  // amount of raised money in wei
  //uint256 public weiRaised;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function WelCoinICO(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, address _wallet, address _token) public {

    // the end of main sale can&#39;t happen before it&#39;s start
    require(_mainSaleStartTime < _mainSaleEndTime);
    require(_wallet != 0x0);

    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    wallet = _wallet;
    token = _token;
    rate = 2500;
    percent = 0;
    mainSaleMinimumWei = 100000000000000000; // 0.1
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {

    require(beneficiary != 0x0);
    require(msg.value != 0x0);
    require(msg.value >= mainSaleMinimumWei);
    require(now >= mainSaleStartTime && now <= mainSaleEndTime);

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // add bonus to tokens depends on the period
    uint256 bonusedTokens = applyBonus(tokens, percent);

    require(token.call(bytes4(keccak256("transfer(address,uint256)")), beneficiary, bonusedTokens));

    // token.mint(beneficiary, bonusedTokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);

    forwardFunds();
  }

  // set new dates for main-sale (emergency case)
  function setMainSaleParameters(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, uint256 _mainSaleMinimumWei) public onlyOwner {
    require(_mainSaleStartTime < _mainSaleEndTime);
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    mainSaleMinimumWei = _mainSaleMinimumWei;
  }

  // set new wallets (emergency case)
  function setWallet(address _wallet) public onlyOwner {
    require(_wallet != 0x0);
    wallet = _wallet;
  }

    // set new rate (emergency case)
  function setRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    rate = _rate;
  }

  // send tokens to specified wallet wallet
  function transferTokens(address _wallet, uint256 _amount) public onlyOwner {
    require(_wallet != 0x0);
    require(_amount != 0);
    require(token.call(bytes4(keccak256("transfer(address,uint256)")), _wallet, _amount));
  }


  // @return true if main sale event has ended
  function mainSaleHasEnded() external constant returns (bool) {
    return now > mainSaleEndTime;
  }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }


  function applyBonus(uint256 tokens, uint256 percentToApply) internal pure returns (uint256 bonusedTokens) {
    uint256 tokensToAdd = tokens.mul(percentToApply).div(100);
    return tokens.add(tokensToAdd);
  }

}