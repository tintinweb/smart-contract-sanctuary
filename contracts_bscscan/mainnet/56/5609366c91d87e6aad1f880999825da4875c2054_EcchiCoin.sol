/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

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
    function allowance(address owner, address spender)
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

// File: openzeppelin-solidity\contracts\utils\Address.sol

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

// File: node_modules\openzeppelin-solidity\contracts\utils\Context.sol

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity\contracts\access\Ownable.sol

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

// File: contracts\EcchiCoin-flatten.sol

pragma solidity ^0.8.0;

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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

contract EcchiCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10000 * 10**6 * 10**9; // True total
    uint256 private _rTotal = (MAX - (MAX % _tTotal)); // Reflected Total
    uint256 private _tFeeTotal;

    string private constant _name = "EcchiCoin";
    string private constant _symbol = "ECCHI";
    uint8 private constant _decimals = 9;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 4;
    uint256 private _previousLiquidityFee = _liquidityFee;

    ////////////////////////////////// TEAM FEE (8%) ///////////////////////////////////
    uint256 public _rewardFee = 3;
    uint256 private _previousRewardFee = _rewardFee;
    address private _rewardFeeAddress =
        address(0x4bE569348cd829C5816b1622144349D1b3868512);

    uint256 public _marketingFee = 1;
    uint256 private _previousMarketingFee = _marketingFee;
    address private _marketingFeeAddress =
        address(0xb9856A4128d762E008948E393DADA7c0C80f546f);

    uint256 public _animeFee = 2;
    uint256 private _previousDevFee = _animeFee;
    address private _animeFeeAddress =
        address(0x868Bc583305405130Cb8B1692DAa3bA0e3Be5CDb);

    address private _stakingWallet = 0x06AC76657Bd3157F47a9e839AaA648B5C34A7D0A;
    address private _devWallet = 0x0FeBc88E7C4b8F231F071770e2b1D8b64b70f47B;
    /////////////////////////////////////////////////////////////////////

    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxAmount = _tTotal.mul(3).div(10**3); //0.3% Max Tranaction For Anti-Whaling
    uint256 private numTokensSellToAddToLiquidity = 20 * 10**6 * 10**9;

    uint256 private deadBlocks = 5;
    uint256 private launchedAt = 0;

    IERC20 private BUSDAddress =
        IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(IERC20 _BUSDAddress) {
        BUSDAddress = _BUSDAddress;

        _rOwned[_msgSender()] = _rTotal;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        // Create a uniswap pair for this new token
        address _pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), address(BUSDAddress));
        pancakePair = _pancakePair;

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_rewardFeeAddress] = true;
        _isExcludedFromFee[_marketingFeeAddress] = true;
        _isExcludedFromFee[_animeFeeAddress] = true;

        // exclude owner and tax wallets from rewards
        excludeFromReward(owner());
        excludeFromReward(address(this));
        excludeFromReward(_rewardFeeAddress);
        excludeFromReward(_marketingFeeAddress);
        excludeFromReward(_animeFeeAddress);
        excludeFromReward(_pancakePair);

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "There is no Balance!");

        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

    function withdrawBUSD() public onlyOwner {
        require(
            BUSDAddress.balanceOf(address(this)) > 0,
            "There is no BUSD Balance!"
        );

        BUSDAddress.transfer(owner(), BUSDAddress.balanceOf(address(this)));
    }

    function changeSwapThreshold(uint256 _numTokensSellToAddToLiquidity)
        public
        onlyOwner
    {
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }

    // function deliver(uint256 tAmount) public {
    //     address sender = _msgSender();
    //     require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    //     (uint256 rAmount,,,,,) = _getValues(tAmount);
    //     _rOwned[sender] = _rOwned[sender].sub(rAmount);
    //     _rTotal = _rTotal.sub(rAmount);
    //     _tFeeTotal = _tFeeTotal.add(tAmount);
    // }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
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

    function setTaxFeePercent(uint256 taxFee) public onlyOwner {
        require(taxFee <= 2, "Can't be higher than 2%");
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) public onlyOwner {
        require(liquidityFee <= 5, "Can't be higher than 5%");
        _liquidityFee = liquidityFee;
    }

    /**
     * @dev This function can be used to maxTxAmount and value should be percentage * 10
     * @param maxTxPercent The new max transaction percentage
     */
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent >= 2, "Max can't be below 0.2%");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**3);
    }

    function setStakingWalletAddress(address stakingWallet) external onlyOwner {
        _stakingWallet = stakingWallet;
    }

    function setDevWalletAddress(address devWallet) external onlyOwner {
        _devWallet = devWallet;
    }

    /**
     * @dev This function can be used to change all fees
     * @param taxFee The new tax fee percentage
     * @param liquidityFee The new liquidity fee percentage
     * @param rewardFee The new reward fee percentage
     * @param marketingFee The new marketing fee percentage
     * @param animeFee The new anime fee percentage
     */
    function setNewFees(
        uint256 taxFee,
        uint256 liquidityFee,
        uint256 rewardFee,
        uint256 marketingFee,
        uint256 animeFee
    ) external onlyOwner {
        require(taxFee <= 2, "Tax can't be higher than 2%");
        require(liquidityFee <= 5, "Liquidity can't be higher than 5%");
        require(rewardFee <= 3, "Rewards can't be higher than 3%");
        require(marketingFee <= 1, "Marketing can't be higher than 1%");
        require(animeFee <= 5, "Anime can't be higher than 5%");
        setTaxFeePercent(taxFee);
        setLiquidityFeePercent(liquidityFee);
        _rewardFee = rewardFee;
        _marketingFee = marketingFee;
        _animeFee = animeFee;
    }

    /**
     * @dev Owner allowed to update rewardFee, marketingFee and address
     * @param rewardFee reward fee
     * @param rewardFeeAddress  rewardFee address
     * @param marketingFee marketing fee
     * @param marketingFeeAddress marketingFee Address
     */
    function setMarketingFee(
        uint256 rewardFee,
        address rewardFeeAddress,
        uint256 marketingFee,
        address marketingFeeAddress
    ) external onlyOwner {
        require(rewardFee <= 3, "Rewards can't be higher than 3%");
        require(marketingFee <= 1, "Marketing can't be higher than 1%");
        _rewardFee = rewardFee;
        _marketingFee = marketingFee;
        // Include Old Team Fee Addresses to Fee Address List
        includeInFee(_rewardFeeAddress);
        includeInReward(_rewardFeeAddress);
        includeInFee(_marketingFeeAddress);
        includeInReward(_marketingFeeAddress);
        _rewardFeeAddress = rewardFeeAddress;
        _marketingFeeAddress = marketingFeeAddress;
        // Exclude New Team Fee Addresses From Fee Address List
        excludeFromFee(_rewardFeeAddress);
        excludeFromReward(_rewardFeeAddress);
        excludeFromFee(_marketingFeeAddress);
        excludeFromReward(_marketingFeeAddress);
    }

    function setAnimeFee(uint256 animeFee, address animeFeeAddress)
        external
        onlyOwner
    {
        require(animeFee <= 5, "Anime can't be higher than 5%");
        _animeFee = animeFee;
        includeInFee(_animeFeeAddress);
        includeInReward(_animeFeeAddress);
        _animeFeeAddress = animeFeeAddress;
        excludeFromFee(_animeFeeAddress);
        excludeFromReward(_animeFeeAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to receive ETH from pancakeRouter when swapping
    receive() external payable {}

    /**
     * @dev Calculates the fees and returns the amount left, and individual fees
     * @param rFee The reflected fee
     * @param tFee The holder fee
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    /**
     * @dev Calculates the fees and returns the amount left, and individual fees
     * @param tAmount The total amount
     * @return uint256 The transfer amount, minus the fees
     * @return uint256 The holder fee
     * @return uint256 The liquidity fee
     * @return uint256 The team's fee (Reward, Marketing, Dev)
     */
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tTeamTax
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tTeamTax,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    /**
     * @dev Calculates the tFee , tTransferAmount liquidity and team tax
     * @param tAmount The total amount
     * @return uint256 The transfer amount, minus the fees
     * @return uint256 The holder fee
     * @return uint256 The liquidity fee
     * @return uint256 The team's fee (Reward, Marketing, Dev)
     */
    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tTotalTxFee = 0;
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        (uint256 tRewardFee, uint256 tMarketingFee) = calculateMarketingFee(
            tAmount
        );
        uint256 tDevFee = calculateDevFee(tAmount);
        uint256 tTeamTax = tRewardFee.add(tMarketingFee).add(tDevFee);
        tTotalTxFee = tTotalTxFee.add(tFee);
        tTotalTxFee = tTotalTxFee.add(tLiquidity);
        tTotalTxFee = tTotalTxFee.add(tTeamTax);

        uint256 tTransferAmount = tAmount.sub(tTotalTxFee);
        return (tTransferAmount, tFee, tLiquidity, tTeamTax);
    }

    /**
     * @dev calculates and returns values of rAmount(reflected Amount), rTransferAmount(determined by rTransferAmount = [rAmount] - [rFee] and rFee(detemined by formuyla [rFee] = tFee * currrentRate)
     * @param tAmount The total amount
     * @param tFee The holder Fee
     * @param tLiquidity The liquidity Fee
     * @param tTeamTax The team's fee (Reward, Marketing, Dev)
     * @param currentRate The holder Fee
     * @return uint256 rAmount (reflected Amount)
     * @return uint256 The holder fee
     * @return rfee = tFee * currentRate(determined by rTotal/tTotal)
     */
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tTeamTax,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rTotalTxFee = 0;
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTeamTax = tTeamTax.mul(currentRate);
        rTotalTxFee = rTotalTxFee.add(rFee);
        rTotalTxFee = rTotalTxFee.add(rLiquidity);
        rTotalTxFee = rTotalTxFee.add(rTeamTax);

        uint256 rTransferAmount = rAmount.sub(rTotalTxFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /**
     * @dev returns ratio of rsupply(reflected supply) and tsupply(total supply)
     * @return uint256 rsupply
     */
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function launch() internal {
        if (launchedAt == 0) {
            launchedAt = block.number;
        }
    }

    /**
     * @dev Calculates and returns rSupply(reflected supply) and tsupply(true supply)
     * @return uint256 rsupply
     * @return uint256 tsupply
     */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /**
     * @dev Private function to take liquidity
     * @param tLiquidity Liquidity fee
     */
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    /**
     * @dev Calculates and returns Tax fee
     * @param _amount Amount of Token
     * @return uint256 Tax Fee
     */
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    /**
     * @dev Calculates and returns liquidity fee
     * @param _amount Amount of Token
     * @return uint256 liquidity Fee
     */
    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    /**
     * @dev Calculates and returns rewadFee and marketingFee
     * @param _amount Amount of Token
     * @return uint256 Reward fee
     * @return uint256 Marketing Fee
     */
    function calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256, uint256)
    {
        return (
            _amount.mul(_rewardFee).div(10**2),
            _amount.mul(_marketingFee).div(10**2)
        );
    }

    /**
     * @dev Calculates and returns DevFee
     * @param _amount Amount of Token
     * @return uint256 Dev Fee
     */
    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_animeFee).div(10**2);
    }

    function adjustFees() private {
        if (launched() && (launchedAt + deadBlocks) > block.number) {
            _previousTaxFee = _taxFee;
            _previousLiquidityFee = _liquidityFee;
            _previousRewardFee = _rewardFee;
            _previousMarketingFee = _marketingFee;
            _previousDevFee = _animeFee;

            _taxFee = 0;
            _liquidityFee = 99;
            _rewardFee = 0;
            _marketingFee = 0;
            _animeFee = 0;
        }
    }

    /**
     * @dev Sets all fees to zero
     */
    function removeAllFee() private {
        if (
            _taxFee == 0 &&
            _liquidityFee == 0 &&
            _rewardFee == 0 &&
            _marketingFee == 0 &&
            _animeFee == 0
        ) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousRewardFee = _rewardFee;
        _previousMarketingFee = _marketingFee;
        _previousDevFee = _animeFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _rewardFee = 0;
        _marketingFee = 0;
        _animeFee = 0;
    }

    /**
     * @dev Restores all fees to default
     */
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _rewardFee = _previousRewardFee;
        _marketingFee = _previousMarketingFee;
        _animeFee = _previousDevFee;
    }

    /**
     * @dev this function is responsible check address is excluded from fee
     * @param account address to check
     * @return bool boolean value in reponse
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @dev this function is responsible check anti-whaling feature prevents holders owning more than 5% of the total circulating supply.
     * @param account address to check
     * @return bool boolean value in reponse
     */
    function isWalletOverFlow(address account, uint256 amount)
        public
        view
        returns (bool)
    {
        if (
            account == _rewardFeeAddress ||
            account == _marketingFeeAddress ||
            account == _animeFeeAddress ||
            account == _stakingWallet ||
            account == _devWallet
        ) return false;
        if (balanceOf(account) + amount >= totalSupply().div(20)) return true;
        return false;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function launched() public view returns (bool) {
        return launchedAt != 0;
    }

    function checkLaunched(address _from) private view {
        require(
            launched() || _isExcludedFromFee[_from],
            "Pre-Launch Protection"
        );
    }

    function setDeadBlocks(uint256 _deadBlocks) public onlyOwner {
        require(_deadBlocks > 3 && _deadBlocks < 11);
        deadBlocks = _deadBlocks;
    }

    /**
     * @dev this function is responsible to transfer amount of tokens
     * @param from The sender
     * @param to The recepient
     * @param amount amount of tokens
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        checkLaunched(from);

        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            require(
                !isWalletOverFlow(to, amount),
                "Receiver balance is over than 5% of Total Balance"
            );
        }

        if (!launched() && to == pancakePair) {
            require(balanceOf(from) > 0, "Balance too low");
            launch();
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            // swapAndLiquify(contractTokenBalance);
            swapAndLiquifyBUSD(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    /**
     * @dev this method is responsible for creating swap for ETH and adding liquidity
     * @param contractTokenBalance Contract balance
     */
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /**
     * @dev this method is responsible for creating swap for BUSD and adding liquidity
     * @param contractTokenBalance Contract balance
     */
    function swapAndLiquifyBUSD(uint256 contractTokenBalance)
        private
        lockTheSwap
    {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        // uint256 initialBalance = address(this).balance;
        uint256 initialBUSDBalance = BUSDAddress.balanceOf(address(this));

        // swap tokens for ETH
        // swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        swapTokensForBUSD(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        // uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 newBUSDBalance = BUSDAddress.balanceOf(address(this)).sub(
            initialBUSDBalance
        );

        // add liquidity to uniswap
        // addLiquidity(otherHalf, newBalance);
        addLiquidityBUSD(otherHalf, newBUSDBalance);

        emit SwapAndLiquify(half, newBUSDBalance, otherHalf);
    }

    /**
     * @dev this method is responsible for swaping tokens in return of ETH
     * @param tokenAmount amount of token to swap
     */
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev this method is responsible for swaping tokens in return of BUSD
     * @param tokenAmount amount of token to swap
     */
    function swapTokensForBUSD(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> BUSD
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(BUSDAddress);

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BUSD
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev this method is responsible for adding liquidity
     * @param tokenAmount amount of token to authorize pancakeRouter
     * @param bnbAmount amount of ETH did we just swap into
     * @return uint256 amount of tokens
     * @return uint256 ETH value
     * @return uint256 The liquidity
     */
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount)
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        (uint256 amountToken, uint256 amountBNB, uint256 liquidity) = pancakeRouter
            .addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        return (amountToken, amountBNB, liquidity);
    }

    /**
     * @dev this method is responsible for adding liquidity for BUSD
     * @param tokenAmount amount of token to authorize pancakeRouter
     * @param BUSDAmount amount of BUSD did we just swap into
     * @return uint256 amount of tokens
     * @return uint256 BUSD value
     * @return uint256 The liquidity
     */
    function addLiquidityBUSD(uint256 tokenAmount, uint256 BUSDAmount)
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);
        BUSDAddress.approve(address(pancakeRouter), BUSDAmount);

        // add the liquidity
        (uint256 amountToken, uint256 amountBUSD, uint256 liquidity) = pancakeRouter
            .addLiquidity(
                address(this),
                address(BUSDAddress),
                tokenAmount,
                BUSDAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(this), //owner(), --- Fixed From Audit Report
                block.timestamp
            );

        return (amountToken, amountBUSD, liquidity);
    }

    /**
     * @dev this method is responsible for taking all fee, if takeFee is true
     * @param sender from
     * @param recipient to
     * @param amount amount of tokens
     * @param takeFee bool variable to determine about fee
     */
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (takeFee) adjustFees();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        restoreAllFee();
    }

    /**
     * @dev This function is responsible to taking all the tax fees
     * @param tRewardFee reward fee
     * @param tMarketingFee marketing fee
     * @param tDevFee Dev fee
     * @param currentRate current rate (rTotal / tTotal)
     */
    function _transferTeamTax(
        uint256 tRewardFee,
        uint256 tMarketingFee,
        uint256 tDevFee,
        uint256 currentRate
    ) private {
        if (_isExcluded[_rewardFeeAddress]) {
            _tOwned[_rewardFeeAddress] = _tOwned[_rewardFeeAddress].add(
                tRewardFee
            );
            _rOwned[_rewardFeeAddress] = _rOwned[_rewardFeeAddress].add(
                tRewardFee.mul(currentRate)
            );
        } else {
            _rOwned[_rewardFeeAddress] = _rOwned[_rewardFeeAddress].add(
                tRewardFee.mul(currentRate)
            );
        }

        if (_isExcluded[_marketingFeeAddress]) {
            _tOwned[_marketingFeeAddress] = _tOwned[_marketingFeeAddress].add(
                tMarketingFee
            );
            _rOwned[_marketingFeeAddress] = _rOwned[_marketingFeeAddress].add(
                tMarketingFee.mul(currentRate)
            );
        } else {
            _rOwned[_marketingFeeAddress] = _rOwned[_marketingFeeAddress].add(
                tMarketingFee.mul(currentRate)
            );
        }

        if (_isExcluded[_animeFeeAddress]) {
            _tOwned[_animeFeeAddress] = _tOwned[_animeFeeAddress].add(tDevFee);
            _rOwned[_animeFeeAddress] = _rOwned[_animeFeeAddress].add(
                tDevFee.mul(currentRate)
            );
        } else {
            _rOwned[_animeFeeAddress] = _rOwned[_animeFeeAddress].add(
                tDevFee.mul(currentRate)
            );
        }
    }

    /**
     * @dev Transfers when sender and recipient are not Excluded from reward
     * @param sender from
     * @param recipient to
     * @param tAmount Amount of tokens
     */
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        (uint256 tRewardFee, uint256 tMarketingFee) = calculateMarketingFee(
            tAmount
        );
        uint256 tAnimeFee = calculateDevFee(tAmount);
        _transferTeamTax(tRewardFee, tMarketingFee, tAnimeFee, _getRate());

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, _rewardFeeAddress, tRewardFee);
        emit Transfer(sender, _marketingFeeAddress, tMarketingFee);
        emit Transfer(sender, _animeFeeAddress, tAnimeFee);
    }

    /**
     * @dev Transfers when recipient is Excluded from reward
     * @param sender from
     * @param recipient to
     * @param tAmount Amount of tokens
     */
    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        (uint256 tRewardFee, uint256 tMarketingFee) = calculateMarketingFee(
            tAmount
        );
        uint256 tAnimeFee = calculateDevFee(tAmount);
        _transferTeamTax(tRewardFee, tMarketingFee, tAnimeFee, _getRate());

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, _rewardFeeAddress, tRewardFee);
        emit Transfer(sender, _marketingFeeAddress, tMarketingFee);
        emit Transfer(sender, _animeFeeAddress, tAnimeFee);
    }

    /**
     * @dev Transfers when sender is Excluded from reward
     * @param sender from
     * @param recipient to
     * @param tAmount Amount of tokens
     */
    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        (uint256 tRewardFee, uint256 tMarketingFee) = calculateMarketingFee(
            tAmount
        );
        uint256 tAnimeFee = calculateDevFee(tAmount);
        _transferTeamTax(tRewardFee, tMarketingFee, tAnimeFee, _getRate());

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, _rewardFeeAddress, tRewardFee);
        emit Transfer(sender, _marketingFeeAddress, tMarketingFee);
        emit Transfer(sender, _animeFeeAddress, tAnimeFee);
    }

    /**
     * @dev Transfers when sender and recipient both are Excluded from reward
     * @param sender from
     * @param recipient to
     * @param tAmount Amount of tokens
     */
    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        (uint256 tRewardFee, uint256 tMarketingFee) = calculateMarketingFee(
            tAmount
        );
        uint256 tAnimeFee = calculateDevFee(tAmount);
        _transferTeamTax(tRewardFee, tMarketingFee, tAnimeFee, _getRate());

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, _rewardFeeAddress, tRewardFee);
        emit Transfer(sender, _marketingFeeAddress, tMarketingFee);
        emit Transfer(sender, _animeFeeAddress, tAnimeFee);
    }
}