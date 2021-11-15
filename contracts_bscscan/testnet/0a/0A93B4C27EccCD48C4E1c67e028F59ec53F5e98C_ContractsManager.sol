// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.6;

contract ContractsManager {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    Transaction[] public transactions;

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public transactionsConfirmed;

    // MODIFIERS
    modifier onlyOwner() {
        require(isOwner[msg.sender], "ERROR_NOT_OWNER");
        _;
    }
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "ERROR_TX_DOES_NOT_EXISTS");
        _;
    }
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "ERROR_TX_ALREADY_EXECUTED");
        _;
    }
    modifier notCancelled(uint _txIndex) {
        require(!transactions[_txIndex].cancelled, "ERROR_TX_ALREADY_CANCELLED");
        _;
    }
    modifier notConfirmedBySender(uint _txIndex) {
        require(!transactionsConfirmed[_txIndex][msg.sender], "ERROR_TX_ALTREADY_CONFIRMED");
        _;
    }
    modifier confirmedBySender(uint _txIndex) {
        require(transactionsConfirmed[_txIndex][msg.sender], "ERROR_TX_NOT_CONFIRMED_WITH_THIS_ADDRESS");
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
        bool cancelled;
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
        uint txIndex = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            cancelled: false,
            numConfirmations: 1
        }));

        transactionsConfirmed[txIndex][msg.sender] = true;

        emit SubmitedTransaction(msg.sender, txIndex, _to, _value, 1, _data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notCancelled(_txIndex)
        notConfirmedBySender(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        transactionsConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmedTransaction(msg.sender, _txIndex, transaction.numConfirmations);
    }

    function cancelConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notCancelled(_txIndex)
        confirmedBySender(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        transaction.numConfirmations -= 1;
        transactionsConfirmed[_txIndex][msg.sender] = false;

        emit CancelledConfirmation(msg.sender, _txIndex, transaction.numConfirmations);
    }

    function cancelTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notCancelled(_txIndex)
    {
        transactions[_txIndex].cancelled = true;

        emit CancelledTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notCancelled(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "ERROR_NOT_CONFIRMED_TX"
        );

        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "ERROR_TX_CALL_FAIL");

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

    function getTransactionsCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransactions() public view returns (Transaction[] memory) {
        return transactions;
    }
    
    function getIsTransactionConfirmed(uint _txIndex, address _owner) public view returns (bool) {
        return transactionsConfirmed[_txIndex][_owner];
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

