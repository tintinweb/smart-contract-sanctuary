pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./PubMiningRateModel.sol";

contract PubMiningRateModelImpl is PubMiningRateModel {
    using SafeMath for uint;

    event NewKink(uint kink);
    event NewSupplyParams(uint baseSpeed, uint g0, uint g1, uint g2);
    event NewBorrowParams(uint baseSpeed, uint g0, uint g1, uint g2);

    address public owner;

    // all params below scaled by 1e18
    uint public kink;

    uint public supplyBaseSpeed;
    uint public supplyG0;
    uint public supplyG1;
    uint public supplyG2;

    uint public borrowBaseSpeed;
    uint public borrowG0;
    uint public borrowG1;
    uint public borrowG2;

    constructor(
        uint kink_,
        uint supplyBaseSpeed_,
        uint supplyG0_,
        uint supplyG1_,
        uint supplyG2_,
        uint borrowBaseSpeed_,
        uint borrowG0_,
        uint borrowG1_,
        uint borrowG2_,
        address owner_) public {
            owner = owner_;

            updateKinkInternal(kink_);
            updateSupplyParamsInternal(supplyBaseSpeed_, supplyG0_, supplyG1_, supplyG2_);
            updateBorrowParamsInternal(borrowBaseSpeed_, borrowG0_, borrowG1_, borrowG2_);
    }

    function updateKink(uint kink_) external {
        require(msg.sender == owner, "only the owner may call this function.");

        updateKinkInternal(kink_);
    }

    function updateSupplyParams(uint baseSpeed, uint g0, uint g1, uint g2) external {
        require(msg.sender == owner, "only the owner may call this function.");

        updateSupplyParamsInternal(baseSpeed, g0, g1, g2);
    }

    function updateBorrowParams(uint baseSpeed, uint g0, uint g1, uint g2) external {
        require(msg.sender == owner, "only the owner may call this function.");

        updateBorrowParamsInternal(baseSpeed, g0, g1, g2);
    }

    function updateKinkInternal(uint kink_) internal {
        require(kink <= 1e18, "require kink <= 1e18");
        
        kink = kink_;

        emit NewKink(kink);
    }

    function updateSupplyParamsInternal(uint baseSpeed, uint g0, uint g1, uint g2) internal {
        require(g0 <= 1e18, "require g0 <= 1e18");
        require(g1 <= 1e18, "require g1 <= 1e18");
        require(g1 <= (uint(1e18).sub(g0)), "require g1 <= (1e18 - g0)");
        require(g2 <= (uint(1e18).sub(g0).sub(g1)), "require g2 <= (1e18 - g0 - g1)");

        supplyBaseSpeed = baseSpeed;
        supplyG0 = g0;
        supplyG1 = g1;
        supplyG2 = g2;

        emit NewSupplyParams(supplyBaseSpeed, supplyG0, supplyG1, supplyG2);
    }

    function updateBorrowParamsInternal(uint baseSpeed, uint g0, uint g1, uint g2) internal {
        require(g0 <= 1e18, "require g0 <= 1e18");
        require(g1 <= 1e18, "require g1 <= 1e18");
        
        borrowBaseSpeed = baseSpeed;
        borrowG0 = g0;
        borrowG1 = g1;
        borrowG2 = g2;

        emit NewBorrowParams(borrowBaseSpeed, borrowG0, borrowG1, borrowG2);
    }

    function getBorrowSpeed(uint utilizationRate) external view returns (uint) {
        uint g;
        if (utilizationRate < kink) {
            uint temp = utilizationRate.mul(borrowG1).div(kink);
            g = uint(1e18).sub(borrowG0).sub(temp);
        } else {
            uint temp = utilizationRate.sub(kink).mul(borrowG2).div(uint(1e18).sub(kink));
            g = uint(1e18).sub(borrowG0).sub(borrowG1).sub(temp);
        }
        
        return borrowBaseSpeed.mul(g).div(1e18);
    }

    function getSupplySpeed(uint utilizationRate) external view returns (uint) {
        uint g; 
        if (utilizationRate < kink) {
            uint temp = utilizationRate.mul(supplyG1).div(kink);
            g = supplyG0.add(temp);
        } else {
            uint temp = utilizationRate.sub(kink).mul(supplyG2).div(uint(1e18).sub(kink));
            g = supplyG0.add(supplyG1).add(temp);
        }
        
        return supplyBaseSpeed.mul(g).div(1e18);
    }
}

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.16;


contract PubMiningRateModel {
    /// @notice Indicator that this is an PubMiningRateModel contract (for inspection)
    bool public constant isPubMiningRateModel = true;

    address public PubMining;

    function getSupplySpeed(uint utilizationRate) external view returns (uint);

    function getBorrowSpeed(uint utilizationRate) external view returns (uint);
}