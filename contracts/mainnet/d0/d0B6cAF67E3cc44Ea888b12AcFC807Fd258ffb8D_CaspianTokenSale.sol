pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// ERC20Interface - Standard ERC20 Interface Definition
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Based on the final ERC20 specification at:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {

   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   function name() public view returns (string);
   function symbol() public view returns (string);
   function decimals() public view returns (uint8);
   function totalSupply() public view returns (uint256);

   function balanceOf(address _owner) public view returns (uint256 balance);
   function allowance(address _owner, address _spender) public view returns (uint256 remaining);

   function transfer(address _to, uint256 _value) public returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
   function approve(address _spender, uint256 _value) public returns (bool success);
}

// ----------------------------------------------------------------------------
// Math - General Math Utility Library
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


library Math {

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 r = a + b;

      require(r >= a);

      return r;
   }


   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(a >= b);

      return a - b;
   }


   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
         return 0;
      }

      uint256 r = a * b;

      require(r / a == b);

      return r;
   }


   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
   }
}

// ----------------------------------------------------------------------------
// Owned - Ownership model with 2 phase transfers
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


// Implements a simple ownership model with 2-phase transfer.
contract Owned {

   address public owner;
   address public proposedOwner;

   event OwnershipTransferInitiated(address indexed _proposedOwner);
   event OwnershipTransferCompleted(address indexed _newOwner);


   constructor() public
   {
      owner = msg.sender;
   }


   modifier onlyOwner() {
      require(isOwner(msg.sender) == true);
      _;
   }


   function isOwner(address _address) public view returns (bool) {
      return (_address == owner);
   }


   function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
      require(_proposedOwner != address(0));
      require(_proposedOwner != address(this));
      require(_proposedOwner != owner);

      proposedOwner = _proposedOwner;

      emit OwnershipTransferInitiated(proposedOwner);

      return true;
   }


   function completeOwnershipTransfer() public returns (bool) {
      require(msg.sender == proposedOwner);

      owner = msg.sender;
      proposedOwner = address(0);

      emit OwnershipTransferCompleted(owner);

      return true;
   }
}

// ----------------------------------------------------------------------------
// Finalizable - Basic implementation of the finalization pattern
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


contract Finalizable is Owned() {

   bool public finalized;

   event Finalized();


   constructor() public
   {
      finalized = false;
   }


   function finalize() public onlyOwner returns (bool) {
      require(!finalized);

      finalized = true;

      emit Finalized();

      return true;
   }
}

// ----------------------------------------------------------------------------
// OpsManaged - Implements an Owner and Ops Permission Model
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------



//
// Implements a security model with owner and ops.
//
contract OpsManaged is Owned() {

   address public opsAddress;

   event OpsAddressUpdated(address indexed _newAddress);


   constructor() public
   {
   }


   modifier onlyOwnerOrOps() {
      require(isOwnerOrOps(msg.sender));
      _;
   }


   function isOps(address _address) public view returns (bool) {
      return (opsAddress != address(0) && _address == opsAddress);
   }


   function isOwnerOrOps(address _address) public view returns (bool) {
      return (isOwner(_address) || isOps(_address));
   }


   function setOpsAddress(address _newOpsAddress) public onlyOwner returns (bool) {
      require(_newOpsAddress != owner);
      require(_newOpsAddress != address(this));

      opsAddress = _newOpsAddress;

      emit OpsAddressUpdated(opsAddress);

      return true;
   }
}

// ----------------------------------------------------------------------------
// ERC20Token - Standard ERC20 Implementation
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


