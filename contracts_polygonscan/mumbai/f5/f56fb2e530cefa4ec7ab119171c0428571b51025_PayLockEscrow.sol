/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.5.7;

contract PayLockEscrow{
    
    enum State {AWAITING_PAYMENT, AWAITING_CONFIRMATION, AWAITING_DELIVERY, COMPLETE}
    State public currentState;
    
    modifier awaitingPaymentState() {
        require(currentState == State.AWAITING_PAYMENT);
        _;
    }
    
    modifier awaitingDeliveryState() {
        require(currentState == State.AWAITING_DELIVERY);
        _;
    }
    
    // This is to start the transaction
    function createTransaction(string memory transactionName, string memory transactionType, string memory description,
        string memory escrow_fee_payment, address payable owner, address  collaborator, string memory activity_type, 
        uint256  amount, uint256 markup) awaitingPaymentState public{
            transactionName = transactionName; 
            transactionType = transactionType;
            owner = owner; 
            description = description;
            escrow_fee_payment = escrow_fee_payment; 
            activity_type = activity_type;
            collaborator = collaborator; 
            amount = amount;  
            markup = markup;
            currentState = State.AWAITING_CONFIRMATION;
    }
    
    // When transaction is approved
    // function approveTransaction(string memory transactionName, string memory transactionType, string memory description,
    //     string memory escrow_fee_payment, address payable owner, address  collaborator, string memory activity_type, 
    //     uint256  amount, uint256 markup) awaitingPaymentState payable public{
    //         transactionName = transactionName; 
    //         transactionType = transactionType;
    //         owner = owner; 
    //         description = description;
    //         escrow_fee_payment = escrow_fee_payment; 
    //         activity_type = activity_type;
    //         collaborator = collaborator; 
    //         amount = amount;  
    //         markup = markup;
    //         currentState = State.AWAITING_DELIVERY;
    // }
    
    
    // // This is to end the transaction and funds moved to contractor.
    // function completeTransaction(string memory transactionName, string memory transactionType, string memory description,
    //     string memory escrow_fee_payment, address payable owner, address  collaborator, string memory activity_type, 
    //     uint256  amount, uint256 markup) awaitingDeliveryState public{
    //         transactionName = transactionName; 
    //         transactionType = transactionType;
    //         owner = owner; 
    //         description = description;
    //         escrow_fee_payment = escrow_fee_payment; 
    //         activity_type = activity_type;
    //         collaborator = collaborator; 
    //         amount = amount;  
    //         markup = markup;
    //         currentState = State.COMPLETE;
        
    // }
    
    // function contractBalance() public view returns(uint256){
    //     return address(this).balance;
    // }
}