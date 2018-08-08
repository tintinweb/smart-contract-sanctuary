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
  uint256 public TOKENS_BOUGHT;
  
  uint256 public minimumContributionPhase1;
  uint256 public minimumContributionPhase2;
  uint256 public minimumContributionPhase3;
  uint256 public minimumContributionPhase4;
  uint256 public minimumContributionPhase5;
  uint256 public minimumContributionPhase6;
  
  uint256 public maxTokensToSaleInClosedPreSale;
  
  uint256 public bonusInPhase1;
  uint256 public bonusInPhase2;
  uint256 public bonusInPhase3;
  uint256 public bonusInPhase4;
  uint256 public bonusInPhase5;
  uint256 public bonusInPhase6;
  
  
  bool public isCrowdsalePaused = false;
  
  uint256 public totalDurationInDays = 123 days;
  
  
  struct userInformation {
      address userAddress;
      uint tokensToBeSent;
      uint ethersToBeSent;
      bool isKYCApproved;
      bool recurringBuyer;
  }
  
  event usersAwaitingTokens(address[] users);
  mapping(address=>userInformation) usersBuyingInformation;
  address[] allUsers;
  address[] u;
  userInformation info;
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
    
    bonusInPhase1 = 30;
    bonusInPhase2 = 20;
    bonusInPhase3 = 15;
    bonusInPhase4 = 10;
    bonusInPhase5 = 75;
    bonusInPhase6 = 5;
    
    minimumContributionPhase1 = uint(3).mul(10 ** 17); //0.3 eth is the minimum contribution in presale phase 1
    minimumContributionPhase2 = uint(5).mul(10 ** 16); //0.05 eth is the minimum contribution in presale phase 2
    minimumContributionPhase3 = uint(5).mul(10 ** 16); //0.05 eth is the minimum contribution in presale phase 3
    minimumContributionPhase4 = uint(5).mul(10 ** 16); //0.05 eth is the minimum contribution in presale phase 4
    minimumContributionPhase5 = uint(5).mul(10 ** 16); //0.05 eth is the minimum contribution in presale phase 5
    minimumContributionPhase6 = uint(5).mul(10 ** 16); //0.05 eth is the minimum contribution in presale phase 6
    
    token = TokenInterface(_tokenAddress);
  }
  
  
   // fallback function can be used to buy tokens
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function determineBonus(uint tokens, uint ethersSent) internal view returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        
        //phase 1 (16 days)
        if (timeElapsedInDays <16)
        {
            require(ethersSent>=minimumContributionPhase1);
            bonus = tokens.mul(bonusInPhase1); 
            bonus = bonus.div(100);
        }
        //phase 2 (31 days)
        else if (timeElapsedInDays >=16 && timeElapsedInDays <47)
        {
            require(ethersSent>=minimumContributionPhase2);
            bonus = tokens.mul(bonusInPhase2); 
            bonus = bonus.div(100);
        }
         //phase 3 (15 days)
        else if (timeElapsedInDays >=47 && timeElapsedInDays <62)
        {
            require(ethersSent>=minimumContributionPhase3);
            bonus = tokens.mul(bonusInPhase3); 
            bonus = bonus.div(100);
        }
        //(16 days) -- break
        else if (timeElapsedInDays >=62 && timeElapsedInDays <78)
        {
           revert();
        }
        //phase 5 (15 days) 
        else if (timeElapsedInDays >=78 && timeElapsedInDays <93)
        {
            require(ethersSent>=minimumContributionPhase4);
            bonus = tokens.mul(bonusInPhase4); 
            bonus = bonus.div(100);
        }
        //phase 6 (15 days)
        else if (timeElapsedInDays >=93 && timeElapsedInDays <108)
        {
            require(ethersSent>=minimumContributionPhase5);
            bonus = tokens.mul(bonusInPhase5); 
            bonus = bonus.div(10);  //to cater for the 7.5 figure
            bonus = bonus.div(100);
        }
         //phase 7 (15 days) 
        else if (timeElapsedInDays >=108 && timeElapsedInDays <123)
        {
            require(ethersSent>=minimumContributionPhase6);
            bonus = tokens.mul(bonusInPhase6); 
            bonus = bonus.div(100);
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
    uint256 weiAmount = msg.value;
    
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens,weiAmount);
    tokens = tokens.add(bonus);
    
    //if the user is first time buyer, add his entries
    if (usersBuyingInformation[beneficiary].recurringBuyer == false)
    {
        info = userInformation ({ userAddress: beneficiary, tokensToBeSent:tokens, ethersToBeSent:weiAmount, isKYCApproved:false,
                                recurringBuyer:true});
        usersBuyingInformation[beneficiary] = info;
        allUsers.push(beneficiary);
    }
    //if the user is has bought with the same address before too, update his entries
    else 
    {
        info = usersBuyingInformation[beneficiary];
        info.tokensToBeSent = info.tokensToBeSent.add(tokens);
        info.ethersToBeSent = info.ethersToBeSent.add(weiAmount);
        usersBuyingInformation[beneficiary] = info;
    }
    TOKENS_BOUGHT = TOKENS_BOUGHT.add(tokens);
    emit TokenPurchase(owner, beneficiary, weiAmount, tokens);
    
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
         TOKENS_BOUGHT = TOKENS_BOUGHT.add(value);
     }
     
     /**
      * function to approve a single user which means the user has passed all KYC checks
      * can only be called by the owner
      **/ 
     function approveSingleUser(address user) public onlyOwner {
        usersBuyingInformation[user].isKYCApproved = true;    
     }
     
     /**
      * function to disapprove a single user which means the user has failed the KYC checks
      * can only be called by the owner
      **/
     function disapproveSingleUser(address user) public onlyOwner {
         usersBuyingInformation[user].isKYCApproved = false;  
     }
     
     /**
      * function to approve multiple users at once 
      * can only be called by the owner
      **/
     function approveMultipleUsers(address[] users) public onlyOwner {
         
         for (uint i=0;i<users.length;i++)
         {
            usersBuyingInformation[users[i]].isKYCApproved = true;    
         }
     }
     
     /**
      * function to distribute the tokens to approved users
      * can only be called by the owner
      **/
     function distributeTokensToApprovedUsers() public onlyOwner {
        for(uint i=0;i<allUsers.length;i++)
        {
            if (usersBuyingInformation[allUsers[i]].isKYCApproved == true && usersBuyingInformation[allUsers[i]].tokensToBeSent>0)
            {
                address to = allUsers[i];
                uint tokens = usersBuyingInformation[to].tokensToBeSent;
                token.transfer(to,tokens);
                if (usersBuyingInformation[allUsers[i]].ethersToBeSent>0)
                    owner.transfer(usersBuyingInformation[allUsers[i]].ethersToBeSent);
                TOKENS_SOLD = TOKENS_SOLD.add(usersBuyingInformation[allUsers[i]].tokensToBeSent);
                weiRaised = weiRaised.add(usersBuyingInformation[allUsers[i]].ethersToBeSent);
                usersBuyingInformation[allUsers[i]].tokensToBeSent = 0;
                usersBuyingInformation[allUsers[i]].ethersToBeSent = 0;
            }
        }
     }
     
      /**
      * function to distribute the tokens to all users whether approved or unapproved
      * can only be called by the owner
      **/
     function distributeTokensToAllUsers() public onlyOwner {
        for(uint i=0;i<allUsers.length;i++)
        {
            if (usersBuyingInformation[allUsers[i]].tokensToBeSent>0)
            {
                address to = allUsers[i];
                uint tokens = usersBuyingInformation[to].tokensToBeSent;
                token.transfer(to,tokens);
                if (usersBuyingInformation[allUsers[i]].ethersToBeSent>0)
                    owner.transfer(usersBuyingInformation[allUsers[i]].ethersToBeSent);
                TOKENS_SOLD = TOKENS_SOLD.add(usersBuyingInformation[allUsers[i]].tokensToBeSent);
                weiRaised = weiRaised.add(usersBuyingInformation[allUsers[i]].ethersToBeSent);
                usersBuyingInformation[allUsers[i]].tokensToBeSent = 0;
                usersBuyingInformation[allUsers[i]].ethersToBeSent = 0;
            }
        }
     }
     
     /**
      * function to refund a single user in case he hasnt passed the KYC checks
      * can only be called by the owner
      **/
     function refundSingleUser(address user) public onlyOwner {
         require(usersBuyingInformation[user].ethersToBeSent > 0 );
         user.transfer(usersBuyingInformation[user].ethersToBeSent);
         usersBuyingInformation[user].tokensToBeSent = 0;
         usersBuyingInformation[user].ethersToBeSent = 0;
     }
     
     /**
      * function to refund to multiple users in case they havent passed the KYC checks
      * can only be called by the owner
      **/
     function refundMultipleUsers(address[] users) public onlyOwner {
         for (uint i=0;i<users.length;i++)
         {
            require(usersBuyingInformation[users[i]].ethersToBeSent >0);
            users[i].transfer(usersBuyingInformation[users[i]].ethersToBeSent);
            usersBuyingInformation[users[i]].tokensToBeSent = 0;
            usersBuyingInformation[users[i]].ethersToBeSent = 0;
         }
     }
     /**
      * function to transfer out all ethers present in the contract
      * after calling this function all refunds would need to be done manually
      * would use this function as a last resort
      * can only be called by owner wallet
      **/ 
     function transferOutAllEthers() public onlyOwner {
         owner.transfer(address(this).balance);
     }
     
     /**
      * function to get the top 150 users who are awaiting the transfer of tokens
      * can only be called by the owner
      * this function would work in read mode
      **/ 
     function getUsersAwaitingForTokensTop150(bool fetch) public constant returns (address[150])  {
          address[150] memory awaiting;
         uint k = 0;
         for (uint i=0;i<allUsers.length;i++)
         {
             if (usersBuyingInformation[allUsers[i]].isKYCApproved == true && usersBuyingInformation[allUsers[i]].tokensToBeSent>0)
             {
                 awaiting[k] = allUsers[i];
                 k = k.add(1);
                 if (k==150)
                    return awaiting;
             }
         }
         return awaiting;
     }
     
     /**
      * function to get the users who are awaiting the transfer of tokens
      * can only be called by the owner
      * this function would work in write mode
      **/ 
     function getUsersAwaitingForTokens() public onlyOwner returns (address[])  {
         delete u;
         for (uint i=0;i<allUsers.length;i++)
         {
             if (usersBuyingInformation[allUsers[i]].isKYCApproved == true && usersBuyingInformation[allUsers[i]].tokensToBeSent>0)
             {
                 u.push(allUsers[i]);
             }
         }
         emit usersAwaitingTokens(u);
         return u;
     }
     
     /**
      * function to return the information of a single user
      **/ 
     function getUserInfo(address userAddress) public constant returns(uint _ethers, uint _tokens, bool _isApproved)
     {
         _ethers = usersBuyingInformation[userAddress].ethersToBeSent;
         _tokens = usersBuyingInformation[userAddress].tokensToBeSent;
         _isApproved = usersBuyingInformation[userAddress].isKYCApproved;
         return(_ethers,_tokens,_isApproved);
         
     }
     
     /**
      * function to clear all payables/receivables of a user
      * can only be called by owner 
      **/
      function closeUser(address userAddress) public onlyOwner 
      {
          //instead of deleting the user from the system we are just clearing the payables/receivables
          //if this user buys again, his entry would be updated
          uint ethersByTheUser =  usersBuyingInformation[userAddress].ethersToBeSent;
          usersBuyingInformation[userAddress].isKYCApproved = false;
          usersBuyingInformation[userAddress].ethersToBeSent = 0;
          usersBuyingInformation[userAddress].tokensToBeSent = 0;
          usersBuyingInformation[userAddress].recurringBuyer = true;
          owner.transfer(ethersByTheUser);
      } 
      
     /**
      * function to get a list of top 150 users that are unapproved
      * can only be called by owner
      * this function would work in read mode
      **/
      function getUnapprovedUsersTop150(bool fetch) public constant returns (address[150]) 
      {
         address[150] memory unapprove;
         uint k = 0;
         for (uint i=0;i<allUsers.length;i++)
         {
             if (usersBuyingInformation[allUsers[i]].isKYCApproved == false)
             {
                 unapprove[k] = allUsers[i];
                 k = k.add(1);
                 if (k==150)
                    return unapprove;
             }
         }
         return unapprove;
      } 
      
       /**
      * function to get a list of all users that are unapproved
      * can only be called by owner
      * this function would work in write mode
      **/
      function getUnapprovedUsers() public onlyOwner returns (address[]) 
      {
         delete u;
         for (uint i=0;i<allUsers.length;i++)
         {
             if (usersBuyingInformation[allUsers[i]].isKYCApproved == false)
             {
                 u.push(allUsers[i]);
             }
         }
         emit usersAwaitingTokens(u);
         return u;
      } 
      
      /**
      * function to return all the users
      **/
      function getAllUsers(bool fetch) public constant returns (address[]) 
      {
          return allUsers;
      } 
      
      /**
       * function to change the address of a user
       * this function would be used in situations where user made the transaction from one wallet
       * but wants to receive tokens in another wallet
       * so owner should be able to update the address
       **/ 
      function changeUserEthAddress(address oldEthAddress, address newEthAddress) public onlyOwner 
      {
          usersBuyingInformation[newEthAddress] = usersBuyingInformation[oldEthAddress];
          for (uint i=0;i<allUsers.length;i++)
          {
              if (allUsers[i] == oldEthAddress)
                allUsers[i] = newEthAddress;
          }
          delete usersBuyingInformation[oldEthAddress];
      }
      
      /**
       * Add a user that has paid with BTC or other payment methods
       **/ 
      function addUser(address userAddr, uint tokens) public onlyOwner 
      {
            // if first time buyer, add his details in the mapping
            if (usersBuyingInformation[userAddr].recurringBuyer == false)
            {
                info = userInformation ({ userAddress: userAddr, tokensToBeSent:tokens, ethersToBeSent:0, isKYCApproved:false,
                                recurringBuyer:true});
                usersBuyingInformation[userAddr] = info;
                allUsers.push(userAddr);
            }
            //if recurring buyer, update his mappings
            else 
            {
                info = usersBuyingInformation[userAddr];
                info.tokensToBeSent = info.tokensToBeSent.add(tokens);
                usersBuyingInformation[userAddr] = info;
            }
            TOKENS_BOUGHT = TOKENS_BOUGHT.add(tokens);
      }
      
      /**
       * Set the tokens bought
       **/ 
      function setTokensBought(uint tokensBought) public onlyOwner 
      {
          TOKENS_BOUGHT = tokensBought;
      }
      
      /**
       * Returns the number of tokens who have been sold  
       **/ 
      function getTokensBought() public constant returns(uint) 
      {
          return TOKENS_BOUGHT;
      }
      
}