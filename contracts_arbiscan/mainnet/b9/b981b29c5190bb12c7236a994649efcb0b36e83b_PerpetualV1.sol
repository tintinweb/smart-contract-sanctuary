/**
 *Submitted for verification at arbiscan.io on 2022-01-12
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
     * @dev Used to represent the signature.
     */
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
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
        mapping(string => PositionStruct) tokenPosition;
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
        view
        returns (address)
    {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
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
    string[] internal _TOKEN_SYMBOL_;

    mapping(address => P1Types.Balance) internal _BALANCES_;

    mapping(address => bool) internal _GLOBAL_OPERATORS_;
    mapping(address => mapping(address => bool)) internal _LOCAL_OPERATORS_;
    mapping(bytes32 => bool) internal _WD_DONE_;

    address internal _TOKEN_;
    address internal _SIGNER1_;
    address internal _GATEWAY_;
    address internal _SIGNER0_;
    
}

// File: contracts/protocol/v1/impl/P1Operator.sol

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
 * @title P1Operator
 * @author  
 *
 * @notice Contract for setting local operators for an account.
 */
contract P1Operator is
    P1Storage
{
    // ============ Events ============

    event LogSetLocalOperator(
        address indexed sender,
        address operator,
        bool approved
    );

    // ============ Functions ============

    /**
     * @notice Grants or revokes permission for another account to perform certain actions on behalf
     *  of the sender.
     * @dev Emits the LogSetLocalOperator event.
     *
     * @param  operator  The account that is approved or disapproved.
     * @param  approved  True for approval, false for disapproval.
     */
    function setLocalOperator(
        address operator,
        bool approved
    )
        external
    {
        _LOCAL_OPERATORS_[msg.sender][operator] = approved;
        emit LogSetLocalOperator(msg.sender, operator, approved);
    }
}

// File: contracts/protocol/v1/impl/P1Getters.sol

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
 * @title P1Getters
 * @author  
 *
 * @notice Contract for read-only getters.
 */
