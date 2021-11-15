// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./VanillaV1Token02.sol";
import "./VanillaV1Uniswap02.sol";
import "./VanillaV1Migration01.sol";
import "./VanillaV1Safelist01.sol";
import "./interfaces/v1/VanillaV1API01.sol";
import "./interfaces/IVanillaV1Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVanillaV1MigrationTarget02.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @dev Needed functions from the WETH contract originally deployed in https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function balanceOf(address owner) external returns (uint256);
}

/// @title Entry point API for Vanilla trading router
contract VanillaV1Router02 is VanillaV1Uniswap02, IVanillaV1Router02 {
    /// @inheritdoc IVanillaV1Router02
    uint256 public immutable override epoch;

    /// @inheritdoc IVanillaV1Router02
    IVanillaV1Token02 public immutable override vnlContract;

    /// @inheritdoc IVanillaV1Router02
    mapping(address => mapping(address => PriceData)) public override tokenPriceData;
    IVanillaV1Safelist01 immutable public override safeList;

    // adopted from @openzeppelin/contracts/security/ReentrancyGuard.sol, modifying because we need to access the status variable
    uint256 private constant NOT_EXECUTING = 1;
    uint256 private constant EXECUTING = 2;
    uint256 private executingStatus; // make sure to set this NOT_EXECUTING in constructor

    /**
        @notice Deploys the contract and the VanillaGovernanceToken contract.
        @dev initializes the token contract for safe reference and sets the epoch for reward calculations
        @param _peripheryState The address of UniswapRouter contract
        @param _v1temp The address of Vanilla v1 contract
    */
    constructor(
        IPeripheryImmutableState _peripheryState,
        VanillaV1API01 _v1temp
    ) VanillaV1Uniswap02(_peripheryState) {
        VanillaV1API01 v1 = VanillaV1API01(_v1temp);

        address vanillaDAO = msg.sender;
        address v1Token01 = v1.vnlContract();

        VanillaV1Token02 tokenContract = new VanillaV1Token02(
            new VanillaV1MigrationState({migrationOwner: vanillaDAO}),
            v1Token01);
        tokenContract.mint(vanillaDAO, calculateTreasuryShare(IERC20(v1Token01).totalSupply()));

        vnlContract = tokenContract;
        epoch = v1.epoch();
        safeList = new VanillaV1Safelist01({safeListOwner: vanillaDAO});
        executingStatus = NOT_EXECUTING;
    }

    function calculateTreasuryShare(uint256 existingVNLSupply) private pure returns (uint256) {
        /// assuming that 100% of current total VNL v1 supply will be converted to VNL v1.1, the calculated treasury share will be
        /// 15% of current total supply:
        /// treasuryShare = existingVNLSupply / (100% - 15%) - existingVNLSupply
        ///               = existingVNLSupply / ( 85 / 100 ) - existingVNLSupply
        ///               = existingVNLSupply * 100 / 85 - existingVNLSupply
        return (existingVNLSupply * 100 / 85) - existingVNLSupply;
    }

    function isTokenRewarded(address token) internal view returns (bool) {
        return safeList.isSafelisted(token);
    }

    modifier beforeDeadline(uint256 deadline) {
        if (deadline < block.timestamp) {
            revert TradeExpired();
        }
        _;
    }

    /// @dev Returns `defaultHolder` if `order.wethOwner` is unspecified
    function verifyWETHAccount (OrderData calldata order) view internal returns (address) {
        if (order.useWETH) {
            return msg.sender;
        }
        return address(this);
    }

    function validateTradeOrderSafety(OrderData calldata order) internal view {
        // we need to do couple of checks if calling the `buy` or `sell` function directly (i.e. not by `execute` or `executePayable`)
        if (executingStatus == NOT_EXECUTING) {
            // if we'd accept value, then it would just get locked into contract (all WETH wrapping happens in
            // `executePayable`) until anybody calls `withdrawAndRefund` (via `execute` or `executePayable`) to get them
            if (msg.value > 0) {
                revert UnauthorizedValueSent();
            }
            // if we'd allow wethHoldingAccount to be this contract,
            // - a buy would always fail because the contract doesn't keep WETHs in the balance
            // - a sell would result in WETHs locked into the contract (all WETH unwrapping and ether sending happens in
            // `withdrawAndRefund` via `multicall`)
            if (!order.useWETH) {
                revert InvalidWethAccount();
            }
        }
    }

    /// @inheritdoc IVanillaV1Router02
    function buy( OrderData calldata buyOrder ) external override payable beforeDeadline(buyOrder.blockTimeDeadline) {
        address wethSource = verifyWETHAccount(buyOrder);
        validateTradeOrderSafety(buyOrder);
        _executeBuy(msg.sender, wethSource, buyOrder);
    }

    function _executeBuy(
        address owner,
        address currentWETHHolder,
        OrderData calldata buyOrder
    ) internal {
        address token = buyOrder.token;
        uint256 numEth = buyOrder.numEth;
        // don't use getPositionData()
        PriceData storage prices = tokenPriceData[owner][token];
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        updateLatestBlock(prices);

        // do the swap and update price data
        uint256 tokens = _buy(token, numEth, buyOrder.numToken, currentWETHHolder, buyOrder.fee);
        prices.ethSum = uint112(uint(prices.ethSum) + numEth);
        prices.tokenSum = uint112(uint(prices.tokenSum) + tokens);
        prices.weightedBlockSum = prices.weightedBlockSum + (block.number * tokens);
        emit TokensPurchased(owner, token, numEth, tokens);
    }

    /**
        @dev Receives the ether only from WETH contract during withdraw()
     */
    receive() external payable {
        // make sure that router accepts ETH only from WETH contract
        assert(msg.sender == _wethAddr);
    }

    function multicall(address payable caller, bytes[] calldata data) internal returns (bytes[] memory results) {
        // adopted from @openzeppelin/contracts/utils/Multicall.sol, made it internal to enable safe payability
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        withdrawAndRefundWETH(caller);
        return results;
    }

    function withdrawAndRefundWETH(address payable recipient) internal {
        IWETH weth = IWETH(_wethAddr);
        uint256 balance = weth.balanceOf(address(this));
        if (balance > 0) {
            weth.withdraw(balance);
        }

        uint256 etherBalance = address(this).balance;
        if (etherBalance > 0) {
            Address.sendValue(recipient, etherBalance);
        }

    }

    modifier noNestedExecute () {
        require(executingStatus == NOT_EXECUTING);
        executingStatus = EXECUTING;
        _;
        executingStatus = NOT_EXECUTING;

    }

    function execute(bytes[] calldata data) external override noNestedExecute returns (bytes[] memory results) {
        results = multicall(payable(msg.sender), data);

    }

    function executePayable(bytes[] calldata data) external payable override noNestedExecute returns (bytes[] memory results) {
        if (msg.value > 0) {
            IWETH weth = IWETH(_wethAddr);
            weth.deposit{value: msg.value}();
        }
        results = multicall(payable(msg.sender), data);
    }

    /// @inheritdoc IVanillaV1Router02
    function sell(OrderData calldata sellOrder) external override payable beforeDeadline(sellOrder.blockTimeDeadline) {
        address wethRecipient = verifyWETHAccount(sellOrder);
        validateTradeOrderSafety(sellOrder);
        _executeSell(msg.sender, wethRecipient, sellOrder);
    }

    function updateLatestBlock(PriceData storage position) internal {
        if (position.latestBlock >= block.number) {
            revert TooManyTradesPerBlock();
        }
        position.latestBlock = uint32(block.number);
    }


    function recalculateAfterSwap(uint256 numToken, PriceData memory position, RewardParams memory rewardParams) internal view returns (
            PriceData memory positionAfter, TradeResult memory result, uint256 avgBlock) {

        avgBlock = position.weightedBlockSum / position.tokenSum;
        result.profitablePrice = numToken * position.ethSum / position.tokenSum;

        uint256 newTokenSum = position.tokenSum - numToken;

        result.price = rewardParams.numEth;
        // this can be 0 when pool is not initialized
        if (rewardParams.averagePeriodInSeconds > 0) {
            result.twapPeriodInSeconds = rewardParams.averagePeriodInSeconds;
            result.maxProfitablePrice = rewardParams.expectedAvgEth;
            uint256 twapPeriodWeightedPrice = (result.profitablePrice * (MAX_TWAP_PERIOD - rewardParams.averagePeriodInSeconds) + rewardParams.expectedAvgEth * rewardParams.averagePeriodInSeconds) / MAX_TWAP_PERIOD;
            uint256 rewardablePrice = Math.min(
                rewardParams.numEth,
                twapPeriodWeightedPrice
            );
            result.rewardableProfit = rewardablePrice > result.profitablePrice
                ? rewardablePrice - result.profitablePrice
                : 0;

            result.reward = _calculateReward(
                epoch,
                avgBlock,
                block.number,
                result.rewardableProfit
            );
        }

        positionAfter.ethSum = uint112(_proportionOf(
            position.ethSum,
            newTokenSum,
            position.tokenSum
        ));
        positionAfter.weightedBlockSum = _proportionOf(
            position.weightedBlockSum,
            newTokenSum,
            position.tokenSum
        );
        positionAfter.tokenSum = uint112(newTokenSum);

    }

    function _executeSell(
        address owner,
        address recipient,
        OrderData calldata sellOrder
    ) internal returns (uint256) {
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        // ownership verified in `getVerifiedPositionData`
        PriceData storage prices = getVerifiedPositionData(owner, sellOrder.token);
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        updateLatestBlock(prices);


        if (sellOrder.numToken > prices.tokenSum) {
            revert TokenBalanceExceeded(sellOrder.numToken, prices.tokenSum);
        }
        // do the swap, calculate the profit and update price data
        RewardParams memory rewardParams = _sell(sellOrder.token, sellOrder.numToken, sellOrder.numEth, sellOrder.fee, recipient);

        (PriceData memory changedPosition, TradeResult memory result,) = recalculateAfterSwap(sellOrder.numToken, prices, rewardParams);

        prices.tokenSum = changedPosition.tokenSum;
        prices.weightedBlockSum = changedPosition.weightedBlockSum;
        prices.ethSum = changedPosition.ethSum;
        // prices.latestBlock has been already updated  in `updateLatestBlock(PriceData storage)`

        if (result.reward > 0 && isTokenRewarded(sellOrder.token)) {
            // mint tokens if eligible for reward
            vnlContract.mint(msg.sender, result.reward);
        }

        emit TokensSold(
            owner,
            sellOrder.token,
            sellOrder.numToken,
            rewardParams.numEth,
            calculateRealProfit(result),
            result.reward
        );
        return rewardParams.numEth;
    }

    function calculateRealProfit(TradeResult memory result) internal pure returns (uint256 profit) {
        return result.price > result.profitablePrice ? result.price - result.profitablePrice : 0;
    }

    /// @inheritdoc IVanillaV1Router02
    function estimateReward(
        address owner,
        address token,
        uint256 numEth,
        uint256 numTokensSold
    )
        external
        view
        override
        returns (
            uint256 avgBlock,
            uint256 htrs,
            RewardEstimate memory estimate
        )
    {
        // ownership verified in `getPositionData`
        PriceData memory prices = getVerifiedPositionData(owner, token);

        {
            RewardParams memory lowFeeEstimate = estimateRewardParams(token, numTokensSold, 500);
            lowFeeEstimate.numEth = numEth;
            (, estimate.low, avgBlock) = recalculateAfterSwap(numTokensSold, prices, lowFeeEstimate);
        }

        {
            RewardParams memory mediumFeeEstimate = estimateRewardParams(token, numTokensSold, 3000);
            mediumFeeEstimate.numEth = numEth;
            (, estimate.medium,) = recalculateAfterSwap(numTokensSold, prices, mediumFeeEstimate);
        }

        {
            RewardParams memory highFeeEstimate = estimateRewardParams(token, numTokensSold, 10000);
            highFeeEstimate.numEth = numEth;
            (, estimate.high,) = recalculateAfterSwap(numTokensSold, prices, highFeeEstimate);
        }

        htrs = _estimateHTRS(avgBlock);
    }

    function _estimateHTRS(uint256 avgBlock) internal view returns (uint256) {
        // H     = "Holding/Trading Ratio, Squared" (HTRS)
        //       = ((Bmax-Bavg)/(Bmax-Bmin))²
        //       = (((Bmax-Bmin)-(Bavg-Bmin))/(Bmax-Bmin))²
        //       = (Bhold/Btrade)² (= 0 if Bmax = Bavg, NaN if Bmax = Bmin)
        if (avgBlock == block.number || block.number == epoch) return 0;

        uint256 bhold = block.number - avgBlock;
        uint256 btrade = block.number - epoch;

        return bhold * bhold * 1_000_000 / (btrade * btrade);
    }

    function _calculateReward(
        uint256 epoch_,
        uint256 avgBlock,
        uint256 currentBlock,
        uint256 profit
    ) internal pure returns (uint256) {
        /*
        Reward formula:
            P     = absolute profit in Ether = `profit`
            Bmax  = block.number when trade is happening = `block.number`
            Bavg  = volume-weighted average block.number of purchase = `avgBlock`
            Bmin  = "epoch", the block.number when contract was deployed = `epoch_`
            Bhold = Bmax-Bavg = number of blocks the trade has been held (instead of traded)
            Btrade= Bmax-Bmin = max possible trading time in blocks
            H     = "Holding/Trading Ratio, Squared" (HTRS)
                  = ((Bmax-Bavg)/(Bmax-Bmin))²
                  = (((Bmax-Bmin)-(Bavg-Bmin))/(Bmax-Bmin))²
                  = (Bhold/Btrade)² (= 0 if Bmax = Bavg, NaN if Bmax = Bmin)
            L     = WETH reserve limit for any traded token = `_reserveLimit`
            R     = minted rewards
                  = P*H
                  = if   (P = 0 || Bmax = Bavg || BMax = Bmin)
                         0
                    else P * (Bhold/Btrade)²
        */

        if (profit == 0) return 0;
        if (currentBlock == avgBlock) return 0;
        if (currentBlock == epoch_) return 0;

        // these cannot underflow thanks to previous checks
        uint256 bhold = currentBlock - avgBlock;
        uint256 btrade = currentBlock - epoch_;

        // no division by zero possible, thanks to previous checks
        return profit * (bhold * bhold) / btrade / btrade;
    }

    function _proportionOf(
        uint256 total,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        // percentage = (numerator/denominator)
        // proportion = total * percentage
        return total * numerator / denominator;
    }

    function getVerifiedPositionData(address owner, address token) internal view returns (PriceData storage priceData) {
        priceData = tokenPriceData[owner][token];
        // check that owner has the tokens
        if (priceData.tokenSum == 0) {
            revert NoTokenPositionFound({
                owner: owner,
                token: token
            });
        }
    }

    /// @inheritdoc IVanillaV1Router02
    function withdrawTokens(address token) external override {
        address owner = msg.sender;
        // ownership verified in `getVerifiedPositionData`
        PriceData storage priceData = getVerifiedPositionData(owner, token);

        // effects before interactions to prevent reentrancy
        (,uint256 tokenSum,,) = clearState(priceData);

        // use safeTransfer to make sure that unsuccessful transaction reverts
        SafeERC20.safeTransfer(IERC20(token), owner, tokenSum);
    }

    /// @inheritdoc IVanillaV1Router02
    function migratePosition(address token, address nextVersion) external override {
        if (nextVersion == address(0) || safeList.nextVersion() != nextVersion) {
            revert UnapprovedMigrationTarget(nextVersion);
        }
        address owner = msg.sender;

        // ownership verified in `getVerifiedPositionData`
        PriceData storage priceData = getVerifiedPositionData(owner, token);

        // effects before interactions to prevent reentrancy
        (uint256 ethSum, uint256 tokenSum, uint256 weightedBlockSum, uint256 latestBlock) = clearState(priceData);

        // transfer tokens before state, so that MigrationTarget can make the balance checks
        SafeERC20.safeTransfer(IERC20(token), nextVersion, tokenSum);

        // finally, transfer the state
        IVanillaV1MigrationTarget02(nextVersion).migrateState(owner, token, ethSum, tokenSum, weightedBlockSum, latestBlock);
    }

    function clearState(PriceData storage priceData) internal returns (uint256 ethSum, uint256 tokenSum, uint256 weightedBlockSum, uint256 latestBlock) {
        tokenSum = priceData.tokenSum;
        ethSum = priceData.ethSum;
        weightedBlockSum = priceData.weightedBlockSum;
        latestBlock = priceData.latestBlock;

        priceData.tokenSum = 0;
        priceData.ethSum = 0;
        priceData.weightedBlockSum = 0;
        priceData.latestBlock = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { VanillaV1Converter } from "./VanillaV1Migration01.sol";
import "./interfaces/IVanillaV1Token02.sol";
import "./interfaces/v1/VanillaV1Token01.sol";

/**
 @title Governance Token for Vanilla Finance.
 */
contract VanillaV1Token02 is ERC20("Vanilla", "VNL"), VanillaV1Converter, IVanillaV1Token02 {
    string private constant _ERROR_ACCESS_DENIED = "c1";
    address private immutable _owner;

    /**
        @notice Deploys the token and sets the caller as an owner.
     */
    constructor(IVanillaV1MigrationState _migrationState, address _vnlAddress) VanillaV1Converter(_migrationState, IERC20(_vnlAddress)) {
        _owner = msg.sender;
    }

    /**
        @dev set the decimals explicitly to 12, for (theoretical maximum of) VNL reward of a 1ETH of profit should be displayed as 1000000VNL (18-6 = 12 decimals).
     */
    function decimals() public pure override returns (uint8) {
        return 12;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, _ERROR_ACCESS_DENIED);
        _;
    }

    function mintConverted(address target, uint256 amount) internal override {
        _mint(target, amount);
    }

    /**
        @notice Mints the tokens. Used only by the VanillaRouter-contract.

        @param to The recipient address of the minted tokens
        @param tradeReward The amount of tokens to be minted
     */
    function mint(address to, uint256 tradeReward) external override onlyOwner {
        _mint(to, tradeReward);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "./TickMath.sol";
import "./VanillaV1Constants02.sol";

/**
    @title The Uniswap v3-enabled base contract for Vanilla.
*/
contract VanillaV1Uniswap02 is IUniswapV3SwapCallback, VanillaV1Constants02 {

    address internal immutable _uniswapFactoryAddr;
    address internal immutable _wethAddr;

    // for ensuring the authenticity of swapCallback caller, also reentrancy/delegatecall control
    address private authorizedPool;
    address private immutable sentinelValue; // sentinelValue _must_ be immutable

    /**
        @notice Deploys the contract and initializes Uniswap contract references
        @dev using UniswapRouter to ensure that Vanilla uses the same WETH contract
        @param router The Uniswap periphery contract implementing the IPeripheryImmutableState
     */
    constructor(IPeripheryImmutableState router) {
        // fetch addresses via router to guarantee correctness
        _wethAddr = router.WETH9();
        _uniswapFactoryAddr = router.factory();

        // we use address(this) as non-zero sentinel value for gas optimization
        sentinelValue = address(this);
        authorizedPool = address(this);
    }

    // because Uniswap V3 swaps are implemented with callback mechanisms, the callback-function becomes a public interface for
    // transferring tokens away from custody, so we want to make sure that we only authorize a _single Uniswap pool_ to
    // call the uniswapV3SwapCallback-function
    modifier onlyAuthorizedUse(IUniswapV3Pool pool) {
        address sentinel = sentinelValue;
        // protect the swap against any potential reentrancy (authorizedPool is set to to pool's address before
        // first swap and resetted back to sentinelValue
        if (authorizedPool != sentinel) {
            revert UnauthorizedReentrantAccess();
        }

        // delegatecalling the callback function should not be a problem, but there's no reason to allow that
        if (address(this) != sentinel) {
            revert UnauthorizedDelegateCall();
        }
        authorizedPool = address(pool);
        _;
        // set back to original, non-zero address for a refund
        authorizedPool = sentinel;
    }
    // this modifier needs to be used on every Uniswap v3 pool callback functions whose access is authorized by `onlyAuthorizedUse` modifier
    modifier onlyAuthorizedCallback() {
        if (msg.sender != authorizedPool) {
            revert UnauthorizedCallback();
        }
        _;
    }


    struct SwapParams {
        address source;
        address recipient;
        uint256 tokensIn;
        uint256 tokensOut;
        address tokenIn;
        address tokenOut;
    }
    function _swapToken0To1(IUniswapV3Pool pool, SwapParams memory params)
    private
    onlyAuthorizedUse(pool)
    returns (uint256 numTokens) {

        // limits are verified in the callback function to optimize gas
        uint256 balanceBefore = IERC20(params.tokenOut).balanceOf(params.recipient);
        (,int256 amountOut) = pool.swap(
            params.recipient,
            true, // "zeroForOne": The direction of the swap, true for token0 to token1, false for token1 to token0
            int256(params.tokensIn),
            TickMath.MIN_SQRT_RATIO+1,
            abi.encode(balanceBefore, params)
        );

        // v3 pool uses sign the represents the flow of tokens into the pool, so negative amount means tokens leaving
        if (amountOut > 0 || uint256(-amountOut) < params.tokensOut) {
            revert InvalidSwap(params.tokensOut, amountOut);
        }
        numTokens = uint256(-amountOut);
    }

    function _swapToken1To0(IUniswapV3Pool pool, SwapParams memory params)
    private onlyAuthorizedUse(pool)
    returns (uint256 numTokens) {

        // limits are verified in the callback function to optimize gas
        uint256 balanceBefore = IERC20(params.tokenOut).balanceOf(params.recipient);
        (int256 amountOut,) = pool.swap(
            params.recipient,
            false, // "zeroForOne": The direction of the swap, true for token0 to token1, false for token1 to token0
            int256(params.tokensIn),
            TickMath.MAX_SQRT_RATIO-1,
            abi.encode(balanceBefore, params)
        );

        // v3 pool uses sign the represents the flow of tokens into the pool, so negative amount means tokens leaving
        if (amountOut > 0 || uint256(-amountOut) < params.tokensOut) {
            revert InvalidSwap(params.tokensOut, amountOut);
        }
        numTokens = uint256(-amountOut);
    }

    function _buy(address token,
        uint256 numEth,
        uint256 limit,
        address wethHolder,
        uint24 fee) internal returns (uint256 numTokens) {
        (IUniswapV3Pool pool, bool tokenFirst) = _v3pool(token, fee);
        if (address(pool) == address(0)) {
            revert UninitializedUniswapPool(token, fee);
        }

        SwapParams memory params = SwapParams({
            source: wethHolder,
            recipient: address(this),
            tokensIn: numEth,
            tokensOut: limit,
            tokenIn: _wethAddr,
            tokenOut: token
        });
        if (tokenFirst) {
            numTokens = _swapToken1To0(pool, params);
        }
        else {
            numTokens = _swapToken0To1(pool, params);
        }
    }

    struct RewardParams {
        uint256 numEth;
        uint256 expectedAvgEth;
        uint32 averagePeriodInSeconds;
    }

    function _sell(
        address token,
        uint256 numTokens,
        uint256 limit,
        uint24 fee,
        address recipient) internal returns (RewardParams memory) {
        (IUniswapV3Pool pool, bool tokenFirst) = _v3pool(token, fee);
        if (address(pool) == address(0)) {
            revert UninitializedUniswapPool(token, fee);
        }

        SwapParams memory params = SwapParams({
            source: address(this),
            recipient: recipient,
            tokensIn: numTokens,
            tokensOut: limit,
            tokenIn: token,
            tokenOut: _wethAddr
        });
        ObservedEntry memory oldest = oldestObservation(pool);
        if (!oldest.poolInitialized) {
            revert UninitializedUniswapPool(token, fee);
        }
        if (tokenFirst) {
            (uint160 avgSqrtPrice, uint32 period) = calculateTWAP(pool, oldest);
            uint256 numEth = _swapToken0To1(pool, params);
            return RewardParams({
                numEth: numEth,
                expectedAvgEth: expectedEthForToken0(numTokens, avgSqrtPrice),
                averagePeriodInSeconds: period
            });
        }
        else {
            (uint160 avgSqrtPrice, uint32 period) = calculateTWAP(pool, oldest);
            uint256 numEth = _swapToken1To0(pool, params);
            return RewardParams({
                numEth: numEth,
                expectedAvgEth: expectedEthForToken1(numTokens, avgSqrtPrice),
                averagePeriodInSeconds: period
            });
        }
    }

    function estimateRewardParams(address token, uint256 numTokens, uint24 fee) internal view returns (
        RewardParams memory) {

        (IUniswapV3Pool pool, bool tokenFirst) = _v3pool(token, fee);
        if (address(pool) == address(0)) {
            return RewardParams({
                numEth: 0,
                expectedAvgEth: 0,
                averagePeriodInSeconds: 0
            });
        }

        ObservedEntry memory oldest = oldestObservation(pool);
        if (!oldest.poolInitialized) {
            return RewardParams({
                numEth: 0,
                expectedAvgEth: 0,
                averagePeriodInSeconds: 0
            });
        }

        (uint160 avgSqrtPrice, uint32 period) = calculateTWAP(pool, oldest);
        if (tokenFirst) {
            return RewardParams({
                numEth: 0, // really wish Uniswap v3 had provided a read-only API for querying this
                expectedAvgEth: expectedEthForToken0(numTokens, avgSqrtPrice),
                averagePeriodInSeconds: period
            });
        }
        else {
            return RewardParams({
                numEth: 0,
                expectedAvgEth: expectedEthForToken1(numTokens, avgSqrtPrice),
                averagePeriodInSeconds: period
            });
        }
    }

    struct ObservedEntry {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint16 observationCardinality;
        bool poolInitialized;
    }
    function oldestObservation(IUniswapV3Pool pool) internal view returns (ObservedEntry memory) {
        (,,uint16 observationIndex, uint16 observationCardinality,,,) = pool.slot0();
        if (observationCardinality == 0) {
            return ObservedEntry(0,0,0, false);
        }
        uint16 oldestIndex = uint16((uint32(observationIndex) + 1) % observationCardinality);
        {
            // it's important to check if the observation in oldestIndex is initialized, because if it's not, then
            // the oracle has not been fully initialized after pool.increaseObservationCardinalityNext() and oldest
            // observation is actually the index 0
            (uint32 blockTimestamp, int56 tickCumulative,, bool initialized) = pool.observations(oldestIndex);
            if (initialized) {
                return ObservedEntry({
                    blockTimestamp: blockTimestamp,
                    tickCumulative: tickCumulative,
                    observationCardinality: observationCardinality,
                    poolInitialized: true
                });
            }
        }
        {
            (uint32 blockTimestamp, int56 tickCumulative,,) = pool.observations(0);

            return ObservedEntry({
                blockTimestamp: blockTimestamp,
                tickCumulative: tickCumulative,
                observationCardinality: observationCardinality,
                poolInitialized: true
            });
        }

    }

    function getSqrtRatioAtAverageTick(uint period, int tickCumulativeDiff) pure internal returns (uint160) {
        int24 avgTick = int24(tickCumulativeDiff / int(uint(period)));
        // round down to negative infinity is correct behavior for tick math
        if (tickCumulativeDiff < 0 && (tickCumulativeDiff % int(uint(period)) != 0)) avgTick--;

        return TickMath.getSqrtRatioAtTick(avgTick);
    }


    function expectedEthForToken1(uint numTokens, uint sqrtPriceX96) internal pure returns (uint) {
        if (sqrtPriceX96 == 0) {
            // calculated average price can be 0 when no swaps has been done and observations are not updated
            return 0;
        }
        // derivation from the whitepaper equations when weth is the token0:
        // Q96 = 2^96, sqrtPriceX96 = Q*sqrt(price) = sqrt(numTokens/numEth)
        // => (sqrtPriceX96/Q96)^2 = numTokens/numEth
        // => numEth = numTokens / sqrtPriceX96^2 / Q96^2
        //           = (Q96^2 * numTokens) / sqrtPriceX96^2
        //           = (2 ** 192) * numTokens / (sqrtPriceX96 ** 2)
        if (numTokens < Q64 && sqrtPriceX96 < Q128) {
            return Q192 * numTokens / (sqrtPriceX96 ** 2);
        }
        else {
            // either numTokens or price is too high for full precision math within a uint256, so we derive an alternative where
            // the fixedpoint resolution is reduced from Q96 to Q64:
            //    ((sqrtPriceX96/2^32) / (Q96/2^32))^2 = numTokens/numEth
            // => ((sqrtPriceX64) / (Q64))^2 = numTokens/numEth
            // => ((sqrtPriceX64) / (Q64))^2 = numTokens/numEth
            // => numEth = numTokens / sqrtPriceX64^2 / Q64^2
            //           = (2 ** 128 * numTokens ) / sqrtPriceX64^2

            // this makes the overflow practically impossible, but increases the precision loss (which is acceptable since this
            // math is only used for estimating reward parameters)
            uint sqrtPriceX64 = sqrtPriceX96 / 2**32;
            return (Q128 * numTokens) / (sqrtPriceX64**2);
        }
    }


    function expectedEthForToken0(uint numTokens, uint sqrtPriceX96) internal pure returns (uint) {
        if (sqrtPriceX96 == 0) {
            // calculated average price can be 0 when no swaps has been done and observations are not updated
            return 0;
        }
        if (numTokens == 0) {
            return 0;
        }
        // derivation from the whitepaper equations when weth is the token1:
        // Q96 = 2^96, sqrtPriceX96 = Q*sqrt(price) = sqrt(numEth/numTokens)
        // => (sqrtPriceX96/Q96)^2 = numEth/numTokens
        // => numEth = numTokens * sqrtPriceX96^2 / Q96^2
        //           = (2 ** 192) * numTokens / (sqrtPriceX96 ** 2)
        //           = sqrtPriceX96 ** 2 / (2 ** 192 / numTokens)
        if (sqrtPriceX96 < Q128) {
            return (sqrtPriceX96 ** 2) / (Q192 / numTokens);
        }
        else {
            // if price is too high for full precision math within a uint256, we derive an alternative where
            // the fixedpoint resolution is reduced from Q96 to Q64:
            //    ((sqrtPriceX96/2^32) / (Q96/2^32))^2 = numEth/numTokens
            // => ((sqrtPriceX64) / (Q64))^2 = numEth/numTokens
            // => numEth = numTokens * sqrtPriceX64^2 / Q64^2
            //           = sqrtPriceX64 ** 2 / (2 ** 128 / numTokens)
            // the level of precision loss is acceptable since this math is only used for estimating reward parameters
            uint sqrtPriceX64 = sqrtPriceX96 / 2**32;
            return (sqrtPriceX64**2) / (Q128 / numTokens);
        }
    }

    function calculateTWAP(IUniswapV3Pool pool, ObservedEntry memory preSwap) internal view returns (uint160 avgSqrtPrice, uint32 period) {
        if (preSwap.observationCardinality == 1) {
            return (0, 0);
        }
        period = uint32(Math.min(block.timestamp - preSwap.blockTimestamp, MAX_TWAP_PERIOD));
        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = period;
        secondAgos[1] = 0;
        (int56[] memory tickCumulatives, ) = pool.observe(secondAgos);
        avgSqrtPrice = getSqrtRatioAtAverageTick(period, tickCumulatives[1] - tickCumulatives[0]);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override onlyAuthorizedCallback {
        if (amount1Delta < 0 && amount0Delta < 0) {
            // this should never happen, but in case it does, it would wreck these calculations so check and revert
            revert InvalidUniswapState();
        }

        // if delta0 is positive (meaning tokens are expected to increase in the pool) then delta1 is negative
        // (meaning pool's token amounts are expected to decrease), and vice versa
        (uint256 amountIn, uint256 amountOut) = amount0Delta > 0 ?
            (uint256(amount0Delta), uint256(-amount1Delta)) :
            (uint256(amount1Delta), uint256(-amount0Delta));

        (uint256 balanceBeforeSwap, SwapParams memory params) = abi.decode(data, (uint256, SwapParams));

        // Pool has already transferred the `amountOut` tokens to recipient, so check the limit before transferring the tokens
        if (IERC20(params.tokenOut).balanceOf(params.recipient) < balanceBeforeSwap + params.tokensOut) {
            revert SlippageExceeded(params.tokensOut, amountOut);
        }

        // check if for some reason the pool actually tries to request more tokens than user allowed
        if (amountIn > params.tokensIn) {
            revert AllowanceExceeded(params.tokensIn, amountIn);
        }

        if (params.source == address(this)) {
            IERC20(params.tokenIn).transfer(msg.sender, amountIn);
        }
        else {
            IERC20(params.tokenIn).transferFrom(params.source, msg.sender, amountIn);
        }
    }

    function _v3pool(
        address token,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool, bool tokenFirst) {
        // save an SLOAD
        address weth = _wethAddr;

        // as order of tokens is important in Uniswap pairs, we record this information here and pass it on to caller
        // for gas optimization
        tokenFirst = token < weth;

        // it's better to just query UniswapV3Factory for pool address instead of calculating the CREATE2 address
        // ourselves, as there are now three fee-tiers it's not guaranteed that all three are created for WETH-pairs
        // and any subsequent calls to non-existing pool will fail - and the UniswapV3Factory holds the canonical information
        // of which fee tiers are created
        // (and after EIP-2929, the uniswap factory address can be added to warmup accesslist which makes the call cost
        // insignificant compared to safety and simplicity gains)
        pool = IUniswapV3Pool(IUniswapV3Factory(_uniswapFactoryAddr).getPool(token, weth, fee));
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVanillaV1MigrationState, IVanillaV1Converter} from "./interfaces/IVanillaV1Migration01.sol";

/// @title The contract keeping the record of VNL v1 -> v1.1 migration state
contract VanillaV1MigrationState is IVanillaV1MigrationState {

    address private immutable owner;

    /// @inheritdoc IVanillaV1MigrationState
    bytes32 public override stateRoot;

    /// @inheritdoc IVanillaV1MigrationState
    uint64 public override blockNumber;

    /// @inheritdoc IVanillaV1MigrationState
    uint64 public override conversionDeadline;

    /// @dev the conversion deadline is initialized to 30 days from the deployment
    /// @param migrationOwner The address of the owner of migration state
    constructor(address migrationOwner) {
        owner = migrationOwner;
        conversionDeadline = uint64(block.timestamp + 30 days);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier beforeDeadline() {
        if (block.timestamp >= conversionDeadline) {
            revert MigrationStateUpdateDisabled();
        }
        _;
    }

    /// @inheritdoc IVanillaV1MigrationState
    function updateConvertibleState(bytes32 newStateRoot, uint64 blockNum) onlyOwner beforeDeadline external override {
        stateRoot = newStateRoot;
        blockNumber = blockNum;
        conversionDeadline = uint64(block.timestamp + 30 days);
    }

    /// @inheritdoc IVanillaV1MigrationState
    function verifyEligibility(bytes32[] memory proof, address tokenOwner, uint256 amount) external view override returns (bool) {
        // deliberately using encodePacked with a delimiter string to resolve ambiguity and let client implementations be simpler
        bytes32 leafInTree = keccak256(abi.encodePacked(tokenOwner, ":", amount));
        return block.timestamp < conversionDeadline && MerkleProof.verify(proof, stateRoot, leafInTree);
    }

}

/// @title Conversion functionality for migrating VNL v1 tokens to VNL v1.1
abstract contract VanillaV1Converter is IVanillaV1Converter {
    /// @inheritdoc IVanillaV1Converter
    IVanillaV1MigrationState public override migrationState;
    IERC20 internal vnl;

    constructor(IVanillaV1MigrationState _state, IERC20 _VNLv1) {
        migrationState = _state;
        vnl = _VNLv1;
    }

    function mintConverted(address target, uint256 amount) internal virtual;


    /// @inheritdoc IVanillaV1Converter
    function checkEligibility(bytes32[] memory proof) external view override returns (bool convertible, bool transferable) {
        uint256 balance = vnl.balanceOf(msg.sender);

        convertible = migrationState.verifyEligibility(proof, msg.sender, balance);
        transferable = balance > 0 && vnl.allowance(msg.sender, address(this)) >= balance;
    }

    /// @inheritdoc IVanillaV1Converter
    function convertVNL(bytes32[] memory proof) external override {
        if (block.timestamp >= migrationState.conversionDeadline()) {
            revert ConversionWindowClosed();
        }

        uint256 convertedAmount = vnl.balanceOf(msg.sender);
        if (convertedAmount == 0) {
            revert NoConvertibleVNL();
        }

        // because VanillaV1Token01's cannot be burned, the conversion just locks them into this contract permanently
        address freezer = address(this);
        uint256 previouslyFrozen = vnl.balanceOf(freezer);

        // we know that OpenZeppelin ERC20 returns always true and reverts on failure, so no need to check the return value
        vnl.transferFrom(msg.sender, freezer, convertedAmount);

        // These should never fail as we know precisely how VanillaV1Token01.transferFrom is implemented
        if (vnl.balanceOf(freezer) != previouslyFrozen + convertedAmount) {
            revert FreezerBalanceMismatch();
        }
        if (vnl.balanceOf(msg.sender) > 0) {
            revert UnexpectedTokensAfterConversion();
        }

        if (!migrationState.verifyEligibility(proof, msg.sender, convertedAmount)) {
            revert VerificationFailed();
        }

        // finally let implementor to mint the converted amount of tokens and log the event
        mintConverted(msg.sender, convertedAmount);
        emit VNLConverted(msg.sender, convertedAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./interfaces/IVanillaV1Safelist01.sol";

/// @title The contract that keeps a safelist of rewardable ERC-20 tokens and next approved Vanilla version
contract VanillaV1Safelist01 is IVanillaV1Safelist01 {

    address private immutable owner;
    /// @inheritdoc IVanillaV1Safelist01
    mapping(address => bool) public override isSafelisted;

    /// @inheritdoc IVanillaV1Safelist01
    address public override nextVersion;

    constructor(address safeListOwner) {
        owner = safeListOwner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert UnauthorizedAccess();
        }
        _;
    }

    /// @notice Adds and removes tokens to/from the safelist. Only for the owner.
    /// @dev Adds first and removes second, so adding and removing a token will not result in safelisted token
    /// @param added Array of added ERC-20 addresses
    /// @param removed Array of removed ERC-20 addresses
    function modify(address[] calldata added, address[] calldata removed) external onlyOwner {
        uint numAdded = added.length;
        if (numAdded > 0) {
            for (uint i = 0; i < numAdded; i++) {
                isSafelisted[added[i]] = true;
            }
            emit TokensAdded(added);
        }

        uint numRemoved = removed.length;
        if (numRemoved > 0) {
            for (uint i = 0; i < numRemoved; i++) {
                delete isSafelisted[removed[i]];
            }
            emit TokensRemoved(removed);
        }
    }

    /// @notice Approves the next version implementation. Only for the owner.
    /// @param implementation Address of the IVanillaV1MigrationTarget02 implementation
    function approveNextVersion(address implementation) external onlyOwner {
        nextVersion = implementation;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface VanillaV1API01 {
    /**
        @notice Checks if the given ERC-20 token will be eligible for rewards (i.e. a safelisted token)
        @param token The ERC-20 token address
     */
    function isTokenRewarded(address token) external view returns (bool);

    /// internally tracked reserves for price manipulation protection for each token (Uniswap uses uint112 so uint128 is plenty)
    function wethReserves(address token) external view returns (uint128);


    function epoch() external view returns (uint256);

    function vnlContract() external view returns (address);

    function reserveLimit() external view returns (uint128);

    /// Price data, indexed as [owner][token]
    function tokenPriceData(address owner, address token) external view returns (uint256 ethSum,
        uint256 tokenSum,
        uint256 weightedBlockSum,
        uint256 latestBlock);

    /**
        @notice Estimates the reward.
        @dev Estimates the reward for given `owner` when selling `numTokensSold``token`s for `numEth` Ether. Also returns the individual components of the reward formula.
        @return profitablePrice The expected amount of Ether for this trade. Profit of this trade can be calculated with `numEth`-`profitablePrice`.
        @return avgBlock The volume-weighted average block for the `owner` and `token`
        @return htrs The Holding/Trading Ratio, Squared- estimate for this trade, percentage value range in fixed point range 0-100.0000.
        @return vpc The Value-Protection Coefficient- estimate for this trade, percentage value range in fixed point range 0-100.0000.
        @return reward The token reward estimate for this trade.
     */
    function estimateReward(
        address owner,
        address token,
        uint256 numEth,
        uint256 numTokensSold
    ) external view returns (
        uint256 profitablePrice,
        uint256 avgBlock,
        uint256 htrs,
        uint256 vpc,
        uint256 reward
    );

    /**
        @notice Buys the tokens with Ether. Use the external pricefeed for pricing.
        @dev Buys the `numToken` tokens for all the msg.value Ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be bought
        @param numToken The amount of ERC20 tokens to be bought
        @param blockTimeDeadline The block timestamp when this buy-transaction expires
     */
    function depositAndBuy(
        address token,
        uint256 numToken,
        uint256 blockTimeDeadline
    ) external payable;

    /**
        @notice Buys the tokens with WETH. Use the external pricefeed for pricing.
        @dev Buys the `numToken` tokens for all the msg.value Ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be bought
        @param numEth The amount of WETH to spend. Needs to be pre-approved for the VanillaRouter.
        @param numToken The amount of ERC20 tokens to be bought
        @param blockTimeDeadline The block timestamp when this buy-transaction expires
     */
    function buy(
        address token,
        uint256 numEth,
        uint256 numToken,
        uint256 blockTimeDeadline
    ) external;

    /**
        @notice Sells the tokens the caller owns. Use the external pricefeed for pricing.
        @dev Sells the `numToken` tokens msg.sender owns, for `numEth` ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be sold
        @param numToken The amount of ERC20 tokens to be sold
        @param numEthLimit The minimum amount of ether to be received for exchange (the limit order)
        @param blockTimeDeadline The block timestamp when this sell-transaction expires
     */
    function sell(
        address token,
        uint256 numToken,
        uint256 numEthLimit,
        uint256 blockTimeDeadline
    ) external;

    /**
        @notice Sells the tokens the caller owns. Use the external pricefeed for pricing.
        @dev Sells the `numToken` tokens msg.sender owns, for `numEth` ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be sold
        @param numToken The amount of ERC20 tokens to be sold
        @param numEthLimit The minimum amount of ether to be received for exchange (the limit order)
        @param blockTimeDeadline The block timestamp when this sell-transaction expires
     */
    function sellAndWithdraw(
        address token,
        uint256 numToken,
        uint256 numEthLimit,
        uint256 blockTimeDeadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IVanillaV1Token02.sol";
import "./IVanillaV1Safelist01.sol";

/// @title Entry point API for Vanilla trading router
interface IVanillaV1Router02 {

    /// @notice Gets the epoch block.number used in reward calculations
    function epoch() external view returns (uint256);

    /// @notice Gets the address of the VNL token contract
    function vnlContract() external view returns (IVanillaV1Token02);

    /// @dev data for calculating volume-weighted average prices, average purchasing block, and limiting trades per block
    struct PriceData {
        uint256 weightedBlockSum;
        uint112 ethSum;
        uint112 tokenSum;
        uint32 latestBlock;
    }

    /// @notice Price data, indexed as [owner][token]
    function tokenPriceData(address owner, address token) external view returns (
        uint256 weightedBlockSum,
        uint112 ethSum,
        uint112 tokenSum,
        uint32 latestBlock);

    /// @dev Emitted when tokens are sold.
    /// @param seller The owner of tokens.
    /// @param token The address of the sold token.
    /// @param amount Number of sold tokens.
    /// @param eth The received ether from the trade.
    /// @param profit The calculated profit from the trade.
    /// @param reward The amount of VanillaGovernanceToken reward tokens transferred to seller.
    event TokensSold(
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 eth,
        uint256 profit,
        uint256 reward
    );

    /// @dev Emitted when tokens are bought.
    /// @param buyer The new owner of tokens.
    /// @param token The address of the purchased token.
    /// @param eth The amount of ether spent in the trade.
    /// @param amount Number of purchased tokens.
    event TokensPurchased(
        address indexed buyer,
        address indexed token,
        uint256 eth,
        uint256 amount
    );

    /// @notice Gets the address of the safelist contract
    function safeList() external view returns (IVanillaV1Safelist01);


    struct TradeResult {
        /// the number of Ether received in the trade
        uint256 price;
        /// the length of observable history available in Uniswap v3 pool (5 minute cap)
        uint256 twapPeriodInSeconds;
        /// the number of Ether expected to make trade profitable
        uint256 profitablePrice;
        /// the max number of Ether to be used in reward calculations (also equals the 5-min capped TWAP price from the pool)
        uint256 maxProfitablePrice;
        /// the amount of rewardable profit to be used in reward calculations (the full profit equals `profitablePrice - price`)
        uint256 rewardableProfit;
        /// the amount of VNL reward for this trade
        uint256 reward;
    }

    struct RewardEstimate {
        /// estimate when trading a token in a low-fee Uniswap v3 pool (0.05%)
        TradeResult low;
        /// estimate when trading a token in a medium-fee Uniswap v3 pool (0.3%)
        TradeResult medium;
        /// estimate when trading a token in a high-fee Uniswap v3 pool (1.0%)
        TradeResult high;
    }

    /// @notice Estimates the reward. Not intended to be called from other contracts.
    /// @dev Estimates the reward for given `owner` when selling `numTokensSold``token`s for `numEth` Ether. Also returns the individual components of the reward formula.
    /// @return avgBlock The volume-weighted average block for the `owner` and `token`
    /// @return htrs The Holding/Trading Ratio, Squared- estimate for this trade, percentage value range in fixed point range 0-100.0000.
    /// @return estimate The token reward estimate for this trade for every Uniswap v3 fee-tier.
    function estimateReward(
        address owner,
        address token,
        uint256 numEth,
        uint256 numTokensSold
    ) external view returns (
        uint256 avgBlock,
        uint256 htrs,
        RewardEstimate memory estimate
    );

    /// @notice Delegate call to multiple functions in this Router and return their results iff they all succeed
    /// @param data The function calls encoded
    /// @return results The results of the encoded function calls, in the same order
    function execute(bytes[] calldata data) external returns (bytes[] memory results);

    /// @notice Delegate call to multiple functions in this Router and return their results iff they all succeed
    /// @dev All `msg.value` will be wrapped to WETH before executing the functions.
    /// @param data The function calls encoded
    /// @return results The results of the encoded function calls, in the same order
    function executePayable(bytes[] calldata data) external payable returns (bytes[] memory results);

    struct OrderData {
        // The address of the token to be bought or sold
        address token;

        // if true, buy-order transfers WETH from caller and sell-order transfers WETHs back to caller without withdrawing
        // if false, it's assumed that executePayable is used to deposit/withdraw WETHs before order
        bool useWETH;

        // The exact amount of WETH to be spent when buying or the limit amount of WETH to be received when selling.
        uint256 numEth;

        // The exact amount of token to be sold when selling or the limit amount of token to be received when buying.
        uint256 numToken;

        // The block.timestamp when this order expires
        uint256 blockTimeDeadline;

        // The Uniswap v3 fee tier to use for the swap (500 = 0.05%, 3000 = 0.3%, 10000 = 1.0%)
        uint24 fee;
    }

    /// @notice Buys the tokens with WETH. Use the external pricefeed for pricing. Do not send ether to this function.
    /// @dev Buys the `buyOrder.numToken` tokens for all the `buyOrder.numEth` WETH, before `buyOrder.blockTimeDeadline`
    /// @param buyOrder.token The address of ERC20 token to be bought
    /// @param buyOrder.useWETH Whether to buy directly with caller's WETHs instead of depositing `msg.value`
    /// @param buyOrder.numEth The amount of WETH to spend.
    /// @param buyOrder.numToken The minimum amount of ERC20 tokens to be bought (the limit order)
    /// @param buyOrder.blockTimeDeadline The block timestamp when this buy-transaction expires
    function buy( OrderData calldata buyOrder ) payable external;

    /// @notice Sells the tokens the caller owns for WETH. Use the external pricefeed for pricing. Do not send ether to this function.
    /// @dev Sells the `sellOrder.numToken` tokens msg.sender owns, for `sellOrder.numEth` ether, before `sellOrder.blockTimeDeadline`
    /// @param sellOrder.token The address of ERC20 token to be sold
    /// @param sellOrder.useWETH Whether to transfer WETHs directly to caller instead of withdrawing them to Ether
    /// @param sellOrder.numToken The amount of ERC20 tokens to be sold
    /// @param sellOrder.numEth The minimum amount of ether to be received for exchange (the limit order)
    /// @param sellOrder.blockTimeDeadline The block timestamp when this sell-transaction expires
    function sell( OrderData calldata sellOrder ) payable external;

    /// @notice Transfer all the tokens msg.sender owns to msg.sender
    /// @param token The address of ERC20 token to be withdrawn
    function withdrawTokens(address token) external;

    /// @notice Migration the token position the msg.sender holds to the next version.
    /// @param token The address of ERC20 token position to be migrated
    /// @param nextVersion The address of the next Vanilla Router version.
    function migratePosition(address token, address nextVersion) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IVanillaV1MigrationTarget02 {
    /// @notice Called by IVanillaV1Router02#migratePosition.
    /// @dev Router transfers the tokens before calling this function, so that balance can be verified.
    function migrateState(address owner, address token, uint256 ethSum, uint256 tokenSum, uint256 weightedBlockSum, uint256 latestBlock) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IVanillaV1Migration01.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVanillaV1Token02 is IERC20, IVanillaV1Converter {

    function mint(address to, uint256 tradeReward) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface VanillaV1Token01 is IERC20 {
    function mint(address to, uint256 tradeReward) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IVanillaV1MigrationState {

    /// @notice The current Merkle tree root for checking the eligibility for token conversion
    /// @dev tree leaves are tuples of (VNLv1-owner-address, VNLv1-token-balance), ordered as keccak256(abi.encodePacked(tokenOwner, ":", amount))
    function stateRoot() external view returns (bytes32);

    /// @notice Gets the block.number which was used to calculate the `stateRoot()` (for off-chain verification)
    function blockNumber() external view returns (uint64);

    /// @notice Gets the current deadline for conversion as block.timestamp
    function conversionDeadline() external view returns (uint64);

    /// @notice Checks if `tokenOwner` owning `amount` of VNL v1s is eligible for token conversion. Needs a Merkle `proof`.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing,
    /// leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    /// @param tokenOwner The address owning the VanillaV1Token01 tokens
    /// @param amount The amount of VanillaV1Token01 tokens (i.e. the balance of the tokenowner)
    /// @return true iff `tokenOwner` is eligible to convert `amount` tokens to VanillaV1Token02
    function verifyEligibility(bytes32[] memory proof, address tokenOwner, uint256 amount) external view returns (bool);

    /// @notice Updates the Merkle tree for provable ownership of convertible VNL v1 tokens. Only for the owner.
    /// @dev Moves also the internal deadline forward 30 days
    /// @param newStateRoot The new Merkle tree root for checking the eligibility for token conversion
    /// @param blockNum The block.number whose state was used to calculate the `newStateRoot`
    function updateConvertibleState(bytes32 newStateRoot, uint64 blockNum) external;

    /// @notice thrown if non-owners try to modify state
    error UnauthorizedAccess();

    /// @notice thrown if attempting to update migration state after conversion deadline
    error MigrationStateUpdateDisabled();
}

interface IVanillaV1Converter {
    /// @notice Gets the address of the migration state contract
    function migrationState() external view returns (IVanillaV1MigrationState);

    /// @dev Emitted when VNL v1.01 is converted to v1.02
    /// @param converter The owner of tokens.
    /// @param amount Number of converted tokens.
    event VNLConverted(address converter, uint256 amount);

    /// @notice Checks if all `msg.sender`s VanillaV1Token01's are eligible for token conversion. Needs a Merkle `proof`.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing, and leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    /// @return convertible true if `msg.sender` is eligible to convert all VanillaV1Token01 tokens to VanillaV1Token02 and conversion window is open
    /// @return transferable true if `msg.sender`'s VanillaV1Token01 tokens are ready to be transferred for conversion
    function checkEligibility(bytes32[] memory proof) external view returns (bool convertible, bool transferable);

    /// @notice Converts _ALL_ `msg.sender`s VanillaV1Token01's to VanillaV1Token02 if eligible. The conversion is irreversible.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing, and leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    function convertVNL(bytes32[] memory proof) external;

    /// @notice thrown when attempting to convert VNL after deadline
    error ConversionWindowClosed();

    /// @notice thrown when attempting to convert 0 VNL
    error NoConvertibleVNL();

    /// @notice thrown if for some reason VNL freezer balance doesn't match the transferred amount + old balance
    error FreezerBalanceMismatch();

    /// @notice thrown if for some reason user holds VNL v1 tokens after conversion (i.e. transfer failed)
    error UnexpectedTokensAfterConversion();

    /// @notice thrown if user provided incorrect proof for conversion eligibility
    error VerificationFailed();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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
pragma solidity ^0.8.4;
// This library is a derived work from @uniswap/v3-core/contracts/libraries/TickMath.sol
// (https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/TickMath.sol).
// The modifications are:
// - fixed integer conversion issues which allows to compile the library with Solidity 0.8
// - pruned the function `getTickAtSqrtRatio` which isn't used in Vanilla


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
        require(absTick <= uint256(int256(MAX_TICK)), 'T');

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

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

abstract contract VanillaV1Constants02 {
    error UnauthorizedReentrantAccess();
    error UnauthorizedDelegateCall();
    error UnauthorizedCallback();
    error AllowanceExceeded(uint256 allowed, uint256 actual);
    error SlippageExceeded(uint256 expected, uint256 actual);
    error InvalidSwap(uint256 expected, int256 amountReceived);
    error InvalidUniswapState();
    error UninitializedUniswapPool(address token, uint24 fee);
    error NoTokenPositionFound(address owner, address token);
    error TooManyTradesPerBlock();
    error WrongTradingParameters();
    error UnauthorizedValueSent();
    error InvalidWethAccount();
    error TradeExpired();
    error TokenBalanceExceeded(uint256 tokens, uint112 balance);
    error UnapprovedMigrationTarget(address invalidVersion);

    // constant units for Q-number calculations (https://en.wikipedia.org/wiki/Q_(number_format))
    uint256 internal constant Q32 = 2**32;
    uint256 internal constant Q64 = 2**64;
    uint256 internal constant Q128 = 2**128;
    uint256 internal constant Q192 = 2**192;

    uint32 internal constant MAX_TWAP_PERIOD = 5 minutes;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IVanillaV1Safelist01 {
    /// @notice Queries if given `token` address is safelisted.
    /// @param token The ERC-20 address
    /// @return true iff safelisted
    function isSafelisted(address token) external view returns (bool);

    /// @notice Queries the safelisted address of the next Vanilla version.
    /// @return The address of the next Vanilla version which implements IVanillaV1MigrationTarget02
    function nextVersion() external view returns (address);

    /// @notice Emitted when tokens are added to the safelist
    /// @param tokens The ERC-20 addresses that are added to the safelist
    event TokensAdded (address[] tokens);

    /// @notice Emitted when tokens are removed from the safelist
    /// @param tokens The ERC-20 addresses that are added to the safelist
    event TokensRemoved (address[] tokens);

    /// @notice Thrown when non-owner attempting to modify safelist state
    error UnauthorizedAccess ();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

