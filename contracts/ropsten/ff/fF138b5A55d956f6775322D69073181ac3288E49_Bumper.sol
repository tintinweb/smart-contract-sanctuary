/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

contract Bumper {
    struct Bump {
        uint256 cat;
        bool dog;
        string name;
        string chair;
    }
    address public governance;

    Bump[] public bumps;
    
    function addBump() public {
        bumps.push(Bump({
                cat: 422,
                dog: true,
                name: "betsi",
                chair: "yes"
            }));
    }
}