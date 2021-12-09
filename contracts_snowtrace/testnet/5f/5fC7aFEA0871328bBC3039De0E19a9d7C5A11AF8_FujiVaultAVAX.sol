/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}


interface IVaultControl {
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  function vAssets() external view returns (VaultAssets memory);
}


/**
 * @title Errors library
 * @author Fuji
 * @notice Defines the error messages emitted by the different contracts
 * @dev Error messages prefix glossary:
 *  - VL = Validation Logic 100 series
 *  - MATH = Math libraries 200 series
 *  - RF = Refinancing 300 series
 *  - VLT = vault 400 series
 *  - SP = Special 900 series
 */
library Errors {
  //Errors
  string public constant VL_INDEX_OVERFLOW = "100"; // index overflows uint128
  string public constant VL_INVALID_MINT_AMOUNT = "101"; //invalid amount to mint
  string public constant VL_INVALID_BURN_AMOUNT = "102"; //invalid amount to burn
  string public constant VL_AMOUNT_ERROR = "103"; //Input value >0, and for ETH msg.value and amount shall match
  string public constant VL_INVALID_WITHDRAW_AMOUNT = "104"; //Withdraw amount exceeds provided collateral, or falls undercollaterized
  string public constant VL_INVALID_BORROW_AMOUNT = "105"; //Borrow amount does not meet collaterization
  string public constant VL_NO_DEBT_TO_PAYBACK = "106"; //Msg sender has no debt amount to be payback
  string public constant VL_MISSING_ERC20_ALLOWANCE = "107"; //Msg sender has not approved ERC20 full amount to transfer
  string public constant VL_USER_NOT_LIQUIDATABLE = "108"; //User debt position is not liquidatable
  string public constant VL_DEBT_LESS_THAN_AMOUNT = "109"; //User debt is less than amount to partial close
  string public constant VL_PROVIDER_ALREADY_ADDED = "110"; // Provider is already added in Provider Array
  string public constant VL_NOT_AUTHORIZED = "111"; //Not authorized
  string public constant VL_INVALID_COLLATERAL = "112"; //There is no Collateral, or Collateral is not in active in vault
  string public constant VL_NO_ERC20_BALANCE = "113"; //User does not have ERC20 balance
  string public constant VL_INPUT_ERROR = "114"; //Check inputs. For ERC1155 batch functions, array sizes should match.
  string public constant VL_ASSET_EXISTS = "115"; //Asset intended to be added already exists in FujiERC1155
  string public constant VL_ZERO_ADDR_1155 = "116"; //ERC1155: balance/transfer for zero address
  string public constant VL_NOT_A_CONTRACT = "117"; //Address is not a contract.
  string public constant VL_INVALID_ASSETID_1155 = "118"; //ERC1155 Asset ID is invalid.
  string public constant VL_NO_ERC1155_BALANCE = "119"; //ERC1155: insufficient balance for transfer.
  string public constant VL_MISSING_ERC1155_APPROVAL = "120"; //ERC1155: transfer caller is not owner nor approved.
  string public constant VL_RECEIVER_REJECT_1155 = "121"; //ERC1155Receiver rejected tokens
  string public constant VL_RECEIVER_CONTRACT_NON_1155 = "122"; //ERC1155: transfer to non ERC1155Receiver implementer
  string public constant VL_OPTIMIZER_FEE_SMALL = "123"; //Fuji OptimizerFee has to be > 1 RAY (1e27)
  string public constant VL_UNDERCOLLATERIZED_ERROR = "124"; // Flashloan-Flashclose cannot be used when User's collateral is worth less than intended debt position to close.
  string public constant VL_MINIMUM_PAYBACK_ERROR = "125"; // Minimum Amount payback should be at least Fuji Optimizerfee accrued interest.
  string public constant VL_HARVESTING_FAILED = "126"; // Harvesting Function failed, check provided _farmProtocolNum or no claimable balance.
  string public constant VL_FLASHLOAN_FAILED = "127"; // Flashloan failed
  string public constant VL_ERC1155_NOT_TRANSFERABLE = "128"; // ERC1155: Not Transferable
  string public constant VL_SWAP_SLIPPAGE_LIMIT_EXCEED = "129"; // ERC1155: Not Transferable
  string public constant VL_ZERO_ADDR = "130"; // Zero Address
  string public constant VL_INVALID_FLASH_NUMBER = "131"; // invalid flashloan number
  string public constant VL_INVALID_HARVEST_PROTOCOL_NUMBER = "132"; // invalid flashloan number
  string public constant VL_INVALID_HARVEST_TYPE = "133"; // invalid flashloan number
  string public constant VL_INVALID_FACTOR = "134"; // invalid factor
  string public constant VL_INVALID_NEW_PROVIDER ="135"; // invalid newProvider in executeSwitch

  string public constant MATH_DIVISION_BY_ZERO = "201";
  string public constant MATH_ADDITION_OVERFLOW = "202";
  string public constant MATH_MULTIPLICATION_OVERFLOW = "203";

  string public constant RF_INVALID_RATIO_VALUES = "301"; // Ratio Value provided is invalid, _ratioA/_ratioB <= 1, and > 0, or activeProvider borrowBalance = 0
  string public constant RF_INVALID_NEW_ACTIVEPROVIDER = "302"; //Input '_newProvider' and vault's 'activeProvider' must be different

  string public constant VLT_CALLER_MUST_BE_VAULT = "401"; // The caller of this function must be a vault

  string public constant ORACLE_INVALID_LENGTH = "501"; // The assets length and price feeds length doesn't match
  string public constant ORACLE_NONE_PRICE_FEED = "502"; // The price feed is not found
}


