/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2021 0xdev0 - All rights reserved
// https://twitter.com/0xdev0

pragma solidity ^0.8.0;

interface IERC20 {
  function initialize() external;
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IPairFactory {
  function pairByTokens(address _tokenA, address _tokenB) external view returns(address);
}

interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function totalDebt(address _token) external view returns(uint);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawRepay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function swapTokenToToken(
    address  _fromToken,
    address  _toToken,
    address  _recipient,
    uint     _inputAmount,
    uint     _minOutput,
    uint     _deadline
  ) external returns(uint);
}

interface IInterestRateModel {
  function systemRate(ILendingPair _pair) external view returns(uint);
  function supplyRate(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRate(ILendingPair _pair, address _token) external view returns(uint);
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function feeRecipient() external view returns(address);
  function priceDelay() external view returns(uint);
  function slowPricePeriod() external view returns(uint);
  function slowPriceRange() external view returns(uint);
  function liqMinHealth() external view returns(uint);
  function liqFeePool() external view returns(uint);
  function liqFeeSystem() external view returns(uint);
  function liqFeeCaller() external view returns(uint);
  function liqFeesTotal() external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
}

interface IWETH {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
}

contract TransferHelper {

  // Mainnet
  IWETH internal constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  // Ropsten
  // IWETH internal constant WETH = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);

  function _safeTransferFrom(address _token, address _sender, uint _amount) internal returns(uint) {
    IERC20(_token).transferFrom(_sender, address(this), _amount);
    require(_amount > 0, "TransferHelper: amount must be > 0");
  }

  function _wethWithdrawTo(address _to, uint _amount) internal {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    WETH.withdraw(_amount);
    (bool success, ) = _to.call { value: _amount }(new bytes(0));
    require(success, 'TransferHelper: ETH transfer failed');
  }
}

contract Router is TransferHelper {

  uint MAX_INT = 2**256 - 1;

  IPairFactory public pairFactory;

  receive() external payable {}

  constructor(IPairFactory _pairFactory) {
    pairFactory = _pairFactory;
  }

  function swapETHToToken(
      address[] memory _path,
      address  _recipient,
      uint     _minOutput,
      uint     _deadline
  ) public payable returns(uint) {

    WETH.deposit { value: msg.value }();
    (IERC20 outputToken, uint outputAmount) = _swap(_path, _minOutput, _deadline);
    outputToken.transfer(_recipient, outputAmount);

    return outputAmount;
  }

  function swapTokenToETH(
      address[] memory _path,
      address  _recipient,
      uint     _inputAmount,
      uint     _minOutput,
      uint     _deadline
  ) public returns(uint) {

    _safeTransferFrom(_path[0], msg.sender, _inputAmount);
    (, uint outputAmount) = _swap(_path, _minOutput, _deadline);
    _wethWithdrawTo(_recipient, outputAmount);

    return outputAmount;
  }

  function swapTokenToToken(
      address[] memory _path,
      address  _recipient,
      uint     _inputAmount,
      uint     _minOutput,
      uint     _deadline
  ) public returns(uint) {

    _safeTransferFrom(_path[0], msg.sender, _inputAmount);
    (IERC20 outputToken, uint outputAmount) = _swap(_path, _minOutput, _deadline);
    outputToken.transfer(_recipient, outputAmount);

    return outputAmount;
  }

  function addLiquidity(
    address _tokenA,
    address _tokenB,
    uint _amountA,
    uint _amountB
  ) public {

    _safeTransferFrom(_tokenA, msg.sender, _amountA);
    _safeTransferFrom(_tokenB, msg.sender, _amountB);

    _addLiquidity(_tokenA, _tokenB, _amountA, _amountB);
  }

  function addLiquidityETH(address _token, uint _amount) public payable {

    _safeTransferFrom(_token, msg.sender, _amount);
    WETH.deposit { value: msg.value }();

    _addLiquidity(_token, address(WETH), _amount, msg.value);
  }

  function _addLiquidity(
    address _tokenA,
    address _tokenB,
    uint _amountA,
    uint _amountB
  ) internal {
    ILendingPair lendingPair = ILendingPair(pairFactory.pairByTokens(_tokenA, _tokenB));

    IERC20(_tokenA).approve(address(lendingPair), MAX_INT);
    IERC20(_tokenB).approve(address(lendingPair), MAX_INT);

    lendingPair.deposit(_tokenA, _amountA);
    lendingPair.deposit(_tokenB, _amountB);

    lendingPair.lpToken(_tokenA).transfer(msg.sender, _amountA);
    lendingPair.lpToken(_tokenB).transfer(msg.sender, _amountB);
  }

  function _swap(address[] memory _path, uint _minOutput, uint _deadline) internal returns(IERC20, uint) {

    for (uint i; i < _path.length - 1; i++) {

      (address fromToken, address toToken) = (_path[i], _path[i + 1]);
      address lendingPair = pairFactory.pairByTokens(fromToken, toToken);

      uint inputAmount = IERC20(fromToken).balanceOf(address(this));

      IERC20(fromToken).approve(lendingPair, MAX_INT);

      ILendingPair(lendingPair).swapTokenToToken(
        fromToken,
        toToken,
        address(this),
        inputAmount,
        0,
        _deadline
      );
    }

    IERC20 outputToken = IERC20(_path[_path.length - 1]);
    uint outputAmount = outputToken.balanceOf(address(this));
    require(outputAmount >= _minOutput, "Router: insufficient return amount");

    return (outputToken, outputAmount);
  }
}