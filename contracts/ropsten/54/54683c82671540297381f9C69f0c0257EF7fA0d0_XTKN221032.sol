/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

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
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

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
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol

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
        require(owner() == _msgSender(), "[xtkn221032][ownable] caller is not the owner");
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
        require(newOwner != address(0), "[xtkn221032][ownable] new owner is the zero address");
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
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

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
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
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
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
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
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 
// #############################################################################################################################
// ####################################### I M P O R T - E X T E R N A L - L I B R A R Y #######################################
 
// We are using an external library to secure/optimize the contract, please check the github release for further information
// this code is not provided by us, but deemed secure by the community
 
// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
// #################################################### I M P O R T - E N D ####################################################
// #############################################################################################################################
 


/*
    this is our anti-whale system
    - triggered when someone sells more than 1 million tokens at once
    - taxation based on sell volume in tax brackets
*/
abstract contract RobinHood is Context{
    using SafeMath for uint256;
    using Address for address;

    struct FriarTuck {
        uint256 start;
        uint256 end;
        uint16 tax;
    }

    uint256[] private MaidMarian;
    uint256 public minTokenForAmbush = 1000000 * (10**9);
    mapping(uint256 => FriarTuck) private _LittleJohnsTaxBracket;

    event AmbushAtNight(address indexed pFrom, address indexed to, uint256 gold);
    event LoadingChestsOntoTheHorseCharriage(uint256 chest, uint256 princeJohn);
    event VanishIntoTheSherwoodForest(uint16 chests, uint256 gold);
    event FleeYouFoolsFlee(bool success);

    constructor(){
        _sheriffOfNottingham(1000000, 2000000, 100, 0); // 10% burn on the first million to the 2nd million
        _sheriffOfNottingham(2000000, 3000000, 120, 1); // 12% burn from 2M to 3M
        _sheriffOfNottingham(3000000, 4000000, 140, 2); // 14% burn from 3M to 4m
        _sheriffOfNottingham(4000000, 10000000, 200, 3); // 20% burn from 4M to 10M
        _sheriffOfNottingham(10000000, 20000000, 250, 4); // 25% burn from 10M to 20M
        _sheriffOfNottingham(20000000, 50000000, 330, 5); // 33% burn from 20M to 50M
        _sheriffOfNottingham(50000000, 100000000, 400, 6); // 40% burn from 50M to 100M
        _sheriffOfNottingham(100000000, 1000000000, 500, 7); // 50% burn from 100M to one billion
    }

    function ambushAtNight(uint256 princeJohn) public returns(uint256 goldCoins){
        // this functin will calculate to the taxes based on the brackets and the volume
        uint16 chests;
        uint256 chest;
        uint256 horseCarriage;

        for(uint256 i=0; i<MaidMarian.length; i++){
            if(princeJohn >= _LittleJohnsTaxBracket[MaidMarian[i]].start){ // check if prince John has enough gold
                if(princeJohn <= _LittleJohnsTaxBracket[MaidMarian[i]].end){ // check if he has more gold for the next bracket
                    chest = princeJohn.sub(_LittleJohnsTaxBracket[MaidMarian[i]].start); // if not, tax the current bracket
                }else{
                    chest = (_LittleJohnsTaxBracket[MaidMarian[i]].end.sub(_LittleJohnsTaxBracket[MaidMarian[i]].start)) + 1; // if yes, tax the current bracket to maximum
                }
                chests = chests + 1; // add a new chest
                horseCarriage = horseCarriage.add(_patButtram(chest, _LittleJohnsTaxBracket[MaidMarian[i]].tax)); // calculate taxes for the chest
                princeJohn = princeJohn.sub(chest); // remove the chest from prince John
                emit LoadingChestsOntoTheHorseCharriage(chest, princeJohn);
            }

            if(princeJohn <= 0){ // if prince John runs out of gold, abort
                break;
            }
        }

        if(horseCarriage > 0){
            emit VanishIntoTheSherwoodForest(chests, horseCarriage);
        }else{
            emit FleeYouFoolsFlee(false);
        }        

        return(horseCarriage); // return amount of taken gold
    }

    function _sheriffOfNottingham(uint256 pStart, uint256 pEnd, uint16 pTax, uint256 pUID) private{
        FriarTuck storage bracket = _LittleJohnsTaxBracket[pUID];
        bracket.start = (pStart + 1) * (10**9);
        bracket.end = pEnd * (10**9);
        bracket.tax = pTax;
        MaidMarian.push(pUID);
    }

    function _patButtram(uint256 pAmount, uint16 pTax) private pure returns(uint256){
        return(pAmount.mul(pTax).div(10**3));
    }
}


