/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.1;

contract MWallet {
    
    struct Transaction {
        uint timestamp;
        uint holdTime;
        uint streamEndTime;
        address[] signatures; 
        uint amount;
        uint paydAmount;
        bool revoke;
        address funder;
        uint signTime;
    }
    
    mapping(address => Transaction) public transactions;
    mapping(address => bool) public owners;
    uint public numConfirmationsRequired;


    modifier isOwner() {
        require(owners[msg.sender], "not owner");
        _;
    }
    
    
    constructor(address[] memory new_owners, uint new_numConfirmationsRequired) {
        require(new_owners.length > 0, "owners required");
        require(
            new_numConfirmationsRequired > 0 &&
                new_numConfirmationsRequired <= new_owners.length,
            "invalid number of required confirmations"
        );
        for (uint i = 0; i < new_owners.length; i++) {
            address owner = new_owners[i];

            require(owner != address(0), "invalid owner");
            require(!owners[owner], "owner not unique");

            owners[owner] = true;
        }
        numConfirmationsRequired = new_numConfirmationsRequired;
    }
    
    // block.timestamp + holdTime + streamTime
    function make_transaction (address recipient, uint holdTime, uint streamTime) isOwner external payable {
        require(transactions[recipient].amount == 0, 'recipient already exist');
        address[]memory signatures;
        transactions[recipient] = (Transaction(block.timestamp, holdTime, streamTime, signatures, msg.value, 0, false, msg.sender, 0));
        transactions[recipient].signatures.push(msg.sender); 
    }


    function sign (address recipient) isOwner external {
        require(transactions[recipient].signatures.length < numConfirmationsRequired, 'already signed');
        require(transactions[recipient].signatures[0] != msg.sender, 'you already signed');
        transactions[recipient].signatures.push(msg.sender);
        if (transactions[recipient].signatures.length == numConfirmationsRequired){
            transactions[recipient].signTime = block.timestamp;
        }
    }
    
    
    function is_signed(address recipient) external view returns (bool){
        return (transactions[recipient].signTime != 0);
    }
    
    function get_num_of_signs(address recipient) external view returns (uint){
        return transactions[recipient].signatures.length;
    }
    
    function revoke (address recipient) isOwner external {
        require(transactions[recipient].signTime < numConfirmationsRequired, 'transaction already approved');
        transactions[recipient].revoke = true;
        payable(transactions[recipient].funder).transfer(transactions[recipient].amount);
    }
    
    
    function get_transaction_info (address recipient) view external returns (Transaction memory) {
        return transactions[recipient];
    }
    
    
    function get_my_balance_info () view external returns (uint){
        require (transactions[msg.sender].amount > 0, 'reccord not found');
        require (transactions[msg.sender].signTime > 0, 'your transaction is not signed');
        
        uint signTime = transactions[msg.sender].signTime;
        uint holdTime = signTime + transactions[msg.sender].holdTime;
        uint streamEndTime = holdTime + transactions[msg.sender].streamEndTime;
        
        require (holdTime < block.timestamp, 'too early');
        
        if (streamEndTime > block.timestamp){
            uint per_sec = transactions[msg.sender].amount/(streamEndTime - holdTime);
            uint till_now = transactions[msg.sender].amount - ((streamEndTime - block.timestamp)*per_sec);
            return (till_now - transactions[msg.sender].paydAmount);
            //if stream time is end
        }else{
            return (transactions[msg.sender].amount - transactions[msg.sender].paydAmount);
        }
    }
    
    
    function withdraw (uint amount) external {
        uint balance;
        require (transactions[msg.sender].amount > 0, 'reccord not found');
        require (transactions[msg.sender].signTime > 0, 'your transaction is not signed');
        
        uint signTime = transactions[msg.sender].signTime;
        uint holdTime = signTime + transactions[msg.sender].holdTime;
        uint streamEndTime = holdTime + transactions[msg.sender].streamEndTime;
        
        require (holdTime < block.timestamp, 'too early');
        
        if (streamEndTime > block.timestamp){
            uint per_sec = transactions[msg.sender].amount/(streamEndTime - holdTime);
            uint till_now = transactions[msg.sender].amount - ((streamEndTime - block.timestamp)*per_sec);
            balance = (till_now - transactions[msg.sender].paydAmount);
            //if stream time is end
        }else{
            balance = (transactions[msg.sender].amount - transactions[msg.sender].paydAmount);
        }
        
        require(amount <= balance, 'amount is bigger than balance');
        
        transactions[msg.sender].paydAmount = transactions[msg.sender].paydAmount + amount;
        payable(msg.sender).transfer(amount);
    }
    
}