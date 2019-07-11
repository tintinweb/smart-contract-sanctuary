/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.24;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0 uint256 c = a / b;
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
 */
contract token { function transfer(address receiver, uint amount){  } }
contract RFCICO {
  using SafeMath for uint256;

  
  // address where funds are collected
  address public wallet;
  // token address
  address public RFC;

  uint256 public price = 303;

  token tokenReward;

  // mapping (address => uint) public contributions;
  

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  constructor() public{
    //You will change this to your wallet where you need the ETH 
    wallet = 0x1c46A08C940D9433297646cBa10Bc492c7D53A82;

    //Here will come the checksum address we got
    RFC = 0xed1CAa23883345098C7939C44Fb201AA622746aD;


    tokenReward = token(RFC);
  }

  bool public started = true;

  function startSale() public{
    if (msg.sender != wallet) revert();
    started = true;
  }

  function stopSale() public{
    if(msg.sender != wallet) revert();
    started = false;
  }

  function setPrice(uint256 _price) public{
    if(msg.sender != wallet) revert();
    price = _price;
  }
  function changeWallet(address _wallet) public{
  	if(msg.sender != wallet) revert();
  	wallet = _wallet;
  }

  function changeTokenReward(address _token) public{
    if(msg.sender!=wallet) revert();
    tokenReward = token(_token);
    RFC = _token;
  }

  // fallback function can be used to buy tokens
  function () payable public{
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable public{
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;


    // calculate token amount to be sent
    uint256 tokens = ((weiAmount) * price);
    
    
   
    weiRaised = weiRaised.add(weiAmount);
    
   
    tokenReward.transfer(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    // wallet.transfer(msg.value);
    if (!wallet.send(msg.value)) {
      revert();
    }
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = started;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) public{
    if(msg.sender!=wallet) revert();
    tokenReward.transfer(wallet,_amount);
  }
}