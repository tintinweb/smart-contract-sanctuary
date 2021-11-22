/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

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
        require(b != -1 || a != MIN_INT256);

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
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
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
     * - `account` cannot be the zero address.
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
     * will be to transferred to `to`.
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
}

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;
  
  uint256 internal magnifiedDividendPerShare;
  
  mapping (address => uint256) public holderBalance;
  mapping (address => uint256) public holderTokenBShare;
  uint256 public totalBalance;

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
  mapping(address => address) public userCurrentRewardTokenA;
  mapping(address => address) public userCurrentRewardTokenB;
  mapping(address => bool) public userHasCustomRewardToken;
  mapping(address => address) public userCurrentRewardAMMTokenA;
  mapping(address => address) public userCurrentRewardAMMTokenB;
  mapping(address => bool) public userHasCustomRewardAMMTokenA;
  mapping(address => bool) public userHasCustomRewardAMMTokenB;
  mapping(address => bool) public ammIsWhiteListed; // only allow whitelisted AMMs
  mapping(address => bool) public whiteListRewardTokens;
 
  IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  
  function updateDividendUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "PCKT: The router already has that address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
  }
  
  uint256 public totalDividendsDistributed; // dividends distributed per reward token

  constructor() {
    // add whitelisted AMMs here -- more will get added postlaunch
    ammIsWhiteListed[address(0x10ED43C718714eb63d5aA57B78B54704E256024E)] = true; // PCS V2 router
    ammIsWhiteListed[address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F)] = true; // PCS V1 router
    ammIsWhiteListed[address(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7)] = true; // ApeSwap router
    
    
    whiteListRewardTokens[address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47)] = true; // ADA
    whiteListRewardTokens[address(0x1CE0c2827e2eF14D5C4f29a091d735A204794041)] = true; // AVAX
    whiteListRewardTokens[address(0x97c6825e6911578A515B11e25B552Ecd5fE58dbA)] = true; // Burning Moon
    whiteListRewardTokens[address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c)] = true; // BTCB
    whiteListRewardTokens[address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)] = true; // BUSD
    whiteListRewardTokens[address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82)] = true; // CAKE
    whiteListRewardTokens[address(0xbF7c81FFF98BbE61B40Ed186e4AfD6DDd01337fe)] = true; // EGLD
    whiteListRewardTokens[address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8)] = true; // ETH
    whiteListRewardTokens[address(0xC7D43F2B51F44f09fBB8a691a0451E8FFCF36c0a)] = true; // RISE
    whiteListRewardTokens[address(0x55d398326f99059fF775485246999027B3197955)] = true; // USDT
  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }
  
  
  // Customized function to send tokens to dividend recipients
  function swapETHForTokensTokenA(
        address recipient,
        uint256 ethAmount,
        address rewardToken
    ) private returns (uint256) {
        
        bool swapSuccess;
        IERC20 token = IERC20(rewardToken);
        IUniswapV2Router02 swapRouter = uniswapV2Router;
        
        if(userHasCustomRewardAMMTokenA[recipient] && ammIsWhiteListed[userCurrentRewardAMMTokenA[recipient]]){
            swapRouter = IUniswapV2Router02(userCurrentRewardAMMTokenA[recipient]);
        }
        
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(token);
        
        // make the swap
        try swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send BNB)
            1, // accept any amount of Tokens above 1 wei (so it will fail if nothing returns)
            path,
            address(recipient),
            block.timestamp
        ){
            swapSuccess = true;
        }
        catch {
            swapSuccess = false;
        }
        
        // if the swap failed, send them their BNB instead
        if(!swapSuccess){
            (bool success,) = recipient.call{value: ethAmount, gas: 3000}("");
    
            if(!success) {
                withdrawnDividends[recipient] = withdrawnDividends[recipient].sub(ethAmount);
                return 0;
            }
        }
        return ethAmount;
    }
    
   // Customized function to send tokens to dividend recipients
  function swapETHForTokensTokenB(
        address recipient,
        uint256 ethAmount,
        address rewardToken
    ) private returns (uint256) {
        
        bool swapSuccess;
        IERC20 token = IERC20(rewardToken);
        IUniswapV2Router02 swapRouter = uniswapV2Router;
        
        if(userHasCustomRewardAMMTokenB[recipient] && ammIsWhiteListed[userCurrentRewardAMMTokenB[recipient]]){
            swapRouter = IUniswapV2Router02(userCurrentRewardAMMTokenB[recipient]);
        }
        
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(token);
        
        // make the swap
        try swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send BNB)
            1, // accept any amount of Tokens above 1 wei (so it will fail if nothing returns)
            path,
            address(recipient),
            block.timestamp
        ){
            swapSuccess = true;
        }
        catch {
            swapSuccess = false;
        }
        
        // if the swap failed, send them their BNB instead
        if(!swapSuccess){
            (bool success,) = recipient.call{value: ethAmount, gas: 3000}("");
    
            if(!success) {
                withdrawnDividends[recipient] = withdrawnDividends[recipient].sub(ethAmount);
                return 0;
            }
        }
        return ethAmount;
    }
  
  function setWhitelistToken(address tokenAddress, bool isWhitelisted) external onlyOwner {
      whiteListRewardTokens[tokenAddress] = isWhitelisted;
  }
  
  // set from main token
  function setTokenBAmount(uint256 percentForTokenB, address holder) external onlyOwner {
      require(percentForTokenB <= 100, "May not set value higher than 100");
      holderTokenBShare[holder] = percentForTokenB;
  }
  
  function isWhitelistedToken(address tokenAddress) public view returns (bool){
      return whiteListRewardTokens[tokenAddress];
  }
  
  function getBNBDividends(address holder) external view returns (uint256){
      return withdrawnDividends[holder];
  }
    
  function setWhiteListAMM(address ammAddress, bool whitelisted) external onlyOwner {
      ammIsWhiteListed[ammAddress] = whitelisted;
  }
  
  // call this to set a custom reward token (call from token contract only)
  function setRewardTokenA(address holder, address rewardTokenAddress, address ammContractAddress) external onlyOwner {
    userHasCustomRewardToken[holder] = true;
    userCurrentRewardTokenA[holder] = rewardTokenAddress;
    // only set custom AMM if the AMM is whitelisted.
    if(ammContractAddress != address(uniswapV2Router) && ammIsWhiteListed[ammContractAddress]){
        userHasCustomRewardAMMTokenA[holder] = true;
        userCurrentRewardAMMTokenA[holder] = ammContractAddress;
    } else {
        userHasCustomRewardAMMTokenA[holder] = false;
        userCurrentRewardAMMTokenA[holder] = address(uniswapV2Router);
    }
  }
  
   // call this to set a custom reward token (call from token contract only)
  function setRewardTokenB(address holder, address rewardTokenAddress, address ammContractAddress) external onlyOwner {
    userHasCustomRewardToken[holder] = true;
    userCurrentRewardTokenB[holder] = rewardTokenAddress;
    // only set custom AMM if the AMM is whitelisted.
    if(ammContractAddress != address(uniswapV2Router) && ammIsWhiteListed[ammContractAddress]){
        userHasCustomRewardAMMTokenB[holder] = true;
        userCurrentRewardAMMTokenB[holder] = ammContractAddress;
    } else {
        userHasCustomRewardAMMTokenB[holder] = false;
        userCurrentRewardAMMTokenB[holder] = address(uniswapV2Router);
    }
  }
  
  
  // call this to go back to receiving BNB after setting another token. (call from token contract only)
  function unsetRewardTokens(address holder) external onlyOwner {
    userHasCustomRewardToken[holder] = false;
    userCurrentRewardTokenA[holder] = address(0);
    userCurrentRewardTokenB[holder] = address(0);
    userCurrentRewardAMMTokenA[holder] = address(uniswapV2Router);
    userCurrentRewardAMMTokenB[holder] = address(uniswapV2Router);
    userHasCustomRewardAMMTokenA[holder] = false;
    userHasCustomRewardAMMTokenB[holder] = false;
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
    require(totalBalance > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalBalance
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }
  
  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() external virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    bool success;
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    uint256 amountForTokenB = _withdrawableDividend * holderTokenBShare[user] / 100;
    uint256 amountForTokenA = _withdrawableDividend - amountForTokenB;
    
    if (_withdrawableDividend > 0) {
        
        if (amountForTokenA > 0){
             // if no custom reward token or reward token is whitelisted, send BNB.
            if(!userHasCustomRewardToken[user] || !isWhitelistedToken(userCurrentRewardTokenA[user])){
            
              withdrawnDividends[user] = withdrawnDividends[user].add(amountForTokenA);
              emit DividendWithdrawn(user, amountForTokenA);
              (success,) = user.call{value: amountForTokenA, gas: 3000}("");
        
              if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(amountForTokenA);
                return 0;
              }
              return _withdrawableDividend;
              
            // the reward is a token, not BNB, use an IERC20 buyback instead!
            } else { 
                
              withdrawnDividends[user] = withdrawnDividends[user].add(amountForTokenA);
              emit DividendWithdrawn(user, amountForTokenA);
              swapETHForTokensTokenA(user, amountForTokenA, userCurrentRewardTokenA[user]);
            }
        }
        
        if (amountForTokenB > 0){
             // if no custom reward token or reward token is whitelisted, send BNB.
            if(!userHasCustomRewardToken[user] || !isWhitelistedToken(userCurrentRewardTokenB[user])){
            
              withdrawnDividends[user] = withdrawnDividends[user].add(amountForTokenB);
              emit DividendWithdrawn(user, _withdrawableDividend);
              (success,) = user.call{value: amountForTokenB, gas: 3000}("");
        
              if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(amountForTokenB);
                return 0;
              }
              return _withdrawableDividend;
          
            // the reward is a token, not BNB, use an IERC20 buyback instead!
            } else { 
                
              withdrawnDividends[user] = withdrawnDividends[user].add(amountForTokenB);
              emit DividendWithdrawn(user, amountForTokenB);
              swapETHForTokensTokenB(user, amountForTokenB, userCurrentRewardTokenB[user]);
            }
        }
    }
    return _withdrawableDividend;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that increases tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that reduces an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;
    if(newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);
      _increase(account, increaseAmount);
      totalBalance += increaseAmount;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      _reduce(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }
}

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


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

