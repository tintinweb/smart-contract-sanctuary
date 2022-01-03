/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

// File: interfaces/IBondDepository.sol



pragma solidity ^0.8.0;

interface IKlimaBondDepository {
    function bondPriceInUSD() external view returns (uint256 price_);

    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_);
}

// File: interfaces/IwsKLIMA.sol



pragma solidity ^0.8.0;

interface IwsKLIMA {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function wKLIMATosKLIMA(uint256 _amount) external view returns (uint256);

    function sKLIMATowKLIMA(uint256 _amount) external view returns (uint256);
}

// File: interfaces/IStakingHelper.sol



pragma solidity ^0.8.0;

interface IStakingHelper {
    function stake(uint256 _amount) external;
}

// File: interfaces/IStaking.sol



pragma solidity ^0.8.0;

interface IStaking {
    function unstake(uint256 _amount, bool _trigger) external;
}

// File: interfaces/IBaseCarbonTonne.sol



pragma solidity ^0.8.0;

interface IBaseCarbonTonne {
    function redeemMany(address[] calldata erc20s, uint256[] calldata amounts)
        external;
}

// File: interfaces/IToucanCarbonOffsets.sol



pragma solidity ^0.8.0;

interface IToucanCarbonOffsets {
    function retire(uint256 amount) external;
}

// File: interfaces/IUniswapV2Router01.sol



pragma solidity >=0.6.2;

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

// File: interfaces/IUniswapV2Router02.sol



pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: interfaces/IUniswapV2Pair.sol



pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Ownable.sol



// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/SafeERC20.sol



