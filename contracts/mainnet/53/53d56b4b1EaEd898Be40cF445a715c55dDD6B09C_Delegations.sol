// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./SafeMath96.sol";
import "./IElections.sol";
import "./IDelegation.sol";
import "./IStakeChangeNotifier.sol";
import "./IStakingContractHandler.sol";
import "./IStakingRewards.sol";
import "./ManagedContract.sol";

contract Delegations is IDelegations, IStakeChangeNotifier, ManagedContract {
	using SafeMath for uint256;
	using SafeMath96 for uint96;

	address constant public VOID_ADDR = address(-1);

	struct StakeOwnerData {
		address delegation;
		uint96 stake;
	}
	mapping(address => StakeOwnerData) public stakeOwnersData;
	mapping(address => uint256) public uncappedDelegatedStake;

	uint256 totalDelegatedStake;

	struct DelegateStatus {
		address addr;
		uint256 uncappedDelegatedStake;
		bool isSelfDelegating;
		uint256 delegatedStake;
		uint96 selfDelegatedStake;
	}

	constructor(IContractRegistry _contractRegistry, address _registryAdmin) ManagedContract(_contractRegistry, _registryAdmin) public {
		address VOID_ADDRESS_DUMMY_DELEGATION = address(-2);
		assert(VOID_ADDR != VOID_ADDRESS_DUMMY_DELEGATION && VOID_ADDR != address(0) && VOID_ADDRESS_DUMMY_DELEGATION != address(0));
		stakeOwnersData[VOID_ADDR].delegation = VOID_ADDRESS_DUMMY_DELEGATION;
	}

	modifier onlyStakingContractHandler() {
		require(msg.sender == address(stakingContractHandler), "caller is not the staking contract handler");

		_;
	}

	/*
	* External functions
	*/

	function delegate(address to) external override onlyWhenActive {
		delegateFrom(msg.sender, to);
	}

	function getDelegation(address addr) external override view returns (address) {
		return getStakeOwnerData(addr).delegation;
	}

	function getDelegationInfo(address addr) external override view returns (address delegation, uint256 delegatorStake) {
		StakeOwnerData memory data = getStakeOwnerData(addr);
		return (data.delegation, data.stake);
	}

	function getDelegatedStake(address addr) external override view returns (uint256) {
		return getDelegateStatus(addr).delegatedStake;
	}

	function getTotalDelegatedStake() external override view returns (uint256) {
		return totalDelegatedStake;
	}

	function refreshStake(address addr) external override onlyWhenActive {
		_stakeChange(addr, stakingContractHandler.getStakeBalanceOf(addr));
	}

	/*
	* Notifications from staking contract
	*/

	function stakeChange(address _stakeOwner, uint256, bool, uint256 _updatedStake) external override onlyStakingContractHandler onlyWhenActive {
		_stakeChange(_stakeOwner, _updatedStake);
	}

	function stakeChangeBatch(address[] calldata _stakeOwners, uint256[] calldata _amounts, bool[] calldata _signs, uint256[] calldata _updatedStakes) external override onlyStakingContractHandler onlyWhenActive {
		uint batchLength = _stakeOwners.length;
		require(batchLength == _amounts.length, "_stakeOwners, _amounts - array length mismatch");
		require(batchLength == _signs.length, "_stakeOwners, _signs - array length mismatch");
		require(batchLength == _updatedStakes.length, "_stakeOwners, _updatedStakes - array length mismatch");

		for (uint i = 0; i < _stakeOwners.length; i++) {
			_stakeChange(_stakeOwners[i], _updatedStakes[i]);
		}
	}

	function stakeMigration(address _stakeOwner, uint256 _amount) external override onlyStakingContractHandler onlyWhenActive {}

	/*
	* Governance functions
	*/

	function importDelegations(address[] calldata from, address to) external override onlyInitializationAdmin {
		require(to != address(0), "to must be a non zero address");
		require(from.length > 0, "from array must contain at least one address");
		(uint96 stakingRewardsPerWeight, ) = stakingRewardsContract.getStakingRewardsState();
		require(stakingRewardsPerWeight == 0, "no rewards may be allocated prior to importing delegations");

		uint256 uncappedDelegatedStakeDelta = 0;
		StakeOwnerData memory data;
		uint256 newTotalDelegatedStake = totalDelegatedStake;
		DelegateStatus memory delegateStatus = getDelegateStatus(to);
		IStakingContractHandler _stakingContractHandler = stakingContractHandler;
		uint256 delegatorUncapped;
		uint256[] memory delegatorsStakes = new uint256[](from.length);
		for (uint i = 0; i < from.length; i++) {
			data = stakeOwnersData[from[i]];
			require(data.delegation == address(0), "import allowed only for uninitialized accounts. existing delegation detected");
			require(from[i] != to, "import cannot be used for self-delegation (already self delegated)");
			require(data.stake == 0 , "import allowed only for uninitialized accounts. existing stake detected");

			// from[i] stops being self delegating. any uncappedDelegatedStake it has now stops being counted towards totalDelegatedStake
			delegatorUncapped = uncappedDelegatedStake[from[i]];
			if (delegatorUncapped > 0) {
				newTotalDelegatedStake = newTotalDelegatedStake.sub(delegatorUncapped);
				emit DelegatedStakeChanged(
					from[i],
					0,
					0,
					from[i],
					0
				);
			}

			// update state
			data.delegation = to;
			data.stake = uint96(_stakingContractHandler.getStakeBalanceOf(from[i]));
			stakeOwnersData[from[i]] = data;

			uncappedDelegatedStakeDelta = uncappedDelegatedStakeDelta.add(data.stake);

			// store individual stake for event
			delegatorsStakes[i] = data.stake;

			emit Delegated(from[i], to);

			emit DelegatedStakeChanged(
				to,
				delegateStatus.selfDelegatedStake,
				delegateStatus.isSelfDelegating ? delegateStatus.delegatedStake.add(uncappedDelegatedStakeDelta) : 0,
				from[i],
				data.stake
			);
		}

		// update totals
		uncappedDelegatedStake[to] = uncappedDelegatedStake[to].add(uncappedDelegatedStakeDelta);

		if (delegateStatus.isSelfDelegating) {
			newTotalDelegatedStake = newTotalDelegatedStake.add(uncappedDelegatedStakeDelta);
		}
		totalDelegatedStake = newTotalDelegatedStake;

		// emit events
		emit DelegationsImported(from, to);
	}

	function initDelegation(address from, address to) external override onlyInitializationAdmin {
		delegateFrom(from, to);
		emit DelegationInitialized(from, to);
	}

	/*
	* Private functions
	*/

	function getDelegateStatus(address addr) private view returns (DelegateStatus memory status) {
		StakeOwnerData memory data = getStakeOwnerData(addr);

		status.addr = addr;
		status.uncappedDelegatedStake = uncappedDelegatedStake[addr];
		status.isSelfDelegating = data.delegation == addr;
		status.selfDelegatedStake = status.isSelfDelegating ? data.stake : 0;
		status.delegatedStake = status.isSelfDelegating ? status.uncappedDelegatedStake : 0;

		return status;
	}

	function getStakeOwnerData(address addr) private view returns (StakeOwnerData memory data) {
		data = stakeOwnersData[addr];
		data.delegation = (data.delegation == address(0)) ? addr : data.delegation;
		return data;
	}

	struct DelegateFromVars {
		DelegateStatus prevDelegateStatusBefore;
		DelegateStatus newDelegateStatusBefore;
		DelegateStatus prevDelegateStatusAfter;
		DelegateStatus newDelegateStatusAfter;
	}

	function delegateFrom(address from, address to) private {
		require(to != address(0), "cannot delegate to a zero address");

		DelegateFromVars memory vars;

		StakeOwnerData memory delegatorData = getStakeOwnerData(from);

		// Optimization - no need for the full flow in the case of a zero staked delegator with no delegations
		if (delegatorData.stake == 0 && uncappedDelegatedStake[from] == 0) {
			stakeOwnersData[from].delegation = to;
			emit Delegated(from, to);
			return;
		}

		address prevDelegate = delegatorData.delegation;

		vars.prevDelegateStatusBefore = getDelegateStatus(prevDelegate);
		vars.newDelegateStatusBefore = getDelegateStatus(to);

		stakingRewardsContract.delegationWillChange(prevDelegate, vars.prevDelegateStatusBefore.delegatedStake, from, delegatorData.stake, to, vars.newDelegateStatusBefore.delegatedStake);

		stakeOwnersData[from].delegation = to;

		uint256 delegatorStake = delegatorData.stake;

		uncappedDelegatedStake[prevDelegate] = vars.prevDelegateStatusBefore.uncappedDelegatedStake.sub(delegatorStake);
		uncappedDelegatedStake[to] = vars.newDelegateStatusBefore.uncappedDelegatedStake.add(delegatorStake);

		vars.prevDelegateStatusAfter = getDelegateStatus(prevDelegate);
		vars.newDelegateStatusAfter = getDelegateStatus(to);

		uint256 _totalDelegatedStake = totalDelegatedStake.sub(
			vars.prevDelegateStatusBefore.delegatedStake
		).add(
			vars.prevDelegateStatusAfter.delegatedStake
		).sub(
			vars.newDelegateStatusBefore.delegatedStake
		).add(
			vars.newDelegateStatusAfter.delegatedStake
		);

		totalDelegatedStake = _totalDelegatedStake;

		emit Delegated(from, to);

		IElections _electionsContract = electionsContract;

		if (vars.prevDelegateStatusBefore.delegatedStake != vars.prevDelegateStatusAfter.delegatedStake) {
			_electionsContract.delegatedStakeChange(
				prevDelegate,
				vars.prevDelegateStatusAfter.selfDelegatedStake,
				vars.prevDelegateStatusAfter.delegatedStake,
				_totalDelegatedStake
			);

			emit DelegatedStakeChanged(
				prevDelegate,
				vars.prevDelegateStatusAfter.selfDelegatedStake,
				vars.prevDelegateStatusAfter.delegatedStake,
				from,
				0
			);
		}

		if (vars.newDelegateStatusBefore.delegatedStake != vars.newDelegateStatusAfter.delegatedStake) {
			_electionsContract.delegatedStakeChange(
				to,
				vars.newDelegateStatusAfter.selfDelegatedStake,
				vars.newDelegateStatusAfter.delegatedStake,
				_totalDelegatedStake
			);

			emit DelegatedStakeChanged(
				to,
				vars.newDelegateStatusAfter.selfDelegatedStake,
				vars.newDelegateStatusAfter.delegatedStake,
				from,
				delegatorStake
			);
		}
	}

	function _stakeChange(address _stakeOwner, uint256 _updatedStake) private {
		StakeOwnerData memory stakeOwnerDataBefore = getStakeOwnerData(_stakeOwner);
		DelegateStatus memory delegateStatusBefore = getDelegateStatus(stakeOwnerDataBefore.delegation);

		uint256 prevUncappedStake = delegateStatusBefore.uncappedDelegatedStake;
		uint256 newUncappedStake = prevUncappedStake.sub(stakeOwnerDataBefore.stake).add(_updatedStake);

		stakingRewardsContract.delegationWillChange(stakeOwnerDataBefore.delegation, delegateStatusBefore.delegatedStake, _stakeOwner, stakeOwnerDataBefore.stake, stakeOwnerDataBefore.delegation, delegateStatusBefore.delegatedStake);

		uncappedDelegatedStake[stakeOwnerDataBefore.delegation] = newUncappedStake;

		require(uint256(uint96(_updatedStake)) == _updatedStake, "Delegations::updatedStakes value too big (>96 bits)");
		stakeOwnersData[_stakeOwner].stake = uint96(_updatedStake);

		uint256 _totalDelegatedStake = totalDelegatedStake;
		if (delegateStatusBefore.isSelfDelegating) {
			_totalDelegatedStake = _totalDelegatedStake.sub(stakeOwnerDataBefore.stake).add(_updatedStake);
			totalDelegatedStake = _totalDelegatedStake;
		}

		DelegateStatus memory delegateStatusAfter = getDelegateStatus(stakeOwnerDataBefore.delegation);

		electionsContract.delegatedStakeChange(
			stakeOwnerDataBefore.delegation,
			delegateStatusAfter.selfDelegatedStake,
			delegateStatusAfter.delegatedStake,
			_totalDelegatedStake
		);

		if (_updatedStake != stakeOwnerDataBefore.stake) {
			emit DelegatedStakeChanged(
				stakeOwnerDataBefore.delegation,
				delegateStatusAfter.selfDelegatedStake,
				delegateStatusAfter.delegatedStake,
				_stakeOwner,
				_updatedStake
			);
		}
	}

	/*
     * Contracts topology / registry interface
     */

	IElections electionsContract;
	IStakingRewards stakingRewardsContract;
	IStakingContractHandler stakingContractHandler;
	function refreshContracts() external override {
		electionsContract = IElections(getElectionsContract());
		stakingContractHandler = IStakingContractHandler(getStakingContractHandler());
		stakingRewardsContract = IStakingRewards(getStakingRewardsContract());
	}

}
