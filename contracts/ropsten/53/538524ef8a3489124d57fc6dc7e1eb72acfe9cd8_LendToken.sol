pragma solidity ^0.4.13;

/*
*
*  /$$       /$$$$$$$$ /$$   /$$ /$$$$$$$  /$$   /$$  /$$$$$$   /$$$$$$  /$$$$$$ /$$   /$$
* | $$      | $$_____/| $$$ | $$| $$__  $$| $$  / $$ /$$__  $$ /$$__  $$|_  $$_/| $$$ | $$
* | $$      | $$      | $$$$| $$| $$  \ $$|  $$/ $$/| $$  \__/| $$  \ $$  | $$  | $$$$| $$
* | $$      | $$$$$   | $$ $$ $$| $$  | $$ \  $$$$/ | $$      | $$  | $$  | $$  | $$ $$ $$
* | $$      | $$__/   | $$  $$$$| $$  | $$  >$$  $$ | $$      | $$  | $$  | $$  | $$  $$$$
* | $$      | $$      | $$\  $$$| $$  | $$ /$$/\  $$| $$    $$| $$  | $$  | $$  | $$\  $$$
* | $$$$$$$$| $$$$$$$$| $$ \  $$| $$$$$$$/| $$  \ $$|  $$$$$$/|  $$$$$$/ /$$$$$$| $$ \  $$
* |________/|________/|__/  \__/|_______/ |__/  |__/ \______/  \______/ |______/|__/  \__/
*/


contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

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
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method: 
   *   super._preValidatePurchase(_beneficiary, _weiAmount);
   *   require(weiRaised.add(_weiAmount) <= cap);
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

contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    // Potentially dangerous assumption about the type of the token.
    require(MintableToken(address(token)).mint(_beneficiary, _tokenAmount));
  }
}

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

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

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

contract DailyLimitCrowdsale is TimedCrowdsale, Ownable {

    uint256 public dailyLimit; // all users
    uint256 public stageLimit; // all users
    uint256 public minDailyPerUser;
    uint256 public maxDailyPerUser;

    // today&#39;s index => who => value
    mapping(uint256 => mapping(address => uint256)) public userSpending;
    // all users
    mapping(uint256 => uint256) public totalSpending;

    uint256 public stageSpending;
    /**
     * @dev Constructor that sets the passed value as a dailyLimit.
     * @param _minDailyPerUser uint256 to represent the min cap / day / user.
     * @param _maxDailyPerUser uint256 to represent the max cap / day/ user.
     * @param _dailyLimit uint256 to represent the daily limit of all users.
     * @param _stageLimit uint256 to represent the stage limit of all users.
     */
    constructor(uint256 _minDailyPerUser, uint256 _maxDailyPerUser, uint256 _dailyLimit, uint256 _stageLimit)
    public {
        minDailyPerUser = _minDailyPerUser;
        maxDailyPerUser = _maxDailyPerUser;
        dailyLimit = _dailyLimit;
        stageLimit = _stageLimit;
        stageSpending = 0;
    }

    function setTime(uint256 _openingTime, uint256 _closingTime)
    onlyOwner
    public {
        require(_closingTime >= _openingTime);
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev sets the daily limit. Does not alter the amount already spent today.
     * @param _value uint256 to represent the new limit.
     */
    function _setDailyLimit(uint256 _value) internal {
        dailyLimit = _value;
    }

    function _setMinDailyPerUser(uint256 _value) internal {
        minDailyPerUser = _value;
    }

    function _setMaxDailyPerUser(uint256 _value) internal {
        maxDailyPerUser = _value;
    }

    function _setStageLimit(uint256 _value) internal {
        stageLimit = _value;
    }


    /**
     * @dev Checks to see if there is enough resource to spend today. If true, the resource may be expended.
     * @param _value uint256 representing the amount of resource to spend.
     * @return A boolean that is True if the resource was spent and false otherwise.
     */

    function underLimit(address who, uint256 _value) internal returns (bool) {
        require(stageLimit > 0);
        require(minDailyPerUser > 0);
        require(maxDailyPerUser > 0);
        require(_value >= minDailyPerUser);
        require(_value <= maxDailyPerUser);
        uint256 _key = today();
        require(userSpending[_key][who] + _value >= userSpending[_key][who] && userSpending[_key][who] + _value <= maxDailyPerUser);
        if (dailyLimit > 0) {
            require(totalSpending[_key] + _value >= totalSpending[_key] && totalSpending[_key] + _value <= dailyLimit);
        }
        require(stageSpending + _value >= stageSpending && stageSpending + _value <= stageLimit);
        totalSpending[_key] += _value;
        userSpending[_key][who] += _value;
        stageSpending += _value;
        return true;
    }

    /**
     * @dev Private function to determine today&#39;s index
     * @return uint256 of today&#39;s index.
     */
    function today() private view returns (uint256) {
        return now / 1 days;
    }

    modifier limitedDaily(address who, uint256 _value) {
        require(underLimit(who, _value));
        _;
    }
    // ===============================
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    limitedDaily(_beneficiary, _weiAmount)
    internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        require(LendToken(token).deliver(_beneficiary, _tokenAmount));
    }
}

