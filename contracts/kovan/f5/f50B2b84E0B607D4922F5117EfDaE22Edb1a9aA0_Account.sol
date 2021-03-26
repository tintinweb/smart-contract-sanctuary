// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./Interfaces/ITracer.sol";
import "./Interfaces/IOracle.sol";
import "./Interfaces/IAccount.sol";
import "./Interfaces/IReceipt.sol";
import "./Interfaces/ITracerFactory.sol";
import "./Interfaces/IPricing.sol";
import "./Interfaces/IInsurance.sol";
import {Balances} from "./lib/LibBalances.sol";
import {Types} from "./Interfaces/Types.sol";
import "./lib/LibMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Account is IAccount, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using LibMath for uint256;
    using LibMath for int256;
    using SafeERC20 for IERC20;

    
    address public insuranceContract;
    address public gasPriceOracle;
    IReceipt public receipt;
    ITracerFactory public factory;
    IPricing public pricing;
    int256 private constant PERCENT_PRECISION = 10000; // Factor to keep precision in percent calcs
    int256 private constant DIVIDE_PRECISION = 10000000; // 10^7
    uint256 public currentLiquidationId;

    // one account per market per user
    // Tracer market => users address => Account Balance struct
    mapping(address => mapping(address => Types.AccountBalance)) public balances;

    // tracer market => total leverage notional value
    mapping(address => int256) public override tracerLeveragedNotionalValue;

    // tracer market => TVL
    mapping(address => uint256) public override tvl;

    event Deposit(address indexed user, uint256 indexed amount, address indexed market);
    event Withdraw(address indexed user, uint256 indexed amount, address indexed market);
    event AccountSettled(address indexed account, int256 margin);
    event Liquidate(address indexed account, address indexed liquidator, int256 liquidationAmount, bool side, address indexed market, uint liquidationId);
    event ClaimedReceipts(address indexed liquidator, address indexed market, uint256[] ids);
    event ClaimedEscrow(address indexed liquidatee, address indexed market, uint256 id);

    constructor(
        address _insuranceContract,
        address _gasPriceOracle,
        address _factory,
        address _pricing,
        address governance
    ) public {
        insuranceContract = _insuranceContract;
        gasPriceOracle = _gasPriceOracle;
        factory = ITracerFactory(_factory);
        pricing = IPricing(_pricing);
        transferOwnership(governance);
    }

    /**
     * @notice Allows am account to deposit on behalf of a user into a specific market
     * @param amount The amount of base tokens to be deposited into the Tracer Market account
     * @param market The address of the tracer market that the margin tokens will be deposited into
     * @param user the user whos account the deposit is being made into
     */
    function depositTo(uint256 amount, address market, address user) external override {
        _deposit(amount, market, user, msg.sender);
    }

    /**
     * @notice Allows a user to deposit into a margin account of a specific tracer
     * @param amount The amount of base tokens to be deposited into the Tracer Market account
     * @param market The address of the tracer market that the margin tokens will be deposited into 
     */
    function deposit(uint256 amount, address market) external override {
        _deposit(amount, market, msg.sender, msg.sender);
    }

    /**
    * @notice Internal deposit logic for accounts adding to the account contract.
    * @dev this contract must be an approvexd spender of the markets base token on behalf of the depositer.
    * @param amount The amount of base tokens to be deposited into the Tracer Market account  
    * @param market The address of the tracer market that the margin tokens will be deposited into 
    * @param user the user whos account the deposit is being made into
    * @param depositer the address who is depositing the funds
    */
    function _deposit(uint256 amount, address market, address user, address depositer) internal isValidTracer(market) {
        require(amount > 0, "ACT: Deposit Amount <= 0"); 
        Types.AccountBalance storage userBalance = balances[market][user];
        address tracerBaseToken = ITracer(market).tracerBaseToken();
        IERC20(tracerBaseToken).safeTransferFrom(depositer, address(this), amount);
        userBalance.base = userBalance.base.add(amount.toInt256());
        userBalance.deposited = userBalance.deposited.add(amount);
        int256 originalLeverage = userBalance.totalLeveragedValue;
        
        _updateAccountLeverage(userBalance.quote,
            pricing.fairPrices(market),
            userBalance.base,
            user,
            market,
            originalLeverage
        );
        tvl[market] = tvl[market].add(amount);
        emit Deposit(user, amount, market);
    }

    /**
     * @notice Allows a user to withdraw from a margin account of a specific tracer
     * @dev Ensures that the users margin percent is valid after withdraw
     * @param amount The amount of margin tokens to be withdrawn from the tracer market account
     * @param market The address of the tracer market to be withdrawn from 
     */
    function withdraw(uint256 amount, address market) external override {
        ITracer _tracer = ITracer(market);
        require(amount > 0, "ACT: Withdraw Amount <= 0");
        Types.AccountBalance storage userBalance = balances[market][msg.sender];    
        require(
            marginIsValid(
                userBalance.base.sub(amount.toInt256()), 
                userBalance.quote,
                pricing.fairPrices(market),
                userBalance.lastUpdatedGasPrice,
                market
            ),
            "ACT: Withdraw below valid Margin"
        );
        address tracerBaseToken = _tracer.tracerBaseToken();
        IERC20(tracerBaseToken).safeTransfer(msg.sender, amount);
        userBalance.base = userBalance.base.sub(amount.toInt256());
        userBalance.deposited = userBalance.deposited.sub(amount);
        int256 originalLeverage = userBalance.totalLeveragedValue;
        _updateAccountLeverage(userBalance.quote, pricing.fairPrices(market), userBalance.base, msg.sender, market, originalLeverage);
        
        // Safemath will throw if tvl[market] < amount
        tvl[market] = tvl[market].sub(amount);
        emit Withdraw(msg.sender, amount, market);
    }

    /**
     * @notice Settles a specific account on a specific tracer. 
     * @dev Ensures margin percent is valid after settlement
     * @param account The address of the account that will be settled
     * @param insuranceMultiplyFactor The multiplying factor for the insurance rate
     * @param currentGlobalRate The current global interest rate 
     * @param currentUserRate The users current interest rate 
     * @param currentInsuranceGlobalRate The current general insurance rate 
     * @param currentInsuranceUserRate The users current insurance rate
     * @param gasPrice The gas price as given by the gasOracle
     * @param priceMultiplier  The multiplying factor of the price
     * @param currentFundingIndex Index referencing which funding rate to use in this function 
     */
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
    ) external override isValidTracer(msg.sender) { 
        Types.AccountBalance storage accountBalance = balances[msg.sender][account];
        Types.AccountBalance storage insuranceBalance = balances[msg.sender][insuranceContract];

        // Calc the difference in funding rates, remove price multiply factor
        int256 fundingDiff = currentGlobalRate.sub(currentUserRate);

        // Update account, divide by 2x price multiplier to factor out price and funding rate scalar value
        // base - (fundingDiff * quote / (priceMultiplier * priceMultiplier))
        accountBalance.base = accountBalance.base.sub(
            fundingDiff.mul(accountBalance.quote).div((priceMultiplier.mul(priceMultiplier)).toInt256())
        );

        // Update account gas price
        accountBalance.lastUpdatedGasPrice = gasPrice;

        if (accountBalance.totalLeveragedValue > 0) {

            // calc and pay insurance funding rate
            int256 changeInInsuranceBalance = (currentInsuranceGlobalRate.sub(currentInsuranceUserRate)).mul(accountBalance.totalLeveragedValue).div(
                insuranceMultiplyFactor
            );

            if (changeInInsuranceBalance > 0) {
                // Only pay insurance fund if required
                accountBalance.base = accountBalance.base.sub(changeInInsuranceBalance);
                insuranceBalance.base = insuranceBalance.base.add(changeInInsuranceBalance);
                // uint is safe since changeInInsuranceBalance > 0
                insuranceBalance.deposited = insuranceBalance.deposited.add(uint256(changeInInsuranceBalance));
            }
        }

        // Update account index
        accountBalance.lastUpdatedIndex = currentFundingIndex;
        require(userMarginIsValid(account, msg.sender), "ACT: Target under-margined");
        emit AccountSettled(account, accountBalance.base);
    }

    /**
     * @notice Liquidates the margin account of a particular user. A deposit is needed from the liquidator. 
     *         Generates a liquidation receipt for the liquidator to use should they need a refund.
     * @param amount The amount of tokens to be liquidated 
     * @param account The account that is to be liquidated. 
     * @param market The Tracer market in which this margin account will be liquidated.
     */
    function liquidate(
        int256 amount, 
        address account,
        address market
    ) external override isValidTracer(market) {

        int256 price = pricing.fairPrices(market);
        int256 margin = getUserMargin(account, market);
        int256 liquidateeQuote = balances[market][account].quote;
        
        require(amount > 0, "ACTL: Liquidation amount <= 0");
        require(
            !userMarginIsValid(account, market),
            "ACTL: Account above margin "
        );

        require(amount <= liquidateeQuote.abs(), "ACTL: Liquidate Amount > Position");

        // calc funds to liquidate and move to Escrow
        uint256 amountToEscrow = calcEscrowLiquidationAmount(
            account,
            margin,
            market
        );

        // Liquidated the account at "account" in the "market" market, function caller is liquidator
        // Updates the state of both accounts as if the liquidation is fully processed
        liquidateAccount(msg.sender, account, amount, market);

        // create a liquidation receipt
        bool side = liquidateeQuote < 0 ? false : true;
        receipt.submitLiquidation(
            market,
            msg.sender,
            account,
            price,
            amountToEscrow,
            amount,
            side
        );

        // Escrow liquidator funds
        Types.AccountBalance memory liqBalance = balances[market][msg.sender];
        balances[market][msg.sender].base = liqBalance.base.sub(amountToEscrow.toInt256());

        
        // Limits the gas use when liquidating 
        int256 gasPrice = IOracle(ITracer(market).gasPriceOracle()).latestAnswer();
        require(tx.gasprice <= uint256(gasPrice.abs()), "ACTL: GasPrice > FGasPrice");

        // Checks if the liquidator is in a valid position to process the liquidation 
        require(
            marginIsValid(
                liqBalance.base,
                liqBalance.quote,
                price,
                gasPrice,
                market
            ),
            "ACTL: Taker undermargin"
        );

        // Update liquidators last updated gas price
        balances[market][msg.sender].lastUpdatedGasPrice = gasPrice;
        emit Liquidate(account, msg.sender, amount, side, market, receipt.currentLiquidationId() - 1);
    }

    /**
     * @notice Allows a liquidator to submit a single liquidation receipt and multiple order ids. If the
     *         liquidator experienced slippage, will refund them a proportional amount of their deposit.
     * @param receiptID Used to identify the receipt that will be claimed
     * @param orderIds The IDs of the orders contained in the liquidation, these are emitted when an order is made
     * @param market The address of the tracer market where the liquidation and receipt originated
     */
    function claimReceipts(
        uint256 receiptID,
        uint256[] memory orderIds,
        address market
    ) public override {
        // Claim the receipts from the escrow system, get back amount to return
        (, address receiptLiquidator, address receiptLiquidatee, , , uint256 escrowedAmount, , , , ,) = receipt 
            .getLiquidationReceipt(receiptID);
        int256 liquidatorMargin = balances[market][receiptLiquidator].base;
        int256 liquidateeMargin = balances[market][receiptLiquidatee].base;
        ITracer tracer = ITracer(market);
        uint256 amountToReturn = receipt.claimReceipts(receiptID, orderIds, tracer.priceMultiplier(), market, msg.sender);

        /* 
         * If there was not enough escrowed, we want to call the insurance pool to help out.
         * First, check the margin of the insurance Account. If this is enough, just drain from there.
         * If this is not enough, call Insurance.drainPool to get some tokens from the insurance pool.
         * If drainPool is able to drain enough, drain from the new margin.
         * If the margin still does not have enough after calling drainPool, we are not able to fully
         * claim the receipt, only up to the amount the insurance pool allows for.
         */
        if (amountToReturn > escrowedAmount) { // Need to cover some loses with the insurance contract
            // Amount needed from insurance
            uint256 amountWantedFromInsurance = amountToReturn - escrowedAmount;
            // Keep track of how much was actually taken out of insurance
            uint256 amountTakenFromInsurance = 0;

            Types.AccountBalance storage insuranceBalance = balances[market][insuranceContract];
            if (insuranceBalance.base >= amountWantedFromInsurance.toInt256()) { // We don't need to drain insurance contract
                insuranceBalance.base = insuranceBalance.base - amountWantedFromInsurance.toInt256();
                amountTakenFromInsurance = amountWantedFromInsurance;
            } else { // insuranceBalance.base < amountWantedFromInsurance
                if (insuranceBalance.base <= 0) {
                    // attempt to drain entire balance that is needed from the pool
                    IInsurance(insuranceContract).drainPool(market, amountWantedFromInsurance);
                } else {
                    // attempt to drain the required balance taking into account the insurance balance in the account contract
                    IInsurance(insuranceContract).drainPool(market, amountWantedFromInsurance.sub(uint256(insuranceBalance.base)));
                }
                if (insuranceBalance.base < amountWantedFromInsurance.toInt256()) { // Still not enough
                    amountTakenFromInsurance = uint(insuranceBalance.base);
                    insuranceBalance.base = 0;
                } else { // insuranceBalance.base >= amountWantedFromInsurance
                    insuranceBalance.base = insuranceBalance.base - amountWantedFromInsurance.toInt256();
                    amountTakenFromInsurance = amountWantedFromInsurance;
                }
            }

            balances[market][receiptLiquidator].base =
                    liquidatorMargin.add((escrowedAmount.add(amountTakenFromInsurance).toInt256()));
            // Don't add any to liquidatee
        } else {
            balances[market][receiptLiquidator].base = liquidatorMargin.add(amountToReturn.toInt256());
            balances[market][receiptLiquidatee].base = liquidateeMargin.add(escrowedAmount.toInt256().sub(amountToReturn.toInt256()));
        }
        emit ClaimedReceipts(msg.sender, market, orderIds);
    }

    /**
     * @notice Allows a trader to claim escrowed funds after the escrow period has expired
     * @param receiptId The ID number of the insurance receipt from which funds are being claimed from
     */
    function claimEscrow(uint256 receiptId) public override {
        // Get receipt
        (address receiptTracer, , address liquidatee , , , , uint256 releaseTime, ,bool escrowClaimed , ,) = receipt.getLiquidationReceipt(receiptId);
        require(liquidatee == msg.sender, "ACTL: Not Entitled");
        require(!escrowClaimed, "ACTL: Already claimed");
        require(block.timestamp > releaseTime, "ACTL: Not yet released");
        
        // Update balance and mark as claimed
        int256 accountMargin = balances[receiptTracer][msg.sender].base;
        int256 amountToReturn = receipt.claimEscrow(receiptId, liquidatee);
        balances[receiptTracer][msg.sender].base = accountMargin.add(amountToReturn);
        emit ClaimedEscrow(msg.sender, receiptTracer, receiptId);
    }

    /**
     * @notice Calculate the amount of funds a liquidator must escrow to claim the liquidation.
     * @param liquidatee The address of the liquadatees account 
     * @param currentUserMargin The users current margin 
     * @param market The address of the Tracer market thats being targeted for this calculation 
     *               (e.g. USD tracer would calculate Escrow amount for the USD tracer market)
     * @return either the amount to escrow (uint) or zero if the userMargin is less than 0 
     */
    function calcEscrowLiquidationAmount(
        address liquidatee,
        int256 currentUserMargin,
        address market
    ) internal view returns (uint256) {
        int256 minMargin = getUserMinMargin(liquidatee, market);
        int256 amountToEscrow = currentUserMargin.sub(minMargin.sub(currentUserMargin));
        if (amountToEscrow < 0) {
            return 0;
        }
        return uint256(amountToEscrow);
    }

    /**
     * @notice Updates both the trader and liquidators account on a liquidation event.
     * @param liquidator The address of the account that is the liquidator 
     * @param liquidatee The address of the account to be liquidated 
     * @param amount The amount that is to be liquidated from the position 
     * @param market The address of the relevant Tracer market for this liquidation 
     */
     function liquidateAccount(
        address liquidator,
        address liquidatee,
        int256 amount,
        address market
    ) internal {
        Types.AccountBalance storage userBalance = balances[market][liquidatee]; 
        Types.AccountBalance storage liqBalance = balances[market][liquidator];
        if (userBalance.base > 0) {
            // Add to the liquidators margin, they are taking on positive margin
            liqBalance.base = liqBalance.base.add(
                (userBalance.base.mul(amount.mul(PERCENT_PRECISION).div(userBalance.quote.abs()))).div(
                    PERCENT_PRECISION
                )
            );

            // Subtract from the liquidatees margin
            userBalance.base = userBalance.base.sub(
                userBalance.base.mul(amount.mul(PERCENT_PRECISION).div(userBalance.quote.abs())).div(
                    PERCENT_PRECISION
                )
            );
        } else {
            // Subtract from the liquidators margin, they are taking on negative margin
            liqBalance.base = liqBalance.base.sub(
                (userBalance.base.mul(amount.mul(PERCENT_PRECISION).div(userBalance.quote.abs()))).div(
                    PERCENT_PRECISION
                )
            );

            // Add this to the user balances margin
            userBalance.base = userBalance.base.add(
                userBalance.base.mul(amount.mul(PERCENT_PRECISION).div(userBalance.quote.abs())).div(
                    PERCENT_PRECISION
                )
            );
        }

        if (userBalance.quote > 0) {
            // Take from liquidatee, give to liquidator
            liqBalance.quote = liqBalance.quote.add(amount);
            userBalance.quote = userBalance.quote.sub(amount);
        } else {
            // Take from liquidator, give to liquidatee
            liqBalance.quote = liqBalance.quote.sub(amount);
            userBalance.quote = userBalance.quote.add(amount);
        }
    }

    /**
     * @notice Updates the account state of a user given a specific tracer, in a trade event. Adds the 
     *         passed in margin and position changes to the current margin and position.
     * @dev Related to permissionedTakeOrder() in tracer.sol 
     * @param baseChange Is equal to: FillAmount.mul(uint256(order.price))).div(priceMultiplier).toInt256()
     * @param quoteChange The amount of the order filled changed to be negative (e.g. if 100$ of the order is filled this would be -$100  )
     * @param accountAddress The address of the account to be updated 
     * @param market The address of the tracer market, used to target the tracer market where the update is relevant 
     */
    function updateAccountOnTrade(
        int256 baseChange,
        int256 quoteChange,
        address accountAddress,
        address market
    ) external override onlyTracer(market) {
        Types.AccountBalance storage userBalance = balances[market][accountAddress];
        ITracer _tracer = ITracer(market);
        userBalance.base = userBalance.base.add(baseChange);
        userBalance.quote = userBalance.quote.add(quoteChange);
        userBalance.lastUpdatedGasPrice = IOracle(_tracer.gasPriceOracle()).latestAnswer();
    }

    /**
     * @notice Updates an accounts total leveraged value. Can only be called by a valid
     *         tracer market.
     * @param account the account to update.
     * @param market the tracer market for which the leverage is being updated
     */
    function updateAccountLeverage(
        address account,
        address market
    ) public override onlyTracer(msg.sender) {
        Types.AccountBalance memory userBalance = balances[market][account];
        int256 originalLeverage = userBalance.totalLeveragedValue;
        _updateAccountLeverage(
            userBalance.quote,
            pricing.fairPrices(market),
            userBalance.base,
            account,
            market,
            originalLeverage
        );
    }

    /**
     * @notice internal function for updating leverage. Called within the Account contract. Also
     *         updates the total leveraged notional value for the tracer market itself.
     */
    function _updateAccountLeverage(
        int256 quote,
        int256 price,
        int256 base,
        address account,
        address market,
        int256 originalLeverage
    ) internal {
        int256 newLeverage = Balances.newCalcLeveragedNotionalValue(
            quote,
            price,
            base,
            ITracer(market).priceMultiplier()
        );
        balances[market][account].totalLeveragedValue = newLeverage;

        // Update market leveraged notional value
        updateTracerLeverage(newLeverage, originalLeverage, market);
    }

    /**
     * @notice Updates the global leverage value given an accounts new leveraged value and old leveraged value
     * @param accountNewLeveragedNotional The future notional value of the account
     * @param accountOldLeveragedNotional The stored notional value of the account
     */
    function updateTracerLeverage(int256 accountNewLeveragedNotional, int256 accountOldLeveragedNotional, address market) internal {
        /*
        Update notional value
        Method:
        For both maker and taker, calculate the new leveraged notional value, as well as their change
        in leverage. In 3 cases, this should update the global leverage. There are only 3 cases since we don"t
        want the contract to store negative leverage (over collateralized accounts should not zero out leveraged accounts)
        
        Cases are:
        a. New leverage is positive and the accounts previous leveraged was positive (leverage increase)
        total contract leverage has increased by the difference between these two (delta)
        b. new leveraged is positive, and old leverage was negative (leverage increase)
        total contract leverage has increased by the difference between zero and the new leverage
        c. new leverage is negative, the change in leverage is negative, but the old leverage was positive (leverage decrease)
        total contract leverage has decreased by the difference between the old leverage and zero
        (which is the old leveraged value)
        */
        int256 accountDelta = accountNewLeveragedNotional.sub(accountOldLeveragedNotional);
        if (accountNewLeveragedNotional > 0 && accountOldLeveragedNotional >= 0) {
            tracerLeveragedNotionalValue[market] = tracerLeveragedNotionalValue[market].add(accountDelta);
        } else if (accountNewLeveragedNotional > 0 && accountOldLeveragedNotional < 0) {
            tracerLeveragedNotionalValue[market] = tracerLeveragedNotionalValue[market].add(accountNewLeveragedNotional);
        } else if (accountNewLeveragedNotional <= 0 && accountDelta < 0 && accountOldLeveragedNotional > 0) {
            tracerLeveragedNotionalValue[market] = tracerLeveragedNotionalValue[market].sub(accountOldLeveragedNotional);
        }
    }
   
    /** 
     * @notice Returns the values of the balance struct of a particular account in a market
     * @param account Address of account to check balance of 
     * @param market Address of the relevant Tracer market 
     */
    function getBalance(address account, address market)
        external
        override
        view
        returns (
            int256 base,
            int256 quote,
            int256 totalLeveragedValue,
            uint256 deposited,
            int256 lastUpdatedGasPrice,
            uint256 lastUpdatedIndex
        )
    {
        Types.AccountBalance memory userBalance = balances[market][account];
        return (
            userBalance.base,
            userBalance.quote,
            userBalance.totalLeveragedValue,
            userBalance.deposited,
            userBalance.lastUpdatedGasPrice,
            userBalance.lastUpdatedIndex
        );
    }
  
    /**
     * @notice Checks the validity of a potential margin given the necessary parameters 
     * @param base The base value to be assessed (positive or negative)
     * @param quote The accounts quote units
     * @param price The market price of the quote asset
     * @param gasPrice The gas price
     * @param market The relevant tracer market
     * @return a bool representing the validity of a margin
     */
    function marginIsValid(
        int256 base,
        int256 quote,
        int256 price, 
        int256 gasPrice,
        address market
    ) public override view returns (bool) {
        ITracer _tracer = ITracer(market);
        int256 gasCost = gasPrice.mul(_tracer.LIQUIDATION_GAS_COST().toInt256());
        int256 minMargin = Balances.calcMinMargin(quote, price, base, gasCost, _tracer.maxLeverage(), _tracer.priceMultiplier());
        int256 margin = Balances.calcMargin(quote, price, base, _tracer.priceMultiplier());

        if (margin < 0) {
            /* Margin being less than 0 is always invalid, even if position is 0.
               This could happen if user attempts to over-withdraw */
            return false;
        }
        if (minMargin == 0) {
            return true;
        }

        return margin > minMargin;
    }

    /**
     * @notice Checks if a given accounts margin is valid
     * @param account The address of the account whose margin is to be checked 
     * @param market The address of the tracer market of whose margin is to be checked 
     * @return true if the margin is valid or false otherwise 
     */
    function userMarginIsValid(address account, address market) public override view returns (bool) {
        Types.AccountBalance memory accountBalance = balances[market][account];
        return
            marginIsValid(
                accountBalance.base,
                accountBalance.quote,
                pricing.fairPrices(market),
                accountBalance.lastUpdatedGasPrice,
                market
            );
    }

    /**
     * @notice Get the current margin of a user
     * @param account The address whose account is queried
     * @param market The address of the relevant Tracer market
     * @return the margin of the account
     */
    function getUserMargin(address account, address market) public override view returns (int256) {
        ITracer _tracer = ITracer(market);
        Types.AccountBalance memory accountBalance = balances[market][account];
        return Balances.calcMargin(
            accountBalance.quote, pricing.fairPrices(market), accountBalance.base, _tracer.priceMultiplier());
    }

    /**
     * @notice Get the current notional value of a user
     * @param account The address whose account is queried
     * @param market The address of the relevant Tracer market
     * @return the margin of the account in power of 10^18
     */
    function getUserNotionalValue(address account, address market) public override view returns (int256) {
        ITracer _tracer = ITracer(market);
        Types.AccountBalance memory accountBalance = balances[market][account];
        return Balances.calcNotionalValue(accountBalance.quote, pricing.fairPrices(market)).div(_tracer.priceMultiplier().toInt256());
    }

    /**
     * @notice Get the current minimum margin of a user
     * @dev This value, at the current price, is what the user's margin must remain over
            lest they become at risk of liquidation
     * @param account The address whose account is queried
     * @param market The address of the relevant Tracer market
     * @return the margin of the account
     */
    function getUserMinMargin(address account, address market) public override view returns (int256) {
        ITracer _tracer = ITracer(market);
        Types.AccountBalance memory accountBalance = balances[market][account];
        return Balances.calcMinMargin(
            accountBalance.quote,
            pricing.fairPrices(market),
            accountBalance.base,
            accountBalance.lastUpdatedGasPrice.mul(_tracer.LIQUIDATION_GAS_COST().toInt256()),
            _tracer.maxLeverage(),
            _tracer.priceMultiplier()
        );
    }

    /**
     * @param newReceiptContract The new instance of Receipt.sol
     */
    function setReceiptContract(address newReceiptContract) public override onlyOwner() {
        receipt = IReceipt(newReceiptContract);
    }

    /**
     * @param newInsuranceContract The new instance of Insurance.sol
     */
    function setInsuranceContract(address newInsuranceContract) public override onlyOwner() {
        insuranceContract = newInsuranceContract;
    }

    /**
     * @param newGasPriceOracle The new instance of GasOracle.sol
     */
    function setGasPriceOracle(address newGasPriceOracle) public override onlyOwner() {
        gasPriceOracle = newGasPriceOracle;
    }

    /**
     * @param newFactory The new instance of Factory.sol
     */
    function setFactoryContract(address newFactory) public override onlyOwner() {
        factory = ITracerFactory(newFactory);
    }

    /**
     * @param newPricing The new instance of Pricing.sol
     */
    function setPricingContract(address newPricing) public override onlyOwner() {
        pricing = IPricing(newPricing);
    }

    /**
     * @dev Ensures that only a valid Tracer contract can call this function
     * @param market The address to verify
     */
    modifier onlyTracer(address market) {
        require(
            msg.sender == market && factory.validTracers(market),
            "ACT: Tracer only function "
        );
        _;
    }


    /**
     * @dev Checks if that passed address is a valid tracer address (i.e. is part of a tracerfactory)
     * @param market The Tracer market to check
     */
    modifier isValidTracer(address market) {
        require(factory.validTracers(market), "ACT: Target not valid tracer");
        _;
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
pragma experimental ABIEncoderV2;
import "./Types.sol";

interface IReceipt {
    function submitLiquidation(
        address market,
        address liquidator,
        address liquidatee,
        int256 price,
        uint256 escrowedAmount,
        int256 amountLiquidated,
        bool liquidationSide
    ) external;

    function claimEscrow(uint256 id, address trader) external returns (int256);

    function claimReceipts(
        uint256 escrowId,
        uint256[] memory orderIds,
        uint256 priceMultiplier,
        address market,
        address liquidator
    ) external returns (uint256);

    function getLiquidationReceipt(uint256 id)
        external
        view
        returns (
            address,
            address,
            address,
            int256,
            uint256,
            uint256,
            uint256,
            int256,
            bool,
            bool,
            bool
        );

    function currentLiquidationId() external view returns(uint256);

    function maxSlippage() external view returns(int256);

    function setMaxSlippage(int256 _maxSlippage) external;
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

interface ITracerFactory {

    function tracersByIndex(uint256 count) external view returns (address);

    function validTracers(address market) external view returns (bool);

    function daoApproved(address market) external view returns (bool);

    function setInsuranceContract(address newInsurance) external;

    function setDeployerContract(address newDeployer) external;

    function setApproved(address market, bool value) external;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}