/**
 *Submitted for verification at polygonscan.com on 2021-12-01
*/

pragma solidity =0.7.6;


// SPDX-License-Identifier: MIT
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

/// This contract is a derivative work of the open-source work of Oasis DEX: https://github.com/OasisDEX/oasis
/// @title RubiconMarket.sol
/// @notice Please see the repository for this code at https://github.com/RubiconDeFi/rubicon_protocol;
/// @notice DSAuth events for authentication schema
contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

/// @notice DSAuth library for setting owner of the contract
/// @dev Provides the auth modifier for authenticated function calls
contract DSAuth is DSAuthEvents {
    address public owner;

    function setOwner(address owner_) external auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    modifier auth {
        require(isAuthorized(msg.sender), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else {
            return false;
        }
    }
}

/// @notice DSMath library for safe math without integer overflow/underflow
contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}

// /// @notice ERC-20 interface as derived from EIP-20
// contract ERC20 {
//     function totalSupply() public view returns (uint256);
//     function balanceOf(address guy) public view returns (uint256);
//     function allowance(address src, address guy) public view returns (uint256);
//     function approve(address guy, uint256 wad) public returns (bool);
//     function transfer(address dst, uint256 wad) public returns (bool);
//     function transferFrom(
//         address src,
//         address dst,
//         uint256 wad
//     ) public returns (bool);
// }
/// @notice Events contract for logging trade activity on Rubicon Market
/// @dev Provides the key event logs that are used in all core functionality of exchanging on the Rubicon Market
contract EventfulMarket {
    event LogItemUpdate(uint256 id);
    event LogTrade(
        uint256 pay_amt,
        address indexed pay_gem,
        uint256 buy_amt,
        address indexed buy_gem
    );

    event LogMake(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        ERC20 pay_gem,
        ERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt,
        uint64 timestamp
    );

    event LogBump(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        ERC20 pay_gem,
        ERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt,
        uint64 timestamp
    );

    event LogTake(
        bytes32 id,
        bytes32 indexed pair,
        address indexed maker,
        ERC20 pay_gem,
        ERC20 buy_gem,
        address indexed taker,
        uint128 take_amt,
        uint128 give_amt,
        uint64 timestamp
    );

    event LogKill(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        ERC20 pay_gem,
        ERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt,
        uint64 timestamp
    );

    event LogInt(string lol, uint256 input);

    event FeeTake(
        bytes32 id,
        bytes32 indexed pair,
        ERC20 asset,
        address indexed taker,
        address feeTo,
        uint256 feeAmt,
        uint64 timestamp
    );

    event OfferDeleted(uint256 id);
}

/// @notice Core trading logic for ERC-20 pairs, an orderbook, and transacting of tokens
/// @dev This contract holds the core ERC-20 / ERC-20 offer, buy, and cancel logic
contract SimpleMarket is EventfulMarket, DSMath {
    uint256 public last_offer_id;

    /// @dev The mapping that makes up the core orderbook of the exchange
    mapping(uint256 => OfferInfo) public offers;

    bool locked;

    /// @dev This parameter is in basis points
    uint256 internal feeBPS;

    /// @dev This parameter provides the address to which fees are sent
    address internal feeTo;

    struct OfferInfo {
        uint256 pay_amt;
        ERC20 pay_gem;
        uint256 buy_amt;
        ERC20 buy_gem;
        address owner;
        uint64 timestamp;
    }

    /// @notice Modifier that insures an order exists and is properly in the orderbook
    modifier can_buy(uint256 id) virtual {
        require(isActive(id));
        _;
    }

    /// @notice Modifier that checks the user to make sure they own the offer and its valid before they attempt to cancel it
    modifier can_cancel(uint256 id) virtual {
        require(isActive(id));
        require(getOwner(id) == msg.sender);
        _;
    }

    modifier can_offer virtual {
        _;
    }

    modifier synchronized {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function isActive(uint256 id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function getOwner(uint256 id) public view returns (address owner) {
        return offers[id].owner;
    }

    function getOffer(uint256 id)
        public
        view
        returns (
            uint256,
            ERC20,
            uint256,
            ERC20
        )
    {
        OfferInfo memory _offer = offers[id];
        return (_offer.pay_amt, _offer.pay_gem, _offer.buy_amt, _offer.buy_gem);
    }

    /// @notice Below are the main public entrypoints

    function bump(bytes32 id_) external can_buy(uint256(id_)) {
        uint256 id = uint256(id_);
        emit LogBump(
            id_,
            keccak256(abi.encodePacked(offers[id].pay_gem, offers[id].buy_gem)),
            offers[id].owner,
            offers[id].pay_gem,
            offers[id].buy_gem,
            uint128(offers[id].pay_amt),
            uint128(offers[id].buy_amt),
            offers[id].timestamp
        );
    }

    /// @notice Accept a given `quantity` of an offer. Transfers funds from caller/taker to offer maker, and from market to caller/taker.
    /// @notice The fee for taker trades is paid in this function.
    function buy(uint256 id, uint256 quantity)
        public
        virtual
        can_buy(id)
        synchronized
        returns (bool)
    {
        OfferInfo memory _offer = offers[id];
        uint256 spend = mul(quantity, _offer.buy_amt) / _offer.pay_amt;

        require(uint128(spend) == spend, "spend is not an int");
        require(uint128(quantity) == quantity, "quantity is not an int");

        ///@dev For backwards semantic compatibility.
        if (
            quantity == 0 ||
            spend == 0 ||
            quantity > _offer.pay_amt ||
            spend > _offer.buy_amt
        ) {
            return false;
        }

        uint256 fee = mul(spend, feeBPS) / 10000;
        require(
            _offer.buy_gem.transferFrom(msg.sender, feeTo, fee),
            "Insufficient funds to cover fee"
        );

        offers[id].pay_amt = sub(_offer.pay_amt, quantity);
        offers[id].buy_amt = sub(_offer.buy_amt, spend);
        require(
            _offer.buy_gem.transferFrom(msg.sender, _offer.owner, spend),
            "_offer.buy_gem.transferFrom(msg.sender, _offer.owner, spend) failed - check that you can pay the fee"
        );
        require(
            _offer.pay_gem.transfer(msg.sender, quantity),
            "_offer.pay_gem.transfer(msg.sender, quantity) failed"
        );

        emit LogItemUpdate(id);
        emit LogTake(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner,
            _offer.pay_gem,
            _offer.buy_gem,
            msg.sender,
            uint128(quantity),
            uint128(spend),
            uint64(block.timestamp)
        );
        emit FeeTake(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.buy_gem,
            msg.sender,
            feeTo,
            fee,
            uint64(block.timestamp)
        );
        emit LogTrade(
            quantity,
            address(_offer.pay_gem),
            spend,
            address(_offer.buy_gem)
        );

        if (offers[id].pay_amt == 0) {
            delete offers[id];
            emit OfferDeleted(id);
        }

        return true;
    }

    /// @notice Allows the caller to cancel the offer if it is their own.
    /// @notice This function refunds the offer to the maker.
    function cancel(uint256 id)
        public
        virtual
        can_cancel(id)
        synchronized
        returns (bool success)
    {
        OfferInfo memory _offer = offers[id];
        delete offers[id];

        require(_offer.pay_gem.transfer(_offer.owner, _offer.pay_amt));

        emit LogItemUpdate(id);
        emit LogKill(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner,
            _offer.pay_gem,
            _offer.buy_gem,
            uint128(_offer.pay_amt),
            uint128(_offer.buy_amt),
            uint64(block.timestamp)
        );

        success = true;
    }

    function kill(bytes32 id) external virtual {
        require(cancel(uint256(id)));
    }

    function make(
        ERC20 pay_gem,
        ERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt
    ) external virtual returns (bytes32 id) {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    /// @notice Key function to make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint256 pay_amt,
        ERC20 pay_gem,
        uint256 buy_amt,
        ERC20 buy_gem
    ) public virtual can_offer synchronized returns (uint256 id) {
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(pay_gem != ERC20(0x0));
        require(buy_amt > 0);
        require(buy_gem != ERC20(0x0));
        require(pay_gem != buy_gem);

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.owner = msg.sender;
        info.timestamp = uint64(block.timestamp);
        id = _next_id();
        offers[id] = info;

        require(pay_gem.transferFrom(msg.sender, address(this), pay_amt));

        emit LogItemUpdate(id);
        emit LogMake(
            bytes32(id),
            keccak256(abi.encodePacked(pay_gem, buy_gem)),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt),
            uint64(block.timestamp)
        );
    }

    function take(bytes32 id, uint128 maxTakeAmount) external virtual {
        require(buy(uint256(id), maxTakeAmount));
    }

    function _next_id() internal returns (uint256) {
        last_offer_id++;
        return last_offer_id;
    }

    // Fee logic
    function getFeeBPS() internal view returns (uint256) {
        return feeBPS;
    }
}

/// @notice Expiring market is a Simple Market with a market lifetime.
/// @dev When the close_time has been reached, offers can only be cancelled (offer and buy will throw).
contract ExpiringMarket is DSAuth, SimpleMarket {
    bool public stopped;

    /// @dev After close_time has been reached, no new offers are allowed.
    modifier can_offer override {
        require(!isClosed());
        _;
    }

    /// @dev After close, no new buys are allowed.
    modifier can_buy(uint256 id) override {
        require(isActive(id));
        require(!isClosed());
        _;
    }

    /// @dev After close, anyone can cancel an offer.
    modifier can_cancel(uint256 id) virtual override {
        require(isActive(id));
        require((msg.sender == getOwner(id)) || isClosed());
        _;
    }

    function isClosed() public pure returns (bool closed) {
        return false;
    }

    function getTime() public view returns (uint64) {
        return uint64(block.timestamp);
    }

    function stop() external auth {
        stopped = true;
    }
}

contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}

contract MatchingEvents {
    event LogBuyEnabled(bool isEnabled);
    event LogMinSell(address pay_gem, uint256 min_amount);
    event LogMatchingEnabled(bool isEnabled);
    event LogUnsortedOffer(uint256 id);
    event LogSortedOffer(uint256 id);
    event LogInsert(address keeper, uint256 id);
    event LogDelete(address keeper, uint256 id);
    event LogMatch(uint256 id, uint256 amount);
}

