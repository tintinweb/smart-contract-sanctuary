/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;

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


pragma solidity 0.7.6;

interface KommunitasStakingV2{
    function getUserStakedTokens(address _of) external view returns (uint256);
    function getTotalStakedAmountBeforeDate(uint256 _before) external view returns(uint256 totalStaked);
    function getUserStakedTokensBeforeDate(address _of, uint256 _before) external view returns (uint256);
}


pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

pragma solidity 0.7.6;

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


pragma solidity 0.7.6;

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


pragma solidity 0.7.6;

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // Less efficient than the CREATE2 method below
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IUniswapV2Factory(factory).getPair(token0, token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}


contract KommunitasProject{
    using SafeMath for uint;
    
    bool public initialized;
    
    address public owner;
    address public factory;
    IUniswapV2Factory public swapFactory;
    address weth;
    
    address public devAddr;
    uint public revenue;
    
    ERC20 public currency;
    ERC20 public tokenProject;
    KommunitasStakingV2 public staking;
    uint public target;
    uint public sale;
    bool public buyEnded;
    bool public vestingEnded;
    uint public vestingMonth;
    uint public minPublicBuy;
    uint public maxPublicBuy;
    uint public boosterProgress;
    uint public vestingProgress;
    uint public fee;
    uint public tge; // Token Generation Event
    address public tokenLeftReceiver;
    address[] public buyers;
    
    uint public constant BOOSTER_RUNNING = 604800; // 7 days
    uint public constant BOOSTER_DELAY = 172800; // 2 days
    uint public constant VESTING_DELAY = 2592000; // 30 days
    
    struct Round{
        uint start;
        uint end;
        uint price;
    }
    
    struct Invoice{
        uint buyersIndex;
        uint boosterId;
        uint amount;
    }
    
    struct Summary{
        uint buyersIndex;
        uint vestingStep;
        uint purchase;
        uint vestingAmount;
        uint claimable;
        bool claimed;
    }
    struct VestingPeriod{
        uint start;
        uint end;
    }
    
    mapping(address => Invoice[]) public invoices;
    mapping(address => Summary) public summaries;
    mapping(uint => Round) public booster;
    mapping(address => bool) public permitToken;
    mapping(uint => VestingPeriod) public vesting;
    
    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    modifier onlyFactory{
        require(msg.sender == factory, "You are not the factory");
        _;
    }
    
    modifier isInitialized{
        require(!initialized, "Already initialized");
        _;
    }
    
    modifier isBuyNotEnded{
        require(!buyEnded, "This project is ended");
        _;
    }
    
    modifier isBoosterProgress{
        require(block.timestamp >= booster[boosterProgress].start && block.timestamp <= booster[boosterProgress].end, "Not in any booster progress");
        _;
    }
    
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }
    
    modifier everBought{
        require(invoices[msg.sender].length > 0, "User buy nothing");
        _;
    }
    
    event TokenBought(uint indexed booster, address indexed buyer, uint buyAmount, uint tokenReceived);
    event TokenClaimed(address indexed buyer, uint vestingAmount, uint claimMade, bool claimedAll);
    
    constructor(){
        factory = msg.sender;
        initialized = false;
        buyEnded = false;
        vestingEnded = false;
    }
    
    function initialize(
        KommunitasStakingV2 _staking,
        address _devAddr,
        IUniswapV2Factory _swapFactory,
        address _weth,
        ERC20 _currency,
        ERC20 _tokenProject,
        uint _sale,
        uint _target,
        uint[3] memory _price,
        uint _vestingMonth,
        uint[2] memory _minMaxPublicBuy,
        uint _fee,
        uint _tge,
        address _tokenLeftReceiver
    ) public onlyFactory isInitialized{
        require(_vestingMonth >= 3 && _vestingMonth <= 10, "Vesting must be between 3-10 months");
        initialized = true;
        
        staking = _staking;
        
        devAddr = _devAddr;
        owner = devAddr;
        swapFactory = _swapFactory;
        weth = _weth;
        
        currency = _currency;
        tokenProject = _tokenProject;
        sale = _sale;
        target = _target;
        for(uint i=0; i<3; i++){
            if(i==0){
                booster[i].start = block.timestamp;
            }else{
                booster[i].start = booster[i-1].end + BOOSTER_DELAY;
            }
            booster[i].end = booster[i].start + BOOSTER_RUNNING;
            booster[i].price = _price[i].mul(currency.decimals()).div(1e6);
        }
        
        require(_tge > booster[2].end, "Token Generation Event must be started after public round ended");
        tge = _tge;
        
        vestingMonth = _vestingMonth;
        for(uint i=0; i<vestingMonth; i++){
            if(i==0){
                vesting[i].start = tge;
            }else{
                vesting[i].start = vesting[i-1].end.add(1);
            }
            vesting[i].end = vesting[i].start + VESTING_DELAY;
        }
        
        minPublicBuy = _minMaxPublicBuy[0].mul(currency.decimals()).div(1e6);
        maxPublicBuy = _minMaxPublicBuy[1].mul(currency.decimals()).div(1e6);
        fee = _fee;
        
        tokenLeftReceiver = _tokenLeftReceiver;
    }
    
    // **** VIEW AREA ****
    
    function updateProject() public{
        if(!vestingEnded){
            if(block.timestamp > booster[2].end){
                if(!buyEnded){
                   buyEnded = true; 
                }
                
                // Transfer left sale token to project's owner
                if(tokenProject.balanceOf(address(this)) > 0){
                    tokenProject.transfer(tokenLeftReceiver, tokenProject.balanceOf(address(this)));
                }
                
                // Transfer revenue to devAddr
                if(currency.balanceOf(address(this)) > 0){
                    currency.transfer(devAddr, currency.balanceOf(address(this)));
                }
                
                // Vesting manage
                if(block.timestamp > vesting[vestingMonth-1].end){
                    vestingEnded = true;
                }else{
                    for(uint i=0; i<vestingMonth; i++){
                        if(block.timestamp >= vesting[i].start && block.timestamp <= vesting[i].end){
                            if(vestingProgress != i){
                                vestingProgress = i;
                            }
                            break;
                        }
                    }
                }
                
            } else{
                for(uint i=0; i<3; i++){
                    if(block.timestamp >= booster[i].start && block.timestamp <= booster[i].end){
                        if(boosterProgress != i){
                            boosterProgress = i;
                        }
                        break;
                    }
                }
    
            }
        }
    }
    
    function getBuyersLength() public view returns(uint){
        return buyers.length;
    }
    
    function getBuyerHistoryLength(address _buyer) public view returns(uint){
        return invoices[_buyer].length;
    }
    
    function getUserAllocation(address _target) public view returns(uint alloc){
        uint userStaked = staking.getUserStakedTokensBeforeDate(_target, booster[boosterProgress].start - 1); // 11:59:59 PM
        uint totalStaked = staking.getTotalStakedAmountBeforeDate(booster[boosterProgress].start - 1); // 11:59:59 PM
        alloc = userStaked.div(totalStaked);
    }
    
    function isBuyer(address _user) public view returns (bool){
        if(buyers.length == 0) return false;
        return (invoices[_user].length > 0);
    }
    
    function buyTokenbyETH(address[] calldata _path) payable isBuyNotEnded isBoosterProgress public {
        require(msg.value > 0, "You buy nothing");
        require(tokenProject.balanceOf(address(this)) > 0, "You are out of token sale");
        
        if(boosterProgress < 2){
            require(getUserAllocation(msg.sender).mul(100) > 0, "You never staked KOM before");
        }
        
        uint buyerId;
        if(!isBuyer(msg.sender)){
            buyers.push(msg.sender);
            buyerId = buyers.length-1;
        }else{
            buyerId = invoices[msg.sender][0].buyersIndex;
        }
        
        uint amountIn = msg.value;
        
        IWETH(weth).deposit{value: msg.value}();
        
        uint buyAmount = swapToCurrency(amountIn, _path, msg.sender);
        
        uint allocationAmount = getUserAllocation(msg.sender).mul(sale);
        
        uint tokenReceived = buyAmount.div(booster[boosterProgress].price);
        
        require(tokenReceived <= tokenProject.balanceOf(address(this)), "You buy more than token sale left");
        
        if(boosterProgress < 2){
            require(summaries[msg.sender].purchase.add(tokenReceived) <= allocationAmount, "You buy more than your KOM staked allocation");
        }else{
            require(tokenReceived >= minPublicBuy && tokenReceived <= maxPublicBuy, "Your token received is out of min & max buy range");
        }
        
        invoices[msg.sender].push(Invoice(buyerId, boosterProgress, tokenReceived));
        
        if(invoices[msg.sender].length == 1){
            summaries[msg.sender].buyersIndex = buyerId;
            summaries[msg.sender].claimed = false;
        }
        summaries[msg.sender].purchase += tokenReceived;
        
        emit TokenBought(boosterProgress, msg.sender, buyAmount, tokenReceived);
    }
    
    function buyTokenbyToken(uint _amountIn, address[] calldata _path) isBuyNotEnded isBoosterProgress public {
        require(_amountIn > 0, "You buy nothing");
        require(tokenProject.balanceOf(address(this)) > 0, "You are out of token sale");
        require(_path[0] != address(currency), "Token same as default, move to buyToken function");
        require(permitToken[_path[0]], "Your token is not acceptable");
        
        if(boosterProgress < 2){
            require(getUserAllocation(msg.sender).mul(100) > 0, "You never staked KOM before");
        }
        
        uint buyerId;
        if(!isBuyer(msg.sender)){
            buyers.push(msg.sender);
            buyerId = buyers.length-1;
        }else{
            buyerId = invoices[msg.sender][0].buyersIndex;
        }
        
        uint buyAmount = swapToCurrency(_amountIn, _path, msg.sender);
        
        uint allocationAmount = getUserAllocation(msg.sender).mul(sale);
        
        uint tokenReceived = buyAmount.div(booster[boosterProgress].price);
        
        require(tokenReceived <= tokenProject.balanceOf(address(this)), "You buy more than token sale left");
        
        if(boosterProgress < 2){
            require(summaries[msg.sender].purchase.add(tokenReceived) <= allocationAmount, "You buy more than your KOM staked allocation");
        }else{
            require(tokenReceived >= minPublicBuy && tokenReceived <= maxPublicBuy, "Your token received is out of min & max buy range");
        }
        
        invoices[msg.sender].push(Invoice(buyerId, boosterProgress, tokenReceived));
        
        if(invoices[msg.sender].length == 1){
            summaries[msg.sender].buyersIndex = buyerId;
            summaries[msg.sender].claimed = false;
        }
        summaries[msg.sender].purchase += tokenReceived;
        
        emit TokenBought(boosterProgress, msg.sender, buyAmount, tokenReceived);
    }
    
    function buyToken(uint _amountIn) isBuyNotEnded isBoosterProgress public {
        require(_amountIn > 0, "You buy nothing");
        require(tokenProject.balanceOf(address(this)) > 0, "You are out of token sale");
        
        if(boosterProgress < 2){
            require(getUserAllocation(msg.sender).mul(100) > 0, "You never staked KOM before");
        }
        
        uint buyerId;
        if(!isBuyer(msg.sender)){
            buyers.push(msg.sender);
            buyerId = buyers.length-1;
        }else{
            buyerId = invoices[msg.sender][0].buyersIndex;
        }
        
        uint allocationAmount = getUserAllocation(msg.sender).mul(sale);
        
        uint tokenReceived = _amountIn.div(booster[boosterProgress].price);
        
        require(tokenReceived <= tokenProject.balanceOf(address(this)), "You buy more than token sale left");
        
        if(boosterProgress < 2){
            require(summaries[msg.sender].purchase.add(tokenReceived) <= allocationAmount, "You buy more than your KOM staked allocation");
        }else{
            require(tokenReceived >= minPublicBuy && tokenReceived <= maxPublicBuy, "Your token received is out of min & max buy range");
        }
        
        invoices[msg.sender].push(Invoice(buyerId, boosterProgress, tokenReceived));
        
        if(invoices[msg.sender].length == 1){
            summaries[msg.sender].buyersIndex = buyerId;
            summaries[msg.sender].claimed = false;
        }
        summaries[msg.sender].purchase += tokenReceived;
        
        emit TokenBought(boosterProgress, msg.sender, _amountIn, tokenReceived);
    }
    
    function swapToCurrency(uint _amountIn, address[] calldata _path, address _to) internal returns(uint swapAmount){
        uint amountOut = getAmountOut(_path[0], _amountIn);
        
        // 0,5% slippage
        uint amountOutMin = amountOut.mul(995).div(1000);

        // deadline + 1 year
        uint deadline = block.timestamp.add(31536000);
        
        uint[] memory amounts;
        if(_path[0] == weth){
            amounts = swapExactETHForTokens(_amountIn, amountOutMin, _path, _to, deadline);
        }else{
            amounts = swapExactTokensForTokens(_amountIn, amountOutMin, _path, _to, deadline);
        }
        swapAmount = amounts[1];
    }
    
    function claimToken() everBought public {
        require(buyEnded, "Booster still running");
        require(block.timestamp >= tge, "Wait until Token Generation Event started");
        require(summaries[msg.sender].vestingStep <= vestingProgress, "Wait until next vesting started");
        require(!summaries[msg.sender].claimed, "You have been claimed all purchased tokens");
        
        if(summaries[msg.sender].vestingAmount == 0){
            summaries[msg.sender].vestingAmount = summaries[msg.sender].purchase.div(vestingMonth);
            summaries[msg.sender].claimable = summaries[msg.sender].purchase;
        }
        
        uint sendAmount;
        if(summaries[msg.sender].claimable > 0){
            sendAmount = summaries[msg.sender].vestingAmount;
            if(summaries[msg.sender].vestingStep < vestingProgress){
                uint deviation = vestingProgress.sub(summaries[msg.sender].vestingStep);
                sendAmount = sendAmount.mul(deviation);
            }
            
            tokenProject.transfer(msg.sender, sendAmount);
            summaries[msg.sender].vestingStep = vestingProgress.add(1);
            summaries[msg.sender].claimable -= sendAmount;
        } else{
            summaries[msg.sender].claimed = true;
        }
        
        emit TokenClaimed(msg.sender, sendAmount, block.timestamp, summaries[msg.sender].claimed);
    }
    
    
    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(address(swapFactory), output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(address(swapFactory), input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) internal ensure(deadline) virtual returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(address(swapFactory), amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(address(swapFactory), path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
 
    function swapExactETHForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) internal ensure(deadline) virtual returns (uint[] memory amounts) {
        require(path[0] == weth, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(address(swapFactory), amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        assert(IWETH(weth).transfer(UniswapV2Library.pairFor(address(swapFactory), path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    
    function getAmountOut(address _tokenIn, uint _amountIn) public view returns(uint amountOut){
        (uint256 tokenInReserve, uint256 tokenOutReserve) = UniswapV2Library.getReserves(address(swapFactory), _tokenIn, address(currency));
        amountOut = UniswapV2Library.quote(_amountIn, tokenInReserve, tokenOutReserve);
    }
    
    // **** ADMIN AREA ****
    
    function assignTokenAccepted(address _token, bool _accepted) public onlyOwner{
        require(_token != address(0), "Can't assign to address(0)");
        require(_token != address(currency), "Token can't be same as default currency");
        permitToken[_token] = _accepted;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0), "Can't assign to address(0)");
        owner = _newOwner;
    }
    
    function setSwapFactory(IUniswapV2Factory _swapFactory) public onlyOwner{
        require(address(_swapFactory) != address(0), "Can't assign to address(0)");
        swapFactory = _swapFactory;
    }
}

contract KommunitasFactory{
    address public owner;
    
    address[] public allProjects;
    
    ERC20 public tokenProject;
    ERC20 public currency;
    IUniswapV2Factory public swapFactory;
    address public immutable weth;
    address public devAddr;
    KommunitasStakingV2 public staking;
    
    modifier onlyOwner{
        require(owner == msg.sender, "You are not the owner");
        _;
    }
    
    mapping(address => address) public getProject;
    
    event ProjectCreated(address indexed tokenProject, address project, uint index);
    
    constructor(
        IUniswapV2Factory _swapFactory,
        address _weth,
        address _currency,
        address _devAddr,
        KommunitasStakingV2 _staking
    ){
        owner = msg.sender;
        swapFactory = _swapFactory;
        weth = _weth;
        currency = ERC20(_currency);
        devAddr = _devAddr;
        staking = _staking;
    }
    
    function allProjectsLength() public view returns (uint) {
        return allProjects.length;
    }
    
    function createProject(address _tokenProject) public onlyOwner returns(address project){
        require(_tokenProject != address(0), "Can't assign to address(0)");
        require(getProject[_tokenProject] == address(0), "Project exist");
        bytes32 salted = keccak256(abi.encodePacked(_tokenProject));
        
        project = address(new KommunitasProject{salt: salted}());
        
        tokenProject = ERC20(_tokenProject);
        getProject[_tokenProject] = project;
        allProjects.push(project);
        
        emit ProjectCreated(_tokenProject, project, allProjects.length-1);
    }
    
    function initializeProject(
        address _tokenProject,
        uint _sale,
        uint _target,
        uint[3] memory _price,
        uint _vestingMonth,
        uint[2] memory _minMaxPublicBuy,
        uint _fee,
        uint _tge,
        address _tokenLeftReceiver
    ) public onlyOwner{
        require(_tokenProject != address(0) && _tokenLeftReceiver != address(0), "Can't assign to address(0)");
        require(getProject[_tokenProject] != address(0), "Project not exist");
        require(_vestingMonth >= 3 && _vestingMonth <= 10, "Vesting must be between 3-10 months");
        
        KommunitasProject(getProject[_tokenProject]).initialize(
            staking,
            devAddr,
            swapFactory,
            weth,
            currency,
            ERC20(_tokenProject),
            _sale,
            _target,
            _price,
            _vestingMonth,
            _minMaxPublicBuy,
            _fee,
            _tge,
            _tokenLeftReceiver
        );
    }
    
    // WARNING: Be careful of gas spending!
    function updateAllProjects() public {
        require(allProjectsLength() > 0, "No Project exist");
        for(uint i=0; i<allProjectsLength(); i++){
            KommunitasProject(allProjects[i]).updateProject();
        }
    }
    
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0), "Can't assign to address(0)");
        owner = _newOwner;
    }
    
    function setSwapFactory(IUniswapV2Factory _swapFactory) public onlyOwner{
        require(address(_swapFactory) != address(0), "Can't assign to address(0)");
        swapFactory = _swapFactory;
    }
    
    function setCurrency(ERC20 _currency) public onlyOwner{
        require(address(_currency) != address(0), "Can't assign to address(0)");
        currency = _currency;
    }
    
    function setDevAddr(address _devAddr) public onlyOwner{
        require(_devAddr != address(0), "Can't assign to address(0)");
        devAddr = _devAddr;
    }
}