// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import "../interfaces/IUniStrategy.sol";
import "../interfaces/IUnipilot.sol";
import "../interfaces/uniswap/IUniswapLiquidityManager.sol";
import "../oracle/interfaces/IOracle.sol";

import "../libraries/LiquidityReserves.sol";
import "../libraries/FixedPoint128.sol";
import "../libraries/SafeCast.sol";
import "../libraries/LiquidityPositions.sol";
import "../libraries/UserPositions.sol";

import "./PeripheryPayments.sol";

/// @title UniswapLiquidityManager Universal Liquidity Manager of Uniswap V3
/// @notice Universal & Automated liquidity managment contract that handles liquidity of any Uniswap V3 pool
/// @dev Instead of deploying a contract each time when a new vault is created, UniswapLiquidityManager will
/// manage this in a single contract, all of the vaults are managed within one contract with users just paying
/// storage fees when creating a new vault.
/// @dev UniswapLiquidityManager always maintains 2 range orders on Uniswap V3,
/// base order: The main liquidity range -- where the majority of LP capital sits
/// limit order: A single token range -- depending on which token it holds more of after the base order was placed.
/// @dev The vault readjustment function can be called by captains or anyone to ensure
/// the liquidity of each vault remains in the most optimum range, incentive will be provided for readjustment of vault
/// @dev Vault can not be readjust more than two times in 24 hrs,
/// pool is too volatile if it requires readjustment more than 2
/// @dev User can collect fees in 2 ways:
/// 1. Claim fees in tokens with vault fare, 2. Claim all fees in PILOT
contract UniswapLiquidityManager is PeripheryPayments, IUniswapLiquidityManager {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    address private immutable uniswapFactory;

    uint128 private constant MAX_UINT128 = type(uint128).max;

    uint8 private _unlocked = 1;

    /// @dev The token ID position data of the user
    mapping(uint256 => Position) private positions;

    /// @dev The data of the Unipilot base & range orders
    mapping(address => LiquidityPosition) private liquidityPositions;

    UnipilotProtocolDetails private unipilotProtocolDetails;

    modifier onlyUnipilot() {
        _isUnipilot();
        _;
    }

    modifier onlyGovernance() {
        _isGovernance();
        _;
    }

    modifier nonReentrant() {
        require(_unlocked == 1);
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    constructor(UnipilotProtocolDetails memory params, address _uniswapFactory) {
        unipilotProtocolDetails = params;
        uniswapFactory = _uniswapFactory;
    }

    function userPositions(uint256 tokenId)
        external
        view
        override
        returns (Position memory)
    {
        return positions[tokenId];
    }

    function poolPositions(address pool)
        external
        view
        override
        returns (LiquidityPosition memory)
    {
        return liquidityPositions[pool];
    }

    /// @dev Blacklist/Whitelist swapping for getting pool in range & premium for readjust liquidity
    /// @param pool Address of the uniswap v3 pool
    /// @param feesInPilot_ Additional premium of a user as an incentive for optimization of vaults.
    /// @param managed_ P
    function setPoolIncentives(
        address pool,
        bool feesInPilot_,
        bool managed_,
        address oracle0,
        address oracle1
    ) external onlyGovernance {
        LiquidityPosition storage lp = liquidityPositions[pool];
        lp.feesInPilot = feesInPilot_;
        lp.managed = managed_;
        lp.oracle0 = oracle0;
        lp.oracle1 = oracle1;
    }

    /// @dev Sets the new details for unipilot protocol
    function setPilotProtocolDetails(UnipilotProtocolDetails calldata params)
        external
        onlyGovernance
    {
        unipilotProtocolDetails = params;
    }

    /// @notice Returns the status of runnng readjust function, the limit is set to 2 readjusts per day
    /// @param pool Address of the pool
    /// @return status Pool rebase status
    function readjustFrequencyStatus(address pool) public returns (bool status) {
        LiquidityPosition storage lp = liquidityPositions[pool];
        if (
            block.timestamp - lp.timestamp > unipilotProtocolDetails.readjustFrequencyTime
        ) {
            lp.counter = 0;
            lp.status = false;
        }
        status = lp.status;
    }

    /// @inheritdoc IUniswapLiquidityManager
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        address sender = msg.sender;
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        _verifyCallback(decoded.token0, decoded.token1, decoded.fee);
        if (amount0Owed > 0) pay(decoded.token0, decoded.payer, sender, amount0Owed);
        if (amount1Owed > 0) pay(decoded.token1, decoded.payer, sender, amount1Owed);
    }

    /// @inheritdoc IUniswapLiquidityManager
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        address recipient = msg.sender;
        SwapCallbackData memory decoded = abi.decode(data, (SwapCallbackData));
        _verifyCallback(decoded.token0, decoded.token1, decoded.fee);
        if (amount0Delta > 0)
            pay(decoded.token0, address(this), recipient, uint256(amount0Delta));
        if (amount1Delta > 0)
            pay(decoded.token1, address(this), recipient, uint256(amount1Delta));
    }

    /// @inheritdoc IUniswapLiquidityManager
    function getReserves(
        address token0,
        address token1,
        bytes calldata data
    )
        external
        view
        override
        returns (
            uint256 totalAmount0,
            uint256 totalAmount1,
            uint256 totalLiquidity
        )
    {
        uint24 fee = abi.decode(data, (uint24));
        address pool = getPoolAddress(token0, token1, fee);
        (totalAmount0, totalAmount1, totalLiquidity) = updatePositionTotalAmounts(pool);
    }

    /// @notice Returns maximum amount of fees owed to a specific user position
    /// @dev Updates the unipilot base & range positions in order to fetch updated amount of user fees
    /// @param tokenId The ID of the Unpilot NFT for which tokens will be collected
    /// @return fees0 Amount of fees in token0
    /// @return fees1 Amount of fees in token1
    function getUserFees(uint256 tokenId)
        external
        returns (uint256 fees0, uint256 fees1)
    {
        Position memory position = positions[tokenId];
        _collectPositionFees(position.pool);
        LiquidityPosition memory lp = liquidityPositions[position.pool];
        (uint256 tokensOwed0, uint256 tokensOwed1) = UserPositions.getTokensOwedAmount(
            position.feeGrowth0,
            position.feeGrowth1,
            position.liquidity,
            lp.feeGrowthGlobal0,
            lp.feeGrowthGlobal1
        );

        fees0 = position.tokensOwed0.add(tokensOwed0);
        fees1 = position.tokensOwed1.add(tokensOwed1);
    }

    /// @inheritdoc IUniswapLiquidityManager
    function createPair(
        address _token0,
        address _token1,
        bytes memory data
    ) external override returns (address _pool) {
        (uint24 _fee, uint160 _sqrtPriceX96) = abi.decode(data, (uint24, uint160));
        _pool = IUniswapV3Factory(uniswapFactory).createPool(_token0, _token1, _fee);
        IUniswapV3Pool(_pool).initialize(_sqrtPriceX96);
        emit PoolCreated(_token0, _token1, _pool, _fee, _sqrtPriceX96);
    }

    /// @inheritdoc IUniswapLiquidityManager
    function deposit(
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 shares,
        uint256 tokenId,
        bool isTokenMinted,
        bytes memory data
    ) external payable override onlyUnipilot {
        DepositVars memory b;
        b.fee = abi.decode(data, (uint24));
        b.pool = getPoolAddress(token0, token1, b.fee);
        LiquidityPosition storage poolPosition = liquidityPositions[b.pool];

        // updating the feeGrowthGlobal of pool for new user
        if (poolPosition.totalLiquidity > 0) _collectPositionFees(b.pool);
        (
            b.amount0Base,
            b.amount1Base,
            b.amount0Range,
            b.amount1Range
        ) = _addLiquidityInManager(
            AddLiquidityManagerParams({
                pool: b.pool,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                shares: shares
            })
        );

        if (!isTokenMinted) {
            Position storage userPosition = positions[tokenId];
            require(b.pool == userPosition.pool);
            userPosition.tokensOwed0 += FullMath.mulDiv(
                poolPosition.feeGrowthGlobal0 - userPosition.feeGrowth0,
                userPosition.liquidity,
                FixedPoint128.Q128
            );
            userPosition.tokensOwed1 += FullMath.mulDiv(
                poolPosition.feeGrowthGlobal1 - userPosition.feeGrowth1,
                userPosition.liquidity,
                FixedPoint128.Q128
            );
            userPosition.liquidity += shares;
            userPosition.feeGrowth0 = poolPosition.feeGrowthGlobal0;
            userPosition.feeGrowth1 = poolPosition.feeGrowthGlobal1;
        } else {
            positions[tokenId] = Position({
                nonce: 0,
                pool: b.pool,
                liquidity: shares,
                feeGrowth0: poolPosition.feeGrowthGlobal0,
                feeGrowth1: poolPosition.feeGrowthGlobal1,
                tokensOwed0: 0,
                tokensOwed1: 0
            });
        }

        _checkDustAmount(
            b.pool,
            (b.amount0Base + b.amount0Range),
            (b.amount1Base + b.amount1Range),
            amount0Desired,
            amount1Desired
        );

        emit Deposited(b.pool, tokenId, amount0Desired, amount1Desired, shares);
    }

    /// @inheritdoc IUniswapLiquidityManager
    function withdraw(
        bool pilotToken,
        bool wethToken,
        uint256 liquidity,
        uint256 tokenId,
        bytes memory data
    ) external payable override onlyUnipilot nonReentrant {
        Position storage position = positions[tokenId];
        require(liquidity > 0);
        require(liquidity <= position.liquidity);
        WithdrawVars memory c;
        c.recipient = abi.decode(data, (address));

        (c.amount0Removed, c.amount1Removed) = _removeLiquidityUniswap(
            false,
            position.pool,
            liquidity
        );

        (c.userAmount0, c.userAmount1, c.pilotAmount) = _distributeFeesAndLiquidity(
            DistributeFeesParams({
                pilotToken: pilotToken,
                wethToken: wethToken,
                pool: position.pool,
                recipient: c.recipient,
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Removed: c.amount0Removed,
                amount1Removed: c.amount1Removed
            })
        );

        emit Withdrawn(
            position.pool,
            c.recipient,
            tokenId,
            c.amount0Removed,
            c.amount1Removed
        );
    }

    /// @inheritdoc IUniswapLiquidityManager
    function collect(
        bool pilotToken,
        bool wethToken,
        uint256 tokenId,
        bytes memory data
    ) external payable override onlyUnipilot nonReentrant {
        Position memory position = positions[tokenId];
        require(position.liquidity > 0);
        address recipient = abi.decode(data, (address));

        _collectPositionFees(position.pool);

        _distributeFeesAndLiquidity(
            DistributeFeesParams({
                pilotToken: pilotToken,
                wethToken: wethToken,
                pool: position.pool,
                recipient: recipient,
                tokenId: tokenId,
                liquidity: 0,
                amount0Removed: 0,
                amount1Removed: 0
            })
        );
    }

    /// @dev Returns the status of the vault that needs reabsing
    function shouldReadjust(
        address pool,
        int24 baseTickLower,
        int24 baseTickUpper
    ) public view returns (bool readjust) {
        (, , , , , , int24 currentTick, ) = getPoolDetails(pool);
        int24 threshold = IUniStrategy(unipilotProtocolDetails.uniStrategy)
            .getReadjustThreshold(pool);
        if (
            (currentTick < (baseTickLower + threshold)) ||
            (currentTick > (baseTickUpper - threshold))
        ) {
            readjust = true;
        } else {
            readjust = false;
        }
    }

    function getPoolDetails(address pool)
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint16 poolCardinality,
            uint128 liquidity,
            uint160 sqrtPriceX96,
            int24 currentTick,
            int24 tickSpacing
        )
    {
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        token0 = uniswapPool.token0();
        token1 = uniswapPool.token1();
        fee = uniswapPool.fee();
        liquidity = uniswapPool.liquidity();
        (sqrtPriceX96, currentTick, , poolCardinality, , , ) = uniswapPool.slot0();
        tickSpacing = uniswapPool.tickSpacing();
    }

    /// @notice burns all positions, collects any fees accrued and mints new base & range positions for vault.
    /// @dev This function can be called by anyone, also user gets the tx fees + premium on chain for readjusting the vault
    /// @dev Only those vaults are eligible for readjust incentive that have liquidity greater than 100,000 USD through Unipilot,
    /// @dev Pools can be readjust 2 times in 24 hrs (more than 2 requirement means pool is too volatile)
    /// @dev If all assets are converted in a single token then 2% amount will be swapped from vault total liquidity
    /// in order to add in range liquidity rather than waiting for price to come in range
    function readjustLiquidity(
        address token0,
        address token1,
        uint24 fee
    ) external {
        // @dev calculating the gas amount at the begining
        uint256 initialGas = gasleft();
        ReadjustVars memory b;

        b.poolAddress = getPoolAddress(token0, token1, fee);
        LiquidityPosition storage position = liquidityPositions[b.poolAddress];

        require(!readjustFrequencyStatus(b.poolAddress));
        require(
            shouldReadjust(b.poolAddress, position.baseTickLower, position.baseTickUpper)
        );

        position.timestamp = block.timestamp;

        (, , , , , b.sqrtPriceX96, , ) = getPoolDetails(b.poolAddress);
        (b.amount0, b.amount1) = _removeLiquidityUniswap(
            true,
            b.poolAddress,
            position.totalLiquidity
        );

        if ((b.amount0 == 0 || b.amount1 == 0)) {
            (b.zeroForOne, b.amountIn) = b.amount0 > 0
                ? (true, b.amount0)
                : (false, b.amount1);
            b.exactSqrtPriceImpact =
                (b.sqrtPriceX96 * (unipilotProtocolDetails.swapPriceThreshold / 2)) /
                1e6;
            b.sqrtPriceLimitX96 = b.zeroForOne
                ? b.sqrtPriceX96 - b.exactSqrtPriceImpact
                : b.sqrtPriceX96 + b.exactSqrtPriceImpact;

            b.amountIn = FullMath.mulDiv(
                b.amountIn,
                unipilotProtocolDetails.swapPercentage,
                100
            );

            (int256 amount0Delta, int256 amount1Delta) = IUniswapV3Pool(b.poolAddress)
                .swap(
                    address(this),
                    b.zeroForOne,
                    b.amountIn.toInt256(),
                    b.sqrtPriceLimitX96,
                    abi.encode(
                        (SwapCallbackData({ token0: token0, token1: token1, fee: fee }))
                    )
                );

            if (amount1Delta < 1) {
                amount1Delta = -amount1Delta;
                b.amount0 = b.amount0.sub(uint256(amount0Delta));
                b.amount1 = b.amount1.add(uint256(amount1Delta));
            } else {
                amount0Delta = -amount0Delta;
                b.amount0 = b.amount0.add(uint256(amount0Delta));
                b.amount1 = b.amount1.sub(uint256(amount1Delta));
            }
        }
        // @dev calculating new ticks for base & range positions
        Tick memory ticks;
        (
            ticks.baseTickLower,
            ticks.baseTickUpper,
            ticks.bidTickLower,
            ticks.bidTickUpper,
            ticks.rangeTickLower,
            ticks.rangeTickUpper
        ) = _getTicksFromUniStrategy(b.poolAddress);

        (b.baseLiquidity, b.amount0Added, b.amount1Added, ) = _addLiquidityUniswap(
            AddLiquidityParams({
                token0: token0,
                token1: token1,
                fee: fee,
                tickLower: ticks.baseTickLower,
                tickUpper: ticks.baseTickUpper,
                amount0Desired: b.amount0,
                amount1Desired: b.amount1
            })
        );

        (position.baseLiquidity, position.baseTickLower, position.baseTickUpper) = (
            b.baseLiquidity,
            ticks.baseTickLower,
            ticks.baseTickUpper
        );

        uint256 amount0Remaining = b.amount0.sub(b.amount0Added);
        uint256 amount1Remaining = b.amount1.sub(b.amount1Added);

        (uint128 bidLiquidity, , ) = LiquidityReserves.getLiquidityAmounts(
            ticks.bidTickLower,
            ticks.bidTickUpper,
            0,
            amount0Remaining,
            amount1Remaining,
            IUniswapV3Pool(b.poolAddress)
        );
        (uint128 rangeLiquidity, , ) = LiquidityReserves.getLiquidityAmounts(
            ticks.rangeTickLower,
            ticks.rangeTickUpper,
            0,
            amount0Remaining,
            amount1Remaining,
            IUniswapV3Pool(b.poolAddress)
        );

        // @dev adding bid or range order on Uniswap depending on which token is left
        if (bidLiquidity > rangeLiquidity) {
            (, b.amount0Range, b.amount1Range, ) = _addLiquidityUniswap(
                AddLiquidityParams({
                    token0: token0,
                    token1: token1,
                    fee: fee,
                    tickLower: ticks.bidTickLower,
                    tickUpper: ticks.bidTickUpper,
                    amount0Desired: amount0Remaining,
                    amount1Desired: amount1Remaining
                })
            );

            (
                position.rangeLiquidity,
                position.rangeTickLower,
                position.rangeTickUpper
            ) = (bidLiquidity, ticks.bidTickLower, ticks.bidTickUpper);
        } else {
            (, b.amount0Range, b.amount1Range, ) = _addLiquidityUniswap(
                AddLiquidityParams({
                    token0: token0,
                    token1: token1,
                    fee: fee,
                    tickLower: ticks.rangeTickLower,
                    tickUpper: ticks.rangeTickUpper,
                    amount0Desired: amount0Remaining,
                    amount1Desired: amount1Remaining
                })
            );
            (
                position.rangeLiquidity,
                position.rangeTickLower,
                position.rangeTickUpper
            ) = (rangeLiquidity, ticks.rangeTickLower, ticks.rangeTickUpper);
        }

        position.counter += 1;
        if (position.counter == 2) position.status = true;

        if (position.managed) {
            require(tx.gasprice <= unipilotProtocolDetails.gasPriceLimit);
            b.gasUsed = (tx.gasprice.mul(initialGas.sub(gasleft()))).add(
                unipilotProtocolDetails.premium
            );
            b.pilotAmount = IOracle(unipilotProtocolDetails.oracle).ethToAsset(
                PILOT,
                unipilotProtocolDetails.pilotWethPair,
                b.gasUsed
            );
            _mintPilot(msg.sender, b.pilotAmount);
        }

        _checkDustAmount(
            b.poolAddress,
            (b.amount0Added + b.amount0Range),
            (b.amount1Added + b.amount1Range),
            b.amount0,
            b.amount1
        );

        emit PoolReajusted(
            b.poolAddress,
            position.baseLiquidity,
            position.rangeLiquidity,
            position.baseTickLower,
            position.baseTickUpper,
            position.rangeTickLower,
            position.rangeTickUpper
        );
    }

    function emergencyExit(address recipient, bytes[10] memory data)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < data.length; ++i) {
            (
                address token,
                address pool,
                int24 tickLower,
                int24 tickUpper,
                uint128 liquidity
            ) = abi.decode(data[i], (address, address, int24, int24, uint128));

            if (pool != address(0)) {
                IUniswapV3Pool(pool).burn(tickLower, tickUpper, liquidity);

                IUniswapV3Pool(pool).collect(
                    recipient,
                    tickLower,
                    tickUpper,
                    MAX_UINT128,
                    MAX_UINT128
                );
            }

            uint256 balanceToken = IERC20(token).balanceOf(address(this));
            if (balanceToken > 0) {
                TransferHelper.safeTransfer(token, recipient, balanceToken);
            }
        }
    }

    /// @inheritdoc IUniswapLiquidityManager
    function updatePositionTotalAmounts(address _pool)
        public
        view
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalLiquidity
        )
    {
        LiquidityPosition memory position = liquidityPositions[_pool];
        if (position.totalLiquidity > 0) {
            return LiquidityPositions.getTotalAmounts(position, _pool);
        }
    }

    function getPoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) private view returns (address) {
        return IUniswapV3Factory(uniswapFactory).getPool(token0, token1, fee);
    }

    function _isUnipilot() private view {
        require(msg.sender == unipilotProtocolDetails.unipilot);
    }

    function _isGovernance() private view {
        require(msg.sender == IUnipilot(unipilotProtocolDetails.unipilot).governance());
    }

    function _mintPilot(address recipient, uint256 amount) private {
        IUnipilot(unipilotProtocolDetails.unipilot).mintPilot(recipient, amount);
    }

    /// @dev fetches the new ticks for base and range positions
    function _getTicksFromUniStrategy(address pool)
        private
        returns (
            int24 baseTickLower,
            int24 baseTickUpper,
            int24 bidTickLower,
            int24 bidTickUpper,
            int24 rangeTickLower,
            int24 rangeTickUpper
        )
    {
        return IUniStrategy(unipilotProtocolDetails.uniStrategy).getTicks(pool);
    }

    /// @dev checks the dust amount durnig deposit
    function _checkDustAmount(
        address pool,
        uint256 amount0Added,
        uint256 amount1Added,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) private {
        LiquidityPosition storage poolPosition = liquidityPositions[pool];
        uint256 dust0 = amount0Desired.sub(amount0Added);
        uint256 dust1 = amount1Desired.sub(amount1Added);

        if (dust0 > 0) {
            poolPosition.fees0 += dust0;
            poolPosition.feeGrowthGlobal0 += FullMath.mulDiv(
                dust0,
                FixedPoint128.Q128,
                poolPosition.totalLiquidity
            );
        }

        if (dust1 > 0) {
            poolPosition.fees1 += dust1;
            poolPosition.feeGrowthGlobal1 += FullMath.mulDiv(
                dust1,
                FixedPoint128.Q128,
                poolPosition.totalLiquidity
            );
        }
    }

    /// @dev Do zero-burns to poke a position on Uniswap so earned fees are
    /// updated. Should be called if total amounts needs to include up-to-date
    /// fees.
    function _updatePosition(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        IUniswapV3Pool pool
    ) private {
        if (liquidity > 0) {
            pool.burn(tickLower, tickUpper, 0);
        }
    }

    /// @notice Deposits user liquidity in a range order of Unipilot vault.
    /// @dev If the liquidity of vault is out of range then contract will add user liquidity in a range position
    /// of the vault, user liquidity gets in range as soon as vault will be rebase again by anyone
    /// @param pool Address of the uniswap pool
    /// @param amount0 The desired amount of token0 to be spent
    /// @param amount1 The desired amount of token1 to be spent,
    /// @param shares Amount of shares minted
    function _addRangeLiquidity(
        address pool,
        uint256 amount0,
        uint256 amount1,
        uint256 shares
    ) private returns (uint256 amount0Range, uint256 amount1Range) {
        RangeLiquidityVars memory b;
        (b.token0, b.token1, b.fee, , , , , ) = getPoolDetails(pool);
        LiquidityPosition storage position = liquidityPositions[pool];

        (b.rangeLiquidity, b.amount0Range, b.amount1Range, ) = _addLiquidityUniswap(
            AddLiquidityParams({
                token0: b.token0,
                token1: b.token1,
                fee: b.fee,
                tickLower: position.rangeTickLower,
                tickUpper: position.rangeTickUpper,
                amount0Desired: amount0,
                amount1Desired: amount1
            })
        );

        position.rangeLiquidity += b.rangeLiquidity;
        position.totalLiquidity += shares;
        (amount0Range, amount1Range) = (b.amount0Range, b.amount1Range);
    }

    /// @dev Deposits liquidity in a range on the UniswapV3 pool.
    /// @param params The params necessary to mint a position, encoded as `AddLiquidityParams`
    /// @return liquidity Amount of liquidity added in a range on UniswapV3
    /// @return amount0 Amount of token0 added in a range
    /// @return amount1 Amount of token1 added in a range
    /// @return pool Instance of the UniswapV3 pool
    function _addLiquidityUniswap(AddLiquidityParams memory params)
        private
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            IUniswapV3Pool pool
        )
    {
        pool = IUniswapV3Pool(getPoolAddress(params.token0, params.token1, params.fee));
        (liquidity, , ) = LiquidityReserves.getLiquidityAmounts(
            params.tickLower,
            params.tickUpper,
            0,
            params.amount0Desired,
            params.amount1Desired,
            pool
        );

        (amount0, amount1) = pool.mint(
            address(this),
            params.tickLower,
            params.tickUpper,
            liquidity,
            abi.encode(
                (
                    MintCallbackData({
                        payer: address(this),
                        token0: params.token0,
                        token1: params.token1,
                        fee: params.fee
                    })
                )
            )
        );
    }

    function _removeLiquiditySingle(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 liquiditySharePercentage,
        IUniswapV3Pool pool
    ) private returns (RemoveLiquidity memory removedLiquidity) {
        uint256 amount0;
        uint256 amount1;

        uint128 liquidityRemoved = _uint256ToUint128(
            FullMath.mulDiv(liquidity, liquiditySharePercentage, 1e18)
        );

        if (liquidity > 0) {
            (amount0, amount1) = pool.burn(tickLower, tickUpper, liquidityRemoved);
        }

        (uint256 collect0, uint256 collect1) = pool.collect(
            address(this),
            tickLower,
            tickUpper,
            MAX_UINT128,
            MAX_UINT128
        );

        removedLiquidity = RemoveLiquidity(
            amount0,
            amount1,
            liquidityRemoved,
            collect0.sub(amount0),
            collect1.sub(amount1)
        );
    }

    /// @dev Do zero-burns to poke a position on Uniswap so earned fees & feeGrowthGlobal of vault are updated
    function _collectPositionFees(address _pool) private {
        LiquidityPosition storage position = liquidityPositions[_pool];
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);

        _updatePosition(
            position.baseTickLower,
            position.baseTickUpper,
            position.baseLiquidity,
            pool
        );
        _updatePosition(
            position.rangeTickLower,
            position.rangeTickUpper,
            position.rangeLiquidity,
            pool
        );

        (uint256 collect0Base, uint256 collect1Base) = pool.collect(
            address(this),
            position.baseTickLower,
            position.baseTickUpper,
            MAX_UINT128,
            MAX_UINT128
        );

        (uint256 collect0Range, uint256 collect1Range) = pool.collect(
            address(this),
            position.rangeTickLower,
            position.rangeTickUpper,
            MAX_UINT128,
            MAX_UINT128
        );

        position.fees0 = position.fees0.add((collect0Base.add(collect0Range)));
        position.fees1 = position.fees1.add((collect1Base.add(collect1Range)));

        position.feeGrowthGlobal0 += FullMath.mulDiv(
            collect0Base + collect0Range,
            FixedPoint128.Q128,
            position.totalLiquidity
        );
        position.feeGrowthGlobal1 += FullMath.mulDiv(
            collect1Base + collect1Range,
            FixedPoint128.Q128,
            position.totalLiquidity
        );
    }

    /// @notice Increases the amount of liquidity in a base & range positions of the vault, with tokens paid by the sender
    /// @param pool Address of the uniswap pool
    /// @param amount0Desired The desired amount of token0 to be spent
    /// @param amount1Desired The desired amount of token1 to be spent,
    /// @param shares Amount of shares minted
    function _increaseLiquidity(
        address pool,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 shares
    )
        private
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range
        )
    {
        LiquidityPosition storage position = liquidityPositions[pool];
        IncreaseParams memory a;
        (a.token0, a.token1, a.fee, , , , a.currentTick, ) = getPoolDetails(pool);

        if (
            a.currentTick < position.baseTickLower ||
            a.currentTick > position.baseTickUpper
        ) {
            (amount0Range, amount1Range) = _addRangeLiquidity(
                pool,
                amount0Desired,
                amount1Desired,
                shares
            );
        } else {
            uint256 liquidityOffset = a.currentTick >= position.rangeTickLower &&
                a.currentTick <= position.rangeTickUpper
                ? 1
                : 0;
            (a.baseLiquidity, a.baseAmount0, a.baseAmount1, ) = _addLiquidityUniswap(
                AddLiquidityParams({
                    token0: a.token0,
                    token1: a.token1,
                    fee: a.fee,
                    tickLower: position.baseTickLower,
                    tickUpper: position.baseTickUpper,
                    amount0Desired: amount0Desired.sub(liquidityOffset),
                    amount1Desired: amount1Desired.sub(liquidityOffset)
                })
            );

            (a.rangeLiquidity, a.rangeAmount0, a.rangeAmount1, ) = _addLiquidityUniswap(
                AddLiquidityParams({
                    token0: a.token0,
                    token1: a.token1,
                    fee: a.fee,
                    tickLower: position.rangeTickLower,
                    tickUpper: position.rangeTickUpper,
                    amount0Desired: amount0Desired.sub(a.baseAmount0),
                    amount1Desired: amount1Desired.sub(a.baseAmount1)
                })
            );

            position.baseLiquidity += a.baseLiquidity;
            position.rangeLiquidity += a.rangeLiquidity;
            position.totalLiquidity += shares;
            (amount0Base, amount1Base) = (a.baseAmount0, a.baseAmount1);
            (amount0Range, amount1Range) = (a.rangeAmount0, a.rangeAmount1);
        }
    }

    /// @dev Two orders are placed - a base order and a range order. The base
    /// order is placed first with as much liquidity as possible. This order
    /// should use up all of one token, leaving only the other one. This excess
    /// amount is then placed as a single-sided bid or ask order.
    function _addLiquidityInManager(AddLiquidityManagerParams memory params)
        private
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range
        )
    {
        TokenDetails memory tokenDetails;
        (
            tokenDetails.token0,
            tokenDetails.token1,
            tokenDetails.fee,
            tokenDetails.poolCardinality,
            ,
            ,
            tokenDetails.currentTick,

        ) = getPoolDetails(params.pool);
        LiquidityPosition storage position = liquidityPositions[params.pool];

        if (position.totalLiquidity > 0) {
            (amount0Base, amount1Base, amount0Range, amount1Range) = _increaseLiquidity(
                params.pool,
                params.amount0Desired,
                params.amount1Desired,
                params.shares
            );
        } else {
            if (
                tokenDetails.poolCardinality <
                unipilotProtocolDetails.poolCardinalityDesired
            )
                IUniswapV3Pool(params.pool).increaseObservationCardinalityNext(
                    unipilotProtocolDetails.poolCardinalityDesired
                );

            // @dev calculate new ticks for base & range order
            Tick memory ticks;
            (
                ticks.baseTickLower,
                ticks.baseTickUpper,
                ticks.bidTickLower,
                ticks.bidTickUpper,
                ticks.rangeTickLower,
                ticks.rangeTickUpper
            ) = _getTicksFromUniStrategy(params.pool);

            if (position.baseTickLower != 0 && position.baseTickUpper != 0) {
                if (
                    tokenDetails.currentTick < position.baseTickLower ||
                    tokenDetails.currentTick > position.baseTickUpper
                ) {
                    (amount0Range, amount1Range) = _addRangeLiquidity(
                        params.pool,
                        params.amount0Desired,
                        params.amount1Desired,
                        params.shares
                    );
                }
            } else {
                (
                    tokenDetails.baseLiquidity,
                    tokenDetails.amount0Added,
                    tokenDetails.amount1Added,

                ) = _addLiquidityUniswap(
                    AddLiquidityParams({
                        token0: tokenDetails.token0,
                        token1: tokenDetails.token1,
                        fee: tokenDetails.fee,
                        tickLower: ticks.baseTickLower,
                        tickUpper: ticks.baseTickUpper,
                        amount0Desired: params.amount0Desired,
                        amount1Desired: params.amount1Desired
                    })
                );

                (
                    position.baseLiquidity,
                    position.baseTickLower,
                    position.baseTickUpper
                ) = (
                    tokenDetails.baseLiquidity,
                    ticks.baseTickLower,
                    ticks.baseTickUpper
                );
                {
                    uint256 amount0 = params.amount0Desired.sub(
                        tokenDetails.amount0Added
                    );
                    uint256 amount1 = params.amount1Desired.sub(
                        tokenDetails.amount1Added
                    );

                    (tokenDetails.bidLiquidity, , ) = LiquidityReserves
                        .getLiquidityAmounts(
                            ticks.bidTickLower,
                            ticks.bidTickUpper,
                            0,
                            amount0,
                            amount1,
                            IUniswapV3Pool(params.pool)
                        );
                    (tokenDetails.rangeLiquidity, , ) = LiquidityReserves
                        .getLiquidityAmounts(
                            ticks.rangeTickLower,
                            ticks.rangeTickUpper,
                            0,
                            amount0,
                            amount1,
                            IUniswapV3Pool(params.pool)
                        );

                    // adding bid or range order on Uniswap depending on which token is left
                    if (tokenDetails.bidLiquidity > tokenDetails.rangeLiquidity) {
                        (, amount0Range, amount1Range, ) = _addLiquidityUniswap(
                            AddLiquidityParams({
                                token0: tokenDetails.token0,
                                token1: tokenDetails.token1,
                                fee: tokenDetails.fee,
                                tickLower: ticks.bidTickLower,
                                tickUpper: ticks.bidTickUpper,
                                amount0Desired: amount0,
                                amount1Desired: amount1
                            })
                        );

                        (
                            position.rangeLiquidity,
                            position.rangeTickLower,
                            position.rangeTickUpper
                        ) = (
                            tokenDetails.bidLiquidity,
                            ticks.bidTickLower,
                            ticks.bidTickUpper
                        );
                        (amount0Base, amount1Base) = (
                            tokenDetails.amount0Added,
                            tokenDetails.amount1Added
                        );
                    } else {
                        (, amount0Range, amount1Range, ) = _addLiquidityUniswap(
                            AddLiquidityParams({
                                token0: tokenDetails.token0,
                                token1: tokenDetails.token1,
                                fee: tokenDetails.fee,
                                tickLower: ticks.rangeTickLower,
                                tickUpper: ticks.rangeTickUpper,
                                amount0Desired: amount0,
                                amount1Desired: amount1
                            })
                        );
                        (
                            position.rangeLiquidity,
                            position.rangeTickLower,
                            position.rangeTickUpper
                        ) = (
                            tokenDetails.rangeLiquidity,
                            ticks.rangeTickLower,
                            ticks.rangeTickUpper
                        );
                        (amount0Base, amount1Base) = (
                            tokenDetails.amount0Added,
                            tokenDetails.amount1Added
                        );
                    }
                }
                position.totalLiquidity = position.totalLiquidity.add(params.shares);
            }
        }
    }

    /// @notice Convert 100% fees of the user in PILOT and transfer it to user
    /// @dev token0 & token1 amount of user fees will be transfered to index fund
    /// @param _recipient The account that should receive the PILOT,
    /// @param _token0 The address of the token0 for a specific pool
    /// @param _token1 The address of the token0 for a specific pool
    /// @param _tokensOwed0 The uncollected amount of token0 fees to the user position as of the last computation
    /// @param _tokensOwed1 The uncollected amount of token1 fees to the user position as of the last computation
    function _distributeFeesInPilot(
        address _recipient,
        address _token0,
        address _token1,
        uint256 _tokensOwed0,
        uint256 _tokensOwed1,
        address _oracle0,
        address _oracle1
    ) private returns (uint256 _pilotAmount) {
        // if the incoming pair is weth pair then compute the amount
        // of PILOT w.r.t alt token amount and the weth amount
        uint256 _pilotAmountInitial = _token0 == WETH
            ? IOracle(unipilotProtocolDetails.oracle).getPilotAmountWethPair(
                _token1,
                _tokensOwed1,
                _tokensOwed0,
                _oracle1
            )
            : IOracle(unipilotProtocolDetails.oracle).getPilotAmountForTokens(
                _token0,
                _token1,
                _tokensOwed0,
                _tokensOwed1,
                _oracle0,
                _oracle1
            );

        _pilotAmount = FullMath.mulDiv(
            _pilotAmountInitial,
            unipilotProtocolDetails.userPilotPercentage,
            100
        );

        _mintPilot(_recipient, _pilotAmount);

        if (_tokensOwed0 > 0)
            TransferHelper.safeTransfer(
                _token0,
                unipilotProtocolDetails.indexFund,
                _tokensOwed0
            );
        if (_tokensOwed1 > 0)
            TransferHelper.safeTransfer(
                _token1,
                unipilotProtocolDetails.indexFund,
                _tokensOwed1
            );
    }

    /// @notice Distribute the maximum amount of fees after calculating the percentage of user & index fund
    /// @dev Total fees of user will be distributed in two parts i.e 98% will be transferred to user & remaining 2% to index fund
    /// @param wethToken Boolean if the user wants fees in WETH or ETH, always false if it is not weth/alt pair
    /// @param _recipient The account that should receive the PILOT,
    /// @param _token0 The address of the token0 for a specific pool
    /// @param _token1 The address of the token0 for a specific pool
    /// @param _tokensOwed0 The uncollected amount of token0 fees to the user position as of the last computation
    /// @param _tokensOwed1 The uncollected amount of token1 fees to the user position as of the last computation
    function _distributeFeesInTokens(
        bool wethToken,
        address _recipient,
        address _token0,
        address _token1,
        uint256 _tokensOwed0,
        uint256 _tokensOwed1
    ) private {
        (
            uint256 _indexAmount0,
            uint256 _indexAmount1,
            uint256 _userBalance0,
            uint256 _userBalance1
        ) = UserPositions.getUserAndIndexShares(
                _tokensOwed0,
                _tokensOwed1,
                unipilotProtocolDetails.feesPercentageIndexFund
            );

        if (_tokensOwed0 > 0) {
            if (_token0 == WETH && !wethToken) {
                IWETH9(WETH).withdraw(_userBalance0);
                TransferHelper.safeTransferETH(_recipient, _userBalance0);
            } else {
                TransferHelper.safeTransfer(_token0, _recipient, _userBalance0);
            }
            TransferHelper.safeTransfer(
                _token0,
                unipilotProtocolDetails.indexFund,
                _indexAmount0
            );
        }

        if (_tokensOwed1 > 0) {
            if (_token1 == WETH && !wethToken) {
                IWETH9(WETH).withdraw(_userBalance1);
                TransferHelper.safeTransferETH(_recipient, _userBalance1);
            } else {
                TransferHelper.safeTransfer(_token1, _recipient, _userBalance1);
            }
            TransferHelper.safeTransfer(
                _token1,
                unipilotProtocolDetails.indexFund,
                _indexAmount1
            );
        }
    }

    /// @notice Transfer the amount of liquidity to user which has been removed from base & range position of the vault
    /// @param _token0 The address of the token0 for a specific pool
    /// @param _token1 The address of the token1 for a specific pool
    /// @param wethToken Boolean whether to recieve liquidity in WETH or ETH (only valid for WETH/ALT pairs)
    /// @param _recipient The account that should receive the liquidity amounts
    /// @param amount0Removed The amount of token0 that has been removed from base & range positions
    /// @param amount1Removed The amount of token1 that has been removed from base & range positions
    function _transferLiquidity(
        address _token0,
        address _token1,
        bool wethToken,
        address _recipient,
        uint256 amount0Removed,
        uint256 amount1Removed
    ) private {
        if (_token0 == WETH || _token1 == WETH) {
            (
                address tokenAlt,
                uint256 altAmount,
                address tokenWeth,
                uint256 wethAmount
            ) = _token0 == WETH
                    ? (_token1, amount1Removed, _token0, amount0Removed)
                    : (_token0, amount0Removed, _token1, amount1Removed);

            if (wethToken) {
                if (amount0Removed > 0)
                    TransferHelper.safeTransfer(tokenWeth, _recipient, wethAmount);
                if (amount1Removed > 0)
                    TransferHelper.safeTransfer(tokenAlt, _recipient, altAmount);
            } else {
                if (wethAmount > 0) {
                    IWETH9(WETH).withdraw(wethAmount);
                    TransferHelper.safeTransferETH(_recipient, wethAmount);
                }
                if (altAmount > 0)
                    TransferHelper.safeTransfer(tokenAlt, _recipient, altAmount);
            }
        } else {
            if (amount0Removed > 0)
                TransferHelper.safeTransfer(_token0, _recipient, amount0Removed);
            if (amount1Removed > 0)
                TransferHelper.safeTransfer(_token1, _recipient, amount1Removed);
        }
    }

    function _distributeFeesAndLiquidity(DistributeFeesParams memory params)
        private
        returns (
            uint256 userAmount0,
            uint256 userAmount1,
            uint256 pilotAmount
        )
    {
        WithdrawTokenOwedParams memory a;
        LiquidityPosition storage position = liquidityPositions[params.pool];
        Position storage userPosition = positions[params.tokenId];
        (a.token0, a.token1, , , , , , ) = getPoolDetails(params.pool);

        (a.tokensOwed0, a.tokensOwed1) = UserPositions.getTokensOwedAmount(
            userPosition.feeGrowth0,
            userPosition.feeGrowth1,
            userPosition.liquidity,
            position.feeGrowthGlobal0,
            position.feeGrowthGlobal1
        );

        userPosition.tokensOwed0 += a.tokensOwed0;
        userPosition.tokensOwed1 += a.tokensOwed1;
        userPosition.feeGrowth0 = position.feeGrowthGlobal0;
        userPosition.feeGrowth1 = position.feeGrowthGlobal1;

        if (position.feesInPilot && params.pilotToken) {
            if (a.token0 == WETH || a.token1 == WETH) {
                (
                    address tokenAlt,
                    uint256 altAmount,
                    address altOracle,
                    address tokenWeth,
                    uint256 wethAmount,
                    address wethOracle
                ) = a.token0 == WETH
                        ? (
                            a.token1,
                            userPosition.tokensOwed1,
                            position.oracle1,
                            a.token0,
                            userPosition.tokensOwed0,
                            position.oracle0
                        )
                        : (
                            a.token0,
                            userPosition.tokensOwed0,
                            position.oracle0,
                            a.token1,
                            userPosition.tokensOwed1,
                            position.oracle1
                        );

                pilotAmount = _distributeFeesInPilot(
                    params.recipient,
                    tokenWeth,
                    tokenAlt,
                    wethAmount,
                    altAmount,
                    wethOracle,
                    altOracle
                );
            } else {
                pilotAmount = _distributeFeesInPilot(
                    params.recipient,
                    a.token0,
                    a.token1,
                    userPosition.tokensOwed0,
                    userPosition.tokensOwed1,
                    position.oracle0,
                    position.oracle1
                );
            }
        } else {
            _distributeFeesInTokens(
                params.wethToken,
                params.recipient,
                a.token0,
                a.token1,
                userPosition.tokensOwed0,
                userPosition.tokensOwed1
            );
        }

        _transferLiquidity(
            a.token0,
            a.token1,
            params.wethToken,
            params.recipient,
            params.amount0Removed,
            params.amount1Removed
        );

        (userAmount0, userAmount1) = (userPosition.tokensOwed0, userPosition.tokensOwed1);
        position.fees0 = position.fees0.sub(userPosition.tokensOwed0);
        position.fees1 = position.fees1.sub(userPosition.tokensOwed1);

        userPosition.tokensOwed0 = 0;
        userPosition.tokensOwed1 = 0;
        userPosition.liquidity = userPosition.liquidity.sub(params.liquidity);

        emit Collect(
            params.tokenId,
            userAmount0,
            userAmount1,
            pilotAmount,
            params.pool,
            params.recipient
        );
    }

    /// @notice Decreases the amount of liquidity (base and range positions) from Uniswap pool and collects all fees in the process.
    /// @dev Total liquidity of Unipilot vault won't decrease in readjust because same liquidity amount is added
    /// again in Uniswap, total liquidity will only decrease if user is withdrawing his share from vault
    /// @param isRebase Boolean for the readjust liquidity function for not decreasing the total liquidity of vault
    /// @param pool Address of the Uniswap pool
    /// @param liquidity Liquidity amount of vault to remove from Uniswap positions
    /// @return amount0Removed The amount of token0 removed from base & range positions
    /// @return amount1Removed The amount of token1 removed from base & range positions
    function _removeLiquidityUniswap(
        bool isRebase,
        address pool,
        uint256 liquidity
    ) private returns (uint256 amount0Removed, uint256 amount1Removed) {
        LiquidityPosition storage position = liquidityPositions[pool];
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);

        uint256 liquiditySharePercentage = FullMath.mulDiv(
            liquidity,
            1e18,
            position.totalLiquidity
        );

        RemoveLiquidity memory bl = _removeLiquiditySingle(
            position.baseTickLower,
            position.baseTickUpper,
            position.baseLiquidity,
            liquiditySharePercentage,
            uniswapPool
        );
        RemoveLiquidity memory rl = _removeLiquiditySingle(
            position.rangeTickLower,
            position.rangeTickUpper,
            position.rangeLiquidity,
            liquiditySharePercentage,
            uniswapPool
        );

        position.fees0 = position.fees0.add(bl.feesCollected0.add(rl.feesCollected0));
        position.fees1 = position.fees1.add(bl.feesCollected1.add(rl.feesCollected1));

        position.feeGrowthGlobal0 += FullMath.mulDiv(
            bl.feesCollected0 + rl.feesCollected0,
            FixedPoint128.Q128,
            position.totalLiquidity
        );
        position.feeGrowthGlobal1 += FullMath.mulDiv(
            bl.feesCollected1 + rl.feesCollected1,
            FixedPoint128.Q128,
            position.totalLiquidity
        );

        amount0Removed = bl.amount0.add(rl.amount0);
        amount1Removed = bl.amount1.add(rl.amount1);

        if (!isRebase) {
            position.totalLiquidity = position.totalLiquidity.sub(liquidity);
        }

        position.baseLiquidity = position.baseLiquidity - bl.liquidityRemoved;
        position.rangeLiquidity = position.rangeLiquidity - rl.liquidityRemoved;

        // @dev reseting the positions to initial state if total liquidity of vault gets zero
        /// in order to calculate the amounts correctly from getSharesAndAmounts
        if (position.totalLiquidity == 0) {
            (position.baseTickLower, position.baseTickUpper) = (0, 0);
            (position.rangeTickLower, position.rangeTickUpper) = (0, 0);
        }
    }

    /// @notice Verify that caller should be the address of a valid Uniswap V3 Pool
    /// @param token0 The contract address of token0
    /// @param token1 The contract address of token1
    /// @param fee Fee tier of the pool
    function _verifyCallback(
        address token0,
        address token1,
        uint24 fee
    ) private view {
        require(msg.sender == getPoolAddress(token0, token1, fee));
    }

    function _uint256ToUint128(uint256 value) private pure returns (uint128) {
        assert(value <= type(uint128).max);
        return uint128(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IUniStrategy {
    struct PoolStrategy {
        int24 baseThreshold;
        int24 rangeThreshold;
        int24 maxTwapDeviation;
        int24 readjustThreshold;
        uint32 twapDuration;
    }

    event StrategyUpdated(PoolStrategy oldStrategy, PoolStrategy newStrategy);
    event MaxTwapDeviationUpdated(int24 oldDeviation, int24 newDeviation);
    event BaseMultiplierUpdated(int24 oldMultiplier, int24 newMultiplier);
    event RangeMultiplierUpdated(int24 oldMultiplier, int24 newMultiplier);
    event PriceThresholdUpdated(uint24 oldThreshold, uint24 newThreshold);
    event SwapPercentageUpdated(uint8 oldPercentage, uint8 newPercentage);
    event TwapDurationUpdated(uint32 oldDuration, uint32 newDuration);

    function getTicks(address _pool)
        external
        returns (
            int24 baseLower,
            int24 baseUpper,
            int24 bidLower,
            int24 bidUpper,
            int24 askLower,
            int24 askUpper
        );

    function getReadjustThreshold(address _pool)
        external
        view
        returns (int24 readjustThreshold);

    function getTwap(address _pool) external view returns (int24);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IExchangeManager.sol";

interface IUnipilot {
    struct DepositVars {
        uint256 totalAmount0;
        uint256 totalAmount1;
        uint256 totalLiquidity;
        uint256 shares;
    }

    event ExchangeWhitelisted(address newExchange);
    event ExchangeStatus(address exchange, bool status);
    event GovernanceUpdated(address oldGovernance, address newGovernance);

    function governance() external view returns (address);

    function mintProxy() external view returns (address);

    function mintPilot(address recipient, uint256 amount) external;

    function deposit(IExchangeManager.DepositParams memory params, bytes memory data)
        external
        payable
        returns (uint256 amount0Added, uint256 amount1Added);

    function createPoolAndDeposit(
        IExchangeManager.DepositParams memory params,
        bytes[2] calldata data
    )
        external
        payable
        returns (
            uint256 amount0Added,
            uint256 amount1Added,
            uint256 mintedTokenId
        );

    function exchangeManagerWhitelist(address exchange) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IULMEvents.sol";

interface IUniswapLiquidityManager is IULMEvents {
    struct LiquidityPosition {
        // base order position
        int24 baseTickLower;
        int24 baseTickUpper;
        uint128 baseLiquidity;
        // range order position
        int24 rangeTickLower;
        int24 rangeTickUpper;
        uint128 rangeLiquidity;
        // accumulated fees
        uint256 fees0;
        uint256 fees1;
        uint256 feeGrowthGlobal0;
        uint256 feeGrowthGlobal1;
        // total liquidity
        uint256 totalLiquidity;
        // pool premiums
        bool feesInPilot;
        // oracle address for tokens to fetch prices from
        address oracle0;
        address oracle1;
        // rebase
        uint256 timestamp;
        uint8 counter;
        bool status;
        bool managed;
    }

    struct Position {
        uint256 nonce;
        address pool;
        uint256 liquidity;
        uint256 feeGrowth0;
        uint256 feeGrowth1;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    struct ReadjustVars {
        bool zeroForOne;
        address poolAddress;
        int24 currentTick;
        uint160 sqrtPriceX96;
        uint160 exactSqrtPriceImpact;
        uint160 sqrtPriceLimitX96;
        uint128 baseLiquidity;
        uint256 amount0;
        uint256 amount1;
        uint256 amountIn;
        uint256 amount0Added;
        uint256 amount1Added;
        uint256 amount0Range;
        uint256 amount1Range;
        uint256 currentTimestamp;
        uint256 gasUsed;
        uint256 pilotAmount;
    }

    struct VarsEmerency {
        address token;
        address pool;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    struct WithdrawVars {
        address recipient;
        uint256 amount0Removed;
        uint256 amount1Removed;
        uint256 userAmount0;
        uint256 userAmount1;
        uint256 pilotAmount;
    }

    struct WithdrawTokenOwedParams {
        address token0;
        address token1;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    struct MintCallbackData {
        address payer;
        address token0;
        address token1;
        uint24 fee;
    }

    struct UnipilotProtocolDetails {
        uint8 swapPercentage;
        uint24 swapPriceThreshold;
        uint256 premium;
        uint256 gasPriceLimit;
        uint256 userPilotPercentage;
        uint256 feesPercentageIndexFund;
        uint24 readjustFrequencyTime;
        uint16 poolCardinalityDesired;
        address pilotWethPair;
        address oracle;
        address indexFund; // 10%
        address uniStrategy;
        address unipilot;
    }

    struct SwapCallbackData {
        address token0;
        address token1;
        uint24 fee;
    }

    struct AddLiquidityParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }

    struct RemoveLiquidity {
        uint256 amount0;
        uint256 amount1;
        uint128 liquidityRemoved;
        uint256 feesCollected0;
        uint256 feesCollected1;
    }

    struct Tick {
        int24 baseTickLower;
        int24 baseTickUpper;
        int24 bidTickLower;
        int24 bidTickUpper;
        int24 rangeTickLower;
        int24 rangeTickUpper;
    }

    struct TokenDetails {
        address token0;
        address token1;
        uint24 fee;
        int24 currentTick;
        uint16 poolCardinality;
        uint128 baseLiquidity;
        uint128 bidLiquidity;
        uint128 rangeLiquidity;
        uint256 amount0Added;
        uint256 amount1Added;
    }

    struct DistributeFeesParams {
        bool pilotToken;
        bool wethToken;
        address pool;
        address recipient;
        uint256 tokenId;
        uint256 liquidity;
        uint256 amount0Removed;
        uint256 amount1Removed;
    }

    struct AddLiquidityManagerParams {
        address pool;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 shares;
    }

    struct DepositVars {
        uint24 fee;
        address pool;
        uint256 amount0Base;
        uint256 amount1Base;
        uint256 amount0Range;
        uint256 amount1Range;
    }

    struct RangeLiquidityVars {
        address token0;
        address token1;
        uint24 fee;
        uint128 rangeLiquidity;
        uint256 amount0Range;
        uint256 amount1Range;
    }

    struct IncreaseParams {
        address token0;
        address token1;
        uint24 fee;
        int24 currentTick;
        uint128 baseLiquidity;
        uint256 baseAmount0;
        uint256 baseAmount1;
        uint128 rangeLiquidity;
        uint256 rangeAmount0;
        uint256 rangeAmount1;
    }

    /// @notice Pull in tokens from sender. Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay to the pool for the minted liquidity.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;

    /// @notice Called to `msg.sender` after minting swaping from IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay to the pool for swap.
    /// @param amount0Delta The amount of token0 due to the pool for the swap
    /// @param amount1Delta The amount of token1 due to the pool for the swap
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;

    /// @notice Returns the user position information associated with a given token ID.
    /// @param tokenId The ID of the token that represents the position
    /// @return Position
    /// - nonce The nonce for permits
    /// - pool Address of the uniswap V3 pool
    /// - liquidity The liquidity of the position
    /// - feeGrowth0 The fee growth of token0 as of the last action on the individual position
    /// - feeGrowth1 The fee growth of token1 as of the last action on the individual position
    /// - tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// - tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function userPositions(uint256 tokenId) external view returns (Position memory);

    /// @notice Returns the vault information of unipilot base & range orders
    /// @param pool Address of the Uniswap pool
    /// @return LiquidityPosition
    /// - baseTickLower The lower tick of the base position
    /// - baseTickUpper The upper tick of the base position
    /// - baseLiquidity The total liquidity of the base position
    /// - rangeTickLower The lower tick of the range position
    /// - rangeTickUpper The upper tick of the range position
    /// - rangeLiquidity The total liquidity of the range position
    /// - fees0 Total amount of fees collected by unipilot positions in terms of token0
    /// - fees1 Total amount of fees collected by unipilot positions in terms of token1
    /// - feeGrowthGlobal0 The fee growth of token0 collected per unit of liquidity for
    /// the entire life of the unipilot vault
    /// - feeGrowthGlobal1 The fee growth of token1 collected per unit of liquidity for
    /// the entire life of the unipilot vault
    /// - totalLiquidity Total amount of liquidity of vault including base & range orders
    function poolPositions(address pool) external view returns (LiquidityPosition memory);

    /// @notice Calculates the vault's total holdings of token0 and token1 - in
    /// other words, how much of each token the vault would hold if it withdrew
    /// all its liquidity from Uniswap.
    /// @param _pool Address of the uniswap pool
    /// @return amount0 Total amount of token0 in vault
    /// @return amount1 Total amount of token1 in vault
    /// @return totalLiquidity Total liquidity of the vault
    function updatePositionTotalAmounts(address _pool)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalLiquidity
        );

    /// @notice Calculates the vault's total holdings of TOKEN0 and TOKEN1 - in
    /// other words, how much of each token the vault would hold if it withdrew
    /// all its liquidity from Uniswap.
    /// @dev Updates the position and return the latest reserves & liquidity.
    /// @param token0 token0 of the pool
    /// @param token0 token1 of the pool
    /// @param data any necessary data needed to get reserves
    /// @return totalAmount0 Amount of token0 in the pool of unipilot
    /// @return totalAmount1 Amount of token1 in the pool of unipilot
    /// @return totalLiquidity Total liquidity available in unipilot pool
    function getReserves(
        address token0,
        address token1,
        bytes calldata data
    )
        external
        returns (
            uint256 totalAmount0,
            uint256 totalAmount1,
            uint256 totalLiquidity
        );

    /// @notice Creates a new pool & then initializes the pool
    /// @param _token0 The contract address of token0 of the pool
    /// @param _token1 The contract address of token1 of the pool
    /// @param data Necessary data needed to create pool
    /// In data we will provide the `fee` amount of the v3 pool for the specified token pair,
    /// also `sqrtPriceX96` The initial square root price of the pool
    /// @return _pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address
    function createPair(
        address _token0,
        address _token1,
        bytes memory data
    ) external returns (address _pool);

    /// @notice Deposits tokens in proportion to the Unipilot's current ticks, mints them
    /// `Unipilot`s NFT.
    /// @param token0 The first of the two tokens of the pool, sorted by address
    /// @param token1 The second of the two tokens of the pool, sorted by address
    /// @param amount0Desired Max amount of token0 to deposit
    /// @param amount1Desired Max amount of token1 to deposit
    /// @param shares Number of shares minted
    /// @param tokenId Token Id of Unipilot
    /// @param isTokenMinted Boolean to check the minting of new tokenId of Unipilot
    /// @param data Necessary data needed to deposit
    function deposit(
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 shares,
        uint256 tokenId,
        bool isTokenMinted,
        bytes memory data
    ) external payable;

    /// @notice withdraws the desired shares from the vault with accumulated user fees and transfers to recipient.
    /// @param pilotToken whether to recieve fees in PILOT or not (valid if user is not reciving fees in token0, token1)
    /// @param wethToken whether to recieve fees in WETH or ETH (only valid for WETH/ALT pairs)
    /// @param liquidity The amount by which liquidity will be withdrawn
    /// @param tokenId The ID of the token for which liquidity is being withdrawn
    /// @param data Necessary data needed to withdraw liquidity from Unipilot
    function withdraw(
        bool pilotToken,
        bool wethToken,
        uint256 liquidity,
        uint256 tokenId,
        bytes memory data
    ) external payable;

    /// @notice Collects up to a maximum amount of fees owed to a specific user position to the recipient
    /// @dev User have both options whether to recieve fees in PILOT or in pool token0 & token1
    /// @param pilotToken whether to recieve fees in PILOT or not (valid if user is not reciving fees in token0, token1)
    /// @param wethToken whether to recieve fees in WETH or ETH (only valid for WETH/ALT pairs)
    /// @param tokenId The ID of the Unpilot NFT for which tokens will be collected
    /// @param data Necessary data needed to collect fees from Unipilot
    function collect(
        bool pilotToken,
        bool wethToken,
        uint256 tokenId,
        bytes memory data
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IOracle {
    event UniStrategyUpdated(address oldStrategy, address newStrategy);
    event GovernanceUpdated(address governance, address _governance);

    function getPilotAmountForTokens(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address oracle0,
        address oracle1
    ) external view returns (uint256 total);

    function getPilotAmountWethPair(
        address tokenAlt,
        uint256 altAmount,
        uint256 wethAmount,
        address altOracle
    ) external view returns (uint256 amount);

    function getPilotAmount(
        address token,
        uint256 amount,
        address pool
    ) external view returns (uint256 pilotAmount);

    function assetToEth(
        address token,
        address pool,
        uint256 amountIn
    ) external view returns (uint256 ethAmountOut);

    function ethToAsset(
        address tokenOut,
        address pool,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getPrice(
        address tokenA,
        address tokenB,
        address pool,
        uint256 _amountIn
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./PositionKey.sol";
import "./LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityReserves {
    function getLiquidityAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDesired,
        uint256 amount0Desired,
        uint256 amount1Desired,
        IUniswapV3Pool pool
    )
        internal
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        if (liquidityDesired > 0) {
            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidityDesired
            );
        } else {
            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0Desired,
                amount1Desired
            );
        }
    }

    function getPositionTokenAmounts(
        int24 tickLower,
        int24 tickUpper,
        IUniswapV3Pool pool,
        uint128 liquidity
    ) internal view returns (uint256 amount0, uint256 amount1) {
        (, amount0, amount1) = LiquidityReserves.getLiquidityAmounts(
            tickLower,
            tickUpper,
            liquidity,
            0,
            0,
            pool
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import "./PositionKey.sol";
import "./LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../interfaces/uniswap/IUniswapLiquidityManager.sol";
import "./LiquidityReserves.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";

// import "./LowGasSafeMath.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityPositions {
    using LowGasSafeMath for uint256;

    struct Vars {
        int24 baseTickLower;
        int24 baseTickUpper;
        int24 rangeTickLower;
        int24 rangeTickUpper;
        uint256 fees0;
        uint256 fees1;
        uint256 totalLiquidity;
        uint256 baseAmount0;
        uint256 baseAmount1;
        uint256 rangeAmount0;
        uint256 rangeAmount1;
    }

    function getTotalAmounts(
        IUniswapLiquidityManager.LiquidityPosition memory self,
        address pool
    )
        internal
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalLiquidity
        )
    {
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        Vars memory localVars;

        (localVars.baseAmount0, localVars.baseAmount1) = LiquidityReserves
            .getPositionTokenAmounts(
                self.baseTickLower,
                self.baseTickUpper,
                uniswapPool,
                self.baseLiquidity
            );
        (localVars.rangeAmount0, localVars.rangeAmount1) = LiquidityReserves
            .getPositionTokenAmounts(
                self.rangeTickLower,
                self.rangeTickUpper,
                uniswapPool,
                self.rangeLiquidity
            );

        amount0 = localVars.baseAmount0.add(localVars.rangeAmount0);
        amount1 = localVars.baseAmount1.add(localVars.rangeAmount1);
        totalLiquidity = self.totalLiquidity;
    }

    function getPoolDetails(address pool)
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint16 poolCardinality,
            uint128 liquidity,
            uint160 sqrtPriceX96,
            int24 currentTick
        )
    {
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        token0 = uniswapPool.token0();
        token1 = uniswapPool.token1();
        fee = uniswapPool.fee();
        liquidity = uniswapPool.liquidity();
        (sqrtPriceX96, currentTick, , poolCardinality, , , ) = uniswapPool.slot0();
    }

    function shouldReadjust(
        address pool,
        int24 baseTickLower,
        int24 baseTickUpper
    ) internal view returns (bool readjust) {
        int24 tickSpacing = 0;
        (, , , , , , int24 currentTick) = getPoolDetails(pool);
        int24 threshold = tickSpacing; // will increase thershold for mainnet to 1200
        if (
            (currentTick < (baseTickLower + threshold)) ||
            (currentTick > (baseTickUpper - threshold))
        ) {
            readjust = true;
        } else {
            readjust = false;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "../interfaces/uniswap/IUniswapLiquidityManager.sol";
import "./FixedPoint128.sol";

// import "./LowGasSafeMath.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library UserPositions {
    using LowGasSafeMath for uint256;

    function getTokensOwedAmount(
        uint256 feeGrowth0,
        uint256 feeGrowth1,
        uint256 liquidity,
        uint256 feeGrowthGlobal0,
        uint256 feeGrowthGlobal1
    ) internal pure returns (uint256 tokensOwed0, uint256 tokensOwed1) {
        tokensOwed0 = FullMath.mulDiv(
            feeGrowthGlobal0.sub(feeGrowth0),
            liquidity,
            FixedPoint128.Q128
        );
        tokensOwed1 = FullMath.mulDiv(
            feeGrowthGlobal1.sub(feeGrowth1),
            liquidity,
            FixedPoint128.Q128
        );
    }

    function getUserAndIndexShares(
        uint256 tokensOwed0,
        uint256 tokensOwed1,
        uint256 feesPercentageIndexFund
    )
        internal
        pure
        returns (
            uint256 indexAmount0,
            uint256 indexAmount1,
            uint256 userAmount0,
            uint256 userAmount1
        )
    {
        indexAmount0 = FullMath.mulDiv(tokensOwed0, feesPercentageIndexFund, 100);
        indexAmount1 = FullMath.mulDiv(tokensOwed1, feesPercentageIndexFund, 100);

        userAmount0 = tokensOwed0.sub(indexAmount0);
        userAmount1 = tokensOwed1.sub(indexAmount1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import "../interfaces/external/IWETH9.sol";
import "../libraries/TransferHelper.sol";

abstract contract PeripheryPayments {
    address internal constant PILOT = 0x37C997B35C619C21323F3518B9357914E8B99525;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    receive() external payable {}

    fallback() external payable {}

    /// @notice Transfers the full amount of a token held by this contract to recipient (In case of Emergency transfer tokens out of vault)
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) internal {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "IT");
        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) internal {
        uint256 balanceWETH9 = IWETH9(WETH).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, "IW");

        if (balanceWETH9 > 0) {
            IWETH9(WETH).withdraw(balanceWETH9);
            TransferHelper.safeTransferETH(recipient, balanceWETH9);
        }
    }

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() internal {
        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH9
            IWETH9(WETH).deposit{ value: value }(); // wrap only what is needed to pay
            IWETH9(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

/// @notice IExchangeManager is a generalized interface for all the liquidity managers
/// @dev Contains all necessary methods that should be available in liquidity manager contracts
interface IExchangeManager {
    struct DepositParams {
        address recipient;
        address exchangeManagerAddress;
        address token0;
        address token1;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 tokenId;
    }

    struct WithdrawParams {
        bool pilotToken;
        bool wethToken;
        address exchangeManagerAddress;
        uint256 liquidity;
        uint256 tokenId;
    }

    struct CollectParams {
        bool pilotToken;
        bool wethToken;
        address exchangeManagerAddress;
        uint256 tokenId;
    }

    function createPair(
        address _token0,
        address _token1,
        bytes calldata data
    ) external;

    function deposit(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 shares,
        uint256 tokenId,
        bool isTokenMinted,
        bytes calldata data
    ) external payable;

    function withdraw(
        bool pilotToken,
        bool wethToken,
        uint256 liquidity,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function getReserves(
        address token0,
        address token1,
        bytes calldata data
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    function collect(
        bool pilotToken,
        bool wethToken,
        uint256 tokenId,
        bytes calldata data
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;

interface IULMEvents {
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address indexed pool,
        uint24 fee,
        uint160 sqrtPriceX96
    );

    event PoolReajusted(
        address pool,
        uint128 baseLiquidity,
        uint128 rangeLiquidity,
        int24 newBaseTickLower,
        int24 newBaseTickUpper,
        int24 newRangeTickLower,
        int24 newRangeTickUpper
    );

    event Deposited(
        address indexed pool,
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );

    event Collect(
        uint256 tokenId,
        uint256 userAmount0,
        uint256 userAmount1,
        uint256 pilotAmount,
        address pool,
        address recipient
    );

    event Withdrawn(
        address indexed pool,
        address indexed recipient,
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/external/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "STE");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IERC20Permit.sol";

interface IERC20 is IERC20Permit {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 value) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}