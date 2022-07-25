/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-30
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// File: contracts/stableswap/interfaces/IStableSwap.sol


pragma solidity >=0.8.0;


interface IStableSwap {
    /// EVENTS
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    event FlashLoan(
        address indexed caller,
        address indexed receiver,
        uint256[] amounts_out
    );

    event TokenExchange(
        address indexed buyer,
        uint256 soldId,
        uint256 tokensSold,
        uint256 boughtId,
        uint256 tokensBought
    );

    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256[] fees, uint256 tokenSupply);

    event RemoveLiquidityOne(address indexed provider, uint256 tokenIndex, uint256 tokenAmount, uint256 coinAmount);

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    event StopRampA(uint256 A, uint256 timestamp);

    event NewFee(uint256 fee, uint256 adminFee);

    event CollectProtocolFee(address token, uint256 amount);

    event FeeControllerChanged(address newController);

    event FeeDistributorChanged(address newController);

    // pool data view functions
    function getLpToken() external view returns (IERC20 lpToken);

    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokens() external view returns (IERC20[] memory);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getTokenBalances() external view returns (uint256[] memory);

    function getNumberOfTokens() external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
        external
        view
        returns (uint256 availableTokenAmount);

    function getAdminBalances() external view returns (uint256[] memory adminBalances);

    function getAdminBalance(uint8 index) external view returns (uint256);

    // state modifying functions
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function flashLoan(
        uint256[] memory amountsOut,
        address to,
        bytes calldata data,
        uint256 deadline
    ) external;

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function withdrawAdminFee() external;
}

// File: contracts/periphery/interfaces/IStableSwapRouter.sol



pragma solidity >=0.8.0;


