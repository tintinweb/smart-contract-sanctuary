/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/pancakeswap/IPancakeFactory.sol

pragma solidity 0.8.4;

interface IPancakeFactory {
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

// File: contracts/pancakeswap/IPancakeERC20.sol

pragma solidity 0.8.4;

interface IPancakeERC20 {
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
}

// File: contracts/pancakeswap/IPancakePair.sol

pragma solidity 0.8.4;


interface IPancakePair is IPancakeERC20 {
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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/pancakeswap/IPancakeRouter01.sol

pragma solidity 0.8.4;

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

// File: contracts/pancakeswap/IPancakeRouter02.sol

pragma solidity 0.8.4;


interface IPancakeRouter02 is IPancakeRouter01 {
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

// File: @openzeppelin/contracts/utils/math/SignedSafeMath.sol


pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// File: @openzeppelin/contracts/utils/math/SafeCast.sol


pragma solidity ^0.8.0;

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

// File: contracts/dividends/IDividendPayingToken.sol

pragma solidity 0.8.4;

interface IDividendPayingToken {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function distributeRewardDividends(uint256 amount) external;
  function withdrawDividend() external;

  event DividendsDistributed(address indexed from, uint256 weiAmount);
  event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// File: contracts/dividends/IDividendPayingTokenOptional.sol

pragma solidity 0.8.4;

interface IDividendPayingTokenOptional {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: contracts/pancakeswap/ERC20.sol


pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/dividends/DividendPayingToken.sol

pragma solidity 0.8.4;







contract DividendPayingToken is
  IDividendPayingToken,
  IDividendPayingTokenOptional,
  ERC20
{
  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;

  address public immutable _dividendToken;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(
    string memory _name,
    string memory _symbol,
    address dividendToken_
  ) ERC20(_name, _symbol) {
    _dividendToken = dividendToken_;
  }

  receive() external payable {}

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if(msg.value > 0) {
      magnifiedDividendPerShare += (msg.value * magnitude) / totalSupply();
      totalDividendsDistributed += msg.value;

      emit DividendsDistributed(msg.sender, msg.value);
    }
  }

