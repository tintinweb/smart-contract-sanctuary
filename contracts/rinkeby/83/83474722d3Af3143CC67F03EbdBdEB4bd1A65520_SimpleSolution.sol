// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;
import "SimpleChallenge.sol";

contract SimpleSolution is SimpleChallenge {
    // A method that computes the greatest common divisor.
    // e.g.,
    //  computeGcd(2, 3) => 1
    //  computeGcd(5, 10) -> 5
    function computeGcd(uint256 a, uint256 b) external pure returns (uint256) {
        uint256 small = (a < b ? a : b);
        uint256 gcd = 1;
        for (uint256 i = 1; i <= small; i++) {
            if (a % i == 0 && b % i == 0) {
                gcd = i;
            }
        }
        return gcd;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface SimpleChallenge {
    // A method that computes the greatest common divisor.
    // e.g.,
    //  computeGcd(2, 3) => 1
    //  computeGcd(5, 10) -> 5
    function computeGcd(uint256 a, uint256 b) external pure returns (uint256);
}