/// @notice The core Rubicon Market smart contract
/// @notice This contract is based on the original open-source work done by OasisDEX under the Apache License 2.0
/// @dev This contract inherits the key trading functionality from SimpleMarket
contract RubiconMarket is MatchingEvents, ExpiringMarket, DSNote {
    bool public buyEnabled = true; //buy enabled
    bool public matchingEnabled = true; //true: enable matching,
    //false: revert to expiring market
    /// @dev Below is variable to allow for a proxy-friendly constructor
    bool public initialized;

    bool public AqueductDistributionLive;
    address public AqueductAddress;

    struct sortInfo {
        uint256 next; //points to id of next higher offer
        uint256 prev; //points to id of previous lower offer
        uint256 delb; //the blocknumber where this entry was marked for delete
    }
    mapping(uint256 => sortInfo) public _rank; //doubly linked lists of sorted offer ids
    mapping(address => mapping(address => uint256)) public _best; //id of the highest offer for a token pair
    mapping(address => mapping(address => uint256)) public _span; //number of offers stored for token pair in sorted orderbook
    mapping(address => uint256) public _dust; //minimum sell amount for a token to avoid dust offers
    mapping(uint256 => uint256) public _near; //next unsorted offer id
    uint256 public _head; //first unsorted offer id
    uint256 public dustId; // id of the latest offer marked as dust

    /// @dev Proxy-safe initialization of storage
    function initialize(bool _live, address _feeTo) public {
        // require(msg.sender == ___deployer____);
        require(!initialized, "contract is already initialized");
        AqueductDistributionLive = _live;
        feeTo = _feeTo;

        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        /// @notice The starting fee on taker trades in basis points
        feeBPS = 20;
        initialized = true;
        matchingEnabled = true;
        buyEnabled = true;
    }

    // After close, anyone can cancel an offer
    modifier can_cancel(uint256 id) override {
        require(isActive(id), "Offer was deleted or taken, or never existed.");
        require(
            isClosed() || msg.sender == getOwner(id) || id == dustId,
            "Offer can not be cancelled because user is not owner, and market is open, and offer sells required amount of tokens."
        );
        _;
    }

    // ---- Public entrypoints ---- //

    function make(
        ERC20 pay_gem,
        ERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt
    ) public override returns (bytes32) {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    function take(bytes32 id, uint128 maxTakeAmount) public override {
        require(buy(uint256(id), maxTakeAmount));
    }

    function kill(bytes32 id) external override {
        require(cancel(uint256(id)));
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    //
    // If matching is enabled:
    //     * creates new offer without putting it in
    //       the sorted list.
    //     * available to authorized contracts only!
    //     * keepers should call insert(id,pos)
    //       to put offer in the sorted list.
    //
    // If matching is disabled:
    //     * calls expiring market's offer().
    //     * available to everyone without authorization.
    //     * no sorting is done.
    //
    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        ERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //taker (ask) buy how much
        ERC20 buy_gem //taker (ask) buy which token
    ) public override returns (uint256) {
        require(!locked, "Reentrancy attempt");


            function(uint256, ERC20, uint256, ERC20) returns (uint256) fn
         = matchingEnabled ? _offeru : super.offer;
        return fn(pay_amt, pay_gem, buy_amt, buy_gem);
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        ERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        ERC20 buy_gem, //maker (ask) buy which token
        uint256 pos //position to insert offer, 0 should be used if unknown
    ) external can_offer returns (uint256) {
        return offer(pay_amt, pay_gem, buy_amt, buy_gem, pos, true);
    }

    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        ERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        ERC20 buy_gem, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        bool matching //match "close enough" orders?
    ) public can_offer returns (uint256) {
        require(!locked, "Reentrancy attempt");
        require(_dust[address(pay_gem)] <= pay_amt);

        if (matchingEnabled) {
            return _matcho(pay_amt, pay_gem, buy_amt, buy_gem, pos, matching);
        }
        return super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
    }

    //Transfers funds from caller to offer maker, and from market to caller.
    function buy(uint256 id, uint256 amount)
        public
        override
        can_buy(id)
        returns (bool)
    {
        require(!locked, "Reentrancy attempt");

        //Optional distribution on trade
        if (AqueductDistributionLive) {
            IAqueduct(AqueductAddress).distributeToMakerAndTaker(
                getOwner(id),
                msg.sender
            );
        }
        function(uint256, uint256) returns (bool) fn = matchingEnabled
            ? _buys
            : super.buy;

        return fn(id, amount);
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(uint256 id)
        public
        override
        can_cancel(id)
        returns (bool success)
    {
        require(!locked, "Reentrancy attempt");
        if (matchingEnabled) {
            if (isOfferSorted(id)) {
                require(_unsort(id));
            } else {
                require(_hide(id));
            }
        }
        return super.cancel(id); //delete the offer.
    }

    //insert offer into the sorted list
    //keepers need to use this function
    function insert(
        uint256 id, //maker (ask) id
        uint256 pos //position to insert into
    ) public returns (bool) {
        require(!locked, "Reentrancy attempt");
        require(!isOfferSorted(id)); //make sure offers[id] is not yet sorted
        require(isActive(id)); //make sure offers[id] is active

        _hide(id); //remove offer from unsorted offers list
        _sort(id, pos); //put offer into the sorted offers list
        emit LogInsert(msg.sender, id);
        return true;
    }

    //deletes _rank [id]
    //  Function should be called by keepers.
    function del_rank(uint256 id) external returns (bool) {
        require(!locked, "Reentrancy attempt");
        require(
            !isActive(id) &&
                _rank[id].delb != 0 &&
                _rank[id].delb < block.number - 10
        );
        delete _rank[id];
        emit LogDelete(msg.sender, id);
        return true;
    }

    //set the minimum sell amount for a token
    //    Function is used to avoid "dust offers" that have
    //    very small amount of tokens to sell, and it would
    //    cost more gas to accept the offer, than the value
    //    of tokens received.
    function setMinSell(
        ERC20 pay_gem, //token to assign minimum sell amount to
        uint256 dust //maker (ask) minimum sell amount
    ) external auth note returns (bool) {
        _dust[address(pay_gem)] = dust;
        emit LogMinSell(address(pay_gem), dust);
        return true;
    }

    //returns the minimum sell amount for an offer
    function getMinSell(
        ERC20 pay_gem //token for which minimum sell amount is queried
    ) external view returns (uint256) {
        return _dust[address(pay_gem)];
    }

    //set buy functionality enabled/disabled
    function setBuyEnabled(bool buyEnabled_) external auth returns (bool) {
        buyEnabled = buyEnabled_;
        emit LogBuyEnabled(buyEnabled);
        return true;
    }

    //set matching enabled/disabled
    //    If matchingEnabled true(default), then inserted offers are matched.
    //    Except the ones inserted by contracts, because those end up
    //    in the unsorted list of offers, that must be later sorted by
    //    keepers using insert().
    //    If matchingEnabled is false then RubiconMarket is reverted to ExpiringMarket,
    //    and matching is not done, and sorted lists are disabled.
    function setMatchingEnabled(bool matchingEnabled_)
        external
        auth
        returns (bool)
    {
        matchingEnabled = matchingEnabled_;
        emit LogMatchingEnabled(matchingEnabled);
        return true;
    }

    //return the best offer for a token pair
    //      the best offer is the lowest one if it's an ask,
    //      and highest one if it's a bid offer
    function getBestOffer(ERC20 sell_gem, ERC20 buy_gem)
        public
        view
        returns (uint256)
    {
        return _best[address(sell_gem)][address(buy_gem)];
    }

    //return the next worse offer in the sorted list
    //      the worse offer is the higher one if its an ask,
    //      a lower one if its a bid offer,
    //      and in both cases the newer one if they're equal.
    function getWorseOffer(uint256 id) public view returns (uint256) {
        return _rank[id].prev;
    }

    //return the next better offer in the sorted list
    //      the better offer is in the lower priced one if its an ask,
    //      the next higher priced one if its a bid offer
    //      and in both cases the older one if they're equal.
    function getBetterOffer(uint256 id) external view returns (uint256) {
        return _rank[id].next;
    }

    //return the amount of better offers for a token pair
    function getOfferCount(ERC20 sell_gem, ERC20 buy_gem)
        public
        view
        returns (uint256)
    {
        return _span[address(sell_gem)][address(buy_gem)];
    }

    //get the first unsorted offer that was inserted by a contract
    //      Contracts can't calculate the insertion position of their offer because it is not an O(1) operation.
    //      Their offers get put in the unsorted list of offers.
    //      Keepers can calculate the insertion position offchain and pass it to the insert() function to insert
    //      the unsorted offer into the sorted list. Unsorted offers will not be matched, but can be bought with buy().
    function getFirstUnsortedOffer() public view returns (uint256) {
        return _head;
    }

    //get the next unsorted offer
    //      Can be used to cycle through all the unsorted offers.
    function getNextUnsortedOffer(uint256 id) public view returns (uint256) {
        return _near[id];
    }

    function isOfferSorted(uint256 id) public view returns (bool) {
        return
            _rank[id].next != 0 ||
            _rank[id].prev != 0 ||
            _best[address(offers[id].pay_gem)][address(offers[id].buy_gem)] ==
            id;
    }

    function sellAllAmount(
        ERC20 pay_gem,
        uint256 pay_amt,
        ERC20 buy_gem,
        uint256 min_fill_amount
    ) external returns (uint256 fill_amt) {
        require(!locked, "Reentrancy attempt");
        uint256 offerId;
        while (pay_amt > 0) {
            //while there is amount to sell
            offerId = getBestOffer(buy_gem, pay_gem); //Get the best offer for the token pair
            require(offerId != 0); //Fails if there are not more offers

            // There is a chance that pay_amt is smaller than 1 wei of the other token
            if (
                pay_amt * 1 ether <
                wdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
            ) {
                break; //We consider that all amount is sold
            }
            if (pay_amt >= offers[offerId].buy_amt) {
                //If amount to sell is higher or equal than current offer amount to buy
                fill_amt = add(fill_amt, offers[offerId].pay_amt); //Add amount bought to acumulator
                pay_amt = sub(pay_amt, offers[offerId].buy_amt); //Decrease amount to sell
                take(bytes32(offerId), uint128(offers[offerId].pay_amt)); //We take the whole offer
            } else {
                // if lower
                uint256 baux = rmul(
                    pay_amt * 10**9,
                    rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
                ) / 10**9;
                fill_amt = add(fill_amt, baux); //Add amount bought to acumulator
                take(bytes32(offerId), uint128(baux)); //We take the portion of the offer that we need
                pay_amt = 0; //All amount is sold
            }
        }
        require(fill_amt >= min_fill_amount);
    }

    function buyAllAmount(
        ERC20 buy_gem,
        uint256 buy_amt,
        ERC20 pay_gem,
        uint256 max_fill_amount
    ) external returns (uint256 fill_amt) {
        require(!locked, "Reentrancy attempt");
        uint256 offerId;
        while (buy_amt > 0) {
            //Meanwhile there is amount to buy
            offerId = getBestOffer(buy_gem, pay_gem); //Get the best offer for the token pair
            require(offerId != 0);

            // There is a chance that buy_amt is smaller than 1 wei of the other token
            if (
                buy_amt * 1 ether <
                wdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
            ) {
                break; //We consider that all amount is sold
            }
            if (buy_amt >= offers[offerId].pay_amt) {
                //If amount to buy is higher or equal than current offer amount to sell
                fill_amt = add(fill_amt, offers[offerId].buy_amt); //Add amount sold to acumulator
                buy_amt = sub(buy_amt, offers[offerId].pay_amt); //Decrease amount to buy
                take(bytes32(offerId), uint128(offers[offerId].pay_amt)); //We take the whole offer
            } else {
                //if lower
                fill_amt = add(
                    fill_amt,
                    rmul(
                        buy_amt * 10**9,
                        rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
                    ) / 10**9
                ); //Add amount sold to acumulator
                take(bytes32(offerId), uint128(buy_amt)); //We take the portion of the offer that we need
                buy_amt = 0; //All amount is bought
            }
        }
        require(fill_amt <= max_fill_amount);
    }

    function getBuyAmount(
        ERC20 buy_gem,
        ERC20 pay_gem,
        uint256 pay_amt
    ) external view returns (uint256 fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem); //Get best offer for the token pair
        while (pay_amt > offers[offerId].buy_amt) {
            fill_amt = add(fill_amt, offers[offerId].pay_amt); //Add amount to buy accumulator
            pay_amt = sub(pay_amt, offers[offerId].buy_amt); //Decrease amount to pay
            if (pay_amt > 0) {
                //If we still need more offers
                offerId = getWorseOffer(offerId); //We look for the next best offer
                require(offerId != 0); //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(
            fill_amt,
            rmul(
                pay_amt * 10**9,
                rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
            ) / 10**9
        ); //Add proportional amount of last offer to buy accumulator
    }

    function getPayAmount(
        ERC20 pay_gem,
        ERC20 buy_gem,
        uint256 buy_amt
    ) external view returns (uint256 fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem); //Get best offer for the token pair
        while (buy_amt > offers[offerId].pay_amt) {
            fill_amt = add(fill_amt, offers[offerId].buy_amt); //Add amount to pay accumulator
            buy_amt = sub(buy_amt, offers[offerId].pay_amt); //Decrease amount to buy
            if (buy_amt > 0) {
                //If we still need more offers
                offerId = getWorseOffer(offerId); //We look for the next best offer
                require(offerId != 0); //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(
            fill_amt,
            rmul(
                buy_amt * 10**9,
                rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
            ) / 10**9
        ); //Add proportional amount of last offer to pay accumulator
    }

    // ---- Internal Functions ---- //

    function _buys(uint256 id, uint256 amount) internal returns (bool) {
        require(buyEnabled);
        if (amount == offers[id].pay_amt) {
            if (isOfferSorted(id)) {
                //offers[id] must be removed from sorted list because all of it is bought
                _unsort(id);
            } else {
                _hide(id);
            }
        }

        require(super.buy(id, amount));

        // If offer has become dust during buy, we cancel it
        if (
            isActive(id) &&
            offers[id].pay_amt < _dust[address(offers[id].pay_gem)]
        ) {
            dustId = id; //enable current msg.sender to call cancel(id)
            cancel(id);
        }
        return true;
    }

    //find the id of the next higher offer after offers[id]
    function _find(uint256 id) internal view returns (uint256) {
        require(id > 0);

        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        uint256 top = _best[pay_gem][buy_gem];
        uint256 old_top = 0;

        // Find the larger-than-id order whose successor is less-than-id.
        while (top != 0 && _isPricedLtOrEq(id, top)) {
            old_top = top;
            top = _rank[top].prev;
        }
        return old_top;
    }

    //find the id of the next higher offer after offers[id]
    function _findpos(uint256 id, uint256 pos) internal view returns (uint256) {
        require(id > 0);

        // Look for an active order.
        while (pos != 0 && !isActive(pos)) {
            pos = _rank[pos].prev;
        }

        if (pos == 0) {
            //if we got to the end of list without a single active offer
            return _find(id);
        } else {
            // if we did find a nearby active offer
            // Walk the order book down from there...
            if (_isPricedLtOrEq(id, pos)) {
                uint256 old_pos;

                // Guaranteed to run at least once because of
                // the prior if statements.
                while (pos != 0 && _isPricedLtOrEq(id, pos)) {
                    old_pos = pos;
                    pos = _rank[pos].prev;
                }
                return old_pos;

                // ...or walk it up.
            } else {
                while (pos != 0 && !_isPricedLtOrEq(id, pos)) {
                    pos = _rank[pos].next;
                }
                return pos;
            }
        }
    }

    //return true if offers[low] priced less than or equal to offers[high]
    function _isPricedLtOrEq(
        uint256 low, //lower priced offer's id
        uint256 high //higher priced offer's id
    ) internal view returns (bool) {
        return
            mul(offers[low].buy_amt, offers[high].pay_amt) >=
            mul(offers[high].buy_amt, offers[low].pay_amt);
    }

    //these variables are global only because of solidity local variable limit

    //match offers with taker offer, and execute token transactions
    function _matcho(
        uint256 t_pay_amt, //taker sell how much
        ERC20 t_pay_gem, //taker sell which token
        uint256 t_buy_amt, //taker buy how much
        ERC20 t_buy_gem, //taker buy which token
        uint256 pos, //position id
        bool rounding //match "close enough" orders?
    ) internal returns (uint256 id) {
        uint256 best_maker_id; //highest maker id
        uint256 t_buy_amt_old; //taker buy how much saved
        uint256 m_buy_amt; //maker offer wants to buy this much token
        uint256 m_pay_amt; //maker offer wants to sell this much token

        // there is at least one offer stored for token pair
        while (_best[address(t_buy_gem)][address(t_pay_gem)] > 0) {
            best_maker_id = _best[address(t_buy_gem)][address(t_pay_gem)];
            m_buy_amt = offers[best_maker_id].buy_amt;
            m_pay_amt = offers[best_maker_id].pay_amt;

            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has t_pay_amt and m_pay_amt at +1 away from
            // their "correct" values and m_buy_amt and t_buy_amt at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            if (
                mul(m_buy_amt, t_buy_amt) >
                mul(t_pay_amt, m_pay_amt) +
                    (
                        rounding
                            ? m_buy_amt + t_buy_amt + t_pay_amt + m_pay_amt
                            : 0
                    )
            ) {
                break;
            }
            // ^ The `rounding` parameter is a compromise borne of a couple days
            // of discussion.
            buy(best_maker_id, min(m_pay_amt, t_buy_amt));
            emit LogMatch(id, min(m_pay_amt, t_buy_amt));
            t_buy_amt_old = t_buy_amt;
            t_buy_amt = sub(t_buy_amt, min(m_pay_amt, t_buy_amt));
            t_pay_amt = mul(t_buy_amt, t_pay_amt) / t_buy_amt_old;

            if (t_pay_amt == 0 || t_buy_amt == 0) {
                break;
            }
        }

        if (
            t_buy_amt > 0 &&
            t_pay_amt > 0 &&
            t_pay_amt >= _dust[address(t_pay_gem)]
        ) {
            //new offer should be created
            id = super.offer(t_pay_amt, t_pay_gem, t_buy_amt, t_buy_gem);
            //insert offer into the sorted list
            _sort(id, pos);
        }
    }

    // Make a new offer without putting it in the sorted list.
    // Takes funds from the caller into market escrow.
    // Keepers should call insert(id,pos) to put offer in the sorted list.
    function _offeru(
        uint256 pay_amt, //maker (ask) sell how much
        ERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        ERC20 buy_gem //maker (ask) buy which token
    ) internal returns (uint256 id) {
        require(_dust[address(pay_gem)] <= pay_amt);
        id = super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
        _near[id] = _head;
        _head = id;
        emit LogUnsortedOffer(id);
    }

    //put offer into the sorted list
    function _sort(
        uint256 id, //maker (ask) id
        uint256 pos //position to insert into
    ) internal {
        require(isActive(id));

        ERC20 buy_gem = offers[id].buy_gem;
        ERC20 pay_gem = offers[id].pay_gem;
        uint256 prev_id; //maker (ask) id

        pos = pos == 0 ||
            offers[pos].pay_gem != pay_gem ||
            offers[pos].buy_gem != buy_gem ||
            !isOfferSorted(pos)
            ? _find(id)
            : _findpos(id, pos);

        if (pos != 0) {
            //offers[id] is not the highest offer
            //requirement below is satisfied by statements above
            //require(_isPricedLtOrEq(id, pos));
            prev_id = _rank[pos].prev;
            _rank[pos].prev = id;
            _rank[id].next = pos;
        } else {
            //offers[id] is the highest offer
            prev_id = _best[address(pay_gem)][address(buy_gem)];
            _best[address(pay_gem)][address(buy_gem)] = id;
        }

        if (prev_id != 0) {
            //if lower offer does exist
            //requirement below is satisfied by statements above
            //require(!_isPricedLtOrEq(id, prev_id));
            _rank[prev_id].next = id;
            _rank[id].prev = prev_id;
        }

        _span[address(pay_gem)][address(buy_gem)]++;
        emit LogSortedOffer(id);
    }

    // Remove offer from the sorted list (does not cancel offer)
    function _unsort(
        uint256 id //id of maker (ask) offer to remove from sorted list
    ) internal returns (bool) {
        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        require(_span[pay_gem][buy_gem] > 0);

        require(
            _rank[id].delb == 0 && //assert id is in the sorted list
                isOfferSorted(id)
        );

        if (id != _best[pay_gem][buy_gem]) {
            // offers[id] is not the highest offer
            require(_rank[_rank[id].next].prev == id);
            _rank[_rank[id].next].prev = _rank[id].prev;
        } else {
            //offers[id] is the highest offer
            _best[pay_gem][buy_gem] = _rank[id].prev;
        }

        if (_rank[id].prev != 0) {
            //offers[id] is not the lowest offer
            require(_rank[_rank[id].prev].next == id);
            _rank[_rank[id].prev].next = _rank[id].next;
        }

        _span[pay_gem][buy_gem]--;
        _rank[id].delb = block.number; //mark _rank[id] for deletion
        return true;
    }

    //Hide offer from the unsorted order book (does not cancel offer)
    function _hide(
        uint256 id //id of maker offer to remove from unsorted list
    ) internal returns (bool) {
        uint256 uid = _head; //id of an offer in unsorted offers list
        uint256 pre = uid; //id of previous offer in unsorted offers list

        require(!isOfferSorted(id)); //make sure offer id is not in sorted offers list

        if (_head == id) {
            //check if offer is first offer in unsorted offers list
            _head = _near[id]; //set head to new first unsorted offer
            _near[id] = 0; //delete order from unsorted order list
            return true;
        }
        while (uid > 0 && uid != id) {
            //find offer in unsorted order list
            pre = uid;
            uid = _near[uid];
        }
        if (uid != id) {
            //did not find offer id in unsorted offers list
            return false;
        }
        _near[pre] = _near[id]; //set previous unsorted offer to point to offer after offer id
        _near[id] = 0; //delete order from unsorted order list
        return true;
    }

    function setFeeBPS(uint256 _newFeeBPS) external auth returns (bool) {
        feeBPS = _newFeeBPS;
        return true;
    }

    function setAqueductDistributionLive(bool live)
        external
        auth
        returns (bool)
    {
        AqueductDistributionLive = live;
        return true;
    }

    function setAqueductAddress(address _Aqueduct)
        external
        auth
        returns (bool)
    {
        AqueductAddress = _Aqueduct;
        return true;
    }

    function setFeeTo(address newFeeTo) external auth returns (bool) {
        feeTo = newFeeTo;
        return true;
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);
}

