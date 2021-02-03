pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20, SafeMath} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";

import {StorageBuffer} from "./proxy/StorageBuffer.sol";
import {GovernableProxy} from "./proxy/GovernableProxy.sol";
import {LPTokenWrapper} from "./JointMiner.sol";

contract SushiDFDMiner is LPTokenWrapper {
    IERC20 public immutable sushi;
    IMasterChef public immutable masterChef;
    uint256 public immutable pid; // sushi pool id

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public sushiPerTokenStored;
    mapping(address => uint256) public sushiPerTokenPaid;
    mapping(address => uint256) public sushiRewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event SushiPaid(address indexed user, uint256 reward);

    constructor(
        address _dfd,
        address _sushi,
        address _lpToken,
        address _masterChef,
        uint256 _pid
    )
        public
        LPTokenWrapper(_dfd, _lpToken)
    {
        require(
           _sushi != address(0) && _masterChef != address(0),
           "NULL_ADDRESSES"
        );
        sushi = IERC20(_sushi);
        masterChef = IMasterChef(_masterChef);
        pid = _pid;
    }

    function _updateReward(address account) override internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        uint _then = sushi.balanceOf(address(this));
        masterChef.withdraw(pid, 0); // harvests sushi
        sushiPerTokenStored = _sushiPerToken(sushi.balanceOf(address(this)).sub(_then));

        if (account != address(0)) {
            rewards[account] = _earned(account, rewardPerTokenStored);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;

            sushiRewards[account] = _sushiEarned(account, sushiPerTokenStored);
            sushiPerTokenPaid[account] = sushiPerTokenStored;
        }
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

    function sushiPerToken() public view returns (uint256) {
        return _sushiPerToken(masterChef.pendingSushi(pid, address(this)));
    }

    function _sushiPerToken(uint earned_) internal view returns (uint256) {
        uint _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            return sushiPerTokenStored
                .add(
                    earned_
                    .mul(1e18)
                    .div(_totalSupply)
                );
        }
        return sushiPerTokenStored;
    }

    function earned(address account) public view returns (uint256) {
        return _earned(account, rewardPerToken());
    }

    function _earned(address account, uint _rewardPerToken) internal view returns (uint256) {
        return
            balanceOf(account)
                .mul(_rewardPerToken.sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function sushiEarned(address account) public view returns (uint256) {
        return _sushiEarned(account, sushiPerToken());
    }

    function _sushiEarned(address account, uint256 sushiPerToken_) internal view returns (uint256) {
        return
            balanceOf(account)
                .mul(sushiPerToken_.sub(sushiPerTokenPaid[account]))
                .div(1e18)
                .add(sushiRewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) override public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        lpToken.safeApprove(address(masterChef), amount);
        masterChef.deposit(pid, amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) override public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        masterChef.withdraw(pid, amount); // harvests sushi
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            dfd.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
        reward = sushiRewards[msg.sender];
        if (reward > 0) {
            sushiRewards[msg.sender] = 0;
            sushi.safeTransfer(msg.sender, reward);
            emit SushiPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward, uint256 duration)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        dfd.safeTransferFrom(msg.sender, address(this), reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }
}

interface IMasterChef {
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function pendingSushi(uint256 pid, address user) external view returns(uint);
}