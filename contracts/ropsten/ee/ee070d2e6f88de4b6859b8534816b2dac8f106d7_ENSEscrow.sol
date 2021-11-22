/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract ENSEscrow {
    struct Bid {
      uint256 value;
      address sender;
    }
    
    mapping(uint256 => Bid) public bids;
    

    function bid(uint256 tokenId) public payable {
        if (msg.value > bids[tokenId].value) {
            payable(bids[tokenId].sender).transfer(bids[tokenId].value);
            bids[tokenId] = Bid(msg.value, msg.sender);
        }
        else
            revert('There is an higher bid');
    }

    
    function cancel(uint256 tokenId) public {
        if (bids[tokenId].sender == msg.sender) {
            payable(msg.sender).transfer(bids[tokenId].value);
            delete bids[tokenId];
        }
    }
    
}