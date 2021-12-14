// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "./SafeMath.sol";
import "./AddressUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./IDEXFactory.sol";
import "./IDEXRouter.sol";
import "./IDEXPair.sol";
import "./IPinkAntiBot.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";


/**
 * @dev Implementation of the {IERC20} interface with 3rd party of DEX services.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
/* solhint-disable-next-line max-states-count */
contract NEFTiLAND is
  // Initializable,
  OwnableUpgradeable,
  IERC20MetadataUpgradeable,
  ReentrancyGuardUpgradeable
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

  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 private _tTotal;                       // total supply
  uint256 private _rTotal;                       // reflection supply
  uint256 private _tFeeTotal;                    // total fee

  uint256 public _taxFee;                        // fee for each transaction
  uint256 private _previousTaxFee;               // previous fee for each transaction

  uint256 public _liquidityFee;                  // fee for each liquidity
  uint256 private _previousLiquidityFee;         // previous fee for each liquidity

  uint256 public _marketingFee;                  // fee for each transaction
  uint256 private _previousMarketingFee;         // previous fee for each transaction

  IPancakeRouter02 public pancakeRouter;         // router contract
  address public pancakePair;                    // pair contract
  address public _supportAddress;                // support address
  address public _marketingAddress;              // marketing address

  bool internal inSwapAndLiquify;
  bool public swapAndLiquifyEnabled;             // if true, swap and liquify is enabled

  uint256 public _maxTxAmount;                   // max amount of tokens that can be sent in a single transaction
  uint256 private numTokensSellToAddToLiquidity; // number of tokens to add to liquidity

  IPinkAntiBot public antiBot;                   // anti-bot contract
  bool public enableAntiBot;                     // if true, anti-bot is enabled

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;  // lock the swap and liquify
    _;                        // allow to call the function
    inSwapAndLiquify = false; // unlock the swap and liquify
  }

  /** 
   * @dev Initialize method, sets intialization the value for parameters:
   * 
   * @param owner_ address: Owner of the contract
   * @param name_ string: Contract name
   * @param symbol_ string: Contract symbol
   * @param totalSupply_ uint256: Total supply of tokens
   * @param router_ address: DeX Router
   * @param maxTxBps_ uint16: Max allowed token amount (0.02%), input example 2
   * @param taxFeeBps_ uint16: Tax fee bps amount (4%), input example 400
   * @param liquidityFeeBps_ uint16: Liquidity fee bps (3%), input example 300
   * @param marketingFeeBps_ uint16: Charity fee bps (3%), input example 300
   * @param operationAddresses_ address[]: Contract operational [support, marketing]
   * @param antiBot_ address: Address of the anti-bot
   *
   * 
   */
  function initialize(
    address owner_,
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    address router_,
    uint16 maxTxBps_,
    uint16 taxFeeBps_,
    uint16 liquidityFeeBps_,
    uint16 marketingFeeBps_,
    address[2] memory operationAddresses_,
    address antiBot_
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
      marketingFeeBps_,
      operationAddresses_,
      antiBot_
    );
  }


  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
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
    uint16 marketingFeeBps_,
    address[2] memory operationAddresses_,
    address antiBot_
  )
    internal initializer
  { 
    VERSION = "1.0.23";

    require(taxFeeBps_ >= 0 && taxFeeBps_ <= 10**4, "Invalid Tax fee");
    require(liquidityFeeBps_ >= 0 && liquidityFeeBps_ <= 10**4, "Invalid Liquidity fee");
    require(marketingFeeBps_ >= 0 && marketingFeeBps_ <= 10**4, "Invalid Marketing fee");
    require(maxTxBps_ > 0 && maxTxBps_ <= 10**4, "Invalid max tx amount");
    if (operationAddresses_[1] == ZERO) {
      // note: OnException: Invalid Marketing address to ZERO and Marketing percent more than 0
      /* solhint-disable-next-line reason-string */
      require(marketingFeeBps_ == 0, "Marketing percent more than 0");
    }
    // note: OnException: Total fee is over 100% of transfer amount
    /* solhint-disable-next-line reason-string */
    require(taxFeeBps_ + liquidityFeeBps_ + marketingFeeBps_ <= 10**4, "Total fee overflow");

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

    _supportAddress = operationAddresses_[0];
    _marketingAddress = operationAddresses_[1];
    _marketingFee = marketingFeeBps_;
    _previousMarketingFee = _marketingFee;

    _maxTxAmount = _tTotal.mul(maxTxBps_).div(10**4);
    numTokensSellToAddToLiquidity = _tTotal.mul(5).div(10**4); // 0.05%

    swapAndLiquifyEnabled = true;

    _rOwned[owner()] = _rTotal;

    // note: Create a PancakeSwap pair for this new token
    IPancakeRouter02 _pancakeRouter = IPancakeRouter02(router_);
    pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
    
    // note: Set the rest of the contract variables
    pancakeRouter = _pancakeRouter;

    initVars(owner_);
    emit Transfer(ZERO, owner_, _tTotal);
  }

  function initVars(address owner_) internal initializer {
    swapAndLiquifyEnabled = true;
    _rOwned[owner_] = _rTotal;
    _isExcluded[address(this)] = true;
    // _isExcluded[_supportAddress] = true;
    // _isExcluded[_marketingAddress] = true;
    
    // note: Exclude owner and this contract from fee
    _isExcludedFromFee[owner_] = true;
    _isExcludedFromFee[address(this)] = true;
    
    // note: Exclude from max tx amount
    _isExcludedFromMaxTx[address(this)] = true;
    _isExcludedFromMaxTx[owner_] = true;
    _isExcludedFromMaxTx[DEAD] = true;
    _isExcludedFromMaxTx[ZERO] = true;
  }

  function setVersion(string memory _version) external onlyOwner { VERSION = _version; }

  function setEnableAntiBot(bool _enable) external onlyOwner { enableAntiBot = _enable; }


  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) { return _name; }

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() public view returns (string memory) { return _symbol; }

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() public view returns (uint8) { return _decimals; }

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() public view override returns (uint256) { return _tTotal; }

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account)
    public view override
    returns (uint256)
  {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function reflectOf(address account)
    public view
    returns (uint256)
  { return _rOwned[account]; }

  function setSupportAccounts(address support, address marketing)
    public onlyOwner
  { _supportAddress = support; _marketingAddress = marketing; }

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount)
    public override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    public view override
    returns (uint256)
  { return _allowances[owner][spender]; }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    public override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
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

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public virtual
    returns (bool)
  {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
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
  {
    /* solhint-disable-next-line not-rely-on-time */
    return ((_isSuspended[account] > 0) && (_isSuspended[account] < block.timestamp), _isSuspended[account]);
  }

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
      uint256 tMarketing
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeMarketingFee(tMarketing);
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

  // note: To recieve BNB from pancakeRouter when swaping
  /* solhint-disable-next-line no-empty-blocks */
  receive() external payable {}

  
  /** 
   * @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
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

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
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

  /**
   * @dev Burn token, public access.
   */
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
    if (_isExcluded[address(this)]) {
      _tOwned[address(this)] = _tOwned[address(this)].add(tFee);
    }
    emit Transfer(_msgSender(), address(this), tFee);
  }

  function _getValues(uint256 tAmount)
    private view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
  {
    (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getTValues(
      tAmount
    );
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
      tAmount,
      tFee,
      tLiquidity,
      tMarketing,
      _getRate()
    );
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
  }

  function _getTValues(uint256 tAmount)
    private view
    returns (uint256, uint256, uint256, uint256)
  {
    uint256 tFee = calcTaxFee(tAmount);
    uint256 tLiquidity = calcLiquidityFee(tAmount);
    uint256 tMarketingFee = calcMarketingFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tMarketingFee);
    return (tTransferAmount, tFee, tLiquidity, tMarketingFee);
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tLiquidity,
    uint256 tMarketing,
    uint256 currentRate
  )
    private pure
    returns (uint256, uint256, uint256)
  {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rMarketing = tMarketing.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketing);
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
    if (_isExcluded[address(this)]) {
      _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    emit Transfer(_msgSender(), address(this), tLiquidity);
  }

  function _takeMarketingFee(uint256 tMarketing)
    private
  {
    if (tMarketing > 0) {
      uint256 currentRate = _getRate();
      uint256 rMarketing = tMarketing.mul(currentRate);
      _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarketing);
      if (_isExcluded[_marketingAddress]) {
        _tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tMarketing);
      }
      emit Transfer(_msgSender(), _marketingAddress, tMarketing);
    }
  }

  function calcTaxFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_taxFee).div(10**4); }

  function calcLiquidityFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_liquidityFee).div(10**4); }

  function calcMarketingFee(uint256 _amount)
    private view
    returns (uint256)
  {
    if (_marketingAddress == ZERO) return 0;
    return _amount.mul(_marketingFee).div(10**4);
  }

  function removeAllFee()
    private
  {
    if (_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;
    _previousMarketingFee = _marketingFee;

    _taxFee = 0;
    _liquidityFee = 0;
    _marketingFee = 0;
  }

  function restoreAllFee()
    private
  {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
    _marketingFee = _previousMarketingFee;
  }

  function isExcludedFromFee(address account) public view returns (bool) { return _isExcludedFromFee[account]; }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
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

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
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

    /**
   * note: Is the token balance of this contract address over the min number of
   * tokens that we need to initiate a swap + liquidity lock?
   * also, don't get caught in a circular liquidity event.
   * also, don't swap & liquify if sender is PancakeSwap pair.
   */
    uint256 contractTokenBalance = balanceOf(address(this));

    if (contractTokenBalance >= _maxTxAmount) { contractTokenBalance = _maxTxAmount; }

    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    if (overMinTokenBalance && !inSwapAndLiquify && from != pancakePair && swapAndLiquifyEnabled) {
      contractTokenBalance = numTokensSellToAddToLiquidity;

      // note: Add the liquidity
      swapAndLiquify(contractTokenBalance);
    }

    // note: Indicates if fee should be deducted from transfer
    bool takeFee = true;

    // note: If any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) { takeFee = false; }

    // note: Transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from, to, amount, takeFee);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // note: Split the contract balance into halves
    uint256 half = contractTokenBalance.div(2);
    uint256 otherHalf = contractTokenBalance.sub(half);

    /**
   * note: Capture the contract's current BNB balance.
   * this is so that we can capture exactly the amount of BNB that the
   * swap creates, and not make the liquidity event include any BNB that
   * has been manually sent to the contract
   */
    uint256 initialBalance = address(this).balance;

    // note: Swap tokens for BNB
    swapTokensForEth(half); // <- this breaks the BNB -> NEFTI swap when swap+liquify is triggered

    // note: How much BNB did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // note: Add liquidity to PancakeSwap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // note: Generate the PancakeSwap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeRouter.WETH();

    _approve(address(this), address(pancakeRouter), tokenAmount);

    // note: Make the swap
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
    // note: Approve token transfer to cover all possible scenarios
    _approve(address(this), address(pancakeRouter), tokenAmount);

    // note: Add the liquidity
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

  function recallTo(address account, uint256 amount)
    public onlyOwner
  {
    require(amount <= balanceOf(address(this)), "Amount exceeds balance");
    _transfer(address(this), account, amount);
  }

  function recallTax() public onlyOwner {
    uint256 _tFeeTotalPrev = _tFeeTotal; _tFeeTotal = 0;
    uint256 currentRate = _getRate();
    uint256 rSupport = _tFeeTotalPrev.mul(currentRate);
    _rOwned[_supportAddress] = _rOwned[_supportAddress].add(rSupport);
    // _rOwned[address(this)] = _rOwned[address(this)].sub(rSupport);
    if (_isExcluded[address(this)]) {
      _tOwned[address(this)] = _tOwned[address(this)].sub(rSupport);
      _tOwned[_supportAddress] = _tOwned[_supportAddress].add(rSupport);
    }
    emit Transfer(_msgSender(), _supportAddress, _tFeeTotalPrev);
  }

  // note: This method is responsible for taking all fee, if takeFee is true
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
      uint256 tMarketing
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeMarketingFee(tMarketing);
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
      uint256 tMarketing
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeMarketingFee(tMarketing);
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
      uint256 tMarketing
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeMarketingFee(tMarketing);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }
}