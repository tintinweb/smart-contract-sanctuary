// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.4;

// https://github.com/ethereum/EIPs/issues/900

interface EIP900 {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount, bytes calldata data) external;
    function stakeFor(address user, uint256 amount, bytes calldata data) external;
    function unstake(uint256 amount, bytes calldata data) external;
    function totalStakedFor(address addr) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function token() external view returns (address);
    function supportsHistory() external pure returns (bool);

    /* optional
    function lastStakedFor(address addr) external view returns (uint256);
    function totalStakedForAt(address addr, uint256 blockNumber) external view returns (uint256);
    function totalStakedAt(uint256 blockNumber) external view returns (uint256);
    */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./EIP900.sol";

import "hardhat/console.sol";

contract ParibusStakeContractV3 is EIP900, Ownable, Pausable {
    struct UserShare {
        uint256 tokensStaked;
        uint256 tokensStakedPower;
        uint256 shareAmount;
        uint256 alreadyClaimed;
        uint256 createdAt;
    }

    struct UserTotalCache {
        uint256 totalShareAmount;
        uint256 totalStakedAmount;
        uint256 totalStakedPowerAmount;
    }

    uint256 constant ERROR_SIMULATE_STAKE_OK = 0x00;
    uint256 constant ERROR_SIMULATE_STAKE_NO_MORE_TOKENS_TO_UNLOCK = 0x01;
    uint256 constant ERROR_SIMULATE_STAKE_STAKED_TOKENS_EXCEEDED_CONTRACT_MAXIMUM = 0x02;
    uint256 constant ERROR_SIMULATE_STAKE_STAKED_TOKENS_BELOW_USER_STAKED_REQUIREMENT = 0x04;
    uint256 constant ERROR_SIMULATE_STAKE_STAKED_TOKENS_EXCEEDED_USER_STAKED_REQUIREMENT = 0x08;
    uint256 constant ERROR_SIMULATE_STAKE_NOT_ENOUGH_ALLOWANCE = 0x10;
    uint256 constant ERROR_SIMULATE_STAKE_NOT_ENOUGH_TOKENS = 0x20;
    uint256 constant ERROR_SIMULATE_STAKE_AMOUNT_EQUAL_ZERO = 0x40;
    uint256 constant ERROR_SIMULATE_STAKE_AMOUNT_TOO_LARGE = 0x80;
    uint256 constant ERROR_SIMULATE_STAKE_SHARE_AMOUNT_LESS_THAN_ZERO = 0x100;

    uint256 constant private SHARE_NOT_DEPLETED = 2 ** 255;

    IERC20 immutable public stakingToken;
    IERC20 immutable public rewardToken;

    uint256 fullyUnlockedAt;
    uint256 _unlockTokenAmountPerSecond;
    uint256 _lastTimeWhenUnlockedTokens;

    uint256 amountOfShares;

    uint256 amountOfStakedTokens;
    uint256 amountOfStakedTokensPower;

    uint256 amountOfTokensInLockedPool;
    uint256 amountOfTokensInUnlockedPool;
    uint256 amountOfPhantomTokensInUnlockedPool;

    uint256 counterAmountOfAlreadyClaimedTokens;
    uint256 counterAmountOfAlreadyUnlockedTokens;
    uint256 counterAmountOfTokensTransferedIntoRewardPool;

    uint256 immutable minimumAmountOfStakedTokenPossible;
    uint256 immutable maximumAmountOfStakedTokenPossible;

    mapping (address => UserShare[]) mapOfUserToUserShare;
    mapping (address => UserTotalCache) mapOfUserToUserTotal;

    uint256 immutable penaltyPeriod;
    uint256 immutable penaltyNumber;

    uint256 immutable maximumAmountOfStakedTokenAllowed;

    string poolName;

    ///
    /// @param _stakingToken token that should be staked
    /// @param _rewardToken token that will be rewarded
    /// @param _penaltyPeriod for how long penalty should last after making a stake
    /// @param _penaltyNumber how big % should user get when withdrawing reward after penalty is applied
    /// @param _maximumAmountOfStakedTokenAllowed maximum limit of tokens that can be staked (sum of all staked tokens)
    /// @param _poolName Name of pool
    /// @param _minimumAmountOfStakedTokenPossible minimum allowed amount of toknes per user (0 for no limit)
    /// @param _maximumAmountOfStakedTokenPossible maximum allowed amount of toknes per user (0 for no limit)
    ///
    constructor(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint256 _penaltyPeriod,
        uint256 _penaltyNumber,
        uint256 _maximumAmountOfStakedTokenAllowed,
        string memory _poolName,
        uint256 _minimumAmountOfStakedTokenPossible,
        uint256 _maximumAmountOfStakedTokenPossible
    ) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        poolName = _poolName;

        penaltyPeriod = _penaltyPeriod;
        penaltyNumber = _penaltyNumber;

        maximumAmountOfStakedTokenAllowed = _maximumAmountOfStakedTokenAllowed;

        minimumAmountOfStakedTokenPossible = _minimumAmountOfStakedTokenPossible;
        maximumAmountOfStakedTokenPossible = _maximumAmountOfStakedTokenPossible;

        if (_minimumAmountOfStakedTokenPossible > 0 && _maximumAmountOfStakedTokenPossible > 0) {
            require(_maximumAmountOfStakedTokenPossible >= _minimumAmountOfStakedTokenPossible, 'ParibusStakeContractV3: maximum staked can not be smaller than minimum');
        }
    }

    ///
    /// @dev implementation of staking tokens
    ///
    /// @param _from From which account we will subtract staked tokens
    /// @param _to To which account we will grant share
    /// @param _amount How many tokens will should be staked
    ///
    function _stakeFor(address _from, address _to, uint256 _amount) whenNotPaused internal {
        unlockTokens();

        require(amountOfTokensInLockedPool > 0, 'ParibusStakeContractV3: no more tokens to unlock');

        (uint256 newShareAmount, uint256 sharePower) = _shareCalculate(_amount);
        require(newShareAmount > 0, 'ParibusStakeContractV3: Amount staked will not grant any reward');

        UserShare memory newShare = UserShare(_amount, sharePower, newShareAmount, 0, block.timestamp);
        mapOfUserToUserShare[_to].push(newShare);

        UserTotalCache storage userTotalStorage = mapOfUserToUserTotal[_to];
        userTotalStorage.totalShareAmount += newShareAmount;
        userTotalStorage.totalStakedAmount += _amount;
        userTotalStorage.totalStakedPowerAmount += sharePower;

        amountOfStakedTokens += _amount;
        amountOfStakedTokensPower += sharePower;
        amountOfShares += newShareAmount;

        _ensureStakedTokensAre(userTotalStorage.totalStakedAmount);
        require(amountOfStakedTokens <= maximumAmountOfStakedTokenAllowed, "ParibusStakeContractV3: maximum amount of tokens reached");
        require(
            stakingToken.transferFrom(_from, address(this), _amount),
            "ParibusStakeContractV3: transfer into staking staking pool failed"
        );

        emit ShareCreated(_to, _amount, newShareAmount);
        emit Staked(_to, _amount, totalStakedFor(_to), "");
    }

    ///
    /// @notice Unlock tokens that are in locked pool in accordance to schedule
    ///
    function unlockTokens() whenNotPaused public {
        uint256 time = block.timestamp;

        (
            /*uint256 currentTimestamp*/,
            uint256 totalTokensUnlocked,
            uint256 totalTokensLocked,
            uint256 tokensUnlockedPerSec
        ) = _calculatePotentialAdvanceAt(time);

        if (totalTokensUnlocked != amountOfTokensInUnlockedPool) {
            uint256 unlockedTokens = totalTokensUnlocked - amountOfTokensInUnlockedPool;
            counterAmountOfAlreadyUnlockedTokens += unlockedTokens;

            amountOfTokensInUnlockedPool = totalTokensUnlocked;
        }

        if (totalTokensLocked != amountOfTokensInLockedPool) {
            amountOfTokensInLockedPool = totalTokensLocked;
        }

        if (tokensUnlockedPerSec != _unlockTokenAmountPerSecond) {
            _unlockTokenAmountPerSecond = tokensUnlockedPerSec;

            emit UnlockedTokensChangedRewardPerSecond(_unlockTokenAmountPerSecond);
        }

        _lastTimeWhenUnlockedTokens = time;
    }

    ///
    /// @notice Staking tokens
    ///
    /// @param _amount Amount of tokens to stake
    /// @dev param _data is ignored, used as compatibility with EIP900
    ///
    function stake(uint256 _amount, bytes calldata /*_data*/) override external {
        _stakeFor(msg.sender, msg.sender, _amount);
    }

    ///
    /// @notice Staking tokens for another user. Keep in mind, that staked tokens will be transferred to _user account,
    ///         and original sender will not be able to withdrawn them later.
    ///
    /// @param _user Amount of tokens to stake
    /// @param _amount Amount of tokens to stake
    /// @dev param _data is ignored, used as compatibility with EIP900
    ///
    function stakeFor(address _user, uint256 _amount, bytes calldata /*_data*/) override external {
        _stakeFor(msg.sender, _user, _amount);
    }

    ///
    /// @notice Unstaking tokens
    ///
    /// @param _amount How many tokens will should be staked
    /// @dev param _data is ignored, used as compatibility with EIP900
    ///
    function unstake(uint256 _amount, bytes calldata /* data */) override external {
        _unstake(msg.sender, _amount);
    }

    ///
    /// @notice Get amount of tokens that _user staked
    ///
    /// @param _user Address of user
    ///
    function totalStakedFor(address _user) override public view returns (uint256) {
        return mapOfUserToUserTotal[_user].totalStakedAmount;
    }

    ///
    /// @notice Amount of all tokens that are staked
    ///
    function totalStaked() override external view returns (uint256) {
        return amountOfStakedTokens;
    }

    ///
    /// @notice Which token is used for staking
    ///
    function token() override external view returns (address) {
        return address(stakingToken);
    }

    ///
    /// @notice Does this contract supports history extension of EIP900. We don't
    ///
    function supportsHistory() override external pure returns (bool) {
        // if you want history, fetch data at older block
        return false;
    }

    ///
    /// @notice Transfer more reward tokens into reward pool
    ///
    /// @param _amount How many tokens should be transferred into pool
    ///
    /// @dev This method only transfers reward token, and doesnt adjust end time of pool unlock. This will mean that
    ///      there will be more tokens released to unlocked per second.
    ///
    function rewardTransferIntoPool(uint256 _amount) whenNotPaused onlyOwner external {
        if (amountOfTokensInLockedPool > 0) {
            unlockTokens();
        } else {
            _lastTimeWhenUnlockedTokens = block.timestamp;
        }

        require(_amount > 0, 'ParibusStakeContractV3: you can not transfer 0 tokens');
        require(_unlockTokenAmountPerSecond > 0, 'ParibusStakeContractV3: pool was never opened');
        require(fullyUnlockedAt > block.timestamp, 'ParibusStakeContractV3: pool is already completely unlocked');

        require(
            rewardToken.transferFrom(msg.sender, address(this), _amount),
            "ParibusStakeContractV3: transfer into reward pool failed"
        );

        amountOfTokensInLockedPool += _amount;
        counterAmountOfTokensTransferedIntoRewardPool += _amount;
        _unlockTokenAmountPerSecond = amountOfTokensInLockedPool / (fullyUnlockedAt - block.timestamp);

        // This should not happen, since we are increasing amountOfTokensToBeUnlocked so in worst case scenario
        // _unlockTokenAmountPerSecond would be the same before calling this method. But just to be sure
        assert(_unlockTokenAmountPerSecond > 0);

        emit RewardPoolTokensTransfered(msg.sender, _amount, amountOfTokensInLockedPool, _unlockTokenAmountPerSecond);
    }

    ///
    /// @notice Change end time when this pool should unlock
    ///
    /// @param _endTimestamp Unix timestamp
    ///
    /// @dev This method only changes end time of pool. This will mean that only thing that chagnes is how many
    ///      tokens are released per second.
    ///
    function rewardChangeEndTime(uint256 _endTimestamp) whenNotPaused onlyOwner external {
        if (amountOfTokensInLockedPool > 0) {
            unlockTokens();
        } else {
            _lastTimeWhenUnlockedTokens = block.timestamp;
        }

        require(_unlockTokenAmountPerSecond > 0, 'ParibusStakeContractV3: pool was never opened');
        require(amountOfTokensInLockedPool > 0, 'ParibusStakeContractV3: pool is empty');
        require(_endTimestamp > block.timestamp, 'ParibusStakeContractV3: pool time is set in the past');

        uint256 ogFullyUnlocked = fullyUnlockedAt;
        fullyUnlockedAt = _endTimestamp;
        _unlockTokenAmountPerSecond = amountOfTokensInLockedPool / (fullyUnlockedAt - block.timestamp);
        require(_unlockTokenAmountPerSecond > 0, 'ParibusStakeContractV3: can not unlock zero tokens per second');

        emit RewardPoolTimeSet(msg.sender, (_endTimestamp - ogFullyUnlocked), fullyUnlockedAt, _unlockTokenAmountPerSecond);
    }

    ///
    /// @notice Transfer more reward tokens and change when this pool should be unlocked
    ///
    /// @param _amount How many tokens should be transferred into pool
    /// @param _endTimestamp Unix timestamp
    ///
    function rewardTransferAndChange(uint256 _amount, uint256 _endTimestamp) whenNotPaused onlyOwner external {
        if (amountOfTokensInLockedPool > 0) {
            unlockTokens();
        } else {
            _lastTimeWhenUnlockedTokens = block.timestamp;
        }

        uint256 ogFullyUnlocked = fullyUnlockedAt;
        fullyUnlockedAt = _endTimestamp;

        require(fullyUnlockedAt > block.timestamp, 'ParibusStakeContractV3: fully open time is set in the past');
        require(_amount > 0, 'ParibusStakeContractV3: can not transfer zero tokens to reward pool');

        require(
            rewardToken.transferFrom(msg.sender, address(this), _amount),
            "ParibusStakeContractV3: transfer into reward pool failed"
        );

        counterAmountOfTokensTransferedIntoRewardPool += _amount;
        amountOfTokensInLockedPool += _amount;
        _unlockTokenAmountPerSecond = amountOfTokensInLockedPool / (fullyUnlockedAt - block.timestamp);
        assert(_unlockTokenAmountPerSecond * (fullyUnlockedAt - block.timestamp) <= amountOfTokensInLockedPool);

        emit RewardPoolTokensTransfered (msg.sender, _amount , amountOfTokensInLockedPool, _unlockTokenAmountPerSecond);
        emit RewardPoolTimeSet          (msg.sender,  (_endTimestamp - ogFullyUnlocked), fullyUnlockedAt, _unlockTokenAmountPerSecond);
    }

    ///
    /// @notice Get general info about contract
    ///
    function getPoolInfo()
        external view
        returns (
            string memory name,
            uint256 penaltyPercent,
            uint256 penaltyLockupPeriod,
            uint256 maximumStakedTokenAllowed,
            uint256 unlockedAt,
            uint256 minAmountOfStakedTokensRequired,
            uint256 maxAmountOfStakedTokensRequired
        )
    {
        return (
            poolName,
            100 - uint32(penaltyNumber),
            penaltyPeriod,
            maximumAmountOfStakedTokenAllowed,
            fullyUnlockedAt,
            minimumAmountOfStakedTokenPossible,
            maximumAmountOfStakedTokenPossible
        );
    }

    ///
    /// @notice Get state of contract
    ///
    function getPoolState()
        external view
        returns (
            uint256 stakedTokenCurrentAmount,
            uint256 updateLastTime,
            uint256 updateUnlocksPerSecond,
            uint256 rewardTokenFromAllTimeToDistribute,
            uint256 rewardTokenTotalClaimedRewards,
            uint256 rewardTokenTotalUnlockedTokens,
            uint256 rewardTokensCurrentlyUnlocked,
            uint256 rewardTokensCurrentlyToBeUnlocked
        )
    {
        updateLastTime = _lastTimeWhenUnlockedTokens;
        updateUnlocksPerSecond = _unlockTokenAmountPerSecond;

        rewardTokenFromAllTimeToDistribute = counterAmountOfTokensTransferedIntoRewardPool;
        rewardTokenTotalClaimedRewards = counterAmountOfAlreadyClaimedTokens;
        rewardTokenTotalUnlockedTokens = counterAmountOfAlreadyUnlockedTokens;

        rewardTokensCurrentlyUnlocked = amountOfTokensInUnlockedPool;
        rewardTokensCurrentlyToBeUnlocked = amountOfTokensInLockedPool;

        stakedTokenCurrentAmount = amountOfStakedTokens;
    }

    ///
    /// @notice Emergency withdrawn tokens from contract. Only for owner, and only when paused.
    ///
    function emergencyWithdrawn() onlyOwner whenPaused external {
        uint256 stakingAmount;
        uint256 rewardAmount;

        if (rewardToken == stakingToken) {
            stakingAmount = rewardToken.balanceOf(address(this));
            require(rewardToken.transfer(msg.sender, stakingAmount), 'ParibusStakeContractV3: failed to withdrawn tokens');
        } else {
            stakingAmount = stakingToken.balanceOf(address(this));
            rewardAmount = rewardToken.balanceOf(address(this));

            require(stakingToken.transfer(msg.sender, stakingAmount), 'ParibusStakeContractV3: failed to withdrawn staking tokens');
            require(rewardToken.transfer(msg.sender, rewardAmount), 'ParibusStakeContractV3: failed to withdrawn reward tokens');
        }

        emit EmergencyWithdrawn(msg.sender, stakingAmount, rewardAmount);
    }

    ///
    /// @notice Pause contract functionality. Only for owner
    ///
    function pause() onlyOwner whenNotPaused external {
        _pause();
    }

    ///
    /// @notice Unpause contract functionality. Only for owner
    ///
    function unpause() onlyOwner whenPaused external {
        _unpause();
    }

    ///
    /// @notice Get current user reward for specific user
    ///
    function getUserRewardInformationFor(address _user)
        view public
        returns (
            uint256 currentTimestamp,
            uint256 stakedTokenPenaltyFree,
            uint256 rewardAmountPenaltyFree,
            uint256 stakedTokenPenalty,
            uint256 rewardAmountAfterPenalty,
            uint256 rewardAmountLost,
            uint256 rewardPenaltyTimestamp
    ) {
        return _getUserRewardInformationFor(_user, block.timestamp);
    }

    ///
    /// @dev Implementation of getUserRewardInformationFor
    ///
    function _getUserRewardInformationFor(address _user, uint256 _time)
        internal view
        returns (
            uint256 currentTimestamp,
            uint256 stakedTokenPenaltyFree,
            uint256 rewardAmountPenaltyFree,
            uint256 stakedTokenPenalty,
            uint256 rewardAmountAfterPenalty,
            uint256 rewardAmountLost,
            uint256 rewardPenaltyTimestamp
        )
    {
        require(_time >= _lastTimeWhenUnlockedTokens, 'ParibusStakeContractV3: this contract does not support calculation before snapshot');

        (
            /*uint256 currentTimestamp*/,
            uint256 totalTokensUnlocked,
            /*uint256 totalTokensLocked*/,
            /*uint256 tokensUnlockedPerSec*/
        ) = _calculatePotentialAdvanceAt(_time);

        uint256 oldestPenaltyTimestamp = amountOfTokensInLockedPool > 0 ?
            _time - penaltyPeriod :
            _time;

        for (uint256 lastProcessedId; lastProcessedId < mapOfUserToUserShare[_user].length; ++lastProcessedId) {
            UserShare storage currentShare = mapOfUserToUserShare[_user][lastProcessedId];

            (
                uint256 shareRewardAfterPenalty,
                uint256 sharePenalty,
                /* uint256 _totalTokensUnlocked */
            ) = _rewardCalculatePartialRewardFromShare(
                _user,
                lastProcessedId,
                currentShare.tokensStaked,
                oldestPenaltyTimestamp,
                totalTokensUnlocked
            );

            if (sharePenalty > 0) {
                stakedTokenPenalty += currentShare.tokensStaked;
                rewardAmountAfterPenalty += shareRewardAfterPenalty;
                rewardAmountLost += sharePenalty;
                rewardPenaltyTimestamp += currentShare.createdAt + penaltyPeriod;
            } else {
                stakedTokenPenaltyFree += currentShare.tokensStaked;
                rewardAmountPenaltyFree += shareRewardAfterPenalty;
            }
        }

        currentTimestamp = block.timestamp;
    }

    ///
    /// @dev Method for calculating state of contract at any given time
    ///
    function _calculatePotentialAdvanceAt(uint256 _time)
        internal view
        returns (
            uint256 currentTimestamp,
            uint256 totalTokensUnlocked,
            uint256 totalTokensLocked,
            uint256 tokensUnlockedPerSec
        )
    {
        return _calculatePotentialAdvanceAt(
            _time,
            amountOfStakedTokens,
            amountOfTokensInUnlockedPool,
            amountOfTokensInLockedPool,
            _unlockTokenAmountPerSecond,
            _lastTimeWhenUnlockedTokens
        );
    }

    ///
    /// @dev Method for calculating state of contract at any given time
    ///
    function _calculatePotentialAdvanceAt(
        uint256 _time,
        uint256 _amountOfTokensStaked,
        uint256 _amountOfTokensAlreadyUnlocked,
        uint256 _amountOfTokensToBeUnlocked,
        uint256 _unlockTokensPerSecond,
        uint256 _lastTime
    )
        internal virtual view
        returns (
            uint256 currentTimestamp,
            uint256 totalTokensUnlocked,
            uint256 totalTokensLocked,
            uint256 tokensUnlockedPerSec
        )
    {
        if (_time == _lastTime) {
            // we already updated this information in this block, so let's bail out quick
            return (
                _time,
                _amountOfTokensAlreadyUnlocked,
                _amountOfTokensToBeUnlocked,
                _unlockTokensPerSecond
            );
        }

        if (_amountOfTokensStaked > 0) {
            if (_time >= fullyUnlockedAt) {
                return (
                    _time,
                    _amountOfTokensAlreadyUnlocked + _amountOfTokensToBeUnlocked,
                    0,
                    _unlockTokensPerSecond
                );
            } else {
                uint256 amountToBeUnlocked = _unlockTokensPerSecond * (_time - _lastTime);

                return (
                    _time,
                    _amountOfTokensAlreadyUnlocked + amountToBeUnlocked,
                    _amountOfTokensToBeUnlocked - amountToBeUnlocked,
                    _unlockTokensPerSecond
                );
            }
        } else {
            // in case that we are already at fullyUnlockedAt time, we won't do anything as first user will unlock
            // everything. This is edge case and we really can't do anything about it
            if (_time < fullyUnlockedAt) {
                return (
                    _time,
                    _amountOfTokensAlreadyUnlocked,
                    _amountOfTokensToBeUnlocked,
                    _amountOfTokensToBeUnlocked / (fullyUnlockedAt - _time)
                );
            }
        }

        return (_time, _amountOfTokensAlreadyUnlocked, _amountOfTokensToBeUnlocked, _unlockTokensPerSecond);
    }

    ///
    /// @notice Method used to simulate stake, to check how much tokens user will get after certain period of time
    ///
    /// @param _sender in what context simulation should be performed
    /// @param _amount how many tokens should be considered for simulation
    /// @param _time for how long simulation should run
    ///
    /// @dev This method returns reward without considering penalty
    ///
    function simulateStake(address _sender, uint256 _amount, uint256 _time)
        external view
        returns (
            uint256 currentTimestamp,
            uint256 rewardFull,
            uint256 returnCode
        )
    {
        uint256 totalTokensUnlocked;
        uint256 totalTokensLocked;

        (
            currentTimestamp,
            totalTokensUnlocked,
            totalTokensLocked,
            /*tokensUnlockedPerSec*/returnCode
        ) = _calculatePotentialAdvanceAt(block.timestamp);

        if (totalTokensLocked == 0) {
            return (block.timestamp, 0, ERROR_SIMULATE_STAKE_NO_MORE_TOKENS_TO_UNLOCK);
        }

        if (_amount + amountOfStakedTokens > maximumAmountOfStakedTokenAllowed) {
            return (block.timestamp, 0, ERROR_SIMULATE_STAKE_STAKED_TOKENS_EXCEEDED_CONTRACT_MAXIMUM);
        }

        (uint256 newShareAmount, uint256 newSharePower) = _shareCalculate(_amount, totalTokensUnlocked);
        if (newShareAmount == 0) {
            return (block.timestamp, 0, ERROR_SIMULATE_STAKE_SHARE_AMOUNT_LESS_THAN_ZERO);
        }

        uint256 amountOfStakedTokensSim = amountOfStakedTokensPower + newSharePower;
        uint256 amountOfSharesSim = amountOfShares + newShareAmount;

        (
            currentTimestamp,
            totalTokensUnlocked,
            totalTokensLocked,
            /*tokensUnlockedPerSec*/
        ) = _calculatePotentialAdvanceAt(
            block.timestamp + _time,
            amountOfStakedTokensSim,
            totalTokensUnlocked,
            totalTokensLocked,
            /*tokensUnlockedPerSec*/returnCode,
            block.timestamp
        );

        {
            UserTotalCache storage userTotalStorage = mapOfUserToUserTotal[_sender];
            if (userTotalStorage.totalStakedAmount + _amount < minimumAmountOfStakedTokenPossible) {
                return (block.timestamp, 0, ERROR_SIMULATE_STAKE_STAKED_TOKENS_BELOW_USER_STAKED_REQUIREMENT);
            }

            if (maximumAmountOfStakedTokenPossible > 0 && (userTotalStorage.totalStakedAmount + _amount) > maximumAmountOfStakedTokenPossible) {
                return (block.timestamp, 0, ERROR_SIMULATE_STAKE_STAKED_TOKENS_EXCEEDED_USER_STAKED_REQUIREMENT);
            }
        }

        uint256 error = ERROR_SIMULATE_STAKE_OK;
        if (stakingToken.allowance(_sender, address(this)) < _amount) {
            error |= ERROR_SIMULATE_STAKE_NOT_ENOUGH_ALLOWANCE;
        }

        if (stakingToken.balanceOf(_sender) < _amount) {
            error |= ERROR_SIMULATE_STAKE_NOT_ENOUGH_TOKENS;
        }

        return (
            currentTimestamp,
            _rewardCalculateRewardDirectly(
                newShareAmount,
                newSharePower,
                0,
                totalTokensUnlocked,
                amountOfStakedTokensSim,
                amountOfSharesSim
            ),
            error
        );
    }

    ///
    /// @notice Method used to simulate unstake, to check how much tokens user will get if unstake right now
    ///
    /// @param _sender in what context simulation should be performed
    /// @param _amount how many tokens should be considered for simulation
    ///
    function simulateUnstake(address _sender, uint256 _amount)
        external view
        returns (
            uint256 currentTimestamp,
            uint256 reward,
            uint256 penalty,
            uint256 unlockTimestamp,
            uint256 returnCode
        )
    {
        uint256 totalTokensUnlocked;

        (
            currentTimestamp,
            totalTokensUnlocked,
            /*totalTokensLocked*/,
            /*tokensUnlockedPerSec*/
        ) = _calculatePotentialAdvanceAt(block.timestamp);

        if (_amount == 0) {
            return (currentTimestamp, 0, 0, 0, ERROR_SIMULATE_STAKE_AMOUNT_EQUAL_ZERO);
        }

        if (totalStakedFor(_sender) < _amount) {
            return (currentTimestamp, 0, 0, 0, ERROR_SIMULATE_STAKE_AMOUNT_TOO_LARGE);
        }

        {
            UserTotalCache storage userTotalStorage = mapOfUserToUserTotal[_sender];

            uint256 totalStakedAmountAfterUnstake = userTotalStorage.totalStakedAmount - _amount;

            if (totalStakedAmountAfterUnstake > 0 && totalStakedAmountAfterUnstake < minimumAmountOfStakedTokenPossible) {
                return (currentTimestamp, 0, 0, 0, ERROR_SIMULATE_STAKE_STAKED_TOKENS_BELOW_USER_STAKED_REQUIREMENT);
            }
        }

        {
            uint256 oldestPenaltyTimestamp = amountOfTokensInLockedPool > 0 ?
                block.timestamp - penaltyPeriod :
                block.timestamp;

            for (uint it; it < mapOfUserToUserShare[_sender].length; ++it) {
                UserShare storage currentShare = mapOfUserToUserShare[_sender][it];

                (
                    uint256 shareRewardAfterPenalty,
                    uint256 sharePenalty,
                    /*uint256 leftTokenAmount*/
                ) = _rewardCalculatePartialRewardFromShare(_sender, it, _amount, oldestPenaltyTimestamp, totalTokensUnlocked);

                if (sharePenalty > 0) {
                    reward += shareRewardAfterPenalty;
                    penalty += sharePenalty;
                    unlockTimestamp = currentShare.createdAt + penaltyPeriod;
                } else {
                    reward += shareRewardAfterPenalty;
                }

                _amount -= currentShare.tokensStaked > _amount ? _amount : currentShare.tokensStaked;

                if (_amount == 0) {
                    break;
                }
            }
        }
    }

    ///
    /// @notice Method used for transferring already unlocked tokens to user that staked tokens
    ///
    function claimUnlocked() public {
        unlockTokens();

        UserShare[] storage allUserShares = mapOfUserToUserShare[msg.sender];
        uint256 oldestTimestamp = amountOfTokensInLockedPool > 0 ?
            block.timestamp - penaltyPeriod :
            block.timestamp;
        uint256 fullRewardInTokens;

        if (allUserShares.length == 0) {
            return;
        }

        for (uint256 it; it < allUserShares.length; ++it) {
            UserShare storage currentShare = allUserShares[it];

            if (currentShare.createdAt >= oldestTimestamp) {
                // if we have share that is newer than our oldest possible penalty-free share, we can finish early
                break;
            }

            uint256 fullReward = _rewardCalculateRewardDirectly(currentShare.shareAmount, currentShare.tokensStakedPower, currentShare.alreadyClaimed);

            currentShare.alreadyClaimed += fullReward;
            fullRewardInTokens += fullReward;

            emit ClaimedTokensFromShare(msg.sender, it, fullReward, currentShare.alreadyClaimed);
        }

        if (fullRewardInTokens == 0) {
            return;
        }

        require(
            rewardToken.transfer(msg.sender, fullRewardInTokens),
            'ParibusStakeContractV3: transfer from reward pool failed!'
        );

        amountOfTokensInUnlockedPool -= fullRewardInTokens;
        amountOfPhantomTokensInUnlockedPool += fullRewardInTokens;
        counterAmountOfAlreadyClaimedTokens += fullRewardInTokens;
    }

    ///
    /// @dev Helper function for calculating how many shares should user get
    ///
    function _shareCalculate(uint256 _amount) private view returns (uint256 share, uint256 sharePower) {
        uint256 sumOfAllTokens = amountOfTokensInUnlockedPool + amountOfPhantomTokensInUnlockedPool + amountOfStakedTokens;

        if (sumOfAllTokens == 0 || amountOfShares == 0) {
            return (_amount * 10 ** 18, _amount);
        }

        share = _amount * amountOfShares / sumOfAllTokens;
        sharePower = _rewardCalculateRewardDirectly(share, 0, 0);
    }

    ///
    /// @dev Helper function for calculating how many shares should user get
    ///
    function _shareCalculate(uint256 _amount, uint256 _amountOfTokensAlreadyUnlocked)
        private view returns (uint256 share, uint256 sharePower)
    {
        uint256 sumOfAllTokens = _amountOfTokensAlreadyUnlocked + amountOfPhantomTokensInUnlockedPool + amountOfStakedTokens;

        if (sumOfAllTokens == 0) {
            return (_amount * 10 ** 18, _amount);
        }

        share = _amount * amountOfShares / sumOfAllTokens;
        sharePower = _rewardCalculateRewardDirectly(share, 0, 0);
    }

    ///
    /// @dev Helper method for verifying if user has enough tokens staked
    ///
    function _ensureStakedTokensAre(uint256 _amount) private view {
        if (_amount > 0) {
            require(_amount >= minimumAmountOfStakedTokenPossible, 'ParibusStakeContractV3: not enough token staked');
            require(
                maximumAmountOfStakedTokenPossible == 0 || maximumAmountOfStakedTokenPossible >= _amount,
                'ParibusStakeContractV3: too much tokens staked'
            );
        }
    }

    function _unstake(address _from, uint256 _amount) private {
        // every method that is operating on state need current version of it
        unlockTokens();

        require(_amount > 0, 'ParibusStakeContractV3: You can not unstake zero tokens');
        require(totalStakedFor(_from) >= _amount, 'ParibusStakeContractV3: You can not unstake more tokens than you own');

        uint256 fullReward;
        uint256 fullPenalty;
        uint256 sumOfAlreadyClaimed;
        uint256 sumOfShares;
        uint256 sumOfStakedTokenPower;
        {
            uint256 it;
            UserShare[] storage userShares = mapOfUserToUserShare[_from];

            { // introducing scope, so we won't create more variables than we can
                uint256 oldestTimestamp = amountOfTokensInLockedPool > 0 ?
                    block.timestamp - penaltyPeriod :
                    block.timestamp;
                uint256 amountOfTokensToUnstake = _amount;

                for (; it < userShares.length; ++it) {
                    UserShare storage currentShare = userShares[it];

                    (
                        uint256 reward,
                        uint256 penalty,
                        uint256 leftTokenAmount
                    ) = _rewardCalculatePartialRewardFromShare(_from, it, amountOfTokensToUnstake, oldestTimestamp);

                    if (leftTokenAmount == 0) {
                        // we unstake all tokens from this share, we need to tag it as depleted
                        amountOfTokensToUnstake -= currentShare.tokensStaked;
                        currentShare.tokensStaked = 0;

                        sumOfAlreadyClaimed += currentShare.alreadyClaimed;
                        sumOfShares += currentShare.shareAmount;
                        sumOfStakedTokenPower += currentShare.tokensStakedPower;

                        emit ShareDeleted(_from, it);
                    } else {
                        // since we are left with some shares, we can assume that this is last share we are processing
                        amountOfTokensToUnstake = 0;

                        sumOfAlreadyClaimed += currentShare.alreadyClaimed;
                        sumOfShares += currentShare.shareAmount;
                        sumOfStakedTokenPower += currentShare.tokensStakedPower;

                        // but we also need to adjust it and scale it back
                        _shareScale(_from, it, currentShare.tokensStaked - leftTokenAmount);

                        sumOfAlreadyClaimed -= currentShare.alreadyClaimed;
                        sumOfShares -= currentShare.shareAmount;
                        sumOfStakedTokenPower -= currentShare.tokensStakedPower;
                    }

                    fullReward += reward;
                    fullPenalty += penalty;

                    if (amountOfTokensToUnstake == 0) {
                        if (currentShare.tokensStaked > 0) {
                            it |= SHARE_NOT_DEPLETED;
                        }
                        break;
                    }
                }
            }

            { // introducing scope, so we won't create more variables than we can
                uint256 sharesToDrop;

                if ((it & ~SHARE_NOT_DEPLETED) > 0 || (it & SHARE_NOT_DEPLETED) == 0) {
                    if ((it & SHARE_NOT_DEPLETED) == 0) {
                        // last share depleted
                        sharesToDrop = it + 1;
                        it++;
                    } else {
                        it -= SHARE_NOT_DEPLETED; // we clear the flag
                        sharesToDrop = it;
                    }

                    if (it + 1 <= userShares.length) {
                        for (uint256 jt = it; jt < userShares.length; ++jt) {
                            // we move elements around
                            userShares[jt - it].createdAt = userShares[jt].createdAt;
                            userShares[jt - it].alreadyClaimed = userShares[jt].alreadyClaimed;
                            userShares[jt - it].shareAmount = userShares[jt].shareAmount;
                            userShares[jt - it].tokensStaked = userShares[jt].tokensStaked;
                            userShares[jt - it].tokensStakedPower = userShares[jt].tokensStakedPower;

                            emit ShareMoved(_from, jt - it, jt);
                        }
                    } else {
                    }
                }

                for (; sharesToDrop > 0; sharesToDrop--) {
                    userShares.pop();
                }
            }
        }

        amountOfStakedTokens -= _amount;
        amountOfStakedTokensPower -= sumOfStakedTokenPower;
        amountOfShares -= sumOfShares;

        amountOfTokensInUnlockedPool -= (fullReward + fullPenalty);
        amountOfTokensInLockedPool += fullPenalty;
        amountOfPhantomTokensInUnlockedPool -= sumOfAlreadyClaimed;

        if (amountOfShares == 0 && amountOfTokensInUnlockedPool > 0) {
            // if for some reason we still have some tokens in unlocked pool, but no more shares, we need to
            // course correct, and either
            if (fullyUnlockedAt <= block.timestamp) {
                // give those tokens to last withdrawing user
                fullReward += amountOfTokensInUnlockedPool;
            } else {
                // or if contract is still running, we move them to locked pool
                fullPenalty += amountOfTokensInUnlockedPool;
                amountOfTokensInLockedPool += amountOfTokensInUnlockedPool;
            }

            amountOfTokensInUnlockedPool = 0;
        }

        counterAmountOfAlreadyClaimedTokens += fullReward;

        if (fullPenalty > 0) {
            uint256 newUnlockedPerSecond = amountOfTokensInLockedPool / (fullyUnlockedAt - block.timestamp);

            if (_unlockTokenAmountPerSecond != newUnlockedPerSecond) {
                _unlockTokenAmountPerSecond = newUnlockedPerSecond;
                emit UnlockedTokensChangedRewardPerSecond(_unlockTokenAmountPerSecond);
            }
        }

        require(stakingToken.transfer(_from, _amount), 'ParibusStakeContractV3: transfer out of staking pool failed');
        if (fullReward > 0) {
            require(rewardToken.transfer(_from, fullReward), 'ParibusStakeContractV3: transfer out of unlocked pool failed');
        }

        UserTotalCache storage userTotalStorage = mapOfUserToUserTotal[_from];

        userTotalStorage.totalShareAmount -= sumOfShares;
        userTotalStorage.totalStakedPowerAmount -= sumOfStakedTokenPower;
        userTotalStorage.totalStakedAmount -= _amount;

        _ensureStakedTokensAre(userTotalStorage.totalStakedAmount);

        emit Unstaked(_from, _amount, totalStakedFor(_from), "");
        claimUnlocked();
    }

    function _rewardCalculatePartialRewardFromShare(
        address _user,
        uint256 _shareId,
        uint256 _amountOfStakedTokens,
        uint256 _oldestPenaltyTime
    )
        private view
        returns (
            uint256 shareRewardAfterPenalty,
            uint256 sharePenalty,
            uint256 shareLeftAmountOfTokens
        )
    {
        return _rewardCalculatePartialRewardFromShare(_user, _shareId, _amountOfStakedTokens, _oldestPenaltyTime, amountOfTokensInUnlockedPool);
    }

    function _rewardCalculatePartialRewardFromShare(
        address _user,
        uint256 _shareId,
        uint256 _amountOfStakedTokens,
        uint256 _oldestPenaltyTime,
        uint256 _totalTokensUnlocked
    )
        private view
        returns (
            uint256 shareRewardAfterPenalty,
            uint256 sharePenalty,
            uint256 shareLeftAmountOfTokens
        )
    {
        UserShare storage currentShare = mapOfUserToUserShare[_user][_shareId];

        // to calculate reward we will always calculate full reward from share
        uint256 fullReward = _rewardCalculateRewardDirectly(currentShare.shareAmount, currentShare.tokensStakedPower, currentShare.alreadyClaimed, _totalTokensUnlocked);

        if (currentShare.createdAt >= _oldestPenaltyTime) {
            // but if your share is still in range of oldestPenaltyTime (now - penaltyPeriod), we need to call IRS on you
            shareRewardAfterPenalty = (fullReward * penaltyNumber) / 100;
            sharePenalty = fullReward - shareRewardAfterPenalty;
        } else {
            shareRewardAfterPenalty = fullReward;
        }

        if (currentShare.tokensStaked > _amountOfStakedTokens) {
            // if we want to take calculate reward for only part of tokens that are staked in this share, we need to
            // scale them back
            shareRewardAfterPenalty = (_amountOfStakedTokens * shareRewardAfterPenalty) / currentShare.tokensStaked;
            sharePenalty = (_amountOfStakedTokens * sharePenalty) / currentShare.tokensStaked;

            shareLeftAmountOfTokens = currentShare.tokensStaked - _amountOfStakedTokens;
        }
    }

    function _rewardCalculateRewardDirectly(uint256 _shareAmount, uint256 _shareStakedTokensPower, uint256 _shareClaimedTokens)
        private view returns (uint256)
    {
        uint256 sumOfTokens = amountOfTokensInUnlockedPool + amountOfPhantomTokensInUnlockedPool + amountOfStakedTokensPower;
        uint256 fullRewardBeforeAdjust = (_shareAmount * sumOfTokens) / amountOfShares;

        return fullRewardBeforeAdjust - _shareStakedTokensPower - _shareClaimedTokens;
    }

    function _rewardCalculateRewardDirectly(
        uint256 _shareAmount,
        uint256 _shareStakedTokensPower,
        uint256 _shareClaimedTokens,
        uint _amountOfTokensInUnlockedPool,
        uint256 _amountOfStakedTokensPower,
        uint256 _amountOfShares
    )
        private view returns (uint256)
    {
        uint256 sumOfTokens = _amountOfTokensInUnlockedPool + amountOfPhantomTokensInUnlockedPool + _amountOfStakedTokensPower;
        uint256 fullRewardBeforeAdjust = (_shareAmount * sumOfTokens) / _amountOfShares;

        return fullRewardBeforeAdjust - _shareStakedTokensPower - _shareClaimedTokens;
    }

    function _rewardCalculateRewardDirectly(uint256 _shareAmount, uint256 _shareStakedTokensPower, uint256 _shareClaimedTokens, uint _amountOfTokensInUnlockedPool)
        private view returns (uint256)
    {
        uint256 sumOfTokens = _amountOfTokensInUnlockedPool + amountOfPhantomTokensInUnlockedPool + amountOfStakedTokensPower;
        uint256 fullRewardBeforeAdjust = (_shareAmount * sumOfTokens) / amountOfShares;

        return fullRewardBeforeAdjust - _shareStakedTokensPower - _shareClaimedTokens;
    }

    function _shareScale(address _user, uint256 _shareId, uint256 _amountOfTokens) private {
        UserShare storage currentShare = mapOfUserToUserShare[_user][_shareId];

        uint256 newShare =  currentShare.shareAmount - (_amountOfTokens * currentShare.shareAmount / currentShare.tokensStaked);
        uint256 newClaimed = currentShare.alreadyClaimed - (_amountOfTokens * currentShare.alreadyClaimed / currentShare.tokensStaked);

        emit ShareUpdated(
            _user,
            _shareId,
            currentShare.shareAmount - newShare,
            newShare,
            newClaimed
        );

        currentShare.shareAmount = newShare;
        currentShare.alreadyClaimed = newClaimed;
        currentShare.tokensStakedPower -= _scaleValue(currentShare.tokensStakedPower, _amountOfTokens, currentShare.tokensStaked);
        currentShare.tokensStaked -= _amountOfTokens;
    }

    function _scaleValue(uint256 mx, uint256 y, uint256 my) private pure returns (uint256 x) {
        x = y * mx / my;
    }

    event RewardPoolTokensTransfered (address indexed sender, uint256 amountAdded, uint256 value, uint256 rewardPerSecond);
    event RewardPoolTimeSet          (address indexed sender, uint256 amountAdded, uint256 value, uint256 rewardPerSecond);
    event RewardPoolTimeExtended     (address indexed sender, uint256 amountAdded, uint256 value, uint256 rewardPerSecond);
    event EmergencyWithdrawn(address indexed sender, uint256 stakingToken, uint256 rewardToken);
    event UnlockedTokensChangedRewardPerSecond(uint256 rewardPerSecond);

    event ClaimedTokensFromShare(address indexed sender, uint256 indexed shareId, uint256 claimed, uint256 sumOfClaimed);

    event ShareUpdated(address indexed shareHolder, uint256 indexed shareId, uint256 shareChange, uint256 shareAbsolute, uint256 sumOfClaimed);
    event ShareCreated(address indexed shareHolder, uint256 amount, uint256 share);
    event ShareMoved(address indexed shareHolder, uint256 indexed newShareId, uint256 indexed oldShareId);
    event ShareDeleted(address indexed shareHolder, uint256 indexed shareId);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}