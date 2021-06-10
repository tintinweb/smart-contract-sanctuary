/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library LibBytes {
      /***********************************|
    |        Read Bytes Functions       |
    |__________________________________*/

    /**
    * @dev Reads a bytes32 value from a position in a byte array.
    * @param b Byte array containing a bytes32 value.
    * @param index Index in byte array of bytes32 value.
    * @return result bytes32 value from byte array.
    */
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(
        b.length >= index + 32,
        "LibBytes#readBytes32 greater or equal to 32 length required"
        );

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
        result := mload(add(b, index))
        }
        return result;
    }
}

contract MultiSigLibEIP712 {
    /***********************************|
  |             Constants             |
  |__________________________________*/

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "MultiSig";
    string public constant EIP712_DOMAIN_VERSION = "v1";

    // EIP712Domain Separator
    bytes32 public EIP712_DOMAIN_SEPARATOR;

    // SUBMIT_TRANSACTION_TYPE_HASH = keccak256("submitTransaction(uint256 transactionId,address destination,uint256 value,bytes data)");
    bytes32 public constant SUBMIT_TRANSACTION_TYPE_HASH = 0x2c78e27c3bb2592e67e8d37ad1a95bfccd188e77557c22593b1af0b920a08295;

    // CONFIRM_TRANSACTION_TYPE_HASH = keccak256("confirmTransaction(uint256 transactionId)");
    bytes32 public constant CONFIRM_TRANSACTION_TYPE_HASH = 0x3e96bdc38d4133bc81813a187b2d41bc74332643ce7dbe82c7d94ead8366a65f;

    constructor() public {
        EIP712_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                getChainID(),
                address(this)
            )
        );
    }

    /**
    * @dev Return `chainId`
    */
    function getChainID() internal pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// File: contracts/external/multisig/MultiSig.sol

/**
 * @title MultiSig
 * @author dYdX
 *
 * Multi-Signature Wallet.
 * Allows multiple parties to agree on transactions before execution.
 * Adapted from Stefan George's MultiSigWallet contract.
 *
 * Logic Changes:
 *  - Removed the fallback function
 *  - Ensure newOwner is notNull
 *
 * Syntax Changes:
 *  - Update Solidity syntax for 0.5.X: use `emit` keyword (events), use `view` keyword (functions)
 *  - Add braces to all `if` and `for` statements
 *  - Remove named return variables
 *  - Add space before and after comparison operators
 *  - Add ADDRESS_ZERO as a constant
 *  - uint => uint256
 *  - external_call => externalCall
 */
