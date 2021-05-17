/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: UNLICENSED

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

interface IUniswapRouter {

  function getAmountsOut(
    uint amountIn,
    address[] memory path
  ) external view returns (uint[] memory amounts);

  function getAmountsIn(
    uint amountOut,
    address[] memory path
  ) external view returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

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
}

interface IInterestRateModel {
  function systemRate(ILendingPair _pair) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function feeRecipient() external view returns(address);
  function liqMinHealth() external view returns(uint);
  function liqFeePool() external view returns(uint);
  function liqFeeSystem() external view returns(uint);
  function liqFeeCaller() external view returns(uint);
  function liqFeesTotal() external view returns(uint);
  function tokenPrice(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function setFeeRecipient(address _feeRecipient) external;
}

interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function accrueAccount(address _account) external;
  function accrue() external;
  function accountHealth(address _account) external view returns(uint);
  function totalDebt(address _token) external view returns(uint);
  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawRepay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract FeeConverter is Ownable {

  uint MAX_INT = 2**256 - 1;

  // Only large liquid tokens: ETH, DAI, USDC, WBTC, etc
  mapping (address => bool) public permittedTokens;

  IUniswapRouter public uniswapRouter;
  IERC20 public wildToken;
  IController public controller;
  address public stakingPool;
  uint public callIncentive;

  event FeeDistribution(uint amount);

  constructor(
    IUniswapRouter _uniswapRouter,
    IController _controller,
    IERC20 _wildToken,
    address _stakingPool,
    uint _callIncentive
  ) {
    uniswapRouter = _uniswapRouter;
    controller = _controller;
    stakingPool = _stakingPool;
    callIncentive = _callIncentive;
    wildToken = _wildToken;
  }

  function convert(
    address _sender,
    ILendingPair _pair,
    address[] memory _path,
    uint _supplyTokenAmount
  ) public {

    _validatePath(_path);
    require(_pair.controller() == controller, "FeeConverter: invalid pair");
    require(_supplyTokenAmount > 0, "FeeConverter: nothing to convert");

    _pair.withdraw(_path[0], _supplyTokenAmount);
    IERC20(_path[0]).approve(address(uniswapRouter), MAX_INT);

    uniswapRouter.swapExactTokensForTokens(
      _supplyTokenAmount,
      0,
      _path,
      address(this),
      block.timestamp + 1000
    );

    uint wildBalance = wildToken.balanceOf(address(this));
    uint callerIncentive = wildBalance * callIncentive / 100e18;
    wildToken.transfer(_sender, callerIncentive);
    wildToken.transfer(stakingPool, wildBalance - callerIncentive);

    emit FeeDistribution(wildBalance - callerIncentive);
  }

  function setStakingRewards(address _value) onlyOwner public {
    stakingPool = _value;
  }

  function setCallIncentive(uint _value) onlyOwner public {
    callIncentive = _value;
  }

  function permitToken(address _token, bool _value) onlyOwner public {
    permittedTokens[_token] = _value;
  }

  function _validatePath(address[] memory _path) internal view {
    require(_path[_path.length - 1] == address(wildToken), "FeeConverter: must convert into WILD");

    // Validate only middle tokens. Skip the first and last token.
    for (uint i; i < _path.length - 1; i++) {
      if (i > 0) {
        require(permittedTokens[_path[i]], "FeeConverter: invalid path");
      }
    }
  }
}