/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol



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

// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol



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
        //unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        //}
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

// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin\contracts\utils\cryptography\ECDSA.sol



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: node_modules\@uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: ..\src\AngryContract.sol


pragma solidity ^0.8.4;





interface IBurnable{
    function burn(uint256 amount) external;
}

contract AngryContract{
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    
    address public constant ANGRY_TOKEN_ADDRESS = 0x1368D135f47202c134Ec4A0415908E91a34E4E1F;  //ANB代币地址
    address public constant USDT_TOKEN_ADDRESS = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;  //USDT代币地址
    address public constant VITALIK_BUTERIN_ADDRESS = 0x4486a5ba2fC9ffaE18454526e949646Ee88aa7c8; //V神账号地址
    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  //Uniswap Router V2地址
    uint256 public constant MAX_MINING_TASK_REWARD = 100000000;  //每次挖矿最多投放1亿枚
    uint256 public constant PREPURCHASE_SUPPLY_PER_DAY = 426137000;  //每天释放4.26137亿枚币用于预购
    uint256 public constant VB_WITHDRAW_AMOUNT_PER_DAY = 5479;  //V神每天可以领取的ANB数量
    
    struct PrePurchaseInfo {
        uint256 amount;
        uint256 paymentAmount;
        uint256 price;
        uint256 expectedPrice;
        uint256 startTime;
        uint256 expiredTime;
        uint8 status;  // 0: not deal, 1 : deal, 2 : cancel, 3 : confirm, 4 : expired
        uint8 paymentType; // 1:ETH, 2:USDT
    }
    
    struct MiningPoolInfo {
        uint256 beginTime;
        uint256 endTime;
        uint256 rewardAmount;
        uint256 claimedAmount;
        uint256 burnedAmount;
        mapping(address => uint8) claimedAccounts;
    }
    
    struct ClaimRewardsInfo {
        string taskId;
        uint256 amount;
        uint256 time;
    }
    
    IERC20 public angryToken = IERC20(ANGRY_TOKEN_ADDRESS);
    IERC20 public usdtToken = IERC20(USDT_TOKEN_ADDRESS);
    IUniswapV2Router02 public uniswapRouterV2 = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    uint256 private angryTokenDecimals;
    uint256 public maxPriceMultiple = 2;
    uint256 public minTokenAmountToPrePurchase = 100;
    uint256 public maxPrePurchaseMultiple = 10;
    uint256 public prePurchaseLimitPerAcc = 10000000;
    uint256 public vsWithdrawAmount;
    uint256 public vsBurnAmount;
    uint256 public vsLastWithdrawTime;
    uint256 public lastMiningTaskTime;
    uint256 public startTime;
    uint256 public totalPrePurcaseAmount;
    uint256 public cancelOrderFeeRate;
    uint256 public feeUSDT;
    uint256 public feeETH;
    uint256 public revenueUSDT;
    uint256 public revenueETH;
    address public owner;
    address public executor;
    address[] public prePurchaseAccounts;
    mapping(address => PrePurchaseInfo[]) public prePurchaseList;
    mapping(address => ClaimRewardsInfo[]) public claimList;
    mapping(string => MiningPoolInfo) public miningPoolInfos;
    
    event PrePurchase(address _userAddr, uint256 _orderIdx, uint256 _amount, uint256 _paymentAmount, uint256 _price, uint256 _expectedPrice, uint256 _startTime, uint256 _expiredTime, uint8 _paymentType, uint8 _status);
    event Withdraw(address _recvAddr, uint256 _revenueETH, uint256 _revenueUSDT, uint256 _feeETH, uint256 _feeUSDT);
    event OrderConfirm(address _userAddr, uint256 _orderIdx, uint8 _orderStatus);
    event OrderExpire(address _userAddr, uint256 _orderIdx, uint8 _orderStatus);
    event OrderComplete(address _userAddr, uint256 _orderIdx, uint8 _orderStatus);
    event FeeChange(uint256 _oldValue, uint256 _newValue);
    event VBRewardBurn(uint256 _amount);
    event MineRemainingBurn(string _taskId, uint256 _amount);
    event OrderCancel(address _userAddr, uint256 _orderIdx, uint8 _orderStatus);
    event VbWithdraw(uint256 _amount);
    event ExecutorChange(address _oldAddr, address _newAddr);
    event MineRewardsWithdraw(address _userAddr, string _invoiceId, uint256 _amount);
    event PrePurchaseaArgsChange(uint256 _minTokenAmountOld,uint256 _maxMultipleOld,uint256 _limitPerAccOld,uint256 _minTokenAmountNew,uint256 _maxMultipleNew,uint256 _limitPerAccNew);
    event MaxPriceMultipleChange(uint256 _oldValue, uint256 _newValue);
    event ANBWithdraw(address _receiver, uint256 _amount);
    event MineTaskAdd(string _taskId, uint256 _rewardAmount, uint256 _beginTime, uint256 _endTime);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyExecutor {
        require(msg.sender == executor);
        _;
    }
    
    constructor (){
        owner = msg.sender;
        executor = msg.sender;
        startTime = block.timestamp;
        angryTokenDecimals = IERC20Metadata(ANGRY_TOKEN_ADDRESS).decimals();
    }
    
    function setExecutor(address _newExecutor) onlyOwner public {
        emit ExecutorChange(executor, _newExecutor);
        executor = _newExecutor;
    }
    
    function withdrawRevenueAndFee(address _receiver) onlyOwner public {
        uint256 ethAmount = revenueETH + feeETH;
        uint256 usdtAmount = revenueUSDT + feeUSDT;
        if(ethAmount > 0){
            payable(_receiver).transfer(ethAmount);
        }
        if(usdtAmount > 0){
            usdtToken.safeTransfer(_receiver, usdtAmount);
        }
        emit Withdraw(_receiver, revenueETH, revenueUSDT, feeETH, feeUSDT);
        revenueETH = 0;
        revenueUSDT = 0;
        feeETH = 0;
        feeUSDT = 0;
    }
    
    function vitalikButerinWithdraw() public {
        require ( msg.sender == VITALIK_BUTERIN_ADDRESS, "Only for Vitalik Buterin!" );
        require ( (block.timestamp - vsLastWithdrawTime) > (1 days), "Withdraw once a day!" );
        uint256 amount = VB_WITHDRAW_AMOUNT_PER_DAY * 10 ** angryTokenDecimals;
        vsLastWithdrawTime = block.timestamp;
        vsWithdrawAmount = vsWithdrawAmount + amount;
        angryToken.safeTransfer(VITALIK_BUTERIN_ADDRESS, amount);
        emit VbWithdraw(amount);
    }
    
    function burnVbUnclaimANB() public {
        uint256 totalAmount = ((block.timestamp - startTime) / (1 days)) * VB_WITHDRAW_AMOUNT_PER_DAY * 10 ** angryTokenDecimals;
        uint256 toBurnAmount = 0;
        if(totalAmount > (vsWithdrawAmount + vsBurnAmount)){
            toBurnAmount = totalAmount - (vsWithdrawAmount + vsBurnAmount);
            IBurnable(ANGRY_TOKEN_ADDRESS).burn(toBurnAmount);
            vsBurnAmount = vsBurnAmount + toBurnAmount;
        }
        emit VBRewardBurn(toBurnAmount);
    }
    
    function queryRevenueAndFee() view public returns (uint256 _revenueETH, uint256 _revenueUSDT, uint256 _feeETH, uint256 _feeUSDT) {
        return (revenueETH, revenueUSDT, feeETH, feeUSDT);
    }
    
    function setPrePurchaseaArgs(uint256 _minTokenAmount, uint256 _maxMultiple, uint256 _limitPerAcc) public onlyExecutor {
        emit PrePurchaseaArgsChange(minTokenAmountToPrePurchase,maxPrePurchaseMultiple,prePurchaseLimitPerAcc,_minTokenAmount,_maxMultiple,_limitPerAcc);
        minTokenAmountToPrePurchase = _minTokenAmount;
        maxPrePurchaseMultiple = _maxMultiple;
        prePurchaseLimitPerAcc = _limitPerAcc;
    }
    
    function getPrePurchaseaArgs() view public returns (uint256 _minTokenAmount, uint256 _maxMultiple, uint256 _limitPerAcc){
        return (minTokenAmountToPrePurchase,maxPrePurchaseMultiple,prePurchaseLimitPerAcc);
    }
    
    function processPrePurchaseOrder(address _addr, uint256 _orderIdx) private {
        uint256 repurchase = 0;
        uint256 amount = 0;
        address[] memory path = new address[](2);
        path[1] = ANGRY_TOKEN_ADDRESS;
        PrePurchaseInfo[] storage purchases = prePurchaseList[ _addr ];
        require( purchases.length > _orderIdx, "Order index out of range!" );
        PrePurchaseInfo storage pcInfo = purchases[ _orderIdx ];
        require( pcInfo.status == 3, "Order havn't beed confirmed!" );
        //require( block.timestamp >= pcInfo.startTime && block.timestamp <= pcInfo.expiredTime, "Out of order execution time!" );
        repurchase = pcInfo.paymentAmount / 10;
        if( pcInfo.paymentType == 1 ){
            revenueETH = revenueETH + ( pcInfo.paymentAmount - repurchase );
            path[0] = uniswapRouterV2.WETH();
            amount = uniswapRouterV2.swapExactETHForTokens{value:repurchase}(0, path, address(this), block.timestamp )[1];
            IBurnable(ANGRY_TOKEN_ADDRESS).burn(amount);
        }else{
            revenueUSDT = revenueUSDT + ( pcInfo.paymentAmount - repurchase );
            path[0] = USDT_TOKEN_ADDRESS;
            usdtToken.safeApprove(UNISWAP_ROUTER_ADDRESS,repurchase);
            amount = uniswapRouterV2.swapExactTokensForTokens(repurchase, 0, path, address(this), block.timestamp )[1];
            IBurnable(ANGRY_TOKEN_ADDRESS).burn(amount);
        }
        angryToken.safeTransfer(_addr, pcInfo.amount);
        pcInfo.status = 1;
        emit OrderComplete(_addr, _orderIdx, pcInfo.status);
    }
    
    function confirmPrePurchaseOrders(address[] calldata _addrList, uint256[] calldata _orderIdxList, bool _bProcess) onlyExecutor public {
        require ( _addrList.length == _orderIdxList.length, "Inconsistent array length!" );
        for ( uint256 i = 0;i < _addrList.length; i++){
            PrePurchaseInfo[] storage purchases = prePurchaseList[ _addrList[i] ];
            require( purchases.length > _orderIdxList[i], "Order index out of range!" );
            PrePurchaseInfo storage pcInfo = purchases[ _orderIdxList[i] ];
            require( pcInfo.status == 0, "Unexpected order status!" );
            pcInfo.status = 3;
            emit OrderConfirm(_addrList[i], _orderIdxList[i], pcInfo.status);
            if(_bProcess){
                processPrePurchaseOrder(_addrList[i], _orderIdxList[i]);
            }
        }
    }
    
    function expirePrePurchaseOrders(address[] calldata _addrList, uint256[] calldata _orderIdxList) onlyExecutor public {
        require ( _addrList.length == _orderIdxList.length, "Inconsistent array length!" );
        for ( uint256 i = 0;i < _addrList.length; i++){
            PrePurchaseInfo[] storage purchases = prePurchaseList[ _addrList[i] ];
            require( purchases.length > _orderIdxList[i], "Order index out of range!" );
            PrePurchaseInfo storage pcInfo = purchases[ _orderIdxList[i] ];
            require( pcInfo.status == 0, "Unexpected order status!" );
            pcInfo.status = 4;
            emit OrderExpire(_addrList[i], _orderIdxList[i], pcInfo.status);
        }
    }
    
    function getAccountPurchasedAmount(address _account)  private view returns(uint256) {
        uint256 amount = 0;
        PrePurchaseInfo[] storage purchases = prePurchaseList[ _account ];
        for(uint256 i = 0;i < purchases.length; i++){
            if(purchases[i].status != 0 && purchases[i].status != 1){
                continue;
            }
            amount = amount + purchases[i].amount;
        }
        return amount;
    }
    
    function getAccountPurchaseQuota(address _account) private view returns(uint256) {
        uint256 tokenAmount = angryToken.balanceOf(_account);
        if(tokenAmount < minTokenAmountToPrePurchase * 10 ** angryTokenDecimals){
            return 0;
        }
        uint256 maxAmount = tokenAmount * maxPrePurchaseMultiple;
        uint256 upLimit = prePurchaseLimitPerAcc * 10 ** angryTokenDecimals;
        if(maxAmount > upLimit){
            maxAmount = upLimit;
        }
        uint256 usedAmount = getAccountPurchasedAmount(_account);
        if( usedAmount >= maxAmount ){
            return 0;
        }
        return maxAmount - usedAmount;
    }
    
    function queryCurrPrePurchaseQuota() public view returns (uint256){
        uint256 timeEclapsed = block.timestamp - startTime;
        uint256 ds = timeEclapsed / (1 days);
        uint256 left = timeEclapsed % (1 days);
        if(left > 0){
            ds = ds + 1;
        }
        return ds * PREPURCHASE_SUPPLY_PER_DAY * 10 ** angryTokenDecimals - totalPrePurcaseAmount;
    }
    
    function getAmountsOut(address _addrIn, address _addrOut, uint256 _amountIn) private view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = _addrIn;
        path[1] = _addrOut;
        return uniswapRouterV2.getAmountsOut(_amountIn, path)[1];
    }
    
    function prePurchase(uint256 _expectedPrice, uint256 _startTime, uint256 _expiredTime) public payable {
        require( _expiredTime > _startTime, "Incorrect time period!" );
        uint256 accountQuota = getAccountPurchaseQuota(msg.sender);
        require( accountQuota > 0, "Exceed account quota!" );
        uint256 currAmount = 0;
        uint256 price = 0;
        PrePurchaseInfo[] storage purchases = prePurchaseList[ msg.sender ];
        PrePurchaseInfo memory pcInfo;
        if(msg.value > 0){
            uint256 highestPrice = getAmountsOut(ANGRY_TOKEN_ADDRESS, uniswapRouterV2.WETH(), 10 ** angryTokenDecimals) * maxPriceMultiple;
            if(highestPrice > 0){
                require( _expectedPrice <= highestPrice, "expectedPrice too high!" );
            }
            currAmount = getAmountsOut(uniswapRouterV2.WETH(), ANGRY_TOKEN_ADDRESS, msg.value);
            price = 10 ** angryTokenDecimals * msg.value / currAmount;
            pcInfo.paymentAmount = msg.value;
            pcInfo.paymentType = 1;
        }else{
            uint256 highestPrice = getAmountsOut(ANGRY_TOKEN_ADDRESS, USDT_TOKEN_ADDRESS, 10 ** angryTokenDecimals) * maxPriceMultiple;
            if(highestPrice > 0){
                require( _expectedPrice <= highestPrice, "expectedPrice too high!" );
            }
            uint256 allowance = usdtToken.allowance(msg.sender, address(this));
            require( allowance > 0, "Not any payments!" );
            currAmount = getAmountsOut(USDT_TOKEN_ADDRESS, ANGRY_TOKEN_ADDRESS, allowance);
            price = 10 ** angryTokenDecimals * allowance / currAmount;
            usdtToken.safeTransferFrom(
                msg.sender,
                address(this),
                allowance
            );
            pcInfo.paymentAmount = allowance;
            pcInfo.paymentType = 2;
        }
        uint256 totalQuota = queryCurrPrePurchaseQuota();
        require( (currAmount + totalPrePurcaseAmount) <= totalQuota, "Exceed daily quota!" );
        require( currAmount <= accountQuota, "Exceed account quota!" );
        if(purchases.length == 0){
            prePurchaseAccounts.push(msg.sender);
        }
        pcInfo.amount = currAmount;
        pcInfo.price = price;
        pcInfo.expectedPrice = _expectedPrice;
        pcInfo.startTime = _startTime;
        pcInfo.expiredTime = _expiredTime;
        pcInfo.status = 0;
        purchases.push(pcInfo);
        totalPrePurcaseAmount = totalPrePurcaseAmount + currAmount;
        emit PrePurchase(msg.sender, purchases.length-1, currAmount, pcInfo.paymentAmount, price, _expectedPrice, _startTime, _expiredTime, pcInfo.paymentType, pcInfo.status);
    }
    
    function getAccountPurchasedList(address _user) view public returns (PrePurchaseInfo[] memory){
        return prePurchaseList[_user];
    }
    
    function getPurchasedAccounts() view public returns (address[] memory){
        return prePurchaseAccounts;
    }
    
    function setCancelOrderFee(uint256 _feeRate) onlyExecutor public {
        require(_feeRate <= 100000);
        uint256 oldValue = cancelOrderFeeRate;
        cancelOrderFeeRate = _feeRate;
        emit FeeChange(oldValue, _feeRate);
    }
    
    function getCancelOrderFee() view public returns(uint256) {
        return cancelOrderFeeRate;
    }
    
    function completePrePurchaseOrder(uint256 _orderIdx) public {
        processPrePurchaseOrder(msg.sender, _orderIdx);
    }
    
    function cancelPrePurchaseOrder(uint256 _orderIdx) public {
        PrePurchaseInfo[] storage purchases = prePurchaseList[ msg.sender ];
        require( purchases.length > _orderIdx, "Order index out of range!" );
        PrePurchaseInfo storage pcInfo = purchases[_orderIdx];
        require( pcInfo.status == 0 || pcInfo.status == 4, "Unexpected order status!" );
        uint256 fee = 0;
        uint256 refundAmount = pcInfo.paymentAmount;
        if(cancelOrderFeeRate > 0){
            fee = pcInfo.paymentAmount * cancelOrderFeeRate / 100000;
        }
        if(fee > 0){
            refundAmount = refundAmount - fee;
        }
        if(pcInfo.paymentType == 1){
            feeETH = feeETH + fee;
            payable(msg.sender).transfer(refundAmount);
        }else{
            feeUSDT = feeUSDT + fee;
            usdtToken.safeTransfer(msg.sender, refundAmount);
        }
        pcInfo.status = 2;
        emit OrderCancel(msg.sender, _orderIdx, pcInfo.status);
    }
    
    function getHash(address _userAddr, string calldata _invoiceId, uint256 _amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_userAddr,_invoiceId, _amount));
    }
    
    function withdrawMiningRewards(string calldata _taskId, uint256 _amount, bytes memory _sig) public {
        MiningPoolInfo storage pi = miningPoolInfos[_taskId];
        require( pi.claimedAccounts[msg.sender] == 0, "Can't withdraw twice!" );
        bytes32 hash = getHash(msg.sender,_taskId, _amount);
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(_sig);
        require( signer == executor, "Unexpected signer!" );
        uint256 left = pi.rewardAmount - (pi.claimedAmount + pi.burnedAmount);
        require( _amount <= left, "Insufficient tokens in pool!" );
        angryToken.safeTransfer(msg.sender, _amount);
        pi.claimedAmount = pi.claimedAmount + _amount;
        ClaimRewardsInfo[] storage infos = claimList[ msg.sender ];
        ClaimRewardsInfo memory cri;
        cri.taskId = _taskId;
        cri.amount = _amount;
        cri.time = block.timestamp;
        infos.push(cri);
        emit MineRewardsWithdraw(msg.sender, _taskId, _amount);
    }
    
    function burnMineRemainingTokens(string calldata _taskId, uint256 _amount) public onlyExecutor {
        MiningPoolInfo storage pi = miningPoolInfos[_taskId];
        require( pi.burnedAmount == 0, "Already burned!" );
        uint256 left = pi.rewardAmount - pi.claimedAmount;
        require( _amount <= left , "Amount exceeded!" );
        IBurnable(ANGRY_TOKEN_ADDRESS).burn(_amount);
        pi.burnedAmount = _amount;
        emit MineRemainingBurn(_taskId, _amount);
    }
    
    function getMaxPriceMultiple() public view returns(uint256) {
        return maxPriceMultiple;
    }
    
    function setMaxPriceMultiple(uint256 _newValue) public onlyExecutor {
        emit MaxPriceMultipleChange(maxPriceMultiple, _newValue);
        maxPriceMultiple = _newValue;
    }
    
    function getHighestExpectedPrice() public view returns(uint256 _ethPrice, uint256 _usdtPrice){
        _ethPrice = getAmountsOut(ANGRY_TOKEN_ADDRESS, uniswapRouterV2.WETH(), 10 ** angryTokenDecimals) * maxPriceMultiple;
        _usdtPrice = getAmountsOut(ANGRY_TOKEN_ADDRESS, USDT_TOKEN_ADDRESS, 10 ** angryTokenDecimals) * maxPriceMultiple;
    }
    
    function withdrawANB(address _receiver, uint256 _amount) public onlyOwner {
        angryToken.safeTransfer(_receiver, _amount);
        emit ANBWithdraw(_receiver, _amount);
    }
    
    function newMiningTask(string calldata _taskId, uint256 _rewardAmount, uint256 _beginTime, uint256 _endTime) public onlyExecutor {
        require( _endTime > _beginTime, "Incorrect time period!" );
        require( _rewardAmount <= MAX_MINING_TASK_REWARD * 10 ** angryTokenDecimals, "Amount exceeded!" );
        MiningPoolInfo storage pi = miningPoolInfos[_taskId];
        require( pi.rewardAmount == 0, "Duplicate task!" );
        pi.rewardAmount = _rewardAmount;
        pi.beginTime = _beginTime;
        pi.endTime = _endTime;
        emit MineTaskAdd(_taskId, _rewardAmount, _beginTime, _endTime);
    }
    
    function getMiningTaskInfo(string calldata _taskId) public view returns(uint256 _rewardAmount, uint256 _claimedAmount, uint256 _burnedAmount) {
        MiningPoolInfo storage pi = miningPoolInfos[_taskId];
        _rewardAmount = pi.rewardAmount;
        _claimedAmount = pi.claimedAmount;
        _burnedAmount = pi.burnedAmount;
    }
    
    function getAccountMingTaskInfo(address _addr) public view returns (ClaimRewardsInfo[] memory){
        return claimList[_addr];
    }
}