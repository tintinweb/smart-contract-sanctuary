/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


struct Package {
	uint256 budget;
	uint256 budgetAllocated;
	uint256 budgetPaid;
	uint256 bonus;
	uint256 bonusAllocated;
	uint256 bonusPaid;
	uint256 timeCreated;
	uint256 timeFinished;
	uint256 totalCollaborators;
	uint256 approvedCollaborators;
}

// 
library PackageLibrary {

	event CreatedPackage(bytes32 indexed projectId, bytes32 indexed packageId, uint256 budget, uint256 bonus);
	event FinishedPackage(bytes32 indexed projectId, bytes32 indexed packageId);

	/**
	@dev Throws if there is no package
	 */
	modifier onlyExistingPackage(Package storage package_) {
		require(package_.timeCreated != 0, "no such package");
		_;
	}

	/**
	* @dev Creates package in project
	* @param package_ reference to Package struct
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param budget_ MGP budget 
	* @param bonus_ Bonus budget 
	*/
	function _createPackage(
		Package storage package_,
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 budget_,
		uint256 bonus_
	)
		public
	{
		package_.budget = budget_;
		package_.bonus = bonus_;
		package_.timeCreated = block.timestamp;
		emit CreatedPackage(projectId_, packageId_, budget_, bonus_);
	}

	/**
	* @dev Adds collaborator to package, checks if there is budget available and allocates it  
	* @param package_ reference to Package struct
	* @param mgp_ minmal garanteed payment
	*/
	function addCollaborator(
		Package storage package_,
		uint256 mgp_
	)
		public
		onlyExistingPackage(package_)
	{
		require(package_.timeFinished == 0, "already finished package");
		require(
			package_.budget - package_.budgetAllocated >= mgp_, 
			"not enough package budget left"
		);
		package_.budgetAllocated += mgp_;
		package_.totalCollaborators++;
	}

	/**
	* @dev Refund package budget and decreace total collaborators if not approved
	* @param package_ reference to Package struct
	* @param approve_ whether to approve or not collaborator payment 
	* @param mgp_ MGP amount
	*/
	function approveCollaborator(
		Package storage package_,
		bool approve_,
		uint256 mgp_
	)
		public
		onlyExistingPackage(package_)
	{
		if(!approve_){
			package_.budgetAllocated -= mgp_;
			package_.totalCollaborators--;
		}else{
			package_.approvedCollaborators++;
		}
	}

	/**
	* @dev Fihishes package in project, checks if already finished, records time
	* if budget left and there is no collaborators, bonus is refunded to package budget
	* @param package_ reference to Package struct
	* @param projectId_ Id of the project 
	*/
	function finishPackage(
		Package storage package_,
		bytes32 projectId_,
		bytes32 packageId_
	)
		public
		onlyExistingPackage(package_)
		returns(uint256 budgetLeft_)
	{
		require(package_.timeFinished == 0, "already finished package");
		require(package_.totalCollaborators == package_.approvedCollaborators, "unapproved collaborators left");
		budgetLeft_ = package_.budget - package_.budgetAllocated;
		if(budgetLeft_ != 0)
			package_.budget = package_.budgetAllocated;
		if(package_.totalCollaborators == 0){
			budgetLeft_ += package_.bonus;
			package_.bonus = 0;
		}
		package_.timeFinished = block.timestamp;
		emit FinishedPackage(projectId_, packageId_);
	}

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param package_ reference to Package struct
	* @param package_ reference to Package struct
	* @param totalBonusScores_ total sum of bonus scores
	* @param maxBonusScores_ max bonus scores (PPM)
	*/
	function _setBonusScores(
		Package storage package_,
		uint256 totalBonusScores_,
		uint256 maxBonusScores_
	)
		public
		onlyExistingPackage(package_)
	{
		require(package_.bonus != 0, "bonus budget is zero");
		require(package_.timeFinished != 0, "package is not finished");
		require(package_.bonusAllocated + totalBonusScores_ <= maxBonusScores_, "no more bonus left");
		package_.bonusAllocated += totalBonusScores_;
	}

	/**
	* @dev Increases package budget paid
	* @param package_ reference to Package struct
	* @param amount_ MGP amount
	*/
	function _getMgp(
		Package storage package_,
		uint256 amount_
	)
		public
		onlyExistingPackage(package_)
	{	
		package_.budgetPaid += amount_;
	}

	/**
	* @dev Increases package bonus paid
	* @param package_ reference to Package struct
	* @param amount_ Bonus amount
	*/
	function _getBonus(
		Package storage package_,
		uint256 amount_
	)
		public
		onlyExistingPackage(package_)
	{
		require(package_.timeFinished != 0, "package not finished");
		require(package_.bonus != 0, "package has no bonus");
		package_.bonusPaid += amount_;
	}

}