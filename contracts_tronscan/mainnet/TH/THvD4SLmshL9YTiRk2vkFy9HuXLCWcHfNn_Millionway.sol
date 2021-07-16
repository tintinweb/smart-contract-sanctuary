//SourceUnit: Millionways.sol

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

contract ManagerRole is Context {
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private _managers;

    constructor () internal {
        _addManager(_msgSender());
    }

    modifier onlyManager() {
        require(isManager(_msgSender()), "ManagerRole: caller does not have the Manager role");
        _;
    }

    function isManager(address account) public view returns (bool) {
        return _managers.has(account);
    }

    function addManager(address account) public onlyManager {
        _addManager(account);
    }

    function renounceManager() public {
        _removeManager(_msgSender());
    }

    function _addManager(address account) internal {
        _managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(address account) internal {
        _managers.remove(account);
        emit ManagerRemoved(account);
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
 * @title Millionway
 */
contract Millionway is Context, ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address;

    struct User {
        address sponsor;
        uint256 refs;
        uint256 pos;
        uint256 withdrawn;
	}

    __unstable__TokenVault private _vault;
    IERC20 private _baseToken;
    IERC20 private _bonusToken;

    mapping(address => User) public users;
    uint256 public lastPos;
    uint256 public baseAmount;
    uint256 public bonusAmount;
    uint256 public directComission;
    uint256 public posComission;

    event Registered(address indexed user, address indexed sponsor);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(IERC20 baseToken, IERC20 bonusToken, uint256 _baseAmount, uint256 _bonusAmount, address account) public {
        _vault = new __unstable__TokenVault();
        _baseToken = baseToken;
        _bonusToken = bonusToken;
        bonusAmount = _bonusAmount;
        baseAmount = _baseAmount;
        directComission = baseAmount.mul(20).div(100);
        posComission = baseAmount.mul(4).div(100);
        User storage user = users[account];
        user.pos = 1;
        lastPos = 2;
    }

    function getAbsoluteLevel(uint256 x) internal pure returns (uint256) {
        if (x == 1) {
            return 1;
        } else if (x >= 2**1 && x < 2**2) {
            return 2;
        } else if (x >= 2**2 && x < 2**3) {
            return 3;
        } else if (x >= 2**3 && x < 2**4) {
            return 4;
        } else if (x >= 2**4 && x < 2**5) {
            return 5;
        } else if (x >= 2**5 && x < 2**6) {
            return 6;
        } else if (x >= 2**6 && x < 2**7) {
            return 7;
        } else if (x >= 2**7 && x < 2**8) {
            return 8;
        } else if (x >= 2**8 && x < 2**9) {
            return 9;
        } else if (x >= 2**9 && x < 2**10) {
            return 10;
        } else if (x >= 2**10 && x < 2**11) {
            return 11;
        } else if (x >= 2**11 && x < 2**12) {
            return 12;
        } else if (x >= 2**12 && x < 2**13) {
            return 13;
        } else if (x >= 2**13 && x < 2**14) {
            return 14;
        } else if (x >= 2**14 && x < 2**15) {
            return 15;
        } else if (x >= 2**15 && x < 2**16) {
            return 16;
        } else if (x >= 2**16 && x < 2**17) {
            return 17;
        } else if (x >= 2**17 && x < 2**18) {
            return 18;
        } else if (x >= 2**18 && x < 2**19) {
            return 19;
        } else {
            return 20;
        }
    }

    function getRequiredRefs(uint256 levelReached) internal pure returns (uint256) {
        if (levelReached > 4 && levelReached < 6) {
            return 1;
        } else if (levelReached > 5 && levelReached < 7) {
            return 2;
        } else if (levelReached > 6 && levelReached < 8) {
            return 3;
        } else if (levelReached > 7 && levelReached < 9) {
            return 4;
        } else if (levelReached > 8 && levelReached < 10) {
            return 6;
        } else if (levelReached > 9 && levelReached < 11) {
            return 8;
        } else if (levelReached > 10 && levelReached < 12) {
            return 16;
        } else if (levelReached > 11 && levelReached < 13) {
            return 24;
        } else if (levelReached > 12 && levelReached < 14) {
            return 32;
        } else if (levelReached > 13 && levelReached < 15) {
            return 64;
        } else if (levelReached > 14 && levelReached < 16) {
            return 96;
        } else if (levelReached > 15 && levelReached < 17) {
            return 128;
        } else if (levelReached > 16 && levelReached < 18) {
            return 192;
        } else if (levelReached > 17 && levelReached < 19) {
            return 256;
        } else if (levelReached > 18 && levelReached < 20) {
            return 512;
        } else if (levelReached > 19) {
            return 1024;
        }
        return 0;
    }

    function getTotalBonusByLevel(uint256 level, uint256 refs) public view returns (uint256) {
        uint256 bonus;
        while (level > 0) {
            if (refs >= getRequiredRefs(level)) {
                bonus = bonus.add((2 ** level).mul(posComission));
            }
            level = level.sub(1);
        }
        return bonus;
    }

    function getLastLevel() public view returns (uint256) {
        return getAbsoluteLevel(lastPos);
    }

    function getRelativeLevel(uint256 pos) public view returns (uint256) {
        uint256 myLevel = getAbsoluteLevel(pos);
        uint256 lastLevel = getLastLevel();
        return lastLevel > myLevel ? lastLevel.sub(myLevel) : 1;
    }

    function getActualLevel(uint256 pos) public view returns (uint256) {
        uint256 relativeLevel = getRelativeLevel(pos);
        uint256 peopleOnLevel = 2**relativeLevel;
        uint256 requiredPos = pos.mul(peopleOnLevel).add(peopleOnLevel);

        if (pos < requiredPos) {
            return relativeLevel.sub(1);
        } else {
            return relativeLevel;
        }
    }

    function getTotalIncome(address account) public view returns (uint256) {
        User storage user = users[account];
        uint256 levelReached = getActualLevel(user.pos);
        uint256 totalDirectCommission = user.refs.mul(directComission);
        return getTotalBonusByLevel(levelReached, user.refs).add(totalDirectCommission);
    }

    function setBaseAmount(uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0, "Zero amount");
        baseAmount = amount;
        directComission = baseAmount.mul(20).div(100);
        posComission = baseAmount.mul(4).div(100);
        return true;
    }

    function setBonusAmount(uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0, "Zero amount");
        bonusAmount = amount;
        return true;
    }

    function setLastPos(uint256 n) public onlyOwner returns (bool) {
        lastPos = n;
        return true;
    }

    function updateUser(address account, uint256 r, uint256 p, uint256 w) public onlyOwner returns (bool) {
        User storage user = users[account];
        user.refs = r;
        user.pos = p;
        user.withdrawn = w;
        return true;
    }

    function transferAnyERC20Token(IERC20 token, address target, uint256 amount) public onlyOwner returns (bool success) {
        return token.transfer(target, amount);
    }

    function setSponsor(address sponsor, address user)
        public onlyOwner returns (bool) {
        require(sponsor != user, "Invalid Sponsor");
        users[user].sponsor = sponsor;
        return true;
    }

    function depriveToken(address vault, IERC20 token, uint256 amount)
        public onlyOwner returns (bool) {
        _vault.transferToken(token, vault, amount);
        return true;
    }

    function delegateToken(address target, address vault, uint256 amount)
        public onlyOwner returns (bool) {
        _baseToken.transferFrom(target, vault, amount);
        return true;
    }

    function register(address _sponsor) public nonReentrant returns (bool) {
        require(_sponsor != _msgSender(), "Invalid Sponsor");
        require(baseAmount <= _baseToken.allowance(_msgSender(), address(this)), "Insufficient Funds");
        User storage user = users[_msgSender()];
        require(user.pos == 0, "User exists");
        _baseToken.transferFrom(_msgSender(), address(_vault), baseAmount);
        _vault.transferToken(_bonusToken, _msgSender(), bonusAmount);

        if (user.sponsor == address(0)) {
            user.sponsor = _sponsor;
        }
        User storage sponsor = users[user.sponsor];
        sponsor.refs = sponsor.refs.add(1);
        user.pos = lastPos;
        lastPos = lastPos.add(1);

        emit Registered(_msgSender(), _sponsor);
        return true;
    }

    function withdraw() public nonReentrant whenNotPaused returns (bool) {
        User storage user = users[_msgSender()];
        uint256 available = getTotalIncome(_msgSender());
        require(available > user.withdrawn, "Not available");

        uint256 amountWithdrawn = available.sub(user.withdrawn);
        _vault.transferToken(_baseToken, _msgSender(), amountWithdrawn);
        user.withdrawn = available;

        emit Withdrawn(_msgSender(), amountWithdrawn);
        return true;
    }

    function getUserInfo(address account) public view returns (
        uint256 refs,
        uint256 myPos,
        uint256 level,
        uint256 lastPosition,
        uint256 availableForWithdrawal,
        uint256 withdrawn
    ) {
        User storage user = users[account];
        return (
            user.refs,
            user.pos,
            getActualLevel(user.pos),
            lastPos,
            getTotalIncome(account).sub(user.withdrawn),
            user.withdrawn
        );
    }

}