pragma solidity ^0.6.0;

import "./OneTokenPool.sol";
import "./IRewardDistributionRecipient.sol";
import "./FBGAccelerator.sol";

contract ETHAcceleratorCashPool is
    IRewardDistributionRecipient,
    FBGAccelerator,
    Operator
{
    IERC20 public basisCash;
    uint256 public DURATION = 5 days;

    uint256 public starttime = 1614614400;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerETHStored;
    mapping(address => uint256) public userRewardPerETHPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public deposits;

    uint256 public rewardAmount;
    uint256 public ethRewardAmount;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address basisCash_, address fbg_) public {
        basisCash = IERC20(basisCash_);
        fbg = IERC20(fbg_);
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, "LPTokenSharePool: not start");
        _;
    }

    modifier updateReward(address account) {
        rewardPerETHStored = rewardPerETH();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = ethEarned(account);
            userRewardPerETHPaid[account] = rewardPerETHStored;
        }
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerETH() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerETHStored;
        }
        return
            rewardPerETHStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function ethEarned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerETH().sub(userRewardPerETHPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function earned(address account) public view returns (uint256) {
        return ethEarned(account) + acceleratorEarned(account);
    }

    function stakeFBG(uint256 amountFBG)
        public
        override
        acceleratorUpdateReward(msg.sender)
        accleratorCheckStart
    {
        require(
            balanceOf(msg.sender) > 0,
            "ETHAcceleratorCashPool: can not accelerate before any HT staked"
        );

        super.stakeFBG(amountFBG);
    }

    // stake
    function stake() public payable updateReward(msg.sender) checkStart {
        uint256 amount = msg.value;
        require(amount > 0, "ETHAcceleratorCashPool: Cannot stake 0");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "ETHAcceleratorCashPool: Cannot withdraw 0");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        //transfer
        address(uint160(msg.sender)).transfer(amount);

        //if not balance , exit
        if (balanceOf(msg.sender) == 0) {
            withdrawFBG(balanceFBGOf(msg.sender));
            getReward();
        }

        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        withdrawFBG(balanceFBGOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            acceleratorRewards[msg.sender] = 0;
            basisCash.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 totalReward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        ethRewardAmount = totalReward.div(2);
        notifyAcceleratorRewardAmount(totalReward.sub(ethRewardAmount));

        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = ethRewardAmount.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = ethRewardAmount.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);

            emit RewardAdded(totalReward);
        } else {
            rewardRate = ethRewardAmount.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);

            emit RewardAdded(totalReward);
        }
    }

    function setStartTime(uint256 starttime_) external onlyOperator {
        starttime = starttime_;
        acceleratorStartTime = starttime_;
    }

    function setDuration(uint256 day) external onlyOperator {
        DURATION = day * 1 days;
        acceleratorDURATION = DURATION;
    }
}