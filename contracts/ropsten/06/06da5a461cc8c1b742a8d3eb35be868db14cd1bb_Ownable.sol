pragma solidity ^0.4.19;

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestaps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrie.
 */
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 
  
  function Ownable () public {
  
 //constructor() public {
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


/**
 * @title ERC20Standard
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract CloudexchangeToken is ERC20Interface,Ownable {

    using SafeMath for uint256;
   
    mapping(address => uint256) tokenBalances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    string public constant name = "CLOUDEXCHANGE";
    string public constant symbol = "CXT";
    uint256 public constant decimals = 18;

   uint256 public constant INITIAL_SUPPLY = 1000000000;
   
   
   

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }
  
  
     /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
     /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

     // ------------------------------------------------------------------------
     // Total supply
     // ------------------------------------------------------------------------
     function totalSupply() public constant returns (uint) {
         return totalSupply  - tokenBalances[address(0)];
     }
     
    
     
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender&#39;s account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
     
     /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

     
     // ------------------------------------------------------------------------
     // Don&#39;t accept ETH
     // ------------------------------------------------------------------------
     function () public payable {
         revert();
     }   


  
  
  
   event Debug(string message, address addr, uint256 number);
   /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
   
   function CloudexchangeToken (address wallet) public {
    
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY * 10 ** 18;
        tokenBalances[wallet] = totalSupply;   //Since we divided the token into 10^18 parts
    }

    function mint(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
      require(tokenBalances[wallet] >= tokenAmount);               // checks if it has enough to sell
      tokenBalances[buyer] = tokenBalances[buyer].add(tokenAmount);                  // adds the amount to buyer&#39;s balance
      tokenBalances[wallet] = tokenBalances[wallet].sub(tokenAmount);                        // subtracts amount from seller&#39;s balance
      Transfer(wallet, buyer, tokenAmount); 
      totalSupply = totalSupply.sub(tokenAmount); 
    }
   
}

contract CloudexchangeCrowdsale {
  using SafeMath for uint256;
  
  // The token being sold
  CloudexchangeToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint public startTime;
  uint public endTime;

  // address where funds are collected
  // address where tokens are deposited and from where we send tokens to buyers
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public ratePerWei = 2000;

  // amount of raised money in wei
  uint256 public weiRaised;

  // flags to show whether soft cap / hard cap is reached
  bool public isSoftCapReached = false;
  bool public isHardCapReached = false;
    
  //this flag is set to true when ICO duration is over and soft cap is not reached  
  bool public refundToBuyers = false;
    
  // Soft cap of the ICO in ethers  
  //uint256 public softCap = 6000;
  uint256 public softCap = 1;
    
  //Hard cap of the ICO in ethers
  //uint256 public hardCap = 50000;
  uint256 public hardCap = 2;
  
  //total tokens that have been sold  
  uint256 public tokens_sold = 0;

  //total tokens that are to be sold - this is 25% of the total supply i.e. 1000000000
  //uint maxTokensForSale = 200000000;
  uint maxTokensForSale = 2;
  
  //tokens that are reserved for the Cloudexchange team - this is 35% of the total supply  
  uint256 public tokensForReservedFund = 0;
  uint256 public tokensForAdvisors = 0;
  uint256 public tokensForFoundersAndTeam = 0;
  uint256 public tokensForMarketing = 0;
  uint256 public tokensForTournament = 0;

  bool ethersSentForRefund = false;

  // the buyers of tokens and the amount of ethers they sent in
  mapping(address=>uint256) usersThatBoughtCXT;
 
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event ICOStarted(uint256 startTime, uint256 endTime);
  
  function CloudexchangeCrowdsale(uint256 _startTime, address _wallet) public {
  
  //constructor (uint256 _startTime, address _wallet) public {
  
    
    startTime = _startTime;
    endTime = startTime.add(4 days);
    //endTime = startTime.add(21600 seconds);
    
    require(endTime >= startTime);
    require(_wallet != 0x0);

    wallet = _wallet;
    token = createTokenContract(wallet);
    
    ICOStarted(startTime,endTime);
  }

  function createTokenContract(address wall) internal returns (CloudexchangeToken) {
    return new CloudexchangeToken(wall);
  }
  
  //*fallback function can be used to buy tokens*/
  
  function () public payable {
    buyTokens(msg.sender);
  }

  //determine the bonus with respect to time elapsed
  function determineBonus(uint tokens) internal view returns (uint256 bonus) {
    
    uint256 timeElapsed = now - startTime;
    uint256 timeElapsedInDays = timeElapsed.div(1 days);
    //uint256 timeElapsedInSeconds = timeElapsed.div(1 seconds);
     
    if (timeElapsedInDays <=1)
	//test mode is 1 hour per time period check
    //if (timeElapsedInSeconds <=3600)
    {
        //early sale
        //valid for 01-08-2018 to 07-08-2018 i.e. 0 to 7 days
        //25% BONUS
        bonus = tokens.mul(25);
        bonus = bonus.div(100);
       
    }
    else if (timeElapsedInDays>1 && timeElapsedInDays <=2)
    //else if (timeElapsedInSeconds>3600 && timeElapsedInSeconds <=7200)
    {
        //sale
        //from 08.08.2018 - 14.08.2018 i.e. 8th to 14th days
   
        //15% bonus
        bonus = tokens.mul(15);
        bonus = bonus.div(100);
        
       
    }
    else if (timeElapsedInDays>2 && timeElapsedInDays <=3)
    //else if (timeElapsedInSeconds>7200 && timeElapsedInSeconds <=10800)
    {
        //sale
        //from 015.08.2018 - 31.08.2018 i.e. 15th to 31th days
       
        //0% bonus
        bonus = 0;
    }
   
  }

  // low level token purchase function
  // Minimum purchase can be of 50 CXT tokens
  
  function buyTokens(address beneficiary) public payable {
    
  //tokens not to be sent to 0x0
  require(beneficiary != 0x0);

  if(hasEnded() && !isHardCapReached)
  {
      if (!isSoftCapReached)
        refundToBuyers = true;
      burnRemainingTokens();
      beneficiary.transfer(msg.value);
  }
  
  else
  {
    //the purchase should be within duration and non zero
    require(validPurchase());
    
    // amount sent by the user
    uint256 weiAmount = msg.value;
    
    // calculate token amount to be sold
    uint256 tokens = weiAmount.mul(ratePerWei);
  
    require (tokens>=50 * 10 ** 18);
    
    //Determine bonus
    uint bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
  
    //can&#39;t sale tokens more than 20000000 tokens
    require(tokens_sold + tokens <= maxTokensForSale * 10 ** 18);
  
    //35% of the tokens being sold are being accumulated for the Cloudexchange team
    
    updateTokensForCloudexchangeTeam(tokens);

    weiRaised = weiRaised.add(weiAmount);
    
    
    if (weiRaised >= softCap * 10 ** 18 && !isSoftCapReached)
    {
      isSoftCapReached = true;
    }
  
    if (weiRaised >= hardCap * 10 ** 18 && !isHardCapReached)
      isHardCapReached = true;
    
    token.mint(wallet, beneficiary, tokens);
    
    uint olderAmount = usersThatBoughtCXT[beneficiary];
    usersThatBoughtCXT[beneficiary] = weiAmount + olderAmount;
    
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    
    tokens_sold = tokens_sold.add(tokens);
    forwardFunds();
  }
 }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    wallet.transfer(msg.value);
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
    
    function burnRemainingTokens() internal
    {
        //burn all the unsold tokens as soon as the ICO is ended
        uint balance = token.balanceOf(wallet);
        require(balance>0);
        uint tokensForTeam = tokensForReservedFund + tokensForFoundersAndTeam + tokensForAdvisors +tokensForMarketing + tokensForTournament;
        uint tokensToBurn = balance.sub(tokensForTeam);
        require (balance >=tokensToBurn);
        address burnAddress = 0x0;
        token.mint(wallet,burnAddress,tokensToBurn);
    }
    
    function getRefund() public 
    {
        require(ethersSentForRefund && usersThatBoughtCXT[msg.sender]>0);
        uint256 ethersSent = usersThatBoughtCXT[msg.sender];
        require (wallet.balance >= ethersSent);
        msg.sender.transfer(ethersSent);
        uint256 tokensIHave = token.balanceOf(msg.sender);
        token.mint(msg.sender,0x0,tokensIHave);
    }
    
    function debitAmountToRefund() public payable 
    {
        require(hasEnded() && msg.sender == wallet && !isSoftCapReached && !ethersSentForRefund);
        require(msg.value >=weiRaised);
        ethersSentForRefund = true;
    }
    
    function updateTokensForCloudexchangeTeam(uint256 tokens) internal 
    {
        uint256 reservedFundTokens;
        uint256 foundersAndTeamTokens;
        uint256 advisorsTokens;
        uint256 marketingTokens;
        uint256 tournamentTokens;
        
        //37% of tokens for reserved fund
        reservedFundTokens = tokens.mul(37);
        reservedFundTokens = reservedFundTokens.div(100);
        tokensForReservedFund = tokensForReservedFund.add(reservedFundTokens);
    
        //35% of tokens for founders and team    
        foundersAndTeamTokens=tokens.mul(35);
        foundersAndTeamTokens= foundersAndTeamTokens.div(100);
        tokensForFoundersAndTeam = tokensForFoundersAndTeam.add(foundersAndTeamTokens);
    
        //1% of tokens for advisors
        advisorsTokens=tokens.mul(1);
        advisorsTokens= advisorsTokens.div(100);
        tokensForAdvisors= tokensForAdvisors.add(advisorsTokens);
    
        //1% of tokens for marketing
        marketingTokens = tokens.mul(1);
        marketingTokens= marketingTokens.div(100);
        tokensForMarketing= tokensForMarketing.add(marketingTokens);
        
        //1% of tokens for tournament 
        tournamentTokens=tokens.mul(1);
        tournamentTokens= tournamentTokens.div(100);
        tokensForTournament= tokensForTournament.add(tournamentTokens);
    }
    
    function withdrawTokensForCloudexchangeTeam(uint256 whoseTokensToWithdraw,address[] whereToSendTokens) public {
        //1 reserved fund, 2 for founders and team, 3 for advisors, 4 for marketing, 5 for tournament
        require(msg.sender == wallet && now>=endTime);
        uint256 lockPeriod = 0;
        uint256 timePassed = now - endTime;
        uint256 tokensToSend = 0;
        uint256 i = 0;
        if (whoseTokensToWithdraw == 1)
        {
          //15 months lockup period
          //lockPeriod = 15 days * 30;
          //3600 second lockup period
          lockPeriod = 1 seconds * 3600;
          require(timePassed >= lockPeriod);
          require (tokensForReservedFund >0);
          //allow withdrawal
          tokensToSend = tokensForReservedFund.div(whereToSendTokens.length);
                
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }
          tokensForReservedFund = 0;
        }
        else if (whoseTokensToWithdraw == 2)
        {
          //10 months lockup period
          //lockPeriod = 10 days * 30;
          // 7200 second lock period
          lockPeriod = 1 seconds * 7200;
          require(timePassed >= lockPeriod);
          require(tokensForFoundersAndTeam > 0);
          //allow withdrawal
          tokensToSend = tokensForFoundersAndTeam.div(whereToSendTokens.length);
                
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }            
          tokensForFoundersAndTeam = 0;
        }
        else if (whoseTokensToWithdraw == 3)
        {
            require (tokensForAdvisors > 0);
          //allow withdrawal
          tokensToSend = tokensForAdvisors.div(whereToSendTokens.length);        
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }
          tokensForAdvisors = 0;
        }
        else if (whoseTokensToWithdraw == 4)
        {
            require (tokensForMarketing > 0);
          //allow withdrawal
          tokensToSend = tokensForMarketing.div(whereToSendTokens.length);
                
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }
          tokensForMarketing = 0;
        }
        else if (whoseTokensToWithdraw == 5)
        {
            require (tokensForTournament > 0);
          //allow withdrawal
          tokensToSend = tokensForTournament.div(whereToSendTokens.length);
                
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }
          tokensForTournament = 0;
        }
        else 
        {
          //wrong input
          require (1!=1);
        }
    }
 }