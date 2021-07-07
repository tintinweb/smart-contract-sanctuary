// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AccessManager is Ownable {
    // Access type
    mapping(address => bool) private accessMap;

    /**
     * @dev Only allow access from specified contracts
     */
    modifier onlyAllowedAddress() {
        require(accessMap[_msgSender()], "Access: sender not allowed");
        _;
    }

    /**
     * @dev Gets if the specified address has access
     * @param _address Address to enable access
     */
    function getAccess(address _address) public view returns (bool) {
        return accessMap[_address];
    }

    /**
     * @dev Enables access to the specified address
     * @param _address Address to enable access
     */
    function enableAccess(address _address) external onlyOwner {
        require(_address != address(0), "Address is empty");
        require(!accessMap[_address], "User already has access");

        accessMap[_address] = true;
    }

    /**
     * @dev Disables access to the specified address
     * @param _address Address to disable access
     */
    function disableAccess(address _address) external onlyOwner {
        require(_address != address(0), "Address is empty");
        require(accessMap[_address], "User already has no access");
        
        accessMap[_address] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AccessManager.sol";

contract LiqiBRLToken is ERC20, Ownable, AccessManager {
    using SafeMath for uint256;

    /**
     * @dev Liqi Offer Token
     */
    constructor() public ERC20("Liqi BRL", "BRLT") {
        _setupDecimals(20);
    }

    /**
     * @dev Allow minting by the owner
     */
    function mint(address _account, uint256 _amount) public onlyOwner {
        require(_account != address(0), "Account is empty");
        require(_amount != 0, "Amount is zero");

        _mint(_account, _amount);
    }

    /**
     * @dev Allow burning by the owner
     */
    function burn(uint256 _amount) public onlyOwner {
        require(_amount != 0, "Amount is zero");

        _burn(owner(), _amount);
    }

    /**
     * @dev Exchanges the funds of one address to another
     */
    function exchangeBalance(address _from, address _to) public onlyOwner {
        require(_from != address(0), "From is empty");
        require(_to != address(0), "To is empty");

        // get current balance of _from address
        uint256 nAmount = balanceOf(_from);

        // dont proceed if theres nothing to exchange
        require(nAmount != 0, "Amount is zero");

        // transfer balance to new address
        _transfer(_from, _to, nAmount);
    }

    /**
     * @dev invest mints the funds on the _investor address
     */
    function invest(address _investor, uint256 _amount)
        public
        onlyAllowedAddress
    {
        // no empty address
        require(_investor != address(0), "Investor is empty");

        // no zero amount
        require(_amount != 0, "Amount is zero");

        // mint the BRLT tokens to the investor account
        _mint(_investor, _amount);

        // transfer balance to new address
        _transfer(_investor, _msgSender(), _amount);
    }

    /**
     * @dev failedSale is only called from failed sales
     */
    function failedSale() public onlyAllowedAddress {
        // get the address of the caller
        address aSender = _msgSender();

        // get the balance of the offer
        uint256 nBalance = balanceOf(aSender);

        // burn everything
        _burn(aSender, nBalance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../base/IOffer.sol";
import "../../LiqiBRLToken.sol";
import "../../base/BaseOfferToken.sol";

contract CRZ0Offer is Ownable, IOffer {
    // R$15,00
    uint256 public constant RATE_PHASE_1 = 1750;
    // R$16,00
    uint256 public constant RATE_PHASE_2 = 1875;
    // R$17,50
    uint256 public constant RATE_PHASE_3 = 2000;
    // R$18,75
    uint256 public constant RATE_PHASE_4 = 2125;
    // Minimum of 72000 to sell
    uint256 public constant MIN_TOTAL_TOKEN_SOLD = 79200 * 1 ether;
    // Total amount of tokens to be sold
    uint256 public constant TOTAL_TOKENS = 316800 * 1 ether;
    // Total amount to sell to end rate 1
    uint256 public constant RATE_AMOUNT_PHASE_1 = 79200 * 1 ether;
    // Total amount to sell to end rate 2
    uint256 public constant RATE_AMOUNT_PHASE_2 = 158400 * 1 ether;
    // Total amount to sell to end rate 3
    uint256 public constant RATE_AMOUNT_PHASE_3 = 237600 * 1 ether;

    // If the offer has been initialized by the owner
    bool private bInitialized;
    // If the success condition has been met
    bool private bSuccess;
    // If the offer has finished the sale of tokens
    bool private bFinished;

    // A counter of the total amount of tokens sold
    uint256 internal nTotalSold;

    // The date the offer finishSale function was called
    uint256 internal nFinishDate;

    // A reference to the BRLToken contract
    LiqiBRLToken private brlToken;
    // A reference to the emitter of the offer
    address private aEmitter;
    // Use safe math for add and sub
    using SafeMath for uint256;
    // Create a structure to save our payments
    struct Payment {
        // The total amount the user bought in tokens
        uint256 totalAmount;
        // The total amount the user has received in tokens
        uint256 totalPaid;
    }
    // A reference to the token were selling
    BaseOfferToken private baseToken;
    // A map of address to payment
    mapping(address => Payment) private mapPayments;

    constructor(
        address _emitter,
        address _brlTokenContract,
        address _tokenAddress
    ) public {
        aEmitter = _emitter;
        brlToken = LiqiBRLToken(_brlTokenContract);
        baseToken = BaseOfferToken(_tokenAddress);
    }

    /*
     * @dev Initializes the sale
     */
    function initialize() public override {
        require(_msgSender() == address(baseToken), "Only call from token");

        require(!bInitialized, "Sale is initialized");

        bInitialized = true;
    }

    function cashoutBRLT() public {
        // no unsuccessful sale
        require(bSuccess, "Sale is not successful");
        // check the balance of tokens of this contract
        uint256 nBalance = brlToken.balanceOf(address(this));
        // nothing to execute if the balance is 0
        require(nBalance != 0, "Balance to cashout is 0");
        // transfer all tokens to the emitter account
        brlToken.transfer(aEmitter, nBalance);
    }

    function getTokenAddress() public view returns (address) {
        return address(brlToken);
    }

    function getToken() public view returns (address token) {
        return address(baseToken);
    }

    /*
     * @dev Declare an investment for an address
     */
    function invest(address _investor, uint256 _amount) public onlyOwner {
        // make sure the investor is not an empty address
        require(_investor != address(0), "Investor is empty");
        // make sure the amount is not zero
        require(_amount != 0, "Amount is zero");
        // do not sell if sale is finished
        require(!bFinished, "Sale is finished");
        // do not sell if not initialized
        require(bInitialized, "Sale is not initialized");

        // process input data
        // call with same args
        brlToken.invest(_investor, _amount);
        // convert input currency to output
        // - get rate from module
        uint256 nRate = getRate();

        // - total amount from the rate obtained
        uint256 nOutputAmount = _amount.div(nRate);

        // pass to module to handling outputs
        // get the current contract's balance
        uint256 nBalance = baseToken.balanceOf(address(this));
        // calculate how many tokens we can sell
        uint256 nRemainingBalance = nBalance.sub(nTotalSold);
        // make sure we're not selling more than we have
        require(
            nOutputAmount <= nRemainingBalance,
            "Offer does not have enough tokens to sell"
        );
        // read the payment data from our map
        Payment memory payment = mapPayments[_investor];
        // increase the amount of tokens this investor has purchased
        payment.totalAmount = payment.totalAmount.add(nOutputAmount);
        mapPayments[_investor] = payment;

        // after everything, add the bought tokens to the total
        nTotalSold = nTotalSold.add(nOutputAmount);

        // and check if the sale is sucessful after this sale
        if (!bSuccess) {
            if (nTotalSold >= MIN_TOTAL_TOKEN_SOLD) {
                // we have sold more than minimum, success
                bSuccess = true;
            }
        }
    }

    /*
     * @dev Marks the offer as finished
     */
    function finishSale() public onlyOwner {
        require(!bFinished, "Sale is finished");
        bFinished = true;

        if (!getSuccess()) {
            // notify the BRLT
            brlToken.failedSale();
        }
        // get the current contract's balance
        uint256 nBalance = baseToken.balanceOf(address(this));
        if (getSuccess()) {
            // calculate how many tokens we have not sold
            uint256 nRemainingBalance = nBalance.sub(nTotalSold);
            // return remaining tokens to owner
            baseToken.transfer(aEmitter, nRemainingBalance);
        } else {
            // return all tokens to owner
            baseToken.transfer(aEmitter, nBalance);
        }
    }

    /*
     * @dev Cashouts tokens for a specified user
     */
    function cashoutTokens(address _investor)
        external
        virtual
        override
        returns (bool)
    {
        require(_msgSender() == address(baseToken), "Call only from token");
        // wait till the offer is successful to allow transfer
        if (!bSuccess) {
            return false;
        }
        // read the token sale data for that address
        Payment storage payment = mapPayments[_investor];
        // nothing to be paid
        if (payment.totalAmount == 0) {
            return false;
        }
        // calculate the remaining tokens
        uint256 nRemaining = payment.totalAmount.sub(payment.totalPaid);
        // make sure there's something to be paid
        if (nRemaining == 0) {
            return false;
        }
        // transfer to requested user
        baseToken.transfer(_investor, nRemaining);
        // mark that we paid the user in fully
        payment.totalPaid = payment.totalAmount;
        return true;
    }

    /*
     * @dev Returns the current rate for the token
     */
    function getRate() public view virtual returns (uint256 rate) {
        if (nTotalSold >= RATE_AMOUNT_PHASE_3) {
            return RATE_PHASE_4;
        } else if (nTotalSold >= RATE_AMOUNT_PHASE_2) {
            return RATE_PHASE_3;
        } else if (nTotalSold >= RATE_AMOUNT_PHASE_1) {
            return RATE_PHASE_2;
        } else {
            return RATE_PHASE_1;
        }
    }

    /*
     * @dev Gets how much the specified user has bought from this offer
     */
    function getTotalBought(address _investor)
        public
        view
        override
        returns (uint256 nTotalBought)
    {
        return mapPayments[_investor].totalAmount;
    }

    /*
     * @dev Get total amount the user has cashed out from this offer
     */
    function getTotalCashedOut(address _investor)
        public
        view
        override
        returns (uint256 nTotalCashedOut)
    {
        return mapPayments[_investor].totalPaid;
    }

    /*
     * @dev Returns true if the sale is initialized
     */
    function getInitialized() public view override returns (bool) {
        return bInitialized;
    }

    /*
     * @dev Returns true if the sale is finished
     */
    function getFinished() public view override returns (bool) {
        return bFinished;
    }

    /*
     * @dev Returns true if the sale is successful
     */
    function getSuccess() public view override returns (bool) {
        return bSuccess;
    }

    /*
     * @dev Gets the total amount of tokens sold
     */
    function getTotalSold() public view virtual returns (uint256 totalSold) {
        return nTotalSold;
    }

    /*
     * @dev Gets the date the offer finished at
     */
    function getFinishDate() external view override returns (uint256) {
        return nFinishDate;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IOffer {
    function getInitialized() external view returns (bool);
    
    function getFinished() external view returns (bool);

    function getSuccess() external view returns (bool);

    function initialize() external;

    function cashoutTokens(address _investor) external returns (bool);

    function getTotalBought(address _investor) external view returns(uint256);
    
    function getTotalCashedOut(address _investor) external view returns(uint256);

    function getFinishDate() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseOfferToken is ERC20Snapshot, Ownable {
    using SafeMath for uint256;

    // A fuse to disable the exchangeBalance function
    bool internal bDisabledExchangeBalance;

    /**
     * @dev Liqi Offer Token
     */
    constructor(string memory _name, string memory _symbol)
        public
        ERC20(_name, _symbol)
    {}

    /**
     * @dev Disables the exchangeBalance function
     */
    function disableExchangeBalance() public onlyOwner {
        require(!bDisabledExchangeBalance, "Exchange balance is already disabled");

        bDisabledExchangeBalance = true;
    }

    /**
     * @dev Exchanges the funds of one address to another
     */
    function exchangeBalance(address _from, address _to) public onlyOwner {
        // check if the function is disabled
        require(!bDisabledExchangeBalance, "Exchange balance has been disabled");
        // simple checks for empty addresses
        require(_from != address(0), "Transaction from 0x");
        require(_to != address(0), "Transaction to 0x");

        // get current balance of _from address
        uint256 amount = balanceOf(_from);

        // check if there's balance to transfer
        require(amount != 0, "Balance is 0");

        // transfer balance to new address
        _transfer(_from, _to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMath.sol";
import "../../utils/Arrays.sol";
import "../../utils/Counters.sol";
import "./ERC20.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../../base/BaseOfferToken.sol";
import "../../base/IOffer.sol";

contract TokenTransfer is BaseOfferToken {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // A map of the offer index to the start date
    mapping(uint256 => uint256) internal mapOfferStartDate;
    // A map of the offer index to the offer object
    mapping(uint256 => IOffer) internal mapOffers;
    // A map of the investor to the last cashout he did
    mapping(address => uint256) internal mapLastCashout;

    // An internal counter to keep track of the offers
    Counters.Counter internal counterTotalOffers;

    // address of the receiver
    address internal aReceiver;

    /**
     * @dev Make a Token Transfer
     */
    constructor(
        address _receiver,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public BaseOfferToken(_tokenName, _tokenSymbol) {
        // make sure the receiver is not empty
        require(_receiver != address(0));

        // make sure were not starting with 0 tokens
        require(_totalTokens != 0);

        // save address of the receiver
        aReceiver = _receiver;

        // mints all tokens to receiver
        _mint(_receiver, _totalTokens);
    }

    /*
    * @dev Get the date the offer of the _index started
    */
    function getOfferDate(uint256 _index) public view returns (uint256) {
        return mapOfferStartDate[_index];
    }

    /*
    * @dev Get the address of the _index offer
    */
    function getOfferAddress(uint256 _index) public view returns (address) {
        return address(mapOffers[_index]);
    }

    /*
    * @dev Get the index of the last cashout for the _account
    */
    function getLastCashout(address _account) public view returns (uint256) {
        return mapLastCashout[_account];
    }

    /*
    * @dev Get the total amount of offers registered
    */
    function getTotalOffers() public view returns (uint256) {
        return counterTotalOffers.current();
    }

    /*
    * @dev Registers a sale on the token
    */
    function startSale(address _aTokenSale) public onlyOwner returns (uint256) {
        // make sure the address isn't empty
        require(_aTokenSale != address(0), "Sale cant be empty");

        // convert the sale to a interface
        IOffer objSale = IOffer(_aTokenSale);

        // make sure the sale is intiialized
        require(!objSale.getInitialized(), "Sale should not be initialized");

        // increment the total of offers
        counterTotalOffers.increment();

        // gets the current offer index
        uint256 nCurrentId = counterTotalOffers.current();

        // save the address of the sale
        mapOffers[nCurrentId] = objSale;

        // save the date the offer should be considered for dividends
        mapOfferStartDate[nCurrentId] = block.timestamp;

        // initialize the sale
        objSale.initialize();

        return nCurrentId;
    }

    /*
    * @dev Try to cashout up to 15 times
    */
    function tryCashouts(address aSender) private {
        for (uint256 i = 0; i < 15; i++) {
            if (!cashoutFrozenAny(aSender)) {
                return;
            }
        }
    }

    /*
    * @dev Main cashout function, cashouts up to 16 times
    */
    function cashoutFrozen() public {
        // cache the sender
        address aSender = _msgSender();

        bool bHasCashout = cashoutFrozenAny(aSender);
        require(bHasCashout, "No cashouts available");

        // try to do 10 cashouts
        tryCashouts(aSender);
    }

    /**
     * @return true if it changed the state
     */
    function cashoutFrozenAny(address _account) public virtual returns (bool) {
        // get the latest token sale that was cashed out
        uint256 nCurrentSnapshotId = counterTotalOffers.current();

        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[_account];

        // return if its the latest offer
        if (nCurrentSnapshotId <= nLastCashout) {
            return false;
        }

        // add 1 to get the next payment index
        uint256 nNextCashoutIndex = nLastCashout.add(1);

        // get the address of the offer this user is cashing out
        IOffer offer = mapOffers[nNextCashoutIndex];

        // cashout the tokens, if the offer allows
        bool bOfferCashout = offer.cashoutTokens(_account);

        // check if the sale is finished
        if (offer.getFinished()) {
            // save that it was cashed out, if the offer is over
            mapLastCashout[_account] = nNextCashoutIndex;

            return true;
        }

        return bOfferCashout;
    }

    /*
    * @dev Returns the total amount of tokens the 
    * caller has in offers, up to _nPaymentDate
    */
    function getTotalInOffers(uint256 _nPaymentDate)
        public
        view
        returns (uint256)
    {
        // start the final balance as 0
        uint256 nBalance = 0;

        // get the latest offer index
        uint256 nCurrent = counterTotalOffers.current();

        // get the address of the sender
        address aSender = _msgSender();

        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[aSender];

        for (uint256 i = nLastCashout + 1; i <= nCurrent; i++) {
            // get offer start date
            uint256 nOfferDate = getOfferDate(i);

            // break if the offer started after the payment date
            if (nOfferDate > _nPaymentDate) {
                break;
            }

            // grab the offer from the map
            IOffer objOffer = mapOffers[i];

            // get the total amount the user bought at the offer
            uint256 nAddBalance = objOffer.getTotalBought(aSender);

            // get the total amount the user cashed out at the offer
            uint256 nRmvBalance = objOffer.getTotalCashedOut(aSender);

            // add the bought and remove the cashed out
            nBalance = nBalance.add(nAddBalance).sub(nRmvBalance);
        }

        return nBalance;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address aSender = _msgSender();
        // try to cashout all possible offers before transfering
        tryCashouts(aSender);

        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../modules/tokens/TokenTransfer.sol";
import "../modules/tokens/dividends/DividendsEther.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";

contract TestDividendsEther is TokenTransfer, DividendsEther {
    /**
     * @dev Transfer Dividends
     */
    constructor(
        address _owner,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_owner, _totalTokens, _tokenName, _tokenSymbol) {
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "./../TokenTransfer.sol";

abstract contract DividendsEther is TokenTransfer {
    uint256 private nSnapshotId;

    mapping(address => uint256) private mapLastPaymentSnapshot;
    mapping(uint256 => uint256) private mapEtherPayment;

    function withdrawDividends() public {
        // use payable so we can send the dividends
        address payable aSender = _msgSender();

        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[aSender];

        // make sure we have a next payment
        require(nLastPayment < nSnapshotId, "No new withdrawal");

        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);

        // save back that we have paid this user
        mapLastPaymentSnapshot[aSender] = nNextPayment;

        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(aSender, nNextPayment);

        // if there's balance, pay dividends
        if (nTokenBalance == 0) {
            // get the total eth balance for this payment
            uint256 nTotalEther = mapEtherPayment[nNextPayment];

            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalEther, nTokenSuppy);

            // send the ether value to the user
            aSender.transfer(nToReceive);
        }
        // console.log("Last Payment: %s", nLastPayment);
        // console.log("Next Payment: %s", nNextPayment);
        // console.log("Latest Payment: %s", nSnapshotId);
        // console.log("-------");
        // console.log("Total Supply: %s", nTokenSuppy);
        // console.log("Total Ether: %s", nTotalEther);
        // console.log("To Receive: %s", nToReceive);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        // snapshot the tokens at the moment the ether enters
        nSnapshotId = _snapshot();
        // register the balance in ether that entered
        mapEtherPayment[nSnapshotId] = msg.value;

        // console.log("Ether To be Paid: %s", msg.value);
        // console.log("Total Token supply: %s", totalSupplyAt(nSnapshotId));
    }

    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 xl = uint128(x);
        uint256 xh = x >> 128;
        uint256 yl = uint128(y);
        uint256 yh = y >> 128;
        uint256 xlyl = xl * yl;
        uint256 xlyh = xl * yh;
        uint256 xhyl = xh * yl;
        uint256 xhyh = xh * yh;

        uint256 ll = uint128(xlyl);
        uint256 lh = (xlyl >> 128) + uint128(xlyh) + uint128(xhyl);
        uint256 hl = uint128(xhyh) + (xlyh >> 128) + (xhyl >> 128);
        uint256 hh = (xhyh >> 128);
        l = ll + (lh << 128);
        h = (lh >> 128) + hl + (hh << 128);
    }

    /**
    * @dev Very cheap x*y/z
    */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../modules/tokens/TokenTransfer.sol";
import "../modules/tokens/dividends/DividendsERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";

contract TestDividendsERC20 is TokenTransfer, DividendsERC20 {
    /**
     * @dev Transfer Dividends
     */
    constructor(
        address _owner,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _dividendsToken
    )
        public
        TokenTransfer(_owner, _totalTokens, _tokenName, _tokenSymbol)
        DividendsERC20(_dividendsToken)
    {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../TokenTransfer.sol";

abstract contract DividendsERC20 is TokenTransfer {
    using SafeMath for uint256;

    // Index of the last token snapshot
    uint256 private nLastSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;

    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend total amount
    mapping(uint256 => uint256) private mapERCPayment;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;

    constructor(address _dividendsToken) public {
        // make sure the dividends token isnt empty
        require(_dividendsToken != address(0), "Dividends token cant be zero");

        // convert the address to an interface
        dividendsToken = IERC20(_dividendsToken);

        // get the balance of this contract to check if the interface works
        uint256 nBalance = dividendsToken.balanceOf(address(this));

        // this is never false, it's just a failsafe so that we execute balanceOf
        require(nBalance == 0, "Contract must have no balance");
    }

    /*
     * @dev Gets the address of the token used for dividends
     */
    function getDividendsToken() public view returns (address) {
        return address(dividendsToken);
    }

    /*
     * @dev Gets the total count of payments
     */
    function getTotalDividendPayments() public view returns (uint256) {
        return nLastSnapshotId;
    }

    function getPayment(uint256 _nIndex)
        public
        view
        returns (uint256 nERCPayment, uint256 nDate)
    {
        nERCPayment = mapERCPayment[_nIndex];
        nDate = mapPaymentDate[_nIndex];
    }

    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /*
     * @dev Function made for owner to transfer tokens to contract for dividend payment
     */
    function payDividends(uint256 _amount) public onlyOwner {
        // make sure the amount is not zero
        require(_amount > 0, "Amount cant be zero");

        // grab our current allowance
        uint256 nAllowance =
            dividendsToken.allowance(_msgSender(), address(this));

        // make sure we at least have the balance added
        require(_amount <= nAllowance, "Not enough balance to pay dividends");

        // transfer the tokens from the sender to the contract
        dividendsToken.transferFrom(_msgSender(), address(this), _amount);

        // snapshot the tokens at the moment the ether enters
        nLastSnapshotId = _snapshot();

        // register the balance in ether that entered
        mapERCPayment[nLastSnapshotId] = _amount;

        // save the date
        mapPaymentDate[nLastSnapshotId] = block.timestamp;
    }

    /*
     * @dev Withdraws dividends up to 16 times
     */
    function withdrawDividends() public {
        require(_withdrawDividends(), "No new withdrawal");

        for (uint256 i = 0; i < 15; i++) {
            if (!_withdrawDividends()) {
                return;
            }
        }
    }

    function _recursiveGetTotalDividends(address _investor)
        internal
        view
        returns (uint256)
    {
        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[_investor];

        // make sure we have a next payment
        if (nLastPayment >= nLastSnapshotId) {
            return 0;
        }

        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);

        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(_investor, nNextPayment);

        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[nNextPayment];

        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate);

        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);

        if (nTokenBalance == 0) {
            return 0;
        } else {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[nNextPayment];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalTokens, nTokenSuppy);

            return nToReceive;
        }
    }

    /**
     * @dev Gets the total amount of dividends for an investor
     */
    function getTotalDividends(address _investor)
        public
        view
        returns (uint256)
    {
        uint256 nBalance = 0;

        for (uint256 i = 0; i < 16; i++) {
            nBalance = nBalance.add(_recursiveGetTotalDividends(_investor));
        }

        return nBalance;
    }

    /*
     * @dev Based on how many tokens the user had at the snapshot,
     * pay dividends of the erc20 token
     * (also pays for tokens inside offer)
     */
    function _withdrawDividends() private returns (bool) {
        // cache the sender
        address aSender = _msgSender();

        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[aSender];

        // make sure we have a next payment
        if (nLastPayment >= nLastSnapshotId) {
            return false;
        }

        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);

        // save back that we have paid this user
        mapLastPaymentSnapshot[aSender] = nNextPayment;

        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(aSender, nNextPayment);

        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[nNextPayment];

        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate);

        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);

        if (nTokenBalance != 0) {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[nNextPayment];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalTokens, nTokenSuppy);

            // send the ERC20 value to the user
            dividendsToken.transfer(aSender, nToReceive);
        }

        return true;
    }

    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 xl = uint128(x);
        uint256 xh = x >> 128;
        uint256 yl = uint128(y);
        uint256 yh = y >> 128;
        uint256 xlyl = xl * yl;
        uint256 xlyh = xl * yh;
        uint256 xhyl = xh * yl;
        uint256 xhyh = xh * yh;

        uint256 ll = uint128(xlyl);
        uint256 lh = (xlyl >> 128) + uint128(xlyh) + uint128(xhyl);
        uint256 hl = uint128(xhyh) + (xlyh >> 128) + (xhyl >> 128);
        uint256 hh = (xhyh >> 128);
        l = ll + (lh << 128);
        h = (lh >> 128) + hl + (hh << 128);
    }

    /**
     * @dev Very cheap x*y/z
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../base/IOffer.sol";

contract CRZ0Token is ERC20Snapshot, Ownable {
    // Name of the token
    string public constant TOKEN_NAME = "Cruzeiro Token - Talentos da Toca";
    // Symbol of the token
    string public constant TOKEN_SYMBOL = "CRZ0";
    // Total amount of tokens
    uint256 public constant TOTAL_TOKENS = 792000 * 1 ether;
    // Date the token should expire
    uint256 public constant EXPIRATION_DATE_AFTER = 1811865600;
    // Date the token should unlock for the emitter
    uint256 public constant LOCKUP_EMITTER_DATE_AFTER = 1811865600;
    // Total amount the emitter has to hold
    uint256 public constant LOCKUP_EMITTER_AMOUNT = 475200 * 1 ether;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    // A map of the offer index to the start date
    mapping(uint256 => uint256) internal mapOfferStartDate;
    // A map of the offer index to the offer object
    mapping(uint256 => IOffer) internal mapOffers;
    // A map of the investor to the last cashout he did
    mapping(address => uint256) internal mapLastCashout;
    // An internal counter to keep track of the offers
    Counters.Counter internal counterTotalOffers;
    // address of the receiver
    address internal aReceiver;
    // Index of the last token snapshot
    uint256 private nSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;
    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend total amount
    mapping(uint256 => uint256) private mapERCPayment;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;
    // A reference to the emitter of the offer
    address internal aEmitter;

    // A fuse to disable the exchangeBalance function
    bool internal bDisabledExchangeBalance;

    constructor(
        address _receiver,
        address _dividendsToken,
        address _emitter
    ) public ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        // make sure the receiver is not empty
        require(_receiver != address(0));
        // save address of the receiver
        aReceiver = _receiver;
        // mints all tokens to receiver
        _mint(_receiver, TOTAL_TOKENS);
        // make sure the dividends token isnt empty
        require(_dividendsToken != address(0), "Dividends token cant be zero");
        // convert the address to an interface
        dividendsToken = IERC20(_dividendsToken);
        // get the balance of this contract to check if the interface works
        uint256 nBalance = dividendsToken.balanceOf(address(this));
        // this is never false, it's just a failsafe so that we execute balanceOf
        require(nBalance == 0, "Contract must have no balance");
        require(_emitter != address(0), "Emitter is empty");
        // save the address of the emitter
        aEmitter = _emitter;
    }

    /*
     * @dev Get the date the offer of the _index started
     */
    function getOfferDate(uint256 _index) public view returns (uint256) {
        return mapOfferStartDate[_index];
    }

    /*
     * @dev Get the address of the _index offer
     */
    function getOfferAddress(uint256 _index) public view returns (address) {
        return address(mapOffers[_index]);
    }

    /*
     * @dev Get the index of the last cashout for the _account
     */
    function getLastCashout(address _account) public view returns (uint256) {
        return mapLastCashout[_account];
    }

    /*
     * @dev Get the total amount of offers registered
     */
    function getTotalOffers() public view returns (uint256) {
        return counterTotalOffers.current();
    }

    /*
     * @dev Registers a sale on the token
     */
    function startSale(address _aTokenSale) public onlyOwner returns (uint256) {
        // make sure the address isn't empty
        require(_aTokenSale != address(0), "Sale cant be empty");
        // convert the sale to a interface
        IOffer objSale = IOffer(_aTokenSale);
        // make sure the sale is intiialized
        require(!objSale.getInitialized(), "Sale should not be initialized");
        // increment the total of offers
        counterTotalOffers.increment();
        // gets the current offer index
        uint256 nCurrentId = counterTotalOffers.current();
        // save the address of the sale
        mapOffers[nCurrentId] = objSale;
        // save the date the offer should be considered for dividends
        mapOfferStartDate[nCurrentId] = block.timestamp;
        // initialize the sale
        objSale.initialize();
        return nCurrentId;
    }

    /*
     * @dev Try to cashout up to 15 times
     */
    function tryCashouts(address aSender) private {
        for (uint256 i = 0; i < 15; i++) {
            if (!cashoutFrozenAny(aSender)) {
                return;
            }
        }
    }

    /*
     * @dev Main cashout function, cashouts up to 16 times
     */
    function cashoutFrozen() public {
        // cache the sender
        address aSender = _msgSender();
        bool bHasCashout = cashoutFrozenAny(aSender);
        require(bHasCashout, "No cashouts available");
        // try to do 10 cashouts
        tryCashouts(aSender);
    }

    /**
     * @return true if it changed the state
     */
    function cashoutFrozenAny(address _account) public virtual returns (bool) {
        // get the latest token sale that was cashed out
        uint256 nCurrentSnapshotId = counterTotalOffers.current();
        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[_account];
        // return if its the latest offer
        if (nCurrentSnapshotId <= nLastCashout) {
            return false;
        }
        // add 1 to get the next payment index
        uint256 nNextCashoutIndex = nLastCashout.add(1);
        // get the address of the offer this user is cashing out
        IOffer offer = mapOffers[nNextCashoutIndex];
        // cashout the tokens, if the offer allows
        bool bOfferCashout = offer.cashoutTokens(_account);
        // check if the sale is finished
        if (offer.getFinished()) {
            // save that it was cashed out, if the offer is over
            mapLastCashout[_account] = nNextCashoutIndex;
            return true;
        }
        return bOfferCashout;
    }

     /*
     * @dev Returns the total amount of tokens the
     * caller has in offers, up to _nPaymentDate
     */
    function getTotalInOffers(uint256 _nPaymentDate, address _aInvestor)
        public
        view
        returns (uint256)
    {
        // start the final balance as 0
        uint256 nBalance = 0;

        // get the latest offer index
        uint256 nCurrent = counterTotalOffers.current();

        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[_aInvestor];

        for (uint256 i = nLastCashout + 1; i <= nCurrent; i++) {
            // get offer start date
            uint256 nOfferDate = getOfferDate(i);

            // break if the offer started after the payment date
            if (nOfferDate > _nPaymentDate) {
                break;
            }

            // grab the offer from the map
            IOffer objOffer = mapOffers[i];

            // get the total amount the user bought at the offer
            uint256 nAddBalance = objOffer.getTotalBought(_aInvestor);

            // get the total amount the user cashed out at the offer
            uint256 nRmvBalance = objOffer.getTotalCashedOut(_aInvestor);

            // add the bought and remove the cashed out
            nBalance = nBalance.add(nAddBalance).sub(nRmvBalance);
        }

        return nBalance;
    }

    /*
     * @dev Gets the address of the token used for dividends
     */
    function getDividendsToken() public view returns (address) {
        return address(dividendsToken);
    }

    /*
     * @dev Gets the total count of payments
     */
    function getTotalDividendPayments() public view returns (uint256) {
        return nSnapshotId;
    }

    function getPayment(uint256 _nIndex)
        public
        view
        returns (uint256 nERCPayment, uint256 nDate)
    {
        nERCPayment = mapERCPayment[_nIndex];
        nDate = mapPaymentDate[_nIndex];
    }

    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /*
     * @dev Function made for owner to transfer tokens to contract for dividend payment
     */
    function payDividends(uint256 _amount) public onlyOwner {
        // make sure the amount is not zero
        require(_amount > 0, "Amount cant be zero");
        // grab our current allowance
        uint256 nAllowance =
            dividendsToken.allowance(_msgSender(), address(this));
        // make sure we at least have the balance added
        require(_amount <= nAllowance, "Not enough balance to pay dividends");
        // transfer the tokens from the sender to the contract
        dividendsToken.transferFrom(_msgSender(), address(this), _amount);
        // snapshot the tokens at the moment the ether enters
        nSnapshotId = _snapshot();
        // register the balance in ether that entered
        mapERCPayment[nSnapshotId] = _amount;
        // save the date
        mapPaymentDate[nSnapshotId] = block.timestamp;
    }

    /*
     * @dev Withdraws dividends up to 16 times
     */
    function withdrawDividends() public {
        require(_withdrawDividends(), "No new withdrawal");
        for (uint256 i = 0; i < 15; i++) {
            if (!_withdrawDividends()) {
                return;
            }
        }
    }

    function _recursiveGetTotalDividends(
        address _aInvestor,
        uint256 _nPaymentIndex
    ) internal view returns (uint256) {
        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(_aInvestor, _nPaymentIndex);

        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[_nPaymentIndex];

        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate, _aInvestor);

        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);

        if (nTokenBalance == 0) {
            return 0;
        } else {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(_nPaymentIndex);

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[_nPaymentIndex];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalTokens, nTokenSuppy);

            return nToReceive;
        }
    }

    /**
     * @dev Gets the total amount of dividends for an investor
     */
    function getTotalDividends(address _investor)
        public
        view
        returns (uint256)
    {
        // start total balance 0
        uint256 nBalance = 0;

        // get the last payment index for the investor
        uint256 nLastPayment = mapLastPaymentSnapshot[_investor];

        // add 16 as the limit
        uint256 nEndPayment = nLastPayment.add(16);

        // loop
        for (uint256 i = nLastPayment + 1; i < nEndPayment; i++) {
            // add the balance that would be withdrawn if called for this index
            nBalance = nBalance.add(_recursiveGetTotalDividends(_investor, i));

            // if bigger than all total snapshots, end the loop
            if (i >= nSnapshotId) {
                break;
            }
        }

        return nBalance;
    }

    /*
     * @dev Based on how many tokens the user had at the snapshot,
     * pay dividends of the erc20 token
     * (also pays for tokens inside offer)
     */
    function _withdrawDividends() private returns (bool) {
        // cache the sender
        address aSender = _msgSender();
        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[aSender];
        // make sure we have a next payment
        if (nLastPayment >= nSnapshotId) {
            return false;
        }
        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);
        // save back that we have paid this user
        mapLastPaymentSnapshot[aSender] = nNextPayment;
        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(aSender, nNextPayment);
        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[nNextPayment];
        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate, aSender);
        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);
        if (nTokenBalance != 0) {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);
            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[nNextPayment];
            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalTokens, nTokenSuppy);
            // send the ERC20 value to the user
            dividendsToken.transfer(aSender, nToReceive);
        }
        return true;
    }

    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 xl = uint128(x);
        uint256 xh = x >> 128;
        uint256 yl = uint128(y);
        uint256 yh = y >> 128;
        uint256 xlyl = xl * yl;
        uint256 xlyh = xl * yh;
        uint256 xhyl = xh * yl;
        uint256 xhyh = xh * yh;
        uint256 ll = uint128(xlyl);
        uint256 lh = (xlyl >> 128) + uint128(xlyh) + uint128(xhyl);
        uint256 hl = uint128(xhyh) + (xlyh >> 128) + (xhyl >> 128);
        uint256 hh = (xhyh >> 128);
        l = ll + (lh << 128);
        h = (lh >> 128) + hl + (hh << 128);
    }

    /**
     * @dev Very cheap x*y/z
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address aSender = _msgSender();
        // try to cashout all possible offers before transfering
        tryCashouts(aSender);
        // check if were allowed to continue
        if (block.timestamp > EXPIRATION_DATE_AFTER) {
            revert("Date is after token lockup date");
        }
        if (_msgSender() == aEmitter) {
            // rule only applies before
            if (block.timestamp < LOCKUP_EMITTER_DATE_AFTER) {
                // check if the balance is enough
                uint256 nBalance = balanceOf(aEmitter);
                // remove the transfer from the balance
                uint256 nFinalBalance = nBalance.sub(amount);
                // make sure the remaining tokens are more than the needed by the rule
                require(
                    nFinalBalance >= LOCKUP_EMITTER_AMOUNT,
                    "Transfering more than account allows"
                );
                super._beforeTokenTransfer(from, to, amount);
            }
        }
    }

    /**
     * @dev Disables the exchangeBalance function
     */
    function disableExchangeBalance() public onlyOwner {
        require(
            !bDisabledExchangeBalance,
            "Exchange balance is already disabled"
        );

        bDisabledExchangeBalance = true;
    }

    /**
     * @dev Exchanges the funds of one address to another
     */
    function exchangeBalance(address _from, address _to) public onlyOwner {
        // check if the function is disabled
        require(
            !bDisabledExchangeBalance,
            "Exchange balance has been disabled"
        );
        // simple checks for empty addresses
        require(_from != address(0), "Transaction from 0x");
        require(_to != address(0), "Transaction to 0x");

        // get current balance of _from address
        uint256 amount = balanceOf(_from);

        // check if there's balance to transfer
        require(amount != 0, "Balance is 0");

        // transfer balance to new address
        _transfer(_from, _to, amount);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IOffer.sol";

contract BaseOfferSale is Ownable, IOffer {
    using SafeMath for uint256;

    bool internal bInitialized;
    bool internal bFinished;
    bool internal bSuccess;

    uint256 internal nTotalSold;
    uint256 internal nFinishDate;

    uint256 private nRate = 1;


    function initialize() public override {
        require(!bInitialized, "Sale is initialized");
        bInitialized = true;

        _initialize();
    }

    function setSuccess() public onlyOwner {
        require(bInitialized, "Sale is not initialized");

        require(!bSuccess, "Sale is already successful");

        bSuccess = true;
    }

    function getInitialized() public view override returns (bool) {
        return bInitialized;
    }

    function getFinished() public view override returns (bool) {
        return bFinished;
    }

    function getSuccess() public view override returns (bool) {
        return bSuccess;
    }

    function getTotalBought(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function getTotalCashedOut(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function invest(address _investor, uint256 _amount)
        public
        onlyOwner
    {
        require(_investor != address(0), "Investor is empty");
        require(_amount != 0, "Amount is zero");
        require(!bFinished, "Sale is finished");
        require(bInitialized, "Sale is not initialized");

        // pass the function to one of our modules
        _investInput(_investor, _amount);

        // convert input currency to output
        // - get rate from module
        uint256 nRate = _getRate();

        // - total amount from the rate obtained
        uint256 nOutputAmount = _amount.div(nRate);

        // pass to module to handling outputs
        _investOutput(_investor, nOutputAmount);

        // after everything, add the bought tokens to the total
        nTotalSold = nTotalSold.add(nOutputAmount);

        // now make sure everything we've done is okay
        _rule();

        // and check if the sale is sucessful after this sale
        _checkSuccess();
    }

    function finishSale() public onlyOwner {
        require(!bFinished, "Sale is finished");
        bFinished = true;

        nFinishDate = block.timestamp;

        _finishSale();
    }

    function getTotalSold() public view virtual returns (uint256 totalSold) {
        return nTotalSold;
    }

    function cashoutTokens(address _investor)
        external
        virtual
        override
        returns (bool)
    {
        return bFinished;
    }

    function _initialize() internal virtual {}

    function _investInput(address _investor, uint256 _amount)
        internal
        virtual
    {}

    function _investOutput(address _investor, uint256 _outputAmount)
        internal
        virtual
    {}

    function _finishSale() internal virtual {}

    function _rule() internal virtual {}

    function _checkSuccess() internal virtual {}

    function _getRate() internal view virtual returns (uint256 rate) {
        return nRate;
    }

    function setRate(uint256 _rate) public {
        nRate = _rate;
    }

    function getFinishDate() external view override returns (uint256) {
        return nFinishDate;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../../../base/BaseOfferSale.sol";
import "../../../base/BaseOfferToken.sol";
import "hardhat/console.sol";

contract OutputOnDemandTransfer is BaseOfferSale {
    // Use safe math for add and sub
    using SafeMath for uint256;

    // Create a structure to save our payments
    struct Payment {
        // The total amount the user bought in tokens
        uint256 totalAmount;
        // The total amount the user has received in tokens
        uint256 totalPaid;
    }

    // A reference to the token were selling
    BaseOfferToken private baseToken;
    
    // A map of address to payment
    mapping(address => Payment) private mapPayments;

    // A reference to the emitter of the offer
    address private aEmitter;

    /**
     * @dev Investment with ERC20 token
     */
    constructor(address _emitter, address _tokenAddress)
        public
        BaseOfferSale()
    {
        aEmitter = _emitter;
        baseToken = BaseOfferToken(_tokenAddress);
    }

    function _initialize() internal override {
        require(_msgSender() == address(baseToken), "Only call from token");
    }

    function _investOutput(address _investor, uint256 nOutputAmount)
        internal
        virtual
        override
    {
        // get the current contract's balance
        uint256 nBalance = baseToken.balanceOf(address(this));

        // calculate how many tokens we can sell
        uint256 nRemainingBalance = nBalance.sub(nTotalSold);

        // make sure we're not selling more than we have
        require(
            nOutputAmount <= nRemainingBalance,
            "Offer does not have enough tokens to sell"
        );

        // read the payment data from our map
        Payment memory payment = mapPayments[_investor];

        // increase the amount of tokens this investor has purchased
        payment.totalAmount = payment.totalAmount.add(nOutputAmount);

        mapPayments[_investor] = payment;
    }

    function _finishSale() internal virtual override {
        // get the current contract's balance
        uint256 nBalance = baseToken.balanceOf(address(this));

        if (getSuccess()) {
            // calculate how many tokens we have not sold
            uint256 nRemainingBalance = nBalance.sub(nTotalSold);

            // return remaining tokens to owner
            baseToken.transfer(aEmitter, nRemainingBalance);
        } else {
            // return all tokens to owner
            baseToken.transfer(aEmitter, nBalance);
        }
    }

    function cashoutTokens(address _investor) external override returns (bool) {
        require(_msgSender() == address(baseToken), "Call only from token");

        // wait till the offer is successful to allow transfer
        if (!bSuccess) {
            return false;
        }

        // read the token sale data for that address
        Payment storage payment = mapPayments[_investor];

        // nothing to be paid
        if (payment.totalAmount == 0) {
            return false;
        }

        // calculate the remaining tokens
        uint256 nRemaining = payment.totalAmount.sub(payment.totalPaid);

        // make sure there's something to be paid
        if (nRemaining == 0) {
            return false;
        }

        // transfer to requested user
        baseToken.transfer(_investor, nRemaining);

        // mark that we paid the user in fully
        payment.totalPaid = payment.totalAmount;

        return true;
    }

    function getTotalBought(address _investor)
        public
        view
        override
        returns (uint256)
    {
        return mapPayments[_investor].totalAmount;
    }

    function getTotalCashedOut(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return mapPayments[_investor].totalPaid;
    }

    function getToken() public view returns (address token) {
        return address(baseToken);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

// Lock token before date
contract LockupEmitterDateAfter is TokenTransfer {
    uint256 public constant LOCKUP_EMITTER_DATE_AFTER = 1935663322; // May 4th 2100
    uint256 public constant LOCKUP_EMITTER_AMOUNT = 10000 * 1 ether; // Total amount of tokens the user has to hold

    // A reference to the emitter of the offer
    address internal aEmitter;

    /**
     * @dev
     */
    constructor(
        address _receiver,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _emitter
    ) public TokenTransfer(_receiver, _totalTokens, _tokenName, _tokenSymbol) {
        require(_emitter != address(0), "Emitter is empty");
        
        // save the address of the emitter
        aEmitter = _emitter;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (_msgSender() == aEmitter) {
            // rule only applies before
            if (block.timestamp < LOCKUP_EMITTER_DATE_AFTER) {
                // check if the balance is enough
                uint256 nBalance = balanceOf(aEmitter);

                // remove the transfer from the balance
                uint256 nFinalBalance = nBalance.sub(amount);

                // make sure the remaining tokens are more than the needed by the rule
                require(nFinalBalance >= LOCKUP_EMITTER_AMOUNT, "Transfering more than account allows");
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

// Lock up before date
contract ExpirationDateBefore is TokenTransfer {
    uint256 public constant EXPIRATION_DATE_RELEASE = 1967286694;
    bool private bInitialized;

    /**
     * @dev
     */
    constructor(
        address _emitter,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_emitter, _totalTokens, _tokenName, _tokenSymbol) {
        bInitialized = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (bInitialized && block.timestamp < EXPIRATION_DATE_RELEASE) {
            revert("Date is before token release date");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

// Lock token after date
contract ExpirationDateAfter is TokenTransfer {
    uint256 public constant EXPIRATION_DATE_AFTER = 1935663322;  // May 4th 2100 

    /**
     * @dev
     */
    constructor(
        address _emitter,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_emitter, _totalTokens, _tokenName, _tokenSymbol) {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (block.timestamp > EXPIRATION_DATE_AFTER) {
            revert("Date is after token lockup date");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../../../base/BaseOfferSale.sol";
import "../../../LiqiBRLToken.sol";

contract InputBRLT is BaseOfferSale {
    // A reference to the BRLToken contract
    LiqiBRLToken private brlToken;
    // A reference to the emitter of the offer
    address private aEmitter;

    /**
     * @dev Investment with ERC20 token
     */
    constructor(address _emitter, address _brlTokenContract)
        public
        BaseOfferSale()
    {
        aEmitter = _emitter;
        brlToken = LiqiBRLToken(_brlTokenContract);
    }

    /*
     * @dev Cashouts BRLTs paid to the offer to the emitter
     */
    function cashoutBRLT() public {
        // no unsuccessful sale
        require(bSuccess, "Sale is not successful");

        // check the balance of tokens of this contract
        uint256 nBalance = brlToken.balanceOf(address(this));

        // nothing to execute if the balance is 0
        require(nBalance != 0, "Balance to cashout is 0");

        // transfer all tokens to the emitter account
        brlToken.transfer(aEmitter, nBalance);
    }

    function _finishSale() internal virtual override {
        if (!getSuccess()) {
            // notify the BRLT 
            brlToken.failedSale();
        }
    }

    function _investInput(address _investor, uint256 _amount)
        internal
        virtual
        override
    {
        // call with same args
        brlToken.invest(_investor, _amount);
    }

    /*
     * @dev Returns the address of the input token
     */
    function getTokenAddress() public view returns (address) {
        return address(brlToken);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiqiToken is ERC20 {
    constructor() public ERC20("Liqi Stock Token", "LIQI") {
        _mint(0x5D4a575D03af19414c728963ef620c6A4925AfEc, 43000 ether);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract RuleMaxTx {
    function _ruleMaxTx(uint256 _maxTx, uint256 _amount) public pure virtual {
        require(_amount <= _maxTx, "Rule: max tx amount");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract RuleMinTx {
    function _ruleMinTx(uint256 _minTx, uint256 _amount) public pure virtual {
        require(_amount >= _minTx, "Rule: min tx amount");
    }
}