contract ERC20Token is ERC20Interface {

   using Math for uint256;

   string  private tokenName;
   string  private tokenSymbol;
   uint8   private tokenDecimals;
   uint256 internal tokenTotalSupply;

   mapping(address => uint256) internal balances;
   mapping(address => mapping (address => uint256)) allowed;


   constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _initialTokenHolder) public {
      tokenName = _name;
      tokenSymbol = _symbol;
      tokenDecimals = _decimals;
      tokenTotalSupply = _totalSupply;

      // The initial balance of tokens is assigned to the given token holder address.
      balances[_initialTokenHolder] = _totalSupply;

      // Per EIP20, the constructor should fire a Transfer event if tokens are assigned to an account.
      emit Transfer(0x0, _initialTokenHolder, _totalSupply);
   }


   function name() public view returns (string) {
      return tokenName;
   }


   function symbol() public view returns (string) {
      return tokenSymbol;
   }


   function decimals() public view returns (uint8) {
      return tokenDecimals;
   }


   function totalSupply() public view returns (uint256) {
      return tokenTotalSupply;
   }


   function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
   }


   function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
   }


   function transfer(address _to, uint256 _value) public returns (bool success) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      emit Transfer(msg.sender, _to, _value);

      return true;
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      emit Transfer(_from, _to, _value);

      return true;
   }


   function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;

      emit Approval(msg.sender, _spender, _value);

      return true;
   }
}

// ----------------------------------------------------------------------------
// FinalizableToken - Extension to ERC20Token with ops and finalization
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


//
// ERC20 token with the following additions:
//    1. Owner/Ops Ownership
//    2. Finalization
//
contract FinalizableToken is ERC20Token, OpsManaged, Finalizable {

   using Math for uint256;


   // The constructor will assign the initial token supply to the owner (msg.sender).
   constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public
      ERC20Token(_name, _symbol, _decimals, _totalSupply, msg.sender)
      OpsManaged()
      Finalizable()
   {
   }


   function transfer(address _to, uint256 _value) public returns (bool success) {
      validateTransfer(msg.sender, _to);

      return super.transfer(_to, _value);
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      validateTransfer(msg.sender, _to);

      return super.transferFrom(_from, _to, _value);
   }


   function validateTransfer(address _sender, address _to) private view {
      // Once the token is finalized, everybody can transfer tokens.
      if (finalized) {
         return;
      }

      if (isOwner(_to)) {
         return;
      }

      // Before the token is finalized, only owner and ops are allowed to initiate transfers.
      // This allows them to move tokens while the sale is still ongoing for example.
      require(isOwnerOrOps(_sender));
   }
}



// ----------------------------------------------------------------------------
// FlexibleTokenSale - Token Sale Contract
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


