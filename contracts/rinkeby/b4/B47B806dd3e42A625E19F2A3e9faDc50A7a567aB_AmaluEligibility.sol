// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IEligibility.sol";

contract AmaluEligibility is IEligibility {

    struct Gate {
        uint maxWithdrawalsAddress;
        uint maxWithdrawalsTotal;
        uint totalWithdrawals;
    }

    mapping (uint => Gate) public gates;
    mapping(uint => mapping(address => uint)) public timesWithdrawn;
    uint public numGates = 0;

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

    function addGate(uint maxWithdrawalsAddress, uint maxWithdrawalsTotal) external managementOnly returns (uint) {
        numGates += 1;

        gates[numGates] = Gate(maxWithdrawalsAddress, maxWithdrawalsTotal, 0);
        return numGates;
    }

    function getGate(uint index) external view returns (uint, uint, uint) {
        Gate memory gate = gates[index];
        return (gate.maxWithdrawalsAddress, gate.maxWithdrawalsTotal, gate.totalWithdrawals);
    }

    function isEligible(uint index, address recipient, bytes32[] memory) public override view returns (bool eligible) {
        Gate memory gate = gates[index];
        return timesWithdrawn[index][recipient] < gate.maxWithdrawalsAddress && gate.totalWithdrawals < gate.maxWithdrawalsTotal;
    }

    function passThruGate(uint index, address recipient, bytes32[] memory) external override {
        require(msg.sender == gateMaster, "Only gatemaster may call this.");

        // close re-entrance gate, prevent double withdrawals
        require(isEligible(index, recipient, new bytes32[](0)), "Address is not eligible");

        timesWithdrawn[index][recipient] += 1;
        Gate storage gate = gates[index];
        gate.totalWithdrawals += 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IEligibility {

//    function getGate(uint) external view returns (struct Gate)
//    function addGate(uint...) external

    function isEligible(uint, address, bytes32[] memory) external view returns (bool eligible);

    function passThruGate(uint, address, bytes32[] memory) external;
}