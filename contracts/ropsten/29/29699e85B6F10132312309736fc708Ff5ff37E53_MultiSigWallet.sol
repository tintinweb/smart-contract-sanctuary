pragma solidity ^0.7.3;

contract MultiSigWallet {

    struct Transaction {
        uint256 txIndex;
        bool isExecuted;
        uint256 numConfirmations;
        address to;
        bytes data;
        uint value;
    }

    event Deposit(address indexed sender, uint256 value, uint256 balance);
    event SubmitTransaction(address indexed to, address indexed sender, uint256 indexed txIndex, bytes data, uint value);
    event ApproveTransaction(address indexed sender, uint256 indexed txIndex);
    event RevokeApproval(address indexed sender, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed sender, uint256 indexed txIndex);

    uint256 public _numConfirmations;
    mapping(address => bool) public isOwner;
    address[] public _owners;

    Transaction[] public transactions;
    // tx index => address => isConfirmed
    mapping (uint256 => mapping (address => bool)) public txToConfirmation;

    modifier onlyOwner() {
         require(isOwner[msg.sender]);
         _;
    }

    constructor(address[] memory owners, uint256 numConfirmations) {
        require(owners.length > 0, "cannot have no owners");
        require(numConfirmations > 0 && numConfirmations == owners.length, "Invalid num confirmations");

        _numConfirmations = numConfirmations;

        for (uint i = 0; i < owners.length; i++) {
            address owner = owners[i];
            require(owner != address(0), "Cannot be 0 address");
            require(!isOwner[owner], "Owner already exists");

            isOwner[owner] = true;
            _owners.push(owner);
        }
    }

    function deposit() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(address to, bytes memory data, uint value) external onlyOwner returns (uint256) {
        require(to != address(0), "Invalid transaction address");
        uint256 txIndex = transactions.length;

        Transaction memory transaction = Transaction({
            txIndex: txIndex,
            to: to,
            data: data,
            value: value,
            isExecuted: false,
            numConfirmations: 0
        });

        transactions.push(transaction);

        emit SubmitTransaction(to, msg.sender, txIndex, data, value);

        return txIndex;
    }

    function approveTransaction(uint256 txIndex) external onlyOwner {
        require(txIndex < transactions.length, "Invalid transaction index");
        require(!txToConfirmation[txIndex][msg.sender], "Already approved transaction");

        Transaction storage transaction = transactions[txIndex];
        require(!transaction.isExecuted, "Already executed");

        transaction.numConfirmations += 1;
        txToConfirmation[txIndex][msg.sender] = true;

        emit ApproveTransaction(msg.sender, txIndex);
    }

    function revokeApproval(uint256 txIndex) external onlyOwner {
        require(txIndex < transactions.length, "Invalid transaction index");
        require(txToConfirmation[txIndex][msg.sender], "Not approved");

        Transaction storage transaction = transactions[txIndex];
        require(!transaction.isExecuted, "Already executed");
        
        transaction.numConfirmations -= 1;
        txToConfirmation[txIndex][msg.sender] = false;

        emit RevokeApproval(msg.sender, txIndex);
    }

    function executeTransaction(uint256 txIndex) external onlyOwner {
        require(txIndex < transactions.length, "Invalid transaction index");

        Transaction storage transaction = transactions[txIndex];
        require(!transaction.isExecuted, "Already executed");
        require(transaction.numConfirmations >= _numConfirmations, "Not enough approvals");
        require(transaction.value >= address(this).balance, "Not enough balance");

        transaction.isExecuted = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit ExecuteTransaction(msg.sender, txIndex);
    }
}