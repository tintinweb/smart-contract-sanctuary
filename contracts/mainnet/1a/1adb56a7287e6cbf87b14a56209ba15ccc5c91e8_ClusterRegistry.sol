/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

/** 
 *  SourceUnit: /Users/prateekyammanuru/work/marlin/contracts_github/Contracts/contracts/Stake/ClusterRegistry.sol
*/
            
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




/** 
 *  SourceUnit: /Users/prateekyammanuru/work/marlin/contracts_github/Contracts/contracts/Stake/ClusterRegistry.sol
*/
            
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




/** 
 *  SourceUnit: /Users/prateekyammanuru/work/marlin/contracts_github/Contracts/contracts/Stake/ClusterRegistry.sol
*/
            
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /Users/prateekyammanuru/work/marlin/contracts_github/Contracts/contracts/Stake/ClusterRegistry.sol
*/
            
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




/** 
 *  SourceUnit: /Users/prateekyammanuru/work/marlin/contracts_github/Contracts/contracts/Stake/ClusterRegistry.sol
*/
            
pragma solidity ^0.5.0;

////import "@openzeppelin/upgrades/contracts/Initializable.sol";

////import "../../GSN/Context.sol";
////import "./IERC20.sol";
////import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
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
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
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
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
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
     * problems described in {IERC20-approve}.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}




/** 
 *  SourceUnit: /Users/prateekyammanuru/work/marlin/contracts_github/Contracts/contracts/Stake/ClusterRegistry.sol
*/
            
pragma solidity ^0.5.0;

////import "@openzeppelin/upgrades/contracts/Initializable.sol";

////import "../GSN/Context.sol";

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


/** 
 *  SourceUnit: /Users/prateekyammanuru/work/marlin/contracts_github/Contracts/contracts/Stake/ClusterRegistry.sol
*/

pragma solidity >=0.4.21 <0.7.0;


