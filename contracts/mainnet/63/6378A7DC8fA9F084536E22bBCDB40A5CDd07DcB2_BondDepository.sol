/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/math/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;



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


// File contracts/math/BitMath.sol
pragma solidity 0.7.5;

library BitMath {
  function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
    require(x > 0, "BitMath::mostSignificantBit: zero");

    if (x >= 0x100000000000000000000000000000000) {
      x >>= 128;
      r += 128;
    }
    if (x >= 0x10000000000000000) {
      x >>= 64;
      r += 64;
    }
    if (x >= 0x100000000) {
      x >>= 32;
      r += 32;
    }
    if (x >= 0x10000) {
      x >>= 16;
      r += 16;
    }
    if (x >= 0x100) {
      x >>= 8;
      r += 8;
    }
    if (x >= 0x10) {
      x >>= 4;
      r += 4;
    }
    if (x >= 0x4) {
      x >>= 2;
      r += 2;
    }
    if (x >= 0x2) r += 1;
  }
}


// File contracts/math/FullMath.sol
pragma solidity 0.7.5;

library FullMath {
  function fullMul(uint256 x, uint256 y)
    private
    pure
    returns (uint256 l, uint256 h)
  {
    uint256 mm = mulmod(x, y, uint256(-1));
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
    uint256 pow2 = d & -d;
    d /= pow2;
    l /= pow2;
    l += h * ((-pow2) / pow2 + 1);
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);
    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;
    require(h < d, "FullMath::mulDiv: overflow");
    return fullDiv(l, h, d);
  }
}


// File contracts/math/FixedPoint.sol
pragma solidity 0.7.5;


library Babylonian {
  function sqrt(uint256 x) internal pure returns (uint256) {
    if (x == 0) return 0;

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
    return (r < r1 ? r : r1);
  }
}

library FixedPoint {
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112
  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = 0x10000000000000000000000000000;
  uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000;
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  // decode a UQ112x112 into a uint112 by truncating after the radix point
  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  // decode a uq112x112 into a uint with 18 decimals of precision
  function decode112with18(uq112x112 memory self)
    internal
    pure
    returns (uint256)
  {
    return uint256(self._x) / 5192296858534827;
  }

  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= uint144(-1)) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= uint224(-1), "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= uint224(-1), "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }

  // square root of a UQ112x112
  // lossy between 0/1 and 40 bits
  function sqrt(uq112x112 memory self)
    internal
    pure
    returns (uq112x112 memory)
  {
    if (self._x <= uint144(-1)) {
      return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
    }

    uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
    safeShiftBits -= safeShiftBits % 2;
    return
      uq112x112(
        uint224(
          Babylonian.sqrt(uint256(self._x) << safeShiftBits) <<
            ((112 - safeShiftBits) / 2)
        )
      );
  }
}


// File contracts/BondingCalculator.sol
pragma solidity 0.7.5;



library MySafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function sqrrt(uint256 a) internal pure returns (uint256 c) {
    if (a > 3) {
      c = a;
      uint256 b = add(div(a, 2), 1);
      while (b < c) {
        c = b;
        b = div(add(div(a, b), b), 2);
      }
    } else if (a != 0) {
      c = 1;
    }
  }
}

interface IUniswapV2ERC20 {
  function totalSupply() external view returns (uint256);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function token0() external view returns (address);

  function token1() external view returns (address);
}

contract BondingCalculator {
  using FixedPoint for *;
  using MySafeMath for uint256;
  using MySafeMath for uint112;

  address public immutable HADES;

  constructor(address _HADES) {
    require(_HADES != address(0));
    HADES = _HADES;
  }

  function getKValue(address _pair) public view returns (uint256 k_) {
    uint256 token0 = ERC20(IUniswapV2Pair(_pair).token0()).decimals();
    uint256 token1 = ERC20(IUniswapV2Pair(_pair).token1()).decimals();
    uint256 decimals = token0.add(token1).sub(ERC20(_pair).decimals());

    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair)
      .getReserves();
    k_ = reserve0.mul(reserve1).div(10**decimals);
  }

  function getTotalValue(address _pair) public view returns (uint256 _value) {
    _value = getKValue(_pair).sqrrt().mul(2);
  }

  function valuation(address _pair, uint256 amount_)
    external
    view
    returns (uint256 _value)
  {
    uint256 totalValue = getTotalValue(_pair);
    uint256 totalSupply = IUniswapV2Pair(_pair).totalSupply();

    _value = totalValue
      .mul(FixedPoint.fraction(amount_, totalSupply).decode112with18())
      .div(1e18);
  }

  function markdown(address _pair) external view returns (uint256) {
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair)
      .getReserves();

    uint256 reserve;
    if (IUniswapV2Pair(_pair).token0() == HADES) {
      reserve = reserve1;
    } else {
      reserve = reserve0;
    }
    return
      reserve.mul(2 * (10**ERC20(HADES).decimals())).div(getTotalValue(_pair));
  }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}


// File @openzeppelin/contracts/presets/[email protected]

pragma solidity >=0.6.0 <0.8.0;





/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}


// File contracts/Treasury.sol
pragma solidity 0.7.5;





