pragma solidity ^0.4.23;


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

 contract EthereumTravelCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;
  
  // Hardcaps & Softcaps
  uint Hardcap = 100000;
  uint Softcap = 10000;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;


  // how many token units a buyer gets per wei
  uint256 public ratePerWei = 10000;

  // amount of raised money in wei
  uint256 public weiRaised;
  uint256 public weiRaisedInPreICO;
  uint256 maxTokensToSale;
  
  uint256 public TOKENS_SOLD;
  

  uint256 bonusPercInICOPhase1;
  uint256 bonusPercInICOPhase2;
  uint256 bonusPercInICOPhase3;
  
  bool isCrowdsalePaused = false;
  
  uint256 totalDurationInDays = 57 days;
  
  mapping(address=>uint)  EthSentAgainstAddress;
  address[] usersAddressForPreICO;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function EthereumTravelCrowdsale(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    //require(_startTime >=now);
    require(_wallet != 0x0);
    
    weiRaised=0;
    weiRaisedInPreICO=0;
    startTime = _startTime;  
    //startTime = now;
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;

    bonusPercInICOPhase1 = 30;
    bonusPercInICOPhase2 = 20;
    bonusPercInICOPhase3 = 10;
    
    token = TokenInterface(_tokenAddress);
    maxTokensToSale=(token.totalSupply().mul(60)).div(100);
    
  }
  
  
   // fallback function can be used to buy tokens
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function determineBonus(uint tokens) internal view returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);

        //Pre ICO Phase ( June 05 - 15 i.e. 11 days)
       if (timeElapsedInDays <12)
        {
            bonus = 0;
        }
        //Break ( June 16 - July 30 i.e. 10 days)
      else if (timeElapsedInDays >= 12 && timeElapsedInDays <27)
        {
            revert();
        }
        
        //ICO phase 1 ( July 1 - July 10 i.e. 10 days)
        else if (timeElapsedInDays >= 27 && timeElapsedInDays <37)
        {
            bonus = tokens.mul(bonusPercInICOPhase1); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        
        //ICO phase 2 ( July 11- July 20 i.e. 10 days)
        else if (timeElapsedInDays >= 37 && timeElapsedInDays<47)
        {
            bonus = tokens.mul(bonusPercInICOPhase2); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        
        //ICO phase 3 ( July 21- July 30 i.e. 10 days)
        else if (timeElapsedInDays >= 47 && timeElapsedInDays<57)
        {
            bonus = tokens.mul(bonusPercInICOPhase3); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
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
    require(msg.value>=1*10**18);
    
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value;
    uint256 timeElapsed = now - startTime;
    uint256 timeElapsedInDays = timeElapsed.div(1 days);

        //Pre ICO Phase ( June 05 - 15 i.e. 11 days)
       if (timeElapsedInDays <12)
        {
            require(usersAddressForPreICO.length<=5000);
            // checks if the user is sending eths the firt time
            if(EthSentAgainstAddress[beneficiary]==0)
            {
                usersAddressForPreICO.push(beneficiary);
            }
            EthSentAgainstAddress[beneficiary]+=weiAmount; 
            // update state
            weiRaised = weiRaised.add(weiAmount);
            weiRaisedInPreICO = weiRaisedInPreICO.add(weiAmount);
            forwardFunds();
        }
        //Break ( June 16 - July 30 i.e. 15 days)
      else if (timeElapsedInDays >= 12 && timeElapsedInDays <27)
        {
            revert();
        }
      else {
          
           // calculate token amount to be created
            uint256 tokens = weiAmount.mul(ratePerWei);
            uint256 bonus = determineBonus(tokens);
            tokens = tokens.add(bonus);
            require(TOKENS_SOLD.add(tokens)<=maxTokensToSale);
            
            // update state
            weiRaised = weiRaised.add(weiAmount);
            
            token.transfer(beneficiary,tokens);
            emit TokenPurchase(owner, beneficiary, weiAmount, tokens);
            TOKENS_SOLD = TOKENS_SOLD.add(tokens);
            forwardFunds();
        
       }
   
  
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
        changeEndDate(startTime+totalDurationInDays);
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
    
  
     
     // ------------------------------------------------------------------------
     // Remaining tokens for sale
     // ------------------------------------------------------------------------
     function remainingTokensForSale() public constant returns (uint) {
         return maxTokensToSale.sub(TOKENS_SOLD);
     }
    
     
     function burnUnsoldTokens() public onlyOwner 
     {
         require(hasEnded());
         uint value = remainingTokensForSale();
         token.burn(value);
         TOKENS_SOLD = maxTokensToSale;
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
     * send PreICO bonus tokens in bulk to 5000 addresses
     **/ 
    function BulkTransfer() public onlyOwner {
        for(uint i = 0; i<usersAddressForPreICO.length; i++)
        {
            uint tks=(EthSentAgainstAddress[usersAddressForPreICO[i]].mul(1000000000*10**18)).div(weiRaisedInPreICO);            
            token.transfer(usersAddressForPreICO[i],tks);
        }
    }
 }