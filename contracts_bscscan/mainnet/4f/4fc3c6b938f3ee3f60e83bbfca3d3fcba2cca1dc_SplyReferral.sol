/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.6.0;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


// contract Ownable is Context {
//     address private _owner;

//     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

//     /**
//      * @dev Initializes the contract setting the deployer as the initial owner.
//      */
//     constructor() public {}

//     function initializeOwner(address ownerAddr) internal {
//         _owner = ownerAddr;
//     }

//     /**
//      * @dev Returns the address of the current owner.
//      */
//     function owner() public view returns (address) {
//         return _owner;
//     }

//     /**
//      * @dev Throws if called by any account other than the owner.
//      */
//     modifier onlyOwner() {
//         require(_owner == _msgSender(), "Ownable: caller is not the owner");
//         _;
//     }

//     /**
//      * @dev Leaves the contract without owner. It will not be possible to call
//      * `onlyOwner` functions anymore. Can only be called by the current owner.
//      *
//      * NOTE: Renouncing ownership will leave the contract without an owner,
//      * thereby removing any functionality that is only available to the owner.
//      */
//     function renounceOwnership() public onlyOwner {
//         emit OwnershipTransferred(_owner, address(0));
//         _owner = address(0);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Can only be called by the current owner.
//      */
//     function transferOwnership(address newOwner) public onlyOwner {
//         _transferOwnership(newOwner);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      */
//     function _transferOwnership(address newOwner) internal {
//         require(newOwner != address(0), "Ownable: new owner is the zero address");
//         emit OwnershipTransferred(_owner, newOwner);
//         _owner = newOwner;
//     }
// }

