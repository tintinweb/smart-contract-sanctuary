pragma solidity ^0.5.5;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

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

contract SupporterRole is Context {
    using Roles for Roles.Role;

    event SupporterAdded(address indexed account);
    event SupporterRemoved(address indexed account);

    Roles.Role private _supporters;

    constructor () internal {
        _addSupporter(_msgSender());
    }

    modifier onlySupporter() {
        require(isSupporter(_msgSender()), "SupporterRole: caller does not have the Supporter role");
        _;
    }

    function isSupporter(address account) public view returns (bool) {
        return _supporters.has(account);
    }

    function addSupporter(address account) public onlySupporter {
        _addSupporter(account);
    }

    function renounceSupporter() public {
        _removeSupporter(_msgSender());
    }

    function _addSupporter(address account) internal {
        _supporters.add(account);
        emit SupporterAdded(account);
    }

    function _removeSupporter(address account) internal {
        _supporters.remove(account);
        emit SupporterRemoved(account);
    }
}

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() internal view returns (address) {
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
    function isOwner() internal view returns (bool) {
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

/**
 * @dev A Secondary contract can only be used by its primary account (the one that created it).
 */
contract Secondary is Context {
    address private _primary;

    /**
     * @dev Emitted when the primary contract changes.
     */
    event PrimaryTransferred(
        address recipient
    );

    /**
     * @dev Sets the primary account to the one that is creating the Secondary contract.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _primary = msgSender;
        emit PrimaryTransferred(msgSender);
    }

    /**
     * @dev Reverts if called from any account other than the primary.
     */
    modifier onlyPrimary() {
        require(_msgSender() == _primary, "Secondary: caller is not the primary account");
        _;
    }

    /**
     * @return the address of the primary.
     */
    function primary() public view returns (address) {
        return _primary;
    }

    /**
     * @dev Transfers contract to a new primary.
     * @param recipient The address of new primary.
     */
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0), "Secondary: new primary is the zero address");
        _primary = recipient;
        emit PrimaryTransferred(recipient);
    }
}

