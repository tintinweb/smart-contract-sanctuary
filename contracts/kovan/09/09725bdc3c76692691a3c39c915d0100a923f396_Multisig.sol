/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source : https://www.youtube.com/watch?v=Dh7r6Ze-0Bs
// ["0x3841cE901b6d8bD32416127D81F355B57E4Bb4F2","0xAfC990F8ed7A866A8e3C0a01454602309B03E603","0x88d6484f83827393C4a9846E59Ec79bF81953eF9"]
// 0xc6F027f37DBD7c4984B52E959D1f4Ee973d4de54

contract Multisig{
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    
    address[] public owner;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }
    
    Transaction[] public transactions;
    
    mapping(uint => mapping(address => bool)) public isConfirmed;
    
    constructor(address[] memory _owners, uint _numConfirmationsRequired) public{
        require(_owners.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");
        for(uint i = 0; i < _owners.length; i++){
            address owner = _owners[i];
            
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");
            
            isOwner[owner] = true;
        }
    }
    
    function deposit() payable external{
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    modifier onlyOwner(){
        require(isOwner[msg.sender],"not owner");
        _;
    }
    
    function submitTransaction(address _to, uint _value, bytes memory _data)
        public
        onlyOwner
    {
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations:0
        }));
        
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }
    
    modifier txExists(uint _txIndex){
        require(_txIndex < transactions.length, "tx doeas not exist");
        _;
    }
    
    modifier notExecuted(uint _txIndex){
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    
    modifier notConfirmed(uint _txIndex){
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
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
        
        emit ConfirmTransaction(msg.sender, _txIndex);
    }
    
    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success,"tx failed");
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }
    
    function revokeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;
        
        emit RevokeTransaction(msg.sender, _txIndex);
    }
    
}