pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";

// Decimal math library
library DecMath {
    using SafeMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    function decmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISION);
    }

    function decdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISION).div(b);
    }
}
