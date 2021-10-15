/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// Verified using https://dapp.tools

// hevm: flattened sources of lib/radicle-streaming/src/DaiPool.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-only
pragma solidity >=0.8.0 <0.9.0 >=0.8.7 <0.9.0;

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

////// lib/radicle-streaming/src/libraries/ReceiverWeights.sol
/* pragma solidity ^0.8.7; */

/// @notice A list of receivers to their weights, iterable and with random access
struct ReceiverWeights {
    mapping(address => ReceiverWeightsImpl.ReceiverWeightStored) data;
}

/// @notice Helper methods for receiver weights list.
/// The list works optimally if after applying a series of changes it's iterated over.
/// The list uses 1 word of storage per receiver with a non-zero weight.
library ReceiverWeightsImpl {
    using ReceiverWeightsImpl for ReceiverWeights;

    struct ReceiverWeightStored {
        address next;
        uint32 weight;
        bool isAttached;
        // Unused. Hints the compiler that it has full control over the content
        // of the whole storage slot and allows it to optimize more aggressively.
        uint56 slotFiller;
    }

    address internal constant ADDR_ROOT = address(0);

    /// @notice Return the next non-zero receiver weight and its address.
    /// Removes all the items that have zero receiver weights found
    /// between the current and the next item from the list.
    /// Iterating over the whole list prunes all the zeroed items.
    /// @param prevReceiver The previously returned `receiver` or ADDR_ROOT to start iterating
    /// @param prevReceiverHint The previously returned `receiverHint`
    /// or ADDR_ROOT to start iterating
    /// @return receiver The receiver address, ADDR_ROOT if the end of the list was reached
    /// @return receiverHint A value passed as `prevReceiverHint` on the next call
    /// @return weight The receiver weight
    function nextWeightPruning(
        ReceiverWeights storage self,
        address prevReceiver,
        address prevReceiverHint
    )
        internal
        returns (
            address receiver,
            address receiverHint,
            uint32 weight
        )
    {
        if (prevReceiver == ADDR_ROOT) prevReceiverHint = self.data[ADDR_ROOT].next;
        receiver = prevReceiverHint;
        while (receiver != ADDR_ROOT) {
            weight = self.data[receiver].weight;
            receiverHint = self.data[receiver].next;
            if (weight != 0) break;
            delete self.data[receiver];
            receiver = receiverHint;
        }
        if (receiver != prevReceiverHint) self.data[prevReceiver].next = receiver;
    }

    /// @notice Return the next non-zero receiver weight and its address
    /// @param prevReceiver The previously returned `receiver` or ADDR_ROOT to start iterating
    /// @param prevReceiverHint The previously returned `receiverHint`
    /// or ADDR_ROOT to start iterating
    /// @return receiver The receiver address, ADDR_ROOT if the end of the list was reached
    /// @return receiverHint A value passed as `prevReceiverHint` on the next call
    /// @return weight The receiver weight
    function nextWeight(
        ReceiverWeights storage self,
        address prevReceiver,
        address prevReceiverHint
    )
        internal
        view
        returns (
            address receiver,
            address receiverHint,
            uint32 weight
        )
    {
        receiver = (prevReceiver == ADDR_ROOT) ? self.data[ADDR_ROOT].next : prevReceiverHint;
        while (receiver != ADDR_ROOT) {
            weight = self.data[receiver].weight;
            receiverHint = self.data[receiver].next;
            if (weight != 0) break;
            receiver = receiverHint;
        }
    }

    /// @notice Set weight for a specific receiver
    /// @param receiver The receiver to set weight
    /// @param weight The weight to set
    /// @return previousWeight The previously set weight, may be zero
    function setWeight(
        ReceiverWeights storage self,
        address receiver,
        uint32 weight
    ) internal returns (uint32 previousWeight) {
        require(receiver != ADDR_ROOT, "Invalid receiver address");
        // Ensure that the weight for a specific receiver is attached to the list
        if (!self.data[receiver].isAttached) {
            address rootNext = self.data[ADDR_ROOT].next;
            self.data[ADDR_ROOT].next = receiver;
            self.data[receiver].next = rootNext;
            self.data[receiver].isAttached = true;
        }
        previousWeight = self.data[receiver].weight;
        self.data[receiver].weight = weight;
    }
}

////// lib/radicle-streaming/src/Pool.sol
/* pragma solidity ^0.8.7; */

/* import {ReceiverWeights, ReceiverWeightsImpl} from "./libraries/ReceiverWeights.sol"; */

struct ReceiverWeight {
    address receiver;
    uint32 weight;
}

