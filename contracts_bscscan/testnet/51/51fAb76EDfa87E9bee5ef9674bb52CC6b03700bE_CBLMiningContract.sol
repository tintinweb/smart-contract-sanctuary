/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-27
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

interface ICBL is IERC20{
    function Destory(uint256 tBurnAmount) external;
    function setInvitor(address Invitor) external returns (bool);
    function getInvitors(address account , bool isCompress) external view returns(address ,address );
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;




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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/LayerMiningContract.sol

pragma solidity 0.6.6;


contract CBLMiningContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardToClaim; // when deposit or withdraw, update pending reward  to rewartToClaim.
    }

    struct PoolInfo {
        string  poolName;           // pool name
        IERC20  lpToken;            // Address of   LP token.
        uint256 allocPoint;         // How many allocation points assigned to this pool. mining token  distribute per block.
        uint256 lastRewardBlock;    // Last block number that mining token distribution occurs.
        uint256 accPerShare;        // Accumulated mining token per share, times 1e12.
        uint256 lpTokenAmount;      // lpToken deposit amount in this pool, for calculating APY
        uint256 maxAmountPerUser;   // The maximum amount of deposits per user. maxAmountPerUser == 0 means no limit
    }

    ICBL public cblToken; //  cbl TOKEN

    uint256 public phase1StartBlockNumber;
    uint256 public phase1EndBlockNumber;
    uint256 public phase2EndBlockNumber;
    uint256 public phase3EndBlockNumber;
    uint256 public phase4EndBlockNumber;

    uint256 public phase1TokenPerBlock;
    uint256 public phase2TokenPerBlock;
    uint256 public phase3TokenPerBlock;
    uint256 public phase4TokenPerBlock;
    
    uint256 public invite1Fee = 4;
    uint256 public invite2Fee = 1;
    uint256 public burnFee = 5;
    bool public isCompress = false;

    PoolInfo[] public poolInfo; // Info of each pool.
    mapping (uint256 => mapping (address => UserInfo)) private userInfo; // Info of each user that stakes LP tokens.
    uint256 public totalAllocPoint = 0;  // Total allocation points. Must be the sum of all allocation points in all pools.
    bool public enableClaim = false;  // claim switch

    event Claim(address indexed user, uint256  pid, uint256 amount);
    event Deposit(address indexed user, uint256  pid, uint256 amount);
    event Withdraw(address indexed user, uint256  pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256  pid, uint256 amount);

    constructor(address _mining_token, uint256 _mining_start_block) public {
        cblToken = ICBL(_mining_token);

        uint256 blockCountPerDay = 28800; //  3 sec per block in bsc , 20 * 60 * 24 =  28800

        phase1StartBlockNumber = _mining_start_block;
        phase1EndBlockNumber = phase1StartBlockNumber.add(blockCountPerDay.mul(7)); 
        phase2EndBlockNumber = phase1EndBlockNumber.add(blockCountPerDay.mul(7));
        phase3EndBlockNumber = phase2EndBlockNumber.add(blockCountPerDay.mul(7)); 
        phase4EndBlockNumber = phase3EndBlockNumber.add(blockCountPerDay.mul(7)); 

        uint256 phase1TokenMountPerDay = 152064 * 1e11; // phase1: 15206.4 CBL per day
        phase1TokenPerBlock = phase1TokenMountPerDay.div(blockCountPerDay) ;
        phase2TokenPerBlock = phase1TokenPerBlock.div(2);
        phase3TokenPerBlock = phase2TokenPerBlock.div(2);
        phase4TokenPerBlock = phase3TokenPerBlock.div(2);
    }

    function  setFee(uint256 _invite1Fee, uint256 _invite2Fee , uint256 _burnFee) public onlyOwner{
        invite1Fee=_invite1Fee;
        invite2Fee=_invite2Fee;
        burnFee=_burnFee;
    }
    function setCompress(bool _isCompress) public onlyOwner {
        isCompress = _isCompress;
    }
    
    function takeFee(uint256 _totalReward) private {
    
        address invitor1=address(0);
        address invitor2=address(0);
        
        uint256 invitor1Amount;
        uint256 invitor2Amount;
        uint256 TotalBurn;
        
        TotalBurn=_totalReward.mul(burnFee).div(1e2);
        
        invitor1Amount=_totalReward.mul(invite1Fee).div(1e2);
        invitor2Amount=_totalReward.mul(invite2Fee).div(1e2);
        
        
        (invitor1,invitor2)=cblToken.getInvitors(_msgSender(),isCompress);
        
        if(invitor1 != address(0)){
            safeMiningTokenTransfer(invitor1,invitor1Amount);
            if(invitor2 != address(0)){
                safeMiningTokenTransfer(invitor2,invitor2Amount);
            }else{
                TotalBurn = TotalBurn.add(invitor2Amount);
            }

        }else{
            TotalBurn = TotalBurn.add(invitor1Amount).add(invitor2Amount);
            
        }
        
        cblToken.Destory(TotalBurn);
    }
    

    function updateClaimSwitch(bool _enableClaim) public onlyOwner {
       enableClaim = _enableClaim;
    }

    function getUserInfo(uint256 _pid, address _user) public view returns (
        uint256 _amount,uint256 _rewardDebt,uint256 _rewardToClaim) {
        require(_pid < poolInfo.length, "invalid _pid");
        UserInfo memory info = userInfo[_pid][_user];
        _amount = info.amount;
        _rewardDebt = info.rewardDebt;
        _rewardToClaim = info.rewardToClaim;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(string memory _poolName, uint256 _allocPoint, address _lpToken, uint256 _maxAmountPerUser, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > phase1StartBlockNumber ? block.number : phase1StartBlockNumber;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            poolName: _poolName,
            lpToken: IERC20(_lpToken),
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPerShare: 0,
            lpTokenAmount: 0,
            maxAmountPerUser : _maxAmountPerUser
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint, uint256 _maxAmountPerUser, bool _withUpdate) public onlyOwner {
        require(_pid < poolInfo.length, "invalid _pid");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].maxAmountPerUser = _maxAmountPerUser;
    }

    function getCurrentRewardsPerBlock() public view returns (uint256) {
        return getMultiplier(block.number - 1, block.number);
    }

    // Return reward  over the given _from to _to block. Suppose it doesn't span two adjacent mining block number
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        require(_to > _from, "_to should greater than  _from ");
        if(_from < phase1StartBlockNumber && phase1StartBlockNumber < _to   && _to < phase1EndBlockNumber) {
            return _to.sub(phase1StartBlockNumber).mul(phase1TokenPerBlock);
        }
        if (phase1StartBlockNumber <= _from  && _from < phase1EndBlockNumber && _to <= phase1EndBlockNumber) {
            return _to.sub(_from).mul(phase1TokenPerBlock);
        }
        if (phase1StartBlockNumber < _from  &&  _from < phase1EndBlockNumber && phase1EndBlockNumber <  _to && _to <= phase2EndBlockNumber) {
            return phase1EndBlockNumber.sub(_from).mul(phase1TokenPerBlock).add(_to.sub(phase1EndBlockNumber).mul(phase2TokenPerBlock));
        }
        if (phase1EndBlockNumber <= _from  && _from < phase2EndBlockNumber && _to <= phase2EndBlockNumber) {
            return _to.sub(_from).mul(phase2TokenPerBlock);
        }
        if (phase1EndBlockNumber < _from  &&  _from < phase2EndBlockNumber && phase2EndBlockNumber <  _to && _to <= phase3EndBlockNumber) {
            return phase2EndBlockNumber.sub(_from).mul(phase2TokenPerBlock).add(_to.sub(phase2EndBlockNumber).mul(phase3TokenPerBlock));
        }
        if (phase2EndBlockNumber <= _from  && _from < phase3EndBlockNumber && _to <= phase3EndBlockNumber) {
            return _to.sub(_from).mul(phase3TokenPerBlock);
        }
        if (phase2EndBlockNumber < _from  &&  _from < phase3EndBlockNumber && phase3EndBlockNumber <  _to && _to <= phase4EndBlockNumber) {
            return phase3EndBlockNumber.sub(_from).mul(phase3TokenPerBlock).add(_to.sub(phase3EndBlockNumber).mul(phase4TokenPerBlock));
        }
        if (phase3EndBlockNumber <= _from  && _from < phase4EndBlockNumber && _to <= phase4EndBlockNumber) {
            return _to.sub(_from).mul(phase4TokenPerBlock);
        }
        if (phase3EndBlockNumber <= _from  &&  _from < phase4EndBlockNumber && phase4EndBlockNumber < _to) {
            return phase4EndBlockNumber.sub(_from).mul(phase4TokenPerBlock);
        }
		return 0;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpTokenAmount;

        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
        pool.accPerShare = pool.accPerShare.add(reward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function getPendingAmount(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPerShare = pool.accPerShare;
        uint256 lpSupply = pool.lpTokenAmount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
            accPerShare = accPerShare.add(reward.mul(1e12).div(lpSupply));
        }
        uint256 pending =  user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
        uint256 totalPendingAmount =  user.rewardToClaim.add(pending);
        return totalPendingAmount; 
    }

    function getAllPendingAmount(address _user) external view returns (uint256) {
        uint256 length = poolInfo.length;
        uint256 allAmount = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            allAmount =  allAmount.add(getPendingAmount(pid,_user));
        }
        return allAmount;
    }

    function claimAll() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
                if(getPendingAmount(pid, msg.sender) > 0 ) {
                   claim(pid);
            }
        }
    }

    function claim(uint256 _pid) public {  
        require(_pid < poolInfo.length, "invalid _pid");
        require(enableClaim, "could not claim now");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            user.rewardToClaim = user.rewardToClaim.add(pending);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        
        // xiugai
        // safeMiningTokenTransfer(msg.sender, user.rewardToClaim);
        // emit Claim(msg.sender, _pid, user.rewardToClaim );

        uint256 totalFeeRate=invite1Fee.add(invite2Fee).add(burnFee);
        uint256 totalFee=user.rewardToClaim.mul(totalFeeRate).div(1e2);
        uint256 reward=user.rewardToClaim.sub(totalFee);            
        
        safeMiningTokenTransfer(msg.sender, reward);
        takeFee(user.rewardToClaim);
        emit Claim(msg.sender, _pid, reward );
        
        user.rewardToClaim = 0;
    }

    // Deposit LP tokens to Mining for token allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // check limit 
        if(pool.maxAmountPerUser > 0) {
            uint256 allowance = pool.maxAmountPerUser.sub(user.amount);
            require(_amount <= allowance, "deposit amount exceeds allowance");
        }

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            user.rewardToClaim = user.rewardToClaim.add(pending);
        }
        if(_amount > 0) { // for gas saving
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            emit Deposit(msg.sender, _pid, _amount);

            pool.lpTokenAmount = pool.lpTokenAmount.add(_amount);

        }

        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);

    }

    // Withdraw LP tokens from Mining.
    function withdraw(uint256 _pid, uint256 _amount) public  nonReentrant {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: user.amount is not enough");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
        user.rewardToClaim = user.rewardToClaim.add(pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        pool.lpTokenAmount = pool.lpTokenAmount.sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        require(_pid < poolInfo.length, "invalid _pid");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        pool.lpTokenAmount = pool.lpTokenAmount.sub(user.amount);

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough mining token.
    function safeMiningTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = cblToken.balanceOf(address(this));
        require(bal >= _amount, "LayerMiningContract' balance is not enough.");
        cblToken.transfer(_to, _amount);
    }
}