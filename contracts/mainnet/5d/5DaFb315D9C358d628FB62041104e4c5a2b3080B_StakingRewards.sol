// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "@bancor/token-governance/contracts/ITokenGovernance.sol";

import "../utility/ContractRegistryClient.sol";
import "../utility/Utils.sol";
import "../utility/Time.sol";
import "../utility/interfaces/ICheckpointStore.sol";

import "../token/ReserveToken.sol";

import "../liquidity-protection/interfaces/ILiquidityProtection.sol";

import "./interfaces/IStakingRewards.sol";

/**
 * @dev This contract manages the distribution of the staking rewards
 */
contract StakingRewards is IStakingRewards, AccessControl, Time, Utils, ContractRegistryClient {
    using SafeMath for uint256;
    using ReserveToken for IReserveToken;
    using SafeERC20 for IERC20;
    using SafeERC20Ex for IERC20;

    // the role is used to globally govern the contract and its governing roles.
    bytes32 public constant ROLE_SUPERVISOR = keccak256("ROLE_SUPERVISOR");

    // the roles is used to restrict who is allowed to publish liquidity protection events.
    bytes32 public constant ROLE_PUBLISHER = keccak256("ROLE_PUBLISHER");

    // the roles is used to restrict who is allowed to update/cache provider rewards.
    bytes32 public constant ROLE_UPDATER = keccak256("ROLE_UPDATER");

    // the weekly 25% increase of the rewards multiplier (in units of PPM).
    uint32 private constant MULTIPLIER_INCREMENT = PPM_RESOLUTION / 4;

    // the maximum weekly 200% rewards multiplier (in units of PPM).
    uint32 private constant MAX_MULTIPLIER = PPM_RESOLUTION + MULTIPLIER_INCREMENT * 4;

    // the rewards halving factor we need to take into account during the sanity verification process.
    uint8 private constant REWARDS_HALVING_FACTOR = 4;

    // since we will be dividing by the total amount of protected tokens in units of wei, we can encounter cases
    // where the total amount in the denominator is higher than the product of the rewards rate and staking duration. In
    // order to avoid this imprecision, we will amplify the reward rate by the units amount.
    uint256 private constant REWARD_RATE_FACTOR = 1e18;

    uint256 private constant MAX_UINT256 = uint256(-1);

    // the staking rewards settings.
    IStakingRewardsStore private immutable _store;

    // the permissioned wrapper around the network token which should allow this contract to mint staking rewards.
    ITokenGovernance private immutable _networkTokenGovernance;

    // the address of the network token.
    IERC20 private immutable _networkToken;

    // the checkpoint store recording last protected position removal times.
    ICheckpointStore private immutable _lastRemoveTimes;

    /**
     * @dev initializes a new StakingRewards contract
     */
    constructor(
        IStakingRewardsStore store,
        ITokenGovernance networkTokenGovernance,
        ICheckpointStore lastRemoveTimes,
        IContractRegistry registry
    )
        public
        validAddress(address(store))
        validAddress(address(networkTokenGovernance))
        validAddress(address(lastRemoveTimes))
        ContractRegistryClient(registry)
    {
        _store = store;
        _networkTokenGovernance = networkTokenGovernance;
        _networkToken = networkTokenGovernance.token();
        _lastRemoveTimes = lastRemoveTimes;

        // set up administrative roles.
        _setRoleAdmin(ROLE_SUPERVISOR, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_PUBLISHER, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_UPDATER, ROLE_SUPERVISOR);

        // allow the deployer to initially govern the contract.
        _setupRole(ROLE_SUPERVISOR, _msgSender());
    }

    modifier onlyPublisher() {
        _onlyPublisher();
        _;
    }

    function _onlyPublisher() internal view {
        require(hasRole(ROLE_PUBLISHER, msg.sender), "ERR_ACCESS_DENIED");
    }

    modifier onlyUpdater() {
        _onlyUpdater();
        _;
    }

    function _onlyUpdater() internal view {
        require(hasRole(ROLE_UPDATER, msg.sender), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev liquidity provision notification callback. The callback should be called *before* the liquidity is added in
     * the LP contract
     *
     * Requirements:
     *
     * - the caller must have the ROLE_PUBLISHER role
     */
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256, /* poolAmount */
        uint256 /* reserveAmount */
    ) external override onlyPublisher validExternalAddress(provider) {
        IDSToken poolToken = IDSToken(address(poolAnchor));
        PoolProgram memory program = _poolProgram(poolToken);
        if (program.startTime == 0) {
            return;
        }

        _updateRewards(provider, poolToken, reserveToken, program, _liquidityProtectionStats());
    }

    /**
     * @dev liquidity removal callback. The callback must be called *before* the liquidity is removed in the LP
     * contract
     *
     * Requirements:
     *
     * - the caller must have the ROLE_PUBLISHER role
     */
    function onRemovingLiquidity(
        uint256, /* id */
        address provider,
        IConverterAnchor, /* poolAnchor */
        IReserveToken, /* reserveToken */
        uint256, /* poolAmount */
        uint256 /* reserveAmount */
    ) external override onlyPublisher validExternalAddress(provider) {
        ILiquidityProtectionStats lpStats = _liquidityProtectionStats();

        // make sure that all pending rewards are properly stored for future claims, with retroactive rewards
        // multipliers.
        _storeRewards(provider, lpStats.providerPools(provider), lpStats);
    }

    /**
     * @dev returns the staking rewards store
     */
    function store() external view override returns (IStakingRewardsStore) {
        return _store;
    }

    /**
     * @dev returns specific provider's pending rewards for all participating pools
     */
    function pendingRewards(address provider) external view override returns (uint256) {
        return _pendingRewards(provider, _liquidityProtectionStats());
    }

    /**
     * @dev returns specific provider's pending rewards for a specific participating pool
     */
    function pendingPoolRewards(address provider, IDSToken poolToken) external view override returns (uint256) {
        return _pendingRewards(provider, poolToken, _liquidityProtectionStats());
    }

    /**
     * @dev returns specific provider's pending rewards for a specific participating pool/reserve
     */
    function pendingReserveRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    ) external view override returns (uint256) {
        PoolProgram memory program = _poolProgram(poolToken);

        return _pendingRewards(provider, poolToken, reserveToken, program, _liquidityProtectionStats());
    }

    /**
     * @dev returns the current rewards multiplier for a provider in a given pool
     */
    function rewardsMultiplier(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    ) external view override returns (uint32) {
        ProviderRewards memory providerRewards = _providerRewards(provider, poolToken, reserveToken);
        PoolProgram memory program = _poolProgram(poolToken);
        return _rewardsMultiplier(provider, providerRewards.effectiveStakingTime, program);
    }

    /**
     * @dev returns specific provider's total claimed rewards from all participating pools
     */
    function totalClaimedRewards(address provider) external view override returns (uint256) {
        uint256 totalRewards = 0;

        ILiquidityProtectionStats lpStats = _liquidityProtectionStats();
        IDSToken[] memory poolTokens = lpStats.providerPools(provider);

        for (uint256 i = 0; i < poolTokens.length; ++i) {
            IDSToken poolToken = poolTokens[i];
            PoolProgram memory program = _poolProgram(poolToken);

            for (uint256 j = 0; j < program.reserveTokens.length; ++j) {
                IReserveToken reserveToken = program.reserveTokens[j];

                ProviderRewards memory providerRewards = _providerRewards(provider, poolToken, reserveToken);

                totalRewards = totalRewards.add(providerRewards.totalClaimedRewards);
            }
        }

        return totalRewards;
    }

    /**
     * @dev claims pending rewards from all participating pools
     */
    function claimRewards() external override returns (uint256) {
        return _claimPendingRewards(msg.sender, _liquidityProtectionStats());
    }

    /**
     * @dev stakes specific pending rewards from all participating pools
     */
    function stakeRewards(uint256 maxAmount, IDSToken poolToken) external override returns (uint256, uint256) {
        return _stakeRewards(msg.sender, maxAmount, poolToken, _liquidityProtectionStats());
    }

    /**
     * @dev store pending rewards for a list of providers in a specific pool for future claims
     *
     * Requirements:
     *
     * - the caller must have the ROLE_UPDATER role
     */
    function storePoolRewards(address[] calldata providers, IDSToken poolToken) external override onlyUpdater {
        ILiquidityProtectionStats lpStats = _liquidityProtectionStats();
        PoolProgram memory program = _poolProgram(poolToken);

        for (uint256 i = 0; i < providers.length; ++i) {
            for (uint256 j = 0; j < program.reserveTokens.length; ++j) {
                _storeRewards(providers[i], poolToken, program.reserveTokens[j], program, lpStats, false);
            }
        }
    }

    /**
     * @dev returns specific provider's pending rewards for all participating pools
     */
    function _pendingRewards(address provider, ILiquidityProtectionStats lpStats) private view returns (uint256) {
        return _pendingRewards(provider, lpStats.providerPools(provider), lpStats);
    }

    /**
     * @dev returns specific provider's pending rewards for a specific list of participating pools
     */
    function _pendingRewards(
        address provider,
        IDSToken[] memory poolTokens,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        uint256 reward = 0;

        uint256 length = poolTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 poolReward = _pendingRewards(provider, poolTokens[i], lpStats);
            reward = reward.add(poolReward);
        }

        return reward;
    }

    /**
     * @dev returns specific provider's pending rewards for a specific pool
     */
    function _pendingRewards(
        address provider,
        IDSToken poolToken,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        uint256 reward = 0;
        PoolProgram memory program = _poolProgram(poolToken);

        for (uint256 i = 0; i < program.reserveTokens.length; ++i) {
            uint256 reserveReward = _pendingRewards(provider, poolToken, program.reserveTokens[i], program, lpStats);
            reward = reward.add(reserveReward);
        }

        return reward;
    }

    /**
     * @dev returns specific provider's pending rewards for a specific pool/reserve
     */

    function _pendingRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        if (!_isProgramValid(reserveToken, program)) {
            return 0;
        }

        // calculate the new reward rate per-token
        PoolRewards memory poolRewardsData = _poolRewards(poolToken, reserveToken);

        // rewardPerToken must be calculated with the previous value of lastUpdateTime
        poolRewardsData.rewardPerToken = _rewardPerToken(poolToken, reserveToken, poolRewardsData, program, lpStats);
        poolRewardsData.lastUpdateTime = Math.min(_time(), program.endTime);

        // update provider's rewards with the newly claimable base rewards and the new reward rate per-token
        ProviderRewards memory providerRewards = _providerRewards(provider, poolToken, reserveToken);

        // if this is the first liquidity provision - set the effective staking time to the current time
        if (
            providerRewards.effectiveStakingTime == 0 &&
            lpStats.totalProviderAmount(provider, poolToken, reserveToken) == 0
        ) {
            providerRewards.effectiveStakingTime = _time();
        }

        // pendingBaseRewards must be calculated with the previous value of providerRewards.rewardPerToken
        providerRewards.pendingBaseRewards = providerRewards.pendingBaseRewards.add(
            _baseRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats)
        );
        providerRewards.rewardPerToken = poolRewardsData.rewardPerToken;

        // get full rewards and the respective rewards multiplier
        (uint256 fullReward, ) =
            _fullRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);

        return fullReward;
    }

    /**
     * @dev claims specific provider's pending rewards for a specific list of participating pools
     */
    function _claimPendingRewards(
        address provider,
        IDSToken[] memory poolTokens,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats,
        bool resetStakingTime
    ) private returns (uint256) {
        uint256 reward = 0;

        uint256 length = poolTokens.length;
        for (uint256 i = 0; i < length && maxAmount > 0; ++i) {
            uint256 poolReward = _claimPendingRewards(provider, poolTokens[i], maxAmount, lpStats, resetStakingTime);
            reward = reward.add(poolReward);

            if (maxAmount != MAX_UINT256) {
                maxAmount = maxAmount.sub(poolReward);
            }
        }

        return reward;
    }

    /**
     * @dev claims specific provider's pending rewards for a specific pool
     */
    function _claimPendingRewards(
        address provider,
        IDSToken poolToken,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats,
        bool resetStakingTime
    ) private returns (uint256) {
        uint256 reward = 0;
        PoolProgram memory program = _poolProgram(poolToken);

        for (uint256 i = 0; i < program.reserveTokens.length && maxAmount > 0; ++i) {
            uint256 reserveReward =
                _claimPendingRewards(
                    provider,
                    poolToken,
                    program.reserveTokens[i],
                    program,
                    maxAmount,
                    lpStats,
                    resetStakingTime
                );
            reward = reward.add(reserveReward);

            if (maxAmount != MAX_UINT256) {
                maxAmount = maxAmount.sub(reserveReward);
            }
        }

        return reward;
    }

    /**
     * @dev claims specific provider's pending rewards for a specific pool/reserve
     */
    function _claimPendingRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolProgram memory program,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats,
        bool resetStakingTime
    ) private returns (uint256) {
        // update all provider's pending rewards, in order to apply retroactive reward multipliers
        (PoolRewards memory poolRewardsData, ProviderRewards memory providerRewards) =
            _updateRewards(provider, poolToken, reserveToken, program, lpStats);

        // get full rewards and the respective rewards multiplier
        (uint256 fullReward, uint32 multiplier) =
            _fullRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);

        // mark any debt as repaid.
        providerRewards.baseRewardsDebt = 0;
        providerRewards.baseRewardsDebtMultiplier = 0;

        if (maxAmount != MAX_UINT256 && fullReward > maxAmount) {
            // get the amount of the actual base rewards that were claimed
            providerRewards.baseRewardsDebt = _removeMultiplier(fullReward.sub(maxAmount), multiplier);

            // store the current multiplier for future retroactive rewards correction
            providerRewards.baseRewardsDebtMultiplier = multiplier;

            // grant only maxAmount rewards
            fullReward = maxAmount;
        }

        // update pool rewards data total claimed rewards
        _store.updatePoolRewardsData(
            poolToken,
            reserveToken,
            poolRewardsData.lastUpdateTime,
            poolRewardsData.rewardPerToken,
            poolRewardsData.totalClaimedRewards.add(fullReward)
        );

        // update provider rewards data with the remaining pending rewards and if needed, set the effective
        // staking time to the timestamp of the current block
        _store.updateProviderRewardsData(
            provider,
            poolToken,
            reserveToken,
            providerRewards.rewardPerToken,
            0,
            providerRewards.totalClaimedRewards.add(fullReward),
            resetStakingTime ? _time() : providerRewards.effectiveStakingTime,
            providerRewards.baseRewardsDebt,
            providerRewards.baseRewardsDebtMultiplier
        );

        return fullReward;
    }

    /**
     * @dev claims specific provider's pending rewards from all participating pools
     */
    function _claimPendingRewards(address provider, ILiquidityProtectionStats lpStats) private returns (uint256) {
        return _claimPendingRewards(provider, lpStats.providerPools(provider), MAX_UINT256, lpStats);
    }

    /**
     * @dev claims specific provider's pending rewards for a specific list of participating pools
     */
    function _claimPendingRewards(
        address provider,
        IDSToken[] memory poolTokens,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256) {
        uint256 amount = _claimPendingRewards(provider, poolTokens, maxAmount, lpStats, true);
        if (amount == 0) {
            return amount;
        }

        // make sure to update the last claim time so that it'll be taken into effect when calculating the next rewards
        // multiplier
        _store.updateProviderLastClaimTime(provider);

        // mint the reward tokens directly to the provider
        _networkTokenGovernance.mint(provider, amount);

        emit RewardsClaimed(provider, amount);

        return amount;
    }

    /**
     * @dev stakes specific provider's pending rewards from all participating pools
     */
    function _stakeRewards(
        address provider,
        uint256 maxAmount,
        IDSToken poolToken,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256, uint256) {
        return _stakeRewards(provider, lpStats.providerPools(provider), maxAmount, poolToken, lpStats);
    }

    /**
     * @dev claims and stakes specific provider's pending rewards for a specific list of participating pools
     */
    function _stakeRewards(
        address provider,
        IDSToken[] memory poolTokens,
        uint256 maxAmount,
        IDSToken newPoolToken,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256, uint256) {
        uint256 amount = _claimPendingRewards(provider, poolTokens, maxAmount, lpStats, false);
        if (amount == 0) {
            return (amount, 0);
        }

        // approve the LiquidityProtection contract to pull the rewards
        ILiquidityProtection liquidityProtection = _liquidityProtection();
        address liquidityProtectionAddress = address(liquidityProtection);
        _networkToken.ensureApprove(liquidityProtectionAddress, amount);

        // mint the reward tokens directly to the staking contract, so that the LiquidityProtection could pull the
        // rewards and attribute them to the provider
        _networkTokenGovernance.mint(address(this), amount);

        uint256 newId =
            liquidityProtection.addLiquidityFor(provider, newPoolToken, IReserveToken(address(_networkToken)), amount);

        // please note, that in order to incentivize staking, we won't be updating the time of the last claim, thus
        // preserving the rewards bonus multiplier

        emit RewardsStaked(provider, newPoolToken, amount, newId);

        return (amount, newId);
    }

    /**
     * @dev store specific provider's pending rewards for future claims
     */
    function _storeRewards(
        address provider,
        IDSToken[] memory poolTokens,
        ILiquidityProtectionStats lpStats
    ) private {
        for (uint256 i = 0; i < poolTokens.length; ++i) {
            IDSToken poolToken = poolTokens[i];
            PoolProgram memory program = _poolProgram(poolToken);

            for (uint256 j = 0; j < program.reserveTokens.length; ++j) {
                _storeRewards(provider, poolToken, program.reserveTokens[j], program, lpStats, true);
            }
        }
    }

    /**
     * @dev store specific provider's pending rewards for future claims
     */
    function _storeRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats,
        bool resetStakingTime
    ) private {
        if (!_isProgramValid(reserveToken, program)) {
            return;
        }

        // update all provider's pending rewards, in order to apply retroactive reward multipliers
        (PoolRewards memory poolRewardsData, ProviderRewards memory providerRewards) =
            _updateRewards(provider, poolToken, reserveToken, program, lpStats);

        // get full rewards and the respective rewards multiplier
        (uint256 fullReward, uint32 multiplier) =
            _fullRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);

        // get the amount of the actual base rewards that were claimed
        providerRewards.baseRewardsDebt = _removeMultiplier(fullReward, multiplier);

        // update store data with the store pending rewards and set the last update time to the timestamp of the
        // current block. if we're resetting the effective staking time, then we'd have to store the rewards multiplier in order to
        // account for it in the future. Otherwise, we must store base rewards without any rewards multiplier
        _store.updateProviderRewardsData(
            provider,
            poolToken,
            reserveToken,
            providerRewards.rewardPerToken,
            0,
            providerRewards.totalClaimedRewards,
            resetStakingTime ? _time() : providerRewards.effectiveStakingTime,
            providerRewards.baseRewardsDebt,
            resetStakingTime ? multiplier : PPM_RESOLUTION
        );
    }

    /**
     * @dev updates pool rewards
     */
    function _updateReserveRewards(
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) private returns (PoolRewards memory) {
        // calculate the new reward rate per-token and update it in the store
        PoolRewards memory poolRewardsData = _poolRewards(poolToken, reserveToken);

        bool update = false;

        // rewardPerToken must be calculated with the previous value of lastUpdateTime
        uint256 newRewardPerToken = _rewardPerToken(poolToken, reserveToken, poolRewardsData, program, lpStats);
        if (poolRewardsData.rewardPerToken != newRewardPerToken) {
            poolRewardsData.rewardPerToken = newRewardPerToken;

            update = true;
        }

        uint256 newLastUpdateTime = Math.min(_time(), program.endTime);
        if (poolRewardsData.lastUpdateTime != newLastUpdateTime) {
            poolRewardsData.lastUpdateTime = newLastUpdateTime;

            update = true;
        }

        if (update) {
            _store.updatePoolRewardsData(
                poolToken,
                reserveToken,
                poolRewardsData.lastUpdateTime,
                poolRewardsData.rewardPerToken,
                poolRewardsData.totalClaimedRewards
            );
        }

        return poolRewardsData;
    }

    /**
     * @dev updates provider rewards. this function is called during every liquidity changes
     */
    function _updateProviderRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolRewards memory poolRewardsData,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) private returns (ProviderRewards memory) {
        // update provider's rewards with the newly claimable base rewards and the new reward rate per-token
        ProviderRewards memory providerRewards = _providerRewards(provider, poolToken, reserveToken);

        bool update = false;

        // if this is the first liquidity provision - set the effective staking time to the current time
        if (
            providerRewards.effectiveStakingTime == 0 &&
            lpStats.totalProviderAmount(provider, poolToken, reserveToken) == 0
        ) {
            providerRewards.effectiveStakingTime = _time();

            update = true;
        }

        // pendingBaseRewards must be calculated with the previous value of providerRewards.rewardPerToken
        uint256 rewards =
            _baseRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);
        if (rewards != 0) {
            providerRewards.pendingBaseRewards = providerRewards.pendingBaseRewards.add(rewards);

            update = true;
        }

        if (providerRewards.rewardPerToken != poolRewardsData.rewardPerToken) {
            providerRewards.rewardPerToken = poolRewardsData.rewardPerToken;

            update = true;
        }

        if (update) {
            _store.updateProviderRewardsData(
                provider,
                poolToken,
                reserveToken,
                providerRewards.rewardPerToken,
                providerRewards.pendingBaseRewards,
                providerRewards.totalClaimedRewards,
                providerRewards.effectiveStakingTime,
                providerRewards.baseRewardsDebt,
                providerRewards.baseRewardsDebtMultiplier
            );
        }

        return providerRewards;
    }

    /**
     * @dev updates pool and provider rewards. this function is called during every liquidity changes
     */
    function _updateRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) private returns (PoolRewards memory, ProviderRewards memory) {
        PoolRewards memory poolRewardsData = _updateReserveRewards(poolToken, reserveToken, program, lpStats);
        ProviderRewards memory providerRewards =
            _updateProviderRewards(provider, poolToken, reserveToken, poolRewardsData, program, lpStats);

        return (poolRewardsData, providerRewards);
    }

    /**
     * @dev returns the aggregated reward rate per-token
     */
    function _rewardPerToken(
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolRewards memory poolRewardsData,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        // if there is no longer any liquidity in this reserve, return the historic rate (i.e., rewards won't accrue)
        uint256 totalReserveAmount = lpStats.totalReserveAmount(poolToken, reserveToken);
        if (totalReserveAmount == 0) {
            return poolRewardsData.rewardPerToken;
        }

        // don't grant any rewards before the starting time of the program
        uint256 currentTime = _time();
        if (currentTime < program.startTime) {
            return 0;
        }

        uint256 stakingEndTime = Math.min(currentTime, program.endTime);
        uint256 stakingStartTime = Math.max(program.startTime, poolRewardsData.lastUpdateTime);
        if (stakingStartTime == stakingEndTime) {
            return poolRewardsData.rewardPerToken;
        }

        // since we will be dividing by the total amount of protected tokens in units of wei, we can encounter cases
        // where the total amount in the denominator is higher than the product of the rewards rate and staking duration.
        // in order to avoid this imprecision, we will amplify the reward rate by the units amount
        return
            poolRewardsData.rewardPerToken.add( // the aggregated reward rate
                stakingEndTime
                    .sub(stakingStartTime) // the duration of the staking
                    .mul(program.rewardRate) // multiplied by the rate
                    .mul(REWARD_RATE_FACTOR) // and factored to increase precision
                    .mul(_rewardShare(reserveToken, program)) // and applied the specific token share of the whole reward
                    .div(totalReserveAmount.mul(PPM_RESOLUTION)) // and divided by the total protected tokens amount in the pool
            );
    }

    /**
     * @dev returns the base rewards since the last claim
     */
    function _baseRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolRewards memory poolRewardsData,
        ProviderRewards memory providerRewards,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        uint256 totalProviderAmount = lpStats.totalProviderAmount(provider, poolToken, reserveToken);
        uint256 newRewardPerToken = _rewardPerToken(poolToken, reserveToken, poolRewardsData, program, lpStats);

        return
            totalProviderAmount // the protected tokens amount held by the provider
                .mul(newRewardPerToken.sub(providerRewards.rewardPerToken)) // multiplied by the difference between the previous and the current rate
                .div(REWARD_RATE_FACTOR); // and factored back
    }

    /**
     * @dev returns the full rewards since the last claim
     */
    function _fullRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        PoolRewards memory poolRewardsData,
        ProviderRewards memory providerRewards,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256, uint32) {
        // calculate the claimable base rewards (since the last claim)
        uint256 newBaseRewards =
            _baseRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);

        // make sure that we aren't exceeding the reward rate for any reason
        _verifyBaseReward(newBaseRewards, providerRewards.effectiveStakingTime, reserveToken, program);

        // calculate pending rewards and apply the rewards multiplier
        uint32 multiplier = _rewardsMultiplier(provider, providerRewards.effectiveStakingTime, program);
        uint256 fullReward = _applyMultiplier(providerRewards.pendingBaseRewards.add(newBaseRewards), multiplier);

        // add any debt, while applying the best retroactive multiplier
        fullReward = fullReward.add(
            _applyHigherMultiplier(
                providerRewards.baseRewardsDebt,
                multiplier,
                providerRewards.baseRewardsDebtMultiplier
            )
        );

        // make sure that we aren't exceeding the full reward rate for any reason
        _verifyFullReward(fullReward, reserveToken, poolRewardsData, program);

        return (fullReward, multiplier);
    }

    /**
     * @dev returns the specific reserve token's share of all rewards
     */
    function _rewardShare(IReserveToken reserveToken, PoolProgram memory program) private pure returns (uint32) {
        if (reserveToken == program.reserveTokens[0]) {
            return program.rewardShares[0];
        }

        return program.rewardShares[1];
    }

    /**
     * @dev returns the rewards multiplier for the specific provider
     */
    function _rewardsMultiplier(
        address provider,
        uint256 stakingStartTime,
        PoolProgram memory program
    ) private view returns (uint32) {
        uint256 effectiveStakingEndTime = Math.min(_time(), program.endTime);
        uint256 effectiveStakingStartTime =
            Math.max( // take the latest of actual staking start time and the latest multiplier reset
                Math.max(stakingStartTime, program.startTime), // don't count staking before the start of the program
                Math.max(_lastRemoveTimes.checkpoint(provider), _store.providerLastClaimTime(provider)) // get the latest multiplier reset timestamp
            );

        // check that the staking range is valid. for example, it can be invalid when calculating the multiplier when
        // the staking has started before the start of the program, in which case the effective staking start time will
        // be in the future, compared to the effective staking end time (which will be the time of the current block)
        if (effectiveStakingStartTime >= effectiveStakingEndTime) {
            return PPM_RESOLUTION;
        }

        uint256 effectiveStakingDuration = effectiveStakingEndTime.sub(effectiveStakingStartTime);

        // given x representing the staking duration (in seconds), the resulting multiplier (in PPM) is:
        // * for 0 <= x <= 1 weeks: 100% PPM
        // * for 1 <= x <= 2 weeks: 125% PPM
        // * for 2 <= x <= 3 weeks: 150% PPM
        // * for 3 <= x <= 4 weeks: 175% PPM
        // * for x > 4 weeks: 200% PPM
        return PPM_RESOLUTION + MULTIPLIER_INCREMENT * uint32(Math.min(effectiveStakingDuration.div(1 weeks), 4));
    }

    /**
     * @dev returns the pool program for a specific pool
     */
    function _poolProgram(IDSToken poolToken) private view returns (PoolProgram memory) {
        PoolProgram memory program;
        (program.startTime, program.endTime, program.rewardRate, program.reserveTokens, program.rewardShares) = _store
            .poolProgram(poolToken);

        return program;
    }

    /**
     * @dev returns pool rewards for a specific pool and reserve
     */
    function _poolRewards(IDSToken poolToken, IReserveToken reserveToken) private view returns (PoolRewards memory) {
        PoolRewards memory data;
        (data.lastUpdateTime, data.rewardPerToken, data.totalClaimedRewards) = _store.poolRewards(
            poolToken,
            reserveToken
        );

        return data;
    }

    /**
     * @dev returns provider rewards for a specific pool and reserve
     */
    function _providerRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    ) private view returns (ProviderRewards memory) {
        ProviderRewards memory data;
        (
            data.rewardPerToken,
            data.pendingBaseRewards,
            data.totalClaimedRewards,
            data.effectiveStakingTime,
            data.baseRewardsDebt,
            data.baseRewardsDebtMultiplier
        ) = _store.providerRewards(provider, poolToken, reserveToken);

        return data;
    }

    /**
     * @dev applies the multiplier on the provided amount
     */
    function _applyMultiplier(uint256 amount, uint32 multiplier) private pure returns (uint256) {
        if (multiplier == PPM_RESOLUTION) {
            return amount;
        }

        return amount.mul(multiplier).div(PPM_RESOLUTION);
    }

    /**
     * @dev removes the multiplier on the provided amount
     */
    function _removeMultiplier(uint256 amount, uint32 multiplier) private pure returns (uint256) {
        if (multiplier == PPM_RESOLUTION) {
            return amount;
        }

        return amount.mul(PPM_RESOLUTION).div(multiplier);
    }

    /**
     * @dev applies the best of two rewards multipliers on the provided amount
     */
    function _applyHigherMultiplier(
        uint256 amount,
        uint32 multiplier1,
        uint32 multiplier2
    ) private pure returns (uint256) {
        return _applyMultiplier(amount, multiplier1 > multiplier2 ? multiplier1 : multiplier2);
    }

    /**
     * @dev performs a sanity check on the newly claimable base rewards
     */
    function _verifyBaseReward(
        uint256 baseReward,
        uint256 stakingStartTime,
        IReserveToken reserveToken,
        PoolProgram memory program
    ) private view {
        // don't grant any rewards before the starting time of the program or for stakes after the end of the program
        uint256 currentTime = _time();
        if (currentTime < program.startTime || stakingStartTime >= program.endTime) {
            require(baseReward == 0, "ERR_BASE_REWARD_TOO_HIGH");

            return;
        }

        uint256 effectiveStakingStartTime = Math.max(stakingStartTime, program.startTime);
        uint256 effectiveStakingEndTime = Math.min(currentTime, program.endTime);

        // make sure that we aren't exceeding the base reward rate for any reason
        require(
            baseReward <=
                (program.rewardRate * REWARDS_HALVING_FACTOR)
                    .mul(effectiveStakingEndTime.sub(effectiveStakingStartTime))
                    .mul(_rewardShare(reserveToken, program))
                    .div(PPM_RESOLUTION),
            "ERR_BASE_REWARD_RATE_TOO_HIGH"
        );
    }

    /**
     * @dev performs a sanity check on the newly claimable full rewards
     */
    function _verifyFullReward(
        uint256 fullReward,
        IReserveToken reserveToken,
        PoolRewards memory poolRewardsData,
        PoolProgram memory program
    ) private pure {
        uint256 maxClaimableReward =
            (
                (program.rewardRate * REWARDS_HALVING_FACTOR)
                    .mul(program.endTime.sub(program.startTime))
                    .mul(_rewardShare(reserveToken, program))
                    .mul(MAX_MULTIPLIER)
                    .div(PPM_RESOLUTION)
                    .div(PPM_RESOLUTION)
            )
                .sub(poolRewardsData.totalClaimedRewards);

        // make sure that we aren't exceeding the full reward rate for any reason
        require(fullReward <= maxClaimableReward, "ERR_REWARD_RATE_TOO_HIGH");
    }

    /**
     * @dev returns the liquidity protection stats data contract
     */
    function _liquidityProtectionStats() private view returns (ILiquidityProtectionStats) {
        return _liquidityProtection().stats();
    }

    /**
     * @dev returns the liquidity protection contract
     */
    function _liquidityProtection() private view returns (ILiquidityProtection) {
        return ILiquidityProtection(_addressOf(LIQUIDITY_PROTECTION));
    }

    /**
     * @dev returns if the program is valid
     */
    function _isProgramValid(IReserveToken reserveToken, PoolProgram memory program) private pure returns (bool) {
        return
            address(reserveToken) != address(0) &&
            (program.reserveTokens[0] == reserveToken || program.reserveTokens[1] == reserveToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IMintableToken.sol";

/// @title The interface for mintable/burnable token governance.
interface ITokenGovernance {
    // The address of the mintable ERC20 token.
    function token() external view returns (IMintableToken);

    /// @dev Mints new tokens.
    ///
    /// @param to Account to receive the new amount.
    /// @param amount Amount to increase the supply by.
    ///
    function mint(address to, uint256 amount) external;

    /// @dev Burns tokens from the caller.
    ///
    /// @param amount Amount to decrease the supply by.
    ///
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./Owned.sol";
import "./Utils.sol";
import "./interfaces/IContractRegistry.sol";

/**
 * @dev This is the base contract for ContractRegistry clients.
 */
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";
    bytes32 internal constant LIQUIDITY_PROTECTION = "LiquidityProtection";
    bytes32 internal constant NETWORK_SETTINGS = "NetworkSettings";

    // address of the current contract registry
    IContractRegistry private _registry;

    // address of the previous contract registry
    IContractRegistry private _prevRegistry;

    // only the owner can update the contract registry
    bool private _onlyOwnerCanUpdateRegistry;

    /**
     * @dev verifies that the caller is mapped to the given contract name
     */
    modifier only(bytes32 contractName) {
        _only(contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 contractName) internal view {
        require(msg.sender == _addressOf(contractName), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev initializes a new ContractRegistryClient instance
     */
    constructor(IContractRegistry initialRegistry) internal validAddress(address(initialRegistry)) {
        _registry = IContractRegistry(initialRegistry);
        _prevRegistry = IContractRegistry(initialRegistry);
    }

    /**
     * @dev updates to the new contract registry
     */
    function updateRegistry() external {
        // verify that this function is permitted
        require(msg.sender == owner() || !_onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract registry
        IContractRegistry newRegistry = IContractRegistry(_addressOf(CONTRACT_REGISTRY));

        // verify that the new contract registry is different and not zero
        require(newRegistry != _registry && address(newRegistry) != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract registry is pointing to a non-zero contract registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract registry before replacing it
        _prevRegistry = _registry;

        // replace the current contract registry with the new contract registry
        _registry = newRegistry;
    }

    /**
     * @dev restores the previous contract registry
     */
    function restoreRegistry() external ownerOnly {
        // restore the previous contract registry
        _registry = _prevRegistry;
    }

    /**
     * @dev restricts the permission to update the contract registry
     */
    function restrictRegistryUpdate(bool restrictOwnerOnly) public ownerOnly {
        // change the permission to update the contract registry
        _onlyOwnerCanUpdateRegistry = restrictOwnerOnly;
    }

    /**
     * @dev returns the address of the current contract registry
     */
    function registry() public view returns (IContractRegistry) {
        return _registry;
    }

    /**
     * @dev returns the address of the previous contract registry
     */
    function prevRegistry() external view returns (IContractRegistry) {
        return _prevRegistry;
    }

    /**
     * @dev returns whether only the owner can update the contract registry
     */
    function onlyOwnerCanUpdateRegistry() external view returns (bool) {
        return _onlyOwnerCanUpdateRegistry;
    }

    /**
     * @dev returns the address associated with the given contract name
     */
    function _addressOf(bytes32 contractName) internal view returns (address) {
        return _registry.addressOf(contractName);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        require(value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        require(addr != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);

        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address addr) {
        _validExternalAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address addr) internal view {
        require(addr != address(0) && addr != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Time implementing contract
*/
contract Time {
    /**
     * @dev returns the current time
     */
    function _time() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Checkpoint store contract interface
 */
interface ICheckpointStore {
    function addCheckpoint(address target) external;

    function addPastCheckpoint(address target, uint256 timestamp) external;

    function addPastCheckpoints(address[] calldata targets, uint256[] calldata timestamps) external;

    function checkpoint(address target) external view returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IReserveToken.sol";

import "./SafeERC20Ex.sol";

/**
 * @dev This library implements ERC20 and SafeERC20 utilities for reserve tokens, which can be either ERC20 tokens or ETH
 */
library ReserveToken {
    using SafeERC20 for IERC20;
    using SafeERC20Ex for IERC20;

    // the address that represents an ETH reserve
    IReserveToken public constant NATIVE_TOKEN_ADDRESS = IReserveToken(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev returns whether the provided token represents an ERC20 or ETH reserve
     */
    function isNativeToken(IReserveToken reserveToken) internal pure returns (bool) {
        return reserveToken == NATIVE_TOKEN_ADDRESS;
    }

    /**
     * @dev returns the balance of the reserve token
     */
    function balanceOf(IReserveToken reserveToken, address account) internal view returns (uint256) {
        if (isNativeToken(reserveToken)) {
            return account.balance;
        }

        return toIERC20(reserveToken).balanceOf(account);
    }

    /**
     * @dev transfers a specific amount of the reserve token
     */
    function safeTransfer(
        IReserveToken reserveToken,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isNativeToken(reserveToken)) {
            payable(to).transfer(amount);
        } else {
            toIERC20(reserveToken).safeTransfer(to, amount);
        }
    }

    /**
     * @dev transfers a specific amount of the reserve token from a specific holder using the allowance mechanism
     *
     * note that the function ignores a reserve token which represents an ETH reserve
     */
    function safeTransferFrom(
        IReserveToken reserveToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev ensures that the spender has sufficient allowance
     *
     * note that this function ignores a reserve token which represents an ETH reserve
     */
    function ensureApprove(
        IReserveToken reserveToken,
        address spender,
        uint256 amount
    ) internal {
        if (isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).ensureApprove(spender, amount);
    }

    /**
     * @dev utility function that converts an IReserveToken to an IERC20
     */
    function toIERC20(IReserveToken reserveToken) private pure returns (IERC20) {
        return IERC20(address(reserveToken));
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./ILiquidityProtectionStore.sol";
import "./ILiquidityProtectionStats.sol";
import "./ILiquidityProtectionSettings.sol";
import "./ILiquidityProtectionSystemStore.sol";
import "./ITransferPositionCallback.sol";

import "../../utility/interfaces/ITokenHolder.sol";

import "../../token/interfaces/IReserveToken.sol";

import "../../converter/interfaces/IConverterAnchor.sol";

/**
 * @dev Liquidity Protection interface
 */
interface ILiquidityProtection {
    function store() external view returns (ILiquidityProtectionStore);

    function stats() external view returns (ILiquidityProtectionStats);

    function settings() external view returns (ILiquidityProtectionSettings);

    function systemStore() external view returns (ILiquidityProtectionSystemStore);

    function wallet() external view returns (ITokenHolder);

    function addLiquidityFor(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function addLiquidity(
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function removeLiquidity(uint256 id, uint32 portion) external;

    function transferPosition(uint256 id, address newProvider) external returns (uint256);

    function transferPositionAndNotify(
        uint256 id,
        address newProvider,
        ITransferPositionCallback callback,
        bytes calldata data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../../liquidity-protection/interfaces/ILiquidityProvisionEventsSubscriber.sol";

import "./IStakingRewardsStore.sol";

interface IStakingRewards is ILiquidityProvisionEventsSubscriber {
    /**
     * @dev triggered when pending rewards are being claimed
     */
    event RewardsClaimed(address indexed provider, uint256 amount);

    /**
     * @dev triggered when pending rewards are being staked in a pool
     */
    event RewardsStaked(address indexed provider, IDSToken indexed poolToken, uint256 amount, uint256 indexed newId);

    function store() external view returns (IStakingRewardsStore);

    function pendingRewards(address provider) external view returns (uint256);

    function pendingPoolRewards(address provider, IDSToken poolToken) external view returns (uint256);

    function pendingReserveRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    ) external view returns (uint256);

    function rewardsMultiplier(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    ) external view returns (uint32);

    function totalClaimedRewards(address provider) external view returns (uint256);

    function claimRewards() external returns (uint256);

    function stakeRewards(uint256 maxAmount, IDSToken poolToken) external returns (uint256, uint256);

    function storePoolRewards(address[] calldata providers, IDSToken poolToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IClaimable.sol";

/// @title Mintable Token interface
interface IMintableToken is IERC20, IClaimable {
    function issue(address to, uint256 amount) external;

    function destroy(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @title Claimable contract interface
interface IClaimable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./interfaces/IOwned.sol";

/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address private _owner;
    address private _newOwner;

    /**
     * @dev triggered when the owner is updated
     */
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        _owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();

        _;
    }

    // error message binary size optimization
    function _ownerOnly() private view {
        require(msg.sender == _owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     *
     * note the new owner still needs to accept the transfer
     */
    function transferOwnership(address newOwner) public override ownerOnly {
        require(newOwner != _owner, "ERR_SAME_OWNER");

        _newOwner = newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == _newOwner, "ERR_ACCESS_DENIED");

        emit OwnerUpdate(_owner, _newOwner);

        _owner = _newOwner;
        _newOwner = address(0);
    }

    /**
     * @dev returns the address of the current owner
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev returns the address of the new owner candidate
     */
    function newOwner() external view returns (address) {
        return _newOwner;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Contract Registry interface
 */
interface IContractRegistry {
    function addressOf(bytes32 contractName) external view returns (address);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Owned interface
 */
interface IOwned {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev This contract is used to represent reserve tokens, which are tokens that can either be regular ERC20 tokens or
 * native ETH (represented by the NATIVE_TOKEN_ADDRESS address)
 *
 * Please note that this interface is intentionally doesn't inherit from IERC20, so that it'd be possible to effectively
 * override its balanceOf() function in the ReserveToken library
 */
interface IReserveToken {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @dev Extends the SafeERC20 library with additional operations
 */
library SafeERC20Ex {
    using SafeERC20 for IERC20;

    /**
     * @dev ensures that the spender has sufficient allowance
     */
    function ensureApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 allowance = token.allowance(address(this), spender);
        if (allowance >= amount) {
            return;
        }

        if (allowance > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../converter/interfaces/IConverterAnchor.sol";

import "../../token/interfaces/IDSToken.sol";
import "../../token/interfaces/IReserveToken.sol";

import "../../utility/interfaces/IOwned.sol";

/**
 * @dev Liquidity Protection Store interface
 */
interface ILiquidityProtectionStore is IOwned {
    function withdrawTokens(
        IReserveToken token,
        address recipient,
        uint256 amount
    ) external;

    function protectedLiquidity(uint256 id)
        external
        view
        returns (
            address,
            IDSToken,
            IReserveToken,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function addProtectedLiquidity(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount,
        uint256 reserveRateN,
        uint256 reserveRateD,
        uint256 timestamp
    ) external returns (uint256);

    function updateProtectedLiquidityAmounts(
        uint256 id,
        uint256 poolNewAmount,
        uint256 reserveNewAmount
    ) external;

    function removeProtectedLiquidity(uint256 id) external;

    function lockedBalance(address provider, uint256 index) external view returns (uint256, uint256);

    function lockedBalanceRange(
        address provider,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (uint256[] memory, uint256[] memory);

    function addLockedBalance(
        address provider,
        uint256 reserveAmount,
        uint256 expirationTime
    ) external returns (uint256);

    function removeLockedBalance(address provider, uint256 index) external;

    function systemBalance(IReserveToken poolToken) external view returns (uint256);

    function incSystemBalance(IReserveToken poolToken, uint256 poolAmount) external;

    function decSystemBalance(IReserveToken poolToken, uint256 poolAmount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../converter/interfaces/IConverterAnchor.sol";

import "../../token/interfaces/IDSToken.sol";
import "../../token/interfaces/IReserveToken.sol";

/**
 * @dev Liquidity Protection Stats interface
 */
interface ILiquidityProtectionStats {
    function increaseTotalAmounts(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function decreaseTotalAmounts(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function addProviderPool(address provider, IDSToken poolToken) external returns (bool);

    function removeProviderPool(address provider, IDSToken poolToken) external returns (bool);

    function totalPoolAmount(IDSToken poolToken) external view returns (uint256);

    function totalReserveAmount(IDSToken poolToken, IReserveToken reserveToken) external view returns (uint256);

    function totalProviderAmount(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    ) external view returns (uint256);

    function providerPools(address provider) external view returns (IDSToken[] memory);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../converter/interfaces/IConverterAnchor.sol";

import "../../token/interfaces/IReserveToken.sol";

import "./ILiquidityProvisionEventsSubscriber.sol";

/**
 * @dev Liquidity Protection Settings interface
 */
interface ILiquidityProtectionSettings {
    function isPoolWhitelisted(IConverterAnchor poolAnchor) external view returns (bool);

    function poolWhitelist() external view returns (address[] memory);

    function subscribers() external view returns (address[] memory);

    function isPoolSupported(IConverterAnchor poolAnchor) external view returns (bool);

    function minNetworkTokenLiquidityForMinting() external view returns (uint256);

    function defaultNetworkTokenMintingLimit() external view returns (uint256);

    function networkTokenMintingLimits(IConverterAnchor poolAnchor) external view returns (uint256);

    function addLiquidityDisabled(IConverterAnchor poolAnchor, IReserveToken reserveToken) external view returns (bool);

    function minProtectionDelay() external view returns (uint256);

    function maxProtectionDelay() external view returns (uint256);

    function minNetworkCompensation() external view returns (uint256);

    function lockDuration() external view returns (uint256);

    function averageRateMaxDeviation() external view returns (uint32);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";

/**
 * @dev Liquidity Protection System Store interface
 */
interface ILiquidityProtectionSystemStore {
    function systemBalance(IERC20 poolToken) external view returns (uint256);

    function incSystemBalance(IERC20 poolToken, uint256 poolAmount) external;

    function decSystemBalance(IERC20 poolToken, uint256 poolAmount) external;

    function networkTokensMinted(IConverterAnchor poolAnchor) external view returns (uint256);

    function incNetworkTokensMinted(IConverterAnchor poolAnchor, uint256 amount) external;

    function decNetworkTokensMinted(IConverterAnchor poolAnchor, uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Transfer position event callback interface
 */
interface ITransferPositionCallback {
    function onTransferPosition(
        uint256 newId,
        address provider,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../token/interfaces/IReserveToken.sol";

import "./IOwned.sol";

/**
 * @dev Token Holder interface
 */
interface ITokenHolder is IOwned {
    receive() external payable;

    function withdrawTokens(
        IReserveToken reserveToken,
        address payable to,
        uint256 amount
    ) external;

    function withdrawTokensMultiple(
        IReserveToken[] calldata reserveTokens,
        address payable to,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../utility/interfaces/IOwned.sol";

/**
 * @dev Converter Anchor interface
 */
interface IConverterAnchor is IOwned {

}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";
import "../../utility/interfaces/IOwned.sol";

/**
 * @dev DSToken interface
 */
interface IDSToken is IConverterAnchor, IERC20 {
    function issue(address recipient, uint256 amount) external;

    function destroy(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "../../converter/interfaces/IConverterAnchor.sol";

import "../../token/interfaces/IReserveToken.sol";

/**
 * @dev Liquidity provision events subscriber interface
 */
interface ILiquidityProvisionEventsSubscriber {
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function onRemovingLiquidity(
        uint256 id,
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../../token/interfaces/IReserveToken.sol";
import "../../token/interfaces/IDSToken.sol";

struct PoolProgram {
    uint256 startTime;
    uint256 endTime;
    uint256 rewardRate;
    IReserveToken[2] reserveTokens;
    uint32[2] rewardShares;
}

struct PoolRewards {
    uint256 lastUpdateTime;
    uint256 rewardPerToken;
    uint256 totalClaimedRewards;
}

struct ProviderRewards {
    uint256 rewardPerToken;
    uint256 pendingBaseRewards;
    uint256 totalClaimedRewards;
    uint256 effectiveStakingTime;
    uint256 baseRewardsDebt;
    uint32 baseRewardsDebtMultiplier;
}

interface IStakingRewardsStore {
    function isPoolParticipating(IDSToken poolToken) external view returns (bool);

    function isReserveParticipating(IDSToken poolToken, IReserveToken reserveToken) external view returns (bool);

    function addPoolProgram(
        IDSToken poolToken,
        IReserveToken[2] calldata reserveTokens,
        uint32[2] calldata rewardShares,
        uint256 endTime,
        uint256 rewardRate
    ) external;

    function removePoolProgram(IDSToken poolToken) external;

    function setPoolProgramEndTime(IDSToken poolToken, uint256 newEndTime) external;

    function poolProgram(IDSToken poolToken)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            IReserveToken[2] memory,
            uint32[2] memory
        );

    function poolPrograms()
        external
        view
        returns (
            IDSToken[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            IReserveToken[2][] memory,
            uint32[2][] memory
        );

    function poolRewards(IDSToken poolToken, IReserveToken reserveToken)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function updatePoolRewardsData(
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 lastUpdateTime,
        uint256 rewardPerToken,
        uint256 totalClaimedRewards
    ) external;

    function providerRewards(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint32
        );

    function updateProviderRewardsData(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 rewardPerToken,
        uint256 pendingBaseRewards,
        uint256 totalClaimedRewards,
        uint256 effectiveStakingTime,
        uint256 baseRewardsDebt,
        uint32 baseRewardsDebtMultiplier
    ) external;

    function updateProviderLastClaimTime(address provider) external;

    function providerLastClaimTime(address provider) external view returns (uint256);
}