  function distributeRewardDividends(uint256 amount) external override {
    require(totalSupply() > 0);

    if(amount > 0) {
      magnifiedDividendPerShare += (amount * magnitude) / totalSupply();
      totalDividendsDistributed += amount;

      emit DividendsDistributed(msg.sender, amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns(uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);

    if(_withdrawableDividend > 0) {
      withdrawnDividends[user] += _withdrawableDividend;

      bool success = IERC20(_dividendToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] -= _withdrawableDividend;
        return 0;
      }

      emit DividendWithdrawn(user, _withdrawableDividend);
      return _withdrawableDividend;
    }

    return 0;
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    int256 accumulativeDividends = (magnifiedDividendPerShare * balanceOf(_owner)).toInt256();
    accumulativeDividends += magnifiedDividendCorrections[_owner];

    return accumulativeDividends.toUint256() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    int256 _magCorrection = (magnifiedDividendPerShare * value).toInt256();

    magnifiedDividendCorrections[from] += _magCorrection;
    magnifiedDividendCorrections[to] -= _magCorrection;
  }

  function _distributeDividendTokens(address account, uint256 value) internal {
    require(account != address(0), 'ZERO_ADDRESS');

    _beforeTokenTransfer(address(0), account, value);

    _totalSupply += value;
    _balances[account] += value;
    emit Transfer(address(0), account, value);

    _afterTokenTransfer(address(0), account, value);

    magnifiedDividendCorrections[account] -= (magnifiedDividendPerShare * value).toInt256();
  }

  function _destroyDividendTokens(address account, uint256 value) internal {
    require(account != address(0), 'ZERO_ADDRESS');

    _beforeTokenTransfer(account, address(0), value);

    uint256 accountBalance = _balances[account];

    require(accountBalance >= value, 'Destroy amount exceeds balance');

    unchecked {
      _balances[account] = accountBalance - value;
    }

    _totalSupply -= value;

    emit Transfer(account, address(0), value);

    _afterTokenTransfer(account, address(0), value);

    magnifiedDividendCorrections[account] += (magnifiedDividendPerShare * value).toInt256();
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 rewardAmount = newBalance - currentBalance;
      _distributeDividendTokens(account, rewardAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;
      _destroyDividendTokens(account, burnAmount);
    }
  }
}

// File: contracts/dividends/DividendTracker.sol

pragma solidity 0.8.4;





library IterableMapping {
  // Iterable mapping from address to uint;
  struct Map {
    address[] keys;
    mapping(address => uint) values;
    mapping(address => uint) indexOf;
    mapping(address => bool) inserted;
  }

  function get(
    Map storage map,
    address key
    ) internal
    view
    returns(
      uint
    ) {
    return map.values[key];
  }

  function getIndexOfKey(
    Map storage map,
    address key
    ) internal
    view
    returns(
      int
    ) {
    if(!map.inserted[key]) {
      return -1;
    }

    return int(map.indexOf[key]);
  }

  function getKeyAtIndex(
    Map storage map,
    uint index
    ) internal
    view
    returns(
      address
    ) {
    return map.keys[index];
  }

  function size(
    Map storage map
    ) internal
    view
    returns(
      uint
    ) {
    return map.keys.length;
  }

  function set(
    Map storage map,
    address key,
    uint val
    ) internal
  {
    if(map.inserted[key]) {
      map.values[key] = val;
    } else {
      map.inserted[key] = true;
      map.values[key] = val;
      map.indexOf[key] = map.keys.length;
      map.keys.push(key);
    }
  }

  function remove(
    Map storage map,
    address key
    ) internal
  {
    if(!map.inserted[key]) {
      return;
    }

    delete map.inserted[key];
    delete map.values[key];

    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
  }
}

contract DividendTracker is Ownable, DividendPayingToken {
  using SafeMath for uint256;
  using SignedSafeMath for int256;
  using IterableMapping for IterableMapping.Map;

  IterableMapping.Map private tokenHoldersMap;
  uint256 public lastProcessedIndex;

  mapping(address => bool) public excludedFromDividends;
  mapping(address => uint256) public lastClaimTimes;

  uint256 public claimWait;
  uint256 public immutable minimumTokenBalanceForDividends;

  event ExcludeFromDividends(
    address indexed account
  );

  event ClaimWaitUpdated(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );

  event Claim(
    address indexed account,
    uint256 amount,
    bool indexed automatic
  );

  constructor(
    string memory name_,
    string memory symbol_,
    address dividendTokenAddress_,
    uint256 claimWait_
  ) DividendPayingToken(
    string(abi.encodePacked(name_, ': Dividend Tracker')),
    string(abi.encodePacked(symbol_, '_DIVIDEND_TRACKER')),

    dividendTokenAddress_
  ) {
    claimWait = claimWait_;
    minimumTokenBalanceForDividends = 10_000_000_000 * 10**18; // must hold 10 billion tokens which equates to 0.001% of the total NanoDogeCoin supply
  }

  function _transfer(
    address,
    address,
    uint256
    ) internal
    pure
    override
  {
    require(false, 'DividendTracker: No transfers allowed');
  }

  function withdrawDividend()
    public
    pure
    override
  {
    require(false, 'DividendTracker: withdrawDividend disabled. Use the \'claim\' function on the main contract.');
  }

  function excludeFromDividends(
    address account
    ) external
    onlyOwner
  {
    require(!excludedFromDividends[account]);
    excludedFromDividends[account] = true;

    _setBalance(account, 0);
    tokenHoldersMap.remove(account);

    emit ExcludeFromDividends(account);
  }

  function updateClaimWait(
    uint256 newClaimWait
    ) external
    onlyOwner
  {
    require(newClaimWait >= 3600 && newClaimWait <= 86400, 'DividendTracker: claimWait must be updated to between 1 and 24 hours');
    require(newClaimWait != claimWait, 'DividendTracker: Cannot update claimWait to same value');

    emit ClaimWaitUpdated(newClaimWait, claimWait);

    claimWait = newClaimWait;
  }

  function getLastProcessedIndex()
  external
  view
  returns(
    uint256
  ) {
    return lastProcessedIndex;
  }

  function getNumberOfTokenHolders()
  external
  view
  returns(
    uint256
  ) {
    return tokenHoldersMap.keys.length;
  }

  function getAccount(
    address _account
  ) public
    view
    returns(
      address account,
      int256 index,
      int256 iterationsUntilProcessed,
      uint256 withdrawableDividends,
      uint256 totalDividends,
      uint256 lastClaimTime,
      uint256 nextClaimTime,
      uint256 secondsUntilAutoClaimAvailable
    )
  {
    account = _account;

    index = tokenHoldersMap.getIndexOfKey(account);

    iterationsUntilProcessed = -1;

    if(index >= 0) {
      if(uint256(index) > lastProcessedIndex) {
        iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
      } else {
        uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
          ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
          : 0;

        iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
      }
    }

    withdrawableDividends = withdrawableDividendOf(account);
    totalDividends = accumulativeDividendOf(account);

    lastClaimTime = lastClaimTimes[account];

    nextClaimTime = lastClaimTime > 0
      ? lastClaimTime.add(claimWait)
      : 0;

    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
      ? nextClaimTime.sub(block.timestamp)
      : 0;
  }

  function getAccountAtIndex(
    uint256 index
    ) public
    view
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    if(index >= tokenHoldersMap.size()) {
      return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
    }

    address account = tokenHoldersMap.getKeyAtIndex(index);

    return getAccount(account);
  }

