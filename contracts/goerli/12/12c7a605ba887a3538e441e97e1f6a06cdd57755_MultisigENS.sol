// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultisigWallet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FeeCollector.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @author Santiago Del Valle - <[email protected]>
contract ERC20MultisigWallet is MultisigWallet {
    using SafeMath for uint256;

    event WithDrawal(address indexed _token, address indexed _to, uint256 _amount);

    FeeCollector private _feeCollector;

    constructor(address[] memory _owners, uint256 _required, address _feeCollectorAddress) MultisigWallet(_owners, _required) {
        require(_feeCollectorAddress != address(0), "Fee Collector cannot be 0");
        _feeCollector = FeeCollector(_feeCollectorAddress);
    }

    function getFee() public view returns(uint256) {
        return _feeCollector.getFeeByMultisig(address(this));
    }

    function getFeeCollector() public view returns(address) {
        return address(_feeCollector);
    }

    function getWithdrawWithFee(uint256 _amount) public view returns(uint256, uint256) {
        uint256 fee = getFee();
        uint256 amountToUser = _amount.sub(_amount.mul(fee).div(1000)); // amount - (amount*fee/100)
        uint256 amountToCollector = _amount - amountToUser;
        return (amountToUser, amountToCollector);
    }

    /// @dev Withdraws token balance from the wallet
    /// @param _token Address of ERC20 token to withdraw.
    /// @param _to Address of receiver
    /// @param _amount Amount to withdraw
    function withdraw(address _token, address _to, uint256 _amount) public onlyWallet {
        require(_token != address(0), "Token address cannot be 0");
        require(_to != address(0), "recipient address cannot be 0");
        require(_amount > 0, "amount cannot be 0");

        require(ERC20(_token).balanceOf(address(this)) > 0, "Contract does not have any balance");
        require(ERC20(_token).balanceOf(address(this)) > _amount, "Contract does not have such balance");

        /** transfer amount */
        /** transfer fee to feeCollector */
        (uint256 transferAmount, uint256 feeAmount) = getWithdrawWithFee(_amount);
        ERC20(_token).transfer(_to, transferAmount);
        ERC20(_token).transfer(address(_feeCollector), feeAmount);
        emit WithDrawal(_token, _to, transferAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableCustom.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FeeCollector is OwnableCustom {
    using SafeMath for uint256;

    event SetFee(uint256 fee);
    event SetFeeByMultisig(address indexed multisigAddress, uint256 fee);
    event SetFeeCollector(address indexed feeCollector);
    event Whitelist(address indexed multisigAddress, bool isWhitelisted);
    event Withdraw(address indexed token, address indexed receiver, uint256 amount);

    mapping(address => uint256) private _feeByMultisig;
    mapping(address => bool) private _isWhitelisted;

    address private _feeCollector;
    
    uint256 private _fee;

    //upgradability
    bool internal _initialized;

    /** @param feeCollector Address that will receive tokens when withdraw function is called*/
    /** @param fee Global fee charged, i.e. 300 means 30%, 30 means 3%, 3 means 0.3%*/
    function initialize(address feeCollector, uint256 fee) public {
        require(feeCollector != address(0), "Fee Collector address cannot be 0");
        require(!_initialized, "Already initialized");
        require(fee.div(1000) == 0, "Fee cannot have more than 3 digits");
        _feeCollector = feeCollector;
        _fee = fee;
        _setOwner(feeCollector); 
        _initialized = true;
        emit SetFee(fee);
        emit SetFeeCollector(feeCollector);
    }

    /** @param feeCollector Address that will receive tokens when withdraw function is called*/
    function setFeeCollector(address feeCollector) external virtual onlyOwner {
        require(feeCollector != address(0), "Fee Collector address cannot be 0");
        _feeCollector = feeCollector;
        emit SetFeeCollector(feeCollector);
    }

    /** @param fee Global fee charged, i.e. 300 means 30%, 30 means 3%, 3 means 0.3%*/
    function setFee(uint256 fee) external virtual onlyOwner {
        require(fee.div(1000) == 0, "Fee cannot have more than 3 digits");
        _fee = fee;
        emit SetFee(fee);
    }

    /** @param multisigAddress Address of multisig tha will have a custom fee*/
    /** @param fee Custom fee charged, i.e. 3*10^18 (3000000000000000000) means 3%, 0.3*10^18 (300000000000000000) means 0.3%*/
    function setFeeByMultisig(address multisigAddress, uint256 fee) external virtual onlyOwner {
        _isWhitelisted[multisigAddress] = false;
        _feeByMultisig[multisigAddress] = fee;
        emit SetFeeByMultisig(multisigAddress, fee);
        emit Whitelist(multisigAddress, false);
    }

    /** @param multisigAddress Address of multisig tha will be whitelisted, fee will be 0*/
    /** @param allow True to add to whitelist and false to remove from whitelist*/
    function whitelistMultisig(address multisigAddress, bool allow) external virtual onlyOwner { 
        require(multisigAddress != address(0), "Multisig Address cannot be 0");
        _isWhitelisted[multisigAddress] = allow;
        emit Whitelist(multisigAddress, allow);
    }

    /** @dev Withdraws token balance from the wallet and sends all balance to feeCollector*/ 
    /** @param _token Token Address to withdraw*/
    function withdraw(address _token) external virtual onlyOwner {
        require(_token != address(0), "Token address cannot be 0");
        ERC20 erc20 = ERC20(_token); 
        uint256 _amount = erc20.balanceOf(address(this));
        require(_amount > 0, "Contract does not have any balance");
        erc20.transfer(_feeCollector, _amount);
        emit Withdraw(_token, _feeCollector, _amount);
    }

    /** Getters */
    function getFeeByMultisig(address multisigAddress) external virtual view returns(uint256) {
        if(_isWhitelisted[multisigAddress]) return 0;
        if(_feeByMultisig[multisigAddress] == 0) {
            return _fee;
        }
        return _feeByMultisig[multisigAddress];
    }

    function getFee() external virtual view returns(uint256) { 
        return _fee;
    }

    function getFeeCollector() external virtual view returns(address) {  
        return _feeCollector;
    }

    function isWhitelisted(address multisigAddress) external virtual view returns(bool) { 
        return _isWhitelisted[multisigAddress];
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableCustom.sol";
import "./ERC20MultisigWallet.sol"; 
import "../libraries/Create2.sol";

contract MultisigDeployer is OwnableCustom  {

    using Create2 for uint256;

    event NewMultisig(address indexed _creator, address indexed _multisigAddress);
    event SetFeeCollector(address indexed feeCollector);

    address[] private _multisigs;
    address public feeCollector;
    mapping(address => bool) private _isMultisigAdded;

    //upgradability
    bool internal _initialized; 
 
    function initialize(address _owner, address _feeCollector) public {
        require(!_initialized, "Contract already initialized");
        require(_feeCollector != address(0), "Fee collector address cannot be 0");
        require(_owner != address(0), "Contract owner cannot be 0");
        feeCollector = _feeCollector;
        _setOwner(_owner); 
        _initialized = true;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "Fee collector address cannot be 0");
        feeCollector = _feeCollector;
        emit SetFeeCollector(_feeCollector);
    }

    function getAll() external virtual view returns(address[] memory) {
        return _multisigs;
    }

    function isMultisigAdded(address _multisig) external virtual view returns(bool) {
        return _isMultisigAdded[_multisig];
    }

    function getBytecode(address[] calldata _owners, uint256 _required) public view returns (bytes memory) {
        bytes memory bytecode = type(ERC20MultisigWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owners, _required, feeCollector));
    }

    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        return _salt.getAddress(bytecode, address(this));
    }

    function deployMultisig(address[] calldata _owners, uint256 _required) external virtual {
        ERC20MultisigWallet multisigWallet = new ERC20MultisigWallet(_owners, _required, feeCollector);
        address multisigAddress = address(multisigWallet);
        _multisigs.push(multisigAddress);
        _isMultisigAdded[multisigAddress] = true;
        emit NewMultisig(msg.sender, multisigAddress);
    }

    function deployMultisigPrecomputed(bytes memory bytecode, uint _salt) public payable {
        address multisigAddress = _salt.deployContract(bytecode);
        _multisigs.push(multisigAddress);
        _isMultisigAdded[multisigAddress] = true;
        emit NewMultisig(msg.sender, multisigAddress);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MultisigDeployer.sol";
import "../interfaces/IMultisigENS.sol";

/// @title Multisignature wallet ENS- Allows to set a ENS over a multisig and over a user.
/// @author Santiago Del Valle - <[email protected]>
contract MultisigENS is IMultisigENS, Ownable {

    MultisigDeployer private _msigDeployer;

    mapping (address => string) private _msigNames;
    mapping (address => string) private _userNames;
 
    modifier onlyMultisig {
        require(_msigDeployer.isMultisigAdded(msg.sender), "Multisig is not added");
        _;
    }

    constructor(address _msigDeployerAddress) {
        require(_msigDeployerAddress != address(0), "Contract address cannot be 0"); 
        _msigDeployer = MultisigDeployer(_msigDeployerAddress);
        emit SetMultisigDeployerAddress(_msigDeployerAddress);
    }

    function setMultisigName(string memory _name) external virtual override onlyMultisig {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "Contract name cannot be empty");
        _msigNames[msg.sender] = _name;
        emit SetContractName(msg.sender, _name);
    }

    function setUserName(string memory _name) external virtual override {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "User name cannot be empty");
        _userNames[msg.sender] = _name;
        emit SetUserName(msg.sender, _name);
    }

    function setMultisigDeployerAddress(address _msigDeployerAddress) external virtual override onlyOwner {
        require(_msigDeployerAddress != address(0), "Contract address cannot be 0");
        _msigDeployer = MultisigDeployer(_msigDeployerAddress);
        emit SetMultisigDeployerAddress(_msigDeployerAddress);
    }

    function getMultisigDeployerAddress() external virtual override view returns(address) {
        return address(_msigDeployer);
    }

    function getMultisigName(address _msig) external virtual override view returns(string memory) {
        return _msigNames[_msig];
    }

    function getUserName(address _user) external virtual override view returns(string memory) {
        return _userNames[_user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <[email protected]>
contract MultisigWallet  {

    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    /*
     *  Constants
     */
    uint256 constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        string description;
        address destination;
        uint256 value;
        bytes data;
        bool executed;
        uint256 timestamp;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this), "Only wallet");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "Owner exists");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner does not exists");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].destination != address(0), "Tx doesn't exist");
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(confirmations[transactionId][owner], "not confirmed");
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(!confirmations[transactionId][owner], "is already confirmed");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "tx already executed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "address is null");
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0, "invalid requirement");
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    fallback() virtual external payable {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    /// @dev Receive function allows to deposit ether.
    receive() virtual external payable {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.

    constructor(address[] memory _owners, uint256 _required) validRequirement(_owners.length, _required) {
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0), "is already owner");
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner to add.
    function addOwner(address owner)  virtual public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to remove.
    function removeOwner(address owner) virtual public onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        int256 ownerIndex = _indexOf(owners, owner);
        owners[uint256(ownerIndex)] = owners[owners.length - 1];
        owners.pop();

        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner) virtual public onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner) {
        for(uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required) virtual public onlyWallet validRequirement(owners.length, _required) {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// return Returns transaction ID.
    function submitTransaction(address destination, uint256 value, bytes memory data, string memory description) virtual public ownerExists(msg.sender)
    returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data, description);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId) virtual public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint256 transactionId) virtual public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId) virtual public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint256 value, uint256 dataLength, bytes memory data) virtual internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// return Confirmation status.
    function isConfirmed(uint256 transactionId) virtual public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// return Returns transaction ID.
    function addTransaction(address destination, uint256 value, bytes memory data, string memory description) virtual internal
     notNull(destination) returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            description: description,
            destination: destination,
            value: value,
            data: data,
            executed: false,
            timestamp: block.timestamp
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// return Number of confirmations.
    function getConfirmationCount(uint256 transactionId) virtual public view returns (uint256 count) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])  count += 1;
        }
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed) virtual public view returns (uint256 count) {
        for (uint256 i = 0; i < transactionCount; i++) {
            if ( pending && !transactions[i].executed || executed && transactions[i].executed)
                count += 1;
        }
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// return Returns array of owner addresses.
    function getConfirmations(uint256 transactionId) virtual public view returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// return Returns array of transaction IDs.
    function getTransactionIds(uint256 from, uint256 to, bool pending, bool executed) virtual public view returns (uint256[] memory _transactionIds) {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++)
            if (   pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++){
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }

    // function getTransactionIds(bool pending, bool executed) virtual public view returns (uint256[] memory _transactionIds) {
    //     uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
    //     uint256 pendingTxCount = 0;
    //     uint256 executedtxCount = 0;
    //     uint256 count = 0;
    //     uint256 i;
    //     for (i = 0; i < transactionCount; i++) {
    //         if(pending && !transactions[i].executed) {
    //             transactionIdsTemp[pendingTxCount] = i;
    //             pendingTxCount += 1;
    //         }
    //         if(executed && transactions[i].executed) {
    //             transactionIdsTemp[executedtxCount] = i;
    //             executedtxCount += 1;
    //         }
    //     }
            
    //     _transactionIds = new uint256[](transactionCount);
    //     for (i = 0; i < transactionCount; i++){
    //         _transactionIds[i] = transactionIdsTemp[i];
    //     }
    // }

    function _indexOf(address[] memory array, address _address) private pure returns (int256) {
        for(uint256 i = 0; i < array.length; i++) {
            if(array[i] == _address) return int256(i);
        }
        return int8(-1);
    } 

    function getOwners() virtual public view returns (address[] memory) {
        return owners;
    }

    function getTransaction(uint256 transactionId) virtual public view returns (Transaction memory) {
        return transactions[transactionId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

contract OwnableCustom is Context  {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function _setOwner(address _newOwner) internal {
        require(_owner == address(0), "Owner already set");
        require(_newOwner != address(0), "New Owner cannot be 0");
        _owner = _newOwner;
        emit OwnershipTransferred(address(0), _newOwner);
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
pragma solidity ^0.8.0;

interface IMultisigENS {

    event SetMultisigDeployerAddress(address indexed msigDeployerAddress);
    event SetContractName(address indexed msigAddress, string name);
    event SetUserName(address indexed userAddress, string name);

    function setMultisigName(string memory _name) external;

    function setUserName(string memory _name) external;

    function setMultisigDeployerAddress(address _msigDeployerAddress) external;

    function getMultisigDeployerAddress() external view returns(address);

    function getMultisigName(address _msig) external view returns(string memory);

    function getUserName(address _user) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Create2 {

    function getAddress(uint _salt, bytes memory bytecode, address contractCreator) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(contractCreator),
                _salt,
                keccak256(bytecode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    function deployContract(uint _salt, bytes memory bytecode) internal returns(address addr) {

        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                0, // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }


    }
}

