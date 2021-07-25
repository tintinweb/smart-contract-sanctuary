// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.4;

import {IMaticValidator as Validator} from "./../contracts/interfaces/IMaticValidator.sol";
import {LNumber as Number} from "./../contracts/lib/LNumber.sol";

 contract StakeMock {
     
     using Number for Number.N256;
     
     Number.N256 public totalStake;

     struct Operator {
        Number.N256 min;
        Validator validator;
        address escrow; // stake helper       
    }
    
    Operator[]  _nodes ;
    Number.N256[]  _stakes;
    
    
    event LogStake(address indexed user, address[] nodes, Number.N256[] amounts, uint256 totalAmount);
    
    function addOperatorWithStake(Operator memory _operator, Number.N256 memory _stakeAmount) public {
        _nodes.push( _operator);
        _stakes.push(_stakeAmount);   
    }
    
    
    function clearOperatorsWithStake() public {
        delete _nodes;
        delete _stakes;
    }

    function getNodesWithStake() public view returns(Operator[] memory, Number.N256[] memory) {
        
        return (_nodes, _stakes);
    }
    
    
    function stake(address[] memory nodes, Number.N256[] memory dist) public {
        uint256 tAmt = 0;
        for(uint256 i = 0 ; i < nodes.length ; i++)
        {
            totalStake = totalStake.add(dist[i]);
            tAmt = tAmt + dist[i].value;
        }
        emit LogStake(msg.sender, nodes, dist, tAmt);
    }

}



pragma solidity 0.8.4;

library LNumber {


    struct N256 {
        uint256 value;
    }

     function add(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (N256 memory)
    {
        return N256({ value: _n1.value+ (_n2.value)});
    }
}

pragma solidity 0.8.4;

interface IMaticValidator {

    function buyVoucher(uint256, uint256) external returns (uint256);
    
    function sellVoucher_new(uint256, uint256) external ;

    function unstakeClaimTokens_new(uint256) external;

    function restake() external returns(uint256, uint256);
    
    function unbondNonces(address) external view returns (uint256);

    function getLiquidRewards(address) external view returns (uint256);

    function minAmount() external view returns (uint256);
    
    function getTotalStake(address) external view returns (uint256, uint256);

    function unbonds_new(address, uint256) external view returns (uint256, uint256);

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LDecimal as Decimal} from "./LDecimal.sol";
import {LMath as Math} from "./LMath.sol";

library LNumber {

    using SafeMath for uint256;

    struct N256 {
        uint256 value;
    }
    
    function zero()
        internal
        pure
        returns (N256 memory)
    {
        return N256({
            value: 0
        });
    }

    function add(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (N256 memory)
    {
        return N256({ value: _n1.value.add(_n2.value)});
    }

    function plusOne(
        N256 memory _n1
    )
        internal
        pure
        returns (N256 memory)
    {
        return add(_n1, N256(1));
    }

    function sub(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (N256 memory)
    {
        return N256({ value: _n1.value.sub(_n2.value)});
    }

    function minusOne(
        N256 memory _n1
    )
        internal
        pure
        returns (N256 memory)
    {
        return sub(_n1, N256(1));
    }

    function mul(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (N256 memory)
    {
        return N256({ value: _n1.value.mul(_n2.value)});
    }

    function div(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (N256 memory)
    {
        return N256({ value: _n1.value.div(_n2.value)});
    }

    function ratio(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({ value: Math.getPartial(_n1.value, Decimal.base(), _n2.value) });
    }

    function mul(
        N256 memory _n,
        Decimal.D256 memory _d
    )
        internal
        pure
        returns (N256 memory)
    {
        return N256({ value: Math.getPartial(_n.value, _d.value, Decimal.base()) });
    }

    function div(
        N256 memory _n,
        Decimal.D256 memory _d
    )
        internal
        pure
        returns (N256 memory)
    {
        return N256({ value: Math.getPartial(_n.value, Decimal.base(), _d.value) });
    }

    function equals(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (bool)
    {
        return (_n1.value == _n2.value);
    }

    function isZero(
        N256 memory _n
    )
        internal
        pure
        returns (bool)
    {
        return _n.value == 0;
    }

    function lt(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (bool)
    {
        return (_n1.value < _n2.value);
    }

    function lte(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (bool)
    {
        return (_n1.value <= _n2.value);
    }

    function gt(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (bool)
    {
        return (_n1.value > _n2.value);
    }

    function gte(
        N256 memory _n1,
        N256 memory _n2
    )
        internal
        pure
        returns (bool)
    {
        return (_n1.value >= _n2.value);
    }

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.4;

interface IMaticValidator {

    function buyVoucher(uint256, uint256) external returns (uint256);
    
    function sellVoucher_new(uint256, uint256) external ;

    function unstakeClaimTokens_new(uint256) external;

    function restake() external returns(uint256, uint256);
    
    function unbondNonces(address) external view returns (uint256);

    function getLiquidRewards(address) external view returns (uint256);

    function minAmount() external view returns (uint256);
    
    function getTotalStake(address) external view returns (uint256, uint256);

    function unbonds_new(address, uint256) external view returns (uint256, uint256);

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LMath {

    using SafeMath for uint256;

    function getPartial(
        uint256 _value,
        uint256 _numerator,
        uint256 _denominator
    )
        internal
        pure
        returns (uint256)
    {
        return _value.mul(_numerator).div(_denominator);
    }

    function min(
        uint256 _a,
        uint256 _b
    )
        internal
        pure
        returns (uint256)
    {
        return _a < _b ? _a : _b;
    }

    function max(
        uint256 _a,
        uint256 _b
    )
        internal
        pure
        returns (uint256)
    {
        return _a > _b ? _a : _b;
    }

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LDecimal {

    using SafeMath for uint256;

    uint256 internal constant BASE = 1e18;

    struct D256 {
        uint256 value;
    }

    function base()
        internal
        pure
        returns (uint256)
    {
        return BASE;
    }

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory _d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: _d.value.add(BASE) });
    }

    function add(
        D256 memory _d1,
        D256 memory _d2
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: _d1.value.add(_d2.value)});
    }

    function sub(
        D256 memory _d1,
        D256 memory _d2
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: _d1.value.sub(_d2.value)});
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}