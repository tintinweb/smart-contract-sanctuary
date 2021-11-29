pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAlphaDistributor.sol";
import "./interfaces/IAlphaReceiver.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IPoolConfiguration.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IVestingAlpha.sol";
import "./AlToken.sol";
import "./AlTokenDeployer.sol";
import "./libraries/WadMath.sol";
import "./libraries/Math.sol";

/**
 * @title Lending pool contract
 * @notice Implements the core contract of lending pool.
 * this contract manages all states and handles user interaction with the pool.
 * @author Alpha
 **/

contract LendingPool is Ownable, ILendingPool, IAlphaReceiver, ReentrancyGuard {
  using SafeMath for uint256;
  using WadMath for uint256;
  using Math for uint256;
  using SafeERC20 for ERC20;

  /*
   * Lending pool smart contracts
   * -----------------------------
   * Each ERC20 token has an individual pool which users provide their liquidity to the pool.
   * Users can use their liquidity as collateral to borrow any asset from all pools if their account is still healthy.
   * By account health checking, the total borrow value must less than the total collateral value (collateral value is
   * ~75% of the liquidity value depends on each token). Borrower need to repay the loan with accumulated interest.
   * Liquidity provider would receive the borrow interest. In case of the user account is not healthy
   * then liquidator can help to liquidate the user's account then receive the collateral with liquidation bonus as the reward.
   *
   * The status of the pool
   * -----------------------------
   * The pool has 3 status. every pool will have only one status at a time.
   * 1. INACTIVE - the pool is on initialized state or inactive state so it's not ready for user to do any actions. users can't deposit, borrow,
   * repay and withdraw
   * 2 .ACTIVE - the pool is active. users can deposit, borrow, repay, withdraw and liquidate
   * 3. CLOSED - the pool is waiting for inactive state. users can clear their account by repaying, withdrawal, liquidation but can't deposit, borrow
   */
  enum PoolStatus {INACTIVE, ACTIVE, CLOSED}
  uint256 internal constant SECONDS_PER_YEAR = 365 days;
  /**
   * @dev emitted on initilize pool
   * @param pool the address of the ERC20 token of the pool
   * @param alTokenAddress the address of the pool's alToken
   * @param poolConfigAddress the address of the pool's configuration contract
   */
  event PoolInitialized(
    address indexed pool,
    address indexed alTokenAddress,
    address indexed poolConfigAddress
  );

  /**
   * @dev emitted on update pool configuration
   * @param pool the address of the ERC20 token of the pool
   * @param poolConfigAddress the address of the updated pool's configuration contract
   */
  event PoolConfigUpdated(address indexed pool, address poolConfigAddress);

  /**
   * @dev emitted on set price oracle
   * @param priceOracleAddress the address of the price oracle
   */
  event PoolPriceOracleUpdated(address indexed priceOracleAddress);

  /**
   * @dev emitted on pool updates interest
   * @param pool the address of the ERC20 token of the pool
   * @param cumulativeBorrowInterest the borrow interest which accumulated from last update timestamp to now
   * @param totalBorrows the updated total borrows of the pool. increasing by the cumulative borrow interest.
   */
  event PoolInterestUpdated(
    address indexed pool,
    uint256 cumulativeBorrowInterest,
    uint256 totalBorrows
  );

  /**
   * @dev emitted on deposit
   * @param pool the address of the ERC20 token of the pool
   * @param user the address of the user who deposit the ERC20 token to the pool
   * @param depositShares the share amount of the ERC20 token which calculated from deposit amount
   * Note: depositShares is the same as number of alphaToken
   * @param depositAmount the amount of the ERC20 that deposit to the pool
   */
  event Deposit(
    address indexed pool,
    address indexed user,
    uint256 depositShares,
    uint256 depositAmount
  );

  /**
   * @dev emitted on borrow
   * @param pool the address of the ERC20 token of the pool
   * @param user the address of the user who borrow the ERC20 token from the pool
   * @param borrowShares the amount of borrow shares which calculated from borrow amount
   * @param borrowAmount the amount of borrow
   */
  event Borrow(
    address indexed pool,
    address indexed user,
    uint256 borrowShares,
    uint256 borrowAmount
  );

  /**
   * @dev emitted on repay
   * @param pool the address of the ERC20 token of the pool
   * @param user the address of the user who repay the ERC20 token to the pool
   * @param repayShares the amount of repay shares which calculated from repay amount
   * @param repayAmount the amount of repay
   */
  event Repay(address indexed pool, address indexed user, uint256 repayShares, uint256 repayAmount);

  /**
   * @dev emitted on withdraw alToken
   * @param pool the address of the ERC20 token of the pool
   * @param user the address of the user who withdraw the ERC20 token from the pool
   * @param withdrawShares the amount of withdraw shares which calculated from withdraw amount
   * @param withdrawAmount the amount of withdraw
   */
  event Withdraw(
    address indexed pool,
    address indexed user,
    uint256 withdrawShares,
    uint256 withdrawAmount
  );

  /**
   * @dev emitted on liquidate
   * @param user the address of the user who is liquidated by liquidator
   * @param pool the address of the ERC20 token which is liquidated by liquidator
   * @param collateral the address of the ERC20 token that liquidator received as a rewards
   * @param liquidateAmount the amount of the ERC20 token that liquidator liquidate for the user
   * @param liquidateShares the amount of liquidate shares which calculated from liquidate amount
   * @param collateralAmount the amount of the collateral which calculated from liquidate amount that liquidator want to liquidate
   * @param collateralShares the amount of collateral shares which liquidator received from liquidation in from of alToken
   * @param liquidator the address of the liquidator
   */
  event Liquidate(
    address indexed user,
    address pool,
    address collateral,
    uint256 liquidateAmount,
    uint256 liquidateShares,
    uint256 collateralAmount,
    uint256 collateralShares,
    address liquidator
  );

  /**
   * @dev emitted on reserve withdraw
   * @param pool the address of the ERC20 token of the pool
   * @param amount the amount to withdraw
   * @param withdrawer the address of withdrawer
   */
  event ReserveWithdrawn(address indexed pool, uint256 amount, address withdrawer);

  /**
   * @dev emitted on update reserve percent
   * @param previousReservePercent the previous pool's reserve percent
   * @param newReservePercent the updated pool's reserve percent
   */
  event ReservePercentUpdated(uint256 previousReservePercent, uint256 newReservePercent);

  /**
   * @dev the struct for storing the user's state separately on each pool
   */
  struct UserPoolData {
    // the user set to used this pool as collateral for borrowing
    bool disableUseAsCollateral;
    // borrow shares of the user of this pool. If user didn't borrow this pool then shere will be 0
    uint256 borrowShares;
    // latest alpha multiplier (borrow reward multiplier) of the user of this pool. Using to calculate current borrow reward.
    uint256 latestAlphaMultiplier;
  }

  /**
   * @dev the struct for storing the pool's state separately on each ERC20 token
   */
  struct Pool {
    // pool status
    PoolStatus status;
    // al token of the pool
    AlToken alToken;
    // pool configuration contract
    IPoolConfiguration poolConfig;
    // total borrow amount on this pool
    uint256 totalBorrows;
    // total share on this pool
    uint256 totalBorrowShares;
    // reserve amount on this pool
    uint256 poolReserves;
    // last update timestamp of this pool
    uint256 lastUpdateTimestamp;
    // total alpha token reward on this pool
    uint256 totalAlphaTokenReward;
    // alpha reward multiplier of each borrow share
    uint256 alphaMultiplier;
  }

  /**
   * @dev the mapping from the ERC20 token to the pool struct of that ERC20 token
   * token address => pool
   */
  mapping(address => Pool) public pools;

  /**
   * @dev the mapping from user address to the ERC20 token to the user data of
   * that ERC20 token's pool
   * user address => token address => user pool data
   */
  mapping(address => mapping(address => UserPoolData)) public userPoolData;

  /**
   * @dev list of all tokens on the lending pool contract.
   */
  ERC20[] public tokenList;

  /**
   * @dev price oracle of the lending pool contract.
   */
  IPriceOracle priceOracle;

  /**
   * @dev alpha token address contract.
   */
  IAlphaDistributor public override distributor;

  /**
   * @dev AltokenDeployer address
   */
  AlTokenDeployer public alTokenDeployer;
  /**
   * @dev VestingAlpha address
   */
  IVestingAlpha public override vestingAlpha;
  // max purchase percent of each liquidation
  // max purchase shares is 50% of user borrow shares
  uint256 public constant CLOSE_FACTOR = 0.5 * 1e18;
  uint256 public constant EQUILIBRIUM = 0.5 * 1e18;
  uint256 public constant MAX_UTILIZATION_RATE = 1 * 1e18;
  uint256 public reservePercent = 0.05 * 1e18;

  constructor(AlTokenDeployer _alTokenDeployer) public {
    alTokenDeployer = _alTokenDeployer;
  }

  /**
   * @dev update accumulated pool's borrow interest from last update timestamp to now then add to total borrows of that pool.
   * any function that use this modifier will update pool's total borrows before starting the function.
   * @param  _token the ERC20 token of the pool that will update accumulated borrow interest to total borrows
   */
  modifier updatePoolWithInterestsAndTimestamp(ERC20 _token) {
    Pool storage pool = pools[address(_token)];
    uint256 borrowInterestRate = pool.poolConfig.calculateInterestRate(
      pool.totalBorrows,
      getTotalLiquidity(_token)
    );
    uint256 cumulativeBorrowInterest = calculateLinearInterest(
      borrowInterestRate,
      pool.lastUpdateTimestamp,
      block.timestamp
    );

    // update pool
    uint256 previousTotalBorrows = pool.totalBorrows;
    pool.totalBorrows = cumulativeBorrowInterest.wadMul(pool.totalBorrows);
    pool.poolReserves = pool.poolReserves.add(
      pool.totalBorrows.sub(previousTotalBorrows).wadMul(reservePercent)
    );
    pool.lastUpdateTimestamp = block.timestamp;
    emit PoolInterestUpdated(address(_token), cumulativeBorrowInterest, pool.totalBorrows);
    _;
  }

  /**
   * @dev update Alpha reward by call poke on distribution contract.
   */
  modifier updateAlphaReward() {
    if (address(distributor) != address(0)) {
      distributor.poke();
    }
    _;
  }

  /**
   * @dev initialize the ERC20 token pool. only owner can initialize the pool.
   * @param _token the ERC20 token of the pool
   * @param _poolConfig the configuration contract of the pool
   */
  function initPool(ERC20 _token, IPoolConfiguration _poolConfig) external onlyOwner {
    for (uint256 i = 0; i < tokenList.length; i++) {
      require(tokenList[i] != _token, "this pool already exists on lending pool");
    }
    string memory alTokenSymbol = string(abi.encodePacked("al", _token.symbol()));
    string memory alTokenName = string(abi.encodePacked("Al", _token.symbol()));
    AlToken alToken = alTokenDeployer.createNewAlToken(alTokenName, alTokenSymbol, _token);
    Pool memory pool = Pool(
      PoolStatus.INACTIVE,
      alToken,
      _poolConfig,
      0,
      0,
      0,
      block.timestamp,
      0,
      0
    );
    pools[address(_token)] = pool;
    tokenList.push(_token);
    emit PoolInitialized(address(_token), address(alToken), address(_poolConfig));
  }

  /**
   * @dev set pool configuration contract of the pool. only owner can set the pool configuration.
   * @param _token the ERC20 token of the pool that will set the configuration
   * @param _poolConfig the interface of the pool's configuration contract
   */
  function setPoolConfig(ERC20 _token, IPoolConfiguration _poolConfig) external onlyOwner {
    Pool storage pool = pools[address(_token)];
    require(
      address(pool.alToken) != address(0),
      "pool isn't initialized, can't set the pool config"
    );
    pool.poolConfig = _poolConfig;
    emit PoolConfigUpdated(address(_token), address(_poolConfig));
  }

  /**
   * @dev set the status of the lending pool. only owner can set the pool's status
   * @param _token the ERC20 token of the pool
   * @param _status the status of the pool
   */
  function setPoolStatus(ERC20 _token, PoolStatus _status) external onlyOwner {
    Pool storage pool = pools[address(_token)];
    pool.status = _status;
  }

  /**
   * @dev set user uses the ERC20 token as collateral flag
   * @param _token the ERC20 token of the pool
   * @param _useAsCollateral the boolean that represent user use the ERC20 token on the pool as collateral or not
   */
  function setUserUseAsCollateral(ERC20 _token, bool _useAsCollateral) external {
    UserPoolData storage userData = userPoolData[msg.sender][address(_token)];
    userData.disableUseAsCollateral = !_useAsCollateral;
    // only disable as collateral need to check the account health
    if (!_useAsCollateral) {
      require(isAccountHealthy(msg.sender), "can't set use as collateral, account isn't healthy.");
    }
  }

  /**
   * @dev set price oracle of the lending pool. only owner can set the price oracle.
   * @param _oracle the price oracle which will get asset price to the lending pool contract
   */
  function setPriceOracle(IPriceOracle _oracle) external onlyOwner {
    priceOracle = _oracle;
    emit PoolPriceOracleUpdated(address(_oracle));
  }

  /**
   * @dev get the pool of the ERC20 token
   * @param _token the ERC20 token of the pool
   * @return status - the pool's status, alTokenAddress - the pool's alToken, poolConfigAddress - the pool's configuration contract,
   * totalBorrows - the pool's total borrows, totalBorrowShares - the pool's total borrow shares, totalLiquidity - the pool's total liquidity,
   * totalAvailableLiquidity - the pool's total available liquidity, lastUpdateTimestamp - the pool's last update timestamp
   */
  function getPool(ERC20 _token)
    external
    view
    returns (
      PoolStatus status,
      address alTokenAddress,
      address poolConfigAddress,
      uint256 totalBorrows,
      uint256 totalBorrowShares,
      uint256 totalLiquidity,
      uint256 totalAvailableLiquidity,
      uint256 lastUpdateTimestamp
    )
  {
    Pool storage pool = pools[address(_token)];
    alTokenAddress = address(pool.alToken);
    poolConfigAddress = address(pool.poolConfig);
    totalBorrows = pool.totalBorrows;
    totalBorrowShares = pool.totalBorrowShares;
    totalLiquidity = getTotalLiquidity(_token);
    totalAvailableLiquidity = getTotalAvailableLiquidity(_token);
    lastUpdateTimestamp = pool.lastUpdateTimestamp;
    status = pool.status;
  }

  /**
   * @dev get user data of the ERC20 token pool
   * @param _user the address of user that need to get the data
   * @param _token the ERC20 token of the pool that need to get the data of the user
   * @return compoundedLiquidityBalance - the compounded liquidity balance of this user in this ERC20 token pool,
   * compoundedBorrowBalance - the compounded borrow balance of this user in this ERC20 pool,
   * userUsePoolAsCollateral - the boolean flag that the user
   * uses the liquidity in this ERC20 token pool as collateral or not
   */
  function getUserPoolData(address _user, ERC20 _token)
    public
    view
    returns (
      uint256 compoundedLiquidityBalance,
      uint256 compoundedBorrowBalance,
      bool userUsePoolAsCollateral
    )
  {
    compoundedLiquidityBalance = getUserCompoundedLiquidityBalance(_user, _token);
    compoundedBorrowBalance = getUserCompoundedBorrowBalance(_user, _token);
    userUsePoolAsCollateral = !userPoolData[_user][address(_token)].disableUseAsCollateral;
  }

  /**
   * @dev calculate the interest rate which is the part of the annual interest rate on the elapsed time
   * @param _rate an annual interest rate express in WAD
   * @param _fromTimestamp the start timestamp to calculate interest
   * @param _toTimestamp the end timestamp to calculate interest
   * @return the interest rate in between the start timestamp to the end timestamp
   */
  function calculateLinearInterest(
    uint256 _rate,
    uint256 _fromTimestamp,
    uint256 _toTimestamp
  ) internal pure returns (uint256) {
    return
      _rate.wadMul(_toTimestamp.sub(_fromTimestamp)).wadDiv(SECONDS_PER_YEAR).add(WadMath.wad());
  }

  /**
   * @dev get user's compounded borrow balance of the user in the ERC20 token pool
   * @param _user the address of the user
   * @param _token the ERC20 token of the pool that will get the compounded borrow balance
   * @return the compounded borrow balance of the user on the ERC20 token pool
   */
  function getUserCompoundedBorrowBalance(address _user, ERC20 _token)
    public
    view
    returns (uint256)
  {
    uint256 userBorrowShares = userPoolData[_user][address(_token)].borrowShares;
    return calculateRoundUpBorrowAmount(_token, userBorrowShares);
  }

  /**
   * @dev get user's compounded liquidity balance of the user in the ERC20 token pool
   * @param _user the account address of the user
   * @param _token the ERC20 token of the pool that will get the compounded liquidity balance
   * @return the compounded liquidity balance of the user on the ERC20 token pool
   */
  function getUserCompoundedLiquidityBalance(address _user, ERC20 _token)
    public
    view
    returns (uint256)
  {
    Pool storage pool = pools[address(_token)];
    uint256 userLiquidityShares = pool.alToken.balanceOf(_user);
    return calculateRoundDownLiquidityAmount(_token, userLiquidityShares);
  }

  /**
   * @dev get total available liquidity in the ERC20 token pool
   * @param _token the ERC20 token of the pool
   * @return the balance of the ERC20 token in the pool
   */
  function getTotalAvailableLiquidity(ERC20 _token) public view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  /**
   * @dev get total liquidity of the ERC20 token pool
   * @param _token the ERC20 token of the pool
   * @return the total liquidity on the lending pool which is the sum of total borrows and available liquidity
   */
  function getTotalLiquidity(ERC20 _token) public view returns (uint256) {
    Pool storage pool = pools[address(_token)];
    return
      pool.totalBorrows.add(getTotalAvailableLiquidity(_token)).sub(
        pools[address(_token)].poolReserves
      );
  }

  /**
   * @dev calculate liquidity share amount (round-down)
   * @param _token the ERC20 token of the pool
   * @param _amount the amount of liquidity to calculate the liquidity shares
   * @return the amount of liquidity shares which is calculated from the below formula
   * liquidity shares = (_amount * total liquidity shares) / total liquidity
   * if the calculated liquidity shares = 2.9 then liquidity shares will be 2
   */
  function calculateRoundDownLiquidityShareAmount(ERC20 _token, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    Pool storage pool = pools[address(_token)];
    uint256 totalLiquidity = getTotalLiquidity(_token);
    uint256 totalLiquidityShares = pool.alToken.totalSupply();
    if (totalLiquidity == 0 && totalLiquidityShares == 0) {
      return _amount;
    }
    return _amount.mul(totalLiquidityShares).div(totalLiquidity);
  }

  /**
   * @dev calculate borrow share amount (round-up)
   * @param _token the ERC20 token of the pool
   * @param _amount the amount of borrow to calculate the borrow shares
   * @return the borrow amount which is calculated from the below formula
   * borrow shares = ((amount * total borrow shares) + (total borrows -  1)) / total borrow
   * if the calculated borrow shares = 10.1 then the borrow shares = 11
   */
  function calculateRoundUpBorrowShareAmount(ERC20 _token, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    Pool storage pool = pools[address(_token)];
    // borrow share amount of the first borrowing is equal to amount
    if (pool.totalBorrows == 0 || pool.totalBorrowShares == 0) {
      return _amount;
    }
    return _amount.mul(pool.totalBorrowShares).divCeil(pool.totalBorrows);
  }

  /**
   * @dev calculate borrow share amount (round-down)
   * @param _token the ERC20 token of the pool
   * @param _amount the amount of borrow to calculate the borrow shares
   * @return the borrow amount which is calculated from the below formula
   * borrow shares = (_amount * total borrow shares) / total borrows
   * if the calculated borrow shares = 10.9 then the borrow shares = 10
   */
  function calculateRoundDownBorrowShareAmount(ERC20 _token, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    Pool storage pool = pools[address(_token)];
    if (pool.totalBorrowShares == 0) {
      return 0;
    }
    return _amount.mul(pool.totalBorrowShares).div(pool.totalBorrows);
  }

  /**
   * @dev calculate liquidity share amount (round-up)
   * @param _token the ERC20 token of the pool
   * @param _amount the amount of liquidity to calculate the liquidity shares
   * @return the liquidity shares which is calculated from the below formula
   * liquidity shares = ((amount * total liquidity shares) + (total liquidity - 1)) / total liquidity shares
   * if the calculated liquidity shares = 10.1 then the liquidity shares = 11
   */
  function calculateRoundUpLiquidityShareAmount(ERC20 _token, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    Pool storage pool = pools[address(_token)];
    uint256 poolTotalLiquidityShares = pool.alToken.totalSupply();
    uint256 poolTotalLiquidity = getTotalLiquidity(_token);
    // liquidity share amount of the first depositing is equal to amount
    if (poolTotalLiquidity == 0 || poolTotalLiquidityShares == 0) {
      return _amount;
    }
    return _amount.mul(poolTotalLiquidityShares).divCeil(poolTotalLiquidity);
  }

  /**
   * @dev calculate liquidity amount (round-down)
   * @param _token the ERC20 token of the pool
   * @param _shareAmount the liquidity shares to calculate the amount of liquidity
   * @return the amount of liquidity which is calculated from the below formula
   * liquidity amount = (_shareAmount * total liquidity) / total liquidity shares
   * if the calculated liquidity amount = 10.9 then the liquidity amount = 10
   */
  function calculateRoundDownLiquidityAmount(ERC20 _token, uint256 _shareAmount)
    internal
    view
    returns (uint256)
  {
    Pool storage pool = pools[address(_token)];
    uint256 poolTotalLiquidityShares = pool.alToken.totalSupply();
    if (poolTotalLiquidityShares == 0) {
      return 0;
    }
    return _shareAmount.mul(getTotalLiquidity(_token)).div(poolTotalLiquidityShares);
  }

  /**
   * @dev calculate borrow amount (round-up)
   * @param _token the ERC20 token of the pool
   * @param _shareAmount the borrow shares to calculate the amount of borrow
   * @return the amount of borrowing which is calculated from the below formula
   * borrowing amount = ((share amount * total borrows) + (total borrow shares - 1)) / total borrow shares
   * if the calculated borrowing amount = 10.1 then the borrowing amount = 11
   */
  function calculateRoundUpBorrowAmount(ERC20 _token, uint256 _shareAmount)
    internal
    view
    returns (uint256)
  {
    Pool storage pool = pools[address(_token)];
    if (pool.totalBorrows == 0 || pool.totalBorrowShares == 0) {
      return _shareAmount;
    }
    return _shareAmount.mul(pool.totalBorrows).divCeil(pool.totalBorrowShares);
  }

  /**
   * @dev check is the user account is still healthy
   * Traverse a token list to visit all ERC20 token pools then accumulate 3 balance values of the user:
   * -----------------------------
   * 1. user's total liquidity balance. Accumulate the user's liquidity balance of all ERC20 token pools
   * 2. user's total borrow balance. Accumulate the user's borrow balance of all ERC20 token pools
   * 3. user's total collateral balance. each ERC20 token has the different max loan-to-value (collateral percent) or the percent of
   * liquidity that can actually use as collateral for the borrowing.
   * e.g. if B token has 75% collateral percent means the collateral balance is 75 if the user's has 100 B token balance
   * -----------------------------
   * the account is still healthy if total borrow value is less than total collateral value. This means the user's collateral
   * still cover the user's loan. In case of total borrow value is more than total collateral value then user's account is not healthy.
   * @param _user the address of the user that will check the account health status
   * @return the boolean that represent the account health status. Returns true if account is still healthy, false if account is not healthy.
   */
  function isAccountHealthy(address _user) public override view returns (bool) {
    (, uint256 totalCollateralBalanceBase, uint256 totalBorrowBalanceBase) = getUserAccount(_user);

    return totalBorrowBalanceBase <= totalCollateralBalanceBase;
  }

  /**
   * @dev get user account details
   * @param _user the address of the user to get the account details
   * return totalLiquidityBalanceBase - the value of user's total liquidity,
   * totalCollateralBalanceBase - the value of user's total collateral,
   * totalBorrowBalanceBase - the value of user's total borrow
   */
  function getUserAccount(address _user)
    public
    view
    returns (
      uint256 totalLiquidityBalanceBase,
      uint256 totalCollateralBalanceBase,
      uint256 totalBorrowBalanceBase
    )
  {
    for (uint256 i = 0; i < tokenList.length; i++) {
      ERC20 _token = tokenList[i];
      Pool storage pool = pools[address(_token)];

      // get user pool data
      (
        uint256 compoundedLiquidityBalance,
        uint256 compoundedBorrowBalance,
        bool userUsePoolAsCollateral
      ) = getUserPoolData(_user, _token);

      if (compoundedLiquidityBalance != 0 || compoundedBorrowBalance != 0) {
        uint256 collateralPercent = pool.poolConfig.getCollateralPercent();
        uint256 poolPricePerUnit = priceOracle.getAssetPrice(address(_token));
        require(poolPricePerUnit > 0, "token price isn't correct");

        uint256 liquidityBalanceBase = poolPricePerUnit.wadMul(compoundedLiquidityBalance);
        totalLiquidityBalanceBase = totalLiquidityBalanceBase.add(liquidityBalanceBase);
        // this pool can use as collateral when collateralPercent more than 0.
        if (collateralPercent > 0 && userUsePoolAsCollateral) {
          totalCollateralBalanceBase = totalCollateralBalanceBase.add(
            liquidityBalanceBase.wadMul(collateralPercent)
          );
        }
        totalBorrowBalanceBase = totalBorrowBalanceBase.add(
          poolPricePerUnit.wadMul(compoundedBorrowBalance)
        );
      }
    }
  }

  function totalBorrowInUSD(ERC20 _token) public view returns (uint256) {
    require(address(priceOracle) != address(0), "price oracle isn't initialized");
    uint256 tokenPricePerUnit = priceOracle.getAssetPrice(address(_token));
    require(tokenPricePerUnit > 0, "token price isn't correct");
    return tokenPricePerUnit.mul(pools[address(_token)].totalBorrows);
  }

  /**
   * @dev deposit the ERC20 token to the pool
   * @param _token the ERC20 token of the pool that user want to deposit
   * @param _amount the deposit amount
   * User can call this function to deposit their ERC20 token to the pool. user will receive the alToken of that ERC20 token
   * which represent the liquidity shares of the user. Providing the liquidity will receive an interest from the the borrower as an incentive.
   * e.g. Alice deposits 10 Hello tokens to the pool.
   * if 1 Hello token shares equals to 2 Hello tokens then Alice will have 5 Hello token shares from 10 Hello tokens depositing.
   * User will receive the liquidity shares in the form of alToken so Alice will have 5 alHello on her wallet
   * for representing her shares.
   */
  function deposit(ERC20 _token, uint256 _amount)
    external
    nonReentrant
    updatePoolWithInterestsAndTimestamp(_token)
    updateAlphaReward
  {
    Pool storage pool = pools[address(_token)];
    require(pool.status == PoolStatus.ACTIVE, "can't deposit to this pool");
    require(_amount > 0, "deposit amount should more than 0");

    // 1. calculate liquidity share amount
    uint256 shareAmount = calculateRoundDownLiquidityShareAmount(_token, _amount);

    // 2. mint alToken to user equal to liquidity share amount
    pool.alToken.mint(msg.sender, shareAmount);

    // 3. transfer user deposit liquidity to the pool
    _token.safeTransferFrom(msg.sender, address(this), _amount);

    emit Deposit(address(_token), msg.sender, shareAmount, _amount);
  }

  /**
   * @dev borrow the ERC20 token from the pool
   * @param _token the ERC20 token of the pool that user want to borrow
   * @param _amount the borrow amount
   * User can call this function to borrow the ERC20 token from the pool. This function will
   * convert the borrow amount to the borrow shares then accumulate borrow shares of this user
   * of this ERC20 pool then set to user data on that pool state.
   * e.g. Bob borrows 10 Hello tokens from the Hello token pool.
   * if 1 borrow shares of Hello token equals to 5 Hello tokens then the lending contract will
   * set Bob's borrow shares state with 2 borrow shares. Bob will receive 10 Hello tokens.
   */
  function borrow(ERC20 _token, uint256 _amount)
    external
    nonReentrant
    updatePoolWithInterestsAndTimestamp(_token)
    updateAlphaReward
  {
    Pool storage pool = pools[address(_token)];
    UserPoolData storage userData = userPoolData[msg.sender][address(_token)];
    require(pool.status == PoolStatus.ACTIVE, "can't borrow this pool");
    require(_amount > 0, "borrow amount should more than 0");
    require(
      _amount <= getTotalAvailableLiquidity(_token),
      "amount is more than available liquidity on pool"
    );

    // 0. Claim alpha token from latest borrow
    claimCurrentAlphaReward(_token, msg.sender);

    // 1. calculate borrow share amount
    uint256 borrowShare = calculateRoundUpBorrowShareAmount(_token, _amount);

    // 2. update pool state
    pool.totalBorrows = pool.totalBorrows.add(_amount);
    pool.totalBorrowShares = pool.totalBorrowShares.add(borrowShare);

    // 3. update user state
    userData.borrowShares = userData.borrowShares.add(borrowShare);

    // 4. transfer borrowed token from pool to user
    _token.safeTransfer(msg.sender, _amount);

    // 5. check account health. this transaction will revert if the account of this user is not healthy
    require(isAccountHealthy(msg.sender), "account is not healthy. can't borrow");
    emit Borrow(address(_token), msg.sender, borrowShare, _amount);
  }

  /**
   * @dev repay the ERC20 token to the pool equal to repay amount
   * @param _token the ERC20 token of the pool that user want to repay
   * @param _amount the repay amount
   * User can call this function to repay the ERC20 token to the pool. For user's convenience,
   * this function will convert repay amount to repay shares then do the repay.
   */
  function repayByAmount(ERC20 _token, uint256 _amount)
    external
    nonReentrant
    updatePoolWithInterestsAndTimestamp(_token)
    updateAlphaReward
  {
    // calculate round down borrow share
    uint256 repayShare = calculateRoundDownBorrowShareAmount(_token, _amount);
    repayInternal(_token, repayShare);
  }

  /**
   * @dev repay the ERC20 token to the pool equal to repay shares
   * @param _token the ERC20 token of the pool that user want to repay
   * @param _share the amount of borrow shares thet user want to repay
   * User can call this function to repay the ERC20 token to the pool.
   * This function will do the repay equal to repay shares
   */
  function repayByShare(ERC20 _token, uint256 _share)
    external
    nonReentrant
    updatePoolWithInterestsAndTimestamp(_token)
    updateAlphaReward
  {
    repayInternal(_token, _share);
  }

  /**
   * @dev repay the ERC20 token to the pool equal to repay shares
   * @param _token the ERC20 token of the pool that user want to repay
   * @param _share the amount of borrow shares thet user want to repay
   * Internal function that do the repay. If Alice want to repay 10 borrow shares then the repay shares is 10.
   * this function will repay the ERC20 token of Alice equal to repay shares value to the pool.
   * If 1 repay shares equal to 2 Hello tokens then Alice will repay 20 Hello tokens to the pool. the Alice's
   * borrow shares will be decreased.
   */
  function repayInternal(ERC20 _token, uint256 _share) internal {
    Pool storage pool = pools[address(_token)];
    UserPoolData storage userData = userPoolData[msg.sender][address(_token)];
    require(
      pool.status == PoolStatus.ACTIVE || pool.status == PoolStatus.CLOSED,
      "can't repay to this pool"
    );
    uint256 paybackShares = _share;
    if (paybackShares > userData.borrowShares) {
      paybackShares = userData.borrowShares;
    }

    // 0. Claim alpha token from latest borrow
    claimCurrentAlphaReward(_token, msg.sender);

    // 1. calculate round up payback token
    uint256 paybackAmount = calculateRoundUpBorrowAmount(_token, paybackShares);

    // 2. update pool state
    pool.totalBorrows = pool.totalBorrows.sub(paybackAmount);
    pool.totalBorrowShares = pool.totalBorrowShares.sub(paybackShares);

    // 3. update user state
    userData.borrowShares = userData.borrowShares.sub(paybackShares);

    // 4. transfer payback tokens to the pool
    _token.safeTransferFrom(msg.sender, address(this), paybackAmount);
    emit Repay(address(_token), msg.sender, paybackShares, paybackAmount);
  }

  /**
   * @dev withdraw the ERC20 token from the pool
   * @param _token the ERC20 token of the pool that user want to withdraw
   * @param _share the alToken amount that user want to withdraw
   * When user withdraw their liquidity shares or alToken, they will receive the ERC20 token from the pool
   * equal to the alHello value.
   * e.g. Bob want to withdraw 10 alHello. If 1 alHello equal to 10 Hello tokens then Bob will receive
   * 100 Hello tokens after withdraw. Bob's alHello will be burned.
   * Note: Bob cannot withdraw his alHello if his account is not healthy which means he uses all of his liquidity as
   * collateral to cover his loan so he cannot withdraw or transfer his alHello.
   */
  function withdraw(ERC20 _token, uint256 _share)
    external
    nonReentrant
    updatePoolWithInterestsAndTimestamp(_token)
    updateAlphaReward
  {
    Pool storage pool = pools[address(_token)];
    uint256 alBalance = pool.alToken.balanceOf(msg.sender);
    require(
      pool.status == PoolStatus.ACTIVE || pool.status == PoolStatus.CLOSED,
      "can't withdraw this pool"
    );
    uint256 withdrawShares = _share;
    if (withdrawShares > alBalance) {
      withdrawShares = alBalance;
    }

    // 1. calculate liquidity amount from shares
    uint256 withdrawAmount = calculateRoundDownLiquidityAmount(_token, withdrawShares);

    // 2. burn al tokens of user equal to shares
    pool.alToken.burn(msg.sender, withdrawShares);

    // 3. transfer ERC20 tokens to user account
    _token.transfer(msg.sender, withdrawAmount);

    // 4. check account health. this transaction will revert if the account of this user is not healthy
    require(isAccountHealthy(msg.sender), "account is not healthy. can't withdraw");
    emit Withdraw(address(_token), msg.sender, withdrawShares, withdrawAmount);
  }

  /**
   * @dev liquidate the unhealthy user account
   * @param _user the address of the user that liquidator want to liquidate
   * @param _token the token that liquidator whan to liquidate
   * @param _liquidateShares the amount of token shares that liquidator want to liquidate
   * @param _collateral the ERC20 token of the pool that liquidator will receive as a reward
   * If the user's account health is not healthy, anothor user can become to the liquidator to liquidate
   * the user account then got the collateral as a reward.
   */
  function liquidate(
    address _user,
    ERC20 _token,
    uint256 _liquidateShares,
    ERC20 _collateral
  )
    external
    nonReentrant
    updatePoolWithInterestsAndTimestamp(_token)
    updatePoolWithInterestsAndTimestamp(_collateral)
    updateAlphaReward
  {
    liquidateInternal(_user, _token, _liquidateShares, _collateral);
  }

  /**
   * @dev liquidate the unhealthy user account (internal)
   * @param _user the address of the user that liquidator want to liquidate
   * @param _token the token that liquidator whan to liquidate
   * @param _liquidateShares the amount of token shares that liquidator want to liquidate
   * @param _collateral the ERC20 token of the pool that liquidator will receive as a reward
   * e.g. Alice account is not healthy. Bob saw Alice account then want to liquidate 10 Hello borrow shares of Alice account
   * and want to get the Seeyou tokens as the collateral. The steps that will happen is below:
   * 1. Bob calls the liquidate function with _user is Alice address, _token is Hello token,
   * _liquidateShare is 10, _collateral is Seeyou token to liquidate Alice account.
   * 2. Contract check if Alice account is in an unhealthy state or not. If Alice account is
   * still healthy, Bob cannot liquidate this account then this transaction will be revert.
   * 3. Contract check if the collateral that Bob has requested enable for the liquidation reward both on
   * pool enabling and Alice enabling.
   * 4. Bob can liquidate Alice account if Alice has been borrowing Hello tokens from the pool.
   * 5. Bob can liquidate from 0 to the max liquidate shares which equal to 50% of Alice's Hello borrow share.
   * 6. Contract calculates the amount of collateral that Bob will receive as the rewards to convert to
   * the amount of Seeyou shares. Seeyou shares is the alSeeyou token.
   * 7. Bob pays Hello tokens equal to 10 Hello shares. If 1 Hello shares equal to 10 Hello tokens then Bob will
   * pay 100 Hello token to the pool
   * 8. The borrowing shares of the Hello token on Alice account will be decreased. The alSeeyou of Alice will be burned.
   * 9. Bob will get 105 alSeeyou tokens.
   * 10. Bob can withdraw the alHello tokens later to get the Hello tokens from the pool.
   * Note: Hello and Seeyou are the imaginary ERC20 token.
   */
  function liquidateInternal(
    address _user,
    ERC20 _token,
    uint256 _liquidateShares,
    ERC20 _collateral
  ) internal {
    Pool storage pool = pools[address(_token)];
    Pool storage collateralPool = pools[address(_collateral)];
    UserPoolData storage userCollateralData = userPoolData[_user][address(_collateral)];
    UserPoolData storage userTokenData = userPoolData[_user][address(_token)];
    require(
      pool.status == PoolStatus.ACTIVE || pool.status == PoolStatus.CLOSED,
      "can't liquidate this pool"
    );

    // 0. Claim alpha token from latest user borrow
    claimCurrentAlphaReward(_token, _user);

    // 1. check account health of user to make sure that liquidator can liquidate this account
    require(!isAccountHealthy(_user), "user's account is healthy. can't liquidate this account");

    // 2. check if the user enables collateral
    require(
      !userCollateralData.disableUseAsCollateral,
      "user didn't enable the requested collateral"
    );

    // 3. check if the token pool enable to use as collateral
    require(
      collateralPool.poolConfig.getCollateralPercent() > 0,
      "this pool isn't used as collateral"
    );

    // 4. check if the user has borrowed tokens that liquidator want to liquidate
    require(userTokenData.borrowShares > 0, "user didn't borrow this token");

    // 5. calculate liquidate amount and shares
    uint256 maxPurchaseShares = userTokenData.borrowShares.wadMul(CLOSE_FACTOR);
    uint256 liquidateShares = _liquidateShares;
    if (liquidateShares > maxPurchaseShares) {
      liquidateShares = maxPurchaseShares;
    }
    uint256 liquidateAmount = calculateRoundUpBorrowAmount(_token, liquidateShares);

    // 6. calculate collateral amount and shares
    uint256 collateralAmount = calculateCollateralAmount(_token, liquidateAmount, _collateral);
    uint256 collateralShares = calculateRoundUpLiquidityShareAmount(_collateral, collateralAmount);

    // 7. transfer liquidate amount to the pool
    _token.safeTransferFrom(msg.sender, address(this), liquidateAmount);

    // 8. burn al token of user equal to collateral shares
    require(
      collateralPool.alToken.balanceOf(_user) > collateralShares,
      "user collateral isn't enough"
    );
    collateralPool.alToken.burn(_user, collateralShares);

    // 9. mint al token equal to collateral shares to liquidator
    collateralPool.alToken.mint(msg.sender, collateralShares);

    // 10. update pool state
    pool.totalBorrows = pool.totalBorrows.sub(liquidateAmount);
    pool.totalBorrowShares = pool.totalBorrowShares.sub(liquidateShares);

    // 11. update user state
    userTokenData.borrowShares = userTokenData.borrowShares.sub(liquidateShares);

    emit Liquidate(
      _user,
      address(_token),
      address(_collateral),
      liquidateAmount,
      liquidateShares,
      collateralAmount,
      collateralShares,
      msg.sender
    );
  }

  /**
   * @dev calculate collateral amount that the liquidator will receive after the liquidation
   * @param _token the token that liquidator whan to liquidate
   * @param _liquidateAmount the amount of token that liquidator want to liquidate
   * @param _collateral the ERC20 token of the pool that liquidator will receive as a reward
   * @return the collateral amount of the liquidation
   * This function will be call on liquidate function to calculate the collateral amount that
   * liquidator will get after the liquidation. Liquidation bonus is expressed in percent. the collateral amount
   * depends on each pool. If the Hello pool has liquidation bonus equal to 105% then the collateral value is
   * more than the value of liquidated tokens around 5%. the formula is below:
   * collateral amount = (token price * liquidate amount * liquidation bonus percent) / collateral price
   */
  function calculateCollateralAmount(
    ERC20 _token,
    uint256 _liquidateAmount,
    ERC20 _collateral
  ) internal view returns (uint256) {
    require(address(priceOracle) != address(0), "price oracle isn't initialized");
    uint256 tokenPricePerUnit = priceOracle.getAssetPrice(address(_token));
    require(tokenPricePerUnit > 0, "liquidated token price isn't correct");
    uint256 collateralPricePerUnit = priceOracle.getAssetPrice(address(_collateral));
    require(collateralPricePerUnit > 0, "collateral price isn't correct");
    uint256 liquidationBonus = pools[address(_token)].poolConfig.getLiquidationBonusPercent();
    return (
      tokenPricePerUnit.mul(_liquidateAmount).wadMul(liquidationBonus).div(collateralPricePerUnit)
    );
  }

  /**
   * @dev set reserve percent for admin
   * @param _reservePercent the percent of pool reserve
   */
  function setReservePercent(uint256 _reservePercent) external onlyOwner {
    uint256 previousReservePercent = reservePercent;
    reservePercent = _reservePercent;
    emit ReservePercentUpdated(previousReservePercent, reservePercent);
  }

  /**
   * @dev withdraw function for admin to get the reserves
   * @param _token the ERC20 token of the pool to withdraw
   * @param _amount amount to withdraw
   */
  function withdrawReserve(ERC20 _token, uint256 _amount)
    external
    nonReentrant
    updatePoolWithInterestsAndTimestamp(_token)
    onlyOwner
  {
    Pool storage pool = pools[address(_token)];
    uint256 poolBalance = _token.balanceOf(address(this));
    require(_amount <= poolBalance, "pool balance insufficient");
    // admin can't withdraw more than pool's reserve
    require(_amount <= pool.poolReserves, "amount is more than pool reserves");
    _token.safeTransfer(msg.sender, _amount);
    pool.poolReserves = pool.poolReserves.sub(_amount);
    emit ReserveWithdrawn(address(_token), _amount, msg.sender);
  }

  // ================== 💸💸💸 Distribute AlphaToken 💸💸💸 ========================

  /**
    @dev set distributor address
   */
  function setDistributor(IAlphaDistributor _distributor) public onlyOwner {
    distributor = _distributor;
  }

  /**
    @dev set vesting alpha address
   */
  function setVestingAlpha(IVestingAlpha _vestingAlpha) public onlyOwner {
    vestingAlpha = _vestingAlpha;
  }

  /**
   * @dev implement function of IAlphaReceiver interface to
   * receive Alpha token rewards from the distributor
   * @param _amount the amount of Alpha token to receive
   */
  function receiveAlpha(uint256 _amount) external override {
    require(msg.sender == address(distributor), "Only distributor can call receive Alpha");
    // Calculate total borrow value.
    uint256[] memory borrows = new uint256[](tokenList.length);
    uint256 totalBorrow = 0;

    for (uint256 i = 0; i < tokenList.length; i++) {
      if (pools[address(tokenList[i])].status == PoolStatus.ACTIVE) {
        borrows[i] = totalBorrowInUSD(tokenList[i]);
        totalBorrow = totalBorrow.add(borrows[i]);
      }
    }
    // This contract should not receive alpha token if no borrow value lock in.
    if (totalBorrow == 0) {
      return;
    }
    distributor.alphaToken().transferFrom(msg.sender, address(this), _amount);
    for (uint256 i = 0; i < borrows.length; i++) {
      Pool storage pool = pools[address(tokenList[i])];
      if (pool.status == PoolStatus.ACTIVE) {
        uint256 portion = _amount.mul(borrows[i]).div(totalBorrow);
        (uint256 lendersGain, uint256 borrowersGain) = splitReward(tokenList[i], portion);
        // Distribute the Alpha token to the lenders (AlToken holder)
        distributor.alphaToken().approve(address(pool.alToken), lendersGain);
        pool.alToken.receiveAlpha(lendersGain);

        // Distribute the Alpha token to the borrowers
        updateBorrowAlphaReward(pool, borrowersGain);
      }
    }
  }

  /**
   * @dev claim Alpha token rewards from all ERC20 token pools and create receipt for caller
   */
  function claimAlpha() external updateAlphaReward nonReentrant {
    for (uint256 i = 0; i < tokenList.length; i++) {
      Pool storage pool = pools[address(tokenList[i])];

      // claim Alpha rewards as a lender
      pool.alToken.claimCurrentAlphaRewardByOwner(msg.sender);

      // claim Alpha reward as a borrower
      claimCurrentAlphaReward(tokenList[i], msg.sender);
    }
  }

  /**
   * @dev update Alpha rewards for the borrower of the ERC20 pool
   * @param _pool the ERC20 token pool to update the Alpha rewards
   * @param _amount the total amount of the rewards to all borrowers of the pool
   */
  function updateBorrowAlphaReward(Pool storage _pool, uint256 _amount) internal {
    _pool.totalAlphaTokenReward = _pool.totalAlphaTokenReward.add(_amount);
    if (_pool.totalBorrowShares == 0) {
      return;
    }
    _pool.alphaMultiplier = _pool.alphaMultiplier.add(
      _amount.mul(1e12).div(_pool.totalBorrowShares)
    );
  }

  /**
   * @dev split the Alpha rewards between the lenders and borrowers
   * @param _token the ERC20 token pool
   * @param _amount the amount of Alpha token rewards to split
   * @return lendersGain - the rewards's lenders gain
   * borrowersGain - the rewards's borrower gain
   */
  function splitReward(ERC20 _token, uint256 _amount)
    internal
    view
    returns (uint256 lendersGain, uint256 borrowersGain)
  {
    Pool storage pool = pools[address(_token)];
    uint256 utilizationRate = pool.poolConfig.getUtilizationRate(
      pool.totalBorrows,
      getTotalLiquidity(_token)
    );
    uint256 optimal = pool.poolConfig.getOptimalUtilizationRate();
    if (utilizationRate <= optimal) {
      // lenders gain = amount * ((EQUILIBRIUM / OPTIMAL) * utilization rate)
      lendersGain = (optimal == 0)
        ? 0
        : _amount.wadMul(EQUILIBRIUM).wadMul(utilizationRate).wadDiv(optimal);
    } else {
      // lenders gain = amount * ((EQUILIBRIUM * (utilization rate - OPTIMAL)) / (MAX_UTILIZATION_RATE - OPTIMAL)) + EQUILIBRIUM)
      lendersGain = (utilizationRate >= MAX_UTILIZATION_RATE)
        ? _amount
        : _amount.wadMul(
          EQUILIBRIUM
            .wadMul(utilizationRate.sub(optimal))
            .wadDiv(MAX_UTILIZATION_RATE.sub(optimal))
            .add(EQUILIBRIUM)
        );
    }
    // borrowers gain = amount - lenders gain
    borrowersGain = _amount.sub(lendersGain);
  }

  function calculateAlphaReward(ERC20 _token, address _account) public view returns (uint256) {
    Pool storage pool = pools[address(_token)];
    UserPoolData storage userData = userPoolData[_account][address(_token)];
    //               reward start block                                        now
    // Global                |----------------|----------------|----------------|
    // User's latest reward  |----------------|----------------|
    // User's Alpha rewards                                    |----------------|
    // reward = [(Global Alpha multiplier - user's lastest Alpha multiplier) * user's Alpha token] / 1e12
    uint256 pending = pool
      .alphaMultiplier
      .sub(userData.latestAlphaMultiplier)
      .mul(userData.borrowShares)
      .div(1e12);
    return pending < pool.totalAlphaTokenReward ? pending : pool.totalAlphaTokenReward;
  }

  /**
   * @dev claim Alpha tokens rewards
   * @param _token the ERC20 pool
   * @param _account the user account that will claim the Alpha tokens
   */
  function claimCurrentAlphaReward(ERC20 _token, address _account) internal {
    // No op if alpha distributor didn't be set in lending pool.
    if (address(distributor) == address(0)) {
      return;
    }
    Pool storage pool = pools[address(_token)];
    UserPoolData storage userData = userPoolData[_account][address(_token)];
    uint256 reward = calculateAlphaReward(_token, _account);
    pool.totalAlphaTokenReward = pool.totalAlphaTokenReward.sub(reward);
    userData.latestAlphaMultiplier = pool.alphaMultiplier;
    sendAlphaReward(_account, reward);
  }

  /**
   * @dev send Alpha tokens to the recipient
   * @param _recipient the recipient of the Alpha reward
   * @param _amount the Alpha reward amount to send
   */
  function sendAlphaReward(address _recipient, uint256 _amount) internal {
    if (address(vestingAlpha) == address(0)) {
      distributor.alphaToken().transfer(_recipient, _amount);
    } else {
      distributor.alphaToken().approve(address(vestingAlpha), _amount);
      vestingAlpha.accumulateAlphaToUser(_recipient, _amount);
    }
  }
}

pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title WadMath library
 * @notice The wad math library.
 * @author Alpha
 **/

library WadMath {
  using SafeMath for uint256;

  /**
   * @dev one WAD is equals to 10^18
   */
  uint256 internal constant WAD = 1e18;

  /**
   * @notice get wad
   */
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @notice a multiply by b in Wad unit
   * @return the result of multiplication
   */
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(b).div(WAD);
  }

  /**
   * @notice a divided by b in Wad unit
   * @return the result of division
   */
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(WAD).div(b);
  }
}

pragma solidity 0.6.11;

/**
 * @title Math library
 * @notice The math library.
 * @author Alpha
 **/

 library Math {
  
   /** 
    * @notice a ceiling division
    * @return the ceiling result of division
    */
   function divCeil(uint256 a, uint256 b) internal pure returns(uint256) {
     require(b > 0, "divider must more than 0");
     uint256 c = a / b;
     if (a % b != 0) {
       c = c + 1;
     }
     return c;
   }
 }

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.11;

/**
 * @title Alpha vesting interface
 * @notice The interface for the alpha vesting contract.
 * @author Alpha
 */

interface IVestingAlpha {

  /**
   * @dev accumulate Alpha token to user
   * @param _user the user account address
   * @param _amount the amount of Alpha token to accumulate
   */
  function accumulateAlphaToUser(address _user, uint256 _amount) external;
}

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 * @title Price oracle interface
 * @notice The interface for the price oracle contract.
 * @author Alpha
 **/

