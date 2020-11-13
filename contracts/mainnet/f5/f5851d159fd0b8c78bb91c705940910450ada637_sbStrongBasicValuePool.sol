// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./sbEthFeePoolInterface.sol";
import "./sbControllerInterface.sol";

contract sbStrongBasicValuePool {
    using SafeMath for uint256;

    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;

    sbEthFeePoolInterface public sbEthFeePool;
    sbControllerInterface public sbController;
    IERC20 public token;

    mapping(address => uint256[]) public minerMineDays;
    mapping(address => uint256[]) public minerMineAmounts;
    mapping(address => uint256[]) public minerMineMineSeconds;

    uint256[] public mineDays;
    uint256[] public mineAmounts;
    uint256[] public mineMineSeconds;

    mapping(address => uint256) public minerDayLastClaimedFor;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistAmount;
    bool public whitelistActive;

    function init(
        address sbEthFeePoolAddress,
        address sbControllerAddress,
        address tokenAddress,
        address adminAddress,
        address superAdminAddress
    ) public {
        require(!initDone, "init done");
        sbEthFeePool = sbEthFeePoolInterface(sbEthFeePoolAddress);
        sbController = sbControllerInterface(sbControllerAddress);
        token = IERC20(tokenAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************
    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "not admin");
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "not pendingAdmin"
        );
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(msg.sender == superAdmin, "not superAdmin");
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

    // WHITELIST
    // *************************************************************************************
    function addToWhitelist(
        address[] memory miners,
        uint256[] memory amountsInWei
    ) public {
        require(msg.sender == superAdmin, "not admin");
        require(miners.length == amountsInWei.length, "lengths");
        require(miners.length != 0, "zero");
        for (uint256 i = 0; i < miners.length; i++) {
            require(!whitelist[miners[i]], "exists");
            whitelist[miners[i]] = true;
            whitelistAmount[miners[i]] = amountsInWei[i];
        }
    }

    function removeFromWhitelist(address miner) public {
        require(msg.sender == superAdmin, "not admin");
        require(whitelist[miner], "invalid miner");
        whitelist[miner] = false;
        whitelistAmount[miner] = 0;
        uint256 currentDay = _getCurrentDay();
        (, uint256 amount, ) = _getMinerMineData(miner, currentDay);
        if (amount != 0) {
            _update(
                minerMineDays[miner],
                minerMineAmounts[miner],
                minerMineMineSeconds[miner],
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
            token.transfer(miner, amount);
        }
    }

    function setWhitelistActiveState(bool activeState) public {
        require(msg.sender == superAdmin, "not admin");
        whitelistActive = activeState;
    }

    // MINING
    // *************************************************************************************
    function mine(uint256 amount) public payable {
        require(amount > 0, "zero");
        if (whitelistActive) {
            require(whitelist[msg.sender], "invalid miner");
            require(amount <= whitelistAmount[msg.sender], "1: too much");
        }
        uint256 currentDay = _getCurrentDay();
        (, uint256 tokens, ) = _getMinerMineData(msg.sender, currentDay);
        require(tokens <= whitelistAmount[msg.sender], "2: too much");
        (uint256 numerator, uint256 denominator) = sbController
            .getValuePoolMiningFee(address(this));
        uint256 fee = amount.mul(numerator).div(denominator);
        require(msg.value == fee, "invalid fee");
        sbEthFeePool.deposit{value: msg.value}();
        token.transferFrom(msg.sender, address(this), amount);

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
    }

    function unmine(uint256 amount) public payable {
        require(amount > 0, "zero");
        (uint256 numerator, uint256 denominator) = sbController
            .getValuePoolUnminingFee(address(this));
        uint256 fee = amount.mul(numerator).div(denominator);
        require(msg.value == fee, "invalid fee");
        sbEthFeePool.deposit{value: msg.value}();
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
        token.transfer(msg.sender, amount);
    }

    function getMinerDayLastClaimedFor(address miner)
        public
        view
        returns (uint256)
    {
        uint256 len = minerMineDays[miner].length;
        if (len != 0) {
            return
                minerDayLastClaimedFor[miner] == 0
                    ? minerMineDays[miner][0].sub(1)
                    : minerDayLastClaimedFor[miner];
        }
        return 0;
    }

    function getMinerMineData(address miner, uint256 dayNumber)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        return _getMinerMineData(miner, day);
    }

    function getMineData(uint256 dayNumber)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        return _getMineData(day);
    }

    // CLAIMING
    // *************************************************************************************
    function claimAll() public payable {
        uint256 len = minerMineDays[msg.sender].length;
        require(len != 0, "no mines");
        uint256 currentDay = _getCurrentDay();
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[msg.sender] == 0
            ? minerMineDays[msg.sender][0].sub(1)
            : minerDayLastClaimedFor[msg.sender];
        uint256 vestingDays = sbController.getValuePoolVestingDays(
            address(this)
        );
        require(
            currentDay > dayLastClaimedFor.add(vestingDays),
            "already claimed"
        );
        // fee is calculated in _claim
        _claim(currentDay, msg.sender, dayLastClaimedFor, vestingDays);
    }

    function claimUpTo(uint256 day) public payable {
        uint256 len = minerMineDays[msg.sender].length;
        require(len != 0, "no mines");
        require(day <= _getCurrentDay(), "invalid day");
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[msg.sender] == 0
            ? minerMineDays[msg.sender][0].sub(1)
            : minerDayLastClaimedFor[msg.sender];
        uint256 vestingDays = sbController.getValuePoolVestingDays(
            address(this)
        );
        require(day > dayLastClaimedFor.add(vestingDays), "already claimed");
        // fee is calculated in _claim
        _claim(day, msg.sender, dayLastClaimedFor, vestingDays);
    }

    function getRewardsDueAll(address miner) public view returns (uint256) {
        uint256 len = minerMineDays[miner].length;
        if (len == 0) {
            return 0;
        }
        uint256 currentDay = _getCurrentDay();
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[miner] == 0
            ? minerMineDays[miner][0].sub(1)
            : minerDayLastClaimedFor[miner];
        uint256 vestingDays = sbController.getValuePoolVestingDays(
            address(this)
        );
        if (!(currentDay > dayLastClaimedFor.add(vestingDays))) {
            return 0;
        }
        return
            _getRewardsDue(currentDay, miner, dayLastClaimedFor, vestingDays);
    }

    function getRewardsDueUpTo(uint256 day, address miner)
        public
        view
        returns (uint256)
    {
        uint256 len = minerMineDays[miner].length;
        if (len == 0) {
            return 0;
        }
        require(day <= _getCurrentDay(), "invalid day");
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[miner] == 0
            ? minerMineDays[miner][0].sub(1)
            : minerDayLastClaimedFor[miner];
        uint256 vestingDays = sbController.getValuePoolVestingDays(
            address(this)
        );
        if (!(day > dayLastClaimedFor.add(vestingDays))) {
            return 0;
        }
        return _getRewardsDue(day, miner, dayLastClaimedFor, vestingDays);
    }

    // SUPPORT
    // *************************************************************************************
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

    function _claim(
        uint256 upToDay,
        address miner,
        uint256 dayLastClaimedFor,
        uint256 vestingDays
    ) internal {
        uint256 rewards = _getRewardsDue(
            upToDay,
            miner,
            dayLastClaimedFor,
            vestingDays
        );
        require(rewards > 0, "no rewards");
        (uint256 numerator, uint256 denominator) = sbController
            .getValuePoolClaimingFee(address(this));
        uint256 fee = rewards.mul(numerator).div(denominator);
        require(msg.value == fee, "invalid fee");
        sbEthFeePool.deposit{value: msg.value}();
        minerDayLastClaimedFor[miner] = upToDay.sub(vestingDays);
        sbController.requestRewards(miner, rewards);
    }

    function _getRewardsDue(
        uint256 upToDay,
        address miner,
        uint256 dayLastClaimedFor,
        uint256 vestingDays
    ) internal view returns (uint256) {
        uint256 rewards;
        for (
            uint256 day = dayLastClaimedFor.add(1);
            day <= upToDay.sub(vestingDays);
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
            uint256 availableRewards = sbController.getValuePoolRewards(
                address(this),
                day
            );
            uint256 amount = availableRewards.mul(minerMineSecondsForDay).div(
                mineSecondsForDay
            );
            rewards = rewards.add(amount);
        }
        return rewards;
    }

    function _getCurrentDay() internal view returns (uint256) {
        return block.timestamp.div(1 days).add(1);
    }
}
