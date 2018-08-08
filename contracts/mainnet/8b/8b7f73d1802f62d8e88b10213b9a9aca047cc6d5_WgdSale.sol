pragma solidity ^0.4.24;

/*
 * Part of Daonomic platform (daonomic.io)
 */

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
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
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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

/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

contract WgdToken is StandardBurnableToken {
  string public constant name = "webGold";
  string public constant symbol = "WGD";
  uint8 public constant decimals = 18;

  constructor(uint _total) public {
    balances[msg.sender] = _total;
    totalSupply_ = _total;
    emit Transfer(address(0), msg.sender, _total);
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
contract DaonomicCrowdsale {
  using SafeMath for uint256;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * @dev This event should be emitted when user buys something
   */
  event Purchase(address indexed buyer, address token, uint256 value, uint256 sold, uint256 bonus, bytes txId);
  /**
   * @dev Should be emitted if new payment method added
   */
  event RateAdd(address token);
  /**
   * @dev Should be emitted if payment method removed
   */
  event RateRemove(address token);

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
    (uint256 tokens, uint256 left) = _getTokenAmount(weiAmount);
    uint256 weiEarned = weiAmount.sub(left);
    uint256 bonus = _getBonus(tokens);
    uint256 withBonus = tokens.add(bonus);
    if (left > 0) {
      _beneficiary.send(left);
    }

    // update state
    weiRaised = weiRaised.add(weiEarned);

    _processPurchase(_beneficiary, withBonus);
    emit Purchase(
      _beneficiary,
      address(0),
        weiEarned,
      tokens,
      bonus,
      ""
    );

    _updatePurchasingState(_beneficiary, weiEarned, withBonus);
    _postValidatePurchase(_beneficiary, weiEarned);
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
  ) internal;

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
    uint256 _weiAmount,
    uint256 _tokens
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   *         and wei left (if no more tokens can be sold)
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256, uint256);

  function _getBonus(uint256 _tokens) internal view returns (uint256);
}

contract Whitelist {
  function isInWhitelist(address addr) view public returns (bool);
}

contract WhitelistDaonomicCrowdsale is Ownable, DaonomicCrowdsale {
  Whitelist[] public whitelists;

  constructor (Whitelist[] _whitelists) public {
    whitelists = _whitelists;
  }

  function setWhitelists(Whitelist[] _whitelists) onlyOwner public {
    whitelists = _whitelists;
  }

  function getWhitelists() view public returns (Whitelist[]) {
    return whitelists;
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(canBuy(_beneficiary), "investor is not verified by Whitelists");
  }

  function canBuy(address _beneficiary) constant public returns (bool) {
    for (uint i = 0; i < whitelists.length; i++) {
      if (whitelists[i].isInWhitelist(_beneficiary)) {
        return true;
      }
    }
    return false;
  }
}

contract RefundableDaonomicCrowdsale is DaonomicCrowdsale {
  event Refund(address _address, uint256 investment);
  mapping(address => uint256) investments;

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);
    investments[_beneficiary] = investments[_beneficiary].add(_weiAmount);
  }

  function claimRefund() public {
    require(isRefundable());
    require(investments[msg.sender] > 0);

    uint investment = investments[msg.sender];
    investments[msg.sender] = 0;

    msg.sender.send(investment);
    emit Refund(msg.sender, investment);
  }

  function isRefundable() view public returns (bool);
}

