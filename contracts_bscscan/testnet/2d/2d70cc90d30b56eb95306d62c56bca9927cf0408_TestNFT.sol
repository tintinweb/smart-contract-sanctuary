/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;



contract TestNFT {
    mapping(address=>uint256) lastMintBlock;
    function mint() public {
      require(lastMintBlock[msg.sender] != block.number,"bot banned");
      lastMintBlock[msg.sender] = block.number;
    }
    
    constructor(){
        
    }
}