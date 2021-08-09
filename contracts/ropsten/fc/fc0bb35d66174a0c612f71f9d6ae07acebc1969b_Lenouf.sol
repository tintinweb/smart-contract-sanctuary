/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract Lenouf {
    address private owner;
    address private addressA;
    address private addressB;
    
    mapping (address => uint256[]) private addressToPendingTransactions;

    uint256 private fee;
    
    constructor(address _addressA, address _addressB, uint256 _fee) {
        require(_fee <= 100);
        
        owner = msg.sender;
        addressA = _addressA;
        addressB = _addressB;
        fee = _fee;
    }
    
    //////////
    // Getters
    function getAccountTransactionAtIndex(address _account, uint256 _index) external view returns(uint256) {
        return(addressToPendingTransactions[_account][_index]);
    }
    
    function getAccountPendingTransactionsLength(address _account) external view returns(uint256) {
        return(addressToPendingTransactions[_account].length);
    }
    
    function getFeePercentage() external view returns(uint256) {
        return(fee);
    }

    ///////
    // Main
    
    receive() external payable {
        addTransaction();
    }
    
    function addTransaction() public payable {
        addressToPendingTransactions[msg.sender].push(msg.value);
    }
    
    function sendTransaction(uint256 _i) external {
        uint256 amount = addressToPendingTransactions[msg.sender][_i];
        
        uint256 feeAmount = amount * fee / 100;
        uint256 transferAmount = amount - feeAmount;
        
        payable(addressA).transfer(transferAmount);
        payable(addressB).transfer(feeAmount);
        
        delete addressToPendingTransactions[msg.sender][_i];
    }
    
    //////////////////
    // Owner functions
    
    function transferOwner(address _owner) external {
        require(msg.sender == owner);
        
        owner = _owner;
    }
    
    function setAddressA(address _addressA) external {
        require(msg.sender == owner);
        
        addressA = _addressA;
    }
    
    function setAddressB(address _addressB) external {
        require(msg.sender == owner);
        
        addressB = _addressB;
    }
    
    function setFeePercentage(uint256 _fee) external {
        require(msg.sender == owner);
        require(_fee <= 100);
        
        fee = _fee;
    }
}