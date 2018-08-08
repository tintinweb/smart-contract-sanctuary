pragma solidity ^0.4.23;

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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
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
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

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
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
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
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

/**
 * @title MultiOwnable
 */
contract MultiOwnable {
  address public root;
  mapping (address => address) public owners; // owner => parent of owner
  
  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    root = msg.sender;
    owners[root] = root;
  }
  
  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(owners[msg.sender] != 0);
    _;
  }
  
  /**
  * @dev Adding new owners
  */
  function newOwner(address _owner) onlyOwner external returns (bool) {
    require(_owner != 0);
    owners[_owner] = msg.sender;
    return true;
  }
  
  /**
    * @dev Deleting owners
    */
  function deleteOwner(address _owner) onlyOwner external returns (bool) {
    require(owners[_owner] == msg.sender || (owners[_owner] != 0 && msg.sender == root));
    owners[_owner] = 0;
    return true;
  }
}

/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistedCrowdsale is Crowdsale, MultiOwnable {

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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

/**
 * @title IndividuallyCappedCrowdsale
 * @dev Crowdsale with per-user caps.
 */
contract IndividuallyCappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public contributions;
  uint256 public individualCap;

  constructor(uint256 _individualCap) public {
    individualCap = _individualCap;
  }

  /**
   * @dev Returns the cap per a user.
   * @return Current cap for individual user
   */
  function getUserCap() public view returns (uint256) {
    return individualCap;
  }

  /**
   * @dev Returns the amount contributed so far by a sepecific user.
   * @param _beneficiary Address of contributor
   * @return User contribution so far
   */
  function getUserContribution(address _beneficiary) public view returns (uint256) {
    return contributions[_beneficiary];
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the user&#39;s funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(contributions[_beneficiary].add(_weiAmount) <= individualCap);
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, MultiOwnable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
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

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract Blacklisted is MultiOwnable {

  mapping(address => bool) public blacklist;

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier notBlacklisted() {
    require(blacklist[msg.sender] == false);
    _;
  }

  /**
   * @dev Adds single address to blacklist.
   * @param _villain Address to be added to the blacklist
   */
  function addToBlacklist(address _villain) external onlyOwner {
    blacklist[_villain] = true;
  }

  /**
   * @dev Adds list of addresses to blacklist. Not overloaded due to limitations with truffle testing.
   * @param _villains Addresses to be added to the blacklist
   */
  function addManyToBlacklist(address[] _villains) external onlyOwner {
    for (uint256 i = 0; i < _villains.length; i++) {
      blacklist[_villains[i]] = true;
    }
  }

  /**
   * @dev Removes single address from blacklist.
   * @param _villain Address to be removed to the blacklist
   */
  function removeFromBlacklist(address _villain) external onlyOwner {
    blacklist[_villain] = false;
  }
}


contract HUMToken is MintableToken, BurnableToken, Blacklisted {

  string public constant name = "HUMToken"; // solium-disable-line uppercase
  string public constant symbol = "HUM"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase, // 18 decimals is the strongly suggested default, avoid changing it

  uint256 public constant INITIAL_SUPPLY = 2500 * 1000 * 1000 * (10 ** uint256(decimals)); // 2,500,000,000 HUM

  bool public isUnlocked = false;
  
  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor(address _wallet) public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[_wallet] = INITIAL_SUPPLY;
    emit Transfer(address(0), _wallet, INITIAL_SUPPLY);
  }

  modifier onlyTransferable() {
    require(isUnlocked || owners[msg.sender] != 0);
    _;
  }

  function transferFrom(address _from, address _to, uint256 _value) public onlyTransferable notBlacklisted returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) public onlyTransferable notBlacklisted returns (bool) {
      return super.transfer(_to, _value);
  }
  
  function unlockTransfer() public onlyOwner {
      isUnlocked = true;
  }
  
  function lockTransfer() public onlyOwner {
      isUnlocked = false;
  }

}

contract HUMPresale is WhitelistedCrowdsale, IndividuallyCappedCrowdsale {
  
  uint256 public constant minimum = 100000000000000000; // 0.1 ether
  bool public isOnSale = false;

  mapping(address => uint256) public bonusTokens;
  uint256 public bonusPercent;
  address[] public contributors;

  event DistrubuteBonusTokens(address indexed sender);
  event Withdraw(address indexed _from, uint256 _amount);

  constructor (
    uint256 _rate,
    uint256 _bonusPercent,
    address _wallet,
    HUMToken _token,
    uint256 _individualCapEther
  ) 
    public
    Crowdsale(_rate, _wallet, _token)
    IndividuallyCappedCrowdsale(_individualCapEther.mul(10 ** 18))
  { 
    bonusPercent = _bonusPercent;
  }

  function modifyTokenPrice(uint256 _rate) public onlyOwner {
    rate = _rate;
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    super._processPurchase(_beneficiary, _tokenAmount);

    if (bonusPercent > 0) {
      if (contributions[_beneficiary] == 0) {
        contributors.push(_beneficiary);
      }
      bonusTokens[_beneficiary] = bonusTokens[_beneficiary].add(_tokenAmount.mul(bonusPercent).div(1000));
    }
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);

    bool isOverMinimum = _weiAmount >= minimum;
  
    require(isOverMinimum && isOnSale);
  }

  function openSale() public onlyOwner {
    require(!isOnSale);

    isOnSale = true;
  }

  function closeSale() public onlyOwner {
    require(isOnSale);

    if (token.balanceOf(this) > 0) {
      withdrawToken();
    }

    isOnSale = false;
  }

  function withdrawToken() public onlyOwner {
    uint256 balanceOfThis = token.balanceOf(this);
    token.transfer(wallet, balanceOfThis);
    emit Withdraw(wallet, balanceOfThis);
  }

  function distributeBonusTokens() public onlyOwner {
    require(!isOnSale);

    for (uint i = 0; i < contributors.length; i++) {
      if (bonusTokens[contributors[i]] > 0) {
        token.transferFrom(wallet, contributors[i], bonusTokens[contributors[i]]);
        bonusTokens[contributors[i]] = 0;
      }
    }

    emit DistrubuteBonusTokens(msg.sender);
  }

  function getContributors() public view onlyOwner returns(address[]) {
    return contributors;
  }

  /// @dev get addresses who has bonus tokens
  /// @return Returns array of addresses.
  function getBonusList() public view onlyOwner returns(address[]) {
    address[] memory contributorsTmp = new address[](contributors.length);
    uint count = 0;
    uint i;

    for (i = 0; i < contributors.length; i++) {
      if (bonusTokens[contributors[i]] > 0) {
        contributorsTmp[count] = contributors[i];
        count += 1;
      }
    }
    
    address[] memory _bonusList = new address[](count);
    for (i = 0; i < count; i++) {
      _bonusList[i] = contributorsTmp[i];
    }

    return _bonusList;
  }

  /// @dev distribute bonus tokens to addresses who has bonus tokens
  /// @param _bonusList array of addresses who has bonus tokens.
  function distributeBonusTokensByList(address[] _bonusList) public onlyOwner {
    require(!isOnSale);

    for (uint i = 0; i < _bonusList.length; i++) {
      if (bonusTokens[_bonusList[i]] > 0) {
        token.transferFrom(wallet, _bonusList[i], bonusTokens[_bonusList[i]]);
        bonusTokens[_bonusList[i]] = 0;
      }
    }

    emit DistrubuteBonusTokens(msg.sender);
  }

}