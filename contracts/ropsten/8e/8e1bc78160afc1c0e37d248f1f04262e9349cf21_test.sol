/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

contract test{ 
    
      struct AUCTION  {
        
      
        // Auction_clossed false empty or ended   1 auction goingon
        bool auctionStatut;
        
        // seller address
        address seller;
        
        // starting price
        uint256 startingPrice;
        
        // Auction started
        uint256 auctionTimestamp;
        
        // Auction duration
        uint256 auctionDuration;
        
        // bond_address
        address bondAddress;
            
        // Bonds
        uint256[] bondClass;
        
        // Bonds
        uint256[] bondNonce;
        
        // Bonds
        uint256[] bondAmount;
        
    }
    
    
    AUCTION[] public idToCatalogue;
    
    constructor() public{

        for (uint i=0; i<10000; i++) {
          idToCatalogue.push();
        }
               
        
        
    }
    

        
    function getAuction(uint256 indexStart, uint256 indexEnd) view public returns(AUCTION[] memory){
        require(indexStart<indexEnd);
        uint256 listLength= indexEnd - indexStart +1;
        require(listLength<10000);
        
        AUCTION[] memory auctionList = new AUCTION[](listLength);
        
        for (uint i = 0; i<listLength; i++) {
            auctionList[i]=idToCatalogue[i];
            
        }
        
        return(auctionList);
    }

}