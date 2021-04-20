// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./base/ERC20NonTransferableDividends.sol";
import "./libraries/TransferHelper.sol";


contract ERC20NonTransferableDividendsOwned is ERC20NonTransferableDividends, Ownable {
  using TransferHelper for address;

  address public immutable token;

  constructor(
    address token_,
    string memory name_,
    string memory symbol_
  ) ERC20NonTransferableDividends(name_, symbol_) Ownable() {
    token = token_;
  }

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external onlyOwner {
    _burn(from, amount);
  }

  function collectFor(address account) public {
    uint256 amount = _prepareCollect(account);
    token.safeTransfer(account, amount);
  }

  function collect() external {
    collectFor(msg.sender);
  }

  function distribute(uint256 amount) external {
    token.safeTransferFrom(msg.sender, address(this), amount);
    _distributeDividends(amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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
pragma solidity =0.7.6;

import "./ERC20NonTransferable.sol";
import "./AbstractDividends.sol";

/**
* @dev Same as the ERC20Dividends.sol but using the non transferable ERC20 base class    
*/
contract ERC20NonTransferableDividends is ERC20NonTransferable, AbstractDividends {
  /**
   * @dev Wrapper for balanceOf to give AbstractDividends a function reference.
   */
  function _balanceOf(address account) internal view returns (uint256) {
    return balanceOf[account];
  }

  /**
   * @dev Wrapper for totalSupply to give AbstractDividends a function reference.
   */
  function _totalSupply() internal view returns (uint256) {
    return totalSupply;
  }

  constructor(string memory name, string memory symbol)
    ERC20NonTransferable(name, symbol, 18)
    AbstractDividends(_balanceOf, _totalSupply)
  {}

	/**
	 * @dev Internal function that transfer tokens from one address to another.
	 * Update pointsCorrection to keep funds unchanged.
	 * @param from The address to transfer from.
	 * @param to The address to transfer to.
	 * @param value The amount to be transferred.
	 */
	function _transfer(address from, address to, uint256 value) internal virtual override {
		super._transfer(from, to, value);
    _correctPointsForTransfer(from, to, value);
	}

	/**
	 * @dev Internal function that mints tokens to an account.
	 * Update pointsCorrection to keep funds unchanged.
	 * @param account The account that will receive the created tokens.
	 * @param amount The amount that will be created.
	 */
	function _mint(address account, uint256 amount) internal virtual override {
		super._mint(account, amount);
    _correctPoints(account, -int256(amount));
	}
	
	/** 
	 * @dev Internal function that burns an amount of the token of a given account.
	 * Update pointsCorrection to keep funds unchanged.
	 * @param account The account whose tokens will be burnt.
	 * @param amount The amount that will be burnt.
	 */
	function _burn(address account, uint256 amount) internal virtual override {
		super._burn(account, amount);
    _correctPoints(account, int256(amount));
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 6a31c618fc3180a6ee945b869d1ce4449f253ee6.

Subject to the GPL-2.0-or-later license
*************************************************************************************************/


library TransferHelper {
  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "STE");
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

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./ERC20.sol";


contract ERC20NonTransferable is ERC20 {
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) ERC20(name_, symbol_, decimals_) {
    // nothing
  }

  /**
   * @dev Disables all transfer related functions
   */
  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
    revert("ERC20NonTransferable: Transfer not supported");
  }

  /**
   * @dev Disables all approval related functions
   *
   */
  function _approve(address owner, address spender, uint256 amount) internal virtual override {
    revert("ERC20NonTransferable: Approval not supported");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "../libraries/LowGasSafeMath.sol";
import "../libraries/SafeCast.sol";
import "../interfaces/IAbstractDividends.sol";

/**
 * @dev Many functions in this contract were taken from this repository:
 * https://github.com/atpar/funds-distribution-token/blob/master/contracts/FundsDistributionToken.sol
 * which is an example implementation of ERC 2222, the draft for which can be found at
 * https://github.com/atpar/funds-distribution-token/blob/master/EIP-DRAFT.md
 *
 * This contract has been substantially modified from the original and does not comply with ERC 2222.
 * Many functions were renamed as "dividends" rather than "funds" and the core functionality was separated
 * into this abstract contract which can be inherited by anything tracking ownership of dividend shares.
 */
abstract contract AbstractDividends is IAbstractDividends {
  using LowGasSafeMath for uint256;
  using SafeCast for uint128;
  using SafeCast for uint256;
  using SafeCast for int256;
  using SignedSafeMath for int256;

/* ========  Constants  ======== */
  uint128 internal constant POINTS_MULTIPLIER = type(uint128).max;

/* ========  Internal Function References  ======== */
  function(address) view returns (uint256) private immutable getSharesOf;
  function() view returns (uint256) private immutable getTotalShares;

/* ========  Storage  ======== */
  uint256 public pointsPerShare;
  mapping(address => int256) internal pointsCorrection;
  mapping(address => uint256) private withdrawnDividends;

  constructor(
    function(address) view returns (uint256) getSharesOf_,
    function() view returns (uint256) getTotalShares_
  ) {
    getSharesOf = getSharesOf_;
    getTotalShares = getTotalShares_;
  }

/* ========  Public View Functions  ======== */
  /**
   * @dev Returns the total amount of dividends a given address is able to withdraw.
   * @param account Address of a dividend recipient
   * @return A uint256 representing the dividends `account` can withdraw
   */
  function withdrawableDividendsOf(address account) public view override returns (uint256) {
    return cumulativeDividendsOf(account).sub(withdrawnDividends[account]);
  }

  /**
   * @notice View the amount of dividends that an address has withdrawn.
   * @param account The address of a token holder.
   * @return The amount of dividends that `account` has withdrawn.
   */
  function withdrawnDividendsOf(address account) public view override returns (uint256) {
    return withdrawnDividends[account];
  }

  /**
   * @notice View the amount of dividends that an address has earned in total.
   * @dev accumulativeFundsOf(account) = withdrawableDividendsOf(account) + withdrawnDividendsOf(account)
   * = (pointsPerShare * balanceOf(account) + pointsCorrection[account]) / POINTS_MULTIPLIER
   * @param account The address of a token holder.
   * @return The amount of dividends that `account` has earned in total.
   */
  function cumulativeDividendsOf(address account) public view override returns (uint256) {
    return pointsPerShare
      .mul(getSharesOf(account))
      .toInt256()
      .add(pointsCorrection[account])
      .toUint256() / POINTS_MULTIPLIER;
  }

/* ========  Dividend Utility Functions  ======== */

  /** 
   * @notice Distributes dividends to token holders.
   * @dev It reverts if the total supply is 0.
   * It emits the `FundsDistributed` event if the amount to distribute is greater than 0.
   * About undistributed dividends:
   *   In each distribution, there is a small amount which does not get distributed,
   *   which is `(amount * POINTS_MULTIPLIER) % totalShares()`.
   *   With a well-chosen `POINTS_MULTIPLIER`, the amount of funds that are not getting
   *   distributed in a distribution can be less than 1 (base unit).
   */
  function _distributeDividends(uint256 amount) internal {
    uint256 shares = getTotalShares();
    require(shares > 0, "SHARES");

    if (amount > 0) {
      pointsPerShare = pointsPerShare.add(
        amount.mul(POINTS_MULTIPLIER) / shares
      );
      emit DividendsDistributed(msg.sender, amount);
    }
  }

  /**
   * @notice Prepares collection of owed dividends
   * @dev It emits a `DividendsWithdrawn` event if the amount of withdrawn dividends is
   * greater than 0.
   */
  function _prepareCollect(address account) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendsOf(account);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[account] = withdrawnDividends[account].add(_withdrawableDividend);
      emit DividendsWithdrawn(account, _withdrawableDividend);
    }
    return _withdrawableDividend;
  }

  function _correctPointsForTransfer(address from, address to, uint256 shares) internal {
    int256 _magCorrection = pointsPerShare.mul(shares).toInt256();
    pointsCorrection[from] = pointsCorrection[from].add(_magCorrection);
    pointsCorrection[to] = pointsCorrection[to].sub(_magCorrection);
  }

  /**
   * @dev Increases or decreases the points correction for `account` by
   * `shares*pointsPerShare`.
   */
  function _correctPoints(address account, int256 shares) internal {
    pointsCorrection[account] = pointsCorrection[account]
      .add(shares.mul(int256(pointsPerShare)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/************************************************************************************************
Originally from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/ERC20.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 8f2b54f645a7844ae266cc50dc3ae4c125c7b9fc.

Subject to the MIT license
*************************************************************************************************/


contract ERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /**
   * @dev The amount of tokens in existence.
   */
  uint256 public totalSupply;
  /**
   * @dev The amount of tokens owned by `account`.
   */
  mapping(address => uint256) public balanceOf;
  /**
   * @dev The remaining number of tokens that `spender` will be allowed
   * to spend on behalf of `owner` through {transferFrom}. This is zero
   * by default.
   */
  mapping(address => mapping(address => uint256)) public allowance;

  /** @dev The name of the token. */
  string public name;

  /** @dev The symbol of the token. */
  string public symbol;

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
   * {balanceOf} and {transfer}.
   */
  uint8 public immutable decimals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    name = name_;
    symbol = symbol_;
    decimals = decimals_;
  }

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address to, uint256 amount) external returns (bool) {
    _transfer(msg.sender, to, amount);
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
  function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
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
  function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
    uint256 spenderAllowance = allowance[msg.sender][spender];
    require(spenderAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
    _approve(msg.sender, spender, spenderAllowance - subtractedValue);
    return true;
  }

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 spenderAllowance = allowance[sender][msg.sender];
    require(spenderAllowance >= amount, 'ERC20: transfer amount exceeds allowance');

    _approve(sender, msg.sender, spenderAllowance - amount);
    return true;
  }

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
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
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
    // If `amount` is 0, or `msg.sender` is `to` nothing happens
    if (amount != 0) {
      uint256 srcBalance = balanceOf[sender];
      require(srcBalance >= amount, "ERC20: transfer amount exceeds balance");
      if (sender != recipient) {
        require(recipient != address(0), 'ERC20: transfer to the zero address'); // Moved down so low balance calls safe some gas
        balanceOf[sender] = srcBalance - amount; // Underflow is checked
        balanceOf[recipient] += amount; // Can't overflow because totalSupply would be greater than 2^256-1
      }
    }

    emit Transfer(sender, recipient, amount);
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
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(spender != address(0), "ERC20: approve to the zero address");
    allowance[owner][spender] = amount;
    emit Approval(owner, spender, amount);
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
    require((totalSupply = totalSupply + amount) >= amount);
    balanceOf[account] += amount;
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
    uint supply = totalSupply;
    uint balance = balanceOf[account];
    require((balanceOf[account] = balance - amount) <= balance, "ERC20: burn amount exceeds balance");
    require((totalSupply = supply - amount) <= supply);

    emit Transfer(account, address(0), amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/LowGasSafeMath.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash b83fcf497e895ae59b97c9d04e997023f69b5e97.

Subject to the GPL-2.0-or-later license
*************************************************************************************************/


/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require((z = x + y) >= x, errorMessage);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require((z = x - y) <= x, errorMessage);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y, errorMessage);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/SafeCast.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash b83fcf497e895ae59b97c9d04e997023f69b5e97.

Subject to the GPL-2.0-or-later license
*************************************************************************************************/


/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a uint256 to a uint128, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint128
  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  /// @notice Cast a int256 to a int128, revert on overflow or underflow
  /// @param y The int256 to be downcasted
  /// @return z The downcasted integer, now type int128
  function toInt128(int256 y) internal pure returns (int128 z) {
    require((z = int128(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = int256(y);
  }

  /// @notice Cast an int256 to a uint256, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint256(int256 y) internal pure returns (uint256 z) {
    require(y >= 0);
    z = uint256(y);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IAbstractDividends {
	/**
	 * @dev Returns the total amount of dividends a given address is able to withdraw.
	 * @param account Address of a dividend recipient
	 * @return A uint256 representing the dividends `account` can withdraw
	 */
	function withdrawableDividendsOf(address account) external view returns (uint256);

  /**
	 * @dev View the amount of funds that an address has withdrawn.
	 * @param account The address of a token holder.
	 * @return The amount of funds that `account` has withdrawn.
	 */
	function withdrawnDividendsOf(address account) external view returns (uint256);

	/**
	 * @dev View the amount of funds that an address has earned in total.
	 * accumulativeFundsOf(account) = withdrawableDividendsOf(account) + withdrawnDividendsOf(account)
	 * = (pointsPerShare * balanceOf(account) + pointsCorrection[account]) / POINTS_MULTIPLIER
	 * @param account The address of a token holder.
	 * @return The amount of funds that `account` has earned in total.
	 */
	function cumulativeDividendsOf(address account) external view returns (uint256);

	/**
	 * @dev This event emits when new funds are distributed
	 * @param by the address of the sender who distributed funds
	 * @param dividendsDistributed the amount of funds received for distribution
	 */
	event DividendsDistributed(address indexed by, uint256 dividendsDistributed);

	/**
	 * @dev This event emits when distributed funds are withdrawn by a token holder.
	 * @param by the address of the receiver of funds
	 * @param fundsWithdrawn the amount of funds that were withdrawn
	 */
	event DividendsWithdrawn(address indexed by, uint256 fundsWithdrawn);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}