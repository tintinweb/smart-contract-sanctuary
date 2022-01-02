// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IPriceGate.sol";

contract AmaluPriceGate is IPriceGate {

    uint public numGates;

    constructor () {}

    function getCost(uint) override external view returns (uint) {
        return 0;
    }

    function passThruGate(uint, address) override external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IPriceGate {

    function getCost(uint) external view returns (uint ethCost);

    function passThruGate(uint, address) external payable;
}