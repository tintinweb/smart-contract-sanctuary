// SPDX-License-Identifier: GPL-3.0-only

pragma solidity =0.7.6;
pragma abicoder v2;

// interface
import {IController} from "../interfaces/IController.sol";
import {IWPowerPerp} from "../interfaces/IWPowerPerp.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IController} from "../interfaces/IController.sol";

// contract
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {StrategyBase} from "./base/StrategyBase.sol";
import {StrategyFlashSwap} from "./base/StrategyFlashSwap.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// lib
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
// StrategyMath licensed under AGPL-3.0-only
import {StrategyMath} from "./base/StrategyMath.sol";
import {Power2Base} from "../libs/Power2Base.sol";

/**
 * @dev CrabStrategy contract
 * @notice Contract for Crab strategy
 * @author Opyn team
 */
contract CrabStrategy is StrategyBase, StrategyFlashSwap, ReentrancyGuard, Ownable {
    using StrategyMath for uint256;
    using Address for address payable;

    /// @dev the cap in ETH for the strategy, above which deposits will be rejected
    uint256 public strategyCap;

    /// @dev the TWAP_PERIOD used in the PowerPerp Controller contract
    uint32 public constant POWER_PERP_PERIOD = 420 seconds;
    /// @dev twap period to use for hedge calculations
    uint32 public hedgingTwapPeriod = 420 seconds;

    /// @dev enum to differentiate between uniswap swap callback function source
    enum FLASH_SOURCE {
        FLASH_DEPOSIT,
        FLASH_WITHDRAW,
        FLASH_HEDGE_SELL,
        FLASH_HEDGE_BUY
    }

    /// @dev ETH:WSqueeth uniswap pool
    address public immutable ethWSqueethPool;
    /// @dev strategy uniswap oracle
    address public immutable oracle;
    address public immutable ethQuoteCurrencyPool;
    address public immutable quoteCurrency;

    /// @dev strategy will only allow hedging if collateral to trade is at least a set percentage of the total strategy collateral
    uint256 public deltaHedgeThreshold = 1e15;
    /// @dev time difference to trigger a hedge (seconds)
    uint256 public hedgeTimeThreshold;
    /// @dev price movement to trigger a hedge (0.1*1e18 = 10%)
    uint256 public hedgePriceThreshold;
    /// @dev hedge auction duration (seconds)
    uint256 public auctionTime;
    /// @dev start auction price multiplier for hedge buy auction and reserve price for hedge sell auction (scaled 1e18)
    uint256 public minPriceMultiplier;
    /// @dev start auction price multiplier for hedge sell auction and reserve price for hedge buy auction (scaled 1e18)
    uint256 public maxPriceMultiplier;

    /// @dev timestamp when last hedge executed
    uint256 public timeAtLastHedge;
    /// @dev WSqueeth/Eth price when last hedge executed
    uint256 public priceAtLastHedge;

    /// @dev set to true when redeemShortShutdown has been called
    bool private hasRedeemedInShutdown;

    struct FlashDepositData {
        uint256 totalDeposit;
    }

    struct FlashWithdrawData {
        uint256 crabAmount;
    }

    struct FlashHedgeData {
        uint256 wSqueethAmount;
        uint256 ethProceeds;
        uint256 minWSqueeth;
        uint256 minEth;
    }

    event Deposit(address indexed depositor, uint256 wSqueethAmount, uint256 lpAmount);
    event Withdraw(address indexed withdrawer, uint256 crabAmount, uint256 wSqueethAmount, uint256 ethWithdrawn);
    event WithdrawShutdown(address indexed withdrawer, uint256 crabAmount, uint256 ethWithdrawn);
    event FlashDeposit(address indexed depositor, uint256 depositedAmount, uint256 tradedAmountOut);
    event FlashWithdraw(address indexed withdrawer, uint256 crabAmount, uint256 wSqueethAmount);
    event FlashDepositCallback(address indexed depositor, uint256 flashswapDebt, uint256 excess);
    event FlashWithdrawCallback(address indexed withdrawer, uint256 flashswapDebt, uint256 excess);
    event TimeHedgeOnUniswap(
        address indexed hedger,
        uint256 hedgeTimestamp,
        uint256 auctionTriggerTimestamp,
        uint256 minWSqueeth,
        uint256 minEth
    );
    event PriceHedgeOnUniswap(
        address indexed hedger,
        uint256 hedgeTimestamp,
        uint256 auctionTriggerTimestamp,
        uint256 minWSqueeth,
        uint256 minEth
    );
    event TimeHedge(address indexed hedger, bool auctionType, uint256 hedgerPrice, uint256 auctionTriggerTimestamp);
    event PriceHedge(address indexed hedger, bool auctionType, uint256 hedgerPrice, uint256 auctionTriggerTimestamp);
    event Hedge(
        address indexed hedger,
        bool auctionType,
        uint256 hedgerPrice,
        uint256 auctionPrice,
        uint256 wSqueethHedgeTargetAmount,
        uint256 ethHedgetargetAmount
    );
    event HedgeOnUniswap(
        address indexed hedger,
        bool auctionType,
        uint256 auctionPrice,
        uint256 wSqueethHedgeTargetAmount,
        uint256 ethHedgetargetAmount
    );
    event ExecuteSellAuction(address indexed buyer, uint256 wSqueethSold, uint256 ethBought, bool isHedgingOnUniswap);
    event ExecuteBuyAuction(address indexed seller, uint256 wSqueethBought, uint256 ethSold, bool isHedgingOnUniswap);
    event SetStrategyCap(uint256 newCapAmount);
    event SetDeltaHedgeThreshold(uint256 newDeltaHedgeThreshold);
    event SetHedgingTwapPeriod(uint32 newHedgingTwapPeriod);
    event SetHedgeTimeThreshold(uint256 newHedgeTimeThreshold);
    event SetHedgePriceThreshold(uint256 newHedgePriceThreshold);
    event SetAuctionTime(uint256 newAuctionTime);
    event SetMinPriceMultiplier(uint256 newMinPriceMultiplier);
    event SetMaxPriceMultiplier(uint256 newMaxPriceMultiplier);

    /**
     * @notice strategy constructor
     * @dev this will open a vault in the power token contract and store the vault ID
     * @param _wSqueethController power token controller address
     * @param _oracle oracle address
     * @param _weth weth address
     * @param _uniswapFactory uniswap factory address
     * @param _ethWSqueethPool eth:wSqueeth uniswap pool address
     * @param _hedgeTimeThreshold hedge time threshold (seconds)
     * @param _hedgePriceThreshold hedge price threshold (0.1*1e18 = 10%)
     * @param _auctionTime auction duration (seconds)
     * @param _minPriceMultiplier minimum auction price multiplier (0.9*1e18 = min auction price is 90% of twap)
     * @param _maxPriceMultiplier maximum auction price multiplier (1.1*1e18 = max auction price is 110% of twap)
     */
    constructor(
        address _wSqueethController,
        address _oracle,
        address _weth,
        address _uniswapFactory,
        address _ethWSqueethPool,
        uint256 _hedgeTimeThreshold,
        uint256 _hedgePriceThreshold,
        uint256 _auctionTime,
        uint256 _minPriceMultiplier,
        uint256 _maxPriceMultiplier
    ) StrategyBase(_wSqueethController, _weth, "Crab Strategy", "Crab") StrategyFlashSwap(_uniswapFactory) {
        require(_oracle != address(0), "invalid oracle address");
        require(_ethWSqueethPool != address(0), "invalid ETH:WSqueeth address");
        require(_hedgeTimeThreshold > 0, "invalid hedge time threshold");
        require(_hedgePriceThreshold > 0, "invalid hedge price threshold");
        require(_auctionTime > 0, "invalid auction time");
        require(_minPriceMultiplier < 1e18, "min price multiplier too high");
        require(_minPriceMultiplier > 0, "invalid min price multiplier");
        require(_maxPriceMultiplier > 1e18, "max price multiplier too low");

        oracle = _oracle;
        ethWSqueethPool = _ethWSqueethPool;
        hedgeTimeThreshold = _hedgeTimeThreshold;
        hedgePriceThreshold = _hedgePriceThreshold;
        auctionTime = _auctionTime;
        minPriceMultiplier = _minPriceMultiplier;
        maxPriceMultiplier = _maxPriceMultiplier;
        ethQuoteCurrencyPool = IController(_wSqueethController).ethQuoteCurrencyPool();
        quoteCurrency = IController(_wSqueethController).quoteCurrency();
    }

    /**
     * @notice receive function to allow ETH transfer to this contract
     */
    receive() external payable {
        require(msg.sender == weth || msg.sender == address(powerTokenController), "Cannot receive eth");
    }

    /**
     * @notice owner can set the strategy cap in ETH collateral terms
     * @dev deposits are rejected if it would put the strategy above the cap amount
     * @dev strategy collateral can be above the cap amount due to hedging activities
     * @param _capAmount the maximum strategy collateral in ETH, checked on deposits
     */
    function setStrategyCap(uint256 _capAmount) external onlyOwner {
        strategyCap = _capAmount;

        emit SetStrategyCap(_capAmount);
    }

    /**
     * @notice called to redeem the net value of a vault post shutdown
     * @dev needs to be called 1 time before users can exit the strategy using withdrawShutdown
     */
    function redeemShortShutdown() external {
        hasRedeemedInShutdown = true;
        powerTokenController.redeemShort(vaultId);
    }

    /**
     * @notice flash deposit into strategy, providing ETH, selling wSqueeth and receiving strategy tokens
     * @dev this function will execute a flash swap where it receives ETH, deposits and mints using flash swap proceeds and msg.value, and then repays the flash swap with wSqueeth
     * @dev _ethToDeposit must be less than msg.value plus the proceeds from the flash swap
     * @dev the difference between _ethToDeposit and msg.value provides the minimum that a user can receive for their sold wSqueeth
     * @param _ethToDeposit total ETH that will be deposited in to the strategy which is a combination of msg.value and flash swap proceeds
     */
    function flashDeposit(uint256 _ethToDeposit) external payable nonReentrant {
        (uint256 cachedStrategyDebt, uint256 cachedStrategyCollateral) = _syncStrategyState();
        _checkStrategyCap(_ethToDeposit, cachedStrategyCollateral);

        (uint256 wSqueethToMint, ) = _calcWsqueethToMintAndFee(
            _ethToDeposit,
            cachedStrategyDebt,
            cachedStrategyCollateral
        );

        if (cachedStrategyDebt == 0 && cachedStrategyCollateral == 0) {
            // store hedge data as strategy is delta neutral at this point
            // only execute this upon first deposit
            uint256 wSqueethEthPrice = IOracle(oracle).getTwap(
                ethWSqueethPool,
                wPowerPerp,
                weth,
                hedgingTwapPeriod,
                true
            );
            timeAtLastHedge = block.timestamp;
            priceAtLastHedge = wSqueethEthPrice;
        }

        _exactInFlashSwap(
            wPowerPerp,
            weth,
            IUniswapV3Pool(ethWSqueethPool).fee(),
            wSqueethToMint,
            _ethToDeposit.sub(msg.value),
            uint8(FLASH_SOURCE.FLASH_DEPOSIT),
            abi.encodePacked(_ethToDeposit)
        );

        emit FlashDeposit(msg.sender, _ethToDeposit, wSqueethToMint);
    }

    /**
     * @notice flash withdraw from strategy, providing strategy tokens, buying wSqueeth, burning and receiving ETH
     * @dev this function will execute a flash swap where it receives wSqueeth, burns, withdraws ETH and then repays the flash swap with ETH
     * @param _crabAmount strategy token amount to burn
     * @param _maxEthToPay maximum ETH to pay to buy back the owed wSqueeth debt
     */
    function flashWithdraw(uint256 _crabAmount, uint256 _maxEthToPay) external nonReentrant {
        uint256 exactWSqueethNeeded = _getDebtFromStrategyAmount(_crabAmount);

        _exactOutFlashSwap(
            weth,
            wPowerPerp,
            IUniswapV3Pool(ethWSqueethPool).fee(),
            exactWSqueethNeeded,
            _maxEthToPay,
            uint8(FLASH_SOURCE.FLASH_WITHDRAW),
            abi.encodePacked(_crabAmount)
        );

        emit FlashWithdraw(msg.sender, _crabAmount, exactWSqueethNeeded);
    }

    /**
     * @notice deposit ETH into strategy
     * @dev provide ETH, return wSqueeth and strategy token
     */
    function deposit() external payable nonReentrant {
        uint256 amount = msg.value;

        (uint256 wSqueethToMint, uint256 depositorCrabAmount) = _deposit(msg.sender, amount, false);

        emit Deposit(msg.sender, wSqueethToMint, depositorCrabAmount);
    }

    /**
     * @notice withdraw WETH from strategy
     * @dev provide strategy tokens and wSqueeth, returns eth
     * @param _crabAmount amount of strategy token to burn
     */
    function withdraw(uint256 _crabAmount) external nonReentrant {
        uint256 wSqueethAmount = _getDebtFromStrategyAmount(_crabAmount);
        uint256 ethToWithdraw = _withdraw(msg.sender, _crabAmount, wSqueethAmount, false);

        // send back ETH collateral
        payable(msg.sender).sendValue(ethToWithdraw);

        emit Withdraw(msg.sender, _crabAmount, wSqueethAmount, ethToWithdraw);
    }

    /**
     * @notice called to exit a vault if the Squeeth Power Perp contracts are shutdown
     * @param _crabAmount amount of strategy token to burn
     */
    function withdrawShutdown(uint256 _crabAmount) external nonReentrant {
        require(powerTokenController.isShutDown(), "Squeeth contracts not shut down");
        require(hasRedeemedInShutdown, "Crab must redeemShortShutdown");

        uint256 strategyShare = _calcCrabRatio(_crabAmount, totalSupply());
        uint256 ethToWithdraw = _calcEthToWithdraw(strategyShare, address(this).balance);
        _burn(msg.sender, _crabAmount);

        payable(msg.sender).sendValue(ethToWithdraw);
        emit WithdrawShutdown(msg.sender, _crabAmount, ethToWithdraw);
    }

    /**
     * @notice hedge startegy based on time threshold with uniswap arbing
     * @dev this function atomically hedges on uniswap and provides a bounty to the caller based on the difference
     * @dev between uniswap execution price and the price of the hedging auction
     * @param _minWSqueeth minimum WSqueeth amount the caller willing to receive if hedge auction is selling WSqueeth
     * @param _minEth minimum ETH amount the caller is willing to receive if hedge auction is buying WSqueeth
     */
    function timeHedgeOnUniswap(uint256 _minWSqueeth, uint256 _minEth) external {
        (bool isTimeHedgeAllowed, uint256 auctionTriggerTime) = _isTimeHedge();

        require(isTimeHedgeAllowed, "Time hedging is not allowed");

        _hedgeOnUniswap(auctionTriggerTime, _minWSqueeth, _minEth);

        emit TimeHedgeOnUniswap(msg.sender, block.timestamp, auctionTriggerTime, _minWSqueeth, _minEth);
    }

    /**
     * @notice hedge startegy based on price threshold with uniswap arbing
     * @dev this function atomically hedges on uniswap and provides a bounty to the caller based on the difference
     * @dev between uniswap execution price and the price of the hedging auction
     * @param _auctionTriggerTime the time when the price deviation threshold was exceeded and when the auction started
     * @param _minWSqueeth minimum WSqueeth amount the caller willing to receive if hedge auction is selling WSqueeth
     * @param _minEth minimum ETH amount the caller is willing to receive if hedge auction is buying WSqueeth
     */
    function priceHedgeOnUniswap(
        uint256 _auctionTriggerTime,
        uint256 _minWSqueeth,
        uint256 _minEth
    ) external payable {
        require(_isPriceHedge(_auctionTriggerTime), "Price hedging not allowed");

        _hedgeOnUniswap(_auctionTriggerTime, _minWSqueeth, _minEth);

        emit PriceHedgeOnUniswap(msg.sender, block.timestamp, _auctionTriggerTime, _minWSqueeth, _minEth);
    }

    /**
     * @notice strategy hedging based on time threshold
     * @dev need to attach msg.value if buying WSqueeth
     * @param _isStrategySellingWSqueeth sell or buy auction, true for sell auction
     * @param _limitPrice hedger limit auction price, should be the max price when auction is sell auction, min price when it is a buy auction
     */
    function timeHedge(bool _isStrategySellingWSqueeth, uint256 _limitPrice) external payable nonReentrant {
        (bool isTimeHedgeAllowed, uint256 auctionTriggerTime) = _isTimeHedge();

        require(isTimeHedgeAllowed, "Time hedging is not allowed");

        _hedge(auctionTriggerTime, _isStrategySellingWSqueeth, _limitPrice);

        emit TimeHedge(msg.sender, _isStrategySellingWSqueeth, _limitPrice, auctionTriggerTime);
    }

    /**
     * @notice strategy hedging based on price threshold
     * @dev need to attach msg.value if buying WSqueeth
     * @param _auctionTriggerTime the time when the price deviation threshold was exceeded and when the auction started
     * @param _isStrategySellingWSqueeth specify the direction of the trade that you expect, this choice impacts the limit price chosen
     * @param _limitPrice the min or max price that you will trade at, depending on if buying or selling
     */
    function priceHedge(
        uint256 _auctionTriggerTime,
        bool _isStrategySellingWSqueeth,
        uint256 _limitPrice
    ) external payable nonReentrant {
        require(_isPriceHedge(_auctionTriggerTime), "Price hedging not allowed");
        _hedge(_auctionTriggerTime, _isStrategySellingWSqueeth, _limitPrice);

        emit PriceHedge(msg.sender, _isStrategySellingWSqueeth, _limitPrice, _auctionTriggerTime);
    }

    /**
     * @notice check if hedging based on price threshold is allowed
     * @param _auctionTriggerTime the time when the price deviation threshold was exceeded and when the auction started
     * @return true if hedging is allowed
     */
    function checkPriceHedge(uint256 _auctionTriggerTime) external view returns (bool) {
        return _isPriceHedge(_auctionTriggerTime);
    }

    /**
     * @notice check if hedging based on time threshold is allowed
     * @return isTimeHedgeAllowed true if hedging is allowed
     * @return auctionTriggertime auction trigger timestamp
     */
    function checkTimeHedge() external view returns (bool, uint256) {
        return _isTimeHedge();
    }

    /**
     * @notice get wSqueeth debt amount associated with strategy token amount
     * @param _crabAmount strategy token amount
     * @return wSqueeth amount
     */
    function getWsqueethFromCrabAmount(uint256 _crabAmount) external view returns (uint256) {
        return _getDebtFromStrategyAmount(_crabAmount);
    }

    /**
     * @notice owner can set the delta hedge threshold as a percent scaled by 1e18 of ETH collateral
     * @dev the strategy will not allow a hedge if the trade size is below this threshold
     * @param _deltaHedgeThreshold minimum hedge size in a percent of ETH collateral
     */
    function setDeltaHedgeThreshold(uint256 _deltaHedgeThreshold) external onlyOwner {
        deltaHedgeThreshold = _deltaHedgeThreshold;

        emit SetDeltaHedgeThreshold(_deltaHedgeThreshold);
    }

    /**
     * @notice owner can set the twap period in seconds that is used for calculating twaps for hedging
     * @param _hedgingTwapPeriod the twap period, in seconds
     */
    function setHedgingTwapPeriod(uint32 _hedgingTwapPeriod) external onlyOwner {
        require(_hedgingTwapPeriod >= 180, "twap period is too short");

        hedgingTwapPeriod = _hedgingTwapPeriod;

        emit SetHedgingTwapPeriod(_hedgingTwapPeriod);
    }

    /**
     * @notice owner can set the hedge time threshold in seconds that determines how often the strategy can be hedged
     * @param _hedgeTimeThreshold the hedge time threshold, in seconds
     */
    function setHedgeTimeThreshold(uint256 _hedgeTimeThreshold) external onlyOwner {
        require(_hedgeTimeThreshold > 0, "invalid hedge time threshold");

        hedgeTimeThreshold = _hedgeTimeThreshold;

        emit SetHedgeTimeThreshold(_hedgeTimeThreshold);
    }

    /**
     * @notice owner can set the hedge time threshold in percent, scaled by 1e18 that determines the deviation in wPowerPerp price that can trigger a rebalance
     * @param _hedgePriceThreshold the hedge price threshold, in percent, scaled by 1e18
     */
    function setHedgePriceThreshold(uint256 _hedgePriceThreshold) external onlyOwner {
        require(_hedgePriceThreshold > 0, "invalid hedge price threshold");

        hedgePriceThreshold = _hedgePriceThreshold;

        emit SetHedgePriceThreshold(_hedgePriceThreshold);
    }

    /**
     * @notice owner can set the auction time, in seconds, that a hedge auction runs for
     * @param _auctionTime the length of the hedge auction in seconds
     */
    function setAuctionTime(uint256 _auctionTime) external onlyOwner {
        require(_auctionTime > 0, "invalid auction time");

        auctionTime = _auctionTime;

        emit SetAuctionTime(_auctionTime);
    }

    /**
     * @notice owner can set the min price multiplier in a percentage scaled by 1e18 (9e17 is 90%)
     * @dev the min price multiplier is multiplied by the TWAP price to get the intial auction price
     * @param _minPriceMultiplier the min price multiplier, a percentage, scaled by 1e18
     */
    function setMinPriceMultiplier(uint256 _minPriceMultiplier) external onlyOwner {
        require(_minPriceMultiplier < 1e18, "min price multiplier too high");

        minPriceMultiplier = _minPriceMultiplier;

        emit SetMinPriceMultiplier(_minPriceMultiplier);
    }

    /**
     * @notice owner can set the max price multiplier in a percentage scaled by 1e18 (11e18 is 110%)
     * @dev the max price multiplier is multiplied by the TWAP price to get the final auction price
     * @param _maxPriceMultiplier the max price multiplier, a percentage, scaled by 1e18
     */
    function setMaxPriceMultiplier(uint256 _maxPriceMultiplier) external onlyOwner {
        require(_maxPriceMultiplier > 1e18, "max price multiplier too low");

        maxPriceMultiplier = _maxPriceMultiplier;

        emit SetMaxPriceMultiplier(_maxPriceMultiplier);
    }

    /**
     * @notice get current auction details
     * @param _auctionTriggerTime timestamp where auction started
     * @return if strategy is selling wSqueeth, wSqueeth amount to auction, ETH proceeds, auction price, if auction direction has switched
     */
    function getAuctionDetails(uint256 _auctionTriggerTime)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        (uint256 strategyDebt, uint256 ethDelta) = _syncStrategyState();
        uint256 currentWSqueethPrice = IOracle(oracle).getTwap(
            ethWSqueethPool,
            wPowerPerp,
            weth,
            hedgingTwapPeriod,
            true
        );
        uint256 feeAdjustment = _calcFeeAdjustment();
        (bool isSellingAuction, ) = _checkAuctionType(strategyDebt, ethDelta, currentWSqueethPrice, feeAdjustment);
        uint256 auctionWSqueethEthPrice = _getAuctionPrice(_auctionTriggerTime, currentWSqueethPrice, isSellingAuction);
        (bool isStillSellingAuction, uint256 wSqueethToAuction) = _checkAuctionType(
            strategyDebt,
            ethDelta,
            auctionWSqueethEthPrice,
            feeAdjustment
        );
        bool isAuctionDirectionChanged = isSellingAuction != isStillSellingAuction;
        uint256 ethProceeds = wSqueethToAuction.wmul(auctionWSqueethEthPrice);

        return (isSellingAuction, wSqueethToAuction, ethProceeds, auctionWSqueethEthPrice, isAuctionDirectionChanged);
    }

    /**
     * @notice check if a user deposit puts the strategy above the cap
     * @dev reverts if a deposit amount puts strategy over the cap
     * @dev it is possible for the strategy to be over the cap from trading/hedging activities, but withdrawals are still allowed
     * @param _depositAmount the user deposit amount in ETH
     * @param _strategyCollateral the updated strategy collateral
     */
    function _checkStrategyCap(uint256 _depositAmount, uint256 _strategyCollateral) internal view {
        require(_strategyCollateral.add(_depositAmount) <= strategyCap, "Deposit exceeds strategy cap");
    }

    /**
     * @notice uniswap flash swap callback function
     * @dev this function will be called by flashswap callback function uniswapV3SwapCallback()
     * @param _caller address of original function caller
     * @param _amountToPay amount to pay back for flashswap
     * @param _callData arbitrary data attached to callback
     * @param _callSource identifier for which function triggered callback
     */
    function _strategyFlash(
        address _caller,
        address, /*_tokenIn*/
        address, /*_tokenOut*/
        uint24, /*_fee*/
        uint256 _amountToPay,
        bytes memory _callData,
        uint8 _callSource
    ) internal override {
        if (FLASH_SOURCE(_callSource) == FLASH_SOURCE.FLASH_DEPOSIT) {
            FlashDepositData memory data = abi.decode(_callData, (FlashDepositData));

            // convert WETH to ETH as Uniswap uses WETH
            IWETH9(weth).withdraw(IWETH9(weth).balanceOf(address(this)));

            //use user msg.value and unwrapped WETH from uniswap flash swap proceeds to deposit into strategy
            //will revert if data.totalDeposit is > eth balance in contract
            _deposit(_caller, data.totalDeposit, true);

            //repay the flash swap
            IWPowerPerp(wPowerPerp).transfer(ethWSqueethPool, _amountToPay);

            emit FlashDepositCallback(_caller, _amountToPay, address(this).balance);

            //return excess eth to the user that was not needed for slippage
            if (address(this).balance > 0) {
                payable(_caller).sendValue(address(this).balance);
            }
        } else if (FLASH_SOURCE(_callSource) == FLASH_SOURCE.FLASH_WITHDRAW) {
            FlashWithdrawData memory data = abi.decode(_callData, (FlashWithdrawData));

            //use flash swap wSqueeth proceeds to withdraw ETH along with user crabAmount
            uint256 ethToWithdraw = _withdraw(
                _caller,
                data.crabAmount,
                IWPowerPerp(wPowerPerp).balanceOf(address(this)),
                true
            );

            //use some amount of withdrawn ETH to repay flash swap
            IWETH9(weth).deposit{value: _amountToPay}();
            IWETH9(weth).transfer(ethWSqueethPool, _amountToPay);

            //excess ETH not used to repay flash swap is transferred to the user
            uint256 proceeds = ethToWithdraw.sub(_amountToPay);

            emit FlashWithdrawCallback(_caller, _amountToPay, proceeds);

            if (proceeds > 0) {
                payable(_caller).sendValue(proceeds);
            }
        } else if (FLASH_SOURCE(_callSource) == FLASH_SOURCE.FLASH_HEDGE_SELL) {
            //strategy is selling wSqueeth for ETH
            FlashHedgeData memory data = abi.decode(_callData, (FlashHedgeData));

            // convert WETH to ETH as Uniswap uses WETH
            IWETH9(weth).withdraw(IWETH9(weth).balanceOf(address(this)));
            //mint wSqueeth to pay hedger and repay flash swap, deposit ETH
            _executeSellAuction(_caller, data.ethProceeds, data.wSqueethAmount, data.ethProceeds, true);

            //determine excess wSqueeth that the auction would have sold but is not needed to repay flash swap
            uint256 wSqueethProfit = data.wSqueethAmount.sub(_amountToPay);

            //minimum profit check for hedger
            require(wSqueethProfit >= data.minWSqueeth, "profit is less than min wSqueeth");

            //repay flash swap and transfer profit to hedger
            IWPowerPerp(wPowerPerp).transfer(ethWSqueethPool, _amountToPay);
            IWPowerPerp(wPowerPerp).transfer(_caller, wSqueethProfit);
        } else if (FLASH_SOURCE(_callSource) == FLASH_SOURCE.FLASH_HEDGE_BUY) {
            //strategy is buying wSqueeth for ETH
            FlashHedgeData memory data = abi.decode(_callData, (FlashHedgeData));

            //withdraw ETH to pay hedger and repay flash swap, burn wSqueeth
            _executeBuyAuction(_caller, data.wSqueethAmount, data.ethProceeds, true);

            //determine excess ETH that the auction would have paid but is not needed to repay flash swap
            uint256 ethProfit = data.ethProceeds.sub(_amountToPay);

            //minimum profit check for hedger
            require(ethProfit >= data.minEth, "profit is less than min ETH");

            //repay flash swap and transfer profit to hedger
            IWETH9(weth).deposit{value: _amountToPay}();
            IWETH9(weth).transfer(ethWSqueethPool, _amountToPay);
            payable(_caller).sendValue(ethProfit);
        }
    }

    /**
     * @notice deposit into strategy
     * @dev if _isFlashDeposit is true, keeps wSqueeth in contract, otherwise sends to user
     * @param _depositor depositor address
     * @param _amount amount of ETH collateral to deposit
     * @param _isFlashDeposit true if called by flashDeposit
     * @return wSqueethToMint minted amount of WSqueeth
     * @return depositorCrabAmount minted CRAB strategy token amount
     */
    function _deposit(
        address _depositor,
        uint256 _amount,
        bool _isFlashDeposit
    ) internal returns (uint256, uint256) {
        (uint256 strategyDebt, uint256 strategyCollateral) = _syncStrategyState();
        _checkStrategyCap(_amount, strategyCollateral);

        (uint256 wSqueethToMint, uint256 ethFee) = _calcWsqueethToMintAndFee(_amount, strategyDebt, strategyCollateral);

        uint256 depositorCrabAmount = _calcSharesToMint(_amount.sub(ethFee), strategyCollateral, totalSupply());

        if (strategyDebt == 0 && strategyCollateral == 0) {
            // store hedge data as strategy is delta neutral at this point
            // only execute this upon first deposit
            uint256 wSqueethEthPrice = IOracle(oracle).getTwap(
                ethWSqueethPool,
                wPowerPerp,
                weth,
                hedgingTwapPeriod,
                true
            );
            timeAtLastHedge = block.timestamp;
            priceAtLastHedge = wSqueethEthPrice;
        }

        // mint wSqueeth and send it to msg.sender
        _mintWPowerPerp(_depositor, wSqueethToMint, _amount, _isFlashDeposit);
        // mint LP to depositor
        _mintStrategyToken(_depositor, depositorCrabAmount);

        return (wSqueethToMint, depositorCrabAmount);
    }

    /**
     * @notice withdraw WETH from strategy
     * @dev if _isFlashDeposit is true, keeps wSqueeth in contract, otherwise sends to user
     * @param _crabAmount amount of strategy token to burn
     * @param _wSqueethAmount amount of wSqueeth to burn
     * @param _isFlashWithdraw flag if called by flashWithdraw
     * @return ETH amount to withdraw
     */
    function _withdraw(
        address _from,
        uint256 _crabAmount,
        uint256 _wSqueethAmount,
        bool _isFlashWithdraw
    ) internal returns (uint256) {
        (, uint256 strategyCollateral) = _syncStrategyState();

        uint256 strategyShare = _calcCrabRatio(_crabAmount, totalSupply());
        uint256 ethToWithdraw = _calcEthToWithdraw(strategyShare, strategyCollateral);

        _burnWPowerPerp(_from, _wSqueethAmount, ethToWithdraw, _isFlashWithdraw);
        _burn(_from, _crabAmount);

        return ethToWithdraw;
    }

    /**
     * @notice hedging function to adjust collateral and debt to be eth delta neutral
     * @param _auctionTriggerTime timestamp where auction started
     * @param _isStrategySellingWSqueeth auction type, true for sell auction
     * @param _limitPrice hedger accepted auction price, should be the max price when auction is sell auction, min price when it is a buy auction
     */
    function _hedge(
        uint256 _auctionTriggerTime,
        bool _isStrategySellingWSqueeth,
        uint256 _limitPrice
    ) internal {
        (
            bool isSellingAuction,
            uint256 wSqueethToAuction,
            uint256 ethProceeds,
            uint256 auctionWSqueethEthPrice
        ) = _startAuction(_auctionTriggerTime);

        require(_isStrategySellingWSqueeth == isSellingAuction, "wrong auction type");

        if (isSellingAuction) {
            // Receiving ETH and paying wSqueeth
            require(auctionWSqueethEthPrice <= _limitPrice, "Auction price > max price");
            require(msg.value >= ethProceeds, "Low ETH amount received");

            _executeSellAuction(msg.sender, msg.value, wSqueethToAuction, ethProceeds, false);
        } else {
            require(msg.value == 0, "ETH attached for buy auction");
            // Receiving wSqueeth and paying ETH
            require(auctionWSqueethEthPrice >= _limitPrice, "Auction price < min price");
            _executeBuyAuction(msg.sender, wSqueethToAuction, ethProceeds, false);
        }

        emit Hedge(
            msg.sender,
            _isStrategySellingWSqueeth,
            _limitPrice,
            auctionWSqueethEthPrice,
            wSqueethToAuction,
            ethProceeds
        );
    }

    /**
     * @notice execute arb between auction price and uniswap price
     * @param _auctionTriggerTime auction starting time
     * @param _minWSqueeth minimum WSqueeth amount the caller willing to receive if hedge auction is selling WSqueeth
     * @param _minEth minimum ETH amount the caller is willing to receive if hedge auction is buying WSqueeth
     */
    function _hedgeOnUniswap(
        uint256 _auctionTriggerTime,
        uint256 _minWSqueeth,
        uint256 _minEth
    ) internal {
        (
            bool isSellingAuction,
            uint256 wSqueethToAuction,
            uint256 ethProceeds,
            uint256 auctionWSqueethEthPrice
        ) = _startAuction(_auctionTriggerTime);

        if (isSellingAuction) {
            _exactOutFlashSwap(
                wPowerPerp,
                weth,
                IUniswapV3Pool(ethWSqueethPool).fee(),
                ethProceeds,
                wSqueethToAuction,
                uint8(FLASH_SOURCE.FLASH_HEDGE_SELL),
                abi.encodePacked(wSqueethToAuction, ethProceeds, _minWSqueeth, _minEth)
            );
        } else {
            _exactOutFlashSwap(
                weth,
                wPowerPerp,
                IUniswapV3Pool(ethWSqueethPool).fee(),
                wSqueethToAuction,
                ethProceeds,
                uint8(FLASH_SOURCE.FLASH_HEDGE_BUY),
                abi.encodePacked(wSqueethToAuction, ethProceeds, _minWSqueeth, _minEth)
            );
        }

        emit HedgeOnUniswap(msg.sender, isSellingAuction, auctionWSqueethEthPrice, wSqueethToAuction, ethProceeds);
    }

    /**
     * @notice execute sell auction based on the parameters calculated
     * @dev if _isHedgingOnUniswap, wSqueeth minted is kept to repay flashswap, otherwise sent to seller
     * @param _buyer buyer address
     * @param _buyerAmount buyer ETH amount sent
     * @param _wSqueethToSell wSqueeth amount to sell
     * @param _ethToBuy ETH amount to buy
     * @param _isHedgingOnUniswap true if arbing with uniswap price
     */
    function _executeSellAuction(
        address _buyer,
        uint256 _buyerAmount,
        uint256 _wSqueethToSell,
        uint256 _ethToBuy,
        bool _isHedgingOnUniswap
    ) internal {
        if (_isHedgingOnUniswap) {
            _mintWPowerPerp(_buyer, _wSqueethToSell, _ethToBuy, true);
        } else {
            _mintWPowerPerp(_buyer, _wSqueethToSell, _ethToBuy, false);

            uint256 remainingEth = _buyerAmount.sub(_ethToBuy);

            if (remainingEth > 0) {
                payable(_buyer).sendValue(remainingEth);
            }
        }

        emit ExecuteSellAuction(_buyer, _wSqueethToSell, _ethToBuy, _isHedgingOnUniswap);
    }

    /**
     * @notice execute buy auction based on the parameters calculated
     * @dev if _isHedgingOnUniswap, ETH proceeds are not sent to seller
     * @param _seller seller address
     * @param _wSqueethToBuy wSqueeth amount to buy
     * @param _ethToSell ETH amount to sell
     * @param _isHedgingOnUniswap true if arbing with uniswap price
     */
    function _executeBuyAuction(
        address _seller,
        uint256 _wSqueethToBuy,
        uint256 _ethToSell,
        bool _isHedgingOnUniswap
    ) internal {
        _burnWPowerPerp(_seller, _wSqueethToBuy, _ethToSell, _isHedgingOnUniswap);

        if (!_isHedgingOnUniswap) {
            payable(_seller).sendValue(_ethToSell);
        }

        emit ExecuteBuyAuction(_seller, _wSqueethToBuy, _ethToSell, _isHedgingOnUniswap);
    }

    /**
     * @notice determine auction direction, price, and ensure auction hasn't switched directions
     * @param _auctionTriggerTime auction starting time
     * @return auction type
     * @return WSqueeth amount to sell or buy
     * @return ETH to sell/buy
     * @return auction WSqueeth/ETH price
     */
    function _startAuction(uint256 _auctionTriggerTime)
        internal
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 strategyDebt, uint256 ethDelta) = _syncStrategyState();
        uint256 currentWSqueethPrice = IOracle(oracle).getTwap(
            ethWSqueethPool,
            wPowerPerp,
            weth,
            hedgingTwapPeriod,
            true
        );
        uint256 feeAdjustment = _calcFeeAdjustment();
        (bool isSellingAuction, ) = _checkAuctionType(strategyDebt, ethDelta, currentWSqueethPrice, feeAdjustment);
        uint256 auctionWSqueethEthPrice = _getAuctionPrice(_auctionTriggerTime, currentWSqueethPrice, isSellingAuction);
        (bool isStillSellingAuction, uint256 wSqueethToAuction) = _checkAuctionType(
            strategyDebt,
            ethDelta,
            auctionWSqueethEthPrice,
            feeAdjustment
        );

        require(isSellingAuction == isStillSellingAuction, "auction direction changed");

        uint256 ethProceeds = wSqueethToAuction.wmul(auctionWSqueethEthPrice);

        timeAtLastHedge = block.timestamp;
        priceAtLastHedge = currentWSqueethPrice;

        return (isSellingAuction, wSqueethToAuction, ethProceeds, auctionWSqueethEthPrice);
    }

    /**
     * @notice sync strategy debt and collateral amount from vault
     * @return synced debt amount
     * @return synced collateral amount
     */
    function _syncStrategyState() internal view returns (uint256, uint256) {
        (, , uint256 syncedStrategyCollateral, uint256 syncedStrategyDebt) = _getVaultDetails();

        return (syncedStrategyDebt, syncedStrategyCollateral);
    }

    /**
     * @notice calculate the fee adjustment factor, which is the amount of ETH owed per 1 wSqueeth minted
     * @dev the fee is a based off the index value of squeeth and uses a twap scaled down by the PowerPerp's INDEX_SCALE
     * @return the fee adjustment factor
     */
    function _calcFeeAdjustment() internal view returns (uint256) {
        uint256 wSqueethEthPrice = Power2Base._getTwap(
            oracle,
            ethWSqueethPool,
            wPowerPerp,
            weth,
            POWER_PERP_PERIOD,
            false
        );
        uint256 feeRate = IController(powerTokenController).feeRate();
        return wSqueethEthPrice.mul(feeRate).div(10000);
    }

    /**
     * @notice calculate amount of wSqueeth to mint and fee paid from deposited amount
     * @param _depositedAmount amount of deposited WETH
     * @param _strategyDebtAmount amount of strategy debt
     * @param _strategyCollateralAmount collateral amount in strategy
     * @return amount of minted wSqueeth and ETH fee paid on minted squeeth
     */
    function _calcWsqueethToMintAndFee(
        uint256 _depositedAmount,
        uint256 _strategyDebtAmount,
        uint256 _strategyCollateralAmount
    ) internal view returns (uint256, uint256) {
        uint256 wSqueethToMint;
        uint256 feeAdjustment = _calcFeeAdjustment();

        if (_strategyDebtAmount == 0 && _strategyCollateralAmount == 0) {
            require(totalSupply() == 0, "Crab contracts shut down");

            uint256 wSqueethEthPrice = IOracle(oracle).getTwap(
                ethWSqueethPool,
                wPowerPerp,
                weth,
                hedgingTwapPeriod,
                true
            );
            uint256 squeethDelta = wSqueethEthPrice.wmul(2e18);
            wSqueethToMint = _depositedAmount.wdiv(squeethDelta.add(feeAdjustment));
        } else {
            wSqueethToMint = _depositedAmount.wmul(_strategyDebtAmount).wdiv(
                _strategyCollateralAmount.add(_strategyDebtAmount.wmul(feeAdjustment))
            );
        }

        uint256 fee = wSqueethToMint.wmul(feeAdjustment);

        return (wSqueethToMint, fee);
    }

    /**
     * @notice check if hedging based on time threshold is allowed
     * @return true if time hedging is allowed
     * @return auction trigger timestamp
     */
    function _isTimeHedge() internal view returns (bool, uint256) {
        uint256 auctionTriggerTime = timeAtLastHedge.add(hedgeTimeThreshold);

        return (block.timestamp >= auctionTriggerTime, auctionTriggerTime);
    }

    /**
     * @notice check if hedging based on price threshold is allowed
     * @param _auctionTriggerTime timestamp where auction started
     * @return true if hedging is allowed
     */
    function _isPriceHedge(uint256 _auctionTriggerTime) internal view returns (bool) {
        if (_auctionTriggerTime < timeAtLastHedge) return false;
        uint32 secondsToPriceHedgeTrigger = uint32(block.timestamp.sub(_auctionTriggerTime));
        uint256 wSqueethEthPriceAtTriggerTime = IOracle(oracle).getHistoricalTwap(
            ethWSqueethPool,
            wPowerPerp,
            weth,
            secondsToPriceHedgeTrigger + hedgingTwapPeriod,
            secondsToPriceHedgeTrigger
        );
        uint256 cachedRatio = wSqueethEthPriceAtTriggerTime.wdiv(priceAtLastHedge);
        uint256 priceThreshold = cachedRatio > 1e18 ? (cachedRatio).sub(1e18) : uint256(1e18).sub(cachedRatio);

        return priceThreshold >= hedgePriceThreshold;
    }

    /**
     * @notice calculate auction price based on auction direction, start time and wSqueeth price
     * @param _auctionTriggerTime timestamp where auction started
     * @param _wSqueethEthPrice WSqueeth/ETH price
     * @param _isSellingAuction auction type (true for selling, false for buying auction)
     * @return auction price
     */
    function _getAuctionPrice(
        uint256 _auctionTriggerTime,
        uint256 _wSqueethEthPrice,
        bool _isSellingAuction
    ) internal view returns (uint256) {
        uint256 auctionCompletionRatio = block.timestamp.sub(_auctionTriggerTime) >= auctionTime
            ? 1e18
            : (block.timestamp.sub(_auctionTriggerTime)).wdiv(auctionTime);

        uint256 priceMultiplier;
        if (_isSellingAuction) {
            priceMultiplier = maxPriceMultiplier.sub(
                auctionCompletionRatio.wmul(maxPriceMultiplier.sub(minPriceMultiplier))
            );
        } else {
            priceMultiplier = minPriceMultiplier.add(
                auctionCompletionRatio.wmul(maxPriceMultiplier.sub(minPriceMultiplier))
            );
        }

        return _wSqueethEthPrice.wmul(priceMultiplier);
    }

    /**
     * @notice check the direction of auction and the target amount of wSqueeth to hedge
     * @param _debt strategy debt
     * @param _ethDelta ETH delta (amount of ETH in strategy)
     * @param _wSqueethEthPrice WSqueeth/ETH price
     * @param _feeAdjustment the fee adjustment, the amount of ETH owed per wSqueeth minted
     * @return auction type(sell or buy) and auction initial target hedge in wSqueeth
     */
    function _checkAuctionType(
        uint256 _debt,
        uint256 _ethDelta,
        uint256 _wSqueethEthPrice,
        uint256 _feeAdjustment
    ) internal view returns (bool, uint256) {
        uint256 wSqueethDelta = _debt.wmul(2e18).wmul(_wSqueethEthPrice);

        (uint256 targetHedge, bool isSellingAuction) = _getTargetHedgeAndAuctionType(
            wSqueethDelta,
            _ethDelta,
            _wSqueethEthPrice,
            _feeAdjustment
        );

        require(targetHedge.wmul(_wSqueethEthPrice).wdiv(_ethDelta) > deltaHedgeThreshold, "strategy is delta neutral");

        return (isSellingAuction, targetHedge);
    }

    /**
     * @dev calculate amount of strategy token to mint for depositor
     * @param _amount amount of ETH deposited
     * @param _strategyCollateralAmount amount of strategy collateral
     * @param _crabTotalSupply total supply of strategy token
     * @return amount of strategy token to mint
     */
    function _calcSharesToMint(
        uint256 _amount,
        uint256 _strategyCollateralAmount,
        uint256 _crabTotalSupply
    ) internal pure returns (uint256) {
        uint256 depositorShare = _amount.wdiv(_strategyCollateralAmount.add(_amount));

        if (_crabTotalSupply != 0) return _crabTotalSupply.wmul(depositorShare).wdiv(uint256(1e18).sub(depositorShare));

        return _amount;
    }

    /**
     * @notice calculates the ownership proportion for strategy debt and collateral relative to a total amount of strategy tokens
     * @param _crabAmount strategy token amount
     * @param _totalSupply strategy total supply
     * @return ownership proportion of a strategy token amount relative to the total strategy tokens
     */
    function _calcCrabRatio(uint256 _crabAmount, uint256 _totalSupply) internal pure returns (uint256) {
        return _crabAmount.wdiv(_totalSupply);
    }

    /**
     * @notice calculate ETH to withdraw from strategy given a ownership proportion
     * @param _crabRatio crab ratio
     * @param _strategyCollateralAmount amount of collateral in strategy
     * @return amount of ETH allowed to withdraw
     */
    function _calcEthToWithdraw(uint256 _crabRatio, uint256 _strategyCollateralAmount) internal pure returns (uint256) {
        return _strategyCollateralAmount.wmul(_crabRatio);
    }

    /**
     * @notice determine target hedge and auction type (selling/buying auction)
     * @dev target hedge is the amount of WSqueeth the auction needs to sell or buy to be eth delta neutral
     * @param _wSqueethDelta WSqueeth delta
     * @param _ethDelta ETH delta
     * @param _wSqueethEthPrice WSqueeth/ETH price
     * @param _feeAdjustment the fee adjustment, the amount of ETH owed per wSqueeth minted
     * @return target hedge in wSqueeth
     * @return auction type: true if auction is selling WSqueeth, false if buying WSqueeth
     */
    function _getTargetHedgeAndAuctionType(
        uint256 _wSqueethDelta,
        uint256 _ethDelta,
        uint256 _wSqueethEthPrice,
        uint256 _feeAdjustment
    ) internal pure returns (uint256, bool) {
        return
            (_wSqueethDelta > _ethDelta)
                ? ((_wSqueethDelta.sub(_ethDelta)).wdiv(_wSqueethEthPrice), false)
                : ((_ethDelta.sub(_wSqueethDelta)).wdiv(_wSqueethEthPrice.add(_feeAdjustment)), true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

pragma abicoder v2;

import {VaultLib} from "../libs/VaultLib.sol";

interface IController {
    function ethQuoteCurrencyPool() external view returns (address);

    function feeRate() external view returns (uint256);

    function getFee(
        uint256 _vaultId,
        uint256 _wPowerPerpAmount,
        uint256 _collateralAmount
    ) external view returns (uint256);

    function quoteCurrency() external view returns (address);

    function vaults(uint256 _vaultId) external view returns (VaultLib.Vault memory);

    function shortPowerPerp() external view returns (address);

    function wPowerPerp() external view returns (address);

    function getExpectedNormalizationFactor() external view returns (uint256);

    function mintPowerPerpAmount(
        uint256 _vaultId,
        uint256 _powerPerpAmount,
        uint256 _uniTokenId
    ) external payable returns (uint256 vaultId, uint256 wPowerPerpAmount);

    function mintWPowerPerpAmount(
        uint256 _vaultId,
        uint256 _wPowerPerpAmount,
        uint256 _uniTokenId
    ) external payable returns (uint256 vaultId);

    /**
     * Deposit collateral into a vault
     */
    function deposit(uint256 _vaultId) external payable;

    /**
     * Withdraw collateral from a vault.
     */
    function withdraw(uint256 _vaultId, uint256 _amount) external payable;

    function burnWPowerPerpAmount(
        uint256 _vaultId,
        uint256 _wPowerPerpAmount,
        uint256 _withdrawAmount
    ) external;

    function burnOnPowerPerpAmount(
        uint256 _vaultId,
        uint256 _powerPerpAmount,
        uint256 _withdrawAmount
    ) external returns (uint256 wPowerPerpAmount);

    function liquidate(uint256 _vaultId, uint256 _maxDebtAmount) external returns (uint256);

    function updateOperator(uint256 _vaultId, address _operator) external;

    /**
     * External function to update the normalized factor as a way to pay funding.
     */
    function applyFunding() external;

    function redeemShort(uint256 _vaultId) external;

    function reduceDebtShutdown(uint256 _vaultId) external;

    function isShutDown() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWPowerPerp is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

interface IOracle {
    function getHistoricalTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        uint32 _periodToHistoricPrice
    ) external view returns (uint256);

    function getTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) external view returns (uint256);

    function getMaxPeriod(address _pool) external view returns (uint32);

    function getTimeWeightedAverageTickSafe(address _pool, uint32 _period)
        external
        view
        returns (int24 timeWeightedAverageTick);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
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

pragma solidity ^0.7.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity =0.7.6;

pragma abicoder v2;

// interface
import {IController} from "../../interfaces/IController.sol";
import {IWPowerPerp} from "../../interfaces/IWPowerPerp.sol";

// contract
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// lib
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
// StrategyMath licensed under AGPL-3.0-only
import {StrategyMath} from "./StrategyMath.sol";
import {VaultLib} from "../../libs/VaultLib.sol";

/**
 * @dev StrategyBase contract
 * @notice base contract for PowerToken strategy
 * @author opyn team
 */
contract StrategyBase is ERC20 {
    using StrategyMath for uint256;
    using Address for address payable;

    /// @dev power token controller
    IController public powerTokenController;

    /// @dev WETH token
    address public immutable weth;
    address public immutable wPowerPerp;

    /// @dev power token strategy vault ID
    uint256 public immutable vaultId;

    /**
     * @notice constructor for StrategyBase
     * @dev this will open a vault in the power token contract and store the vault ID
     * @param _powerTokenController power token controller address
     * @param _weth weth token address
     * @param _name token name for strategy ERC20 token
     * @param _symbol token symbol for strategy ERC20 token
     */
    constructor(address _powerTokenController, address _weth, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        require(_powerTokenController != address(0), "invalid controller address");
        require(_weth != address(0), "invalid weth address");

        weth = _weth;
        powerTokenController = IController(_powerTokenController);
        wPowerPerp = address(powerTokenController.wPowerPerp());
        vaultId = powerTokenController.mintWPowerPerpAmount(0, 0, 0);
    }
    /**
     * @notice get power token strategy vault ID 
     * @return vault ID
     */
    function getStrategyVaultId() external view returns (uint256) {
        return vaultId;
    }

    /**
     * @notice get the vault composition of the strategy 
     * @return operator
     * @return nft collateral id
     * @return collateral amount
     * @return short amount
    */
    function getVaultDetails() external view returns (address, uint256, uint256, uint256) {
        return _getVaultDetails();
    }

    /**
     * @notice mint WPowerPerp and deposit collateral
    * @dev this function will not send WPowerPerp to msg.sender if _keepWSqueeth == true
     * @param _to receiver address
     * @param _wAmount amount of WPowerPerp to mint
     * @param _collateral amount of collateral to deposit
     * @param _keepWsqueeth keep minted wSqueeth in this contract if it is set to true
     */
    function _mintWPowerPerp(
        address _to,
        uint256 _wAmount,
        uint256 _collateral,
        bool _keepWsqueeth
    ) internal {
        powerTokenController.mintWPowerPerpAmount{value: _collateral}(vaultId, _wAmount, 0);

        if (!_keepWsqueeth) {
            IWPowerPerp(wPowerPerp).transfer(_to, _wAmount);
        }
    }

    /**
     * @notice burn WPowerPerp and withdraw collateral
     * @dev this function will not take WPowerPerp from msg.sender if _isOwnedWSqueeth == true
     * @param _from WPowerPerp holder address
     * @param _amount amount of wPowerPerp to burn
     * @param _collateralToWithdraw amount of collateral to withdraw
     * @param _isOwnedWSqueeth transfer WPowerPerp from holder if it is set to false
     */
    function _burnWPowerPerp(
        address _from,
        uint256 _amount,
        uint256 _collateralToWithdraw,
        bool _isOwnedWSqueeth
    ) internal {
        if (!_isOwnedWSqueeth) {
            IWPowerPerp(wPowerPerp).transferFrom(_from, address(this), _amount);
        }

        powerTokenController.burnWPowerPerpAmount(vaultId, _amount, _collateralToWithdraw);
    }

    /**
     * @notice mint strategy token
     * @param _to recepient address
     * @param _amount token amount
     */
    function _mintStrategyToken(address _to, uint256 _amount) internal {
        _mint(_to, _amount);
    }

    /**
     * @notice get strategy debt amount for a specific strategy token amount
     * @param _strategyAmount strategy amount
     * @return debt amount
     */
    function _getDebtFromStrategyAmount(uint256 _strategyAmount) internal view returns (uint256) {
        (, , ,uint256 strategyDebt) = _getVaultDetails();
        return strategyDebt.wmul(_strategyAmount).wdiv(totalSupply());
    }

    /**
     * @notice get the vault composition of the strategy 
     * @return operator
     * @return nft collateral id
     * @return collateral amount
     * @return short amount
     */
    function _getVaultDetails() internal view returns (address, uint256, uint256, uint256) {
        VaultLib.Vault memory strategyVault = powerTokenController.vaults(vaultId);

        return (strategyVault.operator, strategyVault.NftCollateralId, strategyVault.collateralAmount, strategyVault.shortAmount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

// interface
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// lib
import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@uniswap/v3-periphery/contracts/libraries/Path.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import '@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';

contract StrategyFlashSwap is IUniswapV3SwapCallback {
    using Path for bytes;
    using SafeCast for uint256;
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    /// @dev Uniswap factory address
    address public immutable factory;

    struct SwapCallbackData {
        bytes path;
        address caller;
        uint8 callSource;
        bytes callData;
    }

    /**
     * @dev constructor
     * @param _factory uniswap factory address
     */
    constructor(
        address _factory
    ) {
        require(_factory != address(0), "invalid factory address");
        factory = _factory;
    }

    /**
     * @notice uniswap swap callback function for flashes
     * @param amount0Delta amount of token0
     * @param amount1Delta amount of token1
     * @param _data callback data encoded as SwapCallbackData struct
     */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported

        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        //ensure that callback comes from uniswap pool
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee);

        //determine the amount that needs to be repaid as part of the flashswap
        uint256 amountToPay =
            amount0Delta > 0
                ?  uint256(amount0Delta)
                :  uint256(amount1Delta);
        
        //calls the strategy function that uses the proceeds from flash swap and executes logic to have an amount of token to repay the flash swap
        _strategyFlash(data.caller, tokenIn, tokenOut, fee, amountToPay, data.callData, data.callSource);
    }

    /**
     * @notice execute an exact-in flash swap (specify an exact amount to pay)
     * @param _tokenIn token address to sell
     * @param _tokenOut token address to receive
     * @param _fee pool fee
     * @param _amountIn amount to sell
     * @param _amountOutMinimum minimum amount to receive
     * @param _callSource function call source
     * @param _data arbitrary data assigned with the call 
     */
    function _exactInFlashSwap(address _tokenIn, address _tokenOut, uint24 _fee, uint256 _amountIn, uint256 _amountOutMinimum, uint8 _callSource, bytes memory _data) internal {
        //calls internal uniswap swap function that will trigger a callback for the flash swap
        uint256 amountOut = _exactInputInternal(
            _amountIn,
            address(this),
            uint160(0),
            SwapCallbackData({path: abi.encodePacked(_tokenIn, _fee, _tokenOut), caller: msg.sender, callSource: _callSource, callData: _data})
        );
       
        //slippage limit check
        require(amountOut >= _amountOutMinimum, "amount out less than min");
    }


    /**
     * @notice execute an exact-out flash swap (specify an exact amount to receive)
     * @param _tokenIn token address to sell
     * @param _tokenOut token address to receive
     * @param _fee pool fee
     * @param _amountOut exact amount to receive
     * @param _amountInMaximum maximum amount to sell
     * @param _callSource function call source
     * @param _data arbitrary data assigned with the call 
     */
    function _exactOutFlashSwap(address _tokenIn, address _tokenOut, uint24 _fee, uint256 _amountOut, uint256 _amountInMaximum, uint8 _callSource, bytes memory _data) internal {
        //calls internal uniswap swap function that will trigger a callback for the flash swap
        uint256 amountIn = _exactOutputInternal(
            _amountOut,
            address(this),
            uint160(0),
            SwapCallbackData({path: abi.encodePacked(_tokenOut, _fee, _tokenIn), caller: msg.sender, callSource: _callSource, callData: _data})
        );
        
        //slippage limit check
        require(amountIn <= _amountInMaximum, "amount in greater than max");
    }


    /**
     * @notice function to be called by uniswap callback. 
     * @dev this function should be overridden by the child contract
     * param _caller initial strategy function caller
     * param _tokenIn token address sold
     * param _tokenOut token address bought
     * param _fee pool fee
     * param _amountToPay amount to pay for the pool second token
     * param _callData arbitrary data assigned with the flashswap call 
     * param _callSource function call source
     */
    function _strategyFlash(address /*_caller*/, address /*_tokenIn*/, address /*_tokenOut*/, uint24 /*_fee*/, uint256 /*_amountToPay*/, bytes memory _callData, uint8 _callSource) internal virtual {}
    
    /** 
    * @notice internal function for exact-in swap on uniswap (specify exact amount to pay)
    * @param _amountIn amount of token to pay
    * @param _recipient recipient for receive
    * @param _sqrtPriceLimitX96 price limit
    * @return amount of token bought (amountOut)
    */
    function _exactInputInternal(
        uint256 _amountIn,
        address _recipient,
        uint160 _sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256) {
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
       
        //uniswap token0 has a lower address than token1
        //if tokenIn<tokenOut, we are selling an exact amount of token0 in exchange for token1
        //zeroForOne determines which token is being sold and which is being bought
        bool zeroForOne = tokenIn < tokenOut;

        //swap on uniswap, including data to trigger call back for flashswap
        (int256 amount0, int256 amount1) =
            _getPool(tokenIn, tokenOut, fee).swap(
                _recipient,
                zeroForOne,
                _amountIn.toInt256(),
                _sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : _sqrtPriceLimitX96,
                abi.encode(data)
            );
        
        //determine the amountOut based on which token has a lower address
        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /** 
    * @notice internal function for exact-out swap on uniswap (specify exact amount to receive)
    * @param _amountOut amount of token to receive
    * @param _recipient recipient for receive
    * @param _sqrtPriceLimitX96 price limit
    * @return amount of token sold (amountIn)
    */
    function _exactOutputInternal(
        uint256 _amountOut,
        address _recipient,
        uint160 _sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256) {
        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        //uniswap token0 has a lower address than token1
        //if tokenIn<tokenOut, we are buying an exact amount of token1 in exchange for token0
        //zeroForOne determines which token is being sold and which is being bought
        bool zeroForOne = tokenIn < tokenOut;
        
        //swap on uniswap, including data to trigger call back for flashswap
        (int256 amount0Delta, int256 amount1Delta) =
            _getPool(tokenIn, tokenOut, fee).swap(
                _recipient,
                zeroForOne,
                -_amountOut.toInt256(),
                _sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : _sqrtPriceLimitX96,
                abi.encode(data)
            );

        //determine the amountIn and amountOut based on which token has a lower address
        (uint256 amountIn, uint256 amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (_sqrtPriceLimitX96 == 0) require(amountOutReceived == _amountOut);

        return amountIn;
    }

    /** 
    * @notice returns the uniswap pool for the given token pair and fee
    * @dev the pool contract may or may not exist
    * @param tokenA address of first token 
    * @param tokenB address of second token 
    * @param fee fee tier for pool
    */
    function _getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: AGPL-3.0-only

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;


/**
 * @notice Copied from https://github.com/dapphub/ds-math/blob/e70a364787804c1ded9801ed6c27b440a86ebd32/src/math.sol
 * @dev change contract to library, added div() function
 */
library StrategyMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

//interface
import {IOracle} from "../interfaces/IOracle.sol";

//lib
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

library Power2Base {
    using SafeMath for uint256;

    uint32 private constant TWAP_PERIOD = 420 seconds;
    uint256 private constant INDEX_SCALE = 1e4;
    uint256 private constant ONE = 1e18;
    uint256 private constant ONE_ONE = 1e36;

    /**
     * @notice return the scaled down index of the power perp in USD, scaled by 18 decimals
     * @param _period period of time for the twap in seconds (cannot be longer than maximum period for the pool)
     * @param _oracle oracle address
     * @param _ethQuoteCurrencyPool uniswap v3 pool for weth / quoteCurrency
     * @param _weth weth address
     * @param _quoteCurrency quoteCurrency address
     * @return for squeeth, return ethPrice^2
     */
    function _getIndex(
        uint32 _period,
        address _oracle,
        address _ethQuoteCurrencyPool,
        address _weth,
        address _quoteCurrency
    ) internal view returns (uint256) {
        uint256 ethQuoteCurrencyPrice = _getScaledTwap(
            _oracle,
            _ethQuoteCurrencyPool,
            _weth,
            _quoteCurrency,
            _period,
            false
        );
        return ethQuoteCurrencyPrice.mul(ethQuoteCurrencyPrice).div(ONE);
    }

    /**
     * @notice return the unscaled index of the power perp in USD, scaled by 18 decimals
     * @param _period period of time for the twap in seconds (cannot be longer than maximum period for the pool)
     * @param _oracle oracle address
     * @param _ethQuoteCurrencyPool uniswap v3 pool for weth / quoteCurrency
     * @param _weth weth address
     * @param _quoteCurrency quoteCurrency address
     * @return for squeeth, return ethPrice^2
     */
    function _getUnscaledIndex(
        uint32 _period,
        address _oracle,
        address _ethQuoteCurrencyPool,
        address _weth,
        address _quoteCurrency
    ) internal view returns (uint256) {
        uint256 ethQuoteCurrencyPrice = _getTwap(_oracle, _ethQuoteCurrencyPool, _weth, _quoteCurrency, _period, false);
        return ethQuoteCurrencyPrice.mul(ethQuoteCurrencyPrice).div(ONE);
    }

    /**
     * @notice return the mark price of power perp in quoteCurrency, scaled by 18 decimals
     * @param _period period of time for the twap in seconds (cannot be longer than maximum period for the pool)
     * @param _oracle oracle address
     * @param _wSqueethEthPool uniswap v3 pool for wSqueeth / weth
     * @param _ethQuoteCurrencyPool uniswap v3 pool for weth / quoteCurrency
     * @param _weth weth address
     * @param _quoteCurrency quoteCurrency address
     * @param _wSqueeth wSqueeth address
     * @param _normalizationFactor current normalization factor
     * @return for squeeth, return ethPrice * squeethPriceInEth
     */
    function _getDenormalizedMark(
        uint32 _period,
        address _oracle,
        address _wSqueethEthPool,
        address _ethQuoteCurrencyPool,
        address _weth,
        address _quoteCurrency,
        address _wSqueeth,
        uint256 _normalizationFactor
    ) internal view returns (uint256) {
        uint256 ethQuoteCurrencyPrice = _getScaledTwap(
            _oracle,
            _ethQuoteCurrencyPool,
            _weth,
            _quoteCurrency,
            _period,
            false
        );
        uint256 wsqueethEthPrice = _getTwap(_oracle, _wSqueethEthPool, _wSqueeth, _weth, _period, false);

        return wsqueethEthPrice.mul(ethQuoteCurrencyPrice).div(_normalizationFactor);
    }

    /**
     * @notice get the fair collateral value for a _debtAmount of wSqueeth
     * @dev the actual amount liquidator can get should have a 10% bonus on top of this value.
     * @param _debtAmount wSqueeth amount paid by liquidator
     * @param _oracle oracle address
     * @param _wSqueethEthPool uniswap v3 pool for wSqueeth / weth
     * @param _wSqueeth wSqueeth address
     * @param _weth weth address
     * @return returns value of debt in ETH
     */
    function _getDebtValueInEth(
        uint256 _debtAmount,
        address _oracle,
        address _wSqueethEthPool,
        address _wSqueeth,
        address _weth
    ) internal view returns (uint256) {
        uint256 wSqueethPrice = _getTwap(_oracle, _wSqueethEthPool, _wSqueeth, _weth, TWAP_PERIOD, false);
        return _debtAmount.mul(wSqueethPrice).div(ONE);
    }

    /**
     * @notice request twap from our oracle, scaled down by INDEX_SCALE
     * @param _oracle oracle address
     * @param _pool uniswap v3 pool address
     * @param _base base currency. to get eth/usd price, eth is base token
     * @param _quote quote currency. to get eth/usd price, usd is the quote currency
     * @param _period number of seconds in the past to start calculating time-weighted average.
     * @param _checkPeriod check that period is not longer than maximum period for the pool to prevent reverts
     * @return twap price scaled down by INDEX_SCALE
     */
    function _getScaledTwap(
        address _oracle,
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) internal view returns (uint256) {
        uint256 twap = _getTwap(_oracle, _pool, _base, _quote, _period, _checkPeriod);
        return twap.div(INDEX_SCALE);
    }

    /**
     * @notice request twap from our oracle
     * @dev this will revert if period is > max period for the pool
     * @param _oracle oracle address
     * @param _pool uniswap v3 pool address
     * @param _base base currency. to get eth/quoteCurrency price, eth is base token
     * @param _quote quote currency. to get eth/quoteCurrency price, quoteCurrency is the quote currency
     * @param _period number of seconds in the past to start calculating time-weighted average
     * @param _checkPeriod check that period is not longer than maximum period for the pool to prevent reverts
     * @return human readable price. scaled by 1e18
     */
    function _getTwap(
        address _oracle,
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) internal view returns (uint256) {
        // period reaching this point should be check, otherwise might revert
        return IOracle(_oracle).getTwap(_pool, _base, _quote, _period, _checkPeriod);
    }

    /**
     * @notice get the index value of wsqueeth in wei, used when system settles
     * @dev the index of squeeth is ethPrice^2, so each squeeth will need to pay out {ethPrice} eth
     * @param _wsqueethAmount amount of wsqueeth used in settlement
     * @param _indexPriceForSettlement index price for settlement
     * @param _normalizationFactor current normalization factor
     * @return amount in wei that should be paid to the token holder
     */
    function _getLongSettlementValue(
        uint256 _wsqueethAmount,
        uint256 _indexPriceForSettlement,
        uint256 _normalizationFactor
    ) internal pure returns (uint256) {
        return _wsqueethAmount.mul(_normalizationFactor).mul(_indexPriceForSettlement).div(ONE_ONE);
    }
}

//SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;

//interface
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

//lib
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {TickMathExternal} from "./TickMathExternal.sol";
import {SqrtPriceMathPartial} from "./SqrtPriceMathPartial.sol";
import {Uint256Casting} from "./Uint256Casting.sol";

/**
 * Error code:
 * V1: Vault already had nft
 * V2: Vault has no NFT
 */
library VaultLib {
    using SafeMath for uint256;
    using Uint256Casting for uint256;

    uint256 constant ONE_ONE = 1e36;

    // the collateralization ratio (CR) is checked with the numerator and denominator separately
    // a user is safe if - collateral value >= (COLLAT_RATIO_NUMER/COLLAT_RATIO_DENOM)* debt value
    uint256 public constant CR_NUMERATOR = 3;
    uint256 public constant CR_DENOMINATOR = 2;

    struct Vault {
        // the address that can update the vault
        address operator;
        // uniswap position token id deposited into the vault as collateral
        // 2^32 is 4,294,967,296, which means the vault structure will work with up to 4 billion positions
        uint32 NftCollateralId;
        // amount of eth (wei) used in the vault as collateral
        // 2^96 / 1e18 = 79,228,162,514, which means a vault can store up to 79 billion eth
        // when we need to do calculations, we always cast this number to uint256 to avoid overflow
        uint96 collateralAmount;
        // amount of wPowerPerp minted from the vault
        uint128 shortAmount;
    }

    /**
     * @notice add eth collateral to a vault
     * @param _vault in-memory vault
     * @param _amount amount of eth to add
     */
    function addEthCollateral(Vault memory _vault, uint256 _amount) internal pure {
        _vault.collateralAmount = uint256(_vault.collateralAmount).add(_amount).toUint96();
    }

    /**
     * @notice add uniswap position token collateral to a vault
     * @param _vault in-memory vault
     * @param _tokenId uniswap position token id
     */
    function addUniNftCollateral(Vault memory _vault, uint256 _tokenId) internal pure {
        require(_vault.NftCollateralId == 0, "V1");
        require(_tokenId != 0, "C23");
        _vault.NftCollateralId = _tokenId.toUint32();
    }

    /**
     * @notice remove eth collateral from a vault
     * @param _vault in-memory vault
     * @param _amount amount of eth to remove
     */
    function removeEthCollateral(Vault memory _vault, uint256 _amount) internal pure {
        _vault.collateralAmount = uint256(_vault.collateralAmount).sub(_amount).toUint96();
    }

    /**
     * @notice remove uniswap position token collateral from a vault
     * @param _vault in-memory vault
     */
    function removeUniNftCollateral(Vault memory _vault) internal pure {
        require(_vault.NftCollateralId != 0, "V2");
        _vault.NftCollateralId = 0;
    }

    /**
     * @notice add debt to vault
     * @param _vault in-memory vault
     * @param _amount amount of debt to add
     */
    function addShort(Vault memory _vault, uint256 _amount) internal pure {
        _vault.shortAmount = uint256(_vault.shortAmount).add(_amount).toUint128();
    }

    /**
     * @notice remove debt from vault
     * @param _vault in-memory vault
     * @param _amount amount of debt to remove
     */
    function removeShort(Vault memory _vault, uint256 _amount) internal pure {
        _vault.shortAmount = uint256(_vault.shortAmount).sub(_amount).toUint128();
    }

    /**
     * @notice check if a vault is properly collateralized
     * @param _vault the vault we want to check
     * @param _positionManager address of the uniswap position manager
     * @param _normalizationFactor current _normalizationFactor
     * @param _ethQuoteCurrencyPrice current eth price scaled by 1e18
     * @param _minCollateral minimum collateral that needs to be in a vault
     * @param _wsqueethPoolTick current price tick for wsqueeth pool
     * @param _isWethToken0 whether weth is token0 in the wsqueeth pool
     * @return true if the vault is sufficiently collateralized
     * @return true if the vault is considered as a dust vault
     */
    function getVaultStatus(
        Vault memory _vault,
        address _positionManager,
        uint256 _normalizationFactor,
        uint256 _ethQuoteCurrencyPrice,
        uint256 _minCollateral,
        int24 _wsqueethPoolTick,
        bool _isWethToken0
    ) internal view returns (bool, bool) {
        if (_vault.shortAmount == 0) return (true, false);

        uint256 debtValueInETH = uint256(_vault.shortAmount).mul(_normalizationFactor).mul(_ethQuoteCurrencyPrice).div(
            ONE_ONE
        );
        uint256 totalCollateral = _getEffectiveCollateral(
            _vault,
            _positionManager,
            _normalizationFactor,
            _ethQuoteCurrencyPrice,
            _wsqueethPoolTick,
            _isWethToken0
        );

        bool isDust = totalCollateral < _minCollateral;
        bool isAboveWater = totalCollateral.mul(CR_DENOMINATOR) >= debtValueInETH.mul(CR_NUMERATOR);
        return (isAboveWater, isDust);
    }

    /**
     * @notice get the total effective collateral of a vault, which is:
     *         collateral amount + uniswap position token equivelent amount in eth
     * @param _vault the vault we want to check
     * @param _positionManager address of the uniswap position manager
     * @param _normalizationFactor current _normalizationFactor
     * @param _ethQuoteCurrencyPrice current eth price scaled by 1e18
     * @param _wsqueethPoolTick current price tick for wsqueeth pool
     * @param _isWethToken0 whether weth is token0 in the wsqueeth pool
     * @return the total worth of collateral in the vault
     */
    function _getEffectiveCollateral(
        Vault memory _vault,
        address _positionManager,
        uint256 _normalizationFactor,
        uint256 _ethQuoteCurrencyPrice,
        int24 _wsqueethPoolTick,
        bool _isWethToken0
    ) internal view returns (uint256) {
        if (_vault.NftCollateralId == 0) return _vault.collateralAmount;

        // the user has deposited uniswap position token as collateral, see how much eth / wSqueeth the uniswap position token has
        (uint256 nftEthAmount, uint256 nftWsqueethAmount) = _getUniPositionBalances(
            _positionManager,
            _vault.NftCollateralId,
            _wsqueethPoolTick,
            _isWethToken0
        );
        // convert squeeth amount from uniswap position token as equivalent amount of collateral
        uint256 wSqueethIndexValueInEth = nftWsqueethAmount.mul(_normalizationFactor).mul(_ethQuoteCurrencyPrice).div(
            ONE_ONE
        );
        // add eth value from uniswap position token as collateral
        return nftEthAmount.add(wSqueethIndexValueInEth).add(_vault.collateralAmount);
    }

    /**
     * @notice determine how much eth / wPowerPerp the uniswap position contains
     * @param _positionManager address of the uniswap position manager
     * @param _tokenId uniswap position token id
     * @param _wPowerPerpPoolTick current price tick
     * @param _isWethToken0 whether weth is token0 in the pool
     * @return ethAmount the eth amount this LP token contains
     * @return wPowerPerpAmount the wPowerPerp amount this LP token contains
     */
    function _getUniPositionBalances(
        address _positionManager,
        uint256 _tokenId,
        int24 _wPowerPerpPoolTick,
        bool _isWethToken0
    ) internal view returns (uint256 ethAmount, uint256 wPowerPerpAmount) {
        (
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = _getUniswapPositionInfo(_positionManager, _tokenId);
        (uint256 amount0, uint256 amount1) = _getToken0Token1Balances(
            tickLower,
            tickUpper,
            _wPowerPerpPoolTick,
            liquidity
        );

        return
            _isWethToken0
                ? (amount0 + tokensOwed0, amount1 + tokensOwed1)
                : (amount1 + tokensOwed1, amount0 + tokensOwed0);
    }

    /**
     * @notice get uniswap position token info
     * @param _positionManager address of the uniswap position position manager
     * @param _tokenId uniswap position token id
     * @return tickLower lower tick of the position
     * @return tickUpper upper tick of the position
     * @return liquidity raw liquidity amount of the position
     * @return tokensOwed0 amount of token 0 can be collected as fee
     * @return tokensOwed1 amount of token 1 can be collected as fee
     */
    function _getUniswapPositionInfo(address _positionManager, uint256 _tokenId)
        internal
        view
        returns (
            int24,
            int24,
            uint128,
            uint128,
            uint128
        )
    {
        INonfungiblePositionManager positionManager = INonfungiblePositionManager(_positionManager);
        (
            ,
            ,
            ,
            ,
            ,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = positionManager.positions(_tokenId);
        return (tickLower, tickUpper, liquidity, tokensOwed0, tokensOwed1);
    }

    /**
     * @notice get balances of token0 / token1 in a uniswap position
     * @dev knowing liquidity, tick range, and current tick gives balances
     * @param _tickLower address of the uniswap position manager
     * @param _tickUpper uniswap position token id
     * @param _tick current price tick used for calculation
     * @return amount0 the amount of token0 in the uniswap position token
     * @return amount1 the amount of token1 in the uniswap position token
     */
    function _getToken0Token1Balances(
        int24 _tickLower,
        int24 _tickUpper,
        int24 _tick,
        uint128 _liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        // get the current price and tick from wPowerPerp pool
        uint160 sqrtPriceX96 = TickMathExternal.getSqrtRatioAtTick(_tick);

        if (_tick < _tickLower) {
            amount0 = SqrtPriceMathPartial.getAmount0Delta(
                TickMathExternal.getSqrtRatioAtTick(_tickLower),
                TickMathExternal.getSqrtRatioAtTick(_tickUpper),
                _liquidity,
                true
            );
        } else if (_tick < _tickUpper) {
            amount0 = SqrtPriceMathPartial.getAmount0Delta(
                sqrtPriceX96,
                TickMathExternal.getSqrtRatioAtTick(_tickUpper),
                _liquidity,
                true
            );
            amount1 = SqrtPriceMathPartial.getAmount1Delta(
                TickMathExternal.getSqrtRatioAtTick(_tickLower),
                sqrtPriceX96,
                _liquidity,
                true
            );
        } else {
            amount1 = SqrtPriceMathPartial.getAmount1Delta(
                TickMathExternal.getSqrtRatioAtTick(_tickLower),
                TickMathExternal.getSqrtRatioAtTick(_tickUpper),
                _liquidity,
                true
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
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

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMathExternal {
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
    function getSqrtRatioAtTick(int24 tick) public pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), "T");

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
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
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

import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/UnsafeMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Exposes two functions from @uniswap/v3-core SqrtPriceMath
/// that use square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMathPartial {
    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) external pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) external pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

library Uint256Casting {
    /**
     * @notice cast a uint256 to a uint128, revert on overflow
     * @param y the uint256 to be downcasted
     * @return z the downcasted integer, now type uint128
     */
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y, "OF128");
    }

    /**
     * @notice cast a uint256 to a uint96, revert on overflow
     * @param y the uint256 to be downcasted
     * @return z the downcasted integer, now type uint96
     */
    function toUint96(uint256 y) internal pure returns (uint96 z) {
        require((z = uint96(y)) == y, "OF96");
    }

    /**
     * @notice cast a uint256 to a uint32, revert on overflow
     * @param y the uint256 to be downcasted
     * @return z the downcasted integer, now type uint32
     */
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        require((z = uint32(y)) == y, "OF32");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * Requirements:
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
     * Requirements:
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
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

pragma solidity >=0.6.0 <0.8.0;

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
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './PoolAddress.sol';

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        return verifyCallback(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, PoolAddress.PoolKey memory poolKey)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        require(msg.sender == address(pool));
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
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}