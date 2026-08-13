/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-09
*/

pragma solidity 0.8.13;

// SPDX-License-Identifier: GPL-3.0-only

/**
 * @author The Moonbeam Team
 * @title The interface through which solidity contracts will interact with Parachain Staking
 * We follow this same interface including four-byte function selectors, in the precompile that
 * wraps the pallet
 * Address :    0x0000000000000000000000000000000000000800
 */

interface ParachainStaking {
    /// DEPRECATED, replaced by is_delegator
    /// @dev Check whether the specified address is currently a staking nominator
    /// Selector: 8e5080e7
    /// @param nominator the address that we want to confirm is a nominator
    /// @return A boolean confirming whether the address is a nominator
    function is_nominator(address nominator) external view returns (bool);

    /// @dev Check whether the specified address is currently a staking delegator
    /// Selector: 1f030587
    /// @param delegator the address that we want to confirm is a delegator
    /// @return A boolean confirming whether the address is a delegator
    function is_delegator(address delegator) external view returns (bool);

    /// @dev Check whether the specified address is currently a collator candidate
    /// Selector: 8545c833
    /// @param candidate the address that we want to confirm is a collator andidate
    /// @return A boolean confirming whether the address is a collator candidate
    function is_candidate(address candidate) external view returns (bool);

    /// @dev Check whether the specifies address is currently a part of the active set
    /// Selector: 8f6d27c7
    /// @param candidate the address that we want to confirm is a part of the active set
    /// @return A boolean confirming whether the address is a part of the active set
    function is_selected_candidate(address candidate)
        external
        view
        returns (bool);

    /// @dev Total points awarded to all collators in a particular round
    /// Selector: 9799b4e7
    /// @param round the round for which we are querying the points total
    /// @return The total points awarded to all collators in the round
    function points(uint256 round) external view returns (uint256);

    /// DEPRECATED, replaced by min_delegation
    /// @dev Get the minimum nomination amount
    /// Selector: c9f593b2
    /// @return The minimum nomination amount
    function min_nomination() external view returns (uint256);

    /// @dev Get the minimum delegation amount
    /// Selector: 72ce8933
    /// @return The minimum delegation amount
    function min_delegation() external view returns (uint256);

    /// @dev Get the CandidateCount weight hint
    /// Selector: 4b1c4c29
    /// @return The CandidateCount weight hint
    function candidate_count() external view returns (uint256);

    /// DEPRECATED, replaced by candidate_delegation_count
    /// @dev Get the CollatorNominationCount weight hint
    /// Selector: 0ad6a7be
    /// @param collator The address for which we are querying the nomination count
    /// @return The number of nominations backing the collator
    function collator_nomination_count(address collator)
        external
        view
        returns (uint256);

    /// @dev Get the CandidateDelegationCount weight hint
    /// Selector: 815b796c
    /// @param candidate The address for which we are querying the nomination count
    /// @return The number of nominations backing the collator
    function candidate_delegation_count(address candidate)
        external
        view
        returns (uint256);

    /// DEPRECATED, replaced by delegator_delegation_count
    /// @dev Get the NominatorNominationCount weight hint
    /// Selector: dae5659b
    /// @param nominator The address for which we are querying the nomination count
    /// @return The number of nominations made by the nominator
    function nominator_nomination_count(address nominator)
        external
        view
        returns (uint256);

    /// @dev Get the DelegatorDelegationCount weight hint
    /// Selector: fbc51bca
    /// @param delegator The address for which we are querying the delegation count
    /// @return The number of delegations made by the delegator
    function delegator_delegation_count(address delegator)
        external
        view
        returns (uint256);

    /// @dev Get the selected candidates for the current round
    /// Selector: 0x89f47a21
    /// @return The selected candidate accounts
    function selected_candidates() external view returns (address[] memory);

    /// @dev Whether there exists a pending request for a delegation made by a delegator
    /// Selector: 192e1db3
    /// @param delegator the delegator that made the delegation
    /// @param candidate the candidate for which the delegation was made
    /// @return Whether a pending request exists for such delegation
    function delegation_request_is_pending(address delegator, address candidate)
        external
        view
        returns (bool);

    /// @dev Whether there exists a pending exit for delegator
    /// Selector: dc3ec64b
    /// @param delegator the delegator that made the exit request
    /// @return Whether a pending exit exists for delegator
    function delegator_exit_is_pending(address delegator)
        external
        view
        returns (bool);

