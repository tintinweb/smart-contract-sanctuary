/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract FITToken is ERC20, Ownable {

  using SafeMath for uint256;

  uint256 public constant INITIAL_TOKEN_PRICE = 10**14;
  uint256 public constant INITIAL_SUPPLY_PRICE = 200 ether; 
  uint256 public constant MIN_PRICE = 0.01 ether;

  uint256 public constant TOKEN_PRICE_INCREASING_MONTHLY_PERCENT = 100;
  uint256 public constant TOKEN_PRICE_INCREASING_PERIOD = 30 days;

  uint256 public BUY_TOKENS_MARKUP_PERCENT = 20;
  uint256 public REINVEST_TOKENS_MARKUP_PERCENT = 10;
  uint256 public SELL_TOKENS_DISCOUNT_PERCENT = 20;

  uint256[6] public REFERRAL_PERCENTS = [5, 3, 2, 1, 1, 1]; // 13%
  uint256 public REFERRAL_TOTAL_PERCENT;

  uint256 public constant SERVICE_PERCENT = 10;
  uint256 public constant LIQUIDITY_PERCENT = 3;
  address payable public serviceAddress;

  address payable public constant DEFAULT_REFERRER = payable(0xda002E82937f0b31b63e1721701E6A6BfE4D81d5);
  address payable public constant INITIAL_LIQUIDITY = payable(0xa28cb54105F31B9B504CA510b37E4A9e5b3FA81f);

  uint256 public totalPlayers;
  uint256 public totalInvested;
  uint256 public totalPayout;
  uint256 public totalTokensBought;
  uint256 public turnover;

  uint256 public totalReferralReward;

  struct Player {
    uint256 time;
    uint256 balance;
    uint256 deposit;
    uint256 payout;

    address referrer;
    uint256 referralReward;
    uint256[6] referralNumbers;
  }

  mapping(address => Player) public players;

  uint256 private periodStartTime;
  uint256 private periodStartPrice = INITIAL_TOKEN_PRICE;

  uint256 constant public TIME_STEP = 1 days;
  uint256 constant public PERCENTS_DIVIDER = 10000;

  address public flipTokenContractAddress = address(0x0);

  struct Stake {
    uint256 amount;
    uint256 checkpoint;
    uint256 checkpointHold;
    uint256 accumulatedReward;
    uint256 withdrawnReward;
  }
  mapping (address => Stake) stakes;

  // HOLD bonus
  uint256 constant public HOLD_BONUS_PERCENT_STAKE = 500; // 1% //TODO: change
  uint256 constant public HOLD_BONUS_PERCENT_LIMIT = 10000; // 100% //TODO: change

  // VIP bonus
  uint256 constant public USER_DEPOSITS_STEP_STAKE = 100 ether; // 1000 LPs //TODO: change
  uint256 constant public VIP_BONUS_PERCENT_STAKE = 100; // 1% //TODO: change
  uint256 constant public VIP_BONUS_PERCENT_LIMIT = 10000; // 100% //TODO: change

  uint256 public MULTIPLIER = 4;

  event PriceChange(uint256 oldPrice, uint256 newPrice, uint256 time);

  // Staking
  event Staked(address indexed user, uint256 amount);
  event Unstaked(address indexed user, uint256 amount);
  event RewardWithdrawn(address indexed user, uint256 reward);

  event NewReferral(address indexed user, address indexed referral, uint256 amount, uint256 time);

  constructor() ERC20("Fractal Investment Token", "FIT") {
    serviceAddress = DEFAULT_REFERRER;
    players[serviceAddress].time = block.timestamp;
    periodStartTime = block.timestamp;
    register(serviceAddress, serviceAddress);
    _mint(INITIAL_LIQUIDITY, INITIAL_SUPPLY_PRICE.mul(10 ** uint256(decimals())).div(INITIAL_TOKEN_PRICE));

    // Calculate total referral program percent
    for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      REFERRAL_TOTAL_PERCENT = REFERRAL_TOTAL_PERCENT.add(REFERRAL_PERCENTS[i]);
    }
  }

  function register(address _addr, address _referrer) private {
    Player storage player = players[_addr];
    player.referrer = _referrer;

    address ref = _referrer;
    for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      if (ref == serviceAddress) {
        break;
      }
      players[ref].referralNumbers[i] = players[ref].referralNumbers[i].add(1);

      ref = players[ref].referrer;
    }
  }

  function buy(address _referredBy) public payable {
    require(msg.value >= MIN_PRICE, "Invalid buy price");
    Player storage player = players[msg.sender];

    if (player.time == 0) {
      player.time = block.timestamp;
      totalPlayers++;
      if (_referredBy != address(0x0) && players[_referredBy].deposit > 0){
        register(msg.sender, _referredBy);

        emit NewReferral(msg.sender, _referredBy, msg.value, block.timestamp);
      } else {
        register(msg.sender, serviceAddress);
      }
    }
    player.deposit = player.deposit.add(msg.value);

    if (block.timestamp.sub(periodStartTime) >= TOKEN_PRICE_INCREASING_PERIOD) {
      uint256 oldPrice = price();
      periodStartPrice = periodStartPrice.mul(2);
      periodStartTime = block.timestamp;
      emit PriceChange(oldPrice, price(), block.timestamp);
    }

    uint256 tokensAmount = msg.value
      .mul(10 ** uint256(decimals()))
      .div(buyPrice());
    _mint(msg.sender, tokensAmount);

    distributeRef(msg.value, player.referrer);

    totalInvested = totalInvested.add(msg.value);
    totalTokensBought = totalTokensBought.add(tokensAmount);

    payable(owner()).transfer(msg.value.mul(SERVICE_PERCENT).div(100));
    payable(INITIAL_LIQUIDITY).transfer(msg.value.mul(LIQUIDITY_PERCENT).div(100));
  }

  /**
   * Liquifies tokens to the balance.
   */
  function sell(uint256 _amount) public {
    require(balanceOf(msg.sender) >= _amount, "Not enough tokens on the balance");
    Player storage player = players[msg.sender];
    if (player.time == 0) {
      player.time = block.timestamp;
      totalPlayers++;
      register(msg.sender, serviceAddress);
    }

    if (block.timestamp.sub(periodStartTime) >= TOKEN_PRICE_INCREASING_PERIOD) {
      uint256 oldPrice = price();
      periodStartPrice = periodStartPrice.mul(2);
      periodStartTime = block.timestamp;
      emit PriceChange(oldPrice, price(), block.timestamp);
    }

    player.balance = player.balance.add(
      _amount
        .mul(sellPrice())
        .div(10 ** uint256(decimals()))
    );
    _burn(msg.sender, _amount);
  }

  /**
   * Converts all of caller's dividends to tokens.
   */
  function reinvest() public {
    require(players[msg.sender].time > 0, "You didn't buy tokens yet");
    Player storage player = players[msg.sender];

    require(player.balance > 0, "Nothing to reinvest");

    if (block.timestamp.sub(periodStartTime) >= TOKEN_PRICE_INCREASING_PERIOD) {
      uint256 oldPrice = price();
      periodStartPrice = periodStartPrice.mul(2);
      periodStartTime = block.timestamp;
      emit PriceChange(oldPrice, price(), block.timestamp);
    }

    uint256 trxAmount = player.balance;
    uint256 tokensAmount = trxAmount
      .mul(10 ** uint256(decimals()))
      .div(reinvestPrice());
    player.balance = 0;
    _mint(msg.sender, tokensAmount);

    distributeRef(trxAmount, player.referrer);

    totalInvested = totalInvested.add(trxAmount);
    player.deposit = player.deposit.add(trxAmount);
    totalTokensBought = totalTokensBought.add(tokensAmount);

    payable(owner()).transfer(trxAmount.mul(SERVICE_PERCENT).div(100));
  }

  /**
   * Withdraws all of the callers earnings.
   */
  function withdraw() public {
    require(players[msg.sender].time > 0, "You didn't buy tokens yet");
    require(players[msg.sender].balance > 0, "Nothing to withdraw");
    Player storage player = players[msg.sender];
    
    uint256 amount = player.balance;
    player.balance = 0;
    player.payout = player.payout.add(amount);

    totalPayout = totalPayout.add(amount);

    payable(msg.sender).transfer(amount);
  }

  /**
   * Current token price getter.
   */
  function price() public view returns (uint256) {
    return periodStartPrice.add(
      periodStartPrice
        .mul(TOKEN_PRICE_INCREASING_MONTHLY_PERCENT)
        .mul(block.timestamp.sub(periodStartTime))
        .div(TOKEN_PRICE_INCREASING_PERIOD)
        .div(100)
    );
  }

  function buyPrice() public view returns (uint256) {
    return price()
      .mul(100 + BUY_TOKENS_MARKUP_PERCENT)
      .div(100);
  }

  function reinvestPrice() public view returns (uint256) {
    return price()
      .mul(100 + REINVEST_TOKENS_MARKUP_PERCENT)
      .div(100);
  }

  function sellPrice() public view returns (uint256) {
    return price()
      .mul(100 - SELL_TOKENS_DISCOUNT_PERCENT)
      .div(100);
  }

  /**
   * Distribute referrals rewards.
   */
  function distributeRef(uint256 _amount, address _referrer) private {
    uint256 totalReward = (_amount.mul(REFERRAL_TOTAL_PERCENT)).div(100);

    address ref = _referrer;
    uint256 refReward;
    for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      refReward = _amount.mul(REFERRAL_PERCENTS[i]).div(100);
      totalReward = totalReward.sub(refReward);

      players[ref].referralReward = players[ref].referralReward.add(refReward);
      totalReferralReward = totalReferralReward.add(refReward);

      if (refReward > 0) {
        if (ref != address(0x0)) {
          payable(ref).transfer(refReward);
        } else {
          serviceAddress.transfer(refReward);
        }
      }

      ref = players[ref].referrer;
    }

    if (totalReward > 0) {
      serviceAddress.transfer(totalReward);
    }
  }

  /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

  function changeServiceAddress(address payable _address) public onlyOwner {
    require(_address != address(0x0), "Invalid address");
    require(_address != serviceAddress, "Nothing to change");

    serviceAddress = _address;
    players[serviceAddress].time = block.timestamp;
    register(serviceAddress, serviceAddress);
  }

  /*----------  DAPP VIEW FUNCTIONS  ----------*/

  function getStatistics() public view returns (uint256[10] memory) {
    return [
      totalPlayers,
      totalInvested,
      totalPayout,
      totalTokensBought,

      totalReferralReward,

      price(),
      buyPrice(),
      reinvestPrice(),
      sellPrice(),

      turnover
    ];
  }

  function getReferralNumbersByLevels(address _address) public view returns(uint256[6] memory) {
    return players[_address].referralNumbers;
  }

  /*----------  STAKING  ----------*/

  function setFlipTokenContractAddress(address _flipTokenContractAddress) external onlyOwner {
    require(flipTokenContractAddress == address(0x0), "LP token address already configured");
    require(isContract(_flipTokenContractAddress), "Provided address is not an LP token contract address");

    flipTokenContractAddress = _flipTokenContractAddress;
  }

  function getStakeVIPBonusRate(address userAddress) public view returns (uint256) {
    uint256 vipBonusRate = stakes[userAddress].amount.div(USER_DEPOSITS_STEP_STAKE).mul(VIP_BONUS_PERCENT_STAKE);

    if (vipBonusRate > VIP_BONUS_PERCENT_LIMIT) {
      return VIP_BONUS_PERCENT_LIMIT;
    }

    return vipBonusRate;
  }

  function getStakeHOLDBonusRate(address userAddress) public view returns (uint256) {
    if (stakes[userAddress].checkpointHold == 0) {
      return 0;
    }

    uint256 holdBonusRate = (block.timestamp.sub(stakes[userAddress].checkpointHold)).div(TIME_STEP).mul(HOLD_BONUS_PERCENT_STAKE);

    if (holdBonusRate > HOLD_BONUS_PERCENT_LIMIT) {
      return HOLD_BONUS_PERCENT_LIMIT;
    }

    return holdBonusRate;
  }

  function getUserStakePercentRate(address userAddress) public view returns (uint256) {
    return getStakeVIPBonusRate(userAddress)
      .add(getStakeHOLDBonusRate(userAddress));
  }

  function stake(uint256 _amount) external returns (bool) {
    require(_amount > 0, "Invalid tokens amount value");

    if (!IERC20(flipTokenContractAddress).transferFrom(msg.sender, address(this), _amount)) {
      return false;
    }

    uint256 reward = availableReward(msg.sender);
    if (reward > 0) {
      stakes[msg.sender].accumulatedReward = stakes[msg.sender].accumulatedReward.add(reward);
    }

    stakes[msg.sender].amount = stakes[msg.sender].amount.add(_amount);
    stakes[msg.sender].checkpoint = block.timestamp;
    if (stakes[msg.sender].checkpointHold == 0) {
      stakes[msg.sender].checkpointHold = block.timestamp;
    }

    emit Staked(msg.sender, _amount);

    return true;
  }

  function availableReward(address userAddress) public view returns (uint256) {
    uint256 userPercentRate = getUserStakePercentRate(userAddress);

    return (stakes[userAddress].amount
      .mul(PERCENTS_DIVIDER.add(userPercentRate)).div(PERCENTS_DIVIDER))
      .mul(MULTIPLIER)
      .mul(block.timestamp.sub(stakes[userAddress].checkpoint))
      .div(TIME_STEP);
  }

  function withdrawReward() external {
    uint256 reward = stakes[msg.sender].accumulatedReward
      .add(availableReward(msg.sender));

    if (reward > 0) {
      // Distribute tokens
      stakes[msg.sender].checkpoint = block.timestamp;
      stakes[msg.sender].accumulatedReward = 0;
      stakes[msg.sender].withdrawnReward = stakes[msg.sender].withdrawnReward.add(reward);

      _mint(msg.sender, reward);

      emit RewardWithdrawn(msg.sender, reward);
    }
  }

  function unstake(uint256 _amount) external {
    require(_amount > 0, "Invalid tokens amount value");
    require(_amount <= stakes[msg.sender].amount, "Not enough tokens on the stake balance");

    uint256 reward = availableReward(msg.sender);
    if (reward > 0) {
      stakes[msg.sender].accumulatedReward = stakes[msg.sender].accumulatedReward.add(reward);
    }

    stakes[msg.sender].amount = stakes[msg.sender].amount.sub(_amount);
    stakes[msg.sender].checkpoint = block.timestamp;
    if (stakes[msg.sender].amount > 0) {
      stakes[msg.sender].checkpointHold = block.timestamp;
    } else {
      stakes[msg.sender].checkpointHold = 0; // Should be renewed next stake of this token
    }

    require(IERC20(flipTokenContractAddress).transfer(msg.sender, _amount));

    emit Unstaked(msg.sender, _amount);
  }

  function getUserStakeStats(address _userAddress) public view
    returns (uint256, uint256, uint256, uint256, uint256)
  {
    return (
      stakes[_userAddress].amount,
      stakes[_userAddress].accumulatedReward,
      stakes[_userAddress].withdrawnReward,
      getStakeVIPBonusRate(_userAddress),
      getStakeHOLDBonusRate(_userAddress)
    );
  }

  function getUserStakeTimeCheckpoints(address _userAddress) public view returns (uint256, uint256) {
    return (
      stakes[_userAddress].checkpoint,
      stakes[_userAddress].checkpointHold
    );
  }

  function updateMultiplier(uint256 multiplier) public onlyOwner {
    require(multiplier > 0 && multiplier <= 50, "Multiplier is out of range");

    MULTIPLIER = multiplier;
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  function buy() external payable {
    payable(msg.sender).transfer(msg.value);
  }

}