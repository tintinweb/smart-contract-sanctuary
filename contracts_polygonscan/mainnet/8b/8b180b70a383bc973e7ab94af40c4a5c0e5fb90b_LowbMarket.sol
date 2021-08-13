// contracts/LowbMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721LOWB.sol";
import "./IWallet.sol";

contract LowbMarket {

    address public walletAddress;

    address public owner;

    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 10000;
    uint public fee;
    
    struct Offer {
        bool isForSale;
        uint itemId;
        address seller;
        uint minValue;          // in lowb
        address onlySellTo;     // specify to sell only to a specific person
    }
    
    struct RentOffer {
        bool isForRent;
        uint itemId;
        address owner;
        uint minValue;          // in lowb
        uint rentDays;
    }
    
    struct Bid {
        address prevBidder;
        address nextBidder;
        uint value;
    }
    
    mapping (address => uint) public royaltyOf;
    mapping (address => mapping (uint => Offer)) public itemsOfferedForSale;
    mapping (address => mapping (uint => RentOffer)) public itemsOfferedForRent;
    mapping (address => mapping (uint => mapping (address => Bid))) public itemBids;
    mapping (address => mapping (address => uint[])) private _punkHolds;
    
    event ItemNoLongerForSale(address indexed nftAddress, uint indexed itemId);
    event ItemNoLongerForRent(address indexed nftAddress, uint indexed itemId);
    event ItemOffered(address indexed nftAddress, uint indexed itemId, uint minValue);
    event ItemOfferedForRent(address indexed nftAddress, uint indexed itemId, uint minValue, uint rentDays);
    event ItemBought(address indexed nftAddress, uint indexed itemId, uint value, address fromAddress, address toAddress);
    event ItemRent(address indexed nftAddress, uint indexed itemId, uint value, uint rentDays, address fromAddress, address toAddress);
    event NewBidEntered(address indexed nftAddress, uint indexed itemId, uint value, address indexed fromAddress);
    event BidWithdrawn(address indexed nftAddress, uint indexed itemId, uint value, address indexed fromAddress);


    constructor(address wallet_) {
        walletAddress = wallet_;
        owner = msg.sender;
        fee = 250;
    }
    
    function getTotalHolds(address nftAddress, address holder) public view returns (uint) {
      uint n = 0;
      IERC721LOWB token = IERC721LOWB(nftAddress);
      for (uint i=0; i<token.totalSupply(); i++) {
        if (token.holderOf(i) == holder) {
          n++;
        }
      }
      return n;
    }
    
    function getPunkHolds(address nftAddress, address holder) public view returns (uint[] memory) {
      uint n = getTotalHolds(nftAddress, holder);
      uint j = 0;
      uint[] memory punkHolds = new uint[](n);
      IERC721LOWB token = IERC721LOWB(nftAddress);
      for (uint i=0; i<token.totalSupply(); i++) {
        if (token.holderOf(i) == holder) {
          punkHolds[j] = i;
          j++;
        }
      }
      return punkHolds;
    }
    
    function offerItemForRent(address nftAddress, uint itemId, uint minRentPriceInWei, uint rentDays) public {
        IERC721LOWB token = IERC721LOWB(nftAddress);
        require(token.ownerOf(itemId) == msg.sender, "You don't own this token.");

        itemsOfferedForRent[nftAddress][itemId] = RentOffer(true, itemId, msg.sender, minRentPriceInWei, rentDays);
        emit ItemOfferedForRent(nftAddress, itemId, minRentPriceInWei, rentDays);
    }
    
    function itemNoLongerForRent(address nftAddress, uint itemId) public {
        IERC721LOWB token = IERC721LOWB(nftAddress);
        require(token.ownerOf(itemId) == msg.sender, "You don't own this token.");

        itemsOfferedForRent[nftAddress][itemId] = RentOffer(false, itemId, msg.sender, 0, 0);
        emit ItemNoLongerForRent(nftAddress, itemId);
    }
    
    function offerItemForSale(address nftAddress, uint itemId, uint minSalePriceInWei) public {
        IERC721LOWB token = IERC721LOWB(nftAddress);
        require(token.ownerOf(itemId) == msg.sender && token.holderOf(itemId) == msg.sender, "You don't own this token.");
        require(token.getApproved(itemId) == address(this), "Approve this token first.");

        itemsOfferedForSale[nftAddress][itemId] = Offer(true, itemId, msg.sender, minSalePriceInWei, address(0));
        emit ItemOffered(nftAddress, itemId, minSalePriceInWei);
    }
    
    function itemNoLongerForSale(address nftAddress, uint itemId) public {
        IERC721LOWB token = IERC721LOWB(nftAddress);
        require(token.ownerOf(itemId) == msg.sender, "You don't own this token.");

        itemsOfferedForSale[nftAddress][itemId] = Offer(false, itemId, msg.sender, 0, address(0));
        emit ItemNoLongerForSale(nftAddress, itemId);
    }
    
    function _makeDeal(address buyer, address seller, uint amount, address nftAddress) private {
        IERC721LOWB nft = IERC721LOWB(nftAddress);
        uint royalty = royaltyOf[nftAddress];
        uint fee_amount = amount / INVERSE_BASIS_POINT * fee;
        uint royalty_amount = amount / INVERSE_BASIS_POINT * royalty;
        uint actual_amount = amount - fee_amount - royalty_amount;
        address creator = nft.owner();
        require(actual_amount > 0, "Fees should less than the transaction value.");
        
        IWallet wallet = IWallet(walletAddress);
        wallet.award(creator, royalty_amount);
        wallet.award(owner, fee_amount);
        wallet.award(seller, actual_amount);
        
        _punkHolds[nftAddress][seller] = getPunkHolds(nftAddress, seller);
        _punkHolds[nftAddress][buyer] = getPunkHolds(nftAddress, buyer);
    }
    
    function rentItem(address nftAddress, uint itemId, uint amount, uint rentDays) public {
        RentOffer memory offer = itemsOfferedForRent[nftAddress][itemId];
        require(offer.isForRent, "This item not actually for rent.");
        require(amount >= offer.minValue, "You didn't send enough LOWB.");
        require(rentDays <= offer.rentDays, "You didn't send enough LOWB.");
        
        IWallet wallet = IWallet(walletAddress);
        require(wallet.balanceOf(msg.sender) >= amount*rentDays, "Please deposit enough lowb to rent this item!");
        
        wallet.use(msg.sender, amount*rentDays);

        IERC721LOWB nft = IERC721LOWB(nftAddress);
        require(nft.holderOf(itemId) == offer.owner || nft.holderOf(itemId) == msg.sender, "This item is on rent.");
        
        nft.setHolder(itemId, msg.sender, rentDays);
        
        _makeDeal(msg.sender, offer.owner, amount*rentDays, nftAddress);
        emit ItemRent(nftAddress, itemId, amount, rentDays, offer.owner, msg.sender);
    }
    
    function buyItem(address nftAddress, uint itemId, uint amount) public {
        Offer memory offer = itemsOfferedForSale[nftAddress][itemId];
        require(offer.isForSale, "This item not actually for sale.");
        require(amount >= offer.minValue, "You didn't send enough LOWB.");
        
        IWallet wallet = IWallet(walletAddress);
        require(wallet.balanceOf(msg.sender) >= amount, "Please deposit enough lowb to buy this item!");
        
        wallet.use(msg.sender, amount);

        IERC721LOWB nft = IERC721LOWB(nftAddress);
        address seller = offer.seller;
        require(nft.ownerOf(itemId) == seller && nft.holderOf(itemId) == seller, "Seller no longer owner of this item.");
        
        nft.safeTransferFrom(seller, msg.sender, itemId);

        itemNoLongerForSale(nftAddress, itemId);

        _makeDeal(msg.sender, seller, amount, nftAddress);
        emit ItemBought(nftAddress, itemId, amount, seller, msg.sender);
    }
    
    function enterBid(address nftAddress, uint itemId, uint amount) public {
        IWallet wallet = IWallet(walletAddress);
        require(wallet.balanceOf(msg.sender) >= amount, "Please deposit enough lowb before bid!");
        require(amount > 0, "Please bid with some lowb!");

        IERC721LOWB nft = IERC721LOWB(nftAddress);
        require(nft.ownerOf(itemId) != address(0), "Token not created yet.");

        require(itemBids[nftAddress][itemId][msg.sender].value == 0, "You've already entered a bid!");

        // Lock the current bid
        wallet.use(msg.sender, amount);
        address latestBidder = itemBids[nftAddress][itemId][address(0)].nextBidder;
        itemBids[nftAddress][itemId][latestBidder].prevBidder = msg.sender;
        itemBids[nftAddress][itemId][msg.sender] = Bid(address(0), latestBidder, amount);
        itemBids[nftAddress][itemId][address(0)].nextBidder = msg.sender;

        emit NewBidEntered(nftAddress, itemId, amount, msg.sender);
    }
    
    function acceptBid(address nftAddress, uint itemId, address bidder) public {
        IERC721LOWB token = IERC721LOWB(nftAddress);
        require(token.ownerOf(itemId) == msg.sender && token.holderOf(itemId) == msg.sender, "You don't own this token.");
        require(token.getApproved(itemId) == address(this), "Approve this token first.");
        
        address seller = msg.sender;
        uint amount = itemBids[nftAddress][itemId][bidder].value;
        require(amount > 0, "No bid from this address for this item yet.");

        token.safeTransferFrom(seller, bidder, itemId);
        itemsOfferedForSale[nftAddress][itemId] = Offer(false, itemId, bidder, 0, address(0));

        itemBids[nftAddress][itemId][bidder].value = 0;
        address nextBidder = itemBids[nftAddress][itemId][bidder].nextBidder;
        address prevBidder = itemBids[nftAddress][itemId][bidder].prevBidder;
        itemBids[nftAddress][itemId][prevBidder].nextBidder = nextBidder;
        itemBids[nftAddress][itemId][nextBidder].prevBidder = prevBidder;
        
        _makeDeal(bidder, seller, amount, nftAddress);
        
        emit ItemBought(nftAddress, itemId, amount, seller, bidder);
    }
    
    function withdrawBid(address nftAddress, uint itemId) public {
        uint amount = itemBids[nftAddress][itemId][msg.sender].value;
        require(amount > 0, "You don't have a bid for it.");
        
        itemBids[nftAddress][itemId][msg.sender].value = 0;
        address nextBidder = itemBids[nftAddress][itemId][msg.sender].nextBidder;
        address prevBidder = itemBids[nftAddress][itemId][msg.sender].prevBidder;
        itemBids[nftAddress][itemId][prevBidder].nextBidder = nextBidder;
        itemBids[nftAddress][itemId][nextBidder].prevBidder = prevBidder;
        // Refund the bid money
        IWallet wallet = IWallet(walletAddress);
        wallet.award(msg.sender, amount);
        
        emit BidWithdrawn(nftAddress, itemId, amount, msg.sender);
    }

    
    function setRoyalty(address nftAddress, uint royalty) public {
        IERC721LOWB nft = IERC721LOWB(nftAddress);
        require(msg.sender == nft.owner(), "Only owner can set the royalty!");
        require(royalty <= 1000, "Royalty too high!");
        royaltyOf[nftAddress] = royalty;
    }
    
    function getOffers(address nftAddress, uint from, uint to) public view returns (Offer[] memory) {
        require(to >= from, "Invalid index");
        IERC721LOWB token = IERC721LOWB(nftAddress);
        Offer[] memory offers = new Offer[](to-from+1);
        for (uint i=from; i<=to; i++) {
            offers[i-from] = itemsOfferedForSale[nftAddress][i];
            if (token.ownerOf(i) != offers[i-from].seller || token.holderOf(i) != offers[i-from].seller) {
              offers[i-from].isForSale = false;
            }
        }
        return offers;
    }
    
    function getBidsOf(address nftAddress, address user, uint from, uint to) public view returns (Bid[] memory) {
        require(to >= from, "Invalid index");
        Bid[] memory bids = new Bid[](to-from+1);
        for (uint i=from; i<=to; i++) {
            bids[i-from] = itemBids[nftAddress][i][user];
        }
        return bids;
    }
    
    function getHighestBids(address nftAddress, uint from, uint to) public view returns (Bid[] memory) {
        require(to >= from, "Invalid index");

        Bid[] memory bids = new Bid[](to-from+1);
        LowbMarket.Bid memory bid;
        for (uint i=from; i<=to; i++) {
            bid = itemBids[nftAddress][i][address(0)];
            while (bid.nextBidder != address(0)) {
                bid = itemBids[nftAddress][i][bid.nextBidder];
                if (bid.value >= bids[i-from].value) {
                    bids[i-from] = bid;
                }
            }
        }
        return bids;
    }

}