    /// @dev Whether there exists a pending exit for candidate
    /// Selector: eb613b8a
    /// @param candidate the candidate for which the exit request was made
    /// @return Whether a pending request exists for such delegation
    function candidate_exit_is_pending(address candidate)
        external
        view
        returns (bool);

    /// @dev Whether there exists a pending bond less request made by a candidate
    /// Selector: 26ab05fb
    /// @param candidate the candidate which made the request
    /// @return Whether a pending bond less request was made by the candidate
    function candidate_request_is_pending(address candidate)
        external
        view
        returns (bool);

    /// @dev Join the set of collator candidates
    /// Selector: 0a1bff60
    /// @param amount The amount self-bonded by the caller to become a collator candidate
    /// @param candidateCount The number of candidates in the CandidatePool
    function join_candidates(uint256 amount, uint256 candidateCount) external;

    /// DEPRECATED, replaced by schedule_leave_candidates, execute_leave_candidates,
    /// cancel_leave_candidates
    /// @dev Leave the set of collator candidates
    /// Selector: 72b02a31
    /// @param candidateCount The number of candidates in the CandidatePool
    function leave_candidates(uint256 candidateCount) external;

    /// @dev Request to leave the set of collator candidates
    /// Selector: 60afbac6
    /// @param candidateCount The number of candidates in the CandidatePool
    function schedule_leave_candidates(uint256 candidateCount) external;

    /// @dev Execute due request to leave the set of collator candidates
    /// Selector: 3fdc4c30
    /// @param candidate The candidate address for which the pending exit request will be executed
    /// @param candidateDelegationCount The number of delegations for the candidate to be revoked
    function execute_leave_candidates(
        address candidate,
        uint256 candidateDelegationCount
    ) external;

    /// @dev Cancel request to leave the set of collator candidates
    /// Selector: 0880b3e2
    /// @param candidateCount The number of candidates in the CandidatePool
    function cancel_leave_candidates(uint256 candidateCount) external;

    /// @dev Temporarily leave the set of collator candidates without unbonding
    /// Selector: 767e0450
    function go_offline() external;

    /// @dev Rejoin the set of collator candidates if previously had called `go_offline`
    /// Selector: d2f73ceb
    function go_online() external;

    /// @dev Request to bond more for collator candidates
    /// Selector: c57bd3a8
    /// @param more The additional amount self-bonded
    function candidate_bond_more(uint256 more) external;

    /// DEPRECATED, replaced by schedule_candidate_bond_less, execute_candidate_bond_request,
    /// cancel_candidate_bond_request
    /// @dev Request to bond less for collator candidates
    /// Selector: 289b6ba7
    /// @param less The amount to be subtracted from self-bond and unreserved
    function candidate_bond_less(uint256 less) external;

    /// @dev Request to bond less for collator candidates
    /// Selector: 034c47bc
    /// @param less The amount to be subtracted from self-bond and unreserved
    function schedule_candidate_bond_less(uint256 less) external;

    /// @dev Execute pending candidate bond request
    /// Selector: a9a2b8b7
    /// @param candidate The address for the candidate for which the request will be executed
    function execute_candidate_bond_less(address candidate) external;

    /// @dev Cancel pending candidate bond request
    /// Selector: 583d0fdc
    function cancel_candidate_bond_less() external;

    /// DEPRECATED, replaced by delegate
    /// @dev Make a nomination in support of a collator candidate
    /// Selector: 49df6eb3
    /// @param collator The address of the supported collator candidate
    /// @param amount The amount bonded in support of the collator candidate
    /// @param collatorNominationCount The number of nominations in support of the candidate
    /// @param nominatorNominationCount The number of existing nominations by the caller
    function nominate(
        address collator,
        uint256 amount,
        uint256 collatorNominationCount,
        uint256 nominatorNominationCount
    ) external;

    /// @dev Make a delegation in support of a collator candidate
    /// Selector: 829f5ee3
    /// @param candidate The address of the supported collator candidate
    /// @param amount The amount bonded in support of the collator candidate
    /// @param candidateDelegationCount The number of delegations in support of the candidate
    /// @param delegatorDelegationCount The number of existing delegations by the caller
    function delegate(
        address candidate,
        uint256 amount,
        uint256 candidateDelegationCount,
        uint256 delegatorDelegationCount
    ) external;

    /// DEPRECATED, replaced by schedule_leave_delegators, execute_leave_delegators,
    /// cancel_leave_delegators
    /// @dev Request to leave the set of nominators
    /// Selector: b71d2153
    /// @param nominatorNominationCount The number of active nominations to be revoked by caller
    function leave_nominators(uint256 nominatorNominationCount) external;

