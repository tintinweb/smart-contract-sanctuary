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

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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

import "./IERC20.sol";

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

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.0;

interface IPancakeFactory {
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

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.0;

interface IPancakePair {
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

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./IPancakeRouter01.sol";
import "./IPancakeRouter02.sol";

/**
 * @title BEP20Token
 * @author AmberSoft (visit https://ambersoft.llc)
 *
 * @dev Mintable BEP20 token with burning and optional functions implemented.
 * Any address with minter role can mint new tokens.
 * For full specification of ERC-20 standard see:
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract XposeProtocol is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address public immutable WETH;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    IPancakeRouter02 public immutable pancakeswapV2Router;
    address public immutable pancakeswapV2Pair;

    // Fees
    uint256 public _liquidityPoolFee = 50;
    uint256 public _marketingPoolFee = 40;
    uint256 public _burnFee = 5;
    uint256 public _communityRewardPoolFee = 5;

    // Main fee
    uint256 public _commonFee = 5;
    uint256 private _maxCommonFee = 5;
    uint256 public _specialFee = 10;
    uint256 private _maxSpecialFee = 10;

    // Vote config
    uint256 private _minAcceptedVotes = 3;
    uint256 private _minDeclinedVotes = 3;

    // Fee votes
    uint256 public _votedCommonFee;
    bool public _inVoteCommonFee = false;
    mapping(address => bool) public _votesCommonFee;
    address[] public _votedCommonFeeWallets;
    uint256 public _currentOffsetVoteCommonFee = 0;

    uint256 public _votedSpecialFee;
    bool public _inVoteSpecialFee = false;
    mapping(address => bool) public _votesSpecialFee;
    address[] public _votedSpecialFeeWallets;
    uint256 public _currentOffsetVoteSpecialFee = 0;

    // Pools votes
    address payable public _votedMarketingPoolWallet;
    bool public _inVoteMarketingPoolWallet = false;
    mapping(address => bool) public _votesMarketingPoolWallet;
    address[] public _votedMarketingPoolWalletWallets;
    uint256 public _currentOffsetVoteMarketingPoolWallet = 0;

    address payable public _votedCommunityRewardPoolWallet;
    bool public _inVoteCommunityRewardPoolWallet = false;
    mapping(address => bool) public _votesCommunityRewardPoolWallet;
    address[] public _votedCommunityRewardPoolWalletWallets;
    uint256 public _currentOffsetVoteCommunityRewardPoolWallet = 0;

    // Sent to pools on transaction
    bool public _swapOnTransaction = true;

    bool public _swapOnCommunity = true;
    bool public _swapOnMarketing = true;
    bool public _swapOnLiquidity = true;

    // Trigger amount to auto swap
    uint256 public _liquidityTriggerAmount = 5 * 10 ** 14; // = 500,000 tokens
    uint256 public _marketingTriggerAmount = 5 * 10 ** 14; // = 500,000 tokens
    uint256 public _communityTriggerAmount = 5 * 10 ** 14; // = 500,000 tokens

    // Current amount to swap
    uint256 public _currentLiquidityTriggerAmount = 0;
    uint256 public _currentMarketingTriggerAmount = 0;
    uint256 public _currentCommunityTriggerAmount = 0;

    // Total amount
    uint256 public _totalLiquidityTriggerAmount = 0;
    uint256 public _totalMarketingTriggerAmount = 0;
    uint256 public _totalCommunityTriggerAmount = 0;

    // Multisig wallets
    mapping(address => bool) private _multisigWallets;

    // Excluded from fee
    mapping(address => bool) private _excludedFromFee;

    // Special addresses
    mapping(address => bool) private _includedInSpecialFee;

    // Pools addresses
    address payable private _marketingPoolWallet;
    address payable private _communityRewardPoolWallet;

    // Delayed Team Reward
    address private immutable _teamWallet;
    uint256 public immutable _timeToReleaseFirstStep;
    uint256 public immutable _timeToReleaseSecondStep;
    uint256 public immutable _lockedTokensForTeam;
    uint256 public _percentFromSupplyForTeam = 15;
    uint256 public immutable _percentReleaseFirstStep = 60;
    uint256 public immutable _percentReleaseSecondStep = 40;

    bool inSwapAndLiquify;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    bool inSwapAndCommunity;

    modifier lockTheSwapCommunity {
        inSwapAndCommunity = true;
        _;
        inSwapAndCommunity = false;
    }

    event SwapAndCommunity(
        uint256 tokensSwapped,
        uint256 ethReceived
    );
    
    bool inSwapAndMarketing;

    modifier lockTheSwapMarketing {
        inSwapAndMarketing = true;
        _;
        inSwapAndMarketing = false;
    }

    event SwapAndMarketing(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    constructor(
        string memory contractName,
        string memory contractSymbol,
        uint8 contractDecimals,
        uint256 initialSupply,
        address payable initialMarketingPoolWallet,
        address payable initialCommunityRewardPoolWallet,
        address routerAddress, // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 - test, 0x10ED43C718714eb63d5aA57B78B54704E256024E - main
        address contractTeamWallet
    ) public payable {
        require(initialMarketingPoolWallet != address(0), "Marketing pool wallet can't be 0");
        require(initialCommunityRewardPoolWallet != address(0), "Community Reward pool wallet can't be 0");
        require(contractTeamWallet != address(0), "Team wallet can't be 0");
        require(initialSupply >= 1000000000000000000, "Initial supply can't be less than 1000000000000000000");

        _name = contractName;
        _symbol = contractSymbol;
        _decimals = contractDecimals;
        _communityRewardPoolWallet = initialCommunityRewardPoolWallet;
        _marketingPoolWallet = initialMarketingPoolWallet;

        // Initiate multisig wallets @TODO change wallets
        _multisigWallets[0xB6FA2fA21C9fdBe4C83CCa147bDe8d73439cDb62] = true;
        _multisigWallets[0xed8004888E6A84731e8fB3E26d899b18b7EA3aE9] = true;
        _multisigWallets[0x0E665191Bd0791Fa47644D62196e2727c9a8Ab0F] = true;
        _multisigWallets[0xD1D9B3399840846F302Df0f904EC977b3AEbd7c6 ] = true;
        _multisigWallets[0xc8BB3909dF983B5a9634D1C8B0c89Cc6551D84c6] = true;

        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(routerAddress);
        WETH = _pancakeswapV2Router.WETH();

        // Create a Pancake pair for this new token
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;

        excludeFromFee(address(this));
        excludeFromFee(_msgSender());
        excludeFromFee(routerAddress);

        _teamWallet = contractTeamWallet;
        _lockedTokensForTeam = (initialSupply.mul(_percentFromSupplyForTeam)).div(100);
        _timeToReleaseFirstStep = block.timestamp + 243 days;
        _timeToReleaseSecondStep = block.timestamp + 365 days;
        // set tokenOwnerAddress as owner of initial supply, more tokens can be minted later
        _mint(_msgSender(), initialSupply.sub((initialSupply.mul(_percentFromSupplyForTeam)).div(100)));
    }

    function releaseTeamFirstStep() external {
        require(block.timestamp >= _timeToReleaseFirstStep, "It's not time yet");

        uint256 releaseAmount = (_lockedTokensForTeam.mul(_percentReleaseFirstStep)).div(100);
        _mint(_teamWallet, releaseAmount);
    }

    function releaseTeamSecondStep() external {
        require(block.timestamp >= _timeToReleaseSecondStep, "It's not time yet");

        uint256 releaseAmount = (_lockedTokensForTeam.mul(_percentReleaseSecondStep)).div(100);
        _mint(_teamWallet, releaseAmount);
    }

    // Vote methods

    // Common Fee
    function startVoteForCommonFee(uint256 newCommonFee) external {
        require(_multisigWallets[_msgSender()], "Only multisig wallets can start vote");
        require(!_inVoteCommonFee, "Vote is already started");
        require(newCommonFee <= 5, "Maximum fee is 5");

        _inVoteCommonFee = true;
        _votedCommonFee = newCommonFee;
        _votesCommonFee[_msgSender()] = true;
        _votedCommonFeeWallets.push(_msgSender());
    }

    function voteForCommonFee(bool vote) external {
        require(_multisigWallets[_msgSender()], "Only multisig wallets can voting");
        require(_inVoteCommonFee, "Voting hasn't started");

        bool isInVote = false;
        for (uint i = _currentOffsetVoteCommonFee; i < _votedCommonFeeWallets.length; i++) {
            if(_votedCommonFeeWallets[i] == _msgSender()) {
                isInVote = true;
            }
        }
        require(!isInVote, "You can vote only once");

        _votesCommonFee[_msgSender()] = vote;
        _votedCommonFeeWallets.push(_msgSender());

        uint8 currentVoteStatus = checkVotingCommonFee();
        if(currentVoteStatus < 2) {
            endCommonFeeVote(currentVoteStatus == 1);
        }
    }

    function checkVotingCommonFee() internal returns (uint8) {
        uint256 acceptedVotes = 0;
        uint256 declinedVotes = 0;

        for (uint i = _currentOffsetVoteCommonFee; i < _votedCommonFeeWallets.length; i++) {
            address voteWallet = _votedCommonFeeWallets[i];
            if (_votesCommonFee[voteWallet]) {
                acceptedVotes = acceptedVotes.add(1);
            } else {
                declinedVotes = declinedVotes.add(1);
            }
        }

        if (acceptedVotes >= _minAcceptedVotes) {
            return 1;
        }

        if (declinedVotes >= _minDeclinedVotes) {
            return 0;
        }

        return 2;
    }

    function endCommonFeeVote(bool decision) internal {
        if(decision) {
            _commonFee = _votedCommonFee;
        }

        // set to default
        _votedCommonFee = 0;
        _inVoteCommonFee = false;
        for (uint i = _currentOffsetVoteCommonFee; i < _votedCommonFeeWallets.length; i++) {
            address voteWallet = _votedCommonFeeWallets[i];
            delete _votesCommonFee[voteWallet];
            delete _votedCommonFeeWallets[i];
        }
        _currentOffsetVoteCommonFee = _votedCommonFeeWallets.length;
    }

    // Special fee
    function startVoteForSpecialFee(uint256 newSpecialFee) external {
        require(_multisigWallets[_msgSender()], "Only multisig wallets can start vote");
        require(!_inVoteSpecialFee, "Vote is already started");
        require(newSpecialFee <= 10, "Maximum fee is 10");

        _inVoteSpecialFee = true;
        _votedSpecialFee = newSpecialFee;
        _votesSpecialFee[_msgSender()] = true;
        _votedSpecialFeeWallets.push(_msgSender());
    }

    function voteForSpecialFee(bool vote) external {
        require(_multisigWallets[_msgSender()], "Only multisig wallets can voting");
        require(_inVoteSpecialFee, "Voting hasn't started");

        bool isInVote = false;
        for (uint i = _currentOffsetVoteSpecialFee; i < _votedSpecialFeeWallets.length; i++) {
            if(_votedSpecialFeeWallets[i] == _msgSender()) {
                isInVote = true;
            }
        }
        require(!isInVote, "You can vote only once");

        _votesSpecialFee[_msgSender()] = vote;
        _votedSpecialFeeWallets.push(_msgSender());

        uint8 currentVoteStatus = checkVotingSpecialFee();
        if(currentVoteStatus < 2) {
            endSpecialFeeVote(currentVoteStatus == 1);
        }
    }

    function checkVotingSpecialFee() internal returns (uint8) {
        uint256 acceptedVotes = 0;
        uint256 declinedVotes = 0;

        for (uint i = _currentOffsetVoteSpecialFee; i < _votedSpecialFeeWallets.length; i++) {
            address voteWallet = _votedSpecialFeeWallets[i];
            if (_votesSpecialFee[voteWallet]) {
                acceptedVotes = acceptedVotes.add(1);
            } else {
                declinedVotes = declinedVotes.add(1);
            }
        }

        if (acceptedVotes >= _minAcceptedVotes) {
            return 1;
        }

        if (declinedVotes >= _minDeclinedVotes) {
            return 0;
        }

        return 2;
    }

    function endSpecialFeeVote(bool decision) internal {
        if(decision) {
            _specialFee = _votedSpecialFee;
        }

        // set to default
        _votedSpecialFee = 0;
        _inVoteSpecialFee = false;
        for (uint i = _currentOffsetVoteSpecialFee; i < _votedSpecialFeeWallets.length; i++) {
            address voteWallet = _votedSpecialFeeWallets[i];
            delete _votesSpecialFee[voteWallet];
            delete _votedSpecialFeeWallets[i];
        }
        _currentOffsetVoteSpecialFee = _votedSpecialFeeWallets.length;
    }
    
    // Marketing wallet
    function startVoteForMarketingPoolWallet(address payable newMarketingPoolWallet) external {
        require(newMarketingPoolWallet != address(0), "Marketing pool wallet can't be 0");
        require(_multisigWallets[_msgSender()], "Only multisig wallets can start vote");
        require(!_inVoteMarketingPoolWallet, "Vote is already started");

        _inVoteMarketingPoolWallet = true;
        _votedMarketingPoolWallet = newMarketingPoolWallet;
        _votesMarketingPoolWallet[_msgSender()] = true;
        _votedMarketingPoolWalletWallets.push(_msgSender());
    }

    function voteForMarketingPoolWallet(bool vote) external {
        require(_multisigWallets[_msgSender()], "Only multisig wallets can voting");
        require(_inVoteMarketingPoolWallet, "Voting hasn't started");

        bool isInVote = false;
        for (uint i = _currentOffsetVoteMarketingPoolWallet; i < _votedMarketingPoolWalletWallets.length; i++) {
            if(_votedMarketingPoolWalletWallets[i] == _msgSender()) {
                isInVote = true;
            }
        }
        require(!isInVote, "You can vote only once");

        _votesMarketingPoolWallet[_msgSender()] = vote;
        _votedMarketingPoolWalletWallets.push(_msgSender());

        uint8 currentVoteStatus = checkVotingMarketingPoolWallet();
        if(currentVoteStatus < 2) {
            endMarketingPoolWalletVote(currentVoteStatus == 1);
        }
    }

    function checkVotingMarketingPoolWallet() internal returns (uint8) {
        uint256 acceptedVotes = 0;
        uint256 declinedVotes = 0;

        for (uint i = _currentOffsetVoteMarketingPoolWallet; i < _votedMarketingPoolWalletWallets.length; i++) {
            address voteWallet = _votedMarketingPoolWalletWallets[i];
            if (_votesMarketingPoolWallet[voteWallet]) {
                acceptedVotes = acceptedVotes.add(1);
            } else {
                declinedVotes = declinedVotes.add(1);
            }
        }

        if (acceptedVotes >= _minAcceptedVotes) {
            return 1;
        }

        if (declinedVotes >= _minDeclinedVotes) {
            return 0;
        }

        return 2;
    }

    function endMarketingPoolWalletVote(bool decision) internal {
        if(decision) {
            _marketingPoolWallet = _votedMarketingPoolWallet;
        }

        // set to default
        _inVoteMarketingPoolWallet = false;
        for (uint i = _currentOffsetVoteMarketingPoolWallet; i < _votedMarketingPoolWalletWallets.length; i++) {
            address voteWallet = _votedMarketingPoolWalletWallets[i];
            delete _votesMarketingPoolWallet[voteWallet];
            delete _votedMarketingPoolWalletWallets[i];
        }

        _currentOffsetVoteMarketingPoolWallet = _votedMarketingPoolWalletWallets.length;
    }
    
    // Community reward wallet
    function startVoteForCommunityRewardPoolWallet(address payable newCommunityRewardPoolWallet) external {
        require(newCommunityRewardPoolWallet != address(0), "Community reward pool wallet can't be 0");
        require(_multisigWallets[_msgSender()], "Only multisig wallets can start vote");
        require(!_inVoteCommunityRewardPoolWallet, "Vote is already started");

        _inVoteCommunityRewardPoolWallet = true;
        _votedCommunityRewardPoolWallet = newCommunityRewardPoolWallet;
        _votesCommunityRewardPoolWallet[_msgSender()] = true;
        _votedCommunityRewardPoolWalletWallets.push(_msgSender());
    }

    function voteForCommunityRewardPoolWallet(bool vote) external {
        require(_multisigWallets[_msgSender()], "Only multisig wallets can voting");
        require(_inVoteCommunityRewardPoolWallet, "Voting hasn't started");

        bool isInVote = false;
        for (uint i = _currentOffsetVoteCommunityRewardPoolWallet; i < _votedCommunityRewardPoolWalletWallets.length; i++) {
            if(_votedCommunityRewardPoolWalletWallets[i] == _msgSender()) {
                isInVote = true;
            }
        }
        require(!isInVote, "You can vote only once");

        _votesCommunityRewardPoolWallet[_msgSender()] = vote;
        _votedCommunityRewardPoolWalletWallets.push(_msgSender());

        uint8 currentVoteStatus = checkVotingCommunityRewardPoolWallet();
        if(currentVoteStatus < 2) {
            endCommunityRewardPoolWalletVote(currentVoteStatus == 1);
        }
    }

    function checkVotingCommunityRewardPoolWallet() internal returns (uint8) {
        uint256 acceptedVotes = 0;
        uint256 declinedVotes = 0;

        for (uint i = _currentOffsetVoteCommunityRewardPoolWallet; i < _votedCommunityRewardPoolWalletWallets.length; i++) {
            address voteWallet = _votedCommunityRewardPoolWalletWallets[i];
            if (_votesCommunityRewardPoolWallet[voteWallet]) {
                acceptedVotes = acceptedVotes.add(1);
            } else {
                declinedVotes = declinedVotes.add(1);
            }
        }

        if (acceptedVotes >= _minAcceptedVotes) {
            return 1;
        }

        if (declinedVotes >= _minDeclinedVotes) {
            return 0;
        }

        return 2;
    }

    function endCommunityRewardPoolWalletVote(bool decision) internal {
        if(decision) {
            _communityRewardPoolWallet = _votedCommunityRewardPoolWallet;
        }

        // set to default
        _inVoteCommunityRewardPoolWallet = false;
        for (uint i = _currentOffsetVoteCommunityRewardPoolWallet; i < _votedCommunityRewardPoolWalletWallets.length; i++) {
            address voteWallet = _votedCommunityRewardPoolWalletWallets[i];
            delete _votesCommunityRewardPoolWallet[voteWallet];
            delete _votedCommunityRewardPoolWalletWallets[i];
        }

        _currentOffsetVoteCommunityRewardPoolWallet = _votedCommunityRewardPoolWalletWallets.length;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        uint256 totalSendAmount = amount;

        // Only if address is not excluded from fee
        if(!isExcludedFromFee(_msgSender())) {
            uint256 feeAmount = 0;
            if(isIncludedInSpecialFee(_msgSender())) {
                // Special fee
                feeAmount = (totalSendAmount.mul(_specialFee)).div(100);
            } else {
                // Common fee
                feeAmount = (totalSendAmount.mul(_commonFee)).div(100);
            }
            uint256 liquidityPoolAmount = (feeAmount.mul(_liquidityPoolFee)).div(100);
            uint256 marketingPoolAmount = (feeAmount.mul(_marketingPoolFee)).div(100);
            uint256 burnAmount = (feeAmount.mul(_burnFee)).div(100);
            uint256 communityRewardPoolAmount = (feeAmount.mul(_communityRewardPoolFee)).div(100);

            totalSendAmount = totalSendAmount
                .sub(liquidityPoolAmount)
                .sub(marketingPoolAmount)
                .sub(burnAmount)
                .sub(communityRewardPoolAmount);

            _balances[address(this)] = _balances[address(this)]
                .add(liquidityPoolAmount)
                .add(marketingPoolAmount)
                .add(burnAmount)
                .add(communityRewardPoolAmount);

            // Burn
            _burn(address(this), burnAmount);
            
            // Community Reward Pool
            _currentCommunityTriggerAmount = _currentCommunityTriggerAmount.add(communityRewardPoolAmount);
            _totalCommunityTriggerAmount = _totalCommunityTriggerAmount.add(communityRewardPoolAmount);
            
            // Marketing Pool
            _currentMarketingTriggerAmount = _currentMarketingTriggerAmount.add(marketingPoolAmount);
            _totalMarketingTriggerAmount = _totalMarketingTriggerAmount.add(marketingPoolAmount);
            
            // Liquidity Pool
            _currentLiquidityTriggerAmount = _currentLiquidityTriggerAmount.add(liquidityPoolAmount);
            _totalLiquidityTriggerAmount = _totalLiquidityTriggerAmount.add(liquidityPoolAmount);
            
            if(
                _swapOnTransaction &&
                sender != pancakeswapV2Pair
            ) {
                if(_currentCommunityTriggerAmount >= _communityTriggerAmount && !inSwapAndCommunity && _swapOnCommunity) {
                    swapAndCommunity(_currentCommunityTriggerAmount);
                    _currentCommunityTriggerAmount = 0;
                }
                
                if(_currentMarketingTriggerAmount >= _marketingTriggerAmount && !inSwapAndMarketing && _swapOnMarketing) {
                    swapAndMarketing(_currentMarketingTriggerAmount);
                    _currentMarketingTriggerAmount = 0;                    
                }
                
                if(_currentLiquidityTriggerAmount >= _liquidityTriggerAmount && !inSwapAndLiquify && _swapOnLiquidity) {
                    swapAndLiquify(_currentLiquidityTriggerAmount);
                    _currentLiquidityTriggerAmount = 0;
                }
            }
        }

        _balances[recipient] = _balances[recipient].add(totalSendAmount);
        emit Transfer(sender, recipient, amount);
    }

    // to recieve ETH from pancakeswapV2Router when swaping
    receive() external payable {}

    /**
    * Evaluates whether address is a contract and exists.
    */
    function isContract(address addr) view private returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

