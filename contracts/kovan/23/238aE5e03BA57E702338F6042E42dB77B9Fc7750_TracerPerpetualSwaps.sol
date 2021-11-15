// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./lib/SafetyWithdraw.sol";
import "./lib/LibMath.sol";
import {Balances} from "./lib/LibBalances.sol";
import {Types} from "./Interfaces/Types.sol";
import "./lib/LibPrices.sol";
import "./lib/LibPerpetuals.sol";
import "./Interfaces/IOracle.sol";
import "./Interfaces/IInsurance.sol";
import "./Interfaces/ITracerPerpetualSwaps.sol";
import "./Interfaces/IPricing.sol";
import "./Interfaces/ITrader.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

contract TracerPerpetualSwaps is ITracerPerpetualSwaps, Ownable, SafetyWithdraw {
    using LibMath for uint256;
    using LibMath for int256;
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;

    uint256 public constant override LIQUIDATION_GAS_COST = 63516;
    // todo ensure these are fine being immutable
    address public immutable override tracerQuoteToken;
    uint256 public immutable override quoteTokenDecimals;
    bytes32 public immutable override marketId;
    IPricing public pricingContract;
    IInsurance public insuranceContract;
    address public override liquidationContract;
    uint256 public override feeRate;
    uint256 public override fees;
    address public override feeReceiver;

    /* Config variables */
    // The price of gas in gwei
    address public override gasPriceOracle;
    // The maximum ratio of notionalValue to margin
    uint256 public override maxLeverage;
    // WAD value. sensitivity of 1 = 1*10^18
    uint256 public override fundingRateSensitivity;
    // WAD value. The percentage for insurance pool holdings/pool target where deleveraging begins
    uint256 public override deleveragingCliff;
    /* The percentage of insurance holdings to target at which the insurance pool
       funding rate changes, and lowestMaxLeverage is reached */
    uint256 public override insurancePoolSwitchStage;
    // The lowest value that maxLeverage can be, if insurance pool is empty.
    uint256 public override lowestMaxLeverage;

    // Account State Variables
    mapping(address => Balances.Account) public balances;
    uint256 public tvl;
    uint256 public override leveragedNotionalValue;

    // Trading interfaces whitelist
    mapping(address => bool) public override tradingWhitelist;

    event FeeReceiverUpdated(address receiver);
    event FeeWithdrawn(address receiver, uint256 feeAmount);
    event Deposit(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed amount);
    event Settled(address indexed account, int256 margin);
    event MatchedOrders(
        address indexed long,
        address indexed short,
        uint256 amount,
        uint256 price,
        bytes32 longOrderId,
        bytes32 shortOrderId
    );
    event FailedOrders(address indexed long, address indexed short, bytes32 longOrderId, bytes32 shortOrderId);

    /**
     * @notice Creates a new tracer market and sets the initial funding rate of the market. Anyone
     *         will be able to purchase and trade tracers after this deployment.
     * @param _marketId the id of the market, given as BASE/QUOTE
     * @param _tracerQuoteToken the address of the token used for margin accounts (i.e. The margin token)
     * @param _gasPriceOracle the address of the contract implementing gas price oracle
     * @param _maxLeverage the max leverage of the market represented as a WAD value.
     * @param _fundingRateSensitivity the affect funding rate changes have on funding paid.
     * @param _feeRate the fee taken on trades; u60.18-decimal fixed-point number. e.g. 2% fee = 0.02 * 10^18 = 2 * 10^16
     * @param _deleveragingCliff The percentage for insurance pool holdings/pool target where deleveraging begins.
     *                           u60.18-decimal fixed-point number. e.g. 20% = 20*10^18
     * @param _lowestMaxLeverage The lowest value that maxLeverage can be, if insurance pool is empty.
     * @param _insurancePoolSwitchStage The percentage of insurance holdings to target at which the insurance pool
     *                                  funding rate changes, and lowestMaxLeverage is reached
     */
    constructor(
        bytes32 _marketId,
        address _tracerQuoteToken,
        uint256 _tokenDecimals,
        address _gasPriceOracle,
        uint256 _maxLeverage,
        uint256 _fundingRateSensitivity,
        uint256 _feeRate,
        address _feeReceiver,
        uint256 _deleveragingCliff,
        uint256 _lowestMaxLeverage,
        uint256 _insurancePoolSwitchStage
    ) Ownable() {
        // don't convert to interface as we don't need to interact with the contract
        tracerQuoteToken = _tracerQuoteToken;
        quoteTokenDecimals = _tokenDecimals;
        gasPriceOracle = _gasPriceOracle;
        marketId = _marketId;
        feeRate = _feeRate;
        maxLeverage = _maxLeverage;
        fundingRateSensitivity = _fundingRateSensitivity;
        feeReceiver = _feeReceiver;
        deleveragingCliff = _deleveragingCliff;
        lowestMaxLeverage = _lowestMaxLeverage;
        insurancePoolSwitchStage = _insurancePoolSwitchStage;
    }

    /**
     * @notice Adjust the max leverage as insurance pool slides from 100% of target to 0% of target
     */
    function trueMaxLeverage() public view override returns (uint256) {
        IInsurance insurance = IInsurance(insuranceContract);

        return
            Perpetuals.calculateTrueMaxLeverage(
                insurance.collateralAmount(),
                insurance.getPoolTarget(),
                maxLeverage,
                lowestMaxLeverage,
                deleveragingCliff,
                insurancePoolSwitchStage
            );
    }

    /**
     * @notice Allows a user to deposit into their margin account
     * @dev this contract must be an approved spender of the markets quote token on behalf of the depositer.
     * @param amount The amount of quote tokens to be deposited into the Tracer Market account. This amount
     * should be given in WAD format.
     */
    function deposit(uint256 amount) external override {
        Balances.Account storage userBalance = balances[msg.sender];
        // settle outstanding payments
        settle(msg.sender);

        // convert the WAD amount to the correct token amount to transfer
        // cast is safe since amount is a uint, and wadToToken can only
        // scale down the value
        uint256 rawTokenAmount = uint256(Balances.wadToToken(quoteTokenDecimals, amount).toInt256());
        IERC20(tracerQuoteToken).transferFrom(msg.sender, address(this), rawTokenAmount);

        // this prevents dust from being added to the user account
        // eg 10^18 -> 10^8 -> 10^18 will remove lower order bits
        int256 convertedWadAmount = Balances.tokenToWad(quoteTokenDecimals, rawTokenAmount);

        // update user state
        userBalance.position.quote = userBalance.position.quote + convertedWadAmount;
        _updateAccountLeverage(msg.sender);

        // update market TVL
        tvl = tvl + uint256(convertedWadAmount);
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Allows a user to withdraw from their margin account
     * @dev Ensures that the users margin percent is valid after withdraw
     * @param amount The amount of margin tokens to be withdrawn from the tracer market account. This amount
     * should be given in WAD format
     */
    function withdraw(uint256 amount) external override {
        // settle outstanding payments
        settle(msg.sender);

        uint256 rawTokenAmount = Balances.wadToToken(quoteTokenDecimals, amount);
        int256 convertedWadAmount = Balances.tokenToWad(quoteTokenDecimals, rawTokenAmount);

        Balances.Account storage userBalance = balances[msg.sender];
        int256 newQuote = userBalance.position.quote - convertedWadAmount;

        // this may be able to be optimised
        Balances.Position memory newPosition = Balances.Position(newQuote, userBalance.position.base);

        require(marginIsValid(newPosition, userBalance.lastUpdatedGasPrice), "TCR: Withdraw below valid Margin");

        // update user state
        userBalance.position.quote = newQuote;
        _updateAccountLeverage(msg.sender);

        // Safemath will throw if tvl < amount
        tvl = tvl - amount;

        // perform transfer
        IERC20(tracerQuoteToken).transfer(msg.sender, rawTokenAmount);
        emit Withdraw(msg.sender, uint256(convertedWadAmount));
    }

    /**
     * @notice Match two orders that exist on chain against each other
     * @param order1 the first order
     * @param order2 the second order
     */
    function matchOrders(
        Perpetuals.Order memory order1,
        Perpetuals.Order memory order2,
        uint256 fillAmount
    ) public override onlyWhitelisted returns (bool) {
        bytes32 order1Id = Perpetuals.orderId(order1);
        bytes32 order2Id = Perpetuals.orderId(order2);
        uint256 filled1 = ITrader(msg.sender).filled(order1Id);
        uint256 filled2 = ITrader(msg.sender).filled(order2Id);

        uint256 executionPrice = Perpetuals.getExecutionPrice(order1, order2);

        // settle accounts
        // note: this can revert and hence no order events will be emitted
        settle(order1.maker);
        settle(order2.maker);

        (Balances.Position memory newPos1, Balances.Position memory newPos2) = _executeTrade(
            order1,
            order2,
            fillAmount,
            executionPrice
        );
        // validate orders can match, and outcome state is valid
        if (
            !Perpetuals.canMatch(order1, filled1, order2, filled2) ||
            !marginIsValid(newPos1, balances[order1.maker].lastUpdatedGasPrice) ||
            !marginIsValid(newPos2, balances[order2.maker].lastUpdatedGasPrice)
        ) {
            // emit failed to match event and return false
            if (order1.side == Perpetuals.Side.Long) {
                emit FailedOrders(order1.maker, order2.maker, order1Id, order2Id);
            } else {
                emit FailedOrders(order2.maker, order1.maker, order2Id, order1Id);
            }
            return false;
        }

        // update account states
        balances[order1.maker].position = newPos1;
        balances[order2.maker].position = newPos2;

        // update fees
        fees =
            fees +
            // add 2 * fees since getFeeRate returns the fee rate for a single
            // side of the order. Both users were charged fees
            uint256(Balances.getFee(fillAmount, executionPrice, feeRate) * 2);

        // update leverage
        _updateAccountLeverage(order1.maker);
        _updateAccountLeverage(order2.maker);

        // Update internal trade state
        pricingContract.recordTrade(executionPrice, fillAmount);

        if (order1.side == Perpetuals.Side.Long) {
            emit MatchedOrders(order1.maker, order2.maker, fillAmount, executionPrice, order1Id, order2Id);
        } else {
            emit MatchedOrders(order2.maker, order1.maker, fillAmount, executionPrice, order2Id, order1Id);
        }
        return true;
    }

    /**
     * @notice Updates account states of two accounts given two orders that are being executed
     */
    function _executeTrade(
        Perpetuals.Order memory order1,
        Perpetuals.Order memory order2,
        uint256 fillAmount,
        uint256 executionPrice
    ) internal view returns (Balances.Position memory, Balances.Position memory) {
        // Retrieve account state
        Balances.Account memory account1 = balances[order1.maker];
        Balances.Account memory account2 = balances[order2.maker];

        // Construct `Trade` types suitable for use with LibBalances
        (Balances.Trade memory trade1, Balances.Trade memory trade2) = (
            Balances.Trade(executionPrice, fillAmount, order1.side),
            Balances.Trade(executionPrice, fillAmount, order2.side)
        );

        // Calculate new account state
        (Balances.Position memory newPos1, Balances.Position memory newPos2) = (
            Balances.applyTrade(account1.position, trade1, feeRate),
            Balances.applyTrade(account2.position, trade2, feeRate)
        );

        // return new account state
        return (newPos1, newPos2);
    }

    /**
     * @notice internal function for updating leverage. Called within the Account contract. Also
     *         updates the total leveraged notional value for the tracer market itself.
     */
    function _updateAccountLeverage(address account) internal {
        Balances.Account memory userBalance = balances[account];
        uint256 originalLeverage = userBalance.totalLeveragedValue;
        uint256 newLeverage = Balances.leveragedNotionalValue(userBalance.position, pricingContract.fairPrice());
        balances[account].totalLeveragedValue = newLeverage;

        // Update market leveraged notional value
        _updateTracerLeverage(newLeverage, originalLeverage);
    }

    /**
     * @notice Updates the global leverage value given an accounts new leveraged value and old leveraged value
     * @param accountNewLeveragedNotional The future notional value of the account
     * @param accountOldLeveragedNotional The stored notional value of the account
     */
    function _updateTracerLeverage(uint256 accountNewLeveragedNotional, uint256 accountOldLeveragedNotional) internal {
        leveragedNotionalValue = Prices.globalLeverage(
            leveragedNotionalValue,
            accountOldLeveragedNotional,
            accountNewLeveragedNotional
        );
    }

    /**
     * @notice When a liquidation occurs, Liquidation.sol needs to push this contract to update
     *         account states as necessary.
     * @param liquidator Address of the account that called liquidate(...)
     * @param liquidatee Address of the under-margined account getting liquidated
     * @param liquidatorQuoteChange Amount the liquidator's quote is changing
     * @param liquidatorBaseChange Amount the liquidator's base is changing
     * @param liquidateeQuoteChange Amount the liquidated account's quote is changing
     * @param liquidateeBaseChange Amount the liquidated account's base is changing
     * @param amountToEscrow The amount the liquidator has to put into escrow
     */
    function updateAccountsOnLiquidation(
        address liquidator,
        address liquidatee,
        int256 liquidatorQuoteChange,
        int256 liquidatorBaseChange,
        int256 liquidateeQuoteChange,
        int256 liquidateeBaseChange,
        uint256 amountToEscrow
    ) external override onlyLiquidation {
        // Limits the gas use when liquidating
        uint256 gasPrice = IOracle(gasPriceOracle).latestAnswer();
        // Update liquidators last updated gas price
        Balances.Account storage liquidatorBalance = balances[liquidator];
        Balances.Account storage liquidateeBalance = balances[liquidatee];

        // update liquidators balance
        liquidatorBalance.lastUpdatedGasPrice = gasPrice;
        liquidatorBalance.position.quote =
            liquidatorBalance.position.quote +
            liquidatorQuoteChange -
            amountToEscrow.toInt256();
        liquidatorBalance.position.base = liquidatorBalance.position.base + liquidatorBaseChange;

        // update liquidatee balance
        liquidateeBalance.position.quote = liquidateeBalance.position.quote + liquidateeQuoteChange;
        liquidateeBalance.position.base = liquidateeBalance.position.base + liquidateeBaseChange;

        // Checks if the liquidator is in a valid position to process the liquidation
        require(userMarginIsValid(liquidator), "TCR: Liquidator under minimum margin");
    }

    /**
     * @notice When a liquidation receipt is claimed by the liquidator (i.e. they experienced slippage),
               Liquidation.sol needs to tell the market to update its balance and the balance of the
               liquidated agent.
     * @dev Gives the leftover amount from the receipt to the liquidated agent
     * @param claimant The liquidator, who has experienced slippage selling the liquidated position
     * @param amountToGiveToClaimant The amount the liquidator is owe based off slippage
     * @param liquidatee The account that originally got liquidated
     * @param amountToGiveToLiquidatee Amount owed to the liquidated account
     * @param amountToTakeFromInsurance Amount that needs to be taken from the insurance pool
                                        in order to cover liquidation
     */
    function updateAccountsOnClaim(
        address claimant,
        int256 amountToGiveToClaimant,
        address liquidatee,
        int256 amountToGiveToLiquidatee,
        int256 amountToTakeFromInsurance
    ) external override onlyLiquidation {
        address insuranceAddr = address(insuranceContract);
        balances[insuranceAddr].position.quote = balances[insuranceAddr].position.quote - amountToTakeFromInsurance;
        balances[claimant].position.quote = balances[claimant].position.quote + amountToGiveToClaimant;
        balances[liquidatee].position.quote = balances[liquidatee].position.quote + amountToGiveToLiquidatee;
        require(balances[insuranceAddr].position.quote >= 0, "TCR: Insurance not adequately funded");
    }

    /**
     * @notice settles an account. Compares current global rate with the users last updated rate
     *         Updates the accounts margin balance accordingly.
     * @dev Ensures the account remains in a valid margin position. Will throw if account is under margin
     *      and the account must then be liquidated.
     * @param account the address to settle.
     * @dev This function aggregates data to feed into account.sols settle function which sets
     */
    function settle(address account) public override {
        // Get account and global last updated indexes
        uint256 accountLastUpdatedIndex = balances[account].lastUpdatedIndex;
        uint256 currentGlobalFundingIndex = pricingContract.currentFundingIndex();
        Balances.Account storage accountBalance = balances[account];

        // if this user has no positions, bring them in sync
        if (accountBalance.position.base == 0) {
            // set to the last fully established index
            accountBalance.lastUpdatedIndex = currentGlobalFundingIndex;
            accountBalance.lastUpdatedGasPrice = IOracle(gasPriceOracle).latestAnswer();
        } else if (accountLastUpdatedIndex + 1 < currentGlobalFundingIndex) {
            // Only settle account if its last updated index was before the last established
            // global index this is since we reference the last global index
            // Get current and global funding statuses
            uint256 lastEstablishedIndex = currentGlobalFundingIndex - 1;
            // Note: global rates reference the last fully established rate (hence the -1), and not
            // the current global rate. User rates reference the last saved user rate
            Prices.FundingRateInstant memory currGlobalRate = pricingContract.getFundingRate(lastEstablishedIndex);
            Prices.FundingRateInstant memory currUserRate = pricingContract.getFundingRate(accountLastUpdatedIndex);

            Prices.FundingRateInstant memory currInsuranceGlobalRate = pricingContract.getInsuranceFundingRate(
                lastEstablishedIndex
            );

            Prices.FundingRateInstant memory currInsuranceUserRate = pricingContract.getInsuranceFundingRate(
                accountLastUpdatedIndex
            );

            // settle the account
            Balances.Account storage insuranceBalance = balances[address(insuranceContract)];

            accountBalance.position = Prices.applyFunding(accountBalance.position, currGlobalRate, currUserRate);

            // Update account gas price
            accountBalance.lastUpdatedGasPrice = IOracle(gasPriceOracle).latestAnswer();

            if (accountBalance.totalLeveragedValue > 0) {
                (Balances.Position memory newUserPos, Balances.Position memory newInsurancePos) = Prices.applyInsurance(
                    accountBalance.position,
                    insuranceBalance.position,
                    currInsuranceGlobalRate,
                    currInsuranceUserRate,
                    accountBalance.totalLeveragedValue
                );

                balances[account].position = newUserPos;
                balances[(address(insuranceContract))].position = newInsurancePos;
            }

            // Update account index
            accountBalance.lastUpdatedIndex = lastEstablishedIndex;
            require(userMarginIsValid(account), "TCR: Target under-margined");
            emit Settled(account, accountBalance.position.quote);
        }
    }

    // todo this function should be in a lib
    /**
     * @notice Checks the validity of a potential margin given the necessary parameters
     * @param position The position
     * @param gasPrice The gas price
     * @return a bool representing the validity of a margin
     */
    function marginIsValid(Balances.Position memory position, uint256 gasPrice) public view returns (bool) {
        // Get gasCost; denominated in the quote token
        uint256 gasCost = gasPrice * LIQUIDATION_GAS_COST;

        // Get fair price (= oracle price - timeValue)
        uint256 price = pricingContract.fairPrice();

        uint256 minMargin = Balances.minimumMargin(position, price, gasCost, trueMaxLeverage());
        int256 margin = Balances.margin(position, price);

        if (margin < 0) {
            /* Margin being less than 0 is always invalid, even if position is 0.
               This could happen if user attempts to over-withdraw */
            return false;
        }

        return (uint256(margin) >= minMargin);
    }

    /**
     * @notice Checks if a given accounts margin is valid
     * @param account The address of the account whose margin is to be checked
     * @return true if the margin is valid or false otherwise
     */
    function userMarginIsValid(address account) public view returns (bool) {
        Balances.Account memory accountBalance = balances[account];
        return marginIsValid(accountBalance.position, accountBalance.lastUpdatedGasPrice);
    }

    function withdrawFees() public override {
        uint256 tempFees = fees;
        fees = 0;
        tvl = tvl - tempFees;

        // Withdraw from the account
        IERC20(tracerQuoteToken).transfer(feeReceiver, tempFees);
        emit FeeWithdrawn(feeReceiver, tempFees);
    }

    function getBalance(address account) public view override returns (Balances.Account memory) {
        return balances[account];
    }

    function setLiquidationContract(address _liquidationContract) public override onlyOwner {
        liquidationContract = _liquidationContract;
    }

    function setInsuranceContract(address insurance) public override onlyOwner {
        insuranceContract = IInsurance(insurance);
    }

    function setPricingContract(address pricing) public override onlyOwner {
        pricingContract = IPricing(pricing);
    }

    function setGasOracle(address _gasOracle) public override onlyOwner {
        gasPriceOracle = _gasOracle;
    }

    function setFeeReceiver(address _feeReceiver) public override onlyOwner {
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }

    function setFeeRate(uint256 _feeRate) public override onlyOwner {
        feeRate = _feeRate;
    }

    function setMaxLeverage(uint256 _maxLeverage) public override onlyOwner {
        maxLeverage = _maxLeverage;
    }

    function setFundingRateSensitivity(uint256 _fundingRateSensitivity) public override onlyOwner {
        fundingRateSensitivity = _fundingRateSensitivity;
    }

    function setDeleveragingCliff(uint256 _deleveragingCliff) public override onlyOwner {
        deleveragingCliff = _deleveragingCliff;
    }

    function setLowestMaxLeverage(uint256 _lowestMaxLeverage) public override onlyOwner {
        lowestMaxLeverage = _lowestMaxLeverage;
    }

    function setInsurancePoolSwitchStage(uint256 _insurancePoolSwitchStage) public override onlyOwner {
        insurancePoolSwitchStage = _insurancePoolSwitchStage;
    }

    function transferOwnership(address newOwner) public override(Ownable, ITracerPerpetualSwaps) onlyOwner {
        super.transferOwnership(newOwner);
    }

    /**
     * @notice allows the owner of a market to set the whitelisting of a trading interface address
     * @dev a permissioned interface may call the matchOrders function.
     * @param tradingContract the contract to have its whitelisting permissions set
     * @param whitelisted the permission of the contract. If true this contract make call makeOrder
     */
    function setWhitelist(address tradingContract, bool whitelisted) external onlyOwner {
        tradingWhitelist[tradingContract] = whitelisted;
    }

    modifier onlyLiquidation() {
        require(msg.sender == liquidationContract, "TCR: Sender not liquidation");
        _;
    }

    modifier onlyWhitelisted() {
        require(tradingWhitelist[msg.sender], "TCR: Contract not whitelisted");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "../Interfaces/ISafetyWithdraw.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SafetyWithdraw is Ownable, ISafetyWithdraw {
    function withdrawERC20Token(
        address tokenAddress,
        address to,
        uint256 amount
    ) external override onlyOwner {
        IERC20(tokenAddress).transfer(to, amount);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library LibMath {
    uint256 private constant POSITIVE_INT256_MAX = 2**255 - 1;

    function toInt256(uint256 x) internal pure returns (int256) {
        require(x <= POSITIVE_INT256_MAX, "uint256 overflow");
        return int256(x);
    }

    function abs(int256 x) internal pure returns (int256) {
        return x > 0 ? int256(x) : int256(-1 * x);
    }

    function sum(uint256[] memory arr) internal pure returns (uint256) {
        uint256 n = arr.length;
        uint256 total = 0;

        for (uint256 i = 0; i < n; i++) {
            total += arr[i];
        }

        return total;
    }

    /**
     * @notice Get sum of array, for the first `n` elements
     * @param arr Array to get the sum of
     * @param n The number of (first) elements you want to sum up
     * @return Sum of first n elements
     */
    function sumN(uint256[] memory arr, uint256 n) internal pure returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < n; i++) {
            total += arr[i];
        }

        return total;
    }

    function mean(uint256[] memory arr) internal pure returns (uint256) {
        uint256 n = arr.length;

        return sum(arr) / n;
    }

    /** @notice Get mean of array
     * @dev Used for zero-initialised arrays where you only want to calculate
     *      the mean of the first n (populated) elements; rest are 0
     * @param arr Array to get the mean of
     * @param len Divisor/number of elements to get the mean of
     * @return Average of first n elements
     */
    function meanN(uint256[] memory arr, uint256 len) internal pure returns (uint256) {
        return sumN(arr, len) / len;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function signedMin(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./LibMath.sol";
import "../Interfaces/Types.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "./LibPerpetuals.sol";

library Balances {
    using LibMath for int256;
    using LibMath for uint256;
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;

    uint256 public constant MAX_DECIMALS = 18;

    // Size of a position
    struct Position {
        int256 quote;
        int256 base;
    }

    // Information about a trade
    struct Trade {
        uint256 price;
        uint256 amount;
        Perpetuals.Side side;
    }

    // Contains information about the balance of an account in a Tracer market
    struct Account {
        Position position;
        uint256 totalLeveragedValue;
        uint256 lastUpdatedIndex;
        uint256 lastUpdatedGasPrice;
    }

    /**
     * @notice Calculates the notional value of a position as base * price
     * @param position the position the account is currently in
     * @param price The (fair) price of the base asset
     * @return Notional value of a position given the price
     */
    function notionalValue(Position memory position, uint256 price) internal pure returns (uint256) {
        /* cast is safe due to semantics of `abs` */
        return PRBMathUD60x18.mul(uint256(PRBMathSD59x18.abs(position.base)), price);
    }

    /**
     * @notice Calculates the margin as quote + base * base_price
     * @param position The position the account is currently in
     * @param price The price of the base asset
     * @return Margin of the position
     */
    function margin(Position memory position, uint256 price) internal pure returns (int256) {
        /*
         * A cast *must* occur somewhere here in order for this to type check.
         *
         * After you've convinced yourself of this, the next intellectual jump
         * that needs to be made is *what* to cast. We can't cast `quote` as it's
         * allowed to be negative. We can't cast `base` as it's allowed to be
         * negative. Thus, by elimination, the only thing we're left with is
         * `price`.
         *
         * `price` has type `uint256` (i.e., it's unsigned). Thus, our below
         * cast **will** throw iff. `price >= type(int256).max()`.
         */
        int256 signedPrice = LibMath.toInt256(price);
        return position.quote + PRBMathSD59x18.mul(position.base, signedPrice);
    }

    /**
     * @notice Calculates the notional value. i.e. the absolute value of a position
     * @param position The position the account is currently in
     * @param price The price of the base asset
     */
    function leveragedNotionalValue(Position memory position, uint256 price) internal pure returns (uint256) {
        uint256 notionalValue = notionalValue(position, price);
        (position, price);
        int256 marginValue = margin(position, price);

        int256 signedNotionalValue = LibMath.toInt256(notionalValue);

        if (signedNotionalValue - marginValue < 0) {
            return 0;
        } else {
            return uint256(signedNotionalValue - marginValue);
        }
    }

    /**
     * @notice Calculates the minimum margin needed for an account.
     * Calculated as minMargin = notionalValue / maxLev + 6 * liquidationGasCost
     *                         = (base * price) / maxLev + 6 * liquidationGasCost
     * @param position Position to calculate the minimum margin for
     * @param price Price by which to evaluate the minimum margin
     * @param liquidationGasCost Cost for liquidation denominated in quote tokens
     * @param maximumLeverage (True) maximum leverage of a market.
     *   May be less than the set max leverage of the market because
     *   of deleveraging
     * @return Minimum margin of the position given the parameters
     */
    function minimumMargin(
        Position memory position,
        uint256 price,
        uint256 liquidationGasCost,
        uint256 maximumLeverage
    ) internal pure returns (uint256) {
        // There should be no Minimum margin when user has no position
        if (position.base == 0) {
            return 0;
        }

        uint256 notionalValue = notionalValue(position, price);

        // todo confirm that liquidation gas cost should be a WAD value
        uint256 adjustedLiquidationGasCost = liquidationGasCost * 6;

        uint256 minimumMarginWithoutGasCost = PRBMathUD60x18.div(notionalValue, maximumLeverage);

        return adjustedLiquidationGasCost + minimumMarginWithoutGasCost;
    }

    /**
     * @notice Gets the amount that can be matched between two orders
     *         Calculated as min(amountRemaining)
     * @param orderA First order
     * @param fillA Amount of the first order that has been filled
     * @param orderB Second order
     * @param fillB Amount of the second order that has been filled
     * @return Amount matched between two orders
     */
    function fillAmount(
        Perpetuals.Order memory orderA,
        uint256 fillA,
        Perpetuals.Order memory orderB,
        uint256 fillB
    ) internal pure returns (uint256) {
        return LibMath.min(orderA.amount - fillA, orderB.amount - fillB);
    }

    function applyTrade(
        Position memory position,
        Trade memory trade,
        uint256 feeRate
    ) internal pure returns (Position memory) {
        int256 signedAmount = LibMath.toInt256(trade.amount);
        int256 signedPrice = LibMath.toInt256(trade.price);
        int256 quoteChange = PRBMathSD59x18.mul(signedAmount, signedPrice);
        int256 fee = getFee(trade.amount, trade.price, feeRate);

        int256 newQuote = 0;
        int256 newBase = 0;

        if (trade.side == Perpetuals.Side.Long) {
            newBase = position.base + signedAmount;
            newQuote = position.quote - quoteChange + fee;
        } else if (trade.side == Perpetuals.Side.Short) {
            newBase = position.base - signedAmount;
            newQuote = position.quote + quoteChange - fee;
        }

        Position memory newPosition = Position(newQuote, newBase);

        return newPosition;
    }

    function getFee(
        uint256 amount,
        uint256 executionPrice,
        uint256 feeRate
    ) internal pure returns (int256) {
        uint256 quoteChange = PRBMathUD60x18.mul(amount, executionPrice);

        int256 fee = PRBMathUD60x18.mul(quoteChange, feeRate).toInt256();
        return fee;
    }

    function marginValid(
        Position memory position,
        uint256 price,
        uint256 liquidationCost,
        uint256 maximumLeverage
    ) internal pure returns (bool) {
        return uint256(margin(position, price)) >= minimumMargin(position, price, liquidationCost, maximumLeverage);
    }

    /**
     * @notice converts a raw token amount to its WAD representation. Used for tokens
     * that don't have 18 decimal places
     */
    function tokenToWad(uint256 tokenDecimals, uint256 amount) internal pure returns (int256) {
        int256 scaler = int256(10**(MAX_DECIMALS - tokenDecimals));
        return amount.toInt256() * scaler;
    }

    /**
     * @notice converts a wad token amount to its raw representation.
     */
    function wadToToken(uint256 tokenDecimals, uint256 wadAmount) internal pure returns (uint256) {
        uint256 scaler = uint256(10**(MAX_DECIMALS - tokenDecimals));
        return uint256(wadAmount / scaler);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../lib/LibPerpetuals.sol";
import "../lib/LibPrices.sol";

interface Types {
    struct SignedLimitOrder {
        Perpetuals.Order order;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./LibMath.sol";
import "./LibBalances.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";

library Prices {
    using LibMath for uint256;

    struct FundingRateInstant {
        uint256 timestamp;
        int256 fundingRate;
        int256 cumulativeFundingRate;
    }

    struct PriceInstant {
        uint256 cumulativePrice;
        uint256 trades;
    }

    struct TWAP {
        uint256 underlying;
        uint256 derivative;
    }

    function fairPrice(uint256 oraclePrice, int256 _timeValue) public pure returns (uint256) {
        return uint256(LibMath.abs(oraclePrice.toInt256() - _timeValue));
    }

    function timeValue(uint256 averageTracerPrice, uint256 averageOraclePrice) public pure returns (int256) {
        return (averageTracerPrice.toInt256() - averageOraclePrice.toInt256()) / 90;
    }

    /**
     * @notice Calculate the average price of trades in a PriceInstant instance
     * @param price Current cumulative price and number of trades in a time period
     * @return Average price for given instance
     */
    function averagePrice(PriceInstant memory price) public pure returns (uint256) {
        // todo double check safety of this.
        // average price == 0 is not neccesarily the
        // same as no trades in average
        if (price.trades == 0) {
            return 0;
        }
        return price.cumulativePrice / price.trades;
    }

    /**
     * @notice Calculates average price over a time period of 24 hours
     * @dev Ignores hours where the number of trades is zero
     * @param prices Array of PriceInstant instances in the 24 hour period
     * @return Average price in the time period (non-weighted)
     */
    function averagePriceForPeriod(PriceInstant[24] memory prices) public pure returns (uint256) {
        uint256[] memory averagePrices = new uint256[](24);

        // TODO: make sure this procedure is gas-optimised
        uint256 j = 0;
        for (uint256 i = 0; i < 24; i++) {
            PriceInstant memory currPrice = prices[i];

            // don't include periods that have no trades
            if (currPrice.trades == 0) {
                continue;
            } else {
                averagePrices[j] = averagePrice(currPrice);
                j++;
            }
        }

        return LibMath.meanN(averagePrices, j);
    }

    /**
     * @notice Calculate new global leverage
     * @param _globalLeverage Current global leverage
     * @param oldLeverage Old leverage of account
     * @param newLeverage New leverage of account
     * @return New global leverage, calculated from the change from
     *        the old to the new leverage for the account
     */
    function globalLeverage(
        uint256 _globalLeverage,
        uint256 oldLeverage,
        uint256 newLeverage
    ) public pure returns (uint256) {
        int256 newGlobalLeverage = int256(_globalLeverage) + (int256(newLeverage) - int256(oldLeverage));

        // note: this would require a bug in how account leverage was recorded
        // as newLeverage - oldLeverage (leverage delta) would be greater than the
        // markets leverage. This SHOULD NOT be possible, however this is here for sanity.
        if (newGlobalLeverage < 0) {
            return 0;
        }

        return uint256(newGlobalLeverage);
    }

    /**
     * @notice calculates an 8 hour TWAP starting at the hour index amd moving
     * backwards in time.
     * @dev Ignores hours where the number of trades is zero
     * @param hour the 24 hour index to start at
     * @param tracerPrices the average hourly prices of the derivative over the last
     * 24 hours
     * @param oraclePrices the average hourly prices of the oracle over the last
     * 24 hours
     */
    function calculateTWAP(
        uint256 hour,
        PriceInstant[24] memory tracerPrices,
        PriceInstant[24] memory oraclePrices
    ) public pure returns (TWAP memory) {
        require(hour < 24, "Hour index not valid");

        uint256 totalDerivativeTimeWeight = 0;
        uint256 totalUnderlyingTimeWeight = 0;
        uint256 cumulativeDerivative = 0;
        uint256 cumulativeUnderlying = 0;

        for (uint256 i = 0; i < 8; i++) {
            uint256 currTimeWeight = 8 - i;
            // if hour < i loop back towards 0 from 23.
            // otherwise move from hour towards 0
            uint256 j = hour < i ? 24 - i + hour : hour - i;

            uint256 currDerivativePrice = averagePrice(tracerPrices[j]);
            uint256 currUnderlyingPrice = averagePrice(oraclePrices[j]);

            // don't include periods that have no trades
            if (tracerPrices[j].trades == 0) {
                continue;
            } else {
                totalDerivativeTimeWeight += currTimeWeight;
                cumulativeDerivative += currTimeWeight * currDerivativePrice;
            }

            // don't include periods that have no trades
            if (oraclePrices[j].trades == 0) {
                continue;
            } else {
                totalUnderlyingTimeWeight += currTimeWeight;
                cumulativeUnderlying += currTimeWeight * currUnderlyingPrice;
            }
        }

        // If totalUnderlyingTimeWeight or totalDerivativeTimeWeight is 0, there were no trades in
        // the last 8 hours and zero should be returned as the TWAP (also prevents division by zero)
        if (totalUnderlyingTimeWeight == 0 && totalDerivativeTimeWeight == 0) {
            return TWAP(0, 0);
        } else if (totalUnderlyingTimeWeight == 0) {
            return TWAP(0, cumulativeDerivative / totalDerivativeTimeWeight);
        } else if (totalDerivativeTimeWeight == 0) {
            return TWAP(cumulativeUnderlying / totalUnderlyingTimeWeight, 0);
        }

        return TWAP(cumulativeUnderlying / totalUnderlyingTimeWeight, cumulativeDerivative / totalDerivativeTimeWeight);
    }

    // TODO test these
    /**
     * @notice Calculates and returns the effect of the funding rate to a position.
     * @param position Position of the user
     * @param globalRate Global funding rate in current instance
     * @param userRate Last updated user funding rate
     */
    function applyFunding(
        Balances.Position memory position,
        FundingRateInstant memory globalRate,
        FundingRateInstant memory userRate
    ) internal pure returns (Balances.Position memory) {
        // quote after funding rate applied = quote -
        //        (cumulativeGlobalFundingRate - cumulativeUserFundingRate) * base
        return
            Balances.Position(
                position.quote -
                    PRBMathSD59x18.mul(
                        globalRate.cumulativeFundingRate - userRate.cumulativeFundingRate,
                        position.base
                    ),
                position.base
            );
    }

    function applyInsurance(
        Balances.Position memory userPosition,
        Balances.Position memory insurancePosition,
        FundingRateInstant memory globalRate,
        FundingRateInstant memory userRate,
        uint256 totalLeveragedValue
    ) internal pure returns (Balances.Position memory, Balances.Position memory) {
        int256 insuranceDelta = PRBMathSD59x18.mul(
            globalRate.fundingRate - userRate.fundingRate,
            int256(totalLeveragedValue)
        );

        if (insuranceDelta > 0) {
            Balances.Position memory newUserPos = Balances.Position(
                userPosition.quote - insuranceDelta,
                userPosition.base
            );

            Balances.Position memory newInsurancePos = Balances.Position(
                insurancePosition.quote + insuranceDelta,
                insurancePosition.base
            );

            return (newUserPos, newInsurancePos);
        } else {
            return (userPosition, insurancePosition);
        }
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "prb-math/contracts/PRBMathUD60x18.sol";

library Perpetuals {
    enum Side {
        Long,
        Short
    }

    // Information about a given order
    struct Order {
        address maker;
        address market;
        uint256 price;
        uint256 amount;
        Side side;
        uint256 expires;
        uint256 created;
    }

    /**
     * @notice Get the hash of an order from its information, used to unique identify orders
     *      in a market
     * @param order Order that we're getting the hash of
     */
    function orderId(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    /**
     * @return An updated average execution price, based on previous rolling average, and new average
     * @param oldFilledAmount The filled amount that will be getting changed
     * @param oldAverage The average rolling execution price that will be updated
     * @param fillChange The amount of units being added to the filledAmount
     * @param newFillExecutionPrice The execution price of the fillChange units
     */
    function calculateAverageExecutionPrice(
        uint256 oldFilledAmount,
        uint256 oldAverage,
        uint256 fillChange,
        uint256 newFillExecutionPrice
    ) internal pure returns (uint256) {
        uint256 oldFactor = PRBMathUD60x18.mul(oldFilledAmount, oldAverage);
        uint256 newFactor = PRBMathUD60x18.mul(fillChange, newFillExecutionPrice);
        uint256 newTotalAmount = oldFilledAmount + fillChange;
        if (newTotalAmount == 0) {
            return 0;
        }
        uint256 average = PRBMathUD60x18.div(oldFactor + newFactor, newTotalAmount);
        return average;
    }

    /**
     * TODO Test in E2E context
     * @notice Calculate the max leverage based on how full the insurance pool is
     * @param collateralAmount Amount of collateral in insurance pool
     * @param poolTarget Insurance target
     * @param defaultMaxLeverage The max leverage assuming pool is sufficiently full
     * @param lowestMaxLeverage The lowest that max leverage can ever drop to
     * @param deleveragingCliff The point of insurance pool full-ness,
              below which deleveraging begins
     * @param insurancePoolSwitchStage The point of insurance pool full-ness,
              at or below which the insurance pool switches funding rate mechanism
     */
    function calculateTrueMaxLeverage(
        uint256 collateralAmount,
        uint256 poolTarget,
        uint256 defaultMaxLeverage,
        uint256 lowestMaxLeverage,
        uint256 deleveragingCliff,
        uint256 insurancePoolSwitchStage
    ) internal pure returns (uint256) {
        if (poolTarget == 0) {
            return lowestMaxLeverage;
        }
        uint256 percentFull = PRBMathUD60x18.div(collateralAmount, poolTarget);
        percentFull = percentFull * 100; // To bring it up to the same percentage units as everything else

        if (percentFull >= deleveragingCliff) {
            return defaultMaxLeverage;
        }

        if (percentFull <= insurancePoolSwitchStage) {
            return lowestMaxLeverage;
        }

        if (deleveragingCliff == insurancePoolSwitchStage) {
            return lowestMaxLeverage;
        }

        // Linear function intercepting points:
        //       (insurancePoolSwitchStage, lowestMaxLeverage) and (INSURANCE_DELEVERAGING_CLIFF, defaultMaxLeverage)
        // Where the x axis is how full the insurance pool is as a percentage,
        // and the y axis is max leverage.
        // y = mx + b,
        // where m = (y2 - y1) / (x2 - x1)
        //         = (defaultMaxLeverage - lowestMaxLeverage)/
        //           (DELEVERAGING_CLIFF - insurancePoolSwitchStage)
        //       x = percentFull
        //       b = lowestMaxLeverage -
        //           ((defaultMaxLeverage - lowestMaxLeverage) / (deleveragingCliff - insurancePoolSwitchStage))
        // m was reached as that is the formula for calculating the gradient of a linear function
        // (defaultMaxLeverage - LowestMaxLeverage)/cliff * percentFull + lowestMaxLeverage

        uint256 gradientNumerator = defaultMaxLeverage - lowestMaxLeverage;
        uint256 gradientDenominator = deleveragingCliff - insurancePoolSwitchStage;
        uint256 maxLeverageNotBumped = PRBMathUD60x18.mul(
            PRBMathUD60x18.div(gradientNumerator, gradientDenominator), // m
            percentFull // x
        );
        uint256 b = lowestMaxLeverage -
            PRBMathUD60x18.div(defaultMaxLeverage - lowestMaxLeverage, deleveragingCliff - insurancePoolSwitchStage);
        uint256 realMaxLeverage = maxLeverageNotBumped + b; // mx + b

        return realMaxLeverage;
    }

    /**
     * @notice Checks if two orders can be matched given their price, side of trade
     *  (two longs can't can't trade with one another, etc.), expiry times, fill amounts,
     *  markets being the same, makers being different, and time validation.
     * @param a The first order
     * @param aFilled Amount of the first order that has already been filled
     * @param b The second order
     * @param bFilled Amount of the second order that has already been filled
     */
    function canMatch(
        Order memory a,
        uint256 aFilled,
        Order memory b,
        uint256 bFilled
    ) internal view returns (bool) {
        uint256 currentTime = block.timestamp;

        /* predicates */
        bool opposingSides = a.side != b.side;
        // long order must have a price >= short order
        bool pricesMatch = a.side == Side.Long ? a.price >= b.price : a.price <= b.price;
        bool marketsMatch = a.market == b.market;
        bool makersDifferent = a.maker != b.maker;
        bool notExpired = currentTime < a.expires && currentTime < b.expires;
        bool notFilled = aFilled < a.amount && bFilled < b.amount;
        bool createdBefore = currentTime >= a.created && currentTime >= b.created;

        return
            pricesMatch && makersDifferent && marketsMatch && opposingSides && notExpired && notFilled && createdBefore;
    }

    function getExecutionPrice(Order memory a, Order memory b) internal pure returns (uint256) {
        bool aIsFirst = a.created <= b.created;
        if (aIsFirst) {
            return a.price;
        } else {
            return b.price;
        }
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOracle {
    function latestAnswer() external view returns (uint256);

    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IInsurance {
    function collateralAmount() external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function updatePoolAmount() external;

    function drainPool(uint256 amount) external;

    function transferOwnership(address newOwner) external;

    function getPoolUserBalance(address user) external view returns (uint256);

    function getPoolTarget() external view returns (uint256);

    function getPoolFundingRate() external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "../lib/LibPerpetuals.sol";
import "../lib/LibBalances.sol";

interface ITracerPerpetualSwaps {
    function updateAccountsOnLiquidation(
        address liquidator,
        address liquidatee,
        int256 liquidatorQuoteChange,
        int256 liquidatorBaseChange,
        int256 liquidateeQuoteChange,
        int256 liquidateeBaseChange,
        uint256 amountToEscrow
    ) external;

    function updateAccountsOnClaim(
        address claimant,
        int256 amountToGiveToClaimant,
        address liquidatee,
        int256 amountToGiveToLiquidatee,
        int256 amountToTakeFromInsurance
    ) external;

    function settle(address account) external;

    function tracerQuoteToken() external view returns (address);

    function quoteTokenDecimals() external view returns (uint256);

    function liquidationContract() external view returns (address);

    function tradingWhitelist(address trader) external returns (bool);

    function marketId() external view returns (bytes32);

    function leveragedNotionalValue() external view returns (uint256);

    function gasPriceOracle() external view returns (address);

    function feeRate() external view returns (uint256);

    function fees() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function maxLeverage() external view returns (uint256);

    function trueMaxLeverage() external view returns (uint256);

    function LIQUIDATION_GAS_COST() external view returns (uint256);

    function fundingRateSensitivity() external view returns (uint256);

    function deleveragingCliff() external view returns (uint256);

    function lowestMaxLeverage() external view returns (uint256);

    function insurancePoolSwitchStage() external view returns (uint256);

    function getBalance(address account) external view returns (Balances.Account memory);

    function setLiquidationContract(address liquidation) external;

    function setInsuranceContract(address insurance) external;

    function setPricingContract(address pricing) external;

    function setGasOracle(address _gasOracle) external;

    function setFeeRate(uint256 _feeRate) external;

    function setFeeReceiver(address receiver) external;

    function withdrawFees() external;

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setFundingRateSensitivity(uint256 _fundingRateSensitivity) external;

    function setDeleveragingCliff(uint256 _deleveragingCliff) external;

    function setLowestMaxLeverage(uint256 _lowestMaxLeverage) external;

    function setInsurancePoolSwitchStage(uint256 _insurancePoolSwitchStage) external;

    function transferOwnership(address newOwner) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function matchOrders(
        Perpetuals.Order memory order1,
        Perpetuals.Order memory order2,
        uint256 fillAmount
    ) external returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../lib/LibPrices.sol";

interface IPricing {
    function getFundingRate(uint256 index) external view returns (Prices.FundingRateInstant memory);

    function currentHour() external returns (uint8);

    function getInsuranceFundingRate(uint256 index) external view returns (Prices.FundingRateInstant memory);

    function currentFundingIndex() external view returns (uint256);

    function fairPrice() external view returns (uint256);

    function timeValue() external view returns (int256);

    function getTWAPs(uint256 currentHour) external view returns (Prices.TWAP memory);

    function get24HourPrices() external view returns (uint256, uint256);

    function getHourlyAvgTracerPrice(uint256 hour) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function getHourlyAvgOraclePrice(uint256 hour) external view returns (uint256);

    function recordTrade(uint256 tradePrice, uint256 tradeVolume) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "./Types.sol";

interface ITrader {
    function chainId() external view returns (uint256);

    function EIP712_DOMAIN() external view returns (bytes32);

    function executeTrade(Types.SignedLimitOrder[] memory makers, Types.SignedLimitOrder[] memory takers) external;

    function hashOrder(Perpetuals.Order memory order) external view returns (bytes32);

    function filled(bytes32) external view returns (uint256);

    function averageExecutionPrice(bytes32) external view returns (uint256);

    function getDomain() external view returns (bytes32);

    function verifySignature(address signer, Types.SignedLimitOrder memory order) external view returns (bool);

    function getOrder(Perpetuals.Order memory order) external view returns (Perpetuals.Order memory);

    function filledAmount(Perpetuals.Order memory order) external view returns (uint256);

    function getAverageExecutionPrice(Perpetuals.Order memory order) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

import "./PRBMathCommon.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math. It works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 = 57896044618658097711785492504343953926634992332820282019728000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 = -57896044618658097711785492504343953926634992332820282019728000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            require(x > MIN_SD59x18);
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        require(x <= MAX_WHOLE_SD59x18);
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMathCommon.mulDiv".
    /// - None of the inputs can be type(int256).min.
    /// - y cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMathCommon.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        require(x > type(int256).min);
        require(y > type(int256).min);

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 resultUnsigned = PRBMathCommon.mulDiv(ax, uint256(SCALE), ay);
        require(resultUnsigned <= uint256(type(int256).max));

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(resultUnsigned) : int256(resultUnsigned);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 88.722839111672999628.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 128e18.
        require(x < 88722839111672999628);

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 128e18 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2**59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked { result = 1e36 / exp2(-x); }
        } else {
            // 2**128 doesn't fit within the 128.128-bit fixed-point representation.
            require(x < 128e18);

            unchecked {
                // Convert x to the 128.128-bit fixed-point format.
                uint256 x128x128 = (uint256(x) << 128) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 128e18.
                result = int256(PRBMathCommon.exp2(x128x128));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        require(x >= MIN_WHOLE_SD59x18);
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked { result = x % SCALE; }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            require(x >= MIN_SD59x18 / SCALE && x <= MAX_SD59x18 / SCALE);
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            require(xy / x == y);

            // The product cannot be negative.
            require(xy >= 0);

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMathCommon.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked { result = (log2(x) * SCALE) / LOG2_E; }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        require(x > 0);

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked { result = (log2(x) * SCALE) / 332192809488736234; }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        require(x > 0);
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMathCommon.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// alawys 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMathCommon.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMathCommon.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        require(x > MIN_SD59x18);
        require(y > MIN_SD59x18);

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 resultUnsigned = PRBMathCommon.mulDivFixedPoint(ax, ay);
            require(resultUnsigned <= uint256(MAX_SD59x18));

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(resultUnsigned) : int256(resultUnsigned);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMathCommon.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMathCommon.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 absX = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 absResult = y & 1 > 0 ? absX : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            absX = PRBMathCommon.mulDivFixedPoint(absX, absX);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                absResult = PRBMathCommon.mulDivFixedPoint(absResult, absX);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        require(absResult <= uint256(MAX_SD59x18));

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(absResult) : int256(absResult);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// Caveats:
    /// - The maximum fixed-point number permitted is 57896044618658097711785492504343953926634.992332820282019729.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        require(x >= 0);
        require(x < 57896044618658097711785492504343953926634992332820282019729);
        unchecked {
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMathCommon.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked { result = x / SCALE; }
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

import "./PRBMathCommon.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math. It works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an usigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        require(x <= MAX_WHOLE_UD60x18);
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - y cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMathCommon.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 88.722839111672999628.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 128e18.
        require(x < 88722839111672999628);

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 128e18 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2**128 doesn't fit within the 128.128-bit format used internally in this function.
        require(x < 128e18);

        unchecked {
            // Convert x to the 128.128-bit fixed-point format.
            uint256 x128x128 = (x << 128) / SCALE;

            // Pass x to the PRBMathCommon.exp2 function, which uses the 128.128-bit fixed-point number representation.
            result = PRBMathCommon.exp2(x128x128);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            require(x <= MAX_UD60x18 / SCALE);
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            require(xy / x == y);

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMathCommon.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked { result = (log2(x) * SCALE) / LOG2_E; }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        require(x >= SCALE);

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked { result = (log2(x) * SCALE) / 332192809488736234; }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        require(x >= SCALE);
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMathCommon.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMathCommon.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMathCommon.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMathCommon.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMathCommon.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// Caveats:
    /// - The maximum fixed-point number permitted is 115792089237316195423570985008687907853269.984665640564039458.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        require(x < 115792089237316195423570985008687907853269984665640564039458);
        unchecked {
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMathCommon.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked { result = x / SCALE; }
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISafetyWithdraw {
    function withdrawERC20Token(
        address tokenAddress,
        address to,
        uint256 amount
    ) external;
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

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
// representation. When it does not, it is annonated in the function's NatSpec documentation.
library PRBMathCommon {
    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Uses 128.128-bit fixed-point numbers, which is the most efficient way.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 128.128-bit fixed-point number.
    /// @return result The result as an unsigned 60x18 decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 128.128-bit fixed-point format.
            result = 0x80000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^127 and all magic factors are less than 2^129.
            if (x & 0x80000000000000000000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x40000000000000000000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDED) >> 128;
            if (x & 0x20000000000000000000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A7920) >> 128;
            if (x & 0x10000000000000000000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98364) >> 128;
            if (x & 0x8000000000000000000000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FE) >> 128;
            if (x & 0x4000000000000000000000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE9) >> 128;
            if (x & 0x2000000000000000000000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA40) >> 128;
            if (x & 0x1000000000000000000000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9544) >> 128;
            if (x & 0x800000000000000000000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679C) >> 128;
            if (x & 0x400000000000000000000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A011) >> 128;
            if (x & 0x200000000000000000000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5E0) >> 128;
            if (x & 0x100000000000000000000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939726) >> 128;
            if (x & 0x80000000000000000000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3E) >> 128;
            if (x & 0x40000000000000000000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B4) >> 128;
            if (x & 0x20000000000000000000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292027) >> 128;
            if (x & 0x10000000000000000000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FD) >> 128;
            if (x & 0x8000000000000000000000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAC) >> 128;
            if (x & 0x4000000000000000000000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7CA) >> 128;
            if (x & 0x2000000000000000000000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x1000000000000000000000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x800000000000000000000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1629) >> 128;
            if (x & 0x400000000000000000000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2C) >> 128;
            if (x & 0x200000000000000000000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A6) >> 128;
            if (x & 0x100000000000000000000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFF) >> 128;
            if (x & 0x80000000000000000000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2F0) >> 128;
            if (x & 0x40000000000000000000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737B) >> 128;
            if (x & 0x20000000000000000000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F07) >> 128;
            if (x & 0x10000000000000000000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44FA) >> 128;
            if (x & 0x8000000000000000000000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC824) >> 128;
            if (x & 0x4000000000000000000000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE51) >> 128;
            if (x & 0x2000000000000000000000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFD0) >> 128;
            if (x & 0x1000000000000000000000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x800000000000000000000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AE) >> 128;
            if (x & 0x400000000000000000000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CD) >> 128;
            if (x & 0x200000000000000000000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x100000000000000000000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AF) >> 128;
            if (x & 0x80000000000000000000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCF) >> 128;
            if (x & 0x40000000000000000000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0E) >> 128;
            if (x & 0x20000000000000000000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x10000000000000000000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94D) >> 128;
            if (x & 0x8000000000000000000000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33E) >> 128;
            if (x & 0x4000000000000000000000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26946) >> 128;
            if (x & 0x2000000000000000000000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388D) >> 128;
            if (x & 0x1000000000000000000000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D41) >> 128;
            if (x & 0x800000000000000000000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDF) >> 128;
            if (x & 0x400000000000000000000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77F) >> 128;
            if (x & 0x200000000000000000000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C3) >> 128;
            if (x & 0x100000000000000000000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E3) >> 128;
            if (x & 0x80000000000000000000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F2) >> 128;
            if (x & 0x40000000000000000000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA39) >> 128;
            if (x & 0x20000000000000000000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x10000000000000000000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x8000000000000000000 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x4000000000000000000 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x2000000000000000000 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D92) >> 128;
            if (x & 0x1000000000000000000 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x800000000000000000 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE545) >> 128;
            if (x & 0x400000000000000000 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x200000000000000000 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x100000000000000000 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x80000000000000000 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6E) >> 128;
            if (x & 0x40000000000000000 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B3) >> 128;
            if (x & 0x20000000000000000 > 0) result = (result * 0x1000000000000000162E42FEFA39EF359) >> 128;
            if (x & 0x10000000000000000 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AC) >> 128;

            // We do two things at the same time below:
            //
            //     1. Multiply the result by 2^n + 1, where 2^n is the integer part and 1 is an extra bit to account
            //        for the fact that we initially set the result to 0.5 We implement this by subtracting from 127
            //        instead of 128.
            //     2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because result * SCALE * 2^ip / 2^127 = result * SCALE / 2^(127 - ip), where ip is the integer
            // part and SCALE / 2^128 is what converts the result to our unsigned fixed-point format.
            result *= SCALE;
            result >>= (127 - (x >> 128));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2**256 and mod 2**256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
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

        // Make sure the result is less than 2**256. Also prevents denominator == 0.
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2**256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2**256. Now that denominator is an odd number, it has an inverse modulo 2**256 such
            // that denominator * inv = 1 mod 2**256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2**8
            inverse *= 2 - denominator * inverse; // inverse mod 2**16
            inverse *= 2 - denominator * inverse; // inverse mod 2**32
            inverse *= 2 - denominator * inverse; // inverse mod 2**64
            inverse *= 2 - denominator * inverse; // inverse mod 2**128
            inverse *= 2 - denominator * inverse; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2**256. Since the precoditions guarantee that the outcome is
            // less than 2**256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMathCommon.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two queations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        require(SCALE > prod1);

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        require(x > type(int256).min);
        require(y > type(int256).min);
        require(denominator > type(int256).min);

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 resultUnsigned = mulDiv(ax, ay, ad);
        require(resultUnsigned <= uint256(type(int256).max));

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(resultUnsigned) : int256(resultUnsigned);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

