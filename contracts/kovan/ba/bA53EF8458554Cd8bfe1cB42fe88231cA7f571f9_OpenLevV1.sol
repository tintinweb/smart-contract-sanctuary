// SPDX-License-Identifier: MIT


pragma solidity 0.7.3;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual onlyAdmin {
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./liquidity/LPoolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ControllerStorage {

    //lpool-pair
    struct LPoolPair {
        address lpool0;
        address lpool1;
    }
    //lpool-distribution
    struct LPoolDistribution {
        uint64 startTime;
        uint64 endTime;
        uint64 duration;
        uint64 lastUpdateTime;
        uint256 totalAmount;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
    }
    //lpool-rewardByAccount
    struct LPoolRewardByAccount {
        uint rewardPerTokenStored;
        uint rewards;
    }

    struct OLETokenDistribution {
        uint128 liquidatorBalance;
        uint128 liquidatorMaxPer;
        uint128 liquidatorOLERatio;
        uint128 supplyBorrowBalance;
    }

    uint64 public constant LPOOL_DISTRIBUTION_MIN_DURATION = 30 days;

    ERC20 public oleToken;

    address public wChainToken;

    address public lpoolImplementation;

    //interest param
    uint256 public baseRatePerBlock;
    uint256 public multiplierPerBlock;
    uint256 public jumpMultiplierPerBlock;
    uint256 public kink;

    address public openLev;

    OLETokenDistribution public oleTokenDistribution;
    //token0=>token1=>pair
    mapping(address => mapping(address => LPoolPair)) public lpoolPairs;
    //marketId=>isDistribution
    mapping(uint => bool) public marketLiqDistribution;
    //pool=>allowed
    mapping(address => bool) public lpoolUnAlloweds;
    //pool=>bool=>distribution(true is borrow,false is supply)
    mapping(LPoolInterface => mapping(bool => LPoolDistribution)) public lpoolDistributions;
    //pool=>bool=>distribution(true is borrow,false is supply)
    mapping(LPoolInterface => mapping(bool => mapping(address => LPoolRewardByAccount))) public lPoolRewardByAccounts;

    event LPoolPairCreated(address token0, address pool0, address token1, address pool1, uint16 marketId, uint32 marginRatio);

    event Distribution2Pool(address pool, uint supplyAmount, uint borrowerAmount, uint64 startTime, uint64 duration);

}
/**
  * @title Controller
  * @author OpenLeverage
  */
interface ControllerInterface {

    /*** Policy Hooks ***/

    function mintAllowed(address lpool, address minter, uint mintAmount) external;

    function transferAllowed(address lpool, address from, address to) external;

    function redeemAllowed(address lpool, address redeemer, uint redeemTokens) external;

    function borrowAllowed(address lpool, address borrower, address payee, uint borrowAmount) external;

    function repayBorrowAllowed(address lpool, address payer, address borrower, uint repayAmount) external;

    function liquidateAllowed(uint marketId, address liqMarker, address liquidator, uint liquidateAmount) external;

    function createLPoolPair(address tokenA, address tokenB, uint32 marginRatio) external;

    /*** Admin Functions ***/

    function setLPoolImplementation(address _lpoolImplementation) external;

    function setOpenLev(address _openlev) external;

    function setInterestParam(uint256 _baseRatePerBlock, uint256 _multiplierPerBlock, uint256 _jumpMultiplierPerBlock, uint256 _kink) external;

    function setLPoolUnAllowed(address lpool, bool unAllowed) external;

    // liquidatorOLERatio: Two decimal in percentage, ex. 300% => 300
    function setOLETokenDistribution(uint128 moreLiquidatorBalance, uint128 liquidatorMaxPer, uint128 liquidatorOLERatio, uint128 moreSupplyBorrowBalance) external;

    function distributeRewards2Pool(address pool, uint supplyAmount, uint borrowAmount, uint64 startTime, uint64 duration) external;

    function distributeRewards2PoolMore(address pool, uint supplyAmount, uint borrowAmount) external;

    function distributeLiqRewards2Market(uint marketId, bool isDistribution) external;

    /***Distribution Functions ***/

    function earned(LPoolInterface lpool, address account, bool isBorrow) external view returns (uint256);

    function getSupplyRewards(LPoolInterface[] calldata lpools, address account) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;


contract DelegateInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./dex/IUniswapV2Factory.sol";
import "./dex/IUniswapV2Pair.sol";
import "./dex/IUniswapV2Callee.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract DexCaller is IUniswapV2Callee {

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    struct UniVars {
        address sellToken;
        uint amount;
    }



    function flashSell(address buyToken, address sellToken, uint sellAmount, uint minBuyAmount) internal returns (uint buyAmount){
        address pair = uniswapFactory.getPair(buyToken, sellToken);
        require(pair != address(0), 'Invalid pair');
        UniVars memory uniVars = UniVars({
        sellToken : sellToken,
        amount : sellAmount
        });
        (uint256 token0Reserves, uint256 token1Reserves,) = IUniswapV2Pair(pair).getReserves();
        bool isToken0 = IUniswapV2Pair(pair).token0() == buyToken ? true : false;
        if (isToken0) {
            buyAmount = getAmountOut(sellAmount, token1Reserves, token0Reserves);
            require(buyAmount >= minBuyAmount, 'buy amount less than min');
            IUniswapV2Pair(pair).swap(buyAmount, 0, address(this), abi.encode(uniVars));
        } else {
            buyAmount = getAmountOut(sellAmount, token0Reserves, token1Reserves);
            require(buyAmount >= minBuyAmount, 'buy amount less than min');
            IUniswapV2Pair(pair).swap(0, buyAmount, address(this), abi.encode(uniVars));
        }
        return buyAmount;
    }

    function flashBuy(address buyToken, address sellToken, uint buyAmount, uint maxSellAmount) internal returns (uint sellAmount){
        address pair = uniswapFactory.getPair(buyToken, sellToken);
        require(pair != address(0), 'Invalid pair');

        (uint256 token0Reserves, uint256 token1Reserves,) = IUniswapV2Pair(pair).getReserves();
        bool isToken0 = IUniswapV2Pair(pair).token0() == buyToken ? true : false;
        if (isToken0) {
            sellAmount = getAmountIn(buyAmount, token1Reserves, token0Reserves);
            require(maxSellAmount >= sellAmount, 'sell amount not enough');
            UniVars memory uniVars = UniVars({
            sellToken : sellToken,
            amount : sellAmount
            });
            IUniswapV2Pair(pair).swap(buyAmount, 0, address(this), abi.encode(uniVars));
        } else {
            sellAmount = getAmountIn(buyAmount, token0Reserves, token1Reserves);
            require(maxSellAmount >= sellAmount, 'sell amount not enough');
            UniVars memory uniVars = UniVars({
            sellToken : sellToken,
            amount : sellAmount
            });
            IUniswapV2Pair(pair).swap(0, buyAmount, address(this), abi.encode(uniVars));
        }
        return sellAmount;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut)
    {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        onSwapCall(sender, amount0, amount1, data);
    }
//
//    function hswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
//        onSwapCall(sender, amount0, amount1, data);
//    }
//
//    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external override {
//        onSwapCall(sender, amount0, amount1, data);
//    }

    function calBuyAmount(address buyToken, address sellToken, uint sellAmount) external override view returns (uint) {
        address pair = uniswapFactory.getPair(buyToken, sellToken);
        require(pair != address(0), 'Invalid pair');
        (uint256 token0Reserves, uint256 token1Reserves,) = IUniswapV2Pair(pair).getReserves();
        bool isToken0 = IUniswapV2Pair(pair).token0() == buyToken ? true : false;
        if (isToken0) {
            return getAmountOut(sellAmount, token1Reserves, token0Reserves);
        } else {
            return getAmountOut(sellAmount, token0Reserves, token1Reserves);
        }
    }

    function onSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) internal {
        // Shh - currently unused
        sender;
        amount0;
        amount1;
        // fetch the address of token0
        address token0 = IUniswapV2Pair(msg.sender).token0();
        // fetch the address of token1
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // ensure that msg.sender is a V2 pair
        assert(msg.sender == uniswapFactory.getPair(token0, token1));
        // rest of the function goes here!
        (UniVars memory uniVars) = abi.decode(data, (UniVars));
        IERC20(uniVars.sellToken).safeTransfer(msg.sender, uniVars.amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Types.sol";
import "./liquidity/LPoolInterface.sol";
import "./ControllerInterface.sol";
import "./dex/IUniswapV2Factory.sol";
import "./dex/PriceOracleInterface.sol";
import "./Referral.sol";


abstract contract OpenLevStorage {
    using SafeMath for uint;
    using SafeERC20 for IERC20;


    // number of markets
    uint16 public numPairs;

    // marketId => Pair
    mapping(uint16 => Types.Market) public markets;

    // owner => marketId => long0(true)/long1(false) => Trades
    mapping(address => mapping(uint16 => mapping(bool => Types.Trade))) public activeTrades;

    /**
     * @dev Total number of Ltokens in circulation
     */
    uint public _totalSupply;

    /**
     * @dev Official record of Ltoken balances for each account
     */
    //    mapping(address => uint) internal balance;

    address public treasury;

    ReferralInterface public referral;

    PriceOracleInterface public priceOracle;

    address public controller;

    event NewFeesRate(uint oldFeesRate, uint newFeesRate);

    event NewDefaultMarginRatio(uint32 oldRatio, uint32 newRatio);

    event NewMarketMarginLimit(uint16 marketId, uint32 oldRatio, uint32 newRatio);

    // 0.3%
    uint public feesRate = 30; // 0.003

    uint8 public insuranceRatio = 33; // 33%

    uint32 public defaultMarginRatio = 3000; // 30%

    event MarginTrade(
        address trader,
        uint16 marketId,
        bool longToken, // 0 => long token 0; 1 => long token 1;
        bool depositToken,
        uint deposited,
        uint borrowed,
        uint held,
        uint fees,
        uint atPrice,
        uint8 priceDecimals
    );

    event TradeClosed(
        address owner,
        uint16 marketId,
        bool longToken,
        uint closeAmount,
        uint atPrice,
        uint8 priceDecimals
    );

    event LiquidationMarker(
        address owner,
        uint16 marketId,
        bool longToken,
        address marker,
        uint atPrice,
        uint8 priceDecimals
    );
    event LiquidationMarkerReset(
        address owner,
        uint16 marketId,
        bool longToken,
        address marker,
        address resetBy,
        uint atPrice,
        uint8 priceDecimals
    );
    event Liquidation(
        address owner,
        uint16 marketId,
        bool longToken,
        uint liquidationAmount,
        address liquidator1,
        address liquidator2,
        uint atPrice,
        uint8 priceDecimals
    );
}

/**
  * @title OpenLevInterface
  * @author OpenLeverage
  */
interface OpenLevInterface {

    function addMarket(
        LPoolInterface pool0,
        LPoolInterface pool1,
        uint32 marginRatio
    ) external returns (uint16);

    function token0(uint16 marketId) external view returns (address);

    function token1(uint16 marketId) external view returns (address);

    function pool0Available(uint16 marketId) external view returns (uint);

    function pool1Available(uint16 marketId) external view returns (uint);

    function marginTrade(
        uint16 marketId,
        bool longToken,
        bool depositToken,
        uint deposit,
        uint borrow,
        uint minBuyAmount,
        address referrer
    ) external;

    function closeTrade(uint16 marketId, bool longToken, uint closeAmount, uint minBuyAmount) external;

    function getActiveTrade(address owner, uint16 marketId, bool longToken) external view returns (Types.Trade memory);

    function marginRatio(address owner, uint16 marketId, bool longToken) external view returns (uint current, uint32 marketLimit);

    function liqMarker(address owner, uint16 marketId, bool longToken) external;

    function liqMarkerReset(address owner, uint16 marketId, bool longToken) external;

    function liquidate(address owner, uint16 marketId, bool longToken) external;


    /*** Admin Functions ***/

    function setDefaultMarginRatio(uint32 newRatio) external;

    function setMarketMarginLimit(uint16 marketId, uint32 newRatio) external;

    function setFeesRate(uint newRate) external;

    function setInsuranceRatio(uint8 newRatio) external;

    function setController(address newController) external;

    function setPriceOracle(PriceOracleInterface newPriceOracle) external;

    function setUniswapFactory(IUniswapV2Factory _uniswapFactory) external;

    function setReferral(ReferralInterface  _referral) external;

    function moveInsurance(uint16 marketId, uint8 poolIndex, address to, uint amount) external;


}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./OpenLevInterface.sol";
import "./Types.sol";
import "./DexCaller.sol";
import "./dex/PriceOracleInterface.sol";
import "./Adminable.sol";
import "./DelegateInterface.sol";
import "./Referral.sol";

/**
  * @title OpenLevV1
  * @author OpenLeverage
  */
contract OpenLevV1 is DelegateInterface, OpenLevInterface, OpenLevStorage, Adminable, DexCaller, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using Address for address;

    constructor ()
    {
    }

    function initialize(
        address _controller,
        address _treasury,
        PriceOracleInterface _priceOracle,
        IUniswapV2Factory _uniswapFactory,
        ReferralInterface _referral
    ) public {
        require(msg.sender == admin, "Not admin");
        treasury = _treasury;
        priceOracle = _priceOracle;
        controller = _controller;
        uniswapFactory = _uniswapFactory;
        referral = _referral;
    }

    function addMarket(
        LPoolInterface pool0,
        LPoolInterface pool1,
        uint32 marginRatio
    ) external override returns (uint16) {
        require(msg.sender == address(controller), "Creating market is only allowed by controller");
        require(marginRatio >= defaultMarginRatio, "Margin ratio is lower then the default limit");
        require(marginRatio < 100000, "Highest margin ratio is 1000%");
        uint16 marketId = numPairs;
        markets[marketId] = Types.Market(pool0, pool1, marginRatio, 0, 0);
        // todo fix the temporary approve
        IERC20(pool0.underlying()).approve(address(pool0), uint256(- 1));
        IERC20(pool1.underlying()).approve(address(pool1), uint256(- 1));
        numPairs ++;
        return marketId;
    }

    function token0(uint16 marketId) external view override returns (address) {
        return markets[marketId].pool0.underlying();
    }

    function token1(uint16 marketId) external view override returns (address) {
        return markets[marketId].pool1.underlying();
    }

    function pool1Available(uint16 marketId) external override view returns (uint) {
        return markets[marketId].pool1.availableForBorrow();
    }

    function pool0Available(uint16 marketId) external override view returns (uint) {
        return markets[marketId].pool0.availableForBorrow();
    }

    function marginTrade(
        uint16 marketId,
        bool longToken,
        bool depositToken,
        uint deposit,
        uint borrow,
        uint minBuyAmount,
        address referrer
    ) external override nonReentrant {

        require(msg.sender != referrer, "Trader referrer same addr");

        Types.MarketVars memory vars = toMarketVar(marketId, longToken, true);

        uint minimalDeposit = depositToken != longToken ? 10 ** (ERC20(vars.sellPool.underlying()).decimals() - 4)
        : 10 ** (ERC20(vars.buyPool.underlying()).decimals() - 4);
        // 0.0001

        require(deposit > minimalDeposit, "Deposit smaller than minimal amount");
        require(vars.sellPool.availableForBorrow() >= borrow, "Insufficient balance to borrow");

        Types.TradeVars memory tv;

        if (depositToken != longToken) {
            tv.depositErc20 = vars.sellToken;
            tv.depositErc20.safeTransferFrom(msg.sender, address(this), deposit);
            tv.fees = feesAndInsurance(deposit.add(borrow), address(tv.depositErc20), marketId, referrer);
            tv.depositAfterFees = deposit.sub(tv.fees);
            tv.tradeSize = tv.depositAfterFees.add(borrow);
            require(borrow == 0 || deposit.mul(10000).div(borrow) > vars.marginRatio, "Margin ratio limit not met");
        } else {
            (uint currentPrice, uint8 decimals) = priceOracle.getPrice(address(vars.sellToken), address(vars.buyToken));
            uint borrowValue = borrow.mul(currentPrice).div(10 ** uint(decimals));
            tv.depositErc20 = vars.buyToken;
            tv.depositErc20.safeTransferFrom(msg.sender, address(this), deposit);
            tv.fees = feesAndInsurance(deposit.add(borrowValue), address(tv.depositErc20), marketId, referrer);
            tv.depositAfterFees = deposit.sub(tv.fees);
            tv.tradeSize = borrow;
            require(borrow == 0 || deposit.mul(10000).div(borrowValue) > vars.marginRatio, "Margin ratio limit not met");
        }

        Types.Trade storage trade = activeTrades[msg.sender][marketId][longToken];
        require(trade.lastBlockNum != block.number, "Trade can't be handled twice in same block");
        trade.lastBlockNum = block.number;
        //        require(trade.liqBlockNum == 0, "Trade must not in liquidating state");
        //reset liquidate status
        if (trade.liqMarker != address(0)) {
            trade.liqMarker = address(0);
            trade.liqBlockNum = 0;
        }
        if (trade.held == 0) {
            require(borrow > 0, "Borrow nothing is not allowed for new trade");
            trade.depositToken = depositToken;
        } else {
            require(depositToken == trade.depositToken, "Deposit token can't change");
        }

        // Borrow
        vars.sellPool.borrowBehalf(msg.sender, borrow);

        // Trade in exchange
        if (tv.tradeSize > 0) {
            tv.newHeld = flashSell(address(vars.buyToken), address(vars.sellToken), tv.tradeSize, minBuyAmount);
        }

        (uint settlePrice, uint8 buyTokenDecimals) = priceOracle.getPrice(address(vars.buyToken), address(vars.sellToken));

        if (depositToken == longToken) {
            tv.newHeld = tv.newHeld.add(tv.depositAfterFees);
        }

        // Record trade
        if (trade.held == 0) {
            trade.deposited = tv.depositAfterFees;
            trade.held = tv.newHeld;
            trade.marketValueOpen = depositToken != longToken ? tv.depositAfterFees.add(borrow) : tv.newHeld.mul(settlePrice).div(10 ** uint(buyTokenDecimals));
            trade.depositFixedValue = depositToken != longToken ? tv.depositAfterFees : tv.depositAfterFees.mul(settlePrice).div(10 ** uint(buyTokenDecimals));
        } else {
            trade.deposited = trade.deposited.add(tv.depositAfterFees);
            trade.held = trade.held.add(tv.newHeld);

            trade.marketValueOpen = depositToken != longToken ? tv.depositAfterFees.add(borrow).add(trade.marketValueOpen)
            : tv.newHeld.mul(settlePrice).div(10 ** buyTokenDecimals).add(trade.marketValueOpen);

            trade.depositFixedValue = depositToken != longToken ? tv.depositAfterFees.add(trade.depositFixedValue)
            : tv.depositAfterFees.mul(settlePrice).div(10 ** buyTokenDecimals).add(trade.depositFixedValue);
        }

        emit MarginTrade(msg.sender, marketId, longToken, depositToken, deposit, borrow, tv.newHeld, tv.fees, settlePrice, buyTokenDecimals);
    }

    function closeTrade(uint16 marketId, bool longToken, uint closeAmount, uint minAmount) external override nonReentrant {
        // close trade on exchange
        (uint current, uint limit) = marginRatioInternal(msg.sender, marketId, longToken, 0);
        require(current > limit, "Margin ratio is lower than limit, liquidation only");

        Types.Trade storage trade = activeTrades[msg.sender][marketId][longToken];
        require(trade.lastBlockNum != block.number, "Trade can't be handled twice in same block");
        trade.lastBlockNum = block.number;
        require(trade.held != 0, "Invalid MarketId or TradeId or LongToken");
        require(closeAmount <= trade.held, "Close amount exceed held amount");

        uint closeRatio = closeAmount.mul(10000).div(trade.held);
        Types.MarketVars memory vars = toMarketVar(marketId, longToken, false);
        uint fees = feesAndInsurance(closeAmount, address(vars.sellToken), marketId, address(0));

        // repay the loan
        uint repayAmount = vars.buyPool.borrowBalanceCurrent(msg.sender);
        if (trade.depositToken != longToken) {
            uint remaining = flashSell(vars.buyPool.underlying(), vars.sellPool.underlying(), closeAmount.sub(fees), minAmount);
            if (closeAmount != trade.held) {//partial close
                repayAmount = repayAmount.mul(closeRatio).div(10000);
                vars.buyPool.repayBorrowBehalf(msg.sender, repayAmount);
                uint repayDeposit = remaining.sub(repayAmount);
                trade.deposited = trade.deposited.sub(repayDeposit);
                vars.buyToken.safeTransfer(msg.sender, repayDeposit);
            } else {// full close
                if (remaining >= repayAmount) {
                    vars.buyPool.repayBorrowBehalf(msg.sender, repayAmount);
                    vars.buyToken.safeTransfer(msg.sender, remaining.sub(repayAmount));
                } else {
                    // add insurance
                    repayAmount = remaining;
                    vars.buyPool.repayBorrowBehalf(msg.sender, repayAmount);
                }
            }
        } else {// trade.depositToken == longToken
            if (closeAmount != trade.held) {//partial close
                repayAmount = repayAmount.mul(closeRatio).div(10000);
                uint sellAmount = flashBuy(vars.buyPool.underlying(), vars.sellPool.underlying(), repayAmount, closeAmount);
                vars.buyPool.repayBorrowBehalf(msg.sender, repayAmount);
                uint repayDeposit = closeAmount.sub(sellAmount).sub(fees);
                trade.deposited = trade.deposited.sub(repayDeposit);
                vars.sellToken.safeTransfer(msg.sender, repayDeposit);
            } else {// full close
                uint sellAmount = flashBuy(vars.buyPool.underlying(), vars.sellPool.underlying(), repayAmount, closeAmount);
                vars.buyPool.repayBorrowBehalf(msg.sender, repayAmount);
                if (closeAmount > sellAmount) {
                    vars.sellToken.safeTransfer(msg.sender, closeAmount.sub(sellAmount).sub(fees));
                }
            }
        }

        if (trade.held.sub(closeAmount) == 0) {
            delete activeTrades[msg.sender][marketId][longToken];
        } else {
            trade.held = trade.held.sub(closeAmount);
            uint remainRatio = 10000 - closeRatio;
            trade.marketValueOpen = trade.marketValueOpen.mul(remainRatio).div(10000);
            trade.depositFixedValue = trade.depositFixedValue.mul(remainRatio).div(10000);
        }

        (uint settlePrice, uint8 priceDecimals) = priceOracle.getPrice(address(vars.buyToken), address(vars.sellToken));

        emit TradeClosed(msg.sender, marketId, longToken, closeAmount, settlePrice, priceDecimals);
    }

    function toMarketVar(uint16 marketId, bool longToken, bool open) internal view returns (Types.MarketVars memory) {
        Types.MarketVars memory vars;
        Types.Market memory market = markets[marketId];

        if (open) {
            vars.buyPool = longToken ? market.pool1 : market.pool0;
            vars.sellPool = longToken ? market.pool0 : market.pool1;
        } else {
            vars.buyPool = longToken ? market.pool0 : market.pool1;
            vars.sellPool = longToken ? market.pool1 : market.pool0;
        }
        vars.buyPoolInsurance = longToken ? market.pool0Insurance : market.pool1Insurance;
        vars.sellPoolInsurance = longToken ? market.pool1Insurance : market.pool0Insurance;

        vars.buyToken = IERC20(vars.buyPool.underlying());
        vars.sellToken = IERC20(vars.sellPool.underlying());
        vars.marginRatio = market.marginRatio;

        return vars;
    }

    function getActiveTrade(address owner, uint16 marketId, bool longToken) external override view returns (Types.Trade memory) {
        return activeTrades[owner][marketId][longToken];
    }

    function marginRatio(address owner, uint16 marketId, bool longToken) external override view returns (uint current, uint32 marketLimit) {
        return marginRatioInternal(owner, marketId, longToken, 0);
    }

    function marginRatioInternal(address owner, uint16 marketId, bool longToken, uint closeAmount)
    internal view returns (uint current, uint32 marketLimit)
    {
        Types.Trade memory trade = activeTrades[owner][marketId][longToken];
        require(trade.held != 0, "Invalid marketId or TradeId");
        require(closeAmount <= trade.held, "Close amount exceed held amount");

        Types.MarketVars memory vars = toMarketVar(marketId, longToken, true);
        uint borrowed = vars.sellPool.borrowBalanceCurrent(owner);
        (uint buyTokenPrice, uint8 buyTokenDecimals) = priceOracle.getPrice(address(vars.buyToken), address(vars.sellToken));
        uint marketValueCurrent = trade.held.sub(closeAmount).mul(buyTokenPrice).div(10 ** uint(buyTokenDecimals));

        if (trade.marketValueOpen > marketValueCurrent) {// losing
            uint pnl = trade.marketValueOpen.sub(marketValueCurrent);
            if (trade.depositFixedValue >= pnl) {
                return (trade.depositFixedValue.sub(pnl).mul(10000).div(borrowed), vars.marginRatio);
            } else {
                return (0, vars.marginRatio);
            }
        } else {// gaining
            uint pnl = marketValueCurrent.sub(trade.marketValueOpen);
            return (trade.depositFixedValue.add(pnl).mul(10000).div(borrowed), vars.marginRatio);
        }
    }

    function liqMarker(address owner, uint16 marketId, bool longToken) external override onlyMarginRatioLessThanLimit(owner, marketId, longToken) {
        Types.Trade storage trade = activeTrades[owner][marketId][longToken];
        require(trade.lastBlockNum != block.number, "Trade can't be handled twice in same block");
        trade.lastBlockNum = block.number;
        require(trade.liqMarker == address(0), "Trade's already been marked liquidating");
        trade.liqMarker = msg.sender;
        trade.liqBlockNum = block.number;

        Types.MarketVars memory vars = toMarketVar(marketId, longToken, false);
        (uint256 price, uint8 priceDecimals) = priceOracle.getPrice(address(vars.buyToken), address(vars.sellToken));

        emit LiquidationMarker(owner, marketId, longToken, msg.sender, price, priceDecimals);
    }

    function liqMarkerReset(address owner, uint16 marketId, bool longToken) external override {
        Types.Trade storage trade = activeTrades[owner][marketId][longToken];
        require(trade.lastBlockNum != block.number, "Trade can't be handled twice in same block");
        trade.lastBlockNum = block.number;
        require(trade.liqMarker != address(0), "Trade's not marked liquidating");

        (uint current, uint limit) = marginRatioInternal(owner, marketId, longToken, 0);
        require(current >= limit, "Current ratio is less than limit");
        address liqMarkerPrior = trade.liqMarker;
        trade.liqMarker = address(0);
        trade.liqBlockNum = 0;

        Types.MarketVars memory vars = toMarketVar(marketId, longToken, false);
        (uint256 price, uint8 priceDecimals) = priceOracle.getPrice(address(vars.buyToken), address(vars.sellToken));

        emit LiquidationMarkerReset(owner, marketId, longToken, liqMarkerPrior, msg.sender, price, priceDecimals);
    }

    function liquidate(address owner, uint16 marketId, bool longToken) external override onlyMarginRatioLessThanLimit(owner, marketId, longToken) nonReentrant {
        Types.LiquidateVars memory liquidateVars;
        Types.Trade memory trade = activeTrades[owner][marketId][longToken];
        require(trade.lastBlockNum != block.number, "Trade can't be handled twice in same block");
        trade.lastBlockNum = block.number;
        Types.MarketVars memory closeVars = toMarketVar(marketId, longToken, false);
        Types.Market storage market = markets[marketId];
        require(trade.liqMarker != address(0), "Trade should've been marked");
        require(trade.liqBlockNum != block.number, "Should not be marked and liq in same block");
        require(trade.held != 0, "Invalid MarketId or TradeId or LongToken");

        (liquidateVars.settlePrice, liquidateVars.priceDecimals) = priceOracle.getPrice(address(closeVars.buyToken), address(closeVars.sellToken));

        liquidateVars.fees = feesAndInsurance(trade.held, address(closeVars.sellToken), marketId, address(0));
        liquidateVars.remaining = flashSell(closeVars.buyPool.underlying(), closeVars.sellPool.underlying(), trade.held.sub(liquidateVars.fees), 0);

        // repay the loan
        if (liquidateVars.remaining > liquidateVars.borrowed) {
            closeVars.buyPool.repayBorrowBehalf(owner, liquidateVars.borrowed);
            closeVars.buyToken.safeTransfer(owner, liquidateVars.remaining.sub(liquidateVars.borrowed));
        } else if (liquidateVars.remaining == liquidateVars.borrowed) {
            closeVars.buyPool.repayBorrowBehalf(owner, liquidateVars.borrowed);
        } else {// remaining < repayment
            uint needed = liquidateVars.borrowed.sub(liquidateVars.remaining);
            if (longToken) {
                if (market.pool0Insurance >= needed) {
                    market.pool0Insurance = market.pool0Insurance.sub(needed);
                } else {
                    market.pool0Insurance = 0;
                    liquidateVars.borrowed = liquidateVars.borrowed.sub(needed.sub(market.pool0Insurance));
                }
            } else {
                if (market.pool1Insurance >= needed) {
                    market.pool1Insurance = market.pool1Insurance.sub(needed);
                } else {
                    market.pool1Insurance = 0;
                    liquidateVars.borrowed = liquidateVars.borrowed.sub(needed.sub(market.pool1Insurance));
                }
            }
            closeVars.buyPool.repayBorrowBehalf(owner, liquidateVars.borrowed);
        }

        //controller
        (OpenLevControllerInterface(controller)).liquidateAllowed(marketId, trade.liqMarker, msg.sender, trade.held);
        emit Liquidation(owner, marketId, longToken, trade.held, trade.liqMarker, msg.sender, liquidateVars.settlePrice, liquidateVars.priceDecimals);
        delete activeTrades[owner][marketId][longToken];
    }

    function feesAndInsurance(uint tradeSize, address token, uint16 marketId, address referrer) internal returns (uint) {
        Types.Market storage market = markets[marketId];
        uint fees = tradeSize.mul(feesRate).div(10000);
        uint newInsurance = fees.mul(insuranceRatio).div(100);
        uint referralReward = 0;
        if (address(referral) != address(0)) {
            referralReward = referral.calReferralReward(msg.sender, referrer, fees, token);
            if (referralReward != 0) {
                IERC20(token).transfer(address(referral), referralReward);
            }
        }
        IERC20(token).transfer(treasury, fees.sub(newInsurance).sub(referralReward));
        if (token == market.pool1.underlying()) {
            market.pool1Insurance = market.pool1Insurance.add(newInsurance);
        } else {
            market.pool0Insurance = market.pool0Insurance.add(newInsurance);
        }
        return fees;
    }

    /*** Admin Functions ***/

    function setDefaultMarginRatio(uint32 newRatio) external override onlyAdmin() {
        uint32 oldRatio = defaultMarginRatio;
        defaultMarginRatio = newRatio;
        emit NewDefaultMarginRatio(oldRatio, newRatio);
    }

    function setMarketMarginLimit(uint16 marketId, uint32 newRatio) external override onlyAdmin() {
        uint32 oldRatio = markets[marketId].marginRatio;
        markets[marketId].marginRatio = newRatio;
        emit NewMarketMarginLimit(marketId, oldRatio, newRatio);
    }

    function setFeesRate(uint newRate) external override onlyAdmin() {
        uint oldFeesRate = feesRate;
        feesRate = newRate;
        emit NewFeesRate(oldFeesRate, feesRate);
    }

    function setInsuranceRatio(uint8 newRatio) external override onlyAdmin() {
        insuranceRatio = newRatio;
    }

    function setController(address newController) external override onlyAdmin() {
        controller = newController;
    }

    function setPriceOracle(PriceOracleInterface newPriceOracle) external override onlyAdmin() {
        priceOracle = newPriceOracle;
    }

    function setUniswapFactory(IUniswapV2Factory _uniswapFactory) external override onlyAdmin() {
        uniswapFactory = _uniswapFactory;
    }

    function setReferral(ReferralInterface _referral) external override onlyAdmin() {
        referral = _referral;
    }

    function moveInsurance(uint16 marketId, uint8 poolIndex, address to, uint amount) external override nonReentrant() onlyAdmin() {
        Types.Market storage market = markets[marketId];
        if (poolIndex == 0) {
            market.pool0Insurance = market.pool0Insurance.sub(amount);
            (IERC20(market.pool0.underlying())).safeTransfer(to, amount);
            return;
        }
        market.pool1Insurance = market.pool1Insurance.sub(amount);
        (IERC20(market.pool1.underlying())).safeTransfer(to, amount);
    }

    modifier onlyMarginRatioLessThanLimit(address owner, uint16 marketId, bool longToken) {
        (uint current, uint limit) = marginRatioInternal(owner, marketId, longToken, 0);
        require(current < limit, "Current ratio is higher than limit");
        _;
    }

}

interface OpenLevControllerInterface {
    function liquidateAllowed(uint marketId, address liqMarker, address liquidator, uint liquidateAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./OpenLevInterface.sol";
import "./ReferralInterface.sol";
import "./Adminable.sol";
import "./DelegateInterface.sol";

contract Referral is DelegateInterface, ReferralInterface, ReferralStorage, Adminable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    constructor() {}

    function initialize(address _openLev) external {
        require(msg.sender == admin, "not admin");
        openLev = _openLev;
    }


    function registerReferrer() override external {
        Account storage account = accounts[msg.sender];
        require(account.isActive == false, "Already registered");
        account.isActive = true;
        emit NewReferrer(msg.sender);
    }

    function calReferralReward(address referee, address referrer, uint baseAmount, address token) external override returns (uint) {
        require(msg.sender == openLev, "Only call from OpenLev allowed");
        require(referee != address(0), "Referee empty");

        Account storage refereeAcct = accounts[referee];
        address registeredReferrer = refereeAcct.referrer;

        // make referee as a active user and referrer after any trade
        if (!refereeAcct.isActive) {
            refereeAcct.isActive = true;
            emit NewReferrer(msg.sender);
        }

        if (registeredReferrer != address(0)) {// already has registered referrer, ignoring the one passed in
            Account storage registeredReferrerAcct = accounts[registeredReferrer];
            return payReward(registeredReferrerAcct, baseAmount, token);
        } else {
            if (referrer == address(0)) {// not found registeredReferrer and not passed-in any referrer
                return 0;
            } else {// new referrer
                require(!isCircularReference(referrer, referee), "Circular referral");
                Account storage referrerAcct = accounts[referrer];

                // only make referral if referrer is active
                if (referrerAcct.isActive == true) {
                    refereeAcct.referrer = referrer;
                    referrerAcct.referredCount = referrerAcct.referredCount.add(1);
                    emit RegisteredReferral(referee, referrer);
                    return payReward(referrerAcct, baseAmount, token);
                } else {// referrer inactive
                    return 0;
                }
            }
        }
    }

    function getReward(address referrer, address token) external view override returns (uint){
        return accounts[referrer].reward[token];
    }

    function withdrawReward(address token) external override {
        uint withdrawAmt = accounts[msg.sender].reward[token];
        accounts[msg.sender].reward[token] = 0;
        IERC20(token).transfer(msg.sender, withdrawAmt);
    }

    function payReward(Account storage referrerAcct, uint baseAmount, address token) internal returns (uint) {
        uint firstLevelReward = calAmount(firstLevelRate, baseAmount);
        referrerAcct.reward[token] = referrerAcct.reward[token] + firstLevelReward;

        if (referrerAcct.referrer != address(0)) {// two level referral
            uint secondLevelReward = calAmount(secondLevelRate, baseAmount);
            Account storage upperReferrerAcct = accounts[referrerAcct.referrer];
            upperReferrerAcct.reward[token] = upperReferrerAcct.reward[token] + secondLevelReward;
            return firstLevelReward + secondLevelReward;
        } else {
            return firstLevelReward;
        }
    }

    function calAmount(uint rate, uint baseAmount) internal pure returns (uint){
        return baseAmount.mul(rate).div(100);
    }

    function isCircularReference(address referrer, address referee) internal view returns (bool){
        address parent = referrer;

        for (uint i; i < 5; i++) {
            if (parent == address(0)) {
                break;
            }
            if (parent == referee) {
                return true;
            }
            parent = accounts[parent].referrer;
        }
        return false;
    }

    /*** Admin Functions ***/

    function setRate(uint _firstLevelRate, uint _secondLevelRate) override external onlyAdmin {
        firstLevelRate = _firstLevelRate;
        secondLevelRate = _secondLevelRate;
    }

    function setOpenLev(address _openLev) override external onlyAdmin {
        openLev = _openLev;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract ReferralStorage {
    using SafeMath for uint;

    struct Account {
        address referrer;
        mapping(address => uint) reward; // Reward by token
        uint referredCount;
        bool isActive;
    }

    address public openLev;
    uint public firstLevelRate = 16;
    uint public secondLevelRate = 8;
    mapping(address => Account) public accounts;


    event NewReferrer(address referrer);

    event RegisteredReferral(address referee, address referrer);
}

interface ReferralInterface {


    function registerReferrer() external;

    function calReferralReward(address referee, address referrer, uint baseAmount, address token) external returns (uint);

    function getReward(address referrer, address token) external view returns (uint);

    function withdrawReward(address token) external;

    /*** Admin Functions ***/

    function setRate(uint _firstLevelRate, uint _secondLevelRate) external;

    function setOpenLev(address _openLev) external;


}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
import "./liquidity/LPoolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


library Types {
    using SafeERC20 for IERC20;

    struct Market {
        LPoolInterface pool0;
        LPoolInterface pool1;
        uint32 marginRatio; // Two decimal in percentage, ex. 15.32% => 1532
        uint pool0Insurance;
        uint pool1Insurance;
    }

    struct MarketVars {
        LPoolInterface buyPool;
        LPoolInterface sellPool;
        IERC20 buyToken;
        IERC20 sellToken;
        uint buyPoolInsurance;
        uint sellPoolInsurance;
        uint32 marginRatio;
    }

    struct TradeVars {
        uint depositValue;
        IERC20 depositErc20;
        uint fees;
        uint depositAfterFees;
        uint tradeSize;
        uint newHeld;
    }

    struct Trade {
        uint deposited;
        uint depositFixedValue;
        uint held;
        uint marketValueOpen;
        address liqMarker;
        uint liqBlockNum;
        bool depositToken;
        uint lastBlockNum;
    }

    struct LiquidateVars {
        uint settlePrice;
        uint8 priceDecimals;
        uint borrowed;
        uint fees;
        uint remaining;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IUniswapV2Factory.sol";

abstract contract IUniswapV2Callee {
    IUniswapV2Factory public uniswapFactory;

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external virtual;

//    function hswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external virtual;
//
//    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external virtual;

    function calBuyAmount(address buyToken, address sellToken, uint sellAmount) external virtual view returns (uint) ;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
//mainnet:0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function token0()  external view returns (address);
    function token1()  external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface PriceOracleInterface {
    //price,decimals
    function getPrice(address desToken, address quoteToken) external view returns (uint256, uint8);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;


abstract contract LPoolStorage {

    //Guard variable for re-entrancy checks
    bool internal _notEntered;

    /**
     * EIP-20 token name for this token
     */
    string public name;

    /**
     * EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
    * Total number of tokens in circulation
    */
    uint public totalSupply;


    //Official record of token balances for each account
    mapping(address => uint) internal accountTokens;

    //Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint)) internal transferAllowances;


    //Maximum borrow rate that can ever be applied (.0005% / block)
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
    * Maximum fraction of borrower cap(80%)
    */
    uint public  borrowCapFactorMantissa = 0.8e18;
    /**
     * Contract which oversees inter-lToken operations
     */
    address public controller;


    // Initial exchange rate used when minting the first lTokens (used when totalSupply = 0)
    uint internal initialExchangeRateMantissa;

    /**
     * Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;


    address public underlying;

    /**
     * Container for borrow balance information
     * principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    uint256 public baseRatePerBlock;
    uint256 public multiplierPerBlock;
    uint256 public jumpMultiplierPerBlock;
    uint256 public kink;

    // Mapping of account addresses to outstanding borrow balances

    mapping(address => BorrowSnapshot) internal accountBorrows;


    /*** Token Events ***/

    /**
    * Event emitted when tokens are minted
    */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** Market Events ***/

    /**
     * Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, address payee, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /*** Admin Events ***/

    /**
     * Event emitted when controller is changed
     */
    event NewController(address oldController, address newController);

    /**
     * Event emitted when interestParam is changed
     */
    event NewInterestParam(uint baseRatePerBlock, uint multiplierPerBlock, uint jumpMultiplierPerBlock, uint kink);


}

abstract contract LPoolInterface is LPoolStorage {


    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);

    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);

    function approve(address spender, uint amount) external virtual returns (bool);

    function allowance(address owner, address spender) external virtual view returns (uint);

    function balanceOf(address owner) external virtual view returns (uint);

    function balanceOfUnderlying(address owner) external virtual returns (uint);

    /*** Lender & Borrower Functions ***/

    function mint(uint mintAmount) external virtual;

    function redeem(uint redeemTokens) external virtual;

    function redeemUnderlying(uint redeemAmount) external virtual;

    function borrowBehalf(address borrower, uint borrowAmount) external virtual;

    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual;

    function availableForBorrow() external view virtual returns (uint);

    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint);

    function borrowRatePerBlock() external virtual view returns (uint);

    function supplyRatePerBlock() external virtual view returns (uint);

    function totalBorrowsCurrent() external virtual view returns (uint);

    function borrowBalanceCurrent(address account) external virtual view returns (uint);

    function borrowBalanceStored(address account) external virtual view returns (uint);

    function exchangeRateCurrent() public virtual returns (uint);

    function exchangeRateStored() public virtual view returns (uint);

    function getCash() external view virtual returns (uint);

    function accrueInterest() public virtual;


    /*** Admin Functions ***/

    function setController(address newController) public virtual;

    function setBorrowCapFactorMantissa(uint newBorrowCapFactorMantissa) public virtual;

    function setInterestParams(uint baseRatePerBlock_, uint multiplierPerBlock_, uint jumpMultiplierPerBlock_, uint kink_) public virtual;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

