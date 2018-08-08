pragma solidity ^0.4.15;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * Pausable token
 *
 * Simple ERC20 Token example, with pausable token creation
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}


/// @title The PallyCoin
/// @author Merunas Grincalaitis
contract PallyCoin is PausableToken {
   using SafeMath for uint256;

   string public constant name = &#39;PallyCoin&#39;;

   string public constant symbol = &#39;PAL&#39;;

   uint8 public constant decimals = 18;

   uint256 public constant totalSupply = 100e24; // 100M tokens with 18 decimals

   // The tokens already used for the presale buyers
   uint256 public tokensDistributedPresale = 0;

   // The tokens already used for the ICO buyers
   uint256 public tokensDistributedCrowdsale = 0;

   address public crowdsale;

   /// @notice Only allows the execution of the function if it&#39;s comming from crowdsale
   modifier onlyCrowdsale() {
      require(msg.sender == crowdsale);
      _;
   }

   // When someone refunds tokens
   event RefundedTokens(address indexed user, uint256 tokens);

   /// @notice Constructor used to set the platform & development tokens. This is
   /// The 20% + 20% of the 100 M tokens used for platform and development team.
   /// The owner, msg.sender, is able to do allowance for other contracts. Remember
   /// to use `transferFrom()` if you&#39;re allowed
   function PallyCoin() {
      balances[msg.sender] = 40e24; // 40M tokens wei
   }

   /// @notice Function to set the crowdsale smart contract&#39;s address only by the owner of this token
   /// @param _crowdsale The address that will be used
   function setCrowdsaleAddress(address _crowdsale) external onlyOwner whenNotPaused {
      require(_crowdsale != address(0));

      crowdsale = _crowdsale;
   }

   /// @notice Distributes the presale tokens. Only the owner can do this
   /// @param _buyer The address of the buyer
   /// @param tokens The amount of tokens corresponding to that buyer
   function distributePresaleTokens(address _buyer, uint tokens) external onlyOwner whenNotPaused {
      require(_buyer != address(0));
      require(tokens > 0);

      // Check that the limit of 10M presale tokens hasn&#39;t been met yet
      require(tokensDistributedPresale < 10e24);

      tokensDistributedPresale = tokensDistributedPresale.add(tokens);
      balances[_buyer] = balances[_buyer].add(tokens);
   }

   /// @notice Distributes the ICO tokens. Only the crowdsale address can execute this
   /// @param _buyer The buyer address
   /// @param tokens The amount of tokens to send to that address
   function distributeICOTokens(address _buyer, uint tokens) external onlyCrowdsale whenNotPaused {
      require(_buyer != address(0));
      require(tokens > 0);

      // Check that the limit of 50M ICO tokens hasn&#39;t been met yet
      require(tokensDistributedCrowdsale < 50e24);

      tokensDistributedCrowdsale = tokensDistributedCrowdsale.add(tokens);
      balances[_buyer] = balances[_buyer].add(tokens);
   }

   /// @notice Deletes the amount of tokens refunded from that buyer balance
   /// @param _buyer The buyer that wants the refund
   /// @param tokens The tokens to return
   function refundTokens(address _buyer, uint256 tokens) external onlyCrowdsale whenNotPaused {
      require(_buyer != address(0));
      require(tokens > 0);
      require(balances[_buyer] >= tokens);

      balances[_buyer] = balances[_buyer].sub(tokens);
      RefundedTokens(_buyer, tokens);
   }
}


/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  address public wallet;
  address private crowdsale;
  State public state;
  uint256 public weiBalance;

  mapping (address => uint256) public deposited;

  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
  event LogDeposited(address indexed buyer, uint256 amount);
  event VaultClosed();

  modifier onlyCrowdsale() {
      require(msg.sender == crowdsale);
      _;
  }

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);

    wallet = _wallet;
    crowdsale = msg.sender;
    state = State.Active;
  }

  function deposit(address investor) external payable onlyCrowdsale {
    require(state == State.Active);

    weiBalance = weiBalance.add(msg.value);
    deposited[investor] = deposited[investor].add(msg.value);
    LogDeposited(msg.sender, msg.value);
  }

  function close() external onlyCrowdsale {
    require(state == State.Active);

    state = State.Closed;
    wallet.transfer(weiBalance);
    VaultClosed();
  }

  function enableRefunds() external onlyCrowdsale {
    require(state == State.Active);

    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) external onlyCrowdsale {
    require(state == State.Refunding);

    uint256 depositedValue = deposited[investor];
    weiBalance = weiBalance.sub(depositedValue);
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}


