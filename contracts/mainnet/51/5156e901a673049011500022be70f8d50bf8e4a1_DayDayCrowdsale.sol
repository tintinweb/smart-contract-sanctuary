pragma solidity ^0.4.19;


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
     function lockTokensForFs (address F1, address F2) external;
     function lockTokensForAs( address A1, address A2, address A3, address A4, address A5, address A6, address A7, address A8, address A9) external;
     function lockTokensForCs(address C1,address C2, address C3) external;
     function lockTokensForTeamAndReserve(address team) external;
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     event Burn(address indexed burner, uint256 value);
}

 contract DayDayCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;


  // how many token units a buyer gets per wei
  uint256 public ratePerWei = 50000;

  // amount of raised money in wei
  uint256 public weiRaised;

  uint256 TOKENS_SOLD;
  
  uint256 minimumContributionPrivate = 10 * 10 ** 18; //10 eth is the minimum contribution in private investment phase
  uint256 maximumContributionPrivate = 200 * 10 ** 18; //200 eth is the maximum contribution in private investment phase
  
  uint256 minimumContributionPublic = 1 * 10 ** 18; //1 eth is the minimum contribution in public investment phase
  uint256 maximumContributionPublic = 10 * 10 ** 18; //10 eth is the maximum contribution in public investment phase
  
  uint256 maxTokensToSaleInPrivateSeedPhase1;
  uint256 maxTokensToSaleInPrivateSeedPhase2;
  uint256 maxTokensToSaleInSyndicagteSeed; 
  uint256 maxTokensToSaleInPreITOPublic;
  uint256 maxTokensToSaleInITOPublicPhase1;
  uint256 maxTokensToSaleInITOPublicPhase2;
  uint256 maxTokensToSaleInITOPublicPhase3;
  uint256 maxTokensToSale;
  
  uint256 bonusInPrivateSeedPhase1;
  uint256 bonusInPrivateSeedPhase2;
  uint256 bonusInSyndicagteSeed; 
  uint256 bonusInPreITOPublic;
  uint256 bonusInITOPublicPhase1;
  uint256 bonusInITOPublicPhase2;
  uint256 bonusInITOPublicPhase3;
  
  bool isCrowdsalePaused = false;
  
  uint256 softCap;
  uint256 hardCap;
  
  mapping(address=>uint256) amountSentByBuyers; 
  bool refundToBuyers = false;
  uint256 totalDurationInDays = 166 days;
  uint256 decimals = 2;
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function DayDayCrowdsale(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    require(_startTime >=now);
    require(_wallet != 0x0);

    startTime = _startTime;  
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    softCap = 3860*10**18;
    hardCap = 23000*10**18;
    
    maxTokensToSaleInPrivateSeedPhase1 = 199500000 * 10 ** uint256(decimals);
    maxTokensToSaleInPrivateSeedPhase2 = 388500000 * 10 ** uint256(decimals);
    maxTokensToSaleInSyndicagteSeed = 924000000 * 10 ** uint256(decimals); 
    maxTokensToSaleInPreITOPublic = 1396500000 * 10 ** uint256(decimals);
    maxTokensToSaleInITOPublicPhase1 = 1790250000 * 10 ** uint256(decimals);
    maxTokensToSaleInITOPublicPhase2 = 2294250000 * 10 ** uint256(decimals);
    maxTokensToSaleInITOPublicPhase3 = 2898000000 * 10 ** uint256(decimals);
    maxTokensToSale = 3000000000 * 10 ** uint256(decimals);

    bonusInPrivateSeedPhase1 = 90;
    bonusInPrivateSeedPhase2 = 80;
    bonusInSyndicagteSeed = 70; 
    bonusInPreITOPublic = 50;
    bonusInITOPublicPhase1 = 25;
    bonusInITOPublicPhase2 = 20;
    bonusInITOPublicPhase3 = 15;
    
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
        
        //private seed phase 1 (5 days)
        if (timeElapsedInDays <5)
        {
            //bonus application of private seed phase 1
            if (TOKENS_SOLD <maxTokensToSaleInPrivateSeedPhase1)
            {
                bonus = tokens.mul(bonusInPrivateSeedPhase1); 
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPrivateSeedPhase1);
            }
            
            //bonus application of private seed phase 2
            else if (TOKENS_SOLD >= maxTokensToSaleInPrivateSeedPhase1 && TOKENS_SOLD < maxTokensToSaleInPrivateSeedPhase2)
            {
                bonus = tokens.mul(bonusInPrivateSeedPhase2);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPrivateSeedPhase2);
            } 
            
            //bonus application of SyndicagteSeed
            else if (TOKENS_SOLD >= maxTokensToSaleInPrivateSeedPhase2 && TOKENS_SOLD < maxTokensToSaleInSyndicagteSeed)
            {
                bonus = tokens.mul(bonusInSyndicagteSeed);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInSyndicagteSeed);
            }
            
            //bonus application of PreITOPublic phase
            else if (TOKENS_SOLD >= maxTokensToSaleInSyndicagteSeed && TOKENS_SOLD < maxTokensToSaleInPreITOPublic)
            {
                bonus = tokens.mul(bonusInPreITOPublic);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreITOPublic);
            }
            
            //bonus application of ITOPublic phase 1
            else if (TOKENS_SOLD >= maxTokensToSaleInPreITOPublic && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase1)
            {
                bonus = tokens.mul(bonusInITOPublicPhase1);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase1);
            }
            
            //bonus application of ITOPublic phase 2
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase1 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase2)
            {
                bonus = tokens.mul(bonusInITOPublicPhase2);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase2);
            }
            
            //bonus application of ITOPublic phase 3
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase2 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase3)
            {
                bonus = tokens.mul(bonusInITOPublicPhase3);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase3);
            }
            else 
            {
                bonus = 0;
            }
        }
        
        //private seed phase 2 (10 days)
        else if (timeElapsedInDays >= 5 && timeElapsedInDays <16)
        {
            //bonus application of private seed phase 2
            if (TOKENS_SOLD >= maxTokensToSaleInPrivateSeedPhase1 && TOKENS_SOLD < maxTokensToSaleInPrivateSeedPhase2)
            {
                bonus = tokens.mul(bonusInPrivateSeedPhase2);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPrivateSeedPhase2);
            } 
            
            //bonus application of SyndicagteSeed
            else if (TOKENS_SOLD >= maxTokensToSaleInPrivateSeedPhase2 && TOKENS_SOLD < maxTokensToSaleInSyndicagteSeed)
            {
                bonus = tokens.mul(bonusInSyndicagteSeed);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInSyndicagteSeed);
            }
            
            //bonus application of PreITOPublic phase
            else if (TOKENS_SOLD >= maxTokensToSaleInSyndicagteSeed && TOKENS_SOLD < maxTokensToSaleInPreITOPublic)
            {
                bonus = tokens.mul(bonusInPreITOPublic);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreITOPublic);
            }
            
            //bonus application of ITOPublic phase 1
            else if (TOKENS_SOLD >= maxTokensToSaleInPreITOPublic && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase1)
            {
                bonus = tokens.mul(bonusInITOPublicPhase1);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase1);
            }
            
            //bonus application of ITOPublic phase 2
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase1 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase2)
            {
                bonus = tokens.mul(bonusInITOPublicPhase2);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase2);
            }
            
            //bonus application of ITOPublic phase 3
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase2 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase3)
            {
                bonus = tokens.mul(bonusInITOPublicPhase3);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase3);
            }
            else 
            {
                bonus = 0;
            }
        }
        
        //Syndicagte phase (19 days) 
        else if (timeElapsedInDays >= 16 && timeElapsedInDays<36)
        {
            //bonus application of SyndicagteSeed
            if (TOKENS_SOLD >= maxTokensToSaleInPrivateSeedPhase2 && TOKENS_SOLD < maxTokensToSaleInSyndicagteSeed)
            {
                bonus = tokens.mul(bonusInSyndicagteSeed);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInSyndicagteSeed);
            }
            
            //bonus application of PreITOPublic phase
            else if (TOKENS_SOLD >= maxTokensToSaleInSyndicagteSeed && TOKENS_SOLD < maxTokensToSaleInPreITOPublic)
            {
                bonus = tokens.mul(bonusInPreITOPublic);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreITOPublic);
            }
            
            //bonus application of ITOPublic phase 1
            else if (TOKENS_SOLD >= maxTokensToSaleInPreITOPublic && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase1)
            {
                bonus = tokens.mul(bonusInITOPublicPhase1);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase1);
            }
            
            //bonus application of ITOPublic phase 2
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase1 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase2)
            {
                bonus = tokens.mul(bonusInITOPublicPhase2);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase2);
            }
            
            //bonus application of ITOPublic phase 3
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase2 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase3)
            {
                bonus = tokens.mul(bonusInITOPublicPhase3);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase3);
            }
            else 
            {
                bonus = 0;
            }
        }
        
        // Pause before the public phases
        else if (timeElapsedInDays >= 36 && timeElapsedInDays<103)
        {
            //67 days break
            revert();  //no sale during this time, so revert this transaction
        }
        
        // Pre-ITO public phase (5 days)
        else if (timeElapsedInDays >= 103 && timeElapsedInDays<109)
        {
            //bonus application of PreITOPublic phase
            if (TOKENS_SOLD >= maxTokensToSaleInSyndicagteSeed && TOKENS_SOLD < maxTokensToSaleInPreITOPublic)
            {
                bonus = tokens.mul(bonusInPreITOPublic);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreITOPublic);
            }
            
            //bonus application of ITOPublic phase 1
            else if (TOKENS_SOLD >= maxTokensToSaleInPreITOPublic && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase1)
            {
                bonus = tokens.mul(bonusInITOPublicPhase1);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase1);
            }
            
            //bonus application of ITOPublic phase 2
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase1 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase2)
            {
                bonus = tokens.mul(bonusInITOPublicPhase2);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase2);
            }
            
            //bonus application of ITOPublic phase 3
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase2 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase3)
            {
                bonus = tokens.mul(bonusInITOPublicPhase3);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase3);
            }
            else 
            {
                bonus = 0;
            }
        }
        
        // Public ITO phase 1 (15 days)
        else if (timeElapsedInDays >= 109 && timeElapsedInDays<125)
        {
            //bonus application of ITOPublic phase 1
            if (TOKENS_SOLD >= maxTokensToSaleInPreITOPublic && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase1)
            {
                bonus = tokens.mul(bonusInITOPublicPhase1);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase1);
            }
            
            //bonus application of ITOPublic phase 2
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase1 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase2)
            {
                bonus = tokens.mul(bonusInITOPublicPhase2);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase2);
            }
            
            //bonus application of ITOPublic phase 3
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase2 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase3)
            {
                bonus = tokens.mul(bonusInITOPublicPhase3);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase3);
            }
            else 
            {
                bonus = 0;
            }
        }
        
        // Public ITO phase 2 (20 days)
        else if (timeElapsedInDays >= 125 && timeElapsedInDays<146)
        {
            //bonus application of ITOPublic phase 2
            if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase1 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase2)
            {
                bonus = tokens.mul(bonusInITOPublicPhase2);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase2);
            }
            
            //bonus application of ITOPublic phase 3
            else if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase2 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase3)
            {
                bonus = tokens.mul(bonusInITOPublicPhase3);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase3);
            }
            else 
            {
                bonus = 0;
            }
        }
        
        // Public ITO phase 3 (20 days)
        else if (timeElapsedInDays >= 146 && timeElapsedInDays<167)
        {
            //bonus application of ITOPublic phase 3
            if (TOKENS_SOLD >= maxTokensToSaleInITOPublicPhase2 && TOKENS_SOLD < maxTokensToSaleInITOPublicPhase3)
            {
                bonus = tokens.mul(bonusInITOPublicPhase3);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInITOPublicPhase3);
            }
            else 
            {
                bonus = 0;
            }
        }
        
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
    
    if (isPrivateInvestmentPhase())
        require(msg.value>= minimumContributionPrivate && msg.value<=maximumContributionPrivate);
    else
        require(msg.value>= minimumContributionPublic && msg.value<=maximumContributionPublic);
    
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value;
    
    // calculate token amount to be created
    uint weiAmountForTokens = weiAmount.div(10**16);
    uint256 tokens = weiAmountForTokens.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
    require(TOKENS_SOLD.add(tokens)<=maxTokensToSale);
    
    // update state
    weiRaised = weiRaised.add(weiAmount);
    
    token.transfer(beneficiary,tokens);
    amountSentByBuyers[beneficiary] = weiAmount;
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
    
    function changeMinimumContributionForPrivatePhase(uint256 minContribution) public onlyOwner{
        minimumContributionPrivate = minContribution.mul(10 ** 15);
    }
    
    function changeMinimumContributionForPublicPhase(uint256 minContribution) public onlyOwner{
        minimumContributionPublic = minContribution.mul(10 ** 15);
    }
    
     function changeMaximumContributionForPrivatePhase(uint256 minContribution) public onlyOwner{
        maximumContributionPrivate = minContribution.mul(10 ** 15);
    }
    
     function changeMaximumContributionForPublicPhase(uint256 minContribution) public onlyOwner{
        maximumContributionPublic = minContribution.mul(10 ** 15);
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
     * function to change the soft cap of the contract 
     **/
    function changeSoftCap(uint256 softCapEthers) public onlyOwner
    {
        softCap = softCapEthers.mul(10**18);
    }
    
    /**
     * function to change the hard cap of the contract 
     **/
    function changeHardCap(uint256 hardCapEthers) public onlyOwner
    {
        hardCap = hardCapEthers.mul(10**18);
    }
     
     // ------------------------------------------------------------------------
     // Remaining tokens for sale
     // ------------------------------------------------------------------------
     function remainingTokensForSale() public constant returns (uint) {
         return maxTokensToSale.sub(TOKENS_SOLD);
     }
    
     function isPrivateInvestmentPhase() internal constant returns (bool)
     {
         uint timePassed = now.sub(startTime);
         if (timePassed<=30 days)
            return true;
        return false;
     }
     
     function burnUnsoldTokens() public onlyOwner 
     {
         require(hasEnded());
         uint value = remainingTokensForSale();
         token.burn(value);
         TOKENS_SOLD = maxTokensToSale;
     }
    
     function tokensAllocatedForFs(address F1, address F2) public onlyOwner
     {
         token.transfer(F1,90000000 * 10 ** uint256(decimals));
         token.transfer(F2,60000000 * 10 ** uint256(decimals));
         token.lockTokensForFs(F1,F2);
         
     }
     function tokensAllocatedForAs( address A1, address A2, 
                                    address A3, address A4,
                                    address A5, address A6,
                                    address A7, address A8,
                                    address A9) public onlyOwner
     {
         token.transfer(A1,90000000 * 10 ** uint256(decimals));
         token.transfer(A2,60000000 * 10 ** uint256(decimals));
         token.transfer(A3,30000000 * 10 ** uint256(decimals));
         token.transfer(A4,60000000 * 10 ** uint256(decimals));
         token.transfer(A5,60000000 * 10 ** uint256(decimals));
         token.transfer(A6,15000000 * 10 ** uint256(decimals));
         token.transfer(A7,15000000 * 10 ** uint256(decimals));
         token.transfer(A8,15000000 * 10 ** uint256(decimals));
         token.transfer(A9,15000000 * 10 ** uint256(decimals));
         token.lockTokensForAs(A1,A2,A3,A4,A5,A6,A7,A8,A9);
     }
     function tokensAllocatedForCs(address C1, address C2, address C3) public onlyOwner
     {
         token.transfer(C1,2500000 * 10 ** uint256(decimals));
         token.transfer(C2,1000000 * 10 ** uint256(decimals));
         token.transfer(C3,1500000 * 10 ** uint256(decimals));
         token.lockTokensForCs(C1,C2,C3);
     }
      function tokensAllocatedForTeamAndReserve(address team) public onlyOwner
     {
         token.transfer(team,63000000 * 10 ** uint256(decimals));
         token.lockTokensForTeamAndReserve(team);
     }
     
     function refundToBuyersIfSoftCapNotReached() public payable onlyOwner
     {
         require(hasEnded());
         require(weiRaised<softCap);
         require(msg.value>=weiRaised);
         refundToBuyers = true;
     }
     
     function getRefund() public 
     {
         require(refundToBuyers == true);
         if (amountSentByBuyers[msg.sender] > 0)
            msg.sender.transfer(amountSentByBuyers[msg.sender]);
     }
}