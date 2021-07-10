// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAToken {
	function redeem(uint256 amount) external;

	function principalBalanceOf(address user) external view returns (uint256);

	function balanceOf(address user) external view returns (uint256);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function transfer(address, uint256) external returns (bool);

	function transferAllowed(address from, uint256 amount)
		external
		returns (bool);

	function underlyingAssetAddress() external pure returns (address);

	function UNDERLYING_ASSET_ADDRESS() external pure returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveAddressProvider {
	function getLendingPool() external view returns (address);

	function getLendingPoolCore() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveIncentives {
	function REWARD_TOKEN() external view returns (address);

	function getRewardsBalance(address[] calldata assets, address user)
		external
		view
		returns (uint256);

	function getUserUnclaimedRewards(address _user)
		external
		view
		returns (uint256);

	function claimRewards(
		address[] calldata assets,
		uint256 amount,
		address to
	) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPool {
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMemory {
	function getUint() external view returns (uint256);

	function setUint(uint256) external;

	function getAToken(address asset) external view returns (address);

	function setAToken(address asset, address _aToken) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolDistribution {
	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function getReward(address user) external;

	function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RegistryInterface Interface
 */
interface IRegistry {
	function logic(address logicAddr) external view returns (bool);

	function implementation(bytes32 key) external view returns (address);

	function notAllowed(address erc20) external view returns (bool);

	function deployWallet() external returns (address);

	function wallets(address user) external view returns (address);

	function getFee() external view returns (uint256);

	function feeRecipient() external view returns (address);

	function memoryAddr() external view returns (address);

	function distributionContract(address token)
		external
		view
		returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
	function deposit() external payable virtual;

	function withdraw(uint256 amount) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWallet {
	event LogMint(address indexed erc20, uint256 tokenAmt);
	event LogRedeem(address indexed erc20, uint256 tokenAmt);
	event LogBorrow(address indexed erc20, uint256 tokenAmt);
	event LogPayback(address indexed erc20, uint256 tokenAmt);
	event LogDeposit(address indexed erc20, uint256 tokenAmt);
	event LogWithdraw(address indexed erc20, uint256 tokenAmt);
	event LogSwap(address indexed src, address indexed dest, uint256 amount);
	event LogLiquidityAdd(
		address indexed tokenA,
		address indexed tokenB,
		uint256 amountA,
		uint256 amountB
	);
	event LogLiquidityRemove(
		address indexed tokenA,
		address indexed tokenB,
		uint256 amountA,
		uint256 amountB
	);
	event VaultDeposit(address indexed erc20, uint256 tokenAmt);
	event VaultWithdraw(address indexed erc20, uint256 tokenAmt);
	event VaultClaim(address indexed erc20, uint256 tokenAmt);
	event DelegateAdded(address delegate);
	event DelegateRemoved(address delegate);

	function executeMetaTransaction(bytes memory sign, bytes memory data)
		external;

	function execute(address[] calldata targets, bytes[] calldata datas)
		external
		payable;

	function owner() external view returns (address);

	function registry() external view returns (address);

	function DELEGATE_ROLE() external view returns (bytes32);

	function hasRole(bytes32, address) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniversalERC20 {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 private constant ZERO_ADDRESS =
		IERC20(0x0000000000000000000000000000000000000000);
	IERC20 private constant ETH_ADDRESS =
		IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

	function universalTransfer(
		IERC20 token,
		address to,
		uint256 amount
	) internal returns (bool success) {
		if (amount == 0) {
			return true;
		}

		if (isETH(token)) {
			payable(to).transfer(amount);
		} else {
			token.safeTransfer(to, amount);
			return true;
		}
	}

	function universalTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 amount
	) internal {
		if (amount == 0) {
			return;
		}

		if (isETH(token)) {
			require(
				from == msg.sender && msg.value >= amount,
				"Wrong useage of ETH.universalTransferFrom()"
			);
			if (to != address(this)) {
				payable(to).transfer(amount);
			}
			if (msg.value > amount) {
				payable(msg.sender).transfer(msg.value.sub(amount));
			}
		} else {
			token.safeTransferFrom(from, to, amount);
		}
	}

	function universalTransferFromSenderToThis(IERC20 token, uint256 amount)
		internal
	{
		if (amount == 0) {
			return;
		}

		if (isETH(token)) {
			if (msg.value > amount) {
				// Return remainder if exist
				payable(msg.sender).transfer(msg.value.sub(amount));
			}
		} else {
			token.safeTransferFrom(msg.sender, address(this), amount);
		}
	}

	function universalApprove(
		IERC20 token,
		address to,
		uint256 amount
	) internal {
		if (!isETH(token)) {
			if (amount == 0) {
				token.safeApprove(to, 0);
				return;
			}

			uint256 allowance = token.allowance(address(this), to);
			if (allowance < amount) {
				if (allowance > 0) {
					token.safeApprove(to, 0);
				}
				token.safeApprove(to, amount);
			}
		}
	}

	function universalBalanceOf(IERC20 token, address who)
		internal
		view
		returns (uint256)
	{
		if (isETH(token)) {
			return who.balance;
		} else {
			return token.balanceOf(who);
		}
	}

	function universalDecimals(IERC20 token) internal view returns (uint256) {
		if (isETH(token)) {
			return 18;
		}

		(bool success, bytes memory data) =
			address(token).staticcall{gas: 10000}(
				abi.encodeWithSignature("decimals()")
			);
		if (!success || data.length == 0) {
			(success, data) = address(token).staticcall{gas: 10000}(
				abi.encodeWithSignature("DECIMALS()")
			);
		}

		return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
	}

	function isETH(IERC20 token) internal pure returns (bool) {
		return (address(token) == address(ZERO_ADDRESS) ||
			address(token) == address(ETH_ADDRESS));
	}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IWETH.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IAaveIncentives.sol";
import "../interfaces/IAaveAddressProvider.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/IWallet.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IMemory.sol";
import "../interfaces/IProtocolDistribution.sol";
import "../libs/UniversalERC20.sol";
import "./Helpers.sol";

contract DSMath is Helpers {
	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require((z = x + y) >= x, "math-not-safe");
	}

	function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require((z = x - y) <= x, "math-not-safe");
	}

	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		require(y == 0 || (z = x * y) / y == x, "math-not-safe");
	}

	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		require(_b > 0); // Solidity only automatically asserts when dividing by 0
		uint256 c = _a / _b;
		// assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
		return c;
	}

	uint256 constant WAD = 10**18;

	function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = add(mul(x, y), WAD / 2) / WAD;
	}

	function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = add(mul(x, WAD), y / 2) / y;
	}
}

contract AaveHelpers is DSMath {
	/**
	 * @dev get ethereum address
	 */
	function getAddressETH() public pure returns (address eth) {
		eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	}

	/**
	 * @dev get Aave Lending Pool Address V2
	 */
	function getLendingPoolAddress()
		public
		view
		returns (address lendingPoolAddress)
	{
		IAaveAddressProvider adr =
			IAaveAddressProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);
		return adr.getLendingPool();
	}

	function getWMATIC() public pure returns (address) {
		return 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
	}

	function getReferralCode() public pure returns (uint16) {
		return uint16(0);
	}

	function _stake(address erc20, uint256 amount) internal {
		// Add same amount to distribution contract
		address distribution =
			IRegistry(IWallet(address(this)).registry()).distributionContract(
				erc20
			);
		if (distribution != address(0)) {
			IProtocolDistribution(distribution).stake(amount);
		}
	}

	function _unstake(address erc20, uint256 amount) internal {
		address distribution =
			IRegistry(IWallet(address(this)).registry()).distributionContract(
				erc20
			);

		if (distribution != address(0)) {
			uint256 maxWithdrawalAmount =
				IProtocolDistribution(distribution).balanceOf(address(this));

			IProtocolDistribution(distribution).withdraw(
				amount > maxWithdrawalAmount ? maxWithdrawalAmount : amount
			);
		}
	}
}

