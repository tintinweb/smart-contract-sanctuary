/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/***
*** Mammon ***
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@,,,,,,,,,,,,,,,,,,,,,,,,,(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@&,,,,,,,,,/,,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,,,,,,,,,,,,,,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,/,,,,,,,,,,,,,,,,
@,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,/,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,
@,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(,,,,/,,,,,,,,
@,,,,,,*,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,
@,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,,,,,,,,,
@,,,*,,,,@@@@@@@@@@@@@@@@@@@,,,,,@@@@@@@@@@@@@@@,,,,@@@@@@@@@@@@@@@@@@@@,,,,,,,,
@,,*,,,%@@@@@@@@@@@@@@@@@@@@,,,,,@@@@@@@@@@@@@@,,,,,#@@@@@@@@@@@@@@@@@@@@,,,,,,,
@,/,,,%@@@@@@@@@@@@@@@@@@@@@,,,,,,@@@@@@@@@@@@%,,,,,,@@@@@@@@@@@@@@@@@@@@@,,,,,,
@,,,,,@@@@@@@@@@@@@@@@@@@@@@,,,,,,,@@@@@@@@@@@,,,,,,,@@@@@@@@@@@@@@@@@@@@@@,,,,,
@,,,,@@@@@@@@@@@@@@@@@@@@@@*,,,,,,,#@@@@@@@@@,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@,,,*
@,,,,@@@@@@@@@@@@@@@@@@@@@@,,,,*,,,,@@@@@@@@,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@,,,,
@,,,@@@@@@@@@@@@@@@@@@@@@@@,,,,%&,,,,@@@@@@@,,,,@,,,,/@@@@@@@@@@@@@@@@@@@@@@,,,,
@,,,@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@*,,,
@,,,&@@@@@@@@@@@@@@@@@@@@@@,,,,@@@,,,,@@@@,,,,*@@(,,,,@@@@@@@@@@@@@@@@@@@@@@,,,,
@,,,,@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,
@,,,,@@@@@@@@@@@@@@@@@@@@@,,,,,@@@@/,,,,@,,,,@@@@@,,,,@@@@@@@@@@@@@@@@@@@@@@,,,*
@,,,,,@@@@@@@@@@@@@@@@@@@@,,,,,@@@@@,,,,,,,,&@@@@@,,,,(@@@@@@@@@@@@@@@@@@@@,,,,,
@,,,,,/@@@@@@@@@@@@@@@@@@@,,,,@@@@@@@,,,,,,,@@@@@@,,,,,@@@@@@@@@@@@@@@@@@@,,,,,,
@,,,,,,,@@@@@@@@@@@@@@@@@@,,,,@@@@@@@@,,,,,@@@@@@@,,,,,@@@@@@@@@@@@@@@@@@,,,,,,,
@,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,
@,,,,,,,,,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,
@,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,
@,,,,,,,,*,,,,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,
@,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(,,,,,,,,,,,,,,,,
@,,,,,,,,,,,,,*,,,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,,,,,,,(,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,,,,,,,,,,,*,,,,,,,,,,&@@@@@@@@@@@@@@@/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
@,,,,,,,,,,,,,,,,,,,,,,,,,,(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
***/
pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
interface IBEP20 {
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
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    //Locks the contract for owner for the amount of time provided
    function lockShortTime(uint256 time) public virtual onlyOwner {
        require(time < 7 * 24 *60 * 60 , "The contract locking time shall be less than 7 days");
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function lockLongTime(uint256 time) public virtual onlyOwner {
        require(time >= 7 * 24 *60 * 60 , "The contract locking time shall be greater than 7 days");
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}
// pragma solidity >=0.5.0;
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
// pragma solidity >=0.5.0;
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
// pragma solidity >=0.6.2;
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
// pragma solidity >=0.6.2;
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
contract MAMMON is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromAntiWhale;
    mapping (address => bool) private _isExcludedSendDraw;
    mapping (address => TState) public _addressState;
    address[] private _excluded;

    uint256 public _lastFomoAmount = 0;
    uint256 public _totalFomo = 0;
    uint256 public _fomoCount = 0;
    bool public _sendFomoEnable = true;

    address payable private _txgoldWallet;
    address payable private _marketingWallet;

    address public constant _fomoWallet = address(1);
    address public constant _burnPool = address(0x000000000000000000000000000000000000dEaD);

    uint256 private constant MAX256 = ~uint256(0);
    uint256 private constant MAX255 = (~uint256(0)) >> 1;

    string private constant _name = "MAMMON";
    string private constant _symbol = "MAMMON";
    uint8 private constant _decimals = 18;
    uint256 private _tTotal = 100000 * 10**6 * 10**_decimals;

    uint8 public constant MAX_DRAW_BASE = 100; // base is 100

    uint8 public _drawNumerator = 30; // probability 30 / 100, _drawNumerator < MAX_DRAW_BASE

    uint256 private _frontKeccak = 0; // front keccak256

    uint256 public _fixedTime = 86400; // 1 day 24 * 60 *60 s
    uint256 public _floatTime = 1; // _endTime = any % _floatTime + _fixedTime
    uint256 private _endTime = 0; // new start draw time

    uint256 public _fomoSpacedTime = 300; // 5 min 5 *60 s
    uint256 public _fomoEndTime = 0; // new start draw time

    uint256 private _randomNumber_0 = 0;
    uint256 private _randomNumber_1 = 0;

    // 10000 = 100%  1000 = 10%  100 = 1%  10 = 0.1%
    uint256 public _liquidityFee = 300;     // 3%
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _txgoldFee = 150;  // 1.5%
    uint256 private _previousTxgoldFee = _txgoldFee;

    uint256 public _marketingFee = 150;  // 1.5%
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 public _burnFee = 50;  // 0.5%
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _fomoFee = 50;  // 0.5%
    uint256 private _previousFomoFee = _fomoFee;

    uint256 public _gameRound = 1;
    uint256 public _daySellNumber = 10;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private inSwapAndLiquidity;
    bool public swapAndLiquidityEnabled = true;

    uint256 public _maxTxAmount = 100000 * 10**6 * 10**_decimals;
    uint256 public _numTokensSellToAddToLiquidity = 500 * 10**6 * 10**_decimals;
    // anti whale
    bool    public _isAntiWhaleEnabled = true;
    uint256 public _antiWhaleThreshold = 1000 * 10**6 * 10**_decimals;

    struct TData {
        uint256 tAmount;
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 tTxgold;
        uint256 tMarketing;
        uint256 tBurn;
        uint256 tFomo;
    }

    struct TState {
        uint256 round;
        uint256 sellNumber;
        uint256 luckyNumber; // luckyNumber [0, 99], luckyNumber < _drawNumerator = This is luck
        bool isLuck;
    }

    event SearchLuckResult(address account, uint256 luckyNumber, bool result, uint256 sellNum);
    event TriggerNextTimeRound(uint256 time, uint256 Round);
    event DrawFomo(uint256 amount, uint _fomoCount);
    event FomoEndTime(uint256 endTime);
    event FomoState(bool state);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquidityEnabledUpdated(bool enabled);
    event SwapAndLiquidity(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquidity = true;
        _;
        inSwapAndLiquidity = false;
    }

    constructor () {
        _tOwned[owner()] = _tTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _txgoldWallet = payable(owner());
        _marketingWallet = payable(owner());

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromAntiWhale[owner()] = true;
        _isExcludedFromAntiWhale[address(this)] = true;
        _isExcludedFromAntiWhale[address(uniswapV2Router)] = true;
        _isExcludedFromAntiWhale[uniswapV2Pair] = true;
        _isExcludedFromAntiWhale[address(1)] = true;

        _isExcludedSendDraw[owner()] = true;
        _isExcludedSendDraw[address(this)] = true;
        _isExcludedSendDraw[address(uniswapV2Router)] = true;
        _isExcludedSendDraw[address(uniswapV2Pair)] = true;
        _isExcludedSendDraw[_fomoWallet] = true;

        emit Transfer(address(0), owner(), _tTotal);
        emit FomoState(true);
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
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromAntiWhale(address account) public view returns(bool) {
        return _isExcludedFromAntiWhale[account];
    }
    function isExcludedSendDraw(address account) public view returns(bool) {
        return _isExcludedSendDraw[account];
    }
    function isLuckAddress(address account) public returns(bool) {
        if (block.timestamp > _endTime) {
            nextTime();
        }
        if (_isExcludedSendDraw[account]) {
            emit SearchLuckResult(account, 0, true, _daySellNumber);
            return true;
        }
         if (balanceOf(account) == 0) {
             emit SearchLuckResult(account, 100, false, 0);
             return false;
         }

        judgeRoundAndSetState(account);
        bool tmp = _addressState[account].isLuck;
        emit SearchLuckResult(account, _addressState[account].luckyNumber, tmp, _addressState[account].sellNumber);
        return tmp;
    }
    function setUniswapRouter(address r) external onlyOwner {
        require(r != address(0), "BEP20: setUniswapRouter is a zero address");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(r);
        uniswapV2Router = _uniswapV2Router;
    }

    function setUniswapPair(address p) external onlyOwner {
        require(p != address(0), "BEP20: setUniswapPair is a zero address");
        uniswapV2Pair = p;
    }
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTxgoldFeePercent(uint256 txgoldFee) external onlyOwner() {
        require((txgoldFee + _marketingFee + _burnFee + _fomoFee) < 10000, "BEP20: The sum should be less than 10000");
        _txgoldFee = txgoldFee;
    }
    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        require((_txgoldFee + marketingFee + _burnFee + _fomoFee) < 10000, "BEP20: The sum should be less than 10000");
        _marketingFee = marketingFee;
    }
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        require((_txgoldFee + _marketingFee + burnFee + _fomoFee) < 10000, "BEP20: The sum should be less than 10000");
        _burnFee = burnFee;
    }
    function setFomoFeePercent(uint256 fomoFee) external onlyOwner() {
        require((_txgoldFee + _marketingFee + _burnFee + fomoFee) < 10000, "BEP20: The sum should be less than 10000");
        _fomoFee = fomoFee;
    }
    function setFomoEnable(bool state) external onlyOwner() {
        _sendFomoEnable = state;
        emit FomoState(state);
    }

