/**
 *Submitted for verification at hooscan.com on 2021-08-20
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/interfaces/IMdexRouter.sol

pragma solidity >=0.5.0;

interface IMdexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapMining() external pure returns (address);

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

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external view returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

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


// File contracts/interfaces/IMdexPair.sol

pragma solidity >=0.5.0;

interface IMdexPair {
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

    function price(address token, uint256 baseDecimal) external view returns (uint256);

    function initialize(address, address) external;
}


// File contracts/libs/token/ORC20/IORC20.sol



pragma solidity >=0.4.0;

interface IORC20 {
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


// File contracts/libs/GSN/Context.sol



pragma solidity >=0.4.0;

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
    //constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/libs/access/Ownable.sol



pragma solidity >=0.4.0;

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
    constructor() public {
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


// File contracts/libs/math/SafeMath.sol



pragma solidity >=0.4.0;

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


// File contracts/libs/utils/Address.sol



pragma solidity ^0.5.0;

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
        (bool success, ) = recipient.call.value(amount)('');
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
        (bool success, bytes memory returndata) = target.call.value(weiValue)(data);
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


// File contracts/libs/token/ORC20/ORC20.sol



pragma solidity >=0.4.0;





/**
 * @dev Implementation of the {IORC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ORC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ORC20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ORC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IORC20-approve}.
 */
contract ORC20 is Context, IORC20, Ownable {
    using SafeMath for uint256;
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
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ORC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ORC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ORC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ORC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ORC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ORC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ORC20};
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
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ORC20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ORC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ORC20-approve}.
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
            _allowances[_msgSender()][spender].sub(subtractedValue, 'ORC20: decreased allowance below zero')
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
    function mint(uint256 amount) public onlyOwner returns (bool) {
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
    ) internal {
        require(sender != address(0), 'ORC20: transfer from the zero address');
        require(recipient != address(0), 'ORC20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'ORC20: transfer amount exceeds balance');
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
        require(account != address(0), 'ORC20: mint to the zero address');

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'ORC20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'ORC20: burn amount exceeds balance');
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
        require(owner != address(0), 'ORC20: approve from the zero address');
        require(spender != address(0), 'ORC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'ORC20: burn amount exceeds allowance')
        );
    }
}


// File contracts/libs/token/ORC20/SafeORC20.sol



// pragma solidity ^0.6.0;
pragma solidity ^0.5.0;



/**
 * @title SafeORC20
 * @dev Wrappers around ORC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeORC20 for IORC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeORC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IORC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IORC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IORC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IORC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeORC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IORC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IORC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeORC20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IORC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeORC20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeORC20: ORC20 operation did not succeed');
        }
    }
}


// File contracts/libs/utils/ReentrancyGuard.sol



//pragma solidity ^0.6.0;
pragma solidity >=0.5.16;

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
contract ReentrancyGuard {
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

    constructor() public {
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


// File contracts/oldBase/ILpStakingRewards.sol

pragma solidity ^0.5.16;

interface ILpStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount, address user) external;

    function withdraw(uint256 amount, address user) external;

    function getReward() external;

    function claim(address to) external;

    function setHecoPool(uint _hecoPoolId) external;

    function setOperator(address _operator) external;

    function resetRewardPercent(uint256 _percent) external;

    function notifyRewardPercent(uint256 _percent) external;

    function burn(uint256 amount) external;

    function setTimeLock(address _timeLock) external;
}


// File contracts/Syi.sol

pragma solidity ^0.5.0;






contract SYI is ORC20 {
  using SafeORC20 for IORC20;
  using Address for address;
  using SafeMath for uint;

  address public governance;
  uint256 private _cap = uint256(12).mul(1e25);
  mapping (address => bool) public minters;

  constructor () public ORC20("SYI", "SYI") {
      governance = tx.origin;
  }

  /**
    * @dev Returns the cap on the token's total supply.
    */
  function cap() public view returns (uint256) {
      return _cap;
  }

  function mint(address account, uint256 amount) public {
      require(minters[msg.sender], "!minter");
      require(totalSupply().add(amount) <= _cap, "Capped: cap exceeded");
      _mint(account, amount);
  }

  function setGovernance(address _governance) public {
      require(msg.sender == governance, "!governance");
      governance = _governance;
  }

  function addMinter(address _minter) public {
      require(msg.sender == governance, "!governance");
      minters[_minter] = true;
  }

  function removeMinter(address _minter) public {
      require(msg.sender == governance, "!governance");
      minters[_minter] = false;
  }

  function burn(address account, uint256 amount) public {
      require(msg.sender == account, "!burn");
      _burn(account, amount);
  }
}


