// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IPriceGate.sol";
import "IIncinerator.sol";

contract SpeedBumpPriceGate is IPriceGate {

    struct Gate {
        uint priceIncreaseFactor;
        uint priceIncreaseDenominator;
        uint lastPrice;
        uint decayFactor;
        uint priceFloor;
        uint lastPurchaseBlock;
        address burnToken;
        address incinerator;
    }

    mapping (uint => Gate) public gates;
    uint public numGates;
    address public management;

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor (address _management) {
        management = _management;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        management = newMgmt;
    }

    function addGate(uint priceFloor, uint priceDecay, uint priceIncrease, uint priceIncreaseDenominator, address incinerator, address burnToken) external managementOnly {
        numGates += 1;
        Gate storage gate = gates[numGates];
        gate.priceFloor = priceFloor;
        gate.decayFactor = priceDecay;
        gate.priceIncreaseFactor = priceIncrease;
        gate.priceIncreaseDenominator = priceIncreaseDenominator;
        gate.incinerator = incinerator;
        gate.burnToken = burnToken;
    }

    function setPriceParameters(uint index, uint newPriceFloor, uint newPriceDecay, uint newPriceIncreaseFactor, uint newPriceIncreaseDenominator) external managementOnly {
        Gate storage gate = gates[index];
        gate.priceFloor = newPriceFloor;
        gate.decayFactor = newPriceDecay;
        gate.priceIncreaseFactor = newPriceIncreaseFactor;
        gate.priceIncreaseDenominator = newPriceIncreaseDenominator;
    }

    function getCost(uint index) override public view returns (uint _ethCost) {
        Gate memory gate = gates[index];
        uint decay = gate.decayFactor * (block.number - gate.lastPurchaseBlock);
        if (gate.lastPrice < decay + gate.priceFloor) {
            return gate.priceFloor;
        } else {
            return gate.lastPrice - decay;
        }
    }

    function passThruGate(uint index) override external payable {
        uint price = getCost(index);
        require(msg.value >= price, 'Please send more ETH');

        // bump up the price
        Gate storage gate = gates[index];
        gate.lastPrice = (price * gate.priceIncreaseFactor) / gate.priceIncreaseDenominator;
        gate.lastPurchaseBlock = block.number;
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