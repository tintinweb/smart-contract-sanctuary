/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// Verified using https://dapp.tools

// hevm: flattened sources of lib/radicle-drips-hub/src/DaiDripsHub.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-only
pragma solidity >=0.8.0 <0.9.0 >=0.8.7 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/security/Pausable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

/* pragma solidity ^0.8.0; */

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

////// lib/radicle-drips-hub/src/DripsHub.sol
/* pragma solidity ^0.8.7; */

/* import {Ownable} from "openzeppelin-contracts/access/Ownable.sol"; */
/* import {Pausable} from "openzeppelin-contracts/security/Pausable.sol"; */

struct DripsReceiver {
    address receiver;
    uint128 amtPerSec;
}

struct SplitsReceiver {
    address receiver;
    uint32 weight;
}

/// @notice Drips hub contract. Automatically drips and splits funds between users.
///
/// The user can transfer some funds to their drips balance in the contract
/// and configure a list of receivers, to whom they want to drip these funds.
/// As soon as the drips balance is enough to cover at least 1 second of dripping
/// to the configured receivers, the funds start dripping automatically.
/// Every second funds are deducted from the drips balance and moved to their receivers' accounts.
/// The process stops automatically when the drips balance is not enough to cover another second.
///
/// The user can have any number of independent configurations and drips balances by using accounts.
/// An account is identified by the user address and an account identifier.
/// Accounts of different users are separate entities, even if they have the same identifiers.
/// An account can be used to drip or give, but not to receive funds.
///
/// Every user has a receiver balance, in which they have funds received from other users.
/// The dripped funds are added to the receiver balances in global cycles.
/// Every `cycleSecs` seconds the drips hub adds dripped funds to the receivers' balances,
/// so recently dripped funds may not be collectable immediately.
/// `cycleSecs` is a constant configured when the drips hub is deployed.
/// The receiver balance is independent from the drips balance,
/// to drip received funds they need to be first collected and then added to the drips balance.
///
/// The user can share collected funds with other users by using splits.
/// When collecting, the user gives each of their splits receivers a fraction of the received funds.
/// Funds received from splits are available for collection immediately regardless of the cycle.
/// They aren't exempt from being split, so they too can be split when collected.
/// Users can build chains and networks of splits between each other.
/// Anybody can request collection of funds for any user,
/// which can be used to enforce the flow of funds in the network of splits.
///
/// The concept of something happening periodically, e.g. every second or every `cycleSecs` are
/// only high-level abstractions for the user, Ethereum isn't really capable of scheduling work.
/// The actual implementation emulates that behavior by calculating the results of the scheduled
/// events based on how many seconds have passed and only when the user needs their outcomes.
///
/// The contract assumes that all amounts in the system can be stored in signed 128-bit integers.
/// It's guaranteed to be safe only when working with assets with supply lower than `2 ^ 127`.
abstract contract DripsHub is Ownable, Pausable {
    /// @notice On every timestamp `T`, which is a multiple of `cycleSecs`, the receivers
    /// gain access to drips collected during `T - cycleSecs` to `T - 1`.
    uint64 public immutable cycleSecs;
    /// @notice Timestamp at which all drips must be finished
    uint64 internal constant MAX_TIMESTAMP = type(uint64).max - 2;
    /// @notice Maximum number of drips receivers of a single user.
    /// Limits cost of changes in drips configuration.
    uint32 public constant MAX_DRIPS_RECEIVERS = 100;
    /// @notice Maximum number of splits receivers of a single user.
    /// Limits cost of collecting.
    uint32 public constant MAX_SPLITS_RECEIVERS = 200;
    /// @notice The total splits weight of a user
    uint32 public constant TOTAL_SPLITS_WEIGHT = 1_000_000;

    /// @notice Emitted when drips from a user to a receiver are updated.
    /// Funds are being dripped on every second between the event block's timestamp (inclusively)
    /// and`endTime` (exclusively) or until the timestamp of the next drips update (exclusively).
    /// @param user The dripping user
    /// @param receiver The receiver of the updated drips
    /// @param amtPerSec The new amount per second dripped from the user
    /// to the receiver or 0 if the drips are stopped
    /// @param endTime The timestamp when dripping will stop,
    /// always larger than the block timestamp or equal to it if the drips are stopped
    event Dripping(
        address indexed user,
        address indexed receiver,
        uint128 amtPerSec,
        uint64 endTime
    );

    /// @notice Emitted when drips from a user's account to a receiver are updated.
    /// Funds are being dripped on every second between the event block's timestamp (inclusively)
    /// and`endTime` (exclusively) or until the timestamp of the next drips update (exclusively).
    /// @param user The user
    /// @param account The dripping account
    /// @param receiver The receiver of the updated drips
    /// @param amtPerSec The new amount per second dripped from the user's account
    /// to the receiver or 0 if the drips are stopped
    /// @param endTime The timestamp when dripping will stop,
    /// always larger than the block timestamp or equal to it if the drips are stopped
    event Dripping(
        address indexed user,
        uint256 indexed account,
        address indexed receiver,
        uint128 amtPerSec,
        uint64 endTime
    );

    /// @notice Emitted when the drips configuration of a user is updated.
    /// @param user The user
    /// @param balance The new drips balance. These funds will be dripped to the receivers.
    /// @param receivers The new list of the drips receivers.
    event DripsUpdated(address indexed user, uint128 balance, DripsReceiver[] receivers);

    /// @notice Emitted when the drips configuration of a user's account is updated.
    /// @param user The user
    /// @param account The account
    /// @param balance The new drips balance. These funds will be dripped to the receivers.
    /// @param receivers The new list of the drips receivers.
    event DripsUpdated(
        address indexed user,
        uint256 indexed account,
        uint128 balance,
        DripsReceiver[] receivers
    );

    /// @notice Emitted when the user's splits are updated.
    /// @param user The user
    /// @param receivers The list of the user's splits receivers.
    event SplitsUpdated(address indexed user, SplitsReceiver[] receivers);

    /// @notice Emitted when a user collects funds
    /// @param user The user
    /// @param collected The collected amount
    /// @param split The amount split to the user's splits receivers
    event Collected(address indexed user, uint128 collected, uint128 split);

    /// @notice Emitted when funds are split from a user to a receiver.
    /// This is caused by the user collecting received funds.
    /// @param user The user
    /// @param receiver The splits receiver
    /// @param amt The amount split to the receiver
    event Split(address indexed user, address indexed receiver, uint128 amt);

    /// @notice Emitted when funds are given from the user to the receiver.
    /// @param user The address of the user
    /// @param receiver The receiver
    /// @param amt The given amount
    event Given(address indexed user, address indexed receiver, uint128 amt);

    /// @notice Emitted when funds are given from the user's account to the receiver.
    /// @param user The address of the user
    /// @param account The user's account
    /// @param receiver The receiver
    /// @param amt The given amount
    event Given(
        address indexed user,
        uint256 indexed account,
        address indexed receiver,
        uint128 amt
    );

    struct ReceiverState {
        // The amount collectable independently from cycles
        uint128 collectable;
        // The next cycle to be collected
        uint64 nextCollectedCycle;
        // --- SLOT BOUNDARY
        // The changes of collected amounts on specific cycle.
        // The keys are cycles, each cycle `C` becomes collectable on timestamp `C * cycleSecs`.
        // Values for cycles before `nextCollectedCycle` are guaranteed to be zeroed.
        // This means that the value of `amtDeltas[nextCollectedCycle].thisCycle` is always
        // relative to 0 or in other words it's an absolute value independent from other cycles.
        mapping(uint64 => AmtDelta) amtDeltas;
    }

    struct AmtDelta {
        // Amount delta applied on this cycle
        int128 thisCycle;
        // Amount delta applied on the next cycle
        int128 nextCycle;
    }

    struct UserOrAccount {
        bool isAccount;
        address user;
        uint256 account;
    }

    /// @notice Users' splits configuration hashes, see `hashSplits`.
    /// The key is the user address.
    mapping(address => bytes32) public splitsHash;
    /// @notice Users' drips configuration hashes, see `hashDrips`.
    /// The key is the user address.
    mapping(address => bytes32) internal userDripsHashes;
    /// @notice Users' accounts' configuration hashes, see `hashDrips`.
    /// The key are the user address and the account.
    mapping(address => mapping(uint256 => bytes32)) internal accountDripsHashes;
    /// @notice Users' receiver states.
    /// The key is the user address.
    mapping(address => ReceiverState) internal receiverStates;

    /// @param _cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time of funds being frozen
    /// between being taken from the users' drips balances and being collectable by their receivers.
    /// High value makes collecting cheaper by making it process less cycles for a given time range.
    /// @param owner The initial owner of the contract with managerial abilities.
    constructor(uint64 _cycleSecs, address owner) {
        cycleSecs = _cycleSecs;
        transferOwnership(owner);
    }

    /// @notice Pauses any functions changing the state of the contract.
    /// Callable only by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses any functions changing the state of the contract.
    /// Callable only by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Returns amount of received funds available for collection for a user.
    /// @param user The user
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function collectable(address user, SplitsReceiver[] memory currReceivers)
        public
        view
        returns (uint128 collected, uint128 split)
    {
        ReceiverState storage receiver = receiverStates[user];
        _assertCurrSplits(user, currReceivers);

        // Collectable independently from cycles
        collected = receiver.collectable;

        // Collectable from cycles
        uint64 collectedCycle = receiver.nextCollectedCycle;
        uint64 currFinishedCycle = _currTimestamp() / cycleSecs;
        if (collectedCycle != 0 && collectedCycle <= currFinishedCycle) {
            int128 cycleAmt = 0;
            for (; collectedCycle <= currFinishedCycle; collectedCycle++) {
                cycleAmt += receiver.amtDeltas[collectedCycle].thisCycle;
                collected += uint128(cycleAmt);
                cycleAmt += receiver.amtDeltas[collectedCycle].nextCycle;
            }
        }

        // split when collected
        if (collected > 0 && currReceivers.length > 0) {
            uint32 splitsWeight = 0;
            for (uint256 i = 0; i < currReceivers.length; i++) {
                splitsWeight += currReceivers[i].weight;
            }
            split = uint128((uint160(collected) * splitsWeight) / TOTAL_SPLITS_WEIGHT);
            collected -= split;
        }
    }

    /// @notice Collects all received funds available for the user
    /// and transfers them out of the drips hub contract to that user's wallet.
    /// @param user The user
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function collect(address user, SplitsReceiver[] memory currReceivers)
        public
        whenNotPaused
        returns (uint128 collected, uint128 split)
    {
        (collected, split) = _collectInternal(user, currReceivers);
        _transfer(user, int128(collected));
    }

    /// @notice Counts cycles which will need to be analyzed when collecting or flushing.
    /// This function can be used to detect that there are too many cycles
    /// to analyze in a single transaction and flushing is needed.
    /// @param user The user
    /// @return flushable The number of cycles which can be flushed
    function flushableCycles(address user) public view returns (uint64 flushable) {
        uint64 nextCollectedCycle = receiverStates[user].nextCollectedCycle;
        if (nextCollectedCycle == 0) return 0;
        uint64 currFinishedCycle = _currTimestamp() / cycleSecs;
        return currFinishedCycle + 1 - nextCollectedCycle;
    }

    /// @notice Flushes uncollected cycles of the user.
    /// Flushed cycles won't need to be analyzed when the user collects from them.
    /// Calling this function does not collect and does not affect the collectable amount.
    ///
    /// This function is needed when collecting funds received over a period so long, that the gas
    /// needed for analyzing all the uncollected cycles can't fit in a single transaction.
    /// Calling this function allows spreading the analysis cost over multiple transactions.
    /// A cycle is never flushed more than once, even if this function is called many times.
    /// @param user The user
    /// @param maxCycles The maximum number of flushed cycles.
    /// If too low, flushing will be cheap, but will cut little gas from the next collection.
    /// If too high, flushing may become too expensive to fit in a single transaction.
    /// @return flushable The number of cycles which can be flushed
    function flushCycles(address user, uint64 maxCycles)
        public
        whenNotPaused
        returns (uint64 flushable)
    {
        flushable = flushableCycles(user);
        uint64 cycles = maxCycles < flushable ? maxCycles : flushable;
        flushable -= cycles;
        uint128 collected = _flushCyclesInternal(user, cycles);
        if (collected > 0) receiverStates[user].collectable += collected;
    }

    /// @notice Collects all received funds available for the user,
    /// but doesn't transfer them to the user's wallet.
    /// @param user The user
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function _collectInternal(address user, SplitsReceiver[] memory currReceivers)
        internal
        returns (uint128 collected, uint128 split)
    {
        ReceiverState storage receiver = receiverStates[user];
        _assertCurrSplits(user, currReceivers);

        // Collectable independently from cycles
        collected = receiver.collectable;
        if (collected > 0) receiver.collectable = 0;

        // Collectable from cycles
        uint64 cycles = flushableCycles(user);
        collected += _flushCyclesInternal(user, cycles);

        // split when collected
        if (collected > 0 && currReceivers.length > 0) {
            uint32 splitsWeight = 0;
            for (uint256 i = 0; i < currReceivers.length; i++) {
                splitsWeight += currReceivers[i].weight;
                uint128 splitsAmt = uint128(
                    (uint160(collected) * splitsWeight) / TOTAL_SPLITS_WEIGHT - split
                );
                split += splitsAmt;
                address splitsReceiver = currReceivers[i].receiver;
                receiverStates[splitsReceiver].collectable += splitsAmt;
                emit Split(user, splitsReceiver, splitsAmt);
            }
            collected -= split;
        }
        emit Collected(user, collected, split);
    }

    /// @notice Collects and clears user's cycles
    /// @param user The user
    /// @param count The number of flushed cycles.
    /// @return collectedAmt The collected amount
    function _flushCyclesInternal(address user, uint64 count)
        internal
        returns (uint128 collectedAmt)
    {
        if (count == 0) return 0;
        ReceiverState storage receiver = receiverStates[user];
        uint64 cycle = receiver.nextCollectedCycle;
        int128 cycleAmt = 0;
        for (uint256 i = 0; i < count; i++) {
            cycleAmt += receiver.amtDeltas[cycle].thisCycle;
            collectedAmt += uint128(cycleAmt);
            cycleAmt += receiver.amtDeltas[cycle].nextCycle;
            delete receiver.amtDeltas[cycle];
            cycle++;
        }
        // The next cycle delta must be relative to the last collected cycle, which got zeroed.
        // In other words the next cycle delta must be an absolute value.
        if (cycleAmt != 0) receiver.amtDeltas[cycle].thisCycle += cycleAmt;
        receiver.nextCollectedCycle = cycle;
    }

    /// @notice Gives funds from the user or their account to the receiver.
    /// The receiver can collect them immediately.
    /// Transfers the funds to be given from the user's wallet to the drips hub contract.
    /// @param userOrAccount The user or their account
    /// @param receiver The receiver
    /// @param amt The given amount
    function _give(
        UserOrAccount memory userOrAccount,
        address receiver,
        uint128 amt
    ) internal {
        receiverStates[receiver].collectable += amt;
        if (userOrAccount.isAccount) {
            emit Given(userOrAccount.user, userOrAccount.account, receiver, amt);
        } else {
            emit Given(userOrAccount.user, receiver, amt);
        }
        _transfer(userOrAccount.user, -int128(amt));
    }

    /// @notice Current user's drips hash, see `hashDrips`.
    /// @param user The user
    /// @return currDripsHash The current user's drips hash
    function dripsHash(address user) public view returns (bytes32 currDripsHash) {
        return userDripsHashes[user];
    }

    /// @notice Current user account's drips hash, see `hashDrips`.
    /// @param user The user
    /// @param account The account
    /// @return currDripsHash The current user account's drips hash
    function dripsHash(address user, uint256 account) public view returns (bytes32 currDripsHash) {
        return accountDripsHashes[user][account];
    }

    /// @notice Sets the user's or the account's drips configuration.
    /// Transfers funds between the user's wallet and the drips hub contract
    /// to fulfill the change of the drips balance.
    /// @param userOrAccount The user or their account
    /// @param lastUpdate The timestamp of the last drips update of the user or the account.
    /// If this is the first update, pass zero.
    /// @param lastBalance The drips balance after the last drips update of the user or the account.
    /// If this is the first update, pass zero.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user or the account.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The drips balance change to be applied.
    /// Positive to add funds to the drips balance, negative to remove them.
    /// @param newReceivers The list of the drips receivers of the user or the account to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @return newBalance The new drips balance of the user or the account.
    /// Pass it as `lastBalance` when updating that user or the account for the next time.
    /// @return realBalanceDelta The actually applied drips balance change.
    function _setDrips(
        UserOrAccount memory userOrAccount,
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers
    ) internal returns (uint128 newBalance, int128 realBalanceDelta) {
        _assertCurrDrips(userOrAccount, lastUpdate, lastBalance, currReceivers);
        uint128 newAmtPerSec = _assertDripsReceiversValid(newReceivers);
        uint128 currAmtPerSec = _totalDripsAmtPerSec(currReceivers);
        uint64 currEndTime = _dripsEndTime(lastUpdate, lastBalance, currAmtPerSec);
        (newBalance, realBalanceDelta) = _updateDripsBalance(
            lastUpdate,
            lastBalance,
            currEndTime,
            currAmtPerSec,
            balanceDelta
        );
        uint64 newEndTime = _dripsEndTime(_currTimestamp(), newBalance, newAmtPerSec);
        _updateDripsReceiversStates(
            userOrAccount,
            currReceivers,
            currEndTime,
            newReceivers,
            newEndTime
        );
        _storeCurrDrips(userOrAccount, newBalance, newReceivers);
        _emitDripsUpdated(userOrAccount, newBalance, newReceivers);
        _transfer(userOrAccount.user, -realBalanceDelta);
    }

    /// @notice Validates a list of drips receivers.
    /// @param receivers The list of drips receivers.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @return totalAmtPerSec The total amount per second of all drips receivers.
    function _assertDripsReceiversValid(DripsReceiver[] memory receivers)
        internal
        pure
        returns (uint128 totalAmtPerSec)
    {
        require(receivers.length <= MAX_DRIPS_RECEIVERS, "Too many drips receivers");
        uint256 amtPerSec = 0;
        address prevReceiver;
        for (uint256 i = 0; i < receivers.length; i++) {
            uint128 amt = receivers[i].amtPerSec;
            require(amt != 0, "Drips receiver amtPerSec is zero");
            amtPerSec += amt;
            address receiver = receivers[i].receiver;
            if (i > 0) {
                require(prevReceiver != receiver, "Duplicate drips receivers");
                require(prevReceiver < receiver, "Drips receivers not sorted by address");
            }
            prevReceiver = receiver;
        }
        require(amtPerSec <= type(uint128).max, "Total drips receivers amtPerSec too high");
        return uint128(amtPerSec);
    }

    /// @notice Calculates the total amount per second of all the drips receivers.
    /// @param receivers The list of the receivers.
    /// It must have passed `_assertDripsReceiversValid` in the past.
    /// @return totalAmtPerSec The total amount per second of all the drips receivers
    function _totalDripsAmtPerSec(DripsReceiver[] memory receivers)
        internal
        pure
        returns (uint128 totalAmtPerSec)
    {
        uint256 length = receivers.length;
        uint256 i = 0;
        while (i < length) {
            // Safe, because `receivers` passed `_assertDripsReceiversValid` in the past
            unchecked {
                totalAmtPerSec += receivers[i++].amtPerSec;
            }
        }
    }

    /// @notice Updates drips balance.
    /// @param lastUpdate The timestamp of the last drips update.
    /// If this is the first update, pass zero.
    /// @param lastBalance The drips balance after the last drips update.
    /// If this is the first update, pass zero.
    /// @param currEndTime Time when drips were supposed to end according to the last drips update.
    /// @param currAmtPerSec The total amount per second of all drips receivers
    /// according to the last drips update.
    /// @param balanceDelta The drips balance change to be applied.
    /// Positive to add funds to the drips balance, negative to remove them.
    /// @return newBalance The new drips balance.
    /// Pass it as `lastBalance` when updating for the next time.
    /// @return realBalanceDelta The actually applied drips balance change.
    /// If positive, this is the amount which should be transferred from the user to the drips hub,
    /// or if negative, from the drips hub to the user.
    function _updateDripsBalance(
        uint64 lastUpdate,
        uint128 lastBalance,
        uint64 currEndTime,
        uint128 currAmtPerSec,
        int128 balanceDelta
    ) internal view returns (uint128 newBalance, int128 realBalanceDelta) {
        if (currEndTime > _currTimestamp()) currEndTime = _currTimestamp();
        uint128 dripped = (currEndTime - lastUpdate) * currAmtPerSec;
        int128 currBalance = int128(lastBalance - dripped);
        int136 balance = currBalance + int136(balanceDelta);
        if (balance < 0) balance = 0;
        return (uint128(uint136(balance)), int128(balance - currBalance));
    }

    /// @notice Emit an event when drips are updated.
    /// @param userOrAccount The user or their account
    /// @param balance The new drips balance.
    /// @param receivers The new list of the drips receivers.
    function _emitDripsUpdated(
        UserOrAccount memory userOrAccount,
        uint128 balance,
        DripsReceiver[] memory receivers
    ) internal {
        if (userOrAccount.isAccount) {
            emit DripsUpdated(userOrAccount.user, userOrAccount.account, balance, receivers);
        } else {
            emit DripsUpdated(userOrAccount.user, balance, receivers);
        }
    }

    /// @notice Updates the user's or the account's drips receivers' states.
    /// It applies the effects of the change of the drips configuration.
    /// @param userOrAccount The user or their account
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user or the account.
    /// If this is the first update, pass an empty array.
    /// @param currEndTime Time when drips were supposed to end according to the last drips update.
    /// @param newReceivers  The list of the drips receivers of the user or the account to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @param newEndTime Time when drips will end according to the new drips configuration.
    function _updateDripsReceiversStates(
        UserOrAccount memory userOrAccount,
        DripsReceiver[] memory currReceivers,
        uint64 currEndTime,
        DripsReceiver[] memory newReceivers,
        uint64 newEndTime
    ) internal {
        // Skip iterating over `currReceivers` if dripping has run out
        uint256 currIdx = currEndTime > _currTimestamp() ? 0 : currReceivers.length;
        // Skip iterating over `newReceivers` if no new dripping is started
        uint256 newIdx = newEndTime > _currTimestamp() ? 0 : newReceivers.length;
        while (true) {
            // Each iteration gets the next drips update and applies it on the receiver state.
            // A drips update is composed of two drips receiver configurations,
            // one current and one new, or from a single drips receiver configuration
            // if the drips receiver is being added or removed.
            bool pickCurr = currIdx < currReceivers.length;
            bool pickNew = newIdx < newReceivers.length;
            if (!pickCurr && !pickNew) break;
            if (pickCurr && pickNew) {
                // There are two candidate drips receiver configurations to create a drips update.
                // Pick both if they describe the same receiver or the one with a lower address.
                // The one with a higher address won't be used in this iteration.
                // Because drips receivers lists are sorted by addresses and deduplicated,
                // all matching pairs of drips receiver configurations will be found.
                address currReceiver = currReceivers[currIdx].receiver;
                address newReceiver = newReceivers[newIdx].receiver;
                pickCurr = currReceiver <= newReceiver;
                pickNew = newReceiver <= currReceiver;
            }
            // The drips update parameters
            address receiver;
            int128 currAmtPerSec = 0;
            int128 newAmtPerSec = 0;
            if (pickCurr) {
                receiver = currReceivers[currIdx].receiver;
                currAmtPerSec = int128(currReceivers[currIdx].amtPerSec);
                // Clear the obsolete drips end
                _setDelta(receiver, currEndTime, currAmtPerSec);
                currIdx++;
            }
            if (pickNew) {
                receiver = newReceivers[newIdx].receiver;
                newAmtPerSec = int128(newReceivers[newIdx].amtPerSec);
                // Apply the new drips end
                _setDelta(receiver, newEndTime, -newAmtPerSec);
                newIdx++;
            }
            // Apply the drips update since now
            _setDelta(receiver, _currTimestamp(), newAmtPerSec - currAmtPerSec);
            _emitDripping(userOrAccount, receiver, uint128(newAmtPerSec), newEndTime);
            // The receiver has never been used, initialize it
            if (!pickCurr && receiverStates[receiver].nextCollectedCycle == 0) {
                receiverStates[receiver].nextCollectedCycle = _currTimestamp() / cycleSecs + 1;
            }
        }
    }

    /// @notice Emit an event when drips from a user to a receiver are updated.
    /// @param userOrAccount The user or their account
    /// @param receiver The receiver
    /// @param amtPerSec The new amount per second dripped from the user or the account
    /// to the receiver or 0 if the drips are stopped
    /// @param endTime The timestamp when dripping will stop
    function _emitDripping(
        UserOrAccount memory userOrAccount,
        address receiver,
        uint128 amtPerSec,
        uint64 endTime
    ) internal {
        if (amtPerSec == 0) endTime = _currTimestamp();
        if (userOrAccount.isAccount) {
            emit Dripping(userOrAccount.user, userOrAccount.account, receiver, amtPerSec, endTime);
        } else {
            emit Dripping(userOrAccount.user, receiver, amtPerSec, endTime);
        }
    }

    /// @notice Calculates the timestamp when dripping will end.
    /// @param startTime Time when dripping is started.
    /// @param startBalance The drips balance when dripping is started.
    /// @param totalAmtPerSec The total amount per second of all the drips receivers
    /// @return dripsEndTime The dripping end time.
    function _dripsEndTime(
        uint64 startTime,
        uint128 startBalance,
        uint128 totalAmtPerSec
    ) internal pure returns (uint64 dripsEndTime) {
        if (totalAmtPerSec == 0) return startTime;
        uint256 endTime = startTime + uint256(startBalance / totalAmtPerSec);
        return endTime > MAX_TIMESTAMP ? MAX_TIMESTAMP : uint64(endTime);
    }

    /// @notice Asserts that the drips configuration is the currently used one.
    /// @param userOrAccount The user or their account
    /// @param lastUpdate The timestamp of the last drips update of the user or the account.
    /// If this is the first update, pass zero.
    /// @param lastBalance The drips balance after the last drips update of the user or the account.
    /// If this is the first update, pass zero.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user or the account.
    /// If this is the first update, pass an empty array.
    function _assertCurrDrips(
        UserOrAccount memory userOrAccount,
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers
    ) internal view {
        bytes32 expectedHash;
        if (userOrAccount.isAccount) {
            expectedHash = accountDripsHashes[userOrAccount.user][userOrAccount.account];
        } else {
            expectedHash = userDripsHashes[userOrAccount.user];
        }
        bytes32 actualHash = hashDrips(lastUpdate, lastBalance, currReceivers);
        require(actualHash == expectedHash, "Invalid current drips configuration");
    }

    /// @notice Stores the hash of the current drips configuration to be used in `_assertCurrDrips`.
    /// @param userOrAccount The user or their account
    /// @param newBalance The user or the account drips balance.
    /// @param newReceivers The list of the drips receivers of the user or the account.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    function _storeCurrDrips(
        UserOrAccount memory userOrAccount,
        uint128 newBalance,
        DripsReceiver[] memory newReceivers
    ) internal {
        bytes32 currDripsHash = hashDrips(_currTimestamp(), newBalance, newReceivers);
        if (userOrAccount.isAccount) {
            accountDripsHashes[userOrAccount.user][userOrAccount.account] = currDripsHash;
        } else {
            userDripsHashes[userOrAccount.user] = currDripsHash;
        }
    }

    /// @notice Calculates the hash of the drips configuration.
    /// It's used to verify if drips configuration is the previously set one.
    /// @param update The timestamp of the drips update.
    /// If the drips have never been updated, pass zero.
    /// @param balance The drips balance.
    /// If the drips have never been updated, pass zero.
    /// @param receivers The list of the drips receivers.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// If the drips have never been updated, pass an empty array.
    /// @return dripsConfigurationHash The hash of the drips configuration
    function hashDrips(
        uint64 update,
        uint128 balance,
        DripsReceiver[] memory receivers
    ) public pure returns (bytes32 dripsConfigurationHash) {
        if (update == 0 && balance == 0 && receivers.length == 0) return bytes32(0);
        return keccak256(abi.encode(receivers, update, balance));
    }

    /// @notice Collects funds received by the user and sets their splits.
    /// The collected funds are split according to `currReceivers`.
    /// @param user The user
    /// @param currReceivers The list of the user's splits receivers which is currently in use.
    /// If this function is called for the first time for the user, should be an empty array.
    /// @param newReceivers The new list of the user's splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the user.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function _setSplits(
        address user,
        SplitsReceiver[] memory currReceivers,
        SplitsReceiver[] memory newReceivers
    ) internal returns (uint128 collected, uint128 split) {
        (collected, split) = _collectInternal(user, currReceivers);
        _assertSplitsValid(newReceivers);
        splitsHash[user] = hashSplits(newReceivers);
        emit SplitsUpdated(user, newReceivers);
        _transfer(user, int128(collected));
    }

    /// @notice Validates a list of splits receivers
    /// @param receivers The list of splits receivers
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    function _assertSplitsValid(SplitsReceiver[] memory receivers) internal pure {
        require(receivers.length <= MAX_SPLITS_RECEIVERS, "Too many splits receivers");
        uint64 totalWeight = 0;
        address prevReceiver;
        for (uint256 i = 0; i < receivers.length; i++) {
            uint32 weight = receivers[i].weight;
            require(weight != 0, "Splits receiver weight is zero");
            totalWeight += weight;
            address receiver = receivers[i].receiver;
            if (i > 0) {
                require(prevReceiver != receiver, "Duplicate splits receivers");
                require(prevReceiver < receiver, "Splits receivers not sorted by address");
            }
            prevReceiver = receiver;
        }
        require(totalWeight <= TOTAL_SPLITS_WEIGHT, "Splits weights sum too high");
    }

    /// @notice Asserts that the list of splits receivers is the user's currently used one.
    /// @param user The user
    /// @param currReceivers The list of the user's current splits receivers.
    function _assertCurrSplits(address user, SplitsReceiver[] memory currReceivers) internal view {
        require(hashSplits(currReceivers) == splitsHash[user], "Invalid current splits receivers");
    }

    /// @notice Calculates the hash of the list of splits receivers.
    /// @param receivers The list of the splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// @return receiversHash The hash of the list of splits receivers.
    function hashSplits(SplitsReceiver[] memory receivers)
        public
        pure
        returns (bytes32 receiversHash)
    {
        if (receivers.length == 0) return bytes32(0);
        return keccak256(abi.encode(receivers));
    }

    /// @notice Called when funds need to be transferred between the user and the drips hub.
    /// The function must be called no more than once per transaction.
    /// @param user The user
    /// @param amt The transferred amount.
    /// Positive to transfer funds to the user, negative to transfer from them.
    function _transfer(address user, int128 amt) internal virtual;

    /// @notice Sets amt delta of a user on a given timestamp
    /// @param user The user
    /// @param timestamp The timestamp from which the delta takes effect
    /// @param amtPerSecDelta Change of the per-second receiving rate
    function _setDelta(
        address user,
        uint64 timestamp,
        int128 amtPerSecDelta
    ) internal {
        if (amtPerSecDelta == 0) return;
        mapping(uint64 => AmtDelta) storage amtDeltas = receiverStates[user].amtDeltas;
        // In order to set a delta on a specific timestamp it must be introduced in two cycles.
        // The cycle delta is split proportionally based on how much this cycle is affected.
        // The next cycle has the rest of the delta applied, so the update is fully completed.
        uint64 thisCycle = timestamp / cycleSecs + 1;
        uint64 nextCycleSecs = timestamp % cycleSecs;
        uint64 thisCycleSecs = cycleSecs - nextCycleSecs;
        amtDeltas[thisCycle].thisCycle += int128(uint128(thisCycleSecs)) * amtPerSecDelta;
        amtDeltas[thisCycle].nextCycle += int128(uint128(nextCycleSecs)) * amtPerSecDelta;
    }

    function _userOrAccount(address user) internal pure returns (UserOrAccount memory) {
        return UserOrAccount({isAccount: false, user: user, account: 0});
    }

    function _userOrAccount(address user, uint256 account)
        internal
        pure
        returns (UserOrAccount memory)
    {
        return UserOrAccount({isAccount: true, user: user, account: account});
    }

    function _currTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }
}