interface IStableSwapRouter {
    function convert(
        IStableSwap fromPool,
        IStableSwap toPool,
        uint256 amount,
        uint256 minToMint,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function addPoolLiquidity(
        IStableSwap pool,
        uint256[] memory amounts,
        uint256 minMintAmount,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function addPoolAndBaseLiquidity(
        IStableSwap pool,
        IStableSwap basePool,
        uint256[] memory meta_amounts,
        uint256[] memory base_amounts,
        uint256 minToMint,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function removePoolLiquidity(
        IStableSwap pool,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function removePoolLiquidityOneToken(
        IStableSwap pool,
        uint256 lpAmount,
        uint8 index,
        uint256 minAmount,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function removePoolAndBaseLiquidity(
        IStableSwap pool,
        IStableSwap basePool,
        uint256 _amount,
        uint256[] calldata min_amounts_meta,
        uint256[] calldata min_amounts_base,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts, uint256[] memory base_amounts);

    function removePoolAndBaseLiquidityOneToken(
        IStableSwap pool,
        IStableSwap basePool,
        uint256 _token_amount,
        uint8 i,
        uint256 _min_amount,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function swapPool(
        IStableSwap pool,
        uint8 fromIndex,
        uint8 toIndex,
        uint256 inAmount,
        uint256 minOutAmount,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function swapPoolFromBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function swapPoolToBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function calculateConvert(
        IStableSwap fromPool,
        IStableSwap toPool,
        uint256 amount
    ) external view returns (uint256);

    function calculateTokenAmount(
        IStableSwap pool,
        IStableSwap basePool,
        uint256[] memory meta_amounts,
        uint256[] memory base_amounts,
        bool is_deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidity(
        IStableSwap pool,
        IStableSwap basePool,
        uint256 amount
    ) external view returns (uint256[] memory meta_amounts, uint256[] memory base_amounts);

    function calculateRemoveBaseLiquidityOneToken(
        IStableSwap pool,
        IStableSwap basePool,
        uint256 _token_amount,
        uint8 iBase
    ) external view returns (uint256 availableTokenAmount);

    function calculateSwap(
        IStableSwap pool,
        uint8 fromIndex,
        uint8 toIndex,
        uint256 inAmount
    ) external view returns (uint256);

    function calculateSwapFromBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateSwapToBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);
}
// File: contracts/periphery/StableSwapRouter.sol


pragma solidity >=0.8.0;





contract StableSwapRouter is IStableSwapRouter {
    using SafeERC20 for IERC20;

    function convert(
        IStableSwap fromPool,
        IStableSwap toPool,
        uint256 amount,
        uint256 minToMint,
        address to,
        uint256 deadline
    ) external override returns (uint256) {
        uint256 fromPoolLength = fromPool.getNumberOfTokens();
        uint256 toPoolLength = toPool.getNumberOfTokens();
        require(address(fromPool) != address(toPool), "fromPool = toPool");
        require(fromPoolLength == toPoolLength, "poolTokensLengthMissmatch");
        IERC20 fromToken = fromPool.getLpToken();
        IERC20 toToken = toPool.getLpToken();
        uint256[] memory min_amounts = new uint256[](fromPoolLength);
        // validate token
        for (uint8 i = 0; i < fromPoolLength; i++) {
            IERC20 coin = fromPool.getToken(i);
            toPool.getTokenIndex(address(coin));
        }
        fromToken.safeTransferFrom(msg.sender, address(this), amount);
        fromToken.safeIncreaseAllowance(address(fromPool), amount);
        fromPool.removeLiquidity(amount, min_amounts, deadline);

        uint256[] memory meta_amounts = new uint256[](toPoolLength);

        for (uint8 i = 0; i < toPoolLength; i++) {
            IERC20 coin = toPool.getToken(i);
            uint256 addBalance = coin.balanceOf(address(this));
            coin.safeIncreaseAllowance(address(toPool), addBalance);
            meta_amounts[i] = addBalance;
        }
        toPool.addLiquidity(meta_amounts, minToMint, deadline);

        uint256 lpAmount = toToken.balanceOf(address(this));
        toToken.safeTransfer(to, lpAmount);
        return lpAmount;
    }

    function addPoolLiquidity(
        IStableSwap pool,
        uint256[] memory amounts,
        uint256 minMintAmount,
        address to,
        uint256 deadline
    ) external override returns (uint256) {
        IERC20 token = IERC20(pool.getLpToken());
        for (uint8 i = 0; i < amounts.length; i++) {
            IERC20 coin = pool.getToken(i);
            uint256 transferred;
            if (amounts[i] > 0) {
                transferred = transferIn(coin, msg.sender, amounts[i]);
            }
            amounts[i] = transferred;
            if (transferred > 0) {
                coin.safeIncreaseAllowance(address(pool), transferred);
            }
        }
        pool.addLiquidity(amounts, minMintAmount, deadline);
        uint256 lpAmount = token.balanceOf(address(this));
        token.safeTransfer(to, lpAmount);
        return lpAmount;
    }

    function addPoolAndBaseLiquidity(
        IStableSwap pool,
        IStableSwap basePool,
        uint256[] memory meta_amounts,
        uint256[] memory base_amounts,
        uint256 minToMint,
        address to,
        uint256 deadline
    ) external override returns (uint256) {
        IERC20 token = IERC20(pool.getLpToken());
        IERC20 base_lp = IERC20(basePool.getLpToken());
        require(base_amounts.length == basePool.getNumberOfTokens(), "invalidBaseAmountsLength");
        require(meta_amounts.length == pool.getNumberOfTokens(), "invalidMetaAmountsLength");
        bool deposit_base = false;
        for (uint8 i = 0; i < base_amounts.length; i++) {
            uint256 amount = base_amounts[i];
            if (amount > 0) {
                deposit_base = true;
                IERC20 coin = basePool.getToken(i);
                uint256 transferred = transferIn(coin, msg.sender, amount);
                coin.safeIncreaseAllowance(address(basePool), transferred);
                base_amounts[i] = transferred;
            }
        }

        uint256 base_lp_received;
        if (deposit_base) {
            base_lp_received = basePool.addLiquidity(base_amounts, 0, deadline);
        }

        for (uint8 i = 0; i < meta_amounts.length; i++) {
            IERC20 coin = pool.getToken(i);

            uint256 transferred;
            if (address(coin) == address(base_lp)) {
                transferred = base_lp_received;
            } else if (meta_amounts[i] > 0) {
                transferred = transferIn(coin, msg.sender, meta_amounts[i]);
            }

            meta_amounts[i] = transferred;
            if (transferred > 0) {
                coin.safeIncreaseAllowance(address(pool), transferred);
            }
        }

        uint256 base_lp_prior = base_lp.balanceOf(address(this));
        pool.addLiquidity(meta_amounts, minToMint, deadline);
        if (deposit_base) {
            require((base_lp.balanceOf(address(this)) + base_lp_received) == base_lp_prior, "invalidBasePool");
        }

        uint256 lpAmount = token.balanceOf(address(this));
        token.safeTransfer(to, lpAmount);
        return lpAmount;
    }

    function removePoolLiquidity(
        IStableSwap pool,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        IERC20 token = pool.getLpToken();
        token.safeTransferFrom(msg.sender, address(this), lpAmount);
        token.safeIncreaseAllowance(address(pool), lpAmount);
        pool.removeLiquidity(lpAmount, minAmounts, deadline);
        amounts = new uint256[](pool.getNumberOfTokens());
        for (uint8 i = 0; i < pool.getNumberOfTokens(); i++) {
            IERC20 coin = pool.getToken(i);
            amounts[i] = coin.balanceOf(address(this));
            if (amounts[i] > 0) {
                coin.safeTransfer(to, amounts[i]);
            }
        }
    }

    function removePoolLiquidityOneToken(
        IStableSwap pool,
        uint256 lpAmount,
        uint8 index,
        uint256 minAmount,
        address to,
        uint256 deadline
    ) external override returns (uint256) {
        IERC20 token = pool.getLpToken();
        token.safeTransferFrom(msg.sender, address(this), lpAmount);
        token.safeIncreaseAllowance(address(pool), lpAmount);
        pool.removeLiquidityOneToken(lpAmount, index, minAmount, deadline);
        IERC20 coin = pool.getToken(index);
        uint256 coin_amount = coin.balanceOf(address(this));
        coin.safeTransfer(to, coin_amount);
        return coin_amount;
    }

    function removePoolAndBaseLiquidity(
        IStableSwap pool,
        IStableSwap basePool,
        uint256 _amount,
        uint256[] calldata min_amounts_meta,
        uint256[] calldata min_amounts_base,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts, uint256[] memory base_amounts) {
        IERC20 token = pool.getLpToken();
        IERC20 baseToken = basePool.getLpToken();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        token.safeIncreaseAllowance(address(pool), _amount);
        pool.removeLiquidity(_amount, min_amounts_meta, deadline);
        uint256 _base_amount = baseToken.balanceOf(address(this));
        baseToken.safeIncreaseAllowance(address(basePool), _base_amount);

        basePool.removeLiquidity(_base_amount, min_amounts_base, deadline);
        // Transfer all coins out
        amounts = new uint256[](pool.getNumberOfTokens());
        for (uint8 i = 0; i < pool.getNumberOfTokens(); i++) {
            IERC20 coin = pool.getToken(i);
            amounts[i] = coin.balanceOf(address(this));
            if (amounts[i] > 0) {
                coin.safeTransfer(to, amounts[i]);
            }
        }

        base_amounts = new uint256[](basePool.getNumberOfTokens());
        for (uint8 i = 0; i < basePool.getNumberOfTokens(); i++) {
            IERC20 coin = basePool.getToken(i);
            base_amounts[i] = coin.balanceOf(address(this));
            if (base_amounts[i] > 0) {
                coin.safeTransfer(to, base_amounts[i]);
            }
        }
    }

    function removePoolAndBaseLiquidityOneToken(
        IStableSwap pool,
        IStableSwap basePool,
        uint256 _token_amount,
        uint8 i,
        uint256 _min_amount,
        address to,
        uint256 deadline
    ) external override returns (uint256) {
        IERC20 token = pool.getLpToken();
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        token.safeTransferFrom(msg.sender, address(this), _token_amount);
        token.safeIncreaseAllowance(address(pool), _token_amount);
        pool.removeLiquidityOneToken(_token_amount, baseTokenIndex, 0, deadline);
        uint256 _base_amount = baseToken.balanceOf(address(this));
        baseToken.safeIncreaseAllowance(address(basePool), _base_amount);
        basePool.removeLiquidityOneToken(_base_amount, i, _min_amount, deadline);
        IERC20 coin = basePool.getToken(i);
        uint256 coin_amount = coin.balanceOf(address(this));
        coin.safeTransfer(to, coin_amount);
        return coin_amount;
    }

    function swapPool(
        IStableSwap pool,
        uint8 fromIndex,
        uint8 toIndex,
        uint256 inAmount,
        uint256 minOutAmount,
        address to,
        uint256 deadline
    ) external override returns (uint256) {
        IERC20 coin = pool.getToken(fromIndex);
        coin.safeTransferFrom(msg.sender, address(this), inAmount);
        coin.safeIncreaseAllowance(address(pool), inAmount);
        pool.swap(fromIndex, toIndex, inAmount, minOutAmount, deadline);
        IERC20 coinTo = pool.getToken(toIndex);
        uint256 amountOut = coinTo.balanceOf(address(this));
        coinTo.safeTransfer(to, amountOut);
        return amountOut;
    }

    function swapPoolFromBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        address to,
        uint256 deadline
    ) external override returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256[] memory base_amounts = new uint256[](basePool.getNumberOfTokens());
        base_amounts[tokenIndexFrom] = dx;
        IERC20 coin = basePool.getToken(tokenIndexFrom);
        coin.safeTransferFrom(msg.sender, address(this), dx);
        coin.safeIncreaseAllowance(address(basePool), dx);
        uint256 baseLpAmount = basePool.addLiquidity(base_amounts, 0, deadline);
        if (baseTokenIndex != tokenIndexTo) {
            baseToken.safeIncreaseAllowance(address(pool), baseLpAmount);
            pool.swap(baseTokenIndex, tokenIndexTo, baseLpAmount, minDy, deadline);
        }
        IERC20 coinTo = pool.getToken(tokenIndexTo);
        uint256 amountOut = coinTo.balanceOf(address(this));
        coinTo.safeTransfer(to, amountOut);
        return amountOut;
    }

    function swapPoolToBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        address to,
        uint256 deadline
    ) external override returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        IERC20 coin = pool.getToken(tokenIndexFrom);
        coin.safeTransferFrom(msg.sender, address(this), dx);
        uint256 tokenLPAmount = dx;
        if (baseTokenIndex != tokenIndexFrom) {
            coin.safeIncreaseAllowance(address(pool), dx);
            tokenLPAmount = pool.swap(tokenIndexFrom, baseTokenIndex, dx, 0, deadline);
        }
        baseToken.safeIncreaseAllowance(address(basePool), tokenLPAmount);
        basePool.removeLiquidityOneToken(tokenLPAmount, tokenIndexTo, minDy, deadline);
        IERC20 coinTo = basePool.getToken(tokenIndexTo);
        uint256 amountOut = coinTo.balanceOf(address(this));
        coinTo.safeTransfer(to, amountOut);
        return amountOut;
    }

    // =========== VIEW ===========

    function calculateConvert(
        IStableSwap fromPool,
        IStableSwap toPool,
        uint256 amount
    ) external override view returns (uint256) {
        uint256 fromPoolLength = fromPool.getNumberOfTokens();
        uint256[] memory amounts = fromPool.calculateRemoveLiquidity(amount);
        uint256[] memory meta_amounts = new uint256[](fromPoolLength);
        for (uint8 i = 0; i < fromPoolLength; i++) {
            IERC20 fromCoin = fromPool.getToken(i);
            uint256 toCoinIndex = toPool.getTokenIndex(address(fromCoin));
            meta_amounts[toCoinIndex] = amounts[i];
        }
        return toPool.calculateTokenAmount(meta_amounts, true);
    }

    function calculateTokenAmount(
        IStableSwap pool,
        IStableSwap basePool,
        uint256[] memory meta_amounts,
        uint256[] memory base_amounts,
        bool is_deposit
    ) external override view returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256 _base_tokens = basePool.calculateTokenAmount(base_amounts, is_deposit);
        meta_amounts[baseTokenIndex] = meta_amounts[baseTokenIndex] + _base_tokens;
        return pool.calculateTokenAmount(meta_amounts, is_deposit);
    }

    function calculateRemoveLiquidity(
        IStableSwap pool,
        IStableSwap basePool,
        uint256 amount
    ) external override view returns (uint256[] memory meta_amounts, uint256[] memory base_amounts) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        meta_amounts = pool.calculateRemoveLiquidity(amount);
        uint256 lpAmount = meta_amounts[baseTokenIndex];
        meta_amounts[baseTokenIndex] = 0;
        base_amounts = basePool.calculateRemoveLiquidity(lpAmount);
    }

    function calculateRemoveBaseLiquidityOneToken(
        IStableSwap pool,
        IStableSwap basePool,
        uint256 _token_amount,
        uint8 iBase
    ) external override view returns (uint256 availableTokenAmount) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256 _base_tokens = pool.calculateRemoveLiquidityOneToken(_token_amount, baseTokenIndex);
        availableTokenAmount = basePool.calculateRemoveLiquidityOneToken(_base_tokens, iBase);
    }

