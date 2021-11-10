// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IWrappedNativeCurrency.sol";
import "./libraries/AmountNormalization.sol";
import "./libraries/CollateralToken.sol";
import "./libraries/EnumerableAddressSet.sol";
import "./libraries/FixedPointMath.sol";
import "./libraries/Loan.sol";
import "./libraries/Math.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/SafeERC20.sol";
import {Governed} from "./Governance.sol";
import {ICore} from "./Core.sol";
import {IERC20, IMintableAndBurnableERC20} from "./interfaces/ERC20.sol";
import {Initializable} from "./libraries/Upgradability.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";

/// @dev Thrown when trying to list collateral token that has zero decimals.
/// @param token The address of the collateral token contract.
error BaksDAOCollateralTokenZeroDecimals(IERC20 token);

/// @dev Thrown when trying to list collateral token that has too large decimals.
/// @param token The address of the collateral token contract.
error BaksDAOCollateralTokenTooLargeDecimals(IERC20 token, uint8 decimals);

/// @dev Thrown when trying to list collateral token that's already listed.
/// @param token The address of the collateral token contract.
error BaksDAOCollateralTokenAlreadyListed(IERC20 token);

/// @dev Thrown when trying to unlist collateral token that's not listed.
/// @param token The address of the collateral token contract.
error BaksDAOCollateralTokenNotListed(IERC20 token);

/// @dev Thrown when interacting with a token that's not allowed as collateral.
/// @param token The address of the collateral token contract.
error BaksDAOTokenNotAllowedAsCollateral(IERC20 token);

/// @dev Thrown when trying to set initial loan-to-value ratio that higher than margin call or liquidation ones.
/// @param token The address of the collateral token contract.
/// @param initialLoanToValueRatio The initial loan-to-value ratio that was tried to set.
error BaksDAOInitialLoanToValueRatioTooHigh(IERC20 token, uint256 initialLoanToValueRatio);

/// @dev Thrown when trying to interact with inactive loan with `id` id.
/// @param id The loan id.
error BaksDAOInactiveLoan(uint256 id);

/// @dev Thrown when trying to liquidate healthy loan with `id` id.
/// @param id The loan id.
error BaksDAOLoanNotSubjectToLiquidation(uint256 id);
/// @dev Thrown when trying to interact with loan with `id` id that is subject to liquidation.
/// @param id The loan id.
error BaksDAOLoanIsSubjectToLiquidation(uint256 id);

/// @dev Thrown when borrowing a zero amount of stablecoin.
error BaksDAOBorrowZeroAmount();

/// @dev Thrown when trying to borrow below minimum principal amount.
error BaksDAOBorrowBelowMinimumPrincipalAmount();

/// @dev Thrown when depositing a zero amount of collateral token.
error BaksDAODepositZeroAmount();

/// @dev Thrown when repaying a zero amount of stablecoin.
error BaksDAORepayZeroAmount();

/// @dev Thrown when there's no need to rebalance the platform.
error BaksDAONoNeedToRebalance();

/// @dev Thrown when trying to rebalance the platform and there is a shortage of funds to burn.
/// @param shortage Shoratge of funds to burn.
error BaksDAOStabilizationFundOutOfFunds(uint256 shortage);

/// @dev Thrown when trying to salvage one of allowed collateral tokens or stablecoin.
/// @param token The address of the token contract.
error BaksDAOTokenNotAllowedToBeSalvaged(IERC20 token);

/// @dev Thrown when trying to deposit native currency collateral to the non-wrapped native currency token loan
/// with `id` id.
/// @param id The loan id.
error BaksDAONativeCurrencyCollateralNotAllowed(uint256 id);

error BaksDAONativeCurrencyTransferFailed();

error BaksDAOPlainNativeCurrencyTransferNotAllowed();

error BaksDAOInsufficientSecurityAmount(uint256 minimumRequiredSecurityAmount);

error BaksDAOOnlyMagisterAllowed();
error BaksDAOMagisterAlreadyAdded(address magister);
error BaksDAOMagisterDontAdded(address magister);

