// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract MockCrsUsdcOracle {

    uint public constant PERIOD = 24 hours;

    address public token0;
    address public token1;

    function update() external {}

    // this param only in mock
    uint256 public divPercent = 1000000;

    // this param only in mock
    function setDivPercent(uint256 newPercent) public {
        divPercent = newPercent;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint ) {
        if (token == token0) {
            return amountIn * divPercent / 1000000;
        } else {
            return amountIn * divPercent / 1000000;
        }
    }
}

