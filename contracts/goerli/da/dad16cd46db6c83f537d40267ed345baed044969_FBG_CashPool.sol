// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import './OneTokenPool.sol';
import './IRewardDistributionRecipient.sol';

contract FBG_CashPool is OneTokenPool, IRewardDistributionRecipient {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    IERC20 public basisCash;
    uint256 public DURATION = 5 days;

    uint256 public starttime = 1614182740;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public deposits;

    uint256 public tokenRewardAmount;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address basisCash_, address babisGovernance_) public {
        basisCash = IERC20(basisCash_);
        token = IERC20(babisGovernance_);
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, 'FBGCashPool: not start');
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'FBGCashPool: Cannot stake 0');
        uint256 newDeposit = deposits[msg.sender] + amount;
        require(
            newDeposit <= 20000e18,
            'FBGCashPool: deposit amount exceeds maximum 20000'
        );
        deposits[msg.sender] = newDeposit;
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'FBGCashPool: Cannot withdraw 0');
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            basisCash.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // function notifyRewardAmount(uint256 reward)
    //     external
    //     override
    //     onlyRewardDistribution
    //     updateReward(address(0))
    // {
    //     tokenRewardAmount = reward;
    //     if (block.timestamp > starttime) {
    //         if (block.timestamp >= periodFinish) {
    //             rewardRate = reward.div(DURATION);
    //         } else {
    //             uint256 remaining = periodFinish.sub(block.timestamp);
    //             uint256 leftover = remaining.mul(rewardRate);
    //             rewardRate = reward.add(leftover).div(DURATION);
    //         }
    //         lastUpdateTime = block.timestamp;
    //         periodFinish = block.timestamp.add(DURATION);
    //         emit RewardAdded(reward);
    //     } else {
    //         rewardRate = reward.div(DURATION);
    //         lastUpdateTime = starttime;
    //         periodFinish = starttime.add(DURATION);
    //         emit RewardAdded(reward);
    //     }
    // }

    function notifyRewardAmount(uint256 totalReward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        tokenRewardAmount = totalReward;
        rewardRate = tokenRewardAmount.div(DURATION);
    }

    function setTimeCircle(uint256 starttime_, uint256 day)
        external
        onlyOperator
    {
        starttime = starttime_;
        DURATION = day * 1 days;
        periodFinish = starttime.add(DURATION);
        lastUpdateTime = starttime;
    }
}