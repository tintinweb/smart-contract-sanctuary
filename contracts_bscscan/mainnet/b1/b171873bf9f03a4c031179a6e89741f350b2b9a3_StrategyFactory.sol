/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
  function decimals() external view returns (uint8);
}



/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./IERC20Extended.sol";

interface IERC20WETH is IERC20Extended {
  function deposit() external payable;
}



/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IERC20.sol";
////import "../../utils/Context.sol";

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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./IERC20WETH.sol";

interface IBasicDefinitions {
  /** START: Basic Config Getters **/

  function one() external view returns (uint256);

  function yearInSeconds() external view returns (uint256);

  function weth() external view returns (IERC20WETH);

  function acceptableDustPercentage() external view returns (uint256);

  function maxCollectorFeePercentage() external view returns (uint256);

  function whitelist(address _address) external view returns (bool);

  function investorsWhitelist(address _address) external view returns (bool);

  function maxSlippage() external view returns (uint256);

  function minSlippage() external view returns (uint256);

  function maxStreamingFee() external view returns (uint256);

  function maxEntryFee() external view returns (uint256);

  function feeCollectorPercentage() external view returns (uint256);

  function investorIsWhitelisted(address _address) external view returns (bool);

  function userCanDeposit(address _address) external view returns (bool);

  function depositsEnabled() external view returns (bool);

  function feeCollector() external view returns (address);

  function checkSlippage(
    uint256 n1,
    uint256 n2,
    uint256 slippage
  ) external pure returns (bool);

  function normalizeDecimals(uint256 decimals) external pure returns (uint256);

  function weightedAverage(
    uint256 value1,
    uint256 value2,
    uint256 weight1,
    uint256 weight2
  ) external pure returns (uint256);
}




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./IERC20WETH.sol";

interface IEternalStorage {
  /** START: Basic Config Getters **/
  function getStrategist(address _contract) external view returns (address);

  function getClaimable(address _contract) external view returns (uint256);

  function subFromClaimable(uint256 _addAmount) external;

  function retainStreamingFee(uint256 burnAmount, address _user)
    external
    returns (uint256);

  function getWithdrawalAmount(
    uint256 withdrawalAmount,
    uint256 toClaimable,
    uint256 _realTotalSupply
  ) external view returns (uint256);

  function getCurrentlyPositionedToken(address _contract)
    external
    view
    returns (IERC20Extended);

  function setCurrentlyPositionedToken(IERC20Extended _currentlyPositionedToken)
    external;

  function getEntryTimestamp(address _contract, address user)
    external
    view
    returns (uint256);

  function setEntryTimestamp(address account, uint256 timestamp) external;

  function setStrategist(address _strategist) external;

  function validateSwap(
    uint256 price, // baseado no sellAmount
    IERC20Extended sellToken,
    IERC20Extended buyToken,
    uint256 buyTokenBalanceBeforeSwap,
    uint256 sellTokenBalanceBeforeSwap
  ) external view returns (uint256);

  function checkContractToken(
    IERC20Extended sellToken,
    IERC20Extended buyToken,
    bool isTrade
  ) external returns (bool);

  function setupStrategy(
    uint256 _entryFee,
    uint256 _streamingFee,
    uint256 _acceptableSlippage,
    IERC20Extended _protectionToken,
    IERC20Extended _exposureToken,
    address strategyAddress
  ) external;

  function getCollectorFees() external view returns (uint256);

  function getMintAmount(
    uint256 boughtAmount,
    IERC20Extended buyToken,
    uint256 realTotalSupply
  ) external view returns (uint256);

  function retainEntryFee(uint256 mintAmount) external returns (uint256);
}




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../ERC20.sol";
////import "../../../utils/Context.sol";

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
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}




/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
////import "@openzeppelin/contracts/utils/math/SafeMath.sol";
////import "./IEternalStorage.sol";
////import "./IBasicDefinitions.sol";
////import "./IERC20Extended.sol";

/**
 * @title The ERC20 Strategy Contract for Strategy Strategies
 * @author João
 * @notice A strategist will call this contract via the StrategyFactory Contract in order to create a new strategy
 * @dev Check out the docs to have a better understanding of the functions
 */

