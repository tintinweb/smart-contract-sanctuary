/**
 *Submitted for verification at polygonscan.com on 2022-01-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



contract PAYMENTSAuto {
    


    constructor ()  {}
    
   function withdraw() public payable {
        uint256 balance = address(this).balance;
        uint256 share1 = (balance * 50) / 100;
        uint256 share2 = (balance * 50) / 100;
       

        (bool shareholder3, ) = payable(
            0x366587d3648687Bf6743A7002038aE4559ecd0CF
        ).call{value: share1}("");
        require(shareholder3);

        (bool shareholder1, ) = payable(
            0x2253081070CD746E65C9c77C6e83cfF02eedd1ef
        ).call{value: share2}("");
        require(shareholder1);


    }
}