pragma solidity ^0.4.13;

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    isWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract OMICrowdsale is WhitelistedCrowdsale, Pausable {
  using SafeMath for uint256;

  /* 
   *  Constants
   */
  uint256 constant crowdsaleStartTime = 1530273600; // Pacific/Auckland 2018-06-30 00:00:00 
  uint256 constant crowdsaleFinishTime = 1538222400; // Pacific/Auckland 2018-09-30 00:00:00
  uint256 constant crowdsaleUSDGoal = 22125000;
  uint256 constant crowdsaleTokenGoal = 362500000*1e18;
  uint256 constant minimumTokenPurchase = 2500*1e18;
  uint256 constant maximumTokenPurchase = 5000000*1e18;

  /*
   *  Storage
   */
  OMIToken public token;
  OMITokenLock public tokenLock;

  uint256 public totalUSDRaised;
  uint256 public totalTokensSold;
  bool public isFinalized = false;

  mapping(address => uint256) public purchaseRecords;

  /*
   *  Events
   */
  event RateChanged(uint256 newRate);
  event USDRaisedUpdated(uint256 newTotal);
  event WhitelistAddressAdded(address newWhitelistAddress);
  event WhitelistAddressRemoved(address removedWhitelistAddress);
  event CrowdsaleStarted();
  event CrowdsaleFinished();


  /*
   *  Modifiers
   */
  modifier whenNotFinalized () {
    require(!isFinalized);
    _;
  }

  /*
   *  Public Functions
   */
  /// @dev Contract constructor sets...
  function OMICrowdsale (
    uint256 _startingRate,
    address _ETHWallet,
    address _OMIToken,
    address _OMITokenLock
  )
    Crowdsale(_startingRate, _ETHWallet, ERC20(_OMIToken))
    public
  {
    token = OMIToken(_OMIToken);
    require(token.isOMITokenContract());

    tokenLock = OMITokenLock(_OMITokenLock);
    require(tokenLock.isOMITokenLockContract());

    rate = _startingRate;
  }

  /// @dev Function to call from other contracts to ensure that this is the proper contract
  function isOMICrowdsaleContract()
    public 
    pure 
    returns(bool)
  { 
    return true; 
  }

  /// @dev Function to check if crowdsale is open
  function isOpen()
    public
    view
    whenNotPaused
    whenNotFinalized
    returns(bool)
  {
    return now >= crowdsaleStartTime;
  }

  /// @dev Allows the owner to set the current rate for calculating the number of tokens for a purchase.
  /// @dev An external cron job will fetch the ETH/USD daily average from the cryptocompare API and call this function.
  function setRate(uint256 _newRate)
    public
    onlyOwner
    whenNotFinalized
    returns(bool)
  {
    require(_newRate > 0);
    rate = _newRate;
    RateChanged(rate);
    return true;
  }

  /// @dev Allows the owner to update the total amount of USD raised. T
  function setUSDRaised(uint256 _total)
    public
    onlyOwner
    whenNotFinalized
  {
    require(_total > 0);
    totalUSDRaised = _total;
    USDRaisedUpdated(_total);
  }

  /// @dev Gets the purchase records for a given address
  /// @param _beneficiary Tokan purchaser
  function getPurchaseRecord(address _beneficiary) 
    public 
    view 
    isWhitelisted(_beneficiary)
    returns(uint256)
  {
    return purchaseRecords[_beneficiary];
  }

  /// @dev Adds single address to whitelist
  /// @param _beneficiary Address to be added to the whitelist
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
    WhitelistAddressAdded(_beneficiary);
  }

  /// @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
  /// @param _beneficiaries Addresses to be added to the whitelist
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
      WhitelistAddressAdded(_beneficiaries[i]);
    }
  }

  /// @dev Removes single address from whitelist.
  /// @param _beneficiary Address to be removed to the whitelist
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
    WhitelistAddressRemoved(_beneficiary);
  }

  /// @dev Finalizes the crowdsale
  function finalize() external onlyOwner {
    _finalization();
  }

  /*
   *  Internal Functions
   */
  /// @dev Extend parent behavior to check if current stage should close. Must call super to ensure the enforcement of the whitelist.
  /// @param _beneficiary Token purchaser
  /// @param _weiAmount Amount of wei contributed
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
    internal
    whenNotPaused
    whenNotFinalized
   {
    super._preValidatePurchase(_beneficiary, _weiAmount);

    // Beneficiary&#39;s total should be between the minimum and maximum purchase amounts
    uint256 _totalPurchased = purchaseRecords[_beneficiary].add(_getTokenAmount(_weiAmount));
    require(_totalPurchased >= minimumTokenPurchase);
    require(_totalPurchased <= maximumTokenPurchase);

    // Must make the purchase from the intended whitelisted address
    require(msg.sender == _beneficiary);

    // Must be after the start time
    require(now >= crowdsaleStartTime);
  }

  /// @dev Overrides parent by storing balances in timelock contract instead of issuing tokens right away.
  /// @param _beneficiary Token purchaser
  /// @param _tokenAmount Amount of tokens purchased
  function _processPurchase(address _beneficiary, uint256 _tokenAmount)
    internal
  {
    // Lock beneficiary&#39;s tokens
    tokenLock.lockTokens(_beneficiary, 1 weeks, _tokenAmount);
  }

  /// @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
  /// @param _beneficiary Address receiving the tokens
  /// @param _weiAmount Value in wei involved in the purchase
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
    internal
  {
    uint256 _tokenAmount = _getTokenAmount(_weiAmount);

    // Add token amount to the purchase history
    purchaseRecords[_beneficiary] = purchaseRecords[_beneficiary].add(_tokenAmount);
    
    // Add token amount to total tokens sold
    totalTokensSold = totalTokensSold.add(_tokenAmount);

    // Finish the crowdsale...
    // ...if there is not a minimum purchase left
    if (crowdsaleTokenGoal.sub(totalTokensSold) < minimumTokenPurchase) {
      _finalization();
    }
    // ...if USD funding goal has been reached
    if (totalUSDRaised >= crowdsaleUSDGoal) {
      _finalization();
    }
    // ...if the time is after the crowdsale end time
    if (now > crowdsaleFinishTime) {
      _finalization();
    }
  }

  /// @dev Finalizes crowdsale
  function _finalization()
    internal
    whenNotFinalized
  {
    isFinalized = true;
    tokenLock.finishCrowdsale();
    CrowdsaleFinished();
  }
}

