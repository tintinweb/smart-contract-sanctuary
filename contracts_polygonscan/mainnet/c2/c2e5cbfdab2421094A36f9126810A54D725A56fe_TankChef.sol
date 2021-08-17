// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeERC20.sol";

contract TankChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;           // Address of token contract.
        uint256 lastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e18. See below.
    }

    // The deposit token!
    IERC20 public depositToken;
    IERC20 public rewardToken;

    // Reward tokens created per block.
    uint256 public rewardPerBlock;
    uint256 blank;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes tokens.
    mapping (address => UserInfo) public userInfo;
    uint256 public startBlock;
    uint256 public endBlock;

    // The amount to burn in 0.01 percentages
    uint256 public burnMultiplier;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IERC20 _depositToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _burnMultiplier
    ) public {
        depositToken = _depositToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        burnMultiplier = _burnMultiplier;

        // staking pool
        poolInfo = PoolInfo({
            token: _depositToken,
            lastRewardBlock: startBlock,
            accRewardPerShare: 0
        });

    }

    function stopReward() external onlyOwner {
        endBlock = block.number;
    }

    function adjustBlockEnd() external onlyOwner {
        uint256 totalLeft = rewardToken.balanceOf(address(this));
        endBlock = block.number + totalLeft.div(rewardPerBlock);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = poolInfo.accRewardPerShare;
        uint256 supply = poolInfo.token.balanceOf(address(this));
        if (block.number > poolInfo.lastRewardBlock && supply != 0) {
            uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e18).div(supply));
        }
        return user.amount.mul(accRewardPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }
        uint256 supply = poolInfo.token.balanceOf(address(this));
        if (supply == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock);
        poolInfo.accRewardPerShare = poolInfo.accRewardPerShare.add(reward.mul(1e18).div(supply));
        poolInfo.lastRewardBlock = block.number;
    }

    // Stake depositToken tokens to SmartChef
    function deposit(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(poolInfo.accRewardPerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                user.rewardDebt = user.amount.mul(poolInfo.accRewardPerShare).div(1e18);
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if(_amount > 0) {
            uint256 burnAmount = _amount.mul(burnMultiplier).div(10000);
            poolInfo.token.safeTransferFrom(address(msg.sender), address(this), _amount - burnAmount);
            if (burnAmount > 0) {
                poolInfo.token.safeTransferFrom(address(msg.sender), address(0xdead), burnAmount);
            }
            user.amount = user.amount.add(_amount - burnAmount);
        }
        user.rewardDebt = user.amount.mul(poolInfo.accRewardPerShare).div(1e18);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw depositToken tokens from STAKING.
    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(poolInfo.accRewardPerShare).div(1e18).sub(user.rewardDebt);
        if(pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            poolInfo.token.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(poolInfo.accRewardPerShare).div(1e18);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        poolInfo.token.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

}