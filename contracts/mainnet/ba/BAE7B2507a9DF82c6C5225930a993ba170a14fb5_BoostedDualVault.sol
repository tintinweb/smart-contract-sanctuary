// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

// Internal
import { IRewardsRecipientWithPlatformToken } from "../../interfaces/IRewardsDistributionRecipient.sol";
import { IBoostedDualVaultWithLockup } from "../../interfaces/IBoostedDualVaultWithLockup.sol";
import { IRewardsDistributionRecipient, InitializableRewardsDistributionRecipient } from "../InitializableRewardsDistributionRecipient.sol";
import { BoostedTokenWrapper } from "./BoostedTokenWrapper.sol";
import { PlatformTokenVendor } from "../staking/PlatformTokenVendor.sol";
import { Initializable } from "../../shared/@openzeppelin-2.5/Initializable.sol";

// Libs
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { StableMath } from "../../shared/StableMath.sol";

/**
 * @title  BoostedDualVault
 * @author mStable
 * @notice Accrues rewards second by second, based on a users boosted balance
 * @dev    Forked from rewards/staking/StakingRewards.sol
 *         Changes:
 *          - Lockup implemented in `updateReward` hook (20% unlock immediately, 80% locked for 6 months)
 *          - `updateBoost` hook called after every external action to reset a users boost
 *          - Struct packing of common data
 *          - Searching for and claiming of unlocked rewards
 *          - Add a second rewards token in the platform rewards
 */