contract MultiSig is MultiSigLibEIP712 {
    using LibBytes for bytes;

    // ============ Events ============

    event Deposit(address indexed depositer, uint256 amount);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    // ============ Constants ============

    uint256 constant public MAX_OWNER_COUNT = 50;
    address constant ADDRESS_ZERO = address(0x0);

    // ============ Storage ============

    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    // ============ Structs ============

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    // ============ Modifiers ============

    modifier onlyWallet() {
        /* solium-disable-next-line error-reason */
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(
        uint256 transactionId
    ) {
        /* solium-disable-next-line error-reason */
        require(transactions[transactionId].destination != ADDRESS_ZERO);
        _;
    }

    modifier confirmed(
        uint256 transactionId,
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(
        uint256 transactionId,
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(
        uint256 transactionId
    ) {
        /* solium-disable-next-line error-reason */
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(
        address _address
    ) {
        /* solium-disable-next-line error-reason */
        require(_address != ADDRESS_ZERO);
        _;
    }

    modifier validRequirement(
        uint256 ownerCount,
        uint256 _required
    ) {
        /* solium-disable-next-line error-reason */
        require(
            ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0
        );
        _;
    }

    // ========= Fallback function ==========
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets initial owners and required number of confirmations.
     *
     * @param  _owners    List of initial owners.
     * @param  _required  Number of required confirmations.
     */
    constructor(
        address[] memory _owners,
        uint256 _required
    )
        public
        validRequirement(_owners.length, _required)
        MultiSigLibEIP712()
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            /* solium-disable-next-line error-reason */
            require(!isOwner[_owners[i]] && _owners[i] != ADDRESS_ZERO);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    // ============ Wallet-Only Functions ============

    /**
     * Allows to add a new owner. Transaction has to be sent by wallet.
     *
     * @param  owner  Address of new owner.
     */
    function addOwner(
        address owner
    )
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

    /**
     * Allows to remove an owner. Transaction has to be sent by wallet.
     *
     * @param  owner  Address of owner.
     */
    function removeOwner(
        address owner
    )
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
        delete owners[owners.length - 1];
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        emit OwnerRemoval(owner);
    }

    /**
     * Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
     *
     * @param  owner     Address of owner to be replaced.
     * @param  newOwner  Address of new owner.
     */
    function replaceOwner(
        address owner,
        address newOwner
    )
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
        notNull(newOwner)
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

    /**
     * Allows to change the number of required confirmations. Transaction has to be sent by wallet.
     *
     * @param  _required  Number of required confirmations.
     */
    function changeRequirement(
        uint256 _required
    )
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    // ============ Owner Functions ============

    /**
     * Allows an owner to submit and confirm a transaction.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        public
        returns (uint256)
    {
        uint256 transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /**
     * Allows an owner to submit and confirm a transaction via meta transaction.
     *
     * @param  signer           Signer of the meta transaction.
     * @param  transactionId    Transaction ID of this transaction.
     * @param  destination      Transaction target address.
     * @param  value            Transaction ether value.
     * @param  data             Transaction data payload.
     * @param  sig              Signature.
     * @return                  Transaction ID.
     */
    function submitTransaction(
        address signer,
        uint256 transactionId,
        address destination,
        uint256 value,
        bytes memory data,
        bytes memory sig
    )
        public
        ownerExists(signer)
        returns (uint256)
    {
        // SUBMIT_TRANSACTION_TYPE_HASH = keccak256("submitTransaction(uint256 transactionId,address destination,uint256 value,bytes data)");
        bytes32 EIP712SignDigest = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                EIP712_DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        SUBMIT_TRANSACTION_TYPE_HASH,
                        transactionId,
                        destination,
                        value,
                        data
                    )
                )
            )
        );
        validateSignature(signer, EIP712SignDigest, sig);

        uint256 _transactionId = addTransaction(destination, value, data);

        require(transactionId == _transactionId);

        confirmTransactionBySigner(signer, transactionId);
        return transactionId;
    }

    // confirm transaction on behalf of signer, not msg.sender
    function confirmTransactionBySigner(
        address signer,
        uint256 transactionId
    )
        internal
        transactionExists(transactionId)
        notConfirmed(transactionId, signer)
    {
        // Confirm
        confirmations[transactionId][signer] = true;
        emit Confirmation(signer, transactionId);

        // Execute
        executeTransactionBySigner(signer, transactionId);
    }

    // execute transaction on behalf of signer, not msg.sender
    function executeTransactionBySigner(
        address signer,
        uint256 transactionId
    )
        internal
        ownerExists(signer)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (externalCall(
                txn.destination,
                txn.value,
                txn.data.length,
                txn.data)
            ) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    /**
     * Allows an owner to confirm a transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function confirmTransaction(
        uint256 transactionId
    )
        public
        virtual
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /**
     * Allows an owner to confirm a transaction via meta transaction.
     *
     * @param  signer           Signer of the meta transaction.
     * @param  transactionId    Transaction ID.
     * @param  sig              Signature.
     */
    function confirmTransaction(
        address signer,
        uint256 transactionId,
        bytes memory sig
    )
        public
        virtual
        ownerExists(signer)
        transactionExists(transactionId)
        notConfirmed(transactionId, signer)
    {
        // CONFIRM_TRANSACTION_TYPE_HASH = keccak256("confirmTransaction(uint256 transactionId)");
        bytes32 EIP712SignDigest = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                EIP712_DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        CONFIRM_TRANSACTION_TYPE_HASH,
                        transactionId
                    )
                )
            )
        );
        validateSignature(signer, EIP712SignDigest, sig);

        confirmations[transactionId][signer] = true;
        emit Confirmation(signer, transactionId);
        executeTransactionBySigner(signer, transactionId);
    }

    /**
     * Allows an owner to revoke a confirmation for a transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function revokeConfirmation(
        uint256 transactionId
    )
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     * Allows an owner to execute a confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function executeTransaction(
        uint256 transactionId
    )
        public
        virtual
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (externalCall(
                txn.destination,
                txn.value,
                txn.data.length,
                txn.data)
            ) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // ============ Getter Functions ============

    /**
     * Returns the confirmation status of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Confirmation status.
     */
    function isConfirmed(
        uint256 transactionId
    )
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

    /**
     * Returns number of confirmations of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Number of confirmations.
     */
    function getConfirmationCount(
        uint256 transactionId
    )
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns total number of transactions after filers are applied.
     *
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Total number of transactions after filters are applied.
     */
    function getTransactionCount(
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < transactionCount; i++) {
            if (
                pending && !transactions[i].executed
                || executed && transactions[i].executed
            ) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns array of owners.
     *
     * @return  Array of owner addresses.
     */
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

    /**
     * Returns array with owner addresses, which confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Array of owner addresses.
     */
    function getConfirmations(
        uint256 transactionId
    )
        public
        view
        returns (address[] memory)
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
        address[] memory _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
        return _confirmations;
    }

    /**
     * Returns list of transaction IDs in defined range.
     *
     * @param  from      Index start position of transaction array.
     * @param  to        Index end position of transaction array.
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Array of transaction IDs.
     */
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++) {
            if (
                pending && !transactions[i].executed
                || executed && transactions[i].executed
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        uint256[] memory _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
        return _transactionIds;
    }

    // ============ Helper Functions ============

    function validateSignature(
        address signer,
        bytes32 digest,
        bytes memory sig
    )
        internal
        pure
    {
        require(sig.length == 65);
        uint8 v = uint8(sig[64]);
        bytes32 r = sig.readBytes32(0);
        bytes32 s = sig.readBytes32(32);
        address recovered = ecrecover(digest, v, r, s);
        require(signer == recovered);
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function externalCall(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes memory data
    )
        internal
        returns (bool)
    {
        bool result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
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

    /**
     * Adds a new transaction to the transaction mapping, if transaction does not exist yet.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        internal
        notNull(destination)
        returns (uint256)
    {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }
}

// File: contracts/external/multisig/DelayedMultiSig.sol

/**
 * @title DelayedMultiSig
 * @author dYdX
 *
 * Multi-Signature Wallet with delay in execution.
 * Allows multiple parties to execute a transaction after a time lock has passed.
 * Adapted from Amir Bandeali's MultiSigWalletWithTimeLock contract.

 * Logic Changes:
 *  - Only owners can execute transactions
 *  - Require that each transaction succeeds
 *  - Added function to execute multiple transactions within the same Ethereum transaction
 */
contract DelayedMultiSig is
    MultiSig
{
    // ============ Events ============

    event ConfirmationTimeSet(uint256 indexed transactionId, uint256 confirmationTime);
    event TimeLockChange(uint32 secondsTimeLocked);

    // ============ Storage ============

    uint32 public secondsTimeLocked;
    mapping (uint256 => uint256) public confirmationTimes;

    // ============ Modifiers ============

    modifier notFullyConfirmed(
        uint256 transactionId
    ) {
        require(
            !isConfirmed(transactionId),
            "TX_FULLY_CONFIRMED"
        );
        _;
    }

    modifier fullyConfirmed(
        uint256 transactionId
    ) {
        require(
            isConfirmed(transactionId),
            "TX_NOT_FULLY_CONFIRMED"
        );
        _;
    }

    modifier pastTimeLock(
        uint256 transactionId
    ) virtual {
        require(
            block.timestamp >= confirmationTimes[transactionId] + secondsTimeLocked,
            "TIME_LOCK_INCOMPLETE"
        );
        _;
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets initial owners, required number of confirmations, and time lock.
     *
     * @param  _owners             List of initial owners.
     * @param  _required           Number of required confirmations.
     * @param  _secondsTimeLocked  Duration needed after a transaction is confirmed and before it
     *                             becomes executable, in seconds.
     */
    constructor (
        address[] memory _owners,
        uint256 _required,
        uint32 _secondsTimeLocked
    )
        public
        MultiSig(_owners, _required)
    {
        secondsTimeLocked = _secondsTimeLocked;
    }

    // ============ Wallet-Only Functions ============

    /**
     * Changes the duration of the time lock for transactions.
     *
     * @param  _secondsTimeLocked  Duration needed after a transaction is confirmed and before it
     *                             becomes executable, in seconds.
     */
    function changeTimeLock(
        uint32 _secondsTimeLocked
    )
        public
        onlyWallet
    {
        secondsTimeLocked = _secondsTimeLocked;
        emit TimeLockChange(_secondsTimeLocked);
    }

    // ============ Owner Functions ============

    /**
     * Allows an owner to confirm a transaction.
     * Overrides the function in MultiSig.
     *
     * @param  transactionId  Transaction ID.
     */
    function confirmTransaction(
        uint256 transactionId
    )
        public
        override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        notFullyConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        if (isConfirmed(transactionId)) {
            setConfirmationTime(transactionId, block.timestamp);
        }
    }

    /**
     * Allows an owner to confirm a transaction via meta transaction.
     * Overrides the function in MultiSig.
     *
     * @param  signer           Signer of the meta transaction.
     * @param  transactionId    Transaction ID.
     * @param  sig              Signature.
     */
    function confirmTransaction(
        address signer,
        uint256 transactionId,
        bytes memory sig
    )
        public
        override
        ownerExists(signer)
        transactionExists(transactionId)
        notConfirmed(transactionId, signer)
        notFullyConfirmed(transactionId)
    {
        // CONFIRM_TRANSACTION_TYPE_HASH = keccak256("confirmTransaction(uint256 transactionId)");
        bytes32 EIP712SignDigest = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                EIP712_DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        CONFIRM_TRANSACTION_TYPE_HASH,
                        transactionId
                    )
                )
            )
        );
        validateSignature(signer, EIP712SignDigest, sig);

        confirmations[transactionId][signer] = true;
        emit Confirmation(signer, transactionId);
        if (isConfirmed(transactionId)) {
            setConfirmationTime(transactionId, block.timestamp);
        }
    }

    /**
     * Allows an owner to execute a confirmed transaction.
     * Overrides the function in MultiSig.
     *
     * @param  transactionId  Transaction ID.
     */
    function executeTransaction(
        uint256 transactionId
    )
        public
        override
        ownerExists(msg.sender)
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
        pastTimeLock(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        bool success = externalCall(
            txn.destination,
            txn.value,
            txn.data.length,
            txn.data
        );
        require(
            success,
            "TX_REVERTED"
        );
        emit Execution(transactionId);
    }

    /**
     * Allows an owner to execute multiple confirmed transactions.
     *
     * @param  transactionIds  List of transaction IDs.
     */
    function executeMultipleTransactions(
        uint256[] memory transactionIds
    )
        public
        ownerExists(msg.sender)
    {
        for (uint256 i = 0; i < transactionIds.length; i++) {
            executeTransaction(transactionIds[i]);
        }
    }

    // ============ Helper Functions ============

    /**
     * Sets the time of when a submission first passed.
     */
    function setConfirmationTime(
        uint256 transactionId,
        uint256 confirmationTime
    )
        internal
    {
        confirmationTimes[transactionId] = confirmationTime;
        emit ConfirmationTimeSet(transactionId, confirmationTime);
    }
}

