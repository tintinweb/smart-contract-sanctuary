pragma solidity ^0.4.23;


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
  
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}



contract DefaultToken is BasicToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}



// Wings Controller Interface
contract IWingsController {
  uint256 public ethRewardPart;
  uint256 public tokenRewardPart;

  function fitCollectedValueIntoRange(uint256 _totalCollected) public view returns (uint256);
}


contract HasManager {
  address public manager;

  modifier onlyManager {
    require(msg.sender == manager);
    _;
  }

  function transferManager(address _newManager) public onlyManager() {
    require(_newManager != address(0));
    manager = _newManager;
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


// Crowdsale contracts interface
contract ICrowdsaleProcessor is Ownable, HasManager {
  modifier whenCrowdsaleAlive() {
    require(isActive());
    _;
  }

  modifier whenCrowdsaleFailed() {
    require(isFailed());
    _;
  }

  modifier whenCrowdsaleSuccessful() {
    require(isSuccessful());
    _;
  }

  modifier hasntStopped() {
    require(!stopped);
    _;
  }

  modifier hasBeenStopped() {
    require(stopped);
    _;
  }

  modifier hasntStarted() {
    require(!started);
    _;
  }

  modifier hasBeenStarted() {
    require(started);
    _;
  }

  // Minimal acceptable hard cap
  uint256 constant public MIN_HARD_CAP = 1 ether;

  // Minimal acceptable duration of crowdsale
  uint256 constant public MIN_CROWDSALE_TIME = 3 days;

  // Maximal acceptable duration of crowdsale
  uint256 constant public MAX_CROWDSALE_TIME = 50 days;

  // Becomes true when timeframe is assigned
  bool public started;

  // Becomes true if cancelled by owner
  bool public stopped;

  // Total collected forecast question currency
  uint256 public totalCollected;

  // Total collected Ether
  uint256 public totalCollectedETH;

  // Total amount of project&#39;s token sold: must be updated every time tokens has been sold
  uint256 public totalSold;

  // Crowdsale minimal goal, must be greater or equal to Forecasting min amount
  uint256 public minimalGoal;

  // Crowdsale hard cap, must be less or equal to Forecasting max amount
  uint256 public hardCap;

  // Crowdsale duration in seconds.
  // Accepted range is MIN_CROWDSALE_TIME..MAX_CROWDSALE_TIME.
  uint256 public duration;

  // Start timestamp of crowdsale, absolute UTC time
  uint256 public startTimestamp;

  // End timestamp of crowdsale, absolute UTC time
  uint256 public endTimestamp;

  // Allows to transfer some ETH into the contract without selling tokens
  function deposit() public payable {}

  // Returns address of crowdsale token, must be ERC20 compilant
  function getToken() public returns(address);

  // Transfers ETH rewards amount (if ETH rewards is configured) to Forecasting contract
  function mintETHRewards(address _contract, uint256 _amount) public onlyManager();

  // Mints token Rewards to Forecasting contract
  function mintTokenRewards(address _contract, uint256 _amount) public onlyManager();

  // Releases tokens (transfers crowdsale token from mintable to transferrable state)
  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful();

  // Stops crowdsale. Called by CrowdsaleController, the latter is called by owner.
  // Crowdsale may be stopped any time before it finishes.
  function stop() public onlyManager() hasntStopped();

  // Validates parameters and starts crowdsale
  function start(uint256 _startTimestamp, uint256 _endTimestamp, address _fundingAddress)
    public onlyManager() hasntStarted() hasntStopped();

  // Is crowdsale failed (completed, but minimal goal wasn&#39;t reached)
  function isFailed() public constant returns (bool);

  // Is crowdsale active (i.e. the token can be sold)
  function isActive() public constant returns (bool);

  // Is crowdsale completed successfully
  function isSuccessful() public constant returns (bool);
}


// Basic crowdsale implementation both for regualt and 3rdparty Crowdsale contracts
contract BasicCrowdsale is ICrowdsaleProcessor {
  event CROWDSALE_START(uint256 startTimestamp, uint256 endTimestamp, address fundingAddress);

  // Where to transfer collected ETH
  address public fundingAddress;

  // Ctor.
  function BasicCrowdsale(
    address _owner,
    address _manager
  )
    public
  {
    owner = _owner;
    manager = _manager;
  }

  // called by CrowdsaleController to transfer reward part of ETH
  // collected by successful crowdsale to Forecasting contract.
  // This call is made upon closing successful crowdfunding process
  // iff agreed ETH reward part is not zero
  function mintETHRewards(
    address _contract,  // Forecasting contract
    uint256 _amount     // agreed part of totalCollected which is intended for rewards
  )
    public
    onlyManager() // manager is CrowdsaleController instance
  {
    require(_contract.call.value(_amount)());
  }

  // cancels crowdsale
  function stop() public onlyManager() hasntStopped()  {
    // we can stop only not started and not completed crowdsale
    if (started) {
      require(!isFailed());
      require(!isSuccessful());
    }
    stopped = true;
  }

  // called by CrowdsaleController to setup start and end time of crowdfunding process
  // as well as funding address (where to transfer ETH upon successful crowdsale)
  function start(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    address _fundingAddress
  )
    public
    onlyManager()   // manager is CrowdsaleController instance
    hasntStarted()  // not yet started
    hasntStopped()  // crowdsale wasn&#39;t cancelled
  {
    require(_fundingAddress != address(0));

    // start time must not be earlier than current time
    require(_startTimestamp >= block.timestamp);

    // range must be sane
    require(_endTimestamp > _startTimestamp);
    duration = _endTimestamp - _startTimestamp;

    // duration must fit constraints
    require(duration >= MIN_CROWDSALE_TIME && duration <= MAX_CROWDSALE_TIME);

    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    fundingAddress = _fundingAddress;

    // now crowdsale is considered started, even if the current time is before startTimestamp
    started = true;

    CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
  }

  // must return true if crowdsale is over, but it failed
  function isFailed()
    public
    constant
    returns(bool)
  {
    return (
      // it was started
      started &&

      // crowdsale period has finished
      block.timestamp >= endTimestamp &&

      // but collected ETH is below the required minimum
      totalCollected < minimalGoal
    );
  }

  // must return true if crowdsale is active (i.e. the token can be bought)
  function isActive()
    public
    constant
    returns(bool)
  {
    return (
      // it was started
      started &&

      // hard cap wasn&#39;t reached yet
      totalCollected < hardCap &&

      // and current time is within the crowdfunding period
      block.timestamp >= startTimestamp &&
      block.timestamp < endTimestamp
    );
  }

  // must return true if crowdsale completed successfully
  function isSuccessful()
    public
    constant
    returns(bool)
  {
    return (
      // either the hard cap is collected
      totalCollected >= hardCap ||

      // ...or the crowdfunding period is over, but the minimum has been reached
      (block.timestamp >= endTimestamp && totalCollected >= minimalGoal)
    );
  }
}


/*
  Standalone Bridge
*/
contract Bridge is BasicCrowdsale {

  using SafeMath for uint256;

  event CUSTOM_CROWDSALE_TOKEN_ADDED(address token, uint8 decimals);
  event CUSTOM_CROWDSALE_FINISH();

  // Crowdsale token must be ERC20-compliant
  DefaultToken token;

  // Crowdsale state
  bool completed;

  // Constructor
  constructor(
    //uint256 _minimalGoal,
    //uint256 _hardCap,
    //address _token
  ) public
    BasicCrowdsale(msg.sender, msg.sender) // owner, manager
  {
    minimalGoal = 1;
    hardCap = 1;
    token = DefaultToken(0x9998Db897783603c9344ED2678AB1B5D73d0f7C3);
  }

  /*
     Here goes ICrowdsaleProcessor methods implementation
  */

  // Returns address of crowdsale token
  function getToken()
    public
    returns (address)
  {
    return address(token);
  }

  // Mints token Rewards to Forecasting contract
  // called by CrowdsaleController
  function mintTokenRewards(
    address _contract,
    uint256 _amount    // agreed part of totalSold which is intended for rewards
  )
    public
    onlyManager()
  {
    // in our example we are transferring tokens instead of minting them
    token.transfer(_contract, _amount);
  }

  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful() {
  }

  /*
     Crowdsale methods implementation
  */

  // Fallback payable function
  function() public payable {
  }

  // Update information about collected ETH and sold tokens amount
  function notifySale(uint256 _amount, uint256 _ethAmount, uint256 _tokensAmount)
    public
    hasBeenStarted()
    hasntStopped()
    whenCrowdsaleAlive()
    onlyOwner()
  {
    totalCollected = totalCollected.add(_amount);
    totalCollectedETH = totalCollectedETH.add(_ethAmount);
    totalSold = totalSold.add(_tokensAmount);
  }

  // Validates parameters and starts crowdsale
  // called by CrowdsaleController
  function start(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    address _fundingAddress
  )
    public
    hasntStarted()
    hasntStopped()
    onlyManager()
  {
    started = true;

    emit CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
  }

  // Finish crowdsale
  function finish()
    public
    hasntStopped()
    hasBeenStarted()
    whenCrowdsaleAlive()
    onlyOwner()
  {
    completed = true;

    emit CUSTOM_CROWDSALE_FINISH();
  }

  function isFailed()
    public
    view
    returns (bool)
  {
    return (false);
  }

  function isActive()
    public
    view
    returns (bool)
  {
    return (started && !completed);
  }

  function isSuccessful()
    public
    view
    returns (bool)
  {
    return (completed);
  }

  // Find out the amount of rewards in ETH and tokens
  function calculateRewards() public view returns (uint256, uint256) {
    uint256 tokenRewardPart = IWingsController(manager).tokenRewardPart();
    uint256 ethRewardPart = IWingsController(manager).ethRewardPart();
    uint256 ethReward;
    bool hasEthReward = (ethRewardPart != 0);

    uint256 tokenReward = totalSold.mul(tokenRewardPart) / 1000000;

    if (totalCollectedETH != 0) {
      totalCollected = totalCollectedETH;
    }

    totalCollected = IWingsController(manager).fitCollectedValueIntoRange(totalCollected);

    if (hasEthReward) {
      ethReward = totalCollected.mul(ethRewardPart) / 1000000;
    }

    return (ethReward, tokenReward);
  }

  // Change token address (in case you&#39;ve used the dafault token address during bridge deployment)
  function changeToken(address _newToken) public onlyOwner() {
    token = DefaultToken(_newToken);

    emit CUSTOM_CROWDSALE_TOKEN_ADDED(address(token), uint8(token.decimals()));
  }

  // Gives owner ability to withdraw eth and wings from Bridge contract balance in case if some error during reward calculation occured
  function withdraw() public onlyOwner() {
    uint256 ethBalance = address(this).balance;
    uint256 tokenBalance = token.balanceOf(address(this));

    if (ethBalance > 0) {
      require(msg.sender.send(ethBalance));
    }

    if (tokenBalance > 0) {
      require(token.transfer(msg.sender, tokenBalance));
    }
  }
}