// SPDX-License-Identifier: AGPL-3.0-only

/*
    Allocator.sol - SKALE Allocator
    Copyright (C) 2020-Present SKALE Labs
    @author Artem Payvin

    SKALE Allocator is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Allocator is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Allocator.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import "./IERC1820Registry.sol";
import "./IERC777Recipient.sol";
import "./IERC20.sol";
import "./IProxyFactory.sol";
import "./IProxyAdmin.sol";
import "./ITimeHelpers.sol";
import "./Escrow.sol";
import "./Permissions.sol";

/**
 * @title Allocator
 */
contract Allocator is Permissions, IERC777Recipient {

    uint256 constant private _SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant private _MONTHS_PER_YEAR = 12;

    enum TimeUnit {
        DAY,
        MONTH,
        YEAR
    }

    enum BeneficiaryStatus {
        UNKNOWN,
        CONFIRMED,
        ACTIVE,
        TERMINATED
    }

    struct Plan {
        uint256 totalVestingDuration; // months
        uint256 vestingCliff; // months
        TimeUnit vestingIntervalTimeUnit;
        uint256 vestingInterval; // amount of days/months/years
        bool isDelegationAllowed;
        bool isTerminatable;
    }

    struct Beneficiary {
        BeneficiaryStatus status;
        uint256 planId;
        uint256 startMonth;
        uint256 fullAmount;
        uint256 amountAfterLockup;
    }

    event PlanCreated(
        uint256 id
    );

    IERC1820Registry private _erc1820;

    // array of Plan configs
    Plan[] private _plans;

    bytes32 public constant VESTING_MANAGER_ROLE = keccak256("VESTING_MANAGER_ROLE");

    //       beneficiary => beneficiary plan params
    mapping (address => Beneficiary) private _beneficiaries;

    //       beneficiary => Escrow
    mapping (address => Escrow) private _beneficiaryToEscrow;

    modifier onlyVestingManager() {
        require(
            hasRole(VESTING_MANAGER_ROLE, _msgSender()),
            "Message sender is not a vesting manager"
        );
        _;
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )
        external override
        allow("SkaleToken")
        // solhint-disable-next-line no-empty-blocks
    {

    }

    /**
     * @dev Allows Vesting manager to activate a vesting and transfer locked
     * tokens from the Allocator contract to the associated Escrow address.
     * 
     * Requirements:
     * 
     * - Beneficiary address must be already confirmed.
     */
    function startVesting(address beneficiary) external onlyVestingManager {
        require(
            _beneficiaries[beneficiary].status == BeneficiaryStatus.CONFIRMED,
            "Beneficiary has inappropriate status"
        );
        _beneficiaries[beneficiary].status = BeneficiaryStatus.ACTIVE;
        require(
            IERC20(contractManager.getContract("SkaleToken")).transfer(
                address(_beneficiaryToEscrow[beneficiary]),
                _beneficiaries[beneficiary].fullAmount
            ),
            "Error of token sending"
        );
    }

    /**
     * @dev Allows Vesting manager to define and add a Plan.
     * 
     * Requirements:
     * 
     * - Vesting cliff period must be less than or equal to the full period.
     * - Vesting step time unit must be in days, months, or years.
     * - Total vesting duration must equal vesting cliff plus entire vesting schedule.
     */
    function addPlan(
        uint256 vestingCliff, // months
        uint256 totalVestingDuration, // months
        TimeUnit vestingIntervalTimeUnit, // 0 - day 1 - month 2 - year
        uint256 vestingInterval, // months or days or years
        bool canDelegate, // can beneficiary delegate all un-vested tokens
        bool isTerminatable
    )
        external
        onlyVestingManager
    {
        require(totalVestingDuration > 0, "Vesting duration can't be zero");
        require(vestingInterval > 0, "Vesting interval can't be zero");
        require(totalVestingDuration >= vestingCliff, "Cliff period exceeds total vesting duration");
        // can't check if vesting interval in days is correct because it depends on startMonth
        // This check is in connectBeneficiaryToPlan
        if (vestingIntervalTimeUnit == TimeUnit.MONTH) {
            uint256 vestingDurationAfterCliff = totalVestingDuration - vestingCliff;
            require(
                vestingDurationAfterCliff.mod(vestingInterval) == 0,
                "Vesting duration can't be divided into equal intervals"
            );
        } else if (vestingIntervalTimeUnit == TimeUnit.YEAR) {
            uint256 vestingDurationAfterCliff = totalVestingDuration - vestingCliff;
            require(
                vestingDurationAfterCliff.mod(vestingInterval.mul(_MONTHS_PER_YEAR)) == 0,
                "Vesting duration can't be divided into equal intervals"
            );
        }
        
        _plans.push(Plan({
            totalVestingDuration: totalVestingDuration,
            vestingCliff: vestingCliff,
            vestingIntervalTimeUnit: vestingIntervalTimeUnit,
            vestingInterval: vestingInterval,
            isDelegationAllowed: canDelegate,
            isTerminatable: isTerminatable
        }));
        emit PlanCreated(_plans.length);
    }

    /**
     * @dev Allows Vesting manager to register a beneficiary to a Plan.
     * 
     * Requirements:
     * 
     * - Plan must already exist.
     * - The vesting amount must be less than or equal to the full allocation.
     * - The beneficiary address must not already be included in the any other Plan.
     */
    function connectBeneficiaryToPlan(
        address beneficiary,
        uint256 planId,
        uint256 startMonth,
        uint256 fullAmount,
        uint256 lockupAmount
    )
        external
        onlyVestingManager
    {
        require(_plans.length >= planId && planId > 0, "Plan does not exist");
        require(fullAmount >= lockupAmount, "Incorrect amounts");
        require(_beneficiaries[beneficiary].status == BeneficiaryStatus.UNKNOWN, "Beneficiary is already added");
        if (_plans[planId - 1].vestingIntervalTimeUnit == TimeUnit.DAY) {
            uint256 vestingDurationInDays = _daysBetweenMonths(
                startMonth.add(_plans[planId - 1].vestingCliff),
                startMonth.add(_plans[planId - 1].totalVestingDuration)
            );
            require(
                vestingDurationInDays.mod(_plans[planId - 1].vestingInterval) == 0,
                "Vesting duration can't be divided into equal intervals"
            );
        }
        _beneficiaries[beneficiary] = Beneficiary({
            status: BeneficiaryStatus.CONFIRMED,
            planId: planId,
            startMonth: startMonth,
            fullAmount: fullAmount,
            amountAfterLockup: lockupAmount
        });
        _beneficiaryToEscrow[beneficiary] = _deployEscrow(beneficiary);
    }

    /**
     * @dev Allows Vesting manager to terminate vesting of a Escrow. Performed when
     * a beneficiary is terminated.
     * 
     * Requirements:
     * 
     * - Vesting must be active.
     */
    function stopVesting(address beneficiary) external onlyVestingManager {
        require(
            _beneficiaries[beneficiary].status == BeneficiaryStatus.ACTIVE,
            "Cannot stop vesting for a non active beneficiary"
        );
        require(
            _plans[_beneficiaries[beneficiary].planId - 1].isTerminatable,
            "Can't stop vesting for beneficiary with this plan"
        );
        _beneficiaries[beneficiary].status = BeneficiaryStatus.TERMINATED;
        Escrow(_beneficiaryToEscrow[beneficiary]).cancelVesting(calculateVestedAmount(beneficiary));
    }

    /**
     * @dev Returns vesting start month of the beneficiary's Plan.
     */
    function getStartMonth(address beneficiary) external view returns (uint) {
        return _beneficiaries[beneficiary].startMonth;
    }

    /**
     * @dev Returns the final vesting date of the beneficiary's Plan.
     */
    function getFinishVestingTime(address beneficiary) external view returns (uint) {
        ITimeHelpers timeHelpers = ITimeHelpers(contractManager.getContract("TimeHelpers"));
        Beneficiary memory beneficiaryPlan = _beneficiaries[beneficiary];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];
        return timeHelpers.monthToTimestamp(beneficiaryPlan.startMonth.add(planParams.totalVestingDuration));
    }

    /**
     * @dev Returns the vesting cliff period in months.
     */
    function getVestingCliffInMonth(address beneficiary) external view returns (uint) {
        return _plans[_beneficiaries[beneficiary].planId - 1].vestingCliff;
    }

    /**
     * @dev Confirms whether the beneficiary is active in the Plan.
     */
    function isVestingActive(address beneficiary) external view returns (bool) {
        return _beneficiaries[beneficiary].status == BeneficiaryStatus.ACTIVE;
    }

    /**
     * @dev Confirms whether the beneficiary is registered in a Plan.
     */
    function isBeneficiaryRegistered(address beneficiary) external view returns (bool) {
        return _beneficiaries[beneficiary].status != BeneficiaryStatus.UNKNOWN;
    }

    /**
     * @dev Confirms whether the beneficiary's Plan allows all un-vested tokens to be
     * delegated.
     */
    function isDelegationAllowed(address beneficiary) external view returns (bool) {
        return _plans[_beneficiaries[beneficiary].planId - 1].isDelegationAllowed;
    }

    /**
     * @dev Returns the locked and unlocked (full) amount of tokens allocated to
     * the beneficiary address in Plan.
     */
    function getFullAmount(address beneficiary) external view returns (uint) {
        return _beneficiaries[beneficiary].fullAmount;
    }

    /**
     * @dev Returns the Escrow contract by beneficiary.
     */
    function getEscrowAddress(address beneficiary) external view returns (address) {
        return address(_beneficiaryToEscrow[beneficiary]);
    }

    /**
     * @dev Returns the timestamp when vesting cliff ends and periodic vesting
     * begins.
     */
    function getLockupPeriodEndTimestamp(address beneficiary) external view returns (uint) {
        ITimeHelpers timeHelpers = ITimeHelpers(contractManager.getContract("TimeHelpers"));
        Beneficiary memory beneficiaryPlan = _beneficiaries[beneficiary];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];
        return timeHelpers.monthToTimestamp(beneficiaryPlan.startMonth.add(planParams.vestingCliff));
    }

    /**
     * @dev Returns the time of the next vesting event.
     */
    function getTimeOfNextVest(address beneficiary) external view returns (uint) {
        ITimeHelpers timeHelpers = ITimeHelpers(contractManager.getContract("TimeHelpers"));

        Beneficiary memory beneficiaryPlan = _beneficiaries[beneficiary];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];

        uint256 firstVestingMonth = beneficiaryPlan.startMonth.add(planParams.vestingCliff);
        uint256 lockupEndTimestamp = timeHelpers.monthToTimestamp(firstVestingMonth);
        if (now < lockupEndTimestamp) {
            return lockupEndTimestamp;
        }
        require(
            now < timeHelpers.monthToTimestamp(beneficiaryPlan.startMonth.add(planParams.totalVestingDuration)),
            "Vesting is over"
        );
        require(beneficiaryPlan.status != BeneficiaryStatus.TERMINATED, "Vesting was stopped");
        
        uint256 currentMonth = timeHelpers.getCurrentMonth();
        if (planParams.vestingIntervalTimeUnit == TimeUnit.DAY) {
            // TODO: it may be simplified if TimeHelpers contract in skale-manager is updated
            uint daysPassedBeforeCurrentMonth = _daysBetweenMonths(firstVestingMonth, currentMonth);
            uint256 currentMonthBeginningTimestamp = timeHelpers.monthToTimestamp(currentMonth);
            uint256 daysPassedInCurrentMonth = now.sub(currentMonthBeginningTimestamp).div(_SECONDS_PER_DAY);
            uint256 daysPassedBeforeNextVest = _calculateNextVestingStep(
                daysPassedBeforeCurrentMonth.add(daysPassedInCurrentMonth),
                planParams.vestingInterval
            );
            return currentMonthBeginningTimestamp.add(
                daysPassedBeforeNextVest
                    .sub(daysPassedBeforeCurrentMonth)
                    .mul(_SECONDS_PER_DAY)
            );
        } else if (planParams.vestingIntervalTimeUnit == TimeUnit.MONTH) {
            return timeHelpers.monthToTimestamp(
                firstVestingMonth.add(
                    _calculateNextVestingStep(currentMonth.sub(firstVestingMonth), planParams.vestingInterval)
                )
            );
        } else if (planParams.vestingIntervalTimeUnit == TimeUnit.YEAR) {
            return timeHelpers.monthToTimestamp(
                firstVestingMonth.add(
                    _calculateNextVestingStep(
                        currentMonth.sub(firstVestingMonth),
                        planParams.vestingInterval.mul(_MONTHS_PER_YEAR)
                    )
                )
            );
        } else {
            revert("Vesting interval timeunit is incorrect");
        }
    }

    /**
     * @dev Returns the Plan parameters.
     * 
     * Requirements:
     * 
     * - Plan must already exist.
     */
    function getPlan(uint256 planId) external view returns (Plan memory) {
        require(planId > 0 && planId <= _plans.length, "Plan Round does not exist");
        return _plans[planId - 1];
    }

    /**
     * @dev Returns the Plan parameters for a beneficiary address.
     * 
     * Requirements:
     * 
     * - Beneficiary address must be registered to an Plan.
     */
    function getBeneficiaryPlanParams(address beneficiary) external view returns (Beneficiary memory) {
        require(_beneficiaries[beneficiary].status != BeneficiaryStatus.UNKNOWN, "Plan beneficiary is not registered");
        return _beneficiaries[beneficiary];
    }

    function initialize(address contractManagerAddress) public override initializer {
        Permissions.initialize(contractManagerAddress);
        _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    /**
     * @dev Calculates and returns the vested token amount.
     */
    function calculateVestedAmount(address wallet) public view returns (uint256 vestedAmount) {
        ITimeHelpers timeHelpers = ITimeHelpers(contractManager.getContract("TimeHelpers"));
        Beneficiary memory beneficiaryPlan = _beneficiaries[wallet];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];
        vestedAmount = 0;
        uint256 currentMonth = timeHelpers.getCurrentMonth();
        if (currentMonth >= beneficiaryPlan.startMonth.add(planParams.vestingCliff)) {
            vestedAmount = beneficiaryPlan.amountAfterLockup;
            if (currentMonth >= beneficiaryPlan.startMonth.add(planParams.totalVestingDuration)) {
                vestedAmount = beneficiaryPlan.fullAmount;
            } else {
                uint256 payment = _getSinglePaymentSize(
                    wallet,
                    beneficiaryPlan.fullAmount,
                    beneficiaryPlan.amountAfterLockup
                );
                vestedAmount = vestedAmount.add(payment.mul(_getNumberOfCompletedVestingEvents(wallet)));
            }
        }
    }

    /**
     * @dev Returns the number of vesting events that have completed.
     */
    function _getNumberOfCompletedVestingEvents(address wallet) internal view returns (uint) {
        ITimeHelpers timeHelpers = ITimeHelpers(contractManager.getContract("TimeHelpers"));
        
        Beneficiary memory beneficiaryPlan = _beneficiaries[wallet];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];

        uint256 firstVestingMonth = beneficiaryPlan.startMonth.add(planParams.vestingCliff);
        if (now < timeHelpers.monthToTimestamp(firstVestingMonth)) {
            return 0;
        } else {
            uint256 currentMonth = timeHelpers.getCurrentMonth();
            if (planParams.vestingIntervalTimeUnit == TimeUnit.DAY) {
                return _daysBetweenMonths(firstVestingMonth, currentMonth)
                    .add(
                        now
                            .sub(timeHelpers.monthToTimestamp(currentMonth))
                            .div(_SECONDS_PER_DAY)
                    )
                    .div(planParams.vestingInterval);
            } else if (planParams.vestingIntervalTimeUnit == TimeUnit.MONTH) {
                return currentMonth
                    .sub(firstVestingMonth)
                    .div(planParams.vestingInterval);
            } else if (planParams.vestingIntervalTimeUnit == TimeUnit.YEAR) {
                return currentMonth
                    .sub(firstVestingMonth)
                    .div(_MONTHS_PER_YEAR)
                    .div(planParams.vestingInterval);
            } else {
                revert("Unknown time unit");
            }
        }
    }

    /**
     * @dev Returns the number of total vesting events.
     */
    function _getNumberOfAllVestingEvents(address wallet) internal view returns (uint) {
        Beneficiary memory beneficiaryPlan = _beneficiaries[wallet];
        Plan memory planParams = _plans[beneficiaryPlan.planId - 1];
        if (planParams.vestingIntervalTimeUnit == TimeUnit.DAY) {
            return _daysBetweenMonths(
                beneficiaryPlan.startMonth.add(planParams.vestingCliff),
                beneficiaryPlan.startMonth.add(planParams.totalVestingDuration)
            ).div(planParams.vestingInterval);
        } else if (planParams.vestingIntervalTimeUnit == TimeUnit.MONTH) {
            return planParams.totalVestingDuration
                .sub(planParams.vestingCliff)
                .div(planParams.vestingInterval);
        } else if (planParams.vestingIntervalTimeUnit == TimeUnit.YEAR) {
            return planParams.totalVestingDuration
                .sub(planParams.vestingCliff)
                .div(_MONTHS_PER_YEAR)
                .div(planParams.vestingInterval);
        } else {
            revert("Unknown time unit");
        }
    }

    /**
     * @dev Returns the amount of tokens that are unlocked in each vesting
     * period.
     */
    function _getSinglePaymentSize(
        address wallet,
        uint256 fullAmount,
        uint256 afterLockupPeriodAmount
    )
        internal
        view
        returns(uint)
    {
        return fullAmount.sub(afterLockupPeriodAmount).div(_getNumberOfAllVestingEvents(wallet));
    }

    function _deployEscrow(address beneficiary) private returns (Escrow) {
        // TODO: replace with ProxyFactory when @openzeppelin/upgrades will be compatible with solidity 0.6
        IProxyFactory proxyFactory = IProxyFactory(contractManager.getContract("ProxyFactory"));
        Escrow escrow = Escrow(contractManager.getContract("Escrow"));
        // TODO: replace with ProxyAdmin when @openzeppelin/upgrades will be compatible with solidity 0.6
        IProxyAdmin proxyAdmin = IProxyAdmin(contractManager.getContract("ProxyAdmin"));

        return Escrow(
            proxyFactory.deploy(
                uint256(bytes32(bytes20(beneficiary))),
                proxyAdmin.getProxyImplementation(address(escrow)),
                address(proxyAdmin),
                abi.encodeWithSelector(
                    Escrow.initialize.selector,
                    address(contractManager),
                    beneficiary
                )
            )
        );
    }

    function _daysBetweenMonths(uint256 beginMonth, uint256 endMonth) private view returns (uint256) {
        assert(beginMonth <= endMonth);
        ITimeHelpers timeHelpers = ITimeHelpers(contractManager.getContract("TimeHelpers"));
        uint256 beginTimestamp = timeHelpers.monthToTimestamp(beginMonth);
        uint256 endTimestamp = timeHelpers.monthToTimestamp(endMonth);
        uint256 secondsPassed = endTimestamp.sub(beginTimestamp);
        require(secondsPassed.mod(_SECONDS_PER_DAY) == 0, "Internal error in calendar");
        return secondsPassed.div(_SECONDS_PER_DAY);
    }

    /**
     * @dev returns time of next vest in abstract time units named "step"
     * Examples:
     *     if current step is 5 and vesting interval is 7 function returns 7.
     *     if current step is 17 and vesting interval is 7 function returns 21.
     */
    function _calculateNextVestingStep(uint256 currentStep, uint256 vestingInterval) private pure returns (uint256) {
        return currentStep
            .add(vestingInterval)
            .sub(
                currentStep.mod(vestingInterval)
            );
    }
}