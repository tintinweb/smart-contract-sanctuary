//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSigWallet is Ownable {

    /*
     *  Constants
     */
    uint constant MIN_REQUIRED = 1;
    uint constant DEV_OWNER_CLASS = 1;
    uint constant A_OWNER_CLASS = 2;
    uint constant B_OWNER_CLASS = 3;

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint indexed transactionId);
    event OwnerConfirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event DevOwnerSubmission(uint indexed transactionId);
    event AOwnerSubmission(uint indexed transactionId);
    event BOwnerSubmission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event DevOwnerAddition(address indexed owner);
    event AOwnerAddition(address indexed owner);
    event BOwnerAddition(address indexed owner);

    /*
     *  Storage
     */
    mapping (uint => Transaction) public transactions;
    mapping (uint => OwnerTransaction) public ownerTransactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (uint => mapping (address => bool)) public ownerConfirmations;
    mapping (address => bool) public isDevOwner;
    mapping (address => bool) public isAOwner;
    mapping (address => bool) public isBOwner;
    address[] public devOwners;
    address[] public aOwners;
    address[] public bOwners;
    uint public required;
    uint public transactionCount;
    uint public ownerTransactionCount;
    bool lock = false;
    uint requiredFromEachGroup;

    struct Transaction {
        address payable destination;
        uint value;
        bool executed;
    }

    struct OwnerTransaction {
        address owner;
        uint class;
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
        require(!(isAOwner[owner] || isBOwner[owner] || isDevOwner[owner]));
        _;
    }

    modifier ownerExists(address owner) {
        require(isAOwner[owner] || isBOwner[owner] || isDevOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier ownerTransactionExists(uint transactionId) {
        require(ownerTransactions[transactionId].owner != address(0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier ownerConfirmed(uint transactionId, address owner) {
        require(ownerConfirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier ownerNotConfirmed(uint transactionId, address owner) {
        require(!ownerConfirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier ownerNotExecuted(uint transactionId) {
        require(!ownerTransactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(
        uint _devOwnerCount,
        uint _aOwnerCount,
        uint _bOwnerCount,
        uint _requiredFromEachGroup
    ) {
        require(
            _devOwnerCount > 1 &&
            _aOwnerCount > 1 &&
            _bOwnerCount > 1 &&
            requiredFromEachGroup >= MIN_REQUIRED
        );
        _;
    }

    constructor(
        address[] memory _devOwners, 
        address[] memory _aOwners,
        address[] memory _bOwners,
        uint _requiredFromEachGroup
    )
    {
        requiredFromEachGroup = _requiredFromEachGroup;

        uint i;
        for (i=0; i < _devOwners.length; i++) {
            require(!isDevOwner[_devOwners[i]] && _devOwners[i] != address(0));
            isDevOwner[_devOwners[i]] = true;
        }
        for (i=0; i < _aOwners.length; i++) {
            require(!isAOwner[_aOwners[i]] && _aOwners[i] != address(0));
            isAOwner[_aOwners[i]] = true;
        }
        for (i=0; i < _bOwners.length; i++) {
            require(!isBOwner[_bOwners[i]] && _bOwners[i] != address(0));
            isBOwner[_bOwners[i]] = true;
        }
        aOwners = _aOwners;
        bOwners = _bOwners;
        devOwners = _devOwners;
    }

    receive() payable external {
        require(msg.value > 0);
        
        emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addDevOwner(address owner)
        external
        ownerDoesNotExist(owner)
        notNull(owner)
        returns (uint ownerTransactionId)
    {
        ownerTransactionId = addDevOwnerTransaction(owner);
        _confirmOwnerTransaction(ownerTransactionId);
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addAOwner(address owner)
        external
        ownerDoesNotExist(owner)
        notNull(owner)
        returns (uint ownerTransactionId)
    {
        ownerTransactionId = addAOwnerTransaction(owner);
        _confirmOwnerTransaction(ownerTransactionId);
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addBOwner(address owner)
        external
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        returns (uint ownerTransactionId)
    {
        ownerTransactionId = addBOwnerTransaction(owner);
        _confirmOwnerTransaction(ownerTransactionId);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId Returns transaction ID.
    function submitTransaction(address payable destination, uint value)
        external
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value);
        _confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        external
    {
        _confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param ownerTransactionId Transaction ID.
    function confirmOwnerTransaction(uint ownerTransactionId)
        external
    {
        _confirmOwnerTransaction(ownerTransactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        external
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /*
     * Internal functions
     */

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function _confirmTransaction(uint transactionId)
        internal
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        internal
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        require(!lock);
        if (isConfirmed(transactionId)) {
            lock = true;
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            (bool success, ) = txn.destination.call{value:txn.value}("");
            if (success)
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
            lock = false;
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        internal
        view
        returns (bool)
    {
        uint countDev = 0;
        uint countA = 0;
        uint countB = 0;
        uint i = 0;
        for (i=0; i < devOwners.length; i++)
            if (confirmations[transactionId][devOwners[i]])
                countDev += 1;
        for (i=0; i < aOwners.length; i++)
            if (confirmations[transactionId][aOwners[i]])
                countA += 1;
        for (i=0; i < bOwners.length; i++)
            if (confirmations[transactionId][bOwners[i]])
                countB += 1;
        require(
            countDev > requiredFromEachGroup &&
            countA > requiredFromEachGroup &&
            countB > requiredFromEachGroup
        );
        return true;
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId Returns transaction ID.
    function addTransaction(address payable destination, uint value)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param owner Transaction target address.
    /// @return transactionId Returns transaction ID.
    function addDevOwnerTransaction(address owner)
        internal
        notNull(owner)
        returns (uint transactionId)
    {
        transactionId = ownerTransactionCount;
        ownerTransactions[transactionId] = OwnerTransaction({
            owner: owner,
            class: DEV_OWNER_CLASS,
            executed: false
        });
        ownerTransactionCount += 1;
        emit DevOwnerSubmission(transactionId);
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param owner Transaction target address.
    /// @return transactionId Returns transaction ID.
    function addAOwnerTransaction(address owner)
        internal
        notNull(owner)
        returns (uint transactionId)
    {
        transactionId = ownerTransactionCount;
        ownerTransactions[transactionId] = OwnerTransaction({
            owner: owner,
            class: A_OWNER_CLASS,
            executed: false
        });
        ownerTransactionCount += 1;
        emit AOwnerSubmission(transactionId);
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param owner Transaction target address.
    /// @return transactionId Returns transaction ID.
    function addBOwnerTransaction(address owner)
        internal
        notNull(owner)
        returns (uint transactionId)
    {
        transactionId = ownerTransactionCount;
        ownerTransactions[transactionId] = OwnerTransaction({
            owner: owner,
            class: B_OWNER_CLASS,
            executed: false
        });
        ownerTransactionCount += 1;
        emit BOwnerSubmission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count Number of confirmations.
    function getConfirmationCount(uint transactionId)
        external
        view
        returns (uint count)
    {
        uint i;
        for (i=0; i<devOwners.length; i++)
            if (confirmations[transactionId][devOwners[i]])
                count += 1;
        for (i=0; i<aOwners.length; i++)
            if (confirmations[transactionId][aOwners[i]])
                count += 1;
        for (i=0; i<bOwners.length; i++)
            if (confirmations[transactionId][bOwners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        external
        view
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        external
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](devOwners.length + aOwners.length + bOwners.length);
        uint count = 0;
        uint i;
        for (i=0; i<devOwners.length; i++)
            if (confirmations[transactionId][devOwners[i]]) {
                confirmationsTemp[count] = devOwners[i];
                count += 1;
            }
        for (i=0; i<aOwners.length; i++)
            if (confirmations[transactionId][aOwners[i]]) {
                confirmationsTemp[count] = aOwners[i];
                count += 1;
            }
        for (i=0; i<bOwners.length; i++)
            if (confirmations[transactionId][bOwners[i]]) {
                confirmationsTemp[count] = bOwners[i];
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
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        external
        view
        returns (uint[] memory _transactionIds)
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

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return _ownerTransactionIds Returns array of transaction IDs.
    function getOwnerTransactionIds(uint from, uint to, bool pending, bool executed)
        external
        view
        returns (uint[] memory _ownerTransactionIds)
    {
        uint[] memory ownerTransactionIdsTemp = new uint[](ownerTransactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !ownerTransactions[i].executed
                || executed && ownerTransactions[i].executed)
            {
                ownerTransactionIdsTemp[count] = i;
                count += 1;
            }
        _ownerTransactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _ownerTransactionIds[i - from] = ownerTransactionIdsTemp[i];
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function _confirmOwnerTransaction(uint transactionId)
        internal
        ownerExists(msg.sender)
        ownerTransactionExists(transactionId)
        ownerNotConfirmed(transactionId, msg.sender)
    {
        ownerConfirmations[transactionId][msg.sender] = true;
        emit OwnerConfirmation(msg.sender, transactionId);
        executeOwnerTransaction(transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param ownerTransactionId Transaction ID.
    function executeOwnerTransaction(uint ownerTransactionId)
        internal
        ownerExists(msg.sender)
        ownerConfirmed(ownerTransactionId, msg.sender)
        ownerNotExecuted(ownerTransactionId)
    {
        if(isOwnerConfirmed(ownerTransactionId)) {
            OwnerTransaction storage ownerTransaction = ownerTransactions[ownerTransactionId];
            if (ownerTransaction.class == DEV_OWNER_CLASS) {
                isDevOwner[ownerTransaction.owner] = true;
                devOwners.push(ownerTransaction.owner);
                ownerTransaction.executed = true;
                emit DevOwnerAddition(ownerTransaction.owner);
            }
            if (ownerTransaction.class == A_OWNER_CLASS) {
                isAOwner[ownerTransaction.owner] = true;
                aOwners.push(ownerTransaction.owner);
                ownerTransaction.executed = true;
                emit AOwnerAddition(ownerTransaction.owner);
            }
            if (ownerTransaction.class == B_OWNER_CLASS) {
                isBOwner[ownerTransaction.owner] = true;
                bOwners.push(ownerTransaction.owner);
                ownerTransaction.executed = true;
                emit BOwnerAddition(ownerTransaction.owner);
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isOwnerConfirmed(uint transactionId)
        internal
        view
        returns (bool)
    {
        uint countDev = 0;
        uint countA = 0;
        uint countB = 0;
        uint i = 0;
        for (i=0; i < devOwners.length; i++)
            if (ownerConfirmations[transactionId][devOwners[i]])
                countDev += 1;
        for (i=0; i < aOwners.length; i++)
            if (ownerConfirmations[transactionId][aOwners[i]])
                countA += 1;
        for (i=0; i < bOwners.length; i++)
            if (ownerConfirmations[transactionId][bOwners[i]])
                countB += 1;
        require(
            countDev > requiredFromEachGroup &&
            countA > requiredFromEachGroup &&
            countB > requiredFromEachGroup
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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