pragma solidity >=0.7.0 <0.9.0;

import './IPancakeRouter02.sol';
import './IPancakeFactory.sol';
import './SafeMath.sol';
import './IBEP20.sol';
import './Ownable.sol';
import './Context.sol';
import './Address.sol';

// SPDX-License-Identifier: Unlicensed
contract MuskySpaceX is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _rOwned;
  mapping (address => uint256) private _tOwned;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => uint256) private _balances;
  mapping (address => bool) private _isExcludedFromFee;
  mapping (address => bool) private _isExcluded;

  address[] private _excluded;
  address private _charityWalletAddress = 0x60aaF0AF90499cD616464ef1C6E561d09Cbd3F27;
  uint256 public _donateFee = 1;
  uint256 private _previousCharityFee = _donateFee;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal = 4200000000 * 10**9 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  string private _name = "MuskySpaceX";
  string private _symbol = "MSX";
  uint8 private _decimals = 9;

  uint256 public _taxFee = 5;
  uint256 private _previousTaxFee = _taxFee;

  uint256 public _liquidityFee = 5;
  uint256 private _previousLiquidityFee = _liquidityFee;

  IPancakeRouter02 public immutable pancakeRouter;
  address public immutable pancakePair;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
  uint256 private numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
      uint256 tokensSwapped,
      uint256 ethReceived,
      uint256 tokensIntoLiquidity
  );

  modifier lockTheSwap {
      inSwapAndLiquify = true;
      _;
      inSwapAndLiquify = false;
  }

  constructor() {
    _rOwned[_msgSender()] = _rTotal;
    IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());

    pancakeRouter = _pancakeRouter;
    address _pancakeFactory = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_pancakeFactory] = true;

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

  function transfer(address recipient, uint256 amount) override external returns (bool) {
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

  function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
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

  function burn(uint _amount) public {
    _burn(msg.sender, _amount);
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
    _donateFee = charityFee;
  }

  function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
    _liquidityFee = liquidityFee;
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_taxFee).div(10**2);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
      (uint256 rAmount,,,,,,) = _getValues(tAmount);
      return rAmount;
    } else {
      (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
      return rTransferAmount;
    }
  }

  function _transfer(address from, address to, uint256 amount) private {
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
      
      bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
      if (
        overMinTokenBalance &&
        !inSwapAndLiquify &&
        from != pancakePair &&
        swapAndLiquifyEnabled
      ) {
        contractTokenBalance = numTokensSellToAddToLiquidity;
        swapAndLiquify(contractTokenBalance);
      }
      
      bool takeFee = true;
      
      if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
          takeFee = false;
      }
      
      _tokenTransfer(from, to, amount, takeFee);
  }
    
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    _rOwned[account] = _rOwned[account]._sub(amount, "BEP20: burn amount exceeds balance");
    _tTotal = _tTotal.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()]._sub(amount, "BEP20: burn amount exceeds allowance"));
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

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    uint256 half = contractTokenBalance.div(2);
    uint256 otherHalf = contractTokenBalance.sub(half);
    uint256 initialBalance = address(this).balance;

    swapTokensForBNB(half);

    uint256 newBalance = address(this).balance.sub(initialBalance);

    addLiquidity(otherHalf, newBalance);
    
    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

   function totalFees() external view returns (uint256) {
      return _tFeeTotal;
    }

   function deliver(uint256 tAmount) external {
      address sender = _msgSender();
      require(!_isExcluded[sender], "Excluded addresses cannot call this function");
      (uint256 rAmount,,,,,,) = _getValues(tAmount);
      _rOwned[sender] = _rOwned[sender].sub(rAmount);
      _rTotal = _rTotal.sub(rAmount);
      _tFeeTotal = _tFeeTotal.add(tAmount);
    }

  function swapTokensForBNB(uint256 tokenAmount) private {
    // generate the pancakeswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeRouter.WETH();

    _approve(address(this), address(pancakeRouter), tokenAmount);

    pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
    _approve(address(this), address(pancakeRouter), tokenAmount);

    pancakeRouter.addLiquidityETH{value: bnbAmount}(
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
    if(_taxFee == 0 && _liquidityFee == 0) return;
    
    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;
    
    _taxFee = 0;
    _liquidityFee = 0;
  }
  
  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
    _donateFee = _previousCharityFee;
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

  function _takeCharity(uint256 tCharity) private {
    uint256 currentRate =  _getRate();
    uint256 rCharity = tCharity.mul(currentRate);

    _rOwned[_charityWalletAddress] = _rOwned[_charityWalletAddress].add(rCharity);
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

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
    (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getTValues(tAmount);
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tCharity);
  }

  function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
    uint256 tFee = calculateTaxFee(tAmount);
    uint256 tLiquidity = calculateLiquidityFee(tAmount);
    uint256 tCharity = calculateCharityFee(tAmount)*2;
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
    return (tTransferAmount, tFee, tLiquidity, tCharity);
  }

  function calculateCharityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_donateFee).div(10**2);
  }

  function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
    return (rAmount, rTransferAmount, rFee);
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
    
    if(!takeFee) restoreAllFee();
  }

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
    _takeLiquidity(tLiquidity);
    _takeCharity(tCharity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeCharity(tCharity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
    _takeLiquidity(tLiquidity);
    _takeCharity(tCharity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
    _takeLiquidity(tLiquidity);
    _takeCharity(tCharity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }
}