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
    }
    address public governance;
    function getBump() external pure returns (Bump memory) {
        Bump memory book;
        book = Bump(44, true, "gerald");
        return book;
    }
}