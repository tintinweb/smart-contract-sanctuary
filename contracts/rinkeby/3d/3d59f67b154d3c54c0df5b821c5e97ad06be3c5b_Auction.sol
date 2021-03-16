/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity ^0.7.6;
//  SPDX-License-Identifier: MIT
contract Auction {

    

  mapping(string => string)public  detail;
function recordData (string memory auctionId,string memory winnerBidId) public {
       detail[auctionId]  =winnerBidId;  
    }
    
    function getRecordData (string memory auctionId)  public view returns(string memory winnerBidId )  {
     return  detail[auctionId];      
    }


}