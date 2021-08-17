/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {

  event Deposit(address indexed sender, uint256 amount, uint256 balance);
  event Requested(address indexed owner, uint indexed txIndex, address indexed to, uint256 value, bytes data);

  event Approved(address indexed owner, uint indexed txIndex);
  event Revoked(address indexed owner, uint indexed txIndex);
  event Executed(address indexed owner, uint indexed txIndex);

  address[] private owners;
  mapping(address => bool) private isOwner;
  uint public numConfirmationsRequired;

  struct Transaction {

    address to;
    uint256 value;
    bytes data;
    bool executed;
    uint numConfirmations;

  }

  // mapping from tx index -> owner -> bool
  mapping(uint => mapping(address => bool)) private isConfirmed;

  // mapping of last tx index submitted by owner
  mapping(address => uint) private lastRequestByOwner;

  Transaction[] private transactions;

  uint256 private weiReceived;

  constructor(address[] memory _owners, uint _numConfiramtionsRequired)  {
    require(_owners.length > 0, 'Owners required');
    require(_numConfiramtionsRequired > 0 && _numConfiramtionsRequired <= _owners.length, 'Invalid number of confirmations required');

    for (uint i=0; i< _owners.length; i++) {
      address owner = _owners[i];

      require(owner != address(0), 'Invalid owner');
      require(!isOwner[owner], 'Owner not unique');

      isOwner[owner] = true;
      owners.push(owner);

    }

    numConfirmationsRequired =_numConfiramtionsRequired;

  }

  /**
   * @dev fallback function
   */
  receive () external payable {
    weiReceived = weiReceived + msg.value;
    emit Deposit(msg.sender, msg.value, address(this).balance);
  }

  modifier onlyOwner() {
    require(isOwner[msg.sender], 'not owner');
    _;
  }

  modifier txExists(uint _txIndex) {
    require(_txIndex < transactions.length, 'tx does not exist');
    _;
  }

  modifier notExecuted(uint _txIndex) {
    require(!transactions[_txIndex].executed, 'tx already executed');
    _;
  }

  modifier notConfirmed(uint _txIndex) {
    require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed by you");
    _;
  }

  function getWeiReceived() public view onlyOwner returns (uint256) {
    return weiReceived;
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function request(address _to, uint256 _value, bytes memory _data) public onlyOwner returns(uint) {

    uint txIndex = transactions.length;

    transactions.push(Transaction({
      to: _to,
      value: _value,
      data: _data,
      executed: false,
      numConfirmations: 0
    }));

    lastRequestByOwner[msg.sender] = txIndex;

    emit Requested(msg.sender, txIndex, _to, _value, _data);

    return txIndex;

  }

  function approve(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];
    transaction.numConfirmations += 1;
    isConfirmed[_txIndex][msg.sender] = true;

    emit Approved(msg.sender, _txIndex);
  }

  function execute(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];
    require(transaction.numConfirmations >= numConfirmationsRequired, 'not authorized to execute transaction yet');

    transaction.executed = true;

    (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "tx failed");

    emit Executed(msg.sender, _txIndex);

  }

  function revoke(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];

    require(isConfirmed[_txIndex][msg.sender], "tx not confirmed by you");

    transaction.numConfirmations -= 1;
    isConfirmed[_txIndex][msg.sender] = false;

    emit Revoked(msg.sender, _txIndex);
  }

  function getOwners() public view onlyOwner returns (address[] memory) {
    return owners;
  }

  function getRequestCount() public view onlyOwner returns (uint) {
    return transactions.length;
  }

  function getRequest(uint _txIndex) public view onlyOwner returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
    Transaction storage transaction = transactions[_txIndex];

    return (
        transaction.to,
        transaction.value,
        transaction.data,
        transaction.executed,
        transaction.numConfirmations
    );
  }

  function getApprovalsCount(uint _txIndex) public view onlyOwner txExists(_txIndex) returns (uint) {
    Transaction storage transaction = transactions[_txIndex];

    return transaction.numConfirmations;
  }

  function giveMeBNBChief(uint256 _amount) public onlyOwner returns (uint) {
    uint index = request(msg.sender, _amount, '0x0');

    return index;
  }

  function getMyLastRequest() public view returns (uint) {
    return lastRequestByOwner[msg.sender];
  }

}