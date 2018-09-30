pragma solidity 0.4.24;


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

 contract EzeCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;


  // how many token units a buyer gets per wei
  uint256 public ratePerWeiInSelfDrop = 60000;
  uint256 public ratePerWeiInPrivateSale = 30000;
  uint256 public ratePerWeiInPreICO = 6000;
  uint256 public ratePerWeiInMainICO = 5000;

  // amount of raised money in wei
  uint256 public weiRaised;

  uint256 public TOKENS_SOLD;
  
  uint256 maxTokensToSale;
  
  uint256 bonusInSelfDrop = 20;
  uint256 bonusInPrivateSale = 10;
  uint256 bonusInPreICO = 5;
  uint256 bonusInMainICO = 2;
  
  bool isCrowdsalePaused = false;
  
  uint256 totalDurationInDays = 213 days;
  
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
    require(_startTime >=now);
    require(_wallet != 0x0);

    startTime = _startTime;  
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    maxTokensToSale = uint(15000000000).mul( 10 ** uint256(18));
   
    token = TokenInterface(_tokenAddress);
  }
  
  
   // fallback function can be used to buy tokens
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function calculateTokens(uint value) internal view returns (uint256 tokens) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        uint256 bonus = 0;
        //Phase 1 (30 days)
        if (timeElapsedInDays <30)
        {
            tokens = value.mul(ratePerWeiInSelfDrop);
            bonus = tokens.mul(bonusInSelfDrop); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
        //Phase 2 (31 days)
        else if (timeElapsedInDays >=30 && timeElapsedInDays <61)
        {
            tokens = value.mul(ratePerWeiInPrivateSale);
            bonus = tokens.mul(bonusInPrivateSale); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
       
        //Phase 3 (30 days)
        else if (timeElapsedInDays >=61 && timeElapsedInDays <91)
        {
            tokens = value.mul(ratePerWeiInPreICO);
            bonus = tokens.mul(bonusInPreICO); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
        
        //Phase 4 (122 days)
        else if (timeElapsedInDays >=91 && timeElapsedInDays <213)
        {
            tokens = value.mul(ratePerWeiInMainICO);
            bonus = tokens.mul(bonusInMainICO); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
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

    
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value;
    
    uint256 tokens = calculateTokens(weiAmount);
    
    // update state
    weiRaised = weiRaised.add(msg.value);
    
    token.transfer(beneficiary,tokens);
    emit TokenPurchase(owner, beneficiary, msg.value, tokens);
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
     
     function takeTokensBack() public onlyOwner
     {
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(owner,remainingTokensInTheContract);
     }
}