    function swapAndCommunity(uint256 amount) internal lockTheSwapCommunity {
        // capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(amount);

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Send
        if (_communityRewardPoolWallet.send(newBalance))
        {
            emit SwapAndCommunity(amount, newBalance);
        }
        else
        {
            revert();
        }
    }
    
    function swapAndMarketing(uint256 amount) internal lockTheSwapMarketing {
        // capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(amount);

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Send
        if ( _marketingPoolWallet.send(newBalance) )
        {
            emit SwapAndMarketing(amount, newBalance);
        }
        else
        {
            revert();
        }
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        //ETH
        uint256 otherHalf = contractTokenBalance.sub(half);
        //BNB

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);
        // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to Pancake
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function setFees(uint256 liquidityPoolFee,uint256 marketingPoolFee,uint256 burnFee,uint256 communityRewardPoolFee) public onlyOwner {
        uint256 totalFees = liquidityPoolFee.add(marketingPoolFee).add(burnFee).add(communityRewardPoolFee);
        require(totalFees == 100, "BEP20: Sum of fees must be 100.");

        _liquidityPoolFee = liquidityPoolFee;
        _marketingPoolFee = marketingPoolFee;
        _burnFee = burnFee;
        _communityRewardPoolFee = communityRewardPoolFee;
    }