contract WgdSale is WhitelistDaonomicCrowdsale, RefundableDaonomicCrowdsale {
  using SafeERC20 for WgdToken;

  event Buyback(address indexed addr, uint256 tokens, uint256 value);

  WgdToken public token;

  uint256 public forSale;
  uint256 public sold;
  uint256 public minimalWei;
  uint256 public end;
  uint256[] public stages;
  uint256[] public rates;
  uint256[] public bonusStages;
  uint256[] public bonuses;

  constructor(WgdToken _token, uint256 _end, uint256 _minimalWei, uint256[] _stages, uint256[] _rates, uint256[] _bonusStages, uint256[] _bonuses, Whitelist[] _whitelists)
  WhitelistDaonomicCrowdsale(_whitelists) public {
    require(_stages.length == _rates.length);
    require(_bonusStages.length == _bonuses.length);

    token = _token;
    end = _end;
    minimalWei = _minimalWei;
    stages = _stages;
    rates = _rates;
    bonusStages = _bonusStages;
    bonuses = _bonuses;
    forSale = stages[stages.length - 1];

    emit RateAdd(address(0));
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(_weiAmount >= minimalWei);
  }

  /**
   * @dev function for Daonomic UI
   */
  function getRate(address _token) view public returns (uint256) {
    if (_token == address(0)) {
      uint8 stage = getStage(sold);
      if (stage == stages.length) {
        return 0;
      }
      return rates[stage] * 10 ** 18;
    } else {
      return 0;
    }
  }

  /**
   * @dev Executes buyback
   * @dev burns all allowed tokens and returns back Eth
   * @dev call token.approve before calling this function
   */
  function buyback() public {
    require(getStage(sold) > 0, "buyback doesn&#39;t work on stage 0");

    uint256 approved = token.allowance(msg.sender, this);
    uint256 inCirculation = token.totalSupply().sub(token.balanceOf(this));
    uint256 value = approved.mul(this.balance).div(inCirculation);

    token.burnFrom(msg.sender, approved);
    msg.sender.send(value);
    emit Buyback(msg.sender, approved, value);
  }

  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  ) internal {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  function _getBonus(uint256 _tokens) internal view returns (uint256) {
    return getRealAmountBonus(forSale, sold, _tokens);
  }

  function getRealAmountBonus(uint256 _forSale, uint256 _sold, uint256 _tokens) public view returns (uint256) {
    uint256 bonus = getAmountBonus(_tokens);
    uint256 left = _forSale.sub(_sold).sub(_tokens);
    if (left > bonus) {
      return bonus;
    } else {
      return left;
    }
  }

  function getAmountBonus(uint256 _tokens) public view returns (uint256) {
    uint256 currentBonus = 0;
    for (uint8 i = 0; i < bonuses.length; i++) {
      if (_tokens < bonusStages[i]) {
        return currentBonus;
      }
      currentBonus = bonuses[i];
    }
    return currentBonus;
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256, uint256) {
    return getTokenAmount(sold, _weiAmount);
  }

  function getTokenAmount(uint256 _sold, uint256 _weiAmount) public view returns (uint256 tokens, uint256 left) {
    left = _weiAmount;
    while (left > 0) {
      (uint256 currentTokens, uint256 currentLeft) = getTokensForStage(_sold.add(tokens), left);
      if (left == currentLeft) {
        return (tokens, left);
      }
      left = currentLeft;
      tokens = tokens.add(currentTokens);
    }
  }

  /**
   * @dev Calculates tokens for this stage
   * @return Number of tokens that can be purchased in this stage + wei left
   */
  function getTokensForStage(uint256 _sold, uint256 _weiAmount) public view returns (uint256 tokens, uint256 left) {
    uint8 stage = getStage(_sold);
    if (stage == stages.length) {
      return (0, _weiAmount);
    }
    if (stage == 0 && now > end) {
      revert("Sale is refundable, unable to buy");
    }
    uint256 rate = rates[stage];

    tokens = _weiAmount.mul(rate);
    left = 0;
    uint8 newStage = getStage(_sold.add(tokens));
    if (newStage != stage) {
      tokens = stages[stage].sub(_sold);
      uint256 weiSpent = (tokens.add(rate).sub(1)).div(rate);
      left = _weiAmount.sub(weiSpent);
    }
  }

  function getStage(uint256 _sold) public view returns (uint8) {
    for (uint8 i = 0; i < stages.length; i++) {
      if (_sold < stages[i]) {
        return i;
      }
    }
    return uint8(stages.length);
  }

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);

    sold = sold.add(_tokens);
  }

  function isRefundable() view public returns (bool) {
    return now > end && getStage(sold) == 0;
  }
}