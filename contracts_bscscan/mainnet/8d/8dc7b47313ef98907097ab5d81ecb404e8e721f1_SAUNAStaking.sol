/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-15
 */

// SPDX-License-Identifier: MIT

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

pragma solidity 0.8.3;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract SAUNAStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    // The address of the smart chef factory
    address public SMART_CHEF_FACTORY;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when Pool mining ends.
    uint256 public bonusEndBlock;

    // The block number when Pool mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // Last claimed block
    uint256 public lastClaimedBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // CAKE tokens created per block.
    uint256 public rewardPerBlock;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Harvest interval in seconds
    uint256 public harvestInterval = 0;

    // Harvest timelock on/off
    bool public harvestLockOn = false;

    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Withdraw timelock method
    // 0 - disable withdraw timelock
    // 1 - enable withdraw timelock, no one can withdraw
    // 2 - enable withdraw timelock, but can withdraw with paying fee
    uint8 public withdrawLockMethod = 0;

    // Withdraw interval in seconds
    uint256 public withdrawInterval = 0;

    // Withdraw fee allocation method
    // 0 - withdraw fee off
    // 1 - 100% to marketing address
    // 2 - 100% burn
    // 3 - 50% to marketing address, 50% burn
    // 4 - add to BNB-SAUNA liquidity
    uint8 public withdrawFeeMethod = 0;

    // Withdraw fee (default 1%)
    uint16 public withdrawFee = 100;

    // Max withdraw fee 20%
    uint16 public constant MAX_WITHDRAW_FEE = 2000;

    // Marketing address
    address public marketingAddress;

    // Burn address
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    // Deposit whitelist on/off
    bool public depositWhitelistOn = false;

    // Deposit whitelist
    mapping(address => bool) public depositWhitelist;

    // The reward token
    IBEP20 public rewardToken;

    // The staked token
    IBEP20 public stakedToken;

    // The pair token : withdraw fee will be added to stakedToken-pairToken lp
    IBEP20 public pairToken;

    // The pair token is bnb or not
    bool public isBnbPairToken;

    // Withdraw fee liquidity pair
    address public feeLiquidityPair;

    // The swap router, modifiable.
    IUniswapV2Router02 public saunaSwapRouter;

    // Total shares (only used in auto-compound mode)
    uint256 public totalShares;

    // Total staking tokens
    uint256 public totalStakings;

    // Total reward tokens
    uint256 public totalRewards;

    // max Staking Tokens
    uint256 public maxStakings;

    // Freeze start block
    uint256 public freezeStartBlock;

    // Freeze end block
    uint256 public freezeEndBlock;

    // Minimum deposit amount
    uint256 public minDepositAmount;

    // Auto-compounding on / off
    bool public autoCompoundOn = false;

    uint256 public constant MAX_COMPOUND_PERFORMANCE_FEE = 500; // 5%
    uint256 public constant MAX_COMPOUND_CALL_FEE = 100; // 1%
    uint256 public constant MAX_COMPOUND_WITHDRAW_FEE = 100; // 1%
    uint256 public constant MAX_COMPOUND_WITHDRAW_FEE_PERIOD = 72 hours; // 3 days

    uint256 public compoundPerformanceFee = 200; // 2%
    uint256 public compoundCallFee = 25; // 0.25%
    uint256 public compoundWithdrawFee = 10; // 0.1%
    uint256 public compoundWithdrawFeePeriod = 72 hours; // 3 days

    address[] public userList;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        bool registered; // it will add user in address list on first deposit
        address addr; //address of user
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 nextWithdrawUntil; // When can the user withdraw again.
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewFreezeBlocks(uint256 freezeStartBlock, uint256 freezeEndBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event RewardLockedUp(address indexed user, uint256 amountLockedUp);
    event Withdraw(address indexed user, uint256 amount);
    event AddRewardTokens(address indexed user, uint256 amount);
    event SaunaSwapRouterUpdated(
        address indexed operator,
        address indexed router,
        address indexed pair
    );
    event PairTokenUpdated(
        address indexed operator,
        address indexed router,
        address indexed pair
    );
    event UpdateCompoundPerformancefee(
        address indexed sender,
        uint256 oldFee,
        uint256 newFee
    );
    event UpdateCompoundCallfee(
        address indexed sender,
        uint256 oldFee,
        uint256 newFee
    );
    event UpdateCompoundWithdrawfee(
        address indexed sender,
        uint256 oldFee,
        uint256 newFee
    );
    event UpdateCompoundWithdrawFeePeriod(
        address indexed sender,
        uint256 oldPeriod,
        uint256 newPeriod
    );

    constructor() {
        SMART_CHEF_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _maxStakings: max Staking Tokens
     * @param _autoCompoundOn: On/Off auto-compounding feature
     * @param _admin: admin address with ownership
     */
    function initialize(
        IBEP20 _stakedToken,
        IBEP20 _rewardToken,
        bool _isBnbPairToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        uint256 _minDepositAmount,
        uint256 _maxStakings,
        bool _autoCompoundOn,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == SMART_CHEF_FACTORY, "Not factory");
        require(
            _autoCompoundOn == false ||
                address(_stakedToken) == address(_rewardToken),
            "Staking token must be same as reward token when auto compounding feature is on"
        );

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        isBnbPairToken = _isBnbPairToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        minDepositAmount = _minDepositAmount;
        maxStakings = _maxStakings;
        autoCompoundOn = _autoCompoundOn;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock and lastClaimedBlock as the startBlock
        lastRewardBlock = startBlock;
        lastClaimedBlock = startBlock;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(
            _amount > 0 || autoCompoundOn == false,
            "Harvest disabled in auto-compounding mode"
        );
        require(
            depositWhitelistOn == false || depositWhitelist[msg.sender] == true,
            "Address not in whitelist"
        );
        require(
            maxStakings == 0 || totalStakings.add(_amount) <= maxStakings,
            "no more stake in this pool"
        );
        require(isFrozen() == false, "deposit is frozen");

        UserInfo storage user = userInfo[msg.sender];
        require(
            _amount.add(user.amount) >= minDepositAmount,
            "User amount below minimum"
        );

        if (hasUserLimit) {
            require(
                _amount.add(user.amount) <= poolLimitPerUser,
                "User amount above limit"
            );
        }

        _updatePool();

        if (user.amount > 0) {
            payOrLockupPendingReward();
        } else {
            if (user.registered == false) {
                userList.push(msg.sender);
                user.registered = true;
                user.addr = address(msg.sender);
            }
        }

        if (_amount > 0) {
            // Every time when there is a new deposit, reset withdraw interval
            user.nextWithdrawUntil = block.timestamp.add(withdrawInterval);

            stakedToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );

            uint256 currentShares = 0;
            if (totalShares != 0) {
                currentShares = (_amount.mul(totalShares)).div(totalStakings);
            } else {
                currentShares = _amount;
            }

            user.amount = user.amount.add(currentShares);
            user.lastDepositedTime = block.timestamp;

            totalShares = totalShares.add(currentShares);
            totalStakings = totalStakings.add(_amount);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice View function to see if user can harvest.
     */
    function canHarvest(address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return
            harvestLockOn == false || block.timestamp >= user.nextHarvestUntil;
    }

    /**
     * @notice View function to see if user can withdraw.
     */
    function canWithdraw(address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return
            withdrawLockMethod == 0 ||
            withdrawLockMethod == 2 ||
            block.timestamp >= user.nextWithdrawUntil;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = totalStakings;

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(rewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(
            cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
        );
        lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    /**
     * @notice Claim and compound tokens
     */
    function claim() external nonReentrant {
        require(autoCompoundOn, "Only available in auto-compound mode");
        require(
            lastClaimedBlock < block.number,
            "Current block number should be after lastClaimedBlock"
        );

        uint256 multiplier = _getMultiplier(lastClaimedBlock, block.number);
        uint256 claimedAmount = multiplier.mul(rewardPerBlock);

        if (compoundPerformanceFee > 0) {
            uint256 currentPerformanceFee = claimedAmount
                .mul(compoundPerformanceFee)
                .div(10000); // performance fee
            stakedToken.safeTransfer(marketingAddress, currentPerformanceFee);
            claimedAmount = claimedAmount.sub(currentPerformanceFee);
        }

        if (compoundCallFee > 0) {
            uint256 currentCallFee = claimedAmount.mul(compoundCallFee).div(
                10000
            ); // call fee
            stakedToken.safeTransfer(msg.sender, currentCallFee);
            claimedAmount = claimedAmount.sub(currentCallFee);
        }

        totalStakings = totalStakings.add(claimedAmount);
        lastClaimedBlock = block.number;
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(isFrozen() == false, "withdraw is frozen");
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();
        payOrLockupPendingReward();

        if (_amount > 0) {
            if (canWithdraw(msg.sender)) {
                uint256 currentAmount = (totalStakings.mul(_amount)).div(
                    totalShares
                );
                user.amount = user.amount.sub(_amount);
                totalShares = totalShares.sub(_amount);

                require(
                    totalStakings >= currentAmount,
                    "Exceed total staking amount"
                );

                totalStakings = totalStakings.sub(currentAmount);

                // Check withdraw fee period
                if (
                    autoCompoundOn &&
                    block.timestamp <
                    user.lastDepositedTime.add(compoundWithdrawFeePeriod)
                ) {
                    uint256 currentWithdrawFee = currentAmount
                        .mul(compoundWithdrawFee)
                        .div(10000);

                    if (currentWithdrawFee > 0) {
                        stakedToken.safeTransfer(
                            marketingAddress,
                            currentWithdrawFee
                        );
                        currentAmount = currentAmount.sub(currentWithdrawFee);
                    }
                }

                uint256 feeAmount = 0;
                // Withdraw locked, but should pay fee when withdraw before locked time
                if (
                    withdrawLockMethod == 2 &&
                    withdrawFeeMethod != 0 &&
                    withdrawFee > 0 &&
                    block.timestamp < user.nextWithdrawUntil
                ) {
                    feeAmount = currentAmount.mul(withdrawFee).div(10000);
                    if (feeAmount > 0) {
                        if (withdrawFeeMethod == 1) {
                            // 100% to marketing addresss
                            stakedToken.safeTransfer(
                                marketingAddress,
                                feeAmount
                            );
                        } else if (withdrawFeeMethod == 2) {
                            // 100% burn
                            stakedToken.safeTransfer(BURN_ADDRESS, feeAmount);
                        } else if (withdrawFeeMethod == 3) {
                            // 50% marketing address 50% burn
                            stakedToken.safeTransfer(
                                BURN_ADDRESS,
                                feeAmount.div(2)
                            );
                            stakedToken.safeTransfer(
                                marketingAddress,
                                feeAmount.sub(feeAmount.div(2))
                            );
                        } else if (withdrawFeeMethod == 4) {
                            // add to liquidity
                            require(
                                address(saunaSwapRouter) != address(0),
                                "Invalid Sauna Swap Router"
                            );
                            require(
                                address(feeLiquidityPair) != address(0),
                                "Invalid fee liquidity Pair"
                            );

                            uint256 half = feeAmount.div(2);
                            uint256 otherHalf = feeAmount.sub(half);

                            if (half > 0 && otherHalf > 0) {
                                if (isBnbPairToken) {
                                    uint256 initialETHBalance = address(this)
                                        .balance;

                                    // swap staked token to pair token
                                    swapStakedTokenToETH(half);
                                    uint256 newETHBalance = address(this)
                                        .balance
                                        .sub(initialETHBalance);

                                    // add liquidity
                                    addLiquidityETH(newETHBalance, otherHalf);
                                } else {
                                    uint256 initialPairBalance = pairToken
                                        .balanceOf(address(this));

                                    // swap staked token to pair token
                                    swapStakedTokenToPairToken(half);
                                    uint256 newPairBalance = pairToken
                                        .balanceOf(address(this))
                                        .sub(initialPairBalance);

                                    // add liquidity
                                    addLiquidity(newPairBalance, otherHalf);
                                }
                            }
                        }
                    }
                }
                currentAmount = currentAmount.sub(feeAmount);

                if (currentAmount > 0) {
                    stakedToken.safeTransfer(
                        address(msg.sender),
                        currentAmount
                    );
                }

                user.nextWithdrawUntil = block.timestamp.add(withdrawInterval);
            }
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        require(isFrozen() == false, "emergency withdraw is frozen");

        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
            totalStakings = totalStakings.sub(amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /**
     * @notice Pay or lockup pending rewards.
     */
    function payOrLockupPendingReward() internal {
        UserInfo storage user = userInfo[msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(harvestInterval);
        }

        uint256 pending = user
            .amount
            .mul(accTokenPerShare)
            .div(PRECISION_FACTOR)
            .sub(user.rewardDebt);

        if (autoCompoundOn) {
            return;
        } else if (canHarvest(msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 userTotalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(harvestInterval);

                // send rewards
                _safeRewardTransfer(address(msg.sender), userTotalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, pending);
        }
    }

    /// @dev Swap staked token to pair token
    function swapStakedTokenToPairToken(uint256 stakedTokenAmount) private {
        // generate the saunaSwap pair path of staked token -> pair token
        address[] memory path = new address[](2);
        path[0] = address(stakedToken);
        path[1] = address(pairToken);

        stakedToken.approve(address(saunaSwapRouter), stakedTokenAmount);

        // make the swap
        saunaSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            stakedTokenAmount,
            0, // accept any amount of pair token
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 stakedTokenAmount, uint256 pairTokenAmount)
        private
    {
        // approve token transfer to cover all possible scenarios
        stakedToken.approve(address(saunaSwapRouter), stakedTokenAmount);
        pairToken.approve(address(saunaSwapRouter), pairTokenAmount);

        // add the liquidity
        saunaSwapRouter.addLiquidity(
            address(stakedToken),
            address(pairToken),
            stakedTokenAmount,
            pairTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    /// @dev Swap staked token to ETH
    function swapStakedTokenToETH(uint256 stakedTokenAmount) private {
        // generate the saunaSwap pair path of staked token -> ETH
        address[] memory path = new address[](2);
        path[0] = address(stakedToken);
        path[1] = saunaSwapRouter.WETH();

        stakedToken.approve(address(saunaSwapRouter), stakedTokenAmount);

        // make the swap
        saunaSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            stakedTokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidityETH(uint256 stakedTokenAmount, uint256 ethAmount)
        private
    {
        // approve token transfer to cover all possible scenarios
        stakedToken.approve(address(saunaSwapRouter), stakedTokenAmount);

        // add the liquidity
        saunaSwapRouter.addLiquidityETH{value: ethAmount}(
            address(stakedToken),
            stakedTokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    /**
     * @dev Update the pair token.
     * Can only be called by the owner.
     */
    function updatePairToken(IBEP20 _pairToken) public onlyOwner {
        require(
            isBnbPairToken == false,
            "Unable to update pair token, set as bnb"
        );
        pairToken = _pairToken;
        if (address(saunaSwapRouter) != address(0)) {
            feeLiquidityPair = IUniswapV2Factory(saunaSwapRouter.factory())
                .getPair(address(stakedToken), address(pairToken));
            require(
                feeLiquidityPair != address(0),
                "stakedToken-pairToken:: invalid pair"
            );
            emit PairTokenUpdated(
                msg.sender,
                address(saunaSwapRouter),
                feeLiquidityPair
            );
        }
    }

    // To receive BNB from saunaSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev Update the swap router.
     * Can only be called by the owner.
     */
    function updateSaunaSwapRouter(address _router) public onlyOwner {
        saunaSwapRouter = IUniswapV2Router02(_router);
        if (isBnbPairToken) {
            feeLiquidityPair = IUniswapV2Factory(saunaSwapRouter.factory())
                .getPair(address(stakedToken), saunaSwapRouter.WETH());
        } else {
            feeLiquidityPair = IUniswapV2Factory(saunaSwapRouter.factory())
                .getPair(address(stakedToken), address(pairToken));
        }
        require(
            feeLiquidityPair != address(0),
            "stakedToken-pairToken:: invalid pair"
        );
        emit SaunaSwapRouterUpdated(
            msg.sender,
            address(saunaSwapRouter),
            feeLiquidityPair
        );
    }

    /*
     * @notice return length of user addresses
     */
    function getUserListLength() external view returns (uint256) {
        return userList.length;
    }

    /*
     * @notice View function to get users.
     * @param _offset: offset for paging
     * @param _limit: limit for paging
     * @return get users, next offset and total users
     */
    function getUsersPaging(uint256 _offset, uint256 _limit)
        public
        view
        returns (
            UserInfo[] memory users,
            uint256 nextOffset,
            uint256 total
        )
    {
        uint256 totalUsers = userList.length;
        if (_limit == 0) {
            _limit = 1;
        }

        if (_limit > totalUsers - _offset) {
            _limit = totalUsers - _offset;
        }

        UserInfo[] memory values = new UserInfo[](_limit);
        for (uint256 i = 0; i < _limit; i++) {
            values[i] = userInfo[userList[_offset + i]];
        }

        return (values, _offset + _limit, totalUsers);
    }

    /*
     * @notice isFrozed returns if contract is frozen, user cannot call deposit, withdraw, emergencyWithdraw function
     */
    function isFrozen() public view returns (bool) {
        return
            block.number >= freezeStartBlock && block.number <= freezeEndBlock;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        totalRewards = totalRewards.sub(_amount);
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    /**
     * @notice It allows the admin to reward tokens
     * @param _amount: amount of tokens
     * @dev This function is only callable by admin.
     */
    function addRewardTokens(uint256 _amount) external onlyOwner {
        totalRewards = totalRewards.add(_amount);
        rewardToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit AddRewardTokens(msg.sender, _amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(stakedToken),
            "Cannot be staked token"
        );
        require(
            _tokenAddress != address(rewardToken),
            "Cannot be reward token"
        );

        IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Calculates the expected claim reward from third party
     * @return Expected reward to collect in staking token
     */
    function calculateClaimRewards() external view returns (uint256) {
        uint256 multiplier = _getMultiplier(lastClaimedBlock, block.number);
        uint256 claimedAmount = multiplier.mul(rewardPerBlock);
        uint256 currentCallFee = claimedAmount.mul(compoundCallFee).div(10000);

        return currentCallFee;
    }

    /**
     * @notice Calculates the total pending rewards that can be restaked
     * @return Returns total pending cake rewards
     */
    function calculateTotalPendingCakeRewards()
        external
        view
        returns (uint256)
    {
        uint256 multiplier = _getMultiplier(lastClaimedBlock, block.number);
        uint256 claimedAmount = multiplier.mul(rewardPerBlock);

        return claimedAmount;
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return
            totalShares == 0 ? 1e18 : totalStakings.mul(1e18).div(totalShares);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Stop Freeze
     * @dev Only callable by owner
     */
    function stopFreeze() external onlyOwner {
        freezeStartBlock = 0;
        freezeEndBlock = 0;
    }

    /*
     * @notice Enable/disable deposit whitelist
     * @dev Only callable by owner
     */
    function enableDepositWhitelist(bool _on) external onlyOwner {
        depositWhitelistOn = _on;
    }

    /*
     * @notice Add/remove address from whitelist
     * @dev Only callable by owner
     */
    function updateDepositWhitelist(address _address, bool _on)
        external
        onlyOwner
    {
        depositWhitelist[_address] = _on;
    }

    /*
     * @notice Enable/disable harvest timelock
     * @dev Only callable by owner
     */
    function enableHarvestLock(bool _on) external onlyOwner {
        require(harvestLockOn != _on, "Already set");
        require(
            autoCompoundOn == false || _on == false,
            "Harvest lock must be disabled when auto-compounding feature is on"
        );
        harvestLockOn = _on;
    }

    /*
     * @notice Update harvest interval
     * @dev Only callable by owner
     */
    function updateHarvestInterval(uint256 _harvestInterval)
        external
        onlyOwner
    {
        harvestInterval = _harvestInterval;
    }

    /*
     * @notice Update withdraw timelock method
     * @dev Only callable by owner
     */
    function updateWithdrawLockMethod(uint8 _method) external onlyOwner {
        require(
            _method == 0 || _method == 1 || _method == 2,
            "Invalid withdraw lock method set"
        );
        require(_method != withdrawLockMethod, "Already set");
        withdrawLockMethod = _method;
    }

    /*
     * @notice Update withdraw interval
     * @dev Only callable by owner
     */
    function updateWithdrawInterval(uint256 _withdrawInterval)
        external
        onlyOwner
    {
        withdrawInterval = _withdrawInterval;
    }

    /*
     * @notice Update withdraw fee method
     * @dev Only callable by owner
     */
    function updateWithdrawFeeMethod(uint8 _method) external onlyOwner {
        require(
            _method == 0 ||
                _method == 1 ||
                _method == 2 ||
                _method == 3 ||
                _method == 4,
            "Invalid withdraw fee method set"
        );
        require(_method != withdrawFeeMethod, "Already set");
        withdrawFeeMethod = _method;
    }

    /**
     * @notice Update withdraw fee method
     * @dev Only callable by owner
     */
    function updateWithdrawFee(uint16 _withdrawFee) external onlyOwner {
        require(_withdrawFee <= MAX_WITHDRAW_FEE, "Out of withdraw fee range");
        withdrawFee = _withdrawFee;
    }

    /*
     * @notice Update marketing address
     * @dev Only callable by owner
     */
    function updateMarketingAddress(address _marketingAddress)
        external
        onlyOwner
    {
        marketingAddress = _marketingAddress;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(
        bool _hasUserLimit,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(
            block.number < startBlock || block.number > bonusEndBlock,
            "Pool has started"
        );
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external onlyOwner {
        require(
            block.number < startBlock || block.number > bonusEndBlock,
            "Pool has started"
        );
        require(
            _startBlock < _bonusEndBlock,
            "New startBlock must be lower than new end block"
        );
        require(
            block.number < _startBlock,
            "New startBlock must be higher than current block"
        );

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /**
     * @notice It allows the admin to update freeze start and end blocks
     * @dev This function is only callable by owner.
     * @param _freezeStartBlock: the new freeze start block
     * @param _freezeEndBlock: the new freeze end block
     */
    function updateFreezaBlocks(
        uint256 _freezeStartBlock,
        uint256 _freezeEndBlock
    ) external onlyOwner {
        require(
            _freezeStartBlock < _freezeEndBlock,
            "New freeze startBlock must be lower than new endBlock"
        );
        require(
            block.number < _freezeStartBlock,
            "freeze start block must be higher than current block"
        );

        freezeStartBlock = _freezeStartBlock;
        freezeEndBlock = _freezeEndBlock;
        emit NewFreezeBlocks(freezeStartBlock, freezeEndBlock);
    }

    /**
     * @notice Update minimum deposit amount
     * @dev This function is only callable by owner.
     * @param _minDepositAmount: the new minimum deposit amount
     */
    function updateMinDepositAmount(uint256 _minDepositAmount)
        external
        onlyOwner
    {
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @notice Update compound performance fee
     * @dev Only callable by the owner.
     */
    function updateCompoundPerformanceFee(uint256 _compoundPerformanceFee)
        external
        onlyOwner
    {
        require(
            _compoundPerformanceFee <= MAX_COMPOUND_PERFORMANCE_FEE,
            "compoundPerformanceFee cannot be more than MAX_COMPOUND_PERFORMANCE_FEE"
        );
        uint256 oldFee = compoundPerformanceFee;
        compoundPerformanceFee = _compoundPerformanceFee;

        emit UpdateCompoundPerformancefee(
            msg.sender,
            oldFee,
            _compoundPerformanceFee
        );
    }

    /**
     * @notice Update compound call fee
     * @dev Only callable by the owner.
     */
    function updateCompoundCallFee(uint256 _compoundCallFee)
        external
        onlyOwner
    {
        require(
            _compoundCallFee <= MAX_COMPOUND_CALL_FEE,
            "compoundCallFee cannot be more than MAX_COMPOUND_CALL_FEE"
        );
        uint256 oldFee = compoundCallFee;
        compoundCallFee = _compoundCallFee;

        emit UpdateCompoundCallfee(msg.sender, oldFee, _compoundCallFee);
    }

    /**
     * @notice Update compound withdraw fee
     * @dev Only callable by the owner.
     */
    function updateCompoundWithdrawFee(uint256 _compoundWithdrawFee)
        external
        onlyOwner
    {
        require(
            _compoundWithdrawFee <= MAX_COMPOUND_WITHDRAW_FEE,
            "compoundWithdrawFee cannot be more than MAX_COMPOUND_WITHDRAW_FEE"
        );
        uint256 oldFee = compoundWithdrawFee;
        compoundWithdrawFee = _compoundWithdrawFee;

        emit UpdateCompoundWithdrawfee(
            msg.sender,
            oldFee,
            _compoundWithdrawFee
        );
    }

    /**
     * @notice Update withdraw fee period
     * @dev Only callable by the owner.
     */
    function updateCompoundWithdrawFeePeriod(uint256 _compoundWithdrawFeePeriod)
        external
        onlyOwner
    {
        require(
            _compoundWithdrawFeePeriod <= MAX_COMPOUND_WITHDRAW_FEE_PERIOD,
            "compoundWithdrawFeePeriod cannot be more than MAX_COMPOUND_WITHDRAW_FEE_PERIOD"
        );
        uint256 oldPeriod = compoundWithdrawFeePeriod;
        compoundWithdrawFeePeriod = _compoundWithdrawFeePeriod;

        UpdateCompoundWithdrawFeePeriod(
            msg.sender,
            oldPeriod,
            _compoundWithdrawFeePeriod
        );
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = totalStakings;
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare = accTokenPerShare.add(
                cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
            );
            return
                user
                    .amount
                    .mul(adjustedTokenPerShare)
                    .div(PRECISION_FACTOR)
                    .sub(user.rewardDebt);
        } else {
            return
                user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(
                    user.rewardDebt
                );
        }
    }

    /*
     * @notice transfer reward tokens.
     * @param _to: address where tokens will transfer
     * @param _amount: amount of tokens
     */
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBal = totalRewards;
        if (_amount > rewardTokenBal) {
            totalRewards = totalRewards.sub(rewardTokenBal);
            rewardToken.safeTransfer(_to, rewardTokenBal);
        } else {
            totalRewards = totalRewards.sub(_amount);
            rewardToken.safeTransfer(_to, _amount);
        }
    }
}