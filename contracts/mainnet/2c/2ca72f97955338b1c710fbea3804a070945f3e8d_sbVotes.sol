// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./sbControllerInterface.sol";
import "./sbGenericServicePoolInterface.sol";
import "./sbStrongValuePoolInterface.sol";

contract sbVotes {
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );
    event Voted(
        address indexed voter,
        address community,
        address indexed service,
        uint256 amount,
        uint256 indexed day
    );
    event VoteRecalled(
        address indexed voter,
        address community,
        address indexed service,
        uint256 amount,
        uint256 indexed day
    );
    event ServiceDropped(
        address indexed voter,
        address community,
        address indexed service,
        uint256 indexed day
    );
    event Claimed(address indexed service, uint256 amount, uint256 indexed day);
    event AddVotes(address indexed staker, uint256 amount);
    event SubVotes(address indexed staker, uint256 amount);

    using SafeMath for uint256;

    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;

    sbControllerInterface public sbController;
    sbGenericServicePoolInterface public sbGenericServicePool;
    sbStrongValuePoolInterface public sbStrongValuePool;

    mapping(address => uint96) public balances;
    mapping(address => address) public delegates;

    mapping(address => mapping(uint32 => uint32)) public checkpointsFromBlock;
    mapping(address => mapping(uint32 => uint96)) public checkpointsVotes;
    mapping(address => uint32) public numCheckpoints;

    mapping(address => address[]) internal voterServicePools;
    mapping(address => mapping(address => address[]))
        internal voterServicePoolServices;
    mapping(address => mapping(address => mapping(address => uint256[])))
        internal voterServicePoolServiceDays;
    mapping(address => mapping(address => mapping(address => uint256[])))
        internal voterServicePoolServiceAmounts;
    mapping(address => mapping(address => mapping(address => uint256[])))
        internal voterServicePoolServiceVoteSeconds;
    mapping(address => uint256) internal voterDayLastClaimedFor;
    mapping(address => uint256) internal voterVotesOut;

    mapping(address => mapping(address => uint256[]))
        internal serviceServicePoolDays;
    mapping(address => mapping(address => uint256[]))
        internal serviceServicePoolAmounts;
    mapping(address => mapping(address => uint256[]))
        internal serviceServicePoolVoteSeconds;
    mapping(address => mapping(address => uint256))
        internal serviceServicePoolDayLastClaimedFor;

    mapping(address => uint256[]) internal servicePoolDays;
    mapping(address => uint256[]) internal servicePoolAmounts;
    mapping(address => uint256[]) internal servicePoolVoteSeconds;

    function init(
        address sbControllerAddress,
        address sbStrongValuePoolAddress,
        address adminAddress,
        address superAdminAddress
    ) public {
        require(!initDone, "init done");
        sbController = sbControllerInterface(sbControllerAddress);
        sbStrongValuePool = sbStrongValuePoolInterface(
            sbStrongValuePoolAddress
        );
        admin = adminAddress;
        superAdmin = superAdminAddress;
        initDone = true;
    }

    function updateVotes(
        address voter,
        uint256 rawAmount,
        bool adding
    ) external {
        require(
            msg.sender == address(sbStrongValuePool),
            "not sbStrongValuePool"
        );
        uint96 amount = _safe96(rawAmount, "amount exceeds 96 bits");
        if (adding) {
            _addVotes(voter, amount);
        } else {
            require(voter == delegates[voter], "must delegate to self");
            require(
                _getAvailableServiceVotes(voter) >= amount,
                "must recall votes"
            );
            _subVotes(voter, amount);
        }
    }

    function getCurrentProposalVotes(address account)
        external
        view
        returns (uint96)
    {
        return _getCurrentProposalVotes(account);
    }

    function getPriorProposalVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96)
    {
        require(blockNumber < block.number, "not yet determined");
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        if (checkpointsFromBlock[account][nCheckpoints - 1] <= blockNumber) {
            return checkpointsVotes[account][nCheckpoints - 1];
        }
        if (checkpointsFromBlock[account][0] > blockNumber) {
            return 0;
        }
        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            uint32 fromBlock = checkpointsFromBlock[account][center];
            uint96 votes = checkpointsVotes[account][center];
            if (fromBlock == blockNumber) {
                return votes;
            } else if (fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpointsVotes[account][lower];
    }

    function getServiceDayLastClaimedFor(address servicePool, address service)
        public
        view
        returns (uint256)
    {
        uint256 len = serviceServicePoolDays[service][servicePool].length;
        if (len != 0) {
            return
                serviceServicePoolDayLastClaimedFor[service][servicePool] == 0
                    ? serviceServicePoolDays[service][servicePool][0].sub(1)
                    : serviceServicePoolDayLastClaimedFor[service][servicePool];
        }
        return 0;
    }

    function getVoterDayLastClaimedFor(address voter)
        public
        view
        returns (uint256)
    {
        if (voterDayLastClaimedFor[voter] == 0) {
            uint256 firstDayVoted = _getVoterFirstDay(voter);
            if (firstDayVoted == 0) {
                return 0;
            }
            return firstDayVoted.sub(1);
        }
        return voterDayLastClaimedFor[voter];
    }

    function recallAllVotes() public {
        require(voterVotesOut[msg.sender] > 0, "no votes out");
        _recallAllVotes(msg.sender);
    }

    function delegate(address delegatee) public {
        _delegate(msg.sender, delegatee);
    }

    function getDelegate(address delegator) public view returns (address) {
        return delegates[delegator];
    }

    function getAvailableServiceVotes(address account)
        public
        view
        returns (uint96)
    {
        return _getAvailableServiceVotes(account);
    }

    function getVoterServicePoolServices(address voter, address servicePool)
        public
        view
        returns (address[] memory)
    {
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        return voterServicePoolServices[voter][servicePool];
    }

    function vote(
        address servicePool,
        address service,
        uint256 amount
    ) public {
        require(amount > 0, "1: zero");
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        require(
            sbGenericServicePoolInterface(servicePool).isServiceAccepted(
                service
            ),
            "invalid service"
        );
        require(sbStrongValuePool.serviceMinMined(service), "not min mined");
        require(
            uint256(_getAvailableServiceVotes(msg.sender)) >= amount,
            "not enough votes"
        );
        if (!_voterServicePoolServiceExists(msg.sender, servicePool, service)) {
            require(
                voterServicePoolServices[msg.sender][servicePool].length.add(
                    1
                ) <= sbController.getVoteForServicesCount(),
                "1: too many"
            );
            voterServicePoolServices[msg.sender][servicePool].push(service);
        }
        if (!_voterServicePoolExists(msg.sender, servicePool)) {
            require(
                voterServicePools[msg.sender].length.add(1) <=
                    sbController.getVoteForServicePoolsCount(),
                "2: too many"
            );
            voterServicePools[msg.sender].push(servicePool);
        }
        uint256 currentDay = _getCurrentDay();
        _updateVoterServicePoolServiceData(
            msg.sender,
            servicePool,
            service,
            amount,
            true,
            currentDay
        );
        _updateServiceServicePoolData(
            service,
            servicePool,
            amount,
            true,
            currentDay
        );
        _updateServicePoolData(servicePool, amount, true, currentDay);
        voterVotesOut[msg.sender] = voterVotesOut[msg.sender].add(amount);
        emit Voted(msg.sender, servicePool, service, amount, currentDay);
    }

    function recallVote(
        address servicePool,
        address service,
        uint256 amount
    ) public {
        require(amount > 0, "zero");
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        require(
            sbGenericServicePoolInterface(servicePool).isServiceAccepted(
                service
            ),
            "invalid service"
        );
        require(
            _voterServicePoolServiceExists(msg.sender, servicePool, service),
            "not found"
        );
        uint256 currentDay = _getCurrentDay();
        (, uint256 votes, ) = _getVoterServicePoolServiceData(
            msg.sender,
            servicePool,
            service,
            currentDay
        );
        require(votes >= amount, "not enough votes");
        _updateVoterServicePoolServiceData(
            msg.sender,
            servicePool,
            service,
            amount,
            false,
            currentDay
        );
        _updateServiceServicePoolData(
            service,
            servicePool,
            amount,
            false,
            currentDay
        );
        _updateServicePoolData(servicePool, amount, false, currentDay);
        voterVotesOut[msg.sender] = voterVotesOut[msg.sender].sub(amount);
        emit VoteRecalled(msg.sender, servicePool, service, amount, currentDay);
    }

    function dropService(address servicePool, address service) public {
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        require(
            sbGenericServicePoolInterface(servicePool).isServiceAccepted(
                service
            ),
            "invalid service"
        );
        require(
            _voterServicePoolExists(msg.sender, servicePool),
            "2: not found"
        );
        require(
            _voterServicePoolServiceExists(msg.sender, servicePool, service),
            "1: not found"
        );
        uint256 currentDay = _getCurrentDay();
        (, uint256 votes, ) = _getVoterServicePoolServiceData(
            msg.sender,
            servicePool,
            service,
            currentDay
        );
        _updateVoterServicePoolServiceData(
            msg.sender,
            servicePool,
            service,
            votes,
            false,
            currentDay
        );
        _updateServiceServicePoolData(
            service,
            servicePool,
            votes,
            false,
            currentDay
        );
        _updateServicePoolData(servicePool, votes, false, currentDay);
        voterVotesOut[msg.sender] = voterVotesOut[msg.sender].sub(votes);
        uint256 voterServicePoolServicesIndex = _findIndexOfAddress(
            voterServicePoolServices[msg.sender][servicePool],
            service
        );
        _deleteArrayElement(
            voterServicePoolServicesIndex,
            voterServicePoolServices[msg.sender][servicePool]
        );
        if (voterServicePoolServices[msg.sender][servicePool].length == 0) {
            uint256 voterServicePoolsIndex = _findIndexOfAddress(
                voterServicePools[msg.sender],
                servicePool
            );
            _deleteArrayElement(
                voterServicePoolsIndex,
                voterServicePools[msg.sender]
            );
        }
        emit ServiceDropped(msg.sender, servicePool, service, currentDay);
    }

    function serviceClaimAll(address servicePool) public {
        uint256 len = serviceServicePoolDays[msg.sender][servicePool].length;
        require(len != 0, "no votes");
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        uint256 currentDay = _getCurrentDay();
        uint256 dayLastClaimedFor = serviceServicePoolDayLastClaimedFor[msg
            .sender][servicePool] == 0
            ? serviceServicePoolDays[msg.sender][servicePool][0].sub(1)
            : serviceServicePoolDayLastClaimedFor[msg.sender][servicePool];
        uint256 vestingDays = sbController.getVoteReceiverVestingDays();
        require(
            currentDay > dayLastClaimedFor.add(vestingDays),
            "already claimed"
        );
        _serviceClaim(
            currentDay,
            servicePool,
            msg.sender,
            dayLastClaimedFor,
            vestingDays
        );
    }

    function serviceClaimUpTo(address servicePool, uint256 day) public {
        uint256 len = serviceServicePoolDays[msg.sender][servicePool].length;
        require(len != 0, "no votes");
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        require(day <= _getCurrentDay(), "invalid day");
        uint256 dayLastClaimedFor = serviceServicePoolDayLastClaimedFor[msg
            .sender][servicePool] == 0
            ? serviceServicePoolDays[msg.sender][servicePool][0].sub(1)
            : serviceServicePoolDayLastClaimedFor[msg.sender][servicePool];
        uint256 vestingDays = sbController.getVoteReceiverVestingDays();
        require(day > dayLastClaimedFor.add(vestingDays), "already claimed");
        _serviceClaim(
            day,
            servicePool,
            msg.sender,
            dayLastClaimedFor,
            vestingDays
        );
    }

    function voterClaimAll() public {
        uint256 dayLastClaimedFor;
        if (voterDayLastClaimedFor[msg.sender] == 0) {
            uint256 firstDayVoted = _getVoterFirstDay(msg.sender);
            require(firstDayVoted != 0, "no votes");
            dayLastClaimedFor = firstDayVoted.sub(1);
        } else {
            dayLastClaimedFor = voterDayLastClaimedFor[msg.sender];
        }
        uint256 currentDay = _getCurrentDay();
        uint256 vestingDays = sbController.getVoteCasterVestingDays();
        require(
            currentDay > dayLastClaimedFor.add(vestingDays),
            "already claimed"
        );
        _voterClaim(currentDay, msg.sender, dayLastClaimedFor, vestingDays);
    }

    function voterClaimUpTo(uint256 day) public {
        uint256 dayLastClaimedFor;
        if (voterDayLastClaimedFor[msg.sender] == 0) {
            uint256 firstDayVoted = _getVoterFirstDay(msg.sender);
            require(firstDayVoted != 0, "no votes");
            dayLastClaimedFor = firstDayVoted.sub(1);
        } else {
            dayLastClaimedFor = voterDayLastClaimedFor[msg.sender];
        }
        require(day <= _getCurrentDay(), "invalid day");
        uint256 vestingDays = sbController.getVoteCasterVestingDays();
        require(day > dayLastClaimedFor.add(vestingDays), "already claimed");
        _voterClaim(day, msg.sender, dayLastClaimedFor, vestingDays);
    }

    function getServiceRewardsDueAll(address servicePool, address service)
        public
        view
        returns (uint256)
    {
        uint256 len = serviceServicePoolDays[service][servicePool].length;
        if (len == 0) {
            return 0;
        }
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        uint256 currentDay = _getCurrentDay();


            uint256 dayLastClaimedFor
         = serviceServicePoolDayLastClaimedFor[service][servicePool] == 0
            ? serviceServicePoolDays[service][servicePool][0].sub(1)
            : serviceServicePoolDayLastClaimedFor[service][servicePool];
        uint256 vestingDays = sbController.getVoteReceiverVestingDays();
        if (!(currentDay > dayLastClaimedFor.add(vestingDays))) {
            return 0;
        }
        return
            _getServiceRewardsDue(
                currentDay,
                servicePool,
                service,
                dayLastClaimedFor,
                vestingDays
            );
    }

    function getServiceRewardsDueUpTo(
        address servicePool,
        address service,
        uint256 day
    ) public view returns (uint256) {
        uint256 len = serviceServicePoolDays[service][servicePool].length;
        if (len == 0) {
            return 0;
        }
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        require(day <= _getCurrentDay(), "invalid day");


            uint256 dayLastClaimedFor
         = serviceServicePoolDayLastClaimedFor[service][servicePool] == 0
            ? serviceServicePoolDays[service][servicePool][0].sub(1)
            : serviceServicePoolDayLastClaimedFor[service][servicePool];
        uint256 vestingDays = sbController.getVoteReceiverVestingDays();
        if (!(day > dayLastClaimedFor.add(vestingDays))) {
            return 0;
        }
        return
            _getServiceRewardsDue(
                day,
                servicePool,
                service,
                dayLastClaimedFor,
                vestingDays
            );
    }

    function getVoterRewardsDueAll(address voter)
        public
        view
        returns (uint256)
    {
        uint256 dayLastClaimedFor;
        if (voterDayLastClaimedFor[voter] == 0) {
            uint256 firstDayVoted = _getVoterFirstDay(voter);
            if (firstDayVoted == 0) {
                return 0;
            }
            dayLastClaimedFor = firstDayVoted.sub(1);
        } else {
            dayLastClaimedFor = voterDayLastClaimedFor[voter];
        }
        uint256 currentDay = _getCurrentDay();
        uint256 vestingDays = sbController.getVoteCasterVestingDays();
        if (!(currentDay > dayLastClaimedFor.add(vestingDays))) {
            return 0;
        }
        return
            _getVoterRewardsDue(
                currentDay,
                voter,
                dayLastClaimedFor,
                vestingDays
            );
    }

    function getVoterRewardsDueUpTo(uint256 day, address voter)
        public
        view
        returns (uint256)
    {
        uint256 dayLastClaimedFor;
        if (voterDayLastClaimedFor[voter] == 0) {
            uint256 firstDayVoted = _getVoterFirstDay(voter);
            if (firstDayVoted == 0) {
                return 0;
            }
            dayLastClaimedFor = firstDayVoted.sub(1);
        } else {
            dayLastClaimedFor = voterDayLastClaimedFor[voter];
        }
        require(day <= _getCurrentDay(), "invalid day");
        uint256 vestingDays = sbController.getVoteCasterVestingDays();
        if (!(day > dayLastClaimedFor.add(vestingDays))) {
            return 0;
        }
        return _getVoterRewardsDue(day, voter, dayLastClaimedFor, vestingDays);
    }

    function getVoterServicePoolServiceData(
        address voter,
        address servicePool,
        address service,
        uint256 dayNumber
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        require(
            sbGenericServicePoolInterface(servicePool).isServiceAccepted(
                service
            ),
            "invalid service"
        );
        if (!_voterServicePoolServiceExists(voter, servicePool, service)) {
            return (day, 0, 0);
        }
        require(day <= _getCurrentDay(), "invalid day");
        return
            _getVoterServicePoolServiceData(voter, servicePool, service, day);
    }

    function getServiceServicePoolData(
        address service,
        address servicePool,
        uint256 dayNumber
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        require(
            sbGenericServicePoolInterface(servicePool).isServiceAccepted(
                service
            ),
            "invalid service"
        );
        require(day <= _getCurrentDay(), "invalid day");
        return _getServiceServicePoolData(service, servicePool, day);
    }

    function getServicePoolData(address servicePool, uint256 dayNumber)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 day = dayNumber == 0 ? _getCurrentDay() : dayNumber;
        require(
            sbController.isServicePoolAccepted(servicePool),
            "invalid servicePool"
        );
        require(day <= _getCurrentDay(), "invalid day");
        return _getServicePoolData(servicePool, day);
    }

    function _getVoterServicePoolServiceData(
        address voter,
        address servicePool,
        address service,
        uint256 day
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {

            uint256[] memory _Days
         = voterServicePoolServiceDays[voter][servicePool][service];


            uint256[] memory _Amounts
         = voterServicePoolServiceAmounts[voter][servicePool][service];


            uint256[] memory _UnitSeconds
         = voterServicePoolServiceVoteSeconds[voter][servicePool][service];
        return _get(_Days, _Amounts, _UnitSeconds, day);
    }

    function _getServiceServicePoolData(
        address service,
        address servicePool,
        uint256 day
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256[] memory _Days = serviceServicePoolDays[service][servicePool];


            uint256[] memory _Amounts
         = serviceServicePoolAmounts[service][servicePool];


            uint256[] memory _UnitSeconds
         = serviceServicePoolVoteSeconds[service][servicePool];
        return _get(_Days, _Amounts, _UnitSeconds, day);
    }

    function _getServicePoolData(address servicePool, uint256 day)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256[] memory _Days = servicePoolDays[servicePool];
        uint256[] memory _Amounts = servicePoolAmounts[servicePool];
        uint256[] memory _UnitSeconds = servicePoolVoteSeconds[servicePool];
        return _get(_Days, _Amounts, _UnitSeconds, day);
    }

    function _updateVoterServicePoolServiceData(
        address voter,
        address servicePool,
        address service,
        uint256 amount,
        bool adding,
        uint256 currentDay
    ) internal {

            uint256[] storage _Days
         = voterServicePoolServiceDays[voter][servicePool][service];


            uint256[] storage _Amounts
         = voterServicePoolServiceAmounts[voter][servicePool][service];


            uint256[] storage _UnitSeconds
         = voterServicePoolServiceVoteSeconds[voter][servicePool][service];
        _update(_Days, _Amounts, _UnitSeconds, amount, adding, currentDay);
    }

    function _updateServiceServicePoolData(
        address service,
        address servicePool,
        uint256 amount,
        bool adding,
        uint256 currentDay
    ) internal {
        uint256[] storage _Days = serviceServicePoolDays[service][servicePool];


            uint256[] storage _Amounts
         = serviceServicePoolAmounts[service][servicePool];


            uint256[] storage _UnitSeconds
         = serviceServicePoolVoteSeconds[service][servicePool];
        _update(_Days, _Amounts, _UnitSeconds, amount, adding, currentDay);
    }

    function _updateServicePoolData(
        address servicePool,
        uint256 amount,
        bool adding,
        uint256 currentDay
    ) internal {
        uint256[] storage _Days = servicePoolDays[servicePool];
        uint256[] storage _Amounts = servicePoolAmounts[servicePool];
        uint256[] storage _UnitSeconds = servicePoolVoteSeconds[servicePool];
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

    function _addVotes(address voter, uint96 amount) internal {
        require(voter != address(0), "zero address");
        balances[voter] = _add96(
            balances[voter],
            amount,
            "vote amount overflows"
        );
        _addDelegates(voter, amount);
        emit AddVotes(voter, amount);
    }

    function _subVotes(address voter, uint96 amount) internal {
        balances[voter] = _sub96(
            balances[voter],
            amount,
            "vote amount exceeds balance"
        );
        _subtactDelegates(voter, amount);
        emit SubVotes(voter, amount);
    }

    function _addDelegates(address staker, uint96 amount) internal {
        if (delegates[staker] == address(0)) {
            delegates[staker] = staker;
        }
        address currentDelegate = delegates[staker];
        _moveDelegates(address(0), currentDelegate, amount);
    }

    function _subtactDelegates(address staker, uint96 amount) internal {
        address currentDelegate = delegates[staker];
        _moveDelegates(currentDelegate, address(0), amount);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0
                    ? checkpointsVotes[srcRep][srcRepNum - 1]
                    : 0;
                uint96 srcRepNew = _sub96(
                    srcRepOld,
                    amount,
                    "vote amount underflows"
                );
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0
                    ? checkpointsVotes[dstRep][dstRepNum - 1]
                    : 0;
                uint96 dstRepNew = _add96(
                    dstRepOld,
                    amount,
                    "vote amount overflows"
                );
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = _safe32(
            block.number,
            "block number exceeds 32 bits"
        );
        if (
            nCheckpoints > 0 &&
            checkpointsFromBlock[delegatee][nCheckpoints - 1] == blockNumber
        ) {
            checkpointsVotes[delegatee][nCheckpoints - 1] = newVotes;
        } else {
            checkpointsFromBlock[delegatee][nCheckpoints] = blockNumber;
            checkpointsVotes[delegatee][nCheckpoints] = newVotes;
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function _safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function _safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function _add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function _sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function _getCurrentProposalVotes(address account)
        internal
        view
        returns (uint96)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpointsVotes[account][nCheckpoints - 1] : 0;
    }

    function _getAvailableServiceVotes(address account)
        internal
        view
        returns (uint96)
    {
        uint96 proposalVotes = _getCurrentProposalVotes(account);
        return
            proposalVotes == 0
                ? 0
                : proposalVotes -
                    _safe96(
                        voterVotesOut[account],
                        "voterVotesOut exceeds 96 bits"
                    );
    }

    function _voterServicePoolExists(address voter, address servicePool)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < voterServicePools[voter].length; i++) {
            if (voterServicePools[voter][i] == servicePool) {
                return true;
            }
        }
        return false;
    }

    function _voterServicePoolServiceExists(
        address voter,
        address servicePool,
        address service
    ) internal view returns (bool) {
        for (
            uint256 i = 0;
            i < voterServicePoolServices[voter][servicePool].length;
            i++
        ) {
            if (voterServicePoolServices[voter][servicePool][i] == service) {
                return true;
            }
        }
        return false;
    }

    function _recallAllVotes(address voter) internal {
        uint256 currentDay = _getCurrentDay();
        for (uint256 i = 0; i < voterServicePools[voter].length; i++) {
            address servicePool = voterServicePools[voter][i];


                address[] memory services
             = voterServicePoolServices[voter][servicePool];
            for (uint256 j = 0; j < services.length; j++) {
                address service = services[j];
                (, uint256 amount, ) = _getVoterServicePoolServiceData(
                    voter,
                    servicePool,
                    service,
                    currentDay
                );
                _updateVoterServicePoolServiceData(
                    voter,
                    servicePool,
                    service,
                    amount,
                    false,
                    currentDay
                );
                _updateServiceServicePoolData(
                    service,
                    servicePool,
                    amount,
                    false,
                    currentDay
                );
                _updateServicePoolData(servicePool, amount, false, currentDay);
                voterVotesOut[voter] = voterVotesOut[voter].sub(amount);
            }
        }
    }

    function _serviceClaim(
        uint256 upToDay,
        address servicePool,
        address service,
        uint256 dayLastClaimedFor,
        uint256 vestingDays
    ) internal {
        uint256 rewards = _getServiceRewardsDue(
            upToDay,
            servicePool,
            service,
            dayLastClaimedFor,
            vestingDays
        );
        require(rewards > 0, "no rewards");
        serviceServicePoolDayLastClaimedFor[service][servicePool] = upToDay.sub(
            vestingDays
        );
        sbController.requestRewards(service, rewards);
        emit Claimed(service, rewards, _getCurrentDay());
    }

    function _getServiceRewardsDue(
        uint256 upToDay,
        address servicePool,
        address service,
        uint256 dayLastClaimedFor,
        uint256 vestingDays
    ) internal view returns (uint256) {
        uint256 rewards;
        for (
            uint256 day = dayLastClaimedFor.add(1);
            day <= upToDay.sub(vestingDays);
            day++
        ) {
            (, , uint256 servicePoolVoteSecondsForDay) = _getServicePoolData(
                servicePool,
                day
            );
            if (servicePoolVoteSecondsForDay == 0) {
                continue;
            }
            (, , uint256 serviceVoteSecondsForDay) = _getServiceServicePoolData(
                service,
                servicePool,
                day
            );
            uint256 availableRewards = sbController.getVoteReceiversRewards(
                day
            );
            uint256 amount = availableRewards.mul(serviceVoteSecondsForDay).div(
                servicePoolVoteSecondsForDay
            );
            rewards = rewards.add(amount);
        }
        return rewards;
    }

    function _voterClaim(
        uint256 upToDay,
        address voter,
        uint256 dayLastClaimedFor,
        uint256 vestingDays
    ) internal {
        uint256 rewards = _getVoterRewardsDue(
            upToDay,
            voter,
            dayLastClaimedFor,
            vestingDays
        );
        require(rewards > 0, "no rewards");
        voterDayLastClaimedFor[voter] = upToDay.sub(vestingDays);
        sbController.requestRewards(voter, rewards);
        emit Claimed(voter, rewards, _getCurrentDay());
    }

    function _getVoterRewardsDue(
        uint256 upToDay,
        address voter,
        uint256 dayLastClaimedFor,
        uint256 vestingDays
    ) internal view returns (uint256) {
        uint256 rewards;
        address[] memory servicePools = voterServicePools[voter];
        for (
            uint256 day = dayLastClaimedFor.add(1);
            day <= upToDay.sub(vestingDays);
            day++
        ) {
            for (uint256 i = 0; i < servicePools.length; i++) {
                address servicePool = servicePools[i];
                (
                    ,
                    ,
                    uint256 servicePoolVoteSecondsForDay
                ) = _getServicePoolData(servicePool, day);
                if (servicePoolVoteSecondsForDay == 0) {
                    continue;
                }


                    address[] memory services
                 = voterServicePoolServices[voter][servicePool];
                uint256 voterServicePoolVoteSecondsForDay;
                for (uint256 j = 0; j < services.length; j++) {
                    address service = services[j];
                    (
                        ,
                        ,
                        uint256 voterVoteSeconds
                    ) = _getVoterServicePoolServiceData(
                        voter,
                        servicePool,
                        service,
                        day
                    );
                    voterServicePoolVoteSecondsForDay = voterServicePoolVoteSecondsForDay
                        .add(voterVoteSeconds);
                }
                uint256 availableRewards = sbController.getVoteCastersRewards(
                    day
                );
                uint256 amount = availableRewards
                    .mul(voterServicePoolVoteSecondsForDay)
                    .div(servicePoolVoteSecondsForDay);
                rewards = rewards.add(amount);
            }
        }
        return rewards;
    }

    function _getCurrentDay() internal view returns (uint256) {
        return block.timestamp.div(1 days).add(1);
    }

    function _deleteArrayElement(uint256 index, address[] storage array)
        internal
    {
        if (index == array.length.sub(1)) {
            array.pop();
        } else {
            array[index] = array[array.length.sub(1)];
            array.pop();
        }
    }

    function _findIndexOfAddress(address[] memory array, address element)
        internal
        pure
        returns (uint256)
    {
        uint256 index;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                index = i;
            }
        }
        return index;
    }

    function _getVoterFirstDay(address voter) internal view returns (uint256) {
        uint256 firstDay = 0;
        for (uint256 i = 0; i < voterServicePools[voter].length; i++) {
            address servicePool = voterServicePools[voter][i];
            for (
                uint256 j = 0;
                j < voterServicePoolServices[voter][servicePool].length;
                j++
            ) {

                    address service
                 = voterServicePoolServices[voter][servicePool][j];
                if (
                    voterServicePoolServiceDays[voter][servicePool][service]
                        .length != 0
                ) {
                    if (firstDay == 0) {
                        firstDay = voterServicePoolServiceDays[voter][servicePool][service][0];
                    } else if (
                        voterServicePoolServiceDays[voter][servicePool][service][0] <
                        firstDay
                    ) {
                        firstDay = voterServicePoolServiceDays[voter][servicePool][service][0];
                    }
                }
            }
        }
        return firstDay;
    }
}
