// solhint-disable
pragma solidity ^0.5.9;


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <[email protected]>
contract MultiSigWallet {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    /*
     *  Constants
     */
    uint256 constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(
            msg.sender == address(this),
            "ONLY_CALLABLE_BY_WALLET"
        );
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(
            !isOwner[owner],
            "OWNER_EXISTS"
        );
        _;
    }

    modifier ownerExists(address owner) {
        require(
            isOwner[owner],
            "OWNER_DOESNT_EXIST"
        );
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            "TX_DOESNT_EXIST"
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(
            confirmations[transactionId][owner],
            "TX_NOT_CONFIRMED"
        );
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(
            !confirmations[transactionId][owner],
            "TX_ALREADY_CONFIRMED"
        );
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            !transactions[transactionId].executed,
            "TX_ALREADY_EXECUTED"
        );
        _;
    }

    modifier notNull(address _address) {
        require(
            _address != address(0),
            "NULL_ADDRESS"
        );
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0,
            "INVALID_REQUIREMENTS"
        );
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        external
        payable
    {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(
        address[] memory _owners,
        uint256 _required
    )
        public
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(
                !isOwner[_owners[i]] && _owners[i] != address(0),
                "DUPLICATE_OR_NULL_OWNER"
            );
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
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.length -= 1;
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
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
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required)
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
    function submitTransaction(address destination, uint256 value, bytes memory data)
        public
        returns (uint256 transactionId)
    {
        transactionId = _addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId)
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
    function revokeConfirmation(uint256 transactionId)
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
    function executeTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (
                _externalCall(
                    txn.destination,
                    txn.value,
                    txn.data.length,
                    txn.data
                )
            ) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function _externalCall(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes memory data
    )
        internal
        returns (bool)
    {
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
    function isConfirmed(uint256 transactionId)
        public
        view
        returns (bool)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
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
    function _addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        internal
        notNull(destination)
        returns (uint256 transactionId)
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
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                count += 1;
            }
        }
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256[] memory _transactionIds)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "./MultiSigWallet.sol";


/// @title Multisignature wallet with time lock- Allows multiple parties to execute a transaction after a time lock has passed.
/// @author Amir Bandeali - <[email protected]>
// solhint-disable not-rely-on-time
contract MultiSigWalletWithTimeLock is
    MultiSigWallet
{
    using LibSafeMath for uint256;

    event ConfirmationTimeSet(uint256 indexed transactionId, uint256 confirmationTime);
    event TimeLockChange(uint256 secondsTimeLocked);

    uint256 public secondsTimeLocked;

    mapping (uint256 => uint256) public confirmationTimes;

    modifier fullyConfirmed(uint256 transactionId) {
        require(
            isConfirmed(transactionId),
            "TX_NOT_FULLY_CONFIRMED"
        );
        _;
    }

    modifier pastTimeLock(uint256 transactionId) {
        require(
            block.timestamp >= confirmationTimes[transactionId].safeAdd(secondsTimeLocked),
            "TIME_LOCK_INCOMPLETE"
        );
        _;
    }

    /// @dev Contract constructor sets initial owners, required number of confirmations, and time lock.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _secondsTimeLocked Duration needed after a transaction is confirmed and before it becomes executable, in seconds.
    constructor (
        address[] memory _owners,
        uint256 _required,
        uint256 _secondsTimeLocked
    )
        public
        MultiSigWallet(_owners, _required)
    {
        secondsTimeLocked = _secondsTimeLocked;
    }

    /// @dev Changes the duration of the time lock for transactions.
    /// @param _secondsTimeLocked Duration needed after a transaction is confirmed and before it becomes executable, in seconds.
    function changeTimeLock(uint256 _secondsTimeLocked)
        public
        onlyWallet
    {
        secondsTimeLocked = _secondsTimeLocked;
        emit TimeLockChange(_secondsTimeLocked);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        bool isTxFullyConfirmedBeforeConfirmation = isConfirmed(transactionId);

        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);

        if (!isTxFullyConfirmedBeforeConfirmation && isConfirmed(transactionId)) {
            _setConfirmationTime(transactionId, block.timestamp);
        }
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        public
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
        pastTimeLock(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        if (_externalCall(txn.destination, txn.value, txn.data.length, txn.data)) {
            emit Execution(transactionId);
        } else {
            emit ExecutionFailure(transactionId);
            txn.executed = false;
        }
    }

    /// @dev Sets the time of when a submission first passed.
    function _setConfirmationTime(uint256 transactionId, uint256 confirmationTime)
        internal
    {
        confirmationTimes[transactionId] = confirmationTime;
        emit ConfirmationTimeSet(transactionId, confirmationTime);
    }
}

