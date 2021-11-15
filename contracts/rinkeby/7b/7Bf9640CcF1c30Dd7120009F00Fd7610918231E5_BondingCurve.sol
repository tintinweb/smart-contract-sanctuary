// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ICurve} from './ICurve.sol';

interface IBondingCurve is ICurve {
    function getFixedPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurve {
    function getY(uint256 x) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IBondingCurve} from '../Curves/IBondingCurve.sol';

contract BondingCurve is IBondingCurve {
    uint256 public fixedPrice = 1300e6;

    constructor(uint256 price) {
        fixedPrice = price;
    }

    function getFixedPrice() external view override returns(uint256) {
        return fixedPrice;
    }

    function getY(uint256 percent) external pure override returns (uint256) {
        if (percent <= 0) return 7e3;
        else if (percent > 0 && percent <= 10e16) return 73e2;
        else if (percent > 10e16 && percent <= 20e16) return 76e2;
        else if (percent > 20e16 && percent <= 30e16) return 79e2;
        else if (percent > 30e16 && percent <= 40e16) return 82e2;
        else if (percent > 40e16 && percent <= 50e16) return 85e2;
        else if (percent > 50e16 && percent <= 60e16) return 88e2;
        else if (percent > 60e16 && percent <= 70e16) return 91e2;
        else if (percent > 70e16 && percent <= 80e16) return 94e2;
        else if (percent > 80e16 && percent <= 90e16) return 97e2;
        else if (percent > 90e16 && percent <= 100e16) return 1e4; // 0.01
        else return 1e4; // 0.01
    }
}