contract Treasury is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Deposit(address indexed token, uint256 amount, uint256 value);
  event Withdrawal(address indexed token, uint256 amount, uint256 value);
  event CreateDebt(
    address indexed debtor,
    address indexed token,
    uint256 amount,
    uint256 value
  );
  event RepayDebt(
    address indexed debtor,
    address indexed token,
    uint256 amount,
    uint256 value
  );
  event ReservesManaged(address indexed token, uint256 amount);
  event ReservesUpdated(uint256 indexed totalReserves);
  event ReservesAudited(uint256 indexed totalReserves);
  event RewardsMinted(
    address indexed caller,
    address indexed recipient,
    uint256 amount
  );
  event ChangeQueued(MANAGING indexed managing, address queued);
  event ChangeActivated(
    MANAGING indexed managing,
    address activated,
    bool result
  );

  enum MANAGING {
    RESERVEDEPOSITOR,
    RESERVESPENDER,
    RESERVETOKEN,
    RESERVEMANAGER,
    LIQUIDITYDEPOSITOR,
    LIQUIDITYTOKEN,
    LIQUIDITYMANAGER,
    DEBTOR,
    REWARDMANAGER,
    SHADES
  }

  address public immutable HADES;
  uint256 public immutable blocksNeededForQueue;

  address[] public reserveTokens; // Push only, beware false-positives.
  mapping(address => bool) public isReserveToken;
  mapping(address => uint256) public reserveTokenQueue; // Delays changes to mapping.

  address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isReserveDepositor;
  mapping(address => uint256) public reserveDepositorQueue; // Delays changes to mapping.

  address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isReserveSpender;
  mapping(address => uint256) public reserveSpenderQueue; // Delays changes to mapping.

  address[] public liquidityTokens; // Push only, beware false-positives.
  mapping(address => bool) public isLiquidityToken;
  mapping(address => uint256) public LiquidityTokenQueue; // Delays changes to mapping.

  address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isLiquidityDepositor;
  mapping(address => uint256) public LiquidityDepositorQueue; // Delays changes to mapping.

  mapping(address => address) public bondCalculator; // bond calculator for liquidity token

  address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isReserveManager;
  mapping(address => uint256) public ReserveManagerQueue; // Delays changes to mapping.

  address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isLiquidityManager;
  mapping(address => uint256) public LiquidityManagerQueue; // Delays changes to mapping.

  address[] public debtors; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isDebtor;
  mapping(address => uint256) public debtorQueue; // Delays changes to mapping.
  mapping(address => uint256) public debtorBalance;

  address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
  mapping(address => bool) public isRewardManager;
  mapping(address => uint256) public rewardManagerQueue; // Delays changes to mapping.

  address public sHADES;
  uint256 public sHADESQueue; // Delays change to sHADES address

  uint256 public totalReserves; // Risk-free value of all assets
  uint256 public totalDebt;

  constructor(
    address _HADES,
    address _OHM,
    uint256 _blocksNeededForQueue
  ) {
    require(_HADES != address(0));
    HADES = _HADES;

    isReserveToken[_OHM] = true;
    reserveTokens.push(_OHM);

    blocksNeededForQueue = _blocksNeededForQueue;
  }

  /**
        @notice allow approved address to deposit an asset for HADES
        @param _amount uint
        @param _token address
        @param _profit uint
        @param _only_deposit bool
        @return send_ uint
     */
  function deposit(
    uint256 _amount,
    address _token,
    uint256 _profit,
    bool _only_deposit
  ) external returns (uint256 send_) {
    require(isReserveToken[_token] || isLiquidityToken[_token], "Not accepted");
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    if (isReserveToken[_token]) {
      require(isReserveDepositor[msg.sender], "Not approved");
    } else {
      require(isLiquidityDepositor[msg.sender], "Not approved");
    }
    uint256 value = valueOfToken(_token, _amount);

    // Just update reserves if _only_deposit is true - no HADES minting.
    // This is for sending the OHM from the aHades contract.
    // Otherwise, treat it like a normal deposit.
    if (_only_deposit) {
      totalReserves = totalReserves.add(value);
      emit ReservesUpdated(totalReserves);
    } else {
      // mint HADES needed and store amount of rewards for distribution
      send_ = value.sub(_profit);
      ERC20PresetMinterPauser(HADES).mint(msg.sender, send_);

      totalReserves = totalReserves.add(value);
      emit ReservesUpdated(totalReserves);

      emit Deposit(_token, _amount, value);
    }
  }

  /**
        @notice allow approved address to burn HADES for reserves
        @param _amount uint
        @param _token address
     */
  function withdraw(uint256 _amount, address _token) external {
    require(isReserveToken[_token], "Not accepted"); // Only reserves can be used for redemptions
    require(isReserveSpender[msg.sender] == true, "Not approved");

    uint256 value = valueOfToken(_token, _amount);
    ERC20PresetMinterPauser(HADES).burnFrom(msg.sender, value);

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC20(_token).safeTransfer(msg.sender, _amount);

    emit Withdrawal(_token, _amount, value);
  }

  /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
     */
  function incurDebt(uint256 _amount, address _token) external {
    require(isDebtor[msg.sender], "Not approved");
    require(isReserveToken[_token], "Not accepted");

    uint256 value = valueOfToken(_token, _amount);

    uint256 maximumDebt = IERC20(sHADES).balanceOf(msg.sender); // Can only borrow against sHADES held
    uint256 availableDebt = maximumDebt.sub(debtorBalance[msg.sender]);
    require(value <= availableDebt, "Exceeds debt limit");

    debtorBalance[msg.sender] = debtorBalance[msg.sender].add(value);
    totalDebt = totalDebt.add(value);

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC20(_token).transfer(msg.sender, _amount);
    emit CreateDebt(msg.sender, _token, _amount, value);
  }

  /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
     */
  function repayDebtWithReserve(uint256 _amount, address _token) external {
    require(isDebtor[msg.sender], "Not approved");
    require(isReserveToken[_token], "Not accepted");

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 value = valueOfToken(_token, _amount);
    debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(value);
    totalDebt = totalDebt.sub(value);

    totalReserves = totalReserves.add(value);
    emit ReservesUpdated(totalReserves);

    emit RepayDebt(msg.sender, _token, _amount, value);
  }

  /**
        @notice allow approved address to repay borrowed reserves with HADES
        @param _amount uint
     */
  function repayDebtWithHADES(uint256 _amount) external {
    require(isDebtor[msg.sender], "Not approved");

    ERC20PresetMinterPauser(HADES).burnFrom(msg.sender, _amount);

    debtorBalance[msg.sender] = debtorBalance[msg.sender].sub(_amount);
    totalDebt = totalDebt.sub(_amount);

    emit RepayDebt(msg.sender, HADES, _amount, _amount);
  }

  /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
  function manage(address _token, uint256 _amount) external {
    if (isLiquidityToken[_token]) {
      require(isLiquidityManager[msg.sender], "Not approved");
    } else {
      require(isReserveManager[msg.sender], "Not approved");
    }

    uint256 value = valueOfToken(_token, _amount);
    require(value <= excessReserves(), "Insufficient reserves");

    totalReserves = totalReserves.sub(value);
    emit ReservesUpdated(totalReserves);

    IERC20(_token).safeTransfer(msg.sender, _amount);

    emit ReservesManaged(_token, _amount);
  }

  /**
        @notice send epoch reward to staking contract
     */
  function mintRewards(address _recipient, uint256 _amount) external {
    require(isRewardManager[msg.sender], "Not approved");
    require(_amount <= excessReserves(), "Insufficient reserves");

    ERC20PresetMinterPauser(HADES).mint(_recipient, _amount);

    emit RewardsMinted(msg.sender, _recipient, _amount);
  }

  /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
  function excessReserves() public view returns (uint256) {
    return totalReserves.sub(IERC20(HADES).totalSupply().sub(totalDebt));
  }

  /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
  function auditReserves() external onlyOwner {
    uint256 reserves;
    for (uint256 i = 0; i < reserveTokens.length; i++) {
      reserves = reserves.add(
        valueOfToken(
          reserveTokens[i],
          IERC20(reserveTokens[i]).balanceOf(address(this))
        )
      );
    }
    for (uint256 i = 0; i < liquidityTokens.length; i++) {
      reserves = reserves.add(
        valueOfToken(
          liquidityTokens[i],
          IERC20(liquidityTokens[i]).balanceOf(address(this))
        )
      );
    }
    totalReserves = reserves;
    emit ReservesUpdated(reserves);
    emit ReservesAudited(reserves);
  }

  /**
        @notice returns HADES valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
  function valueOfToken(address _token, uint256 _amount)
    public
    view
    returns (uint256 value_)
  {
    if (isReserveToken[_token]) {
      // convert amount to match HADES decimals
      value_ = _amount
        .mul(10**ERC20(HADES).decimals())
        .div(10**ERC20(_token).decimals());
    } else if (isLiquidityToken[_token]) {
      value_ = BondingCalculator(bondCalculator[_token]).valuation(
        _token,
        _amount
      );
    }
  }

  /**
        @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
  function queue(MANAGING _managing, address _address)
    external
    onlyOwner
    returns (bool)
  {
    require(_address != address(0));
    if (_managing == MANAGING.RESERVEDEPOSITOR) {
      // 0
      reserveDepositorQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.RESERVESPENDER) {
      // 1
      reserveSpenderQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.RESERVETOKEN) {
      // 2
      reserveTokenQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.RESERVEMANAGER) {
      // 3
      ReserveManagerQueue[_address] = block.number.add(
        blocksNeededForQueue.mul(2)
      );
    } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
      // 4
      LiquidityDepositorQueue[_address] = block.number.add(
        blocksNeededForQueue
      );
    } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
      // 5
      LiquidityTokenQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
      // 6
      LiquidityManagerQueue[_address] = block.number.add(
        blocksNeededForQueue.mul(2)
      );
    } else if (_managing == MANAGING.DEBTOR) {
      // 7
      debtorQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.REWARDMANAGER) {
      // 8
      rewardManagerQueue[_address] = block.number.add(blocksNeededForQueue);
    } else if (_managing == MANAGING.SHADES) {
      // 9
      sHADESQueue = block.number.add(blocksNeededForQueue);
    } else return false;

    emit ChangeQueued(_managing, _address);
    return true;
  }

  /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
  function toggle(
    MANAGING _managing,
    address _address,
    address _calculator
  ) external onlyOwner returns (bool) {
    require(_address != address(0));
    bool result;
    if (_managing == MANAGING.RESERVEDEPOSITOR) {
      // 0
      if (requirements(reserveDepositorQueue, isReserveDepositor, _address)) {
        reserveDepositorQueue[_address] = 0;
        if (!listContains(reserveDepositors, _address)) {
          reserveDepositors.push(_address);
        }
      }
      result = !isReserveDepositor[_address];
      isReserveDepositor[_address] = result;
    } else if (_managing == MANAGING.RESERVESPENDER) {
      // 1
      if (requirements(reserveSpenderQueue, isReserveSpender, _address)) {
        reserveSpenderQueue[_address] = 0;
        if (!listContains(reserveSpenders, _address)) {
          reserveSpenders.push(_address);
        }
      }
      result = !isReserveSpender[_address];
      isReserveSpender[_address] = result;
    } else if (_managing == MANAGING.RESERVETOKEN) {
      // 2
      if (requirements(reserveTokenQueue, isReserveToken, _address)) {
        reserveTokenQueue[_address] = 0;
        if (!listContains(reserveTokens, _address)) {
          reserveTokens.push(_address);
        }
      }
      result = !isReserveToken[_address];
      isReserveToken[_address] = result;
    } else if (_managing == MANAGING.RESERVEMANAGER) {
      // 3
      if (requirements(ReserveManagerQueue, isReserveManager, _address)) {
        reserveManagers.push(_address);
        ReserveManagerQueue[_address] = 0;
        if (!listContains(reserveManagers, _address)) {
          reserveManagers.push(_address);
        }
      }
      result = !isReserveManager[_address];
      isReserveManager[_address] = result;
    } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
      // 4
      if (
        requirements(LiquidityDepositorQueue, isLiquidityDepositor, _address)
      ) {
        liquidityDepositors.push(_address);
        LiquidityDepositorQueue[_address] = 0;
        if (!listContains(liquidityDepositors, _address)) {
          liquidityDepositors.push(_address);
        }
      }
      result = !isLiquidityDepositor[_address];
      isLiquidityDepositor[_address] = result;
    } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
      // 5
      if (requirements(LiquidityTokenQueue, isLiquidityToken, _address)) {
        LiquidityTokenQueue[_address] = 0;
        if (!listContains(liquidityTokens, _address)) {
          liquidityTokens.push(_address);
        }
      }
      result = !isLiquidityToken[_address];
      isLiquidityToken[_address] = result;
      bondCalculator[_address] = _calculator;
    } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
      // 6
      if (requirements(LiquidityManagerQueue, isLiquidityManager, _address)) {
        LiquidityManagerQueue[_address] = 0;
        if (!listContains(liquidityManagers, _address)) {
          liquidityManagers.push(_address);
        }
      }
      result = !isLiquidityManager[_address];
      isLiquidityManager[_address] = result;
    } else if (_managing == MANAGING.DEBTOR) {
      // 7
      if (requirements(debtorQueue, isDebtor, _address)) {
        debtorQueue[_address] = 0;
        if (!listContains(debtors, _address)) {
          debtors.push(_address);
        }
      }
      result = !isDebtor[_address];
      isDebtor[_address] = result;
    } else if (_managing == MANAGING.REWARDMANAGER) {
      // 8
      if (requirements(rewardManagerQueue, isRewardManager, _address)) {
        rewardManagerQueue[_address] = 0;
        if (!listContains(rewardManagers, _address)) {
          rewardManagers.push(_address);
        }
      }
      result = !isRewardManager[_address];
      isRewardManager[_address] = result;
    } else if (_managing == MANAGING.SHADES) {
      // 9
      sHADESQueue = 0;
      sHADES = _address;
      result = true;
    } else return false;

    emit ChangeActivated(_managing, _address, result);
    return true;
  }

  /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint256 )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool 
     */
  function requirements(
    mapping(address => uint256) storage queue_,
    mapping(address => bool) storage status_,
    address _address
  ) internal view returns (bool) {
    if (!status_[_address]) {
      require(queue_[_address] != 0, "Must queue");
      require(queue_[_address] <= block.number, "Queue not expired");
      return true;
    }
    return false;
  }

  /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
  function listContains(address[] storage _list, address _token)
    internal
    view
    returns (bool)
  {
    for (uint256 i = 0; i < _list.length; i++) {
      if (_list[i] == _token) {
        return true;
      }
    }
    return false;
  }
}


