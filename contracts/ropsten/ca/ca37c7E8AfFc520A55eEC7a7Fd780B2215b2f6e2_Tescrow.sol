/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Tescrow {

    // Initialising variables
    address payable public buyer;
    address payable public seller;
    address payable contractOwner;

    uint256 buyerDepositTimeStamp;
    uint256 sellerAcceptedTimeStamp;
    uint256 completedTimeStamp;

    bool feePaid = false;

    // Create an enum which defines what states the contract can be in
    enum contractState{AWAITING_PARTIES,AWAITING_BUYER_PAYMENT,AWAITNG_SELLER_ACCEPTANCE,AWAITING_BUYER_SATISFACTION,COMPLETED}

    // Initial state of contract
    contractState public state = contractState.AWAITING_PARTIES;

    // Notification to the sender
    event notify(string notification);

    // AWAITING_PARTIES
    // AWAITING_BUYER_PAYMENT
    // AWAITING_SELLER_ACCEPTANCE
    // AWAITING_BUYER_SATISFACTION
    // COMPLETED

    constructor() {

        // Set contract owner when deployed to blockchain
        contractOwner = payable(msg.sender);
    }

    // Define parties within contract
    function set_parties(address payable _seller, address payable _buyer) public {
        
        // Check contract is in initial state
        require(state==contractState.AWAITING_PARTIES,'Parties have already been defined within this contract');
        
        // Only define parties if both parties have been input
        if(_seller != address(0) || buyer == address(0)) {

            // Define seller and buyer
            seller = _seller;
            buyer = _buyer;

            // Update contract state
            state = contractState.AWAITING_BUYER_PAYMENT;

            emit notify('Both parties have now been added to the contract');

        } else {
            revert();
        }

    }

    // Buyer sets contract value by depositing ether
    function buyer_deposit() external payable {

        // Check it is the defined buyer depositing ether
        require(msg.sender == buyer,'For the buyer only');
        // Check contract is in state where buyer must deposit ether
        require(state == contractState.AWAITING_BUYER_PAYMENT,'Only avaiable when buyer has been defined and funds have not yet been deposited within this contract');
        // Check amount deposited is not negative
        require(msg.value > 0);
        
        // Change state to awaiting seller decision
        state = contractState.AWAITNG_SELLER_ACCEPTANCE;

        // Set deposit timestamp
        buyerDepositTimeStamp = block.timestamp;

        // Notify Sender
        emit notify('Deposit has been sent to the contract');
    }

    // Allows seller to either accept or rejected the contract
    function seller_accept(bool _accept) public {
        
        // Check it is defined seller making contract decision
        require(msg.sender == seller, 'Only the seller can accept or decline this contract');
        // Check state of contract is awaiting seller decision
        require(state == contractState.AWAITNG_SELLER_ACCEPTANCE, 'This contract has already been accepted or rejected');

        // Checks if contract has been accepted by seller
        if(this.isBool(_accept)) {

            // Set state to now waiting for the buyer to satisfy the contract
            state = contractState.AWAITING_BUYER_SATISFACTION;

            // Set timestamp of when seller accepted contract
            sellerAcceptedTimeStamp = block.number;

            // Notify Sender
            emit notify('Contract has been accepted');

            // Transfer service charge to the contract owner
            this.sendFee();

        } else {

            // Return funds from contract back to the buyer if contract is rejected
            buyer.transfer(address(this).balance);

            // Set contract to completed
            state = contractState.COMPLETED;

            // Notify Sender
            emit notify('Contract has been rejected');

        }

    }

    // Function is runnable after 3 minutes after buyer transfers deposit, allows buyer
    // to cancel contract if seller never accepts
    function buyer_cancel(bool _cancel) public {

        // Check it is the defined buyer cancelling contract
        require(msg.sender == buyer,'Only the buyer can cancel the contract');
        // Check state of contract is awaiting seller acceptance
        require(state == contractState.AWAITNG_SELLER_ACCEPTANCE,'Seller has already made a decision on the contract');
        // Check minimum amount of time has passed
        require((block.timestamp-buyerDepositTimeStamp) > 3 minutes, 'Not enough time has passed for the buyer to cancel the contract, please wait 3 minutes from the time when you initially deposited the funds');

        // Check if buyer wishes to cancel contract
        if(this.isBool(_cancel)) {

            // Return funds from contract back to the buyer if contract is rejected
            buyer.transfer(address(this).balance);

            // Sets state of contract as complete
            state = contractState.COMPLETED;

            // Notify sender
            emit notify('Contract has been cancelled buy buyer after minimum time limit to accept contract has passed');

        } else {

            // Notify sender
            emit notify('Contract has not been cancelled');

        }

    }   

    // Calculates and sends fee to contract owner
    function sendFee() external {
        
        // Check contract has been accepted
        require(state == contractState.AWAITING_BUYER_SATISFACTION);
        // Check fee has not already been paid;
        require(feePaid == false);

        // Define service charge for contract in percent
        uint256 serviceCharge = 4;
        // Get 4% of the value of the contract
        uint256 fee = (address(this).balance / 100) * serviceCharge;

        // Transfer fee to contractOwner;
        contractOwner.transfer(fee);

        // Confirm in contract fee has been paid
        feePaid = true;
        
    }

    // Simple function to check if a bool is true
    function isBool(bool check) public pure returns(bool) {
        if (check) return true;
        else return false;
    }

    // Gets current value of contract
    function contract_balance() public view returns (uint256) {
        return address(this).balance;
    }

}