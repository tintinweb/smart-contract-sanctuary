/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// Part: Address

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// Part: IAccessControlUpgradeable

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// Part: ICurve3Pool

interface ICurve3Pool {
    function underlying_coins(uint256 _index) external returns (address);

    function coins(uint256 _index) external returns (address);

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external returns (uint256);

    function remove_liquidity(
        uint256 _amount,
        uint256[3] calldata min_amounts,
        bool use_underlying
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount,
        bool use_underlying
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);

    function pool() external view returns (address);
}

// Part: IERC165Upgradeable

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Part: IERC20

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

// Part: IGauge

interface IGauge {
    function claim_rewards() external;

    function claim_rewards(address _addr) external;

    function claim_rewards(address _addr, address _receiver) external;

    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool _claim_rewards) external;
}

// Part: IImpulseMultiStrategy

interface IImpulseMultiStrategy {
    // List underlying tokens managed by strategy
    function listUnderlying() external view returns (address[] memory);

    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens autoFarm -> strategy
    function depositInWant(uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens autoFarm -> strategy
    function depositInUnderlying(uint256[] calldata amounts) external returns (uint256);

    // Transfer want tokens strategy -> autoFarm
    function withdrawInWant(uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens strategy -> autoFarm
    function withdrawInUnderlying(uint256 _wantAmt) external returns (uint256);

    function withdrawInOneUnderlying(uint256 _wantAmt, address _underlying) external returns (uint256);

    // Calculate current price in underlying for want(LP token of pair)
    function wantPriceInUnderlying(uint256 _wantAmt) external view returns (uint256[] memory);

    // Calculate current price in usd for want(LP token of pair)
    function wantPriceInUsd(uint256 _wantAmt) external view returns (uint256);
}

// Part: IPool

interface IPool {
    function get_virtual_price() external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function coins(uint256 i) external view returns (address);
}

// Part: IUniswapV2Router01

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// Part: Initializable

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

// Part: SafeCast

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// Part: StringsUpgradeable

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// Part: ContextUpgradeable

/*
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

// Part: ERC165Upgradeable

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// Part: IERC20Metadata

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

// Part: ReentrancyGuardUpgradeable

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

// Part: SafeERC20

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

// Part: AccessControlUpgradeable

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// Part: BaseImpulseMultiStrategy

contract BaseImpulseMultiStrategy is IImpulseMultiStrategy, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");
    uint256 internal constant DUST = 1e12;

    address internal wantToken;
    IERC20[] internal underlyingTokens;
    address internal targetPoolProtocol;
    address internal targetStakingProtocol;
    uint256 internal wantTotal;
    uint256 internal totalSupplyShares;
    IERC20[] internal rewardTokens;
    /// @notice Swap router address.
    address internal router;
    // fromToken => toToken => path
    mapping(address => mapping(address => address[])) public swapRewardRoutes;

    address public treasury;
    uint256 public commission;
    uint256[] internal commissionsAccuracy;
    address public usdToken;

    event Deposit(uint256 amount, uint256 shares, uint256 wantTotal, uint256 sharesTotal);
    event Withdraw(uint256 amount, uint256 shares, uint256 wantTotal, uint256 sharesTotal);
    event Earning(uint256 earned, uint256[] commission, uint256 wantTotal, uint256 sharesTotal);
    event AdminWithdraw(address token, uint256 amount);
    event UpdateCommission(address treasury, uint256 commission);

    function initialize(
        address _wantToken,
        address[] calldata _underlyingTokens,
        address _targetPoolProtocol,
        address _targetStakingProtocol,
        address[] calldata _rewardTokens,
        address _router
    ) public virtual initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __ReentrancyGuard_init();

        underlyingTokens = new IERC20[](_underlyingTokens.length);
        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            underlyingTokens[i] = IERC20(_underlyingTokens[i]);
        }

        wantToken = _wantToken;
        targetPoolProtocol = _targetPoolProtocol;
        targetStakingProtocol = _targetStakingProtocol;
        router = _router;

        rewardTokens = new IERC20[](_rewardTokens.length);
        commissionsAccuracy = new uint256[](_rewardTokens.length);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            rewardTokens[i] = IERC20(_rewardTokens[i]);
            commissionsAccuracy[i] = 10**IERC20Metadata(_rewardTokens[i]).decimals();
        }

        _verifySetup();
    }

    /**
     * ADMIN INTERFACE
     */

    /// @notice Admin method for withdraw stuck tokens, except want.
    function adminWithdraw(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != address(wantToken), "Wrong token");
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            require(_token != address(underlyingTokens[i]), "Wrong token");
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).transfer(_msgSender(), balance);
        }
        emit AdminWithdraw(_token, balance);
    }

    /// @notice Admin method for set treasury address.
    /// @param _treasury New treasury address.
    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = _treasury;
        emit UpdateCommission(treasury, commission);
    }

    /// @notice Admin method for set treasury address.
    /// @param _commission New commission, 0 - without commission.
    function setCommission(uint256 _commission) external onlyRole(DEFAULT_ADMIN_ROLE) {
        commission = _commission;
        emit UpdateCommission(treasury, commission);
    }

    /// @notice Add route for swapping tokens.
    /// @param _path Full path for swap.
    function setRoutes(address[] memory _path) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_path.length >= 2, "wrong path");
        address from = _path[0];
        address to = _path[_path.length - 1];
        swapRewardRoutes[from][to] = _path;
    }

    /// @notice Set address of token, where balance be showed usd.
    /// @param _usdAddress Token address.
    function setUsdToken(address _usdAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        usdToken = _usdAddress;
    }

    /**
     * USER INTERFACE (FOR STAKING CONTRACT)
     */

    // Transfer want tokens autoFarm -> strategy
    function depositInWant(uint256 _wantAmt) external override nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256) {
        IERC20(wantToken).safeTransferFrom(msg.sender, address(this), _wantAmt);
        return _deposit(_wantAmt);
    }

    // Transfer want tokens autoFarm -> strategy
    function depositInUnderlying(uint256[] calldata _amounts) external override nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256) {
        require(_amounts.length == underlyingTokens.length, "deposit, wrong amounts");
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            if (_amounts[i] != 0) {
                IERC20(underlyingTokens[i]).safeTransferFrom(_msgSender(), address(this), _amounts[i]);
            }
        }
        return _deposit(_swapAllUnderlyingToWant());
    }

    // Transfer want tokens strategy -> autoFarm
    function withdrawInWant(uint256 _wantAmt) external override nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256) {
        require(_wantAmt <= wantTotal && _wantAmt > 0, "withdraw, wrong value");
        uint256 shares = _withdraw(_wantAmt, _msgSender());
        emit Withdraw(_wantAmt, shares, wantTotal, totalSupplyShares);
        return shares;
    }

    // Transfer want tokens strategy -> autoFarm
    function withdrawInUnderlying(uint256 _wantAmt) external override nonReentrant onlyRole(STRATEGIST_ROLE) returns (uint256) {
        require(_wantAmt <= wantTotal && _wantAmt > 0, "withdraw, wrong value");
        uint256 shares = _withdraw(_wantAmt, address(this));
        _swapAllWantTolUnderlying(_msgSender());
        emit Withdraw(0, shares, wantTotal, totalSupplyShares);
        return shares;
    }

    function withdrawInOneUnderlying(uint256 _wantAmt, address _underlying)
        external
        override
        nonReentrant
        onlyRole(STRATEGIST_ROLE)
        returns (uint256)
    {
        require(_wantAmt <= wantTotal && _wantAmt > 0, "withdraw, wrong value");
        require(_validateToken(_underlying), "Wrong underlying provided!");

        uint256 shares = _withdraw(_wantAmt, address(this));
        _swapAllWantToOneUnderlying(_msgSender(), _underlying);

        emit Withdraw(0, shares, wantTotal, totalSupplyShares);
        return shares;
    }

    // Total want tokens managed by stratfegy
    function wantLockedTotal() external view override returns (uint256) {
        return wantTotal;
    }

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view override returns (uint256) {
        return totalSupplyShares;
    }

    // List underlying tokens managed by strategy
    function listUnderlying() external view override returns (address[] memory) {
        address[] memory result = new address[](underlyingTokens.length);
        for (uint256 u = 0; u < underlyingTokens.length; u++) {
            result[u] = address(underlyingTokens[u]);
        }
        return result;
    }

    // Calculate current price in underlying for want(LP token of pair)
    /// @param _wantAmt Shares amount.
    /// @return Price of shares in underlyings.
    function wantPriceInUnderlying(uint256 _wantAmt) public view virtual override returns (uint256[] memory) {
        uint256[] memory result = new uint256[](underlyingTokens.length);
        return result;
    }

    // Calculate current price in usd for want(LP token of pair)
    /// @param _wantAmt Shares amount.
    /// @return Price of shares in usd.
    function wantPriceInUsd(uint256 _wantAmt) external view virtual override returns (uint256) {}

    /**
     * BACKEND SERVICE INTERFACE
     */

    // Main want token compounding function
    function earn() external virtual override nonReentrant onlyRole(BACKEND_ROLE) {
        _getRewards();
        uint256[] memory rewardBalances = new uint256[](rewardTokens.length);

        bool enough = false;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            rewardBalances[i] = rewardTokens[i].balanceOf(address(this));
            if (!enough && rewardBalances[i] > DUST) {
                enough = true;
            }
        }

        uint256 wantEarned = 0;
        uint256[] memory rewardCommissions = new uint256[](rewardTokens.length);

        if (enough) {
            if (commission > 0 && treasury != address(0)) {
                for (uint256 i = 0; i < rewardTokens.length; i++) {
                    if (rewardBalances[i] > DUST) {
                        rewardCommissions[i] = (rewardBalances[i] * commission) / commissionsAccuracy[i];
                        rewardBalances[i] = rewardBalances[i] - rewardCommissions[i];
                        rewardTokens[i].transfer(treasury, rewardCommissions[i]);
                    }
                }
            }

            _swapRewardsToUnderlings(rewardBalances);
            wantEarned = _swapAllUnderlyingToWant();
            _depositLpToken(wantEarned);
            wantTotal = wantTotal + wantEarned;
        }

        emit Earning(wantEarned, rewardCommissions, wantTotal, totalSupplyShares);
    }

    /// @notice Swaps reward tokens to want token.
    /// @param _amount Amount of reward token.
    function _swapTokens(address[] memory path, uint256 _amount) internal virtual {
        IUniswapV2Router01(router).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp + 1)[path.length - 1];
    }

    /// @notice Swap rewards tokens to underlying tokens.
    /// @param _rewardAmts Amount of rewards token.
    function _swapRewardsToUnderlings(uint256[] memory _rewardAmts) internal virtual {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (_rewardAmts[i] > 0) {
                rewardTokens[i].safeApprove(router, 0);
                rewardTokens[i].safeApprove(router, _rewardAmts[i]);
                uint256 countUnderlying = underlyingTokens.length;
                for (uint256 u = 0; u < countUnderlying; u++) {
                    _swapTokens(swapRewardRoutes[address(rewardTokens[i])][address(underlyingTokens[u])], _rewardAmts[i] / countUnderlying);
                }
            }
        }
    }

    /// @notice Deposit want token to staking contract.
    /// @param _wantAmt Amount of want token.
    function _depositLpToken(uint256 _wantAmt) internal virtual {
        IERC20(wantToken).approve(targetStakingProtocol, 0);
        IERC20(wantToken).approve(targetStakingProtocol, _wantAmt);
        IGauge(targetStakingProtocol).deposit(_wantAmt);
    }

    /// @notice Withdraw want token from staking contract.
    /// @param _wantAmt Amount of want token.
    function _withdrawLpToken(uint256 _wantAmt) internal virtual {
        IGauge(targetStakingProtocol).withdraw(_wantAmt);
    }

    /// @notice Get rewards from staking contract.
    function _getRewards() internal virtual {
        IGauge(targetStakingProtocol).claim_rewards(address(this));
    }

    /// @notice Swap all underlying tokens to want tokens.
    /// @return Want received amount.
    function _swapAllUnderlyingToWant() internal virtual returns (uint256) {}

    /// @notice Swap all underlying tokens to want tokens.
    function _swapAllWantTolUnderlying(address _receiver) internal virtual {}

    function _swapAllWantToOneUnderlying(address _receiver, address _underlying) internal virtual {}

    /// @notice Verify constant data, provided on initialize.
    function _verifySetup() internal virtual {}

    // Transfer want tokens autoFarm -> strategy
    function _deposit(uint256 _wantAmt) internal virtual returns (uint256) {
        uint256 shares = 0;
        _depositLpToken(_wantAmt);
        if (totalSupplyShares == 0) {
            shares = _wantAmt;
        } else {
            shares = shares + ((_wantAmt * totalSupplyShares) / wantTotal);
        }
        wantTotal += _wantAmt;
        totalSupplyShares += shares;

        emit Deposit(_wantAmt, shares, wantTotal, totalSupplyShares);
        return shares;
    }

    // Transfer want tokens strategy -> autoFarm
    function _withdraw(uint256 _wantAmt, address _receiver) internal virtual returns (uint256) {
        require(_wantAmt <= wantTotal && _wantAmt > 0, "withdraw, wrong value");
        require(_receiver != address(0), "withdraw, wrong value");
        uint256 shares = 0;
        _withdrawLpToken(_wantAmt);
        if (_receiver != address(this)) {
            IERC20(wantToken).safeTransfer(_receiver, _wantAmt);
        }
        shares = (_wantAmt * totalSupplyShares) / wantTotal;

        wantTotal -= _wantAmt;
        totalSupplyShares -= shares;
        return shares;
    }

    function _validateToken(address _underlying) internal view returns (bool) {
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            if (_underlying == address(underlyingTokens[i])) {
                return true;
            }
        }
        return false;
    }
}

