/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract EtherTemple {
    string latestWish = "take us to mars";
    uint countWishes = 0;

    event WishMade(string w);
    
    function makeWish(string memory w) public {
        countWishes += 1;
        latestWish = w;
        emit WishMade(w);
    }

    function getLastWish() public view returns (string memory) {
        return latestWish;
    }
    
    function getTitle() public pure returns (string memory) {
        return "infiloop's Temple";
    }
    
    function getCountWishes() public view returns (uint) {
        return countWishes;
    }
}