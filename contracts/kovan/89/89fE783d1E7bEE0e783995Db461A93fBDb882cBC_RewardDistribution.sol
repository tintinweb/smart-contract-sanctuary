/**
 *Submitted for verification at Etherscan.io on 2021-06-18
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

interface IPairFactory {
  function pairByTokens(address _tokenA, address _tokenB) external view returns(address);
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
  function liqFeePool() external view returns(uint);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function liqFeesTotal(address _token) external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
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

// Calling setTotalRewardPerBlock, addPool or setReward, pending rewards will be changed.
// Since all pools are likely to get accrued every hour or so, this is an acceptable deviation.
// Accruing all pools here may consume too much gas.
// up to the point of exceeding the gas limit if there are too many pools.

contract RewardDistribution is Ownable {

  struct Pool {
    address pair;
    address token;
    bool    isSupply;
    uint    points;             // How many allocation points assigned to this pool.
    uint    lastRewardBlock;    // Last block number that reward distribution occurs.
    uint    accRewardsPerToken; // Accumulated total rewards
  }

  struct PoolPosition {
    uint pid;
    bool added; // To prevent duplicates.
  }

  IPairFactory public factory;
  IERC20  public rewardToken;
  Pool[]  public pools;
  uint    public totalRewardPerBlock;
  uint    public totalPoints;

  // Pair[token][isSupply] supply = true, borrow = false
  mapping (address => mapping (address => mapping (bool => PoolPosition))) public pidByPairToken;
  // rewardSnapshot[pid][account]
  mapping (uint => mapping (address => uint)) public rewardSnapshot;

  event PoolUpdate(
    uint    indexed pid,
    address indexed pair,
    address indexed token,
    bool    isSupply,
    uint    points
  );

  event RewardRateUpdate(uint value);

  constructor(
    IPairFactory _factory,
    IERC20  _rewardToken,
    uint    _totalRewardPerBlock
  ) {
    factory = _factory;
    rewardToken = _rewardToken;
    totalRewardPerBlock = _totalRewardPerBlock;
  }

  function distributeReward(address _account, address _token) public {
    _onlyLendingPair();
    address pair = msg.sender;
    _distributeReward(_account, pair, _token, true);
    _distributeReward(_account, pair, _token, false);
  }

  function snapshotAccount(address _account, address _token, bool _isSupply) public {
    _onlyLendingPair();
    address pair = msg.sender;

    if (_poolExists(pair, _token, _isSupply)) {
      uint pid = _getPid(pair, _token, _isSupply);
      Pool memory pool = _getPool(pair, _token, _isSupply);
      rewardSnapshot[pid][_account] = pool.accRewardsPerToken * _stakedAccount(pool, _account) / 1e18;
    }
  }

  // Pending rewards will be changed. See class comments.
  function addPool(
    address _pair,
    address _token,
    bool    _isSupply,
    uint    _points
  ) public onlyOwner {

    require(
      pidByPairToken[_pair][_token][_isSupply].added == false,
      "RewardDistribution: already added"
    );

    require(
      ILendingPair(_pair).tokenA() == _token || ILendingPair(_pair).tokenB() == _token,
      "RewardDistribution: invalid token"
    );

    totalPoints += _points;

    pools.push(Pool({
      pair:     _pair,
      token:    _token,
      isSupply: _isSupply,
      points:   _points,
      lastRewardBlock: block.number,
      accRewardsPerToken: 0
    }));

    pidByPairToken[_pair][_token][_isSupply] = PoolPosition({
      pid: pools.length - 1,
      added: true
    });

    emit PoolUpdate(pools.length, _pair, _token, _isSupply, _points);
  }

  // Pending rewards will be changed. See class comments.
  function setReward(
    address _pair,
    address _token,
    bool    _isSupply,
    uint    _points
  ) public onlyOwner {

    uint pid = pidByPairToken[_pair][_token][_isSupply].pid;
    accruePool(pid);

    totalPoints = totalPoints - pools[pid].points + _points;
    pools[pid].points = _points;

    emit PoolUpdate(pid, _pair, _token, _isSupply, _points);
  }

  // Pending rewards will be changed. See class comments.
  function setTotalRewardPerBlock(uint _value) public onlyOwner {
    totalRewardPerBlock = _value;
    emit RewardRateUpdate(_value);
  }

  function accruePool(uint _pid) public {
    Pool storage pool = pools[_pid];
    pool.accRewardsPerToken += _pendingPoolReward(pool);
    pool.lastRewardBlock = block.number;
  }

  function pendingSupplyReward(address _account, address _pair, address _token) public view returns(uint) {
    if (_poolExists(_pair, _token, true)) {
      return _pendingAccountReward(_getPid(_pair, _token, true), _account);
    } else {
      return 0;
    }
  }

  function pendingBorrowReward(address _account, address _pair, address _token) public view returns(uint) {
    if (_poolExists(_pair, _token, false)) {
      return _pendingAccountReward(_getPid(_pair, _token, false), _account);
    } else {
      return 0;
    }
  }

  function pendingTokenReward(address _account, address _pair, address _token) public view returns(uint) {
    return pendingSupplyReward(_account, _pair, _token) + pendingBorrowReward(_account, _pair, _token);
  }

  function pendingAccountReward(address _account, address _pair) public view returns(uint) {
    ILendingPair pair = ILendingPair(_pair);
    return pendingTokenReward(_account, _pair, pair.tokenA()) + pendingTokenReward(_account, _pair, pair.tokenB());
  }

  function supplyBlockReward(address _pair, address _token) public view returns(uint) {
    return _poolRewardRate(_pair, _token, true);
  }

  function borrowBlockReward(address _pair, address _token) public view returns(uint) {
    return _poolRewardRate(_pair, _token, false);
  }

  function poolLength() public view returns (uint) {
    return pools.length;
  }

  // Allows to migrate rewards to a new staking contract.
  function migrateRewards(address _recipient, uint _amount) public onlyOwner {
    rewardToken.transfer(_recipient, _amount);
  }

  function _transferReward(address _to, uint _amount) internal {
    if (_amount > 0) {
      uint rewardTokenBal = rewardToken.balanceOf(address(this));
      if (_amount > rewardTokenBal) {
        rewardToken.transfer(_to, rewardTokenBal);
      } else {
        rewardToken.transfer(_to, _amount);
      }
    }
  }

  function _distributeReward(address _account, address _pair, address _token, bool _isSupply) internal {

    if (_poolExists(_pair, _token, _isSupply)) {

      uint pid = _getPid(_pair, _token, _isSupply);

      accruePool(pid);
      _transferReward(_account, _pendingAccountReward(pid, _account));
    }
  }

  function _poolRewardRate(address _pair, address _token, bool _isSupply) internal view returns(uint) {

    if (_poolExists(_pair, _token, _isSupply)) {

      Pool memory pool = _getPool(_pair, _token, _isSupply);
      return totalRewardPerBlock * pool.points / totalPoints;

    } else {
      return 0;
    }
  }

  function _pendingAccountReward(uint _pid, address _account) internal view returns(uint) {
    Pool memory pool = pools[_pid];

    uint stakedTotal = _stakedTotal(pool);

    if (stakedTotal == 0) {
      return 0;
    }

    pool.accRewardsPerToken += _pendingPoolReward(pool);
    uint stakedAccount = _stakedAccount(pool, _account);
    return pool.accRewardsPerToken * stakedAccount / 1e18 - rewardSnapshot[_pid][_account];
  }

  function _pendingPoolReward(Pool memory _pool) internal view returns(uint) {
    uint totalStaked = _stakedTotal(_pool);

    if (_pool.lastRewardBlock == 0 || totalStaked == 0) {
      return 0;
    }

    uint blocksElapsed = block.number - _pool.lastRewardBlock;
    return blocksElapsed * _poolRewardRate(_pool.pair, _pool.token, _pool.isSupply) * 1e18 / totalStaked;
  }

  function _getPool(address _pair, address _token, bool _isSupply) internal view returns(Pool memory) {
    return pools[_getPid(_pair, _token, _isSupply)];
  }

  function _getPid(address _pair, address _token, bool _isSupply) internal view returns(uint) {
    PoolPosition memory poolPosition = pidByPairToken[_pair][_token][_isSupply];
    require(poolPosition.added, "RewardDistribution: invalid pool");

    return pidByPairToken[_pair][_token][_isSupply].pid;
  }

  function _poolExists(address _pair, address _token, bool _isSupply) internal view returns(bool) {
    return pidByPairToken[_pair][_token][_isSupply].added;
  }

  function _stakedTotal(Pool memory _pool) internal view returns(uint) {
    ILendingPair pair = ILendingPair(_pool.pair);

    if (_pool.isSupply) {
      return pair.lpToken(_pool.token).totalSupply();
    } else {
      return pair.totalDebt(_pool.token);
    }
  }

  function _stakedAccount(Pool memory _pool, address _account) internal view returns(uint) {
    ILendingPair pair = ILendingPair(_pool.pair);

    if (_pool.isSupply) {
      return pair.lpToken(_pool.token).balanceOf(_account);
    } else {
      return pair.debtOf(_pool.token, _account);
    }
  }

  function _onlyLendingPair() internal view {

    if (_isContract(msg.sender)) {
      address factoryPair = factory.pairByTokens(ILendingPair(msg.sender).tokenA(), ILendingPair(msg.sender).tokenB());
      require(factoryPair == msg.sender, "RewardDistribution: caller not lending pair");

    } else {
      revert("RewardDistribution: caller not lending pair");
    }
  }

  function _isContract(address _address) internal view returns(bool isContract) {
    uint32 size;
    assembly {
      size := extcodesize(_address)
    }
    return (size > 0);
  }
}