interface IPriceOracle {
  /**
   * @notice Returns the latest price of an asset given the asset's address
   * @param _asset the address of asset to get the price (price per unit with 9 decimals)
   * @return price per unit
   **/
  function getAssetPrice(address _asset) external view returns (uint256);
}

pragma solidity 0.6.11;

/**
 * @title Pool configuration interface
 * @notice The interface of pool configuration of the ERC20 token pool
 * @author Alpha
 **/

interface IPoolConfiguration {
  /**
   * @notice get optimal utilization rate of the ERC20 token pool
   * @return the optimal utilization
   */
  function getOptimalUtilizationRate() external view returns (uint256);

  /**
   * @notice get base borrow rate of the ERC20 token pool
   * @return the base borrow rate
   */
  function getBaseBorrowRate() external view returns (uint256);

  /**
   * @notice get the liquidation bonus percent to calculate the collateral amount of liquidation
   * @return the liquidation bonus percent
   */
  function getLiquidationBonusPercent() external view returns (uint256);

  /**
   * @notice get the collateral percent which is the percent that the liquidity can use as collateral
   * @return the collateral percent
   */
  function getCollateralPercent() external view returns (uint256);

  /**
   * @notice calculate the annual interest rate
   * @param _totalBorrows the total borrows of the ERC20 token pool
   * @param _totalLiquidity the total liquidity of the ERC20 token of the pool
   * @return borrowInterestRate an annual borrow interest rate
   */
  function calculateInterestRate(uint256 _totalBorrows, uint256 _totalLiquidity)
    external
    view
    returns (uint256 borrowInterestRate);

