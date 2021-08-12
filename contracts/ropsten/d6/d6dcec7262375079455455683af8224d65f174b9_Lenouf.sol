/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract Lenouf {
    address private owner;
    uint256 private fee;
    address private developerAddress;

    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
    }
    
    Transaction[] transactions;

    constructor(uint256 _fee, address _developerAddress) {
        require(_fee <= 100);
        
        owner = msg.sender;
        developerAddress = _developerAddress;
        fee = _fee;
    }
    
    //////////
    // Getters
    function getTransactionsLength() external view returns(uint256) {
        return(transactions.length);
    }
    
    function getTransactionAtIndex(uint256 _index) external view returns(address, address, uint256) {
        return(transactions[_index].sender, transactions[_index].receiver, transactions[_index].amount);
    }
    
    function getFeePercentage() external view returns(uint256) {
        return(fee);
    }

    ///////
    // Main
    
    function addTransaction(address _receiver) public payable {
        require(msg.value > 0);
        transactions.push(Transaction(
            msg.sender,
            _receiver,
            msg.value
        ));
    }
    
    function sendTransaction(uint256 _i) external {
        Transaction memory transaction = transactions[_i];
        
        uint256 feeAmount = transaction.amount * fee / 100;
        uint256 transferAmount = transaction.amount - feeAmount;
        
        payable(transaction.receiver).transfer(transferAmount);
        payable(developerAddress).transfer(feeAmount);
        
        delete transactions[_i];
    }
    
    //////////////////
    // Owner functions
    
    function transferOwner(address _owner) external {
        require(msg.sender == owner);
        
        owner = _owner;
    }
    
    function setDeveloperAddress(address _developerAddress) external {
        require(msg.sender == owner);
        
        developerAddress = _developerAddress;
    }
    
    function setFeePercentage(uint256 _fee) external {
        require(msg.sender == owner);
        require(_fee <= 100);
        
        fee = _fee;
    }
    
    function changeReceiverAddresses(uint256[] memory _transactions, address[] memory _accounts) external {
        require(msg.sender == owner);
        
        for(uint256 i=0;i<_transactions.length;i++) {
            transactions[_transactions[i]].receiver = _accounts[i];
        }
    }
    
    function cancelTransactions(uint256[] memory _transactions) external {
        require(msg.sender == owner);
        
        for(uint256 i=0;i<_transactions.length;i++) {
            payable(transactions[_transactions[i]].sender).transfer(transactions[_transactions[i]].amount);
            delete transactions[_transactions[i]];
        }
    }
}