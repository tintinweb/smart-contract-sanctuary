/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @bancor/token-governance/contracts/IClaimable.sol


pragma solidity 0.6.12;

/// @title Claimable contract interface
interface IClaimable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// File: @bancor/token-governance/contracts/IMintableToken.sol


pragma solidity 0.6.12;



/// @title Mintable Token interface
interface IMintableToken is IERC20, IClaimable {
    function issue(address to, uint256 amount) external;

    function destroy(address from, uint256 amount) external;
}

// File: @bancor/token-governance/contracts/ITokenGovernance.sol


pragma solidity 0.6.12;


/// @title The interface for mintable/burnable token governance.
interface ITokenGovernance {
    // The address of the mintable ERC20 token.
    function token() external view returns (IMintableToken);

    /// @dev Mints new tokens.
    ///
    /// @param to Account to receive the new amount.
    /// @param amount Amount to increase the supply by.
    ///
    function mint(address to, uint256 amount) external;

    /// @dev Burns tokens from the caller.
    ///
    /// @param amount Amount to decrease the supply by.
    ///
    function burn(uint256 amount) external;
}

// File: solidity/contracts/utility/interfaces/ICheckpointStore.sol


pragma solidity 0.6.12;

/**
 * @dev Checkpoint store contract interface
 */
interface ICheckpointStore {
    function addCheckpoint(address _address) external;

    function addPastCheckpoint(address _address, uint256 _time) external;

    function addPastCheckpoints(address[] calldata _addresses, uint256[] calldata _times) external;

    function checkpoint(address _address) external view returns (uint256);
}

// File: solidity/contracts/utility/MathEx.sol


pragma solidity 0.6.12;

/**
 * @dev This library provides a set of complex math operations.
 */
library MathEx {
    uint256 private constant MAX_EXP_BIT_LEN = 4;
    uint256 private constant MAX_EXP = 2**MAX_EXP_BIT_LEN - 1;
    uint256 private constant MAX_UINT128 = 2**128 - 1;

    /**
     * @dev returns the largest integer smaller than or equal to the square root of a positive integer
     *
     * @param _num a positive integer
     *
     * @return the largest integer smaller than or equal to the square root of the positive integer
     */
    function floorSqrt(uint256 _num) internal pure returns (uint256) {
        uint256 x = _num / 2 + 1;
        uint256 y = (x + _num / x) / 2;
        while (x > y) {
            x = y;
            y = (x + _num / x) / 2;
        }
        return x;
    }

    /**
     * @dev returns the smallest integer larger than or equal to the square root of a positive integer
     *
     * @param _num a positive integer
     *
     * @return the smallest integer larger than or equal to the square root of the positive integer
     */
    function ceilSqrt(uint256 _num) internal pure returns (uint256) {
        uint256 x = floorSqrt(_num);
        return x * x == _num ? x : x + 1;
    }

    /**
     * @dev computes a powered ratio
     *
     * @param _n   ratio numerator
     * @param _d   ratio denominator
     * @param _exp ratio exponent
     *
     * @return powered ratio's numerator and denominator
     */
    function poweredRatio(
        uint256 _n,
        uint256 _d,
        uint256 _exp
    ) internal pure returns (uint256, uint256) {
        require(_exp <= MAX_EXP, "ERR_EXP_TOO_LARGE");

        uint256[MAX_EXP_BIT_LEN] memory ns;
        uint256[MAX_EXP_BIT_LEN] memory ds;

        (ns[0], ds[0]) = reducedRatio(_n, _d, MAX_UINT128);
        for (uint256 i = 0; (_exp >> i) > 1; i++) {
            (ns[i + 1], ds[i + 1]) = reducedRatio(ns[i] ** 2, ds[i] ** 2, MAX_UINT128);
        }

        uint256 n = 1;
        uint256 d = 1;

        for (uint256 i = 0; (_exp >> i) > 0; i++) {
            if (((_exp >> i) & 1) > 0) {
                (n, d) = reducedRatio(n * ns[i], d * ds[i], MAX_UINT128);
            }
        }

        return (n, d);
    }

    /**
     * @dev computes a reduced-scalar ratio
     *
     * @param _n   ratio numerator
     * @param _d   ratio denominator
     * @param _max maximum desired scalar
     *
     * @return ratio's numerator and denominator
     */
    function reducedRatio(
        uint256 _n,
        uint256 _d,
        uint256 _max
    ) internal pure returns (uint256, uint256) {
        (uint256 n, uint256 d) = (_n, _d);
        if (n > _max || d > _max) {
            (n, d) = normalizedRatio(n, d, _max);
        }
        if (n != d) {
            return (n, d);
        }
        return (1, 1);
    }

    /**
     * @dev computes "scale * a / (a + b)" and "scale * b / (a + b)".
     */
    function normalizedRatio(
        uint256 _a,
        uint256 _b,
        uint256 _scale
    ) internal pure returns (uint256, uint256) {
        if (_a <= _b) {
            return accurateRatio(_a, _b, _scale);
        }
        (uint256 y, uint256 x) = accurateRatio(_b, _a, _scale);
        return (x, y);
    }

    /**
     * @dev computes "scale * a / (a + b)" and "scale * b / (a + b)", assuming that "a <= b".
     */
    function accurateRatio(
        uint256 _a,
        uint256 _b,
        uint256 _scale
    ) internal pure returns (uint256, uint256) {
        uint256 maxVal = uint256(-1) / _scale;
        if (_a > maxVal) {
            uint256 c = _a / (maxVal + 1) + 1;
            _a /= c; // we can now safely compute `_a * _scale`
            _b /= c;
        }
        if (_a != _b) {
            uint256 n = _a * _scale;
            uint256 d = _a + _b; // can overflow
            if (d >= _a) {
                // no overflow in `_a + _b`
                uint256 x = roundDiv(n, d); // we can now safely compute `_scale - x`
                uint256 y = _scale - x;
                return (x, y);
            }
            if (n < _b - (_b - _a) / 2) {
                return (0, _scale); // `_a * _scale < (_a + _b) / 2 < MAX_UINT256 < _a + _b`
            }
            return (1, _scale - 1); // `(_a + _b) / 2 < _a * _scale < MAX_UINT256 < _a + _b`
        }
        return (_scale / 2, _scale / 2); // allow reduction to `(1, 1)` in the calling function
    }

    /**
     * @dev computes the nearest integer to a given quotient without overflowing or underflowing.
     */
    function roundDiv(uint256 _n, uint256 _d) internal pure returns (uint256) {
        return _n / _d + (_n % _d) / (_d - _d / 2);
    }

    /**
     * @dev returns the average number of decimal digits in a given list of positive integers
     *
     * @param _values  list of positive integers
     *
     * @return the average number of decimal digits in the given list of positive integers
     */
    function geometricMean(uint256[] memory _values) internal pure returns (uint256) {
        uint256 numOfDigits = 0;
        uint256 length = _values.length;
        for (uint256 i = 0; i < length; i++) {
            numOfDigits += decimalLength(_values[i]);
        }
        return uint256(10)**(roundDivUnsafe(numOfDigits, length) - 1);
    }

    /**
     * @dev returns the number of decimal digits in a given positive integer
     *
     * @param _x   positive integer
     *
     * @return the number of decimal digits in the given positive integer
     */
    function decimalLength(uint256 _x) internal pure returns (uint256) {
        uint256 y = 0;
        for (uint256 x = _x; x > 0; x /= 10) {
            y++;
        }
        return y;
    }

    /**
     * @dev returns the nearest integer to a given quotient
     * the computation is overflow-safe assuming that the input is sufficiently small
     *
     * @param _n   quotient numerator
     * @param _d   quotient denominator
     *
     * @return the nearest integer to the given quotient
     */
    function roundDivUnsafe(uint256 _n, uint256 _d) internal pure returns (uint256) {
        return (_n + _d / 2) / _d;
    }

    /**
     * @dev returns the larger of two values
     *
     * @param _val1 the first value
     * @param _val2 the second value
     */
    function max(uint256 _val1, uint256 _val2) internal pure returns (uint256) {
        return _val1 > _val2 ? _val1 : _val2;
    }
}

// File: solidity/contracts/utility/ReentrancyGuard.sol


pragma solidity 0.6.12;

/**
 * @dev This contract provides protection against calling a function
 * (directly or indirectly) from within itself.
 */
contract ReentrancyGuard {
    uint256 private constant UNLOCKED = 1;
    uint256 private constant LOCKED = 2;

    // LOCKED while protected code is being executed, UNLOCKED otherwise
    uint256 private state = UNLOCKED;

    /**
     * @dev ensures instantiation only by sub-contracts
     */
    constructor() internal {}

    // protects a function against reentrancy attacks
    modifier protected() {
        _protected();
        state = LOCKED;
        _;
        state = UNLOCKED;
    }

    // error message binary size optimization
    function _protected() internal view {
        require(state == UNLOCKED, "ERR_REENTRANCY");
    }
}

