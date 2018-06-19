pragma solidity ^0.4.18;
/**
* @title ICO CONTRACT
* @dev ERC-20 Token Standard Complian
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public{
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract token {

  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);

}


contract Crowdsale is Ownable {
  using SafeMath for uint256;
  // The token being sold
  token public token_reward;
  // start and end timestamps where investments are allowed (both inclusive
  
  uint256 public start_time = now; //for testing
  //uint256 public start_time = 1517846400; //02/05/2018 @ 4:00pm (UTC) or 5 PM (UTC + 1)
  uint256 public end_Time = 1524355200; // 04/22/2018 @ 12:00am (UTC)

  uint256 public phase_1_remaining_tokens  = 50000000 * (10 ** uint256(8));
  uint256 public phase_2_remaining_tokens  = 50000000 * (10 ** uint256(8));
  uint256 public phase_3_remaining_tokens  = 50000000 * (10 ** uint256(8));
  uint256 public phase_4_remaining_tokens  = 50000000 * (10 ** uint256(8));
  uint256 public phase_5_remaining_tokens  = 50000000 * (10 ** uint256(8));

  uint256 public phase_1_bonus  = 40;
  uint256 public phase_2_bonus  = 20;
  uint256 public phase_3_bonus  = 15;
  uint256 public phase_4_bonus  = 10;
  uint256 public phase_5_bonus  = 5;

  uint256 public token_price  = 2;// 2 cents

  // address where funds are collected
  address public wallet;
  // Ether to $ price
  uint256 public eth_to_usd = 1000;
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
  // rate change event
  event EthToUsdChanged(address indexed owner, uint256 old_eth_to_usd, uint256 new_eth_to_usd);
  
  // constructor
  function Crowdsale(address tokenContractAddress) public{
    wallet = 0x1aC024482b91fa9AaF22450Ff60680BAd60bF8D3;//wallet where ETH will be transferred
    token_reward = token(tokenContractAddress);
  }
  
 function tokenBalance() constant public returns (uint256){
    return token_reward.balanceOf(this);
  }

  function getRate() constant public returns (uint256){
    return eth_to_usd.mul(100).div(token_price);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= start_time && now <= end_Time;
    bool allPhaseFinished = phase_5_remaining_tokens > 0;
    bool nonZeroPurchase = msg.value != 0;
    bool minPurchase = eth_to_usd*msg.value >= 100; // minimum purchase $100
    return withinPeriod && nonZeroPurchase && allPhaseFinished && minPurchase;
  }

  // @return true if the admin can send tokens manually
  function validPurchaseForManual() internal constant returns (bool) {
    bool withinPeriod = now >= start_time && now <= end_Time;
    bool allPhaseFinished = phase_5_remaining_tokens > 0;
    return withinPeriod && allPhaseFinished;
  }


  // check token availibility for current phase and max allowed token balance
  function checkAndUpdateTokenForManual(uint256 _tokens) internal returns (bool){
    if(phase_1_remaining_tokens > 0){
      if(_tokens > phase_1_remaining_tokens){
        uint256 tokens_from_phase_2 = _tokens.sub(phase_1_remaining_tokens);
        phase_1_remaining_tokens = 0;
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(tokens_from_phase_2);
      }else{
        phase_1_remaining_tokens = phase_1_remaining_tokens.sub(_tokens);
      }
      return true;
    }else if(phase_2_remaining_tokens > 0){
      if(_tokens > phase_2_remaining_tokens){
        uint256 tokens_from_phase_3 = _tokens.sub(phase_2_remaining_tokens);
        phase_2_remaining_tokens = 0;
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(tokens_from_phase_3);
      }else{
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(_tokens);
      }
      return true;
    }else if(phase_3_remaining_tokens > 0){
      if(_tokens > phase_3_remaining_tokens){
        uint256 tokens_from_phase_4 = _tokens.sub(phase_3_remaining_tokens);
        phase_3_remaining_tokens = 0;
        phase_4_remaining_tokens = phase_4_remaining_tokens.sub(tokens_from_phase_4);
      }else{
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(_tokens);
      }
      return true;
    }else if(phase_4_remaining_tokens > 0){
      if(_tokens > phase_4_remaining_tokens){
        uint256 tokens_from_phase_5 = _tokens.sub(phase_4_remaining_tokens);
        phase_4_remaining_tokens = 0;
        phase_5_remaining_tokens = phase_5_remaining_tokens.sub(tokens_from_phase_5);
      }else{
        phase_4_remaining_tokens = phase_4_remaining_tokens.sub(_tokens);
      }
      return true;
    }else if(phase_5_remaining_tokens > 0){
      if(_tokens > phase_5_remaining_tokens){
        return false;
      }else{
        phase_5_remaining_tokens = phase_5_remaining_tokens.sub(_tokens);
       }
    }else{
      return false;
    }
  }

  // function to transfer token manually
  function transferManually(uint256 _tokens, address to_address) onlyOwner public returns (bool){
    require(to_address != 0x0);
    require(validPurchaseForManual());
    require(checkAndUpdateTokenForManual(_tokens));
    token_reward.transfer(to_address, _tokens);
    return true;
  }


  // check token availibility for current phase and max allowed token balance
  function transferIfTokenAvailable(uint256 _tokens, uint256 _weiAmount, address _beneficiary) internal returns (bool){

    uint256 total_token_to_transfer = 0;
    uint256 bonus = 0;
    if(phase_1_remaining_tokens > 0){
      if(_tokens > phase_1_remaining_tokens){
        uint256 tokens_from_phase_2 = _tokens.sub(phase_1_remaining_tokens);
        bonus = (phase_1_remaining_tokens.mul(phase_1_bonus).div(100)).add(tokens_from_phase_2.mul(phase_2_bonus).div(100));
        phase_1_remaining_tokens = 0;
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(tokens_from_phase_2);
      }else{
        phase_1_remaining_tokens = phase_1_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_1_bonus).div(100);
      }
      total_token_to_transfer = _tokens + bonus;
    }else if(phase_2_remaining_tokens > 0){
      if(_tokens > phase_2_remaining_tokens){
        uint256 tokens_from_phase_3 = _tokens.sub(phase_2_remaining_tokens);
        bonus = (phase_2_remaining_tokens.mul(phase_2_bonus).div(100)).add(tokens_from_phase_3.mul(phase_3_bonus).div(100));
        phase_2_remaining_tokens = 0;
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(tokens_from_phase_3);
      }else{
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_2_bonus).div(100);
      }
      total_token_to_transfer = _tokens + bonus;
    }else if(phase_3_remaining_tokens > 0){
      if(_tokens > phase_3_remaining_tokens){
        uint256 tokens_from_phase_4 = _tokens.sub(phase_3_remaining_tokens);
        bonus = (phase_3_remaining_tokens.mul(phase_3_bonus).div(100)).add(tokens_from_phase_4.mul(phase_4_bonus).div(100));
        phase_3_remaining_tokens = 0;
        phase_4_remaining_tokens = phase_4_remaining_tokens.sub(tokens_from_phase_4);
      }else{
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_3_bonus).div(100);
      }
      total_token_to_transfer = _tokens + bonus;
    }else if(phase_4_remaining_tokens > 0){
      if(_tokens > phase_4_remaining_tokens){
        uint256 tokens_from_phase_5 = _tokens.sub(phase_4_remaining_tokens);
        bonus = (phase_4_remaining_tokens.mul(phase_4_bonus).div(100)).add(tokens_from_phase_5.mul(phase_5_bonus).div(100));
        phase_4_remaining_tokens = 0;
        phase_5_remaining_tokens = phase_5_remaining_tokens.sub(tokens_from_phase_5);
      }else{
        phase_4_remaining_tokens = phase_4_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_4_bonus).div(100);
      }
      total_token_to_transfer = _tokens + bonus;
    }else if(phase_5_remaining_tokens > 0){
      if(_tokens > phase_5_remaining_tokens){
        total_token_to_transfer = 0;
      }else{
        phase_5_remaining_tokens = phase_5_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_5_bonus).div(100);
        total_token_to_transfer = _tokens + bonus;
      }
    }else{
      total_token_to_transfer = 0;
    }
    if(total_token_to_transfer > 0){
      token_reward.transfer(_beneficiary, total_token_to_transfer);
      TokenPurchase(msg.sender, _beneficiary, _weiAmount, total_token_to_transfer);
      return true;
    }else{
      return false;
    }
    
  }

  // fallback function can be used to buy tokens
  function () payable public{
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
    // calculate token amount to be created
    uint256 tokens = (weiAmount.mul(getRate())).div(10 ** uint256(10));
    // Check is there are enough token available for current phase and per person  
    require(transferIfTokenAvailable(tokens, weiAmount, beneficiary));
    // update state
    weiRaised = weiRaised.add(weiAmount);
    
    forwardFunds();
  }
  
  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > end_Time;
  }
  // function to transfer token back to owner
  function transferBack(uint256 tokens, address to_address) onlyOwner public returns (bool){
    token_reward.transfer(to_address, tokens);
    return true;
  }
  // function to change rate
  function changeEth_to_usd(uint256 _eth_to_usd) onlyOwner public returns (bool){
    EthToUsdChanged(msg.sender, eth_to_usd, _eth_to_usd);
    eth_to_usd = _eth_to_usd;
    return true;
  }
}