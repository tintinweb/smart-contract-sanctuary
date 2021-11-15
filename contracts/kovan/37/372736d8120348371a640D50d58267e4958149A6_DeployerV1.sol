//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "../lib/LibMath.sol";
import "../Interfaces/Types.sol";
import "../Interfaces/IDex.sol";

/**
 * SimpleDex Contract: Implements the Tracer make/take without underlying
 * management checks.
 */
contract SimpleDex is IDex {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using LibMath for uint256;
    using LibMath for int256;

    // Order counter starts at 1 due to logic in Trader.sol
    uint256 public orderCounter = 1;
    mapping(uint256 => Types.Order) public orders;
    mapping(bytes32 => uint256) public override orderIdByHash;

    /**
     * @notice Places an on chain order via a permissioned contract, fillable by any part on chain.
     * @param amount the amount of Tracers to buy
     * @param price the price in dollars to buy the tracer at
     * @param side the side of the order. True for long, false for short.
     * @param expiration the expiry time for this order
     * @param maker the makers address for this order to be associated with
     */
    function _makeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration,
        address maker
    ) internal returns (uint256) {
        //Create unfilled order
        Types.Order storage order = orders[orderCounter];
        order.maker = maker;
        order.amount = amount;
        order.price = price;
        order.side = side;
        order.expiration = expiration;
        order.creation = block.timestamp;
        //Map order hash to id
        orderIdByHash[hashOrder(amount, price, side, expiration, maker)] = orderCounter; 
        orderCounter++;
        return orderCounter - 1;
    }

    /**
    * @notice Takes an on chain order via a permissioned contract, in whole or in part. Order is executed at the markets
              defined price.
    * @param orderId the ID of the order to be filled. Emitted in the makeOrder function
    * @param amount the amount of the order to fill
    * @param _taker the address of the taker which this order is associated with
    */
    function _takeOrder(
        uint256 orderId,
        uint256 amount,
        address _taker
    )
        internal
        returns (
            Types.Order memory,
            uint256,
            uint256,
            address
        )
    {
        //Fill or partially fill order
        Types.Order storage order = orders[orderId];
        require(order.amount.sub(order.filled) > 0, "SDX: Order filled");
        /* solium-disable-next-line */
        require(block.timestamp < order.expiration, "SDX: Order expired");

        //Calculate the amount to fill
        uint256 fillAmount = (amount > order.amount.sub(order.filled)) ? order.amount.sub(order.filled) : amount;

        //Update order
        order.filled = order.filled.add(fillAmount);
        order.takers[_taker] = order.takers[_taker].add(fillAmount);

        uint256 amountOutstanding = order.amount.sub(order.filled);
        return (order, fillAmount, amountOutstanding, order.maker);
    }

    /**
    * @notice Matches two orders that have already both been made. Has the same
    *         validation as takeOrder 
    */
    function _matchOrder(
        uint256 order1Id,
        uint256 order2Id
    ) internal returns (uint256) {

        // Fill or partially fill order
        Types.Order storage order1 = orders[order1Id];
        Types.Order storage order2 = orders[order2Id];

        // Ensure orders can be cancelled against each other
        require(order1.price == order2.price, "SDX: Price mismatch");

        // Ensure orders are for opposite sides
        require(order1.side != order2.side, "SDX: Same side");
        
        /* solium-disable-next-line */
        require(block.timestamp < order1.expiration &&
            block.timestamp < order2.expiration, "SDX: Order expired");

        // Calculate the amount to fill
        uint256 order1Remaining = order1.amount.sub(order1.filled);
        uint256 order2Remaining = order2.amount.sub(order2.filled);

        // fill amount is the minimum of order 1 and order 2
        uint256 fillAmount = order1Remaining > order2Remaining ? order2Remaining : order1Remaining;

        //Update orders
        order1.filled = order1.filled.add(fillAmount);
        order2.filled = order2.filled.add(fillAmount);
        order1.takers[order2.maker] = order1.takers[order2.maker].add(fillAmount);
        order2.takers[order1.maker] = order2.takers[order1.maker].add(fillAmount);
        return (fillAmount);
    }

    /**
     * @notice hashes a limit order type in order to lookup via hash
     * @return an simple hash of order data
     */
    function hashOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration,
        address user
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(amount, price, side, user, expiration)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "./Tracer.sol";
import "./Interfaces/IDeployer.sol";

/**
 * Deployer contract. Used by the Tracer Factory to deploy new Tracer markets
 */
