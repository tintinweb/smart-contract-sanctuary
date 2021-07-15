/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity ^0.6.12;

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


interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    constructor (string memory name_, string memory symbol_) public {
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
    function decimals() public pure virtual returns (uint8) {
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


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
    constructor () public {
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



library PancakeswapUtilities {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function getPair(address tokA, address tokB, address factoryAddr) public view returns (IUniswapV2Pair) {
      IUniswapV2Factory factory = IUniswapV2Factory(factoryAddr);
      return IUniswapV2Pair(factory.getPair(tokA, tokB));
    }

    function buyToken(address tokenToSpend, address tokenToBuy, address account, uint256 amountOut, IUniswapV2Router02 pancakeRouter) external returns(uint256, uint256) {

      IUniswapV2Pair pair = getPair(tokenToSpend, tokenToBuy, pancakeRouter.factory());
      (uint reservesA, uint reservesB) = getReservesOrdered(pair, tokenToSpend, tokenToBuy);
      uint amountInMin = pancakeRouter.getAmountIn(amountOut, reservesA, reservesB);
      IBEP20(tokenToSpend).approve(address(pancakeRouter), amountInMin);
      address[] memory path = new address[](2);
      path[0] = tokenToSpend;
      path[1] = tokenToBuy;

      uint[] memory amounts = pancakeRouter.swapTokensForExactTokens(
          amountOut,
          amountInMin,
          path,
          account,
          block.timestamp + 60
      );
      return (amounts[1], amounts[0]);
    }
  
    function sellToken(address tokenToSell, address paymentToken, address account, uint256 amountIn, IUniswapV2Router02 pancakeRouter) external returns(uint256, uint256) {
      IBEP20(tokenToSell).approve(address(pancakeRouter), amountIn);
      address[] memory path = new address[](2);
      path[0] = tokenToSell;
      path[1] = paymentToken;
      uint[] memory amounts = pancakeRouter.swapExactTokensForTokens(
          amountIn,
          0,
          path,
          account,
          block.timestamp + 60
      );
      return (amounts[1], amounts[0]);
    }

    function getReservesOrdered(IUniswapV2Pair pair, address tokenFirst, address tokenSecond) public view returns(uint, uint) {
      (address token0,) = PancakeswapUtilities.sortTokens(tokenFirst, tokenSecond);
      (uint tokenAReserve, uint tokenBReserve,) = pair.getReserves();
      return address(tokenFirst) == token0 ? (tokenAReserve, tokenBReserve) : (tokenBReserve, tokenAReserve);
    }
}


contract WBNB {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

     fallback() external {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        // if (src != msg.sender && allowance[src][msg.sender] != ) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        // }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}




/**
This is a crypto index contract. It is create by the IndexController
Tracks a group of cryptocurrencies prices. You can purchase this ERC20 and
sell it for the price of the tokens it's tracking. It's like buying an ETF.
*/
contract IndexPool is ERC20, Ownable, ReentrancyGuard {
    address private  _indexController;
    WBNB private  _WBNB;
    IUniswapV2Router02 private _pancakeRouter;
    IUniswapV2Factory private _pancakeFactory;
    ERC20 private immutable _BUSD;
    address[] _underlyingTokens;
    uint16[] _tokenWeights;
    uint16 constant WEIGHT_FACTOR = 1000;
    uint8[] _categories;

    event Mint(address indexed to, uint256 amount, uint256 cost);
    event Burn(address indexed from, uint256 amount, uint256 paid);
    event CompositionChange(address[] tokens, uint16[] weights);

    constructor(
        address[] memory underlyingTokens,
        uint16[] memory tokenWeights
    ) public ERC20("BivrostIndex", "BIDX") {
        require(
            tokenWeights.length == underlyingTokens.length,
            "Tokens and weights don't have same sizes"
        );
        require(
            underlyingTokens.length >= 2,
            "At least 2 underlying tokens are needed"
        );

        _underlyingTokens = underlyingTokens;
        _BUSD = ERC20(0x3f86c985D3A0e8BA4050eDc556AddA1d97961B8F);
        _pancakeRouter = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
       // _WBNB = WBNB(_pancakeRouter.WETH());
        //_pancakeFactory = IUniswapV2Factory(_pancakeRouter.factory());
        _tokenWeights = tokenWeights;
        _indexController = msg.sender;
        _categories = [0];

        emit CompositionChange(underlyingTokens, tokenWeights);
    }

    /*
    ** purchase at least amountOut of the index paying with a BEP20 token
    */
    function buyIndexWith(uint amountOut, address paymentToken, uint amountInMax) external {
        require(paymentToken == address(_WBNB) || paymentToken == address(_BUSD), "IndexPool: INVALID_PAYMENT_TOKEN");
        uint quote = getIndexQuote(amountOut);
        ERC20(paymentToken).transferFrom(msg.sender, address(this), amountInMax);
        _collectFee(amountInMax / 100, paymentToken);
        (, uint spent) = PancakeswapUtilities.buyToken(paymentToken, address(_WBNB), address(this), quote, _pancakeRouter);
        require(spent <= amountInMax, "IndexPool: INSUFFICIENT_AMOUNT_IN_MAX");
        _buyIndex(amountOut, quote);
    }

    /*
    ** purchase at least amountOut of the index paying with BNB
    */
    function buyIndex(uint amountOut) external payable {
        uint quote = getIndexQuoteWithFee(amountOut);
        uint amountIn = msg.value;
        require(quote <= amountIn, "IndexPool: INSUFFICIENT_AMOUNT_IN");
        _WBNB.deposit{value: quote}();
        (bool sent,) = msg.sender.call{ value: amountIn - quote }("");
        require(sent, "IndexPool: BNB_REFUND_FAIL");
        uint256 remainingWBNB = _buyIndex(amountOut, quote);
        _collectFee(remainingWBNB, address(_WBNB));
    }

    function _buyIndex(uint256 amountOut, uint256 amountIn) private nonReentrant returns (uint256) {
        uint256 totalTokensBought = 0;
        uint totalSpent = 0;
        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            uint purchaseAmount = (amountOut * _tokenWeights[i]) / WEIGHT_FACTOR;
            if (purchaseAmount == 0)
                continue;
            if (_underlyingTokens[i] == address(_WBNB)) {
                totalTokensBought += purchaseAmount;
                totalSpent += purchaseAmount;
                continue;
            }
            (uint256 boughtAmount, uint256 spent) =
                PancakeswapUtilities.buyToken(
                    address(_WBNB),
                    _underlyingTokens[i],
                    address(this),
                    purchaseAmount,
                    _pancakeRouter
                );
            totalTokensBought += boughtAmount;
            totalSpent += spent;
        }

        uint256 amountOutResult = (totalTokensBought * WEIGHT_FACTOR) / _sum(_tokenWeights);

        _mint(msg.sender, amountOutResult);
        emit Mint(msg.sender, amountOutResult, totalSpent);
        return amountIn - totalSpent;
    }

    function sellIndex(uint amount, uint amountOutMin) external nonReentrant returns(uint) {
        require(amount <= balanceOf(msg.sender), "IndexPool: INSUFFICIENT_BALANCE");

        uint256 totalTokensSold = 0;
        uint256 amountToPayUser = 0;

        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            uint256 sellAmount = (amount * _tokenWeights[i]) / WEIGHT_FACTOR;
            if (sellAmount == 0)
                continue;
            if (_underlyingTokens[i] == address(_WBNB)) {
                totalTokensSold += sellAmount;
                amountToPayUser += sellAmount;
                continue;
            }
            (uint256 amountOut, uint256 amountIn) =
                PancakeswapUtilities.sellToken(
                    _underlyingTokens[i],
                    address(_WBNB),
                    address(this),
                    sellAmount,
                    _pancakeRouter
                );

            totalTokensSold += amountIn;
            amountToPayUser += amountOut;
        }
        uint256 amountToBurn = (totalTokensSold * WEIGHT_FACTOR) / _sum(_tokenWeights);
        uint fee = getFee(amountToPayUser);
        _collectFee(fee, address(_WBNB));

        amountToPayUser -= fee;
        _WBNB.withdraw(amountToPayUser);

        _burn(msg.sender, amountToBurn);

        (bool sent,) = msg.sender.call{ value: amountToPayUser }("");
        require(sent, "IndexPool: SEND_BNB_FAIL");
        emit Burn(msg.sender, amountToBurn, amountToPayUser);

        require(amountToPayUser >= amountOutMin, "IndexPool: AMOUNT_OUT_TOO_LOW");
        return amountToPayUser;
    }

    receive() external payable {
    }

    // get the total price of the index in BNB (from Pancakeswap)
    function getIndexQuote(uint amount) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            uint tokenBuyAmount = (_tokenWeights[i] * amount) / WEIGHT_FACTOR;
            total += getTokenQuote(_underlyingTokens[i], tokenBuyAmount);
        }
        return total;
    }

    function getIndexQuoteWithFee(uint amount) public view returns (uint256) {
        uint price = getIndexQuote(amount);
        return price + getFee(price);
    }

    function getFee(uint amount) public pure returns (uint) {
        return amount / 100; // 1% fee
    }

    // get the price of a token in BNB (from Pancakeswap)
    function getTokenQuote(address token, uint amount) public view returns (uint256) {
        if (token == address(_WBNB))
            return amount;
        address pairAddr = _pancakeFactory.getPair(address(_WBNB), token);
        require(pairAddr != address(0), "Cannot find pair BNB-token");
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        (uint256 reserveBNB, uint256 reserveToken) =
            PancakeswapUtilities.getReservesOrdered(
                pair,
                address(_WBNB),
                token
            );
        return _pancakeRouter.getAmountIn(amount, reserveBNB, reserveToken);
    }

    function getComposition()
        public
        view
        returns (address[] memory, uint16[] memory)
    {
        return (_underlyingTokens, _tokenWeights);
    }

    function _sum(uint16[] memory items) private pure returns (uint16) {
        uint16 total = 0;
        for (uint256 i = 0; i < items.length; i++) {
            total += items[i];
        }
        return total;
    }

    function _collectFee(uint256 amount, address token) private {
        // external calls to trusted contracts
        ERC20(token).transfer(_indexController, amount);
        //IndexController(_indexController).redistributeFees(IBEP20(token));
    }

    function changeWeights(uint16[] memory weights) external onlyOwner {
        require(weights.length == _tokenWeights.length, "IndexPool: INVALID_ARRAY_LEN");

        int quoteBefore = int(getIndexQuote(1e18));
        uint totalSale = 0;
        for (uint i = 0; i < weights.length; i++) {
            if (weights[i] < _tokenWeights[i]) {
                uint sellAmount = (totalSupply() * uint(_tokenWeights[i] - weights[i])) / WEIGHT_FACTOR;
                if (_underlyingTokens[i] != address(_WBNB))
                    PancakeswapUtilities.sellToken(
                        _underlyingTokens[i],
                        address(_WBNB),
                        address(this),
                        sellAmount,
                        _pancakeRouter
                    );
                totalSale += sellAmount;
           }
        }
        uint totalSpent = 0;
        for (uint i = 0; i < weights.length; i++) {
            if (weights[i] > _tokenWeights[i]) {
                uint256 buyAmount = (totalSupply() * uint(weights[i] - _tokenWeights[i])) / WEIGHT_FACTOR;
                if (_underlyingTokens[i] == address(_WBNB)) {
                    totalSpent += buyAmount;
                    continue;
                }
                PancakeswapUtilities.buyToken(
                    address(_WBNB),
                    _underlyingTokens[i],
                    address(this),
                    buyAmount,
                    _pancakeRouter
                );
                totalSpent += buyAmount; 
            }
        }
        _tokenWeights = weights;
        int quoteAfter = int(getIndexQuote(1e18));
        require(
            quoteBefore - quoteAfter < quoteBefore / 50,
            "IndexPool: PRICE_LOSS_TOO_HIGH"
        );
    }

    /*
    ** If something's wrong with the LPs or anything else, anyone can
    ** withdraw the index underlying tokens directly to their wallets
    */
    function emergencyWithdraw() external nonReentrant {
        uint userBalance = this.balanceOf(msg.sender);

        for (uint i = 0; i < _underlyingTokens.length; i++) {
            uint entitledAmount = userBalance * _tokenWeights[i] / WEIGHT_FACTOR;
            ERC20 token = ERC20(_underlyingTokens[i]);
            uint indexBalance = token.balanceOf(address(this));
            // should never happen!
            if (indexBalance < entitledAmount)
                entitledAmount = indexBalance;
            token.transfer(msg.sender, entitledAmount);
        }
        _burn(msg.sender, userBalance);
    }
}