/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract CountersTesting{
    
           function getTokenId() public payable returns (uint256 tokenId) {
               uint256 req = 10**16 wei;
               require(msg.value == req,"Error");
               return req;
           }

}