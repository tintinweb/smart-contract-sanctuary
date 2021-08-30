/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

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


// File contracts/ShrubExchange.sol


contract ShrubExchange {

  enum OptionType {
    PUT,
    CALL
  }

  // Data that is common between a buy and sell
  struct OrderCommon {
    address baseAsset;      // ETH-USD, USD is the base
    address quoteAsset;     // ETH-USD ETH is the quote
    uint expiry;            // timestamp expires
    uint strike;            // The price of the pair
    OptionType optionType;
  }

  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }


  // Meant to be hashed with OrderCommon
  struct SmallOrder {
    uint size;              // number of contracts in terms of the smallest unit of the quoteAsset (i.e. 1e18 for 1 ETH call contract)
    bool isBuy;
    uint nonce;             // unique id of order
    uint price;             // total price of the order in terms of the smallest unit of the baseAsset (i.e. 200e6 for an order costing a total of 200 USDC) (price goes up with size)
    uint offerExpire;       // time this order expires
    uint fee;               // matcherFee in terms of wei
  }

  struct Order {
    uint size;
    bool isBuy;
    uint nonce;             // unique id of order
    uint price;
    uint offerExpire;       // time this order expires
    uint fee;               // matcherFee

    address baseAsset;      // ETH-USD, USD is the base
    address quoteAsset;     // ETH-USD ETH is the quote
    uint expiry;            // timestamp expires
    uint strike;            // The price of the pair in terms of the exercise price in the baseAsset times 1e6 (i.e. 2000e6 for a 2000 USDC strike price)
    OptionType optionType;
  }

  event Deposit(address user, address token, uint amount);
  event Withdraw(address user, address token, uint amount);
  event OrderAnnounce(OrderCommon indexed common, bytes32 indexed positionHash, SmallOrder order, Signature sig);
  event OrderMatched(address indexed seller, address indexed buyer, bytes32 positionHash, SmallOrder sellOrder, SmallOrder buyOrder, OrderCommon common);
  mapping(address => mapping(address => mapping(address => uint))) public userPairNonce;
  mapping(address => mapping(address => uint)) public userTokenBalances;
  mapping(address => mapping(address => uint)) public userTokenLockedBalance;

  mapping(bytes32 => mapping(address => uint256)) public positionPoolTokenBalance;
  mapping(bytes32 => uint256) public positionPoolTokenTotalSupply;

  mapping(address => mapping(bytes32 => int)) public userOptionPosition;

  address private constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

  // Used to shift price and strike up and down by factors of 1 million
  uint private constant BASE_SHIFT = 1000000;

  bytes32 public constant SALT = keccak256("0x43efba454ccb1b6fff2625fe562bdd9a23260359");
  bytes public constant EIP712_DOMAIN = "EIP712Domain(string name, string version, uint256 chainId, address verifyingContract, bytes32 salt)";
  bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(EIP712_DOMAIN);
  bytes32 public constant DOMAIN_SEPARATOR = keccak256(abi.encode(
    EIP712_DOMAIN_TYPEHASH,
    keccak256("Shrub Trade"),
    keccak256("1"),
    1,
    0x6e80C53f2cdCad7843aD765E4918298427AaC550,
    SALT
  ));

  bytes32 public constant ORDER_TYPEHASH = keccak256("Order(uint size, address signer, bool isBuy, uint nonce, uint price, uint offerExpire, uint fee, address baseAsset, address quoteAsset, uint expiry, uint strike, OptionType optionType)");

  bytes32 public constant COMMON_TYPEHASH = keccak256("OrderCommon(address baseAsset, address quoteAsset, uint expiry, uint strike, OptionType optionType)");

  function min(uint256 a, uint256 b) pure private returns (uint256) {
    return a < b ? a : b;
  }

  function hashOrder(Order memory order) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      ORDER_TYPEHASH,
      order.size,
      order.isBuy,
      order.nonce,
      order.price,
      order.offerExpire,
      order.fee,

      order.baseAsset,
      order.quoteAsset,
      order.expiry,
      order.strike,
      order.optionType
    ));
  }


  function hashSmallOrder(SmallOrder memory order, OrderCommon memory common) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      ORDER_TYPEHASH,
      order.size,
      order.isBuy,
      order.nonce,
      order.price,
      order.offerExpire,
      order.fee,

      common.baseAsset,
      common.quoteAsset,
      common.expiry,
      common.strike,
      common.optionType
    ));
  }

  function hashOrderCommon(OrderCommon memory common) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(
      COMMON_TYPEHASH,
      common.baseAsset,
      common.quoteAsset,
      common.expiry,
      common.strike,
      common.optionType
    ));
  }

  function getCurrentNonce(address user, address quoteAsset, address baseAsset) public view returns(uint) {
    return userPairNonce[user][quoteAsset][baseAsset];
  }

  function getAvailableBalance(address user, address asset) public view returns(uint) {
    return userTokenBalances[user][asset] - userTokenLockedBalance[user][asset];
  }

  function getSignedHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function validateSignature(address user, bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns(bool) {
    bytes32 payloadHash = getSignedHash(hash);
    return ecrecover(payloadHash, v, r, s) == user;
  }

  function checkOrderMatches(SmallOrder memory sellOrder, SmallOrder memory buyOrder) internal view returns (bool) {
    bool matches = true;
    matches = matches && sellOrder.isBuy == false;
    matches = matches && buyOrder.isBuy == true;

    matches = matches && sellOrder.price <= buyOrder.price;
    matches = matches && sellOrder.offerExpire >= block.timestamp;
    matches = matches && buyOrder.offerExpire >= block.timestamp;
    return matches;
  }

  function getAddressFromSignedOrder(SmallOrder memory order, OrderCommon memory common, Signature memory sig) public pure returns(address) {
    address recovered = ecrecover(getSignedHash(hashSmallOrder(order, common)), sig.v, sig.r, sig.s);
    require(recovered != ZERO_ADDRESS, "Invalid signature, recovered ZERO_ADDRESS");
    return recovered;
  }

  function deposit(address token, uint amount) public payable {
    if(token != ZERO_ADDRESS) {
      require(ERC20(token).transferFrom(msg.sender, address(this), amount), "Must succeed in taking tokens");
      userTokenBalances[msg.sender][token] += amount;
    }
    if(msg.value > 0) {
      userTokenBalances[msg.sender][token] += msg.value;
    }
    emit Deposit(msg.sender, token, amount);
  }

  function depositAndMatch(address token, uint amount, SmallOrder memory sellOrder, SmallOrder memory buyOrder, OrderCommon memory common, Signature memory sellSig, Signature memory buySig) public payable {
    deposit(token, amount);
    matchOrder(sellOrder, buyOrder, common, sellSig, buySig);
  }

  function depositAndAnnounce(address token, uint amount, SmallOrder memory order, OrderCommon memory common, Signature memory sig) public payable {
    deposit(token, amount);
    announce(order, common, sig);
  }


  function depositAndMatchMany(address token, uint amount, SmallOrder[] memory sellOrders, SmallOrder[] memory buyOrders, OrderCommon[] memory commons, Signature[] memory sellSigs, Signature[] memory buySigs) public payable {
    deposit(token, amount);
    matchOrders(sellOrders, buyOrders, commons, sellSigs, buySigs);
  }

  function withdraw(address token, uint amount) public {
    uint balance = getAvailableBalance(msg.sender, token);
    require(amount <= balance, "Cannot withdraw more than available balance");
    userTokenBalances[msg.sender][token] -= amount;
    if(token == ZERO_ADDRESS) {
      payable(msg.sender).transfer(amount);
    } else {
      require(ERC20(token).transfer(msg.sender, amount), "ERC20 transfer must succeed");
    }
    emit Withdraw(msg.sender, token, amount);
  }

  function matchOrder(SmallOrder memory sellOrder, SmallOrder memory buyOrder, OrderCommon memory common, Signature memory sellSig, Signature memory buySig) public {
    (address buyer, address seller, bytes32 positionHash) = doPartialMatch(sellOrder, buyOrder, common, sellSig, buySig);
    emit OrderMatched(seller, buyer, positionHash, sellOrder, buyOrder, common);
    userPairNonce[buyer][common.quoteAsset][common.baseAsset] = buyOrder.nonce;
    userPairNonce[seller][common.quoteAsset][common.baseAsset] = sellOrder.nonce;
  }


  function adjustWithRatio(uint number, uint partsPerMillion) internal pure returns (uint) {
    return (number * partsPerMillion) / BASE_SHIFT;
  }


  function getAdjustedPriceAndFillSize(SmallOrder memory sellOrder, SmallOrder memory buyOrder) internal pure returns (uint, uint) {
    uint fillSize = sellOrder.size < buyOrder.size ?  sellOrder.size : buyOrder.size;
    uint adjustedPrice = fillSize * sellOrder.price / sellOrder.size;

    return (fillSize, adjustedPrice);
  }

  function doPartialMatch(SmallOrder memory sellOrder, SmallOrder memory buyOrder, OrderCommon memory common, Signature memory sellSig, Signature memory buySig)
  internal returns(address, address, bytes32) {
    require(checkOrderMatches(sellOrder, buyOrder), "Buy and sell order do not match");
    address seller = getAddressFromSignedOrder(sellOrder, common, sellSig);
    address buyer = getAddressFromSignedOrder(buyOrder, common, buySig);
    require(seller != buyer, "Seller and Buyer must be different");
    bytes32 positionHash = hashOrderCommon(common);

    require(getCurrentNonce(seller, common.quoteAsset, common.baseAsset) == sellOrder.nonce - 1, "Seller nonce incorrect");
    require(getCurrentNonce(buyer, common.quoteAsset, common.baseAsset) == buyOrder.nonce - 1, "Buyer nonce incorrect");

    (uint fillSize, uint adjustedPrice) = getAdjustedPriceAndFillSize(sellOrder, buyOrder);

    if(common.optionType == OptionType.CALL) {
      require(getAvailableBalance(seller, common.quoteAsset) >= fillSize, "Call Seller must have enough free collateral");
      require(getAvailableBalance(buyer, common.baseAsset) >= adjustedPrice, "Call Buyer must have enough free collateral");

      userTokenLockedBalance[seller][common.quoteAsset] += fillSize;
      positionPoolTokenBalance[positionHash][common.quoteAsset] += fillSize;
      positionPoolTokenTotalSupply[positionHash] += fillSize;

      userTokenBalances[seller][common.baseAsset] += adjustedPrice;
      userTokenBalances[buyer][common.baseAsset] -= adjustedPrice;


      // unlock buyer's collateral if this user was short
      if(userOptionPosition[buyer][positionHash] < 0 && userTokenLockedBalance[buyer][common.quoteAsset] > 0) {
        userTokenLockedBalance[buyer][common.quoteAsset] -= min(fillSize, userTokenLockedBalance[buyer][common.quoteAsset]);
      }
    }

    if(common.optionType == OptionType.PUT) {
      uint lockedCapital = adjustWithRatio(fillSize, common.strike);

      require(getAvailableBalance(seller, common.baseAsset) >= lockedCapital, "Put Seller must have enough free collateral");
      require(getAvailableBalance(buyer, common.quoteAsset) >= adjustedPrice, "Put Buyer must have enough free collateral");

      userTokenLockedBalance[seller][common.baseAsset] += lockedCapital;
      positionPoolTokenBalance[positionHash][common.baseAsset] += lockedCapital;
      positionPoolTokenTotalSupply[positionHash] += lockedCapital;

      userTokenBalances[seller][common.quoteAsset] += adjustedPrice;
      userTokenBalances[buyer][common.quoteAsset] -= adjustedPrice;

      // unlock buyer's collateral if this user was short
      if(userOptionPosition[buyer][positionHash] < 0 && userTokenLockedBalance[buyer][common.baseAsset] > 0) {
        userTokenLockedBalance[buyer][common.baseAsset] -= min(lockedCapital, userTokenLockedBalance[buyer][common.baseAsset]);
      }
    }

    userOptionPosition[seller][positionHash] -= int(fillSize);
    userOptionPosition[buyer][positionHash] += int(fillSize);

    return (buyer, seller, positionHash);
  }

  function matchOrders(SmallOrder[] memory sellOrders, SmallOrder[] memory buyOrders, OrderCommon[] memory commons, Signature[] memory sellSigs, Signature[] memory buySigs) public {
    uint sellIndex = 0;
    uint buyIndex = 0;
    uint sellFilled = 0;
    uint buyFilled = 0;
    uint sellsLen = sellOrders.length;
    uint buysLen = buyOrders.length;
    while(sellIndex < sellOrders.length && buyIndex < buysLen) {
      SmallOrder memory sellOrder = sellOrders[sellIndex];
      OrderCommon memory common = commons[sellIndex];
      Signature memory sellSig = sellSigs[sellIndex];
      SmallOrder memory buyOrder = buyOrders[buyIndex];
      Signature memory buySig = buySigs[buyIndex];
      (address buyer, address seller, bytes32 positionHash) = doPartialMatch(sellOrder, buyOrder, common, sellSig, buySig);

      if(sellOrder.size - sellFilled >= buyOrder.size - buyFilled) {
        sellFilled += buyOrder.size;
        buyIndex++;
        if(sellFilled == sellOrder.size || buyIndex == buysLen) {
          sellIndex++;
          userPairNonce[seller][common.quoteAsset][common.baseAsset] = sellOrder.nonce;
          // calculate remainder of selling order and add it to internal offers
          sellFilled = 0;
        }
        emit OrderMatched(seller, buyer, positionHash, sellOrder, buyOrder, common);
        userPairNonce[buyer][common.quoteAsset][common.baseAsset] = buyOrder.nonce;
      } else if (sellOrder.size - sellFilled < buyOrder.size - buyFilled) {
        buyFilled += sellOrder.size;
        sellIndex++;
        if(buyFilled == buyOrder.size || sellIndex == sellsLen) {
          buyIndex++;
          userPairNonce[buyer][common.quoteAsset][common.baseAsset] = buyOrder.nonce;
          // calculate remainder of buying order and add it to internal offers
          buyFilled = 0;
        }
        emit OrderMatched(seller, buyer, positionHash, sellOrder, buyOrder, common);
        userPairNonce[seller][common.quoteAsset][common.baseAsset] = sellOrder.nonce;
      }
    }
  }

  function exercise(uint256 buyOrderSize, OrderCommon memory common) public payable {
    address buyer = msg.sender;
    bytes32 positionHash = hashOrderCommon(common);

    require(userOptionPosition[buyer][positionHash] > 0, "Must have an open position to exercise");
    require(userOptionPosition[buyer][positionHash] >= int(buyOrderSize), "Cannot exercise more than owned");
    require(int(buyOrderSize) > 0, "buyOrderSize is too large");
    require(common.expiry >= block.timestamp, "Option has already expired");

    // user has exercised this many
    userOptionPosition[buyer][positionHash] -= int(buyOrderSize);

    uint256 totalPaid = adjustWithRatio(buyOrderSize, common.strike);

    if(common.optionType == OptionType.CALL) {
      require(positionPoolTokenBalance[positionHash][common.quoteAsset] >= buyOrderSize, "Pool must have enough funds");
      require(userTokenBalances[buyer][common.baseAsset] >= totalPaid, "Buyer must have enough funds to exercise CALL");

      // deduct the quoteAsset from the pool
      positionPoolTokenBalance[positionHash][common.quoteAsset] -= buyOrderSize;

      // Reduce seller's locked capital and token balance of quote asset
      userTokenBalances[buyer][common.quoteAsset] += buyOrderSize;

      // Give the seller the buyer's funds, in terms of baseAsset
      positionPoolTokenBalance[positionHash][common.baseAsset] += totalPaid;

      // deduct strike * size from buyer
      userTokenBalances[buyer][common.baseAsset] -= totalPaid;
    }
    if(common.optionType == OptionType.PUT) {
      require(positionPoolTokenBalance[positionHash][common.baseAsset] >= totalPaid, "Pool must have enough funds");
      require(userTokenBalances[buyer][common.quoteAsset] >= buyOrderSize, "Buyer must have enough funds to exercise PUT");

      // deduct baseAsset from pool
      positionPoolTokenBalance[positionHash][common.baseAsset] -= totalPaid;

      // increase exercisee balance by strike * size
      userTokenBalances[buyer][common.baseAsset] += totalPaid;

      // credit the pool the amount of quote asset sold
      positionPoolTokenBalance[positionHash][common.quoteAsset] += buyOrderSize;

      // deduct balance of tokens sold
      userTokenBalances[buyer][common.quoteAsset] -= buyOrderSize;
    }
  }

  function claim(OrderCommon memory common) public {
    bytes32 positionHash = hashOrderCommon(common);
    require(userOptionPosition[msg.sender][positionHash] < 0, "Must have sold an option to claim");
    require(common.expiry < block.timestamp, "Cannot claim until options are expired");

    uint256 poolOwnership =  uint256(-1 * userOptionPosition[msg.sender][positionHash]);

    if(common.optionType == OptionType.CALL) {
      // reset quoteAsset locked balance
      userTokenLockedBalance[msg.sender][common.quoteAsset] -= poolOwnership;
      userTokenBalances[msg.sender][common.quoteAsset] -= poolOwnership;
    }
    
    if(common.optionType == OptionType.PUT) {
      // reset baseAsset locked balance
      userTokenLockedBalance[msg.sender][common.baseAsset] -= poolOwnership;
      userTokenBalances[msg.sender][common.baseAsset] -= poolOwnership;
    }

    uint256 totalSupply = positionPoolTokenTotalSupply[positionHash];

    uint256 quoteBalance = positionPoolTokenBalance[positionHash][common.quoteAsset];
    uint256 quoteBalanceOwed = poolOwnership / totalSupply * quoteBalance;

    uint256 baseBalance = positionPoolTokenBalance[positionHash][common.baseAsset];
    uint256 baseBalanceOwed = poolOwnership / totalSupply * baseBalance;

    userTokenBalances[msg.sender][common.baseAsset] += baseBalanceOwed;
    userTokenBalances[msg.sender][common.quoteAsset] += quoteBalanceOwed;

    // reduce pool size by amount claimed
    positionPoolTokenTotalSupply[positionHash] -= poolOwnership;
    userOptionPosition[msg.sender][positionHash] = 0;
  }

  function announce(SmallOrder memory order, OrderCommon memory common, Signature memory sig) public {
    bytes32 positionHash = hashOrderCommon(common);
    address user = getAddressFromSignedOrder(order, common, sig);
    require(getCurrentNonce(user, common.quoteAsset, common.baseAsset) == order.nonce - 1, "User nonce incorrect");

    if(common.optionType == OptionType.CALL) {
      if(order.isBuy) {
        require(getAvailableBalance(user, common.baseAsset) >= order.price, "Call Buyer must have enough free collateral");
      } else {
        require(getAvailableBalance(user, common.quoteAsset) >= order.size, "Call Seller must have enough free collateral");
      }
    }

    if(common.optionType == OptionType.PUT) {
      if(order.isBuy) {
        require(getAvailableBalance(user, common.quoteAsset) >= order.price, "Put Buyer must have enough free collateral");
      } else {
        require(getAvailableBalance(user, common.baseAsset) >= adjustWithRatio(order.size, common.strike), "Put Seller must have enough free collateral");
      }
    }

    emit OrderAnnounce(common, positionHash, order, sig);
  }


  function announceMany(SmallOrder[] memory orders, OrderCommon[] memory commons, Signature[] memory sigs) public {
    require(orders.length == commons.length, "Array length mismatch");
    require(orders.length == sigs.length, "Array length mismatch");
    for(uint i = 0; i < orders.length; i++) {
      announce(orders[i], commons[i], sigs[i]);
    }
  }
}