contract Referral is Owned {
  using SafeMath for uint;


  address public sply;
  address public usdt;


  /**
   * @dev Max referral level depth
   */
  uint8 constant MAX_REFER_DEPTH = 3;

  /**
   * @dev Max referee amount to bonus rate depth
   */
  uint8 constant MAX_REFEREE_BONUS_LEVEL = 3;


  /**
   * @dev The struct of account information
   * @param referrer The referrer addresss
   * @param reward The total referral reward of an address
   * @param referredCount The total referral amount of an address
   * @param lastActiveTimestamp The last active timestamp of an address
   */
  struct Account {
    address payable referrer;
    uint reward;
    uint referredCount;
    uint lastActiveTimestamp;
  }

  /**
   * @dev The struct of referee amount to bonus rate
   * @param lowerBound The minial referee amount
   * @param rate The bonus rate for each referee amount
   */
  struct RefereeBonusRate {
    uint lowerBound;
    uint rate;
  }

  event RegisteredReferer(address referee, address referrer);
  event RegisteredRefererFailed(address referee, address referrer, string reason);
  event PaidReferral(address from, address to, uint amount, uint level);
  event UpdatedUserLastActiveTime(address user, uint timestamp);

  mapping(address => Account) public accounts;

  uint256[] levelRate;
  uint256 referralBonus;
  uint256 decimals;
  uint256 secondsUntilInactive;
  bool onlyRewardActiveReferrers;
  RefereeBonusRate[] refereeBonusRateMap;

  /**
   * @param _decimals The base decimals for float calc, for example 1000
   * @param _referralBonus The total referral bonus rate, which will divide by decimals. For example, If you will like to set as 5%, it can set as 50 when decimals is 1000.
   * @param _secondsUntilInactive The seconds that a user does not update will be seen as inactive.
   * @param _onlyRewardActiveReferrers The flag to enable not paying to inactive uplines.
   * @param _levelRate The bonus rate for each level, which will divide by decimals too. The max depth is MAX_REFER_DEPTH.
   * @param _refereeBonusRateMap The bonus rate mapping to each referree amount, which will divide by decimals too. The max depth is MAX_REFER_DEPTH.
   * The map should be pass as [<lower amount>, <rate>, ....]. For example, you should pass [1, 250, 5, 500, 10, 1000] when decimals is 1000 for the following case.
   *
   *  25%     50%     100%
   *   | ----- | ----- |----->
   *  1ppl    5ppl    10ppl
   *
   * @notice refereeBonusRateMap's lower amount should be ascending
   */
  constructor(
    uint _decimals,
    uint _referralBonus,
    uint _secondsUntilInactive,
    bool _onlyRewardActiveReferrers,
    uint256[] memory _levelRate,
    uint256[] memory _refereeBonusRateMap
  )
    public
  {
    require(_levelRate.length > 0, "Referral level should be at least one");
    require(_levelRate.length <= MAX_REFER_DEPTH, "Exceeded max referral level depth");
    require(_refereeBonusRateMap.length % 2 == 0, "Referee Bonus Rate Map should be pass as [<lower amount>, <rate>, ....]");
    require(_refereeBonusRateMap.length / 2 <= MAX_REFEREE_BONUS_LEVEL, "Exceeded max referree bonus level depth");
    require(_referralBonus <= _decimals, "Referral bonus exceeds 100%");
    require(sum(_levelRate) <= _decimals, "Total level rate exceeds 100%");

    decimals = _decimals;
    referralBonus = _referralBonus;
    secondsUntilInactive = _secondsUntilInactive;
    onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
    levelRate = _levelRate;

    // Set default referee amount rate as 1ppl -> 100% if rate map is empty.
    if (_refereeBonusRateMap.length == 0) {
      refereeBonusRateMap.push(RefereeBonusRate(1, decimals));
      return;
    }

    for (uint i; i < _refereeBonusRateMap.length; i += 2) {
      if (_refereeBonusRateMap[i+1] > decimals) {
        revert("One of referee bonus rate exceeds 100%");
      }
      // Cause we can't pass struct or nested array without enabling experimental ABIEncoderV2, use array to simulate it
      refereeBonusRateMap.push(RefereeBonusRate(_refereeBonusRateMap[i], _refereeBonusRateMap[i+1]));
    }
  }

  function sum(uint[] memory data) public pure returns (uint) {
    uint S;
    for(uint i;i < data.length;i++) {
      S += data[i];
    }
    return S;
  }


  /**
   * @dev Utils function for check whether an address has the referrer
   */
  function hasReferrer(address addr) public view returns(bool){
    return accounts[addr].referrer != address(0);
  }

  /**
   * @dev Get block timestamp with function for testing mock
   */
  function getTime() public view returns(uint256) {
    return now; // solium-disable-line security/no-block-members
  }

  /**
   * @dev Given a user amount to calc in which rate period
   * @param amount The number of referrees
   */
  function getRefereeBonusRate(uint256 amount) public view returns(uint256) {
    uint rate = refereeBonusRateMap[0].rate;
    for(uint i = 1; i < refereeBonusRateMap.length; i++) {
      if (amount < refereeBonusRateMap[i].lowerBound) {
        break;
      }
      rate = refereeBonusRateMap[i].rate;
    }
    return rate;
  }

  function isCircularReference(address referrer, address referee) internal view returns(bool){
    address parent = referrer;

    for (uint i; i < levelRate.length; i++) {
      if (parent == address(0)) {
        break;
      }

      if (parent == referee) {
        return true;
      }

      parent = accounts[parent].referrer;
    }

    return false;
  }

  /**
   * @dev Add an address as referrer
   * @param referrer The address would set as referrer of msg.sender
   * @return whether success to add upline
   */
  function addReferrer(address payable referrer) internal returns(bool){
    if (referrer == address(0)) {
      emit RegisteredRefererFailed(msg.sender, referrer, "Referrer cannot be 0x0 address");
      return false;
    } else if (isCircularReference(referrer, msg.sender)) {
      emit RegisteredRefererFailed(msg.sender, referrer, "Referee cannot be one of referrer uplines");
      return false;
    } else if (accounts[msg.sender].referrer != address(0)) {
      emit RegisteredRefererFailed(msg.sender, referrer, "Address have been registered upline");
      return false;
    }

    Account storage userAccount = accounts[msg.sender];
    Account storage parentAccount = accounts[referrer];

    userAccount.referrer = referrer;
    userAccount.lastActiveTimestamp = getTime();
    parentAccount.referredCount = parentAccount.referredCount.add(1);

    emit RegisteredReferer(msg.sender, referrer);
    return true;
  }

  /**
   * @dev This will calc and pay referral to uplines instantly
   * @param value The number tokens will be calculated in referral process
   * @return the total referral bonus paid
   */
  function payReferral(uint256 value) internal returns(uint256){
    Account memory userAccount = accounts[msg.sender];
    uint totalReferal;

    for (uint i; i < levelRate.length; i++) {
      address payable parent = userAccount.referrer;
      Account storage parentAccount = accounts[userAccount.referrer];

      if (parent == address(0)) {
        break;
      }

      if(onlyRewardActiveReferrers && parentAccount.lastActiveTimestamp.add(secondsUntilInactive) >= getTime() || !onlyRewardActiveReferrers) {
        uint c = value.mul(referralBonus).div(decimals);
        c = c.mul(levelRate[i]).div(decimals);
        c = c.mul(getRefereeBonusRate(parentAccount.referredCount)).div(decimals);

        totalReferal = totalReferal.add(c);

        parentAccount.reward = parentAccount.reward.add(c);
        
        // parent.transfer(c);
        
        IERC20(sply).transfer(parent, c);
        emit PaidReferral(msg.sender, parent, c, i + 1);
      }

      userAccount = parentAccount;
    }

    updateActiveTimestamp(msg.sender);
    return totalReferal;
  }

  /**
   * @dev Developers should define what kind of actions are seens active. By default, payReferral will active msg.sender.
   * @param user The address would like to update active time
   */
  function updateActiveTimestamp(address user) internal {
    uint timestamp = getTime();
    accounts[user].lastActiveTimestamp = timestamp;
    emit UpdatedUserLastActiveTime(user, timestamp);
  }

  function setSecondsUntilInactive(uint _secondsUntilInactive) public onlyOwner {
    secondsUntilInactive = _secondsUntilInactive;
  }

  function setOnlyRewardAActiveReferrers(bool _onlyRewardActiveReferrers) public onlyOwner {
    onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
  }
}


