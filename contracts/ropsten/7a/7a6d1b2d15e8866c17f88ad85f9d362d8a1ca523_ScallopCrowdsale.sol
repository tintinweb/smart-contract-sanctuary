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
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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

 contract ScallopCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;
  
  // Hardcaps & Softcaps
  uint Hardcap = 30000000;
  uint Softcap = 5000000;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;


  // how many token units a buyer gets per eth
  uint256 public ratePerEth = 2000;

  // amount of raised money in wei
  uint256 public weiRaised;
  uint256 maxTokensToSaleInEachPhase;
  uint256 maxTokensToSale;
  
  uint256 public TOKENS_SOLD;
  

  uint256 bonusPercInPrivateSale;
  uint256 bonusPercInPreICO;
  uint256 bonusPercInFinalICO;
  
  
  bool isCrowdsalePaused = false;
  

  mapping(address=>uint)  tokensAgainstAddressPrivateSale;
  address[] usersAddressForPrivateSale;
  
  mapping(address=>uint)  tokensAgainstAddressPreICO;
  address[] usersAddressForPreICO;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function ScallopCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, address _tokenAddress) public 
  {
    //require(_startTime >=now);
    require(_wallet != 0x0);
    
    weiRaised=0;
    
    startTime = _startTime;  
    endTime = _endTime;
    //startTime = now;
    require(endTime >= startTime);
   
    owner = _wallet;

    bonusPercInPrivateSale = 30;
    bonusPercInPreICO= 20;
    bonusPercInFinalICO=0;
    
    
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

        //Private Sale
       if (timeElapsedInDays < 13) //12 days
        {
            bonus = tokens.mul(bonusPercInPrivateSale); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
        //PreICO Phase
        else if (timeElapsedInDays >= 13 && timeElapsedInDays < 25) //12 days
        {
            bonus = tokens.mul(bonusPercInPreICO); 
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
    require(msg.value>=1*10**17);
    
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value;
    uint weiAmountForTokens=0;
    uint256 tokens=0;
    uint256 bonus=0;

    // calculate token amount to be created
    weiAmountForTokens = weiAmount.div(10**(18-2));
    tokens = weiAmountForTokens.mul(ratePerEth);
    bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
    require(TOKENS_SOLD.add(tokens)<=maxTokensToSale);
    
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
        ratePerEth = newPrice;
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
     * send Tokens Manually
     **/ 
    function manualTransfer(address beneficiary, uint tokens) public onlyOwner {
        token.transfer(beneficiary,tokens);
    }
  
 }