/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity ^0.8.1;

//SPDX-License-Identifier: None
contract MultiSigWallet {

    address public _owner;
    mapping(address => uint8) public _owners;

    uint constant MIN_SIGNATURES = 2;
    uint private _transactionIdx;

    struct Transaction {
      address from;
      address payable to;
      uint amount;
      uint8 signatureCount;
      bool isActive;
    }

    mapping (uint => Transaction) public _transactions;
    mapping (uint => mapping (address => uint8)) public signatures;
    
    uint[] private _pendingTransactions;
    uint public pendingTxCnt;
    uint public totalTxCnt;
    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier validOwner() {
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        _;
    }

    event DepositFunds(address from, uint amount);
    event TransactionCreated(address from, address to, uint amount, uint transactionId);
    event TransactionCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionSigned(address by, uint transactionId);

    constructor() {
        _owner = msg.sender;
    }

    function addOwner(address owner)
        isOwner
        public {
        _owners[owner] = 1;
    }

    function removeOwner(address owner)
        isOwner
        public {
        _owners[owner] = 0;
    }

    receive() external payable {
        emit DepositFunds(msg.sender, msg.value);
    }

    function withdraw(uint amount,address payable to)
        public {
        transferTo(to, amount);
    }

    function transferTo(address payable to, uint amount)
        validOwner
        public {
        require(address(this).balance >= amount);
        uint transactionId = _transactionIdx++;

        
        _transactions[transactionId] = Transaction(msg.sender,to,amount,0,true);
        totalTxCnt++;
        pendingTxCnt++;
        emit TransactionCreated(msg.sender, to, amount, transactionId);
    }

    function getPendingTransactions()
      view
      validOwner
      public
      returns (address [] memory, address [] memory, uint [] memory, uint [] memory) {
          address[] memory fromAddress = new address[](pendingTxCnt);
          address[] memory toAddress = new address[](pendingTxCnt);
          uint[] memory userAmount = new uint[](pendingTxCnt);
          uint[] memory userSignatureCount = new uint[](pendingTxCnt);
          
          for(uint i = 0; i < totalTxCnt; i++){
           if(_transactions[i].isActive==true){
                fromAddress[i] = _transactions[i].from;
                toAddress[i] = _transactions[i].to;
                userAmount[i] = _transactions[i].amount;
                userSignatureCount[i] = _transactions[i].signatureCount;
            }
          }
        return (fromAddress, toAddress, userAmount, userSignatureCount);
    }

    function signTransaction(uint transactionId)
      validOwner
      public {

      Transaction storage transaction = _transactions[transactionId];

      // Transaction must exist
      require(address(0x0) != transaction.from);
      // Creator cannot sign the transaction
      require(msg.sender != transaction.from);
      // Cannot sign a transaction more than once
      require(signatures[transactionId][msg.sender] != 1);

      signatures[transactionId][msg.sender] = 1;
      transaction.signatureCount++;

      emit TransactionSigned(msg.sender, transactionId);

      if (transaction.signatureCount >= MIN_SIGNATURES) {
        require(address(this).balance >= transaction.amount);
        transaction.to.transfer(transaction.amount);
       emit  TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
        deleteTransaction(transactionId);
      }
    }

    function deleteTransaction(uint transactionId)
      validOwner
      public {
     _transactions[transactionId].isActive = false;
     pendingTxCnt--;
    }

    function walletBalance()
      public 
      view
      returns (uint) {
      return address(this).balance;
    }
}