// SPDX-License-Identifier: MIT

import './abstract/ReaperBaseStrategy.sol';
import './interfaces/IUniswapRouter.sol';
import './interfaces/CErc20I.sol';
import './interfaces/IComptroller.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

pragma solidity 0.8.9;

/**
 * @dev This strategy will deposit and leverage a token on Scream to maximize yield by farming Scream tokens
 */
contract ReaperAutoCompoundScreamLeverage is ReaperBaseStrategy {
    using SafeERC20 for IERC20;

    /**
     * @dev Tokens Used:
     * {WFTM} - Required for liquidity routing when doing swaps. Also used to charge fees on yield.
     * {SCREAM} - The reward token for farming
     * {want} - The vault token the strategy is maximizing
     * {cWant} - The Scream version of the want token
     */
    address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public constant SCREAM = 0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475;
    address public immutable want;
    CErc20I public immutable cWant;

    /**
     * @dev Third Party Contracts:
     * {UNI_ROUTER} - the UNI_ROUTER for target DEX
     * {comptroller} - Scream contract to enter market and to claim Scream tokens
     */
    address public constant UNI_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    IComptroller public immutable comptroller;

    /**
     * @dev Routes we take to swap tokens
     * {screamToWftmRoute} - Route we take to get from {SCREAM} into {WFTM}.
     * {wftmToWantRoute} - Route we take to get from {WFTM} into {want}.
     */
    address[] public screamToWftmRoute = [SCREAM, WFTM];
    address[] public wftmToWantRoute;

    /**
     * @dev Scream variables
     * {markets} - Contains the Scream tokens to farm, used to enter markets and claim Scream
     * {MANTISSA} - The unit used by the Compound protocol
     */
    address[] public markets;
    uint256 public constant MANTISSA = 1e18;

    /**
     * @dev Strategy variables
     * {targetLTV} - The target loan to value for the strategy where 1 ether = 100%
     * {allowedLTVDrift} - How much the strategy can deviate from the target ltv where 0.01 ether = 1%
     * {balanceOfPool} - The total balance deposited into Scream (supplied - borrowed)
     * {borrowDepth} - The maximum amount of loops used to leverage and deleverage
     * {minWantToLeverage} - The minimum amount of want to leverage in a loop
     */
    uint256 public targetLTV = 0.73 ether;
    uint256 public allowedLTVDrift = 0.01 ether;
    uint256 public balanceOfPool = 0;
    uint256 public borrowDepth = 12;
    uint256 public minWantToLeverage = 1000;
    uint256 public constant MAX_BORROW_DEPTH = 15;
    uint256 public minScreamToSell = 0.01 ether;

    /**
     * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
     * @notice see documentation for each variable above its respective declaration.
     */
    constructor(
        address _vault,
        address[] memory _feeRemitters,
        address[] memory _strategists,
        address _scWant
    ) ReaperBaseStrategy(_vault, _feeRemitters, _strategists) {
        cWant = CErc20I(_scWant);
        markets = [_scWant];
        comptroller = IComptroller(cWant.comptroller());
        want = cWant.underlying();
        wftmToWantRoute = [WFTM, want];

        _giveAllowances();

        comptroller.enterMarkets(markets);
    }

    /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {want} from Scream
     * The available {want} minus fees is returned to the vault.
     */
    function withdraw(uint256 _withdrawAmount) external {
        require(msg.sender == vault, '!vault');

        uint256 _ltv = _calculateLTVAfterWithdraw(_withdrawAmount);

        if (_shouldLeverage(_ltv)) {
            // Strategy is underleveraged so can withdraw underlying directly
            _withdrawUnderlyingToVault(_withdrawAmount, true);
            _leverMax();
        } else if (_shouldDeleverage(_ltv)) {
            _deleverage(_withdrawAmount);

            // Strategy has deleveraged to the point where it can withdraw underlying
            _withdrawUnderlyingToVault(_withdrawAmount, true);
        } else {
            // LTV is in the acceptable range so the underlying can be withdrawn directly
            _withdrawUnderlyingToVault(_withdrawAmount, true);
        }
        updateBalance();
    }

    /**
     * @dev Calculates the LTV using existing exchange rate,
     * depends on the cWant being updated to be accurate.
     * Does not update in order provide a view function for LTV.
     */
    function calculateLTV() external view returns (uint256 ltv) {
        (, uint256 cWantBalance, uint256 borrowed, uint256 exchangeRate) = cWant.getAccountSnapshot(address(this));

        uint256 supplied = (cWantBalance * exchangeRate) / MANTISSA;

        if (supplied == 0 || borrowed == 0) {
            return 0;
        }

        ltv = (MANTISSA * borrowed) / supplied;
    }

    /**
     * @dev Returns the approx amount of profit from harvesting.
     *      Profit is denominated in WFTM, and takes fees into account.
     */
    function estimateHarvest() external view override returns (uint256 profit, uint256 callFeeToUser) {
        uint256 rewards = comptroller.compAccrued(address(this));
        if (rewards == 0) {
            return (0, 0);
        }
        profit = IUniswapRouter(UNI_ROUTER).getAmountsOut(rewards, screamToWftmRoute)[1];
        uint256 wftmFee = (profit * totalFee) / PERCENT_DIVISOR;
        callFeeToUser = (wftmFee * callFee) / PERCENT_DIVISOR;
        profit -= wftmFee;
    }

    /**
     * @dev Emergency function to deleverage in case regular deleveraging breaks
     */
    function manualDeleverage(uint256 amount) external {
        _onlyStrategistOrOwner();
        require(cWant.redeemUnderlying(amount) == 0, 'Scream returned an error');
        require(cWant.repayBorrow(amount) == 0, 'Scream returned an error');
    }

    /**
     * @dev Emergency function to deleverage in case regular deleveraging breaks
     */
    function manualReleaseWant(uint256 amount) external {
        _onlyStrategistOrOwner();
        require(cWant.redeemUnderlying(amount) == 0, 'Scream returned an error');
    }

    /**
     * @dev Sets a new LTV for leveraging.
     * Should be in units of 1e18
     */
    function setTargetLtv(uint256 _ltv) external {
        _onlyStrategistOrOwner();
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cWant));
        require(collateralFactorMantissa > _ltv + allowedLTVDrift, 'Ltv above max level');
        targetLTV = _ltv;
    }

    /**
     * @dev Sets a new allowed LTV drift
     * Should be in units of 1e18
     */
    function setAllowedLtvDrift(uint256 _drift) external {
        _onlyStrategistOrOwner();
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cWant));
        require(collateralFactorMantissa > targetLTV + _drift, 'Ltv above max level');
        allowedLTVDrift = _drift;
    }

    /**
     * @dev Sets a new borrow depth (how many loops for leveraging+deleveraging)
     */
    function setBorrowDepth(uint8 _borrowDepth) external {
        _onlyStrategistOrOwner();
        require(_borrowDepth <= MAX_BORROW_DEPTH, 'Above max borrow depth');
        borrowDepth = _borrowDepth;
    }

    /**
     * @dev Sets the minimum reward the will be sold (too little causes revert from Uniswap)
     */
    function setMinCompToSell(uint256 _minScreamToSell) external {
        _onlyStrategistOrOwner();
        minScreamToSell = _minScreamToSell;
    }

    /**
     * @dev Function that has to be called as part of strat migration. It sends all the available funds back to the
     * vault, ready to be migrated to the new strat.
     */
    function retireStrat() external {
        require(msg.sender == vault, '!vault');
        _claimRewards();
        _swapRewardsToWftm();
        _swapToWant();

        uint256 maxAmount = type(uint256).max;
        _deleverage(maxAmount);
        _withdrawUnderlyingToVault(maxAmount, false);
    }

    /**
     * @dev Pauses supplied. Withdraws all funds from the AceLab contract, leaving rewards behind.
     */
    function panic() external {
        _onlyStrategistOrOwner();

        uint256 maxAmount = type(uint256).max;
        _deleverage(maxAmount);
        _withdrawUnderlyingToVault(maxAmount, false);

        pause();
    }

    /**
     * @dev Unpauses the strat.
     */
    function unpause() external {
        _onlyStrategistOrOwner();
        _unpause();

        _giveAllowances();

        deposit();
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() public {
        _onlyStrategistOrOwner();
        _pause();
        _removeAllowances();
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone supplied in the strategy's vault contract.
     * It supplies {want} Scream to farm {SCREAM}
     */
    function deposit() public whenNotPaused {
        CErc20I(cWant).mint(balanceOfWant());
        uint256 _ltv = _calculateLTV();

        if (_shouldLeverage(_ltv)) {
            _leverMax();
        } else if (_shouldDeleverage(_ltv)) {
            _deleverage(0);
        }
        updateBalance();
    }

    /**
     * @dev Calculates the total amount of {want} held by the strategy
     * which is the balance of want + the total amount supplied to Scream.
     */
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool;
    }

    /**
     * @dev Calculates the balance of want held directly by the strategy
     */
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    /**
     * @dev Calculates how many blocks until we are in liquidation based on current interest rates
     * WARNING does not include compounding so the estimate becomes more innacurate the further ahead we look
     * Compound doesn't include compounding for most blocks
     * Equation: ((supplied*colateralThreshold - borrowed) / (borrowed*borrowrate - supplied*colateralThreshold*interestrate));
     */
    function getblocksUntilLiquidation() public view returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cWant));

        (uint256 supplied, uint256 borrowed) = getCurrentPosition();

        uint256 borrrowRate = cWant.borrowRatePerBlock();

        uint256 supplyRate = cWant.supplyRatePerBlock();

        uint256 collateralisedDeposit = (supplied * collateralFactorMantissa) / MANTISSA;

        uint256 borrowCost = borrowed * borrrowRate;
        uint256 supplyGain = collateralisedDeposit * supplyRate;

        if (supplyGain >= borrowCost) {
            return type(uint256).max;
        } else {
            uint256 netSupplied = collateralisedDeposit - borrowed;
            uint256 totalCost = borrowCost - supplyGain;
            //minus 1 for this block
            return (netSupplied * MANTISSA) / totalCost;
        }
    }

    /**
     * @dev Returns the current position in Scream. Does not accrue interest
     * so might not be accurate, but the cWant is usually updated.
     */
    function getCurrentPosition() public view returns (uint256 supplied, uint256 borrowed) {
        (, uint256 cWantBalance, uint256 borrowBalance, uint256 exchangeRate) = cWant.getAccountSnapshot(address(this));
        borrowed = borrowBalance;

        supplied = (cWantBalance * exchangeRate) / MANTISSA;
    }

    /**
     * @dev Updates the balance. This is the state changing version so it sets
     * balanceOfPool to the latest value.
     */
    function updateBalance() public {
        uint256 supplyBalance = CErc20I(cWant).balanceOfUnderlying(address(this));
        uint256 borrowBalance = CErc20I(cWant).borrowBalanceCurrent(address(this));
        balanceOfPool = supplyBalance - borrowBalance;
    }

    /**
     * @dev Levers the strategy up to the targetLTV
     */
    function _leverMax() internal {
        uint256 supplied = cWant.balanceOfUnderlying(address(this));
        uint256 borrowed = cWant.borrowBalanceStored(address(this));

        uint256 realSupply = supplied - borrowed;
        uint256 newBorrow = _getMaxBorrowFromSupplied(realSupply, targetLTV);
        uint256 totalAmountToBorrow = newBorrow - borrowed;

        for (uint8 i = 0; i < borrowDepth && totalAmountToBorrow > minWantToLeverage; i++) {
            totalAmountToBorrow = totalAmountToBorrow - _leverUpStep(totalAmountToBorrow);
        }
    }

    /**
     * @dev Does one step of leveraging
     */
    function _leverUpStep(uint256 _withdrawAmount) internal returns (uint256) {
        if (_withdrawAmount == 0) {
            return 0;
        }

        uint256 supplied = cWant.balanceOfUnderlying(address(this));
        uint256 borrowed = cWant.borrowBalanceStored(address(this));
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cWant));
        uint256 canBorrow = (supplied * collateralFactorMantissa) / MANTISSA;

        canBorrow -= borrowed;

        if (canBorrow < _withdrawAmount) {
            _withdrawAmount = canBorrow;
        }

        if (_withdrawAmount > 10) {
            // borrow available amount
            CErc20I(cWant).borrow(_withdrawAmount);

            // deposit available want as collateral
            CErc20I(cWant).mint(balanceOfWant());
        }

        return _withdrawAmount;
    }

    /**
     * @dev Gets the maximum amount allowed to be borrowed for a given collateral factor and amount supplied
     */
    function _getMaxBorrowFromSupplied(uint256 wantSupplied, uint256 collateralFactor) internal pure returns (uint256) {
        return ((wantSupplied * collateralFactor) / (MANTISSA - collateralFactor));
    }

    /**
     * @dev Returns if the strategy should leverage with the given ltv level
     */
    function _shouldLeverage(uint256 _ltv) internal view returns (bool) {
        if (_ltv < targetLTV - allowedLTVDrift) {
            return true;
        }
        return false;
    }

    /**
     * @dev Returns if the strategy should deleverage with the given ltv level
     */
    function _shouldDeleverage(uint256 _ltv) internal view returns (bool) {
        if (_ltv > targetLTV + allowedLTVDrift) {
            return true;
        }
        return false;
    }

    /**
     * @dev This is the state changing calculation of LTV that is more accurate
     * to be used internally.
     */
    function _calculateLTV() internal returns (uint256 ltv) {
        uint256 supplied = cWant.balanceOfUnderlying(address(this));
        uint256 borrowed = cWant.borrowBalanceStored(address(this));

        if (supplied == 0 || borrowed == 0) {
            return 0;
        }
        ltv = (MANTISSA * borrowed) / supplied;
    }

    /**
     * @dev Calculates what the LTV will be after withdrawing
     */
    function _calculateLTVAfterWithdraw(uint256 _withdrawAmount) internal returns (uint256 ltv) {
        uint256 supplied = cWant.balanceOfUnderlying(address(this));
        uint256 borrowed = cWant.borrowBalanceStored(address(this));
        supplied = supplied - _withdrawAmount;

        if (supplied == 0 || borrowed == 0) {
            return 0;
        }
        ltv = (uint256(1e18) * borrowed) / supplied;
    }

    /**
     * @dev Withdraws want to the vault by redeeming the underlying
     */
    function _withdrawUnderlyingToVault(uint256 _withdrawAmount, bool _useWithdrawFee) internal {
        uint256 supplied = cWant.balanceOfUnderlying(address(this));
        uint256 borrowed = cWant.borrowBalanceStored(address(this));
        uint256 realSupplied = supplied - borrowed;

        if (realSupplied == 0) {
            return;
        }

        if (_withdrawAmount > realSupplied) {
            _withdrawAmount = realSupplied;
        }

        uint256 tempColla = targetLTV;

        uint256 reservedAmount = 0;
        if (tempColla == 0) {
            tempColla = 1e15; // 0.001 * 1e18. lower we have issues
        }

        reservedAmount = (borrowed * MANTISSA) / tempColla;
        if (supplied >= reservedAmount) {
            uint256 redeemable = supplied - reservedAmount;
            uint256 balance = cWant.balanceOf(address(this));
            if (balance > 1) {
                if (redeemable < _withdrawAmount) {
                    _withdrawAmount = redeemable;
                }
            }
        }

        uint256 withdrawAmount;

        if (_useWithdrawFee) {
            uint256 withdrawFee = (_withdrawAmount * securityFee) / PERCENT_DIVISOR;
            withdrawAmount = _withdrawAmount - withdrawFee - 1;
        } else {
            withdrawAmount = _withdrawAmount - 1;
        }

        CErc20I(cWant).redeemUnderlying(withdrawAmount);
        IERC20(want).safeTransfer(vault, withdrawAmount);
    }

    /**
     * @dev For a given withdraw amount, figures out the new borrow with the current supply
     * that will maintain the target LTV
     */
    function _getDesiredBorrow(uint256 _withdrawAmount) internal returns (uint256 position) {
        //we want to use statechanging for safety
        uint256 supplied = cWant.balanceOfUnderlying(address(this));
        uint256 borrowed = cWant.borrowBalanceStored(address(this));

        //When we unwind we end up with the difference between borrow and supply
        uint256 unwoundSupplied = supplied - borrowed;

        //we want to see how close to collateral target we are.
        //So we take our unwound supplied and add or remove the _withdrawAmount we are are adding/removing.
        //This gives us our desired future undwoundDeposit (desired supply)

        uint256 desiredSupply = 0;
        if (_withdrawAmount > unwoundSupplied) {
            _withdrawAmount = unwoundSupplied;
        }
        desiredSupply = unwoundSupplied - _withdrawAmount;

        //(ds *c)/(1-c)
        uint256 num = desiredSupply * targetLTV;
        uint256 den = MANTISSA - targetLTV;

        uint256 desiredBorrow = num / den;
        if (desiredBorrow > 1e5) {
            //stop us going right up to the wire
            desiredBorrow = desiredBorrow - 1e5;
        }

        position = borrowed - desiredBorrow;
    }

    /**
     * @dev For a given withdraw amount, deleverages to a borrow level
     * that will maintain the target LTV
     */
    function _deleverage(uint256 _withdrawAmount) internal {
        uint256 newBorrow = _getDesiredBorrow(_withdrawAmount);

        // //If there is no deficit we dont need to adjust position
        // //if the position change is tiny do nothing
        if (newBorrow > minWantToLeverage) {
            uint256 i = 0;
            while (newBorrow > minWantToLeverage + 100) {
                newBorrow = newBorrow - _leverDownStep(newBorrow);
                i++;
                //A limit set so we don't run out of gas
                if (i >= borrowDepth) {
                    break;
                }
            }
        }
    }

    /**
     * @dev Deleverages one step
     */
    function _leverDownStep(uint256 maxDeleverage) internal returns (uint256 deleveragedAmount) {
        uint256 minAllowedSupply = 0;
        uint256 supplied = cWant.balanceOfUnderlying(address(this));
        uint256 borrowed = cWant.borrowBalanceStored(address(this));
        (, uint256 collateralFactorMantissa, ) = comptroller.markets(address(cWant));

        //collat ration should never be 0. if it is something is very wrong... but just incase
        if (collateralFactorMantissa != 0) {
            minAllowedSupply = (borrowed * MANTISSA) / collateralFactorMantissa;
        }
        uint256 maxAllowedDeleverageAmount = supplied - minAllowedSupply;

        deleveragedAmount = maxAllowedDeleverageAmount;

        if (deleveragedAmount >= borrowed) {
            deleveragedAmount = borrowed;
        }
        if (deleveragedAmount >= maxDeleverage) {
            deleveragedAmount = maxDeleverage;
        }
        uint256 exchangeRateStored = cWant.exchangeRateStored();
        //redeemTokens = redeemAmountIn * 1e18 / exchangeRate. must be more than 0
        //a rounding error means we need another small addition
        if (deleveragedAmount * MANTISSA >= exchangeRateStored && deleveragedAmount > 10) {
            deleveragedAmount -= 10; // Amount can be slightly off for tokens with less decimals (USDC), so redeem a bit less
            cWant.redeemUnderlying(deleveragedAmount);
            //our borrow has been increased by no more than maxDeleverage
            cWant.repayBorrow(deleveragedAmount);
        }
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * @notice Assumes the deposit will take care of the TVL rebalancing.
     * 1. Claims {SCREAM} from the comptroller.
     * 2. Swaps {SCREAM} to {WFTM}.
     * 3. Claims fees for the harvest caller and treasury.
     * 4. Swaps the {WFTM} token for {want}
     * 5. Deposits.
     */
    function _harvestCore() internal override {
        _claimRewards();
        _swapRewardsToWftm();
        _chargeFees();
        _swapToWant();
        deposit();
    }

    /**
     * @dev Core harvest function.
     * Get rewards from markets entered
     */
    function _claimRewards() internal {
        CTokenI[] memory tokens = new CTokenI[](1);
        tokens[0] = cWant;

        comptroller.claimComp(address(this), tokens);
    }

    /**
     * @dev Core harvest function.
     * Swaps {SCREAM} to {WFTM}
     */
    function _swapRewardsToWftm() internal {
        uint256 screamBalance = IERC20(SCREAM).balanceOf(address(this));
        if (screamBalance >= minScreamToSell) {
            IUniswapRouter(UNI_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                screamBalance,
                0,
                screamToWftmRoute,
                address(this),
                block.timestamp + 600
            );
        }
    }

    /**
     * @dev Core harvest function.
     * Charges fees based on the amount of WFTM gained from reward
     */
    function _chargeFees() internal {
        uint256 wftmFee = (IERC20(WFTM).balanceOf(address(this)) * totalFee) / PERCENT_DIVISOR;
        if (wftmFee != 0) {
            uint256 callFeeToUser = (wftmFee * callFee) / PERCENT_DIVISOR;
            uint256 treasuryFeeToVault = (wftmFee * treasuryFee) / PERCENT_DIVISOR;
            uint256 feeToStrategist = (treasuryFeeToVault * strategistFee) / PERCENT_DIVISOR;
            treasuryFeeToVault -= feeToStrategist;

            IERC20(WFTM).safeTransfer(msg.sender, callFeeToUser);
            IERC20(WFTM).safeTransfer(treasury, treasuryFeeToVault);
            IERC20(WFTM).safeTransfer(strategistRemitter, feeToStrategist);
        }
    }

    /**
     * @dev Core harvest function.
     * Swaps {WFTM} for {want}
     */
    function _swapToWant() internal {
        uint256 wftmBalance = IERC20(WFTM).balanceOf(address(this));
        if (wftmBalance != 0) {
            IUniswapRouter(UNI_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                wftmBalance,
                0,
                wftmToWantRoute,
                address(this),
                block.timestamp + 600
            );
        }
    }

    /**
     * @dev Gives the necessary allowances to mint cWant, swap rewards etc
     */
    function _giveAllowances() internal {
        IERC20(want).safeApprove(address(cWant), 0);
        IERC20(WFTM).safeApprove(UNI_ROUTER, 0);
        IERC20(SCREAM).safeApprove(UNI_ROUTER, 0);
        IERC20(want).safeApprove(address(cWant), type(uint256).max);
        IERC20(WFTM).safeApprove(UNI_ROUTER, type(uint256).max);
        IERC20(SCREAM).safeApprove(UNI_ROUTER, type(uint256).max);
    }

    /**
     * @dev Removes all allowance that were given
     */
    function _removeAllowances() internal {
        IERC20(want).safeApprove(address(cWant), 0);
        IERC20(WFTM).safeApprove(UNI_ROUTER, 0);
        IERC20(SCREAM).safeApprove(UNI_ROUTER, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IStrategy.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract ReaperBaseStrategy is
    AccessControlEnumerable,
    Pausable,
    IStrategy
{
    uint256 public constant PERCENT_DIVISOR = 10_000;
    uint256 public constant ONE_YEAR = 365 days;

    struct Harvest {
        uint256 timestamp;
        int256 profit;
        uint256 tvl; // doesn't include profit
        uint256 timeSinceLastHarvest;
    }

    Harvest[] public harvestLog;
    uint256 public harvestLogCadence = 10 minutes;
    uint256 public lastHarvestTimestamp;

    /**
     * Reaper Roles
     */
    bytes32 public constant STRATEGIST = keccak256("STRATEGIST");
    bytes32 public constant STRATEGIST_MULTISIG =
        keccak256("STRATEGIST_MULTISIG");

    /**
     * @dev Reaper contracts:
     * {treasury} - Address of the Reaper treasury
     * {vault} - Address of the vault that controls the strategy's funds.
     * {strategistRemitter} - Address where strategist fee is remitted to.
     *                        Must be an IPaymentRouter contract.
     */
    address public treasury;
    address public immutable vault;
    address public strategistRemitter;

    /**
     * Fee related constants:
     * {MAX_FEE} - Maximum fee allowed by the strategy. Hard-capped at 10%.
     * {STRATEGIST_MAX_FEE} - Maximum strategist fee allowed by the strategy (as % of treasury fee).
     *                        Hard-capped at 50%
     * {MAX_SECURITY_FEE} - Maximum security fee charged on withdrawal to prevent
     *                      flash deposit/harvest attacks.
     */
    uint256 public constant MAX_FEE = 1000;
    uint256 public constant STRATEGIST_MAX_FEE = 5000;
    uint256 public constant MAX_SECURITY_FEE = 10;

    /**
     * @dev Distribution of fees earned, expressed as % of the profit from each harvest.
     * {totalFee} - divided by 10,000 to determine the % fee. Set to 4.5% by default and
     * lowered as necessary to provide users with the most competitive APY.
     *
     * {callFee} - Percent of the totalFee reserved for the harvester (1000 = 10% of total fee: 0.45% by default)
     * {treasuryFee} - Percent of the totalFee taken by maintainers of the software (9000 = 90% of total fee: 4.05% by default)
     * {strategistFee} - Percent of the treasuryFee taken by strategist (2500 = 25% of treasury fee: 1.0125% by default)
     *
     * {securityFee} - Fee taxed when a user withdraws funds. Taken to prevent flash deposit/harvest attacks.
     * These funds are redistributed to stakers in the pool.
     */
    uint256 public totalFee = 450;
    uint256 public callFee = 1000;
    uint256 public treasuryFee = 9000;
    uint256 public strategistFee = 2500;
    uint256 public securityFee = 10;

    /**
     * {TotalFeeUpdated} Event that is fired each time the total fee is updated.
     * {FeesUpdated} Event that is fired each time callFee+treasuryFee+strategistFee are updated.
     * {StratHarvest} Event that is fired each time the strategy gets harvested.
     * {StrategistRemitterUpdated} Event that is fired each time the strategistRemitter address is updated.
     */
    event TotalFeeUpdated(uint256 newFee);
    event FeesUpdated(
        uint256 newCallFee,
        uint256 newTreasuryFee,
        uint256 newStrategistFee
    );
    event StratHarvest(address indexed harvester);
    event StrategistRemitterUpdated(address newStrategistRemitter);

    constructor(
        address _vault,
        address[] memory _feeRemitters,
        address[] memory _strategists
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        vault = _vault;
        treasury = _feeRemitters[0];
        strategistRemitter = _feeRemitters[1];

        for (uint256 i = 0; i < _strategists.length; i++) {
            _grantRole(STRATEGIST, _strategists[i]);
        }
    }

    /**
     * @dev harvest() function that takes care of logging. Subcontracts should
     *      override _harvestCore() and implement their specific logic in it.
     */
    function harvest() external override whenNotPaused {
        uint256 startingTvl = balanceOf();

        _harvestCore();

        if (
            harvestLog.length == 0 ||
            block.timestamp >=
            harvestLog[harvestLog.length - 1].timestamp + harvestLogCadence
        ) {
            uint256 endingTvl = balanceOf();
            int256 profit;

            if (endingTvl < startingTvl) {
                profit = -int256(startingTvl - endingTvl);
            } else {
                profit = int256(endingTvl - startingTvl);
            }

            harvestLog.push(
                Harvest({
                    timestamp: block.timestamp,
                    profit: profit,
                    tvl: startingTvl,
                    timeSinceLastHarvest: block.timestamp - lastHarvestTimestamp
                })
            );
        }

        lastHarvestTimestamp = block.timestamp;
        emit StratHarvest(msg.sender);
    }

    function harvestLogLength() external view returns (uint256) {
        return harvestLog.length;
    }

    /**
     * @dev Returns a slice of the harvest log containing the _n latest harvests.
     */
    function latestHarvestLogSlice(uint256 _n)
        external
        view
        returns (Harvest[] memory slice)
    {
        slice = new Harvest[](_n);
        uint256 sliceCounter = 0;

        for (uint256 i = harvestLog.length - _n; i < harvestLog.length; i++) {
            slice[sliceCounter++] = harvestLog[i];
        }
    }

    /**
     * @dev Traverses the harvest log backwards until it hits _timestamp,
     *      and returns the average APR calculated across all the included
     *      log entries. APR is multiplied by PERCENT_DIVISOR to retain precision.
     *
     * Note: will never hit the first log since that won't really have a proper
     * timeSinceLastHarvest
     */
    function averageAPRSince(uint256 _timestamp)
        external
        view
        returns (int256)
    {
        int256 runningAPRSum;
        int256 numLogsProcessed;

        for (
            uint256 i = harvestLog.length - 1;
            i > 0 && harvestLog[i].timestamp >= _timestamp;
            i--
        ) {
            runningAPRSum += _getAPRForLog(harvestLog[i]);
            numLogsProcessed++;
        }

        return runningAPRSum / numLogsProcessed;
    }

    /**
     * @dev Traverses the harvest log backwards _n items,
     *      and returns the average APR calculated across all the included
     *      log entries. APR is multiplied by PERCENT_DIVISOR to retain precision.
     *
     * Note: will never hit the first log since that won't really have a proper
     * timeSinceLastHarvest
     */
    function averageAPRAcrossLastNHarvests(int256 _n)
        external
        view
        returns (int256)
    {
        int256 runningAPRSum;
        int256 numLogsProcessed;

        for (
            uint256 i = harvestLog.length - 1;
            i > 0 && numLogsProcessed < _n;
            i--
        ) {
            runningAPRSum += _getAPRForLog(harvestLog[i]);
            numLogsProcessed++;
        }

        return runningAPRSum / numLogsProcessed;
    }

    /**
     * @dev Only strategist or owner can edit the log cadence.
     */
    function updateHarvestLogCadence(uint256 _newCadenceInSeconds) external {
        _onlyStrategistOrOwner();
        harvestLogCadence = _newCadenceInSeconds;
    }

    /**
     * @dev updates the total fee, capped at 5%; only owner.
     */
    function updateTotalFee(uint256 _totalFee)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_totalFee <= MAX_FEE, "Fee Too High");
        totalFee = _totalFee;
        emit TotalFeeUpdated(totalFee);
    }

    /**
     * @dev updates the call fee, treasury fee, and strategist fee
     *      call Fee + treasury Fee must add up to PERCENT_DIVISOR
     *
     *      strategist fee is expressed as % of the treasury fee and
     *      must be no more than STRATEGIST_MAX_FEE
     *
     *      only owner
     */
    function updateFees(
        uint256 _callFee,
        uint256 _treasuryFee,
        uint256 _strategistFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(
            _callFee + _treasuryFee == PERCENT_DIVISOR,
            "sum != PERCENT_DIVISOR"
        );
        require(
            _strategistFee <= STRATEGIST_MAX_FEE,
            "strategist fee > STRATEGIST_MAX_FEE"
        );

        callFee = _callFee;
        treasuryFee = _treasuryFee;
        strategistFee = _strategistFee;
        emit FeesUpdated(callFee, treasuryFee, strategistFee);
        return true;
    }

    function updateSecurityFee(uint256 _securityFee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_securityFee <= MAX_SECURITY_FEE, "fee to high!");
        securityFee = _securityFee;
    }

    /**
     * @dev only owner can update treasury address.
     */
    function updateTreasury(address newTreasury)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        treasury = newTreasury;
        return true;
    }

    /**
     * @dev Updates the current strategistRemitter.
     *      If there is only one strategist this function may be called by
     *      that strategist. However if there are multiple strategists
     *      this function may only be called by the STRATEGIST_MULTISIG role.
     */
    function updateStrategistRemitter(address _newStrategistRemitter) external {
        if (getRoleMemberCount(STRATEGIST) == 1) {
            _checkRole(STRATEGIST, msg.sender);
        } else {
            _checkRole(STRATEGIST_MULTISIG, msg.sender);
        }

        require(_newStrategistRemitter != address(0), "!0");
        strategistRemitter = _newStrategistRemitter;
        emit StrategistRemitterUpdated(_newStrategistRemitter);
    }

    /**
     * @dev Only allow access to strategist or owner
     */
    function _onlyStrategistOrOwner() internal view {
        require(
            hasRole(STRATEGIST, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Not authorized"
        );
    }

    function _getAPRForLog(Harvest storage log) internal view returns (int256) {
        uint256 unsignedProfit;
        if (log.profit < 0) {
            unsignedProfit = uint256(-log.profit);
        } else {
            unsignedProfit = uint256(log.profit);
        }

        uint256 projectedYearlyUnsignedProfit = (unsignedProfit * ONE_YEAR) /
            log.timeSinceLastHarvest;
        uint256 unsignedAPR = (projectedYearlyUnsignedProfit *
            PERCENT_DIVISOR) / log.tvl;

        if (log.profit < 0) {
            return -int256(unsignedAPR);
        }

        return int256(unsignedAPR);
    }

    /**
     * @dev Returns the approx amount of profit from harvesting plus fee that
     *      would be returned to harvest caller.
     */
    function estimateHarvest()
        external
        view
        virtual
        returns (uint256 profit, uint256 callFeeToUser);

    function balanceOf() public view virtual override returns (uint256);

    /**
     * @dev subclasses should add their custom harvesting logic in this function
     *      including charging any fees.
     */
    function _harvestCore() internal virtual;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.9;

interface IStrategy {
    //deposits all funds into the farm
    function deposit() external;

    //vault only - withdraws funds from the strategy
    function withdraw(uint256 _amount) external;

    //returns the balance of all tokens managed by the strategy
    function balanceOf() external view returns (uint256);

    //claims farmed tokens, distributes fees, and sells tokens to re-add to the LP & farm
    function harvest() external;

    //withdraws all tokens and sends them back to the vault
    function retireStrat() external;

    //pauses deposits, resets allowances, and withdraws all funds from farm
    function panic() external;

    //pauses deposits and resets allowances
    function pause() external;

    //unpauses deposits and maxes out allowances again
    function unpause() external;

    //updates Total Fee
    function updateTotalFee(uint256 _totalFee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IUniswapRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./CTokenI.sol";

interface CErc20I is CTokenI {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        CTokenI cTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);

    function comptroller() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./InterestRateModel.sol";

interface CTokenI {
    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(
        uint256 oldReserveFactorMantissa,
        uint256 newReserveFactorMantissa
    );

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(
        address benefactor,
        uint256 addAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(
        address admin,
        uint256 reduceAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function interestRateModel() external view returns (InterestRateModel);

    function totalReserves() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface InterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256, uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './CTokenI.sol';
interface IComptroller {
    function compAccrued(address user) external view returns (uint256 amount);
    function claimComp(address holder, CTokenI[] memory _scTokens) external;
    function claimComp(address holder) external;
    function enterMarkets(address[] memory _scTokens) external;
    function pendingComptrollerImplementation() view external returns (address implementation);
    function markets(address ctoken)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}