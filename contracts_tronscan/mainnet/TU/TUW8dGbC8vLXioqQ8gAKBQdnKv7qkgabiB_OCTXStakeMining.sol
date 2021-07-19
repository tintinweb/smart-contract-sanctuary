//SourceUnit: Context.sol

pragma solidity ^0.5.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SourceUnit: ITRC20.sol

pragma solidity ^0.5.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: Migrations copy.sol

pragma solidity >=0.4.23 <0.6.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}


//SourceUnit: Migrations.sol

pragma solidity >=0.4.23 <0.6.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}


//SourceUnit: OCTXStakeMining.sol

/*! OCTXStakeMining.sol | © 2021  OCTX FINANCE (ORACLETX) */

pragma solidity 0.5.10;

import "./SafeMath.sol";
import "./OCTXToken.sol";

contract OCTXStakeMining {
  using SafeMath for uint256;

  struct User {
    uint256 stakeAmount;
    uint256 octxReward;
    uint256 lastUpdateTime;
    uint256 lp_stakingBalance;
    uint256 lp_lastUpdate;
    uint256 lp_reward;
    address referral;
    uint256 refAddedAt;
    uint256 refReward;
    uint256 totalRefEarnings;
    uint256 priorProtocolRatio;
  }

  //System Infos
  address public devAddress;
  uint256 public constant DEV_FEE = 5;
  address payable public owner;
  address payable public protocolDist;  //distributor address of OCTX protocol rewards
  address public token_address; //OCTX token
  address public lpAddress; //LP Token
  uint256 public initialRate;
  uint256 public availableRewards; 
  uint256 public miningSystemEndTime; 
  uint256 public totalStaked;   //total trx staked in system
  uint256 public miningRewardRate; //a reward factor rate (mining rate)
  uint256 public miningLevel;

  //TRX - OCTX staking
  uint256 public priorAvailable;
  uint256 public lastSysTotalStakeCheck;
  uint256 public lastSysTimeCheck;

  //Time Logs
  uint256 public LAUNCH_TIME = 1602887400;  // oct 16 2020 plus 90 days 7776000 jan 16 2021
  uint256 public GENESIS_MINING_PERIOD = LAUNCH_TIME + 8985600; //   if launch on jan 16  ends after 14 days (209600)
  uint256 public bpTimeLog;

  //LP Reward System
  uint256 public lpStakingRewardRate;
  uint256 private announceTime;
  uint256 public nextLPRewardRate;

  uint256 public lp_availableRewards;
  uint256 public lpSystemEndTime;
  uint256 public lpTotalStaked;
  uint256 public lp_TotalUsersLPStake;

  uint256 public lp_priorAvailable;
  uint256 public lp_totalStakeCheck;
  uint256 public lp_lastTimeCheck;

  uint256 public lpProtocolExchangeRatio = 10000; //set to 4 point precision 
  uint256 public lpProtocolFee = 5;  // 0.5%
  uint256 public lpProtocolPool;

  mapping(address => User) public users;

  /**
   *@dev checks for new deposits into staking
   */
  event NewDeposit(address indexed addr, uint256 amount);

  /**
   *@dev checks for new withdrawals (unstaking)
   */
  event Unstaked(address indexed addr, uint256 amount);

  /**
   *@dev when rewards are claimed
   */
  event ClaimedOCTX(address indexed addr, uint256 amount);

  /**
   *@dev checks for owner change
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   *@dev automated notice for change in mining reward rate
   */
  event UpdateMiningRate(uint256 indexed miningLv, uint256 newRewardRate, uint256 time);

  /**
   *@dev checks staking of LP
   */
  event StakedLP(address indexed addr, uint256 amount);

  /**
   *@dev checks unstaking of LP
   */
  event UnstakeLP(address indexed addr, uint256 amount, uint256 protocolReward);

  /**
   *@dev checks claiming of LP rewards
   */
  event LPRewarded(address indexed addr, uint256 amount);

  /**
   *@dev logs dev fees
   */
  event DevFee(address indexed addr, address indexed staker, uint256 amount);

  /**
   *@dev checks on ref rewards
   */
  event RefReward(address indexed referrer, address indexed referree, uint256 refReward, string tier);

  /**
   *@dev checks when referral bonuses are claimed
   */
  event ReferralBonusClaimed(address indexed claimer, uint256 amount);

  /**
   *@dev notification on LP rate change
   */
  event AnnounceChangeToLPRate(address indexed dev, uint256 newRate);

  /**
   *@dev logs actual change on LP rate
   */
  event SetLPRate(uint256 indexed newLPRate, uint256 oldLPRate);

  /**
   *@dev logs referrals (referree & referr)
   */
  event AddedReferral(address indexed referee, address referredBy);

  /**
   *@dev logs any changes of referrals
   */
  event ChangedRef(address indexed referee, address referredBy);

  /**
   *@dev records distribution of protocol rewards
   */
  event ProtocolRewardsDistributed(address indexed distributor, uint256 amountOfProtocolReward);

  /**
   *@dev records setting of liquidity token address (use only by Dev, likely to only occur once)
   */
  event SetLPAddress(address indexed dev, address lpTokenAddr);

  /**
   *@dev logs individual rewards from protocol
   */
  event RewardedByProcotol(address indexed addr, uint256 priorRatio, uint256 newRatio);

  /**
  * @dev Throws if called by any account other than the dev.
  */
  modifier onlyDev() {
    require(devAddress == msg.sender, "Not the dev");
    _;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner, "Caller is not the owner");
    _;
  }

  constructor(address _tokenAddr, address payable _protocolDist) public {
    owner = msg.sender;
    protocolDist = _protocolDist;
    token_address = _tokenAddr; 
    devAddress = msg.sender;

    availableRewards = 17000000 * 10 ** 6;
    lp_availableRewards = 3000000 * 10 ** 6;

    miningRewardRate = 15000;  //set to genesis mining rate
    initialRate = 10000; //mining lv1 initial rate
    lpStakingRewardRate = 12000;
    bpTimeLog = GENESIS_MINING_PERIOD + 604800;
  }

  function updateDevAddress(address _devAddress) public onlyDev {
    devAddress = _devAddress;
  }

  function setLPTokenAddress(address _lpAddress) public onlyDev {
    lpAddress = _lpAddress;
    emit SetLPAddress(msg.sender, _lpAddress);
  }

  /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
  function transferOwnership(address payable newOwner) public onlyOwner {
      _transferOwnership(newOwner);
  }

  /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    */
  function _transferOwnership(address payable newOwner) internal {
      require(newOwner != address(0), "new owner is the zero address");
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
  }


  function stake() external payable {
    require(block.timestamp >= LAUNCH_TIME, "not yet started"); 

    require(msg.value >= 1e8, 'Miniumum stake amount of 100trx');
    User storage user = users[msg.sender];

    //Update user's OCTX reward amount
    if (user.lastUpdateTime == 0 || user.stakeAmount == 0) {
      user.lastUpdateTime = block.timestamp;
    }
    else {
      _updateOCTXReward();
    }

    //Update stake amount to reflect addition
    user.stakeAmount = user.stakeAmount.add(msg.value);

    //Update total system stake
    totalStaked = totalStaked.add(msg.value);

    //Update system availability
    _updateAvailability();

    emit NewDeposit(msg.sender, msg.value);

    _updateMiningRate();
  }

  function firstDeposit(address _ref) external payable {
    require(msg.value >= 1e8, 'Miniumum stake amount of 100trx');
    User storage user = users[msg.sender];

    if(user.lastUpdateTime == 0 && user.stakeAmount == 0 && _ref != address(0)) {
      user.referral = _ref;
      user.refAddedAt = block.timestamp;

      emit AddedReferral(msg.sender, _ref);
    }

    //Update user's OCTX reward amount
    if (user.lastUpdateTime == 0 || user.stakeAmount == 0) {
      user.lastUpdateTime = block.timestamp;
    }
    else {
      _updateOCTXReward();
    }

    //Update stake amount to reflect addition
    user.stakeAmount = user.stakeAmount.add(msg.value);

    //Update total system stake
    totalStaked = totalStaked.add(msg.value);

    //Update system availability
    _updateAvailability();

    emit NewDeposit(msg.sender, msg.value);

    _updateMiningRate();
  }

  function changeRef(address _referrer) external {
    require(block.timestamp >= users[msg.sender].refAddedAt + 2419200, "Requires a waiting period of 28 days before you are able to change");
    require(_referrer != msg.sender, "Cannot list yourself");
    
    users[msg.sender].referral = _referrer;
    users[msg.sender].refAddedAt = block.timestamp;

    emit ChangedRef(msg.sender, _referrer);
  } 

  function unfreeze() external {
    //timelock for 7 days (half) during the 14-day Genesis Mining
    require(block.timestamp >= LAUNCH_TIME + 604800, "7 Day Time Lock period on TRX Withdrawals during Genesis Mining");

    //totalStake is changed (lowered):  needs to update sys --> _updateAvailability
    User storage user = users[msg.sender];

    require(user.stakeAmount > 0, "Balance of Zero. No TRX were staked.");

    //update OCTX reward prior to unstaking
    _updateOCTXReward();

    uint256 amountBeingUnstaked = user.stakeAmount;
    uint256 devFee = user.stakeAmount.mul(2).div(100);
    uint256 protocolTake = user.stakeAmount.mul(3).div(100);  //protocol rewards to be distributed
    uint256 unfreezeAmount = user.stakeAmount.sub(devFee).sub(protocolTake);

    //Update total system stake (TRX)
    totalStaked = totalStaked.sub(user.stakeAmount);
    
    //Update stake amount to reflect removal
    user.stakeAmount = 0;

    //Update system availability
    _updateAvailability();

    /**
    *@dev currently sends to ProtocolDist to handle exchange and distribution process
    *will be changed to a contract address in the future to facilitate automation of process
    */
    protocolDist.transfer(protocolTake);

    owner.transfer(devFee);
    msg.sender.transfer(unfreezeAmount);

    emit Unstaked(msg.sender, amountBeingUnstaked);

    _updateMiningRate();
  } 

  function claimOCTX() external {
    //timelock for OCTX withdrawals for just the first 48 hours during the 14-day Genesis Mining Event
    require(block.timestamp >= LAUNCH_TIME + 172800, "48hour Time Lock on OCTX withdrawal during start of Genesis Mining");

    _updateOCTXReward(); 

    User storage user = users[msg.sender];
    uint256 rewardAmount = user.octxReward;

    user.octxReward = 0;
    
    if (rewardAmount > 0) {
      safeOCTXTransfer(owner, rewardAmount.mul(DEV_FEE).div(100));
      emit DevFee(owner, msg.sender, rewardAmount.mul(DEV_FEE).div(100));

      safeOCTXTransfer(msg.sender, rewardAmount);
      emit ClaimedOCTX(msg.sender, rewardAmount);
    }
    
    /**
    *@dev 2 Tier Referral Structure
    *
     */
    if(user.referral != address(0)) {
      //log 5% 1st tier referral reward
      users[user.referral].refReward = users[user.referral].refReward.add(rewardAmount.mul(5).div(100));
      availableRewards = availableRewards.sub(rewardAmount.mul(5).div(100));
      emit RefReward(user.referral, msg.sender, rewardAmount.mul(5).div(100), "Tier1");

      if (users[user.referral].referral != address(0)) {
        //log 1% 2nd tier referral reward
        address secondTier = users[user.referral].referral;
        users[secondTier].refReward = users[secondTier].refReward.add(rewardAmount.div(100));
        availableRewards = availableRewards.sub(rewardAmount.div(100));
        emit RefReward(secondTier, msg.sender, rewardAmount.div(100), "Tier2");
      }
    }

    _updateMiningRate();
  }


  /**
   *@dev Only Exception --
   * allow owner to bypass time lock during Genesis Mining to set up 
   * used to withdraw initial tokens to set up external market exchange 
   * initialize the liquidity provider protocol & rewards pool
   */
  function octxClaimOnlyOwner() external onlyOwner {
    _updateOCTXReward(); 

    User storage user = users[msg.sender];
    uint256 rewardAmount = user.octxReward;

    user.octxReward = 0;

    safeOCTXTransfer(msg.sender, rewardAmount);
    emit ClaimedOCTX(msg.sender, rewardAmount);
    
  }


  /**
   *@dev calculate reward based on stake time for OCTX mining at oracletx 
   *factors in a system timer to auto regulates final cutoff when mining completes
   */
  function _updateOCTXReward() internal {
    User storage user = users[msg.sender];

    if(user.stakeAmount > 0) {
      uint256 startTime = user.lastUpdateTime;
      uint256 stakingPeriod;

      if (block.timestamp > miningSystemEndTime) {
        stakingPeriod = miningSystemEndTime.sub(startTime); 
      }
      else {
        stakingPeriod = block.timestamp.sub(startTime); 
      }
      
      uint256 rewardAmount = user.stakeAmount.mul(miningRewardRate).mul(stakingPeriod).div(86400).div(1000000);

      user.octxReward = user.octxReward.add(rewardAmount);
      user.lastUpdateTime = block.timestamp;

    }
  }

  /**
   *@dev set a Mining Lv schedule for ORACLETX 
   *current rate is set to increase mining difficulty every 7 days
   *OCTX tokens will be more scarce to obtain
    */
  function _updateMiningRate() internal {
    if (block.timestamp > GENESIS_MINING_PERIOD && block.timestamp < GENESIS_MINING_PERIOD + 86400) {
      //Genesis Mining is over
      //set to initial Mining Lv1
      miningRewardRate = initialRate;
    }

    if (block.timestamp >= bpTimeLog && miningLevel < 53) {
      miningRewardRate = miningRewardRate.mul(9).div(10);
      bpTimeLog = bpTimeLog.add(604800);
      miningLevel = miningLevel.add(1);

      emit UpdateMiningRate(miningLevel, miningRewardRate, bpTimeLog);
    }
  }

  /**
   *@dev system protocol tracker for amount of rewards distributed
   *amount that is mined but yet to be unclaim
   *and amount of rewards available for mining
    */
  function _updateAvailability() internal {
    uint256 currentUnclaimedRewards = lastSysTotalStakeCheck.mul(miningRewardRate).mul(block.timestamp.sub(lastSysTimeCheck)).div(86400).div(1000000);

    /**
    *@dev calculates ending period of mining for full system 
    */
    if (currentUnclaimedRewards > availableRewards) {
      //Rewards are fully mined and distributed.
      //set availableRewards to zero
      availableRewards = 0;  
      miningLevel = 99;

      uint256 timeDifference = priorAvailable.mul(86400).mul(1000000).div(lastSysTotalStakeCheck).div(miningRewardRate);
      miningSystemEndTime = lastSysTimeCheck.add(timeDifference).sub(1); //
    }
    else {
      availableRewards = availableRewards.sub(currentUnclaimedRewards);

      priorAvailable = availableRewards;
      lastSysTimeCheck = block.timestamp;
      lastSysTotalStakeCheck = totalStaked; 

      //Way to initiate system timer
      uint256 addedTime = availableRewards.mul(86400).mul(1000000).div(totalStaked).div(miningRewardRate);
      miningSystemEndTime = block.timestamp.add(addedTime);
    }
  }

  /**
   *@dev claiming function process of the referral system by ORACLETX
   *
    */
  function claimReferralRewards() external {
    //Timelock on Referral Distribution for 4 days during Genesis Mining Event
    require(block.timestamp >= LAUNCH_TIME + 345600, "4-Day Time Lock on Referral Bonuses during Genesis Mining");

    User storage user = users[msg.sender];
    require(user.refReward > 0, "No referral rewards to claim");

    uint256 referrerRewards = user.refReward;
    safeOCTXTransfer(msg.sender, user.refReward);

    user.totalRefEarnings = user.totalRefEarnings.add(user.refReward);

    user.refReward = 0;

    emit ReferralBonusClaimed(msg.sender, referrerRewards);

  }

  function safeOCTXTransfer(address _to, uint256 _amount) internal {
    uint256 balance = OCTXToken(token_address).balanceOf(address(this));
    if (_amount > balance) {
        OCTXToken(token_address).transfer(_to, balance);
    } else {
        OCTXToken(token_address).transfer(_to, _amount);
    }
  }

  /**
   *@dev specify a certain amount of TRX to unfreeze (unstake)
   *process and update current rewards prior to release
   *fee are only taken on withdraws in order for users to get the most return
   *keep mining for the most rewards and best return
   **/
  function unfreezeAmountOf(uint256 _amount) external {
    //timelock for 7 days (half) during the 14-day Genesis Mining
    require(block.timestamp >= LAUNCH_TIME + 604800, "7 Day Time Lock period on TRX Withdrawals during Genesis Mining");

    User storage user = users[msg.sender];
    require(user.stakeAmount >= _amount, "Amount is greater than user staked balance.");
    require(_amount >= 1000000, "Amount must be at least 1 TRX");
    _updateOCTXReward();

    
    
    //Protocol fees consisting of 2% dev and 3% to protocol pool for wide distribution 
    uint256 devFee = _amount.mul(2).div(100);
    uint256 protocolTake = _amount.mul(3).div(100);
    uint256 unfreezeAmount = _amount.sub(devFee).sub(protocolTake);

    //Update total system stake (TRX)
    //Process update total system stake, removal, and availabity
    totalStaked = totalStaked.sub(_amount);
    user.stakeAmount = user.stakeAmount.sub(_amount);
    _updateAvailability();

    /**
    *@dev currently sends to Protocol Dist to handle exchange and distribution process
    *will be changed to a contract address in the future to facilitate automation of process
    */
    protocolDist.transfer(protocolTake);

    owner.transfer(devFee);
    msg.sender.transfer(unfreezeAmount);

    emit Unstaked(msg.sender, _amount);

    _updateMiningRate();
  } 

  /**
   *@dev display total standing rewards unclaimed by user
   *
   */
  function calcReward() public view returns(uint256) {
    uint256 startTime = users[msg.sender].lastUpdateTime;

    uint256 timeStaked = block.timestamp.sub(startTime);

    uint256 accrueReward = users[msg.sender].stakeAmount.mul(miningRewardRate).mul(timeStaked).div(86400).div(1000000);
    uint256 usersTotalReward = users[msg.sender].octxReward.add(accrueReward);

    return usersTotalReward;

  }

  function seeRemainingRewards() public view returns(uint256) {
    uint256 currentUnclaimedRewards = lastSysTotalStakeCheck.mul(miningRewardRate).mul(block.timestamp.sub(lastSysTimeCheck)).div(86400).div(1000000);

    if (currentUnclaimedRewards > availableRewards) {
      return 0;
    }
    else {
      return availableRewards.sub(currentUnclaimedRewards);
    }
  }

  function referralRewards() public view returns(uint256) {
    return users[msg.sender].refReward;
  }

  function checkTotalRefEarned() public view returns(uint256) {
    return users[msg.sender].totalRefEarnings;
  }

  function checkMyStake() public view returns(uint256) {
    return users[msg.sender].stakeAmount;
  }

  function currentMiningLv() public view returns(uint256) {
    return miningLevel;
  }

  function currentMiningRewardRate() public view returns(uint256) {
    return miningRewardRate; 
  }

  /**
   *@dev <LP> Reward Distribution Protocol
   *participate in liquidity provider pools by ORACLETX
   *stake your OCTX-LP tokens here and boost your earning protential 
   */
  function stakeLPToken(uint256 _amount) external { 
    require(lpAddress != address(0), "Not activated yet, needs dev update");
    require(_amount >= 100000000, "Minimum stake of 100 LP token");
    TRC20(lpAddress).transferFrom(msg.sender, address(this), _amount);

    User storage user = users[msg.sender];

    if (user.lp_lastUpdate == 0 || user.lp_stakingBalance == 0) {
      user.lp_lastUpdate = block.timestamp;
      user.priorProtocolRatio = lpProtocolExchangeRatio;
    }
    else {
      _lpRewardOCTX();
    }

    if (lpProtocolExchangeRatio > user.priorProtocolRatio) {
      user.lp_stakingBalance = user.lp_stakingBalance.mul(lpProtocolExchangeRatio).div(user.priorProtocolRatio);
      emit RewardedByProcotol(msg.sender, user.priorProtocolRatio, lpProtocolExchangeRatio);
      user.priorProtocolRatio = lpProtocolExchangeRatio;
    }

    user.lp_stakingBalance = user.lp_stakingBalance.add(_amount);
    lpTotalStaked = lpTotalStaked.add(_amount);
    _lpUpdateAvailability();

    emit StakedLP(msg.sender, _amount);
  }

  /**
   *@dev Unstaking at any time
   * LP protocol wide 0.5% withdrawl fee take only at time of unstaking
   * this will enter a pool that distributes it to all current stake providers
   */
  function unstakeLPToken() external {
    User storage user = users[msg.sender];
    require(user.lp_stakingBalance > 0, "Balance of Zero. No LP tokens were staked.");

    //update OCTX reward from LP pool prior to unstaking
    _lpRewardOCTX();

    //total LP tokens to be withdrawn
    uint256 unstakeAmount = user.lp_stakingBalance;

    uint256 protocolLPCommission = unstakeAmount.mul(lpProtocolFee).div(1000);  //protocol rewards
    lpProtocolPool = lpProtocolPool.add(protocolLPCommission);

    if (lpProtocolPool >= lpTotalStaked.div(lpProtocolExchangeRatio)) {
      lpProtocolExchangeRatio = lpProtocolExchangeRatio.add(lpProtocolPool.mul(lpProtocolExchangeRatio).div(lpTotalStaked));
      lpProtocolPool = 0;
    }

    uint256 amountToUser = unstakeAmount.sub(protocolLPCommission);
    lpTotalStaked = lpTotalStaked.sub(amountToUser);
    user.lp_stakingBalance = 0; 
    _lpUpdateAvailability(); 
    TRC20(lpAddress).transfer(msg.sender, amountToUser);

    emit UnstakeLP(msg.sender, unstakeAmount, protocolLPCommission);
  }

   /**
    *@dev declare intent to change LP Reward Rate
    *
    */
  function announceLPRewardRate(uint256 _rate) public onlyDev {
    require(_rate <= 3000, "Upper cap on reward rate");
    nextLPRewardRate = _rate;
    announceTime = block.timestamp;

    emit AnnounceChangeToLPRate(devAddress, _rate);
  }

  /*
   *@dev set the rate based on what was previously declared 
   */
  function setLPRewardRate() public onlyDev {
    require(block.timestamp >= announceTime + 172800, "Still in a waiting period");
    emit SetLPRate(nextLPRewardRate, lpStakingRewardRate);
    lpStakingRewardRate = nextLPRewardRate;
  }
  
  function lpClaimOCTX() external {
    User storage user = users[msg.sender];

    _lpRewardOCTX();

    uint256 rewardAmount = user.lp_reward;
    user.lp_reward = 0;

    if (rewardAmount > 0) {
      safeOCTXTransfer(msg.sender, rewardAmount);
      emit LPRewarded(msg.sender, rewardAmount);
      
      safeOCTXTransfer(owner, rewardAmount.mul(DEV_FEE).div(100));
      emit DevFee(owner, msg.sender, rewardAmount.mul(DEV_FEE).div(100));
    }
  }
  
  function _lpRewardOCTX() internal {
    User storage user = users[msg.sender];

    if (user.lp_stakingBalance > 0) {

      uint256 startTime = user.lp_lastUpdate;
      uint256 stakingPeriod;

      if (block.timestamp > lpSystemEndTime) {
       stakingPeriod = lpSystemEndTime.sub(startTime); 
      }
      else {
       stakingPeriod = block.timestamp.sub(startTime); 
      }

      uint256 rewardAmount = user.lp_stakingBalance.mul(lpStakingRewardRate).mul(stakingPeriod).div(86400).div(1000000);

      user.lp_reward = user.lp_reward.add(rewardAmount);
      user.lp_lastUpdate = block.timestamp;

    }
  }

  function _lpUpdateAvailability() internal {
    uint256 unclaimedLPRewards = lp_totalStakeCheck.mul(lpStakingRewardRate).mul(block.timestamp.sub(lp_lastTimeCheck)).div(86400).div(1000000);

    /**
    *@dev calculates ending period of lp rewards when fully mined
    */
    if (unclaimedLPRewards > lp_availableRewards) {
      lp_availableRewards = 0;  

      //calculate time difference of prior availability 
      uint256 timeDifference = lp_priorAvailable.mul(86400).mul(1000000).div(lp_totalStakeCheck).div(lpStakingRewardRate);
      lpSystemEndTime = lp_lastTimeCheck.add(timeDifference).sub(1);
    }
    else {
      lp_availableRewards = lp_availableRewards.sub(unclaimedLPRewards);

      lp_priorAvailable = lp_availableRewards;
      lp_lastTimeCheck = block.timestamp;
      lp_totalStakeCheck = lpTotalStaked; 

      uint256 addedTime = lp_availableRewards.mul(86400).mul(1000000).div(lpTotalStaked).div(lpStakingRewardRate);
      lpSystemEndTime = block.timestamp.add(addedTime);

    }
  }

  function unstakeLPTokenAmountOf(uint256 _amount) external {
    User storage user = users[msg.sender];
    require(user.lp_stakingBalance >= _amount, "This amount is greater than user's staked LP");
    require(_amount >= 100000000, "Minimum unstake amount: 100 OCTX-LP Tokens.");
    _lpRewardOCTX();

    uint256 protocolLPCommission = _amount.mul(lpProtocolFee).div(1000); //protocol rewards
    lpProtocolPool = lpProtocolPool.add(protocolLPCommission);
    if (lpProtocolPool >= lpTotalStaked.div(lpProtocolExchangeRatio)) {
      lpProtocolExchangeRatio = lpProtocolExchangeRatio.add(lpProtocolPool.mul(lpProtocolExchangeRatio).div(lpTotalStaked));
      lpProtocolPool = 0;
    }

    uint256 amountToUser = _amount.sub(protocolLPCommission);
    lpTotalStaked = lpTotalStaked.sub(amountToUser);
    user.lp_stakingBalance = user.lp_stakingBalance.sub(_amount);
    _lpUpdateAvailability();

    TRC20(lpAddress).transfer(msg.sender, amountToUser);
    emit UnstakeLP(msg.sender, _amount, protocolLPCommission);
  }


  function calcLPReward() public view returns(uint256) {
    uint256 startTime = users[msg.sender].lp_lastUpdate;
    uint256 timeStaked = block.timestamp.sub(startTime);
    uint256 accrueReward = users[msg.sender].lp_stakingBalance.mul(lpStakingRewardRate).mul(timeStaked).div(86400).div(1000000);
    uint256 lpUsersTotalReward = users[msg.sender].lp_reward.add(accrueReward);

    return lpUsersTotalReward;
  }

  function seeRemainingLPRewards() public view returns(uint256) {
    uint256 unclaimedLPRewards = lp_totalStakeCheck.mul(lpStakingRewardRate).mul(block.timestamp.sub(lp_lastTimeCheck)).div(86400).div(1000000);

    if (unclaimedLPRewards > lp_availableRewards) {
      return 0;
    }
    else {
      return lp_availableRewards.sub(unclaimedLPRewards);
    }
  }

  /**
  *@dev send LP tokens to be distributed to the Protocol Pool
  *to be used by protocol distributor
  *
  */
  function fullSystemDistribution(uint256 _amount) external {
    require(lpAddress != address(0), "Not activated yet, needs dev update");
    require(_amount > 1000000000, "Minimum stake of 1000 LP token");

    TRC20(lpAddress).transferFrom(msg.sender, address(this), _amount);
    lpProtocolPool = lpProtocolPool.add(_amount);

    emit ProtocolRewardsDistributed(msg.sender, _amount);
  }
}


//SourceUnit: OCTXToken.sol

pragma solidity ^0.5.10;

import "./TRC20.sol";
import "./SafeMath.sol";

/**
 * @title TRC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on TRON all the operations are done in sun.
 *
 * Example inherits from basic TRC20 implementation but can be modified to
 * extend from other ITRC20-based tokens:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1536
 */
contract OCTXToken is TRC20 {
    using SafeMath for uint256;

    /**
     * @dev Constructor
     * @param name The name of the token
     * @param symbol he symbol of the token
     * @param decimals The decimal percision of token
     */
    constructor (string memory name, string memory symbol, uint8 decimals)
      TRC20(name, symbol, decimals)
      public {
        _mint(msg.sender, 2.1e13);      
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

}


//SourceUnit: Ownable.sol

pragma solidity ^0.5.10;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TRC20.sol

pragma solidity ^0.5.10;

import "./Context.sol";
import "./ITRC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract TRC20 is Context, ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol}, and {decimals}
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }



    /**
     * @dev returns total supply.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     /**
     * @dev the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}