contract FlexibleTokenSale is Finalizable, OpsManaged {

   using Math for uint256;

   //
   // Lifecycle
   //
   uint256 public startTime;
   uint256 public endTime;
   bool public suspended;

   //
   // Pricing
   //
   uint256 public tokensPerKEther;
   uint256 public bonus;
   uint256 public maxTokensPerAccount;
   uint256 public contributionMin;
   uint256 public tokenConversionFactor;

   //
   // Wallets
   //
   address public walletAddress;

   //
   // Token
   //
   FinalizableToken public token;

   //
   // Counters
   //
   uint256 public totalTokensSold;
   uint256 public totalEtherCollected;


   //
   // Events
   //
   event Initialized();
   event TokensPerKEtherUpdated(uint256 _newValue);
   event MaxTokensPerAccountUpdated(uint256 _newMax);
   event BonusUpdated(uint256 _newValue);
   event SaleWindowUpdated(uint256 _startTime, uint256 _endTime);
   event WalletAddressUpdated(address _newAddress);
   event SaleSuspended();
   event SaleResumed();
   event TokensPurchased(address _beneficiary, uint256 _cost, uint256 _tokens);
   event TokensReclaimed(uint256 _amount);


   constructor(uint256 _startTime, uint256 _endTime, address _walletAddress) public
      OpsManaged()
   {
      require(_endTime > _startTime);

      require(_walletAddress != address(0));
      require(_walletAddress != address(this));

      walletAddress = _walletAddress;

      finalized = false;
      suspended = false;

      startTime = _startTime;
      endTime   = _endTime;

      // Use some defaults config values. Classes deriving from FlexibleTokenSale
      // should set their own defaults
      tokensPerKEther     = 100000;
      bonus               = 0;
      maxTokensPerAccount = 0;
      contributionMin     = 0.1 ether;

      totalTokensSold     = 0;
      totalEtherCollected = 0;
   }


   function currentTime() public constant returns (uint256) {
      return now;
   }


   // Initialize should be called by the owner as part of the deployment + setup phase.
   // It will associate the sale contract with the token contract and perform basic checks.
   function initialize(FinalizableToken _token) external onlyOwner returns(bool) {
      require(address(token) == address(0));
      require(address(_token) != address(0));
      require(address(_token) != address(this));
      require(address(_token) != address(walletAddress));
      require(isOwnerOrOps(address(_token)) == false);

      token = _token;

      // This factor is used when converting cost <-> tokens.
      // 18 is because of the ETH -> Wei conversion.
      // 3 because prices are in K ETH instead of just ETH.
      // 4 because bonuses are expressed as 0 - 10000 for 0.00% - 100.00% (with 2 decimals).
      tokenConversionFactor = 10**(uint256(18).sub(_token.decimals()).add(3).add(4));
      require(tokenConversionFactor > 0);

      emit Initialized();

      return true;
   }


   //
   // Owner Configuation
   //

   // Allows the owner to change the wallet address which is used for collecting
   // ether received during the token sale.
   function setWalletAddress(address _walletAddress) external onlyOwner returns(bool) {
      require(_walletAddress != address(0));
      require(_walletAddress != address(this));
      require(_walletAddress != address(token));
      require(isOwnerOrOps(_walletAddress) == false);

      walletAddress = _walletAddress;

      emit WalletAddressUpdated(_walletAddress);

      return true;
   }


   // Allows the owner to set an optional limit on the amount of tokens that can be purchased
   // by a contributor. It can also be set to 0 to remove limit.
   function setMaxTokensPerAccount(uint256 _maxTokens) external onlyOwner returns(bool) {

      maxTokensPerAccount = _maxTokens;

      emit MaxTokensPerAccountUpdated(_maxTokens);

      return true;
   }


   // Allows the owner to specify the conversion rate for ETH -> tokens.
   // For example, passing 1,000,000 would mean that 1 ETH would purchase 1000 tokens.
   function setTokensPerKEther(uint256 _tokensPerKEther) external onlyOwner returns(bool) {
      require(_tokensPerKEther > 0);

      tokensPerKEther = _tokensPerKEther;

      emit TokensPerKEtherUpdated(_tokensPerKEther);

      return true;
   }


   // Allows the owner to set a bonus to apply to all purchases.
   // For example, setting it to 2000 means that instead of receiving 200 tokens,
   // for a given price, contributors would receive 240 tokens (20.00% bonus).
   function setBonus(uint256 _bonus) external onlyOwner returns(bool) {
      require(_bonus <= 10000);

      bonus = _bonus;

      emit BonusUpdated(_bonus);

      return true;
   }


   // Allows the owner to set a sale window which will allow the sale (aka buyTokens) to
   // receive contributions between _startTime and _endTime. Once _endTime is reached,
   // the sale contract will automatically stop accepting incoming contributions.
   function setSaleWindow(uint256 _startTime, uint256 _endTime) external onlyOwner returns(bool) {
      require(_startTime > 0);
      require(_endTime > _startTime);

      startTime = _startTime;
      endTime   = _endTime;

      emit SaleWindowUpdated(_startTime, _endTime);

      return true;
   }


   // Allows the owner to suspend the sale until it is manually resumed at a later time.
   function suspend() external onlyOwner returns(bool) {
      if (suspended == true) {
          return false;
      }

      suspended = true;

      emit SaleSuspended();

      return true;
   }


   // Allows the owner to resume the sale.
   function resume() external onlyOwner returns(bool) {
      if (suspended == false) {
          return false;
      }

      suspended = false;

      emit SaleResumed();

      return true;
   }


   //
   // Contributions
   //

   // Default payable function which can be used to purchase tokens.
   function () payable public {
      buyTokens(msg.sender);
   }


   // Allows the caller to purchase tokens for a specific beneficiary (proxy purchase).
   function buyTokens(address _beneficiary) public payable returns (uint256) {
      return buyTokensInternal(_beneficiary, bonus);
   }


   function buyTokensInternal(address _beneficiary, uint256 _bonus) internal returns (uint256) {
      require(!finalized);
      require(!suspended);
      require(currentTime() >= startTime);
      require(currentTime() <= endTime);
      require(msg.value >= contributionMin);
      require(_beneficiary != address(0));
      require(_beneficiary != address(this));
      require(_beneficiary != address(token));

      // We don&#39;t want to allow the wallet collecting ETH to
      // directly be used to purchase tokens.
      require(msg.sender != address(walletAddress));

      // Check how many tokens are still available for sale.
      uint256 saleBalance = token.balanceOf(address(this));
      require(saleBalance > 0);

      // Calculate how many tokens the contributor could purchase based on ETH received.
      uint256 tokens = msg.value.mul(tokensPerKEther).mul(_bonus.add(10000)).div(tokenConversionFactor);
      require(tokens > 0);

      uint256 cost = msg.value;
      uint256 refund = 0;

      // Calculate what is the maximum amount of tokens that the contributor
      // should be allowed to purchase
      uint256 maxTokens = saleBalance;

      if (maxTokensPerAccount > 0) {
         // There is a maximum amount of tokens per account in place.
         // Check if the user already hit that limit.
         uint256 userBalance = getUserTokenBalance(_beneficiary);
         require(userBalance < maxTokensPerAccount);

         uint256 quotaBalance = maxTokensPerAccount.sub(userBalance);

         if (quotaBalance < saleBalance) {
            maxTokens = quotaBalance;
         }
      }

      require(maxTokens > 0);

      if (tokens > maxTokens) {
         // The contributor sent more ETH than allowed to purchase.
         // Limit the amount of tokens that they can purchase in this transaction.
         tokens = maxTokens;

         // Calculate the actual cost for that new amount of tokens.
         cost = tokens.mul(tokenConversionFactor).div(tokensPerKEther.mul(_bonus.add(10000)));

         if (msg.value > cost) {
            // If the contributor sent more ETH than needed to buy the tokens,
            // the balance should be refunded.
            refund = msg.value.sub(cost);
         }
      }

      // This is the actual amount of ETH that can be sent to the wallet.
      uint256 contribution = msg.value.sub(refund);
      walletAddress.transfer(contribution);

      // Update our stats counters.
      totalTokensSold     = totalTokensSold.add(tokens);
      totalEtherCollected = totalEtherCollected.add(contribution);

      // Transfer tokens to the beneficiary.
      require(token.transfer(_beneficiary, tokens));

      // Issue a refund for the excess ETH, as needed.
      if (refund > 0) {
         msg.sender.transfer(refund);
      }

      emit TokensPurchased(_beneficiary, cost, tokens);

      return tokens;
   }


   // Returns the number of tokens that the user has purchased. Will be checked against the
   // maximum allowed. Can be overriden in a sub class to change the calculations.
   function getUserTokenBalance(address _beneficiary) internal view returns (uint256) {
      return token.balanceOf(_beneficiary);
   }


   // Allows the owner to take back the tokens that are assigned to the sale contract.
   function reclaimTokens() external onlyOwner returns (bool) {
      uint256 tokens = token.balanceOf(address(this));

      if (tokens == 0) {
         return false;
      }

      address tokenOwner = token.owner();
      require(tokenOwner != address(0));

      require(token.transfer(tokenOwner, tokens));

      emit TokensReclaimed(tokens);

      return true;
   }
}


