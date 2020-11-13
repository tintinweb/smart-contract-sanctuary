// File: @openzeppelin\contracts-ethereum-package\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin\contracts-ethereum-package\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin\contracts-ethereum-package\contracts\utils\Address.sol

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin\contracts-ethereum-package\contracts\token\ERC20\SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin\upgrades\contracts\Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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

// File: @openzeppelin\contracts-ethereum-package\contracts\GSN\Context.sol

pragma solidity ^0.5.0;


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
contract Context is Initializable {
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

// File: @openzeppelin\contracts-ethereum-package\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
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
     * > Note: Renouncing ownership will leave the contract without an owner,
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

    uint256[50] private ______gap;
}

// File: contracts\common\Base.sol

pragma solidity ^0.5.12;




/**
 * Base contract for all modules
 */
contract Base is Initializable, Context, Ownable {
    address constant  ZERO_ADDRESS = address(0);

    function initialize() public initializer {
        Ownable.initialize(_msgSender());
    }

}

// File: contracts\core\ModuleNames.sol

pragma solidity ^0.5.12;

/**
 * @dev List of module names
 */
contract ModuleNames {
    // Pool Modules
    string internal constant MODULE_ACCESS            = "access";
    string internal constant MODULE_SAVINGS           = "savings";
    string internal constant MODULE_INVESTING         = "investing";
    string internal constant MODULE_STAKING           = "staking";
    string internal constant MODULE_DCA               = "dca";
    string internal constant MODULE_REWARD            = "reward";

    // Pool tokens
    string internal constant TOKEN_AKRO               = "akro";    
    string internal constant TOKEN_ADEL               = "adel";    

    // External Modules (used to store addresses of external contracts)
    string internal constant CONTRACT_RAY             = "ray";
}

// File: contracts\common\Module.sol

pragma solidity ^0.5.12;



/**
 * Base contract for all modules
 */
contract Module is Base, ModuleNames {
    event PoolAddressChanged(address newPool);
    address public pool;

    function initialize(address _pool) public initializer {
        Base.initialize();
        setPool(_pool);
    }

    function setPool(address _pool) public onlyOwner {
        require(_pool != ZERO_ADDRESS, "Module: pool address can't be zero");
        pool = _pool;
        emit PoolAddressChanged(_pool);        
    }

    function getModuleAddress(string memory module) public view returns(address){
        require(pool != ZERO_ADDRESS, "Module: no pool");
        (bool success, bytes memory result) = pool.staticcall(abi.encodeWithSignature("get(string)", module));
        
        //Forward error from Pool contract
        if (!success) assembly {
            revert(add(result, 32), result)
        }

        address moduleAddress = abi.decode(result, (address));
        // string memory error = string(abi.encodePacked("Module: requested module not found - ", module));
        // require(moduleAddress != ZERO_ADDRESS, error);
        require(moduleAddress != ZERO_ADDRESS, "Module: requested module not found");
        return moduleAddress;
    }

}

// File: @openzeppelin\contracts-ethereum-package\contracts\access\Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts\modules\reward\RewardManagerRole.sol

pragma solidity ^0.5.12;




contract RewardManagerRole is Initializable, Context {
    using Roles for Roles.Role;

    event RewardManagerAdded(address indexed account);
    event RewardManagerRemoved(address indexed account);

    Roles.Role private _managers;

    function initialize(address sender) public initializer {
        if (!isRewardManager(sender)) {
            _addRewardManager(sender);
        }
    }

    modifier onlyRewardManager() {
        require(isRewardManager(_msgSender()), "RewardManagerRole: caller does not have the RewardManager role");
        _;
    }

    function addRewardManager(address account) public onlyRewardManager {
        _addRewardManager(account);
    }

    function renounceRewardManager() public {
        _removeRewardManager(_msgSender());
    }

    function isRewardManager(address account) public view returns (bool) {
        return _managers.has(account);
    }

    function _addRewardManager(address account) internal {
        _managers.add(account);
        emit RewardManagerAdded(account);
    }

    function _removeRewardManager(address account) internal {
        _managers.remove(account);
        emit RewardManagerRemoved(account);
    }

}

