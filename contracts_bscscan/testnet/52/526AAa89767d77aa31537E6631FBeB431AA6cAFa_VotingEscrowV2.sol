// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./OwnableUpgradeable.sol";

import "./CoreUtility.sol";
import "./ManagedPausable.sol";
import "./IVotingEscrow.sol";
import "./ProxyUtility.sol";

interface IAddressWhitelist {
    function check(address account) external view returns (bool);
}

interface IVotingEscrowCallback {
    function syncWithVotingEscrow(address account) external;
}

contract VotingEscrowV2 is
    IVotingEscrow,
    OwnableUpgradeable,
    ReentrancyGuard,
    CoreUtility,
    ManagedPausable,
    ProxyUtility
{
    /// @dev Reserved storage slots for future base contract upgrades
    uint256[29] private _reservedSlots;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LockCreated(address indexed account, uint256 amount, uint256 unlockTime);

    event AmountIncreased(address indexed account, uint256 increasedAmount);

    event UnlockTimeIncreased(address indexed account, uint256 newUnlockTime);

    event Withdrawn(address indexed account, uint256 amount);

    uint8 public constant decimals = 18;

    uint256 public immutable override maxTime;

    address public immutable override token;

    string public name;
    string public symbol;

    address public addressWhitelist;

    mapping(address => LockedBalance) public locked;

    /// @notice Mapping of unlockTime => total amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;

    /// @notice max lock time allowed at the moment
    uint256 public maxTimeAllowed;

    /// @notice Contract to be call when an account's locked CHESS is updated
    address public callback;

    /// @notice Amount of Chess locked now. Expired locks are not included.
    uint256 public totalLocked;

    /// @notice Total veCHESS at the end of the last checkpoint's week
    uint256 public nextWeekSupply;

    /// @notice Mapping of week => vote-locked chess total supplies
    ///
    ///         Key is the start timestamp of a week on each Thursday. Value is
    ///         vote-locked chess total supplies captured at the start of each week
    mapping(uint256 => uint256) public veSupplyPerWeek;

    /// @notice Start timestamp of the trading week in which the last checkpoint is made
    uint256 public checkpointWeek;

    constructor(address token_, uint256 maxTime_) public {
        token = token_;
        maxTime = maxTime_;
    }

    /// @dev Initialize the contract. The contract is designed to be used with OpenZeppelin's
    ///      `TransparentUpgradeableProxy`. This function should be called by the proxy's
    ///      constructor (via the `_data` argument).
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxTimeAllowed_
    ) external initializer {
        __Ownable_init();
        require(maxTimeAllowed_ <= maxTime, "Cannot exceed max time");
        maxTimeAllowed = maxTimeAllowed_;
        _initializeV2(msg.sender, name_, symbol_);
    }

    /// @dev Initialize the part added in V2. If this contract is upgraded from the previous
    ///      version, call `upgradeToAndCall` of the proxy and put a call to this function
    ///      in the `data` argument.
    ///
    ///      In the previous version, name and symbol were not correctly initialized via proxy.
    function initializeV2(
        address pauser_,
        string memory name_,
        string memory symbol_
    ) external onlyProxyAdmin {
        _initializeV2(pauser_, name_, symbol_);
    }

    function _initializeV2(
        address pauser_,
        string memory name_,
        string memory symbol_
    ) private {
        _initializeManagedPausable(pauser_);
        require(bytes(name).length == 0 && bytes(symbol).length == 0);
        name = name_;
        symbol = symbol_;

        // Initialize totalLocked, nextWeekSupply and checkpointWeek
        uint256 nextWeek = _endOfWeek(block.timestamp);
        uint256 totalLocked_ = 0;
        uint256 nextWeekSupply_ = 0;
        for (
            uint256 weekCursor = nextWeek;
            weekCursor <= nextWeek + maxTime;
            weekCursor += 1 weeks
        ) {
            totalLocked_ = totalLocked_.add(scheduledUnlock[weekCursor]);
            nextWeekSupply_ = nextWeekSupply_.add(
                (scheduledUnlock[weekCursor].mul(weekCursor - nextWeek)) / maxTime
            );
        }
        totalLocked = totalLocked_;
        nextWeekSupply = nextWeekSupply_;
        checkpointWeek = nextWeek - 1 weeks;
    }

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        override
        returns (uint256)
    {
        LockedBalance memory lockedBalance = locked[account];
        if (lockedBalance.amount == 0 || lockedBalance.amount < threshold) {
            return 0;
        }
        return lockedBalance.unlockTime.sub(threshold.mul(maxTime).div(lockedBalance.amount));
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOfAtTimestamp(account, block.timestamp);
    }

    function totalSupply() external view override returns (uint256) {
        uint256 weekCursor = checkpointWeek;
        uint256 nextWeek = _endOfWeek(block.timestamp);
        uint256 currentWeek = nextWeek - 1 weeks;
        uint256 newNextWeekSupply = nextWeekSupply;
        uint256 newTotalLocked = totalLocked;
        if (weekCursor < currentWeek) {
            weekCursor += 1 weeks;
            for (; weekCursor < currentWeek; weekCursor += 1 weeks) {
                // Remove Chess unlocked at the beginning of the next week from total locked amount.
                newTotalLocked = newTotalLocked.sub(scheduledUnlock[weekCursor]);
                // Calculate supply at the end of the next week.
                newNextWeekSupply = newNextWeekSupply.sub(newTotalLocked.mul(1 weeks) / maxTime);
            }
            newTotalLocked = newTotalLocked.sub(scheduledUnlock[weekCursor]);
            newNextWeekSupply = newNextWeekSupply.sub(
                newTotalLocked.mul(block.timestamp - currentWeek) / maxTime
            );
        } else {
            newNextWeekSupply = newNextWeekSupply.add(
                newTotalLocked.mul(nextWeek - block.timestamp) / maxTime
            );
        }

        return newNextWeekSupply;
    }

    function getLockedBalance(address account)
        external
        view
        override
        returns (LockedBalance memory)
    {
        return locked[account];
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        override
        returns (uint256)
    {
        return _balanceOfAtTimestamp(account, timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256) {
        return _totalSupplyAtTimestamp(timestamp);
    }

    function createLock(uint256 amount, uint256 unlockTime) external nonReentrant whenNotPaused {
        _assertNotContract();
        require(
            unlockTime + 1 weeks == _endOfWeek(unlockTime),
            "Unlock time must be end of a week"
        );

        LockedBalance memory lockedBalance = locked[msg.sender];

        require(amount > 0, "Zero value");
        require(lockedBalance.amount == 0, "Withdraw old tokens first");
        require(unlockTime > block.timestamp, "Can only lock until time in the future");
        require(
            unlockTime <= block.timestamp + maxTimeAllowed,
            "Voting lock cannot exceed max lock time"
        );

        _checkpoint(lockedBalance.amount, lockedBalance.unlockTime, amount, unlockTime);
        scheduledUnlock[unlockTime] = scheduledUnlock[unlockTime].add(amount);
        locked[msg.sender].unlockTime = unlockTime;
        locked[msg.sender].amount = amount;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if (callback != address(0)) {
            IVotingEscrowCallback(callback).syncWithVotingEscrow(msg.sender);
        }

        emit LockCreated(msg.sender, amount, unlockTime);
    }

    function increaseAmount(address account, uint256 amount) external nonReentrant whenNotPaused {
        LockedBalance memory lockedBalance = locked[account];

        require(amount > 0, "Zero value");
        require(lockedBalance.unlockTime > block.timestamp, "Cannot add to expired lock");

        uint256 newAmount = lockedBalance.amount.add(amount);
        _checkpoint(
            lockedBalance.amount,
            lockedBalance.unlockTime,
            newAmount,
            lockedBalance.unlockTime
        );
        scheduledUnlock[lockedBalance.unlockTime] = scheduledUnlock[lockedBalance.unlockTime].add(
            amount
        );
        locked[account].amount = newAmount;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if (callback != address(0)) {
            IVotingEscrowCallback(callback).syncWithVotingEscrow(msg.sender);
        }

        emit AmountIncreased(account, amount);
    }

    function increaseUnlockTime(uint256 unlockTime) external nonReentrant whenNotPaused {
        require(
            unlockTime + 1 weeks == _endOfWeek(unlockTime),
            "Unlock time must be end of a week"
        );
        LockedBalance memory lockedBalance = locked[msg.sender];

        require(lockedBalance.unlockTime > block.timestamp, "Lock expired");
        require(unlockTime > lockedBalance.unlockTime, "Can only increase lock duration");
        require(
            unlockTime <= block.timestamp + maxTimeAllowed,
            "Voting lock cannot exceed max lock time"
        );

        _checkpoint(
            lockedBalance.amount,
            lockedBalance.unlockTime,
            lockedBalance.amount,
            unlockTime
        );
        scheduledUnlock[lockedBalance.unlockTime] = scheduledUnlock[lockedBalance.unlockTime].sub(
            lockedBalance.amount
        );
        scheduledUnlock[unlockTime] = scheduledUnlock[unlockTime].add(lockedBalance.amount);
        locked[msg.sender].unlockTime = unlockTime;

        if (callback != address(0)) {
            IVotingEscrowCallback(callback).syncWithVotingEscrow(msg.sender);
        }

        emit UnlockTimeIncreased(msg.sender, unlockTime);
    }

    function withdraw() external nonReentrant {
        LockedBalance memory lockedBalance = locked[msg.sender];
        require(block.timestamp >= lockedBalance.unlockTime, "The lock is not expired");
        uint256 amount = uint256(lockedBalance.amount);

        lockedBalance.unlockTime = 0;
        lockedBalance.amount = 0;
        locked[msg.sender] = lockedBalance;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function updateAddressWhitelist(address newWhitelist) external onlyOwner {
        require(
            newWhitelist == address(0) || Address.isContract(newWhitelist),
            "Must be null or a contract"
        );
        addressWhitelist = newWhitelist;
    }

    function updateCallback(address newCallback) external onlyOwner {
        require(
            newCallback == address(0) || Address.isContract(newCallback),
            "Must be null or a contract"
        );
        callback = newCallback;
    }

    function _assertNotContract() private view {
        if (msg.sender != tx.origin) {
            if (
                addressWhitelist != address(0) &&
                IAddressWhitelist(addressWhitelist).check(msg.sender)
            ) {
                return;
            }
            revert("Smart contract depositors not allowed");
        }
    }

    function _balanceOfAtTimestamp(address account, uint256 timestamp)
        private
        view
        returns (uint256)
    {
        require(timestamp >= block.timestamp, "Must be current or future time");
        LockedBalance memory lockedBalance = locked[account];
        if (timestamp > lockedBalance.unlockTime) {
            return 0;
        }
        return (lockedBalance.amount.mul(lockedBalance.unlockTime - timestamp)) / maxTime;
    }

    function _totalSupplyAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 weekCursor = _endOfWeek(timestamp);
        uint256 total = 0;
        for (; weekCursor <= timestamp + maxTime; weekCursor += 1 weeks) {
            total = total.add((scheduledUnlock[weekCursor].mul(weekCursor - timestamp)) / maxTime);
        }
        return total;
    }

    /// @dev Pre-conditions:
    ///
    ///      - `newAmount > 0`
    ///      - `newUnlockTime > block.timestamp`
    ///      - `newUnlockTime + 1 weeks == _endOfWeek(newUnlockTime)`, i.e. aligned to a trading week
    ///
    ///      The latter two conditions gaurantee that `newUnlockTime` is no smaller than the local
    ///      variable `nextWeek` in the function.
    function _checkpoint(
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 newAmount,
        uint256 newUnlockTime
    ) private {
        // Update veCHESS supply at the beginning of each week since the last checkpoint.
        uint256 weekCursor = checkpointWeek;
        uint256 nextWeek = _endOfWeek(block.timestamp);
        uint256 currentWeek = nextWeek - 1 weeks;
        uint256 newTotalLocked = totalLocked;
        uint256 newNextWeekSupply = nextWeekSupply;
        if (weekCursor < currentWeek) {
            for (uint256 w = weekCursor + 1 weeks; w <= currentWeek; w += 1 weeks) {
                veSupplyPerWeek[w] = newNextWeekSupply;
                // Remove Chess unlocked at the beginning of this week from total locked amount.
                newTotalLocked = newTotalLocked.sub(scheduledUnlock[w]);
                // Calculate supply at the end of the next week.
                newNextWeekSupply = newNextWeekSupply.sub(newTotalLocked.mul(1 weeks) / maxTime);
            }
            checkpointWeek = currentWeek;
        }

        // Remove the old schedule if there is one
        if (oldAmount > 0 && oldUnlockTime >= nextWeek) {
            newTotalLocked = newTotalLocked.sub(oldAmount);
            newNextWeekSupply = newNextWeekSupply.sub(
                oldAmount.mul(oldUnlockTime - nextWeek) / maxTime
            );
        }

        totalLocked = newTotalLocked.add(newAmount);
        // Round up on division when added to the total supply, so that the total supply is never
        // smaller than the sum of all accounts' veCHESS balance.
        nextWeekSupply = newNextWeekSupply.add(
            newAmount.mul(newUnlockTime - nextWeek).add(maxTime - 1) / maxTime
        );
    }

    function updateMaxTimeAllowed(uint256 newMaxTimeAllowed) external onlyOwner {
        require(newMaxTimeAllowed <= maxTime, "Cannot exceed max time");
        require(newMaxTimeAllowed > maxTimeAllowed, "Cannot shorten max time allowed");
        maxTimeAllowed = newMaxTimeAllowed;
    }

    /// @notice Recalculate `nextWeekSupply` from scratch. This function eliminates accumulated
    ///         rounding errors in `nextWeekSupply`, which is incrementally updated in
    ///         `createLock`, `increaseAmount` and `increaseUnlockTime`. It is almost
    ///         never required.
    /// @dev Search "rounding error" in test cases for details about the rounding errors.
    function calibrateSupply() external {
        uint256 nextWeek = checkpointWeek + 1 weeks;
        nextWeekSupply = _totalSupplyAtTimestamp(nextWeek);
    }
}