pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a5c1c4d3c0e5c4cecac8c7c48bc6cac8">[email&#160;protected]</a>
// released under Apache 2.0 licence
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c)
  {
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
  function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c)
  {
    c = a + b;
    assert(c >= a);
    return c;
  }

}
contract ERC20 {

  function totalSupply() public view returns (uint256);

  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  function allowance(address owner, address spender) public view returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

}
contract Owned {

  event OwnershipTransferred(address indexed _from, address indexed _to);

  address public owner;
  address public newOwner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor()
    public
  {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner)
    public
    onlyOwner
  {
    newOwner = _newOwner;
  }

  function acceptOwnership()
    public
  {
    require(msg.sender == newOwner);
    owner = newOwner;
    newOwner = address(0);
    emit OwnershipTransferred(owner, newOwner);
  }

}
contract StandardToken is ERC20 {

  using SafeMath for uint256;

  uint256 totalSupply_;

  mapping(address => uint256) balances;

  mapping(address => mapping(address => uint256)) internal allowed;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply()
    public
    view
    returns (uint256)
  {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value)
    public
    returns (bool)
  {
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
  function balanceOf(address _owner)
    public
    view
    returns (uint256)
  {
    return balances[_owner];
  }




  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value)
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
  function approve(address _spender, uint256 _value)
    public
    returns (bool)
  {
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
  function allowance(address _owner, address _spender)
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
  function increaseApproval(address _spender, uint256 _addedValue)
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
  function decreaseApproval(address _spender, uint256 _subtractedValue)
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
library SafeERC20 {
  function safeTransfer(ERC20 token, address to, uint256 value) internal {
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

contract PetCoin is StandardToken, Owned {

  using SafeMath for uint256;

  // Token metadata
  string public constant name = "Petcoin";
  string public constant symbol = "PETC";
  uint256 public constant decimals = 18;

  // Token supply breakdown
  uint256 public constant initialSupply = 2340 * (10**6) * 10**decimals; // 2.34 billion
  uint256 public constant stageOneSupply = (10**5) * 10**decimals; // 100,000 tokens for ICO stage 1
  uint256 public constant stageTwoSupply = (10**6) * 10**decimals; // 1,000,000 tokens for ICO stage 2
  uint256 public constant stageThreeSupply = (10**7) * 10**decimals; // 10,000,000 tokens for ICO stage 3

  // Initial Token holder addresses.
  // one billion token holders
  address public constant appWallet = 0x9F6899364610B96D7718Fe3c03A6BD1Deb8623CE;
  address public constant genWallet = 0x530E6B9A17e9AbB77CF4E125b99Bf5D5CAD69942;
  // one hundred million token holders
  address public constant ceoWallet = 0x388Ed3f7Aa1C4461460197FcCE5cfEf84D562c6A;
  address public constant cooWallet = 0xa2c59e6a91B4E502CF8C95A61F50D3aB1AB30cBA;
  address public constant devWallet = 0x7D2ea29E2d4A95f4725f52B941c518C15eAE3c64;
  // the rest token holder
  address public constant poolWallet = 0x7e75fe6b73993D9Be9cb975364ec70Ee2C22c13A;

  // mint configuration
  uint256 public constant yearlyMintCap = (10*7) * 10*decimals; //10,000,000 tokens each year
  uint16 public mintStartYear = 2019;
  uint16 public mintEndYear = 2118;

  mapping (uint16 => bool) minted;


  constructor()
    public
  {
    totalSupply_ = initialSupply.add(stageOneSupply).add(stageTwoSupply).add(stageThreeSupply);
    uint256 oneBillion = (10**9) * 10**decimals;
    uint256 oneHundredMillion = 100 * (10**6) * 10**decimals;
    balances[appWallet] = oneBillion;
    emit Transfer(address(0), appWallet, oneBillion);
    balances[genWallet] = oneBillion;
    emit Transfer(address(0), genWallet, oneBillion);
    balances[ceoWallet] = oneHundredMillion;
    emit Transfer(address(0), ceoWallet, oneHundredMillion);
    balances[cooWallet] = oneHundredMillion;
    emit Transfer(address(0), cooWallet, oneHundredMillion);
    balances[devWallet] = oneHundredMillion;
    emit Transfer(address(0), devWallet, oneHundredMillion);
    balances[poolWallet] = initialSupply.sub(balances[appWallet])
    .sub(balances[genWallet])
    .sub(balances[ceoWallet])
    .sub(balances[cooWallet])
    .sub(balances[devWallet]);
    emit Transfer(address(0), poolWallet, balances[poolWallet]);
    balances[msg.sender] = stageOneSupply.add(stageTwoSupply).add(stageThreeSupply);
    emit Transfer(address(0), msg.sender, balances[msg.sender]);
  }

  event Mint(address indexed to, uint256 amount);

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to
  )
    onlyOwner
    external
    returns (bool)
  {
    uint16 year = _getYear(now);
    require (year >= mintStartYear && year <= mintEndYear && !minted[year]);
    require (_to != address(0));

    totalSupply_ = totalSupply_.add(yearlyMintCap);
    balances[_to] = balances[_to].add(yearlyMintCap);
    minted[year] = true;

    emit Mint(_to, yearlyMintCap);
    emit Transfer(address(0), _to, yearlyMintCap);
    return true;
  }

  function _getYear(uint256 timestamp)
    internal
    pure
    returns (uint16)
  {
    uint16 ORIGIN_YEAR = 1970;
    uint256 YEAR_IN_SECONDS = 31536000;
    uint256 LEAP_YEAR_IN_SECONDS = 31622400;

    uint secondsAccountedFor = 0;
    uint16 year;
    uint numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = _leapYearsBefore(year) - _leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) {
      if (_isLeapYear(uint16(year - 1))) {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      }
      else {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  }

  function _isLeapYear(uint16 year)
    internal
    pure
    returns (bool)
  {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    if (year % 400 != 0) {
      return false;
    }
    return true;
  }

  function _leapYearsBefore(uint year)
    internal
    pure
    returns (uint)
  {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

}
contract PetCoinCrowdSale is Owned {
  using SafeMath for uint256;
  using SafeERC20 for PetCoin;

  // Conversion rates
  uint256 public stageOneRate = 4500; // 1 ETH = 4500 PETC
  uint256 public stageTwoRate = 3000; // 1 ETH = 3000 PETC
  uint256 public stageThreeRate = 2557; // 1 ETH = 2557 PETC

  // The token being sold
  PetCoin public token;

  // Address where funds are collected
  address public wallet;

  // Amount of wei raised
  uint256 public weiRaised;


  // Token Sale State Definitions
  enum TokenSaleState { NOT_STARTED, STAGE_ONE, STAGE_TWO, STAGE_THREE, COMPLETED }

  TokenSaleState public state;

  struct Stage {
    uint256 rate;
    uint256 remaining;
  }

  // Enum as mapping key not supported by Solidity yet
  mapping(uint256 => Stage) public stages;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    uint256 value,
    uint256 amount
  );


  /**
   * Event for refund in case remaining tokens are not sufficient
   * @param purchaser who paid for the tokens
   * @param value weis refunded
   */
  event Refund(
    address indexed purchaser,
    uint256 value
  );

  /**
   * Event for move stage
   * @param oldState old state
   * @param newState new state
   */
  event MoveStage(
    TokenSaleState oldState,
    TokenSaleState newState
  );

  /**
 * Event for rates update
 * @param who updated the rates
 * @param stageOneRate new stageOneRate
 * @param stageTwoRate new stageTwoRate
 * @param stageThreeRate new stageThreeRate
 */
  event RatesUpdate(
    address indexed who,
    uint256 stageOneRate,
    uint256 stageTwoRate,
    uint256 stageThreeRate
  );

  /**
   * @param _token Address of the token being sold
   * @param _wallet Address where collected funds will be forwarded to
   */
  constructor(PetCoin _token, address _wallet)
    public
  {
    require(_token != address(0));
    require(_wallet != address(0));

    token = _token;
    wallet = _wallet;

    state = TokenSaleState.NOT_STARTED;
    stages[uint256(TokenSaleState.STAGE_ONE)] = Stage(stageOneRate, token.stageOneSupply());
    stages[uint256(TokenSaleState.STAGE_TWO)] = Stage(stageTwoRate, token.stageTwoSupply());
    stages[uint256(TokenSaleState.STAGE_THREE)] = Stage(stageThreeRate, token.stageThreeSupply());
  }


  // Modifiers
  modifier notStarted() {
    require (state == TokenSaleState.NOT_STARTED);
    _;
  }

  modifier stageOne() {
    require (state == TokenSaleState.STAGE_ONE);
    _;
  }

  modifier stageTwo() {
    require (state == TokenSaleState.STAGE_TWO);
    _;
  }

  modifier stageThree() {
    require (state == TokenSaleState.STAGE_THREE);
    _;
  }

  modifier completed() {
    require (state == TokenSaleState.COMPLETED);
    _;
  }

  modifier saleInProgress() {
    require (state == TokenSaleState.STAGE_ONE || state == TokenSaleState.STAGE_TWO || state == TokenSaleState.STAGE_THREE);
    _;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  function kickoff()
    external
    onlyOwner
    notStarted
  {
    _moveStage();
  }


  function updateRates(uint256 _stageOneRate, uint256 _stageTwoRate, uint256 _stageThreeRate)
    external
    onlyOwner
  {
    stageOneRate = _stageOneRate;
    stageTwoRate = _stageTwoRate;
    stageThreeRate = _stageThreeRate;
    stages[uint256(TokenSaleState.STAGE_ONE)].rate = stageOneRate;
    stages[uint256(TokenSaleState.STAGE_TWO)].rate = stageTwoRate;
    stages[uint256(TokenSaleState.STAGE_THREE)].rate = stageThreeRate;
    emit RatesUpdate(msg.sender, stageOneRate, stageTwoRate, stageThreeRate);
  }

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function ()
    external
    payable
    saleInProgress
  {
    require(stages[uint256(state)].rate > 0);
    require(stages[uint256(state)].remaining > 0);
    require(msg.value > 0);

    uint256 weiAmount = msg.value;
    uint256 refund = 0;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(stages[uint256(state)].rate);

    if (tokens > stages[uint256(state)].remaining) {
      // calculate wei needed to purchase the remaining tokens
      tokens = stages[uint256(state)].remaining;
      weiAmount = tokens.div(stages[uint256(state)].rate);
      refund = msg.value - weiAmount;
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);

    emit TokenPurchase(
      msg.sender,
      weiAmount,
      tokens
    );

    // update remaining of the stage
    stages[uint256(state)].remaining -= tokens;
    assert(stages[uint256(state)].remaining >= 0);

    if (stages[uint256(state)].remaining == 0) {
      _moveStage();
    }

    // transfer tokens to buyer
    token.safeTransfer(msg.sender, tokens);

    // forward ETH to the wallet
    _forwardFunds(weiAmount);

    if (refund > 0) { // refund the purchaser if required
      msg.sender.transfer(refund);
      emit Refund(
        msg.sender,
        refund
      );
    }
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  function _moveStage()
    internal
  {
    TokenSaleState oldState = state;
    if (state == TokenSaleState.NOT_STARTED) {
      state = TokenSaleState.STAGE_ONE;
    } else if (state == TokenSaleState.STAGE_ONE) {
      state = TokenSaleState.STAGE_TWO;
    } else if (state == TokenSaleState.STAGE_TWO) {
      state = TokenSaleState.STAGE_THREE;
    } else if (state == TokenSaleState.STAGE_THREE) {
      state = TokenSaleState.COMPLETED;
    }
    emit MoveStage(oldState, state);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 weiAmount) internal {
    wallet.transfer(weiAmount);
  }
}