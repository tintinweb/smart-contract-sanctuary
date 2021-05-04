/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// File: libraries/Context.sol

pragma solidity >=0.5.0;

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
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: libraries/Ownable.sol

//pragma solidity ^0.5.0;
pragma solidity >=0.5.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: libraries/SafeERC20.sol

//pragma solidity ^0.7.6;
pragma solidity >=0.5.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

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
// abstract contract Context {
//     function _msgSender() internal view virtual returns (address payable) {
//         return msg.sender;
//     }
//     function _msgData() internal view virtual returns (bytes memory) {
//         this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
//         return msg.data;
//     }
// }
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: libraries/Math.sol

pragma solidity >=0.5.16;

// a library for performing various math operations
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: interfaces/IUniswapV2Pair.sol

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

// File: interfaces/IOracle.sol

pragma solidity ^0.6.12;

interface IOracle {
    event Update(uint256 currPriceMA7, uint256 currPricetime);

    function token0PriceMA7() external view returns (uint256);
    function lastTime() external view returns (uint32);
    // the format of lastTime complies with UniswapV2's uint32 format

}

// File: contracts/Spark.sol

//0.9.2
//1. fixed sqrt [done]
//2. library cleanup [done]
//Final Version:
//1. public to private
//2. comments

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;








/**
 * @title Spark - Sperax Liquidity Mining
 * @author Sperax Dev Team
 * @notice This contract is the main contract for Sperax's liquidity mining program
 */
