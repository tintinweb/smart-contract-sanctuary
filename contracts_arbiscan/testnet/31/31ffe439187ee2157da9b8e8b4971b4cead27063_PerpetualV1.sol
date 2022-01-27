/**
 *Submitted for verification at arbiscan.io on 2022-01-26
*/

// File: contracts/protocol/v1/traders/P1TraderConstants.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.8.9;
pragma abicoder v2;
 


/**
 * @title P1TraderConstants
 * @author  
 *
 * @notice Constants for traderFlags set by contracts implementing the I_P1Trader interface.
 */
contract P1TraderConstants {
    bytes32 constant internal TRADER_FLAG_ORDERS = bytes32(uint256(1));
    bytes32 constant internal TRADER_FLAG_LIQUIDATION = bytes32(uint256(2));
    bytes32 constant internal TRADER_FLAG_DELEVERAGING = bytes32(uint256(4));
}

// File: contracts/protocol/lib/SafeCast.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 


/**
 * @title SafeCast
 * @author  
 *
 * @dev Library for casting uint256 to other types of uint.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint128).
     *
     *  Counterpart to Solidity's `uint128` operator.
     *
     *  Requirements:
     *  - `value` must fit into 128 bits.
     */
    function toUint128(
        uint256 value
    )
        internal
        pure
        returns (uint128)
    {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint120).
     *
     *  Counterpart to Solidity's `uint120` operator.
     *
     *  Requirements:
     *  - `value` must fit into 120 bits.
     */
    function toUint120(
        uint256 value
    )
        internal
        pure
        returns (uint120)
    {
        require(value < 2**120, "SafeCast: value doesn\'t fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint32).
     *
     *  Counterpart to Solidity's `uint32` operator.
     *
     *  Requirements:
     *  - `value` must fit into 32 bits.
     */
    function toUint32(
        uint256 value
    )
        internal
        pure
        returns (uint32)
    {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: contracts/protocol/lib/BaseMath.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 



/**
 * @title BaseMath
 * @author  
 *
 * @dev Arithmetic for fixed-point numbers with 18 decimals of precision.
 */
library BaseMath {
    using SafeMath for uint256;

    // The number One in the BaseMath system.
    uint256 constant internal BASE = 10 ** 18;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function base()
        internal
        pure
        returns (uint256)
    {
        return BASE;
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded down).
     */
    function baseMul(
        uint256 value,
        uint256 baseValue
    )
        internal
        pure
        returns (uint256)
    {
        return value.mul(baseValue).div(BASE);
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded down).
     *  Intended as an alternaltive to baseMul to prevent overflow, when `value` is known
     *  to be divisible by `BASE`.
     */
    function baseDivMul(
        uint256 value,
        uint256 baseValue
    )
        internal
        pure
        returns (uint256)
    {
        return value.div(BASE).mul(baseValue);
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded up).
     */
    function baseMulRoundUp(
        uint256 value,
        uint256 baseValue
    )
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || baseValue == 0) {
            return 0;
        }
        return value.mul(baseValue).sub(1).div(BASE).add(1);
    }

    /**
     * @dev Divide a value by a base value (result is rounded down).
     */
    function baseDiv(
        uint256 value,
        uint256 baseValue
    )
        internal
        pure
        returns (uint256)
    {
        return value.mul(BASE).div(baseValue);
    }

    /**
     * @dev Returns a base value representing the reciprocal of another base value (result is
     *  rounded down).
     */
    function baseReciprocal(
        uint256 baseValue
    )
        internal
        pure
        returns (uint256)
    {
        return baseDiv(BASE, baseValue);
    }
}

// File: contracts/protocol/lib/SignedMath.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 



/**
 * @title SignedMath
 * @author  
 *
 * @dev SignedMath library for doing math with signed integers.
 */
library SignedMath {
    using SafeMath for uint256;

    // ============ Structs ============

    struct Int {
        uint256 value;
        bool isPositive;
    }

    // ============ Functions ============

    /**
     * @dev Returns a new signed integer equal to a signed integer plus an unsigned integer.
     */
    function add(
        Int memory sint,
        uint256 value
    )
        internal
        pure
        returns (Int memory)
    {
        if (sint.isPositive) {
            return Int({
                value: value.add(sint.value),
                isPositive: true
            });
        }
        if (sint.value < value) {
            return Int({
                value: value.sub(sint.value),
                isPositive: true
            });
        }
        return Int({
            value: sint.value.sub(value),
            isPositive: false
        });
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer minus an unsigned integer.
     */
    function sub(
        Int memory sint,
        uint256 value
    )
        internal
        pure
        returns (Int memory)
    {
        if (!sint.isPositive) {
            return Int({
                value: value.add(sint.value),
                isPositive: false
            });
        }
        if (sint.value > value) {
            return Int({
                value: sint.value.sub(value),
                isPositive: true
            });
        }
        return Int({
            value: value.sub(sint.value),
            isPositive: false
        });
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer plus another signed integer.
     */
    function signedAdd(
        Int memory augend,
        Int memory addend
    )
        internal
        pure
        returns (Int memory)
    {
        return addend.isPositive
            ? add(augend, addend.value)
            : sub(augend, addend.value);
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer minus another signed integer.
     */
    function signedSub(
        Int memory minuend,
        Int memory subtrahend
    )
        internal
        pure
        returns (Int memory)
    {
        return subtrahend.isPositive
            ? sub(minuend, subtrahend.value)
            : add(minuend, subtrahend.value);
    }

    /**
     * @dev Returns true if signed integer `a` is greater than signed integer `b`, false otherwise.
     */
    function gt(
        Int memory a,
        Int memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.isPositive) {
            if (b.isPositive) {
                return a.value > b.value;
            } else {
                // True, unless both values are zero.
                return a.value != 0 || b.value != 0;
            }
        } else {
            if (b.isPositive) {
                return false;
            } else {
                return a.value < b.value;
            }
        }
    }

    /**
     * @dev Returns the minimum of signed integers `a` and `b`.
     */
    function min(
        Int memory a,
        Int memory b
    )
        internal
        pure
        returns (Int memory)
    {
        return gt(b, a) ? a : b;
    }

    /**
     * @dev Returns the maximum of signed integers `a` and `b`.
     */
    function max(
        Int memory a,
        Int memory b
    )
        internal
        pure
        returns (Int memory)
    {
        return gt(a, b) ? a : b;
    }
}

// File: contracts/protocol/v1/lib/P1Types.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 


/**
 * @title P1Types
 * @author  
 *
 * @dev Library for common types used in PerpetualV1 contracts.
 */
library P1Types {
    // ============ Structs ============

    /**
     * @dev Used to represent the global index and each account's cached index.
     *  Used to settle funding paymennts on a per-account basis.
     */
    struct Index {
        uint32 timestamp;
        bool isPositive;
        uint128 value;
    }

    /**
     * @dev Used to track the signed position balance values for each symbol.
     */
    struct PositionStruct {
        bool positionIsPositive;
        uint120 position;
    }

    /**
     * @dev Used to track the the signed margin balance for each account.
     */
    struct MarginStruct {
        bool marginIsPositive;
        uint120 margin;
    }

    /**
     * @dev Used to track the signed margin balance and position balance values for each account.
     */
    struct Balance {
        bool marginIsPositive;
        uint120 margin;
        mapping(bytes32 => PositionStruct) tokenPosition;
    }

    /**
     * @dev Used by contracts implementing the I_P1Trader interface to return the result of a trade.
     */
    struct TradeResult {
        uint256 fee_maker;
        uint256 fee_taker;
        SignedMath.Int funding_maker;
        SignedMath.Int funding_taker;
        uint256 positionAmount;
        uint256 margin_change;
        bool is_neg_fee;
        bool isBuy; // From taker's perspective.
        bytes32 traderFlags;
    }
}

// File: contracts/protocol/v1/intf/I_P1Trader.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 



/**
 * @title I_P1Trader
 * @author  
 *
 * @notice Interface that PerpetualV1 Traders must implement.
 */
interface I_P1Trader {

    /**
     * @notice Returns the result of the trade between the maker and the taker. Expected to be
     *  called by PerpetualV1. Reverts if the trade is disallowed.
     *
     * @param  maker        The address of the passive maker account.
     * @param  taker        The address of the active taker account.
     * @param  data         Arbitrary data passed in to the `trade()` function of PerpetualV1.
     *
     * @return              The result of the trade from the perspective of the taker.
     */
    function trade(
        address maker,
        address taker,
        bytes calldata data
    )
        external
        returns (P1Types.TradeResult memory);
}

// File: contracts/protocol/lib/ReentrancyGuard.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 


/**
 * @title ReentrancyGuard
 * @author  
 *
 * @dev Updated ReentrancyGuard library designed to be used with Proxy Contracts.
 */
abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = uint256(int256(-1));

    uint256 private _STATUS_;

    //constructor () {
    //    _STATUS_ = NOT_ENTERED;
    //}

    modifier nonReentrant() {
        require(_STATUS_ != ENTERED, "ReentrancyGuard: reentrant call");
        _STATUS_ = ENTERED;
        _;
        _STATUS_ = NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/protocol/lib/Storage.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 


/**
 * @title Storage
 * @author  
 *
 * @dev Storage library for reading/writing storage at a low level.
 */
library Storage {

    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(
        bytes32 slot
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(
        bytes32 slot,
        bytes32 value
    )
        internal
    {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}

// File: contracts/protocol/lib/Adminable.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 



/**
 * @title Adminable
 * @author  
 *
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
    * @dev Modifier to check whether the `msg.sender` is the admin.
    *  If it is, it will run the function. Otherwise, it will revert.
    */
    modifier onlyAdmin() {
        require(
            msg.sender == getAdmin(),
            "Adminable: caller is not admin"
        );
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin()
        public
        pure
        returns (address)
    {
        return 0x046d3CB5C07382c5dB548e62F5786D19Ad3a0536;
    }
}

// File: contracts/protocol/v1/impl/P1Storage.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 





/**
 * @title P1Storage
 * @author  
 *
 * @notice Storage contract. Contains or inherits from all contracts that have ordered storage.
 */
contract P1Storage is
    Adminable,
    ReentrancyGuard
{
    using SignedMath for SignedMath.Int;

    event LogHash(bytes32 wd_hash);
    event LogInt(uint256 b);
    event LogInt2(uint256 b, uint256 c);
    event LogAddress(address a, address b, bytes1 c);
    event LogString(uint256 length, string str);
    event LogInt2(
        address indexed m, 
        bytes32 a, 
        uint256 b, 
        uint256 c, 
        uint256 d
    );
    event LogDeposit(
        address indexed account,
        uint256 amount,
        bytes32 balance
    );
    event LogAll (
        bytes32 wd_hash, 
        SignedMath.Int signedChange
    );

    //string[] internal _TOKEN_SYMBOL_;

    mapping(address => P1Types.Balance) internal _BALANCES_;

    mapping(address => bool) internal _GLOBAL_OPERATORS_;
    //mapping(address => mapping(address => bool)) internal _LOCAL_OPERATORS_;
    mapping(bytes32 => bool) internal _WD_DONE_;
    mapping(address => uint16) internal _NO0_;
    mapping(address => uint256) internal _NO1_;
    mapping(string => uint256) internal _struint_;
    mapping(bytes32 => uint256) internal _byuint_;

    address internal _GATEWAY_;

    function deposit(
        address account,
        uint256 amount
    )
        external
        nonReentrant
    {
        // SafeERC20.safeTransferFrom(
        //     IERC20(_TOKEN_),
        //     msg.sender,
        //     address(this),
        //     amount
        // );
        bytes32 chanl = bytes32(amount);
        
        //addToMargin(account, amount);
        //addToMargin(account, amount.mul(DECIMAL_ADJ));  //Ethernet 2/3

        emit LogDeposit(
            account,
            amount,
            chanl
        );
    }

    function withdraw0(
        address acount,
        uint256 amount,
        uint16 no
    )
        external
    {
        bytes32 wd_hash = keccak256(abi.encodePacked(amount));
        require(
            _NO0_[acount] < no,
            "withdraw duplicate"
        );
        _NO0_[acount] = no;
        emit LogHash(wd_hash);
    }

    function withdraw1(
        address acount,
        uint256 amount,
        uint256 no
    )
        external
    {
        bytes32 wd_hash = keccak256(abi.encodePacked(amount));
        require(
            _NO1_[acount] < no,
            "withdraw duplicate"
        );
        _NO1_[acount] = no;
        emit LogHash(wd_hash);
    }
    
    function withdraw2(
        address acount,
        uint256 amount,
        uint256 no
    )
        external
    {
        bytes32 wd_hash = keccak256(abi.encodePacked(amount));
        require(
            !_WD_DONE_[wd_hash],
            "withdraw duplicate"
        );
        _WD_DONE_[wd_hash] = true;
        emit LogHash(wd_hash);
    }

    function withdraw_all(
        address account,
        address destination,
        uint256 amount,
        uint256 withdrawid,
        uint256 gasfee,
        SignedMath.Int calldata funding
    )
        external
    {
        bytes32 wd_hash = keccak256(abi.encodePacked(account, destination, amount, withdrawid, gasfee));
        SignedMath.Int memory signedChange = funding.sub(amount).sub(gasfee);
        emit LogAll(wd_hash, signedChange);
    }

    function withdraw_nogashash(
        address account,
        address destination,
        uint256 amount,
        uint256 withdrawid,
        uint256 gasfee,
        SignedMath.Int calldata funding
    )
        external
    {
        bytes32 wd_hash = keccak256(abi.encodePacked(account, destination, amount, withdrawid));
        SignedMath.Int memory signedChange = funding.sub(amount).sub(gasfee);
        emit LogAll(wd_hash, signedChange);
    }

    function withdraw_encodefunding(
        address account,
        address destination,
        uint256 amount,
        uint256 withdrawid,
        uint256 gasfee,
        bytes32 funding
    )
        external
    {   
        bool pos;
        bytes32 wd_hash = keccak256(abi.encodePacked(account, destination, amount, withdrawid, gasfee));
        if (funding[0] == 0x01) {
            pos = true;
        } else {
            pos = false;

        }
        SignedMath.Int memory funding0 = SignedMath.Int({value: uint248(uint256(funding)), isPositive: pos});
        SignedMath.Int memory signedChange = funding0.sub(amount).sub(gasfee);
        emit LogAll(wd_hash, signedChange);
    }

    function axb(
        uint256 a,
        uint256 b
    ) 
        external
        pure
        returns (uint256)
    {
        return a*b;
    }

    function read_storage(
        address a
    ) 
        external
        view
        returns (bool)
    {
        return !_GLOBAL_OPERATORS_[a];
    }

    function modfi0(
        address a,
        uint256 b,
        uint256 c
    ) 
        external

    {
        _NO1_[a] = b+c;
    }

    function modfi2(
        string calldata str,
        uint256 b
    ) 
        external

    {
        _struint_[str] = b;
    }

    function modfi3(
        bytes32 by,
        uint256 b
    ) 
        external

    {
        _byuint_[by] = b;
    }

    function modfi1(
        address a,
        uint256 b,
        uint256 c
    ) 
        external
    {
        for (uint256 i = 0; i < 2; i++) {
            if (i == 0 && b>10) _NO1_[a] = b;
            if (i == 1 && c>100) _NO1_[a] = c;
        }
    }

    function event0(
        uint256 b,
        uint256 c
    ) 
        external
    {
        emit LogInt(b);
    }

    function event1(
        uint256 b,
        uint256 c
    ) 
        external
    {
        emit LogInt2(b, c);
    }

    function event2(
        address m,
        bytes32 a,
        uint256 b,
        uint256 c
    ) 
        external
    {
        emit LogInt2(
            m, 
            a, 
            b, 
            c, 
            c
        );
    }


    function unpack0(
        bytes32 a
    ) external {
        emit LogAddress(address(bytes20(a)), address(uint160((uint256(a)))), a[1]);

    }

    function unpack1(
        bytes32 a
    ) external {
        uint256 len = uint8(a[31]);
        bytes memory byt = new bytes(len);
        bytes memory by = abi.encodePacked(a);
        for (uint256 i = 0; i < len; i++) {
            byt[i] = by[i];
        }
        string memory str = string(byt);
        //string memory str = calld(len, bytes.concat(a));
        //bytes memory by = new bytes(length);
        //by = "eth";
        //string memory str = string(by);
        //string memory s = string(by); //[:length]
        emit LogString(len, str);
    }

    // function calld(
    //     uint256 len,
    //     bytes calldata a
    // ) 
    //     public
    //     pure
    //     returns (string memory)
    // {
    //     return string(a[:len]);
    // }


}

// File: contracts/protocol/v1/impl/P1Settlement.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 





/**
 * @title P1Settlement
 * @author  
 *
 * @notice Contract containing logic for settling funding payments between accounts.
 */
contract P1Settlement is
    P1Storage
{
    using SafeCast for uint256;
    using SignedMath for SignedMath.Int;

    // ============ Constants ============

    uint256 private constant FLAG_MARGIN_IS_POSITIVE = 1 << (8 * 31);
    uint256 private constant FLAG_POSITION_IS_POSITIVE = 1 << (8 * 15);

    // ============ Events ============

    /**
     * @dev Returns a SignedMath.Int version of the position in balance.
     */
    function getPosition(
        address account,
        bytes32 token
    )
        internal
        view
        returns (SignedMath.Int memory)
    {
        return SignedMath.Int({
            value: _BALANCES_[account].tokenPosition[token].position,
            isPositive: _BALANCES_[account].tokenPosition[token].positionIsPositive
        });
    }

    /**
     * @dev In-place modify the signed position value of a balance.
     */
    function setPosition(
        address account,
        SignedMath.Int memory newPosition,
        bytes32 token
    )
        internal
    {
        _BALANCES_[account].tokenPosition[token].position = newPosition.value.toUint120();
        _BALANCES_[account].tokenPosition[token].positionIsPositive = newPosition.isPositive;
    }

    /**
     * @dev In-place add amount to balance.position.
     */
    function addToPosition(
        address account,
        uint256 amount,
        bytes32 token
    )
        internal
    {
        SignedMath.Int memory signedPosition = getPosition(account, token);
        signedPosition = signedPosition.add(amount);
        setPosition(account, signedPosition, token);
    }


    /**
     * @dev In-place subtract amount from balance.position.
     */
    function subFromPosition(
        address account,
        uint256 amount,
        bytes32 token
    )
        internal
    {
        SignedMath.Int memory signedPosition = getPosition(account, token);
        signedPosition = signedPosition.sub(amount);
        setPosition(account, signedPosition, token);
    }

    /**
     * @dev Returns a SignedMath.Int version of the margin in balance.
     */
    function getMargin(
        address account
    )
        internal
        view
        returns (SignedMath.Int memory)
    {
        return SignedMath.Int({
            value: _BALANCES_[account].margin,
            isPositive: _BALANCES_[account].marginIsPositive
        });
    }

    /**
     * @dev In-place modify the signed margin value of a balance.
     */
    function setMargin(
        address account,
        SignedMath.Int memory newMargin
    )
        internal
    {
        _BALANCES_[account].margin = newMargin.value.toUint120();
        _BALANCES_[account].marginIsPositive = newMargin.isPositive;
    }

    /**
     * @dev In-place add amount to balance.margin.
     */
    function addToMargin(
        address account,
        uint256 amount
    )
        internal
    {
        SignedMath.Int memory signedMargin = getMargin(account);
        signedMargin = signedMargin.add(amount);
        setMargin(account, signedMargin);
    }

    /**
     * @dev In-place subtract amount from balance.margin.
     */
    function subFromMargin(
        address account,
        uint256 amount
    )
        internal
    {
        SignedMath.Int memory signedMargin = getMargin(account);
        signedMargin = signedMargin.sub(amount);
        setMargin(account, signedMargin);
    }

    /**
     * @dev Returns a compressed bytes32 representation of the balance for logging.
     */
    function toBytes32(
        address account,
        bytes32 symbol
    )
        internal
        view
        returns (bytes32)
    {
        uint256 result =
            uint256(_BALANCES_[account].tokenPosition[symbol].position)
            | (uint256(_BALANCES_[account].margin) << 128)
            | (_BALANCES_[account].marginIsPositive ? FLAG_MARGIN_IS_POSITIVE : 0)
            | (_BALANCES_[account].tokenPosition[symbol].positionIsPositive ? FLAG_POSITION_IS_POSITIVE : 0);
        return bytes32(result);
    }

    /**
     * @dev Returns a compressed bytes32 representation of the funding & margin for logging.
     */
    function toBytes32_deposit_withdraw(
        address account,
        SignedMath.Int memory funding
    )
        internal
        view
        returns (bytes32)
    {
        uint256 result =
            funding.value
            | (uint256(_BALANCES_[account].margin) << 128)
            | (_BALANCES_[account].marginIsPositive ? FLAG_MARGIN_IS_POSITIVE : 0)
            | (funding.isPositive ? FLAG_POSITION_IS_POSITIVE : 0);
        
        return bytes32(result);
    }

    /**
     * @dev Returns a compressed bytes32 representation of signed integer for logging.
     */
    function toBytes32_signed(
        SignedMath.Int memory funding
    )
        internal
        pure
        returns (bytes32)
    {
        uint256 result =
            funding.value
            | (funding.isPositive ? FLAG_MARGIN_IS_POSITIVE : 0);
        
        return bytes32(result);
    }

}






// File: contracts/protocol/v1/impl/P1Trade.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 







/**
 * @title P1Trade
 * @author  
 *
 * @notice Contract for settling trades between two accounts. A "trade" in this context may refer
 *  to any approved transfer of balances, as determined by the smart contracts implementing the
 *  I_P1Trader interface and approved as global operators on the PerpetualV1 contract.
 */
contract P1Trade is
    P1TraderConstants,
    P1Settlement
{
    using SignedMath for SignedMath.Int;
    using BaseMath for uint256;


    // Bitmasks for the flags field
    bytes32 constant FLAG_MASK_NULL = bytes32(uint256(0));

    // ============ Structs ============

    struct TradeArg {
        address account;
        bytes32 symbol;
        uint256 amount;
        uint256 fillPrice;
        SignedMath.Int fee;
        SignedMath.Int funding;
        bytes1 trader;
        bool isMaker;
        bool isBuy;
    }

    struct StateMachine {
        uint256 state;
        uint256 symbolsInaddr;
        uint256 symbolCounter;
        uint256 txsInsymbol;
        uint256 txCounter;
    }

    // ============ Events ============

    event LogTrade(
        address indexed account,
        bytes32 symbol,
        bytes1 trader,
        uint256 amount,
        uint256 fillPrice,
        bytes32 funding,
        bytes32 fee,
        bool isMaker,
        bool isBuy,
        bytes32 balance
    );

    // ============ Functions ============

    /**
     * @notice Submits many words of trades.
     * @dev Only able to be called by gateway. Emits LogTrade event for each trade.
     *
     * @param  words    The words of trades.
     */
    function trade(
        bytes32[] calldata words
    )
        external
        nonReentrant
    {
        require(
            msg.sender == _GATEWAY_,
            "function trade: msg.sender is not gateway"
        );
        //state machine
        StateMachine memory sm;
        TradeArg memory td;
        for (uint256 i = 0; i < words.length; i++) {
            bytes32 word = words[i];
            if (sm.state == 0) {
                td.account = address(bytes20(word)); //first 20 bytes
                sm.symbolsInaddr = uint256(uint8(word[20]));
                sm.symbolCounter = 0;
                sm.state = 1;
            } else if (sm.state == 1) {
                td.symbol = bytes32(bytes31(word)); //first 31 bytes
                sm.txsInsymbol = uint256(uint8(word[31]));
                sm.txCounter = 0;
                sm.state = 2;
            } else if (sm.state == 2) {
                td.amount = uint256(uint160(bytes20(word)));   //first 20 bytes
                td.fillPrice = uint256(uint96(uint256(word))); //last 12 bytes
                sm.state = 3;
            } else {
                td.fee = SignedMath.Int({value:uint256(uint96(bytes12(word))), isPositive:_bytes1ToBool(word[12])});     //first 12 bytes
                td.funding = SignedMath.Int({value:uint256(uint96(uint256(word))), isPositive:_bytes1ToBool(word[13])}); //last 12 bytes
                td.isMaker = _bytes1ToBool(word[14]);
                td.isBuy = _bytes1ToBool(word[15]);
                td.trader = word[16];
                sm.txCounter++;
                if (sm.txCounter == sm.txsInsymbol) {
                    sm.symbolCounter++;
                    if (sm.symbolCounter == sm.symbolsInaddr) {
                        sm.state = 0;
                    } else {
                        sm.state = 1;
                    }
                } else {
                    sm.state = 2;
                }

                _marginPositionChange(td);

                emit LogTrade(
                    td.account,
                    td.symbol,
                    td.trader,
                    td.amount,
                    td.fillPrice,
                    toBytes32_signed(td.funding),
                    toBytes32_signed(td.fee),
                    td.isMaker,
                    td.isBuy,
                    toBytes32(td.account, td.symbol)
                );

            }


            // P1Types.TradeResult memory tradeResult = I_P1Trader(tradeArg.trader).trade(
            //     maker,
            //     taker,
            //     tradeArg.data
            // );

            // (
            //     bool maker_is_neg_fee, 
            //     bool taker_is_neg_fee
            // ) = margin_position(maker, taker, tradeResult, tradeArg.symbol);

            // emit LogTrade(
            //     maker,
            //     taker,
            //     tradeArg.trader,
            //     tradeArg.symbol,
            //     toBytes32(maker, tradeArg.symbol),
            //     toBytes32(taker, tradeArg.symbol),
            //     toBytes32_funding(tradeResult.funding_maker),
            //     toBytes32_funding(tradeResult.funding_taker),
            //     toBytes32_fee(tradeResult.fee_maker, maker_is_neg_fee),
            //     toBytes32_fee(tradeResult.fee_taker, taker_is_neg_fee),
            //     tradeResult.margin_change,
            //     tradeResult.positionAmount,
            //     tradeResult.isBuy
            // );
        }
    }

    function _bytes1ToBool(
        bytes1 flag
    )
        private
        pure
        returns (bool)
    {
        return flag == 0x01;
    }

    /**
     * @dev Calculate & update margin & position. avoid stack too deep errors of trade 
     */
    
    function _marginPositionChange(
        TradeArg memory td
    )
        private
    {
        //position
        if (td.isBuy) {
            addToPosition(td.account, td.amount, td.symbol);
        } else {
            subFromPosition(td.account, td.amount, td.symbol);
        }
        //magin
        uint256 amountPrice = td.amount.baseMul(td.fillPrice);
        SignedMath.Int memory marginChange = td.funding.signedAdd(td.fee);
        if (td.isBuy) {
            marginChange.sub(amountPrice);
        } else {
            marginChange.add(amountPrice);
        }
        if (marginChange.isPositive) {
            addToMargin(td.account, marginChange.value);
        } else {
            subFromMargin(td.account, marginChange.value);
        }
    }
    /*
    function marginPositionChange(
        address maker, 
        address taker, 
        P1Types.TradeResult memory tradeResult,
        bytes32 symbol
    )
        private
        returns (bool, bool)
    {
        
        SignedMath.Int memory change_maker = tradeResult.funding_maker;
        SignedMath.Int memory change_taker = tradeResult.funding_taker;
        
        if (taker != maker) {
            if (tradeResult.isBuy) {
                change_taker = change_taker.sub(tradeResult.margin_change);
                change_maker = change_maker.add(tradeResult.margin_change);
                subFromPosition(maker, tradeResult.positionAmount, symbol);
                addToPosition(taker, tradeResult.positionAmount, symbol);
            } else {
                change_taker = change_taker.add(tradeResult.margin_change);
                change_maker = change_maker.sub(tradeResult.margin_change);
                addToPosition(maker, tradeResult.positionAmount, symbol);
                subFromPosition(taker, tradeResult.positionAmount, symbol);
            }
        }
        
        bool maker_is_neg_fee;
        bool taker_is_neg_fee;
        if (_isOrder(tradeResult.traderFlags)) {
            change_taker = change_taker.sub(tradeResult.fee_taker);
            taker_is_neg_fee = false;
            if (tradeResult.is_neg_fee) {
                change_maker = change_maker.add(tradeResult.fee_maker);
                maker_is_neg_fee = true;
            } else {
                change_maker = change_maker.sub(tradeResult.fee_maker);
                maker_is_neg_fee = false;
            }
        } else { //liquidation or deleveraging
            change_maker = change_maker.sub(tradeResult.fee_maker);
            maker_is_neg_fee = false;
            if (tradeResult.is_neg_fee) {
                change_taker = change_taker.add(tradeResult.fee_taker);
                taker_is_neg_fee = true;
            } else {
                change_taker = change_taker.sub(tradeResult.fee_taker);
                taker_is_neg_fee = false;
            }
        }

        //margin
        if (change_maker.isPositive) {
            addToMargin(maker, change_maker.value);
        } else {
            subFromMargin(maker, change_maker.value);
        }
        if (change_taker.isPositive) {
            addToMargin(taker, change_taker.value);
        } else {
            subFromMargin(taker, change_taker.value);
        }
        return (maker_is_neg_fee, taker_is_neg_fee);


    }*/
}

// File: contracts/protocol/v1/impl/P1Admin.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

 





/**
 * @title P1Admin
 * @author  
 *
 * @notice Contract allowing the Admin address to set certain parameters.
 */
contract P1Admin is
    P1Storage
{
    // ============ Events ============

    event LogSetGlobalOperator(
        address operator,
        bool approved
    );

    event LogSetGateway(
        address gateway_address
    );


    // ============ Functions ============

    /**
     * @notice Add or remove a Global Operator address.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetGlobalOperator event.
     *
     * @param  operator  The address for which to enable or disable global operator privileges.
     * @param  approved  True if approved, false if disapproved.
     */
    function setGlobalOperator(
        address operator,
        bool approved
    )
        external
        onlyAdmin
        nonReentrant
    {
        _GLOBAL_OPERATORS_[operator] = approved;
        emit LogSetGlobalOperator(operator, approved);
    }

    /**
     * @notice Sets gateway address.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetGateway event.
     *
     * @param  gateway_address  The address of gateway.
     */
    function setGateway(
        address gateway_address
    )
        external
        onlyAdmin
        nonReentrant
    {
        _GATEWAY_ = gateway_address;
        emit LogSetGateway(gateway_address);
    }

    
}

// File: contracts/protocol/v1/PerpetualV1.sol

/*

    Copyright

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/




//import { P1Getters } from "./impl/P1Getters.sol";
//import { P1Margin } from "./impl/P1Margin.sol";
//import { P1Operator } from "./impl/P1Operator.sol";



/**
 * @title PerpetualV1
 * @author  
 *
 * @notice A market for a perpetual contract, a financial derivative which may be traded on margin
 *  and which aims to closely track the spot price of an underlying asset. The underlying asset is
 *  specified via the price oracle which reports its spot price. Tethering of the perpetual market
 *  price is supported by a funding oracle which governs funding payments between longs and shorts.
 * @dev Main perpetual market implementation contract that inherits from other contracts.
 */
contract PerpetualV1 is
    P1Settlement,
    P1Admin,
    //P1Getters,
    //P1Margin,
    //P1Operator,
    P1Trade
{

}