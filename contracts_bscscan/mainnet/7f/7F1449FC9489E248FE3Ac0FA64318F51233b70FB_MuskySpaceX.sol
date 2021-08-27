pragma solidity ^0.6.12;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import './SafeMath.sol';
import './IBEP20.sol';
import './Ownable.sol';
import './Context.sol';
import './Pausable.sol';
import './Address.sol';

// SPDX-License-Identifier: Unlicensed
contract MuskySpaceX is Context, IBEP20, Pausable {
  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _rOwned;
  mapping (address => uint256) private _tOwned;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => uint256) private _balances;
  mapping (address => bool) private _isExcludedFromFee;
  mapping (address => bool) private _isExcluded;

  struct TValuesStruct {
    uint256 tTransferAmount;
    uint256 tFee;
    uint256 tLiquidity;
    uint256 tCharity;
    uint256 tBurn;
    uint256 tMarketing;
  }

  struct RValuesStruct {
    uint256 rAmount;
    uint256 rTransferAmount;
    uint256 rFee;
    uint256 rBurn;
    uint256 rLiquidity;
    uint256 rCharity;
    uint256 rMarketing;
  }

  struct ValuesStruct {
    uint256 rAmount;
    uint256 rTransferAmount;
    uint256 rFee;
    uint256 tTransferAmount;
    uint256 tFee;
    uint256 tLiquidity;
    uint256 tCharity;
    uint256 tBurn;
    uint256 tMarketing;
    uint256 rCharity;
    uint256 rBurn;
    uint256 rMarketing;
    uint256 rLiquidity;
  }

  address[] private _excluded;
  address _burnAddress = 0x000000000000000000000000000000000000dEaD;
  address public _charityWalletAddress = 0x6dD2f1Ed492076A45aED593b5C09F4a33746E447;
  address public _marketingWalletAddress = 0x3434798426F89a8BFA041903747ED76c9130C9d0;
  
  uint256 public _charityFee = 1;
  uint256 private _previousCharityFee = _charityFee;
  uint256 public _marketingFee = 1;
  uint256 private _previousMarketingFee = _marketingFee;
  uint256 public _burnFee = 2;
  uint256 private _previousBurnFee = _burnFee;
  uint256 public _taxFee = 2;
  uint256 private _previousTaxFee = _taxFee;
  uint256 public _liquidityFee = 4;
  uint256 private _previousLiquidityFee = _liquidityFee;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal = 1000000000000000 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;
  uint256 private _tBurnTotal;

  string private _name = "MuskySpaceX";
  string private _symbol = "MSX";
  
  uint8 private _decimals = 9;
  
  IUniswapV2Router02 public  uniswapV2Router;
  address public immutable uniswapV2Pair;
  
  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;
  uint256 public _maxTxAmount = 50000000000000 * 10**9;
  uint256 private numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiquidity
  );
  event Burn(address indexed burner, uint256 value);

  modifier lockTheSwap {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor() public {
    _rOwned[_msgSender()] = _rTotal;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    address _pancakeFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_pancakeFactory] = true;
    _isExcludedFromFee[_burnAddress] = true;
    _isExcluded[_burnAddress] = true;

    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  function getOwner() override external view returns (address) {
    return owner();
  }

  function decimals() override external view returns (uint8) {
    return _decimals;
  }

  function symbol() override external view returns (string memory) {
    return _symbol;
  }

  function name() override external view returns (string memory) {
    return _name;
  }

  function totalSupply() override external view returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) override public view returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount) override external whenNotPaused returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) override external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) override external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function setMarketingWallet(address newWallet) external onlyOwner() {
    _marketingWalletAddress = newWallet;
  }

  function setCharityWallet(address newWallet) external onlyOwner() {
    _charityWalletAddress = newWallet;
  }

  function transferFrom(address sender, address recipient, uint256 amount) override external whenNotPaused returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()]._sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender]._sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
    _taxFee = taxFee;
  }

  function setCharityFeePercent(uint256 charityFee) external onlyOwner() {
    _charityFee = charityFee;
  }

  function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
    _marketingFee = marketingFee;
  }

  function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
    _liquidityFee = liquidityFee;
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_taxFee).div(10**2);
  }

  function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_marketingFee).div(10**2);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    ValuesStruct memory vs = _getValues(tAmount);
    return !deductTransferFee ? vs.rAmount : vs.rTransferAmount;
  }
 
  function _transfer(address from, address to, uint256 amount) private {
    require(from != address(0), "BEP20: transfer from the zero address");
    require(to != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if(from != owner() && to != owner()) {
      require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    if(contractTokenBalance >= _maxTxAmount) contractTokenBalance = _maxTxAmount;
      
    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    if (
        overMinTokenBalance &&
        !inSwapAndLiquify &&
        from != uniswapV2Pair &&
        swapAndLiquifyEnabled
      ) {
        contractTokenBalance = numTokensSellToAddToLiquidity;
        swapAndLiquify(contractTokenBalance);
    }

    bool takeFee = true;

    if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) takeFee = false;
    _tokenTransfer(from, to, amount, takeFee);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function isExcludedFromReward(address account) external view returns (bool) {
    return _isExcluded[account];
  }

  function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
    _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;

    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  receive() external payable {}

  function rescueBNBFromContract() external onlyOwner {
    address _owner = _msgSender();
    payable(_owner).transfer(address(this).balance);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    uint256 half = contractTokenBalance.div(2);
    uint256 otherHalf = contractTokenBalance.sub(half);
    uint256 initialBalance = address(this).balance;

    swapTokensForEth(half);

    uint256 newBalance = address(this).balance.sub(initialBalance);

    addLiquidity(otherHalf, newBalance);
    
    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function totalFees() external view returns (uint256) {
    return _tFeeTotal;
  }

  function totalBurn() public view returns (uint256) {
    return _tBurnTotal;
  }

  function deliver(uint256 tAmount) external {
    address sender = _msgSender();
    require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    ValuesStruct memory vs = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _rTotal = _rTotal.sub(vs.rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.addLiquidityETH{value: bnbAmount}(
      address(this),
      tokenAmount,
      0,
      0,
      owner(),
      block.timestamp
    );
  }

  function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_liquidityFee).div(
        10**2
    );
  }

  function removeAllFee() private {
    if(_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0 && _burnFee == 0 && _marketingFee == 0) return;
    
    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;
    _previousBurnFee = _burnFee;
    _previousMarketingFee = _marketingFee;
    
    _taxFee = 0;
    _liquidityFee = 0;
    _burnFee = 0;
    _charityFee = 0;
    _marketingFee = 0;
  }
  
  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
    _charityFee = _previousCharityFee;
    _burnFee = _previousBurnFee;
    _marketingFee = _previousMarketingFee;
  }
  
  function isExcludedFromFee(address account) public view returns(bool) {
    return _isExcludedFromFee[account];
  }

  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate =  _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);

    if(_isExcluded[address(this)])
      _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }
  

  function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
    _rOwned[_marketingWalletAddress] = _rOwned[_marketingWalletAddress].add(rMarketing);

    if (_isExcluded[_marketingWalletAddress]) {
        _tOwned[_marketingWalletAddress] = _tOwned[_marketingWalletAddress].add(tMarketing);
    }
  }

  function _takeCharity(uint256 rCharity, uint256 tCharity) private {
    _rOwned[_charityWalletAddress] = _rOwned[_charityWalletAddress].add(rCharity);

    if (_isExcluded[_charityWalletAddress]) {
        _tOwned[_charityWalletAddress] = _tOwned[_charityWalletAddress].add(tCharity);
    }
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

  function _getValues(uint256 tAmount) private view returns (ValuesStruct memory) {
    TValuesStruct memory tvs = _getTValues(tAmount);
    RValuesStruct memory rvs = _getRValues(tAmount, tvs, _getRate());
    return ValuesStruct(rvs.rAmount, rvs.rTransferAmount, rvs.rFee, tvs.tTransferAmount, tvs.tFee, tvs.tLiquidity, tvs.tCharity, tvs.tBurn, tvs.tMarketing, rvs.rCharity, rvs.rBurn, rvs.rMarketing, rvs.rLiquidity);
  }

  function _getTValues(uint256 tAmount) private view returns (TValuesStruct memory) {  
    uint256 tFee = calculateTaxFee(tAmount);
    uint256 tBurn = calculateBurnFee(tAmount);
    uint256 tMarketing = calculateMarketingFee(tAmount);
    uint256 tLiquidity = calculateLiquidityFee(tAmount);
    uint256 tCharity = calculateCharityFee(tAmount)*2;
    uint256 deductFee = tBurn.add(tCharity).add(tMarketing);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(deductFee);

    return TValuesStruct(tTransferAmount, tFee, tLiquidity, tCharity, tBurn, tMarketing);
  }

  function calculateCharityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_charityFee).div(10**2);
  }

  function calculateBurnFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_burnFee).div(10**2);
  }

  function _getRValues(uint256 tAmount, TValuesStruct memory tvs, uint256 currentRate) private pure returns (RValuesStruct memory) {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tvs.tFee.mul(currentRate);
    uint256 rBurn = tvs.tBurn.mul(currentRate);
    uint256 rLiquidity = tvs.tLiquidity.mul(currentRate);
    uint256 rCharity = tvs.tCharity.mul(currentRate);
    uint256 rMarketing = tvs.tMarketing.mul(currentRate);
    uint256 deductFee = rCharity.add(rBurn).add(rMarketing);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(deductFee);

    return RValuesStruct(rAmount, rTransferAmount, rFee, rBurn, rLiquidity, rCharity, rMarketing);
  }

  function _getRate() private view returns(uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate =  _getRate();
    return rAmount.div(currentRate);
  }

  function excludeFromReward(address account) public onlyOwner() {
    require(!_isExcluded[account], "Account is already excluded");
    if(_rOwned[account] > 0) {
        _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner() {
    require(_isExcluded[account], "Account is not excluded");
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

  function _distributeFee(uint256 tLiquidity, uint256 rMarketing, uint256 rCharity, uint256 tFee, uint256 rFee, uint256 tBurn, uint256 tCharity, uint256 tMarketing) private {
    _takeLiquidity(tLiquidity);
    _takeCharity(rCharity, tCharity);
    _takeMarketing(rMarketing, tMarketing);

    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
    _tBurnTotal = _tBurnTotal.add(tBurn);
    
    _rOwned[_burnAddress] = _rOwned[_burnAddress].add(tBurn);

    if (_isExcluded[_burnAddress]) {
        _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tBurn);
    }
  }

  function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
    if(!takeFee) removeAllFee();

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }
    if(recipient == _burnAddress) {

    }
    
    if(!takeFee) restoreAllFee();
  }

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    ValuesStruct memory vs = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(vs.tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);        
    _distributeFee(vs.tLiquidity, vs.rMarketing, vs.rCharity, vs.tFee, vs.rFee, vs.tBurn, vs.tCharity, vs.tMarketing);
    emit Transfer(sender, recipient, vs.tTransferAmount);
  }

  function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    ValuesStruct memory vs = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);
    _distributeFee(vs.tLiquidity, vs.rMarketing, vs.rCharity, vs.tFee, vs.rFee, vs.tBurn, vs.tCharity, vs.tMarketing);
    emit Transfer(sender, recipient, vs.tTransferAmount);
  }

  function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
    ValuesStruct memory vs = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(vs.tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);           
    _distributeFee(vs.tLiquidity, vs.rMarketing, vs.rCharity, vs.tFee, vs.rFee, vs.tBurn, vs.tCharity, vs.tMarketing);
    emit Transfer(sender, recipient, vs.tTransferAmount);
  }

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
    ValuesStruct memory vs = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(vs.rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(vs.rTransferAmount);   
    _distributeFee(vs.tLiquidity, vs.rMarketing, vs.rCharity, vs.tFee, vs.rFee, vs.tBurn, vs.tCharity, vs.tMarketing);
    emit Transfer(sender, recipient, vs.tTransferAmount);
  }
}