    function calculateSwap(
        IStableSwap pool,
        uint8 fromIndex,
        uint8 toIndex,
        uint256 inAmount
    ) external override view returns (uint256) {
        return pool.calculateSwap(fromIndex, toIndex, inAmount);
    }

    function calculateSwapFromBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external override view returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256[] memory base_amounts = new uint256[](basePool.getNumberOfTokens());
        base_amounts[tokenIndexFrom] = dx;
        uint256 baseLpAmount = basePool.calculateTokenAmount(base_amounts, true);
        if (baseTokenIndex == tokenIndexTo) {
            return baseLpAmount;
        }
        return pool.calculateSwap(baseTokenIndex, tokenIndexTo, baseLpAmount);
    }

    function calculateSwapToBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external override view returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256 tokenLPAmount = dx;
        if (baseTokenIndex != tokenIndexFrom) {
            tokenLPAmount = pool.calculateSwap(tokenIndexFrom, baseTokenIndex, dx);
        }
        return basePool.calculateRemoveLiquidityOneToken(tokenLPAmount, tokenIndexTo);
    }

    function transferIn(
        IERC20 token,
        address from,
        uint256 amount
    ) internal returns (uint256 transferred) {
        uint256 prior_balance = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        transferred = token.balanceOf(address(this)) - prior_balance;
    }
}