// ----------------------------------------------------------------------------
// CaspianTokenConfig - Token Contract Configuration
//
// Copyright (c) 2018 Caspian, Limited (TM).
// http://www.caspian.tech/
// ----------------------------------------------------------------------------


contract CaspianTokenConfig {

    string  public constant TOKEN_SYMBOL      = "CSP";
    string  public constant TOKEN_NAME        = "Caspian Token";
    uint8   public constant TOKEN_DECIMALS    = 18;

    uint256 public constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}



// ----------------------------------------------------------------------------
// CaspianTokenSaleConfig - Token Sale Configuration
//
// Copyright (c) 2018 Caspian, Limited (TM).
// http://www.caspian.tech/
// ----------------------------------------------------------------------------


contract CaspianTokenSaleConfig is CaspianTokenConfig {

    //
    // Time
    //
    uint256 public constant INITIAL_STARTTIME    = 1538553600; // 2018-10-03, 08:00:00 UTC
    uint256 public constant INITIAL_ENDTIME      = 1538726400; // 2018-10-05, 08:00:00 UTC


    //
    // Purchases
    //

    // Minimum amount of ETH that can be used for purchase.
    uint256 public constant CONTRIBUTION_MIN     = 0.5 ether;

    // Price of tokens, based on the 1 ETH = 4000 CSP conversion ratio.
    uint256 public constant TOKENS_PER_KETHER    = 4000000;

    // Amount of bonus applied to the sale. 2000 = 20.00% bonus, 750 = 7.50% bonus, 0 = no bonus.
    uint256 public constant BONUS                = 0;

    // Maximum amount of tokens that can be purchased for each account. 0 for no maximum.
    uint256 public constant TOKENS_ACCOUNT_MAX   = 400000 * DECIMALSFACTOR; // 100 ETH Max
}


