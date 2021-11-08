// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Governable.sol";
import "./interface/IOptionsFarming.sol";
import "./interface/IFarm.sol";
import "./interface/IFarmController.sol";


/**
 * @title FarmController
 * @author solace.fi
 * @notice Controls the allocation of rewards across multiple farms.
 */
contract FarmController is IFarmController, Governable {

    uint256 internal _rewardPerSecond;

    IOptionsFarming internal _optionsFarming;

    /// @notice Total allocation points across all farms.
    uint256 internal _totalAllocPoints = 0;

    /// @notice The number of farms that have been created.
    uint256 internal _numFarms = 0;

    /// @notice Given a farm ID, return its address.
    /// @dev Indexable 1-numFarms, 0 is null farm
    mapping(uint256 => address) internal _farmAddresses;

    /// @notice Given a farm address, returns its ID.
    /// @dev Returns 0 for not farms and unregistered farms.
    mapping(address => uint256) internal _farmIndices;

    /// @notice Given a farm ID, how many points the farm was allocated.
    mapping(uint256 => uint256) internal _allocPoints;

    /**
     * @notice Constructs the `FarmController` contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param optionsFarming_ The address of the [`OptionsFarming`](./OptionsFarming) contract.
     * @param rewardPerSecond_ Amount of reward to distribute per second.
     */
    constructor(address governance_, address optionsFarming_, uint256 rewardPerSecond_) Governable(governance_) {
        require(optionsFarming_ != address(0x0), "zero address optionsfarming");
        _optionsFarming = IOptionsFarming(payable(optionsFarming_));
        _rewardPerSecond = rewardPerSecond_;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Rewards distributed per second across all farms.
    function rewardPerSecond() external view override returns (uint256) {
        return _rewardPerSecond;
    }

    /// @notice Total allocation points across all farms.
    function totalAllocPoints() external view override returns (uint256) {
        return _totalAllocPoints;
    }

    /// @notice The number of farms that have been created.
    function numFarms() external view override returns (uint256) {
        return _numFarms;
    }

    /// @notice Given a farm ID, return its address.
    /// @dev Indexable 1-numFarms, 0 is null farm.
    function farmAddresses(uint256 farmID) external view override returns (address) {
        return _farmAddresses[farmID];
    }

    /// @notice Given a farm address, returns its ID.
    /// @dev Returns 0 for not farms and unregistered farms.
    function farmIndices(address farmAddress) external view override returns (uint256) {
        return _farmIndices[farmAddress];
    }

    /// @notice Given a farm ID, how many points the farm was allocated.
    function allocPoints(uint256 farmID) external view override returns (uint256) {
        return _allocPoints[farmID];
    }

    /**
     * @notice Calculates the accumulated balance of rewards for the specified user.
     * @param user The user for whom unclaimed rewards will be shown.
     * @return reward Total amount of withdrawable rewards.
     */
    function pendingRewards(address user) external view override returns (uint256 reward) {
        reward = 0;
        uint256 numFarms_ = _numFarms; // copy to memory to save gas
        for(uint256 farmID = 1; farmID <= numFarms_; ++farmID) {
            IFarm farm = IFarm(_farmAddresses[farmID]);
            reward += farm.pendingRewards(user);
        }
        return reward;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Updates all farms to be up to date to the current second.
     */
    function massUpdateFarms() external override {
        uint256 numFarms_ = _numFarms; // copy to memory to save gas
        for(uint256 farmID = 1; farmID <= numFarms_; ++farmID) {
            IFarm(_farmAddresses[farmID]).updateFarm();
        }
    }

    /***************************************
    OPTIONS CREATION FUNCTIONS
    ***************************************/

    /**
     * @notice Withdraw your rewards from all farms and create an [`Option`](./OptionsFarming).
     * @return optionID The ID of the new [`Option`](./OptionsFarming).
     */
    function farmOptionMulti() external override returns (uint256 optionID) {
        // withdraw rewards from all farms
        uint256 rewardAmount = 0;
        uint256 numFarms_ = _numFarms; // copy to memory to save gas
        for(uint256 farmID = 1; farmID <= numFarms_; ++farmID) {
            IFarm farm = IFarm(_farmAddresses[farmID]);
            uint256 rewards = farm.withdrawRewardsForUser(msg.sender);
            rewardAmount += rewards;
        }
        // create an option
        optionID = _optionsFarming.createOption(msg.sender, rewardAmount);
        return optionID;
    }

    /**
     * @notice Creates an [`Option`](./OptionsFarming) for the given `rewardAmount`.
     * Must be called by a farm.
     * @param recipient The recipient of the option.
     * @param rewardAmount The amount to reward in the Option.
     * @return optionID The ID of the new [`Option`](./OptionsFarming).
     */
    function createOption(address recipient, uint256 rewardAmount) external override returns (uint256 optionID) {
        require(_farmIndices[msg.sender] != 0, "!farm");
        // create an option
        optionID = _optionsFarming.createOption(recipient, rewardAmount);
        return optionID;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Registers a farm.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * Cannot register a farm more than once.
     * @param farmAddress The farm's address.
     * @param allocPoints_ How many points to allocate this farm.
     * @return farmID The farm ID.
     */
    function registerFarm(address farmAddress, uint256 allocPoints_) external override onlyGovernance returns (uint256 farmID) {
        // note that each farm will be assigned a number of rewards to distribute per second,
        // but there are no checks in case the farm exceeds that amount.
        // check the farm logic before registering it
        require(_farmIndices[farmAddress] == 0, "already registered");
        require(IFarm(farmAddress).farmType() > 0, "not a farm");
        farmID = ++_numFarms; // starts at 1
        _farmAddresses[farmID] = farmAddress;
        _farmIndices[farmAddress] = farmID;
        _setAllocPoints(farmID, allocPoints_);
        emit FarmRegistered(farmID, farmAddress);
    }

    /**
     * @notice Sets a farm's allocation points.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param farmID The farm to set allocation points.
     * @param allocPoints_ How many points to allocate this farm.
     */
    function setAllocPoints(uint256 farmID, uint256 allocPoints_) external override onlyGovernance {
        require(farmID != 0 && farmID <= _numFarms, "farm does not exist");
        _setAllocPoints(farmID, allocPoints_);
    }

    /**
     * @notice Sets the reward distribution across all farms.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param rewardPerSecond_ Amount of reward to distribute per second.
     */
    function setRewardPerSecond(uint256 rewardPerSecond_) external override onlyGovernance {
        // accounting
        _rewardPerSecond = rewardPerSecond_;
        _updateRewards();
        emit RewardsSet(rewardPerSecond_);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
    * @notice Sets a farm's allocation points.
    * @param farmID The farm to set allocation points.
    * @param allocPoints_ How many points to allocate this farm.
    */
    function _setAllocPoints(uint256 farmID, uint256 allocPoints_) internal {
      _totalAllocPoints = _totalAllocPoints - _allocPoints[farmID] + allocPoints_;
      _allocPoints[farmID] = allocPoints_;
      _updateRewards();
    }

    /**
     * @notice Updates each farm's second rewards.
     */
    function _updateRewards() internal {
        uint256 numFarms_ = _numFarms; // copy to memory to save gas
        uint256 rewardPerSecond_ = _rewardPerSecond;
        uint256 totalAllocPoints_ = _totalAllocPoints;
        for(uint256 farmID = 1; farmID <= numFarms_; ++farmID) {
            uint256 secondReward = (totalAllocPoints_ == 0) ? 0 : (rewardPerSecond_ * _allocPoints[farmID] / totalAllocPoints_);
            IFarm(_farmAddresses[farmID]).setRewards(secondReward);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./interface/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./interface/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721Enhanced.sol";


/**
 * @title IOptionsFarming
 * @author solace.fi
 * @notice Distributes options to farmers.
 *
 * Rewards are accumulated by farmers for participating in farms. Rewards can be redeemed for options with 1:1 reward:[**SOLACE**](./SOLACE). Options can be exercised by paying `strike price` **ETH** before `expiry` to receive `rewardAmount` [**SOLACE**](./SOLACE).
 *
 * The `strike price` is calculated by either:
 *   - The current market price of [**SOLACE**](./SOLACE) * `swap rate` as determined by the [**SOLACE**](./SOLACE)-**ETH** Uniswap pool.
 *   - The floor price of [**SOLACE**](./SOLACE)/**USD** converted to **ETH** using a **ETH**-**USD** Uniswap pool.
 */
interface IOptionsFarming is IERC721Enhanced {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when an option is created.
    event OptionCreated(uint256 optionID);
    /// @notice Emitted when an option is exercised.
    event OptionExercised(uint256 optionID);
    /// @notice Emitted when solace is set.
    event SolaceSet(address solace);
    /// @notice Emitted when farm controller is set.
    event FarmControllerSet(address farmController);
    /// @notice Emitted when [**SOLACE**](../SOLACE)-**ETH** pool is set.
    event SolaceEthPoolSet(address solaceEthPool);
    /// @notice Emitted when **ETH**-**USD** pool is set.
    event EthUsdPoolSet(address ethUsdPool);
    /// @notice Emitted when [**SOLACE**](../SOLACE)-**ETH** twap interval is set.
    event SolaceEthTwapIntervalSet(uint32 twapInterval);
    /// @notice Emitted when **ETH**-**USD** twap interval is set.
    event EthUsdTwapIntervalSet(uint32 twapInterval);
    /// @notice Emitted when expiry duration is set.
    event ExpiryDurationSet(uint256 expiryDuration);
    /// @notice Emitted when swap rate is set.
    event SwapRateSet(uint16 swapRate);
    /// @notice Emitted when fund receiver is set.
    event ReceiverSet(address receiver);
    /// @notice Emitted when the solace-usd price floor is set.
    event PriceFloorSet(uint256 priceFloor);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Native [**SOLACE**](../SOLACE) Token.
    function solace() external view returns (address solace_);

    /// @notice The [`FarmController(../FarmController).
    function farmController() external view returns (address controller_);

    /// @notice The receiver for options payments.
    function receiver() external view returns (address receiver_);

    /// @notice Amount of time in seconds into the future that new options will expire.
    function expiryDuration() external view returns (uint256 expiryDuration_);

    /// @notice Total number of options ever created.
    function numOptions() external view returns (uint256 numOptions_);

    /// @notice The uniswap [**SOLACE**](../SOLACE)-**ETH** pool for calculating twap.
    function solaceEthPool() external view returns (address solaceEthPool_);

    /// @notice The uniswap **ETH**-**USD** pool for calculating twap.
    function ethUsdPool() external view returns (address ethUsdPool_);

    /// @notice Interval in seconds to calculate time weighted average price in strike price.
    /// Used in [**SOLACE**](../SOLACE)-**ETH** twap.
    function solaceEthTwapInterval() external view returns (uint32 twapInterval_);

    /// @notice Interval in seconds to calculate time weighted average price in strike price.
    /// Used in **ETH**-**USD** twap.
    function ethUsdTwapInterval() external view returns (uint32 twapInterval_);

    /// @notice The relative amount of the eth value that a user must pay, measured in BPS.
    /// Only applies to the [**SOLACE**](../SOLACE)-**ETH** pool.
    function swapRate() external view returns (uint16 swapRate_);

    /// @notice The floor price of [**SOLACE**](./SOLACE) measured in **USD**.
    /// Specifically, whichever stablecoin is in the **ETH**-**USD** pool.
    function priceFloor() external view returns (uint256 priceFloor_);

    /**
     * @notice The amount of [**SOLACE**](./SOLACE) that a user is owed if any.
     * @param user The user.
     * @return amount The amount.
     */
    function unpaidSolace(address user) external view returns (uint256 amount);

    struct Option {
        uint256 rewardAmount; // The amount of SOLACE out.
        uint256 strikePrice;  // The amount of ETH in.
        uint256 expiry;       // The expiration timestamp.
    }

    /**
     * @notice Get information about an option.
     * @param optionID The ID of the option to query.
     * @return rewardAmount The amount of [**SOLACE**](../SOLACE) out.
     * @return strikePrice The amount of **ETH** in.
     * @return expiry The expiration timestamp.
     */
    function getOption(uint256 optionID) external view returns (uint256 rewardAmount, uint256 strikePrice, uint256 expiry);

    /**
     * @notice Calculate the strike price for an amount of [**SOLACE**](../SOLACE).
     * @param rewardAmount Amount of [**SOLACE**](../SOLACE).
     * @return strikePrice Strike Price in **ETH**.
     */
    function calculateStrikePrice(uint256 rewardAmount) external view returns (uint256 strikePrice);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Creates an option for the given `rewardAmount`.
     * Must be called by the [`FarmController(./FarmController).
     * @param recipient The recipient of the option.
     * @param rewardAmount The amount to reward in the Option.
     * @return optionID The ID of the newly minted option.
     */
    function createOption(address recipient, uint256 rewardAmount) external returns (uint256 optionID);

    /**
     * @notice Exercises an Option.
     * `msg.sender` must pay `option.strikePrice` **ETH**.
     * `msg.sender` will receive `option.rewardAmount` [**SOLACE**](../SOLACE).
     * Can only be called by the Option owner or approved.
     * Can only be called before `option.expiry`.
     * @param optionID The ID of the Option to exercise.
     */
    function exerciseOption(uint256 optionID) external payable;

    /**
     * @notice Exercises an Option in part.
     * `msg.sender` will pay `msg.value` **ETH**.
     * `msg.sender` will receive a fair amount of [**SOLACE**](../SOLACE).
     * Can only be called by the Option owner or approved.
     * Can only be called before `option.expiry`.
     * @param optionID The ID of the Option to exercise.
     */
    function exerciseOptionInPart(uint256 optionID) external payable;

    /**
     * @notice Transfers the unpaid [**SOLACE**](../SOLACE) to the user.
     */
    function withdraw() external;

    /**
     * @notice Sends this contract's **ETH** balance to `receiver`.
     */
    function sendValue() external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
    * @notice Sets the [**SOLACE**](../SOLACE) native token.
    * Can only be called by the current [**governor**](/docs/protocol/governance).
    * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
    */
    function setSolace(address solace_) external;

    /**
     * @notice Sets the [`FarmController(../FarmController) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param controller The address of the new [`FarmController(../FarmController).
     */
    function setFarmController(address controller) external;

    /**
     * @notice Sets the recipient for Option payments.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param receiver The new recipient.
     */
    function setReceiver(address payable receiver) external;

    /**
     * @notice Sets the time into the future that new Options will expire.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param expiryDuration_ The duration in seconds.
     */
    function setExpiryDuration(uint256 expiryDuration_) external;

    /**
     * @notice Sets the [**SOLACE**](../SOLACE)-**ETH** pool for twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pool The address of the pool.
     * @param solaceIsToken0 True if [**SOLACE**](./SOLACE) is token0 in the pool, false otherwise.
     * @param interval The interval of the twap.
     */
    function setSolaceEthPool(address pool, bool solaceIsToken0, uint32 interval) external;

    /**
     * @notice Sets the **ETH**-**USD** pool for twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pool The address of the pool.
     * @param usdIsToken0 True if **USD** is token0 in the pool, false otherwise.
     * @param interval The interval of the twap.
     * @param priceFloor_ The floor price in the **USD** stablecoin.
     */
    function setEthUsdPool(address pool, bool usdIsToken0, uint32 interval, uint256 priceFloor_) external;

    /**
     * @notice Sets the interval for [**SOLACE**](../SOLACE)-**ETH** twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param interval The interval of the twap.
     */
    function setSolaceEthTwapInterval(uint32 interval) external;

    /**
     * @notice Sets the interval for **ETH**-**USD** twap calculations.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param interval The interval of the twap.
     */
    function setEthUsdTwapInterval(uint32 interval) external;

    /**
     * @notice Sets the swap rate for prices in the [**SOLACE**](../SOLACE)-**ETH** pool.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param swapRate_ The new swap rate.
     */
    function setSwapRate(uint16 swapRate_) external;

    /**
     * @notice Sets the floor price of [**SOLACE**](./SOLACE) measured in **USD**.
     * Specifically, whichever stablecoin is in the **ETH**-**USD** pool.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param priceFloor_ The new floor price.
     */
    function setPriceFloor(uint256 priceFloor_) external;

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    receive() external payable;

    /**
     * @notice Fallback function to allow contract to receive **ETH**.
     */
    fallback () external payable;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from OpenZeppelin and @uniswap/v3-periphery
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title ERC721Enhanced
 * @author solace.fi
 * @notice An extension of `ERC721`.
 *
 * The base is OpenZeppelin's `ERC721Enumerable` which also includes the `Metadata` extension. This extension includes simpler transfers, gasless approvals, and better enumeration.
 */
interface IERC721Enhanced is IERC721Enumerable {

    /***************************************
    SIMPLER TRANSFERS
    ***************************************/

    /**
     * @notice Transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `transferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function transfer(address to, uint256 tokenID) external;

    /**
     * @notice Safely transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `safeTransferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function safeTransfer(address to, uint256 tokenID) external;

    /***************************************
    GASLESS APPROVALS
    ***************************************/

    /**
     * @notice Approve of a specific `tokenID` for spending by `spender` via signature.
     * @param spender The account that is being approved.
     * @param tokenID The ID of the token that is being approved for spending.
     * @param deadline The deadline timestamp by which the call must be mined for the approve to work.
     * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`.
     * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`.
     * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`.
     */
    function permit(
        address spender,
        uint256 tokenID,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the current nonce for `tokenID`. This value must be
     * included whenever a signature is generated for `permit`.
     * Every successful call to `permit` increases ``tokenID``'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @param tokenID ID of the token to request nonce.
     * @return nonce Nonce of the token.
     */
    function nonces(uint256 tokenID) external view returns (uint256 nonce);

    /**
     * @notice The permit typehash used in the `permit` signature.
     * @return typehash The typehash for the `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external view returns (bytes32 typehash);

    /**
     * @notice The domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return seperator The domain seperator for `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 seperator);

    /***************************************
    BETTER ENUMERATION
    ***************************************/

    /**
     * @notice Lists all tokens.
     * Order not specified.
     * @dev This function is more useful off chain than on chain.
     * @return tokenIDs The list of token IDs.
     */
    function listTokens() external view returns (uint256[] memory tokenIDs);

    /**
     * @notice Lists the tokens owned by `owner`.
     * Order not specified.
     * @dev This function is more useful off chain than on chain.
     * @return tokenIDs The list of token IDs.
     */
    function listTokensOfOwner(address owner) external view returns (uint256[] memory tokenIDs);

    /**
     * @notice Determines if a token exists or not.
     * @param tokenID The ID of the token to query.
     * @return status True if the token exists, false if it doesn't.
     */
    function exists(uint256 tokenID) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}