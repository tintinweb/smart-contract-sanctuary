/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestBlockHash {
    bytes32 public hashOfStoreBlock;
    bytes32 public hashOfPreviousBlock;

    constructor(){
        storeBlockHashes();
    }

    function storeBlockHashes() public {
       hashOfStoreBlock = blockhash(block.number);
       hashOfPreviousBlock = blockhash(block.number - 1);
    }

    function blockHash(uint256 blk) public view returns(bytes32){
        return blockHash(blk);
    }
    function blockHashRelative(uint256 offset) public view returns(bytes32){
        return blockHash(block.number-offset);
    }

}