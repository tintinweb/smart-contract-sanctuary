/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}


interface IBEP20 {

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);


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

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

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
    return now;
  }

  function lock(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = now + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  function unlock() public virtual {
    require(_previousOwner == msg.sender, "You don't have permission to unlock");
    require(now > _lockTime , "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }
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

/*
PandaHelp (PANDAHELP):
5% liquidity pool
4% distribution among holders
1% charity/marketing wallet
*/

interface IPandaStake {
  function updateRXBalances(address account) external returns (uint256);
  function getTransferXFee(address account, uint256 rAmount) external returns (uint256, uint256);
  function addToRXBalance(address account, uint256 rAmount) external returns (uint256);
}

contract PandaHelp is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _rOwned;
  mapping (address => uint256) private _tOwned;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _isExcludedFromFee;

  mapping (address => bool) private _isExcluded;
  address[] private _excluded;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal = 1* 10**6 * 10**6 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;
  uint256 private _tCharityTotal;
  address private _charityAddress;

  string private _name = "PandaHelp";
  string private _symbol = "PANDAHELP";
  uint8 private _decimals = 9;

  mapping (address => uint256) private freeXBalances;

  uint256 public _taxFee = 4;
  uint256 private _previousTaxFee = _taxFee;

  uint256 public _charityFee = 1;
  uint256 private _previousCharityFee = _charityFee;


  uint256 public _liquidityFee = 5;
  uint256 private _previousLiquidityFee = _liquidityFee;


  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  IPandaStake public immutable pandaStake;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  // 0.5 %
  uint256 public _maxTxAmount = 5 * 10**3 * 10**6 * 10**9;
  uint256 private minimumTokensBeforeSwap = 500000 * 10**6 * 10**9;
  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ETHReceived,
    uint256 tokensIntoLiqudity
  );

  event Developer(bool ok, uint256 num, string name);

  modifier lockTheSwap {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  struct RValuesStruct {
    uint256 rAmount;
    uint256 rTransferAmount;
    uint256 rFee;
    uint256 rCharity;
    uint256 currentRate;
  }

  struct TValuesStruct {
    uint256 tTransferAmount;
    uint256 tFee;
    uint256 tCharity;
    uint256 tLiquidity;
  }

  struct ValuesStruct {
    uint256 rAmount;
    uint256 rTransferAmount;
    uint256 rFee;
    uint256 rCharity;
    uint256 tTransferAmount;
    uint256 tFee;
    uint256 tCharity;
    uint256 tLiquidity;
    uint256 currentRate;
  }

  constructor (address charityAddress, address pandaStakeAddress) public {
    _rOwned[_msgSender()] = _rTotal;
    freeXBalances[_msgSender()] = _rTotal;
    _charityAddress = charityAddress;

    IPandaStake _pandaStake = IPandaStake(pandaStakeAddress);
    pandaStake = _pandaStake;
//  testnet
//  IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    setRouterAddress(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    emit Transfer(address(0), _msgSender(), _tTotal);
  }
  
  function setRouterAddress(address newRouter) public onlyOwner() {
    uniswapV2Router = IUniswapV2Router02(newRouter);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
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

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function updateFreeBalance(address account) public returns (uint256) {
    uint256 free = pandaStake.updateRXBalances(account);
    freeXBalances[account] = freeXBalances[account].add(free);
    return tokenFromReflection(freeXBalances[account]);
  }

  function freeBalance(address account) public view returns (uint256) {
    return tokenFromReflection(freeXBalances[account]);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function totalCharity() public view returns (uint256) {
    return _tCharityTotal;
  }

  function minimumTokensBeforeSwapAmount() public view returns (uint256) {
    return minimumTokensBeforeSwap;
  }

  function deliver(uint256 tAmount) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    uint256 rAmount = _getValues(sender, tAmount).rAmount;
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public returns(uint256) {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
      uint256 rAmount= _getValues(_msgSender(), tAmount).rAmount;
      return rAmount;
    } else {
      uint256 rTransferAmount = _getValues(_msgSender(), tAmount).rTransferAmount;
      return rTransferAmount;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate =  _getRate();
    return rAmount.div(currentRate);
  }

  function excludeFromReward(address account) public onlyOwner() {
    // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
    require(!_isExcluded[account], "Account is already excluded");
    require(_excluded.length < 256);
    if(_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner() {
    require(_isExcluded[account], "Account is already excluded");
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

  function setAccountFeeEnabled(address account, bool value) public onlyOwner {
    _isExcludedFromFee[account] = value;
  }

  function setCharityAddress(address charityAddress) external onlyOwner() {
    _charityAddress = charityAddress;
  }

  function setTaxFeePercent(uint256 taxFee, uint256 charityFee, uint256 liquidityFee) external onlyOwner() {
    _taxFee = taxFee;
    _charityFee = charityFee;
    _liquidityFee = liquidityFee;
  }

  function setMaxTxPercent(uint256 maxTxPercent, uint256 maxTxDecimals) external onlyOwner() {
    _maxTxAmount = _tTotal.mul(maxTxPercent).div(
      10**(maxTxDecimals.add(2))
    );
  }

  function setMinimumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
    minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    emit MinTokensBeforeSwapUpdated(_minimumTokensBeforeSwap);
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function _reflectFee(uint256 rFee, uint256 rCharity, uint256 tFee, uint256 tCharity) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
    _tCharityTotal = _tCharityTotal.add(tCharity);
    _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
    _tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
  }

  function _getValues(address sender, uint256 tAmount) private returns (ValuesStruct memory) {
    uint256 currentRate = _getRate();
    TValuesStruct memory tvs = _getTValues(tAmount);
    RValuesStruct memory rvs = _getRValues(tAmount, tvs.tFee, tvs.tCharity, tvs.tLiquidity, currentRate);

    emit Developer(true, rvs.rAmount, "Before call in ValuesStruct");

    if (freeXBalances[sender] < rvs.rAmount) {
      (uint256 rXFee, uint256 free) = pandaStake.getTransferXFee(sender, rvs.rAmount - freeXBalances[sender]);
      freeXBalances[sender] = free;
      uint256 tXFee = rXFee.div(currentRate);

      tvs.tCharity = tvs.tCharity.add(tXFee);
      rvs.rCharity = rvs.rCharity.add(rXFee);
      tvs.tTransferAmount = tvs.tTransferAmount.sub(tXFee);
      rvs.rTransferAmount = rvs.rTransferAmount.sub(rXFee);
    }
    return ValuesStruct(
      rvs.rAmount,
      rvs.rTransferAmount,
      rvs.rFee,
      rvs.rCharity,
      tvs.tTransferAmount,
      tvs.tFee,
      tvs.tCharity,
      tvs.tLiquidity,
      rvs.currentRate
    );
  }

  function _getTValues(uint256 tAmount) private view returns (TValuesStruct memory) {
    uint256 tFee = calculateTaxFee(tAmount);
    uint256 tCharity = calculateCharityFee(tAmount);
    uint256 tLiquidity = calculateLiquidityFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tCharity).sub(tLiquidity);
    return TValuesStruct(tTransferAmount, tFee, tCharity, tLiquidity);
  }

  function _getRValues(uint256 tAmount, uint256 tFee, uint256 tCharity, uint256 tLiquidity, uint256 currentRate) private pure returns (RValuesStruct memory) {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rCharity = tCharity.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rCharity).sub(rLiquidity);
    return RValuesStruct(rAmount, rTransferAmount, rFee, rCharity, currentRate);

  }

  function _getRate() private view returns(uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns(uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity, uint256 currentRate) private {
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if(_isExcluded[address(this)])
      _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_taxFee).div(
      10**2
    );
  }

  function calculateCharityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_charityFee).div(
      10**2
    );
  }

  function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_liquidityFee).div(
      10**2
    );
  }

  function removeAllFee() private {
    if(_taxFee == 0 && _charityFee == 0 && _liquidityFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousCharityFee = _charityFee;
    _previousLiquidityFee = _liquidityFee;

    _taxFee = 0;
    _charityFee = 0;
    _liquidityFee = 0;
  }

  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _charityFee = _previousCharityFee;
    _liquidityFee = _previousLiquidityFee;
  }

  function isExcludedFromFee(address account) public view returns(bool) {
    return _isExcludedFromFee[account];
  }

  function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), "BEP20: transfer from the zero address");
    require(to != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    if(from != owner() && to != owner())
      require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");


    uint256 contractTokenBalance = balanceOf(address(this));

    if(contractTokenBalance >= _maxTxAmount)
    {
      contractTokenBalance = _maxTxAmount;
    }

    bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
    if (
      overMinimumTokenBalance &&
      !inSwapAndLiquify &&
      from != uniswapV2Pair &&
      swapAndLiquifyEnabled
    ) {
      contractTokenBalance = minimumTokensBeforeSwap;
      swapAndLiquify(contractTokenBalance);
    }

    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
      takeFee = false;
    }

    _tokenTransfer(from,to,amount,takeFee);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into halves
    uint256 half = contractTokenBalance.div(2);
    uint256 otherHalf = contractTokenBalance.sub(half);

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForETH(half);

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // add liquidity to uniswap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForETH(uint256 tokenAmount) private {
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
      address(this), // The contract
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(this),
      block.timestamp
    );
  }

  function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
    if(!takeFee)
      removeAllFee();

    emit Developer(true, 0, "Before ValuesStruct");
    ValuesStruct memory vs = _getValues(sender, amount);
    // excludes DxSale from fee
    if (_isExcludedFromFee[recipient]) {
      freeXBalances[recipient] = freeXBalances[recipient].add(vs.rAmount);
    } else {
      uint256 free = pandaStake.addToRXBalance(recipient, vs.rAmount);
      freeXBalances[recipient] = freeXBalances[recipient].add(free);
    }

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount, vs);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, vs);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount, vs);
    } else {
      _transferStandard(sender, recipient, vs);
    }

    _reflectFee(vs.rFee, vs.rCharity, vs.tFee, vs.tCharity);
    _takeLiquidity(vs.tLiquidity, vs.currentRate);
    emit Developer(true, 0, "After all");
    if(!takeFee)
      restoreAllFee();
  }

  function _transferStandard(address sender, address recipient, ValuesStruct memory vs) private {
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
    emit Transfer(sender, recipient, vs.tTransferAmount);
  }

  function _transferToExcluded(address sender, address recipient, ValuesStruct memory vs) private {
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(vs.tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
    emit Transfer(sender, recipient, vs.tTransferAmount);
  }

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
    emit Transfer(sender, recipient, vs.tTransferAmount);
  }

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(vs.tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
    emit Transfer(sender, recipient, vs.tTransferAmount);
  }

  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}
}