contract AaveResolver is AaveHelpers {
	using SafeMath for uint256;
	using UniversalERC20 for IERC20;

	event LogMint(address indexed erc20, uint256 tokenAmt);
	event LogRedeem(address indexed erc20, uint256 tokenAmt);
	event LogBorrow(address indexed erc20, uint256 tokenAmt);
	event LogPayback(address indexed erc20, uint256 tokenAmt);

	/**
	 * @dev Deposit MATIC/ERC20 and mint Aave V2 Tokens
	 * @param erc20 underlying asset to deposit
	 * @param tokenAmt amount of underlying asset to deposit
	 * @param getValue read value of tokenAmt from memory contract
	 * @param setValue set value of aTokens minted in memory contract
	 */
	function mintAToken(
		address erc20,
		uint256 tokenAmt,
		bool getValue,
		bool setValue
	) external payable {
		uint256 realAmt = getValue ? getUint() : tokenAmt;

		require(getAToken(erc20) != address(0), "INVALID ASSET");

		require(
			realAmt > 0 &&
				realAmt <= IERC20(erc20).universalBalanceOf(address(this)),
			"INVALID AMOUNT"
		);

		address realToken = erc20;

		if (erc20 == getAddressETH()) {
			IWETH(getWMATIC()).deposit{value: realAmt}();
			realToken = getWMATIC();
		}

		ILendingPool _lendingPool = ILendingPool(getLendingPoolAddress());

		IERC20(realToken).universalApprove(address(_lendingPool), realAmt);

		_lendingPool.deposit(
			realToken,
			realAmt,
			address(this),
			getReferralCode()
		);

		_stake(erc20, realAmt);

		// set aTokens received
		if (setValue) {
			setUint(
				IERC20(getAToken(realToken)).universalBalanceOf(address(this))
			);
		}

		emit LogMint(erc20, realAmt);
	}

	/**
	 * @dev Redeem MATIC/ERC20 and burn Aave V2 Tokens
	 * @param erc20 underlying asset to redeem
	 * @param tokenAmt Amount of underling tokens
	 * @param getValue read value of tokenAmt from memory contract
	 * @param setValue set value of tokens redeemed in memory contract
	 */
	function redeemAToken(
		address erc20,
		uint256 tokenAmt,
		bool getValue,
		bool setValue
	) external {
		IAToken aToken = IAToken(getAToken(erc20));
		require(address(aToken) != address(0), "INVALID ASSET");

		uint256 realAmt = getValue ? getUint() : tokenAmt;

		require(realAmt > 0, "ZERO AMOUNT");
		require(realAmt <= aToken.balanceOf(address(this)), "INVALID AMOUNT");

		ILendingPool _lendingPool = ILendingPool(getLendingPoolAddress());
		_lendingPool.withdraw(erc20, realAmt, address(this));

		address registry = IWallet(address(this)).registry();
		uint256 fee = IRegistry(registry).getFee();

		if (fee > 0) {
			address feeRecipient = IRegistry(registry).feeRecipient();

			require(feeRecipient != address(0), "ZERO ADDRESS");

			IERC20(erc20).universalTransfer(
				feeRecipient,
				div(mul(realAmt, fee), 100000)
			);
		}

		_unstake(erc20, realAmt);

		// set amount of tokens received
		if (setValue) {
			setUint(IERC20(erc20).universalBalanceOf(address(this)));
		}

		emit LogRedeem(erc20, realAmt);
	}

	/**
	 * @dev Redeem MATIC/ERC20 and burn Aave Tokens
	 * @param erc20 Address of the underlying token to borrow
	 * @param tokenAmt Amount of underlying tokens to borrow
	 * @param getValue read value of tokenAmt from memory contract
	 * @param setValue set value of tokens borrowed in memory contract
	 */
	function borrow(
		address erc20,
		uint256 tokenAmt,
		bool getValue,
		bool setValue
	) external payable {
		address realToken = erc20 == getAddressETH() ? getWMATIC() : erc20;
		uint256 realAmt = getValue ? getUint() : tokenAmt;

		ILendingPool(getLendingPoolAddress()).borrow(
			realToken,
			realAmt,
			2,
			getReferralCode(),
			address(this)
		);

		// set amount of tokens received
		if (setValue) {
			setUint(realAmt);
		}

		emit LogBorrow(erc20, realAmt);
	}

	/**
	 * @dev Redeem MATIC/ERC20 and burn Aave Tokens
	 * @param erc20 Address of the underlying token to repay
	 * @param tokenAmt Amount of underlying tokens to repay
	 * @param getValue read value of tokenAmt from memory contract
	 * @param setValue set value of tokens repayed in memory contract
	 */
	function repay(
		address erc20,
		uint256 tokenAmt,
		bool getValue,
		bool setValue
	) external payable {
		address realToken = erc20;
		uint256 realAmt = getValue ? getUint() : tokenAmt;

		if (erc20 == getAddressETH()) {
			IWETH(getWMATIC()).deposit{value: realAmt}();
			realToken = getWMATIC();
		}

		IERC20(realToken).universalApprove(getLendingPoolAddress(), realAmt);

		ILendingPool(getLendingPoolAddress()).repay(
			realToken,
			realAmt,
			2,
			address(this)
		);

		// set amount of tokens received
		if (setValue) {
			setUint(realAmt);
		}

		emit LogPayback(erc20, realAmt);
	}
}

contract AaveLogic is AaveResolver {
	receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IMemory.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IWallet.sol";

contract Helpers {
	/**
	 * @dev Return Memory Variable Address
	 */
	function getMemoryAddr() public view returns (address) {
		return IRegistry(IWallet(address(this)).registry()).memoryAddr();
	}

	/**
	 * @dev Get Uint value from Memory Contract.
	 */
	function getUint() internal view returns (uint256) {
		return IMemory(getMemoryAddr()).getUint();
	}

	/**
	 * @dev Set Uint value in Memory Contract.
	 */
	function setUint(uint256 val) internal {
		IMemory(getMemoryAddr()).setUint(val);
	}

	/**
	 * @dev Get aToken address from Memory Contract.
	 */
	function getAToken(address asset) internal view returns (address) {
		return IMemory(getMemoryAddr()).getAToken(asset);
	}
}