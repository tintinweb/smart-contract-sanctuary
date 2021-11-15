// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

struct Saver{
    uint256 createTimestamp;
    uint256 startTimestamp;
    uint count;
    uint interval;
    uint256 mint;
    uint256 released;
    uint256 accAmount;
    uint256 relAmount;
    uint score;
    uint status;
    uint updatedTimestamp;
    bytes12 ref;
}

struct Transaction{
    bool pos;
    uint timestamp;
    uint amount;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

library CommitmentWeight {
    
    uint constant DECIMALS = 8;
    int constant ONE = int(10**DECIMALS);

    function calculate( uint day ) external pure returns (uint){
        int x = int(day) * ONE;
        int c = 3650 * ONE;
        
        int numerator = div( div( x, c ) - ONE, sqrt( ( div( pow( x, 2 ), 13322500 * ONE ) - div( x, 1825 * ONE ) + ONE + ONE ) ) ) + div( ONE, sqrt( 2 * ONE ) );
        int denominator = ( ONE + div( ONE, sqrt( 2 * ONE ) ) );
        
        return uint( ONE + div( numerator, denominator ) );
    }
    
    function div( int a, int b ) internal pure returns ( int ){
        return ( a * int(ONE) / b );
    }
    
    function sqrt( int a ) internal pure returns ( int ){
        int s = a * int(ONE);
        if( s < 0 ) s = s * -1;
        uint k = uint(s);
        uint z = (k + 1) / 2;
        uint y = k;
        while (z < y) {
            y = z;
            z = (k / z + z) / 2;
        }
        return int(y);
    }

    function pow( int a, int b ) internal pure returns ( int ){
        return int(uint(a) ** uint(b) / uint(ONE));
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CommitmentWeight.sol";
import "../Saver.sol";

library Score {
    using SafeMath for uint;
    
    uint constant SECONDS_OF_DAY = 24 * 60 * 60;

    function _getTimes( uint createTimestamp, uint startTimestamp, uint count, uint interval ) pure private returns( uint deposit, uint withdraw, uint timeline, uint max ){
        deposit     = startTimestamp.sub( createTimestamp );
        withdraw    = SECONDS_OF_DAY.mul( count ).mul( interval );
        timeline    = deposit + withdraw;
        max         = SECONDS_OF_DAY.mul( 365 ).mul( 30 );
    }
    
    function _getDepositTransactions( uint createTimestamp, uint deposit, Transaction [] memory transactions ) private pure returns( uint depositCount, uint [] memory xAxis, uint [] memory yAxis ){
        depositCount = 0;
        yAxis = new uint [] ( transactions.length );
        xAxis = new uint [] ( transactions.length + 1 );
        
        for( uint i = 0 ; i <  transactions.length ; i++ ){
            if( transactions[i].pos ) {
                yAxis[ depositCount ] = i == 0 ? transactions[ i ].amount : transactions[ i ].amount.add( yAxis[ i - 1 ] );
                xAxis[ depositCount ] = transactions[ i ].timestamp.sub( createTimestamp );
                depositCount++;
            }
        }
        xAxis[ depositCount ] = deposit;
        
        uint tempX = 0;
        for( uint i = 1 ; i <= depositCount ; i++ ){
            tempX = tempX + xAxis[ i - 1 ];
            xAxis[ i ] = xAxis[ i ].sub( tempX );
        }
    }

    function calculate( uint createTimestamp, uint startTimestamp, Transaction [] memory transactions, uint count, uint interval, uint decimals ) public pure returns ( uint ){
        
        ( uint deposit, uint withdraw, uint timeline, uint max ) = _getTimes(createTimestamp, startTimestamp, count, interval);
        ( uint depositCount, uint [] memory xAxis, uint [] memory yAxis ) = _getDepositTransactions( createTimestamp, deposit, transactions );
        
        uint cw = CommitmentWeight.calculate( timeline.div( SECONDS_OF_DAY ) );
        
        if( max <= deposit ){
            
            uint accX = 0;
            for( uint i = 0 ; i < depositCount ; i++ ){
                accX = accX.add( xAxis[ i + 1 ] );
                if( accX > max ){
                    xAxis[ i + 1 ] = max.sub( accX.sub( xAxis[ i + 1 ] ) );
                    depositCount = i + 1;
                    break;
                }
            }
            
            uint beforeWithdraw = 0;
            for( uint i = 0 ; i < depositCount ; i++ ){
                beforeWithdraw = beforeWithdraw.add( yAxis[ i ].mul( xAxis[ i + 1 ] ) );
            }
            
            uint afterWithdraw = 0;
            
            return beforeWithdraw.add( afterWithdraw ).div( SECONDS_OF_DAY ).mul( cw ).div( 10 ** decimals );
            
        }else if( max <= timeline ){
            
            uint beforeWithdraw = 0;
            for( uint i = 0 ; i < depositCount ; i++ ){
                beforeWithdraw = beforeWithdraw.add( yAxis[ i ].mul( xAxis[ i + 1 ] ) );
            }
            
            uint afterWithdraw = 0;
            if( withdraw > 0 ){
                uint tempY = yAxis[ depositCount - 1 ].mul( timeline.sub( max ) ).div( withdraw );
                afterWithdraw = yAxis[ depositCount - 1 ].mul( withdraw ).div( 2 );
                afterWithdraw = afterWithdraw.sub( tempY.mul( timeline.sub( max ) ).div( 2 ) );
            }
            
            return beforeWithdraw.add( afterWithdraw ).div( SECONDS_OF_DAY ).mul( cw ).div( 10 ** decimals );
            
        }else {
            
            uint beforeWithdraw = 0;
            for( uint i = 0 ; i < depositCount ; i++ ){
                beforeWithdraw = beforeWithdraw.add( yAxis[ i ].mul( xAxis[ i + 1 ] ) );
            }
            
            uint afterWithdraw = yAxis[ depositCount - 1 ].mul( withdraw ).div( 2 );
            
            return beforeWithdraw.add( afterWithdraw ).div( SECONDS_OF_DAY ).mul( cw ).div( 10 ** decimals );
            
        }
        
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
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

