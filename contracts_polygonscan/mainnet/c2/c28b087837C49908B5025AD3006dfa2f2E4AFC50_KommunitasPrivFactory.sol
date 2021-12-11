/**
 *Submitted for verification at polygonscan.com on 2021-12-11
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

interface IKommunitasPrivFactory{
    event ProjectCreated(address indexed project, uint index);
    
    function owner() external  view returns (address);
    function devAddr() external view returns (address);

    function swapFactory() external view returns (address);
    function weth() external view returns (address);
    function stakingV1() external view returns (address);
    function stakingV2() external view returns (address);
    
    function allProjectsLength() external view returns(uint);
    function allPaymentsLength() external view returns(uint);
    function allProjects(uint) external view returns(address);
    function allPayments(uint) external view returns(address);
    function getPaymentIndex(address) external view returns(uint);

    function createProject(address, uint, uint, uint, uint, uint, uint[2] memory, uint[2] memory, uint, uint) external returns (address);
    
    function transferOwnership(address) external;
    function setSwapFactory(address) external;
    function setPayment(address) external;
    function removePayment(address) external;
    function setDevAddr(address) external;
}


pragma solidity 0.7.6;

interface KommunitasStaking{
    function getUserStakedTokens(address _of) external view returns (uint256);
    function communityStaked() external view returns(uint256);
}


pragma solidity 0.7.6;

interface KommunitasStakingV2{
    function getUserStakedTokens(address _of) external view returns (uint256);
    function getUserStakedTokensBeforeDate(address _of, uint256 _before) external view returns (uint256);
    function minPrivateSale() external view returns(uint256);
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


pragma solidity 0.7.6;

contract KommunitasPrivProject{
    using SafeMath for uint;
    
    bool public initialized;
    bool public isPaused;
    
    address public owner;
    IKommunitasPrivFactory public factory;
    enum StakingChoice { V1, V2 }
    
    uint public revenue;
    ERC20 public payment;
    
    uint public tokenProjectDecimals;
    uint public totalStakedMinPrivateSale;
    uint public target;
    uint public calculation;
    uint public sale;
    bool public buyEnded;
    uint public minPublicBuy;
    uint public maxPublicBuy;
    address[] public buyers;
    address[] public whitelists;
    
    struct Round{
        uint start;
        uint end;
        uint price;
        uint achieve;
    }
    
    struct Invoice{
        uint buyersIndex;
        uint boosterId;
        uint boughtAt;
        uint bought;
        uint received;
    }
    
    mapping(uint => Round) public booster;
    mapping(address => Invoice[]) public invoices;
    mapping(address => string) public recipient;
    mapping(address => uint) public whitelist;
    mapping(address => mapping(uint => uint)) public purchasePerRound;
    mapping(address => bool) public publicBought;
    
    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    modifier onlyFactory{
        require(msg.sender == address(factory), "You are not the factory");
        _;
    }
    
    modifier isNotInitialized{
        require(!initialized, "Already initialized");
        _;
    }
    
    modifier isNotPaused{
        require(!isPaused, "This project is paused");
        _;
    }
    
    modifier isBoosterProgress{
        require(block.timestamp >= booster[boosterProgress()].start && block.timestamp <= booster[boosterProgress()].end, "Not in any booster progress");
        _;
    }
    
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }
    
    event TokenBought(uint indexed booster, address indexed buyer, uint buyAmount, uint tokenReceived);
    
    constructor(){
        factory = IKommunitasPrivFactory(msg.sender);
        initialized = false;
        buyEnded = false;
        isPaused = false;
        owner = tx.origin;
    }
    
    /**
     * @dev Initialize project for raise fund
     * @param _payment Tokens to raise
     * @param _tokenProjectDecimals Token decimals of project
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _target Target amount to raise (decimals 18)
     * @param _calculation Epoch date to start buy allocation calculation
     * @param _start Epoch date to start round 1
     * @param _price Token project price in each rounds (in 6 decimals)
     * @param _minMaxPublicBuy Min and max token to buy (in 0 decimals)
     * @param _boosterRunning Duration when booster running (in seconds)
     * @param _boosterDelay Delay between booster (in seconds)
     */
    function initialize(
        address _payment,
        uint _tokenProjectDecimals,
        uint _sale,
        uint _target,
        uint _calculation,
        uint _start,
        uint[2] memory _price,
        uint[2] memory _minMaxPublicBuy,
        uint _boosterRunning,
        uint _boosterDelay
    ) public onlyFactory isNotInitialized{
        require(_boosterRunning > 0 && _boosterDelay > 0, "Can't be 0");
        require(_calculation < _start, "Calculation must be done before booster is started");
        
        initialized = true;
        
        payment = ERC20(_payment);
        tokenProjectDecimals = _tokenProjectDecimals;
        sale = _sale;
        target = _target;
        calculation = _calculation;
        
        for(uint i=1; i<=2; i++){
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + _boosterDelay;
            }
            booster[i].end = booster[i].start + _boosterRunning;
            booster[i].price = _price[i-1].mul(10**payment.decimals()).div(1e6);
            booster[i].achieve = 0;
        }
        
        minPublicBuy = _minMaxPublicBuy[0].mul(10**tokenProjectDecimals);
        maxPublicBuy = _minMaxPublicBuy[1].mul(10**tokenProjectDecimals);
    }
    
    // **** VIEW AREA ****
    
    /**
     * @dev Get all whitelists length
     */
    function getWhitelistLength() public view returns(uint){
        return whitelists.length;
    }
    
    /**
     * @dev Get all buyers/participants length
     */
    function getBuyersLength() public view returns(uint){
        return buyers.length;
    }
    
    /**
     * @dev Get total number transactions of buyer
     */
    function getBuyerHistoryLength(address _buyer) public view returns(uint){
        return invoices[_buyer].length;
    }

    /**
     * @dev Get User Staked Info
     * @param _choice V1 or V2 Staking
     * @param _target User address
     */
    function getUserStakedInfo(StakingChoice _choice, address _target) internal view returns(uint userStaked, uint totalStaked){
        if(_choice == StakingChoice.V1){
            userStaked = KommunitasStaking(factory.stakingV1()).getUserStakedTokens(_target);
            totalStaked = KommunitasStaking(factory.stakingV1()).communityStaked();
        }else if(_choice == StakingChoice.V2){
            userStaked = KommunitasStakingV2(factory.stakingV2()).getUserStakedTokensBeforeDate(_target, calculation);
            totalStaked = totalStakedMinPrivateSale;
        }else{
            revert("Invalid Staking Choice. Needs to be either 0 (V1) or 1 (V2)");
        }
    }
    
    /**
     * @dev Get User Allocation (in 8 decimals)
     * @param _target User address
     */
    function getUserAllocation_d8(address _target) public view returns(uint alloc){
        alloc = 0;
        if(eligibleCheck(_target)){
            (uint userStaked, uint totalStaked) = getUserStakedToken(_target);
            alloc = userStaked.mul(10 ** 8).div(totalStaked);
        }
    }
    
    /**
     * @dev Get User Staked Token both V1 & V2
     * @param _target User address
     */
    function getUserStakedToken(address _target) internal view returns(uint userStaked, uint totalStaked){
        (uint userV1Staked, uint v1TotalStaked) = getUserStakedInfo(StakingChoice.V1, _target);
        (uint userV2Staked, uint v2TotalStaked) = getUserStakedInfo(StakingChoice.V2, _target);
        userStaked = userV1Staked.add(userV2Staked);
        totalStaked = v1TotalStaked.add(v2TotalStaked);
    }
    
    /**
     * @dev Check whether buyer/participant eligible
     * @param _user User address
     */
    function eligibleCheck(address _user) internal view returns (bool){
        if(boosterProgress() == 1 && whitelist[_user] > 0) return true;
        (uint userStaked,) = getUserStakedToken(_user);
        return (userStaked >= KommunitasStakingV2(factory.stakingV2()).minPrivateSale());
    }
    
    /**
     * @dev Check whether buyer/participant or not
     * @param _user User address
     */
    function isBuyer(address _user) public view returns (bool){
        if(buyers.length == 0) return false;
        return (invoices[_user].length > 0);
    }
    
    /**
     * @dev Get amount out of swap
     * @param _tokenIn Token to swap
     * @param _amountIn Amount to swap
     */
    function getAmountOut(address _tokenIn, uint _amountIn) public view returns(uint256 amountOut){
        address[] memory _path = new address[](2);
        _path[0] = _tokenIn;
        _path[1] = address(payment);
        amountOut = UniswapV2Library.getAmountsOut(factory.swapFactory(), _amountIn, _path)[1];
    }
    
    /**
     * @dev Get total purchase of a user
     * @param _user User address
     */
    function getTotalPurchase(address _user) public view returns(uint total){
        total = purchasePerRound[_user][1].add(purchasePerRound[_user][2]);
    }
    
    /**
     * @dev Get booster running now, 0 = no booster running
     */
    function boosterProgress() public view returns (uint running){
        running = 0;
        for(uint i=1; i<=2; i++){
            if(block.timestamp >= booster[i].start && block.timestamp <= booster[i].end){
                running = i;
            }
        }
    }
    
    /**
     * @dev Get total sold tokens
     */
    function sold() public view returns(uint total){
        total = 0;
        for(uint i=1; i<=2; i++){
            total = total.add(booster[i].achieve);
        }
    }
    
    /**
     * @dev Get whitelist total allocation
     */
    function whitelistTotalAlloc() public view returns(uint total){
        total = 0;
        if(whitelists.length > 0){
            for(uint i=0; i<whitelists.length; i++){
                total = total.add(whitelist[whitelists[i]]);
            }
        }
    }
    
    /**
     * @dev Get User Allocation Token
     * @param _user User address
     */
    function getUserAllocToken(address _user) internal view returns(uint userAllocToken){
        if(whitelist[_user] > 0){
            userAllocToken = whitelist[_user];
        } else{
            userAllocToken = getUserAllocation_d8(_user).mul(sale.sub(whitelistTotalAlloc())).div(10 ** 8);
        }
    }
    
    /**
     * @dev Calculate amount in
     * @param _tokenReceived Token received amount
     * @param _amountIn Amount in to buy
     */
    function amountInCalc(uint _tokenReceived, uint _amountIn, address _user) internal view returns(uint amountInFinal, uint tokenReceivedFinal){
        if(boosterProgress() == 1){
            if(whitelist[_user] == 0){
                require(int(sale - sold() - whitelistTotalAlloc()) > 0, "You are out of token sale");
                if(_tokenReceived > sale.sub(sold()).sub(whitelistTotalAlloc())){
                    _tokenReceived = sale.sub(sold()).sub(whitelistTotalAlloc());
                }
            }
        } else{
            require(sale.sub(sold()) > 0, "You are out of token sale");
            if(_tokenReceived > sale.sub(sold())){
                _tokenReceived = sale.sub(sold());
            }
        }
        _amountIn = _tokenReceived.mul(booster[boosterProgress()].price).div(10 ** tokenProjectDecimals);
        (amountInFinal, tokenReceivedFinal) = amountInCalcInner(_user, _tokenReceived, _amountIn);
    }
    
    /**
     * @dev Calculate amount in inner
     * @param _user User address
     * @param _tokenReceived Token received amount
     * @param _amountIn Amount in to buy
     */
    function amountInCalcInner(address _user, uint _tokenReceived, uint _amountIn) internal view returns(uint amountInFinal, uint tokenReceivedFinal){
        amountInFinal = _amountIn;
        if(boosterProgress() == 1){
            require(purchasePerRound[_user][boosterProgress()] < getUserAllocToken(_user), "You reached your buy allocation limit in this booster");
            if(purchasePerRound[_user][boosterProgress()].add(_tokenReceived) > getUserAllocToken(_user)){
                amountInFinal = (getUserAllocToken(_user).sub(purchasePerRound[_user][boosterProgress()])).mul(booster[boosterProgress()].price).div(10 ** tokenProjectDecimals);
            }
        }else{
            require(!publicBought[_user], "You are allowed to buy once in public round");
            require(_tokenReceived >= minPublicBuy, "You buy less than minPublicBuy");
            if(_tokenReceived > maxPublicBuy){
                amountInFinal = maxPublicBuy.mul(booster[boosterProgress()].price).div(10 ** tokenProjectDecimals);
            }
        }
        require(amountInFinal > 0, "Your buy amount is too small");
        tokenReceivedFinal = amountInFinal.mul(10 ** tokenProjectDecimals).div(booster[boosterProgress()].price);
    }

    /**
     * @dev Convert address to string
     * @param x Address to convert
     */
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    // **** MAIN AREA ****
    
    /**
     * @dev Move fund to devAddr
     */
    function moveFund() public {
        require(block.timestamp > booster[2].end, "Still in progress");
        if(payment.balanceOf(address(this)) > 0){
            payment.transfer(factory.devAddr(), payment.balanceOf(address(this)));
        }
        buyEnded = true;
    }
    
    /**
     * @dev Buy token project using native token
     * @param _path 'Native' to 'token to raise'
     */
    function buyTokenByETH(address[] calldata _path) payable isBoosterProgress isNotPaused public {
        require(eligibleCheck(msg.sender), "You are not eligible to buy");
        require(_path[0] == factory.weth() && _path[1] == address(payment), "Path not correct");
        require(totalStakedMinPrivateSale > 0, "TotalStakedMinPrivateSale haven't been set");
        
        uint buyerId = setBuyer(msg.sender);
        
        uint amountOut = getAmountOut(_path[0], msg.value);
        
        uint tokenReceived = amountOut.mul(10 ** tokenProjectDecimals).div(booster[boosterProgress()].price);
        
        (uint amountInFinal, uint tokenReceivedFinal) = amountInCalc(tokenReceived, amountOut, msg.sender);
        
        uint ethFinal = msg.value.mul(amountInFinal).div(amountOut);

        IWETH(factory.weth()).deposit{value: ethFinal}();
        
        if(ethFinal < msg.value){
            TransferHelper.safeTransferETH(msg.sender, msg.value.sub(ethFinal));
        }
        
        uint buyAmount = swapToAccepted(ethFinal, _path, address(this));
        
        if(boosterProgress() == 2){
            publicBought[msg.sender] = true;
        }
        
        invoices[msg.sender].push(Invoice(buyerId, boosterProgress(), block.timestamp, buyAmount, tokenReceivedFinal));
        
        revenue += buyAmount;
        purchasePerRound[msg.sender][boosterProgress()] += tokenReceivedFinal;
        booster[boosterProgress()].achieve += tokenReceivedFinal;
        
        emit TokenBought(boosterProgress(), msg.sender, buyAmount, tokenReceivedFinal);
    }
    
    /**
     * @dev Buy token project using another token
     * @param _amountIn Buy amount
     * @param _path 'Token' to 'token to raise'
     */
    function buyTokenByToken(uint _amountIn, address[] calldata _path) isBoosterProgress isNotPaused public {
        require(eligibleCheck(msg.sender), "You are not eligible to buy");
        require(_path[0] != address(payment) && _path[0] == factory.allPayments(factory.getPaymentIndex(_path[0])) && _path[1] == address(payment), "Path not correct");
        require(totalStakedMinPrivateSale > 0, "TotalStakedMinPrivateSale haven't been set");
        
        uint buyerId = setBuyer(msg.sender);
        
        uint amountOut = getAmountOut(_path[0], _amountIn);
        
        uint tokenReceived = amountOut.mul(10 ** tokenProjectDecimals).div(booster[boosterProgress()].price);
        
        (uint amountInFinal, uint tokenReceivedFinal) = amountInCalc(tokenReceived, amountOut, msg.sender);
        
        uint buyAmount = swapToAccepted(_amountIn.mul(amountInFinal).div(amountOut), _path, address(this));
        
        if(boosterProgress() == 2){
            publicBought[msg.sender] = true;
        }
        
        invoices[msg.sender].push(Invoice(buyerId, boosterProgress(), block.timestamp, buyAmount, tokenReceivedFinal));
        
        revenue += buyAmount;
        purchasePerRound[msg.sender][boosterProgress()] += tokenReceivedFinal;
        booster[boosterProgress()].achieve += tokenReceivedFinal;
        
        emit TokenBought(boosterProgress(), msg.sender, buyAmount, tokenReceivedFinal);
    }
    
    /**
     * @dev Buy token project using token raise
     * @param _amountIn Buy amount
     * @param _tokenIn token raise address
     */
    function buyToken(uint _amountIn, address _tokenIn) isBoosterProgress isNotPaused public {
        require(eligibleCheck(msg.sender), "You are not eligible to buy");
        require(_tokenIn == address(payment), "Token is different, move to buyTokenbyToken function");
        require(totalStakedMinPrivateSale > 0, "TotalStakedMinPrivateSale haven't been set");
        
        uint buyerId = setBuyer(msg.sender);
        
        uint tokenReceived = _amountIn.mul(10 ** tokenProjectDecimals).div(booster[boosterProgress()].price);
        
        (uint amountInFinal, uint tokenReceivedFinal) = amountInCalc(tokenReceived, _amountIn, msg.sender);
        
        TransferHelper.safeTransferFrom(address(payment), msg.sender, address(this), amountInFinal);

        if(boosterProgress() == 2){
            publicBought[msg.sender] = true;
        }
        
        invoices[msg.sender].push(Invoice(buyerId, boosterProgress(), block.timestamp, amountInFinal, tokenReceivedFinal));
        
        revenue += amountInFinal;
        purchasePerRound[msg.sender][boosterProgress()] += tokenReceivedFinal;
        booster[boosterProgress()].achieve += tokenReceivedFinal;
        
        emit TokenBought(boosterProgress(), msg.sender, amountInFinal, tokenReceivedFinal);
    }

    /**
     * @dev Set buyer id
     * @param _user User address
     */
    function setBuyer(address _user) internal returns(uint buyerId){
        if(!isBuyer(_user)){
            buyers.push(_user);
            buyerId = buyers.length-1;
            
            bytes memory userRecipient = bytes(recipient[_user]);
            if(userRecipient.length == 0){
                recipient[_user] = toAsciiString(_user);
            }
        }else{
            buyerId = invoices[_user][0].buyersIndex;
        }
    }
    
    /**
     * @dev Set recipient address
     * @param _recipient Recipient address
     */
    function setRecipient(string memory _recipient) isNotPaused public {
        recipient[msg.sender] = _recipient;
    }
    
    /**
     * @dev Handle swap amount
     * @param _amountIn Buy amount
     * @param _path 'from' to 'to' token
     * @param _to Target address
     */
    function swapToAccepted(uint _amountIn, address[] calldata _path, address _to) internal returns(uint swapAmount){
        uint amountOut = getAmountOut(_path[0], _amountIn);
        
        // 0,5% slippage
        uint amountOutMin = amountOut.mul(995).div(1000);

        // deadline + 1 year
        uint deadline = block.timestamp.add(31536000);
        
        uint[] memory amounts;
        if(_path[0] == factory.weth()){
            amounts = swapExactETHForTokens(_amountIn, amountOutMin, _path, _to, deadline);
        }else{
            amounts = swapExactTokensForTokens(_amountIn, amountOutMin, _path, _to, deadline);
        }
        swapAmount = amounts[1];
    }
    
    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory.swapFactory(), output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory.swapFactory(), input, output)).swap(
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
        amounts = UniswapV2Library.getAmountsOut(factory.swapFactory(), amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory.swapFactory(), path[0], path[1]), amounts[0]
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
        require(path[0] == factory.weth(), 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory.swapFactory(), amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        assert(IWETH(factory.weth()).transfer(UniswapV2Library.pairFor(factory.swapFactory(), path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    
    // **** ADMIN AREA ****

    /**
     * @dev Set beginning total staked min private sale
     */
    function setTotalStakedMinPrivateSale(uint _finalStaked) public onlyOwner {
        require(block.timestamp >= calculation, "Calculation is not started yet");
        require(totalStakedMinPrivateSale == 0, "totalStakedMinPrivateSale had been set");
        
        totalStakedMinPrivateSale = _finalStaked;
    }

    /**
     * @dev Set whitelist allocation token in 6 decimals
     * @param _user User address
     * @param _allocation Token allocation in 6 decimals
     */
    function setWhitelist_d6(address[] memory _user, uint[] memory _allocation) public onlyOwner {
        require(block.timestamp < calculation, "Calculation has been started");
        require(_user.length == _allocation.length , "users & allocations length mismatch");
        
        for(uint i=0; i<_user.length; i++){
            whitelists.push(_user[i]);
            whitelist[_user[i]] = _allocation[i].mul(10 ** tokenProjectDecimals).div(10 ** 6);
        }
    }

    /**
     * @dev Set Min & Max in FCFS
     * @param _minMaxPublicBuy Min and max token to buy (in 0 decimals)
     */
    function setMinMax(uint[2] memory _minMaxPublicBuy) public onlyOwner{
        require(boosterProgress() != 2, "FCFS started");

        minPublicBuy = _minMaxPublicBuy[0].mul(10**tokenProjectDecimals);
        maxPublicBuy = _minMaxPublicBuy[1].mul(10**tokenProjectDecimals);
    }
    
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0), "Can't assign to address(0)");
        owner = _newOwner;
    }
    
    function togglePause() public onlyOwner{
        isPaused = !isPaused;
    }
}


pragma solidity 0.7.6;

contract KommunitasPrivFactory is IKommunitasPrivFactory{
    address[] public override allProjects; // all projects created
    address[] public override allPayments; // all payment Token accepted
    
    address public override owner;
    address public override devAddr; // dev address to receive revenue
    
    address public override swapFactory; // swap factory address
    address public override immutable weth; 
    address public override immutable stakingV1;
    address public override immutable stakingV2;
    
    modifier onlyOwner{
        require(owner == msg.sender, "You are not the owner");
        _;
    }
    
    mapping(address => uint) public override getPaymentIndex;
    
    constructor(
        address _swapFactory,
        address _weth,
        address _devAddr,
        address _stakingV1,
        address _stakingV2
    ){
        owner = msg.sender;
        swapFactory = _swapFactory;
        weth = _weth;
        devAddr = _devAddr;
        stakingV1 = _stakingV1;
        stakingV2 = _stakingV2;
    }
    
    /**
     * @dev Get total number of projects created
     */
    function allProjectsLength() public override view returns (uint) {
        return allProjects.length;
    }
    
    /**
     * @dev Get total number of payment Toked accepted
     */
    function allPaymentsLength() public override view returns (uint) {
        return allPayments.length;
    }
    
    /**
     * @dev Create new project for raise fund
     * @param _payment Tokens to raise
     * @param _tokenProjectDecimals Token decimals of project
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _target Target amount to raise (based on token to raise decimals)
     * @param _calculation Epoch date to start buy allocation calculation
     * @param _start Epoch date to start round 1
     * @param _price Token project price in each rounds (in 6 decimals)
     * @param _minMaxPublicBuy Min and max token to buy (in 0 decimals)
     * @param _boosterRunning Duration when booster running (in seconds)
     * @param _boosterDelay Delay between booster (in seconds)
     */
    function createProject(
        address _payment,
        uint _tokenProjectDecimals,
        uint _sale,
        uint _target,
        uint _calculation,
        uint _start,
        uint[2] memory _price,
        uint[2] memory _minMaxPublicBuy,
        uint _boosterRunning,
        uint _boosterDelay
    ) public override onlyOwner returns(address project){
        require(_payment != address(0), "Can't assign to address(0)");
        require(_payment == allPayments[getPaymentIndex[_payment]], "Payment not acceptable");
        
        project = address(new KommunitasPrivProject());

        allProjects.push(project);
        
        KommunitasPrivProject(allProjects[allProjects.length-1]).initialize(
            _payment,
            _tokenProjectDecimals,
            _sale,
            _target,
            _calculation,
            _start,
            _price,
            _minMaxPublicBuy,
            _boosterRunning,
            _boosterDelay
        );
        
        emit ProjectCreated(project, allProjects.length-1);
    }
    
    /**
     * @dev Transfer ownership to new owner
     * @param _newOwner New owner
     */
    function transferOwnership(address _newOwner) public override onlyOwner{
        require(_newOwner != address(0), "Can't set to address(0)");
        owner = _newOwner;
    }
    
    /**
     * @dev Set new swap factory
     * @param _swapFactory New swap factory
     */
    function setSwapFactory(address _swapFactory) public override onlyOwner{
        require(_swapFactory != address(0), "Can't set to address(0)");
        swapFactory = _swapFactory;
    }
    
    /**
     * @dev Set new token to be accepted
     * @param _token New token address
     */
    function setPayment(address _token) public override onlyOwner{
        require(_token != address(0), "Can't set to address(0)");
        if(allPayments.length > 0) {
            require(_token != allPayments[getPaymentIndex[_token]], "Token payment is exist");
        }
        
        allPayments.push(_token);
        getPaymentIndex[_token] = allPayments.length-1;
    }
    
    /**
     * @dev Remove token as payment
     * @param _token Token address
     */
    function removePayment(address _token) public override onlyOwner{
        require(_token != address(0), "Can't set to address(0)");
        require(_token == allPayments[getPaymentIndex[_token]], "Token payment not found");
        
        uint indexToDelete = getPaymentIndex[_token];
        address addressToMove = allPayments[allPayments.length-1];
        
        allPayments[indexToDelete] = addressToMove;
        getPaymentIndex[addressToMove] = indexToDelete;
        
        allPayments.pop();
        delete getPaymentIndex[_token];
    }

    /**
     * @dev Set new dev address
     * @param _devAddr Dev address
     */
    function setDevAddr(address _devAddr) public override onlyOwner{
        require(_devAddr != address(0), "Can't set to address(0)");
        devAddr = _devAddr;
    }
}