// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.4;

contract ContractsManager {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    Transaction[] public pendingTransactions; // getPendingTransactions
    Transaction[] public approvedTransactions; // getApprovedTransactions
    Transaction[] public executedTransactions; // getApprovedTransactions
    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // MODIFIERS
    modifier onlyOwner() {
        require(isOwner[msg.sender], "ERROR_NOT_OWNER");
        _;
    }
    modifier pendingTxExists(uint _txIndex) {
        require(_txIndex < pendingTransactions.length, "ERROR_TX_DOES_NOT_EXISTS");
        _;
    }
    modifier approvedTxExists(uint _txIndex) {
        require(_txIndex < approvedTransactions.length, "ERROR_TX_DOES_NOT_EXISTS");
        _;
    }
    modifier pendingNotExecuted(uint _txIndex) {
        require(!pendingTransactions[_txIndex].executed, "ERROR_TX_ALREADY_EXECUTED");
        _;
    }
    modifier approvedNotExecuted(uint _txIndex) {
        require(!approvedTransactions[_txIndex].executed, "ERROR_TX_ALREADY_EXECUTED");
        _;
    }
    modifier notConfirmedBySender(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "ERROR_TX_ALTREADY_CONFIRMED");
        _;
    }
    modifier confirmedBySender(uint _txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "ERROR_TX_NOT_CONFIRMED_WITH_THIS_ADDRESS");
        _;
    }
    modifier selfTransaction() {
        require(msg.sender == address(this), "ERROR_ONLY_SELF_TX");
        _;
    }

    // STRUCTS
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // CONTRUCTOR
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        setOwners(_owners, _numConfirmationsRequired);
    }

    // ONLYOWNER METHODS
    function submitTransaction(address _to, uint _value, bytes memory _data)
        public
        payable
        onlyOwner
    {
        uint txIndex = pendingTransactions.length;

        pendingTransactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 1
        }));

        isConfirmed[txIndex][msg.sender] = true;

        emit SubmitedTransaction(msg.sender, txIndex, _to, _value, 1, _data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        pendingTxExists(_txIndex)
        pendingNotExecuted(_txIndex)
        notConfirmedBySender(_txIndex)
    {
        Transaction storage transaction = pendingTransactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        if (transaction.numConfirmations >= numConfirmationsRequired) {
            delete pendingTransactions[_txIndex];
            approvedTransactions.push(transaction);
        }

        emit ConfirmedTransaction(msg.sender, _txIndex, transaction.numConfirmations);
    }

    function cancelPendingConfirmation(uint _txIndex)
        public
        onlyOwner
        pendingTxExists(_txIndex)
        pendingNotExecuted(_txIndex)
        confirmedBySender(_txIndex)
    {
        Transaction storage transaction = pendingTransactions[_txIndex];

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit CancelledConfirmation(msg.sender, _txIndex, transaction.numConfirmations);
    }

    function cancelApprovedConfirmation(uint _txIndex)
        public
        onlyOwner
        approvedTxExists(_txIndex)
        approvedNotExecuted(_txIndex)
        confirmedBySender(_txIndex)
    {
        Transaction storage transaction = approvedTransactions[_txIndex];

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        if (transaction.numConfirmations < numConfirmationsRequired) {
            delete approvedTransactions[_txIndex];
            pendingTransactions.push(transaction);
        }

        emit CancelledConfirmation(msg.sender, _txIndex, transaction.numConfirmations);
    }

    function cancelPendingTransaction(uint _txIndex)
        public
        onlyOwner
        pendingTxExists(_txIndex)
        pendingNotExecuted(_txIndex)
    {
        delete pendingTransactions[_txIndex];

        emit CancelledTransaction(msg.sender, _txIndex);
    }

    function cancelApprovedTransaction(uint _txIndex)
        public
        onlyOwner
        approvedTxExists(_txIndex)
        approvedNotExecuted(_txIndex)
    {
        delete approvedTransactions[_txIndex];

        emit CancelledTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        approvedTxExists(_txIndex)
        approvedNotExecuted(_txIndex)
    {
        Transaction storage transaction = approvedTransactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "ERROR_NOT_CONFIRMED_TX"
        );

        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "ERROR_TX_CALL_FAIL");

        delete approvedTransactions[_txIndex];
        executedTransactions.push(transaction);

        emit ExecutedTransaction(msg.sender, _txIndex);
    }

    // INTERNAL METHODS
    function changeOwners(address[] memory _owners, uint _numConfirmationsRequired)
        public
        selfTransaction
    {   
        setOwners(_owners, _numConfirmationsRequired);
    }

    function setOwners(address[] memory _owners, uint _numConfirmationsRequired) internal {
        require(_owners.length > 0, "ERROR_OWNERS_REQUIRED");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "ERROR_INVALID_CONFIRMATIONS"
        );

        for (uint i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = false;
        }

        delete owners;

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "ERROR_INVALID_OWNER_ADDRESS");
            require(!isOwner[owner], "ERROR_ADDRESS_NOT_UNIQUE");

            isOwner[owner] = true;
        }

        owners = _owners;
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // PUBLIC METHODS
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getPendingTransactionCount() public view returns (uint) {
        return pendingTransactions.length;
    }

    function getApprovedTransactionCount() public view returns (uint) {
        return approvedTransactions.length;
    }

    // EVENTS
    event SubmitedTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        uint numConfirmations,
        bytes data
    );
    event ConfirmedTransaction(address indexed owner, uint indexed txIndex, uint indexed numConfirmations);
    event ExecutedTransaction(address indexed owner, uint indexed txIndex);
    event CancelledConfirmation(address indexed owner, uint indexed txIndex, uint indexed numConfirmations);
    event CancelledTransaction(address indexed owner, uint indexed txIndex);
}