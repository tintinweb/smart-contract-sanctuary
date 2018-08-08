pragma solidity ^0.4.21;


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

interface TokenInterface {
     function totalSupply() external constant returns (uint);
     function balanceOf(address tokenOwner) external constant returns (uint balance);
     function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
     function transfer(address to, uint tokens) external returns (bool success);
     function approve(address spender, uint tokens) external returns (bool success);
     function transferFrom(address from, address to, uint tokens) external returns (bool success);
     function burn(uint256 _value) external; 
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     event Burn(address indexed burner, uint256 value);
}

 contract PVCCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;


  // how many token units a buyer gets per wei
  uint256 public ratePerWei = 1000;

  // amount of raised money in wei
  uint256 public weiRaised;

  uint256 public TOKENS_SOLD;
  
  uint256 maxTokensToSale;
  uint256 TokensForTeamVesting;
  uint256 TokensForAdvisorVesting;
  uint256 bonusInPreSalePhase1;
  uint256 bonusInPreSalePhase2;
  uint256 bonusInPublicSalePhase1;
  uint256 bonusInPublicSalePhase2;
  uint256 bonusInPublicSalePhase3;
  uint256 bonusInPublicSalePhase4;
  uint256 bonusInPublicSalePhase5;
  uint256 bonusInPublicSalePhase6;
  
  bool isCrowdsalePaused = false;
  
  uint256 totalDurationInDays = 145 days;
  mapping(address=>bool) isAddressWhiteListed;
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function PVCCrowdsale(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    
    require(_wallet != 0x0);
    startTime = _startTime;  
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    maxTokensToSale = 32500000 * 10 ** 18;
    TOKENS_SOLD = 346018452900000000000;    // the tokens that have been sold through the previous contract
                   
    weiRaised = 285373570000000000;     // the weis that have been raised through the previous contract

    bonusInPreSalePhase1 = 30;
    bonusInPreSalePhase2 = 25;
    bonusInPublicSalePhase1 = 20;
    bonusInPublicSalePhase2 = 25;
    bonusInPublicSalePhase3 = 20;
    bonusInPublicSalePhase4 = 15;
    bonusInPublicSalePhase5 = 10;
    bonusInPublicSalePhase6 = 5;
    
    TokensForTeamVesting = 7000000 * 10 ** 18;
    TokensForAdvisorVesting = 3000000 * 10 ** 18;
    token = TokenInterface(_tokenAddress);
  }
  
  
   // fallback function can be used to buy tokens
   function () public  payable {
     buyTokens(msg.sender);
    }
    
  function determineBonus(uint tokens) internal view returns (uint256 bonus) 
  {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        
        //Closed pre-sale phase 1 (8 days starting apr 9)
        if (timeElapsedInDays <8)
        {
            bonus = tokens.mul(bonusInPreSalePhase1); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        //Closed pre-sale phase 2 (8 days starting apr 17)
        else if (timeElapsedInDays >=8 && timeElapsedInDays <16)
        {
            bonus = tokens.mul(bonusInPreSalePhase2); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        //Public sale phase 1 original (30 days starting on apr 25)
        //Public sale phase 1 new (10 days ending may 4)
        else if (timeElapsedInDays >=16 && timeElapsedInDays <26)
        {
            bonus = tokens.mul(bonusInPublicSalePhase1); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }

        //Public sale phase 2 (27 days)
        else if (timeElapsedInDays >=26 && timeElapsedInDays <53)
        {
            bonus = tokens.mul(bonusInPublicSalePhase2); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }

         //Public sale phase 3 (30 days)
        else if (timeElapsedInDays >=53 && timeElapsedInDays <83)
        {
            bonus = tokens.mul(bonusInPublicSalePhase3); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        //Public sale phase 4 (15 days)
        else if (timeElapsedInDays >=83 && timeElapsedInDays <98)
        {
            bonus = tokens.mul(bonusInPublicSalePhase4); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        //Public sale phase 5 (16 days)
        else if (timeElapsedInDays >=98 && timeElapsedInDays <114)
        {
            bonus = tokens.mul(bonusInPublicSalePhase5); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        //Public sale phase 6 (31 days)
        else if (timeElapsedInDays >=114 && timeElapsedInDays <145)
        {
            bonus = tokens.mul(bonusInPublicSalePhase6); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        //
        else 
        {
            bonus = 0;
        }


    }
  // low level token purchase function
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(validPurchase());
    
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value;
    
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
    
    // update state
    weiRaised = weiRaised.add(weiAmount);
    
    token.transfer(beneficiary,tokens);
    emit TokenPurchase(owner, beneficiary, weiAmount, tokens);
    TOKENS_SOLD = TOKENS_SOLD.add(tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
  
   /**
    * function to change the end timestamp of the ico
    * can only be called by owner wallet
    **/
    function changeEndDate(uint256 endTimeUnixTimestamp) public onlyOwner{
        endTime = endTimeUnixTimestamp;
    }
    
    /**
    * function to change the start timestamp of the ico
    * can only be called by owner wallet
    **/
    
    function changeStartDate(uint256 startTimeUnixTimestamp) public onlyOwner{
        startTime = startTimeUnixTimestamp;
    }
    
    /**
    * function to change the rate of tokens
    * can only be called by owner wallet
    **/
    function setPriceRate(uint256 newPrice) public onlyOwner {
        ratePerWei = newPrice;
    }
    
     /**
     * function to pause the crowdsale 
     * can only be called from owner wallet
     **/
     
    function pauseCrowdsale() public onlyOwner {
        isCrowdsalePaused = true;
    }

    /**
     * function to resume the crowdsale if it is paused
     * can only be called from owner wallet
     **/ 
    function resumeCrowdsale() public onlyOwner {
        isCrowdsalePaused = false;
    }
    
     /**
      * function through which owner can take back the tokens from the contract
      **/ 
     function takeTokensBack() public onlyOwner
     {
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(owner,remainingTokensInTheContract);
     }
     
     /**
      * once the ICO has ended, owner can send all the unsold tokens to treasury address 
      **/ 
     function sendUnsoldTokensToTreasury(address treasury) public onlyOwner
     {
         require(hasEnded());
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(treasury,remainingTokensInTheContract);
     }
}