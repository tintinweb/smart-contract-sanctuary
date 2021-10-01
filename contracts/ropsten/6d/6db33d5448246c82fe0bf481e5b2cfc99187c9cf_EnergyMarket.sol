/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EnergyMarket {
  
    //  Energy Resource
    struct Resource {
        uint id;            // Unique ID of resource
        address author;     // Current owner of resource
        uint volume;        // Energy volume
        uint price;         // Energy price
        bool exists;        // Helper for maps
    }
    
    // Array of resources available
    Resource[] public resources;
    mapping(uint => uint) resourceLookup;
    
    event NewResource(Resource newResource);

    // English Auction
    struct Auction {
        address payable auctioneer;
        address highestBidder;
        uint highestBid;
        uint auctionEndTime;
        uint resourceId;
        bool ended;
    }
    
    // Auction 
    Auction englishAuction;
    
    // Previous bids
    mapping(address => uint) pendingReturns;
    
    event AuctionBidIncreased(address newHighestBidder, uint bid);
    event AuctionEnded(address winner, uint highestBid);

    /**
     * Submit a new available energy resource
     */
    function submitResource(uint id, uint volume, uint price) public {
        Resource memory newResource = Resource(id, msg.sender, volume, price, true);
        resources.push(newResource);
        resourceLookup[id] = resources.length;
        
        emit NewResource(newResource);
    }

    /**
     * Returns the resources sorted by merit order by the ascending order of price.
     * 
     * @return {Resource[] memory} sorted of resources by asc price
     */
    function meritOrder() public view returns (Resource[] memory) {
        require(resources.length > 0);
        
        return _sortResources(resources);
    }
    
    /**
     * Starts an english auction for a given resource, provided it exists
     * Additionally requires the address of the auctioneer (auction hoster), and a starting price
     */
    function startAuction(uint resourceId, address payable auctioneer, uint auctionTime) public payable {
        require(!isOngoingAuction(), "There is already an ongoing auction!");
        require(!englishAuction.ended, "The previous auction hasn't been called yet!");
        require(resourceLookup[resourceId] > 0, "Resource must exist!");
        require(resources[resourceLookup[resourceId] - 1].author == msg.sender, "You must own the resource to auction it!");
        
        englishAuction = Auction(auctioneer, auctioneer, msg.value, block.timestamp + auctionTime, resourceId, false);
    }
    
    /**
     * Returns if the current auction has ended
     */
    function isOngoingAuction() public view returns (bool) {
        return englishAuction.auctionEndTime > block.timestamp;
    }
    
    /**
     * Bid on current auction
     */
    function bidAuction() public payable {
        require(isOngoingAuction(), "Auction has ended!");
        require(msg.value > englishAuction.highestBid, "Bid must be higher than current highest bid!");
        
        if (englishAuction.highestBid > 0) {
            pendingReturns[englishAuction.highestBidder] += englishAuction.highestBid;
        }
        
        englishAuction.highestBidder = msg.sender;
        englishAuction.highestBid = msg.value;
        
        emit AuctionBidIncreased(englishAuction.highestBidder, englishAuction.highestBid);
    }
    
    /**
     * Returns any funds that were since outbid.
     */
    function widthdrawPendingReturns() public returns (bool) {
        uint amountOwed = pendingReturns[msg.sender];
        
        if (amountOwed > 0) {
            bool sent = payable(msg.sender).send(amountOwed);
            
            pendingReturns[msg.sender] = sent ? 0 : amountOwed;
            return sent;
        }
        
        return true;
    }
    
    /**
     * End auction and payout the auctioneer
     */
    function endAuction() public {
        require(!isOngoingAuction(), "Auction has not ended yet!");
        require(!englishAuction.ended, "The auction winner has already been called!");

        uint highestBid = englishAuction.highestBid;
        address highestBidder = englishAuction.highestBidder;
        address payable auctioneer = englishAuction.auctioneer;
        uint resourceId = englishAuction.resourceId;

        englishAuction.ended = true;
        emit AuctionEnded(englishAuction.highestBidder, englishAuction.highestBid);

        auctioneer.transfer(highestBid);
        resources[resourceLookup[resourceId] - 1].author = highestBidder;
    }
    
    /**
     * Helper to sort resources by price
     */
    function _sortResources(Resource[] memory resourceArr) internal view returns(Resource[] memory) {
       _quickSortResources(resourceArr, int(0), int(resourceArr.length - 1));
       
       return resourceArr;
    }
    
    function _quickSortResources(Resource[] memory resourceArr, int left, int right) internal view {
        int i = left;
        int j = right;
        if(i==j) return;
        
        uint pivot = resourceArr[uint(left + (right - left) / 2)].price;
        
        while (i <= j) {
            while (resourceArr[uint(i)].price < pivot) i++;
            while (pivot < resourceArr[uint(j)].price) j--;
            
            if (i <= j) {
                (resourceArr[uint(i)], resourceArr[uint(j)]) = (resourceArr[uint(j)], resourceArr[uint(i)]);
                i++;
                j--;
            }
        }
        
        if (left < j)
            _quickSortResources(resourceArr, left, j);
        if (i < right)
            _quickSortResources(resourceArr, i, right);
    }

}