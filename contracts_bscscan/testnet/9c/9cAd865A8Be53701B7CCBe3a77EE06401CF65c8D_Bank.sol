// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IBank.sol";
import "./interfaces/IWrappedNativeCurrency.sol";
import "./libraries/AmountNormalization.sol";
import "./libraries/Beneficiary.sol";
import "./libraries/CollateralToken.sol";
import "./libraries/EnumerableAddressSet.sol";
import "./libraries/FixedPointMath.sol";
import "./libraries/Loan.sol";
import "./libraries/Math.sol";
import "./libraries/MintingStage.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/SafeERC20.sol";
import {CoreInside, ICore} from "./Core.sol";
import {Governed} from "./Governance.sol";
import {IDepositary} from "./Depositary.sol";
import {IERC20, IMintableAndBurnableERC20} from "./interfaces/ERC20.sol";
import {Initializable} from "./libraries/Upgradability.sol";

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

error BaksDAOVoiceNothingToMint();

error BaksDAOVoiceMintingEnded();

/// @title Core smart contract of BaksDAO platform
/// @author BaksDAO
/// @notice You should use this contract to interact with the BaksDAO platform.
/// @notice Only this contract can issue BAKS and BDV tokens.
contract Bank is CoreInside, Governed, IBank, Initializable, ReentrancyGuard {
    using AmountNormalization for IERC20;
    using AmountNormalization for IWrappedNativeCurrency;
    using CollateralToken for CollateralToken.Data;
    using EnumerableAddressSet for EnumerableAddressSet.Set;
    using FixedPointMath for uint256;
    using Loan for Loan.Data;
    using MintingStage for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableAndBurnableERC20;
    using SafeERC20 for IWrappedNativeCurrency;

    enum Health {
        Ok,
        MarginCall,
        Liquidation
    }

    uint256 internal constant ONE = 100e16;
    uint8 internal constant DECIMALS = 18;

    Loan.Data[] public loans;
    mapping(address => uint256[]) public loanIds;

    mapping(IERC20 => CollateralToken.Data) public collateralTokens;
    EnumerableAddressSet.Set internal collateralTokensSet;

    uint256 public nextVoiceMintingStage;

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

    event Rebalance(int256 delta, uint256 voiceMinted);

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

    receive() external payable {
        if (msg.sender != core.wrappedNativeCurrency()) {
            revert BaksDAOPlainNativeCurrencyTransferNotAllowed();
        }
    }

    function initialize(ICore _core) external initializer {
        initializeReentrancyGuard();
        initializeCoreInside(_core);
        setGovernor(msg.sender);
    }

    /// @notice Increases loan's principal on `collateralToken` collateral token and mints `amount` of stablecoin.
    /// @dev The caller must have allowed this contract to spend a sufficient amount of collateral tokens to cover
    /// initial loan-to-value ratio.
    /// @param collateralToken The address of the collateral token contract.
    /// @param amount The amount of stablecoin to borrow and issue.
    function borrow(IERC20 collateralToken, uint256 amount)
        external
        tokenAllowedAsCollateral(collateralToken)
        returns (Loan.Data memory)
    {
        (
            Loan.Data memory loan,
            uint256 exchangeFee,
            uint256 developmentFee,
            uint256 stabilityFee
        ) = calculateLoanByPrincipalAmount(collateralToken, amount);

        collateralToken.safeTransferFrom(msg.sender, core.operator(), collateralToken.denormalizeAmount(stabilityFee));
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            collateralToken.denormalizeAmount(loan.collateralAmount)
        );

        return _createLoan(loan, exchangeFee, developmentFee);
    }

    /// @notice Increases loan's principal on wrapped native currency token and mints stablecoin.
    function borrowInNativeCurrency(uint256 amount) external payable nonReentrant returns (Loan.Data memory) {
        IWrappedNativeCurrency wrappedNativeCurrency = IWrappedNativeCurrency(core.wrappedNativeCurrency());

        (
            Loan.Data memory loan,
            uint256 exchangeFee,
            uint256 developmentFee,
            uint256 stabilityFee
        ) = calculateLoanByPrincipalAmount(wrappedNativeCurrency, amount);
        loan.isNativeCurrency = true;

        uint256 securityAmount = loan.collateralAmount + stabilityFee;
        if (msg.value < securityAmount) {
            revert BaksDAOInsufficientSecurityAmount(securityAmount);
        }

        wrappedNativeCurrency.deposit{value: securityAmount}();
        wrappedNativeCurrency.safeTransfer(core.operator(), wrappedNativeCurrency.denormalizeAmount(stabilityFee));

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

        return _createLoan(loan, exchangeFee, developmentFee);
    }

    /// @notice Deposits `amount` of collateral token to loan with `id` id.
    /// @dev The caller must have allowed this contract to spend `amount` of collateral tokens.
    /// @param loanId The loan id.
    /// @param amount The amount of collateral token to deposit.
    function deposit(uint256 loanId, uint256 amount) external onActiveLoan(loanId) notOnSubjectToLiquidation(loanId) {
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
        IWrappedNativeCurrency wrappedNativeCurrency = IWrappedNativeCurrency(core.wrappedNativeCurrency());
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
        loan.accrueInterest();

        amount = Math.min(loan.principalAmount + loan.interestAmount, amount);
        uint256 interestPayment;
        uint256 principalPayment;
        if (loan.interestAmount < amount) {
            principalPayment = amount - loan.interestAmount;
            interestPayment = loan.interestAmount;

            loan.principalAmount -= principalPayment;
            loan.interestAmount = 0;
        } else {
            interestPayment = amount;
            loan.interestAmount -= interestPayment;
        }

        IMintableAndBurnableERC20 baks = IMintableAndBurnableERC20(core.baks());

        if (interestPayment > 0) {
            baks.safeTransferFrom(msg.sender, core.developmentFund(), interestPayment);
        }

        if (principalPayment > 0) {
            baks.safeTransferFrom(msg.sender, address(this), principalPayment);
        }

        loan.lastInteractionAt = block.timestamp;
        if (loan.principalAmount > 0) {
            emit Repay(loanId, amount);
        } else {
            uint256 denormalizedCollateralAmount = loan.collateralToken.denormalizeAmount(loan.collateralAmount);
            collateralTokens[loan.collateralToken].collateralAmount -= loan.collateralAmount;

            loan.collateralAmount = 0;

            baks.burn(address(this), amount + loan.stabilizationFee);

            loan.isActive = false;
            emit Repaid(loanId);

            loan.collateralToken.safeTransfer(loan.borrower, denormalizedCollateralAmount);

            /* if (!loan.isNativeCurrency) {
                loan.collateralToken.safeTransfer(loan.borrower, denormalizedCollateralAmount);
            } else {
                IWrappedNativeCurrency(core.wrappedNativeCurrency()).withdraw(denormalizedCollateralAmount);
                (bool success, ) = msg.sender.call{value: denormalizedCollateralAmount}("");
                if (!success) {
                    revert BaksDAONativeCurrencyTransferFailed();
                }
            } */
        }
    }

    function liquidate(uint256 loanId) external onActiveLoan(loanId) onSubjectToLiquidation(loanId) {
        Loan.Data storage loan = loans[loanId];

        collateralTokens[loan.collateralToken].collateralAmount -= loan.collateralAmount;
        loan.collateralToken.safeTransfer(
            core.developmentFund(),
            loan.collateralToken.denormalizeAmount(loan.collateralAmount)
        );

        IMintableAndBurnableERC20 baks = IMintableAndBurnableERC20(core.baks());
        uint256 collateralValue = loan.getCollateralValue();
        baks.burn(core.liquidator(), loan.principalAmount);
        baks.burn(address(this), collateralValue - loan.principalAmount);

        loan.isActive = false;
        emit Liquidated(loanId);
    }

    function rebalance() external {
        IMintableAndBurnableERC20 baks = IMintableAndBurnableERC20(core.baks());

        uint256 totalValueLocked = getTotalValueLocked();
        uint256 totalSupply = baks.totalSupply();

        int256 delta = int256(totalSupply) - int256(totalValueLocked);
        uint256 absoluteDelta = Math.abs(delta);
        uint256 p = absoluteDelta.div(totalSupply);
        if (p < core.rebalancingThreshold()) {
            revert BaksDAONoNeedToRebalance();
        }

        if (delta > 0) {
            try baks.burn(address(this), absoluteDelta) {} catch {
                uint256 balance = baks.balanceOf(address(this));
                revert BaksDAOStabilizationFundOutOfFunds(absoluteDelta - balance);
            }
        } else {
            baks.mint(address(this), absoluteDelta);
        }

        emit Rebalance(delta, 0);
    }

    function mintVoice() external {
        uint256[] memory voiceMintingSchedule = core.voiceMintingSchedule();
        uint256 length = voiceMintingSchedule.length;

        if (nextVoiceMintingStage >= length) {
            revert BaksDAOVoiceMintingEnded();
        }

        uint256 totalValueLocked = getTotalValueLocked();
        uint256 voiceToMint;

        for (uint256 i = nextVoiceMintingStage; i < length; i++) {
            (uint256 targetTotalValueLocked, uint256 amount) = voiceMintingSchedule[i].split();

            if (totalValueLocked < targetTotalValueLocked) {
                nextVoiceMintingStage = i;
                break;
            }

            voiceToMint += amount;
        }

        if (voiceToMint == 0) {
            revert BaksDAOVoiceNothingToMint();
        }

        IMintableAndBurnableERC20 voice = IMintableAndBurnableERC20(core.voice());
        voice.mint(address(this), voiceToMint);

        uint256 voiceTotalShares = core.voiceTotalShares();
        uint256[] memory beneficiaries = core.voiceMintingBeneficiaries();
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            (address beneficiary, uint256 share) = Beneficiary.split(beneficiaries[i]);
            voice.safeTransfer(beneficiary, (voiceToMint * share) / voiceTotalShares);
        }

        emit Rebalance(0, voiceToMint);
    }

    function onNewDeposit(IERC20 token, uint256 amount) external onlyDepositary {
        IMintableAndBurnableERC20 baks = IMintableAndBurnableERC20(core.baks());
        if (token == baks) {
            return;
        }

        amount = amount.mul(IPriceOracle(core.priceOracle()).getNormalizedPrice(token));

        baks.mint(address(this), amount.mul(core.stabilizationFee()));
        baks.mint(core.exchangeFund(), amount.mul(core.exchangeFee()));
        baks.mint(core.developmentFund(), amount.mul(core.developmentFee()));
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
                priceOracle: IPriceOracle(core.priceOracle()),
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
        if (tokenAddress == core.baks() || collateralTokensSet.contains(tokenAddress)) {
            revert BaksDAOTokenNotAllowedToBeSalvaged(token);
        }
        token.safeTransfer(core.operator(), token.balanceOf(address(this)));
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
        returns (
            Loan.Data memory loan,
            uint256 exchangeFee,
            uint256 developmentFee,
            uint256 stabilityFee
        )
    {
        return collateralTokens[collateralToken].calculateLoanByPrincipalAmount(principalAmount);
    }

    function calculateLoanByCollateralAmount(IERC20 collateralToken, uint256 collateralAmount)
        public
        view
        returns (
            Loan.Data memory loan,
            uint256 exchangeFee,
            uint256 developmentFee,
            uint256 stabilityFee
        )
    {
        return collateralTokens[collateralToken].calculateLoanByCollateralAmount(collateralAmount);
    }

    function calculateLoanBySecurityAmount(IERC20 collateralToken, uint256 securityAmount)
        public
        view
        returns (
            Loan.Data memory loan,
            uint256 exchangeFee,
            uint256 developmentFee,
            uint256 stabilityFee
        )
    {
        return collateralTokens[collateralToken].calculateLoanBySecurityAmount(securityAmount);
    }

    function getTotalValueLocked() public view returns (uint256 totalValueLocked) {
        for (uint256 i = 0; i < collateralTokensSet.elements.length; i++) {
            totalValueLocked += collateralTokens[IERC20(collateralTokensSet.elements[i])].getCollateralValue();
        }
        totalValueLocked += IDepositary(core.depositary()).getTotalValueLocked();
    }

    function getTotalValueLocked(IERC20 token) public view returns (uint256 totalValueLocked) {
        totalValueLocked = collateralTokens[token].getCollateralValue();
        totalValueLocked += IDepositary(core.depositary()).getTotalValueLocked(token);
    }

    function getLoanToValueRatio(uint256 loanId) public view returns (uint256 loanToValueRatio) {
        Loan.Data memory loan = loans[loanId];
        loanToValueRatio = loan.calculateLoanToValueRatio();
    }

    function getLoanAccruedInterest(uint256 loanId) public view returns (uint256 accruedInterest) {
        Loan.Data memory loan = loans[loanId];
        accruedInterest = loan.calculateInterest();
    }

    function checkHealth(uint256 loanId) public view returns (Health health) {
        uint256 loanToValueRatio = getLoanToValueRatio(loanId);
        health = loanToValueRatio >= core.liquidationLoanToValueRatio()
            ? Health.Liquidation
            : loanToValueRatio >= core.marginCallLoanToValueRatio()
            ? Health.MarginCall
            : Health.Ok;
    }

    function _createLoan(
        Loan.Data memory loan,
        uint256 exchangeFee,
        uint256 developmentFee
    ) internal returns (Loan.Data memory) {
        if (loan.principalAmount == 0) {
            revert BaksDAOBorrowZeroAmount();
        }
        if (loan.principalAmount < core.minimumPrincipalAmount()) {
            revert BaksDAOBorrowBelowMinimumPrincipalAmount();
        }

        IMintableAndBurnableERC20 baks = IMintableAndBurnableERC20(core.baks());
        baks.mint(address(this), loan.stabilizationFee);
        baks.mint(core.exchangeFund(), exchangeFee);
        baks.mint(core.developmentFund(), developmentFee);
        baks.mint(loan.borrower, loan.principalAmount);

        uint256 id = loans.length;
        loan.id = id;
        loan.interest = core.interest();

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
        loan.accrueInterest();

        uint256 normalizedCollateralAmount = loan.collateralToken.normalizeAmount(amount);
        loan.collateralAmount += normalizedCollateralAmount;
        loan.lastInteractionAt = block.timestamp;
        collateralTokens[loan.collateralToken].collateralAmount += normalizedCollateralAmount;

        emit Deposit(loanId, normalizedCollateralAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./libraries/Beneficiary.sol";
import {Governed} from "./Governance.sol";
import {Initializable} from "./libraries/Upgradability.sol";

interface ICore {
    /// @dev Thrown when trying to set platform fees that don't sum up to one.
    /// @param stabilizationFee The stabilization fee that was tried to set.
    /// @param exchangeFee The stabilization fee that was tried to set.
    /// @param developmentFee The stabilization fee that was tried to set.
    error BaksDAOPlatformFeesDontSumUpToOne(uint256 stabilizationFee, uint256 exchangeFee, uint256 developmentFee);

    event PriceOracleUpdated(address priceOracle, address newPriceOracle);

    event BaksUpdated(address baks, address newBaks);
    event VoiceUpdated(address voice, address newVoice);

    event BankUpdated(address bank, address newBank);
    event DepositaryUpdated(address depositary, address newDepositary);
    event ExchangeFundUpdated(address exchangeFund, address newExchangeFund);
    event DevelopmentFundUpdated(address developmentFund, address newDevelopmentFund);

    event OperatorUpdated(address operator, address newOperator);
    event LiquidatorUpdated(address liquidator, address newLiquidator);

    event InterestUpdated(uint256 interest, uint256 newInterest);
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

    event MinimumMagisterDepositAmountUpdated(
        uint256 minimumMagisterDepositAmount,
        uint256 newMinimumMagisterDepositAmount
    );
    event WorkFeeUpdated(uint256 workFee, uint256 newWorkFee);
    event EarlyWithdrawalPeriodUpdated(uint256 earlyWithdrawalPeriod, uint256 newEarlyWithdrawalPeriod);
    event EarlyWithdrawalFeeUpdated(uint256 earlyWithdrawalFee, uint256 newEarlyWithdrawalFee);

    event ServicingThresholdUpdated(uint256 servicingThreshold, uint256 newServicingThreshold);
    event MinimumLiquidityUpdated(uint256 minimumLiquidity, uint256 newMinimumLiquidity);

    function wrappedNativeCurrency() external view returns (address);

    function uniswapV2Router() external view returns (address);

    function priceOracle() external view returns (address);

    function baks() external view returns (address);

    function voice() external view returns (address);

    function bank() external view returns (address);

    function depositary() external view returns (address);

    function exchangeFund() external view returns (address);

    function developmentFund() external view returns (address);

    function operator() external view returns (address);

    function liquidator() external view returns (address);

    function interest() external view returns (uint256);

    function minimumPrincipalAmount() external view returns (uint256);

    function stabilityFee() external view returns (uint256);

    function stabilizationFee() external view returns (uint256);

    function exchangeFee() external view returns (uint256);

    function developmentFee() external view returns (uint256);

    function marginCallLoanToValueRatio() external view returns (uint256);

    function liquidationLoanToValueRatio() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function minimumMagisterDepositAmount() external view returns (uint256);

    function workFee() external view returns (uint256);

    function earlyWithdrawalPeriod() external view returns (uint256);

    function earlyWithdrawalFee() external view returns (uint256);

    function servicingThreshold() external view returns (uint256);

    function minimumLiquidity() external view returns (uint256);

    function voiceMintingSchedule() external view returns (uint256[] memory);

    function voiceTotalShares() external view returns (uint256);

    function voiceMintingBeneficiaries() external view returns (uint256[] memory);

    function isSuperUser(address account) external view returns (bool);
}

contract Core is Initializable, Governed, ICore {
    uint256 internal constant ONE = 100e16;

    address public override wrappedNativeCurrency;
    address public override uniswapV2Router;

    address public override priceOracle;

    address public override baks;
    address public override voice;

    address public override bank;
    address public override depositary;
    address public override exchangeFund;
    address public override developmentFund;

    // Roles
    address public override operator;
    address public override liquidator;

    // Bank parameters
    uint256 public override interest;
    uint256 public override minimumPrincipalAmount;
    uint256 public override stabilityFee;
    uint256 public override stabilizationFee;
    uint256 public override exchangeFee;
    uint256 public override developmentFee;
    uint256 public override marginCallLoanToValueRatio;
    uint256 public override liquidationLoanToValueRatio;
    uint256 public override rebalancingThreshold;

    // Depositary parameters
    uint256 public override minimumMagisterDepositAmount;
    uint256 public override workFee;
    uint256 public override earlyWithdrawalPeriod;
    uint256 public override earlyWithdrawalFee;

    // Exchange fund parameters
    uint256 public override servicingThreshold;
    uint256 public override minimumLiquidity;

    // Voice
    uint256[] internal _voiceMintingSchedule;
    uint256[] internal _voiceMintingBeneficiaries;
    uint256 public override voiceTotalShares;

    mapping(address => bool) public override isSuperUser;

    function initialize(
        address _wrappedNativeCurrency,
        address _uniswapV2Router,
        address _operator,
        address _liquidator
    ) external initializer {
        setGovernor(msg.sender);

        wrappedNativeCurrency = _wrappedNativeCurrency;
        uniswapV2Router = _uniswapV2Router;

        operator = _operator;
        liquidator = _liquidator;

        interest = 11e16; // 11 %
        minimumPrincipalAmount = 50e18; // 50 BAKS
        stabilityFee = 15e15; // 1,5 %
        stabilizationFee = 85e16; // 85 %
        exchangeFee = 15e16; // 15 %
        developmentFee = 0;
        marginCallLoanToValueRatio = 75e16; // 75 %
        liquidationLoanToValueRatio = 83e16; // 83 %
        rebalancingThreshold = 1e16; // 1 %

        minimumMagisterDepositAmount = 50000e18; // 50000 BAKS
        workFee = 2e16; // 2 %
        earlyWithdrawalPeriod = 72 hours;
        earlyWithdrawalFee = 1e15; // 0,1 %

        servicingThreshold = 1e16; // 1%
        minimumLiquidity = 50000e18; // 50000 BAKS

        _voiceMintingSchedule = [
            0x295be96e64066972000000,
            0x0422ca8b0a00a4250000000000000000295be96e64066972000000,
            0x084595161401484a000000000000000052b7d2dcc80cd2e4000000,
            0x108b2a2c28029094000000000000000052b7d2dcc80cd2e4000000,
            0x2116545850052128000000000000000052b7d2dcc80cd2e4000000,
            0x422ca8b0a00a4250000000000000000052b7d2dcc80cd2e4000000,
            0x84595161401484a0000000000000000052b7d2dcc80cd2e4000000,
            0x0108b2a2c280290940000000000000000052b7d2dcc80cd2e4000000,
            0x014adf4b7320334b90000000000000000052b7d2dcc80cd2e4000000,
            0x018d0bf423c03d8de0000000000000000052b7d2dcc80cd2e4000000,
            0x01cf389cd46047d030000000000000000052b7d2dcc80cd2e4000000,
            0x021165458500521280000000000000000052b7d2dcc80cd2e4000000,
            0x025391ee35a05c54d0000000000000000052b7d2dcc80cd2e4000000,
            0x0295be96e6406697200000000000000000a56fa5b99019a5c8000000,
            0x02d7eb3f96e070d9700000000000000000a56fa5b99019a5c8000000,
            0x031a17e847807b1bc00000000000000000a56fa5b99019a5c8000000,
            0x035c4490f820855e100000000000000000a56fa5b99019a5c8000000
        ];

        isSuperUser[msg.sender] = true;
    }

    function setPriceOracle(address newPriceOracle) external onlyGovernor {
        emit PriceOracleUpdated(priceOracle, newPriceOracle);
        priceOracle = newPriceOracle;
    }

    function setBaks(address newBaks) external onlyGovernor {
        emit BaksUpdated(baks, newBaks);
        baks = newBaks;
    }

    function setVoice(address newVoice) external onlyGovernor {
        emit VoiceUpdated(voice, newVoice);
        voice = newVoice;
    }

    function setBank(address newBank) external onlyGovernor {
        emit BankUpdated(bank, newBank);
        bank = newBank;
    }

    function setDepositary(address newDepositary) external onlyGovernor {
        emit DepositaryUpdated(depositary, newDepositary);
        depositary = newDepositary;
    }

    function setExchangeFund(address newExchangeFund) external onlyGovernor {
        emit ExchangeFundUpdated(exchangeFund, newExchangeFund);
        exchangeFund = newExchangeFund;
    }

    function setDevelopmentFund(address newDevelopmentFund) external onlyGovernor {
        emit DevelopmentFundUpdated(developmentFund, newDevelopmentFund);
        developmentFund = newDevelopmentFund;
    }

    function setOperator(address newOperator) external onlyGovernor {
        emit OperatorUpdated(operator, newOperator);
        operator = newOperator;
    }

    function setLiquidator(address newLiquidator) external onlyGovernor {
        emit LiquidatorUpdated(liquidator, newLiquidator);
        liquidator = newLiquidator;
    }

    function setInterest(uint256 newInterest) external onlyGovernor {
        emit InterestUpdated(interest, newInterest);
        interest = newInterest;
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

    function setMinimumMagisterDepositAmount(uint256 newMinimumMagisterDepositAmount) external onlyGovernor {
        emit MinimumMagisterDepositAmountUpdated(minimumMagisterDepositAmount, newMinimumMagisterDepositAmount);
        minimumMagisterDepositAmount = newMinimumMagisterDepositAmount;
    }

    function setWorkFee(uint256 newWorkFee) external onlyGovernor {
        emit WorkFeeUpdated(workFee, newWorkFee);
        workFee = newWorkFee;
    }

    function setEarlyWithdrawalPeriod(uint256 newEarlyWithdrawalPeriod) external onlyGovernor {
        emit EarlyWithdrawalPeriodUpdated(earlyWithdrawalPeriod, newEarlyWithdrawalPeriod);
        earlyWithdrawalPeriod = newEarlyWithdrawalPeriod;
    }

    function setEarlyWithdrawalFee(uint256 newEarlyWithdrawalFee) external onlyGovernor {
        emit EarlyWithdrawalFeeUpdated(earlyWithdrawalFee, newEarlyWithdrawalFee);
        earlyWithdrawalFee = newEarlyWithdrawalFee;
    }

    function setServicingThreshold(uint256 newServicingThreshold) external onlyGovernor {
        emit ServicingThresholdUpdated(servicingThreshold, newServicingThreshold);
        servicingThreshold = newServicingThreshold;
    }

    function setMinimumLiquidity(uint256 newMinimumLiquidity) external onlyGovernor {
        emit MinimumLiquidityUpdated(minimumLiquidity, newMinimumLiquidity);
        minimumLiquidity = newMinimumLiquidity;
    }

    function setVoiceMintingBeneficiaries(uint256[] calldata beneficiaries) external onlyGovernor {
        delete _voiceMintingBeneficiaries;
        _voiceMintingBeneficiaries = beneficiaries;
        for (uint256 i = 0; i < _voiceMintingBeneficiaries.length; i++) {
            (, uint256 share) = Beneficiary.split(_voiceMintingBeneficiaries[i]);
            voiceTotalShares += share;
        }
    }

    function addSuperUser(address account) external onlyGovernor {
        isSuperUser[account] = true;
    }

    function removeSuperUser(address account) external onlyGovernor {
        isSuperUser[account] = false;
    }

    function voiceMintingBeneficiaries() external view override returns (uint256[] memory) {
        return _voiceMintingBeneficiaries;
    }

    function voiceMintingSchedule() external view override returns (uint256[] memory) {
        return _voiceMintingSchedule;
    }
}

abstract contract CoreInside {
    ICore public core;

    error BaksDAOOnlyDepositaryAllowed();
    error BaksDAOOnlySuperUserAllowed();

    modifier onlyDepositary() {
        if (msg.sender != address(core.depositary())) {
            revert BaksDAOOnlyDepositaryAllowed();
        }
        _;
    }

    modifier onlySuperUser() {
        if (!core.isSuperUser(msg.sender)) {
            revert BaksDAOOnlySuperUserAllowed();
        }
        _;
    }

    function initializeCoreInside(ICore _core) internal {
        core = _core;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./libraries/AmountNormalization.sol";
import "./libraries/Deposit.sol";
import "./libraries/EnumerableAddressSet.sol";
import "./libraries/FixedPointMath.sol";
import "./libraries/Magister.sol";
import "./libraries/Math.sol";
import "./libraries/Pool.sol";
import "./libraries/SafeERC20.sol";
import {CoreInside, ICore} from "./Core.sol";
import {Governed} from "./Governance.sol";
import {IERC20} from "./interfaces/ERC20.sol";
import {Initializable} from "./libraries/Upgradability.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import "./interfaces/IDepositary.sol";
import "./interfaces/IBank.sol";

error BaksDAOMagisterAlreadyWhitelisted(address magister);
error BaksDAOMagisterBlacklisted(address magister);
error BaksDAOOnlyDepositorOrMagisterAllowed();
error BaksDAOWithdrawAmountExceedsPrincipal();
error BaksDAOBelowMinimumMagisterDepositAmount();
error BaksDAODepositZeroAmount();

contract Depositary is CoreInside, Governed, IDepositary, Initializable {
    using AmountNormalization for IERC20;
    using Deposit for Deposit.Data;
    using EnumerableAddressSet for EnumerableAddressSet.Set;
    using FixedPointMath for uint256;
    using Magister for Magister.Data;
    using Pool for Pool.Data;
    using SafeERC20 for IERC20;

    uint256 internal constant ONE = 100e16;

    mapping(address => Magister.Data) public magisters;
    EnumerableAddressSet.Set internal magistersSet;

    Pool.Data[] public pools;

    Deposit.Data[] public deposits;
    mapping(uint256 => mapping(address => uint256)) public currentDepositIds;

    event MagisterWhitelisted(address indexed magister);
    event MagisterBlacklisted(address indexed magister);

    function initialize(ICore _core) external initializer {
        initializeCoreInside(_core);
        setGovernor(msg.sender);

        // Add guard pool and deposit
        deposits.push(
            Deposit.Data({
                id: 0,
                isActive: false,
                depositor: address(0),
                magister: address(0),
                poolId: 0,
                principal: 0,
                depositorTotalAccruedRewards: 0,
                depositorWithdrawnRewards: 0,
                magisterTotalAccruedRewards: 0,
                magisterWithdrawnRewards: 0,
                createdAt: block.timestamp,
                lastDepositAt: block.timestamp,
                lastInteractionAt: block.timestamp,
                closedAt: block.timestamp
            })
        );

        pools.push(
            Pool.Data({
                id: 0,
                depositToken: IERC20(address(0)),
                priceOracle: IPriceOracle(core.priceOracle()),
                isCompounding: false,
                depositsAmount: 0,
                depositorApr: 0,
                magisterApr: 0,
                depositorBonusApr: 0,
                magisterBonusApr: 0
            })
        );
    }

    function deposit(uint256 poolId, uint256 amount) external {
        deposit(poolId, amount, address(this));
    }

    function withdraw(uint256 depositId, uint256 amount) external {
        Deposit.Data storage d = deposits[depositId];
        Pool.Data storage p = pools[d.poolId];

        if (!(msg.sender == d.depositor || msg.sender == d.magister)) {
            revert BaksDAOOnlyDepositorOrMagisterAllowed();
        }

        uint256 normalizedAmount = p.depositToken.normalizeAmount(amount);
        accrueRewards(d.id);

        uint256 magisterAmount = Math.min(d.magisterTotalAccruedRewards - d.magisterWithdrawnRewards, normalizedAmount);
        (
            uint256 depositorReward,
            uint256 depositorBonusReward,
            uint256 magisterReward,
            uint256 magisterBonusReward
        ) = splitRewards(d.poolId, d.depositorTotalAccruedRewards - d.depositorWithdrawnRewards, magisterAmount);

        if (msg.sender == d.magister) {
            IERC20(core.baks()).safeTransferFrom(core.exchangeFund(), d.magister, magisterReward);
            if (magisterBonusReward > 0) {
                IERC20(core.voice()).safeTransferFrom(core.exchangeFund(), d.magister, magisterBonusReward);
            }

            d.magisterWithdrawnRewards += magisterAmount;
        } else {
            if (normalizedAmount > d.principal) {
                revert BaksDAOWithdrawAmountExceedsPrincipal();
            }

            uint256 fee;
            if (p.isCompounding) {
                fee = core.workFee();

                if (block.timestamp < d.lastDepositAt + core.earlyWithdrawalPeriod()) {
                    fee += core.earlyWithdrawalFee();
                }

                depositorReward = depositorReward.mul(ONE - fee);
            }

            if (p.depositToken != IERC20(core.baks()) && p.depositToken != IERC20(core.voice())) {
                p.depositToken.safeTransfer(d.depositor, normalizedAmount);
            }
            IERC20(core.baks()).safeTransferFrom(
                core.exchangeFund(),
                d.depositor,
                p.depositToken == IERC20(core.baks()) ? normalizedAmount + depositorReward : depositorReward
            );
            if (depositorBonusReward > 0) {
                IERC20(core.voice()).safeTransferFrom(core.exchangeFund(), d.depositor, depositorBonusReward);
            }

            p.depositsAmount -= normalizedAmount;
            d.principal -= normalizedAmount;
            d.depositorWithdrawnRewards += d.depositorTotalAccruedRewards - d.depositorWithdrawnRewards;
        }

        d.lastInteractionAt = block.timestamp;
        if (d.principal == 0) {
            d.isActive = false;
            d.closedAt = block.timestamp;
            delete currentDepositIds[d.poolId][msg.sender];
        }
    }

    function whitelistMagister(address magister) external onlyGovernor {
        if (magistersSet.contains(magister)) {
            revert BaksDAOMagisterAlreadyWhitelisted(magister);
        }

        if (magistersSet.add(magister)) {
            Magister.Data storage m = magisters[magister];
            m.addr = magister;
            if (m.createdAt == 0) {
                m.createdAt = block.timestamp;
            }
            m.isActive = true;

            emit MagisterWhitelisted(magister);
        }
    }

    function blacklistMagister(address magister) external onlyGovernor {
        if (!magistersSet.contains(magister)) {
            revert BaksDAOMagisterBlacklisted(magister);
        }

        if (magistersSet.remove(magister)) {
            magisters[magister].isActive = false;
            emit MagisterBlacklisted(magister);
        }
    }

    function addPool(
        IERC20 depositToken,
        bool isCompounding,
        uint256 depositorApr,
        uint256 magisterApr,
        uint256 depositorBonusApr,
        uint256 magisterBonusApr
    ) external onlyGovernor {
        uint256 poolId = pools.length;
        pools.push(
            Pool.Data({
                id: poolId,
                depositToken: depositToken,
                priceOracle: IPriceOracle(core.priceOracle()),
                isCompounding: isCompounding,
                depositsAmount: 0,
                depositorApr: depositorApr,
                magisterApr: magisterApr,
                depositorBonusApr: depositorBonusApr,
                magisterBonusApr: magisterBonusApr
            })
        );
    }

    function updatePool(
        uint256 poolId,
        bool isCompounding,
        uint256 depositorApr,
        uint256 magisterApr,
        uint256 depositorBonusApr,
        uint256 magisterBonusApr
    ) external onlyGovernor {
        Pool.Data storage pool = pools[poolId];
        pool.isCompounding = isCompounding;
        pool.depositorApr = depositorApr;
        pool.magisterApr = magisterApr;
        pool.depositorBonusApr = depositorBonusApr;
        pool.magisterBonusApr = magisterBonusApr;
    }

    function getActiveMagisterAddresses() external view returns (address[] memory activeMagisterAddresses) {
        activeMagisterAddresses = magistersSet.elements;
    }

    function getActiveMagisters() external view returns (Magister.Data[] memory activeMagisters) {
        uint256 length = magistersSet.elements.length;
        activeMagisters = new Magister.Data[](length);

        for (uint256 i = 0; i < length; i++) {
            activeMagisters[i] = magisters[magistersSet.elements[i]];
        }
    }

    function getPoolsCount() external view returns (uint256) {
        return pools.length;
    }

    function getPools() external view returns (Pool.Data[] memory) {
        return pools;
    }

    function getMagisterDepositIds(address magister) external view returns (uint256[] memory) {
        return magisters[magister].depositIds;
    }

    function getTotalValueLocked(IERC20 depositToken) external view returns (uint256 totalValueLocked) {
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i].depositToken == depositToken) {
                totalValueLocked += pools[i].getDepositsValue();
            }
        }
    }

    function getTotalValueLocked() external view returns (uint256 totalValueLocked) {
        for (uint256 i = 0; i < pools.length; i++) {
            totalValueLocked += pools[i].getDepositsValue();
        }
    }

    function deposit(
        uint256 poolId,
        uint256 amount,
        address magister
    ) public {
        if (magister == msg.sender || !(magister == address(this) || magisters[magister].isActive)) {
            revert BaksDAOMagisterBlacklisted(magister);
        }

        IERC20 baks = IERC20(core.baks());
        IERC20 voice = IERC20(core.voice());

        Pool.Data storage p = pools[poolId];
        p.depositToken.safeTransferFrom(
            msg.sender,
            (p.depositToken == baks || p.depositToken == voice) ? core.exchangeFund() : address(this),
            amount
        );

        uint256 normalizedAmount = p.depositToken.normalizeAmount(amount);
        p.depositsAmount += normalizedAmount;

        if (currentDepositIds[poolId][msg.sender] == 0) {
            if (amount == 0) {
                revert BaksDAODepositZeroAmount();
            }

            uint256 id = deposits.length;
            deposits.push(
                Deposit.Data({
                    id: id,
                    isActive: true,
                    magister: magister,
                    depositor: msg.sender,
                    poolId: poolId,
                    principal: normalizedAmount,
                    depositorTotalAccruedRewards: 0,
                    depositorWithdrawnRewards: 0,
                    magisterTotalAccruedRewards: 0,
                    magisterWithdrawnRewards: 0,
                    createdAt: block.timestamp,
                    lastDepositAt: block.timestamp,
                    lastInteractionAt: block.timestamp,
                    closedAt: 0
                })
            );

            currentDepositIds[poolId][msg.sender] = id;
            if (magister != address(this)) {
                uint256 depositTokenPrice = IPriceOracle(core.priceOracle()).getNormalizedPrice(p.depositToken);
                if (normalizedAmount.mul(depositTokenPrice) < core.minimumMagisterDepositAmount()) {
                    revert BaksDAOBelowMinimumMagisterDepositAmount();
                }

                magisters[magister].depositIds.push(id);
            }
            if (p.depositToken != baks) {
                IBank(core.bank()).onNewDeposit(p.depositToken, normalizedAmount);
            }
        } else {
            Deposit.Data storage d = deposits[currentDepositIds[poolId][msg.sender]];
            accrueRewards(d.id);

            uint256 r = d.depositorTotalAccruedRewards - d.depositorWithdrawnRewards;
            (uint256 depositorRewards, uint256 depositorBonusRewards, , ) = splitRewards(d.poolId, r, 0);
            baks.safeTransferFrom(core.exchangeFund(), d.depositor, depositorRewards);
            if (depositorBonusRewards > 0) {
                voice.safeTransferFrom(core.exchangeFund(), d.depositor, depositorBonusRewards);
            }

            d.principal += normalizedAmount;
            d.depositorWithdrawnRewards += r;
            d.lastDepositAt = block.timestamp;
            d.lastInteractionAt = block.timestamp;
        }
    }

    function getRewards(uint256 depositId) public view returns (uint256 depositorRewards, uint256 magisterRewards) {
        Deposit.Data memory d = deposits[depositId];

        (uint256 dr, uint256 mr) = calculateRewards(depositId);
        depositorRewards = dr + d.depositorTotalAccruedRewards - d.depositorWithdrawnRewards;
        magisterRewards = mr + d.magisterTotalAccruedRewards - d.magisterWithdrawnRewards;
    }

    function accrueRewards(uint256 depositId) internal {
        (uint256 depositorRewards, uint256 magisterRewards) = calculateRewards(depositId);

        Deposit.Data storage d = deposits[depositId];
        IERC20 depositToken = pools[d.poolId].depositToken;
        uint256 depositTokenPrice = depositToken == IERC20(core.baks())
            ? ONE
            : IPriceOracle(core.priceOracle()).getNormalizedPrice(depositToken);
        if (d.magister != address(this) && magisters[d.magister].isActive) {
            d.magisterTotalAccruedRewards += magisterRewards;
            magisters[d.magister].totalIncome += magisterRewards.mul(depositTokenPrice);
        }

        d.depositorTotalAccruedRewards += depositorRewards;
        if (magisters[msg.sender].isActive) {
            magisters[d.magister].totalIncome += depositorRewards.mul(depositTokenPrice);
        }
    }

    function calculateRewards(uint256 depositId)
        internal
        view
        returns (uint256 depositorRewards, uint256 magisterRewards)
    {
        Deposit.Data memory d = deposits[depositId];
        Pool.Data memory p = pools[d.poolId];

        uint256 totalRewards = d.principal.mul(
            p.calculateMultiplier(core.workFee(), block.timestamp - d.lastInteractionAt)
        );
        uint256 totalApr = p.getTotalApr();

        depositorRewards = totalRewards.mulDiv(p.getDepositorApr(), totalApr);
        magisterRewards = totalRewards.mulDiv(p.getMagisterApr(), totalApr);
    }

    function splitRewards(
        uint256 poolId,
        uint256 _depositorRewards,
        uint256 _magisterRewards
    )
        internal
        view
        returns (
            uint256 depositorRewards,
            uint256 depositorBonusRewards,
            uint256 magisterRewards,
            uint256 magisterBonusRewards
        )
    {
        IPriceOracle priceOracle = IPriceOracle(core.priceOracle());

        Pool.Data memory p = pools[poolId];

        uint256 depositorTotalApr = p.getDepositorApr();
        uint256 magisterTotalApr = p.getMagisterApr();
        uint256 depositTokenPrice = p.depositToken == IERC20(core.baks())
            ? ONE
            : priceOracle.getNormalizedPrice(p.depositToken);

        depositorRewards = _depositorRewards.mul(depositTokenPrice);
        magisterRewards = _magisterRewards.mul(depositTokenPrice);

        try priceOracle.getNormalizedPrice(IERC20(core.voice())) returns (uint256 bonusTokenPrice) {
            if (bonusTokenPrice > 0) {
                depositorBonusRewards = depositorRewards.mulDiv(
                    p.depositorBonusApr.mul(bonusTokenPrice),
                    depositorTotalApr
                );
                magisterBonusRewards = magisterRewards.mulDiv(
                    p.magisterBonusApr.mul(bonusTokenPrice),
                    magisterTotalApr
                );

                depositorRewards = depositorRewards.mulDiv(p.depositorApr, depositorTotalApr);
                magisterRewards = magisterRewards.mulDiv(p.magisterApr, magisterTotalApr);
            }
        } catch {}
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "./ERC20.sol";

interface IBank {
    function onNewDeposit(IERC20 token, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "./ERC20.sol";

interface IDepositary {
    function getTotalValueLocked() external view returns (uint256 totalValueLocked);

    function getTotalValueLocked(IERC20 depositToken) external view returns (uint256 totalValueLocked);
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

library Beneficiary {
    function split(uint256 b) internal pure returns (address beneficiary, uint256 share) {
        share = b & type(uint96).max;
        beneficiary = address(uint160(b >> 96));
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
        returns (
            Loan.Data memory loan,
            uint256 exchangeFee,
            uint256 developmentFee,
            uint256 stabilityFee
        )
    {
        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);

        uint256 restOfIssuance = principalAmount.mul(ONE - self.initialLoanToValueRatio).div(
            self.initialLoanToValueRatio
        );
        uint256 stabilizationFee = restOfIssuance.mul(self.stabilizationFee);
        exchangeFee = restOfIssuance.mul(self.exchangeFee);
        developmentFee = restOfIssuance.mul(self.developmentFee);

        uint256 collateralAmount = principalAmount.div(self.initialLoanToValueRatio.mul(collateralTokenPrice));
        stabilityFee = self.stabilityFee.mul(principalAmount).div(collateralTokenPrice);

        loan = Loan.Data({
            id: 0,
            isActive: true,
            borrower: msg.sender,
            collateralToken: self.collateralToken,
            isNativeCurrency: false,
            priceOracle: self.priceOracle,
            interest: 0,
            stabilizationFee: stabilizationFee,
            principalAmount: principalAmount,
            interestAmount: 0,
            collateralAmount: collateralAmount,
            lastInteractionAt: block.timestamp
        });
    }

    function calculateLoanByCollateralAmount(Data memory self, uint256 collateralAmount)
        internal
        view
        returns (
            Loan.Data memory loan,
            uint256 exchangeFee,
            uint256 developmentFee,
            uint256 stabilityFee
        )
    {
        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);
        uint256 principalAmount = collateralAmount.mul(self.initialLoanToValueRatio).mul(collateralTokenPrice);

        uint256 restOfIssuance = principalAmount.mul(ONE - self.initialLoanToValueRatio).div(
            self.initialLoanToValueRatio
        );
        uint256 stabilizationFee = restOfIssuance.mul(self.stabilizationFee);
        exchangeFee = restOfIssuance.mul(self.exchangeFee);
        developmentFee = restOfIssuance.mul(self.developmentFee);

        stabilityFee = self.stabilityFee.mul(principalAmount).div(collateralTokenPrice);

        loan = Loan.Data({
            id: 0,
            isActive: true,
            borrower: msg.sender,
            collateralToken: self.collateralToken,
            isNativeCurrency: false,
            priceOracle: self.priceOracle,
            stabilizationFee: stabilizationFee,
            interest: 0,
            principalAmount: principalAmount,
            interestAmount: 0,
            collateralAmount: collateralAmount,
            lastInteractionAt: block.timestamp
        });
    }

    function calculateLoanBySecurityAmount(Data memory self, uint256 securityAmount)
        internal
        view
        returns (
            Loan.Data memory loan,
            uint256 exchangeFee,
            uint256 developmentFee,
            uint256 stabilityFee
        )
    {
        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);
        uint256 c = self.stabilityFee.mul(self.initialLoanToValueRatio);
        uint256 principalAmount = securityAmount.mul(self.initialLoanToValueRatio).mul(collateralTokenPrice).div(
            c + ONE
        );
        return calculateLoanByPrincipalAmount(self, principalAmount);
    }

    function getCollateralValue(Data memory self) internal view returns (uint256 collateralValue) {
        if (self.collateralAmount == 0) {
            return 0;
        }

        uint256 collateralTokenPrice = self.priceOracle.getNormalizedPrice(self.collateralToken);
        collateralValue = self.collateralAmount.mul(collateralTokenPrice);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./FixedPointMath.sol";
import {IERC20} from "./../interfaces/ERC20.sol";
import {IPriceOracle} from "./../interfaces/IPriceOracle.sol";

library Deposit {
    using FixedPointMath for uint256;

    struct Data {
        uint256 id;
        bool isActive;
        address depositor;
        address magister;
        uint256 poolId;
        uint256 principal;
        uint256 depositorTotalAccruedRewards;
        uint256 depositorWithdrawnRewards;
        uint256 magisterTotalAccruedRewards;
        uint256 magisterWithdrawnRewards;
        uint256 createdAt;
        uint256 lastDepositAt;
        uint256 lastInteractionAt;
        uint256 closedAt;
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

import "./Math.sol";

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);
error FixedPointMathExpArgumentTooBig(uint256 a);
error FixedPointMathExp2ArgumentTooBig(uint256 a);
error FixedPointMathLog2ArgumentTooBig(uint256 a);

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant SCALE = 1e18;
    uint256 internal constant HALF_SCALE = 5e17;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;
    uint256 internal constant LOG2_E = 1_442695040888963407;

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

    function exp(uint256 x) internal pure returns (uint256 result) {
        if (x >= 133_084258667509499441) {
            revert FixedPointMathExpArgumentTooBig(x);
        }

        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    function exp2(uint256 x) internal pure returns (uint256 result) {
        if (x >= 192e18) {
            revert FixedPointMathExp2ArgumentTooBig(x);
        }

        unchecked {
            x = (x << 64) / SCALE;

            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert FixedPointMathLog2ArgumentTooBig(x);
        }
        unchecked {
            uint256 n = Math.mostSignificantBit(x / SCALE);

            result = n * SCALE;

            uint256 y = x >> n;

            if (y == SCALE) {
                return result;
            }

            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                if (y >= 2 * SCALE) {
                    result += delta;

                    y >>= 1;
                }
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./FixedPointMath.sol";
import "./Math.sol";
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
        uint256 interest;
        uint256 stabilizationFee;
        uint256 principalAmount;
        uint256 interestAmount;
        uint256 collateralAmount;
        uint256 lastInteractionAt;
    }

    uint256 internal constant ONE = 100e16;
    uint256 internal constant SECONDS_PER_YEAR = 31557600;

    function accrueInterest(Data storage self) internal {
        self.interestAmount += calculateInterest(self);
    }

    function calculateInterest(Data memory self) internal view returns (uint256 interest) {
        interest = self.principalAmount.mul(self.interest).mul(
            (block.timestamp - self.lastInteractionAt).mulDiv(ONE, SECONDS_PER_YEAR)
        );
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

        loanToValueRatio = (self.principalAmount + calculateInterest(self)).div(getCollateralValue(self));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./FixedPointMath.sol";
import {IERC20} from "./../interfaces/ERC20.sol";
import {IPriceOracle} from "./../interfaces/IPriceOracle.sol";

library Magister {
    using FixedPointMath for uint256;

    struct Data {
        bool isActive;
        uint256 createdAt;
        address addr;
        uint256 totalIncome;
        uint256[] depositIds;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library MintingStage {
    function split(uint256 mintingStage) internal pure returns (uint256 totalValueLocked, uint256 amount) {
        amount = mintingStage & type(uint128).max;
        totalValueLocked = mintingStage >> 128;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./Deposit.sol";
import "./FixedPointMath.sol";
import {IERC20} from "./../interfaces/ERC20.sol";
import {IPriceOracle} from "./../interfaces/IPriceOracle.sol";

library Pool {
    using FixedPointMath for uint256;

    struct Data {
        uint256 id;
        IERC20 depositToken;
        IPriceOracle priceOracle;
        bool isCompounding;
        uint256 depositsAmount;
        uint256 depositorApr;
        uint256 magisterApr;
        uint256 depositorBonusApr;
        uint256 magisterBonusApr;
    }

    uint256 internal constant ONE = 100e16;
    uint256 internal constant SECONDS_PER_YEAR = 31557600;

    function getDepositsValue(Data memory self) internal view returns (uint256 depositsValue) {
        if (self.depositsAmount == 0) {
            return 0;
        }

        uint256 depositTokenPrice = self.priceOracle.getNormalizedPrice(self.depositToken);
        depositsValue = self.depositsAmount.mul(depositTokenPrice);
    }

    function calculateMultiplier(
        Data memory self,
        uint256 fee,
        uint256 timeDelta
    ) internal pure returns (uint256 multiplier) {
        uint256 totalApr = getTotalApr(self);
        if (!self.isCompounding) {
            multiplier = totalApr.mul(timeDelta.mulDiv(ONE, SECONDS_PER_YEAR));
        } else {
            multiplier =
                FixedPointMath.pow(ONE + (ONE - fee).mul(totalApr).div(SECONDS_PER_YEAR * ONE), timeDelta * ONE) -
                ONE;
        }
    }

    function getDepositorApr(Data memory self) internal pure returns (uint256 depositorApr) {
        depositorApr = self.depositorApr + self.depositorBonusApr;
    }

    function getMagisterApr(Data memory self) internal pure returns (uint256 magisterApr) {
        magisterApr = self.magisterApr + self.magisterBonusApr;
    }

    function getTotalApr(Data memory self) internal pure returns (uint256 totalApr) {
        totalApr = getDepositorApr(self) + getMagisterApr(self);
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

    function initializeReentrancyGuard() internal {
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