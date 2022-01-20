// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "ILIFETreasury.sol";


contract LIFETreasury is ILIFETreasury {

    // ===== Events =====
    event Deposit(address indexed sender, uint amount, uint balance);
    // For Owners 
    event AddOwner(address indexed owner);
    event RemoveOwner(address indexed owner);
    event ReplaceOwner(address indexed oldOwner, address indexed newOwner);

    // for Transaction
    event SubmitTransaction(
        uint256 indexed transactionId,
        address indexed fromOwner,
        address indexed destination,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed transactionId);
    event RevokeConfirmation(address indexed owner, uint256 indexed transactionId);
    event ExecuteTransactionSuccess(uint256 indexed transactionId);
    event ExecuteTransactionFailure(uint256 indexed transactionId);
    event ChangeNumberOfRequiredConfirmation(uint256 numberOfRequiredConfirmation);


    // ===== Constants =====
    uint256 constant public MAX_OWNER_COUNT = 5;

    // ===== Storage =====
    // For Owners
    address[] public owners;
    mapping (address => bool) public isOwner;

    // For Transactions
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }
    // Mapping: transactionId => Transaction object
    mapping (uint256 => Transaction) public transactions;
    // Mapping: transactionId => (owner => confirmed or not))
    mapping (uint256 => mapping (address => bool)) public confirmations;
    uint256 public numberOfRequiredConfirmation;
    uint256 public transactionCount = 0;


    // ===== Modifiers =====
    modifier onlyTreasury() {
        require(msg.sender == address(this), "LIFETreasury: caller must be LIFETreasury");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "LIFETreasury: owner must not exist");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "LIFETreasury: owner must exist") ;
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            "LIFETreasury: transaction id must exist"
        );
        _;
    }

    modifier ownerConfirmed(uint256 transactionId, address owner) {
        require(
            confirmations[transactionId][owner],
            "LIFETreasury: transaction id must be confirmed by owner"
        );
        _;
    }

    modifier ownerNotConfirmed(uint256 transactionId, address owner) {
        require(
            !confirmations[transactionId][owner],
            "LIFETreasury: transaction id must not be confirmed by owner"
        );
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            !transactions[transactionId].executed,
            "LIFETreasury: transaction id must be executed"
        );
        _;
    }

    modifier notNullAddress(address _address) {
        require(_address != address(0), "LIFETreasury: address must not be null");
        _;
    }

    modifier validNumberOfConfirmation(
        uint256 ownerCount, 
        uint256 _numberOfRequiredConfirmation)
    {
        require(
            ownerCount > 0 && ownerCount <= MAX_OWNER_COUNT,
            "LIFETreasury: number of owners must be greater than zero and less than max owners"
        );
        require(
            _numberOfRequiredConfirmation > 0 && _numberOfRequiredConfirmation <= ownerCount,
            "LIFETreasury: number of required confirmations invalid"
        );
        _;
    }

    /*
    * Public functions
    */
    // @dev Contract constructor sets initial owners and numberOfRequiredConfirmation number of confirmations.
    // @param _owners List of initial owners.
    // @param _numberOfRequiredConfirmation Number of numberOfRequiredConfirmation confirmations.
    constructor (
        address[] memory _owners,
        uint256 _numberOfRequiredConfirmation
    )
        validNumberOfConfirmation(_owners.length, _numberOfRequiredConfirmation)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            
            require(owner != address(0), "LIFETreasury: invalid owner address");
            require(!isOwner[owner], "LIFETreasury: existed owner address");
            
            isOwner[owner] = true;
        }
        owners = _owners;
        numberOfRequiredConfirmation = _numberOfRequiredConfirmation;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // @dev Allows to add a new owner. Transaction has to be sent by wallet.
    // @param owner Address of new owner.
    function addOwner(
        address owner
    )
        public
        onlyTreasury
        notNullAddress(owner)
        ownerDoesNotExist(owner)
        validNumberOfConfirmation(owners.length + 1, numberOfRequiredConfirmation)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit AddOwner(owner);
    }

    // @dev Allows to remove an owner. Transaction has to be sent by wallet.
    // @param owner Address of owner.
    function removeOwner(
        address owner
    )
        public
        onlyTreasury
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();

        if (numberOfRequiredConfirmation > owners.length) {
            changeNumberOfConfirmationRequired(owners.length);
        }
        emit RemoveOwner(owner);
    }

    // @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    // @param owner Address of owner to be replaced.
    // @param newOwner Address of new owner.
    function replaceOwner(
        address oldOwner,
        address newOwner
    )
        public
        onlyTreasury
        ownerExists(oldOwner)
        ownerDoesNotExist(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == oldOwner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[oldOwner] = false;
        isOwner[newOwner] = true;
        emit RemoveOwner(oldOwner);
        emit AddOwner(newOwner);
    }

    // @dev Allows to change the number of numberOfRequiredConfirmation confirmations. Transaction has to be sent by wallet.
    // @param _numberOfRequiredConfirmation Number of numberOfRequiredConfirmation confirmations.
    function changeNumberOfConfirmationRequired(
        uint256 _numberOfRequiredConfirmation
    )
        public
        onlyTreasury
        validNumberOfConfirmation(owners.length, _numberOfRequiredConfirmation)
    {
        numberOfRequiredConfirmation = _numberOfRequiredConfirmation;
        emit ChangeNumberOfRequiredConfirmation(_numberOfRequiredConfirmation);
    }

    // @dev Allows an owner to submit and confirm a transaction.
    // @param destination Transaction target address.
    // @param value Transaction ether value.
    // @param data Transaction data payload.
    // @return Returns transaction ID.
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        public
        returns (uint256 transactionId)
    {
        // create new a transaction request
        transactionId = addTransaction(destination, value, data);
        // and make a confirmation of the sender on the transaction at the same time
        confirmTransaction(transactionId);
    }

    // @dev Allows an owner to confirm a transaction.
    // @param transactionId Transaction ID.
    function confirmTransaction(
        uint256 transactionId
    )
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        ownerNotConfirmed(transactionId, msg.sender)
    {
        // update confirmations: the sender had confirmed
        confirmations[transactionId][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, transactionId);

        // always check that the transaction has enough confirmations
        // and execute it as soon as possible
        executeTransaction(transactionId);
    }

    // @dev Allows an owner to revoke a confirmation for a transaction.
    // @param transactionId Transaction ID.
    function revokeConfirmation(
        uint256 transactionId
    )
        public
        ownerExists(msg.sender)
        ownerConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        // update the owner not confirmed on the transaction
        confirmations[transactionId][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, transactionId);
    }

    // @dev Allows anyone to execute a confirmed transaction.
    // @param transactionId Transaction ID.
    function executeTransaction(
        uint256 transactionId
    )
        public
        ownerExists(msg.sender)
        ownerConfirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {

        if (isConfirmedTransaction(transactionId)) {
            Transaction storage transaction = transactions[transactionId];
            transaction.executed = true;

            // execute the transaction
            (bool success, ) = transaction.destination.call{value: transaction.value}(
                transaction.data
            );

            // check result after execution
            require(success, "LIFETreasury: execute transaction failed");
            emit ExecuteTransactionSuccess(transactionId);
        }
    }

    /*
    * Internal functions
    */
    // @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    // @param destination Transaction target address.
    // @param value Transaction ether value.
    // @param data Transaction data payload.
    // @return Returns transaction ID.
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        internal
        notNullAddress(destination)
        returns (uint256 transactionId)
    {
        transactionCount += 1;
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        emit SubmitTransaction(transactionId, msg.sender, destination, value, data);
    }

    /*
    * Web3 call functions
    */
    // @dev Returns number of confirmations of a transaction.
    // @param transactionId Transaction ID.
    // @return Number of confirmations.
    function getConfirmationCount(
        uint256 transactionId
    )
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

    // @dev Returns total number of transactions after filers are applied.
    // @param pending Include pending transactions.
    // @param executed Include executed transactions.
    // @return total number of transactions
    function getTransactionCount(
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                count += 1;
            }
    }

    // @dev Returns the confirmation status of a transaction.
    // @param transactionId Transaction ID.
    // @return Confirmation status.
    function isConfirmedTransaction(
        uint256 transactionId
    )
        public
        view
        returns (bool)
    {
        uint256 count = 0;
        for (uint256 i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == numberOfRequiredConfirmation) {
                return true;
            }
        }
        return false;
    }

    // @dev Returns list of owner addresses.
    function getOwners() public view returns (address[] memory)
    {
        return owners;
    }

    // @dev Returns array with owner addresses, which confirmed transaction.
    // @param transactionId Transaction ID.
    // @return Returns array of owner addresses.
    function getConfirmations(
        uint256 transactionId
    )
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    // @dev Returns list of transaction IDs in defined range.
    // @param from Index start position of transaction array.
    // @param to Index end position of transaction array.
    // @param pending Include pending transactions.
    // @param executed Include executed transactions.
    // @return Returns array of transaction IDs.
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
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ILIFETreasury {}