contract ClusterRegistry is Initializable, Ownable {

    using SafeMath for uint256;

    uint256 constant UINT256_MAX = ~uint256(0);

    struct Cluster {
        uint256 commission;
        address rewardAddress;
        address clientKey;
        bytes32 networkId; // keccak256("ETH") // token ticker for anyother chain in place of ETH
        Status status;
    }

    struct Lock {
        uint256 unlockBlock;
        uint256 iValue;
    }

    mapping(address => Cluster) clusters;

    mapping(bytes32 => Lock) public locks;
    mapping(bytes32 => uint256) public lockWaitTime;
    bytes32 constant COMMISSION_LOCK_SELECTOR = keccak256("COMMISSION_LOCK");
    bytes32 constant SWITCH_NETWORK_LOCK_SELECTOR = keccak256("SWITCH_NETWORK_LOCK");
    bytes32 constant UNREGISTER_LOCK_SELECTOR = keccak256("UNREGISTER_LOCK");

    enum Status{NOT_REGISTERED, REGISTERED}

    mapping(address => address) public clientKeys;

    event ClusterRegistered(
        address cluster, 
        bytes32 networkId, 
        uint256 commission, 
        address rewardAddress, 
        address clientKey
    );
    event CommissionUpdateRequested(address cluster, uint256 commissionAfterUpdate, uint256 effectiveBlock);
    event CommissionUpdated(address cluster, uint256 updatedCommission, uint256 updatedAt);
    event RewardAddressUpdated(address cluster, address updatedRewardAddress);
    event NetworkSwitchRequested(address cluster, bytes32 networkId, uint256 effectiveBlock);
    event NetworkSwitched(address cluster, bytes32 networkId, uint256 updatedAt);
    event ClientKeyUpdated(address cluster, address clientKey);
    event ClusterUnregisterRequested(address cluster, uint256 effectiveBlock);
    event ClusterUnregistered(address cluster, uint256 updatedAt);
    event LockTimeUpdated(bytes32 selector, uint256 prevLockTime, uint256 updatedLockTime);

    function initialize(bytes32[] memory _selectors, uint256[] memory _lockWaitTimes, address _owner) 
        public 
        initializer
    {
        require(
            _selectors.length == _lockWaitTimes.length,
            "CR:I-Invalid params"
        );
        for(uint256 i=0; i < _selectors.length; i++) {
            lockWaitTime[_selectors[i]] = _lockWaitTimes[i];
            emit LockTimeUpdated(_selectors[i], 0, _lockWaitTimes[i]);
        }
        super.initialize(_owner);
    }

    function updateLockWaitTime(bytes32 _selector, uint256 _updatedWaitTime) external onlyOwner {
        emit LockTimeUpdated(_selector, lockWaitTime[_selector], _updatedWaitTime);
        lockWaitTime[_selector] = _updatedWaitTime; 
    }

    function register(
        bytes32 _networkId, 
        uint256 _commission, 
        address _rewardAddress, 
        address _clientKey
    ) external returns(bool) {
        // This happens only when the data of the cluster is registered or it wasn't registered before
        require(
            !isClusterValid(msg.sender), 
            "CR:R-Cluster is already registered"
        );
        require(_commission <= 100, "CR:R-Commission more than 100%");
        require(clientKeys[_clientKey] ==  address(0), "CR:R - Client key is already used");
        clusters[msg.sender].commission = _commission;
        clusters[msg.sender].rewardAddress = _rewardAddress;
        clusters[msg.sender].clientKey = _clientKey;
        clusters[msg.sender].networkId = _networkId;
        clusters[msg.sender].status = Status.REGISTERED;

        clientKeys[_clientKey] = msg.sender;
        
        emit ClusterRegistered(msg.sender, _networkId, _commission, _rewardAddress, _clientKey);
    }

    function updateCluster(uint256 _commission, bytes32 _networkId, address _rewardAddress, address _clientKey) public {
        if(_networkId != bytes32(0)) {
            switchNetwork(_networkId);
        }
        if(_rewardAddress != address(0)) {
            updateRewardAddress(_rewardAddress);
        }
        if(_clientKey != address(0)) {
            updateClientKey(_clientKey);
        }
        if(_commission != UINT256_MAX) {
            updateCommission(_commission);
        }
    }

    function updateCommission(uint256 _commission) public {
        require(
            isClusterValid(msg.sender),
            "CR:UCM-Cluster not registered"
        );
        require(_commission <= 100, "CR:UCM-Commission more than 100%");
        bytes32 lockId = keccak256(abi.encodePacked(COMMISSION_LOCK_SELECTOR, msg.sender));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        require(
            unlockBlock < block.number, 
            "CR:UCM-Commission update in progress"
        );
        if(unlockBlock != 0) {
            uint256 currentCommission = locks[lockId].iValue;
            clusters[msg.sender].commission = currentCommission;
            emit CommissionUpdated(msg.sender, currentCommission, unlockBlock);
        }
        uint256 updatedUnlockBlock = block.number.add(lockWaitTime[COMMISSION_LOCK_SELECTOR]);
        locks[lockId] = Lock(updatedUnlockBlock, _commission);
        emit CommissionUpdateRequested(msg.sender, _commission, updatedUnlockBlock);
    }

    function switchNetwork(bytes32 _networkId) public {
        require(
            isClusterValid(msg.sender),
            "CR:SN-Cluster not registered"
        );
        bytes32 lockId = keccak256(abi.encodePacked(SWITCH_NETWORK_LOCK_SELECTOR, msg.sender));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        require(
            unlockBlock < block.number,
            "CR:SN-Network switch in progress"
        );
        if(unlockBlock != 0) {
            bytes32 currentNetwork = bytes32(locks[lockId].iValue);
            clusters[msg.sender].networkId = currentNetwork;
            emit NetworkSwitched(msg.sender, currentNetwork, unlockBlock);
        }
        uint256 updatedUnlockBlock = block.number.add(lockWaitTime[SWITCH_NETWORK_LOCK_SELECTOR]);
        locks[lockId] = Lock(updatedUnlockBlock, uint256(_networkId));
        emit NetworkSwitchRequested(msg.sender, _networkId, updatedUnlockBlock);
    }

    function updateRewardAddress(address _rewardAddress) public {
        require(
            isClusterValid(msg.sender),
            "CR:URA-Cluster not registered"
        );
        clusters[msg.sender].rewardAddress = _rewardAddress;
        emit RewardAddressUpdated(msg.sender, _rewardAddress);
    }

    function updateClientKey(address _clientKey) public {
        // TODO: Add delay to client key updates as well
        require(
            isClusterValid(msg.sender),
            "CR:UCK-Cluster not registered"
        );
        require(clientKeys[_clientKey] ==  address(0), "CR:UCK - Client key is already used");
        delete clientKeys[clusters[msg.sender].clientKey];
        clusters[msg.sender].clientKey = _clientKey;
        clientKeys[_clientKey] = msg.sender;
        emit ClientKeyUpdated(msg.sender, _clientKey);
    }

    function unregister() external {
        require(
            clusters[msg.sender].status != Status.NOT_REGISTERED,
            "CR:UR-Cluster not registered"
        );
        bytes32 lockId = keccak256(abi.encodePacked(UNREGISTER_LOCK_SELECTOR, msg.sender));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        require(
            unlockBlock < block.number,
            "CR:UR-Unregistration already in progress"
        );
        if(unlockBlock != 0) {
            clusters[msg.sender].status = Status.NOT_REGISTERED;
            emit ClusterUnregistered(msg.sender, unlockBlock);
            delete clientKeys[clusters[msg.sender].clientKey];
            delete locks[lockId];
            delete locks[keccak256(abi.encodePacked(COMMISSION_LOCK_SELECTOR, msg.sender))];
            delete locks[keccak256(abi.encodePacked(SWITCH_NETWORK_LOCK_SELECTOR, msg.sender))];
            return;
        }
        uint256 updatedUnlockBlock = block.number.add(lockWaitTime[UNREGISTER_LOCK_SELECTOR]);
        locks[lockId] = Lock(updatedUnlockBlock, 0);
        emit ClusterUnregisterRequested(msg.sender, updatedUnlockBlock);
    }

    function isClusterValid(address _cluster) public returns(bool) {
        bytes32 lockId = keccak256(abi.encodePacked(UNREGISTER_LOCK_SELECTOR, _cluster));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        if(unlockBlock != 0 && unlockBlock < block.number) {
            clusters[_cluster].status = Status.NOT_REGISTERED;
            delete clientKeys[clusters[_cluster].clientKey];
            emit ClusterUnregistered(_cluster, unlockBlock);
            delete locks[lockId];
            delete locks[keccak256(abi.encodePacked(COMMISSION_LOCK_SELECTOR, msg.sender))];
            delete locks[keccak256(abi.encodePacked(SWITCH_NETWORK_LOCK_SELECTOR, msg.sender))];
            return false;
        }
        return (clusters[_cluster].status != Status.NOT_REGISTERED);    // returns true if the status is registered
    }

    function getCommission(address _cluster) public returns(uint256) {
        bytes32 lockId = keccak256(abi.encodePacked(COMMISSION_LOCK_SELECTOR, _cluster));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        if(unlockBlock != 0 && unlockBlock < block.number) {
            uint256 currentCommission = locks[lockId].iValue;
            clusters[_cluster].commission = currentCommission;
            emit CommissionUpdated(_cluster, currentCommission, unlockBlock);
            delete locks[lockId];
            return currentCommission;
        }
        return clusters[_cluster].commission;
    }

    function getNetwork(address _cluster) public returns(bytes32) {
        bytes32 lockId = keccak256(abi.encodePacked(SWITCH_NETWORK_LOCK_SELECTOR, _cluster));
        uint256 unlockBlock = locks[lockId].unlockBlock;
        if(unlockBlock != 0 && unlockBlock < block.number) {
            bytes32 currentNetwork = bytes32(locks[lockId].iValue);
            clusters[msg.sender].networkId = currentNetwork;
            emit NetworkSwitched(msg.sender, currentNetwork, unlockBlock);
            delete locks[lockId];
            return currentNetwork;
        }
        return clusters[_cluster].networkId;
    }

    function getRewardAddress(address _cluster) external view returns(address) {
        return clusters[_cluster].rewardAddress;
    }

    function getClientKey(address _cluster) external view returns(address) {
        return clusters[_cluster].clientKey;
    }

    function getCluster(address _cluster) external returns(
        uint256 commission, 
        address rewardAddress, 
        address clientKey, 
        bytes32 networkId, 
        bool isValidCluster
    ) {
        return (
            getCommission(_cluster), 
            clusters[_cluster].rewardAddress, 
            clusters[_cluster].clientKey, 
            getNetwork(_cluster), 
            isClusterValid(_cluster)
        );
    }

    function getRewardInfo(address _cluster) external returns(uint256, address) {
        return (getCommission(_cluster), clusters[_cluster].rewardAddress);
    }
    
    function addClientKeys(address[] calldata _clusters) external onlyOwner {
        for(uint256 i=0; i < _clusters.length; i++) {
            address _clientKey = clusters[_clusters[i]].clientKey;
            require(_clientKey != address(0), "CR:ACK - Cluster has invalid client key");
            clientKeys[_clientKey] = _clusters[i];
        }
    }
}