/**
 * @dev Contract that is inherited by FujiVaults
 * contains delegate call functions to providers and {Pausable} guards
 *
 */
abstract contract VaultControlUpgradeable is OwnableUpgradeable, PausableUpgradeable {
  // Vault Struct for Managed Assets
  IVaultControl.VaultAssets public vAssets;

  // Pause Functions

  /**
   * @dev Emergency Call to stop all basic money flow functions.
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @dev Emergency Call to stop all basic money flow functions.
   */
  function unpause() public onlyOwner {
    _unpause();
  }
}

contract VaultBaseUpgradeable is VaultControlUpgradeable {
  using AddressUpgradeable for address;

  // Internal functions

  /**
   * @dev Executes deposit operation with delegatecall.
   * @param _amount: amount to be deposited
   * @param _provider: address of provider to be used
   */
  function _deposit(uint256 _amount, address _provider) internal {
    bytes memory data = abi.encodeWithSignature(
      "deposit(address,uint256)",
      vAssets.collateralAsset,
      _amount
    );
    _execute(_provider, data);
  }

  /**
   * @dev Executes withdraw operation with delegatecall.
   * @param _amount: amount to be withdrawn
   * @param _provider: address of provider to be used
   */
  function _withdraw(uint256 _amount, address _provider) internal {
    bytes memory data = abi.encodeWithSignature(
      "withdraw(address,uint256)",
      vAssets.collateralAsset,
      _amount
    );
    _execute(_provider, data);
  }

  /**
   * @dev Executes borrow operation with delegatecall.
   * @param _amount: amount to be borrowed
   * @param _provider: address of provider to be used
   */
  function _borrow(uint256 _amount, address _provider) internal {
    bytes memory data = abi.encodeWithSignature(
      "borrow(address,uint256)",
      vAssets.borrowAsset,
      _amount
    );
    _execute(_provider, data);
  }

  /**
   * @dev Executes payback operation with delegatecall.
   * @param _amount: amount to be paid back
   * @param _provider: address of provider to be used
   */
  function _payback(uint256 _amount, address _provider) internal {
    bytes memory data = abi.encodeWithSignature(
      "payback(address,uint256)",
      vAssets.borrowAsset,
      _amount
    );
    _execute(_provider, data);
  }

  /**
   * @dev Returns byte response of delegatcalls
   */
  function _execute(address _target, bytes memory _data)
    private
    whenNotPaused
    returns (bytes memory response)
  {
    // This is the same logic of functionDelegateCall provided by openzeppelin.
    // We copy the code here because of oz-upgrades-unsafe-allow for delegatecall.

    require(_target.isContract(), Errors.VL_NOT_A_CONTRACT);

    /// @custom:oz-upgrades-unsafe-allow delegatecall
    (bool success, bytes memory returndata) = _target.delegatecall(_data);

    return AddressUpgradeable.verifyCallResult(success, returndata, "delegate call to provider failed");
  }
}


interface IVault {

  // Vault Events

