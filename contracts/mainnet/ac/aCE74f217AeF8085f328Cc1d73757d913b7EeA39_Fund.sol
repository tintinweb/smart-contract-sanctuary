/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: IFund

interface IFund {
    function underlying() external view returns (address);

    function relayer() external view returns (address);

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerShare() external view returns (uint256);

    function totalValueLocked() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256);
}

// Part: IStrategy

interface IStrategy {
    function name() external pure returns (string memory);

    function version() external pure returns (string memory);

    function underlying() external view returns (address);

    function fund() external view returns (address);

    function creator() external view returns (address);

    function withdrawAllToFund() external;

    function withdrawToFund(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256);

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);
}

// Part: IUpgradeSource

interface IUpgradeSource {
    function shouldUpgrade() external view returns (bool, address);

    function finalizeUpgrade() external;
}

// Part: OpenZeppelin/[email protected]/AddressUpgradeable

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// Part: OpenZeppelin/[email protected]/IERC20Upgradeable

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// Part: OpenZeppelin/[email protected]/MathUpgradeable

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// Part: OpenZeppelin/[email protected]/SafeMathUpgradeable

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
library SafeMathUpgradeable {
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

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: SetGetAssembly

contract SetGetAssembly {
    // solhint-disable-next-line no-empty-blocks
    constructor() public {}

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function setUint8(bytes32 slot, uint8 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function setBool(bytes32 slot, bool _value) internal {
        setUint256(slot, _value ? 1 : 0);
    }

    function getBool(bytes32 slot) internal view returns (bool) {
        return (getUint256(slot) == 1);
    }

    function getAddress(bytes32 slot) internal view returns (address str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getUint8(bytes32 slot) internal view returns (uint8 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }
}

// Part: OpenZeppelin/[email protected]/Initializable

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// Part: FundStorage

contract FundStorage is Initializable, SetGetAssembly {
    bytes32 internal constant _UNDERLYING_SLOT =
        0xe0dc1d429ff8628e5936b3d6a6546947e1cc9ea7415a59d46ce95b3cfa4442b9;
    bytes32 internal constant _UNDERLYING_UNIT_SLOT =
        0x4840b03aa097a422092d99dc6875c2b69e8f48c9af2563a0447f3b4e4928d962;
    bytes32 internal constant _DECIMALS_SLOT =
        0x15b9fa1072bc4b2cdb762a49a2c7917b8b3af02283e37ffd41d0fccd4eef0d48;
    bytes32 internal constant _FUND_MANAGER_SLOT =
        0x670552e214026020a9e6caa820519c7f879b21bd75b5571387d6a9cf8f94bd18;
    bytes32 internal constant _RELAYER_SLOT =
        0x84e8c6b8f2281d51d9f683d351409724c3caa7848051aeb9d92c106ab36cc24c;
    bytes32 internal constant _PLATFORM_REWARDS_SLOT =
        0x92260bfe68dd0f8a9f5439b75466781ba1ce44523ed1a3026a73eada49072e65;
    bytes32 internal constant _DEPOSIT_LIMIT_SLOT =
        0xca2f8a3e9ea81335bcce793cde55fc0c38129b594f53052d2bb18099ffa72613;
    bytes32 internal constant _DEPOSIT_LIMIT_TX_MAX_SLOT =
        0x769f312c3790719cf1ea5f75303393f080fd62be88d75fa86726a6be00bb5a24;
    bytes32 internal constant _DEPOSIT_LIMIT_TX_MIN_SLOT =
        0x9027949576d185c74d79ad3b8a8dbff32126f3a3ee140b346f146beb18234c85;
    bytes32 internal constant _PERFORMANCE_FEE_FUND_SLOT =
        0x5b8979500398f8fbeb42c36d18f31a76fd0ab30f4338d864e7d8734b340e9bb9;
    bytes32 internal constant _PLATFORM_FEE_SLOT =
        0x2084059f3bff3cc3fd204df32325dcb05f47c2f590aba5d103ec584523738e7a;
    bytes32 internal constant _WITHDRAWAL_FEE_SLOT =
        0x0fa90db0cd58feef247d70d3b21f64c03d0e3ec10eb297f015da0cc09eb3412c;
    bytes32 internal constant _MAX_INVESTMENT_IN_STRATEGIES_SLOT =
        0xe3b5969c9426551aa8f16dbc7b25042b9b9c9869b759c77a85f0b097ac363475;
    bytes32 internal constant _TOTAL_WEIGHT_IN_STRATEGIES_SLOT =
        0x63177e03c47ab825f04f5f8f2334e312239890e7588db78cabe10d7aec327fd2;
    bytes32 internal constant _TOTAL_ACCOUNTED_SLOT =
        0xa19f3b8a62465676ae47ab811ee15e3d2b68d88869cb38686d086a11d382f6bb;
    bytes32 internal constant _TOTAL_INVESTED_SLOT =
        0x49c84685200b42972f845832b2c3da3d71def653c151340801aeae053ce104e9;
    bytes32 internal constant _DEPOSITS_PAUSED_SLOT =
        0x3cefcfe9774096ac956c0d63992ea27a01fb3884a22b8765ad63c8366f90a9c8;
    bytes32 internal constant _SHOULD_REBALANCE_SLOT =
        0x7f8e3dfb98485aa419c1d05b6ea089a8cddbafcfcf4491db33f5d0b5fe4f32c7;
    bytes32 internal constant _LAST_HARDWORK_TIMESTAMP_SLOT =
        0x0260c2bf5555cd32cedf39c0fcb0eab8029c67b3d5137faeb3e24a500db80bc9;
    bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT =
        0xa7ae0fa763ec3009113ccc5eb9089e1f0028607f5b8198c52cd42366c1ddb17b;

    constructor() public {
        assert(
            _UNDERLYING_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.mesh.finance.fundStorage.underlying")
                    ) - 1
                )
        );
        assert(
            _UNDERLYING_UNIT_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.underlyingUnit"
                        )
                    ) - 1
                )
        );
        assert(
            _DECIMALS_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.mesh.finance.fundStorage.decimals")
                    ) - 1
                )
        );
        assert(
            _FUND_MANAGER_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.fundManager"
                        )
                    ) - 1
                )
        );
        assert(
            _RELAYER_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.mesh.finance.fundStorage.relayer")
                    ) - 1
                )
        );
        assert(
            _PLATFORM_REWARDS_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.platformRewards"
                        )
                    ) - 1
                )
        );
        assert(
            _DEPOSIT_LIMIT_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.depositLimit"
                        )
                    ) - 1
                )
        );
        assert(
            _DEPOSIT_LIMIT_TX_MAX_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.depositLimitTxMax"
                        )
                    ) - 1
                )
        );
        assert(
            _DEPOSIT_LIMIT_TX_MIN_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.depositLimitTxMin"
                        )
                    ) - 1
                )
        );
        assert(
            _PERFORMANCE_FEE_FUND_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.performanceFeeFund"
                        )
                    ) - 1
                )
        );
        assert(
            _PLATFORM_FEE_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.platformFee"
                        )
                    ) - 1
                )
        );
        assert(
            _WITHDRAWAL_FEE_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.withdrawalFee"
                        )
                    ) - 1
                )
        );
        assert(
            _MAX_INVESTMENT_IN_STRATEGIES_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.maxInvestmentInStrategies"
                        )
                    ) - 1
                )
        );
        assert(
            _TOTAL_WEIGHT_IN_STRATEGIES_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.totalWeightInStrategies"
                        )
                    ) - 1
                )
        );
        assert(
            _TOTAL_ACCOUNTED_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.totalAccounted"
                        )
                    ) - 1
                )
        );
        assert(
            _TOTAL_INVESTED_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.totalInvested"
                        )
                    ) - 1
                )
        );
        assert(
            _DEPOSITS_PAUSED_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.depositsPaused"
                        )
                    ) - 1
                )
        );
        assert(
            _SHOULD_REBALANCE_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.shouldRebalance"
                        )
                    ) - 1
                )
        );
        assert(
            _LAST_HARDWORK_TIMESTAMP_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.lastHardworkTimestamp"
                        )
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.nextImplementation"
                        )
                    ) - 1
                )
        );
    }

    function initializeFundStorage(
        address _underlying,
        uint256 _underlyingUnit,
        uint8 _decimals,
        address _fundManager,
        address _relayer,
        address _platformRewards
    ) public initializer {
        _setUnderlying(_underlying);
        _setUnderlyingUnit(_underlyingUnit);
        _setDecimals(_decimals);
        _setFundManager(_fundManager);
        _setRelayer(_relayer);
        _setPlatformRewards(_platformRewards);
        _setDepositLimit(0);
        _setDepositLimitTxMax(0);
        _setDepositLimitTxMin(0);
        _setPerformanceFeeFund(0);
        _setPlatformFee(0);
        _setWithdrawalFee(0);
        _setMaxInvestmentInStrategies(9000); // 9000 BPS (90%) can be accessed by the strategies. This is to keep something in fund for withdrawal.
        _setTotalWeightInStrategies(0);
        _setTotalAccounted(0);
        _setTotalInvested(0);
        _setDepositsPaused(false);
        _setShouldRebalance(false);
        _setLastHardworkTimestamp(0);
        _setNextImplementation(address(0));
    }

    function _setUnderlying(address _address) internal {
        setAddress(_UNDERLYING_SLOT, _address);
    }

    function _underlying() internal view returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    function _setUnderlyingUnit(uint256 _value) internal {
        setUint256(_UNDERLYING_UNIT_SLOT, _value);
    }

    function _underlyingUnit() internal view returns (uint256) {
        return getUint256(_UNDERLYING_UNIT_SLOT);
    }

    function _setDecimals(uint8 _value) internal {
        setUint8(_DECIMALS_SLOT, _value);
    }

    function _decimals() internal view returns (uint8) {
        return getUint8(_DECIMALS_SLOT);
    }

    function _setFundManager(address _fundManager) internal {
        setAddress(_FUND_MANAGER_SLOT, _fundManager);
    }

    function _fundManager() internal view returns (address) {
        return getAddress(_FUND_MANAGER_SLOT);
    }

    function _setRelayer(address _relayer) internal {
        setAddress(_RELAYER_SLOT, _relayer);
    }

    function _relayer() internal view returns (address) {
        return getAddress(_RELAYER_SLOT);
    }

    function _setPlatformRewards(address _rewards) internal {
        setAddress(_PLATFORM_REWARDS_SLOT, _rewards);
    }

    function _platformRewards() internal view returns (address) {
        return getAddress(_PLATFORM_REWARDS_SLOT);
    }

    function _setDepositLimit(uint256 _value) internal {
        setUint256(_DEPOSIT_LIMIT_SLOT, _value);
    }

    function _depositLimit() internal view returns (uint256) {
        return getUint256(_DEPOSIT_LIMIT_SLOT);
    }

    function _setDepositLimitTxMax(uint256 _value) internal {
        setUint256(_DEPOSIT_LIMIT_TX_MAX_SLOT, _value);
    }

    function _depositLimitTxMax() internal view returns (uint256) {
        return getUint256(_DEPOSIT_LIMIT_TX_MAX_SLOT);
    }

    function _setDepositLimitTxMin(uint256 _value) internal {
        setUint256(_DEPOSIT_LIMIT_TX_MIN_SLOT, _value);
    }

    function _depositLimitTxMin() internal view returns (uint256) {
        return getUint256(_DEPOSIT_LIMIT_TX_MIN_SLOT);
    }

    function _setPerformanceFeeFund(uint256 _value) internal {
        setUint256(_PERFORMANCE_FEE_FUND_SLOT, _value);
    }

    function _performanceFeeFund() internal view returns (uint256) {
        return getUint256(_PERFORMANCE_FEE_FUND_SLOT);
    }

    function _setPlatformFee(uint256 _value) internal {
        setUint256(_PLATFORM_FEE_SLOT, _value);
    }

    function _platformFee() internal view returns (uint256) {
        return getUint256(_PLATFORM_FEE_SLOT);
    }

    function _setWithdrawalFee(uint256 _value) internal {
        setUint256(_WITHDRAWAL_FEE_SLOT, _value);
    }

    function _withdrawalFee() internal view returns (uint256) {
        return getUint256(_WITHDRAWAL_FEE_SLOT);
    }

    function _setMaxInvestmentInStrategies(uint256 _value) internal {
        setUint256(_MAX_INVESTMENT_IN_STRATEGIES_SLOT, _value);
    }

    function _maxInvestmentInStrategies() internal view returns (uint256) {
        return getUint256(_MAX_INVESTMENT_IN_STRATEGIES_SLOT);
    }

    function _setTotalWeightInStrategies(uint256 _value) internal {
        setUint256(_TOTAL_WEIGHT_IN_STRATEGIES_SLOT, _value);
    }

    function _totalWeightInStrategies() internal view returns (uint256) {
        return getUint256(_TOTAL_WEIGHT_IN_STRATEGIES_SLOT);
    }

    function _setTotalAccounted(uint256 _value) internal {
        setUint256(_TOTAL_ACCOUNTED_SLOT, _value);
    }

    function _totalAccounted() internal view returns (uint256) {
        return getUint256(_TOTAL_ACCOUNTED_SLOT);
    }

    function _setTotalInvested(uint256 _value) internal {
        setUint256(_TOTAL_INVESTED_SLOT, _value);
    }

    function _totalInvested() internal view returns (uint256) {
        return getUint256(_TOTAL_INVESTED_SLOT);
    }

    function _setDepositsPaused(bool _value) internal {
        setBool(_DEPOSITS_PAUSED_SLOT, _value);
    }

    function _depositsPaused() internal view returns (bool) {
        return getBool(_DEPOSITS_PAUSED_SLOT);
    }

    function _setShouldRebalance(bool _value) internal {
        setBool(_SHOULD_REBALANCE_SLOT, _value);
    }

    function _shouldRebalance() internal view returns (bool) {
        return getBool(_SHOULD_REBALANCE_SLOT);
    }

    function _setLastHardworkTimestamp(uint256 _value) internal {
        setUint256(_LAST_HARDWORK_TIMESTAMP_SLOT, _value);
    }

    function _lastHardworkTimestamp() internal view returns (uint256) {
        return getUint256(_LAST_HARDWORK_TIMESTAMP_SLOT);
    }

    function _setNextImplementation(address _newImplementation) internal {
        setAddress(_NEXT_IMPLEMENTATION_SLOT, _newImplementation);
    }

    function _nextImplementation() internal view returns (address) {
        return getAddress(_NEXT_IMPLEMENTATION_SLOT);
    }

    uint256[50] private bigEmptySlot;
}