// 1. First you set the address of the wallet in the RefundVault contract that will store the deposit of ether
// 2. If the goal is reached, the state of the vault will change and the ether will be sent to the address
// 3. If the goal is not reached after 28 days, the state of the vault will change to refunding and the users will be able to call claimRefund() to get their ether

/// @title Crowdsale contract to carry out an ICO with the PallyCoin
/// Crowdsales have a start and end timestamps, where investors can make
/// token purchases and the crowdsale will assign them tokens based
/// on a token per ETH rate. Funds collected are forwarded to a wallet
/// as they arrive.
/// @author Merunas Grincalaitis <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="75181007001b140612071c1b161419141c011c06351218141c195b161a18">[email&#160;protected]</a>>
contract Crowdsale is Pausable {
   using SafeMath for uint256;

   // The token being sold
   PallyCoin public token;

   // The vault that will store the ether until the goal is reached
   RefundVault public vault;

   // The block number of when the crowdsale starts
   // 10/15/2017 @ 11:00am (UTC)
   // 10/15/2017 @ 12:00am (GMT + 1)
   uint256 public startTime = 1508065200;

   // The block number of when the crowdsale ends
   // 11/13/2017 @ 11:00am (UTC)
   // 11/13/2017 @ 12:00pm (GMT + 1)
   uint256 public endTime = 1510570800;

   // The wallet that holds the Wei raised on the crowdsale
   address public wallet;

   // The rate of tokens per ether. Only applied for the first tier, the first
   // 12.5 million tokens sold
   uint256 public rate;

   // The rate of tokens per ether. Only applied for the second tier, at between
   // 12.5 million tokens sold and 25 million tokens sold
   uint256 public rateTier2;

   // The rate of tokens per ether. Only applied for the third tier, at between
   // 25 million tokens sold and 37.5 million tokens sold
   uint256 public rateTier3;

   // The rate of tokens per ether. Only applied for the fourth tier, at between
   // 37.5 million tokens sold and 50 million tokens sold
   uint256 public rateTier4;

   // The amount of wei raised
   uint256 public weiRaised = 0;

   // The amount of tokens raised
   uint256 public tokensRaised = 0;

   // You can only buy up to 50 M tokens during the ICO
   uint256 public constant maxTokensRaised = 50e24;

   // The minimum amount of Wei you must pay to participate in the crowdsale
   uint256 public constant minPurchase = 100 finney; // 0.1 ether

   // The max amount of Wei that you can pay to participate in the crowdsale
   uint256 public constant maxPurchase = 2000 ether;

   // Minimum amount of tokens to be raised. 7.5 million tokens which is the 15%
   // of the total of 50 million tokens sold in the crowdsale
   // 7.5e6 + 1e18
   uint256 public constant minimumGoal = 7.5e24;

   // If the crowdsale wasn&#39;t successful, this will be true and users will be able
   // to claim the refund of their ether
   bool public isRefunding = false;

   // If the crowdsale has ended or not
   bool public isEnded = false;

   // How much each user paid for the crowdsale
   mapping(address => uint256) public crowdsaleBalances;

   // How many tokens each user got for the crowdsale
   mapping(address => uint256) public tokensBought;

   // To indicate who purchased what amount of tokens and who received what amount of wei
   event TokenPurchase(address indexed buyer, uint256 value, uint256 amountOfTokens);

   // Indicates if the crowdsale has ended
   event Finalized();

   /// @notice Constructor of the crowsale to set up the main variables and create a token
   /// @param _wallet The wallet address that stores the Wei raised
   /// @param _tokenAddress The token used for the ICO
   function Crowdsale(
      address _wallet,
      address _tokenAddress,
      uint256 _startTime,
      uint256 _endTime
   ) {
      require(_wallet != address(0));
      require(_tokenAddress != address(0));

      // If you send the start and end time on the constructor, the end must be larger
      if(_startTime > 0 && _endTime > 0)
         require(_startTime < _endTime);

      wallet = _wallet;
      token = PallyCoin(_tokenAddress);
      vault = new RefundVault(_wallet);

      if(_startTime > 0)
         startTime = _startTime;

      if(_endTime > 0)
         endTime = _endTime;
   }

   /// @notice Fallback function to buy tokens
   function () payable {
      buyTokens();
   }

   /// @notice To buy tokens given an address
   function buyTokens() public payable whenNotPaused {
      require(validPurchase());

      uint256 tokens = 0;
      uint256 amountPaid = calculateExcessBalance();

      if(tokensRaised < 12.5e24) {

         // Tier 1
         tokens = amountPaid.mul(rate);

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > 12.5e24)
            tokens = calculateExcessTokens(amountPaid, 12.5e24, 1, rate);
      } else if(tokensRaised >= 12.5e24 && tokensRaised < 25e24) {

         // Tier 2
         tokens = amountPaid.mul(rateTier2);

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > 25e24)
            tokens = calculateExcessTokens(amountPaid, 25e24, 2, rateTier2);
      } else if(tokensRaised >= 25e24 && tokensRaised < 37.5e24) {

         // Tier 3
         tokens = amountPaid.mul(rateTier3);

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > 37.5e24)
            tokens = calculateExcessTokens(amountPaid, 37.5e24, 3, rateTier3);
      } else if(tokensRaised >= 37.5e24) {

         // Tier 4
         tokens = amountPaid.mul(rateTier4);
      }

      weiRaised = weiRaised.add(amountPaid);
      tokensRaised = tokensRaised.add(tokens);
      token.distributeICOTokens(msg.sender, tokens);

      // Keep a record of how many tokens everybody gets in case we need to do refunds
      tokensBought[msg.sender] = tokensBought[msg.sender].add(tokens);
      TokenPurchase(msg.sender, amountPaid, tokens);

      forwardFunds(amountPaid);
   }

   /// @notice Sends the funds to the wallet or to the refund vault smart contract
   /// if the minimum goal of tokens hasn&#39;t been reached yet
   /// @param amountPaid The amount of ether paid
   function forwardFunds(uint256 amountPaid) internal whenNotPaused {
      if(goalReached()) {
         wallet.transfer(amountPaid);
      } else {
         vault.deposit.value(amountPaid)(msg.sender);
      }

      // If the minimum goal of the ICO has been reach, close the vault to send
      // the ether to the wallet of the crowdsale
      checkCompletedCrowdsale();
   }

   /// @notice Calculates how many ether will be used to generate the tokens in
   /// case the buyer sends more than the maximum balance but has some balance left
   /// and updates the balance of that buyer.
   /// For instance if he&#39;s 1500 balance and he sends 1000, it will return 500
   /// and refund the other 500 ether
   function calculateExcessBalance() internal whenNotPaused returns(uint256) {
      uint256 amountPaid = msg.value;
      uint256 differenceWei = 0;
      uint256 exceedingBalance = 0;

      // If we&#39;re in the last tier, check that the limit hasn&#39;t been reached
      // and if so, refund the difference and return what will be used to
      // buy the remaining tokens
      if(tokensRaised >= 37.5e24) {
         uint256 addedTokens = tokensRaised.add(amountPaid.mul(rateTier4));

         // If tokensRaised + what you paid converted to tokens is bigger than the max
         if(addedTokens > maxTokensRaised) {

            // Refund the difference
            uint256 difference = addedTokens.sub(maxTokensRaised);
            differenceWei = difference.div(rateTier4);

            amountPaid = amountPaid.sub(differenceWei);
         }
      }

      uint256 addedBalance = crowdsaleBalances[msg.sender].add(amountPaid);

      if(addedBalance <= maxPurchase) {
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      } else {

         // Substracting 2000 ether in wei
         exceedingBalance = addedBalance.sub(maxPurchase);
         amountPaid = msg.value.sub(exceedingBalance);

         // Add that balance to the balances
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      }

      // Make the transfers at the end of the function for security purposes
      if(differenceWei > 0)
         msg.sender.transfer(differenceWei);

      if(exceedingBalance > 0) {

         // Return the exceeding balance to the buyer
         msg.sender.transfer(exceedingBalance);
      }

      return amountPaid;
   }

   /// @notice Set&#39;s the rate of tokens per ether for each tier. Use it after the
   /// smart contract is deployed to set the price according to the ether price
   /// at the start of the ICO
   /// @param tier1 The amount of tokens you get in the tier one
   /// @param tier2 The amount of tokens you get in the tier two
   /// @param tier3 The amount of tokens you get in the tier three
   /// @param tier4 The amount of tokens you get in the tier four
   function setTierRates(uint256 tier1, uint256 tier2, uint256 tier3, uint256 tier4)
      external onlyOwner whenNotPaused
   {
      require(tier1 > 0 && tier2 > 0 && tier3 > 0 && tier4 > 0);

      rate = tier1;
      rateTier2 = tier2;
      rateTier3 = tier3;
      rateTier4 = tier4;
   }

   /// @notice Check if the crowdsale has ended and enables refunds only in case the
   /// goal hasn&#39;t been reached
   function checkCompletedCrowdsale() public whenNotPaused {
      if(!isEnded) {
         if(hasEnded() && !goalReached()){
            vault.enableRefunds();

            isRefunding = true;
            isEnded = true;
            Finalized();
         } else if(hasEnded() && goalReached()) {
            vault.close();

            isEnded = true;
            Finalized();
         }
      }
   }

   /// @notice If crowdsale is unsuccessful, investors can claim refunds here
   function claimRefund() public whenNotPaused {
     require(hasEnded() && !goalReached() && isRefunding);

     vault.refund(msg.sender);
     token.refundTokens(msg.sender, tokensBought[msg.sender]);
   }

   /// @notice Buys the tokens for the specified tier and for the next one
   /// @param amount The amount of ether paid to buy the tokens
   /// @param tokensThisTier The limit of tokens of that tier
   /// @param tierSelected The tier selected
   /// @param _rate The rate used for that `tierSelected`
   /// @return uint The total amount of tokens bought combining the tier prices
   function calculateExcessTokens(
      uint256 amount,
      uint256 tokensThisTier,
      uint256 tierSelected,
      uint256 _rate
   ) public constant returns(uint256 totalTokens) {
      require(amount > 0 && tokensThisTier > 0 && _rate > 0);
      require(tierSelected >= 1 && tierSelected <= 4);

      uint weiThisTier = tokensThisTier.sub(tokensRaised).div(_rate);
      uint weiNextTier = amount.sub(weiThisTier);
      uint tokensNextTier = 0;

      // If there&#39;s excessive wei for the last tier, refund those
      if(tierSelected != 4)
         tokensNextTier = calculateTokensTier(weiNextTier, tierSelected.add(1));
      else
         msg.sender.transfer(weiNextTier);

      totalTokens = tokensThisTier.sub(tokensRaised).add(tokensNextTier);
   }

   /// @notice Buys the tokens given the price of the tier one and the wei paid
   /// @param weiPaid The amount of wei paid that will be used to buy tokens
   /// @param tierSelected The tier that you&#39;ll use for thir purchase
   /// @return calculatedTokens Returns how many tokens you&#39;ve bought for that wei paid
   function calculateTokensTier(uint256 weiPaid, uint256 tierSelected)
        internal constant returns(uint256 calculatedTokens)
   {
      require(weiPaid > 0);
      require(tierSelected >= 1 && tierSelected <= 4);

      if(tierSelected == 1)
         calculatedTokens = weiPaid.mul(rate);
      else if(tierSelected == 2)
         calculatedTokens = weiPaid.mul(rateTier2);
      else if(tierSelected == 3)
         calculatedTokens = weiPaid.mul(rateTier3);
      else
         calculatedTokens = weiPaid.mul(rateTier4);
   }


   /// @notice Checks if a purchase is considered valid
   /// @return bool If the purchase is valid or not
   function validPurchase() internal constant returns(bool) {
      bool withinPeriod = now >= startTime && now <= endTime;
      bool nonZeroPurchase = msg.value > 0;
      bool withinTokenLimit = tokensRaised < maxTokensRaised;
      bool minimumPurchase = msg.value >= minPurchase;
      bool hasBalanceAvailable = crowdsaleBalances[msg.sender] < maxPurchase;

      return withinPeriod && nonZeroPurchase && withinTokenLimit && minimumPurchase && hasBalanceAvailable;
   }

   /// @notice To see if the minimum goal of tokens of the ICO has been reached
   /// @return bool True if the tokens raised are bigger than the goal or false otherwise
   function goalReached() public constant returns(bool) {
      return tokensRaised >= minimumGoal;
   }

   /// @notice Public function to check if the crowdsale has ended or not
   function hasEnded() public constant returns(bool) {
      return now > endTime || tokensRaised >= maxTokensRaised;
   }
}