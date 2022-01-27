/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// Verified using https://dapp.tools

// hevm: flattened sources of contracts/AloeBlend.sol
// SPDX-License-Identifier: AGPL-3.0-only AND MIT AND GPL-2.0-or-later
pragma solidity >=0.5.0 >=0.8.0 >=0.8.0 <0.9.0 >=0.8.10 <0.9.0;

////// lib/solmate/src/tokens/ERC20.sol
/* pragma solidity >=0.8.0; */

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

////// contracts/AloeBlendERC20.sol
/* pragma solidity ^0.8.10; */

/* import "@rari-capital/solmate/src/tokens/ERC20.sol"; */

contract AloeBlendERC20 is ERC20 {
    // solhint-disable no-empty-blocks
    constructor(string memory _name) ERC20(_name, "ALOE-BLEND", 18) {}
}

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

/* pragma solidity ^0.8.0; */

/* import "../IERC20.sol"; */
/* import "../../../utils/Address.sol"; */

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

////// lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol
/* pragma solidity >=0.5.0; */

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

////// lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolDerivedState.sol
/* pragma solidity >=0.5.0; */

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

////// lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolEvents.sol
/* pragma solidity >=0.5.0; */

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

////// lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol
/* pragma solidity >=0.5.0; */

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

////// lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolOwnerActions.sol
/* pragma solidity >=0.5.0; */

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

////// lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol
/* pragma solidity >=0.5.0; */

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

////// lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol
/* pragma solidity >=0.5.0; */

/* import './pool/IUniswapV3PoolImmutables.sol'; */
/* import './pool/IUniswapV3PoolState.sol'; */
/* import './pool/IUniswapV3PoolDerivedState.sol'; */
/* import './pool/IUniswapV3PoolActions.sol'; */
/* import './pool/IUniswapV3PoolOwnerActions.sol'; */
/* import './pool/IUniswapV3PoolEvents.sol'; */

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

////// lib/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol
/* pragma solidity >=0.5.0; */

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

////// contracts/UniswapHelper.sol
/* pragma solidity ^0.8.10; */

/* import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; */
/* import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; */

/* import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol"; */
/* import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol"; */