// Part: Governable

contract Governable is Initializable, SetGetAssembly {
    event GovernanceUpdated(address newGovernance, address oldGovernance);

    bytes32 internal constant _GOVERNANCE_SLOT =
        0x597f9c7c685b907e823520bd45aeb3d58b505f86b2e41cd5b4cd5b6c72782950;
    bytes32 internal constant _PENDING_GOVERNANCE_SLOT =
        0xcd77091f18f9504fccf6140ab99e20533c811d470bb9a5a983d0edc0720fbf8c;

    modifier onlyGovernance() {
        require(_governance() == msg.sender, "Not governance");
        _;
    }

    constructor() public {
        assert(
            _GOVERNANCE_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.mesh.finance.governable.governance")
                    ) - 1
                )
        );
        assert(
            _PENDING_GOVERNANCE_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.governable.pendingGovernance"
                        )
                    ) - 1
                )
        );
    }

    function initializeGovernance(address _governance) public initializer {
        _setGovernance(_governance);
    }

    function _setGovernance(address _governance) private {
        setAddress(_GOVERNANCE_SLOT, _governance);
    }

    function _setPendingGovernance(address _pendingGovernance) private {
        setAddress(_PENDING_GOVERNANCE_SLOT, _pendingGovernance);
    }

    function updateGovernance(address _newGovernance) public onlyGovernance {
        require(
            _newGovernance != address(0),
            "new governance shouldn't be empty"
        );
        _setPendingGovernance(_newGovernance);
    }

    function acceptGovernance() public {
        require(_pendingGovernance() == msg.sender, "Not pending governance");
        address oldGovernance = _governance();
        _setGovernance(msg.sender);
        emit GovernanceUpdated(msg.sender, oldGovernance);
    }

    function _governance() internal view returns (address str) {
        return getAddress(_GOVERNANCE_SLOT);
    }

    function _pendingGovernance() internal view returns (address str) {
        return getAddress(_PENDING_GOVERNANCE_SLOT);
    }

    function governance() public view returns (address) {
        return _governance();
    }
}