contract P1Getters is
    P1Storage
{
    // ============ Account Getters ============

    /**
     * @notice Get the positions of an account, without accounting for changes in the index.
     *
     * @param  account  The address of the account to query the position of.
     * @param  symbol   Trading tokens pair name for short.
     * @return          The position of the account on the symbol.
     */
    function getAccountPosition(
        address account,
        string calldata symbol
    )
        external
        view
        returns (P1Types.PositionStruct memory)
    {
        return _BALANCES_[account].tokenPosition[symbol];
    }

    /**
     * @notice Get the Q value of an account, without accounting for changes in the index.
     *
     * @param  account  The address of the account to query the Qvalue of.
     * @return          The Qvalue of the account.
     */
    function getAccountQvalue(
        address account
    )
        external
        view
        returns (P1Types.MarginStruct memory)
    {
        return P1Types.MarginStruct({
            marginIsPositive: _BALANCES_[account].marginIsPositive,
            margin: _BALANCES_[account].margin
        });
    }

    /**
     * @notice Gets the local operator status of an operator for a particular account.
     *
     * @param  account   The account to query the operator for.
     * @param  operator  The address of the operator to query the status of.
     * @return           True if the operator is a local operator of the account, false otherwise.
     */
    function getIsLocalOperator(
        address account,
        address operator
    )
        external
        view
        returns (bool)
    {
        return _LOCAL_OPERATORS_[account][operator];
    }

    // ============ Global Getters ============

    /**
     * @notice Gets the global operator status of an address.
     *
     * @param  operator  The address of the operator to query the status of.
     * @return           True if the address is a global operator, false otherwise.
     */
    function getIsGlobalOperator(
        address operator
    )
        external
        view
        returns (bool)
    {
        return _GLOBAL_OPERATORS_[operator];
    }

    /**
     * @notice Gets the address of the gateway.
     *
     * @return The address of the gateway.
     */
    function getGateway()
        external
        view
        returns (address)
    {
        return _GATEWAY_;
    }

    /**
     * @notice Gets the address of the signer0.
     *
     * @return The address of the signer0.
     */
    function getSigner0()
        external
        view
        returns (address)
    {
        return _SIGNER0_;
    }

    /**
     * @notice Gets the address of the signer1.
     *
     * @return The address of the signer1.
     */
    function getSigner1()
        external
        view
        returns (address)
    {
        return _SIGNER1_;
    }

    /**
     * @notice Gets the address of the ERC20 margin contract used for margin deposits.
     *
     * @return The address of the ERC20 token.
     */
    function getTokenContract()
        external
        view
        returns (address)
    {
        return _TOKEN_;
    }

    /**
     * @notice Gets the symbols array.
     *
     * @return Array of trading tokens pair names for short.
     */
    function getSymbolArray()
        external
        view
        returns (string [] memory)
    {
        return _TOKEN_SYMBOL_;
    }

    // ============ Public Getters ============

    /**
     * @notice Gets whether an address has permissions to operate an account.
     *
     * @param  account   The account to query.
     * @param  operator  The address to query.
     * @return           True if the operator has permission to operate the account,
     *                   and false otherwise.
     */
    function hasAccountPermissions(
        address account,
        address operator
    )
        public
        view
        returns (bool)
    {
        return account == operator
            || _LOCAL_OPERATORS_[account][operator];
    }
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
        string memory token
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
        string memory token
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
        string memory token
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
        string memory token
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
        string memory symbol
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
     * @dev Returns a compressed bytes32 representation of fee for logging.
     */
    function toBytes32_fee(
        uint256 fee,
        bool is_neg_fee
    )
        internal
        pure
        returns (bytes32)
    {
        uint256 result =
            fee
            | (is_neg_fee ? 0 : FLAG_MARGIN_IS_POSITIVE);
        
        return bytes32(result);
    }

    /**
     * @dev Returns a compressed bytes32 representation of funding for logging.
     */
    function toBytes32_funding(
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

    // Bitmasks for the flags field
    bytes32 constant FLAG_MASK_NULL = bytes32(uint256(0));

    // ============ Structs ============

    struct TradeArg {
        uint256 takerIndex;
        uint256 makerIndex;
        string symbol; 
        address trader;
        bytes data;
    }

    // ============ Events ============

    event LogTrade(
        address indexed maker,
        address indexed taker,
        address trader,
        string symbol,
        bytes32 makerBalance,
        bytes32 takerBalance,
        bytes32 funding_maker,
        bytes32 funding_taker,
        bytes32 fee_maker,
        bytes32 fee_taker,
        uint256 margin_change,
        uint256 positionAmount,
        bool isBuy  //taker or liquidator

    );

    // ============ Functions ============

    /**
     * @notice Submits one or more trades between any number of accounts.
     * @dev Only able to be called by global operators. Emits the LogIndex event, 
     *  one LogAccountSettled event for each account in `accounts`, and the LogTrade event for each trade in `trades`.
     *
     * @param  accounts  The sorted list of accounts that are involved in trades.
     * @param  trades    The list of trades to execute in-order.
     */
    function trade(
        address[] calldata accounts,
        TradeArg[] calldata trades
    )
        external
        nonReentrant
    {
        require(
            msg.sender == _GATEWAY_,
            "function trade: msg.sender is not gateway"
        );
        _verifyAccounts(accounts);

        for (uint256 i = 0; i < trades.length; i++) {
            TradeArg memory tradeArg = trades[i];

            require(
                _GLOBAL_OPERATORS_[tradeArg.trader],
                "trader is not global operator"
            );

            address maker = accounts[tradeArg.makerIndex];
            address taker = accounts[tradeArg.takerIndex];

            P1Types.TradeResult memory tradeResult = I_P1Trader(tradeArg.trader).trade(
                maker,
                taker,
                tradeArg.data
            );

            (
                bool maker_is_neg_fee, 
                bool taker_is_neg_fee
            ) = margin_position(maker, taker, tradeResult, tradeArg.symbol);

            emit LogTrade(
                maker,
                taker,
                tradeArg.trader,
                tradeArg.symbol,
                toBytes32(maker, tradeArg.symbol),
                toBytes32(taker, tradeArg.symbol),
                toBytes32_funding(tradeResult.funding_maker),
                toBytes32_funding(tradeResult.funding_taker),
                toBytes32_fee(tradeResult.fee_maker, maker_is_neg_fee),
                toBytes32_fee(tradeResult.fee_taker, taker_is_neg_fee),
                tradeResult.margin_change,
                tradeResult.positionAmount,
                tradeResult.isBuy
            );
        }
    }

    /**
     * @dev Trader is order.
     *
     */
    function _isOrder(
        bytes32 traderFlags
    )
        private
        pure
        returns (bool)
    {
        return (traderFlags & TRADER_FLAG_ORDERS) != FLAG_MASK_NULL;
    }

    /**
     * @dev Verify that `accounts` contains at least one address and that the contents are unique.
     *  We verify uniqueness by requiring that the array is sorted.
     */
    function _verifyAccounts(
        address[] memory accounts
    )
        private
        pure
    {
        require(
            accounts.length > 0,
            "Accounts must have non-zero length"
        );

        // Check that accounts are unique
        address prevAccount = accounts[0];
        for (uint256 i = 1; i < accounts.length; i++) {
            address account = accounts[i];
            require(
                account > prevAccount,
                "Accounts must be sorted and unique"
            );
            prevAccount = account;
        }
    }

    /**
     * @dev Calculate & update margin & position. avoid stack too deep errors of trade 
     */
    function margin_position(
        address maker, 
        address taker, 
        P1Types.TradeResult memory tradeResult,
        string memory symbol
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


    }
}

// File: contracts/protocol/v1/impl/P1Margin.sol

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
 * @title P1Margin
 * @author  
 *
 * @notice Contract for withdrawing and depositing.
 */
contract P1Margin is
    P1Settlement,
    P1Getters
{
    using SafeMath for uint256;
    using SignedMath for SignedMath.Int;

    uint256 constant internal DECIMAL_ADJ = 10 ** (18 - 6); //Ethernet 1/3

    // ============ Events ============

    event LogDeposit(
        address indexed account,
        uint256 amount,
        bytes32 balance
    );

    event LogWithdraw(
        address indexed account,
        address destination,
        uint256 amount,
        bytes32 balance
    );

    // ============ Functions ============

    /**
     * @notice Deposit some amount of margin tokens from the msg.sender into an account.
     * @dev Emits LogIndex, LogAccountSettled, and LogDeposit events.
     *
     * @param  account  The account for which to credit the deposit.
     * @param  amount   the amount of tokens to deposit.
     */
    function deposit(
        address account,
        uint256 amount
    )
        external
        nonReentrant
    {
        SafeERC20.safeTransferFrom(
            IERC20(_TOKEN_),
            msg.sender,
            address(this),
            amount
        );
        
        //addToMargin(account, amount);
        addToMargin(account, amount.mul(DECIMAL_ADJ));  //Ethernet 2/3

        emit LogDeposit(
            account,
            amount,
            toBytes32_deposit_withdraw(account, SignedMath.Int({value:0, isPositive:false}))
        );
    }

    /**
     * @notice Withdraw some amount of margin tokens from an account to a destination address.
     * @dev Emits LogWithdraw event. 
     *
     * @param  funding      The funding of the account
     * @param  amount       The amount of tokens to withdraw.
     * @param  destination  The address to which the tokens are transferred.
     * @param  timestamp    The timestamp of the withdraw apply
     * @param  signer0      Signer0 signature
     * @param  signer1      Signer1 signature
     */
    function withdraw(
        SignedMath.Int calldata funding,
        address account,
        address destination,
        uint256 amount,
        uint256 timestamp,
        P1Types.Signature calldata signer0,
        P1Types.Signature calldata signer1
    )
        external
        nonReentrant
    {
        require(
            hasAccountPermissions(account, msg.sender),
            "withdraw sender does not have permission to withdraw"
        );

        //check duplication
        bytes32 wd_hash = _getApplyHash(account, destination, amount, timestamp);
        require(
            !_WD_DONE_[wd_hash],
            "withdraw duplicate"
        );

        //check signature
        wd_hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", wd_hash));
        require(
            _SIGNER0_ == ecrecover(wd_hash, signer0.v, signer0.r, signer0.s),
            "withdraw invalid signer0"
        );
        require(
            _SIGNER1_ == ecrecover(wd_hash, signer1.v, signer1.r, signer1.s),
            "withdraw invalid signer1"
        );

        _WD_DONE_[wd_hash] = true;

        SafeERC20.safeTransfer(
            IERC20(_TOKEN_),
            destination,
            amount
        );
        
        SignedMath.Int memory signedChange = funding.sub(amount.mul(DECIMAL_ADJ)); //Ethernet 3/3
        //SignedMath.Int memory signedChange = funding.sub(amount);

        if (signedChange.isPositive) {
            addToMargin(account, signedChange.value);
        }  else {
            subFromMargin(account, signedChange.value);
        }
        
        bytes32 margin_funding = toBytes32_deposit_withdraw(account, funding);
        emit LogWithdraw(
            account,
            destination,
            amount,
            margin_funding
        );
    }

    /**
     * @dev Returns the hash of an withdraw apply.
     */
    function _getApplyHash(
        address account, 
        address destination, 
        uint256 amount,
        uint256 timestamp
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, destination, amount, timestamp));
    }

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

    event LogSetSigner0(
        address signer0_address
    );

    event LogSetSigner1(
        address signer1_address
    );

    event LogSetToken(
        address token_address
    );

    event LogSetTokenSymbolInitial(string [] token_symbol);

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

    /**
     * @notice Sets signer0 address.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetSigner0 event.
     *
     * @param  signer0_address  The address of signer0.
     */
    function setSigner0(
        address signer0_address
    )
        external
        onlyAdmin
        nonReentrant
    {
        _SIGNER0_ = signer0_address;
        emit LogSetSigner0(signer0_address);
    }

    /**
     * @notice Sets signer1 address.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetSigner1 event.
     *
     * @param  signer1_address  The address of signer1.
     */
    function setSigner1(
        address signer1_address
    )
        external
        onlyAdmin
        nonReentrant
    {
        _SIGNER1_ = signer1_address;
        emit LogSetSigner1(signer1_address);
    }

    /**
     * @notice Sets a new token contract.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetToken event.
     *
     * @param  token_address  The address of the token smart contract.
     */
    function setToken(
        address token_address
    )
        external
        onlyAdmin
        nonReentrant
    {
        IERC20(token_address).totalSupply();
        _TOKEN_ = token_address;
        emit LogSetToken(token_address);
    }

    /**
     * @notice Initialize symbols array for adding new symbols.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetTokenSymbolInitial event.
     *
     * @param  symbol_array  array of trading tokens pair names for short.
     */
    function setTokenSymbolInitial(
        string[] calldata symbol_array
    )
        external
        onlyAdmin
        nonReentrant
    {
        _TOKEN_SYMBOL_ = new string[](symbol_array.length);
        for (uint256 i = 0; i < symbol_array.length; i++) {
            _TOKEN_SYMBOL_[i] = symbol_array[i];
        }
        emit LogSetTokenSymbolInitial(_TOKEN_SYMBOL_);
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
    P1Getters,
    P1Margin,
    P1Operator,
    P1Trade
{
    // Non-colliding storage slot.
    bytes32 internal constant PERPETUAL_V1_INITIALIZE_SLOT =
    bytes32(uint256(keccak256(" .PerpetualV1.initialize")) - 1);

    /**
     * @dev Once-only initializer function that replaces the constructor since this contract is
     *  proxied. Uses a non-colliding storage slot to store if this version has been initialized.
     * @dev Can only be called once and can only be called by the admin of this contract.
     *
     * @param  token          The address of the token to use for margin-deposits.
     */
    function initializeV1(
        address token
    )
        external
        onlyAdmin
        nonReentrant
    {
        // only allow initialization once
        require(
            Storage.load(PERPETUAL_V1_INITIALIZE_SLOT) == 0x0,
            "PerpetualV1 already initialized"
        );
        Storage.store(PERPETUAL_V1_INITIALIZE_SLOT, bytes32(uint256(1)));

        _TOKEN_ = token;
    }
}