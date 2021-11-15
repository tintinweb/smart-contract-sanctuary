// SPDX-License-Identifier: UNLICENSED
// 5 wallets, dividend project tokens
pragma solidity ^0.7.6;
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
// File: contracts/Context.sol
//pragma solidity >=0.6.0 <0.8.0;
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
// File: contracts/IUniswapV2Router01.sol
//pragma solidity >=0.6.2;
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
// File: contracts/IUniswapV2Router02.sol
//pragma solidity >=0.6.2;
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
// File: contracts/IUniswapV2Factory.sol
//pragma solidity >=0.5.0;
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
// File: contracts/IUniswapV2Pair.sol
//pragma solidity >=0.5.0;
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
// File: contracts/Ownable.sol
//pragma solidity ^0.7.0;
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
// File: contracts/SafeMathInt.sol
//pragma solidity ^0.7.6;
/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that revert on error
 * @dev SafeMath adapted for int256
 * Based on code of  https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol
 */
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}
// File: contracts/SafeMathUint.sol
//pragma solidity ^0.7.6;
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
// File: contracts/ERC20.sol
//pragma solidity ^0.7.0;
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
    constructor (string memory name_, string memory symbol_) {
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
// File: contracts/SafeMath.sol
//pragma solidity ^0.7.0;
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

// File: contracts/5Wallets.sol
//pragma solidity ^0.7.6;

contract WalletsToken is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool private swapping;
    // reflect
    address[] private _excluded;
    uint256 private _tFeeTotal;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000 * (10**18);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromFees[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    //
    uint256 public maxBuyTranscationAmount = 300000000 * (10**18);
    uint256 public maxSellTransactionAmount = 100000000000 * (10**18);
    uint256 public swapTokensAtAmount = 20000000 * (10**18);
    uint256 public _maxWalletToken = 1500000000 * (10**18); // 1.5% of total supply
    uint256 public lpLockTime;
    address public burnAddress;
    address payable public wallet1Address;
    address payable public wallet2Address;
    address payable public wallet3Address;
    address payable public wallet4Address;
    address payable public wallet5Address;
    // made private, team will be paid in BNB
    address private wallet1TokenAddressForFee;
    address private wallet2TokenAddressForFee;
    address private wallet3TokenAddressForFee;
    address private wallet4TokenAddressForFee;
    address private wallet5TokenAddressForFee;
    // Fees
    uint256 public wallet1Fee;
    uint256 public wallet2Fee;
    uint256 public wallet3Fee;
    uint256 public wallet4Fee;
    uint256 public wallet5Fee;
    uint256 public tokenRewardsFee;
    uint256 public liquidityFee;
    uint256 public totalAdminFees;
    // Previous Fees
    uint256 public prevWallet1Fee;
    uint256 public prevWallet2Fee;
    uint256 public prevWallet3Fee;
    uint256 public prevWallet4Fee;
    uint256 public prevWallet5Fee;
    uint256 public prevTokenRewardsFee;
    uint256 public prevLiquidityFee;
    uint256 public prevTotalAdminFees;
    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 public sellFeeIncreaseFactor = 130;
    address public presaleAddress = address(0);
    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 public tradingEnabledTimestamp = 1626399138;
    // blacklisted from all transfers
    mapping (address => bool) public _isBlacklisted;    
    // exlcude from fees and max transaction amount
    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxSellTransactionAmount;
    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BurnWalletUpdated(address indexed newBurnWallet, address indexed oldBurnWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);

    constructor() public ERC20("5WALLETS", "5WAL") {
        uint256 _tokenRewardsFee = 10;
        uint256 _liquidityFee = 5;
        uint256 _wallet1Fee = 1;
        uint256 _wallet2Fee = 1;
        uint256 _wallet3Fee = 1;
        uint256 _wallet4Fee = 1;
        uint256 _wallet5Fee = 1;
        uint256 _lpLockTime = 1626927347;

        tokenRewardsFee = _tokenRewardsFee;
        liquidityFee = _liquidityFee;
        wallet1Fee = _wallet1Fee;
        wallet2Fee = _wallet2Fee;
        wallet3Fee = _wallet3Fee;
        wallet4Fee = _wallet4Fee;
        wallet5Fee = _wallet5Fee;
        totalAdminFees = _wallet1Fee + _wallet2Fee + _wallet3Fee + _wallet4Fee + _wallet5Fee;
        lpLockTime = _lpLockTime;

        burnAddress = address(0xdead);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(burnAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;

        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }

    // receive BNB
    receive() external payable {}
    // admin actions
    function swapAndLiquifyOwner(uint256 _tokens) external onlyOwner {
        swapAndLiquify(_tokens);
    }
    function updatelpLockTime (uint256 newTimeInEpoch) external onlyOwner {
        lpLockTime = newTimeInEpoch;
    }       
    function withdrawLPTokens () external onlyOwner{
        require(block.timestamp > lpLockTime, 'Wait for LP locktime to expire!');
        uint256 currentBalance = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).transfer(owner(),currentBalance);
        
    }      
    function updateTradingEnabledTime (uint256 newTimeInEpoch) external onlyOwner {
        tradingEnabledTimestamp = newTimeInEpoch;
    }     
    function updateSellIncreaseFee (uint256 newFeeWholeNumber) external onlyOwner {
        sellFeeIncreaseFactor = newFeeWholeNumber;
    }
    function updateMaxWalletAmount(uint256 newAmountNoDecimials) external onlyOwner {
        _maxWalletToken = newAmountNoDecimials * (10**18);
    }     
    function updateSwapAtAmount(uint256 newAmountNoDecimials) external onlyOwner {
        swapTokensAtAmount = newAmountNoDecimials * (10**18);
    } 
    function updateWallet1Address(address payable newAddress) external onlyOwner {
        wallet1Address = newAddress;
        excludeFromFees(newAddress, true);  
    }    
    function updateWallet2Address(address payable newAddress) external onlyOwner {
        wallet2Address = newAddress;
        excludeFromFees(newAddress, true);  

    }       
    function updateWallet3Address(address payable newAddress) external onlyOwner {
        wallet3Address = newAddress;
        excludeFromFees(newAddress, true);
    }      
    function updateWallet4Address(address payable newAddress) external onlyOwner {
        wallet4Address = newAddress;
        excludeFromFees(newAddress, true);
    }      
    function updateWallet5Address(address payable newAddress) external onlyOwner {
        wallet5Address = newAddress;
        excludeFromFees(newAddress, true);
    }    
    function updateFees(uint256 _tokenRewardsFee, uint256 _liquidityFee, uint256 _wallet1Fee, uint256 _wallet2Fee, uint256 _wallet3Fee, uint256 _wallet4Fee, uint256 _wallet5Fee) external onlyOwner {
        tokenRewardsFee = _tokenRewardsFee;
        liquidityFee = _liquidityFee;
        wallet1Fee = _wallet1Fee;
        wallet2Fee = _wallet2Fee;
        wallet3Fee = _wallet3Fee;
        wallet3Fee = _wallet4Fee;
        wallet3Fee = _wallet5Fee;
        totalAdminFees = _liquidityFee.add(wallet1Fee).add(wallet2Fee).add(wallet3Fee).add(wallet4Fee).add(wallet5Fee);
    }
    function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
        presaleAddress = _presaleAddress;
        canTransferBeforeTradingIsEnabled[presaleAddress] = true;
        excludeFromFees(_presaleAddress, true);
        canTransferBeforeTradingIsEnabled[_routerAddress] = true;
        excludeFromFees(_routerAddress, true);
    }
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "5Wallets: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function excludeFromReward(address account) internal {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcludedFromFees[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromFees[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) internal {
        require(_isExcludedFromFees[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromFees[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        if(excluded){
            excludeFromReward(account);
        }else{
            includeInReward(account);
        }
        //emit ExcludeFromFees(account, excluded);
    }       
    function blacklistAddress(address account, bool excluded) public onlyOwner {
        _isBlacklisted[account] = excluded;
    }    
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "5Wallets: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "5Wallets: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }
    function removeAllFee() private {
    if(tokenRewardsFee == 0 && liquidityFee == 0) return;    
    prevWallet1Fee = wallet1Fee;
    prevWallet2Fee = wallet2Fee;
    prevWallet3Fee = wallet3Fee;
    prevWallet4Fee = wallet4Fee;
    prevWallet5Fee = wallet5Fee;
    prevTokenRewardsFee = tokenRewardsFee;
    prevLiquidityFee = liquidityFee;
    prevTotalAdminFees = totalAdminFees;
    wallet1Fee = 0;
    wallet2Fee = 0;
    wallet3Fee = 0;
    wallet4Fee = 0;
    wallet5Fee = 0;
    tokenRewardsFee = 0;
    liquidityFee = 0;
    totalAdminFees = 0;
    }
    function restoreAllFee() private {
    wallet1Fee = prevWallet1Fee;
    wallet2Fee = prevWallet2Fee;
    wallet3Fee = prevWallet3Fee;
    wallet4Fee = prevWallet4Fee;
    wallet5Fee = prevWallet5Fee;
    tokenRewardsFee = prevTokenRewardsFee;
    liquidityFee = prevLiquidityFee;
    totalAdminFees = prevTotalAdminFees;
    }
    // contract actions
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!_isBlacklisted[from], "Blacklisted address cannot transfer!");
        require(!_isBlacklisted[to], "Blacklisted address cannot transfer!");
        require(from != address(0), "ERC20: transfer to the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
            if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !automatedMarketMakerPairs[to] &&
            automatedMarketMakerPairs[from]
        ) {
            require(
                amount <= maxBuyTranscationAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            uint256 contractBalanceRecipient = balanceOf(to);
            require(
                contractBalanceRecipient + amount <= _maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
        }
        
        bool tradingIsEnabled = getTradingIsEnabled();

        // only whitelisted addresses can make transfers after the fixed-sale has started
        // and before the public presale is over
        if(!tradingIsEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "5Wallets: This account cannot send tokens until trading is enabled");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if( 
            !swapping &&
            tradingIsEnabled &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
            from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            tradingIsEnabled && 
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != burnAddress &&
            to != burnAddress
        ) {
            swapping = true;
            swapAndLiquify(swapTokensAtAmount);
            swapping = false;
        }


        bool takeFee = tradingIsEnabled && !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
/*
        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);

            // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }

            amount = amount.sub(fees);

            //super._transfer(from, address(this), fees);
            _tokenTransfer(from,address(this),fees,takeFee);
        }*/

       // super._transfer(from, to, amount);
       _tokenTransfer(from,to,amount,takeFee);

    }
    
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromFees[sender] && _isExcludedFromFees[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromFees[sender] && _isExcludedFromFees[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tAdminFees) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFees(tAdminFees);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _takeFees(uint256 tAdminFees) private {
        uint256 currentRate =  _getRate();
        uint256 rAdminFees = tAdminFees.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rAdminFees);
        if(_isExcludedFromFees[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tAdminFees);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeFees(tAdminFees);
        _reflectFee(rRewardFee, tRewardFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeFees(tAdminFees);
        _reflectFee(rRewardFee, tRewardFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeFees(tAdminFees);
       _reflectFee(rRewardFee, tRewardFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee) = _getRValues(tAmount, tRewardFee, _getRate());
        return (rAmount, rTransferAmount, rRewardFee, tTransferAmount, tRewardFee, tAdminFees);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tRewardFee = calculateTokenRewardFee(tAmount);
        uint256 tAdminFees = calculateAdminFees(tAmount);
        uint256 tTransferAmount = tAmount.sub(tRewardFee).sub(tAdminFees);
        return (tTransferAmount, tRewardFee, tAdminFees);
    }
    function calculateTokenRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(tokenRewardsFee).div(10**2);
    }
    function calculateAdminFees(uint256 _amount) private view returns (uint256) {
        return _amount.mul(totalAdminFees).div(10**2);
    }
    function _getRValues(uint256 tAmount, uint256 tRewardFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRewardFee = tRewardFee.mul(currentRate);
        //uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRewardFee);
        return (rAmount, rTransferAmount, rRewardFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    

    function swapHandler(address payable walletAddress, address tokenAddressForFee, uint256 feeBalance, uint256 feePortion) internal {
        if(tokenAddressForFee != address(0)){
            swapEthForTokens(feeBalance, tokenAddressForFee, walletAddress);
            //_transfer(address(this), burnAddress, wallet1feePortion);
            //emit Transfer(address(this), burnAddress, wallet1feePortion);
        }else{
            (bool sent,) = walletAddress.call{value: feeBalance}("");
            if(sent){
                //_transfer(address(this), burnAddress, wallet1feePortion);
                //emit Transfer(address(this), burnAddress, wallet1feePortion);
            } else {
                addLiquidity(feePortion, feeBalance);
            }
        }   
    }
    function portionCalculatorOne(uint256 _wallet1Fee, uint256 _otherHalf, uint256 _newBalance) internal returns (uint256,uint256){
        // calculate the portions of the liquidity to add to wallet3fee
        uint256 wallet1feeBalance = _newBalance.div(totalAdminFees).mul(_wallet1Fee);
        uint256 wallet1feePortion = _otherHalf.div(totalAdminFees).mul(_wallet1Fee);        
        return (wallet1feeBalance,wallet1feePortion);
    }    
    
    function portionCalculatorTwo(uint256 _wallet2Fee, uint256 _otherHalf, uint256 _newBalance) internal returns (uint256,uint256){
        // calculate the portions of the liquidity to add to wallet3fee
        uint256 wallet2feeBalance = _newBalance.div(totalAdminFees).mul(_wallet2Fee);
        uint256 wallet2feePortion = _otherHalf.div(totalAdminFees).mul(_wallet2Fee);        
        return (wallet2feeBalance,wallet2feePortion);
    }      
    
    function portionCalculatorThree(uint256 _wallet3Fee, uint256 _otherHalf, uint256 _newBalance) internal returns (uint256,uint256){
        // calculate the portions of the liquidity to add to wallet3fee
        uint256 wallet3feeBalance = _newBalance.div(totalAdminFees).mul(_wallet3Fee);
        uint256 wallet3feePortion = _otherHalf.div(totalAdminFees).mul(_wallet3Fee);        
        return (wallet3feeBalance,wallet3feePortion);
    }        
    
    function portionCalculatorFour(uint256 _wallet4Fee, uint256 _otherHalf, uint256 _newBalance) internal returns (uint256,uint256){
        // calculate the portions of the liquidity to add to wallet3fee
        uint256 wallet4feeBalance = _newBalance.div(totalAdminFees).mul(_wallet4Fee);
        uint256 wallet4feePortion = _otherHalf.div(totalAdminFees).mul(_wallet4Fee);        
        return (wallet4feeBalance,wallet4feePortion);
    }         
    
    function portionCalculatorFive(uint256 _wallet5Fee, uint256 _otherHalf, uint256 _newBalance) internal returns (uint256,uint256){
        // calculate the portions of the liquidity to add to wallet3fee
        uint256 wallet5feeBalance = _newBalance.div(totalAdminFees).mul(_wallet5Fee);
        uint256 wallet5feePortion = _otherHalf.div(totalAdminFees).mul(_wallet5Fee);        
        return (wallet5feeBalance,wallet5feePortion);
    }

    function feeBalanceHandler(uint256 _wallet1Fee, uint256 _wallet2Fee,uint256 _wallet3Fee,uint256 _wallet4Fee,uint256 _wallet5Fee, uint256 _otherHalf, uint256 _newBalance) internal returns(uint256, uint256){
        (uint256 wallet1feeBalance,uint256 wallet1feePortion) = portionCalculatorOne(_wallet1Fee,_otherHalf,_newBalance);
        (uint256 wallet2feeBalance,uint256 wallet2feePortion) = portionCalculatorOne(_wallet2Fee,_otherHalf,_newBalance);
        (uint256 wallet3feeBalance,uint256 wallet3feePortion) = portionCalculatorOne(_wallet3Fee,_otherHalf,_newBalance);
        (uint256 wallet4feeBalance,uint256 wallet4feePortion) = portionCalculatorOne(_wallet4Fee,_otherHalf,_newBalance);
        (uint256 wallet5feeBalance,uint256 wallet5feePortion) = portionCalculatorOne(_wallet5Fee,_otherHalf,_newBalance);
        uint256 walletTotalBalance = wallet1feeBalance + wallet2feeBalance + wallet3feeBalance + wallet4feeBalance + wallet5feeBalance;
        uint256 walletTotalPortion = wallet1feePortion + wallet2feePortion + wallet3feePortion + wallet4feePortion + wallet5feePortion;
        allWalletSwapOne(wallet1feeBalance,wallet1feePortion,wallet2feeBalance,wallet2feePortion,wallet3feeBalance,wallet3feePortion);
        allWalletSwapTwo(wallet4feeBalance,wallet4feePortion,wallet5feeBalance,wallet5feePortion);
        return(walletTotalBalance,walletTotalPortion);
    }
    function finalCalculator(uint256 _wallet1Fee, uint256 _wallet2Fee,uint256 _wallet3Fee,uint256 _wallet4Fee,uint256 _wallet5Fee, uint256 _otherHalf, uint256 _newBalance) internal{
        (uint256 walletTotalBalance, uint256 walletTotalPortion) = feeBalanceHandler(_wallet1Fee,_wallet2Fee,_wallet3Fee,_wallet4Fee,_wallet5Fee,_otherHalf,_newBalance);
        uint256 finalBalance = _newBalance - walletTotalBalance;
        uint256 finalHalf = _otherHalf - walletTotalPortion;
        // add liquidity to uniswap
        addLiquidity(finalHalf, finalBalance);
    }    
    
    function allWalletSwapOne(uint256 wallet1feeBalance, uint256 wallet1feePortion,uint256 wallet2feeBalance, uint256 wallet2feePortion,uint256 wallet3feeBalance, uint256 wallet3feePortion) internal{
        // added to manage receiving bnb
        swapHandler(wallet1Address, wallet1TokenAddressForFee, wallet1feeBalance, wallet1feePortion);         
        swapHandler(wallet2Address, wallet2TokenAddressForFee, wallet2feeBalance, wallet2feePortion);       
        swapHandler(wallet3Address, wallet3TokenAddressForFee, wallet3feeBalance, wallet3feePortion);     
    }    
    
    function allWalletSwapTwo(uint256 wallet4feeBalance, uint256 wallet4feePortion,uint256 wallet5feeBalance, uint256 wallet5feePortion) internal{
        // added to manage receiving bnb
        swapHandler(wallet4Address, wallet4TokenAddressForFee, wallet4feeBalance, wallet4feePortion);       
        swapHandler(wallet5Address, wallet5TokenAddressForFee, wallet5feeBalance, wallet5feePortion);  
    }
    
    function swapAndLiquify(uint256 tokens) internal  {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        // calculate the portions of the liquidity to add to wallet1fee
        // calculate finals
        finalCalculator(wallet1Fee,wallet2Fee,wallet3Fee,wallet4Fee,wallet5Fee,otherHalf,newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    // added in order to sell eth for something else like usdt,busd,etc
    function swapEthForTokens(uint256 ethAmount, address tokenAddress, address receiver) private {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;
        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of ETH
            path,
            receiver,
            block.timestamp
        );
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        ); 
    }
}

