pragma solidity ^0.4.24;


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Lomocoin Authors
/// based on the fabulous work of Stefan George
/// some modification is inspired by https://blog.zeppelin.solutions/gnosis-multisig-wallet-audit-d702ff0e2b1e
contract MultiSigWallet {

    /*
     *  Events
     */
    // Confirmation is emitted when an owner to confirm a transaction
    event Confirmation(address indexed sender, uint indexed transactionId);
    // Revocation is emitted when an owner to revoke a confirmation for a transaction
    event Revocation(address indexed sender, uint indexed transactionId);
    // Submission is emitted when a new transaction is added to the transaction mapping, if transaction does not exist yet
    event Submission(uint indexed transactionId);
    // Execution is emitted when a confirmed transaction is executed
    event Execution(uint indexed transactionId);
    // ExecutionFailure is emitted when a confirmed transaction fails to execute
    event ExecutionFailure(uint indexed transactionId);
    // Deposit is emitted when wallet receives ether
    event Deposit(address indexed sender, uint value);
    // OwnerAddition is emitted when a new owner is added
    event OwnerAddition(address indexed owner);
    // OwnerRemoval is emitted when a owner is removed
    event OwnerRemoval(address indexed owner);
    // RequirementChange is emmited when the number of required confirmations is changed
    event RequirementChange(uint required);

    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
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
        require(
            msg.sender == address(this),
            &quot;only wallet itself can call this method&quot;
        );
        _;
    }

    modifier ownerDoesNotExist(address _owner) {
        require(
            !isOwner[_owner],
            &quot;owner can not call this method&quot;
        );
        _;
    }

    modifier ownerExists(address _owner) {
        require(
            isOwner[_owner],
            &quot;only owner can call this method&quot;
        );
        _;
    }

    modifier transactionExists(uint _transactionId) {
        require(
            transactions[_transactionId].destination != 0,
            &quot;tx does not exist / address 0x0 can not be dest&quot;
        );
        _;
    }

    modifier txConfirmedByOwner(uint _transactionId, address _owner) {
        require(
            confirmations[_transactionId][_owner],
            &quot;this tx has not been confirmed by this owner&quot;
        );
        _;
    }

    modifier txNotConfirmedByOwner(uint _transactionId, address _owner) {
        require(
            !confirmations[_transactionId][_owner],
            &quot;this tx has already been confirmed by this owner&quot;
        );
        _;
    }

    modifier notExecuted(uint _transactionId) {
        require(
            !transactions[_transactionId].executed,
            &quot;this tx has already been executed&quot;
        );
        _;
    }

    modifier notNull(address _address) {
        require(
            _address != 0,
            &quot;address can not be 0x0&quot;
        );
        _;
    }

    modifier validRequirement(uint _ownerCount, uint _required) {
        require(
            _ownerCount <= MAX_OWNER_COUNT &&
            _required <= _ownerCount &&
        _required != 0 &&
        _ownerCount != 0,
            &quot;invalid requirement / _required can not be 0 / _ownerCount can not be 0&quot;
        );
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
    payable
    public
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
    constructor (address[] _owners, uint _required)
    public
    validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param _owner Address of new owner.
    function addOwner(address _owner)
    public
    onlyWallet
    ownerDoesNotExist(_owner)
    notNull(_owner)
    validRequirement(owners.length + 1, required)
    {
        isOwner[_owner] = true;
        owners.push(_owner);
        emit  OwnerAddition(_owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param _owner Address of owner.
    function removeOwner(address _owner)
    public
    onlyWallet
    ownerExists(_owner)
    {
        isOwner[_owner] = false;
        for (uint i = 0; i < owners.length - 1; i++)
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;

        // ensure required is not more than owners.length
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        emit OwnerRemoval(_owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param _owner Address of owner to be replaced.
    /// @param _newOwner Address of new owner.
    function replaceOwner(address _owner, address _newOwner)
    public
    onlyWallet
    ownerExists(_owner)
    ownerDoesNotExist(_newOwner)
    notNull(_newOwner)
    {
        for (uint i = 0; i < owners.length; i++)
            if (owners[i] == _owner) {
                owners[i] = _newOwner;
                break;
            }
        isOwner[_owner] = false;
        isOwner[_newOwner] = true;
        emit OwnerRemoval(_owner);
        emit OwnerAddition(_newOwner);
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
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @param _data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address _destination, uint _value, bytes _data)
    public
    returns (uint transactionId)
    {
        transactionId = addTransaction(_destination, _value, _data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param _transactionId Transaction ID.
    function confirmTransaction(uint _transactionId)
    public
    ownerExists(msg.sender)
    transactionExists(_transactionId)
    txNotConfirmedByOwner(_transactionId, msg.sender)
    {
        confirmations[_transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, _transactionId);
        executeTransaction(_transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param _transactionId Transaction ID.
    function revokeConfirmation(uint _transactionId)
    public
    ownerExists(msg.sender)
    txConfirmedByOwner(_transactionId, msg.sender)
    notExecuted(_transactionId)
    {
        confirmations[_transactionId][msg.sender] = false;
        emit Revocation(msg.sender, _transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param _transactionId Transaction ID.
    function executeTransaction(uint _transactionId)
    public
    ownerExists(msg.sender)
    txConfirmedByOwner(_transactionId, msg.sender)
    notExecuted(_transactionId)
    {
        if (isConfirmed(_transactionId)) {
            Transaction storage txn = transactions[_transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(_transactionId);
            else {
                emit ExecutionFailure(_transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity&#39;s code generator to produce a loop that copies tx.data into memory.
    function external_call(address _destination, uint _value, uint _dataLength, bytes _data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // &quot;Allocate&quot; memory for output (0x40 is where &quot;free memory&quot; pointer is stored by convention)
            let d := add(_data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
            sub(gas, 34710), // 34710 is the value that solidity is currently emitting
            // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
            // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
            _destination,
            _value,
            d,
            _dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param _transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint _transactionId)
    public
    view
    returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[_transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @param _data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address _destination, uint _value, bytes _data)
    internal
    notNull(_destination)
    returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination : _destination,
            value : _value,
            data : _data,
            executed : false
            });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param _transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint _transactionId)
    public
    view
    returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++)
            if (confirmations[_transactionId][owners[i]]) {
                count += 1;
            }
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param _pending Include pending transactions.
    /// @param _executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool _pending, bool _executed)
    public
    view
    returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++)
            if (_pending && !transactions[i].executed
            || _executed && transactions[i].executed) {
                count += 1;
            }
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
    /// @param _transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint _transactionId)
    public
    view
    returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[_transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param _from Index start position of transaction array.
    /// @param _to Index end position of transaction array.
    /// @param _pending Include pending transactions.
    /// @param _executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint _from, uint _to, bool _pending, bool _executed)
    public
    view
    returns (uint[] transactionIds)
    {
        require(
            _from < _to,
            &quot;from should be less than to&quot;
        );

        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++)
            if (_pending && !transactions[i].executed
            || _executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        transactionIds = new uint[](_to - _from);
        for (i = _from; i < _to; i++)
            transactionIds[i - _from] = transactionIdsTemp[i];
    }
}