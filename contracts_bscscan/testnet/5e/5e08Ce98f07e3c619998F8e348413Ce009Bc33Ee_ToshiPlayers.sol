/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.8.0;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.8.0;


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: contracts/BABYTOSHIGAMES/Ownable.sol


pragma solidity >=0.8.0;

/*
****************      **************    ****************    ***            ***  ******************   **************      ****************  ***            ***  ****
*****************    ****************   *****************    ***          ***   ******************  ****************    ****************   ***            ***  ****
**             ***  ***            ***  **             ***    ***        ***    ****************** ******************  ****************    ***            ***  **** 
**              **  **              **  **              **     ***      ***            ****        **              **   ***********        ***            ***  ****
**              **  **              **  **              **      ***    ***             ****        **              **    ***********       ***            ***  
*****************   ******************  *****************        ********              ****        **              **     ***********      ******************  ****
*****************   ******************  *****************         ******               ****        **              **      ***********     ******************  ****     
**              **  **              **  **              **         ****                ****        **              **       ***********    ***            ***  ****
**              **  **              **  **              **         ****                ****        **              **        ***********   ***            ***  ****    
**             ***  **              **  **             ***         ****                ****        ******************    ****************  ***            ***  ****
*****************   **              **  *****************          ****                ****         ****************    ****************   ***            ***  ****
****************    **              **  ****************           ****                ****          **************    ****************    ***            ***  ****



******************   **************      ****************  ***            ***  ****  ******************  ***                 ***  ****************
******************  ****************    ****************   ***            ***  ****  ******************  ***                 ***  *****************
       ****        ******************  ****************    ***            ***  ****  ******************  ***                 ***  ******************
       ****        **              **   ***********        ***            ***  ****  ***                 ***                 ***  ***            ***
       ****        **              **    ***********       ***            ***        ***                 ***                 ***  ***            ***
       ****        **              **     ***********      ******************  ****  ******************  ***                 ***  *****************
       ****        **              **      ***********     ******************  ****  ******************  ***                 ***  **************** 
       ****        **              **       ***********    ***            ***  ****  ***                 ***                 ***  ***
       ****        **              **        ***********   ***            ***  ****  ***                 ***                 ***  ***
       ****        ******************    ****************  ***            ***  ****  ***                 ******************  ***  ***
       ****         ****************    ****************   ***            ***  ****  ***                 ******************  ***  ***
       ****          **************    ****************    ***            ***  ****  ***                 ******************  ***  ***
*/ 

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * This contract is Excluded from Babytoshi Fees !!!
 */




