// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./interface.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.0;

interface NftInterface {
    function alive(uint256 tokenId) external view returns (bool);
    function Unit(uint256 tokenId) external view returns (
        string memory name_, uint256 createdAt_, uint256 feedLevel_,
        uint256 generation_, uint256 generationTicker_, uint256 lastPlayTime_,
        uint256 availableFreeDays_, uint256 prestige_, uint256 rewards_,
        uint256 tokensToRevive_, uint256 packChoice
    );
}

contract TimeData {
    using SafeMath for uint256;

    uint256 internal ONE_DAY = 86400;
    uint256 internal ONE_HOUR = 3600; 
    uint256 internal MAX_TIME = 2**256 - 1;
    
    address internal NftAddress = 0xdb58f5a96a7a0F73da6b0c8e8ED3C5a9b68d680D; // change to mainnet gotchi contract
    
function getTimeData(uint256 tokenId) public view returns (
    bool isItPlayTime_, uint256 secondsUntilNextPlay_, uint256 timeBetweenPlays_, uint256 playsPerGeneration_,
    bool isInFeedWindow_, uint256 secondsUntilNextFeed_, uint256 secondsLeftInFeedWindow_ ) {( 
        ,uint256 createdAt_, uint256 feedLevel_, uint256 generation_,,
        uint256 lastPlayTime_,, uint256 prestige_,,,
    ) = NftInterface(NftAddress).Unit(tokenId);
        
    uint256 elapsed;
    
    if (createdAt_ != MAX_TIME && NftInterface(NftAddress).alive(tokenId)) {
        
        if (block.timestamp.sub(lastPlayTime_) > ONE_HOUR.add(prestige_.mul(ONE_HOUR))) { // in play
            elapsed = block.timestamp.sub(lastPlayTime_);
            if (feedLevel_ > uint256(block.timestamp.sub(createdAt_)).div(ONE_DAY)) { // not in a feed
                return (
                    true, 0, ONE_HOUR.add(prestige_.mul(ONE_HOUR)), generation_,  
                    false, feedLevel_.mul(ONE_DAY).sub(block.timestamp.sub(createdAt_)), ONE_HOUR.mul(generation_) 
                );
            }
            if (feedLevel_ == uint256(block.timestamp.sub(createdAt_)).div(ONE_DAY) && block.timestamp.sub(createdAt_).mod(ONE_DAY) < ONE_HOUR.mul(generation_)) { // in feeding window
                return (
                    true, 0, ONE_HOUR.add(prestige_.mul(ONE_HOUR)), generation_, 
                    true, 0,  ONE_HOUR.mul(generation_).sub(block.timestamp.sub(createdAt_).mod(ONE_DAY))
                );
            }
        } else { // not in play
            elapsed = block.timestamp.sub(lastPlayTime_);
            if (feedLevel_ > uint256(block.timestamp.sub(createdAt_)).div(ONE_DAY)) {  // not in a feed
                return (
                    false, ONE_HOUR.add(prestige_.mul(ONE_HOUR)).sub(elapsed), ONE_HOUR.add(prestige_.mul(ONE_HOUR)), generation_, 
                    false, feedLevel_.mul(ONE_DAY).sub(block.timestamp.sub(createdAt_)), ONE_HOUR.mul(generation_)
                );
            }
            if (feedLevel_ == uint256(block.timestamp.sub(createdAt_)).div(ONE_DAY) && block.timestamp.sub(createdAt_).mod(ONE_DAY) < ONE_HOUR.mul(generation_)) { // in feeding window
                return (
                    false, ONE_HOUR.add(prestige_.mul(ONE_HOUR)).sub(elapsed), ONE_HOUR.add(prestige_.mul(ONE_HOUR)), generation_, 
                    true, 0, ONE_HOUR.mul(generation_).sub(block.timestamp.sub(createdAt_).mod(ONE_DAY))
                );
            }
        }
    }
    return (false, 0, 0, 0, false, 0, 0);
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}