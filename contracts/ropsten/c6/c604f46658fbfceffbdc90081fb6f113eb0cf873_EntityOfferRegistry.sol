// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./Owner.sol";

contract EntityOfferRegistry is Owner {

    struct Offer {
        string offerName;

        uint baseFee;
        uint minimumSubscriptionTime;

        bool isRetired;
    }

    mapping(uint => Offer) public entityOffers;
    uint public offerCount;

    event NewOfferAdded(address indexed offerOwner, uint indexed offerIndex);
    event OfferUpdated(address indexed offerOwner, uint indexed offerIndex);
    event OfferRetired(address indexed offerOwner, uint indexed offerIndex);

    // subscription owner -> (offer index -> expiration time)
    mapping(address => mapping(uint => uint)) public subscribers;

    event NewSubscriptionAdded(uint indexed offerIndex, address indexed newSubscriptionOwner, uint expirationTime, uint beginningTime);

    event Withdrawal(address indexed offerOwner, uint amount);

    modifier isExistingOffer(uint _offerIndex) {
        require(_offerIndex < offerCount, "Offer index is out of bounds");
        _;
    }
    
    modifier isNotRetired(uint _offerIndex) {
        require(!entityOffers[_offerIndex].isRetired, "Subscription offer has been retired");
        _;
    }

    function addOfferWithDefaults(string memory _offerName) public isOwner {
        addCustomOffer(_offerName, 1 gwei, 30 minutes);
    }

    function addCustomOffer(string memory _offerName, uint _baseFee, uint _minimumSubscriptionTime) public isOwner {
        Offer storage newOffer = entityOffers[offerCount];
        offerCount++;

        newOffer.offerName = _offerName;
        newOffer.baseFee = _baseFee;
        newOffer.minimumSubscriptionTime = _minimumSubscriptionTime;

        emit NewOfferAdded(msg.sender, offerCount - 1);
    }

    function withdraw() public isOwner {
        uint currentBalance = address(this).balance;
        payable(owner).transfer(currentBalance);

        emit Withdrawal(msg.sender, currentBalance);
    }

    function setBaseFee(uint _offerIndex, uint _baseFee) public isOwner isExistingOffer(_offerIndex) {
        entityOffers[_offerIndex].baseFee = _baseFee;

        emit OfferUpdated(msg.sender, _offerIndex);
    }

    function setMinimumSubscriptionTime(uint _offerIndex, uint _time) public isOwner isExistingOffer(_offerIndex) {
        entityOffers[_offerIndex].minimumSubscriptionTime = _time;

        emit OfferUpdated(msg.sender, _offerIndex);
    }

    function retireOffer(uint _offerIndex) public isOwner isExistingOffer(_offerIndex) isNotRetired(_offerIndex) {
        entityOffers[_offerIndex].isRetired = true;

        emit OfferRetired(msg.sender, _offerIndex);
    }

    function computeFee(uint _offerIndex, uint _time) public view isExistingOffer(_offerIndex) returns (uint)  {
        return _time * entityOffers[_offerIndex].baseFee;
    }

    function newSubscription(uint _offerIndex, uint _time) public payable isExistingOffer(_offerIndex) isNotRetired(_offerIndex) {
        require(_time >= entityOffers[_offerIndex].minimumSubscriptionTime, "Subscription needs to be longer than the current minimum time");
        require(subscribers[msg.sender][_offerIndex] < block.timestamp, "Subscription is already active");
        require(computeFee(_offerIndex, _time) == msg.value, "Only full payments are allowed");

        subscribers[msg.sender][_offerIndex] = block.timestamp + _time;
        
        emit NewSubscriptionAdded(_offerIndex, msg.sender, subscribers[msg.sender][_offerIndex], block.timestamp);
    }

    function subscriptionExists(uint _offerIndex) public view isExistingOffer(_offerIndex) isNotRetired(_offerIndex) {
        require(subscribers[msg.sender][_offerIndex] > 0, "Subscription has not been activated for this account yet");
    }
}