contract Strategy is ERC20Burnable {
  using SafeMath for uint256;

  //EVENTS
  event BoughtTokens(
    IERC20Extended sellToken,
    IERC20Extended buyToken,
    uint256 boughtAmount
  );

  event ClaimableChange(int256);

  IEternalStorage private _eternalStorage;
  IBasicDefinitions private _basicDefinitions;

  address payable private _swapWallet;

  modifier onlyStrategist() {
    require(
      msg.sender == _eternalStorage.getStrategist(address(this)),
      "S:ONLY_STRATEGIST"
    );
    _;
  }

  modifier onlyStrategistOrWallet() {
    require(
      msg.sender == _eternalStorage.getStrategist(address(this)) ||
        msg.sender == _swapWallet,
      "S:ONLY_STRATEGIST_OR_WALLET"
    );
    _;
  }

  /**
   * @notice Constructor
   * @param swapWallet The wallet the strategist must kepp with a positive balance in order to make trades
   */

  constructor(
    string memory name,
    string memory symbol,
    IBasicDefinitions basicDefinitions_,
    IEternalStorage eternalStorage_,
    address payable swapWallet,
    address strategist
  ) ERC20(name, symbol) {
    _eternalStorage = eternalStorage_;
    _basicDefinitions = basicDefinitions_;
    _swapWallet = swapWallet;

    _eternalStorage.setStrategist(strategist);
  }

  function basicDefinitions() public view returns (IBasicDefinitions) {
    return _basicDefinitions;
  }

  function eternalStorage() public view returns (IEternalStorage) {
    return _eternalStorage;
  }

  /** End Basic Config getters **/
  /// @notice returns total supply + the fee amount available to claim by the strategist
  function realTotalSupply() public view returns (uint256) {
    return ERC20.totalSupply().add(_eternalStorage.getClaimable(address(this)));
  }

  /** 
    @notice Computes the entry timestamp of the user on the strategy
            If it`s a user`s first time on the strategy, the current block timestamp is registered for him.
            If he`s a second comming, then the entry time stamp is updated on a weighted average fashion,
            according to his previous and the newly-minted strategy balance.
    @param mintedAmount The amount of strategy tokens it was minted for that user.
                        This function must be called always after a mint
  */
  function _calculateEntryTimestamp(uint256 mintedAmount) internal {
    if (_eternalStorage.getEntryTimestamp(address(this), msg.sender) == 0) {
      _eternalStorage.setEntryTimestamp(msg.sender, block.timestamp);
    } else {
      uint256 userTotalBalance = ERC20.balanceOf(msg.sender);
      uint256 timestamp =
        _basicDefinitions.weightedAverage(
          _eternalStorage.getEntryTimestamp(address(this), msg.sender),
          block.timestamp,
          userTotalBalance.sub(mintedAmount),
          userTotalBalance
        );

      _eternalStorage.setEntryTimestamp(msg.sender, timestamp);
      delete userTotalBalance;
      delete timestamp;
    }
  }

  /**
    @notice withdrawal function
    @param tokenAmount The amount of strategy tokens the user wishes to withdraw.
  */
  function withdraw(uint256 tokenAmount) external {
    require(
      tokenAmount <= ERC20.balanceOf(msg.sender),
      "S:USER_HAS_LOW_BALANCE"
    );

    uint256 toClaimable =
      _eternalStorage.retainStreamingFee(tokenAmount, msg.sender);

    emit ClaimableChange(int256(toClaimable));

    uint256 amountToWithdraw =
      _eternalStorage.getWithdrawalAmount(
        tokenAmount.sub(toClaimable),
        toClaimable,
        realTotalSupply()
      );

    _eternalStorage.getCurrentlyPositionedToken(address(this)).transfer(
      msg.sender,
      amountToWithdraw
    );
    delete toClaimable;
    delete amountToWithdraw;
    _burn(msg.sender, tokenAmount);
  }

  /**
    @notice A function that preceeds minting. It is used to retain the entry fee.
            The entry fee is calculated based on the amount of tokens the user bought,
            proportionally to his participation on the strategy.
    @param boughtAmount the amount of tokens bought by the strategist
    @notice verification for boughtAmount being > 0 is not needed, as it is an internal function
         called only by deposit and swap, which already has this kind of verification
  */
  function _preMint(uint256 boughtAmount)
    internal
    virtual
    returns (uint256 mintAmountMinusEntryFee_)
  {
    uint256 mintAmountMinusEntryFee = 0;

    IERC20Extended buyToken =
      _eternalStorage.getCurrentlyPositionedToken(address(this));

    if (realTotalSupply() == 0) {
      // if is first deposit or the contract is empty
      mintAmountMinusEntryFee = _eternalStorage.retainEntryFee(boughtAmount);

      emit ClaimableChange(int256(boughtAmount.sub(mintAmountMinusEntryFee)));

      _mint(msg.sender, mintAmountMinusEntryFee);
    } else {
      uint256 mintAmount =
        _eternalStorage.getMintAmount(
          boughtAmount,
          buyToken,
          realTotalSupply()
        );

      mintAmountMinusEntryFee = _eternalStorage.retainEntryFee(mintAmount);

      _mint(msg.sender, mintAmountMinusEntryFee);

      delete buyToken;
    }
    return mintAmountMinusEntryFee;
  }

  /**
    @notice The function the strategist must call when he wants to redeem his fess.
    @dev All fees are saved in a uint256 variable and are transformed into a strategy token upon claim request
  */
  function redeemClaimable() external onlyStrategist {
    require(
      _eternalStorage.getClaimable(address(this)) > 0,
      "S:CLAIMABLE_IS_0"
    );

    uint256 dFees = _eternalStorage.getCollectorFees();

    _mint(_basicDefinitions.feeCollector(), dFees);

    _mint(
      _eternalStorage.getStrategist(address(this)),
      _eternalStorage.getClaimable(address(this)) - dFees
    );

    delete dFees;

    _eternalStorage.subFromClaimable(
      _eternalStorage.getClaimable(address(this))
    );
  }

  /**
    @notice overwritten transfer function that is used to update the entry time stamp of the strategy tokens recepient.
    @param recipient recepient address for the transfer request
    @param amount strategy token amount the user wants to transfer
  */
  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    uint256 averageEntryTimestamp;

    if (
      _eternalStorage.getEntryTimestamp(address(this), recipient) == 0 ||
      ERC20.balanceOf(recipient) == 0
    ) {
      averageEntryTimestamp = _eternalStorage.getEntryTimestamp(
        address(this),
        msg.sender
      );
    } else {
      averageEntryTimestamp = _basicDefinitions.weightedAverage(
        _eternalStorage.getEntryTimestamp(address(this), msg.sender),
        _eternalStorage.getEntryTimestamp(address(this), recipient),
        ERC20.balanceOf(msg.sender),
        ERC20.balanceOf(recipient)
      );
    }

    _eternalStorage.setEntryTimestamp(recipient, averageEntryTimestamp);

    _transfer(_msgSender(), recipient, amount);

    delete averageEntryTimestamp;
    return true;
  }

  /**
    @notice Where the swap happens. Only a strategist or the saved Strategy wallet can execute the swap.
            Currently all swaps happen with 100% of the current balance range.
    @param price 0x quoted price (in sellTokenUnits)
    @param sellToken sell token address
    @param buyToken address
    @param swapTarget 0x contract address that will actually execute the swap on the quoted DEX
    @param swapCallData the hex data needed to execute the swap within the 0x contracts
    @dev this is basically a wrapper function for the fillQuote function
   */

  function swap(
    uint256 price,
    IERC20Extended sellToken,
    IERC20Extended buyToken,
    address payable swapTarget,
    bytes calldata swapCallData
  ) public onlyStrategistOrWallet {
    require(realTotalSupply() > 0, "S:NO_STRATEGY_FUNDS");

    _fillQuote(price, sellToken, buyToken, swapTarget, swapCallData, true);

    _eternalStorage.setCurrentlyPositionedToken(buyToken);
  }

  /**
    @notice internal function that executes, validates and mint or reposition the token balances.
    @param price 0x quoted price (in sellTokenUnits)
    @param sellToken sell token address
    @param buyToken address
    @param swapTarget 0x contract address that will actually execute the swap on the quoted DEX
    @param swapCallData the hex data needed to execute the swap within the 0x contract
    @param isTrade to differentiate deposits from trades. If it is a deposit, then it must mint the equivalent
                   strategy tokens to depositor. If it is a trade, it will only update 
                   the currentlyPositionedToken varaible
  */
  function _fillQuote(
    // 0x price quote (in WEI) based on sellAmount
    uint256 price,
    // The `sellTokenAddress` field from the API response.
    IERC20Extended sellToken,
    // The `buyTokenAddress` field from the API response.
    IERC20Extended buyToken,
    // The `to` field from the API response.
    address payable swapTarget,
    // The `data` field from the API response.
    bytes calldata swapCallData,
    bool isTrade
  ) internal returns (uint256) {
    if (
      _eternalStorage.checkContractToken(sellToken, buyToken, isTrade) == false
    ) {
      revert("S:CONTRACT_TOKENS_WRONG");
    }
    require(
      sellToken.approve(swapTarget, type(uint256).max),
      "S:SELL_TOKEN_NOT_ARRPOVED"
    );

    uint256 buyTokenBalanceBeforeSwap = buyToken.balanceOf(address(this));
    uint256 sellTokenBalanceBeforeSwap = sellToken.balanceOf(address(this));

    (bool success, ) = swapTarget.call(swapCallData);

    require(success, "S:SWAP_CALL_FAILED"); //

    delete success;

    uint256 boughtAmount =
      _eternalStorage.validateSwap(
        price,
        sellToken,
        buyToken,
        buyTokenBalanceBeforeSwap,
        sellTokenBalanceBeforeSwap
      );

    emit BoughtTokens(sellToken, buyToken, boughtAmount);

    delete buyTokenBalanceBeforeSwap;
    delete sellTokenBalanceBeforeSwap;

    return boughtAmount;
  }

  /**
    @notice Where a user will make deposits to the contract. Deposits should also be made using 0x API.
    @param price 0x quoted price (in sellTokenUnits)
    @param swapTarget 0x contract address that will actually execute the swap on the quoted DEX
    @param swapCallData the hex data needed to execute the swap within the 0x contracts
  */
  function depositAndSwap(
    uint256 price,
    address payable swapTarget,
    bytes calldata swapCallData
  ) external payable {
    require(
      _basicDefinitions.userCanDeposit(msg.sender) == true,
      "S:USER_CANT_DEPOSIT"
    );

    require(msg.value > 0, "S:VALUE_IS_ZERO");

    _basicDefinitions.weth().deposit{value: msg.value}();

    IERC20Extended currentPositionedToken =
      _eternalStorage.getCurrentlyPositionedToken(address(this));

    if (currentPositionedToken == _basicDefinitions.weth()) {
      emit BoughtTokens(
        _basicDefinitions.weth(),
        currentPositionedToken,
        msg.value
      );

      uint256 minted =
        _preMint(
          /* boughtAmount */
          msg.value
        );

      _calculateEntryTimestamp(minted);
      delete minted;
    } else {
      uint256 boughtAmount =
        _fillQuote(
          price,
          _basicDefinitions.weth(), // sellToken
          currentPositionedToken, // buyToken
          swapTarget,
          swapCallData,
          false
        );

      uint256 minted = _preMint(boughtAmount);
      _calculateEntryTimestamp(minted);
      delete minted;
      delete boughtAmount;
    }
  }
}


