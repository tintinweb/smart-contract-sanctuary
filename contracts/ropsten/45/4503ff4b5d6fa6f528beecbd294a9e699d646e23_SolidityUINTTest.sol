/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract SolidityUINTTest {
    string[] public strings;
    uint private count = 0;
    uint private pseudo_random_counter = 0;
    
    function AddRandomQuotesOfTheDay() public {
        strings.push("Play Team Fortress 2, it's free!");
        strings.push("Buy Team Fortress, it's not free!");
    }
    
    function inc() public {
        count += 1;
        pseudo_random_counter = count%strings.length;
    }
    
    function Result() public view returns(string memory) {
        return strings[pseudo_random_counter];
    }
}