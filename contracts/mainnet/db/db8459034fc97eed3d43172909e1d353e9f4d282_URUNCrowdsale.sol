pragma solidity 0.4.23;


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
  constructor() public {
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

 contract URUNCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;


  // how many token units a buyer gets per wei
  uint256 public ratePerWei = 800;

  // amount of raised money in wei
  uint256 public weiRaised;

  uint256 public TOKENS_SOLD;
  
  uint256 public minimumContributionPresalePhase1 = uint(2).mul(10 ** 18); //2 eth is the minimum contribution in presale phase 1
  uint256 public minimumContributionPresalePhase2 = uint(1).mul(10 ** 18); //1 eth is the minimum contribution in presale phase 2
  
  uint256 public maxTokensToSaleInClosedPreSale;
  
  uint256 public bonusInPreSalePhase1;
  uint256 public bonusInPreSalePhase2;
  
  bool public isCrowdsalePaused = false;
  
  uint256 public totalDurationInDays = 31 days;
  
  mapping(address=>bool) isAddressWhiteListed;
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    
    require(_wallet != 0x0);
    require(_startTime >=now);
    startTime = _startTime;  
    
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    maxTokensToSaleInClosedPreSale = 60000000 * 10 ** 18;
    bonusInPreSalePhase1 = 50;
    bonusInPreSalePhase2 = 40;
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
        
        //Closed pre-sale phase 1 (15 days)
        if (timeElapsedInDays <15)
        {
            bonus = tokens.mul(bonusInPreSalePhase1); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInClosedPreSale);
        }
        //Closed pre-sale phase 2 (16 days)
        else if (timeElapsedInDays >=15 && timeElapsedInDays <31)
        {
            bonus = tokens.mul(bonusInPreSalePhase2); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInClosedPreSale);
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
    require(isAddressWhiteListed[beneficiary]);
    require(validPurchase());
    
    require(isWithinContributionRange());
    
    require(TOKENS_SOLD<maxTokensToSaleInClosedPreSale);
   
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
    * function to change the end time and start time of the ICO
    * can only be called by owner wallet
    **/
    function changeStartAndEndDate (uint256 startTimeUnixTimestamp, uint256 endTimeUnixTimestamp) public onlyOwner
    {
        require (startTimeUnixTimestamp!=0 && endTimeUnixTimestamp!=0);
        require(endTimeUnixTimestamp>startTimeUnixTimestamp);
        require(endTimeUnixTimestamp.sub(startTimeUnixTimestamp) >=totalDurationInDays);
        startTime = startTimeUnixTimestamp;
        endTime = endTimeUnixTimestamp;
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
     * function to check whether the sent amount is within contribution range or not
     **/ 
    function isWithinContributionRange() internal constant returns (bool)
    {
        uint timePassed = now.sub(startTime);
        timePassed = timePassed.div(1 days);

        if (timePassed<15)
            require(msg.value>=minimumContributionPresalePhase1);
        else if (timePassed>=15 && timePassed<31)
            require(msg.value>=minimumContributionPresalePhase2);
        else
            revert();   // off time - no sales during other time periods
            
        return true;
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
      * function through which owner can transfer the tokens to any address
      * use this which to properly display the tokens that have been sold via ether or other payments
      **/ 
     function manualTokenTransfer(address receiver, uint value) public onlyOwner
     {
         token.transfer(receiver,value);
         TOKENS_SOLD = TOKENS_SOLD.add(value);
     }
     
     /**
      * Function to add a single address to whitelist
      * Can only be called by owner wallet address
      **/ 
     function addSingleAddressToWhitelist(address whitelistedAddr) public onlyOwner
     {
         isAddressWhiteListed[whitelistedAddr] = true;
     }
     
     /**
      * Function to add multiple addresses to whitelist
      * Can only be called by owner wallet address
      **/ 
     function addMultipleAddressesToWhitelist(address[] whitelistedAddr) public onlyOwner
     {
         for (uint i=0;i<whitelistedAddr.length;i++)
         {
            isAddressWhiteListed[whitelistedAddr[i]] = true;
         }
     }
     
     /**
      * Function to remove an address from whitelist 
      * Can only be called by owner wallet address 
      **/ 
     function removeSingleAddressFromWhitelist(address whitelistedAddr) public onlyOwner
     {
         isAddressWhiteListed[whitelistedAddr] = false;
     }
     
     /**
     * Function to remove multiple addresses from whitelist 
     * Can only be called by owner wallet address 
     **/ 
     function removeMultipleAddressesFromWhitelist(address[] whitelistedAddr) public onlyOwner
     {
        for (uint i=0;i<whitelistedAddr.length;i++)
         {
            isAddressWhiteListed[whitelistedAddr[i]] = false;
         }
     }
     
     /**
      * Function to check if an address is whitelisted 
      **/ 
     function checkIfAddressIsWhiteListed(address whitelistedAddr) public view returns (bool)
     {
         return isAddressWhiteListed[whitelistedAddr];
     }
}