// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IUniswapV2Router02 } from './interfaces/IUniswapV2Router02.sol';
import { IUniswapV2Factory } from './interfaces/IUniswapV2Factory.sol';

contract Duck is Ownable {
  using SafeMath for uint256;
  /// @notice user structure
  struct User {
    uint256 buy;
    uint256 sell;
    bool exists;
  }

  modifier lockTheSwap {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  /// events
  event BuyBackEnabledUpdated(bool enabled);
  event SwapETHForTokens(uint256 amountIn, address[] path);
  event SwapTokensForETH(uint256 amountIn, address[] path);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  address public immutable deadAddress =
    0x000000000000000000000000000000000000dEaD;
  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => User) private cooldown;

  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isExcluded;
  address[] private _excluded;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal = 1000000000000 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  string private _name = 'Duck token';
  string private _symbol = 'DUCK';
  uint8 private _decimals = 9;

  address payable private _devAddress;

  uint256 public launchTime;
  uint256 private buyLimitEnd;

  uint256 public _taxFee = 5;
  uint256 private _previousTaxFee = _taxFee;
  uint256 public _liquidityFee = 10;
  uint256 private _previousLiquidityFee = _liquidityFee;
  uint256 public _baseLiqFee = _liquidityFee;

  bool private _useImpactFeeSetter = true;
  uint256 private _feeMultiplier = 1000;

  uint256 public _minTrigger = 0;
  uint256 public k = 10;
  uint256 public _baseAmount = 1 * 10**15;

  uint256 private _maxBuyAmount = 2000000000 * 10**9;
  bool private _cooldownEnabled = true;

  bool public tradingOpen = false; //once switched on, can never be switched off.

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = false;
  bool public buyBackEnabled = false;

  /// @notice constructor for DUCK token
  /// @param _uniswapRouterAddress uniswap router address
  constructor(address _uniswapRouterAddress) {
    _rOwned[msg.sender] = _rTotal;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      _uniswapRouterAddress
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    uniswapV2Router = _uniswapV2Router;

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    emit Transfer(address(0), msg.sender, _tTotal);
  }

  /// @notice enable trading
  function enableTrading() external onlyOwner() {
    swapAndLiquifyEnabled = true;
    tradingOpen = true;
    launchTime = block.timestamp;
    buyLimitEnd = block.timestamp + (240 seconds);
  }

  /// @notice token name
  function name() external view returns (string memory name_) {
    name_ = _name;
  }

  /// @notice token symbol
  function symbol() external view returns (string memory symbol_) {
    symbol_ = _symbol;
  }

  /// @notice token decimals
  function decimals() external view returns (uint8 decimals_) {
    decimals_ = _decimals;
  }

  /// @notice token total supply
  function totalSupply() external view returns (uint256 totalSupply_) {
    totalSupply_ = _tTotal;
  }

  /// @notice get balance of account
  /// @param _account the account balance to return
  function balanceOf(address _account) public view returns (uint256 balance_) {
    if (_isExcluded[_account]) balance_ = _tOwned[_account];
    balance_ = tokenFromReflection(_rOwned[_account]);
  }

  /// @notice transfer tokens to account
  /// @param _recipient the account balance to return
  /// @param _amount amount of tokens being sent
  function transfer(address _recipient, uint256 _amount)
    external
    returns (bool success_)
  {
    _transfer(msg.sender, _recipient, _amount);
    success_ = true;
  }

  /// @notice get allowances for spender of owner
  /// @param _owner who owns the tokens
  /// @param _spender who's spending the tokens
  function allowance(address _owner, address _spender)
    external
    view
    returns (uint256 allowance_)
  {
    allowance_ = _allowances[_owner][_spender];
  }

  /// @notice approve spending
  /// @param _spender who's spending the tokens
  /// @param _amount amount of tokens to spend
  function approve(address _spender, uint256 _amount)
    external
    returns (bool success_)
  {
    _approve(msg.sender, _spender, _amount);
    success_ = true;
  }

  /// @notice transfer tokens from an account to another
  /// @param _sender the account sending
  /// @param _recipient the account receiving
  /// @param _amount amount of tokens being sent
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) external returns (bool success_) {
    _transfer(_sender, _recipient, _amount);
    _approve(
      _sender,
      msg.sender,
      _allowances[_sender][msg.sender].sub(
        _amount,
        'DUCK: transfer amount exceeds allowance'
      )
    );
    success_ = true;
  }

  /// @notice increase allowance for spender
  /// @param _sender the account sending
  /// @param _addedValue amount of allowance being increased by
  function increaseAllowance(address _sender, uint256 _addedValue)
    external
    virtual
    returns (bool success_)
  {
    _approve(
      msg.sender,
      _sender,
      _allowances[msg.sender][_sender].add(_addedValue)
    );
    success_ = true;
  }

  /// @notice decrease allowance for spender
  /// @param _sender the account sending
  /// @param _subtractedValue amount of allowance being increased by
  function decreaseAllowance(address _sender, uint256 _subtractedValue)
    external
    virtual
    returns (bool success_)
  {
    _approve(
      msg.sender,
      _sender,
      _allowances[msg.sender][_sender].sub(
        _subtractedValue,
        'DUCK: decreased allowance below zero'
      )
    );
    success_ = true;
  }

  /// @notice check if account is excluded from reward
  /// @param _account the account checking
  function isExcludedFromReward(address _account)
    external
    view
    returns (bool isExcluded_)
  {
    isExcluded_ = _isExcluded[_account];
  }

  /// @notice get total amount of fees
  function totalFees() external view returns (uint256 totalFees_) {
    totalFees_ = _tFeeTotal;
  }

  /// @notice deliver tokens
  /// @param _tAmount amount to deliver
  function deliver(uint256 _tAmount) external {
    address sender = msg.sender;
    require(!_isExcluded[sender], 'DUCK: excluded address cannot deliver');
    (uint256 rAmount, , , , , ) = _getValues(_tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(_tAmount);
  }

  /// @notice get reflection based on token
  /// @param _tAmount amount to deliver
  /// @param _deductTransferFee deduct transfer fee from reflection
  function reflectionFromToken(uint256 _tAmount, bool _deductTransferFee)
    external
    view
    returns (uint256 rValue_)
  {
    require(_tAmount <= _tTotal, 'DUCK: mount must be less than supply');
    if (!_deductTransferFee) {
      (uint256 rAmount, , , , , ) = _getValues(_tAmount);
      rValue_ = rAmount;
    } else {
      (, uint256 rTransferAmount, , , , ) = _getValues(_tAmount);
      rValue_ = rTransferAmount;
    }
  }

  /// @notice get calculation of token from reflection
  /// @param _rAmount amount to deliver
  function tokenFromReflection(uint256 _rAmount)
    public
    view
    returns (uint256 rAmount_)
  {
    require(
      _rAmount <= _rTotal,
      'DUCK: amount must be less than total reflections'
    );
    uint256 currentRate = _getRate();
    rAmount_ = _rAmount.div(currentRate);
  }

  /// @notice check checks if you are excluded from fee
  /// @param _account the account to check
  function isExcludedFromFee(address _account)
    public
    view
    returns (bool account_)
  {
    account_ = _isExcludedFromFee[_account];
  }

  /// @notice sets new dev address
  /// @param _address the account to check
  function setDevAddress(address _address) external onlyOwner() {
    _devAddress = payable(_address);
  }

  /// @notice sets buy back status
  /// @param _enabled buy back status
  function setBuyBackEnabled(bool _enabled) public onlyOwner {
    buyBackEnabled = _enabled;
    emit BuyBackEnabledUpdated(_enabled);
  }

  /// @notice sets min trigger
  /// @param _newTrigger new trigger amount
  function setMinTrigger(uint256 _newTrigger) external onlyOwner() {
    _minTrigger = _newTrigger;
  }

  /// @notice sets k
  /// @param _newK new k amount
  function setK(uint256 _newK) external onlyOwner() {
    k = _newK;
  }

  /// @notice sets base amount
  /// @param _newAmount new base amount
  function setBaseAmount(uint256 _newAmount) external onlyOwner() {
    _baseAmount = _newAmount;
  }

  /// @notice sets tax fee
  /// @param _newTaxFee new tax fee
  function setTaxFeePercent(uint256 _newTaxFee) external onlyOwner() {
    require((_baseLiqFee + _newTaxFee) <= 20);
    _taxFee = _newTaxFee;
    _previousTaxFee = _newTaxFee;
  }

  /// @notice sets base liquidity
  /// @param _newBaseLiqFee new tax fee
  function setBaseLiqFeePercent(uint256 _newBaseLiqFee) external onlyOwner() {
    require((_newBaseLiqFee + _taxFee) <= 20);
    _baseLiqFee = _newBaseLiqFee;
  }

  /// @notice approve spending
  /// @param _owner owner of tokens
  /// @param _spender who's spending the tokens
  /// @param _amount amount of tokens to spend
  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) private {
    require(_owner != address(0), 'DUCK: approve from the zero address');
    require(_spender != address(0), 'DUCK: approve to the zero address');

    _allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  /// @notice transfer tokens to account
  /// @param _sender the account sending
  /// @param _recipient the account balance to return
  /// @param _amount amount of tokens being sent
  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) private {
    require(_sender != address(0), 'DUCK: transfer from the zero address');
    require(_recipient != address(0), 'DUCK: transfer to the zero address');
    require(_amount > 0, 'DUCK: transfer amount must be greater than zero');
    if (_sender != owner() && _recipient != owner()) {
      if (!tradingOpen) {
        if (
          !(_sender == address(this) ||
            _recipient == address(this) ||
            _sender == address(owner()) ||
            _recipient == address(owner()))
        ) {
          require(tradingOpen, 'DUCK: trading is not enabled');
        }
      }

      if (_cooldownEnabled) {
        if (!cooldown[msg.sender].exists) {
          cooldown[msg.sender] = User(0, 0, true);
        }
      }
    }

    if (
      _sender == uniswapV2Pair &&
      _recipient != address(uniswapV2Router) &&
      !_isExcludedFromFee[_recipient]
    ) {
      require(tradingOpen, 'DUCK: trading not yet enabled.');

      _liquidityFee = _baseLiqFee;

      if (_cooldownEnabled) {
        if (buyLimitEnd > block.timestamp) {
          require(_amount <= _maxBuyAmount);
          require(
            cooldown[_recipient].buy < block.timestamp,
            'DUCK: Your buy cooldown has not expired.'
          );
          cooldown[_recipient].buy = block.timestamp + (45 seconds);
        }
      }
      if (_cooldownEnabled) {
        cooldown[_recipient].sell = block.timestamp + (15 seconds);
      }
    }

    if (
      !inSwapAndLiquify && swapAndLiquifyEnabled && _recipient == uniswapV2Pair
    ) {
      if (_useImpactFeeSetter) {
        uint256 feeBasis = _amount.mul(_feeMultiplier);
        feeBasis = feeBasis.div(balanceOf(uniswapV2Pair).add(_amount));
        _setFee(feeBasis);
      }

      uint256 dynamicFee = _liquidityFee;

      //swap contract's tokens for ETH
      uint256 contractTokenBalance = balanceOf(address(this));
      if (contractTokenBalance > 0) {
        _swapTokens(contractTokenBalance);
      }

      uint256 balance = address(this).balance;

      if (buyBackEnabled && _amount >= _minTrigger) {
        uint256 ten = 10;

        uint256 buyBackAmount = _baseAmount
        .mul(ten.add(((dynamicFee.sub(_baseLiqFee)).mul(k)).div(_baseLiqFee)))
        .div(10);

        if (balance >= buyBackAmount) _buyBackTokens(buyBackAmount);
      }

      //restore dynamicFee after buyback
      _liquidityFee = dynamicFee;
    }

    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[_sender] || _isExcludedFromFee[_recipient]) {
      takeFee = false;
    }

    //execute transfer
    _tokenTransfer(_sender, _recipient, _amount, takeFee);
  }

  /// @notice swap tokens locked in contract
  /// @param _tokenBalance the balance of the token
  function _swapTokens(uint256 _tokenBalance) private lockTheSwap {
    uint256 initialBalance = address(this).balance;
    _swapTokensForEth(_tokenBalance);
    uint256 transferredBalance = address(this).balance.sub(initialBalance);

    _transferToAddressETH(_devAddress, transferredBalance.div(2));
  }

  /// @notice buy back sold tokens
  /// @param _amount the amount to buy back
  function _buyBackTokens(uint256 _amount) private lockTheSwap {
    if (_amount > 0) {
      _swapETHForTokens(_amount);
    }
  }

  /// @notice set the fees
  /// @param _fee the fee
  function _setFee(uint256 _fee) private {
    uint256 _impactFee = _baseLiqFee;
    if (_fee < _baseLiqFee) {
      _impactFee = _baseLiqFee;
    } else if (_fee > 40) {
      _impactFee = 40;
    } else {
      _impactFee = _fee;
    }
    if (_impactFee.mod(2) != 0) {
      _impactFee++;
    }

    _liquidityFee = _impactFee;
  }

  /// @notice swap tokens for eth
  /// @param _amount the amount swapping
  function _swapTokensForEth(uint256 _amount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), _amount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _amount,
      0, // accept any amount of ETH
      path,
      address(this), // The contract
      block.timestamp
    );

    emit SwapTokensForETH(_amount, path);
  }

  /// @notice swap eth for tokens
  /// @param _amount the amount swapping
  function _swapETHForTokens(uint256 _amount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = address(this);

    // make the swap
    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: _amount
    }(
      0, // accept any amount of Tokens
      path,
      owner(),
      block.timestamp.add(300)
    );

    emit SwapETHForTokens(_amount, path);
  }

  /// @notice transfer tokens to account
  /// @param _sender the account sending
  /// @param _recipient the account balance to return
  /// @param _amount amount of tokens being sent
  /// @param _takeFee if to take fees or not
  function _tokenTransfer(
    address _sender,
    address _recipient,
    uint256 _amount,
    bool _takeFee
  ) private {
    if (!_takeFee) removeAllFee();

    if (_isExcluded[_sender] && !_isExcluded[_recipient]) {
      _transferFromExcluded(_sender, _recipient, _amount);
    } else if (!_isExcluded[_sender] && _isExcluded[_recipient]) {
      _transferToExcluded(_sender, _recipient, _amount);
    } else if (_isExcluded[_sender] && _isExcluded[_recipient]) {
      _transferBothExcluded(_sender, _recipient, _amount);
    } else {
      _transferStandard(_sender, _recipient, _amount);
    }

    if (!_takeFee) _restoreAllFee();
  }

  /// @notice transfer tokens to account
  /// @param _sender the account sending
  /// @param _recipient the account balance to return
  /// @param _tAmount amount of tokens being sent
  function _transferStandard(
    address _sender,
    address _recipient,
    uint256 _tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(_tAmount);
    _rOwned[_sender] = _rOwned[_sender].sub(rAmount);
    _rOwned[_recipient] = _rOwned[_recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);

    emit Transfer(_sender, _recipient, tTransferAmount);
  }

  /// @notice transfer tokens to account
  /// @param _sender the account sending
  /// @param _recipient the account balance to return
  /// @param _tAmount amount of tokens being sent
  function _transferToExcluded(
    address _sender,
    address _recipient,
    uint256 _tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(_tAmount);
    _rOwned[_sender] = _rOwned[_sender].sub(rAmount);
    _tOwned[_recipient] = _tOwned[_recipient].add(tTransferAmount);
    _rOwned[_recipient] = _rOwned[_recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);

    emit Transfer(_sender, _recipient, tTransferAmount);
  }

  /// @notice transfer tokens to account
  /// @param _sender the account sending
  /// @param _recipient the account balance to return
  /// @param _tAmount amount of tokens being sent
  function _transferFromExcluded(
    address _sender,
    address _recipient,
    uint256 _tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(_tAmount);
    _tOwned[_sender] = _tOwned[_sender].sub(_tAmount);
    _rOwned[_sender] = _rOwned[_sender].sub(rAmount);
    _rOwned[_recipient] = _rOwned[_recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);

    emit Transfer(_sender, _recipient, tTransferAmount);
  }

  /// @notice transfer tokens to account
  /// @param _sender the account sending
  /// @param _recipient the account balance to return
  /// @param _tAmount amount of tokens being sent
  function _transferBothExcluded(
    address _sender,
    address _recipient,
    uint256 _tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(_tAmount);
    _tOwned[_sender] = _tOwned[_sender].sub(_tAmount);
    _rOwned[_sender] = _rOwned[_sender].sub(rAmount);
    _tOwned[_recipient] = _tOwned[_recipient].add(tTransferAmount);
    _rOwned[_recipient] = _rOwned[_recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);

    emit Transfer(_sender, _recipient, tTransferAmount);
  }

  /// @notice reflect from fee
  /// @param _rFee reflect fee
  /// @param _tFee total fee
  function _reflectFee(uint256 _rFee, uint256 _tFee) private {
    _rTotal = _rTotal.sub(_rFee);
    _tFeeTotal = _tFeeTotal.add(_tFee);
  }

  /// @notice get values
  /// @param _tAmount the amount getting values from
  function _getValues(uint256 _tAmount)
    private
    view
    returns (
      uint256 rAmount_,
      uint256 rTransferAmount_,
      uint256 rFee_,
      uint256 tTransferAmount_,
      uint256 tFee_,
      uint256 tLiquidity_
    )
  {
    (tTransferAmount_, tFee_, tLiquidity_) = _getTValues(_tAmount);
    (rAmount_, rTransferAmount_, rFee_) = _getRValues(
      _tAmount,
      tFee_,
      tLiquidity_,
      _getRate()
    );
  }

  /// @notice get values
  /// @param _tAmount the amount getting values from
  function _getTValues(uint256 _tAmount)
    private
    view
    returns (
      uint256 tTransferAmount_,
      uint256 tFee_,
      uint256 tLiquidity_
    )
  {
    tFee_ = _calculateTaxFee(_tAmount);
    tLiquidity_ = _calculateLiquidityFee(_tAmount);
    tTransferAmount_ = _tAmount.sub(tFee_).sub(tLiquidity_);
  }

  /// @notice get reward values
  /// @param _tAmount the amount getting values from
  /// @param _tFee the total fee
  /// @param _tLiquidity the total liquidity
  /// @param _currentRate the current rate
  function _getRValues(
    uint256 _tAmount,
    uint256 _tFee,
    uint256 _tLiquidity,
    uint256 _currentRate
  )
    private
    pure
    returns (
      uint256 rAmount_,
      uint256 rTransferAmount_,
      uint256 rFee_
    )
  {
    rAmount_ = _tAmount.mul(_currentRate);
    rFee_ = _tFee.mul(_currentRate);
    uint256 rLiquidity = _tLiquidity.mul(_currentRate);
    rTransferAmount_ = rAmount_.sub(rFee_).sub(rLiquidity);
  }

  /// @notice get the current rate
  function _getRate() private view returns (uint256 rate_) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    rate_ = rSupply.div(tSupply);
  }

  /// @notice get the current supply
  function _getCurrentSupply()
    private
    view
    returns (uint256 rSupply_, uint256 tSupply_)
  {
    rSupply_ = _rTotal;
    tSupply_ = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply_ || _tOwned[_excluded[i]] > tSupply_)
        return (_rTotal, _tTotal);
      rSupply_ = rSupply_.sub(_rOwned[_excluded[i]]);
      tSupply_ = tSupply_.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply_ < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
  }

  /// @notice take liquidity
  /// @param _tLiquidity liquidity to take
  function _takeLiquidity(uint256 _tLiquidity) private {
    uint256 currentRate = _getRate();
    uint256 rLiquidity = _tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if (_isExcluded[address(this)])
      _tOwned[address(this)] = _tOwned[address(this)].add(_tLiquidity);
  }

  /// @notice calculate tax fee
  /// @param _amount amount to calculate from
  function _calculateTaxFee(uint256 _amount)
    private
    view
    returns (uint256 taxFee_)
  {
    taxFee_ = _amount.mul(_taxFee).div(10**2);
  }

  /// @notice calculate liquidity fee
  /// @param _amount amount to calculate from
  function _calculateLiquidityFee(uint256 _amount)
    private
    view
    returns (uint256 amount_)
  {
    amount_ = _amount.mul(_liquidityFee).div(10**2);
  }

  /// @notice remove all fees
  function removeAllFee() private {
    if (_taxFee == 0 && _liquidityFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;

    _taxFee = 0;
    _liquidityFee = 0;
  }

  /// @notice restore all fees
  function _restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
  }

  /// @notice transfers eth to address
  /// @param _recipient account to transfer eth
  /// @param _amount amount to transfer
  function _transferToAddressETH(address payable _recipient, uint256 _amount)
    private
  {
    _recipient.transfer(_amount);
  }

  //to recieve ETH from uniswapV2Router when swapping
  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}