    function setSwapOnTransaction(bool swapOnTransaction) public onlyOwner {
        _swapOnTransaction = swapOnTransaction;
    }

    function setSwapOnValues(bool swapOnCommunity, bool swapOnMarketing, bool swapOnLiquidity) public onlyOwner {
        _swapOnCommunity = swapOnCommunity;
        _swapOnMarketing = swapOnMarketing;
        _swapOnLiquidity = swapOnLiquidity;
    }

    function setTriggerAmounts(uint256 liquidityTriggerAmount, uint256 marketingTriggerAmount, uint256 communityTriggerAmount) public onlyOwner {
        _liquidityTriggerAmount = liquidityTriggerAmount;
        _marketingTriggerAmount = marketingTriggerAmount;
        _communityTriggerAmount = communityTriggerAmount;
    }

    function excludeFromFee(address account) public onlyOwner {
        _excludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _excludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _excludedFromFee[account];
    }

    // special fee methods
    function includeInSpecialFee(address account) public onlyOwner {
        _includedInSpecialFee[account] = true;
    }

    function excludeFromSpecialFee(address account) public onlyOwner {
        _includedInSpecialFee[account] = false;
    }

    function isIncludedInSpecialFee(address account) public view returns (bool) {
        return _includedInSpecialFee[account];
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
     * Ether and Wei. This is the value {BEP20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
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
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
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
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
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
     * problems described in {IBEP20-approve}.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
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
        require(account != address(0), "BEP20: mint to the zero address");

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
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

