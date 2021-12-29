/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
        _balances[sender] = senderBalance - amount;
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
        _balances[account] = accountBalance - amount;
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
        require(b <= a, errorMessage);
        return a - b;
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract AddressStorage {
    mapping(bytes32 => address) private _addresses;

    function getAddress(bytes32 key) public view returns (address) {
        address result = _addresses[key];
        require(result != address(0), "AddressStorage: Address not found");
        return result;
    }

    function _setAddress(bytes32 key, address value) internal {
        _addresses[key] = value;
    }

}

contract AddressRepository is Ownable, AddressStorage {
    // Repositories & services
    bytes32 private constant POOL_REPOSITORY = "POOL_REPOSITORY";
    bytes32 private constant POSITION_REPOSITORY = "POSITION_REPOSITORY";
    bytes32 private constant PRICE_REPOSITORY = "PRICE_REPOSITORY";

    // External swap services
    bytes32 private constant UNISWAP_ROUTER = "UNISWAP_ROUTER";

    /**
     * @dev returns the address of the LendingPool proxy
     * @return the lending pool proxy address
     **/

    function getPoolRepository() public view returns (address) {
        return getAddress(POOL_REPOSITORY);
    }

    function setPoolRepository(address _address) public onlyOwner {
        _setAddress(POOL_REPOSITORY, _address);
    }

    function getPositionRepository() public view returns (address) {
        return getAddress(POSITION_REPOSITORY);
    }

    function setPositionRepository(address _address) public onlyOwner {
        _setAddress(POSITION_REPOSITORY, _address);
    }

    function getPriceRepository() public view returns (address) {
        return getAddress(PRICE_REPOSITORY);
    }

    function setPriceRepository(address _address) public onlyOwner {
        _setAddress(PRICE_REPOSITORY, _address);
    }

    function getUniswapRouter() public view returns (address) {
        return getAddress(UNISWAP_ROUTER);
    }

    function setUniswapRouter(address _address) public onlyOwner {
        _setAddress(UNISWAP_ROUTER, _address);
    }




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
    ) external  returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external  returns (uint amountETH);

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
    ) external  payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external override pure returns (address);
    function WETH() external override pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external override 
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external override 
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external override 
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external override 
    payable 
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external override pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external override pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external override pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external override view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external override view returns (uint[] memory amounts);


}

contract LPToken is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {

    }

    function mint(address to, uint256 amount ) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount ) external onlyOwner {
        _burn(to, amount);
    }
}