// File contracts/Distributor.sol

pragma solidity 0.7.5;




contract Distributor is Ownable {
  using SafeMath for uint256;

  /* ====== VARIABLES ====== */

  address public immutable HADES;
  address public immutable treasury;

  uint256 public immutable epochLength;
  uint256 public nextEpochBlock;

  mapping(uint256 => Adjust) public adjustments;

  /* ====== STRUCTS ====== */

  struct Info {
    uint256 rate; // in ten-thousandths ( 5000 = 0.5% )
    address recipient;
  }
  Info[] public info;

  struct Adjust {
    bool add;
    uint256 rate;
    uint256 target;
  }

  /* ====== CONSTRUCTOR ====== */

  constructor(
    address _treasury,
    address _hades,
    uint256 _epochLength,
    uint256 _nextEpochBlock
  ) {
    require(_treasury != address(0));
    treasury = _treasury;
    require(_hades != address(0));
    HADES = _hades;
    epochLength = _epochLength;
    nextEpochBlock = _nextEpochBlock;
  }

  /* ====== PUBLIC FUNCTIONS ====== */

  /**
        @notice send epoch reward to staking contract
     */
  function distribute() external returns (bool) {
    if (nextEpochBlock <= block.number) {
      nextEpochBlock = nextEpochBlock.add(epochLength); // set next epoch block

      // distribute rewards to each recipient
      for (uint256 i = 0; i < info.length; i++) {
        if (info[i].rate > 0) {
          Treasury(treasury).mintRewards( // mint and send from treasury
            info[i].recipient,
            nextRewardAt(info[i].rate)
          );
          adjust(i); // check for adjustment
        }
      }
      return true;
    } else {
      return false;
    }
  }

  /* ====== INTERNAL FUNCTIONS ====== */

  /**
        @notice increment reward rate for collector
     */
  function adjust(uint256 _index) internal {
    Adjust memory adjustment = adjustments[_index];
    if (adjustment.rate != 0) {
      if (adjustment.add) {
        // if rate should increase
        info[_index].rate = info[_index].rate.add(adjustment.rate); // raise rate
        if (info[_index].rate >= adjustment.target) {
          // if target met
          adjustments[_index].rate = 0; // turn off adjustment
        }
      } else {
        // if rate should decrease
        info[_index].rate = info[_index].rate.sub(adjustment.rate); // lower rate
        if (info[_index].rate <= adjustment.target) {
          // if target met
          adjustments[_index].rate = 0; // turn off adjustment
        }
      }
    }
  }

  /* ====== VIEW FUNCTIONS ====== */

  /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
  function nextRewardAt(uint256 _rate) public view returns (uint256) {
    return IERC20(HADES).totalSupply().mul(_rate).div(1000000);
  }

  /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint
     */
  function nextRewardFor(address _recipient) public view returns (uint256) {
    uint256 reward;
    for (uint256 i = 0; i < info.length; i++) {
      if (info[i].recipient == _recipient) {
        reward = nextRewardAt(info[i].rate);
      }
    }
    return reward;
  }

  /* ====== POLICY FUNCTIONS ====== */

  /**
        @notice adds recipient for distributions
        @param _recipient address
        @param _rewardRate uint
     */
  function addRecipient(address _recipient, uint256 _rewardRate)
    external
    onlyOwner
  {
    require(_recipient != address(0));
    info.push(Info({recipient: _recipient, rate: _rewardRate}));
  }

  /**
        @notice removes recipient for distributions
        @param _index uint
        @param _recipient address
     */
  function removeRecipient(uint256 _index, address _recipient)
    external
    onlyOwner
  {
    require(_recipient == info[_index].recipient);
    info[_index].recipient = address(0);
    info[_index].rate = 0;
  }

  /**
        @notice set adjustment info for a collector's reward rate
        @param _index uint
        @param _add bool
        @param _rate uint
        @param _target uint
     */
  function setAdjustment(
    uint256 _index,
    bool _add,
    uint256 _rate,
    uint256 _target
  ) external onlyOwner {
    adjustments[_index] = Adjust({add: _add, rate: _rate, target: _target});
  }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/sHades.sol
pragma solidity 0.7.5;



interface sHadesIERC20 {
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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

abstract contract sHadesERC20 is sHadesIERC20 {
  using SafeMath for uint256;

  // TODO comment actual hash value.
  bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
    keccak256("ERC20Token");

  // Present in ERC777
  mapping(address => uint256) internal _balances;

  // Present in ERC777
  mapping(address => mapping(address => uint256)) internal _allowances;

  // Present in ERC777
  uint256 internal _totalSupply;

  // Present in ERC777
  string internal _name;

  // Present in ERC777
  string internal _symbol;

  // Present in ERC777
  uint8 internal _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  /**
   * @dev Returns the name of the token.
   */
  // Present in ERC777
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  // Present in ERC777
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
  // Present in ERC777
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  // Present in ERC777
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  // Present in ERC777
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
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
  // Overrideen in ERC777
  // Confirm that this behavior changes
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  // Present in ERC777
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  // Present in ERC777
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
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
  // Present in ERC777
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _allowances[sender][msg.sender].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
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
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].add(addedValue)
    );
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
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
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(
      amount,
      "ERC20: transfer amount exceeds balance"
    );
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
  // Present in ERC777
  function _mint(address account_, uint256 ammount_) internal virtual {
    require(account_ != address(0), "ERC20: mint to the zero address");
    _beforeTokenTransfer(address(this), account_, ammount_);
    _totalSupply = _totalSupply.add(ammount_);
    _balances[account_] = _balances[account_].add(ammount_);
    emit Transfer(address(this), account_, ammount_);
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
  // Present in ERC777
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(
      amount,
      "ERC20: burn amount exceeds balance"
    );
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
  // Present in ERC777
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
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
  // Considering deprication to reduce size of bytecode as changing _decimals to internal acheived the same functionality.
  // function _setupDecimals(uint8 decimals_) internal {
  //     _decimals = decimals_;
  // }

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
  // Present in ERC777
  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 amount_
  ) internal virtual {}
}

