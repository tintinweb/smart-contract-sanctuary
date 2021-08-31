/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/libraries/FixedPointMath.sol

pragma solidity ^0.6.12;

library FixedPointMath {
  uint256 public constant DECIMALS = 18;
  uint256 public constant SCALAR = 10**DECIMALS;

  struct uq192x64 {
    uint256 x;
  }

  function fromU256(uint256 value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require(value == 0 || (x = value * SCALAR) / SCALAR == value);
    return uq192x64(x);
  }

  function maximumValue() internal pure returns (uq192x64 memory) {
    return uq192x64(uint256(-1));
  }

  function add(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require((x = self.x + value.x) >= self.x);
    return uq192x64(x);
  }

  function add(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    return add(self, fromU256(value));
  }

  function sub(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require((x = self.x - value.x) <= self.x);
    return uq192x64(x);
  }

  function sub(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    return sub(self, fromU256(value));
  }

  function mul(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require(value == 0 || (x = self.x * value) / value == self.x);
    return uq192x64(x);
  }

  function div(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    require(value != 0);
    return uq192x64(self.x / value);
  }

  function cmp(uq192x64 memory self, uq192x64 memory value) internal pure returns (int256) {
    if (self.x < value.x) {
      return -1;
    }

    if (self.x > value.x) {
      return 1;
    }

    return 0;
  }

  function decode(uq192x64 memory self) internal pure returns (uint256) {
    return self.x / SCALAR;
  }
}


// File contracts/interfaces/IDetailedERC20.sol

pragma solidity ^0.6.12;

interface IDetailedERC20 is IERC20 {
  function name() external returns (string memory);
  function symbol() external returns (string memory);
  function decimals() external returns (uint8);
}


// File contracts/interfaces/IVaultAdapterV2.sol

pragma solidity ^0.6.12;

/// Interface for all Vault Adapter implementations.
interface IVaultAdapterV2 {

  /// @dev Gets the token that the adapter accepts.
  function token() external view returns (IDetailedERC20);

  /// @dev The total value of the assets deposited into the vault.
  function totalValue() external view returns (uint256);

  /// @dev Deposits funds into the vault.
  ///
  /// @param _amount  the amount of funds to deposit.
  function deposit(uint256 _amount) external;

  /// @dev Attempts to withdraw funds from the wrapped vault.
  ///
  /// The amount withdrawn to the recipient may be less than the amount requested.
  ///
  /// @param _recipient the recipient of the funds.
  /// @param _amount    the amount of funds to withdraw.
  function withdraw(address _recipient, uint256 _amount, bool _isHarvest) external;
}


// File contracts/interfaces/mStable/IimUSDToken.sol


pragma solidity 0.6.12;

interface IimUSDToken is IERC20 {
    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued);

    function redeemCredits(uint256 _credits) external returns (uint256 massetReturned);

    function exchangeRate() external view returns (uint256);

    function underlying() external view returns (address);

    function decimals() external view returns (uint8);

}


// File contracts/interfaces/mStable/IMUSDVault.sol

pragma solidity 0.6.12;

interface IMUSDVault {

    function stake(uint256) external;

    function withdraw(uint256) external;

    function claimReward() external;

    function balanceOf(address) external view returns (uint256);

}


// File contracts/interfaces/mStable/IAsset.sol

pragma solidity ^0.6.12;
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}


// File contracts/interfaces/mStable/IBalancerVault.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

pragma solidity ^0.6.12;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IBalancerVault{

  enum SwapKind { GIVEN_IN, GIVEN_OUT }

  struct BatchSwapStep {
      bytes32 poolId;
      uint256 assetInIndex;
      uint256 assetOutIndex;
      uint256 amount;
      bytes userData;
  }

  struct FundManagement {
      address sender;
      bool fromInternalBalance;
      address payable recipient;
      bool toInternalBalance;
  }

  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external payable returns (int256[] memory);


}


// File contracts/interfaces/mStable/IMasset.sol


pragma solidity ^0.6.12;
interface IMasset is IERC20{
  function getMintOutput(address _input, uint256 _inputQuantity) external view returns (uint256 mintOutput);

  function mint(address _input, uint256 _inputQuantity, uint256 _minOutputQuantity, address _recipient) external returns (uint256 mintOutput);
}


