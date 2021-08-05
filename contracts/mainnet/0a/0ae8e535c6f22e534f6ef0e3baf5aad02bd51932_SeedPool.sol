/**
 *Submitted for verification at Etherscan.io on 2021-01-13
*/

// Dependency file: contracts/seedpool/State.sol

// SPDX-License-Identifier: MIT

// pragma solidity 0.6.12;


contract State {
    // admin address
    address payable admin;

    // reward token
    address token;

    // controller
    address controller;

    struct Pool {
        // token address of this pool
        // use address(0) for ETH
        address token;

        uint256 stakingBalance;
        uint256 stakedBalance;
    }

    struct User {
        // amount of token or ETH users deposited
        // but has not traded yet
        // this balance will not receive profit
        uint256 stakingBalance;

        // amount of token or ETH users deposited
        // this balance will receive profit
        uint256 stakedBalance;

        // amount of pending reward, users can harvest this
        // this value calculated when admin update the pool
        uint256 pendingReward;
    }

    struct UnstakeRequest {
        // user address
        address user;

        // unstake amount requested by user
        uint256 amount;

        // if true, request processed, just ignore it
        bool processed;
    }

    Pool[] pools;
    mapping(uint256 => address[]) usersList;
    mapping(uint256 => mapping(address => User)) users;
    mapping(uint256 => UnstakeRequest[]) unstakeRequests;

    // pool
    function getPoolsLength() public view returns(uint256) {
        return pools.length;
    }

    function getPool(uint256 _pool) public view returns(address) {
        return pools[_pool].token;
    }

    // users list
    function getUsersListLength(uint256 _pool) public view returns(uint256) {
        return usersList[_pool].length;
    }

    function getUsersList(uint256 _pool) public view returns(address[] memory) {
        return usersList[_pool];
    }

    // user
    function getUser(uint256 _pool, address _user) public view returns(uint256 userStakingBalance, uint256 userStakedBalance, uint256 userPendingReward) {
        return (users[_pool][_user].stakingBalance, users[_pool][_user].stakedBalance, users[_pool][_user].pendingReward);
    }

    // unstake requests
    function getUnstakeRequestsLength(uint256 _pool) public view returns(uint256) {
        return unstakeRequests[_pool].length;
    }

    function getUnstakeRequest(uint256 _pool, uint256 _request) public view returns(address user, uint256 amount, bool processed) {
        return (unstakeRequests[_pool][_request].user, unstakeRequests[_pool][_request].amount, unstakeRequests[_pool][_request].processed);
    }
}


// Dependency file: contracts/controller/Storage.sol


// pragma solidity 0.6.12;


contract Storage {
    // percent value must be multiple by 1e6
    uint256[] marketingLevels;

    // array of addresses which have already registered account
    address[] accountList;

    // bind left with right
    // THE RULE: the child referred by the parent
    mapping(address => address) referrals;

    // whitelist root tree of marketing level
    mapping(address => bool) whitelistRoots;

    function getTotalAccount() public view returns(uint256) {
        return accountList.length;
    }

    function getAccountList() public view returns(address[] memory) {
        return accountList;
    }

    function getReferenceBy(address _child) public view returns(address) {
        return referrals[_child];
    }

    function getMarketingMaxLevel() public view returns(uint256) {
        return marketingLevels.length;
    }

    function getMarketingLevelValue(uint256 _level) public view returns(uint256) {
        return marketingLevels[_level];
    }

    // get reference parent address matching the level tree
    function getReferenceParent(address _child, uint256 _level) public view returns(address) {
        uint i;
        address pointer = _child;

        while(i < marketingLevels.length) {
            pointer = referrals[pointer];

            if (i == _level) {
                return pointer;
            }

            i++;
        }

        return address(0);
    }

    function getWhiteListRoot(address _root) public view returns(bool) {
        return whitelistRoots[_root];
    }
}


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/GSN/Context.sol";
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


// Dependency file: contracts/controller/Controller.sol


// pragma solidity 0.6.12;

// import "contracts/controller/Storage.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";