contract UniswapHelper is IUniswapV3MintCallback {
    using SafeERC20 for IERC20;

    /// @notice The Uniswap pair in which the vault will manage positions
    IUniswapV3Pool public immutable UNI_POOL;

    /// @notice The first token of the Uniswap pair
    IERC20 public immutable TOKEN0;

    /// @notice The second token of the Uniswap pair
    IERC20 public immutable TOKEN1;

    /// @dev The Uniswap pair's tick spacing
    int24 internal immutable TICK_SPACING;

    constructor(IUniswapV3Pool _pool) {
        UNI_POOL = _pool;
        TOKEN0 = IERC20(_pool.token0());
        TOKEN1 = IERC20(_pool.token1());
        TICK_SPACING = _pool.tickSpacing();
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3MintCallback(
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata
    ) external {
        require(msg.sender == address(UNI_POOL));
        if (_amount0 != 0) TOKEN0.safeTransfer(msg.sender, _amount0);
        if (_amount1 != 0) TOKEN1.safeTransfer(msg.sender, _amount1);
    }
}

////// contracts/interfaces/IAloeBlendActions.sol
/* pragma solidity ^0.8.10; */

interface IAloeBlendActions {
    /**
     * @notice Deposits tokens in proportion to the vault's current holdings
     * @dev These tokens sit in the vault and are not used as liquidity
     * until the next rebalance. Also note it's not necessary to check
     * if user manipulated price to deposit cheaper, as the value of range
     * orders can only by manipulated higher.
     * @param amount0Max Max amount of TOKEN0 to deposit
     * @param amount1Max Max amount of TOKEN1 to deposit
     * @param amount0Min Ensure `amount0` is greater than this
     * @param amount1Min Ensure `amount1` is greater than this
     * @return shares Number of shares minted
     * @return amount0 Amount of TOKEN0 deposited
     * @return amount1 Amount of TOKEN1 deposited
     */
    function deposit(
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice Withdraws tokens in proportion to the vault's current holdings
     * @param shares Shares burned by sender
     * @param amount0Min Revert if resulting `amount0` is smaller than this
     * @param amount1Min Revert if resulting `amount1` is smaller than this
     * @return amount0 Amount of token0 sent to recipient
     * @return amount1 Amount of token1 sent to recipient
     */
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Rebalances vault to maintain 50/50 inventory ratio
     * @dev `rewardToken` may be something other than token0 or token1, in which case the available maintenance budget
     * is equal to the contract's balance. Also note that this will revert unless both silos report that removal of
     * `rewardToken` is allowed. For example, a Compound silo would block removal of its cTokens.
     * @param rewardToken The ERC20 token in which the reward should be denominated. If `rewardToken` is the 0 address,
     * no reward will be given. Otherwise, the reward is based on (a) time elapsed since primary position last moved
     * and (b) the contract's estimate of how much each unit of gas costs. Since (b) is fully determined by past
     * contract interactions and is known to all participants, (a) creates a Dutch Auction for calling this function.
     */
    function rebalance(address rewardToken) external;
}

////// contracts/interfaces/IAloeBlendDerivedState.sol
/* pragma solidity ^0.8.10; */

interface IAloeBlendDerivedState {
    /**
     * @notice Calculates the rebalance urgency. Caller's reward is proportional to this value.
     * @return urgency How badly the vault wants its `rebalance()` function to be called
     */
    function getRebalanceUrgency() external view returns (uint32 urgency);

    /**
     * @notice Estimate's the vault's liabilities to users -- in other words, how much would be paid out if all
     * holders redeemed their shares at once.
     * @dev Underestimates the true payout unless both silos and Uniswap positions have just been poked. Also
     * assumes that the maximum amount will accrue to the maintenance budget during the next `rebalance()`. If
     * it takes less than that for the budget to reach capacity, then the values reported here may increase after
     * calling `rebalance()`.
     * @return inventory0 The amount of token0 underlying all shares
     * @return inventory1 The amount of token1 underlying all shares
     */
    function getInventory() external view returns (uint256 inventory0, uint256 inventory1);
}

////// contracts/interfaces/IAloeBlendEvents.sol
/* pragma solidity ^0.8.10; */

interface IAloeBlendEvents {
    /**
     * @notice Emitted every time someone deposits to the vault
     * @param sender The address that deposited to the vault
     * @param shares The shares that were minted and sent to `sender`
     * @param amount0 The amount of token0 that `sender` paid in exchange for `shares`
     * @param amount1 The amount of token1 that `sender` paid in exchange for `shares`
     */
    event Deposit(address indexed sender, uint256 shares, uint256 amount0, uint256 amount1);

    /**
     * @notice Emitted every time someone withdraws from the vault
     * @param sender The address that withdrew from the vault
     * @param shares The shares that were taken from `sender` and burned
     * @param amount0 The amount of token0 that `sender` received in exchange for `shares`
     * @param amount1 The amount of token1 that `sender` received in exchange for `shares`
     */
    event Withdraw(address indexed sender, uint256 shares, uint256 amount0, uint256 amount1);

    /**
     * @notice Emitted every time the vault is rebalanced. Contains general vault data.
     * @param ratio The ratio of value held as token0 to total value,
     * i.e. `inventory0 / (inventory0 + inventory1 / price)`
     * @param shares The total outstanding shares held by depositers
     * @param inventory0 The amount of token0 underlying all shares
     * @param inventory1 The amount of token1 underlying all shares
     */
    event Rebalance(uint256 ratio, uint256 shares, uint256 inventory0, uint256 inventory1);

    /**
     * @notice Emitted every time the primary Uniswap position is recentered
     * @param lower The lower bound of the new primary Uniswap position
     * @param upper The upper bound of the new primary Uniswap position
     */
    event Recenter(int24 lower, int24 upper);

    /**
     * @notice Emitted every time the vault is rebalanced. Contains incentivization data.
     * @param token The ERC20 token in which caller rewards were denominated
     * @param amount The amount of `token` that was sent to caller
     * @param urgency The rebalance urgency when this payout occurred
     */
    event Reward(address token, uint256 amount, uint32 urgency);
}

////// contracts/interfaces/ISilo.sol
/* pragma solidity ^0.8.10; */

interface ISilo {
    /// @notice A descriptive name for the silo (ex: Compound USDC Silo)
    function name() external view returns (string memory);

    /// @notice A place to update the silo's internal state
    /// @dev After this has been called, balances reported by `balanceOf` MUST be correct
    function poke() external;

    /// @notice Deposits `amount` of the underlying token
    function deposit(uint256 amount) external;

    /// @notice Withdraws EXACTLY `amount` of the underlying token
    function withdraw(uint256 amount) external;

    /// @notice Reports how much of the underlying token `account` has stored
    /// @dev Must never overestimate `balance`. Should give the exact, correct value after `poke` is called
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice Whether the given token is irrelevant to the silo's strategy (`shouldAllow = true`) or
     * is required for proper management (`shouldAllow = false`). ex: Compound silos shouldn't allow
     * removal of cTokens, but the may allow removal of COMP rewards.
     * @dev Removed tokens are used to help incentivize rebalances for the Blend vault that uses the silo. So
     * if you want something like COMP rewards to go to Blend *users* instead, you'd have to implement a
     * trading function as part of `poke()` to convert COMP to the underlying token.
     */
    function shouldAllowRemovalOf(address token) external view returns (bool shouldAllow);
}

////// contracts/interfaces/IVolatilityOracle.sol
/* pragma solidity ^0.8.10; */

/* import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol"; */

interface IVolatilityOracle {
    /**
     * @notice Accesses the most recently stored metadata for a given Uniswap pool
     * @dev These values may or may not have been initialized and may or may not be
     * up to date. `tickSpacing` will be non-zero if they've been initialized.
     * @param pool The Uniswap pool for which metadata should be retrieved
     * @return maxSecondsAgo The age of the oldest observation in the pool's oracle
     * @return gamma0 The pool fee minus the protocol fee on token0, scaled by 1e6
     * @return gamma1 The pool fee minus the protocol fee on token1, scaled by 1e6
     * @return tickSpacing The pool's tick spacing
     */
    function cachedPoolMetadata(IUniswapV3Pool pool)
        external
        view
        returns (
            uint32 maxSecondsAgo,
            uint24 gamma0,
            uint24 gamma1,
            int24 tickSpacing
        );

    /**
     * @notice Accesses any of the 25 most recently stored fee growth structs
     * @dev The full array (idx=0,1,2...24) has data that spans *at least* 24 hours
     * @param pool The Uniswap pool for which fee growth should be retrieved
     * @param idx The index into the storage array
     * @return feeGrowthGlobal0X128 Total pool revenue in token0, as of timestamp
     * @return feeGrowthGlobal1X128 Total pool revenue in token1, as of timestamp
     * @return timestamp The time at which snapshot was taken and stored
     */
    function feeGrowthGlobals(IUniswapV3Pool pool, uint256 idx)
        external
        view
        returns (
            uint256 feeGrowthGlobal0X128,
            uint256 feeGrowthGlobal1X128,
            uint32 timestamp
        );

    /**
     * @notice Returns indices that the contract will use to access `feeGrowthGlobals`
     * @param pool The Uniswap pool for which array indices should be fetched
     * @return read The index that was closest to 24 hours old last time `estimate24H` was called
     * @return write The index that was written to last time `estimate24H` was called
     */
    function feeGrowthGlobalsIndices(IUniswapV3Pool pool) external view returns (uint8 read, uint8 write);

    /**
     * @notice Updates cached metadata for a Uniswap pool. Must be called at least once
     * in order for volatility to be determined. Should also be called whenever
     * protocol fee changes
     * @param pool The Uniswap pool to poke
     */
    function cacheMetadataFor(IUniswapV3Pool pool) external;

    /**
     * @notice Provides multiple estimates of IV using all stored `feeGrowthGlobals` entries for `pool`
     * @dev This is not meant to be used on-chain, and it doesn't contribute to the oracle's knowledge.
     * Please use `estimate24H` instead.
     * @param pool The pool to use for volatility estimate
     * @return IV The array of volatility estimates, scaled by 1e18
     */
    function lens(IUniswapV3Pool pool) external returns (uint256[25] memory IV);

    /**
     * @notice Estimates 24-hour implied volatility for a Uniswap pool.
     * @param pool The pool to use for volatility estimate
     * @return IV The estimated volatility, scaled by 1e18
     */
    function estimate24H(IUniswapV3Pool pool) external returns (uint256 IV);
}

////// contracts/interfaces/IAloeBlendImmutables.sol
/* pragma solidity ^0.8.10; */

/* import "./ISilo.sol"; */
/* import "./IVolatilityOracle.sol"; */

// solhint-disable func-name-mixedcase
interface IAloeBlendImmutables {
    /// @notice The nominal time (in seconds) that the primary Uniswap position should stay in one place before
    /// being recentered
    function RECENTERING_INTERVAL() external view returns (uint24);

    /// @notice The minimum width (in ticks) of the primary Uniswap position
    function MIN_WIDTH() external view returns (int24);

    /// @notice The maximum width (in ticks) of the primary Uniswap position
    function MAX_WIDTH() external view returns (int24);

    /// @notice The maintenance budget buffer multiplier
    /// @dev The vault will attempt to build up a maintenance budget equal to the average cost of rebalance
    /// incentivization, multiplied by K.
    function K() external view returns (uint8);

    /// @notice If the maintenance budget drops below [its maximum size ➗ this value], `maintenanceIsSustainable` will
    /// become false. During the next rebalance, this will cause the primary Uniswap position to expand to its maximum
    /// width -- de-risking the vault until it has time to rebuild the maintenance budget.
    function L() external view returns (uint8);

    /// @notice The number of standard deviations (from volatilityOracle) to +/- from mean when choosing
    /// range for primary Uniswap position
    function B() external view returns (uint8);

    /// @notice The constraint factor for new gas price observations. The new observation cannot be less than (1 - 1/D)
    /// times the previous average.
    function D() external view returns (uint8);

    /// @notice The denominator applied to all earnings to determine what portion goes to maintenance budget
    /// @dev For example, if this is 10, then *at most* 1/10th of all revenue will be added to the maintenance budget.
    function MAINTENANCE_FEE() external view returns (uint8);

    /// @notice The percentage of funds (in basis points) that will be left in the contract after the primary Uniswap
    /// position is recentered. If your share of the pool is <<< than this, withdrawals will be more gas efficient.
    /// Also makes it less gassy to place limit orders.
    function FLOAT_PERCENTAGE() external view returns (uint256);

    /// @notice The volatility oracle used to decide position width
    function volatilityOracle() external view returns (IVolatilityOracle);

    /// @notice The silo where excess token0 is stored to earn yield
    function silo0() external view returns (ISilo);

    /// @notice The silo where excess token1 is stored to earn yield
    function silo1() external view returns (ISilo);
}

////// contracts/interfaces/IAloeBlendState.sol
/* pragma solidity ^0.8.10; */

/* import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol"; */

interface IAloeBlendState {
    /**
     * @notice A variety of key parameters used frequently in the vault's code, stored in a single slot to save gas
     * @dev If lower and upper bounds of a Uniswap position are equal, then the vault hasn't deposited liquidity to it
     * @return primaryLower The primary position's lower tick bound
     * @return primaryUpper The primary position's upper tick bound
     * @return limitLower The limit order's lower tick bound
     * @return limitUpper The limit order's upper tick bound
     * @return recenterTimestamp The `block.timestamp` from the last time the primary position moved
     * @return maxRebalanceGas The (approximate) maximum amount of gas that has ever been used to `rebalance()` this vault
     * @return maintenanceIsSustainable Whether `maintenanceBudget0` or `maintenanceBudget1` has filled up according to `K`
     * @return locked Whether the vault is currently locked to reentrancy
     */
    function packedSlot()
        external
        view
        returns (
            int24 primaryLower,
            int24 primaryUpper,
            int24 limitLower,
            int24 limitUpper,
            uint48 recenterTimestamp,
            uint32 maxRebalanceGas,
            bool maintenanceIsSustainable,
            bool locked
        );

    /// @notice The amount of token0 that was in silo0 last time maintenanceBudget0 was updated
    function silo0Basis() external view returns (uint256);

    /// @notice The amount of token1 that was in silo1 last time maintenanceBudget1 was updated
    function silo1Basis() external view returns (uint256);

    /// @notice The amount of token0 available for `rebalance()` rewards
    function maintenanceBudget0() external view returns (uint256);

    /// @notice The amount of token1 available for `rebalance()` rewards
    function maintenanceBudget1() external view returns (uint256);

    /**
     * @notice The contract's opinion on the fair value of 1e4 units of gas, denominated in `_token`
     * @dev The value reported here is an average over 14 samples. Nominally there is 1 sample per day, but actual
     * timing isn't stored. Please do not use this as more than a low fidelity approximation/proxy for truth.
     * @param token The ERC20 token for which the average gas price should be retrieved
     * @return gasPrice The amount of `_token` that may motivate expenditure of 1e4 units of gas
     */
    function gasPrices(address token) external view returns (uint256 gasPrice);
}

////// contracts/interfaces/IAloeBlend.sol
/* pragma solidity ^0.8.10; */

/* import "./IAloeBlendActions.sol"; */
/* import "./IAloeBlendDerivedState.sol"; */
/* import "./IAloeBlendEvents.sol"; */
/* import "./IAloeBlendImmutables.sol"; */
/* import "./IAloeBlendState.sol"; */

// solhint-disable no-empty-blocks
/// @title Aloe Blend vault interface
/// @dev The interface is broken up into many smaller pieces
interface IAloeBlend is
    IAloeBlendActions,
    IAloeBlendDerivedState,
    IAloeBlendEvents,
    IAloeBlendImmutables,
    IAloeBlendState
{

}

////// contracts/interfaces/IFactory.sol
/* pragma solidity ^0.8.10; */

/* import "./IAloeBlend.sol"; */
/* import "./ISilo.sol"; */
/* import "./IVolatilityOracle.sol"; */

interface IFactory {
    /// @notice The address of the volatility oracle
    function volatilityOracle() external view returns (IVolatilityOracle);

    /// @notice Reports the vault's address (if one exists for the chosen parameters)
    function getVault(
        IUniswapV3Pool pool,
        ISilo silo0,
        ISilo silo1
    ) external view returns (IAloeBlend);

    /// @notice Reports whether the given vault was deployed by this factory
    function didCreateVault(IAloeBlend vault) external view returns (bool);

    /// @notice Creates a new Blend vault for the given pool + silo combination
    function createVault(
        IUniswapV3Pool pool,
        ISilo silo0,
        ISilo silo1
    ) external returns (IAloeBlend);
}

////// contracts/libraries/FullMath.sol
/* pragma solidity ^0.8.10; */

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // Handle division by zero
        require(denominator != 0);

        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Short circuit 256 by 256 division
        // This saves gas when a * b is small, at the cost of making the
        // large case a bit more expensive. Depending on your use case you
        // may want to remove this short circuit and always go through the
        // 512 bit path.
        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Handle overflow, the result must be < 2**256
        require(prod1 < denominator);

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        // Note mulmod(_, _, 0) == 0
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            // https://ethereum.stackexchange.com/a/96646
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            // If denominator is zero the inverse starts with 2
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256
            // If denominator is zero, inv is now 128

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

////// contracts/libraries/Silo.sol
/* pragma solidity ^0.8.10; */

/* import "@openzeppelin/contracts/utils/Address.sol"; */

/* import "contracts/interfaces/ISilo.sol"; */

library Silo {
    using Address for address;

    function delegate_poke(ISilo silo) internal {
        address(silo).functionDelegateCall(abi.encodeWithSelector(silo.poke.selector));
    }

    function delegate_deposit(ISilo silo, uint256 amount) internal {
        address(silo).functionDelegateCall(abi.encodeWithSelector(silo.deposit.selector, amount));
    }

    function delegate_withdraw(ISilo silo, uint256 amount) internal {
        address(silo).functionDelegateCall(abi.encodeWithSelector(silo.withdraw.selector, amount));
    }
}

////// contracts/libraries/TickMath.sol
/* pragma solidity ^0.8.10; */

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        unchecked {
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }

    /// @notice Rounds down to the nearest tick where tick % tickSpacing == 0
    /// @param tick The tick to round
    /// @param tickSpacing The tick spacing to round to
    /// @return the floored tick
    /// @dev Ensure tick +/- tickSpacing does not overflow or underflow int24
    function floor(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 mod = tick % tickSpacing;

        unchecked {
            if (mod >= 0) return tick - mod;
            return tick - mod - tickSpacing;
        }
    }

    /// @notice Rounds up to the nearest tick where tick % tickSpacing == 0
    /// @param tick The tick to round
    /// @param tickSpacing The tick spacing to round to
    /// @return the ceiled tick
    /// @dev Ensure tick +/- tickSpacing does not overflow or underflow int24
    function ceil(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 mod = tick % tickSpacing;

        unchecked {
            if (mod > 0) return tick - mod + tickSpacing;
            return tick - mod;
        }
    }
}

////// contracts/libraries/FixedPoint128.sol
/* pragma solidity ^0.8.10; */

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

////// contracts/libraries/FixedPoint96.sol
/* pragma solidity ^0.8.10; */

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

////// contracts/libraries/LiquidityAmounts.sol
/* pragma solidity ^0.8.10; */

/* import "./FixedPoint96.sol"; */
/* import "./FullMath.sol"; */

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        liquidity = toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        liquidity = toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0. Will fit in a uint224 if you need it to
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        amount0 =
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) /
            sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1. Will fit in a uint192 if you need it to
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        amount1 = FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

