/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Contract {
    string public data;
    function setData(string memory _data) public {
        data = _data;
    }
}