pragma solidity ^0.4.11;

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

contract token {
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
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

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale100 is Ownable {
  using SafeMath for uint256;

  // The token being sold
  token myToken;

  uint256 public phase_1_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_2_remaining_tokens  = 5000000 * (10 ** uint256(18));
  uint256 public phase_3_remaining_tokens  = 10500000 * (10 ** uint256(18));

  uint256 public phase_1_remaining_bonus_tokens  = 150000 * (10 ** uint256(18));
  uint256 public phase_2_remaining_bonus_tokens  = 400000 * (10 ** uint256(18));
  uint256 public phase_3_remaining_bonus_tokens  = 315000 * (10 ** uint256(18));
  
  
  // address where funds are collected
  address public wallet;

  // phase wise bonus
  uint256 public phase_1_bonus = 15;
  uint256 public phase_2_bonus = 8;
  uint256 public phase_3_bonus = 3;
  
  // rate => tokens per ether
  uint256 public rate = 440; // its 1.20 per token as 1 ETH is 528

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);


  constructor(address tokenContractAddress, address _walletAddress) public{
    wallet = _walletAddress;
    myToken = token(tokenContractAddress);
  }

  // fallback function can be used to buy tokens
  function () payable public{
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(msg.value != 0);

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // Check is there are enough token available for current phase
    require(isTokenAvailable(tokens));

    uint256 tokens_to_transfer = calculateAndDecreasePhaseSupply(tokens);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    myToken.transfer(beneficiary, tokens_to_transfer);

    emit TokenPurchase(beneficiary, weiAmount, tokens_to_transfer);

    forwardFunds();
  }

  // decrease phase supply
  function calculateAndDecreasePhaseSupply(uint256 _tokens) internal returns (uint256){
    uint256 bonus = 0;
    uint256 tokens_from_phase_2 = 0;
    uint256 phase_2_bonus_tokens = 0;
    uint256 phase_3_bonus_tokens = 0;
    
    if(phase_1_remaining_tokens > 0){
      if(phase_1_remaining_tokens >= _tokens){
        phase_1_remaining_tokens = phase_1_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_1_bonus).div(100);
        phase_1_remaining_bonus_tokens = phase_1_remaining_bonus_tokens.sub(bonus);
        return _tokens.add(bonus);
      }else{
        uint256 tokens_from_phase_1 = phase_1_remaining_tokens;
        tokens_from_phase_2 = _tokens.sub(tokens_from_phase_1);
        
        phase_1_remaining_tokens = 0;
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(tokens_from_phase_2);

        uint256 phase_1_bonus_tokens = tokens_from_phase_1.mul(phase_1_bonus).div(100);
        phase_1_remaining_bonus_tokens = phase_1_remaining_bonus_tokens.sub(phase_1_bonus_tokens);

        phase_2_bonus_tokens = tokens_from_phase_2.mul(phase_2_bonus).div(100);
        phase_2_remaining_bonus_tokens = phase_2_remaining_bonus_tokens.sub(phase_2_bonus_tokens);

        return _tokens.add(phase_1_bonus_tokens).add(phase_2_bonus_tokens);
      }
    }else if(phase_2_remaining_tokens > 0){
      if(phase_2_remaining_tokens >= _tokens){
        phase_2_remaining_tokens = phase_2_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_2_bonus).div(100);
        phase_2_remaining_bonus_tokens = phase_2_remaining_bonus_tokens.sub(bonus);
        return _tokens.add(bonus);
      }else{
        tokens_from_phase_2 = phase_2_remaining_tokens;
        uint256 tokens_from_phase_3 = _tokens.sub(phase_2_remaining_tokens);
        
        phase_2_remaining_tokens = 0;
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(tokens_from_phase_3);

        phase_2_bonus_tokens = tokens_from_phase_2.mul(phase_2_bonus).div(100);
        phase_2_remaining_bonus_tokens = phase_2_remaining_bonus_tokens.sub(phase_2_bonus_tokens);

        phase_3_bonus_tokens = tokens_from_phase_3.mul(phase_3_bonus).div(100);
        phase_3_remaining_bonus_tokens = phase_3_remaining_bonus_tokens.sub(phase_3_bonus_tokens);

        return _tokens.add(phase_2_bonus_tokens).add(phase_3_bonus_tokens);
      }
    }else if(phase_3_remaining_tokens > 0){
      if(phase_3_remaining_tokens >= _tokens){
        phase_3_remaining_tokens = phase_3_remaining_tokens.sub(_tokens);
        bonus = _tokens.mul(phase_3_bonus).div(100);
        phase_3_remaining_bonus_tokens = phase_3_remaining_bonus_tokens.sub(bonus);
        return _tokens.add(bonus);
      }
    }
  }

  // to change rate
  function updateRate(uint256 new_rate) public{
    rate = new_rate;
  }


  // check token availibility  
  function isTokenAvailable(uint256 _tokens) internal constant returns (bool){
    uint256 total_remaining_tokens = phase_1_remaining_tokens.add(phase_2_remaining_tokens).add(phase_3_remaining_tokens);
    return total_remaining_tokens >= _tokens;
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function transferBackTo(uint256 tokens, address beneficiary) onlyOwner public returns (bool){
    myToken.transfer(beneficiary, tokens);
    return true;
  }

}