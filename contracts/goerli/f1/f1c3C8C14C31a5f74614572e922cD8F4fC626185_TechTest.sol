/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-10
*/

pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: UNLICENSED

contract TechTest {
    address private owner;
    
    event MyEvent(
        bytes32 indexed jobId,
        string indexed message
    );
    
    constructor() {
        owner = msg.sender;
    }
    
    function sendEvent(bytes32 jobId, string memory message) public onlyOwner {
        emit MyEvent(jobId, message);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}