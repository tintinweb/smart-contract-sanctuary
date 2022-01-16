/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Counter {

    uint public count;

    function inc() public {
        count += 1;
    }

    function retrieve() public view returns (uint){
        return count;
    }
}