// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ControllerStorage.sol";
import "./ControllerAbstract.sol";
import "./ErrorReporter.sol";
import "./Unitroller.sol";

/**
 * @title Creditum's Controller Contract
 * @author Creditum
 */
contract Controller is ControllerV1Storage, ControllerAbstract, ErrorReporter {
    uint public constant MULTIPLIER = 10**18;

    modifier onlyAdmin() {
        require(_msgSender() == owner() || _msgSender() == controllerImplementation, "Controller: !unauthorized");
        _;
    }

    /* ========== PROTOCOL FUNCTIONS ========== */

    function enterAllowed(
        address user, 
        address collateral, 
        uint depositAmount, 
        uint borrowAmount
    ) external override returns (uint) {
        // Silence warnings
        user;
        depositAmount;
        borrowAmount;

        CollateralData memory collateralDataCopy = collateralData[collateral];
        if (!collateralDataCopy.allowed) {
            return fail(Error.COLLATERAL_NOT_ALLOWED);
        }
        if (collateralDataCopy.maxDebtRatio == 0) {
            return fail(Error.INVALID_MAX_DEBT_RATIO);
        }
        if (collateralDataCopy.liquidationThreshold == 0) {
            return fail(Error.INVALID_LIQUIDATION_THRESHOLD);
        }
        if (collateralDataCopy.depreciationDuration == 0) {
            return fail(Error.INVALID_DEPRECIATION_DURATION);
        }

        // Ensure position isn't pending liquidation
        (uint triggerTimestamp, ) = core.auctionData(collateral, user);
        if (triggerTimestamp > 0) {
            return fail(Error.PENDING_LIQUIDATION);
        }

        return uint(Error.NO_ERROR);
    }

    function enterVerify(
        address user, 
        address collateral, 
        uint depositAmount, 
        uint borrowAmount
    ) external override {
        // Silence warnings
        user;
        collateral;
        depositAmount;
        borrowAmount;

        if (false) {
            paused = paused;
        }
    }

    function depositAllowed(
        address user, 
        address collateral, 
        uint depositAmount
    ) external override returns (uint) {
        // Silence warnings
        user;
        collateral;
        depositAmount;

        if (false) {
            paused = paused;
        }

        return uint(Error.NO_ERROR);
    }

    function depositVerify(
        address user, 
        address collateral, 
        uint depositAmount
    ) external override {
        // Silence warnings
        user;
        collateral;
        depositAmount;

        if (false) {
            paused = paused;
        }
    }

    function borrowAllowed(
        address user, 
        address collateral, 
        uint borrowAmount
    ) external override returns (uint) {
        uint totalDebt = getDebtValue(user, collateral);
        (, uint debt, ) = core.userData(collateral, user);
        uint totalMinted = core.totalMinted(collateral) + totalDebt - debt;

        if (totalMinted + borrowAmount > collateralData[collateral].mintLimit) {
            return fail(Error.EXCEEDS_MINT_LIMIT);
        }

        return uint(Error.NO_ERROR);
    }

    function borrowVerify(
        address user, 
        address collateral, 
        uint borrowAmount
    ) external override {
        // Silence warnings
        user;
        collateral;
        borrowAmount;

        if (false) {
            paused = paused;
        }
    }

    function exitAllowed(
        address user,
        address collateral, 
        uint withdrawAmount, 
        uint repayAmount
    ) external override returns (uint) {
        // Silence warnings
        withdrawAmount;
        repayAmount;

        // Ensure position isn't pending liquidation
        (uint triggerTimestamp, ) = core.auctionData(collateral, user);
        if (triggerTimestamp > 0) {
            return fail(Error.PENDING_LIQUIDATION);
        }

        return uint(Error.NO_ERROR);
    }

    function exitVerify(
        address user, 
        address collateral, 
        uint withdrawAmount, 
        uint repayAmount
    ) external override {
        // Silence warnings
        user;
        collateral;
        withdrawAmount;
        repayAmount;

        if (false) {
            paused = paused;
        }
    }

    function repayAllowed(
        address user, 
        address collateral, 
        uint repayAmount 
    ) external override returns (uint) {
        // Silence warnings
        user;
        collateral;
        repayAmount;

        if (false) {
            paused = paused;
        }

        return uint(Error.NO_ERROR);
    }

    function repayVerify(
        address user, 
        address collateral, 
        uint repayAmount
    ) external override {
        // Silence warnings
        user;
        collateral;
        repayAmount;

        if (false) {
            paused = paused;
        }
    }

    function withdrawAllowed(
        address user,
        address collateral, 
        uint withdrawAmount
    ) external override returns (uint) {
        // Silence warnings
        user;
        collateral;
        withdrawAmount;
        
        if (false) {
            paused = paused;
        }

        return uint(Error.NO_ERROR);
    }

    function withdrawVerify(
        address user,
        address collateral, 
        uint withdrawAmount
    ) external override {
        // Silence warnings
        user;
        collateral;
        withdrawAmount;
        
        if (false) {
            paused = paused;
        }
    }

    function triggerLiquidationAllowed(
        address caller, 
        address borrower, 
        address collateral
    ) external override returns (uint) {
        // Silence warnings
        caller;

        // Ensure position isn't already triggered for liquidation
        (uint triggerTimestamp, ) = core.auctionData(collateral, borrower);
        if (triggerTimestamp != 0) {
            return fail(Error.PENDING_LIQUIDATION);
        }

        (uint error, , , , , uint healthFactor) = getPositionData(borrower, collateral);
        if (error != uint(Error.NO_ERROR)) {
            return fail(Error(error));
        }

        if (healthFactor >= MULTIPLIER) {
            return fail(Error.POSITION_NOT_LIQUIDATABLE);
        }

        return uint(Error.NO_ERROR);
    }

    function triggerLiquidationVerify(
        address caller, 
        address borrower, 
        address collateral
    ) external override {
        // Silence warnings
        caller;
        borrower;
        collateral;

        if (false) {
            paused = paused;
        }
    }

    function liquidateBorrowAllowed(
        address liquidator, 
        address borrower, 
        address collateral
    ) external override returns (uint) {
        // Ensure position has been triggered for liquidation
        (uint triggerTimestamp, ) = core.auctionData(collateral, borrower);
        if (triggerTimestamp == 0) {
            return fail(Error.LIQUIDATION_NOT_TRIGGERED);
        }

        // Borrower can not be liquidator
        if (borrower == liquidator) {
            return fail(Error.LIQUIDATOR_IS_BORROWER);
        }

        return uint(Error.NO_ERROR);
    }

    function liquidateBorrowVerify(
        address liquidator, 
        address borrower, 
        address collateral
    ) external override {
        // Silence warnings
        liquidator;
        borrower;
        collateral;

        if (false) {
            paused = paused;
        }
    }

    function stabilizerMintAllowed(
        address user, 
        address underlying, 
        uint amount
    ) external override returns (uint) {
        // Silence warnings
        user;
        amount;

        if (!stabilizerData[underlying].allowed) {
            return fail(Error.UNDERLYING_NOT_ALLOWED);
        }

        return uint(Error.NO_ERROR);
    }

    function stabilizerMintVerify(
        address user, 
        address underlying, 
        uint amount
    ) external override {
        // Silence warnings
        user;
        underlying;
        amount;

        if (false) {
            paused = paused;
        }
    }

    function stabilizerRedeemAllowed(
        address user, 
        address underlying, 
        uint amount
    ) external override returns (uint) {
        // Silence warnings
        user;
        amount;

        if (!stabilizerData[underlying].allowed) {
            return fail(Error.UNDERLYING_NOT_ALLOWED);
        }

        // Calculate redeem fee and burn amount
        uint stabilizerFee = stabilizerData[underlying].stabilizerFee;
        uint fee = amount * stabilizerFee / MULTIPLIER;
        uint burnAmount = amount - fee;

        uint redeemAmount;
        uint decimals = IERC20(underlying).decimals();
        if (decimals <= 18) {
            redeemAmount = burnAmount / 10**(18 - decimals);
        } else {
            redeemAmount = burnAmount * 10**(decimals - 18);
        }

        uint stabilizerBalance = core.stabilizerDeposits(underlying);
        if (redeemAmount > stabilizerBalance) {
            return fail(Error.INSUFFICIENT_UNDERLYING_BALANCE);
        }
        
        return uint(Error.NO_ERROR);
    }

    function stabilizerRedeemVerify(
        address user, 
        address underlying, 
        uint amount
    ) external override {
        // Silence warnings
        user;
        underlying;
        amount;

        if (false) {
            paused = paused;
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Calculates user's position data
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @return (error code, collateral value, debt value, liquidity, shortfall, health factor)
    function getPositionData(address user, address collateral) public view returns (uint, uint, uint, uint, uint, uint) {
        (uint error, uint collateralValue) = getCollateralValue(user, collateral);
        if (error != uint(Error.NO_ERROR)) {
            return (error, 0, 0, 0, 0, 0);
        }

        uint debtValue = getDebtValue(user, collateral);
        uint maxDebtRatio = collateralData[collateral].maxDebtRatio;
        uint liquidationThreshold = collateralData[collateral].liquidationThreshold;
        uint maxDebt = collateralValue * maxDebtRatio / MULTIPLIER;
        
        uint healthFactor;
        if (debtValue == 0) {
            healthFactor = type(uint).max;
        } else {
            healthFactor = collateralValue * liquidationThreshold / debtValue;
        }

        uint liquidity;
        uint shortfall;
        if (healthFactor >= MULTIPLIER) {
            // Use max debt-to-collateral ratio to calculate available borrow
            if (debtValue <= maxDebt) {
                liquidity = maxDebt - debtValue;
            }
        } else {
            // Use liquidation threshold to calculate shortfall
            shortfall = debtValue - collateralValue * liquidationThreshold / MULTIPLIER;
        }

        return (uint(Error.NO_ERROR), collateralValue, debtValue, liquidity, shortfall, healthFactor);
    }

    /// @notice Calculates user's deposit value for collateral
    /// @dev Collateral value (USD) is scaled by 1e18
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @return (error code, value of user's deposited collateral)
    function getCollateralValue(address user, address collateral) public view returns (uint, uint) {
        (uint deposits, , ) = core.userData(collateral, user);
        if (deposits == 0) {
            return (uint(Error.NO_ERROR), 0);
        }

        (uint error, uint collateralPrice) = getPriceUSD(collateral);
        if (error != uint(Error.NO_ERROR)) {
            return (error, 0);
        }

        // Calculate total collateral value and scale to 1e18 (using collateral's decimals)
        uint8 decimals = IERC20(collateral).decimals();
        uint collateralValue = deposits * collateralPrice / 10**decimals;
        return (uint(Error.NO_ERROR), collateralValue);
    }

    /// @notice Returns price for token
    /// @dev Price (USD) is scaled by 1e18
    /// @param token The address of the token
    /// @return (error code, price of token in USD)
    function getPriceUSD(address token) public view returns (uint, uint) {
        if (address(oracle) == address(0)) {
            return (uint(Error.INVALID_ORACLE_ADDRESS), 0);
        }

        if (token == address(0)) {
            return (uint(Error.INVALID_TOKEN_TO_GET_PRICE), 0);
        }

        try oracle.getPriceUSD(token) returns (uint price) {
            if (price == 0) {
                return (uint(Error.INVALID_ORACLE_PRICE), 0);
            }
            return (uint(Error.NO_ERROR), price);
        } catch {
            return (uint(Error.INVALID_ORACLE_CALL), 0);
        }
    }

    /// @notice Calculates user's total outstanding debt for collateral
    /// @dev Total debt includes accrued interest
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @return totalDebt The total outstanding debt for user's collateral
    function getDebtValue(address user, address collateral) public view returns (uint) {
        (, uint positionDebt, ) = core.userData(collateral, user);
        (uint triggerTimestamp, ) = core.auctionData(collateral, user);
        if (triggerTimestamp > 0) {
            // Ignore accrued interest in total debt calculation since position is pending liquidation
            return positionDebt;
        } else {
            // Calculate total debt as current debt + fees (accrued interest)
            uint fees = getFeeCalculation(user, collateral, positionDebt);
            return positionDebt + fees;
        }
    }

    /// @notice Calculates interest accrued for `amount` of outstanding debt
    /// @dev Interest is calculated from annual stability fee and time elapsed since last update
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @param amount The amount of debt to calculate fee for
    /// @return fee The amount of interest accrued accrued since the last update
    function getFeeCalculation(address user, address collateral, uint amount) public view returns (uint) {
        uint stabilityFee = collateralData[collateral].stabilityFee;
        (, , uint lastUpdatedAt) = core.userData(collateral, user);
        uint timeElapsed = block.timestamp - lastUpdatedAt;

        // Calculate accrued interest based on time elapsed and stability fee
        return amount * stabilityFee * timeElapsed / (365 days * MULTIPLIER);
    }

    /// @notice Calculates principal amount for `repayAmount` of debt (including interest)
    /// @dev Principal Amount = Repay Amount - Accrued Interest
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @param amountWithInterest The amount of debt, including accrued interest
    /// @return principal The principal amount of debt, not including accrued interest
    function getPrincipalAmount(address user, address collateral, uint amountWithInterest) public view returns (uint) {
        (, , uint lastUpdatedAt) = core.userData(collateral, user);
        if (lastUpdatedAt > 0) {
            uint stabilityFee = collateralData[collateral].stabilityFee;
            uint timeElapsed = block.timestamp - lastUpdatedAt;
            uint fee = stabilityFee * timeElapsed / 365 days;

            // Calculate principal amount based on time elapsed and stability fee
            return amountWithInterest * MULTIPLIER / (MULTIPLIER + fee);
        } else {
            return amountWithInterest;
        }
    }

    /// @notice Gets auction price, amount to reward liquidator, and amount to return to owner
    /// @param borrower The borrower to be liquidated
    /// @param collateral The borrower's collateral to liquidate
    /// @return (amount of collateral to reward liquidator, amount of collateral to return to owner, cost to buyout the auction)
    function getAuctionDetails(address borrower, address collateral) public view returns (uint, uint, uint) {
        uint depreciationDuration = collateralData[collateral].depreciationDuration;
        (uint triggerTimestamp, uint initialPrice) = core.auctionData(collateral, borrower);
        uint timeElapsed = block.timestamp - triggerTimestamp;
        uint debt = getDebtValue(borrower, collateral);
        uint penalty = debt * collateralData[collateral].liquidationPenalty / MULTIPLIER;
        (uint totalCollateral, , ) = core.userData(collateral, borrower);

        // Calculate collateral to reward liquidator, collateral to return to owner, and auction price
        return calcAuctionDetails(depreciationDuration, timeElapsed, initialPrice, debt + penalty, totalCollateral);
    }

    /// @notice Calculates auction price, amount to reward liquidator, and amount to return to owner
    /// @dev Auction price decreases linearly over depreciation duration
    /// @dev If full depreciation duration has passed, auction price is 0
    /// @param timeElapsed The time elapsed from liquidation trigger to now
    /// @param initialPrice The initial auction price of the liquidatable user's collateral
    /// @param totalDebt The liquidatable user's debt
    /// @param totalCollateral The amount of collateral the liquidatable user has deposited
    /// @return (amount of collateral to reward liquidator, amount of collateral to return to owner, cost to buyout the auction)
    function calcAuctionDetails(
        uint depreciationDuration,
        uint timeElapsed, 
        uint initialPrice, 
        uint totalDebt, 
        uint totalCollateral
    ) public pure returns (uint, uint, uint) {
        if (depreciationDuration > timeElapsed) {
            // Since depreciation duration hasn't passed, calculate auction price based on time elapsed since liquidation trigger
            uint depreciatedCost = initialPrice * (depreciationDuration - timeElapsed) / depreciationDuration;

            if (depreciatedCost > totalDebt) {
                // Since depreciated cost is > total debt, reward collateral to liquidator and return rest to owner (partially liquidated)
                uint collateralToLiquidator = totalCollateral * totalDebt / depreciatedCost;
                uint collateralToOwner = totalCollateral - collateralToLiquidator;

                return (collateralToLiquidator, collateralToOwner, totalDebt);
            } else {
                // Since depreciated cost is < total debt, reward all collateral to liquidator (fully liquidated)
                return (totalCollateral, 0, depreciatedCost);
            }
        } else {
            // Since depreciation duration has passed, auction price is 0 and will reward all collateral to liquidator (fully liquidated)
            return (totalCollateral, 0, 0);
        }
    }

    /// @notice Calculates user's liquidation price for collateral
    /// @dev Liquidation price is scaled by 1e18
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @return (error code, liquidation price of user's collateral)
    function getLiquidationPrice(address user, address collateral) external view returns (uint, uint) {
        uint debtValue = getDebtValue(user, collateral);
        if (debtValue == 0) {
            return (uint(Error.NO_ERROR), type(uint).max);
        }

        (uint error, uint collateralValue) = getCollateralValue(user, collateral);
        if (error != uint(Error.NO_ERROR)) {
            return (error, 0);
        }

        uint liquidationThreshold = collateralData[collateral].liquidationThreshold;
        uint liquidationPrice = debtValue * MULTIPLIER * MULTIPLIER / (collateralValue * liquidationThreshold);
        return (uint(Error.NO_ERROR), liquidationPrice);
    }

    /// @notice Calculates user's utilization ratio for collateral
    /// @dev Utilization ratio is scaled by 1e18
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @return (error code, utilization ratio of user's collateral)
    function getUtilizationRatio(address user, address collateral) external view returns (uint, uint) {
        uint debtValue = getDebtValue(user, collateral);
        if (debtValue == 0) {
            return (uint(Error.NO_ERROR), 0);
        }

        (uint error, uint collateralValue) = getCollateralValue(user, collateral);
        if (error != uint(Error.NO_ERROR)) {
            return (error, 0);
        }

        uint utilizationRatio = debtValue * MULTIPLIER / collateralValue;
        return (uint(Error.NO_ERROR), utilizationRatio);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    event ParameterChanged(string name, uint oldValue, uint newValue);
    event AddressChanged(string name, address oldAddress, address newAddress);

    function _setPaused(bool _paused) external onlyAdmin {
        emit ParameterChanged("paused", paused ? 1 : 0, _paused ? 1 : 0);
        paused = _paused;
    }

    function _setCore(Core newCore) external onlyAdmin {
        require(newCore.IS_CORE(), "Controller: core address is !contract");
        emit AddressChanged("core", address(core), address(newCore));
        core = newCore;
    }

    function _setOracle(IOracle newOracle) external onlyAdmin {
        require(newOracle.IS_ORACLE(), "Controller: oracle address is !contract");
        emit AddressChanged("oracle", address(oracle), address(newOracle));
        oracle = newOracle;
    }

    function _setTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Controller: treasury is 0");
        emit AddressChanged("treasury", treasury, newTreasury);
        treasury = newTreasury;
    }
   
    /// @notice Set all collateral parameters at once
    /// @dev Stability fee bounds: [0, 0.25] * 1e18
    /// @dev Mint fee bounds: [0, 0.05] * 1e18
    /// @dev Max debt ratio bounds: [0.1, 0.95] * 1e18
    /// @dev Mint limit bounds: [0, ∞) * 1e18
    /// @dev Liquidation threshold bounds: [max debt ratio + 0.01, 1) * 1e18
    /// @dev Liquidation penalty bounds: [0, 0.25] * 1e18
    /// @dev Depreciation duration bounds: [10 minutes, 1 hour]
    function _setCollateralParams(
        address collateral, 
        bool allowed,
        uint stabilityFee,
        uint mintFee,
        uint maxDebtRatio, 
        uint mintLimit, 
        uint liquidationThreshold, 
        uint liquidationPenalty, 
        uint depreciationDuration
    ) external onlyAdmin {
        _setAllowedCollateral(collateral, allowed);
        _setStabilityFee(collateral, stabilityFee);
        _setMintFee(collateral, mintFee);
        _setMaxDebtRatio(collateral, maxDebtRatio);
        _setMintLimit(collateral, mintLimit);
        _setLiquidationThreshold(collateral, liquidationThreshold);
        _setLiquidationPenalty(collateral, liquidationPenalty);
        _setDepreciationDuration(collateral, depreciationDuration);
    }

    function _setAllowedCollaterals(address[] calldata collaterals, bool[] calldata allowed) external onlyAdmin {
        require(collaterals.length == allowed.length, "Controller: lengths don't match");
        for (uint i; i < collaterals.length; i++) {
            _setAllowedCollateral(collaterals[i], allowed[i]);
        }
    }

    function _setAllowedCollateral(address collateral, bool allowed) public onlyAdmin {
        require(collateral != address(0), "Controller: collateral is 0");
        emit ParameterChanged("allowed", collateralData[collateral].allowed ? 1 : 0, allowed ? 1 : 0);
        collateralData[collateral].allowed = allowed;
    }

    function _setStabilityFees(address[] calldata collaterals, uint[] calldata stabilityFees) external onlyAdmin {
        require(collaterals.length == stabilityFees.length, "Controller: lengths don't match");
        for (uint i; i < collaterals.length; i++) {
            _setStabilityFee(collaterals[i], stabilityFees[i]);
        }
    }

    /// @notice Stability fee bounds: [0, 0.25] * 1e18
    function _setStabilityFee(address collateral, uint stabilityFee) public onlyAdmin {
        require(collateral != address(0), "Controller: collateral is 0");
        require(stabilityFee <= 0.25 ether, "Controller: stability fee outside bounds");
        emit ParameterChanged("stabilityFee", collateralData[collateral].stabilityFee, stabilityFee);
        collateralData[collateral].stabilityFee = stabilityFee;
    }

    function _setMintFees(address[] calldata collaterals, uint[] calldata mintFees) external onlyAdmin {
        require(collaterals.length == mintFees.length, "Controller: lengths don't match");
        for (uint i; i < collaterals.length; i++) {
            _setMintFee(collaterals[i], mintFees[i]);
        }
    }

    /// @notice Mint fee bounds: [0, 0.05] * 1e18
    function _setMintFee(address collateral, uint mintFee) public onlyAdmin {
        require(collateral != address(0), "Controller: collateral is 0");
        require(mintFee <= 0.05 ether, "Controller: mint fee outside bounds");
        emit ParameterChanged("mintFee", collateralData[collateral].mintFee, mintFee);
        collateralData[collateral].mintFee = mintFee;
    }

    function _setMaxDebtRatios(address[] calldata collaterals, uint[] calldata maxDebtRatios) external onlyAdmin {
        require(collaterals.length == maxDebtRatios.length, "Controller: lengths don't match");
        for (uint i; i < collaterals.length; i++) {
            _setMaxDebtRatio(collaterals[i], maxDebtRatios[i]);
        }
    }

    /// @notice Max debt ratio bounds: [0.1, 0.95] * 1e18
    function _setMaxDebtRatio(address collateral, uint maxDebtRatio) public onlyAdmin {
        require(collateral != address(0), "Controller: collateral is 0");
        require(maxDebtRatio >= 0.1 ether && maxDebtRatio <= 0.95 ether, "Controller: max debt ratio outside bounds");
        emit ParameterChanged("maxDebtRatio", collateralData[collateral].maxDebtRatio, maxDebtRatio);
        collateralData[collateral].maxDebtRatio = maxDebtRatio;
    }

    function _setMintLimits(address[] calldata collaterals, uint[] calldata mintLimits) external onlyAdmin {
        require(collaterals.length == mintLimits.length, "Controller: lengths don't match");
        for (uint i; i < collaterals.length; i++) {
            _setMintLimit(collaterals[i], mintLimits[i]);
        }
    }

    /// @notice Mint limit bounds: [0, ∞) * 1e18
    function _setMintLimit(address collateral, uint mintLimit) public onlyAdmin {
        require(collateral != address(0), "Controller: collateral is 0");
        emit ParameterChanged("mintLimit", collateralData[collateral].mintLimit, mintLimit);
        collateralData[collateral].mintLimit = mintLimit;
    }

    
    function _setLiquidationThresholds(address[] calldata collaterals, uint[] calldata liquidationThresholds) external onlyAdmin {
        require(collaterals.length == liquidationThresholds.length, "Controller: lengths don't match");
        for (uint i; i < collaterals.length; i++) {
            _setLiquidationThreshold(collaterals[i], liquidationThresholds[i]);
        }
    }

    /// @dev Liquidation threshold bounds: [max debt ratio + 0.01, 1) * 1e18
    function _setLiquidationThreshold(address collateral, uint liquidationThreshold) public onlyAdmin {
        require(collateral != address(0), "Controller: collateral is 0");
        uint maxDebtRatio = collateralData[collateral].maxDebtRatio;
        require(maxDebtRatio > 0, "Controller: cannot initialize liquidation threshold before max debt ratio");
        require(liquidationThreshold >= maxDebtRatio + 0.01 ether && liquidationThreshold < 1 ether, "Controller: liquidation threshold outside bounds");
        emit ParameterChanged("liquidationThreshold", collateralData[collateral].liquidationThreshold, liquidationThreshold);
        collateralData[collateral].liquidationThreshold = liquidationThreshold;
    }

    function _setLiquidationPenalties(address[] calldata collaterals, uint[] calldata liquidationPenalties) external onlyAdmin {
        require(collaterals.length == liquidationPenalties.length, "Controller: lengths don't match");
        for (uint i; i < collaterals.length; i++) {
            _setLiquidationPenalty(collaterals[i], liquidationPenalties[i]);
        }
    }

    /// @notice Liquidation penalty bounds: [0, 0.25] * 1e18
    function _setLiquidationPenalty(address collateral, uint liquidationPenalty) public onlyAdmin {
        require(collateral != address(0), "Controller: collateral is 0");
        require(liquidationPenalty <= 0.25 ether, "Controller: liquidation penalty outside bounds");
        emit ParameterChanged("liquidationPenalty", collateralData[collateral].liquidationPenalty, liquidationPenalty);
        collateralData[collateral].liquidationPenalty = liquidationPenalty;
    }

    function _setDepreciationDurations(address[] calldata collaterals, uint[] calldata depreciationDurations) external onlyAdmin {
        require(collaterals.length == depreciationDurations.length, "Controller: lengths don't match");
        for (uint i; i < collaterals.length; i++) {
            _setDepreciationDuration(collaterals[i], depreciationDurations[i]);
        }
    }

    /// @notice Depreciation duration bounds: [10 minutes, 1 hour]
    function _setDepreciationDuration(address collateral, uint depreciationDuration) public onlyAdmin {
        require(collateral != address(0), "Controller: collateral is 0");
        require(depreciationDuration >= 10 minutes && depreciationDuration <= 1 hours, "Controller: depreciation duration outside bounds");
        emit ParameterChanged("depreciationDuration", collateralData[collateral].depreciationDuration, depreciationDuration);
        collateralData[collateral].depreciationDuration = depreciationDuration;
    }

    function _setAllowedUnderlyings(address[] calldata underlyings, bool[] calldata allowed) external onlyAdmin {
        require(underlyings.length == allowed.length, "Controller: lengths don't match");
        for (uint i; i < underlyings.length; i++) {
            _setAllowedUnderlying(underlyings[i], allowed[i]);
        }
    }

    function _setAllowedUnderlying(address underlying, bool allowed) public onlyAdmin {
        require(underlying != address(0), "Controller: underlying is 0");
        emit ParameterChanged("allowed", stabilizerData[underlying].allowed ? 1 : 0, allowed ? 1 : 0);
        stabilizerData[underlying].allowed = allowed;
    }

    function _setStabilizerFees(address[] calldata underlyings, uint[] calldata stabilizerFees) external onlyAdmin {
        require(underlyings.length == stabilizerFees.length, "Controller: lengths don't match");
        for (uint i; i < underlyings.length; i++) {
            _setStabilizerFee(underlyings[i], stabilizerFees[i]);
        }
    }

    /// @notice Swap fee bounds: [0, 0.01] * 1e18
    function _setStabilizerFee(address underlying, uint _stabilizerFee) public onlyAdmin {
        require(underlying != address(0), "Controller: underlying is 0");
        require(_stabilizerFee <= 0.01 ether, "Controller: stabilizer fee outside bounds");
        emit ParameterChanged("stabilizerFee", stabilizerData[underlying].stabilizerFee, _stabilizerFee);
        stabilizerData[underlying].stabilizerFee = _stabilizerFee;
    }

    function _become(Unitroller unitroller) external {
        require(_msgSender() == unitroller.owner(), "Controller: !unitroller admin");
        unitroller._acceptImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/IOracle.sol";
import "./Core.sol";
import "./utils/Context.sol";
import "./utils/Ownable.sol";

contract UnitrollerAdminStorage is Context, Ownable {
    address public controllerImplementation;
    address public pendingControllerImplementation;
}

contract ControllerV1Storage is UnitrollerAdminStorage {
    struct CollateralData {
        bool allowed;               // Allow collateral to be used as collateral
        uint stabilityFee;          // Annualized stability fee (interest) charged for outstanding debt
        uint mintFee;               // Fee charged upfront when minting debt token
        uint maxDebtRatio;          // Maximum debt-to-collateral ratio to borrow
        uint mintLimit;             // Maximum mintable debt
        uint liquidationThreshold;  // Debt-to-collateral threshold at which position is liquidatable
        uint liquidationPenalty;    // Percentage of repaid liquidation amount to send to treasury
        uint depreciationDuration;  // Duration to linearly decrease auction price
    }

    struct StabilizerData {
        bool allowed;               // Allow swaps between fToken and underlying token via stabilizer
        uint stabilizerFee;         // Fee charged when minting or redeeming via stabilizer
    }

    bool public paused;
    
    Core public core;
    IOracle public oracle;
    address public treasury;

    // Collateral -> Collateral Data
    mapping(address => CollateralData) public collateralData;

    // Underlying token -> Stabilizer data
    mapping(address => StabilizerData) public stabilizerData;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract ControllerAbstract {
    bool public constant IS_CONTROLLER = true;

    function enterAllowed(
        address user, 
        address collateral, 
        uint depositAmount, 
        uint borrowAmount
    ) external virtual returns (uint);
    function enterVerify(
        address user, 
        address collateral, 
        uint depositAmount, 
        uint borrowAmount
    ) external virtual;

    function depositAllowed(
        address user, 
        address collateral, 
        uint depositAmount
    ) external virtual returns (uint);
    function depositVerify(
        address user, 
        address collateral, 
        uint depositAmount
    ) external virtual;

    function borrowAllowed(
        address user, 
        address collateral, 
        uint borrowAmount
    ) external virtual returns (uint);
    function borrowVerify(
        address user, 
        address collateral, 
        uint borrowAmount
    ) external virtual;

    function exitAllowed(
        address user, 
        address collateral, 
        uint withdrawAmount, 
        uint repayAmount
    ) external virtual returns (uint);
    function exitVerify(
        address user, 
        address collateral, 
        uint withdrawAmount, 
        uint repayAmount
    ) external virtual;

    function repayAllowed(
        address user, 
        address collateral, 
        uint repayAmount
    ) external virtual returns (uint);
    function repayVerify(
        address user, 
        address collateral, 
        uint repayAmount
    ) external virtual;

    function withdrawAllowed(
        address user, 
        address collateral, 
        uint withdrawAmount
    ) external virtual returns (uint);
    function withdrawVerify(
        address user, 
        address collateral, 
        uint withdrawAmount
    ) external virtual;

    function triggerLiquidationAllowed(
        address caller, 
        address borrower, 
        address collateral
    ) external virtual returns (uint);
    function triggerLiquidationVerify(
        address caller, 
        address borrower, 
        address collateral
    ) external virtual;

    function liquidateBorrowAllowed(
        address liquidator, 
        address borrower, 
        address collateral
    ) external virtual returns (uint);
    function liquidateBorrowVerify(
        address liquidator, 
        address borrower, 
        address collateral
    ) external virtual;

    function stabilizerMintAllowed(
        address user, 
        address underlying, 
        uint amount
    ) external virtual returns (uint);
    function stabilizerMintVerify(
        address user, 
        address underlying, 
        uint amount
    ) external virtual;

    function stabilizerRedeemAllowed(
        address user, 
        address underlying, 
        uint amount
    ) external virtual returns (uint);
    function stabilizerRedeemVerify(
        address user, 
        address underlying, 
        uint amount
    ) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Error reporter for internal Creditum functions
 * @author Creditum
 */
contract ErrorReporter {
    enum Error {
        NO_ERROR,
        PAUSED,
        COLLATERAL_NOT_ALLOWED,
        INVALID_MAX_DEBT_RATIO,
        INVALID_LIQUIDATION_THRESHOLD,
        INVALID_DEPRECIATION_DURATION,
        INVALID_ORACLE_ADDRESS,
        INVALID_TOKEN_TO_GET_PRICE,
        INVALID_ORACLE_CALL,
        INVALID_ORACLE_PRICE,
        USELESS_TX,
        EXCEEDS_MINT_LIMIT,
        POSITION_IS_UNHEALTHY,
        POSITION_NOT_LIQUIDATABLE,
        PENDING_LIQUIDATION,
        LIQUIDATION_NOT_TRIGGERED,
        LIQUIDATOR_IS_BORROWER,
        UNDERLYING_NOT_ALLOWED,
        INSUFFICIENT_UNDERLYING_BALANCE
    }

    event Failure(uint error);

    function fail(Error err) internal returns (uint) {
        emit Failure(uint(err));

        return uint(err);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ControllerStorage.sol";

contract Unitroller is UnitrollerAdminStorage {
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice Delegate call to Controller implementation
    /// @notice calldata cannot be empty
    fallback() external payable {
        _delegate();
    }

    /// @notice Revert if calldata is empty
    receive() external payable {
        revert();
    }

    function _delegate() internal {
        (bool success, ) = controllerImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function _setPendingImplementation(address newPendingImplementation) external onlyOwner {
        address oldPendingImplementation = pendingControllerImplementation;

        pendingControllerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);
    }

    function _acceptImplementation() external {
        require(pendingControllerImplementation != address(0), "Controller: no pending implementation");
        require(_msgSender() == pendingControllerImplementation, "Controller: !pending implementation");

        address oldImplementation = controllerImplementation;
        address oldPendingImplementation = pendingControllerImplementation;

        controllerImplementation = pendingControllerImplementation;
        pendingControllerImplementation = address(0);

        emit NewImplementation(oldImplementation, controllerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IOracle {
    function IS_ORACLE() external view returns (bool);
    function getPriceUSD(address token) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./CoreAbstract.sol";
import "./ErrorReporter.sol";
import "./ERC20/SafeERC20.sol";
import "./ERC20/IERC20.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Context.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";

/**
 * @title Core internal Creditum functions to perform user actions
 * @author Creditum
 */
contract Core is CoreAbstract, ErrorReporter, ReentrancyGuard, Context, Initializable, Ownable {
    using SafeERC20 for IERC20;

    uint public constant MULTIPLIER = 10**18;

    /// @notice Sender supplies collateral and can mint fToken
    /// @dev Cannot enter if collateral position is pending liquidation 
    /// @param collateral The collateral market to enter
    /// @param depositAmount The amount of collateral to deposit
    /// @param borrowAmount The amount of fToken to borrow
    /// @return (error code, amount of collateral deposited, amount of fToken borrowed)
    function enterInternal(
        address collateral, 
        uint depositAmount, 
        uint borrowAmount
    ) internal nonReentrant returns (uint, uint, uint) {
        // Ensure protocol isn't paused
        bool paused = controller.paused();
        if (paused) {
            return (fail(Error.PAUSED), 0, 0);
        }

        // Ensure transaction params are valid
        if (depositAmount == 0 && borrowAmount == 0) {
            return (fail(Error.USELESS_TX), 0, 0);
        }

        return enterFresh(_msgSender(), collateral, depositAmount, borrowAmount);
    }

    /// @notice User supplies collateral and can mint fToken
    /// @dev Cannot enter if collateral position is pending liquidation 
    /// @param user The address of the user
    /// @param collateral The collateral market to enter
    /// @param depositAmount The amount of collateral to deposit
    /// @param borrowAmount The amount of fToken to borrow
    /// @return (error code, amount of collateral deposited, amount of fToken borrowed)
    function enterFresh(
        address user,
        address collateral, 
        uint depositAmount, 
        uint borrowAmount
    ) internal returns (uint, uint, uint) {
        // Ensure user is allowed to enter market
        uint enterAllowed = controller.enterAllowed(user, collateral, depositAmount, borrowAmount);
        if (enterAllowed != uint(Error.NO_ERROR)) {
            return (fail(Error(enterAllowed)), 0, 0);
        }

        uint depositAllowed;
        uint amountDeposited;
        uint borrowAllowed;
        uint amountBorrowed;

        if (depositAmount > 0) {
            // Deposit collateral
            (depositAllowed, amountDeposited) = depositFresh(user, collateral, depositAmount);
        }

        if (borrowAmount > 0) {
            // Borrow fToken
            (borrowAllowed, amountBorrowed) = borrowFresh(user, collateral, borrowAmount);
        }

        if (depositAmount == 0 || borrowAmount == 0) {
            // Can safely return if either depositing or borrowing (not both)
            if (depositAllowed != uint(Error.NO_ERROR)) {
                return (fail(Error(depositAllowed)), 0, 0);
            }

            if (borrowAllowed != uint(Error.NO_ERROR)) {
                return (fail(Error(borrowAllowed)), 0, 0);
            }
        } else {
            // Already passed point of no return if depositing and borrowing
            require(depositAllowed == uint(Error.NO_ERROR), "Creditum: depositFresh failed");
            require(borrowAllowed == uint(Error.NO_ERROR), "Creditum: borrowFresh failed");
        }

        emit Enter(user, collateral, depositAmount, borrowAmount);

        // Perform safety checks post-enter
        // controller.enterVerify(user, collateral, depositAmount, borrowAmount);

        return (uint(Error.NO_ERROR), amountDeposited, amountBorrowed);
    }

    /// @notice Deposits collateral from user
    /// @notice Supports fee-on-transfer tokens
    /// @param user The address of the user
    /// @param collateral The user's collateral
    /// @param depositAmount The amount of collateral to deposit
    /// @return (error code, amount of collateral deposited)
    function depositFresh(address user, address collateral, uint depositAmount) internal returns (uint, uint) {
        // Ensure user is allowed to deposit
        uint depositAllowed = controller.depositAllowed(user, collateral, depositAmount);
        if (depositAllowed != uint(Error.NO_ERROR)) {
            return (fail(Error(depositAllowed)), 0);
        }

        // Transfer collateral from user
        uint balanceBefore = IERC20(collateral).balanceOf(address(this));
        IERC20(collateral).safeTransferFrom(user, address(this), depositAmount);
        uint amountReceived = IERC20(collateral).balanceOf(address(this)) - balanceBefore;

        // Increment user's deposits by deposit amount
        userData[collateral][user].deposits += amountReceived;

        emit Deposit(user, collateral, amountReceived);

        // Perform safety checks post-deposit
        // controller.depositVerify(user, collateral, depositAmount);

        return (uint(Error.NO_ERROR), amountReceived);
    }

    /// @notice Borrows fToken to user
    /// @param user The address of the user
    /// @param collateral The user's collateral
    /// @param borrowAmount The amount of fToken to borrow
    /// @return (error code, amount of fToken borrowed)
    function borrowFresh(address user, address collateral, uint borrowAmount) internal returns (uint, uint) {
        // Ensure user is allowed to borrow
        uint borrowAllowed = controller.borrowAllowed(user, collateral, borrowAmount);
        if (borrowAllowed != uint(Error.NO_ERROR)) {
            return (fail(Error(borrowAllowed)), 0);
        }

        ///////////////////////////
        /** NO MORE SAFE RETURNS */
        ///////////////////////////

        // Update storage
        update(user, collateral);

        // Increment user's debt and total collateral minted amount by mint amount
        userData[collateral][user].debt += borrowAmount;
        totalMinted[collateral] += borrowAmount;

        (uint error, , , , uint shortfall, uint healthFactor) = controller.getPositionData(user, collateral);
        require(error == uint(Error.NO_ERROR), "Creditum: failed to verify health factor");
        require(shortfall == 0 && healthFactor >= MULTIPLIER, "Creditum: !healthy");

        // Mint amount to user (and treasury)
        (, , uint mintFee, , , , , ) = controller.collateralData(collateral);
        if (mintFee > 0) {
            uint amountToTreasury = borrowAmount * mintFee / MULTIPLIER;
            borrowAmount -= amountToTreasury;
            fToken.mint(controller.treasury(), amountToTreasury);
        }
        fToken.mint(user, borrowAmount);

        emit Borrow(user, collateral, borrowAmount);

        // Perform safety checks post-borrow
        // controller.borrowVerify(user, collateral, borrowAmount);

        return (uint(Error.NO_ERROR), borrowAmount);
    }

    /// @notice Sender repays fToken debt and can withdraw collateral
    /// @dev Cannot exit if collateral position is pending liquidation
    /// @param collateral The collateral market to enter
    /// @param withdrawAmount The amount of collateral to withdraw
    /// @param repayAmount The amount of fToken to repay
    /// @return (error code, amount of collateral withdrawn, amount of fToken repaid)
    function exitInternal(
        address collateral, 
        uint withdrawAmount, 
        uint repayAmount
    ) internal nonReentrant returns (uint, uint, uint) {
        // Ensure protocol isn't paused
        bool paused = controller.paused();
        if (paused) {
            return (fail(Error.PAUSED), 0, 0);
        }

        // Ensure transaction params are valid
        if (withdrawAmount == 0 && repayAmount == 0) {
            return (fail(Error.USELESS_TX), 0, 0);
        }

        return exitFresh(_msgSender(), collateral, withdrawAmount, repayAmount);
    }

    /// @notice User repays fToken debt and can withdraw collateral
    /// @dev Cannot exit if collateral position is pending liquidation
    /// @dev Users can repay (and withdraw) even if oracle fails (must repay all debt)
    /// @param user The address of the user
    /// @param collateral The collateral market to enter
    /// @param withdrawAmount The amount of collateral to withdraw
    /// @param repayAmount The amount of fToken to repay
    /// @return (error code, amount of collateral withdrawn, amount of fToken repaid)
    function exitFresh(
        address user,
        address collateral, 
        uint withdrawAmount, 
        uint repayAmount
    ) internal returns (uint, uint, uint) {
        // Ensure user is allowed to exit
        uint exitAllowed = controller.exitAllowed(user, collateral, withdrawAmount, repayAmount);
        if (exitAllowed != uint(Error.NO_ERROR)) {
            return (fail(Error(exitAllowed)), 0, 0);
        }

        uint repayAllowed;
        uint amountRepaid;
        uint withdrawAllowed;
        uint amountWithdrawn;

        if (repayAmount > 0) {
            // Repay fToken
            (repayAllowed, amountRepaid) = repayFresh(user, collateral, repayAmount);
        }

        if (withdrawAmount > 0) {
            // Withdraw collateral
            (withdrawAllowed, amountWithdrawn) = withdrawFresh(user, collateral, withdrawAmount);
        }

        if (repayAmount == 0 || withdrawAmount == 0) {
            // Can safely return if either repaying or withdrawing (not both)
            if (repayAllowed != uint(Error.NO_ERROR)) {
                return (fail(Error(repayAllowed)), 0, 0);
            }

            if (withdrawAllowed != uint(Error.NO_ERROR)) {
                return (fail(Error(withdrawAllowed)), 0, 0);
            }
        } else {
            // Already passed point of no return if repaying and borrowing
            require(repayAllowed == uint(Error.NO_ERROR), "Creditum: repayFresh failed");
            require(withdrawAllowed == uint(Error.NO_ERROR), "Creditum: withdrawFresh failed");
        }

        emit Exit(user, collateral, withdrawAmount, repayAmount);

        // Perform safety checks post-exit
        // controller.exitVerify(user, collateral, withdrawAmount, repayAmount);

        return (uint(Error.NO_ERROR), amountWithdrawn, amountRepaid);
    }

    /// @notice Burns fToken from user and sends accrued interest to treasury
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @param repayAmount The amount to repay
    /// @return (error code, amount of fToken repaid)
    function repayFresh(address user, address collateral, uint repayAmount) internal returns (uint, uint) {
        // Ensure user is allowed to repay
        uint repayAllowed = controller.repayAllowed(user, collateral, repayAmount);
        if (repayAllowed != uint(Error.NO_ERROR)) {
            return (fail(Error(repayAllowed)), 0);
        }

        if (userData[collateral][user].debt == 0) {
            return (uint(Error.NO_ERROR), 0);
        }

        uint totalDebt = controller.getDebtValue(user, collateral);

        uint amountToBurn;
        uint fee;
        if (repayAmount >= totalDebt) {
            amountToBurn = userData[collateral][user].debt;
            fee = controller.getFeeCalculation(user, collateral, amountToBurn);
        } else {
            amountToBurn = controller.getPrincipalAmount(user, collateral, repayAmount);
            fee = repayAmount - amountToBurn;
        }

        uint amountRepaid = amountToBurn + fee;

        ///////////////////////////
        /** NO MORE SAFE RETURNS */
        ///////////////////////////

        // Burn principal amount from user
        fToken.burn(user, amountToBurn);

        // Transfer accrued interest from user to treasury
        if (fee > 0) {
            IERC20(fToken).safeTransferFrom(user, controller.treasury(), fee);
        }

        // Decrement user's debt and total minted amount
        userData[collateral][user].debt -= amountToBurn;
        totalMinted[collateral] -= amountToBurn;

        if (userData[collateral][user].debt == 0) {
            delete userData[collateral][user].lastUpdatedAt;
        } else {
            // Update storage
            update(user, collateral);
        }

        emit Repay(user, collateral, repayAmount);

        // Perform safety checks post-repay
        // controller.repayVerify(user, collateral, repayAmount);

        return (uint(Error.NO_ERROR), amountRepaid);
    }

    /// @notice Withdraws collateral to user
    /// @param user The address of the user
    /// @param collateral The collateral
    /// @param withdrawAmount The amount of collateral to withdraw
    /// @return (error code, amount of collateral withdrawn)
    function withdrawFresh(address user, address collateral, uint withdrawAmount) internal returns (uint, uint) {
        // Ensure user is allowed to withdraw
        uint withdrawAllowed = controller.withdrawAllowed(user, collateral, withdrawAmount);
        if (withdrawAllowed != uint(Error.NO_ERROR)) {
            return (fail(Error(withdrawAllowed)), 0);
        }
        
        uint amountToWithdraw;

        uint deposits = userData[collateral][user].deposits;
        if (deposits == 0) {
            return (uint(Error.NO_ERROR), 0);
        } else if (withdrawAmount > deposits) {
            amountToWithdraw = deposits;
        } else {
            amountToWithdraw = withdrawAmount;
        }

        ///////////////////////////
        /** NO MORE SAFE RETURNS */
        ///////////////////////////

        // Decrement user's deposits by withdraw amount 
        userData[collateral][user].deposits -= amountToWithdraw;

        if (userData[collateral][user].debt > 0) {
            // Update storage
            update(user, collateral);
            (uint error, , , , uint shortfall, uint healthFactor) = controller.getPositionData(user, collateral);
            require(error == uint(Error.NO_ERROR), "Creditum: failed to verify health factor");
            require(shortfall == 0 && healthFactor >= MULTIPLIER, "Creditum: !healthy");
        }

        // Transfer collateral to user
        IERC20(collateral).safeTransfer(user, amountToWithdraw);

        emit Withdraw(user, collateral, amountToWithdraw);

        // Perform safety checks post-withdraw
        // controller.withdrawVerify(user, collateral, amountToWithdraw);

        return (uint(Error.NO_ERROR), amountToWithdraw);
    }

    /// @notice Sender mints fToken with underlying token
    /// @dev Mints fToken 1:1 with underlying token (not including fee)
    /// @dev Allows fToken price arbitrage in case peg fails
    /// @param underlying The underlying token to deposit
    /// @param amount The amount of the underlying token to deposit
    /// @return (error code, fToken amount minted)
    function stabilizerMintInternal(address underlying, uint amount) internal nonReentrant returns (uint, uint) {
        // Ensure protocol isn't paused
        bool paused = controller.paused();
        if (paused) {
            return (fail(Error.PAUSED), 0);
        }

        if (amount == 0) {
            return (fail(Error.USELESS_TX), 0);
        }

        return stabilizerMintFresh(_msgSender(), underlying, amount);
    }

    /// @notice User mints fToken with underlying token
    /// @dev Mints fToken 1:1 with underlying token (not including fee)
    /// @dev Allows fToken price arbitrage in case peg fails
    /// @param user The address of the user
    /// @param underlying The underlying token to deposit
    /// @param amount The amount of the underlying token to deposit
    /// @return (error code, fToken amount minted)
    function stabilizerMintFresh(address user, address underlying, uint amount) internal returns (uint, uint) {
        // Ensure user is allowed to mint via stabilizer
        uint allowed = controller.stabilizerMintAllowed(user, underlying, amount);
        if (allowed != uint(Error.NO_ERROR)) {
            return (fail(Error(allowed)), 0);
        }

        ///////////////////////////
        /** NO MORE SAFE RETURNS */
        ///////////////////////////

        // Transfer underlying token from user
        uint balanceBefore = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransferFrom(user, address(this), amount);
        uint amountReceived = IERC20(underlying).balanceOf(address(this)) - balanceBefore;

        stabilizerDeposits[underlying] += amountReceived;

        // Standardize amount to 1e18
        uint standardAmount;
        uint decimals = IERC20(underlying).decimals();
        if (decimals <= 18) {
            standardAmount = amountReceived * 10**(18 - decimals);
        } else {
            standardAmount = amountReceived / 10**(decimals - 18);
        }

        // Calculate mint fee and mint amount
        (, uint stabilizerFee) = controller.stabilizerData(underlying);
        uint fee = standardAmount * stabilizerFee / MULTIPLIER;
        uint mintAmount = standardAmount - fee;

        // Mint amount to user
        fToken.mint(user, mintAmount);

        // Mint fee to treasury
        if (fee > 0) {
            fToken.mint(controller.treasury(), fee);
        }

        emit StabilizerMint(user, underlying, mintAmount);

        // Perform safety checks post-mint
        // controller.stabilizerMintVerify(user, underlying, amount);

        return (uint(Error.NO_ERROR), mintAmount);
    }

    /// @notice Sender redeems underlying token with fToken
    /// @dev Redeems underlying token 1:1 with fToken (not including fee)
    /// @dev Allows fToken price arbitrage in case peg fails
    /// @param underlying The underlying token to redeem
    /// @param amount The amount of fToken to burn
    /// @return (error code, underlying token amount redeemed)
    function stabilizerRedeemInternal(address underlying, uint amount) internal nonReentrant returns (uint, uint) {
        // Ensure protocol isn't paused
        bool paused = controller.paused();
        if (paused) {
            return (fail(Error.PAUSED), 0);
        }

        if (amount == 0) {
            return (fail(Error.USELESS_TX), 0);
        }

        return stabilizerRedeemFresh(_msgSender(), underlying, amount);
    }

    /// @notice User redeems underlying token with fToken
    /// @dev Redeems underlying token 1:1 with fToken (not including fee)
    /// @dev Allows fToken price arbitrage in case peg fails
    /// @param user The address of the user
    /// @param underlying The underlying token to redeem
    /// @param amount The amount of fToken to burn
    /// @return (error code, underlying token amount redeemed)
    function stabilizerRedeemFresh(address user, address underlying, uint amount) internal returns (uint, uint) {
        // Ensure user is allowed to redeem via stabilizer
        uint allowed = controller.stabilizerRedeemAllowed(user, underlying, amount);
        if (allowed != uint(Error.NO_ERROR)) {
            return (fail(Error(allowed)), 0);
        }

        uint fee;
        uint burnAmount;
        uint redeemAmount;
        
        {
        (, uint stabilizerFee) = controller.stabilizerData(underlying);
        fee = amount * stabilizerFee / MULTIPLIER;
        burnAmount = amount - fee;

        uint decimals = IERC20(underlying).decimals();
        if (decimals <= 18) {
            redeemAmount = burnAmount / 10**(18 - decimals);
        } else {
            redeemAmount = burnAmount * 10**(decimals - 18);
        }
        }

        ///////////////////////////
        /** NO MORE SAFE RETURNS */
        ///////////////////////////

        // Burn burn amount from user
        fToken.burn(user, burnAmount);

        // Send fee amount to treasury
        if (fee > 0) {
            IERC20(fToken).safeTransferFrom(user, controller.treasury(), fee);
        }

        // Decrement available swap balance
        stabilizerDeposits[underlying] -= redeemAmount;
        
        // Send underlying token to user
        IERC20(underlying).safeTransfer(user, redeemAmount);

        emit StabilizerRedeem(user, underlying, redeemAmount);

        // Perform safety checks post-redeem
        // controller.stabilizerRedeemVerify(user, underlying, amount);

        return (uint(Error.NO_ERROR), redeemAmount);
    }

        /// @notice Sender enables borrower's collateral to be liquidated
    /// @dev Health factor must be < 1 to trigger liquidation
    /// @dev Once a position is triggered for liquidation, it can not be reverted/saved
    /// @param borrower The borrower to be liquidated
    /// @param collateral The borrower's collateral to liquidate
    /// @return uint 0=success, otherwise a failure
    function triggerLiquidationInternal(address borrower, address collateral) internal nonReentrant returns (uint) {
        // Ensure protocol isn't paused
        bool paused = controller.paused();
        if (paused) {
            return fail(Error.PAUSED);
        }

        return triggerLiquidationFresh(_msgSender(), borrower, collateral);
    }

    /// @notice User enables borrower's collateral to be liquidated
    /// @dev Health factor must be < 1 to trigger liquidation
    /// @dev Once a position is triggered for liquidation, it can not be reverted/saved
    /// @param caller The address that triggered the liquidation
    /// @param borrower The borrower to be liquidated
    /// @param collateral The borrower's collateral to liquidate
    /// @return uint 0=success, otherwise a failure
    function triggerLiquidationFresh(address caller, address borrower, address collateral) internal returns (uint) {
        // Ensure liquidation trigger is allowed
        uint allowed = controller.triggerLiquidationAllowed(caller, borrower, collateral);
        if (allowed != uint(Error.NO_ERROR)) {
            return fail(Error(allowed));
        }

        ///////////////////////////
        /** NO MORE SAFE RETURNS */
        ///////////////////////////

        // Update borrower's total debt
        userData[collateral][borrower].debt = controller.getDebtValue(borrower, collateral);

        // Mark liquidation trigger timestamp for depreciation calculations
        auctionData[collateral][borrower].triggerTimestamp = block.timestamp;

        // Set initial auction price at borrower's collateral value
        (, uint collateralValue) = controller.getCollateralValue(borrower, collateral);
        auctionData[collateral][borrower].initialAuctionPrice = collateralValue;

        emit TriggerLiquidation(caller, borrower, collateral, block.timestamp, collateralValue);

        // Perform safety checks post-trigger
        // controller.triggerLiquidationVerify(caller, borrower, collateral);

        return uint(Error.NO_ERROR);
    }

    /// @notice Sender liquidates borrower's collateral
    /// @dev Can only liquidate a position that has been triggered
    /// @param borrower The borrower to be liquidated
    /// @param collateral The borrower's collateral to liquidate
    /// @return (error code, amount of fToken burned, amount of collateral sender received)
    function liquidateBorrowInternal(address borrower, address collateral) internal nonReentrant returns (uint, uint, uint) {
        // Ensure protocol isn't paused
        bool paused = controller.paused();
        if (paused) {
            return (fail(Error.PAUSED), 0, 0);
        }

        return liquidateBorrowFresh(_msgSender(), borrower, collateral);
    }

    /// @notice Liquidator liquidates borrower's collateral
    /// @dev Can only liquidate a position that has been triggered
    /// @param liquidator The address of the liquidator
    /// @param borrower The borrower to be liquidated
    /// @param collateral The borrower's collateral to liquidate
    /// @return (error code, amount of fToken burned, amount of collateral liquidator received)
    function liquidateBorrowFresh(address liquidator, address borrower, address collateral) internal returns (uint, uint, uint) {
        // Ensure liquidation is allowed
        uint allowed = controller.liquidateBorrowAllowed(liquidator, borrower, collateral);
        if (allowed != uint(Error.NO_ERROR)) {
            return (fail(Error(allowed)), 0, 0);
        }

        uint collateralToLiquidator;
        uint collateralToOwner;
        uint auctionPrice;
        uint collateralToTreasury;
        uint penalty;

        {
        // Calculate collateral to reward liquidator, collateral to return to owner, and auction price
        (collateralToLiquidator, collateralToOwner, auctionPrice) = controller.getAuctionDetails(borrower, collateral);

        // Calculate dust collateral to send to treasury
        uint totalCollateral = userData[collateral][borrower].deposits;
        collateralToTreasury = totalCollateral - collateralToLiquidator - collateralToOwner;

        // Calculate liquidation penalty
        uint debt = controller.getDebtValue(borrower, collateral);
        (, , , , , , uint liquidationPenalty, ) = controller.collateralData(collateral);
        penalty = debt * liquidationPenalty / MULTIPLIER;
        }

        address treasury = controller.treasury();

        ///////////////////////////
        /** NO MORE SAFE RETURNS */
        ///////////////////////////

        // Delete storage slots before performing transfers
        delete auctionData[collateral][borrower];
        delete userData[collateral][borrower];

        if (auctionPrice > penalty) {
            // Since auction price > liquidation penalty, transfer liquidation penalty to treasury
            if (penalty > 0) {
                IERC20(fToken).safeTransferFrom(liquidator, treasury, penalty);
            }

            // Burn remaining auction proceeds from liquidator
            fToken.burn(liquidator, auctionPrice - penalty);
        } else {
            // Since auction price <= liquidation penalty, transfer entire repayment to treasury directly from liquidator
            if (auctionPrice > 0) {
                IERC20(fToken).safeTransferFrom(liquidator, treasury, auctionPrice);
            }
        }

        // Send rewarded collateral to liquidator
        if (collateralToLiquidator > 0) {
            IERC20(collateral).safeTransfer(liquidator, collateralToLiquidator);
        }
        
        // Return excess collateral to owner
        if (collateralToOwner > 0) {
            IERC20(collateral).safeTransfer(borrower, collateralToOwner);
        }

        // Send dust collateral to treasury
        if (collateralToTreasury > 0) {
            IERC20(collateral).safeTransfer(treasury, collateralToTreasury);
        }

        emit LiquidateBorrow(liquidator, borrower, collateral, auctionPrice);

        // Perform safety checks post-liquidation
        // controller.liquidateBorrowVerify(liquidator, borrower, collateral);

        return (uint(Error.NO_ERROR), auctionPrice, collateralToLiquidator);
    }

    /// @notice Updates user's debt and total collateral minted amount
    /// @dev Last update time is used to calculate accrued interest in `getFeeCalculation`
    /// @param user The address of the user
    /// @param collateral The collateral
    function update(address user, address collateral) internal {
        // Temporarily store user's total debt
        uint totalDebt = controller.getDebtValue(user, collateral);

        // Increment total collateral minted amount by accrued interest
        totalMinted[collateral] += totalDebt - userData[collateral][user].debt;

        // Update user's total debt
        userData[collateral][user].debt = totalDebt;

        // Update last updated at timestamp
        userData[collateral][user].lastUpdatedAt = block.timestamp;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /// @notice Initialize parameters & deploy fToken contract
    /// @param _name The name of the fToken
    /// @param _symbol The symbol of the fToken
    function _initialize(
        string memory _name, 
        string memory _symbol, 
        Controller _controller
    ) external override initializer onlyOwner {
        // Ensure not initialized already
        require(address(fToken) == address(0), "Creditum: already initialized");

        // Ensure name and symbol not null
        bytes memory nameBytes = bytes(_name);
        bytes memory symbolBytes = bytes(_symbol);
        
        require(nameBytes.length > 0, "Creditum: !name");
        require(symbolBytes.length > 0, "Creditum: !symbol");
        require(_controller.IS_CONTROLLER(), "Creditum: !valid controller contract");
        controller = _controller;
        
        fToken = new FToken(_name, _symbol);
        fToken.transferOwnership(_msgSender());
    }

    function _setController(Controller _controller) external override onlyOwner {
        require(_controller.IS_CONTROLLER(), "Creditum: !valid controller contract");
        controller = _controller;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Controller.sol";
import "./FToken.sol";

contract CoreStorage {
    struct UserData {
        uint deposits;              // Amount of collateral deposited
        uint debt;                  // Last updated outstanding debt
        uint lastUpdatedAt;         // Last updated timestamp
    }

    struct AuctionData {
        uint triggerTimestamp;      // Timestamp liquidation was triggered
        uint initialAuctionPrice;   // Initial liquidation auction price
    }

    FToken public fToken;
    Controller public controller;

    // Collateral -> User -> User Data
    mapping(address => mapping(address => UserData)) public userData;
    
    // Collateral -> User -> Auction Data
    mapping(address => mapping(address => AuctionData)) public auctionData;

    // Collateral -> fToken amount minted
    mapping(address => uint) public totalMinted;

    // Underlying token -> amount deposited in stabilizer
    mapping(address => uint) public stabilizerDeposits;
}

abstract contract CoreAbstract is CoreStorage {
    bool public constant IS_CORE = true;
    
    /* ========== MARKET EVENTS ========== */

    event Enter(address indexed user, address indexed collateral, uint depositAmount, uint mintAmount);
    event Exit(address indexed user, address indexed collateral, uint withdrawAmount, uint repayAmount);
    event Deposit(address indexed user, address indexed collateral, uint amount);
    event Borrow(address indexed user, address indexed collateral, uint amount);
    event Repay(address indexed user, address indexed collateral, uint amount);
    event Withdraw(address indexed user, address indexed collateral, uint amount);
    event StabilizerMint(address indexed user, address indexed underlying, uint amount);
    event StabilizerRedeem(address indexed user, address indexed underlying, uint amount);
    
    event TriggerLiquidation(address indexed caller, address indexed borrower, address indexed collateral, uint startTimestamp, uint initialPrice);
    event LiquidateBorrow(address indexed liquidator, address indexed borrower, address indexed collateral, uint debt);

    /* ========== ADMIN FUNCTIONS ========== */

    function _initialize(string memory _name, string memory _symbol, Controller _controller) external virtual;
    function _setController(Controller newController) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
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
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.3.2 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20/ERC20FlashMint.sol";
import "./utils/Ownable.sol";

/**
 * @title Overcollateralized debt token minted by Creditum
 * @author Creditum
 */
contract FToken is ERC20FlashMint, Ownable {
    bool public constant IS_FTOKEN = true;
    
    // Allows multiple Creditum contracts to mint/burn
    mapping(address => bool) public creditum;

    modifier onlyCreditum() {
        require(creditum[_msgSender()], "!creditum");
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        creditum[_msgSender()] = true;
    }

    function mint(address account, uint256 amount) external onlyCreditum returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) external onlyCreditum returns (bool) {
        _burn(account, amount);
        return true;
    }

    /// @notice Universal admin allowed to add/remove Creditum contracts
    function setCreditum(address _creditum, bool _allowed) external onlyOwner {
        creditum[_creditum] = _allowed;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/extensions/ERC20FlashMint.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";
import "./ERC20.sol";

/**
 * @dev Implementation of the ERC3156 Flash loans extension, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * Adds the {flashLoan} method, which provides flash loan support at the token
 * level. By default there is no fee, but this can be changed by overriding {flashFee}.
 *
 * _Available since v4.1._
 */
abstract contract ERC20FlashMint is ERC20, IERC3156FlashLender {
    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return The amont of token that can be loaned.
     */
    function maxFlashLoan(address token) public view override returns (uint256) {
        return token == address(this) ? type(uint256).max - ERC20.totalSupply() : 0;
    }

    /**
     * @dev Returns the fee applied when doing flash loans. By default this
     * implementation has 0 fees. This function can be overloaded to make
     * the flash loan mechanism deflationary.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function flashFee(address token, uint256 amount) public view virtual override returns (uint256) {
        require(token == address(this), "ERC20FlashMint: wrong token");
        amount;
        return 0;
    }

    /**
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower.onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` is the flash loan was successful.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bool) {
        uint256 fee = flashFee(token, amount);
        _mint(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
            "ERC20FlashMint: invalid return value"
        );
        uint256 currentAllowance = allowance(address(receiver), address(this));
        require(currentAllowance >= amount + fee, "ERC20FlashMint: allowance does not allow refund");
        _approve(address(receiver), address(this), currentAllowance - amount - fee);
        _burn(address(receiver), amount + fee);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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