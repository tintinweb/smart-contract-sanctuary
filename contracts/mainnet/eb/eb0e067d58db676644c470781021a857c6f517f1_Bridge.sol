pragma solidity ^0.4.18;

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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract MultiOwnable {

    mapping(address => bool) public isOwner;
    address[] public ownerHistory;
    uint8 public ownerCount;

    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

    function MultiOwnable() public {
        // Add default owner
        address owner = msg.sender;
        ownerHistory.push(owner);
        isOwner[owner] = true;
        ownerCount++;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }

    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

    /** Add extra owner. */
    function addOwner(address owner) onlyOwner public {
        require(owner != address(0));
        require(!isOwner[owner]);
        ownerHistory.push(owner);
        isOwner[owner] = true;
        ownerCount++;
        OwnerAddedEvent(owner);
    }

    /** Remove extra owner. */
    function removeOwner(address owner) onlyOwner public {

        // This check is neccessary to prevent a situation where all owners 
        // are accidentally removed, because we do not want an ownable contract 
        // to become an orphan.
        require(ownerCount > 1);

        require(isOwner[owner]);
        isOwner[owner] = false;
        ownerCount--;
        OwnerRemovedEvent(owner);
    }
}

contract Pausable is Ownable {

    bool public paused;

    modifier ifNotPaused {
        require(!paused);
        _;
    }

    modifier ifPaused {
        require(paused);
        _;
    }

    // Called by the owner on emergency, triggers paused state
    function pause() external onlyOwner ifNotPaused {
        paused = true;
    }

    // Called by the owner on end of emergency, returns to normal state
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}

contract ERC20 {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20 {

    using SafeMath for uint;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract CommonToken is StandardToken, MultiOwnable {

    string public constant name = &#39;White Rabbit Token&#39;;
    string public constant symbol = &#39;WRT&#39;;
    uint8 public constant decimals = 18;

    // The main account that holds all tokens from the time token created and during all tokensales.
    address public seller;

    // saleLimit (e18) Maximum amount of tokens for sale across all tokensales.
    // Reserved tokens formula: 16% Team + 6% Partners + 5% Advisory Board + 15% WR reserve 1 = 42%
    // For sale formula: 40% for sale + 1.5% Bounty + 16.5% WR reserve 2 = 58%
    uint256 public constant saleLimit = 110200000 ether;

    // Next fields are for stats:
    uint256 public tokensSold; // (e18) Number of tokens sold through all tiers or tokensales.
    uint256 public totalSales; // Total number of sales (including external sales) made through all tiers or tokensales.

    // Lock the transfer functions during tokensales to prevent price speculations.
    bool public locked = true;

    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();

    function CommonToken(
        address _seller
    ) MultiOwnable() public {

        require(_seller != 0);
        seller = _seller;

        totalSupply = 190000000 ether;
        balances[seller] = totalSupply;
        Transfer(0x0, seller, totalSupply);
    }

    modifier ifUnlocked() {
        require(isOwner[msg.sender] || !locked);
        _;
    }

    /**
     * An address can become a new seller only in case it has no tokens.
     * This is required to prevent stealing of tokens  from newSeller via 
     * 2 calls of this function.
     */
    function changeSeller(address newSeller) onlyOwner public returns (bool) {
        require(newSeller != address(0));
        require(seller != newSeller);

        // To prevent stealing of tokens from newSeller via 2 calls of changeSeller:
        require(balances[newSeller] == 0);

        address oldSeller = seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = unsoldTokens;
        Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }

    /**
     * User-friendly alternative to sell() function.
     */
    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value) onlyOwner public returns (bool) {

        // Check that we are not out of limit and still can sell tokens:
        if (saleLimit > 0) require(tokensSold.add(_value) <= saleLimit);

        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[seller]);

        balances[seller] = balances[seller].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(seller, _to, _value);

        totalSales++;
        tokensSold = tokensSold.add(_value);
        SellEvent(seller, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) ifUnlocked public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, 0x0, _value);
        Burn(msg.sender, _value);
        return true;
    }

    /** Can be called once by super owner. */
    function unlock() onlyOwner public {
        require(locked);
        locked = false;
        Unlock();
    }
}

