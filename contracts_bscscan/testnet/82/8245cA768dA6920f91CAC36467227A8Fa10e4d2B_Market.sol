// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";
import "./IERC721.sol";


/**
 * @title Owner
 * @dev Set & change owner
 */
contract Market {

    enum Side {
        Sell,
        Buy
    }

    enum OfferStatus {
        Open,
        Accepted,
        Cancelled
    }

    event NewOffer(uint id);


    struct Offer {
        uint256 tokenId;
        uint256 price;
        IERC20 dealToken;
        IERC721 nft;
        address user;
        address acceptUser;
        OfferStatus status;
        Side side;
    }
    
    Offer[] public offers;

    function addOffer(uint256 tokenId, uint256 price, address dealToken, 
        address nft, address user, Side side) public {
        uint256 id = offers.length - 1;
        Offer memory o = Offer(tokenId, price, IERC20(dealToken), IERC721(nft), 
            user, address(0), OfferStatus.Open, side);
        offers.push(o);
        emit NewOffer(id);
    }

}