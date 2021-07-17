/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: CC BY 3.0 US

/**
 * Creative Commons Attribution License for ADMIRE Content Coin, https://admire.dev/
 * Attribution license because this "highly secure" token can be easily modified to
 * do exceptionally evil things, such as capture and divert individual address' balances.
 * If you see a deployed contract with the same amount of MultiSig options, it's likely
 * a copy and you need to review the modifiers in the final token contract. Make sure they're
 * only reverting, not redirecting. If the latter, it's an "evil contract", BEWARE!
 * 
 * ADMIRE's core team is welcoming, positive and inclusive: If you clone our token or
 * code, do drop in on social media and say "hello"! Best of luck!
 */
 
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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


// AND PDX-License-Identifier: MIT

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

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
    event Charity(address indexed sender, uint amount0, uint amount1, address indexed to);
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
    function charity(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }


    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}




contract MultiSig is Context {
    using Address for address;

    // @dev Include for BEP20_Pausable.sol, just seprating out some logic, which will be inherited
    

    // @dev Initializes the contract with MultiSig _mint_wrappers_stopped state control off.
    // @dev Initializes the contract with MultiSig _change_operator_stopped state control off.
    // @dev Initializes the contract with MultiSig _rate_change_stopped state control off.
    // @dev Initializes the contract with MultiSig _blacklist_stopped state control off.
    // @dev Initializes the contract with MultiSig _antiwhale_stopped state control off.
    // @dev Initializes the contract with MultiSig _mint_stopped state control off.
    // @dev Initializes the contract with MultiSig _approve__addresses_stopped state control off.
    // @dev Initializes the contract with MultiSig _nocontracts_stopped state control off.
    constructor () public {
        _mint_wrappers_stopped = false;
        _change_operator_stopped = false;
        _rate_change_stopped = false;
        _blacklist_stopped = false;
        _antiwhale_stopped = false;
        _mint_hardlock_stopped = false;
        _approve_spendable_address_stopped = false;
        _nocontracts_stopped = false;
     }

    // @dev **************** Lock the Mint_Wrappers   ***********************
    // @dev Emitted when Minting is paused by Operator.
    event Mint_Wrappers_Stopped(address account);

    // @dev Emitted when the Minting is allowed by Operator.
    event Started_Mint_Wrappers(address account);

    bool internal _mint_wrappers_stopped;

    // @dev Returns true if the contract is _mint_wrappers_stopped, and false otherwise.
    function mint_wrappers_stopped() public view returns (bool) {
        return _mint_wrappers_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _mint_wrappers_stopped.
    modifier whenMintWrappersOn() {
        require(!_mint_wrappers_stopped, "MultiSig:: Mint Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _mint_wrappers_stopped.
    modifier whenMintWrappersOff() {
        require(_mint_wrappers_stopped, "Multisig::Error:: Declined By _mint_wrappers");
        _;
    }

    // @dev Triggers stopped state. Call in function mint:
    // function mint(address _to, uint256 _amount) public onlyOwner whenMintWrappersOn {
    function _stop_mint_wrappers() internal virtual whenMintWrappersOn {
        _mint_wrappers_stopped = true;
        emit Mint_Wrappers_Stopped(_msgSender());
    }


    // @dev Returns to normal state.
    function _start_mint_wrappers() internal virtual whenMintWrappersOff {
        _mint_wrappers_stopped = false;
        //emit Started_Mint_Wrappers(_msgSender());
    }

    
    // @dev **************** Lock the Operator   ***********************
    // @dev Emitted when Changing The Operator is paused by Operator.
    event Change_Operator_Stopped(address account);

    // @dev Emitted when the Changing The Operator is allowed by Operator.
    event Started_Change_Operator(address account);

    bool private _change_operator_stopped;

    // @dev Returns true if the contract is _change_operator_stopped, and false otherwise.
    function change_operator_stopped() public view returns (bool) {
        return _change_operator_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _change_operator_stopped.
    modifier whenChangeOperatorOn() {
        require(!_change_operator_stopped, "MultiSig: Changing Operator Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _change_operator_stopped.
    modifier whenChangeOperatorOff() {
        require(_change_operator_stopped, "Multisig: Error: Changing Operator To Permission Revoked");
        _;
    }

    // @dev Triggers stopped state. Call in function D3_transferOperator:
    // function D3_transferOperator(address newOperator) public onlyOwner whenChangeOperatorOn {
    function _stop_change_operator() internal virtual whenChangeOperatorOn {
        _change_operator_stopped = true;
        emit Change_Operator_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_change_operator() internal virtual whenChangeOperatorOff {
        _change_operator_stopped = false;
        emit Started_Change_Operator(_msgSender());
    }
    
    // @dev **************** Lock the Rates   ***********************
    // @dev Emitted when RateChanging is paused by Operator.
    event Rate_Change_Stopped(address account);

    // @dev Emitted when the RateChanging is allowed by Operator.
    event Started_Rate_Change(address account);

    bool private _rate_change_stopped;

    // @dev Returns true if the contract is _rate_change_stopped, and false otherwise.
    function rate_change_stopped() public view returns (bool) {
        return _rate_change_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _rate_change_stopped.
    modifier whenRateChangeOn() {
        require(!_rate_change_stopped, "MultiSig: RateChange Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _rate_change_stopped.
    modifier whenRateChangeOff() {
        require(_rate_change_stopped, "ADMIRE::Multisig::Error: RateChange Permission Revoked");
        _;
    }

    // @dev Triggers stopped state. Call in function updateRate:
    //function updateRate(uint16 _charityRate) public onlypOwner whenRateChangeOn { 
    function _stop_rate_change() internal virtual whenRateChangeOn {
        _rate_change_stopped = true;
        emit Rate_Change_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_rate_change() internal virtual whenRateChangeOff {
        _rate_change_stopped = false; 
        emit Started_Rate_Change(_msgSender());
    }

    
    // @dev **************** Lock the Blacklist   ***********************
        // @dev Emitted when Minting is paused by Operator.
    event Blacklist_Stopped(address account);

    // @dev Emitted when the Minting is allowed by Operator.
    event Started_Blacklist(address account);

    bool private _blacklist_stopped;

    // @dev Returns true if the contract is _blacklist_stopped, and false otherwise.
    function blacklist_stopped() public view returns (bool) {
        return _blacklist_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _blacklist_stopped.
    modifier whenBlacklistOn() {
        require(!_blacklist_stopped, "MultiSig: Mint To Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _blacklist_stopped.
    modifier whenBlacklistOff() {
        require(_blacklist_stopped, "Multisig: Error: Mint To Permission Revoked");
        _;
    }

    // @dev Triggers stopped state. Call in function blacklistUpdate:
    // function blacklistUpdate(address user, bool value) public virtual onlyOwner whenBlacklistOn {
    function _stop_blacklist() internal virtual whenBlacklistOn {
        _blacklist_stopped = true;
        emit Blacklist_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_blacklist() internal virtual whenBlacklistOff {
        _blacklist_stopped = false;
        emit Started_Blacklist(_msgSender());
    }
    
    // @dev **************** Lock the AntiWhale   ***********************
    // @dev Emitted when Minting is paused by Operator.
    event AntiWhale_Stopped(address account);

    // @dev Emitted when the Minting is allowed by Operator.
    event Started_AntiWhale(address account);

    bool private _antiwhale_stopped;

    // @dev Returns true if the contract is _antiwhale_stopped, and false otherwise.
    function antiwhale_stopped() public view returns (bool) {
        return _antiwhale_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _antiwhale_stopped.
    modifier whenAntiWhaleOn() {
        require(!_antiwhale_stopped, "MultiSig: Mint To Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _antiwhale_stopped.
    modifier whenAntiWhaleOff() {
        require(_antiwhale_stopped, "Multisig: Error: Mint To Permission Revoked");
        _;
    }

    // @dev Triggers stopped state. Call in function antiwhaleUpdate:
    // function G5_setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOwner whenAntiWhaleOn {
    function _stop_antiwhale() internal virtual whenAntiWhaleOn {
        _antiwhale_stopped = true;
        emit AntiWhale_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_antiwhale() internal virtual whenAntiWhaleOff {
        _antiwhale_stopped = false;
        emit Started_AntiWhale(_msgSender());
    }
    

    /* @dev **************** Lock the MintHardlock_To   ***********************
     * This breaks almost everything, only for serious emergencies!
     */
    // @dev Emitted when MintHardlocking is paused by Operator.
    event MintHardlock_Stopped(address account);

    // @dev Emitted when the MintHardlocking is allowed by Operator.
    event Started_MintHardlock(address account);

    bool private _mint_hardlock_stopped;

    // @dev Returns true if the contract is _mint_hardlock_stopped, and false otherwise.
    function mint_stopped() public view returns (bool) {
        return _mint_hardlock_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _mint_hardlock_stopped.
    modifier whenMintHardlockOn() {
        require(!_mint_hardlock_stopped, "MultiSig: MintHardlock Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _mint_hardlock_stopped.
    modifier whenMintHardlockOff() {
        require(_mint_hardlock_stopped, "ADMIRE::MultiSig::Error: MintHardlock Enabled");
        _;
    }

    // @dev Triggers stopped state. Call in function mintUpdate:
    // function mint(uint256 amount) public onlyOwner  whenMintHardlockOff returns (bool) {
    function _stop_mint_hardlock() internal virtual whenMintHardlockOn {
        _mint_hardlock_stopped = true;
        emit MintHardlock_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_mint_hardlock() internal virtual whenMintHardlockOff {
        _mint_hardlock_stopped = false;
        emit Started_MintHardlock(_msgSender());
    }


    // @dev **************** Locking Approving Access by address can BREAKS THINGS   ***********************
    // @dev Emitted when ApproveSpendableAddress is paused by Operator.
    event Approve_Spendable_Address_Stopped(address account);

    // @dev Emitted when the ApproveSpendableAddress is allowed by Operator.
    event Started_Approve_Spendable_Address(address account);

    bool private _approve_spendable_address_stopped;

    // @dev Returns true if the contract is _approve_spendable_address_stopped, and false otherwise.
    function approve_spendable_address_stopped() public view returns (bool) {
        return _approve_spendable_address_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _approve_spendable_address_stopped.
    modifier whenApproveSpendableAddressOn() {
        require(!_approve_spendable_address_stopped, "MultiSig: ApproveSpendableAddress Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _approve_spendable_address_stopped.
    modifier whenApproveSpendableAddressOff() {
        require(_approve_spendable_address_stopped, "Multisig: Error: ApproveSpendableAddress Permission Revoked");
        _;
    }

    // @dev Triggers stopped state. Call in function whenApproveSpendableAddressOn
    function _stop_approve_spendable_address() internal virtual whenApproveSpendableAddressOn {
        _approve_spendable_address_stopped = true;
        emit Approve_Spendable_Address_Stopped(_msgSender());
    }


    // @dev Returns to normal state.
    function _start_approve_spendable_address() internal virtual whenApproveSpendableAddressOff {
        _approve_spendable_address_stopped = false;
        emit Started_Approve_Spendable_Address(_msgSender());
    }


    // @dev **************** Locking Out Access by Contracts BREAKS THINGS   ***********************
    // First whitelist all contracts that interact with ADMIRE, turn this on if under attack
    // @dev Emitted when Changing Contract Interaction is paused by Operator.
    event NoContracts_Stopped(address account);

    // @dev Emitted when the Changing Contract Interaction is allowed by Operator.
    event Started_NoContracts(address account);

    bool internal _nocontracts_stopped;


    // @dev Returns true if the contract is _nocontracts_stopped, and false otherwise.
    function nocontracts_stopped() public view returns (bool) {
        return _nocontracts_stopped;
    }

    // @dev Modifier to make a function callable only when the contract is not _nocontracts_stopped.
    modifier whenNoContractsOn() {
        require(!_nocontracts_stopped, "MultiSig: NoContracts Allowed");
        _;
    }

    // @dev Modifier to make a function callable only when the contract is _nocontracts_stopped.
    modifier whenNoContractsOff() {
        require(_nocontracts_stopped, "Multisig: Error: NoContracts Permission Revoked");
        _;
    }

    // @dev Triggers stopped state. Call in function E5_updateCharityRate:
    function _stop_nocontracts() internal virtual whenNoContractsOn {
        _nocontracts_stopped = true;
        emit NoContracts_Stopped(_msgSender());
    }

    // @dev Returns to normal state.
    function _start_nocontracts() internal virtual whenNoContractsOff {
        _nocontracts_stopped = false; 
       // emit Started_NoContracts(_msgSender());
    }


    /**
     *   @dev Triggers stopped state. Call in function whenNoContractsOn:
     *   function function _start_nocontracts(address sender) will stop contracts interacting, 
     *   But without whitelisted addresses, move to modifier in coin contract
     */

    /**
     * // @dev Returns to normal state.
     * function _start_nocontracts(address sender) internal virtual whenNoContractsOff {
     *   if (sender.isContract()) {
     *       _nocontracts_stopped = false;
     *       emit Started_NoContracts(_msgSender());
     *  }
     *}
     */
  }


/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable, Pausable, MultiSig {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }
    
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override whenNotPaused view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override whenNotPaused whenApproveSpendableAddressOn returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public whenApproveSpendableAddressOn returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    // function mint(uint256 amount) public onlyOwner whenMintHardlockOn returns (bool) {
    function mint(uint256 amount) public onlyOwner whenMintHardlockOn returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }
    

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _charity(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: charity from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: charity amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_charity} and {_approve}.
     */
    function _charityFrom(address account, uint256 amount) internal {
        _charity(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: charity amount exceeds allowance')
        );
    }
}


contract A_Solc6_V16 is BEP20('ArrgghhV15', 'ADMRSL6V16'){
    using Address for address;
    // Transfer tax rate in basis points. (default 5% which would be 500)
    uint16 public transferTaxRate = 0;
    // Charity rate % of transfer tax. (default 20% which is 20 below x 5% = 1% of total amount).
    uint16 public charityRate = 0;
    // Max transfer tax rate: 10% which is 1000 below 
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    // Charity address
    // uncomment and leave constant if you don't want to be able to change the charity address
    // Also, if you want it fixed, comment out the address changing funtions and event below
    //address public constant CHARITY_ADDRESS = 0x5d484FbAa477D3bB73D94D89F17E6F5858B85dc0;
    address public CHARITY_ADDRESS = 0x5d484FbAa477D3bB73D94D89F17E6F5858B85dc0;
    // uncomment and leave constant if you don't want to be able to change the charity address
    // Also, if you want it fixed, comment out the address changing funtions and event below
    //address public constant TAX_ADDRESS = 0x73cb224189F6b33aB841B946EcE553c07EBdF1A0;
    address public TAX_ADDRESS = 0x73cb224189F6b33aB841B946EcE553c07EBdF1A0;
    
    // Max transfer amount rate in basis points. (default is 0.5% of total supply, which is 50 below)
    uint16 public maxTransferAmountRate = 50;
    // Addresses that excluded from antiWhale
    mapping(address => bool) public _excludedFromAntiWhale;
    // Addresses that are MultiSig
    mapping(address => bool) public _excludedFromMultiSig;
    // Address that are blacklisted
	mapping(address => bool) public _blacklist;
	// Contract address that are whitelisted
	mapping(address => bool) public _contractwhitelist;
	// Address that have the Minter Role
	mapping(address => bool) public _minterroleaddress;
    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = false;
    // Min amount to liquify. (default 500 ADMIREs)
    uint256 public minAmountToLiquify = 500 ether;
    // The swap router, modifiable. Will be changed to Admire's router when our own AMM release
    IUniswapV2Router02 public admireSwapRouter;
    // The trading pair
    address public admireSwapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;
    // The operator can only update the transfer tax rate
    address private _operator;



    // Events
    event ContractAddressTransferred(address indexed previosContractAddress, address indexed newContractAddress);
        // comment out if you want the CHARITY_ADDRESS static
    event CharityAddressTransferred(address indexed previosCharityAddress, address indexed newCharityAddress);
        // comment out if you want the TAX_ADDRESS static
    event TaxAddressTransferred(address indexed previosTaxAddress, address indexed newTaxAddress);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed owner, uint256 previousRate, uint256 newRate);
    event CharityRateUpdated(address indexed owner, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed owner, uint256 previousRate, uint256 newRate);
    event SwapAndLiquifyEnabledUpdated(address indexed owner, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed owner, uint256 previousAmount, uint256 newAmount);
    event AdmireRouterUpdated(address indexed owner, address indexed router, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event BlacklistUpdated(address indexed owner, bool value);
    event ContractWhitelistUpdated(address indexed owner, bool value);
    event MinterRoleUpdated(address indexed owner, bool value);
    event WithdrawTokensSentHere(address token , address owner, uint256 amount);

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "ADMIRE::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    modifier blacklisted(address sender, address recipient) {
            if ( _blacklist[sender] == true || _blacklist[recipient] == true 
            ) {
            // @dev WARNING! If this is doing anything other than revert, it's an EVIL CONTRACT!
            // @dev should be similar to: revert("ADMIRE::blacklisted: Transfer declined");
        	 revert("ADMIRE::blacklisted: Transfer declined");
            }
            _;
    }


    modifier NoContractsOn(address sender, address recipient) {
            if ( _nocontracts_stopped == true) {
                if ( (sender.isContract() && _contractwhitelist[sender] == false)
                    || (recipient.isContract() && _contractwhitelist[recipient] == false)
                   ) {
                   revert("ADMIRE::MultiSig::Transfers to non-whitelisted contracts declined");
                  }
              }
              _;
    }
 
    modifier MintWrappersOn(address recipient) {
            if ( _mint_wrappers_stopped == true && _minterroleaddress[recipient] == false) {
                if  (recipient.isContract() && _contractwhitelist[recipient] == false)
                   {
                   revert("ADMIRE::MultiSig::Minting to non-whitelisted contracts declined");
                  }
              }
              _;
    }
 //whenMintWrappersOn

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }


    constructor() public {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
        //emit ContractAddressTransferred(address(0), _minterroleaddress);
        emit CharityAddressTransferred(address(0), CHARITY_ADDRESS);
        emit TaxAddressTransferred(address(0), TAX_ADDRESS);
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[CHARITY_ADDRESS] = true;
        _excludedFromAntiWhale[TAX_ADDRESS] = true;
        _contractwhitelist[msg.sender] = true;
        _contractwhitelist[address(this)] = true;
       // _minterroleaddress[msg.sender] = true;
        _minterroleaddress[address(this)] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address recipient, uint256 _amount) public onlyOwner MintWrappersOn(recipient) {
        _mint(recipient, _amount);
        _moveDelegates(address(0), _delegates[recipient], _amount);
    }
    
    function F4_blacklistUpdate(address user, bool value) public virtual onlyOwner whenBlacklistOn {
        // require(_owner == _msgSender(), "Only owner is allowed to modify blacklist.");
        _blacklist[user] = value;
        emit BlacklistUpdated(user, value);
    }
    
    function H4_contractwhitelistUpdate(address user, bool value) public virtual onlyOwner whenApproveSpendableAddressOn {
        // require(_owner == _msgSender(), "Only owner is allowed to modify blacklist.");
        _contractwhitelist[user] = value;
        emit ContractWhitelistUpdated(user, value);
    }
        
    function G4_isContractWhiteListed(address user) public view onlyOwner returns (bool) {
        return _contractwhitelist[user];
    }
    
    function H3_MinterRoleUpdate(address user, bool value) public virtual onlyOwner whenApproveSpendableAddressOn {
        _minterroleaddress[user] = value;
        emit MinterRoleUpdated(user, value);
    }

    function F3_isBlackListed(address user) public view onlyOwner returns (bool) {
        return _blacklist[user];
        
    }

    function H5_isMinterRole(address user) public view onlyOwner returns (bool) {
        return _minterroleaddress[user];
    }
    
    // @dev begins MultiSig enforcement
    function A1_PauseTheChain_Pause() public onlyOperator whenNotPaused {
        _pause();
    }

    function A2_PauseTheChain_Unpause() public onlyOperator whenPaused {
        _unpause();
    }
    
    function B1_MintWrappers_EnableProtection() public onlyOperator whenMintWrappersOn {
        _stop_mint_wrappers();
    }
  
     function B2_MintWrappers_DisableProtection() public onlyOperator whenMintWrappersOff {
        _start_mint_wrappers();
    }

    // @dev WARNING! Things will break! Only for pausing during partner sites' and/or BSC network-wide hacks.
    function C1_MintLockOutDevWallet_TurnOn() public onlyOperator whenMintHardlockOn {
        _stop_mint_hardlock();
    }

     function C2_MintLockOutDevWallet_AllowMinting() public onlyOperator whenMintHardlockOff {
        _start_mint_hardlock();
    }

    
    function D1_Revoke_Change_The_Operator() public onlyOperator whenChangeOperatorOn {
        _stop_change_operator();
    }

    function D2_Allow_Change_The_Operator() public onlyOperator whenChangeOperatorOff {
        _start_change_operator();
    }


   function E1_Revoke_Changing_Rates() public onlyOperator whenRateChangeOn {
        _stop_rate_change();
    }

    function E2_Allow_Changing_Rates() public onlyOperator whenRateChangeOff {
        _start_rate_change();
    }


    function F1_BlacklistingAddresses_TurnOff() public onlyOperator whenBlacklistOn {
        _stop_blacklist();
    }

    function F2_BlacklistingAdresses_TurnOn() public onlyOperator whenBlacklistOff {
        _start_blacklist();
    }

    function G1_Revoke_AntiWhale() public onlyOperator whenAntiWhaleOn {
        _stop_antiwhale();
    }

     function G2_Allow_AntiWhale() public onlyOperator whenAntiWhaleOff {
        _start_antiwhale();
    }

    // @dev WARNING! Things will break! The devs need to be able to increase allowances.
    function H1_Approve_Spendable_Address_TurnOff() public onlyOperator whenApproveSpendableAddressOn {
        _stop_approve_spendable_address();
    }

     function H2_Approve_Spendable_Address_TurnOn() public onlyOperator whenApproveSpendableAddressOff {
        _start_approve_spendable_address();
    }

    // @dev WARNING! This will absolutely break things! Whitelist every known contract first!
      function G1_NonWhitelistedContracts_TurnOff() public onlyOperator whenNoContractsOn {
        _stop_nocontracts();
    }

     function G2_NonWhitelistedContracts_TurnOn() public onlyOperator whenNoContractsOff {
        _start_nocontracts();
    }

    
    /// @dev overrides transfer function to meet tokenomics of ADMIRE
    function _transfer(address sender, address recipient, uint256 amount) 
        internal virtual override 
            blacklisted(sender, recipient) antiWhale(sender, recipient, amount) NoContractsOn(sender, recipient) 
            // blacklisted(sender, recipient) antiWhale(sender, recipient, amount)
    {
        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(admireSwapRouter) != address(0)
            && admireSwapPair != address(0)
            && sender != admireSwapPair
            && sender != owner()
        ) {
            swapAndLiquify();
        }
        //} else if (recipient == CHARITY_ADDRESS || transferTaxRate == 0) {
        if (charityRate > 0 && transferTaxRate == 0) {
            uint256 charityAmount = amount.mul(charityRate).div(10000);
            uint256 sendAmount = amount.sub(charityAmount);
            super._transfer(sender, CHARITY_ADDRESS, charityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        } else if  (charityRate == 0 || transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 5% of every transfer
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
            uint256 charityAmount = taxAmount.mul(charityRate).div(10000);
            uint256 liquidityAmount = taxAmount.sub(charityAmount);
            require(taxAmount == charityAmount + liquidityAmount, "ADMIRE::transfer: Charity value invalid");

            // default 95% of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "ADMIRE::transfer: Tax value invalid");

            super._transfer(sender, CHARITY_ADDRESS, charityAmount);
            //super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, TAX_ADDRESS, liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }
    

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree  {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 maxTransferAmount = maxTransferAmount();
        contractTokenBalance = contractTokenBalance > maxTransferAmount ? maxTransferAmount : contractTokenBalance;

        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = liquifyAmount.div(2);
            uint256 otherHalf = liquifyAmount.sub(half);

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half);

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add liquidity
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the admireSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = admireSwapRouter.WETH();

        _approve(address(this), address(admireSwapRouter), tokenAmount);

        // make the swap
        admireSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(admireSwapRouter), tokenAmount);

        // add the liquidity
        admireSwapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            operator(),
            block.timestamp
        );
    }

   /// destroy the contract and reclaim the leftover funds. REMOVE FOR PRODUCTION USE
    function kill() public onlyOwner {
        selfdestruct(msg.sender);
    }
    
    
    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(1000000000000000000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev Returns the address is excluded from MultiSig or not.
     *
     * function isExcludedFromMultiSig(address _account) public view returns (bool) {
     *   return _excludedFromMultiSig[_account];
     *}
     * /

    // To receive BNB from admireSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function E4_updateTransferTaxRate(uint16 _transferTaxRate) public onlyOwner whenRateChangeOn {
        require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "ADMIRE::E4_updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateUpdated(msg.sender, transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @dev Update the charity rate.
     * Can only be called by the current operator.
     */
    function E5_updateCharityRate(uint16 _charityRate) public onlyOwner whenRateChangeOn {
        require(_charityRate <= 10000, "ADMIRE::E5_updateCharityRate: Charity rate must not exceed the maximum rate.");
        emit CharityRateUpdated(msg.sender, charityRate, _charityRate);
        charityRate = _charityRate;
    }

    // owner can drain tokens that are sent here by mistake
    function K1_withdrawTokensSentHere(BEP20 token, uint amount) public onlyOwner {
        emit WithdrawTokensSentHere(address(token), owner(), amount);
        token.transfer(owner(), amount);
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function E6_updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOwner whenRateChangeOn {
        require(_maxTransferAmountRate <= 10000, "ADMIRE::E6_updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Update the min amount to liquify.
     * Can only be called by the current operator.
     */
    function E7_updateMinAmountToLiquify(uint256 _minAmount) public onlyOwner {
        emit MinAmountToLiquifyUpdated(msg.sender, minAmountToLiquify, _minAmount);
        minAmountToLiquify = _minAmount;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function G5_setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOwner whenAntiWhaleOn {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Exclude or include an address from MultiSig.
     * Can only be called by the current operator.
     *
     *function setExcludedFromMultiSig(address _account, bool _excluded) public onlyOperator {
     *   _excludedFromMultiSig[_account] = _excluded;
     * }
     * /

    /**
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateAdmireRouter(address _router) public onlyOwner {
        admireSwapRouter = IUniswapV2Router02(_router);
        admireSwapPair = IUniswapV2Factory(admireSwapRouter.factory()).getPair(address(this), admireSwapRouter.WETH());
        require(admireSwapPair != address(0), "ADMIRE::updateAdmireRouter: Invalid pair address.");
        emit AdmireRouterUpdated(msg.sender, address(admireSwapRouter), admireSwapPair);
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function D3_transferOperator(address newOperator) public onlyOwner whenChangeOperatorOn {
        require(newOperator != address(0), "ADMIRE::D3_transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

  /**
    * @dev Change the charity address, only allowed when multisig auth to change charity rate is true
    * Comment out this function if you want CHARITY_ADDRESS to be static
    */
    function E3_transferCharitytAddress(address newCharityAddress) public onlyOwner whenRateChangeOn {
        require(newCharityAddress != address(0), "ADMIRE::transferCharityAddress: contract cannot be the zero address");
        emit CharityAddressTransferred(CHARITY_ADDRESS, newCharityAddress);
        CHARITY_ADDRESS = newCharityAddress;
    }
    
      /**
    * @dev Change the charity address, only allowed when multisig auth to change tax rate is true
    * Comment out this function if you want CHARITY_ADDRESS to be static
    */
    function E4_transferTaxAddress(address newTaxAddress) public onlyOwner whenRateChangeOn  {
        require(newTaxAddress != address(0), "ADMIRE::E4_transferTaxAddress: contract cannot be the zero address");
        emit TaxAddressTransferred(TAX_ADDRESS, newTaxAddress);
        TAX_ADDRESS = newTaxAddress;
    }
    
    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        'EIP712Domain(string name,uint256 chainId,address verifyingContract)'
    );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256(
        'Delegation(address delegatee,uint256 nonce,uint256 expiry)'
    );

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
        );

        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'ADMIRE::delegateBySig: invalid signature');
        require(nonce == nonces[signatory]++, 'ADMIRE::delegateBySig: invalid nonce');
        require(now <= expiry, 'ADMIRE::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, 'ADMIRE::getPriorVotes: not yet determined');

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying ADMIREs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, 'ADMIRE::_writeCheckpoint: block number exceeds 32 bits');

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    
}