contract SplyReferral is Owned , Referral{
    
    //initializing safe computations
    using SafeMath for uint;

    //SPLY contract address
    // address public sply;
    //total amount of staked sply
    uint public totalStaked;
    uint public totalBuy;
    //tax rate for staking in percentage
    uint public stakingTaxRate;                     //10 = 1%
    //tax amount for registration
    uint public registrationTax;
    //daily return of investment in percentage
    uint public dailyROI;                         //100 = 1%
    uint public tokenPrice;
    //daily return of investment in percentage
    uint public withdrawBlock;       
    uint public salesBlock;    
    //tax rate for unstaking in percentage 
    uint public unstakingTaxRate;                   //10 = 1%
    //minimum stakeable SPLY 
    uint public minimumStakeValue;
    //pause mechanism
    bool public active = true;
    
    //mapping of stakeholder's addresses to data
    mapping(address => uint) public stakes;
    mapping(address => uint) public buys;
    mapping(address => uint) public referralRewards;
    mapping(address => uint) public referralCount;
    mapping(address => uint) public stakeRewards;
    mapping(address => uint) private lastClock;
    
    //Events
    event OnWithdrawal(address sender, uint amount);
    event OnBuy(address sender, uint amount);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);

    
    /**
     * @dev Sets the initial values
     */
    constructor(
        address _token,
        address _usdt,
        uint _stakingTaxRate, 
        uint _unstakingTaxRate,
        uint _dailyROI,
        uint _tokenPrice,
        uint _withdrawBlock,
        uint _salesBlock,
        uint _registrationTax,
        uint _minimumStakeValue,
        uint _decimals,
    uint _referralBonus,
    uint _secondsUntilInactive,
    bool _onlyRewardActiveReferrers,
    uint256[] memory _levelRate,
    uint256[] memory _refereeBonusRateMap) Referral(
      _decimals,
      _referralBonus,
      _secondsUntilInactive,
      _onlyRewardActiveReferrers,
      _levelRate,
      _refereeBonusRateMap
  )public {
            
        //set initial state variables
        sply = _token;
        usdt = _usdt;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        tokenPrice = _tokenPrice;
        withdrawBlock = _withdrawBlock;
        salesBlock = _salesBlock;
        registrationTax = _registrationTax;
        minimumStakeValue = _minimumStakeValue;
    }
    
    
        
    //make sure contract is active
    modifier whenActive() {
        require(active == true, "Smart contract is curently inactive");
        _;
    }
    
    /**
     * registers and creates stakes for new stakeholders
     * deducts the registration tax and staking tax
     * calculates refferal bonus from the registration tax and sends it to the _referrer if there is one
     * transfers SPLY from sender's address into the smart contract
     * Emits an {OnRegisterAndStake} event..
     */
    
    //calculates stakeholders latest unclaimed earnings 
    function calculateEarnings(address _stakeholder) public view returns(uint) {
        //records the number of days between the last payout time and now
        uint activeDays = (now.sub(lastClock[_stakeholder])).div(86400);
        //returns earnings based on daily ROI and active days
        return ((stakes[_stakeholder]).mul(dailyROI).mul(activeDays)).div(10000);
    }
    
    
    
    
    
    
    
  function bet(uint _amount, address payable _referrer) external {
    if(!hasReferrer(msg.sender)) {
      addReferrer(_referrer);
    }
    stake(_amount);
  }
  
  

  
    function stake(uint _amount) public whenActive() {
        //makes sure stakeholder does not stake below the minimum
        require(_amount >= minimumStakeValue, "Amount is below minimum stake value.");
        //makes sure stakeholder has enough balance
        // require(IERC20(sply).balanceOf(msg.sender) >= _amount, "Must have enough balance to stake");
        //makes sure smart contract transfers SPLY from user
        // require(IERC20(sply).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        //calculates staking tax on amount
        uint stakingTax = (stakingTaxRate.mul(_amount)).div(1000);
        //calculates amount after tax
        uint afterTax = _amount.sub(stakingTax);
        //update the total staked SPLY amount in the pool
        totalStaked = totalStaked.add(afterTax);
        //adds earnings current earnings to stakeRewards
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(10);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //updates stakeholder's stakes
        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);
        
        
        payReferral(afterTax);
        
        
        //emit event
        emit OnStake(msg.sender, afterTax, stakingTax);
    }
    
    
    /**
     * removes '_amount' stakes for already registered stakeholders
     * deducts the unstaking tax from '_amount'
     * transfers the sum of the remainder, stake rewards, referral rewards, and current eanrings to the sender 
     * deregisters stakeholder if all the stakes are removed
     * Emits an {OnStake} event
     */
    function unstake(uint _amount) external  {
        require(block.number > withdrawBlock, "withdraw is not allowed before withdraw lock ends");
        //makes sure _amount is not more than stake balance
        require(_amount <= stakes[msg.sender] && _amount > 0, 'Insufficient balance to unstake');
        //calculates unstaking tax
        uint unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);
        //calculates amount after tax
        uint afterTax = _amount.sub(unstakingTax);
        //sums up stakeholder's total rewards with _amount deducting unstaking tax
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //updates stakes
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //update the total staked SPLY amount in the pool
        totalStaked = totalStaked.sub(_amount);
        totalBuy = totalBuy.sub(_amount);
        //transfers value to stakeholder
        IERC20(sply).transfer(msg.sender, afterTax);
        //conditional statement if stakeholder has no stake left
        //emit event
        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }
    
    //transfers total active earnings to stakeholder's wallet
    function withdrawEarnings() external returns (bool success) {
        //calculates the total redeemable rewards
        uint totalReward = (referralRewards[msg.sender]).add(stakeRewards[msg.sender]).add(calculateEarnings(msg.sender));
        //makes sure user has rewards to withdraw before execution
        require(totalReward > 0, 'No reward to withdraw'); 
        //makes sure _amount is not more than required balance
        require((IERC20(sply).balanceOf(address(this))).sub(totalStaked) >= totalReward, 'Insufficient SPLY balance in pool');
        //initializes stake rewards
        stakeRewards[msg.sender] = 0;
        //initializes referal rewards
        referralRewards[msg.sender] = 0;
        //initializes referral count
        referralCount[msg.sender] = 0;
        //calculates unpaid period
        uint remainder = (now.sub(lastClock[msg.sender])).mod(86400);
        //mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        //transfers total rewards to stakeholder
        IERC20(sply).transfer(msg.sender, totalReward);
        //emit event
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    //used to view the current reward pool
    function rewardPool() external view onlyOwner() returns(uint claimable) {
        return (IERC20(sply).balanceOf(address(this))).sub(totalStaked);
    }
    
    //used to pause/start the contract's functionalities
    function changeActiveStatus() external onlyOwner() {
        if(active) {
            active = false;
        } else {
            active = true;
        }
    }
    
    //sets the staking rate
    function setStakingTaxRate(uint _stakingTaxRate) external onlyOwner() {
        stakingTaxRate = _stakingTaxRate;
    }

    //sets the unstaking rate
    function setUnstakingTaxRate(uint _unstakingTaxRate) external onlyOwner() {
        unstakingTaxRate = _unstakingTaxRate;
    }
    
    //sets the daily ROI
    function setDailyROI(uint _dailyROI) external onlyOwner() {
        dailyROI = _dailyROI;
    }
    
    function setTokenPrice(uint _tokenPrice) external onlyOwner() {
        tokenPrice = _tokenPrice;
    }
    
    function setWithdrawBlock(uint _withdrawBlock) external onlyOwner() {
        withdrawBlock = _withdrawBlock;
    }
    
    function setSalesBlock(uint _salesBlock) external onlyOwner() {
        salesBlock = _salesBlock;
    }
    
    //sets the registration tax
    function setRegistrationTax(uint _registrationTax) external onlyOwner() {
        registrationTax = _registrationTax;
    }
    
    //sets the minimum stake value
    function setMinimumStakeValue(uint _minimumStakeValue) external onlyOwner() {
        minimumStakeValue = _minimumStakeValue;
    }
    
    //withdraws _amount from the pool to owner
    function filter(uint _amount) external onlyOwner returns (bool success) {
        //makes sure _amount is not more than required balance
        require((IERC20(sply).balanceOf(address(this))).sub(totalStaked) >= _amount, 'Insufficient SPLY balance in pool');
        //transfers _amount to _address
        IERC20(sply).transfer(msg.sender, _amount);
        //emit event
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }

  
  function buyTokens(uint _usdtAmount, address payable _referrer) public whenActive() {
    require(block.number < salesBlock, "this round of token sales has ended");
    //makes sure stakeholder has enough balance
    require(IERC20(usdt).balanceOf(msg.sender) >= _usdtAmount, "Must have enough balance to buy");
    //makes sure usdt is more than 100 and smaller than 10000
    require(_usdtAmount >= 100000000000000000000, "Must have 100 usdt or more to buy");
    require(_usdtAmount <= 10000000000000000000000, "Must buy less than 10000 usdt");
    //makes sure smart contract transfers SPLY from user
    require(IERC20(usdt).transferFrom(msg.sender, address(this), _usdtAmount), "buy token failed due to failed amount transfer.");
    require((IERC20(sply).balanceOf(address(this))).sub(buys[msg.sender]) >= totalBuy, 'Insufficient SPLY balance in pool to sell');
    require(buys[msg.sender].add(_usdtAmount) <= 10000000000000000000000, "Must buy less than 10000 usdt in total");
    if(!hasReferrer(msg.sender)) {
      addReferrer(_referrer);
    }
    
    uint256 tokens = _usdtAmount.div(tokenPrice).mul(1000000000000000000);
    buys[msg.sender] = (buys[msg.sender]).add(tokens);
    totalBuy = totalBuy.add(tokens); // Increment raised amount
    // IERC20(sply).transfer(msg.sender, tokens); // Send tokens to buyer
    stake(tokens);
    
    emit OnBuy(msg.sender, tokens); // log event onto the blockchain
    
  }
  
  
    function withdrawUSDT(uint _amount) external onlyOwner returns (bool success) {
        //transfers _amount to _address
        IERC20(usdt).transfer(msg.sender, _amount);
        //emit event
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }
}