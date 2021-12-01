/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File contracts/interfaces/IElfCoin.sol

interface IElfCoin {
    /**
     * @dev Allows trading.
     */
    function enableTrading() external;

    /**
     * @dev Sets whether swapping is enabled.
     */
    function setSwapEnabled(bool enabled) external;
    
    /**
     * @dev Triggers a buyback using BNB stored in contract wallet from Buy Back fees.
     */
    function triggerBuyBack(uint256 amount) external;

    /**
     * @dev Sets the various fees collected during a transaction.
     */
    function setFeesEnabled(bool enabled) external;

    /**
     * @dev Enables/disable exclusion of fees and transactional limits for an address.
     */
    function excludeFromFees(address account, bool excluded) external;

    /**
     * @dev Sets gas when processing dividends.
     */
    function setGasForProcessingDividends(uint256 gas) external;

    /**
     * @dev Sets gas when processing dividends.
     */
    function setMarketPair(address pair, bool enabled) external;

    /**
     * @dev Sets minimum period between distribution of dividends.
     */
    function setMinimumDividendDistributionPeriod(uint256 period) external;

    /**
     * @dev Sets the minimum dividend distribution sent to a account.
     */
    function setMinimumDividendDistribution(uint256 distribution) external;

    /**
     * @dev Sets a sniper address as a sniper or is not a sniper.
     */
    function setSniper(address account, bool isSniper) external;

    /**
     * @dev Emitted when we've added to the liquidity pool.
     */
    event AutoLiquify(uint256 bnbAmount, uint256 tokenAmount);

    /**
     * @dev Emitted when an account is excluded from fees and transactional limits.
     */
    event ExcludeFromFees(address indexed account, bool isExcluded);

    /**
     * @dev Emitted when an account is excluded from dividends.
     */
    event ExcludeFromDividends(address indexed account, bool isExcluded);

    /**
     * @dev Emitted when a Market Pair is added or removed from the pool.
     */
    event SetMarketPair(address indexed pair, bool indexed enabled);
}


// File contracts/SafeMath.sol

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


// File contracts/DividendDistributor.sol

