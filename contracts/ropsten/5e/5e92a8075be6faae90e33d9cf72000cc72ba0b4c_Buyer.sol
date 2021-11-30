/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Buyer {
    
    address[20] public Buyers;

    function buyers(uint goodId) public returns (uint) {
        require(goodId >=0 && goodId <= 19);
        Buyers[goodId] = msg.sender;

        return goodId;
    }

    function getBuyers() public view returns (address[20] memory) {
        return Buyers;
    }
}