contract CommonWhitelist is MultiOwnable {

    mapping(address => bool) public isAllowed;

    // Historical array of wallet that have bben added to whitelist,
    // even if some addresses have been removed later such wallet still remaining
    // in the history. This is Solidity optimization for work with large arrays.
    address[] public history;

    event AddedEvent(address indexed wallet);
    event RemovedEvent(address indexed wallet);

    function CommonWhitelist() MultiOwnable() public {}

    function historyCount() public view returns (uint) {
        return history.length;
    }

    function add(address _wallet) internal {
        require(_wallet != address(0));
        require(!isAllowed[_wallet]);

        history.push(_wallet);
        isAllowed[_wallet] = true;
        AddedEvent(_wallet);
    }

    function addMany(address[] _wallets) public onlyOwner {
        for (uint i = 0; i < _wallets.length; i++) {
            add(_wallets[i]);
        }
    }

    function remove(address _wallet) internal {
        require(isAllowed[_wallet]);

        isAllowed[_wallet] = false;
        RemovedEvent(_wallet);
    }

    function removeMany(address[] _wallets) public onlyOwner {
        for (uint i = 0; i < _wallets.length; i++) {
            remove(_wallets[i]);
        }
    }
}

//---------------------------------------------------------------
// Wings contracts: Start
// DO NOT CHANGE the next contracts. They were copied from Wings 
// and left unformated.

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
    function getToken() public returns (address);

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
        address _contract, // Forecasting contract
        uint256 _amount     // agreed part of totalCollected which is intended for rewards
    )
    public
    onlyManager() // manager is CrowdsaleController instance
    {
        require(_contract.call.value(_amount)());
    }

    // cancels crowdsale
    function stop() public onlyManager() hasntStopped() {
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
    onlyManager() // manager is CrowdsaleController instance
    hasntStarted() // not yet started
    hasntStopped() // crowdsale wasn&#39;t cancelled
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
    returns (bool)
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
    returns (bool)
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
    returns (bool)
    {
        return (
        // either the hard cap is collected
        totalCollected >= hardCap ||

        // ...or the crowdfunding period is over, but the minimum has been reached
        (block.timestamp >= endTimestamp && totalCollected >= minimalGoal)
        );
    }
}

// Minimal crowdsale token for custom contracts
contract IWingsController {
    uint256 public ethRewardPart;
    uint256 public tokenRewardPart;
}