abstract contract Ownable {
    using SafeMath for uint256;
    
    receive() external payable {}
    fallback() external payable {}
    
    address internal there = address(this);
    address internal owner = address(0x200923193ed77BEAb040011580e89c66390CBBa2); //TEST : 0x200923193ed77BEAb040011580e89c66390CBBa2   ---   REAL : 0x91b5af08eccc9c208738218b45726bd6450c8025

    address internal constant BABYTOSHI_ADDRESS = address(0x382ecCa048f1Fca7C5795A30E8977F41F5c229a4);  //Test : 0x382ecCa048f1Fca7C5795A30E8977F41F5c229a4   --- REAL : 0xD2309BbD6Ec83D8B3341cE5b061ce378F45c2621
    address internal constant MARKETING_WALLET = address(0x50F2E07131Cfbed5658aEc7AD52e83207DaC8DCD); //TEST: 0x50F2E07131Cfbed5658aEc7AD52e83207DaC8DCD   --- REAL : 0x61472ced7d1dea15d3ef3e30158006a4152e48b5
    address public constant BURN_WALLET = address(0x0122000000000122000000000012200000000bab); // //TEST: 0x0122000000000122000000000012200000000bab   --- REAL : 0x0221120210000291120210000022022024000BaB
    address internal constant PANCAKESWAP_ROUTER_ADDRESS = address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Test : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1   --- REAL : 0x10ed43c718714eb63d5aa57b78b54704e256024e
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapTokenForETH(address indexed currency, address indexed sender, address receiver, uint256 tokenAmount);
    event AddLiquidity(address indexed babytoshiAddress, uint256 tokenAmount, uint256 bnbAmount);
    event Burn(address indexed sender, address indexed receiver, uint256 burnAmount);
    event TransferTo(address indexed currency, address indexed sender, address indexed receiver, uint256 amount);
    event TransferFrom(address indexed currency, address indexed sender, address indexed receiver, uint256 amount);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () onlyOwner {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by the owner.
     */
    modifier notOwner() {
        require(owner != _msgSender() && owner != _msgSender(), "not callable by owner!");
        _;
    }
    
    /**
     * @dev swap any tokens for bnb
     * Can only be called by derived contracts
     */
    function swapTokenForETH(address currency, uint256 tokenAmount, address receiver) internal returns (bool swapped){
        // generate the uniswap pair path of token -> weth
        IUniswapV2Router02 pancakeswapV2Router = IUniswapV2Router02(PANCAKESWAP_ROUTER_ADDRESS);
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = pancakeswapV2Router.WETH();

        bool approved = ERC20(currency).approve(PANCAKESWAP_ROUTER_ADDRESS, tokenAmount);
        require(approved, 'the token was not approved for swap to bnb');
        
        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            receiver,
            block.timestamp
        );
        emit SwapTokenForETH(currency, _msgSender(), receiver, tokenAmount);
        return true;
    }
    
    /**
     * @dev Add babytoshi liquidity
     * Can only be called by derived contracts
     */
    function addLiquidity(uint256 babytoshiAmount) internal returns (bool liquidityAdded){
        IUniswapV2Router02 pancakeswapV2Router = IUniswapV2Router02(PANCAKESWAP_ROUTER_ADDRESS);
        uint256 half = babytoshiAmount.div(2);
        uint256 otherHalf = babytoshiAmount.sub(half);
        
        uint256 initialBalance = there.balance;
        bool swap = swapTokenForETH(BABYTOSHI_ADDRESS, half, there); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        require(swap, "non swap liquidity");
        uint256 newBalance = there.balance.sub(initialBalance);
        require(newBalance > 0, "no balance");

        bool approved = ERC20(BABYTOSHI_ADDRESS).approve(PANCAKESWAP_ROUTER_ADDRESS, babytoshiAmount);
        require(approved, 'the token was not approved for swap to bnb');
        
        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: newBalance}(
            BABYTOSHI_ADDRESS,
            otherHalf,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
        emit AddLiquidity(BABYTOSHI_ADDRESS, otherHalf, newBalance);
        return true;
    }
    
    /**
     * @dev Burn an amount of babytoshi
     * Can only be called by derived contracts
     */
    function burn(uint256 burnAmount) internal returns(bool burned) {
        bool _burned = transferTo(BABYTOSHI_ADDRESS, BURN_WALLET, burnAmount);
        emit Burn(there, BURN_WALLET, burnAmount);
        return _burned;
    }
    
    /**
     * @dev Transfer currency to an account
     * Can only be called by derived contracts
     */
    function transferTo(address currency, address key, uint256 amount) internal returns (bool transferred){
        bool approved = ERC20(BABYTOSHI_ADDRESS).approve(key, amount);
        require(approved, 'the token was not approved to transfer if');
        (bool _transferred,) = currency.call(abi.encodeWithSignature("transfer(address,uint256)", key, amount));
        emit TransferTo(currency, _msgSender(), key, amount);
        return _transferred;
    }
    /**
     * @dev Withdraw currency to an account
     * Can only be called by owner
     */
    function withdraw(address currency, address key, uint256 amount) public onlyOwner returns (bool withdrawed){
        bool approved = ERC20(BABYTOSHI_ADDRESS).approve(key, amount);
        require(approved, 'the token was not approved to transfer if');
        (bool transferred,) = currency.call(abi.encodeWithSignature("transfer(address,uint256)", key, amount));
        require(transferred, "CONTEXT: the amount to this player was not transfered!");
        emit TransferTo(currency, _msgSender(), key, amount);
        return true;
    }
    
    /**
     * @dev Transfer currency from an account
     * Can only be called by derived contracts
     */
    function transferFrom(address currency, address player, uint256 amount) internal returns (bool transferred){
        (bool _transferred,) = currency.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", player, there, amount));
        emit TransferFrom(currency, player, there, amount);
        return _transferred;
    }
    
    /**
     * @dev Deposit currency here
     * Can only be called by owner
     */
    function deposit(address currency, uint256 amount) public onlyOwner returns (bool deposited){
        (bool transferred,) = currency.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _msgSender(), there, amount));
        require(transferred, "CONTEXT: the amount to this player was not transfered!");
        emit TransferFrom(currency, _msgSender(), there, amount);
        return true;
    }

    function _msgSender() internal view virtual returns (address msgSender) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata data) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(newOwner != owner, "Ownable: new owner is the same than actual");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
// File: contracts/BABYTOSHIGAMES/ToshiPlayers.sol