  function canAutoClaim(
    uint256 lastClaimTime
    ) private
    view
    returns(
      bool
    ) {
    if(lastClaimTime > block.timestamp)  {
      return false;
    }

    return block.timestamp.sub(lastClaimTime) >= claimWait;
  }

  function setBalance(
    address payable account,
    uint256 newBalance
    ) external
    onlyOwner
  {
    if(excludedFromDividends[account]) {
      return;
    }

    if(newBalance >= minimumTokenBalanceForDividends) {
      _setBalance(account, newBalance);
      tokenHoldersMap.set(account, newBalance);
    } else {
      _setBalance(account, 0);
      tokenHoldersMap.remove(account);
    }

    processAccount(account, true);
  }

  function process(
    uint256 gas
    ) public
    returns(
      uint256,
      uint256,
      uint256
    ) {
    uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    if(numberOfTokenHolders == 0) {
      return (0, 0, lastProcessedIndex);
    }

    uint256 _lastProcessedIndex = lastProcessedIndex;

    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();

    uint256 iterations = 0;
    uint256 claims = 0;

    while(gasUsed < gas && iterations < numberOfTokenHolders) {
      _lastProcessedIndex += 1;

      if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
        _lastProcessedIndex = 0;
      }

      address account = tokenHoldersMap.keys[_lastProcessedIndex];

      if(canAutoClaim(lastClaimTimes[account])) {
        if(processAccount(payable(account), true)) {
          claims += 1;
        }
      }

      iterations += 1;

      uint256 newGasLeft = gasleft();

      if(gasLeft > newGasLeft) {
        gasUsed += (gasLeft - newGasLeft);
      }

      gasLeft = newGasLeft;
    }

    lastProcessedIndex = _lastProcessedIndex;

    return (iterations, claims, lastProcessedIndex);
  }

  function processAccount(
    address payable account,
    bool automatic
    ) public
    onlyOwner
    returns(
      bool
    ) {
    uint256 amount = _withdrawDividendOfUser(account);

    if(amount > 0) {
      lastClaimTimes[account] = block.timestamp;
      emit Claim(account, amount, automatic);
      return true;
    }

    return false;
  }
}

// File: contracts/INanoDogeCoin.sol

pragma solidity 0.8.4;







interface INanoDogeCoin is IERC20, IERC20Metadata {
  event UpdateDividendTracker(
    address indexed newAddress,
    address indexed oldAddress
  );

  event UpdateUniswapV2Router(
    address indexed newAddress,
    address indexed oldAddress
  );

  event ExcludeFromFees(
    address indexed account,
    bool isExcluded
  );

  event ExcludeMultipleAccountsFromFees(
    address[] accounts,
    bool isExcluded
  );