contract Spark is Ownable {
    using SafeMath for *;
    using SafeERC20 for IERC20;
    using SafeERC20 for IUniswapV2Pair;

    event Staked(address user, uint ID, uint amount);
    event Unstaked(address user, uint ID, uint amount);
    event TokensClaimed(address user, uint ID, uint reward);
    event FreeClaimRequest(address user, uint depositID, uint requestID);
    event FreeClaimExecuted(address user, uint depositID, uint requestID);
    event FreeClaimCancelled(address user, uint depositID, uint requestID);

    struct Deposit {
        uint stakedLP;
        uint timestampSec;
        // the amount of reward claimed from this deposit so far
        uint amountClaimed;
        // the ID of the request if there is one; if not, requestID = 0
        uint requestID;
    }

    struct Profile {
        // the index of the next deposit
        uint nextID;
    }

    struct Request {
        bool isActive;
        // if there is this free-claim request
        address user;
        // the address of the user who has initiated this request
        uint64 index;
        // the index of the deposit this request is for
    }

    struct RequestBoard {
        // the current total number of requests to execute
        uint64 totalRequest;
        // the index of the first request to execute
        uint64 startRequestID;
        // the index of the next request from users
        uint64 nextRequestID;
    }

    //
    // Constant List
    //

    address public constant REWARD_TOKEN_POOL = 0x6B75bF5aC9e5eF2FD01660c3555Aaf015bA24439;
    // all reward tokens are from 0x6B75bF5aC9e5eF2FD01660c3555Aaf015bA24439, i.e. "ecosystem"
    uint public constant APR_PREC = 100;
    // PRECISION = APR_PREC * 100,
    // i.e. the precision of interest rate, APR is 1 / (APR_PREC * 100) = 1 / PRECISION
    //TO-DO: switch back to private
    IUniswapV2Pair public immutable _pair;
    IERC20 public immutable _pair_IERC20;
    IOracle public immutable _priceOracle;
    IERC20 public immutable _rewardToken;

    //
    // Global Stats
    //

    uint public immutable startTimeStamp = now;
    uint public totalLP;
    uint public totalRewardGiven;
    // when "totalRewardGiven" meets "threshold," no new user will be admitted to Spark LM
    // only Owner can modify "threshold," but the modification is restricted to increase only to protect users' interest
    // the initial threshold is 20,000,000 SPAs
    uint public threshold = 2 * 10**25;

    // the past-7-day moving average of token0 price denominated by token0
    // reminder: actual ma7 price = ma7Token0Price >> 112 (compliant with Uniswap)
    uint public ma7Token0Price;
    uint public extDays;
    uint public extAPR;

    // requestBoard records: a. totalRequest; b. startRequestID; c. nextRequestID
    RequestBoard public requestBoard = RequestBoard(0, 1, 1);
    mapping(uint => Request) public _requestMap;

    //
    // User Stats
    //

    //TO-DO: switch back to private
    mapping(address => mapping(uint => Deposit)) public _userDeposits;
    mapping(address => Profile) public _userProfiles;

    //
    // Getters
    //

    function get_userProf(address user) public view returns (uint){
        return (_userProfiles[user].nextID);
    }
    function get_userDepo(address user, uint index) public view returns (uint, uint, uint, uint){
        return (_userDeposits[user][index].stakedLP, _userDeposits[user][index].timestampSec, _userDeposits[user][index].amountClaimed, _userDeposits[user][index].requestID);
    }

    //
    // Constructor
    //

    constructor(address pair_, address oracle_, address rewardToken_) public{
        _pair = IUniswapV2Pair(pair_);
        _pair_IERC20 = IERC20(pair_);
        _priceOracle = IOracle(oracle_);
        _rewardToken = IERC20(rewardToken_);
        ma7Token0Price = IOracle(oracle_).token0PriceMA7();
    }

    //
    // Owner Only Function: incThreshold, extend
    //

    /**
     * @notice increase "threshold" by "incAmount"
     * @dev "incAmount" includes precision, which is usually 10**18
     * @dev only the owner of this contract can call this function
     * @param incAmount the amount to increase for threshold
     */
    function incThreshold(uint incAmount) external onlyOwner {
        threshold = threshold.add(incAmount);
    }

    /**
     * @notice extent the duration of the program by "_extDays" day with "_extAPR" APR in the extended time period
     * @dev only one extension allowed
     * @dev only the owner of this contract can call this function
     * @param _extDays the number of days for which the program is extend
     * @param _extAPR the APR of the extended period
     */
    function extend(uint _extDays, uint _extAPR) external onlyOwner {
        require(_extDays > 0, 'extend: only positive extension duration allowed');
        require(_extAPR > 0, 'extend: only positive APR allowed');
        require(extDays == 0, 'extend: already extended');
        extDays = _extDays;
        extAPR = _extAPR;
    }

    //
    // Core Function: stake
    //

    /**
     * @notice msg.sender stakes a certain amount of LP tokens in Spark
     * @param amount the amount of LP tokens to stake
     * @return id the index of the new deposit
     */
    function stake(uint amount) external returns (uint id) {
        // sanity check
        require(amount > 0, 'stake Error: stake amount is zero.');
        // check if the user is still allowed to join
        require(totalRewardGiven < threshold, "stake Error: threshold has been met. No new deposit is allowed.");
        uint endTimeStamp = startTimeStamp + 28 days + extDays;
        require(now < endTimeStamp, "stake Error: program has ended");
        // update the user and global stats for this interaction
        // 1. update user stats
        id = _userProfiles[msg.sender].nextID;
        Deposit memory newDeposit = Deposit(amount, now, 0, 0);
        _userDeposits[msg.sender][id] = newDeposit;
        _userProfiles[msg.sender].nextID = id + 1;
        // 2. update global stats
        totalLP = totalLP.add(amount);

        // interactions
        _pair_IERC20.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, id, amount);
    }

    //
    // Core Function: _claim, claim, claimBatch
    //

     /**
     * @notice msg.sender claim reward from a certain deposit without withdrawing her LP tokens
     * @dev this is a wrapper of _claim for external usage
     * @param index the index of the chosen deposit
     * @return the amount of reward claimed
     */
    function claim(uint index) public returns (uint) {
        // sanity check
        require(_userDeposits[msg.sender][index].stakedLP > 0, "claim: the deposit does not exist.");

        // check free-claim request
        if (_userDeposits[msg.sender][index].requestID != 0) {
            _cancelFreeClaim(msg.sender, index);
        }

        return _claim(msg.sender, index);
    }

    /**
     * @notice "staker" claim reward from a certain deposit without withdrawing her LP tokens
     * @param staker the address of the staker
     * @param index the index of the chosen deposit
     * @return the amount of reward claimed
     */
    function _claim(address staker, uint index) private returns (uint) {
        // sanity check
        require(_userDeposits[staker][index].stakedLP > 0, "_claim: the deposit does not exist.");

        // sync price from Oracle
        syncPrice();

        // calculate the claimable amount
        uint amountClaimed = _userDeposits[staker][index].amountClaimed;
        uint claimableAmt = computeUnitRewardFor(staker, index).sub(amountClaimed);
        if (claimableAmt <= 0) {
            emit TokensClaimed(staker, index, 0);
            return 0;
        }

        // update user and global stats accordingly
        // 1. update user stats
        _userDeposits[staker][index].amountClaimed = _userDeposits[staker][index].amountClaimed.add(claimableAmt);
        // 2. update global stats
        totalRewardGiven = totalRewardGiven.add(claimableAmt);

        // interaction
        _rewardToken.safeTransferFrom(REWARD_TOKEN_POOL, staker, claimableAmt);

        emit TokensClaimed(staker, index, claimableAmt);

        return claimableAmt;
    }

    /**
     * @notice claim rewards from multiple deposits in a single batch
     * @param indices the array of indices of the deposits from which msg.sender claims rewards
     * @return totalClaimed the total amount of rewards claimed from this batch
     */
    function claimBatch(uint[] memory indices) external returns (uint) {
        // proceed only when all deposits exist
        for (uint i = 0; i < indices.length; i++) {
            require(_userDeposits[msg.sender][indices[i]].stakedLP > 0, "claimBatch: at least one deposit does not exist.");
        }
        // claim one by one
        uint totalClaimed = 0;
        for (uint i = 0; i < indices.length; i++) {
            totalClaimed += claim(indices[i]);
        }
        return totalClaimed;
    }

    //
    // Core Function: claimAndWithdraw， claimAndWithdrawBatch
    //

    /**
     * @notice msg.sender claim rewards and withdraw all LP tokens from a certain deposit
     * @param index the index of the chosen deposit
     * @return claimAmt the amount of reward claimed, withdrawAmt the amount of LP tokens withdrawn
     */
    function claimAndWithdraw(uint index) public returns (uint claimAmt, uint withdrawAmt) {
        // 1. claim, including sanity check, price sync, user & global stats update, etc.
        claimAmt = claim(index);

        // 2. withdraw
        withdrawAmt = _userDeposits[msg.sender][index].stakedLP;
        // update global stats
        totalLP = totalLP.sub(withdrawAmt);
        // update user stats
        delete _userDeposits[msg.sender][index];

        // interaction
        _pair_IERC20.safeTransfer(msg.sender, withdrawAmt);

        emit Unstaked(msg.sender, index, withdrawAmt);
    }

    //
    // Core Function: requestFreeClaim, requestFreeClaimBatch, executeFreeClaim
    //

    /**
     * @notice place a free-claim request for a deposit
     * @dev the tx would be reverted if there is already a request placed on this deposit
     * @param index the index of the deposit the staker wants to put a free-claim request
     */
    function requestFreeClaim(uint index) public {
        // check if the deposit exists
        require(_userDeposits[msg.sender][index].stakedLP > 0, "requestFreeClaim: the deposit does not exist.");
        // check if there is already a request placed before
        require(_userDeposits[msg.sender][index].requestID == 0, "requestFreeClaim: a request has already been placed.");

        // update global request records
        // obtain the current record
        RequestBoard memory newBoard = requestBoard;
        uint id = uint(newBoard.nextRequestID);
        // update the records
        _requestMap[id] = Request(true, msg.sender, uint64(index));
        newBoard.nextRequestID++;
        newBoard.totalRequest++;
        requestBoard = newBoard;

        // update user record
        _userDeposits[msg.sender][index].requestID = id;

        // emit request event
        emit FreeClaimRequest(msg.sender, index, id);
    }

    /**
     * @notice execute free-claim requests
     * @dev only Sperax team can execute free-claim requests, and the team would pay for the gas cost
     * @param numToExe the number of requests to execute in this tx
     */
    function executeFreeClaim(uint numToExe) external onlyOwner {
        // obtain current request board record
        RequestBoard memory newBoard = requestBoard;

        // sanity check
        require(numToExe <= newBoard.totalRequest, "executeFreeClaim: there are not so many requests to execute.");

        // execute each free-claim request one by one
        uint numExecuted = 0;
        Request memory req;
        while (numExecuted < numToExe) {
            // check if the request is still active
            if (_requestMap[newBoard.startRequestID].isActive) {
                // get request info
                req = _requestMap[newBoard.startRequestID];
                (address requester, uint index) = (req.user, uint(req.index));
                // conduct reward claim for the requester for free
                _claim(requester, index);

                // update user record
                _userDeposits[requester][index].requestID = 0;
                // update global records
                delete _requestMap[newBoard.startRequestID];
                newBoard.totalRequest--;
                newBoard.startRequestID++;
                // emit event and count
                emit FreeClaimExecuted(requester, index, newBoard.startRequestID-1);
                numExecuted++;
            } else {
                // the request is inactive, skip it
                newBoard.startRequestID++;
            }
        }

        //update the global request board records
        requestBoard = newBoard;
    }

    /**
     * @notice cancel a previously-placed free-claim request
     * @dev private use only
     * @param staker the owner of the request
     * @param index the index of the deposit this request is about
     */
    function _cancelFreeClaim(address staker, uint index) private {
        require(_userDeposits[staker][index].stakedLP > 0, "_cancelFreeClaim: the deposit does not exist.");
        require(_userDeposits[staker][index].requestID != 0, "_cancelFreeClaim: there is no request on this deposit.");
        // global record
        uint reqID = _userDeposits[staker][index].requestID;
        delete _requestMap[reqID];
        requestBoard.totalRequest--;
        // user record
        _userDeposits[msg.sender][index].requestID = 0;
        // emit event
        emit FreeClaimCancelled(msg.sender, index, reqID);
    }

    //
    // Auxiliary Functions
    //

    /**
     * @notice query latest token0PriveMV7 from Oracle.sol for synchronization
     */
    function syncPrice() public {
        ma7Token0Price = _priceOracle.token0PriceMA7();
    }

    /**
     * @notice compute the reward accumulated so far in the given deposit of the given staker
     * @dev "interest" includes APR_PREC
     * @dev remember to sycn price before computation
     * @param staker the address of the staker to inspect
     * @param index the index of the deposit to inspect
     * @return the accumulated reward denominated in the reward token with precisoin
     */
    function computeUnitRewardFor(address staker, uint index) public view returns (uint) {
        require(_userDeposits[staker][index].stakedLP > 0, "computeUnitRewardFor: the deposit does not exist.");

        // determine the interest rate I, with precision, for this withdrawal
        uint endTimeStamp = startTimeStamp + 28 days + extDays;
        uint timeDay;
        uint depoTimeStamp = _userDeposits[staker][index].timestampSec;
        if (endTimeStamp <= depoTimeStamp) {
          timeDay = 0;
        } else {
          timeDay = (now < endTimeStamp ? now : endTimeStamp).sub(depoTimeStamp).div(1 days);
        }
        uint interest = computeInterestWithPrecision(timeDay);

        // determine the value in SPA for the principal, i.e. "amount" LP tokens
        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        uint principal = computeLPValue(_pair.totalSupply().div(10), _pair.totalSupply(), ma7Token0Price, uint(reserve0).mul(uint(reserve1)));
         //uint principal = computeLPValue(_userDeposits[staker][index].stakedLP, _pair.totalSupply(), ma7Token0Price, uint(reserve0).mul(uint(reserve1)));

        // calculate the reward
        return principal.mul(interest).div(APR_PREC*100);
    }

    /**
     * @notice compute the interest rate when the staking time is t days (w/ or w/o extension)
     * @dev the returned interest rate includes precision
            precison is included in order to perform decimal division
     * @param t the number of days of staking
     * @return the interest rate
     */
    function computeInterestWithPrecision(uint t) public view returns (uint) {
        if (t == 0) {
            //return 0;
            return 200.mul(APR_PREC).mul(5).div(365);
        } else if (t <= 7) {
            return 200.mul(APR_PREC).mul(t).div(365);
        } else if (t <= 14) {
            return (300 * t - 700).mul(APR_PREC).div(365);
            //return (300 * (t - 7)+ 200 * 7).mul(APR_PREC).div(365);
        } else if (t <= 21) {
            return (400 * t - 2100).mul(APR_PREC).div(365);
            //return (400 * (t - 14)+ (200 + 300) * 7).mul(APR_PREC).div(365);
        } else if (t <= 28) {
            return (500 * t - 4200).mul(APR_PREC).div(365);
            //return (500 * (t - 21)+ (200 + 300 + 400) * 7).mul(APR_PREC).div(365);
        } else if (t <= (28 + extDays)) {
            return (extAPR * (t - 28) + 9800).mul(APR_PREC).div(365);
            //return (extAPR * (t - 28) + (200 + 300 + 400 + 500) * 7).mul(APR_PREC).div(365);
        } else {
            return (extAPR * extDays + 9800).mul(APR_PREC).div(365);
            //return (extAPR * extDays  + (200 + 300 + 400 + 500) * 7).mul(APR_PREC).div(365);
        }
    }

    /**
     * @notice compute the underlying value, denominated by token0, of the provided LP tokens
     * @dev value = (amountInLP / poolLP) * sqrt(4 * k * price) = (amountInLP / poolLP) * (price*sqrt(k/price) + sqrt(k*price))
     * @dev both amountInLP and the returned value incldue precision = 10 ** 18
     * @param amountInLP the amount of LP tokens to evaluate
     * @param poolLP the total amount of LP tokens minted for the pair pool
     * @param priceRaw the past-7-day moving average of token0 price denominated by token0 with precison = 2 ** 112
     * @param k the last k in the pair pool
     * @return the value denominated by token0 (with 10**18 precision)
     */
    function computeLPValue(uint amountInLP, uint poolLP, uint priceRaw, uint k) public pure returns (uint) {
        uint sqrtP = Math.sqrt(priceRaw);
        uint sqrtK = Math.sqrt(k);
        uint rawValue = amountInLP.mul(sqrtP).mul(sqrtK).mul(2).div(poolLP);
        return uint(rawValue >> 56);
    }

}