pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "./LPTokenWrapper.sol";
import "./interfaces/IMultiplier.sol";


contract CORGIETH is LPTokenWrapper, OwnableUpgradeSafe {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    IERC20 public dream;
    IMultiplier multiplier;
    uint256 public DURATION;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public deployedTime;
    address public vault;
    address public nap;

    struct RewardInfo {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    mapping(address => RewardInfo) public rewards;

    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Boost(address _token, uint256 level);

    constructor(
        uint256 _duration,
        address _stakingToken,
        address _rewardToken,
        address _multiplier,
        address _treasury,
        address _vault,
        address _nap
    ) public {
        require(
            _duration != 0 &&
                _stakingToken != address(0) &&
                _rewardToken != address(0) &&
                _multiplier != address(0) &&
                _treasury != address(0) &&
                _vault != address(0) &&
                _nap != address(0),
            "!constructor"
        );
        __Ownable_init();
        setStakingToken(_stakingToken);
        multiplier = IMultiplier(_multiplier);
        treasury = _treasury;
        devFee = 10; // 1%
        rewardToken = IERC20(_rewardToken);
        deployedTime = block.timestamp;
        DURATION = _duration;
        vault = _vault;
        nap = _nap;
    }

    function setNewTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function lastTimeRewardsActive() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /* @dev Returns the current rate of rewards per token (doh) */
    function rewardPerToken() public view returns (uint256) {
        // Do not distribute rewards before startTime.
        if (block.timestamp < startTime) {
            return 0;
        }
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        // Effective total supply takes into account all the multipliers bought by userbase.
        uint256 effectiveTotalSupply = _totalSupply.add(_totalSupplyAccounting);
        // The returrn value is time-based on last time the contract had rewards active multipliede by the reward-rate.
        // It's evened out with a division of bonus effective supply.
        return
            rewardPerTokenStored.add(
                lastTimeRewardsActive().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(effectiveTotalSupply)
            );
    }

    /** @dev Returns the claimable tokens for user.*/
    function earned(address account) public view returns (uint256) {
        // Do a lookup for the multiplier on the view - it's necessary for correct reward distribution.
        // A user might have staked while owning global multiplier tokens but sold them and not acted in the contract after that.
        // So we do a recheck of the correct multiplier value here.
        uint256 totalMultiplier = multiplier.getTotalValueForUser(address(this), account);
        uint256 balance = _balances[account].balance;
        uint256 effectiveBalance = balance.add(balance.mul(totalMultiplier).div(1000));
        RewardInfo memory userRewards = rewards[account];
        return
            effectiveBalance.mul(rewardPerToken().sub(userRewards.userRewardPerTokenPaid)).div(1e18).add(
                userRewards.rewards
            );
    }

    /** @dev Staking function which updates the user balances in the parent contract */
    function stake(uint256 amount) public override {
        updateReward(msg.sender);
        require(amount > 0, "Cannot stake 0");

        super.stake(amount);
        // Call the parent to adjust the balances.

        // Get users multiplier.
        uint256 userTotalMultiplier = multiplier.getTotalValueForUser(address(this), msg.sender);

        // Adjust the bonus effective stake according to the multiplier.
        adjustEffectiveStake(userTotalMultiplier, false);
        emit Staked(msg.sender, amount);
    }

    /** @dev Withdraw function, this pool contains a tax which is defined in the constructor */
    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);

        // Calculate the withdraw tax (it's 1% of the amount)
        uint256 tax = amount.mul(devFee).div(1000);

        // Transfer the tokens to user
        stakingToken.safeTransfer(msg.sender, amount.sub(tax));
        // Tax to treasury
        stakingToken.safeTransfer(treasury, tax);

        // Adjust regular balances
        super.withdraw(amount);

        // And the bonus balances
        uint256 userTotalMultiplier = multiplier.getTotalValueForUser(address(this), msg.sender);
        adjustEffectiveStake(userTotalMultiplier, true);
        emit Withdrawn(msg.sender, amount);
    }

    /** @dev Adjust the bonus effective stakee for user and whole userbase */
    function adjustEffectiveStake(uint256 _totalMultiplier, bool _isWithdraw) private {
        Balances storage balances = _balances[msg.sender];
        uint256 prevBalancesAccounting = balances.balancesAccounting;
        if (_totalMultiplier > 0) {
            // Calculate and set self's new accounting balance
            uint256 newBalancesAccounting = balances.balance.mul(_totalMultiplier).div(1000);

            // Adjust total accounting supply accordingly - Subtracting previous balance from new balance on withdraws
            // On deposits it's vice-versa.
            if (_isWithdraw) {
                uint256 diffBalancesAccounting = prevBalancesAccounting.sub(newBalancesAccounting);
                balances.balancesAccounting = balances.balancesAccounting.sub(diffBalancesAccounting);
                _totalSupplyAccounting = _totalSupplyAccounting.sub(diffBalancesAccounting);
            } else {
                uint256 diffBalancesAccounting = newBalancesAccounting.sub(prevBalancesAccounting);
                balances.balancesAccounting = balances.balancesAccounting.add(diffBalancesAccounting);
                _totalSupplyAccounting = _totalSupplyAccounting.add(diffBalancesAccounting);
            }
        } else {
            balances.balancesAccounting = 0;
            _totalSupplyAccounting = _totalSupplyAccounting.sub(prevBalancesAccounting);
        }
    }

    // Ease-of-access function for user to remove assets from the pool.
    function exit() external {
        getReward();
        withdraw(balanceOf(msg.sender));
    }

    // Sends out the reward tokens to the user.
    function getReward() public {
        updateReward(msg.sender);
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender].rewards = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Called to start the pool.
    // Owner must send rewards to the contract and the balance of this token is used as the reward to account for fee on transfer tokens.
    // The reward period will be the duration of the pool.
    function notifyRewardAmount() external onlyOwner {
        uint256 reward = rewardToken.balanceOf(address(this));
        require(reward > 0, "!reward added");
        // Update reward values
        updateRewardPerTokenStored();

        // Rewardrate must stay at a constant since it's used by end-users claiming rewards after the reward period has finished.
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.sub(reward.div(98)).div(DURATION + 6 hours);
        } else {
            // Remaining time for the pool
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            // And the rewards
            uint256 rewardsRemaining = remainingTime.mul(rewardRate);
            // Set the current rate
            rewardRate = reward.add(rewardsRemaining).div(DURATION);
        }

        // Set the last updated
        lastUpdateTime = block.timestamp;
        startTime = block.timestamp;
        // Add the period to be equal to duration set.s
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    // Returns the users current multiplier level
    function getTotalLevel(address _user) external view returns (uint256) {
        return multiplier.getTotalLevel(address(this), _user);
    }

    // Return the amount spent on multipliers, used for subtracting for future purchases.
    function getSpent(address _token, address _user) external view returns (uint256) {
        return multiplier.getTokensSpentPerContract(address(this), _token, _user);
    }

    // Calculate the cost for purchasing a boost.
    function calculateCost(
        address _user,
        address _token,
        uint256 _level
    ) public view returns (uint256) {
        // Users last level, no cost for levels lower than current (doh)
        uint256 lastLevel = multiplier.getLastTokenLevelForUser(address(this), _user, _token);
        if (lastLevel >= _level) {
            return 0;
        } else {
            return multiplier.getSpendableCostPerTokenForUser(address(this), _user, _token, _level);
        }
    }

    // Purchase a multiplier level, same level cannot be purchased twice.
    function purchase(address _token, uint256 _newLevel) external {
        // Must be a spendable token
        require(multiplier.isSpendableTokenInContract(address(this), _token), "Not a spendable token");

        // What's the last level for the user? s
        uint256 lastLevel = multiplier.getLastTokenLevelForUser(address(this), msg.sender, _token);
        require(lastLevel < _newLevel, "Cannot downgrade level or same level");

        // Get the subtracted cost for the new level.
        uint256 cost = calculateCost(msg.sender, _token, _newLevel);
        require(cost != 0, "cost cannot be 0");

        if (_token == address(dream)) {
            IERC20(_token).safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, cost);
        } else if (_token == nap) {
            IERC20(_token).safeTransferFrom(msg.sender, vault, cost.div(2));
            IERC20(_token).safeTransferFrom(msg.sender, treasury, cost.div(2));
        } else {
            // Transfer the bonus cost into the treasury.
            IERC20(_token).safeTransferFrom(msg.sender, treasury, cost);
        }

        // Update balances and level in the multiplier contarct
        multiplier.purchase(address(this), msg.sender, _token, _newLevel);

        // Adjust new level
        uint256 userTotalMultiplier = multiplier.getTotalValueForUser(address(this), msg.sender);
        adjustEffectiveStake(userTotalMultiplier, false);

        emit Boost(_token, _newLevel);
    }

    // Returns the multiplier for user.
    function getTotalMultiplier(address _account) public view returns (uint256) {
        return multiplier.getTotalValueForUser(address(this), _account);
    }

    // Ejects any remaining tokens from the pool.
    // Callable only after the pool has started and the pools reward distribution period has finished.
    function eject() external onlyOwner {
        require(
            startTime < block.timestamp && block.timestamp >= periodFinish + 12 hours,
            "Cannot eject before period finishes or pool has started"
        );
        uint256 currBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, currBalance);
    }

    // Forcefully retire a pool
    // Only sets the period finish to 0
    // This will prevent more rewards from being disbursed
    function kill() external onlyOwner {
        periodFinish = block.timestamp;
    }

    function updateRewardPerTokenStored() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardsActive();
    }

    function updateReward(address account) internal {
        updateRewardPerTokenStored();
        rewards[account].rewards = earned(account);
        rewards[account].userRewardPerTokenPaid = rewardPerTokenStored;
    }
}