  /**
  * @dev Log a deposit transaction done by a user
  */
  event Deposit(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a withdraw transaction done by a user
  */
  event Withdraw(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a borrow transaction done by a user
  */
  event Borrow(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a payback transaction done by a user
  */
  event Payback(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a switch from provider to new provider in vault
  */
  event Switch(
    address fromProviderAddrs,
    address toProviderAddr,
    uint256 debtamount,
    uint256 collattamount
  );
  /**
  * @dev Log a change in active provider
  */
  event SetActiveProvider(address newActiveProviderAddress);
  /**
  * @dev Log a change in the array of provider addresses
  */
  event ProvidersChanged(address[] newProviderArray);
  /**
  * @dev Log a change in F1155 address
  */
  event F1155Changed(address newF1155Address);
  /**
  * @dev Log a change in fuji admin address
  */
  event FujiAdminChanged(address newFujiAdmin);
  /**
  * @dev Log a change in the factor values
  */
  event FactorChanged(
    FactorType factorType,
    uint64 newFactorA,
    uint64 newFactorB
  );
  /**
  * @dev Log a change in the oracle address
  */
  event OracleChanged(address newOracle);

  enum FactorType {
    Safety,
    Collateralization,
    ProtocolFee,
    BonusLiquidation
  }

  struct Factor {
    uint64 a;
    uint64 b;
  }

  // Core Vault Functions

  function deposit(uint256 _collateralAmount) external payable;

  function withdraw(int256 _withdrawAmount) external;

  function withdrawLiq(int256 _withdrawAmount) external;

  function borrow(uint256 _borrowAmount) external;

  function payback(int256 _repayAmount) external payable;

  function paybackLiq(address[] memory _users, uint256 _repayAmount) external payable;

  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanDebt,
    uint256 _fee
  ) external payable;

  //Getter Functions

  function activeProvider() external view returns (address);

  function borrowBalance(address _provider) external view returns (uint256);

  function depositBalance(address _provider) external view returns (uint256);

  function userDebtBalance(address _user) external view returns (uint256);

  function userProtocolFee(address _user) external view returns (uint256);

  function userDepositBalance(address _user) external view returns (uint256);

  function getNeededCollateralFor(uint256 _amount, bool _withFactors)
    external
    view
    returns (uint256);

  function getLiquidationBonusFor(uint256 _amount) external view returns (uint256);

  function getProviders() external view returns (address[] memory);

  function fujiERC1155() external view returns (address);

  //Setter Functions

  function setActiveProvider(address _provider) external;

  function updateF1155Balances() external;

  function protocolFee() external view returns (uint64, uint64);
}


interface IHarvester {
  struct Transaction {
    address to;
    bytes data;
  }

  function getHarvestTransaction(uint256 _farmProtocolNum, bytes memory _data)
    external
    returns (address claimedToken, Transaction memory transaction);
}


interface ISwapper {
  struct Transaction {
    address to;
    bytes data;
    uint256 value;
  }

  function getSwapTransaction(
    address assetFrom,
    address assetTo,
    uint256 amount
  ) external returns (Transaction memory transaction);
}


interface IERC20Extended {
  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}


interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


interface IFujiAdmin {

  // FujiAdmin Events

  /**
  * @dev Log change of flasher address
  */
  event FlasherChanged(address newFlasher);
  /**
  * @dev Log change of fliquidator address
  */
  event FliquidatorChanged(address newFliquidator);
  /**
  * @dev Log change of treasury address
  */
  event TreasuryChanged(address newTreasury);
  /**
  * @dev Log change of controller address
  */
  event ControllerChanged(address newController);
  /**
  * @dev Log change of vault harvester address
  */
  event VaultHarvesterChanged(address newHarvester);
  /**
  * @dev Log change of swapper address
  */
  event SwapperChanged(address newSwapper);
  /**
  * @dev Log change of vault address permission
  */
  event VaultPermitChanged(address vaultAddress, bool newPermit);


  function validVault(address _vaultAddr) external view returns (bool);

  function getFlasher() external view returns (address);

  function getFliquidator() external view returns (address);

  function getController() external view returns (address);

  function getTreasury() external view returns (address payable);

  function getVaultHarvester() external view returns (address);

  function getSwapper() external view returns (address);
}


interface IFujiOracle {

  // FujiOracle Events

  /**
  * @dev Log a change in price feed address for asset address
  */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  ) external view returns (uint256);
}


interface IFujiERC1155 {
  //Asset Types
  enum AssetType {
    //uint8 = 0
    collateralToken,
    //uint8 = 1
    debtToken
  }

  //General Getter Functions

  function getAssetID(AssetType _type, address _assetAddr) external view returns (uint256);

  function qtyOfManagedAssets() external view returns (uint64);

  function balanceOf(address _account, uint256 _id) external view returns (uint256);

  // function splitBalanceOf(address account,uint256 _AssetID) external view  returns (uint256,uint256);

  // function balanceOfBatchType(address account, AssetType _Type) external view returns (uint256);

  //Permit Controlled  Functions
  function mint(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external;

  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external;

  function updateState(uint256 _assetID, uint256 _newBalance) external;

  function addInitializeAsset(AssetType _type, address _addr) external returns (uint64);
}


interface IProvider {
  //Basic Core Functions

  function deposit(address _collateralAsset, uint256 _collateralAmount) external payable;

  function borrow(address _borrowAsset, uint256 _borrowAmount) external payable;

  function withdraw(address _collateralAsset, uint256 _collateralAmount) external payable;

  function payback(address _borrowAsset, uint256 _borrowAmount) external payable;

  // returns the borrow annualized rate for an asset in ray (1e27)
  //Example 8.5% annual interest = 0.085 x 10^27 = 85000000000000000000000000 or 85*(10**24)
  function getBorrowRateFor(address _asset) external view returns (uint256);

  function getBorrowBalance(address _asset) external view returns (uint256);

  function getDepositBalance(address _asset) external view returns (uint256);

  function getBorrowBalanceOf(address _asset, address _who) external returns (uint256);
}


library LibUniversalERC20UpgradeableAVAX {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  IERC20Upgradeable private constant _AVAX_ADDRESS =
    IERC20Upgradeable(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
  IERC20Upgradeable private constant _ZERO_ADDRESS =
    IERC20Upgradeable(0x0000000000000000000000000000000000000000);

  function isAVAX(IERC20Upgradeable token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _AVAX_ADDRESS);
  }

  function univBalanceOf(IERC20Upgradeable token, address account) internal view returns (uint256) {
    if (isAVAX(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function univTransfer(
    IERC20Upgradeable token,
    address payable to,
    uint256 amount
  ) internal {
    if (amount > 0) {
      if (isAVAX(token)) {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send AVAX");
      } else {
        token.safeTransfer(to, amount);
      }
    }
  }

  function univApprove(
    IERC20Upgradeable token,
    address to,
    uint256 amount
  ) internal {
    require(!isAVAX(token), "Approve called on AVAX");

    if (amount == 0) {
      token.safeApprove(to, 0);
    } else {
      uint256 allowance = token.allowance(address(this), to);
      if (allowance < amount) {
        if (allowance > 0) {
          token.safeApprove(to, 0);
        }
        token.safeApprove(to, amount);
      }
    }
  }
}


/**
 * @dev Contract for the interaction of Fuji users with the Fuji protocol.
 *  - Performs deposit, withdraw, borrow and payback functions.
 *  - Contains the fallback logic to perform a switch of providers.
 */
contract FujiVaultAVAX is VaultBaseUpgradeable, ReentrancyGuardUpgradeable, IVault {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using LibUniversalERC20UpgradeableAVAX for IERC20Upgradeable;

  address public constant AVAX = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

  // Safety factor
  Factor public safetyF;

  // Collateralization factor
  Factor public collatF;

  // Protocol Fee factor
  Factor public override protocolFee;

  // Bonus factor for liquidation
  Factor public bonusLiqF;

  //State variables
  address[] public providers;
  address public override activeProvider;

  IFujiAdmin private _fujiAdmin;
  address public override fujiERC1155;
  IFujiOracle public oracle;

  string public name;

  uint8 internal _collateralAssetDecimals;
  uint8 internal _borrowAssetDecimals;

  uint256 public constant ONE_YEAR = 60 * 60 * 24 * 365;

  mapping(address => uint256) internal _userFeeTimestamps; // to be used for protocol fee calculation
  uint256 public remainingProtocolFee;

  /**
  * @dev Throws if caller is not the 'owner' or the '_controller' address stored in {FujiAdmin}
  */
  modifier isAuthorized() {
    require(
      msg.sender == owner() || msg.sender == _fujiAdmin.getController(),
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  /**
  * @dev Throws if caller is not the '_flasher' address stored in {FujiAdmin}
  */
  modifier onlyFlash() {
    require(msg.sender == _fujiAdmin.getFlasher(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  /**
  * @dev Throws if caller is not the '_fliquidator' address stored in {FujiAdmin}
  */
  modifier onlyFliquidator() {
    require(msg.sender == _fujiAdmin.getFliquidator(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  /**
  * @dev Initializes the contract by setting:
  * - Type of collateral and borrow asset of this vault.
  * - Addresses for fujiAdmin, _oracle.
  */
  function initialize(
    address _fujiadmin,
    address _oracle,
    address _collateralAsset,
    address _borrowAsset
  ) external initializer {

    require(
      _fujiadmin != address(0) &&
      _oracle != address(0) &&
      _collateralAsset != address(0) &&
      _borrowAsset != address(0),
      Errors.VL_ZERO_ADDR);

    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    _fujiAdmin = IFujiAdmin(_fujiadmin);
    oracle = IFujiOracle(_oracle);
    vAssets.collateralAsset = _collateralAsset;
    vAssets.borrowAsset = _borrowAsset;

    string memory collateralSymbol;
    string memory borrowSymbol;

    if (_collateralAsset == AVAX) {
      collateralSymbol = "AVAX";
      _collateralAssetDecimals = 18;
    } else {
      collateralSymbol = IERC20Extended(_collateralAsset).symbol();
      _collateralAssetDecimals = IERC20Extended(_collateralAsset).decimals();
    }

    if (_borrowAsset == AVAX) {
      borrowSymbol = "AVAX";
      _borrowAssetDecimals = 18;
    } else {
      borrowSymbol = IERC20Extended(_borrowAsset).symbol();
      _borrowAssetDecimals = IERC20Extended(_borrowAsset).decimals();
    }

    name = string(abi.encodePacked("Vault", collateralSymbol, borrowSymbol));

    // 1.05
    safetyF.a = 21;
    safetyF.b = 20;

    // 1.269
    collatF.a = 80;
    collatF.b = 63;

    // 0.05
    bonusLiqF.a = 1;
    bonusLiqF.b = 20;

    protocolFee.a = 1;
    protocolFee.b = 1000;
  }

  receive() external payable {}

  //Core functions

  /**
   * @dev Deposits collateral and borrows underlying in a single function call from activeProvider
   * @param _collateralAmount: amount to be deposited
   * @param _borrowAmount: amount to be borrowed
   */
  function depositAndBorrow(uint256 _collateralAmount, uint256 _borrowAmount) external payable {
    updateF1155Balances();
    _internalDeposit(_collateralAmount);
    _internalBorrow(_borrowAmount);
  }

  /**
   * @dev Paybacks the underlying asset and withdraws collateral in a single function call from activeProvider
   * @param _paybackAmount: amount of underlying asset to be payback, pass -1 to pay full amount
   * @param _collateralAmount: amount of collateral to be withdrawn, pass -1 to withdraw maximum amount
   */
  function paybackAndWithdraw(int256 _paybackAmount, int256 _collateralAmount) external payable {
    updateF1155Balances();
    _internalPayback(_paybackAmount);
    _internalWithdraw(_collateralAmount);
  }

  /**
   * @dev Deposit Vault's type collateral to activeProvider
   * call Controller checkrates
   * @param _collateralAmount: to be deposited
   * Emits a {Deposit} event.
   */
  function deposit(uint256 _collateralAmount) public payable override {
    updateF1155Balances();
    _internalDeposit(_collateralAmount);
  }

  /**
   * @dev Withdraws Vault's type collateral from activeProvider
   * call Controller checkrates - by normal users
   * @param _withdrawAmount: amount of collateral to withdraw
   * otherwise pass any 'negative number' to withdraw maximum amount possible of collateral (including safety factors)
   * Emits a {Withdraw} event.
   */
  function withdraw(int256 _withdrawAmount) public override nonReentrant {
    updateF1155Balances();
    _internalWithdraw(_withdrawAmount);
  }

  /**
   * @dev Withdraws Vault's type collateral from activeProvider
   * call Controller checkrates - by Fliquidator
   * @param _withdrawAmount: amount of collateral to withdraw
   * otherwise pass -1 to withdraw maximum amount possible of collateral (including safety factors)
   * Emits a {Withdraw} event.
   */
  function withdrawLiq(int256 _withdrawAmount) external override nonReentrant onlyFliquidator {
    // Logic used when called by Fliquidator
    _withdraw(uint256(_withdrawAmount), address(activeProvider));
    IERC20Upgradeable(vAssets.collateralAsset).univTransfer(
      payable(msg.sender),
      uint256(_withdrawAmount)
    );
  }

  /**
   * @dev Borrows Vault's type underlying amount from activeProvider
   * @param _borrowAmount: token amount of underlying to borrow
   * Emits a {Borrow} event.
   */
  function borrow(uint256 _borrowAmount) public override nonReentrant {
    updateF1155Balances();
    _internalBorrow(_borrowAmount);
  }

  /**
   * @dev Paybacks Vault's type underlying to activeProvider - called by users
   * @param _repayAmount: token amount of underlying to repay, or
   * pass any 'negative number' to repay full ammount
   * Emits a {Repay} event.
   */
  function payback(int256 _repayAmount) public payable override {
    updateF1155Balances();
    _internalPayback(_repayAmount);
  }

  /**
   * @dev Paybacks Vault's type underlying to activeProvider
   * @param _repayAmount: token amount of underlying to repay, or pass -1 to repay full ammount
   * Emits a {Repay} event.
   */
  function paybackLiq(address[] memory _users, uint256 _repayAmount)
    external
    payable
    override
    onlyFliquidator
  {
    // calculate protocol fee
    uint256 _fee = 0;
    for (uint256 i = 0; i < _users.length; i++) {
      if (_users[i] != address(0)) {
        _userFeeTimestamps[_users[i]] = block.timestamp;

        uint256 debtPrincipal = IFujiERC1155(fujiERC1155).balanceOf(_users[i], vAssets.borrowID);
        _fee += _userProtocolFee(_users[i], debtPrincipal);
      }
    }

    // Logic used when called by Fliquidator
    _payback(_repayAmount - _fee, address(activeProvider));

    // Update protocol fees
    remainingProtocolFee += _fee;
  }

  /**
   * @dev Changes Vault debt and collateral to newProvider, called by Flasher
   * @param _newProvider new provider's address
   * @param _flashLoanAmount amount of flashloan underlying to repay Flashloan
   * Emits a {Switch} event.
   */
  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanAmount,
    uint256 _fee
  ) external payable override onlyFlash whenNotPaused {
    // Check '_newProvider' is a valid provider
    bool validProvider;
    for (uint i = 0; i < providers.length; i++) {
      if (_newProvider == providers[i]) {
        validProvider = true;
      }
    }
    if (!validProvider) {
      revert(Errors.VL_INVALID_NEW_PROVIDER);
    }

    // Compute Ratio of transfer before payback
    uint256 ratio = (_flashLoanAmount * 1e18) /
      (IProvider(activeProvider).getBorrowBalance(vAssets.borrowAsset));

    // Payback current provider
    _payback(_flashLoanAmount, activeProvider);

    // Withdraw collateral proportional ratio from current provider
    uint256 collateraltoMove = (IProvider(activeProvider).getDepositBalance(
      vAssets.collateralAsset
    ) * ratio) / 1e18;

    _withdraw(collateraltoMove, activeProvider);

    // Deposit to the new provider
    _deposit(collateraltoMove, _newProvider);

    // Borrow from the new provider, borrowBalance + premium
    _borrow(_flashLoanAmount + _fee, _newProvider);

    // return borrowed amount to Flasher
    IERC20Upgradeable(vAssets.borrowAsset).univTransfer(
      payable(msg.sender),
      _flashLoanAmount + _fee
    );

    emit Switch(activeProvider, _newProvider, _flashLoanAmount, collateraltoMove);
  }

  // Setter, change state functions

  /**
   * @dev Sets the fujiAdmin Address
   * @param _newFujiAdmin: FujiAdmin Contract Address
   * Emits a {FujiAdminChanged} event.
   */
  function setFujiAdmin(address _newFujiAdmin) external onlyOwner {
    require(_newFujiAdmin != address(0), Errors.VL_ZERO_ADDR);
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
    emit FujiAdminChanged(_newFujiAdmin);
  }

  /**
   * @dev Sets a new active provider for the Vault
   * @param _provider: fuji address of the new provider
   * Emits a {SetActiveProvider} event.
   */
  function setActiveProvider(address _provider) external override isAuthorized {
    require(_provider != address(0), Errors.VL_ZERO_ADDR);
    activeProvider = _provider;
    emit SetActiveProvider(_provider);
  }

  // Administrative functions

  /**
   * @dev Sets a fujiERC1155 Collateral and Debt Asset manager for this vault and initializes it.
   * @param _fujiERC1155: fuji ERC1155 address
   * Emits a {F1155Changed} event.
   */
  function setFujiERC1155(address _fujiERC1155) external isAuthorized {
    require(_fujiERC1155 != address(0), Errors.VL_ZERO_ADDR);
    fujiERC1155 = _fujiERC1155;

    vAssets.collateralID = IFujiERC1155(_fujiERC1155).addInitializeAsset(
      IFujiERC1155.AssetType.collateralToken,
      address(this)
    );
    vAssets.borrowID = IFujiERC1155(_fujiERC1155).addInitializeAsset(
      IFujiERC1155.AssetType.debtToken,
      address(this)
    );
    emit F1155Changed(_fujiERC1155);
  }

  /**
   * @dev Set Factors "a" and "b" for a Struct Factor.
   * @param _newFactorA: Nominator
   * @param _newFactorB: Denominator
   * @param _type: 0 for "safetyF", 1 for "collatF", 2 for "protocolFee", 3 for "bonusLiqF"
   * Emits a {FactorChanged} event.
   * Requirements:
   * - _newFactorA and _newFactorB should be non-zero values.
   * - For safetyF;  a/b, should be > 1.
   * - For collatF; a/b, should be > 1.
   * - For bonusLiqF; a/b should be < 1.
   * - For protocolFee; a/b should be < 1.
   */
  function setFactor(
    uint64 _newFactorA,
    uint64 _newFactorB,
    FactorType _type
  ) external isAuthorized {
    if (_type == FactorType.Safety) {
      require(_newFactorA > _newFactorB, Errors.RF_INVALID_RATIO_VALUES);
      safetyF.a = _newFactorA;
      safetyF.b = _newFactorB;
    } else if (_type == FactorType.Collateralization) {
      require(_newFactorA > _newFactorB, Errors.RF_INVALID_RATIO_VALUES);
      collatF.a = _newFactorA;
      collatF.b = _newFactorB;
    } else if (_type == FactorType.ProtocolFee) {
      require(_newFactorA < _newFactorB, Errors.RF_INVALID_RATIO_VALUES);
      protocolFee.a = _newFactorA;
      protocolFee.b = _newFactorB;
    } else if (_type == FactorType.BonusLiquidation) {
      require(_newFactorA < _newFactorB, Errors.RF_INVALID_RATIO_VALUES);
      bonusLiqF.a = _newFactorA;
      bonusLiqF.b = _newFactorB;
    } else {
      revert(Errors.VL_INVALID_FACTOR);
    }

    emit FactorChanged(_type, _newFactorA, _newFactorB);
  }

  /**
   * @dev Sets the Oracle address (Must Comply with AggregatorV3Interface)
   * @param _oracle: new Oracle address
   * Emits a {OracleChanged} event.
   */
  function setOracle(address _oracle) external isAuthorized {
    require(_oracle != address(0), Errors.VL_ZERO_ADDR);
    oracle = IFujiOracle(_oracle);
    emit OracleChanged(_oracle);
  }

  /**
   * @dev Set providers to the Vault
   * @param _providers: new providers' addresses
   * Emits a {ProvidersChanged} event.
   */
  function setProviders(address[] calldata _providers) external isAuthorized {
    for(uint i = 0; i < _providers.length; i++) {
      require(_providers[i] != address(0), Errors.VL_ZERO_ADDR);
    }
    providers = _providers;
    emit ProvidersChanged(_providers);
  }

  /**
   * @dev External Function to call updateState in F1155
   */
  function updateF1155Balances() public override {
    IFujiERC1155(fujiERC1155).updateState(
      vAssets.borrowID,
      IProvider(activeProvider).getBorrowBalance(vAssets.borrowAsset)
    );
    IFujiERC1155(fujiERC1155).updateState(
      vAssets.collateralID,
      IProvider(activeProvider).getDepositBalance(vAssets.collateralAsset)
    );
  }

  //Getter Functions

  /**
   * @dev Returns an array of the Vault's providers
   */
  function getProviders() external view override returns (address[] memory) {
    return providers;
  }

  /**
   * @dev Returns an amount to be paid as bonus for liquidation
   * @param _amount: Vault underlying type intended to be liquidated
   */
  function getLiquidationBonusFor(uint256 _amount) external view override returns (uint256) {
    return (_amount * bonusLiqF.a) / bonusLiqF.b;
  }

  /**
   * @dev Returns the amount of collateral needed, including or not safety factors
   * @param _amount: Vault underlying type intended to be borrowed
   * @param _withFactors: Inidicate if computation should include safety_Factors
   */
  function getNeededCollateralFor(uint256 _amount, bool _withFactors)
    public
    view
    override
    returns (uint256)
  {
    // Get exchange rate
    uint256 price = oracle.getPriceOf(
      vAssets.collateralAsset,
      vAssets.borrowAsset,
      _collateralAssetDecimals
    );
    uint256 minimumReq = (_amount * price) / (10**uint256(_borrowAssetDecimals));
    if (_withFactors) {
      return (minimumReq * (collatF.a) * (safetyF.a)) / (collatF.b) / (safetyF.b);
    } else {
      return minimumReq;
    }
  }

  /**
   * @dev Returns the borrow balance of the Vault's underlying at a particular provider
   * @param _provider: address of a provider
   */
  function borrowBalance(address _provider) external view override returns (uint256) {
    return IProvider(_provider).getBorrowBalance(vAssets.borrowAsset);
  }

  /**
   * @dev Returns the deposit balance of the Vault's type collateral at a particular provider
   * @param _provider: address of a provider
   */
  function depositBalance(address _provider) external view override returns (uint256) {
    return IProvider(_provider).getDepositBalance(vAssets.collateralAsset);
  }

  /**
   * @dev Returns the total debt of a user
   * @param _user: address of a user
   * @return the total debt of a user including the protocol fee
   */
  function userDebtBalance(address _user) external view override returns (uint256) {
    uint256 debtPrincipal = IFujiERC1155(fujiERC1155).balanceOf(_user, vAssets.borrowID);
    uint256 fee = (debtPrincipal * (block.timestamp - _userFeeTimestamps[_user]) * protocolFee.a) /
      protocolFee.b /
      ONE_YEAR;

    return debtPrincipal + fee;
  }

  /**
   * @dev Returns the protocol fee of a user
   * @param _user: address of a user
   * @return the protocol fee of a user
   */
  function userProtocolFee(address _user) external view override returns (uint256) {
    uint256 debtPrincipal = IFujiERC1155(fujiERC1155).balanceOf(_user, vAssets.borrowID);
    return _userProtocolFee(_user, debtPrincipal);
  }

  /**
   * @dev Returns the collateral asset balance of a user
   * @param _user: address of a user
   * @return the collateral asset balance
   */
  function userDepositBalance(address _user) external view override returns (uint256) {
    return IFujiERC1155(fujiERC1155).balanceOf(_user, vAssets.collateralID);
  }

  /**
   * @dev Harvests the Rewards from baseLayer Protocols
   * @param _farmProtocolNum: number per VaultHarvester Contract for specific farm
   * @param _data: the additional data to be used for harvest
   */
  function harvestRewards(uint256 _farmProtocolNum, bytes memory _data) external onlyOwner {
    (address tokenReturned, IHarvester.Transaction memory harvestTransaction) = IHarvester(
      _fujiAdmin.getVaultHarvester()
    ).getHarvestTransaction(_farmProtocolNum, _data);

    // Claim rewards
    (bool success, ) = harvestTransaction.to.call(harvestTransaction.data);
    require(success, "failed to harvest rewards");

    if (tokenReturned != address(0)) {
      uint256 tokenBal = IERC20Upgradeable(tokenReturned).univBalanceOf(address(this));
      require(tokenReturned != address(0) && tokenBal > 0, Errors.VL_HARVESTING_FAILED);

      ISwapper.Transaction memory swapTransaction = ISwapper(_fujiAdmin.getSwapper())
        .getSwapTransaction(tokenReturned, vAssets.collateralAsset, tokenBal);

      // Approve rewards
      if (tokenReturned != AVAX) {
        IERC20Upgradeable(tokenReturned).univApprove(swapTransaction.to, tokenBal);
      }

      // Swap rewards -> collateralAsset
      (success, ) = swapTransaction.to.call{ value: swapTransaction.value }(swapTransaction.data);
      require(success, "failed to swap rewards");

      _deposit(
        IERC20Upgradeable(vAssets.collateralAsset).univBalanceOf(address(this)),
        address(activeProvider)
      );

      updateF1155Balances();
    }
  }

  /**
  * @dev Withdraws all the collected Fuji fees in this vault.
  * NOTE: Fuji fee is charged to all users
  * as a service for the loan cost optimization.
  * It is a percentage (defined in 'protocolFee') on top of the users 'debtPrincipal'.
  * Requirements:
  * - Must send all fees amount collected to the Fuji treasury.
  */
  function withdrawProtocolFee() external nonReentrant {
    IERC20Upgradeable(vAssets.borrowAsset).univTransfer(
      payable(IFujiAdmin(_fujiAdmin).getTreasury()),
      remainingProtocolFee
    );

    remainingProtocolFee = 0;
  }

  // Internal Functions

  /**
  * @dev Returns de amount of accrued of Fuji fee by user.
  * @param _user: user to whom Fuji fee will be computed.
  * @param _debtPrincipal: current user's debt.
  */
  function _userProtocolFee(address _user, uint256 _debtPrincipal) internal view returns (uint256) {
    return
      (_debtPrincipal * (block.timestamp - _userFeeTimestamps[_user]) * protocolFee.a) /
      protocolFee.b /
      ONE_YEAR;
  }

  /**
  * @dev Internal function handling logic for {deposit} without 'updateState' call
  * See {deposit}
  */
  function _internalDeposit(uint256 _collateralAmount) internal {
    if (vAssets.collateralAsset == AVAX) {
      require(msg.value == _collateralAmount && _collateralAmount != 0, Errors.VL_AMOUNT_ERROR);
    } else {
      require(_collateralAmount != 0, Errors.VL_AMOUNT_ERROR);
      IERC20Upgradeable(vAssets.collateralAsset).safeTransferFrom(
        msg.sender,
        address(this),
        _collateralAmount
      );
    }

    // Delegate Call Deposit to current provider
    _deposit(_collateralAmount, address(activeProvider));

    // Collateral Management
    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.collateralID, _collateralAmount);

    emit Deposit(msg.sender, vAssets.collateralAsset, _collateralAmount);
  }

  /**
  * @dev Internal function handling logic for {withdraw} without 'updateState' call
  * See {withdraw}
  */
  function _internalWithdraw(int256 _withdrawAmount) internal {
    // Get User Collateral in this Vault
    uint256 providedCollateral = IFujiERC1155(fujiERC1155).balanceOf(
      msg.sender,
      vAssets.collateralID
    );

    // Check User has collateral
    require(providedCollateral > 0, Errors.VL_INVALID_COLLATERAL);

    // Get Required Collateral with Factors to maintain debt position healthy
    uint256 neededCollateral = getNeededCollateralFor(
      IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID),
      true
    );

    uint256 amountToWithdraw = _withdrawAmount < 0
      ? providedCollateral - neededCollateral
      : uint256(_withdrawAmount);

    // Check Withdrawal amount, and that it will not fall undercollaterized.
    require(
      amountToWithdraw != 0 && providedCollateral - amountToWithdraw >= neededCollateral,
      Errors.VL_INVALID_WITHDRAW_AMOUNT
    );

    // Collateral Management before Withdraw Operation
    IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.collateralID, amountToWithdraw);

    // Delegate Call Withdraw to current provider
    _withdraw(amountToWithdraw, address(activeProvider));

    // Transer Assets to User
    IERC20Upgradeable(vAssets.collateralAsset).univTransfer(payable(msg.sender), amountToWithdraw);

    emit Withdraw(msg.sender, vAssets.collateralAsset, amountToWithdraw);
  }

  /**
  * @dev Internal function handling logic for {borrow} without 'updateState' call
  * See {borrow}
  */
  function _internalBorrow(uint256 _borrowAmount) internal {
    uint256 providedCollateral = IFujiERC1155(fujiERC1155).balanceOf(
      msg.sender,
      vAssets.collateralID
    );

    uint256 debtPrincipal = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID);
    uint256 totalBorrow = _borrowAmount + debtPrincipal;
    // Get Required Collateral with Factors to maintain debt position healthy
    uint256 neededCollateral = getNeededCollateralFor(totalBorrow, true);

    // Check Provided Collateral is not Zero, and greater than needed to maintain healthy position
    require(
      _borrowAmount != 0 && providedCollateral > neededCollateral,
      Errors.VL_INVALID_BORROW_AMOUNT
    );

    // Update timestamp for fee calculation

    uint256 userFee = (debtPrincipal *
      (block.timestamp - _userFeeTimestamps[msg.sender]) *
      protocolFee.a) /
      protocolFee.b /
      ONE_YEAR;

    _userFeeTimestamps[msg.sender] =
      block.timestamp -
      (userFee * ONE_YEAR * protocolFee.a) /
      protocolFee.b /
      totalBorrow;

    // Debt Management
    IFujiERC1155(fujiERC1155).mint(msg.sender, vAssets.borrowID, _borrowAmount);

    // Delegate Call Borrow to current provider
    _borrow(_borrowAmount, address(activeProvider));

    // Transer Assets to User
    IERC20Upgradeable(vAssets.borrowAsset).univTransfer(payable(msg.sender), _borrowAmount);

    emit Borrow(msg.sender, vAssets.borrowAsset, _borrowAmount);
  }

  /**
  * @dev Internal function handling logic for {payback} without 'updateState' call
  * See {payback}
  */
  function _internalPayback(int256 _repayAmount) internal {
    uint256 debtBalance = IFujiERC1155(fujiERC1155).balanceOf(msg.sender, vAssets.borrowID);
    uint256 userFee = _userProtocolFee(msg.sender, debtBalance);

    // Check User Debt is greater than Zero and amount is not Zero
    require(uint256(_repayAmount) > userFee && debtBalance > 0, Errors.VL_NO_DEBT_TO_PAYBACK);

    // If passed argument amount is negative do MAX
    uint256 amountToPayback = _repayAmount < 0 ? debtBalance + userFee : uint256(_repayAmount);

    if (vAssets.borrowAsset == AVAX) {
      require(msg.value >= amountToPayback, Errors.VL_AMOUNT_ERROR);
      if (msg.value > amountToPayback) {
        IERC20Upgradeable(vAssets.borrowAsset).univTransfer(
          payable(msg.sender),
          msg.value - amountToPayback
        );
      }
    } else {
      // Check User Allowance
      require(
        IERC20Upgradeable(vAssets.borrowAsset).allowance(msg.sender, address(this)) >=
          amountToPayback,
        Errors.VL_MISSING_ERC20_ALLOWANCE
      );

      // Transfer Asset from User to Vault
      IERC20Upgradeable(vAssets.borrowAsset).safeTransferFrom(
        msg.sender,
        address(this),
        amountToPayback
      );
    }

    // Delegate Call Payback to current provider
    _payback(amountToPayback - userFee, address(activeProvider));

    // Debt Management
    IFujiERC1155(fujiERC1155).burn(msg.sender, vAssets.borrowID, amountToPayback - userFee);

    // Update protocol fees
    _userFeeTimestamps[msg.sender] = block.timestamp;
    remainingProtocolFee += userFee;

    emit Payback(msg.sender, vAssets.borrowAsset, debtBalance);
  }
}