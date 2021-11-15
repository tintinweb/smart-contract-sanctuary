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

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.7.6;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;
    address payable public developer;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);
    constructor () {
        developer = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }
    modifier onlyAdminOrDeveloper() {
        require(msg.sender == admin || msg.sender == developer, "caller must be admin or developer");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual {
        require(msg.sender == pendingAdmin, "only pendingAdmin can accept admin");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

pragma experimental ABIEncoderV2;

import "./liquidity/LPoolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./dex/DexAggregatorInterface.sol";

contract ControllerStorage {

    //lpool-pair
    struct LPoolPair {
        address lpool0;
        address lpool1;
    }
    //lpool-distribution
    struct LPoolDistribution {
        uint64 startTime;
        uint64 endTime;
        uint64 duration;
        uint64 lastUpdateTime;
        uint256 totalRewardAmount;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
        uint256 extraTotalToken;
    }
    //lpool-rewardByAccount
    struct LPoolRewardByAccount {
        uint rewardPerTokenStored;
        uint rewards;
        uint extraToken;
    }

    struct OLETokenDistribution {
        uint supplyBorrowBalance;
        uint extraBalance;
        uint128 updatePricePer;
        uint128 liquidatorMaxPer;
        uint16 liquidatorOLERatio;//300=>300%
        uint16 xoleRaiseRatio;//150=>150%
        uint128 xoleRaiseMinAmount;
    }

    IERC20 public oleToken;

    address public xoleToken;

    address public wETH;

    address public lpoolImplementation;

    //interest param
    uint256 public baseRatePerBlock;
    uint256 public multiplierPerBlock;
    uint256 public jumpMultiplierPerBlock;
    uint256 public kink;

    address public openLev;

    DexAggregatorInterface public dexAggregator;

    bool public suspend;

    OLETokenDistribution public oleTokenDistribution;
    //token0=>token1=>pair
    mapping(address => mapping(address => LPoolPair)) public lpoolPairs;
    //marketId=>isDistribution
    mapping(uint => bool) public marketExtraDistribution;
    //marketId=>isDistribution
    mapping(uint => bool) public marketSuspend;
    //pool=>allowed
    mapping(address => bool) public lpoolUnAlloweds;
    //pool=>bool=>distribution(true is borrow,false is supply)
    mapping(LPoolInterface => mapping(bool => LPoolDistribution)) public lpoolDistributions;
    //pool=>bool=>distribution(true is borrow,false is supply)
    mapping(LPoolInterface => mapping(bool => mapping(address => LPoolRewardByAccount))) public lPoolRewardByAccounts;

    event LPoolPairCreated(address token0, address pool0, address token1, address pool1, uint16 marketId, uint16 marginLimit, bytes dexData);

    event Distribution2Pool(address pool, uint supplyAmount, uint borrowerAmount, uint64 startTime, uint64 duration);

}
/**
  * @title Controller
  * @author OpenLeverage
  */
interface ControllerInterface {

    function createLPoolPair(address tokenA, address tokenB, uint16 marginLimit, bytes memory dexData) external;

    /*** Policy Hooks ***/

    function mintAllowed(address lpool, address minter, uint lTokenAmount) external;

    function transferAllowed(address lpool, address from, address to, uint lTokenAmount) external;

    function redeemAllowed(address lpool, address redeemer, uint lTokenAmount) external;

    function borrowAllowed(address lpool, address borrower, address payee, uint borrowAmount) external;

    function repayBorrowAllowed(address lpool, address payer, address borrower, uint repayAmount, bool isEnd) external;

    function liquidateAllowed(uint marketId, address liquidator, uint liquidateAmount, bytes memory dexData) external;

    function marginTradeAllowed(uint marketId) external view returns (bool);

    function updatePriceAllowed(uint marketId) external;

    /*** Admin Functions ***/

    function setLPoolImplementation(address _lpoolImplementation) external;

    function setOpenLev(address _openlev) external;

    function setDexAggregator(DexAggregatorInterface _dexAggregator) external;

    function setInterestParam(uint256 _baseRatePerBlock, uint256 _multiplierPerBlock, uint256 _jumpMultiplierPerBlock, uint256 _kink) external;

    function setLPoolUnAllowed(address lpool, bool unAllowed) external;

    function setSuspend(bool suspend) external;

    function setMarketSuspend(uint marketId, bool suspend) external;

    // liquidatorOLERatio: Two decimal in percentage, ex. 300% => 300
    function setOLETokenDistribution(uint moreSupplyBorrowBalance, uint moreExtraBalance, uint128 updatePricePer, uint128 liquidatorMaxPer, uint16 liquidatorOLERatio, uint16 xoleRaiseRatio, uint128 xoleRaiseMinAmount) external;

    function distributeRewards2Pool(address pool, uint supplyAmount, uint borrowAmount, uint64 startTime, uint64 duration) external;

    function distributeRewards2PoolMore(address pool, uint supplyAmount, uint borrowAmount) external;

    function distributeExtraRewards2Market(uint marketId, bool isDistribution) external;

    /***Distribution Functions ***/

    function earned(LPoolInterface lpool, address account, bool isBorrow) external view returns (uint256);

    function getSupplyRewards(LPoolInterface[] calldata lpools, address account) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./ControllerInterface.sol";
import "./liquidity/LPoolDelegator.sol";
import "./Adminable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./DelegateInterface.sol";
import "./lib/DexData.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
  * @title Controller
  * @author OpenLeverage
  */
contract ControllerV1 is DelegateInterface, ControllerInterface, ControllerStorage, Adminable {
    using SafeMath for uint;

    constructor () {}

    function initialize(
        IERC20 _oleToken,
        address _xoleToken,
        address _wETH,
        address _lpoolImplementation,
        address _openlev,
        DexAggregatorInterface _dexAggregator
    ) public {
        require(msg.sender == admin, "not admin");
        oleToken = _oleToken;
        xoleToken = _xoleToken;
        wETH = _wETH;
        lpoolImplementation = _lpoolImplementation;
        openLev = _openlev;
        dexAggregator = _dexAggregator;
    }

    struct LPoolPairVar {
        address token0;
        address token1;
        uint16 marginLimit;
        bytes dexData;
        string tokenName;
        string tokenSymbol;
    }

    function createLPoolPair(address token0, address token1, uint16 marginLimit, bytes memory dexData) external override {
        require(token0 != token1, 'identical address');
        require(lpoolPairs[token0][token1].lpool0 == address(0) || lpoolPairs[token1][token0].lpool0 == address(0), 'pool pair exists');
        LPoolPairVar memory pairVar = LPoolPairVar(token0, token1, marginLimit, dexData, "OpenLeverage LToken", "LToken");
        LPoolDelegator pool0 = new LPoolDelegator();
        pool0.initialize(pairVar.token0, pairVar.token0 == wETH ? true : false, address(this), baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink, 1e18,
            pairVar.tokenName, pairVar.tokenSymbol, ERC20(pairVar.token0).decimals(), admin, lpoolImplementation);
        LPoolDelegator pool1 = new LPoolDelegator();
        pool1.initialize(pairVar.token1, pairVar.token1 == wETH ? true : false, address(this), baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink, 1e18,
            pairVar.tokenName, pairVar.tokenSymbol, ERC20(pairVar.token1).decimals(), admin, lpoolImplementation);
        lpoolPairs[token0][token1] = LPoolPair(address(pool0), address(pool1));
        lpoolPairs[token1][token0] = LPoolPair(address(pool0), address(pool1));
        uint16 marketId = (OPENLevInterface(openLev)).addMarket(LPoolInterface(address(pool0)), LPoolInterface(address(pool1)), pairVar.marginLimit, pairVar.dexData);
        emit LPoolPairCreated(pairVar.token0, address(pool0), pairVar.token1, address(pool1), marketId, pairVar.marginLimit, pairVar.dexData);
    }


    /*** Policy Hooks ***/
    function mintAllowed(address lpool, address minter, uint lTokenAmount) external override onlyLPoolSender(lpool) onlyLPoolAllowed(lpool) onlyNotSuspended() {
        stake(LPoolInterface(lpool), minter, lTokenAmount);
    }

    function transferAllowed(address lpool, address from, address to, uint lTokenAmount) external override onlyLPoolSender(lpool) {
        withdraw(LPoolInterface(lpool), from, lTokenAmount);
        stake(LPoolInterface(lpool), to, lTokenAmount);
    }

    function redeemAllowed(address lpool, address redeemer, uint lTokenAmount) external override onlyLPoolSender(lpool) onlyNotSuspended() {
        if (withdraw(LPoolInterface(lpool), redeemer, lTokenAmount)) {
            getRewardInternal(LPoolInterface(lpool), redeemer, false);
        }
    }

    function borrowAllowed(address lpool, address borrower, address payee, uint borrowAmount) external override onlyLPoolSender(lpool) onlyLPoolAllowed(lpool) onlyOpenLevOperator(payee) onlyNotSuspended() {
        require(LPoolInterface(lpool).availableForBorrow() >= borrowAmount, "Borrow out of range");
        updateReward(LPoolInterface(lpool), borrower, true);
    }

    function repayBorrowAllowed(address lpool, address payer, address borrower, uint repayAmount, bool isEnd) external override onlyLPoolSender(lpool) {
        // Shh - currently unused
        payer;
        repayAmount;
        if (isEnd) {
            require(openLev == payer, "Operator not openLev");
        }
        if (updateReward(LPoolInterface(lpool), borrower, true)) {
            getRewardInternal(LPoolInterface(lpool), borrower, true);
        }
    }

    function liquidateAllowed(uint marketId, address liquidator, uint liquidateAmount, bytes memory dexData) external override onlyOpenLevOperator(msg.sender) {
        require(!marketSuspend[marketId], 'Market suspended');
        // Shh - currently unused
        liquidateAmount;
        dexData;
        // market no distribution
        if (marketExtraDistribution[marketId] == false) {
            return;
        }
        // rewards is zero or balance not enough
        if (oleTokenDistribution.liquidatorMaxPer == 0) {
            return;
        }
        //get wETH quote ole price
        (uint256 price, uint8 decimal) = dexAggregator.getPrice(wETH, address(oleToken), DexData.UNIV2);
        // oleRewards=wETHValue*liquidatorOLERatio
        uint calcLiquidatorRewards = uint(600000)  // needs approximately 600k gas for liquidation
        .mul(tx.gasprice).mul(price).div(10 ** uint(decimal))
        .mul(oleTokenDistribution.liquidatorOLERatio).div(100);
        // check compare max
        if (calcLiquidatorRewards > oleTokenDistribution.liquidatorMaxPer) {
            calcLiquidatorRewards = oleTokenDistribution.liquidatorMaxPer;
        }
        if (calcLiquidatorRewards > oleTokenDistribution.extraBalance) {
            return;
        }
        if (transferOut(liquidator, calcLiquidatorRewards)) {
            oleTokenDistribution.extraBalance = oleTokenDistribution.extraBalance.sub(calcLiquidatorRewards);
        }
    }

    function marginTradeAllowed(uint marketId) external view override onlyNotSuspended() returns (bool){
        require(!marketSuspend[marketId], 'Market suspended');
        return true;
    }

    function updatePriceAllowed(uint marketId) external override onlyOpenLevOperator(msg.sender) {
        // Shh - currently unused
        marketId;
        // market no distribution
        if (marketExtraDistribution[marketId] == false) {
            return;
        }
        uint reward = oleTokenDistribution.updatePricePer;
        if (reward > oleTokenDistribution.extraBalance) {
            return;
        }
        if (transferOut(tx.origin, reward)) {
            oleTokenDistribution.extraBalance = oleTokenDistribution.extraBalance.sub(reward);
        }
    }

    /*** Distribution Functions ***/

    function initDistribution(uint totalAmount, uint64 startTime, uint64 duration) internal pure returns (ControllerStorage.LPoolDistribution memory distribution){
        distribution.startTime = startTime;
        distribution.endTime = startTime + duration;
        require(distribution.endTime >= startTime, 'EndTime is overflow');
        distribution.duration = duration;
        distribution.lastUpdateTime = startTime;
        distribution.totalRewardAmount = totalAmount;
        distribution.rewardRate = totalAmount.div(duration);
    }

    function updateDistribution(ControllerStorage.LPoolDistribution storage distribution, uint addAmount) internal {
        uint256 blockTime = block.timestamp;
        if (blockTime >= distribution.endTime) {
            distribution.rewardRate = addAmount.div(distribution.duration);
        } else {
            uint256 remaining = distribution.endTime - blockTime;
            uint256 leftover = remaining.mul(distribution.rewardRate);
            distribution.rewardRate = addAmount.add(leftover).div(distribution.duration);
        }
        distribution.lastUpdateTime = uint64(blockTime);
        distribution.totalRewardAmount = distribution.totalRewardAmount.add(addAmount);
        distribution.endTime = distribution.duration + uint64(blockTime);
        require(distribution.endTime > blockTime, 'EndTime is overflow');
    }

    function checkStart(LPoolInterface lpool, bool isBorrow) internal view returns (bool){
        return block.timestamp >= lpoolDistributions[lpool][isBorrow].startTime;
    }


    function existRewards(LPoolInterface lpool, bool isBorrow) internal view returns (bool){
        return lpoolDistributions[lpool][isBorrow].totalRewardAmount > 0;
    }

    function lastTimeRewardApplicable(LPoolInterface lpool, bool isBorrow) public view returns (uint256) {
        return Math.min(block.timestamp, lpoolDistributions[lpool][isBorrow].endTime);
    }

    function rewardPerToken(LPoolInterface lpool, bool isBorrow) internal view returns (uint256) {
        LPoolDistribution memory distribution = lpoolDistributions[lpool][isBorrow];
        uint totalAmount = isBorrow ? lpool.totalBorrowsCurrent() : lpool.totalSupply().add(distribution.extraTotalToken);
        if (totalAmount == 0) {
            return distribution.rewardPerTokenStored;
        }
        return
        distribution.rewardPerTokenStored.add(
            lastTimeRewardApplicable(lpool, isBorrow)
            .sub(distribution.lastUpdateTime)
            .mul(distribution.rewardRate)
            .mul(1e18)
            .div(totalAmount)
        );
    }

    function updateReward(LPoolInterface lpool, address account, bool isBorrow) internal returns (bool) {
        if (!existRewards(lpool, isBorrow) || !checkStart(lpool, isBorrow)) {
            return false;
        }
        uint rewardPerTokenStored = rewardPerToken(lpool, isBorrow);
        lpoolDistributions[lpool][isBorrow].rewardPerTokenStored = rewardPerTokenStored;
        lpoolDistributions[lpool][isBorrow].lastUpdateTime = uint64(lastTimeRewardApplicable(lpool, isBorrow));
        if (account != address(0)) {
            lPoolRewardByAccounts[lpool][isBorrow][account].rewards = earnedInternal(lpool, account, isBorrow);
            lPoolRewardByAccounts[lpool][isBorrow][account].rewardPerTokenStored = rewardPerTokenStored;
        }
        return true;
    }

    function stake(LPoolInterface lpool, address account, uint256 amount) internal returns (bool) {
        bool updateSucceed = updateReward(lpool, account, false);
        if (xoleToken == address(0) || XOleInterface(xoleToken).balanceOf(account, 0) < oleTokenDistribution.xoleRaiseMinAmount) {
            return updateSucceed;
        }
        uint addExtraToken = amount.mul(oleTokenDistribution.xoleRaiseRatio).div(100);
        lPoolRewardByAccounts[lpool][false][account].extraToken = lPoolRewardByAccounts[lpool][false][account].extraToken.add(addExtraToken);
        lpoolDistributions[lpool][false].extraTotalToken = lpoolDistributions[lpool][false].extraTotalToken.add(addExtraToken);
        return updateSucceed;
    }

    function withdraw(LPoolInterface lpool, address account, uint256 amount) internal returns (bool)  {
        bool updateSucceed = updateReward(lpool, account, false);
        if (xoleToken == address(0)) {
            return updateSucceed;
        }
        uint extraToken = lPoolRewardByAccounts[lpool][false][account].extraToken;
        if (extraToken == 0) {
            return updateSucceed;
        }
        uint oldBalance = lpool.balanceOf(account);
        //withdraw all
        if (oldBalance == amount) {
            lPoolRewardByAccounts[lpool][false][account].extraToken = 0;
            lpoolDistributions[lpool][false].extraTotalToken = lpoolDistributions[lpool][false].extraTotalToken.sub(extraToken);
        } else {
            uint subExtraToken = extraToken.mul(amount).div(oldBalance);
            lPoolRewardByAccounts[lpool][false][account].extraToken = extraToken.sub(subExtraToken);
            lpoolDistributions[lpool][false].extraTotalToken = lpoolDistributions[lpool][false].extraTotalToken.sub(subExtraToken);
        }
        return updateSucceed;
    }


    function earnedInternal(LPoolInterface lpool, address account, bool isBorrow) internal view returns (uint256) {
        LPoolRewardByAccount memory accountReward = lPoolRewardByAccounts[lpool][isBorrow][account];
        uint accountBalance = isBorrow ? lpool.borrowBalanceCurrent(account) : lpool.balanceOf(account).add(accountReward.extraToken);
        return
        accountBalance
        .mul(rewardPerToken(lpool, isBorrow).sub(accountReward.rewardPerTokenStored))
        .div(1e18)
        .add(accountReward.rewards);
    }

    function getRewardInternal(LPoolInterface lpool, address account, bool isBorrow) internal {
        uint256 reward = lPoolRewardByAccounts[lpool][isBorrow][account].rewards;
        if (reward > 0) {
            bool succeed = transferOut(account, reward);
            if (succeed) {
                lPoolRewardByAccounts[lpool][isBorrow][account].rewards = 0;
            }
        }
    }

    function earned(LPoolInterface lpool, address account, bool isBorrow) external override view returns (uint256) {
        if (!existRewards(lpool, isBorrow) || !checkStart(lpool, isBorrow)) {
            return 0;
        }
        return earnedInternal(lpool, account, isBorrow);
    }

    function getSupplyRewards(LPoolInterface[] calldata lpools, address account) external override {
        uint rewards;
        for (uint i = 0; i < lpools.length; i++) {
            if (updateReward(lpools[i], account, false)) {
                rewards = rewards.add(earnedInternal(lpools[i], account, false));
                lPoolRewardByAccounts[lpools[i]][false][account].rewards = 0;
            }
        }
        require(rewards > 0, 'rewards is zero');
        require(oleToken.balanceOf(address(this)) >= rewards, 'balance<rewards');
        oleToken.transfer(account, rewards);
    }


    function transferOut(address to, uint amount) internal returns (bool){
        if (oleToken.balanceOf(address(this)) < amount) {
            return false;
        }
        oleToken.transfer(to, amount);
        return true;
    }
    /*** Admin Functions ***/

    function setOLETokenDistribution(uint moreSupplyBorrowBalance, uint moreExtraBalance, uint128 updatePricePer, uint128 liquidatorMaxPer, uint16 liquidatorOLERatio, uint16 xoleRaiseRatio, uint128 xoleRaiseMinAmount) external override onlyAdmin {
        uint newSupplyBorrowBalance = oleTokenDistribution.supplyBorrowBalance.add(moreSupplyBorrowBalance);
        uint newExtraBalance = oleTokenDistribution.extraBalance.add(moreExtraBalance);
        uint totalAll = newExtraBalance.add(newSupplyBorrowBalance);
        require(oleToken.balanceOf(address(this)) >= totalAll, 'not enough balance');
        oleTokenDistribution.supplyBorrowBalance = newSupplyBorrowBalance;
        oleTokenDistribution.extraBalance = newExtraBalance;
        oleTokenDistribution.updatePricePer = updatePricePer;
        oleTokenDistribution.liquidatorMaxPer = liquidatorMaxPer;
        oleTokenDistribution.liquidatorOLERatio = liquidatorOLERatio;
        oleTokenDistribution.xoleRaiseRatio = xoleRaiseRatio;
        oleTokenDistribution.xoleRaiseMinAmount = xoleRaiseMinAmount;
    }

    function distributeRewards2Pool(address pool, uint supplyAmount, uint borrowAmount, uint64 startTime, uint64 duration) external override onlyAdmin {
        require(supplyAmount > 0 || borrowAmount > 0, 'amount is less than 0');
        require(startTime > block.timestamp, 'startTime < blockTime');
        if (supplyAmount > 0) {
            require(lpoolDistributions[LPoolInterface(pool)][false].startTime == 0, 'Distribute only once');
            lpoolDistributions[LPoolInterface(pool)][false] = initDistribution(supplyAmount, startTime, duration);
        }
        if (borrowAmount > 0) {
            require(lpoolDistributions[LPoolInterface(pool)][true].startTime == 0, 'Distribute only once');
            lpoolDistributions[LPoolInterface(pool)][true] = initDistribution(borrowAmount, startTime, duration);
        }
        uint subAmount = supplyAmount.add(borrowAmount);
        oleTokenDistribution.supplyBorrowBalance = oleTokenDistribution.supplyBorrowBalance.sub(subAmount);
        emit Distribution2Pool(pool, supplyAmount, borrowAmount, startTime, duration);
    }

    function distributeRewards2PoolMore(address pool, uint supplyAmount, uint borrowAmount) external override onlyAdmin {
        require(supplyAmount > 0 || borrowAmount > 0, 'amount0 and amount1 is 0');
        if (supplyAmount > 0) {
            updateReward(LPoolInterface(pool), address(0), false);
            updateDistribution(lpoolDistributions[LPoolInterface(pool)][false], supplyAmount);
        }
        if (borrowAmount > 0) {
            updateReward(LPoolInterface(pool), address(0), true);
            updateDistribution(lpoolDistributions[LPoolInterface(pool)][true], borrowAmount);
        }
        bool isBorrowMore = borrowAmount > 0 ? true : false;
        uint subAmount = supplyAmount.add(borrowAmount);
        oleTokenDistribution.supplyBorrowBalance = oleTokenDistribution.supplyBorrowBalance.sub(subAmount);
        emit Distribution2Pool(pool, supplyAmount, borrowAmount, lpoolDistributions[LPoolInterface(pool)][isBorrowMore].startTime, lpoolDistributions[LPoolInterface(pool)][isBorrowMore].duration);
    }

    function distributeExtraRewards2Market(uint marketId, bool isDistribution) external override onlyAdminOrDeveloper {
        marketExtraDistribution[marketId] = isDistribution;
    }

    function setLPoolImplementation(address _lpoolImplementation) external override onlyAdmin {
        require(address(0) != _lpoolImplementation, '0x');
        lpoolImplementation = _lpoolImplementation;
    }

    function setOpenLev(address _openlev) external override onlyAdmin {
        require(address(0) != _openlev, '0x');
        openLev = _openlev;
    }

    function setDexAggregator(DexAggregatorInterface _dexAggregator) external override onlyAdmin {
        require(address(0) != address(_dexAggregator), '0x');
        dexAggregator = _dexAggregator;
    }

    function setInterestParam(uint256 _baseRatePerBlock, uint256 _multiplierPerBlock, uint256 _jumpMultiplierPerBlock, uint256 _kink) external override onlyAdmin {
        require(_baseRatePerBlock < 1e13 && _multiplierPerBlock < 1e13 && _jumpMultiplierPerBlock < 1e13 && _kink <= 1e18, 'PRI');
        baseRatePerBlock = _baseRatePerBlock;
        multiplierPerBlock = _multiplierPerBlock;
        jumpMultiplierPerBlock = _jumpMultiplierPerBlock;
        kink = _kink;
    }

    function setLPoolUnAllowed(address lpool, bool unAllowed) external override onlyAdminOrDeveloper {
        lpoolUnAlloweds[lpool] = unAllowed;
    }

    function setSuspend(bool _uspend) external override onlyAdminOrDeveloper {
        suspend = _uspend;
    }

    function setMarketSuspend(uint marketId, bool suspend) external override onlyAdminOrDeveloper {
        marketSuspend[marketId] = suspend;
    }
    modifier onlyLPoolSender(address lPool) {
        require(msg.sender == lPool, "Sender not lPool");
        _;
    }
    modifier onlyLPoolAllowed(address lPool) {
        require(!lpoolUnAlloweds[lPool], "LPool paused");
        _;
    }
    modifier onlyNotSuspended() {
        require(!suspend, 'Suspended');
        _;
    }
    modifier onlyOpenLevOperator(address operator) {
        require(openLev == operator || openLev == address(0), "Operator not openLev");
        _;
    }

}

interface OPENLevInterface {
    function addMarket(
        LPoolInterface pool0,
        LPoolInterface pool1,
        uint16 marginLimit,
        bytes memory dexData
    ) external returns (uint16);
}

interface XOleInterface {
    function balanceOf(address addr, uint256 _t) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


contract DelegateInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


abstract contract DelegatorInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;

    /**
     * Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public virtual;


    /**
    * Internal method to delegate execution to another contract
    * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    * @param callee The contract to delegatecall
    * @param data The raw data to delegatecall
    * @return The returned bytes from the delegatecall
    */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {revert(add(returnData, 0x20), returndatasize())}
        }
        return returnData;
    }

    /**
     * Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {revert(add(returnData, 0x20), returndatasize())}
        }
        return abi.decode(returnData, (bytes));
    }
    /**
    * Delegates execution to an implementation contract
    * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    */
    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        // delegate all other functions to current implementation
        if (msg.data.length > 0) {
            (bool success,) = implementation.delegatecall(msg.data);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize())
                switch success
                case 0 {revert(free_mem_ptr, returndatasize())}
                default {return (free_mem_ptr, returndatasize())}
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface DexAggregatorInterface {

    function sell(address buyToken, address sellToken, uint sellAmount, uint minBuyAmount, bytes memory data) external returns (uint buyAmount);

    function sellMul(uint sellAmount, uint minBuyAmount, bytes memory data) external returns (uint buyAmount);

    function buy(address buyToken, address sellToken, uint buyAmount, uint maxSellAmount, bytes memory data) external returns (uint sellAmount);

    function calBuyAmount(address buyToken, address sellToken, uint sellAmount, bytes memory data) external view returns (uint);

    function calSellAmount(address buyToken, address sellToken, uint buyAmount, bytes memory data) external view returns (uint);

    function getPrice(address desToken, address quoteToken, bytes memory data) external view returns (uint256 price, uint8 decimals);

    function getAvgPrice(address desToken, address quoteToken, uint32 secondsAgo, bytes memory data) external view returns (uint256 price, uint8 decimals, uint256 timestamp);

    //cal current avg price and get history avg price
    function getPriceCAvgPriceHAvgPrice(address desToken, address quoteToken, uint32 secondsAgo, bytes memory dexData) external view returns (uint price, uint cAvgPrice, uint256 hAvgPrice, uint8 decimals, uint256 timestamp);

    function updatePriceOracle(address desToken, address quoteToken, uint32 timeWindow, bytes memory data) external returns(bool);

    function updateV3Observation(address desToken, address quoteToken, bytes memory data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;


library DexData {
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;


    uint constant dexNameStart = 0;
    uint constant dexNameLength = 1;
    uint constant feeStart = 1;
    uint constant feeLength = 3;
    uint constant uniV3QuoteFlagStart = 4;
    uint constant uniV3QuoteFlagLength = 1;

    uint8 constant DEX_UNIV2 = 1;
    uint8 constant DEX_UNIV3 = 2;
    bytes constant UNIV2 = hex"01";
    //    bytes constant UNIV3_FEE0 = hex"02000000";

    struct V3PoolData {
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    function toDex(bytes memory data) internal pure returns (uint8) {
        require(data.length >= dexNameLength, 'dex error');
        uint8 temp;
        assembly {
            temp := byte(0, mload(add(data, add(0x20, dexNameStart))))
        }
        return temp;
    }

    function toFee(bytes memory data) internal pure returns (uint24) {
        require(data.length >= dexNameLength + feeLength, 'fee error');
        uint temp;
        assembly {
            temp := mload(add(data, add(0x20, feeStart)))
        }
        return uint24(temp >> (256 - (feeLength * 8)));
    }

    function toDexDetail(bytes memory data) internal pure returns (uint32) {
        if (data.length == dexNameLength) {
            uint8 temp;
            assembly {
                temp := byte(0, mload(add(data, add(0x20, dexNameStart))))
            }
            return uint32(temp);
        } else {
            uint temp;
            assembly {
                temp := mload(add(data, add(0x20, dexNameStart)))
            }
            return uint32(temp >> (256 - ((feeLength + dexNameLength) * 8)));
        }
    }
    // true ,sell all
    function toUniV3QuoteFlag(bytes memory data) internal pure returns (bool) {
        require(data.length >= dexNameLength + feeLength + uniV3QuoteFlagLength, 'v3flag error');
        uint8 temp;
        assembly {
            temp := byte(0, mload(add(data, add(0x20, uniV3QuoteFlagStart))))
        }
        return temp > 0;
    }
    // univ2 class
    function isUniV2Class(bytes memory data) internal pure returns (bool) {
        return (data.length - dexNameLength) % 20 == 0;
    }
    // v2 path
    function toUniV2Path(bytes memory data) internal pure returns (address[] memory path) {
        data = slice(data, dexNameLength, data.length - dexNameLength);
        uint pathLength = data.length / 20;
        path = new address[](pathLength);
        for (uint i = 0; i < pathLength; i++) {
            path[i] = toAddress(data, 20 * i);
        }
    }

    // v3 path
    function toUniV3Path(bytes memory data) internal pure returns (V3PoolData[] memory path) {
        data = slice(data, uniV3QuoteFlagStart + uniV3QuoteFlagLength, data.length - (uniV3QuoteFlagStart + uniV3QuoteFlagLength));
        uint pathLength = numPools(data);
        path = new V3PoolData[](pathLength);
        for (uint i = 0; i < pathLength; i++) {
            V3PoolData memory pool;
            if (i != 0) {
                data = slice(data, NEXT_OFFSET, data.length - NEXT_OFFSET);
            }
            pool.tokenA = toAddress(data, 0);
            pool.fee = toUint24(data, ADDR_SIZE);
            pool.tokenB = toAddress(data, NEXT_OFFSET);
            path[i] = pool;
        }
    }

    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }
        return tempUint;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;
        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }
        return tempAddress;
    }


    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


import "../Adminable.sol";
import "../DelegatorInterface.sol";


/**
 * @title Compound's LPoolDelegator Contract
 * LTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author Compound
 */
contract LPoolDelegator is DelegatorInterface, Adminable {


    constructor() {
        admin = msg.sender;
    }
    function initialize(address underlying_,
        bool isWethPool_,
        address contoller_,
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_,

        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address payable admin_,
        address implementation_) external onlyAdmin {
        require(implementation == address(0), "initialize once");
        // Creator of the contract is admin during initialization
        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation_, abi.encodeWithSignature("initialize(address,bool,address,uint256,uint256,uint256,uint256,uint256,string,string,uint8)",
            underlying_,
            isWethPool_,
            contoller_,
            baseRatePerYear,
            multiplierPerYear,
            jumpMultiplierPerYear,
            kink_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_));

        implementation = implementation_;

        // Set the proper admin now that initialization is done
        admin = admin_;
    }
    /**
     * Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public override onlyAdmin {
        address oldImplementation = implementation;
        implementation = implementation_;
        emit NewImplementation(oldImplementation, implementation);
    }


}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


abstract contract LPoolStorage {

    //Guard variable for re-entrancy checks
    bool internal _notEntered;

    /**
     * EIP-20 token name for this token
     */
    string public name;

    /**
     * EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
    * Total number of tokens in circulation
    */
    uint public totalSupply;


    //Official record of token balances for each account
    mapping(address => uint) internal accountTokens;

    //Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint)) internal transferAllowances;


    //Maximum borrow rate that can ever be applied (.0005% / block)
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
    * Maximum fraction of borrower cap(80%)
    */
    uint public  borrowCapFactorMantissa;
    /**
     * Contract which oversees inter-lToken operations
     */
    address public controller;


    // Initial exchange rate used when minting the first lTokens (used when totalSupply = 0)
    uint internal initialExchangeRateMantissa;

    /**
     * Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
    * @notice Fraction of interest currently set aside for reserves 20%
    */
    uint public reserveFactorMantissa;


    uint public totalReserves;


    address public underlying;

    bool public isWethPool;

    /**
     * Container for borrow balance information
     * principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    uint256 public baseRatePerBlock;
    uint256 public multiplierPerBlock;
    uint256 public jumpMultiplierPerBlock;
    uint256 public kink;

    // Mapping of account addresses to outstanding borrow balances

    mapping(address => BorrowSnapshot) internal accountBorrows;


    /*** Token Events ***/

    /**
    * Event emitted when tokens are minted
    */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** Market Events ***/

    /**
     * Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, address payee, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint badDebtsAmount, uint accountBorrows, uint totalBorrows);

    /*** Admin Events ***/

    /**
     * Event emitted when controller is changed
     */
    event NewController(address oldController, address newController);

    /**
     * Event emitted when interestParam is changed
     */
    event NewInterestParam(uint baseRatePerBlock, uint multiplierPerBlock, uint jumpMultiplierPerBlock, uint kink);

    /**
    * @notice Event emitted when the reserve factor is changed
    */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address to, uint reduceAmount, uint newTotalReserves);

    event NewBorrowCapFactorMantissa(uint oldBorrowCapFactorMantissa, uint newBorrowCapFactorMantissa);

}

abstract contract LPoolInterface is LPoolStorage {


    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);

    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);

    function approve(address spender, uint amount) external virtual returns (bool);

    function allowance(address owner, address spender) external virtual view returns (uint);

    function balanceOf(address owner) external virtual view returns (uint);

    function balanceOfUnderlying(address owner) external virtual returns (uint);

    /*** Lender & Borrower Functions ***/

    function mint(uint mintAmount) external virtual;

    function mintEth() external payable virtual;

    function redeem(uint redeemTokens) external virtual;

    function redeemUnderlying(uint redeemAmount) external virtual;

    function borrowBehalf(address borrower, uint borrowAmount) external virtual;

    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual;

    function repayBorrowEndByOpenLev(address borrower, uint repayAmount) external virtual;

    function availableForBorrow() external view virtual returns (uint);

    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint);

    function borrowRatePerBlock() external virtual view returns (uint);

    function supplyRatePerBlock() external virtual view returns (uint);

    function totalBorrowsCurrent() external virtual view returns (uint);

    function borrowBalanceCurrent(address account) external virtual view returns (uint);

    function borrowBalanceStored(address account) external virtual view returns (uint);

    function exchangeRateCurrent() public virtual returns (uint);

    function exchangeRateStored() public virtual view returns (uint);

    function getCash() external view virtual returns (uint);

    function accrueInterest() public virtual;


    /*** Admin Functions ***/

    function setController(address newController) external virtual;

    function setBorrowCapFactorMantissa(uint newBorrowCapFactorMantissa) external virtual;

    function setInterestParams(uint baseRatePerBlock_, uint multiplierPerBlock_, uint jumpMultiplierPerBlock_, uint kink_) external virtual;

    function setReserveFactor(uint newReserveFactorMantissa) external virtual;

    function addReserves(uint addAmount) external virtual;

    function reduceReserves(address payable to, uint reduceAmount) external virtual;

}

