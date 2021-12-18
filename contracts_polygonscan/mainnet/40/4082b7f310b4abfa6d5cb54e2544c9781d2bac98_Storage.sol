/**
 *Submitted for verification at polygonscan.com on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string data;

    constructor(string memory _data) {
        data = _data;
    }

    function retrieve() public view returns (string memory){
        return data;
    }
}