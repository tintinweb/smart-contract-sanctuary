/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Create an enum which defines what states the contract can be in
enum contractState{AWAITING_BUYER_PAYMENT,AWAITNG_SELLER_ACCEPTANCE,AWAITING_BUYER_SATISFACTION,COMPLETE}

contract Escrow_Factory {

    event notify(string message);

    address payable public contractOwner;

    mapping(uint256 => Escrow) public escrows;

    constructor() {
        contractOwner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == contractOwner, 'Only the deployer of this contract can create more escrows.');
        _;
    }

    function newEscrow(uint256 _id, address payable _seller, address payable _buyer) onlyOwner external {

        // Check a contract doesnt already exist with that ID
        require(!this.exists(_id), 'Sorry a contract with that ID already exist.');

        // Check _seller, _buyer are not empty inputs
        require(_seller != address(0) && _buyer != address(0), 'Ensure buyer and seller address are valid.');

        // Create new contract
        Escrow e = new Escrow(_seller,_buyer,address(this));

        // Store contract in mapping
        escrows[_id] = e;

    }

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

        emit notify('Successfully deposited funds.');

    }

    // Function to confirm buyer the price they have entered into the contract is correct
    function buyerConfirm(uint256 _id, bool _confirmed) public {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Check msg.sender is the buyer of the contract
        require(msg.sender == e.getBuyer(), 'Only the defined buyer of this contract can deposit to pot.');

        // Require contract still be in deposit phase
        require(e.getState() == contractState.AWAITING_BUYER_PAYMENT, 'Contract must be accepting funds in order to be confirmed by buyer');

        // Check confirmation
        require(_confirmed, 'To cancel contract enter a valid positive bool input');

        // If user inputs true (yes) then set contract to state where seller can accept
        // If user inputs false (no) then cancel and refund monies
        if(_confirmed) {

            // Update state of contract to allow seller to accept
            e.setState(contractState.AWAITNG_SELLER_ACCEPTANCE);

            // Log timestamp when value was confirmed by buyer
            e.setBuyerConfirmedTimeStamp(block.timestamp);

            emit notify('Contract is now awaiting seller acceptance.');

        } else {

            // Refund value of escrow contract
            e.cancel();

            emit notify('Contract has been cancelled, funds have been returned.');
        }

    }

    // Function allows buyer to cancel contract if seller never accepts
    function buyerCancel(uint256 _id, bool _cancel) public {

        // Check a contract doesnt already exist with that ID
        require(this.exists(_id), "Sorry a contract with that ID doesn't exist.");

        // Get contract
        Escrow e = escrows[_id];

        // Check msg.sender is the buyer
        require(msg.sender == e.getBuyer(), 'Only the buyer of this contract can cancel offer');

        // Attempt to cancel contract
        require(_cancel, 'To cancel contract enter a valid positive bool input');

        // Make sure contract is in a state that can be cancelled
        require(e.getState() == contractState.AWAITNG_SELLER_ACCEPTANCE || e.getState() == contractState.AWAITING_BUYER_PAYMENT, 'Contract can only be cancelled if it is still awaiting acceptance from seller');

        // if(e.getState() == contractState.AWAITING_BUYER_PAYMENT) {

        //     e.cancel();

        //     emit notify('Contract cancelled and now marked as complete');

        // } else if (e.getState() == contractState.AWAITNG_SELLER_ACCEPTANCE) {

        //     // Make sure 3 days have passed for seller to accept
        //     require((block.timestamp - e.getBuyerConfirmedTimeStamp()) > 5 minutes, 'Please allow 3 days for the seller to accept before cancelling');

        //     // Refund monies and complete contract
        //     e.cancel();

        //     emit notify('Contract cancelled and now marked as complete');

        // }

        e.cancel();

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

}

contract Escrow {

    address payable public seller;
    address payable public buyer;
    address factory;

    uint256 buyerConfirmedTimeStamp;

    contractState state;

    // When declared a function can only be called by the contract factory. This prevents
    // users manually editing values within the contract on the blockchain
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

    fallback() external payable {}

    function cancel() onlyFactory external {

        // Transfer value of contract back to buyer
        buyer.transfer(address(this).balance);

        // Update state of contract to complete
        state  = contractState.COMPLETE;
    }

}

// Author: Etienne Cellier-Clarke