contract OMITokenLock is Ownable, Pausable {
  using SafeMath for uint256;

  /*
   *  Storage
   */
  OMIToken public token;
  OMICrowdsale public crowdsale;
  address public allowanceProvider;
  bool public crowdsaleFinished = false;
  uint256 public crowdsaleEndTime;

  struct Lock {
    uint256 amount;
    uint256 lockDuration;
    bool released;
    bool revoked;
  }
  struct TokenLockVault {
    address beneficiary;
    uint256 tokenBalance;
    uint256 lockIndex;
    Lock[] locks;
  }
  mapping(address => TokenLockVault) public tokenLocks;
  address[] public lockIndexes;
  uint256 public totalTokensLocked;

  /*
   *  Modifiers
   */
  modifier ownerOrCrowdsale () {
    require(msg.sender == owner || OMICrowdsale(msg.sender) == crowdsale);
    _;
  }

  /*
   *  Events
   */
  event LockedTokens(address indexed beneficiary, uint256 amount, uint256 releaseTime);
  event UnlockedTokens(address indexed beneficiary, uint256 amount);
  event FinishedCrowdsale();

  /*
   *  Public Functions
   */
  /// @dev Constructor function
  function OMITokenLock (address _token, address _allowanceProvider) public {
    token = OMIToken(_token);
    require(token.isOMITokenContract());

    allowanceProvider = _allowanceProvider;
  }

  /// @dev Function to call from other contracts to ensure that this is the proper contract
  function isOMITokenLockContract()
    public 
    pure 
    returns(bool)
  { 
    return true; 
  }

  /// @dev Sets the crowdsale address to allow authorize locking permissions
  /// @param _crowdsale The address of the crowdsale
  function setCrowdsaleAddress (address _crowdsale)
    public
    onlyOwner
    returns (bool)
  {
    crowdsale = OMICrowdsale(_crowdsale);
    require(crowdsale.isOMICrowdsaleContract());

    return true;
  }

  /// @dev Sets the token allowance provider address
  /// @param _allowanceProvider The address of the token allowance provider
  function setAllowanceAddress (address _allowanceProvider)
    public
    onlyOwner
    returns (bool)
  {
    allowanceProvider = _allowanceProvider;
    return true;
  }

  /// @dev Marks the crowdsale as being finished and sets the crowdsale finish date
  function finishCrowdsale()
    public
    ownerOrCrowdsale
    whenNotPaused
  {
    require(!crowdsaleFinished);
    crowdsaleFinished = true;
    crowdsaleEndTime = now;
    FinishedCrowdsale();
  }

  /// @dev Gets the total amount of tokens for a given address
  /// @param _beneficiary The address for which to look up the total token amount
  function getTokenBalance(address _beneficiary)
    public
    view
    returns (uint)
  {
    return tokenLocks[_beneficiary].tokenBalance;
  }

  /// @dev Gets the total number of locks for a given address
  /// @param _beneficiary The address for which to look up the total number of locks
  function getNumberOfLocks(address _beneficiary)
    public
    view
    returns (uint)
  {
    return tokenLocks[_beneficiary].locks.length;
  }

  /// @dev Gets the lock at a given index for a given address
  /// @param _beneficiary The address used to look up the lock
  /// @param _lockIndex The index used to look up the lock
  function getLockByIndex(address _beneficiary, uint256 _lockIndex)
    public
    view
    returns (uint256 amount, uint256 lockDuration, bool released, bool revoked)
  {
    require(_lockIndex >= 0);
    require(_lockIndex <= tokenLocks[_beneficiary].locks.length.sub(1));

    return (
      tokenLocks[_beneficiary].locks[_lockIndex].amount,
      tokenLocks[_beneficiary].locks[_lockIndex].lockDuration,
      tokenLocks[_beneficiary].locks[_lockIndex].released,
      tokenLocks[_beneficiary].locks[_lockIndex].revoked
    );
  }

  /// @dev Revokes the lock at a given index for a given address
  /// @param _beneficiary The address used to look up the lock
  /// @param _lockIndex The lock index to be revoked
  function revokeLockByIndex(address _beneficiary, uint256 _lockIndex)
    public
    onlyOwner
    returns (bool)
  {
    require(_lockIndex >= 0);
    require(_lockIndex <= tokenLocks[_beneficiary].locks.length.sub(1));
    require(!tokenLocks[_beneficiary].locks[_lockIndex].revoked);

    tokenLocks[_beneficiary].locks[_lockIndex].revoked = true;

    return true;
  }

  /// @dev Locks tokens for a given beneficiary
  /// @param _beneficiary The address to which the tokens will be released
  /// @param _lockDuration The duration of time that must elapse after the crowdsale end date
  /// @param _tokens The amount of tokens to be locked
  function lockTokens(address _beneficiary, uint256 _lockDuration, uint256 _tokens)
    external
    ownerOrCrowdsale
    whenNotPaused
  {
    // Lock duration must be greater than zero seconds
    require(_lockDuration >= 0);
    // Token amount must be greater than zero
    require(_tokens > 0);

    // Token Lock must have a sufficient allowance prior to creating locks
    require(_tokens.add(totalTokensLocked) <= token.allowance(allowanceProvider, address(this)));

    TokenLockVault storage lock = tokenLocks[_beneficiary];

    // If this is the first lock for this beneficiary, add their address to the lock indexes
    if (lock.beneficiary == 0) {
      lock.beneficiary = _beneficiary;
      lock.lockIndex = lockIndexes.length;
      lockIndexes.push(_beneficiary);
    }

    // Add the lock
    lock.locks.push(Lock(_tokens, _lockDuration, false, false));

    // Update the total tokens for this beneficiary
    lock.tokenBalance = lock.tokenBalance.add(_tokens);

    // Update the number of locked tokens
    totalTokensLocked = _tokens.add(totalTokensLocked);

    LockedTokens(_beneficiary, _tokens, _lockDuration);
  }

  /// @dev Transfers any tokens held in a timelock vault to beneficiary if they are due for release.
  function releaseTokens()
    public
    whenNotPaused
    returns(bool)
  {
    require(crowdsaleFinished);
    require(_release(msg.sender));
    return true;
  }

  /// @dev Transfers tokens held by timelock to all beneficiaries within the provided range.
  /// @param _beneficiary The user for which token locks should be released.
  function releaseTokensByAddress(address _beneficiary)
    external
    whenNotPaused
    onlyOwner
    returns (bool)
  {
    require(crowdsaleFinished);
    require(_release(_beneficiary));
    return true;
  }

  /*
   *  Internal Functions
   */
  /// @dev Reviews and releases token for a given beneficiary
  /// @param _beneficiary address for which a token release should be attempted
  function _release(address _beneficiary)
    internal
    whenNotPaused
    returns (bool)
  {
    TokenLockVault memory lock = tokenLocks[_beneficiary];
    require(lock.beneficiary == _beneficiary);
    require(_beneficiary != 0x0);

    bool hasUnDueLocks = false;

    for (uint256 i = 0; i < lock.locks.length; i++) {
      Lock memory currentLock = lock.locks[i];
      // Skip any locks which are already released or revoked
      if (currentLock.released || currentLock.revoked) {
        continue;
      }

      // Skip any locks that are not due for release
      if (crowdsaleEndTime.add(currentLock.lockDuration) >= now) {
        hasUnDueLocks = true;
        continue;
      }

      // The amount of tokens to transfer must be less than the number of locked tokens
      require(currentLock.amount <= token.allowance(allowanceProvider, address(this)));

      // Release Tokens
      UnlockedTokens(_beneficiary, currentLock.amount);
      tokenLocks[_beneficiary].locks[i].released = true;
      tokenLocks[_beneficiary].tokenBalance = tokenLocks[_beneficiary].tokenBalance.sub(currentLock.amount);
      totalTokensLocked = totalTokensLocked.sub(currentLock.amount);
      assert(token.transferFrom(allowanceProvider, _beneficiary, currentLock.amount));
    }

    // If there are no future locks to be released, delete the lock vault
    if (!hasUnDueLocks) {
      delete tokenLocks[_beneficiary];
      lockIndexes[lock.lockIndex] = 0x0;
    }

    return true;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    onlyOwner
    canMint
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract OMIToken is CappedToken, PausableToken {
  string public constant name = "Ecomi Token";
  string public constant symbol = "OMI";
  uint256 public decimals = 18;

  function OMIToken() public CappedToken(1000000000*1e18) {}

  /// @dev Function to call from other contracts to ensure that this is the proper contract
  function isOMITokenContract()
    public 
    pure 
    returns(bool)
  { 
    return true; 
  }
}