/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
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
   * https://github.com/ethereum/EIPs/ch/ef/in/u/20#issuecomment-263524729
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function allPairs(uint) external view returns (address lpPair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

interface AntiSnipe {
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _algo) external;
    function setGasPriceLimit(uint256 gas) external;
    function removeSniper(address account) external;
    function getSniperAmt() external view returns (uint256);
    function removeBlacklisted(address account) external;
    function isBlacklisted(address account) external view returns (bool);
    function setBlacklistEnabled(address account, bool enabled) external;
}

contract ChefInu is Context, IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private presaleAddresses;
    bool private allowedPresaleExclusion = true;
    mapping (address => bool) private _liquidityHolders;

    uint256 private startingSupply = 1_000_000_000;

    string constant private _name = "Chef Inu";
    string constant private _symbol = "CHEFI";

    struct FeesStruct {
        uint16 reflect;
        uint16 liquidity;
        uint16 marketing;
    }

    struct StaticValuesStruct {
        uint16 maxReflect;
        uint16 maxLiquidity;
        uint16 maxMarketing;
        uint16 masterTaxDivisor;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 marketing;
        uint16 total;
    }

    FeesStruct private currentTaxes = FeesStruct({
        reflect: 0,
        liquidity: 0,
        marketing: 0
        });

    FeesStruct public _buyTaxes = FeesStruct({
        reflect: 100,
        liquidity: 300,
        marketing: 500
        });

    FeesStruct public _sellTaxes = FeesStruct({
        reflect: 100,
        liquidity: 300,
        marketing: 500
        });

    FeesStruct public _transferTaxes = FeesStruct({
        reflect: 100,
        liquidity: 300,
        marketing: 500
        });

    Ratios public _ratios = Ratios({
        liquidity: 300,
        marketing: 500,
        total: 800
        });

    StaticValuesStruct public staticVals = StaticValuesStruct({
        maxReflect: 800,
        maxLiquidity: 800,
        maxMarketing: 800,
        masterTaxDivisor: 10000
        });

    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _tTotal = startingSupply * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    // PCS2 DEVNET ROUTER
    address constant private _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    // UNI ROUTER
    //address constant private _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address payable private _marketingWallet = payable(0xb91b37A1b175c770D8d048ab80f5Cd9A43d62470);
    
    bool inSwap;
    bool public contractSwapEnabled = false;

    uint256 private maxTPercent = 15;
    uint256 private maxTDivisor = 1000;
    uint256 private maxWPercent = 3;
    uint256 private maxWDivisor = 100;
    uint256 private _maxTxAmount = (_tTotal * maxTPercent) / maxTDivisor;
    uint256 public maxTxAmountUI = (startingSupply * maxTPercent) / maxTDivisor;
    uint256 private _maxWalletSize = (_tTotal * maxWPercent) / maxWDivisor;
    uint256 public maxWalletSizeUI = (startingSupply * maxWPercent) / maxWDivisor;

    uint256 private swapThreshold = (_tTotal * 5) / 10000;
    uint256 private swapAmount = (_tTotal * 5) / 1000;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    AntiSnipe antiSnipe;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event ContractSwapEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SniperCaught(address sniperAddress);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller =/= owner.");
        _;
    }
    
    constructor () payable {
        _rOwned[_msgSender()] = _rTotal;

        // Set the owner.
        _owner = msg.sender;

        _approve(msg.sender, _routerAddress, type(uint256).max);
        _approve(address(this), _routerAddress, type(uint256).max);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[owner()] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and recnouncements.
    // This allows for removal of ownership privelages from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
        if (_marketingWallet == payable(_owner))
            _marketingWallet = payable(newOwner);
        
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner() {
        setExcludedFromFees(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() public onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function setNewRouter(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
            antiSnipe.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "Cannot set a new pair this week!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            antiSnipe.setLpPair(pair, true);
        }
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_isExcluded[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else if (enabled == false) {
            require(_isExcluded[account], "Account is already included.");
            if(_excluded.length == 1){
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
            } else {
                for (uint256 i = 0; i < _excluded.length; i++) {
                    if (_excluded[i] == account) {
                        _excluded[i] = _excluded[_excluded.length - 1];
                        _tOwned[account] = 0;
                        _isExcluded[account] = false;
                        _excluded.pop();
                        break;
                    }
                }
            }
        }
    }

    function setInitializer(address initializer) external onlyOwner {
        require(!_hasLiqBeenAdded, "Liquidity is already in.");
        require(initializer != address(this), "Can't be self.");
        antiSnipe = AntiSnipe(initializer);
    }

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabled(account, enabled);
    }

    function removeSniper(address account) external onlyOwner {
        antiSnipe.removeSniper(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return antiSnipe.isBlacklisted(account);
    }

    function getSniperAmt() public view returns (uint256) {
        return antiSnipe.getSniperAmt();
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiSpecial) external onlyOwner {
        antiSnipe.setProtections(_antiSnipe, _antiSpecial);
    }
    
    function setTaxesBuy(uint16 reflect, uint16 liquidity, uint16 marketing) external onlyOwner {
        require(reflect <= staticVals.maxReflect
                && liquidity <= staticVals.maxLiquidity
                && marketing <= staticVals.maxMarketing);
        require(liquidity + reflect + marketing <= 3450);
        _buyTaxes.liquidity = liquidity;
        _buyTaxes.reflect = reflect;
        _buyTaxes.marketing = marketing;
    }

    function setTaxesSell(uint16 reflect, uint16 liquidity, uint16 marketing) external onlyOwner {
        require(reflect <= staticVals.maxReflect
                && liquidity <= staticVals.maxLiquidity
                && marketing <= staticVals.maxMarketing);
        require(liquidity + reflect + marketing <= 3450);
        _sellTaxes.liquidity = liquidity;
        _sellTaxes.reflect = reflect;
        _sellTaxes.marketing = marketing;
    }

    function setTaxesTransfer(uint16 reflect, uint16 liquidity, uint16 marketing) external onlyOwner {
        require(reflect <= staticVals.maxReflect
                && liquidity <= staticVals.maxLiquidity
                && marketing <= staticVals.maxMarketing);
        require(liquidity + reflect + marketing <= 3450);
        _transferTaxes.liquidity = liquidity;
        _transferTaxes.reflect = reflect;
        _transferTaxes.marketing = marketing;
    }

    function setRatios(uint16 liquidity, uint16 marketing) external onlyOwner {
        require (liquidity + marketing >= 99, "Must add up to 100% or 99%.");
        _ratios.liquidity = liquidity;
        _ratios.marketing = marketing;
        _ratios.total = liquidity + marketing;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = check;
        maxTxAmountUI = (startingSupply * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Max Wallet amt must be above 0.1% of total supply.");
        _maxWalletSize = check;
        maxWalletSizeUI = (startingSupply * percent) / divisor;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setWallets(address payable marketingWallet) external onlyOwner {
        _marketingWallet = payable(marketingWallet);
    }

    function setContractSwapEnabled(bool _enabled) public onlyOwner {
        contractSwapEnabled = _enabled;
        emit ContractSwapEnabledUpdated(_enabled);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    bool public pausedOnce;
    bool public oneTimePause;

    function pauseTrading(bool enabled) external onlyOwner {
        if(enabled){
            require(!pausedOnce, "Can only pause once.");
            oneTimePause = enabled;
            pausedOnce = true;
        } else {
            oneTimePause = enabled;
        }
    }

    function createLP() external onlyOwner {
        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!oneTimePause, "Trading is currently paused.");
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if(lpPairs[from] || lpPairs[to]){
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
            if(to != _routerAddress && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        if (lpPairs[to]) {
            if (!inSwap
                && contractSwapEnabled
                && !presaleAddresses[to]
                && !presaleAddresses[from]
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    contractSwap(contractTokenBalance);
                }
            }      
        } 
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function contractSwap(uint256 contractTokenBalance) private lockTheSwap {
        if (_ratios.total == 0)
            return;

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * _ratios.liquidity) / _ratios.total) / 2;

        uint256 toSwapForEth = contractTokenBalance - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwapForEth,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 liquidityBalance = ((address(this).balance * _ratios.liquidity) / _ratios.total) / 2;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                DEAD,
                block.timestamp
            );
            emit SwapAndLiquify(toLiquify, liquidityBalance, toLiquify);
        }
        if (contractTokenBalance - toLiquify > 0) {
            _marketingWallet.transfer(address(this).balance);
        }
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            if(address(antiSnipe) == address(0)){
                antiSnipe = AntiSnipe(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        setExcludedFromReward(address(this), true);
        setExcludedFromReward(lpPair, true);
        if(address(antiSnipe) == address(0)){
            antiSnipe = AntiSnipe(address(this));
        }
        try antiSnipe.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp)) {} catch {}
        tradingEnabled = true;
    }

    function sweepContingency() external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot call after liquidity.");
        payable(owner()).transfer(address(this).balance);
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;

        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
    }

    function _finalizeTransfer(address from, address to, uint256 tAmount, bool takeFee) private returns (bool) {
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                revert("Only owner can transfer at this time.");
            }
        }

        ExtraValues memory values = _getValues(from, to, tAmount, takeFee);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (_isExcluded[from] && !_isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;  
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }

        if (values.tLiquidity > 0)
            _takeLiquidity(from, values.tLiquidity);
        if (values.rFee > 0 || values.tFee > 0)
            _rTotal -= values.rFee;
            _tFeeTotal += values.tFee;

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function _getValues(address from, address to, uint256 tAmount, bool takeFee) private returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate();

        values.rAmount = tAmount * currentRate;

        if (_hasLimits(from, to)) {
            bool checked;
            try antiSnipe.checkUser(from, to, tAmount) returns (bool check) {
                checked = check;
            } catch {
                revert();
            }

            if(!checked) {
                revert();
            }
        }

        if(takeFee) {
            if (lpPairs[to]) {
                currentTaxes.reflect = _sellTaxes.reflect;
                currentTaxes.liquidity = _sellTaxes.liquidity;
                currentTaxes.marketing = _sellTaxes.marketing;
            } else if (lpPairs[from]) {
                currentTaxes.reflect = _buyTaxes.reflect;
                currentTaxes.liquidity = _buyTaxes.liquidity;
                currentTaxes.marketing = _buyTaxes.marketing;
            } else {
                currentTaxes.reflect = _transferTaxes.reflect;
                currentTaxes.liquidity = _transferTaxes.liquidity;
                currentTaxes.marketing = _transferTaxes.marketing;
            }

            values.tFee = (tAmount * currentTaxes.reflect) / staticVals.masterTaxDivisor;
            values.tLiquidity = (tAmount * (currentTaxes.liquidity + currentTaxes.marketing)) / staticVals.masterTaxDivisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tLiquidity);

            values.rFee = values.tFee * currentRate;
        } else {
            values.tFee = 0;
            values.tLiquidity = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }
        values.rTransferAmount = values.rAmount - (values.rFee + (values.tLiquidity * currentRate));
        return values;
    }

    function _getRate() internal view returns(uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return _rTotal / _tTotal;
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return _rTotal / _tTotal;
        return rSupply / tSupply;
    }

    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        _rOwned[address(this)] = _rOwned[address(this)] + (tLiquidity * _getRate());
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity); // Transparency is the key to success.
    }
}