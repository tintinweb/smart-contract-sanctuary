library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
    * @dev give an account access to this role
    */
    function add(Role storage role, address account) internal {
        require(account != address(0), "the 0x0 address cannot hold roles");
        require(!has(role, account), "this account already has already been given this role");

        role.bearer[account] = true;
    }

    /**
    * @dev remove an account&#39;s access to this role
    */
    function remove(Role storage role, address account) internal {
        require(account != address(0), "the 0x0 address cannot hold roles");
        require(has(role, account), "this account doesn&#39;t have this role to remove");

        role.bearer[account] = false;
    }

    /**
    * @dev check if an account has this role
    * @return bool
    */
    function has(Role storage role, address account)
      internal
      view
      returns (bool)
    {
        require(account != address(0), "the 0x0 address cannot hold roles");
        return role.bearer[account];
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "c divided by a must equal b, otherwise a * b has overflowed");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "cannot divide by zero"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "b must be less than or equal to a, otherwise c could overflow");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "c must be greter than or equal to a, otherwise a + b has overflown");

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "cannot divide by zero");
        return a % b;
    }
}
contract FundkeeperRole {
    using Roles for Roles.Role;

    address public fundkeeper;

    event FundkeeperTransferred(
      address indexed previousKeeper,
      address indexed newKeeper
    );

    Roles.Role private fundkeepers;

    constructor() internal {
        _addFundkeeper(msg.sender);
    }

    modifier onlyFundkeeper() {
        require(isFundkeeper(msg.sender), "msg.sender does not have the fundkeeper role");
        _;
    }

    function isFundkeeper(address account) public view returns (bool) {
        return fundkeepers.has(account);
    }

    function transferFundkeeper(address newFundkeeper) public onlyFundkeeper {
        _transferFundkeeper(newFundkeeper);
    }

    /**
    * @dev Transfers control of the intial contract tokens to a newFunkeeper.
    * @param newFundkeeper The address to transfer the fundkeeper role to.
    */
    function _transferFundkeeper(address newFundkeeper) internal {
        _addFundkeeper(newFundkeeper);
        _removeFundkeeper(msg.sender);
        emit FundkeeperTransferred(msg.sender, newFundkeeper);
    }

    function renounceFundkeeper() public {
        _removeFundkeeper(msg.sender);
    }

    function _addFundkeeper(address account) internal {
        require(account != address(0), "fundkeeper role cannot be held by 0x0");
        fundkeepers.add(account);
        fundkeeper = account;
        emit FundkeeperTransferred(address(0), account);
    }

    function _removeFundkeeper(address account) internal {
        fundkeepers.remove(account);
        emit FundkeeperTransferred(account, address(0));
    }
}
contract IERC20 is FundkeeperRole{ 
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(
      address indexed from,
      address indexed to,
      uint256 value
    );

    event Approval(
      address indexed owner,
      address indexed spender,
      uint256 value
    );
}
interface ICrowdsale {

  /** 
  * Getters
  */

  function getInterval(uint256 blockNumber) external view returns (uint256);
  
  function getERC20() external view returns (address);
  
  function getDistributedTotal() external view returns (uint256);
    
  function currentStage() external view returns (uint256);

  /*** CrowdsaleDeployed Stage functions ***/ 

  /** 
  * Manager Role Functionality
  */ 

  function initialize(
      uint256 ETHPrice,
      uint256 reserveFloor,
      uint256 reserveStart, 
      uint256 reserveCeiling,
      uint256 crowdsaleAllocation
    ) external returns (bool); 

  /*** Crowdsale Stage functions ***/

  /**
  * Public Account Functionality
  */
  // function to participate in the crowdsale by contributing ETH, limit represent the TBN per ETH limit a user would like to enforce (0 means no limit set, free participation)
  function participate(uint256 limit) external payable returns (bool);

  // function to claim TBN from previous specific intervals of participation
  function claim(uint256 interval) external;

  // function to claim TBN from all previous un-claimed intervals of participation
  function claimAll() external returns (bool);