// File: solidity/contracts/utility/Types.sol


pragma solidity 0.6.12;

/**
 * @dev This contract provides types which can be used by various contracts.
 */

struct Fraction {
    uint256 n; // numerator
    uint256 d; // denominator
}

// File: solidity/contracts/utility/Time.sol


pragma solidity 0.6.12;

/*
    Time implementing contract
*/
contract Time {
    /**
     * @dev returns the current time
     */
    function time() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// File: solidity/contracts/utility/Utils.sol


pragma solidity 0.6.12;


/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);
        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address _address) {
        _validExternalAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address _address) internal view {
        require(_address != address(0) && _address != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);
        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// File: solidity/contracts/utility/interfaces/IOwned.sol


pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// File: solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;


/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
     * @dev triggered when the owner is updated
     *
     * @param _prevOwner previous owner
     * @param _newOwner  new owner
     */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     * the new owner still needs to accept the transfer
     * can only be called by the contract owner
     *
     * @param _newOwner    new contract owner
     */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/converter/interfaces/IConverterAnchor.sol


pragma solidity 0.6.12;


/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned {

}

// File: solidity/contracts/token/interfaces/IDSToken.sol


pragma solidity 0.6.12;




/*
    DSToken interface
*/
interface IDSToken is IConverterAnchor, IERC20 {
    function issue(address _to, uint256 _amount) external;

    function destroy(address _from, uint256 _amount) external;
}

// File: solidity/contracts/token/interfaces/IReserveToken.sol


pragma solidity 0.6.12;

/**
 * @dev This contract is used to represent reserve tokens, which are tokens that can either be regular ERC20 tokens or
 * native ETH (represented by the NATIVE_TOKEN_ADDRESS address)
 *
 * Please note that this interface is intentionally doesn't inherit from IERC20, so that it'd be possible to effectively
 * override its balanceOf() function in the ReserveToken library
 */
interface IReserveToken {

}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: solidity/contracts/token/SafeERC20Ex.sol


pragma solidity 0.6.12;


/**
 * @dev Extends the SafeERC20 library with additional operations
 */
library SafeERC20Ex {
    using SafeERC20 for IERC20;

    /**
     * @dev ensures that the spender has sufficient allowance
     *
     * @param token the address of the token to ensure
     * @param spender the address allowed to spend
     * @param amount the allowed amount to spend
     */
    function ensureApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 allowance = token.allowance(address(this), spender);
        if (allowance >= amount) {
            return;
        }

        if (allowance > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }
}

// File: solidity/contracts/token/ReserveToken.sol


pragma solidity 0.6.12;




/**
 * @dev This library implements ERC20 and SafeERC20 utilities for reserve tokens, which can be either ERC20 tokens or ETH
 */
library ReserveToken {
    using SafeERC20 for IERC20;
    using SafeERC20Ex for IERC20;

    // the address that represents an ETH reserve
    IReserveToken public constant NATIVE_TOKEN_ADDRESS = IReserveToken(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev returns whether the provided token represents an ERC20 or ETH reserve
     *
     * @param reserveToken the address of the reserve token
     *
     * @return whether the provided token represents an ERC20 or ETH reserve
     */
    function isNativeToken(IReserveToken reserveToken) internal pure returns (bool) {
        return reserveToken == NATIVE_TOKEN_ADDRESS;
    }

    /**
     * @dev returns the balance of the reserve token
     *
     * @param reserveToken the address of the reserve token
     * @param account the address of the account to check
     *
     * @return the balance of the reserve token
     */
    function balanceOf(IReserveToken reserveToken, address account) internal view returns (uint256) {
        if (isNativeToken(reserveToken)) {
            return account.balance;
        }

        return toIERC20(reserveToken).balanceOf(account);
    }

    /**
     * @dev transfers a specific amount of the reserve token
     *
     * @param reserveToken the address of the reserve token
     * @param to the destination address to transfer the amount to
     * @param amount the amount to transfer
     */
    function safeTransfer(
        IReserveToken reserveToken,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isNativeToken(reserveToken)) {
            payable(to).transfer(amount);
        } else {
            toIERC20(reserveToken).safeTransfer(to, amount);
        }
    }

    /**
     * @dev transfers a specific amount of the reserve token from a specific holder using the allowance mechanism
     * this function ignores a reserve token which represents an ETH reserve
     *
     * @param reserveToken the address of the reserve token
     * @param from the source address to transfer the amount from
     * @param to the destination address to transfer the amount to
     * @param amount the amount to transfer
     */
    function safeTransferFrom(
        IReserveToken reserveToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev ensures that the spender has sufficient allowance
     * this function ignores a reserve token which represents an ETH reserve
     *
     * @param reserveToken the address of the reserve token
     * @param spender the address allowed to spend
     * @param amount the allowed amount to spend
     */
    function ensureApprove(
        IReserveToken reserveToken,
        address spender,
        uint256 amount
    ) internal {
        if (isNativeToken(reserveToken)) {
            return;
        }

        toIERC20(reserveToken).ensureApprove(spender, amount);
    }

    /**
     * @dev utility function that converts an IReserveToken to an IERC20
     *
     * @param reserveToken the address of the reserve token
     *
     * @return an IERC20
     */
    function toIERC20(IReserveToken reserveToken) private pure returns (IERC20) {
        return IERC20(address(reserveToken));
    }
}

// File: solidity/contracts/converter/interfaces/IConverter.sol


pragma solidity 0.6.12;





/*
    Converter interface
*/
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IReserveToken _sourceToken,
        IReserveToken _targetToken,
        uint256 _amount
    ) external view returns (uint256, uint256);

    function convert(
        IReserveToken _sourceToken,
        IReserveToken _targetToken,
        uint256 _amount,
        address _trader,
        address payable _beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IReserveToken _reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 _conversionFee) external;

    function addReserve(IReserveToken _token, uint32 _weight) external;

    function transferReservesOnUpgrade(address _newConverter) external;

    function onUpgradeComplete() external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address _newOwner) external;

    function acceptTokenOwnership() external;

    function connectors(IReserveToken _address)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IReserveToken _connectorToken) external view returns (uint256);

    function connectorTokens(uint256 _index) external view returns (IReserveToken);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     *
     * @param _type        converter type
     * @param _anchor      converter anchor
     * @param _activated   true if the converter was activated, false if it was deactivated
     */
    event Activation(uint16 indexed _type, IConverterAnchor indexed _anchor, bool indexed _activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     *
     * @param _fromToken       source reserve token
     * @param _toToken         target reserve token
     * @param _trader          wallet that initiated the trade
     * @param _amount          input amount in units of the source token
     * @param _return          output amount minus conversion fee in units of the target token
     * @param _conversionFee   conversion fee in units of the target token
     */
    event Conversion(
        IReserveToken indexed _fromToken,
        IReserveToken indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     *
     * @param  _token1 address of the first token
     * @param  _token2 address of the second token
     * @param  _rateN  rate of 1 unit of `_token1` in `_token2` (numerator)
     * @param  _rateD  rate of 1 unit of `_token1` in `_token2` (denominator)
     */
    event TokenRateUpdate(address indexed _token1, address indexed _token2, uint256 _rateN, uint256 _rateD);

    /**
     * @dev triggered when the conversion fee is updated
     *
     * @param  _prevFee    previous fee percentage, represented in ppm
     * @param  _newFee     new fee percentage, represented in ppm
     */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);
}

// File: solidity/contracts/converter/interfaces/IConverterRegistry.sol


pragma solidity 0.6.12;



interface IConverterRegistry {
    function getAnchorCount() external view returns (uint256);

    function getAnchors() external view returns (address[] memory);

    function getAnchor(uint256 _index) external view returns (IConverterAnchor);

    function isAnchor(address _value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);

    function getLiquidityPools() external view returns (address[] memory);

    function getLiquidityPool(uint256 _index) external view returns (IConverterAnchor);

    function isLiquidityPool(address _value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);

    function getConvertibleTokens() external view returns (address[] memory);

    function getConvertibleToken(uint256 _index) external view returns (IReserveToken);

    function isConvertibleToken(address _value) external view returns (bool);

    function getConvertibleTokenAnchorCount(IReserveToken _convertibleToken) external view returns (uint256);

    function getConvertibleTokenAnchors(IReserveToken _convertibleToken) external view returns (address[] memory);

    function getConvertibleTokenAnchor(IReserveToken _convertibleToken, uint256 _index)
        external
        view
        returns (IConverterAnchor);

    function isConvertibleTokenAnchor(IReserveToken _convertibleToken, address _value) external view returns (bool);

    function getLiquidityPoolByConfig(
        uint16 _type,
        IReserveToken[] memory _reserveTokens,
        uint32[] memory _reserveWeights
    ) external view returns (IConverterAnchor);
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionStore.sol


pragma solidity 0.6.12;





/*
    Liquidity Protection Store interface
*/
interface ILiquidityProtectionStore is IOwned {
    function withdrawTokens(
        IReserveToken _token,
        address _to,
        uint256 _amount
    ) external;

