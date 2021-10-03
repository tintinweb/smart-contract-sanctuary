/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IERC721{
    function transferFrom(address from, address to, uint tokenID) external;
}

contract MarketEvents{
  
    event Sale(
        uint indexed id,
        address indexed buyer
    );

    event Listed(
        uint indexed id,
        uint indexed price,
        address indexed seller
    );

    event Unlisted(
        uint indexed id
    );
  
    struct Listing{
        address owner;       // who owns the listed artifact
        uint256 buyoutPrice; // price of the artifact in xdai
    }
    mapping(uint256 => Listing) public listings; // all listings 
    IERC721 immutable DFTokens; 
        
    constructor(address tokensAddress){
        DFTokens = IERC721(tokensAddress);  
    }

    // sendValue from openZeppelin Address library https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function list(uint256 tokenID, uint256 price) external  {
        
        listings[tokenID] = Listing({
            owner: msg.sender,
            buyoutPrice: price
        });

        DFTokens.transferFrom(msg.sender, address(this), tokenID);
        emit Listed(tokenID,price,msg.sender);
    }

    // buying function. User input is the price they pay
    function buy(uint256 tokenID) external payable  {
        Listing memory oldListing = listings[tokenID];
        delete listings[tokenID];
        require (msg.value == oldListing.buyoutPrice, "wrong value");
        DFTokens.transferFrom(address(this), msg.sender, tokenID);
        sendValue(payable(oldListing.owner), oldListing.buyoutPrice);
        emit Sale(tokenID,msg.sender);
    }
    
    // Unlist a token you listed
    // Useful if you want your tokens back
    function unlist (uint256 id) external {
        address holder = listings[id].owner;
        require(msg.sender == holder);
        delete listings[id];
        DFTokens.transferFrom(address(this), holder, id);
        emit Unlisted(id);
    }

}