// File: contracts/RetireToucanCarbon.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RetireToucanCarbon is Ownable {
    using SafeERC20 for IERC20;

    constructor(
        address _KLIMA,
        address _sKLIMA,
        address _wsKLIMA,
        address _USDC,
        address _staking,
        address _stakingHelper,
        address _DAO
    ) {
        KLIMA = _KLIMA;
        sKLIMA = _sKLIMA;
        wsKLIMA = _wsKLIMA;
        USDC = _USDC;
        staking = _staking;
        stakingHelper = _stakingHelper;
        DAO = _DAO;
    }

    address public immutable KLIMA;
    address public immutable sKLIMA;
    address public immutable wsKLIMA;
    address public immutable USDC;
    address public immutable staking;
    address public immutable stakingHelper;
    address public immutable DAO;

    event ToucanRetired(
        address retiree,
        string beneficiary,
        address carbonPool,
        address carbonToken,
        uint256 amount
    );
    event PoolAdded(address carbonPool, bool result);
    event FeeUpdated(uint256 oldFee, uint256 newFee);

    address[] public toucanPools;
    mapping(address => bool) public isToucanPool;
    mapping(address => address) public poolRouter;
    mapping(address => address) public bondDepository;

    uint256 feeAmount;

    function retireWithKLIMA(
        uint256 _amount,
        string calldata _beneficiary,
        address _KlimaType,
        address[] calldata _listTCO2,
        address _toucanPool
    ) public {
        require(isToucanPool[_toucanPool], "Not a Toucan Protocol Carbon Pool");

        uint256 totalPoolNeeded = (_amount * (1000 + feeAmount)) / 1000;

        (uint256 amountIn, address[] memory path) = getNeededKLIMA(
            _toucanPool,
            poolRouter[_toucanPool],
            totalPoolNeeded
        );

        uint256 unwrappedKLIMA;

        if (_KlimaType == wsKLIMA) {
            // Get wsKLIMA needed, transfer and unwrap, unstake to KLIMA
            uint256 wsKLIMANeeded = IwsKLIMA(wsKLIMA).sKLIMATowKLIMA(amountIn);

            IERC20(wsKLIMA).safeTransferFrom(
                msg.sender,
                address(this),
                wsKLIMANeeded
            );
            IERC20(wsKLIMA).approve(wsKLIMA, wsKLIMANeeded);
            unwrappedKLIMA = IwsKLIMA(wsKLIMA).unwrap(wsKLIMANeeded);
            IERC20(sKLIMA).safeIncreaseAllowance(staking, unwrappedKLIMA);
            IStaking(staking).unstake(unwrappedKLIMA, false);
        }

        // If using sKLIMA, transfer in and unstake
        if (_KlimaType == sKLIMA) {
            IERC20(sKLIMA).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
            IERC20(sKLIMA).safeIncreaseAllowance(staking, amountIn);
            IStaking(staking).unstake(amountIn, false);
        }

        // If using KLIMA, transfer in
        if (_KlimaType == KLIMA) {
            IERC20(KLIMA).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        IERC20(KLIMA).safeIncreaseAllowance(poolRouter[_toucanPool], amountIn);

        uint256[] memory amounts = IUniswapV2Router02(poolRouter[_toucanPool])
            .swapTokensForExactTokens(
                totalPoolNeeded,
                amountIn,
                path,
                address(this),
                block.timestamp
            );
        // Return any dust remaining (slippage protection)

        uint256 tradeDust;

        if (_KlimaType == KLIMA) {
            tradeDust = amountIn - (amounts[0] == 0 ? amounts[1] : amounts[0]);
            IERC20(KLIMA).safeTransfer(msg.sender, tradeDust);
        }
        if (_KlimaType == sKLIMA) {
            tradeDust = amountIn - (amounts[0] == 0 ? amounts[1] : amounts[0]);
            IERC20(KLIMA).safeIncreaseAllowance(stakingHelper, tradeDust);

            IStakingHelper(stakingHelper).stake(tradeDust);

            IERC20(sKLIMA).safeTransfer(msg.sender, tradeDust);
        }
        if (_KlimaType == wsKLIMA) {
            tradeDust =
                unwrappedKLIMA -
                (amounts[0] == 0 ? amounts[1] : amounts[0]);
            IERC20(KLIMA).safeIncreaseAllowance(stakingHelper, tradeDust);

            IStakingHelper(stakingHelper).stake(tradeDust);
            IERC20(sKLIMA).safeIncreaseAllowance(wsKLIMA, tradeDust);
            uint256 wrappedDust = IwsKLIMA(wsKLIMA).wrap(tradeDust);
            IERC20(wsKLIMA).safeTransfer(msg.sender, wrappedDust);
        }

        _retireCarbon(_amount, _beneficiary, _listTCO2, _toucanPool);

        _bondFees(_toucanPool);
    }

    function retireWithUSDC(
        uint256 _amount,
        string calldata _beneficiary,
        address[] calldata _listTCO2,
        address _toucanPool
    ) public {
        require(isToucanPool[_toucanPool], "Not a Toucan Protocol Carbon Pool");

        uint256 totalPoolNeeded = (_amount * (1000 + feeAmount)) / 1000;

        (uint256 amountIn, address[] memory path) = getNeededUSDC(
            _toucanPool,
            poolRouter[_toucanPool],
            totalPoolNeeded
        );

        // Transfer and swap from USDC to Carbon Pool

        IERC20(USDC).safeTransferFrom(msg.sender, address(this), amountIn);

        IERC20(USDC).safeIncreaseAllowance(poolRouter[_toucanPool], amountIn);

        uint256[] memory amounts = IUniswapV2Router02(poolRouter[_toucanPool])
            .swapTokensForExactTokens(
                totalPoolNeeded,
                amountIn,
                path,
                address(this),
                block.timestamp
            );
        // Return any dust remaining (slippage protection)

        uint256 tradeDust = amountIn -
            (amounts[0] == 0 ? amounts[1] : amounts[0]);

        IERC20(USDC).safeTransfer(msg.sender, tradeDust);

        _retireCarbon(_amount, _beneficiary, _listTCO2, _toucanPool);

        _bondFees(_toucanPool);
    }

    function retireWithPool(
        uint256 _amount,
        string calldata _beneficiary,
        address[] calldata _listTCO2,
        address _toucanPool
    ) public {
        require(isToucanPool[_toucanPool], "Not a Toucan Protocol Carbon Pool");

        uint256 totalPoolNeeded = (_amount * (1000 + feeAmount)) / 1000;

        // Transfer in the pool token to retire
        IERC20(_toucanPool).safeTransferFrom(
            msg.sender,
            address(this),
            totalPoolNeeded
        );

        // Retire the carbon
        _retireCarbon(_amount, _beneficiary, _listTCO2, _toucanPool);

        _bondFees(_toucanPool);
    }

    function _retireCarbon(
        uint256 _amount,
        string calldata _beneficiary,
        address[] calldata _listTCO2,
        address _toucanPool
    ) internal {
        // The carbon to be retired should be transferred or swapped inside this contract before calling this function.
        uint256 leftToBurn = _amount;

        for (uint256 i = 0; i < _listTCO2.length && leftToBurn > 0; i++) {
            // Start with the first address in the list and work your way down.

            // Get the pools balance of TCO2
            uint256 poolBalance = IERC20(_listTCO2[i]).balanceOf(_toucanPool);

            // Error check for possible 0 balance / stale lists
            if (poolBalance == 0) {} else {
                address[] memory redeemERC20 = new address[](1);
                redeemERC20[0] = _listTCO2[i];

                uint256[] memory redeemAmount = new uint256[](1);

                // Burn only pool balance if there are more pool tokens than available
                if (leftToBurn > poolBalance) {
                    // Redeem from pool
                    redeemAmount[0] = poolBalance;
                    IBaseCarbonTonne(_toucanPool).redeemMany(
                        redeemERC20,
                        redeemAmount
                    );

                    // Retire TCO2
                    IToucanCarbonOffsets(_listTCO2[i]).retire(poolBalance);
                    emit ToucanRetired(
                        msg.sender,
                        _beneficiary,
                        _toucanPool,
                        _listTCO2[i],
                        poolBalance
                    );

                    leftToBurn -= poolBalance;
                } else {
                    // Redeem from pool
                    redeemAmount[0] = leftToBurn;
                    IBaseCarbonTonne(_toucanPool).redeemMany(
                        redeemERC20,
                        redeemAmount
                    );

                    // Retire TCO2
                    IToucanCarbonOffsets(_listTCO2[i]).retire(leftToBurn);
                    emit ToucanRetired(
                        msg.sender,
                        _beneficiary,
                        _toucanPool,
                        _listTCO2[i],
                        leftToBurn
                    );

                    leftToBurn = 0;
                }
            }
        }

        require(
            leftToBurn == 0,
            "Not all pool tokens were burned. Please submit a larger TCO2 token list."
        );
    }

    function _bondFees(address _toucanPool) internal returns (bool) {
        // Bond cumulative fees to the DAO if bond is large enough
        uint256 poolBalance = IERC20(_toucanPool).balanceOf(address(this));

        uint256 bondPrice = IKlimaBondDepository(bondDepository[_toucanPool])
            .bondPriceInUSD();

        if ((poolBalance * (10**9)) / bondPrice > 10000000) {
            IERC20(_toucanPool).safeIncreaseAllowance(
                bondDepository[_toucanPool],
                poolBalance
            );

            IKlimaBondDepository(bondDepository[_toucanPool]).deposit(
                poolBalance,
                bondPrice,
                DAO
            );
        }
        return true;
    }

    function setFeeAmount(uint256 _amount) external onlyOwner returns (bool) {
        emit FeeUpdated(feeAmount, _amount);

        feeAmount = _amount;
        return true;
    }

    function setPoolRouter(address _toucanPool, address _router)
        external
        onlyOwner
        returns (bool)
    {
        poolRouter[_toucanPool] = _router;
        return true;
    }

    function addPool(
        address _toucanPool,
        address _router,
        address _bondDepository
    ) external onlyOwner returns (bool) {
        bool result;

        require(!listContains(toucanPools, _toucanPool), "Pool already added");

        if (!listContains(toucanPools, _toucanPool)) {
            toucanPools.push(_toucanPool);
        }
        result = !isToucanPool[_toucanPool];
        isToucanPool[_toucanPool] = result;
        poolRouter[_toucanPool] = _router;
        bondDepository[_toucanPool] = _bondDepository;

        emit PoolAdded(_toucanPool, result);
        return true;
    }

    function updateBondDepository(address _toucanPool, address _bondDepository)
        external
        onlyOwner
        returns (bool)
    {
        require(isToucanPool[_toucanPool], "Not a Toucan Carbon Pool");

        bondDepository[_toucanPool] = _bondDepository;
        return true;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains(address[] storage _list, address _token)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function getNeededUSDC(
        address _toucanPool,
        address _router,
        uint256 _poolAmount
    ) public view returns (uint256, address[] memory) {
        address[] memory path = new address[](2);

        path[0] = USDC;
        path[1] = _toucanPool;

        uint256[] memory amountIn = IUniswapV2Router02(_router).getAmountsIn(
            _poolAmount,
            path
        );

        return ((amountIn[0] * 1005) / 1000, path); // Account for .5% slippage
    }

    function getNeededKLIMA(
        address _toucanPool,
        address _router,
        uint256 _poolAmount
    ) public view returns (uint256, address[] memory) {
        address[] memory path = new address[](2);

        path[0] = KLIMA;
        path[1] = _toucanPool;

        uint256[] memory amountIn = IUniswapV2Router02(_router).getAmountsIn(
            _poolAmount,
            path
        );

        return ((amountIn[0] * 1005) / 1000, path); // Account for .5% slippage
    }

    // To withdraw any potentially un-bonded fees

    function emergencyWithdraw(address _token) public onlyOwner returns (bool) {
        IERC20(_token).safeTransfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );

        return true;
    }
}