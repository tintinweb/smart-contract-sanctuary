/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// File: contracts/IUniswapV2Router.sol



pragma solidity ^0.6.2;

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



// pragma solidity >=0.6.2;

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

// File: contracts/SafeMathInt.sol



/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.6.2;

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

// File: contracts/SafeMathUint.sol



pragma solidity ^0.6.2;

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

// File: contracts/SafeMath.sol



pragma solidity ^0.6.2;

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

// File: contracts/Context.sol



pragma solidity ^0.6.2;

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

// File: contracts/Ownable.sol

pragma solidity ^0.6.2;



contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
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
// File: contracts/IERC20.sol



pragma solidity ^0.6.2;

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
// File: contracts/IERC20Metadata.sol



pragma solidity ^0.6.2;


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
// File: contracts/ERC20.sol



pragma solidity ^0.6.2;





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
    using SafeMath for uint256;

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
    constructor(string memory name_, string memory symbol_) public {
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
// File: contracts/Staking.sol



pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;







contract LowerTierStaking is Ownable {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    address public DIVIDEND_TOKEN;
    address public HEDGE;


    // With `magnitude`, we can properly distribute dividends even if the amount of received dividends is small.
    uint256 constant internal magnitude = 2**128;

    uint256 public withdrawalFee;
    uint256 public hedgeBoost = 0;

    mapping(address => uint256) public magnifiedDividendPerShare;
    mapping(address => mapping(address => int256)) public magnifiedDividendCorrections;
    mapping(address => mapping(address => uint256)) public withdrawnDividends;
    mapping(address => uint) public stakes;

    // Stuff for providing Hedge APY from fee
    uint256 public magnifiedHedgePerShare;
    uint256 public totalHedgeDistributed;
    uint256 public totalHedgeWithdrawn;
    mapping(address => int256) public magnifiedHedgeCorrections;
    mapping(address => uint256) public withdrawnHedge;
    /////////

    mapping(address => uint256) public totalDividendsDistributed;
    mapping(address => uint256) public totalDividendsWithdrawn;
    mapping(address => bool) public prevDividend;

    // Stuff for providing APY and Rewards to frontend
    uint public start;
    order[] internal orders;

    struct order {
        address token;
        uint256 amount;
    }

    address[] public dividendTokens;

    //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D <-- rinkeby uniswap
    //0x10ED43C718714eb63d5aA57B78B54704E256024E <-- bsc pancake
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    constructor(address _hedge, address _dividendToken) public{
        DIVIDEND_TOKEN = _dividendToken;
        dividendTokens.push(DIVIDEND_TOKEN);
        prevDividend[DIVIDEND_TOKEN] = true;
        HEDGE = _hedge;
        withdrawalFee = 200; // 2% in basis points
        start = now;
    }

    function updateWithdrawalFee(uint newFee) public onlyOwner {
        require(withdrawalFee < 1000, "Fee cant be more than 10%");
        withdrawalFee = newFee;
    }

    function updateRouter(address newRouter) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newRouter);
    }

    function changeDividendToken(address newToken) public onlyOwner {
        calculateNewDividends();
        DIVIDEND_TOKEN = newToken;
        if (!prevDividend[DIVIDEND_TOKEN]) {
            prevDividend[DIVIDEND_TOKEN] = true;
            dividendTokens.push(DIVIDEND_TOKEN);
        }
    }

    // Function to withdraw random tokens people may send to the pool
    function withdrawRandomToken(address token) public onlyOwner {
        require(token != HEDGE, "You cant withdraw Hedge this way");
        require(!prevDividend[token], "You cant withdraw a dividend token");
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    //Frontend Getters
    function getHedgeBoostRatio() public view returns (uint256) {
        return 0;
    }

    //@return: Annualized amount of HEDGE dividends distributed
    function getStakerHedgeAPYTotal() public view returns (uint256) {
        uint diff = (now.sub(start)).add(1); // add 1 to include intialization block, avoid divide by zero
        return (totalHedgeDistributed.mul(31536000)).div(diff);
    }

    //@return: Annualized amount of HEDGE dividends distributed per HEDGE staked
    function getStakerHedgeAPYPerHedge() public view returns (uint256) {
        uint diff = (now.sub(start)).add(1); // add 1 to include intialization block, avoid divide by zero
        uint balance = ERC20(HEDGE).balanceOf(address(this));
        uint correction = totalHedgeDistributed.sub(totalHedgeWithdrawn);
        balance = balance.sub(correction);
        // Divide by 0 error
        if (balance == 0 || diff == 0) {
            return 0;
        }
        else {
            return ((totalHedgeDistributed.mul(31536000).mul(1000000000000000000)).div(diff.mul(balance)));
        }
    }

    //@return: All of the rewards accumulated by the staker
    function getAllRewards(address user) public view returns (order[] memory) {
        uint size = dividendTokens.length;
        order[] memory allRewards = new order[](size);
        for (uint i = 0; i < size; i++) {
            allRewards[i] = order({token: dividendTokens[i], amount: withdrawableDividendOfToken(user, dividendTokens[i])});
        }
        return allRewards;
    }

    //HEDGE APY Functions
    function accumulativeHedgeOf(address _owner) public view returns(uint256) {
        return magnifiedHedgePerShare.mul(stakes[_owner]).toInt256Safe()
        .add(magnifiedHedgeCorrections[_owner]).toUint256Safe() / magnitude;
    }

    function withdrawableHedgeOf(address _owner) public view returns(uint256) {
        return accumulativeHedgeOf(_owner).sub(withdrawnHedge[_owner]);
    }

    function withdrawnHedgeOf(address _owner) public view returns(uint256) {
        return withdrawnHedge[_owner];
    }

    function distributeHEDGEDividends(uint256 amount) internal {
        uint balance = ERC20(HEDGE).balanceOf(address(this));
        uint correction = totalHedgeDistributed.sub(totalHedgeWithdrawn);
        balance = balance.sub(correction).sub(amount);
        if (amount > 0) {
            magnifiedHedgePerShare = magnifiedHedgePerShare.add(
                (amount).mul(magnitude) / (balance)
            );
            totalHedgeDistributed = totalHedgeDistributed.add(amount);
        }
    }

    function withdrawHedgeDividend(address user) public {
        uint256 _withdrawableHedge = withdrawableHedgeOf(user);
        if (_withdrawableHedge > 0) {
            withdrawnHedge[user] = withdrawnHedge[user].add(_withdrawableHedge);
            totalHedgeWithdrawn = totalHedgeWithdrawn.add(_withdrawableHedge);
            bool success = IERC20(HEDGE).transfer(user, _withdrawableHedge);
            require(success, "transfer failed");
        }
    }

    function restakeHedgeDividend(address user) public {
        uint256 withdrawableHedge = withdrawableHedgeOf(user);
        if (withdrawableHedge > 0) {
            withdrawnHedge[user] = withdrawnHedge[user].add(withdrawableHedge);
            totalHedgeWithdrawn = totalHedgeWithdrawn.add(withdrawableHedge);
            stakes[msg.sender] = stakes[msg.sender].add(withdrawableHedge);
            _mint(msg.sender, withdrawableHedge);
        }
    }
    // END HEDGE APY Functions

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) public view returns(uint256) {
        return magnifiedDividendPerShare[DIVIDEND_TOKEN].mul(stakes[_owner]).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner][DIVIDEND_TOKEN]).toUint256Safe() / magnitude;
    }


    function accumulativeDividendOfToken(address _owner, address token) public view returns(uint256) {
        return magnifiedDividendPerShare[token].mul(stakes[_owner]).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner][token]).toUint256Safe() / magnitude;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) public view returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner][DIVIDEND_TOKEN]);
    }

    function withdrawableDividendOfToken(address _owner, address token) public view returns(uint256) {
        return accumulativeDividendOfToken(_owner, token).sub(withdrawnDividends[_owner][token]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view returns(uint256) {
        return withdrawnDividends[_owner][DIVIDEND_TOKEN];
    }

    //TEST FUNCTION
    function calculateNewRewardsCheck() public view returns(uint){
        uint diff = totalDividendsDistributed[DIVIDEND_TOKEN].sub(totalDividendsWithdrawn[DIVIDEND_TOKEN]);
        uint256 newRewards = ERC20(DIVIDEND_TOKEN).balanceOf(address(this)).sub(diff);
        return newRewards;
    }

    function calculateNewDividends() public {
        uint diff = totalDividendsDistributed[DIVIDEND_TOKEN].sub(totalDividendsWithdrawn[DIVIDEND_TOKEN]);
        uint256 newRewards = ERC20(DIVIDEND_TOKEN).balanceOf(address(this)).sub(diff);
        if (newRewards > 0) {
            distributeREWARDDividends(newRewards);
        }
    }

    function distributeREWARDDividends(uint256 amount) internal {
        require(ERC20(HEDGE).balanceOf(address(this)) > 0);
        uint balance = ERC20(HEDGE).balanceOf(address(this));
        uint correction = totalHedgeDistributed.sub(totalHedgeWithdrawn);

        balance = balance.sub(correction);
        if (amount > 0) {
            magnifiedDividendPerShare[DIVIDEND_TOKEN] = magnifiedDividendPerShare[DIVIDEND_TOKEN].add(
                (amount).mul(magnitude) / balance
            );

            totalDividendsDistributed[DIVIDEND_TOKEN] = totalDividendsDistributed[DIVIDEND_TOKEN].add(amount);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public {
        _withdrawDividendOfUser(msg.sender);
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address user) internal returns (uint256) {
        calculateNewDividends();
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user][DIVIDEND_TOKEN] = withdrawnDividends[user][DIVIDEND_TOKEN].add(_withdrawableDividend);
            totalDividendsWithdrawn[DIVIDEND_TOKEN] = totalDividendsWithdrawn[DIVIDEND_TOKEN].add(_withdrawableDividend);
            bool success = IERC20(DIVIDEND_TOKEN).transfer(user, _withdrawableDividend);

            if(!success) {
                withdrawnDividends[user][DIVIDEND_TOKEN] = withdrawnDividends[user][DIVIDEND_TOKEN].sub(_withdrawableDividend);
                totalDividendsWithdrawn[DIVIDEND_TOKEN] = totalDividendsWithdrawn[DIVIDEND_TOKEN].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function _withdrawDividendOfUserToken(address user, address token) internal {
        calculateNewDividends();
        uint256 _withdrawableDividend = withdrawableDividendOfToken(user, token);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user][token] = withdrawnDividends[user][token].add(_withdrawableDividend);
            totalDividendsWithdrawn[token] = totalDividendsWithdrawn[token].add(_withdrawableDividend);
            require(IERC20(token).transfer(user, _withdrawableDividend), "Transfer Failed");
        }
    }

    function withdrawDividendOfUserToken(address user, address token) public {
        _withdrawDividendOfUserToken(user, token);
    }


    function withdrawAllDividends(address user) public {
        for (uint i=0; i < dividendTokens.length; i++) {
            _withdrawDividendOfUserToken(user, dividendTokens[i]);
        }
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal {
        magnifiedHedgeCorrections[account] = magnifiedHedgeCorrections[account].sub( (magnifiedHedgePerShare.mul(value)).toInt256Safe() );
        for (uint i = 0; i < dividendTokens.length; i++) {
            magnifiedDividendCorrections[account][dividendTokens[i]] = magnifiedDividendCorrections[account][dividendTokens[i]]
            .sub( (magnifiedDividendPerShare[dividendTokens[i]].mul(value)).toInt256Safe() );
        }
    }

    function stake(uint256 amount) public {
        calculateNewDividends();
        bool success = IERC20(HEDGE).transferFrom(msg.sender, address(this), amount);
        if (success) {
            stakes[msg.sender] = stakes[msg.sender].add(amount);
            _mint(msg.sender, amount);
        }
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal {
        //super._burn(account, value);
        magnifiedHedgeCorrections[account] = magnifiedHedgeCorrections[account].add( (magnifiedHedgePerShare.mul(value)).toInt256Safe() );
        for (uint i = 0; i < dividendTokens.length; i++) {
            magnifiedDividendCorrections[account][dividendTokens[i]] = magnifiedDividendCorrections[account][dividendTokens[i]]
            .add( (magnifiedDividendPerShare[dividendTokens[i]].mul(value)).toInt256Safe() );
        }
    }

    function unstake(uint256 amount) public {
        require (amount <= stakes[msg.sender]);
        calculateNewDividends();
        withdrawAllDividends(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].sub(amount);

        //Take fee here
        uint fee = amount.mul(withdrawalFee).div(10000);
        uint owed = amount.sub(fee);


        bool success = IERC20(HEDGE).transfer(msg.sender, owed);

        // if the transfer fails we want the whole transaction to revert, and not update their staking balance
        require(success, "Withdrawal unsuccessful");
        _burn(msg.sender, amount);

        // process fee
        // Here the fee is distributed among remaining stakers
        distributeHEDGEDividends(fee);
        withdrawHedgeDividend(msg.sender);
    }

    function reinvestAllRewards() public {
        for (uint i = 0; i < dividendTokens.length; i++) {
            if (withdrawableDividendOfToken(msg.sender, dividendTokens[i]) > 0) {
                reinvestReward(dividendTokens[i]);
            }
        }
    }

    function reinvestReward(address _rewardTokenAddress) public {
        calculateNewDividends();
        uint toReinvest = withdrawableDividendOfToken(msg.sender, _rewardTokenAddress);

        require(toReinvest > 0, "You dont have any rewards to reinvest");
        address[] memory path = new address[](3);
        path[0] = address(_rewardTokenAddress);
        path[1] = uniswapV2Router.WETH();
        path[2] = HEDGE;

        IERC20(_rewardTokenAddress).approve(address(uniswapV2Router), toReinvest);

        uint256 hedgeBalanceBefore = IERC20(HEDGE).balanceOf(address(this));

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            toReinvest,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 hedgeBalanceAfter = IERC20(HEDGE).balanceOf(address(this));

        withdrawnDividends[msg.sender][_rewardTokenAddress] = withdrawnDividends[msg.sender][_rewardTokenAddress].add(toReinvest);
        totalDividendsWithdrawn[_rewardTokenAddress] = totalDividendsWithdrawn[_rewardTokenAddress].add(toReinvest);

        uint256 newStake = hedgeBalanceAfter.sub(hedgeBalanceBefore);
        stakes[msg.sender] = stakes[msg.sender].add(newStake);
        _mint(msg.sender, newStake);
    }
}