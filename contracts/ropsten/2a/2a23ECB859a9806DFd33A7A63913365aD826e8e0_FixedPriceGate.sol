// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IPriceGate.sol";
import "IIncinerator.sol";

contract FixedPriceGate is IPriceGate {

    struct Gate {
        uint ethCost;
        address burnToken;
        address incinerator;
    }

    address public management;
    uint public numGates;

    mapping (uint => Gate) public gates;


    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor (address _management) {
        management = _management;
    }

    function addGate(uint _ethCost, address _incinerator, address _burnToken) external managementOnly {
        numGates += 1;
        Gate storage gate = gates[numGates];
        gate.ethCost = _ethCost;
        gate.burnToken = _burnToken;
        gate.incinerator = _incinerator;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        management = newMgmt;
    }

    // we don't allow resetting of burnToken or incinerator
    function setPrice(uint index, uint newPrice) external managementOnly {
        require(index <= numGates, 'Invalid index');
        Gate storage gate = gates[index];
        gate.ethCost = newPrice;
    }

    function getCost(uint index) override external view returns (uint _ethCost) {
        Gate memory gate = gates[index];
        return gate.ethCost;
    }

    function passThruGate(uint index) override external payable {
        Gate memory gate = gates[index];
        require(msg.value >= gate.ethCost, 'Please send more ETH');

        // burn token cost
        if (msg.value > 0) {
            IIncinerator(gate.incinerator).incinerate{value: msg.value}(gate.burnToken);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IPriceGate {

    function getCost(uint) external view returns (uint ethCost);

    function passThruGate(uint) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IIncinerator {

    function incinerate(address tokenAddr) external payable;
}