/*
  Implements custom crowdsale as bridge
*/
contract Bridge is BasicCrowdsale {
    using SafeMath for uint256;

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

    // Crowdsale token
    StandardToken token;

    // Address of crowdsale
    address public crowdsaleAddress;

    // is crowdsale completed
    bool public completed;

    // Ctor. In this example, minimalGoal, hardCap, and price are not changeable.
    // In more complex cases, those parameters may be changed until start() is called.
    function Bridge(
        uint256 _minimalGoal,
        uint256 _hardCap,
        address _token,
        address _crowdsaleAddress
    )
    public
        // simplest case where manager==owner. See onlyOwner() and onlyManager() modifiers
        // before functions to figure out the cases in which those addresses should differ
    BasicCrowdsale(msg.sender, msg.sender)
    {
        // just setup them once...
        minimalGoal = _minimalGoal;
        hardCap = _hardCap;
        crowdsaleAddress = _crowdsaleAddress;
        token = StandardToken(_token);
    }

    // Here goes ICrowdsaleProcessor implementation

    // returns address of crowdsale token. The token must be ERC20-compliant
    function getToken()
    public
    returns (address)
    {
        return address(token);
    }

    // called by CrowdsaleController to transfer reward part of
    // tokens sold by successful crowdsale to Forecasting contract.
    // This call is made upon closing successful crowdfunding process.
    function mintTokenRewards(
        address _contract, // Forecasting contract
        uint256 _amount     // agreed part of totalSold which is intended for rewards
    )
    public
    onlyManager() // manager is CrowdsaleController instance
    {
        // crowdsale token is mintable in this example, tokens are created here
        token.transfer(_contract, _amount);
    }

    // transfers crowdsale token from mintable to transferrable state
    function releaseTokens()
    public
    onlyManager() // manager is CrowdsaleController instance
    hasntStopped() // crowdsale wasn&#39;t cancelled
    whenCrowdsaleSuccessful() // crowdsale was successful
    {
        // empty for bridge
    }

    // Here go crowdsale process itself and token manipulations

    // default function allows for ETH transfers to the contract
    function() payable public {
    }

    function notifySale(uint256 _ethAmount, uint256 _tokensAmount) public
    hasBeenStarted() // crowdsale started
    hasntStopped() // wasn&#39;t cancelled by owner
    whenCrowdsaleAlive() // in active state
    onlyCrowdsale() // can do only crowdsale
    {
        totalCollected = totalCollected.add(_ethAmount);
        totalSold = totalSold.add(_tokensAmount);
    }

    // finish collecting data
    function finish() public
    hasntStopped()
    hasBeenStarted()
    whenCrowdsaleAlive()
    onlyCrowdsale()
    {
        completed = true;
    }

    // project&#39;s owner withdraws ETH funds to the funding address upon successful crowdsale
    function withdraw(
        uint256 _amount // can be done partially
    )
    public
    onlyOwner() // project&#39;s owner
    hasntStopped() // crowdsale wasn&#39;t cancelled
    whenCrowdsaleSuccessful() // crowdsale completed successfully
    {
        // nothing to withdraw
    }

    // backers refund their ETH if the crowdsale was cancelled or has failed
    function refund()
    public
    {
        // nothing to refund
    }

    // called by CrowdsaleController to setup start and end time of crowdfunding process
    // as well as funding address (where to transfer ETH upon successful crowdsale)
    function start(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _fundingAddress
    )
    public
    onlyManager() // manager is CrowdsaleController instance
    hasntStarted() // not yet started
    hasntStopped() // crowdsale wasn&#39;t cancelled
    {
        // just start crowdsale
        started = true;

        CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
    }

    // must return true if crowdsale is over, but it failed
    function isFailed()
    public
    constant
    returns (bool)
    {
        return (
        false
        );
    }

    // must return true if crowdsale is active (i.e. the token can be bought)
    function isActive()
    public
    constant
    returns (bool)
    {
        return (
        // we remove timelines
        started && !completed
        );
    }

    // must return true if crowdsale completed successfully
    function isSuccessful()
    public
    constant
    returns (bool)
    {
        return (
        completed
        );
    }

    function calculateRewards() public view returns (uint256, uint256) {
        uint256 tokenRewardPart = IWingsController(manager).tokenRewardPart();
        uint256 ethRewardPart = IWingsController(manager).ethRewardPart();

        uint256 tokenReward = totalSold.mul(tokenRewardPart) / 1000000;
        bool hasEthReward = (ethRewardPart != 0);

        uint256 ethReward = 0;
        if (hasEthReward) {
            ethReward = totalCollected.mul(ethRewardPart) / 1000000;
        }

        return (ethReward, tokenReward);
    }
}

contract Connector is Ownable {
    modifier bridgeInitialized() {
        require(address(bridge) != address(0x0));
        _;
    }

    Bridge public bridge;

    function changeBridge(address _bridge) public onlyOwner {
        require(_bridge != address(0x0));
        bridge = Bridge(_bridge);
    }

    function notifySale(uint256 _ethAmount, uint256 _tokenAmount) internal bridgeInitialized {
        bridge.notifySale(_ethAmount, _tokenAmount);
    }

    function closeBridge() internal bridgeInitialized {
        bridge.finish();
    }
}

