// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IMarket.sol';
import '../interfaces/IPositionNFT.sol';
import '../interfaces/IHue.sol';
import '../interfaces/ILendHue.sol';
import '../interfaces/IAccounting.sol';
import '../interfaces/IRates.sol';
import '../utils/LocksProtocol.sol';
import '../utils/Time.sol';
import '../utils/SafeMath.sol';
import '../utils/TcpSafeMath.sol';
import '../utils/TcpSafeCast.sol';

import '@openzeppelin/contracts/math/SignedSafeMath.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

/**
 * @title Market
 *
 * @notice Market is responsible for allowing users to borrow Hue and pay it back,
 * charging positive interest on positions, paying negative interest to borrowers,
 * and distributing TCP to those that borrow. Market is also responsible for allowing
 * Hue holders to lend Hue back to the protocol for a portion of positive interest charged
 * to borrowers.
 *
 *  If you are a borrower, call claimRewards up to once every hour to claim your rewards.
 *  It is not necessary to call the function every hour as rewards will continue to accrue
 *    and will automatically be claimed as part of increasing or decreasing a position.
 */
contract Market is IMarket, LocksProtocol, PeriodTime {
    using SafeMath64 for uint64;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using TcpSafeMath for uint256;
    using TcpSafeCast for uint256;

    /// @notice The minimum ratio of collateral value to debt. Can be updated by governance.
    uint public override collateralizationRequirement = 1.5e18; // 150%

    /*
     * @notice The minimum number of Hue that must be borrowed in a position, if not 0.
     * This ensures that there is an incentive to liquidate given high gas prices.
     */
    uint public minPositionSize = 2500e18;

    /*
     * @notice The percentage of positive interest on debt that will go to those lending Hue
     * back to the protocol.
     */
    uint public interestPortionToLenders = 0.2e18;

    /// @dev The ERC721 that tokenizes collateralized debt positions.
    IPositionNFT public immutable huePositionNFT;
    /// @dev The token of the system
    IHue public immutable hue;
    /// @dev The ERC20 that is issued as a claim to lent Hue.
    ILendHue public immutable lendHue;
    /// @dev The ERC20 that is issued as a claim to lent Hue.
    IAccounting public immutable accounting;
    /// @dev The standard decimals, used for eth and for all other tokens in this system
    uint8 internal constant STANDARD_DECIMALS = 18;

    /// @notice Number of seconds for twap calculating prices used in this module.
    uint32 public twapDuration = 30 minutes;

    /// @dev The length of an interest period
    uint64 internal constant PERIOD_LENGTH = 1 hours;
    /// @dev The minimum amount of time between borrow and payback. This prevents flash borrowing,
    ///   and ensures that all position pay thier fair share of interest.
    uint64 internal constant MIN_BORROW_TIME = PERIOD_LENGTH + (30 minutes);
    /// @dev Count market interest periods per year.
    uint64 internal constant PERIODS_PER_YEAR = (365 days) / PERIOD_LENGTH;
    /// @dev Count market interest periods per day.
    uint64 internal constant PERIODS_PER_DAY = (1 days) / PERIOD_LENGTH;
    /// @dev The last period that interest was accrued. The period at protocol launch is 1, increasing by 1 every hour.
    uint64 public override lastPeriodGlobalInterestAccrued;

    address public deployer;

    constructor(ConstructorParams memory params) LocksProtocol(
        params.Governor,
        params.ProtocolLock
    ) PeriodTime (PERIOD_LENGTH) {
        huePositionNFT = params.HuePositionNFT;
        hue = params.Hue;
        lendHue = params.LendHue;
        accounting = params.Accounting;

        // define valid governance actions
        bytes4[4] memory validUpdates = [
            Market.setCollateralizationRequirement.selector,
            Market.setTwapDuration.selector,
            Market.setMinPositionSize.selector,
            Market.setInterestPortionToLenders.selector];
        for(uint i = 0; i < validUpdates.length; i++) validUpdate[validUpdates[i]] = true;

        deployer = msg.sender;
    }

    function init() external {
        _requireAuthorized(msg.sender == deployer);
        delete deployer;

        // assign the liquidation account, position 0, to accounting
        require(huePositionNFT.mintTo(address(accounting)) == 0);

        // initialize the liquidation account
        IAccounting.DebtPosition memory dp;
        accounting.setPosition(0, _updatePosition(0, dp));
    }

    /*****************************************************
     * ================ LEND INTERFACE ================= *
     *****************************************************/
    /**
     * @notice If you would like to lend Hue back to the protocol and earn a possible positive return,
     * you can do so by using this function. If system interest rates, determined by the Rates module, are
     * negative, there will be no return. If they are positive, there will be a positive return on
     * lent hue if interestPortionToLenders is not zero.
     *
     * @param hueCount number of Hue to lend
     */
    function lend(uint hueCount) external lockProtocol runnable {
        _requireEffect(hueCount > 0);
        address msgSender = msg.sender;

        // accrue interest first so that a user can't take advantage of immediately lending then
        // unlending when there is a delay in accruing positive interest on borrows.
        _accrueInterestImpl();

        // determine how many LendHue tokens the given amount of hue is worth.
        uint lendTokenCount = hueCount._mul(_lendTokenExchangeRate());

        accounting.increaseLentHue(hueCount);

        // Take in the lenders Hue and give them LendHue in return.
        // Deposit Hue on to the Accounting contract for safe keeping even if this contract is upgraded.
        TransferHelper.safeTransferFrom(address(hue), msgSender, address(accounting), hueCount);
        lendHue.mintTo(msgSender, lendTokenCount);

        emit Lend(msgSender, hueCount, lendTokenCount);
    }

    /**
     * @notice Burn LendHue for Hue tokens. The user can expect the same or more Hue than was
     * originally locked to mint the LendHue. This function is allowed to run after the protocol
     * has been shutdown so that lenders can always get back the Hue they are entitled to.
     *
     * @param lendTokenCount the number of LendHue tokens to burn.
     */
    function unlend(uint lendTokenCount) external lockProtocol notStopped {
        _requireEffect(lendTokenCount > 0);
        address msgSender = msg.sender;

        // determine how many Hue tokens the given amount of LendHue is worth.
        uint hueCount = valueOfLendTokensInHue(lendTokenCount);

        // burn the callers LendHue and give them Hue in return.
        lendHue.burnFrom(msgSender, lendTokenCount);
        accounting.sendLentHue(msgSender, hueCount);

        emit Unlend(msgSender, hueCount, lendTokenCount);
    }

    /*****************************************************
     * =============== BORROW INTERFACE ================ *
     *****************************************************/
    /**
     * @notice Create a new debt position.
     *
     * The returned positionID can also be obtained by calling positionIDs(ownerAddress) on HuePositionNFT.
     *
     * This is in fact issuing a new NFT to the caller, which is then registered in Accounting
     * with a given collateral type. DO NOT give the NFT to someone else unless you want them to have
     * FULL control over your position and your collateral. You would also lose that control.
     *
     * @param initialDebt The initial debt for the position, 0 if none. Eth can be sent as collateral.
     *
     * @return positionID the ID of the new position to provide to the borrow function. EOAs can
     *   get this value from positionIDs(address) on HuePositionNFT.
     */
    function createPosition(
        uint initialDebt,
        uint32 ui
    ) external payable lockProtocol runnable returns (uint64 positionID) {
        require(msg.value > 0, 'Must add collateral');

        // Mint a new NFT representing ownership of the position to the user.
        positionID = huePositionNFT.mintTo(msg.sender);

        IAccounting.DebtPosition memory dp;
        dp.ui = ui;

        // create, initialize, and store the position
        _adjustPosition(_updatePosition(positionID, dp), positionID, initialDebt.toInt256(), 0);

        emit PositionCreated(msg.sender, positionID, initialDebt);
    }

    /**
     * @notice Lock collateral and/or borrow Hue. The caller must either own positionID,
     * or have been given authorization to administer positionID by the owner.
     * Positions must be overcollateralized or they will be subject to liquidation.
     *
     * @param positionID The positionID obtained in createNewPosition().
     * @param debtChange The change in debt desired, positive for increase, negative for decrease
     * @param collateralDecrease How much the caller wishes collateral to decrease. Additional collateral
     *   can be sent along with the transaction.
     */
    function adjustPosition(
        uint64 positionID,
        int debtChange,
        uint collateralDecrease,
        uint32 ui
    ) external payable lockProtocol runnable {
        // Only allow the owner of the position or an account they have given permission to borrow.
        _requireAuthorized(huePositionNFT.isApprovedOrOwner(msg.sender, positionID));

        // load and update the position
        IAccounting.DebtPosition memory dp =
            _updatePosition(positionID, accounting.getPosition(positionID));

        dp.ui = ui;

        _adjustPosition(
            dp,
            positionID,
            debtChange,
            collateralDecrease);
    }

    /**
     * @notice Allows the user to claim their TCP rewards for holding a position with debt.
     *   There is no need to call this proactively, rewards will continue to accrue regardless
     *   of if this is called. Only call if you want rewards now.
     *
     * @param positionID the ID of the position to update.
     */
    function claimRewards(uint64 positionID, uint32 ui) external lockProtocol notStopped {
        _requireAuthorized(huePositionNFT.isApprovedOrOwner(msg.sender, positionID));

        IAccounting.DebtPosition memory dp =
            _updatePosition(positionID, accounting.getPosition(positionID));

        dp.ui = ui;

        accounting.setPosition(positionID, dp);
    }

    /*
     * With all other function, a ui tag is registered to allow the host of the UI to get a portion
     *   of the TCP accrued to the position. This incentivizes a broad decentralized UI network for
     *   this protocol, removing centralized points of failure. If a kickback has been set on the
     *   position, an approved operator can manually remove that kickback using this function
     *   so that all FUTURE Tcp is accrued directly to the owner.
     *
     * @param positionID the ID of the position to remove the kickback from.
     */
    function removeKickback(uint64 positionID) external lockProtocol runnable {
        _requireAuthorized(huePositionNFT.isApprovedOrOwner(msg.sender, positionID));

        IAccounting.DebtPosition memory dp =
            _updatePosition(positionID, accounting.getPosition(positionID));

        dp.ui = 0;

        accounting.setPosition(positionID, dp);
    }


    /**
     * @notice Anyone can accrue global interest and update borrowing rewards counts.
     *   This is not necessary for proper operation of the system, as interest will be accrued
     *   as needed by the other functions in this contract.
     */
    function accrueInterest() external override lockContract {
        _accrueInterestImpl();
    }

    /*****************************************************
     * =============== SYSTEM FUNCTIONS ================ *
     *****************************************************/
    /**
     * @dev Allows other contracts in the protocol to receive updated information about
     *   a position. This is access restricted because it forces rewards to be distributed, something
     *   that the position owner might not desire if given the choice. The system will only call
     *   this function if absolutely needed, for example when the position has already been verified
     *   to be undercollateralized, or after the system is shutdown and anyone can trade Hue for Eth
     *   from any position.
     *
     * @param positionID The ID of the position requested.
     */
    function systemGetUpdatedPosition(
        uint64 positionID
    ) external override lockContract returns (IAccounting.DebtPosition memory) {
        governor.requireUpdatePositionAccess(msg.sender);

        return _updatePosition(positionID, accounting.getPosition(positionID));
    }

    /*****************************************************
     * ==================== VIEW ======================= *
     *****************************************************/
    /**
     * @notice The value in Hue of a given number of LendHue tokens.
     */
    function valueOfLendTokensInHue(uint lendTokenCount) public view returns (uint) {
        return lendTokenCount._div(_lendTokenExchangeRate());
    }

    /*****************************************************
     * =============== INTERNAL HELPERS ================ *
     *****************************************************/
    /// @dev Saves space on require messages.
    function _requireEffect(bool hasEffect) internal pure {
        require(hasEffect, 'Noop');
    }

    /**
     * @dev Gives the current period, stopping at the time the protocol was shutdown if it was.
     *   This ensures that all TCP rewards stop at protocol shutdown, but that rewards accrued
     *   before shutdown can still be claimed after shutdown.
     */
    function _currentPeriodEndingAtShutdown() internal view returns (uint64 period) {
        period = _timeToPeriod(_currentTimeEndingAtShutdown());
    }

    /**
     * @dev Gives the current time, stopping at the time the protocol was shut down if it was.
     *   This ensures that all TCP rewards stop at protocol shutdown, but that rewards accrued
     *   before shutdown can still be claimed after shutdown.
     */
    function _currentTimeEndingAtShutdown() internal view returns (uint64 time) {
        time = _currentTime();
        uint64 shutdownTime = governor.shutdownTime();
        if (shutdownTime > 0 && shutdownTime < time) time = shutdownTime;
    }

    /*
     * @dev Calculates the exchange rate for lend tokens and hue tokens.
     *   This is determined as the total supply of lend tokens divided by the number of Hue in the
     *   lend pool.
     */
    function _lendTokenExchangeRate() internal view returns (uint) {
        uint lends = accounting.lentHue();
        uint totalLendHue = lendHue.totalSupply();
        return (totalLendHue == 0 || lends == 0) ? TcpSafeMath.ONE : totalLendHue._div(lends);
    }

    /**
     * @dev Handle increasing debt and/or collateral of an account
     */
    function _adjustPosition(
        IAccounting.DebtPosition memory position,
        uint64 positionID,
        int debtChange,
        uint collateralDecrease
    ) internal {
        // SET UP LOCAL VARIABLES
        uint collateralIncrease = msg.value;

        uint debtIncrease = debtChange > 0 ? uint(debtChange) : 0;
        uint debtDecrease = debtChange < 0 ? uint(debtChange.mul(-1)) : 0;

        // CHECK INPUTS
        require(!(collateralIncrease > 0 && collateralDecrease > 0), 'Cant increase & decrease collateral');

        _requireEffect(collateralIncrease > 0 || collateralDecrease > 0 || debtIncrease > 0 || debtDecrease > 0);

        // HANDLE DEBT CHANGE
        if (debtIncrease > 0)  {
            // store the time of this borrow in order to prevent using borrow/payback for flash borrowing
            position.lastBorrowTime = _currentTime();
            // increase the debt count of the position.
            position.debt = position.debt.add(debtIncrease);
            // record that total system debt has increased
            accounting.increaseDebt(debtIncrease);
        }
        if (debtDecrease > 0) {
            // Disallow flash borrowing.
            require(position.lastBorrowTime.add(MIN_BORROW_TIME) < _currentTime(), 'No flash borrow');
             // allow user to pay back all debt easily after interest has been accrued.
            if (position.debt < debtDecrease) debtDecrease = position.debt;
            // decrease the positions debt.
            position.debt -= debtDecrease;
            // register the decreased system debt
            accounting.decreaseDebt(debtDecrease);
        }

        // HANDLE COLLATERAL CHANGE
        if (collateralIncrease > 0) position.collateral = position.collateral.add(collateralIncrease);
        if (collateralDecrease > 0) position.collateral = position.collateral.sub(collateralDecrease);

        // TEST FOR FAILURE CASES
        if (position.debt > 0) {
            require(position.debt >= minPositionSize, 'Position too small');

            // If the position is decreasing it's collateral to debt ratio, ensure that it is well collateralized
            if (collateralDecrease > 0 || debtIncrease > 0) {
                _requireWellCollateralized(position.debt, position.collateral);
            }
        }

        // UPDATE STORAGE
        accounting.setPosition(positionID, position);

        // TRANSFER VALUE
        // mint hue or burn hue from the user
        if (debtIncrease > 0) hue.mintTo(msg.sender, debtIncrease);
        if (debtDecrease > 0) hue.burnFrom(msg.sender, debtDecrease);

        // take in collateral or send it back to the user
        if (collateralIncrease > 0) TransferHelper.safeTransferETH(address(accounting), collateralIncrease);
        if (collateralDecrease > 0) accounting.sendCollateral(msg.sender, collateralDecrease);

        emit PositionAdjusted(
          positionID,
          debtIncrease,
          debtDecrease,
          collateralIncrease,
          collateralDecrease,
          position.debt,
          position.collateral);
    }

    /*
     * @dev ensure that the position has acceptable amounts of debt and collateral.
     */
    function _requireWellCollateralized(uint debtCount, uint collateralCount) view internal {
        // (position: collateral / debt) * (price: hue / eth)   (types cancel out to give raw value)
        // should be greater than or equal to the collateralization requirement (which has no type)
        //
        // So, with safe math, we have
        // (positionCollateral * ONE / positionDebt) * price / ONE >= collatReq
        //
        // simplifying: positionCollateral * price / positionDebt >= collatReq
        //
        // increase math precision: positionCollateral * price >= collatReq * positionDebt
        uint price = governor.prices().calculateInstantCollateralPrice(twapDuration);

        require(collateralCount.mul(price) >= collateralizationRequirement.mul(debtCount), 'Insufficient collateral');
    }

    /**
     * @dev Updates:
     *  * Global interest rates,
     *  * Global debt,
     *  * Token interest for lenders,
     *  * Reserves,
     *  * Total rewards available for borrowers to claim.
     *
     * The above calculations are only completed at most every period, which is every hour to save gas.
     */
    function _accrueInterestImpl() internal {
        // The current period, ending at shutdown time if the protocol is shutdown
        uint64 period = _currentPeriodEndingAtShutdown();
        if (period <= lastPeriodGlobalInterestAccrued) return;

        // total number of periods we are calculating for. Safe due to the check above
        uint64 periods = period - lastPeriodGlobalInterestAccrued;
        // get system debt info
        IAccounting.SystemDebtInfo memory sdi = accounting.getSystemDebtInfo();
        // get rates contract
        IRates rates = governor.rates();

        // calculate new interest information including:
        // global debt, debt exchange rate, and change in reserves and the lend fund.
        CalculatedInterestInfo memory cii = _calculateInterest(
            sdi,
            periods,
            rates.interestRateAbsoluteValue(),
            rates.positiveInterestRate(),
            hue.reserves(),
            interestPortionToLenders);

        // Calculate how many TCP tokens should be allocated to borrowers.
        uint rewardCount = governor.calculateCurrentDailyDebtRewardCount().mul(periods) / PERIODS_PER_DAY;

        // update system debt info according to new data.
        sdi = IAccounting.SystemDebtInfo({
            debt: cii.newDebt,
            totalTCPRewards: sdi.totalTCPRewards.add(rewardCount),
            cumulativeDebt: sdi.cumulativeDebt.add(sdi.debt.mul(periods)),
            debtExchangeRate: cii.newExchangeRate
        });

        // save the new data.
        accounting.setSystemDebtInfo(sdi);

        // register that interest is up to date as of the current period.
        lastPeriodGlobalInterestAccrued = period;

        // expand or reduce reserves, and accrue interest to lent tokens.
        if (cii.additionalLends > 0) {
            accounting.increaseLentHue(cii.additionalLends);
            hue.mintTo(address(accounting), cii.additionalLends);
        }
        if (cii.additionalReserves > 0) hue.mintTo(address(hue), cii.additionalReserves);
        if (cii.reducedReserves > 0) hue.burnReserves(cii.reducedReserves);

        emit InterestAccrued(
            period,
            periods,
            sdi.debt,
            sdi.totalTCPRewards,
            sdi.cumulativeDebt,
            sdi.debtExchangeRate);
    }

    /*
     * @dev Calculate interest given information the protocol debt, interest rate, time
     *   since calculation and reserves. This function is pure for easy unit testing.
     */
    function _calculateInterest(
        IAccounting.SystemDebtInfo memory sdi,
        uint64 periods,
        uint annualInterestRateAbsoluteValue,
        bool positiveInterestRate,
        uint reserves,
        uint _interestPortionToLenders
    ) internal pure returns (CalculatedInterestInfo memory cii) {
        // if the interest rate for borrowing HUE is currently 0%, our job is easy, don't change anything.
        if (annualInterestRateAbsoluteValue == 0) {
            cii.newDebt = sdi.debt;
            cii.newExchangeRate = sdi.debtExchangeRate;
            return cii;
        }

        // Given an annual interest rate and the number of periods we are behind, calculate the
        // interest rate since the last update.
        uint periodInterestRateAbsoluteValue = annualInterestRateAbsoluteValue.mulDiv(periods, PERIODS_PER_YEAR);

        // the debt exchange rate should increase if there is a positive interest rate (debt increases)
        // or decrease if there is a negative interest rate.
        uint interestRateMultiplier = positiveInterestRate
            ? TcpSafeMath.ONE.add(periodInterestRateAbsoluteValue)
            : TcpSafeMath.ONE.sub(periodInterestRateAbsoluteValue);

        cii.newExchangeRate = sdi.debtExchangeRate._mul(interestRateMultiplier);

        // given this new exchange rate, it is trivial to calculate the total system debt.
        cii.newDebt = sdi.debt.mulDiv(cii.newExchangeRate, sdi.debtExchangeRate);

        // now we must allocate the increased system debt between reserves and interest to HUE lenders.
        // if the system debt has decreased (negative interest) then positive interest only is taken from reserves,
        // but ONLY if there are sufficient reserves.
        if (cii.newDebt > sdi.debt) {
            // positive interest case
            uint additionalDebt = cii.newDebt - sdi.debt;
            // the interestPortionToLenders of the additional debt goes to those who are lending HUE
            cii.additionalLends = additionalDebt._mul(_interestPortionToLenders);
            // the rest is added to reserves.
            cii.additionalReserves = additionalDebt - cii.additionalLends;
        } else if (cii.newDebt < sdi.debt) {
            // negative interest case
            uint debtReduction = sdi.debt - cii.newDebt;
            // we must first check that there are reserves to pay the proposed negative interest.
            if (debtReduction >= reserves) {
                // Don't accrue negative interest if there is insufficient reserves, otherwise
                // there would be unbacked hue.
                cii.newDebt = sdi.debt;
                cii.newExchangeRate = sdi.debtExchangeRate;
            } else {
                // If there are sufficient reserves, they need to be reduced to pay negative interest.
                cii.reducedReserves = debtReduction;
            }
        }
    }

    /*
     * @dev Take current system debt information and update a position's account information,
     *   awarding TCP as needed.
     */
    function _updatePosition(
        uint positionID,
        IAccounting.DebtPosition memory _position
    ) internal returns (IAccounting.DebtPosition memory position) {
        // only allow rewards and interest to be accrued up until shutdown time, if the protocol has
        // been shutdown.
        uint64 timeNow = _currentTimeEndingAtShutdown();
        uint64 periodNow = _timeToPeriod(timeNow);
        uint64 lastPeriodUpdated = _position.lastTimeUpdated == 0 ? 0 : _timeToPeriod(_position.lastTimeUpdated);

        // if everything is up to date, then return.
        if (periodNow <= lastPeriodUpdated) return _position;

        // accrue global interest to make sure the position calculations are correct.
        // if global interest has already been accrued this period, then this function will return quickly.
        _accrueInterestImpl();

        uint rewards;
        // calculate the updated position and rewards owed to the position owner, if any.
        (position, rewards) = _updatePositionImpl(_position, accounting.getSystemDebtInfo(), timeNow);

        // if there are rewards that are not for the liqudiation account, get them to the position owner.
        if (rewards > 0 && positionID != 0) {
            // if there is a ui registered for this position with a valid kickback, give some of the
            // TCP to the kickbackDestination
            if (position.kickbackDestination != address(0) && position.kickbackPortion > 0) {
                uint kickback = rewards._mul(position.kickbackPortion);
                governor.mintTCP(position.kickbackDestination, kickback);

                emit RewardsDistributed(position.kickbackDestination, true, kickback);

                rewards = rewards.sub(kickback);
            }

            // give the rest to the owner
            address owner = huePositionNFT.ownerOf(positionID);
            governor.mintTCP(owner, rewards);
            emit RewardsDistributed(owner, false, rewards);
        }

        emit PositionUpdated(positionID, periodNow, position.debt, rewards);
    }

    /*
     * @dev Calculate a position's values given any accrued interest.
     * If the position is up to date, then return the position without further computation.
     *
     * This function is pure for easy unit testing.
     */
    function _updatePositionImpl(
        IAccounting.DebtPosition memory _position,
        IAccounting.SystemDebtInfo memory sdi,
        uint64 timeNow
    ) internal pure returns (IAccounting.DebtPosition memory position, uint rewards) {
        position = _position;

        // if this is the first initialization don't accrue interest or calculate rewards
        // if there is no debt then there is no rewards or interest to accrue
        if (position.lastTimeUpdated > 0 && position.debt > 0) {

            // update the position debt.
            position.debt = position.debt.mulDiv(sdi.debtExchangeRate, position.startDebtExchangeRate);

            // given the rewards added since last update and this position's portion of total
            // debt, calculate the TCP this position is entitled to.
            // Scale it by the amount of time since the last update, to prevent against outsized rewards for
            // exceedingly small lengths of time between updates that cross a period border.
            rewards = position.debt
                .mulDiv(
                    sdi.totalTCPRewards.sub(position.startTCPRewards),
                    sdi.cumulativeDebt.sub(position.startCumulativeDebt))
                .mulDiv(timeNow.sub(position.lastTimeUpdated), PERIOD_LENGTH);
        }

        // update the position metadata to be current
        position.startDebtExchangeRate = sdi.debtExchangeRate;
        position.startTCPRewards = sdi.totalTCPRewards;
        position.startCumulativeDebt = sdi.cumulativeDebt;
        position.lastTimeUpdated = timeNow;
    }

    /*****************************************************
     * ================== GOVERNANCE =================== *
     *****************************************************/
    /**
     * @notice Set collateralization requirement, scaled by 1e18 for the given collateral type
     * For example, a 150% collateralization would be denoted by 1.5e18.
     */
    function setCollateralizationRequirement(uint requirement) external onlyGovernor {
        collateralizationRequirement = requirement;
        require(requirement >= TcpSafeMath.ONE);

        emit CollateralizationRequirementUpdated(requirement);
    }

    /**
     * @notice Governance function to set the min position size. Only settable by governance.
     */
    function setMinPositionSize(uint size) external onlyGovernor {
        minPositionSize = size;

        emit MinPositionSizeUpdated(size);
    }

    /**
     * @notice Governance function to set the percentage of positive interest that is accrued to lenders.
     * Only settable by governance.
     */
    function setInterestPortionToLenders(uint percentage) external onlyGovernor {
        interestPortionToLenders = percentage;
        require(interestPortionToLenders <= TcpSafeMath.ONE);

        emit InterestPortionToLendersUpdated(percentage);
    }

    /**
     * @notice Governance function to set TWAP duration for the collateral pool
     * Only settable by governance.
     */
    function setTwapDuration(uint32 duration) external onlyGovernor {
        require(duration >= 5 minutes);
        twapDuration = duration;

        emit TwapDurationUpdated(duration);
    }

    /**
     * @notice Governance function to stop this contract from operating. This happens during a contract
     * upgrade to a new implementation of this contract. Only settable during upgrade by Governor.sol.
     */
    function stop() external override onlyGovernor {
        _stopImpl();
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import './IAccounting.sol';
import './IGovernor.sol';
import './IHue.sol';
import './ILendHue.sol';
import './IPositionNFT.sol';
import './IProtocolLock.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface IMarket {
    // ==================== VIEW ======================
    function collateralizationRequirement() external view returns (uint ratio);
    function lastPeriodGlobalInterestAccrued() external view returns (uint64 period);

    // ==================== EXTERNAL FUNCTIONS ======================
    function accrueInterest() external;

    // ==================== SYSTEM FUNCTIONS ======================
    function systemGetUpdatedPosition(uint64 positionID) external returns (IAccounting.DebtPosition memory position);

    // ================= GOVERNANCE ===================
    function stop() external;

    // ==================== STRUCTS ======================
    struct CalculatedInterestInfo {
        uint newDebt;
        uint newExchangeRate;
        uint additionalReserves;
        uint additionalLends;
        uint reducedReserves;
    }

    struct ConstructorParams {
        IGovernor Governor;
        IProtocolLock ProtocolLock;
        IPositionNFT HuePositionNFT;
        IHue Hue;
        ILendHue LendHue;
        IAccounting Accounting;
    }

    // ==================== EVENTS ======================
    // lend functions
    event Lend(address indexed account, uint hueCount, uint lendTokenCount);
    event Unlend(address indexed account, uint hueCount, uint lendTokenCount);

    // borrow functions
    event PositionCreated(address indexed creator, uint64 indexed positionID, uint initialDebt);
    event PositionAdjusted(
      uint64 indexed positionID,
      uint debtIncrease,
      uint debtDecrease,
      uint collateralIncrease,
      uint collateralDecrease,
      uint newDebt,
      uint newCollateral);
    event RewardsDistributed(address indexed account, bool indexed isKickback, uint tcpRewards);

    event InterestAccrued(uint64 indexed period, uint64 periods, uint newDebt, uint rewardCount, uint cumulativeDebt, uint debtExchangeRate);
    event PositionUpdated(uint indexed positionID, uint64 indexed period, uint debtAfter, uint tcpRewards);

    // params
    event CollateralizationRequirementUpdated(uint requirement);
    event MinPositionSizeUpdated(uint size);
    event InterestPortionToLendersUpdated(uint percentage);
    event TwapDurationUpdated(uint32 duration);
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';



interface IPositionNFT is IERC721, IERC721Metadata {
    // ==================== SYSTEM FUNCTIONS ======================
    function mintTo(address to) external returns (uint64 id);
    function burn(uint64 tokenID) external;

    // =========================== VIEW ===========================
    function isApprovedOrOwner(address account, uint tokenId) external view returns (bool r);
    function positionIDs(address account) external view returns (uint64[] memory IDs);
    function nextPositionID() external view returns (uint64 ID);
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './IGovernor.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IHue is IERC20 {
    // ==================== VIEW FUNCTIONS ======================
    function reserves() external view returns (uint);

    // ==================== SYSTEM FUNCTIONS ======================
    function distributeReserves(address dest, uint count) external;
    function burnReserves(uint count) external;
    function mintTo(address account, uint countTokensToMint) external;
    function burnFrom(address account, uint256 amount) external;

    // ==================== STRUCTS ======================
    struct ConstructorParams {
        IGovernor Governor;
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './IGovernor.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface ILendHue is IERC20 {
    // ==================== SYSTEM FUNCTIONS ======================
    function mintTo(address account, uint countTokensToMint) external;
    function burnFrom(address account, uint256 amount) external;

    // ==================== STRUCTS ======================
    struct ConstructorParams {
        IGovernor Governor;
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import './IGovernor.sol';
import './IRewards.sol';
import './IHue.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IAccounting {
    // ================= DEBT POSITIONS ===================
    function getBasicPositionInfo(uint64 positionID) external view returns (uint debtCount, uint collateralCount);
    function getPosition(uint64 positionID) external view returns (DebtPosition memory acct);
    function setPosition(uint64 positionID, DebtPosition memory dp) external;
    function sendCollateral(address payable account, uint count) external;

    // ================= LENDING ===================
    function lentHue() external view returns (uint);
    function increaseLentHue(uint count) external;
    function sendLentHue(address dest, uint count) external;

    // ================= SYSTEM DEBT INFO ===================
    function debt() external view returns (uint);
    function getSystemDebtInfo() external view returns (SystemDebtInfo memory);
    function setSystemDebtInfo(SystemDebtInfo memory _systemDebtInfo) external;
    function increaseDebt(uint count) external;
    function decreaseDebt(uint count) external;

    // ================= POOL TOKENS ===================
    function getPoolPosition(uint nftID) external view returns (PoolPosition memory pt);
    function setPoolPosition(uint nftID, PoolPosition memory pt) external;
    function deletePoolPosition(uint nftID) external;

    function setRewardStatus(uint16 poolID, RewardStatus memory rs) external;
    function getRewardStatus(uint16 poolID) external view returns (RewardStatus memory rs);

    function poolLiquidity(IUniswapV3Pool pool) external view returns (uint liquidity);
    function increasePoolLiquidity(IUniswapV3Pool pool, uint liquidity) external;
    function decreasePoolLiquidity(IUniswapV3Pool pool, uint liquidity) external;

    // ===================== REWARDS KEEPER ================================
    function addPositionToIndex(address owner, uint nftID) external;

    // ===================== GOVERNANCE ================================
    function onRewardsUpgrade(address newRewards) external;

    // ===================== UIs ================================
    function approveUIs(uint32[] memory ids) external;
    function disapproveUIs(uint32[] memory ids) external;

    // ================= STRUCTS ===================

    // ================ system debt data ================
    struct SystemDebtInfo {
        uint debt;
        uint totalTCPRewards;
        uint cumulativeDebt;
        uint debtExchangeRate;
    }

    struct SystemDebtInfoStorage {
        uint cumulativeDebt;
        uint128 debt;
        uint128 debtExchangeRate;
        uint128 totalTCPRewards;
    }

    // ================ debt position data ================
    struct DebtPosition { // See DebtPositionStorage below for explanation
        uint startCumulativeDebt;
        uint collateral;
        uint debt;
        uint startDebtExchangeRate;
        uint startTCPRewards;
        uint64 lastTimeUpdated;
        uint64 lastBorrowTime;
        int24 tick;
        bool tickSet;
        uint64 tickIndex;
        uint32 ui;
        address kickbackDestination;
        uint64 kickbackPortion;
    }

    struct DebtPositionStorage {
        uint startCumulativeDebt; // debt cumulator at time of last reward distribution
        uint128 collateral; // number of collateral tokens
        uint128 debt; // number of borrowed HUE
        uint128 startDebtExchangeRate; // the debt exchange rate at time of last account update
        uint128 startTCPRewards; // total number of
        uint64 lastTimeUpdated; // last time that this position was updated
        uint64 lastBorrowTime; // last time that this the debt of this position was increased
        int24 tick;
        bool tickSet;
        uint64 tickIndex; // the index of this position in the positions stored for the above band.
        uint32 ui;
    }

    // ================ pool position data ================
    struct RewardStatus {
        uint totalRewards;
        uint cumulativeLiquidity;
    }

    struct PoolPosition {
        address owner;
        uint16 poolID;
        uint cumulativeLiquidity;
        uint totalRewards;
        uint lastBlockPositionIncreased;
        uint128 liquidity;
        uint64 lastTimeRewarded;
        int24 tickLower;
        int24 tickUpper;
        uint32 ui;
        address kickbackDestination;
        uint64 kickbackPortion;
    }

    struct PoolPositionStorage {
        address owner;
        uint16 poolID;
        uint32 ui;
        uint cumulativeLiquidity;
        uint176 totalRewards;
        uint40 lastTimeRewarded;
        uint40 lastBlockPositionIncreased;
    }

    struct ConstructorParams {
        IGovernor Governor;
        IHue Hue;
        INonfungiblePositionManager NftPositionManager;
    }

    // ==================== USER INTERFACES ======================
    enum UIGovernanceRating { NotRated, Approved, Disapproved }

    // tags:
    // add 1 for borrow ui
    // add 2 for lend ui
    // add 4 for liquidity ui
    // add 8 for auctions ui
    // add 16 for governance ui
    // others can be defined by the community as needed
    struct UserInterface {
        address kickbackDestination;
        uint64 kickbackPortion;
        UIGovernanceRating governanceRating;
        uint24 tags;
        string ipfsHash;
    }

    // ==================== EVENTS ======================
    event PoolPositionIndexingDisabled();
    event DebtPositionIndexingDisabled();

    event UIsApproved(uint32[] uis);
    event UIsDisapproved(uint32[] uis);
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './IGovernor.sol';
import './IProtocolLock.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface IRates {
    // ================= SYSTEM FUNCTIONS ===================
    function positiveInterestRate() external view returns (bool);
    function interestRateAbsoluteValue() external view returns (uint);

    // ================= GOVERNANCE ===================
    function setInterestRateStep(uint128 step) external;
    function addReferencePool(IUniswapV3Pool pool) external;
    function removeReferencePool(IUniswapV3Pool pool) external;

    function stop() external;

    // ================= EVENTS ===================
    event RateUpdated(int interestRate, uint price, uint rewardCount, uint64 nextUpdateTime);

    event ReferencePoolAdded(address pool);
    event ReferencePoolRemoved(address pool);
    event AcceptableErrorUpdated(uint128 error);
    event ErrorIntervalUpdated(uint128 error);
    event InterestRateStepUpdated(uint128 step);
    event MaxStepsUpdated(uint64 steps);
    event MinRateUpdated(int128 min);
    event MaxRateUpdated(int128 max);
    event MinTimeBetweenUpdatesUpdated(uint64 time);

    // ================= STRUCTS ===================
    struct ConstructorParams {
        IGovernor Governor;
        IProtocolLock ProtocolLock;
        IUniswapV3Pool CollateralPool;
        IUniswapV3Pool[] ReferencePools;
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// adapted from OpenZeppelin v3.1.0 Ownable.sol
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '../interfaces/IProtocolLock.sol';
import '../utils/Governed.sol';


/**
 * @title Governed
 *
 * @notice All contracts in the protocol that connect with Governor extend Governed. This could mean
 * anything to just using values from Governor, having parameters that can be updated from Governor,
 * or being fully upgradeable by Governor.
 *
 * The contract also contains security modifiers for contracts in the Hue Protocol.
 */
abstract contract LocksProtocol is Governed {
    IProtocolLock private immutable protocolLock;

    constructor (IGovernor _governor, IProtocolLock _protocolLock) Governed(_governor) {
        protocolLock = _protocolLock;
    }

    // Verbatim OZ ReentrancyGuard implementation which wraps the contract. Wrapped in a protocol lock.
    /*
     * @notice A Verbatim Open Zeppelin ReentrancyGuard implementation which wraps the contract.
     *   This is additionally wrapped in a protocol lock, which is a reentrancy guard at the protocol
     *   level. This disallows multiple calls originating outside the protocol to be nested within
     *   eachother, helping to prevent an entire class of attacks.
     */
    modifier lockProtocol() {
        _lockProtocol();
        _;
        _unlockProtocol();
    }

    function _lockProtocol() internal {
        protocolLock.enter();

        require(_status != _ENTERED, 'LP Reentrancy');
        _status = _ENTERED;
    }

    function _unlockProtocol() internal {
        _status = _NOT_ENTERED;

        protocolLock.exit();
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './TcpSafeCast.sol';
import './SafeMath64.sol';


/*
 * @title Time
 *
 * @notice A simple abstract contract handling time calculations.
 * @dev Abstract, should be inhereted by all contracts that need time calculation logic.
 */
abstract contract Time {
    using SafeMath64 for uint64;
    using TcpSafeCast for uint256;

    /// @dev Gives the current block time scaled to uint64
    function _currentTime() internal view returns (uint64 time) {
        time = block.timestamp.toUint64();
    }

    /// @dev Gives a time in the future relative to current block time scaled to uint64
    function _futureTime(uint64 addition) internal view returns (uint64 time) {
        time = _currentTime().add(addition);
    }
}

/*
 * @title PeriodTime
 *
 * @notice A simple abstract contract handling time and period calculations.
 * @dev Abstract, should be inhereted by all contracts that need period calculation logic.
 */
abstract contract PeriodTime is Time {
    using SafeMath64 for uint64;

    /// @notice The length of a period for this contract.
    uint64 public immutable periodLength;
    /// @notice The period considered the first period.
    uint64 public immutable firstPeriod;

    /// @notice Set up the period length and first period.
    constructor (uint64 _periodLength) {
        firstPeriod = (_currentTime() / _periodLength) - 1;
        periodLength = _periodLength;
    }

    /*
     * @notice Gives the current period for the contract starting at 1.
     *
     * @return period The calculated period starting from 1.
     */
    function currentPeriod() external view returns (uint64 period) {
        period = _currentPeriod();
    }

    /// @dev for internal use
    function _currentPeriod() internal view returns (uint64 period) {
        period = (_currentTime() / periodLength) - firstPeriod;
    }

    /*
     * @dev Convert a given period to a time, the beginning of the period is used.
     *
     * @param period The period starting at 1 desired
     *
     * @return time The time at the beginning of that period.
     */
    function _periodToTime(uint64 period) internal view returns (uint64 time) {
        time = periodLength.mul(firstPeriod.add(period));
    }

    /*
     * @dev Convert a given time to a period, floowing at 1
     *
     * @param time The time to convert to a period
     *
     * @return period The period, relative to the first period.
     */
    function _timeToPeriod(uint64 time) internal view returns (uint64 period) {
        period = (time / periodLength).sub(firstPeriod);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

// modified from library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

// modified from library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library TcpSafeMath {
    // The following is copied from Uniswap v3 under the MIT license
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


    // ==================== CUSTOM ADDITIONS ======================
    /**
     * @notice All uint number values provided to and used in the protocol will use this value as "one"
     *
     * The number one throughout the Hue Protocol.
     */
    uint256 public constant ONE = 1e18;

    /**
     * @notice A divide that properly handles two numbers using ONE as their base.
     */
    function _div(uint256 a, uint256 b) internal pure returns (uint256 r) {
        r = mulDiv(a, ONE, b);
    }

    /**
     * @notice A multiply that properly handles two numbers using ONE as their base.
     */
    function _mul(uint256 a, uint256 b) internal pure returns (uint256 r) {
        r = mulDiv(a, b, ONE);
    }
}

// SPDX-License-Identifier: MIT
// NOTE: modified compiler version to 0.7.4 and added toUint192, toUint160, and toUint96

pragma solidity =0.7.6;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library TcpSafeCast {
    // =======================================
    // ============= UNSIGNED ================
    // =======================================

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 216 bits
     */
    function toUint248(uint256 value) internal pure returns (uint216) {
        require(value < 2**216, "more than 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value < 2**216, "more than 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value < 2**192, "more than 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value < 2**184, "more than 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value < 2**176, "more than 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value < 2**160, "more than 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "more than 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "more than 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "more than 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value < 2**48, "more than 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     * NOTE: ADDED THIS. THIS WAS NOT IN THE ORIGNAL OZ LIBRARY
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "more than 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "more than 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "more than 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "more than 8 bits");
        return uint8(value);
    }

    // =====================================
    // ============= SIGNED ================
    // =====================================
    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "more than 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "more than 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "more than 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * NOTE: added this
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v3.1._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= -2**23 && value < 2**23, "more than 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "more than 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "more than 8 bits");
        return int8(value);
    }

    // =================================================
    // ============= SIGNED <> UNSIGNED ================
    // =================================================
    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "value not positive");
        return uint256(value);
    }


    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "too big for int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;


import './IAccounting.sol';
import './IAuctions.sol';
import './ITCP.sol';
import './IHue.sol';
import './IPositionNFT.sol';
import './IEnforcedDecentralization.sol';
import './ILendHue.sol';
import './ILiquidations.sol';
import './IMarket.sol';
import './IPrices.sol';
import './IProtocolLock.sol';
import './IRates.sol';
import './IRewards.sol';
import './ISettlement.sol';
import './ITokenIncentiveMinter.sol';
import './IExecutor.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IGovernor is ITokenIncentiveMinter, IExecutor {
    // ================= PROTOCOL STATUS ===================
    function isShutdown() external view returns (bool);
    function shutdownTime() external view returns (uint64);
    function currentPhase() external view returns (uint8);
    function requireValidAction(address target, string calldata signature) external view;
    function calculateCurrentDailyDebtRewardCount() external returns (uint);
    function calculateCurrentDailyLiquidityRewardCount() external returns (uint);

    // ==================== PROTOCOL CONTRACTS ======================
    function accounting() external view returns (IAccounting);
    function auctions() external view returns (IAuctions);
    function tcp() external view returns (ITCP);
    function hue() external view returns (IHue);
    function huePositionNFT() external view returns (IPositionNFT);
    function enforcedDecentralization() external view returns (IEnforcedDecentralization);
    function lendHue() external view returns (ILendHue);
    function liquidations() external view returns (ILiquidations);
    function market() external view returns (IMarket);
    function prices() external view returns (IPrices);
    function protocolLock() external view returns (IProtocolLock);
    function rates() external view returns (IRates);
    function rewards() external view returns (IRewards);
    function settlement() external view returns (ISettlement);

    // ==================== ACCESS CONTROL ======================
    function requireDebtServicesAccess(address caller) external view;
    function requireHueReservesBurnAccess(address caller) external view;
    function requireUpdatePositionAccess(address caller) external view;
    function requireInitializePoolAccess(address caller) external view;

    // ==================== SYSTEM MODIFICATIONS ======================
    function executeShutdown() external;
    function upgradeProtocol(address newGovernor) external;

    // ==================== SYSTEM FUNCTIONS ======================
    function mintTCP(address to, uint count) external;
    function mintVotingRewards(address to, uint count) external;

    // ================= MANAGE CONTRACT UPGRADE ===================
    function upgradeAuctions(address _auctions) external;
    function upgradeLiquidations(address _liquidations) external;
    function upgradeMarket(address _market) external;
    function upgradePrices(address _prices) external;
    function upgradeRates(address _rates) external;
    function upgradeRewards(address _rewards) external;
    function upgradeSettlement(address _settlement) external;

    // ==================== EVENTS ======================
    // contract/protocol shutdown/upgrade
    event ContractUpgraded(string indexed contractName, address indexed contractAddress);
    event ShutdownTokensLocked(address indexed locker, uint count);
    event ShutdownTokensUnlocked(address indexed locker, uint count);
    event ShutdownExecuted();
    event ProtocolUpgraded(address indexed newGovernor);


    // ==================== EVENTS ======================
    struct ProtocolData {
        IAccounting accounting;
        IAuctions auctions;
        IEnforcedDecentralization enforcedDecentralization;
        address governorAlpha;
        IHue hue;
        IPositionNFT huePositionNFT;
        ILendHue lendHue;
        ILiquidations liquidations;
        IMarket market;
        IPrices prices;
        IProtocolLock protocolLock;
        IRates rates;
        IRewards rewards;
        ISettlement settlement;
        ITCP tcp;
        address timelock;
        address[] tokenIncentiveMinters;
        uint[] caps;
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '../utils/LocksProtocol.sol';


interface IProtocolLock {
    // ================= GUARD FUNCTIONS ===================
    function enter() external;
    function exit() external;

    // ================= SYSTEM FUNCTIONS ===================
    function authorizeCaller(address caller) external;
    function unauthorizeCaller(address caller) external;

    // ==================== EVENTS ======================
    event CallerAuthorized(address indexed caller);
    event CallerUnauthorized(address indexed caller);

    // ==================== STRUCTS ======================
    struct ConstructorParams {
        IGovernor Governor;
    }
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

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './IGovernor.sol';
import './IProtocolLock.sol';
import './IAccounting.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';


interface IRewards {
    // ================= GOVERNANCE ===================
    function accrueRewards() external;
    function stop() external;

    // ================= STRUCTS ===================
    struct Tick {
        bool isValid;
        int24 value;
    }

    struct MinimumCollateralLiquidityByPeriod {
        uint64 period;
        uint192 minLiquidity;
    }

    struct PoolConfig {
        IUniswapV3Pool pool;
        uint64 rewardsPortion;
    }

    struct ConstructorParams {
        IGovernor Governor;
        IProtocolLock ProtocolLock;
        IAccounting Accounting;
        address Weth;
        INonfungiblePositionManager NftPositionManager;
        IUniswapV3Factory UniswapV3Factory;
    }

    // ================= EVENTS ===================
    // lock/unlock
    event LiquidityPositionCreated(address indexed owner, uint16 indexed poolID, uint indexed nftID, int24 tickLower, int24 tickUpper, uint128 liquidity);
    event LiquidityPositionIncreased(uint indexed nftID, uint128 liquidity);
    event LiquidityPositionDecreased(uint indexed nftID, uint amount0, uint amount1);
    event LiquidityPositionRemoved(uint indexed nftID, uint amount0, uint amount1);
    event LiquidityPositionLiquidated(uint indexed nftID, address indexed liquidator);

    // claim rewards
    event RewardsClaimed(address indexed caller, uint indexed nftTokenID, uint amount0, uint amount1);

    // maintenance
    event RewardsAccrued(uint count, uint64 periods);
    event RewardsDistributed(address indexed account, bool indexed isKickback, uint tcpRewards);

    // params
    event PoolAdded(address indexed pool, uint16 indexed poolID, uint64 rewardsPortion);
    event PoolIncentiveUpdated(uint16 indexed poolID, uint64 incentive);
    event MaxCollateralLiquidityDecreasePerPeriodUpdated(uint64 decreasePortion);
    event MinHueCountPerPositionUpdated(uint128 min);
    event TwapDurationUpdated(uint64 duration);
    event LiquidationPenaltyUpdated(uint64 penalty);
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

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './IGovernor.sol';
import './IProtocolLock.sol';
import './IHue.sol';


interface IAuctions {
    // ================= VIEW ===================
    function latestAuctionCompletionTime() external view returns (uint64);

    // ================= STRUCTS ===================
    struct Auction {
        uint128 count;
        uint128 bid;
        address bidder;
        uint48 endTime;
        uint48 maxEndTime;
    }

    // ================= GOVERNANCE ===================
    function stop() external;

    // ================= EVENTS ===================
    event SurplusAuctionStarted(uint64 indexed auctionID, uint indexed count, uint64 maxEndTime);
    event DeficitAuctionStarted(uint64 indexed auctionID, uint indexed count, uint64 maxEndTime);
    event SurplusAuctionBid(uint64 indexed auctionID, address indexed bidder, uint bid);
    event DeficitAuctionBid(uint64 indexed auctionID, address indexed bidder, uint bid);
    event SurplusAuctionSettled(uint64 indexed auctionID, address indexed winner);
    event DeficitAuctionSettled(uint64 indexed auctionID, address indexed winner);

    event MinBidDeltaUpdated(uint delta);
    event MinLotSizeUpdated(uint size);
    event MaxSurplusLotSizeUpdated(uint size);
    event maxDeficitLotSizeUpdated(uint size);
    event ReservesBufferLowerBoundUpdated(uint bound);
    event ReservesBufferUpperBoundUpdated(uint bound);
    event MaxBatchSizeUpdated(uint64 size);
    event ExtensionPerBidUpdated(uint64 extension);
    event MinAuctionDurationUpdated(uint64 duration);
    event MaxAuctionDurationUpdated(uint64 duration);
    event TwapDurationUpdated(uint32 duration);

    // ================= STRUCTS ===================
    struct ConstructorParams {
        IGovernor Governor;
        IProtocolLock ProtocolLock;
        IHue Hue;
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface ITCP is IERC20 {
    // ==================== SYSTEM FUNCTIONS ======================
    function mintTo(address to, uint count) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function addGovernor(address newGovernor) external;
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './IGovernor.sol';
import './IProtocolLock.sol';


interface IEnforcedDecentralization {
    function requireValidAction(address target, string memory signature) external view;
    function currentPhase() external view returns (uint8);

    // ================= GOVERNANCE ===================
    function setPhaseOneStartTime(uint64 phaseOneStartTime) external;

    // ==================== EVENTS ======================
    event PhaseOneStartTimeSet(uint64 startTime);
    event PhaseStartDelayed(uint8 indexed phase, uint64 startTime, uint8 delaysRemaining);
    event UpdateLockDelayed(uint64 locktime, uint8 delaysRemaining);
    event ActionBlacklisted(address indexed target, string indexed signature);

    // ==================== STRUCT ======================
    struct ConstructorParams {
        IGovernor Governor;
        IProtocolLock ProtocolLock;
        address Tcp;
    }
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


import './IAccounting.sol';
import './IGovernor.sol';
import './IHue.sol';
import './IMarket.sol';
import './IProtocolLock.sol';

interface ILiquidations {
    // ================= GOVERNANCE ===================
    function stop() external;

    // ==================== STRUCTS ======================
    struct LqInfo {
        uint discoverReward;
        uint liquidateReward;
        uint price;
        address discoverer;
        address priceInitializer;
        address account;
        uint8 collateral;
    }

    struct RewardsLimit {
        uint192 remaining; // How much Hue value of rewards can be accumulated for the most recent price pull.
        uint64 period; // the period for which this limit applies
    }

    struct DiscoverLiquidationInfo {
        IAccounting.DebtPosition lqAcct;
        uint discoverReward;
        uint rewardsRemaining;
        uint collateralizationRequirement;
        IMarket market;
    }

    struct ConstructorParams {
        IGovernor Governor;
        IProtocolLock ProtocolLock;
        IAccounting Accounting;
        IHue Hue;
    }

    // ================= EVENTS ===================
    event UndercollatPositionDiscovered(
        uint64 indexed positionID,
        uint debtCount,
        uint collateralCount,
        uint price);
    event Liquidated(uint baseTokensToRepay, uint collateralToReceive);
    event CoveredUnbackedDebt(uint price, uint amountCovered);

    // params
    event MaxRewardsRatioUpdated(uint64 ratio);
    event DiscoveryIncentiveUpdated(uint64 incentive);
    event MinLiquidationIncentiveUpdated(uint64 incentive);
    event LiquidationIncentiveUpdated(uint64 incentive);
    event twapDurationUpdated(uint32 duration);
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './IGovernor.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface IPrices {
    // ================= VIEW ===================
    function calculateTwappedPrice(IUniswapV3Pool pool, bool normalizeDecimals) external view returns (uint price);
    function calculateInstantTwappedPrice(IUniswapV3Pool pool, uint32 twapDuration) external view returns (uint);
    function calculateInstantTwappedTick(IUniswapV3Pool pool, uint32 twapDuration) external view returns (int24 tick);
    function hueTcpPrice(uint32 twapDuration) external view returns (uint);
    function getRealHueCountForSinglePoolPosition(
        IUniswapV3Pool pool,
        int24 tick,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint32 twapDuration
    ) external view returns (uint hueCount);
    function isPoolInitialized(IUniswapV3Pool pool) external view returns (bool);

    // ================= SYSTEM FUNCTIONS ===================
    function systemObtainReferencePrice(IUniswapV3Pool pool) external returns (uint);
    function initializePool(IUniswapV3Pool pool) external;
    function initializeWethPool(IUniswapV3Pool pool) external;
    function calculateInstantCollateralPrice(uint32 twapDuration) external view returns (uint price);

    // ================= GOVERNANCE ===================
    function stop() external;

    // ==================== STRUCTS ======================
    struct PriceInfo {
        uint64 startTime;
        int56 tickCumulative;
        int24 tick;
        uint8 otherTokenDecimals;
        bool isToken0;
        bool valid;
    }

    struct ConstructorParams {
        IGovernor Governor;
        address Weth;
        address Tcp;
        address Hue;
        IUniswapV3Pool CollateralPool;
        IUniswapV3Pool ProtocolPool;
    }

    // ==================== EVENTS ======================
    event PriceUpdated(address indexed pool, uint price, int24 tick);
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import './IGovernor.sol';
import './IProtocolLock.sol';
import './IAccounting.sol';
import './ITCP.sol';
import './IHue.sol';


interface ISettlement {
    // ================== SYSTEM FUNCTIONS ===================
    function stakeTokensForNoPriceConfidence(uint countTCPToStake) external;
    function unstakeTokensForNoPriceConfidence() external;

    // ================= GOVERNANCE ===================
    function setEthPriceProvider(IPriceProvider aggregator) external;
    function stop() external;

    // ==================== EVENTS ======================
    // price discovery
    event SettlementInitialized(uint settlementDiscoveryStartTime);
    event StakedNoConfidenceTokens(address indexed account, uint count);
    event UnstakedNoConfidenceTokens(address indexed account, uint count);
    event NoConfidenceConfirmed(address indexed account);

    // settlement
    event SettlementWithdrawCollateral(uint64 indexed positionID, address indexed owner, uint collateralToWithdraw);
    event SettlementCollateralForHue(uint64 indexed positionID, address indexed caller, uint hueCount, uint collateralCount);

    // parameters
    event EthPriceProviderUpdated(address provider);

    // ================= ENUM ===================
    enum SettlementStage {
        ContractStopped,
        NotShutdown,
        NotInitialized,
        WaitingForPriceTime,
        NoPriceConfidence,
        PriceConfidence,
        PriceConfirmed
    }

    // ================= STRUCTS ===================
    struct ConstructorParams {
        IGovernor Governor;
        IProtocolLock ProtocolLock;
        IPriceProvider PriceProvider;
        IAccounting Accounting;
        ITCP Tcp;
        IHue Hue;
    }
}

interface IPriceProvider {
  function decimals() external view returns (uint8);
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface ITokenIncentiveMinter {
    function mintIncentive(address dest, uint count) external;
}

// Copyright (c) 2020-2022. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


/**
 * @title IExecutor
 */
interface IExecutor {
    function execute(
        address target,
        string memory signature,
        bytes memory data
    ) external returns (bool success, bytes memory returnData);
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

// Copyright (c) 2020-2022. All Rights Reserved
// adapted from OpenZeppelin v3.1.0 Ownable.sol
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '../interfaces/IGovernor.sol';


/**
 * @title Governed
 *
 * @notice All contracts in the protocol that connect with Governor extend Governed. This could mean
 * anything to just using values from Governor, having parameters that can be updated from Governor,
 * or being fully upgradeable by Governor.
 *
 * The contract also contains security modifiers for contracts in the Hue Protocol.
 */
abstract contract Governed {
    /*****************************************************
     * ============== CONTRACT SETUP =================== *
     *****************************************************/
    /// @notice The contract that can govern this contract.
    IGovernor public immutable governor;
    /// @notice Whether or not this contract is stopped. If it is stopped, it should not operate.
    bool public stopped;

    event Stopped();

    constructor (IGovernor _governor) {
        governor = _governor;
    }

    /*****************************************************
     * ============== UPDATE VALIDITY ================== *
     *****************************************************/
    /*
     * @dev A list of function selectors that can be called by the governance contract to update values
     * on this contract. All other functions are not allowed to be called by governance.
     */
    mapping(bytes4 => bool) public validUpdate;

    /*****************************************************
     * ============= SECURITY MODIFIERS ================ *
     *****************************************************/
    function _requireAuthorized(bool authorized) internal pure {
        require(authorized, 'Not Authorized');
    }

    function _onlyGovernor() internal view {
        _requireAuthorized(msg.sender == address(governor));
    }

    /*
     * @notice A modifier that only allows the Governor to call a function. This is most commonly
     *   used for contract parameter updates.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    /*
     * @notice A modifier that does not allow a function to be called if the protocol has not started,
     *   if the contract is stopped, or the protocol is shutdown.
     */
    modifier runnable() {
        _runnable();
        _;
    }

    function _runnable() internal view {
        _notStopped();
        require(!governor.isShutdown(), 'Protocol shutdown');
    }

    modifier notStopped() {
        _notStopped();
        _;
    }

    function _notStopped() internal view {
        require(!stopped, 'Contract is stopped');
    }

    uint internal constant _NOT_ENTERED = 1;
    uint internal constant _ENTERED = 2;
    uint internal _status = _NOT_ENTERED;

    /*
     * @notice A Verbatim Open Zeppelin ReentrancyGuard implementation
     *   Prevents against attacks that rely on reentrant calls.
     */
    modifier lockContract() {
        _lockContract();
        _;
        _unlockContract();
    }

    function _lockContract() internal {
        require(_status != _ENTERED, 'LC Reentrancy');
        _status = _ENTERED;
    }

    function _unlockContract() internal {
        _status = _NOT_ENTERED;
    }

    /*****************************************************
     * ============= INTERNAL HELPERS ================== *
     *****************************************************/
    /*
     * @dev An implementation of stop, which an extending contract can call as needed if Governor
     * tells the contract to stop when it is being upgraded.
     */
    function _stopImpl() internal {
        stopped = true;
        emit Stopped();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

// modified from library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath64 {
    function add(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x + y) >= x, 'add-overflow');
    }

    function sub(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x - y) <= x, 'sub-underflow');
    }

    function mul(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require(y == 0 || (z = x * y) / y == x, 'mul-overflow');
    }
}