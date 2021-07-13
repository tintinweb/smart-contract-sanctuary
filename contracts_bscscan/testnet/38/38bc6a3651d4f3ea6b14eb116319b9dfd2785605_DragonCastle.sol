/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Math.sol

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/Context.sol

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/IERC20.sol

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

// File: contracts/Address.sol

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
}

// File: contracts/ERC20.sol

pragma solidity ^0.6.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = _msgSender();
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

pragma solidity >=0.6.0 <0.8.0;

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

    constructor() internal {
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

// File: contracts/DragonCastle.sol

pragma solidity 0.6.12;

contract DragonCastle is Ownable, ReentrancyGuard, ERC20("Dragon Castle","gDRAGON"){
    using SafeMath for uint256;

    // The address of the smart chef factory
    address public DRAGON_CASTLE_FACTORY;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether a limit is set for the pool
    bool public hasPoolLimit;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    mapping(ERC20 => uint256) public accTokenPerShare;

    // The block number when DRAGON mining ends.
    uint256 public bonusEndBlock;

    // The block number when DRAGON mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // The pool limit per user (0 if none)
    uint256 public poolLimitPerUser;

    // The pool cap (0 if none)
    uint256 public poolCap;

    // Whether the pool's staked token balance can be remove by owner
    bool private isRemovable;

    // DRAGON tokens created per block.
    mapping(ERC20 => uint256) public rewardPerBlock;

    // The precision factor
    mapping(ERC20 => uint256) public PRECISION_FACTOR;

    // The reward token
    ERC20[] public rewardTokens;

    // The staked token
    ERC20 public stakedToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        mapping(ERC20 => uint256) rewardDebt; // Reward debt
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock, ERC20 token);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event NewPoolCap(uint256 poolCap);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);
    event NewRewardToken(ERC20 token, uint256 rewardPerBlock, uint256 p_factor);
    event RemoveRewardToken(ERC20 token);

    constructor() public {
        DRAGON_CASTLE_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _poolCap: pool cap in stakedToken (if any, else 0)
     * @param _admin: admin address with ownership
     */
    function initialize(
        ERC20 _stakedToken,
        ERC20[] memory _rewardTokens,
        uint256[] memory _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        uint256 _poolCap,
        bool _isRemovable,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == DRAGON_CASTLE_FACTORY, "Not factory");
        require(_rewardTokens.length == _rewardPerBlock.length, "Mismatch length");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardTokens = _rewardTokens;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        isRemovable = _isRemovable;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }
        if (_poolCap > 0){
            hasPoolLimit = true;
            poolCap = _poolCap;
        }
        
        uint256 decimalsRewardToken;
        for(uint i = 0; i< _rewardTokens.length; i++){
            decimalsRewardToken = uint256(_rewardTokens[i].decimals());
            require(decimalsRewardToken < 30, "Must be inferior to 30");
            PRECISION_FACTOR[_rewardTokens[i]] = uint256(10**(uint256(30).sub(decimalsRewardToken)));
            rewardPerBlock[_rewardTokens[i]] = _rewardPerBlock[i];
        }

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (hasPoolLimit) {
            uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
            require(_amount.add(stakedTokenSupply) <= poolCap, "Pool cap reached");
        }

        if (hasUserLimit) {
            require(_amount.add(user.amount) <= poolLimitPerUser, "User amount above limit");
        }

        _updatePool();

        if (user.amount > 0) {
            uint256 pending;
            for(uint i = 0; i < rewardTokens.length; i++){
                pending = user.amount.mul(accTokenPerShare[rewardTokens[i]]).div(PRECISION_FACTOR[rewardTokens[i]]).sub(user.rewardDebt[rewardTokens[i]]);
                if (pending > 0) {
                    ERC20(rewardTokens[i]).transfer(address(msg.sender), pending);
                }
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            ERC20(stakedToken).transferFrom(address(msg.sender), address(this), _amount);
            _mint(address(msg.sender),_amount);
        }
        for(uint i = 0; i < rewardTokens.length; i++){
            user.rewardDebt[rewardTokens[i]] = user.amount.mul(accTokenPerShare[rewardTokens[i]]).div(PRECISION_FACTOR[rewardTokens[i]]);
        }

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        // uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        uint256 pending;
        for(uint i = 0; i < rewardTokens.length; i++){
            pending = user.amount.mul(accTokenPerShare[rewardTokens[i]]).div(PRECISION_FACTOR[rewardTokens[i]]).sub(user.rewardDebt[rewardTokens[i]]);
            if (pending > 0) {
                ERC20(rewardTokens[i]).transfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            ERC20(stakedToken).transfer(address(msg.sender), _amount);
            _burn(address(msg.sender),_amount);
        }
        for(uint i = 0; i < rewardTokens.length; i++){
            user.rewardDebt[rewardTokens[i]] = user.amount.mul(accTokenPerShare[rewardTokens[i]]).div(PRECISION_FACTOR[rewardTokens[i]]);
        }

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        for(uint i = 0; i < rewardTokens.length; i++){
            user.rewardDebt[rewardTokens[i]] = 0;
        }

        if (amountToTransfer > 0) {
            ERC20(stakedToken).transfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        for(uint i = 0; i < rewardTokens.length; i++){
            ERC20(rewardTokens[i]).transfer(address(msg.sender), _amount);
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        // require(_tokenAddress != address(rewardToken), "Cannot be reward token");
        for(uint i = 0; i < rewardTokens.length; i++){
            require(_tokenAddress != address(rewardTokens[i]), "Cannot be reward token");
        }

        ERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Allow owner to remove all staked token from pool.
     * @param _amount: amount to withdraw (in stakedToken)
     * @dev Only callable by owner
     */
    function emergencyRemoval(uint256 _amount) external onlyOwner {
        require(isRemovable, "The pool is not removable");
        require(stakedToken.balanceOf(address(this)) >= _amount, "Amount exceeds pool balance");
        if (_amount > 0) {
            ERC20(stakedToken).transfer(address(msg.sender), _amount);
        }
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            // require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update pool cap
     * @dev Only callable by owner.
     * @param _hasPoolLimit: whether the cap remains forced
     * @param _poolCap: new pool limit per user
     */
    function updatePoolCap(bool _hasPoolLimit, uint256 _poolCap) external onlyOwner {
        require(hasPoolLimit, "Must be set");
        if (_hasPoolLimit) {
            // require(_poolCap > poolCap, "New cap must be higher");
            poolCap = _poolCap;
        } else {
            hasPoolLimit = _hasPoolLimit;
            poolCap = 0;
        }
        emit NewPoolCap(poolCap);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock, ERC20 _token) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        (bool foundToken, uint tokenIndex) = findElementPosition(_token,rewardTokens);
        require(foundToken, "Cannot find token");
        rewardPerBlock[_token] = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock,_token);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256[] memory, ERC20[] memory) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        uint256[] memory userPendingRewards = new uint256[](rewardTokens.length);
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 dragonReward;
            uint256 adjustedTokenPerShare;
            for(uint i = 0; i < rewardTokens.length; i++){
                dragonReward = multiplier.mul(rewardPerBlock[rewardTokens[i]]);
                adjustedTokenPerShare = accTokenPerShare[rewardTokens[i]].add(dragonReward.mul(PRECISION_FACTOR[rewardTokens[i]]).div(stakedTokenSupply));
                userPendingRewards[i] = user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR[rewardTokens[i]]).sub(user.rewardDebt[rewardTokens[i]]);
            }
            return (userPendingRewards, rewardTokens);
        } else {
            for(uint i = 0; i < rewardTokens.length; i++){
                userPendingRewards[i] = user.amount.mul(accTokenPerShare[rewardTokens[i]]).div(PRECISION_FACTOR[rewardTokens[i]]).sub(user.rewardDebt[rewardTokens[i]]);
            }
            return (userPendingRewards, rewardTokens);
        }
    }

    /*
     * @notice View function to see pending reward on frontend (categorized by rewardToken)
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingRewardByToken(address _user, ERC20 _token) external view returns (uint256) {
        (bool foundToken, uint tokenIndex) = findElementPosition(_token,rewardTokens);
        if(!foundToken){
            return 0;
        }
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        uint256 userPendingReward;
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 dragonReward = multiplier.mul(rewardPerBlock[_token]);
            uint256 adjustedTokenPerShare = accTokenPerShare[_token].add(dragonReward.mul(PRECISION_FACTOR[_token]).div(stakedTokenSupply));
            userPendingReward = user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR[_token]).sub(user.rewardDebt[_token]);
            return userPendingReward;
        } else {
            return user.amount.mul(accTokenPerShare[_token]).div(PRECISION_FACTOR[_token]).sub(user.rewardDebt[_token]);
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 dragonReward;
        for(uint i = 0; i < rewardTokens.length; i++){
            dragonReward = multiplier.mul(rewardPerBlock[rewardTokens[i]]);
            accTokenPerShare[rewardTokens[i]] = accTokenPerShare[rewardTokens[i]].add(dragonReward.mul(PRECISION_FACTOR[rewardTokens[i]]).div(stakedTokenSupply));
        }
        lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    /*
     * @notice Add new reward token.
     * @param _token: new rewardToken to add
     * @param _rewardPerBlock: _token's rewardPerBlock
     */
    function addRewardToken(ERC20 _token, uint256 _rewardPerBlock) external onlyOwner {
        require(address(_token) != address(0), "Must be a real token");
        require(address(_token) != address(this), "Must be a real token");
        (bool foundToken, uint tokenIndex) = findElementPosition(_token,rewardTokens);
        require(!foundToken, "Token exists");
        rewardTokens.push(_token);

        uint256 decimalsRewardToken = uint256(_token.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR[_token] = uint256(10**(uint256(30).sub(decimalsRewardToken)));
        rewardPerBlock[_token] = _rewardPerBlock;
        accTokenPerShare[_token] = 0;

        emit NewRewardToken(_token,_rewardPerBlock,PRECISION_FACTOR[_token]);
    }

    /*
     * @notice Remove a reward token.
     * @param _token: rewardToken to remove
     */
    function removeRewardToken(ERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "Must be a real token");
        require(address(_token) != address(this), "Must be a real token");
        require(rewardTokens.length > 0, "List of token is empty");
        
        (bool foundToken, uint tokenIndex) = findElementPosition(_token,rewardTokens);
        require(foundToken, "Cannot find token");
        (bool success, ERC20[] memory newRewards) = removeElement(tokenIndex,rewardTokens);
        rewardTokens = newRewards;
        require(success, "Remove token unsuccessfully");
        PRECISION_FACTOR[_token] = 0;
        rewardPerBlock[_token] = 0;
        accTokenPerShare[_token] = 0;

        emit RemoveRewardToken(_token);
    } 

    /*
     * @notice Remove element at index.
     * @param _index: index of the element to remove
     * @param _array: array of which to remove element at _index
     */
    function removeElement(uint _index, ERC20[] storage _array) internal returns(bool,ERC20[] memory) {
        if(_index >= _array.length){
            return (false,_array);
        }

        for (uint i = _index; i<_array.length-1; i++){
            _array[i] = _array[i+1];
        }

        _array.pop();
        return (true,_array);
    }

    /*
     * @notice Find element position in array.
     * @param _token: token of which to find position
     * @param _array: array that contains _token
     */
    function findElementPosition(ERC20 _token, ERC20[] storage _array) internal view returns(bool,uint){
        for(uint i = 0; i < _array.length; i++){
            if(_array[i] == _token){
                return (true,i);
            }
        }
        return (false,0);
    }

    function getUserDebt(address _usr) external view returns(ERC20[] memory, uint256[] memory){
        uint256[] memory userDebt = new uint256[](rewardTokens.length);
        UserInfo storage user = userInfo[_usr];
        for(uint i = 0; i < rewardTokens.length; i++){
            userDebt[i] = user.rewardDebt[rewardTokens[i]];
        }
        return (rewardTokens,userDebt);
    }

    function getUserDebtByToken(address _usr, ERC20 _token) external view returns(uint256){
        UserInfo storage user = userInfo[_usr];
        return (user.rewardDebt[_token]);
    }

    //*Overrid transfer functions, allowing receipts to be transferable */

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        UserInfo storage _sender = userInfo[_msgSender()];
        UserInfo storage _receiver = userInfo[recipient];

        _transfer(_msgSender(), recipient, amount);

        _sender.amount = _sender.amount.sub(amount);
        _receiver.amount = _receiver.amount.add(amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        UserInfo storage _sender = userInfo[sender];
        UserInfo storage _receiver = userInfo[recipient];

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender,_msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));

        _sender.amount = _sender.amount.sub(amount);
        _receiver.amount = _receiver.amount.add(amount);
        return true;
    }
}