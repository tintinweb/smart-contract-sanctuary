/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ILove {

    string _massage;

    constructor(string memory massage) {
        _massage = massage;
    }

    function ShowMessage() public view returns (string memory) {
        return _massage;
    }
}