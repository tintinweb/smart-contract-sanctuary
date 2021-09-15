// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewards is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public TKN;
    uint256 public rewardRateNumerator = 1450; //for 14.5%
    uint256 constant private REWARD_RATE_DENOMINATOR = 10000;
    uint256 public periodFinish = 0;
    uint256 rewardDebt = 0;

    uint256 private _totalSupply;
    
    struct UserInfo{
        uint256 rewards;
        uint256 balances;
        uint256 lastUpdateTime;
    }
    
    mapping(address => UserInfo) users;



    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _TKN
    ) {
        TKN = IERC20(_TKN);

        transferOwnership(_owner);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return users[account].balances;
    }
    
    function earned(address account) public view returns (uint256) {
        return rewardRateNumerator.mul(users[account].balances).mul(block.timestamp.sub(users[account].lastUpdateTime)).mul(1e12).div(360 days).div(REWARD_RATE_DENOMINATOR).div(1e12);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(block.timestamp < periodFinish, "Staking program is expired!");
        uint256 amountDebt = amount.mul(rewardRateNumerator).mul(periodFinish.sub(block.timestamp)).mul(1e12).div(REWARD_RATE_DENOMINATOR).div(360 days).div(1e12);
        require(amountDebt.add(rewardDebt).add(_totalSupply) < TKN.balanceOf(address(this)), "Cannot stake, cause not enough reward tokens on the staking contract");
        UserInfo storage user = users[msg.sender];
        _totalSupply = _totalSupply.add(amount);
        user.balances = user.balances.add(amount);
        TKN.safeTransferFrom(msg.sender, address(this), amount);
        rewardDebt = rewardDebt.add(amountDebt);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        UserInfo storage user = users[msg.sender];
        _totalSupply = _totalSupply.sub(amount);
        user.balances = user.balances.sub(amount);
        TKN.safeTransfer(msg.sender, amount);
        if (block.timestamp < periodFinish) {
            uint256 amountDebt = amount.mul(rewardRateNumerator).mul(periodFinish.sub(block.timestamp)).mul(1e12).div(REWARD_RATE_DENOMINATOR).div(360 days).div(1e12);
            rewardDebt = rewardDebt.sub(amountDebt);
        }
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = users[msg.sender].rewards;
        if (reward > 0) {
            users[msg.sender].rewards = 0;
            TKN.safeTransfer(msg.sender, reward);
            rewardDebt = rewardDebt.sub(reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external updateReward(msg.sender) {
        withdraw(users[msg.sender].balances);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(uint256 tokenAmount) external onlyOwner {
        require(tokenAmount.add(_totalSupply).add(rewardDebt) < (TKN.balanceOf(address(this))), "Cannot withdraw the staking tokens");
        TKN.safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAmount);
    }

    function setPaused(bool _p) external onlyOwner {
        if (_p) {
            _pause();
        } else {
            _unpause();
        }
    }
    
    function prolongDuration(uint256 _period) external onlyOwner {
        uint256 newPeriodFinish = block.timestamp.add(_period.mul(1 days));
        require(TKN.balanceOf(address(this)) > _totalSupply.add(rewardDebt).add(_totalSupply.mul(rewardRateNumerator).mul(1e12).mul(newPeriodFinish.sub(block.timestamp)).div(REWARD_RATE_DENOMINATOR).div(360 days).div(1e12)), "Not enough balance to prolong staking programm");
        periodFinish = newPeriodFinish;
        rewardDebt = rewardDebt.add(_totalSupply.mul(rewardRateNumerator).mul(1e12).mul(periodFinish.sub(block.timestamp)).div(REWARD_RATE_DENOMINATOR).div(360 days).div(1e12));
    }
    
    function getRewardDebt() public view onlyOwner returns(uint256){
        return rewardDebt;
    }
    
    function getRewards(address account) public view returns(uint256){
        return users[account].rewards;
    }
    

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        users[account].rewards = users[account].rewards.add(earned(account));
        users[account].lastUpdateTime = block.timestamp;
        _;
    }

    /* ========== EVENTS ========== */

    event RewardRateChanged(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(uint256 amount);
}