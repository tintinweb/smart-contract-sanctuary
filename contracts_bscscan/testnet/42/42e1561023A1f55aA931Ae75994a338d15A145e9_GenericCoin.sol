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

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Constructors.sol";
import "../roles/Manageable.sol";

contract AntiWhaleHelper is Ownable, Manageable {
    using SafeMath for uint256;

    IERC20 _token;
    address _pancakeSwapLiquidityPairAddress = 0x0000000000000000000000000000000000000000;

    bool _isMaxSellTransactionAmountOptionEnabled;
    uint256 _maxSellTransactionAmount;
    uint256 _whiteListMaxSellTransactionAmount;
    uint256 _goldListMaxSellTransactionAmount;

    bool _isMaxWalletSizeOptionEnabled;
    uint256 _maxWalletSize;
    uint256 _whiteListMaxWalletSize;
    uint256 _goldListMaxWalletSize;

    bool _isWhaleMaxSellTransactionAmountOptionEnabled;
    uint256 _whalePercentageThreshold;
    uint256 _whaleMaxSellTransactionAmount;
    uint256 _whiteListWhaleMaxSellTransactionAmount;
    uint256 _goldListWhaleMaxSellTransactionAmount;

    uint256 _whaleSellFeePerThousand;
    uint256 _whiteListWhaleSellFeePerThousand;
    uint256 _goldListWhaleSellFeePerThousand;

    mapping(address => bool) public _vipAddresses;
    mapping(address => bool) public _goldAddresses;
    mapping(address => bool) public _whiteListAddresses;

    constructor(
        address tokenAddress,
        uint256 decimals,
        address tokenOwnerAddress,
        address pancakePairAddress,
        Constructors.AntiWhaleParams memory params
    ){
        _token = IERC20(tokenAddress);
        _vipAddresses[address(_token)] = true;
        _vipAddresses[tokenOwnerAddress] = true;

        _isMaxWalletSizeOptionEnabled = params.isMaxWalletSizeOptionEnabled;
        _maxWalletSize = params.humanReadableMaxWalletSize.mul((10 ** decimals));
        _whiteListMaxWalletSize = params.humanReadableWhiteListMaxWalletSize.mul((10 ** decimals));
        _goldListMaxWalletSize = params.humanReadableGoldListMaxWalletSize.mul((10 ** decimals));

        _isMaxSellTransactionAmountOptionEnabled = params.isMaxSellTransactionAmountOptionEnabled;
        _maxSellTransactionAmount = params.humanReadableMaxSellTransactionAmount.mul((10 ** decimals));
        _whiteListMaxSellTransactionAmount = params.humanReadableWhiteListMaxSellTransactionAmount.mul((10 ** decimals));
        _goldListMaxSellTransactionAmount = params.humanReadableGoldListMaxSellTransactionAmount.mul((10 ** decimals));

        _whalePercentageThreshold = params.whalePercentageThreshold;

        _isWhaleMaxSellTransactionAmountOptionEnabled = params.isWhaleMaxSellTransactionAmountOptionEnabled;
        _whaleMaxSellTransactionAmount = params.humanReadableWhaleMaxSellTransactionAmount.mul((10 ** decimals));
        _whiteListWhaleMaxSellTransactionAmount = params.humanReadableWhiteListWhaleMaxSellTransactionAmount.mul((10 ** decimals));
        _goldListWhaleMaxSellTransactionAmount = params.humanReadableGoldListWhaleMaxSellTransactionAmount.mul((10 ** decimals));

        _whaleSellFeePerThousand = params.whaleSellFeePerThousand;
        _whiteListWhaleSellFeePerThousand = params.whiteListWhaleSellFeePerThousand;
        _goldListWhaleSellFeePerThousand = params.goldListWhaleSellFeePerThousand;

        _pancakeSwapLiquidityPairAddress = pancakePairAddress;
    }

    function removeFromVipList(address vipAddress) external onlyAdmin {
        require(_vipAddresses[vipAddress] == true, "address is not in vip list");
        _vipAddresses[vipAddress] = false;
    }

    function addToVipList(address vipAddress) external onlyAdmin {
        require(_vipAddresses[vipAddress] == false, "address is already in vip list");
        if (_whiteListAddresses[vipAddress]) {
            _whiteListAddresses[vipAddress] = false;
        }
        if (_goldAddresses[vipAddress]) {
            _goldAddresses[vipAddress] = false;
        }
        _vipAddresses[vipAddress] = true;
    }

    function removeFromGoldList(address goldAddress) external onlyAdmin {
        require(_goldAddresses[goldAddress] == true, "address is not in gold list");
        _goldAddresses[goldAddress] = false;
    }

    function addToGoldList(address goldAddress) external onlyAdmin {
        require(_goldAddresses[goldAddress] == false, "address is already in gold list");
        require(_vipAddresses[goldAddress] == false, "Already in VIP list");
        if (_whiteListAddresses[goldAddress]) {
            _whiteListAddresses[goldAddress] = false;
        }
        _goldAddresses[goldAddress] = true;
    }

    function removeFromWhitelist(address whiteListAddress) external onlyAdmin {
        require(_whiteListAddresses[whiteListAddress] == true, "address is not in whitelist");

        _whiteListAddresses[whiteListAddress] = false;
    }

    function addToWhitelist(address whiteListAddress) external onlyAdmin {
        require(_whiteListAddresses[whiteListAddress] == false, "address is already in whitelist");
        require(_vipAddresses[whiteListAddress] == false, "Already in VIP list");
        require(_goldAddresses[whiteListAddress] == false, "Already in gold list");

        _whiteListAddresses[whiteListAddress] = true;
    }

    function isInWhiteList(address wallet) external view onlyAdmin returns (bool)  {
        return _whiteListAddresses[wallet];
    }

    function isInGoldList(address wallet) external view onlyAdmin returns (bool)  {
        return _goldAddresses[wallet];
    }

    function isInVipList(address wallet) external view onlyAdmin returns (bool)  {
        return _vipAddresses[wallet];
    }

    function isMaxWalletSizeOptionEnabled() external view returns (bool){
        return _isMaxWalletSizeOptionEnabled;
    }

    function getMaxWalletSize() external view returns (uint256){
        return _maxWalletSize;
    }

    function getWhitelistMaxWalletSize() external view returns (uint256){
        return _whiteListMaxWalletSize;
    }

    function getGoldMaxWalletSize() external view returns (uint256){
        return _goldListMaxWalletSize;
    }

    function isMaxSellTransactionAmountOptionEnabled() external view returns (bool){
        return _isMaxSellTransactionAmountOptionEnabled;
    }

    function getMaxSellTransactionAmount() external view returns (uint256){
        return _maxSellTransactionAmount;
    }

    function isWhaleMaxSellTransactionAmountOptionEnabled() external view returns (bool){
        return _isWhaleMaxSellTransactionAmountOptionEnabled;
    }

    function getWhalePercentageThreshold() external view returns (uint256){
        return _whalePercentageThreshold;
    }

    function getWhaleMaxSellTransactionAmount() external view returns (uint256){
        return _whaleMaxSellTransactionAmount;
    }

    function isWhale(address wallet) public view returns (bool){
        if (_vipAddresses[wallet]) {
            return false;
        }
        uint256 computedWhaleBalance = _token.totalSupply() * _whalePercentageThreshold / 100;
        if (_token.balanceOf(wallet) > computedWhaleBalance) {
            return true;
        }
        return false;
    }

    function isTransactionAllowed(address from, address to, uint256 amount) external view returns (bool){
        if (_vipAddresses[from] || _vipAddresses[to]) {
            return true;
        }
        //buy
        if (_pancakeSwapLiquidityPairAddress == from) {
            return isBuyTransactionAllowed(to, amount);
        }
        //sell
        if (_pancakeSwapLiquidityPairAddress == to) {
            return isSellTransactionAllowed(from, amount);
        }
        return true;
    }

    function isBuyTransactionAllowed(address buyerAddress, uint256 amount) public view returns (bool){
        if (!_isMaxWalletSizeOptionEnabled) {
            return true;
        }

        uint256 computedNewBalance = _token.balanceOf(buyerAddress) + amount;

        if (computedNewBalance <= _maxWalletSize) {
            return true;
        }

        if (_whiteListAddresses[buyerAddress] && computedNewBalance <= _whiteListMaxWalletSize) {
            return true;
        }

        if (_goldAddresses[buyerAddress] && computedNewBalance <= _goldListMaxWalletSize) {
            return true;
        }

        return false;
    }

    function getSellFeePerThousand(address seller) external view returns (uint256){
        if (!isWhale(seller)) {
            return 0;
        }
        if (_goldAddresses[seller]) {
            return _goldListWhaleSellFeePerThousand;
        }
        if (_whiteListAddresses[seller]) {
            return _whiteListWhaleSellFeePerThousand;
        }
        return _whaleSellFeePerThousand;
    }

    function isSellTransactionAllowed(address sellerAddress, uint256 amount) public view returns (bool){
        if (isWhale(sellerAddress)) {
            if (!isWhaleSellTransactionAllowed(sellerAddress, amount)) {
                return false;
            }
        }

        return isStandardSellTransactionAllowed(sellerAddress, amount);
    }

    function isWhaleSellTransactionAllowed(address sellerAddress, uint256 amount) internal view returns (bool){
        if (!_isWhaleMaxSellTransactionAmountOptionEnabled) {
            return true;
        }

        //gold whale
        if (_goldAddresses[sellerAddress] && amount <= _goldListWhaleMaxSellTransactionAmount) {
            return true;
        }

        //whiteList whale
        if (_whiteListAddresses[sellerAddress] && amount <= _whiteListWhaleMaxSellTransactionAmount) {
            return true;
        }

        //standard whale
        if (amount <= _whaleMaxSellTransactionAmount) {
            return true;
        }

        return false;
    }

    function isStandardSellTransactionAllowed(address sellerAddress, uint256 amount) internal view returns (bool){
        if (!_isMaxSellTransactionAmountOptionEnabled) {
            return true;
        }

        //gold whale
        if (_goldAddresses[sellerAddress] && amount <= _goldListMaxSellTransactionAmount) {
            return true;
        }

        //whiteList whale
        if (_whiteListAddresses[sellerAddress] && amount <= _whiteListMaxSellTransactionAmount) {
            return true;
        }

        //standard whale
        if (amount <= _maxSellTransactionAmount) {
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;

contract Constructors {

    struct CoinInitializer {
        string name;
        string symbol;
        uint256 decimals;
        uint256 humanReadableInitialSupply;
        address routerAddress;
        address payableAddress;
    }

    struct FeeParams {
        bool isRewardOptionEnabled;
        uint256 bnbRewardsFee;
        uint256 claimWaitInSec;
        uint256 humanReadableRewardMinAmount;
        bool isAddLiquidityOptionEnabled;
        uint256 liquidityFee;
        bool isMarketingFeesOptionEnabled;
        uint256 marketingFee;
        address marketingAddress;
        bool isBurnOptionEnabled;
        uint256 burnFee;
    }

    struct AntiWhaleParams {
        bool isMaxSellTransactionAmountOptionEnabled;
        uint256 humanReadableMaxSellTransactionAmount;
        uint256 humanReadableWhiteListMaxSellTransactionAmount;
        uint256 humanReadableGoldListMaxSellTransactionAmount;

        bool isMaxWalletSizeOptionEnabled;
        uint256 humanReadableMaxWalletSize;
        uint256 humanReadableWhiteListMaxWalletSize;
        uint256 humanReadableGoldListMaxWalletSize;

        uint256 whalePercentageThreshold;
        bool isWhaleMaxSellTransactionAmountOptionEnabled;
        uint256 humanReadableWhaleMaxSellTransactionAmount;
        uint256 humanReadableWhiteListWhaleMaxSellTransactionAmount;
        uint256 humanReadableGoldListWhaleMaxSellTransactionAmount;

        uint256 whaleSellFeePerThousand;
        uint256 whiteListWhaleSellFeePerThousand;
        uint256 goldListWhaleSellFeePerThousand;

        uint256 vipListEthPrice;
        uint256 goldListEthPrice;
        uint256 whiteListEthPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";


/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal magnitude = 2 ** 128;

    uint256 internal magnifiedDividendPerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

    }

    /// @dev Distributes dividends whenever ether is paid to this contract.
    receive() external payable {
        distributeDividends();
    }

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.
    function distributeDividends() public override payable {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success,) = user.call{value : _withdrawableDividend, gas : 3000}("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }


    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }


    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) public view override returns (uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function burn(address account, uint256 value) public {
        require(balanceOf(msg.sender) > value, "Cannot burn what you don't have");
        _burn(account, value);
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) external view returns (uint256);

    /// @notice Distributes ether to token holders as dividends.
    /// @dev SHOULD distribute the paid ether to token holders as dividends.
    ///  SHOULD NOT directly transfer ether to token holders in this function.
    ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
    function distributeDividends() external payable;

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
    function withdrawDividend() external;

    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount
    );

    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ether from this contract.
    /// @param weiAmount The amount of withdrawn ether in wei.
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) external view returns (uint256);

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) external view returns (uint256);

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DividendPayingToken.sol";
import "./IterableMapping.sol";

contract DividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(
        uint256 decimals,
        uint256 claimWaitInSec,
        uint256 humanReadableMinimumBalance
    )
    DividendPayingToken(
        "Dividend_Tracker",
        "Dividend_Tracker"
    ) {
        claimWait = claimWaitInSec;
        minimumTokenBalanceForDividends = humanReadableMinimumBalance * (10 ** decimals);
    }

    function _transfer(address, address, uint256) internal override pure {
        require(false, "Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override pure {
        require(false, "Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
    public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = - 1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
        lastClaimTime.add(claimWait) :
        0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
        nextClaimTime.sub(block.timestamp) :
        0;
    }

    function getAccountAtIndex(uint256 index)
    public view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, - 1, - 1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../pancakeswap/IUniswapV2Router.sol";
import "../pancakeswap/IUniswapV2Factory.sol";
import "./DividendTracker.sol";
import "./Constructors.sol";
import "./AntiWhaleHelper.sol";

pragma experimental ABIEncoderV2;

contract GenericCoin is ERC20, Ownable, Manageable {
    using SafeMath for uint256;

    address public DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    address _payableAddress;

    bool swapping = false;
    mapping(address => bool) public _workingAddresses;
    mapping(address => bool) public _isExcludedFromFees;


    address public _pancakeSwapRouterAddress = DEAD_WALLET;
    address public _pancakeSwapLiquidityPairAddress = DEAD_WALLET;

    uint256 _minimumAmountForSwap = 2000000e18;
    uint256 _gasForProcessing = 300000;

    bool public _isRewardOptionEnabled = false;
    uint256 public _bnbRewardsFee = 0;
    bool public _isAddLiquidityOptionEnabled = false;
    uint256 public _liquidityFee = 0;
    bool public _isMarketingFeesOptionEnabled = false;
    uint256 public _marketingFee = 0;
    address public _marketingAddress = DEAD_WALLET;
    bool public _isBurnOptionEnabled = false;
    uint256 public _burnFee = 0;
    uint256 public _totalFees = 0;

    uint256 _vipListEthPrice;
    uint256 _goldListEthPrice;
    uint256 _whiteListEthPrice;

    IUniswapV2Router02 _pancakeSwapRouter;
    DividendTracker public _dividendTracker;
    AntiWhaleHelper _antiWhaleHelper;

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event AddToWhiteList(address indexed addedAddress, address indexed responsibleAdmin);
    event AddToGoldList(address indexed addedAddress, address indexed responsibleAdmin);
    event AddToVipList(address indexed addedAddress, address indexed responsibleAdmin);
    event RemoveFromWhiteList(address indexed removedAddress, address indexed responsibleAdmin);
    event RemoveFromGoldList(address indexed removedAddress, address indexed responsibleAdmin);
    event RemoveFromVipList(address indexed removedAddress, address indexed responsibleAdmin);

    receive() external payable {
        payable(_payableAddress).transfer(msg.value);
    }

    constructor(
        Constructors.CoinInitializer memory initializer,
        Constructors.FeeParams memory feeParams,
        Constructors.AntiWhaleParams memory antiWhaleParams
    ) ERC20(
        initializer.name,
        initializer.symbol
    ) {

        _isRewardOptionEnabled = feeParams.isRewardOptionEnabled;
        _bnbRewardsFee = feeParams.bnbRewardsFee;

        _isAddLiquidityOptionEnabled = feeParams.isAddLiquidityOptionEnabled;
        _liquidityFee = feeParams.liquidityFee;

        _isMarketingFeesOptionEnabled = feeParams.isMarketingFeesOptionEnabled;
        _marketingFee = feeParams.marketingFee;
        _marketingAddress = feeParams.marketingAddress;

        _isBurnOptionEnabled = feeParams.isBurnOptionEnabled;
        _burnFee = feeParams.burnFee;

        _totalFees = _bnbRewardsFee.add(_liquidityFee).add(_marketingFee).add(_burnFee);

        _pancakeSwapRouter = IUniswapV2Router02(initializer.routerAddress);
        _pancakeSwapRouterAddress = initializer.routerAddress;

        _pancakeSwapLiquidityPairAddress = IUniswapV2Factory(_pancakeSwapRouter.factory()).createPair(address(this), _pancakeSwapRouter.WETH());

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[DEAD_WALLET] = true;
        _isExcludedFromFees[address(0)] = true;
        _isExcludedFromFees[address(this)] = true;

        if (_isRewardOptionEnabled) {
            _dividendTracker = new DividendTracker(initializer.decimals, feeParams.claimWaitInSec, feeParams.humanReadableRewardMinAmount);
            _dividendTracker.excludeFromDividends(address(0));
            _dividendTracker.excludeFromDividends(address(this));
            _dividendTracker.excludeFromDividends(address(owner()));
            _dividendTracker.excludeFromDividends(address(DEAD_WALLET));
            _dividendTracker.excludeFromDividends(address(_dividendTracker));
            _dividendTracker.excludeFromDividends(address(_pancakeSwapRouter));
            _dividendTracker.excludeFromDividends(_pancakeSwapLiquidityPairAddress);
        }

        _antiWhaleHelper = new AntiWhaleHelper(
            address(this),
            initializer.decimals,
            owner(),
            _pancakeSwapLiquidityPairAddress,
            antiWhaleParams
        );

        _vipListEthPrice = antiWhaleParams.vipListEthPrice;
        _goldListEthPrice = antiWhaleParams.goldListEthPrice;
        _whiteListEthPrice = antiWhaleParams.whiteListEthPrice;

        _payableAddress = initializer.payableAddress;

        _mint(owner(), initializer.humanReadableInitialSupply * (10 ** initializer.decimals));
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _antiWhaleHelper.removeFromVipList(owner());
        super.transferOwnership(newOwner);
        _antiWhaleHelper.addToVipList(newOwner);
    }

    function addMeInVipList() external payable {
        require(msg.value >= _vipListEthPrice, "Becoming VIP is not that cheap");
        payable(_payableAddress).transfer(msg.value);
        _addToVipList(msg.sender);
    }

    function addMeInGoldListList() external payable {
        require(msg.value >= _goldListEthPrice, "Becoming gold member is not that cheap");
        payable(_payableAddress).transfer(msg.value);
        _addToGoldList(msg.sender);
    }

    function addMeInWhiteList() external payable {
        require(msg.value >= _whiteListEthPrice, "Entering the whitelist is not that cheap");
        payable(_payableAddress).transfer(msg.value);
        _addToWhitelist(msg.sender);
    }

    function burn(uint256 amount) public {
        require(balanceOf(msg.sender) > amount, "Cannot burn what you don't have");
        require(amount > 0, "Cannot burn nothing");
        if (_isRewardOptionEnabled) {
            _dividendTracker.burn(msg.sender, amount);
        }
        _burn(msg.sender, amount);
    }

    function addToVipList(address vipAddress) external onlyAdmin {
        _addToVipList(vipAddress);
    }

    function addToGoldList(address goldAddress) external onlyAdmin {
        _addToGoldList(goldAddress);
    }

    function addToWhitelist(address whiteListAddress) external onlyAdmin {
        _addToWhitelist(whiteListAddress);
    }

    function _addToVipList(address vipAddress) private {
        _antiWhaleHelper.addToVipList(vipAddress);
        emit AddToVipList(vipAddress, msg.sender);
    }

    function _addToGoldList(address goldAddress) private {
        _antiWhaleHelper.addToGoldList(goldAddress);
        emit AddToGoldList(goldAddress, msg.sender);
    }

    function _addToWhitelist(address whiteListAddress) private {
        _antiWhaleHelper.addToWhitelist(whiteListAddress);
        emit AddToWhiteList(whiteListAddress, msg.sender);
    }

    function removeFromGoldList(address goldAddress) public onlyAdmin {
        _antiWhaleHelper.removeFromGoldList(goldAddress);
        emit RemoveFromGoldList(goldAddress, msg.sender);
    }

    function removeFromWhitelist(address whiteListAddress) public onlyAdmin {
        _antiWhaleHelper.removeFromWhitelist(whiteListAddress);
        emit RemoveFromWhiteList(whiteListAddress, msg.sender);
    }

    function removeFromVipList(address vipAddress) public onlyAdmin {
        _antiWhaleHelper.removeFromVipList(vipAddress);
        emit RemoveFromVipList(vipAddress, msg.sender);
    }

    function setWorkingAddress(address workingAddress) public onlyAdmin {
        require(_workingAddresses[workingAddress] != true, "CWF: Working Address is already set");
        _workingAddresses[workingAddress] = true;
        _isExcludedFromFees[workingAddress] = true;
        if (_isRewardOptionEnabled) {
            _dividendTracker.excludeFromDividends(workingAddress);
        }
    }

    function checkIfAddressesCanSwap(address from, address to) view internal returns (bool){
        return from != owner() && to != owner() && !_workingAddresses[from] && !_workingAddresses[to];
    }

    function withdrawableDividendOf(address account) public view returns (uint256) {
        if (_isRewardOptionEnabled) {
            return _dividendTracker.withdrawableDividendOf(account);
        }
        return 0;
    }

    function claim() external {
        if (_isRewardOptionEnabled) {
            _dividendTracker.processAccount(msg.sender, false);
        }
    }

    function handleSwaps() internal {
        if (shallTakeFee() && canSwap() && !swapping) {
            swapping = true;

            uint256 effectiveBalance = balanceOf(address(this));

            swapAndSendToMarketingAddressFrom(effectiveBalance);

            swapAndLiquifyFrom(effectiveBalance);

            swapAndSendToRewardAddressFrom(effectiveBalance);

            uint256 burnableAmount = computeBurnAmountFrom(effectiveBalance);
            if (burnableAmount > 0) {
                _burn(address(this), burnableAmount);
            }

            swapping = false;
        }
    }

    /*
        function isMaxWalletSizeOptionEnabled() external view returns (bool){
            return _antiWhaleHelper.isMaxWalletSizeOptionEnabled();
        }

        function getMaxWalletSize() external view returns (uint256){
            return _antiWhaleHelper.getMaxWalletSize();
        }

        function isMaxSellTransactionAmountOptionEnabled() external view returns (bool){
            return _antiWhaleHelper.isMaxSellTransactionAmountOptionEnabled();
        }

        function maxSellTransactionAmount() external view returns (uint256){
            return _antiWhaleHelper.getMaxSellTransactionAmount();
        }

        function isWhaleMaxSellTransactionAmountOptionEnabled() external view returns (bool){
            return _antiWhaleHelper.isWhaleMaxSellTransactionAmountOptionEnabled();
        }

        function whalePercentageThreshold() external view returns (uint256){
            return _antiWhaleHelper.getWhalePercentageThreshold();
        }

        function whaleMaxSellTransactionAmount() external view returns (uint256){
            return _antiWhaleHelper.getWhaleMaxSellTransactionAmount();
        }
        */

    function isVip(address wallet) public view returns (bool){
        return _antiWhaleHelper.isInVipList(wallet);
    }

    function isGold(address wallet) public view returns (bool){
        return _antiWhaleHelper.isInGoldList(wallet);
    }

    function isInWhitelist(address wallet) public view returns (bool){
        return _antiWhaleHelper.isInWhiteList(wallet);
    }

    function isWhale(address wallet) public view returns (bool){
        return _antiWhaleHelper.isWhale(wallet);
    }

    function isTransactionAllowed(address from, address to, uint256 amount) public view returns (bool){
        return _antiWhaleHelper.isTransactionAllowed(from, to, amount);
    }

    function isBuyTransactionAllowed(address buyerAddress, uint256 amount) public view returns (bool){
        return _antiWhaleHelper.isBuyTransactionAllowed(buyerAddress, amount);
    }

    function isSellTransactionAllowed(address sellerAddress, uint256 amount) public view returns (bool){
        return _antiWhaleHelper.isSellTransactionAllowed(sellerAddress, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(_antiWhaleHelper.isTransactionAllowed(from, to, amount), "Transfer not permitted");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        //not onBuy and not special addresses
        if (!isBuyingFromLp(from) && checkIfAddressesCanSwap(from, to)) {
            handleSwaps();
        }

        bool shallTakeFee = shallTakeFee() && !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to];

        if (shallTakeFee) {
            uint256 fees = amount.mul(_totalFees).div(100);
            //1% fee when selling
            if (isSellingToLp(to)) {
//                uint256 flatSellFeePerThousand = 10;
//                uint256 whaleSellFeePerThousand = _antiWhaleHelper.getSellFeePerThousand(from);
//                uint256 totalSellFeePerThousand = flatSellFeePerThousand.add(whaleSellFeePerThousand);
                uint256 totalSellFeePerThousand = _antiWhaleHelper.getSellFeePerThousand(from).add(10);
                fees += amount.mul(totalSellFeePerThousand).div(1000);
            }
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try _dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try _dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = _gasForProcessing;

            try _dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {

            }
        }
    }

    function canSwap() view internal returns (bool){
        return balanceOf(address(this)) >= _minimumAmountForSwap;
    }

    function shallTakeFee() view internal returns (bool){
        return _isRewardOptionEnabled || _isAddLiquidityOptionEnabled || _isMarketingFeesOptionEnabled || _isBurnOptionEnabled;
    }

    function isBuyingFromLp(address from) view internal returns (bool){
        return from == _pancakeSwapLiquidityPairAddress;
    }

    function isSellingToLp(address to) view internal returns (bool){
        return to == _pancakeSwapLiquidityPairAddress;
    }

    //_isMarketingFeesOptionEnabled
    function swapAndSendToMarketingAddressFrom(uint256 effectiveBalance) internal {
        if (!_isMarketingFeesOptionEnabled) {
            return;
        }

        uint256 tokenAmount = effectiveBalance.mul(_marketingFee).div(_totalFees);
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 marketingBnb = (address(this).balance).sub(initialBNBBalance);
        payable(_marketingAddress).transfer(marketingBnb);
    }

    //_isAddLiquidityOptionEnabled
    function swapAndLiquifyFrom(uint256 effectiveBalance) internal {
        if (!_isAddLiquidityOptionEnabled) {
            return;
        }

        uint256 tokenAmount = effectiveBalance.mul(_liquidityFee).div(_totalFees);
        uint256 half = tokenAmount.div(2);
        uint256 otherHalf = tokenAmount.sub(half);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 liquidityBnb = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, liquidityBnb);
    }

    //_isBurnOptionEnabled
    function computeBurnAmountFrom(uint256 effectiveBalance) view internal returns (uint256){
        if (!_isBurnOptionEnabled) {
            return 0;
        }
        return effectiveBalance.mul(_burnFee).div(_totalFees);
    }

    //_isRewardOptionEnabled
    function swapAndSendToRewardAddressFrom(uint256 effectiveBalance) internal {
        if (!_isRewardOptionEnabled) {
            return;
        }

        uint256 tokenAmount = effectiveBalance.mul(_bnbRewardsFee).div(_totalFees);
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 rewardBnb = (address(this).balance).sub(initialBNBBalance);
        (bool success,) = address(_dividendTracker).call{value : rewardBnb}("");

        if (success) {
            emit SendDividends(tokenAmount, rewardBnb);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_pancakeSwapRouter), tokenAmount);
        // add the liquidity
        _pancakeSwapRouter.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );

    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeSwapRouter.WETH();

        _approve(address(this), address(_pancakeSwapRouter), tokenAmount);
        // make the swap
        _pancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity >=0.6.2;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != - 1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? - a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract Manageable is Context {
    using SafeMath for uint256;

    mapping(address => bool) private _admins;

    event AdministratorAdded(address indexed addedAdminAddress, address indexed responsibleAdmin);
    event AdministratorRemoved(address indexed removedAdminAddress, address indexed responsibleAdmin);

    /**
     * @dev Initializes the contract setting the deployer as an administrator.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _admins[msgSender] = true;
        emit AdministratorAdded(msgSender, address(0));
    }

    /**
     * @dev Returns a boolean indicating if the requested address is an admin one
     */
    function isAdmin(address requestedAddress) public view virtual returns (bool) {
        return _admins[requestedAddress];
    }

    /**
     * @dev Throws if called by any account that is not an admin one.
     */
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Manageable: caller is not an admin");
        _;
    }

    /**
     * @dev Removes the requestedAddress from the admin list
     */
    function removeAdministrator(address requestedAddress) public virtual onlyAdmin {
        if(isAdmin(requestedAddress)){
            _admins[requestedAddress] = false;
            emit AdministratorRemoved(requestedAddress, _msgSender());
        }
    }

    /**
     * @dev Adds the requestedAddress to the admin list
     */
    function addAdministrator(address requestedAddress) public virtual onlyAdmin {
        if(!isAdmin(requestedAddress)){
            _admins[requestedAddress] = true;
            emit AdministratorAdded(requestedAddress, _msgSender());
        }
    }
}