pragma solidity 0.5.17;



import "./LPTokenWrapper.sol";


contract StakingPool is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public constant rewardToken = IERC20(0x1820e4eB3031D27cb30b3040DA17A7697Ee72d23);

    string public desc;

    uint256 public DURATION;
    uint256 public starttime;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _lpToken, string memory _desc, uint256 _starttime) public LPTokenWrapper(_lpToken) {
        rewardDistribution = msg.sender;
        desc = _desc;
        starttime = _starttime;
    }

    function setStartTime(uint256 _starttime) external onlyOwner {
        require(block.timestamp < starttime, "started");
        starttime = _starttime;
    }

    modifier checkStart(){
        require(block.timestamp >= starttime, "not started");
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

    function stake(uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot withdraw 0");
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
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 _reward, uint256 _duration) external onlyRewardDistribution updateReward(address(0)) {
        require(_duration != 0, "Duration must not be 0");
        require(_reward != 0, "Reward must not be 0");

        rewardToken.safeTransferFrom(msg.sender, address(this), _reward);
        DURATION = _duration;
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = _reward.div(_duration);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = _reward.add(leftover).div(_duration);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(_duration);
            emit RewardAdded(_reward);
        } else {
            rewardRate = _reward.div(_duration);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(_duration);
            emit RewardAdded(_reward);
        }
    }
}