// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./interfaces/IMarzResources.sol";

contract MultiMine {
    address private resources;

    constructor(address _resources) {
        resources = _resources;
    }

    function mine(uint256[] calldata plotIds) external {
        IMarzResources _resources = IMarzResources(resources);

        for (uint256 i = 0; i < plotIds.length; i++) {
            _resources.mine(plotIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IMarzResources {
    /**
     * Starts mining a given plot
     * Outputs one of each resource found on that plot per period
     * with maximum of CLAIMS_PER_PLOT
     */
    function mine(uint256 plotId) external;
}

