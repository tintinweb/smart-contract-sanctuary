/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

/**
 * @dev Add Pancake Router and Pancake Pair interfaces
 * 
 * from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter01.sol
 */
interface IPancakeRouter01 {
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

// from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol
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

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
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

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakePair.sol
interface IPancakePair {
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
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

/**
 * @dev Collection of functions related to the address type
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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

/**
 * @dev BEP20 Token interface
 */
interface IBEP20 {
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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * 
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    /**
     * @dev Provides information about the current execution context, including the
     * sender of the transaction and its data. While these are generally available
     * via msg.sender and msg.data, they should not be accessed in such a direct
     * manner, since when dealing with GSN meta-transactions the account sending and
     * paying for execution may not be the actual sender (as far as an application
     * is concerned).
     */
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public onlyOwner {
        _previousOwner = _owner;
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public onlyOwner {
        require(_previousOwner == _msgSender(), "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/**
 * @dev Contract module based on Safemoon Protocol
 */
contract XtremeNFT is IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rBalances;
    mapping(address => uint256) private _tBalances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isLockedWallet;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    string private constant _name = "XtremeNFT";
    string private constant _symbol = "XtremeNFT";
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotalSupply = 10 * 10**15 * 10**_decimals; // 10Q
    uint256 private constant _buyMaxTxAmount = _tTotalSupply / 20; // Max 5%
    uint256 private constant _sellMaxTxAmount = 3 * 10**12 * 10**_decimals; // 3T
    uint256 private constant _buyTaxFee = 5;  // 5% holders
    uint256 private constant _buyLiquidityFee = 5; // 5% LP
    uint256 private constant _buyDonationFee = 0; // 0% donation
    uint256 private constant _sellTaxFee = 5; // 5% holders
    uint256 private constant _sellLiquidityFee = 5; // 5% LP
    uint256 private constant _sellDonationFee = 10; // 10% donation
    uint256 private constant numTokensSellToAddToLiquidity = _sellMaxTxAmount; // the same as the maximum sale transaction
    uint256 private constant MAX = ~uint256(0); // MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935

    uint256 private _rTotalSupply;
    uint256 private _maxTxAmount;
    uint256 private _taxFee;
    uint256 private _previousTaxFee;
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;
    uint256 private _donationFee;
    uint256 private _previousDonationFee;
    uint256 private _tFeeTotal;
    uint256 private _tDonationTotal;
    bool private inSwapAndLiquify;

    // wallet for donation
    address payable public constant donationWallet = payable(0x598d38aeD989f1FD7cdA318CD9246c42a0ce8603);
    // wallet for marketing
    address public constant marketingWallet = 0xC8c95A12DBC2385157a83db3D4df3ef72250be78;
    // Mainnet BSC - PancakeSwap Router V2
    address private constant _pancakeRouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    // Testnet BSC - PancakeSwap Router V2
    //address private constant _pancakeRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

    // structs to reflect transfers and fees
    struct tValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tDonationFee;
    }
    // structs for transfers and fees
    struct rValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rLiquidity;
        uint256 rDonationFee;
    }

    constructor() {
        // set utility variables
        _maxTxAmount = _buyMaxTxAmount;
        _taxFee = _buyTaxFee;
        _previousTaxFee = _taxFee;
        _liquidityFee = _buyLiquidityFee;
        _previousLiquidityFee = _liquidityFee;
        _donationFee = _buyDonationFee;
        _previousDonationFee = _donationFee;

        // set reflect total supply
        _rTotalSupply = (MAX - (MAX % _tTotalSupply));
        _rBalances[_msgSender()] = _rTotalSupply;
        emit Transfer(address(0), _msgSender(), _tTotalSupply);

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        // exclude owner, this contract, donation wallet and marketing wallet from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[donationWallet] =  true;
        _isExcludedFromFee[marketingWallet] =  true;
    }

    // to receive BNBs
    receive() external payable {}

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tBalances[account];
        return tokenFromReflection(_rBalances[account]);
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalDonations() public view returns (uint256) {
        return _tDonationTotal;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function lockWallet(address account) public onlyOwner {
        _isLockedWallet[account] = true;
        emit LockedWallet(account, true);
    }

    function unLockWallet(address account) public onlyOwner {
        _isLockedWallet[account] = false;
        emit LockedWallet(account, false);
    }

    function isLockedWallet(address account) public view returns(bool) {
        return _isLockedWallet[account];
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(account != donationWallet, 'We can not exclude donation wallet.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rBalances[account] > 0) {
            _tBalances[account] = tokenFromReflection(_rBalances[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tBalances[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotalSupply, "Amount must be less than supply");
        if (!deductTransferFee) {
            (rValues memory _rv, tValues memory _tv) = _getValues(tAmount); // <- add to donation fee
            _tv.tTransferAmount = 0; _tv.tFee = 0; _tv.tLiquidity = 0; _tv.tDonationFee = 0;
            _rv.rTransferAmount = 0; _rv.rFee = 0; _rv.rLiquidity = 0; _rv.rDonationFee = 0;
            return _rv.rAmount;
        } else {
            (rValues memory _rv, tValues memory _tv) = _getValues(tAmount); // <- add to donation fee
            _tv.tTransferAmount = 0; _tv.tFee = 0; _tv.tLiquidity = 0; _tv.tDonationFee = 0;
            _rv.rTransferAmount = 0; _rv.rFee = 0; _rv.rLiquidity = 0; _rv.rDonationFee = 0;
            return _rv.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotalSupply, "Amount must be less than total reflections");
        return rAmount.div(_getRate());
    }

    function _transfer(address from, address to, uint256 amount) private {
        // prevents transfer of blocked wallets
        require(!_isLockedWallet[from], "Locked addresses cannot call this function");

        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            // set _maxTxAmount to buy or sell action
            if (from == pancakePair) { // Buy
                _maxTxAmount = _buyMaxTxAmount;
            } else if (to == pancakePair) { // Sell
                _maxTxAmount = _sellMaxTxAmount;
            } else { // other
                _maxTxAmount = _buyMaxTxAmount;
            }

            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinimumTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (overMinimumTokenBalance && !inSwapAndLiquify && from != pancakePair) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            // add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        // indicates if fee should be deducted from transfer
        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else {
            // set _taxFee and _liquidityFee to buy or sell action
            if (from == pancakePair) { // Buy
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee;
                _donationFee = _buyDonationFee;
            } else if (to == pancakePair) { // Sell
                _taxFee = _sellTaxFee;
                _liquidityFee = _sellLiquidityFee;
                _donationFee = _sellDonationFee;
            } else { // other
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee;
                _donationFee = _buyDonationFee;
            }
        }

        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _getValues(uint256 tAmount) private view returns (rValues memory, tValues memory) {
        tValues memory _tv = _getTValues(tAmount);
        rValues memory _rv = _getRValues(tAmount, _tv.tFee, _tv.tLiquidity, _tv.tDonationFee, _getRate());
        return (_rv, _tv);
    }

    function _getTValues(uint256 tAmount) private view returns (tValues memory) {
        tValues memory _tv;
        _tv.tFee = calculateTaxFee(tAmount);
        _tv.tLiquidity = calculateLiquidityFee(tAmount);
        _tv.tDonationFee = calculateDonationFee(tAmount);
        _tv.tTransferAmount = tAmount.sub(_tv.tFee).sub(_tv.tLiquidity).sub(_tv.tDonationFee);
        return (_tv);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDonationFee, uint256 currentRate) private pure returns (rValues memory) {
        rValues memory _rv;
        _rv.rAmount = tAmount.mul(currentRate);
        _rv.rFee = tFee.mul(currentRate);
        _rv.rLiquidity = tLiquidity.mul(currentRate);
        _rv.rDonationFee = tDonationFee.mul(currentRate);
        _rv.rTransferAmount = _rv.rAmount.sub(_rv.rFee).sub(_rv.rLiquidity).sub(_rv.rDonationFee);
        return (_rv);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _tTotalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rBalances[_excluded[i]] > rSupply || _tBalances[_excluded[i]] > tSupply) return (_rTotalSupply, _tTotalSupply);
            rSupply = rSupply.sub(_rBalances[_excluded[i]]);
            tSupply = tSupply.sub(_tBalances[_excluded[i]]);
        }
        if (rSupply < _rTotalSupply.div(_tTotalSupply)) return (_rTotalSupply, _tTotalSupply);
        return (rSupply, tSupply);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function calculateDonationFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_donationFee).div(10**2);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBNBBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBNB(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBNBBalance = address(this).balance.sub(initialBNBBalance);

        // add liquidity to pancake
        addLiquidity(otherHalf, newBNBBalance);
        emit SwapAndLiquify(half, newBNBBalance, otherHalf);

        // takes the remaining BNBs and sends them to the donation wallet
        uint256 donationBNBBalance = address(this).balance;
        if (donationBNBBalance > 0) {
            transferBNBDonation(donationWallet, donationBNBBalance);
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: bnbAmount}( // the return values of function not will are handled
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0), // generated LP tokens from the SOSAMZ-BNB pool will sended to blackhole address
            block.timestamp
        );
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _donationFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousDonationFee = _donationFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _donationFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _donationFee = _previousDonationFee;
    }

    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (rValues memory _rv, tValues memory _tv) = _getValues(tAmount);
        _rBalances[sender] = _rBalances[sender].sub(_rv.rAmount);
        _rBalances[recipient] = _rBalances[recipient].add(_rv.rTransferAmount);
        _takeLiquidity(_tv.tLiquidity);
        _reflectFee(_rv.rFee, _tv.tFee);
        emit Transfer(sender, recipient, _tv.tTransferAmount);
        _transferDonation(sender, _rv.rDonationFee, _tv.tDonationFee);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (rValues memory _rv, tValues memory _tv) = _getValues(tAmount);
        _rBalances[sender] = _rBalances[sender].sub(_rv.rAmount);
        _tBalances[recipient] = _tBalances[recipient].add(_tv.tTransferAmount);
        _rBalances[recipient] = _rBalances[recipient].add(_rv.rTransferAmount);
        _takeLiquidity(_tv.tLiquidity);
        _reflectFee(_rv.rFee, _tv.tFee);
        emit Transfer(sender, recipient, _tv.tTransferAmount);
        _transferDonation(sender, _rv.rDonationFee, _tv.tDonationFee);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (rValues memory _rv, tValues memory _tv) = _getValues(tAmount);
        _tBalances[sender] = _tBalances[sender].sub(tAmount);
        _rBalances[sender] = _rBalances[sender].sub(_rv.rAmount);
        _rBalances[recipient] = _rBalances[recipient].add(_rv.rTransferAmount);
        _takeLiquidity(_tv.tLiquidity);
        _reflectFee(_rv.rFee, _tv.tFee);
        emit Transfer(sender, recipient, _tv.tTransferAmount);
        _transferDonation(sender, _rv.rDonationFee, _tv.tDonationFee);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (rValues memory _rv, tValues memory _tv) = _getValues(tAmount);
        _tBalances[sender] = _tBalances[sender].sub(tAmount);
        _rBalances[sender] = _rBalances[sender].sub(_rv.rAmount);
        _tBalances[recipient] = _tBalances[recipient].add(_tv.tTransferAmount);
        _rBalances[recipient] = _rBalances[recipient].add(_rv.rTransferAmount);
        _takeLiquidity(_tv.tLiquidity);
        _reflectFee(_rv.rFee, _tv.tFee);
        emit Transfer(sender, recipient, _tv.tTransferAmount);
        _transferDonation(sender, _rv.rDonationFee, _tv.tDonationFee);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 rLiquidity = tLiquidity.mul(_getRate());
        _rBalances[address(this)] = _rBalances[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)]) {
            _tBalances[address(this)] = _tBalances[address(this)].add(tLiquidity);
        }
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotalSupply = _rTotalSupply.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _transferDonation(address sender, uint256 rDonationFee, uint256 tDonationFee) private {
        if (_donationFee > 0) {
            _rBalances[donationWallet] = _rBalances[donationWallet].add(rDonationFee);
            emit Transfer(sender, donationWallet, tDonationFee);
            _tDonationTotal = _tDonationTotal.add(tDonationFee); 
        }
    }

    function transferBNBDonation(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
    event LockedWallet(address wallet, bool locked);
}
/**
 * End contract
 * 
 * Developed by @tadryanom
 */