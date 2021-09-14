/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// "SPDX-License-Identifier: UNLICENSED" for non-open-source code. Please see https://spdx.org for more information.
pragma solidity ^0.8.7;

contract MyContract {
    uint public data;
    
    function setDate(uint _data) external {
        data = _data;
    }
}