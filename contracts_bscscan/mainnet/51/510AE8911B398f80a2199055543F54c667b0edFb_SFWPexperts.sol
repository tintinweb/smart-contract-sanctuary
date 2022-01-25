/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
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
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// File: contracts/SFWPexperts.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Use these for deploying
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

// Use these on remix for flattening the contract




contract SFWPexperts is ERC20("Next Intelligence", "NEXT"), Ownable
{
    using SafeMath for uint256;

    mapping (address => bool) private adminMap;
    mapping (address => bool) private allowedRevertTransfer;
    mapping (address => uint256) private listOfTimeLockedAccounts;

    /**
     * @dev Modifier to check if user has administrative privileges
     */
    modifier onlyAdmin() {
        require(adminMap[_msgSender()] == true || _msgSender() == owner(), "Only administrator can do this action");

        _;
    }

    /**
     * @dev Modifier to check if user account is locked
     */
    modifier isAddressLocked(address account) {
        require(listOfTimeLockedAccounts[account] < block.timestamp, "This account is locked, and you cant move any funds from it");

        _;
    }

    /**
     * @dev Smart Contract Constructor
     *
     * @param _adminList       List of addresses that should have administrative privilages
     * @param _treasuryAmount  How many tokens should be emitted. This is final amount of tokens that will be ever emitted
     * @param _treasuryAccount On which account we will mint tokens
     * @param _advisorList     Which accounts are advisor account, which should be locked for a time
     * @param _advisorLockTime Timestamp when advisor account should be unlocked
     */
    constructor (
        address[] memory _adminList,
        uint256 _treasuryAmount,
        address _treasuryAccount,
        address[] memory _advisorList,
        uint256 _advisorLockTime
    ) {
        //_setupDecimals(8);

        for (uint it = 0; it < _adminList.length; ++it) {
            adminMap[_adminList[it]] = true;
        }

        for (uint it = 0; it < _advisorList.length; ++it) {
            _lockAccountTransferUntil(_advisorList[it], _advisorLockTime);
        }

        _mint(_treasuryAccount, _treasuryAmount);
    }

    /**
     * @dev Burn tokens. Only admin can do this
     */
    function burn(uint256 _amount) onlyAdmin isAddressLocked(msg.sender) external {
        _burn(_msgSender(), _amount);

        emit BurnedTokens(_msgSender(), _msgSender(), _amount);
    }

    /**
     * @dev Burn tokens from any account. Only admin can do this
     */
    function burnFrom(address _account, uint256 _amount) onlyAdmin isAddressLocked(_account) external {
        _burn(_account, _amount);

        emit BurnedTokens(_msgSender(), _account, _amount);
    }

    /**
     * @dev Allow user to add itself to revert list
     */
    function selfAddToRevertList() external {
        _addToRevertList(_msgSender(), _msgSender());
    }

    /**
     * @dev Allow user to remove itself from revert list
     */
    function selfRemoveFromRevertList() external {
        _removeFromRevertList(_msgSender(), _msgSender());
    }

    /**
     * @dev Allow admin to add any user to revert list
     *
     * @param _holder Address to add
     */
    function addAnyToRevertList(address _holder) onlyAdmin external {
        _addToRevertList(_msgSender(), _holder);
    }

    /**
     * @dev Allow admin to remove any user from revert list
     *
     * @param _holder Address to remove
     */
    function removeAnyFromRevertList(address _holder) onlyAdmin external {
        _removeFromRevertList(_msgSender(), _holder);
    }

    /**
     * @dev Implementation of adding user to revert list
     *
     * @param _operator Which account is adding user to revert list
     * @param _holder Which account is being added to revert list
     */
    function _addToRevertList(address _operator, address _holder) internal {
        require(allowedRevertTransfer[_holder] == false, "This address is already on list");

        allowedRevertTransfer[_holder] = true;

        emit AddedToRevertList(_operator, _holder);
    }

    /**
     * @dev Implementation of removing user from revert list
     *
     * @param _operator Which account is removing user from revert list
     * @param _holder Which account is being removed from revert list
     */
    function _removeFromRevertList(address _operator, address _holder) internal {
        require(allowedRevertTransfer[_holder] == true, "This address is not on list");

        allowedRevertTransfer[_holder] = false;

        emit RemovedFromRevertList(_operator, _holder);
    }

    /**
     * @dev Check if user is on revert list
     */
    function isAddressOnRevertList(address _tokenHolder) view external returns (bool) {
        return allowedRevertTransfer[_tokenHolder];
    }

    /**
     * @dev Revert transaction
     *
     * @param _from  From which address we are reverting tokens. This address must be on revert list.
     * @param _to    To which address we are moving tokens. This address doesn't need to be on revert list.
     * @param _value How many tokens should be moved
     * @param _data  Additional data passed to TransactionReverted event
     */
    function revertTransfer(address _from, address _to, uint256 _value, bytes calldata _data) onlyAdmin isAddressLocked(_from) external {
        require(allowedRevertTransfer[_from] == true, "User need to be whitelisted");

        _transfer(_from, _to, _value);

        emit TransactionReverted(_msgSender(), _from, _to, _value, _data);
    }

    /**
     * @inheritdoc ERC20
     */
    function transfer(address recipient, uint256 amount) public override isAddressLocked(msg.sender) returns (bool) {
        return ERC20.transfer(recipient, amount);
    }

    /**
     * @inheritdoc ERC20
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override isAddressLocked(sender) returns (bool) {
        return ERC20.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Transfer With data, this is just a wrapper over transfer call, that allows attaching additional data to
     *      transfer. Standard transfer event is still emitted to be compatible with rest of the ecosystem.
     */
    function transferWithData(address _to, uint256 _value, bytes calldata _data) onlyAdmin isAddressLocked(msg.sender) external returns (bool result) {
        result = transfer(_to, _value);

        emit TransferWithData(msg.sender, _to, _value, _data);
    }

    /**
     * @dev Transfer From With data, this is just a wrapper over transferFrom call, that allows attaching additional data to
     *      transfer. Standard transfer event is still emitted to be compatible with rest of the ecosystem.
     */
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external onlyAdmin isAddressLocked(_from) returns (bool result) {
        result = transferFrom(_from, _to, _value);

        emit TransferFromWithData(msg.sender, _from, _to, _value, _data);
    }

    /**
     * @dev Allows locking any account for any amount of time. This method is internal, and doesnt check if caller is admin.
     *
     * @param _holder Which account should be locked
     * @param _time Unix timestamp, for how long user should be locked
     */
    function _lockAccountTransferUntil(address _holder, uint256 _time) internal {
        listOfTimeLockedAccounts[_holder] = _time;

        emit AccountLocked(msg.sender, _holder, _time);
    }

    /**
     * @dev Unlock account. This method is internal, and doesnt check if caller is admin.
     *
     * @param _holder Which account should be unlocked
     */
    function _unlockAccountTransfer(address _holder) internal {
        require(listOfTimeLockedAccounts[_holder] >= block.timestamp, "Account not locked");

        listOfTimeLockedAccounts[_holder] = 0;

        emit AccountUnlocked(msg.sender, _holder);
    }

    /**
     * @dev Lock account. This in admin only api. Admin can't shorten his own sentence.
     *
     * @param _holder Which account should be locked
     * @param _time For how long this account should be locked
     */
    function lockAccountTransferUntil(address _holder, uint256 _time) onlyAdmin external {
        if (_holder == msg.sender) {
            require(_time > listOfTimeLockedAccounts[_holder], "You can't shorten your own lock");
        }

        _lockAccountTransferUntil(_holder, _time);
    }

    /**
     * @dev Unlock account. This is admin only api. Admin can't unlock his own account.
     *
     * @param _holder Which account should be locked
     */
    function unlockAccountTransfer(address _holder) onlyAdmin external {
        require(_holder != msg.sender, "You can't unlock your own account");

        _unlockAccountTransfer(_holder);
    }

    /**
     * @dev Check if account _holder is locked
     */
    function isAccountLocked(address _holder) external view returns (bool) {
        return listOfTimeLockedAccounts[_holder] > block.timestamp;
    }

    /**
     * @dev Get account unlock time for _holder.
     */
    function getAccountUnlockTime(address _holder) external view returns (uint256) {
        return listOfTimeLockedAccounts[_holder];
    }

    /**
     * @dev Add new admin by owner
     */
    function addToAdmin(address _admin) onlyOwner external {
        require(adminMap[_admin] == false);

        adminMap[_admin] = true;

        emit AddToAdminList(_msgSender(), _admin);
    }

    /**
    * @dev Remove admin by owner
    */
    function removeFromAdmin(address _admin) onlyOwner external {
        require(adminMap[_admin] == true);

        adminMap[_admin] = false;

        emit RemoveFromAdminList(_msgSender(), _admin);
    }

    /**
     * @dev Check if user is an admin or owner
     */
    function isAddressOnAdminList(address _tokenHolder) view external returns (bool) {
        return adminMap[_tokenHolder] || _tokenHolder == owner();
    }

    function renounceOwnership() override view public onlyOwner {
        revert("This method is not supported");
    }

    /**
     * @inheritdoc ERC20
     */
    function approve(address spender, uint256 amount) override public returns (bool) {
        require(spender != _msgSender(), "You can't grant your own account allowance");

        return ERC20.approve(spender, amount);
    }

    /**
     * @inheritdoc ERC20
     */
    function increaseAllowance(address spender, uint256 addedValue) override public returns (bool) {
        require(spender != _msgSender(), "You can't grant your own account allowance");

        return ERC20.increaseAllowance(spender, addedValue);
    }

    /**
     * @inheritdoc ERC20
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) override public returns (bool) {
        require(spender != _msgSender(), "You can't grant your own account allowance");

        return ERC20.decreaseAllowance(spender, subtractedValue);
    }

    event AddToAdminList(address indexed operator, address indexed newAdmin);
    event RemoveFromAdminList(address indexed operator, address indexed newAdmin);

    event AddedToRevertList(address indexed operator, address indexed tokenHolder);
    event RemovedFromRevertList(address indexed operator, address indexed tokenHolder);

    event TransactionReverted(address indexed operator, address indexed from, address indexed to, uint256 value, bytes data);
    event BurnedTokens(address indexed operator, address indexed tokenHolder, uint256 value);

    event TransferWithData(address indexed from, address indexed to, uint256 value, bytes data);
    event TransferFromWithData(address indexed operator, address indexed from, address indexed to, uint256 value, bytes data);

    event AccountLocked(address indexed operator, address indexed tokenHolder, uint256 unixTimestamp);
    event AccountUnlocked(address indexed operator, address indexed tokenHolder);
}