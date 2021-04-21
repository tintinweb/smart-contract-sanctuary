// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./CoinvestingDeFiToken.sol";
import "./Ownable.sol";

contract MultiSigWallet is Ownable{
    // Types
    enum Authorization {
        NONE,
        OWNER,
        DEACTIVATED
    }

    struct Transaction {
        uint id; 
        uint amount;
        address payable to;
        address tokenContract;
        address createdBy;
        uint signatureCount;
        bool completed;
    }

    // Public variables
    CoinvestingDeFiToken public tokenContract;
    uint public constant quorum = 2;

    // Internal variables
    bool internal contractSeted = false;

    // Private variables
    uint private nextTransactionId;
    uint[] private _pendingTransactions;
    uint[] private completed;
    address private _admin;

    // Mappings
    mapping(address => Authorization) private owners;
    mapping(uint => Transaction) transactions;
    mapping(uint => mapping(address => bool)) signatures;

    // Modifiers
    modifier canContractSet() {
        require(!contractSeted, "Set contract token is not allowed!");
        _;
    }

    modifier isValidOwner() {
        require(owners[msg.sender] == Authorization.OWNER,
        "You must have owner authorization to create transaction!");
        _;
    }

    // Events
    event TransactionCreated(uint nextTransactionId, address createdBy, address to,  uint amount);
    event TransactionCompleted(uint transactionId, address to, uint amount, address createdBy, address executedBy);
    event TransactionSigned(uint transactionId, address signer);
    event NewOwnerAdded(address newOwner);
    event FundsDeposited(address from, uint amount);

    // Constructor
    constructor() payable {
        _admin = msg.sender;
        owners[msg.sender] = Authorization.OWNER;
    }

    // Receive function
    receive() external payable{
        emit FundsDeposited(msg.sender, msg.value);
    }

    // External functions
    function activateOwner(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address!");
        owners[addr] = Authorization.OWNER;
    }

    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address!");
        require(owners[newOwner] == Authorization.NONE, "Address already an owner!");
        owners[newOwner] = Authorization.OWNER;
        emit NewOwnerAdded(newOwner);
    }

    function createTransfer(uint amount, address payable to) external isValidOwner {
        nextTransactionId++;  
         
        transactions[nextTransactionId]= Transaction({
            id:nextTransactionId,
            amount: amount,
            to: to,
            tokenContract: address(tokenContract),
            createdBy: msg.sender,
            signatureCount: 0,
            completed: false
        });

        _pendingTransactions.push(nextTransactionId);
        emit TransactionCreated(nextTransactionId, msg.sender, to, amount);
    }

    function deactivateOwner(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address!");
        owners[addr] = Authorization.DEACTIVATED;
    }

    function executeTransaction(uint id) external isValidOwner {
        require(transactions[id].to != address(0),
        "Transaction does not exist!");
        require(transactions[id].completed == false,
        "Transactions has already been completed!");
        require(transactions[id].signatureCount >= quorum,
        "Transaction requires more signatures!");
        require(tokenContract.balanceOf(address(this)) >= transactions[id].amount,
        "Insufficient balance.");

        transactions[id].completed = true;
        address payable to = transactions[id].to;
        uint amount = transactions[id].amount;
        tokenContract.transfer(to, amount);
        completed.push(id);
        emit TransactionCompleted(id, to, amount, transactions[id].createdBy, msg.sender);
    }
         
    function setTokenContract(CoinvestingDeFiToken _tokenContract) external onlyOwner canContractSet {
        tokenContract = _tokenContract;
        contractSeted = true;
    }

    function signTransation(uint id) external isValidOwner {
        require(transactions[id].to != address(0),
        "Transaction does not exist!");
        require(transactions[id].createdBy != msg.sender,
        "Transaction creator cannot sign transaction!");
        require(signatures[id][msg.sender] == false,
        "Cannot sign transaction more than once!");
        
        Transaction storage transaction = transactions[id];
        signatures[id][msg.sender] = true;
        transaction.signatureCount++; 
        emit TransactionSigned(id, msg.sender);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Insuficient funds!");
        uint amount = address(this).balance;
        // sending to prevent re-entrancy attacks
        address(this).balance - amount;
        payable(msg.sender).transfer(amount);
    }

    // External functions that are view
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getPendingTransactions() external view returns(uint[] memory){
        return _pendingTransactions;
    }

    function getCompletedTransactions() public view returns(uint[] memory){
        return completed;
    }

    function getTokenBalance() external view returns(uint) {
        return tokenContract.balanceOf(address(this));
    }

    function getTransactionSignatureCount(uint transactionId) external view returns(uint) {
        require(transactions[transactionId].to != address(0),
        "Transaction does not exist!");
        return transactions[transactionId].signatureCount;
    }
}