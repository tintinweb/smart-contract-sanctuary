/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract MASToken is ERC20, Ownable {
    using SafeMath for uint256;

    struct VestingPlan {
        uint256 vType;
        uint256 totalBalance;
        uint256 totalClaimed;
        uint256 start;
        uint256 end;
        uint256 cliff;
        uint256 releasePercentWhenStart;
        uint256 releasePercentEachMonth;
        uint256 claimedCheckPoint;
    }

    mapping (address => VestingPlan) public vestingList;

    uint256 private _totalSupply            = 1000000000 * 10**18;
        
    uint256 private MONTH                   = 5 * 60;
    uint256 private PERCENT_ACCURACY        = 1000000;

    uint256 public totalTokenForSeed        = _totalSupply.mul(6667).div(PERCENT_ACCURACY);
    uint256 public totalTokenForPrivate     = _totalSupply.mul(75000).div(PERCENT_ACCURACY);
    uint256 public totalTokenForPublic      = _totalSupply.mul(50000).div(PERCENT_ACCURACY);
    uint256 public totalTokenForAdvisor     = _totalSupply.mul(50000).div(PERCENT_ACCURACY);
    uint256 public totalTokenForTeam        = _totalSupply.mul(200000).div(PERCENT_ACCURACY);
    uint256 public totalTokenForDexCex      = _totalSupply.mul(200000).div(PERCENT_ACCURACY);
    uint256 public totalTokenForEcosystem   = _totalSupply.mul(78333).div(PERCENT_ACCURACY);
    uint256 public totalTokenForReserve     = _totalSupply.mul(90000).div(PERCENT_ACCURACY);
    uint256 public totalTokenForCommunity   = _totalSupply.mul(250000).div(PERCENT_ACCURACY);


    uint256 public totalDistributedTokenForSeed        = 0;
    uint256 public totalDistributedTokenForPrivate     = 0;
    uint256 public totalDistributedTokenForPublic      = 0;
    uint256 public totalDistributedTokenForAdvisor     = 0;
    uint256 public totalDistributedTokenForTeam        = 0;
    uint256 public totalDistributedTokenForDexCex      = 0;
    uint256 public totalDistributedTokenForEcosystem   = 0;
    uint256 public totalDistributedTokenForReserve     = 0;
    uint256 public totalDistributedTokenForCommunity   = 0;

    uint8 public VEST_TYPE_SEED     = 1;
    uint8 public VEST_TYPE_PRIVATE  = 2;
    uint8 public VEST_TYPE_PUBLIC  = 3;
    uint8 public VEST_TYPE_ADVISOR  = 4;
    uint8 public VEST_TYPE_TEAM = 5;
    uint8 public VEST_TYPE_DEXCEX = 6;
    uint8 public VEST_TYPE_ECO = 7;
    uint8 public VEST_TYPE_RESERVE = 8;
    uint8 public VEST_TYPE_COMMUNITY = 9;


    constructor () ERC20("MAS Token", "MAS") {
        _mint(owner(), totalTokenForPublic.add(totalTokenForReserve)); //Public & Reserve

        uint256 totalVestToken = totalTokenForSeed + totalTokenForPrivate + totalTokenForAdvisor + totalTokenForTeam + totalTokenForDexCex + totalTokenForEcosystem + totalTokenForCommunity;
        _mint(address(this), totalVestToken); // Total vesting token

        addingVestToken(owner(), totalTokenForDexCex, VEST_TYPE_DEXCEX);
        addingVestToken(0x367015167931bD8e3e28F2c3444DFDD1b801eE39, 70000000 * 10**18, VEST_TYPE_TEAM);
        addingVestToken(0x6d65cFe5bD36bF4146b3d149FE37463308c0BC76, 130000000 * 10**18, VEST_TYPE_TEAM);
        
    }

    function addingVestToken(address account, uint256 amount, uint8 vType) public onlyOwner {
        VestingPlan storage vestPlan = vestingList[account];
        if(vType == VEST_TYPE_SEED){
            require(totalDistributedTokenForSeed.add(amount) <= totalTokenForSeed, "Exceed token for SEED");
            totalDistributedTokenForSeed = totalDistributedTokenForSeed.add(amount);
            vestPlan.cliff = 3;
            vestPlan.releasePercentWhenStart = 220000;
            vestPlan.releasePercentEachMonth = 32500;
        }else if(vType == VEST_TYPE_PRIVATE){
            require(totalDistributedTokenForPrivate.add(amount) <= totalTokenForPrivate, "Exceed token for PRIVATE");
            totalDistributedTokenForPrivate = totalDistributedTokenForPrivate.add(amount);
            vestPlan.cliff = 3;
            vestPlan.releasePercentWhenStart = 220000;
            vestPlan.releasePercentEachMonth = 32500;
        }else if(vType == VEST_TYPE_ADVISOR){
            require(totalDistributedTokenForAdvisor.add(amount) <= totalTokenForAdvisor, "Exceed token for ADVISOR");
            totalDistributedTokenForAdvisor = totalDistributedTokenForAdvisor.add(amount);
            vestPlan.cliff = 4;
            vestPlan.releasePercentWhenStart = 205000;
            vestPlan.releasePercentEachMonth = 66250;
        }else if(vType == VEST_TYPE_TEAM){
            require(totalDistributedTokenForTeam.add(amount) <= totalTokenForTeam, "Exceed token for TEAM");
            totalDistributedTokenForTeam = totalDistributedTokenForTeam.add(amount);
            vestPlan.cliff = 4;
            vestPlan.releasePercentWhenStart = 205000;
            vestPlan.releasePercentEachMonth = 66250;
        }else if(vType == VEST_TYPE_DEXCEX){
            require(totalDistributedTokenForDexCex.add(amount) <= totalTokenForDexCex, "Exceed token for DEXCEX");
            totalDistributedTokenForDexCex = totalDistributedTokenForDexCex.add(amount);
            vestPlan.cliff = 0;
            vestPlan.releasePercentWhenStart = 300000;
            vestPlan.releasePercentEachMonth = 19444;
        }else if(vType == VEST_TYPE_ECO){
            require(totalDistributedTokenForEcosystem.add(amount) <= totalTokenForEcosystem, "Exceed token for ECOSYSTEM");
            totalDistributedTokenForEcosystem = totalDistributedTokenForEcosystem.add(amount);
            vestPlan.cliff = 0;
            vestPlan.releasePercentWhenStart = 50000;
            vestPlan.releasePercentEachMonth = 26333;
        }else if(vType == VEST_TYPE_COMMUNITY){
            require(totalDistributedTokenForCommunity.add(amount) <= totalTokenForCommunity, "Exceed token for COMMUNITY");
            totalDistributedTokenForCommunity = totalDistributedTokenForCommunity.add(amount);
            vestPlan.cliff = 0;
            vestPlan.releasePercentWhenStart = 50000;
            vestPlan.releasePercentEachMonth = 26333;
        }else {
            require(false, "Wrong vesting type!");
        }
 
        vestPlan.vType = vType;
        vestPlan.totalBalance = amount;
        vestPlan.claimedCheckPoint = 0;

        if(vType == VEST_TYPE_DEXCEX || vType == VEST_TYPE_ECO ||  vType == VEST_TYPE_COMMUNITY){
            vestPlan.start = block.timestamp;
            vestPlan.end = block.timestamp + vestPlan.cliff * MONTH + ((PERCENT_ACCURACY - vestPlan.releasePercentWhenStart)/vestPlan.releasePercentEachMonth) * MONTH;
            vestPlan.totalClaimed = (vestPlan.totalBalance * vestPlan.releasePercentWhenStart)/PERCENT_ACCURACY;
            if(vestPlan.totalClaimed > 0){
                _transfer(address(this), account, vestPlan.totalClaimed);
            }
        }
    }

    uint256 public launchTime;
    function launch() public onlyOwner {
        launchTime = block.timestamp;
    }

    function getClaimableToken(address account) public view returns (uint256){
        VestingPlan memory vestPlan = vestingList[account];

        if(vestPlan.totalClaimed == vestPlan.totalBalance){
            return 0;
        }

        uint256 claimableAmount = 0;
        uint256 vestStart = vestPlan.start; 
        uint256 vestEnd = vestPlan.end; 

        if(block.timestamp > launchTime && launchTime > 0){
            if(vestStart == 0){
                vestStart = launchTime;
                vestEnd = vestStart + vestPlan.cliff * MONTH + ((PERCENT_ACCURACY - vestPlan.releasePercentWhenStart)/vestPlan.releasePercentEachMonth) * MONTH;
                if(vestPlan.vType == VEST_TYPE_SEED || vestPlan.vType == VEST_TYPE_PRIVATE){
                    claimableAmount = (vestPlan.totalBalance * vestPlan.releasePercentWhenStart)/PERCENT_ACCURACY;
                }

                if(vestPlan.vType == VEST_TYPE_TEAM || vestPlan.vType == VEST_TYPE_ADVISOR){
                    if(block.timestamp >= launchTime + 3*MONTH)
                        claimableAmount = (vestPlan.totalBalance * vestPlan.releasePercentWhenStart)/PERCENT_ACCURACY;
                }
            }
        }

        if(block.timestamp <= vestStart + vestPlan.cliff * MONTH ){
            return claimableAmount;
        }else { 
            uint256 currentTime = block.timestamp;
            if(currentTime > vestEnd){
                currentTime = vestEnd;
            }

            uint256 currentCheckPoint = (currentTime - vestStart - vestPlan.cliff * MONTH) / MONTH;
            if(currentCheckPoint > vestPlan.claimedCheckPoint){
                uint256 claimable =  ((currentCheckPoint - vestPlan.claimedCheckPoint)* vestPlan.releasePercentEachMonth * vestPlan.totalBalance) / PERCENT_ACCURACY;
                return claimable.add(claimableAmount);
            }else {
                return claimableAmount;
            }
        }
    }

    function balanceRemainingInVesting(address account) public view returns(uint256){
        VestingPlan memory vestPlan = vestingList[account];
        return vestPlan.totalBalance -  vestPlan.totalClaimed;
    }

    function withDrawFromVesting() public{
        VestingPlan storage vestPlan = vestingList[msg.sender];

        uint256 claimableAmount = getClaimableToken(msg.sender);
        require(claimableAmount > 0, "There isn't token in vesting that claimable at the moment");
        require(vestPlan.totalClaimed.add(claimableAmount) <= vestPlan.totalBalance, "Can't claim amount that exceed totalBalance");


        if(vestPlan.start == 0){ // For team/advisor/seed/private, release token after TGE
            vestPlan.start = launchTime;
            vestPlan.end = launchTime + vestPlan.cliff * MONTH + ((PERCENT_ACCURACY - vestPlan.releasePercentWhenStart)/vestPlan.releasePercentEachMonth) * MONTH;
        }

        uint256 currentTime = block.timestamp;
        if(currentTime > vestPlan.end){
            currentTime = vestPlan.end;
        }
        
        if(currentTime - vestPlan.start - vestPlan.cliff * MONTH >= 0) // Only update checkpoint after cliff time
            vestPlan.claimedCheckPoint = (currentTime - vestPlan.start - vestPlan.cliff * MONTH) / MONTH;

        vestPlan.totalClaimed = vestPlan.totalClaimed.add(claimableAmount);

        _transfer(address(this), msg.sender, claimableAmount);
    }
}