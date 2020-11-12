// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./sbTokensInterface.sol";
import "./sbControllerInterface.sol";
import "./sbStrongPoolInterface.sol";
import "./sbVotesInterface.sol";

contract sbCommunityV2 {
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event MinerRewardsPercentageUpdated(uint256 percentage);
    event RewardsReceived(uint256 indexed day, uint256 amount);
    event ETHMined(address indexed miner, uint256 amount, uint256 indexed day);
    event ETHUnmined(
        address indexed miner,
        uint256 amount,
        uint256 indexed day
    );
    event ERC20Mined(
        address indexed miner,
        address indexed token,
        uint256 amount,
        uint256 indexed day
    );
    event ERC20Unmined(
        address indexed miner,
        address indexed token,
        uint256 amount,
        uint256 indexed day
    );
    event Claimed(address indexed miner, uint256 amount, uint256 indexed day);
    event ServiceAdded(address indexed service, string tag);
    event TagAddedForService(address indexed service, string tag);

    using SafeMath for uint256;
    bool internal initDone;
    address internal constant ETH = address(0);
    string internal name;
    uint256 internal minerRewardPercentage;

    IERC20 internal strongToken;
    sbTokensInterface internal sbTokens;
    sbControllerInterface internal sbController;
    sbStrongPoolInterface internal sbStrongPool;
    sbVotesInterface internal sbVotes;
    address internal sbTimelock;
    address internal admin;
    address internal pendingAdmin;

    mapping(address => mapping(address => uint256[])) internal minerTokenDays;
    mapping(address => mapping(address => uint256[]))
        internal minerTokenAmounts;
    mapping(address => mapping(address => uint256[]))
        internal minerTokenMineSeconds;

    mapping(address => uint256[]) internal tokenDays;
    mapping(address => uint256[]) internal tokenAmounts;
    mapping(address => uint256[]) internal tokenMineSeconds;

    mapping(address => uint256) internal minerDayLastClaimedFor;
    mapping(uint256 => uint256) internal dayServiceRewards;

    address[] internal services;
    mapping(address => string[]) internal serviceTags;

    address internal superAdmin;
    address internal pendingSuperAdmin;
    uint256 internal delayDays;

    function setSuperAdmin() public {
        require(superAdmin == address(0), "superAdmin already set");
        superAdmin = address(0x4B5057B2c87Ec9e7C047fb00c0E406dfF2FDaCad);
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

    function superAdminUpdateMinerRewardPercentage(uint256 percentage)
        external
    {
        require(
            msg.sender == superAdmin && msg.sender != address(0),
            "not superAdmin"
        );
        require(percentage <= 100, "greater than 100");
        minerRewardPercentage = percentage;
        emit MinerRewardsPercentageUpdated(percentage);
    }

    function setDelayDays(uint256 dayCount) public {
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

    function updateMinerRewardPercentage(uint256 percentage) external {
        require(msg.sender == sbTimelock, "not sbTimelock");
        require(percentage <= 100, "greater than 100");
        minerRewardPercentage = percentage;
        emit MinerRewardsPercentageUpdated(percentage);
    }

    function getTokenData(address token, uint256 day)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(sbTokens.tokenAccepted(token), "invalid token");
        require(day <= _getCurrentDay(), "invalid day");
        return _getTokenData(token, day);
    }

    function serviceAccepted(address service) external view returns (bool) {
        return _serviceExists(service);
    }

    function receiveRewards(uint256 day, uint256 amount) external {
        require(amount > 0, "zero");
        require(msg.sender == address(sbController), "not sbController");
        strongToken.transferFrom(address(sbController), address(this), amount);
        uint256 oneHundred = 100;
        uint256 serviceReward = oneHundred
            .sub(minerRewardPercentage)
            .mul(amount)
            .div(oneHundred);
        (, , uint256 communityVoteSeconds) = sbVotes.getCommunityData(
            address(this),
            day
        );
        if (communityVoteSeconds != 0 && serviceReward != 0) {
            dayServiceRewards[day] = serviceReward;
            strongToken.approve(address(sbVotes), serviceReward);
            sbVotes.receiveServiceRewards(day, serviceReward);
        }
        emit RewardsReceived(day, amount.sub(serviceReward));
    }

    function getMinerRewardPercentage() external view returns (uint256) {
        return minerRewardPercentage;
    }

    function addService(address service, string memory tag) public {
        require(msg.sender == admin, "not admin");
        require(sbStrongPool.serviceMinMined(service), "not min mined");
        require(service != address(0), "service not zero address");
        require(!_serviceExists(service), "service exists");
        services.push(service);
        serviceTags[service].push(tag);
        emit ServiceAdded(service, tag);
    }

    function getServices() public view returns (address[] memory) {
        return services;
    }

    function getServiceTags(address service)
        public
        view
        returns (string[] memory)
    {
        require(_serviceExists(service), "invalid service");
        return serviceTags[service];
    }

    function addTag(address service, string memory tag) public {
        require(msg.sender == admin, "not admin");
        require(_serviceExists(service), "invalid service");
        require(!_serviceTagExists(service, tag), "tag exists");
        serviceTags[service].push(tag);
        emit TagAddedForService(service, tag);
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "not admin");
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "not pendingAdmin"
        );
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function getAdminAddressUsed() public view returns (address) {
        return admin;
    }

    function getPendingAdminAddressUsed() public view returns (address) {
        return pendingAdmin;
    }

    function getSbControllerAddressUsed() public view returns (address) {
        return address(sbController);
    }

    function getStrongAddressUsed() public view returns (address) {
        return address(strongToken);
    }

    function getSbTokensAddressUsed() public view returns (address) {
        return address(sbTokens);
    }

    function getSbStrongPoolAddressUsed() public view returns (address) {
        return address(sbStrongPool);
    }

    function getSbVotesAddressUsed() public view returns (address) {
        return address(sbVotes);
    }

    function getSbTimelockAddressUsed() public view returns (address) {
        return sbTimelock;
    }

    function getDayServiceRewards(uint256 day) public view returns (uint256) {
        return dayServiceRewards[day];
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getCurrentDay() public view returns (uint256) {
        return _getCurrentDay();
    }

    function mineETH() public payable {
        require(msg.value > 0, "zero");
        require(sbTokens.tokenAccepted(ETH), "invalid token");
        uint256 currentDay = _getCurrentDay();
        uint256 startDay = sbController.getStartDay();
        uint256 MAX_YEARS = sbController.getMaxYears();
        uint256 year = _getYearDayIsIn(currentDay, startDay);
        require(year <= MAX_YEARS, "invalid year");
        require(sbStrongPool.minerMinMined(msg.sender), "not min mined");
        _updateMinerTokenData(msg.sender, ETH, msg.value, true, currentDay);
        _updateTokenData(ETH, msg.value, true, currentDay);
        emit ETHMined(msg.sender, msg.value, currentDay);
    }

    function mineERC20(address token, uint256 amount) public {
        require(amount > 0, "zero");
        require(token != ETH, "no mine ETH");
        require(sbTokens.tokenAccepted(token), "invalid token");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 currentDay = _getCurrentDay();
        uint256 startDay = sbController.getStartDay();
        uint256 MAX_YEARS = sbController.getMaxYears();
        uint256 year = _getYearDayIsIn(currentDay, startDay);
        require(year <= MAX_YEARS, "invalid year");
        require(sbStrongPool.minerMinMined(msg.sender), "not min mined");
        _updateMinerTokenData(msg.sender, token, amount, true, currentDay);
        _updateTokenData(token, amount, true, currentDay);
        emit ERC20Mined(msg.sender, token, amount, currentDay);
    }

    function unmine(address token, uint256 amount) public {
        require(amount > 0, "zero");
        require(sbTokens.tokenAccepted(token), "invalid token");

        uint256 currentDay = _getCurrentDay();
        _updateMinerTokenData(msg.sender, token, amount, false, currentDay);
        _updateTokenData(token, amount, false, currentDay);

        if (token == ETH) {
            msg.sender.transfer(amount);
            emit ETHUnmined(msg.sender, amount, currentDay);
        } else {
            IERC20(token).transfer(msg.sender, amount);
            emit ERC20Unmined(msg.sender, token, amount, currentDay);
        }
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
        require(sbTokens.upToDate(), "need token prices");
        require(sbController.upToDate(), "need rewards released");
        _claim(currentDay, msg.sender, dayLastClaimedFor);
    }

    function claimUpTo(uint256 day) public {
        require(delayDays > 0, "zero");
        require(day <= _getCurrentDay(), "invalid day");
        uint256 dayLastClaimedFor = minerDayLastClaimedFor[msg.sender] == 0
            ? sbController.getStartDay().sub(1)
            : minerDayLastClaimedFor[msg.sender];
        require(day > dayLastClaimedFor.add(delayDays), "already claimed");
        require(sbTokens.upToDate(), "need token prices");
        require(sbController.upToDate(), "need rewards released");
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
        require(sbTokens.upToDate(), "need token prices");
        require(sbController.upToDate(), "need rewards released");
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
        require(sbTokens.upToDate(), "need token prices");
        require(sbController.upToDate(), "need rewards released");
        return _getRewardsDue(day, miner, dayLastClaimedFor);
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

    function getMinerTokenData(
        address miner,
        address token,
        uint256 day
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(sbTokens.tokenAccepted(token), "invalid token");
        require(day <= _getCurrentDay(), "invalid day");
        return _getMinerTokenData(miner, token, day);
    }

    function _getMinerTokenData(
        address miner,
        address token,
        uint256 day
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256[] memory _Days = minerTokenDays[miner][token];
        uint256[] memory _Amounts = minerTokenAmounts[miner][token];
        uint256[] memory _UnitSeconds = minerTokenMineSeconds[miner][token];
        return _get(_Days, _Amounts, _UnitSeconds, day);
    }

    function _getTokenData(address token, uint256 day)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256[] memory _Days = tokenDays[token];
        uint256[] memory _Amounts = tokenAmounts[token];
        uint256[] memory _UnitSeconds = tokenMineSeconds[token];
        return _get(_Days, _Amounts, _UnitSeconds, day);
    }

    function _updateMinerTokenData(
        address miner,
        address token,
        uint256 amount,
        bool adding,
        uint256 currentDay
    ) internal {
        uint256[] storage _Days = minerTokenDays[miner][token];
        uint256[] storage _Amounts = minerTokenAmounts[miner][token];
        uint256[] storage _UnitSeconds = minerTokenMineSeconds[miner][token];
        _update(_Days, _Amounts, _UnitSeconds, amount, adding, currentDay);
    }

    function _updateTokenData(
        address token,
        uint256 amount,
        bool adding,
        uint256 currentDay
    ) internal {
        uint256[] storage _Days = tokenDays[token];
        uint256[] storage _Amounts = tokenAmounts[token];
        uint256[] storage _UnitSeconds = tokenMineSeconds[token];
        _update(_Days, _Amounts, _UnitSeconds, amount, adding, currentDay);
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
        uint256 dayLastClaimedFor
    ) internal {
        uint256 rewards = _getRewardsDue(upToDay, miner, dayLastClaimedFor);
        require(rewards > 0, "no rewards");
        minerDayLastClaimedFor[miner] = upToDay.sub(delayDays);
        strongToken.approve(address(sbStrongPool), rewards);
        sbStrongPool.mineFor(miner, rewards);
        emit Claimed(miner, rewards, _getCurrentDay());
    }

    function _getRewardsDue(
        uint256 upToDay,
        address miner,
        uint256 dayLastClaimedFor
    ) internal view returns (uint256) {
        address[] memory tokens = sbTokens.getTokens();
        uint256 rewards;
        for (
            uint256 day = dayLastClaimedFor.add(1);
            day <= upToDay.sub(delayDays);
            day++
        ) {
            uint256 communityDayMineSecondsUSD = sbController
                .getCommunityDayMineSecondsUSD(address(this), day);
            if (communityDayMineSecondsUSD == 0) {
                continue;
            }
            uint256 minerDayMineSecondsUSD = 0;
            uint256[] memory tokenPrices = sbTokens.getTokenPrices(day);
            for (uint256 i = 0; i < tokens.length; i++) {
                address token = tokens[i];
                (, , uint256 minerMineSeconds) = _getMinerTokenData(
                    miner,
                    token,
                    day
                );
                uint256 amount = minerMineSeconds.mul(tokenPrices[i]).div(1e18);
                minerDayMineSecondsUSD = minerDayMineSecondsUSD.add(amount);
            }
            uint256 communityDayRewards = sbController
                .getCommunityDayRewards(address(this), day)
                .sub(dayServiceRewards[day]);
            uint256 amount = communityDayRewards
                .mul(minerDayMineSecondsUSD)
                .div(communityDayMineSecondsUSD);
            rewards = rewards.add(amount);
        }
        return rewards;
    }

    function _serviceExists(address service) internal view returns (bool) {
        return serviceTags[service].length > 0;
    }

    function _serviceTagExists(address service, string memory tag)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < serviceTags[service].length; i++) {
            if (
                keccak256(abi.encode(tag)) ==
                keccak256(abi.encode(serviceTags[service][i]))
            ) {
                return true;
            }
        }
        return false;
    }

    function _getYearDayIsIn(uint256 day, uint256 startDay)
        internal
        pure
        returns (uint256)
    {
        return day.sub(startDay).div(366).add(1); // dividing by 366 makes day 1 and 365 be in year 1
    }

    function _getCurrentDay() internal view returns (uint256) {
        return block.timestamp.div(1 days).add(1);
    }
}