  event SetAutomatedMarketMakerPair(
    address indexed pair,
    bool indexed value
  );

  event LiquidityWalletUpdated(
    address indexed newLiquidityWallet,
    address indexed oldLiquidityWallet
  );

  event GasForProcessingUpdated(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);

  event SwapAndLiquify(
    uint256 half,
    uint256 newBalance,
    uint256 otherHalf
  );

  event ProcessedDividendTracker(
    uint256 iterations,
    uint256 claims,
    uint256 lastProcessedIndex,
    bool indexed automatic,
    uint256 gas,
    address indexed processor
  );

  event SniperCaught(address sniperAddress);

  event SendDividends(
    uint256 tokensSwapped,
    uint256 amount
  );

  function increaseAllowance(address spender, uint256 addedValue)
    external
    returns(bool);

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns(bool);

  function isSniper(address account) external view returns(bool);

  // There is no way to add to the blacklist except through the initial sniper check.
  // But this can remove from the blacklist if someone human somehow made it onto the list.
  function removeSniper(address account) external;
  function setSniperProtectionEnabled(bool enabled) external;
  function excludeDividends(address exclude) external;

  // Adjusted to allow for smaller than 1%'s, as low as 0.1%
  function setMaxTxPercent(uint256 _maxTxPercent) external;
  function maxTxAmountUI() external view returns(uint256);
  function setSwapAndLiquifyEnabled(bool _enabled) external;
  function excludeFromFee(address account) external;
  function includeInFee(address account) external;

  function setDxSaleAddress(address dxRouter, address presaleRouter) external;
  function setAutomatedMarketMakerPair(address pair, bool value) external;

  function updateClaimWait(uint256 claimWait) external;

  function getClaimWait() external view returns(uint256);

  function getTotalDividendsDistributed() external view returns(uint256);
  function withdrawableDividendOf(address account) external view returns(uint256);
  function dividendRewardTokenBalanceOf(address account) external view returns(uint256);

  function getAccountDividendsInfo(address account)
    external
    view
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  function getAccountDividendsInfoAtIndex(uint256 index)
    external
    view
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  function processDividendTracker(uint256 gas) external;
  function claim() external;
  function getLastProcessedIndex() external view returns(uint256);
  function getNumberOfDividendTokenHolders() external view returns(uint256);

  function isExcludedFromFee(address account) external view returns(bool);
  function withdrawLockedETH(address recipient) external;

  // withdraw any tokens that are not supposed to be insided this contract.
  function withdrawLockedTokens(address recipient, address _token) external;
  function setMarketingWallet(address payable newWallet) external;
  function updateDividendTracker(address newAddress) external;
  function changeFees(uint256 liquidityFee, uint256 marketingFee, uint256 usdtFee)  external;
}

// File: contracts/NanoDogeCoin.sol

pragma solidity 0.8.4;











contract NanoDogeCoin is
  INanoDogeCoin,
  Context,
  Ownable,
  ReentrancyGuard
{
  using Address for address;
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) public automatedMarketMakerPairs;

  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _liquidityHolders;
  mapping(address => bool) private _isSniper;

  uint256 private constant MAX = type(uint256).max;

  uint8 private _decimals = 18;
  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  uint256 public _totalFee;
  uint256 private _previousTotalFee;

  uint256 public _marketingFee;
  uint256 public _liquidityFee;
  uint256 public _dividendRewardsFee;

  uint256 private _withdrawableBalance;

  DividendTracker public dividendTracker;
  address private _dividendRewardToken;
  uint256 public gasForProcessing = 300000;

  IPancakeRouter02 public pancakeswapV2Router;
  address public pancakeswapV2Pair;

  address public burnAddress = 0x000000000000000000000000000000000000dEaD;

  address _marketingWallet;

  bool private swapping;
  bool private setPresaleAddresses = true;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 private _maxTxDivisor = 100;
  uint256 private _maxTxAmount;
  uint256 private _previousMaxTxAmount;

  uint256 private _numTokensSellToAddToLiquidity;

  bool private _sniperProtection = true;
  bool private _hasLiqBeenAdded = false;
  bool private _tradingEnabled = false;

