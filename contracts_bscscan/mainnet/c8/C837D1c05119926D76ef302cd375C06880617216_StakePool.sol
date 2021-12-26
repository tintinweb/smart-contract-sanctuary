/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
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

pragma solidity ^0.8.0;



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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;

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




contract StakePool is ReentrancyGuard, Ownable {


    using SafeMath for uint256;
    using SafeERC20 for IERC20;

   modifier stakeEnabled {
        require(stakeOn == true , "Staking is paused !");
        _;
    }

   modifier withdrawEnabled {
        require(withdrawOn == true , "Withdrawing is paused !");
        _;
    }

    struct Tier {
        uint stake;
        uint32 weight;
        uint unlockTime;
    }
    
    IERC20 public stakeToken;
    IERC20 public rewardToken;

    uint public totalAllocPoint;
    
    uint public  apy;
    
    uint public tokenSupply;

    uint public totalStaked;


    mapping(address => uint) stakeBalances;
    mapping(address => uint) allocPoints;
    mapping(address => uint) userTime;
    mapping(address => uint) rewards;
    
    address[] public userAdresses; 

    mapping(address => uint) timeLocks;

    mapping(address => uint) stakingTime;

    bool stakeOn;   

    bool withdrawOn;  

    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardClaimed(address indexed user, uint amount);
    event Deposited(address indexed user, uint amount);
    event FeeWithdrawn(address indexed user, uint amount);
    event TokenSupplyWithdrawn(address indexed user, uint amount);

    Tier[] public tiers;
    
    uint private collectedFee;

    uint8 decimals = 18;


    constructor(address _stakeToken, address _rewardToken) {
        
        require(_stakeToken != address(0));
        require(_rewardToken != address(0));
         
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        apy = 10;
        totalAllocPoint = 0;
        tokenSupply = 0;
        totalStaked = 0;

        addTier(20000 ether, 750, uint32(1 days));
        addTier(10000 ether, 300, uint32(1 days));
        addTier(5000 ether, 130, uint32(1 days));
        addTier(2000 ether, 40, uint32(1 days));
        addTier(1000 ether, 15, uint32(1 days));

        collectedFee = 0;
        stakeOn = true;
        withdrawOn = true;
    }


    function depositTokens(uint _amount) external onlyOwner   { 
       
        require(rewardToken.balanceOf(msg.sender) >= _amount, "!amount");
        require(_amount >= (10 *10** decimals) , "min amount is 10 tokens");

        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);

        tokenSupply += _amount;

        emit Deposited(msg.sender, _amount);
    }
    

    function stake(uint _amount) external stakeEnabled {

        require(stakeToken.balanceOf(msg.sender) >= _amount, "!amount");
        require(_amount >  (10 * 10 ** decimals) ,  "minimum 10!");
        require((_amount +  stakeBalances[msg.sender])  >= (1000 * 10 ** decimals) , "user should stake a minimum 1000!");

        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint _reward = pendingRewards(msg.sender);

        rewards[msg.sender] += _reward; 
        
        stakeBalances[msg.sender] += _amount; 

        totalAllocPoint -= allocPoints[msg.sender];

        allocPoints[msg.sender] = _reBalance(stakeBalances[msg.sender] );
        
        userTime[msg.sender] = block.timestamp;

        totalAllocPoint += allocPoints[msg.sender];

        totalStaked += _amount;

        _checkOrAddUser(msg.sender);

        uint _unlock = block.timestamp;   

        timeLocks[msg.sender] = _unlock; 

        stakingTime[msg.sender] = _unlock; 

        emit Staked(msg.sender, _amount);
    }


    function withdraw(uint _amount) public virtual withdrawEnabled {
       
        require(balanceOf(msg.sender) >= _amount, "!StakeAmount");

        uint _fee =  calculateWithdrawFees(_amount); 

        collectedFee += _fee;

        rewards[msg.sender] += pendingRewards(msg.sender);

        uint _transferAmount = _amount - _fee;

        stakeBalances[msg.sender] -= _amount ; 

        totalAllocPoint -= allocPoints[msg.sender];

        totalStaked -= _amount;

        allocPoints[msg.sender] = _reBalance(stakeBalances[msg.sender] );

        userTime[msg.sender] = block.timestamp;
        
        
        stakingTime[msg.sender] = 0;

    
        stakeToken.safeTransfer(msg.sender, _transferAmount);

        totalAllocPoint += allocPoints[msg.sender];
        
        emit Withdrawn(msg.sender, _amount);
    }


    function withdrawAll() external virtual withdrawEnabled {
     
        withdraw(stakeBalances[msg.sender]);
    }


    function claimReward() public  {
        
        rewards[msg.sender] += pendingRewards(msg.sender); 

        uint _reward = rewards[msg.sender];

        require(_reward > 0, "No reward balance");
 
        require (tokenSupply >= _reward,'Not enough tokens, try later');
        
        rewards[msg.sender] = 0; 

        userTime[msg.sender] = block.timestamp;  
        
        rewardToken.safeTransfer(msg.sender, _reward);

        tokenSupply -= _reward;
        
        emit RewardClaimed(msg.sender, _reward);
    }

  
    function _checkOrAddUser(address _user) internal returns (bool) {
        
        bool _new = true;
        for(uint i = 0 ; i < userAdresses.length ; i++) {
            if (userAdresses[i] == _user) {
                _new = false;
                i = userAdresses.length ;
            }
        }
        if (_new){
            userAdresses.push(_user);
        }
        return _new;
    }

    function _reBalance(uint _balance) internal view returns (uint _points) {
        
        _points = 0;
        
        uint _smallest = tiers[tiers.length-1].stake; 

        while (_balance >= _smallest) {
            for (uint i = 0; i < tiers.length; i++) {  
                if (_balance >= tiers[i].stake) { 
                    _points += tiers[i].weight;
                    _balance -= tiers[i].stake;
                    i = tiers.length;
                }
            }
        }
        return _points;
    }


    function calculateWithdrawFees(uint _amount) internal view returns (uint _fee){
        
        _fee = 0;

        uint _stakingTime = timeLocks[msg.sender]; 

        if(block.timestamp > _stakingTime + uint(8 weeks)){
             _fee = 0;
        }

        if(block.timestamp <= _stakingTime + uint(8 weeks)){
           _fee = (_amount * 2) / 100;
        }
        
        if(block.timestamp <= _stakingTime + uint(6 weeks)){
           _fee = (_amount * 5) / 100;
        }

        if(block.timestamp <= _stakingTime + uint(4 weeks)){
           _fee = (_amount * 10) / 100;
        }

         if(block.timestamp <= _stakingTime + uint(2 weeks)){        
           _fee = (_amount * 20) / 100;
        }

        return _fee;
    }


    function balanceOf(address _sender) public view returns(uint) {

        return stakeBalances[_sender];
    }


    function allocPointsOf(address _sender) public view returns(uint) {

        return allocPoints[_sender];
    }


    function allocPercentageOf(address _sender) public view returns(uint) {
        
        uint points = allocPoints[_sender]*10**6; 

        uint millePercentage = points.div(totalAllocPoint);

        return millePercentage;
    }

        
    function tierCount() public view returns (uint8) {
        
        return uint8(tiers.length);
    }

        
    function getUserList() external view onlyOwner returns (address[] memory) {
        
        address[] memory userList = new address[](userAdresses.length);
        
        for (uint i = 0; i < userAdresses.length; i++) {
            userList[i] = userAdresses[i];
        }

        return userList;
    }

 
    function viewCollectedFee() external view  returns(uint) {
        
        return collectedFee;
    }
    

    function pendingRewards(address _account) public view returns(uint){
      
        uint _balance = stakeBalances[_account]; 

        uint _tokens = _balance.mul(apy).div(100);  
        
        uint _tokensPerSecond = _tokens.div(52 * 1 weeks);
        
        uint _userTime = userTime[_account]; 
        
        uint _currentTime = block.timestamp; 
        
        uint _time = _currentTime.sub(_userTime); 
        
        uint _result = _tokensPerSecond * _time;  
         
        return _result; 
        
    }


    function getTotalPendingRewards() external view returns (uint) {
      
       uint _total =0;
      
        for (uint i = 0; i < userAdresses.length; i++) {
            _total += pendingRewards(userAdresses[i]);
        }
        return _total;
    }


    function viewRewards(address _account) public view returns(uint) {      
        
        return rewards[_account];
    }


    function getStakingTime(address _account) public view returns(uint) {

        uint _stakingTime = stakingTime[_account];

        if(_stakingTime > 0) {

            return block.timestamp - _stakingTime ;
        
        } else {

            return _stakingTime;
        }
    }


    function addTier(uint _stake, uint32 _weight, uint _unlockTime) public onlyOwner {
        
        tiers.push(
            Tier({  
                stake: _stake,
                weight: _weight,
                unlockTime: _unlockTime
            })
        );
    }


    function setDisableStake(bool _flag) external onlyOwner {

        stakeOn = _flag;
    }


    function setDisableWithdraw(bool _flag) external onlyOwner {

        withdrawOn = _flag;
    }

    
    function changeRewardToken(address _rewardToken) external onlyOwner {

        require(_rewardToken != address(0));

        rewardToken = IERC20(_rewardToken);
    }


    function resetApy(uint _apy) public onlyOwner {
        
        require(_apy > 0, "!apy");

        for(uint i = 0 ; i < userAdresses.length; i++) {

             uint _reward = pendingRewards(userAdresses[i]);

             rewards[userAdresses[i]] += _reward;

             userTime[userAdresses[i]] = block.timestamp;
         }

         apy = _apy;
    }


    function withdrawCollectedFee() external onlyOwner {
        
        require(collectedFee > 0, "!Fee");

        uint _amount = collectedFee;

        stakeToken.safeTransfer(msg.sender, collectedFee);

        collectedFee = 0;

        emit FeeWithdrawn(msg.sender, _amount);
    }
       

    function returnRewardTokens() external onlyOwner  { 

        require (tokenSupply > 0,'!Amount');   

        uint _amount = tokenSupply;

        rewardToken.safeTransfer(msg.sender, tokenSupply);

        tokenSupply = 0;

        emit TokenSupplyWithdrawn(msg.sender, _amount);
    }


 
}