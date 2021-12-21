// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "IERC20.sol";
import "IERC721.sol";
import "ILPTokenMaster.sol";
import "ILendingPair.sol";
import "ILendingController.sol";
import "IInterestRateModel.sol";
import "IUniswapV3Helper.sol";
import "INonfungiblePositionManagerSimple.sol";

import "Math.sol";
import "Clones.sol";
import "ReentrancyGuard.sol";
import "AddressLibrary.sol";

import "LPTokenMaster.sol";

import "ERC721Receivable.sol";
import "TransferHelper.sol";

contract LendingPair is ILendingPair, ReentrancyGuard, TransferHelper, ERC721Receivable {

  INonfungiblePositionManagerSimple internal constant positionManager = INonfungiblePositionManagerSimple(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  IERC721 internal constant uniPositions = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  uint    public   constant LIQ_MIN_HEALTH = 1e18;
  uint    private  constant MIN_DECIMALS = 6;

  using AddressLibrary for address;
  using Clones for address;

  mapping (address => mapping (address => uint)) public override supplySharesOf;
  mapping (address => mapping (address => uint)) public debtSharesOf;
  mapping (address => uint) public pendingSystemFees;
  mapping (address => uint) public lastBlockAccrued;
  mapping (address => uint) public override totalSupplyShares;
  mapping (address => uint) public override totalSupplyAmount;
  mapping (address => uint) public override totalDebtShares;
  mapping (address => uint) public override totalDebtAmount;
  mapping (address => uint) public uniPosition;
  mapping (address => uint) private decimals;
  mapping (address => address) public override lpToken;

  IUniswapV3Helper   private uniV3Helper;
  ILendingController public  lendingController;

  address public feeRecipient;
  address public override tokenA;
  address public override tokenB;

  event Liquidation(
    address indexed account,
    address indexed repayToken,
    address indexed supplyToken,
    uint repayAmount,
    uint supplyAmount
  );

  event Deposit(address indexed account, address indexed token, uint amount);
  event Withdraw(address indexed account, address indexed token, uint amount);
  event Borrow(address indexed account, address indexed token, uint amount);
  event Repay(address indexed account, address indexed token, uint amount);
  event CollectSystemFee(address indexed token, uint amount);
  event DepositUniPosition(address indexed account, uint positionID);
  event WithdrawUniPosition(address indexed account, uint positionID);

  modifier onlyLpToken() {
    require(lpToken[tokenA] == msg.sender || lpToken[tokenB] == msg.sender, "LendingController: caller must be LP token");
    _;
  }

  function initialize(
    address _lpTokenMaster,
    address _lendingController,
    address _uniV3Helper,
    address _feeRecipient,
    address _tokenA,
    address _tokenB
  ) external override {
    require(tokenA == address(0), "LendingPair: already initialized");

    lendingController = ILendingController(_lendingController);
    uniV3Helper       = IUniswapV3Helper(_uniV3Helper);
    feeRecipient      = _feeRecipient;
    tokenA = _tokenA;
    tokenB = _tokenB;
    lastBlockAccrued[tokenA] = block.number;
    lastBlockAccrued[tokenB] = block.number;

    decimals[tokenA] = IERC20(tokenA).decimals();
    decimals[tokenB] = IERC20(tokenB).decimals();

    require(decimals[tokenA] >= MIN_DECIMALS && decimals[tokenB] >= MIN_DECIMALS, "LendingPair: MIN_DECIMALS");

    lpToken[tokenA] = _createLpToken(_lpTokenMaster, tokenA);
    lpToken[tokenB] = _createLpToken(_lpTokenMaster, tokenB);
  }

  // Deposit limits do not apply to Uniswap positions
  function depositUniPosition(address _account, uint _positionID) external nonReentrant {
    _checkDepositsEnabled();
    _validateUniPosition(_positionID);
    require(_positionID > 0, "LendingPair: invalid position");
    require(uniPosition[_account] == 0, "LendingPair: one position per account");

    uniPositions.safeTransferFrom(msg.sender, address(this), _positionID);
    uniPosition[_account] = _positionID;

    emit DepositUniPosition(_account, _positionID);
  }

  function withdrawUniPosition() external nonReentrant {
    uint positionID = uniPosition[msg.sender];
    require(positionID > 0, "LendingPair: nothing to withdraw");
    uniPositions.safeTransferFrom(address(this), msg.sender, positionID);
    uniPosition[msg.sender] = 0;

    accrue(tokenA);
    accrue(tokenB);
    checkAccountHealth(msg.sender);

    emit WithdrawUniPosition(msg.sender, positionID);
  }

  // claim & mint supply from uniswap fees
  function uniClaimDeposit() external nonReentrant {
    accrue(tokenA);
    accrue(tokenB);
    (uint amountA, uint amountB) = _uniCollectFees(msg.sender);
    _mintSupplyAmount(tokenA, msg.sender, amountA);
    _mintSupplyAmount(tokenB, msg.sender, amountB);
  }

  // claim & withdraw uniswap fees
  function uniClaimWithdraw() external nonReentrant {
    (uint amountA, uint amountB) = _uniCollectFees(msg.sender);
    _safeTransfer(tokenA, msg.sender, amountA);
    _safeTransfer(tokenB, msg.sender, amountB);
  }

  function depositRepay(address _account, address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _depositRepay(_account, _token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function depositRepayETH(address _account) external payable nonReentrant {
    _validateToken(address(WETH));
    accrue(address(WETH));

    _depositRepay(_account, address(WETH), msg.value);
    _depositWeth();
  }

  function deposit(address _account, address _token, uint _amount) external override nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _deposit(_account, _token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function withdrawBorrow(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _withdrawBorrow(_token, _amount);
    _safeTransfer(_token, msg.sender, _amount);
  }

  function withdrawBorrowETH(uint _amount) external nonReentrant {
    _validateToken(address(WETH));
    accrue(address(WETH));

    _withdrawBorrow(address(WETH), _amount);
    _wethWithdrawTo(msg.sender, _amount);
  }

  function withdraw(address _token, uint _amount) external override nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _withdrawShares(_token, _supplyToShares(_token, _amount));
    _safeTransfer(_token, msg.sender, _amount);
  }

  function withdrawAll(address _token) external override nonReentrant {
    _validateToken(_token);
    accrue(_token);

    uint shares = supplySharesOf[_token][msg.sender];
    uint amount = _sharesToSupply(_token, shares);
    _withdrawShares(_token, shares);
    _safeTransfer(_token, msg.sender, amount);
  }

  function withdrawAllETH() external nonReentrant {
    _validateToken(address(WETH));
    accrue(address(WETH));

    uint shares = supplySharesOf[address(WETH)][msg.sender];
    uint amount = _sharesToSupply(address(WETH), shares);
    _withdrawShares(address(WETH), shares);
    _wethWithdrawTo(msg.sender, amount);
  }

  function borrow(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _borrow(_token, _amount);
    _safeTransfer(_token, msg.sender, _amount);
  }

  function repayAll(address _account, address _token, uint _maxAmount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    uint amount = _repayShares(_account, _token, debtSharesOf[_token][_account]);
    require(amount <= _maxAmount, "LendingPair: amount <= _maxAmount");
    _safeTransferFrom(_token, msg.sender, amount);
  }

  function repayAllETH(address _account) external payable nonReentrant {
    _validateToken(address(WETH));
    accrue(address(WETH));

    uint amount = _repayShares(_account, address(WETH), debtSharesOf[address(WETH)][_account]);
    require(msg.value >= amount, "LendingPair: insufficient ETH deposit");

    _depositWeth();
    uint refundAmount = msg.value > amount ? (msg.value - amount) : 0;

    if (refundAmount > 0) {
      _wethWithdrawTo(msg.sender, refundAmount);
    }
  }

  function repay(address _account, address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _repayShares(_account, _token, _debtToShares(_token, _amount));
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function accrue(address _token) public {
    if (lastBlockAccrued[_token] < block.number) {
      uint newDebt   = _accrueDebt(_token);
      uint newSupply = newDebt * _lpRate(_token) / 100e18;
      totalSupplyAmount[_token] += newSupply;
      pendingSystemFees[_token] += (newDebt - newSupply);
      lastBlockAccrued[_token]   = block.number;
    }
  }

  function collectSystemFee(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    pendingSystemFees[_token] -= _amount;
    _safeTransfer(_token, feeRecipient, _amount);
    emit CollectSystemFee(_token, _amount);
  }

  function transferLp(address _token, address _from, address _to, uint _amount) external override onlyLpToken {
    require(debtSharesOf[_token][_to] == 0, "LendingPair: cannot receive borrowed token");
    supplySharesOf[_token][_from] -= _amount;
    supplySharesOf[_token][_to]   += _amount;
    checkAccountHealth(_from);
  }

  // Sell collateral to reduce debt and increase accountHealth
  // Set _repayAmount to type(uint).max to repay all debt, inc. pending interest
  function liquidateAccount(
    address _account,
    address _repayToken,
    uint    _repayAmount,
    uint    _minSupplyOutput
  ) external nonReentrant {

    // Input validation and adjustments

    _validateToken(_repayToken);

    address supplyToken = _repayToken == tokenA ? tokenB : tokenA;

    // Check account is underwater after interest

    accrue(supplyToken);
    accrue(_repayToken);

    uint health = accountHealth(_account);
    require(health < LIQ_MIN_HEALTH, "LendingPair: account health < LIQ_MIN_HEALTH");

    // Fully unwrap Uni position - withdraw & mint supply

    _unwrapUniPosition(_account);

    // Calculate balance adjustments

    _repayAmount = Math.min(_repayAmount, _debtOf(_repayToken, _account));
    (uint repayPrice, uint supplyPrice) = lendingController.tokenPrices(_repayToken, supplyToken);

    uint supplyDebt   = _convertTokenValues(_repayToken, supplyToken, _repayAmount, repayPrice, supplyPrice);
    uint callerFee    = supplyDebt * lendingController.liqFeeCaller(_repayToken) / 100e18;
    uint systemFee    = supplyDebt * lendingController.liqFeeSystem(_repayToken) / 100e18;
    uint supplyBurn   = supplyDebt + callerFee + systemFee;
    uint supplyOutput = supplyDebt + callerFee;

    require(supplyOutput >= _minSupplyOutput, "LendingPair: supplyOutput >= _minSupplyOutput");

    // Adjust balances

    _burnSupplyShares(supplyToken, _account, _supplyToShares(supplyToken, supplyBurn));
    pendingSystemFees[supplyToken] += systemFee;
    _burnDebtShares(_repayToken, _account, _debtToShares(_repayToken, _repayAmount));

    // Uni position unwrapping can mint supply of already borrowed tokens

    _repayDebtFromSupply(_account, tokenA);
    _repayDebtFromSupply(_account, tokenB);

    // Settle token transfers

    _safeTransferFrom(_repayToken, msg.sender, _repayAmount);
    _mintSupplyAmount(supplyToken, msg.sender, supplyOutput);

    emit Liquidation(_account, _repayToken, supplyToken, _repayAmount, supplyOutput);
  }

  // Compare all supply & borrow balances converted into the the same token - tokenA
  function accountHealth(address _account) public view returns(uint) {

    if (debtSharesOf[tokenA][_account] == 0 && debtSharesOf[tokenB][_account] == 0) {
      return LIQ_MIN_HEALTH;
    }

    (uint priceA, uint priceB) = lendingController.tokenPrices(tokenA, tokenB);
    uint colFactorA = lendingController.colFactor(tokenA);
    uint colFactorB = lendingController.colFactor(tokenB);

    uint creditA   = _supplyOf(tokenA, _account) * colFactorA / 100e18;
    uint creditB   = _supplyBalanceConverted(_account, tokenB, tokenA, priceB, priceA) * colFactorB / 100e18;
    uint creditUni = _convertedCreditAUni(_account, priceA, priceB, colFactorA, colFactorB);

    uint totalAccountSupply = creditA + creditB + creditUni;

    uint totalAccountBorrow = _debtOf(tokenA, _account) + _borrowBalanceConverted(_account, tokenB, tokenA, priceB, priceA);

    return totalAccountSupply * 1e18 / totalAccountBorrow;
  }

  function debtOf(address _token, address _account) external view returns(uint) {
    _validateToken(_token);
    return _debtOf(_token, _account);
  }

  function supplyOf(address _token, address _account) external view override returns(uint) {
    _validateToken(_token);
    return _supplyOf(_token, _account);
  }

  // Get borow balance converted to the units of _returnToken
  function borrowBalanceConverted(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint) {

    _validateToken(_borrowedToken);
    _validateToken(_returnToken);

    (uint borrowPrice, uint returnPrice) = lendingController.tokenPrices(_borrowedToken, _returnToken);
    return _borrowBalanceConverted(_account, _borrowedToken, _returnToken, borrowPrice, returnPrice);
  }

  function supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view override returns(uint) {

    _validateToken(_suppliedToken);
    _validateToken(_returnToken);

    (uint supplyPrice, uint returnPrice) = lendingController.tokenPrices(_suppliedToken, _returnToken);
    return _supplyBalanceConverted(_account, _suppliedToken, _returnToken, supplyPrice, returnPrice);
  }

  function supplyRatePerBlock(address _token) external view returns(uint) {
    _validateToken(_token);
    if (totalSupplyAmount[_token] == 0 || totalDebtAmount[_token] == 0) { return 0; }
    uint utilizationRate = totalDebtAmount[_token] * 100e18 / totalSupplyAmount[_token];
    return _interestRatePerBlock(_token) * utilizationRate * _lpRate(_token) / 100e18 / 100e18;
  }

  function borrowRatePerBlock(address _token) external view returns(uint) {
    _validateToken(_token);
    return _interestRatePerBlock(_token);
  }

  function checkAccountHealth(address _account) public view  {
    uint health = accountHealth(_account);
    require(health >= LIQ_MIN_HEALTH, "LendingPair: insufficient accountHealth");
  }

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint) {

    _validateToken(_fromToken);
    _validateToken(_toToken);

    (uint fromPrice, uint toPrice) = lendingController.tokenPrices(_fromToken, _toToken);
    return _convertTokenValues(_fromToken, _toToken, _inputAmount, fromPrice, toPrice);
  }

  function _depositRepay(address _account, address _token, uint _amount) internal {

    uint debt          = _debtOf(_token, _account);
    uint repayAmount   = debt > _amount ? _amount : debt;
    uint depositAmount = _amount - repayAmount;

    if (repayAmount > 0) {
      _repayShares(_account, _token, _debtToShares(_token, repayAmount));
    }

    if (depositAmount > 0) {
      _deposit(_account, _token, depositAmount);
    }
  }

  function _withdrawBorrow(address _token, uint _amount) internal {

    uint supplyAmount   = _supplyOf(_token, msg.sender);
    uint withdrawAmount = supplyAmount > _amount ? _amount : supplyAmount;
    uint borrowAmount   = _amount - withdrawAmount;

    if (withdrawAmount > 0) {
      _withdrawShares(_token, _supplyToShares(_token, withdrawAmount));
    }

    if (borrowAmount > 0) {
      _borrow(_token, borrowAmount);
    }
  }

  // Uses price oracle to estimate min outputs to reduce MEV
  // Liquidation might be temporarily unavailable due to this
  function _unwrapUniPosition(address _account) internal {

    if (uniPosition[_account] > 0) {

      (uint priceA, uint priceB) = lendingController.tokenPrices(tokenA, tokenB);
      (uint amount0, uint amount1) = _positionAmounts(uniPosition[_account], priceA, priceB);
      uint uniMinOutput = lendingController.uniMinOutputPct();

      uniPositions.approve(address(uniV3Helper), uniPosition[_account]);
      (uint amountA, uint amountB) = uniV3Helper.removeLiquidity(
        uniPosition[_account],
        amount0 * uniMinOutput / 100e18,
        amount1 * uniMinOutput / 100e18
      );
      uniPosition[_account] = 0;

      _mintSupplyAmount(tokenA, _account, amountA);
      _mintSupplyAmount(tokenB, _account, amountB);
    }
  }

  // Ensure we never have borrow + supply balances of the same token on the same account
  function _repayDebtFromSupply(address _account, address _token) internal {

    uint burnAmount = Math.min(_debtOf(_token, _account), _supplyOf(_token, _account));

    if (burnAmount > 0) {
      _burnDebtShares(_token, _account, _debtToShares(_token, burnAmount));
      _burnSupplyShares(_token, _account, _supplyToShares(_token, burnAmount));
    }
  }

  function _uniCollectFees(address _account) internal returns(uint, uint) {
    uniPositions.approve(address(uniV3Helper), uniPosition[_account]);
    return uniV3Helper.collectFees(uniPosition[_account]);
  }

  function _mintSupplyAmount(address _token, address _account, uint _amount) internal returns(uint shares) {
    if (_amount > 0) {
      shares = _supplyToShares(_token, _amount);
      supplySharesOf[_token][_account] += shares;
      totalSupplyShares[_token] += shares;
      totalSupplyAmount[_token] += _amount;
    }
  }

  function _burnSupplyShares(address _token, address _account, uint _shares) internal returns(uint amount) {
    if (_shares > 0) {
      // Fix rounding error which can make issues during depositRepay / withdrawBorrow
      if (supplySharesOf[_token][_account] - _shares == 1) { _shares += 1; }
      amount = _sharesToSupply(_token, _shares);
      supplySharesOf[_token][_account] -= _shares;
      totalSupplyShares[_token] -= _shares;
      totalSupplyAmount[_token] -= amount;
    }
  }

  function _mintDebtAmount(address _token, address _account, uint _amount) internal returns(uint shares) {
    if (_amount > 0) {
      shares = _debtToShares(_token, _amount);
      debtSharesOf[_token][_account] += shares;
      totalDebtShares[_token] += shares;
      totalDebtAmount[_token] += _amount;
    }
  }

  function _burnDebtShares(address _token, address _account, uint _shares) internal returns(uint amount) {
    if (_shares > 0) {
      // Fix rounding error which can make issues during depositRepay / withdrawBorrow
      if (debtSharesOf[_token][_account] - _shares == 1) { _shares += 1; }
      amount = _sharesToDebt(_token, _shares);
      debtSharesOf[_token][_account] -= _shares;
      totalDebtShares[_token] -= _shares;
      totalDebtAmount[_token] -= amount;
    }
  }

  function _accrueDebt(address _token) internal returns(uint newDebt) {
    if (totalDebtAmount[_token] > 0) {
      uint blocksElapsed = block.number - lastBlockAccrued[_token];
      uint pendingInterestRate = _interestRatePerBlock(_token) * blocksElapsed;
      newDebt = totalDebtAmount[_token] * pendingInterestRate / 100e18;
      totalDebtAmount[_token] += newDebt;
    }
  }

  function _withdrawShares(address _token, uint _shares) internal {
    uint amount = _burnSupplyShares(_token, msg.sender, _shares);
    checkAccountHealth(msg.sender);
    emit Withdraw(msg.sender, _token, amount);
  }

  function _borrow(address _token, uint _amount) internal {

    require(supplySharesOf[_token][msg.sender] == 0, "LendingPair: cannot borrow supplied token");

    _checkBorrowEnabled();
    _checkBorrowLimits(_token, msg.sender, _amount);

    _mintDebtAmount(_token, msg.sender, _amount);
    checkAccountHealth(msg.sender);

    emit Borrow(msg.sender, _token, _amount);
  }

  function _repayShares(address _account, address _token, uint _shares) internal returns(uint amount) {
    amount = _burnDebtShares(_token, _account, _shares);
    emit Repay(_account, _token, amount);
  }

  function _deposit(address _account, address _token, uint _amount) internal {

    require(debtSharesOf[_token][_account] == 0, "LendingPair: cannot deposit borrowed token");

    _checkDepositsEnabled();
    _checkDepositLimit(_token, _amount);
    _mintSupplyAmount(_token, _account, _amount);

    emit Deposit(_account, _token, _amount);
  }

  function _createLpToken(address _lpTokenMaster, address _underlying) internal returns(address) {
    ILPTokenMaster newLPToken = ILPTokenMaster(_lpTokenMaster.clone());
    newLPToken.initialize(_underlying, address(lendingController));
    return address(newLPToken);
  }

  function _amountToShares(uint _totalShares, uint _totalAmount, uint _inputSupply) internal view returns(uint) {
    if (_totalShares > 0 && _totalAmount > 0) {
      return _inputSupply * _totalShares / _totalAmount;
    } else {
      return _inputSupply;
    }
  }

  function _sharesToAmount(uint _totalShares, uint _totalAmount, uint _inputShares) internal view returns(uint) {
    if (_totalShares > 0 && _totalAmount > 0) {
      return _inputShares * _totalAmount / _totalShares;
    } else {
      return _inputShares;
    }
  }

  function _debtToShares(address _token, uint _amount) internal view returns(uint) {
    return _amountToShares(totalDebtShares[_token], totalDebtAmount[_token], _amount);
  }

  function _sharesToDebt(address _token, uint _shares) internal view returns(uint) {
    return _sharesToAmount(totalDebtShares[_token], totalDebtAmount[_token], _shares);
  }

  function _supplyToShares(address _token, uint _amount) internal view returns(uint) {
    return _amountToShares(totalSupplyShares[_token], totalSupplyAmount[_token], _amount);
  }

  function _sharesToSupply(address _token, uint _shares) internal view returns(uint) {
    return _sharesToAmount(totalSupplyShares[_token], totalSupplyAmount[_token], _shares);
  }

  function _debtOf(address _token, address _account) internal view returns(uint) {
    return _sharesToDebt(_token, debtSharesOf[_token][_account]);
  }

  function _supplyOf(address _token, address _account) internal view returns(uint) {
    return _sharesToSupply(_token, supplySharesOf[_token][_account]);
  }

  function _interestRatePerBlock(address _token) internal view returns(uint) {
    return _interestRateModel().interestRatePerBlock(
      address(this),
      _token,
      totalSupplyAmount[_token],
      totalDebtAmount[_token]
    );
  }

  function _interestRateModel() internal view returns(IInterestRateModel) {
    return IInterestRateModel(lendingController.interestRateModel());
  }

  // Get borrow balance converted to the units of _returnToken
  function _borrowBalanceConverted(
    address _account,
    address _borrowedToken,
    address _returnToken,
    uint    _borrowPrice,
    uint    _returnPrice
  ) internal view returns(uint) {

    return _convertTokenValues(
      _borrowedToken,
      _returnToken,
      _debtOf(_borrowedToken, _account),
      _borrowPrice,
      _returnPrice
    );
  }

  // Get supply balance converted to the units of _returnToken
  function _supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken,
    uint    _supplyPrice,
    uint    _returnPrice
  ) internal view returns(uint) {

    return _convertTokenValues(
      _suppliedToken,
      _returnToken,
      _supplyOf(_suppliedToken, _account),
      _supplyPrice,
      _returnPrice
    );
  }

  function _convertedCreditAUni(
    address _account,
    uint    _priceA,
    uint    _priceB,
    uint    _colFactorA,
    uint    _colFactorB
  ) internal view returns(uint) {

    if (uniPosition[_account] > 0) {

      (uint amountA, uint amountB) = _positionAmounts(uniPosition[_account], _priceA, _priceB);

      uint creditA = amountA * _colFactorA / 100e18;
      uint creditB = _convertTokenValues(tokenB, tokenA, amountB, _priceB, _priceA) * _colFactorB / 100e18;

      return (creditA + creditB);

    } else {
      return 0;
    }
  }

  function _positionAmounts(
    uint _position,
    uint _priceA,
    uint _priceB
  ) internal view returns(uint, uint) {

    uint priceA = 1 * 10 ** decimals[tokenB];
    uint priceB = _priceB * 10 ** decimals[tokenA] / _priceA;

    return uniV3Helper.positionAmounts(_position, priceA, priceB);
  }

  // Not calling priceOracle.convertTokenValues() to save gas by reusing already fetched prices
  function _convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount,
    uint    _fromPrice,
    uint    _toPrice
  ) internal view returns(uint) {

    uint fromPrice = _fromPrice * 1e18 / 10 ** decimals[_fromToken];
    uint toPrice   = _toPrice   * 1e18 / 10 ** decimals[_toToken];

    return _inputAmount * fromPrice / toPrice;
  }

  function _validateToken(address _token) internal view {
    require(_token == tokenA || _token == tokenB, "LendingPair: invalid token");
  }

  function _validateUniPosition(uint _positionID) internal view {
    (, , address uniTokenA, address uniTokenB, , , , uint liquidity, , , ,) = positionManager.positions(_positionID);
    require(liquidity > 0, "LendingPair: liquidity > 0");
    _validateToken(uniTokenA);
    _validateToken(uniTokenB);
  }

  function _checkDepositsEnabled() internal view {
    require(lendingController.depositsEnabled(), "LendingPair: deposits disabled");
  }

  function _checkBorrowEnabled() internal view {
    require(lendingController.borrowingEnabled(), "LendingPair: borrowing disabled");
  }

  function _checkDepositLimit(address _token, uint _amount) internal view {
    uint depositLimit = lendingController.depositLimit(address(this), _token);

    if (depositLimit > 0) {
      require(
        totalSupplyAmount[_token] + _amount <= depositLimit,
        "LendingPair: deposit limit reached"
      );
    }
  }

  function _checkBorrowLimits(address _token, address _account, uint _amount) internal view {
    require(
      _debtOf(_token, _account) + _amount >= lendingController.minBorrow(_token),
      "LendingPair: borrow amount below minimum"
    );

    uint borrowLimit = lendingController.borrowLimit(address(this), _token);

    if (borrowLimit > 0) {
      require(totalDebtAmount[_token] + _amount <= borrowLimit, "LendingPair: borrow limit reached");
    }
  }

  function _lpRate(address _token) internal view returns(uint) {
    return _interestRateModel().lpRate(address(this), _token);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns(uint);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function allowance(address owner, address spender) external view returns(uint);
  function decimals() external view returns(uint8);
  function approve(address spender, uint amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint amount) external returns(bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC721 {

  function approve(address to, uint tokenId) external;
  function ownerOf(uint _tokenId) external view returns (address);

  function safeTransferFrom(
    address from,
    address to,
    uint tokenId
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";
import "IERC20.sol";

interface ILPTokenMaster is IOwnable, IERC20 {
  function initialize(address _underlying, address _lendingController) external;
  function underlying() external view returns(address);
  function lendingPair() external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address _newOwner) external;
  function acceptOwnership() external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface ILendingPair {

  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(address);
  function deposit(address _account, address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function withdrawAll(address _token) external;
  function transferLp(address _token, address _from, address _to, uint _amount) external;
  function supplySharesOf(address _token, address _account) external view returns(uint);
  function totalSupplyShares(address _token) external view returns(uint);
  function totalSupplyAmount(address _token) external view returns(uint);
  function totalDebtShares(address _token) external view returns(uint);
  function totalDebtAmount(address _token) external view returns(uint);
  function supplyOf(address _token, address _account) external view returns(uint);

  function supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view returns(uint);

  function initialize(
    address _lpTokenMaster,
    address _lendingController,
    address _uniV3Helper,
    address _feeRecipient,
    address _tokenA,
    address _tokenB
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";

interface ILendingController is IOwnable {
  function interestRateModel() external view returns(address);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function uniMinOutputPct() external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function tokenPrice(address _token) external view returns(uint);
  function minBorrow(address _token) external view returns(uint);
  function tokenPrices(address _tokenA, address _tokenB) external view returns (uint, uint);
  function tokenSupported(address _token) external view returns(bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IInterestRateModel {
  function lpRate(address _pair, address _token) external view returns(uint);
  function interestRatePerBlock(address _pair, address _token, uint _totalSupply, uint _totalDebt) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >0.7.0;

interface IUniswapV3Helper {
  function removeLiquidity(uint _tokenId, uint _minOutput0, uint _minOutput1) external returns (uint, uint);
  function collectFees(uint _tokenId) external returns (uint amount0, uint amount1);
  function positionTokens(uint _tokenId) external view returns(address, address);
  function positionAmounts(uint _tokenId, uint _price0, uint _price1) external view returns(uint, uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

// We can't use full INonfungiblePositionManager as provided by Uniswap since it's on Solidity 0.7

interface INonfungiblePositionManagerSimple {

  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library Math {

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute.
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor () {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library AddressLibrary {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "ILPTokenMaster.sol";
import "ILendingPair.sol";
import "ILendingController.sol";
import "SafeOwnable.sol";

contract LPTokenMaster is ILPTokenMaster, SafeOwnable {

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event NameChange(string _name, string _symbol);

  mapping (address => mapping (address => uint)) public override allowance;

  address public override underlying;
  address public lendingController;
  string  public constant name = "WILD-LP";
  string  public constant symbol = "WILD-LP";
  uint8   public constant override decimals = 18;
  bool    private initialized;

  modifier onlyOperator() {
    require(msg.sender == ILendingController(lendingController).owner(), "LPToken: caller is not an operator");
    _;
  }

  function initialize(address _underlying, address _lendingController) external override {
    require(initialized != true, "LPToken: already intialized");
    owner = msg.sender;
    underlying = _underlying;
    lendingController = _lendingController;
    initialized = true;
  }

  function transfer(address _recipient, uint _amount) external override returns(bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  function approve(address _spender, uint _amount) external override returns(bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(address _sender, address _recipient, uint _amount) external override returns(bool) {
    _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
    _transfer(_sender, _recipient, _amount);
    return true;
  }

  function lendingPair() external view override returns(address) {
    return owner;
  }

  function balanceOf(address _account) external view override returns(uint) {
    return ILendingPair(owner).supplySharesOf(underlying, _account);
  }

  function totalSupply() external view override returns(uint) {
    return ILendingPair(owner).totalSupplyShares(underlying);
  }

  function _transfer(address _sender, address _recipient, uint _amount) internal {
    require(_sender != address(0), "ERC20: transfer from the zero address");
    require(_recipient != address(0), "ERC20: transfer to the zero address");

    ILendingPair(owner).transferLp(underlying, _sender, _recipient, _amount);

    emit Transfer(_sender, _recipient, _amount);
  }

  function _approve(address _owner, address _spender, uint _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");

    allowance[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";

contract SafeOwnable is IOwnable {

  uint public constant RENOUNCE_TIMEOUT = 1 hours;

  address public override owner;
  address public pendingOwner;
  uint public renouncedAt;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external override onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external override {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function initiateRenounceOwnership() external onlyOwner {
    require(renouncedAt == 0, "Ownable: already initiated");
    renouncedAt = block.timestamp;
  }

  function acceptRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    require(block.timestamp - renouncedAt > RENOUNCE_TIMEOUT, "Ownable: too early");
    owner = address(0);
    pendingOwner = address(0);
    renouncedAt = 0;
  }

  function cancelRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    renouncedAt = 0;
  }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity >0.7.0;

contract ERC721Receivable {

  function onERC721Received(
    address _operator,
    address _user,
    uint _tokenId,
    bytes memory _data
  ) public returns (bytes4) {
    return 0x150b7a02;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "IWETH.sol";
import "IERC20.sol";
import "SafeERC20.sol";

contract TransferHelper {

  using SafeERC20 for IERC20;

  // Mainnet
  IWETH internal constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  // Goerli
  // IWETH internal constant WETH = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

  function _safeTransferFrom(address _token, address _sender, uint _amount) internal {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
  }

  function _safeTransfer(address _token, address _recipient, uint _amount) internal {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    IERC20(_token).safeTransfer(_recipient, _amount);
  }

  function _wethWithdrawTo(address _to, uint _amount) internal {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    require(_to != address(0), "TransferHelper: invalid recipient");

    WETH.withdraw(_amount);
    (bool success, ) = _to.call { value: _amount }(new bytes(0));
    require(success, 'TransferHelper: ETH transfer failed');
  }

  function _depositWeth() internal {
    require(msg.value > 0, "TransferHelper: amount must be > 0");
    WETH.deposit { value: msg.value }();
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "IERC20.sol";
import "SafeMath.sol";
import "AddressLibrary.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using AddressLibrary for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}