// File: ImpulseCurve3Pool.sol

contract ImpulseCurve3Pool is BaseImpulseMultiStrategy {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int128;
    using SafeCast for int256;

    uint256 public constant UNDERLYING_COUNT = 3;

    function initialize(
        address _wantToken,
        address[] calldata _underlyingTokens,
        address _targetPoolProtocol,
        address _targetStakingProtocol,
        address[] calldata _rewardTokens,
        address _router
    ) public override initializer {
        super.initialize(_wantToken, _underlyingTokens, _targetPoolProtocol, _targetStakingProtocol, _rewardTokens, _router);
    }

    // Calculate current price in underlying for want(LP token of pair)
    /// @param _wantAmt Shares amount.
    /**
     * @return Array with 3 elements which represent want tokens price in underlyings.
     * First element is DAI amount on Polygon or WXDAI amount on xDai.
     * Second element is USDC amount.
     * Third element us USDT amount.
     */
    function wantPriceInUnderlying(uint256 _wantAmt) public view override returns (uint256[] memory) {
        uint256[] memory result = new uint256[](UNDERLYING_COUNT);
        uint256 totalSupply = IERC20(wantToken).totalSupply();
        // // Calculate amounts of first 3 coins (DAI, USDC, USDT) in Aave pool and WXDAI, USDC, USDT in 3Pool.
        for (uint256 i = 0; i < 3; i++) {
            uint256 balance = IPool(targetPoolProtocol).balances(i);
            result[i] = (_wantAmt * balance) / totalSupply;
        }
        return result;
    }

    // Calculate current price in usd for want(LP token of pair)
    /// @param _wantAmt Shares amount.
    /// @return Price of shares in usd(with 18 decimals).
    function wantPriceInUsd(uint256 _wantAmt) external view virtual override returns (uint256) {
        uint256[] memory underlyingAmounts = wantPriceInUnderlying(_wantAmt);
        uint256 wantPrice = 0;
        // Price of stablecoins
        for (uint256 i = 0; i < 3; i++) {
            uint256 decimals = IERC20Metadata(address(underlyingTokens[i])).decimals();
            if (decimals < 18) {
                underlyingAmounts[i] = underlyingAmounts[i] * (10**(18 - decimals));
            }
            wantPrice += underlyingAmounts[i];
        }
        return wantPrice;
    }

    function _swapAllUnderlyingToWant() internal virtual override returns (uint256) {
        uint256 countUnderlying = underlyingTokens.length;
        uint256[UNDERLYING_COUNT] memory amounts;
        for (uint256 i = 0; i < countUnderlying; i++) {
            amounts[i] = IERC20(underlyingTokens[i]).balanceOf(address(this));
            IERC20(underlyingTokens[i]).safeApprove(targetPoolProtocol, 0);
            IERC20(underlyingTokens[i]).safeApprove(targetPoolProtocol, amounts[i]);
        }
        uint256 wantBalanceBefore = IERC20(wantToken).balanceOf(address(this));
        // Order of amounts was verified in  _verifySetup
        if (targetPoolProtocol == address(0x445FE580eF8d70FF569aB36e80c647af338db351)) {
            //Curve Aave pool contract address on Polygon
            ICurve3Pool(targetPoolProtocol).add_liquidity(amounts, 0, true);
        } else if (targetPoolProtocol == address(0x7f90122BF0700F9E7e1F688fe926940E8839F353)) {
            //Curve 3Pool contract address on xDai
            ICurve3Pool(targetPoolProtocol).add_liquidity(amounts, 0);
        }
        return IERC20(wantToken).balanceOf(address(this)) - wantBalanceBefore;
    }

    function _swapAllWantTolUnderlying(address _receiver) internal virtual override {
        uint256 wantAmount = IERC20(wantToken).balanceOf(address(this));
        if (wantAmount > 0) {
            uint256[UNDERLYING_COUNT] memory amounts3Pool;
            IERC20(wantToken).safeApprove(targetPoolProtocol, wantAmount);
            if (targetPoolProtocol == address(0x445FE580eF8d70FF569aB36e80c647af338db351)) {
                //Curve Aave pool contract address on Polygon
                ICurve3Pool(targetPoolProtocol).remove_liquidity(wantAmount, amounts3Pool, true);
            } else if (targetPoolProtocol == address(0x7f90122BF0700F9E7e1F688fe926940E8839F353)) {
                //Curve 3Pool contract address on xDai
                ICurve3Pool(targetPoolProtocol).remove_liquidity(wantAmount, amounts3Pool);
            }
            for (uint256 i = 0; i < underlyingTokens.length; i++) {
                IERC20(underlyingTokens[i]).safeTransfer(_receiver, IERC20(underlyingTokens[i]).balanceOf(address(this)));
            }
        }
    }

    function _swapAllWantToOneUnderlying(address _receiver, address _underlying) internal virtual override {
        uint256 index;
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            if (address(underlyingTokens[i]) == _underlying) {
                index = i;
                break;
            }
        }

        uint256 wantAmount = IERC20(wantToken).balanceOf(address(this));
        if (wantAmount > 0) {
            IERC20(wantToken).safeApprove(targetPoolProtocol, 0);
            IERC20(wantToken).safeApprove(targetPoolProtocol, wantAmount);
            int128 index128 = index.toInt256().toInt128();
            if (targetPoolProtocol == address(0x445FE580eF8d70FF569aB36e80c647af338db351)) {
                //Curve Aave pool contract address on Polygon
                ICurve3Pool(targetPoolProtocol).remove_liquidity_one_coin(wantAmount, index128, 0, true);
            } else if (targetPoolProtocol == address(0x7f90122BF0700F9E7e1F688fe926940E8839F353)) {
                //Curve 3Pool contract address on xDai
                ICurve3Pool(targetPoolProtocol).remove_liquidity_one_coin(wantAmount, index128, 0);
            }
            IERC20(_underlying).safeTransfer(_receiver, IERC20(_underlying).balanceOf(address(this)));
        }
    }

    function _verifySetup() internal virtual override {
        require(underlyingTokens.length == UNDERLYING_COUNT, "Wrong underlying");
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            // Check order of underlying
            if (targetPoolProtocol == address(0x445FE580eF8d70FF569aB36e80c647af338db351)) {
                //Curve Aave pool contract address on Polygon
                require(ICurve3Pool(targetPoolProtocol).underlying_coins(i) == address(underlyingTokens[i]), "Wrong underlying");
            } else if (targetPoolProtocol == address(0x7f90122BF0700F9E7e1F688fe926940E8839F353)) {
                //Curve 3Pool contract address on xDai
                require(ICurve3Pool(targetPoolProtocol).coins(i) == address(underlyingTokens[i]), "Wrong underlying");
            }
        }
    }
}