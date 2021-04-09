pragma solidity =0.6.6;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Pair.sol";
import "./Library.sol";

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _factory;
    address private _router;
    bool initialTokenGenerationFinish;

    constructor (address router, address factory) public {
        _name = "Ido Pad";
        _symbol = "IDO";
        _decimals = 18;
        _router = router;
        _factory = factory;
        initialTokenGenerationFinish = false;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function uniswapV2factory() public view returns (address) {
        return _factory;
    }
    function uniswapV2router() public view returns (address) {
        return _router;
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    bool public initialTokensGenerationFinish;
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
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    /**
     * This implementation is agnostic to the way tokens are created. 
     * This means that a supply mechanism has to be added in a derived contract.
     */
    function initialSupplyTokens (address Contract, uint256 initialSupply) public onlyOwner {
        require(initialTokenGenerationFinish == false);
        _totalSupply = _totalSupply.add(initialSupply);
        _balances[Contract] = _balances[Contract].add(initialSupply);
        initialTokensGenerationFinish = true;
    }
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
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
     * @dev Hook that is called before any transfer of tokens. 
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract IdoToken is ERC20 {
    using SafeMath for uint256;

    /// @notice dummy uniswap listing rate
    uint256 public constant INITIAL_TOKENS_PER_ETH = 100 * 1 ether;

    /// @notice max burn percentage
    uint256 public constant BURN_PCT = 48;

    /// @notice min burn percentage
    uint256 public constant MIN_BURN_PCT = 30;

    /// @notice WETH token address
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice self-explanatory
    address public uniswapV2Factory;
    
    address public uniswapV2Router;

    /// @notice uniswap pair for GEM/ETH
    address uniswapPair;

    /// @notice Whether or not this token is first in uniswap GEM<>ETH pair
    bool isThisToken0;

    /// @notice last TWAP update time
    uint32 blockTimestampLast;

    /// @notice last TWAP cumulative price
    uint256 priceCumulativeLast;

    /// @notice last TWAP average price
    uint256 priceAverageLast;

    /// @notice TWAP min delta (10-min)
    uint256 minDeltaTwap;

    event TwapUpdated(uint256 priceCumulativeLast, uint256 blockTimestampLast, uint256 priceAverageLast);

    constructor(
    ) 
    public
    Ownable()
    ERC20(uniswapV2Router, uniswapV2Factory)
    {
        _initializePair();
    }
 
    function _initializePair() internal {
        (address token0, address token1) = UniswapV2Library.sortTokens(address(this), address(WETH));
        isThisToken0 = (token0 == address(this));
        uniswapPair = UniswapV2Library.pairFor(uniswapV2Factory, token0, token1);
        
    }
    function _updateTwap() internal virtual returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed > minDeltaTwap) {
            uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
            );

            priceCumulativeLast = priceCumulative;
            blockTimestampLast = blockTimestamp;

            priceAverageLast = FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));

            emit TwapUpdated(priceCumulativeLast, blockTimestampLast, priceAverageLast);
        }

        return priceAverageLast;
    }

}