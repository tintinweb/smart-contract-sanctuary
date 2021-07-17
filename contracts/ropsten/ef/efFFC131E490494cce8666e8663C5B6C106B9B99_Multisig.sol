//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


/// @title Multisignature wallet that allows multiple users to agree on a transaction before executing it.
/// @author Pavol Karas
contract Multisig {

  uint8 public minNumOfSignatures;
  uint8 public ownersCount;

  mapping(address => bool) private isOwner;
  // keeps track of which txId was confirmed by which owner
  mapping(uint256 => mapping(address => bool)) public isConfirmed;

  struct Transaction{
    address payable to;
    uint256 value;
    uint8 numOfSignatures;
    bool executed;
    bytes data;
  }

  Transaction[] public transactions;

  event Deposit(address indexed from, uint256 amount, uint256 balance);
  event TransactionCreated(
    address indexed owner,
    uint256 indexed txId,
    address to,
    uint256 value,
    bytes data
  );
  event TransactionConfirmed(address indexed owner, uint256 indexed txId);
  event TransactionRevoked(address indexed owner, uint256 indexed txId);
  event TransactionExecuted(address indexed owner, uint256 indexed txId);
  event SignatureRequirementChanged(address indexed owner, uint8 newNumOfSignatures);

  /// @notice Contruct constructor stores minNumOfSignatures and checks for duplicate/null address owners
  /// @param _minNumOfSignatures Minimal number of signatures required for a transaction to be executed.
  /// @param _owners Array of owner addresses able to create, confirm, reject or execute transactions.
  constructor(uint8 _minNumOfSignatures, address[] memory _owners) {
    // validate number of owners and min num of signatures
    require(_minNumOfSignatures > 1, "min number of signatures must be more than 1");
    require(_owners.length >= _minNumOfSignatures, "numer of owners must be more/equal than min num of signatures");


    // specify min number of signatories -> minNumOfSignatures
    minNumOfSignatures = _minNumOfSignatures;

    // specify which addresses are owners of this multisig contract -> owners mapping
    for (uint256 i = 0; i < _owners.length; i++) {
      address owner = _owners[i];

      require(owner != address(0), "invalid owner address");
      require(!isOwner[owner], "can't have duplicate owners");

      isOwner[owner] = true;
      ownersCount++;
    }
  }

  modifier onlyOwner() {
    require(isOwner[msg.sender], "this function can be called by one of contract owners");
    _;
  }

  modifier transactionNotConfirmed(uint256 _txId) {
    require(!isConfirmed[_txId][msg.sender], "transaction is already confirmed");
    _;
  }

  modifier transactionNotExecuted(uint256 _txId) {
    require(!_isTxExecuted(_txId), "transaction is already executed");
    _;
  }

  modifier transactionExists(uint256 _txId) {
    require(_txId < getTransactionsLength(), "transaction does not exist");
    _;
  }

  modifier transactionConfirmed(uint256 _txId) {
    require(isConfirmed[_txId][msg.sender], "you have not confirmed this transaction yet");
    _;
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value, address(this).balance);
  }

  /// @notice Function to create a transaction for confirmation. Can be called only by contract owners
  /// @param _to Address where the transaction should be sent 
  /// @param _amount Amount of Ether (in Wei) that should be included in the transaction
  /// @param _data Transaction data that should be sent with the transaction
  /// @dev Transaction data can be used to call other contracts
  function createTransaction(address _to, uint256 _amount, bytes memory _data) public onlyOwner {
    // msg.sender would want to confirm this tx => numOfSignatures: 1
    transactions.push(Transaction({
      to: payable(_to),
      value: _amount,
      data: _data,
      executed: false,
      numOfSignatures: 1
    }));

    // create a transaction ID that will be used to identify the tx for signing
    uint256 txId = transactions.length - 1;
    // don't forget to set the tx as confirmed by msg.sender
    isConfirmed[txId][msg.sender] = true;

    emit TransactionCreated(msg.sender, txId, _to, _amount, _data);
  }

  /// @notice Function to confirm a transaction for execution
  /// @param _txId ID of the transaction you want to confirm 
  function confirmTransaction(uint256 _txId)
    public
    onlyOwner
    transactionExists(_txId)
    transactionNotConfirmed(_txId)
    transactionNotExecuted(_txId)
  {
    transactions[_txId].numOfSignatures++;
    isConfirmed[_txId][msg.sender] = true;
    emit TransactionConfirmed(msg.sender, _txId);
  }

  /// @notice Function to revoke a confirmation of a transaction
  /// @param _txId ID of the transaction you want to confirm 
  function revokeTransaction(uint256 _txId)
    public
    onlyOwner
    transactionExists(_txId)
    transactionConfirmed(_txId)
    transactionNotExecuted(_txId)
  {
    transactions[_txId].numOfSignatures--;
    isConfirmed[_txId][msg.sender] = false;
    emit TransactionRevoked(msg.sender, _txId);
  }

  /// @notice Function to execute transaction with enough confirmations
  /// @param _txId ID of the transaction you want to confirm 
  /// @dev The amount of ETH in contract must be enough to execute this transaction, otherwise the execution will fail 
  function executeTransaction(uint256 _txId) 
    public
    onlyOwner
    transactionExists(_txId)
    transactionNotExecuted(_txId)
  {
    Transaction storage transaction = transactions[_txId];

    require(transaction.numOfSignatures >= minNumOfSignatures, "transaction does not have enough signatures");

    transaction.executed = true;

    (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "transaction execution has failed");

    emit TransactionExecuted(msg.sender, _txId);
  }

  function changeSignatureRequirement(uint8 _newNumOfSignatures) public onlyOwner {
    require(_newNumOfSignatures > 1, "min number of signatures must be more than 1");
    require(ownersCount >= _newNumOfSignatures, "numer of owners must be more/equal than min num of signatures");
    require(
      _newNumOfSignatures != minNumOfSignatures,
      "new number of signatures is equal to current min num of signatures"
    );


    minNumOfSignatures = _newNumOfSignatures;
    emit SignatureRequirementChanged(msg.sender, _newNumOfSignatures);
  }

  /// @notice Returns the number of transactions, that were created in the contract
  /// @dev Can be used to get the ID of the latest tx (transactions.length - 1)
  /// @return Number of transactions created
  function getTransactionsLength() public view returns (uint256) {
    return transactions.length;
  }

  /// @dev _isTxExecuted exists only so that I can override it in tests
  function _isTxExecuted(uint256 _txId) internal view virtual returns (bool) {
    return transactions[_txId].executed;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}