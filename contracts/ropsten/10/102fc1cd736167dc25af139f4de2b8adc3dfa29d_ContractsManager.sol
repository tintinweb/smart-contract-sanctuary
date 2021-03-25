/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.2;

contract ContractsManager {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    Transaction[] public transactions;
    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

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
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "ERROR_TX_ALTREADY_CONFIRMED");
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
        uint txIndex = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 1
        }));

        isConfirmed[txIndex][msg.sender] = true;

        emit SubmitedTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmedTransaction(msg.sender, _txIndex);
    }

    function cancelConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "ERROR_TX_NOT_CONFIRMED_WITH_THIS_ADDRESS");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit CancelledConfirmation(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "ERROR_NOT_CONFIRMED_TX"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "ERROR_TX_CALL_FAIL");

        emit ExecutedTransaction(msg.sender, _txIndex);
    }

    // INTERNAL METHODS
    function changeOwner(address[] memory _owners, uint _numConfirmationsRequired)
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

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "ERROR_INVALID_OWNER_ADDRESS");
            require(!isOwner[owner], "ERROR_ADDRESS_NOT_UNIQUE");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // PUBLIC METHODS
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations)
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    // EVENTS
    event SubmitedTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmedTransaction(address indexed owner, uint indexed txIndex);
    event ExecutedTransaction(address indexed owner, uint indexed txIndex);
    event CancelledConfirmation(address indexed owner, uint indexed txIndex);
}