// File: contracts/external/multisig/PartiallyDelayedMultiSig.sol

/**
 * @title PartiallyDelayedMultiSig
 * @author dYdX
 *
 * Multi-Signature Wallet with delay in execution except for some function selectors.
 */
contract PartiallyDelayedMultiSig is
    DelayedMultiSig
{
    // ============ Events ============

    event SelectorSet(address destination, bytes4 selector, bool approved);

    // ============ Constants ============

    bytes4 constant internal BYTES_ZERO = bytes4(0x0);

    // ============ Storage ============

    // destination => function selector => can bypass timelock
    mapping (address => mapping (bytes4 => bool)) public instantData;

    // ============ Modifiers ============

    // Overrides old modifier that requires a timelock for every transaction
    modifier pastTimeLock(
        uint256 transactionId
    ) override {
        // if the function selector is not exempt from timelock, then require timelock
        require(
            block.timestamp >= confirmationTimes[transactionId] + secondsTimeLocked
            || txCanBeExecutedInstantly(transactionId),
            "TIME_LOCK_INCOMPLETE"
        );
        _;
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets initial owners, required number of confirmations, and time lock.
     *
     * @param  _owners               List of initial owners.
     * @param  _required             Number of required confirmations.
     * @param  _secondsTimeLocked    Duration needed after a transaction is confirmed and before it
     *                               becomes executable, in seconds.
     * @param  _noDelayDestinations  List of destinations that correspond with the selectors.
     *                               Zero address allows the function selector to be used with any
     *                               address.
     * @param  _noDelaySelectors     All function selectors that do not require a delay to execute.
     *                               Fallback function is 0x00000000.
     */
    constructor (
        address[] memory _owners,
        uint256 _required,
        uint32 _secondsTimeLocked,
        address[] memory _noDelayDestinations,
        bytes4[] memory _noDelaySelectors
    )
        public
        DelayedMultiSig(_owners, _required, _secondsTimeLocked)
    {
        require(
            _noDelayDestinations.length == _noDelaySelectors.length,
            "ADDRESS_AND_SELECTOR_MISMATCH"
        );

        for (uint256 i = 0; i < _noDelaySelectors.length; i++) {
            address destination = _noDelayDestinations[i];
            bytes4 selector = _noDelaySelectors[i];
            instantData[destination][selector] = true;
            emit SelectorSet(destination, selector, true);
        }
    }

    // ============ Wallet-Only Functions ============

    /**
     * Adds or removes functions that can be executed instantly. Transaction must be sent by wallet.
     *
     * @param  destination  Destination address of function. Zero address allows the function to be
     *                      sent to any address.
     * @param  selector     4-byte selector of the function. Fallback function is 0x00000000.
     * @param  approved     True if adding approval, false if removing approval.
     */
    function setSelector(
        address destination,
        bytes4 selector,
        bool approved
    )
        public
        onlyWallet
    {
        instantData[destination][selector] = approved;
        emit SelectorSet(destination, selector, approved);
    }

    // ============ Helper Functions ============

    /**
     * Returns true if transaction can be executed instantly (without timelock).
     */
    function txCanBeExecutedInstantly(
        uint256 transactionId
    )
        internal
        view
        returns (bool)
    {
        // get transaction from storage
        Transaction memory txn = transactions[transactionId];
        address dest = txn.destination;
        bytes memory data = txn.data;

        // fallback function
        if (data.length == 0) {
            return selectorCanBeExecutedInstantly(dest, BYTES_ZERO);
        }

        // invalid function selector
        if (data.length < 4) {
            return false;
        }

        // check first four bytes (function selector)
        bytes32 rawData;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            rawData := mload(add(data, 32))
        }
        bytes4 selector = bytes4(rawData);

        return selectorCanBeExecutedInstantly(dest, selector);
    }

    /**
     * Function selector is in instantData for address dest (or for address zero).
     */
    function selectorCanBeExecutedInstantly(
        address destination,
        bytes4 selector
    )
        internal
        view
        returns (bool)
    {
        return instantData[destination][selector]
            || instantData[ADDRESS_ZERO][selector];
    }
}