  /** 
  * Manager Role Functionality
  */
  // function to set a new ETH price for the crowdsale depending on the open market price (will auto-adjust the ETHprice, the reservePrice, and the ETHReserveAmount in the next interval)
  function setRebase(uint256 newETHPrice) external returns (bool);

  // function to reveal the hidden hard cap if/when it is reached (45 days guaranteed)
  function revealCap(uint256 cap, uint256 secret) external returns (bool); 

  /**
  * Fundkeeper Role Functionality
  */
  // function to gather any ETH funds from the crowdsale to the Fundkeeper Account
  function collect() external returns (bool);
  
  /**
   * Whitelister Role Functionality
  */
  // funciton to add to whitelist participants to claim during Crowdsale
  function addToWhitelist(address[] _participant_addresses) external;
  
  // funciton to remove whitelist participants to claim during Crowdsale
  function removeFromWhitelist(address[] _participant_addresses) external;

    
  /*** CrowdsaleEnded Stage functions ***/

  /** 
  * Recoverer Role Functionality
  */ 
  // function to recover ERC20 tokens (if TBN ERC20, must occur in the CrowdsaleEnded Stage)
  function recoverTokens(IERC20 token) external returns (bool);

  event Participated (uint256 interval, address account, uint256 amount);
  event Claimed (uint256 interval, address account, uint256 amount);
  event Collected (address collector, uint256 amount);
  event Rebased(uint256 newETHPrice, uint256 newETHReservePrice, uint256 newETHReserveAmount);
  event TokensRecovered(IERC20 token, uint256 recovered);
}
contract ManagerRole {
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private managers;

    constructor() internal {
        _addManager(msg.sender);
    }

    modifier onlyManager() {
        require(isManager(msg.sender), "msg.sender does not have the manager role");
        _;
    }

    function isManager(address account) public view returns (bool) {
        return managers.has(account);
    }

    function addManager(address account) public onlyManager {
        _addManager(account);
    }

    function renounceManager() public {
        _removeManager(msg.sender);
    }

    function _addManager(address account) internal {
        managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(address account) internal {
        managers.remove(account);
        emit ManagerRemoved(account);
    }
}
contract RecoverRole {
    using Roles for Roles.Role;

    event RecovererAdded(address indexed account);
    event RecovererRemoved(address indexed account);

    Roles.Role private recoverers;

    constructor() internal {
        _addRecoverer(msg.sender);
    }

    modifier onlyRecoverer() {
        require(isRecoverer(msg.sender), "msg.sender does not have the recoverer role");
        _;
    }

    function isRecoverer(address account) public view returns (bool) {
        return recoverers.has(account);
    }

    function addRecoverer(address account) public onlyRecoverer {
        _addRecoverer(account);
    }

    function renounceRecoverer() public {
        _removeRecoverer(msg.sender);
    }

    function _addRecoverer(address account) internal {
        recoverers.add(account);
        emit RecovererAdded(account);
    }

    function _removeRecoverer(address account) internal {
        recoverers.remove(account);
        emit RecovererRemoved(account);
    }
}
contract WhitelisterRole {
    using Roles for Roles.Role;

    event WhitelisterAdded(address indexed account);
    event WhitelisterRemoved(address indexed account);

    Roles.Role private _whitelisters;

    constructor () internal {
        _addWhitelister(msg.sender);
    }

    modifier onlyWhitelister() {
        require(isWhitelister(msg.sender));
        _;
    }

    function isWhitelister(address account) public view returns (bool) {
        return _whitelisters.has(account);
    }

    function addWhitelister(address account) public onlyWhitelister {
        _addWhitelister(account);
    }

    function renounceWhitelister() public {
        _removeWhitelister(msg.sender);
    }

    function _addWhitelister(address account) internal {
        _whitelisters.add(account);
        emit WhitelisterAdded(account);
    }

    function _removeWhitelister(address account) internal {
        _whitelisters.remove(account);
        emit WhitelisterRemoved(account);
    }
}
contract TBNCrowdSale is ICrowdsale, ManagerRole, RecoverRole, FundkeeperRole, WhitelisterRole {
    using SafeMath for uint256;
    
    /*
     *  Storage
     */
    struct Interval {
        uint256 reservePrice;  // the reservePrice in ETH for this interval @ 18 decimals of precision
        uint256 ETHReserveAmount;   // the reserve amount of ETH for this interval @ 18 decimals of precision
    }

    mapping (uint256 => Interval) public intervals;

    IERC20 private _erc20;                          // the TBN ERC20 token deployment
    
    uint256 private _guaranteedIntervals;           // number of guaranteed intervals before the sale can end early (set as 47)
    uint256 private _numberOfIntervals;             // number of intervals in the sale (188)
    bytes32 private _hiddenCap;                     // a hash of <the hidden hard cap(in WEI)>+<a secret number> to be revealed if/when the hard cap is reached - does not rebase so choose wisely

                                                    // Note: 18 decimal precision accomodates ETH prices up to 10**5
    uint256 private _ETHPrice;                      // ETH price in USD with 18 decimal precision for calculating reserve pricing
    uint256 private _reserveFloor;                  // the minimum possible reserve price in USD @ 18 decimal precision (set @ 0.0975 USD)
    uint256 private _reserveCeiling;                // the maximum possible reserve price in USD @ 18 decimal precision (set @ 0.15 USD)
    uint256 private _reserveStep;                   // the base amount to step down the price if reserve is not met @ 18 decimals of precision (0.15-.0975/188 = .0000279255)

    uint256 private _crowdsaleAllocation;           // total amount of TBN allocated to the crowdsale contract for distribution
    uint256 private _distributedTotal;              // total amount of TBN to be distributed (this will be fixed at CrowdsaleEnded, running total until then)
    uint256 private _totalContributions;            // total amount of ETH contributed for the whole sale period

    uint256 private WEI_FACTOR = 10**18;            // ETH base in WEI

    uint256 private _rebaseNewPrice;                // holds the rebase ETH price until rebasing occurs in the next active interval @ decimal 18
    uint256 private _rebased;                       // the interval setRebase was called, _rebase() will occur in the next interval
    
    uint256 private _lastAdjustedInterval;          // the most recent reserve adjusted interval

    bool private _recoverySafety;                           // a flag to be sure it is safe to recover TBN tokens

    uint256 public startBlock;                      // block number of the start of interval 0
    uint256 public endBlock;                        // block number of the last block of the last interval
    uint256 public endInterval;                     // the interval number when the Crowdfund stage was ended
    uint256 public INTERVAL_BLOCKS = 80;          // number of block per interval - 23 hours @ 15 sec per block

    uint256 public tokensPerInterval;               // number of tokens available for distribution each interval
    
    mapping (uint256 => uint256) public intervalTotals; // total ETH contributed per interval

    mapping (uint256 => mapping (address => uint256)) public participationAmount;
    mapping (uint256 => mapping (address => bool)) public claimed;
    mapping (address => bool) public whitelist;
    
    Stages public stages;

    /*
     *  Enums
     */
    enum Stages {
        CrowdsaleDeployed,
        Crowdsale,
        CrowdsaleEnded
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        require(stages == _stage, "functionality not allowed at current stage");
        _;
    }

    modifier onlyWhitelisted(address _participant) {
        require(whitelist[_participant] == true, "account is not white listed");
        _;
    }

    // update reserve adjustment and execute rebasing if ETH price was rebased last interval
    // also checks for end of sale endBlock condition and accounts for if the sale has been ended early or via reaching the endblock (then does final adjust and distribution calculations)
    modifier update() {
        uint256 interval = getInterval(block.number);
        if(endInterval == 0) {
            if (block.number > endBlock) { // check for sale end, endBlock condition
                interval = _numberOfIntervals.add(1);
                if (uint(stages) < 2) {
                    stages = Stages.CrowdsaleEnded;
                    endInterval = _numberOfIntervals.add(1);
                }
            }
        } else {
            interval = endInterval;
        }

        if(_lastAdjustedInterval != interval){ // check that the current interval is reserve adjusted
            for (uint i = _lastAdjustedInterval.add(1); i <= interval; i++) { // if current not adjusted, catch up adjustment until current interval
                _adjustReserve(i); // adjust the dynamic reserve price
                _addDistribution(i); // sum of total sale distribution
            }
            if(endInterval != 0 && _recoverySafety != true) { // need to ensure that update() has been called at least once after endInterval has been set (to guarantee the accuracy of _distributedTotal)
                _recoverySafety = true;
            }
            _lastAdjustedInterval = interval;
        }

        // we can rebase only if reserve ETH ajdustment is current (done above)
        if( interval > 1 && _rebased == interval.sub(1)){ // check if the ETH price was set for rebasing last interval
            _rebase(_rebaseNewPrice);
            _;
        } else {
            _;
        }
    }

    /**
    * @dev Constructor
    * @param token TBNERC20 token contract
    * @param numberOfIntervals the total number of 23 hr intervals run the crowdsale (set as 188)
    * @param guaranteedIntervals the number of guaranteed intervals before the sale can end eraly (set as 47)
    * @param hiddenCap a keccak256 hash string of the hardcap number of ETH (in WEI) and a secret number to be revealed if this hidden hard cap is reached
    */
    constructor(
        IERC20 token,
        uint256 numberOfIntervals,
        uint256 guaranteedIntervals,
        bytes32 hiddenCap    
    ) public {
        require(address(token) != 0x0, "token address cannot be 0x0");
        require(guaranteedIntervals > 0, "guaranteedIntervals must be larger than zero");
        require(numberOfIntervals > guaranteedIntervals, "numberOfIntervals must be larger than guaranteedIntervals");

        _erc20 = token;
        _numberOfIntervals = numberOfIntervals;
        _guaranteedIntervals = guaranteedIntervals;
        _hiddenCap = hiddenCap;

        stages = Stages.CrowdsaleDeployed;
    }

    /**
    * @dev Fallback auto participates with any ETH payment, with guarantee set to 0 (this means no TBN per ETH restrictions)
    */
    function () external payable {
        participate(0);
    }

    /**
    * @dev Safety function for recovering missent ERC20 tokens (and recovering the un-distributed allocation after CrowdsaleEnded)
    * @param token address of the ERC20 contract to recover
    */
    function recoverTokens(IERC20 token) 
        external 
        onlyRecoverer 
        returns (bool) 
    {
        uint256 recover;
        if (token == _erc20){
            require(uint(stages) >= 2, "if recovering TBN, must have progressed to CrowdsaleEnded");
            require(_recoverySafety, "update() needs to run at least once since the sale has ended");
            recover = token.balanceOf(address(this)).sub(_distributedTotal);
        } else {
            recover = token.balanceOf(address(this));
        }

        token.transfer(msg.sender, recover);
        emit TokensRecovered(token, recover);
        return true;
    }

   /*
     *  Getters
     */


    /**
    * @dev Gets the interval based on the blockNumber given
    * @param blockNumber The block.number to check the interval of
    * @return An uint256 representing the interval number
    */
    function getInterval(uint256 blockNumber) public view returns (uint256) {
        return _intervalFor(blockNumber);
    }

    /**
    * @dev Gets the TBN ERC20 deployment linked to this contract
    * @return The address of the deployed TBN ERC20 contract
    */
    function getERC20() public view returns (address) {
        return address(_erc20);
    }

    /**
    * @dev Gets the current total number of TBN distributed based on the contributions minus any tokens already claimed
    * @return The running total of distributed TBN
    */
    function getDistributedTotal() public view returns (uint256) {
        return _distributedTotal;
    }

    function currentStage() public view returns(uint256) {
        return uint256(stages);
    }

    /**
    * @dev public function for anyone to participate in a given interval
    * @param guarantee The minimum number of TBN per ETH contribution ratio the participant is willing to make this call at
    *    Note: a non-zero guarantee allows the participant to set a guaranteed minimum number of TBN per ETH for participation
    *    e.g., guarantee = 1000, guarantees that if the current rewarded TBN per 1 ETH is less than 1000, the call will fail
    * @return True if successful
    */
    function participate(uint256 guarantee) 
        public 
        payable 
        atStage(Stages.Crowdsale) 
        update()
        onlyWhitelisted(msg.sender) 
        returns (bool) 
    {
        uint256 interval = getInterval(block.number);
        require(interval <= _numberOfIntervals, "interval of current block number must be less than or equal to the number of intervals");
        require(msg.value >= .01 ether, "minimum participation amount is .01 ETH");

        participationAmount[interval][msg.sender] = participationAmount[interval][msg.sender].add(msg.value);
        intervalTotals[interval] = intervalTotals[interval].add(msg.value);
        _totalContributions = _totalContributions.add(msg.value);

        if (guarantee != 0) {
            uint256 TBNperETH;
            if(intervalTotals[interval] >= intervals[interval].ETHReserveAmount) {
                TBNperETH = (tokensPerInterval.mul(WEI_FACTOR)).div(intervalTotals[interval]); // WEI_FACTOR for 18 decimal precision
            } else {
                TBNperETH = (WEI_FACTOR.mul(WEI_FACTOR)).div(intervals[interval].reservePrice); // 1st WEI_FACTOR represents 1 ETH, second WEI_FACTOR is for 18 decimal precision
            }
            require(TBNperETH >= guarantee, "the number TBN per ETH is less than your expected guaranteed number of TBN");
        }

        emit Participated(interval, msg.sender, msg.value);

        return true;
    }


    /**
    * @dev public function for anyone to claim TBN from past interval participations
    * @param interval The interval to claim from
    */
    function claim(uint256 interval) 
        public 
        update()
    {
        require(uint(stages) >= 1, "must be in the Crowdsale or later stage to claim");
        require(getInterval(block.number) > interval, "the given interval must be less than the current interval");
        
        if (claimed[interval][msg.sender] || intervalTotals[interval] == 0) {
            return;
        }

        uint256 intervalClaim;
        uint256 contributorProportion = participationAmount[interval][msg.sender].mul(WEI_FACTOR).div(intervalTotals[interval]);
        uint256 reserveMultiplier;
        if (intervalTotals[interval] >= intervals[interval].ETHReserveAmount){
            reserveMultiplier = WEI_FACTOR;
        } else {
            reserveMultiplier = intervalTotals[interval].mul(WEI_FACTOR).div(intervals[interval].ETHReserveAmount);
        }

        intervalClaim = tokensPerInterval.mul(contributorProportion).mul(reserveMultiplier).div(10**36);
        _distributedTotal = _distributedTotal.sub(intervalClaim);
        claimed[interval][msg.sender] = true;
        _erc20.transfer(msg.sender, intervalClaim);

        emit Claimed(interval, msg.sender, intervalClaim);
    }

    /**
    * @dev public function to claim all interval unclaimed so far
    * @return True is successfull
    */
    function claimAll() 
        public
        returns (bool) 
    {
        for (uint i = 0; i < getInterval(block.number); i++) {
            claim(i);
        }
        return true;
    }

     ///  @dev Function to whitelist participants during the crowdsale
    ///  @param _participant_addresses Array of addresses to whitelist
    function addToWhitelist(address[] _participant_addresses) external onlyWhitelister {
        for (uint32 i = 0; i < _participant_addresses.length; i++) {
            if(_participant_addresses[i] != address(0) && whitelist[_participant_addresses[i]] == false){
                whitelist[_participant_addresses[i]] = true;
            }
        }
    }

    ///  @dev Function to remove the whitelististed participants
    ///  @param _participant_addresses is an array of accounts to remove form the whitelist
    function removeFromWhitelist(address[] _participant_addresses) external onlyWhitelister {
        for (uint32 i = 0; i < _participant_addresses.length; i++) {
            if(_participant_addresses[i] != address(0) && whitelist[_participant_addresses[i]] == true){
                whitelist[_participant_addresses[i]] = false;
            }
        }
    }

    /**
    * @dev Crowdsale Manager Role can assign the crowdsale token allocation to this contract. Note: TBN token fundkeeper must give this contract an allowance before calling intialize
    *      Also sets the initial ETH Price, reserve price floor, and reserve price ceiling; all in USD with 18 decimal precision
    * @param ETHPrice the intital price of ETH in USD
    * @param reserveFloor the minimum reserve price per TBN (in USD)
    * @param reserveCeiling the maximum reserve price per TBN (in USD)
    * @param crowdsaleAllocation the amount of tokens assigned to this contract for Crowdsale distribution upon initialization
    * @return True if successful
    */
    function initialize(
        uint256 ETHPrice,
        uint256 reserveFloor,
        uint256 reserveStart, 
        uint256 reserveCeiling,
        uint256 crowdsaleAllocation
    ) 
        external 
        onlyManager 
        atStage(Stages.CrowdsaleDeployed) 
        returns (bool) 
    {
        require(ETHPrice > reserveCeiling, "ETH basis price must be greater than the reserve ceiling"); 
        require(reserveFloor > 0, "the reserve floor must be greater than 0");
        require(reserveCeiling > reserveFloor.add(_numberOfIntervals), "the reserve ceiling must be _numberOfIntervals WEI greater than the reserve floor");
        require(reserveStart >= reserveFloor, "the reserve start price must be greater than the reserve floor");
        require(reserveStart <= reserveCeiling, "the reserve start price must be less than the reserve ceiling");
        require(crowdsaleAllocation > 0, "crowdsale allocation must be assigned a number greater than 0");
        
        address fundkeeper = _erc20.fundkeeper();
        require(_erc20.allowance(address(fundkeeper), address(this)) == crowdsaleAllocation, "crowdsale allocation must be equal to the amount of tokens approved for this contract");

        // set intital variables
        _ETHPrice = ETHPrice;
        _rebaseNewPrice = ETHPrice;
        _crowdsaleAllocation = crowdsaleAllocation;
        _reserveFloor = reserveFloor;
        _reserveCeiling = reserveCeiling;
        _reserveStep = (_reserveCeiling.sub(_reserveFloor)).div(_numberOfIntervals);
        startBlock = block.number;
        
        tokensPerInterval = crowdsaleAllocation.div(_numberOfIntervals);

        // calc initial intervalReserve
        uint256 interval = getInterval(block.number);
        intervals[interval].reservePrice = (reserveStart.mul(WEI_FACTOR)).div(_ETHPrice);
        intervals[interval].ETHReserveAmount = tokensPerInterval.mul(intervals[interval].reservePrice).div(WEI_FACTOR);

        // place crowdsale allocation in this contract
        _erc20.transferFrom(fundkeeper, address(this), crowdsaleAllocation);

        // create calculated initial variables
        endBlock = startBlock.add(INTERVAL_BLOCKS.mul(_numberOfIntervals));
       
        stages = Stages.Crowdsale;

        return true;
    }

    /**
    * @dev Crowdsale Manager Role can rebase the ETH price to accurately reflect the open market
    *      Note: this rebase will occur in this following interval from when this function is called and only on rebase can occur in an interval
    *            Rebasing can occur as many times as necessary in the previous interval before updating occurs 
    * @param newETHPrice the intital price of ETH in USD
    * @return True if successful
    */
    function setRebase(uint256 newETHPrice) 
        external 
        onlyManager 
        atStage(Stages.Crowdsale) 
        returns (bool) 
    {
        require(newETHPrice > _reserveCeiling, "ETH price cannot be set smaller than the reserve ceiling");
        uint256 interval = getInterval(block.number);
        require(block.number <= endBlock, "cannot rebase after the crowdsale period is over");
        require(interval > 0, "cannot rebase in the initial interval");
        _rebaseNewPrice = newETHPrice;
        _rebased = interval;
        return true;
    }

    /**
    * @dev Crowdsale Manager Role can reveal the hidden hard cap (and end sale early - but only enacted after 45 days as per our policy)
    * @param cap the hidden hard cap - number of ETH (in WEI)
    * @param secret an additional secret uint256 to prevent people from guessing the hidden cap
    * @return True if successful
    */
    function revealCap(uint256 cap, uint256 secret) 
        external 
        onlyManager 
        atStage(Stages.Crowdsale) 
        returns (bool) 
    {
        require(block.number >= startBlock.add(INTERVAL_BLOCKS.mul(_guaranteedIntervals)), "cannot reveal hidden cap until after the guaranteed period");
        uint256 interval = getInterval(block.number);
        bytes32 hashed = keccak256(abi.encode(cap, secret));
        if (hashed == _hiddenCap) {
            require(cap <= _totalContributions, "revealed cap must be under the total contribution");
            stages = Stages.CrowdsaleEnded;
            endInterval = interval;
            return true;
        }
        return false;
    }

    /**
    * @dev Crowdsale Fundkeeper Role can collect ETH any number of times
    * @return True if successful
    */
    function collect() 
        external 
        onlyFundkeeper 
        returns (bool) 
    {
        msg.sender.transfer(address(this).balance);
        emit Collected(msg.sender, address(this).balance);
    }

    /**
    * @dev Crowdsale Manager Role can rebase the ETH price to accurately reflect the open market (internal function)
    * @param newETHPrice the intital price of ETH in USD
    */
    function _rebase(uint256 newETHPrice) 
        internal 
        atStage(Stages.Crowdsale) 
    {
        uint256 interval = getInterval(block.number);
        
        // get old price
        uint256 oldPrice = (intervals[interval].reservePrice.mul(_ETHPrice)).div(WEI_FACTOR);
        
        // new ETH base price
        _ETHPrice = newETHPrice;

        // recalc ETH reserve Price
        intervals[interval].reservePrice = (oldPrice.mul(WEI_FACTOR)).div(_ETHPrice);
        // recalc ETH reserve Amount
        intervals[interval].ETHReserveAmount = tokensPerInterval.mul(intervals[interval].reservePrice).div(WEI_FACTOR);

        // reset _rebaseNewPrice to 0
        _rebaseNewPrice = 0;
        // reset _rebased to 0
        _rebased = 0;

        emit Rebased(
            _ETHPrice,
            intervals[interval].reservePrice,
            intervals[interval].ETHReserveAmount
        );
    } 

    /**
    * @dev Gets the interval based on the blockNumber given (internal function)
    *      Note: Each window is 23 hours long so that end-of-window rotates around the clock for all timezones
    * @param blockNumber The block.number to check the interval of
    * @return An uint256 representing the interval number
    */
    function _intervalFor(uint256 blockNumber) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 interval;
        if(blockNumber <= startBlock) {
            interval = 0;
        }else if(blockNumber <= endBlock) {
            interval = blockNumber.sub(startBlock).div(INTERVAL_BLOCKS);
        } else {
            interval = ((endBlock.sub(startBlock)).div(INTERVAL_BLOCKS)).add(1);
        }

        return interval;
    }

    /**
    * @dev Adjusts the dynamic reserve price and therefore the new expected reserve amount (both in ETH) for this interval depending on the contribution results of the previous interval (internal function)
    * @param interval the interval to do the adjustment for
    */
    function _adjustReserve(uint256 interval) internal {
        require(interval > 0, "cannot adjust the intial interval reserve");
        // get last reserve info
        uint256 lastReserveAmount = intervals[interval.sub(1)].ETHReserveAmount; // reserve amount of ETH expected last round
        uint256 lastUSDPrice = (intervals[interval.sub(1)].reservePrice.mul(_ETHPrice)).div(WEI_FACTOR); // the calculated price per TBN in USD from the last round

        uint256 ratio; // % in 18 decimal precision to see what ratio the contribution and target reserve are apart
        uint256 multiplier; //  a mltiplier to increase the number of steps to adjust depending on the size of the ratio

        uint256 newUSDPrice;

        // adjust reservePrice accordingly, the further away from the target reserve contribution was, the more steps the reerve price will be adjusted
        if (intervalTotals[interval.sub(1)] > lastReserveAmount) { // check if last reserve was exceeded
            ratio = (lastReserveAmount.mul(WEI_FACTOR)).div(intervalTotals[interval.sub(1)]);
            if(ratio <= 33*10**16){ // if lastReserveAmount is 33% or less of the last contributed amount step up * 3
                multiplier = 3;
            } else if (ratio <= 66*10**16){ // if lastReserveAmount is between 33%+ or 66% of the last contributed amount step up * 2
                multiplier = 2;
            } else { // if lastReserveAmount is larger than 66%+ upto 100% of the contributed amount
                multiplier = 1;
            }

            newUSDPrice = lastUSDPrice.add(_reserveStep.mul(multiplier)); // the new USD price will be the last interval USD price plus the reserve step times the multiplier
            
            if (newUSDPrice >= _reserveCeiling) { // new price is greater than or equal to the ceiling reserve
                intervals[interval].reservePrice = (_reserveCeiling.mul(WEI_FACTOR)).div(_ETHPrice); // set to ceiling reserve (capped)
            } else { // new price is less than the ceiling reserve
                intervals[interval].reservePrice = (newUSDPrice.mul(WEI_FACTOR)).div(_ETHPrice); // set new reserve price
            }

        } else if (intervalTotals[interval.sub(1)] < lastReserveAmount) { // last reserve was not met
            ratio = (intervalTotals[interval.sub(1)].mul(WEI_FACTOR)).div(lastReserveAmount);
            if(ratio <= 33*10**16){ // the last contributed amount is 33% or less of lastReserveAmount, step down * 3
                multiplier = 3;
            } else if (ratio <= 66*10**16){ // the last contributed amount is between 33%+ and 66% of lastReserveAmount, step down * 2
                multiplier = 2;
            } else { // the last contributed amount is greater than 66%+ of lastReserveAmount, step down * 1
                multiplier = 1;
            }

            newUSDPrice = lastUSDPrice.sub(_reserveStep.mul(multiplier)); // the new USD price will be the last interval USD price minus the reserve step times the multiplier
            
            if (newUSDPrice <= _reserveFloor) { // new price is less than or equal to the floor reserve
                intervals[interval].reservePrice = (_reserveFloor.mul(WEI_FACTOR)).div(_ETHPrice); // set to floor reserve (bottomed)
            } else { // new price is greater than the floor reserve
                intervals[interval].reservePrice = (newUSDPrice.mul(WEI_FACTOR)).div(_ETHPrice); // set new reserve price
            }
        } else { // intervalTotals[interval.sub(1)] == lastReserveAmount, last reserve met exactly
            intervals[interval].reservePrice = intervals[interval.sub(1)].reservePrice; // reserve Amount met exactly, no change in price
        }
        // calculate ETHReserveAmount based on the new reserve price
        intervals[interval].ETHReserveAmount = tokensPerInterval.mul(intervals[interval].reservePrice).div(WEI_FACTOR);
                            
    }

    /**
    * @dev Adds this interval&#39;s distributed tokens to the _distributedTotal storage variable to track the total number of TBN tokens to be distributed
    * @param interval the interval to do the calculation for
    */
    function _addDistribution(uint256 interval) internal {
        uint256 reserveMultiplier;

        if (intervalTotals[interval.sub(1)] >= intervals[interval.sub(1)].ETHReserveAmount){
            reserveMultiplier = WEI_FACTOR;
        } else {
            reserveMultiplier = intervalTotals[interval.sub(1)].mul(WEI_FACTOR).div(intervals[interval.sub(1)].ETHReserveAmount);
        }
        uint256 intervalDistribution = (tokensPerInterval.mul(reserveMultiplier)).div(WEI_FACTOR);

        _distributedTotal = _distributedTotal.add(intervalDistribution);
    }
}