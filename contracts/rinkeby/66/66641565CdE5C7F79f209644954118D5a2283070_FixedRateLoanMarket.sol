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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IEIP20.sol";
import "./interfaces/IQollateralManager.sol";
import "./libraries/Verifier.sol";
import "./libraries/QConst.sol";
import "./libraries/QTypes.sol";

contract FixedRateLoanMarket is ERC20{

  using SafeMath for uint;

  /// @notice Address of the `QollateralManager`
  address public qollateralManagerAddress;

  /// @notice Address of the ERC20 token which the loan will be denominated
  address private principalTokenAddress;

  /// @notice UNIX timestamp (in seconds) when the market matures
  uint private maturity;

  /// @notice True if a nonce has been used for a Quote, false otherwise.
  /// Used for checking if a Quote is a duplicate.
  /// account => nonce => bool
  mapping(address => mapping(uint => bool)) private noncesUsed;

  /// @notice Storage for all borrows by a user
  /// account => principalPlusInterest
  mapping(address => uint) private accountBorrows;
  
  /// @notice Storage for the current total partial fill for a Quote
  /// signature => filled
  mapping(bytes => uint) private quoteFill;

  /// @notice Emitted when a borrower and lender are matched for a fixed rate loan
  event FixedRateLoan(
                      address borrower,
                      address lender,
                      uint principal,
                      uint principalPlusInterest);
  
  constructor(
              address _qollateralManagerAddress,
              address _principalTokenAddress,
              uint _maturity,
              string memory _name,
              string memory _symbol
              ) ERC20(_name, _symbol) {
    qollateralManagerAddress = _qollateralManagerAddress;
    principalTokenAddress = _principalTokenAddress;
    maturity = _maturity;
  }
  
  /** USER INTERFACE **/

  /// @notice Call this function to enter into FixedRateLoan as a borrower
  /// @param amount Amount that the borrower wants to execute, in case its not full size
  /// @param lender Account of the lender
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function borrow(                  
                  uint amount,
                  address lender,
                  uint quoteExpiryTime,
                  uint principal,
                  uint principalPlusInterest,
                  uint nonce,
                  bytes memory signature
                  ) external {
    QTypes.Quote memory quote = QTypes.Quote(
                                             address(this),
                                             lender,
                                             1, // side = 1 for lender
                                             quoteExpiryTime,
                                             principal,
                                             principalPlusInterest,
                                             nonce,
                                             signature
                                             );
    _processLoan(amount, quote);
  }

  /// @notice Call this function to enter into FixedRateLoan as a lender
  /// @param amount Amount that the lender wants to execute, in case its not full size
  /// @param borrower Account of the borrower
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function lend(
                uint amount,
                address borrower,
                uint quoteExpiryTime,
                uint principal,
                uint principalPlusInterest,
                uint nonce,
                bytes memory signature
                ) external {
    QTypes.Quote memory quote = QTypes.Quote(
                                             address(this),
                                             borrower,
                                             0, //side = 0 for borrower
                                             quoteExpiryTime,
                                             principal,
                                             principalPlusInterest,
                                             nonce,
                                             signature
                                             );
    _processLoan(amount, quote);
  }

  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  function repayBorrow(uint amount) external {
    
    // Don't allow users to pay more than necessary
    amount = Math.min(amount, accountBorrows[msg.sender]);

    // Repayment amount must be positive
    require(amount > 0, "zero repay amount");

    // Check borrower has approved contract spend    
    require(_checkApproval(msg.sender, principalTokenAddress, amount),
            "insufficient allowance");

    // Check borrower has enough balance
    require(_checkBalance(msg.sender, principalTokenAddress, amount),
            "insufficient balance");

    // Effects: Deduct from the account's total debts
    // Guaranteed not to underflow due to the flooring on amount above
    accountBorrows[msg.sender] -= amount;

    // Transfer amount from borrower to contract for escrow until maturity
    IEIP20 principalToken = IEIP20(principalTokenAddress);
    principalToken.transferFrom(msg.sender, address(this), amount);
  }

  /// @notice By setting the nonce in `noncesUsed` to true, this is equivalent to
  /// invalidating the Quote (i.e. cancelling the quote)
  /// param nonce Nonce of the Quote to be cancelled
  function cancelQuote(uint nonce) external {
    noncesUsed[msg.sender][nonce] = true;
  }

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return address
  function getPrincipalTokenAddress() external view returns(address){
    return principalTokenAddress;
  }

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function getMaturity() external view returns(uint){
    return maturity;
  }
  
  /// @notice True if a nonce has been used for a Quote, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function getNoncesUsed(address account, uint nonce) external view returns(bool){
    return noncesUsed[account][nonce];
  }

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function getAccountBorrows(address account) external view returns(uint){
    return accountBorrows[account];
  }

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function getQuoteFill(bytes memory signature) external view returns(uint){
    return quoteFill[signature];
  }
    
  /** INTERNAL FUNCTIONS **/

  /// @notice Intermediary function that handles some error handling, partial fills
  /// and managing uniqueness of nonces
  /// @param amount Amount msg.sender wants to execute, in case its not full size
  /// @param quote Quote struct for code simplicity / avoiding 'stack too deep' error
  function _processLoan(uint amount, QTypes.Quote memory quote) internal {

    address signer = Verifier.getSigner(
                                        quote.marketAddress,
                                        quote.quoter,
                                        quote.side,
                                        quote.quoteExpiryTime,
                                        quote.principal,
                                        quote.principalPlusInterest,
                                        quote.nonce,
                                        quote.signature
                                        );

    // Check if signature is valid
    require(signer == quote.quoter, "invalid signature");
    
    // Check that quote hasn't expired yet
    require(quote.quoteExpiryTime == 0 ||
            quote.quoteExpiryTime > block.timestamp,
            "quote expired");

    // The borrow amount cannot be greater than the remaining Quote size
    amount = Math.min(amount, quote.principal - quoteFill[quote.signature]);
    require(amount > 0, "quote already filled");

    // Check that the nonce hasn't already been used
    require(!noncesUsed[quote.quoter][quote.nonce], "invalid nonce");

    // TODO: Still need to check if borrower has sufficient collateral for loan
    
    // For partial fills, get the equivalent `amountPlusInterest` to pay at the end
    uint amountPlusInterest = _scaleAmountWithInterest(
                                                       amount,
                                                       quote.principal,
                                                       quote.principalPlusInterest
                                                       );
    
    // Determine who is the lender and who is the borrower before instantiating loan
    if(quote.side == 1){
      // If quote.side = 1, the quoter is the lender
      _createFixedRateLoan(msg.sender, quote.quoter, amount, amountPlusInterest);
    }else if (quote.side == 0){
      // If quote.side = 0, the quoter is the borrower
      _createFixedRateLoan(quote.quoter, msg.sender, amount, amountPlusInterest);
    }else {
      revert("invalid side"); //should not reach here
    }

    // Update the partial fills for the quote
    quoteFill[quote.signature] = quoteFill[quote.signature] + amount;
    
    // Nonce is used up once the partial fill equals the original principal amount
    if(quoteFill[quote.signature] == quote.principal){
      noncesUsed[quote.quoter][quote.nonce] = true;
    }
  }

  /// @notice Mint the future payment tokens to the lender, add the
  /// `principalPlusInterest` amount to the borrower's debts, and transfer the
  /// loan principal from lender to borrower
  /// @param borrower Account of the borrower
  /// @param lender Account of the lender
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  function _createFixedRateLoan(
                                address borrower,
                                address lender,
                                uint principal,
                                uint principalPlusInterest
                                ) internal {

    // Loan amount must be strictly positive
    require(principal > 0, "invalid principal amount");

    // Interest rate needs to be positive
    require(principal < principalPlusInterest, "invalid principalPlusInterest");

    // Cannot borrow from yourself
    require(lender != borrower, "invalid counterparty");

    // Cannot create a loan past its maturity time
    require(block.timestamp < maturity, "invalid maturity");

    // Check lender has approved contract spend
    require(_checkApproval(lender, principalTokenAddress, principal),
            "lender insufficient allowance");

    // Check lender has enough balance
    require(_checkBalance(lender, principalTokenAddress, principal),
            "lender insufficient balance");

    // Effects: Keep track of net borrows by the borrower
    // If the amount of qTokens exceeds the new borrow, just burn the borrow amount
    // from the qToken balance. Otherwise, burn the full qToken amount and add the
    // net borrow amount to the `accountBorrows.
    // NOTE: The borrow amount is the full `principalPlusInterest`, not the
    // initial `principal` amount. A potential future improvement could be
    // using a "principal plus interest accrued so far" value, which improves
    // capital efficiency, especially for long-dated borrows
    if(balanceOf(borrower) > principalPlusInterest){

      // Just deduct the full `principalPlusBalance` from the borrower's qTokens
      _burn(borrower, principalPlusInterest);
    }else{

      // Get the net borrowed amount
      uint remaining = principalPlusInterest - balanceOf(borrower);

      // Add the net borrowed amount to total `accountBorrows`
      accountBorrows[borrower] = accountBorrows[borrower].add(remaining);
      
      // Get rid of any remaining qTokens
      if(balanceOf(borrower) > 0){
        _burn(borrower, balanceOf(borrower));
      }     
    }

    // Effects: Keep track of net lends by the lender.
    // If the lends exceed the borrows, mint qTokens to the lender, reedemable
    // at maturity. Otherwise, subtract that out from te account borrows
    if(principalPlusInterest > accountBorrows[lender]){

      //Guaranteed not to underflow
      uint netLends = principalPlusInterest - accountBorrows[lender];

      accountBorrows[lender] = 0;
      _mint(lender, netLends);
    }else{

      //Just deduct the `principalPlusInterest` from the accountBorrows
      //Guaranteed not to underflow
      accountBorrows[lender] -= principalPlusInterest;
    }

    // Record that the lender/borrow have participated in this market
    IQollateralManager qm = IQollateralManager(qollateralManagerAddress);
    if(!qm.getAccountMarkets(address(this), lender)){
      qm._addAccountMarket(lender);
    }
    if(!qm.getAccountMarkets(address(this), borrower)){
      qm._addAccountMarket(borrower);
    }
    
    // Emit the matched borrower and lender and fixed rate loan terms
    emit FixedRateLoan(borrower, lender, principal, principalPlusInterest);
    
    // Transfer the principal from lender to borrower
    IEIP20 principalToken = IEIP20(principalTokenAddress);
    principalToken.transferFrom(lender, borrower, principal);
  }



  /// @notice Applies the implied interest on the amount given the starting principal and
  /// ending principalPlusInterest
  /// @param amount Value to apply the implied interest on
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @return uint Amount plus interest
  function _scaleAmountWithInterest(
                                    uint amount,
                                    uint principal,
                                    uint principalPlusInterest
                                    ) internal pure returns(uint){
    uint rate = principalPlusInterest.mul(QConst.MANTISSA_DEFAULT).div(principal);
    uint amountPlusInterest = amount.mul(rate).div(QConst.MANTISSA_DEFAULT);
    return amountPlusInterest;
  }
                                    
  /// @notice Verify if the user has enough token balance
  /// @param userAddress Address of the account to check
  /// @param tokenAddress Address of the ERC20 token
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address userAddress,
                         address tokenAddress,
                         uint256 amount
                         ) internal view returns(bool){
    if(IEIP20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }
  
  /// @notice Verify if the user has approved the smart contract for spend
  /// @param userAddress Address of the account to check
  /// @param tokenAddress Address of the ERC20 token
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address userAddress,
                          address tokenAddress,
                          uint256 amount
                          ) internal view returns(bool) {
    if(IEIP20(tokenAddress).allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  }




  /** ERC20 Implementation **/

  /// @notice Number of decimal places of the qToken should match the number
  /// of decimal places of the underlying token
  /// @return uint8 Number of decimal places
  function decimals() public view override returns(uint8) {
    //TODO possible for ERC20 to not define decimals. Do we need to handle this?
    return IEIP20(principalTokenAddress).decimals();
  }
  
  /// @notice This hook requires users trying to transfer their qTokens to only
  /// be able to transfer tokens in excess of their current borrows. This is to
  /// protect the protocol from users gaming the collateral management system
  /// by borrowing off of the qToken and then immediately transferring out the
  /// qToken to another address, leaving the borrowing account uncollateralized
  /// @param from Address of the sender
  /// @param to Address of the receiver
  /// @param amount Amount of tokens to send
  function _beforeTokenTransfer(
                                address from,
                                address to,
                                uint256 amount
                                ) internal override {

    // Ignore hook for 0x000... addresses (e.g. _mint, _burn functions)
    if(from == address(0) || to == address(0)){
      return;
    }

    // Transfers rejected if borrows exceed lends
    require(balanceOf(from) > accountBorrows[from], "ERC20: account borrows exceeds balance");
    
    // Safe from underflow after previous require statement
    unchecked {
      uint maxTransferrable = balanceOf(from) - accountBorrows[from];
      require(amount <= maxTransferrable, "ERC20: amount must be in excess of borrows");
    }
      
  }

}

