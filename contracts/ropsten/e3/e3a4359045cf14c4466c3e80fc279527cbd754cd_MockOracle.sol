// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface ITruPriceOracle {
    function usdToTru(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {ITruPriceOracle} from "ITruPriceOracle.sol";

contract MockOracle is ITruPriceOracle {
    function usdToTru(uint256 amount) external override view returns (uint256) {
        return amount / 5e10;
    }
}