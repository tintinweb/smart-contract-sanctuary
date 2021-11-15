/**
 *Submitted for verification at BscScan.com on 2021-05-07
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.8;

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
     * - the calling contract must have an BNB balance of at least `value`.
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

/**
Interface for Pancake swap liquidity
 */
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

/**
Interface for Pancake swap liquidity
 */
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

/**
Interface for Pancake swap liquidity
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

/**
Interface for Pancake swap liquidity
 */
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

// File: contracts/protocols/bep/ReentrancyGuard.sol

pragma solidity >=0.6.8;

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

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

/**
 ______     ______     __  __     ______     ______     _____     ______     ______    
/\  ___\   /\  == \   /\ \/\ \   /\  ___\   /\  __ \   /\  __-.  /\  ___\   /\  == \   
\ \ \____  \ \  __<   \ \ \_\ \  \ \___  \  \ \  __ \  \ \ \/\ \ \ \  __\   \ \  __<   
 \ \_____\  \ \_\ \_\  \ \_____\  \/\_____\   \ \_\ \_\  \ \____-  \ \_____\  \ \_\\_\ 
  \/_____/   \/_/ /_/   \/_____/   \/_____/   \/_/\/_/   \/____/   \/_____/   \/_/ /_/ 
                                                                                       
    CRUSADER token paired with the Crusaders of Crypto Game
    Major Features:
    5% Auto LP
    10% true BNB Redistribution
    Game/Dev wallets cannot sell (hard coded).
    https://crusadersofcrypto.com for more information!
 */
