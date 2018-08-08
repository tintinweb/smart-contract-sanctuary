pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

/**
 * @title TokenlessCrowdsale
 * @dev Crowdsale based on OpenZeppelin&#39;s Crowdsale but without token-related logic
 * @author U-Zyn Chua <<span class="__cf_email__" data-cfemail="17626d6e79576d6e7972647e643974787a">[email&#160;protected]</span>>
 *
 * Largely similar to OpenZeppelin except the following irrelevant token-related hooks removed:
 * - function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal
 * - function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal
 * - function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256)
 * - event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount)
 *
 * Added hooks:
 * - function _processPurchaseInWei(address _beneficiary, uint256 _weiAmount) internal
 * - event SaleContribution(address indexed purchaser, address indexed beneficiary, uint256 value)
 */
contract TokenlessCrowdsale {
  using SafeMath for uint256;

  // Address where funds are collected
  address public wallet;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * similar to TokenPurchase without the token amount
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   */
  event SaleContribution(address indexed purchaser, address indexed beneficiary, uint256 value);

  /**
   * @param _wallet Address where collected funds will be forwarded to
   */
  constructor (address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
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

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchaseInWei(_beneficiary, weiAmount);
    emit SaleContribution(
      msg.sender,
      _beneficiary,
      weiAmount
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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Number of wei contributed
   */
  function _processPurchaseInWei(address _beneficiary, uint256 _weiAmount) internal {
    // override with logic on tokens delivery
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
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


/**
 * @title WhitelistedAICrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute,
 * with a defined individual cap in wei,
 * and a bool flag on whether a user is an accredited investor (AI)
 * Based on OpenZeppelin&#39;s WhitelistedCrowdsale and IndividuallyCappedCrowdsale
 * @author U-Zyn Chua <<span class="__cf_email__" data-cfemail="20555a594e605a594e455349530e434f4d">[email&#160;protected]</span>>
 */
contract WhitelistedAICrowdsale is TokenlessCrowdsale, Ownable {
  using SafeMath for uint256;

  mapping(address => bool) public accredited;

  // Individual cap
  mapping(address => uint256) public contributions;
  mapping(address => uint256) public caps;

 /**
  * @dev Returns if a beneficiary is whitelisted
  * @return bool
  */
  function isWhitelisted(address _beneficiary) public view returns (bool) {
    if (caps[_beneficiary] != 0) {
      return true;
    }
    return false;
  }

  /**
   * @dev Adds single address to whitelist.
   * Use this also to update
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary, uint256 _cap, bool _accredited) external onlyOwner {
    caps[_beneficiary] = _cap;
    accredited[_beneficiary] = _accredited;
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    caps[_beneficiary] = 0;
    accredited[_beneficiary] = false;
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(contributions[_beneficiary].add(_weiAmount) <= caps[_beneficiary]);
  }

  /**
   * @dev Extend parent behavior to update user contributions
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }

}


/**
 * @title FiatCappedCrowdsale
 * @dev Crowdsale with a limit for total contributions defined in fiat (USD).
 * Based on OpenZeppelin&#39;s CappedCrowdsale
 * Handles fiat rates, but does not handle token awarding.
 * @author U-Zyn Chua <<span class="__cf_email__" data-cfemail="acd9d6d5c2ecd6d5c2c9dfc5df82cfc3c1">[email&#160;protected]</span>>
 */
contract FiatCappedCrowdsale is TokenlessCrowdsale, Ownable {
  using SafeMath for uint256;

  // 1 USD = 1000 mill (1 mill is USD 0.001)
  // 1 ETH = 1e18 wei
  // 1 SPX = 1e18 leconte

  uint256 public millCap; // cap defined in USD mill
  uint256 public millRaised; // amount of USD mill raised

  // Minimum fiat value purchase per transaction
  uint256 public minMillPurchase;

  // How many ETH wei per USD 0.001
  uint256 public millWeiRate;

  // How many SPX leconte per USD 0.001, without bonus
  uint256 public millLeconteRate;

  // Sanity checks
  // 1 ETH is between USD 100 and USD 5,000
  uint256 constant minMillWeiRate = (10 ** 18) / (5000 * (10 ** 3)); // USD 5,000
  uint256 constant maxMillWeiRate = (10 ** 18) / (100 * (10 ** 3)); // USD 100

  // 1 SPX is between USD 0.01 and USD 1
  uint256 constant minMillLeconteRate = (10 ** 18) / 1000; // USD 1
  uint256 constant maxMillLeconteRate = (10 ** 18) / 10; // USD 0.01

  /**
   * @dev Throws if mill rate for ETH wei is not sane
   */
  modifier isSaneETHRate(uint256 _millWeiRate) {
    require(_millWeiRate >= minMillWeiRate);
    require(_millWeiRate <= maxMillWeiRate);
    _;
  }

  /**
   * @dev Throws if mill rate for SPX wei is not sane
   */
  modifier isSaneSPXRate(uint256 _millLeconteRate) {
    require(_millLeconteRate >= minMillLeconteRate);
    require(_millLeconteRate <= maxMillLeconteRate);
    _;
  }

  /**
   * @dev Constructor
   * @param _millCap Max amount of mill to be contributed
   * @param _millLeconteRate How many SPX leconte per mill
   * @param _millWeiRate How many ETH wei per mill, this is updateable with setWeiRate()
   */
  constructor (
    uint256 _millCap,
    uint256 _minMillPurchase,
    uint256 _millLeconteRate,
    uint256 _millWeiRate
  ) public isSaneSPXRate(_millLeconteRate) isSaneETHRate(_millWeiRate) {
    require(_millCap > 0);
    require(_minMillPurchase > 0);

    millCap = _millCap;
    minMillPurchase = _minMillPurchase;
    millLeconteRate = _millLeconteRate;
    millWeiRate = _millWeiRate;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return millRaised >= millCap;
  }

  /**
   * @dev Sets the current ETH wei rate - How many ETH wei per mill
   */
  function setWeiRate(uint256 _millWeiRate) external onlyOwner isSaneETHRate(_millWeiRate) {
    millWeiRate = _millWeiRate;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap,
   * and that contribution should be >= minMillPurchase
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);

    // Check for minimum contribution
    uint256 _millAmount = _toMill(_weiAmount);
    require(_millAmount >= minMillPurchase);

    // Check for funding cap
    uint256 _millRaised = millRaised.add(_millAmount);
    require(_millRaised <= millCap);
    millRaised = _millRaised;
  }

  /**
   * @dev Returns the amount in USD mill given ETH wei
   * @param _weiAmount Amount in ETH wei
   * @return amount in mill
   */
  function _toMill(uint256 _weiAmount) internal returns (uint256) {
    return _weiAmount.div(millWeiRate);
  }

  /**
   * @dev Returns the amount in SPX leconte given ETH wei
   * @param _weiAmount Amount in ETH wei
   * @return amount in leconte
   */
  function _toLeconte(uint256 _weiAmount) internal returns (uint256) {
    return _toMill(_weiAmount).mul(millLeconteRate);
  }
}

/**
 * @title PausableCrowdsale
 * @dev Crowdsale allowing owner to halt sale process
 * Based on OpenZeppelin&#39;s TimedCrowdsale
 * @author U-Zyn Chua <<span class="__cf_email__" data-cfemail="aadfd0d3c4ead0d3c4cfd9c3d984c9c5c7">[email&#160;protected]</span>>
 */
contract PausableCrowdsale is TokenlessCrowdsale, Ownable {
  /**
   * Owner controllable switch to open or halt sale
   * This is independent from other checks such as cap, no other processes except owner should alter this value. This also means that even if hardCap is reached, this variable does not set to false on its own.
   * This variable is revocable, hence behaving more like a pause than close when turned to off.
   */
  bool public open = true;

  modifier saleIsOpen() {
    require(open);
    _;
  }

  function unpauseSale() external onlyOwner {
    require(!open);
    open = true;
  }

  function pauseSale() external onlyOwner saleIsOpen {
    open = false;
  }

  /**
   * @dev Extend parent behavior requiring sale to be opened
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal saleIsOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}

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

/**
 * @title ERC223 Token Receiver Interface
 * based on https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/Receiver_Interface.sol but much simplified
 */
contract BasicERC223Receiver {
  function tokenFallback(address _from, uint256 _value, bytes _data) public pure;
}


/**
 * @title RestrictedToken
 * @dev Standard Mintable ERC20 Token that can only be sent to an authorized address
 * Based on Consensys&#39; TokenFoundry&#39;s ControllableToken
 * @author U-Zyn Chua <<span class="__cf_email__" data-cfemail="087d727166487271666d7b617b266b6765">[email&#160;protected]</span>>
 */
contract RestrictedToken is BasicToken, Ownable {
  string public name;
  string public symbol;
  uint8 public decimals;

  // Authorized senders are able to transfer tokens freely, usu. Sale contract
  address public issuer;

  // Vesting period for exchanging of RestrictedToken to non-restricted token
  // This is for reference by exchange contract and no inherit use for this contract
  uint256 public vestingPeriod;

  // Holders of RestrictedToken are only able to transfer token to authorizedRecipients, usu. Exchange contract
  mapping(address => bool) public authorizedRecipients;

  // Whether recipients are ERC223-compliant
  mapping(address => bool) public erc223Recipients;

  // Last issued time of token per recipient
  mapping(address => uint256) public lastIssuedTime;

  event Issue(address indexed to, uint256 value);

  /**
   * @dev Throws if called by any account other than the issuer.
   */
  modifier onlyIssuer() {
    require(msg.sender == issuer);
    _;
  }

  /**
   * @dev Modifier to check if a transfer is allowed
   */
  modifier isAuthorizedRecipient(address _recipient) {
    require(authorizedRecipients[_recipient]);
    _;
  }

  constructor (
    uint256 _supply,
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 _vestingPeriod,
    address _owner, // usu. human
    address _issuer // usu. sale contract
  ) public {
    require(_supply != 0);
    require(_owner != address(0));
    require(_issuer != address(0));

    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    vestingPeriod = _vestingPeriod;
    owner = _owner;
    issuer = _issuer;
    totalSupply_ = _supply;
    balances[_issuer] = _supply;
    emit Transfer(address(0), _issuer, _supply);
  }

  /**
   * @dev Allows owner to authorize or deauthorize recipients
   */
  function authorize(address _recipient, bool _isERC223) public onlyOwner {
    require(_recipient != address(0));
    authorizedRecipients[_recipient] = true;
    erc223Recipients[_recipient] = _isERC223;
  }

  function deauthorize(address _recipient) public onlyOwner isAuthorizedRecipient(_recipient) {
    authorizedRecipients[_recipient] = false;
    erc223Recipients[_recipient] = false;
  }

  /**
   * @dev Only allow transfer to authorized recipients
   */
  function transfer(address _to, uint256 _value) public isAuthorizedRecipient(_to) returns (bool) {
    if (erc223Recipients[_to]) {
      BasicERC223Receiver receiver = BasicERC223Receiver(_to);
      bytes memory empty;
      receiver.tokenFallback(msg.sender, _value, empty);
    }
    return super.transfer(_to, _value);
  }

  /**
   * Issue token
   * @dev also records the token issued time
   */
  function issue(address _to, uint256 _value) public onlyIssuer returns (bool) {
    lastIssuedTime[_to] = block.timestamp;

    emit Issue(_to, _value);
    return super.transfer(_to, _value);
  }
}

/**
 * @title Sparrow Token private sale
 */
contract PrivateSale is TokenlessCrowdsale, WhitelistedAICrowdsale, FiatCappedCrowdsale, PausableCrowdsale {
  using SafeMath for uint256;

  // The 2 tokens being sold
  RestrictedToken public tokenR0; // SPX-R0 - restricted token with no vesting
  RestrictedToken public tokenR6; // SPX-R6 - restricted token with 6-month vesting

  uint8 constant bonusPct = 30;

  constructor (address _wallet, uint256 _millWeiRate) TokenlessCrowdsale(_wallet)
    FiatCappedCrowdsale(
      5000000 * (10 ** 3), // millCap: USD 5 million
      10000 * (10 ** 3), // minMillPurchase: USD 10,000
      (10 ** 18) / 50, // millLeconteRate: 1 SPX = USD 0.05
      _millWeiRate
    )
  public {
    tokenR0 = new RestrictedToken(
      2 * 100000000 * (10 ** 18), // supply: 100 million (* 2 for edge safety)
      &#39;Sparrow Token (Restricted)&#39;, // name
      &#39;SPX-R0&#39;, // symbol
      18, // decimals
      0, // no vesting
      msg.sender, // owner
      this // issuer
    );

    // SPX-R6: Only 30 mil needed if all contributors are AI, 130 mil needed if all contributors are non-AIs
    tokenR6 = new RestrictedToken(
      2 * 130000000 * (10 ** 18), // supply: 130 million (* 2 for edge safety)
      &#39;Sparrow Token (Restricted with 6-month vesting)&#39;, // name
      &#39;SPX-R6&#39;, // symbol
      18, // decimals
      6 * 30 * 86400, // vesting: 6 months
      msg.sender, // owner
      this // issuer
    );
  }

  // If accredited, non-bonus tokens are given as tokenR0, bonus tokens are given as tokenR6
  // If non-accredited, non-bonus and bonus tokens are given as tokenR6
  function _processPurchaseInWei(address _beneficiary, uint256 _weiAmount) internal {
    super._processPurchaseInWei(_beneficiary, _weiAmount);

    uint256 tokens = _toLeconte(_weiAmount);
    uint256 bonus = tokens.mul(bonusPct).div(100);

    // Accredited
    if (accredited[_beneficiary]) {
      tokenR0.issue(_beneficiary, tokens);
      tokenR6.issue(_beneficiary, bonus);
    } else {
      tokenR6.issue(_beneficiary, tokens.add(bonus));
    }
  }
}