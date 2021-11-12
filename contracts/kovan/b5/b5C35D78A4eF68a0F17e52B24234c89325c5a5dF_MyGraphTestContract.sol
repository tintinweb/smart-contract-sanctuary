/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MyGraphTestContract {
    uint public data;

    event UpdateState(uint newState);

    function setData(uint newData) public {
        data = newData;
        emit UpdateState(newData);
    }
}