pragma solidity ^0.4.24;

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }
}

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6f1c1b0a090e0141080a001d080a2f0c00011c0a011c161c41010a1b">[email&#160;protected]</a>>
/// @author Hung Le - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c8a0bda6afa4a588beb2a7bca9e6aba7a5e6bea6">[email&#160;protected]</a>>
contract TeamWallet {
    using ECDSA for bytes32;

    /*
     *  Events
     */
    event TeamCreated(address[] owners, address contractAddress, string id);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Rejection(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId, uint trackingId);
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
    mapping (uint => mapping (address => bool)) public rejections;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;
    string public id;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bytes reasonHash;
        bool executed;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this), "Sender is not wallet");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "Owner existed");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner does not existed");
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0, "Transaction was not existed");
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner], "Transaction was not confirmed");
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner], "Transaction was confirmed");
        _;
    }

    modifier notRejected(uint transactionId, address owner) {
        require(!rejections[transactionId][owner], "Transaction was rejected");
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, "Transaction was executed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0, "Null address");
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0, "Invalid required");
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
    constructor(address[] _owners, uint _required, string _id)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0, "Invalid owner");
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        id = _id;
        emit TeamCreated(owners, this, id);
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
        for (uint i = 0; i < owners.length - 1; i++)
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
        for (uint i = 0; i < owners.length; i++)
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

    /// @dev Allows an owner to submit and confirm a transaction, bypass signature.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @param owner Owner
    /// @return Returns transaction ID.
    function _submitTransaction(address destination, uint value, bytes data, bytes reasonHash, address owner, uint trackingId)
        internal
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data, reasonHash, trackingId);
        _confirmTransaction(transactionId, owner);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @param signature Signature
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data, bytes reasonHash, bytes signature, uint trackingId)
        public
        returns (uint transactionId)
    {
        bytes32 opHash = keccak256(abi.encodePacked(destination, value, data, reasonHash));
        address opSigner = opHash.recover(signature);
        
        transactionId = _submitTransaction(destination, value, data, reasonHash, opSigner, trackingId);
    }

    /// @dev Allows an owner to confirm a transaction, bypass signature.
    /// @param transactionId Transaction ID.
    function _confirmTransaction(uint transactionId, address owner)
        internal
        ownerExists(owner)
        transactionExists(transactionId)
        notConfirmed(transactionId, owner)
        notRejected(transactionId, owner)
    {
        confirmations[transactionId][owner] = true;
        emit Confirmation(owner, transactionId);
        _executeTransaction(transactionId, owner);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId, bytes signature)
        public
    {
        bytes32 opHash = keccak256(abi.encodePacked(transactionId));
        address opSigner = opHash.recover(signature);
        
        _confirmTransaction(transactionId, opSigner);
    }

    /// @dev Allows an owner to reject a transaction.
    /// @param transactionId Transaction ID.
    function _rejectTransaction(uint transactionId, address owner)
        internal
        ownerExists(owner)
        notConfirmed(transactionId, owner)
        notExecuted(transactionId)
    {
        rejections[transactionId][owner] = true;
        emit Rejection(owner, transactionId);
    }

    /// @dev Allows an owner to reject a transaction.
    /// @param transactionId Transaction ID.
    function rejectTransaction(uint transactionId, bytes signature)
        public
    {
        bytes32 opHash = keccak256(abi.encodePacked(transactionId));
        address opSigner = opHash.recover(signature);
        
        _rejectTransaction(transactionId, opSigner);
    }

    /// @dev Allows anyone to execute a confirmed transaction, bypass signature.
    /// @param transactionId Transaction ID.
    function _executeTransaction(uint transactionId, address owner)
        internal
        ownerExists(owner)
        confirmed(transactionId, owner)
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

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId, bytes signature)
        public
    {
        bytes32 opHash = keccak256(abi.encodePacked(transactionId));
        address opSigner = opHash.recover(signature);
        
        _executeTransaction(transactionId, opSigner);
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity&#39;s code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes data) private returns (bool) {
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
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
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
    function addTransaction(address destination, uint value, bytes data, bytes reasonHash, uint trackingId)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            reasonHash: reasonHash,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId, trackingId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) count += 1;
    }

    /// @dev Returns number of rejections of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of rejections.
    function getRejectionCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++)
            if (rejections[transactionId][owners[i]]) count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed ||
            executed && transactions[i].executed) count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        view
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        view
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getRejections(uint transactionId)
        public
        view
        returns (address[] _rejections)
    {
        address[] memory rejectionsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++)
            if (rejections[transactionId][owners[i]]) {
                rejectionsTemp[count] = owners[i];
                count += 1;
            }
        _rejections = new address[](count);
        for (i = 0; i < count; i++)
            _rejections[i] = rejectionsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed ||
                executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}