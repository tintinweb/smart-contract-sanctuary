// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/ISherlock.sol';

import './NativeLock.sol';

contract ForeignLock is NativeLock {
  constructor(
    string memory _name,
    string memory _symbol,
    IERC20 _sherlock,
    IERC20 _underlying
  ) NativeLock(_name, _symbol, _sherlock) {
    underlying = _underlying;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    ISherlock(owner())._beforeTokenTransfer(from, to, amount);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'diamond-2/contracts/interfaces/IERC173.sol';
import 'diamond-2/contracts/interfaces/IDiamondLoupe.sol';
import 'diamond-2/contracts/interfaces/IDiamondCut.sol';
import './ISherX.sol';
import './ISherXERC20.sol';
import './IGov.sol';
import './IGovDev.sol';
import './IPayout.sol';
import './IManager.sol';
import './IPoolBase.sol';
import './IPoolStake.sol';
import './IPoolStrategy.sol';

interface ISherlock is
  IERC173,
  IDiamondLoupe,
  IDiamondCut,
  ISherX,
  ISherXERC20,
  IERC20,
  IGov,
  IGovDev,
  IPayout,
  IManager,
  IPoolBase,
  IPoolStake,
  IPoolStrategy
{}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/ILock.sol';

contract NativeLock is ERC20, ILock, Ownable {
  IERC20 public override underlying;

  constructor(
    string memory _name,
    string memory _symbol,
    IERC20 _sherlock
  ) ERC20(_name, _symbol) {
    transferOwnership(address(_sherlock));
    underlying = _sherlock;
  }

  function getOwner() external view override returns (address) {
    return owner();
  }

  function mint(address _account, uint256 _amount) external override onlyOwner {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount) external override onlyOwner {
    _burn(_account, _amount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/ILock.sol';

/// @title SHERX Logic Controller
/// @author Evert Kors
/// @notice This contract is used to manage functions related to the SHERX token
/// @dev Contract is meant to be included as a facet in the diamond
interface ISherX {
  //
  // Events
  //

  /// @notice Sends an event whenever a staker "harvests" earned SHERX
  /// @notice Harvesting is when SHERX "interest" is staked in the SHERX pool
  /// @param user Address of the user for whom SHERX is harvested
  /// @param token Token which had accumulated the harvested SHERX
  event Harvest(address indexed user, IERC20 indexed token);

  //
  // View methods
  //

  /// @notice Returns the USD amount of tokens being added to the SHERX pool each block
  /// @return USD amount added to SHERX pool per block
  function getTotalUsdPerBlock() external view returns (uint256);

  /// @notice Returns the internal USD amount of tokens represented by SHERX
  /// @return Last stored value of total internal USD underlying SHERX
  function getTotalUsdPoolStored() external view returns (uint256);

  /// @notice Returns the total USD amount of tokens represented by SHERX
  /// @return Current total internal USD underlying SHERX
  function getTotalUsdPool() external view returns (uint256);

  /// @notice Returns block number at which the total USD underlying SHERX was last stored
  /// @return Block number for stored USD underlying SHERX
  function getTotalUsdLastSettled() external view returns (uint256);

  /// @notice Returns stored USD amount for `_token`
  /// @param _token Token used for protocol premiums
  /// @return Stored USD amount
  function getStoredUsd(IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX that has not been minted yet
  /// @return Unminted amount of SHERX tokens
  function getTotalSherXUnminted() external view returns (uint256);

  /// @notice Returns total amount of SHERX, including unminted
  /// @return Total amount of SHERX tokens
  function getTotalSherX() external view returns (uint256);

  /// @notice Returns the amount of SHERX created per block
  /// @return SHERX per block
  function getSherXPerBlock() external view returns (uint256);

  /// @notice Returns the total amount of SHERX accrued by the sender
  /// @return Total SHERX balance
  function getSherXBalance() external view returns (uint256);

  /// @notice Returns the amount of SHERX accrued by `_user`
  /// @param _user address to get the SHERX balance of
  /// @return Total SHERX balance
  function getSherXBalance(address _user) external view returns (uint256);

  /// @notice Returns the total supply of SHERX from storage (only used internally)
  /// @return Total supply of SHERX
  function getInternalTotalSupply() external view returns (uint256);

  /// @notice Returns the block number when total SHERX supply was last set in storage
  /// @return block number of last write to storage for the total SHERX supply
  function getInternalTotalSupplySettled() external view returns (uint256);

  /// @notice Returns the tokens and amounts underlying msg.sender's SHERX balance
  /// @return tokens Array of ERC-20 tokens representing the underlying
  /// @return amounts Corresponding amounts of the underlying tokens
  function calcUnderlying()
    external
    view
    returns (IERC20[] memory tokens, uint256[] memory amounts);

  /// @notice Returns the tokens and amounts underlying `_user` SHERX balance
  /// @param _user Account whose underlying SHERX tokens should be queried
  /// @return tokens Array of ERC-20 tokens representing the underlying
  /// @return amounts Corresponding amounts of the underlying tokens
  function calcUnderlying(address _user)
    external
    view
    returns (IERC20[] memory tokens, uint256[] memory amounts);

  /// @notice Returns the tokens and amounts underlying the given amount of SHERX
  /// @param _amount Amount of SHERX tokens to calculate the underlying tokens of
  /// @return tokens Array of ERC-20 tokens representing the underlying
  /// @return amounts Corresponding amounts of the underlying tokens
  function calcUnderlying(uint256 _amount)
    external
    view
    returns (IERC20[] memory tokens, uint256[] memory amounts);

  /// @notice Returns the internal USD amount underlying senders SHERX
  /// @return USD value of SHERX accrued to sender
  function calcUnderlyingInStoredUSD() external view returns (uint256);

  /// @notice Returns the internal USD amount underlying the given amount SHERX
  /// @param _amount Amount of SHERX tokens to find the underlying USD value of
  /// @return usd USD value of the given amount of SHERX
  function calcUnderlyingInStoredUSD(uint256 _amount) external view returns (uint256 usd);

  //
  // State changing methods
  //

  /// @notice Function called by lockTokens before transfer
  /// @param from Address from which lockTokens are being transferred
  /// @param to Address to which lockTokens are being transferred
  /// @param amount Amount of lockTokens to be transferred
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) external;

  /// @notice Set initial SHERX distribution to Watsons
  function setInitialWeight() external;

  /// @notice Set SHERX distribution
  /// @param _tokens Array of tokens to set the weights of
  /// @param _weights Respective weighting for each token
  /// @param _watsons Weighting to set for the Watsons
  function setWeights(
    IERC20[] memory _tokens,
    uint16[] memory _weights,
    uint256 _watsons
  ) external;

  /// @notice Harvest all tokens on behalf of the sender
  function harvest() external;

  /// @notice Harvest `_token` on behalf of the sender
  /// @param _token Token to harvest accrued SHERX for
  function harvest(ILock _token) external;

  /// @notice Harvest `_tokens` on behalf of the sender
  /// @param _tokens Array of tokens to harvest accrued SHERX for
  function harvest(ILock[] calldata _tokens) external;

  /// @notice Harvest all tokens for `_user`
  /// @param _user Account for which to harvest SHERX
  function harvestFor(address _user) external;

  /// @notice Harvest `_token` for `_user`
  /// @param _user Account for which to harvest SHERX
  /// @param _token Token to harvest
  function harvestFor(address _user, ILock _token) external;

  /// @notice Harvest `_tokens` for `_user`
  /// @param _user Account for which to harvest SHERX
  /// @param _tokens Array of tokens to harvest accrued SHERX for
  function harvestFor(address _user, ILock[] calldata _tokens) external;

  /// @notice Redeems SHERX tokens for the underlying collateral
  /// @param _amount Amount of SHERX tokens to redeem
  /// @param _receiver Address to send redeemed tokens to
  function redeem(uint256 _amount, address _receiver) external;

  /// @notice Accrue SHERX based on internal weights
  function accrueSherX() external;

  /// @notice Accrues SHERX to specific token
  /// @param _token Token to accure SHERX to.
  function accrueSherX(IERC20 _token) external;

  /// @notice Accrues SHERX to the Watsons.
  function accrueSherXWatsons() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

interface ISherXERC20 {
  //
  // View methods
  //

  /// @notice Get the token name
  /// @return The token name
  function name() external view returns (string memory);

  /// @notice Get the token symbol
  /// @return The token symbol
  function symbol() external view returns (string memory);

  /// @notice Get the amount of decimals
  /// @return Amount of decimals
  function decimals() external view returns (uint8);

  //
  // State changing methods
  //

  /// @notice Sets up the metadata and initial supply. Can be called by the contract owner
  /// @param _name Name of the token
  /// @param _symbol Symbol of the token
  function initializeSherXERC20(string memory _name, string memory _symbol) external;

  /// @notice Increase the amount of tokens another address can spend
  /// @param _spender Spender
  /// @param _amount Amount to increase by
  function increaseAllowance(address _spender, uint256 _amount) external returns (bool);

  /// @notice Decrease the amount of tokens another address can spend
  /// @param _spender Spender
  /// @param _amount Amount to decrease by
  function decreaseAllowance(address _spender, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/ILock.sol';
import '../interfaces/IRemove.sol';

/// @title Sherlock Main Governance
/// @author Evert Kors
/// @notice This contract is used for managing tokens, protocols and more in Sherlock
/// @dev Contract is meant to be included as a facet in the diamond
/// @dev Storage library is used
interface IGov {
  //
  // Events
  //

  //
  // View methods
  //

  /// @notice Returns the main governance address
  /// @return Main governance address
  function getGovMain() external view returns (address);

  /// @notice Returns the compensation address for the Watsons
  /// @return Watsons address
  function getWatsons() external view returns (address);

  /// @notice Returns the weight for the Watsons compensation
  /// @return Watsons compensation weight
  /// @dev Value is scaled by type(uint16).max
  function getWatsonsSherXWeight() external view returns (uint16);

  /// @notice Returns the last block number the SherX was accrued to the Watsons
  /// @return Block number
  function getWatsonsSherxLastAccrued() external view returns (uint40);

  /// @notice Returns the amount of SherX the Watsons receive per block
  /// @return Number of SherX per block
  function getWatsonsSherXPerBlock() external view returns (uint256);

  /// @notice Returns the total amount of uminted SherX for the Watsons
  /// @return SherX to be minted
  /// @dev Based on current block, last accrued and the SherX per block
  function getWatsonsUnmintedSherX() external view returns (uint256);

  /// @notice Returns the window of opportunity in blocks to unstake funds
  /// @notice Cooldown period has to be expired first to start the unstake window
  /// @return Amount of blocks
  function getUnstakeWindow() external view returns (uint40);

  /// @notice Returns the cooldown period in blocks
  /// @notice After the cooldown period funds can be unstaked
  /// @return Amount of blocks
  function getCooldown() external view returns (uint40);

  /// @notice Returns an array of tokens accounts are allowed to stake in
  /// @return Array of ERC20 tokens
  function getTokensStaker() external view returns (IERC20[] memory);

  /// @notice Returns an array of tokens that are included in the SherX as underlying
  /// @notice Registered protocols use one or more of these tokens to compensate Sherlock
  /// @return Array of ERC20 tokens
  function getTokensSherX() external view returns (IERC20[] memory);

  /// @notice Verify if a protocol is included in Sherlock
  /// @param _protocol Protocol identifier
  /// @return Boolean indicating if protocol is included
  function getProtocolIsCovered(bytes32 _protocol) external view returns (bool);

  /// @notice Returns address responsible on behalf of Sherlock for the protocol
  /// @param _protocol Protocol identifier
  /// @return Address of account
  function getProtocolManager(bytes32 _protocol) external view returns (address);

  /// @notice Returns address responsible on behalf of the protocol
  /// @param _protocol Protocol identifier
  /// @return Address of account
  /// @dev Account is able to withdraw protocol balance
  function getProtocolAgent(bytes32 _protocol) external view returns (address);

  /// @notice Get the maximum of tokens to be in the SherX array
  /// @return Max maximum amount of tokens
  function getMaxTokensSherX() external view returns (uint8);

  /// @notice Get the maximum of tokens to be in the Staker array
  /// @return Max maximum amount of tokens
  function getMaxTokensStaker() external view returns (uint8);

  /// @notice Get the maximum of protocol to be in a single pool
  /// @return Max maximum amount of protocol
  function getMaxProtocolPool() external view returns (uint8);

  //
  // State changing methods
  //

  /// @notice Set initial main governance address
  /// @param _govMain The address of the main governance
  /// @dev Diamond deployer - GovDev - is able to call this function
  function setInitialGovMain(address _govMain) external;

  /// @notice Transfer the main governance
  /// @param _govMain New address for the main governance
  function transferGovMain(address _govMain) external;

  /// @notice Set the compensation address for the Watsons
  /// @param _watsons Address for Watsons
  function setWatsonsAddress(address _watsons) external;

  /// @notice Set unstake window
  /// @param _unstakeWindow Unstake window in amount of blocks
  function setUnstakeWindow(uint40 _unstakeWindow) external;

  /// @notice Set cooldown period
  /// @param _period Cooldown period in amount of blocks
  function setCooldown(uint40 _period) external;

  /// @notice Add a new protocol to Sherlock
  /// @param _protocol Protocol identifier
  /// @param _eoaProtocolAgent Account to be registered as the agent
  /// @param _eoaManager Account to be registered as the manager
  /// @param _tokens Initial array of tokens the protocol is allowed to pay in
  /// @dev _tokens should first be initialized by calling tokenInit()
  function protocolAdd(
    bytes32 _protocol,
    address _eoaProtocolAgent,
    address _eoaManager,
    IERC20[] memory _tokens
  ) external;

  /// @notice Update protocol agent and/or manager
  /// @param _protocol Protocol identifier
  /// @param _eoaProtocolAgent Account to be registered as the agent
  /// @param _eoaManager Account to be registered as the manager
  function protocolUpdate(
    bytes32 _protocol,
    address _eoaProtocolAgent,
    address _eoaManager
  ) external;

  /// @notice Add tokens the protocol is allowed to pay in
  /// @param _protocol Protocol identifier
  /// @param _tokens Array of tokens to be added as valid protocol payment
  /// @dev _tokens should first be initialized by calling tokenInit()
  function protocolDepositAdd(bytes32 _protocol, IERC20[] memory _tokens) external;

  /// @notice Remove protocol from the Sherlock registry
  /// @param _protocol Protocol identifier
  function protocolRemove(bytes32 _protocol) external;

  /// @notice Initialize a new token
  /// @param _token Address of the token
  /// @param _govPool Account responsible for the token
  /// @param _lock Corresponding lock token, indicating staker token
  /// @param _isProtocolPremium Boolean indicating if token should be registered as protocol payment
  /// @dev Token can be reinitialiezd
  /// @dev Zero address for _lock will not enable stakers to deposit with the _token
  function tokenInit(
    IERC20 _token,
    address _govPool,
    ILock _lock,
    bool _isProtocolPremium
  ) external;

  /// @notice Disable a token for stakers
  /// @param _token Address of the token
  /// @param _index Index of the token in storage array
  function tokenDisableStakers(IERC20 _token, uint256 _index) external;

  /// @notice Disable a token for protocols
  /// @param _token Address of the token
  /// @param _index Index of the token in storage array
  /// @dev Removes the token as underlying from SherX
  function tokenDisableProtocol(IERC20 _token, uint256 _index) external;

  /// @notice Unload tokens from Sherlock
  /// @param _token Address of the token
  /// @param _native Contract being used to swap existing token in Sherlock
  /// @param _remaining Account used to send the unallocated SherX and remaining balance for _token
  function tokenUnload(
    IERC20 _token,
    IRemove _native,
    address _remaining
  ) external;

  /// @notice Remove a token from storage
  /// @param _token Address of the token
  function tokenRemove(IERC20 _token) external;

  /// @notice Set the maximum of tokens to be in the SherX array
  /// @param _max maximum amount of tokens
  function setMaxTokensSherX(uint8 _max) external;

  /// @notice Set the maximum of tokens to be in the Staker array
  /// @param _max maximum amount of tokens
  function setMaxTokensStaker(uint8 _max) external;

  /// @notice Set the maximum of protocol to be in a single pool
  /// @param _max maximum amount of protocol
  function setMaxProtocolPool(uint8 _max) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import 'diamond-2/contracts/libraries/LibDiamond.sol';

/// @title Sherlock Dev Controller
/// @author Evert Kors
/// @notice This contract is used during development for upgrading logic
/// @dev Contract is meant to be included as a facet in the diamond
interface IGovDev {
  /// @notice Returns the dev controller address
  /// @return Dev address
  function getGovDev() external view returns (address);

  /// @notice Transfer dev role to other account or renounce
  /// @param _govDev New dev address
  function transferGovDev(address _govDev) external;

  /// @notice Renounce dev role
  function renounceGovDev() external;

  /// @notice Delete, update or add functions
  /// @param _diamondCut Struct containing data of function mutation
  /// @param _init Address to call after pushing changes
  /// @param _calldata Data to call address with
  function updateSolution(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Sherlock Payout Controller
/// @author Evert Kors
/// @notice This contract is used for doing payouts
/// @dev Contract is meant to be included as a facet in the diamond
/// @dev Storage library is used
interface IPayout {
  /// @notice Returns the governance address able to do payouts
  /// @return Payout governance address
  function getGovPayout() external view returns (address);

  /// @notice Set initial payout governance address
  /// @param _govPayout The address of the payout governance
  /// @dev Diamond deployer - GovDev - is able to call this function
  function setInitialGovPayout(address _govPayout) external;

  /// @notice Transfer the payout governance
  /// @param _govPayout New address for the payout governance
  function transferGovPayout(address _govPayout) external;

  /// @notice Send `_tokens` to `_payout`
  /// @param _payout Account to receive payout
  /// @param _tokens Tokens to be paid out
  /// @param _firstMoneyOut Amount used from first money out
  /// @param _amounts Amount used staker balance
  /// @param _unallocatedSherX Amount of unallocated SHERX used
  /// @param _exclude Token excluded from payout
  function payout(
    address _payout,
    IERC20[] memory _tokens,
    uint256[] memory _firstMoneyOut,
    uint256[] memory _amounts,
    uint256[] memory _unallocatedSherX,
    address _exclude
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Sherlock Protocol Manager
/// @author Evert Kors
/// @notice Managing the amounts protocol are due to Sherlock
interface IManager {
  //
  // State changing methods
  //

  /// @notice Set internal price of `_token` to `_newUsd`
  /// @param _token Token to be updated
  /// @param _newUsd USD amount of token
  /// @dev Updating token price for 1 token
  function setTokenPrice(IERC20 _token, uint256 _newUsd) external;

  /// @notice Set internal price of multiple tokens
  /// @param _token Array of token addresses
  /// @param _newUsd Array of USD amounts
  /// @dev Updating token price for 1+ tokens
  function setTokenPrice(IERC20[] memory _token, uint256[] memory _newUsd) external;

  /// @notice Set `_token` premium for `_protocol` to `_premium` per block
  /// @param _protocol Protocol identifier
  /// @param _token Token address
  /// @param _premium Amount of tokens to be paid per block
  /// @dev Updating protocol premium for 1 token
  function setProtocolPremium(
    bytes32 _protocol,
    IERC20 _token,
    uint256 _premium
  ) external;

  /// @notice Set multiple token premiums for `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _token Array of token addresses
  /// @param _premium Array of amount of tokens to be paid per block
  /// @dev Updating protocol premium for 1+ tokens
  function setProtocolPremium(
    bytes32 _protocol,
    IERC20[] memory _token,
    uint256[] memory _premium
  ) external;

  // NOTE: note implemented for now, same call with price has better use case
  // updating multiple protocol's premiums for 1 tokens
  // function setProtocolPremium(
  //   bytes32[] memory _protocol,
  //   IERC20 memory _token,
  //   uint256[] memory _premium
  // ) external;

  /// @notice Set multiple tokens premium for multiple protocols
  /// @param _protocol Array of protocol identifiers
  /// @param _token 2 dimensional array of token addresses
  /// @param _premium 2 dimensional array of amount of tokens to be paid per block
  /// @dev Updating multiple protocol's premium for 1+ tokens
  function setProtocolPremium(
    bytes32[] memory _protocol,
    IERC20[][] memory _token,
    uint256[][] memory _premium
  ) external;

  /// @notice Set `_token` premium for `_protocol` to `_premium` per block and internal price to `_newUsd`
  /// @param _protocol Protocol identifier
  /// @param _token Token address
  /// @param _premium Amount of tokens to be paid per block
  /// @param _newUsd USD amount of token
  /// @dev Updating protocol premium and token price for 1 token
  function setProtocolPremiumAndTokenPrice(
    bytes32 _protocol,
    IERC20 _token,
    uint256 _premium,
    uint256 _newUsd
  ) external;

  /// @notice Set multiple token premiums for `_protocol` and update internal prices
  /// @param _protocol Protocol identifier
  /// @param _token Array of token addresses
  /// @param _premium Array of amount of tokens to be paid per block
  /// @param _newUsd Array of USD amounts
  /// @dev Updating protocol premiums and token price for 1+ token
  function setProtocolPremiumAndTokenPrice(
    bytes32 _protocol,
    IERC20[] memory _token,
    uint256[] memory _premium,
    uint256[] memory _newUsd
  ) external;

  /// @notice Set `_token` premium for protocols and internal price to `_newUsd`
  /// @param _protocol Array of protocol identifiers
  /// @param _token Token address
  /// @param _premium Array of amount of tokens to be paid per block
  /// @param _newUsd USD amount
  /// @dev Updating multiple protocol premiums for 1 token, including price
  function setProtocolPremiumAndTokenPrice(
    bytes32[] memory _protocol,
    IERC20 _token,
    uint256[] memory _premium,
    uint256 _newUsd
  ) external;

  /// @notice Update multiple token premiums and prices for multiple protocols
  /// @param _protocol Array of protocol identifiers
  /// @param _token 2 dimensional array of tokens
  /// @param _premium 2 dimensional array of amounts to be paid per block
  /// @param _newUsd 2 dimensional array of USD amounts
  /// @dev Updating multiple protocol premiums for multiple tokens, including price
  function setProtocolPremiumAndTokenPrice(
    bytes32[] memory _protocol,
    IERC20[][] memory _token,
    uint256[][] memory _premium,
    uint256[][] memory _newUsd
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../storage/PoolStorage.sol';

/// @title Sherlock Pool Controller
/// @author Evert Kors
/// @notice This contract is for every token pool
/// @dev Contract is meant to be included as a facet in the diamond
/// @dev Storage library is used
/// @dev Storage pointer is calculated based on last _token argument
interface IPoolBase {
  //
  // Events
  //

  //
  // View methods
  //

  /// @notice Returns the fee used on `_token` cooldown activation
  /// @param _token Token used
  /// @return Cooldown fee scaled by type(uint32).max
  function getCooldownFee(IERC20 _token) external view returns (uint32);

  /// @notice Returns SherX weight for `_token`
  /// @param _token Token used
  /// @return SherX weight scaled by type(uint16).max
  function getSherXWeight(IERC20 _token) external view returns (uint16);

  /// @notice Returns account responsible for `_token`
  /// @param _token Token used
  /// @return Account address
  function getGovPool(IERC20 _token) external view returns (address);

  /// @notice Returns boolean indicating if `_token` can be used for protocol payments
  /// @param _token Token used
  /// @return Premium boolean
  function isPremium(IERC20 _token) external view returns (bool);

  /// @notice Returns boolean indicating if `_token` can be used for staking
  /// @param _token Token used
  /// @return Staking boolean
  function isStake(IERC20 _token) external view returns (bool);

  /// @notice Returns current `_token` balance for `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _token Token used
  /// @return Current balance
  function getProtocolBalance(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /// @notice Returns current `_token` premium for `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _token Token used
  /// @return Current premium per block
  function getProtocolPremium(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /// @notice Returns linked lockToken for `_token`
  /// @param _token Token used
  /// @return Address of lockToken
  function getLockToken(IERC20 _token) external view returns (ILock);

  /// @notice Returns if `_protocol` is whitelisted for `_token`
  /// @param _protocol Protocol identifier
  /// @param _token Token used
  /// @return Boolean indicating whitelist status
  function isProtocol(bytes32 _protocol, IERC20 _token) external view returns (bool);

  /// @notice Returns array of whitelisted protcols
  /// @param _token Token used
  /// @return Array protocol identifiers
  function getProtocols(IERC20 _token) external view returns (bytes32[] memory);

  /// @notice Returns `_token` untake entry for `_staker` with id `_id`
  /// @param _staker Account that started unstake process
  /// @param _id ID of unstaking entry
  /// @param _token Token used
  /// @return Unstaking entry
  function getUnstakeEntry(
    address _staker,
    uint256 _id,
    IERC20 _token
  ) external view returns (PoolStorage.UnstakeEntry memory);

  /// @notice Return total debt in  `_token` whitelisted protocols accrued
  /// @param _token Token used
  /// @return Total accrued debt
  function getTotalAccruedDebt(IERC20 _token) external view returns (uint256);

  /// @notice Return current size of first money out pool
  /// @param _token Token used
  /// @return First money out size
  function getFirstMoneyOut(IERC20 _token) external view returns (uint256);

  /// @notice Return debt in  `_token` `_protocol` accrued
  /// @param _protocol Protocol identifier
  /// @param _token Token used
  /// @return Accrued debt
  function getAccruedDebt(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /// @notice Return total premium per block that whitelisted protocols are accrueing as debt
  /// @param _token Token used
  /// @return Total amount of premium
  function getTotalPremiumPerBlock(IERC20 _token) external view returns (uint256);

  /// @notice Returns block debt was last accrued.
  /// @param _token Token used
  /// @return Block number
  function getPremiumLastPaid(IERC20 _token) external view returns (uint40);

  /// @notice Return total amount of `_token` used as underlying for SHERX
  /// @param _token Token used
  /// @return Amount used as underlying
  function getSherXUnderlying(IERC20 _token) external view returns (uint256);

  /// @notice Return total amount of `_staker` unstaking entries for `_token`
  /// @param _staker Account used
  /// @param _token Token used
  /// @return Amount of entries
  function getUnstakeEntrySize(address _staker, IERC20 _token) external view returns (uint256);

  /// @notice Returns initial active unstaking enty for `_staker`
  /// @param _staker Account used
  /// @param _token Token used
  /// @return Initial ID of unstaking entry
  function getInitialUnstakeEntry(address _staker, IERC20 _token) external view returns (uint256);

  /// @notice Returns amount staked in `_token` that is not included in a yield strategy
  /// @param _token Token used
  /// @return Amount staked
  function getUnactivatedStakersPoolBalance(IERC20 _token) external view returns (uint256);

  /// @notice Returns amount staked in `_token` including yield strategy
  /// @param _token Token used
  /// @return Amount staked
  function getStakersPoolBalance(IERC20 _token) external view returns (uint256);

  /// @notice Returns `_staker` amount staked in `_token`
  /// @param _staker Account used
  /// @param _token Token used
  /// @return Amount staked
  function getStakerPoolBalance(address _staker, IERC20 _token) external view returns (uint256);

  /// @notice Returns unminted SHERX for `_token`
  /// @param _token Token used
  /// @return Unminted SHERX
  function getTotalUnmintedSherX(IERC20 _token) external view returns (uint256);

  /// @notice Returns stored amount of SHERX not allocated to stakers
  /// @param _token Token used
  /// @return Unallocated amount of SHERX
  function getUnallocatedSherXStored(IERC20 _token) external view returns (uint256);

  /// @notice Returns current amount of SHERX not allocated to stakers
  /// @param _token Token used
  /// @return Unallocated amount of SHERX
  function getUnallocatedSherXTotal(IERC20 _token) external view returns (uint256);

  /// @notice Returns current amount of SHERX not allocated to `_user`
  /// @param _user Staker in token
  /// @param _token Token used
  /// @return Unallocated amount of SHERX
  function getUnallocatedSherXFor(address _user, IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX distributed to `_token` stakers per block
  /// @param _token Token used
  /// @return Amount of SHERX distributed
  function getTotalSherXPerBlock(IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX distributed per block to sender for staking in `_token`
  /// @param _token Token used
  /// @return Amount of SHERX distributed
  function getSherXPerBlock(IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX distributed per block to `_user` for staking in `_token`
  /// @param _user Account used
  /// @param _token Token used
  /// @return Amount of SHERX distributed
  function getSherXPerBlock(address _user, IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX distributed per block when staking `_amount` of `_token`
  /// @param _amount Amount of tokens
  /// @param _token Token used
  /// @return SHERX to be distrubuted if staked
  function getSherXPerBlock(uint256 _amount, IERC20 _token) external view returns (uint256);

  /// @notice Returns block SHERX was last accrued to `_token`
  /// @param _token Token used
  /// @return Block last accrued
  function getSherXLastAccrued(IERC20 _token) external view returns (uint40);

  /// @notice Current exchange rate from lockToken to `_token`
  /// @param _token Token used
  /// @return Current exchange rate
  function LockToTokenXRate(IERC20 _token) external view returns (uint256);

  /// @notice Current exchange rate from lockToken to `_token` using `_amount`
  /// @param _amount Amount to be exchanged
  /// @param _token Token used
  /// @return Current exchange rate
  function LockToToken(uint256 _amount, IERC20 _token) external view returns (uint256);

  /// @notice Current exchange rate from `_token` to lockToken
  /// @param _token Token used
  /// @return Current exchange rate
  function TokenToLockXRate(IERC20 _token) external view returns (uint256);

  /// @notice Current exchange rate from `_token` to lockToken using `_amount`
  /// @param _amount Amount to be exchanged
  /// @param _token Token used
  /// @return Current exchange rate
  function TokenToLock(uint256 _amount, IERC20 _token) external view returns (uint256);

  //
  // State changing methods
  //

  /// @notice Set `_fee` used for activating cooldowns on `_token`
  /// @param _fee Fee scaled by type(uint32).max
  /// @param _token Token used
  function setCooldownFee(uint32 _fee, IERC20 _token) external;

  /// @notice Deposit `_amount` of `_token` on behalf of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens
  /// @param _token Token used
  function depositProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    IERC20 _token
  ) external;

  /// @notice Withdraw `_amount` of `_token` on behalf of `_protocol` to `_receiver`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens
  /// @param _receiver Address receiving the amount
  /// @param _token Token used
  function withdrawProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    IERC20 _token
  ) external;

  /// @notice Start unstaking flow for sender with `_amount` of lockTokens
  /// @param _amount Amount of lockTokens
  /// @param _token Token used
  /// @return ID of unstaking entry
  /// @dev e.g. _token is DAI, _amount is amount of lockDAI
  function activateCooldown(uint256 _amount, IERC20 _token) external returns (uint256);

  /// @notice Cancel unstaking `_token` with entry `_id` for sender
  /// @param _id ID of unstaking entry
  /// @param _token Token used
  function cancelCooldown(uint256 _id, IERC20 _token) external;

  /// @notice Returns lockTokens to _account if unstaking entry _id is expired
  /// @param _account Account that initiated unstaking flow
  /// @param _id ID of unstaking entry
  /// @param _token Token used
  function unstakeWindowExpiry(
    address _account,
    uint256 _id,
    IERC20 _token
  ) external;

  /// @notice Unstake _token for sender with entry _id, send to _receiver
  /// @param _id ID of unstaking entry
  /// @param _receiver Account receiving the tokens
  /// @param _token Token used
  /// @return amount of tokens unstaked
  function unstake(
    uint256 _id,
    address _receiver,
    IERC20 _token
  ) external returns (uint256 amount);

  /// @notice Pay off accrued debt of whitelisted protocols
  /// @param _token Token used
  function payOffDebtAll(IERC20 _token) external;

  /// @notice Remove `_protocol` from `_token` whitelist, send remaining balance to `_receiver`
  /// @param _protocol Protocol indetifier
  /// @param _index Entry of protocol in storage array
  /// @param _forceDebt If protocol has outstanding debt, pay off
  /// @param _receiver Receiver of remaining deposited balance
  /// @param _token Token used
  function cleanProtocol(
    bytes32 _protocol,
    uint256 _index,
    bool _forceDebt,
    address _receiver,
    IERC20 _token
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPoolStake {
  /// @notice Stake `_amount` of `_token`, send lockToken to `_receiver`
  /// @param _amount Amount to stake
  /// @param _receiver Account receiving the lockTokens
  /// @param _token Token used
  /// @return Amount of lockTokens representing deposited `_amount`
  function stake(
    uint256 _amount,
    address _receiver,
    IERC20 _token
  ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IStrategy.sol';

/// @title Sherlock Pool Strategy Controller
/// @author Evert Kors
/// @notice This contract is for every token pool
/// @dev Used for activate token assets for earning yield
/// @dev Contract is meant to be included as a facet in the diamond
/// @dev Storage library is used
/// @dev Storage pointer is calculated based on last _token argument
interface IPoolStrategy {
  function getStrategy(IERC20 _token) external view returns (IStrategy);

  function strategyRemove(
    IERC20 _token,
    address _receiver,
    IERC20[] memory _extraTokens
  ) external;

  function strategyUpdate(IStrategy _strategy, IERC20 _token) external;

  function strategyDeposit(uint256 _amount, IERC20 _token) external;

  function strategyWithdraw(uint256 _amount, IERC20 _token) external;

  function strategyWithdrawAll(IERC20 _token) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Lock Token
/// @author Evert Kors
/// @notice Lock tokens represent a stake in Sherlock
interface ILock is IERC20 {
  /// @notice Returns the owner of this contract
  /// @return Owner address
  /// @dev Should be equal to the Sherlock address
  function getOwner() external view returns (address);

  /// @notice Returns token it represents
  /// @return Token address
  function underlying() external view returns (IERC20);

  /// @notice Mint `_amount` tokens for `_account`
  /// @param _account Account to receive tokens
  /// @param _amount Amount to be minted
  function mint(address _account, uint256 _amount) external;

  /// @notice Burn `_amount` tokens for `_account`
  /// @param _account Account to be burned
  /// @param _amount Amount to be burned
  function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IRemove {
  /// @notice Swap `_token` amounts
  /// @param _token Token to swap
  /// @param _fmo Amount of first money out pool swapped
  /// @param _sherXUnderlying Amount of underlying being swapped
  /// @return newToken Token being swapped to
  /// @return newFmo Share of `_fmo` in newToken
  /// @return newSherxUnderlying Share of `_sherXUnderlying` in newToken
  function swap(
    IERC20 _token,
    uint256 _fmo,
    uint256 _sherXUnderlying
  )
    external
    returns (
      IERC20 newToken,
      uint256 newFmo,
      uint256 newSherxUnderlying
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
*
* This is gas optimized by reducing storage reads and storage writes.
* This code is as complex as it is to reduce gas costs.
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // owner of the contract
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    modifier onlyOwner {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
        _;
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount % 8 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount / 8];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount % 8 > 0) {
            ds.selectorSlots[selectorCount / 8] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            require(_newFacetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount % 8) * 32;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount / 8] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            require(_newFacetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount / 8;
            uint256 selectorInSlotIndex = (_selectorCount % 8) - 1;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex * 32));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount / 8;
                    oldSelectorInSlotPosition = (oldSelectorCount % 8) * 32;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
                selectorInSlotIndex--;
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex + 1;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/ILock.sol';
import '../interfaces/IStrategy.sol';

// TokenStorage
library PoolStorage {
  bytes32 constant POOL_STORAGE_PREFIX = 'diamond.sherlock.pool.';

  struct Base {
    address govPool;
    // Variable used to calculate the fee when activating the cooldown
    // Max value is type(uint32).max which creates a 100% fee on the withdrawal
    uint32 activateCooldownFee;
    // How much sherX is distributed to stakers of this token
    // The max value is type(uint16).max, which means 100% of the total SherX minted is allocated to this pool
    uint16 sherXWeight;
    // The last block the total amount of rewards were accrued.
    // Accrueing SherX increases the `unallocatedSherX` variable
    uint40 sherXLastAccrued;
    // Indicates if protocol are able to pay premiums with this token
    // If this value is true, the token is also included as underlying of the SherX
    bool premiums;
    // Protocol debt can only be settled at once for all the protocols at the same time
    // This variable is the block number the last time all the protocols debt was settled
    uint40 totalPremiumLastPaid;
    //
    // Staking
    //
    // Indicates if stakers can stake funds in the pool
    bool stakes;
    // Address of the lockToken. Representing stakes in this pool
    ILock lockToken;
    // The total amount staked by the stakers in this pool, including value of `firstMoneyOut`
    // if you exclude the `firstMoneyOut` from this value, you get the actual amount of tokens staked
    // This value is also excluding funds deposited in a strategy.
    uint256 stakeBalance;
    // All the withdrawals by an account
    // The values of the struct are all deleted if expiry() or unstake() function is called
    mapping(address => UnstakeEntry[]) unstakeEntries;
    // Represents the amount of tokens in the first money out pool
    uint256 firstMoneyOut;
    // If the `stakes` = true, the stakers can be rewarded by sherx
    // stakers can claim their rewards by calling the harvest() function
    // SherX could be minted before the stakers call the harvest() function
    // Minted SherX that is assigned as reward for the pool will be added to this value
    uint256 unallocatedSherX;
    // Non-native variables
    // These variables are used to calculate the right amount of SherX rewards for the token staked
    mapping(address => uint256) sWithdrawn;
    uint256 sWeight;
    // Storing the protocol token balance based on the protocols bytes32 indentifier
    mapping(bytes32 => uint256) protocolBalance;
    // Storing the protocol premium, the amount of debt the protocol builds up per block.
    // This is based on the bytes32 identifier of the protocol.
    mapping(bytes32 => uint256) protocolPremium;
    // The sum of all the protocol premiums, the total amount of debt that builds up in this token. (per block)
    uint256 totalPremiumPerBlock;
    // How much tokens are used as underlying for SherX
    uint256 sherXUnderlying;
    // Check if the protocol is included in the token pool
    // The protocol can deposit balances if this is the case
    mapping(bytes32 => bool) isProtocol;
    // Array of protocols that are registered in this pool
    bytes32[] protocols;
    // Active strategy for this token pool
    IStrategy strategy;
  }

  struct UnstakeEntry {
    // The block number the cooldown is activated
    uint40 blockInitiated;
    // The amount of lock tokens to be withdrawn
    uint256 lock;
  }

  function ps(IERC20 _token) internal pure returns (Base storage psx) {
    bytes32 position = keccak256(abi.encodePacked(POOL_STORAGE_PREFIX, _token));
    assembly {
      psx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

interface IStrategy {
  function want() external view returns (ERC20);

  function withdrawAll() external returns (uint256);

  function withdraw(uint256 _amount) external;

  function deposit() external;

  function balanceOf() external view returns (uint256);

  function sweep(address _receiver, IERC20[] memory _extraTokens) external;
}