contract PriceModel {
    using SafeMath for uint256;

    uint256 constant U_OPTIMAL = 80;
    uint256 constant R_BASE = 0;
    uint256 constant R_SLOPE1 = 4;
    uint256 constant R_SLOPE2 = 75;
    uint256 constant S_1 = 1e18;

    function getInterestParameters()
    external
    pure
    returns (
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        return (U_OPTIMAL, R_BASE, R_SLOPE1, R_SLOPE2);
    }

    uint256 private _cumulativeIndex;
    uint256 private _currentBorrowRate;
    uint256 private _cumulativeIndexLastUpdate;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /// NEEDS PARAMS
    function _calcBorrowRate_S1(uint256 totalLiquidity, uint256 availableLiquidity) internal pure returns (uint256) {
        uint256 U_OPTIMAL_S1 = U_OPTIMAL.mul(S_1);
        uint256 R_BASE_S1 = R_BASE.mul(S_1);
        uint256 R_SLOPE1_S1 = R_SLOPE1.mul(S_1);

        if (totalLiquidity == 0) {
            return 0;
        }

        uint256 utilisationRate_s1 =
        totalLiquidity.sub(availableLiquidity).mul(S_1).mul(100).div(totalLiquidity);
        if (utilisationRate_s1 < U_OPTIMAL_S1) {
            return
            utilisationRate_s1.mul(R_SLOPE1).div(U_OPTIMAL).add(R_BASE_S1);
        }

        return
        utilisationRate_s1
        .sub(U_OPTIMAL_S1)
        .mul(R_SLOPE2)
        .div(100 - U_OPTIMAL)
        .add(R_BASE_S1)
        .add(R_SLOPE1_S1);
    }

    function calcLinearCumulative_S1() public view returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference =
        block.timestamp.sub(uint256(_cumulativeIndexLastUpdate));

        return calcLinearIndex(timeDifference);
    }

    function calcLinearIndex(uint256 timeDifference)
    public
    view
    returns (uint256)
    {
        uint256 linearAccumulated_S1 =
        _currentBorrowRate.mul(timeDifference).div(SECONDS_PER_YEAR).add(
            S_1
        );

        return _cumulativeIndex.mul(linearAccumulated_S1).div(S_1);
    }

    function getCumulativeIndex() external view returns (uint256) {
        return _cumulativeIndex;
    }

    /// NEEDS PARAMS
    function _updateCumIndexByLiquidity(uint256 totalLiquidity, uint256 availableLiquidity) internal {
        uint256 newCIndex = calcLinearCumulative_S1();

        // Update cumulativeIndex
        _updateCumulativeIndex(newCIndex);

        // update borrow rate
        _currentBorrowRate = _calcBorrowRate_S1(totalLiquidity, availableLiquidity);
    }

    function _updateCumulativeIndex(uint256 value) internal {
        _cumulativeIndex = value;
        _cumulativeIndexLastUpdate = block.timestamp;
    }
}

