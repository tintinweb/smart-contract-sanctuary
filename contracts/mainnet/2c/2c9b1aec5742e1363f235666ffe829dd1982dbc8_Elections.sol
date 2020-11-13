// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./SafeMath.sol";

import "./IElections.sol";
import "./IDelegation.sol";
import "./IGuardiansRegistration.sol";
import "./ICommittee.sol";
import "./ICertification.sol";
import "./ManagedContract.sol";

contract Elections is IElections, ManagedContract {
	using SafeMath for uint256;

	uint32 constant PERCENT_MILLIE_BASE = 100000;

	mapping(address => mapping(address => uint256)) voteUnreadyVotes; // by => to => expiration
	mapping(address => uint256) public votersStake;
	mapping(address => address) voteOutVotes; // by => to
	mapping(address => uint256) accumulatedStakesForVoteOut; // addr => total stake
	mapping(address => bool) votedOutGuardians;

	struct Settings {
		uint32 minSelfStakePercentMille;
		uint32 voteUnreadyPercentMilleThreshold;
		uint32 voteOutPercentMilleThreshold;
	}
	Settings settings;

	constructor(IContractRegistry _contractRegistry, address _registryAdmin, uint32 minSelfStakePercentMille, uint32 voteUnreadyPercentMilleThreshold, uint32 voteOutPercentMilleThreshold) ManagedContract(_contractRegistry, _registryAdmin) public {
		setMinSelfStakePercentMille(minSelfStakePercentMille);
		setVoteOutPercentMilleThreshold(voteOutPercentMilleThreshold);
		setVoteUnreadyPercentMilleThreshold(voteUnreadyPercentMilleThreshold);
	}

	modifier onlyDelegationsContract() {
		require(msg.sender == address(delegationsContract), "caller is not the delegations contract");

		_;
	}

	modifier onlyGuardiansRegistrationContract() {
		require(msg.sender == address(guardianRegistrationContract), "caller is not the guardian registrations contract");

		_;
	}

	/*
	 * External functions
	 */

	function readyToSync() external override onlyWhenActive {
		address guardian = guardianRegistrationContract.resolveGuardianAddress(msg.sender); // this validates registration
		require(!isVotedOut(guardian), "caller is voted-out");

		emit GuardianStatusUpdated(guardian, true, false);

		committeeContract.removeMember(guardian);
	}

	function readyForCommittee() external override onlyWhenActive {
		_readyForCommittee(msg.sender);
	}

	function canJoinCommittee(address guardian) external view override returns (bool) {
		guardian = guardianRegistrationContract.resolveGuardianAddress(guardian); // this validates registration

		if (isVotedOut(guardian)) {
			return false;
		}

		(, uint256 effectiveStake, ) = getGuardianStakeInfo(guardian, settings);
		return committeeContract.checkAddMember(guardian, effectiveStake);
	}

	function getEffectiveStake(address guardian) external override view returns (uint effectiveStake) {
		(, effectiveStake, ) = getGuardianStakeInfo(guardian, settings);
	}

	/// @dev returns the current committee
	function getCommittee() external override view returns (address[] memory committee, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips) {
		IGuardiansRegistration _guardianRegistrationContract = guardianRegistrationContract;
		(committee, weights, certification) = committeeContract.getCommittee();
		orbsAddrs = _guardianRegistrationContract.getGuardiansOrbsAddress(committee);
		ips = _guardianRegistrationContract.getGuardianIps(committee);
	}

	// Vote-unready

	function voteUnready(address subject, uint voteExpiration) external override onlyWhenActive {
		require(voteExpiration >= block.timestamp, "vote expiration time must not be in the past");

		address voter = guardianRegistrationContract.resolveGuardianAddress(msg.sender);
		voteUnreadyVotes[voter][subject] = voteExpiration;
		emit VoteUnreadyCasted(voter, subject, voteExpiration);

		(address[] memory generalCommittee, uint256[] memory generalWeights, bool[] memory certification) = committeeContract.getCommittee();

		bool votedUnready = isCommitteeVoteUnreadyThresholdReached(generalCommittee, generalWeights, certification, subject);
		if (votedUnready) {
			clearCommitteeUnreadyVotes(generalCommittee, subject);
			emit GuardianVotedUnready(subject);

			emit GuardianStatusUpdated(subject, false, false);
			committeeContract.removeMember(subject);
		}
	}

	function getVoteUnreadyVote(address voter, address subject) public override view returns (bool valid, uint256 expiration) {
		expiration = voteUnreadyVotes[voter][subject];
		valid = expiration != 0 && block.timestamp < expiration;
	}

	function getVoteUnreadyStatus(address subject) external override view returns (address[] memory committee, uint256[] memory weights, bool[] memory certification, bool[] memory votes, bool subjectInCommittee, bool subjectInCertifiedCommittee) {
		(committee, weights, certification) = committeeContract.getCommittee();

		votes = new bool[](committee.length);
		for (uint i = 0; i < committee.length; i++) {
			address memberAddr = committee[i];
			if (block.timestamp < voteUnreadyVotes[memberAddr][subject]) {
				votes[i] = true;
			}

			if (memberAddr == subject) {
				subjectInCommittee = true;
				subjectInCertifiedCommittee = certification[i];
			}
		}
	}

	// Vote-out

	function voteOut(address subject) external override onlyWhenActive {
		Settings memory _settings = settings;

		address voter = msg.sender;
		address prevSubject = voteOutVotes[voter];

		voteOutVotes[voter] = subject;
		emit VoteOutCasted(voter, subject);

		uint256 voterStake = delegationsContract.getDelegatedStake(voter);

		if (prevSubject == address(0)) {
			votersStake[voter] = voterStake;
		}

		if (subject == address(0)) {
			delete votersStake[voter];
		}

		uint totalStake = delegationsContract.getTotalDelegatedStake();

		if (prevSubject != address(0) && prevSubject != subject) {
			applyVoteOutVotesFor(prevSubject, 0, voterStake, totalStake, _settings);
		}

		if (subject != address(0)) {
			uint voteStakeAdded = prevSubject != subject ? voterStake : 0;
			applyVoteOutVotesFor(subject, voteStakeAdded, 0, totalStake, _settings); // recheck also if not new
		}
	}

	function getVoteOutVote(address voter) external override view returns (address) {
		return voteOutVotes[voter];
	}

	function getVoteOutStatus(address subject) external override view returns (bool votedOut, uint votedStake, uint totalDelegatedStake) {
		votedOut = isVotedOut(subject);
		votedStake = accumulatedStakesForVoteOut[subject];
		totalDelegatedStake = delegationsContract.getTotalDelegatedStake();
	}

	/*
	 * Notification functions from other PoS contracts
	 */

	function delegatedStakeChange(address delegate, uint256 selfStake, uint256 delegatedStake, uint256 totalDelegatedStake) external override onlyDelegationsContract onlyWhenActive {
		Settings memory _settings = settings;

		uint effectiveStake = calcEffectiveStake(selfStake, delegatedStake, _settings);
		emit StakeChanged(delegate, selfStake, delegatedStake, effectiveStake);

		committeeContract.memberWeightChange(delegate, effectiveStake);

		applyStakesToVoteOutBy(delegate, delegatedStake, totalDelegatedStake, _settings);
	}

	/// @dev Called by: guardian registration contract
	/// Notifies a new guardian was unregistered
	function guardianUnregistered(address guardian) external override onlyGuardiansRegistrationContract onlyWhenActive {
		emit GuardianStatusUpdated(guardian, false, false);
		committeeContract.removeMember(guardian);
	}

	/// @dev Called by: guardian registration contract
	/// Notifies on a guardian certification change
	function guardianCertificationChanged(address guardian, bool isCertified) external override onlyWhenActive {
		committeeContract.memberCertificationChange(guardian, isCertified);
	}

	/*
     * Governance functions
	 */

	function setMinSelfStakePercentMille(uint32 minSelfStakePercentMille) public override onlyFunctionalManager {
		require(minSelfStakePercentMille <= PERCENT_MILLIE_BASE, "minSelfStakePercentMille must be 100000 at most");
		emit MinSelfStakePercentMilleChanged(minSelfStakePercentMille, settings.minSelfStakePercentMille);
		settings.minSelfStakePercentMille = minSelfStakePercentMille;
	}

	function getMinSelfStakePercentMille() external override view returns (uint32) {
		return settings.minSelfStakePercentMille;
	}

	function setVoteOutPercentMilleThreshold(uint32 voteOutPercentMilleThreshold) public override onlyFunctionalManager {
		require(voteOutPercentMilleThreshold <= PERCENT_MILLIE_BASE, "voteOutPercentMilleThreshold must not be larger than 100000");
		emit VoteOutPercentMilleThresholdChanged(voteOutPercentMilleThreshold, settings.voteOutPercentMilleThreshold);
		settings.voteOutPercentMilleThreshold = voteOutPercentMilleThreshold;
	}

	function getVoteOutPercentMilleThreshold() external override view returns (uint32) {
		return settings.voteOutPercentMilleThreshold;
	}

	function setVoteUnreadyPercentMilleThreshold(uint32 voteUnreadyPercentMilleThreshold) public override onlyFunctionalManager {
		require(voteUnreadyPercentMilleThreshold <= PERCENT_MILLIE_BASE, "voteUnreadyPercentMilleThreshold must not be larger than 100000");
		emit VoteUnreadyPercentMilleThresholdChanged(voteUnreadyPercentMilleThreshold, settings.voteUnreadyPercentMilleThreshold);
		settings.voteUnreadyPercentMilleThreshold = voteUnreadyPercentMilleThreshold;
	}

	function getVoteUnreadyPercentMilleThreshold() external override view returns (uint32) {
		return settings.voteUnreadyPercentMilleThreshold;
	}

	function getSettings() external override view returns (
		uint32 minSelfStakePercentMille,
		uint32 voteUnreadyPercentMilleThreshold,
		uint32 voteOutPercentMilleThreshold
	) {
		Settings memory _settings = settings;
		minSelfStakePercentMille = _settings.minSelfStakePercentMille;
		voteUnreadyPercentMilleThreshold = _settings.voteUnreadyPercentMilleThreshold;
		voteOutPercentMilleThreshold = _settings.voteOutPercentMilleThreshold;
	}

	function initReadyForCommittee(address[] calldata guardians) external override onlyInitializationAdmin {
		for (uint i = 0; i < guardians.length; i++) {
			_readyForCommittee(guardians[i]);
		}
	}

	/*
     * Private functions
	 */

	function _readyForCommittee(address guardian) private {
		guardian = guardianRegistrationContract.resolveGuardianAddress(guardian); // this validates registration
		require(!isVotedOut(guardian), "caller is voted-out");

		emit GuardianStatusUpdated(guardian, true, true);

		(, uint256 effectiveStake, ) = getGuardianStakeInfo(guardian, settings);
		committeeContract.addMember(guardian, effectiveStake, certificationContract.isGuardianCertified(guardian));
	}

	function calcEffectiveStake(uint256 selfStake, uint256 delegatedStake, Settings memory _settings) private pure returns (uint256) {
		if (selfStake.mul(PERCENT_MILLIE_BASE) >= delegatedStake.mul(_settings.minSelfStakePercentMille)) {
			return delegatedStake;
		}
		return selfStake.mul(PERCENT_MILLIE_BASE).div(_settings.minSelfStakePercentMille); // never overflows or divides by zero
	}

	function getGuardianStakeInfo(address guardian, Settings memory _settings) private view returns (uint256 selfStake, uint256 effectiveStake, uint256 delegatedStake) {
		IDelegations _delegationsContract = delegationsContract;
		(,selfStake) = _delegationsContract.getDelegationInfo(guardian);
		delegatedStake = _delegationsContract.getDelegatedStake(guardian);
		effectiveStake = calcEffectiveStake(selfStake, delegatedStake, _settings);
	}

	// Vote-unready

	function isCommitteeVoteUnreadyThresholdReached(address[] memory committee, uint256[] memory weights, bool[] memory certification, address subject) private returns (bool) {
		Settings memory _settings = settings;

		uint256 totalCommitteeStake = 0;
		uint256 totalVoteUnreadyStake = 0;
		uint256 totalCertifiedStake = 0;
		uint256 totalCertifiedVoteUnreadyStake = 0;

		address member;
		uint256 memberStake;
		bool isSubjectCertified;
		for (uint i = 0; i < committee.length; i++) {
			member = committee[i];
			memberStake = weights[i];

			if (member == subject && certification[i]) {
				isSubjectCertified = true;
			}

			totalCommitteeStake = totalCommitteeStake.add(memberStake);
			if (certification[i]) {
				totalCertifiedStake = totalCertifiedStake.add(memberStake);
			}

			(bool valid, uint256 expiration) = getVoteUnreadyVote(member, subject);
			if (valid) {
				totalVoteUnreadyStake = totalVoteUnreadyStake.add(memberStake);
				if (certification[i]) {
					totalCertifiedVoteUnreadyStake = totalCertifiedVoteUnreadyStake.add(memberStake);
				}
			} else if (expiration != 0) {
				// Vote is stale, delete from state
				delete voteUnreadyVotes[member][subject];
			}
		}

		return (
			totalCommitteeStake > 0 &&
			totalVoteUnreadyStake.mul(PERCENT_MILLIE_BASE) >= uint256(_settings.voteUnreadyPercentMilleThreshold).mul(totalCommitteeStake)
		) || (
			isSubjectCertified &&
			totalCertifiedStake > 0 &&
			totalCertifiedVoteUnreadyStake.mul(PERCENT_MILLIE_BASE) >= uint256(_settings.voteUnreadyPercentMilleThreshold).mul(totalCertifiedStake)
		);
	}

	function clearCommitteeUnreadyVotes(address[] memory committee, address subject) private {
		for (uint i = 0; i < committee.length; i++) {
			voteUnreadyVotes[committee[i]][subject] = 0; // clear vote-outs
		}
	}

	// Vote-out

	function applyStakesToVoteOutBy(address voter, uint256 currentVoterStake, uint256 totalGovernanceStake, Settings memory _settings) private {
		address subject = voteOutVotes[voter];
		if (subject == address(0)) return;

		uint256 prevVoterStake = votersStake[voter];
		votersStake[voter] = currentVoterStake;

		applyVoteOutVotesFor(subject, currentVoterStake, prevVoterStake, totalGovernanceStake, _settings);
	}

    function applyVoteOutVotesFor(address subject, uint256 voteOutStakeAdded, uint256 voteOutStakeRemoved, uint256 totalGovernanceStake, Settings memory _settings) private {
		if (isVotedOut(subject)) {
			return;
		}

		uint256 accumulated = accumulatedStakesForVoteOut[subject].
			sub(voteOutStakeRemoved).
			add(voteOutStakeAdded);

		bool shouldBeVotedOut = totalGovernanceStake > 0 && accumulated.mul(PERCENT_MILLIE_BASE) >= uint256(_settings.voteOutPercentMilleThreshold).mul(totalGovernanceStake);
		if (shouldBeVotedOut) {
			votedOutGuardians[subject] = true;
			emit GuardianVotedOut(subject);

			emit GuardianStatusUpdated(subject, false, false);
			committeeContract.removeMember(subject);
		}

		accumulatedStakesForVoteOut[subject] = accumulated;
	}

	function isVotedOut(address guardian) private view returns (bool) {
		return votedOutGuardians[guardian];
	}

	/*
     * Contracts topology / registry interface
     */

	ICommittee committeeContract;
	IDelegations delegationsContract;
	IGuardiansRegistration guardianRegistrationContract;
	ICertification certificationContract;
	function refreshContracts() external override {
		committeeContract = ICommittee(getCommitteeContract());
		delegationsContract = IDelegations(getDelegationsContract());
		guardianRegistrationContract = IGuardiansRegistration(getGuardiansRegistrationContract());
		certificationContract = ICertification(getCertificationContract());
	}

}
