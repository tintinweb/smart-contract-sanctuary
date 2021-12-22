// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Collaborator } from "./Structs.sol";

library CollaboratorLibrary {

	/**
	@dev Throws if there is no such collaborator
	*/
	modifier onlyExistingCollaborator(Collaborator storage collaborator_) {
		require(collaborator_.mgp != 0, "no such collaborator");
		_;
	}

	/**
	* @dev Adds collaborator, checks for zero address and if already added, records mgp 
	* @param collaborator_ reference to Collaborator struct
	* @param collaborator_ collaborator's address  
	* @param mgp_ minmal garanteed payment
	*/
	function _addCollaborator(
		Collaborator storage collaborator_,
		uint256 mgp_
	)
		public
	{
		require(collaborator_.mgp == 0, "collaborator already added");
		collaborator_.mgp = mgp_;
	}

	/**
	* @dev Approves collaborator's MPG or deletes collaborator 
	* @param collaborator_ reference to Collaborator struct
	* @param approve_ whether to approve or not collaborator payment  
	*/
	function _approveCollaborator(
		Collaborator storage collaborator_,
		bool approve_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.timeMgpApproved == 0, "already approved collaborator mgp");
		if(approve_){
			collaborator_.timeMgpApproved = block.timestamp;
		}
	}

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param collaborator_ reference to Collaborator struct
	* @param bonusScore_ collaborator's bonus score
	*/
	function _setBonusScore(
		Collaborator storage collaborator_,
		uint256 bonusScore_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.bonusScore == 0, "collaborator bonus score already set");
		collaborator_.bonusScore = bonusScore_;
	}

	/**
	* @dev Sets MGP time paid flag, checks if approved and already paid
	* @param collaborator_ reference to Collaborator struct
	*/
	function _getMgp(
		Collaborator storage collaborator_
	)
		public
		onlyExistingCollaborator(collaborator_)
		returns(uint256)
	{
		require(collaborator_.timeMgpApproved != 0, "mgp is not approved");
		require(collaborator_.timeMgpPaid == 0, "mgp already paid");
		collaborator_.timeMgpPaid = block.timestamp;
		return collaborator_.mgp;
	}

	/**
	* @dev Sets Bonus time paid flag, checks is approved and already paid
	* @param collaborator_ reference to Collaborator struct
	*/
	function _paidBonus(
		Collaborator storage collaborator_
	)
		internal
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.bonusScore != 0, "bonus score is zero");
		require(collaborator_.timeBonusPaid == 0, "bonus already paid");
		collaborator_.timeBonusPaid = block.timestamp;
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct Project {
	address initiator;
	address token;
	bool isOwnToken;
	uint256 budget;
	uint256 budgetAllocated;
	uint256 budgetPaid;
	uint256 timeCreated;
	uint256 timeApproved;
	uint256 timeStarted;
	uint256 timeFinished;
	uint256 totalPackages;
	uint256 totalFinishedPackages;
}

struct Package{
	uint256 budget;
	uint256 budgetAllocated;
	uint256 budgetPaid;
	uint256 budgetObservers;
	uint256 budgetObserversPaid;
	uint256 bonus;
	uint256 bonusAllocated;
	uint256 bonusPaid;
	uint256 timeCreated;
	uint256 timeFinished;
	uint256 totalObservers;
	uint256 totalCollaborators;
	uint256 approvedCollaborators;
}

struct Collaborator{
	uint256 mgp;
	uint256 timeMgpApproved;
	uint256 timeMgpPaid;
	uint256 timeBonusPaid;
	uint256 bonusScore;
}

struct Observer{
	uint256 timeCreated;
	uint256 timePaid;
}