// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721.sol";

contract Market{

enum ListingStatus{
    Active,
    Sold,
    Cancelled
}

struct Listing{
    ListingStatus status;
    address seller;
    address token;
    uint tokenid;
    uint price;
}

mapping(uint => Listing)private _listings;
uint private _listingId=0;

//listToken events
event Listed(
    uint listingId,
    address seller,
    address token,
    uint tokenid,
    uint price
);
//buytoken event
event Sale(
    address seller,
    address buyer,
    uint price,
    uint listingId,
    address token,
    uint tokeni
);

//cancel token event

event cancelled(
    uint ListingId,
    address sender
);

   function ListToken(address token,uint tokenid,uint price) external{
       IERC721(token).transferFrom(msg.sender, address(this), tokenid);
       Listing memory listing=
       Listing(
           ListingStatus.Active,
            msg.sender ,
           token,
           tokenid,
           price);
      
      _listingId++;
      
      _listings[_listingId]=listing;
      emit Listed(_listingId, msg.sender, token, tokenid, price);
   }
  
  function getListing(uint listingId) public view returns (Listing memory){
      return _listings[listingId];
  }

   function buyToken(uint listingId) external payable{
       Listing storage listing=_listings[listingId];

       require(msg.sender != listing.seller,"Owner cannot buy tokens");
       require(msg.value >= listing.price,"insufficient amount");
       require(listing.status==ListingStatus.Active,"Listing is not Active");
       
       
       listing.status=ListingStatus.Sold;
       IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenid);
      payable(listing.seller).transfer(listing.price);
      emit Sale(listing.seller,msg.sender,listing.price,listingId,listing.token,listing.tokenid);
   }

   function cancel(uint listingId) public{
    Listing storage listing=_listings[listingId];

    require(msg.sender==listing.seller,"only seller can cancel the listing");
    require(listing.status==ListingStatus.Active,"listing is not active");

    listing.status=ListingStatus.Cancelled;
     IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenid);
     emit cancelled(listingId, msg.sender);
   }

}