// File contracts/oldBase/OldLpStakingRewards.sol

pragma solidity ^0.5.16;




/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}



// Inheritance

contract RewardsDistributionRecipient {
    address public owner;
    mapping(address => bool) public verified;

    function notifyRewardPercent(uint256 percent) external;

    modifier onlyRewardsDistribution() {
        require(verified[msg.sender], "Caller is not verified");
        _;
    }
}

contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

interface IHecoPool {
    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;
}

interface ITimeLock {
    function addLockTokenForRewardRecipient(address account, uint256 amount) external;

    function updateTokenReleaseStartTime(uint256 _startTime) external;
}

contract OldLpStakingRewards is ILpStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, Initializable {
    using SafeMath for uint256;
    using SafeORC20 for IORC20;
    using SafeORC20 for SYI;

    IHecoPool public hecoPool;
    IORC20 public mdxToken;

    /* ========== STATE VARIABLES ========== */

    // 成员变量顺序不要调整，切记。
    // 部署后基类不能再修改。所有新需求的函数和storage变量都在子类添加

    address public operator;
    SYI public rewardsToken;
    IORC20 public stakingToken;
    ITimeLock public timeLock;
    uint256 public hecoPoolId;
    uint256 public startTime;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalAmount;
    uint256 public totalRewards;
    uint256 internal rewardsNext;
    // 用户累计提现金额
    uint256 public rewardsPaid;
    // 累计发放到奖金池中的奖励
    uint256 public rewarded;
    uint256 public leftRewardTimes;
    // 记录当前周期内每个块的发放币数量，用于调整币池占用比例时，调整rewardRate参数
    uint256 public currentRewardToken;
    // 下个周期内每个块发放币量
    uint256 internal nextRewardToken;
    uint256 internal firstDurationRewards;
    // 百分比的精度，小数点后两位，支持设置5.15%，则百分比的输入值为515
    uint256 internal decimalPercent;
    uint256 public percentOfRewardToken;
    uint256 internal hecoBlockIntervalInSec;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 internal _totalSupply;
    // 用户在开仓、补仓时，存入mdex的钱，返回的lp的余额
    mapping(address => uint256) internal _balances;

    // 解锁开始时间，为奖励开始的4周后
    uint256 public releaseStartTime;

    function initialize(
        address _rewardsManager,   // LpStakingRewardsManager
        address _rewardsToken,     // SYI
        address _stakingToken,     // MdexPair
        uint256 _hecoPoolId,
        uint256 _startTime
    ) public initializer() {
        require(_rewardsToken != _stakingToken, "_rewardsToken and _stakingToken can not be equal");

        owner = msg.sender;
        verified[owner] = true;
        verified[_rewardsManager] = true;

        rewardsToken = SYI(_rewardsToken);
        stakingToken = IORC20(_stakingToken);
        hecoPoolId = _hecoPoolId;
        startTime = _startTime;

        hecoPool = IHecoPool(0x26eE42a4DE70CEBCde40795853ebA4E492a9547F);
        mdxToken = IORC20(0xbE8D16084841875a1f398E6C3eC00bBfcbFa571b);
        rewardsDuration = 7 days;
        totalAmount = 12e25;
        leftRewardTimes = 64;
        nextRewardToken = 20e18;
        firstDurationRewards = 75e18;
        decimalPercent = 10000;
        hecoBlockIntervalInSec = 3;
    }

    /// @dev totalSupply 用户投入总额
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @dev balanceOf 用户在本合约的余额
    /// @param account 用户地址
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @dev rewardPerToken 利息率
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    /// @dev earned 用户能够获得多少奖励
    /// @param account 用户地址
    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /// @dev earnedWithLock 用户在锁仓时，能够获得多少奖励
    /// @param account 用户地址
    function earnedWithLock(address account) public view returns (uint256 releasedTokens, uint256 lockedTokens) {
        // 当前用户在不锁仓的情况下能够收获的数量
        uint256 earnedBalance = earned(account);

        (releasedTokens, lockedTokens) = getLockableInfo(earnedBalance);
    }

    /// @dev getRewardForDuration 在本次出块周期内，奖励额度
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /// @dev stake 用户存入钱，并获得奖励
    /// @param amount 用户存入的额度
    /// @param user 用户地址
    function stake(uint256 amount, address user) external nonReentrant updateReward(user) checkhalve checkStart checkOperator(user, msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(user != address(0), "user cannot be 0");
        address from = operator != address(0) ? operator : user;
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
        stakingToken.safeTransferFrom(from, address(this), amount);
        if (hecoPoolId > 0) {
            // stake to heco pool for mdx
            stakingToken.safeApprove(address(hecoPool), 0);
            stakingToken.safeApprove(address(hecoPool), uint256(-1));
            hecoPool.deposit(hecoPoolId, amount);
            emit StakedHecoPool(from, amount);
        }
        emit Staked(from, amount);
    }

    /// @dev withdraw 用户提取
    function withdraw(uint256 amount, address user) public nonReentrant updateReward(user) checkhalve checkStart checkOperator(user, msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(user != address(0), "user cannot be 0");
        require(_balances[user] >= amount, "not enough");

        // 确认operator和user操作条件，本合约有两种应用场景，当为单币合约时，operator为0地址，并且hecoPoolId为0
        // 当为币对时，operator为Goblin地址，hecoPoolId为mdex池子中币对的mdexPair地址
        address to = operator != address(0) ? operator : user;
        if (hecoPoolId > 0) {
            // withdraw lp token back
            hecoPool.withdraw(hecoPoolId, amount);
            emit WithdrawnHecoPool(to, amount);
        }
        _totalSupply = _totalSupply.sub(amount);
        _balances[user] = _balances[user].sub(amount);

        // to是Goblin地址
        stakingToken.safeTransfer(to, amount);
        emit Withdrawn(to, amount);
    }

    /// @dev 计算锁定币量信息，在1-4周，lockTotal和lockBalance是一致的
    /// @param unclaimedReward 根据earned函数计算的当前可收获值
    function getLockableInfo(uint256 unclaimedReward) internal view returns (uint256 releasedTokens, uint256 lockedTokens){
        // 使用剩余奖励周期数判断是否锁定奖励，在前4个奖励周期内，剩余奖励周期数大于等于60
        // 总奖励周期为64，每期7天
        if(leftRewardTimes >= 60) {
            // 在最初的1-4周，锁定获取量的70%，30%可提取
            releasedTokens = unclaimedReward.mul(30).div(100);
            lockedTokens = unclaimedReward.sub(releasedTokens);
        } else {
            // 判断获取时，是否需要锁定币量，在第4周之后，不需要锁定
            releasedTokens = unclaimedReward;
        }
    }

    /// @dev getReward 获取奖励
    function getReward() public nonReentrant updateReward(msg.sender) checkhalve checkStart {
        require(msg.sender != address(0), "user cannot be 0");
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;

            // 计算解锁量、锁定量
            (uint256 releasedTokens, uint256 lockedTokens) = getLockableInfo(reward);

            if(lockedTokens > 0){
                timeLock.addLockTokenForRewardRecipient(msg.sender, lockedTokens);
                rewardsToken.safeTransfer(address(timeLock), lockedTokens);

                emit RewardPaidTimeLock(msg.sender, lockedTokens);
            }

            if(releasedTokens > 0){
                rewardsPaid = rewardsPaid.add(releasedTokens);
                rewardsToken.safeTransfer(msg.sender, releasedTokens);

                emit RewardPaid(msg.sender, releasedTokens);
            }
        }
    }

    function burn(uint256 amount) external onlyRewardsDistribution {
        leftRewardTimes = 0;
        nextRewardToken = 0;
        rewardsNext = 0;
        rewardsToken.burn(address(this), amount);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier checkhalve() {
        if (block.timestamp >= periodFinish && leftRewardTimes > 0 && nextRewardToken > 0) {
            // 记录当前周期内，每个块的发币数量
            currentRewardToken = nextRewardToken;
            leftRewardTimes = leftRewardTimes.sub(1);

            // 奖励模型，共64期，一期一周，第一期每个区块奖励75个代币
            // 第二期每个区块奖励20个代币，之后每个奖励期递减1个代币
            // 到第13期，奖励模型变化，奖励代币数量为上一个奖励期的95%
            // 当奖励期结束时，nextRewardToken赋值0
            // Note：由于在上一个周期发放奖励时，下一个周期的奖励数已经计算完毕
            // 第13期时leftRewardTimes为51，第12期时，leftRewardTimes为52
            // 即在leftRewardTimes为52时，nextRewardToken要按照上一个周期的95%计算
            if (leftRewardTimes > 52) {
                nextRewardToken = nextRewardToken.sub(1e18);
            } else {
                nextRewardToken = leftRewardTimes == 0 ? 0 : nextRewardToken.mul(95).div(100);
            }

            // 在第五个奖励周期开始时，同步开始解锁锁定币
            // 59为在第五个奖励周期时，还剩余的奖励周期
            if (leftRewardTimes <= 59 && releaseStartTime == 0) {
                releaseStartTime = block.timestamp;
                timeLock.updateTokenReleaseStartTime(block.timestamp);
            }

            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardsDuration);
            // 奖励提前发放结束
            if (totalRewards <= rewarded) {
                leftRewardTimes = 0;
                nextRewardToken = 0;
                rewardsNext = 0;
            } else {
                uint256 left = totalRewards.sub(rewarded);
                uint256 reward = leftRewardTimes == 0 ? left : rewardsNext;
                if (reward >= left) {
                    reward = left;

                    leftRewardTimes = 0;
                    nextRewardToken = 0;
                    rewardsNext = 0;
                } else {
                    rewardsNext = leftRewardTimes == 0 ? 0 : rewardsDuration.div(hecoBlockIntervalInSec).mul(nextRewardToken).mul(percentOfRewardToken).div(decimalPercent);
                }

                rewardRate = reward.div(rewardsDuration);
                rewarded = rewarded.add(reward);
                rewardsToken.mint(address(this), reward);

                emit RewardAdded(reward);
            }
        }
        _;
    }

    modifier checkStart() {
        require(block.timestamp > startTime, "not start");
        _;
    }

    modifier checkOperator(address user, address sender) {
        require((operator == address(0) && user == sender) || (operator != address(0) && operator == sender),"this contract must be deployed by LpStakingRewardsManager");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    // _percent 输入为本币池子占用总代币的百分比，精确到小数点后2位，比如6%，输入600，6.18%，则输入618
    function notifyRewardPercent(uint256 _percent) external onlyRewardsDistribution updateReward(address(0)) {
        require(rewarded == 0, "reward already inited");
        require(percentOfRewardToken == 0, "percentOfRewardToken already init");
        percentOfRewardToken = _percent;
        // 本币池子中代币总额
        totalRewards = totalAmount.mul(percentOfRewardToken).div(decimalPercent);
        require(totalRewards <= totalAmount, "exceeds total amount");

        // 记录当前奖励周期内每个块的发币数量
        currentRewardToken = firstDurationRewards;
        // 第一个发放周期总奖励额度
        uint256 reward = rewardsDuration.div(hecoBlockIntervalInSec).mul(firstDurationRewards).mul(percentOfRewardToken).div(decimalPercent);
        require(reward <= totalRewards, "period reward exceeds total rewards amount");

        rewardsToken.mint(address(this), reward);
        rewardRate = reward.div(rewardsDuration);
        // 累计奖励
        rewarded = reward;
        leftRewardTimes = leftRewardTimes.sub(1);
        rewardsNext = rewardsDuration.div(hecoBlockIntervalInSec).mul(nextRewardToken).mul(percentOfRewardToken).div(decimalPercent);
        lastUpdateTime = block.timestamp;
        periodFinish = startTime.add(rewardsDuration);
        emit RewardAdded(percentOfRewardToken);
    }

    // 按百分比重新设置下个周期的发放币量
    function resetRewardPercent(uint256 _percent) external onlyRewardsDistribution updateReward(address(0)) {
        // 设置的币量百分比不能与之前的相当
        require(percentOfRewardToken != _percent, "the _percent and percentOfRewardToken are equal");

        uint256 newTotalRewards = totalAmount.mul(_percent).div(decimalPercent);
        // 检查_percent比例的代币总额，与已发放代币总额比较，必须要大于已发放代币总额
        require(newTotalRewards > rewarded, "rewarded is bigger than the new total limit");
        require(newTotalRewards <= totalAmount, "new total rewards exceeds total amount");

        percentOfRewardToken = _percent;
        totalRewards = newTotalRewards;
        rewardsNext = rewardsDuration.div(hecoBlockIntervalInSec).mul(nextRewardToken).mul(percentOfRewardToken).div(decimalPercent);
        emit ResetRewardPercent(_percent);
    }

    function setOperator(address _operator) external onlyRewardsDistribution {
        // 增加逻辑operator只能设置一次，防止上线运行后，operator的修改导致用户取不出存款
        require(operator == address(0), "operator of LpStakingRewards can not be set repeatedly");
        require(_operator != address(0), "the _operator can not be 0");
        operator = _operator;
    }

    function setHecoPool(uint _hecoPoolId) external onlyRewardsDistribution {
        require(_hecoPoolId > 0 && hecoPoolId == 0, "heco pool can not be update");
        hecoPoolId = _hecoPoolId;
        // stake to heco pool for mdx
        stakingToken.safeApprove(address(hecoPool), 0);
        stakingToken.safeApprove(address(hecoPool), uint256(-1));
        hecoPool.deposit(hecoPoolId, _totalSupply);
        emit StakedHecoPool(address(this), _totalSupply);
    }

    function setTimeLock(address _timeLock) external onlyRewardsDistribution {
        require(_timeLock != address(0), "the _timeLock can not be 0");
        timeLock = ITimeLock(_timeLock);
        rewardsToken.approve(_timeLock, uint256(-1));
    }

    function verifyOperators(address[] calldata _operators, bool ok) external onlyRewardsDistribution {
        for (uint256 i = 0; i < _operators.length; i++) {
            verified[_operators[i]] = ok;
        }
    }

    function claim(address to) external onlyRewardsDistribution {
        uint256 amount = mdxToken.balanceOf(address(this));
        mdxToken.transfer(to, amount);
        emit Claim(to, amount);
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 percent);
    event ResetRewardPercent(uint256 percent);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardPaidTimeLock(address indexed user, uint256 reward);
    event StakedHecoPool(address indexed user, uint256 amount);
    event WithdrawnHecoPool(address indexed user, uint256 amount);
    event Claim(address indexed to, uint256 amount);
}


