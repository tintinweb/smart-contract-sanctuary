/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.7.5;
//SPDX-License-Identifier: UNLICENSED

    struct Offer {
        address  creator;
        string   itemHash;
        uint256  price;
        bool     available;
        bool     minted;
    } 

interface IMintyToken {
    function mint(address buyer, address artist,uint256 tokenId, string memory ipfsHash) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function creator(uint256 tokenId) external view returns (address);

    function tokenExists(uint256 tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view  returns (address);
}

contract mintysale {

    address                     public owner = msg.sender;
    IMintyToken                 public token;

    uint256                     public nextToken;
    mapping(uint256 => Offer)   public items; 

    bool                               entered;
    uint                        public ownerPerMille;
    uint                        public creatorPerMille;
    address payable             public minty;
    mapping(uint => mapping(address => uint256)) public bids;

    event SharesUpdated(uint256 ownerShare, uint256 creatorShare);
    event NewOffer(uint256 tokenId, address owner, uint256 price, string hash);
    event SaleResubmitted(uint256 tokenId, uint256 price);
    event OfferAccepted(address buyer, uint256 tokenId, uint256 price);
    event SaleRetracted(uint256 tokenId);

    event BidReceived(address  bidder, uint256 tokenId, uint256 bid);
    event BidIncreased(address bidder, uint256 tokenId, uint256 previous_bid, uint256 this_bid);


    event Payment(address wallet,address creator, address _owner);

    constructor(IMintyToken m, address payable wallet, uint256 opm, uint256 cpm) {
        token = m;
        minty = wallet;
        ownerPerMille = opm;
        creatorPerMille = cpm;
        emit SharesUpdated(opm, cpm);
    }

    function updateShares(uint256 opm, uint256 cpm) external {
        require(msg.sender == owner, "unauthorised");
        ownerPerMille = opm;
        creatorPerMille = cpm;
        emit SharesUpdated(opm, cpm);
    }

    function offerNew(uint256 tokenId, string memory ipfsString, uint256 price) external {
        require(!token.tokenExists(tokenId),"Invalid token ID");
        items[tokenId] = Offer(msg.sender, ipfsString,price, true,false);
        emit NewOffer(tokenId, msg.sender, price, ipfsString);
    }

    function offerSpecial(uint256 tokenId, address creator, string memory ipfsString, uint256 price) external {
        require(msg.sender == owner,"Special function, unauthorised");
        require(!token.tokenExists(tokenId),"Invalid token ID");
        items[tokenId] = Offer(creator, ipfsString,price, true,false);
        emit NewOffer(tokenId, creator, price, ipfsString);
    }

    function retractOffer(uint256 tokenId) external {
        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        if (token.tokenExists(tokenId)) {
            _owner = token.ownerOf(tokenId);
        }
        require(_owner == msg.sender,"Unauthorised");
        offer.available = false;
        items[tokenId] = offer;
        emit SaleRetracted(tokenId);
    }

    function reSubmitOffer(uint256 tokenId, uint256 price) external {
        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        if (token.tokenExists(tokenId)) {
            _owner = token.ownerOf(tokenId);
        }
        require(_owner == msg.sender,"Unauthorised");
        offer.available = true;
        offer.price = price;
        items[tokenId] = offer;
        emit SaleResubmitted(tokenId, price);
    }

    function acceptOffer(uint tokenId) external payable {
        accept(tokenId,msg.value);
    }

    function accept(uint tokenId, uint value) internal {
        require(!entered,"No reentrancy please");
        entered = true;
        bytes memory data;
        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        address _realOwner = token.ownerOf(tokenId);
        require(offer.available,"Item not available");
        require(value >= offer.price, "Price not met");
        require(_realOwner == _owner,"Item not owned by offerer");
        if (offer.minted) {
            token.safeTransferFrom(_owner,msg.sender,tokenId,data);
        } else {
            token.mint(msg.sender,offer.creator,tokenId,offer.itemHash);
            offer.minted = true;
        }
        offer.available = false;
        items[tokenId] = offer;
        emit Payment(minty,offer.creator,_owner);
        splitFee(payable(offer.creator), payable(_owner), value);
        entered = false;
        emit OfferAccepted(msg.sender, tokenId, value);
    }

    function splitFee(address payable creator, address payable _owner, uint value) internal {
        uint creatorPart = value * creatorPerMille / 1000;
        uint ownerPart   = value - creatorPart;
        if (creator == _owner) {
            creator.transfer(ownerPart+creatorPart);
        } else {
            creator.transfer(creatorPart);
            _owner.transfer(ownerPart);
        }
        minty.transfer(value - (creatorPart + ownerPart));
    }

    function makeBid(uint256 tokenId) external payable {
        Offer memory offer = items[tokenId];
        require(offer.available,"Item not available");
        uint myBid = msg.value + bids[tokenId][msg.sender];
        if (myBid > offer.price) {
            bids[tokenId][msg.sender] = 0;
            accept(tokenId, myBid);
            return;
        }
        bids[tokenId][msg.sender] = myBid;
        if (myBid == msg.value) {
            emit BidReceived(msg.sender, tokenId, myBid);
        } else {
            emit BidIncreased(msg.sender, tokenId, myBid-msg.value, msg.value);
        }
    }

    function acceptBid(uint256 tokenId, address bidder) external {
        bytes memory data;
        require(!entered,"No reentrancy please");
        entered = true;

        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        address _realOwner = token.ownerOf(tokenId);
        require(offer.available,"Item not available");
        require(_realOwner == _owner,"Item not owned by offerer");
        require(msg.sender == _owner,"Not your item to sell");
        uint256 bid = bids[tokenId][bidder];
        bids[tokenId][bidder] = 0;

        if (offer.minted) {
            token.safeTransferFrom(_owner,bidder,tokenId,data);
        } else {
            token.mint(bidder,offer.creator,tokenId,offer.itemHash);
            offer.minted = true;
        }
        offer.available = false;
        items[tokenId] = offer;
        emit Payment(minty,offer.creator,_owner);
        splitFee(payable(offer.creator), payable(_owner),bid);
        entered = false;
        emit OfferAccepted(msg.sender, tokenId, bid);
    }

    function withdrawBid(uint256 tokenId, address bidder, uint256 amount) external {
        require(!entered,"No reentrancy please");
        entered = true;
        uint256 bid = bids[tokenId][bidder];
        require(bid >= amount,"bid insufficient");



        entered = false;
    }

}