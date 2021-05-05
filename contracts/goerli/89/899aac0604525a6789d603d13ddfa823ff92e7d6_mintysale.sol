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

    event SharesUpdated(uint256 ownerShare, uint256 creatorShare);
    event NewOffer(uint256 tokenId, address owner, uint256 price, string hash);
    event SaleResubmitted(uint256 tokenId, uint256 price);
    event OfferAccepted(address buyer, uint256 tokenId, uint256 price);
    event SaleRetracted(uint256 tokenId);

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
        require(!entered,"No reentrancy please");
        entered = true;
        bytes memory data;
        Offer memory offer = items[tokenId];
        address _owner = offer.creator;
        require(offer.available,"Item not available");
        require(msg.value >= offer.price, "Price not met");
        if (offer.minted) {
            _owner = token.ownerOf(tokenId);
            token.safeTransferFrom(_owner,msg.sender,tokenId,data);
        } else {
            token.mint(msg.sender,offer.creator,tokenId,offer.itemHash);
            offer.minted = true;
        }
        offer.available = false;
        items[tokenId] = offer;
        splitFee(payable(token.creator(tokenId)), payable(_owner));
        entered = false;
        emit OfferAccepted(msg.sender, tokenId, msg.value);
    }

    function splitFee(address payable creator, address payable _owner) internal {
        uint creatorPart = msg.value * creatorPerMille / 1000;
        uint ownerPart   = msg.value * ownerPerMille / 1000;
        if (creator == _owner) {
            creator.transfer(ownerPart+creatorPart);
        } else {
            creator.transfer(creatorPart);
            _owner.transfer(ownerPart);
        }
        minty.transfer(address(this).balance);
    }


}