// File contracts/pudding/LpStakingRewardsComp.sol

pragma solidity ^0.5.16;



contract LpStakingRewardsComp is OldLpStakingRewards {
    uint256 public controllerFee;
    uint256 public constant controllerFeeMax = 10000; // 100 = 1%
    uint256 public constant controllerFeeUL = 300;

    uint256 public buyBackRate;
    uint256 public constant buyBackRateMax = 10000; // 100 = 1%
    uint256 public constant buyBackRateUL = 800;

    uint256 public entranceFeeFactor;
    uint256 public constant entranceFeeFactorMax = 10000;
    uint256 public constant entranceFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    uint256 public withdrawFeeFactor;
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    uint256 public slippageFactor;
    uint256 public constant slippageFactorUL = 995;

    address public feeRecipient;
    address public buyBackAddress;
    uint256 public totalShares;

    address public mdxRouterAddress;
    address[] public earnedToSYIPath;
    address[] public earnedToToken0Path;
    address[] public earnedToToken1Path;
    address[] public token0ToEarnedPath;
    address[] public token1ToEarnedPath;

    function init(address _recipient, address _router) public onlyRewardsDistribution {
        require(_router != address(0), "_router cannot be zero");

        feeRecipient = _recipient;
        mdxRouterAddress = _router;

        // 1.88%
        controllerFee = 70;
        buyBackRate = 0;
        entranceFeeFactor = 10000;
        withdrawFeeFactor = 10000;
        // 5% default slippage tolerance
        slippageFactor = 950;
        buyBackAddress = 0x000000000000000000000000000000000000dEaD;
    }

    function setSwapPath(
        address[] calldata _earnedToSYIPath,
        address[] calldata _earnedToToken0Path,
        address[] calldata _earnedToToken1Path,
        address[] calldata _token0ToEarnedPath,
        address[] calldata _token1ToEarnedPath
    ) external onlyRewardsDistribution {
        earnedToSYIPath = _earnedToSYIPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        token1ToEarnedPath = _token1ToEarnedPath;
    }

    // 不用的两个函数。直接覆盖掉。防止误调用
    function stake(uint256 amount, address user) external {
        require(false, "please call stakeComp instead");
    }
    function withdraw(uint256 amount, address user) public {
        require(false, "please call withdrawComp instead");
    }

    /// @dev reward per share 利息率
    function rewardPerToken() public view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime)
                .mul(rewardRate).mul(1e18).div(totalShares)
            );
    }

    function previewAmount(uint256 shares, address user) external view returns (uint256) {
        if (shares > _balances[user]) {
            shares = _balances[user];
        }

        return shares.mul(_totalSupply).div(totalShares);
    }

    /// @dev stake 用户存入钱，并获得奖励
    /// @param amount 用户存入的 LP 额度
    /// @param user 用户地址
    function stakeComp(uint256 amount, address user) external nonReentrant updateReward(user) checkhalve checkStart checkOperator(user, msg.sender) returns (uint256) {
        require(amount > 0, "Cannot stake 0");
        require(user != address(0), "user cannot be 0");
        require(hecoPoolId > 0, "hecoPoolId should > 0");

        address from = operator != address(0) ? operator : user;
        stakingToken.safeTransferFrom(from, address(this), amount);

        // stake to heco pool for mdx
        stakingToken.safeApprove(address(hecoPool), 0);
        stakingToken.safeApprove(address(hecoPool), uint256(-1));
        hecoPool.deposit(hecoPoolId, amount);
        emit StakedHecoPool(from, amount);

        uint256 sharesAdded = amount;
        if (_totalSupply > 0 && totalShares > 0) {
            sharesAdded = amount
                .mul(totalShares)
                .mul(entranceFeeFactor)
                .div(_totalSupply.mul(entranceFeeFactorMax));
        }
        // 为了逻辑统一以及减少改动兼容基类的earned方法，_balance 记录的也是shares数量
        _balances[user] = _balances[user].add(sharesAdded);
        totalShares = totalShares.add(sharesAdded);
        _totalSupply = _totalSupply.add(amount);

        emit Staked(from, amount);
        return sharesAdded;
    }

    /// @dev withdraw 用户提取
    function withdrawComp(uint256 amount, address user) public nonReentrant updateReward(user) checkhalve checkStart checkOperator(user, msg.sender) returns (uint256) {
        require(amount > 0, "Cannot withdraw 0");
        require(user != address(0), "user cannot be 0");
        require(hecoPoolId > 0, "hecoPoolId should > 0");

        uint256 sharesRemoved = amount.mul(totalShares).div(_totalSupply);

        totalShares = totalShares <= sharesRemoved ? 0 : totalShares.sub(sharesRemoved);
        _balances[user] = _balances[user] <= sharesRemoved ? 0 : _balances[user].sub(sharesRemoved);
        // withdraw lp token back
        if (withdrawFeeFactor < withdrawFeeFactorMax) {
            amount = amount.mul(withdrawFeeFactor).div(withdrawFeeFactorMax);
        }

        // 确认operator和user操作条件，本合约有两种应用场景，当为单币合约时，operator为0地址，并且hecoPoolId为0
        // 当为币对时，operator为Goblin地址，hecoPoolId为mdex池子中币对的mdexPair地址
        address to = operator != address(0) ? operator : user;
        hecoPool.withdraw(hecoPoolId, amount);
        emit WithdrawnHecoPool(to, amount);

        // to是Goblin地址
        uint256 balance = stakingToken.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }

        _totalSupply = _totalSupply <= amount ? 0 : _totalSupply.sub(amount);
        stakingToken.safeTransfer(to, amount);
        emit Withdrawn(to, amount);

        return sharesRemoved;
    }

    function distributeFee(uint256 _earnedAmount) internal returns (uint256) {
        if (_earnedAmount > 0 && controllerFee > 0) {
            uint256 fee = _earnedAmount.mul(controllerFee).div(controllerFeeMax);
            mdxToken.safeTransfer(feeRecipient, fee);
            _earnedAmount = _earnedAmount.sub(fee);
        }

        return _earnedAmount;
    }

    function buyBack(uint256 _earnedAmt) internal returns (uint256) {
        if (buyBackRate <= 0) {
            return _earnedAmt;
        }

        uint256 buyBackAmt = _earnedAmt.mul(buyBackRate).div(buyBackRateMax);

        mdxToken.safeIncreaseAllowance(
            mdxRouterAddress,
            buyBackAmt
        );

        _safeSwap(
            mdxRouterAddress,
            buyBackAmt,
            slippageFactor,
            earnedToSYIPath,
            buyBackAddress,
            block.timestamp.add(600)
        );

        return _earnedAmt.sub(buyBackAmt);
    }

    function compound() public onlyRewardsDistribution nonReentrant {
        // harvest
        hecoPool.withdraw(hecoPoolId, 0);

        uint256 earnedAmount = mdxToken.balanceOf(address(this));

        earnedAmount = distributeFee(earnedAmount);
        earnedAmount = buyBack(earnedAmount);

        IMdexPair pair = IMdexPair(address(stakingToken));
        address token0 = pair.token0();
        address token1 = pair.token1();

        mdxToken.safeApprove(mdxRouterAddress, 0);
        mdxToken.safeIncreaseAllowance(
            mdxRouterAddress,
            earnedAmount
        );

        if (address(mdxToken) != token0) {
            _safeSwap(
                mdxRouterAddress,
                earnedAmount.div(2),
                slippageFactor,
                earnedToToken0Path,
                address(this),
                block.timestamp.add(600)
            );
        }
        if (address(mdxToken) != token1) {
            _safeSwap(
                mdxRouterAddress,
                earnedAmount.div(2),
                slippageFactor,
                earnedToToken1Path,
                address(this),
                block.timestamp.add(600)
            );
        }

        uint256 token0Amount = IORC20(token0).balanceOf(address(this));
        uint256 token1Amount = IORC20(token1).balanceOf(address(this));
        if (token0Amount > 0 && token1Amount > 0) {
            IORC20(token0).safeIncreaseAllowance(
                mdxRouterAddress,
                token0Amount
            );
            IORC20(token1).safeIncreaseAllowance(
                mdxRouterAddress,
                token1Amount
            );
            IMdexRouter(mdxRouterAddress).addLiquidity(
                token0,
                token1,
                token0Amount,
                token1Amount,
                0,
                0,
                address(this),
                block.timestamp.add(600)
            );
        }

        uint256 lpAdded = stakingToken.balanceOf(address(this));
        _totalSupply = _totalSupply.add(lpAdded);
        hecoPool.deposit(hecoPoolId, lpAdded);
    }

    function setBuyBackAddress(address _buyBackAddress) public onlyRewardsDistribution {
        buyBackAddress = _buyBackAddress;
        emit SetBuyBackAddress(_buyBackAddress);
    }

    function setSettings(
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _slippageFactor
    ) public onlyRewardsDistribution {
        require(
            _entranceFeeFactor >= entranceFeeFactorLL,
            "_entranceFeeFactor too low"
        );
        require(
            _entranceFeeFactor <= entranceFeeFactorMax,
            "_entranceFeeFactor too high"
        );
        entranceFeeFactor = _entranceFeeFactor;

        require(
            _withdrawFeeFactor >= withdrawFeeFactorLL,
            "_withdrawFeeFactor too low"
        );
        require(
            _withdrawFeeFactor <= withdrawFeeFactorMax,
            "_withdrawFeeFactor too high"
        );
        withdrawFeeFactor = _withdrawFeeFactor;

        require(_controllerFee <= controllerFeeUL, "_controllerFee too high");
        controllerFee = _controllerFee;

        require(_buyBackRate <= buyBackRateUL, "_buyBackRate too high");
        buyBackRate = _buyBackRate;

        require(
            _slippageFactor <= slippageFactorUL,
            "_slippageFactor too high"
        );
        slippageFactor = _slippageFactor;

        emit SetSettings(
            _entranceFeeFactor,
            _withdrawFeeFactor,
            _controllerFee,
            _buyBackRate,
            _slippageFactor
        );
    }

    function convertDustToEarned() public onlyRewardsDistribution {
        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        IMdexPair pair = IMdexPair(address(stakingToken));
        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 token0Amt = IORC20(token0).balanceOf(address(this));
        if (address(mdxToken) != token0 && token0Amt > 0) {
            IORC20(token0).safeIncreaseAllowance(
                mdxRouterAddress,
                token0Amt
            );

            // Swap all dust tokens to earned tokens
            _safeSwap(
                mdxRouterAddress,
                token0Amt,
                slippageFactor,
                token0ToEarnedPath,
                address(this),
                block.timestamp.add(600)
            );
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amt = IORC20(token1).balanceOf(address(this));
        if (address(mdxToken) != token1 && token1Amt > 0) {
            IORC20(token1).safeIncreaseAllowance(
                mdxRouterAddress,
                token1Amt
            );

            // Swap all dust tokens to earned tokens
            _safeSwap(
                mdxRouterAddress,
                token1Amt,
                slippageFactor,
                token1ToEarnedPath,
                address(this),
                block.timestamp.add(600)
            );
        }
    }

    function _safeSwap(
        address _routerAddress,
        uint256 _amountIn,
        uint256 _slippageFactor,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal {
        uint256[] memory amounts =
            IMdexRouter(_routerAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IMdexRouter(_routerAddress)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            amountOut.mul(_slippageFactor).div(1000),
            _path,
            _to,
            _deadline
        );
    }

    event SetBuyBackAddress(address _buyBackAddress);
    event SetSettings(
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _slippageFactor
    );
}