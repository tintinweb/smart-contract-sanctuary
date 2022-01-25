//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./MigrationPoolsV8.sol";
import "./LockDepositsBatches.sol";

/// @author  umb.network
contract LockDepositsMigratable is MigrationPoolsV8, LockDepositsBatches {
    event StakedTokenMigrated();
    event RewardTokenMigrated();

    constructor(address _rewardToken) LockDepositsBatches (_rewardToken) {}

    function migrateReward(address[] calldata _tokens, MigrationPoolsV8 _newPool, bytes calldata _data) external {
        unchecked {
            uint256 amount;

            for (uint256 i; i < _tokens.length; i++) {
                uint256 count = depositNextIndex[msg.sender][_tokens[i]];

                for (uint256 x; x < count; x++) {
                    amount += _claimFor(msg.sender, _tokens[i], x, address(this));
                }
            }

            if (amount == 0) return;

            emit RewardTokenMigrated();
            if (!rewardToken.transfer(address(_newPool), amount)) revert TokenTransferFailed();

            _newPool.migrateTokenCallback(address(rewardToken), msg.sender, amount, _data);
        }
    }

    function migrateLockedTokens(
        address[] calldata _tokens,
        MigrationPoolsV8[] calldata _newPools,
        bytes[] calldata _data
    ) external {
        for (uint256 i; i < _tokens.length; i++) {
            uint256 count = depositNextIndex[msg.sender][_tokens[i]];
            uint256 amount;

            for (uint256 x; x < count; x++) {
                amount += _withdrawFor(msg.sender, _tokens[i], x, address(0));
            }

            if (amount == 0) continue;

            emit StakedTokenMigrated();
            if (!Token(_tokens[i]).transfer(address(_newPools[i]), amount)) revert TokenTransferFailed();

            _newPools[i].migrateTokenCallback(_tokens[i], msg.sender, amount, _data[i]);
        }
    }

    function migrateTokenCallback(address _token, address _user, uint256 _amount, bytes calldata _data)
        external
        override
        onlyPool
    {
        uint32 period = abi.decode(_data, (uint32));
        _lock(_user, _token, period, _amount, true);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/V4/access/Ownable.sol";

/// @author  umb.network
/// @dev this is pure copy of MigrationPools but for solidity 0.8.0
abstract contract MigrationPoolsV8 is Ownable {
    /// @dev pools that we can migrate from
    mapping(address => bool) public migrationPools;

    event PoolSetup(address pool, bool active);

    modifier onlyPool() {
        require(migrationPools[msg.sender], "not a staking pool");
        _;
    }

    function activatePools(address[] calldata _pools) external {
        _setupPools(_pools, true);
    }

    function deactivatePools(address[] calldata _pools) external {
        _setupPools(_pools, false);
    }

    /// @dev should use onlyPool modifier
    function migrateTokenCallback(address _token, address _user, uint256 _amount, bytes calldata _data)
        external
        virtual;

    function _setupPools(address[] calldata _pools, bool _active) internal onlyOwner {
        for (uint256 i; i < _pools.length; i++) {
            migrationPools[_pools[i]] = _active;
            emit PoolSetup(_pools[i], _active);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./LockDepositsCore.sol";

/// @author  umb.network
contract LockDepositsBatches is LockDepositsCore {
    constructor(address _rewardToken) LockDepositsCore (_rewardToken) {}

    function lockMany(address[] calldata _tokens, uint32[] calldata _periods, uint256[] calldata _amounts) external {
        if (_tokens.length != _periods.length) revert ArraysNotMatch();
        if (_tokens.length != _amounts.length) revert ArraysNotMatch();

        for (uint256 i; i < _tokens.length; i++) {
            _lock(msg.sender, _tokens[i], _periods[i], _amounts[i], false);
        }
    }

    function exit(address[] calldata _tokens, uint256[] calldata _indexes) external {
        for (uint256 i; i < _tokens.length; i++) {
            _claimFor(msg.sender, _tokens[i], _indexes[i], msg.sender);
            _withdrawFor(msg.sender, _tokens[i], _indexes[i], msg.sender);
        }
    }

    function exitAll(address[] calldata _tokens) external {
        for (uint256 i; i < _tokens.length; i++) {
            uint256 count = depositNextIndex[msg.sender][_tokens[i]];

            for (uint256 x; x < count; x++) {
                _claimFor(msg.sender, _tokens[i], x, msg.sender);
                _withdrawFor(msg.sender, _tokens[i], x, msg.sender);
            }
        }
    }

    function claimMany(address[] calldata _tokens, uint256[] calldata _indexes) external {
        for (uint256 i; i < _tokens.length; i++) {
            _claimFor(msg.sender, _tokens[i], _indexes[i], msg.sender);
        }
    }

    function claimAll(address[] calldata _tokens) external {
        for (uint256 i; i < _tokens.length; i++) {
            uint256 count = depositNextIndex[msg.sender][_tokens[i]];

            for (uint256 x; x < count; x++) {
                _claimFor(msg.sender, _tokens[i], x, msg.sender);
            }
        }
    }

    function withdrawMany(address[] calldata _tokens, uint256[] calldata _indexes) external {
        for (uint256 i; i < _tokens.length; i++) {
            _withdrawFor(msg.sender, _tokens[i], _indexes[i], msg.sender);
        }
    }

    function withdrawAll(address[] calldata _tokens) external {
        for (uint256 i; i < _tokens.length; i++) {
            uint256 count = depositNextIndex[msg.sender][_tokens[i]];

            for (uint256 x; x < count; x++) {
                _withdrawFor(msg.sender, _tokens[i], x, msg.sender);
            }
        }
    }

    function allDeposits(address _user, address[] calldata _tokens)
        external
        view
        returns (Deposit[][] memory userDeposits)
    {
        userDeposits = new Deposit[][](_tokens.length);

        unchecked {
            for (uint256 i; i < _tokens.length; i++) {
                uint256 count = depositNextIndex[_user][_tokens[i]];
                userDeposits[i] = new Deposit[](count);

                for (uint256 x; x < count; x++) {
                    userDeposits[i][x] = deposits[_user][_tokens[i]][x];
                }
            }
        }
    }

    function totalClaimable(address _user, address[] calldata _tokens)
        external
        view
        returns (uint256 totalReward, uint256 pendingReward)
    {
        unchecked {
            for (uint256 i; i < _tokens.length; i++) {
                uint256 count = depositNextIndex[_user][_tokens[i]];

                for (uint256 x; x < count; x++) {
                    (uint256 reward, uint256 pending) = _claimable(deposits[_user][_tokens[i]][x]);
                    totalReward += reward;
                    pendingReward += pending;
                }
            }
        }
    }

    function totalPaid(address _user, address[] calldata _tokens) external view returns (uint256 paidSoFar) {
        unchecked {
            for (uint256 i; i < _tokens.length; i++) {
                uint256 count = depositNextIndex[_user][_tokens[i]];

                for (uint256 x; x < count; x++) {
                    paidSoFar += deposits[_user][_tokens[i]][x].rewardPaid;
                }
            }
        }
    }

    /// @return totalLocked total amount of `_token` locked by user
    /// @return reward total reward of `rewardToken` earned so far
    function balanceOf(address _token, address _address) public view returns (uint256 totalLocked, uint256 reward) {
        unchecked {
            uint256 lastIndex = depositNextIndex[_address][_token];
            uint256 timestamp = block.timestamp;

            for (uint256 i; i < lastIndex; i++) {
                Deposit memory deposit = deposits[_address][_token][i];
                if (deposit.withdrawnAt == 0) totalLocked += deposit.amount;

                reward += _calculateReward(deposit, timestamp) - deposit.rewardPaid;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/V4/access/Ownable.sol";
import "./Error.sol";

interface Token {
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

/// @author  umb.network
contract LockDepositsCore is Ownable {
    struct Deposit {
        // total supply of UMB can be saved using 89bits, so we good with 128
        // TODO check if for MC it will be the same
        uint128 amount;
        uint128 rewardPaid;
        uint32 startDate;
        uint32 finishDate;
        uint32 apy;
        uint32 withdrawnAt;
    }

    struct Setting {
        // duration in seconds => multiplier
        mapping(uint32 => uint32) multipliers;
        uint32 baseRate;
    }

    uint32 public constant SECONDS_PER_YEAR = 365 days;

    /// @dev decimals for: baseRate, APY, multipliers
    ///         eg for baseRate: 1e6 is 1%, 50e6 is 50%
    ///         eg for multipliers: 1e6 is 1.0x, 3210000 is 3.21x
    uint32 public constant RATE_DECIMALS = 10 ** 6;

    Token public immutable rewardToken;

    /// @dev staking token => dedicated settings
    mapping(address => Setting) public settings;

    /// @dev user => staking token => deposit index => Deposit
    mapping(address => mapping(address => mapping(uint256 => Deposit))) public deposits;

    /// @dev user => staking token => deposit next index
    mapping(address => mapping(address => uint256)) public depositNextIndex;

    event LogTokenSettings(address indexed token, uint32 baseRate, uint32 period, uint32 multiplier);
    event LogTokenRemoved(address indexed token);
    event LogDeposit(address indexed user, address indexed token, uint256 depositIndex, uint256 amount);
    event LogRewardClaimed(address indexed user, address indexed token, uint256 depositIndex, uint256 amount);
    event LogWithdraw(address indexed user, address indexed token, uint256 depositIndex, uint256 amount);

    constructor(address _rewardToken) {
        if (Token(_rewardToken).decimals() != 18) revert TokenNotSupported();

        rewardToken = Token(_rewardToken);
    }

    function turnOffTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            settings[_tokens[i]].baseRate = 0;
            emit LogTokenRemoved(_tokens[i]);
        }
    }

    function setStakingTokenSettings(
        address _token,
        uint32 _baseRate,
        uint32[] calldata _periods,
        uint32[] calldata _multipliers
    )
        external
        onlyOwner
    {
        if (_baseRate == 0) revert EmptyBaseRate();
        if (_periods.length == 0) revert EmptyPeriods();
        if (_periods.length != _multipliers.length) revert ArraysNotMatch();
        if (Token(_token).decimals() != 18) revert TokenNotSupported();

        Setting storage setting = settings[_token];
        setting.baseRate = _baseRate;

        for (uint256 i; i < _periods.length; i++) {
            if (_periods[i] == 0 || _multipliers[i] == 0) revert InvalidSettings();

            setting.multipliers[_periods[i]] = _multipliers[i];
            emit LogTokenSettings(_token, _baseRate, _periods[i], _multipliers[i]);
        }
    }

    function lock(address _token, uint32 _period, uint256 _amount) external virtual {
        _lock(msg.sender, _token, _period, _amount, false);
    }

    /// @return totalReward total amount of reward token that user earned so far during lock period
    /// @return pendingReward pending amount of reward token available for claim
    function claimable(address _user, address _token, uint256 _index)
        external
        view
        returns (uint256 totalReward, uint256 pendingReward)
    {
        return _claimable(deposits[_user][_token][_index]);
    }

    /// @return reward amount that has been claimed by user so far
    function paid(address _user, address _token, uint256 _index) external view returns (uint256) {
        return deposits[_user][_token][_index].rewardPaid;
    }

    function claim(address _token, uint256 _index) public {
        _claimFor(msg.sender, _token, _index, msg.sender);
    }

    function withdraw(address _token, uint256 _index) public {
        _withdrawFor(msg.sender, _token, _index, msg.sender);
    }

    function _withdrawFor(address _user, address _token, uint256 _index, address _recipient)
        internal
        returns (uint256 amount)
    {
        unchecked {
            Deposit storage deposit = deposits[_user][_token][_index];
            uint32 withdrawnAt = deposit.withdrawnAt;
            if (withdrawnAt != 0) revert DepositAlreadyWithdrawn();

            if (block.timestamp < deposit.finishDate) revert DepositLocked();

            amount = deposit.amount;
            if (amount == 0) return 0;

            deposit.withdrawnAt = uint32(block.timestamp);
            emit LogWithdraw(_user, _token, _index, amount);

            if (_recipient != address(0)) Token(_token).transfer(_recipient, amount);
        }
    }

    function _lock(address _user, address _token, uint32 _period, uint256 _amount, bool _migration) internal {
        unchecked {
            uint256 nextIndex = depositNextIndex[_user][_token];
            Deposit storage deposit = deposits[_user][_token][nextIndex];
            uint256 baseRate = uint256(settings[_token].baseRate);

            if (baseRate == 0) revert InvalidDepositToken();

            // we do not support unknown tokens, so no need for safe transfer
            if (_migration) {
                // on migration tokens are transferred to us
            } else if (!Token(_token).transferFrom(_user, address(this), _amount)) revert TokenTransferFailed();

            uint256 multiplier = uint256(settings[_token].multipliers[_period]);
            if (multiplier == 0) revert InvalidPeriod();

            uint32 now32 = uint32(block.timestamp);

            deposit.amount = uint128(_amount);
            deposit.startDate = now32;
            deposit.finishDate = now32 + _period;
            deposit.apy = uint32(baseRate * multiplier / RATE_DECIMALS);

            depositNextIndex[_user][_token] = nextIndex + 1;

            emit LogDeposit(_user, _token, nextIndex, _amount);
        }
    }

    function _claimRewardFor(address _user, address _token, uint256 _index) internal returns (uint256 amountToMint) {
        Deposit memory deposit = deposits[_user][_token][_index];

        (uint256 totalReward, uint256 pendingReward) = _claimable(deposit);
        if (pendingReward == 0) return 0;

        deposits[_user][_token][_index].rewardPaid = uint128(totalReward);

        emit LogRewardClaimed(_user, _token, _index, pendingReward);

        return pendingReward;
    }

    function _claimFor(address _user, address _token, uint256 _index, address _recipient)
        internal
        returns (uint256 rewardAmount)
    {
        rewardAmount = _claimRewardFor(_user, _token, _index);
        if (rewardAmount != 0) rewardToken.mint(_recipient, rewardAmount);
    }

    function _claimable(Deposit memory _deposit) internal view returns (uint256 totalReward, uint256 pendingReward) {
        unchecked {
            totalReward = _calculateReward(_deposit, block.timestamp);
            pendingReward = totalReward - _deposit.rewardPaid;
        }
    }

    function _calculateReward(Deposit memory _deposit, uint256 _timestamp) internal pure returns (uint256 reward) {
        unchecked {
            uint256 deltaTime =
                (_timestamp < _deposit.finishDate ? _timestamp : _deposit.finishDate) - _deposit.startDate;

            reward = _deposit.amount * _deposit.apy * deltaTime / SECONDS_PER_YEAR / RATE_DECIMALS;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

error EmptyOwner();

error TokenNotSupported();

error EmptyBaseRate();

error EmptyPeriods();

error ArraysNotMatch();

error InvalidSettings();

error TokenTransferFailed();

error InvalidDepositToken();

error InvalidPeriod();

error InvalidFinishTimestamp();

error DepositAlreadyWithdrawn();

error NothingToWithdraw();

error DepositLocked();

error LockingNotPossible();