// File: contracts\modules\reward\RewardVestingModule.sol

pragma solidity ^0.5.12;







contract RewardVestingModule is Module, RewardManagerRole {
    event RewardTokenRegistered(address indexed protocol, address token);
    event EpochRewardAdded(address indexed protocol, address indexed token, uint256 epoch, uint256 amount);
    event RewardClaimed(address indexed protocol, address indexed token, uint256 claimPeriodStart, uint256 claimPeriodEnd, uint256 claimAmount);

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Epoch {
        uint256 end;        // Timestamp of Epoch end
        uint256 amount;     // Amount of reward token for this protocol on this epoch
    }

    struct RewardInfo {
        Epoch[] epochs;
        uint256 lastClaim; // Timestamp of last claim
    }

    struct ProtocolRewards {
        address[] tokens;
        mapping(address=>RewardInfo) rewardInfo;
    }

    mapping(address => ProtocolRewards) internal rewards;
    uint256 public defaultEpochLength;

    function initialize(address _pool) public initializer {
        Module.initialize(_pool);
        RewardManagerRole.initialize(_msgSender());
        defaultEpochLength = 7*24*60*60;
    }

    function registerRewardToken(address protocol, address token, uint256 firstEpochStart) public onlyRewardManager {
        if(firstEpochStart == 0) firstEpochStart = block.timestamp;
        //Push zero epoch
        ProtocolRewards storage r = rewards[protocol];
        RewardInfo storage ri = r.rewardInfo[token];
        require(ri.epochs.length == 0, "RewardVesting: token already registered for this protocol");
        r.tokens.push(token);
        ri.epochs.push(Epoch({
            end: firstEpochStart,
            amount: 0
        }));
        emit RewardTokenRegistered(protocol, token);
    }

    function setDefaultEpochLength(uint256 _defaultEpochLength) public onlyRewardManager {
        defaultEpochLength = _defaultEpochLength;
    }

    function getEpochInfo(address protocol, address token, uint256 epoch) public view returns(uint256 epochStart, uint256 epochEnd, uint256 rewardAmount) {
        ProtocolRewards storage r = rewards[protocol];
        RewardInfo storage ri = r.rewardInfo[token];
        require(ri.epochs.length > 0, "RewardVesting: protocol or token not registered");
        require (epoch < ri.epochs.length, "RewardVesting: epoch number too high");
        if(epoch == 0) {
            epochStart = 0;
        }else {
            epochStart = ri.epochs[epoch-1].end;
        }
        epochEnd = ri.epochs[epoch].end;
        rewardAmount = ri.epochs[epoch].amount;
        return (epochStart, epochEnd, rewardAmount);
    }

    function getLastCreatedEpoch(address protocol, address token) public view returns(uint256) {
        ProtocolRewards storage r = rewards[protocol];
        RewardInfo storage ri = r.rewardInfo[token];
        require(ri.epochs.length > 0, "RewardVesting: protocol or token not registered");
        return ri.epochs.length-1;       
    }

    function claimRewards() public {
        address protocol = _msgSender();
        ProtocolRewards storage r = rewards[protocol];
        //require(r.tokens.length > 0, "RewardVesting: call only from registered protocols allowed");
        if(r.tokens.length == 0) return;    //This allows claims from protocols which are not yet registered without reverting
        for(uint256 i=0; i < r.tokens.length; i++){
            _claimRewards(protocol, r.tokens[i]);
        }
    }

    function claimRewards(address protocol, address token) public {
        _claimRewards(protocol, token);
    }

    function _claimRewards(address protocol, address token) internal {
        ProtocolRewards storage r = rewards[protocol];
        RewardInfo storage ri = r.rewardInfo[token];
        uint256 epochsLength = ri.epochs.length;
        require(epochsLength > 0, "RewardVesting: protocol or token not registered");

        Epoch storage lastEpoch = ri.epochs[epochsLength-1];
        uint256 previousClaim = ri.lastClaim;
        if(previousClaim == lastEpoch.end) return; // Nothing to claim yet

        if(lastEpoch.end < block.timestamp) {
            ri.lastClaim = lastEpoch.end;
        }else{
            ri.lastClaim = block.timestamp;
        }
        
        uint256 claimAmount;
        Epoch storage ep = ri.epochs[0];
        uint256 i;
        // Searching for last claimable epoch
        for(i = epochsLength-1; i > 0; i--) {
            ep = ri.epochs[i];
            if(ep.end < block.timestamp) {  // We've found last fully-finished epoch
                if(i < epochsLength-1) {    // We have already started current epoch
                    i++;                    //    Go back to currently-running epoch
                    ep = ri.epochs[i];
                }
                break;
            }
        }
        if(ep.end > block.timestamp) {
            //Half-claim
            uint256 epStart = ri.epochs[i-1].end;
            uint256 claimStart = (previousClaim > epStart)?previousClaim:epStart;
            uint256 epochClaim = ep.amount.mul(block.timestamp.sub(claimStart)).div(ep.end.sub(epStart));
            claimAmount = claimAmount.add(epochClaim);
            i--;
        }
        //Claim rest
        for(i; i > 0; i--) {
            ep = ri.epochs[i];
            if(ep.end > previousClaim) {
                claimAmount = claimAmount.add(ep.amount);
            } else {
                break;
            }
        }
        IERC20(token).safeTransfer(protocol, claimAmount);
        emit RewardClaimed(protocol, token, previousClaim, ri.lastClaim, claimAmount);
    }

    function createEpoch(address protocol, address token, uint256 epochEnd, uint256 amount) public onlyRewardManager {
        ProtocolRewards storage r = rewards[protocol];
        RewardInfo storage ri = r.rewardInfo[token];
        uint256 epochsLength = ri.epochs.length;
        require(epochsLength > 0, "RewardVesting: protocol or token not registered");
        uint256 prevEpochEnd = ri.epochs[epochsLength-1].end;
        require(epochEnd > prevEpochEnd, "RewardVesting: new epoch should end after previous");
        ri.epochs.push(Epoch({
            end: epochEnd,
            amount:0
        }));            
        _addReward(protocol, token, epochsLength, amount);
    }

    function addReward(address protocol, address token, uint256 epoch, uint256 amount) public onlyRewardManager {
        _addReward(protocol, token, epoch, amount);
    }

    function addRewards(address[] calldata protocols, address[] calldata tokens, uint256[] calldata epochs, uint256[] calldata amounts) external onlyRewardManager {
        require(
            (protocols.length == tokens.length) && 
            (protocols.length == epochs.length) && 
            (protocols.length == amounts.length),
            "RewardVesting: array lengths do not match");
        for(uint256 i=0; i<protocols.length; i++) {
            _addReward(protocols[i], tokens[i], epochs[i], amounts[i]);
        }
    }

    /**
     * @notice Add reward to existing epoch or crete a new one
     * @param protocol Protocol for reward
     * @param token Reward token
     * @param epoch Epoch number - can be 0 to create new Epoch
     * @param amount Amount of Reward token to deposit
     */
    function _addReward(address protocol, address token, uint256 epoch, uint256 amount) internal {
        ProtocolRewards storage r = rewards[protocol];
        RewardInfo storage ri = r.rewardInfo[token];
        uint256 epochsLength = ri.epochs.length;
        require(epochsLength > 0, "RewardVesting: protocol or token not registered");
        if(epoch == 0) epoch = epochsLength; // creating a new epoch
        if (epoch == epochsLength) {
            uint256 epochEnd = ri.epochs[epochsLength-1].end.add(defaultEpochLength);
            if(epochEnd < block.timestamp) epochEnd = block.timestamp; //This generally should not happen, but just in case - we generate only one epoch since previous end
            ri.epochs.push(Epoch({
                end: epochEnd,
                amount: amount
            }));            
        } else  {
            require(epochsLength > epoch, "RewardVesting: epoch is too high");
            Epoch storage ep = ri.epochs[epoch];
            require(ep.end > block.timestamp, "RewardVesting: epoch already finished");
            ep.amount = ep.amount.add(amount);
        }
        emit EpochRewardAdded(protocol, token, epoch, amount);
        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
    }


}