// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface Itoken {

    function decimals() external view returns(uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./inter.sol";

contract tokentester {

    Itoken public immutable T;

    uint256 public a;
    uint256 public b;

    constructor(address _token) {
        T = Itoken(_token);
    }

    function calc() external view returns(uint256) {
        return 8000 * T.decimals();
    }

    function wcalc() external {
        a = 8000 * T.decimals();
    }

    function wcalctwo() external {
        b = 8000 * uint256(T.decimals());
    }
}