/// @notice Funding pool contract. Automatically sends funds to a configurable set of receivers.
///
/// The contract has 2 types of users: the senders and the receivers.
///
/// A sender has some funds and a set of addresses of receivers, to whom he wants to send funds.
/// In order to send there are 3 conditions, which must be fulfilled:
///
/// 1. There must be funds on his account in this contract.
///    They can be added with `topUp` and removed with `withdraw`.
/// 2. Total amount sent to the receivers every second must be set to a non-zero value.
///    This is done with `setAmtPerSec`.
/// 3. A set of receivers must be non-empty.
///    Receivers can be added, removed and updated with `setReceiver`.
///    Each receiver has a weight, which is used to calculate how the total sent amount is split.
///
/// Each of these functions can be called in any order and at any time, they have immediate effects.
/// When all of these conditions are fulfilled, every second the configured amount is being sent.
/// It's extracted from the `withdraw`able balance and transferred to the receivers.
/// The process continues automatically until the sender's balance is empty.
///
/// A single address can act as any number of independent senders by using sub-senders.
/// A sub-sender is identified by a user address and an ID.
/// The sender and all sub-senders' configurations are independent and they have separate balances.
///
/// A receiver has an account, from which he can `collect` funds sent by the senders.
/// The available amount is updated every `cycleSecs` seconds,
/// so recently sent funds may not be `collect`able immediately.
/// `cycleSecs` is a constant configured when the pool is deployed.
///
/// A single address can be used as a receiver, a sender or any number of sub-senders,
/// even at the same time.
/// It will have multiple balances in the contract, one with received funds, one with funds
/// being sent and one with funds being sent for each used sub-sender.
/// These balances have no connection between them and no shared configuration.
/// In order to send received funds, they must be first collected and then used to tup up
/// if they are to be sent through the contract.
///
/// The concept of something happening periodically, e.g. every second or every `cycleSecs` are
/// only high-level abstractions for the user, Ethereum isn't really capable of scheduling work.
/// The actual implementation emulates that behavior by calculating the results of the scheduled
/// events based on how many seconds have passed and only when a user needs their outcomes.
///
/// The contract assumes that all amounts in the system can be stored in signed 128-bit integers.
/// It's guaranteed to be safe only when working with assets with supply lower than `2 ^ 127`.
abstract contract Pool {
    using ReceiverWeightsImpl for ReceiverWeights;

    /// @notice On every timestamp `T`, which is a multiple of `cycleSecs`, the receivers
    /// gain access to funds collected during `T - cycleSecs` to `T - 1`.
    uint64 public immutable cycleSecs;
    /// @dev Timestamp at which all funding periods must be finished
    uint64 internal constant MAX_TIMESTAMP = type(uint64).max - 2;
    /// @notice Maximum sum of all receiver weights of a single sender.
    /// Limits loss of per-second funding accuracy, they are always multiples of weights sum.
    uint32 public constant SENDER_WEIGHTS_SUM_MAX = 10_000;
    /// @notice Maximum number of receivers of a single sender.
    /// Limits costs of changes in sender's configuration.
    uint32 public constant SENDER_WEIGHTS_COUNT_MAX = 100;
    /// @notice Maximum value of drips fraction
    uint32 public constant DRIPS_FRACTION_MAX = 1_000_000;
    /// @notice The amount passed as the withdraw amount to withdraw all the funds
    uint128 public constant WITHDRAW_ALL = type(uint128).max;
    /// @notice The amount passed as the amount per second to keep the parameter unchanged
    uint128 public constant AMT_PER_SEC_UNCHANGED = type(uint128).max;

    /// @notice Emitted when a direct stream of funds between a sender and a receiver is updated.
    /// This is caused by a sender updating their parameters.
    /// Funds are being sent on every second between the event block's timestamp (inclusively) and
    /// `endTime` (exclusively) or until the timestamp of the next stream update (exclusively).
    /// @param sender The sender of the updated stream
    /// @param receiver The receiver of the updated stream
    /// @param amtPerSec The new amount per second sent from the sender to the receiver
    /// or 0 if sending is stopped
    /// @param endTime The timestamp when the funds stop being sent,
    /// always larger than the block timestamp or equal to it if sending is stopped
    event SenderToReceiverUpdated(
        address indexed sender,
        address indexed receiver,
        uint128 amtPerSec,
        uint64 endTime
    );

    /// @notice Emitted when a direct stream of funds between
    /// a sender's sub-sender and a receiver is updated.
    /// This is caused by a sender updating their sub-sender's parameters.
    /// Funds are being sent on every second between the event block's timestamp (inclusively) and
    /// `endTime` (exclusively) or until the timestamp of the next stream update (exclusively).
    /// @param senderAddr The address of the sender of the updated stream
    /// @param subSenderId The id of the sender's sub-sender
    /// @param receiver The receiver of the updated stream
    /// @param amtPerSec The new amount per second sent from the sender to the receiver
    /// or 0 if sending is stopped
    /// @param endTime The timestamp when the funds stop being sent,
    /// always larger than the block timestamp or equal to it if sending is stopped
    event SubSenderToReceiverUpdated(
        address indexed senderAddr,
        uint256 indexed subSenderId,
        address indexed receiver,
        uint128 amtPerSec,
        uint64 endTime
    );

    /// @notice Emitted when a sender is updated
    /// @param sender The updated sender
    /// @param balance The sender's balance since the event block's timestamp
    /// @param amtPerSec The target amount sent per second after the update.
    /// Takes effect on the event block's timestamp (inclusively).
    /// @param dripsFraction The fraction of received funds to be dripped.
    /// A value from 0 to `DRIPS_FRACTION_MAX` inclusively,
    /// where 0 means no dripping and `DRIPS_FRACTION_MAX` dripping everything.
    event SenderUpdated(
        address indexed sender,
        uint128 balance,
        uint128 amtPerSec,
        uint32 dripsFraction
    );

    /// @notice Emitted when a sender is updated
    /// @param senderAddr The address of the sender
    /// @param subSenderId The id of the sender's updated sub-sender
    /// @param balance The sender's balance since the event block's timestamp
    /// @param amtPerSec The target amount sent per second after the update.
    /// Takes effect on the event block's timestamp (inclusively).
    event SubSenderUpdated(
        address indexed senderAddr,
        uint256 indexed subSenderId,
        uint128 balance,
        uint128 amtPerSec
    );

    /// @notice Emitted when a receiver collects funds
    /// @param receiver The collecting receiver
    /// @param amt The collected amount
    event Collected(address indexed receiver, uint128 amt);

    struct Sender {
        // Timestamp at which the funding period has started
        uint64 startTime;
        // The amount available when the funding period has started
        uint128 startBalance;
        // The total weight of all the receivers, must never be larger than `SENDER_WEIGHTS_SUM_MAX`
        uint32 weightSum;
        // The number of the receivers, must never be larger than `SENDER_WEIGHTS_COUNT_MAX`.
        uint32 weightCount;
        // --- SLOT BOUNDARY
        // The target amount sent per second.
        // The actual amount is rounded down to the closes multiple of `weightSum`.
        uint128 amtPerSec;
        // The fraction of received funds to be dripped.
        // Always has value from 0 to `DRIPS_FRACTION_MAX` inclusively,
        // where 0 means no dripping and `DRIPS_FRACTION_MAX` dripping everything.
        uint32 dripsFraction;
        // --- SLOT BOUNDARY
        // The receivers' addresses and their weights
        ReceiverWeights receiverWeights;
    }

    struct Receiver {
        // The next cycle to be collected
        uint64 nextCollectedCycle;
        // The amount of funds received for the last collected cycle.
        // It never is negative, it's a signed integer only for convenience of casting.
        int128 lastFundsPerCycle;
        // --- SLOT BOUNDARY
        // The changes of collected amounts on specific cycle.
        // The keys are cycles, each cycle `C` becomes collectable on timestamp `C * cycleSecs`.
        mapping(uint64 => AmtDelta) amtDeltas;
    }

    struct AmtDelta {
        // Amount delta applied on this cycle
        int128 thisCycle;
        // Amount delta applied on the next cycle
        int128 nextCycle;
    }

    struct StreamUpdates {
        uint256 length;
        StreamUpdate[] updates;
    }

    struct StreamUpdate {
        address receiver;
        uint128 amtPerSec;
        uint64 endTime;
    }

    /// @dev Details about all the senders, the key is the owner's address
    mapping(address => Sender) internal senders;
    /// @dev Details about all the sub-senders, the keys is the owner address and the sub-sender ID
    mapping(address => mapping(uint256 => Sender)) internal subSenders;
    /// @dev Details about all the receivers, the key is the owner's address
    mapping(address => Receiver) internal receivers;

    /// @param _cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low values make funds more available by shortening the average duration of funds being
    /// frozen between being taken from senders' balances and being collectable by the receiver.
    /// High values make collecting cheaper by making it process less cycles for a given time range.
    constructor(uint64 _cycleSecs) {
        cycleSecs = _cycleSecs;
    }

    /// @notice Returns amount of received funds available for collection
    /// @param receiverAddr The address of the receiver
    /// @return collected The available amount
    function collectable(address receiverAddr) public view returns (uint128) {
        Receiver storage receiver = receivers[receiverAddr];
        uint64 collectedCycle = receiver.nextCollectedCycle;
        if (collectedCycle == 0) return 0;
        uint64 currFinishedCycle = _currTimestamp() / cycleSecs;
        if (collectedCycle > currFinishedCycle) return 0;
        int128 collected = 0;
        int128 lastFundsPerCycle = receiver.lastFundsPerCycle;
        for (; collectedCycle <= currFinishedCycle; collectedCycle++) {
            lastFundsPerCycle += receiver.amtDeltas[collectedCycle - 1].nextCycle;
            lastFundsPerCycle += receiver.amtDeltas[collectedCycle].thisCycle;
            collected += lastFundsPerCycle;
        }
        return uint128(collected);
    }

    /// @notice Collects all received funds available for the user and sends them to that user
    /// @param receiverAddr The address of the receiver
    function collect(address receiverAddr) public virtual {
        uint128 collected = _collectInternal(receiverAddr);
        if (collected > 0) {
            _transfer(receiverAddr, collected);
        }
        emit Collected(receiverAddr, collected);
    }

    /// @notice Removes from the history and returns the amount of received
    /// funds available for collection by the user
    /// @param receiverAddr The address of the receiver
    /// @return collected The collected amount
    function _collectInternal(address receiverAddr) internal returns (uint128 collected) {
        Receiver storage receiver = receivers[receiverAddr];
        uint64 collectedCycle = receiver.nextCollectedCycle;
        if (collectedCycle == 0) return 0;
        uint64 currFinishedCycle = _currTimestamp() / cycleSecs;
        if (collectedCycle > currFinishedCycle) return 0;
        int128 lastFundsPerCycle = receiver.lastFundsPerCycle;
        for (; collectedCycle <= currFinishedCycle; collectedCycle++) {
            lastFundsPerCycle += receiver.amtDeltas[collectedCycle - 1].nextCycle;
            lastFundsPerCycle += receiver.amtDeltas[collectedCycle].thisCycle;
            collected += uint128(lastFundsPerCycle);
            delete receiver.amtDeltas[collectedCycle - 1];
        }
        receiver.lastFundsPerCycle = lastFundsPerCycle;
        receiver.nextCollectedCycle = collectedCycle;
    }

    /// @notice Updates all the sender parameters of the user.
    /// See `_updateAnySender` for more details.
    /// @param senderAddr The address of the sender
    function _updateSenderInternal(
        address senderAddr,
        uint128 topUpAmt,
        uint128 withdrawAmt,
        uint128 amtPerSec,
        uint32 dripsFraction,
        ReceiverWeight[] calldata updatedReceivers
    ) internal returns (uint128 withdrawn) {
        Sender storage sender = senders[senderAddr];
        StreamUpdates memory updates;
        (withdrawn, updates) = _updateAnySender(
            sender,
            topUpAmt,
            withdrawAmt,
            amtPerSec,
            dripsFraction,
            updatedReceivers
        );
        emit SenderUpdated(senderAddr, sender.startBalance, sender.amtPerSec, sender.dripsFraction);
        for (uint256 i = 0; i < updates.length; i++) {
            StreamUpdate memory update = updates.updates[i];
            emit SenderToReceiverUpdated(
                senderAddr,
                update.receiver,
                update.amtPerSec,
                update.endTime
            );
        }
    }

    /// @notice Updates all the parameters of the sender's sub-sender.
    /// See `_updateAnySender` for more details.
    /// @param senderAddr The address of the sender
    /// @param subSenderId The id of the sender's sub-sender
    function _updateSubSenderInternal(
        address senderAddr,
        uint256 subSenderId,
        uint128 topUpAmt,
        uint128 withdrawAmt,
        uint128 amtPerSec,
        ReceiverWeight[] calldata updatedReceivers
    ) internal returns (uint128 withdrawn) {
        Sender storage sender = subSenders[senderAddr][subSenderId];
        StreamUpdates memory updates;
        (withdrawn, updates) = _updateAnySender(
            sender,
            topUpAmt,
            withdrawAmt,
            amtPerSec,
            0,
            updatedReceivers
        );
        emit SubSenderUpdated(senderAddr, subSenderId, sender.startBalance, sender.amtPerSec);
        for (uint256 i = 0; i < updates.length; i++) {
            StreamUpdate memory update = updates.updates[i];
            emit SubSenderToReceiverUpdated(
                senderAddr,
                subSenderId,
                update.receiver,
                update.amtPerSec,
                update.endTime
            );
        }
    }

    /// @notice Updates all the sender's parameters.
    ///
    /// Tops up and withdraws unsent funds from the balance of the sender.
    ///
    /// Sets the target amount sent every second from the sender.
    /// Every second this amount is rounded down to the closest multiple of the sum of the weights
    /// of the receivers and split between them proportionally to their weights.
    /// Each receiver then receives their part from the sender's balance.
    /// If set to zero, stops funding.
    ///
    /// Sets the weight of the provided receivers of the sender.
    /// The weight regulates the share of the amount sent every second
    /// that each of the sender's receivers get.
    /// Setting a non-zero weight for a new receiver adds it to the set of the sender's receivers.
    /// Setting zero as the weight for a receiver removes it from the set of the sender's receivers.
    /// @param sender The updated sender
    /// @param topUpAmt The topped up amount.
    /// @param withdrawAmt The amount to be withdrawn, must not be higher than available funds.
    /// Can be `WITHDRAW_ALL` to withdraw everything.
    /// @param amtPerSec The target amount to be sent every second.
    /// Can be `AMT_PER_SEC_UNCHANGED` to keep the amount unchanged.
    /// @param dripsFraction The fraction of received funds to be dripped.
    /// Must be a value from 0 to `DRIPS_FRACTION_MAX` inclusively,
    /// where 0 means no dripping and `DRIPS_FRACTION_MAX` dripping everything.
    /// @param updatedReceivers The list of the updated receivers and their new weights
    /// @return withdrawn The withdrawn amount which should be sent to the user.
    /// Equal to `withdrawAmt` unless `WITHDRAW_ALL` is used.
    /// @return updates The list of stream updates to log
    function _updateAnySender(
        Sender storage sender,
        uint128 topUpAmt,
        uint128 withdrawAmt,
        uint128 amtPerSec,
        uint32 dripsFraction,
        ReceiverWeight[] calldata updatedReceivers
    ) internal returns (uint128 withdrawn, StreamUpdates memory updates) {
        uint256 maxUpdates = sender.weightCount + updatedReceivers.length;
        updates = StreamUpdates({length: 0, updates: new StreamUpdate[](maxUpdates)});
        _stopSending(sender, updates);
        _topUp(sender, topUpAmt);
        withdrawn = _withdraw(sender, withdrawAmt);
        _setAmtPerSec(sender, amtPerSec);
        _setDripsFraction(sender, dripsFraction);
        for (uint256 i = 0; i < updatedReceivers.length; i++) {
            _setReceiver(sender, updatedReceivers[i].receiver, updatedReceivers[i].weight);
        }
        _startSending(sender, updates);
    }

    /// @notice Adds the given amount to the senders balance of the user.
    /// @param sender The updated sender
    /// @param amt The topped up amount
    function _topUp(Sender storage sender, uint128 amt) internal {
        if (amt != 0) sender.startBalance += amt;
    }

    /// @notice Returns amount of unsent funds available for withdrawal for the sender
    /// @param senderAddr The address of the sender
    /// @return balance The available balance
    function withdrawable(address senderAddr) public view returns (uint128) {
        return _withdrawableAnySender(senders[senderAddr]);
    }

    /// @notice Returns amount of unsent funds available for withdrawal for the sub-sender
    /// @param senderAddr The address of the sender
    /// @param subSenderId The id of the sender's sub-sender
    /// @return balance The available balance
    function withdrawableSubSender(address senderAddr, uint256 subSenderId)
        public
        view
        returns (uint128)
    {
        return _withdrawableAnySender(subSenders[senderAddr][subSenderId]);
    }

    /// @notice Returns amount of unsent funds available for withdrawal for the sender.
    /// See `withdrawable` for more details
    /// @param sender The queried sender
    function _withdrawableAnySender(Sender storage sender) internal view returns (uint128) {
        // Hasn't been sending anything
        if (sender.weightSum == 0 || sender.amtPerSec < sender.weightSum) {
            return sender.startBalance;
        }
        uint128 amtPerSec = sender.amtPerSec - (sender.amtPerSec % sender.weightSum);
        uint192 alreadySent = (_currTimestamp() - sender.startTime) * amtPerSec;
        if (alreadySent > sender.startBalance) {
            return sender.startBalance % amtPerSec;
        }
        return sender.startBalance - uint128(alreadySent);
    }

    /// @notice Withdraws unsent funds of the user.
    /// @param sender The updated sender
    /// @param amt The amount to be withdrawn, must not be higher than available funds.
    /// Can be `WITHDRAW_ALL` to withdraw everything.
    /// @return withdrawn The actually withdrawn amount.
    /// Equal to `amt` unless `WITHDRAW_ALL` is used.
    function _withdraw(Sender storage sender, uint128 amt) internal returns (uint128 withdrawn) {
        if (amt == 0) return 0;
        uint128 startBalance = sender.startBalance;
        if (amt == WITHDRAW_ALL) amt = startBalance;
        if (amt == 0) return 0;
        require(amt <= startBalance, "Not enough funds in the sender account");
        sender.startBalance = startBalance - amt;
        return amt;
    }

    /// @notice Sets the target amount sent every second from the user.
    /// Every second this amount is rounded down to the closest multiple of the sum of the weights
    /// of the receivers and split between them proportionally to their weights.
    /// Each receiver then receives their part from the sender's balance.
    /// If set to zero, stops funding.
    /// @param sender The updated sender
    /// @param amtPerSec The target amount to be sent every second
    function _setAmtPerSec(Sender storage sender, uint128 amtPerSec) internal {
        if (amtPerSec != AMT_PER_SEC_UNCHANGED) sender.amtPerSec = amtPerSec;
    }

    /// @notice Gets the target amount sent every second for the provided sender.
    /// The actual amount sent every second may differ from the target value.
    /// It's rounded down to the closest multiple of the sum of the weights of
    /// the sender's receivers and split between them proportionally to their weights.
    /// Each receiver then receives their part from the sender's balance.
    /// If zero, funding is stopped.
    /// @param senderAddr The address of the sender
    /// @return amt The target amount to be sent every second
    function getAmtPerSec(address senderAddr) public view returns (uint128 amt) {
        return senders[senderAddr].amtPerSec;
    }

    /// @notice Gets the target amount sent every second for the provided sub-sender.
    /// The actual amount sent every second may differ from the target value.
    /// It's rounded down to the closest multiple of the sum of the weights of
    /// the sub-sender's receivers and split between them proportionally to their weights.
    /// Each receiver then receives their part from the sub-sender's balance.
    /// If zero, funding is stopped.
    /// @param senderAddr The address of the sender
    /// @param subSenderId The id of the sender's sub-sender
    /// @return amt The target amount to be sent every second
    function getAmtPerSecSubSender(address senderAddr, uint256 subSenderId)
        public
        view
        returns (uint128 amt)
    {
        return subSenders[senderAddr][subSenderId].amtPerSec;
    }

    /// @notice Sets the fraction of received funds to be dripped by the sender.
    /// @param sender The updated sender
    /// @param dripsFraction The fraction of received funds to be dripped.
    /// Must be a value from 0 to `DRIPS_FRACTION_MAX` inclusively,
    /// where 0 means no dripping and `DRIPS_FRACTION_MAX` dripping everything.
    function _setDripsFraction(Sender storage sender, uint32 dripsFraction) internal {
        require(dripsFraction <= DRIPS_FRACTION_MAX, "Drip fraction too high");
        sender.dripsFraction = dripsFraction;
    }

    /// @notice Gets the fraction of received funds to be dripped by the provided user.
    /// @param userAddr The address of the user
    /// @return dripsFraction The fraction of received funds to be dripped.
    /// A value from 0 to `DRIPS_FRACTION_MAX` inclusively,
    /// where 0 means no dripping and `DRIPS_FRACTION_MAX` dripping everything.
    function getDripsFraction(address userAddr) public view returns (uint32 dripsFraction) {
        return senders[userAddr].dripsFraction;
    }

    /// @notice Sets the weight of the provided receiver of the user.
    /// The weight regulates the share of the amount sent every second
    /// that each of the sender's receivers gets.
    /// Setting a non-zero weight for a new receiver adds it to the list of the sender's receivers.
    /// Setting zero as the weight for a receiver removes it from the list of the sender's receivers.
    /// @param sender The updated sender
    /// @param receiver The address of the receiver
    /// @param weight The weight of the receiver
    function _setReceiver(
        Sender storage sender,
        address receiver,
        uint32 weight
    ) internal {
        uint64 senderWeightSum = sender.weightSum;
        uint32 oldWeight = sender.receiverWeights.setWeight(receiver, weight);
        senderWeightSum -= oldWeight;
        senderWeightSum += weight;
        require(senderWeightSum <= SENDER_WEIGHTS_SUM_MAX, "Too much total receivers weight");
        sender.weightSum = uint32(senderWeightSum);
        if (weight != 0 && oldWeight == 0) {
            sender.weightCount++;
            require(sender.weightCount <= SENDER_WEIGHTS_COUNT_MAX, "Too many receivers");
        } else if (weight == 0 && oldWeight != 0) {
            sender.weightCount--;
        }
    }

    /// @notice Gets the receivers to whom the sender sends funds.
    /// Each entry contains a weight, which regulates the share of the amount
    /// being sent every second in relation to other sender's receivers.
    /// @param senderAddr The address of the sender
    /// @return weights The list of receiver addresses and their weights.
    /// The weights are never zero.
    function getAllReceivers(address senderAddr)
        public
        view
        returns (ReceiverWeight[] memory weights)
    {
        return _getAllReceiversAnySender(senders[senderAddr]);
    }

    /// @notice Gets the receivers to whom the sub-sender sends funds.
    /// Each entry contains a weight, which regulates the share of the amount
    /// being sent every second in relation to other sub-sender's receivers.
    /// @param senderAddr The address of the sender
    /// @param subSenderId The id of the sender's sub-sender
    /// @return weights The list of receiver addresses and their weights.
    /// The weights are never zero.
    function getAllReceiversSubSender(address senderAddr, uint256 subSenderId)
        public
        view
        returns (ReceiverWeight[] memory weights)
    {
        return _getAllReceiversAnySender(subSenders[senderAddr][subSenderId]);
    }

    /// @notice Gets the receivers to whom the sender sends funds.
    /// See `getAllReceivers` for more details.
    /// @param sender The queried sender
    function _getAllReceiversAnySender(Sender storage sender)
        internal
        view
        returns (ReceiverWeight[] memory weights)
    {
        weights = new ReceiverWeight[](sender.weightCount);
        uint32 weightsCount = 0;
        // Iterating over receivers, see `ReceiverWeights` for details
        address receiver = ReceiverWeightsImpl.ADDR_ROOT;
        address hint = ReceiverWeightsImpl.ADDR_ROOT;
        while (true) {
            uint32 receiverWeight;
            (receiver, hint, receiverWeight) = sender.receiverWeights.nextWeight(receiver, hint);
            if (receiver == ReceiverWeightsImpl.ADDR_ROOT) break;
            weights[weightsCount++] = ReceiverWeight(receiver, receiverWeight);
        }
    }

    /// @notice Called when user funds need to be transferred out of the pool
    /// @param to The address of the transfer recipient.
    /// @param amt The transferred amount
    function _transfer(address to, uint128 amt) internal virtual;

    /// @notice Makes the user stop sending funds.
    /// It removes any effects of the sender from all of its receivers.
    /// It doesn't modify the sender.
    /// It allows the properties of the sender to be safely modified
    /// without having to update the state of its receivers.
    /// @param sender The updated sender
    /// @param updates The list of stream updates to log
    function _stopSending(Sender storage sender, StreamUpdates memory updates) internal {
        // Hasn't been sending anything
        if (sender.weightSum == 0 || sender.amtPerSec < sender.weightSum) return;
        uint128 amtPerWeight = sender.amtPerSec / sender.weightSum;
        uint128 amtPerSec = amtPerWeight * sender.weightSum;
        uint256 endTimeUncapped = sender.startTime + uint256(sender.startBalance / amtPerSec);
        uint64 endTime = endTimeUncapped > MAX_TIMESTAMP ? MAX_TIMESTAMP : uint64(endTimeUncapped);
        // The funding period has run out
        if (endTime <= _currTimestamp()) {
            sender.startBalance %= amtPerSec;
            return;
        }
        sender.startBalance -= (_currTimestamp() - sender.startTime) * amtPerSec;
        // Set negative deltas to clear deltas applied by the previous call to `_startSending`
        _setDeltasFromNow(sender, -int128(amtPerWeight), endTime, updates);
    }

    /// @notice Makes the user start sending funds.
    /// It applies effects of the sender on all of its receivers.
    /// It doesn't modify the sender.
    /// @param sender The updated sender
    /// @param updates The list of stream updates to log
    function _startSending(Sender storage sender, StreamUpdates memory updates) internal {
        // Won't be sending anything
        if (sender.weightSum == 0 || sender.amtPerSec < sender.weightSum) return;
        uint128 amtPerWeight = sender.amtPerSec / sender.weightSum;
        uint128 amtPerSec = amtPerWeight * sender.weightSum;
        // Won't be sending anything
        if (sender.startBalance < amtPerSec) return;
        sender.startTime = _currTimestamp();
        uint256 endTimeUncapped = _currTimestamp() + uint256(sender.startBalance / amtPerSec);
        uint64 endTime = endTimeUncapped > MAX_TIMESTAMP ? MAX_TIMESTAMP : uint64(endTimeUncapped);
        _setDeltasFromNow(sender, int128(amtPerWeight), endTime, updates);
    }

    /// @notice Sets deltas to all sender's receivers from now to `timeEnd`
    /// proportionally to their weights.
    /// Effects are applied as if the change was made on the beginning of the current cycle.
    /// @param sender The updated sender
    /// @param amtPerWeightPerSecDelta Amount of per-second delta applied per receiver weight
    /// @param timeEnd The timestamp from which the delta stops taking effect
    /// @param updates The list of stream updates to log
    function _setDeltasFromNow(
        Sender storage sender,
        int128 amtPerWeightPerSecDelta,
        uint64 timeEnd,
        StreamUpdates memory updates
    ) internal {
        // Iterating over receivers, see `ReceiverWeights` for details
        address receiverAddr = ReceiverWeightsImpl.ADDR_ROOT;
        address hint = ReceiverWeightsImpl.ADDR_ROOT;
        uint256 oldLength = updates.length;
        while (true) {
            uint32 weight;
            (receiverAddr, hint, weight) = sender.receiverWeights.nextWeightPruning(
                receiverAddr,
                hint
            );
            if (receiverAddr == ReceiverWeightsImpl.ADDR_ROOT) break;
            int128 amtPerSecDelta = int128(uint128(weight)) * amtPerWeightPerSecDelta;
            _setReceiverDeltaFromNow(receiverAddr, amtPerSecDelta, timeEnd);

            // Stopping sending
            if (amtPerSecDelta < 0) {
                updates.updates[updates.length] = StreamUpdate({
                    receiver: receiverAddr,
                    amtPerSec: 0,
                    endTime: _currTimestamp()
                });
                updates.length++;
            }
            // Starting sending
            else {
                // Find an old receiver stream log to update
                uint256 updated = 0;
                while (updated < oldLength && updates.updates[updated].receiver != receiverAddr) {
                    updated++;
                }
                // Receiver not found among old logs, will be pushed
                if (updated == oldLength) {
                    updated = updates.length;
                    updates.length++;
                }
                updates.updates[updated] = StreamUpdate({
                    receiver: receiverAddr,
                    amtPerSec: uint128(amtPerSecDelta),
                    endTime: timeEnd
                });
            }
        }
    }

    /// @notice Sets deltas to a receiver from now to `timeEnd`
    /// @param receiverAddr The address of the receiver
    /// @param amtPerSecDelta Change of the per-second receiving rate
    /// @param timeEnd The timestamp from which the delta stops taking effect
    function _setReceiverDeltaFromNow(
        address receiverAddr,
        int128 amtPerSecDelta,
        uint64 timeEnd
    ) internal {
        Receiver storage receiver = receivers[receiverAddr];
        // The receiver was never used, initialize it.
        // The first usage of a receiver is always setting a positive delta to start sending.
        // If the delta is negative, the receiver must've been used before and now is being cleared.
        if (amtPerSecDelta > 0 && receiver.nextCollectedCycle == 0)
            receiver.nextCollectedCycle = _currTimestamp() / cycleSecs + 1;
        // Set delta in a time range from now to `timeEnd`
        _setSingleDelta(receiver.amtDeltas, _currTimestamp(), amtPerSecDelta);
        _setSingleDelta(receiver.amtDeltas, timeEnd, -amtPerSecDelta);
    }

    /// @notice Sets delta of a single receiver on a given timestamp
    /// @param amtDeltas The deltas of the per-cycle receiving rate
    /// @param timestamp The timestamp from which the delta takes effect
    /// @param amtPerSecDelta Change of the per-second receiving rate
    function _setSingleDelta(
        mapping(uint64 => AmtDelta) storage amtDeltas,
        uint64 timestamp,
        int128 amtPerSecDelta
    ) internal {
        // In order to set a delta on a specific timestamp it must be introduced in two cycles.
        // The cycle delta is split proportionally based on how much this cycle is affected.
        // The next cycle has the rest of the delta applied, so the update is fully completed.
        uint64 thisCycle = timestamp / cycleSecs + 1;
        uint64 nextCycleSecs = timestamp % cycleSecs;
        uint64 thisCycleSecs = cycleSecs - nextCycleSecs;
        amtDeltas[thisCycle].thisCycle += int128(uint128(thisCycleSecs)) * amtPerSecDelta;
        amtDeltas[thisCycle].nextCycle += int128(uint128(nextCycleSecs)) * amtPerSecDelta;
    }

    function _currTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }
}