// Part: OpenZeppelin/[email protected]/ContextUpgradeable

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// Part: OpenZeppelin/[email protected]/ReentrancyGuardUpgradeable

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// Part: OpenZeppelin/[email protected]/ERC20Upgradeable

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// File: Fund.sol

contract Fund is
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    IFund,
    IUpgradeSource,
    Governable,
    FundStorage
{
    using SafeERC20 for IERC20;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint8;

    event Withdraw(address indexed beneficiary, uint256 amount, uint256 fee);
    event Deposit(address indexed beneficiary, uint256 amount);
    event InvestInStrategy(address strategy, uint256 amount);
    event StrategyRewards(
        address strategy,
        uint256 profit,
        uint256 strategyCreatorFee
    );
    event FundManagerRewards(uint256 profitTotal, uint256 fundManagerFee);
    event PlatformRewards(
        uint256 lastBalance,
        uint256 timeElapsed,
        uint256 platformFee
    );
    event HardWorkDone(uint256 totalValueLocked, uint256 pricePerShare);

    event StrategyAdded(
        address strategy,
        uint256 weightage,
        uint256 performanceFeeStrategy
    );
    event StrategyWeightageUpdated(address strategy, uint256 newWeightage);
    event StrategyPerformanceFeeUpdated(
        address strategy,
        uint256 newPerformanceFeeStrategy
    );
    event StrategyRemoved(address strategy);

    address internal constant ZERO_ADDRESS = address(0);

    uint256 internal constant MAX_BPS = 10000; // 100% in basis points
    uint256 internal constant SECS_PER_YEAR = 31556952; // 365.25 days from yearn

    uint256 internal constant MAX_PLATFORM_FEE = 500; // 5% (annual on AUM), goes to governance/treasury
    uint256 internal constant MAX_PERFORMANCE_FEE_FUND = 1000; // 10% on profits, goes to fund manager
    uint256 internal constant MAX_PERFORMANCE_FEE_STRATEGY = 1000; // 10% on profits, goes to strategy creator
    uint256 internal constant MAX_WITHDRAWAL_FEE = 100; // 1%, goes to governance/treasury

    struct StrategyParams {
        uint256 weightage; // weightage of total assets in fund this strategy can access (in BPS) (5000 for 50%)
        uint256 performanceFeeStrategy; // in BPS, fee on yield of the strategy, goes to strategy creator
        uint256 activation; // timestamp when strategy is added
        uint256 lastBalance; // balance at last hard work
        uint256 indexInList;
    }

    mapping(address => StrategyParams) public strategies;
    address[] public strategyList;

    // solhint-disable-next-line no-empty-blocks
    constructor() public {}

    function initializeFund(
        address _governance,
        address _underlying,
        string memory _name,
        string memory _symbol
    ) public initializer {
        ERC20Upgradeable.__ERC20_init(_name, _symbol);

        __ReentrancyGuard_init();

        Governable.initializeGovernance(_governance);

        uint8 _decimals = ERC20Upgradeable(_underlying).decimals();

        uint256 _underlyingUnit = 10**uint256(_decimals);

        FundStorage.initializeFundStorage(
            _underlying,
            _underlyingUnit,
            _decimals,
            _governance, // fund manager is initialized as governance
            _governance, // relayer is initialized as governance
            _governance // rewards contract is initialized as governance
        );
    }

    modifier onlyFundManagerOrGovernance() {
        require(
            (_governance() == msg.sender) || (_fundManager() == msg.sender),
            "Not governance nor fund manager"
        );
        _;
    }

    modifier onlyFundManagerOrGovernanceOrRelayer() {
        require(
            (_governance() == msg.sender) ||
                (_fundManager() == msg.sender) ||
                (_relayer() == msg.sender),
            "Not governance nor fund manager nor relayer"
        );
        _;
    }

    modifier whenDepositsNotPaused() {
        require(!_depositsPaused(), "Deposits are paused");
        _;
    }

    function fundManager() external view returns (address) {
        return _fundManager();
    }

    function relayer() external view override returns (address) {
        return _relayer();
    }

    function underlying() external view override returns (address) {
        return _underlying();
    }

    function underlyingUnit() external view returns (uint256) {
        return _underlyingUnit();
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals();
    }

    function getStrategyCount() internal view returns (uint256) {
        return strategyList.length;
    }

    modifier whenStrategyDefined() {
        require(getStrategyCount() > 0, "Strategies must be defined");
        _;
    }

    function getStrategyList() public view returns (address[] memory) {
        return strategyList;
    }

    function getStrategy(address strategy)
        public
        view
        returns (StrategyParams memory)
    {
        return strategies[strategy];
    }

    /*
     * Returns the underlying balance currently in the fund.
     */
    function underlyingBalanceInFund() internal view returns (uint256) {
        return IERC20(_underlying()).balanceOf(address(this));
    }

    /*
     * Returns the current underlying (e.g., DAI's) balance together with
     * the invested amount (if DAI is invested elsewhere by the strategies).
     */
    function underlyingBalanceWithInvestment() internal view returns (uint256) {
        uint256 underlyingBalance = underlyingBalanceInFund();
        for (uint256 i; i < getStrategyCount(); i++) {
            underlyingBalance = underlyingBalance.add(
                IStrategy(strategyList[i]).investedUnderlyingBalance()
            );
        }
        return underlyingBalance;
    }

    /*
     * Returns price per share, scaled by underlying unit (10 ** decimals) to keep everything in uint256.
     */
    function _getPricePerShare() internal view returns (uint256) {
        return
            totalSupply() == 0
                ? _underlyingUnit()
                : _underlyingUnit().mul(underlyingBalanceWithInvestment()).div(
                    totalSupply()
                );
    }

    function getPricePerShare() external view override returns (uint256) {
        return _getPricePerShare();
    }

    function totalValueLocked() external view override returns (uint256) {
        return underlyingBalanceWithInvestment();
    }

    function _underlyingFromShares(uint256 numShares)
        internal
        view
        returns (uint256)
    {
        return
            underlyingBalanceWithInvestment().mul(numShares).div(totalSupply());
    }

    /*
     * get the user's balance (in underlying)
     */
    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        override
        returns (uint256)
    {
        if (totalSupply() == 0) {
            return 0;
        }
        return _underlyingFromShares(balanceOf(holder));
    }

    function isActiveStrategy(address strategy) internal view returns (bool) {
        return strategies[strategy].weightage > 0;
    }

    function addStrategy(
        address newStrategy,
        uint256 weightage,
        uint256 performanceFeeStrategy
    ) external onlyFundManagerOrGovernance {
        require(newStrategy != ZERO_ADDRESS, "new newStrategy cannot be empty");
        require(
            IStrategy(newStrategy).fund() == address(this),
            "The strategy does not belong to this fund"
        );
        require(
            isActiveStrategy(newStrategy) == false,
            "This strategy is already active in this fund"
        );
        require(weightage > 0, "The weightage should be greater than 0");
        uint256 totalWeightInStrategies =
            _totalWeightInStrategies().add(weightage);
        require(
            totalWeightInStrategies <= _maxInvestmentInStrategies(),
            "Total investment can't be above max allowed"
        );
        require(
            performanceFeeStrategy <= MAX_PERFORMANCE_FEE_STRATEGY,
            "Performance fee too high"
        );

        strategies[newStrategy].weightage = weightage;
        _setTotalWeightInStrategies(totalWeightInStrategies);
        // solhint-disable-next-line not-rely-on-time
        strategies[newStrategy].activation = block.timestamp;
        strategies[newStrategy].indexInList = getStrategyCount();
        strategies[newStrategy].performanceFeeStrategy = performanceFeeStrategy;
        strategyList.push(newStrategy);
        _setShouldRebalance(true);

        IERC20(_underlying()).safeApprove(newStrategy, 0);
        IERC20(_underlying()).safeApprove(newStrategy, type(uint256).max);

        emit StrategyAdded(newStrategy, weightage, performanceFeeStrategy);
    }

    function removeStrategy(address activeStrategy)
        external
        onlyFundManagerOrGovernance
    {
        require(
            activeStrategy != ZERO_ADDRESS,
            "current strategy cannot be empty"
        );
        require(
            isActiveStrategy(activeStrategy),
            "This strategy is not active in this fund"
        );

        _setTotalWeightInStrategies(
            _totalWeightInStrategies().sub(strategies[activeStrategy].weightage)
        );
        uint256 totalStrategies = getStrategyCount();
        for (
            uint256 i = strategies[activeStrategy].indexInList;
            i < totalStrategies - 1;
            i++
        ) {
            strategyList[i] = strategyList[i + 1];
            strategies[strategyList[i]].indexInList = i;
        }
        strategyList.pop();
        delete strategies[activeStrategy];
        IERC20(_underlying()).safeApprove(activeStrategy, 0);
        IStrategy(activeStrategy).withdrawAllToFund();
        _setShouldRebalance(true);

        emit StrategyRemoved(activeStrategy);
    }

    function updateStrategyWeightage(
        address activeStrategy,
        uint256 newWeightage
    ) external onlyFundManagerOrGovernance {
        require(
            activeStrategy != ZERO_ADDRESS,
            "current strategy cannot be empty"
        );
        require(
            isActiveStrategy(activeStrategy),
            "This strategy is not active in this fund"
        );
        require(newWeightage > 0, "The weightage should be greater than 0");
        uint256 totalWeightInStrategies =
            _totalWeightInStrategies()
                .sub(strategies[activeStrategy].weightage)
                .add(newWeightage);
        require(
            totalWeightInStrategies <= _maxInvestmentInStrategies(),
            "Total investment can't be above max allowed"
        );

        _setTotalWeightInStrategies(totalWeightInStrategies);
        strategies[activeStrategy].weightage = newWeightage;
        _setShouldRebalance(true);

        emit StrategyWeightageUpdated(activeStrategy, newWeightage);
    }

    function updateStrategyPerformanceFee(
        address activeStrategy,
        uint256 newPerformanceFeeStrategy
    ) external onlyFundManagerOrGovernance {
        require(
            activeStrategy != ZERO_ADDRESS,
            "current strategy cannot be empty"
        );
        require(
            isActiveStrategy(activeStrategy),
            "This strategy is not active in this fund"
        );
        require(
            newPerformanceFeeStrategy <= MAX_PERFORMANCE_FEE_STRATEGY,
            "Performance fee too high"
        );

        strategies[activeStrategy]
            .performanceFeeStrategy = newPerformanceFeeStrategy;

        emit StrategyPerformanceFeeUpdated(
            activeStrategy,
            newPerformanceFeeStrategy
        );
    }

    function processFees() internal {
        uint256 profitToFund = 0;

        for (uint256 i; i < getStrategyCount(); i++) {
            address strategy = strategyList[i];

            uint256 profit = 0;
            uint256 strategyCreatorFee = 0;

            if (
                IStrategy(strategy).investedUnderlyingBalance() >
                strategies[strategy].lastBalance
            ) {
                profit =
                    IStrategy(strategy).investedUnderlyingBalance() -
                    strategies[strategy].lastBalance;
                strategyCreatorFee = profit
                    .mul(strategies[strategy].performanceFeeStrategy)
                    .div(MAX_BPS);
                if (
                    strategyCreatorFee > 0 &&
                    strategyCreatorFee < underlyingBalanceInFund()
                ) {
                    IERC20(_underlying()).safeTransfer(
                        IStrategy(strategy).creator(),
                        strategyCreatorFee
                    );
                }
                profitToFund = profitToFund.add(profit).sub(strategyCreatorFee);
            }
            emit StrategyRewards(strategy, profit, strategyCreatorFee);
        }

        uint256 fundManagerFee =
            profitToFund.mul(_performanceFeeFund()).div(MAX_BPS);
        if (fundManagerFee > 0 && fundManagerFee < underlyingBalanceInFund()) {
            address fundManagerRewards =
                (_fundManager() == _governance())
                    ? _platformRewards()
                    : _fundManager();
            IERC20(_underlying()).safeTransfer(
                fundManagerRewards,
                fundManagerFee
            );
            emit FundManagerRewards(profitToFund, fundManagerFee);
        }

        uint256 platformFee =
            // solhint-disable-next-line not-rely-on-time
            (_totalInvested() * (block.timestamp - _lastHardworkTimestamp()))
                .mul(_platformFee())
                .div(MAX_BPS)
                .div(SECS_PER_YEAR);

        if (platformFee > 0 && platformFee < underlyingBalanceInFund()) {
            IERC20(_underlying()).safeTransfer(_platformRewards(), platformFee);
            emit PlatformRewards(
                _totalInvested(),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp - _lastHardworkTimestamp(),
                platformFee
            );
        }
    }

    /*
     * Invests the underlying capital to various strategies. Looks for weightage changes.
     */
    function doHardWork()
        external
        whenStrategyDefined
        onlyFundManagerOrGovernanceOrRelayer
    {
        if (_lastHardworkTimestamp() > 0) {
            processFees();
        }
        // ensure that new funds are invested too

        if (_shouldRebalance()) {
            _setShouldRebalance(false);
            doHardWorkWithRebalance();
        } else {
            doHardWorkWithoutRebalance();
        }
        // solhint-disable-next-line not-rely-on-time
        _setLastHardworkTimestamp(block.timestamp);
        emit HardWorkDone(
            underlyingBalanceWithInvestment(),
            _getPricePerShare()
        );
    }

    function doHardWorkWithoutRebalance() internal {
        uint256 lastReserve =
            _totalAccounted() > 0 ? _totalAccounted().sub(_totalInvested()) : 0;
        uint256 availableAmountToInvest =
            underlyingBalanceInFund() > lastReserve
                ? underlyingBalanceInFund().sub(lastReserve)
                : 0;

        if (availableAmountToInvest == 0) {
            return;
        }

        _setTotalAccounted(_totalAccounted().add(availableAmountToInvest));
        uint256 totalInvested = 0;

        for (uint256 i; i < getStrategyCount(); i++) {
            address strategy = strategyList[i];
            uint256 availableAmountForStrategy =
                availableAmountToInvest.mul(strategies[strategy].weightage).div(
                    MAX_BPS
                );
            if (availableAmountForStrategy > 0) {
                IERC20(_underlying()).safeTransfer(
                    strategy,
                    availableAmountForStrategy
                );
                totalInvested = totalInvested.add(availableAmountForStrategy);
                emit InvestInStrategy(strategy, availableAmountForStrategy);
            }

            IStrategy(strategy).doHardWork();

            strategies[strategy].lastBalance = IStrategy(strategy)
                .investedUnderlyingBalance();
        }
        _setTotalInvested(totalInvested);
    }

    function doHardWorkWithRebalance() internal {
        uint256 totalUnderlyingWithInvestment =
            underlyingBalanceWithInvestment();
        _setTotalAccounted(totalUnderlyingWithInvestment);
        uint256 totalInvested = 0;
        uint256[] memory toDeposit = new uint256[](getStrategyCount());

        for (uint256 i; i < getStrategyCount(); i++) {
            address strategy = strategyList[i];
            uint256 shouldBeInStrategy =
                totalUnderlyingWithInvestment
                    .mul(strategies[strategy].weightage)
                    .div(MAX_BPS);
            totalInvested = totalInvested.add(shouldBeInStrategy);
            uint256 currentlyInStrategy =
                IStrategy(strategy).investedUnderlyingBalance();
            if (currentlyInStrategy > shouldBeInStrategy) {
                // withdraw from strategy
                IStrategy(strategy).withdrawToFund(
                    currentlyInStrategy.sub(shouldBeInStrategy)
                );
            } else if (shouldBeInStrategy > currentlyInStrategy) {
                // can not directly deposit here as there might not be enough balance before withdrawing from required strategies
                toDeposit[i] = shouldBeInStrategy.sub(currentlyInStrategy);
            }
        }
        _setTotalInvested(totalInvested);

        for (uint256 i; i < getStrategyCount(); i++) {
            address strategy = strategyList[i];
            if (toDeposit[i] > 0) {
                IERC20(_underlying()).safeTransfer(strategy, toDeposit[i]);
                emit InvestInStrategy(strategy, toDeposit[i]);
            }
            IStrategy(strategy).doHardWork();

            strategies[strategy].lastBalance = IStrategy(strategy)
                .investedUnderlyingBalance();
        }
    }

    function pauseDeposits(bool trigger) external onlyFundManagerOrGovernance {
        _setDepositsPaused(trigger);
    }

    /*
     * Allows for depositing the underlying asset in exchange for shares.
     * Approval is assumed.
     */
    function deposit(uint256 amount)
        external
        override
        nonReentrant
        whenDepositsNotPaused
    {
        _deposit(amount, msg.sender, msg.sender);
    }

    /*
     * Allows for depositing the underlying asset and shares assigned to the holder.
     * This facilitates depositing for someone else (e.g. using DepositHelper)
     */
    function depositFor(uint256 amount, address holder)
        external
        override
        nonReentrant
        whenDepositsNotPaused
    {
        require(holder != ZERO_ADDRESS, "holder must be defined");
        _deposit(amount, msg.sender, holder);
    }

    function _deposit(
        uint256 amount,
        address sender,
        address beneficiary
    ) internal {
        require(amount > 0, "Cannot deposit 0");

        if (_depositLimit() > 0) {
            // if deposit limit is 0, then there is no deposit limit
            require(
                underlyingBalanceWithInvestment().add(amount) <=
                    _depositLimit(),
                "Total deposit limit hit"
            );
        }

        if (_depositLimitTxMax() > 0) {
            // if deposit limit is 0, then there is no deposit limit
            require(
                amount <= _depositLimitTxMax(),
                "Maximum transaction deposit limit hit"
            );
        }

        if (_depositLimitTxMin() > 0) {
            // if deposit limit is 0, then there is no deposit limit
            require(
                amount >= _depositLimitTxMin(),
                "Minimum transaction deposit limit hit"
            );
        }

        uint256 toMint =
            totalSupply() == 0
                ? amount
                : amount.mul(totalSupply()).div(
                    underlyingBalanceWithInvestment()
                );
        _mint(beneficiary, toMint);

        IERC20(_underlying()).safeTransferFrom(sender, address(this), amount);
        emit Deposit(beneficiary, amount);
    }

    function withdraw(uint256 numberOfShares) external override nonReentrant {
        require(totalSupply() > 0, "Fund has no shares");
        require(numberOfShares > 0, "numberOfShares must be greater than 0");

        uint256 underlyingAmountToWithdraw =
            _underlyingFromShares(numberOfShares);
        _burn(msg.sender, numberOfShares);

        if (underlyingAmountToWithdraw > underlyingBalanceInFund()) {
            uint256 missing =
                underlyingAmountToWithdraw.sub(underlyingBalanceInFund());
            uint256 missingCarryOver;
            for (uint256 i; i < getStrategyCount(); i++) {
                if (isActiveStrategy(strategyList[i])) {
                    uint256 balanceBefore = underlyingBalanceInFund();
                    uint256 weightage = strategies[strategyList[i]].weightage;
                    uint256 missingforStrategy =
                        (missing.mul(weightage).div(_totalWeightInStrategies()))
                            .add(missingCarryOver);
                    IStrategy(strategyList[i]).withdrawToFund(
                        missingforStrategy
                    );
                    missingCarryOver = missingforStrategy
                        .add(balanceBefore)
                        .sub(underlyingBalanceInFund());
                }
            }
            // recalculate to improve accuracy
            underlyingAmountToWithdraw = MathUpgradeable.min(
                underlyingAmountToWithdraw,
                underlyingBalanceInFund()
            );
            _setShouldRebalance(true);
        }

        uint256 withdrawalFee =
            underlyingAmountToWithdraw.mul(_withdrawalFee()).div(MAX_BPS);

        if (withdrawalFee > 0) {
            IERC20(_underlying()).safeTransfer(
                _platformRewards(),
                withdrawalFee
            );
            underlyingAmountToWithdraw = underlyingAmountToWithdraw.sub(
                withdrawalFee
            );
        }

        IERC20(_underlying()).safeTransfer(
            msg.sender,
            underlyingAmountToWithdraw
        );

        emit Withdraw(msg.sender, underlyingAmountToWithdraw, withdrawalFee);
    }

    /**
    * Schedules an upgrade for this fund's proxy.
    */
    function scheduleUpgrade(address newImplementation) external onlyGovernance {
        // Timelock implementation can be done here later
        _setNextImplementation(newImplementation);
    }

    function shouldUpgrade() external view override returns (bool, address) {
        return (_nextImplementation() != address(0), _nextImplementation());
    }

    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
    }

    function setFundManager(address newFundManager)
        external
        onlyFundManagerOrGovernance
    {
        _setFundManager(newFundManager);
    }

    function setRelayer(address newRelayer)
        external
        onlyFundManagerOrGovernance
    {
        _setRelayer(newRelayer);
    }

    function setPlatformRewards(address newRewards) external onlyGovernance {
        _setPlatformRewards(newRewards);
    }

    function setShouldRebalance(bool trigger)
        external
        onlyFundManagerOrGovernance
    {
        _setShouldRebalance(trigger);
    }

    function setMaxInvestmentInStrategies(uint256 value)
        external
        onlyFundManagerOrGovernance
    {
        require(value < MAX_BPS, "Value greater than 100%");
        _setMaxInvestmentInStrategies(value);
    }

    // if limit == 0 then there is no deposit limit
    function setDepositLimit(uint256 limit)
        external
        onlyFundManagerOrGovernance
    {
        _setDepositLimit(limit);
    }

    function depositLimit() external view returns (uint256) {
        return _depositLimit();
    }

    // if limit == 0 then there is no deposit limit
    function setDepositLimitTxMax(uint256 limit)
        external
        onlyFundManagerOrGovernance
    {
        _setDepositLimitTxMax(limit);
    }

    function depositLimitTxMax() external view returns (uint256) {
        return _depositLimitTxMax();
    }

    // if limit == 0 then there is no deposit limit
    function setDepositLimitTxMin(uint256 limit)
        external
        onlyFundManagerOrGovernance
    {
        _setDepositLimitTxMin(limit);
    }

    function depositLimitTxMin() external view returns (uint256) {
        return _depositLimitTxMin();
    }

    function setPerformanceFeeFund(uint256 fee)
        external
        onlyFundManagerOrGovernance
    {
        require(fee <= MAX_PERFORMANCE_FEE_FUND, "Fee greater than max limit");
        _setPerformanceFeeFund(fee);
    }

    function performanceFeeFund() external view returns (uint256) {
        return _performanceFeeFund();
    }

    function setPlatformFee(uint256 fee) external onlyFundManagerOrGovernance {
        require(fee <= MAX_PLATFORM_FEE, "Fee greater than max limit");
        _setPlatformFee(fee);
    }

    function platformFee() external view returns (uint256) {
        return _platformFee();
    }

    function setWithdrawalFee(uint256 fee)
        external
        onlyFundManagerOrGovernance
    {
        require(fee <= MAX_WITHDRAWAL_FEE, "Fee greater than max limit");
        _setWithdrawalFee(fee);
    }

    function withdrawalFee() external view returns (uint256) {
        return _withdrawalFee();
    }

    // no tokens should ever be stored on this contract. Any tokens that are sent here by mistake are recoverable by governance
    function sweep(address _token, address _sweepTo) external onlyGovernance {
        require(_token != address(_underlying()), "can not sweep underlying");
        IERC20(_token).safeTransfer(
            _sweepTo,
            IERC20(_token).balanceOf(address(this))
        );
    }
}