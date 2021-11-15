// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract MockCrsUsdcOracle {

    uint public constant PERIOD = 24 hours;

    address public token0;
    address public token1;

    function update() external {}


    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint ) {
        if (token == token0) {
            return amountIn;
        } else {
            return amountIn;
        }
    }
}

