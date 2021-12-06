/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

contract DataContract {

    string public data;

    function putData(string memory _d) public {
        data = _d;
    }

    function getData() public view returns (string memory) {
        return data;
    }
}