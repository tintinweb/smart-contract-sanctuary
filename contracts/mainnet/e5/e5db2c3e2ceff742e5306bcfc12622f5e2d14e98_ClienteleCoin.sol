/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Added function
    // 1 minute = 60
    // 1h 3600
    // 24h 86400
    // 1w 604800

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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

    constructor() internal {
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
        require(_status != _ENTERED, "nonReentrant:: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "isHuman:: sorry humans only");
        _;
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
        return 9;
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ClienteleCoin is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    //AMM swap settings
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    uint256 public liquidateTokensAtAmount = 1000 * (10**9);

    //Token info
    uint256 public constant TOTAL_SUPPLY = 137000000000000 * (10**9);

    //Transfer delay info
    bool public TDEnabled = false;
    uint256 public TD = 30 minutes;
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    mapping(address => uint256) private _soldTimes;
    mapping(address => uint256) private _boughtTimes;

    //Tax info
    bool _feesEnabled = true;
    uint256 public constant ETH_REWARDS_FEE = 25;
    uint256 public constant MARKETING_FEE = 25;
    uint256 public constant DEV_FEE = 25;
    uint256 public impactFee = 200;
    uint256 public constant TOTAL_FEES = ETH_REWARDS_FEE + MARKETING_FEE + DEV_FEE;
    address public devWallet = 0x395DA634618C39675b560Aa5d321966672D6DC71;
    address public marketingWallet = 0xD7F7e7C412824C6f4F107453068e7c8062B0B488;
    address private _airdropAddress = 0xAcfE101cA7E2bc9Ee6a76Deaa9Bc6C9DAb0b5481;

    mapping(address => bool) private _isExcludedFromFees;
    uint256 public impactThreshold = 50;
    bool public priceImpactFeeDisabled = true;

    // Claiming info
    mapping(address => uint256) public nextAvailableClaimDate;
    uint256 public rewardCycleBlock = 2 days;
    uint256 threshHoldTopUpRate = 2;

    bool private liquidating = false;

    event UpdatedUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event CycleBlockUpdated(uint256 indexed newBlock, uint256 indexed OldBlock);
    event ImpactFeeUpdated(uint256 indexed newFee, uint256 indexed oldFee);
    event ThresholdFeeUpdated(uint256 indexed newThreshold, uint256 indexed oldThreshold);
    event ImpactFeeDisableUpdated(bool indexed value);

    event LiquidationThresholdUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event TaxDistributed(uint256 tokensSwapped, uint256 ethReceived, uint256 rewardPoolGot, uint256 devGot, uint256 marketingGot);

    event ClaimSuccessfully(address recipient, uint256 ethReceived, uint256 nextAvailableClaimDate);

    constructor(address routerAddress) ERC20("ClienteleCoin", "CLT") {
        //set amm info
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner());
        excludeFromFees(address(this));

        // mint tokens
        _mint(owner(), TOTAL_SUPPLY);
    }

    receive() external payable {}

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "CLT: The router already has that address");
        emit UpdatedUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function enableFees() public onlyOwner {
        _feesEnabled = true;
    }

    function disableFees() public onlyOwner {
        _feesEnabled = false;
    }

    function updateliquidateTokensAtAmount(uint256 newValue) public onlyOwner {
        liquidateTokensAtAmount = newValue;
    }

    function updateAirdropAddress(address airdropAddress) public onlyOwner {
        _airdropAddress = airdropAddress;
    }

    function updateRewardCycleBlock(uint256 newBlock) public onlyOwner {
        emit CycleBlockUpdated(newBlock, rewardCycleBlock);
        rewardCycleBlock = newBlock;
    }

    function updateImpactThreshold(uint256 newValue) public onlyOwner {
        emit ThresholdFeeUpdated(newValue, impactThreshold);
        impactThreshold = newValue;
    }

    function updateImpactFee(uint256 newValue) public onlyOwner {
        emit ImpactFeeUpdated(newValue, impactFee);
        impactFee = newValue;
    }

    function updateImpactFeeDisabled(bool newValue) public onlyOwner {
        emit ImpactFeeDisableUpdated(newValue);
        priceImpactFeeDisabled = newValue;
    }

    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }

    function includeToFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function updateLiquidationThreshold(uint256 newValue) external onlyOwner {
        emit LiquidationThresholdUpdated(newValue, liquidateTokensAtAmount);
        liquidateTokensAtAmount = newValue;
    }

    function activateTD() external onlyOwner {
        TDEnabled = true;
    }

    function DisableTD() external onlyOwner {
        TDEnabled = false;
    }

    function setTDTime(uint256 delay) public onlyOwner returns (bool) {
        TD = delay; // in seconds
        return true;
    }

    function getPriceImpactFee(uint256 amount) public view returns (uint256) {
        if (priceImpactFeeDisabled) return 0;

        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 reserve0;
        uint256 reserve1;

        if (token0 == address(this)) {
            (reserve1, reserve0, ) = pair.getReserves();
        } else if (token1 == address(this)) {
            (reserve0, reserve1, ) = pair.getReserves();
        }

        if (reserve0 == 0 && reserve1 == 0) {
            // check liquidity has ever been added or not. if not, the function will return zero impact
            return 0;
        }

        uint256 amountB = uniswapV2Router.getAmountIn(amount, reserve0, reserve1);
        uint256 priceImpact = reserve0.sub(reserve0.sub(amountB)).mul(10000) / reserve0;

        if (priceImpact >= impactThreshold) {
            return impactFee;
        }

        return 0;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        //check if tx delay enabled, the sender should wait until the delay passess
        if (TDEnabled && !liquidating) {
            if (from == address(uniswapV2Pair)) {
                uint256 multiplier = _boughtTimes[to] == 1 ? 2 : 1;
                require(
                    (_holderLastTransferTimestamp[to].add(TD.mul(multiplier)) <= block.timestamp) || _isExcludedFromFees[to],
                    "_transfer:: Transfer Delay enabled.  Please try again after the tx block passess"
                );
                _holderLastTransferTimestamp[to] = block.timestamp;
                _boughtTimes[to] = _boughtTimes[to] + 1;
            } else if (to == address(uniswapV2Pair)) {
                uint256 multiplier = _soldTimes[from] == 1 ? 2 : 1;
                require(
                    (_holderLastTransferTimestamp[from].add(TD.mul(multiplier)) <= block.timestamp) || _isExcludedFromFees[from],
                    "_transfer:: Transfer Delay enabled.  Please try again after the tx block passess"
                );
                _holderLastTransferTimestamp[from] = block.timestamp;
                _soldTimes[to] = _soldTimes[to] + 1;
            } else {
                require(
                    (_holderLastTransferTimestamp[from].add(TD.mul(2)) <= block.timestamp) || _isExcludedFromFees[from],
                    "_transfer:: Transfer Delay enabled.  Please try again after the tx block passess"
                );
                _holderLastTransferTimestamp[from] = block.timestamp;
            }
        }

        //if tokens came from airdrop wallet, then add anti-dump transfer delay for recepients
        if (from == _airdropAddress) {
            _holderLastTransferTimestamp[to] = block.timestamp + 2 hours;
        }

        //check the contract balance > swap amount threshold,
        //then do it and distribute rewards to the reward pool, dev, markting wallet
        //distribution won't work in case a transfer is from uni
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= liquidateTokensAtAmount;
        if (canSwap && from != address(uniswapV2Pair)) swapAndDistributeRewards(contractTokenBalance);

        //fee is being taken only from buy/sells
        //also avoid fees on liquidation
        bool takeFee = false;
        if ((to == address(uniswapV2Pair) && !_isExcludedFromFees[from]) || (from == address(uniswapV2Pair) && !_isExcludedFromFees[to])) {
            takeFee = true;
        }

        if (liquidating) takeFee = false;

        //main fee taking logic
        if (takeFee && _feesEnabled) {
            //calculate fees and send amount
            uint256 rewardPoolAmount = amount.mul(ETH_REWARDS_FEE).div(1000);
            uint256 marketingAmount = amount.mul(MARKETING_FEE).div(1000);
            uint256 devAmount = amount.mul(DEV_FEE).div(1000);
            uint256 priceFee = getPriceImpactFee(amount.sub(rewardPoolAmount).sub(marketingAmount).sub(devAmount));
            uint256 impactFeeAmount = amount.mul(priceFee).div(1000);
            uint256 sendAmount = amount.sub(rewardPoolAmount).sub(marketingAmount).sub(devAmount);

            //avoid stack problem
            sendAmount = sendAmount.sub(impactFeeAmount);
            uint256 taxAmount = amount.sub(sendAmount);

            //check if fees and send amount are correct
            require(amount == sendAmount.add(taxAmount), "CLT::transfer: Tax value invalid");

            //transfer tax to the contract wallet
            super._transfer(from, address(this), taxAmount);

            //remained tokens will be transferred to the recipient
            amount = sendAmount;
        }

        //block
        topUpClaimCycleAfterTransfer(to, amount);

        super._transfer(from, to, amount);
    }

    function swapAndDistributeRewards(uint256 tokens) private {
        //NOTE: do smth with the correct part management

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        if (!liquidating) {
            liquidating = true;

            swapTokensForEth(tokens);

            // how much eth should we distribute
            uint256 newBalance = address(this).balance.sub(initialBalance);

            //split the contract balance into three parts
            uint256 toRewardPool = newBalance.div(3);
            uint256 toDevWallet = toRewardPool;
            uint256 toMarketingWallet = newBalance.sub(toDevWallet).sub(toRewardPool);

            //reward pool eth stay on the contract
            address(marketingWallet).call{value: toMarketingWallet}("");
            address(devWallet).call{value: toDevWallet}("");

            liquidating = false;
            emit TaxDistributed(tokens, newBalance, toRewardPool, toDevWallet, toMarketingWallet);
        }
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

    //to do add to claim cycle after receiving

    function calculateReward(address ofAddress) public view returns (uint256) {
        uint256 totalSupply = totalSupply().sub(balanceOf(address(0))).sub(balanceOf(0x000000000000000000000000000000000000dEaD)).sub(balanceOf(address(uniswapV2Pair))); // exclude burned wallets //and uni pair

        uint256 poolValue = address(this).balance;
        uint256 currentBalance = balanceOf(address(ofAddress));
        uint256 reward = poolValue.mul(currentBalance).div(totalSupply);

        return reward;
    }

    function claimReward() public isHuman nonReentrant {
        require(nextAvailableClaimDate[msg.sender] <= block.timestamp, "Error: next available not reached");
        require(balanceOf(msg.sender) >= 0, "Error: must own token to claim reward");

        uint256 reward = calculateReward(msg.sender);

        // update rewardCycleBlock
        nextAvailableClaimDate[msg.sender] = block.timestamp + rewardCycleBlock;
        emit ClaimSuccessfully(msg.sender, reward, nextAvailableClaimDate[msg.sender]);

        (bool sent, ) = address(msg.sender).call{value: reward}("");
        require(sent, "Error: Cannot withdraw reward");
    }

    function topUpClaimCycleAfterTransfer(address recipient, uint256 amount) private {
        uint256 currentRecipientBalance = balanceOf(recipient);
        uint256 additionalBlock = 0;
        if (nextAvailableClaimDate[recipient] + rewardCycleBlock < block.timestamp) nextAvailableClaimDate[recipient] = block.timestamp;

        //if a user has zero balance, just regular rewardCycleBlock will be applied
        if (currentRecipientBalance > 0) {
            uint256 rate = amount.mul(100).div(currentRecipientBalance);
            if (uint256(rate) >= threshHoldTopUpRate) {
                uint256 incurCycleBlock = rewardCycleBlock.mul(uint256(rate)).div(100);
                if (incurCycleBlock >= rewardCycleBlock) {
                    incurCycleBlock = rewardCycleBlock;
                }
                additionalBlock = incurCycleBlock;
            }
        } else {
            nextAvailableClaimDate[recipient] = nextAvailableClaimDate[recipient] + rewardCycleBlock;
        }
        nextAvailableClaimDate[recipient] = nextAvailableClaimDate[recipient] + additionalBlock;
    }
}