/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


struct Collaborator {
	uint256 mgp;
	uint256 timeMgpApproved;
	uint256 timeMgpPaid;
	uint256 timeBonusPaid;
	uint256 bonusScore;
}

// 
library CollaboratorLibrary {

	event AddedCollaborator(
		bytes32 indexed projectId, bytes32 indexed packageId, address indexed collaborator, uint256 mgp
	);
	event ApprovedCollaborator(bytes32 indexed projectId, bytes32 indexed packageId, address indexed collaborator);
	event RemovedCollaborator(bytes32 indexed projectId, bytes32 indexed packageId, address indexed collaborator);

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
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address  
	* @param mgp_ minmal garanteed payment
	*/
	function addCollaborator(
		Collaborator storage collaborator_,
		bytes32 projectId_,
		bytes32 packageId_,
		address collaboratorAddress_,
		uint256 mgp_
	)
		public
	{
		require(collaborator_.mgp == 0, "collaborator already added");
		require(collaboratorAddress_ != address(0), "collaborator's address is zero");
		collaborator_.mgp = mgp_;
		emit AddedCollaborator(projectId_, packageId_, collaboratorAddress_, mgp_);
	}

	/**
	* @dev Approves collaborator's MPG or deletes collaborator 
	* @param collaborator_ reference to Collaborator struct
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address 
	* @param approve_ whether to approve or not collaborator payment  
	*/
	function approveCollaborator(
		Collaborator storage collaborator_,
		bytes32 projectId_,
		bytes32 packageId_,
		address collaboratorAddress_,
		bool approve_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.timeMgpApproved == 0, "already approved collaborator mgp");
		if(approve_){
			collaborator_.timeMgpApproved = block.timestamp;
			emit ApprovedCollaborator(projectId_, packageId_, collaboratorAddress_);
		}else{
			emit RemovedCollaborator(projectId_, packageId_, collaboratorAddress_);
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
		collaborator_.bonusScore = bonusScore_;
	}

	/**
	* @dev Sets MGP time paid flag, checks if approved and already paid
	* @param collaborator_ reference to Collaborator struct
	*/
	function getMgp(
		Collaborator storage collaborator_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.timeMgpApproved != 0, "mgp is not approved");
		require(collaborator_.timeMgpPaid == 0, "mgp already paid");
		collaborator_.timeMgpPaid = block.timestamp;
	}

	/**
	* @dev Sets Bonus time paid flag, checks is approved and already paid
	* @param collaborator_ reference to Collaborator struct
	*/
	function getBonus(
		Collaborator storage collaborator_
	)
		public
		onlyExistingCollaborator(collaborator_)
	{
		require(collaborator_.timeBonusPaid == 0, "bonus already paid");
		collaborator_.timeBonusPaid = block.timestamp;
	}

}