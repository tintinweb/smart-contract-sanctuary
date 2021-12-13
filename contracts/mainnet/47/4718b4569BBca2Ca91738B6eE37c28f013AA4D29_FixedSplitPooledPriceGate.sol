// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IPriceGate.sol";
import "IIncinerator.sol";

contract FixedSplitPooledPriceGate is IPriceGate {

    struct Gate {
        uint ethReceived;
        uint ethCost;
        address burnToken;
        address incinerator;
        address payable beneficiary;
        uint beneficiaryPct;
    }

    uint public numGates;
    mapping (uint => Gate) public gates;

    address public management;

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor (address mgmt) {
        management = mgmt;
    }

    function addGate(uint _ethCost, uint _beneficiaryPct, address _incinerator, address _burnToken, address payable _beneficiary) external managementOnly {
        numGates += 1;
        Gate storage gate = gates[numGates];

        require(_beneficiaryPct <= 100, 'Percents must be between 0 and 100');

        gate.ethCost = _ethCost;
        gate.burnToken = _burnToken;
        gate.incinerator = _incinerator;
        gate.beneficiary = _beneficiary;
        gate.beneficiaryPct = _beneficiaryPct;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        management = newMgmt;
    }

    function getCost(uint index) override external view returns (uint _ethCost) {
        Gate memory gate = gates[index];
        return gate.ethCost;
    }

   function passThruGate(uint index, address) override external payable {
        Gate storage gate = gates[index];
        require(msg.value >= gate.ethCost, 'Please send more ETH');
        gate.ethReceived += msg.value;
    }

    function distribute(uint index, uint amountOutMin) external managementOnly {
        Gate storage gate = gates[index];
        uint balance = gate.ethReceived;
        uint beneficiaryAmt = balance * gate.beneficiaryPct / 100;
        uint incinerateAmt = balance - beneficiaryAmt;
        gate.ethReceived = 0;
        IIncinerator(gate.incinerator).incinerate{value: incinerateAmt}(gate.burnToken, amountOutMin);
        (bool sent, bytes memory data) = gate.beneficiary.call{value: beneficiaryAmt}("");
        require(sent, 'ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IPriceGate {

    function getCost(uint) external view returns (uint ethCost);

    function passThruGate(uint, address) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IIncinerator {

    function incinerate(address tokenAddr, uint amountOutMin) external payable;
}