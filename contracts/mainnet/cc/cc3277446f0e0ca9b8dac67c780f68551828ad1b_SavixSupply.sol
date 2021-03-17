/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) public pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) public pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) public pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) public pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) public pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) public pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev savix interest and supply calculations.
 *
*/
 library SavixSupply {
     
    uint256 public constant MAX_UINT256 = 2**256 - 1;
    uint256 public constant MAX_UINT128 = 2**128 - 1;
    uint public constant MINTIMEWIN = 7200; // 2 hours
    uint public constant SECPERDAY = 3600 * 24;
    uint public constant DECIMALS = 9;

    struct SupplyWinBoundary 
    {
        uint256 x1;
        uint256 x2;
        uint256 y1;
        uint256 y2;
    }

    function getSupplyWindow(uint256[2][] memory map, uint256 calcTime) internal pure returns (SupplyWinBoundary memory)
    {
        SupplyWinBoundary memory winBound;
        
        winBound.x1 = 0;
        winBound.x2 = 0;

        winBound.y1 = map[0][1];
        winBound.y2 = 0;

        for (uint i=0; i < map.length; i++)
        {
            if (map[i][0] == 0) 
              continue;

            if (calcTime < map[i][0])
            {
                winBound.x2 = map[i][0];
                winBound.y2 = map[i][1];
                break;
            }
            else
            {
                winBound.x1 = map[i][0];
                winBound.y1 = map[i][1];
            }
        }
        if (winBound.x2 == 0) winBound.x2 = MAX_UINT128;
        if (winBound.y2 == 0) winBound.y2 = MAX_UINT128;
        return winBound;
    }

    // function to calculate new Supply with SafeMath for divisions only, shortest (cheapest) form
    function getAdjustedSupply(uint256[2][] memory map, uint256 transactionTime, uint constGradient) internal pure returns (uint256)
    {
        if (transactionTime >= map[map.length-1][0])
        {
            // return (map[map.length-1][1] + constGradient * (SafeMath.sub(transactionTime, map[map.length-1][0])));  ** old version
            return (map[map.length-1][1] + SafeMath.mul(constGradient, SafeMath.sub(transactionTime, map[map.length-1][0])));
        }
        
        SupplyWinBoundary memory winBound = getSupplyWindow(map, transactionTime);
        // return (winBound.y1 + SafeMath.div(winBound.y2 - winBound.y1, winBound.x2 - winBound.x1) * (transactionTime - winBound.x1));  ** old version
        return (winBound.y1 + SafeMath.div(SafeMath.mul(SafeMath.sub(winBound.y2, winBound.y1), SafeMath.sub(transactionTime, winBound.x1)), SafeMath.sub(winBound.x2, winBound.x1)));
    }

    function getDailyInterest(uint256 currentTime, uint256 lastAdjustTime, uint256 currentSupply, uint256 lastSupply) internal pure returns (uint)
    {
        if (currentTime <= lastAdjustTime)
        {
           return uint128(0);
        }

        // ** old version                
        // uint256 InterestSinceLastAdjust = SafeMath.div((currentSupply - lastSupply) * 100, lastSupply);
        // return (SafeMath.div(InterestSinceLastAdjust * SECPERDAY, currentTime - lastAdjustTime));
        return (SafeMath.div(SafeMath.sub(currentSupply, lastSupply) * 100 * 10**DECIMALS * SECPERDAY, SafeMath.mul(SafeMath.sub(currentTime, lastAdjustTime), lastSupply)));
    }
 
    // ** new method
    // yearlyInterest rate is given in percent with 2 decimals => result has to be divede by 10**9 to get correct number with precision 2
    function getYearlyInterest(uint256 currentTime, uint256 lastAdjustTime, uint256 currentSupply, uint256 lastSupply) internal pure returns (uint)
    {
        if (currentTime <= lastAdjustTime)
        {
           return uint128(0);
        }
        return (SafeMath.div(SafeMath.sub(currentSupply, lastSupply) * 100 * 10**DECIMALS * SECPERDAY * 360, SafeMath.mul(SafeMath.sub(currentTime, lastAdjustTime), lastSupply)));
    }
}