// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IERC721.sol";

contract Market{

    IERC721 public PlayCards;

    struct Offer {
        bool isForSale;
        uint tokenId;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint tokenId;
        address bidder;
        uint value;
    }

    mapping (uint => Offer) public tokensOfferedForSale;
    mapping (uint => Bid) public tokenBids;
    mapping (address => uint) public pendingWithdrawals;

    event TokenOffered(uint indexed Id, uint minValue, address indexed toAddress);
    event TokenBidEntered(uint indexed tokenId, uint value, address indexed fromAddress);
    event TokenBidWithdrawn(uint indexed tokenId, uint value, address indexed fromAddress);
    event TokenBought(uint indexed id, uint value, address indexed fromAddress, address indexed toAddress);
    event TokenNoLongerForSale(uint indexed Id);

    constructor(address tokenContractAddress){
        PlayCards = IERC721(tokenContractAddress);
    }

    function offerTokenForSale(uint256 tokenId, uint256 minSalePriceInWei) public {
        require(PlayCards.ownerOf(tokenId) == msg.sender, "market: you are not owner of this token");
        tokensOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, address(0));
        emit TokenOffered(tokenId, minSalePriceInWei, address(0));
    }

    function offerTokenForSaleToAddress(uint256 tokenId, uint256 minSalePriceInWei, address toAddress) public {
        require(PlayCards.ownerOf(tokenId) == msg.sender, "market: you are not owner of this token");
        tokensOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, toAddress);
        emit TokenOffered(tokenId, minSalePriceInWei, toAddress);
    }

    function tokenNoLongerForSale(uint256 tokenId) public {
        require(PlayCards.ownerOf(tokenId) == msg.sender, "market: you are not owner of this token");
        tokensOfferedForSale[tokenId] = Offer(false, tokenId, msg.sender, 0, address(0));
        emit TokenNoLongerForSale(tokenId);
    }

function buyToken(uint tokenId) public payable {
        Offer memory offer = tokensOfferedForSale[tokenId];
        require(offer.isForSale, "token is not for sale");
        if (offer.onlySellTo != address(0) && offer.onlySellTo != msg.sender) {
            revert("Market: not supposed to be sold to this user");
        }
        require(msg.value >= offer.minValue, "not enough eth");
        require(offer.seller == PlayCards.ownerOf(tokenId), "seller no longer owner of token");

        address seller = offer.seller;

        PlayCards.safeTransferFrom(seller, msg.sender, tokenId);
        pendingWithdrawals[seller] += msg.value;
        tokenNoLongerForSale(tokenId);
        emit TokenBought(tokenId, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = tokenBids[tokenId];
        if (bid.bidder == msg.sender) {
            // Kill the bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            tokenBids[tokenId] = Bid(false, tokenId, address(0), 0);
        }
    }

    function enterBidForToken(uint tokenId) public payable {
        require(PlayCards.ownerOf(tokenId) != msg.sender, "you already owned this token");
        require(msg.value != 0, "zero bid value");
        Bid memory existing = tokenBids[tokenId];
        require(msg.value >= existing.value, "you have to bid at least equal to existing bid");
        if (existing.value > 0) {
            // refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        tokenBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
        emit TokenBidEntered(tokenId, msg.value, msg.sender);
    }

    function withdrawBidForToken(uint tokenId) public {
        require(PlayCards.ownerOf(tokenId) != msg.sender, "you already owned this token");
        Bid memory bid = tokenBids[tokenId];
        require(bid.bidder == msg.sender, "you have not bid for this token");
        
        emit TokenBidWithdrawn(tokenId, bid.value, msg.sender);
        tokenBids[tokenId] = Bid(false, tokenId, address(0), 0);
        // refund the bid money
        address payable reciever = payable(msg.sender);
        reciever.transfer(bid.value);
    }

    function acceptBidForToken(uint tokenId, uint minPrice) public {
        require(PlayCards.ownerOf(tokenId) == msg.sender, "market: you are not owner of this token");
        Bid memory bid = tokenBids[tokenId];
        require(bid.value != 0, "there is no bid for this token");
        require(bid.value >= minPrice, "the bid value is lesser than minPrice");
        address seller = msg.sender;
        PlayCards.safeTransferFrom(seller, bid.bidder, tokenId);

        tokensOfferedForSale[tokenId] = Offer(false, tokenId, bid.bidder, 0, address(0));
        tokenBids[tokenId] = Bid(false, tokenId, address(0), 0);
        pendingWithdrawals[seller] += bid.value;
        emit TokenBought(tokenId, bid.value, seller, bid.bidder);
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        address payable reciever = payable(msg.sender);
        reciever.transfer(amount);
    }
    
    function ownerOf(uint256 tokenId) public view returns(address) {
        return PlayCards.ownerOf(tokenId);
    } 
    
    function balanceOf(address owner_) public view returns(uint256) {
        return PlayCards.balanceOf(owner_);
    } 
}