////// lib/radicle-drips-hub/src/ERC20DripsHub.sol
/* pragma solidity ^0.8.7; */

/* import {SplitsReceiver, DripsHub, DripsReceiver} from "./DripsHub.sol"; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */

/// @notice Drips hub contract for any ERC-20 token.
/// See the base `DripsHub` contract docs for more details.
contract ERC20DripsHub is DripsHub {
    /// @notice The address of the ERC-20 contract which tokens the drips hub works with
    IERC20 public immutable erc20;

    /// @param cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time of funds being frozen
    /// between being taken from the users' drips balances and being collectable by their receivers.
    /// High value makes collecting cheaper by making it process less cycles for a given time range.
    /// @param owner The initial owner of the contract with managerial abilities.
    /// @param _erc20 The address of an ERC-20 contract which tokens the drips hub will work with.
    /// The supply of the tokens must be lower than `2 ^ 127`.
    constructor(
        uint64 cycleSecs,
        address owner,
        IERC20 _erc20
    ) DripsHub(cycleSecs, owner) {
        erc20 = _erc20;
    }

    /// @notice Sets the drips configuration of the `msg.sender`.
    /// Transfers funds to or from the sender to fulfill the update of the drips balance.
    /// The sender must first grant the contract a sufficient allowance.
    /// @param lastUpdate The timestamp of the last drips update of the `msg.sender`.
    /// If this is the first update, pass zero.
    /// @param lastBalance The drips balance after the last drips update of the `msg.sender`.
    /// If this is the first update, pass zero.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the `msg.sender`.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The drips balance change to be applied.
    /// Positive to add funds to the drips balance, negative to remove them.
    /// @param newReceivers The list of the drips receivers of the `msg.sender` to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @return newBalance The new drips balance of the `msg.sender`.
    /// Pass it as `lastBalance` when updating that user or the account for the next time.
    /// @return realBalanceDelta The actually applied drips balance change.
    function setDrips(
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers
    ) public whenNotPaused returns (uint128 newBalance, int128 realBalanceDelta) {
        return
            _setDrips(
                _userOrAccount(msg.sender),
                lastUpdate,
                lastBalance,
                currReceivers,
                balanceDelta,
                newReceivers
            );
    }

    /// @notice Sets the drips configuration of an account of the `msg.sender`.
    /// See `setDrips` for more details
    /// @param account The account
    function setDrips(
        uint256 account,
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers
    ) public whenNotPaused returns (uint128 newBalance, int128 realBalanceDelta) {
        return
            _setDrips(
                _userOrAccount(msg.sender, account),
                lastUpdate,
                lastBalance,
                currReceivers,
                balanceDelta,
                newReceivers
            );
    }

    /// @notice Gives funds from the `msg.sender` to the receiver.
    /// The receiver can collect them immediately.
    /// Transfers the funds to be given from the sender's wallet to the drips hub contract.
    /// @param receiver The receiver
    /// @param amt The given amount
    function give(address receiver, uint128 amt) public whenNotPaused {
        _give(_userOrAccount(msg.sender), receiver, amt);
    }

    /// @notice Gives funds from the account of the `msg.sender` to the receiver.
    /// The receiver can collect them immediately.
    /// Transfers the funds to be given from the sender's wallet to the drips hub contract.
    /// @param account The account
    /// @param receiver The receiver
    /// @param amt The given amount
    function give(
        uint256 account,
        address receiver,
        uint128 amt
    ) public whenNotPaused {
        _give(_userOrAccount(msg.sender, account), receiver, amt);
    }

    /// @notice Collects funds received by the `msg.sender` and sets their splits.
    /// The collected funds are split according to `currReceivers`.
    /// @param currReceivers The list of the user's splits receivers which is currently in use.
    /// If this function is called for the first time for the user, should be an empty array.
    /// @param newReceivers The new list of the user's splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the user.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function setSplits(SplitsReceiver[] memory currReceivers, SplitsReceiver[] memory newReceivers)
        public
        whenNotPaused
        returns (uint128 collected, uint128 split)
    {
        return _setSplits(msg.sender, currReceivers, newReceivers);
    }

    function _transfer(address user, int128 amt) internal override {
        if (amt > 0) erc20.transfer(user, uint128(amt));
        else if (amt < 0) erc20.transferFrom(user, address(this), uint128(-amt));
    }
}

