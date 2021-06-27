/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

contract Owner {

    address owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}


contract EntityOfferRegistry is Owner {

    struct Offer {
        string offerName;

        uint baseFee;
        uint minimumSubscriptionTime;

        bool isRetired;
    }

    mapping(uint => Offer) public entityOffers;
    uint public offerCount;

    event OfferAdded(address indexed offerOwner, uint indexed offerIndex);
    event OfferUpdated(address indexed offerOwner, uint indexed offerIndex, string propertyName, uint newValue);
    event OfferRetired(address indexed offerOwner, uint indexed offerIndex);

    // subscription owner -> (offer index -> expiration time)
    mapping(address => mapping(uint => uint)) public subscribers;

    event SubscriptionAdded(uint indexed offerIndex, address indexed newSubscriptionOwner, uint expirationTimestamp, uint duration);
    event SubscriptionStopped(uint indexed offerIndex, address indexed subscriptionOwner, uint oldExpirationTimestamp);
    event SubscriptionAccessed(uint indexed offerIndex, address indexed subscriptionOwner);

    event Withdrawal(address indexed offerOwner, uint amount);

    modifier isExistingOffer(uint _offerIndex) {
        require(_offerIndex < offerCount, "Offer index is out of bounds");
        _;
    }
    
    modifier isNotRetired(uint _offerIndex) {
        require(!entityOffers[_offerIndex].isRetired, "Subscription offer has been retired");
        _;
    }

    function addOfferWithDefaults(string memory _offerName) public {
        addCustomOffer(_offerName, 100 gwei, 30 minutes);
    }

    function addCustomOffer(string memory _offerName, uint _baseFee, uint _minimumSubscriptionTime) public isOwner {
        Offer storage newOffer = entityOffers[offerCount];
        offerCount++;

        newOffer.offerName = _offerName;
        newOffer.baseFee = _baseFee;
        newOffer.minimumSubscriptionTime = _minimumSubscriptionTime;

        emit OfferAdded(msg.sender, offerCount - 1);
    }

    function withdraw() public isOwner {
        uint currentBalance = address(this).balance;
        payable(owner).transfer(currentBalance);

        emit Withdrawal(msg.sender, currentBalance);
    }

    function setBaseFee(uint _offerIndex, uint _baseFee) public isOwner isExistingOffer(_offerIndex) {
        entityOffers[_offerIndex].baseFee = _baseFee;

        emit OfferUpdated(msg.sender, _offerIndex, "baseFee", _baseFee);
    }

    function setMinimumSubscriptionTime(uint _offerIndex, uint _time) public isOwner isExistingOffer(_offerIndex) {
        entityOffers[_offerIndex].minimumSubscriptionTime = _time;

        emit OfferUpdated(msg.sender, _offerIndex, "minimumSubscriptionTime", _time);
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
        
        emit SubscriptionAdded(_offerIndex, msg.sender, subscribers[msg.sender][_offerIndex], _time);
    }

    function stopSubscription(address _subscriptionOwner, uint _offerIndex) public isOwner isExistingOffer(_offerIndex) {
        require(subscribers[_subscriptionOwner][_offerIndex] > block.timestamp, "Subscription is already inactive");

        uint oldExpirationTimestamp = subscribers[_subscriptionOwner][_offerIndex];
        subscribers[msg.sender][_offerIndex] = block.timestamp;

        emit SubscriptionStopped(_offerIndex, _subscriptionOwner, oldExpirationTimestamp);
    }

    function isSubscriptionActive(address _subscriptionOwner, uint _offerIndex) public view isExistingOffer(_offerIndex) isNotRetired(_offerIndex) returns (bool) {
        return subscribers[_subscriptionOwner][_offerIndex] >= block.timestamp;
    }

    function isMySubscriptionActive(uint _offerIndex) public returns (bool) {
        bool active = isSubscriptionActive(msg.sender, _offerIndex);

        if (active) {
            emit SubscriptionAccessed(_offerIndex, msg.sender);
        }

        return active;
    }
}