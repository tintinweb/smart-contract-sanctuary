// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.6.12;

interface IMatchPair {
    
    function stake(uint256 _index, address _user,uint256 _amount) external;  // owner
    function untakeToken(uint256 _index, address _user,uint256 _amount) external returns (uint256 _tokenAmount, uint256 _leftAmount);// owner
    // function untakeLP(uint256 _index, address _user,uint256 _amount) external returns (uint256);// owner

    function token(uint256 _index) external view  returns (address);

    //token0 - token1 Amount
    //LP0 - LP1 Amount
    // queue Token0 / token1
    function queueTokenAmount(uint256 _index) external view  returns (uint256);
    // max Accept Amount
    function maxAcceptAmount(uint256 _index, uint256 _molecular, uint256 _denominator, uint256 _inputAmount) external view returns (uint256);

}

pragma solidity 0.6.12;
interface IPriceSafeChecker {
    //checking price ( _reserve0/_reserve1 ) to making sure  in a safe range
    function checkPrice(uint256 _reserve0, uint256 _reserve1) external view ;

     event SettingPriceRang(uint256 _minPriceNumerator, uint256 _minPriceDenominator, uint256 _maxPriceNumerator, uint256 _maxPriceDenominator);
}

pragma solidity 0.6.12;

interface IStakeGatling {

    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function presentRate() external view returns (uint256);
    function totalLPAmount() external view returns (uint256);
    function totalToken() external view returns (uint256 amount0, uint256 amount1);

