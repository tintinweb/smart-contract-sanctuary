/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function skim(address to) external;
    function sync() external;
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


contract FastHands is Context, IERC20 {
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
   
    uint256 private startingSupply = 1_000_000_000_000_000;

    string constant private _name = "Fast Hands X";
    string constant private _symbol = "$FHX";
    uint8 private _decimals = 9;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = startingSupply * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));


    struct CurrentFees {
        uint16 reflect;
        uint16 totalSwap;
        uint16 burn;
    }

    struct Fees {
        uint16 reflect;
        uint16 liquidity;
        uint16 marketing;
        uint16 burn;
        uint16 dev1;
        uint16 dev2;
        uint16 totalSwap;
    }

    struct StaticValuesStruct {
        uint16 maxReflect;
        uint16 maxLiquidity;
        uint16 maxMarketing;
        uint16 maxBurn;
        uint16 maxDev1;
        uint16 maxDev2;
        uint16 masterTaxDivisor;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 marketing;
        uint16 dev1;
        uint16 dev2;
        uint16 total;
    }

    CurrentFees private currentTaxes = CurrentFees({
        reflect: 0,
        totalSwap: 0,
        burn: 0
        });

    Fees public _buyTaxes = Fees({
        reflect: 200,
        liquidity: 200,
        marketing: 300,
        burn: 100,
        dev1: 100,
        dev2: 100,
        totalSwap: 800
        });

    Fees public _sellTaxes = Fees({
        reflect: 200,
        liquidity: 200,
        marketing: 900,
        burn: 100,
        dev1: 100,
        dev2: 100,
        totalSwap: 1400
        });

    Fees public _transferTaxes = Fees({
        reflect: 0,
        liquidity: 0,
        marketing: 400,
        burn: 0,
        dev1: 200,
        dev2: 200,
        totalSwap: 800
        });

    Ratios public _ratios = Ratios({
        liquidity: 2,
        marketing: 3,
        dev1: 1,
        dev2: 1,
        total: 7
        });

    StaticValuesStruct public staticVals = StaticValuesStruct({
        maxReflect: 800,
        maxLiquidity: 800,
        maxMarketing: 800,
        maxBurn: 800,
        maxDev1: 800,
        maxDev2: 800,
        masterTaxDivisor: 10000
        });

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    address public currentRouter;
    // PCS ROUTER
    address private pcsV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // UNI ROUTER
    address private uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // KOFFEE ROUTER
    address private _routerAddress = 0xc0fFee0000C824D24E0F280f1e4D21152625742b;
    // TESTNET BUSD ADDY
    address TESTNET_BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address payable public _marketingWallet = payable(0x6D0b366129B54fdf2428DfA1edcAdf0922CE54Eb);
    address payable public _dev1Wallet = payable(0x80ea25751B4F407D7349A3F2384b37504eDC6740);
    address payable public _dev2Wallet = payable(0xFff1814d05218Eb88931458d71ec8e5871DcCcEF);
    
    bool inSwap;
    bool public contractSwapEnabled = true;

    uint256 private maxTBPercent = 3;
    uint256 private maxTBDivisor = 100;
    uint256 private maxTSPercent = 9;
    uint256 private maxTSDivisor = 1000;
    uint256 private maxWPercent = 3;
    uint256 private maxWDivisor = 100;

    uint256 private _maxTxAmountBuy = (_tTotal * maxTBPercent) / maxTBDivisor;
    uint256 public maxTxAmountUIBuy = (startingSupply * maxTBPercent) / maxTBDivisor;
    uint256 private _maxTxAmountSell = (_tTotal * maxTSPercent) / maxTSDivisor;
    uint256 public maxTxAmountUISell = (startingSupply * maxTSPercent) / maxTSDivisor;
    uint256 private _maxWalletSize = (_tTotal * maxWPercent) / maxWDivisor;
    uint256 public maxWalletSizeUI = (startingSupply * maxWPercent) / maxWDivisor;

    uint256 private swapThreshold = (_tTotal * 5) / 10000;
    uint256 private swapAmount = (_tTotal * 5) / 1000;

   
    bool public _hasLiqBeenAdded = false;

    mapping (address => uint256) private lastBuyTime;
    bool public doubleDayTradingTaxEnabled = true;
    uint256 public doubleDayTradingTaxTime = 24 hours;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event ContractSwapEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    
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

        if (block.chainid == 56 || block.chainid == 97) {
            currentRouter = pcsV2Router;
        } else if (block.chainid == 1) {
            currentRouter = uniswapV2Router;
        }

        dexRouter = IUniswapV2Router02(currentRouter);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;

        _approve(msg.sender, currentRouter, type(uint256).max);
        _approve(address(this), currentRouter, type(uint256).max);

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
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
   function owner() public view returns (address) {
        return _owner;
    }
    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
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

    

    function changeRouterContingency(address router) external onlyOwner {
        require(!_hasLiqBeenAdded);
        currentRouter = router;
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
            if(account != lpPair){
            _excluded.push(account);
            }
        } else if (enabled == false) {
            require(_isExcluded[account], "Account is already included.");
            if (account == lpPair) {	
                _rOwned[account] = _tOwned[account] * _getRate();	
                _tOwned[account] = 0;	
                _isExcluded[account] = false;
        } if(_excluded.length == 1){
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
            } else {
                for (uint256 i = 0; i < _excluded.length; i++) {
                    if (_excluded[i] == account) {
                        _excluded[i] = _excluded[_excluded.length - 1];
                        _tOwned[account] = 0;
                        _rOwned[account] = _tOwned[account] * _getRate();
                        _isExcluded[account] = false;
                        _excluded.pop();
                        break;
                    }
                }
            }
        }
    }

    
    function setTaxesBuy(uint16 reflect, uint16 liquidity, uint16 marketing, uint16 burn, uint16 dev1, uint16 dev2) external onlyOwner {
        uint16 check = reflect + liquidity + marketing + burn + dev1 + dev2;
        require(reflect <= staticVals.maxReflect
                && liquidity <= staticVals.maxLiquidity
                && marketing <= staticVals.maxMarketing
                && burn <= staticVals.maxBurn
                && dev1 <= staticVals.maxDev1
                && dev2 <= staticVals.maxDev2);
        require(check <= 3450);
        _buyTaxes.liquidity = liquidity;
        _buyTaxes.reflect = reflect;
        _buyTaxes.marketing = marketing;
        _buyTaxes.burn = burn;
        _buyTaxes.dev1 = dev1;
        _buyTaxes.dev2 = dev2;
        _buyTaxes.totalSwap = check - (reflect + burn);
    }

    function setTaxesSell(uint16 reflect, uint16 liquidity, uint16 marketing, uint16 burn, uint16 dev1, uint16 dev2) external onlyOwner {
        uint16 check = reflect + liquidity + marketing + burn + dev1 + dev2;
        require(reflect <= staticVals.maxReflect
                && liquidity <= staticVals.maxLiquidity
                && marketing <= staticVals.maxMarketing
                && burn <= staticVals.maxBurn
                && dev1 <= staticVals.maxDev1
                && dev2 <= staticVals.maxDev2);
        require(check <= 3450);
        _sellTaxes.liquidity = liquidity;
        _sellTaxes.reflect = reflect;
        _sellTaxes.marketing = marketing;
        _sellTaxes.burn = burn;
        _sellTaxes.dev1 = dev1;
        _sellTaxes.dev2 = dev2;
        _sellTaxes.totalSwap = check - (reflect + burn);
    }

    function setTaxesTransfer(uint16 reflect, uint16 liquidity, uint16 marketing, uint16 burn, uint16 dev1, uint16 dev2) external onlyOwner {
        uint16 check = reflect + liquidity + marketing + burn + dev1 + dev2;
        require(reflect <= staticVals.maxReflect
                && liquidity <= staticVals.maxLiquidity
                && marketing <= staticVals.maxMarketing
                && burn <= staticVals.maxBurn
                && dev1 <= staticVals.maxDev1
                && dev2 <= staticVals.maxDev2);
        require(check <= 3450);
        _transferTaxes.liquidity = liquidity;
        _transferTaxes.reflect = reflect;
        _transferTaxes.marketing = marketing;
        _transferTaxes.burn = burn;
        _transferTaxes.dev1 = dev1;
        _transferTaxes.dev2 = dev2;
        _transferTaxes.totalSwap = check - (reflect + burn);
    }

    function setRatios(uint16 liquidity, uint16 marketing, uint16 dev1, uint16 dev2) external onlyOwner {
        _ratios.liquidity = liquidity;
        _ratios.marketing = marketing;
        _ratios.dev1 = dev1;
        _ratios.dev2 = dev2;
        _ratios.total = liquidity + marketing + dev1 + dev2;
    }

    function setDoubleDayTradeTaxEnabled(bool enabled) external onlyOwner {
        doubleDayTradingTaxEnabled = enabled;
    }

    function setDoubleDayTradeTaxTime(uint256 time) external onlyOwner {
        require(time <= 24 hours);
        doubleDayTradingTaxTime = time;
    }

    function setMaxTxPercents(uint256 percentBuy, uint256 divisorBuy, uint256 percentSell, uint256 divisorSell) public onlyOwner {
        uint256 check = (_tTotal * percentBuy) / divisorBuy;
        require(check >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmountBuy = check;
        maxTxAmountUIBuy = (startingSupply * percentBuy) / divisorBuy;
        check = (_tTotal * percentSell) / divisorSell;
        require(check >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmountSell = check;
        maxTxAmountUISell = (startingSupply * percentSell) / divisorSell;
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

    function setWallets(address payable marketing, address payable dev1, address payable dev2) external onlyOwner {
        _marketingWallet = payable(marketing);
        _dev1Wallet = payable(dev1);
        _dev2Wallet = payable(dev2);
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

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        if(_hasLimits(from, to)) {
            if(lpPairs[from]){
                require(amount <= _maxTxAmountBuy, "Transfer amount exceeds the maxTxAmount.");
            } else if (lpPairs[to]) {
                require(amount <= _maxTxAmountSell, "Transfer amount exceeds the maxTxAmount.");
            }
            if(to != currentRouter && !lpPairs[to]) {
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
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    contractSwap(contractTokenBalance, path);
                }
            }      
        } 
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    struct Balances {
        uint256 total;
        uint256 marketing;
        uint256 liquidity;
        uint256 dev1;
        uint256 dev2;
    }

    Balances private __balances = Balances(0,0,0,0,0);

    function contractSwap(uint256 contractTokenBalance, address[] memory path) private lockTheSwap {
        if (_ratios.total == 0)
            return;

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * _ratios.liquidity) / _ratios.total) / 2;

        uint256 toSwapForEth = contractTokenBalance - toLiquify;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwapForEth,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        __balances.total = address(this).balance;

        uint256 liquidityBalance = ((address(this).balance * _ratios.liquidity) / _ratios.total) / 2;
        __balances.liquidity = liquidityBalance;

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
        if (address(this).balance > 0) {
            uint256 amountETH = address(this).balance;
            _dev1Wallet.transfer((amountETH * _ratios.dev1) / (_ratios.total - _ratios.liquidity));
            _dev2Wallet.transfer((amountETH * _ratios.dev2) / (_ratios.total - _ratios.liquidity));
            __balances.dev1 = ((amountETH * _ratios.dev1) / (_ratios.total - _ratios.liquidity));
            __balances.dev2 = ((amountETH * _ratios.dev2) / (_ratios.total - _ratios.liquidity));
            __balances.marketing = address(this).balance;
            _marketingWallet.transfer(address(this).balance);
        }
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
           
            
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    

    function sweepContingency() external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot call after liquidity.");
        payable(owner()).transfer(address(this).balance);
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tSwap;
        uint256 tBurn;

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

        if (_isExcluded[from]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        }
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;  
        }

        if (values.tSwap > 0) {
            _rOwned[address(this)] = _rOwned[address(this)] + (values.tSwap * _getRate());
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)] + values.tSwap;
            emit Transfer(from, address(this), values.tSwap); // Transparency is the key to success.
        }

        if (values.tBurn > 0) {
            _rOwned[DEAD] = _rOwned[DEAD] + (values.tBurn * _getRate());
            if(_isExcluded[DEAD])
                _tOwned[DEAD] = _tOwned[DEAD] + values.tBurn;
            emit Transfer(from, DEAD, values.tBurn); // Transparency is the key to success.
        }

        if (values.rFee > 0 || values.tFee > 0) {
            _rTotal -= values.rFee;
        }

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function _getValues(address from, address to, uint256 tAmount, bool takeFee) private returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate();

        values.rAmount = tAmount * currentRate;

        if (_hasLimits(from, to)) {
            
           
            }
    
                

        if(takeFee) {
            if (lpPairs[to]) {
                currentTaxes.reflect = _sellTaxes.reflect;
                currentTaxes.totalSwap = _sellTaxes.totalSwap;
                currentTaxes.burn = _sellTaxes.burn;
            } else if (lpPairs[from]) {
                currentTaxes.reflect = _buyTaxes.reflect;
                currentTaxes.totalSwap = _buyTaxes.totalSwap;
                currentTaxes.burn = _buyTaxes.burn;
            } else {
                currentTaxes.reflect = _transferTaxes.reflect;
                currentTaxes.totalSwap = _transferTaxes.totalSwap;
                currentTaxes.burn = _transferTaxes.burn;
            }

            if(doubleDayTradingTaxEnabled && lpPairs[to]) {
                if(lastBuyTime[from] + doubleDayTradingTaxTime >= block.timestamp) {
                    currentTaxes.reflect *= 2;
                    currentTaxes.totalSwap *= 2;
                    currentTaxes.burn *= 2;
                }
            } else if (doubleDayTradingTaxEnabled && lpPairs[from]) {
                lastBuyTime[to] = block.timestamp;
            }

            values.tFee = (tAmount * currentTaxes.reflect) / staticVals.masterTaxDivisor;
            values.tSwap = (tAmount * currentTaxes.totalSwap) / staticVals.masterTaxDivisor;
            values.tBurn = (tAmount * currentTaxes.burn) / staticVals.masterTaxDivisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tSwap + values.tBurn);

            values.rFee = values.tFee * currentRate;
        } else {
            values.tFee = 0;
            values.tSwap = 0;
            values.tBurn = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }
        values.rTransferAmount = values.rAmount - (values.rFee + (values.tSwap * currentRate) + (values.tBurn * currentRate));
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
}