// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./ICommittee.sol";
import "./ManagedContract.sol";
import "./IStakingRewards.sol";
import "./IFeesAndBootstrapRewards.sol";

contract Committee is ICommittee, ManagedContract {
	using SafeMath for uint256;
	using SafeMath for uint96;

	uint96 constant CERTIFICATION_MASK = 1 << 95;
	uint96 constant WEIGHT_MASK = ~CERTIFICATION_MASK;

	struct CommitteeMember {
		address addr;
		uint96 weightAndCertifiedBit;
	}
	CommitteeMember[] committee;

	struct MemberStatus {
		uint32 pos;
		bool inCommittee;
	}
	mapping(address => MemberStatus) public membersStatus;

	struct CommitteeStats {
		uint96 totalWeight;
		uint32 generalCommitteeSize;
		uint32 certifiedCommitteeSize;
	}
	CommitteeStats committeeStats;

	uint8 maxCommitteeSize;

	constructor(IContractRegistry _contractRegistry, address _registryAdmin, uint8 _maxCommitteeSize) ManagedContract(_contractRegistry, _registryAdmin) public {
		setMaxCommitteeSize(_maxCommitteeSize);
	}

	modifier onlyElectionsContract() {
		require(msg.sender == electionsContract, "caller is not the elections");

		_;
	}

	/*
	 * External functions
	 */

	function memberWeightChange(address addr, uint256 weight) external override onlyElectionsContract onlyWhenActive {
		MemberStatus memory status = membersStatus[addr];

		if (!status.inCommittee) {
			return;
		}
		CommitteeMember memory member = committee[status.pos];
		(uint prevWeight, bool isCertified) = getWeightCertification(member);

		committeeStats.totalWeight = uint96(committeeStats.totalWeight.sub(prevWeight).add(weight));

		committee[status.pos].weightAndCertifiedBit = packWeightCertification(weight, isCertified);
		emit CommitteeChange(addr, weight, isCertified, true);
	}

	function memberCertificationChange(address addr, bool isCertified) external override onlyElectionsContract onlyWhenActive {
		MemberStatus memory status = membersStatus[addr];

		if (!status.inCommittee) {
			return;
		}
		CommitteeMember memory member = committee[status.pos];
		(uint weight, bool prevCertification) = getWeightCertification(member);

		CommitteeStats memory _committeeStats = committeeStats;

		feesAndBootstrapRewardsContract.committeeMembershipWillChange(addr, true, prevCertification, isCertified, _committeeStats.generalCommitteeSize, _committeeStats.certifiedCommitteeSize);

		committeeStats.certifiedCommitteeSize = _committeeStats.certifiedCommitteeSize - (prevCertification ? 1 : 0) + (isCertified ? 1 : 0);

		committee[status.pos].weightAndCertifiedBit = packWeightCertification(weight, isCertified);
		emit CommitteeChange(addr, weight, isCertified, true);
	}

	function addMember(address addr, uint256 weight, bool isCertified) external override onlyElectionsContract onlyWhenActive returns (bool memberAdded) {
		MemberStatus memory status = membersStatus[addr];

		if (status.inCommittee) {
			return false;
		}

		(bool qualified, uint entryPos) = qualifiesToEnterCommittee(addr, weight, maxCommitteeSize);
		if (!qualified) {
			return false;
		}

		memberAdded = true;

		CommitteeStats memory _committeeStats = committeeStats;

		stakingRewardsContract.committeeMembershipWillChange(addr, weight, _committeeStats.totalWeight, false, true);
		feesAndBootstrapRewardsContract.committeeMembershipWillChange(addr, false, isCertified, isCertified, _committeeStats.generalCommitteeSize, _committeeStats.certifiedCommitteeSize);

		_committeeStats.generalCommitteeSize++;
		if (isCertified) _committeeStats.certifiedCommitteeSize++;
		_committeeStats.totalWeight = uint96(_committeeStats.totalWeight.add(weight));

		CommitteeMember memory newMember = CommitteeMember({
			addr: addr,
			weightAndCertifiedBit: packWeightCertification(weight, isCertified)
		});

		if (entryPos < committee.length) {
			CommitteeMember memory removed = committee[entryPos];
			unpackWeightCertification(removed.weightAndCertifiedBit);

			_committeeStats = removeMemberAtPos(entryPos, false, _committeeStats);
			committee[entryPos] = newMember;
		} else {
			committee.push(newMember);
		}

		status.inCommittee = true;
		status.pos = uint32(entryPos);
		membersStatus[addr] = status;

		committeeStats = _committeeStats;

		emit CommitteeChange(addr, weight, isCertified, true);
	}

	function checkAddMember(address addr, uint256 weight) external view override returns (bool wouldAddMember) {
		if (membersStatus[addr].inCommittee) {
			return false;
		}

		(bool qualified, ) = qualifiesToEnterCommittee(addr, weight, maxCommitteeSize);
		return qualified;
	}

	/// @dev Called by: Elections contract
	/// Notifies a a member removal for example due to voteOut / voteUnready
	function removeMember(address addr) external override onlyElectionsContract onlyWhenActive returns (bool memberRemoved, uint256 memberEffectiveStake, bool isCertified) {
		MemberStatus memory status = membersStatus[addr];
		if (!status.inCommittee) {
			return (false, 0, false);
		}

		memberRemoved = true;
		(memberEffectiveStake, isCertified) = getWeightCertification(committee[status.pos]);

		committeeStats = removeMemberAtPos(status.pos, true, committeeStats);
	}

	/// @dev Called by: Elections contract
	/// Returns the committee members and their weights
	function getCommittee() external override view returns (address[] memory addrs, uint256[] memory weights, bool[] memory certification) {
		return _getCommittee();
	}

	function emitCommitteeSnapshot() external override {
		(address[] memory addrs, uint256[] memory weights, bool[] memory certification) = _getCommittee();
		for (uint i = 0; i < addrs.length; i++) {
			emit CommitteeChange(addrs[i], weights[i], certification[i], true);
		}
		emit CommitteeSnapshot(addrs, weights, certification);
	}

	/*
	 * Governance functions
	 */

	function setMaxCommitteeSize(uint8 _maxCommitteeSize) public override onlyFunctionalManager {
		uint8 prevMaxCommitteeSize = maxCommitteeSize;
		maxCommitteeSize = _maxCommitteeSize;

		while (committee.length > _maxCommitteeSize) {
			(, ,uint pos) = _getMinCommitteeMember();
			committeeStats = removeMemberAtPos(pos, true, committeeStats);
		}

		emit MaxCommitteeSizeChanged(_maxCommitteeSize, prevMaxCommitteeSize);
	}

	function getMaxCommitteeSize() external override view returns (uint8) {
		return maxCommitteeSize;
	}

	function getCommitteeStats() external override view returns (uint generalCommitteeSize, uint certifiedCommitteeSize, uint totalWeight) {
		CommitteeStats memory _committeeStats = committeeStats;
		return (_committeeStats.generalCommitteeSize, _committeeStats.certifiedCommitteeSize, _committeeStats.totalWeight);
	}

	function getMemberInfo(address addr) external override view returns (bool inCommittee, uint weight, bool isCertified, uint totalCommitteeWeight) {
		MemberStatus memory status = membersStatus[addr];
		inCommittee = status.inCommittee;
		if (inCommittee) {
			(weight, isCertified) = getWeightCertification(committee[status.pos]);
		}
		totalCommitteeWeight = committeeStats.totalWeight;
	}

	/*
	 * Private
	 */

	function packWeightCertification(uint256 weight, bool certification) private pure returns (uint96 weightAndCertified) {
		return uint96(weight) | (certification ? CERTIFICATION_MASK : 0);
	}

	function unpackWeightCertification(uint96 weightAndCertifiedBit) private pure returns (uint256 weight, bool certification) {
		return (uint256(weightAndCertifiedBit & WEIGHT_MASK), weightAndCertifiedBit & CERTIFICATION_MASK != 0);
	}

	function getWeightCertification(CommitteeMember memory member) private pure returns (uint256 weight, bool certification) {
		return unpackWeightCertification(member.weightAndCertifiedBit);
	}

	function _getCommittee() private view returns (address[] memory addrs, uint256[] memory weights, bool[] memory certification) {
		CommitteeMember[] memory _committee = committee;
		addrs = new address[](_committee.length);
		weights = new uint[](_committee.length);
		certification = new bool[](_committee.length);

		for (uint i = 0; i < _committee.length; i++) {
			addrs[i] = _committee[i].addr;
			(weights[i], certification[i]) = getWeightCertification(_committee[i]);
		}
	}

	function _getMinCommitteeMember() private view returns (
		address minMemberAddress,
		uint256 minMemberWeight,
		uint minMemberPos
	){
		CommitteeMember[] memory _committee = committee;
		minMemberPos = uint256(-1);
		minMemberWeight = uint256(-1);
		uint256 memberWeight;
		address memberAddress;
		for (uint i = 0; i < _committee.length; i++) {
			memberAddress = _committee[i].addr;
			(memberWeight,) = getWeightCertification(_committee[i]);
			if (memberWeight < minMemberWeight || memberWeight == minMemberWeight && memberAddress < minMemberAddress) {
				minMemberPos = i;
				minMemberWeight = memberWeight;
				minMemberAddress = memberAddress;
			}
		}
	}

	function qualifiesToEnterCommittee(address addr, uint256 weight, uint8 _maxCommitteeSize) private view returns (bool qualified, uint entryPos) {
		uint committeeLength = committee.length;
		if (committeeLength < _maxCommitteeSize) {
			return (true, committeeLength);
		}

		(address minMemberAddress, uint256 minMemberWeight, uint minMemberPos) = _getMinCommitteeMember();

		if (weight > minMemberWeight || weight == minMemberWeight && addr > minMemberAddress) {
			return (true, minMemberPos);
		}

		return (false, 0);
	}

	function removeMemberAtPos(uint pos, bool clearFromList, CommitteeStats memory _committeeStats) private returns (CommitteeStats memory newCommitteeStats){
		CommitteeMember memory member = committee[pos];

		(uint weight, bool certification) = getWeightCertification(member);

		stakingRewardsContract.committeeMembershipWillChange(member.addr, weight, _committeeStats.totalWeight, true, false);
		feesAndBootstrapRewardsContract.committeeMembershipWillChange(member.addr, true, certification, certification, _committeeStats.generalCommitteeSize, _committeeStats.certifiedCommitteeSize);

		delete membersStatus[member.addr];

		_committeeStats.generalCommitteeSize--;
		if (certification) _committeeStats.certifiedCommitteeSize--;
		_committeeStats.totalWeight = uint96(_committeeStats.totalWeight.sub(weight));

		emit CommitteeChange(member.addr, weight, certification, false);

		if (clearFromList) {
			uint committeeLength = committee.length;
			if (pos < committeeLength - 1) {
				CommitteeMember memory last = committee[committeeLength - 1];
				committee[pos] = last;
				membersStatus[last.addr].pos = uint32(pos);
			}
			committee.pop();
		}

		return _committeeStats;
	}

	/*
     * Contracts topology / registry interface
     */

	address electionsContract;
	IStakingRewards stakingRewardsContract;
	IFeesAndBootstrapRewards feesAndBootstrapRewardsContract;
	function refreshContracts() external override {
		electionsContract = getElectionsContract();
		stakingRewardsContract = IStakingRewards(getStakingRewardsContract());
		feesAndBootstrapRewardsContract = IFeesAndBootstrapRewards(getFeesAndBootstrapRewardsContract());
	}

}