contract VaultService is PriceModel, Ownable {
    //!!!!!!!! Check befor deploy !!!!!!!!
    // Not more then 100 units  of underline token(see decimals) 
    uint256 constant MAX_DEPOSIT = 100000e18;
    using SafeMath for uint256;


    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Liquidity parameters
    uint256 private _totalLiquidity;
    uint256 private _availableLiquidity;

    /// @dev Token address for vault asset
    address private _underlyingTokenAddress;

    // Repositories
    AddressRepository private _addressRepository;
    LPToken private _lpToken;

    // Swap operators
    IUniswapV2Router02 private _uniswapRouter;

    mapping(address => bool) private _poolServices;

    // Liquidity pool
    event AddLiquidity(address indexed sender, uint256 amount);
    event RemoveLiquidity(address indexed sender, uint256 amount);

    constructor(address addressRepository,
        address underlyingTokenAddress,
        address gToken) {
        _addressRepository = AddressRepository(addressRepository);
        _lpToken = LPToken(gToken);
        _underlyingTokenAddress = underlyingTokenAddress;
        _uniswapRouter = IUniswapV2Router02(
            _addressRepository.getUniswapRouter()
        );

        approveOnUniswap(_underlyingTokenAddress);
        _updateCumulativeIndex(S_1);
    }
    
    modifier onlyPoolService() {
        require(_poolServices[msg.sender], "Allowed for pool services only");
        _;
    }

    function addToPoolServicesList(address poolService) external onlyOwner{
        _poolServices[poolService] = true;
    }

    function approveOnUniswap(address token) public onlyOwner {
        ERC20(token).approve(address(_uniswapRouter), MAX_INT);
    }

    // Add liquidity to vault
    function addLiquidity(uint256 amount) external {
        require(amount < MAX_DEPOSIT, "NOT MORE in TESTS");
        ERC20(_underlyingTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        _lpToken.mint(msg.sender, amount);
        _totalLiquidity = _totalLiquidity.add(amount);
        _availableLiquidity = _availableLiquidity.add(amount);
        _updateCumIndexByLiquidity(_totalLiquidity, _availableLiquidity);
        emit AddLiquidity(msg.sender, amount);
    }

    function removeLiquidity(uint256 amount) external {
        ERC20(_underlyingTokenAddress).transfer(msg.sender, amount);
        _lpToken.burn(msg.sender, amount);
        _totalLiquidity = _totalLiquidity.sub(amount);
        _availableLiquidity = _availableLiquidity.sub(amount);
        _updateCumIndexByLiquidity(_totalLiquidity, _availableLiquidity);
        emit RemoveLiquidity(msg.sender, amount);
    }

    function updateLeverageOpen(
        address holder,
        uint256 amount,
        uint256 leveragedAmount
    ) external onlyPoolService {
        require(leveragedAmount < _availableLiquidity, "Not enough liquidity");
        ERC20(_underlyingTokenAddress).transferFrom(holder, address(this), amount);
        _availableLiquidity = _availableLiquidity.add(amount).sub(
            leveragedAmount
        );
        _totalLiquidity = _totalLiquidity.add(amount);
        _updateCumIndexByLiquidity(_totalLiquidity, _availableLiquidity);
    }

    function updateOnLeverageClose(
        address holder,
        uint256 amountToReturn,
        uint256 backToVault,
        uint256 liquidatorPremium,
        address liquidatorAddress
    ) external onlyPoolService {
        ERC20(_underlyingTokenAddress).transfer(
            holder,
            amountToReturn
        );
        _totalLiquidity = _totalLiquidity.sub(amountToReturn);

        // Pay liquidator premium;
        if (liquidatorPremium > 0 && liquidatorAddress != address(0)) {
            ERC20(_underlyingTokenAddress).transfer(
                liquidatorAddress,
                liquidatorPremium
            );
            _totalLiquidity = _totalLiquidity.sub(liquidatorPremium);
        }

        // Update available liquidity
        _availableLiquidity = _availableLiquidity.add(backToVault);
        _updateCumIndexByLiquidity(_totalLiquidity, _availableLiquidity);
    }

    function getBalance(address token) external view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    /// SWAP PART

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwner {
        _uniswapRouter.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            deadline
        );
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwner {
        _uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
    }

    function getTotalLiquidity() external view returns (uint256) {
        return _totalLiquidity;
    }

    function getAvailableLiquidity() external view returns (uint256) {
        return _availableLiquidity;
    }

    function calcBorrowRate_S1() public view returns (uint256) {
        return _calcBorrowRate_S1(_totalLiquidity, _availableLiquidity);
    }

    function getUnderlyingToken() external view returns (address) {
        return _underlyingTokenAddress;
    }

    function getLPToken() external view returns (address) {
        return address(_lpToken);
    }

}

contract PoolACL is Ownable{

    mapping(address => bool) private _poolServices;

    modifier onlyPoolService() {
        require(_poolServices[msg.sender], "Allowed for pool services only");
        _;
    }

    function addToPoolServicesList(address poolService) external onlyOwner{
        _poolServices[poolService] = true;
    }
}

contract PositionRepository is Ownable, PoolACL {
    using SafeMath for uint256;

    struct Position {
        uint256 mainTokenAmount;
        uint256 leveragedTokenAmount;
        mapping(address => bool) tokensListMap;
        // Tokens which trader has
        // ToDo: move to ERC20 tokens
        mapping(address => uint256) tokensBalances;
        // cumulative index at open
        uint256 cumulativeIndexAtOpen;
        // Active is true if leverage is opened
        bool active;
        // Exists is true if leverage was created sometime
        bool exists;
        address[] tokensList;
    }

    mapping(address => address[]) private _traders;
    mapping(address => mapping(address => Position)) private _positions;

    modifier activePositionOnly(address trader) {
        require(
            _positions[msg.sender][trader].active,
            "Position doesn't not exists"
        );
        _;
    }

   modifier activePoolPositionOnly(address pool, address trader) {
        require(
            _positions[pool][trader].active,
            "Position doesn't not exists"
        );
        _;
    }

    function hasOpenPosition(address pool, address trader)
        external
        view
        returns (bool)
    {
        return _positions[pool][trader].active;
    }

    // Returns quantity of leverages holders
    function tradersCount(address pool) external view returns (uint256) {
        return _traders[pool].length;
    }

    // Returns trader address by id
    function getTraderById(address pool, uint256 id)
        external
        view
        returns (address)
    {
        return _traders[pool][id];
    }

    function getPositionDetails(address pool, address trader)
        external
        view
        returns (
            uint256 amount,
            uint256 leveragedAmount,
            uint256 cumulativeIndex
        )
    {
        Position storage _position = _positions[pool][trader];
        amount = _position.mainTokenAmount;
        leveragedAmount = _position.leveragedTokenAmount;
        cumulativeIndex = _position.cumulativeIndexAtOpen;
    }

    // @dev Opens leverage for trader
    function openPosition(
        address trader,
        address mainAsset,
        uint256 mainTokenAmount,
        uint256 leveragedTokenAmount,
        uint256 cumulativeIndex
    ) external onlyPoolService {
        address pool = msg.sender;
        // Check that trader doesn't have open leverages
        require(!_positions[pool][trader].active, "Position is already opened");

        // Add trader to list if he creates leverage first time
        if (!_positions[pool][trader].exists) {
            _traders[pool].push(trader);
        } else {}

        address[] memory emptyArray;

        _positions[pool][trader].mainTokenAmount = mainTokenAmount;
        _positions[pool][trader].leveragedTokenAmount = leveragedTokenAmount;
        _positions[pool][trader].cumulativeIndexAtOpen = cumulativeIndex;
        _positions[pool][trader].tokensList = emptyArray;
        _positions[pool][trader].active = true;
        _positions[pool][trader].exists = true;

        _updateLeverageToken(pool, trader, mainAsset, leveragedTokenAmount);
    }

    function closePosition(address trader)
        external
        onlyPoolService
        activePositionOnly(trader)
    {
        address pool = msg.sender;
        for (uint256 i = 0; i < getTokenListCount(pool, trader); i++) {
            (address token, ) = getTokenById(pool, trader, i);
            delete _positions[pool][trader].tokensListMap[token];
            delete _positions[pool][trader].tokensBalances[token];
        }
        _positions[pool][trader].active = false;
    }

    function swapAssets(
        address trader,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    ) external onlyPoolService activePositionOnly(trader) {
        address pool = msg.sender;
        require(
            _positions[pool][trader].tokensBalances[tokenIn] >= amountIn,
            "Insufficient funds"
        );

        _updateLeverageToken(
            pool,
            trader,
            tokenIn,
            _positions[pool][trader].tokensBalances[tokenIn].sub(amountIn)
        );
        _updateLeverageToken(
            pool,
            trader,
            tokenOut,
            _positions[pool][trader].tokensBalances[tokenOut].add(amountOut)
        );
    }

    function getTokenListCount(address pool, address trader)
        public
        view
        activePoolPositionOnly(pool, trader)
        returns (uint256)
    {
        return _positions[pool][trader].tokensList.length;
    }

    function getTokenById(
        address pool,
        address trader,
        uint256 id
    ) public view activePoolPositionOnly(pool, trader) returns (address, uint256) {
        address tokenAddr = _positions[pool][trader].tokensList[id];
        uint256 amount = _positions[pool][trader].tokensBalances[tokenAddr];
        return (tokenAddr, amount);
    }

    // @dev updates leverage token balances
    function _updateLeverageToken(
        address pool,
        address trader,
        address token,
        uint256 amount
    ) internal activePoolPositionOnly(pool, trader) {
        if (!_positions[pool][trader].tokensListMap[token]) {
            _positions[pool][trader].tokensListMap[token] = true;
            _positions[pool][trader].tokensList.push(token);
        }

        _positions[pool][trader].tokensBalances[token] = amount;
    }
}

interface IPriceRepository {

    function addPriceFeed(address token1,
        address token2,
        address priceFeedContract) external;

    function getLastPrice(address token1, address token2) external view returns (uint256);

}
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract PriceRepository is Ownable, IPriceRepository, PoolACL {
    using SafeMath for uint256;

    mapping(address => mapping(address => AggregatorV3Interface)) _oracles;

    // And new source of prices for tokens
    function addPriceFeed(address token1,
        address token2,
        address priceFeedContract) external override onlyPoolService {
        _oracles[token1][token2] = AggregatorV3Interface(priceFeedContract);
    }

    function getLastPrice(address token1, address token2) external view override returns (uint256) {
        if (token1 == token2) return 1;

        require(address(_oracles[token1][token2]) != address(0), "Oracle doesn't exists");

        (,int price,,,) = _oracles[token1][token2].latestRoundData();


        return uint256(price);


    }
}

contract PoolService is Ownable {
    //!!!!!!!! Check befor deploy !!!!!!!!
    // Not more then 100 units  of underline token(see decimals) 
    uint256 constant MAX_DEPOSIT = 100000e18;

    using SafeMath for uint256;
    uint256 constant X_LEVERAGE = 4;
    uint256 constant S_1 = 1e18;
    uint256 constant LEVERAGE_CUT = 10;

    /// @dev Token address for vault asset
    address private _underlyingTokenAddress;


    mapping(address => bool) private _liquidatePositionList;
    mapping(address => bool) _allowedTokens;
    address[] _allowedTokensList;

    // Repositories
    AddressRepository private _addressRepository;
    PositionRepository private _PositionRepository;
    IPriceRepository private _priceRepository;

    // Tokens
    VaultService private _vaultService;
    LPToken private _lpToken;

    // Risk Level
    bool private _isHighRisk;

    // Leverage events
    event OpenLeverage(address indexed sender, uint256 amount);
    event CloseLeverage(address indexed sender, uint256 collateral, uint256 debt, uint256 currentBalance, uint256 apr);
    event LiquidateLeverage(address indexed sender, address indexed liquidator, uint256 collateral, uint256 debt, uint256 currentBalance, uint256 apr);

    constructor(address addressRepository, address vault, bool isHighRisk) {
        // Repositories & services
        _addressRepository = AddressRepository(addressRepository);
        _PositionRepository = PositionRepository(
            _addressRepository.getPositionRepository()
        );
        _priceRepository = IPriceRepository(
            _addressRepository.getPriceRepository()
        );
        _vaultService = VaultService(vault);

        // Tokens init
        _lpToken = LPToken(_vaultService.getLPToken());
        _underlyingTokenAddress = _vaultService.getUnderlyingToken();

        _allowedTokens[_underlyingTokenAddress] = true;
        _allowedTokensList.push(_underlyingTokenAddress);

        _isHighRisk = isHighRisk;
    }

    modifier onlyLiquidatePosition() {
        require(_liquidatePositionList[msg.sender], "Allowed for who can liquidate position only");
        _;
    }

    function setLiquidatorStatus(address addr, bool status) external onlyOwner {
        _liquidatePositionList[addr] = status;
    }

    function allowTokenForTrading(address token, address priceFeedContract) external onlyOwner {
        require(token != address(0), "0x0 address is not allowed");
        require(priceFeedContract != address(0), "0x0 pricefeed address is not allowed");

        _vaultService.approveOnUniswap(token);
        _priceRepository.addPriceFeed(token, _underlyingTokenAddress, priceFeedContract);
        _allowedTokens[token] = true;

        bool notExistToken = true;
        for (uint256 i = 0; i < _allowedTokensList.length; i++) {
            if (_allowedTokensList[i] == token) {
                notExistToken = false;
            }
        }

        if (notExistToken) {
            _allowedTokensList.push(token);
        }
    }

    function allowedTokenCount() external view returns (uint256) {
        return _allowedTokensList.length;
    }

    function allowedTokenById(uint256 id) external view returns (address) {
        return _allowedTokensList[id];
    }

    function hasOpenPosition() external view returns (bool) {
        return _PositionRepository.hasOpenPosition(address(this), msg.sender);
    }

    function disallowTokenForTrading(address token) external onlyOwner {
        require(
            token != _underlyingTokenAddress,
            "You cant disallow base vault token"
        );

        _allowedTokens[token] = false;

        bool existToken = false;
        uint256 indexToken = _allowedTokensList.length - 1;
        for (uint256 i = 0; i < _allowedTokensList.length; i++) {
            if (_allowedTokensList[i] == token) {
                existToken = true;
                indexToken = i;
            }
        }
        if (existToken) {
            if (indexToken != _allowedTokensList.length - 1) {
                _allowedTokensList[indexToken] = _allowedTokensList[_allowedTokensList.length - 1];
            }
            _allowedTokensList.pop();
        }
    }

    // open Leverage for client
    function openPosition(uint256 amount) external {
        require(amount < MAX_DEPOSIT, "NOT MORE in TESTS");
        // move tokens to vault
        uint256 leveragedAmount = amount.mul(X_LEVERAGE);
        uint256 ci = _vaultService.calcLinearCumulative_S1();
        _vaultService.updateLeverageOpen(msg.sender, amount, leveragedAmount);
        _PositionRepository.openPosition(
            msg.sender,
            _underlyingTokenAddress,
            amount,
            leveragedAmount,
            ci
        );
        emit OpenLeverage(msg.sender, amount);
    }

    function closePosition() external {
        (uint256 collateral, uint256 debt, uint256 currentBalance, uint256 apr) = _infoClosePosition(msg.sender);

        _closePosition(msg.sender, address(0));
        emit CloseLeverage(msg.sender, collateral, debt, currentBalance, apr);
    }

    // @dev liquidate leverage if it meets required conditions
    // and return premium for liquidator
    function liquidatePosition(address holder) external onlyLiquidatePosition {
        (uint256 collateral, uint256 debt, uint256 currentBalance, uint256 apr) = _infoClosePosition(holder);

        _closePosition(holder, msg.sender);
        emit LiquidateLeverage(holder, msg.sender, collateral, debt, currentBalance, apr);
    }

    function _infoClosePosition(address holder) public view returns (uint256, uint256, uint256, uint256) {
        (uint256 collateral, uint256 debt, ) = _PositionRepository.getPositionDetails(address(this), holder);
        uint256 currentBalance = calcPositionBalance(holder);
        uint256 apr = _vaultService.calcBorrowRate_S1();
        return (collateral, debt, currentBalance, apr);
    }

    function _closePosition(address holder, address liquidator) internal {
        uint256 balanceBeforeSale =
            _vaultService.getBalance(_underlyingTokenAddress);

        uint256 underlyingAssetAmount = _saleAllTokensExceptVaultToken(holder);

        (uint256 amount, uint256 leveragedAmount, ) =
            _PositionRepository.getPositionDetails(address(this), holder);

        uint256 totalBalanceInVaultTokens =
            _vaultService.getBalance(_underlyingTokenAddress).add(underlyingAssetAmount).sub(balanceBeforeSale);

        uint256 amountInterested = calcAmountInterested(holder);

        // Amount which should be pushed back to pool
        uint256 backToVault = leveragedAmount.add(amountInterested).sub(amount);
        uint256 amountToReturn = totalBalanceInVaultTokens.sub(backToVault);

        uint256 liquidationPremium;
        
        if (liquidator == address(0)) {
            liquidationPremium = 0;
        } else {
            liquidationPremium = leveragedAmount.mul(LEVERAGE_CUT).div(100);
            if (liquidationPremium > amountToReturn) {
                liquidationPremium = amountToReturn;
            }
        }

        amountToReturn = amountToReturn.sub(liquidationPremium);

        // Vault move tokens to holder
        _vaultService.updateOnLeverageClose(
            holder,
            amountToReturn,
            backToVault,
            liquidationPremium,
            liquidator
        );
        // Closing leverage in repository
        _PositionRepository.closePosition(holder);
    }

    function _saleAllTokensExceptVaultToken(address holder) internal returns (uint256) {
        uint256 tokensCount = _PositionRepository.getTokenListCount(address(this), holder);
        uint256 underlying = 0;
        for (uint256 i = 0; i < tokensCount; i++) {
            (address addr, uint256 amount) =
                _PositionRepository.getTokenById(address(this), holder, i);
            if (addr != _underlyingTokenAddress) {
                // Sell on vault
                address[] memory path = new address[](2);
                path[0] = addr;
                path[1] = _underlyingTokenAddress;

                uint256 deadline = block.timestamp + 1;
                _vaultService.swapExactTokensForTokens(
                    amount,
                    0,
                    path,
                    deadline
                );
            } else {
                underlying = amount;
            }
        }
        return underlying;
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external {
        address tokenIn = path[0];
        require(_allowedTokens[tokenIn], "This token is not allowed");

        address tokenOut = path[path.length - 1];
        require(_allowedTokens[tokenOut], "This token is not allowed");

        // store balances before swap
        uint256 balanceInBefore = _vaultService.getBalance(tokenIn);
        uint256 balanceOutBefore = _vaultService.getBalance(tokenOut);

        // swapTokens
        _vaultService.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            deadline
        );

        // compute changes in balances
        uint256 amountInSpent =
            balanceInBefore.sub(_vaultService.getBalance(tokenIn));
        uint256 amountOutGot =
            _vaultService.getBalance(tokenOut).sub(balanceOutBefore);

        // update stored balances with differences
        _PositionRepository.swapAssets(
            msg.sender,
            tokenIn,
            amountInSpent,
            tokenOut,
            amountOutGot
        );
    }

    function calcPositionBalance(address holder) public view returns (uint256) {
        uint256 total = 0;
        uint256 tokensCount = _PositionRepository.getTokenListCount(address(this), holder);

        for (uint256 i = 0; i < tokensCount; i++) {
            (address addr, uint256 amount) =
                _PositionRepository.getTokenById(address(this), holder, i);

            uint256 price =
                _priceRepository.getLastPrice(addr, _underlyingTokenAddress);

            uint256 tokenValueInVaultCurrency = price.mul(amount);

            total = total.add(tokenValueInVaultCurrency);
        }
        return total;
    }

    function calcAmountInterested(address holder)
        public
        view
        returns (uint256)
    {
        uint256 current_cumulative_index =
            _vaultService.calcLinearCumulative_S1();

        (uint256 amount, uint256 leveragedAmount, uint256 ciAtOpen) =
            _PositionRepository.getPositionDetails(address(this), holder);

        uint256 amountBorrowed = leveragedAmount - amount;
        return amountBorrowed.mul(current_cumulative_index).div(ciAtOpen).div(S_1);
    }

    function calcPositionCoverage_S1(address holder)
        public
        view
        returns (uint256)
    {
        (, uint256 leveragedAmount, ) =
            _PositionRepository.getPositionDetails(address(this), holder);

        uint256 amountInterested = calcAmountInterested(holder);
        uint256 balance = calcPositionBalance(holder);
        return balance.sub(amountInterested).mul(S_1).div(leveragedAmount);
    }

    function getVaultService() external view returns (address) {
        return address (_vaultService);
    }

    function getPositionDetails(address holder) external view returns (uint256, uint256) {
        (uint256 amount, uint256 leveragedAmount, ) =
        _PositionRepository.getPositionDetails(address(this), holder);
        return (amount, leveragedAmount);
    }

    function getPositionTokensCount(address trader) external view returns (uint256) {
        return  _PositionRepository.getTokenListCount(address(this), trader);
    }

    function getPositionTokensById(address trader, uint256 id) external view returns (address, uint256) {
        return  _PositionRepository.getTokenById(address(this), trader, id);
    }

    function getRiskLevel() external view returns (bool) {
        return _isHighRisk;
    }
}