contract DeployerV1 is IDeployer {

    function deploy(
        bytes calldata _data
    ) external override returns(address) {
        (
            bytes32 _tracerId,
            address _tracerBaseToken,
            address _oracle,
            address _gasPriceOracle,
            address _accountContract,
            address _pricingContract,
            int256 _maxLeverage,
            uint256 _fundingRateSensitivity
        ) = abi.decode(_data, (
            bytes32,
            address,
            address,
            address,
            address,
            address,
            int256,
            uint256
        ));
        Tracer tracer = new Tracer(
            _tracerId,
            _tracerBaseToken,
            _oracle,
            _gasPriceOracle,
            _accountContract,
            _pricingContract,
            _maxLeverage,
            _fundingRateSensitivity
        );
        tracer.transferOwnership(msg.sender);
        return address(tracer);
    }

}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./Types.sol";

interface IAccount {
    function deposit(uint256 amount, address market) external;

    function depositTo(uint256 amount, address market, address user) external;

    function withdraw(uint256 amount, address market) external;

    function settle(
        address account,
        int256 insuranceMultiplyFactor,
        int256 currentGlobalRate,
        int256 currentUserRate,
        int256 currentInsuranceGlobalRate,
        int256 currentInsuranceUserRate,
        int256 gasPrice,
        uint256 priceMultiplier,
        uint256 currentFundingIndex
    ) external;

    function liquidate(
        int256 amount,
        address account,
        address market
    ) external;

    function claimReceipts(
        uint256 escrowId,
        uint256[] memory orderIds,
        address market
    ) external;

    function claimEscrow(uint256 id) external;
    
    function getBalance(address account, address market)
        external
        view
        returns (
            int256,
            int256,
            int256,
            uint256,
            int256,
            uint256
        );

    function updateAccountOnTrade(
        int256 marginChange,
        int256 positionChange,
        address account,
        address market
    ) external;

    function updateAccountLeverage(
        address account,
        address market
    ) external;

    function marginIsValid(
        int256 base,
        int256 quote,
        int256 price,
        int256 gasPrice,
        address market
    ) external view returns (bool);

    function userMarginIsValid(address account, address market) external view returns (bool);

    function getUserMargin(address account, address market) external view returns (int256);

    function getUserNotionalValue(address account, address market) external view returns (int256);

    function getUserMinMargin(address account, address market) external view returns (int256);

    function tracerLeveragedNotionalValue(address market) external view returns(int256);

    function tvl(address market) external view returns(uint256);

    function setReceiptContract(address newReceiptContract) external;

    function setInsuranceContract(address newInsuranceContract) external;

    function setGasPriceOracle(address newGasPriceOracle) external;

    function setFactoryContract(address newFactory) external;

