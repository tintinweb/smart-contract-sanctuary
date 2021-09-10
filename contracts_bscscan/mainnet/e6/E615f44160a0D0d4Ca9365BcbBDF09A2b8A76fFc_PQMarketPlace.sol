// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC20.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Distributor is Ownable() {

    address private qbitContractAddress = 0xA38898a4Ae982Cb0131104a6746f77fA0dA57aAA;

    constructor() Ownable() {
        
    }

    function distributeSale(address to, uint256 amount) external onlyOwner {
        require(ERC20(qbitContractAddress).transfer(to, amount));
    }
}

contract PQMarketPlace is Ownable, ERC165, IERC721Receiver {
    
    Distributor private distributor;
    address private developer;
    
    constructor() Ownable() {
        distributor = new Distributor();
    }
    
    using Counters for Counters.Counter;
    Counters.Counter private listingIDS;
    
    enum TokenType {
        ERC721,
        ERC1155
    }
    
    struct Bid {
        address buyer;
        uint256 amount;
    }
    
    struct Listing {
        uint256 listingID;
        address owner;
        TokenType tokenType;
        address contractAddress;
        uint256 tokenID;
        uint256 buyItNowPrice;
        uint256 minBidPrice;
        uint lastBid;
        uint256 expiry;
        uint amount;
    }
    
    
    
    address private qbitContractAddress = 0xA38898a4Ae982Cb0131104a6746f77fA0dA57aAA;
    //ListingID => bidID => Bid Information
    mapping(uint256 => mapping(uint256 => Bid)) private bids;
    mapping(uint256 => uint256[]) private bidIDs;
    //Listing ID => Listing
    mapping(uint256 => Listing) private individualListings;
    uint256[] private listingIDs;
    //User address => listing ID => Listing
    mapping(address => mapping(uint256 => Listing)) private userListings;
    //User Address => listing IDs
    mapping(address => uint256[]) private playerListingIDs;
    uint fee = 5;
    uint power = 1000;
    uint256 constant  maxQbitTransfer = 100000000000;
    uint256 maxExpiry = 2592000000;

    
    
    event ListOutOfGameItem(address owner, address contractAddress, uint256 tokenID, uint256 buyItNowPrice, uint256 expiry);
    event RelistItem(address owner, uint256 listingID, uint256 newExpiry, uint256 newMinBidPrice, uint256 newBuyItNowPrice);
    event CancelListing(address owner, uint256 listingID);
    event BuyItNow(uint256 listing, address from, uint256 price);
    event ClaimListing(address bidder, uint256 listingID, uint256 price);
    event PlaceBid(address bidder, uint256 listingID, uint256 amount);
    
    
    function setQbitContractAddress(address contractAddress) public onlyOwner {
        qbitContractAddress = contractAddress;
    }

    function setFee(uint newFee, uint256 newPower) public onlyOwner {
        fee = newFee;
        power = newPower;
    }
    
    function getDistributorAddress() public view returns (address) {
        return address(distributor);
    }
    
    function setMaxExpiry(uint256 _maxExpiry) public onlyOwner {
        maxExpiry = _maxExpiry;
    }
    
    function setDeveloper(address _developer) public onlyOwner {
        require(developer == address(0x0), "Developer cannot be changed once it has been set.");
        developer = _developer;
    }
    
    function getDeveloper() public view returns (address) {
        return developer;
    }
    
    function listOutOfGameItem(address owner, address contractAddress, uint256 tokenID, uint256 buyItNowPrice, uint256 minBidPrice, uint256 expiry) public {
        require(buyItNowPrice < maxQbitTransfer && minBidPrice < maxQbitTransfer, "You cannot transfer more than 1billion Qbit");
        require(owner == msg.sender, "only the owner of the asset can list their item");
        require(minBidPrice < buyItNowPrice, "Min Bid Price cannot be lower than the buy it now price");
        require(expiry - block.timestamp < maxExpiry, "A listing cannot be longer than the max expiry");
        listingIDS.increment();
        uint256 listingID = listingIDS.current();
        ERC721(contractAddress).safeTransferFrom(owner, address(this), tokenID);
        Listing memory newListing = Listing(listingID, owner, TokenType.ERC721, contractAddress, tokenID, buyItNowPrice, minBidPrice, 0, expiry, 1);
        listingIDs.push(listingID);
        individualListings[listingID] = newListing;
        userListings[owner][listingID] = newListing;
        playerListingIDs[owner].push(listingID);
        
        emit ListOutOfGameItem(owner, contractAddress, tokenID, buyItNowPrice, expiry);
    }

    function relistItem(address owner, uint256 listingID, uint256 newExpiry, uint256 newMinBidPrice, uint256 newBuyItNowPrice) public {
        Listing storage item = individualListings[listingID];
        require(owner == msg.sender && owner == item.owner , "only the owner of the asset can relist their item");
        require(newMinBidPrice < newBuyItNowPrice, "Min Bid Price cannot be lower than the buy it now price");
        require(bidIDs[listingID].length == 0, "The Item contains bids and cannot be relisted");
        require(block.timestamp > item.expiry, "Item has not expired you cannot relist");
        item.expiry = newExpiry;
        item.minBidPrice = newMinBidPrice;
        item.buyItNowPrice = newBuyItNowPrice;
        
        emit RelistItem(owner, listingID, newExpiry, newMinBidPrice, newBuyItNowPrice);
    }

    function cancelListing(address owner, uint256 listingID) public {
        Listing storage item = individualListings[listingID];
        require((owner == msg.sender || super.owner() == msg.sender) && owner == item.owner , "only the owner of this contract or the owner of the asset can cancel their listing");
        require(bidIDs[listingID].length == 0, "The Item contains bids and cannot be canceled");
        transferERC721Token(owner, item);
        delete individualListings[listingID];
        delete userListings[item.owner][listingID];
        delete playerListingIDs[item.owner];
        uint256[] memory newArray = new uint[](listingIDs.length - 1);
        bool found = false;
        for(uint256 i = 0; i < listingIDs.length; i++) {
            if(listingIDs[i] == listingID) {
                found = true;
            } else {
                if(found) {
                    newArray[i - 1] = listingIDs[i];
                } else {
                    newArray[i] = listingIDs[i];
                }
                
            }
        }
        listingIDs = newArray;
        
        emit CancelListing(owner, listingID);
    }

    function buyItNow(uint256 listing, address from) public {
        Listing storage item = individualListings[listing];
        require(item.owner != from, "You cannot buy your own listing");
        require(bids[listing][item.lastBid].amount < item.buyItNowPrice, "The bidding price has surpassed the buy it now price");
        uint256 feeAmount = item.buyItNowPrice * fee / power;
        uint256 finalAmount = item.buyItNowPrice - feeAmount;
        //reflection will happen direct transfer from a user to a user.
        require(ERC20(qbitContractAddress).transferFrom(from, item.owner, finalAmount), "Failed to send qbit to Distributor");
        if(feeAmount > 0) {
            require(ERC20(qbitContractAddress).transferFrom(from, address(this), feeAmount), "Failed to take Fee");
            require(ERC20(qbitContractAddress).transfer(developer, feeAmount), "Failed to send Fee");
        }
        transferERC721Token(from, item);
        delete individualListings[listing];
        delete userListings[item.owner][listing];
        delete playerListingIDs[item.owner];
        uint256[] memory newArray = new uint[](listingIDs.length - 1);
        bool found = false;
        for(uint256 i = 0; i < listingIDs.length; i++) {
            if(listingIDs[i] == listing) {
                found = true;
            } else {
                if(found) {
                    newArray[i - 1] = listingIDs[i];
                } else {
                    newArray[i] = listingIDs[i];
                }
                
            }
        }
        listingIDs = newArray;
        mapping(uint256 => Bid) storage bidders = bids[listing];
        uint256[] memory listingbidIDs = bidIDs[listing];
        for(uint256 i = 0; i < listingbidIDs.length; i++) {
            uint256 bidID = listingbidIDs[i];
            if(bidID == item.lastBid) {
                ERC20(qbitContractAddress).transfer(bidders[bidID].buyer, bidders[bidID].amount);
            }
            delete bids[listing][bidID];
        }
        
        emit BuyItNow(listing, from, item.buyItNowPrice);
    }

    function claimListing(address bidder, uint256 listingID) public {
        require(bidder == msg.sender || super.owner() == msg.sender , "only the owner of this contract or the address owner of the bidding wallet can claim Listing");
        Listing storage item = individualListings[listingID];
        uint256[] memory listingbidIDs = bidIDs[listingID];
        mapping(uint256 => Bid) storage bidders = bids[listingID];
        require(bids[listingID][item.lastBid].buyer == bidder, "You are not the final bidder and cannot claim item");
        require(block.timestamp > item.expiry, "The listing has not finished");
        for(uint256 i = 0; i < listingbidIDs.length; i++) {
            uint256 bidID = listingbidIDs[i];
            if(bidID == item.lastBid) {
                uint256 feeAmount = bidders[bidID].amount * fee / power;
                uint256 finalAmount = bidders[bidID].amount - feeAmount;
                require(ERC20(qbitContractAddress).transfer(address(distributor), finalAmount), "Failed to send QBIT to distributor");
                distributor.distributeSale(item.owner, finalAmount);
                if(feeAmount > 0) {
                    require(ERC20(qbitContractAddress).transfer(developer, feeAmount), "Failed to take Fee");
                }
                transferERC721Token(bidders[bidID].buyer, item);
            }
            delete bids[listingID][bidID];
        }
        delete individualListings[listingID];
        delete userListings[item.owner][listingID];
        delete playerListingIDs[item.owner];
        uint256[] memory newArray = new uint[](listingIDs.length - 1);
        bool found = false;
        for(uint256 i = 0; i < listingIDs.length; i++) {
            if(listingIDs[i] == listingID) {
                found = true;
            } else {
                if(found) {
                    newArray[i - 1] = listingIDs[i];
                } else {
                    newArray[i] = listingIDs[i];
                }
                
            }
        }
        listingIDs = newArray;
        emit ClaimListing(bidder, listingID, item.buyItNowPrice);
    }
    
    function placeBid(address bidder, uint256 listingID, uint256 amount) public {
        require(bidder == msg.sender, "only the owner of the address owner of the bidding wallet can bid");
        Listing storage item = individualListings[listingID];
        require(item.owner != bidder, "You cannot bid on your own listing");
        require(amount < item.minBidPrice, "Min bid price is higher than the amount bid");
        require(bids[listingID][item.lastBid].buyer != bidder, "You are already the highest bidder on this Listing.");
        require(amount > bids[listingID][item.lastBid].amount, "Bid is not higher than the previous bid.");
        require(ERC20(qbitContractAddress).balanceOf(bidder) >= amount, "You do not have enough QBIT to make this bid.");
        require(item.expiry > block.timestamp, "Bidding has ended");
        ERC20(qbitContractAddress).transferFrom(bidder, address(this), amount);
        if(item.lastBid != 0) {
            ERC20(qbitContractAddress).transfer(bids[listingID][item.lastBid].buyer, bids[listingID][item.lastBid].amount);
        }
        item.lastBid++;
        bids[listingID][item.lastBid].buyer = bidder;
        bids[listingID][item.lastBid].amount = amount;
        bidIDs[listingID].push(item.lastBid);
        
        emit PlaceBid(bidder, listingID, amount);
    }
    
    function transferERC721Token(address to, Listing storage item) private {
        ERC721(item.contractAddress).transferFrom(address(this), to, item.tokenID);
    }

    // Getters
    function getAllListings() public view returns (Listing[] memory) {
        Listing[] memory currentListings = new Listing[](listingIDs.length);
        for(uint256 i=0; i < listingIDs.length; i++) {
            currentListings[i] = individualListings[listingIDs[i]];
        }
        return currentListings;
    }

    function getListing(uint256 listingID) public view returns (Listing memory) {
        return individualListings[listingID];
    }

    function getPlayerListings(address player) public view returns (Listing[] memory) {
        mapping(uint256 => Listing) storage playerListings = userListings[player];
        uint256[] memory pListingIDs = playerListingIDs[player];
        Listing[] memory pListings = new Listing[](pListingIDs.length);
        for(uint256 i = 0; i < pListingIDs.length; i++) {
            pListings[i] = playerListings[listingIDs[i]];
        }
        return pListings;
    }

    function getBidsForListing(uint256 listingID) public view returns(Bid[] memory) {
        Bid[] memory currentBids = new Bid[](bidIDs[listingID].length);
        for(uint256 i=0; i < bidIDs[listingID].length; i++) {
            currentBids[i] = bids[listingID][bidIDs[listingID][i]];
        }
        return currentBids;
    }
    
    function getBidByID(uint256 listingID, uint256 bidID) public view returns(Bid memory) {
        return bids[listingID][bidID];
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}