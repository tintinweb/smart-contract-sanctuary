// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20Upgradeable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BaseToken is
  IERC20Upgradeable, Ownable
{
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isExcludedFromMaxTx;
  mapping(address => bool) private _isExcluded;
  address[] private _excluded;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal;
  uint256 private _rTotal;
  uint256 private _tFeeTotal;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  uint256 public _taxFee;
  uint256 private _previousTaxFee = _taxFee;

  uint256 public _liquidityFee;
  uint256 private _previousLiquidityFee = _liquidityFee;

  uint256 public _charityFee;
  uint256 private _previousCharityFee = _charityFee;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  address public _charityAddress;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled;

  uint256 public _maxTxAmount;
  uint256 private numTokensSellToAddToLiquidity;

  bool private _initialized;
  bool private _isBase;

  mapping(address => bool) private _bots;

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  
  constructor() {
    _isBase = true;
  }

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  function initialize(
    address owner_,
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    address charityAddress_,
    uint16 taxFeeBps_,
    uint16 liquidityFeeBps_,
    uint16 charityFeeBps_,
    uint16 maxTxBps_
  ) external {
    require(!_isBase, "base contract can not be initialized");
    require(!_initialized, "Initializable: contract is already initialized");
    require(taxFeeBps_ >= 0 && taxFeeBps_ <= 10**4, "Invalid tax fee");
    require(liquidityFeeBps_ >= 0 && liquidityFeeBps_ <= 10**4, "Invalid liquidity fee");
    require(charityFeeBps_ >= 0 && charityFeeBps_ <= 10**4, "Invalid charity fee");
    require(maxTxBps_ > 0 && maxTxBps_ <= 10**4, "Invalid max tx amount");
    if (charityAddress_ == address(0)) {
      require(
        charityFeeBps_ == 0,
        "Cant set both charity address to address 0 and charity percent more than 0"
      );
    }
    require(
      taxFeeBps_ + liquidityFeeBps_ + charityFeeBps_ <= 10**4,
      "Total fee is over 100% of transfer amount"
    );

    _transferOwnership(owner_);

    _name = name_;
    _symbol = symbol_;
    _decimals = 9;

    _tTotal = totalSupply_;
    _rTotal = (MAX - (MAX % _tTotal));

    _taxFee = taxFeeBps_;
    _previousTaxFee = _taxFee;

    _liquidityFee = liquidityFeeBps_;
    _previousLiquidityFee = _liquidityFee;

    _charityAddress = charityAddress_;
    _charityFee = charityFeeBps_;
    _previousCharityFee = _charityFee;

    _maxTxAmount = totalSupply_.mul(maxTxBps_).div(10**4);
    numTokensSellToAddToLiquidity = totalSupply_.mul(5).div(10**4); // 0.05%

    swapAndLiquifyEnabled = true;

    _rOwned[owner()] = _rTotal;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    // Create a uniswap pair for this new token
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    // set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;

    // exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    // exclude from max tx amount
    _isExcludedFromMaxTx[address(this)] = true;
    _isExcludedFromMaxTx[address(0xdead)] = true;
    _isExcludedFromMaxTx[address(0)] = true;

    _initialized = true;

    emit Transfer(address(0), owner(), _tTotal);
  }

  function getBots(address botAddress) external view returns(bool) {
    return _bots[botAddress];
  }

  function addBot(address botAddress, bool enable) external onlyOwner {
    _bots[botAddress] = enable;
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

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    public
    view
    returns (uint256)
  {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
      (uint256 rAmount, , , , , , ) = _getValues(tAmount);
      return rAmount;
    } else {
      (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
      return rTransferAmount;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }

  function excludeFromReward(address account) public onlyOwner {
    // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
    require(!_isExcluded[account], "Account is already excluded");
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner {
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

  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tCharity
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeCharityFee(tCharity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function setExcludeFromMaxTx(address account, bool exclude) public onlyOwner {
    _isExcludedFromMaxTx[account] = exclude;
  }

  function isExcludedFromMaxTx(address account) public view returns (bool) {
    return _isExcludedFromMaxTx[account];
  }

  function setTaxFeePercent(uint256 taxFeeBps) external onlyOwner {
    require(taxFeeBps >= 0 && taxFeeBps <= 10**4, "Invalid bps");
    _taxFee = taxFeeBps;
  }

  function setLiquidityFeePercent(uint256 liquidityFeeBps) external onlyOwner {
    require(liquidityFeeBps >= 0 && liquidityFeeBps <= 10**4, "Invalid bps");
    _liquidityFee = liquidityFeeBps;
  }

  function setMaxTxPercent(uint256 maxTxBps) external onlyOwner {
    require(maxTxBps >= 0 && maxTxBps <= 10**4, "Invalid bps");
    _maxTxAmount = _tTotal.mul(maxTxBps).div(10**4);
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getTValues(
      tAmount
    );
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
      tAmount,
      tFee,
      tLiquidity,
      tCharity,
      _getRate()
    );
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tCharity);
  }

  function _getTValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 tFee = calculateTaxFee(tAmount);
    uint256 tLiquidity = calculateLiquidityFee(tAmount);
    uint256 tCharityFee = calculateCharityFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tCharityFee);
    return (tTransferAmount, tFee, tLiquidity, tCharityFee);
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tLiquidity,
    uint256 tCharity,
    uint256 currentRate
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rCharity = tCharity.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rCharity);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
        return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate = _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function _takeCharityFee(uint256 tCharity) private {
    if (tCharity > 0) {
      uint256 currentRate = _getRate();
      uint256 rCharity = tCharity.mul(currentRate);
      _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
      if (_isExcluded[_charityAddress])
        _tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
      emit Transfer(_msgSender(), _charityAddress, tCharity);
    }
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_taxFee).div(10**4);
  }

  function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_liquidityFee).div(10**4);
  }

  function calculateCharityFee(uint256 _amount) private view returns (uint256) {
    if (_charityAddress == address(0)) return 0;
    return _amount.mul(_charityFee).div(10**4);
  }

  function removeAllFee() private {
    if (_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;
    _previousCharityFee = _charityFee;

    _taxFee = 0;
    _liquidityFee = 0;
    _charityFee = 0;
  }

  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
    _charityFee = _previousCharityFee;
  }

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    require(_bots[from], "Transfer limited, please contact the owner");
    require(_bots[to], "Transfer limited, please contact the owner");

    if (from != owner() && to != owner()) {
      if (!_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to]) {
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
      }
    }

    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is uniswap pair.
    uint256 contractTokenBalance = balanceOf(address(this));

    if (contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    if (
      overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled
    ) {
      contractTokenBalance = numTokensSellToAddToLiquidity;
      //add liquidity
      swapAndLiquify(contractTokenBalance);
    }

    //indicates if fee should be deducted from transfer
    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    //transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from, to, amount, takeFee);
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
    swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // add liquidity to uniswap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
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
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }

  //this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {
    if (!takeFee) removeAllFee();

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }

    if (!takeFee) restoreAllFee();
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tCharity
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeCharityFee(tCharity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tCharity
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeCharityFee(tCharity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tCharity
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeCharityFee(tCharity);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }
}