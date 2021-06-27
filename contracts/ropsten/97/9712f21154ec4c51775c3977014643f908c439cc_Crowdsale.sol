/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

/**
 *Submitted for verification at Etherscan.io on 2019-07-20
*/

pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0 uint256 c = a / b;
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded 
 to a wallet
 * as they arrive.
 */
interface token { 
    function transfer(address receiver, uint amount) external ; 
    function transferFrom(address, address, uint) external;
    function allowance(address _owner, address _spender) external view returns (uint256);
}
contract Crowdsale {
  using SafeMath for uint256;


  // address where funds are collected
  address public wallet;
  // token address
  address public addressOfTokenUsedAsReward;

  uint256 public price = 2000;
  uint public tokensPerUsdt = 1 * 10**8;

  token tokenReward;

  // amount of raised money in wei
  uint256 public weiRaised;
  address public usdtAddress = 0xeeD406A9C3dB4710Ad742746bcAd6643392B49c3;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  constructor () public {
    //You will change this to your wallet where you need the ETH 
    wallet = 0xB616340a10F14218E5dB19cdAddA686A9557658B;
    
    //Here will come the checksum address we got
    addressOfTokenUsedAsReward =  0x9cC3C31142c179f52683A4F1Dc17fcB8B2Ab45Fb;

    tokenReward = token(addressOfTokenUsedAsReward);
  }

  bool public started = true;

  function startSale() public {
    require (msg.sender == wallet);
    started = true;
  }

  function stopSale() public {
    require(msg.sender == wallet);
    started = false;
  }

  function setPrice(uint256 _price) public {
    require(msg.sender == wallet);
    price = _price;
  }
  function changeWallet(address _wallet) public {
    require (msg.sender == wallet);
    wallet = _wallet;
  }
  
  function setUsdtAddress(address _usdtAddress) public {
      require(msg.sender == wallet);
      usdtAddress = _usdtAddress;
  }
  
  function setTokensPerUsdt(uint _tokensPerUsdt) public {
      require(msg.sender == wallet);
      tokensPerUsdt = _tokensPerUsdt;
      
  }
  
  function buyWithUsdt() public {
      token USDT = token(usdtAddress);
      uint allowed = USDT.allowance(msg.sender, address(this));
      
      require(allowed > 0);
      
      USDT.transferFrom(msg.sender, wallet, allowed);
      
      uint tokens = tokensPerUsdt.mul(allowed).div(1e6);
      
      tokenReward.transfer(msg.sender, tokens);
  }


  // fallback function can be used to buy tokens
  function () payable public {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable public {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;


    // calculate token amount to be sent
    uint256 tokens = (weiAmount/10**10) * price;//weiamount * price 
    // uint256 tokens = (weiAmount/10**(18-decimals)) * price;//weiamount * price 

    // update state
    weiRaised = weiRaised.add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
     wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = started;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) public {
    require (msg.sender == wallet);
    tokenReward.transfer(wallet,_amount);
  }
}