pragma solidity ^0.5.9;

import "./LibRichErrors.sol";
import "./LibSafeMathRichErrors.sol";


library LibSafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


library LibRichErrors {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

pragma solidity ^0.5.9;


library LibSafeMathRichErrors {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./MultiSigWalletWithTimeLock.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";


contract ZeroExGovernor is
    MultiSigWalletWithTimeLock
{
    using LibBytes for bytes;
    using LibSafeMath for uint256;

    struct TimeLock {
        bool hasCustomTimeLock;
        uint128 secondsTimeLocked;
    }

    event FunctionCallTimeLockRegistration(
        bytes4 functionSelector,
        address destination,
        bool hasCustomTimeLock,
        uint128 newSecondsTimeLocked
    );

    // Function selector => destination => seconds timelocked
    mapping (bytes4 => mapping (address => TimeLock)) public functionCallTimeLocks;

    /// @dev Contract constructor sets initial owners, required number of confirmations, and default time lock
    ///      It will also register unique timelocks for each passed in function selector / destination combo.
    /// @param _functionSelectors Array of function selectors for registered functions.
    /// @param _destinations Array of destinations for registered function calls.
    /// @param _functionCallTimeLockSeconds Array of seconds that each registered function call will be timelocked.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _defaultSecondsTimeLocked Default duration in seconds needed after a transaction is confirmed to become executable.
    constructor (
        bytes4[] memory _functionSelectors,
        address[] memory _destinations,
        uint128[] memory _functionCallTimeLockSeconds,
        address[] memory _owners,
        uint256 _required,
        uint256 _defaultSecondsTimeLocked
    )
        public
        MultiSigWalletWithTimeLock(
            _owners,
            _required,
            _defaultSecondsTimeLocked
        )
    {
        uint256 length = _functionSelectors.length;
        require(
            length == _destinations.length && length == _functionCallTimeLockSeconds.length,
            "EQUAL_LENGTHS_REQUIRED"
        );

        // Register function timelocks
        for (uint256 i = 0; i != length; i++) {
            _registerFunctionCall(
                true,  // all functions registered in constructor are assumed to have a custom timelock
                _functionSelectors[i],
                _destinations[i],
                _functionCallTimeLockSeconds[i]
            );
        }
    }

    /// @dev Registers a custom timelock to a specific function selector / destination combo
    /// @param hasCustomTimeLock True if timelock is custom.
    /// @param functionSelector 4 byte selector of registered function.
    /// @param destination Address of destination where function will be called.
    /// @param newSecondsTimeLocked Duration in seconds needed after a transaction is confirmed to become executable.
    function registerFunctionCall(
        bool hasCustomTimeLock,
        bytes4 functionSelector,
        address destination,
        uint128 newSecondsTimeLocked
    )
        external
        onlyWallet
    {
        _registerFunctionCall(
            hasCustomTimeLock,
            functionSelector,
            destination,
            newSecondsTimeLocked
        );
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    ///      Transactions *must* encode the values with the signature "bytes[] data, address[] destinations, uint256[] values"
    ///      The `destination` and `value` fields of the transaction in storage are ignored.
    ///      All function calls must be successful or the entire call will revert.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        public
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
    {
        Transaction storage transaction = transactions[transactionId];
        transaction.executed = true;

        // Decode batch transaction data from transaction.data
        // `destination` and `value` fields of transaction are ignored
        // Note that `destination` must be non-0, or the transaction cannot be submitted
        // solhint-disable
        (
            bytes[] memory data,
            address[] memory destinations,
            uint256[] memory values
        ) = abi.decode(
            transaction.data,
            (bytes[], address[], uint256[])
        );
        // solhint-enable

        // Ensure lengths of array properties are equal
        uint256 length = data.length;
        require(
            length == destinations.length && length == values.length,
            "EQUAL_LENGTHS_REQUIRED"
        );

        uint256 transactionConfirmationTime = confirmationTimes[transactionId];
        for (uint i = 0; i != length; i++) {
            // Ensure that each function call is past its timelock
            _assertValidFunctionCall(
                transactionConfirmationTime,
                data[i],
                destinations[i]
            );
            // Call each function
            // solhint-disable-next-line avoid-call-value
            (bool didSucceed,) = destinations[i].call.value(values[i])(data[i]);
            // Ensure that function call was successful
            require(
                didSucceed,
                "FAILED_EXECUTION"
            );
        }
        emit Execution(transactionId);
    }

    /// @dev Registers a custom timelock to a specific function selector / destination combo
    /// @param hasCustomTimeLock True if timelock is custom.
    /// @param functionSelector 4 byte selector of registered function.
    /// @param destination Address of destination where function will be called.
    /// @param newSecondsTimeLocked Duration in seconds needed after a transaction is confirmed to become executable.
    function _registerFunctionCall(
        bool hasCustomTimeLock,
        bytes4 functionSelector,
        address destination,
        uint128 newSecondsTimeLocked
    )
        internal
    {
        // Clear the previous secondsTimeLocked if custom timelock not used
        uint128 _secondsTimeLocked = hasCustomTimeLock ? newSecondsTimeLocked : 0;
        TimeLock memory timeLock = TimeLock({
            hasCustomTimeLock: hasCustomTimeLock,
            secondsTimeLocked: _secondsTimeLocked
        });
        functionCallTimeLocks[functionSelector][destination] = timeLock;
        emit FunctionCallTimeLockRegistration(
            functionSelector,
            destination,
            hasCustomTimeLock,
            _secondsTimeLocked
        );
    }

    /// @dev Ensures that the function call has past its timelock.
    /// @param transactionConfirmationTime Timestamp at which transaction was fully confirmed.
    /// @param data Function calldata.
    /// @param destination Address to call function on.
    function _assertValidFunctionCall(
        uint256 transactionConfirmationTime,
        bytes memory data,
        address destination
    )
        internal
        view
    {
        bytes4 functionSelector = data.readBytes4(0);
        TimeLock memory timeLock = functionCallTimeLocks[functionSelector][destination];
        // solhint-disable not-rely-on-time
        if (timeLock.hasCustomTimeLock) {
            require(
                block.timestamp >= transactionConfirmationTime.safeAdd(timeLock.secondsTimeLocked),
                "CUSTOM_TIME_LOCK_INCOMPLETE"
            );
        } else {
            require(
                block.timestamp >= transactionConfirmationTime.safeAdd(secondsTimeLocked),
                "DEFAULT_TIME_LOCK_INCOMPLETE"
            );
        }
        // solhint-enable not-rely-on-time
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "./LibBytesRichErrors.sol";
import "./LibRichErrors.sol";


library LibBytes {

    using LibBytes for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return The byte that was popped off.
    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                b.length,
                0
            ));
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return True if arrays are the same. False otherwise.
    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return bytes32 value from byte array.
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return bytes4 value from byte array.
    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (b.length < index + 4) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                b.length,
                index + 4
            ));
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length)
        internal
        pure
    {
        assembly {
            mstore(b, length)
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


library LibBytesRichErrors {

    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR =
        0x28006595;

    // solhint-disable func-name-mixedcase
    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_BYTE_OPERATION_ERROR_SELECTOR,
            errorCode,
            offset,
            required
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";


contract ContractCallReceiver {

    using LibBytes for bytes;

    event ContractCall(
        bytes4 functionSelector,
        bytes data,
        uint256 value
    );

    bytes4 constant internal ALWAYS_REVERT_SELECTOR = 0xF1F2F3F4;

    function ()
        external
        payable
    {
        bytes4 selector = msg.data.readBytes4(0);
        if (selector == ALWAYS_REVERT_SELECTOR) {
            revert();
        }

        emit ContractCall(
            selector,
            msg.data,
            msg.value
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;


// solhint-disable no-empty-blocks
contract TestRejectEther {}

/*

  Copyright 2019 ZeroEx Intl.

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

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../src/ZeroExGovernor.sol";


// solhint-disable no-empty-blocks
contract TestZeroExGovernor is
    ZeroExGovernor
{
    constructor (
        bytes4[] memory _functionSelectors,
        address[] memory _destinations,
        uint128[] memory _functionCallTimeLockSeconds,
        address[] memory _owners,
        uint256 _required,
        uint256 _defaultSecondsTimeLocked
    )
        public
        ZeroExGovernor(
            _functionSelectors,
            _destinations,
            _functionCallTimeLockSeconds,
            _owners,
            _required,
            _defaultSecondsTimeLocked
        )
    {}
    
    function registerFunctionCallBypassWallet(
        bool hasCustomTimeLock,
        bytes4 functionSelector,
        address destination,
        uint128 newSecondsTimeLocked
    )
        external
    {
        _registerFunctionCall(
            hasCustomTimeLock,
            functionSelector,
            destination,
            newSecondsTimeLocked
        );
    }

    function assertValidFunctionCall(
        uint256 transactionConfirmationTime,
        bytes calldata data,
        address destination
    )
        external
        view
    {
        _assertValidFunctionCall(
            transactionConfirmationTime,
            data,
            destination
        );
    }
}