// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import './IERC20.sol';
contract swappingEth{
    struct swappedTransaction{
        uint amount;
        uint tax;
        address sender;
        address receiver;
    }
    IERC20 public token;
    address public authorizedAccount;
    mapping(uint => swappedTransaction) transactions;
    uint totalTransactions;
    
    constructor(address _token,address _authorizedAccount){
        token = IERC20(_token);
        authorizedAccount = _authorizedAccount;
    }

    modifier onlyAuthorizedAccount(address withdrawer){
        require(authorizedAccount == withdrawer,'Only Authorized Account can submit a withdraw request');
        _;
    }
    modifier validTransaction(uint index, address transactionInitiator){
        require(index <= totalTransactions, "Invalid Transaction ID");
        _;
    }
    
    event fundingReciept(uint256 index);

    event refunded(uint256 index);

    function fund(uint _amount,uint _tax,address reciever) external payable returns(uint currentIndex){
        require(token.balanceOf(msg.sender)>= _amount,"Not Enough Balance to complete this transaction");
        // require(token.approve(address(this), _amount),"Approve Failed Try Again");
        swappedTransaction memory newTransaction = swappedTransaction(_amount,_tax,msg.sender,reciever);
        transactions[totalTransactions] = newTransaction;
        require(token.transferFrom(msg.sender,address(this),_amount),"Could not process the transaction try again");
        emit fundingReciept(totalTransactions);
        totalTransactions = totalTransactions + 1;
        return totalTransactions;
    }

    function refund(uint index) validTransaction(index,msg.sender) onlyAuthorizedAccount(msg.sender) public{
        require(token.transfer(transactions[totalTransactions].sender, transactions[totalTransactions].amount),"Transaction Failed");
        emit refunded(index);
    }
    // Removing onlyAuthorized Restriction
    function withdraw(uint _amount, address reciever) onlyAuthorizedAccount(msg.sender) public{
        token.transfer(reciever, _amount);
    }

    function getCurrentIndex() external view returns (uint256 index){
        return totalTransactions;        
    }
    // works fine
    function withDrawTax(address payable to) onlyAuthorizedAccount(msg.sender) public{
        to.transfer(address(this).balance);
    }
    // Withdraws xDNA FUNCTIOn
    function withDrawxDNA(address to,uint256 amount) onlyAuthorizedAccount(msg.sender) public{
       require(token.transfer(to, amount),"TRANSACTION FAILED WHEN TRANSFERING XDNA");
    }

    function getTransaction(uint index) external view returns (swappedTransaction memory transaction){
        require(index >= 0 && index <= totalTransactions,"Invalid Index");
        return transactions[index];        
    }
}