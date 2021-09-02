/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract RandomNumberConsumer {
        function random(uint256 nonce) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, blockhash(1), nonce, block.gaslimit, block.coinbase, block.timestamp , gasleft())))%100;
        
    }
    
    function getgaslimit() public view returns(uint256){
        return block.gaslimit;
    }
    

}