/** 
 *  SourceUnit: /Users/joaohenriquecosta/gitf/dalpha/dalpha-smart-contracts/contracts/StrategyFactory.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./Strategy.sol";
////import "./IBasicDefinitions.sol";
////import "./IEternalStorage.sol";

contract StrategyFactory {
  event StrategyCreated(Strategy strategyAddress);

  IBasicDefinitions private _basicDefinitions;
  IEternalStorage private _eternalStorage;

  address private _owner;

  constructor(
    IBasicDefinitions basicDefinitions_,
    IEternalStorage eternalStorage_
  ) {
    _basicDefinitions = basicDefinitions_;
    _eternalStorage = eternalStorage_;
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, "NOT_OWNER");
    _;
  }

  function basicDefinitions()
    public
    view
    returns (IBasicDefinitions basicDefinitions_)
  {
    return _basicDefinitions;
  }

  function eternalStorage()
    public
    view
    returns (IEternalStorage eternalStorage_)
  {
    return _eternalStorage;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function changeOwner(address newOwner) public onlyOwner {
    _owner = newOwner;
  }

  function changeBasicDefinitions(IBasicDefinitions basicDefinitions_)
    public
    onlyOwner
  {
    _basicDefinitions = basicDefinitions_;
  }

  function changeEternalStorage(IEternalStorage eternalStorage_)
    public
    onlyOwner
  {
    _eternalStorage = eternalStorage_;
  }

  function createStrategy(
    string memory name_,
    string memory symbol_,
    uint256 entryFee_,
    uint256 streamingFee_,
    uint256 acceptableSlippage_,
    IERC20Extended protectionToken_,
    IERC20Extended exposureToken_,
    address payable swapWallet_
  ) external {
    Strategy s =
      new Strategy(
        name_,
        symbol_,
        _basicDefinitions,
        _eternalStorage,
        swapWallet_,
        msg.sender
      );

    _eternalStorage.setupStrategy(
      entryFee_,
      streamingFee_,
      acceptableSlippage_,
      protectionToken_,
      exposureToken_,
      address(s)
    );

    emit StrategyCreated(s);
  }
}