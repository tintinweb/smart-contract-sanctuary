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


// 还差
// 1. 白名单 就是一个mapping吧 ok
// 2. 个人cap 其实就是 不是xxx 不收 require
// emit event 打log
contract Crowdsale {
  using SafeMath for uint256;

 // 这下面是我从openzepplin抄的
  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }



  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) public {
    require(msg.sender == wallet);
    whitelist[_beneficiary] = true;
  }



  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) public {
      require(msg.sender == wallet);
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }



  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) public {
    require(msg.sender == wallet);
    whitelist[_beneficiary] = false;
  }


  function _removeFromWhitelist(address _beneficiary) internal {
    whitelist[_beneficiary] = false;
  }

  // *****************

  // address where funds are collected
  address public wallet;
  // token address
  address public addressOfTokenUsedAsReward;

  uint256 public price = 2000;
  uint public tokensPerUsdt = 1 * 10**8;

  token tokenReward;

  // amount of raised money in wei
  uint256 public weiRaised;
  uint256 public cap = 1 * 10**18;
  address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

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
    wallet = 0x14dDda446688b73161AA1382F4E4343353aF6FC8;
    
    //Here will come the checksum address we got
    addressOfTokenUsedAsReward =  0x8eA2CaA3CFB352BE989C7C17911FecFDC11151Ba;

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

  function setCap(uint256 _cap) public {
    require(msg.sender == wallet);
    cap = _cap;
  }
  
  // fallback function can be used to buy tokens
  function () payable public {
    require(validPurchase());
    buyTokens();
  }

  // low level token purchase function
  function buyTokens() payable public isWhitelisted(msg.sender) {
    require(validPurchase());

    uint256 weiAmount = msg.value;


    // calculate token amount to be sent
    uint256 tokens = (weiAmount/10**10) * price;//weiamount * price 
    // uint256 tokens = (weiAmount/10**(18-decimals)) * price;//weiamount * price 

    // update state
    weiRaised = weiRaised.add(weiAmount);

    tokenReward.transfer(msg.sender, tokens);
    emit TokenPurchase(msg.sender, msg.sender, weiAmount, tokens);
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
    bool isWhitelist = whitelist[msg.sender];
    bool isCompatibleWithCap = msg.value == cap;
    return withinPeriod && nonZeroPurchase && isWhitelist && isCompatibleWithCap;
  }

  function withdrawTokens(uint256 _amount) public {
    require (msg.sender == wallet);
    tokenReward.transfer(wallet,_amount);
  }
}