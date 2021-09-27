/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
//import "./SafeMath.sol";
contract BookMarketPlace {
   // using SafeMath for uint256;
       // state
       
       mapping(uint256 => Book) public bookById;
       mapping(uint256 => Buyer[]) private RequestsById;
       
       // book represent by id 
       uint256 private id = 0;
       
       
       struct Book {
           string name;
           uint256 price;
           uint256 id;
           address owner;
       }
       struct Buyer {
           address requester;
           uint256 offerAmount;
       }
       
       // events
       event BookListed(string bookName,uint256 price,uint256 id,address owner);
       event BookPurchased(string bookName,uint256 soldAt,address newOwner);
       event OfferReceived(string bookName, uint256 offerAmount, address by);
       
       // @notice function to list book on Marketplace
       // @param1: _name: set book name
       // @param2: _price: set book price
       function sellBook(string memory _name, uint256 _price) public returns(bool success){
           
           Book memory obj = Book(_name, _price, id, msg.sender);
           bookById[id] = obj;
           emit BookListed(_name, _price, id, msg.sender);
           
           //id = id.add(1);
           id++;
           success = true;
       }
       
       // @notice buyer submit request with desired offer, 
       // If offer matches with seller demand price, new owner will be buyer 
       // @param1: _id: book id to request on
       // param2: _offerAmount: set desired offer
       function buyRequest(uint256 _id, uint256 _offerAmount) public payable returns(bool success){
          // pointer to book 
          Book memory book = bookById[_id];
          
          // book should be on sell 
          require(book.owner != address(0),"buyRequest: book not listed");
          
           if(_offerAmount == book.price){
               // check If buyer is serious
               require(msg.value >= book.price, "buyRequest: amount should be valid");
               payable(book.owner).transfer(msg.value); //
               
               //delete requests;
               delete RequestsById[_id];
               
               // delete book from listing
               delete bookById[_id];
               
               emit BookPurchased(book.name,book.price, msg.sender);
               success = true;
           }
           else {
            Buyer memory obj = Buyer(msg.sender, _offerAmount);
            RequestsById[_id].push(obj);
            emit OfferReceived(book.name, _offerAmount, msg.sender);
            success = true;
           }
           
       }
       function checkRequests(uint256 _id) public view returns(Buyer[] memory) {
           return RequestsById[_id];
       }
       
}