contract DividendDistributor {
    using SafeMath for uint256;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address private _token;
    address private WBNB;
    IERC20 private BUSD;
    IUniswapV2Router02 private uniswapV2Router;

    address[] private _shareholders;

    mapping(address => uint256) private _shareholderIndexes;
    mapping(address => uint256) private _lastClaimTimes;
    mapping(address => Share) private _shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;
    uint256 public minPeriod = 12 hours;
    uint256 public minDistribution = 1 * (10**18);
    uint256 public gasForProcessing = 5000000;

    uint256 private _currentShareholderIndex;

    modifier onlyToken()
    {
        require(msg.sender == _token);
        _;
    }

    constructor(address router, address busd)
    {
        _token = msg.sender;
        uniswapV2Router = IUniswapV2Router02(router);
        WBNB = uniswapV2Router.WETH();
        BUSD = IERC20(busd);
    }

    function setGasForProcessing(uint256 gas) external onlyToken
    {
        gasForProcessing = gas;
    }

    function setMinimumDistributionPeriod(uint256 period) external onlyToken
    {
        minPeriod = period;
    }

    function setMinimumDistribution(uint256 distribution) external onlyToken
    {
        minDistribution = distribution;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken
    {
        if (_shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && _shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && _shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(_shares[shareholder].amount).add(amount);

        _shares[shareholder].amount = amount;

        _shares[shareholder].totalExcluded = getCumulativeDividends(
            _shares[shareholder].amount
        );
    }

    function deposit() external payable onlyToken
    {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);

        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function processDividends() external onlyToken
    {
        uint256 shareholderCount = _shareholders.length;

        // No shareholders? No dividends!
        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gasForProcessing && iterations < shareholderCount) {
            if (_currentShareholderIndex >= shareholderCount) {
                _currentShareholderIndex = 0;
            }

            address currentShareholder = _shareholders[_currentShareholderIndex];

            if (shouldDistribute(currentShareholder)) {
                distributeDividend(currentShareholder);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();

            _currentShareholderIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool)
    {
        return
            _lastClaimTimes[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal
    {
        if (_shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);

        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);

            BUSD.transfer(shareholder, amount);

            _lastClaimTimes[shareholder] = block.timestamp;

            _shares[shareholder].totalRealised = _shares[shareholder]
                .totalRealised
                .add(amount);

            _shares[shareholder].totalExcluded = getCumulativeDividends(
                _shares[shareholder].amount
            );
        }
    }

    function claimDividend() external
    {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256)
    {
        if (_shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(_shares[shareholder].amount);
        uint256 shareholderTotalExcluded = _shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256)
    {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address adding) internal
    {
        _shareholderIndexes[adding] = _shareholders.length;
        _shareholders.push(adding);
    }

    function removeShareholder(address removing) internal
    {
        address replacementShareholder = _shareholders[_shareholders.length - 1];

        // Sets last shareholder in place of removed shareholder
        _shareholders[_shareholderIndexes[removing]] = replacementShareholder;

        // Update shareholderIndexes mapping to point to new shareholder
        _shareholderIndexes[replacementShareholder] = _shareholderIndexes[removing];

        // Remove the last shareholder as they will now be in the array twice
        _shareholders.pop();
    }
}


// File contracts/Auth.sol

/**
 * @dev Contract module which provides a access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 * 
 * This is an extension of "openzeppelin" Ownable contract, allowing for authorised parties
 * to run contract methods.
 */
abstract contract Auth is Context {
    address private _owner;
    address private _authorised;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _authorised = _msgSender();
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
        require(owner() == _msgSender(), "Auth: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than someone authorised.
     */
    modifier onlyAuthorised() {
        require(_authorised == _msgSender(), "Auth: caller is not authorised");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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


// File contracts/ElfCoin.sol

/*
          _  __             _       
         | |/ _|           (_)      
      ___| | |_    ___ ___  _ _ __  
     / _ \ |  _|  / __/ _ \| | '_ \ 
    |  __/ | |   | (_| (_) | | | | |
     \___|_|_|    \___\___/|_|_| |_|

    Website: theelfcoin.com
    Telegram: t.me/realelfcoin
    Twitter: twitter.com/RealElfCoin

                 ___,@
                /  <
           ,_  /    \  _,
       ?    \`/______\`/
    ,_(_).  |; (e  e) ;|
     \___ \ \/\   7  /\/    _\8/_
         \/\   \'=='/      | /| /|
          \ \___)--(_______|//|//|
           \___  ()  _____/|/_|/_|
              /  ()  \    `----'
             /   ()   \
            '-.______.-'
          _    |_||_|    _
         (@____) || ([email protected])
          \______||______/

*/

contract ElfCoin is ERC20, Auth, IElfCoin {
    using SafeMath for uint256;

    // Mapping
    mapping(address => bool) private _marketPairs;
    mapping(address => bool) private _isFeeExcluded;
    mapping(address => bool) private _isDividendExcluded;
    mapping(address => bool) private _isSniper;

    // Token Details & Fees
    uint256 private constant _masterTaxDivisor = 100;
    uint256 private constant _startingSupply = 1_000_000_000_000_000; // 1 Quadrillion, underscores aid readability
    uint256 private constant _totalTokens = _startingSupply * (10**18);

    bool public tradingEnabled = false;
    bool public feesEnabled = false;
    uint256 public launchTime;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 2;
    uint256 public reflectionFee = 6;
    uint256 public buyBackFee = 2;
    uint256 public totalFee = liquidityFee.add(marketingFee).add(reflectionFee).add(buyBackFee);
    uint256 public maxTransactionAmount = _totalTokens.div(200); // 0.5%

    // Addresses
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public zeroAddress = 0x0000000000000000000000000000000000000000;
    address payable public marketingWallet = payable(0x4BBdA5E86593Cc60E6eA12faC95Cf383CFF869D4);
    address private BUSD;
    address private WBNB;

    // Fee receiver and liquidity details
    uint256 private _targetLiquidity = 25;
    uint256 private _targetLiquidityDenominator = 100;

    // Distribution
    address public distributorAddress;
    DividendDistributor _dividendDistributor;

    // Token Swapping (Purchase from Exchange)
    bool public swapEnabled = true;
    bool private _inSwap;
    uint256 private _swapThreshold = _totalTokens / 20000;
    uint256 private _swapAmount = (_totalTokens * 5) / 1000;

    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    // Router 'n' Trading Pair
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor(address router, address busd) ERC20("Elf Coin", "ELFIE") {
        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        WBNB = uniswapV2Router.WETH();
        BUSD = busd;

        _dividendDistributor = new DividendDistributor(router, BUSD);
        distributorAddress = address(_dividendDistributor);

        _setMarketPair(uniswapV2Pair, true);

        _isFeeExcluded[owner()] = true;
        _isFeeExcluded[address(this)] = true;

        excludeFromDividends(deadAddress, true);
        excludeFromDividends(zeroAddress, true);
        excludeFromDividends(distributorAddress, true);
        excludeFromDividends(owner(), true);
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(uniswapV2Router), true);

        _approve(address(this), address(router), _totalTokens);
        approve(address(uniswapV2Router), _totalTokens);
        approve(uniswapV2Pair, _totalTokens);

        // Ever-growing sniper/tool blacklist
        _isSniper[0xE4882975f933A199C92b5A925C9A8fE65d599Aa8] = true;
        _isSniper[0x86C70C4a3BC775FB4030448c9fdb73Dc09dd8444] = true;
        _isSniper[0x20C00AFf15Bb04cC631DB07ee9ce361ae91D12f8] = true;
        _isSniper[0x0538856b6d0383cde1709c6531B9a0437185462b] = true;

        /**
         * @dev This is an internal method, and is only called here therefore
         * cannot be called again in future.
         */
        _mint(owner(), _totalTokens);
    }

    function enableTrading() external onlyAuthorised
    {
        require(launchTime == 0, "Trading has already been enabled!");

        tradingEnabled = true;
        launchTime = block.timestamp;
    }

    function setSwapEnabled(bool enabled) external onlyAuthorised
    {
        swapEnabled = enabled;
    }

    function triggerBuyBack(uint256 amount) external onlyAuthorised
    {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amount }(
            0,
            path,
            deadAddress,
            block.timestamp
        );
    }

    function getCirculatingSupply() public view returns (uint256)
    {
        return _totalTokens.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
    }

    function setFeesEnabled(bool enabled) external onlyAuthorised
    {
        feesEnabled = enabled;
    }

    function excludeFromFees(address account, bool excluded) external onlyAuthorised
    {
        require(
            _isFeeExcluded[account] != excluded,
            "Account is already the value of 'excluded'"
        );

        _isFeeExcluded[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool)
    {
        return _isFeeExcluded[account];
    }

    function excludeFromDividends(address account, bool excluded) public onlyAuthorised
    {
        _isDividendExcluded[account] = excluded;

        if (excluded) {
            _dividendDistributor.setShare(account, 0);
        } else {
            _dividendDistributor.setShare(account, balanceOf(account));
        }

        emit ExcludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account) public view returns (bool)
    {
        return _isDividendExcluded[account];
    }

    function setGasForProcessingDividends(uint256 gas) external onlyAuthorised
    {
        _dividendDistributor.setGasForProcessing(gas);
    }

    function setMarketPair(address pair, bool enabled) external onlyAuthorised
    {
        require(
            pair != uniswapV2Pair,
            "The PancakeSwap pair cannot be altered"
        );
        require(
            _marketPairs[pair] != enabled,
            "Market pair is already set to that value"
        );

        _setMarketPair(pair, enabled);
    }

    function setMinimumDividendDistributionPeriod(uint256 period) external onlyAuthorised
    {
        _dividendDistributor.setMinimumDistributionPeriod(period);
    }

    function setMinimumDividendDistribution(uint256 distribution) external onlyAuthorised
    {
        _dividendDistributor.setMinimumDistribution(distribution);
    }

    function setSniper(address account, bool isASniper) external onlyAuthorised
    {
        require(
            _isSniper[account] != isASniper,
            "Account is already the value of 'isASniper'"
        );

        _isSniper[account] = isASniper;
    }

    function isSniper(address account) public view returns (bool)
    {
        return _isSniper[account];
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256)
    {
        return
            accuracy.mul(balanceOf(uniswapV2Pair).mul(2)).div(
                getCirculatingSupply()
            );
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    /**
     * @dev Internal methods
     */
    function _transfer(address from, address to, uint256 amount) internal override
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isSniper(from), "Snipers must be rejected!");
        require(!isSniper(to), "Snipers must be rejected!");

        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !isExcludedFromFees(to)) {
            require(tradingEnabled, "Trading is not currently enabled");
            require(amount <= maxTransactionAmount, "Transaction limit exceeded");

            // antibot
            if (block.timestamp == launchTime) {
                _isSniper[to] = true;
            }
        }
        
        if (_inSwap) {
            return super._transfer(from, to, amount);
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance > _swapAmount)
            contractTokenBalance = _swapAmount;

        if (
            !_inSwap &&
            !_marketPairs[from] &&
            swapEnabled &&
            contractTokenBalance >= _swapThreshold
        ) {
            _swapBack(contractTokenBalance);
        }
        
        if (_shouldTakeFees(from, to)) {
            uint256 feeAmount = (amount * totalFee) / _masterTaxDivisor;
            amount = amount.sub(feeAmount);

            super._transfer(from, address(this), feeAmount);
        }

        super._transfer(from, to, amount);

        if (!isExcludedFromDividends(from)) {
            try _dividendDistributor.setShare(from, balanceOf(from)) {} catch {}
        }

        if (!isExcludedFromDividends(to)) {
            try _dividendDistributor.setShare(to, balanceOf(to)) {} catch {}
        }

        try _dividendDistributor.processDividends() {} catch {}
    }

    function _shouldTakeFees(address from, address to) internal view returns (bool) {
        return feesEnabled && (from == uniswapV2Pair || to == uniswapV2Pair) && !(isExcludedFromFees(from) || isExcludedFromFees(to));
    }

    function _swapBack(uint256 numTokensToSwap) internal swapping
    {
        if (!feesEnabled) {
            return;
        }

        uint256 dynamicLiquidityFee = isOverLiquified(
            _targetLiquidity,
            _targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;

        uint256 amountToLiquify = numTokensToSwap
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);

        uint256 amountToSwap = numTokensToSwap.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbAmount = address(this).balance.sub(balanceBefore);
        uint256 bnbTotalFee = totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 bnbLiquidity = bnbAmount.mul(dynamicLiquidityFee).div(bnbTotalFee).div(2);
        uint256 bnbReflection = bnbAmount.mul(reflectionFee).div(bnbTotalFee);
        uint256 bnbMarketing = bnbAmount.sub(bnbLiquidity + bnbReflection);

        marketingWallet.transfer(bnbMarketing);

        try _dividendDistributor.deposit{value: bnbReflection}() {} catch {}

        if (amountToLiquify > 0) {
            _approve(address(this), address(uniswapV2Router), amountToLiquify);

            uniswapV2Router.addLiquidityETH{value: bnbLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                owner(),
                block.timestamp
            );

            emit AutoLiquify(bnbLiquidity, amountToLiquify);
        }
    }

    function _setMarketPair(address pair, bool enabled) internal
    {
        _marketPairs[pair] = enabled;
        
        excludeFromDividends(pair, enabled);

        emit SetMarketPair(pair, enabled);
    }

    receive() external payable {}
}