abstract contract Native is Context, Ownable {
    function balance() public view virtual returns(uint256){
        return(address(this).balance);
    }

    function transferNative(address pTo, uint256 pAmount) public virtual onlyOwner returns(bool){
        address payable to = payable(pTo);
        (bool sent, ) = to.call{value:pAmount}("");
        return(sent);
    }
}



library Array256{
    using Array256 for uint256[];
    function del(uint256[] storage self, uint256 i) internal{
        self[i] = self[self.length -1];
        self.pop();
    }

    function delval(uint256[] storage self, uint256 v) internal{
        for(uint256 i=0; i<self.length; i++){
            if(self[i] == v){
                self.del(i);
            }
        }
    }
}


contract IXTKN221032Liquidity{
    function init() public{}
    function getPair() public returns(address){}
}


contract IXTKN221032Project{
    function init() public{}
    function deposit(address, address, uint256) public{}
    function update() public {}
}


contract IXTKN221032Staking{
    function init() public{}
    function deposit(address, address, uint256) public{}
    function balanceOf(address) public view returns(uint256){}
}


contract IXTKN221032StakingLocked{
    function init(uint256, uint256) public{}
    function balanceOf(address) public view returns(uint256){}
}


contract IXTKN221032PreSale{
    function init(uint256, address) public{}
    function balanceOf(address) public view returns(uint256){}
}


contract IXTKN221032Lottery{
    function init(uint256) public{}
    function deposit(address, address, uint256) public{}
    function balanceOf(address) public view returns(uint256){}
}



