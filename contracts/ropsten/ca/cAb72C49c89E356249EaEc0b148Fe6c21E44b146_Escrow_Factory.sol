/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Create an enum which defines what states the contract can be in
enum contractState{AWAITING_BUYER_PAYMENT,AWAITNG_SELLER_ACCEPTANCE,AWAITING_BUYER_SATISFACTION,COMPLETE,CANCELLED}

contract Escrow_Factory {

    // Allows a notification to the user
    event notify(string message);

    // Initialise global variables
    address payable public factoryOwner;
    uint256 fee;
    mapping(uint256 => Escrow) public escrows;

    constructor() {
        factoryOwner = payable(msg.sender);

        // default fee in percent
        fee = 4;
    }

    // Modifier for a function that means it can only be ran by the factoryOwner
    modifier onlyOwner {
        require(msg.sender == factoryOwner, 'Only the deployer of this contract can create user this function.');
        _;
    }

    // Allows factory owner to change fee for any future contracts
    function setFee(uint256 _fee) onlyOwner public {
        fee = _fee;
    }

    // Creates a new escrow contract
    function newEscrow(uint256 _id, address payable _seller, address payable _buyer) external {

        // Check a contract doesnt already exist with that ID
        require(!this.exists(_id), 'Sorry a contract with that ID already exist.');

        // Check _seller, _buyer are not empty inputs
        require(_seller != address(0) && _buyer != address(0), 'Ensure buyer and seller address are valid.');

        // Create new contract
        Escrow e = new Escrow(_seller,_buyer,address(this));

        // Store contract in mapping
        escrows[_id] = e;

    }

    // Reusable function for buyer to deposit into contract before confirming offer
    function buyerDeposit(uint256 _id) external payable {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Ensure value deposited is greater than 0
        require(msg.value > 0, 'Please ensure amount depositied is greater than 0.');

        // Get contract
        Escrow e = escrows[_id];

        // Check msg.sender is the buyer of the contract
        require(msg.sender == e.getBuyer(), 'Only the defined buyer of this contract can deposit to pot.');

        // Check contract is in a state ready to accept buyer deposit
        require(e.getState() == contractState.AWAITING_BUYER_PAYMENT, 'Contract cannot recieve any more funds.');

        // Move funds to escrow contract
        (bool success, ) = address(e).call{value:msg.value}('');
        require(success, 'Error transfering funds to escrow contract.');

        // Notify user
        emit notify('Successfully deposited funds.');

    }

    // Function to confirm with buyer the amount of ether entered into the contract is correct. If
    // not then the funds stored within contract is returned back to the buyer and contract is marked as complete
    function buyerConfirm(uint256 _id, bool _decision) public {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Check msg.sender is the buyer of the contract
        require(msg.sender == e.getBuyer(), 'Only the defined buyer of this contract can deposit to pot.');

        // Require contract still be in deposit phase
        require(e.getState() == contractState.AWAITING_BUYER_PAYMENT, 'Contract must be accepting funds in order to be confirmed by buyer.');

        // Check confirmation
        require(_decision, 'To cancel contract enter a valid positive bool input.');

        // If user inputs true (yes) then set contract to state where seller can accept
        // If user inputs false (no) then cancel and refund monies
        if(_decision) {

            // Update state of contract to allow seller to accept
            e.setState(contractState.AWAITNG_SELLER_ACCEPTANCE);

            // Log timestamp when value was confirmed by buyer
            e.setBuyerConfirmedTimeStamp(block.timestamp);

            // Notify user
            emit notify('Contract is now awaiting seller acceptance.');

        } else {

            // Refund value of escrow contract
            e.cancel();

            // Notify user
            emit notify('Contract has been cancelled, funds have been returned.');
        }

    }

    // Function allows buyer to cancel contract if seller doesn't accept within allotted time
    function buyerCancel(uint256 _id, bool _cancel) public {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Check msg.sender is the buyer
        require(msg.sender == e.getBuyer(), 'Only the buyer of this contract can cancel offer.');

        // Attempt to cancel contract
        require(_cancel, 'To cancel contract enter a valid positive bool input');

        // Make sure contract is in a state that can be cancelled
        require(e.getState() == contractState.AWAITNG_SELLER_ACCEPTANCE || e.getState() == contractState.AWAITING_BUYER_PAYMENT, 'Contract can only be cancelled if it is still awaiting acceptance from seller.');

        // If contract is waiting on buyer confirmation then cancel and return monies straight away. If waiting for seller
        // to accept then check if 5 days have passed for the seller to accept before allowing buyer to cancel
        if(e.getState() == contractState.AWAITING_BUYER_PAYMENT) {

            // Cancel contract
            e.cancel();

            // Notify user
            emit notify('Contract cancelled and state updated.');

        } else if (e.getState() == contractState.AWAITNG_SELLER_ACCEPTANCE) {

            // Make sure 5 days have passed for seller to accept
            require((block.timestamp - e.getBuyerConfirmedTimeStamp()) > 5 days, 'Please allow 5 days (including weekends) for the seller to accept before cancelling.');

            // Refund monies and complete contract
            e.cancel();

            // Notify user
            emit notify('Contract cancelled and state updated.');

        }

    }

    // This function allows only the seller to accept an offer from the buyer. If they chose to deny (cancel) the offer
    // then all monies are returned back to the buyer.
    function sellerAccept(uint256 _id, bool _decision) public {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Check msg.sender is the buyer
        require(msg.sender == e.getSeller(), 'Only the seller of this contract can accept offer');

        // Ensure contract is waiting for seller acceptance
        require(e.getState() == contractState.AWAITNG_SELLER_ACCEPTANCE, 'Sorry, this contract cannot be accepted at this time.');

        // If decision is true (accepted) then accept contract and send fee to factory owner, if decision is false (declined)
        // then refund monies
        if(_decision) {

            // Accept contract
            e.accept();

            // fee for using escrow contract
            e.sendFee(factoryOwner, fee);

            // Notify user
            emit notify('Contract has been accepted.');

        } else if (!_decision) {

            // Refund monies to buyer
            e.cancel();

            // Notify user
            emit notify('Contract cancelled.');

        }

    }

    // Determines if buyer is satisfied with product. Asks for confirmation of satisfaction before funds are 
    // then paid to the seller
    function buyerSatisfied(uint256 _id, bool _decision, bool _confirm) public {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Check msg.sender is the buyer
        require(msg.sender == e.getBuyer(), 'Only the buyer of this contract can cancel offer.');

        // Check state is waiting for buyer satisfaction
        require(e.getState() == contractState.AWAITING_BUYER_SATISFACTION, 'Contract is not currently waiting for buyer satisfaction.');

        // Make sure input entered is a positive bool
        require(_decision && _confirm, 'To confirm contract satisfaction please ensure both your decision and confirmation are positive bool inputs.');

        // Complete contract
        e.complete();

    }

    // Admin function for the factory owner. If any disputes occur the factory owner can distribute the contract worth
    // between the buyer and seller as they see fit
    function ownerDecision(uint256 _id, uint256 _percent_seller, uint256 _percent_buyer) onlyOwner external {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Check that values entered add up to 100
        require(_percent_seller + _percent_buyer == 100, 'Percents must add up to 100.');

        // Distribute funds accordingly
        e.ownerDistribute(_percent_seller,_percent_buyer);

    }

    // Gets the value of a contract
    function getContractValue(uint256 _id) public view returns (uint256) {
        
        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Return balance of contract
        return address(e).balance;

    }

    // Gets the address of an escrow contract
    function getContractAddress(uint256 _id) public view returns (address) {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Return address of contract
        return address(e);

    }

    // Checks if a contract is already allocated a unique ID
    function exists(uint256 _id) public view returns (bool) {
        if(address(escrows[_id]) != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    // Gets contract state
    function getContractState(uint256 _id) public view returns (contractState) {
        
        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Return address of contract
        return e.getState();
    }

    // Gets unix timestamp when buyer confirms deposit
    function getContractBuyerConfirmedTime(uint256 _id) public view returns (uint256) {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Return buyer confirmation timestamp of contract
        return e.getBuyerConfirmedTimeStamp();
        
    }

    // Gets unix timestamp when seller accepts offer
    function getContractSellerConfirmedTimeStamp(uint256 _id) public view returns (uint256) {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Return address of contract
        return e.getSellerConfirmedTimeStamp();
        
    }

    // Gets unix timestamp when buyer is satisfied with sellers product
    function getContractBuyerSatisfiedTimeStamp(uint256 _id) public view returns (uint256) {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Return address of contract
        return e.getBuyerSatisfiedTimeStamp();
        
    }

    // Gets unix timestmap when contract is completed
    function getContractCompletedTimeStamp(uint256 _id) public view returns (uint256) {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Return address of contract
        return e.getCompletedTimeStamp();
        
    }

}

contract Escrow {

    address payable public seller;
    address payable public buyer;
    address factory;

    uint256 buyerConfirmedTimeStamp;
    uint256 sellerConfirmedTimeStamp;
    uint256 buyerSatisfiedTimeStamp;
    uint256 completedTimeStamp;

    contractState state;

    modifier onlyFactory {
        require(msg.sender == factory, 'Only the factory can edit this contract');
        _;
    }

    constructor(address payable _seller, address payable _buyer, address _factory) {
        seller = _seller;
        buyer = _buyer;
        factory = _factory;

        state = contractState.AWAITING_BUYER_PAYMENT;
    }

    function getBuyer() public view returns (address) {
        return buyer;
    }

    function getSeller() public view returns (address) {
        return seller;
    }

    function getState() public view returns (contractState) {
        return state;
    }

    function setState(contractState _state) onlyFactory public {
        state = _state;
    }

    function setBuyerConfirmedTimeStamp(uint256 _time) onlyFactory public {
        buyerConfirmedTimeStamp = _time;
    }

    function getBuyerConfirmedTimeStamp() public view returns (uint256) {
        return buyerConfirmedTimeStamp;
    }

    function getSellerConfirmedTimeStamp() public view returns (uint256) {
        return sellerConfirmedTimeStamp;
    }

    function getBuyerSatisfiedTimeStamp() public view returns (uint256) {
        return buyerSatisfiedTimeStamp;
    }

    function getCompletedTimeStamp() public view returns (uint256) {
        return completedTimeStamp;
    }

    fallback() external payable {}

    function accept() onlyFactory public {

        state = contractState.AWAITING_BUYER_SATISFACTION;

        sellerConfirmedTimeStamp = block.timestamp;

    }

    function cancel() onlyFactory external {

        buyer.transfer(address(this).balance);

        completedTimeStamp = block.timestamp;

        state  = contractState.CANCELLED;
    }

    function complete() onlyFactory external {

        seller.transfer(address(this).balance);

        buyerSatisfiedTimeStamp = block.timestamp;
        completedTimeStamp = block.timestamp;

        state = contractState.COMPLETE;

    }

    function sendFee(address payable _owner, uint256 _fee) onlyFactory external {

        _owner.transfer((address(this).balance) * _fee/100);

    }

    function ownerDistribute(uint256 _percent_seller, uint256 _percent_buyer) onlyFactory external {

        if(_percent_seller == 0) {
            buyer.transfer(address(this).balance);
        } else if (_percent_buyer == 0) {
            seller.transfer(address(this).balance);
        } else {
            seller.transfer((address(this).balance) * _percent_seller/100);
            buyer.transfer((address(this).balance) * _percent_buyer/100);
        }

    }

}

// Author: Etienne Cellier-Clarke, add me on LinkedIn. Cheers.