interface IERC2612Permit {
  /**
   * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
   * given `owner`'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current ERC2612 nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is sHadesERC20, IERC2612Permit {
  using Counters for Counters.Counter;

  mapping(address => Counters.Counter) private _nonces;

  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  bytes32 public DOMAIN_SEPARATOR;

  constructor() {
    uint256 chainID;
    assembly {
      chainID := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(name())),
        keccak256(bytes("1")), // Version
        chainID,
        address(this)
      )
    );
  }

  /**
   * @dev See {IERC2612Permit-permit}.
   *
   */
  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(block.timestamp <= deadline, "Permit: expired deadline");

    bytes32 hashStruct = keccak256(
      abi.encode(
        PERMIT_TYPEHASH,
        owner,
        spender,
        amount,
        _nonces[owner].current(),
        deadline
      )
    );

    bytes32 _hash = keccak256(
      abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct)
    );

    address signer = ecrecover(_hash, v, r, s);
    require(
      signer != address(0) && signer == owner,
      "ZeroSwapPermit: Invalid signature"
    );

    _nonces[owner].increment();
    _approve(owner, spender, amount);
  }

  /**
   * @dev See {IERC2612Permit-nonces}.
   */
  function nonces(address owner) public view override returns (uint256) {
    return _nonces[owner].current();
  }
}

