/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-113 ===

    STATUS: [complete]
    DEPLOYED AT: 0x12d8dde128a2276dbc99911f437ee36d114c5add

    VULNERABILITY REPRODUCTION STEPS:
    1. Call register() thrice.
    2. Call refundAll()
    
    EXPECTED OUTCOME:
    One ether will be given to each address in refundAddresses if the contract has it, or 
    the contract will send zero ether once it is out.
    
    ACTUAL OUTCOME:
    All funds are held up because one transaction failed (namely the third one).
    
    NOTES:
    @source: https://consensys.github.io/smart-contract-best-practices/known_attacks/#dos-with-unexpected-revert
    @author: ConsenSys Diligence
    Modified by Bernhard Mueller
    Modified by Anurag Kompalli
*/

pragma solidity 0.4.24;

contract Refunder {
    
    address[] private refundAddresses;
    uint256 public refunds;

    constructor() public payable{
        refunds = msg.value;
    }
    
    function registerForRefund() public {
        refundAddresses.push(msg.sender);
    }

    // bad
    function refundAll() public {
        for(uint x; x < refundAddresses.length; x++) {
            // Send 1 ether to each address 
            require(refundAddresses[x].send(1000000000000000000));
        }
    }

}