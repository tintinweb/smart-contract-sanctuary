// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../interface/IFarm.sol";


/**
 * @title MockFarm
 * @author solace.fi
 * @notice Used to test FarmController and FarmRewards.
 */
contract MockFarm is IFarm {

    /// @notice A unique enumerator that identifies the farm type.
    uint256 internal constant _farmType = 999;
    /// @notice FarmController contract.
    IFarmController internal _controller;
    /// @notice Amount of SOLACE distributed per seconds.
    uint256 internal _rewardPerSecond;
    /// @notice When the farm will start.
    uint256 internal _startTime;
    /// @notice When the farm will end.
    uint256 internal _endTime;

    mapping(address => uint256) internal _pendingRewards;

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice A unique enumerator that identifies the farm type.
    function farmType() external pure override returns (uint256 farmType_) {
        return _farmType;
    }

    /// @notice FarmController contract.
    function farmController() external view override returns (address controller_) {
        return address(_controller);
    }

    /// @notice Amount of SOLACE distributed per second.
    function rewardPerSecond() external view override returns (uint256) {
        return _rewardPerSecond;
    }

    /// @notice When the farm will start.
    function startTime() external view override returns (uint256 timestamp) {
        return _startTime;
    }

    /// @notice When the farm will end.
    function endTime() external view override returns (uint256 timestamp) {
        return _endTime;
    }

    /**
     * @notice Calculates the accumulated balance of [**SOLACE**](./SOLACE) for specified user.
     * @param user The user for whom unclaimed tokens will be shown.
     * @return reward Total amount of withdrawable reward tokens.
     */
    function pendingRewards(address user) external view override returns (uint256 reward) {
        return _pendingRewards[user];
    }

    /**
     * @notice Calculates the reward amount distributed between two timestamps.
     * @param from The start of the period to measure rewards for.
     * @param to The end of the period to measure rewards for.
     * @return amount The reward amount distributed in the given period.
     */
    function getRewardAmountDistributed(uint256 from, uint256 to) public view override returns (uint256 amount) {
        return 0;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Updates a users pending rewards.
     * @param user User to update.
     * @param amount Amount to update.
     */
    function setPendingRewards(address user, uint256 amount) external {
        _pendingRewards[user] = amount;
    }

    /**
     * @notice Updates farm information to be up to date to the current time.
     */
    function updateFarm() public override { }

    /***************************************
    OPTIONS MINING FUNCTIONS
    ***************************************/

    /**
     * @notice Converts the senders unpaid rewards into an [`Option`](./OptionsFarming).
     * @return optionID The ID of the newly minted [`Option`](./OptionsFarming).
     */
    function withdrawRewards() external override returns (uint256 optionID) {
        return 0;
    }

    /**
     * @notice Withdraw a users rewards without unstaking their tokens.
     * Can only be called by [`FarmController`](./FarmController).
     * @param user User to withdraw rewards for.
     * @return rewardAmount The amount of rewards the user earned on this farm.
     */
    function withdrawRewardsForUser(address user) external override returns (uint256 rewardAmount) {
        return 0;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the amount of [**SOLACE**](./SOLACE) to distribute per second.
     * Only affects future rewards.
     * Can only be called by [`FarmController`](./FarmController).
     * @param rewardPerSecond_ Amount to distribute per second.
     */
    function setRewards(uint256 rewardPerSecond_) external override { }

    /**
     * @notice Sets the farm's end time. Used to extend the duration.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param endTime_ The new end time.
     */
    function setEnd(uint256 endTime_) external override { }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IFarmController.sol";


/**
 * @title IFarm
 * @author solace.fi
 * @notice Rewards investors in [**SOLACE**](../SOLACE).
 */
interface IFarm {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice [`IFarmController`](../FarmController) contract.
    function farmController() external view returns (address);

    /// @notice A unique enumerator that identifies the farm type.
    function farmType() external view returns (uint256);

    /// @notice Amount of rewards distributed per second.
    function rewardPerSecond() external view returns (uint256);

    /// @notice When the farm will start.
    function startTime() external view returns (uint256);

    /// @notice When the farm will end.
    function endTime() external view returns (uint256);

    /**
     * @notice Calculates the accumulated rewards for specified user.
     * @param user The user for whom unclaimed tokens will be shown.
     * @return reward Total amount of withdrawable rewards.
     */
    function pendingRewards(address user) external view returns (uint256 reward);

    /**
     * @notice Calculates the reward amount distributed between two timestamps.
     * @param from The start of the period to measure rewards for.
     * @param to The end of the period to measure rewards for.
     * @return amount The reward amount distributed in the given period.
     */
    function getRewardAmountDistributed(uint256 from, uint256 to) external view returns (uint256 amount);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Converts the senders unpaid rewards into an [`Option`](../OptionsFarming).
     * @return optionID The ID of the newly minted [`Option`](../OptionsFarming).
     */
    function withdrawRewards() external returns (uint256 optionID);

    /**
     * @notice Withdraw a users rewards without unstaking their tokens.
     * Can only be called by [`FarmController`](../FarmController).
     * @param user User to withdraw rewards for.
     * @return rewardAmount The amount of rewards the user earned on this farm.
     */
    function withdrawRewardsForUser(address user) external returns (uint256 rewardAmount);

    /**
     * @notice Updates farm information to be up to date to the current time.
     */
    function updateFarm() external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the amount of rewards to distribute per second.
     * Only affects future rewards.
     * Can only be called by [`FarmController`](../FarmController).
     * @param rewardPerSecond_ Amount to distribute per second.
     */
    function setRewards(uint256 rewardPerSecond_) external;

    /**
     * @notice Sets the farm's end time. Used to extend the duration.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param endTime_ The new end time.
     */
    function setEnd(uint256 endTime_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IFarmController
 * @author solace.fi
 * @notice Controls the allocation of rewards across multiple farms.
 */
interface IFarmController {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a farm is registered.
    event FarmRegistered(uint256 indexed farmID, address indexed farmAddress);
    /// @notice Emitted when reward per second is changed.
    event RewardsSet(uint256 rewardPerSecond);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Rewards distributed per second across all farms.
    function rewardPerSecond() external view returns (uint256);

    /// @notice Total allocation points across all farms.
    function totalAllocPoints() external view returns (uint256);

    /// @notice The number of farms that have been created.
    function numFarms() external view returns (uint256);

    /// @notice Given a farm ID, return its address.
    /// @dev Indexable 1-numFarms, 0 is null farm.
    function farmAddresses(uint256 farmID) external view returns (address);

    /// @notice Given a farm address, returns its ID.
    /// @dev Returns 0 for not farms and unregistered farms.
    function farmIndices(address farmAddress) external view returns (uint256);

    /// @notice Given a farm ID, how many points the farm was allocated.
    function allocPoints(uint256 farmID) external view returns (uint256);

    /**
     * @notice Calculates the accumulated balance of rewards for the specified user.
     * @param user The user for whom unclaimed rewards will be shown.
     * @return reward Total amount of withdrawable rewards.
     */
    function pendingRewards(address user) external view returns (uint256 reward);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Updates all farms to be up to date to the current second.
     */
    function massUpdateFarms() external;

    /***************************************
    OPTIONS CREATION FUNCTIONS
    ***************************************/

    /**
     * @notice Withdraw your rewards from all farms and create an [`Option`](../OptionsFarming).
     * @return optionID The ID of the new [`Option`](./OptionsFarming).
     */
    function farmOptionMulti() external returns (uint256 optionID);

    /**
     * @notice Creates an [`Option`](../OptionsFarming) for the given `rewardAmount`.
     * Must be called by a farm.
     * @param recipient The recipient of the option.
     * @param rewardAmount The amount to reward in the Option.
     * @return optionID The ID of the new [`Option`](./OptionsFarming).
     */
    function createOption(address recipient, uint256 rewardAmount) external returns (uint256 optionID);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Registers a farm.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * Cannot register a farm more than once.
     * @param farmAddress The farm's address.
     * @param allocPoints How many points to allocate this farm.
     * @return farmID The farm ID.
     */
    function registerFarm(address farmAddress, uint256 allocPoints) external returns (uint256 farmID);

    /**
     * @notice Sets a farm's allocation points.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param farmID The farm to set allocation points.
     * @param allocPoints_ How many points to allocate this farm.
     */
    function setAllocPoints(uint256 farmID, uint256 allocPoints_) external;

    /**
     * @notice Sets the reward distribution across all farms.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param rewardPerSecond_ Amount of reward to distribute per second.
     */
    function setRewardPerSecond(uint256 rewardPerSecond_) external;
}