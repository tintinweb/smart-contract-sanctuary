// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEpoch {
    function setPeriod(uint256 _period) external;

    function callable() external view returns (bool);

    function getPeriod() external view returns (uint256);

    function getNextEpoch() external view returns (uint256);

    function getLastEpoch() external view returns (uint256);

    function getStartTime() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IEpoch} from './IEpoch.sol';

interface IUniswapOracle is IEpoch {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from '@openzeppelin/contracts/contracts/math/SafeMath.sol';

import {IUniswapOracle} from '../interfaces/IUniswapOracle.sol';

contract SimplePairOracle is IUniswapOracle {
    using SafeMath for uint256;

    /**
     * State variables.
     */

    address public tokenA;
    address public tokenB;
    uint256 public priceA = 1e18;
    uint256 public priceB = 1e18;
    bool public error;
    uint256 public epoch;
    uint256 public startTime;
    uint256 public period = 1;

    /// Events.
    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);

    /**
     * Constructor.
     */
    constructor(
        uint256 priceA_,
        uint256 priceB_,
        address tokenA_,
        address tokenB_
    ) {
        priceA = priceA_;
        priceB = priceB_;
        tokenA = tokenA_;
        tokenB = tokenB_;
    }

    /**
     * Setters.
     */

    function setPriceTokenA(uint256 price) public {
        require(price >= 0, 'Oracle: price cannot be < 0');

        priceA = price;
    }

    function setPriceTokenB(uint256 price) public {
        require(price >= 0, 'Oracle: price cannot be < 0');

        priceB = price;
    }

    function setEpoch(uint256 _epoch) public {
        epoch = _epoch;
    }

    function setStartTime(uint256 _startTime) public {
        startTime = _startTime;
    }

    function setPeriod(uint256 _period) public override {
        period = _period;
    }

    function setRevert(bool _error) public {
        error = _error;
    }

    /**
     * Views.
     */

    function getPriceTokenA() public view returns (uint256) {
        return priceA;
    }

    function getPriceTokenB() public view returns (uint256) {
        return priceB;
    }

    function getLastEpoch() public view override returns (uint256) {
        return epoch;
    }

    function getCurrentEpoch() public view override returns (uint256) {
        return epoch;
    }

    function getNextEpoch() public view override returns (uint256) {
        return epoch.add(1);
    }

    function nextEpochPoint() public view override returns (uint256) {
        return startTime.add(getNextEpoch().mul(period));
    }

    function getPeriod() public view override returns (uint256) {
        return period;
    }

    function getStartTime() public view override returns (uint256) {
        return startTime;
    }

    function consult(address token, uint256 amountIn)
        external
        view
        override
        returns (uint256)
    {
        if (token == tokenA) return priceA.mul(amountIn).div(1e18);

        require(token == tokenB, 'Oracle: invalid token');

        return priceB.mul(amountIn).div(1e18);
    }

    /**
     * Pure.
     */
    function callable() public pure override returns (bool) {
        return true;
    }

    function update() external override {
        require(!error, 'Oracle: mocked error');
        emit Updated(0, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

