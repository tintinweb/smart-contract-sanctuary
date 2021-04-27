/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: none
pragma solidity 0.7.6;


contract Test {

    event TestEvent(uint256 blockNumber, string msg);
    
    function doTest(string calldata _msg) public {
        emit TestEvent(block.number, _msg);
    }
}