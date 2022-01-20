// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { IReBakedDAO } from "./interfaces/IRebakedDAO.sol";
import { ITokenFactory } from "./interfaces/ITokenFactory.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Projects} from "./Projects.sol";

contract ReBakedDAO is IReBakedDAO, Ownable, ReentrancyGuard, Projects {

	using SafeERC20 for IERC20;

	// Rebaked DAO wallet
	address public treasury;
	// Percent Precision PPM (parts per million)
	uint256 constant public PCT_PRECISION = 1e6;
	// Fee for DAO for new projects
	uint256 public feeDao;
	// Fee for Observers for new projects
	uint256 public feeObservers;
	// Token Factory contract address
	address public tokenFactory;
    
	
	constructor (
		address treasury_,
		uint256 feeDao_,
		uint256 feeObservers_,
		address tokenFactory_
	)
	{
		treasury = treasury_;
		changeFees(feeDao_, feeObservers_);
		tokenFactory = tokenFactory_;
	}

	/**
	 * @dev Throws if amount provided is zero
	 */
	modifier nonZero(uint256 amount_) {
		require(amount_ != 0, "amount must be greater than 0");
		_;
	}

	/**
	 * @dev Throws if amount provided bytes32 array length is zero
	 */
	modifier noneEmptyBytesArray(bytes32[] memory array_) {
		require(array_.length != 0, "array length must be greater than 0");
		_;
	}

	/**
	 * @dev Throws if amount provided uint256 array length is zero
	 */
	modifier noneEmptyUintArray(uint256[] memory array_) {
		require(array_.length != 0, "array length must be greater than 0");
		_;
	}

	/**
	 * @dev Throws if called by any account other than the project initiator
	 */
	modifier onlyInitiator(bytes32 projectId_) {
		require(projectData[projectId_].initiator == msg.sender, "caller is not the project initiator");
		_;
	}

	/***************************************
					PRIVATE
	****************************************/
	/**
	* @dev Generates unique id hash based on msg.sender address and previous block hash. 
	* @param nonce_ nonce
	* @return Id
	*/
	function _generateId(uint256 nonce_)
		private
		view
		returns(bytes32)
	{
		return keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1), nonce_));
	}

	/**
	* @dev Returns a new unique project id. 
	* @return projectId_ Id of the project.
	*/
	function _generateProjectId()
		private
		view
		returns(bytes32 projectId_)
	{
		projectId_ = _generateId(0);
		require(projectData[projectId_].timeCreated == 0, "duplicate project id");
	}

	/**
	* @dev Returns a new unique package id. 
	* @param projectId_ Id of the project
	* @param nonce_ nonce
	* @return packageId_ Id of the package
	*/
	function _generatePackageId(bytes32 projectId_, uint256 nonce_)
		private
		view
		returns(bytes32 packageId_)
	{
		packageId_ = _generateId(nonce_);
		require(packageData[projectId_][packageId_].timeCreated == 0, "duplicate package id");
	}

	/**
	* @dev Starts project
	* @param projectId_ Id of the project
	*/
	function _startProject(
		bytes32 projectId_
	)
		internal
	{
		uint256 _feeDaoAmount = projectData[projectId_].budget * feeDao / PCT_PRECISION;
		_startProject(projectId_, treasury, _feeDaoAmount, tokenFactory);
		emit StartedProject(projectId_);
		emit PaidDao(projectId_, _feeDaoAmount);
	}

	/**
	* @dev Approves collaborator's MPG (or deletes collaborator should be called by admin)
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address
	* @param approve_ - bool whether to approve or not collaborator payment 
	*/
	function _approveCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		bool approve_
	)
		internal
		override
		returns(uint256)
	{
		if(approve_) {
			require
				(projectData[projectId_].initiator == msg.sender ||
				owner() == msg.sender,
				"caller is not the project initiator nor the owner");
		}else{
			require(owner() == msg.sender, "caller is not the owner");
		}
		return super._approveCollaborator(projectId_, packageId_, collaborator_, approve_);
	}

	/***************************************
					ADMIN
	****************************************/
	
	/**
	 * @dev Sets new fees
	 * @param feeDao_ DAO fee in ppm
	 * @param feeObservers_ Observers fee in ppm
	 */
	function changeFees (
		uint256 feeDao_,
		uint256 feeObservers_
	)
		public
		onlyOwner
	{
		feeDao = feeDao_;
		feeObservers = feeObservers_;
		emit ChangedFees(feeDao_, feeObservers_);
	}

	/**
	* @dev Approves project
	* @param projectId_ Id of the project
	*/
	function approveProject(
		bytes32 projectId_
	)
		external
		onlyOwner
	{
		_approveProject(projectId_);
		emit ApprovedProject(projectId_);
	}

	/**
	* @dev Batch approves projects
	* @param projectIds_ Array of the project Ids
	*/
	function approveProjects(
		bytes32[] memory projectIds_
	)
		external
		noneEmptyBytesArray(projectIds_)
		onlyOwner
	{
		for (uint256 i = 0; i < projectIds_.length; i++) {
			_approveProject(projectIds_[i]);
		}
		emit ApprovedProjects(projectIds_);
	}

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborators_ array of collaborators' addresses
	* @param scores_ array of collaboratos' scores in PPM
	*/
	function setBonusScores(
		bytes32 projectId_,
		bytes32 packageId_,
		address[] memory collaborators_,
		uint256[] memory scores_
	)
		external
		noneEmptyUintArray(scores_)
		onlyOwner
	{
		require(collaborators_.length == scores_.length, "collaborators' and scores' length are not the same");
		uint256 _totalBonusScores;
		for(uint256 i = 0; i < collaborators_.length; i++){
			_setBonusScore(projectId_, packageId_, collaborators_[i], scores_[i]);
			_totalBonusScores += scores_[i];
		}
		_setBonusScores(projectId_, packageId_, _totalBonusScores, PCT_PRECISION);
		emit SetBonusScores(projectId_, packageId_, collaborators_, scores_);
	}

	/**
	* @dev Approves collaborator's MPG (or deletes collaborator should be called by admin)
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address
	* @param approve_ - bool whether to approve or not collaborator payment 
	*/
	function approveCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		bool approve_
	)
		external
	{
		_approveCollaborator(projectId_, packageId_, collaborator_, approve_);
		emit ApprovedCollaborator(projectId_, packageId_, collaborator_, approve_);
	}

    function raiseDispute(bytes32 _projectId, bytes32 _packageId, address _collaborator) external {
		require( msg.sender == projectData[_projectId].initiator || approvedUser[_packageId][msg.sender] == true);
		_raiseDispute(_packageId, _collaborator);    
    }

    function approvePayment(bytes32 _projectId, bytes32 _packageId, address _collaborator) external onlyOwner {
        _getMgpForApprovedPayment(_projectId, _packageId,_collaborator);
        _paidBonusForApprovedPayment(_projectId, _packageId,_collaborator);
    }

    function rejectPayment(bytes32 _projectId, bytes32 _packageId,address _collaborator) external onlyOwner {
		uint256 _mgp = collaboratorData[_projectId][_packageId][_collaborator].mgp;
		uint256 _bonus = collaboratorData[_projectId][_packageId][_collaborator].bonusScore;
		address _initiator = projectData[_projectId].initiator;
		uint256 _feesToBeRevert = _mgp + _bonus;
		address _token = projectData[_projectId].token;
		IERC20(_token).safeTransfer(_initiator,_feesToBeRevert);
		collaboratorData[_projectId][_packageId][_collaborator].mgp = 0;
		collaboratorData[_projectId][_packageId][_collaborator].bonusScore = 0;
		_downDispute(_projectId,_collaborator);
    }
	/**
	* @dev Batch approves collaborator's MPG (or deletes collaborators should be called by admin) 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborators_ array of collaborator's addresses
	* @param approves_ - array of bools (whether to approve or not collaborator payment) 
	*/
	function approveCollaborators(
		bytes32 projectId_,
		bytes32 packageId_,
		address[] memory collaborators_,
		bool[] memory approves_
	)
		external
	{
		require(collaborators_.length != 0, "array length must be greater than 0");
		require(
			collaborators_.length == approves_.length, 
			"collaborators' and approves' array length are not the same"
		);
		for (uint256 i = 0; i < collaborators_.length; i++) {
			_approveCollaborator(projectId_, packageId_, collaborators_[i], approves_[i]);	
		}
		emit ApprovedCollaborators(projectId_, packageId_, collaborators_, approves_);
	}

	/**
	* @dev Finishes project
	* @param projectId_ Id of the project
	*/
	function finishProject(
		bytes32 projectId_
	)
		external
	{
		require(projectData[projectId_].initiator == msg.sender,"Caller Is Not Initiator");
		_finishProject(projectId_);
		emit FinishedProject(projectId_);
	}

	/***************************************
			PROJECT INITIATOR ACTIONS
	****************************************/

	/**
	* @dev Creates project proposal
	* @param token_ project token address, zero addres if project has not token yet 
	* (IOUT will be deployed on project approval) 
	* @param budget_ total budget (has to be approved on token contract if project has its own token)
	* @return projectId_ Id of the project proposal created
	*/
	function createProject(
		address token_,
		uint256 budget_
	)
		external
		nonZero(budget_)
		returns(bytes32 projectId_)
	{
		projectId_ = _generateProjectId();
		_createProject(projectId_, token_, budget_);
		emit CreatedProject(projectId_, msg.sender, token_, budget_);
		if(token_ != address(0)) {
			emit ApprovedProject(projectId_);
			_startProject(projectId_);
		}
	}

	/**
	* @dev Starts project
	* @param projectId_ Id of the project
	*/
	function startProject(
		bytes32 projectId_
	)
		external
		onlyInitiator(projectId_)
	{
		_startProject(projectId_);
	}

	/**
	* @dev Creates package in project
	* @param projectId_ Id of the project
	* @param budget_ MGP budget 
	* @param bonus_ Bonus budget 
	* @return packageId_ Id of the package created
	*/
	function createPackage(
		bytes32 projectId_,
		uint256 budget_,
		uint256 bonus_
	)
		external
		onlyInitiator(projectId_)
		nonZero(budget_)
		returns(bytes32 packageId_)
	{
		packageId_ = _generatePackageId(projectId_, 0);
		_createPackage(projectId_, packageId_, budget_, budget_ * feeObservers / PCT_PRECISION, bonus_);
		_reservePackagesBudget(projectId_, budget_ + bonus_, 1);
		emit CreatedPackage(projectId_, packageId_, budget_, bonus_);
	}

	/**
	* @dev Batch creates packages in project
	* @param projectId_ Id of the project
	* @param budgets_ array of MGP budgets 
	* @param bonuses_ array of bonus budgets 
	* @return packageIds_ array of package Ids created
	*/
	function createPackages(
		bytes32 projectId_,
		uint256[] memory budgets_,
		uint256[] memory bonuses_
	)
		external
		noneEmptyUintArray(budgets_)
		onlyInitiator(projectId_)
		returns(bytes32[] memory packageIds_)
	{
		require(budgets_.length == bonuses_.length, "budgets and bonuses arrays lengths are not the same");
		uint256 _amount;
		packageIds_ = new bytes32[](budgets_.length);
		for (uint256 i = 0; i < budgets_.length; i++) {
			require(budgets_[i] != 0, "amount must be greater than 0");
			packageIds_[i] = _generatePackageId(projectId_, i);
			_amount += budgets_[i] + bonuses_[i];
			_createPackage(projectId_, packageIds_[i], budgets_[i], budgets_[i] * feeObservers / PCT_PRECISION, bonuses_[i]);
		}
		_reservePackagesBudget(projectId_, _amount, budgets_.length);
		emit CreatedPackages(projectId_, packageIds_, budgets_, bonuses_);
	}

	/**
	* @dev Adds observer to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param observer_ observer addresses
	*/
	function addObserver(
		bytes32 projectId_,
		bytes32 packageId_,
		address observer_
	)
		external
		onlyInitiator(projectId_)
	{
		_addObserver(projectId_, packageId_, observer_);
		_addObservers(projectId_, packageId_, 1);
		emit AddedObserver(projectId_, packageId_, observer_);
	}

	/**
	* @dev Batch adds observers to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param observers_ array of observer addresses
	*/
	function addObservers(
		bytes32 projectId_,
		bytes32 packageId_,
		address[] calldata observers_
	)
		external
		onlyInitiator(projectId_)
	{
		require(observers_.length > 0, "zero length observers array");
		for(uint256 i = 0; i < observers_.length; i++)
			_addObserver(projectId_, packageId_, observers_[i]);
		_addObservers(projectId_, packageId_, observers_.length);
		emit AddedObservers(projectId_, packageId_, observers_);
	}

	/**
	* @dev Adds collaborator to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborators' addresses  
	* @param mgp_ MGP amount
	*/
	function addCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		uint256 mgp_
	)
		external
		onlyInitiator(projectId_)
		nonZero(mgp_)
	{
		_addCollaborator(projectId_, packageId_, collaborator_, mgp_);
		_reserveCollaboratorsBudget(projectId_, packageId_, 1, mgp_);
		emit AddedCollaborator(projectId_, packageId_, collaborator_, mgp_);
	}

	/**
	* @dev Batch Adds collaborators to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborators_ array of collaborators' addresses  
	* @param mgps_ array of MGP amounts
	*/
	function addCollaborators(
		bytes32 projectId_,
		bytes32 packageId_,
		address[] memory collaborators_,
		uint256[] memory mgps_
	)
		external
		noneEmptyUintArray(mgps_)
		onlyInitiator(projectId_)
	{
		require(collaborators_.length == mgps_.length, "collaborators and mpgs arrays lengths are not the same");
		uint256 _amount;
		for (uint256 i = 0; i < collaborators_.length; i++) {
			require(mgps_[i] != 0, "amount must be greater than 0");
			_amount += mgps_[i];
			_addCollaborator(projectId_, packageId_, collaborators_[i], mgps_[i]);
		}
		_reserveCollaboratorsBudget(projectId_, packageId_, collaborators_.length, _amount);
		emit AddedCollaborators(projectId_, packageId_, collaborators_, mgps_);
	}

	/**
	* @dev Fihishes package in project
	* @param projectId_ Id of the project 
	*/
	function finishPackage(
		bytes32 projectId_,
		bytes32 packageId_
	)
		external
		onlyInitiator(projectId_)
	{
		_finishPackage(projectId_, packageId_);
		emit FinishedPackage(projectId_, packageId_);
	}
	
	/***************************************
			COLLABORATOR ACTIONS
	****************************************/
	/**
	* @dev Sends approved MGP to collaborator, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package  
	*/
	function getMgp(
		bytes32 projectId_,
		bytes32 packageId_,
        address collaborator_
	)
        external
		nonReentrant
		returns(uint256 amount_)
	{
		require(!isDispute[collaborator_][packageId_]);
        amount_ = _getMgp(projectId_, packageId_); 
		_pay(projectId_, amount_);
		emit PaidMgp(projectId_, packageId_, msg.sender, amount_);
	}
	
	/**
	* @dev Batch sends approved MGP to collaborator for multiple packages, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageIds_ array of package Ids  
	*/
	function getMgps(
		bytes32 projectId_,
		bytes32[] memory packageIds_,
        address[] memory collaborators_
	)
		external
		nonReentrant
		noneEmptyBytesArray(packageIds_)
		returns(uint256 amount_)
	{
		for (uint256 i = 0; i < packageIds_.length; i++) {
            require(!isDispute[collaborators_[i]][packageIds_[i]]);
			amount_ += _getMgp(projectId_, packageIds_[i]);
             
		}
		_pay(projectId_, amount_);
		emit PaidMgps(projectId_, packageIds_, msg.sender, amount_);
	}

	/**
	* @dev Sends approved Bonus to collaborator, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package  
	*/
	function getBonus(
		bytes32 projectId_,
		bytes32 packageId_,
        address collaborator_
	)
		external
		nonReentrant
		returns(uint256 amount_)
	{
        require(!isDispute[collaborator_][packageId_]);
		// uint temp;
		// temp = packageData[projectId_][packageId_].bonus * collaboratorData[projectId_][packageId_][msg.sender].bonusScore * 10e18;
		// uint temp_1;
		// temp_1 = temp / PCT_PRECISION;
		// amount_ = temp_1;
		amount_ = collaboratorData[projectId_][packageId_][msg.sender].bonusScore;
		_paidBonus(projectId_, packageId_, amount_); 
		_pay(projectId_, amount_);
		emit PaidBonus(projectId_, packageId_, msg.sender, amount_);
	}

	/**
	* @dev Batch Sends approved Bonus to collaborator, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageIds_ array of package Ids  
	*/
	function getBonuses(
		bytes32 projectId_,
		bytes32[] memory packageIds_,
        address[] memory collaborators_

	)
		external
		nonReentrant
		noneEmptyBytesArray(packageIds_)
		returns(uint256 amount_)
	{
		uint256 _amount;
		for (uint256 i = 0; i < packageIds_.length; i++) {
            require(!isDispute[collaborators_[i]][packageIds_[i]]);
			// uint256 temp;
			// temp = packageData[projectId_][packageIds_[i]].bonus * collaboratorData[projectId_][packageIds_[i]][msg.sender].bonusScore * 10e18;
			// uint temp_1;
			// temp_1 = temp / PCT_PRECISION;
			 _amount = collaboratorData[projectId_][packageIds_[i]][msg.sender].bonusScore;
			// amount_ += _amount;
			amount_ += _amount;
			_paidBonus(projectId_, packageIds_[i], _amount);
		}
		_pay(projectId_, amount_);
		emit PaidBonuses(projectId_, packageIds_, msg.sender, amount_);
	}

	/***************************************
			OBSERVER ACTIONS
	****************************************/

	/**
	* @dev Sends observer fee, should be called from observer's address
	* @param projectId_ Id of the project  
	* @param packageId_ Id of the package
	* @return amount_ fee amount paid
	*/
	function getObserverFee(
		bytes32 projectId_,
		bytes32 packageId_
	)
		external
		nonReentrant
		returns(uint256 amount_)
	{
		_paidObserverFee(projectId_, packageId_);
		amount_ = _getObserverFee(projectId_, packageId_);
		_pay(projectId_, amount_);
		emit PaidObserverFee(projectId_, packageId_, msg.sender, amount_);
	}

	/**
	* @dev Sends observer fee for multiple packages, should be called from observer's address
	* @param projectId_ Id of the project  
	* @param packageIds_ array of package Ids
	* @return amount_ fee amount paid
	*/
	function getObserverFees(
		bytes32 projectId_,
		bytes32[] memory packageIds_
	)
		external
		nonReentrant
		noneEmptyBytesArray(packageIds_)
		returns(uint256 amount_)
	{
		for (uint256 i = 0; i < packageIds_.length; i++) {
			_paidObserverFee(projectId_, packageIds_[i]);
			amount_ += _getObserverFee(projectId_, packageIds_[i]);
		}
		_pay(projectId_, amount_);
		emit PaidObserverFees(projectId_, packageIds_, msg.sender, amount_);
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface IReBakedDAO {

	event ChangedFees(uint256 feeDao, uint256 feeObservers);
	event CreatedProject(bytes32 indexed projectId, address initiator, address token, uint256 budget);
	event ApprovedProject(bytes32 indexed projectId);
	event ApprovedProjects(bytes32[] projectIds);
	event StartedProject(bytes32 indexed projectId);
	event FinishedProject(bytes32 indexed projectId);
	event CreatedPackage(bytes32 indexed projectId, bytes32 indexed packageId, uint256 budget, uint256 bonus);
	event CreatedPackages(bytes32 indexed projectId, bytes32[] packageIds, uint256[] budgets, uint256[] bonuses);
	event AddedObserver(bytes32 indexed projectId, bytes32 indexed packageId, address observer);
	event AddedObservers(bytes32 indexed projectId, bytes32 indexed packageId, address[] observers);
	event AddedCollaborator(
		bytes32 indexed projectId, bytes32 indexed packageId, address collaborator, uint256 mgp
	);
	event AddedCollaborators(
		bytes32 indexed projectId, bytes32 indexed packageId, address[] collaborators, uint256[] mgps
	);
	event ApprovedCollaborator(
		bytes32 indexed projectId, bytes32 indexed packageId, address collaborator, bool approve
	);
	event ApprovedCollaborators(
		bytes32 indexed projectId, bytes32 indexed packageId, address[] collaborators, bool[] approves
	);
	event FinishedPackage(bytes32 indexed projectId, bytes32 indexed packageId);
	event SetBonusScores(bytes32 indexed projectId, bytes32 indexed packageId, address[] collaborators, uint256[] scores);
	event PaidDao(bytes32 indexed projectId, uint256 amount);
	event PaidMgp(
		bytes32 indexed projectId, bytes32 indexed packageId, address collaborator, uint256 amount
	);
	event PaidMgps(
		bytes32 indexed projectId, bytes32[] packageIds, address collaborator, uint256 amount
	);
	event PaidBonus(
		bytes32 indexed projectId, bytes32 indexed packageId, address collaborator, uint256 amount
	);
	event PaidBonuses(
		bytes32 indexed projectId, bytes32[] packageIds, address collaborator, uint256 amount
	);
	event PaidObserverFee(bytes32 indexed projectId, bytes32 indexed packageId, address observer, uint256 amount);
	event PaidObserverFees(
		bytes32 indexed projectId, bytes32[] packageIds, address observer, uint256 amount
	);

	/***************************************
					ADMIN
	****************************************/
	
	/**
	 * @dev Sets new fees
	 * @param feeDao_ DAO fee in ppm
	 * @param feeObservers_ Observers fee in ppm
	 */
	function changeFees (uint256 feeDao_, uint256 feeObservers_) external;

	/**
	* @dev Approves project
	* @param projectId_ Id of the project
	*/
	function approveProject(bytes32 projectId_)	external;

	/**
	* @dev Batch approves projects
	* @param projectIds_ Array of the project Ids
	*/
	function approveProjects(bytes32[] memory projectIds_) external;

	/**
	* @dev Approves collaborator's MPG or deletes collaborator 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address
	* @param approve_ - bool whether to approve or not collaborator payment 
	*/
	function approveCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		bool approve_
	) external;

	/**
	* @dev Batch approves collaborator's MPG or deletes collaborator 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborators_ array of collaborator's addresses
	* @param approves_ - array of bools (whether to approve or not collaborator payment) 
	*/
	function approveCollaborators(
		bytes32 projectId_,
		bytes32 packageId_,
		address[] memory collaborators_,
		bool[] memory approves_
	) external;

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborators_ array of collaborators' addresses
	* @param scores_ array of collaboratos' scores in PPM
	*/
	function setBonusScores(
		bytes32 projectId_,
		bytes32 packageId_,
		address[] memory collaborators_,
		uint256[] memory scores_
	) external;

	/**
	* @dev Finishes project
	* @param projectId_ Id of the project
	*/
	function finishProject(bytes32 projectId_) external;

	/***************************************
			PROJECT INITIATOR ACTIONS
	****************************************/

	/**
	* @dev Creates project proposal
	* @param token_ project token address, zero addres if project has not token yet 
	* (IOUT will be deployed on project approval) 
	* @param budget_ total budget (has to be approved on token contract if project has its own token)
	* @return projectId_ Id of the project proposal created
	*/
	function createProject(address token_, uint256 budget_) external returns(bytes32 projectId_);

	/**
	* @dev Starts project
	* @param projectId_ Id of the project
	*/
	function startProject(bytes32 projectId_) external;

	/**
	* @dev Creates package in project
	* @param projectId_ Id of the project
	* @param budget_ MGP budget 
	* @param bonus_ Bonus budget 
	* @return packageId_ Id of the package created
	*/
	function createPackage(
        bytes32 projectId_, uint256 budget_, uint256 bonus_) external returns(bytes32 packageId_);

	/**
	* @dev Batch creates packages in project
	* @param projectId_ Id of the project
	* @param budgets_ array of MGP budgets 
	* @param bonuses_ array of bonus budgets 
	* @return packageIds_ array of package Ids created
	*/
	function createPackages(
        bytes32 projectId_, uint256[] memory budgets_, uint256[] memory bonuses_
    ) external returns(bytes32[] memory packageIds_);

	/**
	* @dev Adds observer to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param observer_ observer addresses
	*/
	function addObserver(bytes32 projectId_, bytes32 packageId_, address observer_) external;

	/**
	* @dev Batch adds observers to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param observers_ array of observer addresses
	*/
	function addObservers( bytes32 projectId_, bytes32 packageId_, address[] calldata observers_) external;

	/**
	* @dev Adds collaborator to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborators' addresses  
	* @param mgp_ MGP amount
	*/
	function addCollaborator( bytes32 projectId_, bytes32 packageId_, address collaborator_, uint256 mgp_) external;

	/**
	* @dev Batch Adds collaborators to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborators_ array of collaborators' addresses  
	* @param mgps_ array of MGP amounts
	*/
	function addCollaborators(
        bytes32 projectId_, bytes32 packageId_, address[] memory collaborators_, uint256[] memory mgps_) external;

	/**
	* @dev Fihishes package in project
	* @param projectId_ Id of the project 
	*/
	function finishPackage( bytes32 projectId_, bytes32 packageId_) external;
	
	/***************************************
			COLLABORATOR ACTIONS
	****************************************/
	/**
	* @dev Sends approved MGP to collaborator, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package  
    * @return amount_ mgp amount paid
	*/
	function getMgp(bytes32 projectId_, bytes32 packageId_, address collaborator_) external returns(uint256 amount_);

	/**
	* @dev Batch sends approved MGP to collaborator for multiple packages, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageIds_ array of package Ids  
    * @return amount_ mgp amount paid
	*/
	function getMgps(bytes32 projectId_, bytes32[] memory packageIds_, address[] memory collaborators_) external returns(uint256 amount_);

	/**
	* @dev Sends approved Bonus to collaborator, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package  
    * @return amount_ bonus amount paid
	*/
	function getBonus(bytes32 projectId_, bytes32 packageId_, address collaborator_) external returns(uint256 amount_);

	/**
	* @dev Batch Sends approved Bonus to collaborator, should be called from collaborator's address
	* @param projectId_ Id of the project
	* @param packageIds_ array of package Ids  
    * @return amount_ bonus amount paid
	*/
	function getBonuses(bytes32 projectId_, bytes32[] memory packageIds_, address[] memory collaborators_) external returns(uint256 amount_);

	/***************************************
			OBSERVER ACTIONS
	****************************************/

	/**
	* @dev Sends observer fee, should be called from observer's address
	* @param projectId_ Id of the project  
	* @param packageId_ Id of the package
	* @return amount_ fee amount paid
	*/
	function getObserverFee(bytes32 projectId_, bytes32 packageId_) external returns(uint256 amount_);

	/**
	* @dev Sends observer fee for multiple packages, should be called from observer's address
	* @param projectId_ Id of the project  
	* @param packageIds_ array of package Ids
	* @return amount_ fee amount paid
	*/
	function getObserverFees(bytes32 projectId_, bytes32[] memory packageIds_) external returns(uint256 amount_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokenFactory {
	function deployToken(uint256 totalSupply_) external returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Project, ProjectLibrary } from "./libraries/ProjectLibrary.sol";
import { Packages } from "./Packages.sol";

contract Projects is Packages {
	
	using ProjectLibrary for Project;

	mapping (bytes32 => Project) internal projectData;

	/**
	* @dev Creates project proposal
	* @param token_ project token address
	* @param budget_ total budget
	*/
	function _createProject(
		bytes32 projectId_,
		address token_,
		uint256 budget_
	)
		internal
	{
		projectData[projectId_]._createProject(token_, budget_);
	}

	/**
	* @dev Approves project
	* @param projectId_ Id of the project
	*/
	function _approveProject(
		bytes32 projectId_
	)
		internal
	{
		projectData[projectId_]._approveProject();
	}

	/**
	* @dev Starts project
	*/
	function _startProject(
		bytes32 projectId_,
		address treasury_,
		uint256 feeDaoAmount_,
		address tokenFactory_
	)
		internal
	{
		projectData[projectId_]._startProject(treasury_, feeDaoAmount_, tokenFactory_);
	}

	/**
	* @dev Finishes project
	* @param projectId_ Id of the project
	*/
	function _finishProject(
		bytes32 projectId_
	)
		internal
	{
		projectData[projectId_]._finishProject();
	}

	/**
	* @dev Creates package in project, check if there is budget available
	* allocates budget and increase total number of packages
	* @param projectId_ Id of the project
	* @param totalBudget_ total budget MGP + Bonus 
	* @param count_ total count of packages
	*/
	function _reservePackagesBudget(
		bytes32 projectId_,
		uint256 totalBudget_,
		uint256 count_
	)
		internal
	{
		projectData[projectId_]._reservePackagesBudget(totalBudget_, count_);
	}

	/**
	* @dev Fihishes package in project
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	*/
	function _finishPackage(
		bytes32 projectId_,
		bytes32 packageId_
	)
		internal
		override
		returns(uint256 budgetLeft_)
	{
		budgetLeft_ = super._finishPackage(projectId_, packageId_);
		projectData[projectId_]._finishPackage(budgetLeft_);
	}

	/**
	* @dev Sends observer fee after package is finished
	* @param projectId_ Id of the project
	* @param amount_ amount to pay
	*/
	function _pay(
		bytes32 projectId_,
		uint256 amount_
	)
		internal
	{
		projectData[projectId_]._pay(amount_);
	}

	/**
	* @dev Returns project data for given project id.
	* @param projectId_ project ID
	* @return projectData_
	*/
	function getProjectData(bytes32 projectId_)
		external
		view
		returns(Project memory)
	{
		return projectData[projectId_];
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity ^0.8.10;
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ITokenFactory } from "../interfaces/ITokenFactory.sol";
import { IIOUToken } from "../interfaces/IIOUToken.sol";
import { Project } from "./Structs.sol";

library ProjectLibrary {

	using SafeERC20 for IERC20;

	/**
	@dev Throws if there is no such project
	 */
	modifier onlyExistingProject(Project storage project_) {
		require(project_.timeCreated != 0, "no such project");
		_;
	}

	/**
	* @dev Creates project proposal
	* @param project_ reference to Project struct
	* @param token_ project token address
	* @param budget_ total budget
	*/
	function _createProject(
		Project storage project_,
		address token_,
		uint256 budget_
	)
		public
	{
		project_.initiator = msg.sender;
		project_.token = token_;
		project_.budget = budget_;
		project_.timeCreated = block.timestamp;
		if(token_ != address(0)) {
			project_.isOwnToken = true;
			_approveProject(project_);
		}
	}

	/**
	* @dev Approves project
	* @param project_ reference to Project struct
	*/
	function _approveProject(
		Project storage project_
	)
		public
		onlyExistingProject(project_)
	{
		require(project_.timeApproved == 0, "already approved project");
		project_.timeApproved = block.timestamp;
	}

	/**
	* @dev Starts project, if project own token auto approve, otherwise deploys IOUToken, transfers fee to DAO wallet
	* @param project_ reference to Project struct
	* @param treasury_ address of DAO wallet
	* @param feeDaoAmount_ DAO fee amount
	* @param tokenFactory_ address of token factory contract
	*/
	function _startProject(
		Project storage project_,
		address treasury_,
		uint256 feeDaoAmount_,
		address tokenFactory_
	)
		public
		onlyExistingProject(project_)
	{
		require(project_.timeStarted == 0, "project already started");
		require(project_.timeApproved != 0, "project is not approved");
		if(project_.isOwnToken)
			// IERC20(project_.token).safeTransferFrom(msg.sender, address(this), project_.budget * 10e18);
			IERC20(project_.token).safeTransferFrom(msg.sender, address(this), project_.budget);
		else
			project_.token = ITokenFactory(tokenFactory_).deployToken(project_.budget);
		project_.budgetAllocated = feeDaoAmount_;
		IERC20(project_.token).safeTransfer(treasury_, feeDaoAmount_);
		project_.budgetPaid = feeDaoAmount_;
		project_.timeStarted = block.timestamp;
	}

	/**
	* @dev Finishes project, checks if already finished or unfinished packages left
	* unallocated budget returned to initiator or burned (in case of IOUToken)
	* @param project_ reference to Project struct
	*/
	function _finishProject(
		Project storage project_
	)
		public
		onlyExistingProject(project_)
	{
		require(project_.timeFinished == 0, "already finished project");
		require(project_.totalPackages == project_.totalFinishedPackages, "unfinished packages left in project");
		project_.timeFinished = block.timestamp;
		uint256 budgetLeft_ = project_.budget - project_.budgetAllocated;
		if(project_.timeStarted != 0 && budgetLeft_ != 0){
			if(project_.isOwnToken)
				IERC20(project_.token).safeTransfer(project_.initiator, budgetLeft_);
			else
				IIOUToken(address(project_.token)).burn(budgetLeft_);
		}
	}

	/**
	* @dev Creates package in project, check if there is budget available
	* allocates budget and increase total number of packages
	* @param project_ reference to Project struct
	* @param totalBudget_ total budget MGP + Bonus  
	* @param count_ total count of packages
	*/
	function _reservePackagesBudget(
		Project storage project_,
		uint256 totalBudget_,
		uint256 count_
	)
		public
		onlyExistingProject(project_)
	{
		require(project_.timeStarted != 0, "project is not started");
		require(project_.timeFinished == 0, "project is finished");
		uint256 _projectBudgetAvaiable = project_.budget - project_.budgetAllocated;
		require(_projectBudgetAvaiable >= totalBudget_, "not enough project budget left");
		project_.budgetAllocated += totalBudget_;
		project_.totalPackages += count_;
	}

	/**
	* @dev Fihishes package in project, budget left addded refunded back to project budget
	* increases total number of finished packages
	* @param project_ reference to Project struct
	* @param budgetLeft_ amount of budget left
	*/
	function _finishPackage(
		Project storage project_,
		uint256 budgetLeft_
	)
		public
		onlyExistingProject(project_)
	{
		if(budgetLeft_ != 0)
			project_.budgetAllocated -= budgetLeft_;
		project_.totalFinishedPackages++;
	}

	/**
	* @dev Pays from project's budget, increases budget paid
	* @param project_ reference to Project struct
	* @param amount_ amount to pay     
	*/
	function _pay(
		Project storage project_,
		uint256 amount_
	)
		public
		onlyExistingProject(project_)
	{
		IERC20(project_.token).safeTransfer(msg.sender, amount_);
		project_.budgetPaid += amount_;
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Package, PackageLibrary } from "./libraries/PackageLibrary.sol";
import { Observers } from "./Observers.sol";
import { Collaborators } from "./Collaborators.sol";

contract Packages is Observers, Collaborators {
	
	using PackageLibrary for Package;

	mapping (bytes32 => mapping(bytes32 => Package)) internal packageData;

	// address of approved collaborator with perticular package
	mapping (bytes32 => mapping (address => bool)) internal approvedUser;

     // Boolean to know if there is a dispute against a paticular collaborator in a particular package
	mapping(address => mapping(bytes32 => bool)) isDispute;
    

	/**
	* @dev Creates package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param budget_ MGP budget 
	* @param feeObserversBudget_ Observers fee budget
	* @param bonus_ Bonus budget 
	*/
	function _createPackage(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 budget_,
		uint256 feeObserversBudget_,
		uint256 bonus_
	)
		internal
		virtual
	{
		packageData[projectId_][packageId_]._createPackage(budget_, feeObserversBudget_, bonus_);
	}

	/**
	* @dev Adds observers to package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param count_ number of observers
	*/
	function _addObservers(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 count_
	)
		internal
	{
		packageData[projectId_][packageId_]._addObservers(count_);
	}

	/**
	* @dev Reserves collaborators MGP from package budget and increase total number of collaborators
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param count_ number of collaborators to add 
	* @param amount_ amount to reserve  
	*/
	function _reserveCollaboratorsBudget(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 count_,
		uint256 amount_
	)
		internal
	{
		packageData[projectId_][packageId_]._reserveCollaboratorsBudget(count_, amount_);
	}

	/**
	* @dev Refund package budget and decreace total collaborators if not approved
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param collaborator_ address of collaborator
	* @param approve_ - whether to approve or not collaborator payment 
	*/
	function _approveCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		bool approve_
	)
		internal
		override
		virtual
		returns(uint256 mgp_)
	{
		mgp_ = super._approveCollaborator(projectId_, packageId_, collaborator_, approve_);
		packageData[projectId_][packageId_]._approveCollaborator(approve_, mgp_);
		approvedUser[packageId_][collaborator_] = true;
	}

	/**
	* @dev Fihishes package
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	*/
	function _finishPackage(
		bytes32 projectId_,
		bytes32 packageId_
	)
		internal
		virtual
		returns(uint256)
	{
		return packageData[projectId_][packageId_]._finishPackage();
	}

	/**
	* @dev Sets allocated bonuses
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param totalBonusScores_ total sum of bonus scores
	* @param maxBonusScores_ max bonus scores (PPM)
	*/
	function _setBonusScores(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 totalBonusScores_,
		uint256 maxBonusScores_
	)
		internal
	{
		packageData[projectId_][packageId_]._setBonusScores(totalBonusScores_, maxBonusScores_);
	}

	/**
	* @dev Calls _getObserverFee in Observers and _getObserverFee in Observers Library
	* @param projectId_ Id of the project  
	* @param packageId_ Id of the package
	* @return amount_ fee amount paid
	*/
	function _getObserverFee(
		bytes32 projectId_,
		bytes32 packageId_
	)
		internal
		returns(uint256)
	{
		return packageData[projectId_][packageId_]._getObserverFee();
	}	

	/**
	* @dev Increases package budget paid
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param amount_ mgp amount   
	*/
	function _getMgp(
		bytes32 projectId_,
		bytes32 packageId_
	)
		internal
		virtual
		override
		returns(uint256 amount_)
	{	
		amount_ = super._getMgp(projectId_, packageId_);
		packageData[projectId_][packageId_]._getMgp(amount_);
	}

	/**
	* @dev Increases package bonus paid
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param amount_ paid amount
	*/
	function _paidBonus(
		bytes32 projectId_,
		bytes32 packageId_,
		uint256 amount_
	)
		internal
	{
		packageData[projectId_][packageId_]._paidBonus(amount_);
		super._paidBonus(projectId_, packageId_);
	}

    function _raiseDispute(bytes32 packageId_, address collaborator_) internal {
        require(isDispute[collaborator_][packageId_] == false);
		isDispute[collaborator_][packageId_] = true;
    }

	function _downDispute(bytes32 packageId_, address collaborator_) internal {
		require(isDispute[collaborator_][packageId_] == true);
		isDispute[collaborator_][packageId_] = false;
	}

	/**
	* @dev Returns package data for given project id and package id.
	* @param projectId_ project ID
	* @param packageId_ package ID
	* @return packageData_
	*/
	function getPackageData(bytes32 projectId_, bytes32 packageId_)
		external
		view
		returns(Package memory)
	{
		return packageData[projectId_][packageId_];
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IIOUToken {
	function burn(uint256 amount_) 	external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Package } from "./Structs.sol";

library PackageLibrary {

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
	* @param budget_ MGP budget 
	* @param feeObserversBudget_ Observers fee budget
	* @param bonus_ Bonus budget
	*/
	function _createPackage(
		Package storage package_,
		uint256 budget_,
		uint256 feeObserversBudget_,
		uint256 bonus_
	)
		public
	{
		package_.budget = budget_;
		package_.budgetAllocated = feeObserversBudget_;
		package_.budgetObservers = feeObserversBudget_;
		package_.bonus = bonus_;
		package_.timeCreated = block.timestamp;
	}

	/**
	* @dev Adds observers to package
	* @param package_ reference to Package struct
	* @param count_ number observer addresses
	*/
	function _addObservers(
		Package storage package_,
		uint256 count_
	)
		public
		onlyExistingPackage(package_)
	{
		require(package_.timeFinished == 0, "already finished package");
		package_.totalObservers += count_;
	}

	/**
	* @dev Reserves collaborators MGP from package budget and increase total number of collaborators,
	* checks if there is budget available and allocates it  
	* @param count_ number of collaborators to add 
	* @param amount_ amount to reserve
	*/
	function _reserveCollaboratorsBudget(
		Package storage package_,
		uint256 count_,
		uint256 amount_
	)
		public
		onlyExistingPackage(package_)
	{
		require(package_.timeFinished == 0, "already finished package");
		require(
			package_.budget - package_.budgetAllocated >= amount_, 
			"not enough package budget left"
		);
		package_.budgetAllocated += amount_;
		package_.totalCollaborators += count_;
	}

	/**
	* @dev Refund package budget and decreace total collaborators if not approved
	* @param package_ reference to Package struct
	* @param approve_ whether to approve or not collaborator payment 
	* @param mgp_ MGP amount
	*/
	function _approveCollaborator(
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
	*/
	function _finishPackage(
		Package storage package_
	)
		public
		onlyExistingPackage(package_)
		returns(uint256 budgetLeft_)
	{
		//require(package_.timeFinished == 0, "already finished package");
		//require(package_.totalCollaborators == package_.approvedCollaborators, "unapproved collaborators left");
		budgetLeft_ = package_.budget - package_.budgetAllocated;
		if(package_.totalObservers == 0)
			budgetLeft_ += package_.budgetObservers;
		if(package_.totalCollaborators == 0)
			budgetLeft_ += package_.bonus;
		package_.timeFinished = block.timestamp;
	}

	/**
	* @dev Sets scores for collaborator bonuses 
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
	* @dev Sends observer fee after package is finished, increses package budget and observers' budget paid
	* @param package_ reference to Package struct
	* @return amount_ fee amount
	*/
	function _getObserverFee(
		Package storage package_
	)
		internal
		onlyExistingPackage(package_)
		returns(uint256 amount_)
	{
		require(package_.timeFinished != 0, "package is not finished");
		amount_ = package_.budgetObservers / package_.totalObservers;
		package_.budgetPaid += amount_;
		package_.budgetObserversPaid += amount_;
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
	function _paidBonus(
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Observer } from "./libraries/Structs.sol";

contract Observers {

	mapping(bytes32 => mapping(bytes32 => mapping(address => Observer))) internal observerData;

	/**
	* @dev Checks if observer can be added and records time
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package
	* @param observer_ observer addresses
	*/
	function _addObserver(
		bytes32 projectId_,
		bytes32 packageId_,
		address observer_
	)
		internal
	{
		require(observer_ != address(0), "observer address is zero");
		Observer storage _observer = observerData[projectId_][packageId_][observer_];
		require(_observer.timeCreated == 0, "observer already added");
		_observer.timeCreated = block.timestamp;
	}

	/**
	* @dev Marks observer fee paid, checks if observer can be paid and records time
	* @param projectId_ Id of the project  
	* @param packageId_ Id of the package
	*/
	function _paidObserverFee(
		bytes32 projectId_,
		bytes32 packageId_
	)
		internal
		returns(uint256)
	{
		Observer storage _observer = observerData[projectId_][packageId_][msg.sender];
		require(_observer.timeCreated != 0, "no such observer");
		require(_observer.timePaid == 0, "observer already paid");
		_observer.timePaid = block.timestamp;
		return 0;
	}

	/**
	* @dev Returns observer data for project id and address.
	* @param projectId_ project ID
	* @param packageId_ Id of the package
	* @param observer_ observer's address
	* @return observerData_
	*/
	function getObserverData(bytes32 projectId_, bytes32 packageId_, address observer_)
		external
		view
		returns(Observer memory)
	{
		return observerData[projectId_][packageId_][observer_];
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Collaborator, CollaboratorLibrary } from "./libraries/CollaboratorLibrary.sol";

contract Collaborators {
	
	using CollaboratorLibrary for Collaborator;

	mapping (bytes32 => mapping(bytes32 => mapping(address => Collaborator))) internal collaboratorData;

	/**
	* @dev Adds collaborator
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address  
	* @param mgp_ minimal garanteed payment
	*/
	function _addCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		uint256 mgp_
	)
		internal
	{
		require(collaborator_ != address(0), "collaborator's address is zero");
		 collaboratorData[projectId_][packageId_][collaborator_]._addCollaborator(mgp_);
	}

	/**
	* @dev Approves collaborator's MPG or deletes collaborator 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address 
	* @param approve_ whether to approve or not collaborator payment  
	*/
	function _approveCollaborator(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		bool approve_
	)
		internal
		virtual
		returns(uint256 mgp_)
	{
		mgp_ = collaboratorData[projectId_][packageId_][collaborator_].mgp; 
		collaboratorData[projectId_][packageId_][collaborator_]._approveCollaborator(approve_);
		if(!approve_)
			delete collaboratorData[projectId_][packageId_][collaborator_];
	}

	/**
	* @dev Sets scores for collaborator bonuses 
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	* @param collaborator_ collaborator's address 
	* @param bonusScore_ collaborator's bonus score
	*/
	function _setBonusScore(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_,
		uint256 bonusScore_
	)
		internal
	{
		collaboratorData[projectId_][packageId_][collaborator_]._setBonusScore(bonusScore_);
	}

	/**
	* @dev Sets MGP time paid flag
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	*/
	function _getMgp(
		bytes32 projectId_,
		bytes32 packageId_
	)
		internal
		virtual
		returns(uint256)
	{
		return collaboratorData[projectId_][packageId_][msg.sender]._getMgp();
	}

	function _getMgpForApprovedPayment(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_
	)
	 	internal
		virtual
		returns(uint256)
	{
		return collaboratorData[projectId_][packageId_][collaborator_]._getMgp();
	}
	/**
	* @dev Sets Bonus time paid flag
	* @param projectId_ Id of the project
	* @param packageId_ Id of the package 
	*/
	function _paidBonus(
		bytes32 projectId_,
		bytes32 packageId_
	)
		internal
	{
		collaboratorData[projectId_][packageId_][msg.sender]._paidBonus();
	}

	function _paidBonusForApprovedPayment(
		bytes32 projectId_,
		bytes32 packageId_,
		address collaborator_
	)
		internal
	{
		collaboratorData[projectId_][packageId_][collaborator_]._paidBonus();
	}
	
	/**
	* @dev Returns collaborator data for given project id, package id and address.
	* @param projectId_ project ID
	* @param packageId_ package ID
	* @param collaborator_ collaborator's address 
	* @return collaboratorData_
	*/
	function getCollaboratorData(bytes32 projectId_, bytes32 packageId_, address collaborator_)
		external
		view
		returns(Collaborator memory)
	{
		return collaboratorData[projectId_][packageId_][collaborator_];
	}

}

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