// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./IMasterChef.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewardsWithMasterChef is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public timelock;

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    IERC20 public sushiToken = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IMasterChef public sushiMasterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    uint256 public masterchefPID;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public sushiPerTokenStored;
    uint256 public sushiBalanceAtLastUpdate;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userSushiPerTokenPaid;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public sushiRewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _timelock,
        address _owner,
        address _rewardsToken,
        address _stakingToken,
        uint256 _masterchefPID
    ) {
        timelock = _timelock;

        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);

        masterchefPID = _masterchefPID;

        transferOwnership(_owner);
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

    function sushiPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return sushiPerTokenStored;
        }

        uint256 pendingSushi = sushiMasterChef.pendingSushi(masterchefPID, address(this));
        return
            sushiPerTokenStored.add(
                sushiToken.balanceOf(address(this)).add(pendingSushi).sub(sushiBalanceAtLastUpdate).mul(1e18).div(
                    _totalSupply
                )
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    function sushiEarned(address account) public view returns (uint256) {
        return
            _balances[account].mul(sushiPerToken().sub(userSushiPerTokenPaid[account])).div(1e18).add(
                sushiRewards[account]
            );
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // Deposit into masterchef
        stakingToken.safeApprove(address(sushiMasterChef), 0);
        stakingToken.safeApprove(address(sushiMasterChef), amount);
        sushiMasterChef.deposit(masterchefPID, amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        // Withdraw from masterchef
        sushiMasterChef.withdraw(masterchefPID, amount);

        // Send to user
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        uint256 sushiReward = sushiRewards[msg.sender];

        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
        }

        if (sushiReward > 0) {
            sushiRewards[msg.sender] = 0;
            sushiToken.safeTransfer(msg.sender, sushiReward);

            // Remember to update sushi balance
            sushiBalanceAtLastUpdate = sushiBalanceAtLastUpdate.sub(sushiReward);
        }

        emit RewardPaid(msg.sender, reward, sushiReward);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
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
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);

        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
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

    function setPaused(bool _p) external onlyOwner {
        if (_p) {
            _pause();
        } else {
            _unpause();
        }
    }

    function emergencyWithdraw(address _destination) external {
        require(msg.sender == timelock);

        sushiMasterChef.emergencyWithdraw(masterchefPID);
        stakingToken.transfer(_destination, stakingToken.balanceOf(address(this)));
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        // Get rewards from masterchef first
        // to store the delta
        sushiMasterChef.withdraw(masterchefPID, 0);
        sushiPerTokenStored = sushiPerToken();
        sushiBalanceAtLastUpdate = sushiToken.balanceOf(address(this));

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;

            sushiRewards[account] = sushiEarned(account);
            userSushiPerTokenPaid[account] = sushiPerTokenStored;
        }

        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, uint256 sushiReward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}