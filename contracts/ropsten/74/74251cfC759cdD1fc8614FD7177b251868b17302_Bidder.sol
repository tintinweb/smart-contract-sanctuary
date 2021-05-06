/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.6.0;

contract Bidder {
    
    //anyone can check his/her own bid based on his/her address
    mapping(address => Bid) public myBids;
    address[] AddressBook;

    struct Bid {
        uint bid;
        string name;
    }
    
    //add your bid based on your address
    function addMyBid(uint bid, string memory _name) public {
        myBids[msg.sender] = Bid(bid, _name);
    }
    
    //add your address to the address book
    function addMyAddress(address _address) public {
        AddressBook.push(_address);
    }
    
    //finds the biggest bid and provides the winner's name
    function countBestBid() public view returns (string memory) {
        string memory bidder = "none";
        uint bid_counter = 0;
        address sender;
        
        for(uint i = 0; i < AddressBook.length; i++) {
            sender = AddressBook[i];
            if(myBids[msg.sender].bid > bid_counter ) {
                bid_counter = myBids[msg.sender].bid;
                bidder = myBids[msg.sender].name;
            }
        }
        
        return bidder;
    }
    
}