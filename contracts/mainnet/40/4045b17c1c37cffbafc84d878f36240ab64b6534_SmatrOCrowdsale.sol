pragma solidity ^0.4.18;

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
  function Ownable() public { owner = msg.sender; }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {owner = newOwner;}
}contract IERC20 {

  function totalSupply() public constant returns (uint256);

  function balanceOf(address _owner) public constant returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  function allowance(address _owner, address _spender) public constant returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

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

  // Total collected Ethereum: must be updated every time tokens has been sold
  uint256 public totalCollected;

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






library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SmartOToken is Ownable, IERC20 {

  using SafeMath for uint256;

  /* Public variables of the token */
  string public constant name = "STO";
  string public constant symbol = "STO";
  uint public constant decimals = 18;
  uint256 public constant initialSupply = 12000000000 * 1 ether;
  uint256 public totalSupply;

  /* This creates an array with all balances */
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  /* Events */
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);

  /* Constuctor: Initializes contract with initial supply tokens to the creator of the contract */
  function SmartOToken() public {
      balances[msg.sender] = initialSupply;              // Give the creator all initial tokens
      totalSupply = initialSupply;                        // Update total supply
  }


  /* Implementation of ERC20Interface */

  function totalSupply() public constant returns (uint256) { return totalSupply; }

  function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }

  /* Internal transfer, only can be called by this contract */
  function _transfer(address _from, address _to, uint _amount) internal {
      require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
      require (balances[_from] >= _amount);                // Check if the sender has enough
      balances[_from] = balances[_from].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(_from, _to, _amount);

  }

  function transfer(address _to, uint256 _amount) public returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require (_value <= allowed[_from][msg.sender]);     // Check allowance
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _amount) public returns (bool) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowed[_owner][_spender];
  }

}

// Custom crowdsale example
contract SmatrOCrowdsale is BasicCrowdsale {
  // Crowdsale participants
  mapping(address => uint256) participants;

  // tokens per ETH fixed price
  uint256 tokensPerEthPrice;

  // Crowdsale token
  SmartOToken crowdsaleToken;

  // Ctor. In this example, minimalGoal, hardCap, and price are not changeable.
  // In more complex cases, those parameters may be changed until start() is called.
  function SmatrOCrowdsale(
    uint256 _minimalGoal,
    uint256 _hardCap,
    uint256 _tokensPerEthPrice,
    address _token
  )
    public
    // simplest case where manager==owner. See onlyOwner() and onlyManager() modifiers
    // before functions to figure out the cases in which those addresses should differ
    BasicCrowdsale(msg.sender, msg.sender)
  {
    // just setup them once...
    minimalGoal = _minimalGoal;
    hardCap = _hardCap;
    tokensPerEthPrice = _tokensPerEthPrice;
    crowdsaleToken = SmartOToken(_token);
  }

// Here goes ICrowdsaleProcessor implementation

  // returns address of crowdsale token. The token must be ERC20-compliant
  function getToken()
    public
    returns(address)
  {
    return address(crowdsaleToken);
  }

  // called by CrowdsaleController to transfer reward part of
  // tokens sold by successful crowdsale to Forecasting contract.
  // This call is made upon closing successful crowdfunding process.
  function mintTokenRewards(
    address _contract,  // Forecasting contract
    uint256 _amount     // agreed part of totalSold which is intended for rewards
  )
    public
    onlyManager() // manager is CrowdsaleController instance
  {
    // crowdsale token is mintable in this example, tokens are created here
    crowdsaleToken.transfer(_contract, _amount);
  }

  // transfers crowdsale token from mintable to transferrable state
  function releaseTokens()
    public
    onlyManager()             // manager is CrowdsaleController instance
    hasntStopped()            // crowdsale wasn&#39;t cancelled
    whenCrowdsaleSuccessful() // crowdsale was successful
  {
    // do nothing
  }

// Here go crowdsale process itself and token manipulations

  function setRate(uint256 _tokensPerEthPrice)
    public
    onlyOwner
  {
    tokensPerEthPrice = _tokensPerEthPrice;
  }

  // default function allows for ETH transfers to the contract
  function () payable public {
    require(msg.value >= 0.1 * 1 ether);

    // and it sells the token
    sellTokens(msg.sender, msg.value);
  }

  // sels the project&#39;s token to buyers
  function sellTokens(address _recepient, uint256 _value)
    internal
    hasBeenStarted()     // crowdsale started
    hasntStopped()       // wasn&#39;t cancelled by owner
    whenCrowdsaleAlive() // in active state
  {
    uint256 newTotalCollected = totalCollected + _value;

    if (hardCap < newTotalCollected) {
      // don&#39;t sell anything above the hard cap

      uint256 refund = newTotalCollected - hardCap;
      uint256 diff = _value - refund;

      // send the ETH part which exceeds the hard cap back to the buyer
      _recepient.transfer(refund);
      _value = diff;
    }

    // token amount as per price (fixed in this example)
    uint256 tokensSold = _value * tokensPerEthPrice;

    // create new tokens for this buyer
    crowdsaleToken.transfer(_recepient, tokensSold);

    // remember the buyer so he/she/it may refund its ETH if crowdsale failed
    participants[_recepient] += _value;

    // update total ETH collected
    totalCollected += _value;

    // update totel tokens sold
    totalSold += tokensSold;
  }

  // project&#39;s owner withdraws ETH funds to the funding address upon successful crowdsale
  function withdraw(
    uint256 _amount // can be done partially
  )
    public
    onlyOwner() // project&#39;s owner
    hasntStopped()  // crowdsale wasn&#39;t cancelled
    whenCrowdsaleSuccessful() // crowdsale completed successfully
  {
    require(_amount <= this.balance);
    fundingAddress.transfer(_amount);
  }

  // backers refund their ETH if the crowdsale was cancelled or has failed
  function refund()
    public
  {
    // either cancelled or failed
    require(stopped || isFailed());

    uint256 amount = participants[msg.sender];

    // prevent from doing it twice
    require(amount > 0);
    participants[msg.sender] = 0;

    msg.sender.transfer(amount);
  }
}