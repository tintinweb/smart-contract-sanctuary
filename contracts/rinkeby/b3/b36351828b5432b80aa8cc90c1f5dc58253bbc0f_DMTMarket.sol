// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title: DMT Market
/// @author: www.sadat.pk

import "./IERC1155Interface.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                          ░░░░░░░░░  ░░░░░░░░░  ░░░░░░░░   ░░░░░░░░               //
//                         ░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░              //
//                        ░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░         //
//                       ░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░        //
//                      ░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░        //
//                   ░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░         //
//                 ░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░            //
//                ░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░           //
//               ░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░          //
//                ░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░          //
//                 ░░░░░░░░░░░   ░░░░░░░░░ ░░░░░░░░░  ░░░░░░░░░  ░░░░░░░░░          //
//                    ░░░░░░       ░░░░       ░░░░       ░░░       ░░░░             //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////

contract DMTMarket {
    uint256 private _listingId = 0;
	mapping(uint256 => Listing) private _listings;
    mapping(address => uint256) public balances;

    struct Listing {
    address contractAddr;
    uint256 tokenId;
    uint256 amount;
    uint256 price;
    address seller;
    }
    function list(address contractAddr, uint256 tokenId, uint256 amount, uint256 price) public {
        require(IERC1155(contractAddr).balanceOf(msg.sender, tokenId) >= amount, "must own enough supply");
        require(IERC1155(contractAddr).isApprovedForAll(msg.sender, address(this)), "contract not approved");
        Listing memory listing = Listing(contractAddr, tokenId, amount, price, msg.sender);
		_listingId++;
		_listings[_listingId] = listing;
    }
    function getlisting(uint256 listingId) public view returns (Listing memory) {
		return _listings[listingId];
	}

    function buy(uint256 listingId, uint256 amount) external payable {
		Listing storage listing = _listings[listingId];
		require(msg.sender != listing.seller, "seller cannot be buyer");
        require(IERC1155(listing.contractAddr).balanceOf(listing.seller, listing.tokenId) >= amount, "not enough supply");
        require(msg.value >= listing.price * amount, "insufficient eth sent");
        balances[listing.seller] += msg.value;
        IERC1155(listing.contractAddr).safeTransferFrom(listing.seller, msg.sender, listing.tokenId, amount, "");
        listing.amount = listing.amount - amount;

	}

    function withdraw(uint256 amount, address payable destAddr) public {
        require(amount <= balances[msg.sender], "insufficient funds");
        balances[msg.sender] -= amount;
        destAddr.transfer(amount);
    }
}