/**
 *Submitted for verification at polygonscan.com on 2021-08-15
*/

pragma solidity ^0.5.17;

/**
 *  @title A access contract with granular access for multiple parties.
 *  @author Shebin John - [email protected]
 *  @notice You can use this contract for creating multiple roles with different access.
 *  @dev To add a new role, add the corresponding array and mapping, along with add, remove and get functions.
 */
contract CourtifyRights {
	/* Storage */

	address public chiefJustice;
	address[] private courts;
	address[] private advocates;

	mapping(address => bool) private isCourt;
	mapping(address => bool) private isAdvocate;
	/**
	 * @notice In the future new list can be added based on the required limit.
	 * When adding a new list, a new array & mapping has to be created.
	 * Adding/Removing functions, getter for array and mapping.
	 * Events for Adding/Removing and modifier to check the validity.
	 */

	/* Events */

	/**
	 * @notice Emitted when a chief justice position is transferred.
	 * @param _oldChiefJustice The one who initiates this event. Will be the current chief justice.
	 * @param _newChiefJustice The new chief justice who has been added recently.
	 */
	event ChiefJusticeTransferred(address indexed _oldChiefJustice, address indexed _newChiefJustice);

	/**
	 * @notice Emitted when a new court is added.
	 * @param _initiator The one who initiates this event.
	 * @param _newCourt The new court who has been added recently.
	 */
	event CourtAdded(address indexed _initiator, address indexed _newCourt);

	/**
	 * @notice Emitted when a court is removed.
	 * @param _initiator The one who initiates this event.
	 * @param _removedCourt The court who has been removed.
	 */
	event CourtRemoved(address indexed _initiator, address indexed _removedCourt);

	/**
	 * @notice Emitted when an Advocate is added.
	 * @param _initiator The one who initiates this event.
	 * @param _newAdvocate The new Advocate who has been added recently.
	 */
	event AdvocateAdded(address indexed _initiator, address indexed _newAdvocate);

	/**
	 * @notice Emitted when an Advocate is removed.
	 * @param _initiator The one who initiates this event.
	 * @param _removedAdvocate The Advocate who has been removed.
	 */
	event AdvocateRemoved(address indexed _initiator, address indexed _removedAdvocate);

	/* Modifiers */

	/**
	 * @dev Throws if called by any account other than the Chief Justice.
	 */
	modifier onlyChiefJustice() {
		require(chiefJustice == msg.sender, "CourtifyRights: Only Chief Justice can call this function.");
		_;
	}

	/**
	 * @dev Throws if called by any account other than the Court.
	 */
	modifier onlyCourt() {
		require(isCourt[msg.sender], "CourtifyRights: Only Court can call this function.");
		_;
	}

	/**
	 * @dev Throws if called by any account other than the Advocate.
	 */
	modifier onlyAdvocate() {
		require(isAdvocate[msg.sender], "CourtifyRights: Only Advocate can call this function.");
		_;
	}

	/* Functions */

	/**
	 * @dev Initializes the contract, setting the Chief Justice initially.
	 * @param _chiefJustice The Chief Justice Address.
	 */
	constructor(address _chiefJustice) public {
		require(_chiefJustice != address(0), "CourtifyRights: Chief Justice Address cannot be a zero Address.");
		chiefJustice = _chiefJustice;
		emit ChiefJusticeTransferred(address(0), _chiefJustice);
	}

	/**
	 * @notice The function to transfer Chief Justice Position.
	 * @param _newChiefJustice The address of the new Chief Justice.
	 * @dev Only callable by Chief Justice.
	 */
	function transferChiefJustice(address _newChiefJustice) public onlyChiefJustice {
		_transferChiefJustice(_newChiefJustice);
	}

	/**
	 * @notice The function to add a new court.
	 * @param _newCourt The address of the new court.
	 * @dev Only callable by Chief Justice.
	 */
	function addCourt(address _newCourt) public onlyChiefJustice {
		_addCourt(_newCourt);
	}

	/**
	 * @notice The function to remove a court.
	 * @param _courtToRemove The address of the court which should be removed.
	 * @dev Only callable by Chief Justice.
	 */
	function removeCourt(address _courtToRemove) public onlyChiefJustice {
		_removeCourt(_courtToRemove);
	}

	/**
	 * @notice The function to add a new advocate.
	 * @param _newAdvocate The address of the new advocate.
	 * @dev Only callable by a Court.
	 */
	function addAdvocate(address _newAdvocate) public onlyCourt {
		_addAdvocate(_newAdvocate);
	}

	/**
	 * @notice The function to remove an advocate.
	 * @param _advocateToRemove The address of the advocate which should be removed.
	 * @dev Only callable by a Court.
	 */
	function removeAdvocate(address _advocateToRemove) public onlyCourt {
		_removeAdvocate(_advocateToRemove);
	}

	/* Internal Functions */

	/**
	 * @notice The internal function to add a new court.
	 * @param _newChiefJustice The address of the new court.
	 */
	function _transferChiefJustice(address _newChiefJustice) internal {
		require(_newChiefJustice != address(0), "CourtifyRights: Invalid Address.");
		chiefJustice = _newChiefJustice;
		emit ChiefJusticeTransferred(msg.sender, _newChiefJustice);
	}

	/**
	 * @notice The internal function to add a new court.
	 * @param _newCourt The address of the new court.
	 */
	function _addCourt(address _newCourt) internal {
		require(_newCourt != address(0), "CourtifyRights: Invalid Address.");
		require(!isCourt[_newCourt], "CourtifyRights: Address is already a court.");
		isCourt[_newCourt] = true;
		courts.push(_newCourt);

		emit CourtAdded(msg.sender, _newCourt);
	}

	/**
	 * @notice The internal function to remove a court.
	 * @param _courtToRemove The address of the court which should be removed.
	 */
	function _removeCourt(address _courtToRemove) internal {
		require(isCourt[_courtToRemove], "CourtifyRights: Address is not a court.");
		isCourt[_courtToRemove] = false;
		uint256 len = courts.length;
		for (uint256 index = 0; index < len; index++) {
			if (_courtToRemove == courts[index]) {
				courts[index] = courts[len - 1];
				break;
			}
		}
		courts.pop();

		emit CourtRemoved(msg.sender, _courtToRemove);
	}

	/**
	 * @notice The internal function to add a new advocate.
	 * @param _newAdvocate The address of the new advocate.
	 */
	function _addAdvocate(address _newAdvocate) internal {
		require(_newAdvocate != address(0), "CourtifyRights: Invalid Address.");
		require(!isAdvocate[_newAdvocate], "CourtifyRights: Address is already an advocate.");
		isAdvocate[_newAdvocate] = true;
		advocates.push(_newAdvocate);

		emit AdvocateAdded(msg.sender, _newAdvocate);
	}

	/**
	 * @notice The internal function to remove an advocate.
	 * @param _advocateToRemove The address of the advocate which should be removed.
	 */
	function _removeAdvocate(address _advocateToRemove) internal {
		require(isAdvocate[_advocateToRemove], "CourtifyRights: Address is not an advocate.");
		isAdvocate[_advocateToRemove] = false;
		uint256 len = advocates.length;
		for (uint256 index = 0; index < len; index++) {
			if (_advocateToRemove == advocates[index]) {
				advocates[index] = advocates[len - 1];
				break;
			}
		}
		advocates.pop();

		emit AdvocateRemoved(msg.sender, _advocateToRemove);
	}

	/* Getter Functions */

	/**
	 * @notice Checks if the passed address is an court or not.
	 * @param _addr The address to check.
	 * @return True if Court, False otherwise.
	 */
	function checkCourt(address _addr) public view returns (bool) {
		return isCourt[_addr];
	}

	/**
	 * @notice Checks if the passed address is a advocate or not.
	 * @param _addr The address to check.
	 * @return True if Advocate, False otherwise.
	 */
	function checkAdvocate(address _addr) public view returns (bool) {
		return isAdvocate[_addr];
	}

	/**
	 * @dev Returns the address array of the courts.
	 * @return The list of courts.
	 */
	function getCourts() public view returns (address[] memory) {
		return courts;
	}

	/**
	 * @dev Returns the address array of the advocate.
	 * @return The list of advocates.
	 */
	function getAdvocates() public view returns (address[] memory) {
		return advocates;
	}
}

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

