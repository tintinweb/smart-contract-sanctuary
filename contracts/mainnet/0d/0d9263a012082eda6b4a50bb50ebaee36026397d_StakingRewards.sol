// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./ILinkswapERC20.sol";
import "./IStakingRewards.sol";
import "./RewardsRecipient.sol";

contract StakingRewards is IStakingRewards, RewardsRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    event RewardAdded(address indexed rewardToken, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 amount);

    /* ========== STATE VARIABLES ========== */

    address public owner;
    IERC20 public stakingToken;
    uint256 public lastUpdateTime;
    uint256 public periodFinish;
    uint256 public rewardsDuration;

    IERC20[2] public rewardTokens;
    uint256[2] public rewardRate;
    uint256[2] public rewardPerTokenStored;
    mapping(address => uint256)[2] public userRewardPerTokenPaid;
    mapping(address => uint256)[2] public unclaimedRewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingToken,
        address _rewardsDistributor,
        address _varenToken,
        address _extraRewardToken, // optional
        uint256 _rewardsDuration,
        address _owner
    ) {
        require(
            _rewardsDistributor != address(0) &&
                _varenToken != address(0) &&
                _stakingToken != address(0),
            "address(0)"
        );
        require(_rewardsDuration > 0, "rewardsDuration=0");
        rewardsDistributor = _rewardsDistributor;
        rewardTokens[0] = IERC20(_varenToken);
        rewardTokens[1] = IERC20(_extraRewardToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDuration = _rewardsDuration;
        owner = _owner;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored[0] = rewardPerToken(0);
        if (address(rewardTokens[1]) != address(0)) rewardPerTokenStored[1] = rewardPerToken(1);
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            unclaimedRewards[0][account] = earned(account, 0);
            unclaimedRewards[1][account] = earned(account, 1);
            userRewardPerTokenPaid[0][account] = rewardPerTokenStored[0];
            userRewardPerTokenPaid[1][account] = rewardPerTokenStored[1];
        }
        _;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function getRewardForDuration(uint256 rewardTokenIndex) external view override returns (uint256) {
        return rewardRate[rewardTokenIndex].mul(rewardsDuration);
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken(uint256 rewardTokenIndex) public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored[rewardTokenIndex];
        }
        return
            rewardPerTokenStored[rewardTokenIndex].add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate[rewardTokenIndex])
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account, uint256 rewardTokenIndex) public view override returns (uint256) {
        return
            _balances[account]
                .mul(
                rewardPerToken(rewardTokenIndex).sub(
                    userRewardPerTokenPaid[rewardTokenIndex][account]
                )
            )
                .div(1e18)
                .add(unclaimedRewards[rewardTokenIndex][account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        ILinkswapERC20(address(stakingToken)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        _stake(amount);
    }

    function unstakeAndClaimRewards(uint256 unstakeAmount)
        external override
        nonReentrant
        updateReward(msg.sender)
    {
        _unstake(unstakeAmount);
        _claimReward(0);
        _claimReward(1);
    }

    // Unstake without claiming rewards. For emergency use if claiming rewards is failing.
    function unstake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        _unstake(amount);
    }

    // Sends to the caller any unclaimed rewards earned by the caller.
    function claimRewards() external override nonReentrant updateReward(msg.sender) {
        _claimReward(0);
        _claimReward(1);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _stake(uint256 amount) private {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function _unstake(uint256 amount) private {
        require(amount > 0, "Cannot unstake 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function _claimReward(uint256 rewardTokenIndex) private {
        uint256 rewardAmount = unclaimedRewards[rewardTokenIndex][msg.sender];
        if (rewardAmount > 0) {
            uint256 rewardsBal = rewardTokens[rewardTokenIndex].balanceOf(address(this));
            if (rewardsBal == 0) return;
            // avoid paying more than total rewards balance
            rewardAmount = rewardsBal < rewardAmount ? rewardsBal : rewardAmount;
            unclaimedRewards[rewardTokenIndex][msg.sender] = unclaimedRewards[rewardTokenIndex][msg
                .sender]
                .sub(rewardAmount);
            rewardTokens[rewardTokenIndex].safeTransfer(msg.sender, rewardAmount);
            emit RewardPaid(msg.sender, address(rewardTokens[rewardTokenIndex]), rewardAmount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 amount, uint256 extraAmount)
        external override
        onlyRewardsDistributor
        updateReward(address(0))
    {
        require(amount > 0 || extraAmount > 0, "zero amount");
        if (extraAmount > 0) {
            require(address(rewardTokens[1]) != address(0), "extraRewardToken=0x0");
        }
        if (block.timestamp >= periodFinish) {
            rewardRate[0] = amount.div(rewardsDuration);
            if (extraAmount > 0) rewardRate[1] = extraAmount.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate[0]);
            rewardRate[0] = amount.add(leftover).div(rewardsDuration);
            if (extraAmount > 0) {
                leftover = remaining.mul(rewardRate[1]);
                rewardRate[1] = extraAmount.add(leftover).div(rewardsDuration);
            }
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardTokens[0].balanceOf(address(this));
        require(rewardRate[0] <= balance.div(rewardsDuration), "Provided reward too high");
        if (extraAmount > 0) {
            balance = rewardTokens[1].balanceOf(address(this));
            require(
                rewardRate[1] <= balance.div(rewardsDuration),
                "Provided extra reward too high"
            );
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(address(rewardTokens[0]), amount);
        if (extraAmount > 0) emit RewardAdded(address(rewardTokens[1]), extraAmount);
    }
}