/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface CellSubscription {
    function makePayment() external;
}

contract EthCollector {
    address owner;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function collect() external onlyOwner {
        require(block.number % 2 == 0);
        CellSubscription(0x7fb75c961DB6d65333DFE63e3C1527AE6a09a263).makePayment();
    }
    
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}