  uint256 private _liqAddBlock = 0;
  uint256 private _snipeBlockAmount = 3;
  uint256 public snipersCaught = 0;

  modifier lockTheSwap {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 supply_,
    uint256 maxTxPercent_,
    uint256 liquidityThresholdPercentage_,

    uint256 liquidityFee_,
    uint256 marketingFee_,
    uint256 dividendRewardsFee_,

    address dividendRewardToken_,
    address marketingWallet_,
    address v2Router_
  ) {
    _name = name_;
    _symbol = symbol_;
    _totalSupply = supply_ * (10**uint256(_decimals));
    _numTokensSellToAddToLiquidity = (_totalSupply * liquidityThresholdPercentage_) / 10000;

    _dividendRewardToken = dividendRewardToken_;
    _marketingWallet = marketingWallet_;
    _setupDividendTracker();

    setMaxTxPercent(maxTxPercent_);
    changeFees(liquidityFee_, marketingFee_, dividendRewardsFee_);

    _setupPancakeswap(v2Router_);
    _setupExclusions();

    _balances[_msgSender()] = _totalSupply;
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  function _setupPancakeswap(address _routerAddress) private {
    pancakeswapV2Router = IPancakeRouter02(_routerAddress);

    // create a pancakeswap pair for this new token
    pancakeswapV2Pair = IPancakeFactory(pancakeswapV2Router.factory())
      .createPair(address(this), pancakeswapV2Router.WETH());

    _setAutomatedMarketMakerPair(pancakeswapV2Pair, true);
  }

  function _setupExclusions() private {
    // exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_marketingWallet] = true;
    _liquidityHolders[owner()] = true;
  }

  function _setupDividendTracker() private {
    dividendTracker = new DividendTracker(
      _name,
      _symbol,
      _dividendRewardToken,
      3600 // 1h claim
    );

    dividendTracker.excludeFromDividends(address(dividendTracker));
    dividendTracker.excludeFromDividends(address(this));
    dividendTracker.excludeFromDividends(owner());
    dividendTracker.excludeFromDividends(address(pancakeswapV2Router));
  }

  function name()
    public
    view
    override
    returns(
      string memory)
    {
      return _name;
  }

  function symbol()
    public
    view
    override
    returns(
      string memory
   ) {
      return _symbol;
  }

  function decimals()
    public
    view
    override
    returns(
      uint8
    ) {
      return _decimals;
  }

  function totalSupply()
    public
    view
    override
    returns(
      uint256
    ) {
      return _totalSupply;
  }

  function balanceOf(
    address account)
    public view override returns(uint256) {
      return _balances[account];
  }

  function allowance(
    address owner,
    address spender)
    public
    view
    override
    returns(
      uint256
    ) {
      return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
    ) public
    override
    returns(
      bool
    ) {
      _approve(_msgSender(), spender, amount);
      return true;
  }

  function transfer(
    address recipient,
    uint256 amount
    ) public
    override
    returns(
      bool
    ) {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
    ) public
    override
    returns(bool)
  {
    _transfer(sender, recipient, amount);

    _approve(
      sender,
      _msgSender(),

      _allowances[sender][_msgSender()]
        .sub(amount, 'ERC20: transfer amount exceeds allowance')
    );

    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
    ) public
    override
    returns(bool)
  {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
    ) public
    override
    returns(bool)
  {
    _approve(
      _msgSender(),
      spender,

      _allowances[_msgSender()][spender]
        .sub(subtractedValue, 'ERC20: decreased allowance below zero')
    );

    return true;
  }

  function isSniper(
    address account
    ) public
    view
    override
    returns(
      bool
  ) {
    return _isSniper[account];
  }

  // There is no way to add to the blacklist except through the initial sniper check.
  // But this can remove from the blacklist if someone human somehow made it onto the list.
  function removeSniper(
    address account
    ) external
    override
    onlyOwner
  {
    require(_isSniper[account], 'Account is not a recorded sniper.');
    _isSniper[account] = false;
  }

  function setSniperProtectionEnabled(
    bool enabled
    ) external
    override
    onlyOwner
  {
    _sniperProtection = enabled;
  }

  function excludeDividends(
    address exclude
    ) external
    override
    onlyOwner
  {
    dividendTracker.excludeFromDividends(address(exclude));
  }

  // adjusted to allow for smaller than 1%'s, as low as 0.1%
  function setMaxTxPercent(
    uint256 maxTxPercent_
    ) public
    override
    onlyOwner
  {
    require(maxTxPercent_ >= 1); // cannot set to 0.

    // division by 1000, set to 20 for 2%, set to 2 for 0.2%
    _maxTxAmount = (_totalSupply * maxTxPercent_) / 1000;
  }

  function maxTxAmountUI()
  external
  view
  override
  returns(
    uint256
  ) {
    return _maxTxAmount / uint256(_decimals);
  }

  function setSwapAndLiquifyEnabled(
    bool _enabled
    ) external
    override
    onlyOwner
  {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function excludeFromFee(
    address account
    ) external
    override
    onlyOwner
  {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(
    address account
    ) external
    override
    onlyOwner
  {
    _isExcludedFromFee[account] = false;
  }

  function setDxSaleAddress(
    address dxRouter,
    address presaleRouter
  ) external
    override
    onlyOwner
  {
    require(setPresaleAddresses == true, 'You can only set the presale addresses once!');

    setPresaleAddresses = false;
    _liquidityHolders[dxRouter] = true;
    _isExcludedFromFee[dxRouter] = true;
    _liquidityHolders[presaleRouter] = true;
    _isExcludedFromFee[presaleRouter] = true;
  }

  function setAutomatedMarketMakerPair(
    address pair,
    bool value
    ) external
    override
    onlyOwner
  {
    require(
      pair != pancakeswapV2Pair,
      'NanoDoge: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs'
    );

    _setAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(
    address pair,
    bool value
    ) private
  {
    require(automatedMarketMakerPairs[pair] != value, "NanoDoge: Automated market maker pair is already set to that value");
    automatedMarketMakerPairs[pair] = value;

    if(value) {
      dividendTracker.excludeFromDividends(pair);
    }

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function updateClaimWait(
    uint256 claimWait
    ) external
    override
    onlyOwner
  {
    dividendTracker.updateClaimWait(claimWait);
  }

  function getClaimWait()
  external
  view
  override
  returns(
    uint256
  ) {
    return dividendTracker.claimWait();
  }

  function getTotalDividendsDistributed()
  external
  view
  override
  returns(
    uint256
  ) {
    return dividendTracker.totalDividendsDistributed();
  }

  function withdrawableDividendOf(
    address account
    ) external
    view
    override
    returns(
      uint256
    ) {
    return dividendTracker.withdrawableDividendOf(account);
  }

  function dividendRewardTokenBalanceOf(
    address account
    ) external
    view
    override
    returns(
      uint256
    ) {
    return dividendTracker.balanceOf(account);
  }

  function getAccountDividendsInfo(
    address account
    ) external
    view
    override
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccount(account);
  }

  function getAccountDividendsInfoAtIndex(
    uint256 index
    ) external
    view
    override
    returns(
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccountAtIndex(index);
  }

  function processDividendTracker(
    uint256 gas
    ) external
    override
   { (
      uint256 iterations,
      uint256 claims,
      uint256 lastProcessedIndex
    ) = dividendTracker.process(gas);

    emit ProcessedDividendTracker(
      iterations,
      claims,
      lastProcessedIndex,
      false,
      gas,
      tx.origin
    );
  }

  function claim()
  external
  override
  {
    dividendTracker.processAccount(payable(msg.sender), false);
  }

  function getLastProcessedIndex()
  external
  view
  override
  returns(
    uint256
  ) {
    return dividendTracker.getLastProcessedIndex();
  }

  function getNumberOfDividendTokenHolders()
  external
  view
  override
  returns(
    uint256
  ) {
    return dividendTracker.getNumberOfTokenHolders();
  }

  function _removeAllFee()
  private
  {
    if(_totalFee == 0) {
      return;
    }

    _previousTotalFee = _totalFee;
    _totalFee = 0;
  }

  function _restoreAllFee()
  private
  {
    _totalFee = _previousTotalFee;
  }

  function isExcludedFromFee(
    address account
    ) public
    view
    override
    returns(
      bool
    ) {
    return _isExcludedFromFee[account];
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
    ) private
  {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(amount > 0, 'Transfer amount must be greater than zero');

    if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
      require(amount <= _maxTxAmount, 'Transfer amount exceeds the maxTxAmount.');
      require(_tradingEnabled, 'Trading is currently disabled');
    }

    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is pancakeswap pair.
    uint256 contractTokenBalance = balanceOf(address(this));

    if(contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    if(
      (contractTokenBalance >= _numTokensSellToAddToLiquidity)
        && !inSwapAndLiquify
        && from != pancakeswapV2Pair
        && swapAndLiquifyEnabled
    ) {
      // set inSwapAndLiquify to true so the contract isnt looping through adding liquididty
      inSwapAndLiquify = true;

      contractTokenBalance = _numTokensSellToAddToLiquidity;
      uint256 swapForLiq = (contractTokenBalance * _liquidityFee) / _totalFee;
      _swapAndLiquify(swapForLiq);

      uint256 swapForDividends = (contractTokenBalance * _dividendRewardsFee) / _totalFee;
      _swapAndSendTokenDividends(swapForDividends);

      uint256 swapForMarketing = balanceOf(address(this));
      _swapTokensForMarketing(swapForMarketing);

      // dust ETH after executing all swaps
      _withdrawableBalance = address(this).balance;

      inSwapAndLiquify = false;
    }

    // indicates if fee should be deducted from transfer
    bool takeFee = true;

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    // transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from, to, amount, takeFee);
  }

  function _swapAndLiquify(
      uint256 tokens
      ) private
      {
        // split the contract balance into halves
        uint256 half = (tokens / 2);
        uint256 otherHalf = tokens - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForETH(half);

        // get the delta balance from the swap
        uint256 deltaBalance = (address(this).balance - initialBalance);

        // add liquidity to pancakeswap
        _addLiquidity(otherHalf, deltaBalance);

        emit SwapAndLiquify(half, deltaBalance, otherHalf);
  }

  function _swapTokensForETH(
      uint256 tokenAmount
      ) private
      {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0, // accept any amount of ETH
          path,
          address(this),
          block.timestamp
        );
      }

  function _swapTokensForMarketing(
      uint256 tokenAmount)
      private
      {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0, // accept any amount of ETH
          path,
          _marketingWallet,
          block.timestamp
        );
      }

  function withdrawLockedETH(
      address recipient
      ) external
        override
        nonReentrant
        onlyOwner
      {
        require(recipient != address(0), 'Cannot withdraw the ETH balance to the zero address');
        require(_withdrawableBalance > 0, 'The ETH balance must be greater than 0');

        uint256 amount = _withdrawableBalance;
        _withdrawableBalance = 0;

        (bool success,) = payable(recipient).call{value: amount}('');

        if(!success) {
          revert();
        }
      }

  function _swapTokensForDividends(
      uint256 tokenAmount,
      address recipient
      ) private
      {
        // generate the pancakeswap pair path of weth -> dividend
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        path[2] = _dividendRewardToken;

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          tokenAmount,
          0, // accept any amount of tokens
          path,
          recipient,
          block.timestamp
        );
      }

  // withdraw any tokens that are not supposed to be insided this contract.
  function withdrawLockedTokens(
      address recipient,
      address _token
      ) external
        override
        onlyOwner
      {
        require(_token != pancakeswapV2Router.WETH());
        require(_token != address(this));

        uint256 amountToWithdraw = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(payable(recipient), amountToWithdraw);
      }

      function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
          address(this),
          tokenAmount,
          0, // slippage is unavoidable
          0, // slippage is unavoidable
          owner(),
          block.timestamp
        );
      }

