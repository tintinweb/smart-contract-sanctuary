/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract MultiSigWallet{
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value, 
        bytes data
    );
    
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event Deposit(address sender,uint amount,uint balance);
    
    address[] public owners;
    mapping(address=>bool) public isOwner;
    uint public numConfirmationRequired;
    
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
        mapping(address=>bool) isConfirmed;
        uint numConfirmations;
    }
    
    Transaction [] transactions;
    
    constructor(address[] memory _owners, uint _numConfirmationsRequired) public {
        require(_owners.length>0,"Owner required");
        require(_numConfirmationsRequired>0 && _numConfirmationsRequired <= _owners.length ,"confirmation no. required");
            for(uint i=0;i< _owners.length;i++){
              address owner = _owners[i];
              
              require(owner!=address(0),"invalid owners");
              require(!isOwner[owner],"owner not unique");
              
              isOwner[owner] = true;
              owners.push(owner);
              
            }
        numConfirmationRequired = _numConfirmationsRequired;
    }
    
    modifier onlyOwner(){
        require(isOwner[msg.sender],"not allowed");
        _;
    }
    
    modifier txExists(uint _txIndex){
        require(_txIndex< transactions.length,"tx does not exist");
        _;
    }
    modifier notExecuted(uint _txIndex){
        require(!transactions[_txIndex].executed,"tx already executed");
        _;
    }
    
    modifier notConfirmed(uint _txIndex){
        require(!transactions[_txIndex].isConfirmed[msg.sender],"tx already confirmed");
    _;
    }

    
    function submitTransaction(address _to, uint _value, bytes memory _data)
    public onlyOwner
    {
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value:_value,
            data:_data,
            executed:false,
            numConfirmations: 0
        }));
        
        emit SubmitTransaction(msg.sender,txIndex,_to,_value,_data);
        
    }
    function confirmTransaction(uint _txIndex)
    public onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notConfirmed(_txIndex)
    {
     Transaction storage transaction = transactions[_txIndex];
     
     transaction.isConfirmed[msg.sender] = true;
     
     transaction.numConfirmations +=1;
     
     emit ConfirmTransaction(msg.sender,_txIndex);
     
    }
    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex){
     Transaction storage transaction = transactions[_txIndex];
     
     require(transaction.numConfirmations>= numConfirmationRequired,"cannot execute tx");
    
    transaction.executed = true;
    
    (bool success,) = transaction.to.call{value :transaction.value}(transaction.data);
    require(success,"tx failed");
    
    emit ExecuteTransaction(msg.sender,_txIndex);
    }
    function revokeConfirmation(uint _txIndex)public onlyOwner txExists(_txIndex) 
    notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        
        transaction.isConfirmed[msg.sender] = false;
        
        transaction.numConfirmations -= 1;
        
        emit RevokeConfirmation(msg.sender,_txIndex);
        
    }
    
   receive() payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
     function deposit() payable external{
        emit Deposit(msg.sender,msg.value,address(this).balance);
    }

    
}