contract BoostedDualVault is
    IBoostedDualVaultWithLockup,
    IRewardsRecipientWithPlatformToken,
    Initializable,
    InitializableRewardsDistributionRecipient,
    BoostedTokenWrapper
{
    using SafeERC20 for IERC20;
    using StableMath for uint256;
    using SafeCast for uint256;

    event RewardAdded(uint256 reward, uint256 platformReward);
    event Staked(address indexed user, uint256 amount, address payer);
    event Withdrawn(address indexed user, uint256 amount);
    event Poked(address indexed user);
    event RewardPaid(address indexed user, uint256 reward, uint256 platformReward);

    /// @notice token the rewards are distributed in. eg MTA
    IERC20 public immutable rewardsToken;
    /// @notice token the platform rewards are distributed in. eg WMATIC
    IERC20 public immutable platformToken;
    /// @notice contract that holds the platform tokens
    PlatformTokenVendor public platformTokenVendor;
    /// @notice total raw balance
    uint256 public totalRaw;

    /// @notice length of each staking period in seconds. 7 days = 604,800; 3 months = 7,862,400
    uint64 public constant DURATION = 7 days;
    /// @notice  Length of token lockup, after rewards are earned
    uint256 public constant LOCKUP = 26 weeks;
    /// @notice  Percentage of earned tokens unlocked immediately
    uint64 public constant UNLOCK = 33e16;

    /// @notice  Timestamp for current period finish
    uint256 public periodFinish;
    /// @notice  Reward rate for the rest of the period
    uint256 public rewardRate;
    /// @notice Platform reward rate for the rest of the period
    uint256 public platformRewardRate;
    /// @notice Last time any user took action
    uint256 public lastUpdateTime;
    /// @notice  Ever increasing rewardPerToken rate, based on % of total supply
    uint256 public rewardPerTokenStored;
    /// @notice Ever increasing platformRewardPerToken rate, based on % of total supply
    uint256 public platformRewardPerTokenStored;

    mapping(address => UserData) public userData;
    /// @notice  Locked reward tracking
    mapping(address => Reward[]) public userRewards;
    mapping(address => uint64) public userClaim;

    struct UserData {
        uint128 rewardPerTokenPaid;
        uint128 rewards;
        uint128 platformRewardPerTokenPaid;
        uint128 platformRewards;
        uint64 lastAction;
        uint64 rewardCount;
    }

    struct Reward {
        uint64 start;
        uint64 finish;
        uint128 rate;
    }

    /**
     * @param _nexus mStable system Nexus address
     * @param _stakingToken token that is being rewarded for being staked. eg MTA, imUSD or fPmUSD/GUSD
     * @param _boostDirector vMTA boost director
     * @param _priceCoeff Rough price of a given LP token, to be used in boost calculations, where $1 = 1e18
     * @param _boostCoeff  Boost coefficent using the the boost formula
     * @param _rewardsToken first token that is being distributed as a reward. eg MTA
     * @param _platformToken second token that is being distributed as a reward. eg FXS for FRAX
     */
    constructor(
        address _nexus,
        address _stakingToken,
        address _boostDirector,
        uint256 _priceCoeff,
        uint256 _boostCoeff,
        address _rewardsToken,
        address _platformToken
    )
        InitializableRewardsDistributionRecipient(_nexus)
        BoostedTokenWrapper(_stakingToken, _boostDirector, _priceCoeff, _boostCoeff)
    {
        rewardsToken = IERC20(_rewardsToken);
        platformToken = IERC20(_platformToken);
    }

    /**
     * @dev Initialization function for upgradable proxy contract.
     *      This function should be called via Proxy just after contract deployment.
     *      To avoid variable shadowing appended `Arg` after arguments name.
     * @param _rewardsDistributorArg mStable Reward Distributor contract address
     * @param _nameArg token name. eg imUSD Vault or GUSD Feeder Pool Vault
     * @param _symbolArg token symbol. eg v-imUSD or v-fPmUSD/GUSD
     */
    function initialize(
        address _rewardsDistributorArg,
        string calldata _nameArg,
        string calldata _symbolArg
    ) external initializer {
        InitializableRewardsDistributionRecipient._initialize(_rewardsDistributorArg);
        BoostedTokenWrapper._initialize(_nameArg, _symbolArg);
        platformTokenVendor = new PlatformTokenVendor(platformToken);
    }

    /**
     * @dev Updates the reward for a given address, before executing function.
     * Locks 80% of new rewards up for 6 months, vesting linearly from (time of last action + 6 months) to
     * (now + 6 months). This allows rewards to be distributed close to how they were accrued, as opposed
     * to locking up for a flat 6 months from the time of this fn call (allowing more passive accrual).
     */
    modifier updateReward(address _account) {
        _updateReward(_account);
        _;
    }

    function _updateReward(address _account) internal {
        uint256 currentTime = block.timestamp;
        uint64 currentTime64 = SafeCast.toUint64(currentTime);

        // Setting of global vars
        (
            uint256 newRewardPerToken,
            uint256 newPlatformRewardPerToken,
            uint256 lastApplicableTime
        ) = _rewardPerToken();
        // If statement protects against loss in initialisation case
        if (newRewardPerToken > 0 || newPlatformRewardPerToken > 0) {
            rewardPerTokenStored = newRewardPerToken;
            platformRewardPerTokenStored = newPlatformRewardPerToken;
            lastUpdateTime = lastApplicableTime;

            // Setting of personal vars based on new globals
            if (_account != address(0)) {
                UserData memory data = userData[_account];
                uint256 earned_ = _earned(
                    _account,
                    data.rewardPerTokenPaid,
                    newRewardPerToken,
                    false
                );
                uint256 platformEarned_ = _earned(
                    _account,
                    data.platformRewardPerTokenPaid,
                    newPlatformRewardPerToken,
                    true
                );

                // If earned == 0, then it must either be the initial stake, or an action in the
                // same block, since new rewards unlock after each block.
                if (earned_ > 0) {
                    uint256 unlocked = earned_.mulTruncate(UNLOCK);
                    uint256 locked = earned_ - unlocked;

                    userRewards[_account].push(
                        Reward({
                            start: SafeCast.toUint64(LOCKUP + data.lastAction),
                            finish: SafeCast.toUint64(LOCKUP + currentTime),
                            rate: SafeCast.toUint128(locked / (currentTime - data.lastAction))
                        })
                    );

                    userData[_account] = UserData({
                        rewardPerTokenPaid: SafeCast.toUint128(newRewardPerToken),
                        rewards: SafeCast.toUint128(unlocked + data.rewards),
                        platformRewardPerTokenPaid: SafeCast.toUint128(newPlatformRewardPerToken),
                        platformRewards: data.platformRewards + SafeCast.toUint128(platformEarned_),
                        lastAction: currentTime64,
                        rewardCount: data.rewardCount + 1
                    });
                } else {
                    userData[_account] = UserData({
                        rewardPerTokenPaid: SafeCast.toUint128(newRewardPerToken),
                        rewards: data.rewards,
                        platformRewardPerTokenPaid: SafeCast.toUint128(newPlatformRewardPerToken),
                        platformRewards: data.platformRewards + SafeCast.toUint128(platformEarned_),
                        lastAction: currentTime64,
                        rewardCount: data.rewardCount
                    });
                }
            }
        } else if (_account != address(0)) {
            // This should only be hit once, for first staker in initialisation case
            userData[_account].lastAction = currentTime64;
        }
    }

    /** @dev Updates the boost for a given address, after the rest of the function has executed */
    modifier updateBoost(address _account) {
        _;
        _setBoost(_account);
    }

    /***************************************
                ACTIONS - EXTERNAL
    ****************************************/

    /**
     * @dev Stakes a given amount of the StakingToken for the sender
     * @param _amount Units of StakingToken
     */
    function stake(uint256 _amount)
        external
        override
        updateReward(msg.sender)
        updateBoost(msg.sender)
    {
        _stake(msg.sender, _amount);
    }

    /**
     * @dev Stakes a given amount of the StakingToken for a given beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function stake(address _beneficiary, uint256 _amount)
        external
        override
        updateReward(_beneficiary)
        updateBoost(_beneficiary)
    {
        _stake(_beneficiary, _amount);
    }

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function exit() external override updateReward(msg.sender) updateBoost(msg.sender) {
        _withdraw(rawBalanceOf(msg.sender));
        (uint256 first, uint256 last) = _unclaimedEpochs(msg.sender);
        _claimRewards(first, last);
    }

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function exit(uint256 _first, uint256 _last)
        external
        override
        updateReward(msg.sender)
        updateBoost(msg.sender)
    {
        _withdraw(rawBalanceOf(msg.sender));
        _claimRewards(_first, _last);
    }

    /**
     * @dev Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdraw(uint256 _amount)
        external
        override
        updateReward(msg.sender)
        updateBoost(msg.sender)
    {
        _withdraw(_amount);
    }

    /**
     * @dev Claims only the tokens that have been immediately unlocked, not including
     * those that are in the lockers.
     */
    function claimReward() external override updateReward(msg.sender) updateBoost(msg.sender) {
        uint256 unlocked = userData[msg.sender].rewards;
        userData[msg.sender].rewards = 0;

        if (unlocked > 0) {
            rewardsToken.safeTransfer(msg.sender, unlocked);
        }

        uint256 platformReward = _claimPlatformReward();

        emit RewardPaid(msg.sender, unlocked, platformReward);
    }

    /**
     * @dev Claims all unlocked rewards for sender.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function claimRewards() external override updateReward(msg.sender) updateBoost(msg.sender) {
        (uint256 first, uint256 last) = _unclaimedEpochs(msg.sender);

        _claimRewards(first, last);
    }

    /**
     * @dev Claims all unlocked rewards for sender. Both immediately unlocked
     * rewards and also locked rewards past their time lock.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function claimRewards(uint256 _first, uint256 _last)
        external
        override
        updateReward(msg.sender)
        updateBoost(msg.sender)
    {
        _claimRewards(_first, _last);
    }

    /**
     * @dev Pokes a given account to reset the boost
     */
    function pokeBoost(address _account)
        external
        override
        updateReward(_account)
        updateBoost(_account)
    {
        emit Poked(_account);
    }

    /***************************************
                ACTIONS - INTERNAL
    ****************************************/

    /**
     * @dev Claims all unlocked rewards for sender. Both immediately unlocked
     * rewards and also locked rewards past their time lock.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function _claimRewards(uint256 _first, uint256 _last) internal {
        (uint256 unclaimed, uint256 lastTimestamp) = _unclaimedRewards(msg.sender, _first, _last);
        userClaim[msg.sender] = uint64(lastTimestamp);

        uint256 unlocked = userData[msg.sender].rewards;
        userData[msg.sender].rewards = 0;

        uint256 total = unclaimed + unlocked;

        if (total > 0) {
            rewardsToken.safeTransfer(msg.sender, total);
        }

        uint256 platformReward = _claimPlatformReward();

        emit RewardPaid(msg.sender, total, platformReward);
    }

    /**
     * @dev Claims any outstanding platform reward tokens
     */
    function _claimPlatformReward() internal returns (uint256) {
        uint256 platformReward = userData[msg.sender].platformRewards;
        if (platformReward > 0) {
            userData[msg.sender].platformRewards = 0;
            platformToken.safeTransferFrom(
                address(platformTokenVendor),
                msg.sender,
                platformReward
            );
        }
        return platformReward;
    }

    /**
     * @dev Internally stakes an amount by depositing from sender,
     * and crediting to the specified beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function _stake(address _beneficiary, uint256 _amount) internal {
        require(_amount > 0, "Cannot stake 0");
        require(_beneficiary != address(0), "Invalid beneficiary address");

        _stakeRaw(_beneficiary, _amount);
        totalRaw += _amount;
        emit Staked(_beneficiary, _amount, msg.sender);
    }

    /**
     * @dev Withdraws raw units from the sender
     * @param _amount      Units of StakingToken
     */
    function _withdraw(uint256 _amount) internal {
        require(_amount > 0, "Cannot withdraw 0");
        _withdrawRaw(_amount);
        totalRaw -= _amount;
        emit Withdrawn(msg.sender, _amount);
    }

    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @dev Gets the RewardsToken
     */
    function getRewardToken()
        external
        view
        override(IRewardsDistributionRecipient, IRewardsRecipientWithPlatformToken)
        returns (IERC20)
    {
        return rewardsToken;
    }

    /**
     * @dev Gets the PlatformToken
     */
    function getPlatformToken() external view override returns (IERC20) {
        return platformToken;
    }

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return StableMath.min(block.timestamp, periodFinish);
    }

    /**
     * @dev Calculates the amount of unclaimed rewards per token since last update,
     * and sums with stored to give the new cumulative reward per token
     * @return 'Reward' per staked token
     */
    function rewardPerToken() public view override returns (uint256, uint256) {
        (uint256 rewardPerToken_, uint256 platformRewardPerToken_, ) = _rewardPerToken();
        return (rewardPerToken_, platformRewardPerToken_);
    }

    function _rewardPerToken()
        internal
        view
        returns (
            uint256 rewardPerToken_,
            uint256 platformRewardPerToken_,
            uint256 lastTimeRewardApplicable_
        )
    {
        uint256 lastApplicableTime = lastTimeRewardApplicable(); // + 1 SLOAD
        uint256 timeDelta = lastApplicableTime - lastUpdateTime; // + 1 SLOAD
        // If this has been called twice in the same block, shortcircuit to reduce gas
        if (timeDelta == 0) {
            return (rewardPerTokenStored, platformRewardPerTokenStored, lastApplicableTime);
        }
        // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 rewardUnitsToDistribute = rewardRate * timeDelta; // + 1 SLOAD
        uint256 platformRewardUnitsToDistribute = platformRewardRate * timeDelta; // + 1 SLOAD
        // If there is no StakingToken liquidity, avoid div(0)
        // If there is nothing to distribute, short circuit
        if (
            totalSupply() == 0 ||
            (rewardUnitsToDistribute == 0 && platformRewardUnitsToDistribute == 0)
        ) {
            return (rewardPerTokenStored, platformRewardPerTokenStored, lastApplicableTime);
        }
        // new reward units per token = (rewardUnitsToDistribute * 1e18) / totalTokens
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(totalSupply());
        uint256 platformUnitsToDistributePerToken = platformRewardUnitsToDistribute.divPrecisely(
            totalRaw
        );
        // return summed rate
        return (
            rewardPerTokenStored + unitsToDistributePerToken,
            platformRewardPerTokenStored + platformUnitsToDistributePerToken,
            lastApplicableTime
        ); // + 1 SLOAD
    }

    /**
     * @dev Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
     * does NOT include the majority of rewards which will be locked up.
     * @param _account User address
     * @return Total reward amount earned
     * @return Platform reward claimable
     */
    function earned(address _account) public view override returns (uint256, uint256) {
        (uint256 rewardPerToken_, uint256 platformRewardPerToken_) = rewardPerToken();
        uint256 newEarned = _earned(
            _account,
            userData[_account].rewardPerTokenPaid,
            rewardPerToken_,
            false
        );
        uint256 immediatelyUnlocked = newEarned.mulTruncate(UNLOCK);
        return (
            immediatelyUnlocked + userData[_account].rewards,
            _earned(
                _account,
                userData[_account].platformRewardPerTokenPaid,
                platformRewardPerToken_,
                true
            )
        );
    }

    /**
     * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
     * and those that have passed their time lock.
     * @param _account User address
     * @return amount Total units of unclaimed rewards
     * @return first Index of the first userReward that has unlocked
     * @return last Index of the last userReward that has unlocked
     */
    function unclaimedRewards(address _account)
        external
        view
        override
        returns (
            uint256 amount,
            uint256 first,
            uint256 last,
            uint256 platformAmount
        )
    {
        (first, last) = _unclaimedEpochs(_account);
        (uint256 unlocked, ) = _unclaimedRewards(_account, first, last);
        (uint256 earned_, uint256 platformEarned_) = earned(_account);
        amount = unlocked + earned_;
        platformAmount = platformEarned_;
    }

    /** @dev Returns only the most recently earned rewards */
    function _earned(
        address _account,
        uint256 _userRewardPerTokenPaid,
        uint256 _currentRewardPerToken,
        bool _useRawBalance
    ) internal view returns (uint256) {
        // current rate per token - rate user previously received
        uint256 userRewardDelta = _currentRewardPerToken - _userRewardPerTokenPaid;
        // Short circuit if there is nothing new to distribute
        if (userRewardDelta == 0) {
            return 0;
        }
        // new reward = staked tokens * difference in rate
        uint256 bal = _useRawBalance ? rawBalanceOf(_account) : balanceOf(_account);
        return bal.mulTruncate(userRewardDelta);
    }

    /**
     * @dev Gets the first and last indexes of array elements containing unclaimed rewards
     */
    function _unclaimedEpochs(address _account)
        internal
        view
        returns (uint256 first, uint256 last)
    {
        uint64 lastClaim = userClaim[_account];

        uint256 firstUnclaimed = _findFirstUnclaimed(lastClaim, _account);
        uint256 lastUnclaimed = _findLastUnclaimed(_account);

        return (firstUnclaimed, lastUnclaimed);
    }

    /**
     * @dev Sums the cumulative rewards from a valid range
     */
    function _unclaimedRewards(
        address _account,
        uint256 _first,
        uint256 _last
    ) internal view returns (uint256 amount, uint256 latestTimestamp) {
        uint256 currentTime = block.timestamp;
        uint64 lastClaim = userClaim[_account];

        // Check for no rewards unlocked
        uint256 totalLen = userRewards[_account].length;
        if (_first == 0 && _last == 0) {
            if (totalLen == 0 || currentTime <= userRewards[_account][0].start) {
                return (0, currentTime);
            }
        }
        // If there are previous unlocks, check for claims that would leave them untouchable
        if (_first > 0) {
            require(
                lastClaim >= userRewards[_account][_first - 1].finish,
                "Invalid _first arg: Must claim earlier entries"
            );
        }

        uint256 count = _last - _first + 1;
        for (uint256 i = 0; i < count; i++) {
            uint256 id = _first + i;
            Reward memory rwd = userRewards[_account][id];

            require(currentTime >= rwd.start && lastClaim <= rwd.finish, "Invalid epoch");

            uint256 endTime = StableMath.min(rwd.finish, currentTime);
            uint256 startTime = StableMath.max(rwd.start, lastClaim);
            uint256 unclaimed = (endTime - startTime) * rwd.rate;

            amount += unclaimed;
        }

        // Calculate last relevant timestamp here to allow users to avoid issue of OOG errors
        // by claiming rewards in batches.
        latestTimestamp = StableMath.min(currentTime, userRewards[_account][_last].finish);
    }

    /**
     * @dev Uses binarysearch to find the unclaimed lockups for a given account
     */
    function _findFirstUnclaimed(uint64 _lastClaim, address _account)
        internal
        view
        returns (uint256 first)
    {
        uint256 len = userRewards[_account].length;
        if (len == 0) return 0;
        // Binary search
        uint256 min = 0;
        uint256 max = len - 1;
        // Will be always enough for 128-bit numbers
        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) break;
            uint256 mid = (min + max + 1) / 2;
            if (_lastClaim > userRewards[_account][mid].start) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    /**
     * @dev Uses binarysearch to find the unclaimed lockups for a given account
     */
    function _findLastUnclaimed(address _account) internal view returns (uint256 first) {
        uint256 len = userRewards[_account].length;
        if (len == 0) return 0;
        // Binary search
        uint256 min = 0;
        uint256 max = len - 1;
        // Will be always enough for 128-bit numbers
        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) break;
            uint256 mid = (min + max + 1) / 2;
            if (block.timestamp > userRewards[_account][mid].start) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    /***************************************
                    ADMIN
    ****************************************/

    /**
     * @dev Notifies the contract that new rewards have been added.
     * Calculates an updated rewardRate based on the rewards in period.
     * @param _reward Units of RewardToken that have been added to the pool
     */
    function notifyRewardAmount(uint256 _reward)
        external
        override(IRewardsDistributionRecipient, IRewardsRecipientWithPlatformToken)
        onlyRewardsDistributor
        updateReward(address(0))
    {
        require(_reward < 1e24, "Cannot notify with more than a million units");

        uint256 newPlatformRewards = platformToken.balanceOf(address(this));
        if (newPlatformRewards > 0) {
            platformToken.safeTransfer(address(platformTokenVendor), newPlatformRewards);
        }

        uint256 currentTime = block.timestamp;
        // If previous period over, reset rewardRate
        if (currentTime >= periodFinish) {
            rewardRate = _reward / DURATION;
            platformRewardRate = newPlatformRewards / DURATION;
        }
        // If additional reward to existing period, calc sum
        else {
            uint256 remaining = periodFinish - currentTime;

            uint256 leftoverReward = remaining * rewardRate;
            rewardRate = (_reward + leftoverReward) / DURATION;

            uint256 leftoverPlatformReward = remaining * platformRewardRate;
            platformRewardRate = (newPlatformRewards + leftoverPlatformReward) / DURATION;
        }

        lastUpdateTime = currentTime;
        periodFinish = currentTime + DURATION;

        emit RewardAdded(_reward, newPlatformRewards);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;

    function getRewardToken() external view returns (IERC20);
}

