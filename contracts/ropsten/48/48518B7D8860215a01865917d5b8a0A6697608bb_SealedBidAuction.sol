/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7 <0.9.0;


contract SealedBidAuction {
    function generateSealedBid(uint _bidAmount , bool _isLegit , string memory _secret ) public pure returns( bytes32 sealedBid ) {
    sealedBid = keccak256( abi . encodePacked(_bidAmount , _isLegit , _secret )) ;
    }
}