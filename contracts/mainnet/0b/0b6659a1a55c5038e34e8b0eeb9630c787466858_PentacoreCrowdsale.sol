pragma solidity ^0.4.21;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
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

}

// File: contracts/PentacoreToken.sol

/**
 * @title Smart Contract which defines the token managed by the Pentacore Hedge Fund.
 * @author Jordan Stojanovski
 */
contract PentacoreToken is StandardToken {
  using SafeMath for uint256;

  string public name = &#39;PentacoreToken&#39;;
  string public symbol = &#39;PENT&#39;;
  uint256 public constant million = 1000000;
  uint256 public constant tokenCap = 1000 * million; // one billion tokens
  bool public isPaused = true;

  // Unlike the common practice to put the whitelist checks in the crowdsale,
  // the PentacoreToken does these tests itself.  This is mandated by legal
  // issues, as follows:
  // - The exchange can be anywhere and it should not be concerned with
  //   Pentacore&#39;s whitelisting methods.  If the exchange desires, it can
  //   perform its own KYC.
  // - Even after the Crowdsale / ICO if a whitelisted owner tries to sell
  //   their tokens to a non-whitelisted buyer (address), the seller shall be
  //   directed to the KYC process to be whitelisted before the sale can proceed.
  //   This prevents against selling tokens to buyers under embargo.
  // - If the seller is removed from the whitelist prior to the sale attempt,
  //   the corresponding sale should be reported to the authorities instead of
  //   allowing the seller to proceed.  This is subject of further discussion.
  mapping(address => bool) public whitelist;

  // If set to true, allow transfers between any addresses regardless of whitelist.
  // However, sale and/or redemption would still be not allowed regardless of this flag.
  // In the future, if it is determined that it is legal to transfer but not sell and/or redeem,
  // we could turn this flag on.
  bool public isFreeTransferAllowed = false;

  uint256 public tokenNAVMicroUSD; // Net Asset Value per token in MicroUSD (millionths of 1 US$)
  uint256 public weiPerUSD; // How many Wei is one US$

  // Who&#39;s Who
  address public owner; // The owner of this contract.
  address public kycAdmin; // The address of the caller which can update the KYC status of an address.
  address public navAdmin; // The address of the caller which can update the NAV/USD and ETH/USD values.
  address public crowdsale; //The address of the crowdsale contract.
  address public redemption; // The address of the redemption contract.
  address public distributedAutonomousExchange; // The address of the exchange contract.

  event Mint(address indexed to, uint256 amount);
  event Burn(uint256 amount);
  event AddToWhitelist(address indexed beneficiary);
  event RemoveFromWhitelist(address indexed beneficiary);

  function PentacoreToken() public {
    owner = msg.sender;
    tokenNAVMicroUSD = million; // Initially 1 PENT = 1 US$ (a million millionths)
    isFreeTransferAllowed = false;
    isPaused = true;
    totalSupply_ = 0; // No tokens exist at creation.  They are minted as sold.
  }

  /**
   * @dev Throws if called by any account other than the authorized one.
   * @param authorized the address of the authorized caller.
   */
  modifier onlyBy(address authorized) {
    require(authorized != address(0));
    require(msg.sender == authorized);
    _;
  }

  /**
   * @dev Pauses / unpauses the transferability of the token.
   * @param _pause pause if true; unpause if false
   */
  function setPaused(bool _pause) public {
    require(owner != address(0));
    require(msg.sender == owner);

    isPaused = _pause;
  }

  modifier notPaused() {
    require(!isPaused);
    _;
  }

  /**
   * @dev Sets the address of the owner.
   * @param _address The address of the new owner of the Token Contract.
   */
  function transferOwnership(address _address) external onlyBy(owner) {
    require(_address != address(0)); // Prevent rendering it unusable
    owner = _address;
  }

  /**
   * @dev Sets the address of the PentacoreCrowdsale contract.
   * @param _address PentacoreCrowdsale contract address.
   */
  function setKYCAdmin(address _address) external onlyBy(owner) {
    kycAdmin = _address;
  }

  /**
   * @dev Sets the address of the PentacoreCrowdsale contract.
   * @param _address PentacoreCrowdsale contract address.
   */
  function setNAVAdmin(address _address) external onlyBy(owner) {
    navAdmin = _address;
  }

  /**
   * @dev Sets the address of the PentacoreCrowdsale contract.
   * @param _address PentacoreCrowdsale contract address.
   */
  function setCrowdsaleContract(address _address) external onlyBy(owner) {
    crowdsale = _address;
  }

  /**
   * @dev Sets the address of the PentacoreRedemption contract.
   * @param _address PentacoreRedemption contract address.
   */
  function setRedemptionContract(address _address) external onlyBy(owner) {
    redemption = _address;
  }

  /**
    * @dev Sets the address of the DistributedAutonomousExchange contract.
    * @param _address DistributedAutonomousExchange contract address.
    */
  function setDistributedAutonomousExchange(address _address) external onlyBy(owner) {
    distributedAutonomousExchange = _address;
  }

  /**
   * @dev Sets the token price in US$.  Set by owner to reflect NAV/token.
   * @param _price PentacoreToken price in USD.
   */
  function setTokenNAVMicroUSD(uint256 _price) external onlyBy(navAdmin) {
    tokenNAVMicroUSD = _price;
  }

  /**
   * @dev Sets the token price in US$.  Set by owner to reflect NAV/token.
   * @param _price PentacoreToken price in USD.
   */
  function setWeiPerUSD(uint256 _price) external onlyBy(navAdmin) {
    weiPerUSD = _price;
  }

  /**
   * @dev Calculate the amount of Wei for a given token amount.  The result is rounded down (floored) to a millionth of a US$)
   * @param _tokenAmount Whole number of tokens to be converted to Wei
   * @return amount of Wei for the given amount of tokens
   */
  function tokensToWei(uint256 _tokenAmount) public view returns (uint256) {
    require(tokenNAVMicroUSD != uint256(0));
    require(weiPerUSD != uint256(0));
    return _tokenAmount.mul(tokenNAVMicroUSD).mul(weiPerUSD).div(million);
  }

  /**
   * @dev Calculate the amount tokens for a given Wei amount and the amount of change in Wei.
   * @param _weiAmount Whole number of Wei to be converted to tokens
   * @return whole amount of tokens for the given amount in Wei
   * @return change in Wei that is not sufficient to buy a whole token
   */
  function weiToTokens(uint256 _weiAmount) public view returns (uint256, uint256) {
    require(tokenNAVMicroUSD != uint256(0));
    require(weiPerUSD != uint256(0));
    uint256 tokens = _weiAmount.mul(million).div(weiPerUSD).div(tokenNAVMicroUSD);
    uint256 changeWei = _weiAmount.sub(tokensToWei(tokens));
    return (tokens, changeWei);
  }

  /**
   * @dev Allows / disallows free transferability of tokens regardless of whitelist.
   * @param _isFreeTransferAllowed disregard whitelist if true; not if false
   */
  function setFreeTransferAllowed(bool _isFreeTransferAllowed) public {
    require(owner != address(0));
    require(msg.sender == owner);

    isFreeTransferAllowed = _isFreeTransferAllowed;
  }

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   * @param _beneficiary the address which must be whitelisted by the KYC process in order to pass.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Reverts if beneficiary is not whitelisted and isFreeTransferAllowed is false. Can be used when extending this contract.
   * @param _beneficiary the address which must be whitelisted by the KYC process in order to pass unless isFreeTransferAllowed.
   */
  modifier isWhitelistedOrFreeTransferAllowed(address _beneficiary) {
    require(isFreeTransferAllowed || whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) public onlyBy(kycAdmin) {
    whitelist[_beneficiary] = true;
    emit AddToWhitelist(_beneficiary);
  }

  /**
   * @dev Adds list of addresses to whitelist.
   * @param _beneficiaries List of addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyBy(kycAdmin) {
    for (uint256 i = 0; i < _beneficiaries.length; i++) addToWhitelist(_beneficiaries[i]);
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) public onlyBy(kycAdmin) {
    whitelist[_beneficiary] = false;
    emit RemoveFromWhitelist(_beneficiary);
  }

  /**
   * @dev Removes list of addresses from whitelist.
   * @param _beneficiaries List of addresses to be removed to the whitelist
   */
  function removeManyFromWhitelist(address[] _beneficiaries) external onlyBy(kycAdmin) {
    for (uint256 i = 0; i < _beneficiaries.length; i++) removeFromWhitelist(_beneficiaries[i]);
  }

  /**
   * @dev Function to mint tokens. We mint as we sell tokens (actually the PentacoreCrowdsale contract does).
   * @dev The recipient should be whitelisted.
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) public onlyBy(crowdsale) isWhitelisted(_to) returns (bool) {
    // Should run even when the token is paused.
    require(tokenNAVMicroUSD != uint256(0));
    require(weiPerUSD != uint256(0));
    require(totalSupply_.add(_amount) <= tokenCap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to burn tokens. We burn as owners redeem tokens (actually the PentacoreRedemptions contract does).
   * @param _amount The amount of tokens to burn.
   * @return A boolean that indicates if the operation was successful.
   */
  function burn(uint256 _amount) public onlyBy(redemption) returns (bool) {
    // Should run even when the token is paused.
    require(balances[redemption].sub(_amount) >= uint256(0));
    require(totalSupply_.sub(_amount) >= uint256(0));
    balances[redemption] = balances[redemption].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);
    emit Burn(_amount);
    return true;
  }

  /**
   * @dev transfer token for a specified address
   * @dev Both the sender and the recipient should be whitelisted.
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public notPaused isWhitelistedOrFreeTransferAllowed(msg.sender) isWhitelistedOrFreeTransferAllowed(_to) returns (bool) {
    return super.transfer(_to, _value);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @dev The sender should be whitelisted.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public notPaused isWhitelistedOrFreeTransferAllowed(msg.sender) returns (bool) {
    return super.approve(_spender, _value);
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * @dev The sender should be whitelisted.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public notPaused isWhitelistedOrFreeTransferAllowed(msg.sender) returns (bool) {
    return super.increaseApproval(_spender, _addedValue);
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   *
   * @dev The sender does not need to be whitelisted.  This is in case they are removed from white list and no longer agree to sell at an exchange.
   * @dev This function stays untouched (directly inherited), but it&#39;s re-defined for clarity:
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @dev Both the sender and the recipient should be whitelisted.
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public notPaused isWhitelistedOrFreeTransferAllowed(_from) isWhitelistedOrFreeTransferAllowed(_to) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

// File: contracts/PentacoreCrowdsale.sol

/**
 * @title Allows payers to this contract to purchase Pentacore Tokens (PENT).
 * @author Jordan Stojanovski
 */
contract PentacoreCrowdsale {
  using SafeMath for uint256;

  uint256 public constant million = 1000000;
  uint256 public constant icoTokenCap = 50 * million;
  uint256 public constant minimumPurchase = 100; // amount of tokens
  uint public constant icoDuration = 4 weeks;
  uint256 public icoStart;
  bool public postICOSale = false;

  // The owner of this contracts
  address public owner;

  // The token being sold
  PentacoreToken public token;

  // Address where funds are collected
  address public wallet;

  // Amount of wei raised
  uint256 public weiRaised;

  //

  // Amount raised in various currencies via external sales expressed as currency => valueRaised
  mapping (bytes32 => uint256) public externalFundsRaised;

  /**
   * @dev Sets the address of the owner.
   * @param _address The address of the new owner of this contract.
   */
  function transferOwnership(address _address) external {
    require(msg.sender == owner);
    require(owner != address(0));
    require(_address != address(0)); // Prevent rendering it unusable

    owner = _address;
  }

  /**
   * @dev Sets the address of the wallet where crowdsale prceeds end up.
   * @param _newWallet The address of the new wallet.
   */
  function changeWallet(address _newWallet) external {
    require(msg.sender == owner);
    require(owner != address(0));
    require(_newWallet != address(0)); // Prevent rendering it unusable

    wallet = _newWallet;
  }

/**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  /**
   * Event for external token purchase logging
   * @param purchaser who paid for the tokens
   * @param currency currency in which payment was processed
   * @param value units in specified currency paid for purchase
   * @param amount amount of tokens purchased
   * @param txid the transaction ID of the external deposit.  Could be a Bitcoin Transaction Hash or Wire Transfer Reference Number.
   */
  event ExternalTokenPurchase(address indexed purchaser, string currency, uint256 value, uint256 amount, uint256 txid);

  /**
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function PentacoreCrowdsale(address _wallet, PentacoreToken _token) public {
    owner = msg.sender;
    require(_wallet != address(0));
    require(_token != address(0));

    wallet = _wallet;
    token = _token;
  }

  function startICO() external {
    require(owner != address(0));
    require(msg.sender == owner);
    require(token != address(0));
    require(icoStart == uint256(0));

    icoStart = now;
  }

  function isICOActive() public view returns(bool) {
    return icoStart != 0 && now <= icoStart.add(icoDuration);
  }

  function setPostICOSale(bool _postICOSale) public {
    postICOSale = _postICOSale;
  }

  // -----------------------------------------
  // PentacoreCrowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function
   */
  function () external payable {
    buyTokens();
  }

  /**
   * @dev Token Purchase
   */
  function buyTokens() public payable {
    require(msg.value != 0);
    require(msg.sender != 0);
    require(isICOActive() || postICOSale);
    require(token.whitelist(msg.sender));

    // calculate token amount to be created
    uint256 tokensPurchased;
    uint256 weiChange;
    (tokensPurchased, weiChange) = token.weiToTokens(msg.value);
    uint256 weiExactAmount = msg.value.sub(weiChange);

    require(tokensPurchased >= minimumPurchase);

    // Cannot exceed total allocated supply for the ICO
    // reverting allows a smaller purchase to pass in the future, up to the icoTokenCap
    if (isICOActive() && token.totalSupply().add(tokensPurchased) > icoTokenCap) revert();

    // Update total amount raised from purchases in Wei
    weiRaised = weiRaised.add(weiExactAmount);

    // Issue the tokens
    token.mint(msg.sender, tokensPurchased); // will revert if tokenCap is reached
    emit TokenPurchase(msg.sender, weiExactAmount, tokensPurchased);

    // Process the payment
    wallet.transfer(weiExactAmount);
    msg.sender.transfer(weiChange);
  }

  /**
   * @dev This is separated as a function because it can be called separately to avoid costs as it is view only
   * @param _currency currency symbol
   * @return the hash of the currency (no security needed - just so it can be mapped)
   */
   function currencyToHash(string _currency) public pure returns(bytes32) {
     return keccak256(_currency);
   }

   /**
    * @dev This is separated as a function because it can be called separately to avoid costs as it is view only
    * @param _currency currency symbol
    * @return the amount of funds externally raised in the given currency
    */
    function getExternalFundsRaised(string _currency) public view returns(uint256) {
      return externalFundsRaised[currencyToHash(_currency)];
    }

  /**
   * @dev Token Purchase outside of this contract, usually paid for by currencies other than ETH
   * @dev Only the owner of this contract can issue tokens in exchange for payments in other currencies
   * @param _beneficiary the address which receives the tokens
   * @param _currency currency symbol
   * @param _value amount paid in the given currency.  It must be in whole units, so currencies like MicroUSD (millionth of a US$) should be used
   * @param _txid the transaction ID of the external deposit.  Could be a Bitcoin Transaction Hash or Wire Transfer Reference Number.
   * @param _amount amount of tokens purchased
   */
  function externalPurchase(address _beneficiary, string _currency, uint256 _value, uint256 _amount, uint256 _txid) public {
    require(owner != address(0));
    require(msg.sender == owner); //  Only owner can issue tokens in exchange for external payment
    require(isICOActive() || postICOSale);
    require(token.whitelist(_beneficiary));

    require(_amount >= minimumPurchase);

    // Cannot exceed total allocated supply for the ICO
    // reverting allows a smaller purchase to pass in the future, up to the icoTokenCap
    if (isICOActive() && token.totalSupply().add(_amount) > icoTokenCap) revert();

    // Update total amount raised from purchases via external sales
    externalFundsRaised[currencyToHash(_currency)] = externalFundsRaised[currencyToHash(_currency)].add(_value);

    // Issue the tokens
    token.mint(_beneficiary, _amount); // will revert if tokenCap is reached
    emit ExternalTokenPurchase(_beneficiary, _currency, _value, _amount, _txid);
  }
}