/// @title Core smart contract of BaksDAO platform
/// @author Andrey Gulitsky
/// @notice You should use this contract to interact with the BaksDAO platform.
/// @notice Only this contract can issue stablecoins.
contract Bank is Initializable, Governed, ReentrancyGuard {
    using AmountNormalization for IERC20;
    using AmountNormalization for IWrappedNativeCurrency;
    using CollateralToken for CollateralToken.Data;
    using EnumerableAddressSet for EnumerableAddressSet.Set;
    using FixedPointMath for uint256;
    using Loan for Loan.Data;
    using SafeERC20 for IWrappedNativeCurrency;
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableAndBurnableERC20;

    enum Health {
        Ok,
        MarginCall,
        Liquidation
    }

    uint256 internal constant ONE = 100e16;
    uint8 internal constant DECIMALS = 18;

    IWrappedNativeCurrency public wrappedNativeCurrency;
    ICore public core;
    IMintableAndBurnableERC20 public stablecoin;
    IPriceOracle public priceOracle;

    address public operator;
    address public liquidator;
    address public exchangeFund;
    address public developmentFund;

    Loan.Data[] public loans;
    mapping(address => uint256[]) public loanIds;

    mapping(IERC20 => CollateralToken.Data) public collateralTokens;
    EnumerableAddressSet.Set internal collateralTokensSet;

    mapping(address => bool) internal magisters;

    event CollateralTokenListed(IERC20 indexed token);
    event CollateralTokenUnlisted(IERC20 indexed token);

    event InitialLoanToValueRatioUpdated(
        IERC20 indexed token,
        uint256 initialLoanToValueRatio,
        uint256 newInitialLoanToValueRatio
    );

    event Borrow(
        uint256 indexed id,
        address indexed borrower,
        IERC20 indexed token,
        uint256 principalAmount,
        uint256 collateralAmount,
        uint256 initialLoanToValueRatio
    );
    event Deposit(uint256 indexed id, uint256 collateralAmount);
    event Repay(uint256 indexed id, uint256 principalAmount);
    event Repaid(uint256 indexed id);

    event Liquidated(uint256 indexed id);

    event Rebalance(int256 delta);

    event MagisterAdded(address indexed magister);
    event MagisterRemoved(address indexed magister);

    modifier tokenAllowedAsCollateral(IERC20 token) {
        if (!collateralTokensSet.contains(address(token))) {
            revert BaksDAOTokenNotAllowedAsCollateral(token);
        }
        _;
    }

    modifier onActiveLoan(uint256 id) {
        if (id >= loans.length || !loans[id].isActive) {
            revert BaksDAOInactiveLoan(id);
        }
        _;
    }

    modifier notOnSubjectToLiquidation(uint256 loanId) {
        if (checkHealth(loanId) == Health.Liquidation) {
            revert BaksDAOLoanIsSubjectToLiquidation(loanId);
        }
        _;
    }

    modifier onSubjectToLiquidation(uint256 loanId) {
        if (checkHealth(loanId) != Health.Liquidation) {
            revert BaksDAOLoanNotSubjectToLiquidation(loanId);
        }
        _;
    }

    modifier onlyMagister() {
        if (!magisters[msg.sender]) {
            revert BaksDAOOnlyMagisterAllowed();
        }
        _;
    }

    receive() external payable {
        if (msg.sender != address(wrappedNativeCurrency)) {
            revert BaksDAOPlainNativeCurrencyTransferNotAllowed();
        }
    }

    function initialize(
        IWrappedNativeCurrency _wrappedNativeCurrency,
        ICore _core,
        IMintableAndBurnableERC20 _stablecoin,
        IPriceOracle _priceOracle,
        address _operator,
        address _liquidator,
        address _exchangeFund,
        address _developmentFund
    ) external initializer {
        setGovernor(msg.sender);

        wrappedNativeCurrency = _wrappedNativeCurrency;
        core = _core;
        stablecoin = _stablecoin;
        priceOracle = _priceOracle;
        operator = _operator;
        liquidator = _liquidator;
        exchangeFund = _exchangeFund;
        developmentFund = _developmentFund;
    }

    /// @notice Increases loan's principal on `collateralToken` collateral token and mints `amount` of stablecoin.
    /// @dev The caller must have allowed this contract to spend a sufficient amount of collateral tokens to cover
    /// initial loan-to-value ratio.
    /// @param collateralToken The address of the collateral token contract.
    /// @param amount The amount of stablecoin to borrow and issue.
    function borrow(IERC20 collateralToken, uint256 amount)
        external
        nonReentrant
        tokenAllowedAsCollateral(collateralToken)
        returns (Loan.Data memory)
    {
        Loan.Data memory loan = calculateLoanByPrincipalAmount(collateralToken, amount);

        collateralToken.safeTransferFrom(msg.sender, operator, collateralToken.denormalizeAmount(loan.stabilityFee));
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            collateralToken.denormalizeAmount(loan.collateralAmount)
        );

        return _createLoan(loan);
    }

    /// @notice Increases loan's principal on wrapped native currency token and mints stablecoin.
    function borrowInNativeCurrency(uint256 amount) external payable nonReentrant returns (Loan.Data memory) {
        Loan.Data memory loan = calculateLoanByPrincipalAmount(wrappedNativeCurrency, amount);
        loan.isNativeCurrency = true;

        uint256 securityAmount = loan.collateralAmount + loan.stabilityFee;
        if (msg.value < securityAmount) {
            revert BaksDAOInsufficientSecurityAmount(securityAmount);
        }

        wrappedNativeCurrency.deposit{value: securityAmount}();
        wrappedNativeCurrency.safeTransfer(operator, wrappedNativeCurrency.denormalizeAmount(loan.stabilityFee));

        uint256 change;
        unchecked {
            change = msg.value - securityAmount;
        }
        if (change > 0) {
            (bool success, ) = msg.sender.call{value: change}("");
            if (!success) {
                revert BaksDAONativeCurrencyTransferFailed();
            }
        }

        return _createLoan(loan);
    }

    /// @notice Deposits `amount` of collateral token to loan with `id` id.
    /// @dev The caller must have allowed this contract to spend `amount` of collateral tokens.
    /// @param loanId The loan id.
    /// @param amount The amount of collateral token to deposit.
    function deposit(uint256 loanId, uint256 amount)
        external
        nonReentrant
        onActiveLoan(loanId)
        notOnSubjectToLiquidation(loanId)
    {
        loans[loanId].collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        _deposit(loanId, amount);
    }

    /// @notice Deposits wrapped native currency token to loan with `id` id.
    function depositInNativeCurrency(uint256 loanId)
        external
        payable
        nonReentrant
        onActiveLoan(loanId)
        notOnSubjectToLiquidation(loanId)
    {
        if (loans[loanId].collateralToken != wrappedNativeCurrency) {
            revert BaksDAONativeCurrencyCollateralNotAllowed(loanId);
        }
        wrappedNativeCurrency.deposit{value: msg.value}();
        _deposit(loanId, msg.value);
    }

    /// @notice Decreases principal of loan with `id` id by `amount` of stablecoin.
    /// @param loanId The loan id.
    /// @param amount The amount of stablecoin to repay.
    function repay(uint256 loanId, uint256 amount)
        external
        nonReentrant
        onActiveLoan(loanId)
        notOnSubjectToLiquidation(loanId)
    {
        if (amount == 0) {
            revert BaksDAORepayZeroAmount();
        }
        Loan.Data storage loan = loans[loanId];
        loan.principalAmount -= amount;

        stablecoin.burn(msg.sender, amount);
        loan.lastRepaymentAt = block.timestamp;
        if (loan.principalAmount > 0) {
            emit Repay(loanId, amount);
        } else {
            uint256 denormalizedCollateralAmount = loan.collateralToken.denormalizeAmount(loan.collateralAmount);
            collateralTokens[loan.collateralToken].collateralAmount -= loan.collateralAmount;

            loan.collateralAmount = 0;

            stablecoin.burn(address(this), loan.stabilizationFee);

            loan.isActive = false;
            emit Repaid(loanId);

            if (!loan.isNativeCurrency) {
                loan.collateralToken.safeTransfer(loan.borrower, denormalizedCollateralAmount);
            } else {
                wrappedNativeCurrency.withdraw(denormalizedCollateralAmount);
                (bool success, ) = msg.sender.call{value: denormalizedCollateralAmount}("");
                if (!success) {
                    revert BaksDAONativeCurrencyTransferFailed();
                }
            }
        }
    }

    function liquidate(uint256 loanId) external nonReentrant onActiveLoan(loanId) onSubjectToLiquidation(loanId) {
        Loan.Data storage loan = loans[loanId];

        collateralTokens[loan.collateralToken].collateralAmount -= loan.collateralAmount;
        loan.collateralToken.safeTransfer(liquidator, loan.collateralToken.denormalizeAmount(loan.collateralAmount));

        uint256 collateralValue = loan.getCollateralValue();
        stablecoin.burn(liquidator, loan.principalAmount);
        stablecoin.burn(address(this), collateralValue - loan.principalAmount);

        loan.isActive = false;
        emit Liquidated(loanId);
    }

    function rebalance() external nonReentrant {
        uint256 totalValueLocked = getTotalValueLocked();
        uint256 totalSupply = stablecoin.totalSupply();

        int256 delta = int256(totalSupply) - int256(totalValueLocked);
        uint256 absoluteDelta = Math.abs(delta);
        uint256 p = absoluteDelta.div(totalSupply);
        if (p < core.rebalancingThreshold()) {
            revert BaksDAONoNeedToRebalance();
        }

        if (delta > 0) {
            try stablecoin.burn(address(this), absoluteDelta) {} catch {
                uint256 balance = stablecoin.balanceOf(address(this));
                revert BaksDAOStabilizationFundOutOfFunds(absoluteDelta - balance);
            }
        } else {
            stablecoin.mint(address(this), absoluteDelta);
        }

        emit Rebalance(delta);
    }

    function listCollateralToken(IERC20 token, uint256 initialLoanToValueRatio) external onlyGovernor {
        if (collateralTokensSet.contains(address(token))) {
            revert BaksDAOCollateralTokenAlreadyListed(token);
        }

        if (initialLoanToValueRatio >= core.marginCallLoanToValueRatio()) {
            revert BaksDAOInitialLoanToValueRatioTooHigh(token, initialLoanToValueRatio);
        }

        uint8 decimals = token.decimals();
        if (decimals == 0) {
            revert BaksDAOCollateralTokenZeroDecimals(token);
        }
        if (decimals > DECIMALS) {
            revert BaksDAOCollateralTokenTooLargeDecimals(token, decimals);
        }

        if (collateralTokensSet.add(address(token))) {
            collateralTokens[token] = CollateralToken.Data({
                collateralToken: token,
                priceOracle: priceOracle,
                stabilityFee: core.stabilityFee(),
                stabilizationFee: core.stabilizationFee(),
                exchangeFee: core.exchangeFee(),
                developmentFee: core.developmentFee(),
                initialLoanToValueRatio: initialLoanToValueRatio,
                marginCallLoanToValueRatio: core.marginCallLoanToValueRatio(),
                liquidationLoanToValueRatio: core.liquidationLoanToValueRatio(),
                collateralAmount: 0
            });

            emit CollateralTokenListed(token);
            emit InitialLoanToValueRatioUpdated(token, 0, initialLoanToValueRatio);
        }
    }

    function unlistCollateralToken(IERC20 token) external onlyGovernor {
        if (!collateralTokensSet.contains(address(token))) {
            revert BaksDAOCollateralTokenNotListed(token);
        }

        if (collateralTokensSet.remove(address(token))) {
            delete collateralTokens[token];
            emit CollateralTokenUnlisted(token);
        }
    }

    function addMagister(address magister) external onlyGovernor {
        if (magisters[magister]) {
            revert BaksDAOMagisterAlreadyAdded(magister);
        }
        emit MagisterAdded(magister);
    }

    function removeMagister(address magister) external onlyGovernor {
        if (!magisters[magister]) {
            revert BaksDAOMagisterDontAdded(magister);
        }
        emit MagisterRemoved(magister);
    }

    function setInitialLoanToValueRatio(IERC20 token, uint256 newInitialLoanToValueRatio) external onlyGovernor {
        if (!collateralTokensSet.contains(address(token))) {
            revert BaksDAOCollateralTokenNotListed(token);
        }

        CollateralToken.Data storage collateralToken = collateralTokens[token];
        if (newInitialLoanToValueRatio >= collateralToken.marginCallLoanToValueRatio) {
            revert BaksDAOInitialLoanToValueRatioTooHigh(token, newInitialLoanToValueRatio);
        }

        uint256 initialLoanToValueRatio = collateralToken.initialLoanToValueRatio;
        collateralToken.initialLoanToValueRatio = newInitialLoanToValueRatio;

        emit InitialLoanToValueRatioUpdated(token, initialLoanToValueRatio, newInitialLoanToValueRatio);
    }

    function salvage(IERC20 token) external onlyGovernor {
        address tokenAddress = address(token);
        if (tokenAddress == address(stablecoin) || collateralTokensSet.contains(tokenAddress)) {
            revert BaksDAOTokenNotAllowedToBeSalvaged(token);
        }
        token.safeTransfer(operator, token.balanceOf(address(this)));
    }

    function getLoans(address borrower) external view returns (Loan.Data[] memory _loans) {
        uint256 length = loanIds[borrower].length;
        _loans = new Loan.Data[](length);

        for (uint256 i = 0; i < length; i++) {
            _loans[i] = loans[loanIds[borrower][i]];
        }
    }

    function getAllowedCollateralTokens()
        external
        view
        returns (CollateralToken.Data[] memory allowedCollateralTokens)
    {
        uint256 length = collateralTokensSet.elements.length;
        allowedCollateralTokens = new CollateralToken.Data[](length);

        for (uint256 i = 0; i < length; i++) {
            allowedCollateralTokens[i] = collateralTokens[IERC20(collateralTokensSet.elements[i])];
        }
    }

    function calculateLoanByPrincipalAmount(IERC20 collateralToken, uint256 principalAmount)
        public
        view
        returns (Loan.Data memory loan)
    {
        loan = collateralTokens[collateralToken].calculateLoanByPrincipalAmount(principalAmount);
    }

    function calculateLoanByCollateralAmount(IERC20 collateralToken, uint256 collateralAmount)
        public
        view
        returns (Loan.Data memory loan)
    {
        loan = collateralTokens[collateralToken].calculateLoanByCollateralAmount(collateralAmount);
    }

    function calculateLoanBySecurityAmount(IERC20 collateralToken, uint256 securityAmount)
        public
        view
        returns (Loan.Data memory loan)
    {
        loan = collateralTokens[collateralToken].calculateLoanBySecurityAmount(securityAmount);
    }

    function getTotalValueLocked() public view returns (uint256 totalValueLocked) {
        for (uint256 i = 0; i < collateralTokensSet.elements.length; i++) {
            totalValueLocked += collateralTokens[IERC20(collateralTokensSet.elements[i])].getCollateralValue();
        }
    }

    function getLoanToValueRatio(uint256 loanId) public view returns (uint256 loanToValueRatio) {
        Loan.Data memory loan = loans[loanId];
        loanToValueRatio = loan.calculateLoanToValueRatio();
    }

    function checkHealth(uint256 loanId) public view returns (Health health) {
        uint256 loanToValueRatio = getLoanToValueRatio(loanId);
        health = loanToValueRatio >= core.liquidationLoanToValueRatio()
            ? Health.Liquidation
            : loanToValueRatio >= core.marginCallLoanToValueRatio()
            ? Health.MarginCall
            : Health.Ok;
    }

    function _createLoan(Loan.Data memory loan) internal returns (Loan.Data memory) {
        if (loan.principalAmount == 0) {
            revert BaksDAOBorrowZeroAmount();
        }
        if (loan.principalAmount < core.minimumPrincipalAmount()) {
            revert BaksDAOBorrowBelowMinimumPrincipalAmount();
        }

        stablecoin.mint(address(this), loan.stabilizationFee);
        stablecoin.mint(exchangeFund, loan.exchangeFee);
        stablecoin.mint(developmentFund, loan.developmentFee);
        stablecoin.mint(loan.borrower, loan.principalAmount);

        uint256 id = loans.length;
        loan.id = id;

        loans.push(loan);
        loanIds[loan.borrower].push(id);

        collateralTokens[loan.collateralToken].collateralAmount += loan.collateralAmount;

        emit Borrow(
            id,
            loan.borrower,
            loan.collateralToken,
            loan.principalAmount,
            loan.collateralAmount,
            collateralTokens[loan.collateralToken].initialLoanToValueRatio
        );

        return loan;
    }

    function _deposit(uint256 loanId, uint256 amount) internal {
        if (amount == 0) {
            revert BaksDAODepositZeroAmount();
        }

        Loan.Data storage loan = loans[loanId];

        uint256 normalizedCollateralAmount = loan.collateralToken.normalizeAmount(amount);
        loan.collateralAmount += normalizedCollateralAmount;
        loan.lastDepositAt = block.timestamp;
        collateralTokens[loan.collateralToken].collateralAmount += normalizedCollateralAmount;

        emit Deposit(loanId, normalizedCollateralAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Initializable} from "./libraries/Upgradability.sol";
import {Governed} from "./Governance.sol";

/// @dev Thrown when trying to set platform fees that don't sum up to one.
/// @param stabilizationFee The stabilization fee that was tried to set.
/// @param exchangeFee The stabilization fee that was tried to set.
/// @param developmentFee The stabilization fee that was tried to set.
error BaksDAOPlatformFeesDontSumUpToOne(uint256 stabilizationFee, uint256 exchangeFee, uint256 developmentFee);

interface ICore {
    event MinimumPrincipalAmountUpdated(uint256 minimumPrincipalAmount, uint256 newMinimumPrincipalAmount);
    event StabilityFeeUpdated(uint256 stabilityFee, uint256 newStabilityFee);
    event RebalancingThresholdUpdated(uint256 rebalancingThreshold, uint256 newRebalancingThreshold);
    event PlatformFeesUpdated(
        uint256 stabilizationFee,
        uint256 newStabilizationFee,
        uint256 exchangeFee,
        uint256 newExchangeFee,
        uint256 developmentFee,
        uint256 newDevelopmentFee
    );
    event MarginCallLoanToValueRatioUpdated(uint256 marginCallLoanToValueRatio, uint256 newMarginCallLoanToValueRatio);
    event LiquidationLoanToValueRatioUpdated(
        uint256 liqudationLoanToValueRatio,
        uint256 newLiquidationLoanToValueRatio
    );

    event ServicingThresholdUpdated(uint256 servicingThreshold, uint256 newServicingThreshold);
    event MinimumLiquidityUpdated(uint256 minimumLiquidity, uint256 newMinimumLiquidity);

    function minimumPrincipalAmount() external view returns (uint256);

    function stabilityFee() external view returns (uint256);

    function stabilizationFee() external view returns (uint256);

    function exchangeFee() external view returns (uint256);

    function developmentFee() external view returns (uint256);

    function marginCallLoanToValueRatio() external view returns (uint256);

    function liquidationLoanToValueRatio() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function servicingThreshold() external view returns (uint256);

    function minimumLiquidity() external view returns (uint256);
}

contract Core is Initializable, Governed, ICore {
    uint256 internal constant ONE = 100e16;

    uint256 public override minimumPrincipalAmount;
    uint256 public override stabilityFee;
    uint256 public override stabilizationFee;
    uint256 public override exchangeFee;
    uint256 public override developmentFee;
    uint256 public override marginCallLoanToValueRatio;
    uint256 public override liquidationLoanToValueRatio;
    uint256 public override rebalancingThreshold;

    uint256 public override servicingThreshold;
    uint256 public override minimumLiquidity;

    function initialize() external initializer {
        setGovernor(msg.sender);

        minimumPrincipalAmount = 50e18; // 50 BAKS
        stabilityFee = 3e16; // 3 %
        stabilizationFee = 85e16; // 85 %
        exchangeFee = 15e16; // 15 %
        developmentFee = 0;
        marginCallLoanToValueRatio = 75e16; // 75 %
        liquidationLoanToValueRatio = 83e16; // 83 %
        rebalancingThreshold = 1e16; // 1 %

        servicingThreshold = 1e16; // 1%
        minimumLiquidity = 50000e18; // 50000 BAKS
    }

    function setMinimumPrincipalAmount(uint256 newMinimumPrincipalAmount) external onlyGovernor {
        emit StabilityFeeUpdated(minimumPrincipalAmount, newMinimumPrincipalAmount);
        minimumPrincipalAmount = newMinimumPrincipalAmount;
    }

    function setStabilityFee(uint256 newStabilityFee) external onlyGovernor {
        emit StabilityFeeUpdated(stabilityFee, newStabilityFee);
        stabilityFee = newStabilityFee;
    }

    function setPlatformFees(
        uint256 newStabilizationFee,
        uint256 newExchangeFee,
        uint256 newDevelopmentFee
    ) external onlyGovernor {
        if (newStabilizationFee + newExchangeFee + newDevelopmentFee != ONE) {
            revert BaksDAOPlatformFeesDontSumUpToOne(newStabilizationFee, newExchangeFee, newDevelopmentFee);
        }
        emit PlatformFeesUpdated(
            stabilizationFee,
            newStabilizationFee,
            exchangeFee,
            newExchangeFee,
            developmentFee,
            newDevelopmentFee
        );
        stabilizationFee = newStabilizationFee;
        exchangeFee = newExchangeFee;
        developmentFee = newDevelopmentFee;
    }

    function setMarginCallLoanToValueRatio(uint256 newMarginCallLoanToValueRatio) external onlyGovernor {
        emit MarginCallLoanToValueRatioUpdated(marginCallLoanToValueRatio, newMarginCallLoanToValueRatio);
        marginCallLoanToValueRatio = newMarginCallLoanToValueRatio;
    }

    function setLiquidationLoanToValueRatio(uint256 newLiquidationLoanToValueRatio) external onlyGovernor {
        emit LiquidationLoanToValueRatioUpdated(liquidationLoanToValueRatio, newLiquidationLoanToValueRatio);
        liquidationLoanToValueRatio = newLiquidationLoanToValueRatio;
    }

    function setRebalancingThreshold(uint256 newRebalancingThreshold) external onlyGovernor {
        emit RebalancingThresholdUpdated(rebalancingThreshold, newRebalancingThreshold);
        rebalancingThreshold = newRebalancingThreshold;
    }

    function setServicingThreshold(uint256 newServicingThreshold) external onlyGovernor {
        emit ServicingThresholdUpdated(servicingThreshold, newServicingThreshold);
        servicingThreshold = newServicingThreshold;
    }

    function setMinimumLiquidity(uint256 newMinimumLiquidity) external onlyGovernor {
        emit MinimumLiquidityUpdated(minimumLiquidity, newMinimumLiquidity);
        minimumLiquidity = newMinimumLiquidity;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

error GovernedOnlyGovernorAllowedToCall();
error GovernedOnlyPendingGovernorAllowedToCall();
error GovernedGovernorZeroAddress();
error GovernedCantGoverItself();

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert GovernedOnlyGovernorAllowedToCall();
        }
        _;
    }

    function transitGovernance(address newGovernor, bool force) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        if (!force) {
            emit PendingGovernanceTransition(governor, newGovernor);
        } else {
            setGovernor(newGovernor);
        }
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }

    function setGovernor(address newGovernor) internal {
        governor = newGovernor;
        emit GovernanceTransited(governor, newGovernor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IMintableAndBurnableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./ERC20.sol";
import "./../libraries/FixedPointMath.sol";

/// @notice Thrown when oracle doesn't provide price for `token` token.
/// @param token The address of the token contract.
error PriceOracleTokenUnknown(IERC20 token);
/// @notice Thrown when oracle provide stale price `price` for `token` token.
/// @param token The address of the token contract.
/// @param price Provided price.
error PriceOracleStalePrice(IERC20 token, uint256 price);
/// @notice Thrown when oracle provide negative, zero or in other ways invalid price `price` for `token` token.
/// @param token The address of the token contract.
/// @param price Provided price.
error PriceOracleInvalidPrice(IERC20 token, int256 price);

interface IPriceOracle {
    /// @notice Gets normalized to 18 decimals price for the `token` token.
    /// @param token The address of the token contract.
    /// @return normalizedPrice Normalized price.
    function getNormalizedPrice(IERC20 token) external view returns (uint256 normalizedPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./ERC20.sol";

interface IWrappedNativeCurrency is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error CallToNonContract(address target);

library Address {
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.call(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function delegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.delegatecall(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }

        return codeSize > 0;
    }

    function verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returnData;
        } else {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(returnData, 32), returnDataSize)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./../interfaces/ERC20.sol";

library AmountNormalization {
    uint8 internal constant DECIMALS = 18;

    function normalizeAmount(IERC20 self, uint256 denormalizedAmount) internal view returns (uint256 normalizedAmount) {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return denormalizedAmount * scale;
        }
        return denormalizedAmount;
    }

    function denormalizeAmount(IERC20 self, uint256 normalizedAmount)
        internal
        view
        returns (uint256 denormalizedAmount)
    {
        uint256 scale = 10**(DECIMALS - self.decimals());
        if (scale != 1) {
            return normalizedAmount / scale;
        }
        return normalizedAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./FixedPointMath.sol";
import "./Loan.sol";
import {IERC20} from "./../interfaces/ERC20.sol";
import {IPriceOracle} from "./../interfaces/IPriceOracle.sol";

library CollateralToken {
    using FixedPointMath for uint256;

    struct Data {
        IERC20 collateralToken;
        IPriceOracle priceOracle;
        uint256 stabilityFee;
        uint256 stabilizationFee;
        uint256 exchangeFee;
        uint256 developmentFee;
        uint256 initialLoanToValueRatio;
        uint256 marginCallLoanToValueRatio;
        uint256 liquidationLoanToValueRatio;
        uint256 collateralAmount;
    }

    uint256 internal constant ONE = 100e16;

    function calculateLoanByPrincipalAmount(Data memory self, uint256 principalAmount)
        internal
        view
        returns (Loan.Data memory)
    {
        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);

        uint256 restOfIssuance = principalAmount.mul(ONE - self.initialLoanToValueRatio).div(
            self.initialLoanToValueRatio
        );
        uint256 stabilizationFee = restOfIssuance.mul(self.stabilizationFee);
        uint256 exchangeFee = restOfIssuance.mul(self.exchangeFee);
        uint256 developmentFee = restOfIssuance.mul(self.developmentFee);

        uint256 collateralAmount = principalAmount.div(self.initialLoanToValueRatio.mul(collateralTokenPrice));
        uint256 stabilityFee = self.stabilityFee.mul(principalAmount).div(collateralTokenPrice);

        return
            Loan.Data({
                id: 0,
                isActive: true,
                borrower: msg.sender,
                collateralToken: self.collateralToken,
                isNativeCurrency: false,
                priceOracle: self.priceOracle,
                stabilityFee: stabilityFee,
                stabilizationFee: stabilizationFee,
                exchangeFee: exchangeFee,
                developmentFee: developmentFee,
                principalAmount: principalAmount,
                collateralAmount: collateralAmount,
                lastDepositAt: block.timestamp,
                lastRepaymentAt: block.timestamp
            });
    }

    function calculateLoanByCollateralAmount(Data memory self, uint256 collateralAmount)
        internal
        view
        returns (Loan.Data memory)
    {
        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);
        uint256 principalAmount = collateralAmount.mul(self.initialLoanToValueRatio).mul(collateralTokenPrice);

        uint256 restOfIssuance = principalAmount.mul(ONE - self.initialLoanToValueRatio).div(
            self.initialLoanToValueRatio
        );
        uint256 stabilizationFee = restOfIssuance.mul(self.stabilizationFee);
        uint256 exchangeFee = restOfIssuance.mul(self.exchangeFee);
        uint256 developmentFee = restOfIssuance.mul(self.developmentFee);

        uint256 stabilityFee = self.stabilityFee.mul(principalAmount).div(collateralTokenPrice);

        return
            Loan.Data({
                id: 0,
                isActive: true,
                borrower: msg.sender,
                collateralToken: self.collateralToken,
                isNativeCurrency: false,
                priceOracle: self.priceOracle,
                stabilityFee: stabilityFee,
                stabilizationFee: stabilizationFee,
                exchangeFee: exchangeFee,
                developmentFee: developmentFee,
                principalAmount: principalAmount,
                collateralAmount: collateralAmount,
                lastDepositAt: block.timestamp,
                lastRepaymentAt: block.timestamp
            });
    }

    function calculateLoanBySecurityAmount(Data memory self, uint256 securityAmount)
        internal
        view
        returns (Loan.Data memory)
    {
        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);
        uint256 c = self.stabilityFee.mul(self.initialLoanToValueRatio);
        uint256 principalAmount = securityAmount.mul(self.initialLoanToValueRatio).mul(collateralTokenPrice).div(
            c + ONE
        );
        return calculateLoanByPrincipalAmount(self, principalAmount);
    }

    function getCollateralValue(Data memory self) internal view returns (uint256 collateralValue) {
        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);
        collateralValue = self.collateralAmount.mul(collateralTokenPrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library EnumerableAddressSet {
    struct Set {
        address[] elements;
        mapping(address => uint256) indexes;
    }

    function add(Set storage self, address element) internal returns (bool) {
        if (contains(self, element)) {
            return false;
        }

        self.elements.push(element);
        self.indexes[element] = self.elements.length;

        return true;
    }

    function remove(Set storage self, address element) internal returns (bool) {
        uint256 elementIndex = indexOf(self, element);
        if (elementIndex == 0) {
            return false;
        }

        uint256 indexToRemove = elementIndex - 1;
        uint256 lastIndex = count(self) - 1;
        if (indexToRemove != lastIndex) {
            address lastElement = self.elements[lastIndex];
            self.elements[indexToRemove] = lastElement;
            self.indexes[lastElement] = elementIndex;
        }
        self.elements.pop();
        delete self.indexes[element];

        return true;
    }

    function indexOf(Set storage self, address element) internal view returns (uint256) {
        return self.indexes[element];
    }

    function contains(Set storage self, address element) internal view returns (bool) {
        return indexOf(self, element) != 0;
    }

    function count(Set storage self) internal view returns (uint256) {
        return self.elements.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant SCALE = 1e18;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./FixedPointMath.sol";
import {IERC20} from "./../interfaces/ERC20.sol";
import {IPriceOracle} from "./../interfaces/IPriceOracle.sol";

library Loan {
    using FixedPointMath for uint256;

    struct Data {
        uint256 id;
        bool isActive;
        address borrower;
        IERC20 collateralToken;
        bool isNativeCurrency;
        IPriceOracle priceOracle;
        uint256 stabilityFee;
        uint256 stabilizationFee;
        uint256 exchangeFee;
        uint256 developmentFee;
        uint256 principalAmount;
        uint256 collateralAmount;
        uint256 lastDepositAt;
        uint256 lastRepaymentAt;
    }

    function getCollateralValue(Data memory self) internal view returns (uint256 collateralValue) {
        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);
        collateralValue = self.collateralAmount.mul(collateralTokenPrice);
    }

    function calculateLoanToValueRatio(Data memory self) internal view returns (uint256 loanToValueRatio) {
        if (self.principalAmount == 0) {
            return 0;
        }
        if (self.collateralAmount == 0) {
            return type(uint256).max;
        }

        loanToValueRatio = self.principalAmount.div(getCollateralValue(self));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Math {
    function abs(int256 a) internal pure returns (uint256) {
        return a >= 0 ? uint256(a) : uint256(-a);
    }

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }
        uint256 xAux = x;
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

        uint256 repeat = 7;
        while (repeat > 0) {
            result = (result + x / result) >> 1;
            repeat--;
        }
        uint256 roundedDownResult = x / result;

        return result >= roundedDownResult ? roundedDownResult : result;
    }

    function fpsqrt(uint256 a) internal pure returns (uint256 result) {
        if (a == 0) result = 0;
        else result = sqrt(a) * 1e9;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error ReentrancyGuardReentrantCall();

abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private status;

    modifier nonReentrant() {
        if (status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }

    constructor() {
        status = NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./../interfaces/ERC20.sol";
import "./Address.sol";

error SafeERC20NoReturnData();

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    function callWithOptionalReturn(IERC20 token, bytes memory data) internal {
        address tokenAddress = address(token);

        bytes memory returnData = tokenAddress.functionCall(data, "SafeERC20: low-level call failed");
        if (returnData.length > 0) {
            if (!abi.decode(returnData, (bool))) {
                revert SafeERC20NoReturnData();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Address.sol";

error EIP1967ImplementationIsNotContract(address implementation);
error ContractAlreadyInitialized();
error OnlyProxyCallAllowed();
error OnlyCurrentImplementationAllowed();

library EIP1967 {
    using Address for address;

    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed newImplementation);

    function upgradeTo(address newImplementation) internal {
        if (!newImplementation.isContract()) {
            revert EIP1967ImplementationIsNotContract(newImplementation);
        }

        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }

        emit Upgraded(newImplementation);
    }

    function getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }
}

contract Proxy {
    using Address for address;

    constructor(address implementation, bytes memory data) {
        EIP1967.upgradeTo(implementation);
        implementation.delegateCall(data, "Proxy: construction failed");
    }

    receive() external payable {
        delegateCall();
    }

    fallback() external payable {
        delegateCall();
    }

    function delegateCall() internal {
        address implementation = EIP1967.getImplementation();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

abstract contract Upgradeable {
    address private immutable self = address(this);

    modifier onlyProxy() {
        if (address(this) == self) {
            revert OnlyProxyCallAllowed();
        }
        if (EIP1967.getImplementation() != self) {
            revert OnlyCurrentImplementationAllowed();
        }
        _;
    }

    function upgradeTo(address newImplementation) public virtual onlyProxy {
        EIP1967.upgradeTo(newImplementation);
    }
}

abstract contract Initializable {
    bool private initializing;
    bool private initialized;

    modifier initializer() {
        if (!initializing && initialized) {
            revert ContractAlreadyInitialized();
        }

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }
}