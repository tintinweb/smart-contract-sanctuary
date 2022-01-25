//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./MultiSigWallet.sol";


/// @title Multisignature wallet with daily limit - Allows an owner to withdraw a daily limit without multisig.
/// @author Stefan George - <[email protected]>
contract MultiSigWalletWithDailyLimit is MultiSigWallet {

    /*
     *  Events
     */
    event DailyLimitChange(uint dailyLimit);

    /*
     *  Storage
     */
    uint public dailyLimit;
    uint public lastDay;
    uint public spentToday;

    /*
     * Public functions
     */
    // @dev Contract constructor sets initial owners, required number of confirmations and daily withdraw limit.
    // @param _owners List of initial owners.
    // @param _required Number of required confirmations.
    // @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    constructor(address[] memory owners_, uint8 group_, uint8 required_, uint dailyLimit_) MultiSigWallet(owners_, group_, required_) {
        dailyLimit = dailyLimit_;
    }

    // @dev Allows to change the daily limit. Transaction has to be sent by wallet.
    // @param _dailyLimit Amount in wei.
    function changeDailyLimit(uint _dailyLimit)
        public
        onlyWallet
    {
        dailyLimit = _dailyLimit;
        emit DailyLimitChange(_dailyLimit);
    }

    // @dev Allows anyone to execute a confirmed transaction or ether withdraws until daily limit is reached.
    // @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public override
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        bool _confirmed = isConfirmed(transactionId);
        if (_confirmed || txn.data.length == 0 && isUnderLimit(txn.value)) {
            txn.executed = true;
            if (!_confirmed)
                spentToday += txn.value;
            if (external_call(txn.destination, txn.value, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
                if (!_confirmed)
                    spentToday -= txn.value;
            }
        }
    }

    /*
     * Internal functions
     */
    /// @dev Returns if amount is within daily limit and resets spentToday after one day.
    /// @param amount Amount to withdraw.
    /// @return Returns if amount is under daily limit.
    function isUnderLimit(uint amount)
        internal
        returns (bool)
    {
        if (block.timestamp > lastDay + 24 hours) {
            lastDay = block.timestamp;
            spentToday = 0;
        }
        if (spentToday + amount > dailyLimit || spentToday + amount < spentToday)
            return false;
        return true;
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns maximum withdraw amount.
    /// @return Returns amount.
    function calcMaxWithdraw()
        public
        view
        returns (uint)
    {
        if (block.timestamp > lastDay + 24 hours)
            return dailyLimit;
        if (dailyLimit < spentToday)
            return 0;
        return dailyLimit - spentToday;
    }
}