pragma solidity ^0.8.9;

interface IEIP20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity ^0.8.9;

interface IQollateralManager {

  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param tokenAddress Address of the token the collateral will be denominated in
  /// @param amount Amount to deposit (in local ccy)
  function depositCollateral(address tokenAddress, uint amount) external;

  /// @notice get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function getTotalCollateralValue(address account) external view returns(uint);

  /// @notice get the `riskFactor` weighted value (in USD) of all the collateral
  /// deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function getTotalCollateralValueWeighted(address account) external view returns(uint);

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed.
  /// @return answer uint256, decimals uint8
  function getPriceFeed(address oracleFeed) external view returns(uint256, uint8);

  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account  
  /// @return uint Balance in local
  function getAccountBalances(
                              address tokenAddress,
                              address account
                              ) external view returns(uint);

  /// @notice Get iterable list of assets which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function getIterableAccountAssets(
                                    address account
                                    ) external view returns(address[] memory);

  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function getIterableAccountMarkets(
                                     address account
                                     ) external view returns(address[] memory);

  /// @notice Quick lookup of whether an account has nonzero balance in an asset.
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account
  /// @return bool True if user has balance, false otherwise
  function getAccountAssets(
                            address tokenAddress,
                            address account
                            ) external view returns(bool);

  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param fixedRateLoanMarketAddress Address of `FixedRateLoanMarket` contract
  /// @param account User account
  /// @return bool True if participated, false otherwise
  function getAccountMarkets(
                             address fixedRateLoanMarketAddress,
                             address account
                             ) external view returns(bool);

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateLoanMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `totalBorrowValue`. Only the `FixedRateLoanMarket` contract itself may call
  /// this function
  /// @param account User account
  function _addAccountMarket(address account) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QConst {
  
  /// @notice Generic mantissa corresponding to ETH decimals
  uint internal constant MANTISSA_DEFAULT = 1e18;

  /// @notice Mantissa for stablecoins
  uint internal constant MANTISSA_STABLECOIN = 1e6;
  
  /// @notice `riskFactor` has up to 8 decimal places precision
  uint internal constant MANTISSA_RISK_FACTOR = 1e8;

  /// @notice `riskFactor` cannot be below .05
  uint internal constant MIN_RISK_FACTOR = .05e8;

  /// @notice `riskFactor` cannot be above .95
  uint internal constant MAX_RISK_FACTOR = .95e8;
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if a asset is defined, false otherwise
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member riskFactor Value from 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member maturities Iterable storage for all enabled maturities
  struct Asset {
    bool isEnabled;
    address oracleFeed;
    uint riskFactor;
    uint[] maturities;
  }

  

  
  /// @notice Contains all the fields of a FixedRateLoan agreement
  /// @member startTime Starting timestamp  when the loan is instantiated
  /// @member maturity Ending timestamp when the loan terminates
  /// @member principal Size of the loan
  /// @member principalPlusInterest Final amount that must be paid by borrower
  /// @member amountRepaid Current total amount repaid so far by borrower
  /// @member lender Account of the lender
  /// @member borrower Account of the borrower
  struct FixedRateLoan {
    uint startTime;
    uint maturity;
    uint principal;
    uint principalPlusInterest;
    uint amountRepaid;
    address lender;
    address borrower;
  }

  /// @notice Contains all the fields of a published Quote
  /// @param marketAddress Address of the `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Initial size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  struct Quote {
    address marketAddress;
    address quoter;
    uint8 side;
    uint quoteExpiryTime;
    uint principal;
    uint principalPlusInterest;
    uint nonce;
    bytes signature;
  }
  
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Verifier {

  /// @notice Recover the signer of a Quote given the plaintext inputs and signature
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return address signer of the message
  function getSigner(
                     address marketAddress,
                     address quoter,
                     uint8 side,
                     uint quoteExpiryTime,
                     uint principal,
                     uint principalPlusInterest,
                     uint nonce,
                     bytes memory signature
                     ) internal pure returns(address){
    bytes32 messageHash = getMessageHash(
                                         marketAddress,
                                         quoter,
                                         side,
                                         quoteExpiryTime,
                                         principal,
                                         principalPlusInterest,
                                         nonce
                                         );
    return  _recoverSigner(messageHash, signature);
  }

  /// @notice Hashes the fields of a Quote into an Ethereum message hash
  /// @param marketAddress Address `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @return bytes32 message hash
  function getMessageHash(
                          address marketAddress,
                          address quoter,
                          uint8 side,
                          uint quoteExpiryTime,
                          uint principal,
                          uint principalPlusInterest,
                          uint nonce
                          ) internal pure returns(bytes32) {
    bytes32 unprefixedHash = keccak256(abi.encodePacked(
                                                        marketAddress,
                                                        quoter,
                                                        side,
                                                        quoteExpiryTime,
                                                        principal,
                                                        principalPlusInterest,
                                                        nonce
                                                        ));
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", unprefixedHash));
  }

  /// @notice Recovers the address of the signer of the `messageHash` from the signature. It should be used to check versus the cleartext address given to verify the message is indeed signed by the owner
  /// @param messageHash Hash of the loan fields
  /// @param signature The candidate signature to recover the signer from
  /// @return address This is the recovered signer of the `messageHash` using the signature
  function _recoverSigner(
                         bytes32 messageHash,
                         bytes memory signature
                         ) private pure returns(address) {
    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
    
    //built-in solidity function to recover the signer address using
    // the messageHash and signature
    return ecrecover(messageHash, v, r, s);
  }

  
  /// @notice Helper function that splits the signature into r,s,v components
  /// @param signature The candidate signature to recover the signer from
  /// @return r bytes32, s bytes32, v uint8
  function _splitSignature(bytes memory signature) private pure returns(
                                                                      bytes32 r,
                                                                      bytes32 s,
                                                                      uint8 v) {
    require(signature.length == 65, "invalid signature length");
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }
  }
}