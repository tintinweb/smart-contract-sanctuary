// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Minimal interface for Vault compatible strategies.
/// @dev Designed for out of the box compatibility with Fuse cTokens.
/// @dev Like cTokens, strategies must be transferrable ERC20s.
abstract contract Strategy {
	/// @notice Returns whether the strategy accepts ETH or an ERC20.
	/// @return True if the strategy accepts ETH, false otherwise.
	/// @dev Only present in Fuse cTokens, not Compound cTokens.
	function isCEther() external view virtual returns (bool);

	/// @notice Withdraws a specific amount of underlying tokens from the strategy.
	/// @param amount The amount of underlying tokens to withdraw.
	/// @return An error code, or 0 if the withdrawal was successful.
	function redeemUnderlying(uint256 amount) external virtual returns (uint256);

	/// @notice Returns a user's strategy balance in underlying tokens.
	/// @param user The user to get the underlying balance of.
	/// @return The user's strategy balance in underlying tokens.
	/// @dev May mutate the state of the strategy by accruing interest.
	function balanceOfUnderlying(address user) external virtual returns (uint256);

	/// @notice Returns max deposits a strategy can take.
	/// @return MaxTvl
	function getMaxTvl() external virtual returns (uint256);

	/// @notice Withdraws any ERC20 tokens back to recipient.
	function emergencyWithdraw(address recipient, IERC20[] memory tokens) external virtual;
}

/// @notice Minimal interface for Vault strategies that accept ERC20s.
/// @dev Designed for out of the box compatibility with Fuse cERC20s.
abstract contract ERC20Strategy is Strategy {
	/// @notice Returns the underlying ERC20 token the strategy accepts.
	/// @return The underlying ERC20 token the strategy accepts.
	function underlying() external view virtual returns (IERC20);

	/// @notice Deposit a specific amount of underlying tokens into the strategy.
	/// @param amount The amount of underlying tokens to deposit.
	/// @return An error code, or 0 if the deposit was successful.
	function mint(uint256 amount) external virtual returns (uint256);
}

/// @notice Minimal interface for Vault strategies that accept ETH.
/// @dev Designed for out of the box compatibility with Fuse cEther.
abstract contract ETHStrategy is Strategy {
	/// @notice Deposit a specific amount of ETH into the strategy.
	/// @dev The amount of ETH is specified via msg.value. Reverts on error.
	function mint() external payable virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IComptroller.sol";
import "./InterestRateModel.sol";

interface ICTokenStorage {
	/**
	 * @dev Container for borrow balance information
	 * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
	 * @member interestIndex Global borrowIndex as of the most recent balance-changing action
	 */
	struct BorrowSnapshot {
		uint256 principal;
		uint256 interestIndex;
	}
}

interface ICToken is ICTokenStorage {
	/*** Market Events ***/

	/**
	 * @dev Event emitted when interest is accrued
	 */
	event AccrueInterest(
		uint256 cashPrior,
		uint256 interestAccumulated,
		uint256 borrowIndex,
		uint256 totalBorrows
	);

	/**
	 * @dev Event emitted when tokens are minted
	 */
	event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

	/**
	 * @dev Event emitted when tokens are redeemed
	 */
	event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

	/**
	 * @dev Event emitted when underlying is borrowed
	 */
	event Borrow(
		address borrower,
		uint256 borrowAmount,
		uint256 accountBorrows,
		uint256 totalBorrows
	);

	/**
	 * @dev Event emitted when a borrow is repaid
	 */
	event RepayBorrow(
		address payer,
		address borrower,
		uint256 repayAmount,
		uint256 accountBorrows,
		uint256 totalBorrows
	);

	/**
	 * @dev Event emitted when a borrow is liquidated
	 */
	event LiquidateBorrow(
		address liquidator,
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral,
		uint256 seizeTokens
	);

	/*** Admin Events ***/

	/**
	 * @dev Event emitted when pendingAdmin is changed
	 */
	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

	/**
	 * @dev Event emitted when pendingAdmin is accepted, which means admin is updated
	 */
	event NewAdmin(address oldAdmin, address newAdmin);

	/**
	 * @dev Event emitted when comptroller is changed
	 */
	event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);

	/**
	 * @dev Event emitted when interestRateModel is changed
	 */
	event NewMarketInterestRateModel(
		InterestRateModel oldInterestRateModel,
		InterestRateModel newInterestRateModel
	);

	/**
	 * @dev Event emitted when the reserve factor is changed
	 */
	event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

	/**
	 * @dev Event emitted when the reserves are added
	 */
	event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

	/**
	 * @dev Event emitted when the reserves are reduced
	 */
	event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

	/**
	 * @dev EIP20 Transfer event
	 */
	event Transfer(address indexed from, address indexed to, uint256 amount);

	/**
	 * @dev EIP20 Approval event
	 */
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/**
	 * @dev Failure event
	 */
	event Failure(uint256 error, uint256 info, uint256 detail);

	/*** User Interface ***/
	function totalBorrows() external view returns (uint256);

	function totalReserves() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function transfer(address dst, uint256 amount) external returns (bool);

	function transferFrom(
		address src,
		address dst,
		uint256 amount
	) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function balanceOfUnderlying(address owner) external returns (uint256);

	function getAccountSnapshot(address account)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);

	function borrowRatePerBlock() external view returns (uint256);

	function supplyRatePerBlock() external view returns (uint256);

	function totalBorrowsCurrent() external returns (uint256);

	function borrowBalanceCurrent(address account) external returns (uint256);

	function borrowBalanceStored(address account) external view returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function exchangeRateStored() external view returns (uint256);

	function getCash() external view returns (uint256);

	function accrueInterest() external returns (uint256);

	function seize(
		address liquidator,
		address borrower,
		uint256 seizeTokens
	) external returns (uint256);

	/*** Admin Functions ***/

	function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

	function _acceptAdmin() external returns (uint256);

	function _setComptroller(IComptroller newComptroller) external returns (uint256);

	function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

	function _reduceReserves(uint256 reduceAmount) external returns (uint256);

	function _setInterestRateModel(InterestRateModel newInterestRateModel)
		external
		returns (uint256);
}

interface ICTokenErc20 is ICToken {
	/*** User Interface ***/

	function mint(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 redeemTokens) external returns (uint256);

	function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

	function borrow(uint256 borrowAmount) external returns (uint256);

	function repayBorrow(uint256 repayAmount) external returns (uint256);

	function liquidateBorrow(
		address borrower,
		uint256 repayAmount,
		ICToken cTokenCollateral
	) external returns (uint256);

	/*** Admin Functions ***/

	function _addReserves(uint256 addAmount) external returns (uint256);
}

interface ICTokenBase is ICToken {
	function repayBorrow() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICTokenInterfaces.sol";

interface ICompPriceOracle {
	function isPriceOracle() external view returns (bool);