// main contract
/*
    This is the main contract of the project
    - Owner of all sub contracts except the ones that lock or self destroy
    - ERC20 functionality
    - Taxation of transfers
*/
contract XTKN221032 is Context, IERC20, Ownable, RobinHood, Native, ReentrancyGuard{
    // public properties
        // lib
            using SafeMath for uint256; // more safe & secure uint256 operations
            using Address for address; // more safe & secure address operations
            using Array256 for uint256[]; // added functionality to arrays

        // interfaces
            // these are interfaces to all other contracts of the project
            IXTKN221032Liquidity private _liquidity;
            IXTKN221032Project private _project;
            IXTKN221032Staking private _staking;
            IXTKN221032StakingLocked private _staking30D;
            IXTKN221032StakingLocked private _staking90D;
            IXTKN221032StakingLocked private _staking180D;
            IXTKN221032StakingLocked private _staking365D;
            IXTKN221032PreSale private _preSale;
            IXTKN221032Lottery private _lottery;

        // addresses
            address public ADDRESS_BURN = 0x000000000000000000000000000000000000dEaD; // burn baby, burn!
            address public ADDRESS_LIQUIDITY;// liquidity contract, locked no owner
            address public ADDRESS_PAIR;// swap pair contract, locked no owner
            address public ADDRESS_PRESALE;// presale contract, locked no owner
            address public ADDRESS_PRESALE_VAULT;// locked tokens after presale
            address public ADDRESS_LOTTERY;// lottery contract, locked no owner
            address public ADDRESS_STAKING;// default stacking (add/withdraw any time), locked no owner
            address public ADDRESS_PROJECT;// project funds, unlocked (team)
            address public ADDRESS_STAKING_DAYS30;// staking for 30 days contract, locked no owner
            address public ADDRESS_STAKING_DAYS90;// staking for three months contract, locked no owner
            address public ADDRESS_STAKING_DAYS180;// staking for half a year, locked no owner
            address public ADDRESS_STAKING_DAYS365;// staking for a year, locked no owner
            address public ADDRESS_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // address of the uniswap router
            address public ADDRESS_ERC20_USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // address of the USDC coin on this blockchain

        // interfaces
            IUniswapV2Router02 public router; // interface for uniswap router
            ERC20 private ERC20_NATIVE; // interface for wrapped native
            ERC20 private ERC20_USDC; // interface for USDC

        // taxes
            // there are different tax fees hard codes, these fees can never be changed
            // there is a different fee for buying and selling, there is even a whale sell fee called robinhood (check the abstract contract for that)
            // taxes are stored as uint16 and divided by 10^3, that means 1 = 0.1%, 10 = 1%, 100 = 10%, 1000 = 100%
            uint16 public TAX_BUY_LOTTERY = 35;
            uint16 public TAX_BUY_STAKING = 35;
            uint16 public TAX_BUY_PROJECT = 30;
            uint16 public TAX_BUY_BURN = 0;

            uint16 public TAX_SELL_LOTTERY = 10;
            uint16 public TAX_SELL_STAKING = 10;
            uint16 public TAX_SELL_PROJECT = 10;
            uint16 public TAX_SELL_BURN = 70;
            uint16 public TAX_SELL_REDISTRIBUTE_ROBIN_HOOD = 11; // 11% of all tokens taken by robin hood will be added to the staking pool and lottery (2x11%)

        // token distribution
            // this is the initial token distrubtion, of all tokens, all of them will be sent to other contracts
            // the main contract holds no tokens
            uint256 public TOKENS_FOR_PROJECT;
            uint256 public TOKENS_FOR_STAKING;
            uint256 public TOKENS_FOR_LIQUIDITY;
            uint256 public TOKENS_FOR_PRESALE;
            bool public SWAPPING_ENABLED = false; // will be activated once presale is finished an liquidity has been created

    // private properties
        // tokenomics
        // how our token is setup, standard one billion tokens, but with 9 decimals
            string private _name = "XTKN221032"; // the name of our project
            string private _symbol = "XTKN221032";
            uint8 private _decimals = 9;
            uint256 private _totalSupply = 1000000000 * (10**9); // one billion
            uint256 private _whaleAlert = 1000000 * (10**9); // whale alert minimum tokens (one million)

        // mappings (data storage)
            mapping(address => uint256) private _balances;
            mapping(address => mapping (address => uint256)) private _allowances;
            mapping(address => bool) private _accountNoTaxes;

        // struct
            // we use this data struct to hold tax calculations for the transaction
            struct Tax{
                uint16 Lottery;
                uint16 Staking;
                uint16 Project;
                uint16 Burn;
                uint256 totalLottery;
                uint256 totalStaking;
                uint256 totalProject;
                uint256 totalBurn;
                uint256 total;
                uint256 ambush;
                uint256 ambushStaking;
                uint256 ambushLottery;
            }

        // activation of contracts
            // when all contracts are active, the main contract can be activated too, not before!
            bool private _contractLiquidityActive = false;
            bool private _contractLotteryActive = false;
            bool private _contractStakingActive = false;
            bool private _contractProjectActive = false;
            bool private _contractPreSaleActive = false;

    // events
        // these events are used off-chain (like on a website, or for a bot, or for you), to see whats happening in real time
        event ContractCreation();
        event ContractLocked(address indexed locker, uint256 time);

        event TransactionStart(address indexed pFrom, address indexed to, uint256 value);
            event TransactionBuy(address indexed pFrom, address indexed to, uint256 value);
            event TransactionSell(address indexed pFrom, address indexed to, uint256 value);
            event TransactionWhaleAlert(address indexed pFrom, address indexed to, uint256 value, bool buy, bool sell);
            event TransactionTransfer(address indexed pFrom, address indexed to, uint256 value);
            event TransactionWithNoTaxes(address indexed pFrom, address indexed to, uint256 value);
            event TransactionWithTaxes(address indexed pFrom, address indexed to, uint256 value, uint256 taxes);
            event TransactionBurn(uint256 burn, uint256 total);
            event TransactionLottery(uint256 lotteryTax);
            event TransactionStaking(uint256 stakingTax);
            event TransactionProject(uint256 projectTax);
        event TransactionEnd();

    // contract can be paid
    // we need to be able to get paid
    receive() external payable {}

    constructor(){
        // token creation
            // create all tokens and keep them in this contract for now
            _balances[address(this)] = _totalSupply;
            emit Transfer(address(0), address(this), _totalSupply);

        // except some accounts from paying taxes
            // in order to move tokens arround, we need to except our contracts to not pay taxes, otherwise you pay taxes on taxes on taxes in a loop
            _accountNoTaxes[address(this)] = true;
            _accountNoTaxes[ADDRESS_BURN] = true;

        // set token distribution
            // how we distribute our tokens after creation
            TOKENS_FOR_STAKING = 150000000 * (10**_decimals); // 150 million for staking rewards
            TOKENS_FOR_PRESALE = 135000000 * (10**_decimals); // 135 million to presale
            TOKENS_FOR_PROJECT = 50000000 * (10**_decimals); // 50 million to development for initial funding
            TOKENS_FOR_LIQUIDITY = _totalSupply.sub(TOKENS_FOR_STAKING).sub(TOKENS_FOR_PROJECT).sub(TOKENS_FOR_PRESALE); // rest goes to liquidity

        // set interfaces
            router = IUniswapV2Router02(ADDRESS_ROUTER);
            ERC20_NATIVE = ERC20(router.WETH());
            ERC20_USDC = ERC20(ADDRESS_ERC20_USDC);

        emit ContractCreation();
    }



    // owner
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝
    
    function kill() public onlyOwner{
        renounceOwnership(); // contract locked, bye!
        emit ContractLocked(_msgSender(), block.timestamp);
    }

    
    event LiquiditySuccess();
    event LiquidityBalance(uint256 balance);
    event LiquidityFail();    
    function initLiquidity(address contractAddress) public onlyOwner{
        if(!_contractLiquidityActive){
            // set contract address
            ADDRESS_LIQUIDITY = contractAddress;

            // no taxes for contract
            _accountNoTaxes[ADDRESS_LIQUIDITY] = true;

            // send all native tokens to liquidity
            transferNative(ADDRESS_LIQUIDITY, balance());

            // check if liquidity contract has any native tokens, if not abort
            emit LiquidityBalance(ADDRESS_LIQUIDITY.balance);

            if(ADDRESS_LIQUIDITY.balance > 0){
                // send tokens
                _transactionTokens(address(this), ADDRESS_LIQUIDITY, TOKENS_FOR_LIQUIDITY);

                // init contract
                _liquidity = IXTKN221032Liquidity(ADDRESS_LIQUIDITY);
                _liquidity.init();
                ADDRESS_PAIR = _liquidity.getPair();

                // contract active
                _contractLiquidityActive = true;
                SWAPPING_ENABLED = true;

                emit LiquiditySuccess();
            }else{
                emit LiquidityFail();
            }
        }
    }

    event ProjectSuccess();
    function initProject(address contractAddress) public onlyOwner{
        if(!_contractProjectActive){
            // set contract address
            ADDRESS_PROJECT = contractAddress;

            // no taxes for contract
            _accountNoTaxes[ADDRESS_PROJECT] = true;

            // transfer initial tokens
            _transactionTokens(address(this), ADDRESS_PROJECT, TOKENS_FOR_PROJECT);

            // init contract
            _project = IXTKN221032Project(ADDRESS_PROJECT);
            _project.init();
            _project.deposit(address(this), ADDRESS_PROJECT, TOKENS_FOR_PROJECT);
            _project.update();

            // contract active
            _contractProjectActive = true;

            emit ProjectSuccess();
        }
    }

    event StakingSuccess();
    function initStaking(
        address contractAddress,
        address contractAddress30D,
        address contractAddress90D,
        address contractAddress180D,
        address contractAddress365D
    ) public onlyOwner{
        if(!_contractStakingActive){
            // set contract address
            ADDRESS_STAKING = contractAddress;
            ADDRESS_STAKING_DAYS30 = contractAddress30D;
            ADDRESS_STAKING_DAYS90 = contractAddress90D;
            ADDRESS_STAKING_DAYS180 = contractAddress180D;
            ADDRESS_STAKING_DAYS365 = contractAddress365D;

            // no taxes for contract
            _accountNoTaxes[ADDRESS_STAKING] = true;
            _accountNoTaxes[ADDRESS_STAKING_DAYS30] = true;
            _accountNoTaxes[ADDRESS_STAKING_DAYS90] = true;
            _accountNoTaxes[ADDRESS_STAKING_DAYS180] = true;
            _accountNoTaxes[ADDRESS_STAKING_DAYS365] = true;

            // transfer initial tokens to staking contracts
            uint256 staking30D = 5000000 * (10**9);
            uint256 staking90D = 16000000 * (10**9);
            uint256 staking180D = 35000000 * (10**9);
            uint256 staking365D = 94000000 * (10**9);
            _transactionTokens(address(this), ADDRESS_STAKING_DAYS30, staking30D);
            _transactionTokens(address(this), ADDRESS_STAKING_DAYS90, staking90D);
            _transactionTokens(address(this), ADDRESS_STAKING_DAYS180, staking180D);
            _transactionTokens(address(this), ADDRESS_STAKING_DAYS365, staking365D);

            // init contract
            _staking = IXTKN221032Staking(ADDRESS_STAKING);
            _staking.init();
            
            _staking30D = IXTKN221032StakingLocked(ADDRESS_STAKING_DAYS30);
            _staking30D.init(1640166435, 30);

            _staking90D = IXTKN221032StakingLocked(ADDRESS_STAKING_DAYS90);
            _staking90D.init(1640166435, 90);

            _staking180D = IXTKN221032StakingLocked(ADDRESS_STAKING_DAYS180);
            _staking180D.init(1640166435, 180);

            _staking365D = IXTKN221032StakingLocked(ADDRESS_STAKING_DAYS365);
            _staking365D.init(1640166435, 365);

            // contract active
            _contractStakingActive = true;

            emit StakingSuccess();
        }
    }

    event PreSaleSuccess();
    function initPreSale(address contractAddress, address contractVault) public onlyOwner{
        if(!_contractPreSaleActive){
            // set contract address
            ADDRESS_PRESALE = contractAddress;
            ADDRESS_PRESALE_VAULT = contractVault;

            // no taxes for contract
            _accountNoTaxes[ADDRESS_PRESALE] = true;
            _accountNoTaxes[ADDRESS_PRESALE_VAULT] = true;

            // transfer initial tokens
            _transactionTokens(address(this), ADDRESS_PRESALE, TOKENS_FOR_PRESALE);

            // init contract
            _preSale = IXTKN221032PreSale(ADDRESS_PRESALE);
            _preSale.init(1640166435, ADDRESS_PRESALE_VAULT);

            // contract active
            _contractPreSaleActive = true;

            // disable trading during presale, if we could trade, it would make presale useless
            SWAPPING_ENABLED = false;

            emit PreSaleSuccess();
        }
    }

    event LotterySuccess();
    function initLottery(address contractAddress) public onlyOwner{
        if(!_contractLotteryActive){
            // set contract address
            ADDRESS_LOTTERY = contractAddress;

            // no taxes for contract
            _accountNoTaxes[ADDRESS_LOTTERY] = true;

            // init contract
            _lottery = IXTKN221032Lottery(ADDRESS_LOTTERY);
            _lottery.init(1640166435);

            // contract active
            _contractLotteryActive = true;

            emit LotterySuccess();
        }
    }




    // public
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

    
    function name() public view returns(string memory) {
        return(_name);
    }

    function symbol() public view returns(string memory) {
        return(_symbol);
    }

    function decimals() public view returns(uint8){
        return(_decimals);
    }

    function totalSupply() public view override returns(uint256){
        return(_totalSupply);
    }

    function balanceOf(address account) public view override returns(uint256){
        return(_balances[account]);
    }

    function allowance(address owner, address spender) public view override returns(uint256){
        return(_allowances[owner][spender]);
    }

    function approve(address spender, uint256 amount) public override returns(bool){
        _approve(_msgSender(), spender, amount);
        return(true);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "[xtkn221032] approve from the zero address");
        require(spender != address(0), "[xtkn221032] approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return(true);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "[xtkn221032] decreased allowance below zero"));
        return(true);
    }

    function transfer(address recipient, uint256 amount) public override returns(bool){
        _transfer(_msgSender(), recipient, amount);
        return(true);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "[xtkn221032] transfer amount exceeds allowance"));
        return(true);
    }


    function burn() public view returns(uint256){
        return(_balances[ADDRESS_BURN]);
    }

    function price() public view returns(uint256){
        require(_contractLiquidityActive, "[xtkn221032][Main] no liquidity, no price!");
        uint256 oneSingleNativeToken = 1 * (10**ERC20_NATIVE.decimals());

        // get price native vs USDC
        address[] memory pathUSDC = new address[](2);
        pathUSDC[0] = router.WETH(); // native address
        pathUSDC[1] = ADDRESS_ERC20_USDC; // USDC currency address
        uint256[] memory priceNativeToUSDC = router.getAmountsOut(oneSingleNativeToken, pathUSDC);

        // get price native vs token
        address[] memory pathTOKEN = new address[](2);
        pathTOKEN[0] = router.WETH(); // native address
        pathTOKEN[1] = address(this); // token address
        uint256[] memory priceNativeToTOKEN = router.getAmountsOut(oneSingleNativeToken, pathTOKEN);
        
        // calculate USDC price
        uint256 tokenPrice = priceNativeToUSDC[1].mul(10**18).div(priceNativeToTOKEN[1]);
        return(tokenPrice);
    }

    function totalBalanceOf(address pWallet) public view returns(uint256){
        uint256 tokenBalance = balanceOf(pWallet);

        if(_contractPreSaleActive){
            tokenBalance = tokenBalance.add(_preSale.balanceOf(pWallet));
        }

        if(_contractStakingActive){
            tokenBalance = tokenBalance.add(_staking.balanceOf(pWallet));
            tokenBalance = tokenBalance.add(_staking30D.balanceOf(pWallet));
            tokenBalance = tokenBalance.add(_staking90D.balanceOf(pWallet));
            tokenBalance = tokenBalance.add(_staking180D.balanceOf(pWallet));
            tokenBalance = tokenBalance.add(_staking365D.balanceOf(pWallet));
        }

        if(_contractLotteryActive){
            tokenBalance = tokenBalance.add(_lottery.balanceOf(pWallet));
        }

        return(tokenBalance);
    }


    // private
    // ███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗███████╗
    // ╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

    function _transfer(address pFrom, address pTo, uint256 pAmount) private{
        // this is the main transfer function used by transfer and transferFrom

        emit TransactionStart(pFrom, pTo, pAmount);

        Tax memory Taxes; // only store in memory, not storage
        bool isBuy = false;
        bool isSell = false;

        // get trade direction
        if(pFrom == ADDRESS_PAIR){
            require(SWAPPING_ENABLED, "[xtkn221032][Main] trading disabled during presale!");
            // buy from LP set buy tax
            isBuy = true;
            Taxes.Lottery = TAX_BUY_LOTTERY;
            Taxes.Staking = TAX_BUY_STAKING;
            Taxes.Project = TAX_BUY_PROJECT;
            Taxes.Burn = TAX_BUY_BURN;

            emit TransactionBuy(pFrom, pTo, pAmount);
        }

        if(pTo == ADDRESS_PAIR){
            require(SWAPPING_ENABLED, "[xtkn221032][Main] trading disabled during presale!");
            // sell to LP set sell tax
            isSell = true;
            Taxes.Lottery = TAX_SELL_LOTTERY;
            Taxes.Staking = TAX_SELL_STAKING;
            Taxes.Project = TAX_SELL_PROJECT;
            Taxes.Burn = TAX_SELL_BURN;

            emit TransactionSell(pFrom, pTo, pAmount);
        }

        if(!isBuy && !isSell){
            // transfer, we do not buy or sell, but move tokens from A to B, no taxes!
            Taxes.Lottery = 0;
            Taxes.Staking = 0;
            Taxes.Project = 0;
            Taxes.Burn = 0;

            emit TransactionTransfer(pFrom, pTo, pAmount);
        }

        if(pAmount > _whaleAlert){
            emit TransactionWhaleAlert(pFrom, pTo, pAmount, isBuy, isSell);
        }

        if(_accountNoTaxes[pFrom] || _accountNoTaxes[pTo]){
            // transaction is excepted from paying any taxes (internal contract transfers)
            emit TransactionWithNoTaxes(pFrom, pTo, pAmount);  
            _transactionTokens(pFrom, pTo, pAmount);
        }else{
            // lets start calculating taxes
            if(_contractLotteryActive){
                Taxes.totalLottery = _tax(pAmount, Taxes.Lottery);
            }else{
                Taxes.totalLottery = 0;
            }
            if(_contractStakingActive){
                Taxes.totalStaking = _tax(pAmount, Taxes.Staking);
            }else{
                Taxes.totalStaking = 0;
            }
            if(_contractProjectActive){
                Taxes.totalProject = _tax(pAmount, Taxes.Project);
            }else{
                Taxes.totalProject = 0;
            }
            
            if(isSell && pAmount > minTokenForAmbush){
                // the sell of more than the needed amount of tokens is triggered
                // we will now add further taxes, like you pay your income tax, this will be calculated in brackets
                // this will only affect whales who sell more than one million tokens
                // only ambush Prince John at night
                emit AmbushAtNight(pFrom, pTo, pAmount);
                Taxes.ambush = ambushAtNight(pAmount);
                Taxes.totalBurn = Taxes.ambush; // burn all the chests!

                if(_contractLotteryActive){
                    Taxes.ambushLottery = _tax(Taxes.ambush, TAX_SELL_REDISTRIBUTE_ROBIN_HOOD);
                    Taxes.totalBurn = Taxes.totalBurn.sub(Taxes.ambushLottery);
                    Taxes.totalLottery = Taxes.totalLottery.add(Taxes.ambushLottery);
                }

                if(_contractStakingActive){
                    Taxes.ambushStaking = _tax(Taxes.ambush, TAX_SELL_REDISTRIBUTE_ROBIN_HOOD);
                    Taxes.totalBurn = Taxes.totalBurn.sub(Taxes.ambushStaking);
                    Taxes.totalStaking = Taxes.totalStaking.add(Taxes.ambushStaking);
                }
            }else{
                Taxes.totalBurn = _tax(pAmount, Taxes.Burn);
            }

            Taxes.total = Taxes.totalLottery.add(Taxes.totalStaking).add(Taxes.totalProject).add(Taxes.totalBurn);
            emit TransactionWithTaxes(pFrom, pTo, pAmount, Taxes.total);

            // taxation
            if(Taxes.totalBurn > 0){
                _transactionTokens(pFrom, ADDRESS_BURN, Taxes.totalBurn);
                emit TransactionBurn(Taxes.totalBurn, _balances[ADDRESS_BURN]);
            }
            if(Taxes.totalLottery > 0){
                _transactionTokens(pFrom, ADDRESS_LOTTERY, Taxes.totalLottery);
                _lottery.deposit(pFrom, pTo, Taxes.totalLottery);
                emit TransactionLottery(Taxes.totalLottery);
            }
            if(Taxes.totalStaking > 0){
                _transactionTokens(pFrom, ADDRESS_STAKING, Taxes.totalStaking);
                _staking.deposit(pFrom, pTo, Taxes.totalStaking);
                emit TransactionStaking(Taxes.totalStaking);
            }
            if(Taxes.totalProject > 0){
                _transactionTokens(pFrom, ADDRESS_PROJECT, Taxes.totalProject);
                _project.deposit(pFrom, pTo, Taxes.totalProject);
                emit TransactionProject(Taxes.totalProject);
            }

            _transactionTokens(pFrom, pTo, pAmount.sub(Taxes.total));
        }

        emit TransactionEnd();
    }

    function _transactionTokens(address pFrom, address pTo, uint256 pAmount) private{
        _balances[pFrom] = _balances[pFrom].sub(pAmount);
        _balances[pTo] = _balances[pTo].add(pAmount);

        emit Transfer(pFrom, pTo, pAmount);
    }

    function _tax(uint256 pAmount, uint16 tax) private pure returns(uint256){
        return(pAmount.mul(tax).div(10**3));
    }
}