contract Crusaders is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    
    // A mapping of address to how much token has been earned via reflection
    mapping(address => uint256) private _tokensOwned;

    //Mapping of how much an address is allowed to give to another address
    //used to allow transactions with the pancake router, etc.
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    //The total number of tokens from contract
    uint256 private _tTotal = 1000000000 * 10 ** 6 * 10 ** 9;

    //Token Information
    string private _name = "Crusaders of Crypto";
    string private _symbol = "CRUSADER";
    uint8 private _decimals = 9;

    //Interface for pancakeswap
    IPancakeRouter02 public immutable pancakeRouter;

    //Address for pancake swap
    address public pancakePair;

    //Addresses for Team
    address public immutable gameWalletAddress;
    address public immutable devWalletAddress;
    
    //Allows trading to be activated when invoking activateContract(). This cannot be unset.
    bool public isTradingEnabled = false;

    /**
        @dev Variables for the total 10% fee used for the token for liquidity and bnb rewards
     */
    bool private _inSwapAndLiquify = false;
    bool public swapAndLiquifyDisabled = true;
    // Reward Pool %. Note that it defaults to 0 and is set to default by the activateContract() function
    uint256 public rewardFee = 0;
    uint256 private _previousRewardFee = 4; //10% will be converted to BNB
    
    //Liquidity Pool %. Note that it defaults to 0 and is set to default by the activateContract() function
    uint256 public liquidityFee = 0; // 5% will be added pool
    uint256 private _previousLiquidityFee = 6;
    uint256 public minTokenNumberToSell = _tTotal.div(100000); // 0.001% max supply amount will trigger swap and add liquidity/bnb rewards

    //External: to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    /**
        Variables for tracking bnb rewards
     */
     uint256 public bnbPerToken; //how much bnb should be awared per token owned
     mapping(address => uint256) public bnbAlreadyPaid; //how much bnb has already been awarded to all holders, per address (used in calculating incremental claims)
     mapping(address => uint256) public bnbRewarded; //lifetime total total bnb rewarded to address
     mapping(address => uint256) public bnbToPayOut; //how much bnb is left to pay out per address
     uint256 public totalBnbClaimed; //how much bnb has ever been claimed from the contract
     mapping(address => bool) private _isExcludedFromReward; //used to exclude structural address from being able to claim redistribution
     address[] private _excludedFromReward; //used to exclude structural address from being able to claim redistribution
     uint256 private constant _bnbPerTokenMultiplier = 2 ** 64; //Multiplier to give the `bnbPerToken` value some accuracy
     mapping(address => bool) public excludedFromTransactionLimit; //Used by deployer/airdropper to give away 100% of supply
     uint256 public transactionLimit = _tTotal; //total amount of tokens allowed in a single sell/buy. Set to .5% of total supply on activateContract()

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event ClaimBNBSuccessfully(
        address recipient,
        uint256 bnbReceived
    );

    constructor (
        address payable routerAddress,
        address payable gameWallet,
        address payable devWallet
    ) {
        _tokensOwned[_msgSender()] = _tTotal;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(routerAddress);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
        .createPair(address(this), _pancakeRouter.WETH());

        //assign wallets
        gameWalletAddress = gameWallet;
        devWalletAddress = devWallet;

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromReward[owner()] = true;
        _excludedFromReward.push(owner());

        _isExcludedFromReward[address(_pancakeRouter)] = true;
        _excludedFromReward.push(address(_pancakeRouter));

        _isExcludedFromReward[address(this)] = true;
        _excludedFromReward.push(address(this));

        _isExcludedFromReward[0x000000000000000000000000000000000000dEaD] = true;
        _excludedFromReward.push(0x000000000000000000000000000000000000dEaD);

        _isExcludedFromReward[pancakePair] = true;
        _excludedFromReward.push(pancakePair);

        excludedFromTransactionLimit[owner()] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }

    /**
    Update how much of the internal crusader pool should be liquified for LP and BNB rewards
    */
    function setMinTokenToLiquify(uint256 tokensToLiquify) public onlyOwner {

        require(tokensToLiquify < getRewardSupply().div(1000), "token to liquify must be significantly small (<.1%) to prevent flashloan attack via reward claiming");
        minTokenNumberToSell = tokensToLiquify;
    }

    /**
    Update the max transaction limit for buys and sells. This defaults to .1% of total supply, based on the invocation from activateContract()
    Note that the input to this method is actual token amount (it will do internal math to account for decimals after the fact)
     */
    function setTransactionLimit(uint256 newTransactionLimit) public onlyOwner {
        transactionLimit = newTransactionLimit.mul(1000000000);
    }

    /**
        Disables autoliquification if needed
     */
    function disableSwapAndLiquify(bool toDisable) public onlyOwner {
        swapAndLiquifyDisabled = toDisable;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokensOwned[account];
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    //Exclude Address from Reward Claiming
    function excludeFromReward(address account) nonReentrant public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(!_isExcludedFromReward[account], "Account is already excluded");

        if (calculateBNBReward(account) > 0) {
            settleBnbReward(account);
        }

        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    //Include Address in Reward Claiming
    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");
        //note that be including something for rewards, it should backdate
        //any payouts, as to be fair an honest when including:
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                bnbAlreadyPaid[account] = bnbPerToken.mul(_tokensOwned[account]);
                bnbRewarded[account] = bnbPerToken.mul(_tokensOwned[account]);
                break;
            }
        }        
    }    

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setRewardFeePercent(uint256 newRewardFee) external onlyOwner() {
        rewardFee = newRewardFee;
    }

    function setLiquidityFeePercent(uint256 newLiquidityFee) external onlyOwner() {
        liquidityFee = newLiquidityFee;
    }

    //calculates current supply of token. Used in reward calculations
    function getRewardSupply() public view returns (uint256) {
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            tSupply = tSupply.sub(_tokensOwned[_excludedFromReward[i]]);
        }
        return tSupply;
    }

    //Calculates amount of reward and liquidity to take from the transfer amount
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(liquidityFee).div(
            10 ** 2
        );
    }

    //Calculates amount of reward and liquidity to take from the transfer amount
    function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(rewardFee).div(
            10 ** 2
        );
    }

    /**
        Read only method. Allows checking to ensure that all the appropriate addresses are
        allowlisted out of paying fees, particularly the DX Sale Router and Presale address.
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
        Approve transfers between two addresses. This allows the movement
        of tokens wbetween two addresses. Particularly useful when setting up the pancake swap
        router, after presale is finalized.
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _validateTransaction(
        address from,
        address to,
        uint256 amount
    ) private view {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from != gameWalletAddress && from != devWalletAddress, "Game wallet and Dev wallet are prohibited from selling");

        //note that once isTradingEnabled = true from activateContract(), it can no longer be disabled
        require(isTradingEnabled || from == owner(),"trading not yet enabled to allow time for deployer to airdrop/LP add to complete");

        uint256 fromBalance = _tokensOwned[from];
        require(fromBalance >= amount, "Transfer exceeds balance of sender");

        if (!excludedFromTransactionLimit[from]) {
            require(amount <= transactionLimit, "Transaction must be below limit");
        }
    }

    /**
        Standard autoliquidity/autoreward transfer method. Will transfer tokens between
        to addresses, and ensure to "liquify" (aka Sell for BNB) crusader token on the contract
        itself, to support both adding liquidity, and adding to the bnb reward pool for holders
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        _validateTransaction(from, to, amount);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        //similarly exclude transactions between the router and pair
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else if (from == pancakePair && to == address(pancakeRouter)) {
            takeFee = false;
        } else if (from == address(pancakeRouter) && to == pancakePair) {
            takeFee = false;
        }

        if (takeFee) {
            // swap and liquify if necessary
            // note: only do it on taxed transfers
            swapAndLiquify(from, to);

            uint256 liquidityFeeTaken = calculateLiquidityFee(amount);
            uint256 rewardFeeTaken = calculateRewardFee(amount);

            uint256 totalFeeTaken = liquidityFeeTaken.add(rewardFeeTaken);

            uint256 amountAfterFees = amount.sub(totalFeeTaken);

            //take from seller
            _modifyTokens(from, amount, true);
            //add to buyer
            _modifyTokens(to, amountAfterFees, false);
            //add to contract
            _tokensOwned[address(this)] = _tokensOwned[address(this)].add(totalFeeTaken);

            emit Transfer(from, to, amountAfterFees);
        } else {
            //take from seller
            _modifyTokens(from, amount, true);
            //add to buyer
            _modifyTokens(to, amount, false);
            emit Transfer(from, to, amount);
        }
    }

    /**
        Modifies tokens of the recipient, and updates their internal balance for bnb claiming
        as appropriate. For adding tokens, the amount will be a positive value. For removing tokens
        the amount should be negative
     */
    function _modifyTokens(address recipient, uint256 amount, bool minus) private {
        uint256 newBalance = _tokensOwned[recipient];

        if (minus) {
            newBalance = newBalance.sub(amount);
        } else {
            newBalance = newBalance.add(amount);
        }

        if (_isExcludedFromReward[recipient]) {
            _tokensOwned[recipient] = newBalance;
            return; //exit early, as no bnb claim is possible for this account
        }

        //first we ensure we capture all current rewards for the recipient
        //and ensure they are sent out on next claim
        uint currentRewards = calculateBNBRewardBeforePayout(recipient);
        bnbToPayOut[recipient] = bnbToPayOut[recipient].add(currentRewards);

        //then we reset the bnb distribution counter to track future gains
        //from trading volume
        bnbAlreadyPaid[recipient] = bnbPerToken.mul(newBalance); 

        //and lastly we modify the recipients token amount
        _tokensOwned[recipient] = newBalance;
    }

    /**
        This method is the main entry point for holders to claim their redistribution via BNB.
        This method will also "bump" the claim date everytime the redistribution is claimed by
        one reward cycle (default is 1 day).
     */
    function claimBNBReward() nonReentrant public {
        settleBnbReward(msg.sender);
    }

    /**
        Private method used for settling BNB rewards for the given account
        Invoked in two places: first is when folks claim their own BNB rewards.
        Second is when an account is excluded from rewards, any outstanding bnb should be force
        claimed to that given account before exclusion happens
     */
    function settleBnbReward(address account) private {
        require(balanceOf(account) > 0, 'Error: must own token to claim redistribution');

        //determine how much should be awarded from previous payouts
        //and inflight payouts
        uint256 reward = calculateBNBReward(account);

        (bool sent,) = address(account).call{value : reward}("");
        require(sent, 'Error: Cannot withdraw reward, insufficient balance');

        //reset inflight payouts and rewarded payouts
        bnbAlreadyPaid[account] = bnbPerToken.mul(_tokensOwned[account]);
        bnbToPayOut[account] = 0;
        bnbRewarded[account] = bnbRewarded[account].add(reward);
        totalBnbClaimed = totalBnbClaimed.add(reward);

        emit ClaimBNBSuccessfully(account, reward);
    }

    /**
        Event used for debugging purposes during development
     */
    //event LogEvent(address from, address to, address sender, string message);

    /**
        This method is responsible for determining the various pieces of the formula.
        Specifically what is considered "Total Supply". THe total supply used excludes
        both the liquidity wallet, as well as the burn address from calculations, which
        results in more bnb for holders. This method solely returns bnb _previously_ rewarded
        to the recipient that has yet to be claimed. It doesnt not include any in flight transactions
    */
    function calculateBNBRewardBeforePayout(address recipient) public view returns (uint256) {
        uint256 maxPayout = bnbPerToken.mul(_tokensOwned[recipient]); 

        if (maxPayout < bnbAlreadyPaid[recipient]) return 0; //if the max payout is already accounted for, return 0

        //Otherwise, retun the difference between the max payout and whats already been paid out
        //(accounting for the bnb payout multiplier)
        return (maxPayout.sub(bnbAlreadyPaid[recipient])).div(_bnbPerTokenMultiplier);
    }

    /**
        This method is responsible for determining the various pieces of the formula.
        Specifically what is considered "Total Supply". THe total supply used excludes
        both the liquidity wallet, as well as the burn address from calculations, which
        results in more bnb for holders.
    */
    function calculateBNBReward(address recipient) public view returns (uint256) {

        //Otherwise, retun the difference between the max payout and whats already been paid out
        //(accounting for the bnb payout multiplier)
        return calculateBNBRewardBeforePayout(recipient).add(bnbToPayOut[recipient]);
    }

    
    /**
        Take contracts internal balance of CRUSADER and liquidate it on
        Every sell transaction. The resultant BNB will be used in two ways
        Firstly to fuel the liquidity pool, and secondly to provide bnb
        to the reward pool (which is represented by the bnb balnce on the contract)
        itself
     */
    function swapAndLiquify(address from, address to) private {
        //we ensure that we only liquifiy if the following criteria are met:
        //it isnt from this contract to the pancake pair
        //there is enough tokens to liquifiy
        //and fees are enabled
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 totalFee = liquidityFee.add(rewardFee);

        bool shouldSell =   !_inSwapAndLiquify //renetry check
                            && contractTokenBalance >= minTokenNumberToSell //enough token is on contract to liquify
                            && totalFee > 0 //fee has been imposed on the transaction
                            && from != pancakePair //transaction isnt from the pair
                            && !(from == address(this) && to == address(pancakePair)) //transactino isnt between pair and contract
                            && !swapAndLiquifyDisabled; //SaL not disabled
        
        if (!shouldSell) {
            return; //no valid reason to sell
        }

        executeSwapAndLiquify();
    }

    /**
        Take contracts internal balance of CRUSADER and liquidate it on
        Every sell transaction. The resultant BNB will be used in two ways
        Firstly to fuel the liquidity pool, and secondly to provide bnb
        to the reward pool (which is represented by the bnb balnce on the contract)
        itself
     */
    function executeSwapAndLiquify() private lockTheSwap {
        uint256 totalFee = liquidityFee.add(rewardFee);
        uint256 tokensToLiquifiy = minTokenNumberToSell; //always sell for the min amount
        uint256 tokensForLiqudity = (tokensToLiquifiy.mul(liquidityFee)).div(totalFee);
        uint256 tokensForReward = (tokensToLiquifiy.mul(rewardFee)).div(totalFee);

        uint256 toPair = tokensForLiqudity.div(2); //half of the liquitidty tokens must be reserved to be paired
        uint256 toLP = tokensForLiqudity.sub(toPair); //the other half must turn into bnb to pair

        //swap tokens for bnb via pancakeswap
        uint256 initialBnb = address(this).balance;
        uint256 tokensSwappedForBnb = tokensForReward.add(toLP);
        swapTokensForBnb(tokensSwappedForBnb);
        uint256 resultantBnb = address(this).balance.sub(initialBnb);

        
        //add bnb/token pair for liquidityu
        uint bnbForLiquidity = (resultantBnb.mul(toLP)).div(tokensSwappedForBnb);
        addLiquidity(toPair, bnbForLiquidity);

        //lastly distribute the remaining bnb balance (after adding to liquidpool)
        
        //to holders
        uint256 bnbToReward = address(this).balance.sub(initialBnb);

        _rewardHolders(bnbToReward);

        emit SwapAndLiquify(tokensToLiquifiy, resultantBnb, toPair);
    }

    /**
        Used for manual invocation of the auto liquidity logic to turn stored tokens into 
        LP and BNB Rewards for all holders. Does not touch liquidity directly, and is limited
        to Crusader balance of the contract itself.
     */
    function triggerSwapAndLiquify() public onlyOwner {
        //we ensure that we only liquifiy if the following criteria are met:
        //there is enough tokens to liquifiy
        //and and the lock around SaL is met
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell =   !_inSwapAndLiquify 
                            && contractTokenBalance >= minTokenNumberToSell;

        if (!shouldSell) {
            //there is not enough tokens on the contract to trigger a SaL
            //so we do nothing
            return;
        }

        executeSwapAndLiquify();
    }


    /**
        Takes the bnb amount and adds it to the `bnbPerToken` appropriately,
        to reward existing holders
     */
    function _rewardHolders(uint256 bnbAmount) private {
        bnbPerToken = bnbPerToken.add((bnbAmount.mul(_bnbPerTokenMultiplier)).div(getRewardSupply()));
    }

    function swapTokensForBnb(
        uint256 tokenAmount
    ) private {
        // generate the pancake pair path of token -> weth
        _approve(address(this), address(pancakeRouter), tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(
        uint256 tokenAmount,
        uint256 bnbAmount
    ) private {
        // add the liquidity
        _approve(address(this), address(pancakeRouter), tokenAmount);
        pancakeRouter.addLiquidityETH{value : bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    
    function activateContract() public onlyOwner {

        liquidityFee = 5; //5% will be added pool
        rewardFee = 10; //10% will be converted to BNB
        disableSwapAndLiquify(false); //enable auto liquification for LP and BNB distribution
        isTradingEnabled = true;
        transactionLimit = _tTotal.div(200); //set transaction limit to .5% of total supply 
    }
}

