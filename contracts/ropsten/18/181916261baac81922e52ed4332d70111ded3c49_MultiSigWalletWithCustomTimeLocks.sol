/*

  Copyright 2018 bZeroX, LLC
  Adapted from MultiSigWalletWithTimeLock.sol, Copyright 2017 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.4.24;

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        public
        payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity&#39;s code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas, 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

contract MultiSigWalletWithCustomTimeLocks is MultiSigWallet {

    event ConfirmationTimeSet(uint indexed transactionId, uint confirmationTime);
    event TimeLockDefaultChange(uint secondsTimeLockedDefault);
    event TimeLockCustomChange(string funcHeader, uint secondsTimeLockedCustom);
    event TimeLockCustomRemove(string funcHeader);

    struct CustomTimeLock {
        uint secondsTimeLocked;
        bool isSet;
    }
    
    uint public secondsTimeLockedDefault; // default timelock for functions without a custom setting
    mapping (bytes4 => CustomTimeLock) public customTimeLocks; // mapping of function headers to CustomTimeLock structs
    string[] public customTimeLockFunctions; // array of functions with custom values

    mapping (uint => uint) public confirmationTimes;

    modifier notFullyConfirmed(uint transactionId) {
        require(!isConfirmed(transactionId));
        _;
    }

    modifier fullyConfirmed(uint transactionId) {
        require(isConfirmed(transactionId));
        _;
    }

    modifier pastTimeLock(uint transactionId) {
        uint timelock = getSecondsTimeLockedByTx(transactionId);
        require(timelock == 0 || block.timestamp >= confirmationTimes[transactionId] + timelock);
        _;
    }

    /*
     * Public functions
     */

    /// @dev Contract constructor sets initial owners, required number of confirmations, and time lock.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _secondsTimeLockedDefault Default duration needed after a transaction is confirmed and before it becomes executable, in seconds.
    constructor(address[] _owners, uint _required, uint _secondsTimeLockedDefault)
        public
        MultiSigWallet(_owners, _required)
    {
        secondsTimeLockedDefault = _secondsTimeLockedDefault;

        customTimeLockFunctions.push("transferOwnership(address)");
        customTimeLocks[0xf2fde38b].isSet = true;
        customTimeLocks[0xf2fde38b].secondsTimeLocked = 600; // 10 min

        customTimeLockFunctions.push("transferBZxOwnership(address)");
        customTimeLocks[0x72e98a79].isSet = true;
        customTimeLocks[0x72e98a79].secondsTimeLocked = 600;

        customTimeLockFunctions.push("replaceContract(address)");
        customTimeLocks[0xfb08fdaa].isSet = true;
        customTimeLocks[0xfb08fdaa].secondsTimeLocked = 600;

        customTimeLockFunctions.push("setTarget(string,address)");
        customTimeLocks[0xc11296fc].isSet = true;
        customTimeLocks[0xc11296fc].secondsTimeLocked = 600;

        customTimeLockFunctions.push("setBZxAddresses(address,address,address,address)");
        customTimeLocks[0x0dc2e439].isSet = true;
        customTimeLocks[0x0dc2e439].secondsTimeLocked = 600;

        customTimeLockFunctions.push("setVault(address)");
        customTimeLocks[0x6817031b].isSet = true;
        customTimeLocks[0x6817031b].secondsTimeLocked = 600;
    }

    /// @dev Changes the default duration of the time lock for transactions.
    /// @param _secondsTimeLockedDefault Default duration needed after a transaction is confirmed and before it becomes executable, in seconds.
    function changeDefaultTimeLock(uint _secondsTimeLockedDefault)
        public
        onlyWallet
    {
        secondsTimeLockedDefault = _secondsTimeLockedDefault;
        emit TimeLockDefaultChange(_secondsTimeLockedDefault);
    }

    /// @dev Changes the custom duration of the time lock for transactions to a specific function.
    /// @param _funcId example: "functionName(address[6],uint256[9],address,uint256,bytes)"
    /// @param _secondsTimeLockedCustom Custom duration needed after a transaction is confirmed and before it becomes executable, in seconds.
    function changeCustomTimeLock(string _funcId, uint _secondsTimeLockedCustom)
        public
        onlyWallet
    {
        bytes4 f = bytes4(keccak256(abi.encodePacked(_funcId)));
        if (!customTimeLocks[f].isSet) {
            customTimeLocks[f].isSet = true;
            customTimeLockFunctions.push(_funcId);
        }
        customTimeLocks[f].secondsTimeLocked = _secondsTimeLockedCustom;
        emit TimeLockCustomChange(_funcId, _secondsTimeLockedCustom);
    }

    /// @dev Removes the custom duration of the time lock for transactions to a specific function.
    /// @param _funcId example: "functionName(address[6],uint256[9],address,uint256,bytes)"
    function removeCustomTimeLock(string _funcId)
        public
        onlyWallet
    {
        bytes4 f = bytes4(keccak256(abi.encodePacked(_funcId)));
        if (!customTimeLocks[f].isSet)
            revert();

        for (uint i=0; i < customTimeLockFunctions.length; i++) {
            if (keccak256(bytes(customTimeLockFunctions[i])) == keccak256(bytes(_funcId))) {
                if (i < customTimeLockFunctions.length - 1)
                    customTimeLockFunctions[i] = customTimeLockFunctions[customTimeLockFunctions.length - 1];
                customTimeLockFunctions.length--;

                customTimeLocks[f].secondsTimeLocked = 0;
                customTimeLocks[f].isSet = false;

                emit TimeLockCustomRemove(_funcId);

                break;
            }
        }
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        notFullyConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        if (getSecondsTimeLockedByTx(transactionId) > 0 && isConfirmed(transactionId)) {
            setConfirmationTime(transactionId, block.timestamp);
        }
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
        notFullyConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
        pastTimeLock(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
            emit Execution(transactionId);
        else {
            emit ExecutionFailure(transactionId);
            txn.executed = false;
        }
    }

    /// @dev Returns the custom timelock for a function, or the default timelock if a custom value isn&#39;t set
    /// @param _funcId Function signature (encoded bytes)
    /// @return Timelock value
    function getSecondsTimeLocked(bytes4 _funcId)
        public
        view
        returns (uint)
    {
        if (customTimeLocks[_funcId].isSet)
            return customTimeLocks[_funcId].secondsTimeLocked;
        else
            return secondsTimeLockedDefault;
    }

    /// @dev Returns the custom timelock for a function, or the default timelock if a custom value isn&#39;t set
    /// @param _funcId Function signature (complete string)
    /// @return Timelock value
    function getSecondsTimeLockedByString(string _funcId)
        public
        view
        returns (uint)
    {
        return (getSecondsTimeLocked(bytes4(keccak256(abi.encodePacked(_funcId)))));
    }

    /// @dev Returns the custom timelock for a transaction, or the default timelock if a custom value isn&#39;t set
    /// @param transactionId Transaction ID.
    /// @return Timelock value
    function getSecondsTimeLockedByTx(uint transactionId)
        public
        view
        returns (uint)
    {
        Transaction memory txn = transactions[transactionId];
        bytes memory data = txn.data;
        bytes4 funcId;
        assembly {
            funcId := mload(add(data, 32))
        }
        return (getSecondsTimeLocked(funcId));
    }

    /*
     * Internal functions
     */

    /// @dev Sets the time of when a submission first passed.
    function setConfirmationTime(uint transactionId, uint confirmationTime)
        internal
    {
        confirmationTimes[transactionId] = confirmationTime;
        emit ConfirmationTimeSet(transactionId, confirmationTime);
    }
}