////// lib/radicle-drips-hub/src/DaiDripsHub.sol
/* pragma solidity ^0.8.7; */

/* import {ERC20DripsHub, DripsReceiver, SplitsReceiver} from "./ERC20DripsHub.sol"; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */

interface IDai is IERC20 {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

struct PermitArgs {
    uint256 nonce;
    uint256 expiry;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/// @notice Drips hub contract for DAI token.
/// See the base `DripsHub` contract docs for more details.
contract DaiDripsHub is ERC20DripsHub {
    /// @notice The address of the Dai contract which tokens the drips hub works with.
    /// Always equal to `erc20`, but more strictly typed.
    IDai public immutable dai;

    /// @notice See `ERC20DripsHub` constructor documentation for more details.
    constructor(
        uint64 cycleSecs,
        address owner,
        IDai _dai
    ) ERC20DripsHub(cycleSecs, owner, _dai) {
        dai = _dai;
    }

    /// @notice Sets the drips configuration of the `msg.sender`
    /// and permits spending their Dai by the drips hub.
    /// This function is an extension of `setDrips`, see its documentation for more details.
    ///
    /// The user must sign a Dai permission document allowing the drips hub to spend their funds.
    /// These parameters will be passed to the Dai contract by this function.
    /// @param permitArgs The Dai permission arguments.
    function setDripsAndPermit(
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers,
        PermitArgs calldata permitArgs
    ) public whenNotPaused returns (uint128 newBalance, int128 realBalanceDelta) {
        _permit(permitArgs);
        return setDrips(lastUpdate, lastBalance, currReceivers, balanceDelta, newReceivers);
    }

    /// @notice Sets the drips configuration of an account of the `msg.sender`
    /// and permits spending their Dai by the drips hub.
    /// This function is an extension of `setDrips`, see its documentation for more details.
    ///
    /// The user must sign a Dai permission document allowing the drips hub to spend their funds.
    /// These parameters will be passed to the Dai contract by this function.
    /// @param permitArgs The Dai permission arguments.
    function setDripsAndPermit(
        uint256 account,
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers,
        PermitArgs calldata permitArgs
    ) public whenNotPaused returns (uint128 newBalance, int128 realBalanceDelta) {
        _permit(permitArgs);
        return
            setDrips(account, lastUpdate, lastBalance, currReceivers, balanceDelta, newReceivers);
    }

    /// @notice Gives funds from the `msg.sender` to the receiver
    /// and permits spending sender's Dai by the drips hub.
    /// This function is an extension of `give`, see its documentation for more details.
    ///
    /// The user must sign a Dai permission document allowing the drips hub to spend their funds.
    /// These parameters will be passed to the Dai contract by this function.
    /// @param permitArgs The Dai permission arguments.
    function giveAndPermit(
        address receiver,
        uint128 amt,
        PermitArgs calldata permitArgs
    ) public whenNotPaused {
        _permit(permitArgs);
        give(receiver, amt);
    }

    /// @notice Gives funds from the account of the `msg.sender` to the receiver
    /// and permits spending sender's Dai by the drips hub.
    /// This function is an extension of `give` see its documentation for more details.
    ///
    /// The user must sign a Dai permission document allowing the drips hub to spend their funds.
    /// These parameters will be passed to the Dai contract by this function.
    /// @param permitArgs The Dai permission arguments.
    function giveAndPermit(
        uint256 account,
        address receiver,
        uint128 amt,
        PermitArgs calldata permitArgs
    ) public whenNotPaused {
        _permit(permitArgs);
        give(account, receiver, amt);
    }

    /// @notice Permits the drips hub to spend the message sender's Dai.
    /// @param permitArgs The Dai permission arguments.
    function _permit(PermitArgs calldata permitArgs) internal {
        dai.permit(
            msg.sender,
            address(this),
            permitArgs.nonce,
            permitArgs.expiry,
            true,
            permitArgs.v,
            permitArgs.r,
            permitArgs.s
        );
    }
}