	/**
	 * @notice Get the underlying price of a cToken asset
	 * @param cToken The cToken to get the underlying price of
	 * @return The underlying asset price mantissa (scaled by 1e18).
	 *  Zero means the price is unavailable.
	 */
	function getUnderlyingPrice(address cToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICTokenInterfaces.sol";

interface IComptroller {
	/*** Assets You Are In ***/

	function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

	function exitMarket(address cToken) external returns (uint256);

	/*** Policy Hooks ***/

	function mintAllowed(
		address cToken,
		address minter,
		uint256 mintAmount
	) external returns (uint256);

	function mintVerify(
		address cToken,
		address minter,
		uint256 mintAmount,
		uint256 mintTokens
	) external;

	function redeemAllowed(
		address cToken,
		address redeemer,
		uint256 redeemTokens
	) external returns (uint256);

	function redeemVerify(
		address cToken,
		address redeemer,
		uint256 redeemAmount,
		uint256 redeemTokens
	) external;

	function borrowAllowed(
		address cToken,
		address borrower,
		uint256 borrowAmount
	) external returns (uint256);

	function borrowVerify(
		address cToken,
		address borrower,
		uint256 borrowAmount
	) external;

	function repayBorrowAllowed(
		address cToken,
		address payer,
		address borrower,
		uint256 repayAmount
	) external returns (uint256);

	function repayBorrowVerify(
		address cToken,
		address payer,
		address borrower,
		uint256 repayAmount,
		uint256 borrowerIndex
	) external;

	function liquidateBorrowAllowed(
		address cTokenBorrowed,
		address cTokenCollateral,
		address liquidator,
		address borrower,
		uint256 repayAmount
	) external returns (uint256);

	function liquidateBorrowVerify(
		address cTokenBorrowed,
		address cTokenCollateral,
		address liquidator,
		address borrower,
		uint256 repayAmount,
		uint256 seizeTokens
	) external;

	function seizeAllowed(
		address cTokenCollateral,
		address cTokenBorrowed,
		address liquidator,
		address borrower,
		uint256 seizeTokens
	) external returns (uint256);

	function seizeVerify(
		address cTokenCollateral,
		address cTokenBorrowed,
		address liquidator,
		address borrower,
		uint256 seizeTokens
	) external;

	function transferAllowed(
		address cToken,
		address src,
		address dst,
		uint256 transferTokens
	) external returns (uint256);

	function transferVerify(
		address cToken,
		address src,
		address dst,
		uint256 transferTokens
	) external;

	function claimComp(address holder) external;

	function claimComp(address holder, ICTokenErc20[] memory cTokens) external;

	/*** Liquidity/Liquidation Calculations ***/

	function liquidateCalculateSeizeTokens(
		address cTokenBorrowed,
		address cTokenCollateral,
		uint256 repayAmount
	) external view returns (uint256, uint256);
}

interface UnitrollerAdminStorage {
	/**
	 * @notice Administrator for this contract
	 */
	// address external admin;
	function admin() external view returns (address);

	/**
	 * @notice Pending administrator for this contract
	 */
	// address external pendingAdmin;
	function pendingAdmin() external view returns (address);

	/**
	 * @notice Active brains of Unitroller
	 */
	// address external comptrollerImplementation;
	function comptrollerImplementation() external view returns (address);

	/**
	 * @notice Pending brains of Unitroller
	 */
	// address external pendingComptrollerImplementation;
	function pendingComptrollerImplementation() external view returns (address);
}

interface ComptrollerV1Storage is UnitrollerAdminStorage {
	/**
	 * @notice Oracle which gives the price of any given asset
	 */
	// PriceOracle external oracle;
	function oracle() external view returns (address);

	/**
	 * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
	 */
	// uint external closeFactorMantissa;
	function closeFactorMantissa() external view returns (uint256);

	/**
	 * @notice Multiplier representing the discount on collateral that a liquidator receives
	 */
	// uint external liquidationIncentiveMantissa;
	function liquidationIncentiveMantissa() external view returns (uint256);

	/**
	 * @notice Max number of assets a single account can participate in (borrow or use as collateral)
	 */
	// uint external maxAssets;
	function maxAssets() external view returns (uint256);

	/**
	 * @notice Per-account mapping of "assets you are in", capped by maxAssets
	 */
	// mapping(address => CToken[]) external accountAssets;
	// function accountAssets(address) external view returns (CToken[]);
}

abstract contract ComptrollerV2Storage is ComptrollerV1Storage {
	enum Version {
		VANILLA,
		COLLATERALCAP,
		WRAPPEDNATIVE
	}

	struct Market {
		bool isListed;
		uint256 collateralFactorMantissa;
		mapping(address => bool) accountMembership;
		bool isComped;
		// Version version;
	}

	/**
	 * @notice Official mapping of cTokens -> Market metadata
	 * @dev Used e.g. to determine if a market is supported
	 */
	mapping(address => Market) public markets;

	/**
	 * @notice The Pause Guardian can pause certain actions as a safety mechanism.
	 *  Actions which allow users to remove their own assets cannot be paused.
	 *  Liquidation / seizing / transfer can only be paused globally, not by market.
	 */
	// address external pauseGuardian;
	// bool external _mintGuardianPaused;
	// bool external _borrowGuardianPaused;
	// bool external transferGuardianPaused;
	// bool external seizeGuardianPaused;
	// mapping(address => bool) external mintGuardianPaused;
	// mapping(address => bool) external borrowGuardianPaused;
}

abstract contract ComptrollerV3Storage is ComptrollerV2Storage {
	// struct CompMarketState {
	//     /// @notice The market's last updated compBorrowIndex or compSupplyIndex
	//     uint224 index;
	//     /// @notice The block number the index was last updated at
	//     uint32 block;
	// }
	// /// @notice A list of all markets
	// CToken[] external allMarkets;
	// /// @notice The rate at which the flywheel distributes COMP, per block
	// uint external compRate;
	// /// @notice The portion of compRate that each market currently receives
	// mapping(address => uint) external compSpeeds;
	// /// @notice The COMP market supply state for each market
	// mapping(address => CompMarketState) external compSupplyState;
	// /// @notice The COMP market borrow state for each market
	// mapping(address => CompMarketState) external compBorrowState;
	// /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
	// mapping(address => mapping(address => uint)) external compSupplierIndex;
	// /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
	// mapping(address => mapping(address => uint)) external compBorrowerIndex;
	// /// @notice The COMP accrued but not yet transferred to each user
	// mapping(address => uint) external compAccrued;
}

abstract contract ComptrollerV4Storage is ComptrollerV3Storage {
	// @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
	// address external borrowCapGuardian;
	function borrowCapGuardian() external view virtual returns (address);

	// @notice Borrow caps enforced by borrowAllowed for each cToken address. Defaults to zero which corresponds to unlimited borrowing.
	// mapping(address => uint) external borrowCaps;
	function borrowCaps(address) external view virtual returns (uint256);
}

abstract contract ComptrollerV5Storage is ComptrollerV4Storage {
	// @notice The supplyCapGuardian can set supplyCaps to any number for any market. Lowering the supply cap could disable supplying to the given market.
	// address external supplyCapGuardian;
	function supplyCapGuardian() external view virtual returns (address);

	// @notice Supply caps enforced by mintAllowed for each cToken address. Defaults to zero which corresponds to unlimited supplying.
	// mapping(address => uint) external supplyCaps;
	function supplyCaps(address) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {
	/**
	 * @dev Calculates the current borrow interest rate per block
	 * @param cash The total amount of cash the market has
	 * @param borrows The total amount of borrows the market has outstanding
	 * @param reserves The total amnount of reserves the market has
	 * @return The borrow rate per block (as a percentage, and scaled by 1e18)
	 */
	function getBorrowRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves
	) external view returns (uint256);

	/**
	 * @dev Calculates the current supply interest rate per block
	 * @param cash The total amount of cash the market has
	 * @param borrows The total amount of borrows the market has outstanding
	 * @param reserves The total amnount of reserves the market has
	 * @param reserveFactorMantissa The current reserve factor the market has
	 * @return The supply rate per block (as a percentage, and scaled by 1e18)
	 */
	function getSupplyRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves,
		uint256 reserveFactorMantissa
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IClaimReward {
	function claimReward(uint8 rewardType, address payable holder) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingRewards is IERC20 {
	function stakingToken() external view returns (address);

	function lastTimeRewardApplicable() external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function earned(address account) external view returns (uint256);

	function getRewardForDuration() external view returns (uint256);

	function stakeWithPermit(
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function getReward() external;

	function exit() external;
}

// some farms use sushi interface
interface IMasterChef {
	// depositing 0 amount will withdraw the rewards (harvest)
	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;

	function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

	function emergencyWithdraw(uint256 _pid) external;

	function pendingTokens(uint256 _pid, address _user)
		external
		view
		returns (
			uint256,
			address,
			string memory,
			uint256
		);
}

interface IMiniChefV2 {
	struct UserInfo {
		uint256 amount;
		int256 rewardDebt;
	}

	struct PoolInfo {
		uint128 accSushiPerShare;
		uint64 lastRewardTime;
		uint64 allocPoint;
	}

	function poolLength() external view returns (uint256);

	function updatePool(uint256 pid) external returns (IMiniChefV2.PoolInfo memory);

	function userInfo(uint256 _pid, address _user) external view returns (uint256, int256);

	function deposit(
		uint256 pid,
		uint256 amount,
		address to
	) external;

	function withdraw(
		uint256 pid,
		uint256 amount,
		address to
	) external;

	function harvest(uint256 pid, address to) external;

	function withdrawAndHarvest(
		uint256 pid,
		uint256 amount,
		address to
	) external;

	function emergencyWithdraw(uint256 pid, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
	function deposit() external payable;

	function transfer(address to, uint256 value) external returns (bool);

	function withdraw(uint256) external;

	function balanceOf(address) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

library SafeETH {
	function safeTransferETH(address to, uint256 amount) internal {
		bool callStatus;

		assembly {
			// Transfer the ETH and store if it succeeded or not.
			callStatus := call(gas(), to, amount, 0, 0, 0, 0)
		}

		require(callStatus, "ETH_TRANSFER_FAILED");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/uniswap/IUniswapV2Router01.sol";
import "../interfaces/uniswap/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library UniUtils {
	using SafeERC20 for IERC20;

	function _getPairTokens(IUniswapV2Pair pair) internal view returns (address, address) {
		return (pair.token0(), pair.token1());
	}

	function _getPairReserves(
		IUniswapV2Pair pair,
		address tokenA,
		address tokenB
	) internal view returns (uint256 reserveA, uint256 reserveB) {
		(address token0, ) = _sortTokens(tokenA, tokenB);
		(uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
		(reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// given some amount of an asset and lp reserves, returns an equivalent amount of the other asset
	function _quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) internal pure returns (uint256 amountB) {
		require(amountA > 0, "UniUtils: INSUFFICIENT_AMOUNT");
		require(reserveA > 0 && reserveB > 0, "UniUtils: INSUFFICIENT_LIQUIDITY");
		amountB = (amountA * reserveB) / reserveA;
	}

	function _sortTokens(address tokenA, address tokenB)
		internal
		pure
		returns (address token0, address token1)
	{
		require(tokenA != tokenB, "UniUtils: IDENTICAL_ADDRESSES");
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), "UniUtils: ZERO_ADDRESS");
	}

	function _getAmountOut(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal view returns (uint256 amountOut) {
		require(amountIn > 0, "UniUtils: INSUFFICIENT_INPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = reserveIn * 1000 + amountInWithFee;
		amountOut = numerator / denominator;
	}

	function _getAmountIn(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal view returns (uint256 amountIn) {
		require(amountOut > 0, "UniUtils: INSUFFICIENT_OUTPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		amountIn = (numerator / denominator) + 1;
	}

	function _swapExactTokensForTokens(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal returns (uint256) {
		uint256 amountOut = _getAmountOut(pair, amountIn, inToken, outToken);
		(address token0, ) = _sortTokens(outToken, inToken);
		(uint256 amount0Out, uint256 amount1Out) = inToken == token0
			? (uint256(0), amountOut)
			: (amountOut, uint256(0));

		IERC20(inToken).safeTransfer(address(pair), amountIn);
		pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
		return amountOut;
	}

	function _swapTokensForExactTokens(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal returns (uint256) {
		uint256 amountIn = _getAmountIn(pair, amountOut, inToken, outToken);
		(address token0, ) = _sortTokens(outToken, inToken);
		(uint256 amount0Out, uint256 amount1Out) = inToken == token0
			? (uint256(0), amountOut)
			: (amountOut, uint256(0));

		IERC20(inToken).safeTransfer(address(pair), amountIn);
		pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
		return amountIn;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct Config {
	address underlying;
	address short;
	address cTokenLend;
	address cTokenBorrow;
	address uniPair;
	address uniFarm;
	address farmToken;
	uint256 farmId;
	address farmRouter;
	address comptroller;
	address lendRewardRouter;
	address lendRewardToken;
	address vault;
	string symbol;
	string name;
	uint256 maxTvl;
}

// all interfaces need to inherit from base
abstract contract IBase {
	bool public isIntialized;

	modifier initializer() {
		require(isIntialized == false, "INITIALIZED");
		_;
	}

	function short() public view virtual returns (IERC20);

	function underlying() public view virtual returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/compound/ICTokenInterfaces.sol";
import "../interfaces/compound/IComptroller.sol";
import "../interfaces/compound/ICompPriceOracle.sol";
import "../interfaces/compound/IComptroller.sol";

import "../interfaces/uniswap/IWETH.sol";

import "./ILending.sol";
import "./IBase.sol";

// import "hardhat/console.sol";

abstract contract ICompound is ILending {
	using SafeERC20 for IERC20;

	function cTokenLend() public view virtual returns (ICTokenErc20);

	function cTokenBorrow() public view virtual returns (ICTokenErc20);

	function oracle() public view virtual returns (ICompPriceOracle);

	function comptroller() public view virtual returns (IComptroller);

	function _enterMarket() internal {
		address[] memory cTokens = new address[](2);
		cTokens[0] = address(cTokenLend());
		cTokens[1] = address(cTokenBorrow());
		comptroller().enterMarkets(cTokens);
	}

	function _getCollateralFactor() internal view override returns (uint256) {
		(, uint256 collateralFactorMantissa, ) = ComptrollerV2Storage(address(comptroller()))
			.markets(address(cTokenLend()));
		return collateralFactorMantissa;
	}

	// TODO handle error
	function _redeem(uint256 amount) internal override {
		uint256 err = cTokenLend().redeemUnderlying(amount);
		// require(err == 0, "Compund: error redeeming underlying");
	}

	function _borrow(uint256 amount) internal override {
		cTokenBorrow().borrow(amount);

		// in case we need to wrap the tokens
		if (_isBase(1)) IWETH(address(short())).deposit{ value: amount }();
	}

	function _lend(uint256 amount) internal override {
		cTokenLend().mint(amount);
	}

	function _repay(uint256 amount) internal override {
		if (_isBase(1)) {
			// need to convert to base first
			IWETH(address(short())).withdraw(amount);

			// then repay in the base
			_repayBase(amount);
			return;
		}
		cTokenBorrow().repayBorrow(amount);
	}

	function _repayBase(uint256 amount) internal {
		ICTokenBase(address(cTokenBorrow())).repayBorrow{ value: amount }();
	}

	function _updateAndGetCollateralBalance() internal override returns (uint256) {
		return cTokenLend().balanceOfUnderlying(address(this));
	}

	function _getCollateralBalance() internal view override returns (uint256) {
		uint256 b = cTokenLend().balanceOf(address(this));
		return (b * cTokenLend().exchangeRateStored()) / 1e18;
	}

	function _updateAndGetBorrowBalance() internal override returns (uint256) {
		return cTokenBorrow().borrowBalanceCurrent(address(this));
	}

	function _getBorrowBalance() internal view override returns (uint256 shortBorrow) {
		shortBorrow = cTokenBorrow().borrowBalanceStored(address(this));
	}

	function _oraclePriceOfShort(uint256 amount) internal view override returns (uint256) {
		return
			(amount * oracle().getUnderlyingPrice(address(cTokenBorrow()))) /
			oracle().getUnderlyingPrice(address(cTokenLend()));
	}

	function _oraclePriceOfUnderlying(uint256 amount) internal view override returns (uint256) {
		return
			(amount * oracle().getUnderlyingPrice(address(cTokenLend()))) /
			oracle().getUnderlyingPrice(address(cTokenBorrow()));
	}

	function _maxBorrow() internal view virtual override returns (uint256) {
		return cTokenBorrow().getCash();
	}

	// returns true if either of the CTokens is cEth
	// index 0 = cTokenLend index 1 = cTokenBorrow
	function _isBase(uint8 index) internal virtual returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/uniswap/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IBase.sol";

struct HarvestSwapParms {
	address[] path; //path that the token takes
	uint256 min; // min price of in token * 1e18 (computed externally based on spot * slippage + fees)
	uint256 deadline;
}

abstract contract IFarmable is IBase {
	using SafeERC20 for IERC20;

	event HarvestedToken(address indexed token, uint256 amount);

	function _swap(
		IUniswapV2Router01 router,
		HarvestSwapParms calldata swapParams,
		address from,
		uint256 amount
	) internal {
		address out = swapParams.path[swapParams.path.length - 1];
		// ensure malicious harvester is not trading with wrong tokens
		// TODO should we limit path length to 2 to prevent malicious path?
		require(
			((swapParams.path[0] == address(from) && (out == address(short()))) ||
				out == address(underlying())),
			"IFarmable: WRONG_PATH"
		);
		router.swapExactTokensForTokens(
			amount,
			swapParams.min,
			swapParams.path, // optimal route determined externally
			address(this),
			swapParams.deadline
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IFarmable.sol";

abstract contract IFarmableLp is IFarmable {
	function _depositIntoFarm(uint256 amount) internal virtual;

	function _withdrawFromFarm(uint256 amount) internal virtual;

	function _harvestFarm(HarvestSwapParms[] calldata swapParams)
		internal
		virtual
		returns (uint256[] memory);

	function _getFarmLp() internal view virtual returns (uint256);

	function _addFarmApprovals() internal virtual;

	function farmRouter() public view virtual returns (IUniswapV2Router01);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBase.sol";
import "./IFarmable.sol";

// import "hardhat/console.sol";

abstract contract ILending is IBase {
	function _addLendingApprovals() internal virtual;

	function _getCollateralBalance() internal view virtual returns (uint256);

	function _getBorrowBalance() internal view virtual returns (uint256);

	function _updateAndGetCollateralBalance() internal virtual returns (uint256);

	function _updateAndGetBorrowBalance() internal virtual returns (uint256);

	function _getCollateralFactor() internal view virtual returns (uint256);

	function safeCollateralRatio() public view virtual returns (uint256);

	function _oraclePriceOfShort(uint256 amount) internal view virtual returns (uint256);

	function _oraclePriceOfUnderlying(uint256 amount) internal view virtual returns (uint256);

	function _lend(uint256 amount) internal virtual;

	function _redeem(uint256 amount) internal virtual;

	function _borrow(uint256 amount) internal virtual;

	function _repay(uint256 amount) internal virtual;

	function _harvestLending(HarvestSwapParms[] calldata swapParams)
		internal
		virtual
		returns (uint256[] memory);

	function lendFarmRouter() public view virtual returns (IUniswapV2Router01);

	function getCollateralRatio() public view virtual returns (uint256) {
		return (_getCollateralFactor() * safeCollateralRatio()) / 1e18;
	}

	// returns loan health value which is collateralBalance / minCollateral
	function loanHealth() public view returns (uint256) {
		uint256 borrowValue = _oraclePriceOfShort(_getBorrowBalance());
		if (borrowValue == 0) return 10000;
		uint256 collateralBalance = _getCollateralBalance();
		uint256 minCollateral = (borrowValue * 1e18) / _getCollateralFactor();
		return (1e18 * collateralBalance) / minCollateral;
	}

	function _adjustCollateral(uint256 targetCollateral)
		internal
		returns (uint256 added, uint256 removed)
	{
		uint256 collateralBalance = _getCollateralBalance();
		if (collateralBalance == targetCollateral) return (0, 0);
		(added, removed) = collateralBalance > targetCollateral
			? (uint256(0), _removeCollateral(collateralBalance - targetCollateral))
			: (_addCollateral(targetCollateral - collateralBalance), uint256(0));
	}

	function _removeCollateral(uint256 amountToRemove) internal returns (uint256 removed) {
		uint256 maxRemove = _freeCollateral();
		removed = maxRemove > amountToRemove ? amountToRemove : maxRemove;
		if (removed > 0) _redeem(removed);
	}

	function _freeCollateral() internal view returns (uint256) {
		uint256 collateral = _getCollateralBalance();
		uint256 borrowValue = _oraclePriceOfShort(_getBorrowBalance());
		// stay within 1% of the liquidation threshold (this is allways temporary)
		uint256 minCollateral = (100 * (borrowValue * 1e18)) / _getCollateralFactor() / 99;
		if (minCollateral > collateral) return 0;
		return collateral - minCollateral;
	}

	function _addCollateral(uint256 amountToAdd) internal returns (uint256 added) {
		uint256 underlyingBalance = underlying().balanceOf(address(this));
		added = underlyingBalance > amountToAdd ? amountToAdd : underlyingBalance;
		if (added != 0) _lend(added);
	}

	function _maxBorrow() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ILp {
	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view virtual returns (uint256 price);

	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		virtual
		returns (uint256 liquidity);

	function _removeLiquidity(uint256 liquidity) internal virtual returns (uint256, uint256);

	function _getLPBalances()
		internal
		view
		virtual
		returns (uint256 underlyingBalance, uint256 shortBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../libraries/UniUtils.sol";

import "./IBase.sol";
import "./ILp.sol";

// import "hardhat/console.sol";

abstract contract IUniLp is IBase, ILp {
	using SafeERC20 for IERC20;
	using UniUtils for IUniswapV2Pair;

	function pair() public view virtual returns (IUniswapV2Pair);

	function _getLiquidity() internal view virtual returns (uint256);

	// should only be called after oracle or user-input swap price check
	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		override
		returns (uint256 liquidity)
	{
		underlying().safeTransfer(address(pair()), amountToken0);
		short().safeTransfer(address(pair()), amountToken1);
		liquidity = pair().mint(address(this));
	}

	function _removeLiquidity(uint256 liquidity) internal override returns (uint256, uint256) {
		IERC20(address(pair())).safeTransfer(address(pair()), liquidity);
		(address tokenA, ) = UniUtils._sortTokens(address(underlying()), address(short()));
		(uint256 amountToken0, uint256 amountToken1) = pair().burn(address(this));
		return
			tokenA == address(underlying())
				? (amountToken0, amountToken1)
				: (amountToken1, amountToken0);
	}

	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view virtual override returns (uint256 price) {
		if (amount == 0) return 0;
		(uint256 reserve0, uint256 reserve1) = pair()._getPairReserves(token0, token1);
		price = UniUtils._quote(amount, reserve0, reserve1);
	}

	// fetches and sorts the reserves for a uniswap pair
	function getUnderlyingShortReserves() public view returns (uint256 reserveA, uint256 reserveB) {
		(reserveA, reserveB) = pair()._getPairReserves(address(underlying()), address(short()));
	}

	function _getLPBalances()
		internal
		view
		override
		returns (uint256 underlyingBalance, uint256 shortBalance)
	{
		uint256 totalLp = _getLiquidity();
		(uint256 totalUnderlyingBalance, uint256 totalShortBalance) = getUnderlyingShortReserves();
		uint256 total = pair().totalSupply();
		underlyingBalance = (totalUnderlyingBalance * totalLp) / total;
		shortBalance = (totalShortBalance * totalLp) / total;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/Strategy.sol";
import "../libraries/SafeETH.sol";

// import "hardhat/console.sol";

abstract contract BaseStrategy is Strategy, Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	modifier onlyVault() {
		require(msg.sender == vault(), "Strat: ONLY_VAULT");
		_;
	}

	modifier onlyAuth() {
		require(msg.sender == owner() || _managers[msg.sender] == true, "Strat: NO_AUTH");
		_;
	}

	bool isInitialized;

	uint256 constant BPS_ADJUST = 10000;
	uint256 public lastHarvest; // block.timestamp;
	address private _vault;
	uint256 private _shares;

	string public name;
	string public symbol;

	mapping(address => bool) private _managers;

	uint256 public BASE_UNIT; // 10 ** decimals

	event Harvest(uint256 harvested); // this is actual the tvl before harvest
	event Deposit(address sender, uint256 amount);
	event Withdraw(address sender, uint256 amount);
	event Rebalance(uint256 shortPrice, uint256 tvlBeforeRebalance, uint256 positionOffset);
	event EmergencyWithdraw(address indexed recipient, IERC20[] tokens);
	event ManagerUpdate(address indexed account, bool isManager);
	event VaultUpdate(address indexed vault);

	constructor(
		address vault_,
		string memory symbol_,
		string memory name_
	) Ownable() ReentrancyGuard() {
		_vault = vault_;
		symbol = symbol_;
		name = name_;
	}

	// VIEW
	function vault() public view returns (address) {
		return _vault;
	}

	function totalSupply() public view returns (uint256) {
		return _shares;
	}

	/**
	 * @notice
	 *  Returns the share price of the strategy in `underlying` units, multiplied
	 *  by 1e18
	 */
	function getPricePerShare() public view returns (uint256) {
		uint256 bal = balanceOfUnderlying();
		if (_shares == 0) return BASE_UNIT;
		return (bal * BASE_UNIT) / _shares;
	}

	function balanceOfUnderlying(address) public view virtual override returns (uint256) {
		return balanceOfUnderlying();
	}

	function balanceOfUnderlying() public view virtual returns (uint256);

	// PUBLIC METHODS
	function mint(uint256 amount) external onlyVault returns (uint256 errCode) {
		uint256 newShares = _deposit(amount);
		_shares += newShares;
		errCode = 0;
	}

	function redeemUnderlying(uint256 amount)
		external
		override
		onlyVault
		returns (uint256 errCode)
	{
		uint256 burnShares = _withdraw(amount);
		_shares -= burnShares;
		errCode = 0;
	}

	// GOVERNANCE - MANAGER
	function isManager(address user) public view returns (bool) {
		return _managers[user];
	}

	function setManager(address user, bool _isManager) external onlyOwner {
		_managers[user] = _isManager;
		emit ManagerUpdate(user, _isManager);
	}

	function setVault(address vault_) external onlyOwner {
		_vault = vault_;
		emit VaultUpdate(vault_);
	}

	// emergency only
	// closePosition should be attempted first, if after some tokens are stuck,
	// send them to a designated address
	function emergencyWithdraw(address recipient, IERC20[] calldata tokens)
		external
		override
		onlyVault
	{
		for (uint256 i = 0; i < tokens.length; i++) {
			IERC20 token = tokens[i];
			uint256 balance = token.balanceOf(address(this));
			if (balance != 0) token.safeTransfer(recipient, balance);
		}
		if (address(this).balance > 0) SafeETH.safeTransferETH(msg.sender, address(this).balance);
		emit EmergencyWithdraw(recipient, tokens);
	}

	function _deposit(uint256 amount) internal virtual returns (uint256 newShares);

	function _withdraw(uint256 amount) internal virtual returns (uint256 burnShares);

	function isCEther() public pure override returns (bool) {
		return false;
	}

	receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../mixins/IBase.sol";
import "../mixins/ILending.sol";
import "../mixins/IFarmableLp.sol";
import "../mixins/IUniLp.sol";
import "./BaseStrategy.sol";
import "../interfaces/uniswap/IWETH.sol";

// import "hardhat/console.sol";

// @custom: alphabetize dependencies to avoid linearization conflicts
abstract contract HedgedLP is IBase, BaseStrategy, ILending, IFarmableLp, IUniLp {
	using UniUtils for IUniswapV2Pair;
	using SafeERC20 for IERC20;

	event RebalanceLoan(address indexed sender, uint256 startLoanHealth, uint256 updatedLoanHealth);
	event setMinLoanHealth(uint256 loanHealth);
	event SetMaxPriceMismatch(uint256 loanHealth);
	event SetRebalanceThreshold(uint256 loanHealth);
	event SetMaxTvl(uint256 loanHealth);
	event SetSafeCollateralRaio(uint256 collateralRatio);

	uint256 constant MINIMUM_LIQUIDITY = 1000;

	IERC20 private _underlying;
	IERC20 private _short;

	uint256 public maxPriceMismatch = 150; // 1.5%
	uint256 constant maxAllowedMismatch = 300; // manager cannot make price mismatch more than 3%
	uint256 public minLoanHealth = 1.04e18; // how close to liquidation we get

	uint16 public rebalanceThreshold = 400; // 4% of lp

	uint256 private _maxTvl;
	uint256 private _safeCollateralRatio = 8400; // 84% (90% is possible but not safe)

	// for security we update this value only after oracle price checks in 'getAndUpdateTvl'
	uint256 private _cachedBalanceOfUnderlying;
	uint256 public constant version = 1;

	modifier checkPrice(uint256 maxSlippage) {
		if (maxSlippage == 0) maxSlippage = maxPriceMismatch;
		require(getPriceOffset() <= maxSlippage, "HLP: PRICE_MISMATCH");
		_;
		// any method that uses checkPrice should updated the _cachedBalanceOfUnderlying
		(_cachedBalanceOfUnderlying, , , , , ) = getTVL();
	}

	function __HedgedLP_init_(
		address underlying_,
		address short_,
		uint256 maxTvl_
	) internal initializer {
		_underlying = IERC20(underlying_);
		_short = IERC20(short_);

		_underlying.safeApprove(address(this), type(uint256).max);

		BASE_UNIT = 10**decimals();

		// init params
		setMaxTvl(maxTvl_);

		// emit default settings events
		emit setMinLoanHealth(minLoanHealth);
		emit SetMaxPriceMismatch(maxPriceMismatch);
		emit SetRebalanceThreshold(rebalanceThreshold);
		emit SetSafeCollateralRaio(_safeCollateralRatio);

		// TODO should we add a revoke aprovals methods?
		_addLendingApprovals();
		_addFarmApprovals();

		isInitialized = true;
	}

	function safeCollateralRatio() public view override returns (uint256) {
		return _safeCollateralRatio;
	}

	function setSafeCollateralRatio(uint256 safeCollateralRatio_) public onlyOwner {
		_safeCollateralRatio = safeCollateralRatio_;
		emit SetSafeCollateralRaio(safeCollateralRatio_);
	}

	function decimals() public view returns (uint8) {
		return IERC20Metadata(address(_underlying)).decimals();
	}

	// OWNER CONFIG
	function setMinLoanHeath(uint256 minLoanHealth_) public onlyOwner {
		minLoanHealth = minLoanHealth_;
		emit setMinLoanHealth(minLoanHealth_);
	}

	// manager can adjust max price if needed
	function setMaxPriceMismatch(uint256 maxPriceMismatch_) public onlyAuth {
		require(msg.sender == owner() || maxAllowedMismatch >= maxPriceMismatch_, "HLP: TOO LARGE");
		maxPriceMismatch = maxPriceMismatch_;
		emit SetMaxPriceMismatch(maxPriceMismatch_);
	}

	function setRebalanceThreshold(uint16 rebalanceThreshold_) public onlyOwner {
		rebalanceThreshold = rebalanceThreshold_;
		emit SetRebalanceThreshold(rebalanceThreshold_);
	}

	function setMaxTvl(uint256 maxTvl_) public onlyAuth {
		_maxTvl = maxTvl_;
		emit SetMaxTvl(maxTvl_);
	}

	// PUBLIC METHODS

	function short() public view override returns (IERC20) {
		return _short;
	}

	function underlying() public view override returns (IERC20) {
		return _underlying;
	}

	// public method that anyone can call to prevent an immenent loan liquidation
	// this is an emergency measure in case rebalance() is not called in time
	// price check is not necessary here because we are only removing LP and
	// if swap price differs it is to our benefit
	function rebalanceLoan() public nonReentrant {
		uint256 _loanHealth = loanHealth();
		require(_loanHealth <= minLoanHealth, "HLP: SAFE");
		(uint256 underlyingLp, ) = _getLPBalances();

		// remove 5% of LP to repay loan & add collateral
		uint256 newLP = (9500 * _loanHealth * underlyingLp) / 10000 / minLoanHealth;

		// remove lp
		(uint256 underlyingBalance, uint256 shortBalance) = _decreaseLpTo(newLP);

		_repay(shortBalance);
		_lend(underlyingBalance);
		emit RebalanceLoan(msg.sender, _loanHealth, loanHealth());
	}

	function _deposit(uint256 amount)
		internal
		override
		checkPrice(0)
		nonReentrant
		returns (uint256 newShares)
	{
		if (amount <= 0) return 0; // cannot deposit 0
		uint256 tvl = _getAndUpdateTVL();
		require(amount + tvl <= getMaxTvl(), "HLP: OVER_MAX_TVL");
		newShares = totalSupply() == 0 ? amount : (totalSupply() * amount) / tvl;
		_underlying.transferFrom(vault(), address(this), amount);
		_increasePosition(amount);
		emit Deposit(msg.sender, amount);
	}

	// can pass type(uint256).max to withdraw full amount
	function _withdraw(uint256 amount)
		internal
		override
		checkPrice(0)
		nonReentrant
		returns (uint256 burnShares)
	{
		if (amount == 0) return 0;
		uint256 tvl = _getAndUpdateTVL();
		if (tvl == 0) return 0;

		uint256 reserves = _underlying.balanceOf(address(this));

		// if we can not withdraw straight out of reserves
		if (reserves < amount) {
			// add .5% to withdraw amount for tx fees & slippage etc
			uint256 withdrawAmnt = amount == type(uint256).max
				? tvl
				: min(tvl, (amount * 1005) / 1000);

			// decrease current position
			withdrawAmnt = withdrawAmnt >= tvl
				? _closePosition()
				: _decreasePosition(withdrawAmnt - reserves) + reserves;

			// use the minimum of the two
			amount = min(withdrawAmnt, amount);
		}
		// grab current tvl to account for fees and slippage
		(tvl, , , , , ) = getTVL();

		// round up to keep price precision and leave less dust
		burnShares = min(((amount + 1) * totalSupply()) / tvl, totalSupply());

		_underlying.safeTransferFrom(address(this), vault(), amount);
		// require(tvl > 0, "no funds in vault");
		emit Withdraw(msg.sender, amount);
	}

	// decreases position based on current desired balance
	// ** does not rebalance remaining portfolio
	// ** may return slighly less then desired amount
	// ** make sure to update lending positions before calling this
	function _decreasePosition(uint256 amount) internal returns (uint256) {
		uint256 removeLpAmnt = _totalToLp(amount);
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 shortPosition = _getBorrowBalance();
		uint256 removeShortLp = _underlyingToShort(removeLpAmnt);

		if (removeLpAmnt >= underlyingLp || removeShortLp >= shortPosition) return _closePosition();

		// remove lp
		(uint256 availableUnderlying, uint256 shortBalance) = _decreaseLpTo(
			underlyingLp - removeLpAmnt
		);

		_repay(shortBalance);

		// this might remove less collateral than desired if we hit the limit
		// this happens when position is close to empty
		availableUnderlying += _removeCollateral(amount - availableUnderlying);
		return availableUnderlying;
	}

	// increases the position based on current desired balance
	// ** does not rebalance remaining portfolio
	function _increasePosition(uint256 amount) internal {
		if (amount < MINIMUM_LIQUIDITY) return; // avoid imprecision
		uint256 amntUnderlying = _totalToLp(amount);
		uint256 amntShort = _underlyingToShort(amntUnderlying);
		_lend(amount - amntUnderlying);
		_borrow(amntShort);
		uint256 liquidity = _addLiquidity(amntUnderlying, amntShort);
		_depositIntoFarm(liquidity);
	}

	// use the return of the function to estimate pending harvest via staticCall
	function harvest(
		HarvestSwapParms[] calldata uniParams,
		HarvestSwapParms[] calldata lendingParams
	)
		external
		onlyAuth
		checkPrice(0)
		nonReentrant
		returns (uint256[] memory farmHarvest, uint256[] memory lendHarvest)
	{
		(uint256 startTvl, , , , , ) = getTVL();
		if (uniParams.length != 0) farmHarvest = _harvestFarm(uniParams);
		if (lendingParams.length != 0) lendHarvest = _harvestLending(lendingParams);

		// compound our lp position disreguarding the borrowTarget param
		_increaseLpPosition(type(uint256).max);
		emit Harvest(startTvl);
	}

	// MANAGER + OWNER METHODS
	// Backwards compatability
	function rebalance() external pure {
		require(false, "MUST_USE_SLIPPAGE");
	}

	function rebalance(uint256 maxSlippage) external onlyAuth checkPrice(maxSlippage) nonReentrant {
		// call this first to ensure we use an updated borrowBalance when computing offset
		uint256 tvl = _getAndUpdateTVL();
		uint256 positionOffset = getPositionOffset();

		// don't rebalance unless we exceeded the threshold
		require(positionOffset > rebalanceThreshold, "HLP: REB-THRESH"); // maybe next time...

		if (tvl == 0) return;
		uint256 targetUnderlyingLP = _totalToLp(tvl);

		// add .1% room for fees
		_rebalancePosition((targetUnderlyingLP * 999) / 1000, tvl - targetUnderlyingLP);
		emit Rebalance(_shortToUnderlying(1e18), positionOffset, tvl);
	}

	function closePosition(uint256 maxSlippage) public checkPrice(maxSlippage) onlyAuth {
		_closePosition();
	}

	function _closePosition() internal returns (uint256) {
		_decreaseLpTo(0);
		uint256 shortPosition = _updateAndGetBorrowBalance();
		uint256 shortBalance = _short.balanceOf(address(this));
		if (shortPosition > shortBalance) {
			pair()._swapTokensForExactTokens(
				shortPosition - shortBalance,
				address(_underlying),
				address(_short)
			);
		} else if (shortBalance > shortPosition) {
			pair()._swapExactTokensForTokens(
				shortBalance - shortPosition,
				address(_short),
				address(_underlying)
			);
		}
		_repay(_short.balanceOf(address(this)));
		uint256 collateralBalance = _updateAndGetCollateralBalance();
		_redeem(collateralBalance);
		return _underlying.balanceOf(address(this));
	}

	function _decreaseLpTo(uint256 targetUnderlyingLP)
		internal
		returns (uint256 underlyingRemove, uint256 shortRemove)
	{
		(uint256 underlyingLp, ) = _getLPBalances();
		if (targetUnderlyingLP >= underlyingLp) return (0, 0); // nothing to withdraw
		uint256 liquidity = _getLiquidity();
		uint256 targetLiquidity = (liquidity * targetUnderlyingLP) / underlyingLp;
		uint256 removeLp = liquidity - targetLiquidity;
		uint256 liquidityBalance = pair().balanceOf(address(this));
		if (removeLp > liquidityBalance) _withdrawFromFarm(removeLp - liquidityBalance);
		return removeLp == 0 ? (0, 0) : _removeLiquidity(removeLp);
	}

	function _rebalancePosition(uint256 targetUnderlyingLP, uint256 targetCollateral) internal {
		uint256 targetBorrow = _underlyingToShort(targetUnderlyingLP);
		// we already updated tvl
		uint256 currentBorrow = _getBorrowBalance();

		// borrow funds or repay loan
		if (targetBorrow > currentBorrow) {
			// remove extra lp (we may need to remove more in order to add more collateral)
			_decreaseLpTo(
				_needUnderlying(targetUnderlyingLP, targetCollateral) > 0 ? 0 : targetUnderlyingLP
			);
			// add collateral
			_adjustCollateral(targetCollateral);
			_borrow(targetBorrow - currentBorrow);
		} else if (targetBorrow < currentBorrow) {
			// remove all of lp so we can repay loan
			_decreaseLpTo(0);
			uint256 repayAmnt = min(_short.balanceOf(address(this)), currentBorrow - targetBorrow);
			if (repayAmnt > 0) _repay(repayAmnt);
			// remove extra collateral
			_adjustCollateral(targetCollateral);
		}
		_increaseLpPosition(targetBorrow);
	}

	///////////////////////////
	//// INCREASE LP POSITION
	///////////////////////
	function _increaseLpPosition(uint256 targetBorrow) internal {
		uint256 underlyingBalance = _underlying.balanceOf(address(this));
		uint256 shortBalance = _short.balanceOf(address(this));

		// here we make sure we don't add extra lp
		(, uint256 shortLP) = _getLPBalances();

		if (targetBorrow < shortLP) return;

		uint256 addShort = min(
			(shortBalance + _underlyingToShort(underlyingBalance)) / 2,
			targetBorrow - shortLP
		);

		uint256 addUnderlying = _shortToUnderlying(addShort);

		// buy or sell underlying
		if (addUnderlying < underlyingBalance) {
			shortBalance += pair()._swapExactTokensForTokens(
				underlyingBalance - addUnderlying,
				address(_underlying),
				address(_short)
			);
			underlyingBalance = addUnderlying;
		} else if (shortBalance > addShort) {
			// swap extra tokens back (this may end up using more gas)
			underlyingBalance += pair()._swapExactTokensForTokens(
				shortBalance - addShort,
				address(_short),
				address(_underlying)
			);
			shortBalance = addShort;
		}

		// compute final lp amounts
		uint256 amntShort = shortBalance;
		uint256 amntUnderlying = _shortToUnderlying(amntShort);
		if (underlyingBalance < amntUnderlying) {
			amntUnderlying = underlyingBalance;
			amntShort = _underlyingToShort(amntUnderlying);
		}

		if (amntUnderlying == 0) return;

		// add liquidity
		// don't need to use min with underlying and short because we did oracle check
		// amounts are exact because we used swap price above
		uint256 liquidity = _addLiquidity(amntUnderlying, amntShort);
		_depositIntoFarm(liquidity);
	}

	function _needUnderlying(uint256 tragetUnderlying, uint256 targetCollateral)
		internal
		view
		returns (uint256)
	{
		uint256 collateralBalance = _getCollateralBalance();
		if (targetCollateral < collateralBalance) return 0;
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 uBalance = tragetUnderlying > underlyingLp ? tragetUnderlying - underlyingLp : 0;
		uint256 addCollateral = targetCollateral - collateralBalance;
		if (uBalance >= addCollateral) return 0;
		return addCollateral - uBalance;
	}

	// TVL

	function getMaxTvl() public view override returns (uint256) {
		return min(_maxTvl, _borrowToTotal(_oraclePriceOfShort(_maxBorrow())));
	}

	// TODO should we compute pending farm & lending rewards here?
	function _getAndUpdateTVL() internal returns (uint256 tvl) {
		uint256 collateralBalance = _updateAndGetCollateralBalance();
		uint256 shortPosition = _updateAndGetBorrowBalance();
		uint256 borrowBalance = _shortToUnderlying(shortPosition);
		uint256 shortP = _short.balanceOf(address(this));
		uint256 shortBalance = shortP == 0 ? 0 : _shortToUnderlying(shortP);
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 underlyingBalance = _underlying.balanceOf(address(this));
		tvl =
			collateralBalance +
			underlyingLp *
			2 -
			borrowBalance +
			underlyingBalance +
			shortBalance;
	}

	// for security this method should return cached value only
	// this is used by vault to track balance,
	// so this value should only be updated after oracle price check
	function balanceOfUnderlying() public view override returns (uint256) {
		return _cachedBalanceOfUnderlying;
	}

	function getTotalTVL() public view returns (uint256 tvl) {
		(tvl, , , , , ) = getTVL();
	}

	function getTVL()
		public
		view
		returns (
			uint256 tvl,
			uint256 collateralBalance,
			uint256 borrowPosition,
			uint256 borrowBalance,
			uint256 lpBalance,
			uint256 underlyingBalance
		)
	{
		collateralBalance = _getCollateralBalance();
		borrowPosition = _getBorrowBalance();
		borrowBalance = _shortToUnderlying(borrowPosition);

		uint256 shortPosition = _short.balanceOf(address(this));
		uint256 shortBalance = shortPosition == 0 ? 0 : _shortToUnderlying(shortPosition);

		(uint256 underlyingLp, uint256 shortLp) = _getLPBalances();
		lpBalance = underlyingLp + _shortToUnderlying(shortLp);
		underlyingBalance = _underlying.balanceOf(address(this));

		tvl = collateralBalance + lpBalance - borrowBalance + underlyingBalance + shortBalance;
	}

	function getPositionOffset() public view returns (uint256 positionOffset) {
		(, uint256 shortLp) = _getLPBalances();
		uint256 borrowBalance = _getBorrowBalance();
		uint256 shortBalance = shortLp + _short.balanceOf(address(this));

		if (shortBalance == borrowBalance) return 0;
		// if short lp > 0 and borrowBalance is 0 we are off by inf, returning 100% should be enough
		if (borrowBalance == 0) return 10000;

		// this is the % by which our position has moved from beeing balanced
		positionOffset = shortBalance > borrowBalance
			? ((shortBalance - borrowBalance) * BPS_ADJUST) / borrowBalance
			: ((borrowBalance - shortBalance) * BPS_ADJUST) / borrowBalance;
	}

	function getPriceOffset() public view returns (uint256 offset) {
		uint256 minPrice = _shortToUnderlying(1e18);
		uint256 maxPrice = _oraclePriceOfShort(1e18);
		(minPrice, maxPrice) = maxPrice > minPrice ? (minPrice, maxPrice) : (maxPrice, minPrice);
		offset = ((maxPrice - minPrice) * BPS_ADJUST) / maxPrice;
	}

	// UTILS

	function _totalToLp(uint256 total) internal view returns (uint256) {
		uint256 cRatio = getCollateralRatio();
		return (total * cRatio) / (BPS_ADJUST + cRatio);
	}

	function _borrowToTotal(uint256 amount) internal view returns (uint256) {
		uint256 cRatio = getCollateralRatio();
		return (amount * (BPS_ADJUST + cRatio)) / cRatio;
	}

	// this is the current uniswap price
	function _shortToUnderlying(uint256 amount) internal view returns (uint256) {
		return amount == 0 ? 0 : _quote(amount, address(_short), address(_underlying));
	}

	// this is the current uniswap price
	function _underlyingToShort(uint256 amount) internal view returns (uint256) {
		return amount == 0 ? 0 : _quote(amount, address(_underlying), address(_short));
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/forks/IClaimReward.sol";
import "./CompoundFarm.sol";

// import "hardhat/console.sol";

abstract contract CompMultiFarm is CompoundFarm {
	// BenQi has two two token rewards
	// pid 0 is Qi token and pid 1 is AVAX (not wrapped)
	function _harvestLending(HarvestSwapParms[] calldata swapParams)
		internal
		override
		returns (uint256[] memory harvested)
	{
		// farm token on id 0
		IClaimReward(address(comptroller())).claimReward(0, payable(address(this)));
		harvested = new uint256[](1);
		harvested[0] = _farmToken.balanceOf(address(this));

		if (harvested[0] > 0) {
			_swap(lendFarmRouter(), swapParams[0], address(_farmToken), harvested[0]);
			emit HarvestedToken(address(_farmToken), harvested[0]);
		}

		// base token rewards on id 1
		IClaimReward(address(comptroller())).claimReward(1, payable(address(this)));

		uint256 avaxBalance = address(this).balance;
		if (avaxBalance > 0) {
			IWETH(address(short())).deposit{ value: avaxBalance }();
			emit HarvestedToken(address(short()), avaxBalance);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/compound/ICTokenInterfaces.sol";
import "../../interfaces/compound/IComptroller.sol";
import "../../interfaces/compound/ICompPriceOracle.sol";
import "../../interfaces/compound/IComptroller.sol";

import "../../mixins/ICompound.sol";

// import "hardhat/console.sol";

abstract contract Compound is ICompound {
	using SafeERC20 for IERC20;

	ICTokenErc20 private _cTokenLend;
	ICTokenErc20 private _cTokenBorrow;

	IComptroller private _comptroller;
	ICompPriceOracle private _oracle;

	function __Compound_init_(
		address comptroller_,
		address cTokenLend_,
		address cTokenBorrow_
	) internal {
		_cTokenLend = ICTokenErc20(cTokenLend_);
		_cTokenBorrow = ICTokenErc20(cTokenBorrow_);
		_comptroller = IComptroller(comptroller_);
		_oracle = ICompPriceOracle(ComptrollerV1Storage(comptroller_).oracle());
		_enterMarket();
	}

	function _addLendingApprovals() internal override {
		// ensure USDC approval - assume we trust USDC
		underlying().safeApprove(address(_cTokenLend), type(uint256).max);
		short().safeApprove(address(_cTokenBorrow), type(uint256).max);
	}

	function cTokenLend() public view override returns (ICTokenErc20) {
		return _cTokenLend;
	}

	function cTokenBorrow() public view override returns (ICTokenErc20) {
		return _cTokenBorrow;
	}

	function oracle() public view override returns (ICompPriceOracle) {
		return _oracle;
	}

	function comptroller() public view override returns (IComptroller) {
		return _comptroller;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../mixins/ICompound.sol";
import "../../mixins/IFarmable.sol";
import "../../interfaces/uniswap/IUniswapV2Pair.sol";

// import "hardhat/console.sol";

abstract contract CompoundFarm is ICompound, IFarmable {
	using SafeERC20 for IERC20;

	IUniswapV2Router01 private _router; // use router here
	IERC20 _farmToken;

	function __CompoundFarm_init_(address router_, address token_) internal initializer {
		_farmToken = IERC20(token_);
		_router = IUniswapV2Router01(router_);
		_farmToken.safeApprove(address(_router), type(uint256).max);
	}

	function lendFarmRouter() public view override returns (IUniswapV2Router01) {
		return _router;
	}

	function _harvestLending(HarvestSwapParms[] calldata swapParams)
		internal
		virtual
		override
		returns (uint256[] memory harvested)
	{
		// comp token rewards
		ICTokenErc20[] memory cTokens = new ICTokenErc20[](2);
		cTokens[0] = cTokenLend();
		cTokens[1] = cTokenBorrow();
		comptroller().claimComp(address(this), cTokens);

		harvested = new uint256[](1);
		harvested[0] = _farmToken.balanceOf(address(this));
		if (harvested[0] == 0) return harvested;

		if (address(_router) != address(0))
			_swap(_router, swapParams[0], address(_farmToken), harvested[0]);
		emit HarvestedToken(address(_farmToken), harvested[0]);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IMasterChef } from "../../interfaces/uniswap/IStakingRewards.sol";
import "../../interfaces/uniswap/IUniswapV2Pair.sol";

import "../../mixins/IFarmableLp.sol";
import "../../mixins/IUniLp.sol";
import "../../interfaces/uniswap/IWETH.sol";

// import "hardhat/console.sol";

abstract contract MasterChefFarm is IFarmableLp, IUniLp {
	using SafeERC20 for IERC20;

	IMasterChef private _farm;
	IUniswapV2Router01 private _router;
	IERC20 private _farmToken;
	IUniswapV2Pair private _pair;
	uint256 private _farmId;

	function __MasterChefFarm_init_(
		address pair_,
		address farm_,
		address router_,
		address farmToken_,
		uint256 farmPid_
	) internal initializer {
		_farm = IMasterChef(farm_);
		_router = IUniswapV2Router01(router_);
		_farmToken = IERC20(farmToken_);
		_pair = IUniswapV2Pair(pair_);
		_farmId = farmPid_;
	}

	// assumption that _router and _farm are trusted
	function _addFarmApprovals() internal override {
		IERC20(address(_pair)).safeApprove(address(_farm), type(uint256).max);
		if (_farmToken.allowance(address(this), address(_router)) == 0)
			_farmToken.safeApprove(address(_router), type(uint256).max);
	}

	function farmRouter() public view override returns (IUniswapV2Router01) {
		return _router;
	}

	function pair() public view override returns (IUniswapV2Pair) {
		return _pair;
	}

	function _withdrawFromFarm(uint256 amount) internal override {
		_farm.withdraw(_farmId, amount);
	}

	function _depositIntoFarm(uint256 amount) internal override {
		_farm.deposit(_farmId, amount);
	}

	function _harvestFarm(HarvestSwapParms[] calldata swapParams)
		internal
		override
		returns (uint256[] memory harvested)
	{
		_farm.deposit(_farmId, 0);
		harvested = new uint256[](1);
		harvested[0] = _farmToken.balanceOf(address(this));
		if (harvested[0] == 0) return harvested;

		_swap(_router, swapParams[0], address(_farmToken), harvested[0]);
		emit HarvestedToken(address(_farmToken), harvested[0]);

		uint256 avaxBalance = address(this).balance;
		if (avaxBalance > 0) {
			IWETH(address(short())).deposit{ value: avaxBalance }();
			emit HarvestedToken(address(short()), avaxBalance);
		}
	}

	function _getFarmLp() internal view override returns (uint256) {
		(uint256 lp, ) = _farm.userInfo(_farmId, address(this));
		return lp;
	}

	function _getLiquidity() internal view override returns (uint256) {
		uint256 farmLp = _getFarmLp();
		uint256 poolLp = _pair.balanceOf(address(this));
		return farmLp + poolLp;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../HedgedLP.sol";
import "../adapters/Compound.sol";
import "../adapters/MasterChefFarm.sol";
import "../adapters/CompMultiFarm.sol";

// import "hardhat/console.sol";

contract USDCmovrSOLARwell is HedgedLP, Compound, CompMultiFarm, MasterChefFarm {
	// HedgedLP should allways be intialized last
	constructor(Config memory config) BaseStrategy(config.vault, config.symbol, config.name) {
		__MasterChefFarm_init_(
			config.uniPair,
			config.uniFarm,
			config.farmRouter,
			config.farmToken,
			config.farmId
		);

		__Compound_init_(config.comptroller, config.cTokenLend, config.cTokenBorrow);

		__CompoundFarm_init_(config.lendRewardRouter, config.lendRewardToken);

		__HedgedLP_init_(config.underlying, config.short, config.maxTvl);
	}

	// if borrow token is treated as ETH
	function _isBase(uint8) internal pure override(ICompound) returns (bool) {
		return true;
	}
}