contract Courtify is CourtifyRights {
	/* STORAGE */

	uint256 public lastCaseID;
	uint256 public totalPetitoner;

	mapping(uint256 => Petitoner) public petitoners;
	mapping(uint256 => Case) public cases;

	struct Petitoner {
		uint256 id;
		string name;
	}

	struct Case {
		uint256 timestamp;
		string state;
		string district;
		string court;
		uint256 petitonerID;
		uint256 caseType;
		string[] evidence;
	}

	/* EVENTS */

	/*
	 * @notice Emitted when case is created.
	 * @param _initiator The one who initiates the event.
	 * @param _caseID The new case id which was created.
	 * @param _timestamp The time when the case was created.
	 * @param _state The state where the case was created.
	 * @param _district The district where the case was created.
	 * @param _court The court where the case was created.
	 * @param _petitonerID The Petitioner ID.
	 * @param _caseType The case type.
	 */
	event CaseCreated(
		address _initiator,
		uint256 indexed _caseID,
		uint256 _timestamp,
		string _state,
		string _district,
		string _court,
		uint256 indexed _petitonerID,
		uint256 indexed _caseType
	);

	/*
	 * @notice Emitted when the case is created.
	 * @param _initiator The one who initiates the event.
	 * @param _caseID The case ID for which the evidence was added.
	 * @param _IPFS The IPFS hash.
	 */
	event EvidenceAdded(address _initiator, uint256 _caseID, string _IPFS);

	/* CONSTRUCTOR */

	/*
	 * @param _chiefJustice The Chief Justice Address.
	 * @dev _chiefJustice cannot be a zero address.
	 */
	constructor(address _chiefJustice) public CourtifyRights(_chiefJustice) {
		lastCaseID = 1;
		totalPetitoner = 1;
	}

	/* PUBLIC */

	/*
	 * @notice Function to create a new case.
	 * @param _timestamp The time when the case was created.
	 * @param _state The state where the case was created.
	 * @param _district The district where the case was created.
	 * @param _court The court where the case was created.
	 * @param _petitonerID The Petitioner ID.
	 * @param _name The Petitioner Name.
	 * @param _caseType The case type.
	 * @return _newCaseID The new case id which was created.
	 */
	function createNewCase(
		uint256 _timestamp,
		string memory _state,
		string memory _district,
		string memory _court,
		uint256 _petitonerID,
		string memory _name,
		uint256 _caseType
	) public onlyCourt returns (uint256 _newCaseID) {
		_newCaseID = _createNewCase(_timestamp, _state, _district, _court, _petitonerID, _name, _caseType);
	}

	/*
	 * @notice Function to upload the evidence.
	 * @param _caseID The case ID for which the evidence will be added.
	 * @param _IPFS The IPFS hash.
	 */
	function uploadEvidence(uint256 _caseID, string memory _IPFS) public onlyAdvocate {
		_uploadEvidence(_caseID, _IPFS);
	}

	/* INTERNAL */

	/*
	 * @param _timestamp The time when the case was created.
	 * @param _state The state where the case was created.
	 * @param _district The district where the case was created.
	 * @param _court The court where the case was created.
	 * @param _petitonerID The Petitioner ID.
	 * @param _name The Petitioner Name.
	 * @param _caseType The case type.
	 * @return _newCaseID The new case id which was created.
	 * @dev The internal function which creates a new case.
	 */
	function _createNewCase(
		uint256 _timestamp,
		string memory _state,
		string memory _district,
		string memory _court,
		uint256 _petitonerID,
		string memory _name,
		uint256 _caseType
	) internal returns (uint256 _newCaseID) {
		_newCaseID = lastCaseID;
		Case storage _case = cases[_newCaseID];
		_case.timestamp = _timestamp;
		if (_timestamp == 0) {
			_case.timestamp = block.timestamp;
		}
		_case.state = _state;
		_case.district = _district;
		_case.court = _court;
		if (_petitonerID == 0) {
			petitoners[totalPetitoner].id = totalPetitoner;
			petitoners[totalPetitoner].name = _name;
			_case.petitonerID = totalPetitoner;
			totalPetitoner++;
		} else {
			_case.petitonerID = _petitonerID;
		}
		_case.caseType = _caseType;
		emit CaseCreated(msg.sender, _newCaseID, _timestamp, _state, _district, _court, _petitonerID, _caseType);
		lastCaseID++;
	}

	/*
	 * @param _caseID The case ID for which the evidence will be added.
	 * @param _IPFS The IPFS hash.
	 * @dev Internal function to upload the evidence.
	 */
	function _uploadEvidence(uint256 _caseID, string memory _IPFS) internal {
		cases[_caseID].evidence.push(_IPFS);
		emit EvidenceAdded(msg.sender, _caseID, _IPFS);
	}

	/* GETTER */

	/*
	 * @notice Function to get the case details.
	 * @param _caseID The case ID which has to be queried.
	 * @return _timestamp The time when the case was created.
	 * @return _state The state where the case was created.
	 * @return _district The district where the case was created.
	 * @return _court The court where the case was created.
	 * @return _name The Petitioner Name.
	 * @return _caseType The case type.
	 */
	function getCase(uint256 _caseID)
		public
		view
		returns (
			uint256 _timestamp,
			string memory _state,
			string memory _district,
			string memory _court,
			string memory _name,
			uint256 _caseType
		)
	{
		Case memory _case = cases[_caseID];
		Petitoner memory petitoner = petitoners[_case.petitonerID];
		return (_case.timestamp, _case.state, _case.district, _case.court, petitoner.name, _case.caseType);
	}

	/*
	 * @notice Function to get the evidence of a case.
	 * @param _caseID The case ID which has to be queried.
	 * @return The IPFS array of evidences for a case.
	 */
	function getEvidence(uint256 _caseID) public view returns (string[] memory) {
		return cases[_caseID].evidence;
	}
}