contract sHades is ERC20Permit, Ownable {
  using SafeMath for uint256;

  modifier onlyStakingContract() {
    require(msg.sender == stakingContract);
    _;
  }

  address public stakingContract;
  address public initializer;

  event LogSupply(
    uint256 indexed epoch,
    uint256 timestamp,
    uint256 totalSupply
  );
  event LogRebase(uint256 indexed epoch, uint256 rebase, uint256 index);
  event LogStakingContractUpdated(address stakingContract);

  struct Rebase {
    uint256 epoch;
    uint256 rebase; // 18 decimals
    uint256 totalStakedBefore;
    uint256 totalStakedAfter;
    uint256 amountRebased;
    uint256 index;
    uint256 blockNumberOccured;
  }
  Rebase[] public rebases;

  uint256 public INDEX;

  uint256 private constant MAX_UINT256 = ~uint256(0);
  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5000000 * 10**9;

  // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
  // Use the highest value that fits in a uint256 for max granularity.
  uint256 private constant TOTAL_GONS =
    MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

  // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
  uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1

  uint256 private _gonsPerFragment;
  mapping(address => uint256) private _gonBalances;

  mapping(address => mapping(address => uint256)) private _allowedValue;

  constructor() sHadesERC20("Staked Hades", "sHADES", 9) ERC20Permit() {
    initializer = msg.sender;
    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
  }

  function initialize(address stakingContract_) external returns (bool) {
    require(msg.sender == initializer);
    require(stakingContract_ != address(0));
    stakingContract = stakingContract_;
    _gonBalances[stakingContract] = TOTAL_GONS;

    emit Transfer(address(0x0), stakingContract, _totalSupply);
    emit LogStakingContractUpdated(stakingContract_);

    initializer = address(0);
    return true;
  }

  function setIndex(uint256 _INDEX) external onlyOwner returns (bool) {
    require(INDEX == 0);
    INDEX = gonsForBalance(_INDEX);
    return true;
  }

  /**
        @notice increases sOHM supply to increase staking balances relative to profit_
        @param profit_ uint256
        @return uint256
     */
  function rebase(uint256 profit_, uint256 epoch_)
    public
    onlyStakingContract
    returns (uint256)
  {
    uint256 rebaseAmount;
    uint256 circulatingSupply_ = circulatingSupply();

    if (profit_ == 0) {
      emit LogSupply(epoch_, block.timestamp, _totalSupply);
      emit LogRebase(epoch_, 0, index());
      return _totalSupply;
    } else if (circulatingSupply_ > 0) {
      rebaseAmount = profit_.mul(_totalSupply).div(circulatingSupply_);
    } else {
      rebaseAmount = profit_;
    }

    _totalSupply = _totalSupply.add(rebaseAmount);

    if (_totalSupply > MAX_SUPPLY) {
      _totalSupply = MAX_SUPPLY;
    }

    _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

    _storeRebase(circulatingSupply_, profit_, epoch_);

    return _totalSupply;
  }

  /**
        @notice emits event with data about rebase
        @param previousCirculating_ uint
        @param profit_ uint
        @param epoch_ uint
        @return bool
     */
  function _storeRebase(
    uint256 previousCirculating_,
    uint256 profit_,
    uint256 epoch_
  ) internal returns (bool) {
    uint256 rebasePercent = profit_.mul(1e18).div(previousCirculating_);

    rebases.push(
      Rebase({
        epoch: epoch_,
        rebase: rebasePercent, // 18 decimals
        totalStakedBefore: previousCirculating_,
        totalStakedAfter: circulatingSupply(),
        amountRebased: profit_,
        index: index(),
        blockNumberOccured: block.number
      })
    );

    emit LogSupply(epoch_, block.timestamp, _totalSupply);
    emit LogRebase(epoch_, rebasePercent, index());

    return true;
  }

  function balanceOf(address who) public view override returns (uint256) {
    return _gonBalances[who].div(_gonsPerFragment);
  }

  function gonsForBalance(uint256 amount) public view returns (uint256) {
    return amount.mul(_gonsPerFragment);
  }

  function balanceForGons(uint256 gons) public view returns (uint256) {
    return gons.div(_gonsPerFragment);
  }

  // Staking contract holds excess sOHM
  function circulatingSupply() public view returns (uint256) {
    return _totalSupply.sub(balanceOf(stakingContract));
  }

  function index() public view returns (uint256) {
    return balanceForGons(INDEX);
  }

  function transfer(address to, uint256 value) public override returns (bool) {
    uint256 gonValue = value.mul(_gonsPerFragment);
    _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
    _gonBalances[to] = _gonBalances[to].add(gonValue);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function allowance(address owner_, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowedValue[owner_][spender];
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public override returns (bool) {
    _allowedValue[from][msg.sender] = _allowedValue[from][msg.sender].sub(
      value
    );
    emit Approval(from, msg.sender, _allowedValue[from][msg.sender]);

    uint256 gonValue = gonsForBalance(value);
    _gonBalances[from] = _gonBalances[from].sub(gonValue);
    _gonBalances[to] = _gonBalances[to].add(gonValue);
    emit Transfer(from, to, value);

    return true;
  }

  function approve(address spender, uint256 value)
    public
    override
    returns (bool)
  {
    _allowedValue[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  // What gets called in a permit
  function _approve(
    address owner,
    address spender,
    uint256 value
  ) internal virtual override {
    _allowedValue[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    override
    returns (bool)
  {
    _allowedValue[msg.sender][spender] = _allowedValue[msg.sender][spender].add(
      addedValue
    );
    emit Approval(msg.sender, spender, _allowedValue[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    override
    returns (bool)
  {
    uint256 oldValue = _allowedValue[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedValue[msg.sender][spender] = 0;
    } else {
      _allowedValue[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedValue[msg.sender][spender]);
    return true;
  }
}


// File contracts/StakingWarmup.sol
pragma solidity 0.7.5;

contract StakingWarmup {
  address public immutable staking;
  address public immutable sHADES;

  constructor(address _staking, address _sHADES) {
    require(_staking != address(0));
    staking = _staking;
    require(_sHADES != address(0));
    sHADES = _sHADES;
  }

  function retrieve(address _staker, uint256 _amount) external {
    require(msg.sender == staking);
    IERC20(sHADES).transfer(_staker, _amount);
  }
}


// File contracts/Staking.sol
pragma solidity 0.7.5;







contract Staking is Ownable {
  using SafeMath for uint256;

  address public immutable HADES;
  address public immutable sHADES;

  struct Epoch {
    uint256 length;
    uint256 number;
    uint256 endBlock;
    uint256 distribute;
  }
  Epoch public epoch;

  address public distributor;

  address public locker;
  uint256 public totalBonus;

  address public warmupContract;
  uint256 public warmupPeriod;

  constructor(
    address _HADES,
    address _sHADES,
    uint256 _epochLength,
    uint256 _firstEpochNumber,
    uint256 _firstEpochBlock
  ) {
    require(_HADES != address(0));
    HADES = _HADES;
    require(_sHADES != address(0));
    sHADES = _sHADES;

    epoch = Epoch({
      length: _epochLength,
      number: _firstEpochNumber,
      endBlock: _firstEpochBlock,
      distribute: 0
    });
  }

  struct Claim {
    uint256 deposit;
    uint256 gons;
    uint256 expiry;
    bool lock; // prevents malicious delays
  }
  mapping(address => Claim) public warmupInfo;

  /**
        @notice stake HADES to enter warmup
        @param _amount uint
        @return bool
     */
  function stake(uint256 _amount, address _recipient) external returns (bool) {
    rebase();

    SafeERC20.safeTransferFrom(
      IERC20(HADES),
      msg.sender,
      address(this),
      _amount
    );

    Claim memory info = warmupInfo[_recipient];
    require(!info.lock, "Deposits for account are locked");

    warmupInfo[_recipient] = Claim({
      deposit: info.deposit.add(_amount),
      gons: info.gons.add(sHades(sHADES).gonsForBalance(_amount)),
      expiry: epoch.number.add(warmupPeriod),
      lock: false
    });

    SafeERC20.safeTransfer(IERC20(sHADES), warmupContract, _amount);
    return true;
  }

  /**
        @notice retrieve sHADES from warmup
        @param _recipient address
     */
  function claim(address _recipient) public {
    Claim memory info = warmupInfo[_recipient];
    if (epoch.number >= info.expiry && info.expiry != 0) {
      delete warmupInfo[_recipient];
      StakingWarmup(warmupContract).retrieve(
        _recipient,
        sHades(sHADES).balanceForGons(info.gons)
      );
    }
  }

  /**
        @notice forfeit sHADES in warmup and retrieve HADES
     */
  function forfeit() external {
    Claim memory info = warmupInfo[msg.sender];
    delete warmupInfo[msg.sender];

    StakingWarmup(warmupContract).retrieve(
      address(this),
      sHades(sHADES).balanceForGons(info.gons)
    );
    SafeERC20.safeTransfer(IERC20(HADES), msg.sender, info.deposit);
  }

  /**
        @notice prevent new deposits to address (protection from malicious activity)
     */
  function toggleDepositLock() external {
    warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
  }

  /**
        @notice redeem sHADES for HADES
        @param _amount uint
        @param _trigger bool
     */
  function unstake(uint256 _amount, bool _trigger) external {
    if (_trigger) {
      rebase();
    }
    SafeERC20.safeTransferFrom(
      IERC20(sHADES),
      msg.sender,
      address(this),
      _amount
    );
    SafeERC20.safeTransfer(IERC20(HADES), msg.sender, _amount);
  }

  /**
        @notice returns the sHADES index, which tracks rebase growth
        @return uint
     */
  function index() public view returns (uint256) {
    return sHades(sHADES).index();
  }

  /**
        @notice trigger rebase if epoch over
     */
  function rebase() public {
    if (epoch.endBlock <= block.number) {
      sHades(sHADES).rebase(epoch.distribute, epoch.number);

      epoch.endBlock = epoch.endBlock.add(epoch.length);
      epoch.number++;

      if (distributor != address(0)) {
        Distributor(distributor).distribute();
      }

      uint256 balance = contractBalance();
      uint256 staked = sHades(sHADES).circulatingSupply();

      if (balance <= staked) {
        epoch.distribute = 0;
      } else {
        epoch.distribute = balance.sub(staked);
      }
    }
  }

  /**
        @notice returns contract HADES holdings, including bonuses provided
        @return uint
     */
  function contractBalance() public view returns (uint256) {
    return IERC20(HADES).balanceOf(address(this)).add(totalBonus);
  }

  /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
  function giveLockBonus(uint256 _amount) external {
    require(msg.sender == locker);
    totalBonus = totalBonus.add(_amount);
    SafeERC20.safeTransfer(IERC20(sHADES), locker, _amount);
  }

  /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
  function returnLockBonus(uint256 _amount) external {
    require(msg.sender == locker);
    totalBonus = totalBonus.sub(_amount);
    SafeERC20.safeTransferFrom(IERC20(sHADES), locker, address(this), _amount);
  }

  enum CONTRACTS {
    DISTRIBUTOR,
    WARMUP,
    LOCKER
  }

  /**
        @notice sets the contract address for LP staking
        @param _contract address
     */
  function setContract(CONTRACTS _contract, address _address)
    external
    onlyOwner
  {
    if (_contract == CONTRACTS.DISTRIBUTOR) {
      // 0
      distributor = _address;
    } else if (_contract == CONTRACTS.WARMUP) {
      // 1
      require(
        warmupContract == address(0),
        "Warmup cannot be set more than once"
      );
      warmupContract = _address;
    } else if (_contract == CONTRACTS.LOCKER) {
      // 2
      require(locker == address(0), "Locker cannot be set more than once");
      locker = _address;
    }
  }

  /**
   * @notice set warmup period for new stakers
   * @param _warmupPeriod uint
   */
  function setWarmup(uint256 _warmupPeriod) external onlyOwner {
    warmupPeriod = _warmupPeriod;
  }
}


// File contracts/StakingHelper.sol
pragma solidity 0.7.5;


contract StakingHelper {
  address public immutable staking;
  address public immutable HADES;

  constructor(address _staking, address _HADES) {
    require(_staking != address(0));
    staking = _staking;
    require(_HADES != address(0));
    HADES = _HADES;
  }

  function stake(uint256 _amount, address _recipient) external {
    IERC20(HADES).transferFrom(msg.sender, address(this), _amount);
    IERC20(HADES).approve(staking, _amount);
    Staking(staking).stake(_amount, _recipient);
    Staking(staking).claim(_recipient);
  }
}


// File contracts/BondDepository.sol
pragma solidity 0.7.5;











contract BondDepository is Ownable {
  using FixedPoint for *;
  using SafeMath for uint256;

  /* ======== EVENTS ======== */

  event BondCreated(
    uint256 deposit,
    uint256 indexed payout,
    uint256 indexed expires,
    uint256 indexed priceInUSD
  );
  event BondRedeemed(
    address indexed recipient,
    uint256 payout,
    uint256 remaining
  );
  event BondPriceChanged(
    uint256 indexed priceInUSD,
    uint256 indexed internalPrice,
    uint256 indexed debtRatio
  );
  event ControlVariableAdjustment(
    uint256 initialBCV,
    uint256 newBCV,
    uint256 adjustment,
    bool addition
  );

  /* ======== STATE VARIABLES ======== */

  address public immutable HADES; // token given as payment for bond
  address public immutable principle; // token used to create bond
  address public immutable treasury; // mints HADES when receives principle
  address public immutable DAO; // receives profit share from bond

  bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
  address public immutable bondCalculator; // calculates value of LP tokens

  address public staking; // to auto-stake payout
  address public stakingHelper; // to stake and claim if no staking warmup
  bool public useHelper;

  Terms public terms; // stores terms for new bonds
  Adjust public adjustment; // stores adjustment to BCV data

  mapping(address => Bond) public bondInfo; // stores bond information for depositors

  uint256 public totalDebt; // total value of outstanding bonds; used for pricing
  uint256 public lastDecay; // reference block for debt decay

  /* ======== STRUCTS ======== */

  // Info for creating new bonds
  struct Terms {
    uint256 controlVariable; // scaling variable for price
    uint256 vestingTerm; // in blocks
    uint256 minimumPrice; // vs principle value
    uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
    uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
    uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
  }

  // Info for bond holder
  struct Bond {
    uint256 payout; // HADES remaining to be paid
    uint256 vesting; // Blocks left to vest
    uint256 lastBlock; // Last interaction
    uint256 pricePaid; // In DAI, for front end viewing
  }

  // Info for incremental adjustments to control variable
  struct Adjust {
    bool add; // addition or subtraction
    uint256 rate; // increment
    uint256 target; // BCV when adjustment finished
    uint256 buffer; // minimum length (in blocks) between adjustments
    uint256 lastBlock; // block when last adjustment made
  }

  /* ======== INITIALIZATION ======== */

  constructor(
    address _HADES,
    address _principle,
    address _treasury,
    address _DAO,
    address _bondCalculator
  ) {
    require(_HADES != address(0));
    HADES = _HADES;
    require(_principle != address(0));
    principle = _principle;
    require(_treasury != address(0));
    treasury = _treasury;
    require(_DAO != address(0));
    DAO = _DAO;
    // bondCalculator should be address(0) if not LP bond
    bondCalculator = _bondCalculator;
    isLiquidityBond = (_bondCalculator != address(0));
  }

  /**
   *  @notice initializes bond parameters
   *  @param _controlVariable uint
   *  @param _vestingTerm uint
   *  @param _minimumPrice uint
   *  @param _maxPayout uint
   *  @param _fee uint
   *  @param _maxDebt uint
   *  @param _initialDebt uint
   */
  function initializeBondTerms(
    uint256 _controlVariable,
    uint256 _vestingTerm,
    uint256 _minimumPrice,
    uint256 _maxPayout,
    uint256 _fee,
    uint256 _maxDebt,
    uint256 _initialDebt
  ) external onlyOwner {
    require(terms.controlVariable == 0, "Bonds must be initialized from 0");
    terms = Terms({
      controlVariable: _controlVariable,
      vestingTerm: _vestingTerm,
      minimumPrice: _minimumPrice,
      maxPayout: _maxPayout,
      fee: _fee,
      maxDebt: _maxDebt
    });
    totalDebt = _initialDebt;
    lastDecay = block.number;
  }

  /* ======== POLICY FUNCTIONS ======== */

  enum PARAMETER {
    VESTING,
    PAYOUT,
    FEE,
    DEBT
  }

  /**
   *  @notice set parameters for new bonds
   *  @param _parameter PARAMETER
   *  @param _input uint
   */
  function setBondTerms(PARAMETER _parameter, uint256 _input)
    external
    onlyOwner
  {
    if (_parameter == PARAMETER.VESTING) {
      // 0
      require(_input >= 10000, "Vesting must be longer than 36 hours");
      terms.vestingTerm = _input;
    } else if (_parameter == PARAMETER.PAYOUT) {
      // 1
      require(_input <= 1000, "Payout cannot be above 1 percent");
      terms.maxPayout = _input;
    } else if (_parameter == PARAMETER.FEE) {
      // 2
      require(_input <= 10000, "DAO fee cannot exceed payout");
      terms.fee = _input;
    } else if (_parameter == PARAMETER.DEBT) {
      // 3
      terms.maxDebt = _input;
    }
  }

  /**
   *  @notice set control variable adjustment
   *  @param _addition bool
   *  @param _increment uint
   *  @param _target uint
   *  @param _buffer uint
   */
  function setAdjustment(
    bool _addition,
    uint256 _increment,
    uint256 _target,
    uint256 _buffer
  ) external onlyOwner {
    require(
      _increment <= terms.controlVariable.mul(25).div(1000),
      "Increment too large"
    );

    adjustment = Adjust({
      add: _addition,
      rate: _increment,
      target: _target,
      buffer: _buffer,
      lastBlock: block.number
    });
  }

  /**
   *  @notice set contract for auto stake
   *  @param _staking address
   *  @param _helper bool
   */
  function setStaking(address _staking, bool _helper) external onlyOwner {
    require(_staking != address(0));
    if (_helper) {
      useHelper = true;
      stakingHelper = _staking;
    } else {
      useHelper = false;
      staking = _staking;
    }
  }

  /* ======== USER FUNCTIONS ======== */

  /**
   *  @notice deposit bond
   *  @param _amount uint
   *  @param _maxPrice uint
   *  @param _depositor address
   *  @return uint
   */
  function deposit(
    uint256 _amount,
    uint256 _maxPrice,
    address _depositor
  ) external returns (uint256) {
    require(_depositor != address(0), "Invalid address");

    decayDebt();
    require(totalDebt <= terms.maxDebt, "Max capacity reached");

    uint256 priceInUSD = bondPriceInUSD(); // Stored in bond info
    uint256 nativePrice = _bondPrice();

    require(_maxPrice >= nativePrice, "Slippage limit: more than max price"); // slippage protection

    uint256 value = Treasury(treasury).valueOfToken(principle, _amount);
    uint256 payout = payoutFor(value); // payout to bonder is computed

    require(payout >= 10000000, "Bond too small"); // must be > 0.01 HADES ( underflow protection )
    require(payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

    // profits are calculated
    uint256 fee = payout.mul(terms.fee).div(10000);
    uint256 profit = value.sub(payout).sub(fee);

    /**
            principle is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) HADES
         */
    SafeERC20.safeTransferFrom(
      IERC20(principle),
      msg.sender,
      address(this),
      _amount
    );
    IERC20(principle).approve(address(treasury), _amount);
    Treasury(treasury).deposit(_amount, principle, profit, false);

    if (fee != 0) {
      // fee is transferred to dao
      SafeERC20.safeTransfer(IERC20(HADES), DAO, fee);
    }

    // total debt is increased
    totalDebt = totalDebt.add(value);

    // depositor info is stored
    bondInfo[_depositor] = Bond({
      payout: bondInfo[_depositor].payout.add(payout),
      vesting: terms.vestingTerm,
      lastBlock: block.number,
      pricePaid: priceInUSD
    });

    // indexed events are emitted
    emit BondCreated(
      _amount,
      payout,
      block.number.add(terms.vestingTerm),
      priceInUSD
    );
    emit BondPriceChanged(bondPriceInUSD(), _bondPrice(), debtRatio());

    adjust(); // control variable is adjusted
    return payout;
  }

  /**
   *  @notice redeem bond for user
   *  @param _recipient address
   *  @param _stake bool
   *  @return uint
   */
  function redeem(address _recipient, bool _stake) external returns (uint256) {
    Bond memory info = bondInfo[_recipient];
    uint256 percentVested = percentVestedFor(_recipient); // (blocks since last interaction / vesting term remaining)

    if (percentVested >= 10000) {
      // if fully vested
      delete bondInfo[_recipient]; // delete user info
      emit BondRedeemed(_recipient, info.payout, 0); // emit bond data
      return stakeOrSend(_recipient, _stake, info.payout); // pay user everything due
    } else {
      // if unfinished
      // calculate payout vested
      uint256 payout = info.payout.mul(percentVested).div(10000);

      // store updated deposit info
      bondInfo[_recipient] = Bond({
        payout: info.payout.sub(payout),
        vesting: info.vesting.sub(block.number.sub(info.lastBlock)),
        lastBlock: block.number,
        pricePaid: info.pricePaid
      });

      emit BondRedeemed(_recipient, payout, bondInfo[_recipient].payout);
      return stakeOrSend(_recipient, _stake, payout);
    }
  }

  /* ======== INTERNAL HELPER FUNCTIONS ======== */

  /**
   *  @notice allow user to stake payout automatically
   *  @param _stake bool
   *  @param _amount uint
   *  @return uint
   */
  function stakeOrSend(
    address _recipient,
    bool _stake,
    uint256 _amount
  ) internal returns (uint256) {
    if (!_stake) {
      // if user does not want to stake
      IERC20(HADES).transfer(_recipient, _amount); // send payout
    } else {
      // if user wants to stake
      if (useHelper) {
        // use if staking warmup is 0
        IERC20(HADES).approve(stakingHelper, _amount);
        StakingHelper(stakingHelper).stake(_amount, _recipient);
      } else {
        IERC20(HADES).approve(staking, _amount);
        Staking(staking).stake(_amount, _recipient);
      }
    }
    return _amount;
  }

  /**
   *  @notice makes incremental adjustment to control variable
   */
  function adjust() internal {
    uint256 blockCanAdjust = adjustment.lastBlock.add(adjustment.buffer);
    if (adjustment.rate != 0 && block.number >= blockCanAdjust) {
      uint256 initial = terms.controlVariable;
      if (adjustment.add) {
        terms.controlVariable = terms.controlVariable.add(adjustment.rate);
        if (terms.controlVariable >= adjustment.target) {
          adjustment.rate = 0;
        }
      } else {
        terms.controlVariable = terms.controlVariable.sub(adjustment.rate);
        if (terms.controlVariable <= adjustment.target) {
          adjustment.rate = 0;
        }
      }
      adjustment.lastBlock = block.number;
      emit ControlVariableAdjustment(
        initial,
        terms.controlVariable,
        adjustment.rate,
        adjustment.add
      );
    }
  }

  /**
   *  @notice reduce total debt
   */
  function decayDebt() internal {
    totalDebt = totalDebt.sub(debtDecay());
    lastDecay = block.number;
  }

  /* ======== VIEW FUNCTIONS ======== */

  /**
   *  @notice determine maximum bond size
   *  @return uint
   */
  function maxPayout() public view returns (uint256) {
    return IERC20(HADES).totalSupply().mul(terms.maxPayout).div(100000);
  }

  /**
   *  @notice calculate interest due for new bond
   *  @param _value uint
   *  @return uint
   */
  function payoutFor(uint256 _value) public view returns (uint256) {
    return FixedPoint.fraction(_value, bondPrice()).decode112with18().div(1e16);
  }

  /**
   *  @notice calculate current bond premium
   *  @return price_ uint
   */
  function bondPrice() public view returns (uint256 price_) {
    price_ = terms.controlVariable.mul(debtRatio()).add(1000000000).div(1e7);
    if (price_ < terms.minimumPrice) {
      price_ = terms.minimumPrice;
    }
  }

  /**
   *  @notice calculate current bond price and remove floor if above
   *  @return price_ uint
   */
  function _bondPrice() internal returns (uint256 price_) {
    price_ = terms.controlVariable.mul(debtRatio()).add(1000000000).div(1e7);
    if (price_ < terms.minimumPrice) {
      price_ = terms.minimumPrice;
    } else if (terms.minimumPrice != 0) {
      terms.minimumPrice = 0;
    }
  }

  /**
   *  @notice converts bond price to DAI value
   *  @return price_ uint
   */
  function bondPriceInUSD() public view returns (uint256 price_) {
    if (isLiquidityBond) {
      price_ = bondPrice()
        .mul(BondingCalculator(bondCalculator).markdown(principle))
        .div(100);
    } else {
      price_ = bondPrice().mul(10**ERC20(principle).decimals()).div(100);
    }
  }

  /**
   *  @notice calculate current ratio of debt to HADES supply
   *  @return debtRatio_ uint
   */
  function debtRatio() public view returns (uint256 debtRatio_) {
    uint256 supply = IERC20(HADES).totalSupply();
    debtRatio_ = FixedPoint
      .fraction(currentDebt().mul(1e9), supply)
      .decode112with18()
      .div(1e18);
  }

  /**
   *  @notice debt ratio in same terms for reserve or liquidity bonds
   *  @return uint
   */
  function standardizedDebtRatio() external view returns (uint256) {
    if (isLiquidityBond) {
      return
        debtRatio()
          .mul(BondingCalculator(bondCalculator).markdown(principle))
          .div(1e9);
    } else {
      return debtRatio();
    }
  }

  /**
   *  @notice calculate debt factoring in decay
   *  @return uint
   */
  function currentDebt() public view returns (uint256) {
    return totalDebt.sub(debtDecay());
  }

  /**
   *  @notice amount to decay total debt by
   *  @return decay_ uint
   */
  function debtDecay() public view returns (uint256 decay_) {
    uint256 blocksSinceLast = block.number.sub(lastDecay);
    decay_ = totalDebt.mul(blocksSinceLast).div(terms.vestingTerm);
    if (decay_ > totalDebt) {
      decay_ = totalDebt;
    }
  }

  /**
   *  @notice calculate how far into vesting a depositor is
   *  @param _depositor address
   *  @return percentVested_ uint
   */
  function percentVestedFor(address _depositor)
    public
    view
    returns (uint256 percentVested_)
  {
    Bond memory bond = bondInfo[_depositor];
    uint256 blocksSinceLast = block.number.sub(bond.lastBlock);
    uint256 vesting = bond.vesting;

    if (vesting > 0) {
      percentVested_ = blocksSinceLast.mul(10000).div(vesting);
    } else {
      percentVested_ = 0;
    }
  }

  /**
   *  @notice calculate amount of HADES available for claim by depositor
   *  @param _depositor address
   *  @return pendingPayout_ uint
   */
  function pendingPayoutFor(address _depositor)
    external
    view
    returns (uint256 pendingPayout_)
  {
    uint256 percentVested = percentVestedFor(_depositor);
    uint256 payout = bondInfo[_depositor].payout;

    if (percentVested >= 10000) {
      pendingPayout_ = payout;
    } else {
      pendingPayout_ = payout.mul(percentVested).div(10000);
    }
  }

  /* ======= AUXILLIARY ======= */

  /**
   *  @notice allow anyone to send lost tokens (excluding principle or HADES) to the DAO
   *  @return bool
   */
  function recoverLostToken(address _token) external returns (bool) {
    require(_token != HADES);
    require(_token != principle);
    SafeERC20.safeTransfer(
      IERC20(_token),
      DAO,
      IERC20(_token).balanceOf(address(this))
    );
    return true;
  }
}