////// lib/radicle-streaming/src/ERC20Pool.sol
/* pragma solidity ^0.8.7; */

/* import {Pool, ReceiverWeight} from "./Pool.sol"; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */

/// @notice Funding pool contract for any ERC-20 token.
/// See the base `Pool` contract docs for more details.
contract ERC20Pool is Pool {
    /// @notice The address of the ERC-20 contract which tokens the pool works with
    IERC20 public immutable erc20;

    /// @param cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low values make funds more available by shortening the average duration of tokens being
    /// frozen between being taken from senders' balances and being collectable by the receiver.
    /// High values make collecting cheaper by making it process less cycles for a given time range.
    /// @param _erc20 The address of an ERC-20 contract which tokens the pool will work with.
    /// To guarantee safety the supply of the tokens must be lower than `2 ^ 127`.
    constructor(uint64 cycleSecs, IERC20 _erc20) Pool(cycleSecs) {
        erc20 = _erc20;
    }

    /// @notice Updates all the sender parameters of the sender of the message.
    ///
    /// Tops up and withdraws unsent funds from the balance of the sender.
    /// The sender must first grant the contract a sufficient allowance to top up.
    /// Sends the withdrawn funds to the sender of the message.
    ///
    /// Sets the target amount sent every second from the sender of the message.
    /// Every second this amount is rounded down to the closest multiple of the sum of the weights
    /// of the receivers and split between them proportionally to their weights.
    /// Each receiver then receives their part from the sender's balance.
    /// If set to zero, stops funding.
    ///
    /// Sets the weight of the provided receivers of the sender of the message.
    /// The weight regulates the share of the amount sent every second
    /// that each of the sender's receivers get.
    /// Setting a non-zero weight for a new receiver adds it to the set of the sender's receivers.
    /// Setting zero as the weight for a receiver removes it from the set of the sender's receivers.
    /// @param topUpAmt The topped up amount
    /// @param withdraw The amount to be withdrawn, must not be higher than available funds.
    /// Can be `WITHDRAW_ALL` to withdraw everything.
    /// @param amtPerSec The target amount to be sent every second.
    /// Can be `AMT_PER_SEC_UNCHANGED` to keep the amount unchanged.
    /// @param dripsFraction The fraction of received funds to be dripped.
    /// Must be a value from 0 to `DRIPS_FRACTION_MAX` inclusively,
    /// where 0 means no dripping and `DRIPS_FRACTION_MAX` dripping everything.
    /// @param updatedReceivers The list of the updated receivers and their new weights
    /// @return withdrawn The actually withdrawn amount.
    function updateSender(
        uint128 topUpAmt,
        uint128 withdraw,
        uint128 amtPerSec,
        uint32 dripsFraction,
        ReceiverWeight[] calldata updatedReceivers
    ) public virtual returns (uint128 withdrawn) {
        _transferToContract(msg.sender, topUpAmt);
        withdrawn = _updateSenderInternal(
            msg.sender,
            topUpAmt,
            withdraw,
            amtPerSec,
            dripsFraction,
            updatedReceivers
        );
        _transfer(msg.sender, withdrawn);
    }

    /// @notice Updates all the parameters of a sub-sender of the sender of the message.
    /// See `updateSender` for more details
    /// @param subSenderId The id of the sender's sub-sender
    function updateSubSender(
        uint256 subSenderId,
        uint128 topUpAmt,
        uint128 withdraw,
        uint128 amtPerSec,
        ReceiverWeight[] calldata updatedReceivers
    ) public payable virtual returns (uint128 withdrawn) {
        _transferToContract(msg.sender, topUpAmt);
        withdrawn = _updateSubSenderInternal(
            msg.sender,
            subSenderId,
            topUpAmt,
            withdraw,
            amtPerSec,
            updatedReceivers
        );
        _transfer(msg.sender, withdrawn);
    }

    function _transferToContract(address from, uint128 amt) internal {
        if (amt != 0) erc20.transferFrom(from, address(this), amt);
    }

    function _transfer(address to, uint128 amt) internal override {
        if (amt != 0) erc20.transfer(to, amt);
    }
}