  function _checkLiquidityAdd(
      address from,
      address to
      ) private {
        // if liquidity is added by the _liquidityholders set trading enables to true and start the anti sniper timer
        require(!_hasLiqBeenAdded, 'Liquidity already added and marked.');
        if (_liquidityHolders[from] && to == pancakeswapV2Pair) {
        _hasLiqBeenAdded = true;
        _tradingEnabled = true;
        _liqAddBlock = block.number;
        }
  }
  // this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {
    // failsafe, disable the whole system if needed.
    if(_sniperProtection) {
      // if sender is a sniper address, reject the sell.
      if(isSniper(sender)) {
        revert('Sniper rejected.');
      }

      // check if this is the liquidity adding tx to startup.
      if(!_hasLiqBeenAdded) {
        _checkLiquidityAdd(sender, recipient);
      } else {
        if(
          _liqAddBlock > 0
            && sender == pancakeswapV2Pair
            && !_liquidityHolders[sender]
            && !_liquidityHolders[recipient]
        ) {
          if(block.number - _liqAddBlock < _snipeBlockAmount) {
            _isSniper[recipient] = true;
            snipersCaught++;
            emit SniperCaught(recipient);
          }
        }
      }
    }

    if(!takeFee) {
      _removeAllFee();
    }

    _takeLiquidityAndTransfer(sender, recipient, amount);

