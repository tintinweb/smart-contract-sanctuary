/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract RandomNumberConsumer {
        function random(
        uint256 number
    ) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender,number,gasleft())));
        
    }
    
    function getgaslimit() public view returns(uint256){
        return block.gaslimit;
    }
    

}