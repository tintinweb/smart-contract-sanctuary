pragma solidity ^0.4.23;

// File: contracts\all\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public adminAddress;

  event AdminAddressUpdated(address indexed newAdminAddress);
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

  modifier onlyOwnerOrAdmin(){
    require(isOwnerOrAdmin(msg.sender));
    _;
  }

  function isAdmin(address _address) public view returns (bool){
    return (adminAddress != address(0) && _address == adminAddress);
  }

  function isOwner(address _address) public view returns (bool){
    return (owner != address(0) && _address == owner);
  }

  function isOwnerOrAdmin(address _address) public view returns (bool){
    return (isOwner(_address) || isAdmin(_address));
  }

  function setAdminAddress(address _newAdminAddress) public onlyOwner returns (bool){
    require(_newAdminAddress != owner);
    require(_newAdminAddress != address(this));

    adminAddress = _newAdminAddress;
    emit AdminAddressUpdated(adminAddress);

    return true;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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

// File: contracts\all\Finalizable.sol

// ----------------------------------------------------------------------------
// Finalizable - Basic implementation of the finalization pattern
// ----------------------------------------------------------------------------



contract Finalizable is Ownable {

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

// File: contracts\all\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: contracts\all\ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender)
    public view returns (uint256);
  function transferFrom(address from, address to, uint256 value)
    public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts\all\StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) balances;

  uint256 public totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply;
  }

  /**
  * @dev Transfer token for a specified address
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
  * @param _account The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _account) public view returns (uint256) {
    return balances[_account];
  }

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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts\all\FinalizableToken.sol

// ----------------------------------------------------------------------------
// FinalizableToken - Extension to StandardToken with Owner and finalization
// ----------------------------------------------------------------------------






//
// ERC20 token with the following additions:
//    1. Owner/Admin Ownership
//    2. Finalization
//
contract FinalizableToken is StandardToken, Ownable, Finalizable {

   using SafeMath for uint256;


   // The constructor will assign the initial token supply to the owner (msg.sender).
   constructor() public
      StandardToken()
      Ownable()
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
      require(_to != address(0));

      // Once the token is finalized, everybody can transfer tokens.
      if (finalized) {
         return;
      }

      if (isOwner(_to)) {
         return;
      }

      // Before the token is finalized, only owner and admin are allowed to initiate transfers.
      // This allows them to move tokens while the sale is still ongoing for example.
      require(isOwnerOrAdmin(_sender));
   }
}

// File: contracts\all\SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around FinalizableToken operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for FinalizableToken;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(FinalizableToken token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    FinalizableToken token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(FinalizableToken token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: contracts\all\Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract Crowdsale is Finalizable{
  using SafeMath for uint256;
  using SafeERC20 for FinalizableToken;

  // The token being sold
  FinalizableToken public token;

  // Address where funds are collected
  address public wallet;

  bool public saleSuspended;

  //================Pricing=====================
  // How many token units a buyer gets per wei.
  // The tokensPerEther is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a tokensPerEther of 1 with a DetailedERC20 token with 3 decimals called TOK
  uint256 public tokensPerEther;
  uint256 public maxContribution;
  uint256 public minContribution;
  uint256 public tokenConversionFactor;
  uint256 public currentStage;
  uint256 public finalStage;

  mapping(uint256 => uint256) bonusStages;
  mapping(uint256 => uint256) bonusStagesTokenBalance;
  mapping(address => uint256) balanceEth;

  //============== Sales status===================
  uint256 public totalTokensSold;
  uint256 public weiRaised;

  event TokensPerEtherUpdated(uint256 _newValue);
  event MaxContributionUpdated(uint256 _newMax);
  event MinContributionUpdated(uint256 _newMin);
  event BonusUpdated(uint256 _stage, uint256 _newBonus);
  event SaleWindowUpdated(uint256 _startTime, uint256 _endTime);
  event WalletAddressUpdated(address _newAddress);
  event SaleSuspended();
  event SaleResumed();
  event TokensPurchased(address _beneficiary, uint256 _cost, uint256 _tokens);

  /**
   * @param _tokensPerEther Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _tokensPerEther, address _wallet, FinalizableToken _token) public {
    require(_tokensPerEther > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    tokensPerEther = _tokensPerEther;
    wallet = _wallet;
    token = _token;

    finalized = false;
    saleSuspended = false;

    // Use some defaults config values. 
    // should set their own defaults
    currentStage        = 0;
    finalStage          = 2;
    bonusStages[0]      = 2000;
    bonusStages[1]      = 1500;
    bonusStages[2]      = 1000;
    // bonusStages[3]      = 500;
    // bonusStages[4]      = 0;
    bonusStagesTokenBalance[0] = 10000*10**(18);
    bonusStagesTokenBalance[1] = 10000*10**(18);
    bonusStagesTokenBalance[2] = 10000*10**(18);
    maxContribution     = 2 ether; //100 ether
    minContribution     = 0.5 ether; // 5 ether during Pre-ICO,2 ether during public sale 
    totalTokensSold     = 0;
    weiRaised           = 0;

    // This factor is used when converting cost <-> tokens.
    // 4 because bonuses are expressed as 0 - 10000 for 0.00% - 100.00% (with 2 decimals).
    tokenConversionFactor = 10**4;
    require(tokenConversionFactor > 0);
  }

  //==================Owner configuration====================
  // Allows the owner to change the wallet address which is used for collecting
  // ether received during the token sale.
  function setWalletAddress(address _walletAddress) external onlyOwner returns(bool) {
    require(_walletAddress != address(0));
    require(_walletAddress != address(this));
    require(_walletAddress != address(token));
    require(isOwnerOrAdmin(_walletAddress) == false);

    wallet = _walletAddress;

    emit WalletAddressUpdated(_walletAddress);

    return true;
  }

  // Allows the owner to set an optional limit on the amount of ether that can be contributed
  // by a contributor. It can also be set to 0 to remove limit.
  function setMaxContribution(uint256 _maxEthers) external onlyOwner returns(bool) {
    require(_maxEthers > minContribution);
    maxContribution = _maxEthers;

    emit MaxContributionUpdated(_maxEthers);

    return true;
  }

  // Allows the owner to set an minimum amount of ether that can be contributed
  // by a contributor. It can also be set to 0 to remove limit.
  function setMinContribution(uint256 _minEthers) external onlyOwner returns(bool) {
    require(_minEthers < maxContribution);
    minContribution = _minEthers;

    emit MinContributionUpdated(_minEthers);

    return true;
  }

  // Allows the owner to specify the conversion rate for ETH -> tokens.
  // For example, passing 1,000 would mean that 1 ETH would purchase 1,000 tokens.
  function setTokensPerEther(uint256 _tokensPerEther) external onlyOwner returns(bool) {
    require(_tokensPerEther > 0);

    tokensPerEther = _tokensPerEther;

    emit TokensPerEtherUpdated(_tokensPerEther);

    return true;
  }

  // Allows the owner to set a bonus to apply to all purchases.
  // For example, setting it to 2000 means that instead of receiving 200 tokens,
  // for a given price, contributors would receive 240 tokens (20.00% bonus).
  function setBonus(uint256 _stage, uint256 _bonus) external onlyOwner returns(bool) {
    require(_bonus <= 10000);
    require(_stage > currentStage);

    bonusStages[_stage] = _bonus;

    emit BonusUpdated(_stage , _bonus);

    return true;
  }

  //Progress to the next stage bonus
  function nextStageBonus() internal {
    require(currentStage <= finalStage);
    currentStage=currentStage.add(1);
  }

  function getStageBonus() public view returns (uint256) {
    return bonusStages[currentStage];
  }

  function getCurrentStage() public view returns (uint256) {
    return currentStage;
  }

  // Allows the owner to suspend the sale until it is manually resumed at a later time.
   function suspendSale() external onlyOwner returns(bool) {
      if (saleSuspended == true) {
          return false;
      }

      saleSuspended = true;

      emit SaleSuspended();

      return true;
   }

   // Allows the owner to resume the sale.
   function resume() external onlyOwner returns(bool) {
      if (saleSuspended == false) {
          return false;
      }

      saleSuspended = false;

      emit SaleResumed();

      return true;
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
    uint256 refund = 0;

    _preValidatePurchase(_beneficiary, weiAmount);

    //Check how many tokens are still available for sale.
    uint256 saleBalance = token.balanceOf(address(this));
    require(saleBalance > 0);

    //Maximum number of Eth user can buy
    uint256 maxEth = weiAmount;
    if (maxContribution > 0) {
         // There is a maximum amount of Eth per account in place.
         // Check if the user already hit that limit.
         uint256 userBalance = balanceEthOf(_beneficiary);
         require(userBalance <= maxContribution);

         uint256 quotaBalance = maxContribution.sub(userBalance);

         if (quotaBalance < maxEth) {
            maxEth = quotaBalance;
         }
    }

    require(maxEth > 0);

    if (weiAmount > maxEth) {
        // The contributor sent more ETH than allowed to purchase.
        // Limit the amount of ETH that they can contribute.
        refund = weiAmount.sub(maxEth);
    }

    // calculate token amount to be created

    uint256 tokensTemp = 0;
    uint256 ethTemp = maxEth;
    uint256 tokenCheck = _getTokenAmount(ethTemp);

    while( tokenCheck > bonusStagesTokenBalance[currentStage]){
      require(currentStage < finalStage);
      tokensTemp = tokensTemp.add(bonusStagesTokenBalance[currentStage]);
      ethTemp = ethTemp.sub(tokensToEth(bonusStagesTokenBalance[currentStage], currentStage));
      bonusStagesTokenBalance[currentStage] = 0;
      tokenCheck = _getTokenAmount(ethTemp);

      nextStageBonus();
    }

    //Update tokens remain in the current bonus stage.
    bonusStagesTokenBalance[currentStage] = bonusStagesTokenBalance[currentStage].sub(tokenCheck);

    uint256 tokens = _getTokenAmount(ethTemp).add(tokensTemp);

    // update state
    weiRaised = weiRaised.add(maxEth);
    totalTokensSold = totalTokensSold.add(tokens);

    _processPurchase(_beneficiary, tokens);

    if(refund > 0){
      msg.sender.transfer(refund);
    }

    emit TokensPurchased(
      _beneficiary,
      maxEth,
      tokens
    );

    _updatePurchasingState(_beneficiary, maxEth);

    _forwardFunds(maxEth);
    _postValidatePurchase(_beneficiary, maxEth);
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
    require(!finalized);
    require(!saleSuspended);
    require(msg.value >= minContribution);

    //Prevent the wallet collecting ETH to directly be used to purchase tokens.
    require(msg.sender != address(wallet));
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
    token.safeTransfer(_beneficiary, _tokenAmount);
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
    balanceEth[_beneficiary] = balanceEth[_beneficiary].add(_weiAmount);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    public view returns (uint256)
  {
    return _weiAmount.mul(tokensPerEther).mul(bonusStages[currentStage].add(10000)).div(tokenConversionFactor);

  }

  function tokensToEth(uint256 _tokens, uint256 _currentStage) public view returns(uint256){
    return _tokens.div(tokensPerEther).div(bonusStages[_currentStage].add(10000)).mul(tokenConversionFactor);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 maxEth) internal {
    wallet.transfer(maxEth);
  }

  //Return the number of ETH the user has contributed.
  //***** to change public to internal once done with testing.
  function balanceEthOf(address _beneficiary) public view returns (uint256){
    return balanceEth[_beneficiary];
  }

  function GetCurrentBonusStageTokenBalance() public view returns (uint256){
    return bonusStagesTokenBalance[currentStage];
  }
}

// File: contracts\all\CappedCrowdsale.sol

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

// File: contracts\all\TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  event UpdatedOpeningTime(uint256 _newOpeningTime);
  event UpdatedClosingTime(uint256 _newClosingTime);
  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  function currentTime() public constant returns (uint256){
    return now;
  }

  function updateOpeningTime(uint256 _newOpeningTime) public returns (bool) {
    require(now < openingTime);
    require(now < _newOpeningTime);

    openingTime = _newOpeningTime;

    emit UpdatedOpeningTime(_newOpeningTime);

    return true;
  }

  function updateClosingTime(uint256 _newClosingTime) public returns (bool) {
    require(now < openingTime);
    require(openingTime < _newClosingTime);

    closingTime = _newClosingTime;

    emit UpdatedClosingTime(_newClosingTime);

    return true;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: contracts\tokensale.sol

contract TokenSale is Crowdsale, TimedCrowdsale, CappedCrowdsale{

    constructor
    (
        uint256 _rate,
        address _wallet,
        FinalizableToken _token,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _cap
    ) 
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
        CappedCrowdsale(_cap)
        public
    {

    }
}