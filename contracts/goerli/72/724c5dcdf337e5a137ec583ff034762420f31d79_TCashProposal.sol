/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

//SPDX-License-Identifier: MIT

// Tornado Cash blank proposal for testing

pragma solidity ^0.8.0;

contract TCashProposal {
    event Debug(string message, uint256 timestamp);
    
    function executeProposal() public {
        emit Debug("dummy proposal executed", block.timestamp);
    }
}