contract DividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken() {
    	claimWait = 1200;
        minimumTokenBalanceForDividends = 100 * 1e18; //must hold 100+ tokens to get divs
    }

    function withdrawDividend() pure external override {
        require(false, "PCKT_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main PCKT contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function includeInDividends(address account) external onlyOwner {
    	require(excludedFromDividends[account]);
    	excludedFromDividends[account] = false;

    	emit IncludeInDividends(account);
    }
    
    function updateDividendMinimum(uint256 minimumToEarnDivs) external onlyOwner {
        minimumTokenBalanceForDividends = minimumToEarnDivs;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
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

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
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
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) external returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

contract PCKT is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool private swapping;

    DividendTracker public dividendTracker;
    
    mapping(address => uint256) public holderBNBUsedForBuyBacks;
    
    mapping(address => bool) public isAuthorized;

    address public liquidityWallet;
    address public operationsWallet;
    address public p2eWallet;
    address public devWallet;
    
    uint256 public swapTokensAtAmount;

    // sell fees
    uint256 public sellRewardsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellOperationsFee;
    uint256 public sellP2eFee;
    uint256 public sellDevFee;
    uint256 public sellTotalFees;
    
    // buy fees
    uint256 public buyRewardsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyOperationsFee;
    uint256 public buyP2eFee;
    uint256 public buyDevFee;
    uint256 public buyTotalFees;
    
    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _devTokensToSwap;
    uint256 private _rewardTokensToSwap;
    
    uint256 public tradingActiveBlock; 
    
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    uint256 maxTransactionAmount; // 0.1% maxTransactionAmountTxn
    
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public limitsInEffect = true;

    bool private gasLimitActive = true;
    uint256 private gasPriceLimit = 75 * 1 gwei; // do not allow over x gwei for launch
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BuyBackWithNoFees(address indexed holder, uint256 indexed bnbSpent);

    event LiquidityWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event OperationsWalletUpdated(address indexed newLWallet, address indexed oldWallet);
    event DevelopmentWalletUpdated(address indexed newLWallet, address indexed oldWallet);
    event P2EWalletUpdated(address indexed newLWallet, address indexed oldWallet);
    
    event FeesUpdated(uint256 indexed newBNBRewardsFee, uint256 indexed newLiquidityFee, uint256 newOperationsFee, uint256 newBuyBackFee);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event AuthorizedAccountChange(address indexed account, bool isAuthorized);
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 amount
    );
    
    

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("Pocket", "PCKT", 18) {
        address futureOwner = address(0x7b498eFA017CA2f1721FdB6F9a21a7cA7290eB10);
        
        // sell fees
        sellRewardsFee = 6;
        sellLiquidityFee = 3;
        sellOperationsFee = 3;
        sellP2eFee = 1;
        sellDevFee = 1;
        sellTotalFees = sellRewardsFee + sellLiquidityFee + sellOperationsFee + sellP2eFee + sellDevFee;
        
        // buy fees
        buyRewardsFee = 4;
        buyLiquidityFee = 2;
        buyOperationsFee = 2;
        buyP2eFee = 1;
        buyDevFee = 1;
        buyTotalFees = buyRewardsFee + buyLiquidityFee + buyOperationsFee + buyP2eFee + buyDevFee;
            
    	dividendTracker = new DividendTracker();

    	liquidityWallet = address(futureOwner);
    	operationsWallet = address(0x25A80A4C38DB4AC44c2d31751960650c5e0Af995);
    	p2eWallet = address(0x140f98eDADbf522435eB0af4BD60C283df2D5666);
    	devWallet = address(0x434a19a06F45f1C8e080Ee89334498607d587B24);
        
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        uint256 totalSupply = 75 * 1e9 * 1e18;
        swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swap tokens amount
        maxTransactionAmount = totalSupply * 5 / 1000; // 0.5% maxTransactionAmountTxn
        
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(address(0xdead));
        dividendTracker.excludeFromDividends(futureOwner);
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(futureOwner, true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(futureOwner, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        isAuthorized[futureOwner] = true;

        _mint(owner(), totalSupply);
    }

    receive() external payable {

  	}
  	
  	// @dev Owner functions start -------------------------------------
  	
  	// enable / disable custom AMMs
  	function setWhiteListAMM(address ammAddress, bool isWhiteListed) external onlyOwner {
  	  require(isContract(ammAddress), "PCKT: setWhiteListAMM:: AMM is a wallet, not a contract");
      dividendTracker.setWhiteListAMM(ammAddress, isWhiteListed);
    }
    
    function updateAuthorized(address account, bool enabled) external onlyOwner {
        isAuthorized[account] = enabled;
        emit AuthorizedAccountChange(account, enabled);
    }
    
    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner{
        limitsInEffect = false;
        gasLimitActive = false;
        transferDelayEnabled = false;
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
    
    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner{
        transferDelayEnabled = false;
    }
    
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

  	// migration feature (DO NOT CHANGE WITHOUT CONSULTATION)
  	function updateDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(dividendTracker), "PCKT: The dividend tracker already has that address");

        DividendTracker newDividendTracker = DividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "PCKT: The new dividend tracker must be owned by the PCKT token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(address(0xdead));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    // excludes wallets from max txn and fees.
    function excludeFromFees(address account, bool excluded) public onlyAuthorized {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // allows multiple exclusions at once
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyAuthorized {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    // excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // removes exclusion on wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
    }
    
    // allow adding additional AMM pairs to the list
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "PCKT: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    // for airdrop feature after contract deployment
    function airdropToWallets(address[] memory airdropWallets, uint256[] memory amount) external onlyAuthorized {
        require(airdropWallets.length == amount.length, "PCKT: airdropToWallets:: Arrays must be the same length");
        for(uint256 i = 0; i < airdropWallets.length; i++){
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i];
            super._transfer(msg.sender, wallet, airdropAmount);
            dividendTracker.setBalance(payable(wallet), balanceOf(wallet));
        }
    }
    
    // sets the wallet that receives LP tokens to lock
    function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        require(newLiquidityWallet != address(0), "PCKT: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    
    // updates the operations wallet (marketing, charity, etc.)
    function updateOperationsWallet(address newOperationsWallet) external onlyOwner {
        require(newOperationsWallet != operationsWallet, "PCKT: The operations wallet is already this address");
        excludeFromFees(newOperationsWallet, true);
        emit OperationsWalletUpdated(newOperationsWallet, operationsWallet);
        operationsWallet = newOperationsWallet;
    }
    
    function updateDevelopmentWallet(address newWallet) external onlyOwner {
        devWallet= newWallet;
        emit DevelopmentWalletUpdated(newWallet, devWallet);
    }
    
    function updateP2EWallet(address newWallet) external onlyOwner {
        p2eWallet = newWallet;
        emit P2EWalletUpdated(newWallet, p2eWallet);
    }


    function updateBuyFees(uint256 _operationsFee, uint256 _rewardsFee, uint256 _liquidityFee, uint256 _p2eFee, uint256 _devFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyRewardsFee = _rewardsFee;
        buyLiquidityFee = _liquidityFee;
        buyP2eFee = _p2eFee;
        buyDevFee = _devFee;
        buyTotalFees = buyRewardsFee + buyLiquidityFee + buyOperationsFee + buyP2eFee + buyDevFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }
    
    function updateSellFees(uint256 _operationsFee, uint256 _rewardsFee, uint256 _liquidityFee, uint256 _p2eFee, uint256 _devFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellRewardsFee = _rewardsFee;
        sellLiquidityFee = _liquidityFee;
        sellP2eFee = _p2eFee;
        sellDevFee = _devFee;
        sellTotalFees = sellRewardsFee + sellLiquidityFee + sellOperationsFee + sellP2eFee + sellDevFee;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    // changes the gas reserve for processing dividend distribution
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "PCKT: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "PCKT: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    function updateMaxAmount(uint256 newNum) external onlyAuthorized {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * (10**18);
    }

    // changes the amount of time to wait for claims (expressed in seconds)
    function updateClaimWait(uint256 claimWait) external onlyOwner returns (bool){
        dividendTracker.updateClaimWait(claimWait);
        return true;
    }
    
    function setWhitelistToken(address tokenAddress, bool isWhitelisted) public onlyOwner returns (bool){
        dividendTracker.setWhitelistToken(tokenAddress, isWhitelisted);
        return true;
    }
    

    // @dev Views start here ------------------------------------
    
    // determines if an AMM can be used for rewards
    function isAMMWhitelisted(address ammAddress) public view returns (bool){
        return dividendTracker.ammIsWhiteListed(ammAddress);
    }
  	
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
  	
  	function getUserCurrentRewardTokenA(address holder) external view returns (address){
  	    return dividendTracker.userCurrentRewardTokenA(holder);
  	}
  	
  	function getUserCurrentRewardTokenB(address holder) external view returns (address){
  	    return dividendTracker.userCurrentRewardTokenB(holder);
  	}
  	
  	function getUserHasCustomRewardToken(address holder) external view returns (bool){
  	    return dividendTracker.userHasCustomRewardToken(holder);
  	}
  	
  	function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getDividendTokensMinimum() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }
    
    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) external view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) external view returns (uint256) {
		return dividendTracker.holderBalance(account);
	}
	
	function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }
    
    function getBNBDividends(address holder) public view returns (uint256){
        return dividendTracker.getBNBDividends(holder);
    }
    
    function getBNBAvailableForHolderBuyBack(address holder) external view returns (uint256){
        return getBNBDividends(holder).sub(holderBNBUsedForBuyBacks[msg.sender]);
    }
    
    function isWhitelistedToken(address tokenAddress) public view returns (bool){
        return dividendTracker.isWhitelistedToken(tokenAddress);
    }
    
    function getHolderTokenBAmount(address holder) external view returns (uint256){
      return dividendTracker.holderTokenBShare(holder);
    }
    
    // @dev User Callable Functions start here! ---------------------------------------------
  	
  	// set the reward token for the user.  Call from here.
  	function setRewardTokenA(address rewardTokenAddress) external returns (bool) {
  	    require(isContract(rewardTokenAddress), "PCKT: setRewardToken:: Address is a wallet, not a contract.");
  	    require(rewardTokenAddress != address(this), "PCKT: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
  	    require(isWhitelistedToken(rewardTokenAddress), "PCKT: setRewardToken:: Reward Token must be whitelisted to be used as rewards.");
  	    dividendTracker.setRewardTokenA(msg.sender, rewardTokenAddress, address(uniswapV2Router));
  	    return true;
  	}
  	
  	// set the reward token for the user with a custom AMM (AMM must be whitelisted).  Call from here.
  	function setRewardTokenAWithCustomAMM(address rewardTokenAddress, address ammContractAddress) external returns (bool) {
  	    require(isContract(rewardTokenAddress), "PCKT: setRewardToken:: Address is a wallet, not a contract.");
  	    require(ammContractAddress != address(uniswapV2Router), "PCKT: setRewardToken:: Use setRewardToken to use default Router");
  	    require(rewardTokenAddress != address(this), "PCKT: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
  	    require(isWhitelistedToken(rewardTokenAddress), "PCKT: setRewardToken:: Reward Token must be whitelisted to be used as rewards.");
  	    require(isAMMWhitelisted(ammContractAddress) == true, "PCKT: setRewardToken:: AMM is not whitelisted!");
  	    dividendTracker.setRewardTokenA(msg.sender, rewardTokenAddress, ammContractAddress);
  	    return true;
  	}
  	
  	// set the reward token for the user.  Call from here.
  	function setRewardTokenB(address rewardTokenAddress) external returns (bool) {
  	    require(isContract(rewardTokenAddress), "PCKT: setRewardToken:: Address is a wallet, not a contract.");
  	    require(rewardTokenAddress != address(this), "PCKT: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
  	    require(isWhitelistedToken(rewardTokenAddress), "PCKT: setRewardToken:: Reward Token must be whitelisted to be used as rewards.");
  	    dividendTracker.setRewardTokenB(msg.sender, rewardTokenAddress, address(uniswapV2Router));
  	    return true;
  	}
  	
  	// set the reward token for the user with a custom AMM (AMM must be whitelisted).  Call from here.
  	function setRewardTokenBWithCustomAMM(address rewardTokenAddress, address ammContractAddress) external returns (bool) {
  	    require(isContract(rewardTokenAddress), "PCKT: setRewardToken:: Address is a wallet, not a contract.");
  	    require(ammContractAddress != address(uniswapV2Router), "PCKT: setRewardToken:: Use setRewardToken to use default Router");
  	    require(rewardTokenAddress != address(this), "PCKT: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
  	    require(isWhitelistedToken(rewardTokenAddress), "PCKT: setRewardToken:: Reward Token must be whitelisted to be used as rewards.");
  	    require(isAMMWhitelisted(ammContractAddress) == true, "PCKT: setRewardToken:: AMM is not whitelisted!");
  	    dividendTracker.setRewardTokenB(msg.sender, rewardTokenAddress, ammContractAddress);
  	    return true;
  	}
  	
  	 // only use if conducting a presale (more specifically on DxSale where there is both an address and a router, PinkSale only uses one address, you can paste it in here twice with no issue)
    function addPresaleAddressForExclusions(address _presaleAddress, address _presaleRouterAddress) external onlyOwner {
        excludeFromFees(_presaleAddress, true);
        dividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleRouterAddress, true);
        dividendTracker.excludeFromDividends(_presaleRouterAddress);
    }
  	
  	// Unset the reward token back to BNB.  Call from here.
  	function unsetRewardToken() external returns (bool){
  	    dividendTracker.unsetRewardTokens(msg.sender);
  	    return true;
  	}
  	
  	// lets the user set a % to receive of a second reward token
    function setTokenBAmount(uint256 percent) external {
        dividendTracker.setTokenBAmount(percent, msg.sender);
    }
  	
  	// Holders can buyback with no fees up to their claimed raw BNB amount.
    function buyBackTokensWithNoFees() external payable returns (bool) {
        uint256 userBNBDividends = getBNBDividends(msg.sender);
        require(userBNBDividends >= holderBNBUsedForBuyBacks[msg.sender].add(msg.value), "buyBackTokensWithNoFees:: Cannot Spend more than earned.");
        
        uint256 ethAmount = msg.value;
        
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        // update amount to prevent user from buying with more BNB than they've received as raw rewards (update before transfer to prevent reentrancy)
        holderBNBUsedForBuyBacks[msg.sender] = holderBNBUsedForBuyBacks[msg.sender].add(msg.value);
        
        bool prevExclusion = _isExcludedFromFees[msg.sender]; // ensure we don't remove exclusions if the current wallet is already excluded
        // make the swap to the contract first to bypass fees
        _isExcludedFromFees[msg.sender] = true;
        
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send BNB)
            0, // accept any amount of Tokens
            path,
            address(msg.sender),
            block.timestamp + 360
        );
        
        _isExcludedFromFees[msg.sender] = prevExclusion; // set value to match original value
        emit BuyBackWithNoFees(msg.sender, ethAmount);
        return true;
    }
  	
  	// allows a user to manually claim their tokens.
  	function claim() external {
  	    dividendTracker.processAccount(payable(msg.sender), false);
    }
    
    // allow a user to manually process dividends.
    function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    
    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender] || msg.sender == owner(), "Caller is not authorized to call this function");
        _;
    }
    
    // @dev Token functions
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "PCKT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        // early exit with no other logic if transfering 0 (to prevent 0 transfers from triggering other logic)
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                // only use to prevent sniper buys in the first blocks.
                if (gasLimitActive && automatedMarketMakerPairs[from]) {
                    require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                }
                
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        
        if(
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[to] &&
            !_isExcludedFromFees[from] &&
            swapEnabled
        ) {
            swapping = true;
            
            swapBack();

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || from == address(this)) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees;
        	
        	uint256 tokensForP2E;
        	
        	if(tradingActiveBlock + 1 >= block.number && (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from])){
                fees = amount.mul(99).div(100);
                _liquidityTokensToSwap += fees * 33 / 99;
                tokensForP2E = fees * 33 / 99;
                _marketingTokensToSwap += fees * 33 / 99;
            }
            
        	//buy
        	else if(automatedMarketMakerPairs[from]) {
                fees = amount.mul(buyTotalFees).div(100);
                _liquidityTokensToSwap += fees * buyLiquidityFee / buyTotalFees;
                _marketingTokensToSwap += fees * buyOperationsFee / buyTotalFees;
                _devTokensToSwap += fees * buyDevFee / buyTotalFees;
                _rewardTokensToSwap += fees * buyRewardsFee / buyTotalFees;
                tokensForP2E = fees * buyP2eFee / buyTotalFees;
            }

            //sell
            else if(automatedMarketMakerPairs[to]) {
                fees = amount.mul(sellTotalFees).div(100);
                _liquidityTokensToSwap += fees * sellLiquidityFee / sellTotalFees;
                _marketingTokensToSwap += fees * sellOperationsFee / sellTotalFees;
                _devTokensToSwap += fees * sellDevFee / sellTotalFees;
                _rewardTokensToSwap += fees * sellRewardsFee / sellTotalFees;
                tokensForP2E = fees * sellP2eFee / sellTotalFees;
            }
            
            if(tokensForP2E > 0){
                super._transfer(from, address(p2eWallet), tokensForP2E);
            }

            if(fees > 0){
            	amount = amount.sub(fees);
            	fees -= tokensForP2E;
                super._transfer(from, address(this), fees);
            }
        }
        

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {
	    	}
        }
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap + _devTokensToSwap + _marketingTokensToSwap + _rewardTokensToSwap;
        if(totalTokensToSwap == 0){return;}
        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityTokensToSwap / 2;
        uint256 amountToSwapForBNB = contractBalance - tokensForLiquidity;
        
        uint256 initialBNBBalance = address(this).balance;

        swapTokensForEth(amountToSwapForBNB); 
        
        uint256 bnbBalance = address(this).balance.sub(initialBNBBalance);
        
        uint256 bnbForMarketing = bnbBalance.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForDev = bnbBalance.mul(_devTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForRewards = bnbBalance.mul(_rewardTokensToSwap).div(totalTokensToSwap);
        
        uint256 bnbForLiquidity = bnbBalance - bnbForMarketing - bnbForDev - bnbForRewards;
        
        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _devTokensToSwap = 0;
        _rewardTokensToSwap = 0;
        
        (bool success,) = address(operationsWallet).call{value: bnbForMarketing}("");
        (success,) = address(devWallet).call{value: bnbForDev}("");
        (success,) = address(dividendTracker).call{value: bnbForRewards}("");
        
        if(tokensForLiquidity > 0 && bnbForLiquidity > 0){
            addLiquidity(tokensForLiquidity, bnbForLiquidity);
            emit SwapAndLiquify(amountToSwapForBNB, bnbForLiquidity, tokensForLiquidity);
        }
        
        // any remnants of leftover bnb can be boughtback with buyback feature.
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
        
    }
    
    // useful for buybacks or to reclaim any BNB on the contract in a way that helps holders.
    function buyBackTokens(uint256 bnbAmountInWei) external onlyOwner {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmountInWei}(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
    }
}