/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;



// Part: IEligibility

interface IEligibility {
    
    function isEligible(uint, address, bytes32[] memory) external view returns (bool eligible);

    function passThruGate(uint, address, bytes32[] memory) external;
}

// File: AmaluEligibility.sol

contract AmaluEligibility is IEligibility {

    mapping(uint => mapping(address => uint)) public timesWithdrawn;
    mapping(uint => uint) public maxWithdrawals;
    address public gateMaster;
    address public management;

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor (address _mgmt, address _gateMaster) {
        gateMaster = _gateMaster;
        management = _mgmt;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        management = newMgmt;
    }

    function setMaxWithdrawals(uint index, uint max) external managementOnly {
        maxWithdrawals[index] = max;
    }

    function isEligible(uint index, address recipient, bytes32[] memory) public override view returns (bool eligible) {
        return timesWithdrawn[index][recipient] < maxWithdrawals[index];
    }

    function passThruGate(uint index, address recipient, bytes32[] memory) external override {
        require(msg.sender == gateMaster, "Only gatemaster may call this.");

        // close re-entrance gate, prevent double withdrawals
        require(isEligible(index, recipient, new bytes32[](0)), "Address is not eligible");

        timesWithdrawn[index][recipient] += 1;
    }
}