////// lib/radicle-streaming/src/DaiPool.sol
/* pragma solidity ^0.8.7; */

/* import {ERC20Pool, ReceiverWeight} from "./ERC20Pool.sol"; */
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

/// @notice Funding pool contract for DAI token.
/// See the base `Pool` contract docs for more details.
contract DaiPool is ERC20Pool {
    /// @notice The address of the Dai contract which tokens the pool works with.
    /// Always equal to `erc20`, but more strictly typed.
    IDai public immutable dai;

    /// @notice See `ERC20Pool` constructor documentation for more details.
    constructor(uint64 cycleSecs, IDai _dai) ERC20Pool(cycleSecs, _dai) {
        dai = _dai;
    }

    /// @notice Updates all the sender parameters of the sender of the message
    /// and permits spending sender's Dai by the pool.
    /// This function is an extension of `updateSender`, see its documentation for more details.
    ///
    /// The sender must sign a Dai permission document allowing the pool to spend their funds.
    /// The document's `nonce` and `expiry` must be passed here along the parts of its signature.
    /// These parameters will be passed to the Dai contract by this function.
    function updateSenderAndPermit(
        uint128 topUpAmt,
        uint128 withdraw,
        uint128 amtPerSec,
        uint32 dripsFraction,
        ReceiverWeight[] calldata updatedReceivers,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint128 withdrawn) {
        dai.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
        return updateSender(topUpAmt, withdraw, amtPerSec, dripsFraction, updatedReceivers);
    }

    /// @notice Updates all the parameters of a sub-sender of the sender of the message
    /// and permits spending sender's Dai by the pool.
    /// This function is an extension of `updateSubSender`, see its documentation for more details.
    /// @param subSenderId The id of the sender's sub-sender
    function updateSubSenderAndPermit(
        uint256 subSenderId,
        uint128 topUpAmt,
        uint128 withdraw,
        uint128 amtPerSec,
        ReceiverWeight[] calldata updatedReceivers,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint128 withdrawn) {
        dai.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
        return updateSubSender(subSenderId, topUpAmt, withdraw, amtPerSec, updatedReceivers);
    }
}