// ----------------------------------------------------------------------------
// CaspianTokenSale - Token Sale Contract
//
// Copyright (c) 2018 Caspian, Limited (TM).
// http://www.caspian.tech/
//
// Based on code from Enuma Technologies.
// Copyright (c) 2017 Enuma Technologies Limited.
// ----------------------------------------------------------------------------


contract CaspianTokenSale is FlexibleTokenSale, CaspianTokenSaleConfig {

   //
   // Whitelist
   //
   uint8 public currentPhase;

   mapping(address => uint8) public whitelist;


   //
   // Events
   //
   event WhitelistUpdated(address indexed _account, uint8 _phase);


   constructor(address wallet) public
      FlexibleTokenSale(INITIAL_STARTTIME, INITIAL_ENDTIME, wallet)
   {
      tokensPerKEther     = TOKENS_PER_KETHER;
      bonus               = BONUS;
      maxTokensPerAccount = TOKENS_ACCOUNT_MAX;
      contributionMin     = CONTRIBUTION_MIN;
      currentPhase        = 1;
   }


   // Allows the owner or ops to add/remove people from the whitelist.
   function updateWhitelist(address _address, uint8 _phase) external onlyOwnerOrOps returns (bool) {
      return updateWhitelistInternal(_address, _phase);
   }


   function updateWhitelistInternal(address _address, uint8 _phase) internal returns (bool) {
      require(_address != address(0));
      require(_address != address(this));
      require(_address != walletAddress);
      require(_phase <= 1);

      whitelist[_address] = _phase;

      emit WhitelistUpdated(_address, _phase);

      return true;
   }


   // Allows the owner or ops to add/remove people from the whitelist, in batches.
   function updateWhitelistBatch(address[] _addresses, uint8 _phase) external onlyOwnerOrOps returns (bool) {
      require(_addresses.length > 0);

      for (uint256 i = 0; i < _addresses.length; i++) {
         require(updateWhitelistInternal(_addresses[i], _phase));
      }

      return true;
   }


   // This is an extension to the buyToken function in FlexibleTokenSale which also takes
   // care of checking contributors against the whitelist. Since buyTokens supports proxy payments
   // we check that both the sender and the beneficiary have been whitelisted.
   function buyTokensInternal(address _beneficiary, uint256 _bonus) internal returns (uint256) {
      require(whitelist[msg.sender] >= currentPhase);
      require(whitelist[_beneficiary] >= currentPhase);

      return super.buyTokensInternal(_beneficiary, _bonus);
   }
}