/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostDeliveryCrowdsale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
contract __unstable__TokenVault is Secondary {
    function transferToken(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
    function transferFunds(address payable to, uint256 amount) public onlyPrimary {
        require (address(this).balance >= amount);
        to.transfer(amount);
    }
    function () external payable {}
}

/**
 * @title MoonStaking
 */
contract MoonStaking is Ownable, Pausable, SupporterRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Pool {
        uint256 rate;
        uint256 adapter;
        uint256 totalStaked;
    }
    struct User {
        mapping(address => UserSp) tokenPools;
        UserSp ePool;
	}
    struct UserSp {
        uint256 staked;
        uint256 lastRewardTime;
        uint256 earned;
	}

    mapping(address => User) users;
    mapping(address => Pool) pools;

    // The MOON TOKEN!
    IERC20 public moon;

    uint256 eRate;
    uint256 eAdapter;
    uint256 eTotalStaked;

    __unstable__TokenVault private _vault;

    /**
     * @param _moon The MOON token.
     */
    constructor(IERC20 _moon) public {
        _vault = new __unstable__TokenVault();
        moon = _moon;
    }

    /**
    * @dev Update token pool rate
    * @return True when successful
    */
    function updatePoolRate(address pool, uint256 _rate, uint256 _adapter)
        public onlyOwner returns (bool) {
        pools[pool].rate = _rate;
        pools[pool].adapter = _adapter;
        return true;
    }

    /**
    * @dev Update epool pool rate
    * @return True when successful
    */
    function updateEpoolRate(uint256 _rate, uint256 _adapter)
        public onlyOwner returns (bool) {
        eRate = _rate;
        eAdapter = _adapter;
        return true;
    }

    /**
    * @dev Checks whether the pool is available.
    * @return Whether the pool is available.
    */
    function isPoolAvailable(address pool) public view returns (bool) {
        return pools[pool].rate != 0;
    }

    /**
    * @dev View pool token info
    * @param _pool Token address.
    * @return Pool info
    */
    function poolTokenInfo(address _pool) public view returns (
        uint256 rate,
        uint256 adapter,
        uint256 totalStaked
    ) {
        Pool storage pool = pools[_pool];
        return (pool.rate, pool.adapter, pool.totalStaked);
    }

    /**
    * @dev View pool E info
    * @return Pool info
    */
    function poolInfo(address poolAddress) public view returns (
        uint256 rate,
        uint256 adapter,
        uint256 totalStaked
    ) {
        Pool storage sPool = pools[poolAddress];
        return (sPool.rate, sPool.adapter, sPool.totalStaked);
    }

    /**
    * @dev View pool E info
    * @return Pool info
    */
    function poolEInfo() public view returns (
        uint256 rate,
        uint256 adapter,
        uint256 totalStaked
    ) {
        return (eRate, eAdapter, eTotalStaked);
    }

        /**
     * @dev Get earned reward in e pool.
     */
    function getEarnedEpool() public view returns (uint256) {
        UserSp storage pool = users[_msgSender()].ePool;
        return _getEarned(eRate, eAdapter, pool);
    }

    /**
     * @dev Get earned reward in t pool.
     */
    function getEarnedTpool(address stakingPoolAddress) public view returns (uint256) {
        UserSp storage stakingPool = users[_msgSender()].tokenPools[stakingPoolAddress];
        Pool storage pool = pools[stakingPoolAddress];
        return _getEarned(pool.rate, pool.adapter, stakingPool);
    }

    /**
     * @dev Stake with E
     * @return true if successful
     */
    function stakeE() public payable returns (bool) {
        uint256 _value = msg.value;
        require(_value != 0, "Zero amount");
        address(uint160((address(_vault)))).transfer(_value);
        UserSp storage ePool = users[_msgSender()].ePool;
        ePool.earned = ePool.earned.add(_getEarned(eRate, eAdapter, ePool));
        ePool.lastRewardTime = block.timestamp;
        ePool.staked = ePool.staked.add(_value);
        eTotalStaked = eTotalStaked.add(_value);
        return true;
    }

    /**
     * @dev Stake with tokens
     * @param _value Token amount.
     * @param token Token address.
     * @return true if successful
     */
    function stake(uint256 _value, IERC20 token) public returns (bool) {
        require(token.balanceOf(_msgSender()) >= _value, "Insufficient Funds");
        require(token.allowance(_msgSender(), address(this)) >= _value, "Insufficient Funds Approved");
        address tokenAddress = address(token);
        require(isPoolAvailable(tokenAddress), "Pool is not available");
        _forwardFundsToken(token, _value);
        Pool storage pool = pools[tokenAddress];
        UserSp storage tokenPool = users[_msgSender()].tokenPools[tokenAddress];
        tokenPool.earned = tokenPool.earned.add(_getEarned(pool.rate, pool.adapter, tokenPool));
        tokenPool.lastRewardTime = block.timestamp;
        tokenPool.staked = tokenPool.staked.add(_value);
        pool.totalStaked = pool.totalStaked.add(_value);
        return true;
    }

    /**
     * @dev Withdraw all available tokens.
     */
    function withdrawTokenPool(address token) public whenNotPaused nonReentrant returns (bool) {
        UserSp storage tokenStakingPool = users[_msgSender()].tokenPools[token];
        require(tokenStakingPool.staked > 0 != tokenStakingPool.earned > 0, "Not available");
        if (tokenStakingPool.earned > 0) {
            Pool storage pool = pools[token];
            _vault.transferToken(moon, _msgSender(),  _getEarned(pool.rate, pool.adapter, tokenStakingPool));
            tokenStakingPool.lastRewardTime = block.timestamp;
            tokenStakingPool.earned = 0;
        }
        if (tokenStakingPool.staked > 0) {
            _vault.transferToken(IERC20(token), _msgSender(), tokenStakingPool.staked);
            tokenStakingPool.staked = 0;
        }
        return true;
    }

    /**
     * @dev Withdraw all available tokens.
     */
    function withdrawEPool() public whenNotPaused nonReentrant returns (bool) {
        UserSp storage eStakingPool = users[_msgSender()].ePool;
        require(eStakingPool.staked > 0 != eStakingPool.earned > 0, "Not available");
        if (eStakingPool.earned > 0) {
            _vault.transferToken(moon, _msgSender(),  _getEarned(eRate, eAdapter, eStakingPool));
            eStakingPool.lastRewardTime = block.timestamp;
            eStakingPool.earned = 0;
        }
        if (eStakingPool.staked > 0) {
            _vault.transferFunds(_msgSender(), eStakingPool.staked);
            eStakingPool.staked = 0;
        }
        return true;
    }

    /**
     * @dev Claim earned Moon.
     */
    function claimMoonInTpool(address token) public whenNotPaused returns (bool) {
        UserSp storage tokenStakingPool = users[_msgSender()].tokenPools[token];
        require(tokenStakingPool.staked > 0 != tokenStakingPool.earned > 0, "Not available");
        Pool storage pool = pools[token];
        _vault.transferToken(moon, _msgSender(), _getEarned(pool.rate, pool.adapter, tokenStakingPool));
        tokenStakingPool.lastRewardTime = block.timestamp;
        tokenStakingPool.earned = 0;
        return true;
    }

    /**
     * @dev Claim earned Moon.
     */
    function claimMoonInEpool() public whenNotPaused returns (bool) {
        UserSp storage eStakingPool = users[_msgSender()].ePool;
        require(eStakingPool.staked > 0 != eStakingPool.earned > 0, "Not available");
        _vault.transferToken(moon, _msgSender(), _getEarned(eRate, eAdapter, eStakingPool));
        eStakingPool.lastRewardTime = block.timestamp;
        eStakingPool.earned = 0;
        return true;
    }

    /**
     * @dev Get reserved token.
     */
    function getReserved() public view onlyOwner
        returns (uint256 vaultTokens, uint256 vaultFunds) {
        address vaultAddress = address(_vault);
        vaultTokens = moon.balanceOf(vaultAddress);
        vaultFunds = address(uint160(vaultAddress)).balance;
    }

    /**
     * @dev Get reserved token by address.
     */
    function getReservedByAddress(IERC20 token) public view onlyOwner returns (uint256) {
        return token.balanceOf(address(_vault));
    }

    /**
     * @dev Supply token for the vaults.
     * @param amount Supply amount
     */
    function supplyVault(uint256 amount)
        public onlyOwner
        returns (bool) {
        moon.transferFrom(_msgSender(), address(_vault), amount);
        return true;
    }

    /**
     * @dev deprive tokens from vaults.
     * @param vault Vault address
     * @param amount The amount
     */
    function depriveToken(address vault, IERC20 token, uint256 amount)
        public onlyOwner returns (bool) {
        _vault.transferToken(token, vault, amount);
        return true;
    }

    /**
     * @dev deprive funds from vaults.
     * @param vault Vault address
     * @param amount The amount
     */
    function depriveFunds(address payable vault, uint256 amount)
        public onlyOwner
        returns (bool) {
        _vault.transferFunds(vault, amount);
        return true;
    }

    /**
     * @dev Fallback function
     */
    function () external payable {
        address(uint160((address(_vault)))).transfer(msg.value);
    }

    /**
     * @dev Extend parent behavior
     * @param erc20Token ERC20 Token
     * @param _value Amount contributed
     */
    function _forwardFundsToken(IERC20 erc20Token, uint256 _value) internal {
        erc20Token.transferFrom(_msgSender(), address(_vault), _value);
    }

    /**
     * @dev Get earned reward.
     */
    function _getEarned(uint256 rate, uint256 adapter, UserSp memory stakingPool) internal view returns (uint256) {
        uint256 moonPerSec = stakingPool.staked.mul(rate).div(adapter);
        return block.timestamp.sub(stakingPool.lastRewardTime).mul(moonPerSec).add(stakingPool.earned);
    }
}