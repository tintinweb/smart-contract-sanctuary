// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./AddressUpgradeable.sol";
import "./IDEXFactory.sol";
import "./IDEXRouter.sol";
import "./IDEXPair.sol";
import "./IPinkAntiBot.sol";
import "./INEFTiLANDToken.sol";

/* solhint-disable-next-line max-states-count */
contract NEFTiLAND is
  IERC20Upgradeable,
  OwnableUpgradeable,
  INEFTiLANDToken
{
  using SafeMath for uint256;
  using AddressUpgradeable for address;

  /* solhint-disable-next-line var-name-mixedcase */
  address internal constant DEAD = address(0xdead); address internal constant ZERO = address(0); uint256 private constant MAX = ~uint256(0);
  /* solhint-disable-next-line var-name-mixedcase */
  string public VERSION;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => uint256) private _isSuspended;
  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isExcludedFromMaxTx;
  mapping(address => bool) private _isExcluded;
  address[] private _excluded;

  
  uint256 private _tTotal;                                // total supply
  uint256 private _rTotal;                                // reflection supply
  uint256 private _tFeeTotal;                             // total fee

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  uint256 public _taxFee;                                 // fee for each transaction
  uint256 private _previousTaxFee;                        // previous fee for each transaction

  uint256 public _liquidityFee;                           // fee for each liquidity
  uint256 private _previousLiquidityFee;                  // previous fee for each liquidity

  uint256 public _charityFee;                             // fee for each transaction
  uint256 private _previousCharityFee;                    // previous fee for each transaction

  IPancakeRouter02 public pancakeRouter;                  // router contract
  address public pancakePair;                             // pair contract
  address public _charityAddress;                         // address of the charity

  bool internal inSwapAndLiquify;
  bool public swapAndLiquifyEnabled;                      // if true, swap and liquify is enabled

  uint256 public _maxTxAmount;                            // max amount of tokens that can be sent in a single transaction
  uint256 private numTokensSellToAddToLiquidity;          // number of tokens to add to liquidity

  IPinkAntiBot public antiBot;                            // anti-bot contract
  bool public enableAntiBot;                              // if true, anti-bot is enabled

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;  // lock the swap and liquify
    _;                        // allow to call the function
    inSwapAndLiquify = false; // unlock the swap and liquify
  }

  function initialize(
    address owner_,             // owner of the contract
      // 0xCe8fdCb06e6471ec8164b65617C939BFe7d432f3 (TestNet)
      // 0xCe8fdCb06e6471ec8164b65617C939BFe7d432f3 (MainNet)
    string memory name_,        // NEFTiLAND
    string memory symbol_,      // NEFTI              
    uint256 totalSupply_,       // 99999999
    address router_,            // DeX Router
      // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 (TestNet)
      // 0x10ED43C718714eb63d5aA57B78B54704E256024E (MainNet)
    uint16 maxTxBps_,           // max allowed token amount (0.02 %)  2
    uint16 taxFeeBps_,          // tax fee bps amount       (4    %)  400
    uint16 liquidityFeeBps_,    // liquidity fee bps        (3    %)  300
    uint16 charityFeeBps_,      // charity fee bps          (3    %)  300
    address charityAddress_,    // address of the charity
      // 0x3b351C5cA4cdD6165ad06106CfB92B631032fD35 (TestNet)
      // 0x1F1aa0691E52a30e2088d672Eadf215EFa7B8966 (MainNet)
    address antiBot_            // address of the anti-bot
      // 0xbb06F5C7689eA93d9DeACCf4aF8546C4Fe0Bf1E5 (TestNet)
      // 0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002 (MainNet)
  )
    public initializer
  {
    __Ownable_init();
    __NEFTiLAND_init(
      owner_,
      name_,
      symbol_,
      totalSupply_,
      router_,
      maxTxBps_,
      taxFeeBps_,
      liquidityFeeBps_,
      charityFeeBps_,
      charityAddress_,
      antiBot_
    );
  }

  /* solhint-disable-next-line func-name-mixedcase */
  function __NEFTiLAND_init(
    address owner_,
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    address router_,
    uint16 maxTxBps_,
    uint16 taxFeeBps_,
    uint16 liquidityFeeBps_,
    uint16 charityFeeBps_,
    address charityAddress_,
    address antiBot_
  )
    internal initializer
  { 
    __Ownable_init();

    VERSION = "1.0.14";

    require(taxFeeBps_ >= 0 && taxFeeBps_ <= 10**4, "Invalid Tax fee");
    require(liquidityFeeBps_ >= 0 && liquidityFeeBps_ <= 10**4, "Invalid Liquidity fee");
    require(charityFeeBps_ >= 0 && charityFeeBps_ <= 10**4, "Invalid Charity fee");
    require(maxTxBps_ > 0 && maxTxBps_ <= 10**4, "Invalid max tx amount");
    if (charityAddress_ == ZERO) {
      // note: OnException: Invalid Charity address to ZERO and Charity percent more than 0
      /* solhint-disable-next-line reason-string */
      require(charityFeeBps_ == 0, "Charity percent more than 0");
    }
    // note: OnException: Total fee is over 100% of transfer amount
    /* solhint-disable-next-line reason-string */
    require(taxFeeBps_ + liquidityFeeBps_ + charityFeeBps_ <= 10**4, "Total fee overflow");

    antiBot = IPinkAntiBot(antiBot_);
    antiBot.setTokenOwner(owner_);
    enableAntiBot = false;

    transferOwnership(payable(owner_));
    
    _name = name_;
    _symbol = symbol_;
    _decimals = 9;

    _tTotal = totalSupply_ * (10**_decimals);
    _rTotal = (MAX - (MAX % _tTotal));

    _taxFee = taxFeeBps_;
    _previousTaxFee = _taxFee;

    _liquidityFee = liquidityFeeBps_;
    _previousLiquidityFee = _liquidityFee;

    _charityAddress = charityAddress_;
    _charityFee = charityFeeBps_;
    _previousCharityFee = _charityFee;

    _maxTxAmount = _tTotal.mul(maxTxBps_).div(10**4);
    numTokensSellToAddToLiquidity = _tTotal.mul(5).div(10**4); // 0.05%

    swapAndLiquifyEnabled = true;

    _rOwned[owner()] = _rTotal;

    // Create a PancakeSwap pair for this new token
    IPancakeRouter02 _pancakeRouter = IPancakeRouter02(router_);
    pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
    // set the rest of the contract variables
    pancakeRouter = _pancakeRouter;

    // exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    // exclude from max tx amount
    _isExcludedFromMaxTx[address(this)] = true;
    _isExcludedFromMaxTx[DEAD] = true;
    _isExcludedFromMaxTx[ZERO] = true;

    emit Transfer(ZERO, owner(), _tTotal);
  }

  function setVersion(string memory _version) external onlyOwner { VERSION = _version; }

  function setEnableAntiBot(bool _enable) external onlyOwner { enableAntiBot = _enable; }

  function name() public view returns (string memory) { return _name; }

  function symbol() public view returns (string memory) { return _symbol; }

  function decimals() public view returns (uint8) { return _decimals; }

  function totalSupply() public view override returns (uint256) { return _tTotal; }

  function balanceOf(address account)
    public view override
    returns (uint256)
  {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount)
    public override
    returns (bool)
  {
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

  function transferFrom(address sender, address recipient, uint256 amount)
    public override
    returns (bool)
  {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public virtual
    returns (bool)
  {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public virtual
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

  function suspend(address account, uint256 valueTo)
    public onlyOwner
  { _isSuspended[account] = valueTo; }

  function isSuspended(address account)
    public view
    returns (bool suspended, uint256 timeTo)
  /* solhint-disable-next-line not-rely-on-time */
  { return ((_isSuspended[account] > 0) && (_isSuspended[account] < block.timestamp), _isSuspended[account]); }

  function isExcludedFromReward(address account) public view returns (bool) { return _isExcluded[account]; }

  function totalFees() public view returns (uint256) { return _tFeeTotal; }

  function deliver(uint256 tAmount)
    public
  {
    address sender = _msgSender();
    // note: OnException: Excluded addresses cannot call this function
    /* solhint-disable-next-line reason-string */
    require(!_isExcluded[sender], "Unauthorized Excluded addresses");
    (uint256 rAmount, , , , , , ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    public view
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

  function tokenFromReflection(uint256 rAmount)
    public view
    returns (uint256)
  {
    // note: OnException: Amount must be less than total reflections
    /* solhint-disable-next-line reason-string */
    require(rAmount <= _rTotal, "Reflection amount overflow");
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }

  function excludeFromReward(address account)
    public onlyOwner
  {
    // require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude PancakeSwap router.');
    require(!_isExcluded[account], "Account is already excluded");
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account)
    external onlyOwner
  {
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

  function _transferBothExcluded(address sender, address recipient, uint256 tAmount)
    private
  {
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

  function excludeFromFee(address account) public onlyOwner { _isExcludedFromFee[account] = true; }

  function includeInFee(address account) public onlyOwner { _isExcludedFromFee[account] = false; }

  function setExcludeFromMaxTx(address account, bool exclude) public onlyOwner { _isExcludedFromMaxTx[account] = exclude; }

  function isExcludedFromMaxTx(address account) public view returns (bool) { return _isExcludedFromMaxTx[account]; }

  function setTaxFeePercent(uint256 taxFeeBps)
    external onlyOwner
  {
    require(taxFeeBps >= 0 && taxFeeBps <= 10**4, "Invalid bps");
    _taxFee = taxFeeBps;
  }

  function setLiquidityFeePercent(uint256 liquidityFeeBps)
    external onlyOwner
  {
    require(liquidityFeeBps >= 0 && liquidityFeeBps <= 10**4, "Invalid bps");
    _liquidityFee = liquidityFeeBps;
  }

  function setMaxTxPercent(uint256 maxTxBps)
    external onlyOwner
  {
    require(maxTxBps >= 0 && maxTxBps <= 10**4, "Invalid bps");
    _maxTxAmount = _tTotal.mul(maxTxBps).div(10**4);
  }

  function setSwapAndLiquifyEnabled(bool _enabled)
    public onlyOwner
  {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  //to recieve BNB from pancakeRouter when swaping
  /* solhint-disable-next-line no-empty-blocks */
  receive() external payable {}

  function mint(uint256 amount)
    public onlyOwner
  {
    if (_isExcluded[owner()]) {
      _tOwned[owner()] = _tOwned[owner()].add(amount);
    }
    _rOwned[owner()] = _rOwned[owner()].add(amount);
    _tTotal.add(amount);
    
    emit Transfer(ZERO, owner(), amount);
  }

  function _burn(address account, uint256 amount)
    internal
  {
    if (_isExcluded[account]) {
      _tOwned[account] = _tOwned[account].sub(amount);
    }
    _rOwned[account] = _rOwned[account].sub(amount);
    _tTotal.sub(amount);
    
    emit Transfer(account, ZERO, amount);
  }

  function burn(uint256 amount)
    public
  { _burn(_msgSender(), amount); }

  function burnFrom(address account, uint256 amount)
    public
  {
    uint256 currentAllowance = allowance(account, _msgSender());
    // solhint-disable-next-line reason-string
    require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
      _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }

  function _reflectFee(uint256 rFee, uint256 tFee)
    private
  {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount)
    private view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
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
    private view
    returns (uint256, uint256, uint256, uint256)
  {
    uint256 tFee = calcTaxFee(tAmount);
    uint256 tLiquidity = calcLiquidityFee(tAmount);
    uint256 tCharityFee = calcCharityFee(tAmount);
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
    private pure
    returns (uint256, uint256, uint256)
  {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rCharity = tCharity.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rCharity);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate()
    private view
    returns (uint256)
  {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply()
    private view
    returns (uint256, uint256)
  {
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

  function _takeLiquidity(uint256 tLiquidity)
    private
  {
    uint256 currentRate = _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function _takeCharityFee(uint256 tCharity)
    private
  {
    if (tCharity > 0) {
      uint256 currentRate = _getRate();
      uint256 rCharity = tCharity.mul(currentRate);
      _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
      if (_isExcluded[_charityAddress])
        _tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
      emit Transfer(_msgSender(), _charityAddress, tCharity);
    }
  }

  function calcTaxFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_taxFee).div(10**4); }

  function calcLiquidityFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_liquidityFee).div(10**4); }

  function calcCharityFee(uint256 _amount)
    private view
    returns (uint256)
  {
    if (_charityAddress == ZERO) return 0;
    return _amount.mul(_charityFee).div(10**4);
  }

  function removeAllFee()
    private
  {
    if (_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;
    _previousCharityFee = _charityFee;

    _taxFee = 0;
    _liquidityFee = 0;
    _charityFee = 0;
  }

  function restoreAllFee()
    private
  {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
    _charityFee = _previousCharityFee;
  }

  function isExcludedFromFee(address account) public view returns (bool) { return _isExcludedFromFee[account]; }

  function _approve(address owner, address spender, uint256 amount)
    private
  {
    /* solhint-disable-next-line reason-string */
    require(owner != ZERO, "ERC20: approve from the zero address");
    /* solhint-disable-next-line reason-string */
    require(spender != ZERO, "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(address from, address to, uint256 amount)
    private
  {
    /* solhint-disable-next-line reason-string */
    require(from != ZERO, "ERC20: transfer from the zero address");
    /* solhint-disable-next-line reason-string */
    require(to != ZERO, "ERC20: transfer to the zero address");
    // note: OnExeption: Transfer amount must be greater than zero
    /* solhint-disable-next-line reason-string */
    require(amount > 0, "Zero transfer amount");

    /* solhint-disable-next-line not-rely-on-time */
    (bool checkFrom,) = isSuspended(from);
    (bool checkTo,) = isSuspended(to);
    require( !checkFrom, "Suspended time range");
    /* solhint-disable-next-line not-rely-on-time */
    require( !checkTo, "Suspended time range");

    if (enableAntiBot) { antiBot.onPreTransferCheck(from, to, amount); }

    if (from != owner() && to != owner()) {
      if (!_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to]) {
        // note: OnExeption: Transfer amount exceeds the maxTxAmount
        /* solhint-disable-next-line reason-string */
        require(amount <= _maxTxAmount, "Transfer amount exceeds");
      }
    }

    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is PancakeSwap pair.
    uint256 contractTokenBalance = balanceOf(address(this));

    if (contractTokenBalance >= _maxTxAmount) { contractTokenBalance = _maxTxAmount; }

    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    if (overMinTokenBalance && !inSwapAndLiquify && from != pancakePair && swapAndLiquifyEnabled) {
      contractTokenBalance = numTokensSellToAddToLiquidity;
      // add liquidity
      swapAndLiquify(contractTokenBalance);
    }

    // indicates if fee should be deducted from transfer
    bool takeFee = true;

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) { takeFee = false; }

    // transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from, to, amount, takeFee);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into halves
    uint256 half = contractTokenBalance.div(2);
    uint256 otherHalf = contractTokenBalance.sub(half);

    // capture the contract's current BNB balance.
    // this is so that we can capture exactly the amount of BNB that the
    // swap creates, and not make the liquidity event include any BNB that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for BNB
    swapTokensForEth(half); // <- this breaks the BNB -> NEFTI swap when swap+liquify is triggered

    // how much BNB did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // add liquidity to PancakeSwap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the PancakeSwap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeRouter.WETH();

    _approve(address(this), address(pancakeRouter), tokenAmount);

    // make the swap
    pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of BNB
      path,
      address(this),
      /* solhint-disable-next-line not-rely-on-time */
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(pancakeRouter), tokenAmount);

    // add the liquidity
    pancakeRouter.addLiquidityETH{ value: bnbAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      /* solhint-disable-next-line not-rely-on-time */
      block.timestamp
    );
  }

  // this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee)
    private
  {
    if (!takeFee) removeAllFee();

    if (_isExcluded[sender] && !_isExcluded[recipient]) { _transferFromExcluded(sender, recipient, amount); }
    else if (!_isExcluded[sender] && _isExcluded[recipient]) { _transferToExcluded(sender, recipient, amount); }
    else if (!_isExcluded[sender] && !_isExcluded[recipient]) { _transferStandard(sender, recipient, amount); }
    else if (_isExcluded[sender] && _isExcluded[recipient]) { _transferBothExcluded(sender, recipient, amount); }
    else { _transferStandard(sender, recipient, amount); }

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

  function _transferToExcluded(address sender, address recipient, uint256 tAmount)
    private
  {
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

  function _transferFromExcluded(address sender, address recipient, uint256 tAmount)
    private
  {
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