pragma solidity >=0.8.0;
/*
****************      **************    ****************    ***            ***  ******************   **************      ****************  ***            ***  ****
*****************    ****************   *****************    ***          ***   ******************  ****************    ****************   ***            ***  ****
**             ***  ***            ***  **             ***    ***        ***    ****************** ******************  ****************    ***            ***  **** 
**              **  **              **  **              **     ***      ***            ****        **              **   ***********        ***            ***  ****
**              **  **              **  **              **      ***    ***             ****        **              **    ***********       ***            ***  
*****************   ******************  *****************        ********              ****        **              **     ***********      ******************  ****
*****************   ******************  *****************         ******               ****        **              **      ***********     ******************  ****     
**              **  **              **  **              **         ****                ****        **              **       ***********    ***            ***  ****
**              **  **              **  **              **         ****                ****        **              **        ***********   ***            ***  ****    
**             ***  **              **  **             ***         ****                ****        ******************    ****************  ***            ***  ****
*****************   **              **  *****************          ****                ****         ****************    ****************   ***            ***  ****
****************    **              **  ****************           ****                ****          **************    ****************    ***            ***  ****



******************   **************      ****************  ***            ***  ****  ******************  ***                 ***  ****************
******************  ****************    ****************   ***            ***  ****  ******************  ***                 ***  *****************
       ****        ******************  ****************    ***            ***  ****  ******************  ***                 ***  ******************
       ****        **              **   ***********        ***            ***  ****  ***                 ***                 ***  ***            ***
       ****        **              **    ***********       ***            ***        ***                 ***                 ***  ***            ***
       ****        **              **     ***********      ******************  ****  ******************  ***                 ***  *****************
       ****        **              **      ***********     ******************  ****  ******************  ***                 ***  **************** 
       ****        **              **       ***********    ***            ***  ****  ***                 ***                 ***  ***
       ****        **              **        ***********   ***            ***  ****  ***                 ***                 ***  ***
       ****        ******************    ****************  ***            ***  ****  ***                 ******************  ***  ***
       ****         ****************    ****************   ***            ***  ****  ***                 ******************  ***  ***
       ****          **************    ****************    ***            ***  ****  ***                 ******************  ***  ***
*/            
/**
 * @dev Simply subscribe to ToshiPlayers will permit you to access to ToshiGames space
 * 
 * Repartition of subscription fees : 
  * 50% add to liquidity pool
  * 25% transfer to marketing
  * 20% transfer to a lucky random player
  * 5% send to burn wallet
 
 * This contract is Excluded from Babytoshi Fees !!!
 * Dont send funds to this contract !!!
**/



/*
 * @dev 
 * Required to manage players
 * Only new players can subscribe
 */
