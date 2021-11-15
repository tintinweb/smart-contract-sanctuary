// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.3;

import "./Math.sol";
import "./SafeMath.sol";

library CalculateSwap {
    using SafeMath for uint256;
    
    function calculateOptimalSwapAmount(
        uint256 amountA,
        uint256 amountB,
        uint256 reserveA,
        uint256 reserveB,
        uint256 swap_fee_numerator,
        uint256 swap_fee_denominator
    ) public pure returns (uint256) {
        require(amountA.mul(reserveB) >= amountB.mul(reserveA), "Expected amountA*reserveB value to be greater than amountB*reserveA value");
        uint256 double_non_fee_part = uint256(swap_fee_denominator.sub(swap_fee_numerator)).mul(2);
        uint256 reserve_amounts_delta = (amountA.mul(reserveB)).sub(amountB.mul(reserveA));
        uint256 ratio = reserve_amounts_delta.mul(swap_fee_denominator).div(amountB.add(reserveB)).mul(reserveA);
        uint256 delta = double_non_fee_part.mul(ratio).mul(2);
        uint256 base = uint256(double_non_fee_part.add(swap_fee_numerator)).mul(reserveA);
        uint256 distance = Math.sqrt(base.mul(base).add(delta));
        return uint256(distance.sub(base)).div(double_non_fee_part);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.3;

// a library for performing various math operations
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