    function setPricingContract(address newPricing) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface IDeployer {

    function deploy(bytes calldata _data) external returns(address);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
import "./Types.sol";

interface IDex {

    function orderIdByHash(bytes32 orderHash) external returns (uint256);

}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface IInsurance {

    function stake(uint256 amount, address market) external;

    function withdraw(uint256 amount, address market) external;

    function reward(uint256 amount, address market) external;

    function updatePoolAmount(address market) external;

    function drainPool(address market, uint256 amount) external;

    function deployInsurancePool(address market) external;

    function getPoolUserBalance(address market, address user) external view returns (uint256);

    function getRewardsPerToken(address market) external view returns (uint256);

    function getPoolToken(address market) external view returns (address);

    function getPoolTarget(address market) external view returns (uint256);

    function getPoolHoldings(address market) external view returns (uint256);

    function getPoolFundingRate(address market) external view returns (uint256);

    function poolNeedsFunding(address market) external view returns (bool);

    function isInsured(address market) external view returns (bool);

    function setFactory(address tracerFactory) external;

    function setAccountContract(address accountContract) external;

    function INSURANCE_MUL_FACTOR() external view returns (int256);
    
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface IOracle {

    function latestAnswer() external view returns (int256);

    function isStale() external view returns (bool);

    function decimals() external view returns (uint8);

    function setDecimals(uint8 _decimals) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface IPricing {
    function setFundingRate(address market, int256 price, int256 fundingRate, int256 fundingRateValue) external;

    function setInsuranceFundingRate(address market, int256 price, int256 fundingRate, int256 fundingRateValue) external;

    function incrementFundingIndex(address market) external;

    function getFundingRate(address market, uint index) external view returns(uint256, int256, int256, int256);

    function getInsuranceFundingRate(address market, uint index) external view returns(uint256, int256, int256, int256);

    function currentFundingIndex(address market) external view returns(uint256);

    function fairPrices(address market) external view returns (int256);

    function timeValues(address market) external view returns(int256);
    
    function updatePrice(
        int256 price,
        int256 oraclePrice,
        bool newRecord,
        address market
    ) external;

    function updateFundingRate(address market, int256 oraclePrice, int256 poolFundingRate) external;

    function updateTimeValue(address market) external;

    function getTWAPs(address marketAddress, uint currentHour)  external view returns (int256, int256);
        
    function get24HourPrices(address market) external view returns (uint256, uint256);

    function getOnlyFundingRate(address marketAddress, uint index) external view returns (int256);

    function getOnlyFundingRateValue(address marketAddress, uint index) external view returns (int256);

    function getOnlyInsuranceFundingRateValue(address marketAddress, uint index) external view returns(int256);

    function getHourlyAvgTracerPrice(uint256 hour, address marketAddress) external view returns (int256);

    function getHourlyAvgOraclePrice(uint256 hour, address marketAddress) external view returns (int256);
    
    // function getHourlyAvgPrice(
    //     uint256 index,
    //     bool isOraclePrice,
    //     address market
    // ) external view returns (int256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

interface ITracer {

    function makeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration
    ) external returns (uint256);

    function permissionedMakeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration,
        address maker
    ) external returns (uint256);

    function takeOrder(uint256 orderId, uint256 amount) external;

    function permissionedTakeOrder(uint256 orderId, uint256 amount, address taker) external;

    function settle(address account) external;

    function tracerBaseToken() external view returns (address);

    function marketId() external view returns(bytes32);

    function leveragedNotionalValue() external view returns(int256);

    function oracle() external view returns(address);

    function gasPriceOracle() external view returns(address);

    function priceMultiplier() external view returns(uint256);

    function feeRate() external view returns(uint256);

    function maxLeverage() external view returns(int256);

    function LIQUIDATION_GAS_COST() external pure returns(uint256);

    function FUNDING_RATE_SENSITIVITY() external pure returns(uint256);

    function currentHour() external view returns(uint8);

    function getOrder(uint orderId) external view returns(uint256, uint256, int256, bool, address, uint256);

    function getOrderTakerAmount(uint256 orderId, address taker) external view returns(uint256);

    function tracerGetBalance(address account) external view returns(
        int256 margin,
        int256 position,
        int256 totalLeveragedValue,
        uint256 deposited,
        int256 lastUpdatedGasPrice,
        uint256 lastUpdatedIndex
    );

    function setUserPermissions(address account, bool permission) external;

    function setInsuranceContract(address insurance) external;

    function setAccountContract(address account) external;

    function setPricingContract(address pricing) external;

    function setOracle(address _oracle) external;

    function setGasOracle(address _gasOracle) external;

    function setFeeRate(uint256 _feeRate) external;

    function setMaxLeverage(int256 _maxLeverage) external;

    function setFundingRateSensitivity(uint256 _fundingRateSensitivity) external;

    function transferOwnership(address newOwner) external;

    function initializePricing() external;

    function matchOrders(uint order1, uint order2) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface Types {

    struct AccountBalance {
        uint256 deposited;
        int256 base; // The amount of units in the base asset
        int256 quote; // The amount of units in the quote asset
        int256 totalLeveragedValue;
        uint256 lastUpdatedIndex;
        int256 lastUpdatedGasPrice;
    }

    struct FundingRate {
        uint256 recordTime;
        int256 recordPrice;
        int256 fundingRate; //positive value = longs pay shorts
        int256 fundingRateValue; //previous rate + (time diff * price * rate)
    }

    struct Order {
        address maker;
        uint256 amount;
        int256 price;
        uint256 filled;
        bool side; //true for long, false for short
        uint256 expiration;
        uint256 creation;
        mapping(address => uint256) takers;
    }

    struct HourlyPrices {
        int256 totalPrice;
        uint256 numTrades;
    }

    struct PricingMetrics {
        Types.HourlyPrices[24] hourlyTracerPrices;
        Types.HourlyPrices[24] hourlyOraclePrices;
    }

    struct LiquidationReceipt {
        address tracer;
        address liquidator;
        address liquidatee;
        int256 price;
        uint256 time;
        uint256 escrowedAmount;
        uint256 releaseTime;
        int256 amountLiquidated;
        bool escrowClaimed;
        bool liquidationSide;
        bool liquidatorRefundClaimed;
    }

    struct LimitOrder {
        uint256 amount;
        int256 price;
        bool side;
        address user;
        uint256 expiration;
        address targetTracer;
        uint256 nonce;
    }

    struct SignedLimitOrder {
        LimitOrder order;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }


}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/LibMath.sol";
import {Balances} from "./lib/LibBalances.sol";
import {Types} from "./Interfaces/Types.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Interfaces/IOracle.sol";
import "./Interfaces/IInsurance.sol";
import "./Interfaces/IAccount.sol";
import "./Interfaces/ITracer.sol";
import "./Interfaces/IPricing.sol";
import "./DEX/SimpleDex.sol";

contract Tracer is ITracer, SimpleDex, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using LibMath for uint256;
    using LibMath for int256;
    using SafeERC20 for IERC20;

    uint256 public override FUNDING_RATE_SENSITIVITY;
    uint256 public constant override LIQUIDATION_GAS_COST = 63516;
    uint256 public immutable override priceMultiplier;
    address public immutable override tracerBaseToken;
    bytes32 public immutable override marketId;
    IAccount public accountContract;
    IPricing public pricingContract;
    IInsurance public insuranceContract;
    uint256 public override feeRate;

    // Config variables
    address public override oracle;
    address public override gasPriceOracle;
    bool private pricingInitialized;
    int256 public override maxLeverage; // The maximum ratio of notionalValue to margin

    // Funding rate variables
    uint256 internal startLastHour;
    uint256 internal startLast24Hours;
    uint8 public override currentHour;

    // Account1 => account2 => whether account2 can trade on behalf of account1
    mapping(address => mapping(address => bool)) public tradePermissions;

    event FeeReceiverUpdated(address receiver);
    event HourlyPriceUpdated(int256 price, uint256 currentHour);
    event FundingRateUpdated(int256 fundingRate, int256 fundingRateValue);
    event InsuranceFundingRateUpdated(int256 insuranceFundingRate, int256 insuranceFundingRateValue);
    event OrderMade(uint256 indexed orderId, uint256 amount, int256 price, address indexed maker, bool isLong, bytes32 indexed marketId);
    event OrderFilled(uint256 indexed orderId, uint256 amount, uint256 amountOutstanding, address indexed taker, address maker, bytes32 indexed marketId);


    /**
     * @notice Creates a new tracer market and sets the initial funding rate of the market. Anyone
     *         will be able to purchase and trade tracers after this deployment.
     * @param _marketId the id of the market, given as BASE/QUOTE
     * @param _tracerBaseToken the address of the token used for margin accounts (i.e. The margin token)
     * @param _oracle the address of the contract implementing the tracer oracle interface
     * @param _gasPriceOracle the address of the contract implementing gas price oracle
     * @param _accountContract the address of the contract implementing the IAccount.sol interface
     * @param _pricingContract the address of the contract implementing the IPricing.sol interface
     */
    constructor(
        bytes32 _marketId,
        address _tracerBaseToken,
        address _oracle,
        address _gasPriceOracle,
        address _accountContract,
        address _pricingContract,
        int256 _maxLeverage,
        uint256 fundingRateSensitivity
    ) public Ownable() {
        accountContract = IAccount(_accountContract);
        pricingContract = IPricing(_pricingContract);
        tracerBaseToken = _tracerBaseToken;
        oracle = _oracle;
        gasPriceOracle = _gasPriceOracle;
        marketId = _marketId;
        IOracle ioracle = IOracle(oracle);
        priceMultiplier = 10**uint256(ioracle.decimals());
        feeRate = 0;
        maxLeverage = _maxLeverage;
        FUNDING_RATE_SENSITIVITY = fundingRateSensitivity;

        // Start average prices from deployment
        startLastHour = block.timestamp;
        startLast24Hours = block.timestamp;
    }

    /**
     * @notice Sets the pricing constants initiallly in the pricing contract
     */
    function initializePricing() public override onlyOwner {
        require(!pricingInitialized, "TCR: Pricing already set");
        // Set first funding rates to 0 and current time
        int256 oracleLatestPrice = IOracle(oracle).latestAnswer();
        pricingContract.setFundingRate(address(this), oracleLatestPrice, 0, 0);
        pricingContract.setInsuranceFundingRate(address(this), oracleLatestPrice, 0, 0);

        pricingContract.incrementFundingIndex(address(this));
        pricingInitialized = true;
    }

    /**
     * @notice Places an on chain order, fillable by any part on chain
     * @dev passes data to permissionedMakeOrder.
     * @param amount the amount of Tracers to buy
     * @param price the price at which someone can purchase (or "fill") 1 tracer of this order
     * @param side the side of the order. True for long, false for short.
     * @param expiration the expiry time for this order
     * @return (orderCounter - 1)
     */
    function makeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration
    ) public override returns (uint256) {
        return permissionedMakeOrder(amount, price, side, expiration, msg.sender);
    }

    /**
     * @notice Places an on chain order via a permissioned contract, fillable by any part on chain.
     * @param amount the amount of Tracers to buy
     * @param price the price in dollars to buy the tracer at
     * @param side the side of the order. True for long, false for short.
     * @param expiration the expiry time for this order
     * @param maker the makers address for this order to be associated with
     */
    function permissionedMakeOrder(
        uint256 amount,
        int256 price,
        bool side,
        uint256 expiration,
        address maker
    ) public override isPermissioned(maker) returns (uint256) {
        {
            // Validate in its own context to help stack
            (int256 base, int256 quote, , , , ) = accountContract.getBalance(maker, address(this));

            // Check base will hold up after trade
            (int256 baseAfterTrade, int256 quoteAfterTrade) = Balances.safeCalcTradeMargin(
                base,
                quote,
                amount,
                price,
                side,
                priceMultiplier,
                feeRate
            );
            uint256 gasCost = uint256(IOracle(gasPriceOracle).latestAnswer()); // We multiply by LIQUIDATION_GAS_COST in Account.marginIsValid
            // Validates margin, will throw if margin is invalid
            require(
                accountContract.marginIsValid(baseAfterTrade, quoteAfterTrade, price, gasCost.toInt256(), address(this)),
                "TCR: Invalid margin"
            );
        }

        // This make order function happens in the DEX (decentralized exchange)
        uint256 orderCounter = _makeOrder(amount, price, side, expiration, maker);
        emit OrderMade(orderCounter, amount, price, maker, side, marketId);
        return orderCounter;
    }

    /**
     * @notice Takes an on chain order, you can specify the amount of the order you wish to will.
     * @param orderId the ID of the order to be filled. Emitted in the makeOrder function
     * @param amount the amount of tokens you wish to fill
     */
    function takeOrder(uint256 orderId, uint256 amount) public override {
        return permissionedTakeOrder(orderId, amount, msg.sender);
    }

    /**
     * @notice Takes an on chain order via a permissioned contract, in whole or in part. Order is executed at the makers
     *         defined price.
     * @param orderId the ID of the order to be filled. Emitted in the makeOrder function
     * @param amount the amount of the order to fill.
     * @param _taker the address of the taker which this order is associated with
     */
    function permissionedTakeOrder(
        uint256 orderId,
        uint256 amount,
        address _taker
    ) public override isPermissioned(_taker) {

        // Calculate the amount to fill
        // _takeOrder is a function in the Decentralized Exchange (DEX) contract
        // fillAmount is how much of the order will be filled (its not necessarily amount);
        (Types.Order memory order, uint256 fillAmount, uint256 amountOutstanding, address maker) = _takeOrder(orderId, amount, _taker);
        emit OrderFilled(orderId, amount, amountOutstanding, _taker, maker, marketId);

        int256 baseChange = (fillAmount.mul(uint256(order.price))).div(priceMultiplier).toInt256();
        require(baseChange > 0, "TCR: Margin change <= 0");

        // update account states
        updateAccounts(baseChange, fillAmount, order.side, order.maker, _taker);
        
        // Update leverage
        accountContract.updateAccountLeverage(_taker, address(this));
        accountContract.updateAccountLeverage(order.maker, address(this));
        
        // Settle accounts
        settle(_taker);
        settle(order.maker);

        // Update internal trade state
        updateInternalRecords(order.price);

        // Ensures that you are in a position to take the trade
        require(
            accountContract.userMarginIsValid(_taker, address(this)) &&
                accountContract.userMarginIsValid(order.maker, address(this)),
            "TCR: Margin Invalid post trade"
        );
    }

    /**
    * @notice Match two orders that exist on chain against each other
    * @param order1 the first order that exists on chain
    * @param order2 the second order that exists on chain
    */
    function matchOrders(uint order1, uint order2) public override {
        // perform compatibility checks (price, side) and calc fill amount
        uint256 fillAmount = _matchOrder(order1, order2);

        int256 orderPrice = orders[order1].price;
        address order1User = orders[order1].maker;
        address order2User = orders[order2].maker;
        bool order1Side = orders[order1].side;
        int256 baseChange = (fillAmount.mul(uint256(orderPrice))).div(priceMultiplier).toInt256();

        //Update account states
        updateAccounts(baseChange, fillAmount, order1Side, order1User, order2User);

        // Update leverage
        accountContract.updateAccountLeverage(order1User, address(this));
        accountContract.updateAccountLeverage(order2User, address(this));

        // Settle accounts
        settle(order1User);
        settle(order2User);

        // Update internal trade state
        updateInternalRecords(orderPrice);

        // Ensures that you are in a position to take the trade
        require(
            accountContract.userMarginIsValid(order1User, address(this)) &&
                accountContract.userMarginIsValid(order2User, address(this)),
            "TCR: Margin Invalid post trade"
        );
    }

    /**
    * @notice Updates account states of two accounts given a change in base, an amount of positions filled and
    *         the side of the first account listed.
    * @dev relies on the account contarct to perform actual state update for a trade.
    */
    function updateAccounts(int256 baseChange, uint256 fillAmount, bool user1Side, address user1, address user2) internal {
        //Update account states
        int256 neg1 = -1;

        if (user1Side) {
            // User 1 long, user 2 short
            // short - base increased, quote decreased
            accountContract.updateAccountOnTrade(
                baseChange,
                neg1.mul(fillAmount.toInt256()),
                user2,
                address(this)
            );
            // long - base decreased, quote increased
            accountContract.updateAccountOnTrade(
                neg1.mul(baseChange),
                fillAmount.toInt256(),
                user1,
                address(this)
            );
        } else {
            // User 2 long, user 1 short
            // long - base decreased, quote increased
            accountContract.updateAccountOnTrade(
                neg1.mul(baseChange),
                fillAmount.toInt256(),
                user2,
                address(this)
            );
            // short - base increased, quote decreased
            accountContract.updateAccountOnTrade(
                baseChange,
                neg1.mul(fillAmount.toInt256()),
                user1,
                address(this)
            );
        }
    }

    /**
     * @notice settles an account. Compares current global rate with the users last updated rate
     *         Updates the accounts margin balance accordingly.
     * @dev Ensures the account remains in a valid margin position. Will throw if account is under margin
     *      and the account must then be liquidated.
     * @param account the address to settle.
     * @dev This function aggregates data to feed into account.sol"s settle function which sets
     */
    function settle(address account) public override {
        // Get account and global last updated indexes
        (, , , , , uint256 accountLastUpdatedIndex) = accountContract.getBalance(account, address(this));
        uint256 currentGlobalFundingIndex = pricingContract.currentFundingIndex(address(this));

        // Only settle account if its last updated index was before the current global index
        if (accountLastUpdatedIndex < currentGlobalFundingIndex) {
            
            /*
             Get current and global funding statuses
             Note: global rates reference the last fully established rate (hence the -1), and not
             the current global rate. User rates reference the last saved user rate
            */
            (, , , int256 currentGlobalRate) = pricingContract.getFundingRate(
                address(this),
                pricingContract.currentFundingIndex(address(this)) - 1
            );
            (, , , int256 currentUserRate) = pricingContract.getFundingRate(address(this), accountLastUpdatedIndex);
            (, , , int256 currentInsuranceGlobalRate) = pricingContract.getInsuranceFundingRate(
                address(this),
                pricingContract.currentFundingIndex(address(this)) - 1
            );
            (, , , int256 currentInsuranceUserRate) = pricingContract.getInsuranceFundingRate(
                address(this),
                accountLastUpdatedIndex
            );

            accountContract.settle(
                account,
                insuranceContract.INSURANCE_MUL_FACTOR(),
                currentGlobalRate,
                currentUserRate,
                currentInsuranceGlobalRate,
                currentInsuranceUserRate,
                IOracle(gasPriceOracle).latestAnswer(),
                priceMultiplier,
                pricingContract.currentFundingIndex(address(this))
            );
        }
    }

    /**
     * @notice Updates the internal records for pricing, funding rate and interest
     * @param price The price to be used to update the internal records, this is the price that a trade occurred at
     *              (i.e. The price and order has been filled at)
     */
    function updateInternalRecords(int256 price) internal {
        IOracle ioracle = IOracle(oracle);
        if (startLastHour <= block.timestamp.sub(1 hours)) {
            // emit the old hourly average
            int256 hourlyTracerPrice =
                    pricingContract.getHourlyAvgTracerPrice(currentHour, address(this));
            emit HourlyPriceUpdated(hourlyTracerPrice, currentHour);

            // Update the price to a new entry and funding rate every hour
            // Check current hour and loop around if need be
            if (currentHour == 23) {
                currentHour = 0;
            } else {
                currentHour = currentHour + 1;
            }
            // Update pricing and funding rate states
            pricingContract.updatePrice(price, ioracle.latestAnswer(), true, address(this));
            int256 poolFundingRate = insuranceContract.getPoolFundingRate(address(this)).toInt256();

            pricingContract.updateFundingRate(address(this), ioracle.latestAnswer(), poolFundingRate); 

            // Gather variables and emit events
            uint256 currentFundingIndex = pricingContract.currentFundingIndex(address(this));
            (,,int256 fundingRate, int256 fundingRateValue) =
                    pricingContract.getFundingRate(address(this), currentFundingIndex);
            (,,int256 insuranceFundingRate, int256 insuranceFundingRateValue) =
                    pricingContract.getInsuranceFundingRate(address(this), currentFundingIndex);
            emit FundingRateUpdated(fundingRate, fundingRateValue);
            emit InsuranceFundingRateUpdated(insuranceFundingRate, insuranceFundingRateValue);

            if (startLast24Hours <= block.timestamp.sub(24 hours)) {
                // Update the interest rate every 24 hours
                pricingContract.updateTimeValue(address(this));
                startLast24Hours = block.timestamp;
            }

            startLastHour = block.timestamp;
        } else {
            // Update old pricing entry
            pricingContract.updatePrice(price, ioracle.latestAnswer(), false, address(this));
        }
    }

    /**
     * @notice gets a order placed on chain
     * @return the order amount, amount filled, price and the side of an order
     * @param orderId The ID number of a placed order
     */
    function getOrder(uint256 orderId)
        external
        override
        view
        returns (
            uint256,
            uint256,
            int256,
            bool,
            address,
            uint256
        )
    {
        Types.Order memory order = orders[orderId];
        return (order.amount, order.filled, order.price, order.side, order.maker, order.creation);
    }

    /**
     * @notice gets the amount taken by a taker against an order
     * @param orderId The ID number of the order
     * @param taker The address of the taker account
     */
    function getOrderTakerAmount(uint256 orderId, address taker) external override view returns (uint256) {
        Types.Order storage order = orders[orderId];
        return (order.takers[taker]);
    }

    /**
     * @notice Gets the different balance variables of an account in this Tracer.
     * @dev Does so by calling the Account contract's getBalance
     * @param account The account whose balances will be returned
     */
    function tracerGetBalance(address account) external view override returns (
        int256 margin,
        int256 position,
        int256 totalLeveragedValue,
        uint256 deposited,
        int256 lastUpdatedGasPrice,
        uint256 lastUpdatedIndex
    ) {
        return accountContract.getBalance(account, address(this));
    }

    /**
     * @notice Gets the total leveraged notional value for this tracer from
              the account contract.
     * @return the total leveraged notional value of this tracer market
     */
    function leveragedNotionalValue() public override view returns(int256) {
        return accountContract.tracerLeveragedNotionalValue(address(this));
    }

    /**
     * @notice Sets the execution permissions for a specific address. This gives this address permission to
     *         open and close orders on behalf of the users account.
     * @dev No limit is enforced on amount spendable by permissioned users.
     * @param account the address of the account to have execution permissions set.
     * @param permission the permissions for this account to be set, true for giving permission, false to remove
     */
    function setUserPermissions(address account, bool permission) public override {
        tradePermissions[msg.sender][account] = permission;
    }

    // --------------------- //
    //  GOVERNANCE FUNCTIONS //
    // --------------------- //

    function setInsuranceContract(address insurance) public override onlyOwner {
        insuranceContract = IInsurance(insurance);
    }

    function setAccountContract(address account) public override onlyOwner {
        accountContract = IAccount(account);
    }

    function setPricingContract(address pricing) public override onlyOwner {
        pricingContract = IPricing(pricing);
    }

    function setOracle(address _oracle) public override onlyOwner {
        oracle = _oracle;
    }

    function setGasOracle(address _gasOracle) public override onlyOwner {
        gasPriceOracle = _gasOracle;
    }

    function setFeeRate(uint256 _feeRate) public override onlyOwner {
        feeRate = _feeRate;
    }

    function setMaxLeverage(int256 _maxLeverage) public override onlyOwner {
        maxLeverage = _maxLeverage;
    }

    function setFundingRateSensitivity(uint256 _fundingRateSensitivity) public override onlyOwner {
        FUNDING_RATE_SENSITIVITY = _fundingRateSensitivity;
    }

    function transferOwnership(address newOwner) public override(Ownable, ITracer) onlyOwner {
        super.transferOwnership(newOwner);
    }

    modifier isPermissioned(address account) {
        require(msg.sender == account || tradePermissions[account][msg.sender], "TCR: No trade permission");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./LibMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "../Interfaces/Types.sol";

library Balances {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using LibMath for uint256;
    using LibMath for int256;

    int256 private constant MARGIN_MUL_FACTOR = 10000; // Factor to keep precision in base calcs
    uint256 private constant FEED_UNIT_DIVIDER = 10e7; // used to normalise gas feed prices for base calcs

    /**
     * @notice Calculates the new base and position given trade details. Assumes the entire trade will execute
               to calculate the new base and position.
     * @param currentBase the users current base account balance
     * @param currentQuote the users current position balance
     * @param amount the amount of positions being purchased in this trade
     * @param price the price the positions are being purchased at
     * @param side the side of the order (true for LONG, false for SHORT)
     * @param priceMultiplier the price multiplier used for the tracer contract the calc is being run for
     * @param feeRate the current fee rate of the tracer contract the calc is being run for
     */
    function safeCalcTradeMargin(
        int256 currentBase,
        int256 currentQuote,
        uint256 amount,
        int256 price,
        bool side,
        uint256 priceMultiplier,
        uint256 feeRate
    ) internal pure returns (int256 _currentBase, int256 _currentQuote) {
        // Get base change and fee if present
        int256 baseChange = (amount.mul(uint(price.abs()))).div(priceMultiplier).toInt256();
        int256 fee = (baseChange.mul(feeRate.toInt256())).div(priceMultiplier.toInt256());
        if (side) {
            // LONG
            currentQuote = currentQuote.add(amount.toInt256());
            currentBase = currentBase.sub(baseChange.add(fee));
        } else {
            // SHORT
            currentQuote = currentQuote.sub(amount.toInt256());
            currentBase = currentBase.add(baseChange.sub(fee));
        }

        return (currentBase, currentQuote);
    }


    /**
     * @notice calculates the net value of both the users base and position given a
     *         price and price multiplier.
     * @param base the base of a user
     * @param position the position of a user
     * @param price the price for which the value is being calculated at
     * @param priceMultiplier the multiplier value used for the price being referenced
    */
    function calcMarginPositionValue(
        int256 base,
        int256 position,
        int256 price,
        uint256 priceMultiplier
    ) internal pure returns (int256 _baseCorrectUnits, int256 _positionValue) {
        int256 baseCorrectUnits = 0;
        int256 positionValue = 0;

        baseCorrectUnits = base.abs().mul(priceMultiplier.toInt256().mul(MARGIN_MUL_FACTOR));
        positionValue = position.abs().mul(price);

        return (baseCorrectUnits, positionValue);
    }

    /**
     * @dev deprecated
     * @notice Calculates an accounts leveraged notional value
     * @param quote the quote assets of a user
     * @param deposited the amount of funds a user has deposited
     * @param price the fair rice for which the value is being calculated at
     * @param priceMultiplier the multiplier value used for the price being referenced
     */
    function calcLeveragedNotionalValue(
        int256 quote,
        int256 price,
        uint256 deposited,
        uint256 priceMultiplier
    ) internal pure returns (int256) {
        // quote * price - deposited
        return (quote.abs().mul(price).div(priceMultiplier.toInt256())).sub(deposited.toInt256());
    }

    /**
     * @notice Calculates the marign as base + quote * quote_price
     * @param quote The amount of quote units
     * @param price The price of the quote asset
     * @param base The base units
     * @param priceMultiplier The multiplier for the price feed
     */
    function calcMargin(
        int256 quote,
        int256 price,
        int256 base,
        uint256 priceMultiplier
    ) internal pure returns (int256) {
        // (10^18 * 10^8 + 10^18 * 10^8) / 10^8
        // (10^26 + 10^26) / 10^8
        // 10^18
        return ((base.mul(priceMultiplier.toInt256())).add(quote.mul(price))).div(priceMultiplier.toInt256());
    }

    /*
     * @notice Calculates what the minimum margin should be given a certain position
     * @param quote The amount of quote units
     * @param price The price of the quote asset
     * @param base The base units
     * @param liquidationGasCost The cost to perform a liquidation
     * @param maxLeverage The maximum ratio of notional value/margin
     */
    function calcMinMargin(
        int256 quote, // 10^18
        int256 price, // 10^8
        int256 base,  // 10^18
        int256 liquidationGasCost, // USD/GAS 10^18
        int256 maxLeverage,
        uint256 priceMultiplier
    ) internal pure returns (int256) {
        int256 leveragedNotionalValue = newCalcLeveragedNotionalValue(quote, price, base, priceMultiplier);
        int256 notionalValue = calcNotionalValue(quote, price);

        if (leveragedNotionalValue <= 0 && quote >= 0) {
            // Over collateralised
            return 0;
        }
        // LGC * 6 + notionalValue/maxLeverage
        int256 lgc = liquidationGasCost.mul(6); // 10^18
        // 10^26 * 10^4 / 10^4 / 10^8 = 10^18
        int256 baseMinimum = notionalValue.mul(MARGIN_MUL_FACTOR).div(maxLeverage).div(priceMultiplier.toInt256());
        return lgc.add(baseMinimum);
    }

    /**
     * @notice Calculates Leveraged Notional Value, a.k.a the borrowed amount
     *         The difference between the absolute value of the position and the margin
     * @param quote The amount of quote units
     * @param price The price of the quote asset
     * @param base The base units
     */
    function newCalcLeveragedNotionalValue(
        int256 quote, // 10^18
        int256 price, // 10^8
        int256 base, // 10^18
        uint256 priceMultiplier // 10^8
    ) internal pure returns (int256) {
        int256 notionalValue = calcNotionalValue(quote, price);
        int256 margin = calcMargin(quote, price, base, priceMultiplier);
        int256 LNV = notionalValue.sub(margin.mul(priceMultiplier.toInt256())).div(priceMultiplier.toInt256());
        if (LNV < 0) {
            LNV = 0;
        }
        return LNV;
    }

    /**
     * @notice Calculates the notional value. i.e. the absolute value of a position
     * @param quote The amount of quote units
     * @param price The price of the quote asset
     */
    function calcNotionalValue(
        int256 quote,
        int256 price
    ) internal pure returns (int256) {
        quote = quote.abs();
        return quote.mul(price); // 10^18 * 10^8 = 10^26
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

library LibMath {
    uint256 private constant POSITIVE_INT256_MAX = 2**255 - 1;

    function toInt256(uint256 x) internal pure returns (int256) {
        require(x <= POSITIVE_INT256_MAX, "uint256 overflow");
        return int256(x);
    }

    function abs(int256 x) internal pure returns (int256) {
        return x > 0 ? int256(x) : int256(-1 * x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

