/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {

    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner,uint indexed txIndex);
    event ExecuteTransaction(address indexed owner,uint indexed txIndex);
    event RevokeConfirmation(address indexed owner,uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    mapping(uint => mapping(address => bool)) isConfirmed;

    Transaction[] public transactions;

    constructor(address[] memory _owners,uint _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners requires");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "Invalid number of owners"
        );

        for(uint i = 0; i < owners.length ; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid Owner");
            require(!isOwner[owner],"Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender],"Not Owner");
        _;
    }

    modifier txExist(uint _txIndex) {
        require(_txIndex < transactions.length,"Tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed,"Tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender],"Tx already confirmed");
        _;
    }

    function submitTrasaction(address _to, uint _value, bytes memory _data)
        public 
        onlyOwner 
    {
        uint txIndex = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex)
        public 
        onlyOwner
        txExist(_txIndex) 
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        isConfirmed[_txIndex][msg.sender] = true;
        transaction.numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public 
        onlyOwner 
        txExist(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Cannot Execute Transaction"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        require(success, "Tx Faild");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeTransaction(uint _txIndex)
        public 
        onlyOwner
        txExist(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender],"Tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns(address[] memory) {
        return owners;
    }

}