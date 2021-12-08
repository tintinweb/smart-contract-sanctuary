/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract DeploMe {
    string title;

    constructor(string memory _title) {
        title = _title;
    }

    function setTitle(string memory _title) public {
        title = _title;
    }

    function getTitle() public view returns(string memory) {
        return title;
    }
}