////// contracts/libraries/Uniswap.sol
/* pragma solidity ^0.8.10; */

/* import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol"; */

/* import "./FixedPoint128.sol"; */
/* import "./LiquidityAmounts.sol"; */
/* import "./TickMath.sol"; */

library Uniswap {
    struct Position {
        // The pool the position is in
        IUniswapV3Pool pool;
        // Lower tick of the position
        int24 lower;
        // Upper tick of the position
        int24 upper;
    }

    /// @dev Do zero-burns to poke the Uniswap pools so earned fees are updated
    function poke(Position memory position) internal {
        if (position.lower == position.upper) return;
        (uint128 liquidity, , , , ) = info(position);
        if (liquidity != 0) {
            position.pool.burn(position.lower, position.upper, 0);
        }
    }

    /// @dev Deposits liquidity in a range on the Uniswap pool.
    function deposit(Position memory position, uint128 liquidity) internal returns (uint256 amount0, uint256 amount1) {
        if (liquidity != 0) {
            (amount0, amount1) = position.pool.mint(address(this), position.lower, position.upper, liquidity, "");
        }
    }

    /// @dev Withdraws all liquidity and collects all fees
    function withdraw(Position memory position, uint128 liquidity)
        internal
        returns (
            uint256 burned0,
            uint256 burned1,
            uint256 earned0,
            uint256 earned1
        )
    {
        if (liquidity != 0) {
            (burned0, burned1) = position.pool.burn(position.lower, position.upper, liquidity);
        }

        // Collect all owed tokens including earned fees
        (uint256 collected0, uint256 collected1) = position.pool.collect(
            address(this),
            position.lower,
            position.upper,
            type(uint128).max,
            type(uint128).max
        );

        unchecked {
            earned0 = collected0 - burned0;
            earned1 = collected1 - burned1;
        }
    }

    /**
     * @notice Amounts of TOKEN0 and TOKEN1 held in vault's position. Includes
     * owed fees, except those accrued since last poke.
     */
    function collectableAmountsAsOfLastPoke(Position memory position, uint160 sqrtPriceX96)
        internal
        view
        returns (
            uint256,
            uint256,
            uint128
        )
    {
        if (position.lower == position.upper) return (0, 0, 0);

        (uint128 liquidity, , , uint128 earnable0, uint128 earnable1) = info(position);
        (uint256 burnable0, uint256 burnable1) = amountsForLiquidity(position, sqrtPriceX96, liquidity);

        return (burnable0 + earnable0, burnable1 + earnable1, liquidity);
    }

    /// @dev Wrapper around `IUniswapV3Pool.positions()`.
    function info(Position memory position)
        internal
        view
        returns (
            uint128, // liquidity
            uint256, // feeGrowthInside0LastX128
            uint256, // feeGrowthInside1LastX128
            uint128, // tokensOwed0
            uint128 // tokensOwed1
        )
    {
        return position.pool.positions(keccak256(abi.encodePacked(address(this), position.lower, position.upper)));
    }

    /// @dev Wrapper around `LiquidityAmounts.getAmountsForLiquidity()`.
    function amountsForLiquidity(
        Position memory position,
        uint160 sqrtPriceX96,
        uint128 liquidity
    ) internal pure returns (uint256, uint256) {
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(position.lower),
                TickMath.getSqrtRatioAtTick(position.upper),
                liquidity
            );
    }

    /// @dev Wrapper around `LiquidityAmounts.getLiquidityForAmounts()`.
    function liquidityForAmounts(
        Position memory position,
        uint160 sqrtPriceX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128) {
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(position.lower),
                TickMath.getSqrtRatioAtTick(position.upper),
                amount0,
                amount1
            );
    }

    /// @dev Wrapper around `LiquidityAmounts.getLiquidityForAmount0()`.
    function liquidityForAmount0(Position memory position, uint256 amount0) internal pure returns (uint128) {
        return
            LiquidityAmounts.getLiquidityForAmount0(
                TickMath.getSqrtRatioAtTick(position.lower),
                TickMath.getSqrtRatioAtTick(position.upper),
                amount0
            );
    }

    /// @dev Wrapper around `LiquidityAmounts.getLiquidityForAmount1()`.
    function liquidityForAmount1(Position memory position, uint256 amount1) internal pure returns (uint128) {
        return
            LiquidityAmounts.getLiquidityForAmount1(
                TickMath.getSqrtRatioAtTick(position.lower),
                TickMath.getSqrtRatioAtTick(position.upper),
                amount1
            );
    }
}

////// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

/* pragma solidity ^0.8.0; */

/* import "../IERC20.sol"; */

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

////// contracts/AloeBlend.sol
/* pragma solidity ^0.8.10; */

/* import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol"; */
/* import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; */

/* import "contracts/libraries/FullMath.sol"; */
/* import "contracts/libraries/TickMath.sol"; */
/* import "contracts/libraries/Silo.sol"; */
/* import "contracts/libraries/Uniswap.sol"; */

/* import {IFactory} from "./interfaces/IFactory.sol"; */
/* import {IAloeBlend, IAloeBlendActions, IAloeBlendDerivedState, IAloeBlendEvents, IAloeBlendImmutables, IAloeBlendState} from "./interfaces/IAloeBlend.sol"; */
/* import {IVolatilityOracle} from "./interfaces/IVolatilityOracle.sol"; */

/* import "./AloeBlendERC20.sol"; */
/* import "./UniswapHelper.sol"; */

/*
                              #                                                                    
                             ###                                                                   
                             #####                                                                 
          #                 #######                                *###*                           
           ###             #########                         ########                              
           #####         ###########                   ###########                                 
           ########    ############               ############                                     
            ########    ###########         *##############                                        
           ###########   ########      #################                                           
           ############   ###      #################                                               
           ############       ##################                                                   
          #############    #################*         *#############*                              
         ##############    #############      #####################################                
        ###############   ####******      #######################*                                 
      ################                                                                             
    #################   *############################*                                             
      ##############    ######################################                                     
          ########    ################*                     **######*                              
              ###    ###                                                                           
*/

uint256 constant Q96 = 2**96;

