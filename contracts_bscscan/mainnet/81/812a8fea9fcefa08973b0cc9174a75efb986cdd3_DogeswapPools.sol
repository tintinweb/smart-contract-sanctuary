/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;




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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: bscContracts/DogeswapPools.sol

pragma experimental ABIEncoderV2;



interface IDOG is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function totalSupply() external override view returns (uint256);
}

contract DogeswapPools is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Mint(uint256 amount);
    event PoolAdded(POOL_TYPE poolType, address indexed stakedToken, uint256 allocPoint, uint256 pid);
    event PoolSetted(address indexed stakedToken, uint256 allocPoint, uint256 pid);
    
    // Control mining
    bool public paused = false;
    modifier notPause() {
        require(paused == false, "DogeswapPools: Mining has been suspended");
        _;
    }

    enum POOL_TYPE { Single, LP }

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP/Single tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    // Info of each pools.
    struct PoolInfo {
        POOL_TYPE poolType;
        IERC20 stakedToken;           
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accDOGPerShare;
        uint256 totalStakedAddress;
        uint256 totalAmount;
    }

    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens corresponding pid
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Is staked address corresponding pid
    mapping (uint256 => mapping (address => bool)) isStakedAddress;

    // DOG token
    IDOG public DOG;
    // max mint of DOG token
    uint256 private maxMint = 70000000 * 1e18; 
    uint256 public totalMint;
    // total DOG token mined per block
    uint256 public DOGPerBlock;
    // Single pool shares 5% per block
    uint256 public SINGLE_SHARE = 5;
    // LP pool shares 95% per block
    uint256 public LP_SHARE = 95;
    // Single allocation points. Must be the sum of all allocation points in all single pools.
    uint256 public singleAllocPoints = 0;
    // LP allocation points. Must be the sum of all allocation points in all lp pools.
    uint256 public lpAllocPoints = 0;
    // The block number when DOG mining starts.
    uint256 public startBlock;
    // Halving cycle(how many blocks to halve)
    uint256 public HALVING_CYCLE = 5184000;
    // Dev address which get DOG token.
    address payable public devaddr;
    // Fee address which get fee of single pool.
    address payable public feeAddr;
    // pid corresponding address
    mapping(address => uint256) public pidOfPool;
    
    // feeOn of deposit and withdraw to single pool
    bool public depositSinglePoolFeeOn = true;
    uint256 public depositSinglePoolFee = 5 * 1e16;
    bool public withdrawSinglePoolFeeOn = true;
    uint256 public withdrawSinglePoolFee = 5 * 1e16;
    
    constructor(
        IDOG _dog,
        uint256 _dogPerBlock,
        address payable _devaddr,
        address payable _feeAddr,
        uint256 _startTime
    ) public {
        require(_startTime > block.timestamp, "DogeswapPools: Incorrect start time");
        DOG = _dog;
        DOGPerBlock = _dogPerBlock;
        devaddr = _devaddr;
        feeAddr = _feeAddr;
        startBlock = block.number + (_startTime - block.timestamp) / 3;
    }
    
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }
    
    function phase(uint256 blockNumber) public view returns (uint256) {
        if (HALVING_CYCLE == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock).sub(1)).div(HALVING_CYCLE);
        }
        return 0;
    }

    function reward(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        return DOGPerBlock.div(2 ** _phase);
    }
    
    function getDOGBlockReward(uint256 _lastRewardBlock, uint256 _currentBlock) public view returns (uint256) {
        uint256 blockReward = 0;
        uint256 n = phase(_lastRewardBlock);
        uint256 m = phase(_currentBlock);
        while (n < m) {
            n++;
            uint256 r = n.mul(HALVING_CYCLE).add(startBlock);
            blockReward = blockReward.add((r.sub(_lastRewardBlock)).mul(reward(r)));
            _lastRewardBlock = r;
        }
        blockReward = blockReward.add((_currentBlock.sub(_lastRewardBlock)).mul(reward(_currentBlock)));
        return blockReward;
    }
    
    function pendingDOG(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDOGPerShare = pool.accDOGPerShare;
        uint256 stakedTokenSupply;
        if (_isDOGPool(pool.stakedToken)) {
            stakedTokenSupply = pool.totalAmount;
        } else {
            stakedTokenSupply = pool.stakedToken.balanceOf(address(this));
        }
        if (user.amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getDOGBlockReward(pool.lastRewardBlock, block.number);
                uint256 dogReward = 0;
                if (pool.poolType == POOL_TYPE.Single) {
                    dogReward = blockReward.mul(SINGLE_SHARE).div(100).mul(pool.allocPoint).div(singleAllocPoints);
                } else {
                    dogReward = blockReward.mul(LP_SHARE).div(100).mul(pool.allocPoint).div(lpAllocPoints);
                }
                accDOGPerShare = accDOGPerShare.add(dogReward.mul(1e24).div(stakedTokenSupply));
                return user.amount.mul(accDOGPerShare).div(1e24).sub(user.rewardDebt);
            }
            if (block.number == pool.lastRewardBlock) {
                return user.amount.mul(accDOGPerShare).div(1e24).sub(user.rewardDebt);
            }
        }
        return 0;
    }
    
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        
        uint256 stakedTokenSupply;
        
        if (_isDOGPool(pool.stakedToken)) {
            if (pool.totalAmount == 0) {
                pool.lastRewardBlock = block.number;
                return;
            }
            stakedTokenSupply = pool.totalAmount;
        } else {
            stakedTokenSupply = pool.stakedToken.balanceOf(address(this));
            if (stakedTokenSupply == 0) {
                pool.lastRewardBlock = block.number;
                return;
            }
        }
        
        uint256 blockReward = getDOGBlockReward(pool.lastRewardBlock, block.number);
        uint256 dogReward = 0;
        uint256 devReward = 0;
        
        if (blockReward <= 0) {
            return;
        }
        
        if (pool.poolType == POOL_TYPE.Single && singleAllocPoints > 0) {
            dogReward = blockReward.mul(SINGLE_SHARE).div(100).mul(pool.allocPoint).div(singleAllocPoints);
        } else if (lpAllocPoints > 0) {
            dogReward = blockReward.mul(LP_SHARE).div(100).mul(pool.allocPoint).div(lpAllocPoints);
        }
        
        uint256 remaining = maxMint.sub(totalMint);
        
        if (dogReward.add(dogReward.div(10)) < remaining) {
            devReward = dogReward.div(10);
            totalMint = totalMint.add(dogReward.add(devReward));
            DOG.mint(devaddr, devReward);
            DOG.mint(address(this), dogReward);
            pool.accDOGPerShare = pool.accDOGPerShare.add(dogReward.mul(1e24).div(stakedTokenSupply));
            emit Mint(dogReward);
        } else if (remaining > 0) {
            devReward = remaining.mul(1).div(11);
            dogReward = remaining.sub(devReward);
            totalMint = totalMint.add(devReward.add(dogReward));
            DOG.mint(devaddr, devReward);
            DOG.mint(address(this), dogReward);
            pool.accDOGPerShare = pool.accDOGPerShare.add(dogReward.mul(1e24).div(stakedTokenSupply));
            emit Mint(dogReward);
        }
        
        pool.lastRewardBlock = block.number;
    }
    
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    function deposit(uint256 _pid, uint256 _amount) public payable notPause {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.poolType == POOL_TYPE.Single && depositSinglePoolFeeOn) {
            require(msg.value == depositSinglePoolFee, "DogeswapPools: Can't deposit to single pool without fee");
            feeAddr.transfer(address(this).balance);
        }
        address _user = msg.sender;
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accDOGPerShare).div(1e24).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                _safeDOGTransfer(_user, pendingAmount);
            }
        }
        if (_amount > 0) {
            pool.stakedToken.safeTransferFrom(_user, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
            if (!isStakedAddress[_pid][_user]) {
                isStakedAddress[_pid][_user] = true;
                pool.totalStakedAddress = pool.totalStakedAddress.add(1);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accDOGPerShare).div(1e24);
        emit Deposit(_user, _pid, _amount);
    }
    
    function withdraw(uint256 _pid, uint256 _amount) public payable notPause {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.poolType == POOL_TYPE.Single && withdrawSinglePoolFeeOn) {
            require(msg.value == withdrawSinglePoolFee, "DogeswapPools: Can't withdraw from single pool without fee");
            feeAddr.transfer(address(this).balance);
        }
        address _user = msg.sender;
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, "DogeswapPools: Insuffcient amount to withdraw");
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accDOGPerShare).div(1e24).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            _safeDOGTransfer(_user, pendingAmount);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            pool.stakedToken.safeTransfer(_user, _amount);
            if (user.amount == 0) {
                isStakedAddress[_pid][_user] = false;
                pool.totalStakedAddress = pool.totalStakedAddress.sub(1);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accDOGPerShare).div(1e24);
        emit Withdraw(_user, _pid, _amount);
    }
    
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public payable notPause {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.poolType == POOL_TYPE.Single && withdrawSinglePoolFeeOn) {
            require(msg.value == withdrawSinglePoolFee, "DogeswapPools: Can't withdraw from single pool without fee");
        }
        address _user = msg.sender;
        UserInfo storage user = userInfo[_pid][_user];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.stakedToken.safeTransfer(_user, amount);
        pool.totalAmount = pool.totalAmount.sub(amount);
        isStakedAddress[_pid][_user] = false;
        pool.totalStakedAddress = pool.totalStakedAddress.sub(1);
        emit EmergencyWithdraw(_user, _pid, amount);
    }
    
    function get365EarnedByPid(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 blockReward = getDOGBlockReward(block.number, block.number.add(365 days / 3));
        uint256 dogReward = 0;
        
        if (blockReward <= 0) {
            return 0;
        }
        
        if (pool.poolType == POOL_TYPE.Single) {
            dogReward = blockReward.mul(SINGLE_SHARE).div(100).mul(pool.allocPoint).div(singleAllocPoints);
        } else {
            dogReward = blockReward.mul(LP_SHARE).div(100).mul(pool.allocPoint).div(lpAllocPoints);
        }
        
        return dogReward;
    }
    
    // ======== INTERNAL METHODS ========= //
    
    function _addPool(
        POOL_TYPE _poolType, 
        uint256 _allocPoint, 
        IERC20 _stakedToken, 
        bool _withUpdate
    ) internal {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        if (_poolType == POOL_TYPE.Single) {
            singleAllocPoints = singleAllocPoints.add(_allocPoint);
        } else {
            lpAllocPoints = lpAllocPoints.add(_allocPoint);
        }
        poolInfo.push(PoolInfo({
            poolType: _poolType,
            stakedToken: _stakedToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accDOGPerShare: 0,
            totalAmount: 0,
            totalStakedAddress: 0
        }));
        pidOfPool[address(_stakedToken)] = poolInfo.length - 1;
        emit PoolAdded(_poolType, address(_stakedToken), _allocPoint, poolInfo.length - 1);
    }
    
    function _setPool(
        uint256 _pid, 
        uint256 _allocPoint, 
        bool _withUpdate
    ) internal {
        if (_withUpdate) {
            massUpdatePools();
        }
        if (poolInfo[_pid].poolType == POOL_TYPE.Single) {
            singleAllocPoints = singleAllocPoints.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        } else {
            lpAllocPoints = lpAllocPoints.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        }
        poolInfo[_pid].allocPoint = _allocPoint;
        emit PoolSetted(address(poolInfo[_pid].stakedToken), _allocPoint, _pid);
    }
    
    function _isDOGPool(IERC20 stakedToken) internal view returns (bool) {
        return stakedToken == DOG;
    }
    
    function _safeDOGTransfer(address _to, uint256 _amount) internal {
        uint256 dogBal = DOG.balanceOf(address(this));
        if (_amount > dogBal) {
            DOG.transfer(_to, dogBal);
        } else {
            DOG.transfer(_to, _amount);
        }
    }
    
    // ======== ONLY OWNER CONTROL METHODS ========== //
    function batchAddPools(
        IERC20[] memory stakedTokens,
        uint256[] memory allocPoints,
        POOL_TYPE[] memory poolTypes,
        bool _withUpdate
    ) external onlyOwner {
        require(
            stakedTokens.length == allocPoints.length && 
            stakedTokens.length == poolTypes.length,
            "DogeswapPools: Invalid length of pools"
        );
        for(uint i = 0; i < stakedTokens.length; i++) {
            require(pidOfPool[address(stakedTokens[i])] == 0, "DogeswapPools: Existed Pool");
            _addPool(poolTypes[i], allocPoints[i], stakedTokens[i], _withUpdate);
        }
    }
    
    function batchSetPoolsByStakedToken(
        IERC20[] memory stakedTokens, 
        uint256[] memory allocPoints, 
        bool _withUpdate
    ) external onlyOwner {
        require(
            stakedTokens.length == allocPoints.length,
            "DogeswapPools: Invalid length of pools"
        );
        for(uint i = 0; i < stakedTokens.length; i++) {
            _setPool(pidOfPool[address(stakedTokens[i])], allocPoints[i], _withUpdate);
        }
    }
    
    function setDOGPerBlock(uint256 _dogPerBlock) external onlyOwner {
        massUpdatePools();
        DOGPerBlock = _dogPerBlock;
    }
    
    function setHalvingCycle(uint256 cycle) external onlyOwner {
        HALVING_CYCLE = cycle;
    }
    
    function setPoolShare(uint256 single, uint256 lp) external onlyOwner {
        require(single.add(lp) == 100, "DogeswapPools: the sum of two share should be 100");
        SINGLE_SHARE = single;
        LP_SHARE = lp;
    }
    
    function setPause() external onlyOwner {
        paused = !paused;
    }
    
    // Update dev address by owner
    function setDevAddr(address payable _devaddr) external onlyOwner {
        devaddr = _devaddr;
    }
    
    // Update fee address by owner
    function setFeeAddr(address payable _feeAddr) external onlyOwner{
        feeAddr = _feeAddr;
    }
    
    function setDepositFee(bool _feeOn, uint256 _fee) external onlyOwner {
        depositSinglePoolFeeOn = _feeOn;
        depositSinglePoolFee = _fee;
    }
    
    function setWithdrawFee(bool _feeOn, uint256 _fee) external onlyOwner {
        withdrawSinglePoolFeeOn = _feeOn;
        withdrawSinglePoolFee = _fee;
    }
    
    function setMaxMint(uint256 maxNum) external onlyOwner {
        maxMint = maxNum;
    }
    
    function setStartBlock(uint256 _startBlock) external onlyOwner {
        require(totalMint == 0, "DogeswapPools: can't set startBlock after mining started'");
        require(_startBlock > block.number, "DogeswapPools: wrong block number");
        startBlock = _startBlock;
    }
}