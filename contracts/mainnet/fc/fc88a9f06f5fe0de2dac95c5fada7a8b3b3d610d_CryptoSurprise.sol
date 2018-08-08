pragma solidity ^0.4.19;

	////////////////////////////////////
	////// CRYPTO SURPRISE
	////// https://cryptosurprise.me
	////////////////////////////////////
	
contract CryptoSurprise
{
    using SetLibrary for SetLibrary.Set;
    
    ////////////////////////////////////
    ////// CONSTANTS
    
    uint256 constant public BAG_TRANSFER_FEE = 0.05 ether;
    uint256 constant public BAG_TRANSFER_MINIMUM_AMOUNT_OF_BUYS = 4;
    
    
    ////////////////////////////////////
    ////// STATE VARIABLES
    
    struct BagType
    {
        // Constants
        string name;
        
        uint256 startPrice;
        uint256 priceMultiplierPerBuy; // For example, 2 000 000 means 100% increase. (100% = doubling every buy)
        
        uint256 startCommission; // 0 to 1 000 000, for example 100 000 means 10%
        uint256 commissionIncrementPerBuy;
        uint256 maximumCommission;
        
        uint256 supplyHardCap;
        
        // Variables
        uint256 currentSupply;
    }
    
    struct Bag
    {
        // Constants
        uint256 bagTypeIndex;
        
        // Variables
        uint256 amountOfBuys;
        address owner;
        uint256 commission; // 0 to 1 000 000, for example 100 000 means 10%
        uint256 price;
        
        uint256 availableTimestamp;
    }
    
    // Variable that remembers the current owner
    address public owner;
    BagType[] public bagTypes;
    Bag[] public bags;
    
    mapping(address => uint256) public addressToTotalEtherSpent;
    mapping(address => uint256) public addressToTotalPurchasesMade;
    mapping(address => SetLibrary.Set) private ownerToBagIndices;
    address[] public allParticipants;
    
    
    ////////////////////////////////////
    ////// PLAYER FUNCTIONS
    
    function buyBag(uint256 _bagIndex) external payable
    {
        // Make sure that the bag exists
        require(_bagIndex < bags.length);
        
        // Reference the bag data and bag type data
        Bag storage bag = bags[_bagIndex];
        BagType storage bagType = bagTypes[bag.bagTypeIndex];
        
        // Make sure the bag is already available
        require(now >= bag.availableTimestamp);
        
        // Make sure the caller payed at least the current price
        require(msg.value >= bag.price);
        uint256 refund = msg.value - bag.price;
        
        // Remember who the previous owner was
        address previousOwner = bag.owner;
        
        // Set the buyer as the new owner
        bag.owner = msg.sender;
        
        // Calculate the previous and next price
        uint256 previousPrice = bag.price * 1000000 / bagType.priceMultiplierPerBuy;
        uint256 nextPrice = bag.price * bagType.priceMultiplierPerBuy / 1000000;
        
        // Calculate how much the previous owner should get:
        uint256 previousOwnerReward;
        
        // If this is the first buy: the full current price
        if (bag.amountOfBuys == 0)
        {
            previousOwnerReward = bag.price;
        }
        
        // otherwise: previous price + the commission
        else
        {
            previousOwnerReward = bag.price * bag.commission / 1000000;
            //previousOwnerReward = previousPrice + previousPrice * bag.commission / 1000000;
        }
        
        // Set the new price of the bag
        bag.price = nextPrice;
        
        // Increment the amountOfBuys counter
        bag.amountOfBuys++;
        
        // If this is NOT the first buy of this bag:
        if (bag.amountOfBuys > 1)
        {
            // Increase the commission up to the maximum
            if (bag.commission < bagType.maximumCommission)
            {
                uint256 newCommission = bag.commission + bagType.commissionIncrementPerBuy;
                
                if (newCommission >= bagType.maximumCommission)
                {
                    bag.commission = bagType.maximumCommission;
                }
                else 
                {
                    bag.commission = newCommission;
                }
            }
        }
        
        // Record statistics
        if (addressToTotalPurchasesMade[msg.sender] == 0)
        {
            allParticipants.push(msg.sender);
        }
        addressToTotalEtherSpent[msg.sender] += msg.value;
        addressToTotalPurchasesMade[msg.sender]++;
        
        // Transfer the reward to the previous owner. If the previous owner is
        // the CryptoSurprise smart contract itself, we don&#39;t need to perform any
        // transfer because the contract already has it.
        if (previousOwner != address(this))
        {
            previousOwner.transfer(previousOwnerReward);
        }
        
        if (refund > 0)
        {
            msg.sender.transfer(refund);
        }
    }
    
    function transferBag(address _newOwner, uint256 _bagIndex) public payable
    {
        // Require payment
        require(msg.value == BAG_TRANSFER_FEE);
        
        // Perform the transfer
        _transferBag(msg.sender, _newOwner, _bagIndex);
    }
    
    
    ////////////////////////////////////
    ////// OWNER FUNCTIONS
    
    // Constructor function
    function CryptoSurprise() public
    {
        owner = msg.sender;
        
        bagTypes.push(BagType({
            name: "Blue",
            
            startPrice: 0.04 ether,
            priceMultiplierPerBuy: 1300000, // 130%
            
            startCommission: 850000, // 85%
            commissionIncrementPerBuy: 5000, // 0.5 %-point
            maximumCommission: 900000, // 90%
            
            supplyHardCap: 600,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "Red",
            
            startPrice: 0.03 ether,
            priceMultiplierPerBuy: 1330000, // 133%
            
            startCommission: 870000, // 87%
            commissionIncrementPerBuy: 5000, // 0.5 %-point
            maximumCommission: 920000, // 92%
            
            supplyHardCap: 300,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "Green",
            
            startPrice: 0.02 ether,
            priceMultiplierPerBuy: 1360000, // 136%
            
            startCommission: 890000, // 89%
            commissionIncrementPerBuy: 5000, // 0.5 %-point
            maximumCommission: 940000, // 94%
            
            supplyHardCap: 150,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "Black",
            
            startPrice: 0.1 ether,
            priceMultiplierPerBuy: 1450000, // 145%
            
            startCommission: 920000, // 92%
            commissionIncrementPerBuy: 10000, // 1 %-point
            maximumCommission: 960000, // 96%
            
            supplyHardCap: 50,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "Pink",
            
            startPrice: 1 ether,
            priceMultiplierPerBuy: 1500000, // 150%
            
            startCommission: 940000, // 94%
            commissionIncrementPerBuy: 10000, // 1 %-point
            maximumCommission: 980000, // 98%
            
            supplyHardCap: 10,
            
            currentSupply: 0
        }));
		bagTypes.push(BagType({
            name: "White",
            
            startPrice: 10 ether,
            priceMultiplierPerBuy: 1500000, // 150%
            
            startCommission: 970000, // 97%
            commissionIncrementPerBuy: 10000, // 1 %-point
            maximumCommission: 990000, // 99%
            
            supplyHardCap: 1,
            
            currentSupply: 0
        }));
    }
    
    // Function that allows the current owner to transfer ownership
    function transferOwnership(address _newOwner) external
    {
        require(msg.sender == owner);
        owner = _newOwner;
    }
    
    // Only the owner can deposit ETH by sending it directly to the contract
    function () payable external
    {
        require(msg.sender == owner);
    }
    
    // Function that allows the current owner to withdraw any amount
    // of ETH from the contract
    function withdrawEther(uint256 amount) external
    {
        require(msg.sender == owner);
        owner.transfer(amount);
    }
    
    function addBag(uint256 _bagTypeIndex) external
    {
        addBagAndGift(_bagTypeIndex, address(this));
    }
    function addBagDelayed(uint256 _bagTypeIndex, uint256 _delaySeconds) external
    {
        addBagAndGiftAtTime(_bagTypeIndex, address(this), now + _delaySeconds);
    }
    
    function addBagAndGift(uint256 _bagTypeIndex, address _firstOwner) public
    {
        addBagAndGiftAtTime(_bagTypeIndex, _firstOwner, now);
    }
    function addBagAndGiftAtTime(uint256 _bagTypeIndex, address _firstOwner, uint256 _timestamp) public
    {
        require(msg.sender == owner);
        
        require(_bagTypeIndex < bagTypes.length);
        
        BagType storage bagType = bagTypes[_bagTypeIndex];
        
        require(bagType.currentSupply < bagType.supplyHardCap);
        
        bags.push(Bag({
            bagTypeIndex: _bagTypeIndex,
            
            amountOfBuys: 0,
            owner: _firstOwner,
            commission: bagType.startCommission,
            price: bagType.startPrice,
            
            availableTimestamp: _timestamp
        }));
        
        bagType.currentSupply++;
    }
    

    
    ////////////////////////////////////
    ////// INTERNAL FUNCTIONS
    
    function _transferBag(address _from, address _to, uint256 _bagIndex) internal
    {
        // Make sure that the bag exists
        require(_bagIndex < bags.length);
        
        // Bag may not be transferred before it has been bought x times
        require(bags[_bagIndex].amountOfBuys >= BAG_TRANSFER_MINIMUM_AMOUNT_OF_BUYS);
        
        // Make sure that the sender is the current owner of the bag
        require(bags[_bagIndex].owner == _from);
        
        // Set the new owner
        bags[_bagIndex].owner = _to;
        ownerToBagIndices[_from].remove(_bagIndex);
        ownerToBagIndices[_to].add(_bagIndex);
        
        // Trigger blockchain event
        Transfer(_from, _to, _bagIndex);
    }
    
    
    ////////////////////////////////////
    ////// VIEW FUNCTIONS FOR USER INTERFACE
    
    function amountOfBags() external view returns (uint256)
    {
        return bags.length;
    }
    function amountOfBagTypes() external view returns (uint256)
    {
        return bagTypes.length;
    }
    function amountOfParticipants() external view returns (uint256)
    {
        return allParticipants.length;
    }
    
    
    ////////////////////////////////////
    ////// ERC721 NON FUNGIBLE TOKEN INTERFACE
    
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    
    function name() external pure returns (string)
    {
        return "Bags";
    }
    
    function symbol() external pure returns (string)
    {
        return "BAG";
    }
    
    function totalSupply() external view returns (uint256)
    {
        return bags.length;
    }
    
    function balanceOf(address _owner) external view returns (uint256)
    {
        return ownerToBagIndices[_owner].size();
    }
    
    function ownerOf(uint256 _bagIndex) external view returns (address)
    {
        require(_bagIndex < bags.length);
        
        return bags[_bagIndex].owner;
    }
    mapping(address => mapping(address => mapping(uint256 => bool))) private ownerToAddressToBagIndexAllowed;
    function approve(address _to, uint256 _bagIndex) external
    {
        require(_bagIndex < bags.length);
        
        require(msg.sender == bags[_bagIndex].owner);
        
        ownerToAddressToBagIndexAllowed[msg.sender][_to][_bagIndex] = true;
    }
    
    function takeOwnership(uint256 _bagIndex) external
    {
        require(_bagIndex < bags.length);
        
        address previousOwner = bags[_bagIndex].owner;
        
        require(ownerToAddressToBagIndexAllowed[previousOwner][msg.sender][_bagIndex] == true);
        
        ownerToAddressToBagIndexAllowed[previousOwner][msg.sender][_bagIndex] = false;
        
        _transferBag(previousOwner, msg.sender, _bagIndex);
    }
    
    function transfer(address _to, uint256 _bagIndex) external
    {
        transferBag(_to, _bagIndex);
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256)
    {
        require(_index < ownerToBagIndices[_owner].size());
        
        return ownerToBagIndices[_owner].values[_index];
    }
}
 