    function protectedLiquidity(uint256 _id)
        external
        view
        returns (
            address,
            IDSToken,
            IReserveToken,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function addProtectedLiquidity(
        address _provider,
        IDSToken _poolToken,
        IReserveToken _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount,
        uint256 _reserveRateN,
        uint256 _reserveRateD,
        uint256 _timestamp
    ) external returns (uint256);

    function updateProtectedLiquidityAmounts(
        uint256 _id,
        uint256 _poolNewAmount,
        uint256 _reserveNewAmount
    ) external;

    function removeProtectedLiquidity(uint256 _id) external;

    function lockedBalance(address _provider, uint256 _index) external view returns (uint256, uint256);

    function lockedBalanceRange(
        address _provider,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (uint256[] memory, uint256[] memory);

    function addLockedBalance(
        address _provider,
        uint256 _reserveAmount,
        uint256 _expirationTime
    ) external returns (uint256);

    function removeLockedBalance(address _provider, uint256 _index) external;

    function systemBalance(IReserveToken _poolToken) external view returns (uint256);

    function incSystemBalance(IReserveToken _poolToken, uint256 _poolAmount) external;

    function decSystemBalance(IReserveToken _poolToken, uint256 _poolAmount) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionStats.sol


pragma solidity 0.6.12;




/*
    Liquidity Protection Stats interface
*/
interface ILiquidityProtectionStats {
    function increaseTotalAmounts(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function decreaseTotalAmounts(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function addProviderPool(address provider, IDSToken poolToken) external returns (bool);

    function removeProviderPool(address provider, IDSToken poolToken) external returns (bool);

    function totalPoolAmount(IDSToken poolToken) external view returns (uint256);

    function totalReserveAmount(IDSToken poolToken, IReserveToken reserveToken) external view returns (uint256);

    function totalProviderAmount(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken
    ) external view returns (uint256);

    function providerPools(address provider) external view returns (IDSToken[] memory);
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProvisionEventsSubscriber.sol


pragma solidity 0.6.12;



/**
 * @dev Liquidity provision events subscriber interface
 */
interface ILiquidityProvisionEventsSubscriber {
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function onRemovingLiquidity(
        uint256 id,
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionSettings.sol


pragma solidity 0.6.12;




/*
    Liquidity Protection Store Settings interface
*/
interface ILiquidityProtectionSettings {
    function isPoolWhitelisted(IConverterAnchor poolAnchor) external view returns (bool);

    function poolWhitelist() external view returns (address[] memory);

    function subscribers() external view returns (address[] memory);

    function isPoolSupported(IConverterAnchor poolAnchor) external view returns (bool);

    function minNetworkTokenLiquidityForMinting() external view returns (uint256);

    function defaultNetworkTokenMintingLimit() external view returns (uint256);

    function networkTokenMintingLimits(IConverterAnchor poolAnchor) external view returns (uint256);

    function addLiquidityDisabled(IConverterAnchor poolAnchor, IReserveToken reserveToken) external view returns (bool);

    function minProtectionDelay() external view returns (uint256);

    function maxProtectionDelay() external view returns (uint256);

    function minNetworkCompensation() external view returns (uint256);

    function lockDuration() external view returns (uint256);

    function averageRateMaxDeviation() external view returns (uint32);
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionSystemStore.sol


pragma solidity 0.6.12;



/*
    Liquidity Protection System Store interface
*/
interface ILiquidityProtectionSystemStore {
    function systemBalance(IERC20 poolToken) external view returns (uint256);

    function incSystemBalance(IERC20 poolToken, uint256 poolAmount) external;

    function decSystemBalance(IERC20 poolToken, uint256 poolAmount) external;

    function networkTokensMinted(IConverterAnchor poolAnchor) external view returns (uint256);

    function incNetworkTokensMinted(IConverterAnchor poolAnchor, uint256 amount) external;

    function decNetworkTokensMinted(IConverterAnchor poolAnchor, uint256 amount) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ITransferPositionCallback.sol


pragma solidity 0.6.12;

/**
 * @dev Transfer position event callback interface
 */
interface ITransferPositionCallback {
    function onTransferPosition(
        uint256 newId,
        address provider,
        bytes calldata data
    ) external;
}

// File: solidity/contracts/utility/interfaces/ITokenHolder.sol


pragma solidity 0.6.12;



/*
    Token Holder interface
*/
interface ITokenHolder is IOwned {
    receive() external payable;

    function withdrawTokens(
        IReserveToken reserveToken,
        address payable to,
        uint256 amount
    ) external;

    function withdrawTokensMultiple(
        IReserveToken[] calldata reserveTokens,
        address payable to,
        uint256[] calldata amounts
    ) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtection.sol


pragma solidity 0.6.12;









/*
    Liquidity Protection interface
*/
interface ILiquidityProtection {
    function store() external view returns (ILiquidityProtectionStore);

    function stats() external view returns (ILiquidityProtectionStats);

    function settings() external view returns (ILiquidityProtectionSettings);

    function systemStore() external view returns (ILiquidityProtectionSystemStore);

    function wallet() external view returns (ITokenHolder);

    function addLiquidityFor(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function addLiquidity(
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function removeLiquidity(uint256 id, uint32 portion) external;

    function transferPosition(uint256 id, address newProvider) external returns (uint256);

    function transferPositionAndNotify(
        uint256 id,
        address newProvider,
        ITransferPositionCallback callback,
        bytes calldata data
    ) external returns (uint256);
}

// File: solidity/contracts/liquidity-protection/LiquidityProtection.sol


pragma solidity 0.6.12;

















interface ILiquidityPoolConverter is IConverter {
    function addLiquidity(
        IReserveToken[] memory reserveTokens,
        uint256[] memory reserveAmounts,
        uint256 _minReturn
    ) external payable;

    function removeLiquidity(
        uint256 amount,
        IReserveToken[] memory reserveTokens,
        uint256[] memory _reserveMinReturnAmounts
    ) external;

    function recentAverageRate(IReserveToken reserveToken) external view returns (uint256, uint256);
}

/**
 * @dev This contract implements the liquidity protection mechanism.
 */
contract LiquidityProtection is ILiquidityProtection, Utils, Owned, ReentrancyGuard, Time {
    using SafeMath for uint256;
    using ReserveToken for IReserveToken;
    using SafeERC20 for IERC20;
    using SafeERC20 for IDSToken;
    using SafeERC20Ex for IERC20;
    using MathEx for *;

    struct Position {
        address provider; // liquidity provider
        IDSToken poolToken; // pool token address
        IReserveToken reserveToken; // reserve token address
        uint256 poolAmount; // pool token amount
        uint256 reserveAmount; // reserve token amount
        uint256 reserveRateN; // rate of 1 protected reserve token in units of the other reserve token (numerator)
        uint256 reserveRateD; // rate of 1 protected reserve token in units of the other reserve token (denominator)
        uint256 timestamp; // timestamp
    }

    // various rates between the two reserve tokens. the rate is of 1 unit of the protected reserve token in units of the other reserve token
    struct PackedRates {
        uint128 addSpotRateN; // spot rate of 1 A in units of B when liquidity was added (numerator)
        uint128 addSpotRateD; // spot rate of 1 A in units of B when liquidity was added (denominator)
        uint128 removeSpotRateN; // spot rate of 1 A in units of B when liquidity is removed (numerator)
        uint128 removeSpotRateD; // spot rate of 1 A in units of B when liquidity is removed (denominator)
        uint128 removeAverageRateN; // average rate of 1 A in units of B when liquidity is removed (numerator)
        uint128 removeAverageRateD; // average rate of 1 A in units of B when liquidity is removed (denominator)
    }

    uint256 internal constant MAX_UINT128 = 2**128 - 1;
    uint256 internal constant MAX_UINT256 = uint256(-1);

    ILiquidityProtectionSettings private immutable _settings;
    ILiquidityProtectionStore private immutable _store;
    ILiquidityProtectionStats private immutable _stats;
    ILiquidityProtectionSystemStore private immutable _systemStore;
    ITokenHolder private immutable _wallet;
    IERC20 private immutable _networkToken;
    ITokenGovernance private immutable _networkTokenGovernance;
    IERC20 private immutable _govToken;
    ITokenGovernance private immutable _govTokenGovernance;
    ICheckpointStore private immutable _lastRemoveCheckpointStore;

    /**
     * @dev initializes a new LiquidityProtection contract
     *
     * @param settings liquidity protection settings
     * @param store liquidity protection store
     * @param stats liquidity protection stats
     * @param systemStore liquidity protection system store
     * @param wallet liquidity protection wallet
     * @param networkTokenGovernance network token governance
     * @param govTokenGovernance governance token governance
     * @param lastRemoveCheckpointStore last liquidity removal/unprotection checkpoints store
     */
    constructor(
        ILiquidityProtectionSettings settings,
        ILiquidityProtectionStore store,
        ILiquidityProtectionStats stats,
        ILiquidityProtectionSystemStore systemStore,
        ITokenHolder wallet,
        ITokenGovernance networkTokenGovernance,
        ITokenGovernance govTokenGovernance,
        ICheckpointStore lastRemoveCheckpointStore
    )
        public
        validAddress(address(settings))
        validAddress(address(store))
        validAddress(address(stats))
        validAddress(address(systemStore))
        validAddress(address(wallet))
        validAddress(address(lastRemoveCheckpointStore))
    {
        _settings = settings;
        _store = store;
        _stats = stats;
        _systemStore = systemStore;
        _wallet = wallet;
        _networkTokenGovernance = networkTokenGovernance;
        _govTokenGovernance = govTokenGovernance;
        _lastRemoveCheckpointStore = lastRemoveCheckpointStore;

        _networkToken = networkTokenGovernance.token();
        _govToken = govTokenGovernance.token();
    }

    // ensures that the pool is supported and whitelisted
    modifier poolSupportedAndWhitelisted(IConverterAnchor poolAnchor) {
        _poolSupported(poolAnchor);
        _poolWhitelisted(poolAnchor);

        _;
    }

    // ensures that add liquidity is enabled
    modifier addLiquidityEnabled(IConverterAnchor poolAnchor, IReserveToken reserveToken) {
        _addLiquidityEnabled(poolAnchor, reserveToken);

        _;
    }

    // error message binary size optimization
    function _poolSupported(IConverterAnchor poolAnchor) internal view {
        require(_settings.isPoolSupported(poolAnchor), "ERR_POOL_NOT_SUPPORTED");
    }

    // error message binary size optimization
    function _poolWhitelisted(IConverterAnchor poolAnchor) internal view {
        require(_settings.isPoolWhitelisted(poolAnchor), "ERR_POOL_NOT_WHITELISTED");
    }

    // error message binary size optimization
    function _addLiquidityEnabled(IConverterAnchor poolAnchor, IReserveToken reserveToken) internal view {
        require(!_settings.addLiquidityDisabled(poolAnchor, reserveToken), "ERR_ADD_LIQUIDITY_DISABLED");
    }

    // error message binary size optimization
    function verifyEthAmount(uint256 value) internal view {
        require(msg.value == value, "ERR_ETH_AMOUNT_MISMATCH");
    }

    /**
     * @dev returns the LP store
     *
     * @return the LP store
     */
    function store() external view override returns (ILiquidityProtectionStore) {
        return _store;
    }

    /**
     * @dev returns the LP stats
     *
     * @return the LP stats
     */
    function stats() external view override returns (ILiquidityProtectionStats) {
        return _stats;
    }

    /**
     * @dev returns the LP settings
     *
     * @return the LP settings
     */
    function settings() external view override returns (ILiquidityProtectionSettings) {
        return _settings;
    }

    /**
     * @dev returns the LP system store
     *
     * @return the LP system store
     */
    function systemStore() external view override returns (ILiquidityProtectionSystemStore) {
        return _systemStore;
    }

    /**
     * @dev returns the LP wallet
     *
     * @return the LP wallet
     */
    function wallet() external view override returns (ITokenHolder) {
        return _wallet;
    }

    /**
     * @dev accept ETH
     */
    receive() external payable {}

    /**
     * @dev transfers the ownership of the store
     * can only be called by the contract owner
     *
     * @param newOwner the new owner of the store
     */
    function transferStoreOwnership(address newOwner) external ownerOnly {
        _store.transferOwnership(newOwner);
    }

    /**
     * @dev accepts the ownership of the store
     * can only be called by the contract owner
     */
    function acceptStoreOwnership() external ownerOnly {
        _store.acceptOwnership();
    }

    /**
     * @dev transfers the ownership of the wallet
     * can only be called by the contract owner
     *
     * @param newOwner the new owner of the wallet
     */
    function transferWalletOwnership(address newOwner) external ownerOnly {
        _wallet.transferOwnership(newOwner);
    }

    /**
     * @dev accepts the ownership of the wallet
     * can only be called by the contract owner
     */
    function acceptWalletOwnership() external ownerOnly {
        _wallet.acceptOwnership();
    }

    /**
     * @dev adds protected liquidity to a pool for a specific recipient
     * also mints new governance tokens for the caller if the caller adds network tokens
     *
     * @param owner position owner
     * @param poolAnchor anchor of the pool
     * @param reserveToken reserve token to add to the pool
     * @param amount amount of tokens to add to the pool
     *
     * @return new position id
     */
    function addLiquidityFor(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    )
        external
        payable
        override
        protected
        validAddress(owner)
        poolSupportedAndWhitelisted(poolAnchor)
        addLiquidityEnabled(poolAnchor, reserveToken)
        greaterThanZero(amount)
        returns (uint256)
    {
        return addLiquidity(owner, poolAnchor, reserveToken, amount);
    }

    /**
     * @dev adds protected liquidity to a pool
     * also mints new governance tokens for the caller if the caller adds network tokens
     *
     * @param poolAnchor anchor of the pool
     * @param reserveToken reserve token to add to the pool
     * @param amount amount of tokens to add to the pool
     *
     * @return new position id
     */
    function addLiquidity(
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    )
        external
        payable
        override
        protected
        poolSupportedAndWhitelisted(poolAnchor)
        addLiquidityEnabled(poolAnchor, reserveToken)
        greaterThanZero(amount)
        returns (uint256)
    {
        return addLiquidity(msg.sender, poolAnchor, reserveToken, amount);
    }

    /**
     * @dev adds protected liquidity to a pool for a specific recipient
     * also mints new governance tokens for the caller if the caller adds network tokens
     *
     * @param owner position owner
     * @param poolAnchor anchor of the pool
     * @param reserveToken reserve token to add to the pool
     * @param amount amount of tokens to add to the pool
     *
     * @return new position id
     */
    function addLiquidity(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 amount
    ) private returns (uint256) {
        if (isNetworkToken(reserveToken)) {
            verifyEthAmount(0);
            return addNetworkTokenLiquidity(owner, poolAnchor, amount);
        }

        // verify that ETH was passed with the call if needed
        verifyEthAmount(reserveToken.isNativeToken() ? amount : 0);
        return addBaseTokenLiquidity(owner, poolAnchor, reserveToken, amount);
    }

    /**
     * @dev adds network token liquidity to a pool
     * also mints new governance tokens for the caller
     *
     * @param owner position owner
     * @param poolAnchor anchor of the pool
     * @param amount amount of tokens to add to the pool
     *
     * @return new position id
     */
    function addNetworkTokenLiquidity(
        address owner,
        IConverterAnchor poolAnchor,
        uint256 amount
    ) internal returns (uint256) {
        IDSToken poolToken = IDSToken(address(poolAnchor));
        IReserveToken networkToken = IReserveToken(address(_networkToken));

        // get the rate between the pool token and the reserve
        Fraction memory poolRate = poolTokenRate(poolToken, networkToken);

        // calculate the amount of pool tokens based on the amount of reserve tokens
        uint256 poolTokenAmount = amount.mul(poolRate.d).div(poolRate.n);

        // remove the pool tokens from the system's ownership (will revert if not enough tokens are available)
        _systemStore.decSystemBalance(poolToken, poolTokenAmount);

        // add the position for the recipient
        uint256 id = addPosition(owner, poolToken, networkToken, poolTokenAmount, amount, time());

        // burns the network tokens from the caller. we need to transfer the tokens to the contract itself, since only
        // token holders can burn their tokens
        _networkToken.safeTransferFrom(msg.sender, address(this), amount);
        burnNetworkTokens(poolAnchor, amount);

        // mint governance tokens to the recipient
        _govTokenGovernance.mint(owner, amount);

        return id;
    }

    /**
     * @dev adds base token liquidity to a pool
     *
     * @param owner position owner
     * @param poolAnchor anchor of the pool
     * @param baseToken the base reserve token of the pool
     * @param amount amount of tokens to add to the pool
     *
     * @return new position id
     */
    function addBaseTokenLiquidity(
        address owner,
        IConverterAnchor poolAnchor,
        IReserveToken baseToken,
        uint256 amount
    ) internal returns (uint256) {
        IDSToken poolToken = IDSToken(address(poolAnchor));
        IReserveToken networkToken = IReserveToken(address(_networkToken));

        // get the reserve balances
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(ownedBy(poolAnchor)));
        (uint256 reserveBalanceBase, uint256 reserveBalanceNetwork) =
            converterReserveBalances(converter, baseToken, networkToken);

        require(reserveBalanceNetwork >= _settings.minNetworkTokenLiquidityForMinting(), "ERR_NOT_ENOUGH_LIQUIDITY");

        // calculate and mint the required amount of network tokens for adding liquidity
        uint256 newNetworkLiquidityAmount = amount.mul(reserveBalanceNetwork).div(reserveBalanceBase);

        // verify network token minting limit
        uint256 mintingLimit = _settings.networkTokenMintingLimits(poolAnchor);
        if (mintingLimit == 0) {
            mintingLimit = _settings.defaultNetworkTokenMintingLimit();
        }

        uint256 newNetworkTokensMinted = _systemStore.networkTokensMinted(poolAnchor).add(newNetworkLiquidityAmount);
        require(newNetworkTokensMinted <= mintingLimit, "ERR_MAX_AMOUNT_REACHED");

        // issue new network tokens to the system
        mintNetworkTokens(address(this), poolAnchor, newNetworkLiquidityAmount);

        // transfer the base tokens from the caller and approve the converter
        networkToken.ensureApprove(address(converter), newNetworkLiquidityAmount);

        if (!baseToken.isNativeToken()) {
            baseToken.safeTransferFrom(msg.sender, address(this), amount);
            baseToken.ensureApprove(address(converter), amount);
        }

        // add the liquidity to the converter
        addLiquidity(converter, baseToken, networkToken, amount, newNetworkLiquidityAmount, msg.value);

        // transfer the new pool tokens to the wallet
        uint256 poolTokenAmount = poolToken.balanceOf(address(this));
        poolToken.safeTransfer(address(_wallet), poolTokenAmount);

        // the system splits the pool tokens with the caller
        // increase the system's pool token balance and add the position for the caller
        _systemStore.incSystemBalance(poolToken, poolTokenAmount - poolTokenAmount / 2); // account for rounding errors

        return addPosition(owner, poolToken, baseToken, poolTokenAmount / 2, amount, time());
    }

    /**
     * @dev returns the single-side staking limits of a given pool
     *
     * @param poolAnchor anchor of the pool
     *
     * @return maximum amount of base tokens that can be single-side staked in the pool
     * @return maximum amount of network tokens that can be single-side staked in the pool
     */
    function poolAvailableSpace(IConverterAnchor poolAnchor)
        external
        view
        poolSupportedAndWhitelisted(poolAnchor)
        returns (uint256, uint256)
    {
        return (baseTokenAvailableSpace(poolAnchor), networkTokenAvailableSpace(poolAnchor));
    }

    /**
     * @dev returns the base-token staking limits of a given pool
     *
     * @param poolAnchor anchor of the pool
     *
     * @return maximum amount of base tokens that can be single-side staked in the pool
     */
    function baseTokenAvailableSpace(IConverterAnchor poolAnchor) internal view returns (uint256) {
        // get the pool converter
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(ownedBy(poolAnchor)));

        // get the base token
        IReserveToken networkToken = IReserveToken(address(_networkToken));
        IReserveToken baseToken = converterOtherReserve(converter, networkToken);

        // get the reserve balances
        (uint256 reserveBalanceBase, uint256 reserveBalanceNetwork) =
            converterReserveBalances(converter, baseToken, networkToken);

        // get the network token minting limit
        uint256 mintingLimit = _settings.networkTokenMintingLimits(poolAnchor);
        if (mintingLimit == 0) {
            mintingLimit = _settings.defaultNetworkTokenMintingLimit();
        }

        // get the amount of network tokens already minted for the pool
        uint256 networkTokensMinted = _systemStore.networkTokensMinted(poolAnchor);

        // get the amount of network tokens which can minted for the pool
        uint256 networkTokensCanBeMinted = MathEx.max(mintingLimit, networkTokensMinted) - networkTokensMinted;

        // return the maximum amount of base token liquidity that can be single-sided staked in the pool
        return networkTokensCanBeMinted.mul(reserveBalanceBase).div(reserveBalanceNetwork);
    }

    /**
     * @dev returns the network-token staking limits of a given pool
     *
     * @param poolAnchor anchor of the pool
     *
     * @return maximum amount of network tokens that can be single-side staked in the pool
     */
    function networkTokenAvailableSpace(IConverterAnchor poolAnchor) internal view returns (uint256) {
        // get the pool token
        IDSToken poolToken = IDSToken(address(poolAnchor));
        IReserveToken networkToken = IReserveToken(address(_networkToken));

        // get the pool token rate
        Fraction memory poolRate = poolTokenRate(poolToken, networkToken);

        // return the maximum amount of network token liquidity that can be single-sided staked in the pool
        return _systemStore.systemBalance(poolToken).mul(poolRate.n).add(poolRate.n).sub(1).div(poolRate.d);
    }

    /**
     * @dev returns the expected/actual amounts the provider will receive for removing liquidity
     * it's also possible to provide the remove liquidity time to get an estimation
     * for the return at that given point
     *
     * @param id position id
     * @param portion portion of liquidity to remove, in PPM
     * @param removeTimestamp time at which the liquidity is removed
     *
     * @return expected return amount in the reserve token
     * @return actual return amount in the reserve token
     * @return compensation in the network token
     */
    function removeLiquidityReturn(
        uint256 id,
        uint32 portion,
        uint256 removeTimestamp
    )
        external
        view
        validPortion(portion)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Position memory pos = position(id);

        // verify input
        require(pos.provider != address(0), "ERR_INVALID_ID");
        require(removeTimestamp >= pos.timestamp, "ERR_INVALID_TIMESTAMP");

        // calculate the portion of the liquidity to remove
        if (portion != PPM_RESOLUTION) {
            pos.poolAmount = pos.poolAmount.mul(portion) / PPM_RESOLUTION;
            pos.reserveAmount = pos.reserveAmount.mul(portion) / PPM_RESOLUTION;
        }

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates = packRates(pos.poolToken, pos.reserveToken, pos.reserveRateN, pos.reserveRateD);

        uint256 targetAmount =
            removeLiquidityTargetAmount(
                pos.poolToken,
                pos.reserveToken,
                pos.poolAmount,
                pos.reserveAmount,
                packedRates,
                pos.timestamp,
                removeTimestamp
            );

        // for network token, the return amount is identical to the target amount
        if (isNetworkToken(pos.reserveToken)) {
            return (targetAmount, targetAmount, 0);
        }

        // handle base token return

        // calculate the amount of pool tokens required for liquidation
        // note that the amount is doubled since it's not possible to liquidate one reserve only
        Fraction memory poolRate = poolTokenRate(pos.poolToken, pos.reserveToken);
        uint256 poolAmount = targetAmount.mul(poolRate.d).div(poolRate.n / 2);

        // limit the amount of pool tokens by the amount the system/caller holds
        uint256 availableBalance = _systemStore.systemBalance(pos.poolToken).add(pos.poolAmount);
        poolAmount = poolAmount > availableBalance ? availableBalance : poolAmount;

        // calculate the base token amount received by liquidating the pool tokens
        // note that the amount is divided by 2 since the pool amount represents both reserves
        uint256 baseAmount = poolAmount.mul(poolRate.n / 2).div(poolRate.d);
        uint256 networkAmount = networkCompensation(targetAmount, baseAmount, packedRates);

        return (targetAmount, baseAmount, networkAmount);
    }

    /**
     * @dev removes protected liquidity from a pool
     * also burns governance tokens from the caller if the caller removes network tokens
     *
     * @param id position id
     * @param portion portion of liquidity to remove, in PPM
     */
    function removeLiquidity(uint256 id, uint32 portion) external override protected validPortion(portion) {
        removeLiquidity(msg.sender, id, portion);
    }

    /**
     * @dev removes a position from a pool
     * also burns governance tokens from the caller if the caller removes network tokens
     *
     * @param provider liquidity provider
     * @param id position id
     * @param portion portion of liquidity to remove, in PPM
     */
    function removeLiquidity(
        address payable provider,
        uint256 id,
        uint32 portion
    ) internal {
        // remove the position from the store and update the stats and the last removal checkpoint
        Position memory removedPos = removePosition(provider, id, portion);

        // add the pool tokens to the system
        _systemStore.incSystemBalance(removedPos.poolToken, removedPos.poolAmount);

        // if removing network token liquidity, burn the governance tokens from the caller. we need to transfer the
        // tokens to the contract itself, since only token holders can burn their tokens
        if (isNetworkToken(removedPos.reserveToken)) {
            _govToken.safeTransferFrom(provider, address(this), removedPos.reserveAmount);
            _govTokenGovernance.burn(removedPos.reserveAmount);
        }

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates =
            packRates(removedPos.poolToken, removedPos.reserveToken, removedPos.reserveRateN, removedPos.reserveRateD);

        // verify rate deviation as early as possible in order to reduce gas-cost for failing transactions
        verifyRateDeviation(
            packedRates.removeSpotRateN,
            packedRates.removeSpotRateD,
            packedRates.removeAverageRateN,
            packedRates.removeAverageRateD
        );

        // get the target token amount
        uint256 targetAmount =
            removeLiquidityTargetAmount(
                removedPos.poolToken,
                removedPos.reserveToken,
                removedPos.poolAmount,
                removedPos.reserveAmount,
                packedRates,
                removedPos.timestamp,
                time()
            );

        // remove network token liquidity
        if (isNetworkToken(removedPos.reserveToken)) {
            // mint network tokens for the caller and lock them
            mintNetworkTokens(address(_wallet), removedPos.poolToken, targetAmount);
            lockTokens(provider, targetAmount);

            return;
        }

        // remove base token liquidity

        // calculate the amount of pool tokens required for liquidation
        // note that the amount is doubled since it's not possible to liquidate one reserve only
        Fraction memory poolRate = poolTokenRate(removedPos.poolToken, removedPos.reserveToken);
        uint256 poolAmount = targetAmount.mul(poolRate.d).div(poolRate.n / 2);

        // limit the amount of pool tokens by the amount the system holds
        uint256 systemBalance = _systemStore.systemBalance(removedPos.poolToken);
        poolAmount = poolAmount > systemBalance ? systemBalance : poolAmount;

        // withdraw the pool tokens from the wallet
        IReserveToken poolToken = IReserveToken(address(removedPos.poolToken));
        _systemStore.decSystemBalance(removedPos.poolToken, poolAmount);
        _wallet.withdrawTokens(poolToken, address(this), poolAmount);

        // remove liquidity
        removeLiquidity(
            removedPos.poolToken,
            poolAmount,
            removedPos.reserveToken,
            IReserveToken(address(_networkToken))
        );

        // transfer the base tokens to the caller
        uint256 baseBalance = removedPos.reserveToken.balanceOf(address(this));
        removedPos.reserveToken.safeTransfer(provider, baseBalance);

        // compensate the caller with network tokens if still needed
        uint256 delta = networkCompensation(targetAmount, baseBalance, packedRates);
        if (delta > 0) {
            // check if there's enough network token balance, otherwise mint more
            uint256 networkBalance = _networkToken.balanceOf(address(this));
            if (networkBalance < delta) {
                _networkTokenGovernance.mint(address(this), delta - networkBalance);
            }

            // lock network tokens for the caller
            _networkToken.safeTransfer(address(_wallet), delta);
            lockTokens(provider, delta);
        }

        // if the contract still holds network tokens, burn them
        uint256 networkBalance = _networkToken.balanceOf(address(this));
        if (networkBalance > 0) {
            burnNetworkTokens(removedPos.poolToken, networkBalance);
        }
    }

    /**
     * @dev returns the amount the provider will receive for removing liquidity
     * it's also possible to provide the remove liquidity rate & time to get an estimation
     * for the return at that given point
     *
     * @param poolToken pool token
     * @param reserveToken reserve token
     * @param poolAmount pool token amount when the liquidity was added
     * @param reserveAmount reserve token amount that was added
     * @param packedRates see `struct PackedRates`
     * @param addTimestamp time at which the liquidity was added
     * @param removeTimestamp time at which the liquidity is removed
     *
     * @return amount received for removing liquidity
     */
    function removeLiquidityTargetAmount(
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount,
        PackedRates memory packedRates,
        uint256 addTimestamp,
        uint256 removeTimestamp
    ) internal view returns (uint256) {
        // get the rate between the pool token and the reserve token
        Fraction memory poolRate = poolTokenRate(poolToken, reserveToken);

        // get the rate between the reserves upon adding liquidity and now
        Fraction memory addSpotRate = Fraction({ n: packedRates.addSpotRateN, d: packedRates.addSpotRateD });
        Fraction memory removeSpotRate = Fraction({ n: packedRates.removeSpotRateN, d: packedRates.removeSpotRateD });
        Fraction memory removeAverageRate =
            Fraction({ n: packedRates.removeAverageRateN, d: packedRates.removeAverageRateD });

        // calculate the protected amount of reserve tokens plus accumulated fee before compensation
        uint256 total = protectedAmountPlusFee(poolAmount, poolRate, addSpotRate, removeSpotRate);

        // calculate the impermanent loss
        Fraction memory loss = impLoss(addSpotRate, removeAverageRate);

        // calculate the protection level
        Fraction memory level = protectionLevel(addTimestamp, removeTimestamp);

        // calculate the compensation amount
        return compensationAmount(reserveAmount, MathEx.max(reserveAmount, total), loss, level);
    }

    /**
     * @dev transfers a position to a new provider
     *
     * @param id position id
     * @param newProvider the new provider
     *
     * @return new position id
     */
    function transferPosition(uint256 id, address newProvider)
        external
        override
        protected
        validAddress(newProvider)
        returns (uint256)
    {
        return transferPosition(msg.sender, id, newProvider);
    }

    /**
     * @dev transfers a position to a new provider and optionally notifies another contract
     *
     * @param id position id
     * @param newProvider the new provider
     * @param callback the callback contract to notify
     * @param data custom data provided to the callback
     *
     * @return new position id
     */
    function transferPositionAndNotify(
        uint256 id,
        address newProvider,
        ITransferPositionCallback callback,
        bytes calldata data
    ) external override protected validAddress(newProvider) validAddress(address(callback)) returns (uint256) {
        uint256 newId = transferPosition(msg.sender, id, newProvider);

        callback.onTransferPosition(newId, msg.sender, data);

        return newId;
    }

    /**
     * @dev transfers a position to a new provider
     *
     * @param provider the existing provider
     * @param id position id
     * @param newProvider the new provider
     *
     * @return new position id
     */
    function transferPosition(
        address provider,
        uint256 id,
        address newProvider
    ) internal returns (uint256) {
        // remove the position from the store and update the stats and the last removal checkpoint
        Position memory removedPos = removePosition(provider, id, PPM_RESOLUTION);

        // add the position to the store, update the stats, and return the new id
        return
            addPosition(
                newProvider,
                removedPos.poolToken,
                removedPos.reserveToken,
                removedPos.poolAmount,
                removedPos.reserveAmount,
                removedPos.timestamp
            );
    }

    /**
     * @dev allows the caller to claim network token balance that is no longer locked
     * note that the function can revert if the range is too large
     *
     * @param startIndex start index in the caller's list of locked balances
     * @param endIndex end index in the caller's list of locked balances (exclusive)
     */
    function claimBalance(uint256 startIndex, uint256 endIndex) external protected {
        // get the locked balances from the store
        (uint256[] memory amounts, uint256[] memory expirationTimes) =
            _store.lockedBalanceRange(msg.sender, startIndex, endIndex);

        uint256 totalAmount = 0;
        uint256 length = amounts.length;
        assert(length == expirationTimes.length);

        // reverse iteration since we're removing from the list
        for (uint256 i = length; i > 0; i--) {
            uint256 index = i - 1;
            if (expirationTimes[index] > time()) {
                continue;
            }

            // remove the locked balance item
            _store.removeLockedBalance(msg.sender, startIndex + index);
            totalAmount = totalAmount.add(amounts[index]);
        }

        if (totalAmount > 0) {
            // transfer the tokens to the caller in a single call
            _wallet.withdrawTokens(IReserveToken(address(_networkToken)), msg.sender, totalAmount);
        }
    }

    /**
     * @dev returns the ROI for removing liquidity in the current state after providing liquidity with the given args
     * the function assumes full protection is in effect
     * return value is in PPM and can be larger than PPM_RESOLUTION for positive ROI, 1M = 0% ROI
     *
     * @param poolToken pool token
     * @param reserveToken reserve token
     * @param reserveAmount reserve token amount that was added
     * @param poolRateN rate of 1 pool token in reserve token units when the liquidity was added (numerator)
     * @param poolRateD rate of 1 pool token in reserve token units when the liquidity was added (denominator)
     * @param reserveRateN rate of 1 reserve token in the other reserve token units when the liquidity was added (numerator)
     * @param reserveRateD rate of 1 reserve token in the other reserve token units when the liquidity was added (denominator)
     *
     * @return ROI in PPM
     */
    function poolROI(
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 reserveAmount,
        uint256 poolRateN,
        uint256 poolRateD,
        uint256 reserveRateN,
        uint256 reserveRateD
    ) external view returns (uint256) {
        // calculate the amount of pool tokens based on the amount of reserve tokens
        uint256 poolAmount = reserveAmount.mul(poolRateD).div(poolRateN);

        // get the various rates between the reserves upon adding liquidity and now
        PackedRates memory packedRates = packRates(poolToken, reserveToken, reserveRateN, reserveRateD);

        // get the current return
        uint256 protectedReturn =
            removeLiquidityTargetAmount(
                poolToken,
                reserveToken,
                poolAmount,
                reserveAmount,
                packedRates,
                time().sub(_settings.maxProtectionDelay()),
                time()
            );

        // calculate the ROI as the ratio between the current fully protected return and the initial amount
        return protectedReturn.mul(PPM_RESOLUTION).div(reserveAmount);
    }

    /**
     * @dev adds the position to the store and updates the stats
     *
     * @param provider the provider
     * @param poolToken pool token
     * @param reserveToken reserve token
     * @param poolAmount amount of pool tokens to protect
     * @param reserveAmount amount of reserve tokens to protect
     * @param timestamp the timestamp of the position
     *
     * @return new position id
     */
    function addPosition(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount,
        uint256 timestamp
    ) internal returns (uint256) {
        // verify rate deviation as early as possible in order to reduce gas-cost for failing transactions
        (Fraction memory spotRate, Fraction memory averageRate) = reserveTokenRates(poolToken, reserveToken);
        verifyRateDeviation(spotRate.n, spotRate.d, averageRate.n, averageRate.d);

        notifyEventSubscribersOnAddingLiquidity(provider, poolToken, reserveToken, poolAmount, reserveAmount);

        _stats.increaseTotalAmounts(provider, poolToken, reserveToken, poolAmount, reserveAmount);
        _stats.addProviderPool(provider, poolToken);

        return
            _store.addProtectedLiquidity(
                provider,
                poolToken,
                reserveToken,
                poolAmount,
                reserveAmount,
                spotRate.n,
                spotRate.d,
                timestamp
            );
    }

    /**
     * @dev removes the position from the store and updates the stats and the last removal checkpoint
     *
     * @param provider the provider
     * @param id position id
     * @param portion portion of the position to remove, in PPM
     *
     * @return a Position struct representing the removed liquidity
     */
    function removePosition(
        address provider,
        uint256 id,
        uint32 portion
    ) private returns (Position memory) {
        Position memory pos = providerPosition(id, provider);

        // verify that the pool is whitelisted
        _poolWhitelisted(pos.poolToken);

        // verify that the position is not removed on the same block in which it was added
        require(pos.timestamp < time(), "ERR_TOO_EARLY");

        if (portion == PPM_RESOLUTION) {
            notifyEventSubscribersOnRemovingLiquidity(
                id,
                pos.provider,
                pos.poolToken,
                pos.reserveToken,
                pos.poolAmount,
                pos.reserveAmount
            );

            // remove the position from the provider
            _store.removeProtectedLiquidity(id);
        } else {
            // remove a portion of the position from the provider
            uint256 fullPoolAmount = pos.poolAmount;
            uint256 fullReserveAmount = pos.reserveAmount;
            pos.poolAmount = pos.poolAmount.mul(portion) / PPM_RESOLUTION;
            pos.reserveAmount = pos.reserveAmount.mul(portion) / PPM_RESOLUTION;

            notifyEventSubscribersOnRemovingLiquidity(
                id,
                pos.provider,
                pos.poolToken,
                pos.reserveToken,
                pos.poolAmount,
                pos.reserveAmount
            );

            _store.updateProtectedLiquidityAmounts(
                id,
                fullPoolAmount - pos.poolAmount,
                fullReserveAmount - pos.reserveAmount
            );
        }

        // update the statistics
        _stats.decreaseTotalAmounts(pos.provider, pos.poolToken, pos.reserveToken, pos.poolAmount, pos.reserveAmount);

        // update last liquidity removal checkpoint
        _lastRemoveCheckpointStore.addCheckpoint(provider);

        return pos;
    }

    /**
     * @dev locks network tokens for the provider and emits the tokens locked event
     *
     * @param provider tokens provider
     * @param amount amount of network tokens
     */
    function lockTokens(address provider, uint256 amount) internal {
        uint256 expirationTime = time().add(_settings.lockDuration());
        _store.addLockedBalance(provider, amount, expirationTime);
    }

    /**
     * @dev returns the rate of 1 pool token in reserve token units
     *
     * @param poolToken pool token
     * @param reserveToken reserve token
     */
    function poolTokenRate(IDSToken poolToken, IReserveToken reserveToken)
        internal
        view
        virtual
        returns (Fraction memory)
    {
        // get the pool token supply
        uint256 poolTokenSupply = poolToken.totalSupply();

        // get the reserve balance
        IConverter converter = IConverter(payable(ownedBy(poolToken)));
        uint256 reserveBalance = converter.getConnectorBalance(reserveToken);

        // for standard pools, 50% of the pool supply value equals the value of each reserve
        return Fraction({ n: reserveBalance.mul(2), d: poolTokenSupply });
    }

    /**
     * @dev returns the spot rate and average rate of 1 reserve token in the other reserve token units
     *
     * @param poolToken pool token
     * @param reserveToken reserve token
     *
     * @return spot rate
     * @return average rate
     */
    function reserveTokenRates(IDSToken poolToken, IReserveToken reserveToken)
        internal
        view
        returns (Fraction memory, Fraction memory)
    {
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(ownedBy(poolToken)));
        IReserveToken otherReserve = converterOtherReserve(converter, reserveToken);

        (uint256 spotRateN, uint256 spotRateD) = converterReserveBalances(converter, otherReserve, reserveToken);
        (uint256 averageRateN, uint256 averageRateD) = converter.recentAverageRate(reserveToken);

        return (Fraction({ n: spotRateN, d: spotRateD }), Fraction({ n: averageRateN, d: averageRateD }));
    }

    /**
     * @dev returns the various rates between the reserves
     *
     * @param poolToken pool token
     * @param reserveToken reserve token
     * @param addSpotRateN add spot rate numerator
     * @param addSpotRateD add spot rate denominator
     *
     * @return see `struct PackedRates`
     */
    function packRates(
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 addSpotRateN,
        uint256 addSpotRateD
    ) internal view returns (PackedRates memory) {
        (Fraction memory removeSpotRate, Fraction memory removeAverageRate) =
            reserveTokenRates(poolToken, reserveToken);

        assert(
            addSpotRateN <= MAX_UINT128 &&
                addSpotRateD <= MAX_UINT128 &&
                removeSpotRate.n <= MAX_UINT128 &&
                removeSpotRate.d <= MAX_UINT128 &&
                removeAverageRate.n <= MAX_UINT128 &&
                removeAverageRate.d <= MAX_UINT128
        );

        return
            PackedRates({
                addSpotRateN: uint128(addSpotRateN),
                addSpotRateD: uint128(addSpotRateD),
                removeSpotRateN: uint128(removeSpotRate.n),
                removeSpotRateD: uint128(removeSpotRate.d),
                removeAverageRateN: uint128(removeAverageRate.n),
                removeAverageRateD: uint128(removeAverageRate.d)
            });
    }

    /**
     * @dev verifies that the deviation of the average rate from the spot rate is within the permitted range
     * for example, if the maximum permitted deviation is 5%, then verify `95/100 <= average/spot <= 100/95`
     *
     * @param spotRateN spot rate numerator
     * @param spotRateD spot rate denominator
     * @param averageRateN average rate numerator
     * @param averageRateD average rate denominator
     */
    function verifyRateDeviation(
        uint256 spotRateN,
        uint256 spotRateD,
        uint256 averageRateN,
        uint256 averageRateD
    ) internal view {
        uint256 ppmDelta = PPM_RESOLUTION - _settings.averageRateMaxDeviation();
        uint256 min = spotRateN.mul(averageRateD).mul(ppmDelta).mul(ppmDelta);
        uint256 mid = spotRateD.mul(averageRateN).mul(ppmDelta).mul(PPM_RESOLUTION);
        uint256 max = spotRateN.mul(averageRateD).mul(PPM_RESOLUTION).mul(PPM_RESOLUTION);
        require(min <= mid && mid <= max, "ERR_INVALID_RATE");
    }

    /**
     * @dev utility to add liquidity to a converter
     *
     * @param converter converter
     * @param reserveToken1 reserve token 1
     * @param reserveToken2 reserve token 2
     * @param reserveAmount1 reserve amount 1
     * @param reserveAmount2 reserve amount 2
     * @param value ETH amount to add
     */
    function addLiquidity(
        ILiquidityPoolConverter converter,
        IReserveToken reserveToken1,
        IReserveToken reserveToken2,
        uint256 reserveAmount1,
        uint256 reserveAmount2,
        uint256 value
    ) internal {
        IReserveToken[] memory reserveTokens = new IReserveToken[](2);
        uint256[] memory amounts = new uint256[](2);
        reserveTokens[0] = reserveToken1;
        reserveTokens[1] = reserveToken2;
        amounts[0] = reserveAmount1;
        amounts[1] = reserveAmount2;
        converter.addLiquidity{ value: value }(reserveTokens, amounts, 1);
    }

    /**
     * @dev utility to remove liquidity from a converter
     *
     * @param poolToken pool token of the converter
     * @param poolAmount amount of pool tokens to remove
     * @param reserveToken1 reserve token 1
     * @param reserveToken2 reserve token 2
     */
    function removeLiquidity(
        IDSToken poolToken,
        uint256 poolAmount,
        IReserveToken reserveToken1,
        IReserveToken reserveToken2
    ) internal {
        ILiquidityPoolConverter converter = ILiquidityPoolConverter(payable(ownedBy(poolToken)));

        IReserveToken[] memory reserveTokens = new IReserveToken[](2);
        uint256[] memory minReturns = new uint256[](2);
        reserveTokens[0] = reserveToken1;
        reserveTokens[1] = reserveToken2;
        minReturns[0] = 1;
        minReturns[1] = 1;
        converter.removeLiquidity(poolAmount, reserveTokens, minReturns);
    }

    /**
     * @dev returns a position from the store
     *
     * @param id position id
     *
     * @return a position
     */
    function position(uint256 id) internal view returns (Position memory) {
        Position memory pos;
        (
            pos.provider,
            pos.poolToken,
            pos.reserveToken,
            pos.poolAmount,
            pos.reserveAmount,
            pos.reserveRateN,
            pos.reserveRateD,
            pos.timestamp
        ) = _store.protectedLiquidity(id);

        return pos;
    }

    /**
     * @dev returns a position from the store
     *
     * @param id position id
     * @param provider authorized provider
     *
     * @return a position
     */
    function providerPosition(uint256 id, address provider) internal view returns (Position memory) {
        Position memory pos = position(id);
        require(pos.provider == provider, "ERR_ACCESS_DENIED");

        return pos;
    }

    /**
     * @dev returns the protected amount of reserve tokens plus accumulated fee before compensation
     *
     * @param poolAmount pool token amount when the liquidity was added
     * @param poolRate rate of 1 pool token in the related reserve token units
     * @param addRate rate of 1 reserve token in the other reserve token units when the liquidity was added
     * @param removeRate rate of 1 reserve token in the other reserve token units when the liquidity is removed
     *
     * @return protected amount of reserve tokens plus accumulated fee = sqrt(removeRate / addRate) * poolRate * poolAmount
     */
    function protectedAmountPlusFee(
        uint256 poolAmount,
        Fraction memory poolRate,
        Fraction memory addRate,
        Fraction memory removeRate
    ) internal pure returns (uint256) {
        uint256 n = MathEx.ceilSqrt(addRate.d.mul(removeRate.n)).mul(poolRate.n);
        uint256 d = MathEx.floorSqrt(addRate.n.mul(removeRate.d)).mul(poolRate.d);

        uint256 x = n * poolAmount;
        if (x / n == poolAmount) {
            return x / d;
        }

        (uint256 hi, uint256 lo) = n > poolAmount ? (n, poolAmount) : (poolAmount, n);
        (uint256 p, uint256 q) = MathEx.reducedRatio(hi, d, MAX_UINT256 / lo);
        uint256 min = (hi / d).mul(lo);

        if (q > 0) {
            return MathEx.max(min, (p * lo) / q);
        }
        return min;
    }

    /**
     * @dev returns the impermanent loss incurred due to the change in rates between the reserve tokens
     *
     * @param prevRate previous rate between the reserves
     * @param newRate new rate between the reserves
     *
     * @return impermanent loss (as a ratio)
     */
    function impLoss(Fraction memory prevRate, Fraction memory newRate) internal pure returns (Fraction memory) {
        uint256 ratioN = newRate.n.mul(prevRate.d);
        uint256 ratioD = newRate.d.mul(prevRate.n);

        uint256 prod = ratioN * ratioD;
        uint256 root =
            prod / ratioN == ratioD ? MathEx.floorSqrt(prod) : MathEx.floorSqrt(ratioN) * MathEx.floorSqrt(ratioD);
        uint256 sum = ratioN.add(ratioD);

        // the arithmetic below is safe because `x + y >= sqrt(x * y) * 2`
        if (sum % 2 == 0) {
            sum /= 2;
            return Fraction({ n: sum - root, d: sum });
        }
        return Fraction({ n: sum - root * 2, d: sum });
    }

    /**
     * @dev returns the protection level based on the timestamp and protection delays
     *
     * @param addTimestamp time at which the liquidity was added
     * @param removeTimestamp time at which the liquidity is removed
     *
     * @return protection level (as a ratio)
     */
    function protectionLevel(uint256 addTimestamp, uint256 removeTimestamp) internal view returns (Fraction memory) {
        uint256 timeElapsed = removeTimestamp.sub(addTimestamp);
        uint256 minProtectionDelay = _settings.minProtectionDelay();
        uint256 maxProtectionDelay = _settings.maxProtectionDelay();
        if (timeElapsed < minProtectionDelay) {
            return Fraction({ n: 0, d: 1 });
        }

        if (timeElapsed >= maxProtectionDelay) {
            return Fraction({ n: 1, d: 1 });
        }

        return Fraction({ n: timeElapsed, d: maxProtectionDelay });
    }

    /**
     * @dev returns the compensation amount based on the impermanent loss and the protection level
     *
     * @param amount protected amount in units of the reserve token
     * @param total amount plus fee in units of the reserve token
     * @param loss protection level (as a ratio between 0 and 1)
     * @param level impermanent loss (as a ratio between 0 and 1)
     *
     * @return compensation amount
     */
    function compensationAmount(
        uint256 amount,
        uint256 total,
        Fraction memory loss,
        Fraction memory level
    ) internal pure returns (uint256) {
        uint256 levelN = level.n.mul(amount);
        uint256 levelD = level.d;
        uint256 maxVal = MathEx.max(MathEx.max(levelN, levelD), total);
        (uint256 lossN, uint256 lossD) = MathEx.reducedRatio(loss.n, loss.d, MAX_UINT256 / maxVal);
        return total.mul(lossD.sub(lossN)).div(lossD).add(lossN.mul(levelN).div(lossD.mul(levelD)));
    }

    function networkCompensation(
        uint256 targetAmount,
        uint256 baseAmount,
        PackedRates memory packedRates
    ) internal view returns (uint256) {
        if (targetAmount <= baseAmount) {
            return 0;
        }

        // calculate the delta in network tokens
        uint256 delta =
            (targetAmount - baseAmount).mul(packedRates.removeAverageRateN).div(packedRates.removeAverageRateD);

        // the delta might be very small due to precision loss
        // in which case no compensation will take place (gas optimization)
        if (delta >= _settings.minNetworkCompensation()) {
            return delta;
        }

        return 0;
    }

    // utility to mint network tokens
    function mintNetworkTokens(
        address owner,
        IConverterAnchor poolAnchor,
        uint256 amount
    ) private {
        _systemStore.incNetworkTokensMinted(poolAnchor, amount);
        _networkTokenGovernance.mint(owner, amount);
    }

    // utility to burn network tokens
    function burnNetworkTokens(IConverterAnchor poolAnchor, uint256 amount) private {
        _systemStore.decNetworkTokensMinted(poolAnchor, amount);
        _networkTokenGovernance.burn(amount);
    }

    /**
     * @dev notify event subscribers on adding liquidity
     *
     * @param provider liquidity provider
     * @param poolToken pool token
     * @param reserveToken reserve token
     * @param poolAmount amount of pool tokens to protect
     * @param reserveAmount amount of reserve tokens to protect
     */
    function notifyEventSubscribersOnAddingLiquidity(
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) private {
        address[] memory subscribers = _settings.subscribers();
        uint256 length = subscribers.length;
        for (uint256 i = 0; i < length; i++) {
            ILiquidityProvisionEventsSubscriber(subscribers[i]).onAddingLiquidity(
                provider,
                poolToken,
                reserveToken,
                poolAmount,
                reserveAmount
            );
        }
    }

    /**
     * @dev notify event subscribers on removing liquidity
     *
     * @param id position id
     * @param provider liquidity provider
     * @param poolToken pool token
     * @param reserveToken reserve token
     * @param poolAmount amount of pool tokens to protect
     * @param reserveAmount amount of reserve tokens to protect
     */
    function notifyEventSubscribersOnRemovingLiquidity(
        uint256 id,
        address provider,
        IDSToken poolToken,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) private {
        address[] memory subscribers = _settings.subscribers();
        uint256 length = subscribers.length;
        for (uint256 i = 0; i < length; i++) {
            ILiquidityProvisionEventsSubscriber(subscribers[i]).onRemovingLiquidity(
                id,
                provider,
                poolToken,
                reserveToken,
                poolAmount,
                reserveAmount
            );
        }
    }

    // utility to get the reserve balances
    function converterReserveBalances(
        IConverter converter,
        IReserveToken reserveToken1,
        IReserveToken reserveToken2
    ) private view returns (uint256, uint256) {
        return (converter.getConnectorBalance(reserveToken1), converter.getConnectorBalance(reserveToken2));
    }

    // utility to get the other reserve
    function converterOtherReserve(IConverter converter, IReserveToken thisReserve)
        private
        view
        returns (IReserveToken)
    {
        IReserveToken otherReserve = converter.connectorTokens(0);
        return otherReserve != thisReserve ? otherReserve : converter.connectorTokens(1);
    }

    // utility to get the owner
    function ownedBy(IOwned owned) private view returns (address) {
        return owned.owner();
    }

    /**
     * @dev returns whether the provided reserve token is the network token
     *
     * @return whether the provided reserve token is the network token
     */
    function isNetworkToken(IReserveToken reserveToken) private view returns (bool) {
        return address(reserveToken) == address(_networkToken);
    }
}