    try dividendTracker.setBalance(payable(sender), balanceOf(sender)) {} catch {}
    try dividendTracker.setBalance(payable(recipient), balanceOf(recipient)) {} catch {}

    if(!inSwapAndLiquify) {
      uint256 gas = gasForProcessing;

      try dividendTracker.process(gas) returns(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex
      ) {
        emit ProcessedDividendTracker(
          iterations,
          claims,
          lastProcessedIndex,
          true,
          gas,
          tx.origin
        );
      } catch {}
    }

    if(!takeFee) {
      _restoreAllFee();
    }
  }

  function _takeLiquidityAndTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    _balances[sender] -= amount;

    uint256 liquidityAmount = (amount / 100) * _totalFee;
    uint256 transferAmount = amount - liquidityAmount;

    _balances[address(this)] += liquidityAmount;
    _balances[recipient] += transferAmount;

    emit Transfer(sender, address(this), liquidityAmount);
    emit Transfer(sender, recipient, transferAmount);
  }

  function setMarketingWallet(
    address payable newWallet
    ) external
    override
    onlyOwner
  {
    require(_marketingWallet != newWallet, 'Wallet already set!');
    _marketingWallet = newWallet;
  }

  function updateDividendTracker(
    address newAddress
    ) external
    override
    onlyOwner
  {
    require(
      newAddress != address(dividendTracker),
      'NanoDogeCoin: The dividend tracker already has that address'
    );

    DividendTracker newDividendTracker = DividendTracker(payable(newAddress));

    require(
      newDividendTracker.owner() == address(this),
      'NanoDogeCoin: The new dividend tracker must be owned by the token contract'
    );

    newDividendTracker.excludeFromDividends(address(newDividendTracker));
    newDividendTracker.excludeFromDividends(address(this));
    newDividendTracker.excludeFromDividends(owner());
    newDividendTracker.excludeFromDividends(address(pancakeswapV2Router));

    emit UpdateDividendTracker(newAddress, address(dividendTracker));

    dividendTracker = newDividendTracker;
  }

  function _swapAndSendTokenDividends(
    uint256 tokens
    ) private
    {
      _swapTokensForDividends(tokens, address(this));
      uint256 dividends = IERC20(_dividendRewardToken).balanceOf(address(this));
      bool success = IERC20(_dividendRewardToken).transfer(address(dividendTracker), dividends);

          if(success) {
         dividendTracker.distributeRewardDividends(dividends);
         emit SendDividends(tokens, dividends);
        }
    }

  function changeFees(
    uint256 liquidityFee,
    uint256 marketingFee,
    uint256 dividendFee
    ) public
    override
    onlyOwner
  {
    // fees are setup so they can not exceed 30% in total
    // and specific limits for each one.
    require(liquidityFee <= 5);
    require(marketingFee <= 5);
    require(dividendFee <= 20);

    _liquidityFee = liquidityFee;
    _marketingFee = marketingFee;
    _dividendRewardsFee = dividendFee;

    _totalFee = liquidityFee + marketingFee + dividendFee;
  }
}