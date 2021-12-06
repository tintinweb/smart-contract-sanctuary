// SPDX-License-Identifier: GPL-3.0
import './ERC721.sol';
pragma solidity ^0.8.4;
contract SimpleAuction is ERC721 {
    address payable public artist;
    address payable public beneficiary;
    uint256 tokenId;
    uint public royaltyPercentage;
    uint public auctionEndTime;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    bool ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);


    // Errors that describe failures.
    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is already a higher or equal bid.
    error BidNotHighEnough(uint highestBid);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();
    /// The asset does not belong to the auctioneer
    error NotAssetOwner();

    constructor(
        uint biddingTime,
        address payable beneficiaryAddress,
        uint256 _tokenId,
        uint _royaltyPercentage,
        address payable _artist
    ) ERC721('My NFT', 'ABC'){
        beneficiary = beneficiaryAddress;
        tokenId = _tokenId;
        royaltyPercentage = _royaltyPercentage % 100;
        auctionEndTime = block.timestamp + biddingTime;
        artist = _artist;
        _mint(artist, 0);
    }
    function startAuction(uint biddingTime,
        address payable beneficiaryAddress,
        uint256 _tokenId) external {
        require(msg.sender == beneficiary, "not owner");
            beneficiary = beneficiaryAddress;
            tokenId = _tokenId;
            highestBid = 0;
            highestBidder = address(0);
            auctionEndTime = block.timestamp + biddingTime;
            ended = false;
    }
    function bid() external payable {
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();
        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() external {

        // 1. Conditions
        require(msg.sender == beneficiary, "not owner");
        
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        // 2. Effects
        ended = true;
        //emit AuctionEnded(highestBidder, highestBid);
        if (ownerOf(tokenId) != beneficiary){
            pendingReturns[highestBidder] += highestBid;
            revert NotAssetOwner();
        }
        transferFrom(beneficiary, highestBidder, tokenId);
        uint amountOwner = ((100-royaltyPercentage)*highestBid)/100;
        uint amountArtist = (royaltyPercentage*highestBid)/100;

        beneficiary.transfer(amountOwner);
        artist.transfer(amountArtist);

        beneficiary = payable(highestBidder);
    }


  function transferFrom(
    address from, 
    address to, 
    uint256 __tokenId
  ) public override {
     require(
       _isApprovedOrOwner(_msgSender(), tokenId), 
       'ERC721: transfer caller is not owner nor approved'
     );
     _transfer(from, to, __tokenId);
  }
}