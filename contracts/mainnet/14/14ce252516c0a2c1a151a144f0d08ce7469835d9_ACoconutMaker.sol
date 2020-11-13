// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;


// 
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

// 
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

// 
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

// 
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

// 
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

    constructor () internal {
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

// 
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * Credit: https://github.com/OpenZeppelin/openzeppelin-upgrades/blob/master/packages/core/contracts/Initializable.sol
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// 
/**
 * @notice Interface for ERC20 token which supports minting new tokens.
 */
interface IERC20Mintable is IERC20 {
    
    function mint(address _user, uint256 _amount) external;

}

// 
/**
 * @notice Interface for ERC20 token which supports mint and burn.
 */
interface IERC20MintableBurnable is IERC20Mintable {
    
    function burn(address _user, uint256 _amount) external;
}

// 
/**
 * @notice ACoconut swap.
 */
contract ACoconutSwap is Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Token swapped between two underlying tokens.
     */
    event TokenSwapped(address indexed buyer, address indexed tokenSold, address indexed tokenBought, uint256 amountSold, uint256 amountBought);
    /**
     * @dev New pool token is minted.
     */
    event Minted(address indexed provider, uint256 mintAmount, uint256[] amounts, uint256 feeAmount);
    /**
     * @dev Pool token is redeemed.
     */
    event Redeemed(address indexed provider, uint256 redeemAmount, uint256[] amounts, uint256 feeAmount);
    /**
     * @dev Fee is collected.
     */
    event FeeCollected(address indexed feeRecipient, uint256 feeAmount);

    uint256 public constant feeDenominator = 10 ** 10;
    address[] public tokens;
    uint256[] public precisions; // 10 ** (18 - token decimals)
    uint256[] public balances; // Converted to 10 ** 18
    uint256 public mintFee; // Mint fee * 10**10
    uint256 public swapFee; // Swap fee * 10**10
    uint256 public redeemFee; // Redeem fee * 10**10
    address public feeRecipient;
    address public poolToken;
    uint256 public totalSupply; // The total amount of pool token minted by the swap.
                                // It might be different from the pool token supply as the pool token can have multiple minters.

    address public governance;
    mapping(address => bool) public admins;
    bool public paused;

    uint256 public initialA;

    /**
     * @dev Initialize the ACoconut Swap.
     */
    function initialize(address[] memory _tokens, uint256[] memory _precisions, uint256[] memory _fees,
        address _poolToken, uint256 _A) public initializer {
        require(_tokens.length == _precisions.length, "input mismatch");
        require(_fees.length == 3, "no fees");
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0x0), "token not set");
            require(_precisions[i] != 0, "precision not set");
            balances.push(0);
        }
        require(_poolToken != address(0x0), "pool token not set");

        governance = msg.sender;
        feeRecipient = msg.sender;
        tokens = _tokens;
        precisions = _precisions;
        mintFee = _fees[0];
        swapFee = _fees[1];
        redeemFee = _fees[2];
        poolToken = _poolToken;

        initialA = _A;

        // The swap must start with paused state!
        paused = true;
    }

    /**
     * @dev Returns the current value of A. This method might be updated in the future.
     */
    function getA() public view returns (uint256) {
        return initialA;
    }

    /**
     * @dev Computes D given token balances.
     * @param _balances Normalized balance of each token.
     * @param _A Amplification coefficient from getA()
     */
    function _getD(uint256[] memory _balances, uint256 _A) internal pure returns (uint256) {
        uint256 sum = 0;
        uint256 i = 0;
        uint256 Ann = _A;
        for (i = 0; i < _balances.length; i++) {
            sum = sum.add(_balances[i]);
            Ann = Ann.mul(_balances.length);
        }
        if (sum == 0)   return 0;

        uint256 prevD = 0;
        uint256 D = sum;
        for (i = 0; i < 255; i++) {
            uint256 pD = D;
            for (uint256 j = 0; j < _balances.length; j++) {
                // pD = pD * D / (_x * balance.length)
                pD = pD.mul(D).div(_balances[j].mul(_balances.length));
            }
            prevD = D;
            // D = (Ann * sum + pD * balance.length) * D / ((Ann - 1) * D + (balance.length + 1) * pD)
            D = Ann.mul(sum).add(pD.mul(_balances.length)).mul(D).div(Ann.sub(1).mul(D).add(_balances.length.add(1).mul(pD)));
            if (D > prevD) {
                if (D - prevD <= 1) break;
            } else {
                if (prevD - D <= 1) break;
            }
        }

        return D;
    }

    /**
     * @dev Computes token balance given D.
     * @param _balances Converted balance of each token except token with index _j.
     * @param _j Index of the token to calculate balance.
     * @param _D The target D value.
     * @param _A Amplification coeffient.
     * @return Converted balance of the token with index _j.
     */
    function _getY(uint256[] memory _balances, uint256 _j, uint256 _D, uint256 _A) internal pure returns (uint256) {
        uint256 c = _D;
        uint256 S_ = 0;
        uint256 Ann = _A;
        uint256 i = 0;
        for (i = 0; i < _balances.length; i++) {
            Ann = Ann.mul(_balances.length);
            if (i == _j) continue;
            S_ = S_.add(_balances[i]);
            // c = c * D / (_x * N)
            c = c.mul(_D).div(_balances[i].mul(_balances.length));
        }
        // c = c * D / (Ann * N)
        c = c.mul(_D).div(Ann.mul(_balances.length));
        // b = S_ + D / Ann
        uint256 b = S_.add(_D.div(Ann));
        uint256 prevY = 0;
        uint256 y = _D;

        // 255 since the result is 256 digits
        for (i = 0; i < 255; i++) {
            prevY = y;
            // y = (y * y + c) / (2 * y + b - D)
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(_D));
            if (y > prevY) {
                if (y - prevY <= 1) break;
            } else {
                if (prevY - y <= 1) break;
            }
        }

        return y;
    }

    /**
     * @dev Compute the amount of pool token that can be minted.
     * @param _amounts Unconverted token balances.
     * @return The amount of pool token minted.
     */
    function getMintAmount(uint256[] calldata _amounts) external view returns (uint256, uint256) {
        uint256[] memory _balances = balances;
        require(_amounts.length == _balances.length, "invalid amount");
        
        uint256 A = getA();
        uint256 oldD = totalSupply;
        uint256 i = 0;
        for (i = 0; i < _balances.length; i++) {
            if (_amounts[i] == 0)   continue;
            // balance = balance + amount * precision
            _balances[i] = _balances[i].add(_amounts[i].mul(precisions[i]));
        }
        uint256 newD = _getD(_balances, A);
        // newD should be bigger than or equal to oldD
        uint256 mintAmount = newD.sub(oldD);
        uint256 feeAmount = 0;

        if (mintFee > 0) {
            feeAmount = mintAmount.mul(mintFee).div(feeDenominator);
            mintAmount = mintAmount.sub(feeAmount);
        }

        return (mintAmount, feeAmount);
    }

    /**
     * @dev Mints new pool token.
     * @param _amounts Unconverted token balances used to mint pool token.
     * @param _minMintAmount Minimum amount of pool token to mint.
     */
    function mint(uint256[] calldata _amounts, uint256 _minMintAmount) external nonReentrant {
        uint256[] memory _balances = balances;
        // If swap is paused, only admins can mint.
        require(!paused || admins[msg.sender], "paused");
        require(_balances.length == _amounts.length, "invalid amounts");

        uint256 A = getA();
        uint256 oldD = totalSupply;
        uint256 i = 0;
        for (i = 0; i < _balances.length; i++) {
            if (_amounts[i] == 0) {
                // Initial deposit requires all tokens provided!
                require(oldD > 0, "zero amount");
                continue;
            }
            _balances[i] = _balances[i].add(_amounts[i].mul(precisions[i]));
        }
        uint256 newD = _getD(_balances, A);
        // newD should be bigger than or equal to oldD
        uint256 mintAmount = newD.sub(oldD);

        uint256 fee = mintFee;
        uint256 feeAmount;
        if (fee > 0) {
            feeAmount = mintAmount.mul(fee).div(feeDenominator);
            mintAmount = mintAmount.sub(feeAmount);
        }
        require(mintAmount >= _minMintAmount, "fewer than expected");

        // Transfer tokens into the swap
        for (i = 0; i < _amounts.length; i++) {
            if (_amounts[i] == 0)    continue;
            // Update the balance in storage
            balances[i] = _balances[i];
            IERC20(tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
        }
        totalSupply = newD;
        IERC20MintableBurnable(poolToken).mint(feeRecipient, feeAmount);
        IERC20MintableBurnable(poolToken).mint(msg.sender, mintAmount);

        emit Minted(msg.sender, mintAmount, _amounts, feeAmount);
    }

    /**
     * @dev Computes the output amount after the swap.
     * @param _i Token index to swap in.
     * @param _j Token index to swap out.
     * @param _dx Unconverted amount of token _i to swap in.
     * @return Unconverted amount of token _j to swap out.
     */
    function getSwapAmount(uint256 _i, uint256 _j, uint256 _dx) external view returns (uint256) {
        uint256[] memory _balances = balances;
        require(_i != _j, "same token");
        require(_i < _balances.length, "invalid in");
        require(_j < _balances.length, "invalid out");
        require(_dx > 0, "invalid amount");

        uint256 A = getA();
        uint256 D = totalSupply;
        // balance[i] = balance[i] + dx * precisions[i]
        _balances[_i] = _balances[_i].add(_dx.mul(precisions[_i]));
        uint256 y = _getY(_balances, _j, D, A);
        // dy = (balance[j] - y - 1) / precisions[j] in case there was rounding errors
        uint256 dy = _balances[_j].sub(y).sub(1).div(precisions[_j]);

        if (swapFee > 0) {
            dy = dy.sub(dy.mul(swapFee).div(feeDenominator));
        }

        return dy;
    }

    /**
     * @dev Exchange between two underlying tokens.
     * @param _i Token index to swap in.
     * @param _j Token index to swap out.
     * @param _dx Unconverted amount of token _i to swap in.
     * @param _minDy Minimum token _j to swap out in converted balance.
     */
    function swap(uint256 _i, uint256 _j, uint256 _dx, uint256 _minDy) external nonReentrant {
        uint256[] memory _balances = balances;
        // If swap is paused, only admins can swap.
        require(!paused || admins[msg.sender], "paused");
        require(_i != _j, "same token");
        require(_i < _balances.length, "invalid in");
        require(_j < _balances.length, "invalid out");
        require(_dx > 0, "invalid amount");

        uint256 A = getA();
        uint256 D = totalSupply;
        // balance[i] = balance[i] + dx * precisions[i]
        _balances[_i] = _balances[_i].add(_dx.mul(precisions[_i]));
        uint256 y = _getY(_balances, _j, D, A);
        // dy = (balance[j] - y - 1) / precisions[j] in case there was rounding errors
        uint256 dy = _balances[_j].sub(y).sub(1).div(precisions[_j]);
        // Update token balance in storage
        balances[_j] = y;
        balances[_i] = _balances[_i];

        uint256 fee = swapFee;
        if (fee > 0) {
            dy = dy.sub(dy.mul(fee).div(feeDenominator));
        }
        require(dy >= _minDy, "fewer than expected");

        IERC20(tokens[_i]).safeTransferFrom(msg.sender, address(this), _dx);
        // Important: When swap fee > 0, the swap fee is charged on the output token.
        // Therefore, balances[j] < tokens[j].balanceOf(this)
        // Since balances[j] is used to compute D, D is unchanged.
        // collectFees() is used to convert the difference between balances[j] and tokens[j].balanceOf(this)
        // into pool token as fees!
        IERC20(tokens[_j]).safeTransfer(msg.sender, dy);

        emit TokenSwapped(msg.sender, tokens[_i], tokens[_j], _dx, dy);
    }

    /**
     * @dev Computes the amounts of underlying tokens when redeeming pool token.
     * @param _amount Amount of pool tokens to redeem.
     * @return Amounts of underlying tokens redeemed.
     */
    function getRedeemProportionAmount(uint256 _amount) external view returns (uint256[] memory, uint256) {
        uint256[] memory _balances = balances;
        require(_amount > 0, "zero amount");

        uint256 D = totalSupply;
        uint256[] memory amounts = new uint256[](_balances.length);
        uint256 feeAmount = 0;
        if (redeemFee > 0) {
            feeAmount = _amount.mul(redeemFee).div(feeDenominator);
            // Redemption fee is charged with pool token before redemption.
            _amount = _amount.sub(feeAmount);
        }

        for (uint256 i = 0; i < _balances.length; i++) {
            // We might choose to use poolToken.totalSupply to compute the amount, but decide to use
            // D in case we have multiple minters on the pool token.
            amounts[i] = _balances[i].mul(_amount).div(D).div(precisions[i]);
        }

        return (amounts, feeAmount);
    }

    /**
     * @dev Redeems pool token to underlying tokens proportionally.
     * @param _amount Amount of pool token to redeem.
     * @param _minRedeemAmounts Minimum amount of underlying tokens to get.
     */
    function redeemProportion(uint256 _amount, uint256[] calldata _minRedeemAmounts) external nonReentrant {
        uint256[] memory _balances = balances;
        // If swap is paused, only admins can redeem.
        require(!paused || admins[msg.sender], "paused");
        require(_amount > 0, "zero amount");
        require(_balances.length == _minRedeemAmounts.length, "invalid mins");

        uint256 D = totalSupply;
        uint256[] memory amounts = new uint256[](_balances.length);
        uint256 fee = redeemFee;
        uint256 feeAmount;
        if (fee > 0) {
            feeAmount = _amount.mul(fee).div(feeDenominator);
            // Redemption fee is paid with pool token
            // No conversion is needed as the pool token has 18 decimals
            IERC20(poolToken).safeTransferFrom(msg.sender, feeRecipient, feeAmount);
            _amount = _amount.sub(feeAmount);
        }

        for (uint256 i = 0; i < _balances.length; i++) {
            // We might choose to use poolToken.totalSupply to compute the amount, but decide to use
            // D in case we have multiple minters on the pool token.
            uint256 tokenAmount = _balances[i].mul(_amount).div(D);
            // Important: Underlying tokens must convert back to original decimals!
            amounts[i] = tokenAmount.div(precisions[i]);
            require(amounts[i] >= _minRedeemAmounts[i], "fewer than expected");
            // Updates the balance in storage
            balances[i] = _balances[i].sub(tokenAmount);
            IERC20(tokens[i]).safeTransfer(msg.sender, amounts[i]);
        }

        totalSupply = D.sub(_amount);
        // After reducing the redeem fee, the remaining pool tokens are burned!
        IERC20MintableBurnable(poolToken).burn(msg.sender, _amount);

        emit Redeemed(msg.sender, _amount.add(feeAmount), amounts, feeAmount);
    }

    /**
     * @dev Computes the amount when redeeming pool token to one specific underlying token.
     * @param _amount Amount of pool token to redeem.
     * @param _i Index of the underlying token to redeem to.
     * @return Amount of underlying token that can be redeem to.
     */
    function getRedeemSingleAmount(uint256 _amount, uint256 _i) external view returns (uint256, uint256) {
        uint256[] memory _balances = balances;
        require(_amount > 0, "zero amount");
        require(_i < _balances.length, "invalid token");

        uint256 A = getA();
        uint256 D = totalSupply;
        uint256 feeAmount = 0;
        if (redeemFee > 0) {
            feeAmount = _amount.mul(redeemFee).div(feeDenominator);
            // Redemption fee is charged with pool token before redemption.
            _amount = _amount.sub(feeAmount);
        }
        // The pool token amount becomes D - _amount
        uint256 y = _getY(_balances, _i, D.sub(_amount), A);
        uint256 dy = _balances[_i].sub(y).div(precisions[_i]);

        return (dy, feeAmount);
    }

    /**
     * @dev Redeem pool token to one specific underlying token.
     * @param _amount Amount of pool token to redeem.
     * @param _i Index of the token to redeem to.
     * @param _minRedeemAmount Minimum amount of the underlying token to redeem to.
     */
    function redeemSingle(uint256 _amount, uint256 _i, uint256 _minRedeemAmount) external nonReentrant {
        uint256[] memory _balances = balances;
        // If swap is paused, only admins can redeem.
        require(!paused || admins[msg.sender], "paused");
        require(_amount > 0, "zero amount");
        require(_i < _balances.length, "invalid token");

        uint256 A = getA();
        uint256 D = totalSupply;
        uint256 fee = redeemFee;
        uint256 feeAmount = 0;
        if (fee > 0) {
            // Redemption fee is charged with pool token before redemption.
            feeAmount = _amount.mul(fee).div(feeDenominator);
            // No conversion is needed as the pool token has 18 decimals
            IERC20(poolToken).safeTransferFrom(msg.sender, feeRecipient, feeAmount);
            _amount = _amount.sub(feeAmount);
        }

        // y is converted(18 decimals)
        uint256 y = _getY(_balances, _i, D.sub(_amount), A);
        // dy is not converted
        uint256 dy = _balances[_i].sub(y).div(precisions[_i]);
        require(dy >= _minRedeemAmount, "fewer than expected");
        // Updates token balance in storage
        balances[_i] = y;
        uint256[] memory amounts = new uint256[](_balances.length);
        amounts[_i] = dy;
        IERC20(tokens[_i]).safeTransfer(msg.sender, dy);

        totalSupply = D.sub(_amount);
        IERC20MintableBurnable(poolToken).burn(msg.sender, _amount);

        emit Redeemed(msg.sender, _amount.add(feeAmount), amounts, feeAmount);
    }

    /**
     * @dev Compute the amount of pool token that needs to be redeemed.
     * @param _amounts Unconverted token balances.
     * @return The amount of pool token that needs to be redeemed.
     */
    function getRedeemMultiAmount(uint256[] calldata _amounts) external view returns (uint256, uint256) {
        uint256[] memory _balances = balances;
        require(_amounts.length == balances.length, "length not match");
        
        uint256 A = getA();
        uint256 oldD = totalSupply;
        for (uint256 i = 0; i < _balances.length; i++) {
            if (_amounts[i] == 0)   continue;
            // balance = balance + amount * precision
            _balances[i] = _balances[i].sub(_amounts[i].mul(precisions[i]));
        }
        uint256 newD = _getD(_balances, A);

        // newD should be smaller than or equal to oldD
        uint256 redeemAmount = oldD.sub(newD);
        uint256 feeAmount = 0;
        if (redeemFee > 0) {
            redeemAmount = redeemAmount.mul(feeDenominator).div(feeDenominator.sub(redeemFee));
            feeAmount = redeemAmount.sub(oldD.sub(newD));
        }

        return (redeemAmount, feeAmount);
    }

    /**
     * @dev Redeems underlying tokens.
     * @param _amounts Amounts of underlying tokens to redeem to.
     * @param _maxRedeemAmount Maximum of pool token to redeem.
     */
    function redeemMulti(uint256[] calldata _amounts, uint256 _maxRedeemAmount) external nonReentrant {
        uint256[] memory _balances = balances;
        require(_amounts.length == balances.length, "length not match");
        // If swap is paused, only admins can redeem.
        require(!paused || admins[msg.sender], "paused");
        
        uint256 A = getA();
        uint256 oldD = totalSupply;
        uint256 i = 0;
        for (i = 0; i < _balances.length; i++) {
            if (_amounts[i] == 0)   continue;
            // balance = balance + amount * precision
            _balances[i] = _balances[i].sub(_amounts[i].mul(precisions[i]));
        }
        uint256 newD = _getD(_balances, A);

        // newD should be smaller than or equal to oldD
        uint256 redeemAmount = oldD.sub(newD);
        uint256 fee = redeemFee;
        uint256 feeAmount = 0;
        if (fee > 0) {
            redeemAmount = redeemAmount.mul(feeDenominator).div(feeDenominator.sub(fee));
            feeAmount = redeemAmount.sub(oldD.sub(newD));
            // No conversion is needed as the pool token has 18 decimals
            IERC20(poolToken).safeTransferFrom(msg.sender, feeRecipient, feeAmount);
        }
        require(redeemAmount <= _maxRedeemAmount, "more than expected");

        // Updates token balances in storage.
        balances = _balances;
        uint256 burnAmount = redeemAmount.sub(feeAmount);
        totalSupply = oldD.sub(burnAmount);
        IERC20MintableBurnable(poolToken).burn(msg.sender, burnAmount);
        for (i = 0; i < _balances.length; i++) {
            if (_amounts[i] == 0)   continue;
            IERC20(tokens[i]).safeTransfer(msg.sender, _amounts[i]);
        }

        emit Redeemed(msg.sender, redeemAmount, _amounts, feeAmount);
    }

    /**
     * @dev Return the amount of fee that's not collected.
     */
    function getPendingFeeAmount() external view returns (uint256) {
        uint256[] memory _balances = balances;
        uint256 A = getA();
        uint256 oldD = totalSupply;

        for (uint256 i = 0; i < _balances.length; i++) {
            _balances[i] = IERC20(tokens[i]).balanceOf(address(this)).mul(precisions[i]);
        }
        uint256 newD = _getD(_balances, A);

        return newD.sub(oldD);
    }

    /**
     * @dev Collect fee based on the token balance difference.
     */
    function collectFee() external returns (uint256) {
        require(admins[msg.sender], "not admin");
        uint256[] memory _balances = balances;
        uint256 A = getA();
        uint256 oldD = totalSupply;

        for (uint256 i = 0; i < _balances.length; i++) {
            _balances[i] = IERC20(tokens[i]).balanceOf(address(this)).mul(precisions[i]);
        }
        uint256 newD = _getD(_balances, A);
        uint256 feeAmount = newD.sub(oldD);
        if (feeAmount == 0) return 0;

        balances = _balances;
        totalSupply = newD;
        address _feeRecipient = feeRecipient;
        IERC20MintableBurnable(poolToken).mint(_feeRecipient, feeAmount);

        emit FeeCollected(_feeRecipient, feeAmount);

        return feeAmount;
    }

    /**
     * @dev Updates the govenance address.
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "not governance");
        governance = _governance;
    }

    /**
     * @dev Updates the mint fee.
     */
    function setMintFee(uint256 _mintFee) external {
        require(msg.sender == governance, "not governance");
        mintFee = _mintFee;
    }

    /**
     * @dev Updates the swap fee.
     */
    function setSwapFee(uint256 _swapFee) external {
        require(msg.sender == governance, "not governance");
        swapFee = _swapFee;
    }

    /**
     * @dev Updates the redeem fee.
     */
    function setRedeemFee(uint256 _redeemFee) external {
        require(msg.sender == governance, "not governance");
        redeemFee = _redeemFee;
    }

    /**
     * @dev Updates the recipient of mint/swap/redeem fees.
     */
    function setFeeRecipient(address _feeRecipient) external {
        require(msg.sender == governance, "not governance");
        require(_feeRecipient != address(0x0), "fee recipient not set");
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Updates the pool token.
     */
    function setPoolToken(address _poolToken) external {
        require(msg.sender == governance, "not governance");
        require(_poolToken != address(0x0), "pool token not set");
        poolToken = _poolToken;
    }

    /**
     * @dev Pause mint/swap/redeem actions. Can unpause later.
     */
    function pause() external {
        require(msg.sender == governance, "not governance");
        require(!paused, "paused");

        paused = true;
    }

    /**
     * @dev Unpause mint/swap/redeem actions.
     */
    function unpause() external {
        require(msg.sender == governance, "not governance");
        require(paused, "not paused");

        paused = false;
    }

    /**
     * @dev Updates the admin role for the address.
     * @param _account Address to update admin role.
     * @param _allowed Whether the address is granted the admin role.
     */
    function setAdmin(address _account, bool _allowed) external {
        require(msg.sender == governance, "not governance");
        require(_account != address(0x0), "account not set");

        admins[_account] = _allowed;
    }
}

// 
/**
 * @notice Contract that collects transaction fees from ACoconutSwap.
 */
contract ACoconutMaker {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Beta
    address public constant acBtc = address(0x3644B1464Cc0ADb73AcC936dc6C4d5dDE42D108b);
    address public constant acBtcVault = address(0xbDB15b5E88698c2DCfb6bFB7eb65fDEA36238055);
    address public constant acSwap = address(0x7FFe8B3B2d5ea4F0174060D968a4744858DC9B75);    // To add after ACoconutSwap is deployed.

    // address public constant acBtc = address(0xAcf806FeAeD6455244D34590AE57F772e80AA1a8);
    // address public constant acBtcVault = address(0x1eB47C01cfAb26D2346B449975b7BF20a34e0d45);
    // address public constant acSwap = address(0x0);    // To add after ACoconutSwap is deployed.

    address public governance;
    address public strategist;

    address public reserve;
    uint256 public reserveRate = 0;
    uint256 public constant reserveRateMax = 10000;

    constructor() public {
        governance = msg.sender;
        strategist = msg.sender;
        reserve = msg.sender;
    }

    /**
     * @dev Updates the govenance address.
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "not governance");
        governance = _governance;
    }

    /**
     * @dev Updates the strategist address.
     */
    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "not governance");
        strategist = _strategist;
    }

    /**
     * @dev Updates the reserve rate.
     */
    function setReserveRate(uint256 _reserveRate) external {
        require(msg.sender == governance, "not governance");
        require(_reserveRate <= reserveRateMax, "invalid rate");

        reserveRate = _reserveRate;
    } 

    /**
     * @dev Updates the reserve address.
     */
    function setReserve(address _reserve) external {
        require(msg.sender == governance, "not governance");
        require(_reserve != address(0x0), "reserve not set");

        reserve = _reserve;
    }

    /**
     * @dev Allocates swap fees accured in the contract.
     */
    function allocateFees() public {
        require(msg.sender == strategist || msg.sender == governance, "not authorized");
        uint256 balance = IERC20(acBtc).balanceOf(address(this));

        if (balance > 0 && reserveRate > 0 && reserve != address(0x0)) {
            uint256 reserveAmount = balance.mul(reserveRate).div(reserveRateMax);
            IERC20(acBtc).safeTransfer(reserve, reserveAmount);
            balance = balance.sub(reserveAmount);
        }

        IERC20(acBtc).safeTransfer(acBtcVault, balance);
    }
    
    /**
     * @dev Collect fees from the ACoconut Swap.
     * This contract must be an admin of ACoconut Swap in order to proceed.
     */
    function collectFees() public {
        require(msg.sender == strategist || msg.sender == governance, "not authorized");
        ACoconutSwap(acSwap).collectFee();
        allocateFees();
    }

    /**
     * @dev Used to salvage any token deposited into the contract by mistake.
     * @param _tokenAddress Token address to salvage.
     * @param _amount Amount of token to salvage.
     */
    function salvage(address _tokenAddress, uint256 _amount) public {
        require(msg.sender == strategist || msg.sender == governance, "not authorized");
        require(_tokenAddress != acBtc, "cannot salvage");
        require(_amount > 0, "zero amount");
        IERC20(_tokenAddress).safeTransfer(governance, _amount);
    }
}