// Wings contracts: End
//---------------------------------------------------------------

contract CommonTokensale is Connector, Pausable {

    using SafeMath for uint;

    CommonToken public token;         // Token contract reference.
    CommonWhitelist public whitelist; // Whitelist contract reference.

    address public beneficiary;       // Address that will receive ETH raised during this tokensale.
    address public bsWallet = 0x8D5bd2aBa04A07Bfa0cc976C73eD45B23cC6D6a2;

    bool public whitelistEnabled = true;

    uint public constant preSaleMinPaymentWei = 5 ether;    // Hint: Set to lower amount (ex. 0.001 ETH) for tests.
    uint public constant mainSaleMinPaymentWei = 0.05 ether; // Hint: Set to lower amount (ex. 0.001 ETH) for tests.

    uint public defaultTokensPerWei = 4750; // TODO To be determined based on ETH to USD price at the date of sale.
    uint public tokensPerWei5;
    uint public tokensPerWei7;
    uint public tokensPerWei10;
    uint public tokensPerWei15;
    uint public tokensPerWei20;

    uint public minCapWei = 3200 ether;  // TODO  2m USD. Recalculate based on ETH to USD price at the date of tokensale.
    uint public maxCapWei = 16000 ether; // TODO 10m USD. Recalculate based on ETH to USD price at the date of tokensale.

    uint public constant startTime = 1525701600; // May 7, 2018 2:00:00 PM
    uint public constant preSaleEndTime = 1526306400; // May 14, 2018 2:00:00 PM
    uint public constant mainSaleStartTime = 1526392800; // May 15, 2018 2:00:00 PM
    uint public constant endTime = 1528639200; // June 10, 2018 2:00:00 PM

    // At main sale bonuses will be available only during the first 48 hours.
    uint public mainSaleBonusEndTime;

    // In case min (soft) cap is not reached, token buyers will be able to 
    // refund their contributions during one month after sale is finished.
    uint public refundDeadlineTime;

    // Stats for current tokensale:

    uint public totalTokensSold;  // Total amount of tokens sold during this tokensale.
    uint public totalWeiReceived; // Total amount of wei received during this tokensale.
    uint public totalWeiRefunded; // Total amount of wei refunded if min (soft) cap is not reached.

    // This mapping stores info on how many ETH (wei) have been sent to this tokensale from specific address.
    mapping(address => uint256) public buyerToSentWei;

    mapping(bytes32 => bool) public calledOnce;

    event ChangeBeneficiaryEvent(address indexed _oldAddress, address indexed _newAddress);
    event ChangeWhitelistEvent(address indexed _oldAddress, address indexed _newAddress);
    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);
    event RefundEthEvent(address indexed _buyer, uint256 _amountWei);

    function CommonTokensale(
        address _token,
        address _whitelist,
        address _beneficiary
    ) public Connector() {
        require(_token != 0);
        require(_whitelist != 0);
        require(_beneficiary != 0);

        token = CommonToken(_token);
        whitelist = CommonWhitelist(_whitelist);
        beneficiary = _beneficiary;

        mainSaleBonusEndTime = mainSaleStartTime + 48 hours;
        refundDeadlineTime = endTime + 30 days;

        recalcBonuses();
    }

    modifier canBeCalledOnce(bytes32 _flag) {
        require(!calledOnce[_flag]);
        calledOnce[_flag] = true;
        _;
    }

    function updateMinCapEthOnce(uint _amountInEth) public onlyOwner canBeCalledOnce("updateMinCapEth") {
        minCapWei = _amountInEth * 1e18;
        // Convert ETH to Wei and update a min cap.
    }

    function updateMaxCapEthOnce(uint _amountInEth) public onlyOwner canBeCalledOnce("updateMaxCapEth") {
        maxCapWei = _amountInEth * 1e18;
        // Convert ETH to Wei and update a max cap.
    }

    function updateTokensPerEthOnce(uint _amountInEth) public onlyOwner canBeCalledOnce("updateTokensPerEth") {
        defaultTokensPerWei = _amountInEth;
        recalcBonuses();
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != 0);
        ChangeBeneficiaryEvent(beneficiary, _beneficiary);
        beneficiary = _beneficiary;
    }

    function setWhitelist(address _whitelist) public onlyOwner {
        require(_whitelist != 0);
        ChangeWhitelistEvent(whitelist, _whitelist);
        whitelist = CommonWhitelist(_whitelist);
    }

    function setWhitelistEnabled(bool _enabled) public onlyOwner {
        whitelistEnabled = _enabled;
    }

    /** The fallback function corresponds to a donation in ETH. */
    function() public payable {
        sellTokensForEth(msg.sender, msg.value);
    }

    function sellTokensForEth(
        address _buyer,
        uint256 _amountWei
    ) ifNotPaused internal {

        // Check that buyer is in whitelist onlist if whitelist check is enabled.
        if (whitelistEnabled) require(whitelist.isAllowed(_buyer));

        require(canAcceptPayment(_amountWei));
        require(totalWeiReceived < maxCapWei);

        uint256 newTotalReceived = totalWeiReceived.add(_amountWei);

        // Don&#39;t sell anything above the hard cap
        if (newTotalReceived > maxCapWei) {
            uint refundWei = newTotalReceived.sub(maxCapWei);
            _amountWei = _amountWei.sub(refundWei);

            // We need to check payment amount once more such as we updated 
            // (reduced) it in this if-clause.
            require(canAcceptPayment(_amountWei));

            // Send the ETH part which exceeds the hard cap back to the buyer:
            _buyer.transfer(refundWei);
        }

        uint tokensE18 = weiToTokens(_amountWei);
        // Transfer tokens to buyer.
        token.sell(_buyer, tokensE18);

        // 0.75% of sold tokens go to BS account:
        uint bsTokens = tokensE18.mul(75).div(10000);
        token.sell(bsWallet, bsTokens);

        // Update total stats:
        totalTokensSold = totalTokensSold.add(tokensE18).add(bsTokens);
        totalWeiReceived = totalWeiReceived.add(_amountWei);
        buyerToSentWei[_buyer] = buyerToSentWei[_buyer].add(_amountWei);
        ReceiveEthEvent(_buyer, _amountWei);

        // Notify Wings about successful sale of tokens:
        notifySale(_amountWei, tokensE18.add(bsTokens));
    }

    function recalcBonuses() internal {
        tokensPerWei5 = tokensPerWeiPlusBonus(5);
        tokensPerWei7 = tokensPerWeiPlusBonus(7);
        tokensPerWei10 = tokensPerWeiPlusBonus(10);
        tokensPerWei15 = tokensPerWeiPlusBonus(15);
        tokensPerWei20 = tokensPerWeiPlusBonus(20);
    }

    function tokensPerWeiPlusBonus(uint _per) public view returns (uint) {
        return defaultTokensPerWei.add(
            amountPercentage(defaultTokensPerWei, _per)
        );
    }

    function amountPercentage(uint _amount, uint _per) public pure returns (uint) {
        return _amount.mul(_per).div(100);
    }

    /** Calc how much tokens you can buy at current time. */
    function weiToTokens(uint _amountWei) public view returns (uint) {
        return _amountWei.mul(tokensPerWei(_amountWei));
    }

    function tokensPerWei(uint _amountWei) public view returns (uint256) {
        // Presale bonuses:
        if (isPreSaleTime()) {
            if (5 ether <= _amountWei && _amountWei < 10 ether) return tokensPerWei10;
            if (_amountWei < 20 ether) return tokensPerWei15;
            if (20 ether <= _amountWei) return tokensPerWei20;
        }
        // Main sale bonues:
        if (isMainSaleBonusTime()) {
            if (0.05 ether <= _amountWei && _amountWei < 10 ether) return tokensPerWei5;
            if (_amountWei < 20 ether) return tokensPerWei7;
            if (20 ether <= _amountWei) return tokensPerWei10;
        }
        return defaultTokensPerWei;
    }

    function canAcceptPayment(uint _amountWei) public view returns (bool) {
        if (isPreSaleTime()) return _amountWei >= preSaleMinPaymentWei;
        if (isMainSaleTime()) return _amountWei >= mainSaleMinPaymentWei;
        return false;
    }

    function isPreSaleTime() public view returns (bool) {
        return startTime <= now && now <= preSaleEndTime;
    }

    function isMainSaleBonusTime() public view returns (bool) {
        return mainSaleStartTime <= now && now <= mainSaleBonusEndTime;
    }

    function isMainSaleTime() public view returns (bool) {
        return mainSaleStartTime <= now && now <= endTime;
    }

    function isFinishedSuccessfully() public view returns (bool) {
        return totalWeiReceived >= minCapWei && now > endTime;
    }

    /** 
     * During tokensale it will be possible to withdraw only in two cases:
     * min cap reached OR refund period expired.
     */
    function canWithdraw() public view returns (bool) {
        return totalWeiReceived >= minCapWei || now > refundDeadlineTime;
    }

    /** 
     * This method allows to withdraw to any arbitrary ETH address. 
     * This approach gives more flexibility.
     */
    function withdraw(address _to, uint256 _amount) public {
        require(canWithdraw());
        require(msg.sender == beneficiary);
        require(_amount <= this.balance);

        _to.transfer(_amount);
    }

    function withdraw(address _to) public {
        withdraw(_to, this.balance);
    }

    /** 
     * It will be possible to refund only if min (soft) cap is not reached and 
     * refund requested during 30 days after tokensale finished.
     */
    function canRefund() public view returns (bool) {
        return totalWeiReceived < minCapWei && endTime < now && now <= refundDeadlineTime;
    }

    function refund() public {
        require(canRefund());

        address buyer = msg.sender;
        uint amount = buyerToSentWei[buyer];
        require(amount > 0);

        RefundEthEvent(buyer, amount);
        buyerToSentWei[buyer] = 0;
        totalWeiRefunded = totalWeiRefunded.add(amount);
        buyer.transfer(amount);
    }

    /**
     * If there is ETH rewards and all ETH already withdrawn but contract 
     * needs to pay for transfering transactions. 
     */
    function deposit() public payable {
        require(isFinishedSuccessfully());
    }

    /** 
     * This function should be called only once only after 
     * successfully finished tokensale. Once - because Wings bridge 
     * will be closed at the end of this function call.
     */
    function sendWingsRewardsOnce() public onlyOwner canBeCalledOnce("sendWingsRewards") {
        require(isFinishedSuccessfully());

        uint256 ethReward = 0;
        uint256 tokenReward = 0;

        (ethReward, tokenReward) = bridge.calculateRewards();

        if (ethReward > 0) {
            bridge.transfer(ethReward);
        }

        if (tokenReward > 0) {
            token.sell(bridge, tokenReward);
        }

        // Close Wings bridge
        closeBridge();
    }
}


// >> Start:
// >> EXAMPLE: How to deploy Token, Whitelist and Tokensale.

// token = new CommonToken(
//     0x123 // TODO Set seller address
// );
// whitelist = new CommonWhitelist();
// tokensale = new Tokensale(
//     token,
//     whitelist,
//     0x123 // TODO Set beneficiary address
// );
// token.addOwner(tokensale);

// << EXAMPLE: How to deploy Token, Whitelist and Tokensale.
// << End


// TODO After Tokensale deployed, call token.addOwner(address_of_deployed_tokensale)
contract ProdTokensale is CommonTokensale {
    function ProdTokensale() CommonTokensale(
        0x123, // TODO Set token address
        0x123, // TODO Set whitelist address
        0x123  // TODO Set beneficiary address
    ) public {}
}