    function setNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity) external onlyOwner() {
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
    }
    function setTxgoldAddress(address payable txgold) public onlyOwner() {
        require(txgold != address(0), "BEP20: setTxgoldAddress is a zero address");

        _isExcludedFromFee[txgold] = true;
        _isExcludedFromAntiWhale[txgold] = true;
        _isExcludedSendDraw[txgold] = true;

        _txgoldWallet = txgold;
    }
    function setMarketingAddress(address payable marketing) public onlyOwner() {
        require(marketing != address(0), "BEP20: setMarketingAddress is a zero address");

        _isExcludedFromFee[marketing] = true;
        _isExcludedFromAntiWhale[marketing] = true;
        _isExcludedSendDraw[marketing] = true;

        _marketingWallet = marketing;
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    function setFomoSpacedTime(uint256 fomoSpacedTime) external onlyOwner() {
        _fomoSpacedTime = fomoSpacedTime;
        _fomoEndTime = block.timestamp + _fomoSpacedTime;
        emit FomoEndTime(_fomoEndTime);
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }
    function setSwapAndLiquidityEnabled(bool _enabled) public onlyOwner {
        swapAndLiquidityEnabled = _enabled;
        emit SwapAndLiquidityEnabledUpdated(_enabled);
    }
    function setAntiWhaleEnabled(bool e) external onlyOwner {
        _isAntiWhaleEnabled = e;
    }
    function setAntiWhaleThreshold(uint256 amount) external onlyOwner {
        _antiWhaleThreshold = amount;
    }
    function setExcludedFromAntiWhale(address account, bool e) external onlyOwner {
        _isExcludedFromAntiWhale[account] = e;
    }
    function setExcludedSendDraw(address account, bool e) external onlyOwner {
        _isExcludedSendDraw[account] = e;
    }
    function setDrawNumerator(uint8 drawNumerator) public onlyOwner {
        require(drawNumerator <= MAX_DRAW_BASE, "BEP20: drawNumerator should not be greater than MAX_DRAW_BASE");

        _drawNumerator = drawNumerator;
    }
    function setDrawTime(uint256 fixedTime, uint256 floatTime) public onlyOwner {
        _fixedTime = fixedTime;
        _floatTime = floatTime;
        nextTime();
    }
    function setDaySellNumber(uint256 daySellNumber) public onlyOwner {
        _daySellNumber = daySellNumber;
    }

    function rescueWBNB(uint256 amount) public onlyOwner {
        IBEP20 wbnb = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        if (wbnb.balanceOf(address(this)) > 0) {
            wbnb.transfer(_msgSender(), amount);
        }
    }

    function rescueUSDT(uint256 amount) public onlyOwner {
        IBEP20 usdt = IBEP20(0x55d398326f99059fF775485246999027B3197955);
        if (usdt.balanceOf(address(this)) > 0) {
            usdt.transfer(_msgSender(), amount);
        }
    }

    function rescueBUSD(uint256 amount) public onlyOwner {
        IBEP20 busd = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        if (busd.balanceOf(address(this)) > 0) {
            busd.transfer(_msgSender(), amount);
        }
    }

    /**  
     * @dev recovers any BNB stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     */
    function rescueBNB(uint256 amount) external onlyOwner {
        payable(_msgSender()).transfer(amount);
    }

    /**  
     * @dev recovers any tokens stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     * NOTE! Contract's Address and Owner's address MUST NOT
     */
    function recoverTokens(uint256 amount) public onlyOwner {
        _tOwned[address(this)] = _tOwned[address(this)].sub(amount);
        _tOwned[_msgSender()] = _tOwned[_msgSender()].add(amount);

        emit Transfer(address(this), _msgSender(), amount);
    }

    function _getValues(uint256 tAmount) private view returns (TData memory) {
        uint256 tLiquidity = calculateLiquidityFee(tAmount);

        uint256 tTxgold = calculateTxgoldFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tFomo = calculateFomoFee(tAmount);

        uint256 tTransferAmount = tAmount.sub(tLiquidity);
                tTransferAmount = tTransferAmount.sub(tTxgold);
                tTransferAmount = tTransferAmount.sub(tMarketing);
                tTransferAmount = tTransferAmount.sub(tBurn);
                tTransferAmount = tTransferAmount.sub(tFomo);
        return TData(tAmount, tTransferAmount, tLiquidity, tTxgold, tMarketing, tBurn, tFomo);
    }

     //to receive ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _takeTxgold(uint256 tTxgold, address from) private {
        if (tTxgold == 0)
            return;

        _tOwned[_txgoldWallet] = _tOwned[_txgoldWallet].add(tTxgold);
        emit Transfer(from, _txgoldWallet, tTxgold);
    }

    function _takeMarketing(uint256 tMarketing, address from) private {
        if (tMarketing == 0)
            return;

        _tOwned[_marketingWallet] = _tOwned[_marketingWallet].add(tMarketing);
        emit Transfer(from, _marketingWallet, tMarketing);
    }

    function _takeBurn(uint256 tBurn, address from) private {
        if (tBurn == 0)
            return;

        _tTotal = _tTotal.sub(tBurn);
        _tOwned[_burnPool] = _tOwned[_burnPool].add(tBurn);
        emit Transfer(from, _burnPool, tBurn);
    }

    function _takeFomo(uint256 tFomo, address from) private {
        if (tFomo == 0)
            return;

        _tOwned[_fomoWallet] = _tOwned[_fomoWallet].add(tFomo);
        emit Transfer(from, _fomoWallet, tFomo);
    }

    function _takeLiquidity(uint256 tLiquidity, address from) private {
        if (tLiquidity == 0)
            return;


        _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(from, address(this), tLiquidity);
    }

    function calculateTxgoldFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_txgoldFee).div(
            10**4
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**4
        );
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**4
        );
    }

    function calculateFomoFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_fomoFee).div(
            10**4
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**4
        );
    }

    function removeAllFee() private {
        if(_liquidityFee == 0 && _txgoldFee == 0 && _marketingFee == 0 && _burnFee == 0 && _fomoFee == 0) return;

        _previousTxgoldFee = _txgoldFee;
        _previousMarketingFee = _marketingFee;
        _previousBurnFee = _burnFee;
        _previousFomoFee = _fomoFee;
        _previousLiquidityFee = _liquidityFee;

        _txgoldFee = 0;
        _marketingFee = 0;
        _burnFee = 0;
        _fomoFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _txgoldFee = _previousTxgoldFee;
        _marketingFee = _previousMarketingFee;
        _burnFee = _previousBurnFee;
        _fomoFee = _previousFomoFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function judgeRoundAndSetState(address account) private {
        if (_gameRound != _addressState[account].round) {
            _addressState[account].round = _gameRound;
            uint256 luckyNumber = calculateLuck(account);
            bool luck = (luckyNumber < _drawNumerator);
            _addressState[account].luckyNumber = luckyNumber;
            _addressState[account].isLuck = luck;
            if (luck) {
                _addressState[account].sellNumber = _daySellNumber;
            } else {
                _addressState[account].sellNumber = 0;
            }
        }
    }

    function calculateLuck(address account) private returns(uint256) {
        uint160 tmp = uint160(account);
        _frontKeccak = uint256(keccak256(abi.encodePacked(_randomNumber_0, _randomNumber_1, uint64(tmp))));
        return _frontKeccak.mod(MAX_DRAW_BASE);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 fromBalance = balanceOf(from);
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        if ((from == _fomoWallet) && (amount == 0 || fromBalance == 0)) return;
        require(amount > 0, "BEP20: Transfer amount must be greater than zero");
        require(fromBalance >= amount, "BEP20: Token Balance is less than transfer amount");
        checkAddressState(from);
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "BEP20: Transfer amount exceeds the maxTxAmount.");

        /*
            anti whale: when buying, check if sender balance will be greater than 1% of total supply
            if greater, throw error
        */
        if (_isAntiWhaleEnabled && (!_isExcludedFromAntiWhale[to]) && (from != _fomoWallet)) {
            if ( from == address(uniswapV2Pair) || from == address(uniswapV2Router) ) {
                require(amount <= _antiWhaleThreshold, "BEP20: Anti whale: can't buy more than the specified threshold");
                require(balanceOf(to).add(amount) <= _antiWhaleThreshold, "BEP20: Anti whale: can't hold more than the specified threshold");
            }
        }
        if (from != _fomoWallet) {
            checkFomo(from, to);
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & Liquidity if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance && !inSwapAndLiquidity && from != uniswapV2Pair &&
            from != _fomoWallet && swapAndLiquidityEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquidity(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

        if (block.timestamp > _endTime) {
            nextTime();
        }
    }

    function checkAddressState(address from) private {
        if (_isExcludedSendDraw[from]) {
            return;
        }
        judgeRoundAndSetState(from);
        require(_addressState[from].isLuck, "BEP20: not lucky");
        require(_addressState[from].sellNumber > 0, "BEP20: no number of sales");
        _addressState[from].sellNumber = _addressState[from].sellNumber - 1;
    }

    function checkFomo(address from, address to) private {
        uint256 fomoBalance = balanceOf(_fomoWallet);
        if (from == uniswapV2Pair) {
            if (_sendFomoEnable) {
                if (block.timestamp > _fomoEndTime) {
                    _transfer(_fomoWallet, to, fomoBalance);
                    _lastFomoAmount = fomoBalance;
                    _totalFomo = _totalFomo.add(fomoBalance);
                    ++_fomoCount;
                    emit DrawFomo(fomoBalance, _fomoCount);
                }
                _fomoEndTime = block.timestamp + _fomoSpacedTime;
                emit FomoEndTime(_fomoEndTime);
            }
        }
    }

    function nextTime() private {
        startNextTime();
        return;
    }

    function startNextTime() private {
        // (X & MAX255) Prevent overflow
        _frontKeccak = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _frontKeccak)));
        _endTime = _frontKeccak.mod(_floatTime) + _fixedTime + block.timestamp;
        randomRandomNum();

        if (_gameRound == MAX256) {
            _gameRound = 1;
        } else {
            _gameRound++;
        }
        emit TriggerNextTimeRound(_endTime, _gameRound.sub(1));
    }

    function randomRandomNum() private {
        // (X & MAX255) Prevent overflow
        _randomNumber_0 = (block.difficulty & MAX255) + uint64(_frontKeccak.div(2**64));
        _randomNumber_1 = (block.timestamp & MAX255) + uint64(_frontKeccak);
    }

    function swapAndLiquidity(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+Liquidity is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquidity(half, newBalance, otherHalf);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        _transferStandard(sender, recipient, amount);

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (TData memory tData) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        if (recipient == _burnPool) {
            _takeBurn(tAmount, sender);
            return;
        } else {
            _tOwned[recipient] = _tOwned[recipient].add(tData.tTransferAmount);
        }
        _takeLiquidity(tData.tLiquidity, sender);
        _takeTxgold(tData.tTxgold, sender);
        _takeMarketing(tData.tMarketing, sender);
        _takeBurn(tData.tBurn, sender);
        _takeFomo(tData.tFomo, sender);
        emit Transfer(sender, recipient, tData.tTransferAmount);
    }
}