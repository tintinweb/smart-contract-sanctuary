pragma solidity ^0.4.24;

//part of Daonomic platform: https://daonomic.io
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
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
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
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
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

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
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
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
    public
    hasMintPermission
    canMint
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
  function finishMinting() public onlyOwner canMint returns (bool) {
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
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

contract CCXToken is BurnableToken, PausableToken, MintableToken {
  string public constant name = "Crypto Circle Exchange Token";
  string public constant symbol = "CCX";
  uint8 public constant decimals = 18;
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

    // calculate token amount to be created
    (uint256 tokens, uint256 left) = _getTokenAmount(weiAmount);
    uint256 weiEarned = weiAmount.sub(left);
    uint256 bonus = _getBonus(tokens);
    uint256 withBonus = tokens.add(bonus);

    _preValidatePurchase(_beneficiary, weiAmount, tokens, bonus);

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

    if (left > 0) {
      _beneficiary.transfer(left);
    }
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
    uint256 _weiAmount,
    uint256 _tokens,
    uint256 _bonus
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(_tokens != 0);
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
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256 tokens, uint256 weiLeft);

  function _getBonus(uint256 _tokens) internal view returns (uint256);
}

contract Whitelist {
  function isInWhitelist(address addr) public view returns (bool);
}

contract WhitelistDaonomicCrowdsale is Ownable, DaonomicCrowdsale {
  Whitelist public whitelist;

  constructor (Whitelist _whitelist) public {
    whitelist = _whitelist;
  }

  function getWhitelists() view public returns (Whitelist[]) {
    Whitelist[] memory result = new Whitelist[](1);
    result[0] = whitelist;
    return result;
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens,
    uint256 _bonus
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount, _tokens, _bonus);
    require(canBuy(_beneficiary), "investor is not verified by Whitelist");
  }

  function canBuy(address _beneficiary) constant public returns (bool) {
    return whitelist.isInWhitelist(_beneficiary);
  }
}

contract RefundableDaonomicCrowdsale is DaonomicCrowdsale {
  event Refund(address _address, uint256 investment);
  mapping(address => uint256) public investments;

  function claimRefund() public {
    require(isRefundable());
    require(investments[msg.sender] > 0);

    uint investment = investments[msg.sender];
    investments[msg.sender] = 0;

    msg.sender.transfer(investment);
    emit Refund(msg.sender, investment);
  }

  function isRefundable() public view returns (bool);

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);
    investments[_beneficiary] = investments[_beneficiary].add(_weiAmount);
  }
}

contract CCXSale is WhitelistDaonomicCrowdsale, RefundableDaonomicCrowdsale {

  event UsdEthRateChange(uint256 rate);
  event Withdraw(address to, uint256 value);

  uint256 constant public SOFT_CAP = 50000000 * 10 ** 18;
  uint256 constant public HARD_CAP = 225000000 * 10 ** 18;
  uint256 constant public MINIMAL_CCX = 1000 * 10 ** 18;
  uint256 constant public START = 1539820800; // 18 oct 2018 00:00:00
  uint256 constant public END = 1549152000; // 3 feb 2019 00:00:00

  CCXToken public token;
  uint256 public sold;
  uint256 public rate;
  address public operator;

  constructor(CCXToken _token, Whitelist _whitelist, uint256 _usdEthRate, address _operator)
  WhitelistDaonomicCrowdsale(_whitelist) public {
    token = _token;
    operator = _operator;
    setUsdEthRate(_usdEthRate);
    //needed for Daonomic UI
    emit RateAdd(address(0));
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens,
    uint256 _bonus
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount, _tokens, _bonus);
    require(now >= START);
    require(now < END);
    require(_tokens.add(_bonus) > MINIMAL_CCX);
  }

  function setUsdEthRate(uint256 _usdEthRate) onlyOperatorOrOwner public {
    rate = _usdEthRate.mul(100).div(9);
    emit UsdEthRateChange(_usdEthRate);
  }

  modifier onlyOperatorOrOwner() {
    require(msg.sender == operator || msg.sender == owner);
    _;
  }

  function withdrawEth(address _to, uint256 _value) onlyOwner public {
    _to.transfer(_value);
    emit Withdraw(_to, _value);
  }

  function setOperator(address _operator) onlyOwner public {
    operator = _operator;
  }

  function pauseToken() onlyOwner public {
    token.pause();
  }

  function unpauseToken() onlyOwner public {
    token.unpause();
  }

  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  ) internal {
    token.mint(_beneficiary, _tokenAmount);
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256 tokens, uint256 weiLeft) {
    tokens = _weiAmount.mul(rate);
    if (sold.add(tokens) > HARD_CAP) {
      tokens = HARD_CAP.sub(sold);
      //alternative to Math.ceil(tokens / rate)
      uint256 weiSpent = (tokens.add(rate).sub(1)).div(rate);
      weiLeft =_weiAmount.sub(weiSpent);
    } else {
      weiLeft = 0;
    }
  }

  function _getBonus(uint256 _tokens) internal view returns (uint256) {
    uint256 possibleBonus = getTimeBonus(_tokens) + getAmountBonus(_tokens);
    if (sold.add(_tokens).add(possibleBonus) > HARD_CAP) {
      return HARD_CAP.sub(sold).sub(_tokens);
    } else {
      return possibleBonus;
    }
  }

  function getTimeBonus(uint256 _tokens) public view returns (uint256) {
    if (now < 1542931200) { //23 nov 2018 00:00:00
      return _tokens.mul(15).div(100);
    } else if (now < 1546041600) { // 29 dec 2018 00:00:00
      return _tokens.mul(7).div(100);
    } else {
      return 0;
    }
  }

  function getAmountBonus(uint256 _tokens) public pure returns (uint256) {
    if (_tokens < 10000 * 10 ** 18) {
      return 0;
    } else if (_tokens < 100000 * 10 ** 18) {
      return _tokens.mul(3).div(100);
    } else if (_tokens < 1000000 * 10 ** 18) {
      return _tokens.mul(5).div(100);
    } else if (_tokens < 10000000 * 10 ** 18) {
      return _tokens.mul(7).div(100);
    } else {
      return _tokens.mul(10).div(100);
    }
  }

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);

    sold = sold.add(_tokens);
  }

  function isRefundable() public view returns (bool) {
    return now > END && sold < SOFT_CAP;
  }

  /**
   * @dev function for Daonomic UI
   */
  function getRate(address _token) public view returns (uint256) {
    if (_token == address(0)) {
      return rate * 10 ** 18;
    } else {
      return 0;
    }
  }

  /**
   * @dev function for Daonomic UI
   */
  function start() public pure returns (uint256) {
    return START;
  }

  /**
   * @dev function for Daonomic UI
   */
  function end() public pure returns (uint256) {
    return END;
  }

}