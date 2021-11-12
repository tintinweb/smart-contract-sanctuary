/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol



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

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol



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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol



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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: BDK03.sol



pragma solidity 0.8.0;






library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    //注：data.length == 0,主要针对的是usdt, 同时！该方法在波场不适用！！ 波场的的U 有返回data,但是一直是false!!
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

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

contract BDK03 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name = "Bull Demon King";
    string private _symbol = "BDK";
    uint8 private _decimals = 10;
    uint256 private _totalSupply = 0;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;//流动池地址
    
    mapping (uint256 => address) public poolUsers;//用户总数
    mapping (address => uint256) public _bOwned;//用户流动池代币余额
    mapping (address => uint256) public _tOwned;//用户流动池稳定币余额
    mapping (address => uint256) public lastLiquidityTime;//用户最后入流动池时间
    mapping (address => uint256) public bBuyLimit;//用户购买BOk数量限额
    mapping (address => uint256) public bUserSwap;//用户已兑换代币的总量
    mapping (address => uint256) public dayMine;//用户每日挖矿收益BDK
    mapping (address => uint256) public totalMine;//用户挖矿累计收益BDK
    mapping (address => uint256) public dayFund;//用户每日基金会分红收益TRX
    mapping (address => uint256) public totalFund;//用户累计基金会分红收益TRX
    mapping (address => uint256) public bDraw;//用户已提取BDK分红
    mapping (address => uint256) public bSurplus;//用户剩余未提取BDK分红
    mapping (address => uint256) public tDraw;//用户已提取的TRX分红
    mapping (address => uint256) public tSurplus;//用户剩余未提取的TRX分红
    
    mapping (address => bool) private transferEnable;//限制交易开关
    mapping (address => bool) private _isExcluded;//是否排除
    
    uint256 public totalPoolUser = 0;//质押用户总数
    uint256 public bMineMax = 60000000000* 10**10;//挖矿上限600亿
    uint256 public bMineTotal = 0;//已挖出BDk数量
    uint256 public bSwapMax = 30000000000* 10**10;//所有用户兑换代币的上限
    uint256 public bSwapTotal = 0;//所有用户已兑换代币的总量
    uint256 public bStopBurn = 1000000000* 10**10;//兑换额剩10亿时停止销毁
    uint256 public bBuyMax = 100000000* 10**10;//单个用户购买BDk数量限额1亿
    uint256 public bPoolTotal = 0;//所有用户挖矿质押BDK数量
    uint256 public tPoolTotal = 0;//所有用户挖矿质押trx数量
    uint256 public bFundTotal = 0;//基金会收取的BDK总数量
    uint256 public tFundTotal = 0;//基金会收取TRX总数量
    uint256 public tFundOld = 0;//基金会今日结算时收取TRX数量
    uint256 public lastSettlementTime = 0;//上次结算时间
    // uint256 public _begin = 8;//结算开始时间,小时
    // uint256 public _duration = 30;//结算持续时长,分钟
    uint256 public bTotalBurn = 0;//代币销毁总量

    uint256 private _bTotal = 100000000000 * 10**10;//代币发行量1000亿
    
    uint256 public _taxFee = 10;//用户转账手续费
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 10;//流动池手续费
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _swapFee = 10;//用户转账手续费
    uint256 private _previousSwapFee = _swapFee;
    
    // bool inSwapAndLiquify;
    bool public tradeEnabled = true;
    
    event TradeEnabled(bool enabled);//兑换增加流动性允许更新
    event SwapAndLiquify(
        uint256 tokensSwapped,//兑换的代币数量
        uint256 ethReceived,//收到的ETH
        uint256 tokensIntoLiqudity////代币加流动池的数量
    );
    
    //流动池增删开关
    /*modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }*/
    
    constructor () {
        _mint(owner(), 30000000000 * (10**10));
        _mint(address(this), 70000000000 * (10**10));
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x15d1cfA4e71f9B8c7C1BFAeDE30fDE4cAe7Cd20C);//PancakeRouter的地址0x15d1cfA4e71f9B8c7C1BFAeDE30fDE4cAe7Cd20C
        
        //使用代币地址创建的流动池地址
        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());//_uniswapV2Router.WETH()为ETH地址

        //设置其余的合约变量
        uniswapV2Router = _uniswapV2Router;
        
        //合约与创建者排除扣费
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;
        transferEnable[owner()] = true;
        transferEnable[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _bTotal);
    }
    
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public immutable tokenB = address(this);
    address public immutable tokenT = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public  ownerto;
    address public  ownermsg = msg.sender;
    address public  owner_msg = _msgSender();
    
    function pair() public onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());//_uniswapV2Router.WETH()为ETH地址
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
       return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        // ownerto = recipient;
        // ownermsg = msg.sender;
        // owner_msg = _msgSender();
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        // _transfer(sender, recipient, amount);

        // uint256 currentAllowance = _allowances[sender][_msgSender()];
        // require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        // unchecked {
        //     _approve(sender, _msgSender(), currentAllowance - amount);
        // }

        // return true;
        
        _approve(sender, recipient, amount);
        _transfer(sender, recipient, amount);
        _approve(sender, recipient, _allowances[sender][recipient].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
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
    
    //在交换时从UNISWAPv2接收ETH
    receive() external payable {}
    
    function ownerWithdrew(uint256 amount) public  onlyOwner{
        
        amount = amount * 10 **10;
        
        uint256 dexBalance = balanceOf(address(this));
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        
        transfer(msg.sender, amount);
    }
    
    function ownerDeposit(uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **10;

        uint256 dexBalance = balanceOf(msg.sender);
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Dont hava enough EMSC");
        
        transferFrom(msg.sender, address(this), amount);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        //交易开关
        // autoSetTradeEnabled();
        // require(tradeEnabled,"now is limit time");
        
        // if(_isExcluded[sender]){
        if(_isExcluded[sender] || _isExcluded[recipient]){
            
            // totalPoolUser ++;
            
            // poolUsers[totalPoolUser] = recipient;
            
            // bUserSwap[recipient] += amount;
            
            _tokenTransfer(sender, recipient, amount);
            
        }else{
            
            if(sender == uniswapV2Pair && lastLiquidityTime[recipient] == 0){
                
                totalPoolUser ++;
            
                poolUsers[totalPoolUser] = recipient;
                
                bUserSwap[recipient] += amount;
                
                //检查代币购买限额
                // require(_notExceedLimit(recipient),"purchase limit exceeded");
                
                _tokenTransfer(sender, recipient, amount);
                
                // split the contract balance into halves
                uint256 half = amount.div(2);
                uint256 otherHalf = amount.sub(half);
        
                // 当前ETH余额。
                uint256 initialBalance = IERC20(tokenT).balanceOf(address(recipient));//兑换前ETH余额
                
                //兑换代币为ETH,发送
                _swapTokenForEth(recipient, otherHalf); //触发交换+流动性时进行仇恨交换
        
                //合约ETH余额变化
                uint256 newBalance = IERC20(tokenT).balanceOf(address(recipient)).sub(initialBalance);
                
                _addLiquidity(recipient, half, newBalance);
                
                lastLiquidityTime[recipient] = block.timestamp;
                
                bSwapTotal += amount;
                
            }else{
            
                /*if(sender == uniswapV2Pair){
                    require(transferEnable[recipient],"recipient is disable"); 
                }else{
                    require(transferEnable[sender],"transfer is disable"); 
                }*/
                
                _tokenTransfer(sender, recipient, amount);
                
                // _beforeTokenTransfer(sender, recipient, amount);
                // _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
                // _balances[recipient] = _balances[recipient].add(amount);
                
            }
            
        }
        
        emit Transfer(sender, recipient, amount);
        
    }
    
    
    function _tokenTransfer(
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
    
    //检查代币购买限额
    function _notExceedLimit(address user) internal virtual returns (bool){
            
        if(_isExcluded[user]){
            return true;
        }else{
            
            if(bBuyLimit[user] > _bBuyMax()){
                bBuyLimit[user] = _bBuyMax();
            }
            
            if(bUserSwap[user] <= bBuyLimit[user]){
                return true;
            } else {
                return false;
            }
        }
        
    }
    
    //用户转账,非排除用户收取10%手续费
    function userTransfer(address recipient,uint256 amountB) public {
        
        amountB = amountB * 10 **18;
        
        if(transferEnable[msg.sender]){
            
            if(_isExcluded[msg.sender]){
                _tokenTransfer(msg.sender,recipient,amountB);
            }
        
            if(!_isExcluded[msg.sender]){
                _tokenTransfer(msg.sender,address(this),amountB.mul(_taxFee).div(100));
                bFundTotal += amountB.mul(_taxFee).div(100);
                _tokenTransfer(msg.sender,recipient,amountB.mul(100-_taxFee).div(100));
            }
            
        }else{
            
            transferEnable[msg.sender] = true;
            
            if(_isExcluded[msg.sender]){
                _tokenTransfer(msg.sender,recipient,amountB);
            }
        
            if(!_isExcluded[msg.sender]){
                _tokenTransfer(msg.sender,address(this),amountB.mul(_taxFee).div(100));
                bFundTotal += amountB.mul(_taxFee).div(100);
                _tokenTransfer(msg.sender,recipient,amountB.mul(100-_taxFee).div(100));
            }
            
            transferEnable[msg.sender] = false;
            
        }
        
    }
    
    //trx兑换代币并加入的流动池
    function swapAndLiquify(uint256 amountT) public {
        
        _swapAndLiquify(msg.sender, amountT);
        
    }
    
    //trx兑换代币并加入的流动池
    function _swapAndLiquify(address user,uint256 amountT) internal virtual {
        
        require(amountT > 0,"swap number is zore");
        
        // amountT = amountT * 10 **18;
        
        //判断是否为流动性提供者
        if(!_isExcluded[user] && lastLiquidityTime[user] == 0){
            
            totalPoolUser ++;
            
            poolUsers[totalPoolUser] = user;
            
        }
        
        lastLiquidityTime[user] = block.timestamp;
        
        // split the contract balance into halves
        uint256 half = amountT.div(2);
        uint256 otherHalf = amountT.sub(half);

        // 当前用户token余额。
        uint256 initialBalance = IERC20(tokenT).balanceOf(address(user));//兑换前ETH余额

        //兑换ETH为代币,发送
        swapEthForToken(half); //触发交换+流动性时进行交换

        //用户token余额变化,流动池手续费0.3%
        uint256 newBalance = IERC20(tokenT).balanceOf(address(user)).sub(initialBalance);
        
        bUserSwap[user] += newBalance;
        
        //检查代币购买限额
        require(_notExceedLimit(user),"purchase limit exceeded");
        
        bSwapTotal += newBalance;
        
        if(_isExcluded[user]){
            
            // add liquidity to uniswap
            _addLiquidity(user, newBalance, otherHalf);//排除账户100%入资金池增加流动性
            
        }else{
            
            // add liquidity to uniswap,90%
            uint256 bAmount = newBalance.mul(100 - _liquidityFee).div(100);
            uint256 tAmount = otherHalf.mul(100 - _liquidityFee).div(100);
            
            if(transferEnable[user]){
                
                if(bSwapMax - bSwapTotal > bStopBurn){//发行总量剩余10亿枚时停止销毁
                    transfer(deadWallet, newBalance.mul(_liquidityFee).div(100));
                }
                
                //基金会收取手续费10%TRX
                TransferHelper.safeTransferFrom(tokenT,user,address(this),otherHalf.mul(_liquidityFee).div(100));//10%TRX手续费转账合约
                tFundTotal += otherHalf.mul(_liquidityFee).div(100);
                
                // add liquidity to uniswap
                _addLiquidity(user, bAmount, tAmount);//排除账户入资金池增加流动性
            
            }else {
                
                transferEnable[user] = true;
                
                //发行总量剩余10亿枚时停止销毁
                if(bSwapMax - bSwapTotal >= bStopBurn){
                    transfer(deadWallet, newBalance.mul(_liquidityFee).div(100));
                }
                
                //基金会收取手续费10%TRX
                TransferHelper.safeTransferFrom(tokenT,user,address(this),otherHalf.mul(_liquidityFee).div(100));
                tFundTotal += otherHalf.mul(_liquidityFee).div(100);
                
                // add liquidity to uniswap
                _addLiquidity(user, bAmount, tAmount);
                
                transferEnable[user] = false;
            }
            
        }
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
        
    }

    // 代币兑换为ETH
    function swapTokenForEth(uint256 amountB) public {
        
        _swapTokenForEth(msg.sender, amountB);
        
    }
    
    // 代币兑换为ETH
    function _swapTokenForEth(address user, uint256 amountB) internal virtual {
        require(amountB > 0,"swap number is zore");
        require(amountB <= _bTotal, "Amount must be less than total");
        
        amountB = amountB * 10 **10;
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);//代币地址
        path[1] = uniswapV2Router.WETH();//uniswapV2Router.WETH()为ETH地址
        
        _approve(user, address(uniswapV2Router), amountB);
        
        if(_isExcluded[user]){
            
                // transfer(tokenB, amountB);
                
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountB,
                    0, // accept any amount of ETH
                    path,//两种兑换币地址
                    user,//接收方地址
                    block.timestamp
                );
            
        }else{
            IERC20(tokenT).balanceOf(address(user));
            // 当前ETH余额。
            //uint256 initialBalance = address(user).balance;
            uint256 initialBalance = IERC20(tokenT).balanceOf(address(user));
            
            if(transferEnable[user]){
                
                // transfer(tokenB, amountB);
            
                // 输入精确token换取输出eth,
                uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                        amountB,
                        0, // accept any amount of ETH
                        path,//两种兑换币地址
                        user,//接收方地址
                        block.timestamp
                    );
                
            }else{
                
                transferEnable[user] = true;
                
                // transfer(tokenB, amountB);
                
                // 输入精确token换取输出eth,
                uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountB.mul(100-_taxFee).div(100),
                    0, // accept any amount of ETH
                    path,//两种兑换币地址
                    user,//接收方地址
                    block.timestamp
                );
                
                transferEnable[user] = false;
            }
            
            //合约ETH余额变化
            uint256 newBalance = IERC20(tokenT).balanceOf(address(user)).sub(initialBalance);
            
            TransferHelper.safeTransferFrom(tokenT,user,address(this),newBalance.mul(_swapFee).div(100));
            
            tFundTotal += newBalance;
            
        }
        
    }
    
     // 代币兑换为ETH
    function swapEthForToken(uint256 amountT) public {
        
        _swapEthForToken(msg.sender, amountT);
        
    }
    
    // ETH兑换为代币
    function _swapEthForToken(address user, uint256 amountT) internal virtual {
        
        // amountT = amountT * 10 **18;
        
        require(amountT > 0,"swap number is zore");
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);//代币地址
        path[1] = uniswapV2Router.WETH();//uniswapV2Router.WETH()为ETH地址

        _approve(user, address(uniswapV2Router), amountT);
        
        if(transferEnable[user]){
            
            // 输入精确eth换取输出token,
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
                amountT,
                path,//两种兑换币地址
                user,//接收方地址
                block.timestamp
            );
            
        }else {
            
            transferEnable[user] = true;
            
            // 输入精确eth换取输出token,
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
                amountT,
                path,//两种兑换币地址
                user,//接收方地址
                block.timestamp
            );
            
            transferEnable[user] = false;
        }
        
    }
    
    // 增加流动池流动性
    function addLiquidity(uint256 amountB, uint256 amountT) public {
        
        require(amountB > 0 && amountT > 0,"swap number is zore");
        
        amountB = amountB * 10 **10;
        
        //判断是否为流动性提供者
        if(!_isExcluded[msg.sender] && lastLiquidityTime[msg.sender] == 0){
            
            totalPoolUser ++;
            
            poolUsers[totalPoolUser] = msg.sender;
            
        }
        
        _addLiquidity(msg.sender, amountB, amountT);
        
        lastLiquidityTime[msg.sender] = block.timestamp;
        
    }
    
    // 增加流动池流动性
    function _addLiquidity(address user, uint256 amountB, uint256 amountT) internal virtual {
        
        // approve token transfer to cover all possible scenarios
        _approve(user, address(uniswapV2Router), amountB);
        
        if(transferEnable[user]){
            
            transfer(tokenB, amountB);
            
            // add the liquidity
            uniswapV2Router.addLiquidity(
                tokenB,
                tokenT,
                amountB,
                amountT,
                0,
                0,
                user,
                block.timestamp
            );
            
        }else {
            
            transferEnable[user] = true;
            
            transfer(tokenB, amountB);
            
            // add the liquidity
            uniswapV2Router.addLiquidity(
                tokenB,
                tokenT,
                amountB,
                amountT,
                0,
                0,
                user,
                block.timestamp
            );
            
            /*// add the liquidity
            uniswapV2Router.addLiquidityETH{value: ethAmount}(//添加流动性，其中一个币种是eth
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable //eth最小输入量；  对应的Desired在msg.value
                user,//发送方地址
                block.timestamp
            );*/
            
            transferEnable[user] = false;
            
        }
        
        _bOwned[user] += amountB;
        _tOwned[user] += amountT;
        bPoolTotal += amountB;
        tPoolTotal += amountT;
        
    }
    
    //删除流动性,Liquidity代币数量
    function _takeLiquidity(address user, uint256 liquidity) internal virtual {
        
        require(liquidity > 0,"take liquidity number is zore");
        
        // autoSetTradeEnabled();
        // require(!tradeEnabled,"now is limit time");//交易开关
        require(lastLiquidityTime[user] > 0 || _bOwned[user] > 0 || _tOwned[user] > 0, "ERC20: approve from the zero address"); //用户已加入流动池,且有流动性
        
        uint256 amountB;
        uint256 amountT;
        
        if(_isExcluded[user]){
            (amountB, amountT) =  uniswapV2Router.removeLiquidity(
                    tokenB,
                    tokenT,
                    liquidity,
                    0,
                    0,
                    user,
                    block.timestamp
                );
        }else{
            
            if(transferEnable[user]){
            
                (amountB, amountT) =  uniswapV2Router.removeLiquidity(
                        tokenB,
                        tokenT,
                        liquidity,
                        0,
                        0,
                        user,
                        block.timestamp
                    );
             if(lastLiquidityTime[user] + 60 days > block.timestamp){
                
                //基金会收取手续费
                transfer(address(this), amountB.mul(50).div(100));
                TransferHelper.safeTransferFrom(tokenT, user, address(this), amountT.mul(50).div(100));
                
                bFundTotal += amountB.mul(50).div(100);
                tFundTotal += amountT.mul(50).div(100);
                
            }   
            
            } else {
                
                transferEnable[user] = true;
                
                (amountB, amountT) =  uniswapV2Router.removeLiquidity(
                        tokenB,
                        tokenT,
                        liquidity,
                        0,
                        0,
                        user,
                        block.timestamp
                    );
                
                if(lastLiquidityTime[user] + 60 days > block.timestamp){
                    
                    //基金会收取手续费
                    transfer(address(this), amountB.mul(50).div(100));
                    TransferHelper.safeTransferFrom(tokenT, user, address(this), amountT.mul(50).div(100));
                    
                    bFundTotal += amountB.mul(50).div(100);
                    tFundTotal += amountT.mul(50).div(100);
                    
                    
                }
                transferEnable[user] = false;
            }
            
            _bOwned[user] = _bOwned[user].sub(amountB);
            _tOwned[user] = _tOwned[user].sub(amountB);
            bPoolTotal = bPoolTotal.sub(amountB);
            tPoolTotal = tPoolTotal.sub(amountB);
        }
       
    }
    
    //挖矿 用户分红
    function mining() public onlyOwner {
        
        require((block.timestamp/24 hours)-(lastSettlementTime/24 hours) >= 1,"");//上次结算时间距今大于一天
        
        //非交易时段结算
        // autoSetTradeEnabled();
        // require(!tradeEnabled,"now is limit time");
        
        require(bMineTotal < bMineMax,"up to _bMineMax,stop mining");
        
        //当日挖矿BDK数量
        uint256 bNum = bPoolTotal.mul(_mineRate().div(100));
        
        //所有已挖出BDK数量
        bMineTotal += bNum;
        
        if(bMineTotal > bMineMax){//当所有已挖出BDK数量大于600亿,
            bNum = bNum - (bMineTotal - bMineMax);//扣除超额部分 
            bMineTotal = bMineMax;
            
            //最后100亿销毁
            transferFrom(address(this), deadWallet, 10000000000* 10**10);
        }
        
        //10%BDk手续费转基金会
        bFundTotal += bNum.mul(10).div(100);
        
        //剩余90%BDK
        bNum = bNum.mul(90).div(100);
        
        //基金会今日收取TRX数量
        uint256 _tFund = tFundTotal - tFundOld;
        
        //基金会今日收取TRX数量的30%分给用户
        uint256 tFundUser = _tFund.mul(30).div(100);
        
        //更新用户数据
        for(uint256 i = 1; i < totalPoolUser; i++){
            
            address user = poolUsers[i];
            
            //用户每日挖矿收益BDK
            dayMine[user] = bNum.mul(_bOwned[user]).div(bPoolTotal);
            
            //用户累计挖矿收益BDK
            totalMine[user] += dayMine[user]; 
            
            //用户每日基金会分红收益TRX
            dayFund[user] = tFundUser.mul(_bOwned[user]).div(bPoolTotal);
            
            //用户累计基金会分红收益TRX
            totalFund[user] += dayFund[user];
            
            //用户剩余未提取BDK,TRX分红
            bSurplus[user] += dayMine[user];
            tSurplus[user] += dayFund[user]; 
        }
        
        //上次结算时间
        lastSettlementTime = block.timestamp;
        
        //记录昨日分红时基金会TRX数量
        tFundOld = tFundTotal;
    }
    
    //用户提取BDK分红
    function drawB(uint256 bNum) public {
        
        //检查交易开关
        // autoSetTradeEnabled();
        // require(tradeEnabled,"now is limit time");
        
        //检查用户分红余额
        require(bSurplus[msg.sender] > 0 || bSurplus[msg.sender] > bNum,"");
        
        //用户已提取的BDK分红
        bDraw[msg.sender] += bNum;
        
        //用户未提取的BDK分红
        bSurplus[msg.sender] = bSurplus[msg.sender].sub(bNum);
        
        if(transferEnable[msg.sender]){
            
            // transferFrom(address(this), msg.sender, bNum);
            _tokenTransfer(address(this), msg.sender, bNum);
            
        }else {
            
            transferEnable[msg.sender] = true;
            
            // transferFrom(address(this), msg.sender, bNum);
            _tokenTransfer(address(this), msg.sender, bNum);
            
            transferEnable[msg.sender] = false;
            
        }
        
    }
    
    //用户提取TRX分红
    function drawT(uint256 tNum) public {
        
        //检查交易开关
        // autoSetTradeEnabled();
        // require(tradeEnabled,"now is limit time");
        
        //检查用户分红余额
        require(tSurplus[msg.sender] > 0 || tSurplus[msg.sender] > tNum,"");
        
        //用户已提取的TRX分红
        tDraw[msg.sender] += tNum;
        
        //用户未提取的TRX分红
        tSurplus[msg.sender] = tSurplus[msg.sender].sub(tNum);
        
        //发送给用户
        TransferHelper.safeTransferFrom(tokenB, address(this), msg.sender, tNum);
    }
    
    //账户排除扣费
    function isExcluded(address account) external onlyOwner returns (bool) {
        _isExcluded[account] = true;
        return _isExcluded[account];
    }
    
    //账户扣费
    function notExcluded(address account) external onlyOwner returns (bool) {
        _isExcluded[account] = false;
        return _isExcluded[account];
    }
    
    //设置转账手续费费率
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee >= 0 && taxFee < 100,"");
        _taxFee = taxFee;
    }
    
    //设置流动池税费费率
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee >= 0 && liquidityFee < 100,"");
        _liquidityFee = liquidityFee;
    }
    
    //交易开关手动设置
    function setTradeEnabled(bool _enabled) external onlyOwner {
        tradeEnabled = _enabled;
        emit TradeEnabled(_enabled);
    }
    
    //交易开关自动设置 Settlement time
    function autoSetTradeEnabled() public onlyOwner {
        // if((block.timestamp % 24 hours) > (_begin hours) && (block.timestamp % 24 hours) < ((_begin hours).add(_duration minutes)) ){
        if((block.timestamp % 24 hours) > (20 hours) && (block.timestamp % 24 hours) < (21 hours)){
            tradeEnabled = false;
        }else{
            tradeEnabled = true;
        }
        
        emit TradeEnabled(tradeEnabled);
    }
    
    //移除税费
    function removeAllFee() public onlyOwner {
        if(_taxFee == 0 && _liquidityFee == 0 && _swapFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousSwapFee = _swapFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _swapFee = 0;
        
    }
    
    //恢复税费
    function restoreAllFee() public onlyOwner {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _swapFee = _previousSwapFee;
    }
    
    //所有用户BDK购买限额
    function _bBuyMax() internal virtual returns (uint256) {
        
        if(0 <= bMineTotal && bMineTotal <= 500000000){
            bBuyMax = 100000000;
        }
        if(500000000 < bMineTotal && bMineTotal <= 2000000000){
            bBuyMax = 80000000;
        }
        if(2000000000 < bMineTotal && bMineTotal <= 10000000000){
            bBuyMax = 64000000;
        }
        if(10000000000 < bMineTotal && bMineTotal <= 20000000000){
            bBuyMax = 51000000;
        }
        if(20000000000 < bMineTotal && bMineTotal <= 30000000000){
            bBuyMax = 41000000;
        }
        if(30000000000 < bMineTotal && bMineTotal <= 40000000000){
            bBuyMax = 33000000;
        }
        if(40000000000 < bMineTotal && bMineTotal <= 50000000000){
            bBuyMax = 26000000;
        }
        if(50000000000 < bMineTotal && bMineTotal <= 60000000000){
            bBuyMax = 21000000;
        }
        // if(60000000000 < mineBDK && mineBDK <= 70000000000){
        //     mineRate = 17;
        // }
        return bBuyMax;
    }
    
    //挖矿产率,20%递减
    function _mineRate() internal virtual returns (uint256 mineRate){
        
        if(0 <= bMineTotal && bMineTotal <= 500000000){
            mineRate = 100;
        }
        if(500000000 < bMineTotal && bMineTotal <= 2000000000){
            mineRate = 80;
        }
        if(2000000000 < bMineTotal && bMineTotal <= 10000000000){
            mineRate = 64;
        }
        if(10000000000 < bMineTotal && bMineTotal <= 20000000000){
            mineRate = 51;
        }
        if(20000000000 < bMineTotal && bMineTotal <= 30000000000){
            mineRate = 41;
        }
        if(30000000000 < bMineTotal && bMineTotal <= 40000000000){
            mineRate = 33;
        }
        if(40000000000 < bMineTotal && bMineTotal <= 50000000000){
            mineRate = 26;
        }
        if(50000000000 < bMineTotal && bMineTotal <= 60000000000){
            mineRate = 21;
        }
        if(60000000000 < bMineTotal && bMineTotal <= 70000000000){
            mineRate = 0;
        }
        return mineRate;
    }
   
}