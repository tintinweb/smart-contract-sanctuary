/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract DoubleSig {
    struct PendingTransfer {
        address address_to;
        uint amount;
        address first_approver;
        bool is_paid;
    }
    
    PendingTransfer[] public pending_transfer;
    address public owner1;
    address public owner2;
    
    
    constructor (address owner1_, address owner2_) public {
        owner1 = owner1_;
        owner2 = owner2_;
    }
    
    function deposit() external payable{}

    function initiate(address to, uint amount) external returns (uint id){
        require(msg.sender == owner1 || msg.sender == owner2 , "caller must be an owner of the system.");
        
        PendingTransfer memory transfer_txn;
        transfer_txn.address_to = to;
        transfer_txn.amount = amount;
        transfer_txn.first_approver = msg.sender;
        transfer_txn.is_paid = false;
        pending_transfer.push(transfer_txn);
        
        return pending_transfer.length-1;
    }
    
    function approve(uint initiate_id) external {
        require(msg.sender == owner1 || msg.sender == owner2 , "caller must be an owner of the system.");
        require(initiate_id < pending_transfer.length, "invalid id");
        require(!pending_transfer[initiate_id].is_paid, "This request has been paid");
        
        PendingTransfer memory transfer_txn = pending_transfer[initiate_id];
        uint amount = transfer_txn.amount;
        address payable address_to = payable(transfer_txn.address_to);
        require(msg.sender != transfer_txn.first_approver, "this owner already approved it");
        
        address_to.transfer(amount);
        pending_transfer[initiate_id].is_paid = true;
    }
}