contract AloeBlend is AloeBlendERC20, UniswapHelper, IAloeBlend {
    using SafeERC20 for IERC20;
    using Uniswap for Uniswap.Position;
    using Silo for ISilo;

    /// @inheritdoc IAloeBlendImmutables
    uint24 public constant RECENTERING_INTERVAL = 24 hours; // aim to recenter once per day

    /// @inheritdoc IAloeBlendImmutables
    int24 public constant MIN_WIDTH = 402; // 1% of inventory in primary Uniswap position

    /// @inheritdoc IAloeBlendImmutables
    int24 public constant MAX_WIDTH = 27728; // 50% of inventory in primary Uniswap position

    /// @inheritdoc IAloeBlendImmutables
    uint8 public constant K = 20; // maintenance budget should cover at least 20 rebalances

    /// @inheritdoc IAloeBlendImmutables
    uint8 public constant L = 4; // if maintenance budget drops below 1/4th of its max value, consider it unsustainable

    /// @inheritdoc IAloeBlendImmutables
    uint8 public constant B = 2; // primary Uniswap position should cover 95% (2 std. dev.) of trading activity

    /// @inheritdoc IAloeBlendImmutables
    uint8 public constant D = 10; // new gas price observations must not be less than [avg - avg/10]

    /// @inheritdoc IAloeBlendImmutables
    uint8 public constant MAINTENANCE_FEE = 10; // 1/10th of earnings from primary Uniswap position

    /// @inheritdoc IAloeBlendImmutables
    uint256 public constant FLOAT_PERCENTAGE = 500; // 5% of inventory sits in contract to cheapen small withdrawals

    /// @dev The minimum tick that can serve as a position boundary in the Uniswap pool
    int24 private immutable MIN_TICK;

    /// @dev The maximum tick that can serve as a position boundary in the Uniswap pool
    int24 private immutable MAX_TICK;

    /// @inheritdoc IAloeBlendImmutables
    IVolatilityOracle public immutable volatilityOracle;

    /// @inheritdoc IAloeBlendImmutables
    ISilo public immutable silo0;

    /// @inheritdoc IAloeBlendImmutables
    ISilo public immutable silo1;

    struct PackedSlot {
        // The primary position's lower tick bound
        int24 primaryLower;
        // The primary position's upper tick bound
        int24 primaryUpper;
        // The limit order's lower tick bound
        int24 limitLower;
        // The limit order's upper tick bound
        int24 limitUpper;
        // The `block.timestamp` from the last time the primary position moved
        uint48 recenterTimestamp;
        // The (approximate) maximum amount of gas that has ever been used to `rebalance()` this vault
        uint32 maxRebalanceGas;
        // Whether `maintenanceBudget0` or `maintenanceBudget1` is filled up
        bool maintenanceIsSustainable;
        // Whether the vault is currently locked to reentrancy
        bool locked;
    }

    /// @inheritdoc IAloeBlendState
    PackedSlot public packedSlot;

    /// @inheritdoc IAloeBlendState
    uint256 public silo0Basis;

    /// @inheritdoc IAloeBlendState
    uint256 public silo1Basis;

    /// @inheritdoc IAloeBlendState
    uint256 public maintenanceBudget0;

    /// @inheritdoc IAloeBlendState
    uint256 public maintenanceBudget1;

    /// @inheritdoc IAloeBlendState
    mapping(address => uint256) public gasPrices;

    /// @dev Stores 14 samples of the gas price for each token, scaled by 1e4 and divided by 14. The sum over each
    /// array is equal to the value reported by `gasPrices`
    mapping(address => uint256[14]) private gasPriceArrays;

    /// @dev The index of `gasPriceArrays[address]` in which the next gas price measurement will be stored
    mapping(address => uint8) private gasPriceIdxs;

    /// @dev Required for some silos
    receive() external payable {}

    constructor(
        IUniswapV3Pool _uniPool,
        ISilo _silo0,
        ISilo _silo1
    )
        AloeBlendERC20(
            // ex: Aloe Blend USDC/WETH
            string(
                abi.encodePacked(
                    "Aloe Blend ",
                    IERC20Metadata(_uniPool.token0()).symbol(),
                    "/",
                    IERC20Metadata(_uniPool.token1()).symbol()
                )
            )
        )
        UniswapHelper(_uniPool)
    {
        MIN_TICK = TickMath.ceil(TickMath.MIN_TICK, TICK_SPACING);
        MAX_TICK = TickMath.floor(TickMath.MAX_TICK, TICK_SPACING);

        volatilityOracle = IFactory(msg.sender).volatilityOracle();
        silo0 = _silo0;
        silo1 = _silo1;

        packedSlot.recenterTimestamp = uint48(block.timestamp);
    }

    /// @inheritdoc IAloeBlendActions
    function deposit(
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(amount0Max != 0 || amount1Max != 0, "Aloe: 0 deposit");
        // Reentrancy guard is embedded in `_loadPackedSlot` to save gas
        (Uniswap.Position memory primary, Uniswap.Position memory limit, , , ) = _loadPackedSlot();
        packedSlot.locked = true;

        // Poke all assets
        primary.poke();
        limit.poke();
        silo0.delegate_poke();
        silo1.delegate_poke();

        (uint160 sqrtPriceX96, , , , , , ) = UNI_POOL.slot0();
        (uint256 inventory0, uint256 inventory1, ) = _getInventory(primary, limit, sqrtPriceX96, true);
        (shares, amount0, amount1) = _computeLPShares(
            totalSupply,
            inventory0,
            inventory1,
            amount0Max,
            amount1Max,
            sqrtPriceX96
        );
        require(shares != 0, "Aloe: 0 shares");
        require(amount0 >= amount0Min, "Aloe: amount0 too low");
        require(amount1 >= amount1Min, "Aloe: amount1 too low");

        // Pull in tokens from sender
        TOKEN0.safeTransferFrom(msg.sender, address(this), amount0);
        TOKEN1.safeTransferFrom(msg.sender, address(this), amount1);

        // Mint shares
        _mint(msg.sender, shares);
        emit Deposit(msg.sender, shares, amount0, amount1);
        packedSlot.locked = false;
    }

    /// @inheritdoc IAloeBlendActions
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256 amount0, uint256 amount1) {
        require(shares != 0, "Aloe: 0 shares");
        // Reentrancy guard is embedded in `_loadPackedSlot` to save gas
        (Uniswap.Position memory primary, Uniswap.Position memory limit, , , ) = _loadPackedSlot();
        packedSlot.locked = true;

        // Poke silos to ensure reported balances are correct
        silo0.delegate_poke();
        silo1.delegate_poke();

        uint256 _totalSupply = totalSupply;
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;

        // Compute user's portion of token0 from contract + silo0
        c = _balance0();
        a = silo0Basis;
        b = silo0.balanceOf(address(this));
        a = b > a ? (b - a) / MAINTENANCE_FEE : 0; // interest / MAINTENANCE_FEE
        amount0 = FullMath.mulDiv(c + b - a, shares, _totalSupply);
        // Withdraw from silo0 if contract balance can't cover what user is owed
        if (amount0 > c) {
            c = a + amount0 - c;
            silo0.delegate_withdraw(c);
            maintenanceBudget0 += a;
            silo0Basis = b - c;
        }

        // Compute user's portion of token1 from contract + silo1
        c = _balance1();
        a = silo1Basis;
        b = silo1.balanceOf(address(this));
        a = b > a ? (b - a) / MAINTENANCE_FEE : 0; // interest / MAINTENANCE_FEE
        amount1 = FullMath.mulDiv(c + b - a, shares, _totalSupply);
        // Withdraw from silo1 if contract balance can't cover what user is owed
        if (amount1 > c) {
            c = a + amount1 - c;
            silo1.delegate_withdraw(c);
            maintenanceBudget1 += a;
            silo1Basis = b - c;
        }

        // Withdraw user's portion of the primary position
        {
            (uint128 liquidity, , , , ) = primary.info();
            (a, b, c, d) = primary.withdraw(uint128(FullMath.mulDiv(liquidity, shares, _totalSupply)));
            amount0 += a;
            amount1 += b;
            a = c / MAINTENANCE_FEE;
            b = d / MAINTENANCE_FEE;
            amount0 += FullMath.mulDiv(c - a, shares, _totalSupply);
            amount1 += FullMath.mulDiv(d - b, shares, _totalSupply);
            maintenanceBudget0 += a;
            maintenanceBudget1 += b;
        }

        // Withdraw user's portion of the limit order
        if (limit.lower != limit.upper) {
            (uint128 liquidity, , , , ) = limit.info();
            (a, b, c, d) = limit.withdraw(uint128(FullMath.mulDiv(liquidity, shares, _totalSupply)));
            amount0 += a + FullMath.mulDiv(c, shares, _totalSupply);
            amount1 += b + FullMath.mulDiv(d, shares, _totalSupply);
        }

        // Check constraints
        require(amount0 >= amount0Min, "Aloe: amount0 too low");
        require(amount1 >= amount1Min, "Aloe: amount1 too low");

        // Transfer tokens
        TOKEN0.safeTransfer(msg.sender, amount0);
        TOKEN1.safeTransfer(msg.sender, amount1);

        // Burn shares
        _burn(msg.sender, shares);
        emit Withdraw(msg.sender, shares, amount0, amount1);
        packedSlot.locked = false;
    }

    struct RebalanceCache {
        uint160 sqrtPriceX96;
        uint224 priceX96;
        int24 tick;
    }

    /// @inheritdoc IAloeBlendActions
    function rebalance(address rewardToken) external {
        uint32 gas = uint32(gasleft());
        // Reentrancy guard is embedded in `_loadPackedSlot` to save gas
        (
            Uniswap.Position memory primary,
            Uniswap.Position memory limit,
            uint48 recenterTimestamp,
            uint32 maxRebalanceGas,
            bool maintenanceIsSustainable
        ) = _loadPackedSlot();
        packedSlot.locked = true;

        // Populate rebalance cache
        RebalanceCache memory cache;
        (cache.sqrtPriceX96, cache.tick, , , , , ) = UNI_POOL.slot0();
        cache.priceX96 = uint224(FullMath.mulDiv(cache.sqrtPriceX96, cache.sqrtPriceX96, Q96));
        uint32 urgency = _getRebalanceUrgency(recenterTimestamp);

        // Poke silos to ensure reported balances are correct
        silo0.delegate_poke();
        silo1.delegate_poke();

        // Check inventory
        (uint256 inventory0, uint256 inventory1, InventoryDetails memory d) = _getInventory(
            primary,
            limit,
            cache.sqrtPriceX96,
            false
        );

        // Remove the limit order if it exists
        if (d.limitLiquidity != 0) limit.withdraw(d.limitLiquidity);

        // Compute inventory ratio to determine what happens next
        uint256 ratio = FullMath.mulDiv(
            10_000,
            inventory0,
            inventory0 + FullMath.mulDiv(inventory1, Q96, cache.priceX96)
        );
        if (ratio < 4900) {
            // Attempt to sell token1 for token0. Choose limit order bounds below the market price. Disable
            // incentive if removing & replacing in the same spot
            limit.upper = TickMath.floor(cache.tick, TICK_SPACING);
            if (d.limitLiquidity != 0 && limit.lower == limit.upper - TICK_SPACING) urgency = 0;
            limit.lower = limit.upper - TICK_SPACING;
            // Choose amount1 such that ratio will be 50/50 once the limit order is pushed through (division by 2
            // is a good approximation for small tickSpacing). Also have to constrain to fluid1 since we're not
            // yet withdrawing from primary Uniswap position
            uint256 amount1 = (inventory1 - FullMath.mulDiv(inventory0, cache.priceX96, Q96)) >> 1;
            if (amount1 > d.fluid1) amount1 = d.fluid1;
            // If contract balance is insufficient, withdraw from silo1. That still may not be enough, so reassign
            // `amount1` to the actual available amount
            unchecked {
                uint256 balance1 = _balance1();
                if (balance1 < amount1) amount1 = balance1 + _silo1Withdraw(amount1 - balance1);
            }
            // Place a new limit order
            limit.deposit(limit.liquidityForAmount1(amount1));
        } else if (ratio > 5100) {
            // Attempt to sell token0 for token1. Choose limit order bounds above the market price. Disable
            // incentive if removing & replacing in the same spot
            limit.lower = TickMath.ceil(cache.tick, TICK_SPACING);
            if (d.limitLiquidity != 0 && limit.upper == limit.lower + TICK_SPACING) urgency = 0;
            limit.upper = limit.lower + TICK_SPACING;
            // Choose amount0 such that ratio will be 50/50 once the limit order is pushed through (division by 2
            // is a good approximation for small tickSpacing). Also have to constrain to fluid0 since we're not
            // yet withdrawing from primary Uniswap position
            uint256 amount0 = (inventory0 - FullMath.mulDiv(inventory1, Q96, cache.priceX96)) >> 1;
            if (amount0 > d.fluid0) amount0 = d.fluid0;
            // If contract balance is insufficient, withdraw from silo0. That still may not be enough, so reassign
            // `amount0` to the actual available amount
            unchecked {
                uint256 balance0 = _balance0();
                if (balance0 < amount0) amount0 = balance0 + _silo0Withdraw(amount0 - balance0);
            }
            // Place a new limit order
            limit.deposit(limit.liquidityForAmount0(amount0));
        } else {
            // Zero-out the limit struct to indicate that it's inactive
            delete limit;
            // Recenter the primary position
            primary = _recenter(cache, primary, d.primaryLiquidity, inventory0, inventory1, maintenanceIsSustainable);
            recenterTimestamp = uint48(block.timestamp);
        }

        gas = uint32(21000 + gas - gasleft());
        if (gas > maxRebalanceGas) maxRebalanceGas = gas;
        maintenanceIsSustainable = _rewardCaller(rewardToken, urgency, gas, maxRebalanceGas, maintenanceIsSustainable);

        emit Rebalance(ratio, totalSupply, inventory0, inventory1);
        packedSlot = PackedSlot(
            primary.lower,
            primary.upper,
            limit.lower,
            limit.upper,
            recenterTimestamp,
            maxRebalanceGas,
            maintenanceIsSustainable,
            false
        );
    }

    /**
     * @notice Recenters the primary Uniswap position around the current tick. Deposits leftover funds into the silos.
     * @dev This function assumes that the limit order has no liquidity (never existed or already exited)
     * @param _cache The rebalance cache, populated with sqrtPriceX96, priceX96, and tick
     * @param _primary The existing primary Uniswap position
     * @param _primaryLiquidity The amount of liquidity currently in `_primary`
     * @param _inventory0 The amount of token0 underlying all LP tokens. MUST BE <= THE TRUE VALUE. No overestimates!
     * @param _inventory1 The amount of token1 underlying all LP tokens. MUST BE <= THE TRUE VALUE. No overestimates!
     * @param _maintenanceIsSustainable Whether `maintenanceBudget0` or `maintenanceBudget1` has filled up according to
     * `K` -- if false, position width is maximized rather than scaling with volatility
     * @return Uniswap.Position memory `_primary` updated with new lower and upper tick bounds
     */
    function _recenter(
        RebalanceCache memory _cache,
        Uniswap.Position memory _primary,
        uint128 _primaryLiquidity,
        uint256 _inventory0,
        uint256 _inventory1,
        bool _maintenanceIsSustainable
    ) private returns (Uniswap.Position memory) {
        // Exit primary Uniswap position
        unchecked {
            (, , uint256 earned0, uint256 earned1) = _primary.withdraw(_primaryLiquidity);
            maintenanceBudget0 += earned0 / MAINTENANCE_FEE;
            maintenanceBudget1 += earned1 / MAINTENANCE_FEE;
        }

        // Decide primary position width...
        int24 w = _maintenanceIsSustainable
            ? _computeNextPositionWidth(volatilityOracle.estimate24H(UNI_POOL))
            : MAX_WIDTH;
        w = w >> 1;
        // ...and compute amounts that should be placed inside
        (uint256 amount0, uint256 amount1) = _computeMagicAmounts(_inventory0, _inventory1, w);

        // If contract balance (leaving out the float) is insufficient, withdraw from silos
        int256 balance0;
        int256 balance1;
        unchecked {
            balance0 = int256(_balance0()) - int256(FullMath.mulDiv(_inventory0, FLOAT_PERCENTAGE, 10_000));
            balance1 = int256(_balance1()) - int256(FullMath.mulDiv(_inventory1, FLOAT_PERCENTAGE, 10_000));
            if (balance0 < int256(amount0)) {
                _inventory0 = 0; // reuse var to avoid stack too deep. now a flag, 0 means we withdraw from silo0
                amount0 = uint256(balance0 + int256(_silo0Withdraw(uint256(int256(amount0) - balance0))));
            }
            if (balance1 < int256(amount1)) {
                _inventory1 = 0; // reuse var to avoid stack too deep. now a flag, 0 means we withdraw from silo1
                amount1 = uint256(balance1 + int256(_silo1Withdraw(uint256(int256(amount1) - balance1))));
            }
        }

        // Update primary position's ticks
        unchecked {
            _primary.lower = TickMath.floor(_cache.tick - w, TICK_SPACING);
            _primary.upper = TickMath.ceil(_cache.tick + w, TICK_SPACING);
            if (_primary.lower < MIN_TICK) _primary.lower = MIN_TICK;
            if (_primary.upper > MAX_TICK) _primary.upper = MAX_TICK;
        }

        // Place some liquidity in Uniswap
        (amount0, amount1) = _primary.deposit(_primary.liquidityForAmounts(_cache.sqrtPriceX96, amount0, amount1));

        // Place excess into silos
        if (_inventory0 != 0) {
            silo0.delegate_deposit(uint256(balance0) - amount0);
            silo0Basis += uint256(balance0) - amount0;
        }
        if (_inventory1 != 0) {
            silo1.delegate_deposit(uint256(balance1) - amount1);
            silo1Basis += uint256(balance1) - amount1;
        }

        emit Recenter(_primary.lower, _primary.upper);
        return _primary;
    }

    /**
     * @notice Sends some `_rewardToken` to `msg.sender` as a reward for calling rebalance
     * @param _rewardToken The ERC20 token in which the reward should be denominated. If `rewardToken` is the 0
     * address, no reward will be given.
     * @param _urgency How critical it is that rebalance gets called right now. Nominal value is 100_000
     * @param _gasUsed How much gas was used for core rebalance logic
     * @param _maxRebalanceGas The (approximate) maximum amount of gas that's ever been used for `rebalance()`
     * @param _maintenanceIsSustainable Whether the most recently-used maintenance budget was filled up after the
     * last rebalance
     * @return bool If `_rewardToken` is token0 or token1, return whether the maintenance budget will remain full
     * after sending reward. If `_rewardToken` is something else, return previous _maintenanceIsSustainable value
     */
    function _rewardCaller(
        address _rewardToken,
        uint32 _urgency,
        uint32 _gasUsed,
        uint32 _maxRebalanceGas,
        bool _maintenanceIsSustainable
    ) private returns (bool) {
        // Short-circuit if the caller doesn't want to be rewarded
        if (_rewardToken == address(0)) {
            emit Reward(address(0), 0, _urgency);
            return _maintenanceIsSustainable;
        }

        // Otherwise, do math
        uint256 rewardPerGas = gasPrices[_rewardToken]; // extra factor of 1e4
        uint256 reward = FullMath.mulDiv(rewardPerGas * _gasUsed, _urgency, 1e9);

        if (_rewardToken == address(TOKEN0)) {
            uint256 budget = maintenanceBudget0;
            if (reward > budget || rewardPerGas == 0) reward = budget;
            budget -= reward;

            uint256 maxBudget = FullMath.mulDiv(rewardPerGas * K, _maxRebalanceGas, 1e4);
            maintenanceBudget0 = budget > maxBudget ? maxBudget : budget;

            if (budget > maxBudget) _maintenanceIsSustainable = true;
            else if (budget < maxBudget / L) _maintenanceIsSustainable = false;
        } else if (_rewardToken == address(TOKEN1)) {
            uint256 budget = maintenanceBudget1;
            if (reward > budget || rewardPerGas == 0) reward = budget;
            budget -= reward;

            uint256 maxBudget = FullMath.mulDiv(rewardPerGas * K, _maxRebalanceGas, 1e4);
            maintenanceBudget1 = budget > maxBudget ? maxBudget : budget;

            if (budget > maxBudget) _maintenanceIsSustainable = true;
            else if (budget < maxBudget / L) _maintenanceIsSustainable = false;
        } else {
            uint256 budget = IERC20(_rewardToken).balanceOf(address(this));
            if (reward > budget || rewardPerGas == 0) reward = budget;

            require(silo0.shouldAllowRemovalOf(_rewardToken) && silo1.shouldAllowRemovalOf(_rewardToken));
        }

        IERC20(_rewardToken).safeTransfer(msg.sender, reward);
        _pushGasPrice(_rewardToken, FullMath.mulDiv(1e4, reward, _gasUsed));
        emit Reward(_rewardToken, reward, _urgency);
        return _maintenanceIsSustainable;
    }

    /**
     * @notice Attempts to withdraw `_amount` from silo0. If `_amount` is more than what's available, withdraw the
     * maximum amount.
     * @dev This reads and writes from/to `maintenanceBudget0`, so use sparingly
     * @param _amount The desired amount of token0 to withdraw from silo0
     * @return uint256 The actual amount of token0 that was withdrawn
     */
    function _silo0Withdraw(uint256 _amount) private returns (uint256) {
        unchecked {
            uint256 a = silo0Basis;
            uint256 b = silo0.balanceOf(address(this));
            a = b > a ? (b - a) / MAINTENANCE_FEE : 0; // interest / MAINTENANCE_FEE

            if (_amount > b - a) _amount = b - a;

            silo0.delegate_withdraw(a + _amount);
            maintenanceBudget0 += a;
            silo0Basis = b - a - _amount;

            return _amount;
        }
    }

    /**
     * @notice Attempts to withdraw `_amount` from silo1. If `_amount` is more than what's available, withdraw the
     * maximum amount.
     * @dev This reads and writes from/to `maintenanceBudget1`, so use sparingly
     * @param _amount The desired amount of token1 to withdraw from silo1
     * @return uint256 The actual amount of token1 that was withdrawn
     */
    function _silo1Withdraw(uint256 _amount) private returns (uint256) {
        unchecked {
            uint256 a = silo1Basis;
            uint256 b = silo1.balanceOf(address(this));
            a = b > a ? (b - a) / MAINTENANCE_FEE : 0; // interest / MAINTENANCE_FEE

            if (_amount > b - a) _amount = b - a;

            silo1.delegate_withdraw(a + _amount);
            maintenanceBudget1 += a;
            silo1Basis = b - a - _amount;

            return _amount;
        }
    }

    /**
     * @dev Assumes that `_gasPrice` represents the fair value of 1e4 units of gas, denominated in `_token`.
     * Updates the contract's gas price oracle accordingly, including incrementing the array index.
     * @param _token The ERC20 token for which average gas price should be updated
     * @param _gasPrice The amount of `_token` necessary to incentivize expenditure of 1e4 units of gas
     */
    function _pushGasPrice(address _token, uint256 _gasPrice) private {
        uint256[14] storage array = gasPriceArrays[_token];
        uint8 idx = gasPriceIdxs[_token];
        unchecked {
            // New entry cannot be lower than 90% of the previous average
            uint256 average = gasPrices[_token];
            uint256 minimum = average - average / D;
            if (_gasPrice < minimum) _gasPrice = minimum;

            _gasPrice /= 14;
            gasPrices[_token] = average + _gasPrice - array[idx];
            array[idx] = _gasPrice;
            gasPriceIdxs[_token] = (idx + 1) % 14;
        }
    }

    // ⬇️⬇️⬇️⬇️ VIEW FUNCTIONS ⬇️⬇️⬇️⬇️  ------------------------------------------------------------------------------

    /// @dev Unpacks `packedSlot` from storage, ensuring that `_packedSlot.locked == false`
    function _loadPackedSlot()
        private
        view
        returns (
            Uniswap.Position memory,
            Uniswap.Position memory,
            uint48,
            uint32,
            bool
        )
    {
        PackedSlot memory _packedSlot = packedSlot;
        require(!_packedSlot.locked);
        return (
            Uniswap.Position(UNI_POOL, _packedSlot.primaryLower, _packedSlot.primaryUpper),
            Uniswap.Position(UNI_POOL, _packedSlot.limitLower, _packedSlot.limitUpper),
            _packedSlot.recenterTimestamp,
            _packedSlot.maxRebalanceGas,
            _packedSlot.maintenanceIsSustainable
        );
    }

    /// @inheritdoc IAloeBlendDerivedState
    function getRebalanceUrgency() external view returns (uint32 urgency) {
        urgency = _getRebalanceUrgency(packedSlot.recenterTimestamp);
    }

    /**
     * @notice Reports how badly the vault wants its `rebalance()` function to be called. Proportional to time
     * elapsed since the primary position last moved.
     * @dev Since `RECENTERING_INTERVAL` is 86400 seconds, urgency is guaranteed to be nonzero unless the primary
     * position is moved more than once in a single block.
     * @param _recenterTimestamp The `block.timestamp` from the last time the primary position moved
     * @return urgency How badly the vault wants its `rebalance()` function to be called
     */
    function _getRebalanceUrgency(uint48 _recenterTimestamp) private view returns (uint32 urgency) {
        urgency = uint32(FullMath.mulDiv(100_000, block.timestamp - _recenterTimestamp, RECENTERING_INTERVAL));
    }

    /// @inheritdoc IAloeBlendDerivedState
    function getInventory() external view returns (uint256 inventory0, uint256 inventory1) {
        (Uniswap.Position memory primary, Uniswap.Position memory limit, , , ) = _loadPackedSlot();
        (uint160 sqrtPriceX96, , , , , , ) = UNI_POOL.slot0();
        (inventory0, inventory1, ) = _getInventory(primary, limit, sqrtPriceX96, false);
    }

    struct InventoryDetails {
        // The amount of token0 available to limit order, i.e. everything *not* in the primary position
        uint256 fluid0;
        // The amount of token1 available to limit order, i.e. everything *not* in the primary position
        uint256 fluid1;
        // The liquidity present in the primary position. Note that this may be higher than what the
        // vault deposited since someone may designate this contract as a `mint()` recipient
        uint128 primaryLiquidity;
        // The liquidity present in the limit order. Note that this may be higher than what the
        // vault deposited since someone may designate this contract as a `mint()` recipient
        uint128 limitLiquidity;
    }

    /**
     * @notice Estimate's the vault's liabilities to users -- in other words, how much would be paid out if all
     * holders redeemed their LP tokens at once.
     * @dev Underestimates the true payout unless both silos and Uniswap positions have just been poked. Also...
     * if _overestimate is false
     *      Assumes that the maximum amount will accrue to the maintenance budget during the next `rebalance()`. If it
     *      takes less than that for the budget to reach capacity, then the values reported here may increase after
     *      calling `rebalance()`.
     * if _overestimate is true
     *      Assumes that nothing will accrue to the maintenance budget during the next `rebalance()`. So the values
     *      reported here may decrease after calling `rebalance()`, i.e. this becomes an overestimate rather than an
     *      underestimate.
     * @param _primary The primary position
     * @param _limit The limit order; if inactive, `_limit.lower` should equal `_limit.upper`
     * @param _sqrtPriceX96 The current sqrt(price) of the Uniswap pair from `slot0()`
     * @param _overestimate Whether to error on the side of overestimating or underestimating
     * @return inventory0 The amount of token0 underlying all LP tokens
     * @return inventory1 The amount of token1 underlying all LP tokens
     * @return d A struct containing details that may be relevant to other functions. We return it here to avoid
     * reloading things from external storage (saves gas).
     */
    function _getInventory(
        Uniswap.Position memory _primary,
        Uniswap.Position memory _limit,
        uint160 _sqrtPriceX96,
        bool _overestimate
    )
        private
        view
        returns (
            uint256 inventory0,
            uint256 inventory1,
            InventoryDetails memory d
        )
    {
        uint256 a;
        uint256 b;

        // Limit order
        if (_limit.lower != _limit.upper) {
            (d.limitLiquidity, , , a, b) = _limit.info();
            (d.fluid0, d.fluid1) = _limit.amountsForLiquidity(_sqrtPriceX96, d.limitLiquidity);
            // Earnings from limit order don't get added to maintenance budget
            d.fluid0 += a;
            d.fluid1 += b;
        }

        // token0 from contract + silo0
        a = silo0Basis;
        b = silo0.balanceOf(address(this));
        a = b > a ? (b - a) / MAINTENANCE_FEE : 0; // interest / MAINTENANCE_FEE
        d.fluid0 += _balance0() + b - (_overestimate ? 0 : a);

        // token1 from contract + silo1
        a = silo1Basis;
        b = silo1.balanceOf(address(this));
        a = b > a ? (b - a) / MAINTENANCE_FEE : 0; // interest / MAINTENANCE_FEE
        d.fluid1 += _balance1() + b - (_overestimate ? 0 : a);

        // Primary position; limit order is placed without touching this, so its amounts aren't included in `fluid`
        if (_primary.lower != _primary.upper) {
            (d.primaryLiquidity, , , a, b) = _primary.info();
            (inventory0, inventory1) = _primary.amountsForLiquidity(_sqrtPriceX96, d.primaryLiquidity);

            inventory0 += d.fluid0 + a - (_overestimate ? 0 : a / MAINTENANCE_FEE);
            inventory1 += d.fluid1 + b - (_overestimate ? 0 : b / MAINTENANCE_FEE);
        } else {
            inventory0 = d.fluid0;
            inventory1 = d.fluid1;
        }
    }

    /// @dev The amount of token0 in the contract that's not in maintenanceBudget0
    function _balance0() private view returns (uint256) {
        return TOKEN0.balanceOf(address(this)) - maintenanceBudget0;
    }

    /// @dev The amount of token1 in the contract that's not in maintenanceBudget1
    function _balance1() private view returns (uint256) {
        return TOKEN1.balanceOf(address(this)) - maintenanceBudget1;
    }

    // ⬆️⬆️⬆️⬆️ VIEW FUNCTIONS ⬆️⬆️⬆️⬆️  ------------------------------------------------------------------------------
    // ⬇️⬇️⬇️⬇️ PURE FUNCTIONS ⬇️⬇️⬇️⬇️  ------------------------------------------------------------------------------

    /// @dev Computes position width based on volatility. Doesn't revert
    function _computeNextPositionWidth(uint256 _sigma) internal pure returns (int24) {
        if (_sigma <= 9.9491783619e15) return MIN_WIDTH; // \frac{1e18}{B} (1 - \frac{1}{1.0001^(MIN_WIDTH / 2)})
        if (_sigma >= 3.7500454036e17) return MAX_WIDTH; // \frac{1e18}{B} (1 - \frac{1}{1.0001^(MAX_WIDTH / 2)})
        _sigma *= B; // scale by a constant factor to increase confidence

        unchecked {
            uint160 ratio = uint160((Q96 * 1e18) / (1e18 - _sigma));
            return TickMath.getTickAtSqrtRatio(ratio);
        }
    }

    /// @dev Computes amounts that should be placed in primary Uniswap position to maintain 50/50 inventory ratio.
    /// Doesn't revert as long as MIN_WIDTH <= _halfWidth * 2 <= MAX_WIDTH
    function _computeMagicAmounts(
        uint256 _inventory0,
        uint256 _inventory1,
        int24 _halfWidth
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        // the fraction of total inventory (X96) that should be put into primary Uniswap order to mimic Uniswap v2
        uint96 magic = uint96(Q96 - TickMath.getSqrtRatioAtTick(-_halfWidth));
        amount0 = FullMath.mulDiv(_inventory0, magic, Q96);
        amount1 = FullMath.mulDiv(_inventory1, magic, Q96);
    }

    /// @dev Computes the largest possible `amount0` and `amount1` such that they match the current inventory ratio,
    /// but are not greater than `_amount0Max` and `_amount1Max` respectively. May revert if the following are true:
    ///     _totalSupply * _amount0Max / _inventory0 > type(uint256).max
    ///     _totalSupply * _amount1Max / _inventory1 > type(uint256).max
    /// This is okay because it only blocks deposit (not withdraw). Can also workaround by depositing smaller amounts
    function _computeLPShares(
        uint256 _totalSupply,
        uint256 _inventory0,
        uint256 _inventory1,
        uint256 _amount0Max,
        uint256 _amount1Max,
        uint160 _sqrtPriceX96
    )
        internal
        pure
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        // If total supply > 0, pool can't be empty
        assert(_totalSupply == 0 || _inventory0 != 0 || _inventory1 != 0);

        if (_totalSupply == 0) {
            // For first deposit, enforce 50/50 ratio manually
            uint224 priceX96 = uint224(FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, Q96));
            amount0 = FullMath.mulDiv(_amount1Max, Q96, priceX96);

            if (amount0 < _amount0Max) {
                amount1 = _amount1Max;
                shares = amount1;
            } else {
                amount0 = _amount0Max;
                amount1 = FullMath.mulDiv(amount0, priceX96, Q96);
                shares = amount0;
            }
        } else if (_inventory0 == 0) {
            amount1 = _amount1Max;
            shares = FullMath.mulDiv(amount1, _totalSupply, _inventory1);
        } else if (_inventory1 == 0) {
            amount0 = _amount0Max;
            shares = FullMath.mulDiv(amount0, _totalSupply, _inventory0);
        } else {
            // The branches of this ternary are logically identical, but must be separate to avoid overflow
            bool cond = _inventory0 < _inventory1
                ? FullMath.mulDiv(_amount1Max, _inventory0, _inventory1) < _amount0Max
                : _amount1Max < FullMath.mulDiv(_amount0Max, _inventory1, _inventory0);

            if (cond) {
                amount1 = _amount1Max;
                amount0 = FullMath.mulDiv(amount1, _inventory0, _inventory1);
                shares = FullMath.mulDiv(amount1, _totalSupply, _inventory1);
            } else {
                amount0 = _amount0Max;
                amount1 = FullMath.mulDiv(amount0, _inventory1, _inventory0);
                shares = FullMath.mulDiv(amount0, _totalSupply, _inventory0);
            }
        }
    }
}