  /**
   * @notice calculate the utilization rate
   * @param _totalBorrows the total borrows of the ERC20 token pool
   * @param _totalLiquidity the total liquidity of the ERC20 token of the pool
   * @return utilizationRate the utilization rate of the ERC20 pool
   */
  function getUtilizationRate(uint256 _totalBorrows, uint256 _totalLiquidity)
    external
    view
    returns (uint256 utilizationRate);
}

pragma solidity 0.6.11;

import "./IAlphaDistributor.sol";
import "./IVestingAlpha.sol";

/**
 * @title ILendingPool interface
 * @notice The interface for the lending pool contract.
 * @author Alpha
 **/

interface ILendingPool {
  /**
   * @notice Returns the health status of account.
   **/
  function isAccountHealthy(address _account) external view returns (bool);

  /**
   * @notice Returns the Alpha distributor.
   **/
  function distributor() external view returns (IAlphaDistributor);

  /**
   * @notice Returns the Vesting Alpha constract
   **/
  function vestingAlpha() external view returns (IVestingAlpha);
}

pragma solidity 0.6.11;

/**
 * @title Alpha receiver interface
 * @notice The interface of Alpha token reward receiver
 * @author Alpha
 **/

interface IAlphaReceiver {
  /**
   * @notice receive Alpha token from the distributor
   * @param _amount the amount of Alpha token to receive
   */
  function receiveAlpha(uint256 _amount) external;
}