contract ToshiPlayers is Ownable {
    using SafeMath for uint256;
    
    mapping(address => bool) private allowedContracts;
    mapping(address => bool) private bannedPlayers;
    address[] eternalBanned = [address(0), there, BABYTOSHI_ADDRESS, owner, MARKETING_WALLET, BURN_WALLET, PANCAKESWAP_ROUTER_ADDRESS];

    uint256 public constant MIN_AMOUNT_SUBSCRIBE = uint256(1_000_000) * (10**18);
    uint256 public amountSubscribe = uint256(5_000_000) * (10**18);
    uint256 public liquidityFeeSubscribe = 50; // 50% in percentage
    uint256 public marketingFeeSubscribe = 25; // 25% in percentage
    uint256 public randomFeeSubscribe = 20; // 20% in percentage
    uint256 public burnFeeSubscribe = 5; // 5% in percentage
    address public lastWinnerFeeSubscribe = address(0);
    
    uint256 private temporaryBanTime = 1 weeks;
    uint256 private permanentBanTime = 50_000 weeks; // 1 year = ~50 weeks --- 1,0000 years = 50,000 weeks
    uint private nbRandom = 0;

    /**
     * @dev Struc of all players
     */
    struct PlayersMap{
        address[] keys;
        mapping(address => uint256) wins;
        mapping(address => uint256) looses;
        mapping(address => bool) banned;
        mapping(address => uint256) unlockTime;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    PlayersMap players;
    
    event UpdateAmountSubscribe (address indexed there, uint256 newAmount);
    event AddAllowedContract(address indexed there, address allowedContract);
    event RemoveAllowedContract(address indexed there, address allowedContract);
    
    event Subscribe(address indexed there, address indexed player);
    event SendSubscribeFees(address indexed there, address indexed player, uint256 amountSubscribe, uint256 balanceLiquidity, uint256 balanceMarketing, uint256 balanceRandom, uint256 balanceBurn, address randomPlayer);
    
    event UpdatePlayerStatistics(address indexed there, address indexed player, uint256 wins, uint256 looses);
    
    event BanPlayer(address indexed there, address indexed player, uint256 unlockTime);
    event BanPlayers(address indexed there, address[] indexed players, uint256 unlockTime);
    event PermitPlayer(address indexed there, address indexed player);
    
     /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() onlyOwner {
        owner = _msgSender();
        banAddresses(eternalBanned);
        emit OwnershipTransferred(address(0), _msgSender());
    }

    /**
     * @dev Throws if called by any account other than a player.
     */
    modifier onlyPlayers() {
        require(contains(_msgSender()) || contains(_msgSender()), "only callable by players!");
        _;
    }
    /**
     * @dev Throws if called by one player.
     */
    modifier notPlayers() {
        require(!contains(_msgSender()) || !contains(_msgSender()), "only callable by new player!");
        _;
    }
    /**
     * @dev Throws if called by banned player.
     */
    modifier notBanned() {
        require(!isBanned(_msgSender()) && !isBanned(_msgSender()), "excluded player can't execute this function!");
        _;
    }
    /**
     * @dev Throws if called by forbidden contract.
     */
    modifier onlyAllowedContracts() {
        require(allowedContracts[_msgSender()], "only callable by allowed contracts");
        _;
    }
    
    /**
     * @dev Add allowed contracts
     * Can only be called by owner of the contract.
     */
    function updateAmountSubscribe(uint256 newAmount) public {
        require(newAmount > 0 && newAmount >= MIN_AMOUNT_SUBSCRIBE && newAmount!=amountSubscribe, 'check the input amount');
        amountSubscribe = newAmount;
        emit UpdateAmountSubscribe(there, newAmount);
    }
     /**
     * @dev Get amount already burn
     * Can only be called by owner of the contract.
     */
    function getAmountBurned() public view returns(uint256 mountBurned) {
        return ERC20(BABYTOSHI_ADDRESS).balanceOf(BURN_WALLET);
    }
    /**
     * @dev Add allowed contracts
     * Can only be called by owner of the contract.
     */
    function addAllowedContract(address key) public onlyOwner {
        allowedContracts[key] = true;
        emit AddAllowedContract(there, key);
    }
    /**
     * @dev Remove allowed contracts
     * Can only be called by owner of the contract.
     */
    function removeAllowedContract(address key) public onlyOwner {
        if( allowedContracts[key] ){
            delete allowedContracts[key];
        }
        emit RemoveAllowedContract(there, key);
    }
    /**
     * @dev Get random player address from contract
     */
    function getRandomPlayer() public view returns (address randomPlayer) {
        if( players.keys.length == 0 ){
            return BURN_WALLET;
        }
        uint random = uint(keccak256(abi.encodePacked(nbRandom, _msgSender(), there, block.timestamp, block.difficulty))) % players.keys.length;
        return players.keys[random];
    }
    /**
     * @dev Get informations of a player
     */
    function getPlayer(address player) public view returns(address key, uint256 wins, uint256 looses, bool banned, uint256 unlockTime){
        if( !players.inserted[player] ){
            return (address(0), 0, 0, false, 0);
        }
        return (player, players.wins[player], players.looses[player], players.banned[player], players.unlockTime[player]);
    }
    /**
     * @dev Subscription fee distribution
     * Can only inside of subscribe mthod.
     */
    function sendSubscribeFees() private {
        uint256 balanceLiquidity = amountSubscribe.mul(liquidityFeeSubscribe).div(100);
        uint256 balanceMarketing = amountSubscribe.mul(marketingFeeSubscribe).div(100);
        uint256 balanceRandom = amountSubscribe.mul(randomFeeSubscribe).div(100);
        uint256 balanceBurn = amountSubscribe.mul(burnFeeSubscribe).div(100);
        
        uint256 attemptBalanceRandom = ERC20(BABYTOSHI_ADDRESS).balanceOf(there).sub(amountSubscribe);
        
        bool marketingSwapped = swapTokenForETH(BABYTOSHI_ADDRESS, balanceMarketing, MARKETING_WALLET);
        require(marketingSwapped, "no transfer bnb marketing");
        
        bool burned = burn(balanceBurn);
        require(burned, "NON burn tokens");
        
        bool liquidityAdded = addLiquidity(balanceLiquidity);
        require(liquidityAdded, "no liquidity added");
        
        uint256 balanceGiveAway = ERC20(BABYTOSHI_ADDRESS).balanceOf(there).sub(attemptBalanceRandom);
        require(balanceGiveAway >= balanceRandom, "not random");
        address randomPlayer = address(0);
        if( size() > 1 ){ // minimum 2 players to send to random player, ifnot add to liquidity
            randomPlayer = getRandomPlayer();
            bool transferredToRandom = transferTo(BABYTOSHI_ADDRESS, randomPlayer, balanceGiveAway);
            require(transferredToRandom, "NON transfer tokens random");
            lastWinnerFeeSubscribe = randomPlayer;
            nbRandom++; // increase value of 'getRandomPlayer', to get new hash each time
        }else{
            liquidityAdded = addLiquidity(balanceGiveAway);
            require(liquidityAdded, "no liquidity added");
        }
        emit SendSubscribeFees(there, _msgSender(), amountSubscribe, balanceLiquidity, balanceMarketing, balanceRandom, balanceBurn, randomPlayer);
    }
    
    /**
     * @dev Subscription of a player
     * Can only be called by new player.
     */
    function subscribe() public notOwner notPlayers notBanned {
        bool transferredFrom = transferFrom(BABYTOSHI_ADDRESS, _msgSender(), amountSubscribe);
        require(transferredFrom, "NOT transfer register");
        players.wins[_msgSender()] = 0;
        players.looses[_msgSender()] = 0;
        players.banned[_msgSender()] = false;
        players.unlockTime[_msgSender()] = 0;
        players.indexOf[_msgSender()] = players.keys.length;
        players.inserted[_msgSender()] = true;
        players.keys.push(_msgSender());
        sendSubscribeFees();
        emit Subscribe(there, _msgSender());
    }
    function getIndexOfKey(address key) internal view returns (int index) {
        if(!players.inserted[key]) {
            return -1;
        }
        return int(players.indexOf[key]);
    }
    function getKeyAtIndex(uint index) internal view returns (address playerAddress) {
        return players.keys[index];
    }
    
    function contains(address key) public view returns(bool isPlayer){
        return players.inserted[key];
    }
    function size() public view returns (uint length) {
        return players.keys.length;
    }
    
    function isBanned(address key) public view returns(bool banned) {
        return bannedPlayers[key];
    }
    
    /**
     * @dev Update player stats.
     * Can only be called by allowed contracts.
     */
    function incrementWin(address key) public onlyAllowedContracts {
        if( !players.inserted[key] ){
            return;
        }
        players.wins[key] += 1;
        emit UpdatePlayerStatistics(there, _msgSender(), players.wins[key], players.looses[key]);
    }
    /**
     * @dev Update player stats.
     * Can only be called by allowed contracts.
     */
    function incrementLoose(address key) public onlyAllowedContracts {
        if( !players.inserted[key] ){
            return;
        }
        players.looses[key] += 1;
        emit UpdatePlayerStatistics(there, _msgSender(), players.wins[key], players.looses[key]);
    }
    
    /**
     * @dev Players ban himself mporary
     * Can only be called by the current player.
     */
    function temporaryBanMySelf() public onlyPlayers notBanned {
        bannedPlayers[_msgSender()] = true;
        players.banned[_msgSender()] = true;
        players.unlockTime[_msgSender()] = block.timestamp + temporaryBanTime;
        emit BanPlayer(there, _msgSender(), block.timestamp + temporaryBanTime);
    }
    /**
     * @dev Players ban himself permanently
     * Can only be called by the current player.
     */
    function permanentBanMySelf() public onlyPlayers {
        bannedPlayers[_msgSender()] = true;
        players.banned[_msgSender()] = true;
        players.unlockTime[_msgSender()] = block.timestamp + permanentBanTime;
        emit BanPlayer(there, _msgSender(), block.timestamp + permanentBanTime);
    }
    /**
     * @dev Players permit himself, after ban
     * Can only be called by the current player and after unlockTime
     */
    function permitMySelf() public onlyPlayers {
        if( block.timestamp <= players.unlockTime[_msgSender()] ){
            return;
        }
        delete bannedPlayers[_msgSender()];
        players.banned[_msgSender()] = false;
        players.unlockTime[_msgSender()] = 0;
        emit PermitPlayer(there, _msgSender());
    }
    
    /**
     * @dev Ban address permanently.
     * Can only be called by the current owner.
     */
    function banAddress(address key) public virtual onlyOwner {
        if( players.inserted[key] ){
            return;
        }
        bannedPlayers[key] = true;
        emit BanPlayer(there, key, block.timestamp + permanentBanTime);
    }
    /**
     * @dev Ban multiple addresses permently.
     * Can only be called by the current owner.
     */
    function banAddresses(address[] memory keys) public virtual onlyOwner {
        for( uint256 i=0; i < keys.length; i++ ){
            banAddress(keys[i]);
        }
        emit BanPlayers(there, keys, block.timestamp + permanentBanTime);
    }
}