library SetLibrary
{
    struct ArrayIndexAndExistsFlag
    {
        uint256 index;
        bool exists;
    }
    struct Set
    {
        mapping(uint256 => ArrayIndexAndExistsFlag) valuesMapping;
        uint256[] values;
    }
    function add(Set storage self, uint256 value) public returns (bool added)
    {
        // If the value is already in the set, we don&#39;t need to do anything
        if (self.valuesMapping[value].exists == true) return false;
        
        // Remember that the value is in the set, and remember the value&#39;s array index
        self.valuesMapping[value] = ArrayIndexAndExistsFlag({index: self.values.length, exists: true});
        
        // Add the value to the array of unique values
        self.values.push(value);
        
        return true;
    }
    function contains(Set storage self, uint256 value) public view returns (bool contained)
    {
        return self.valuesMapping[value].exists;
    }
    function remove(Set storage self, uint256 value) public returns (bool removed)
    {
        // If the value is not in the set, we don&#39;t need to do anything
        if (self.valuesMapping[value].exists == false) return false;
        
        // Remember that the value is not in the set
        self.valuesMapping[value].exists = false;
        
        // Now we need to remove the value from the array. To prevent leaking
        // storage space, we move the last value in the array into the spot that
        // contains the element we&#39;re removing.
        if (self.valuesMapping[value].index < self.values.length-1)
        {
            uint256 valueToMove = self.values[self.values.length-1];
            uint256 indexToMoveItTo = self.valuesMapping[value].index;
            self.values[indexToMoveItTo] = valueToMove;
            self.valuesMapping[valueToMove].index = indexToMoveItTo;
        }
        
        // Now we remove the last element from the array, because we just duplicated it.
        // We don&#39;t free the storage allocation of the removed last element,
        // because it will most likely be used again by a call to add().
        // De-allocating and re-allocating storage space costs more gas than
        // just keeping it allocated and unused.
        
        // Uncomment this line to save gas if your use case does not call add() after remove():
        // delete self.values[self.values.length-1];
        self.values.length--;
        
        // We do free the storage allocation in the mapping, because it is
        // less likely that the exact same value will added again.
        delete self.valuesMapping[value];
        
        return true;
    }
    function size(Set storage self) public view returns (uint256 amountOfValues)
    {
        return self.values.length;
    }
    
    // Also accept address and bytes32 types, so the user doesn&#39;t have to cast.
    function add(Set storage self, address value) public returns (bool added) { return add(self, uint256(value)); }
    function add(Set storage self, bytes32 value) public returns (bool added) { return add(self, uint256(value)); }
    function contains(Set storage self, address value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function contains(Set storage self, bytes32 value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function remove(Set storage self, address value) public returns (bool removed) { return remove(self, uint256(value)); }
    function remove(Set storage self, bytes32 value) public returns (bool removed) { return remove(self, uint256(value)); }
}