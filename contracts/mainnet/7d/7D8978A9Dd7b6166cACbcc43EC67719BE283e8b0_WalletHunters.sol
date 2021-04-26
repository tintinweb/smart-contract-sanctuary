// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

abstract contract RelayRecipientUpgradeable is
    Initializable,
    ERC2771ContextUpgradeable
{
    function __RelayRecipientUpgradeable_init() internal initializer {
        __RelayRecipientUpgradeable_init_unchained();
    }

    function __RelayRecipientUpgradeable_init_unchained()
        internal
        initializer
    {}

    event TrustedForwarderChanged(address previous, address current);

    function _setTrustedForwarder(address trustedForwarder_) internal {
        address previousForwarder = _trustedForwarder;
        _trustedForwarder = trustedForwarder_;
        emit TrustedForwarderChanged(previousForwarder, trustedForwarder_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../interfaces/IWalletHunters.sol";
import "../utils/AccountingTokenUpgradeable.sol";
import "../gsn/RelayRecipientUpgradeable.sol";

contract WalletHunters is
    IWalletHunters,
    AccountingTokenUpgradeable,
    RelayRecipientUpgradeable,
    AccessControlUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct Request {
        address hunter;
        uint256 reward;
        uint256 creationTime;
        uint256 configurationIndex;
        bool discarded;
    }

    struct RequestVoting {
        uint256 votesFor;
        uint256 votesAgainst;
        EnumerableSetUpgradeable.AddressSet voters;
        mapping(address => SheriffVote) votes;
    }

    struct SheriffVote {
        uint256 amount;
        bool voteFor;
    }

    struct Configuration {
        uint256 votingDuration;
        uint256 sheriffsRewardShare;
        uint256 fixedSheriffReward;
        uint256 minimalVotesForRequest;
        uint256 minimalDepositForSheriff;
        uint256 requestReward;
    }

    uint256 public constant MAX_PERCENT = 10000; // 100%
    uint256 public constant SUPER_MAJORITY = 6700; // 67%

    bytes32 public constant MAYOR_ROLE = keccak256("MAYOR_ROLE");
    string private constant ERC20_NAME = "Wallet Hunters, Sheriff Token";
    string private constant ERC20_SYMBOL = "WHST";

    IERC20Upgradeable public stakingToken;

    uint256 public rewardsPool;
    CountersUpgradeable.Counter private _requestCounter;
    mapping(uint256 => Request) private _requests;
    mapping(uint256 => RequestVoting) private _requestVotings;
    mapping(address => EnumerableSetUpgradeable.UintSet)
        private _activeRequests;
    Configuration[] private _configurations;

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "Must have appropriate role");
        _;
    }

    function initialize(
        address admin_,
        address trustedForwarder_,
        address stakingToken_,
        uint256 votingDuration_,
        uint256 sheriffsRewardShare_,
        uint256 fixedSheriffReward_,
        uint256 minimalVotesForRequest_,
        uint256 minimalDepositForSheriff_,
        uint256 requestReward_
    ) external initializer {
        __WalletHunters_init(
            admin_,
            trustedForwarder_,
            stakingToken_,
            votingDuration_,
            sheriffsRewardShare_,
            fixedSheriffReward_,
            minimalVotesForRequest_,
            minimalDepositForSheriff_,
            requestReward_
        );
    }

    function __WalletHunters_init(
        address admin_,
        address trustedForwarder_,
        address stakingToken_,
        uint256 votingDuration_,
        uint256 sheriffsRewardShare_,
        uint256 fixedSheriffReward_,
        uint256 minimalVotesForRequest_,
        uint256 minimalDepositForSheriff_,
        uint256 requestReward_
    ) internal initializer {
        __AccountingToken_init(ERC20_NAME, ERC20_SYMBOL);
        __RelayRecipientUpgradeable_init();
        __AccessControl_init();

        __WalletHunters_init_unchained(
            admin_,
            trustedForwarder_,
            stakingToken_,
            votingDuration_,
            sheriffsRewardShare_,
            fixedSheriffReward_,
            minimalVotesForRequest_,
            minimalDepositForSheriff_,
            requestReward_
        );
    }

    function __WalletHunters_init_unchained(
        address admin,
        address trustedForwarder_,
        address stakingToken_,
        uint256 votingDuration_,
        uint256 sheriffsRewardShare_,
        uint256 fixedSheriffReward_,
        uint256 minimalVotesForRequest_,
        uint256 minimalDepositForSheriff_,
        uint256 requestReward_
    ) internal initializer {
        require(stakingToken_.isContract(), "StakingToken must be contract");
        require(
            trustedForwarder_.isContract(),
            "StakingToken must be contract"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MAYOR_ROLE, admin);

        stakingToken = IERC20Upgradeable(stakingToken_);

        super._setTrustedForwarder(trustedForwarder_);

        _updateConfiguration(
            votingDuration_,
            sheriffsRewardShare_,
            fixedSheriffReward_,
            minimalVotesForRequest_,
            minimalDepositForSheriff_,
            requestReward_
        );
    }

    function submitRequest(address hunter) external override returns (uint256) {
        require(_msgSender() == hunter, "Sender must be hunter");

        uint256 id = _requestCounter.current();
        _requestCounter.increment();

        Request storage _request = _requests[id];

        uint256 configurationIndex = _currentConfigurationIndex();

        _request.hunter = hunter;
        _request.reward = _configurations[configurationIndex].requestReward;
        _request.configurationIndex = configurationIndex;
        _request.discarded = false;
        // solhint-disable-next-line not-rely-on-time
        _request.creationTime = block.timestamp;

        // ignore return
        _activeRequests[hunter].add(id);

        emit NewWalletRequest(id, hunter, _request.reward);

        return id;
    }

    function stake(address sheriff, uint256 amount) external override {
        require(sheriff == _msgSender(), "Sender must be sheriff");
        require(amount > 0, "Cannot deposit 0");
        _mint(sheriff, amount);
        stakingToken.safeTransferFrom(sheriff, address(this), amount);
        emit Staked(sheriff, amount);
    }

    function vote(
        address sheriff,
        uint256 requestId,
        bool voteFor
    ) external override {
        require(sheriff == _msgSender(), "Sender must be sheriff");
        require(isSheriff(sheriff), "Sender is not sheriff");
        require(_votingState(requestId), "Voting is finished");
        require(
            _requests[requestId].hunter != sheriff,
            "Sheriff can't be hunter"
        );

        uint256 amount = balanceOf(sheriff);

        require(
            _activeRequests[sheriff].add(requestId),
            "User is already participated"
        );
        require(
            _requestVotings[requestId].voters.add(sheriff),
            "Sheriff is already participated"
        );
        _requestVotings[requestId].votes[sheriff].amount = amount;

        if (voteFor) {
            _requestVotings[requestId].votes[sheriff].voteFor = true;
            _requestVotings[requestId].votesFor =
                _requestVotings[requestId].votesFor +
                amount;
        } else {
            _requestVotings[requestId].votes[sheriff].voteFor = false;
            _requestVotings[requestId].votesAgainst =
                _requestVotings[requestId].votesAgainst +
                amount;
        }

        emit Voted(requestId, sheriff, amount, voteFor);
    }

    function discardRequest(uint256 requestId)
        external
        override
        onlyRole(MAYOR_ROLE)
    {
        require(_votingState(requestId), "Voting is finished");

        _requests[requestId].discarded = true;

        emit RequestDiscarded(requestId);
    }

    function withdraw(address sheriff, uint256 amount) public override {
        require(sheriff == _msgSender(), "Sender must be sheriff");
        require(amount > 0, "Cannot withdraw 0");
        uint256 available = balanceOf(sheriff) - lockedBalance(sheriff);
        require(amount <= available, "Withdraw exceeds balance");
        _burn(sheriff, amount);
        stakingToken.safeTransfer(sheriff, amount);
        emit Withdrawn(sheriff, amount);
    }

    function exit(address sheriff, uint256[] calldata requestIds)
        external
        override
    {
        claimRewards(sheriff, requestIds);
        withdraw(sheriff, balanceOf(sheriff));
    }

    function replenishRewardPool(address from, uint256 amount)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(from == _msgSender(), "Sender must be from address");
        rewardsPool += amount;

        stakingToken.safeTransferFrom(from, address(this), amount);

        emit ReplenishedRewardPool(from, amount);
    }

    function claimRewards(address user, uint256[] calldata requestIds)
        public
        override
    {
        require(user == _msgSender(), "Sender must be user");
        uint256 totalReward = 0;

        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];

            uint256 reward = userReward(user, requestId);

            _activeRequests[user].remove(requestId);

            totalReward = totalReward + reward;
        }

        if (totalReward > 0) {
            _transferReward(user, totalReward);
        }

        emit UserRewardPaid(user, requestIds, totalReward);
    }

    function claimHunterReward(address hunter, uint256[] calldata requestIds)
        external
        override
    {
        require(hunter == _msgSender(), "Sender must be hunter");
        uint256 totalReward = 0;

        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];

            uint256 reward = hunterReward(hunter, requestId);
            _activeRequests[hunter].remove(requestId);

            totalReward = totalReward + reward;
        }

        if (totalReward > 0) {
            _transferReward(hunter, totalReward);
        }

        emit HunterRewardPaid(hunter, requestIds, totalReward);
    }

    function claimSheriffRewards(address sheriff, uint256[] calldata requestIds)
        external
        override
    {
        require(sheriff == _msgSender(), "Sender must be sheriff");
        uint256 totalReward = 0;

        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];

            uint256 reward = sheriffReward(sheriff, requestId);
            _activeRequests[sheriff].remove(requestId);

            totalReward = totalReward + reward;
        }

        if (totalReward > 0) {
            _transferReward(sheriff, totalReward);
        }

        emit SheriffRewardPaid(sheriff, requestIds, totalReward);
    }

    function updateConfiguration(
        uint256 _votingDuration,
        uint256 _sheriffsRewardShare,
        uint256 _fixedSheriffReward,
        uint256 _minimalVotesForRequest,
        uint256 _minimalDepositForSheriff,
        uint256 _requestReward
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateConfiguration(
            _votingDuration,
            _sheriffsRewardShare,
            _fixedSheriffReward,
            _minimalVotesForRequest,
            _minimalDepositForSheriff,
            _requestReward
        );
    }

    function configuration()
        external
        view
        override
        returns (
            uint256 votingDuration,
            uint256 sheriffsRewardShare,
            uint256 fixedSheriffReward,
            uint256 minimalVotesForRequest,
            uint256 minimalDepositForSheriff,
            uint256 requestReward
        )
    {
        Configuration storage _configuration =
            _configurations[_currentConfigurationIndex()];

        votingDuration = _configuration.votingDuration;
        sheriffsRewardShare = _configuration.sheriffsRewardShare;
        fixedSheriffReward = _configuration.fixedSheriffReward;
        minimalVotesForRequest = _configuration.minimalVotesForRequest;
        minimalDepositForSheriff = _configuration.minimalDepositForSheriff;
        requestReward = _configuration.requestReward;
    }

    function configurationAt(uint256 index)
        external
        view
        returns (
            uint256 votingDuration,
            uint256 sheriffsRewardShare,
            uint256 fixedSheriffReward,
            uint256 minimalVotesForRequest,
            uint256 minimalDepositForSheriff,
            uint256 requestReward
        )
    {
        require(
            index <= _currentConfigurationIndex(),
            "Configuration doesn't exist"
        );
        Configuration storage _configuration = _configurations[index];

        votingDuration = _configuration.votingDuration;
        sheriffsRewardShare = _configuration.sheriffsRewardShare;
        fixedSheriffReward = _configuration.fixedSheriffReward;
        minimalVotesForRequest = _configuration.minimalVotesForRequest;
        minimalDepositForSheriff = _configuration.minimalDepositForSheriff;
        requestReward = _configuration.requestReward;
    }

    function _currentConfigurationIndex() internal view returns (uint256) {
        return _configurations.length - 1;
    }

    function _updateConfiguration(
        uint256 _votingDuration,
        uint256 _sheriffsRewardShare,
        uint256 _fixedSheriffReward,
        uint256 _minimalVotesForRequest,
        uint256 _minimalDepositForSheriff,
        uint256 _requestReward
    ) internal {
        require(
            _votingDuration >= 10 minutes && _votingDuration <= 1 weeks,
            "Voting duration too long"
        );
        require(
            _sheriffsRewardShare > 0 && _sheriffsRewardShare < MAX_PERCENT,
            "Sheriff share too much"
        );

        _configurations.push(
            Configuration({
                votingDuration: _votingDuration,
                sheriffsRewardShare: _sheriffsRewardShare,
                fixedSheriffReward: _fixedSheriffReward,
                minimalVotesForRequest: _minimalVotesForRequest,
                minimalDepositForSheriff: _minimalDepositForSheriff,
                requestReward: _requestReward
            })
        );

        emit ConfigurationChanged(
            _votingDuration,
            _sheriffsRewardShare,
            _fixedSheriffReward,
            _minimalVotesForRequest,
            _minimalDepositForSheriff,
            _requestReward
        );
    }

    function walletProposalsLength() external view override returns (uint256) {
        return _requestCounter.current();
    }

    function walletProposals(uint256 startRequestId, uint256 pageSize)
        external
        view
        override
        returns (WalletProposal[] memory)
    {
        require(
            startRequestId + pageSize <= _requestCounter.current(),
            "Read index out of bounds"
        );

        WalletProposal[] memory result = new WalletProposal[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            _walletProposal(startRequestId + i, result[i]);
        }

        return result;
    }

    function walletProposal(uint256 requestId)
        public
        view
        override
        returns (WalletProposal memory)
    {
        require(requestId < _requestCounter.current(), "Request doesn't exist");
        WalletProposal memory proposal;

        _walletProposal(requestId, proposal);

        return proposal;
    }

    function _walletProposal(uint256 requestId, WalletProposal memory proposal)
        internal
        view
    {
        proposal.requestId = requestId;

        proposal.hunter = _requests[requestId].hunter;
        proposal.reward = _requests[requestId].reward;
        proposal.creationTime = _requests[requestId].creationTime;

        uint256 configurationIndex = _requests[requestId].configurationIndex;

        proposal.finishTime =
            _requests[requestId].creationTime +
            _configurations[configurationIndex].votingDuration;

        proposal.sheriffsRewardShare = _configurations[configurationIndex]
            .sheriffsRewardShare;
        proposal.fixedSheriffReward = _configurations[configurationIndex]
            .fixedSheriffReward;

        proposal.votesFor = _requestVotings[requestId].votesFor;
        proposal.votesAgainst = _requestVotings[requestId].votesAgainst;

        proposal.claimedReward = !_activeRequests[_requests[requestId].hunter]
            .contains(requestId);
        proposal.state = _walletState(requestId);
    }

    function getVotesLength(uint256 requestId)
        external
        view
        override
        returns (uint256)
    {
        return _requestVotings[requestId].voters.length();
    }

    function getVotes(
        uint256 requestId,
        uint256 startIndex,
        uint256 pageSize
    ) external view override returns (WalletVote[] memory) {
        require(
            startIndex + pageSize <= _requestVotings[requestId].voters.length(),
            "Read index out of bounds"
        );

        WalletVote[] memory result = new WalletVote[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            address voter =
                _requestVotings[requestId].voters.at(startIndex + i);
            _getVote(requestId, voter, result[i]);
        }

        return result;
    }

    function getVote(uint256 requestId, address sheriff)
        external
        view
        override
        returns (WalletVote memory)
    {
        WalletVote memory _vote;

        _getVote(requestId, sheriff, _vote);

        return _vote;
    }

    function _transferReward(address destination, uint256 amount) internal {
        require(amount <= rewardsPool, "Don't enough tokens in reward pool");

        rewardsPool -= amount;

        stakingToken.safeTransfer(destination, amount);
    }

    function _getVote(
        uint256 requestId,
        address sheriff,
        WalletVote memory _vote
    ) internal view {
        require(requestId < _requestCounter.current(), "Request doesn't exist");

        _vote.requestId = requestId;
        _vote.sheriff = sheriff;

        _vote.amount = _requestVotings[requestId].votes[sheriff].amount;
        _vote.voteFor = _requestVotings[requestId].votes[sheriff].voteFor;
    }

    function userRewards(address user)
        external
        view
        override
        returns (uint256)
    {
        uint256 totalReward = 0;

        for (uint256 i = 0; i < _activeRequests[user].length(); i++) {
            uint256 requestId = _activeRequests[user].at(i);

            if (_votingState(requestId)) {
                // voting is not finished
                continue;
            }

            uint256 reward = userReward(user, requestId);

            totalReward = totalReward + reward;
        }

        return totalReward;
    }

    function userReward(address user, uint256 requestId)
        public
        view
        override
        returns (uint256)
    {
        uint256 reward;
        if (_requests[requestId].hunter == user) {
            reward = hunterReward(user, requestId);
        } else {
            reward = sheriffReward(user, requestId);
        }

        return reward;
    }

    function hunterReward(address hunter, uint256 requestId)
        public
        view
        override
        returns (uint256)
    {
        require(!_votingState(requestId), "Voting is not finished");
        require(
            hunter == _requests[requestId].hunter,
            "Hunter isn't valid for request"
        );
        require(
            _activeRequests[hunter].contains(requestId),
            "Already rewarded"
        );

        if (!_isEnoughVotes(requestId) || _requests[requestId].discarded) {
            return 0;
        }

        if (_walletApproved(requestId)) {
            uint256 sheriffsRewardShare =
                _configurations[_requests[requestId].configurationIndex]
                    .sheriffsRewardShare;

            return
                (_requests[requestId].reward *
                    (MAX_PERCENT - sheriffsRewardShare)) / MAX_PERCENT;
        } else {
            return 0;
        }
    }

    function sheriffReward(address sheriff, uint256 requestId)
        public
        view
        override
        returns (uint256)
    {
        require(!_votingState(requestId), "Voting is not finished");
        require(
            _requestVotings[requestId].votes[sheriff].amount > 0,
            "Sheriff doesn't vote"
        );
        require(
            _activeRequests[sheriff].contains(requestId),
            "Already rewarded"
        );

        if (!_isEnoughVotes(requestId) || _requests[requestId].discarded) {
            return 0;
        }

        bool walletApproved = _walletApproved(requestId);

        if (
            walletApproved &&
            _requestVotings[requestId].votes[sheriff].voteFor
        ) {
            uint256 reward = _requests[requestId].reward;
            uint256 votes = _requestVotings[requestId].votes[sheriff].amount;
            uint256 totalVotes = _requestVotings[requestId].votesFor;
            uint256 sheriffsRewardShare =
                _configurations[_requests[requestId].configurationIndex]
                    .sheriffsRewardShare;
            uint256 fixedSheriffReward =
                _configurations[_requests[requestId].configurationIndex]
                    .fixedSheriffReward;

            uint256 actualReward =
                (((reward * votes) / totalVotes) * sheriffsRewardShare) /
                    MAX_PERCENT;

            return MathUpgradeable.max(actualReward, fixedSheriffReward);
        } else if (
            !walletApproved &&
            !_requestVotings[requestId].votes[sheriff].voteFor
        ) {
            return
                _configurations[_requests[requestId].configurationIndex]
                    .fixedSheriffReward;
        } else {
            return 0;
        }
    }

    function setTrustedForwarder(address trustedForwarder)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._setTrustedForwarder(trustedForwarder);
    }

    function activeRequests(
        address user,
        uint256 startIndex,
        uint256 pageSize
    ) external view override returns (uint256[] memory) {
        require(
            startIndex + pageSize <= _activeRequests[user].length(),
            "Read index out of bounds"
        );

        uint256[] memory result = new uint256[](pageSize);

        for (uint256 i = 0; i < pageSize; i++) {
            result[i] = _activeRequests[user].at(startIndex + i);
        }

        return result;
    }

    function activeRequest(address user, uint256 index)
        external
        view
        override
        returns (uint256)
    {
        return _activeRequests[user].at(index);
    }

    function activeRequestsLength(address user)
        external
        view
        override
        returns (uint256)
    {
        return _activeRequests[user].length();
    }

    function isSheriff(address sheriff) public view override returns (bool) {
        return
            balanceOf(sheriff) >=
            _configurations[_currentConfigurationIndex()]
                .minimalDepositForSheriff;
    }

    function lockedBalance(address user)
        public
        view
        override
        returns (uint256 locked)
    {
        locked = 0;

        for (uint256 i = 0; i < _activeRequests[user].length(); i++) {
            uint256 requestId = _activeRequests[user].at(i);
            if (!_votingState(requestId)) {
                // voting finished
                continue;
            }

            uint256 votes = _requestVotings[requestId].votes[user].amount;
            if (votes > locked) {
                locked = votes;
            }
        }
    }

    function _walletState(uint256 requestId) internal view returns (State) {
        if (_requests[requestId].discarded) {
            return State.DISCARDED;
        }

        if (_votingState(requestId)) {
            return State.ACTIVE;
        }

        if (_isEnoughVotes(requestId) && _walletApproved(requestId)) {
            return State.APPROVED;
        } else {
            return State.DECLINED;
        }
    }

    function _isEnoughVotes(uint256 requestId) internal view returns (bool) {
        uint256 totalVotes =
            _requestVotings[requestId].votesFor +
                _requestVotings[requestId].votesAgainst;

        uint256 minimalVotesForRequest =
            _configurations[_requests[requestId].configurationIndex]
                .minimalVotesForRequest;

        return totalVotes >= minimalVotesForRequest;
    }

    function _walletApproved(uint256 requestId) internal view returns (bool) {
        uint256 totalVotes =
            _requestVotings[requestId].votesFor +
                _requestVotings[requestId].votesAgainst;

        return
            (_requestVotings[requestId].votesFor * MAX_PERCENT) / totalVotes >
            SUPER_MAJORITY;
    }

    function _votingState(uint256 requestId) internal view returns (bool) {
        require(requestId < _requestCounter.current(), "Request doesn't exist");

        // solhint-disable-next-line not-rely-on-time
        uint256 votingDuration =
            _configurations[_requests[requestId].configurationIndex]
                .votingDuration;

        return
            block.timestamp <
            _requests[requestId].creationTime + votingDuration &&
            !_requests[requestId].discarded;
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWalletHunters {
    enum State {ACTIVE, APPROVED, DECLINED, DISCARDED}

    struct WalletProposal {
        uint256 requestId;
        address hunter;
        uint256 reward;
        State state;
        bool claimedReward;
        uint256 creationTime;
        uint256 finishTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 sheriffsRewardShare;
        uint256 fixedSheriffReward;
    }

    struct WalletVote {
        uint256 requestId;
        address sheriff;
        uint256 amount;
        bool voteFor;
    }

    event NewWalletRequest(
        uint256 indexed requestId,
        address indexed hunter,
        uint256 reward
    );

    event Staked(address indexed sheriff, uint256 amount);

    event Withdrawn(address indexed sheriff, uint256 amount);

    event Voted(
        uint256 indexed requestId,
        address indexed sheriff,
        uint256 amount,
        bool voteFor
    );

    event HunterRewardPaid(
        address indexed hunter,
        uint256[] requestIds,
        uint256 totalReward
    );

    event SheriffRewardPaid(
        address indexed sheriff,
        uint256[] requestIds,
        uint256 totalReward
    );

    event UserRewardPaid(
        address indexed user,
        uint256[] requestIds,
        uint256 totalReward
    );

    event RequestDiscarded(uint256 indexed requestId);

    event ConfigurationChanged(
        uint256 votingDuration,
        uint256 sheriffsRewardShare,
        uint256 fixedSheriffReward,
        uint256 minimalVotesForRequest,
        uint256 minimalDepositForSheriff,
        uint256 requestReward
    );

    event ReplenishedRewardPool(address from, uint256 amount);

    /**
     * @dev        Submit a new wallet request. Increment request id and return it. Counter starts
     * from 0. Request automatically moved in active state, see enum #State. Caller must be hunter.
     * Emit #NewWalletRequest.
     * @param      hunter  The hunter address, which will get reward.
     * for sheriffs reward in approve case.
     * @return     request id for submitted request.
     */
    function submitRequest(address hunter) external returns (uint256);

    /**
     * @dev        Discard wallet request and move request at discarded state, see enum #State.
     * Every who participated gets 0 reward. Caller must have access role. Emit #RequestDiscarded.
     * @param      requestId The reqiest id, request must be in active state.
     */
    function discardRequest(uint256 requestId) external;

    /**
     * @dev        Deposit san tokens to have ability to vote for request. Before user
     * should approve tokens using ERC20#approve. Mint internall tokens that represents
     * amount of staked tokens 1:1. Emit #Staked.
     * @param      sheriff  The sheriff address
     * @param      amount   The amount of san tokens
     */
    function stake(address sheriff, uint256 amount) external;

    /**
     * @dev        Vote for wallet request with amount of staked tokens. Sheriff can vote only once.
     * Lock user stake for period of voting. Wallet request must be in active state, see
     * enum #State. Emit #Voted.
     * @param      sheriff    The sheriff address
     * @param      requestId  The request identifier
     * @param      voteFor    The vote for
     */
    function vote(
        address sheriff,
        uint256 requestId,
        bool voteFor
    ) external;

    /**
     * @dev        Withdraw san tokens. Burn internall tokens 1:1. Tokens must not be in locked
     * state. Emit #Withdrawn
     * @param      sheriff  The sheriff
     * @param      amount   The amount
     */
    function withdraw(address sheriff, uint256 amount) external;

    /**
     * @dev        Combine two invokes #claimRewards and #withdraw.
     * @param      sheriff     The sheriff address
     * @param      requestIds  The request ids
     */
    function exit(address sheriff, uint256[] calldata requestIds) external;

    /**
     * @dev        Return wallet requests that user participates at this time as sheriff or hunter.
     * Request can be in voting or finished state.
     * @param      user         The user address
     * @param      startIndex  The start index. Can be 0
     * @param      pageSize     The page size. Can be #activeRequestsLength
     * @return     array of request ids
     */
    function activeRequests(
        address user,
        uint256 startIndex,
        uint256 pageSize
    ) external view returns (uint256[] memory);

    /**
     * @dev        Get request id at index at array.
     * @param      user   The user address
     * @param      index  The index
     * @return     request id
     */
    function activeRequest(address user, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev        Return amount of requests that user participates at this time as sheriff or
     * hunter. Should be used for iterating over requests using #activeRequest.
     * @param      user  The user address
     * @return     length of user requests array
     */
    function activeRequestsLength(address user) external view returns (uint256);

    /**
     * @dev        Replinish reward pool in staking tokens.
     * @param      from    The address from whom tokens will be transfered
     * @param      amount  The amount of tokens
     */
    function replenishRewardPool(address from, uint256 amount) external;

    /**
     * @dev        Claim hunter and sheriff rewards. Mint reward tokens. Should be used all
     * available request ids in not active state for user, even if #hunterReward equal 0 for
     * specific request id. Emit #UserRewardPaid. Remove requestIds from #activeRequests set.
     * @param      user        The user address
     * @param      requestIds  The request ids
     */
    function claimRewards(address user, uint256[] calldata requestIds) external;

    /**
     * @dev        Claim hunter reward. Mint reward tokens. Should be used all available request
     * ids in finished state for hunter, even if #hunterReward equal 0 for specific request id.
     * Emit #HunterRewardPaid. Remove requestIds from #activeRequests set.
     * @param      hunter      The hunter address
     * @param      requestIds  The request ids
     */
    function claimHunterReward(address hunter, uint256[] calldata requestIds)
        external;

    /**
     * @dev        Claim sheriff reward. Mint reward tokens. Should be used all available request
     * ids in finished state for sheriff, even if #hunterReward equal 0 for specific request id.
     * Emit #SheriffRewardPaid. Remove requestIds from #activeRequests set.
     * @param      sheriff      The sheriff address.
     * @param      requestIds  The request ids.
     */
    function claimSheriffRewards(address sheriff, uint256[] calldata requestIds)
        external;

    /**
     * @dev        Get wallet request data.
     * @param      startRequestId  The start request id. Can be 0
     * @param      pageSize        The page size. Can be #walletProposalsLength
     */
    function walletProposals(uint256 startRequestId, uint256 pageSize)
        external
        view
        returns (WalletProposal[] memory);

    /**
     * @dev        Get wallet request data.
     * @param      requestId  The request id
     */
    function walletProposal(uint256 requestId)
        external
        view
        returns (WalletProposal memory);

    /**
     * @dev        Get amount of all proposals
     * @return     Amount of all proposals
     */
    function walletProposalsLength() external view returns (uint256);

    /**
     * @dev        Wallet hunters configuration.
     */
    function configuration()
        external
        view
        returns (
            uint256 votingDuration,
            uint256 sheriffsRewardShare,
            uint256 fixedSheriffReward,
            uint256 minimalVotesForRequest,
            uint256 minimalDepositForSheriff,
            uint256 requestReward
        );

    /**
     * @dev        Update wallet hunters configuration. Must have access role. Emit
     * #ConfigurationChanged.
     * @param      votingDuration            The voting duration for next request.
     * @param      sheriffsRewardShare       The sheriffs reward share for next request.
     * @param      fixedSheriffReward        The fixed sheriff reward in case of disapprove request
     * for next request.
     * @param      minimalVotesForRequest    The minimal votes for request to be approved.
     * @param      minimalDepositForSheriff  The minimal deposit to become sheriff.
     * @param      requestReward             The reward for next request;
     */
    function updateConfiguration(
        uint256 votingDuration,
        uint256 sheriffsRewardShare,
        uint256 fixedSheriffReward,
        uint256 minimalVotesForRequest,
        uint256 minimalDepositForSheriff,
        uint256 requestReward
    ) external;

    /**
     * @dev        Get amount of reward tokens that user can claim for request as hunter or sheriff.
     * Request must have not active state, see enum #State.
     * @param      user       The user address
     * @param      requestId  The request id
     * @return     amount of reward tokens. Return 0 if request was discarded
     */
    function userReward(address user, uint256 requestId)
        external
        view
        returns (uint256);

    /**
     * @dev        Sum up amount of reward tokens that user can claim for request as hunter or
     * sheriff. Will be used only requests that has not active state.
     * @param      user  The user address
     * @return     amount of reward tokens
     */
    function userRewards(address user) external view returns (uint256);

    /**
     * @dev        Get amount of reward tokens that hunter can claim for request. Request must have
     * not active state, see enum #State.
     * @param      hunter     The hunter address
     * @param      requestId  The request id
     * @return     amount of reward tokens. Return 0 if request was discarded
     */
    function hunterReward(address hunter, uint256 requestId)
        external
        view
        returns (uint256);

    /**
     * @dev        Get amount of reward tokens that sheriff can claim for request. Request must have
     * not active state, see enum #State.
     * @param      sheriff    The sheriff address
     * @param      requestId  The request id
     * @return     amount of reward tokens. Return 0 if request was discarded or user voted wrong
     */
    function sheriffReward(address sheriff, uint256 requestId)
        external
        view
        returns (uint256);

    /**
     * @dev        Get sheriff vote information for wallet request.
     * @param      requestId  The request id
     * @param      sheriff    The sheriff address
     */
    function getVote(uint256 requestId, address sheriff)
        external
        view
        returns (WalletVote memory);

    /**
     * @dev        Get amount of votes for request.
     * @param      requestId  The request id
     */
    function getVotesLength(uint256 requestId) external view returns (uint256);

    /**
     * @dev        Get list of votes for request.
     * @param      requestId   The request id
     * @param      startIndex  The start index. Can be 0
     * @param      pageSize    The page size. Can be #getVotesLength
     */
    function getVotes(
        uint256 requestId,
        uint256 startIndex,
        uint256 pageSize
    ) external view returns (WalletVote[] memory);

    /**
     * @dev        Get amount of locked balance for user, see #vote.
     * @param      sheriff  The sheriff address
     * @return     amount of locked tokens
     */
    function lockedBalance(address sheriff) external view returns (uint256);

    /**
     * @dev        Check sheriff status for user. User must stake enough tokens to be sheriff, see
     * #configuration.
     * @param      sheriff  The user address
     */
    function isSheriff(address sheriff) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @dev This contract is version of ERC20 token, but with limitations: holder can't transfer these tokens.
 */
contract AccountingTokenUpgradeable is ERC20Upgradeable {
    function __AccountingToken_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __ERC20_init(name_, symbol_);

        __AccountingToken_init_unchained();
    }

    function __AccountingToken_init_unchained() internal initializer {}

    // Do not need transfer of this token
    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert("Forbidden");
    }

    // Do not need allowance of this token
    function _approve(
        address,
        address,
        uint256
    ) internal pure override {
        revert("Forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/*
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly { sender := shr(96, calldataload(sub(calldatasize(), 20))) }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length-20];
        } else {
            return super._msgData();
        }
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
library EnumerableSetUpgradeable {
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}