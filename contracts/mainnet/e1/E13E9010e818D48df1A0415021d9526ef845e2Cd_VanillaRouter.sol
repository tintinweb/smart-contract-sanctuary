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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
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
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal {
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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.8;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
    @title The Uniswap-enabled base contract for Vanilla.
*/
contract UniswapTrader {
    using SafeMath for uint256;

    string private constant _ERROR_SLIPPAGE_LIMIT_EXCEEDED = "a1";
    string private constant _INVALID_UNISWAP_PAIR = "a2";

    address internal immutable _uniswapFactoryAddr;
    address internal immutable _wethAddr;

    // internally tracked reserves for price manipulation protection for each token (Uniswap uses uint112 so uint128 is plenty)
    mapping(address => uint128) public wethReserves;

    /**
        @notice Deploys the contract and initializes Uniswap contract references and internal WETH-reserve for safe tokens.
        @dev using UniswapRouter to ensure that Vanilla uses the same WETH contract
        @param routerAddress The address of UniswapRouter contract
        @param limit The initial reserve value for tokens in the safelist
        @param safeList The list of "safe" tokens to trade
     */
    constructor(
        address routerAddress,
        uint128 limit,
        address[] memory safeList
    ) public {
        // fetch addresses via router to guarantee correctness
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address wethAddr = router.WETH();
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        for (uint256 i = 0; i < safeList.length; i++) {
            address token = safeList[i];
            // verify that WETH-token pair exists in Uniswap
            // (order isn't significant, UniswapV2Factory.createPair populates the mapping in reverse direction too)
            address pair = factory.getPair(token, wethAddr);
            require(pair != address(0), _INVALID_UNISWAP_PAIR);

            // we initialize the fixed list of rewardedTokens with the reserveLimit-value that they'll match the invariant
            // "every rewardedToken will have wethReserves[rewardedToken] > 0"
            // (this way we don't need to store separate lists for both wethReserve-tracking and tokens eligible for the rewards)
            wethReserves[token] = limit;
        }
        _wethAddr = wethAddr;
        _uniswapFactoryAddr = address(factory);
    }

    /**
        @notice Checks if the given ERC-20 token will be eligible for rewards (i.e. a safelisted token)
        @param token The ERC-20 token address
     */
    function isTokenRewarded(address token) public view returns (bool) {
        return wethReserves[token] > 0;
    }

    function _pairInfo(
        address factory,
        address token,
        address weth
    ) internal pure returns (address pair, bool tokenFirst) {
        // as order of tokens is important in Uniswap pairs, we record this information here and pass it on to caller
        // for gas optimization
        tokenFirst = token < weth;

        // adapted from UniswapV2Library.sol, calculates the CREATE2 address for a pair without making any external calls to factory contract
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(
                            tokenFirst
                                ? abi.encodePacked(token, weth)
                                : abi.encodePacked(weth, token)
                        ),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                    )
                )
            )
        );
    }

    function _amountToSwap(
        uint256 tokensIn,
        uint256 reservesIn,
        uint256 reservesOut
    ) internal pure returns (uint256 tokensOut) {
        uint256 inMinusFee = tokensIn.mul(997); // in * (100% - 0.3%)
        tokensOut = reservesOut.mul(inMinusFee).div(
            reservesIn.mul(1000).add(inMinusFee)
        );
    }

    function _updateReservesOnBuy(address token, uint112 wethReserve)
        private
        returns (uint128 reserve)
    {
        // when buying, update internal reserve only if Uniswap reserve is greater
        reserve = wethReserves[token];
        if (reserve == 0) {
            // trading a non-safelisted token, so do not update internal reserves
            return reserve;
        }
        if (wethReserve > reserve) {
            wethReserves[token] = wethReserve;
            reserve = wethReserve;
        }
    }

    function _buyInUniswap(
        address token_,
        uint256 eth,
        uint256 amount_,
        address tokenOwner_
    ) internal returns (uint256 numToken, uint128 reserve) {
        (address pairAddress, bool tokenFirst) =
            _pairInfo(_uniswapFactoryAddr, token_, _wethAddr);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        address tokenCustody = address(this);
        uint256 balance = IERC20(token_).balanceOf(tokenCustody);
        IERC20(_wethAddr).transferFrom(tokenOwner_, pairAddress, eth);
        if (tokenFirst) {
            (uint112 tokenReserve, uint112 wethReserve, ) = pair.getReserves();
            pair.swap(
                _amountToSwap(eth, wethReserve, tokenReserve),
                uint256(0),
                tokenCustody,
                new bytes(0)
            );
            reserve = _updateReservesOnBuy(token_, wethReserve);
        } else {
            (uint112 wethReserve, uint112 tokenReserve, ) = pair.getReserves();
            pair.swap(
                uint256(0),
                _amountToSwap(eth, wethReserve, tokenReserve),
                tokenCustody,
                new bytes(0)
            );
            reserve = _updateReservesOnBuy(token_, wethReserve);
        }
        // finally check how the custody balance has changed after swap
        numToken = IERC20(token_).balanceOf(tokenCustody) - balance;
        // revert if the price diff between trade-time and execution-time was too large
        require(numToken >= amount_, _ERROR_SLIPPAGE_LIMIT_EXCEEDED);
    }

    function _updateReservesOnSell(address token, uint112 wethReserve)
        private
        returns (uint128 reserve)
    {
        // when selling, update internal reserve only if the Uniswap reserve is smaller
        reserve = wethReserves[token];
        if (reserve == 0) {
            // trading a non-safelisted token, so do not update internal reserves
            return reserve;
        }
        if (wethReserve < reserve) {
            wethReserves[token] = wethReserve;
            reserve = wethReserve;
        }
    }

    function _sellInUniswap(
        address token_,
        uint256 amount_,
        uint256 eth_,
        address tokenReceiver_
    ) internal returns (uint256 numEth, uint128 reserve) {
        (address pairAddress, bool tokenFirst) =
            _pairInfo(_uniswapFactoryAddr, token_, _wethAddr);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        uint256 balance = IERC20(_wethAddr).balanceOf(tokenReceiver_);

        // Use TransferHelper because we have no idea here how token.transfer() has been implemented
        TransferHelper.safeTransfer(token_, pairAddress, amount_);
        if (tokenFirst) {
            (uint112 tokenReserve, uint112 wethReserve, ) = pair.getReserves();
            pair.swap(
                uint256(0),
                _amountToSwap(amount_, tokenReserve, wethReserve),
                tokenReceiver_,
                new bytes(0)
            );
            reserve = _updateReservesOnSell(token_, wethReserve);
        } else {
            (uint112 wethReserve, uint112 tokenReserve, ) = pair.getReserves();
            pair.swap(
                _amountToSwap(amount_, tokenReserve, wethReserve),
                uint256(0),
                tokenReceiver_,
                new bytes(0)
            );
            reserve = _updateReservesOnSell(token_, wethReserve);
        }
        // finally check how the receivers balance has changed after swap
        numEth = IERC20(_wethAddr).balanceOf(tokenReceiver_) - balance;
        // revert if the price diff between trade-time and execution-time was too large
        require(numEth >= eth_, _ERROR_SLIPPAGE_LIMIT_EXCEEDED);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 @title Governance Token for Vanilla Finance.
 */
contract VanillaGovernanceToken is ERC20("Vanilla", "VNL") {
    string private constant _ERROR_ACCESS_DENIED = "c1";
    address private immutable _owner;

    /**
        @notice Deploys the token and sets the caller as an owner.
     */
    constructor() public {
        _owner = msg.sender;
        // set the decimals explicitly to 12, for (theoretical maximum of) VNL reward of a 1ETH of profit
        // should be displayed as 1000000VNL (18-6 = 12 decimals).
        _setupDecimals(12);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, _ERROR_ACCESS_DENIED);
        _;
    }

    /**
        @notice Mints the tokens. Used only by the VanillaRouter-contract.

        @param to The recipient address of the minted tokens
        @param tradeReward The amount of tokens to be minted
     */
    function mint(address to, uint256 tradeReward) external onlyOwner {
        _mint(to, tradeReward);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./VanillaGovernanceToken.sol";
import "./UniswapTrader.sol";

/// @dev Needed functions from the WETH contract originally deployed in https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

/**
    @title The main entrypoint for Vanilla
*/
contract VanillaRouter is UniswapTrader {
    string private constant _ERROR_TRADE_EXPIRED = "b1";
    string private constant _ERROR_TRANSFER_FAILED = "b2";
    string private constant _ERROR_TOO_MANY_TRADES_PER_BLOCK = "b3";
    string private constant _ERROR_NO_TOKEN_OWNERSHIP = "b4";
    string private constant _ERROR_RESERVELIMIT_TOO_LOW = "b5";
    string private constant _ERROR_NO_SAFE_TOKENS = "b6";

    uint256 public immutable epoch;
    VanillaGovernanceToken public immutable vnlContract;
    uint128 public immutable reserveLimit;

    using SafeMath for uint256;

    // data for calculating volume-weighted average prices, average purchasing block, and limiting trades per block
    struct PriceData {
        uint256 ethSum;
        uint256 tokenSum;
        uint256 weightedBlockSum;
        uint256 latestBlock;
    }

    // Price data, indexed as [owner][token]
    mapping(address => mapping(address => PriceData)) public tokenPriceData;

    /**
       @dev Emitted when tokens are sold.
       @param seller The owner of tokens.
       @param token The address of the sold token.
       @param amount Number of sold tokens.
       @param eth The received ether from the trade.
       @param profit The calculated profit from the trade.
       @param reward The amount of VanillaGovernanceToken reward tokens transferred to seller.
       @param reserve The internally tracker Uniswap WETH reserve before trade.
     */
    event TokensSold(
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 eth,
        uint256 profit,
        uint256 reward,
        uint256 reserve
    );

    /**
       @dev Emitted when tokens are bought.
       @param buyer The new owner of tokens.
       @param token The address of the purchased token.
       @param eth The amount of ether spent in the trade.
       @param amount Number of purchased tokens.
       @param reserve The internally tracker Uniswap WETH reserve before trade.
     */
    event TokensPurchased(
        address indexed buyer,
        address indexed token,
        uint256 eth,
        uint256 amount,
        uint256 reserve
    );

    /**
        @notice Deploys the contract and the VanillaGovernanceToken contract.
        @dev initializes the token contract for safe reference and sets the epoch for reward calculations
        @param uniswapRouter The address of UniswapRouter contract
        @param limit The minimum WETH reserve for a token to be eligible in profit mining
        @param safeList The list of ERC-20 addresses that are considered "safe", and will be eligible for rewards
    */
    constructor(
        address uniswapRouter,
        uint128 limit,
        address[] memory safeList
    ) public UniswapTrader(uniswapRouter, limit, safeList) {
        vnlContract = new VanillaGovernanceToken();
        epoch = block.number;
        require(limit > 0, _ERROR_RESERVELIMIT_TOO_LOW);
        require(safeList.length > 0, _ERROR_NO_SAFE_TOKENS);
        reserveLimit = limit;
    }

    modifier beforeDeadline(uint256 deadline) {
        require(deadline >= block.timestamp, _ERROR_TRADE_EXPIRED);
        _;
    }

    /**
        @notice Buys the tokens with Ether. Use the external pricefeed for pricing.
        @dev Buys the `numToken` tokens for all the msg.value Ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be bought
        @param numToken The amount of ERC20 tokens to be bought
        @param blockTimeDeadline The block timestamp when this buy-transaction expires
     */
    function depositAndBuy(
        address token,
        uint256 numToken,
        uint256 blockTimeDeadline
    ) external payable beforeDeadline(blockTimeDeadline) {
        IWETH weth = IWETH(_wethAddr);
        uint256 numEth = msg.value;
        weth.deposit{value: numEth}();

        // execute swap using WETH-balance of this contract
        _executeBuy(msg.sender, address(this), token, numEth, numToken);
    }

    /**
        @notice Buys the tokens with WETH. Use the external pricefeed for pricing.
        @dev Buys the `numToken` tokens for all the msg.value Ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be bought
        @param numEth The amount of WETH to spend. Needs to be pre-approved for the VanillaRouter.
        @param numToken The amount of ERC20 tokens to be bought
        @param blockTimeDeadline The block timestamp when this buy-transaction expires
     */
    function buy(
        address token,
        uint256 numEth,
        uint256 numToken,
        uint256 blockTimeDeadline
    ) external beforeDeadline(blockTimeDeadline) {
        // execute swap using WETH-balance of the caller
        _executeBuy(msg.sender, msg.sender, token, numEth, numToken);
    }

    function _executeBuy(
        address owner,
        address currentWETHHolder,
        address token,
        uint256 numEthSold,
        uint256 numToken
    ) internal {
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        PriceData storage prices = tokenPriceData[owner][token];
        require(
            block.number > prices.latestBlock,
            _ERROR_TOO_MANY_TRADES_PER_BLOCK
        );
        prices.latestBlock = block.number;

        // do the swap and update price data
        (uint256 tokens, uint256 newReserve) =
            _buyInUniswap(token, numEthSold, numToken, currentWETHHolder);
        prices.ethSum = prices.ethSum.add(numEthSold);
        prices.tokenSum = prices.tokenSum.add(tokens);
        prices.weightedBlockSum = prices.weightedBlockSum.add(
            block.number.mul(tokens)
        );
        emit TokensPurchased(msg.sender, token, numEthSold, tokens, newReserve);
    }

    /**
        @dev Receives the ether only from WETH contract during withdraw()
     */
    receive() external payable {
        // make sure that router accepts ETH only from WETH contract
        assert(msg.sender == _wethAddr);
    }

    /**
        @notice Sells the tokens the caller owns. Use the external pricefeed for pricing.
        @dev Sells the `numToken` tokens msg.sender owns, for `numEth` ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be sold
        @param numToken The amount of ERC20 tokens to be sold
        @param numEthLimit The minimum amount of ether to be received for exchange (the limit order)
        @param blockTimeDeadline The block timestamp when this sell-transaction expires
     */
    function sell(
        address token,
        uint256 numToken,
        uint256 numEthLimit,
        uint256 blockTimeDeadline
    ) external beforeDeadline(blockTimeDeadline) {
        // execute the swap by transferring WETH directly to caller
        _executeSell(msg.sender, msg.sender, token, numToken, numEthLimit);
    }

    /**
        @notice Sells the tokens the caller owns. Use the external pricefeed for pricing.
        @dev Sells the `numToken` tokens msg.sender owns, for `numEth` ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be sold
        @param numToken The amount of ERC20 tokens to be sold
        @param numEthLimit The minimum amount of ether to be received for exchange (the limit order)
        @param blockTimeDeadline The block timestamp when this sell-transaction expires
     */
    function sellAndWithdraw(
        address token,
        uint256 numToken,
        uint256 numEthLimit,
        uint256 blockTimeDeadline
    ) external beforeDeadline(blockTimeDeadline) {
        // execute the swap by transferring WETH to this contract first
        uint256 numEth =
            _executeSell(
                msg.sender,
                address(this),
                token,
                numToken,
                numEthLimit
            );

        IWETH iweth = IWETH(_wethAddr);
        iweth.withdraw(numEth);

        (bool etherTransferSuccessful, ) =
            msg.sender.call{value: numEth}(new bytes(0));
        require(etherTransferSuccessful, _ERROR_TRANSFER_FAILED);
    }

    function _executeSell(
        address owner,
        address recipient,
        address token,
        uint256 numTokensSold,
        uint256 numEthLimit
    ) internal returns (uint256) {
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        PriceData storage prices = tokenPriceData[owner][token];
        require(
            block.number > prices.latestBlock,
            _ERROR_TOO_MANY_TRADES_PER_BLOCK
        );
        prices.latestBlock = block.number;

        // do the swap, calculate the profit and update price data
        (uint256 numEth, uint128 reserve) =
            _sellInUniswap(token, numTokensSold, numEthLimit, recipient);

        uint256 profitablePrice =
            numTokensSold.mul(prices.ethSum).div(prices.tokenSum);
        uint256 avgBlock = prices.weightedBlockSum.div(prices.tokenSum);
        uint256 newTokenSum = prices.tokenSum.sub(numTokensSold);
        uint256 profit =
            numEth > profitablePrice ? numEth.sub(profitablePrice) : 0;

        prices.ethSum = _proportionOf(
            prices.ethSum,
            newTokenSum,
            prices.tokenSum
        );
        prices.weightedBlockSum = _proportionOf(
            prices.weightedBlockSum,
            newTokenSum,
            prices.tokenSum
        );
        prices.tokenSum = newTokenSum;

        uint256 reward = 0;
        if (isTokenRewarded(token)) {
            // calculate the reward, and mint tokens
            reward = _calculateReward(
                epoch,
                avgBlock,
                block.number,
                profit,
                reserve,
                reserveLimit
            );
            if (reward > 0) {
                vnlContract.mint(msg.sender, reward);
            }
        }

        emit TokensSold(
            msg.sender,
            token,
            numTokensSold,
            numEth,
            profit,
            reward,
            reserve
        );
        return numEth;
    }

    /**
        @notice Estimates the reward.
        @dev Estimates the reward for given `owner` when selling `numTokensSold``token`s for `numEth` Ether. Also returns the individual components of the reward formula.
        @return profitablePrice The expected amount of Ether for this trade. Profit of this trade can be calculated with `numEth`-`profitablePrice`.
        @return avgBlock The volume-weighted average block for the `owner` and `token`
        @return htrs The Holding/Trading Ratio, Squared- estimate for this trade, percentage value range in fixed point range 0-100.0000.
        @return vpc The Value-Protection Coefficient- estimate for this trade, percentage value range in fixed point range 0-100.0000.
        @return reward The token reward estimate for this trade.
     */
    function estimateReward(
        address owner,
        address token,
        uint256 numEth,
        uint256 numTokensSold
    )
        external
        view
        returns (
            uint256 profitablePrice,
            uint256 avgBlock,
            uint256 htrs,
            uint256 vpc,
            uint256 reward
        )
    {
        PriceData storage prices = tokenPriceData[owner][token];
        require(prices.tokenSum > 0, _ERROR_NO_TOKEN_OWNERSHIP);
        profitablePrice = numTokensSold.mul(prices.ethSum).div(prices.tokenSum);
        avgBlock = prices.weightedBlockSum.div(prices.tokenSum);
        if (numEth > profitablePrice) {
            uint256 profit = numEth.sub(profitablePrice);
            uint128 wethReserve = wethReserves[token];
            htrs = _estimateHTRS(avgBlock);
            vpc = _estimateVPC(profit, wethReserve);
            reward = _calculateReward(
                epoch,
                avgBlock,
                block.number,
                profit,
                wethReserve,
                reserveLimit
            );
        } else {
            htrs = 0;
            vpc = 0;
            reward = 0;
        }
    }

    function _estimateHTRS(uint256 avgBlock) internal view returns (uint256) {
        // H     = "Holding/Trading Ratio, Squared" (HTRS)
        //       = ((Bmax-Bavg)/(Bmax-Bmin))²
        //       = (((Bmax-Bmin)-(Bavg-Bmin))/(Bmax-Bmin))²
        //       = (Bhold/Btrade)² (= 0 if Bmax = Bavg, NaN if Bmax = Bmin)
        if (avgBlock == block.number || block.number == epoch) return 0;

        uint256 bhold = block.number - avgBlock;
        uint256 btrade = block.number - epoch;

        return bhold.mul(bhold).mul(1_000_000).div(btrade.mul(btrade));
    }

    function _estimateVPC(uint256 profit, uint256 reserve)
        internal
        view
        returns (uint256)
    {
        // VPC = 1-max((P + L)/W, 1) (= 0 if P+L > W)
        //     = (W - P - L ) / W
        if (profit + reserveLimit > reserve) return 0;

        return (reserve - profit - reserveLimit).mul(1_000_000).div(reserve);
    }

    function _calculateReward(
        uint256 epoch_,
        uint256 avgBlock,
        uint256 currentBlock,
        uint256 profit,
        uint128 wethReserve,
        uint128 reserveLimit_
    ) internal pure returns (uint256) {
        /*
        Reward formula:
            P     = absolute profit in Ether = `profit`
            Bmax  = block.number when trade is happening = `block.number`
            Bavg  = volume-weighted average block.number of purchase = `avgBlock`
            Bmin  = "epoch", the block.number when contract was deployed = `epoch_`
            Bhold = Bmax-Bavg = number of blocks the trade has been held (instead of traded)
            Btrade= Bmax-Bmin = max possible trading time in blocks
            H     = "Holding/Trading Ratio, Squared" (HTRS)
                  = ((Bmax-Bavg)/(Bmax-Bmin))²
                  = (((Bmax-Bmin)-(Bavg-Bmin))/(Bmax-Bmin))²
                  = (Bhold/Btrade)² (= 0 if Bmax = Bavg, NaN if Bmax = Bmin)
            L     = WETH reserve limit for any traded token = `_reserveLimit`
            W     = internally tracked WETH reserve size for when selling a token = `wethReserve`
            V     = value protection coefficient
                  = 1-min((P + L)/W, 1) (= 0 if P+L > W)
            R     = minted rewards
                  = P*V*H
                  = if   (P = 0 || P + L > W || Bmax = Bavg || BMax = Bmin)
                         0
                    else P * (1-(P + L)/W) * (Bhold/Btrade)²
                       = (P * (W - P - L) * Bhold²) / W / Btrade²
        */

        if (profit == 0) return 0;
        if (profit + reserveLimit_ > wethReserve) return 0;
        if (currentBlock == avgBlock) return 0;
        if (currentBlock == epoch_) return 0;

        // these cannot underflow thanks to previous checks
        uint256 rpl = wethReserve - profit - reserveLimit_;
        uint256 bhold = currentBlock - avgBlock;
        uint256 btrade = currentBlock - epoch_;

        uint256 nominator = profit.mul(rpl).mul(bhold.mul(bhold));
        // no division by zero possible, both wethReserve and btrade² are always > 0
        return nominator / wethReserve / (btrade.mul(btrade));
    }

    function _proportionOf(
        uint256 total,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        // percentage = (numerator/denominator)
        // proportion = total * percentage
        return total.mul(numerator).div(denominator);
    }
}