interface IRewardsRecipientWithPlatformToken {
    function notifyRewardAmount(uint256 reward) external;

    function getRewardToken() external view returns (IERC20);

    function getPlatformToken() external view returns (IERC20);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBoostedDualVaultWithLockup {
    /**
     * @dev Stakes a given amount of the StakingToken for the sender
     * @param _amount Units of StakingToken
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Stakes a given amount of the StakingToken for a given beneficiary
     * @param _beneficiary Staked tokens are credited to this address
     * @param _amount      Units of StakingToken
     */
    function stake(address _beneficiary, uint256 _amount) external;

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function exit() external;

    /**
     * @dev Withdraws stake from pool and claims any unlocked rewards.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function exit(uint256 _first, uint256 _last) external;

    /**
     * @dev Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Claims only the tokens that have been immediately unlocked, not including
     * those that are in the lockers.
     */
    function claimReward() external;

    /**
     * @dev Claims all unlocked rewards for sender.
     * Note, this function is costly - the args for _claimRewards
     * should be determined off chain and then passed to other fn
     */
    function claimRewards() external;

    /**
     * @dev Claims all unlocked rewards for sender. Both immediately unlocked
     * rewards and also locked rewards past their time lock.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function claimRewards(uint256 _first, uint256 _last) external;

    /**
     * @dev Pokes a given account to reset the boost
     */
    function pokeBoost(address _account) external;

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @dev Calculates the amount of unclaimed rewards per token since last update,
     * and sums with stored to give the new cumulative reward per token
     * @return 'Reward' per staked token
     */
    function rewardPerToken() external view returns (uint256, uint256);

    /**
     * @dev Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
     * does NOT include the majority of rewards which will be locked up.
     * @param _account User address
     * @return Total reward amount earned
     */
    function earned(address _account) external view returns (uint256, uint256);

    /**
     * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
     * and those that have passed their time lock.
     * @param _account User address
     * @return amount Total units of unclaimed rewards
     * @return first Index of the first userReward that has unlocked
     * @return last Index of the last userReward that has unlocked
     */
    function unclaimedRewards(address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 first,
            uint256 last,
            uint256 platformAmount
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { ImmutableModule } from "../shared/ImmutableModule.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IRewardsDistributionRecipient } from "../interfaces/IRewardsDistributionRecipient.sol";

/**
 * @title  RewardsDistributionRecipient
 * @author Originally: Synthetix (forked from /Synthetixio/synthetix/contracts/RewardsDistributionRecipient.sol)
 *         Changes by: mStable
 * @notice RewardsDistributionRecipient gets notified of additional rewards by the rewardsDistributor
 * @dev    Changes: Addition of Module and abstract `getRewardToken` func + cosmetic
 */
abstract contract InitializableRewardsDistributionRecipient is
    IRewardsDistributionRecipient,
    ImmutableModule
{
    // This address has the ability to distribute the rewards
    address public rewardsDistributor;

    constructor(address _nexus) ImmutableModule(_nexus) {}

    /** @dev Recipient is a module, governed by mStable governance */
    function _initialize(address _rewardsDistributor) internal virtual {
        rewardsDistributor = _rewardsDistributor;
    }

    /**
     * @dev Only the rewards distributor can notify about rewards
     */
    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "Caller is not reward distributor");
        _;
    }

    /**
     * @dev Change the rewardsDistributor - only called by mStable governor
     * @param _rewardsDistributor   Address of the new distributor
     */
    function setRewardsDistribution(address _rewardsDistributor) external onlyGovernor {
        rewardsDistributor = _rewardsDistributor;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

// Internal
import { IBoostDirector } from "../../interfaces/IBoostDirector.sol";

// Libs
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { InitializableReentrancyGuard } from "../../shared/InitializableReentrancyGuard.sol";
import { StableMath } from "../../shared/StableMath.sol";
import { Root } from "../../shared/Root.sol";

/**
 * @title  BoostedTokenWrapper
 * @author mStable
 * @notice Wrapper to facilitate tracking of staked balances, applying a boost
 * @dev    Forked from rewards/staking/StakingTokenWrapper.sol
 *         Changes:
 *          - Adding `_boostedBalances` and `_totalBoostedSupply`
 *          - Implemting of a `_setBoost` hook to calculate/apply a users boost
 */
contract BoostedTokenWrapper is InitializableReentrancyGuard {
    using StableMath for uint256;
    using SafeERC20 for IERC20;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string private _name;
    string private _symbol;

    IERC20 public immutable stakingToken;
    IBoostDirector public immutable boostDirector;

    uint256 private _totalBoostedSupply;
    mapping(address => uint256) private _boostedBalances;
    mapping(address => uint256) private _rawBalances;

    // Vars for use in the boost calculations
    uint256 private constant MIN_DEPOSIT = 1e18;
    uint256 private constant MAX_VMTA = 600000e18;
    uint256 private constant MAX_BOOST = 3e18;
    uint256 private constant MIN_BOOST = 1e18;
    uint256 private constant FLOOR = 98e16;
    uint256 public immutable boostCoeff; // scaled by 10
    uint256 public immutable priceCoeff;

    /**
     * @dev TokenWrapper constructor
     * @param _stakingToken Wrapped token to be staked
     * @param _boostDirector vMTA boost director
     * @param _priceCoeff Rough price of a given LP token, to be used in boost calculations, where $1 = 1e18
     * @param _boostCoeff  Boost coefficent using the the boost formula
     */
    constructor(
        address _stakingToken,
        address _boostDirector,
        uint256 _priceCoeff,
        uint256 _boostCoeff
    ) {
        stakingToken = IERC20(_stakingToken);
        boostDirector = IBoostDirector(_boostDirector);
        priceCoeff = _priceCoeff;
        boostCoeff = _boostCoeff;
    }

    /**
     * @param _nameArg token name. eg imUSD Vault or GUSD Feeder Pool Vault
     * @param _symbolArg token symbol. eg v-imUSD or v-fPmUSD/GUSD
     */
    function _initialize(string memory _nameArg, string memory _symbolArg) internal {
        _initializeReentrancyGuard();
        _name = _nameArg;
        _symbol = _symbolArg;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev Get the total boosted amount
     * @return uint256 total supply
     */
    function totalSupply() public view returns (uint256) {
        return _totalBoostedSupply;
    }

    /**
     * @dev Get the boosted balance of a given account
     * @param _account User for which to retrieve balance
     */
    function balanceOf(address _account) public view returns (uint256) {
        return _boostedBalances[_account];
    }

    /**
     * @dev Get the RAW balance of a given account
     * @param _account User for which to retrieve balance
     */
    function rawBalanceOf(address _account) public view returns (uint256) {
        return _rawBalances[_account];
    }

    /**
     * @dev Read the boost for the given address
     * @param _account User for which to return the boost
     * @return boost where 1x == 1e18
     */
    function getBoost(address _account) public view returns (uint256) {
        return balanceOf(_account).divPrecisely(rawBalanceOf(_account));
    }

    /**
     * @dev Deposits a given amount of StakingToken from sender
     * @param _amount Units of StakingToken
     */
    function _stakeRaw(address _beneficiary, uint256 _amount) internal nonReentrant {
        _rawBalances[_beneficiary] += _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Withdraws a given stake from sender
     * @param _amount Units of StakingToken
     */
    function _withdrawRaw(uint256 _amount) internal nonReentrant {
        _rawBalances[msg.sender] -= _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Updates the boost for the given address according to the formula
     * boost = min(0.5 + c * vMTA_balance / imUSD_locked^(7/8), 1.5)
     * If rawBalance <= MIN_DEPOSIT, boost is 0
     * @param _account User for which to update the boost
     */
    function _setBoost(address _account) internal {
        uint256 rawBalance = _rawBalances[_account];
        uint256 boostedBalance = _boostedBalances[_account];
        uint256 boost = MIN_BOOST;

        // Check whether balance is sufficient
        // is_boosted is used to minimize gas usage
        uint256 scaledBalance = (rawBalance * priceCoeff) / 1e18;
        if (scaledBalance >= MIN_DEPOSIT) {
            uint256 votingWeight = boostDirector.getBalance(_account);
            boost = _computeBoost(scaledBalance, votingWeight);
        }

        uint256 newBoostedBalance = rawBalance.mulTruncate(boost);

        if (newBoostedBalance != boostedBalance) {
            _totalBoostedSupply = _totalBoostedSupply - boostedBalance + newBoostedBalance;
            _boostedBalances[_account] = newBoostedBalance;

            if (newBoostedBalance > boostedBalance) {
                emit Transfer(address(0), _account, newBoostedBalance - boostedBalance);
            } else {
                emit Transfer(_account, address(0), boostedBalance - newBoostedBalance);
            }
        }
    }

    /**
     * @dev Computes the boost for
     * boost = min(m, max(1, 0.95 + c * min(voting_weight, f) / deposit^(3/4)))
     * @param _scaledDeposit deposit amount in terms of USD
     */
    function _computeBoost(uint256 _scaledDeposit, uint256 _votingWeight)
        private
        view
        returns (uint256 boost)
    {
        if (_votingWeight == 0) return MIN_BOOST;

        // Compute balance to the power 3/4
        uint256 sqrt1 = Root.sqrt(_scaledDeposit * 1e6);
        uint256 sqrt2 = Root.sqrt(sqrt1);
        uint256 denominator = sqrt1 * sqrt2;
        boost =
            (((StableMath.min(_votingWeight, MAX_VMTA) * boostCoeff) / 10) * 1e18) /
            denominator;
        boost = StableMath.min(MAX_BOOST, StableMath.max(MIN_BOOST, FLOOR + boost));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MassetHelpers } from "../../shared/MassetHelpers.sol";

/**
 * @title  PlatformTokenVendor
 * @author mStable
 * @notice Stores platform tokens for distributing to StakingReward participants
 * @dev    Only deploy this during the constructor of a given StakingReward contract
 */
contract PlatformTokenVendor {
    IERC20 public immutable platformToken;
    address public immutable parentStakingContract;

    /** @dev Simple constructor that stores the parent address */
    constructor(IERC20 _platformToken) {
        parentStakingContract = msg.sender;
        platformToken = _platformToken;
        MassetHelpers.safeInfiniteApprove(address(_platformToken), msg.sender);
    }

    /**
     * @dev Re-approves the StakingReward contract to spend the platform token.
     * Just incase for some reason approval has been reset.
     */
    function reApproveOwner() external {
        MassetHelpers.safeInfiniteApprove(address(platformToken), parentStakingContract);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title   StableMath
 * @author  mStable
 * @notice  A library providing safe mathematical operations to multiply and
 *          divide with standardised precision.
 * @dev     Derives from OpenZeppelin's SafeMath lib and uses generic system
 *          wide variables for managing precision.
 */
library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Token Ratios are used when converting between units of bAsset, mAsset and MTA
     * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
     * bAsset ratio unit for use in exact calculations,
     * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
     */
    uint256 private constant RATIO_SCALE = 1e8;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Provides an interface to the ratio unit
     * @return Ratio scale unit (1e8 or 1 * 10**8)
     */
    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e36 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                  RATIO FUNCS
    ****************************************/

    /**
     * @dev Multiplies and truncates a token ratio, essentially flooring the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand operand to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the two inputs and then dividing by the ratio scale
     */
    function mulRatioTruncate(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    /**
     * @dev Multiplies and truncates a token ratio, rounding up the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand input to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              ratio scale, rounded up to the closest base unit.
     */
    function mulRatioTruncateCeil(uint256 x, uint256 ratio) internal pure returns (uint256) {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x * ratio;
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled + RATIO_SCALE - 1;
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil / RATIO_SCALE;
    }

    /**
     * @dev Precisely divides two ratioed units, by first scaling the left hand operand
     *      i.e. How much bAsset is this mAsset worth?
     * @param x     Left hand operand in division
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divRatioPrecisely(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        // e.g. 1e14 * 1e8 = 1e22
        // return 1e22 / 1e12 = 1e10
        return (x * RATIO_SCALE) / ratio;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { ModuleKeys } from "./ModuleKeys.sol";
import { INexus } from "../interfaces/INexus.sol";

/**
 * @title   ImmutableModule
 * @author  mStable
 * @dev     Subscribes to module updates from a given publisher and reads from its registry.
 *          Contract is used for upgradable proxy contracts.
 */
abstract contract ImmutableModule is ModuleKeys {
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return SavingsManager Module address from the Nexus
     * @return Address of the SavingsManager Module contract
     */
    function _savingsManager() internal view returns (address) {
        return nexus.getModule(KEY_SAVINGS_MANAGER);
    }

    /**
     * @dev Return Recollateraliser Module address from the Nexus
     * @return  Address of the Recollateraliser Module contract (Phase 2)
     */
    function _recollateraliser() internal view returns (address) {
        return nexus.getModule(KEY_RECOLLATERALISER);
    }

    /**
     * @dev Return Liquidator Module address from the Nexus
     * @return  Address of the Liquidator Module contract
     */
    function _liquidator() internal view returns (address) {
        return nexus.getModule(KEY_LIQUIDATOR);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Nexus
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title  ModuleKeys
 * @author mStable
 * @notice Provides system wide access to the byte32 represntations of system modules
 *         This allows each system module to be able to reference and update one another in a
 *         friendly way
 * @dev    keccak256() values are hardcoded to avoid re-evaluation of the constants at runtime.
 */
contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title INexus
 * @dev Basic interface for interacting with the Nexus i.e. SystemKernel
 */
interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

interface IBoostDirector {
    function getBalance(address _user) external returns (uint256);

    function setDirection(
        address _old,
        address _new,
        bool _pokeNew
    ) external;

    function whitelistVaults(address[] calldata _vaults) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract InitializableReentrancyGuard {
    bool private _notEntered;

    function _initializeReentrancyGuard() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

library Root {
    /**
     * @dev Returns the square root of a given number
     * @param x Input
     * @return y Square root of Input
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint256(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title   MassetHelpers
 * @author  mStable
 * @notice  Helper functions to facilitate minting and redemption from off chain
 * @dev     VERSION: 1.0
 *          DATE:    2020-03-28
 */
library MassetHelpers {
    using SafeERC20 for IERC20;

    function transferReturnBalance(
        address _sender,
        address _recipient,
        address _bAsset,
        uint256 _qty
    ) internal returns (uint256 receivedQty, uint256 recipientBalance) {
        uint256 balBefore = IERC20(_bAsset).balanceOf(_recipient);
        IERC20(_bAsset).safeTransferFrom(_sender, _recipient, _qty);
        recipientBalance = IERC20(_bAsset).balanceOf(_recipient);
        receivedQty = recipientBalance - balBefore;
    }

    function safeInfiniteApprove(address _asset, address _spender) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, 2**256 - 1);
    }
}