// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant MAX_INT = 2**256 - 1;

uint256 constant DECIMALS = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant ONE_MONTH = 30 days;

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";

import "./interfaces/IPolicyBook.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/ILiquidityMining.sol";
import "./interfaces/IPolicyBookRegistry.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract LiquidityMining is
    ILiquidityMining,
    OwnableUpgradeable,
    ERC1155Receiver,
    AbstractDependant
{
    using Math for uint256;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address[] public leaderboard;
    address[] public topUsers;
    address[] public allUsers;
    EnumerableSet.AddressSet private teamsArr;

    uint256 public override startLiquidityMiningTime;

    uint256 public constant MAX_GROUP_LEADERS_SIZE = 10;
    uint256 public constant MAX_LEADERBOARD_SIZE = 10;
    uint256 public constant MAX_TOP_USERS_SIZE = 5;
    uint256 public constant MAX_MONTH_TO_GET_REWARD = 5;
    uint256 public constant LM_DURATION = 2 weeks;

    uint256 public constant MAX_SLASHING_FEE = 50 * PRECISION;

    IERC20 public bmiToken;
    IERC1155 public liquidityMiningNFT;
    IPolicyBookRegistry public policyBookRegistry;

    // Referral link => team info
    mapping(address => TeamInfo) public teamInfos;

    // User addr => Info
    mapping(address => UserTeamInfo) public usersTeamInfo;

    mapping(string => bool) public existingNames;

    // Referral link => members
    mapping(address => EnumerableSet.AddressSet) private teamsMembers;

    event TeamCreated(address _referralLink, string _name);
    event TeamDeleted(address _referralLink, string _name);
    event MemberAdded(address _referralLink, address _newMember, uint256 _membersNumber);
    event TeamInvested(address _referralLink, address _daiInvestor, uint256 _tokensAmount);
    event LeaderboardUpdated(uint256 _index, address _prevLink, address _newReferralLink);
    event TopUsersUpdated(uint256 _index, address _prevAddr, address _newAddr);
    event RewardSent(address _referralLink, address _address, uint256 _reward);
    event NFTSent(address _address, uint256 _nftIndex);

    function __LiquidityMining_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        bmiToken = IERC20(_contractsRegistry.getBMIContract());
        liquidityMiningNFT = IERC1155(_contractsRegistry.getLiquidityMiningNFTContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
    }

    function startLiquidityMining() external onlyOwner {
        require(startLiquidityMiningTime == 0, "LM: start liquidity mining is already set");

        startLiquidityMiningTime = block.timestamp;
    }

    function getAllTeamsLength() external view override returns (uint256) {
        return teamsArr.length();
    }

    function getAllTeamsDetails(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (TeamDetails[] memory _teamDetailsArr)
    {
        uint256 _to = (_offset.add(_limit)).min(teamsArr.length()).max(_offset);

        _teamDetailsArr = new TeamDetails[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            _teamDetailsArr[i - _offset] = _getTeamDetails(teamsArr.at(i));
        }
    }

    function getTeamLeaders(address _referralLink)
        external
        view
        override
        returns (address[] memory)
    {
        return teamInfos[_referralLink].teamLeaders;
    }

    function getMyTeamsLength() external view override returns (uint256) {
        return teamsMembers[usersTeamInfo[msg.sender].teamAddr].length();
    }

    function getMyTeamMembers(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (address[] memory _teamMembers, uint256[] memory _memberStakedAmount)
    {
        EnumerableSet.AddressSet storage _members =
            teamsMembers[usersTeamInfo[msg.sender].teamAddr];

        uint256 _to = (_offset.add(_limit)).min(_members.length()).max(_offset);
        uint256 _size = _to - _offset;

        _teamMembers = new address[](_size);
        _memberStakedAmount = new uint256[](_size);

        for (uint256 i = _offset; i < _to; i++) {
            address _currentMember = _members.at(i);
            _teamMembers[i - _offset] = _currentMember;
            _memberStakedAmount[i - _offset] = usersTeamInfo[_currentMember].stakedAmount;
        }
    }

    function getAllUsersLength() external view override returns (uint256) {
        return allUsers.length;
    }

    function getAllUsersInfo(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (UserInfo[] memory _userInfos)
    {
        uint256 _to = (_offset.add(_limit)).min(allUsers.length).max(_offset);

        _userInfos = new UserInfo[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            address _currentUserAddr = allUsers[i];

            _userInfos[i - _offset] = UserInfo(
                teamInfos[usersTeamInfo[_currentUserAddr].teamAddr].name,
                _currentUserAddr,
                usersTeamInfo[_currentUserAddr].stakedAmount
            );
        }
    }

    function getMyTeamInfo() external view override returns (MyTeamInfo memory _myTeamInfo) {
        UserTeamInfo storage userTeamInfo = usersTeamInfo[msg.sender];

        _myTeamInfo.teamDetails = _getTeamDetails(userTeamInfo.teamAddr);
        _myTeamInfo.myStakedAmount = userTeamInfo.stakedAmount;
    }

    function _getTeamDetails(address _teamAddr)
        internal
        view
        returns (TeamDetails memory _teamDetails)
    {
        _teamDetails = TeamDetails(
            teamInfos[_teamAddr].name,
            _teamAddr,
            teamsMembers[_teamAddr].length(),
            teamInfos[_teamAddr].totalAmount
        );
    }

    function createTeam(string calldata _teamName) external override {
        require(startLiquidityMiningTime != 0, "LM: Event has not started yet");
        require(bytes(_teamName).length != 0, "LM: Team name is empty");
        require(
            usersTeamInfo[msg.sender].teamAddr == address(0),
            "LM: The user is already in the team"
        );
        require(!existingNames[_teamName], "LM: Team name already exists");

        teamInfos[msg.sender].name = _teamName;
        usersTeamInfo[msg.sender].teamAddr = msg.sender;

        teamsArr.add(msg.sender);
        teamsMembers[msg.sender].add(msg.sender);
        existingNames[_teamName] = true;

        emit TeamCreated(msg.sender, _teamName);
    }

    function deleteTeam() external override {
        require(teamsMembers[msg.sender].length() == 1, "LM: Unable to delete a team");
        require(usersTeamInfo[msg.sender].stakedAmount == 0, "LM: Unable to remove a team");

        string memory _teamName = teamInfos[msg.sender].name;

        teamsArr.remove(msg.sender);
        delete usersTeamInfo[msg.sender];
        delete teamsMembers[msg.sender];
        delete teamInfos[msg.sender].name;
        delete existingNames[_teamName];

        emit TeamDeleted(msg.sender, _teamName);
    }

    function joinTheTeam(address _referralLink) external override {
        require(_referralLink != address(0), "LM: Invalid referral link");
        require(teamsArr.contains(_referralLink), "LM: There is no such team");
        require(
            usersTeamInfo[msg.sender].teamAddr == address(0),
            "LM: The user is already in the team"
        );

        teamsMembers[_referralLink].add(msg.sender);

        usersTeamInfo[msg.sender].teamAddr = _referralLink;

        emit MemberAdded(_referralLink, msg.sender, teamsMembers[_referralLink].length());
    }

    function getSlashingPercentage() public view override returns (uint256) {
        uint256 feePerSecond = MAX_SLASHING_FEE.div(LM_DURATION);
        return
            Math.min(
                block.timestamp.sub(startLiquidityMiningTime).mul(feePerSecond),
                MAX_SLASHING_FEE
            );
    }

    function investDAI(uint256 _tokensAmount, address _policyBookAddr) external override {
        require(_tokensAmount > 0, "LM: Tokens amount is zero");
        require(block.timestamp < getEndLMTime(), "LM: LME is over");
        require(
            policyBookRegistry.isPolicyBook(_policyBookAddr),
            "LM: Can't invest to not a PolicyBook"
        );

        address _userTeamAddr = usersTeamInfo[msg.sender].teamAddr;
        uint256 _userStakedAmount = usersTeamInfo[msg.sender].stakedAmount;

        require(_userTeamAddr != address(0), "LM: User is without a team");

        if (_userStakedAmount == 0) {
            allUsers.push(msg.sender);
        }

        uint256 _finalTokensAmount =
            _tokensAmount.sub(_tokensAmount.mul(getSlashingPercentage()).div(PERCENTAGE_100));

        teamInfos[_userTeamAddr].totalAmount = teamInfos[_userTeamAddr].totalAmount.add(
            _finalTokensAmount
        );

        usersTeamInfo[msg.sender].stakedAmount = _userStakedAmount.add(_finalTokensAmount);

        _updateTopUsers();
        _updateLeaderboard(_userTeamAddr);
        _updateGroupLeaders(_userTeamAddr);

        emit TeamInvested(_userTeamAddr, msg.sender, _finalTokensAmount);
        IPolicyBook(_policyBookAddr).addLiquidityFromLM(msg.sender, _tokensAmount);
    }

    function distributeNFT() external override {
        require(
            startLiquidityMiningTime != 0 && block.timestamp > getEndLMTime(),
            "LM: LME has not finished"
        );

        UserTeamInfo storage _userTeamInfo = usersTeamInfo[msg.sender];

        require(!_userTeamInfo.isNFTDistributed, "LM: NFT is already distributed");

        _userTeamInfo.isNFTDistributed = true;

        uint256 _indexInTheTeam = _getIndexInTheGroupLeaders(msg.sender);

        if (
            _getIndexInTheLeaderboard(_userTeamInfo.teamAddr) != MAX_LEADERBOARD_SIZE &&
            _indexInTheTeam != MAX_GROUP_LEADERS_SIZE
        ) {
            _sendNFT(_indexInTheTeam, msg.sender);
        }

        uint256 _topUsersLength = topUsers.length;

        for (uint256 i = 0; i < _topUsersLength; i++) {
            if (msg.sender == topUsers[i]) {
                liquidityMiningNFT.safeTransferFrom(address(this), msg.sender, 1, 1, "");
                emit NFTSent(msg.sender, 1);

                break;
            }
        }
    }

    function checkAvailableNFTReward(address _userAddr) external view override returns (bool) {
        if (startLiquidityMiningTime == 0 || block.timestamp < getEndLMTime()) {
            return false;
        }

        if (
            _getIndexInTheLeaderboard(usersTeamInfo[_userAddr].teamAddr) != MAX_LEADERBOARD_SIZE &&
            _getIndexInTheGroupLeaders(_userAddr) != MAX_GROUP_LEADERS_SIZE
        ) {
            return true;
        }

        if (_getIndexInTopUsers(_userAddr) != MAX_TOP_USERS_SIZE) {
            return true;
        }

        return false;
    }

    function getReward() external override returns (uint256) {
        require(
            startLiquidityMiningTime == 0 || block.timestamp > getEndLMTime(),
            "LM: LME has not finished"
        );

        address _teamAddr = usersTeamInfo[msg.sender].teamAddr;
        uint256 _userReward = checkAvailableBMIReward(msg.sender);

        if (_userReward == 0) {
            return 0;
        }

        bmiToken.transfer(msg.sender, _userReward);
        emit RewardSent(_teamAddr, msg.sender, _userReward);

        usersTeamInfo[msg.sender].countOfRewardedMonth += _getAvailableMonthForReward(msg.sender);

        return _userReward;
    }

    function checkAvailableBMIReward(address _userAddr) public view override returns (uint256) {
        if (startLiquidityMiningTime == 0) {
            return 0;
        }

        address _teamAddr = usersTeamInfo[_userAddr].teamAddr;
        uint256 _currentGroupIndex = _getIndexInTheLeaderboard(_teamAddr);
        uint256 _availableMonthCount = _getAvailableMonthForReward(_userAddr);

        if (
            _currentGroupIndex == MAX_LEADERBOARD_SIZE ||
            usersTeamInfo[_userAddr].stakedAmount == 0 ||
            _availableMonthCount == 0
        ) {
            return 0;
        }

        uint256 _totalReward = _getRewardPerMonth(_teamAddr).mul(_availableMonthCount);
        uint256 _userRewardPercent =
            _calculatePercentage(
                usersTeamInfo[_userAddr].stakedAmount,
                teamInfos[_teamAddr].totalAmount
            );

        uint256 _userReward = _totalReward.mul(_userRewardPercent).div(PERCENTAGE_100);

        return _userReward;
    }

    function getEndLMTime() public view override returns (uint256) {
        return startLiquidityMiningTime.add(LM_DURATION);
    }

    function _sendNFT(uint256 _index, address _userAddr) internal {
        uint256 _nftIndex;

        if (_index == 0) {
            _nftIndex = 2;
        } else if (_index < 4) {
            _nftIndex = 3;
        } else {
            _nftIndex = 4;
        }

        liquidityMiningNFT.safeTransferFrom(address(this), _userAddr, _nftIndex, 1, "");

        emit NFTSent(_userAddr, _nftIndex);
    }

    function _calculatePercentage(uint256 _part, uint256 _amount) internal pure returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        return _part.mul(PERCENTAGE_100).div(_amount);
    }

    function _getRewardPerMonth(address _teamAddr) internal view returns (uint256) {
        uint256 _indexInTheLeaderboard = _getIndexInTheLeaderboard(_teamAddr);
        uint256 _rewardPerMonth;

        if (_indexInTheLeaderboard == 0) {
            _rewardPerMonth = 30000;
        } else if (_indexInTheLeaderboard > 0 && _indexInTheLeaderboard < 5) {
            _rewardPerMonth = 10000;
        } else {
            _rewardPerMonth = 4000;
        }

        return _rewardPerMonth.mul(DECIMALS);
    }

    function _getAvailableMonthForReward(address _userAddr) internal view returns (uint256) {
        uint256 _startRewardTime = getEndLMTime();

        uint256 _countOfRewardedMonth = usersTeamInfo[_userAddr].countOfRewardedMonth;
        uint256 _numberOfMonthForReward;

        for (uint256 i = _countOfRewardedMonth; i < MAX_MONTH_TO_GET_REWARD; i++) {
            if (block.timestamp > _startRewardTime.add(ONE_MONTH.mul(i))) {
                _numberOfMonthForReward++;
            } else {
                break;
            }
        }

        return _numberOfMonthForReward;
    }

    function _getIndexInTopUsers(address _userAddr) internal view returns (uint256) {
        uint256 _foundIndex = MAX_TOP_USERS_SIZE;
        uint256 _topUsersLength = topUsers.length;

        for (uint256 i = 0; i < _topUsersLength; i++) {
            if (_userAddr == topUsers[i]) {
                _foundIndex = i;
                break;
            }
        }

        return _foundIndex;
    }

    function _getIndexInTheGroupLeaders(address _userAddr) internal view returns (uint256) {
        address _referralLink = usersTeamInfo[_userAddr].teamAddr;
        uint256 _size = teamInfos[_referralLink].teamLeaders.length;
        uint256 _foundIndex = MAX_GROUP_LEADERS_SIZE;

        for (uint256 i = 0; i < _size; i++) {
            if (_userAddr == teamInfos[_referralLink].teamLeaders[i]) {
                _foundIndex = i;
                break;
            }
        }

        return _foundIndex;
    }

    function _getIndexInTheLeaderboard(address _referralLink) internal view returns (uint256) {
        uint256 _leaderBoardLength = leaderboard.length;
        uint256 _foundIndex = MAX_LEADERBOARD_SIZE;

        for (uint256 i = 0; i < _leaderBoardLength; i++) {
            if (_referralLink == leaderboard[i]) {
                _foundIndex = i;
                break;
            }
        }

        return _foundIndex;
    }

    function _updateLeaderboard(address _referralLink) internal {
        uint256 _leaderBoardLength = leaderboard.length;

        if (_leaderBoardLength == 0) {
            leaderboard.push(_referralLink);
            emit LeaderboardUpdated(0, address(0), _referralLink);
            return;
        }

        uint256 _currentGroupIndex = _getIndexInTheLeaderboard(_referralLink);

        if (_currentGroupIndex == MAX_LEADERBOARD_SIZE) {
            _currentGroupIndex = leaderboard.length;
            leaderboard.push(_referralLink);
        }

        if (_currentGroupIndex == 0) {
            return;
        }

        uint256 _currentIndex = _currentGroupIndex - 1;
        uint256 _currentTeamAmount = teamInfos[_referralLink].totalAmount;

        while (_currentTeamAmount > teamInfos[leaderboard[_currentIndex]].totalAmount) {
            address _tmpLink = leaderboard[_currentIndex];
            leaderboard[_currentIndex] = _referralLink;
            leaderboard[_currentIndex + 1] = _tmpLink;

            if (_currentIndex == 0) {
                break;
            }

            _currentIndex--;
        }

        emit LeaderboardUpdated(_currentIndex, leaderboard[_currentIndex + 1], _referralLink);

        if (leaderboard.length > MAX_LEADERBOARD_SIZE) {
            leaderboard.pop();
        }
    }

    function _updateTopUsers() internal {
        uint256 _topUsersLength = topUsers.length;

        if (_topUsersLength == 0) {
            topUsers.push(msg.sender);
            emit TopUsersUpdated(0, address(0), msg.sender);
            return;
        }

        uint256 _currentIndex = _getIndexInTopUsers(msg.sender);

        if (_currentIndex == MAX_TOP_USERS_SIZE) {
            _currentIndex = _topUsersLength;
            topUsers.push(msg.sender);
        }

        if (_currentIndex == 0) {
            return;
        }

        uint256 _tmpIndex = _currentIndex - 1;
        uint256 _currentUserAmount = usersTeamInfo[msg.sender].stakedAmount;

        while (_currentUserAmount > usersTeamInfo[topUsers[_tmpIndex]].stakedAmount) {
            address _tmpAddr = topUsers[_tmpIndex];
            topUsers[_tmpIndex] = msg.sender;
            topUsers[_tmpIndex + 1] = _tmpAddr;

            if (_tmpIndex == 0) {
                break;
            }

            _tmpIndex--;
        }

        emit TopUsersUpdated(_tmpIndex, topUsers[_tmpIndex + 1], msg.sender);

        if (topUsers.length > MAX_TOP_USERS_SIZE) {
            topUsers.pop();
        }
    }

    function _updateGroupLeaders(address _referralLink) internal {
        uint256 _groupLeadersSize = teamInfos[_referralLink].teamLeaders.length;

        if (_groupLeadersSize == 0) {
            teamInfos[_referralLink].teamLeaders.push(msg.sender);
            return;
        }

        uint256 _currentIndex = _getIndexInTheGroupLeaders(msg.sender);

        if (_currentIndex == MAX_GROUP_LEADERS_SIZE) {
            _currentIndex = _groupLeadersSize;
            teamInfos[_referralLink].teamLeaders.push(msg.sender);
        }

        if (_currentIndex == 0) {
            return;
        }

        address[] memory _addresses = teamInfos[_referralLink].teamLeaders;
        uint256 _tmpIndex = _currentIndex - 1;
        uint256 _currentUserAmount = usersTeamInfo[msg.sender].stakedAmount;

        while (_currentUserAmount > usersTeamInfo[_addresses[_tmpIndex]].stakedAmount) {
            address _tmpAddr = _addresses[_tmpIndex];
            _addresses[_tmpIndex] = msg.sender;
            _addresses[_tmpIndex + 1] = _tmpAddr;

            if (_tmpIndex == 0) {
                break;
            }

            _tmpIndex--;
        }

        teamInfos[_referralLink].teamLeaders = _addresses;

        if (_addresses.length > MAX_GROUP_LEADERS_SIZE) {
            teamInfos[_referralLink].teamLeaders.pop();
        }
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IContractsRegistry {
    function getUniswapRouterContract() external view returns (address);

    function getUniswapBMIToETHPairContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getDAIContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMIDAIStakingContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getLiquidityMiningNFTContract() external view returns (address);

    function getLiquidityMiningContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getVBMIContract() external view returns (address);

    function getLiquidityMiningStakingContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface ILiquidityMining {
    struct TeamDetails {
        string teamName;
        address referralLink;
        uint256 membersNumber;
        uint256 totalStakedAmount;
    }

    struct MyTeamInfo {
        TeamDetails teamDetails;
        uint256 myStakedAmount;
    }

    struct UserInfo {
        string teamName;
        address userAddr;
        uint256 stakedAmount;
    }

    struct UserTeamInfo {
        address teamAddr;
        uint256 stakedAmount;
        uint256 countOfRewardedMonth;
        bool isNFTDistributed;
    }

    struct TeamInfo {
        string name;
        uint256 totalAmount;
        address[] teamLeaders;
    }

    function startLiquidityMiningTime() external view returns (uint256);

    function getAllTeamsLength() external view returns (uint256);

    function getAllTeamsDetails(uint256 _offset, uint256 _limit)
        external
        view
        returns (TeamDetails[] memory _teamDetailsArr);

    function getTeamLeaders(address _referralLink) external view returns (address[] memory);

    function getMyTeamsLength() external view returns (uint256);

    function getMyTeamMembers(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory _teamMembers, uint256[] memory _memberStakedAmount);

    function getAllUsersLength() external view returns (uint256);

    function getAllUsersInfo(uint256 _offset, uint256 _limit)
        external
        view
        returns (UserInfo[] memory _userInfos);

    function getMyTeamInfo() external view returns (MyTeamInfo memory _myTeamInfo);

    function createTeam(string calldata _teamName) external;

    function deleteTeam() external;

    function joinTheTeam(address _referralLink) external;

    function getSlashingPercentage() external view returns (uint256);

    function investDAI(uint256 _tokensAmount, address _policyBookAddr) external;

    function distributeNFT() external;

    function checkAvailableNFTReward(address _userAddr) external view returns (bool);

    function getReward() external returns (uint256);

    function checkAvailableBMIReward(address _userAddr) external view returns (uint256);

    function getEndLMTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IPolicyBook {
    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    struct PolicyHolder {
        uint256 coverTokens;
        uint256 startEpochNumber;
        uint256 endEpochNumber;
        uint256 payed;
    }

    struct WithdrawalInfo {
        uint256 withdrawalAmount;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    function EPOCH_DURATION() external view returns (uint256);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function whitelisted() external view returns (bool);

    function epochStartTime() external view returns (uint256);

    // @TODO: should we let DAO to change contract address?
    /// @notice Returns address of contract this PolicyBook covers, access: ANY
    /// @return _contract is address of covered contract
    function insuranceContractAddress() external view returns (address _contract);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function totalLiquidity() external view returns (uint256);

    function totalCoverTokens() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmount,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __PolicyBook_init(
        address _insuranceContract,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    function whitelist(bool _whitelisted) external;

    /// @notice get DAI equivalent
    function convertDAIXToDAI(uint256 _amount) external view returns (uint256);

    /// @notice get DAIx equivalent
    function convertDAIToDAIX(uint256 _amount) external view returns (uint256);

    /// @notice returns how many BMI tokens needs to approve in order to submit a claim
    function getClaimApprovalAmount(address user) external view returns (uint256);

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting() external;

    /// @notice submits new appeal claim of the policy book
    function submitAppealAndInitializeVoting() external;

    /// @notice updates info on claim acceptance
    function commitClaim(address claimer, uint256 claimAmount) external;

    function buyPolicyFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external returns (uint256);

    /// @notice Let user to buy policy by supplying DAI, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _coverTokens is number of tokens to cover
    function buyPolicy(uint256 _durationSeconds, uint256 _coverTokens) external returns (uint256);

    function updateEpochsInfo() external;

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice Let user to add liquidity by supplying DAI, access: ANY
    /// @param _liqudityAmount is amount of DAI tokens to secure
    function addLiquidity(uint256 _liqudityAmount) external;

    /// @notice Let liquidityMining contract to add liqiudity for another user by supplying DAI, access: ONLY LM
    /// @param _liquidityHolderAddr is address of address to assign cover
    /// @param _liqudityAmount is amount of DAI tokens to secure
    function addLiquidityFromLM(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _bmiDAIxAmount) external;

    function addLiquidityAndStakeWithPermit(
        uint256 _liquidityAmount,
        uint256 _bmiDAIxAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getAvailableDAIXWithdrawalAmount(address _userAddr) external view returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function requestWithdrawalWithPermit(
        uint256 _tokensToWithdraw,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function unlockTokens() external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external returns (uint256);

    /// @notice Getting user stats, access: ANY
    function userStats(address _user) external view returns (PolicyHolder memory);

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max token amount that a user can buy
    /// @return _totalDaiLiquidity is PolicyBook's liquidity
    /// @return _annualProfitYields is its APY
    /// @return _annualInsuranceCost is percentage of cover tokens that is required to be payed for 1 year of insurance
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _totalDaiLiquidity,
            uint256 _annualProfitYields,
            uint256 _annualInsuranceCost
        );

    /// @notice Getting stats, access: ANY
    /// @return _symbol is the symbol of PolicyBook (bmiDaiX)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is a type of insured contract
    /// @return _whitelisted is a state of whitelisting
    function stats()
        external
        view
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyBookFabric {
    enum ContractType {STABLECOIN, DEFI, CONTRACT, EXCHANGE}

    /// @notice Create new Policy Book contract, access: ANY
    /// @param _contract is Contract to create policy book for
    /// @param _contractType is Contract to create policy book for
    /// @param _description is bmiDAIx token desription for this policy book
    /// @param _projectSymbol replaces x in bmiDAIx token symbol
    /// @return _policyBook is address of created contract
    function create(
        address _contract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IPolicyBookFabric.sol";

interface IPolicyBookRegistry {
    struct PolicyBookStats {
        string symbol;
        address insuredContract;
        IPolicyBookFabric.ContractType contractType;
        uint256 maxCapacity;
        uint256 totalDaiLiquidity;
        uint256 APY;
        uint256 annualInsuranceCost;
        bool whitelisted;
    }

    /// @notice Adds PolicyBook to registry, access: PolicyFabric
    function add(address _insuredContract, address _policyBook) external;

    /// @notice Buys a batch of policies
    function buyPolicyBatch(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external returns (uint256[] memory _allowances);

    /// @notice Checks if provided address is a PolicyBook
    function isPolicyBook(address _contract) external view returns (bool);

    /// @notice Returns number of registered PolicyBooks, access: ANY
    function count() external view returns (uint256);

    /// @notice Listing registered PolicyBooks, access: ANY
    /// @return _policyBooks is array of registered PolicyBook addresses
    function list(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory _policyBooks);

    /// @notice Listing registered PolicyBooks, access: ANY
    function listWithStats(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory _policyBooks, PolicyBookStats[] memory _stats);

    /// @notice Return existing Policy Book contract, access: ANY
    /// @param _contract is contract address to lookup for created IPolicyBook
    function policyBookFor(address _contract) external view returns (address);

    /// @notice Getting stats from policy books, access: ANY
    /// @param _policyBooks is list of PolicyBooks addresses
    function stats(address[] calldata _policyBooks)
        external
        view
        returns (PolicyBookStats[] memory _stats);

    /// @notice Getting stats from policy books, access: ANY
    /// @param _insuredContracts is list of insuredContracts in registry
    function statsByInsuredContracts(address[] calldata _insuredContracts)
        external
        view
        returns (PolicyBookStats[] memory _stats);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

