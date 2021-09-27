/**
 *Submitted for verification at BscScan.com on 2021-08-20
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;



import "./WexRefferal.sol";


pragma solidity >=0.6.0 <0.8.0;

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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts\libs\BEP20.sol

// Adding-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }
}

// File: node_modules\@uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

pragma solidity >=0.6.2;

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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: contracts\WedexToken.sol

// Adding-Identifier: MIT

pragma solidity 0.6.12;

// Wedex with Governance.
contract Wedex is BEP20 {
    // Transfer tax rate in basis points. (default 5%)
    uint16 public transferTaxRate = 500;
    // Burn rate % of transfer tax. (default 20% x 5% = 1% of total amount).
    uint16 public burnRate = 20;
    // Max transfer tax rate: 10%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    // Burn address
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    // Max transfer amount rate in basis points. (default is 0.5% of total supply)
    uint16 public maxTransferAmountRate = 500;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = false;
    // Lock the token until presale end
    bool public presaleUnlocked = false;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _presaleLocked;
    // Min amount to liquify. (default 500 Wedex)
    uint256 public minAmountToLiquify = 500 ether;
    // The swap router, modifiable. Will be changed to Wedex's router when our own AMM release
    IUniswapV2Router02 public wedexSwapRouter;
    // The trading pair
    address public wedexSwapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;

    // The operator can only update the transfer tax rate
    address private _operator;
    // The operator can only update the transfer tax rate
    address private _minter;
    //addd

    // Events
    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );
    event TransferTaxRateUpdated(
        address indexed operator,
        uint256 previousRate,
        uint256 newRate
    );
    event BurnRateUpdated(
        address indexed operator,
        uint256 previousRate,
        uint256 newRate
    );
    event MaxTransferAmountRateUpdated(
        address indexed operator,
        uint256 previousRate,
        uint256 newRate
    );
    event SwapAndLiquifyEnabledUpdated(address indexed operator, bool enabled);
    event MinAmountToLiquifyUpdated(
        address indexed operator,
        uint256 previousAmount,
        uint256 newAmount
    );
    event WedexSwapRouterUpdated(
        address indexed operator,
        address indexed router,
        address indexed pair
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            "operator: caller is not the operator"
        );
        _;
    }
    modifier onlyMinter() {
        require(_minter == msg.sender, "operator: caller is not the minter");
        _;
    }
    modifier antiWhale(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false &&
                _excludedFromAntiWhale[recipient] == false
            ) {
                require(
                    amount <= maxTransferAmount(),
                    "WEDEX::antiWhale: Transfer amount exceeds the maxTransferAmount"
                );
            }
        }
        _;
    }

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree() {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @notice Constructs the WEDEX contract.
     */
    constructor() public BEP20("WEDEX TOKEN", "WEX") {
        _operator = _msgSender();
        _minter = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
        _excludedFromAntiWhale[owner()] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (WedexMaster).
    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of WEDEX
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override antiWhale(sender, recipient, amount) {
        // swap and liquify
        if (
            swapAndLiquifyEnabled == true &&
            _inSwapAndLiquify == false &&
            address(wedexSwapRouter) != address(0) &&
            wedexSwapPair != address(0) &&
            sender != wedexSwapPair &&
            sender != owner()
        ) {
            swapAndLiquify();
        }

        if (recipient == BURN_ADDRESS || transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 5% of every transfer
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
            uint256 burnAmount = taxAmount.mul(burnRate).div(100);
            uint256 liquidityAmount = taxAmount.sub(burnAmount);
            require(
                taxAmount == burnAmount + liquidityAmount,
                "WEDEX::transfer: Burn value invalid"
            );

            // default 95% of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(
                amount == sendAmount + taxAmount,
                "WEDEX::transfer: Tax value invalid"
            );

            super._transfer(sender, BURN_ADDRESS, burnAmount);
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 maxTransferAmount = maxTransferAmount();
        contractTokenBalance = contractTokenBalance > maxTransferAmount
            ? maxTransferAmount
            : contractTokenBalance;

        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = liquifyAmount.div(2);
            uint256 otherHalf = liquifyAmount.sub(half);

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half);

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add liquidity
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    /// @dev Swap tokens for BNB
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the WedexSWAP pair path of token -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wedexSwapRouter.WETH();

        _approve(address(this), address(wedexSwapRouter), tokenAmount);

        // make the swap
        wedexSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(wedexSwapRouter), tokenAmount);

        // add the liquidity
        wedexSwapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            operator(),
            block.timestamp
        );
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account)
        public
        view
        returns (bool)
    {
        return _excludedFromAntiWhale[_account];
    }

    function presaleLocked(address _account) public view returns (bool) {
        return _presaleLocked[_account];
    }

    // To receive BNB from WedexSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate)
        public
        onlyOperator
    {
        require(
            _transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE,
            "WEDEX::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate."
        );
        emit TransferTaxRateUpdated(
            msg.sender,
            transferTaxRate,
            _transferTaxRate
        );
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @dev Update the burn rate.
     * Can only be called by the current operator.
     */
    function updateBurnRate(uint16 _burnRate) public onlyOperator {
        require(
            _burnRate <= 100,
            "WEDEX::updateBurnRate: Burn rate must not exceed the maximum rate."
        );
        emit BurnRateUpdated(msg.sender, burnRate, _burnRate);
        burnRate = _burnRate;
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate)
        public
        onlyOperator
    {
        require(
            _maxTransferAmountRate <= 10000,
            "WEDEX::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate."
        );
        emit MaxTransferAmountRateUpdated(
            msg.sender,
            maxTransferAmountRate,
            _maxTransferAmountRate
        );
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Update the min amount to liquify.
     * Can only be called by the current operator.
     */
    function updateMinAmountToLiquify(uint256 _minAmount) public onlyOperator {
        emit MinAmountToLiquifyUpdated(
            msg.sender,
            minAmountToLiquify,
            _minAmount
        );
        minAmountToLiquify = _minAmount;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded)
        public
        onlyOperator
    {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOperator {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateWedexSwapRouter(address _router) public onlyOperator {
        wedexSwapRouter = IUniswapV2Router02(_router);
        wedexSwapPair = IUniswapV2Factory(wedexSwapRouter.factory()).getPair(
            address(this),
            wedexSwapRouter.WETH()
        );
        require(
            wedexSwapPair != address(0),
            "WEDEX::updateWedexSwapRouter: Invalid pair address."
        );
        emit WedexSwapRouterUpdated(
            msg.sender,
            address(wedexSwapRouter),
            wedexSwapPair
        );
    }

    // Recover lost BNB and send it to the treasury
    function recoverLostBNB() public onlyOperator {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    // Ensure requested tokens aren't users LP or RUSH tokens
    function recoverLostTokensExceptOurTokens(address _token, uint256 amount)
        public
        onlyOperator
    {
        require(_token != address(this), "Cannot recover WEDEX tokens");
        BEP20(_token).transfer(msg.sender, amount);
    }

    // After activating cannot lock again
    function activateTrading() public onlyOperator {
        presaleUnlocked = true;
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(
            newOperator != address(0),
            "WEDEX::transferOperator: new operator is the zero address"
        );
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

    function transferMinter(address newMinter) public onlyOperator {
        require(
            newMinter != address(0),
            "WEDEX::transferOperator: new operator is the zero address"
        );
        emit OperatorTransferred(_minter, newMinter);
        _minter = newMinter;
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "WEDEX::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "WEDEX::delegateBySig: invalid nonce"
        );
        require(now <= expiry, "WEDEX::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "WEDEX::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying Wedex (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "WEDEX::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
// File: contracts\WedexMaster.sol

// Adding-Identifier: MIT

pragma solidity 0.6.12;

// MasterChef is the master of Wedex. He can create new Wedex and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Wedex is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract WedexChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct DepositAmount {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 lockUntil;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        DepositAmount[] investments;
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 startInvestmentPosition; //The first position haven't withdrawed

        //
        // We do some fancy math here. Basically, any point in time, the amount of WEDEXES
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accWedexPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWedexPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 totalAmount; // Total amount in pool
        uint256 lastRewardBlock; // Last block number that WEDEX distribution occurs.
        uint256 accWedexPerShare; // Accumulated WEDEX per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds

        uint256 lockingPeriod;
        // uint256 instantReward;
        // uint256 tierReward;
        uint256 fixedApr;
        uint256 tokenType; // 0 for wex token, 1 for other token, 2 for stable lp token, 3 for other lp
        // uint256 totalAmount;

        address token1BusdLPaddress;
    }

    // The WEDEX TOKEN!
    Wedex public wedex;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    //busdAddress
    address public busdAddress = 0x55d398326f99059fF775485246999027B3197955;
    // uint256 public wedexPerBlock;
    // Bonus muliplier for early Wedex Holder.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Wedex mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Wedex referral contract address.
    WEXReferral public wedexReferral;
    uint256 public referDepth = 6;
    uint256[] public referralCommissionTier = [500,400,300,200];

    address public wexLPAddress;
    IUniswapV2Router02 public pancakeRouterV2 = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uint256 constant BLOCKS_PER_YEAR = 10512000;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmissionRateUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );
    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );

    constructor(
        Wedex _wedex,
        uint256 _startBlock,
        // uint256 _wedexPerBlock,
        address _wexLPAddress
    ) public {
        wedex = _wedex;
        startBlock = _startBlock;
        // wedexPerBlock = _wedexPerBlock;
        wexLPAddress = _wexLPAddress;

        devAddress = msg.sender;
        feeAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    //Modifier to prevent adding the pool with the same token - I don't know what could happen here.
    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        IBEP20 _lpToken,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        uint256 _lockingPeriod,
    	uint256 _fixedApr,
    	uint256 _tokenType,
        
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        // totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        
        address _token1BusdLpaddress = 0x0000000000000000000000000000000000000000;
        if(_tokenType==1){
            _token1BusdLpaddress = IUniswapV2Factory(pancakeRouterV2.factory()).getPair(
                address(_lpToken),
                busdAddress
            );
        }
        if(_tokenType==3){
            _token1BusdLpaddress = IUniswapV2Factory(pancakeRouterV2.factory()).getPair(
                IUniswapV2Pair(address(_lpToken)).token0(),
                busdAddress
            );
        }
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                lastRewardBlock: lastRewardBlock,
                accWedexPerShare: 0,
                depositFeeBP: _depositFeeBP,
                harvestInterval: _harvestInterval,
                lockingPeriod: _lockingPeriod,
                fixedApr: _fixedApr,
                tokenType: _tokenType,
                totalAmount: 0,
                token1BusdLPaddress: _token1BusdLpaddress
            })
        );
    }

    // Update the given pool's Wedex allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
    	uint256 _fixedApr,
    	uint256 _tokenType,
        
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "set: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "set: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
            
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].fixedApr = _fixedApr;
        poolInfo[_pid].tokenType = _tokenType;
        if(_tokenType==1){
            poolInfo[_pid].token1BusdLPaddress = IUniswapV2Factory(pancakeRouterV2.factory()).getPair(
                address(poolInfo[_pid].lpToken),
                busdAddress
            );
        }
        if(_tokenType==3){
            poolInfo[_pid].token1BusdLPaddress = IUniswapV2Factory(pancakeRouterV2.factory()).getPair(
                IUniswapV2Pair( address(poolInfo[_pid].lpToken)).token0(),
                busdAddress
            );
        }
        updatePool(_pid);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function getWexPrice() public view returns (uint256) {
        // wexLPAddress
        return IBEP20(busdAddress).balanceOf(wexLPAddress).div(wedex.balanceOf(wexLPAddress));
    }
    
    function getLPPrice(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        if(pool.tokenType == 0)
            return getWexPrice();
        if(pool.tokenType == 1)
            return IBEP20(busdAddress).balanceOf(pool.token1BusdLPaddress).div(IBEP20(pool.lpToken).balanceOf(pool.token1BusdLPaddress));
        if(pool.tokenType == 2)
            return IBEP20(busdAddress).balanceOf(address(pool.lpToken)).mul(2).div(pool.lpToken.totalSupply());
        return IBEP20(busdAddress).balanceOf(pool.token1BusdLPaddress).div(IBEP20(pool.lpToken).balanceOf(pool.token1BusdLPaddress)).mul(2).div(pool.lpToken.totalSupply());
    }

    // View function to see pending Wedex on frontend.
    function pendingWedex(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWedexPerShare = pool.accWedexPerShare;
        if (block.number > pool.lastRewardBlock) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            
            uint256 WedexReward = multiplier.mul(pool.fixedApr).mul(getLPPrice(_pid)).mul(1e12).div(getWexPrice()).div(BLOCKS_PER_YEAR.mul(100));

            accWedexPerShare = accWedexPerShare.add(WedexReward);
        }
        uint256 pending = user.amount.mul(accWedexPerShare).div(1e12).sub(
            user.rewardDebt
        );
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest Wedex.
    function canHarvest(uint256 _pid, address _user)
        public
        view
        returns (bool)
    {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.totalAmount == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        
        uint256 wedexReward = multiplier.mul(pool.fixedApr).mul(getLPPrice(_pid)).mul(pool.totalAmount).mul(1e12).div(BLOCKS_PER_YEAR.mul(100)).div(getWexPrice());

        wedex.mint(devAddress, wedexReward.div(1e12).div(10));
        wedex.mint(address(this), wedexReward.div(1e12));
        
        pool.accWedexPerShare = pool.accWedexPerShare.add(
            wedexReward.div(pool.totalAmount)
        );
        
        pool.lastRewardBlock = block.number;
    }
    
    function getLeader(address user) public view returns(address){
        (address referrer, bool vipBranch, uint256 leaderCommission) = wedexReferral.referrers(user);
        if(!vipBranch){
            return referrer;
        }
        return getLeader(referrer);
    }
    
    function getUpperVip(address user) public view returns(address) {
        address referrer = wedexReferral.getReferrer(user);
        while(!(wedexReferral.isVip(referrer) || referrer == address(0))){
            referrer = wedexReferral.getReferrer(referrer);
        }
        
        return referrer;
    }

    // Deposit LP tokens to MasterChef for Wedex allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer,
        bool _vipBranch,
        uint256 _leaderCommission
    ) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (
            address(wedexReferral) != address(0) &&
            _referrer != address(0) &&
            _referrer != msg.sender
        ) {
            wedexReferral.recordReferral(msg.sender, _referrer,_vipBranch,_leaderCommission);
        }

        payOrLockupPendingWedex(_pid);
        if (_amount > 0) {
             pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (address(wedexReferral) != address(0)) {
                (address referrer, bool vipBranch, uint256 leaderCommission) = wedexReferral.referrers(msg.sender);
                if (referrer != address(0)) {
                    wedexReferral.addTotalFund(referrer, _amount.mul(getLPPrice(_pid)), 0);
                    if(pool.lockingPeriod > 0){
                        payDirectCommission(_pid,_amount,vipBranch,leaderCommission,referrer);
                    }
                }
            }
            
            if (address(pool.lpToken) == address(wedex)) {
                uint256 transferTax = _amount.mul(wedex.transferTaxRate()).div(
                    10000
                );
                _amount = _amount.sub(transferTax);
            }
            
            if(pool.lockingPeriod > 0){
                user.investments.push(DepositAmount({
                    amount: _amount,
                    lockUntil: block.timestamp.add(pool.lockingPeriod)
                }));
            }

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                
                pool.totalAmount = pool.totalAmount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                
                pool.totalAmount = pool.totalAmount.add(_amount);
            }
            
        }
        user.rewardDebt = user.amount.mul(pool.accWedexPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
    function payDirectCommission(uint256 _pid,uint256 _amount, bool vipBranch, uint256 leaderCommission, address referrer) internal {
        uint256 lpPrice = getLPPrice(_pid);
        if(vipBranch){
            wedex.mint(
                address(referrer),
                _amount.mul(lpPrice).mul(uint256(10).div(1e2).sub(leaderCommission))
            );
            wedexReferral.recordReferralCommission(referrer,_amount.mul(lpPrice).mul(uint256(10).div(1e2).sub(leaderCommission)));
            wedex.mint(
                getLeader(msg.sender),
                _amount.mul(lpPrice).mul(leaderCommission).div(1e2)
            );
            wedexReferral.recordReferralCommission(
                getLeader(msg.sender),
                _amount.mul(lpPrice).mul(leaderCommission).div(1e2)
            );
            
        } else {
            wedex.mint(
                address(referrer),
                _amount.mul(7).div(1e2)
            );
            wedexReferral.recordReferralCommission(referrer,_amount.mul(7).div(1e2));
            address upperVip =  getUpperVip(msg.sender);
            if(upperVip!=address(0)){
                wedex.mint(
                    upperVip,
                    _amount.mul(3).div(1e2)
                );
                wedexReferral.recordReferralCommission(upperVip,_amount.mul(3).div(1e2));
            }
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "withdraw: not good");
        require(pool.lockingPeriod == 0, "withdraw: not good");

        updatePool(_pid);
        payOrLockupPendingWedex(_pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            if (
                address(wedexReferral) != address(0) &&
                wedexReferral.getReferrer(msg.sender) != address(0)
            ) {
                wedexReferral.reduceTotalFund(
                    wedexReferral.getReferrer(msg.sender),
                    _amount.mul(getLPPrice(_pid)),
                    0
                );
            }
        }
        user.rewardDebt = user.amount.mul(pool.accWedexPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawInvestment(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.lockingPeriod > 0, "withdraw: not good");

        updatePool(_pid);
        payOrLockupPendingWedex(_pid);

        uint _startInvestmentPosition = 0;
        uint256 _totalWithdrawalAmount = 0;

        for(uint i=user.startInvestmentPosition; i<user.investments.length;i++){
            if(user.investments[i].amount > 0 && user.investments[i].lockUntil <= block.timestamp){
                _totalWithdrawalAmount = _totalWithdrawalAmount.add(user.investments[i].amount);
                user.investments[i].amount = 0;
            } else {
                _startInvestmentPosition = i;
                break;
            }
        }

        if(_startInvestmentPosition > user.startInvestmentPosition){
            user.startInvestmentPosition = _startInvestmentPosition;
        }
        if(_totalWithdrawalAmount > 0 && _totalWithdrawalAmount <= user.amount){
            user.amount = user.amount.sub(_totalWithdrawalAmount);
            pool.totalAmount = pool.totalAmount.sub(_totalWithdrawalAmount);
            pool.lpToken.safeTransfer(address(msg.sender), _totalWithdrawalAmount);

            if (
                address(wedexReferral) != address(0) &&
                wedexReferral.getReferrer(msg.sender) != address(0)
            ) {
                wedexReferral.reduceTotalFund(
                    wedexReferral.getReferrer(msg.sender),
                    _totalWithdrawalAmount,
                    0
                );
            }
        }
        user.rewardDebt = user.amount.mul(pool.accWedexPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _totalWithdrawalAmount);
    }

    function getFreeInvestmentAmount(uint256 _pid) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _total = 0;

        for(uint i=user.startInvestmentPosition; i<user.investments.length;i++){
            if(user.investments[i].amount > 0 && user.investments[i].lockUntil <= block.timestamp){
                _total = _total.add(user.investments[i].amount);
            } else {
                break;
            }
        }

        return _total;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.lockingPeriod == 0, "withdraw: not good");
        uint256 amount = user.amount;
        user.amount = 0;
        pool.totalAmount = pool.totalAmount.sub(amount);
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        if (
            address(wedexReferral) != address(0) &&
            wedexReferral.getReferrer(msg.sender) != address(0)
        ) {
            wedexReferral.reduceTotalFund(
                wedexReferral.getReferrer(msg.sender),
                amount,
                0
            );
        }
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending Wedex.
    function payOrLockupPendingWedex(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accWedexPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(
                    pool.harvestInterval
                );

                // send rewards
                safeWedexTransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards, 0);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe Wedex transfer function, just in case if rounding error causes pool to not have enough Wedex to pay.
    function safeWedexTransfer(address _to, uint256 _amount) internal {
        uint256 wedexBal = wedex.balanceOf(address(this));
        if (_amount > wedexBal) {
            wedex.transfer(_to, wedexBal);
        } else {
            wedex.transfer(_to, _amount);
        }
    }

    function setreferDepth(uint256 _depth) public onlyOwner {
        referDepth = _depth;
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }
    
    function setPancakeRouterV2 (IUniswapV2Router02 _pancakeRouterV2) external
    {
        pancakeRouterV2 = _pancakeRouterV2;
    }
    function setBusdAdress (address _busdAddress) external
    {
        busdAddress = _busdAddress;
    }

    // Update the Wedex referral contract address by the owner
    function setWedexReferral(WEXReferral _wedexReferral) public onlyOwner {
        wedexReferral = _wedexReferral;
    }
    
    
    function getReferralCommissionRate(uint256 depth) private view returns (uint256){
        return referralCommissionTier[depth];
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(
        address _user,
        uint256 _pending,
        uint256 depth
    ) internal {
        if (address(wedexReferral) != address(0)) {
            address _referrer  = wedexReferral.getReferrer(_user);
            
            uint256 commissionAmount = _pending
                .mul(getReferralCommissionRate(depth))
                .div(10000);

            if (commissionAmount > 0) {
                wedex.mint(_referrer, commissionAmount);
                wedexReferral.recordReferralCommission(
                    _referrer,
                    commissionAmount
                );
            }
            
            emit ReferralCommissionPaid(_user, _referrer, commissionAmount);
            if (depth < referDepth) {
                payReferralCommission(
                    _referrer,
                    commissionAmount,
                    depth.add(1)
                );
            }
        }
    }
    
}