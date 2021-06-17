/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
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

interface IInterestRateModel {
  function systemRate(ILendingPair _pair, address _token) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IRewardDistribution {
  function distributeReward(address _account, address _token) external;
  function snapshotAccount(address _account, address _token, bool isSupply) external;
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function rewardDistribution() external view returns(IRewardDistribution);
  function feeRecipient() external view returns(address);
  function LIQ_MIN_HEALTH() external view returns(uint);
  function minBorrowUSD() external view returns(uint);
  function liqFeePool() external view returns(uint);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function liqFeesTotal(address _token) external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function setFeeRecipient(address _feeRecipient) external;
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
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

  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

interface IPriceOracle {
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
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

contract Controller is Ownable {

  uint public  constant LIQ_MIN_HEALTH = 1e18;
  uint private constant MAX_COL_FACTOR = 99e18;

  IInterestRateModel  public interestRateModel;
  IPriceOracle        public priceOracle;
  IRewardDistribution public rewardDistribution;

  bool public depositsEnabled;
  bool public borrowingEnabled;
  uint public liqFeeCallerDefault;
  uint public liqFeeSystemDefault;
  uint public minBorrowUSD;

  mapping(address => mapping(address => uint)) public depositLimit;
  mapping(address => mapping(address => uint)) public borrowLimit;
  mapping(address => uint) public liqFeeCallerToken; // 1e18  = 1%
  mapping(address => uint) public liqFeeSystemToken; // 1e18  = 1%
  mapping(address => uint) public colFactor; // 99e18 = 99%

  address public feeRecipient;

  event NewFeeRecipient(address feeRecipient);
  event NewInterestRateModel(address interestRateModel);
  event NewPriceOracle(address priceOracle);
  event NewRewardDistribution(address rewardDistribution);
  event NewColFactor(address token, uint value);
  event NewDepositLimit(address pair, address token, uint value);
  event NewBorrowLimit(address pair, address token, uint value);
  event DepositsEnabled(bool value);
  event BorrowingEnabled(bool value);
  event NewLiqParamsToken(address token, uint liqFeeSystem, uint liqFeeCaller);
  event NewLiqParamsDefault(uint liqFeeSystem, uint liqFeeCaller);

  constructor(
    IInterestRateModel _interestRateModel,
    uint _liqFeeSystemDefault,
    uint _liqFeeCallerDefault
  ) {
    feeRecipient = msg.sender;
    interestRateModel = _interestRateModel;
    liqFeeSystemDefault = _liqFeeSystemDefault;
    liqFeeCallerDefault = _liqFeeCallerDefault;
    depositsEnabled = true;
    borrowingEnabled = true;
  }

  function setFeeRecipient(address _feeRecipient) public onlyOwner {
    feeRecipient = _feeRecipient;
    emit NewFeeRecipient(_feeRecipient);
  }

  function setLiqParamsToken(
    address _token,
    uint    _liqFeeSystem,
    uint    _liqFeeCaller
  ) public onlyOwner {
    // Never more than a total of 50%
    require(_liqFeeCaller + _liqFeeSystem <= 50e18, "Controller: fees too high");

    liqFeeSystemToken[_token] = _liqFeeSystem;
    liqFeeCallerToken[_token] = _liqFeeCaller;

    emit NewLiqParamsToken(_token, _liqFeeSystem, _liqFeeCaller);
  }

  function setLiqParamsDefault(
    uint    _liqFeeSystem,
    uint    _liqFeeCaller
  ) public onlyOwner {
    // Never more than a total of 50%
    require(_liqFeeCaller + _liqFeeSystem <= 50e18, "Controller: fees too high");

    liqFeeSystemDefault = _liqFeeSystem;
    liqFeeCallerDefault = _liqFeeCaller;

    emit NewLiqParamsDefault(_liqFeeSystem, _liqFeeCaller);
  }

  function setInterestRateModel(IInterestRateModel _value) public onlyOwner {
    interestRateModel = _value;
    emit NewInterestRateModel(address(_value));
  }

  function setPriceOracle(IPriceOracle _oracle) public onlyOwner {
    priceOracle = _oracle;
    emit NewPriceOracle(address(_oracle));
  }

  function setRewardDistribution(IRewardDistribution _value) public onlyOwner {
    rewardDistribution = _value;
    emit NewRewardDistribution(address(_value));
  }

  function setDepositsEnabled(bool _value) public onlyOwner {
    depositsEnabled = _value;
    emit DepositsEnabled(_value);
  }

  function setBorrowingEnabled(bool _value) public onlyOwner {
    borrowingEnabled = _value;
    emit BorrowingEnabled(_value);
  }

  function setDepositLimit(address _pair, address _token, uint _value) public onlyOwner {
    depositLimit[_pair][_token] = _value;
    emit NewDepositLimit(_pair, _token, _value);
  }

  function setBorrowLimit(address _pair, address _token, uint _value) public onlyOwner {
    borrowLimit[_pair][_token] = _value;
    emit NewBorrowLimit(_pair, _token, _value);
  }

  function setMinBorrowUSD(uint _value) public onlyOwner {
    minBorrowUSD = _value;
  }

  function setColFactor(address _token, uint _value) public onlyOwner {
    require(_value <= MAX_COL_FACTOR, "Controller: _value <= MAX_COL_FACTOR");
    colFactor[_token] = _value;
    emit NewColFactor(_token, _value);
  }

  function liqFeesTotal(address _token) public view returns(uint) {
    return liqFeeSystem(_token) + liqFeeCaller(_token);
  }

  function liqFeeSystem(address _token) public view returns(uint) {
    return liqFeeSystemToken[_token] > 0 ? liqFeeSystemToken[_token] : liqFeeSystemDefault;
  }

  function liqFeeCaller(address _token) public view returns(uint) {
    return liqFeeCallerToken[_token] > 0 ? liqFeeCallerToken[_token] : liqFeeCallerDefault;
  }

  function tokenPrice(address _token) public view returns(uint) {
    return priceOracle.tokenPrice(_token);
  }

  function tokenSupported(address _token) public view returns(bool) {
    return priceOracle.tokenSupported(_token);
  }
}