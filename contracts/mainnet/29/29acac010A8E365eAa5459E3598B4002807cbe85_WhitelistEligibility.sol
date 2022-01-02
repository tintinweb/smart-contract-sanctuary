// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IEligibility.sol";

contract WhitelistEligibility is IEligibility {

    struct Gate {
        address whitelisted;
        uint maxWithdrawals;
        uint numWithdrawals;
    }

    mapping (uint => Gate) public gates;
    uint public numGates = 0;

    address public gateMaster;
    address public management;
    bool public paused;

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

    function setPaused(bool _paused) external managementOnly {
        paused = _paused;
    }

    function addGate(address whitelisted, uint maxWithdrawals) external managementOnly returns (uint) {
        numGates += 1;
        Gate storage gate = gates[numGates];
        gate.whitelisted = whitelisted;
        gate.maxWithdrawals = maxWithdrawals;
        return numGates;
    }

    function getGate(uint index) external view returns (address, uint, uint) {
        Gate memory gate = gates[index];
        return (gate.whitelisted, gate.maxWithdrawals, gate.numWithdrawals);
    }

    function isEligible(uint index, address recipient, bytes32[] memory) public override view returns (bool eligible) {
        Gate storage gate = gates[index];
        return !paused && recipient == gate.whitelisted && gate.numWithdrawals < gate.maxWithdrawals;
    }

    function passThruGate(uint index, address recipient, bytes32[] memory) external override {
        require(msg.sender == gateMaster, "Only gatemaster may call this.");
        // close re-entrance gate, prevent double withdrawals
        require(isEligible(index, recipient, new bytes32[](0)), "Address is not eligible");

        Gate storage gate = gates[index];
        gate.numWithdrawals += 1;
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