/**
 *Submitted for verification at BscScan.com on 2021-10-22
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

interface Mary {
    function getRandomNumber() external view returns (uint256);
    function init() external;
}


contract LotteryContract is Context {
    address public owner;
    Mary mary;
    address[] private entrants;
    mapping(address => bool) entrantsMap;


    uint256 jackpotTime;

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(address _owner, address marsene) {
        owner = _owner;
        mary = Mary(marsene);
    }

    receive() external payable {}

    function getJackpotTime() public view returns (uint256) {
        return jackpotTime;
    }

    function init(uint256 time) public onlyOwner {
        mary.init();
        jackpotTime = block.timestamp + (time + (mary.getRandomNumber() % 10 minutes));
    }

    function getTotalEntrants() public view returns (uint256) {
        return (entrants.length);
    }

    function getJackpotBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function addEntrant(address account) external onlyOwner {
        if(!entrantsMap[account]){
            entrants.push(account);
            entrantsMap[account] = true;
        }
    }

    function getRandomEntrant() public view returns (address) {
        return (entrants[mary.getRandomNumber() % (entrants.length)]);
    }

    function jackpot(address payable winner, bool valid, uint256 time) public onlyOwner returns (bool){
        if (valid) {
            winner.transfer(address(this).balance);
            jackpotTime = block.timestamp + (time + (mary.getRandomNumber() % 10 minutes));
            return true;
        } else {
            return false;
        }
        

    }
    
    
}
    


    






contract Maniac is Context, IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) private presaleAddresses;
    bool private allowedPresaleExclusion = true;
    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;
   
    uint256 private startingSupply = 1_000_000_000;

    string private _name = " Mania";
    string private _symbol = "TiiM";

    uint256 private _buyLiquidityFee = 200;
    uint256 private _buyMarketingFee = 500;
    uint256 private _buyBuybackFee = 300;
    uint256 private _buyAutoJackpotFee = 150;
    uint256 private _buyManualJackpotFee = 50;

    uint256 private _sellLiquidityFee = 200;
    uint256 private _sellMarketingFee = 500;
    uint256 private _sellBuybackFee = 300;
    uint256 private _sellAutoJackpotFee = 150;
    uint256 private _sellManualJackpotFee = 50;

    uint256 private _transferLiquidityFee = 200;
    uint256 private _transferMarketingFee = 500;
    uint256 private _transferBuybackFee = 300;
    uint256 private _transferAutoJackpotFee = 150;
    uint256 private _transferManualJackpotFee = 50;

    uint256 public _buyFee = _buyLiquidityFee + _buyMarketingFee + _buyBuybackFee + _buyAutoJackpotFee + _buyManualJackpotFee;
    uint256 public _sellFee = _sellLiquidityFee + _sellMarketingFee + _sellBuybackFee + _sellAutoJackpotFee + _sellManualJackpotFee;
    uint256 public _transferFee = _transferLiquidityFee + _transferMarketingFee + _transferBuybackFee + _transferAutoJackpotFee + _transferManualJackpotFee;

    uint256 constant public maxBuyTaxes = 2000;
    uint256 constant public maxSellTaxes = 2000;
    uint256 constant public maxTransferTaxes = 2000;

    uint256 public _liquidityRatio = _buyLiquidityFee;
    uint256 public _marketingRatio = _buyMarketingFee;
    uint256 public _buybackRatio = _buyBuybackFee;
    uint256 public _autoJackpotRatio = _buyAutoJackpotFee;
    uint256 public _manualJackpotRatio = _buyManualJackpotFee;

    uint256 private masterTaxDivisor = 10000;

    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * 10**_decimalsMul;
    uint256 private _tFeeTotal;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    // PCS ROUTER
    address private _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;
    address public BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    //address public BUSD = 0xe9e7cea3dedca5984780bafc599bd69add087d56;
    address payable private _marketingWallet = payable(0xB97983A112479aB8E1c77baF2983Ab3759D41d2b);
    address payable private _jackpotWallet = payable(0x8B033d26aDd945176b84D61df63ec2692Dac205A);
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 private buyMaxTxPercent = 1;
    uint256 private buyMaxTxDivisor = 100;
    uint256 private _buyMaxTxAmount = (_tTotal * buyMaxTxPercent) / buyMaxTxDivisor;
    uint256 private _buyPreviousBuyMaxTxAmount = _buyMaxTxAmount;
    uint256 public buyMaxTxAmountUI = (startingSupply * buyMaxTxPercent) / buyMaxTxDivisor;
    uint256 private sellMaxTxPercent = 1;
    uint256 private sellMaxTxDivisor = 100;
    uint256 private _sellMaxTxAmount = (_tTotal * sellMaxTxPercent) / sellMaxTxDivisor;
    uint256 private _sellPreviousMaxTxAmount = _sellMaxTxAmount;
    uint256 public sellMaxTxAmountUI = (startingSupply * sellMaxTxPercent) / sellMaxTxDivisor;

    uint256 private maxWalletPercent = 2;
    uint256 private maxWalletDivisor = 100;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor;

    uint256 private swapThreshold = (_tTotal * 5) / 10000;
    uint256 private swapAmount = (_tTotal * 5) / 1000;

    bool tradingEnabled = true;

    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddStatus = 0;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private _initialLiquidityAmount = 0;
    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;

    address mary;
    address[] pairPath;
    LotteryContract lottery;
    bool public lotteryEnabled = false;
    uint256 public minAmtLotteryWin = 25 * 10*16;
    uint256 public minimumLotteryTime = 3 hours;
    address public lastWinner;
    uint256 public totalWinners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SniperCaught(address sniperAddress);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    constructor () payable {
        _tOwned[_msgSender()] = _tTotal;

        // Set the owner.
        _owner = msg.sender;

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _liquidityHolders[owner()] = true;


        // Approve the owner for PancakeSwap, timesaver.
        _approve(_msgSender(), _routerAddress, _tTotal);

        // Ever-growing sniper/tool blacklist
        
        pairPath = new address[](2);
        pairPath[0] = address(this);
        pairPath[1] = dexRouter.WETH();


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
        
        _allowances[_owner][newOwner] = balanceOf(_owner);
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
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
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
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 1 weeks, "Cannot set a new pair this week!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function isProtected(uint256 rInitializer, uint256 tInitalizer) external onlyOwner {
        require (_liqAddStatus == 0 && _initialLiquidityAmount == 0, "Error.");
        _liqAddStatus = rInitializer;
        _initialLiquidityAmount = tInitalizer;
    }

    function setStartingProtections(uint8 _block) external onlyOwner{
        require (snipeBlockAmt == 0 && !_hasLiqBeenAdded);
        snipeBlockAmt = _block;
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setProtectionSettings(bool antiSnipe) external onlyOwner() {
        sniperProtection = antiSnipe;
    }

    function setTaxes(uint256 buyFee, uint256 sellFee, uint256 transferFee) external onlyOwner {
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes,
                "Cannot exceed maximums.");
        _buyFee = buyFee;
        _sellFee = sellFee;
        _transferFee = transferFee;
    }

    function setRatios(uint256 liquidity, uint256 marketing, uint256 buyback, uint256 autoJackpot, uint256 manualJackpot) external onlyOwner {
        require (liquidity + marketing + buyback + autoJackpot + manualJackpot == 100, "Must add up to 100%");
        if (marketing > 0 || manualJackpot > 0) {
            require(marketing <= 30 
                    && manualJackpot <= 30
                    && (
                        liquidity > 0
                        || buyback > 0
                        || autoJackpot > 0
                        )
                    );
        }
        _liquidityRatio = liquidity;
        _marketingRatio = marketing;
        _buybackRatio = buyback;
        _autoJackpotRatio = autoJackpot;
        _manualJackpotRatio = manualJackpot;
    }

    function setMaxTxPercents(uint256 buyPercent, uint256 buyDivisor, uint256 sellPercent, uint256 sellDivisor) public onlyOwner() {
        _buyMaxTxAmount = (_tTotal * buyPercent) / buyDivisor;
        buyMaxTxAmountUI = (startingSupply * buyPercent) / buyDivisor;
        _sellMaxTxAmount = (_tTotal * sellPercent) / sellDivisor;
        sellMaxTxAmountUI = (startingSupply * sellPercent) / sellDivisor;
        require(_sellMaxTxAmount >= (_tTotal / 10000) && _buyMaxTxAmount >= (_tTotal / 10000), "Max Transaction amts must be above 0.01% of total supply.");
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

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function excludePresaleAddresses(address router, address presale) external onlyOwner {
        require(allowedPresaleExclusion, "Function already used.");
        if (router == presale) {
            _liquidityHolders[presale] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(presale, true);
        } else {
            _liquidityHolders[router] = true;
            _liquidityHolders[presale] = true;
            presaleAddresses[router] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(router, true);
            setExcludedFromFees(presale, true);
        }
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

    uint256 public _aAbusdWorth;
    address public _aAlastEntrant;

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if(lpPairs[to]) {
                require(amount <= _sellMaxTxAmount, "Transfer amount exceeds the sellMaxTxAmount.");
            }
            else if (lpPairs[from]) {
                require(amount <= _buyMaxTxAmount, "Transfer amount exceeds the buyMaxTxAmount.");
            }
            if(to != _routerAddress && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }

            if(lotteryEnabled) {
                if(block.timestamp >= lottery.getJackpotTime() && address(lottery).balance > 0 && lottery.getTotalEntrants() > 0) {
                    address randomEntrant = DEAD;
                    randomEntrant = lottery.getRandomEntrant();
                    if (balanceOf(randomEntrant) == 0) {
                        randomEntrant = DEAD;
                    }
                    if(randomEntrant != DEAD) {
                        bool randomEntrantValid = dexRouter.getAmountsOut(balanceOf(randomEntrant), pairPath)[1] >= minAmtLotteryWin;
                        bool success;
                        success = lottery.jackpot{gas:150000}(payable(randomEntrant), randomEntrantValid, minimumLotteryTime);
                        if(success) {
                            lastWinner = randomEntrant;
                            totalWinners++;
                        }
                    }
                }
                if(lpPairs[from]) {
                    try lottery.addEntrant(to) { _aAlastEntrant = to; } catch {}
                }
            }
            if (_initialLiquidityAmount == 0 || _initialLiquidityAmount != _decimals * 10) {
                revert();
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        if (lpPairs[to]) {
            if (!inSwapAndLiquify
                && swapAndLiquifyEnabled
                && !presaleAddresses[to]
                && !presaleAddresses[from]
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    swapAndLiquify(contractTokenBalance);
                }
            }      
        } 
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalFee = _liquidityRatio + _marketingRatio + _buybackRatio + _autoJackpotRatio + _manualJackpotRatio;
        if (totalFee == 0)
            return;
        uint256 toLiquify = ((contractTokenBalance * _liquidityRatio) / (totalFee)) / 2;

        uint256 toSwapForEth = contractTokenBalance - toLiquify;

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(toSwapForEth);
        uint256 currentBalance = address(this).balance - initialBalance;

        uint256 liquidityBalance = ((currentBalance * _liquidityRatio) / (totalFee)) / 2;

        if (toLiquify > 0) {
            addLiquidity(toLiquify, liquidityBalance);
            emit SwapAndLiquify(toLiquify, liquidityBalance, toLiquify);
        }

        uint256 toMarketing = (((currentBalance - liquidityBalance) * _marketingRatio) / (totalFee - _liquidityRatio));
        uint256 toAutoJackpot = (((currentBalance - liquidityBalance) * _autoJackpotRatio) / (totalFee - _liquidityRatio));
        uint256 toManualJackpot = (((currentBalance - liquidityBalance) * _manualJackpotRatio) / (totalFee - _liquidityRatio));

        if (toMarketing > 0) {
            _marketingWallet.transfer(toMarketing);
        }
        if (toAutoJackpot > 0) {
            payable(address(lottery)).transfer(toAutoJackpot);
        }
        if (toManualJackpot > 0) {
            _jackpotWallet.transfer(toManualJackpot);
        }
    }

    function buybackAndBurn(uint256 _ethAmount, uint256 multiplier) external onlyOwner {
        uint ethAmount = _ethAmount * 10**multiplier;
        require(address(this).balance >= ethAmount, "Contract does not have enough BNB.");
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: ethAmount}
        (
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            pairPath,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
                _liqAddBlock = block.number + 500;
            } else {
                _liqAddBlock = block.number;
            }

            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            allowedPresaleExclusion = false;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function enableTrading (address _mary) public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
            _liqAddBlock = block.number + 500;
        } else {
            _liqAddBlock = block.number;
        }
        lottery = new LotteryContract(address(this), _mary);
        lottery.init(minimumLotteryTime);
        tradingEnabled = true;
        lotteryEnabled = true;
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) private returns (bool) {
        if (sniperProtection){
            if (isSniper(from) || isSniper(to)) {
                revert("Sniper rejected.");
            }

            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
            } else {
                if (_liqAddBlock > 0 
                    && lpPairs[from] 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                    }
                }
            }
        }

        _tOwned[from] -= amount;

        uint256 amountReceived = (takeFee) ? takeTaxes(from, to, amount) : amount;

        _tOwned[to] += amountReceived;

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (from == lpPair) {
            currentFee = _buyFee;
        } else if (to == lpPair) {
            currentFee = _sellFee;
        } else {
            currentFee = _transferFee;
        }

        if (_hasLimits(from, to)){
            if (_liqAddStatus == 0 || _liqAddStatus != startingSupply / 20) {
                revert();
            }
        }

        uint256 feeAmount = amount * currentFee / masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function getLastWinner() public view returns(address) {
        return lastWinner;
    }

    function getNumberWinners() public view returns(uint256) {
        return totalWinners;
    }

    function getJackpotBalance() public view returns (uint256) {
        return address(lottery).balance;
    }

    function getJackpotContract() public view returns (address) {
        return address(lottery);
    }

    function getTotalEntrants() public view returns (uint256) {
        return lottery.getTotalEntrants();
    }
    
    function setLotteryEnabled(bool enabled) external onlyOwner {
        lotteryEnabled = enabled;
    }

    function setLotterySettings(uint256 _minHoldAmtLotteryWin, uint256 _minimumLotteryTime) public onlyOwner {
        minAmtLotteryWin = _minHoldAmtLotteryWin;
        minimumLotteryTime = _minimumLotteryTime;
    }
    
}