contract LendContract is MintedCrowdsale, DailyLimitCrowdsale {

    // Fields:
    enum CrowdsaleStage {
        BT,         // Bounty
        PS,         // Pre sale
        TS_R1,      // Token sale round 1
        TS_R2,      // Token sale round 2
        TS_R3,      // Token sale round 3
        EX,         // Exchange
        P2P_EX      // P2P Exchange
    }

    CrowdsaleStage public stage = CrowdsaleStage.PS; // By default it&#39;s Presale
    // =============

    // Token Distribution
    // =============================
    uint256 public maxTokens = 120 * 1e6 * 1e18; // There will be total 120 million Tokens available for sale
    uint256 public tokensForReserve = 50 * 1e6 * 1e18; // 50 million for the eco system reserve
    uint256 public tokensForBounty = 1 * 1e6 * 1e18; // 1 million for token bounty will send from fund deposit address
    uint256 public totalTokensForTokenSale = 49 * 1e6 * 1e18; // 49 million Tokens will be sold in Crowdsale
    uint256 public totalTokensForSaleDuringPreSale = 20 * 1e6 * 1e18; // 20 million out of 6 million will be sold during PreSale
    // ==============================
    // Token Funding Rates
    // ==============================
    uint256 public constant PRESALE_RATE = 1070; // 1 ETH = 1070 xcoin
    uint256 public constant ROUND_1_TOKENSALE_RATE = 535; // 1 ETH = 535 xcoin
    uint256 public constant ROUND_2_TOKENSALE_RATE = 389; // 1 ETH = 389 xcoin
    uint256 public constant ROUND_3_TOKENSALE_RATE = 306; // 1 ETH = 306 xcoin

    // ==============================
    // Token Limit
    // ==============================

    uint256 public constant PRESALE_MIN_DAILY_PER_USER = 5 * 1e18; // 5 ETH / user / day
    uint256 public constant PRESALE_MAX_DAILY_PER_USER = 100 * 1e18; // 100 ETH / user / day

    uint256 public constant TOKENSALE_MIN_DAILY_PER_USER = 0.1 * 1e18; // 0.1 ETH / user / day
    uint256 public constant TOKENSALE_MAX_DAILY_PER_USER = 10 * 1e18; // 10 ETH / user / day


    uint256 public constant ROUND_1_TOKENSALE_LIMIT_PER_DAY = 1.5 * 1e6 * 1e18; //1.5M xcoin all users
    uint256 public constant ROUND_1_TOKENSALE_LIMIT = 15 * 1e6 * 1e18; //15M xcoin all users

    uint256 public constant ROUND_2_TOKENSALE_LIMIT_PER_DAY = 1.5 * 1e6 * 1e18; //1.5M xcoin all users
    uint256 public constant ROUND_2_TOKENSALE_LIMIT = 15 * 1e6 * 1e18; //15M xcoin all users

    uint256 public constant ROUND_3_TOKENSALE_LIMIT_PER_DAY = 1.9 * 1e6 * 1e18; //1.9M xcoin all users
    uint256 public constant ROUND_3_TOKENSALE_LIMIT = 19 * 1e6 * 1e18; //19M xcoin all users

    // ===================
    bool public crowdsaleStarted = true;
    bool public crowdsalePaused = false;
    // Events
    event EthTransferred(string text);
    event EthRefunded(string text);

    function LendContract
    (
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _rate,
        address _wallet,
        uint256 _minDailyPerUser,
        uint256 _maxDailyPerUser,
        uint256 _dailyLimit,
        uint256 _stageLimit,
        MintableToken _token
    )
    public
    DailyLimitCrowdsale(_minDailyPerUser, _maxDailyPerUser, _dailyLimit, _stageLimit)
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime) {

    }
    function setCrowdsaleStage(uint value) public onlyOwner {
        require(value > uint(CrowdsaleStage.BT) && value < uint(CrowdsaleStage.EX));
        CrowdsaleStage _stage;
        if (uint(CrowdsaleStage.PS) == value) {
            _stage = CrowdsaleStage.PS;
            setCurrentRate(PRESALE_RATE);
            setMinDailyPerUser(PRESALE_MIN_DAILY_PER_USER);
            setMaxDailyPerUser(PRESALE_MAX_DAILY_PER_USER);
            setStageLimit(totalTokensForSaleDuringPreSale);
        } else if (uint(CrowdsaleStage.TS_R1) == value) {
            _stage = CrowdsaleStage.TS_R2;
            setCurrentRate(ROUND_1_TOKENSALE_RATE);
            // update limit
            setDailyLimit(ROUND_1_TOKENSALE_LIMIT_PER_DAY);
            setMinDailyPerUser(TOKENSALE_MIN_DAILY_PER_USER);
            setMaxDailyPerUser(TOKENSALE_MAX_DAILY_PER_USER);
            setStageLimit(ROUND_1_TOKENSALE_LIMIT);
        } else if (uint(CrowdsaleStage.TS_R2) == value) {
            _stage = CrowdsaleStage.TS_R2;
            setCurrentRate(ROUND_2_TOKENSALE_RATE);
            // update limit
            setDailyLimit(ROUND_2_TOKENSALE_LIMIT_PER_DAY);
            setMinDailyPerUser(TOKENSALE_MIN_DAILY_PER_USER);
            setMaxDailyPerUser(TOKENSALE_MAX_DAILY_PER_USER);
            setStageLimit(ROUND_2_TOKENSALE_LIMIT);
        } else if (uint(CrowdsaleStage.TS_R3) == value) {
            _stage = CrowdsaleStage.TS_R3;
            setCurrentRate(ROUND_2_TOKENSALE_RATE);
            // update limit
            setDailyLimit(ROUND_2_TOKENSALE_LIMIT_PER_DAY);
            setMinDailyPerUser(TOKENSALE_MIN_DAILY_PER_USER);
            setMaxDailyPerUser(TOKENSALE_MAX_DAILY_PER_USER);
            setStageLimit(ROUND_3_TOKENSALE_LIMIT);
        }
        stage = _stage;
    }

    // Change the current rate
    function setCurrentRate(uint256 _rate) private {
        rate = _rate;
    }

    function setRate(uint256 _rate) public onlyOwner {
        setCurrentRate(_rate);
    }

    function setCrowdSale(bool _started) public onlyOwner {
        crowdsaleStarted = _started;
    }
    // limit by user
    function setDailyLimit(uint256 _value) public onlyOwner {
        _setDailyLimit(_value);
    }
    function setMinDailyPerUser(uint256 _value) public onlyOwner {
        _setMinDailyPerUser(_value);
    }

    function setMaxDailyPerUser(uint256 _value) public onlyOwner {
        _setMaxDailyPerUser(_value);
    }
    function setStageLimit(uint256 _value) public onlyOwner {
        _setStageLimit(_value);
    }
    function pauseCrowdsale() public onlyOwner {
        crowdsalePaused = true;
    }

    function unPauseCrowdsale() public onlyOwner {
        crowdsalePaused = false;
    }
    // ===========================
    // Finish: Mint Extra Tokens as needed before finalizing the Crowdsale.
    // ====================================================================

    function finish(address _reserveFund) public onlyOwner {
        if (crowdsaleStarted) {
            uint256 alreadyMinted = token.totalSupply();
            require(alreadyMinted < maxTokens);

            uint256 unsoldTokens = totalTokensForTokenSale - alreadyMinted;
            if (unsoldTokens > 0) {
                tokensForReserve = tokensForReserve + unsoldTokens;
            }
            MintableToken(token).mint(_reserveFund, tokensForReserve);
            crowdsaleStarted = false;
        }
    }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract LendToken is MintableToken {
    string public name = "LENDXCOIN";
    string public symbol = "XCOIN";
    uint8 public decimals = 18;
    address public contractAddress;
    uint256 public fee;

    uint256 public constant FEE_TRANSFER = 5 * 1e15; // 0.005 xcoin

    uint256 public constant INITIAL_SUPPLY = 51 * 1e6 * (10 ** uint256(decimals)); // 50M + 1M bounty

    // Events
    event ChangedFee(address who, uint256 newFee);

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function LendToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        fee = FEE_TRANSFER;
    }

    function setContractAddress(address _contractAddress) external onlyOwner {
        if (_contractAddress != address(0)) {
            contractAddress = _contractAddress;
        }
    }

    function deliver(
        address _beneficiary,
        uint256 _tokenAmount
    )
    public
    returns (bool success)
    {
        require(_tokenAmount > 0);
        require(msg.sender == contractAddress);
        balances[_beneficiary] += _tokenAmount;
        totalSupply_ += _tokenAmount;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (msg.sender == owner) {
            return super.transfer(_to, _value);
        } else {
            require(fee <= balances[msg.sender]);
            balances[owner] = balances[owner].add(fee);
            balances[msg.sender] = balances[msg.sender].sub(fee);
            return super.transfer(_to, _value - fee);
        }
    }

    function setFee(uint256 _fee)
    onlyOwner
    public
    {
        fee = _fee;
        emit ChangedFee(msg.sender, _fee);
    }

}