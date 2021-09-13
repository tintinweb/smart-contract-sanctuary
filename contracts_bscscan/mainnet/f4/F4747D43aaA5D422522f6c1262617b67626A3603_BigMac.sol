/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract BigMac {
    address payable private PurrrrrrrrfectCharityRecipient;
    uint256 private PurrrrrrrrfectDonations;
    
    constructor() {
        PurrrrrrrrfectCharityRecipient = payable(msg.sender);
    }
    
    function OneBigMacPlease() external pure returns (string memory) {
        return "No Big Mac for you Penderis!";
    }
    
    function CollectPurrrrrrrrfectDonations() external {
        PurrrrrrrrfectCharityRecipient.transfer(PurrrrrrrrfectDonations);
        PurrrrrrrrfectDonations = 0;
    }
    
    receive() external payable {
        PurrrrrrrrfectDonations += msg.value;
    }
}