// File contracts/adapters/MUSDVaultAdapter.sol

pragma solidity ^0.6.12;

/// @title MUSDVaultAdapter
///
/// @dev A vault adapter implementation which wraps a vault.
contract MUSDVaultAdapter is IVaultAdapterV2 {
  using FixedPointMath for FixedPointMath.uq192x64;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  /// @dev The vault that the adapter is wrapping.
  IimUSDToken public vault;

  /// @dev The stakingPool that the adapter is wrapping.
  IMUSDVault public stakingPool;

  /// @dev balancerVault
  IBalancerVault public balancerVault;

  /// @dev mtaToken
  IDetailedERC20 public mtaToken;

  /// @dev wMatic
  IDetailedERC20 public wMaticToken;

  /// @dev usdc
  IDetailedERC20 public usdcToken;

  IMasset public mUSDToken;

  /// @dev The address which has admin control over this contract.
  address public admin;

  /// @dev The decimals of the token.
  uint256 public decimals;

  constructor(IimUSDToken _vault, address _admin, IBalancerVault _balancerVault, IMUSDVault _stakingPool, IDetailedERC20 _mtaToken, IDetailedERC20 _wMaticToken, IDetailedERC20 _usdcToken) public {
    require(address(_vault) != address(0), "MUSDVaultAdapter: vault address cannot be 0x0.");
    require(_admin != address(0), "MUSDVaultAdapter: _admin cannot be 0x0.");

    vault = _vault;
    admin = _admin;
    balancerVault = _balancerVault;
    stakingPool = _stakingPool;
    mtaToken = _mtaToken;
    wMaticToken = _wMaticToken;
    usdcToken = _usdcToken;
    mUSDToken = IMasset(vault.underlying());

    updateApproval();
    decimals = _vault.decimals();
  }

  /// @dev A modifier which reverts if the caller is not the admin.
  modifier onlyAdmin() {
    require(admin == msg.sender, "MUSDVaultAdapter: only admin");
    _;
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token() external view override returns (IDetailedERC20) {
    return IDetailedERC20(vault.underlying());
  }

  /// @dev Gets the total value of the assets that the adapter holds in the vault.
  ///
  /// @return the total assets.
  function totalValue() external view override returns (uint256) {

    return _sharesToTokens(stakingPool.balanceOf(address(this)));
  }

  /// @dev Deposits tokens into the vault.
  ///
  /// @param _amount the amount of tokens to deposit into the vault.
  function deposit(uint256 _amount) external override {

    // save to vault
    vault.depositSavings(_amount);
    // stake to stakingPool
    stakingPool.stake(vault.balanceOf(address(this)));

  }

  /// @dev Withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(address _recipient, uint256 _amount, bool _isHarvest) external override onlyAdmin {
    // unstake
    stakingPool.withdraw(_tokensToShares(_amount));

    // withdraw
    vault.redeemCredits(_tokensToShares(_amount));

    if(_isHarvest){

      // withdraw accumulated imMusd from collector harvest
      if(vault.balanceOf(address(this)) > 0){
        vault.redeemCredits(vault.balanceOf(address(this)));
      }

      // claim mta and wmatic
      stakingPool.claimReward();

      // swap mta to usdc
      IBalancerVault.BatchSwapStep[] memory _mtaSteps = new IBalancerVault.BatchSwapStep[](2);

      IBalancerVault.BatchSwapStep memory mtaStepOne;

      mtaStepOne.poolId = 0x614b5038611729ed49e0ded154d8a5d3af9d1d9e00010000000000000000001d;
      mtaStepOne.assetInIndex = 0;
      mtaStepOne.assetOutIndex = 1;
      mtaStepOne.amount = mtaToken.balanceOf(address(this));

      IBalancerVault.BatchSwapStep memory mtaStepTwo;

      mtaStepTwo.poolId = 0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002;
      mtaStepTwo.assetInIndex = 1;
      mtaStepTwo.assetOutIndex = 2;
      mtaStepTwo.amount = 0;

      _mtaSteps[0] = mtaStepOne;
      _mtaSteps[1] = mtaStepTwo;


      IBalancerVault.FundManagement memory fundManagementMta;

      fundManagementMta.sender = address(this);
      fundManagementMta.recipient = payable(address(this));

      IAsset[] memory _assetsMta = new IAsset[](3);

      _assetsMta[0] = IAsset(0xF501dd45a1198C2E1b5aEF5314A68B9006D842E0);
      _assetsMta[1] = IAsset(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
      _assetsMta[2] = IAsset(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

      int256[] memory _limitsMta = new int256[](3);

      _limitsMta[0] = int256(mtaToken.balanceOf(address(this)));
      _limitsMta[1] = 0;
      _limitsMta[2] = 0; // TODO

      balancerVault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN,_mtaSteps,_assetsMta,fundManagementMta,_limitsMta,block.timestamp+800);

      // swap wmatic to usdc
      IBalancerVault.BatchSwapStep[] memory _wmaticSteps = new IBalancerVault.BatchSwapStep[](2);

      IBalancerVault.BatchSwapStep memory wmaticStepOne;

      wmaticStepOne.poolId = 0xeb58be542e77195355d90100beb07105b9bd295e00010000000000000000001b;
      wmaticStepOne.assetInIndex = 0;
      wmaticStepOne.assetOutIndex = 1;
      wmaticStepOne.amount = wMaticToken.balanceOf(address(this));

      IBalancerVault.BatchSwapStep memory wmaticStepTwo;

      wmaticStepTwo.poolId = 0x36128d5436d2d70cab39c9af9cce146c38554ff0000100000000000000000008;
      wmaticStepTwo.assetInIndex = 1;
      wmaticStepTwo.assetOutIndex = 2;
      wmaticStepTwo.amount = 0;

      _wmaticSteps[0] = wmaticStepOne;
      _wmaticSteps[1] = wmaticStepTwo;


      IBalancerVault.FundManagement memory fundManagementWMatic;

      fundManagementWMatic.sender = address(this);
      fundManagementWMatic.recipient = payable(address(this));

      IAsset[] memory _assetsWMatic = new IAsset[](3);

      _assetsWMatic[0] = IAsset(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
      _assetsWMatic[1] = IAsset(0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3);
      _assetsWMatic[2] = IAsset(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

      int256[] memory _limitsWMatic = new int256[](3);

      _limitsWMatic[0] = int256(wMaticToken.balanceOf(address(this)));
      _limitsWMatic[1] = 0;
      _limitsWMatic[2] = 0; // TODO

      balancerVault.batchSwap(IBalancerVault.SwapKind.GIVEN_IN,_wmaticSteps,_assetsWMatic,fundManagementWMatic,_limitsWMatic,block.timestamp+800);

      // deposit usdc to mUSD
      uint256 minOut = mUSDToken.getMintOutput(address(usdcToken),usdcToken.balanceOf(address(this)));
      mUSDToken.mint(address(usdcToken),usdcToken.balanceOf(address(this)),minOut,address(this));

    }

    // transfer all the busd in adapter to yum
    mUSDToken.transfer(_recipient,mUSDToken.balanceOf(address(this)));
  }

  /// @dev Updates the vaults approval of the token to be the maximum value.
  function updateApproval() public {
    // musd to vault
    address _token = vault.underlying();
    IDetailedERC20(_token).safeApprove(address(vault), uint256(-1));
    // vault to stakingPool
    IDetailedERC20(address(vault)).safeApprove(address(stakingPool), uint256(-1));
    // mta to balancerVault
    mtaToken.safeApprove(address(balancerVault), uint256(-1));

    // wmatic to balancerVault
    wMaticToken.safeApprove(address(balancerVault), uint256(-1));

    // usdc to mUSDToken
    usdcToken.safeApprove(address(mUSDToken), uint256(-1));
  }

  /// @dev Computes the number of tokens an amount of shares is worth.
  ///
  /// @param _sharesAmount the amount of shares.
  ///
  /// @return the number of tokens the shares are worth.

  function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
    return _sharesAmount.mul(vault.exchangeRate()).div(10**decimals);
  }

  /// @dev Computes the number of shares an amount of tokens is worth.
  ///
  /// @param _tokensAmount the amount of shares.
  ///
  /// @return the number of shares the tokens are worth.
  function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
    return _tokensAmount.mul(10**decimals).div(vault.exchangeRate());
  }
}