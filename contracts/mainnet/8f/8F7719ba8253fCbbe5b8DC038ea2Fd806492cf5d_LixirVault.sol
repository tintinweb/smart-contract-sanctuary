pragma solidity ^0.7.6;
pragma abicoder v2;

import "./LixirVaultDeps.sol";


contract LixirVault is
  ILixirVault,
  LixirVaultToken,
  LixirBase,
  IUniswapV3MintCallback
{
  using LowGasSafeMath for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeCast for uint128;

  IERC20 public override token0;
  IERC20 public override token1;

  uint24 public override activeFee;
  IUniswapV3Pool public override activePool;

  address public override strategy;
  address public override strategist;
  address public override keeper;

  Position public override mainPosition;
  Position public override rangePosition;

  uint24 public override performanceFee;

  uint24 immutable PERFORMANCE_FEE_PRECISION;

  address immutable uniV3Factory;

  event Deposit(
    address indexed depositor,
    address indexed recipient,
    uint256 shares,
    uint256 amount0In,
    uint256 amount1In,
    uint256 total0,
    uint256 total1
  );

  event Withdraw(
    address indexed withdrawer,
    address indexed recipient,
    uint256 shares,
    uint256 amount0Out,
    uint256 amount1Out
  );

  event Rebalance(
    int24 mainTickLower,
    int24 mainTickUpper,
    int24 rangeTickLower,
    int24 rangeTickUpper,
    uint24 newFee,
    uint256 total0,
    uint256 total1,
    FeeData feeData
  );

  event PerformanceFeeSet(uint24 oldFee, uint24 newFee);

  event StrategySet(address oldStrategy, address newStrategy);

  struct FeeData {
    uint160 sqrtRatioX96;
    uint256 tokensOwed0;
    uint256 tokensOwed1;
    uint256 totalSupply;
    uint256 sharesMinted;
  }

  struct DepositPositionData {
    uint128 LDelta;
    int24 tickLower;
    int24 tickUpper;
  }

  enum POSITION {MAIN, RANGE}

  // details about the uniswap position
  struct Position {
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
  }

  constructor(address _registry) LixirBase(_registry) {
    PERFORMANCE_FEE_PRECISION = LixirRegistry(_registry)
      .PERFORMANCE_FEE_PRECISION();
    uniV3Factory = LixirRegistry(_registry).uniV3Factory();
  }

  /**
    @notice sets fields in the contract and initializes the `LixirVaultToken`
   */
  function initialize(
    string memory name,
    string memory symbol,
    address _token0,
    address _token1,
    address _strategist,
    address _keeper,
    address _strategy
  )
    public
    virtual
    override
    hasRole(LixirRoles.strategist_role, _strategist)
    hasRole(LixirRoles.keeper_role, _keeper)
    hasRole(LixirRoles.strategy_role, _strategy)
    initializer
  {
    require(_token0 < _token1);
    __LixirVaultToken__initialize(name, symbol);
    token0 = IERC20(_token0);
    token1 = IERC20(_token1);
    strategist = _strategist;
    keeper = _keeper;
    strategy = _strategy;
  }

  modifier onlyStrategist() {
    require(msg.sender == strategist);
    _;
  }

  modifier onlyStrategy() {
    require(msg.sender == strategy);
    _;
  }

  modifier notExpired(uint256 deadline) {
    require(block.timestamp <= deadline, 'EXPIRED');
    _;
  }

  /**
    @dev calculates shares, totals, etc. to mint the proper amount of `LixirVaultToken`s
    to `recipient`
   */
  function _depositStepOne(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient
  )
    internal
    returns (
      DepositPositionData memory mainData,
      DepositPositionData memory rangeData,
      uint256 shares,
      uint256 amount0In,
      uint256 amount1In,
      uint256 total0,
      uint256 total1
    )
  {
    LixirErrors.require_XFER_ZERO_ADDRESS(recipient != address(0));
    uint256 _totalSupply = totalSupply();

    mainData = DepositPositionData({
      LDelta: 0,
      tickLower: mainPosition.tickLower,
      tickUpper: mainPosition.tickUpper
    });

    rangeData = DepositPositionData({
      LDelta: 0,
      tickLower: rangePosition.tickLower,
      tickUpper: rangePosition.tickUpper
    });

    if (_totalSupply == 0) {
      (shares, mainData.LDelta, amount0In, amount1In) = calculateInitialDeposit(
        amount0Desired,
        amount1Desired
      );
      total0 = amount0In;
      total1 = amount1In;
    } else {
      uint128 mL;
      uint128 rL;
      {
        (uint160 sqrtRatioX96, int24 tick) = getSqrtRatioX96AndTick();
        (total0, total1, mL, rL) = _calculateTotals(
          sqrtRatioX96,
          tick,
          mainData,
          rangeData
        );
      }

      (shares, amount0In, amount1In) = calcSharesAndAmounts(
        amount0Desired,
        amount1Desired,
        total0,
        total1,
        _totalSupply
      );
      mainData.LDelta = uint128(FullMath.mulDiv(mL, shares, _totalSupply));
      rangeData.LDelta = uint128(FullMath.mulDiv(rL, shares, _totalSupply));
    }

    LixirErrors.require_INSUFFICIENT_OUTPUT_AMOUNT(
      amount0Min <= amount0In && amount1Min <= amount1In
    );

    _mintPoolTokens(recipient, shares);
  }

  /**
    @dev this function deposits the tokens into the UniV3 pool
   */
  function _depositStepTwo(
    DepositPositionData memory mainData,
    DepositPositionData memory rangeData,
    address recipient,
    uint256 shares,
    uint256 amount0In,
    uint256 amount1In,
    uint256 total0,
    uint256 total1
  ) internal {
    uint128 mLDelta = mainData.LDelta;
    if (0 < mLDelta) {
      activePool.mint(
        address(this),
        mainData.tickLower,
        mainData.tickUpper,
        mLDelta,
        ''
      );
    }
    uint128 rLDelta = rangeData.LDelta;
    if (0 < rLDelta) {
      activePool.mint(
        address(this),
        rangeData.tickLower,
        rangeData.tickUpper,
        rLDelta,
        ''
      );
    }
    emit Deposit(
      address(msg.sender),
      address(recipient),
      shares,
      amount0In,
      amount1In,
      total0,
      total1
    );
  }

  /**
    @notice deposit's the callers ERC20 tokens into the vault, mints them
    `LixirVaultToken`s, and adds their liquidity to the UniswapV3 pool.
    @param amount0Desired Amount of token 0 desired by user
    @param amount1Desired Amount of token 1 desired by user
    @param amount0Min Minimum amount of token 0 desired by user
    @param amount1Min Minimum amount of token 1 desired by user
    @param recipient The address for which the liquidity will be created
    @param deadline Blocktimestamp that this must execute before
    @return shares
    @return amount0In how much token0 was actually deposited
    @return amount1In how much token1 was actually deposited
   */
  function deposit(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  )
    external
    override
    notExpired(deadline)
    returns (
      uint256 shares,
      uint256 amount0In,
      uint256 amount1In
    )
  {
    DepositPositionData memory mainData;
    DepositPositionData memory rangeData;
    uint256 total0;
    uint256 total1;
    (
      mainData,
      rangeData,
      shares,
      amount0In,
      amount1In,
      total0,
      total1
    ) = _depositStepOne(
      amount0Desired,
      amount1Desired,
      amount0Min,
      amount1Min,
      recipient
    );
    if (0 < amount0In) {
      // token0.transferFrom(msg.sender, address(this), amount0In);
      TransferHelper.safeTransferFrom(
        address(token0),
        msg.sender,
        address(this),
        amount0In
      );
    }
    if (0 < amount1In) {
      // token1.transferFrom(msg.sender, address(this), amount1In);
      TransferHelper.safeTransferFrom(
        address(token1),
        msg.sender,
        address(this),
        amount1In
      );
    }
    _depositStepTwo(
      mainData,
      rangeData,
      recipient,
      shares,
      amount0In,
      amount1In,
      total0,
      total1
    );
  }

  function _withdrawStep(
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient
  ) internal returns (uint256 amount0Out, uint256 amount1Out) {
    LixirErrors.require_XFER_ZERO_ADDRESS(recipient != address(0));
    uint256 _totalSupply = totalSupply();
    _burnPoolTokens(withdrawer, shares); // does balance check

    (, int24 tick, , , , , ) = activePool.slot0();

    // if withdrawing everything, then burn and collect the all positions
    // else, calculate their share and return it
    if (shares == _totalSupply) {
      burnCollectPositions();
      amount0Out = token0.balanceOf(address(this));
      amount1Out = token1.balanceOf(address(this));
    } else {
      {
        uint256 e0 = token0.balanceOf(address(this));
        amount0Out = e0 > 0 ? FullMath.mulDiv(e0, shares, _totalSupply) : 0;
        uint256 e1 = token1.balanceOf(address(this));
        amount1Out = e1 > 0 ? FullMath.mulDiv(e1, shares, _totalSupply) : 0;
      }
      {
        (uint256 ma0Out, uint256 ma1Out) =
          burnAndCollect(mainPosition, tick, shares, _totalSupply);
        amount0Out = amount0Out.add(ma0Out);
        amount1Out = amount1Out.add(ma1Out);
      }
      {
        (uint256 ra0Out, uint256 ra1Out) =
          burnAndCollect(rangePosition, tick, shares, _totalSupply);
        amount0Out = amount0Out.add(ra0Out);
        amount1Out = amount1Out.add(ra1Out);
      }
    }
    LixirErrors.require_INSUFFICIENT_OUTPUT_AMOUNT(
      amount0Min <= amount0Out && amount1Min <= amount1Out
    );
    emit Withdraw(
      address(msg.sender),
      address(recipient),
      shares,
      amount0Out,
      amount1Out
    );
  }

  modifier canSpend(address withdrawer, uint256 shares) {
    uint256 currentAllowance = _allowance[withdrawer][msg.sender];
    LixirErrors.require_INSUFFICIENT_ALLOWANCE(
      msg.sender == withdrawer || currentAllowance >= shares
    );

    if (msg.sender != withdrawer && currentAllowance != uint256(-1)) {
      // Because of the previous require, we know that if msg.sender != withdrawer then currentAllowance >= shares
      _setAllowance(withdrawer, msg.sender, currentAllowance - shares);
    }
    _;
  }

  /**
  @notice withdraws the desired shares from the vault on behalf of another account
  @dev same as `withdraw` except this can be called from an `approve`d address
  @param withdrawer the address to withdraw from
  @param shares number of shares to withdraw
  @param amount0Min Minimum amount of token 0 desired by user
  @param amount1Min Minimum amount of token 1 desired by user
  @param recipient address to recieve token0 and token1 withdrawals
  @param deadline blocktimestamp that this must execute by
  @return amount0Out how much token0 was actually withdrawn
  @return amount1Out how much token1 was actually withdrawn
  */
  function withdrawFrom(
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  )
    external
    override
    canSpend(withdrawer, shares)
    returns (uint256 amount0Out, uint256 amount1Out)
  {
    (amount0Out, amount1Out) = _withdraw(
      withdrawer,
      shares,
      amount0Min,
      amount1Min,
      recipient,
      deadline
    );
  }

  /**
    @notice withdraws the desired shares from the vault and transfers to caller.
    @dev `_withdrawStep` calculates how much the caller is owed
    @dev `_withdraw` transfers the tokens to the caller
    @param shares number of shares to withdraw
    @param amount0Min Minimum amount of token 0 desired by user
    @param amount1Min Minimum amount of token 1 desired by user
    @param recipient address to recieve token0 and token1 withdrawals
    @param deadline blocktimestamp that this must execute by
    @return amount0Out how much token0 was actually withdrawn
    @return amount1Out how much token1 was actually withdrawn
   */
  function withdraw(
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  ) external override returns (uint256 amount0Out, uint256 amount1Out) {
    (amount0Out, amount1Out) = _withdraw(
      msg.sender,
      shares,
      amount0Min,
      amount1Min,
      recipient,
      deadline
    );
  }

  function _withdraw(
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  )
    internal
    notExpired(deadline)
    returns (uint256 amount0Out, uint256 amount1Out)
  {
    (amount0Out, amount1Out) = _withdrawStep(
      withdrawer,
      shares,
      amount0Min,
      amount1Min,
      recipient
    );
    if (0 < amount0Out) {
      TransferHelper.safeTransfer(address(token0), recipient, amount0Out);
    }
    if (0 < amount1Out) {
      TransferHelper.safeTransfer(address(token1), recipient, amount1Out);
    }
  }

  function setPerformanceFee(uint24 newFee)
    external
    override
    onlyRole(LixirRoles.fee_setter_role)
  {
    require(newFee < PERFORMANCE_FEE_PRECISION);
    emit PerformanceFeeSet(performanceFee, newFee);
    performanceFee = newFee;
  }

  function _setPool(uint24 fee) internal {
    activePool = IUniswapV3Pool(
      PoolAddress.computeAddress(
        uniV3Factory,
        PoolAddress.getPoolKey(address(token0), address(token1), fee)
      )
    );
    require(Address.isContract(address(activePool)));
    activeFee = fee;
  }

  function setKeeper(address _keeper)
    external
    override
    onlyStrategist
    hasRole(LixirRoles.keeper_role, _keeper)
  {
    keeper = _keeper;
  }

  function setStrategy(address _strategy)
    external
    override
    onlyStrategist
    hasRole(LixirRoles.strategy_role, _strategy)
  {
    emit StrategySet(strategy, _strategy);
    strategy = _strategy;
  }

  function setStrategist(address _strategist)
    external
    override
    onlyGovOrDelegate
    hasRole(LixirRoles.strategist_role, _strategist)
  {
    strategist = _strategist;
  }

  /**
    @notice burns all positions collects any fees accrued since last `rebalance`
    and mints new positions.
    @dev This function is not called by an external account, but instead by the
    strategy contract, which automatically calculates the proper positions to mint.
   */
  function rebalance(
    int24 mainTickLower,
    int24 mainTickUpper,
    int24 rangeTickLower0,
    int24 rangeTickUpper0,
    int24 rangeTickLower1,
    int24 rangeTickUpper1,
    uint24 fee
  ) external override onlyStrategy {
    require(
      TickMath.MIN_TICK <= mainTickLower &&
        mainTickUpper <= TickMath.MAX_TICK &&
        mainTickLower < mainTickUpper &&
        TickMath.MIN_TICK <= rangeTickLower0 &&
        rangeTickUpper0 <= TickMath.MAX_TICK &&
        rangeTickLower0 < rangeTickUpper0 &&
        TickMath.MIN_TICK <= rangeTickLower1 &&
        rangeTickUpper1 <= TickMath.MAX_TICK &&
        rangeTickLower1 < rangeTickUpper1
    );
    // if a pool has been previously set, then take the performance fee accrued since last `rebalance`
    // and burn and collect all positions.
    FeeData memory feeData;
    if (address(activePool) != address(0)) {
      feeData = _getFeeDataMaybeTakePerfFee();
      burnCollectPositions();
    } else {
      feeData = FeeData(0, 0, 0, 0, 0);
    }
    // if the strategist has changed the pool fee tier (e.g. 0.05%, 0.3%, 1%), then change the pool
    if (fee != activeFee) {
      _setPool(fee);
    }

    uint256 total0 = token0.balanceOf(address(this));
    uint256 total1 = token1.balanceOf(address(this));

    Position memory mainData = Position(mainTickLower, mainTickUpper);
    Position memory rangeData0 = Position(rangeTickLower0, rangeTickUpper0);
    Position memory rangeData1 = Position(rangeTickLower1, rangeTickUpper1);

    mintPositions(total0, total1, mainData, rangeData0, rangeData1);

    emit Rebalance(
      mainTickLower,
      mainTickUpper,
      rangePosition.tickLower,
      rangePosition.tickUpper,
      fee,
      total0,
      total1,
      feeData
    );
  }

  function mintPositions(
    uint256 amount0,
    uint256 amount1,
    Position memory mainData,
    Position memory rangeData0,
    Position memory rangeData1
  ) internal {
    (uint160 sqrtRatioX96, ) = getSqrtRatioX96AndTick();
    mainPosition.tickLower = mainData.tickLower;
    mainPosition.tickUpper = mainData.tickUpper;

    if (0 < amount0 || 0 < amount1) {
      uint128 mL =
        LiquidityAmounts.getLiquidityForAmounts(
          sqrtRatioX96,
          TickMath.getSqrtRatioAtTick(mainData.tickLower),
          TickMath.getSqrtRatioAtTick(mainData.tickUpper),
          amount0,
          amount1
        );

      if (0 < mL) {
        activePool.mint(
          address(this),
          mainData.tickLower,
          mainData.tickUpper,
          mL,
          ''
        );
      }
    }
    amount0 = token0.balanceOf(address(this));
    amount1 = token1.balanceOf(address(this));
    uint128 rL;
    Position memory rangeData;
    if (0 < amount0 || 0 < amount1) {
      uint128 rL0 =
        LiquidityAmounts.getLiquidityForAmount0(
          TickMath.getSqrtRatioAtTick(rangeData0.tickLower),
          TickMath.getSqrtRatioAtTick(rangeData0.tickUpper),
          amount0
        );
      uint128 rL1 =
        LiquidityAmounts.getLiquidityForAmount1(
          TickMath.getSqrtRatioAtTick(rangeData1.tickLower),
          TickMath.getSqrtRatioAtTick(rangeData1.tickUpper),
          amount1
        );

      /// only one range position will ever have liquidity (if any)
      if (rL1 < rL0) {
        rL = rL0;
        rangeData = rangeData0;
      } else if (0 < rL1) {
        rangeData = rangeData1;
        rL = rL1;
      }
    } else {
      rangeData = Position(0, 0);
    }

    rangePosition.tickLower = rangeData.tickLower;
    rangePosition.tickUpper = rangeData.tickUpper;

    if (0 < rL) {
      activePool.mint(
        address(this),
        rangeData.tickLower,
        rangeData.tickUpper,
        rL,
        ''
      );
    }
  }

  function _getFeeDataMaybeTakePerfFee() internal returns (FeeData memory) {
    uint24 _perfFee = performanceFee;
    address _feeTo = registry.feeTo();
    (uint160 sqrtRatioX96, int24 tick) = getSqrtRatioX96AndTick();
    (
      ,
      uint256 total0,
      uint256 total1,
      uint256 tokensOwed0,
      uint256 tokensOwed1
    ) =
      calculatePositionInfo(
        tick,
        sqrtRatioX96,
        mainPosition.tickLower,
        mainPosition.tickUpper
      );
    {
      (
        ,
        uint256 total0Range,
        uint256 total1Range,
        uint256 tokensOwed0Range,
        uint256 tokensOwed1Range
      ) =
        calculatePositionInfo(
          tick,
          sqrtRatioX96,
          rangePosition.tickLower,
          rangePosition.tickUpper
        );
      total0 = total0.add(total0Range).add(token0.balanceOf(address(this)));
      total1 = total1.add(total1Range).add(token1.balanceOf(address(this)));
      tokensOwed0 = tokensOwed0.add(tokensOwed0Range);
      tokensOwed1 = tokensOwed1.add(tokensOwed1Range);
    }
    uint256 _totalSupply = totalSupply();

    FeeData memory feeData =
      FeeData(
        sqrtRatioX96,
        tokensOwed0,
        tokensOwed1,
        _totalSupply,
        0
      );

    if (_feeTo != address(0) && 0 < _perfFee) {
      uint256 price =
        FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, FixedPoint96.Q96);

      total1 = total1.add(FullMath.mulDiv(total0, price, FixedPoint96.Q96));
      if (total1 > 0) {
        tokensOwed1 = tokensOwed1.add(
          FullMath.mulDiv(tokensOwed0, price, FixedPoint96.Q96)
        );
        uint256 shares =
          FullMath.mulDiv(
            FullMath.mulDiv(tokensOwed1, _totalSupply, total1),
            performanceFee,
            PERFORMANCE_FEE_PRECISION
          );
        if (shares > 0) {
          feeData.sharesMinted = shares;
          _mintPoolTokens(_feeTo, shares);
        }
      }
    }
    return feeData;
  }

  /**
    @notice burns everyting (main and range positions) and collects any fees accrued in the pool.
    @dev this is called fairly frequently since compounding is not automatic: in UniV3,
    all fees must be manually withdrawn.
   */
  function burnCollectPositions() internal {
    uint128 mL = positionLiquidity(mainPosition);
    uint128 rL = positionLiquidity(rangePosition);

    if (0 < mL) {
      activePool.burn(mainPosition.tickLower, mainPosition.tickUpper, mL);
      activePool.collect(
        address(this),
        mainPosition.tickLower,
        mainPosition.tickUpper,
        type(uint128).max,
        type(uint128).max
      );
    }
    if (0 < rL) {
      activePool.burn(rangePosition.tickLower, rangePosition.tickUpper, rL);
      activePool.collect(
        address(this),
        rangePosition.tickLower,
        rangePosition.tickUpper,
        type(uint128).max,
        type(uint128).max
      );
    }
  }

  /**
    @notice in contrast to `burnCollectPositions`, this only burns a portion of liqudity,
    used for when a user withdraws tokens from the vault.
    @param position Storage pointer to position
    @param tick Current tick
    @param shares User shares to burn
    @param _totalSupply totalSupply of Lixir vault tokens
   */
  function burnAndCollect(
    Position storage position,
    int24 tick,
    uint256 shares,
    uint256 _totalSupply
  ) internal returns (uint256 amount0Out, uint256 amount1Out) {
    int24 tickLower = position.tickLower;
    int24 tickUpper = position.tickUpper;
    /*
     * N.B. that tokensOwed{0,1} here are calculated prior to burning,
     *  and so should only contain tokensOwed from fees and never tokensOwed from a burn
     */
    (uint128 liquidity, uint256 tokensOwed0, uint256 tokensOwed1) =
      liquidityAndTokensOwed(tick, tickLower, tickUpper);

    uint128 LDelta =
      FullMath.mulDiv(shares, liquidity, _totalSupply).toUint128();

    amount0Out = FullMath.mulDiv(tokensOwed0, shares, _totalSupply);
    amount1Out = FullMath.mulDiv(tokensOwed1, shares, _totalSupply);

    if (0 < LDelta) {
      (uint256 burnt0Out, uint256 burnt1Out) =
        activePool.burn(tickLower, tickUpper, LDelta);
      amount0Out = amount0Out.add(burnt0Out);
      amount1Out = amount1Out.add(burnt1Out);
    }
    if (0 < amount0Out || 0 < amount1Out) {
      activePool.collect(
        address(this),
        tickLower,
        tickUpper,
        amount0Out.toUint128(),
        amount1Out.toUint128()
      );
    }
  }

  /// @dev internal readonly getters and pure helper functions

  /**
   * @dev Calculates shares and amounts to deposit from amounts desired, TVL of vault, and totalSupply of vault tokens
   * @param amount0Desired Amount of token 0 desired by user
   * @param amount1Desired Amount of token 1 desired by user
   * @param total0 Total amount of token 0 available to activePool
   * @param total1 Total amount of token 1 available to activePool
   * @param _totalSupply Total supply of vault tokens
   * @return shares Shares of activePool to mint to user
   * @return amount0In Actual amount of token0 user should deposit into activePool
   * @return amount1In Actual amount of token1 user should deposit into activePool
   */
  function calcSharesAndAmounts(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 total0,
    uint256 total1,
    uint256 _totalSupply
  )
    internal
    pure
    returns (
      uint256 shares,
      uint256 amount0In,
      uint256 amount1In
    )
  {
    (bool roundedSharesFrom0, uint256 sharesFrom0) =
      0 < total0
        ? mulDivRoundingUp(amount0Desired, _totalSupply, total0)
        : (false, 0);
    (bool roundedSharesFrom1, uint256 sharesFrom1) =
      0 < total1
        ? mulDivRoundingUp(amount1Desired, _totalSupply, total1)
        : (false, 0);
    uint8 realSharesOffsetFor0 = roundedSharesFrom0 ? 1 : 2;
    uint8 realSharesOffsetFor1 = roundedSharesFrom1 ? 1 : 2;
    if (
      realSharesOffsetFor0 < sharesFrom0 &&
      (total1 == 0 || sharesFrom0 < sharesFrom1)
    ) {
      shares = sharesFrom0 - 1 - realSharesOffsetFor0;
      amount0In = amount0Desired;
      amount1In = FullMath.mulDivRoundingUp(sharesFrom0, total1, _totalSupply);
    } else {
      LixirErrors.require_INSUFFICIENT_INPUT_AMOUNT(
        realSharesOffsetFor1 < sharesFrom1
      );
      shares = sharesFrom1 - 1 - realSharesOffsetFor1;
      amount0In = FullMath.mulDivRoundingUp(sharesFrom1, total0, _totalSupply);
      amount1In = amount1Desired;
    }
    LixirErrors.require_INSUFFICIENT_OUTPUT_AMOUNT(amount0In <= amount0Desired);
    LixirErrors.require_INSUFFICIENT_OUTPUT_AMOUNT(amount1In <= amount1Desired);
  }

  function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (bool rounded, uint256 result) {
    result = FullMath.mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      require(result < type(uint256).max);
      result++;
      rounded = true;
    }
  }

  /**
   * @dev Calculates shares, liquidity deltas, and amounts in for initial deposit
   * @param amount0Desired Amount of token 0 desired by user
   * @param amount1Desired Amount of token 1 desired by user
   * @return shares Initial shares to mint
   * @return mLDelta Liquidity delta for main position
   * @return amount0In Amount of token 0 to transfer from user
   * @return amount1In Amount of token 1 to transfer from user
   */
  function calculateInitialDeposit(
    uint256 amount0Desired,
    uint256 amount1Desired
  )
    internal
    view
    returns (
      uint256 shares,
      uint128 mLDelta,
      uint256 amount0In,
      uint256 amount1In
    )
  {
    (uint160 sqrtRatioX96, ) = getSqrtRatioX96AndTick();
    uint160 sqrtRatioLowerX96 =
      TickMath.getSqrtRatioAtTick(mainPosition.tickLower);
    uint160 sqrtRatioUpperX96 =
      TickMath.getSqrtRatioAtTick(mainPosition.tickUpper);

    mLDelta = LiquidityAmounts.getLiquidityForAmounts(
      sqrtRatioX96,
      sqrtRatioLowerX96,
      sqrtRatioUpperX96,
      amount0Desired,
      amount1Desired
    );

    LixirErrors.require_INSUFFICIENT_INPUT_AMOUNT(0 < mLDelta);

    (amount0In, amount1In) = getAmountsForLiquidity(
      sqrtRatioX96,
      sqrtRatioLowerX96,
      sqrtRatioUpperX96,
      mLDelta.toInt128()
    );
    shares = mLDelta;
  }

  /**
   * @dev Queries activePool for current square root price and current tick
   * @return _sqrtRatioX96 Current square root price
   * @return _tick Current tick
   */
  function getSqrtRatioX96AndTick()
    internal
    view
    returns (uint160 _sqrtRatioX96, int24 _tick)
  {
    (_sqrtRatioX96, _tick, , , , , ) = activePool.slot0();
  }

  /**
   * @dev Calculates tokens owed for a position
   * @param realTick Current tick
   * @param tickLower Lower tick of position
   * @param tickUpper Upper tick of position
   * @param feeGrowthInside0LastX128 Last fee growth of token0 between tickLower and tickUpper
   * @param feeGrowthInside1LastX128 Last fee growth of token0 between tickLower and tickUpper
   * @param liquidity Liquidity of position for which tokens owed is being calculated
   * @param tokensOwed0Last Last tokens owed to position
   * @param tokensOwed1Last Last tokens owed to position
   * @return tokensOwed0 Amount of token0 owed to position
   * @return tokensOwed1 Amount of token1 owed to position
   */
  function calculateTokensOwed(
    int24 realTick,
    int24 tickLower,
    int24 tickUpper,
    uint256 feeGrowthInside0LastX128,
    uint256 feeGrowthInside1LastX128,
    uint128 liquidity,
    uint128 tokensOwed0Last,
    uint128 tokensOwed1Last
  ) internal view returns (uint128 tokensOwed0, uint128 tokensOwed1) {
    /*
     * V3 doesn't use SafeMath here, so we don't either
     * This could of course result in a dramatic forfeiture of fees. The reality though is
     * we rebalance far frequently enough for this to never happen in any realistic scenario.
     * This has no difference from the v3 implementation, and was copied from contracts/libraries/Position.sol
     */
    (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
      getFeeGrowthInsideTicks(realTick, tickLower, tickUpper);
    tokensOwed0 = uint128(
      tokensOwed0Last +
        FullMath.mulDiv(
          feeGrowthInside0X128 - feeGrowthInside0LastX128,
          liquidity,
          FixedPoint128.Q128
        )
    );
    tokensOwed1 = uint128(
      tokensOwed1Last +
        FullMath.mulDiv(
          feeGrowthInside1X128 - feeGrowthInside1LastX128,
          liquidity,
          FixedPoint128.Q128
        )
    );
  }

  function _positionDataHelper(
    int24 realTick,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (
      uint128 liquidity,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    )
  {
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    (
      liquidity,
      feeGrowthInside0LastX128,
      feeGrowthInside1LastX128,
      tokensOwed0,
      tokensOwed1
    ) = activePool.positions(
      PositionKey.compute(address(this), tickLower, tickUpper)
    );

    if (liquidity == 0) {
      return (0, tokensOwed0, tokensOwed1);
    }

    (tokensOwed0, tokensOwed1) = calculateTokensOwed(
      realTick,
      tickLower,
      tickUpper,
      feeGrowthInside0LastX128,
      feeGrowthInside1LastX128,
      liquidity,
      tokensOwed0,
      tokensOwed1
    );
  }

  /**
   * @dev Queries and calculates liquidity and tokens owed
   * @param tick Current tick
   * @param tickLower Lower tick of position
   * @param tickUpper Upper tick of position
   * @return liquidity Liquidity of position for which tokens owed is being calculated
   * @return tokensOwed0 Amount of token0 owed to position
   * @return tokensOwed1 Amount of token1 owed to position
   */
  function liquidityAndTokensOwed(
    int24 tick,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (
      uint128 liquidity,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    )
  {
    (liquidity, tokensOwed0, tokensOwed1) = _positionDataHelper(
      tick,
      tickLower,
      tickUpper
    );
  }

  function calculateTotals()
    external
    view
    override
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    )
  {
    (uint160 sqrtRatioX96, int24 tick) = getSqrtRatioX96AndTick();
    return
      _calculateTotals(
        sqrtRatioX96,
        tick,
        DepositPositionData(0, mainPosition.tickLower, mainPosition.tickUpper),
        DepositPositionData(0, rangePosition.tickLower, rangePosition.tickUpper)
      );
  }

  /**
   * @notice This variant is so that tick TWAP's may be used by other protocols to calculate
   * totals, allowing them to safeguard themselves from manipulation. This would be useful if
   * Lixir vault tokens were used as collateral in a lending protocol.
   * @param virtualTick Tick at which to calculate amounts from liquidity
   */
  function calculateTotalsFromTick(int24 virtualTick)
    external
    view
    override
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    )
  {
    uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(virtualTick);
    (, int24 realTick) = getSqrtRatioX96AndTick();
    return
      _calculateTotalsFromTick(
        sqrtRatioX96,
        realTick,
        DepositPositionData(0, mainPosition.tickLower, mainPosition.tickUpper),
        DepositPositionData(0, rangePosition.tickLower, rangePosition.tickUpper)
      );
  }

  /**
   * @dev Helper function for calculating totals
   * @param sqrtRatioX96 *Current or virtual* sqrtPriceX96
   * @param realTick Current tick, for calculating tokensOwed correctly
   * @param mainData Main position data
   * @param rangeData Range position data
   * N.B realTick must be provided because tokensOwed calculation needs
   * the current correct tick because the ticks are only updated upon the
   * crossing of ticks
   * sqrtRatioX96 can be a current sqrtPriceX96 *or* a sqrtPriceX96 calculated
   * from a virtual tick, for external consumption
   */
  function _calculateTotalsFromTick(
    uint160 sqrtRatioX96,
    int24 realTick,
    DepositPositionData memory mainData,
    DepositPositionData memory rangeData
  )
    internal
    view
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    )
  {
    (mL, total0, total1) = calculatePositionTotals(
      realTick,
      sqrtRatioX96,
      mainData.tickLower,
      mainData.tickUpper
    );
    {
      uint256 rt0;
      uint256 rt1;
      (rL, rt0, rt1) = calculatePositionTotals(
        realTick,
        sqrtRatioX96,
        rangeData.tickLower,
        rangeData.tickUpper
      );
      total0 = total0.add(rt0);
      total1 = total1.add(rt1);
    }
    total0 = total0.add(token0.balanceOf(address(this)));
    total1 = total1.add(token1.balanceOf(address(this)));
  }

  function _calculateTotals(
    uint160 sqrtRatioX96,
    int24 tick,
    DepositPositionData memory mainData,
    DepositPositionData memory rangeData
  )
    internal
    view
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    )
  {
    return _calculateTotalsFromTick(sqrtRatioX96, tick, mainData, rangeData);
  }

  /**
   * @dev Calculates total tokens obtainable and liquidity of a given position (fees + amounts in position)
   * total{0,1} is sum of tokensOwed{0,1} from each position plus sum of liquidityForAmount{0,1} for each position plus vault balance of token{0,1}
   * @param realTick Current tick (for calculating tokensOwed)
   * @param sqrtRatioX96 Current (or virtual) square root price
   * @param tickLower Lower tick of position
   * @param tickLower Upper tick of position
   * @return liquidity Liquidity of position
   * @return total0 Total amount of token0 obtainable from position
   * @return total1 Total amount of token1 obtainable from position
   */
  function calculatePositionTotals(
    int24 realTick,
    uint160 sqrtRatioX96,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (
      uint128 liquidity,
      uint256 total0,
      uint256 total1
    )
  {
    uint256 tokensOwed0;
    uint256 tokensOwed1;
    (
      liquidity,
      total0,
      total1,
      tokensOwed0,
      tokensOwed1
    ) = calculatePositionInfo(realTick, sqrtRatioX96, tickLower, tickUpper);
    total0 = total0.add(tokensOwed0);
    total1 = total1.add(tokensOwed1);
  }

  function calculatePositionInfo(
    int24 realTick,
    uint160 sqrtRatioX96,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (
      uint128 liquidity,
      uint256 total0,
      uint256 total1,
      uint256 tokensOwed0,
      uint256 tokensOwed1
    )
  {
    (liquidity, tokensOwed0, tokensOwed1) = _positionDataHelper(
      realTick,
      tickLower,
      tickUpper
    );

    uint160 sqrtPriceLower = TickMath.getSqrtRatioAtTick(tickLower);
    uint160 sqrtPriceUpper = TickMath.getSqrtRatioAtTick(tickUpper);
    (total0, total1) = getAmountsForLiquidity(
      sqrtRatioX96,
      sqrtPriceLower,
      sqrtPriceUpper,
      liquidity.toInt128()
    );
  }

  /**
   * @dev Calculates fee growth between a tick range
   * @param tick Current tick
   * @param tickLower Lower tick of range
   * @param tickUpper Upper tick of range
   * @return feeGrowthInside0X128 Fee growth of token 0 inside ticks
   * @return feeGrowthInside1X128 Fee growth of token 1 inside ticks
   */
  function getFeeGrowthInsideTicks(
    int24 tick,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
  {
    /*
     * Underflow is Good here, actually.
     * Uniswap V3 doesn't use SafeMath here, and the cases where it does underflow,
     * it should help us get back to the rightful fee growth value of our position.
     * It would underflow only when feeGrowthGlobal{0,1}X128 has overflowed already in the V3 contract.
     * It should never underflow if feeGrowthGlobal{0,1}X128 hasn't yet overflowed.
     * Of course, if feeGrowthGlobal{0,1}X128 has overflowed twice over or more, we cannot possibly recover
     * fees from the overflow before last via underflow here, and it is possible our feeGrowthOutside values are
     * insufficently large to underflow enough to recover fees from the most recent overflow.
     * But, we rebalance frequently, so this should never be an issue.
     * This math is no different than in the v3 activePool contract and was copied from contracts/libraries/Tick.sol
     */
    uint256 feeGrowthGlobal0X128 = activePool.feeGrowthGlobal0X128();
    uint256 feeGrowthGlobal1X128 = activePool.feeGrowthGlobal1X128();
    (
      ,
      ,
      uint256 feeGrowthOutside0X128Lower,
      uint256 feeGrowthOutside1X128Lower,
      ,
      ,
      ,

    ) = activePool.ticks(tickLower);
    (
      ,
      ,
      uint256 feeGrowthOutside0X128Upper,
      uint256 feeGrowthOutside1X128Upper,
      ,
      ,
      ,

    ) = activePool.ticks(tickUpper);

    // calculate fee growth below
    uint256 feeGrowthBelow0X128;
    uint256 feeGrowthBelow1X128;
    if (tick >= tickLower) {
      feeGrowthBelow0X128 = feeGrowthOutside0X128Lower;
      feeGrowthBelow1X128 = feeGrowthOutside1X128Lower;
    } else {
      feeGrowthBelow0X128 = feeGrowthGlobal0X128 - feeGrowthOutside0X128Lower;
      feeGrowthBelow1X128 = feeGrowthGlobal1X128 - feeGrowthOutside1X128Lower;
    }

    // calculate fee growth above
    uint256 feeGrowthAbove0X128;
    uint256 feeGrowthAbove1X128;
    if (tick < tickUpper) {
      feeGrowthAbove0X128 = feeGrowthOutside0X128Upper;
      feeGrowthAbove1X128 = feeGrowthOutside1X128Upper;
    } else {
      feeGrowthAbove0X128 = feeGrowthGlobal0X128 - feeGrowthOutside0X128Upper;
      feeGrowthAbove1X128 = feeGrowthGlobal1X128 - feeGrowthOutside1X128Upper;
    }

    feeGrowthInside0X128 =
      feeGrowthGlobal0X128 -
      feeGrowthBelow0X128 -
      feeGrowthAbove0X128;
    feeGrowthInside1X128 =
      feeGrowthGlobal1X128 -
      feeGrowthBelow1X128 -
      feeGrowthAbove1X128;
  }

  /**
   * @dev Queries position liquidity
   * @param position Storage pointer to position we want to query
   */
  function positionLiquidity(Position storage position)
    internal
    view
    returns (uint128 _liquidity)
  {
    (_liquidity, , , , ) = activePool.positions(
      PositionKey.compute(address(this), position.tickLower, position.tickUpper)
    );
  }

  function getAmountsForLiquidity(
    uint160 sqrtPriceX96,
    uint160 sqrtPriceX96Lower,
    uint160 sqrtPriceX96Upper,
    int128 liquidityDelta
  ) internal pure returns (uint256 amount0, uint256 amount1) {
    if (sqrtPriceX96 <= sqrtPriceX96Lower) {
      // current tick is below the passed range; liquidity can only become in range by crossing from left to
      // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
      amount0 = SqrtPriceMath
        .getAmount0Delta(sqrtPriceX96Lower, sqrtPriceX96Upper, liquidityDelta)
        .abs();
    } else if (sqrtPriceX96 < sqrtPriceX96Upper) {
      amount0 = SqrtPriceMath
        .getAmount0Delta(sqrtPriceX96, sqrtPriceX96Upper, liquidityDelta)
        .abs();
      amount1 = SqrtPriceMath
        .getAmount1Delta(sqrtPriceX96Lower, sqrtPriceX96, liquidityDelta)
        .abs();
    } else {
      // current tick is above the passed range; liquidity can only become in range by crossing from right to
      // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
      amount1 = SqrtPriceMath
        .getAmount1Delta(sqrtPriceX96Lower, sqrtPriceX96Upper, liquidityDelta)
        .abs();
    }
  }

  /// @inheritdoc IUniswapV3MintCallback
  function uniswapV3MintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata
  ) external virtual override {
    require(msg.sender == address(activePool));
    if (amount0Owed > 0) {
      TransferHelper.safeTransfer(address(token0), msg.sender, amount0Owed);
    }
    if (amount1Owed > 0) {
      TransferHelper.safeTransfer(address(token1), msg.sender, amount1Owed);
    }
  }
}