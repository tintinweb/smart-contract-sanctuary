pragma solidity 0.4.25;

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
     function lockTokensForAddress (address lockedAddress, uint lockupAmount, uint lockDays) external;
      function unlockTokensForAddress (address lockedAddress) external;
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     event Burn(address indexed burner, uint256 value);
}

 contract CitusCrowdsale is Ownable{
  using SafeMath for uint256;
 
  // The token being sold
  TokenInterface public token;

  struct ICOPhase
  {
      uint startTime;
      uint endTime;
      uint maxTokensToSale;
      uint tokensSold;
      uint ratePerWei;
      uint softCap;
      uint weiRaised;
      uint bonus;
      bool isRefundAllowed;
      bool isPhaseEnded;
      bool isPhasePaused;
  }
  
  ICOPhase phase;
  mapping(uint=>ICOPhase) icoPhases;
  uint activePhase = 0;
  
  // amount of raised money in wei
  uint256 public weiRaised;

  uint256 TOKENS_SOLD;
  uint256 maxTokensToSale;
  
  mapping(address=>mapping(uint=>uint)) amountSentByBuyersInEachPhase; 
  mapping(address=>bool) whitelistedAddresses;
  
  uint minimumContribution;
  uint maximumContribution;
  
  uint256 decimals = 4;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function CitrusCrowdsale(address _wallet, address _tokenAddress) public 
  {
    require(_wallet != 0x0);
    require(_tokenAddress != 0x0);
    owner = _wallet;
    token = TokenInterface(_tokenAddress);
    maxTokensToSale =uint(780000000).mul( 10 ** uint256(decimals));
    minimumContribution = uint(1).mul(10**18);
    maximumContribution = uint(10000000).mul(10**18);
  }
  
  
  function AddNewPhase(uint _startTime, uint _endTime, uint _maxTokensToSale, uint _ratePerWei,uint _softCap, uint _bonus) public onlyOwner 
  {
      
      require(_startTime>=now);
      require(_startTime<_endTime);
      require(_maxTokensToSale>0 && TOKENS_SOLD.add(_maxTokensToSale)<=maxTokensToSale);
      require(_ratePerWei>0);
      require(_startTime> icoPhases[activePhase].endTime);
      activePhase = activePhase.add(1);
      phase = ICOPhase({startTime:_startTime, endTime:_endTime, maxTokensToSale:_maxTokensToSale,
                        tokensSold:0, ratePerWei:_ratePerWei,softCap:_softCap, weiRaised:0,
                        bonus:_bonus,isRefundAllowed:false,isPhaseEnded:false,isPhasePaused:false
      });
      icoPhases[activePhase]=phase;
  }
  function WhatTimeIsNow() public constant returns (uint)
  {
      return now;
  }
   // fallback function can be used to buy tokens
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    // low level token purchase function
  
    function buyTokens(address beneficiary) public payable {
        
        require(beneficiary != 0x0);
        require(msg.value>0);
        require(now>=icoPhases[activePhase].startTime && now<=icoPhases[activePhase].endTime);
        require(icoPhases[activePhase].tokensSold<icoPhases[activePhase].maxTokensToSale);
        require(!icoPhases[activePhase].isPhasePaused);
        require(!icoPhases[activePhase].isPhaseEnded);
        require(whitelistedAddresses[msg.sender]);
        uint weiAmountForTokens = msg.value.div(10**14);
        uint tokens = weiAmountForTokens.mul(icoPhases[activePhase].ratePerWei);
        uint bonus = tokens.mul(icoPhases[activePhase].bonus).div(100);
        tokens = tokens.add(bonus);
        
        token.transfer(msg.sender,tokens);
        TOKENS_SOLD = TOKENS_SOLD.add(tokens);
        icoPhases[activePhase].tokensSold = icoPhases[activePhase].tokensSold.add(tokens);
        icoPhases[activePhase].weiRaised = icoPhases[activePhase].weiRaised.add(msg.value);
        amountSentByBuyersInEachPhase[msg.sender][activePhase] = msg.value;
        weiRaised = weiRaised.add(msg.value);
        forwardFunds();
    }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }

   /**
    * function to change the end timestamp of the ico
    * can only be called by owner wallet
    **/
    function changeEndDate(uint256 phaseNumber, uint256 endTimeUnixTimestamp) public onlyOwner{
        icoPhases[phaseNumber].endTime = endTimeUnixTimestamp;
    }
    
    /**
    * function to change the start timestamp of the ico
    * can only be called by owner wallet
    **/
    
    function changeStartDate(uint256 phaseNumber,uint256 startTimeUnixTimestamp) public onlyOwner{
        icoPhases[phaseNumber].startTime = startTimeUnixTimestamp;
    }
    
    /**
    * function to change the rate of tokens
    * can only be called by owner wallet
    **/
    function setPriceRate(uint256 phaseNumber, uint256 newPrice) public onlyOwner {
        icoPhases[phaseNumber].ratePerWei = newPrice;
    }
    
    function changeMinimumContributionForAllPhases(uint256 minContribution) public onlyOwner{
        minimumContribution = minContribution;
    }
    
     function changeMaximumContributionForAllPhases(uint256 minContribution) public onlyOwner{
        maximumContribution = minContribution;
    }
    
     /**
     * function to pause the crowdsale 
     * can only be called from owner wallet
     **/
     
    function pauseCrowdsale() public onlyOwner {
        icoPhases[activePhase].isPhasePaused = true;
    }

    /**
     * function to resume the crowdsale if it is paused
     * can only be called from owner wallet
     **/ 
    function resumeCrowdsale() public onlyOwner {
        icoPhases[activePhase].isPhasePaused = false;
    }
    
    /**
     * function to change the soft cap of the contract 
     **/
    function changeSoftCap(uint256 phaseNumber, uint256 softCapEthers) public onlyOwner
    {
        icoPhases[phaseNumber].softCap = softCapEthers;
    }
    
     
     // ------------------------------------------------------------------------
     // Remaining tokens for sale
     // ------------------------------------------------------------------------
     function remainingTokensForSale() public constant returns (uint) {
         return maxTokensToSale.sub(TOKENS_SOLD);
     }

     function burnUnsoldTokens() public onlyOwner 
     {
         require(now>=icoPhases[activePhase].endTime);
         uint value = remainingTokensForSale();
         token.burn(value);
         TOKENS_SOLD = maxTokensToSale;
     }
     
     function refundToBuyersIfSoftCapNotReached(uint phaseNumber) public payable onlyOwner
     {
        require(now>icoPhases[phaseNumber].endTime);
        require(icoPhases[phaseNumber].weiRaised<icoPhases[phaseNumber].softCap);
        icoPhases[phaseNumber].isRefundAllowed = true;
     }
     
     function getRefund(uint phaseNumber) public 
     {
         require(icoPhases[phaseNumber].isRefundAllowed);
         
         if (amountSentByBuyersInEachPhase[msg.sender][phaseNumber] > 0)
            msg.sender.transfer(amountSentByBuyersInEachPhase[msg.sender][phaseNumber]);
     }
     function getUnsoldTokensBack() public onlyOwner
     {
        uint contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance>0);
        token.transfer(owner,contractTokenBalance);
     }
     
     function addAddressToWhitelist(address whitelistedAddr) public onlyOwner
     {
         whitelistedAddresses[whitelistedAddr] = true;
     }
     
     function removeAddressFromWhitelist(address whitelistedAddr) public onlyOwner
     {
         whitelistedAddresses[whitelistedAddr] = false;
     }
     function checkIfAddressIsWhiteListed(address whitelistedAddr) public constant onlyOwner returns (bool)
     {
         return whitelistedAddresses[whitelistedAddr];
     }
}