pragma solidity 0.6.11;

import {AlphaToken} from "../distribution/AlphaToken.sol";

/**
 * @title Alpha distributor interface
 * @notice The interface of Alpha distributor for Alpha token rewards
 * @author Alpha
 **/

interface IAlphaDistributor {
  /**
   * @notice get the Alpha token of the distributor
   * @return AlphaToken - the Alpha token
   */
  function alphaToken() external view returns (AlphaToken);

  /**
   * @notice distribute the Alpha token to the receivers
   */
  function poke() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Alpha token contract
 * @notice Implements Alpha token contracts
 * @author Alpha
 */

contract AlphaToken is ERC20("AlphaToken", "ALPHA"), Ownable {
  function mint(address _to, uint256 _value) public onlyOwner {
    _mint(_to, _value);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ILendingPool.sol";
import "./AlToken.sol";

/**
 * @title Alpha token deployer
 * @notice Implements Alpha token deployer
 * @author Alpha
 */

contract AlTokenDeployer {
  /**
   * @dev deploy AlToken for the lending pool
   * @param _name the name of AlToken
   * @param _symbol the token symbol of AlToken
   * @param _underlyingAsset the underlying ERC20 token of the AlToken
   */
  function createNewAlToken(
    string memory _name,
    string memory _symbol,
    ERC20 _underlyingAsset
  ) public returns (AlToken) {
    AlToken alToken = new AlToken(_name, _symbol, ILendingPool(msg.sender), _underlyingAsset);
    alToken.transferOwnership(msg.sender);
    return alToken;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAlphaReceiver.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IVestingAlpha.sol";

/**
 * @title alToken contract
 * @notice Implements the altoken of the ERC20 token.
 * The alToken represent the liquidity shares of the holder on the ERC20 lending pool.
 * @author Alpha
 **/

contract AlToken is ERC20, Ownable, IAlphaReceiver, ReentrancyGuard {
  /**
   * @dev the lending pool of the AlToken
   */
  ILendingPool private lendingPool;

  /**
   * @dev the underlying ERC20 token of the AlToken
   */
  ERC20 public underlyingAsset;

  /**
   * @dev the alpha reward multiplier to calculate Alpha token rewards for the AlToken holder.
   */
  uint256 public alphaMultiplier;

  /**
   * @dev the latest reward of user after latest user activity.
   * Global alphaMultiplier |-----------------|-----------------|---------------|
   *                                                                     alphaMultiplier
   * User's latest reward   |-----------------|-----------------|
   *                        start                         last block that user do any activity (received rewards)
                                                          user's latestAlphaMultiplier
   *
   * user address => latest rewards
   */
  mapping(address => uint256) latestAlphaMultiplier;

  constructor(
    string memory _name,
    string memory _symbol,
    ILendingPool _lendingPoolAddress,
    ERC20 _underlyingAsset
  ) public ERC20(_name, _symbol) {
    lendingPool = _lendingPoolAddress;
    underlyingAsset = _underlyingAsset;
  }

  /**
   * @dev mint alToken to the address equal to amount
   * @param _account the account address of receiver
   * @param _amount the amount of alToken to mint
   * Only lending pool can mint alToken
   */
  function mint(address _account, uint256 _amount) external onlyOwner {
    claimCurrentAlphaReward(_account);
    _mint(_account, _amount);
  }

  /**
   * @dev burn alToken of the address equal to amount
   * @param _account the account address that will burn the token
   * @param _amount the amount of alToken to burn
   * Only lending pool can burn alToken
   */
  function burn(address _account, uint256 _amount) external onlyOwner {
    claimCurrentAlphaReward(_account);
    _burn(_account, _amount);
  }

  /**
   * @dev receive Alpha token from the token distributor
   * @param _amount the amount of Alpha to receive
   */
  function receiveAlpha(uint256 _amount) external override {
    require(msg.sender == address(lendingPool), "Only lending pool can call receive Alpha");
    lendingPool.distributor().alphaToken().transferFrom(msg.sender, address(this), _amount);
    // Don't change alphaMultiplier if total supply equal zero.
    if (totalSupply() == 0) {
      return;
    }
    alphaMultiplier = alphaMultiplier.add(_amount.mul(1e12).div(totalSupply()));
  }

  /**
   * @dev calculate Alpha reward of the user
   * @param _account the user account address
   * @return the amount of Alpha rewards
   */
  function calculateAlphaReward(address _account) public view returns (uint256) {
    //               reward start block                                        now
    // Global                |----------------|----------------|----------------|
    // User's latest reward  |----------------|----------------|
    // User's Alpha rewards                                    |----------------|
    // reward = [(Global Alpha multiplier - user's lastest Alpha multiplier) * user's Alpha token] / 1e12
    return
      (alphaMultiplier.sub(latestAlphaMultiplier[_account]).mul(balanceOf(_account))).div(1e12);
  }

  /**
   * @dev claim user's pending Alpha rewards by owner
   * @param _account the user account address
   */
  function claimCurrentAlphaRewardByOwner(address _account) external onlyOwner {
    claimCurrentAlphaReward(_account);
  }

  /**
   * @dev claim the pending Alpha rewards from the latest rewards giving to now
   * @param _account the user account address
   */
  function claimCurrentAlphaReward(address _account) internal {
    // No op if alpha distributor didn't be set in lending pool.
    if (address(lendingPool.distributor()) == address(0)) {
      return;
    }
    uint256 pending = calculateAlphaReward(_account);
    uint256 alphaBalance = lendingPool.distributor().alphaToken().balanceOf(address(this));
    pending = pending < alphaBalance ? pending : alphaBalance;
    if (address(lendingPool.vestingAlpha()) == address(0)) {
      lendingPool.distributor().alphaToken().transfer(_account, pending);
    } else {
      IVestingAlpha vestingAlpha = lendingPool.vestingAlpha();
      lendingPool.distributor().alphaToken().approve(address(vestingAlpha), pending);
      vestingAlpha.accumulateAlphaToUser(_account, pending);
    }
    latestAlphaMultiplier[_account] = alphaMultiplier;
  }

  /**
   * @dev  transfer alToken to another account
   * @param _from the sender account address
   * @param _to the receiver account address
   * @param _amount the amount of alToken to burn
   * Lending pool will check the account health of the sender. If the sender transfer alTokens to
   * the receiver then the sender account is not healthy, the transfer transaction will be revert.
   * Also claim the user Alpha rewards and set the new user's latest reward
   */
  function _transfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override {
    claimCurrentAlphaReward(_from);
    claimCurrentAlphaReward(_to);
    super._transfer(_from, _to, _amount);
    require(lendingPool.isAccountHealthy(_from), "Transfer tokens is not allowed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

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

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}