    function burn(address _to, uint256 _amount) external returns (uint256 amount0, uint256 amount1);
    function lpStakeDst() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../uniswapv2/interfaces/IUniswapV2Pair.sol";
import '../uniswapv2/libraries/UniswapV2Library.sol';
import '../uniswapv2/libraries/TransferHelper.sol';

import "../utils/MasterCaller.sol";
import "../interfaces/IStakeGatling.sol";
import "../interfaces/IMatchPair.sol";
import "../interfaces/IPriceSafeChecker.sol";
import "../storage/MatchPairStorageStableV3.sol";


// Logic layer implementation of MatchPairStableDelegateV8
// diff
// untake token will get two side tokens if lose assets in IL
contract MatchPairStableDelegateV8 is MatchPairStorageStableV3, IMatchPair, Ownable, MasterCaller{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    uint256 private _swapAmount;
    constructor(address _lpAddress) public {
        lpToken = IUniswapV2Pair(_lpAddress);
    }
    function setStakeGatling(address _gatlinAddress) public onlyOwner() {
        //widthdraw All from LP , then update
        if(address(stakeGatling) != address(0)) {
           uint256 requirLp = stakeGatling.totalLPAmount();
            if(requirLp >  0) { // small amount lp cause Exception in UniswapV2.burn();

                (uint256 amount0, uint256 amount1) = untakeLP(0, requirLp);
                _addPendingAmount( 0 ,  amount0);
                _addPendingAmount( 1 ,  amount1);
            } 
        }
        stakeGatling = IStakeGatling(_gatlinAddress);
        updatePool();
    }

    /**
     * @notice Just logic layer
     */
    function stake(uint256 _index, address _user,uint256 _amount) public  override {
        _checkPrice();
        // 1. updateLpAmount
        _updateLpProfit();
        _rebasePoolCalc();
        //
        uint256 totalAmount = totalTokenAmount(_index);
        uint256 totalPoint = _index == 0 ? totalTokenPoint0 : totalTokenPoint1;

        uint256 userPoint;
        {
            if(totalPoint == 0 || totalAmount == 0) {
                userPoint = _amount;
            }else {
                userPoint = _amount.mul(totalPoint).div(totalAmount);
            }
        }
        _addTotalPoint(_index, _user, userPoint);
        _addPendingAmount(_index, _amount);
        updatePool();
    }

    function _addTotalPoint(uint256 _index, address _user, uint256 _amount) private {
        UserInfo storage userInfo = _index == 0? userInfo0[_user] : userInfo1[_user];
        userInfo.tokenPoint = userInfo.tokenPoint.add(_amount);
        if(_index == 0) {
            totalTokenPoint0 = totalTokenPoint0.add(_amount);
        }else {
            totalTokenPoint1 = totalTokenPoint1.add(_amount);
        }
    }

    function rebasePoolExec() public  {
        //updatePending
        (address _token0, address _token1) = (lpToken.token0(), lpToken.token1());
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        pendingToken0 = balance0;
        pendingToken1 = balance1;
        updatePool();
        _rebasePoolCalc();
    }
    // @dev reimburese Asset to user,
    // @para _user : user address
    // @para _amount: _userPoint of IL
    // @para _index: the lose side, will reimburse other side
    function reimburseIlAmount(address _user, uint256 _userPoint, uint256 _side) private returns (uint256) {
        uint256 _index = _side % 2;

        if (_index == 0) {
            require(!tokenProfit0, "Reimburse side token0 no IL loss");
            uint256 _amount = _userAmountByPoint(_userPoint, totalTokenPoint0, tokenPL0);

            uint256 reimAmount =  _amount.mul(tokenPL1).div(tokenPL0);
            tokenPL0 = tokenPL0.sub(_amount);
            tokenPL1 = tokenPL1.sub(reimAmount);
            if(_side >1) {
                // _execSwap(1, reimAmount, _user);
                return reimAmount;
            }else {
                address to = lpToken.token1() == WETH? masterCaller() : _user;
                TransferHelper.safeTransfer(lpToken.token1(), to, reimAmount);
            }
            _subPendingAmount(1, reimAmount);
        } else if( _index == 1 ) {
            require(!tokenProfit1, "Reimburse side token0 no IL loss");
            uint256 _amount = _userAmountByPoint(_userPoint, totalTokenPoint1, tokenPL1);
            uint256 reimAmount =  _amount.mul(tokenPL0).div(tokenPL1);
            tokenPL1 = tokenPL1.sub(_amount);
            tokenPL0 = tokenPL0.sub(reimAmount);

            if(_side >1) {
                return reimAmount;
            }else {
                // send token0 to User
                address to = lpToken.token0() == WETH? masterCaller() : _user;
                TransferHelper.safeTransfer(lpToken.token0(), to, reimAmount);
            }
            _subPendingAmount(0, reimAmount);

        } else {
            revert("Reimburse unavailable side parameter");
        }
    }

    function _rebasePoolCalc() internal {
        uint256 totalLp = stakeGatling.totalLPAmount();

        if(totalLp > sentinelAmount) {

            uint256 _expectAmount0 = totalLp.mul(tokenReserve0).div(totalSupply);
            uint256 _expectAmount1 = totalLp.mul(tokenReserve1).div(totalSupply);
            (uint256 _amount0, uint256 _amount1) = lp2TokenAmountActual(totalLp);
            bool win0 = _amount0 >= _expectAmount0;
            bool win1 = _amount1 >= _expectAmount1;

            uint256 plAmount0 = win0? _amount0 - _expectAmount0 : _expectAmount0 - _amount0 ;
            if(win0 == tokenProfit0) { // same P/L
                tokenPL0 = tokenPL0.add(plAmount0);
            } else {
                if (tokenPL0 >= plAmount0) {
                    tokenPL0 = tokenPL0 - plAmount0;
                } else {
                    tokenPL0 = plAmount0 - tokenPL0;
                    tokenProfit0 = win0;
                }
            }

            // Token1 calculate
            uint256 plAmount1 = win1? _amount1 - _expectAmount1 : _expectAmount1 - _amount1 ;

            if(win1 == tokenProfit1) {
                tokenPL1 = tokenPL1.add(plAmount1);
            } else {
                if (tokenPL1 >= plAmount1) {
                    tokenPL1 = tokenPL1 - plAmount1;
                } else {
                    tokenPL1 = plAmount1 - tokenPL1;
                    tokenProfit1 = win1;
                }
            }
        }
        updateLpPrice();
    }

    function updateLpPrice() private {

        (tokenReserve0, tokenReserve1, ) = lpToken.getReserves();

        totalSupply = lpToken.totalSupply();
    }

    function _getPendingAndPoint(uint256 _index) private returns (uint256 pendingAmount,uint256 totalPoint) {
        if(_index == 0) {
            return (pendingToken0, totalTokenPoint0);
        }else {
            return (pendingToken1, totalTokenPoint1);
        }
    }

    function _getPendingAmount(uint256 _index) private returns (uint256 pendingAmount) {
        if(_index == 0) {
            return pendingToken0;
        }else {
            return pendingToken1;
        }
    }
    
    function updatePool() private {
        uint256 bal0 = IERC20(lpToken.token0()).balanceOf(address(this));
        uint256 bal1 = IERC20(lpToken.token1()).balanceOf(address(this));
        
        if( bal0 > minMintToken0 && bal1 > minMintToken1 ) {

            (uint amountA, uint amountB) = getPairAmount( bal0, bal1 );
            if( amountA > minMintToken0 && amountB > minMintToken1 ) {
                
                TransferHelper.safeTransfer(lpToken.token0(), address(lpToken), amountA);
                TransferHelper.safeTransfer(lpToken.token1(), address(lpToken), amountB);
                if(amountA > pendingToken0) {
                    pendingToken0 = 0;
                } else {
                    pendingToken0 = pendingToken0.sub(amountA);
                }
                if(amountB > pendingToken1) {
                    pendingToken1 = 0;
                } else {
                    pendingToken1 = pendingToken1.sub(amountB);
                }
                //mint LP
                uint liquidity = lpToken.mint(stakeGatling.lpStakeDst());
                //stake Token to Gatling  
                stakeGatling.stake(liquidity);
            }
        }
    }

 
    function getPairAmount(
        uint amountADesired,
        uint amountBDesired  ) private returns ( uint amountA, uint amountB) {

        (uint reserveA, uint reserveB,) = lpToken.getReserves();

        uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }
    // @dev 
    // @return uint256 _withdrawableAmount : the true amount sended to Master.address
    // @return uint256 _leftAmount : the amount user left
    function untakeToken(uint256 _side, address _user, uint256 _amount) 
        public
        override
        returns (uint256 _withdrawableAmount, uint256 _leftAmount) 
    {
        _checkPrice();
        _updateLpProfit();
        _rebasePoolCalc();
        uint256 _index = _side % 2;
        address tokenCurrent = _index == 0 ? lpToken.token0() : lpToken.token1();

        (uint256 totalAmount,  ) = safeTotalTokenAmount(_index, _amount);
        (uint256 pendingAmount, uint256 totalPoint) = _getPendingAndPoint(_index);

        uint256 userAmount = _userAmountByPoint( userPoint(_index, _user) , totalPoint, totalAmount);
        _amount = min(userAmount, _amount);
        
        uint256 pointAmount = _amount.mul(totalPoint).div(totalAmount);

        _withdrawableAmount = _amount;
        //
        bool isIlWiner = _index == 0 ? tokenProfit0 : tokenProfit1;
        burnAll();
        if(!isIlWiner) { // assets lose in IL
            // requireBurnLP to get token0/token1. due to asset had burned, update is necessary
            // burnAll();
            
            _swapAmount = reimburseIlAmount(_user, pointAmount, _side);
            //reset PendingAmount valiavle
            pendingAmount = _getPendingAmount(_index);
            // withdrawable equal userPoint of actualAmount
            (, uint256 actualAmount ) = safeTotalTokenAmount(_index, _amount);
            _withdrawableAmount = _userAmountByPoint(pointAmount, totalPoint, actualAmount);
        }
        pendingAmount = _getPendingAmount(_index);
        {
            if(_withdrawableAmount <=  pendingAmount) {
                _subPendingAmount(_index, _withdrawableAmount);
            }else  {
                uint256 amountRequireViaLp =  _withdrawableAmount.sub(pendingAmount);
                if(_index == 0){
                    pendingToken0 = 0;
                }else {
                    pendingToken1 = 0;
                }
                uint256 amountBurned = burnFromLp(_index, amountRequireViaLp, tokenCurrent);
                _withdrawableAmount = pendingAmount.add(amountBurned);
            }
        }
        _subUserPoint(_index, _user, pointAmount);
        _leftAmount = userAmount.sub(_amount);
        // transfer to Master
        TransferHelper.safeTransfer(tokenCurrent, masterCaller(), _withdrawableAmount);

        updatePool();
        if(_side >1 && _swapAmount > 0) {
            redimeSwap( _index == 0 ? 1 : 0, _swapAmount, _user );
        }
        return(_withdrawableAmount, _leftAmount);
    }

    function redimeSwap(uint256 _indexIn, uint256 _amountIn, address _to ) private {
        uint256 pendingAmount = _indexIn == 0 ? pendingToken0 : pendingToken1;
        if( _amountIn> pendingAmount ) {
            burnFromLp(_indexIn, _amountIn.sub(pendingAmount), token(_indexIn));
        }
        _subPendingAmount(_indexIn, _amountIn);
        _execSwap(_indexIn, _amountIn, _to);
        _swapAmount = 0;
    }

      /**
     * @notice Desire Token via burn LP
     */
    function burnFromLp(uint256 _index, uint256 amountRequireViaLp, address tokenCurrent) private returns(uint256) {

        uint256 lpAmount = IERC20(tokenCurrent).balanceOf(address(lpToken));
        require(lpAmount > 0, "MatchPaireStable: lpAmount not enough");
        uint256 requirLp = amountRequireViaLp.mul(lpToken.totalSupply()).div(lpAmount);
        if(requirLp >  sentinelAmount) { // small amount lp cause Exception in UniswapV2.burn();

            (uint256 amountC, uint256 amountOther) = untakeLP(_index, requirLp);

            _addPendingAmount( (_index +1)%2 ,  amountOther);
            return amountC;
        }
    }


    function burnAll() private returns(uint256) {

        uint256 requirLp = stakeGatling.totalLPAmount();
        if(requirLp >  sentinelAmount) { // small amount lp cause Exception in UniswapV2.burn();

           (uint256 amount0, uint256 amount1) = untakeLP(0, requirLp);
            _addPendingAmount( 0 ,  amount0);
            _addPendingAmount( 1 ,  amount1);
        }
    }

    function _execSwap(uint256 indexIn, uint256 amountIn, address _to) private returns(uint256 amountOunt) {

        if(amountIn > 0) {
            amountOunt = _getAmountVoutIndexed( indexIn,  amountIn);
            (address sellToken, address forToken) = indexIn == 0? (lpToken.token0(), lpToken.token1()) : (lpToken.token1(), lpToken.token0());
            TransferHelper.safeTransfer(sellToken, address(lpToken), amountIn);
             uint256 zero;
            (uint256 amount0Out, uint256 amount1Out ) = indexIn == 0 ? (zero, amountOunt ) : (amountOunt, zero);
            bool isWEHT = forToken == WETH;
            //WETH will transfer to Master,then Master withdraw and transfer to User
            lpToken.swap(amount0Out, amount1Out, isWEHT ? masterCaller() : _to, new bytes(0));
        }
    }

     function _getAmountVoutIndexed(uint256 _inIndex, uint256 _amountIn ) private returns(uint256 amountOut) {
        (uint256 _reserveIn, uint256 _reserveOut, ) = lpToken.getReserves();
        if(_inIndex == 1) {
            (_reserveIn, _reserveOut) = (_reserveOut, _reserveIn);
        }
        amountOut = _getAmountOut(_amountIn, _reserveIn, _reserveOut);
    }


    function _getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {

        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function _burnLp(uint256 _index, uint256 _lpAmount) private returns (uint256 tokenCurrent, uint256 tokenPaired) {
        //no precheck before call this function
        if(_lpAmount > sentinelAmount) {
            (tokenCurrent, tokenPaired) = stakeGatling.burn(address(this), _lpAmount);
            if(_index == 1) {
                (tokenCurrent, tokenPaired) = (tokenPaired, tokenCurrent );
            }
        }
    }

    /**
     * @notice price feeded by  Oracle
     */
    function _checkPrice() private {

        if(address(priceChecker) != address(0) ) {
            (uint reserve0, uint reserve1,) = lpToken.getReserves();
            priceChecker.checkPrice(reserve0, reserve1);
        }
    }
    /**
     * @notice Compound interest calculation in Gatling layer
     */
    function _updateLpProfit() private {
        stakeGatling.withdraw(0);
    }

    function _subPendingAmount(uint256 _index, uint256 _amount) private {
        if(_index == 0) {
            pendingToken0 = pendingToken0.sub(_amount);
        }else {
            pendingToken1 = pendingToken1.sub(_amount);
        }
    }

    function _addPendingAmount(uint256 _index, uint256 _amount) private {
        if(_index == 0) {
            pendingToken0 = pendingToken0.add(_amount);
        }else {
            pendingToken1 = pendingToken1.add(_amount);
        }
    }

    function _subUserPoint(uint256 _index, address _user, uint256 _amount) private {
        UserInfo storage userInfo = _index == 0? userInfo0[_user] : userInfo1[_user];
        userInfo.tokenPoint = userInfo.tokenPoint.sub(_amount);

        if(_index == 0) {
            totalTokenPoint0 = totalTokenPoint0.sub(_amount);
        }else {
            totalTokenPoint1 = totalTokenPoint1.sub(_amount);
        }
    }

    function untakeLP(uint256 _index,uint256 _untakeLP) private returns (uint256 amountC, uint256 amountPaired) {
        
        (amountC, amountPaired) = stakeGatling.burn(address(this), _untakeLP);
        if(_index == 1) {
             (amountC , amountPaired) = (amountPaired, amountC);
        }
    }
    
    function token(uint256 _index) public view override returns (address) {
        return _index == 0 ? lpToken.token0() : lpToken.token1();
    }

    function lPAmount(uint256 _index, address _user) public view returns (uint256) {
        uint256 totalPoint = _index == 0? totalTokenPoint0 : totalTokenPoint1;
        return stakeGatling.totalLPAmount().mul(userPoint(_index, _user)).div(totalPoint);
    }

    function tokenAmount(uint256 _index, address _user) public view returns (uint256) {
        uint256 totalPoint = _index == 0? totalTokenPoint0 : totalTokenPoint1;
        // uint256 pendingAmount = _index == 0? pendingToken0 : pendingToken1;
        // todo mock:: both amount show via method.tokenAmount()
        uint256 pendingAmount = totalTokenAmount(_index);

        uint256 userPoint = userPoint(_index, _user);
        return _userAmountByPoint(userPoint, totalPoint, pendingAmount);
    }

    function userPoint(uint256 _index, address _user) public view returns (uint256) {
        UserInfo storage user = _index == 0? userInfo0[_user] : userInfo1[_user];
        return user.tokenPoint;
    }

    function _userAmountByPoint(uint256 _point, uint256 _totalPoint, uint256 _totalAmount ) 
        private pure returns (uint256) {
        if(_totalPoint == 0) {
            return 0;
        }
        return _point.mul(_totalAmount).div(_totalPoint);
    }

    function queueTokenAmount(uint256 _index) public view override  returns (uint256) {
        return _index == 0 ? pendingToken0: pendingToken1;
    }

    function safeTotalTokenAmount(uint256 _index, uint256 _withdrawAmount) private view returns (uint256 expectTotalAmount, uint256 actualTotalAmount ) {
        (uint256 amount0, uint256 amount1) = stakeGatling.totalToken();
        if(_index == 0) {
            actualTotalAmount = amount0.add(pendingToken0);
            expectTotalAmount = tokenProfit0 ? actualTotalAmount.sub(tokenPL0) : actualTotalAmount.add(tokenPL0);
        }else {
            actualTotalAmount = amount1.add(pendingToken1);
            expectTotalAmount = tokenProfit1 ? actualTotalAmount.sub(tokenPL1) : actualTotalAmount.add(tokenPL1);
        }
    }

    function totalTokenAmount(uint256 _index) private view  returns (uint256) {
        uint256 totalLp = stakeGatling.totalLPAmount();
        if(_index == 0) {
            uint256 _expectAmount0 = totalLp.mul(tokenReserve0).div(totalSupply);
            uint256 nativeAmount = _expectAmount0.add(pendingToken0);
            uint256 result = tokenProfit0 ? nativeAmount.sub(tokenPL0) : nativeAmount.add(tokenPL0);
            return result;
        
        }else {
            uint256 _expectAmount1 = totalLp.mul(tokenReserve1).div(totalSupply);
            uint256 nativeAmount = _expectAmount1.add(pendingToken1);
            uint256 result = tokenProfit1 ? nativeAmount.sub(tokenPL1) : nativeAmount.add(tokenPL1);
            return result;  
        }
    }

    /**
     *
     */
    function lp2TokenAmountActual(uint256 _liquidity) public view  returns (uint256 amount0, uint256 amount1) {
        uint256 _totalSupply = lpToken.totalSupply();
        (address _token0, address _token1) = (lpToken.token0(), lpToken.token1());

        uint balance0 = IERC20(_token0).balanceOf(address(lpToken));
        uint balance1 = IERC20(_token1).balanceOf(address(lpToken));
        amount0 = _liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = _liquidity.mul(balance1) / _totalSupply;
    }
    function lp2TokenAmount(uint256 _liquidity) public view  returns (uint256 amount0, uint256 amount1) {

        amount0 = _liquidity.mul(tokenReserve0) / totalSupply; // using balances ensures pro-rata distribution
        amount1 = _liquidity.mul(tokenReserve1) / totalSupply;
    }

    function maxAcceptAmount(uint256 _index, uint256 _molecular, uint256 _denominator, uint256 _inputAmount) public view override returns (uint256) {
        
        (uint256 amount0, uint256 amount1) = stakeGatling.totalToken();

        uint256 pendingTokenAmount = _index == 0 ? pendingToken0 : pendingToken1;
        uint256 lpTokenAmount =  _index == 0 ? amount0 : amount1;

        require(lpTokenAmount.mul(_molecular).div(_denominator) > pendingTokenAmount, "Amount in pool less than PendingAmount");
        uint256 maxAmount = lpTokenAmount.mul(_molecular).div(_denominator).sub(pendingTokenAmount);
        
        return _inputAmount > maxAmount ? maxAmount : _inputAmount ; 
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b :a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "../interfaces/IStakeGatling.sol";
import "../interfaces/IPriceSafeChecker.sol";
import "../uniswapv2/interfaces/IUniswapV2Pair.sol";

// Storage layer implementation of MatchPairStableV2
contract MatchPairStorageStableV3 {
    
    uint256 public constant PROXY_INDEX = 4;
    IUniswapV2Pair public lpToken;
    IStakeGatling public stakeGatling;
    IPriceSafeChecker public priceChecker;

    address public admin;

    struct UserInfo{
        address user;
        //actual fund point
        uint256 tokenPoint;
    }
    // had profited via impermanence loss
    bool public tokenProfit0;
    bool public tokenProfit1;
    // cover impermanence loss P/L value
    uint256 public tokenPL0;
    uint256 public tokenPL1;
    // retrieve LP priced value via tokenReserve0/totalSupply
    uint256 public tokenReserve0;
    uint256 public tokenReserve1;
    uint256 public totalSupply;

    uint256 public pendingToken0;
    uint256 public pendingToken1;
    uint256 public totalTokenPoint0;
    uint256 public totalTokenPoint1;

    // in UniswapV2.burn() call ,small LP cause Exception('UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED')
    uint256 public sentinelAmount = 500;
    // filter too small asset, saving gas
    uint256 public minMintToken0;
    uint256 public minMintToken1;

    mapping(address => UserInfo) public userInfo0;
    mapping(address => UserInfo) public userInfo1;

    event Stake(bool _index0, address _user, uint256 _amount);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

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

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

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
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';
import '../interfaces/IUniswapV2Factory.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair  =  IUniswapV2Factory(factory).getPair(token0, token1);
        
        // = address(uint(keccak256(abi.encodePacked(
        //         hex'ff',
        //         factory,
        //         keccak256(abi.encodePacked(token0, token1)),
        //         hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
        //     ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract MasterCaller {
    address private _master;

    event MastershipTransferred(address indexed previousMaster, address indexed newMaster);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _master = msg.sender;
        emit MastershipTransferred(address(0), _master);
    }

    /**
     * @dev Returns the address of the current MasterCaller.
     */
    function masterCaller() public view returns (address) {
        return _master;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMasterCaller() {
        require(_master == msg.sender, "Master: caller is not the master");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferMastership(address newMaster) public virtual onlyMasterCaller {
        require(newMaster != address(0), "Master: new owner is the zero address");
        emit MastershipTransferred(_master, newMaster);
        _master = newMaster;
    }
}