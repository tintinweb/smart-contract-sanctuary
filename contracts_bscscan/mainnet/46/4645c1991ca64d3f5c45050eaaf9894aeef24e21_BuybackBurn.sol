/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

/**
   Telegram: https://t.me/shibarosstoken
   Website: http://www.shibaross.com


   ░██████╗██╗░░██╗██╗██████╗░░█████╗░  ██████╗░░█████╗░░██████╗░██████╗
   ██╔════╝██║░░██║██║██╔══██╗██╔══██╗  ██╔══██╗██╔══██╗██╔════╝██╔════╝
   ╚█████╗░███████║██║██████╦╝███████║  ██████╔╝██║░░██║╚█████╗░╚█████╗░
   ░╚═══██╗██╔══██║██║██╔══██╗██╔══██║  ██╔══██╗██║░░██║░╚═══██╗░╚═══██╗
   ██████╔╝██║░░██║██║██████╦╝██║░░██║  ██║░░██║╚█████╔╝██████╔╝██████╔╝
   ╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝░╚═╝░░╚═╝  ╚═╝░░╚═╝░╚════╝░╚═════╝░╚═════╝░
*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;


abstract contract Context {
   function _msgSender() internal view returns (address payable) {
       return payable(msg.sender);
   }
   function _msgData() internal view returns (bytes memory) {
       this;
       return msg.data;
   }
}


interface IERC20 {
 function totalSupply() external view returns (uint256);
 function decimals() external view returns (uint8);
 function symbol() external view returns (string memory);
 function name() external view returns (string memory);
 function getOwner() external view returns (address);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address _owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
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


contract BuybackBurn is Context, IERC20 {
   address private _owner;


   mapping (address => uint256) private _tOwned;
   mapping (address => bool) lpPairs;
   uint256 private timeSinceLastPair = 0;
   mapping (address => mapping (address => uint256)) private _allowances;


   mapping (address => bool) private _isExcludedFromFees;


   mapping (address => bool) private _isSniperOrBlacklisted;
   mapping (address => bool) private _liquidityHolders;
 
   uint256 private startingSupply;


   string private _name;
   string private _symbol;


   uint256 public _buyFee = 1200;
   uint256 public _sellFee = 1500;
   uint256 public _transferFee = 1250;


   uint256 constant public maxBuyTaxes = 2000;
   uint256 constant public maxSellTaxes = 2000;
   uint256 constant public maxTransferTaxes = 2000;


   uint256 public _liquidityRatio = 600;
   uint256 public _marketingRatio = 500;
   uint256 public _buybackRatio = 100;


   uint256 private masterTaxDivisor = 10000;


   uint256 private constant MAX = ~uint256(0);
   uint8 private _decimals;
   uint256 private _decimalsMul = _decimals;
   uint256 private _tTotal;
   uint256 private _tFeeTotal;


   IUniswapV2Router02 public dexRouter;
   address public lpPair;


   // PCS ROUTER
   address private _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;


   address public DEAD = 0x000000000000000000000000000000000000dEaD;
   address public ZERO = 0x0000000000000000000000000000000000000000;
   address payable private _marketingWallet = payable(0x941Af9017F68DE37a11674E1c41b5a2d5a3b1eDE);
  
   bool inSwapAndLiquify;
   bool public swapAndLiquifyEnabled = false;


   uint256 public _maxTxAmount;
   uint256 public _maxWalletSize;


   uint256 private swapThreshold;
   uint256 private swapAmount;


   uint256 public bonusTime = 1 hours;
   uint256 private bonusTimeStamp;


   bool public tradingEnabled = false;
   bool public launched = false;


   bool public sniperProtection = false;
   bool public _hasLiqBeenAdded = false;
   uint256 private _liqAddBlock = 0;
   uint256 public _liqAddStamp = 0;
   uint256 private snipeBlockAmt = 0;
   uint256 public snipersCaught = 0;
   bool public gasLimitActive = false;
   uint256 public gasPriceLimit;
   bool public sameBlockActive = false;
   mapping (address => uint256) private lastTrade;


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


       // Set the owner.
       _owner = msg.sender;


       _approve(msg.sender, address(_routerAddress), type(uint256).max);
       _approve(address(this), address(_routerAddress), type(uint256).max);
      
       _allowances[address(this)][address(_routerAddress)] = type(uint256).max;


       _isExcludedFromFees[owner()] = true;
       _isExcludedFromFees[address(this)] = true;
       _liquidityHolders[owner()] = true;
       _liquidityHolders[address(this)] = true;


       // Approve the owner for PancakeSwap, timesaver.
       _approve(_msgSender(), _routerAddress, _tTotal);


   }
   function ghostLaunch(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
       require(!launched, "1");
       require(accounts.length < 200, "2");
       require(accounts.length == amounts.length, "3");
       startingSupply = 1_000_000_000_000_000;
       if (startingSupply < 10000000000) {
           _decimals = 18;
       } else {
           _decimals = 9;
       }
       _tTotal = startingSupply * (10**_decimals);
       _name = "Ross Inu";
       _symbol = "$ROSS";
       dexRouter = IUniswapV2Router02(_routerAddress);
       lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
       lpPairs[lpPair] = true;
       _maxTxAmount = (_tTotal * 5) / 1000;
       _maxWalletSize = (_tTotal * 15) / 1000;
       swapThreshold = (_tTotal * 5) / 10000;
       swapAmount = (_tTotal * 5) / 10000;
       launched = true;    
       _tOwned[owner()] = _tTotal;
       emit Transfer(address(0), owner(), _tTotal);


       _approve(address(this), address(dexRouter), type(uint256).max);


       for(uint256 i = 0; i < accounts.length; i++){
           uint256 amount = amounts[i] * 10**_decimals;
           _transfer(owner(), accounts[i], amount);
       }


       _transfer(owner(), address(this), balanceOf(owner()));


       dexRouter.addLiquidityETH{value: address(this).balance}(
           address(this),
           balanceOf(address(this)),
           0, // slippage is unavoidable
           0, // slippage is unavoidable
           owner(),
           block.timestamp
       );
       setStartingProtections(2, 149);
       setProtectionSettings(true, true, true);
       enableTrading();
       swapAndLiquifyEnabled = true;
   }


   receive() external payable {}


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


   function isSniperOrBlacklisted(address account) public view returns (bool) {
       return _isSniperOrBlacklisted[account];
   }


   function setStartingProtections(uint8 _block, uint256 _gas) public onlyOwner{
       require (snipeBlockAmt == 0 && gasPriceLimit == 0 && !_hasLiqBeenAdded);
       snipeBlockAmt = _block;
       gasPriceLimit = _gas * 1 gwei;
   }


   function setBlacklistEnabled(address account, bool enabled) external onlyOwner() {
       _isSniperOrBlacklisted[account] = enabled;
   }


   function setProtectionSettings(bool antiSnipe, bool antiGas, bool antiBlock) public onlyOwner() {
       sniperProtection = antiSnipe;
       gasLimitActive = antiGas;
       sameBlockActive = antiBlock;
   }


   function setGasPriceLimit(uint256 gas) external onlyOwner {
       require(gas >= 75);
       gasPriceLimit = gas * 1 gwei;
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


   function setRatios(uint256 liquidity, uint256 marketing, uint256 buyback) external onlyOwner {
       require (liquidity + marketing + buyback == 100, "Must add up to 100%");
       if (marketing > 0) {
           require(marketing <= 30
                   );
       }
       _liquidityRatio = liquidity;
       _marketingRatio = marketing;
       _buybackRatio = buyback;
   }


   function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
       require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
       _maxTxAmount = (_tTotal * percent) / divisor;
   }


   function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
       require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Wallet amt must be above 0.1% of total supply.");
       _maxWalletSize = (_tTotal * percent) / divisor;
   }


   function getMaxTX() public view returns (uint256) {
       return _maxTxAmount / (10**_decimals);
   }


   function getMaxWallet() public view returns (uint256) {
       return _maxWalletSize / (10**_decimals);
   }


   function setBonusTaxTime(uint256 time) external onlyOwner {
       require(time <= 2 hours, "Cannot set above 2 hrs.");
       bonusTime = time;
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


   function _hasLimits(address from, address to) private view returns (bool) {
       return from != owner()
           && to != owner()
           && !_liquidityHolders[to]
           && !_liquidityHolders[from]
           && to != DEAD
           && to != address(0)
           && from != address(this);
   }


   function _transfer(address from, address to, uint256 amount) internal returns (bool) {
       require(from != address(0), "ERC20: transfer from the zero address");
       require(to != address(0), "ERC20: transfer to the zero address");
       require(amount > 0, "Transfer amount must be greater than zero");
       if (gasLimitActive) {
           require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
       }
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
           if (sameBlockActive) {
               if (lpPairs[from]){
                   require(lastTrade[to] != block.number);
                   lastTrade[to] = block.number;
               } else {
                   require(lastTrade[from] != block.number);
                   lastTrade[from] = block.number;
               }
           }


           if(lpPairs[from] && block.timestamp < _liqAddStamp + 30 minutes) {
               address[] memory path = new address[](2);
               path[0] = address(this);
               path[1] = dexRouter.WETH();
               uint256 bnbAmt = dexRouter.getAmountsOut(amount, path)[1];
               require(bnbAmt <= 25 * 10**16, "Can only buy up to .25 BNB at the start!");
           }
       }


       bool takeFee = true;
       if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
           takeFee = false;
       }


       if (lpPairs[to]) {
           if (!inSwapAndLiquify
               && swapAndLiquifyEnabled
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
       uint256 totalFee = _liquidityRatio + _marketingRatio + _buybackRatio;
       if (totalFee == 0)
           return;
       uint256 toLiquify = ((contractTokenBalance * _liquidityRatio) / (_liquidityRatio + _marketingRatio)) / 2;


       uint256 toSwapForEth = contractTokenBalance - toLiquify;


       uint256 initialBalance = address(this).balance;
       swapTokensForEth(toSwapForEth);
       uint256 currentBalance = address(this).balance - initialBalance;


       uint256 liquidityBalance = ((currentBalance * _liquidityRatio) / (totalFee)) / 2;
       uint256 toMarketing = (((currentBalance - liquidityBalance) * _marketingRatio) / (totalFee - _liquidityRatio));


       if (toLiquify > 0) {
           addLiquidity(toLiquify, liquidityBalance);
           emit SwapAndLiquify(toLiquify, liquidityBalance, toLiquify);
       }
       if (toMarketing > 0) {
           _marketingWallet.transfer(toMarketing);
       }
   }


   function swapTokensForEth(uint256 tokenAmount) internal {
       address[] memory path = new address[](2);
       path[0] = address(this);
       path[1] = dexRouter.WETH();


       dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
           tokenAmount,
           0, // accept any amount of ETH
           path,
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
           _marketingWallet,
           block.timestamp
       );
   }


   function _checkLiquidityAdd(address from, address to) private {
       require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
       if (!_hasLimits(from, to) && to == lpPair) {
           if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
               _liqAddBlock = block.number + 10;
           } else {
               _liqAddBlock = block.number;
           }


           _liquidityHolders[from] = true;
           _hasLiqBeenAdded = true;
           _liqAddStamp = block.timestamp;


           swapAndLiquifyEnabled = true;
           emit SwapAndLiquifyEnabledUpdated(true);
       }
   }


   function enableTrading() public onlyOwner {
       require(!tradingEnabled, "Trading already enabled!");
       if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
           _liqAddBlock = block.number + 10;
           _liqAddStamp = block.timestamp;
       } else {
           _liqAddBlock = block.number;
           _liqAddStamp = block.timestamp;
       }
       _hasLiqBeenAdded = true;
       tradingEnabled = true;
   }


   function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) private returns (bool) {
       if (sniperProtection){
           if (isSniperOrBlacklisted(from) || isSniperOrBlacklisted(to)) {
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
                       _isSniperOrBlacklisted[to] = true;
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
           if(block.timestamp <= bonusTimeStamp) {
               currentFee = _sellFee * 2;
           }
       } else {
           currentFee = _transferFee;
       }


       uint256 feeAmount = amount * currentFee / masterTaxDivisor;


       _tOwned[address(this)] += feeAmount;
       emit Transfer(from, address(this), feeAmount);


       return amount - feeAmount;
   }


   function buybackAndBurn(uint256 _bnbAmountInHundreds) external onlyOwner {
       uint ethAmount = _bnbAmountInHundreds * 10**16;
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
       bonusTimeStamp = block.timestamp + bonusTime;
   }
}