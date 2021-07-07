// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "Ownable.sol";
import "SafeMath.sol";
import "Context.sol";
import "IERC20.sol";

contract NetVrkVesting is Context, Ownable {
    using SafeMath for uint256;

    struct VestingSchedule {
        uint256 totalAmount; // Total amount of tokens to be vested.
        uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    mapping(address => VestingSchedule) public recipients;
    uint256 public startTime = block.timestamp;
    uint256 public currentTime = block.timestamp;
    bool public isStartTimeSet;
    uint256 public withdrawInterval; // Amount of time in seconds between withdrawal periods.
    uint256 public releaseRate; // Release percent in each withdrawing interval
    uint256 public totalAmount; // Total amount of tokens to be vested.
    uint256 public unallocatedAmount; // The amount of tokens that are not allocated yet.
    uint256 public initialUnlock; // Percent of tokens initially unlocked
    uint256 public lockPeriod; // Number of periods before start release.
    IERC20 public flameToken;
    event VestingScheduleRegistered(
        address registeredAddress,
        uint256 totalAmount
    );
    event VestingSchedulesRegistered(
        address[] registeredAddresses,
        uint256[] totalAmounts
    );
    event Withdraw(address registeredAddress, uint256 amountWithdrawn);
    event StartTimeSet(uint256 startTime);

    constructor(
        address _flameToken,
        uint256 _totalAmount,
        uint256 _initialUnlock,
        uint256 _withdrawInterval,
        uint256 _releaseRate,
        uint256 _lockPeriod
    ) {
        require(_totalAmount > 0);
        require(_withdrawInterval > 0);
        flameToken = IERC20(_flameToken);
        totalAmount = _totalAmount;
        initialUnlock = _initialUnlock;
        unallocatedAmount = _totalAmount;
        withdrawInterval = _withdrawInterval;
        releaseRate = _releaseRate;
        lockPeriod = _lockPeriod;
        isStartTimeSet = false;
    }

    function addRecipient(address _newRecipient, uint256 _totalAmount)
        external
        onlyOwner
    {
        // Only allow to add recipient before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp);
        require(_newRecipient != address(0));
        unallocatedAmount = unallocatedAmount.add(
            recipients[_newRecipient].totalAmount
        );
        require(_totalAmount > 0 && _totalAmount <= unallocatedAmount);
        recipients[_newRecipient] = VestingSchedule({
            totalAmount: _totalAmount,
            amountWithdrawn: 0
        });
        unallocatedAmount = unallocatedAmount.sub(_totalAmount);
        emit VestingScheduleRegistered(_newRecipient, _totalAmount);
    }

    function addRecipients(
        address[] memory _newRecipients,
        uint256[] memory _totalAmounts
    ) external onlyOwner {
        // Only allow to add recipient before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp);
        for (uint256 i = 0; i < _newRecipients.length; i++) {
            address _newRecipient = _newRecipients[i];
            uint256 _totalAmount = _totalAmounts[i];
            require(_newRecipient != address(0));
            unallocatedAmount = unallocatedAmount.add(
                recipients[_newRecipient].totalAmount
            );
            require(_totalAmount > 0 && _totalAmount <= unallocatedAmount);
            recipients[_newRecipient] = VestingSchedule({
                totalAmount: _totalAmount,
                amountWithdrawn: 0
            });
            unallocatedAmount = unallocatedAmount.sub(_totalAmount);
        }
        emit VestingSchedulesRegistered(_newRecipients, _totalAmounts);
    }

    function setStartTime(uint256 _newStartTime) external onlyOwner {
        // Only allow to change start time before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp);
        require(_newStartTime > block.timestamp);
        startTime = _newStartTime;
        isStartTimeSet = true;
        emit StartTimeSet(_newStartTime);
    }

    function getStartDateTime() public view returns (uint256 _startTime) {
        return startTime;
    }

    function getEndDateTime() public view returns (uint256 _endTime) {
        return startTime.add(lockPeriod);
    }

    function getTotalVestedAmount()
        public
        view
        returns (uint256 _amountVested)
    {
        return totalAmount;
    }

    function getAvailableClaimAmount()
        public
        view
        returns (uint256 _amountClaim)
    {
        return unallocatedAmount;
    }

    // Returns the amount of tokens you can withdraw
    function vested(address beneficiary)
        public
        view
        virtual
        returns (uint256 _amountVested)
    {
        VestingSchedule memory _vestingSchedule = recipients[beneficiary];
        if (
            !isStartTimeSet ||
            (_vestingSchedule.totalAmount == 0) ||
            (block.timestamp < startTime) ||
            (block.timestamp < startTime.add(lockPeriod))
        ) {
            return 0;
        }
        uint256 initialUnlockAmount = _vestingSchedule
        .totalAmount
        .mul(initialUnlock)
        .div(100);
        uint256 unlockRate = _vestingSchedule
        .totalAmount
        .mul(releaseRate)
        .div(100)
        .div(withdrawInterval);
        uint256 vestedAmount = unlockRate
        .mul(block.timestamp.sub(startTime).sub(lockPeriod))
        .add(initialUnlockAmount);
        if (vestedAmount > _vestingSchedule.totalAmount) {
            return _vestingSchedule.totalAmount;
        }
        return vestedAmount;
    }

    function locked(address beneficiary) public view returns (uint256 amount) {
        return recipients[beneficiary].totalAmount.sub(vested(beneficiary));
    }

    function withdrawable(address beneficiary)
        public
        view
        returns (uint256 amount)
    {
        return vested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    function withdraw() external {
        VestingSchedule storage vestingSchedule = recipients[_msgSender()];
        if (vestingSchedule.totalAmount == 0) return;
        uint256 _vested = vested(_msgSender());
        uint256 _withdrawable = withdrawable(_msgSender());
        vestingSchedule.amountWithdrawn = _vested;
        require(_withdrawable > 0, "Nothing to withdraw");
        require(flameToken.transfer(_msgSender(), _withdrawable));
        emit Withdraw(_msgSender(), _withdrawable);
    }
}