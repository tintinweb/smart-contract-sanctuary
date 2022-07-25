//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

import "./LandSale.sol";
import "./IERC20.sol";

contract LandSaleMarket is LandSale {

    event PlotListed(uint256 indexed plotId, address indexed seller, uint256 price);
    event PlotPriceChanged(uint256 indexed plotId, address indexed seller, uint256 oldPrice, uint256 newPrice);
    event PlotDelisted(uint256 indexed plotId, address indexed seller);
    event PlotPurchased(uint256 indexed plotId, address indexed seller, address indexed buyer, uint256 price);
    event OfferMade(uint256 indexed plotId, address indexed buyer, uint256 price);
    event OfferCancelled(uint256 indexed plotId, address indexed buyer, uint256 price);
    event EscrowReturned(address indexed buyer, uint256 value);
    event PlotTransferred(uint256 indexed plotIds, address indexed oldOwner, address indexed newOwner);

    struct Listing {
        uint256 price;
        uint256 timestamp;
    }

    struct Offer {
        address buyer;
        uint256 price;
        uint256 timestamp;
        bool cancelled;
    }

    bool private _pausedSales;
    bool private _pausedTransfers;
    uint256 private _creatorFee;

    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => Offer[]) private _offers;
    mapping(address => uint256) private _claimableEscrow;

    constructor(uint256 commonPrice, uint256 rarePrice, uint256 epicPrice, uint256 creatorFee)
        LandSale(commonPrice, rarePrice, epicPrice)
    {
        _creatorFee = creatorFee;
        _pausedSales = true;
        _pausedTransfers = true;
    }

    modifier notPaused () {
        require(!_pausedSales, "Sales are paused");
        _;
    }

    // Setings
    function setPausedSales(bool paused) external onlyOwnerOrAdmin {
        _pausedSales = paused;
    }
    function setPausedTransfers(bool paused) external onlyOwnerOrAdmin {
        _pausedTransfers = paused;
    }

    function setCreatorFee(uint256 creatorFee) external onlyOwnerOrAdmin {
        _creatorFee = creatorFee;
    }

    function getPausedSales() external view returns (bool) {
        return _pausedSales;
    }

    function getPausedTransfers() external view returns (bool) {
        return _pausedTransfers;
    }

    function getCreatorFee() external view returns (uint256) {
        return _creatorFee;
    }

    // List - Buy - Offer

    function list(uint256 plotId, uint256 price) external onlyPlotOwner(plotId) notPaused {
        require(price > 0, "Price must be greater than 0");
        _listings[plotId] = Listing(price, block.timestamp);

        emit PlotListed(plotId, msg.sender, price);
    }

    function changePrice(uint256 plotId, uint256 newPrice) external onlyPlotOwner(plotId) {
        require(newPrice > 0, "Price must be greater than 0");
        uint oldPrice = _listings[plotId].price;
        require(oldPrice > 0, "Not listed");
        _listings[plotId].price = newPrice;

        emit PlotPriceChanged(plotId, msg.sender, oldPrice, newPrice);
    }

    function delist(uint256 plotId) external onlyPlotOwner(plotId) {
        _delist(plotId, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        emit PlotDelisted(plotId, msg.sender);
    }

    function _delist(uint256 plotId, uint256 doNotReturnIndex) private {
        delete _listings[plotId];
        Offer[] memory offers = _offers[plotId];
        uint numOffers = offers.length;
        for (uint i; i<numOffers;) {
            if (!offers[i].cancelled && i != doNotReturnIndex) {
                _claimableEscrow[offers[i].buyer] += offers[i].price;
            }
            unchecked { ++i; }
        }
        delete _offers[plotId];
    }

    function buy(uint256 plotId, uint256 price) external notPaused {
        Listing memory listing = _listings[plotId];
        require(listing.price > 0, "Not listed");
        IERC20 rmrkToken = IERC20(xcRMRK);
        require(rmrkToken.allowance(msg.sender, address(this)) >= listing.price, "Not enough allowance");
        require(price == listing.price, "Price does not match");

        _delist(plotId, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        address previousOwner = getPlotOwner(plotId);
        setPlotOwner(msg.sender, plotId);
        (uint pay, uint fee) = _getPayAndFee(listing.price);
        rmrkToken.transferFrom(msg.sender, previousOwner, pay);
        rmrkToken.transferFrom(msg.sender, beneficiary, fee);

        emit PlotPurchased(plotId, previousOwner, msg.sender, price);
    }

    function makeOffer(uint256 plotId, uint256 price) external notPaused {
        require(price > 0, "Price must be higher than 0");
        require(msg.sender != getPlotOwner(plotId), "User is land owner");

        Listing memory listing = _listings[plotId];
        require(listing.price > 0, "Not listed");
        require(price < listing.price, "Offer over listed price");

        IERC20 rmrkToken = IERC20(xcRMRK);
        require(rmrkToken.allowance(msg.sender, address(this)) >= price, "Not enough allowance");

        Offer memory offer = Offer(msg.sender, price, block.timestamp, false);
        _offers[plotId].push(offer);
        rmrkToken.transferFrom(msg.sender, address(this), price);

        emit OfferMade(plotId, msg.sender, price);
    }

    function cancelOffer(uint256 plotId, uint256 offerIndex) external {
        require(offerIndex < _offers[plotId].length, "Offer index out of range");
        Offer memory offer = _offers[plotId][offerIndex];
        require(msg.sender == offer.buyer, "User is not offer owner");
        require(!offer.cancelled, "Offer already cancelled");

        _claimableEscrow[offer.buyer] += offer.price;
        _offers[plotId][offerIndex].cancelled = true;

        emit OfferCancelled(plotId, msg.sender, offer.price);
    }

    function getOffers(uint256 plotId) external view returns(Offer[] memory) {
        return _offers[plotId];
    }

    function acceptOffer(uint256 plotId, uint256 offerIndex, uint256 price) external onlyPlotOwner(plotId) notPaused {
        require(offerIndex < _offers[plotId].length, "Offer index out of range");
        Offer memory offer = _offers[plotId][offerIndex];
        require(!offer.cancelled, "Offer already cancelled");
        require(offer.price == price, "Price does not match");

        _delist(plotId, offerIndex);
        setPlotOwner(offer.buyer, plotId);

        IERC20 rmrkToken = IERC20(xcRMRK);
        (uint pay, uint fee) = _getPayAndFee(offer.price);
        rmrkToken.transfer(msg.sender, pay);
        rmrkToken.transfer(beneficiary, fee);
        emit PlotPurchased(plotId, msg.sender, offer.buyer, price);
    }

    function returnEscrowed() external {
        uint256 returnValue = _claimableEscrow[msg.sender];
        require(returnValue > 0, "No escrow to return");
        IERC20(xcRMRK).transfer(msg.sender, returnValue);

        emit EscrowReturned(msg.sender, returnValue);
    }

    // Transfer

    function transfer(uint plotId, address newOwner) external onlyPlotOwner(plotId) {
        require(newOwner != msg.sender, "Cannot transfer to self");
        require(!_pausedTransfers, "Transfers are paused");
        require(_listings[plotId].price == 0, "Cannot transfer listed plot");

        setPlotOwner(newOwner, plotId);
        emit PlotTransferred(plotId, msg.sender, newOwner);
    }

    // Utilities
    function getIsListed(uint256 plotId) external view returns (bool) {
        return _listings[plotId].price > 0; 
    }

    function getListedInfo(uint256 plotId) external view returns (uint256, uint256) {
        Listing memory listing = _listings[plotId];
        require(listing.price > 0, "Not listed");
        return (listing.price, listing.timestamp);
    }

    function getListedPrice(uint256 plotId) external view returns (uint256) {
        uint256 price = _listings[plotId].price;
        require(price > 0, "Not listed");
        return price;
    }

    function getCurrentBid(uint256 plotId) external view returns (uint256) {
        require(_listings[plotId].price > 0, "Not listed");
        Offer[] memory offers = _offers[plotId];
        uint numOffers = offers.length;
        uint currentBid = 0;
        for (uint i; i<numOffers;) {
            if (!offers[i].cancelled && offers[i].price > currentBid) {
                currentBid = offers[i].price;
            }
            unchecked { ++i; }
        }
        return currentBid;
    }

    function getClaimableEscrow() external view returns (uint256) {
        return _claimableEscrow[msg.sender];
    }

    function _getPayAndFee(uint256 price) private view returns (uint256, uint256) {
        uint256 fee = uint256(price * _creatorFee) / _PRICE_PRECISION;
        uint256 pay = uint256(price - fee);
        return (pay, fee);
    }

}