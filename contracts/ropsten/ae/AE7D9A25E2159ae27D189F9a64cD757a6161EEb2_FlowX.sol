/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

pragma solidity ^0.8.4;

interface IUniV2FactoryMin {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniV2RouterMin {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline
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

  function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
  ) external returns (uint amountETH);
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}
contract FlowX is ERC20, Ownable {
  string private _name = 'FlowX';
  string private _symbol = 'FLOWX';
  uint8 private _decimals = 9;

  IUniV2RouterMin public uniswapV2Router;

  address public immutable uniswapV2Pair;
  bool private liquidating;
  uint256 public MAX_SELL_LIMIT_AMT;
  uint256[2] public FEE_RWDS;
  uint256[2] public FEE_CHTY;
  uint256[2] public FEE_MKTG;
  uint256[2] public FEE_LQTY;
  uint256 public TOTAL_FEES_BUYS;
  uint256 public TOTAL_FEES_SELLS;
  uint256 private TKN_SPLIT_RWDS;
  uint256 private TKN_SPLIT_CHTY;
  uint256 private TKN_SPLIT_MKTG;
  uint256 private TKN_SPLIT_LQTY;
  bool _devFeeEnabled = false;
  bool public tradingEnabled = false;

  mapping (address => bool) private _isBlackListedBot;
  address private constant ADDR_UNIROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address payable private ADDR_PAYABLE_CHTY;
  address payable private ADDR_PAYABLE_MKTG;
  uint256 public gasForProcessing;
  uint256 public tokenLiquidationThreshold;

  function activate() external onlyOwner {
    _devFeeEnabled = true;
    tradingEnabled = true;
  }
  function setTokenLiquidationThreshold(uint256 tokenAmt) external onlyOwner {
    tokenLiquidationThreshold = tokenAmt;
  }

  mapping (address => bool) public _isExcludedFromFees;

  mapping (address => bool) public automatedMarketMakerPairs;

  mapping(address => uint256) private _xbalances;

  uint256 private _xTotalSupply;
  uint256 private constant xMagnitude = 2**128;
  uint256 private xMagnifiedDividendPerShare;
  mapping(address => int256) private xMagnifiedDividendCorrections;
  mapping(address => uint256) private xWithdrawnDividends;
  uint256 public xGasForTransfer;
  uint256 public xTotalDividendsDistributed;

  struct IterableMap {
    address[] keys;
    mapping(address => uint256) values;
    mapping(address => uint256) indexOf;
    mapping(address => bool) inserted;
  }

  IterableMap private xTokenHoldersMap;
  uint256 public xLastProcessedIndex;
  mapping(address => bool) public xExcludedFromDividends;
  mapping(address => uint256) public xLastClaimTimes;
  uint256 public xClaimWait;
  uint256 public constant xMinTokenBalanceForDividends = 10000 * (10**18);
  event XDividendWithdrawn(address indexed user, uint256 indexed amount);
  event XClaim(address indexed account, uint256 amount);

  constructor() ERC20(_name, _symbol){
    _transferOwnership(_msgSender());

    gasForProcessing = 150000;

    tokenLiquidationThreshold = 10000 * (10**_decimals);
    MAX_SELL_LIMIT_AMT = 1000000000 * (10**_decimals);

    FEE_RWDS = [200,400];
    FEE_CHTY = [100,100];
    FEE_MKTG = [100,100];
    FEE_LQTY = [100,200];
    TOTAL_FEES_BUYS = FEE_RWDS[0] + FEE_CHTY[0] + FEE_MKTG[0] + FEE_LQTY[0];
    TOTAL_FEES_SELLS = FEE_RWDS[1] + FEE_CHTY[1] + FEE_MKTG[1] + FEE_LQTY[1];

    ADDR_PAYABLE_CHTY = payable(0xb849fBBfB25b679ADdFAD5Ebe94132c9ec7803aa);
    ADDR_PAYABLE_MKTG = payable(0xF2d5C58cB49148D7cFC00E833328f15D92e95fdC);

    xClaimWait = 180;
    xGasForTransfer = 3000;

    IUniV2RouterMin _uniswapV2Router = IUniV2RouterMin(ADDR_UNIROUTER);

    address _uniswapV2Pair = IUniV2FactoryMin(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;
    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    xExcludedFromDividends[address(this)] = true;
    xExcludedFromDividends[owner()] = true;
    xExcludedFromDividends[address(_uniswapV2Router)] = true;
    xExcludedFromDividends[address(0x000000000000000000000000000000000000dEaD)] = true;

    excludeFromFees(owner());
    excludeFromFees(address(this));

    _mint(owner(), 500_000_000_000 * (10**_decimals)); 
  }

  function imap_getIndexOfKey(address key) public view returns (int256){
    if (!xTokenHoldersMap.inserted[key]) {return -1;}
    return int256(xTokenHoldersMap.indexOf[key]);
  }
  function imap_getKeyAtIndex(uint256 index) public view returns (address){
    return xTokenHoldersMap.keys[index];
  }

  function imap_set(address key, uint256 val) public {
    if (xTokenHoldersMap.inserted[key]) {
      xTokenHoldersMap.values[key] = val;
    } else {
      xTokenHoldersMap.inserted[key] = true;
      xTokenHoldersMap.values[key] = val;
      xTokenHoldersMap.indexOf[key] = xTokenHoldersMap.keys.length;
      xTokenHoldersMap.keys.push(key);
    }
  }
  function imap_remove(address key) public {
    if (!xTokenHoldersMap.inserted[key]) {return;}
    delete xTokenHoldersMap.inserted[key];
    delete xTokenHoldersMap.values[key];
    uint256 index = xTokenHoldersMap.indexOf[key];
    uint256 lastIndex = xTokenHoldersMap.keys.length - 1;
    address lastKey = xTokenHoldersMap.keys[lastIndex];
    xTokenHoldersMap.indexOf[lastKey] = index;
    delete xTokenHoldersMap.indexOf[key];
    xTokenHoldersMap.keys[index] = lastKey;
    xTokenHoldersMap.keys.pop();
  }
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function _transfer(address from, address to, uint256 amount) internal override{
    require(amount > 0);
    require(from != address(0));
    require(to != address(0));
    require(!_isBlackListedBot[to], "no bots");
    require(!_isBlackListedBot[msg.sender], "no bots");
    require(!_isBlackListedBot[from], "no bots");

    if(from != owner() && to != owner()){
      require(tradingEnabled);
    }

    liquidating = false;
    uint256 ratio;
    uint8 nBuyOrSell = automatedMarketMakerPairs[from] ? 0 : automatedMarketMakerPairs[to] ? 1 : 2;

    if (nBuyOrSell == 1 
      && from != address(uniswapV2Router) 
      && !_isExcludedFromFees[to] 
    ) {
      require(amount <= MAX_SELL_LIMIT_AMT, "sell>MAX_SELL_LIMIT_AMT.");
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    if ( contractTokenBalance >= tokenLiquidationThreshold
      && _devFeeEnabled
      && nBuyOrSell == 1 
      && from != owner() && to != owner()
    ) {
      liquidating = true;

      uint256 lqtyTokenHalf = TKN_SPLIT_LQTY / 2;
      uint256 lqtyEthHalf = TKN_SPLIT_LQTY - lqtyTokenHalf;
      uint256 tokenSplitTotal = TKN_SPLIT_CHTY + TKN_SPLIT_MKTG + lqtyEthHalf + TKN_SPLIT_RWDS;
      uint256 initialContractEthBal = address(this).balance;

      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();

      _approve(address(this), address(uniswapV2Router), tokenSplitTotal);

      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenSplitTotal,
        0, 
        path,
        address(this),
        block.timestamp
      );

      uint256 totalEthCreatedThisSwap = address(this).balance - initialContractEthBal;
      ratio = totalEthCreatedThisSwap / tokenSplitTotal;
      uint256 ETH_SPLIT_CHTY = TKN_SPLIT_CHTY * ratio;
      uint256 ETH_SPLIT_MKTG = TKN_SPLIT_MKTG * ratio;
      uint256 ETH_SPLIT_LQTY = TKN_SPLIT_LQTY * ratio;

      ADDR_PAYABLE_CHTY.transfer(ETH_SPLIT_CHTY);
      ADDR_PAYABLE_MKTG.transfer(ETH_SPLIT_MKTG);

      _approve(address(this), address(uniswapV2Router), ETH_SPLIT_LQTY); 
      uniswapV2Router.addLiquidityETH{ value: ETH_SPLIT_LQTY }(
        address(this),lqtyTokenHalf,0,0,owner(),block.timestamp
      );

    }

    bool applyFees = !(_isExcludedFromFees[from] || _isExcludedFromFees[to] || liquidating || nBuyOrSell==2);

    if (applyFees) {
      uint256 totalFeeThisTx = nBuyOrSell==0?TOTAL_FEES_BUYS:TOTAL_FEES_SELLS;
      uint256 fees = amount * ((totalFeeThisTx/100) / 100);
      amount = amount - fees;
      ratio = fees / totalFeeThisTx;
      TKN_SPLIT_RWDS += (FEE_RWDS[nBuyOrSell]/100) * ratio;
      TKN_SPLIT_CHTY += (FEE_CHTY[nBuyOrSell]/100) * ratio;
      TKN_SPLIT_MKTG += (FEE_MKTG[nBuyOrSell]/100) * ratio;
      TKN_SPLIT_LQTY += (FEE_LQTY[nBuyOrSell]/100) * ratio;

      ERC20._transfer(from, address(this), fees);
    }

    ERC20._transfer(from, to, amount);

    xSetBalance(payable(from), balanceOf(from));
    xSetBalance(payable(to), balanceOf(to));

  }

  function enableDevFee(bool enabled) external onlyOwner{
    _devFeeEnabled = enabled;
  }
  function setMaxSellLimit(uint256 amount) external onlyOwner {
    MAX_SELL_LIMIT_AMT = amount;
  }
  function excludeFromFees(address account) public onlyOwner {
    require(!_isExcludedFromFees[account]);
    _isExcludedFromFees[account] = true;
  }

  function setFeePcts (uint256[2] calldata rewardsPct, uint256[2] calldata liquidityPct,
  uint256[2] calldata marketingPct, uint256[2] calldata charityPct) external {
    FEE_RWDS = rewardsPct;
    FEE_CHTY = charityPct;
    FEE_MKTG = marketingPct;
    FEE_LQTY = liquidityPct;
    TOTAL_FEES_BUYS = FEE_RWDS[0] + FEE_CHTY[0] + FEE_MKTG[0] + FEE_LQTY[0];
    TOTAL_FEES_SELLS = FEE_RWDS[1] + FEE_CHTY[1] + FEE_MKTG[1] + FEE_LQTY[1];
  }

  function setAutomatedMarketMakerPair(address pair, bool toggle) public onlyOwner {
    require(pair != uniswapV2Pair);
    _setAutomatedMarketMakerPair(pair, toggle);
  }
  function _setAutomatedMarketMakerPair(address pair, bool toggle) private {
    require(automatedMarketMakerPairs[pair] != toggle);
    automatedMarketMakerPairs[pair] = toggle;
    if(toggle) {
      xExcludeFromDividends(pair);
    }
  }

  function setCharityWallet(address payable account) external onlyOwner() {
    ADDR_PAYABLE_CHTY = account;
  }
  function setMarketingWallet(address payable account) external onlyOwner() {
    ADDR_PAYABLE_MKTG = account;
  }
  function setBlackList(address account, bool toggle) external onlyOwner() {
    if(toggle) {
      require(account != ADDR_UNIROUTER);
      _isBlackListedBot[account] = true;
    }else{
      delete _isBlackListedBot[account];
    }
  }

  function xTotalSupply() public view returns (uint256) {return _xTotalSupply;}
  function xBalanceOf(address account) public view returns (uint256) {
    return _xbalances[account];
  }

  receive() external payable {

    require(xTotalSupply() > 0);
    if (msg.value > 0) {
      xMagnifiedDividendPerShare =
      xMagnifiedDividendPerShare +
      ((msg.value * xMagnitude) / xTotalSupply());
      xTotalDividendsDistributed = xTotalDividendsDistributed + msg.value;
    }

  }

  function xWithdrawableDividendOf(address owner_) public view returns (uint256){
    return xAccumulativeDividendOf(owner_) - xWithdrawnDividends[owner_];
  }

  function xAccumulativeDividendOf(address owner_) public view returns (uint256){
    return uint256(
      int256(xMagnifiedDividendPerShare * balanceOf(owner_)) +
      xMagnifiedDividendCorrections[owner_]
    ) / xMagnitude;
  }

  function xIsExcludedFromDividends(address account) public view returns (bool) {
    return xExcludedFromDividends[account];
  }
  function xExcludeFromDividends(address account) public onlyOwner {
    require(!xExcludedFromDividends[account]);
    xExcludedFromDividends[account] = true;
    _xSetBalance(account, 0);
    imap_remove(account);
  }

  function xUpdateGasForTransfer(uint256 newGasForTransfer) external onlyOwner {
    xGasForTransfer = newGasForTransfer;
  }
  function xUpdateClaimWait(uint256 newClaimWait) external onlyOwner {
    require(newClaimWait >= 180 && newClaimWait <= 86400,"1h-24h");
    xClaimWait = newClaimWait;
  }

  function xGetAccount(address _account) public view returns (
    address account,
    int256 index,
    int256 iterationsUntilProcessed,
    uint256 withdrawableDividends,
    uint256 totalDividends,
    uint256 lastClaimTime,
    uint256 nextClaimTime,
    uint256 secondsUntilAutoClaimAvailable
  ){
    account = _account;
    index = imap_getIndexOfKey(account);
    iterationsUntilProcessed = -1;
    if (index >= 0) {
      if (uint256(index) > xLastProcessedIndex) {
        iterationsUntilProcessed = index - int256(xLastProcessedIndex);
      } else {
        uint256 processesUntilEndOfArray = xTokenHoldersMap.keys.length >
        xLastProcessedIndex ? xTokenHoldersMap.keys.length - xLastProcessedIndex : 0;
        iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
      }
    }
    withdrawableDividends = xWithdrawableDividendOf(account);
    totalDividends = xAccumulativeDividendOf(account);
    lastClaimTime = xLastClaimTimes[account];
    nextClaimTime = lastClaimTime > 0 ? lastClaimTime + xClaimWait : 0;
    secondsUntilAutoClaimAvailable =
    nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
  }

  function _xSetBalance(address account, uint256 newBalance) private {
    require(account != address(0));
    uint256 currentBalance = balanceOf(account);
    if (newBalance > currentBalance) {
      uint256 mintAmount = newBalance - currentBalance;

      _xTotalSupply += mintAmount;
      _xbalances[account] += mintAmount;
      xMagnifiedDividendCorrections[account] =
      xMagnifiedDividendCorrections[account] -
      int256(xMagnifiedDividendPerShare * mintAmount);

    } else if (newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;

      require(account != address(0));
      uint256 accountBalance = _xbalances[account];
      require(accountBalance >= burnAmount);
      unchecked {
        _xbalances[account] = accountBalance - burnAmount;
      }
      _xTotalSupply -= burnAmount;

      xMagnifiedDividendCorrections[account] =
      xMagnifiedDividendCorrections[account] +
      int256(xMagnifiedDividendPerShare * burnAmount);

    }
  }
  function xSetBalance(address payable account, uint256 newBalance) public onlyOwner {
    if (xExcludedFromDividends[account]) {
      return;
    }
    if (newBalance >= xMinTokenBalanceForDividends) {
      _xSetBalance(account, newBalance);
      imap_set(account, newBalance);
    } else {
      _xSetBalance(account, 0);
      imap_remove(account);
    }
    xProcessAccount(account);
  }

  function xProcessAll(uint256 gas) public returns (uint256, uint256, uint256){
    uint256 numberOfTokenHolders = xTokenHoldersMap.keys.length;
    if (numberOfTokenHolders == 0) {
      return (0, 0, xLastProcessedIndex);
    }
    uint256 _xLastProcessedIndex = xLastProcessedIndex;
    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();
    uint256 iterations = 0;
    uint256 claims = 0;
    while (gasUsed < gas && iterations < numberOfTokenHolders) {
      _xLastProcessedIndex++;
      if (_xLastProcessedIndex >= xTokenHoldersMap.keys.length) {
        _xLastProcessedIndex = 0;
      }
      address account = xTokenHoldersMap.keys[_xLastProcessedIndex];

      if (xLastClaimTimes[account] < block.timestamp
      && block.timestamp - xLastClaimTimes[account] >= xClaimWait
      && xProcessAccount(payable(account))
      ) {
        claims++;
      }

      iterations++;
      uint256 newGasLeft = gasleft();
      if (gasLeft > newGasLeft) {
        gasUsed = gasUsed + (gasLeft - newGasLeft);
      }
      gasLeft = newGasLeft;
    }
    xLastProcessedIndex = _xLastProcessedIndex;
    return (iterations, claims, xLastProcessedIndex);
  }

  function xProcessAccount(address payable account) public onlyOwner returns (bool successful){
    uint256 amount = 0;
    uint256 _withdrawableDividend = xWithdrawableDividendOf(account);
    if (_withdrawableDividend > 0) {
      xWithdrawnDividends[account] =
      xWithdrawnDividends[account] +
      _withdrawableDividend;
      emit XDividendWithdrawn(account, _withdrawableDividend);
      (bool success,) = account.call{value: _withdrawableDividend, gas: xGasForTransfer}("");
      if (success) {
        amount = _withdrawableDividend;
        xLastClaimTimes[account] = block.timestamp;
        emit XClaim(account, amount);
        return true;
      }else{
        xWithdrawnDividends[account] =
        xWithdrawnDividends[account] -
        _withdrawableDividend;
        return false;
      }
    }else{return false;}
  }
  function xClaim() external {
    xProcessAccount(payable(msg.sender));
  }
  function recoverEth() external onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
  }

}