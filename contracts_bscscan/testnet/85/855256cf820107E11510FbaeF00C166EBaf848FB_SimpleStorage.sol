/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
 
contract SimpleStorage {
   
    string name;
    uint256 lastTokenId;
    uint256 lastAmmount;
    address lastBidder;
   
    function set(string memory x) public {
        name = x;
    }
    
    function bid(uint256 _tokenId, uint256 _amount) external {
        lastTokenId = _tokenId;
        lastAmmount = _amount;
        lastBidder = msg.sender;
    }
   
    function get() public view returns (string memory) {
        return name;
    }
    
    function getLastBidder() public view returns  (address) {
        return lastBidder;
    }
   
}