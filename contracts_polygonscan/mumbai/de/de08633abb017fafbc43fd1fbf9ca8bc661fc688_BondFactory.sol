// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { IERC20 } from './IERC20.sol';
import {BondWallet} from './BondWallet.sol';

struct Subscriber {
        address payable subscriber;
        uint subscriptionValue;
        uint availableBalance;
 }

 /**
    @title BondFactory
    @author Harry Moy, Sam Clusker
    @dev Contract used to create and call Bond Wallets
    Copyright 2021 Harry Moy, Sam Clusker
  */
contract BondFactory {

    uint private bondCount = 1;
    mapping (uint => address) private bonds;
    mapping (uint => mapping(address => Subscriber)) private subscribers;
    IERC20 private paymentToken;
    
    event IssueBond (uint _bondId);
    event SubscribedToBond(address _bond, address _subscriber, uint _subscriptionValue);
    event Withdrawal(uint _bondId, address _subscriber, uint _amount);
    event BondStateChange(string _message);
    event SubscriptionChange(uint _subscription);
    event RateChange(uint _newRate);
    event BondQuery(uint _currentBalance, uint _maxSubscription, uint _rate);
    event EmitAddressForApproval(address _bondAddress);
    

    //Instantiate the contract with the Dai token address.
    constructor() {
        paymentToken = IERC20(address(0x655F2166b0709cd575202630952D71E2bB0d61Af));
    }

                                                        ///////////////////////////////////// Function Calls /////////////////////////////////////

    /**
        Issue the bond and create a BondWallet contract.
        @param _rate: The rate the bond is issued at.
        @param _maxSubscription: The amount the user is looking to raise.
        @return Returns the address of the issued bond.
     */                                     
    function issueBond(uint _rate, uint _maxSubscription) public returns (address) {
        BondWallet bond = new BondWallet(msg.sender, _maxSubscription, _rate, paymentToken);
        bonds[bondCount] = address(bond);
        bondCount++;
        emit IssueBond(bondCount);
        return address(bond);
    }

    /**
        Emits the address for a selected bond so the .approve() can be called at Dai's address with the selected bond's address.
        @param _bondId: The Id for a specific bond.
     */    
    function requestApprovalForBond(uint _bondId) public {
        address bondAddress = bonds[_bondId];
        emit EmitAddressForApproval(bondAddress);
    }

    /**
        Subscribes a user to a selected bond. Performs checks that whether the user is already subscribed and if the amount they're subscribing is greater than max subscription.
        @param _bondId: The Id for a specific bond.
        @param _subscriptionAmount: The amount they want to subscribe with.
     */    
    function subscribeToBond(uint _bondId, uint _subscriptionAmount) public payable {
        BondWallet selectedBond = BondWallet(bonds[_bondId]);
        uint bondCurrentBalance = selectedBond.getBalance();
        uint bondMaxSubscription = selectedBond.maxSubscription();
        uint existingSubscriberValue = subscribers[_bondId][msg.sender].subscriptionValue;
        uint subscriptionValue = _subscriptionAmount * selectedBond.rate();

        assert(_subscriptionAmount + bondCurrentBalance < bondMaxSubscription);
        if (existingSubscriberValue > 0) {
            assert(existingSubscriberValue + _subscriptionAmount + bondCurrentBalance < bondMaxSubscription);
            subscribers[_bondId][msg.sender].subscriptionValue += subscriptionValue;
        } else {
            Subscriber memory subscriber = Subscriber(payable(msg.sender), subscriptionValue, 0);
            subscribers[_bondId][msg.sender] = subscriber;
        }

        selectedBond.subscribeToBond(_subscriptionAmount, msg.sender);
        emit SubscribedToBond(address(selectedBond), msg.sender, subscriptionValue);
    }

    /**
        Checks if the user has sufficient funds to withdraw and withdraws that amount.
        @param _bondId: The Id for a specific bond.
        @param _amount: The amount they wish to withdraw.
     */    
    function withdraw(uint _bondId, uint _amount) public {
        BondWallet selectedBond = BondWallet(bonds[_bondId]);
        uint bondCurrentBalance = selectedBond.getBalance();

        if (selectedBond.owner() == msg.sender) {
            require(selectedBond.owner() == msg.sender, "You are not the owner");
            require(_amount <= bondCurrentBalance, "You are trying to withdraw too much");
        } else {
            uint availableBalance = subscribers[_bondId][msg.sender].availableBalance; 
            require(availableBalance > 0 && availableBalance > _amount, "You have no balance to withdraw");
        }
        selectedBond.withdraw(_amount, msg.sender);
        emit Withdrawal(_bondId, msg.sender, _amount);
    }
    
    /**
        Closes the bond so it cannot receive any more subscriptions if user is the owner.
        @param _bondId: The Id for a specific bond.
     */    
    function closeBond(uint _bondId) public {
        BondWallet selectedBond = BondWallet(bonds[_bondId]);
        selectedBond.closeBond(msg.sender);
        emit BondStateChange("Closed");
    }

    /**
        Opens the bond so it can receive subscriptions if the user is the owner.
        @param _bondId: The Id for a specific bond.
     */
    function openBond(uint _bondId) public {
        BondWallet selectedBond = BondWallet(bonds[_bondId]);
        selectedBond.openBond(msg.sender);
        emit BondStateChange("Opened");
    }

    /**
        Deletes the bond if the user is the owner.
        @param _bondId: The Id for a specific bond.
     */
    function deleteBond(uint _bondId) public {
        BondWallet selectedBond = BondWallet(bonds[_bondId]);
        selectedBond.deleteBond(msg.sender);
        emit BondStateChange("Deleted");
    }

    /**
        Changes the maximum subscription if the user is the owner.
        @param _bondId: The Id for a specific bond.
        @param _amount: The amount they wish to change the max subscription to.
     */
    function changeMaxSubscription(uint _bondId, uint _amount) public returns(uint)  {
        BondWallet selectedBond = BondWallet(bonds[_bondId]);
        uint newMax = selectedBond.changeMaxSubscription(_amount);
        emit SubscriptionChange(newMax);
        return newMax;
    }
    
    /**
        Changes the rate if the user is the owner.
        @param _bondID: The Id for a specific bond.
        @param _newRate: The new rate they wish to apply.
     */
    function changeRate(uint _bondID, uint _newRate) public returns(uint) {
        BondWallet selectedBond = BondWallet(bonds[_bondID]);
        uint newRate = selectedBond.changeRate(_newRate);
        emit RateChange(newRate);
        return newRate;
    }

     /**
        Queries the selected bond's data.
        @param _bondId: The Id for a specific bond.
     */
    function queryBondData(uint _bondId) public {
        BondWallet selectedBond = BondWallet(bonds[_bondId]);
        uint bondCurrentBalance = selectedBond.getBalance();
        uint bondMaxSubscription = selectedBond.maxSubscription();
        uint bondCurrentRate = selectedBond.rate();
        emit BondQuery(bondCurrentBalance, bondMaxSubscription, bondCurrentRate);
    }
}