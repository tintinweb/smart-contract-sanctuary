// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

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
}

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is Ownable {
    uint256 public constant DENOMINATOR = 10000;

    uint256 public executorFeeNumerator = 15;
    uint256 public feeNumerator = 5;

    address public feeTo;

    event FeeSet(uint256 feeNumerator, uint256 timestamp);
    event ExecutorFeeSet(uint256 executorFeeNumerator, uint256 timestamp);
    event FeeToSet(address feeTo, uint256 timestamp);

    function calculateFees(uint256 _amount)
        public
        view
        returns (uint256 fee, uint256 executorFee)
    {
        fee = (_amount * feeNumerator) / DENOMINATOR;
        executorFee = (_amount * executorFeeNumerator) / DENOMINATOR;
    }

    function setFeeNumerator(uint256 _feeNumerator) external onlyOwner {
        feeNumerator = _feeNumerator;
        emit FeeSet(_feeNumerator, block.timestamp);
    }

    function setExecutorFeeNumerator(uint256 _executorFeeNumerator)
        external
        onlyOwner
    {
        executorFeeNumerator = _executorFeeNumerator;
        emit ExecutorFeeSet(_executorFeeNumerator, block.timestamp);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != address(0), "Invalid fee to address");
        feeTo = _feeTo;
        emit FeeToSet(feeTo, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OrderBook.sol";
import "./FeeManager.sol";

contract MateCore is OrderBook, FeeManager, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable mate;

    constructor(
        address _router,
        address _mate,
        address _feeTo
    ) {
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(router.factory());
        mate = _mate;
        feeTo = _feeTo;
    }

    event OrderExecuted(
        bytes32 indexed orderId,
        address indexed executor,
        uint256 amountOut,
        uint256 timestamp
    );

    function canExecuteOrder(bytes32 _orderId, address[] memory _pathToTokenOut)
        external
        view
        returns (bool success, string memory reason)
    {
        return _canExecuteOrder(_orderId, _pathToTokenOut, new address[](0));
    }

    function canExecuteOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) external view returns (bool success, string memory reason) {
        return _canExecuteOrder(_orderId, _pathToTokenOut, _pathToMate);
    }

    function _canExecuteOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) internal view returns (bool success, string memory reason) {
        Order storage order = orders[_orderId];

        uint256 balance = IERC20(order.tokenIn).balanceOf(order.creator);
        if (balance < order.amountIn) return (false, "Insufficient balance");

        uint256 lockedBalance = _lockedBalance[order.creator][order.tokenIn];
        uint256 availableBalance = balance > lockedBalance
            ? balance - lockedBalance
            : 0;
        if (availableBalance < order.amountIn)
            return (false, "Unavailable balance");

        uint256 allowance = IERC20(order.tokenIn).allowance(
            order.creator,
            address(this)
        );
        if (allowance < order.amountIn)
            return (false, "Insufficient allowance");

        if (block.timestamp > order.expiration) return (false, "Expired order");

        if (order.status != Status.Open) return (false, "Invalid status");

        if (
            _pathToTokenOut.length < 1 ||
            _pathToTokenOut[0] != order.tokenIn ||
            _pathToTokenOut[_pathToTokenOut.length - 1] != order.tokenOut
        ) return (false, "Invalid path to output token");

        if (order.tokenIn != mate && _pathToMate.length > 1) {
            if (
                _pathToMate[0] != order.tokenIn ||
                _pathToMate[_pathToMate.length - 1] != mate
            ) return (false, "Invalid path to Mate token");
        }

        (uint256 fee, uint256 executorFee) = calculateFees(order.amountIn);

        uint256 amountInWithFees = order.amountIn - fee - executorFee;

        uint256 amountOutMin = getAmountOutMin(
            amountInWithFees,
            _pathToTokenOut
        );

        if (amountOutMin < order.amountOutMin)
            return (false, "Insufficient output amount");

        return (true, "");
    }

    function executeOrder(bytes32 _orderId, address[] memory _pathToTokenOut)
        external
    {
        _executeOrder(_orderId, _pathToTokenOut, new address[](0));
    }

    function executeOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) external {
        _executeOrder(_orderId, _pathToTokenOut, _pathToMate);
    }

    function _executeOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) internal nonReentrant {
        Order storage order = orders[_orderId];

        uint256 balance = IERC20(order.tokenIn).balanceOf(order.creator);
        require(balance >= order.amountIn, "Insufficient balance");

        uint256 lockedBalance = _lockedBalance[order.creator][order.tokenIn];
        uint256 availableBalance = balance > lockedBalance
            ? balance - lockedBalance
            : 0;
        require(availableBalance >= order.amountIn, "Unavailable balance");

        uint256 allowance = IERC20(order.tokenIn).allowance(
            order.creator,
            address(this)
        );
        require(allowance >= order.amountIn, "Insufficient allowance");

        require(block.timestamp <= order.expiration, "Expired order");

        require(order.status == Status.Open, "Invalid status");

        require(
            _pathToTokenOut.length > 1 &&
                _pathToTokenOut[0] == order.tokenIn &&
                _pathToTokenOut[_pathToTokenOut.length - 1] == order.tokenOut,
            "Invalid path to output token"
        );

        if (order.tokenIn != mate && _pathToMate.length > 1) {
            require(
                _pathToMate[0] == order.tokenIn &&
                    _pathToMate[_pathToMate.length - 1] == mate,
                "Invalid path to Mate token"
            );
        }

        (uint256 fee, uint256 executorFee) = calculateFees(order.amountIn);

        uint256 amountInWithFees = order.amountIn - fee - executorFee;

        uint256 amountOutMin = getAmountOutMin(
            amountInWithFees,
            _pathToTokenOut
        );

        require(
            amountOutMin >= order.amountOutMin,
            "Insufficient output amount"
        );

        order.status = Status.Filled;

        _lockedBalance[order.creator][order.tokenIn] -= order.amountIn;

        IERC20(order.tokenIn).safeTransferFrom(
            order.creator,
            address(this),
            order.amountIn
        );

        uint256 amountOut = _swap(
            _pathToTokenOut,
            amountInWithFees,
            order.amountOutMin,
            order.recipient
        );

        _removeOpenOrder(order.id);

        _transferFees(fee, executorFee, order.tokenIn, _pathToMate);

        emit OrderExecuted(_orderId, msg.sender, amountOut, block.timestamp);
    }

    function _transferFees(
        uint256 _fee,
        uint256 _executorFee,
        address _tokenIn,
        address[] memory _pathToMate
    ) internal {
        if (_fee > 0) {
            IERC20(_tokenIn).safeTransfer(feeTo, _fee);
        }

        if (_executorFee > 0) {
            if (_tokenIn == mate || _pathToMate.length <= 1) {
                IERC20(_tokenIn).safeTransfer(msg.sender, _executorFee);
            } else {
                _swap(
                    _pathToMate,
                    _executorFee,
                    getAmountOutMin(_executorFee, _pathToMate),
                    msg.sender
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./UniswapHandler.sol";

contract OrderBook is UniswapHandler {
    enum Status {
        Expired,
        Open,
        Filled,
        Canceled
    }

    struct Order {
        bytes32 id;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address recipient;
        address creator;
        uint256 createdAt;
        uint256 expiration;
        Status status;
    }

    mapping(bytes32 => Order) public orders;
    mapping(address => uint256) private _nonces;

    // User addr => Token addr => Locked balance (in orders)
    mapping(address => mapping(address => uint256)) internal _lockedBalance;

    bytes32[] public openOrders;

    event OrderPlaced(
        bytes32 indexed orderId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address indexed recipient,
        address indexed creator,
        uint256 expiration,
        uint256 timestamp
    );

    event OrderCanceled(bytes32 indexed orderId, uint256 timestamp);

    function placeOrder(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient,
        uint256 _expiration
    ) external {
        require(_tokenIn != address(0), "Invalid input token address");
        require(_tokenOut != address(0), "Invalid output token address");
        require(_amountIn > 0, "Invalid input amount");
        require(_amountOutMin > 0, "Invalid output amount");
        require(_recipient != address(0), "Invalid recipient address");
        require(_expiration > block.timestamp, "Invalid expiration timestamp");

        uint256 balance = IERC20(_tokenIn).balanceOf(msg.sender);
        require(balance >= _amountIn, "Insufficient balance");

        uint256 lockedBalance = _lockedBalance[msg.sender][_tokenIn];
        uint256 availableBalance = balance > lockedBalance
            ? balance - lockedBalance
            : 0;
        require(availableBalance >= _amountIn, "Unavailable balance");

        uint256 allowance = IERC20(_tokenIn).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= _amountIn, "Insufficient allowance");

        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, _nonces[msg.sender]++)
        );

        Order storage order = orders[id];
        order.id = id;
        order.tokenIn = _tokenIn;
        order.tokenOut = _tokenOut;
        order.amountIn = _amountIn;
        order.amountOutMin = _amountOutMin;
        order.recipient = _recipient;
        order.creator = msg.sender;
        order.createdAt = block.timestamp;
        order.expiration = _expiration;

        _lockedBalance[order.creator][order.tokenIn] += order.amountIn;

        _addOpenOrder(order);

        emit OrderPlaced(
            id,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _amountOutMin,
            _recipient,
            msg.sender,
            _expiration,
            block.timestamp
        );
    }

    function cancelOrder(bytes32 _orderId) external {
        Order storage order = orders[_orderId];
        require(msg.sender == order.creator, "Only order creator");
        require(order.status == Status.Open, "Cannot cancel unopen order");
        require(order.createdAt > 0, "Invalid order");
        order.status = Status.Canceled;
        _lockedBalance[order.creator][order.tokenIn] -= order.amountIn;

        _removeOpenOrder(order.id);
        emit OrderCanceled(_orderId, block.timestamp);
    }

    function _removeOpenOrder(bytes32 _orderId) internal {
        uint256 length = openOrders.length;
        for (uint256 i = 0; i < length; i++) {
            if (openOrders[i] == _orderId) {
                openOrders[i] = openOrders[length - 1];
                openOrders.pop();
                break;
            }
        }
    }

    function _addOpenOrder(Order storage _order) private {
        _order.status = Status.Open;
        openOrders.push(_order.id);
    }

    function getAvailableBalance(address _account, address _token)
        external
        view
        returns (uint256)
    {
        uint256 balance = IERC20(_token).balanceOf(_account);
        uint256 lockedBalance = _lockedBalance[_account][_token];
        return balance > lockedBalance ? balance - lockedBalance : 0;
    }

    function getLockedBalance(address _account, address _token)
        external
        view
        returns (uint256)
    {
        return _lockedBalance[_account][_token];
    }

    function getNonce(address _account) external view returns (uint256) {
        return _nonces[_account];
    }

    function getStatus(bytes32 _orderId) external view returns (Status) {
        Order storage order = orders[_orderId];

        if (order.status == Status.Open) {
            if (block.timestamp >= order.expiration) return Status.Expired;
        }

        return order.status;
    }

    function isExpiredOrder(bytes32 _orderId) external view returns (bool) {
        Order storage order = orders[_orderId];
        return block.timestamp >= order.expiration;
    }

    function getOrder(bytes32 _orderId)
        public
        view
        returns (
            bytes32 id,
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 amountOutMin,
            address recipient,
            address creator,
            uint256 createdAt,
            uint256 expiration,
            uint8 status
        )
    {
        Order storage order = orders[_orderId];
        id = order.id;
        tokenIn = order.tokenIn;
        tokenOut = order.tokenOut;
        amountIn = order.amountIn;
        amountOutMin = order.amountOutMin;
        recipient = order.recipient;
        createdAt = order.createdAt;
        creator = order.creator;
        expiration = order.expiration;
        status = uint8(order.status);
    }

    function getOpenOrders() external view returns (bytes32[] memory) {
        return openOrders;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapHandler {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;

    /**
     * @dev Function to swap tokens
     * @param _path An array of addresses from tokenIn to tokenOut
     * @param _amountIn Amount of input tokens
     * @param _amountOutMin Mininum amount of output tokens
     * @param _recipient Address to send output tokens to
     * @return Amount of output tokens received
     */
    function _swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient
    ) internal returns (uint256) {
        IERC20(_path[0]).safeIncreaseAllowance(address(router), _amountIn);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _recipient,
            block.timestamp + 120
        );

        return amounts[_path.length - 1];
    }

    function getReserves(address _tokenIn, address _tokenOut)
        external
        view
        returns (uint256 reserveIn, uint256 reserveOut)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(
            factory.getPair(_tokenIn, _tokenOut)
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        return
            _tokenIn < _tokenOut ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @dev Function to get the minumum amount from a swap
     * @param _amountIn Amount of input token
     * @param _path An array of addresses from tokenIn to tokenOut
     * @return Minumim amount out
     */
    function getAmountOutMin(uint256 _amountIn, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256[] memory amountOutMins = router.getAmountsOut(_amountIn, _path);
        return amountOutMins[_path.length - 1];
    }

    function getAmountsOut(uint256 _amountIn, address[] memory _path)
        external
        view
        returns (uint256[] memory)
    {
        return router.getAmountsOut(_amountIn, _path);
    }
}

