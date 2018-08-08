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
     function addPrivateSaleBuyer(address buyer,uint value) external;
     function addPreSaleBuyer(address buyer,uint value) external;
     function addPrivateSaleEndDate(uint256 endDate) external;
     function addPreSaleEndDate(uint256 endDate) external;
     function addICOEndDate(uint256 endDate) external;
     function addTeamAndAdvisoryMembers(address[] members) external;
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     event Burn(address indexed burner, uint256 value);
}

 contract FeedCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;


  // how many token units a buyer gets per wei
  uint256 public ratePerWei = 11905;

  // amount of raised money in wei
  uint256 public weiRaised;
  
  uint256 public weiRaisedInPreICO;

  uint256 TOKENS_SOLD;

  uint256 maxTokensToSaleInPrivateSale;
  uint256 maxTokensToSaleInPreICO;
  uint256 maxTokensToSale;
  
  uint256 bonusInPrivateSale;

  bool isCrowdsalePaused = false;
  
  uint256 minimumContributionInPrivatePhase;
  uint256 minimumContributionInPreICO;
  uint256 maximumContributionInPreICO;
  uint256 maximumContributionInMainICO;
  
  uint256 totalDurationInDays = 112 days;
  uint256 decimals = 18;
  
  uint256 hardCap = 46200 ether;
  uint256 softCapForPreICO = 1680 ether;
  
  address[] tokenBuyers;
  
  mapping(address=>uint256) EthersSentByBuyers; 
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
    maxTokensToSaleInPrivateSale = 100000000 * 10 ** uint256(decimals);
    maxTokensToSaleInPreICO = 200000000 * 10 ** uint256(decimals);
    maxTokensToSale = 550000000 * 10 ** uint256(decimals);
    bonusInPrivateSale = 100;
    
    minimumContributionInPrivatePhase = 168 ether;
    minimumContributionInPreICO = 1.68 ether;
    maximumContributionInPreICO = 1680 ether;
    maximumContributionInMainICO = 168 ether;
    token = TokenInterface(_tokenAddress);
  }
  
  
   // fallback function can be used to buy tokens
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function determineBonus(uint tokens, uint amountSent, address sender) internal returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        
        //private sale (30 days)
        if (timeElapsedInDays <30)
        {
            require(amountSent>=minimumContributionInPrivatePhase);
            bonus = tokens.mul(bonusInPrivateSale);
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPrivateSale);  
            token.addPrivateSaleBuyer(sender,tokens.add(bonus));
        }
        //break
        else if (timeElapsedInDays >=30 && timeElapsedInDays <51)
        {
            revert();
        }
        //pre-ico/presale
        else if (timeElapsedInDays>=51 && timeElapsedInDays<72)
        {
            require(amountSent>=minimumContributionInPreICO && amountSent<=maximumContributionInPreICO);
            if (amountSent>=1.68 ether && amountSent < 17 ether)
            {
                bonus = tokens.mul(5);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICO); 
            }
            else if (amountSent>=17 ether && amountSent < 169 ether)
            {
                bonus = tokens.mul(10);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICO); 
            }
            else if (amountSent>=169 ether && amountSent < 841 ether)
            {
                bonus = tokens.mul(15);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICO); 
            }
            else if (amountSent>=841 ether && amountSent < 1680 ether)
            {
                bonus = tokens.mul(20);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICO); 
            }
            //adding to pre ico sale for soft cap refunding
            if (EthersSentByBuyers[sender] == 0)
            {
                EthersSentByBuyers[sender] = amountSent;
                tokenBuyers.push(sender);
            }
            else 
            {
                EthersSentByBuyers[sender] = EthersSentByBuyers[sender].add(amountSent);
            }
            weiRaisedInPreICO = weiRaisedInPreICO.add(amountSent);
            token.addPreSaleBuyer(sender,tokens.add(bonus));
        }
        //break
        else if (timeElapsedInDays>=72 && timeElapsedInDays<83)
        {
            revert();
        }
        //main ico
        else if(timeElapsedInDays>=83)
        {
            require(amountSent<=maximumContributionInMainICO);
            bonus = 0;
        }
    }

  // low level token purchase function
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(validPurchase());
    require(TOKENS_SOLD<maxTokensToSale && weiRaised<hardCap);
   
    uint256 weiAmount = msg.value;
    
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens,weiAmount,beneficiary);
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
     * Remaining tokens for sale
    **/ 
      
     function remainingTokensForSale() public constant returns (uint) {
         return maxTokensToSale.sub(TOKENS_SOLD);
     }
     
     function getUnsoldTokensBack() public onlyOwner
     {
        uint contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance>0);
        token.transfer(owner,contractTokenBalance);
     }
     
     /**
      * Refund the tokens to buyers of presale if soft cap not reached
      **/ 
     function RefundToBuyers() public payable onlyOwner {
         //require(now > startTime.add(72 days) );
         require(weiRaised<softCapForPreICO);
         require(msg.value>=weiRaisedInPreICO);
         for (uint i=0;i<tokenBuyers.length;i++)
         {
             uint etherAmount = EthersSentByBuyers[tokenBuyers[i]];
             if (etherAmount>0)
             {
                tokenBuyers[i].transfer(etherAmount);
                EthersSentByBuyers[tokenBuyers[i]] = 0;
             }
         }
     }
     /**
      * Add the team and advisory members
      **/ 
     function addTeamAndAdvisoryMembers(address[] members) public onlyOwner {
         token.addTeamAndAdvisoryMembers(members);
     }
     
     /**
      * view the private sale end date and time
      **/
     function getPrivateSaleEndDate() public view onlyOwner returns (uint) {
         return startTime.add(30 days);
     }
     
     /**
      * view the presale end date and time
      **/
     function getPreSaleEndDate() public view onlyOwner returns (uint) {
          return startTime.add(72 days);
     }
     
     /**
      * view the ICO end date and time
      **/
     function getICOEndDate() public view onlyOwner returns (uint) {
          return startTime.add(112 days);
     }
     
     /**
      * set the private sale end date and time
      **/
      function setPrivateSaleEndDate(uint256 timestamp) public onlyOwner  {
          token.addPrivateSaleEndDate(timestamp);
      }
      
     /**
      * set the pre sale end date and time
      **/
       function setPreSaleEndDate(uint256 timestamp) public onlyOwner {
           token.addPreSaleEndDate(timestamp);
       }
       
     /**
      * set the ICO end date and time
      **/
        function setICOEndDate(uint timestamp) public onlyOwner {
           token.addICOEndDate(timestamp);
       }
}