pragma solidity ^0.8.0;

import "./ITribalChief.sol";

interface IAutoRewardsDistributor {
    function setAutoRewardsDistribution() external;
}

interface ITimelock {
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external;
}

/**
    @title TribalChief Synchronize contract
    This contract is able to keep the tribalChief and autoRewardsDistributor in sync when either:
    1. adding pools or 
    2. updating block rewards

    It needs the EXECUTOR role on the optimistic timelock, so it can atomically trigger the 3 actions.

    It also includes a mapping for updating block rewards according to the schedule in https://tribe.fei.money/t/tribe-liquidity-mining-emission-schedule/3549
    It needs the TRIBAL_CHIEF_ADMIN_ROLE role to auto trigger reward decreases.
 */
contract TribalChiefSyncV2 {
    ITribalChief public immutable tribalChief;
    IAutoRewardsDistributor public immutable autoRewardsDistributor;
    ITimelock public immutable timelock;

    /// @notice a mapping from reward rates to timestamps after which they become active
    mapping(uint256 => uint256) public rewardsSchedule;

    /// @notice rewards schedule in reverse order
    uint256[] public rewardsArray;

    // TribalChief struct
    struct RewardData {
        uint128 lockLength;
        uint128 rewardMultiplier;
    }

    constructor(
        ITribalChief _tribalChief,
        IAutoRewardsDistributor _autoRewardsDistributor,
        ITimelock _timelock,
        uint256[] memory rewards,
        uint256[] memory timestamps
    ) {
        tribalChief = _tribalChief;
        autoRewardsDistributor = _autoRewardsDistributor;
        timelock = _timelock;

        require(rewards.length == timestamps.length, "length");

        uint256 lastReward = type(uint256).max;
        uint256 lastTimestamp = block.timestamp;
        uint256 len = rewards.length;
        rewardsArray = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            uint256 nextReward = rewards[i];
            uint256 nextTimestamp = timestamps[i];
            
            require(nextReward < lastReward, "rewards");
            require(nextTimestamp > lastTimestamp, "timestamp");
            
            rewardsSchedule[nextReward] = nextTimestamp;
            rewardsArray[len - i - 1] = nextReward;

            lastReward = nextReward;
            lastTimestamp = nextTimestamp;
        }
    }

    /// @notice Before an action, mass update all pools, after sync the autoRewardsDistributor
    modifier update {
        uint256 numPools = tribalChief.numPools();
        uint256[] memory pids = new uint256[](numPools);
        for (uint256 i = 0; i < numPools; i++) {
            pids[i] = i;
        }
        tribalChief.massUpdatePools(pids);
        _;
        autoRewardsDistributor.setAutoRewardsDistribution();
    }

    /// @notice Sync a rewards rate change automatically using pre-approved map
    function autoDecreaseRewards() external update {
        require(isRewardDecreaseAvailable(), "time not passed");
        uint256 tribePerBlock = nextRewardsRate();
        tribalChief.updateBlockReward(tribePerBlock);
        rewardsArray.pop();
    }

    function isRewardDecreaseAvailable() public view returns(bool) {
        return rewardsArray.length > 0 && nextRewardTimestamp() < block.timestamp;
    }

    function nextRewardTimestamp() public view returns(uint256) {
        return rewardsSchedule[nextRewardsRate()];
    }

    function nextRewardsRate() public view returns(uint256) {
        return rewardsArray[rewardsArray.length - 1];
    }

    /// @notice Sync a rewards rate change
    function decreaseRewards(uint256 tribePerBlock, bytes32 salt) external update {
        bytes memory data = abi.encodeWithSelector(
            tribalChief.updateBlockReward.selector, 
            tribePerBlock
        );
        timelock.execute(
            address(tribalChief), 
            0, 
            data, 
            bytes32(0), 
            salt
        );
    }

    /// @notice Sync a pool addition
    function addPool(
        uint120 allocPoint, 
        address stakedToken, 
        address rewarder, 
        RewardData[] memory rewardData, 
        bytes32 salt
    ) external update {
        bytes memory data = abi.encodeWithSelector(
            tribalChief.add.selector, 
            allocPoint,
            stakedToken,
            rewarder,
            rewardData
        );
        timelock.execute(
            address(tribalChief), 
            0, 
            data, 
            bytes32(0), 
            salt
        );
    }

    /// @notice Sync a pool set action
    function setPool(
        uint256 pid,
        uint120 allocPoint,
        IRewarder rewarder,
        bool overwrite,
        bytes32 salt
    ) external update {
        bytes memory data = abi.encodeWithSelector(
            tribalChief.set.selector,
            pid,
            allocPoint,
            rewarder,
            overwrite
        );
        timelock.execute(
            address(tribalChief), 
            0, 
            data, 
            bytes32(0), 
            salt
        );
    }

    /// @notice Sync a pool reset rewards action
    function resetPool(
        uint256 pid,
        bytes32 salt
    ) external update {
        bytes memory data = abi.encodeWithSelector(
            tribalChief.resetRewards.selector,
            pid
        );
        timelock.execute(
            address(tribalChief), 
            0, 
            data, 
            bytes32(0), 
            salt
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IRewarder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface ITribalChief {
    /// @notice Data needed for governor to create a new lockup period
    /// and associated reward multiplier
    struct RewardData {
        uint128 lockLength;
        uint128 rewardMultiplier;
    }

    /// @notice Info of each pool.
    struct PoolInfo {
        uint256 virtualTotalSupply;
        uint256 accTribePerShare;
        uint128 lastRewardBlock;
        uint120 allocPoint;
        bool unlocked;
    }

    /// @notice view only functions that return data on pools, user deposit(s), tribe distributed per block, and other constants
    function rewardMultipliers(uint256 _pid, uint128 _blocksLocked) external view returns (uint128);
    function stakedToken(uint256 _index) external view returns(IERC20);
    function poolInfo(uint256 _index) external view returns(uint256, uint256, uint128, uint120, bool);
    function tribePerBlock() external view returns (uint256);
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256);
    function getTotalStakedInPool(uint256 pid, address user) external view returns (uint256);
    function openUserDeposits(uint256 pid, address user) external view returns (uint256);
    function numPools() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function SCALE_FACTOR() external view returns (uint256);

    /// @notice functions for users to deposit, withdraw and get rewards from our contracts
    function deposit(uint256 _pid, uint256 _amount, uint64 _lockLength) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAllAndHarvest(uint256 pid, address to) external;
    function withdrawFromDeposit(uint256 pid, uint256 amount, address to, uint256 index) external; 
    function emergencyWithdraw(uint256 pid, address to) external;

    /// @notice functions to update pools that can be called by anyone
    function updatePool(uint256 pid) external;
    function massUpdatePools(uint256[] calldata pids) external;

    /// @notice functions to change and add pools and multipliers that can only be called by governor, guardian, or TribalChiefAdmin
    function resetRewards(uint256 _pid) external;
    function set(uint256 _pid, uint120 _allocPoint, IRewarder _rewarder, bool overwrite) external;
    function add(uint120 allocPoint, IERC20 _stakedToken, IRewarder _rewarder, RewardData[] calldata rewardData) external;
    function governorWithdrawTribe(uint256 amount) external;
    function governorAddPoolMultiplier(uint256 _pid, uint64 lockLength, uint64 newRewardsMultiplier) external;
    function unlockPool(uint256 _pid) external;
    function lockPool(uint256 _pid) external;
    function updateBlockReward(uint256 newBlockReward) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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