    /// @dev Request to leave the set of delegators
    /// Selector: 65a5bbd0
    function schedule_leave_delegators() external;

    /// @dev Execute request to leave the set of delegators and revoke all delegations
    /// Selector: a84a7468
    /// @param delegator The leaving delegator
    /// @param delegatorDelegationCount The number of active delegations to be revoked by delegator
    function execute_leave_delegators(
        address delegator,
        uint256 delegatorDelegationCount
    ) external;

    /// @dev Cancel request to leave the set of delegators
    /// Selector: 2a987643
    function cancel_leave_delegators() external;

    /// DEPRECATED, replaced by schedule_revoke_delegation, execute_delegation_request,
    /// cancel_delegation_request
    /// @dev Request to revoke an existing nomination
    /// Selector: 4b65c34b
    /// @param collator The address of the collator candidate which will no longer be supported
    function revoke_nomination(address collator) external;

    /// @dev Request to revoke an existing delegation
    /// Selector: 22266e75
    /// @param candidate The address of the collator candidate which will no longer be supported
    function schedule_revoke_delegation(address candidate) external;

    /// DEPRECATED, replaced by delegator_bond_more
    /// @dev Request to bond more for nominators with respect to a specific collator candidate
    /// Selector: 971d44c8
    /// @param candidate The address of the collator candidate for which nomination is increased
    /// @param more The amount by which the nomination is increased
    function nominator_bond_more(address candidate, uint256 more) external;

    /// @dev Bond more for delegators with respect to a specific collator candidate
    /// Selector: f8331108
    /// @param candidate The address of the collator candidate for which delegation shall increase
    /// @param more The amount by which the delegation is increased
    function delegator_bond_more(address candidate, uint256 more) external;

    /// DEPRECATED, replaced by schedule_delegator_bond_less, execute_delegation_request,
    /// cancel_delegation_request
    /// @dev Request to bond less for nominators with respect to a specific collator candidate
    /// Selector: f6a52569
    /// @param candidate The address of the collator candidate for which nomination is decreased
    /// @param less The amount by which the nomination is decreased
    function nominator_bond_less(address candidate, uint256 less) external;

    /// @dev Request to bond less for delegators with respect to a specific collator candidate
    /// Selector: 00043acf
    /// @param candidate The address of the collator candidate for which delegation shall decrease
    /// @param less The amount by which the delegation is decreased (upon execution)
    function schedule_delegator_bond_less(address candidate, uint256 less)
        external;

    /// @dev Execute pending delegation request (if exists && is due)
    /// Selector: e42366a6
    /// @param delegator The address of the delegator
    /// @param candidate The address of the candidate
    function execute_delegation_request(address delegator, address candidate)
        external;

    /// @dev Cancel pending delegation request (already made in support of input by caller)
    /// Selector: 7284cf50
    /// @param candidate The address of the candidate
    function cancel_delegation_request(address candidate) external;
}

contract DelegationDAO {

    address public constant STAKING_SC_ADDRESS = 0x0000000000000000000000000000000000000800;
    ParachainStaking public staking = ParachainStaking(STAKING_SC_ADDRESS);
    address public target = 0xb15F8D5c222C5998451f34882e3dA4Ad5C2B3165;
    address public owner = 0x747110477a6718b925F00140bFC832eb653e6102;

    modifier onlyOwner() {
        require(msg.sender == owner);
            _;
    }

    function changeOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }

    function changeTarget(address newCollator) onlyOwner external {
        target = newCollator;
    }

    function delegate(uint256 amount) onlyOwner external payable {
        staking.delegate(target, amount, staking.candidate_delegation_count(target), staking.delegator_delegation_count(address(this)));
    }

    function delegator_bond_more(uint256 more) onlyOwner external payable {
        staking.delegator_bond_more(target,more);
    }

    function delegate_all_funds() onlyOwner external payable {
        staking.delegator_bond_more(target,address(this).balance);
    }

    function schedule_delegator_bond_less(uint256 less) onlyOwner external {
        staking.schedule_delegator_bond_less(target,less);
    }

    function schedule_revoke_delegation() onlyOwner external {
        staking.schedule_revoke_delegation(target);
    }

    function execute_delegation_request() onlyOwner external {
        staking.execute_delegation_request(address(this),target);
    }

    function cancel_delegation_request() onlyOwner external {
        staking.cancel_delegation_request(target);
    }

    function withdraw() onlyOwner external {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}

}