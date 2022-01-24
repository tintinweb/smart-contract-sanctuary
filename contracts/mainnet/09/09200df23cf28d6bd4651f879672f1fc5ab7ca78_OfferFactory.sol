// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {Ownable} from "./Ownable.sol";
import {LockedWETHOffer} from "./LockedWETHOffer.sol";

contract OfferFactory is Ownable {
    uint256 public fee = 30; // in bps
    LockedWETHOffer[] public offers;

    event OfferCreated(address offerAddress, address tokenWanted, uint256 amountWanted);

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function createOffer(address _tokenWanted, uint256 _amountWanted) public returns (LockedWETHOffer) {
        LockedWETHOffer offer = new LockedWETHOffer(msg.sender, _tokenWanted, _amountWanted, fee);
        offers.push(offer);
        emit OfferCreated(address(offer), _tokenWanted, _amountWanted);
        return offer;
    }

    function getActiveOffersByOwner() public view returns (LockedWETHOffer[] memory, LockedWETHOffer[] memory) {
        LockedWETHOffer[] memory myBids = new LockedWETHOffer[](offers.length);
        LockedWETHOffer[] memory otherBids = new LockedWETHOffer[](offers.length);

        uint256 myBidsCount;
        uint256 otherBidsCount;
        for (uint256 i; i < offers.length; i++) {
            LockedWETHOffer offer = LockedWETHOffer(offers[i]);
            if (offer.hasWETH() && !offer.hasEnded()) {
                if (offer.seller() == msg.sender) {
                    myBids[myBidsCount++] = offers[i];
                } else {
                    otherBids[otherBidsCount++] = offers[i];
                }
            }
        }

        return (myBids, otherBids);
    }

    function getActiveOffers() public view returns (LockedWETHOffer[] memory) {
        LockedWETHOffer[] memory activeOffers = new LockedWETHOffer[](offers.length);
        uint256 count;
        for (uint256 i; i < offers.length; i++) {
            LockedWETHOffer offer = LockedWETHOffer(offers[i]);
            if (offer.hasWETH() && !offer.hasEnded()) {
                activeOffers[count++] = offer;
            }
        }

        return activeOffers;
    }

    function getActiveOffersByRange(uint256 start, uint256 end) public view returns (LockedWETHOffer[] memory) {
        LockedWETHOffer[] memory activeOffers = new LockedWETHOffer[](end - start);

        uint256 count;
        for (uint256 i = start; i < end; i++) {
            if (offers[i].hasWETH() && !offers[i].hasEnded()) {
                activeOffers[count++] = offers[i];
            }
        }

        return activeOffers;
    }
}