contract Controller is Storage, Ownable {
    event LinkCreated(address indexed addr, address indexed refer);

    constructor() public {
        // init marketing level values
        // level from 1 -> 8
        marketingLevels.push(25e6); // 25%
        marketingLevels.push(20e6);
        marketingLevels.push(15e6);
        marketingLevels.push(10e6);
        marketingLevels.push(10e6);
        marketingLevels.push(10e6);
        marketingLevels.push(5e6);
        marketingLevels.push(5e6);
    }

    // user register referral address
    function register(address _refer) public {
        require(msg.sender != _refer, "ERROR: address cannot refer itself");
        require(referrals[msg.sender] == address(0), "ERROR: already set refer address");

        // owner address is the root of references tree
        if (_refer != owner() && !getWhiteListRoot(_refer)) {
            require(referrals[_refer] != address(0), "ERROR: invalid refer address");
        }

        // update reference tree
        referrals[msg.sender] = _refer;

        emit LinkCreated(msg.sender, _refer);
    }

    // admin update marketing level value
    function updateMarketingLevelValue(uint256 _level, uint256 _value) public onlyOwner {
        // value must be expo with 1e6
        // 25% -> 25e6
        marketingLevels[_level] = _value;
    }

    // add white list root tree
    function addWhiteListRoot(address _root) public onlyOwner {
        whitelistRoots[_root] = true;
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/ERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/GSN/Context.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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
     * Requirements:
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
     * Requirements:
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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


// Dependency file: contracts/libraries/ERC20Helper.sol


// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library ERC20Helper {
    function getDecimals(address addr) internal view returns(uint256) {
        ERC20 token = ERC20(addr);
        return token.decimals();
    }

    function getBalance(address addr, address user) internal view returns(uint256) {
        if (addr == address(0)) {
            return address(addr).balance;
        }

        ERC20 token = ERC20(addr);
        return token.balanceOf(user);
    }
}

// Dependency file: contracts/seedpool/Getters.sol


// pragma solidity 0.6.12;


// import "contracts/seedpool/State.sol";
// import "contracts/controller/Controller.sol";
// import "contracts/libraries/ERC20Helper.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";

contract Getters is State {
    using SafeMath for uint256;

    // get reward token address
    function getToken() public view returns(address) {
        return token;
    }

    // get admin address
    function getAdmin() public view returns(address) {
        return admin;
    }

    // get controller address
    function getController() public view returns(address) {
        return controller;
    }

    /*
    *   pool
    */

    // get total value locked in pool: included staking + staked balance
    function getPoolBalance(uint256 _pool) public view returns(uint256) {
        return pools[_pool].stakingBalance + pools[_pool].stakedBalance;
    }

    // get total pool staking balance
    function getPoolStakingBalance(uint256 _pool) public view returns(uint256) {
        return pools[_pool].stakingBalance;
    }

    // get total pool staked balance
    function getPoolStakedBalance(uint256 _pool) public view returns(uint256) {
        return pools[_pool].stakedBalance;
    }

    function getPoolPendingReward(uint256 _pool) public view returns(uint256) {
        uint256 amount;
        for (uint256 i=0; i<usersList[_pool].length; i++) {
            address user = usersList[_pool][i];
            amount = amount.add(users[_pool][user].pendingReward);
        }
        return amount;
    }

    function getPoolPendingUnstake(uint256 _pool) public view returns(uint256) {
        uint256 amount;
        for (uint256 i=0; i<unstakeRequests[_pool].length; i++) {
            if (!unstakeRequests[_pool][i].processed) {
                amount = amount.add(unstakeRequests[_pool][i].amount);
            }
        }
        return amount;
    }


    /*
    *   user
    */

    // get total balance of user
    function getUserBalance(uint256 _pool, address _user) public view returns(uint256) {
        return users[_pool][_user].stakingBalance + users[_pool][_user].stakedBalance;
    }

    // get user staking balance
    function getUserStakingBalance(uint256 _pool, address _user) public view returns(uint256) {
        return users[_pool][_user].stakingBalance;
    }

    // get user staked balance
    function getUserStakedBalance(uint256 _pool, address _user) public view returns(uint256) {
        return users[_pool][_user].stakedBalance;
    }

    // get pending reward of user
    function getUserPendingReward(uint256 _pool, address _user) public view returns(uint256) {
        return users[_pool][_user].pendingReward;
    }

    // get total user unstake requested amount
    function getUserPendingUnstake(uint256 _pool, address _user) public view returns(uint256) {
        uint256 amount;
        for (uint256 i=0; i<unstakeRequests[_pool].length; i++) {
            if (unstakeRequests[_pool][i].user == _user && !unstakeRequests[_pool][i].processed) {
                amount = amount.add(unstakeRequests[_pool][i].amount);
            }
        }
        return amount;
    }

    // estimate amount of reward token for harvest
    function estimatePayout(uint256 _pool, uint256 _percent, uint256 _rate) public view returns(uint256) {
        uint256 estimateAmount;
        uint256 decimals = 18;
        if (_pool != 0) {
            decimals = ERC20Helper.getDecimals(pools[_pool].token);
        }

        for (uint256 i=0; i<usersList[_pool].length; i++) {
            address user = usersList[_pool][i];

            // calculate profit
            uint256 profitAmount = getUserStakedBalance(_pool, user)
                .mul(_percent)
                .mul(_rate)
                .div(100);
            profitAmount = profitAmount.mul(10**(18 - decimals)).div(1e12);

            estimateAmount = estimateAmount.add(profitAmount);

            // estimate payout amount for references
            Controller iController = Controller(controller);
            uint256 maxLevel = iController.getMarketingMaxLevel();
            uint256 level;
            while(level < maxLevel) {
                address parent = iController.getReferenceParent(user, level);
                if (parent == address(0)) break;

                if (getUserStakedBalance(_pool, parent) > 0) {
                    uint256 percent = iController.getMarketingLevelValue(level);
                    uint256 referProfitAmount = profitAmount.mul(percent).div(100).div(1e6);
                    estimateAmount = estimateAmount.add(referProfitAmount);
                }

                level++;
            }
        }

        return estimateAmount;
    }
}


// Dependency file: contracts/seedpool/Setters.sol


// pragma solidity 0.6.12;


// import "contracts/seedpool/Getters.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";

contract Setters is Getters {
    using SafeMath for uint256;

    function setAdmin(address payable _admin) internal {
        admin = _admin;
    }

    function setController(address _controller) internal {
        controller = _controller;
    }

    function setToken(address _token) internal {
        token = _token;
    }

    /*
    *   user
    */
    function increaseUserStakingBalance(uint256 _pool, address _user, uint256 _amount) internal {
        users[_pool][_user].stakingBalance = users[_pool][_user].stakingBalance.add(_amount);

        // increase pool staking balance
        increasePoolStakingBalance(_pool, _amount);
    }

    function decreaseUserStakingBalance(uint256 _pool, address _user, uint256 _amount) internal {
        users[_pool][_user].stakingBalance = users[_pool][_user].stakingBalance.sub(_amount);

        // decrease pool staking balance
        decreasePoolStakingBalance(_pool, _amount);
    }

    function increaseUserStakedBalance(uint256 _pool, address _user, uint256 _amount) internal {
        users[_pool][_user].stakedBalance = users[_pool][_user].stakedBalance.add(_amount);

        increasePoolStakedBalance(_pool, _amount);
    }

    function decreaseUserStakedBalance(uint256 _pool, address _user, uint256 _amount) internal {
        users[_pool][_user].stakedBalance = users[_pool][_user].stakedBalance.sub(_amount);

        decreasePoolStakedBalance(_pool, _amount);
    }

    function increaseUserPendingReward(uint256 _pool, address _user, uint256 _amount) internal {
        users[_pool][_user].pendingReward = users[_pool][_user].pendingReward.add(_amount);
    }

    function decreaseUserPendingReward(uint256 _pool, address _user, uint256 _amount) internal {
        users[_pool][_user].pendingReward = users[_pool][_user].pendingReward.sub(_amount);
    }

    function emptyUserPendingReward(uint256 _pool, address _user) internal {
        users[_pool][_user].pendingReward = 0;
    }

    /*
    *   pool
    */
    function appendNewPool(address _token) internal {
            pools.push(Pool({
            token: _token,
            stakingBalance: 0,
            stakedBalance: 0
        }));
    }

    function increasePoolStakingBalance(uint256 _pool, uint256 _amount) internal {
        pools[_pool].stakingBalance = pools[_pool].stakingBalance.add(_amount);
    }

    function decreasePoolStakedBalance(uint256 _pool, uint256 _amount) internal {
        pools[_pool].stakedBalance = pools[_pool].stakedBalance.sub(_amount);
    }

    function increasePoolStakedBalance(uint256 _pool, uint256 _amount) internal {
        pools[_pool].stakedBalance = pools[_pool].stakedBalance.add(_amount);
    }

    function decreasePoolStakingBalance(uint256 _pool, uint256 _amount) internal {
        pools[_pool].stakingBalance = pools[_pool].stakingBalance.sub(_amount);
    }

    /*
    *   unstake requests
    */
    function setProcessedUnstakeRequest(uint256 _pool, uint256 _req) internal {
        unstakeRequests[_pool][_req].processed = true;
    }
}


// Dependency file: contracts/Constants.sol


// pragma solidity 0.6.12;


library Constants {
    address constant BVA = address(0x10d88D7495cA381df1391229Bdb82D015b9Ad17D);
    address constant USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
}


// Dependency file: contracts/libraries/TransferHelper.sol


// pragma solidity ^0.6.0;

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

// Root file: contracts/seedpool/SeedPool.sol


pragma solidity 0.6.12;


// import "contracts/seedpool/Setters.sol";
// import "contracts/Constants.sol";
// import "contracts/controller/Controller.sol";
// import "contracts/libraries/TransferHelper.sol";
// import "contracts/libraries/ERC20Helper.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SeedPool is Setters, Ownable {
    using SafeMath for uint256;

    event Stake(address indexed user, uint256 indexed pool, uint256 indexed amount);
    event Unstake(address indexed user, uint256 indexed pool, uint256 indexed amount);
    event Harvest(address indexed user, uint256 indexed pool, uint256 indexed amount);
    event Payout(address admin, uint256 indexed pool, uint256 indexed percent, uint256 indexed rate);

    // emit when admin process the pool unstake request
    event UnstakeProcessed(address admin, uint256 indexed pool, uint256 indexed amount);

    constructor(address payable _admin, address _controller) public {
        setAdmin(_admin);
        setToken(Constants.BVA);
        setController(_controller);

        // setup default pools
        appendNewPool(address(0));
        appendNewPool(Constants.USDT);
    }

    // fallback function will help contract receive eth sent only by admin
    receive() external payable {
        require(msg.sender == admin, "ERROR: send ETH to contract is not allowed");
    }

    // check msg.sender is admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "ERROR: only admin");
        _;
    }

    // update profit for reference parents
    function payoutReference(uint256 _pool, address _child, uint256 _amount) internal returns(uint256) {
        uint256 totalPayout;
        Controller iController = Controller(controller);
        uint256 maxLevel = iController.getMarketingMaxLevel();
        uint256 level;
        while(level < maxLevel) {
            address parent = iController.getReferenceParent(_child, level);
            if (parent == address(0)) break;

            if (getUserStakedBalance(_pool, parent) > 0) {
                uint256 percent = iController.getMarketingLevelValue(level);
                uint256 referProfitAmount = _amount.mul(percent).div(100).div(1e6);

                increaseUserPendingReward(_pool, parent, referProfitAmount);
                totalPayout = totalPayout.add(referProfitAmount);
            }

            level++;
        }

        return totalPayout;
    }

    // deposit amount of ETH or tokens to contract
    // user MUST call approve function in Token contract to approve _value for this contract
    //
    // after deposit, _value added to staking balance
    // after one payout action, staking balance will be moved to staked balance
    function stake(uint256 _pool, uint256 _value) public payable {
        if (_pool == 0) {
            increaseUserStakingBalance(_pool, msg.sender, msg.value);

            TransferHelper.safeTransferETH(admin, msg.value);

            emit Stake(msg.sender, _pool, msg.value);
        } else {
            TransferHelper.safeTransferFrom(pools[_pool].token, msg.sender, address(this), _value);
            TransferHelper.safeTransfer(pools[_pool].token, admin, _value);

            increaseUserStakingBalance(_pool, msg.sender, _value);

            emit Stake(msg.sender, _pool, _value);
        }

        bool isListed;
        for (uint256 i=0; i<usersList[_pool].length; i++) {
            if (usersList[_pool][i] == msg.sender) isListed = true;
        }

        if (!isListed) {
            usersList[_pool].push(msg.sender);
        }
    }

    // request unstake amount of ETH or tokens
    // user can only request unstake in staked balance
    function unstake(uint256 _pool, uint256 _value) public {
        uint256 stakedBalance = getUserStakedBalance(_pool, msg.sender);
        uint256 requestedAmount = getUserPendingUnstake(_pool, msg.sender);
        require(_value + requestedAmount <= stakedBalance, "ERROR: insufficient balance");

        unstakeRequests[_pool].push(UnstakeRequest({
            user: msg.sender,
            amount: _value,
            processed: false
        }));

        emit Unstake(msg.sender, _pool, _value);
    }

    // harvest pending reward token
    // simple transfer pendingReward to uer wallet
    function harvest(uint256 _pool) public {
        uint256 receiveAmount = getUserPendingReward(_pool, msg.sender);
        if (receiveAmount > 0) {
            TransferHelper.safeTransfer(token, msg.sender, receiveAmount);
            emptyUserPendingReward(_pool, msg.sender);
        }

        emit Harvest(msg.sender, _pool, receiveAmount);
    }

    // payout function
    // called only by admin
    // param @_percent: present amount of reward based on stakedBalance of user
    // param @_rate: how many reward token for each deposit token
    //  ex: ? BVA = 1 ETH
    // _percent & _rate must be multiple by 1e6
    //
    // 1. process user staked balance
    // 2. move user staking balance to staked balance
    function payout(uint256 _pool, uint256 _percent, uint256 _rate) public onlyAdmin {
        uint256 totalPayoutReward;
        uint256 decimals = 18;
        if (_pool != 0) {
            decimals = ERC20Helper.getDecimals(pools[_pool].token);
        }

        for (uint256 i=0; i<usersList[_pool].length; i++) {
            address user = usersList[_pool][i];

            // calculate profit
            uint256 profitAmount = getUserStakedBalance(_pool, user)
                .mul(_percent)
                .mul(_rate)
                .div(100);
            profitAmount = profitAmount.mul(10**(18 - decimals)).div(1e12);
            totalPayoutReward = totalPayoutReward.add(profitAmount);

            // add profit to pending reward
            increaseUserPendingReward(_pool, user, profitAmount);

            // move user staking balance to staked balance
            increaseUserStakedBalance(_pool, user, getUserStakingBalance(_pool, user));
            decreaseUserStakingBalance(_pool, user, getUserStakingBalance(_pool, user));

            // calculate profit for reference users
            // double check vs controller
            uint256 totalReferencePayout = payoutReference(_pool, user, profitAmount);
            totalPayoutReward = totalPayoutReward.add(totalReferencePayout);
        }

        TransferHelper.safeTransferFrom(token, msg.sender, address(this), totalPayoutReward);

        emit Payout(msg.sender, _pool, _percent, _rate);
    }

    // process unstake requests
    // admin call this function and send ETH or tokens to process
    // this function check requests all auto process each request
    function processUnstake(uint256 _pool, uint256 _amount) public payable onlyAdmin {
        if (_pool == 0) {
            uint256 tokenBalance = address(this).balance;

            // process until tokenBalance = 0
            for (uint256 i=0; i<unstakeRequests[_pool].length; i++) {
                if (unstakeRequests[_pool][i].amount <= tokenBalance && !unstakeRequests[_pool][i].processed) {
                    address user = unstakeRequests[_pool][i].user;
                    TransferHelper.safeTransferETH(user, unstakeRequests[_pool][i].amount);
                    tokenBalance = tokenBalance.sub(unstakeRequests[_pool][i].amount);
                    decreaseUserStakedBalance(_pool, user, unstakeRequests[_pool][i].amount);
                    setProcessedUnstakeRequest(_pool, i);
                }
            }

            emit UnstakeProcessed(msg.sender, _pool, msg.value);
        } else {
            TransferHelper.safeTransferFrom(pools[_pool].token, getAdmin(), address(this), _amount);
            uint256 tokenBalance = ERC20Helper.getBalance(pools[_pool].token, address(this));

            for (uint256 i=0; i<unstakeRequests[_pool].length; i++) {
                if (unstakeRequests[_pool][i].amount <= tokenBalance && !unstakeRequests[_pool][i].processed) {
                    address user = unstakeRequests[_pool][i].user;
                    // transfer token from contract -> user
                    TransferHelper.safeTransfer(pools[_pool].token, user, unstakeRequests[_pool][i].amount);
                    tokenBalance = tokenBalance.sub(unstakeRequests[_pool][i].amount);

                    decreaseUserStakedBalance(_pool, user, unstakeRequests[_pool][i].amount);
                    setProcessedUnstakeRequest(_pool, i);
                }
            }

            emit UnstakeProcessed(msg.sender, _pool, _amount);
        }
    }

    // function emergency get all coin from contract to admin
    function emergencyGetToken(uint256 _pool) public onlyAdmin {
        if (_pool == 0) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        } else {
            IERC20 token = IERC20(pools[_pool].token);
            TransferHelper.safeTransfer(pools[_pool].token, msg.sender, token.balanceOf(address(this)));
        }
    }

    // transfer admin
    function changeAdmin(address payable _admin) public onlyOwner {
        setAdmin(_admin);
    }

    // transfer token
    function changeToken(address _token) public onlyOwner {
        setToken(_token);
    }

    // transfer controller
    function changeController(address _controller) public onlyOwner {
        setController(_controller);
    }
}