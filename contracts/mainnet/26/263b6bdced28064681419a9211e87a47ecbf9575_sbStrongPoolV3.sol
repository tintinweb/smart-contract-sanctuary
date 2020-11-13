// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./sbControllerInterface.sol";
import "./sbVotesInterface.sol";

contract sbStrongPoolV3 {
    event ServiceMinMineUpdated(uint256 amount);
    event MinerMinMineUpdated(uint256 amount);
    event MinedFor(
        address indexed miner,
        address indexed receiver,
        uint256 amount,
        uint256 indexed day
    );
    event RewardsReceived(uint256 indexed day, uint256 amount);
    event Mined(address indexed miner, uint256 amount, uint256 indexed day);
    event Unmined(address indexed miner, uint256 amount, uint256 indexed day);
    event MinedForVotesOnly(
        address indexed miner,
        uint256 amount,
        uint256 indexed day
    );
    event UnminedForVotesOnly(
        address indexed miner,
        uint256 amount,
        uint256 indexed day
    );
    event Claimed(address indexed miner, uint256 amount, uint256 indexed day);

    using SafeMath for uint256;

    bool internal initDone;

    IERC20 internal strongToken;
    sbControllerInterface internal sbController;
    sbVotesInterface internal sbVotes;
    address internal sbTimelock;

    uint256 internal serviceMinMine;
    uint256 internal minerMinMine;

    mapping(address => uint256[]) internal minerMineDays;
    mapping(address => uint256[]) internal minerMineAmounts;
    mapping(address => uint256[]) internal minerMineMineSeconds;

    uint256[] internal mineDays;
    uint256[] internal mineAmounts;
    uint256[] internal mineMineSeconds;

    mapping(address => uint256) internal minerDayLastClaimedFor;
    mapping(uint256 => uint256) internal dayRewards;

    mapping(address => uint256) internal mineForVotes;

    address internal superAdmin;
    address internal pendingSuperAdmin;
    uint256 internal delayDays;

    function removeTokens(address account, uint256 amount) public {
        require(msg.sender == superAdmin, "not superAdmin");
        strongToken.transfer(account, amount);
    }

    function burnTokens(uint256 amount) public {
        require(msg.sender == superAdmin, "not superAdmin");
        strongToken.transfer(
            address(0x000000000000000000000000000000000000dEaD),
            amount
        );
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(
            msg.sender == superAdmin && msg.sender != address(0),
            "not superAdmin"
        );
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(
            msg.sender == pendingSuperAdmin && msg.sender != address(0),
            "not pendingSuperAdmin"
        );
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    function getSuperAdminAddressUsed() public view returns (address) {
        return superAdmin;
    }

    function getPendingSuperAdminAddressUsed() public view returns (address) {
        return pendingSuperAdmin;
    }

    function setDelayDays(uint256 dayCount) external {
        require(
            msg.sender == superAdmin && msg.sender != address(0),
            "not superAdmin"
        );
        require(dayCount >= 1, "zero");
        delayDays = dayCount;
    }

    function getDelayDays() public view returns (uint256) {
        return delayDays;
    }

    function serviceMinMined(address miner) external view returns (bool) {
        uint256 currentDay = _getCurrentDay();
        (, uint256 twoDaysAgoMine, ) = _getMinerMineData(
            miner,
            currentDay.sub(2)
        );
        (, uint256 oneDayAgoMine, ) = _getMinerMineData(
            miner,
            currentDay.sub(1)
        );
        (, uint256 todayMine, ) = _getMinerMineData(miner, currentDay);
        return
            twoDaysAgoMine >= serviceMinMine &&
            oneDayAgoMine >= serviceMinMine &&
            todayMine >= serviceMinMine;
    }

    function minerMinMined(address miner) external view returns (bool) {
        (, uint256 todayMine, ) = _getMinerMineData(miner, _getCurrentDay());
        return todayMine >= minerMinMine;
    }

    function updateServiceMinMine(uint256 serviceMinMineAmount) external {
        require(serviceMinMineAmount > 0, "zero");
        require(msg.sender == sbTimelock, "not sbTimelock");
        serviceMinMine = serviceMinMineAmount;
        emit ServiceMinMineUpdated(serviceMinMineAmount);
    }

    function updateMinerMinMine(uint256 minerMinMineAmount) external {
        require(minerMinMineAmount > 0, "zero");
        require(msg.sender == sbTimelock, "not sbTimelock");
        minerMinMine = minerMinMineAmount;
        emit MinerMinMineUpdated(minerMinMineAmount);
    }

    function mineFor(address miner, uint256 amount) external {
        require(amount > 0, "zero");
        require(miner != address(0), "zero address");
        if (msg.sender != address(this)) {
            strongToken.transferFrom(msg.sender, address(this), amount);
        }
        uint256 currentDay = _getCurrentDay();
        uint256 startDay = sbController.getStartDay();
        uint256 MAX_YEARS = sbController.getMaxYears();
        uint256 year = _getYearDayIsIn(currentDay, startDay);
        require(year <= MAX_YEARS, "year limit met");
        _update(
            minerMineDays[miner],
            minerMineAmounts[miner],
            minerMineMineSeconds[miner],
            amount,
            true,
            currentDay
        );
        _update(
            mineDays,
            mineAmounts,
            mineMineSeconds,
            amount,
            true,
            currentDay
        );
        sbVotes.updateVotes(miner, amount, true);
        emit MinedFor(msg.sender, miner, amount, currentDay);
    }

    function getMineData(uint256 day)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return _getMineData(day);
    }

    function receiveRewards(uint256 day, uint256 amount) external {
        require(amount > 0, "zero");
        require(msg.sender == address(sbController), "not sbController");
        strongToken.transferFrom(address(sbController), address(this), amount);
        dayRewards[day] = dayRewards[day].add(amount);
        emit RewardsReceived(day, amount);
    }

    function getDayRewards(uint256 day) public view returns (uint256) {
        require(day <= _getCurrentDay(), "invalid day");
        return dayRewards[day];
    }

    function mine(uint256 amount) public {
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        uint256 currentDay = _getCurrentDay();
        uint256 startDay = sbController.getStartDay();
        uint256 MAX_YEARS = sbController.getMaxYears();
        uint256 year = _getYearDayIsIn(currentDay, startDay);
        require(year <= MAX_YEARS, "year limit met");
        _update(
            minerMineDays[msg.sender],
            minerMineAmounts[msg.sender],
            minerMineMineSeconds[msg.sender],
            amount,
            true,
            currentDay
        );
        _update(
            mineDays,
            mineAmounts,
            mineMineSeconds,
            amount,
            true,
            currentDay
        );
        sbVotes.updateVotes(msg.sender, amount, true);
        emit Mined(msg.sender, amount, currentDay);
    }

    function unmine(uint256 amount) public {
        require(amount > 0, "zero");
        uint256 currentDay = _getCurrentDay();
        _update(
            minerMineDays[msg.sender],
            minerMineAmounts[msg.sender],
            minerMineMineSeconds[msg.sender],
            amount,
            false,
            currentDay
        );
        _update(
            mineDays,
            mineAmounts,
            mineMineSeconds,
            amount,
            false,
            currentDay
        );
        sbVotes.updateVotes(msg.sender, amount, false);
        strongToken.transfer(msg.sender, amount);
        emit Unmined(msg.sender, amount, currentDay);
    }

    function mineForVotesOnly(uint256 amount) public {
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        uint256 currentDay = _getCurrentDay();
        uint256 startDay = sbController.getStartDay();
        uint256 MAX_YEARS = sbController.getMaxYears();
        uint256 year = _getYearDayIsIn(currentDay, startDay);
        require(year <= MAX_YEARS, "year limit met");
        mineForVotes[msg.sender] = mineForVotes[msg.sender].add(amount);
        sbVotes.updateVotes(msg.sender, amount, true);
        emit MinedForVotesOnly(msg.sender, amount, currentDay);
    }

    function unmineForVotesOnly(uint256 amount) public {
        require(amount > 0, "zero");
        require(mineForVotes[msg.sender] >= amount, "not enough mine");
        mineForVotes[msg.sender] = mineForVotes[msg.sender].sub(amount);
        sbVotes.updateVotes(msg.sender, amount, false);
        strongToken.transfer(msg.sender, amount);
        emit UnminedForVotesOnly(msg.sender, amount, _getCurrentDay());
    }

    function getMineForVotesOnly(address miner) public view returns (uint256) {
        return mineForVotes[miner];
    }

    function getServiceMinMineAmount() public view returns (uint256) {
        return serviceMinMine;
    }

    function getMinerMinMineAmount() public view returns (uint256) {
        return minerMinMine;
    }

    function getSbControllerAddressUsed() public view returns (address) {
        return address(sbController);
    }

    function getStrongAddressUsed() public view returns (address) {
        return address(strongToken);
    }

    function getSbVotesAddressUsed() public view returns (address) {
        return address(sbVotes);
    }

    function getSbTimelockAddressUsed() public view returns (address) {
        return sbTimelock;
    }

    function getMinerDayLastClaimedFor(address miner)
        public
        view
        returns (uint256)
    {
        return
            minerDayLastClaimedFor[miner] == 0
                ? sbController.getStartDay().sub(1)
                : minerDayLastClaimedFor[miner];
    }

    function claimAll() public {
        require(delayDays > 0, "zero");
        uint256 currentDay = _getCurrentDay();
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[msg.sender] == 0
            ? sbController.getStartDay().sub(1)
            : minerDayLastClaimedFor[msg.sender];
        require(
            currentDay > dayLastClaimedFor.add(delayDays),
            "already claimed"
        );
        // require(sbController.upToDate(), 'need rewards released');
        _claim(currentDay, msg.sender, dayLastClaimedFor);
    }

    function claimUpTo(uint256 day) public {
        require(delayDays > 0, "zero");
        require(day <= _getCurrentDay(), "invalid day");
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[msg.sender] == 0
            ? sbController.getStartDay().sub(1)
            : minerDayLastClaimedFor[msg.sender];
        require(day > dayLastClaimedFor.add(delayDays), "already claimed");
        // require(sbController.upToDate(), 'need rewards released');
        _claim(day, msg.sender, dayLastClaimedFor);
    }

    function getRewardsDueAll(address miner) public view returns (uint256) {
        require(delayDays > 0, "zero");
        uint256 currentDay = _getCurrentDay();
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[miner] == 0
            ? sbController.getStartDay().sub(1)
            : minerDayLastClaimedFor[miner];
        if (!(currentDay > dayLastClaimedFor.add(delayDays))) {
            return 0;
        }
        // require(sbController.upToDate(), 'need rewards released');
        return _getRewardsDue(currentDay, miner, dayLastClaimedFor);
    }

    function getRewardsDueUpTo(uint256 day, address miner)
        public
        view
        returns (uint256)
    {
        require(delayDays > 0, "zero");
        require(day <= _getCurrentDay(), "invalid day");
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[miner] == 0
            ? sbController.getStartDay().sub(1)
            : minerDayLastClaimedFor[miner];
        if (!(day > dayLastClaimedFor.add(delayDays))) {
            return 0;
        }
        // require(sbController.upToDate(), 'need rewards released');
        return _getRewardsDue(day, miner, dayLastClaimedFor);
    }

    function getMinerMineData(address miner, uint256 day)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return _getMinerMineData(miner, day);
    }

    function _getMineData(uint256 day)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return _get(mineDays, mineAmounts, mineMineSeconds, day);
    }

    function _getMinerMineData(address miner, uint256 day)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256[] memory _Days = minerMineDays[miner];
        uint256[] memory _Amounts = minerMineAmounts[miner];
        uint256[] memory _UnitSeconds = minerMineMineSeconds[miner];
        return _get(_Days, _Amounts, _UnitSeconds, day);
    }

    function _get(
        uint256[] memory _Days,
        uint256[] memory _Amounts,
        uint256[] memory _UnitSeconds,
        uint256 day
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 len = _Days.length;
        if (len == 0) {
            return (day, 0, 0);
        }
        if (day < _Days[0]) {
            return (day, 0, 0);
        }
        uint256 lastIndex = len.sub(1);
        uint256 lastMinedDay = _Days[lastIndex];
        if (day == lastMinedDay) {
            return (day, _Amounts[lastIndex], _UnitSeconds[lastIndex]);
        } else if (day > lastMinedDay) {
            return (day, _Amounts[lastIndex], _Amounts[lastIndex].mul(1 days));
        }
        return _find(_Days, _Amounts, _UnitSeconds, day);
    }

    function _find(
        uint256[] memory _Days,
        uint256[] memory _Amounts,
        uint256[] memory _UnitSeconds,
        uint256 day
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 left = 0;
        uint256 right = _Days.length.sub(1);
        uint256 middle = right.add(left).div(2);
        while (left < right) {
            if (_Days[middle] == day) {
                return (day, _Amounts[middle], _UnitSeconds[middle]);
            } else if (_Days[middle] > day) {
                if (middle > 0 && _Days[middle.sub(1)] < day) {
                    return (
                        day,
                        _Amounts[middle.sub(1)],
                        _Amounts[middle.sub(1)].mul(1 days)
                    );
                }
                if (middle == 0) {
                    return (day, 0, 0);
                }
                right = middle.sub(1);
            } else if (_Days[middle] < day) {
                if (
                    middle < _Days.length.sub(1) && _Days[middle.add(1)] > day
                ) {
                    return (
                        day,
                        _Amounts[middle],
                        _Amounts[middle].mul(1 days)
                    );
                }
                left = middle.add(1);
            }
            middle = right.add(left).div(2);
        }
        if (_Days[middle] != day) {
            return (day, 0, 0);
        } else {
            return (day, _Amounts[middle], _UnitSeconds[middle]);
        }
    }

    function _update(
        uint256[] storage _Days,
        uint256[] storage _Amounts,
        uint256[] storage _UnitSeconds,
        uint256 amount,
        bool adding,
        uint256 currentDay
    ) internal {
        uint256 len = _Days.length;
        uint256 secondsInADay = 1 days;
        uint256 secondsSinceStartOfDay = block.timestamp % secondsInADay;
        uint256 secondsUntilEndOfDay = secondsInADay.sub(
            secondsSinceStartOfDay
        );

        if (len == 0) {
            if (adding) {
                _Days.push(currentDay);
                _Amounts.push(amount);
                _UnitSeconds.push(amount.mul(secondsUntilEndOfDay));
            } else {
                require(false, "1: not enough mine");
            }
        } else {
            uint256 lastIndex = len.sub(1);
            uint256 lastMinedDay = _Days[lastIndex];
            uint256 lastMinedAmount = _Amounts[lastIndex];
            uint256 lastUnitSeconds = _UnitSeconds[lastIndex];

            uint256 newAmount;
            uint256 newUnitSeconds;

            if (lastMinedDay == currentDay) {
                if (adding) {
                    newAmount = lastMinedAmount.add(amount);
                    newUnitSeconds = lastUnitSeconds.add(
                        amount.mul(secondsUntilEndOfDay)
                    );
                } else {
                    require(lastMinedAmount >= amount, "2: not enough mine");
                    newAmount = lastMinedAmount.sub(amount);
                    newUnitSeconds = lastUnitSeconds.sub(
                        amount.mul(secondsUntilEndOfDay)
                    );
                }
                _Amounts[lastIndex] = newAmount;
                _UnitSeconds[lastIndex] = newUnitSeconds;
            } else {
                if (adding) {
                    newAmount = lastMinedAmount.add(amount);
                    newUnitSeconds = lastMinedAmount.mul(1 days).add(
                        amount.mul(secondsUntilEndOfDay)
                    );
                } else {
                    require(lastMinedAmount >= amount, "3: not enough mine");
                    newAmount = lastMinedAmount.sub(amount);
                    newUnitSeconds = lastMinedAmount.mul(1 days).sub(
                        amount.mul(secondsUntilEndOfDay)
                    );
                }
                _Days.push(currentDay);
                _Amounts.push(newAmount);
                _UnitSeconds.push(newUnitSeconds);
            }
        }
    }

    function _getCurrentDay() internal view returns (uint256) {
        return block.timestamp.div(1 days).add(1);
    }

    function _claim(
        uint256 upToDay,
        address miner,
        uint256 dayLastClaimedFor
    ) internal {
        uint256 rewards = _getRewardsDue(upToDay, miner, dayLastClaimedFor);
        require(rewards > 0, "no rewards");
        minerDayLastClaimedFor[miner] = upToDay.sub(delayDays);
        this.mineFor(miner, rewards);
        emit Claimed(miner, rewards, _getCurrentDay());
    }

    function _getRewardsDue(
        uint256 upToDay,
        address miner,
        uint256 dayLastClaimedFor
    ) internal view returns (uint256) {
        uint256 rewards;
        for (
            uint256 day = dayLastClaimedFor.add(1);
            day <= upToDay.sub(delayDays);
            day++
        ) {
            (, , uint256 minerMineSecondsForDay) = _getMinerMineData(
                miner,
                day
            );
            (, , uint256 mineSecondsForDay) = _getMineData(day);
            if (mineSecondsForDay == 0) {
                continue;
            }
            uint256 strongPoolDayRewards = dayRewards[day];
            if (strongPoolDayRewards == 0) {
                continue;
            }
            uint256 amount = strongPoolDayRewards
                .mul(minerMineSecondsForDay)
                .div(mineSecondsForDay);
            rewards = rewards.add(amount);
        }
        return rewards;
    }

    function _getYearDayIsIn(uint256 day, uint256 startDay)
        internal
        pure
        returns (uint256)
    {
        return day.sub(startDay).div(366).add(1); // dividing by 366 makes day 1 and 365 be in year 1
    }
}
