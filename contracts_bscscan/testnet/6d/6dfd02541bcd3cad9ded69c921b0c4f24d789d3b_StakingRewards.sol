pragma solidity ^0.5.16;

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20Detailed.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

// Inheritance
import "./IStakingRewards.sol";
import "./RewardsDistributionRecipient.sol";
import "./Pausable.sol";


// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    // uint256 public rewardsDuration = 7 days;
    uint256 public rewardsDuration = 90 days;

    //lock duration
    // uint256 public lockDownDuration = 30 days;
    uint256 public lockDownDuration = 5 seconds;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    //withdraw rate 5 for 0.05% 
    uint256 public withdrawRate = 0;
    uint256 public feeScale = 10000;

    //NOTE:modify me before mainnet
    address public feeCollector = 0xCcC8f5E44647eC7B05F6aA4A31E388A55303f73c;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    struct TimedStake {
      mapping(uint256 => uint256) stakes;
      uint256[] stakeTimes;
    }

    mapping(address => TimedStake) timeStakeInfo;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public Owned(_owner) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }


    function withdrawableAmount(address account)public view returns(uint256){
        uint256 amount = 0;
        TimedStake storage _timedStake = timeStakeInfo[account];
        
        for (uint8 index = 0; index < _timedStake.stakeTimes.length; index++) {
            uint256 key = _timedStake.stakeTimes[index];
            if (now.sub(key) > lockDownDuration){
                amount = amount.add(_timedStake.stakes[key]);
            }
        }
        return amount;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setWithdrawRate(uint256 _rate) external onlyOwner {
        require(_rate < 10000,"withdraw rate is too high");
        withdrawRate = _rate;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner{
        feeCollector = _feeCollector;
    }

    function stake(uint256 amount) external nonReentrant notPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        TimedStake storage _timedStake = timeStakeInfo[msg.sender];
        _timedStake.stakes[now] = amount;
        _timedStake.stakeTimes.push(now);
        timeStakeInfo[msg.sender] = _timedStake;
        emit Staked(msg.sender, amount);
    }

    function dealwithLockdown(uint256 amount,address account) internal {
        uint256 _total = amount;
        TimedStake storage _timedStake = timeStakeInfo[account];
         for (uint8 index = 0; index < _timedStake.stakeTimes.length; index++) {
           if (_total > 0){
              uint256 key = _timedStake.stakeTimes[index];
              if (now.sub(key) > lockDownDuration){
                  if(_total >= _timedStake.stakes[key]){
                      _total = _total.sub(_timedStake.stakes[key]);
                      delete( _timedStake.stakes[key]);
                      delete( _timedStake.stakeTimes[index]);
                  }else{
                      _timedStake.stakes[key] = _timedStake.stakes[key].sub(_total);
                      _total = 0;
                      break;
                  }
              }
           }
        }
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        require(withdrawableAmount(msg.sender) >= amount,"not enough withdrawable balance");
        dealwithLockdown(amount,msg.sender);
        uint256 fee = amount.mul(withdrawRate).div(feeScale);
        stakingToken.safeTransfer(msg.sender, amount.sub(fee));
        if (fee > 0 ){
            stakingToken.safeTransfer(feeCollector, fee);
        }
        emit Withdrawn(msg.sender, amount.sub(fee));
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");
        // for staking token same with reward token casee
        // if(rewardsToken == stakingToken){
        //     require(balance - _totalSupply == reward,"reward not same with depoist amount");
        // }
       
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setLockDownDuration(uint256 _lockdownDuration) external onlyOwner {
        lockDownDuration = _lockdownDuration;
        emit LockDownDurationUpdated(_lockdownDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event LockDownDurationUpdated(uint256 newLockDownDuration);
}