interface IAqueduct {
    function distributeToMakerAndTaker(address maker, address taker)
        external
        returns (bool);
}

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
//<0.6.0-0||>=0.6.0 <0.7.0-0||>=0.7.0 <0.8.0-0;
/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(x <= 0x7FFFFFFFFFFFFFFF);
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0);
        return uint64(x >> 64);
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return int256(x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = (int256(x) * y) >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require(
                y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                    y <= 0x1000000000000000000000000000000000000000000000000
            );
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu(x, uint256(y));
            if (negativeResult) {
                require(
                    absoluteResult <=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                );
                return -int256(absoluteResult); // We rely on overflow behavior here
            } else {
                require(
                    absoluteResult <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
                return int256(absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0);

        uint256 lo = (uint256(x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >>
            64;
        uint256 hi = uint256(x) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require(
            hi <=
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
                    lo
        );
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        require(y != 0);
        int256 result = (int256(x) << 64) / y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        require(y != 0);

        bool negativeResult = false;
        if (x < 0) {
            x = -x; // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y; // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu(uint256(x), uint256(y));
        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000);
            return -int128(absoluteResult); // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128(absoluteResult); // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0);
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64));
        return int128(result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return -x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return x < 0 ? -x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        require(x != 0);
        int256 result = int256(0x100000000000000000000000000000000) / x;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return int128((int256(x) + int256(y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256(x) * int256(y);
        require(m >= 0);
        require(
            m <
                0x4000000000000000000000000000000000000000000000000000000000000000
        );
        return int128(sqrtu(uint256(m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        uint256 absoluteResult;
        bool negativeResult = false;
        if (x >= 0) {
            absoluteResult = powu(uint256(x) << 63, y);
        } else {
            // We rely on overflow behavior here
            absoluteResult = powu(uint256(uint128(-x)) << 63, y);
            negativeResult = y & 1 > 0;
        }

        absoluteResult >>= 63;

        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000);
            return -int128(absoluteResult); // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128(absoluteResult); // We rely on overflow behavior here
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        require(x >= 0);
        return int128(sqrtu(uint256(x) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1; // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(x) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        require(x > 0);

        return
            int128(
                (uint256(log_2(x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
            );
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
        if (x & 0x4000000000000000 > 0)
            result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
        if (x & 0x2000000000000000 > 0)
            result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
        if (x & 0x1000000000000000 > 0)
            result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
        if (x & 0x800000000000000 > 0)
            result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
        if (x & 0x400000000000000 > 0)
            result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
        if (x & 0x200000000000000 > 0)
            result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
        if (x & 0x100000000000000 > 0)
            result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
        if (x & 0x80000000000000 > 0)
            result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
        if (x & 0x40000000000000 > 0)
            result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
        if (x & 0x20000000000000 > 0)
            result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
        if (x & 0x10000000000000 > 0)
            result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
        if (x & 0x8000000000000 > 0)
            result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
        if (x & 0x4000000000000 > 0)
            result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
        if (x & 0x2000000000000 > 0)
            result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
        if (x & 0x1000000000000 > 0)
            result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
        if (x & 0x800000000000 > 0)
            result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
        if (x & 0x400000000000 > 0)
            result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
        if (x & 0x200000000000 > 0)
            result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
        if (x & 0x100000000000 > 0)
            result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
        if (x & 0x80000000000 > 0)
            result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
        if (x & 0x40000000000 > 0)
            result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
        if (x & 0x20000000000 > 0)
            result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
        if (x & 0x10000000000 > 0)
            result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
        if (x & 0x8000000000 > 0)
            result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
        if (x & 0x4000000000 > 0)
            result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
        if (x & 0x2000000000 > 0)
            result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
        if (x & 0x1000000000 > 0)
            result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
        if (x & 0x800000000 > 0)
            result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
        if (x & 0x400000000 > 0)
            result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
        if (x & 0x200000000 > 0)
            result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
        if (x & 0x100000000 > 0)
            result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
        if (x & 0x80000000 > 0)
            result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
        if (x & 0x40000000 > 0)
            result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
        if (x & 0x20000000 > 0)
            result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
        if (x & 0x10000000 > 0)
            result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
        if (x & 0x8000000 > 0)
            result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
        if (x & 0x4000000 > 0)
            result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
        if (x & 0x2000000 > 0)
            result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
        if (x & 0x1000000 > 0)
            result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
        if (x & 0x800000 > 0)
            result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
        if (x & 0x400000 > 0)
            result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
        if (x & 0x200000 > 0)
            result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
        if (x & 0x100000 > 0)
            result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
        if (x & 0x80000 > 0)
            result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
        if (x & 0x40000 > 0)
            result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
        if (x & 0x20000 > 0)
            result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
        if (x & 0x10000 > 0)
            result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
        if (x & 0x8000 > 0)
            result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
        if (x & 0x4000 > 0)
            result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
        if (x & 0x2000 > 0)
            result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
        if (x & 0x1000 > 0)
            result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
        if (x & 0x800 > 0)
            result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
        if (x & 0x400 > 0)
            result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
        if (x & 0x200 > 0)
            result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
        if (x & 0x100 > 0)
            result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
        if (x & 0x80 > 0)
            result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
        if (x & 0x40 > 0)
            result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
        if (x & 0x20 > 0)
            result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
        if (x & 0x10 > 0)
            result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
        if (x & 0x8 > 0)
            result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
        if (x & 0x4 > 0)
            result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
        if (x & 0x2 > 0)
            result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
        if (x & 0x1 > 0)
            result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

        result >>= uint256(63 - (x >> 64));
        require(result <= uint256(MAX_64x64));

        return int128(result);
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        return
            exp_2(
                int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128)
            );
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128(result);
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
     * number and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x unsigned 129.127-bit fixed point number
     * @param y uint256 value
     * @return unsigned 129.127-bit fixed point number
     */
    function powu(uint256 x, uint256 y) private pure returns (uint256) {
        if (y == 0) return 0x80000000000000000000000000000000;
        else if (x == 0) return 0;
        else {
            int256 msb = 0;
            uint256 xc = x;
            if (xc >= 0x100000000000000000000000000000000) {
                xc >>= 128;
                msb += 128;
            }
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 xe = msb - 127;
            if (xe > 0) x >>= uint256(xe);
            else x <<= uint256(-xe);

            uint256 result = 0x80000000000000000000000000000000;
            int256 re = 0;

            while (y > 0) {
                if (y & 1 > 0) {
                    result = result * x;
                    y -= 1;
                    re += xe;
                    if (
                        result >=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    ) {
                        result >>= 128;
                        re += 1;
                    } else result >>= 127;
                    if (re < -127) return 0; // Underflow
                    require(re < 128); // Overflow
                } else {
                    x = x * x;
                    y >>= 1;
                    xe <<= 1;
                    if (
                        x >=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    ) {
                        x >>= 128;
                        xe += 1;
                    } else x >>= 127;
                    if (xe < -127) return 0; // Underflow
                    require(xe < 128); // Overflow
                }
            }

            if (re > 0) result <<= uint256(re);
            else if (re < 0) result >>= uint256(-re);

            return result;
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// @unsupported: ovm
// Copyright (C) 2015, 2016, 2017 Dapphub
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "balance check failed");

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(
                allowance[src][msg.sender] >= wad,
                "not allowed to transfer"
            );
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

/// @author Benjamin Hughes - Rubicon
/// @notice This contract represents a single-asset liquidity pool for Rubicon Pools
/// @notice Any user can deposit assets into this pool and earn yield from successful strategist market making with their liquidity
/// @notice This contract looks to both BathPairs and the BathHouse as its admin
contract BathToken {
    using SafeMath for uint256;
    bool public initialized;

    string public symbol;
    string public name;
    uint8 public decimals;

    address public RubiconMarketAddress;
    address public bathHouse; // admin
    address public feeTo;
    IERC20 public underlyingToken;
    uint256 public feeBPS;

    uint256 public totalSupply;
    uint256 public outstandingAmount; // quantity of underlyingToken that is in the orderbook and still in pools
    uint256[] outstandingIDs;
    mapping(uint256 => uint256) id2Ind;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event LogInit(uint256 timeOfInit);
    event Deposit(
        uint256 depositedAmt,
        IERC20 asset,
        uint256 sharesReceived,
        address depositor
    );
    event Withdraw(
        uint256 amountWithdrawn,
        IERC20 asset,
        uint256 sharesWithdrawn,
        address withdrawer,
        uint256 fee,
        address feeTo
    );

    /// @dev Proxy-safe initialization of storage
    function initialize(
        string memory bathName,
        IERC20 token,
        address market,
        address _bathHouse,
        address _feeTo
    ) external {
        require(!initialized);
        symbol = bathName;
        underlyingToken = token;
        RubiconMarketAddress = market;
        bathHouse = _bathHouse;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        name = "BathToken v1";
        decimals = 18;

        require(
            RubiconMarket(RubiconMarketAddress).initialized() &&
                BathHouse(bathHouse).initialized()
        );

        // Add infinite approval of Rubicon Market for this asset

        IERC20(address(token)).approve(RubiconMarketAddress, 2**256 - 1);
        emit LogInit(block.timestamp);

        feeTo = _feeTo; //BathHouse admin is initial recipient
        feeBPS = 0; //Fee set to zero

        initialized = true;
    }

    modifier onlyPair() {
        require(
            BathHouse(bathHouse).isApprovedPair(msg.sender) == true,
            "not an approved pair - bathToken"
        );
        _;
    }

    function setMarket(address newRubiconMarket) external {
        require(msg.sender == bathHouse && initialized);
        RubiconMarketAddress = newRubiconMarket;
    }

    function setBathHouse(address newBathHouse) external {
        require(msg.sender == bathHouse && initialized);
        bathHouse = newBathHouse;
    }

    function setFeeBPS(uint256 _feeBPS) external {
        require(msg.sender == bathHouse && initialized);
        feeBPS = _feeBPS;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == bathHouse && initialized);
        feeTo = _feeTo;
    }

    function underlying() external view returns (address) {
        require(initialized);
        return address(underlyingToken);
    }

    /// @notice returns the amount of underlying ERC20 tokens in this pool in addition to
    ///         any tokens that may be outstanding in the Rubicon order book
    function underlyingBalance() public view returns (uint256) {
        require(initialized, "BathToken not initialized");

        uint256 _pool = IERC20(underlyingToken).balanceOf(address(this));
        return _pool.add(outstandingAmount);
    }

    // ** Rubicon Market Functions: **
    function cancel(uint256 id, uint256 amt) external onlyPair {
        outstandingAmount = outstandingAmount.sub(amt);
        RubiconMarket(RubiconMarketAddress).cancel(id);
    }

    function removeFilledTradeAmount(uint256 amt) external onlyPair {
        outstandingAmount = outstandingAmount.sub(amt);
    }

    // function that places a bid/ask in the orderbook for a given pair
    function placeOffer(
        uint256 pay_amt,
        ERC20 pay_gem,
        uint256 buy_amt,
        ERC20 buy_gem
    ) external onlyPair returns (uint256) {
        // Place an offer in RubiconMarket
        // If incomplete offer return 0
        if (
            pay_amt == 0 ||
            pay_gem == ERC20(0) ||
            buy_amt == 0 ||
            buy_gem == ERC20(0)
        ) {
            return 0;
        }

        uint256 id = RubiconMarket(RubiconMarketAddress).offer(
            pay_amt,
            pay_gem,
            buy_amt,
            buy_gem,
            0,
            false
        );
        outstandingAmount = outstandingAmount.add(pay_amt);
        return (id);
    }

    // This function returns filled orders to the correct liquidity pool and sends strategist rewards to the Pair
    function rebalance(
        address sisterBath,
        address underlyingAsset, /* sister asset */
        uint256 stratProportion,
        uint256 rebalAmt
    ) external onlyPair {
        require(initialized);
        uint256 stratReward = (stratProportion.mul(rebalAmt)).div(10000);
        IERC20(underlyingAsset).transfer(sisterBath, rebalAmt.sub(stratReward));
        IERC20(underlyingAsset).transfer(msg.sender, stratReward);
    }

    // ** User Entrypoints: **
    // https://github.com/yearn/yearn-protocol/blob/develop/contracts/vaults/yVault.sol - shoutout yEarn homies
    function deposit(uint256 _amount) external returns (uint256 shares) {
        uint256 _pool = underlyingBalance();
        uint256 _before = underlyingToken.balanceOf(address(this));

        underlyingToken.transferFrom(msg.sender, address(this), _amount);
        uint256 _after = underlyingToken.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens

        shares = 0;
        (totalSupply == 0) ? shares = _amount : shares = (
            _amount.mul(totalSupply)
        ).div(_pool);

        _mint(msg.sender, shares);
        emit Deposit(_amount, underlyingToken, shares, msg.sender);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint256 _shares)
        external
        returns (uint256 amountWithdrawn)
    {
        uint256 r = (underlyingBalance().mul(_shares)).div(totalSupply);
        _burn(msg.sender, _shares);
        uint256 _fee = r.mul(feeBPS).div(10000);
        underlyingToken.transfer(feeTo, _fee);
        amountWithdrawn = r.sub(_fee);
        underlyingToken.transfer(msg.sender, amountWithdrawn);
        emit Withdraw(
            amountWithdrawn,
            underlyingToken,
            _shares,
            msg.sender,
            _fee,
            feeTo
        );
    }

    function approveMarket() external {
        require(initialized);
        if (
            IERC20(underlyingToken).allowance(
                address(this),
                RubiconMarketAddress
            ) == 0
        ) {
            IERC20(address(underlyingToken)).approve(
                RubiconMarketAddress,
                2**256 - 1
            );
        }
    }

    // ** Internal Functions **

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "bathToken: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "bathToken: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

/// @author Benjamin Hughes - Rubicon
/// @notice This contract allows a strategist to use user funds in order to market make for a Rubicon pair
/// @notice The BathPair is the admin for the pair's liquidity and has many security checks in place
/// @notice This contract is also where strategists claim rewards for successful market making
// import "./StrategistUtility.sol";
contract BathPair {
    using SafeMath for uint256;

    address public bathHouse;
    address public underlyingAsset;
    address public underlyingQuote;

    address public bathAssetAddress;
    address public bathQuoteAddress;

    address public RubiconMarketAddress;

    bool public initialized;

    int128 internal shapeCoefNum;
    uint256 public maxOrderSizeBPS;

    /// @dev Internal variables for localalized searching in bathScrub
    uint256 internal start;
    uint256 internal searchRadius;

    uint256 internal totalAssetFills;
    uint256 internal totalQuoteFills;

    /// @dev [askID, ask.pay_amt, bidID, bid.pay_amt, timestamp]
    StrategistTrade[] public outstandingPairIDs;

    /// @dev Maps a trade ID to each of their strategists for rewards purposes
    mapping(address => uint256) public strategist2FillsAsset;
    mapping(address => uint256) public strategist2FillsQuote;

    struct order {
        uint256 pay_amt;
        ERC20 pay_gem;
        uint256 buy_amt;
        ERC20 buy_gem;
    }

    struct StrategistTrade {
        uint256 askId;
        uint256 askAmt;
        uint256 bidId;
        uint256 bidAmt;
        uint256 timestamp;
        address strategist;
    }

    event LogStrategistTrade(
        uint256 askId,
        uint256 askAmt,
        uint256 bidId,
        uint256 bidAmt,
        uint256 timestamp,
        address strategist
    );

    event StrategistRewardClaim(
        address strategist,
        address asset,
        uint256 amountOfReward,
        uint256 timestamp
    );

    /// @dev Proxy-safe initialization of storage
    function initialize(
        address _bathAssetAddress,
        address _bathQuoteAddress,
        address _bathHouse,
        uint256 _maxOrderSizeBPS,
        int128 _shapeCoefNum
    ) external {
        require(!initialized);
        bathHouse = _bathHouse;

        bathAssetAddress = _bathAssetAddress;
        bathQuoteAddress = _bathQuoteAddress;

        require(
            BathToken(bathAssetAddress).underlying() !=
                address(0x0000000000000000000000000000000000000000)
        );
        require(
            BathToken(bathQuoteAddress).underlying() !=
                address(0x0000000000000000000000000000000000000000)
        );
        underlyingAsset = BathToken(bathAssetAddress).underlying();
        underlyingQuote = BathToken(bathQuoteAddress).underlying();

        require(
            BathHouse(bathHouse).getMarket() !=
                address(0x0000000000000000000000000000000000000000)
        );
        RubiconMarketAddress = BathHouse(bathHouse).getMarket();

        maxOrderSizeBPS = _maxOrderSizeBPS;
        shapeCoefNum = _shapeCoefNum;
        start = 0;
        searchRadius = 2;
        initialized = true;
    }

    modifier onlyBathHouse() {
        require(msg.sender == bathHouse);
        _;
    }

    modifier onlyApprovedStrategist(address targetStrategist) {
        require(
            BathHouse(bathHouse).isApprovedStrategist(targetStrategist) == true,
            "you are not an approved strategist - bathPair"
        );
        _;
    }

    // modifier enforceReserveRatio() {
    //     _;
    //     require(
    //         (
    //             BathToken(bathAssetAddress).totalSupply().mul(
    //                 BathHouse(bathHouse).reserveRatio()
    //             )
    //         ).div(100) <= IERC20(underlyingAsset).balanceOf(bathAssetAddress), "Failed to meet asset reserve ratio"
    //     );
    //     require(
    //         (
    //             BathToken(bathQuoteAddress).totalSupply().mul(
    //                 BathHouse(bathHouse).reserveRatio()
    //             )
    //         ).div(100) <= IERC20(underlyingQuote).balanceOf(bathQuoteAddress), "Failed to meet quote reserve ratio"
    //     );
    // }

    function setMaxOrderSizeBPS(uint16 val) external onlyBathHouse {
        maxOrderSizeBPS = val;
    }

    function setShapeCoefNum(int128 val) external onlyBathHouse {
        shapeCoefNum = val;
    }

    function setSearchRadius(uint256 val) external onlyBathHouse {
        searchRadius = val;
    }

    function getThisBathQuote() external view returns (address) {
        require(initialized);
        return bathQuoteAddress;
    }

    function getThisBathAsset() external view returns (address) {
        require(initialized);
        return bathAssetAddress;
    }

    function getOutstandingPairCount() external view returns (uint256) {
        return outstandingPairIDs.length;
    }

    function getSearchRadius() external view returns (uint256) {
        return searchRadius;
    }

    // *** Internal Functions ***

    function getMidpointPrice() internal view returns (int128) {
        address _RubiconMarketAddress = RubiconMarketAddress;
        uint256 bestAskID = RubiconMarket(_RubiconMarketAddress).getBestOffer(
            ERC20(underlyingAsset),
            ERC20(underlyingQuote)
        );
        uint256 bestBidID = RubiconMarket(_RubiconMarketAddress).getBestOffer(
            ERC20(underlyingQuote),
            ERC20(underlyingAsset)
        );
        // Throw a zero if unable to determine midpoint from the book
        if (bestAskID == 0 || bestBidID == 0) {
            return 0;
        }
        order memory bestAsk = getOfferInfo(bestAskID);
        order memory bestBid = getOfferInfo(bestBidID);
        int128 midpoint = ABDKMath64x64.divu(
            (
                (bestAsk.buy_amt.div(bestAsk.pay_amt)).add(
                    bestBid.pay_amt.div(bestBid.buy_amt)
                )
            ),
            2
        );
        return midpoint;
    }

    // orderID of the fill
    // only log fills for each strategist - needs to be asset specific
    // isAssetFill are *quotes* that result in asset yield
    function logFill(
        uint256 amt,
        bool isAssetFill,
        address sender
    ) internal {
        // Goal is to map a fill to a strategist
        if (isAssetFill) {
            strategist2FillsAsset[sender] += amt;
            totalAssetFills += amt;
        } else {
            strategist2FillsQuote[sender] += amt;
            totalQuoteFills += amt;
        }
    }

    function removeElement(uint256 index) internal {
        outstandingPairIDs[index] = outstandingPairIDs[
            outstandingPairIDs.length - 1
        ];
        outstandingPairIDs.pop();
    }

    function handleStratOrderAtIndex(uint256 index) internal {
        StrategistTrade memory info = outstandingPairIDs[index];
        order memory offer1 = getOfferInfo(info.askId); //ask
        order memory offer2 = getOfferInfo(info.bidId); //bid
        uint256 askDelta = info.askAmt - offer1.pay_amt;
        uint256 bidDelta = info.bidAmt - offer2.pay_amt;

        // if real
        if (info.askId != 0) {
            // if delta > 0 - delta is fill => handle any amount of fill here
            if (askDelta > 0) {
                logFill(askDelta, true, info.strategist);
                BathToken(bathAssetAddress).removeFilledTradeAmount(askDelta);
                // not a full fill
                if (askDelta != info.askAmt) {
                    BathToken(bathAssetAddress).cancel(
                        info.askId,
                        info.askAmt.sub(askDelta)
                    );
                }
            }
            // otherwise didn't fill so cancel
            else {
                BathToken(bathAssetAddress).cancel(info.askId, info.askAmt); // pas amount too
            }
        }

        // if real
        if (info.bidId != 0) {
            // if delta > 0 - delta is fill => handle any amount of fill here
            if (bidDelta > 0) {
                logFill(bidDelta, false, info.strategist);
                BathToken(bathQuoteAddress).removeFilledTradeAmount(bidDelta);
                // not a full fill
                if (bidDelta != info.bidAmt) {
                    BathToken(bathQuoteAddress).cancel(
                        info.bidId,
                        info.bidAmt.sub(bidDelta)
                    );
                }
            }
            // otherwise didn't fill so cancel
            else {
                BathToken(bathQuoteAddress).cancel(info.bidId, info.bidAmt); // pass amount too
            }
        }
    }

    // Get offer info from Rubicon Market
    function getOfferInfo(uint256 id) internal view returns (order memory) {
        (
            uint256 ask_amt,
            ERC20 ask_gem,
            uint256 bid_amt,
            ERC20 bid_gem
        ) = RubiconMarket(RubiconMarketAddress).getOffer(id);
        order memory offerInfo = order(ask_amt, ask_gem, bid_amt, bid_gem);
        return offerInfo;
    }

    // *** External functions that can be called by Strategists ***

    function executeStrategy(
        uint256 askNumerator, // Quote / Asset
        uint256 askDenominator, // Asset / Quote
        uint256 bidNumerator, // size in ASSET
        uint256 bidDenominator // size in QUOTES
    ) external onlyApprovedStrategist(msg.sender) {
        // Require at least one order is non-zero
        require(
            (askNumerator > 0 && askDenominator > 0) ||
                (bidNumerator > 0 && bidDenominator > 0)
        );
        address _underlyingAsset = underlyingAsset;
        address _underlyingQuote = underlyingQuote;
        address _bathAssetAddress = bathAssetAddress;
        address _bathQuoteAddress = bathQuoteAddress;
        address _bathHouse = bathHouse;

        // Enforce dynamic ordersizing and inventory management
        require(
            askNumerator <=
                getMaxOrderSize(_underlyingAsset, _bathAssetAddress),
            "ask too large"
        );
        require(
            bidNumerator <=
                getMaxOrderSize(_underlyingQuote, _bathQuoteAddress),
            "bid too large"
        );

        // Enforce that the bath is scrubbed for outstanding pairs
        require(
            outstandingPairIDs.length <
                BathHouse(_bathHouse).maxOutstandingPairCount(),
            "too many outstanding pairs, please call bathScrub() first"
        );
        require(
            (askNumerator > 0 && askDenominator > 0) ||
                (bidNumerator > 0 && bidDenominator > 0),
            "one order must be non-zero"
        );

        // Calculate new bid and/or ask
        order memory ask = order(
            askNumerator,
            ERC20(_underlyingAsset),
            askDenominator,
            ERC20(_underlyingQuote)
        );
        order memory bid = order(
            bidNumerator,
            ERC20(_underlyingQuote),
            bidDenominator,
            ERC20(_underlyingAsset)
        );

        // Place new bid and/or ask
        uint256 newAskID = BathToken(bathAssetAddress).placeOffer(
            ask.pay_amt,
            ask.pay_gem,
            ask.buy_amt,
            ask.buy_gem
        );

        uint256 newBidID = BathToken(bathQuoteAddress).placeOffer(
            bid.pay_amt,
            bid.pay_gem,
            bid.buy_amt,
            bid.buy_gem
        );

        // Strategist trade is recorded so they can get paid and the trade is logged for time
        StrategistTrade memory outgoing = StrategistTrade(
            newAskID,
            ask.pay_amt,
            newBidID,
            bid.pay_amt,
            block.timestamp,
            msg.sender
        );
        outstandingPairIDs.push(outgoing);

        emit LogStrategistTrade(
            outgoing.askId,
            outgoing.askAmt,
            outgoing.bidId,
            outgoing.bidAmt,
            outgoing.timestamp,
            outgoing.strategist
        );
    }

    function rebalancePair(
        uint256 assetRebalAmt, //amount of ASSET in the quote buffer
        uint256 quoteRebalAmt //amount of QUOTE in the asset buffer
    ) external onlyApprovedStrategist(msg.sender) {
        address _bathAssetAddress = bathAssetAddress;
        address _bathQuoteAddress = bathQuoteAddress;
        address _underlyingAsset = underlyingAsset;
        address _underlyingQuote = underlyingQuote;
        uint16 stratReward = BathHouse(bathHouse).getBPSToStrats(address(this));

        // Simply rebalance given amounts
        if (assetRebalAmt > 0) {
            BathToken(_bathQuoteAddress).rebalance(
                _bathAssetAddress,
                _underlyingAsset,
                stratReward,
                assetRebalAmt
            );
        }
        if (quoteRebalAmt > 0) {
            BathToken(_bathAssetAddress).rebalance(
                _bathQuoteAddress,
                _underlyingQuote,
                stratReward,
                quoteRebalAmt
            );
        }
    }

    // //Function to attempt AMM inventory risk tail off
    // function attemptTailOff(
    //     address targetPool,
    //     address tokenToHandle,
    //     address targetToken,
    //     address _stratUtil, // delegatecall target
    //     uint256 amount, //fill amount to handle
    //     uint256 hurdle, //must clear this on tail off
    //     uint24 _poolFee
    // ) external onlyApprovedStrategist(msg.sender) {
    //     // transfer here
    //     uint16 stratReward = BathHouse(bathHouse).getBPSToStrats(address(this));

    //     BathToken(targetPool).rebalance(
    //         address(this),
    //         tokenToHandle,
    //         stratReward,
    //         amount
    //     );
    //     (
    //         bool success, bytes memory data
    //     ) = _stratUtil.delegatecall(
    //             abi.encodeWithSignature(
    //                 "UNItrade(uint256,address,address,uint256,uint256)",
    //                 amount,
    //                 tokenToHandle,
    //                 targetToken,
    //                 hurdle,
    //                 _poolFee
    //             )
    //         );
    //     // Try to derisk on UNI, if fail handle normally
    //     // if (success) {
    //     require(success, "Uni tail off failed");
    //     uint256 outcome = abi.decode(data, (uint256));
    //     //then return to proper pool
    //     ERC20(tokenToHandle).transfer(targetPool, outcome);
    // }

    // This function cleans outstanding orders on a time basis and rebalances yield between bathTokens
    function bathScrub() external {
        uint256 timeDelay = BathHouse(bathHouse).timeDelay();
        uint256 len = outstandingPairIDs.length;
        uint256 _start = start;

        uint256 _searchRadius = searchRadius;
        if (_start + _searchRadius >= len) {
            // start over from beggining
            if (_searchRadius >= len) {
                _start = 0;
                _searchRadius = len;
            } else {
                _searchRadius = len - _start;
            }
        }

        for (uint256 x = _start; x < _start + _searchRadius; x++) {
            if (
                outstandingPairIDs[x].timestamp < (block.timestamp - timeDelay)
            ) {
                handleStratOrderAtIndex(x);

                removeElement(x);
                x--;
                _searchRadius--;
            }
        }
        if (_start + searchRadius >= len) {
            start = 0;
        } else {
            start = _start + searchRadius;
        }
    }

    // Inputs are indices through which to scrub
    // Zero indexed indices!
    function indexScrub(uint8 _start, uint8 _end)
        external
        onlyApprovedStrategist(msg.sender)
    {
        uint256 len = outstandingPairIDs.length;
        uint256 delta = len - 1 - _end;
        require(
            _end - _start <= len,
            "range of indices too great for outstandingPairs length"
        );
        for (uint8 x = _start; x <= _end; x++) {
            handleStratOrderAtIndex(x);

            //delta is indices delta from _end through end of array
            if (delta > 0) {
                removeElement(x);
                delta--;
            } else if (x < _end) {
                removeElement(x);
                x--;
                _end--;
            } else if (x == _end) {
                outstandingPairIDs.pop();
            }
        }
    }

    // Return the largest order size that can be placed as a strategist for given asset and liquidity pool
    function getMaxOrderSize(address asset, address bathTokenAddress)
        public
        view
        returns (uint256 maxOrderSize)
    {
        address _underlyingAsset = underlyingAsset;
        address _underlyingQuote = underlyingQuote;
        require(asset == _underlyingAsset || asset == _underlyingQuote);
        int128 shapeCoef = ABDKMath64x64.div(shapeCoefNum, 1000);

        uint256 underlyingBalance = IERC20(asset).balanceOf(bathTokenAddress);
        require(
            underlyingBalance > 0,
            "no bathToken liquidity to calculate max orderSize permissable"
        );

        // If no midpoint in book, allow **permissioned** strategist to maxOrderSize
        int128 midpoint = getMidpointPrice();
        if (midpoint == 0) {
            return maxOrderSizeBPS.mul(underlyingBalance).div(10000);
        }
        // if the asset/quote is overweighted: underlyingBalance / (Proportion of quote allocated to pair) * underlyingQuote balance
        if (asset == _underlyingAsset) {
            int128 ratio = ABDKMath64x64.divu(
                underlyingBalance,
                IERC20(_underlyingQuote).balanceOf(bathQuoteAddress)
            );
            if (ABDKMath64x64.mul(ratio, midpoint) > (2**64)) {
                // bid at maxSize
                return maxOrderSizeBPS.mul(underlyingBalance).div(10000);
            } else {
                // return dynamic order size
                uint256 maxSize = maxOrderSizeBPS.mul(underlyingBalance).div(
                    10000
                );
                int128 shapeFactor = ABDKMath64x64.exp(
                    ABDKMath64x64.mul(
                        shapeCoef,
                        ABDKMath64x64.inv(ABDKMath64x64.mul(ratio, midpoint))
                    )
                );
                uint256 dynamicSize = ABDKMath64x64.mulu(shapeFactor, maxSize);
                return dynamicSize;
            }
        } else if (asset == _underlyingQuote) {
            int128 ratio = ABDKMath64x64.divu(
                underlyingBalance,
                IERC20(_underlyingAsset).balanceOf(bathAssetAddress)
            );
            if (ABDKMath64x64.div(ratio, midpoint) > (2**64)) {
                return maxOrderSizeBPS.mul(underlyingBalance).div(10000);
            } else {
                // return dynamic order size
                uint256 maxSize = maxOrderSizeBPS.mul(underlyingBalance).div(
                    10000
                );
                int128 shapeFactor = ABDKMath64x64.exp(
                    ABDKMath64x64.mul(
                        shapeCoef,
                        ABDKMath64x64.inv(ABDKMath64x64.div(ratio, midpoint))
                    )
                );
                uint256 dynamicSize = ABDKMath64x64.mulu(shapeFactor, maxSize);
                return dynamicSize;
            }
        }
    }

    // This function allows a strategist to remove Pools liquidity from the order book from a trade id
    // function removeLiquidity(uint256 id) external {
    //     require(id != 0, "cant remove a zero order");
    //     order memory ord = getOfferInfo(id);
    //     if (ord.pay_gem == ERC20(underlyingAsset)) {
    //         uint256 len = outstandingPairIDs.length;
    //         for (uint256 x = 0; x < len; x++) {
    //             if (outstandingPairIDs[x].askId == id) {
    //                 require(
    //                     msg.sender == outstandingPairIDs[x].strategist,
    //                     "only strategist can cancel their orders"
    //                 );
    //                 handleStratOrderAtIndex(x);
    //                 removeElement(x);
    //                 break;
    //             }
    //         }
    //     } else if (ord.pay_gem == ERC20(underlyingQuote)) {
    //         uint256 len = outstandingPairIDs.length;
    //         for (uint256 x = 0; x < len; x++) {
    //             if (outstandingPairIDs[x].bidId == id) {
    //                 require(
    //                     msg.sender == outstandingPairIDs[x].strategist,
    //                     "only strategist can cancel their orders"
    //                 );
    //                 handleStratOrderAtIndex(x);
    //                 removeElement(x);
    //                 break;
    //             }
    //         }
    //     }
    // }

    // function where strategists claim rewards proportional to their quantity of fills
    function strategistBootyClaim() external {
        uint256 fillCountA = strategist2FillsAsset[msg.sender];
        uint256 fillCountQ = strategist2FillsQuote[msg.sender];
        if (fillCountA > 0) {
            uint256 booty = (
                fillCountA.mul(ERC20(underlyingAsset).balanceOf(address(this)))
            ).div(totalAssetFills);
            IERC20(underlyingAsset).transfer(msg.sender, booty);
            emit StrategistRewardClaim(
                msg.sender,
                underlyingAsset,
                booty,
                block.timestamp
            );
            totalAssetFills -= fillCountA;
            strategist2FillsAsset[msg.sender] -= fillCountA;
        }
        if (fillCountQ > 0) {
            uint256 booty = (
                fillCountQ.mul(ERC20(underlyingQuote).balanceOf(address(this)))
            ).div(totalQuoteFills);
            IERC20(underlyingQuote).transfer(msg.sender, booty);
            emit StrategistRewardClaim(
                msg.sender,
                underlyingQuote,
                booty,
                block.timestamp
            );
            totalQuoteFills -= fillCountQ;
            strategist2FillsQuote[msg.sender] -= fillCountQ;
        }
    }
}

/// @author Benjamin Hughes - Rubicon
/// @notice This contract acts as the admin for the Rubicon Pools system
/// @notice The BathHouse approves library contracts and initializes bathPairs
contract BathHouse {
    string public name;

    mapping(address => mapping(address => address)) public getPair;

    address public admin;
    address public RubiconMarketAddress;

    // List of approved strategies
    mapping(address => bool) public approvedBathTokens;
    mapping(address => bool) public approvedPairs;
    mapping(address => bool) public approvedStrategists;

    mapping(address => bool) internal bathQuoteExists;
    mapping(address => bool) internal bathAssetExists;
    mapping(address => uint8) public propToStrategists;
    mapping(address => address) internal quoteToBathQuote;
    mapping(address => address) internal assetToBathAsset;

    bool public initialized;
    bool public permissionedStrategists; //if true strategists are permissioned

    // Key, system-wide risk parameters for Pools
    uint256 public reserveRatio; // proportion of the pool that must remain present in the pair

    // The delay after which unfilled orders are cancelled
    uint256 public timeDelay;

    // Constraint variable for the max amount of outstanding market making pairs at a time
    uint256 public maxOutstandingPairCount;

    // Event to log new BathPairs and their bathTokens
    event LogNewBathPair(
        address newPair,
        address newPairBathAsset,
        address newPairBathQuote,
        address newPairAsset,
        address newPairQuote,
        uint8 newPairStratRewardRate
    );

    /// @dev Proxy-safe initialization of storage
    function initialize(
        address market,
        uint256 _reserveRatio,
        uint256 _timeDelay,
        uint256 mopc
    ) external {
        require(!initialized);
        name = "Rubicon Bath House";
        admin = msg.sender;
        timeDelay = _timeDelay;
        require(_reserveRatio <= 100);
        require(_reserveRatio > 0);
        reserveRatio = _reserveRatio;

        maxOutstandingPairCount = mopc;

        RubiconMarketAddress = market;
        approveStrategist(admin);
        permissionedStrategists = true;
        initialized = true;
    }

    function initBathPair(
        address asset,
        address quote,
        address pair,
        uint8 _propToStrategists
    ) external onlyAdmin returns (address newPair) {
        //calls initialize on two Bath Tokens and spins them up
        require(asset != quote);
        require(asset != address(0));
        require(quote != address(0));

        // Ensure the pair doesn't exist and approved
        require(!isApprovedPair(getPair[asset][quote]));
        propToStrategists[pair] = _propToStrategists;

        getPair[asset][quote] = address(pair);

        approvePair(address(pair));
        address newPairBathAsset = BathPair(pair).getThisBathAsset();
        address newPairBathQuote =BathPair(pair).getThisBathQuote();

        addQuote(quote, newPairBathQuote);
        addAsset(asset, newPairBathAsset);
        
        emit LogNewBathPair(address(pair), newPairBathAsset, newPairBathQuote, asset, quote, _propToStrategists);

        return address(pair);
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function setBathHouseAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function setPermissionedStrategists(bool _new) external onlyAdmin {
        permissionedStrategists = _new;
    }

    // Setter Functions for paramters - onlyAdmin
    function setCancelTimeDelay(uint256 value) external onlyAdmin {
        timeDelay = value;
    }

    function setReserveRatio(uint256 rr) external onlyAdmin {
        require(rr <= 100);
        require(rr > 0);
        reserveRatio = rr;
    }

    function setPropToStrats(uint8 value, address pair) external onlyAdmin {
        require(value < 50);
        require(value >= 0);
        propToStrategists[pair] = value;
    }

    function setMaxOutstandingPairCount(uint256 value) external onlyAdmin {
        maxOutstandingPairCount = value;
    }

    function setBathTokenMarket(address bathToken, address newMarket)
        external
        onlyAdmin
    {
        BathToken(bathToken).setMarket(newMarket);
    }

    function setBathTokenBathHouse(address bathToken, address newAdmin)
        external
        onlyAdmin
    {
        BathToken(bathToken).setMarket(newAdmin);
    }

    function setBathTokenFeeBPS(address bathToken, uint256 newBPS)
        external
        onlyAdmin
    {
        BathToken(bathToken).setFeeBPS(newBPS);
    }

    function setFeeTo(address bathToken, address feeTo) external onlyAdmin {
        BathToken(bathToken).setFeeTo(feeTo);
    }

    function setBathPairMOSBPS(address bathPair, uint16 mosbps)
        external
        onlyAdmin
    {
        BathPair(bathPair).setMaxOrderSizeBPS(mosbps);
    }

    function setBathPairSearchRadius(address bathPair, uint256 sr)
        external
        onlyAdmin
    {
        BathPair(bathPair).setSearchRadius(sr);
    }

    function setBathPairSCN(address bathPair, int128 val) external onlyAdmin {
        BathPair(bathPair).setShapeCoefNum(val);
    }

    function setMarket(address newMarket) external onlyAdmin {
        RubiconMarketAddress = newMarket;
    }

    // Getter Functions for parameters
    function getMarket() external view returns (address) {
        return RubiconMarketAddress;
    }

    function getReserveRatio() external view returns (uint256) {
        return reserveRatio;
    }

    function getCancelTimeDelay() external view returns (uint256) {
        return timeDelay;
    }

    function getBathPair(address asset, address quote)
        external
        view
        returns (address pair)
    {
        return getPair[asset][quote];
    }

    function doesQuoteExist(address quote) external view returns (bool) {
        return bathQuoteExists[quote];
    }

    function doesAssetExist(address asset) external view returns (bool) {
        return bathAssetExists[asset];
    }

    function getBathTokenfromQuote(address quote)
        external
        view
        returns (address)
    {
        return quoteToBathQuote[quote];
    }

    function getBathTokenfromAsset(address asset)
        external
        view
        returns (address)
    {
        return assetToBathAsset[asset];
    }

    function getBPSToStrats(address pair) external view returns (uint8) {
        return propToStrategists[pair];
    }

    // ** Security Checks used throughout Pools **
    function isApprovedStrategist(address wouldBeStrategist)
        external
        view
        returns (bool)
    {
        if (
            approvedStrategists[wouldBeStrategist] == true ||
            !permissionedStrategists
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isApprovedPair(address pair) public view returns (bool) {
        if (approvedPairs[pair] == true) {
            return true;
        } else {
            return false;
        }
    }

    function approveStrategist(address strategist) public onlyAdmin {
        approvedStrategists[strategist] = true;
    }

    function approvePair(address pair) internal {
        approvedPairs[pair] = true;
    }

    function removePair(address pair) external onlyAdmin {
        approvedPairs[pair] = false;
    }

    function addQuote(address quote, address bathQuote) internal {
        if (bathQuoteExists[quote]) {
            return;
        } else {
            bathQuoteExists[quote] = true;
            quoteToBathQuote[quote] = bathQuote;
        }
    }

    function addAsset(address asset, address bathAsset) internal {
        if (bathAssetExists[asset]) {
            return;
        } else {
            bathAssetExists[asset] = true;
            assetToBathAsset[asset] = bathAsset;
        }
    }
}

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

/// @author Benjamin Hughes - Rubicon
/// @notice This contract is a router to interact with the low-level functions present in RubiconMarket and Pools
// @unsupported: ovm
///@dev this contract is a high-level router that utilizes Rubicon smart contracts to provide
///@dev added convenience and functionality when interacting with the Rubicon protocol
contract RubiconRouter {
    using SafeMath for uint256;

    address public RubiconMarketAddress;

    address payable public wethAddress;

    bool public started;

    event LogNote(string, uint256);

    event Swap(
        uint256 inputAmount,
        address inputERC20,
        uint256 hurdleBuyAmtMin,
        address targetERC20,
        uint256 realizedFill,
        address recipient
    );

    function startErUp(address _theTrap, address payable _weth) external {
        require(!started);
        RubiconMarketAddress = _theTrap;
        wethAddress = _weth;
        started = true;
    }

    /// @dev this function returns the best offer for a pair's id and info
    function getBestOfferAndInfo(address asset, address quote)
        public
        view
        returns (
            uint256, //id
            uint256,
            ERC20,
            uint256,
            ERC20
        )
    {
        address _market = RubiconMarketAddress;
        uint256 offer = RubiconMarket(_market).getBestOffer(
            ERC20(asset),
            ERC20(quote)
        );
        (
            uint256 pay_amt,
            ERC20 pay_gem,
            uint256 buy_amt,
            ERC20 buy_gem
        ) = RubiconMarket(_market).getOffer(offer);
        return (offer, pay_amt, pay_gem, buy_amt, buy_gem);
    }

    // function for infinite approvals of Rubicon Market
    function approveAssetOnMarket(address toApprove) public {
        // Approve exchange
        ERC20(toApprove).approve(RubiconMarketAddress, 2**256 - 1);
    }

    /// @dev this function takes the same parameters of swap and returns the expected amount
    function getExpectedSwapFill(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] calldata route, // First address is what is being payed, Last address is what is being bought
        uint256 expectedMarketFeeBPS //20
    ) public view returns (uint256 fill_amt) {
        address _market = RubiconMarketAddress;
        uint256 currentAmount = 0;
        for (uint256 i = 0; i < route.length - 1; i++) {
            (address input, address output) = (route[i], route[i + 1]);
            uint256 _pay = i == 0
                ? pay_amt
                : (
                    currentAmount.sub(
                        currentAmount.mul(expectedMarketFeeBPS).div(10000)
                    )
                );
            uint256 wouldBeFillAmount = RubiconMarket(_market).getBuyAmount(
                ERC20(output),
                ERC20(input),
                _pay
            );
            currentAmount = wouldBeFillAmount;
        }
        require(currentAmount >= buy_amt_min, "didnt clear buy_amt_min");

        // Return the wouldbe resulting swap amount
        return (currentAmount);
    }

    /// @dev This function lets a user swap from route[0] -> route[last] at some minimum expected rate
    /// @dev pay_amt - amount to be swapped away from msg.sender of *first address in path*
    /// @dev buy_amt_min - target minimum received of *last address in path*
    function swap(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] calldata route, // First address is what is being payed, Last address is what is being bought
        uint256 expectedMarketFeeBPS //20
    ) public returns (uint256) {
        //**User must approve this contract first**
        //transfer needed amount here first
        ERC20(route[0]).transferFrom(
            msg.sender,
            address(this),
            pay_amt.add(pay_amt.mul(expectedMarketFeeBPS).div(10000)) // Account for expected fee
        );
        return
            _swap(
                pay_amt,
                buy_amt_min,
                route,
                expectedMarketFeeBPS,
                msg.sender
            );
    }

    // Internal function requires that ERC20s are here before execution
    function _swap(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] calldata route, // First address is what is being payed, Last address is what is being bought
        uint256 expectedMarketFeeBPS,
        address to // Recipient of swap outputs!
    ) internal returns (uint256) {
        address _market = RubiconMarketAddress;
        uint256 currentAmount = 0;
        for (uint256 i = 0; i < route.length - 1; i++) {
            (address input, address output) = (route[i], route[i + 1]);
            uint256 _pay = i == 0
                ? pay_amt
                : (
                    currentAmount.sub(
                        currentAmount.mul(expectedMarketFeeBPS).div(10000)
                    )
                );
            if (ERC20(input).allowance(address(this), _market) == 0) {
                approveAssetOnMarket(input);
            }
            uint256 fillAmount = RubiconMarket(_market).sellAllAmount(
                ERC20(input),
                _pay,
                ERC20(output),
                0 //naively assume no fill_amt here for loop purposes?
            );
            currentAmount = fillAmount;
        }
        require(currentAmount >= buy_amt_min, "didnt clear buy_amt_min");

        // send tokens back to sender if not keeping here
        if (to != address(this)) {
            ERC20(route[route.length - 1]).transfer(to, currentAmount);
        }

        emit Swap(
            pay_amt,
            route[0],
            buy_amt_min,
            route[route.length - 1],
            currentAmount,
            to
        );
        return currentAmount;
    }

    /// @dev this function takes a user's entire balance for the trade in case they want to do a max trade so there's no leftover dust
    function swapEntireBalance(
        uint256 buy_amt_min,
        address[] calldata route, // First address is what is being payed, Last address is what is being bought
        uint256 expectedMarketFeeBPS
    ) external returns (uint256) {
        //swaps msg.sender entire balance in the trade
        uint256 maxAmount = ERC20(route[0]).balanceOf(msg.sender);
        ERC20(route[0]).transferFrom(
            msg.sender,
            address(this),
            maxAmount // Account for expected fee
        );
        return
            _swap(
                maxAmount,
                maxAmount.sub(buy_amt_min.mul(expectedMarketFeeBPS).div(10000)), //account for fee
                route,
                expectedMarketFeeBPS,
                msg.sender
            );
    }

    /// @dev this function takes a user's entire balance for the trade in case they want to do a max trade so there's no leftover dust
    function maxBuyAllAmount(
        ERC20 buy_gem,
        ERC20 pay_gem,
        uint256 max_fill_amount
    ) external returns (uint256 fill) {
        //swaps msg.sender's entire balance in the trade
        uint256 maxAmount = ERC20(buy_gem).balanceOf(msg.sender);
        fill = RubiconMarket(RubiconMarketAddress).buyAllAmount(
            buy_gem,
            maxAmount,
            pay_gem,
            max_fill_amount
        );
        ERC20(buy_gem).transfer(msg.sender, fill);
    }

    /// @dev this function takes a user's entire balance for the trade in case they want to do a max trade so there's no leftover dust
    function maxSellAllAmount(
        ERC20 pay_gem,
        ERC20 buy_gem,
        uint256 min_fill_amount
    ) external returns (uint256 fill) {
        //swaps msg.sender entire balance in the trade
        uint256 maxAmount = ERC20(buy_gem).balanceOf(msg.sender);
        fill = RubiconMarket(RubiconMarketAddress).sellAllAmount(
            pay_gem,
            maxAmount,
            buy_gem,
            min_fill_amount
        );
        ERC20(buy_gem).transfer(msg.sender, fill);
    }

    // ** Native ETH Wrapper Functions **
    /// @dev WETH wrapper functions to obfuscate WETH complexities from ETH holders
    function ETHbuyAllAmountP(
        ERC20 buy_gem,
        uint256 buy_amt,
        // ERC20 nativeETH,
        uint256 max_fill_amount
    ) external payable returns (uint256 fill) {
        require(
            msg.value >= max_fill_amount,
            "must send as much ETH as max_fill_amt"
        );
        WETH9(wethAddress).deposit{value: max_fill_amount}(); // Pay with native ETH -> WETH
        fill = RubiconMarket(RubiconMarketAddress).buyAllAmount(
            buy_gem,
            buy_amt,
            ERC20(wethAddress),
            max_fill_amount
        );
        ERC20(buy_gem).transfer(msg.sender, fill);
        return fill;
    }

    // Paying ERC20 to buy native ETH
    function ETHbuyAllAmountB(
        // ERC20 nativeETH,
        uint256 buy_amt,
        ERC20 pay_gem,
        uint256 max_fill_amount
    ) external returns (uint256 fill) {
        ERC20(pay_gem).transferFrom(msg.sender, address(this), max_fill_amount); //transfer pay here
        fill = RubiconMarket(RubiconMarketAddress).buyAllAmount(
            ERC20(wethAddress),
            buy_amt,
            pay_gem,
            max_fill_amount
        );
        WETH9(wethAddress).withdraw(fill); // Fill in WETH
        msg.sender.transfer(fill); // Return native ETH
        // Return unspent coins to sender
        if (max_fill_amount > fill) {
            ERC20(pay_gem).transfer(msg.sender, max_fill_amount - fill);
        }
        return fill;
    }

    // Pay in native ETH
    function ETHofferP(
        uint256 pay_amt, //maker (ask) sell how much
        // ERC20 nativeETH, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        ERC20 buy_gem, //maker (ask) buy which token
        uint256 pos //position to insert offer, 0 should be used if unknown
    ) external payable returns (uint256) {
        require(
            msg.value >= pay_amt,
            "didnt send enough native ETH for WETH offer"
        );
        uint256 _before = ERC20(buy_gem).balanceOf(address(this));
        WETH9(wethAddress).deposit{value: pay_amt}();
        uint256 id = RubiconMarket(RubiconMarketAddress).offer(
            pay_amt,
            ERC20(wethAddress),
            buy_amt,
            buy_gem,
            pos
        );
        uint256 _after = ERC20(buy_gem).balanceOf(address(this));
        if (_after > _before) {
            //return any potential fill amount on the offer
            ERC20(buy_gem).transfer(msg.sender, _after - _before);
        }
        return id;
    }

    // Pay in native ETH
    function ETHofferB(
        uint256 pay_amt, //maker (ask) sell how much
        ERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        // ERC20 nativeETH, //maker (ask) buy which token
        uint256 pos //position to insert offer, 0 should be used if unknown
    ) external returns (uint256) {
        ERC20(pay_gem).transferFrom(msg.sender, address(this), pay_amt);

        uint256 _before = ERC20(wethAddress).balanceOf(address(this));
        uint256 id = RubiconMarket(RubiconMarketAddress).offer(
            pay_amt,
            pay_gem,
            buy_amt,
            ERC20(wethAddress),
            pos
        );
        uint256 _after = ERC20(wethAddress).balanceOf(address(this));
        if (_after > _before) {
            //return any potential fill amount on the offer as native ETH
            uint256 delta = _after - _before;
            WETH9(wethAddress).withdraw(delta);
            msg.sender.transfer(delta);
        }
        return id;
    }

    // Cancel an offer made in WETH
    function ETHcancel(uint256 id) external returns (bool outcome) {
        (uint256 pay_amt, ERC20 pay_gem, , ) = RubiconMarket(
            RubiconMarketAddress
        ).getOffer(id);
        require(
            address(pay_gem) == wethAddress,
            "trying to cancel a non WETH order"
        );
        // Cancel order and receive WETH here in amount of pay_amt
        outcome = RubiconMarket(RubiconMarketAddress).cancel(id);
        WETH9(wethAddress).withdraw(pay_amt);
        msg.sender.transfer(pay_amt);
    }

    // Deposit native ETH -> WETH pool
    function ETHdeposit(uint256 amount, address targetPool)
        external
        payable
        returns (uint256 newShares)
    {
        IERC20 target = BathToken(targetPool).underlyingToken();
        require(target == ERC20(wethAddress), "target pool not weth pool");
        require(msg.value >= amount, "didnt send enough eth");
        WETH9(wethAddress).deposit{value: amount}();
        newShares = BathToken(targetPool).deposit(amount);
        //Send back bathTokens to sender
        ERC20(targetPool).transfer(msg.sender, newShares);
    }

    // Withdraw native ETH <- WETH pool
    function ETHwithdraw(uint256 shares, address targetPool)
        external
        payable
        returns (uint256 withdrawnWETH)
    {
        IERC20 target = BathToken(targetPool).underlyingToken();
        require(target == ERC20(wethAddress), "target pool not weth pool");
        require(
            BathToken(targetPool).balanceOf(msg.sender) >= shares,
            "didnt send enough shares"
        );
        withdrawnWETH = BathToken(targetPool).withdraw(shares);
        WETH9(wethAddress).withdraw(withdrawnWETH);
        //Send back withdrawn native eth to sender
        msg.sender.transfer(withdrawnWETH);
    }

    function swapWithETH(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] calldata route, // First address is what is being payed, Last address is what is being bought
        uint256 expectedMarketFeeBPS
    ) external payable returns (uint256) {
        require(route[0] == wethAddress, "Initial value in path not WETH");
        uint256 amtWithFee = pay_amt.add(
            pay_amt.mul(expectedMarketFeeBPS).div(10000)
        );
        require(
            msg.value >= amtWithFee,
            "must send enough native ETH to pay as weth and account for fee"
        );
        WETH9(wethAddress).deposit{value: amtWithFee}();
        return
            _swap(
                pay_amt,
                buy_amt_min,
                route,
                expectedMarketFeeBPS,
                msg.sender
            );
    }

    function swapForETH(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] calldata route, // First address is what is being payed, Last address is what is being bought
        uint256 expectedMarketFeeBPS
    ) external payable returns (uint256 fill) {
        require(
            route[route.length - 1] == wethAddress,
            "target of swap is not WETH"
        );
        //Transfer tokens here first and account for fee
        require(
            ERC20(route[0]).transferFrom(
                msg.sender,
                address(this),
                pay_amt.add(pay_amt.mul(expectedMarketFeeBPS).div(10000))
            ),
            "initial ERC20 transfer failed"
        );
        fill = _swap(
            pay_amt,
            buy_amt_min,
            route,
            expectedMarketFeeBPS,
            address(this)
        );

        WETH9(wethAddress).withdraw(fill);
        // msg.sender.transfer(fill);
        TransferHelper.safeTransferETH(msg.sender, fill);
    }
}