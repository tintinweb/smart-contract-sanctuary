/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract escrowService{
    
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }
    
    uint public contractLiabilities;
        
    struct transaction_details{
        State state;
        address payable seller_address;
        uint transaction_value_in_ether;
    }
    mapping(address => transaction_details) transactions;

    
    
    function newTransaction(address payable sellerAddress) external payable {
        require(msg.value > 0, "Transaction value must be larger than zero");
        require(sellerAddress != payable(0), "Seller address must be given");
        require(transactions[msg.sender].seller_address == payable(0), "This address already has a transaction pending");
        transactions[msg.sender] = transaction_details(State.AWAITING_DELIVERY, sellerAddress, msg.value);
        contractLiabilities = contractLiabilities + msg.value;
    }
    
    function confirmDelivery() external{
        require(transactions[msg.sender].state == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        transactions[msg.sender].seller_address.transfer(transactions[msg.sender].transaction_value_in_ether);
        contractLiabilities = contractLiabilities - transactions[msg.sender].transaction_value_in_ether;
        transactions[msg.sender].state = State.COMPLETE;
        transactions[msg.sender].seller_address = payable(0);
        
        
    }
    
    function getContractBalance() public view returns(uint){
     return address(this).balance;
    }
    
    function getTransaction(address fetchAddress) public view returns(uint, address) {
        if (transactions[fetchAddress].state == State.AWAITING_DELIVERY) {
            return (transactions[fetchAddress].transaction_value_in_ether, transactions[fetchAddress].seller_address);
        }else{
            return (0, address(0));
        }
    }
    
    receive() external payable{
       
    }
}