/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.6;

interface ILandRegistration {

    // Land Developer Info
    struct Developer {
        string  companyName;
        string  companyType;
        string  grossRevenue;
        string  industrySector;
        uint    developerID;
        address developerAddress;
        uint[]  myActiveLandIDs;    // active land ID array
        mapping(uint => uint) myIndexOfLands;   // using landID -> index in the above land ID array
    }

    // Land Info
    struct Land {
        // basic info
        uint    propertyIdentificationNumber;
        string  legalDescriptionOfProperty;
        string  typeOfOwnership;
        string  registeredItems;
        bool    isValid;
        // vote related
        address[] votedAddresses;
        uint    landID;
        uint    developerID;
        address developerAddress;
        // appraisal related
        uint    appraisalAmount;
        uint8   appraisalDiscountInPercent;
        uint    amountBorrowedByDeveloper;
        bool    isCollateral;        
    }


    /// Developer Related Events
    event NewDeveloperAdded       (uint indexed developerID, address indexed developerAddress, string  companyName, string  companyType, string  grossRevenue, string  industrySector); 
    event DeveloperUpdated        (uint indexed developerID, address indexed developerAddress, string  companyName, string  companyType, string  grossRevenue, string  industrySector);
    /// Land Related Events
    event NewLandAdded            (uint indexed landID, uint propertyIdentificationNumber, string legalDescriptionOfProperty, string typeOfOwnership, string registeredItems, uint developerID);
    event LandBasicInfoUpdated    (uint indexed landID, uint propertyIdentificationNumber, string legalDescriptionOfProperty, string typeOfOwnership, string registeredItems, uint developerID);
    event LandAppraisalAddedorUpdated           (uint indexed landID, uint appraisalAmount, uint8 appraisalDiscountInPercent, uint amountBorrowedByDeveloper);
    event AppraisalBorrowedByDeveloperUpdated   (uint indexed landID, uint amountBorrowedByDeveloper);
    event LandAppraisalApproved   (uint indexed landID, bool isValid);
    /// Developer & Land Delete
    event DeveloperDeleted  (uint indexed developerID); 
    event LandDeleted       (uint indexed landID);

    /// Developer add & update & delete
    /// for developers: no approval needed from MC
    function addNewDeveloper(string calldata _companyName, string calldata _companyType, string calldata _grossRevenue, string calldata _industrySector, address _developerAddress) external;
    function updateDeveloper(uint _developerID, string calldata _companyName, string calldata _companyType, string calldata _grossRevenue, string calldata _industrySector, address _developerAddress) external;

    /// Land add & update & appraisal update
    /// for lands: update basic info and uupdateAppraisalBorrowedByDeveloper() no need to approve
    ///            but for appraisal info update needs approval
    function addNewLand(uint _propertyIdentificationNumber, string calldata _legalDescriptionOfProperty, string calldata _typeOfOwnership, string calldata _registeredItems, uint _developerID) external;
    function updateLandBaiscInfo(uint _landID, uint _propertyIdentificationNumber, string calldata _legalDescriptionOfProperty, string calldata _typeOfOwnership, string calldata _registeredItems, uint _developerID) external;
    function addOrUpdateLandAppraisal(uint _landID, uint _appraisalAmount, uint8 _appraisalDiscountInPercent, uint _amountBorrowedByDeveloper) external;
    ///@dev updateAppraisalBorrowedByDeveloper should only be called by the Loan contract, we can set it later
    function updateAppraisalBorrowedByDeveloper(uint _landID, uint _amountBorrowedByDeveloper) external;
    function approveLandAppraisal(uint _landID) external;
    
    /// delete developer / land
    function deleteDeveloper(uint _developerID) external;
    function deleteLand(uint _landID) external;
}

// File: src/contracts/interfaces/IManagementCompany.sol

pragma solidity >=0.6.0;

interface IManagementCompany {
    event newAdminProposed(address indexed proposer, address indexed newPendingAdmin);
    event newMinApprovalRequiredProposed(address indexed proposer, uint indexed newNumber);
    event newMemberRemovalProposed(address indexed proposer, address indexed newPendingRemoveMember);

    event newAdminApproved(address indexed proposer, address indexed newPendingAdmin);
    event newMinApprovalRequiredApproved(address indexed proposer, uint indexed newNumber);
    event newMemberRemovalApproved(address indexed proposer, address indexed newPendingRemoveMember);

    event newAdminAppended(address indexed newPendingAdmin);
    event newMinApprovalRequiredUpdated(uint indexed newNumber);
    event memberRemoved(address indexed newPendingRemoveMember);

    function minApprovalRequired() external view returns (uint);
    function isMCAdmin(address admin) external returns (bool);

    function proposeNewAdmin(address newAdmin) external;
    function proposeNewApprovalRequiredNumber(uint number) external;
    function proposeRemoveAdmin(address adminToBeRemoved) external;
    function approveNewAdmin() external;
    function approveNewApprovalRequiredNumber() external;
    function approveAdminRemoval() external;
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: src/contracts/LandRegistration.sol

pragma solidity ^0.7.6;




contract LandRegistration is ILandRegistration {
    using SafeMath for uint256;
    address public MCBoard;             // MCBoard Contract address

    // developer related
    uint    public nextDeveloperID;     // next developer ID
    uint[]  public activeDeveloperIDs;  // current active dev ID array
    mapping(address => uint)    public getDeveloperIDByAddress; // using develper address -> developer ID
    mapping(uint => Developer)  public getDeveloperByID;        // using developer id -> developer info struct
    mapping(uint => uint)       public indexOfDeveloper;        // using developer id -> get corresponding index of activeDeveloperIDs
    mapping(uint => bool)       public isDeveloperIDValid;      // using developer id -> developer valid or not
    // developer address whitelist - user cannot set two developer with same address
    mapping(address => bool)    public addressWhitelist;

    // land related
    uint    public nextLandID;          // next land ID
    uint[]  public activeLandIDs;       // current active land ID array
    mapping(uint => Land) public getLandByID;       // using land ID -> land info struct
    mapping(uint => uint) public indexOfLand;       // using land ID -> get corresponding index of activeLandIDs
    mapping(uint => bool) public isLandIDValid;     // using landID -> land valid or not

    // creating land records and developer records
    // mapping(uint256 => Developer) public Developers;
    // mapping(uint256 => Land)      public Lands;

    // only MC admins can procced
    modifier onlyAdmins {
        require(IManagementCompany(MCBoard).isMCAdmin(msg.sender) == true,"Only admins can call this");
         _;
    }


    constructor(
        address _MCBoard    // MC_Contract Address
    ) public {
        MCBoard = _MCBoard;
        // set both active array first element to 0, so deleted developers & lands can refer to this
        activeDeveloperIDs.push(0); 
        activeLandIDs.push(0);      
    }

    
    ///@notice register developer to developers, require msg.sender from the MC contract admin address lsit
    ///@param   _companyName    company name
    ///@param   _companyType    company type: Corporation, Sole Proprietor Holding Company, etc.
    ///@param   _grossRevenue   description of company revenue
    ///@param   _industrySector company sector: Construction, Government, Health, Education, High0Tech, Retail
    ///@param   _developerAddress developer address: address of developer's wallet
    function addNewDeveloper(
        string calldata _companyName, 
        string calldata _companyType, 
        string calldata _grossRevenue, 
        string calldata _industrySector,
        address _developerAddress
    ) external override onlyAdmins {
        require(bytes(_companyName).length > 0,     "please do not leave name empty"    );
        require(bytes(_companyType).length > 0,     "please do not leave type empty"    );
        require(bytes(_grossRevenue).length > 0,    "please do not leave revenue empty" );
        require(bytes(_industrySector).length > 0,  "please do not leave sector empty"  );
        require(_developerAddress != address(0),    "please do not leave address empty" );
        require(addressWhitelist[_developerAddress] != true, "please choose another developer address");

        // increment next developer ID
        nextDeveloperID++;

        // update info in _developer
        Developer storage _developer = getDeveloperByID[nextDeveloperID];
        _developer.companyName      = _companyName;
        _developer.companyType      = _companyType;
        _developer.grossRevenue     = _grossRevenue;
        _developer.industrySector   = _industrySector;
        _developer.developerID      = nextDeveloperID;
        _developer.developerAddress = _developerAddress;
        addressWhitelist[_developerAddress] = true;
        // store to active developer array
        activeDeveloperIDs.push(nextDeveloperID);
        getDeveloperIDByAddress[_developerAddress] = nextDeveloperID;
        // getDeveloperByID[nextDeveloperID] = _developer;                     //  index    0  1  2  active[1] = 1  active[2] = 2
        indexOfDeveloper[nextDeveloperID] = activeDeveloperIDs.length - 1;  // active = [0, 1, 2] indexOfDeveloper = [1, 2]        
        getDeveloperByID[nextDeveloperID].myActiveLandIDs.push(0);          // make sure myActiveLandIDs starts from 0
        isDeveloperIDValid[nextDeveloperID] = true; // set developer to valid

        // emit developer registration info
        emit NewDeveloperAdded(nextDeveloperID, _developerAddress, _companyName, _companyType, _grossRevenue, _industrySector);
    }

     
    ///@notice update developer's info, require msg.sender from the MC contract admin address lsit
    ///@param   _developerID        developer identification numver should be in range (0, nextDeveloperID]
    ///@param   _companyName        company name
    ///@param   _companyType        company type
    ///@param   _grossRevenue       company revenue
    ///@param   _industrySector     company sector
    ///@param   _developerAddress   developer address: address of developer's wallet
    function updateDeveloper(
        uint _developerID, 
        string calldata _companyName, 
        string calldata _companyType, 
        string calldata _grossRevenue, 
        string calldata _industrySector,
        address _developerAddress
    ) external override onlyAdmins {
        require(_developerID > 0 && _developerID <= nextDeveloperID,       "Developer ID should be in valid range");
        require(bytes(_companyName).length > 0,     "please do not leave name empty"    );
        require(bytes(_companyType).length > 0,     "please do not leave type empty"    );
        require(bytes(_grossRevenue).length > 0,    "please do not leave revenue empty" );
        require(bytes(_industrySector).length > 0,  "please do not leave sector empty"  );
        require(_developerAddress != address(0),    "please do not leave address empty" );
        // if user do not want to use current address
        Developer storage _developer = getDeveloperByID[_developerID];
        if (_developerAddress != _developer.developerAddress){
            // require user using one not from the table
            require(addressWhitelist[_developerAddress] != true, "please choose another developer address");
            // update address whitelist -> old one set to false, new one set to true
            addressWhitelist[_developerAddress] = true;
            address oldAddress = getDeveloperByID[_developerID].developerAddress;
            addressWhitelist[oldAddress] = false;
        }

        // update info in _developer
        _developer.companyName      = _companyName;
        _developer.companyType      = _companyType;
        _developer.grossRevenue     = _grossRevenue;
        _developer.industrySector   = _industrySector;

        // emit developer updated info
        emit NewDeveloperAdded(_developerID, _developerAddress, _companyName, _companyType, _grossRevenue, _industrySector);
    }


    ///@notice clear developer's info, require msg.sender from the MC contract admin address lsit
    ///@param   _developerID    developer identification numver should be in range (0, nextDeveloperID]
    function deleteDeveloper(uint _developerID) external override onlyAdmins {
        require(_developerID > 0 && _developerID <= nextDeveloperID, "Developer ID should be in valid range");

        // set developer to invalid
        isDeveloperIDValid[_developerID] = false;
        // modify activeDeveloperIDs -> [1, 2, 3, 4] delete 2 -> [1, 4, 3]
        uint _indexOfDeveloper = indexOfDeveloper[_developerID];
        uint _lengthOfActive = activeDeveloperIDs.length;
        activeDeveloperIDs[_indexOfDeveloper] = activeDeveloperIDs[_lengthOfActive - 1];
        activeDeveloperIDs.pop();   // pop the last element
        // modify indexOfDeveloper 
        indexOfDeveloper[_developerID] = 0; // set it to first element of activeDeveloperIDs

        // emit developer deleted evet
        emit DeveloperDeleted(_developerID);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _propertyIdentificationNumber   PIN number, official number for a land
    ///@param   _legalDescriptionOfProperty     legal description about the land
    ///@param   _typeOfOwnership    description of types of ownership
    ///@param   _registeredItems    items under the land
    ///@param   _developerID    developer identification numver should be in range (0, nextDeveloperID]
    function addNewLand(
        uint _propertyIdentificationNumber, 
        string calldata _legalDescriptionOfProperty, 
        string calldata _typeOfOwnership,
        string calldata _registeredItems,
        uint _developerID    
    ) external override onlyAdmins {
        require(_propertyIdentificationNumber != 0,                     "please do not leave PIN empty");
        require(bytes(_legalDescriptionOfProperty).length > 0,          "please do not leave legal description empty"    );
        require(bytes(_typeOfOwnership).length > 0,     "please do not leave type empty");
        require(bytes(_registeredItems).length > 0,     "please do not leave registered items empty");
        require(_developerID > 0 && _developerID <= nextDeveloperID,    "Developer ID should be in valid range");

        // increment developer number
        nextLandID++;

        // update info in _land
        Land memory _land;
        _land.propertyIdentificationNumber = _propertyIdentificationNumber;
        _land.legalDescriptionOfProperty = _legalDescriptionOfProperty;
        _land.typeOfOwnership = _typeOfOwnership;
        _land.registeredItems = _registeredItems;
        _land.isValid = true;
        _land.landID = nextLandID;
        _land.developerID = _developerID;
        _land.developerAddress = getDeveloperByID[_developerID].developerAddress;
        _land.isCollateral = false;
        // store to active land array
        activeLandIDs.push(nextLandID);
        getLandByID[nextLandID] = _land;                        //  index    0  1  2  active[1] = 1  active[2] = 2
        indexOfLand[nextLandID] = activeLandIDs.length - 1;     // active = [0, 1, 2] indexOfDeveloper = [1, 2]
        isLandIDValid[nextLandID] = true;

        // update corresponding developer's info
        Developer storage _developer = getDeveloperByID[_developerID];
        _developer.myActiveLandIDs.push(nextLandID);
        _developer.myIndexOfLands[nextLandID] = _developer.myActiveLandIDs.length - 1;

        // emit land registration event
        emit NewLandAdded(nextLandID, _propertyIdentificationNumber, _legalDescriptionOfProperty, _typeOfOwnership, _registeredItems, _developerID);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID                         Land ID
    ///@param   _propertyIdentificationNumber   PIN number, official number for a land
    ///@param   _legalDescriptionOfProperty     legal description about the land
    ///@param   _typeOfOwnership    description of types of ownership
    ///@param   _registeredItems    items under the land
    ///@param   _developerID    developer identification numver should be in range (0, developerNum]
    function updateLandBaiscInfo(
        uint _landID,
        uint _propertyIdentificationNumber, 
        string calldata _legalDescriptionOfProperty, 
        string calldata _typeOfOwnership, 
        string calldata _registeredItems, 
        uint _developerID
    ) external override onlyAdmins {
        require(_landID > 0 && _landID <= nextLandID,           "landID should in a valid range");
        require(_propertyIdentificationNumber > 0,              "please do not leave PIN empty" );
        require(bytes(_legalDescriptionOfProperty).length > 0,  "please do not leave legal description empty");
        require(bytes(_typeOfOwnership).length > 0,     "please do not leave type empty");
        require(bytes(_registeredItems).length > 0,     "please do not leave registered items empty");
        require(_developerID > 0 && _developerID <= nextDeveloperID, "Developer ID should be in valid range");
        require(isDeveloperIDValid[_developerID] == true,       "Developer must be valid");

        // update info in _land
        Land storage _land = getLandByID[_landID];
        _land.propertyIdentificationNumber = _propertyIdentificationNumber;
        _land.legalDescriptionOfProperty = _legalDescriptionOfProperty;
        _land.typeOfOwnership = _typeOfOwnership;
        _land.registeredItems = _registeredItems;
        _land.isValid = true;
        _land.developerID = _developerID;
        _land.developerAddress = getDeveloperByID[_developerID].developerAddress;
        // store in lands
        uint oldOwner = getLandByID[_landID].developerID;

        // if developerID got updated
        if (oldOwner != _developerID){
            // update original owner's info
            uint _indexOfLand = getDeveloperByID[oldOwner].myIndexOfLands[_landID];
            uint tempLength = getDeveloperByID[oldOwner].myActiveLandIDs.length;
            getDeveloperByID[oldOwner].myActiveLandIDs[_indexOfLand] = getDeveloperByID[oldOwner].myActiveLandIDs[tempLength - 1]; 
            getDeveloperByID[oldOwner].myActiveLandIDs.pop();
            getDeveloperByID[oldOwner].myIndexOfLands[_landID] = 0;      // set index of lands to default

            // update my active land info and index info
            getDeveloperByID[_developerID].myActiveLandIDs.push(_landID);
            getDeveloperByID[_developerID].myIndexOfLands[_landID] = getDeveloperByID[_developerID].myActiveLandIDs.length - 1;
        }

        // emit land basic info updated event
        emit LandBasicInfoUpdated(_landID, _propertyIdentificationNumber, _legalDescriptionOfProperty, _typeOfOwnership, _registeredItems, _developerID);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID                         PIN number, official number for a land
    ///@param   _appraisalAmount                legal description about the land
    ///@param   _appraisalDiscountInPercent     description of types of ownership
    ///@param   _amountBorrowedByDeveloper      items under the land
    function addOrUpdateLandAppraisal(
        uint _landID, 
        uint _appraisalAmount, 
        uint8 _appraisalDiscountInPercent, 
        uint _amountBorrowedByDeveloper
    ) external override onlyAdmins {
        require(_landID > 0 && _landID <= nextLandID,   "landID should in a valid range");
        require(_appraisalAmount > 0,                   "please do not leave appraisal amount empty");
        require(_appraisalDiscountInPercent > 0,        "please do not leave discount empty");
        // _appraisalAmount x (100 - _appraisalDiscountInPercent) / 100 >=_amountBorrowedByDeveloper
        uint num = 100;
        require((num.sub(_appraisalDiscountInPercent)).mul(_appraisalAmount).div(num) >= _amountBorrowedByDeveloper,
                "Developer cannot overuse the approved amount");
        require(_amountBorrowedByDeveloper > 0,         "please input correct amount");

        // update in lands
        Land storage _land = getLandByID[_landID];
        _land.appraisalAmount = _appraisalAmount;
        _land.appraisalDiscountInPercent = _appraisalDiscountInPercent;
        _land.amountBorrowedByDeveloper = _amountBorrowedByDeveloper;
       
        // change apprasial record will cause valid -> false
        delete _land.votedAddresses;   // clear voted addresses
        _land.votedAddresses.push(msg.sender);
        _land.isValid = false;
        _land.isCollateral = true;
        
        // update validity
        isLandIDValid[_landID] = false;

        // emit land appraisal added or updated
        emit LandAppraisalAddedorUpdated(_landID, _appraisalAmount, _appraisalDiscountInPercent, _amountBorrowedByDeveloper);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID   land ID
    ///@param   _amountBorrowedByDeveloper   amount been brrowed out
    function updateAppraisalBorrowedByDeveloper(
        uint _landID, 
        uint _amountBorrowedByDeveloper
    ) external override onlyAdmins {
        require(_landID > 0 && _landID <= nextLandID,   "landID should in a valid range");
        require(_amountBorrowedByDeveloper > 0,         "please do not leave borrowed amount empty");
        Land storage _land = getLandByID[_landID];
        // _appraisalAmount x (100 - _appraisalDiscountInPercent) / 100 >=_amountBorrowedByDeveloper
        uint num = 100;
        require((num.sub(_land.appraisalDiscountInPercent)).mul(_land.appraisalAmount).div(num) >= _amountBorrowedByDeveloper,
                "Developer cannot overuse the approved amount");
        require(isLandIDValid[_landID] == true,         "Land must be valid");
        require(getLandByID[_landID].appraisalAmount != 0,    "Land appraisal must be defined");
        require(getLandByID[_landID].isCollateral == true,    "Land must be a collateral");

        // update in lands
        _land.amountBorrowedByDeveloper = _amountBorrowedByDeveloper;

        // emit land appraisal borrowed by developer
        emit AppraisalBorrowedByDeveloperUpdated(_landID, _amountBorrowedByDeveloper);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID   LandID
    function approveLandAppraisal(
        uint _landID
    ) external override onlyAdmins {
        require(_landID > 0 && _landID <= nextLandID,  "landID should in a valid range");

        // update in lands
        Land storage _land = getLandByID[_landID];
        // check msg.sender in votedAddresses array or not, if not, then put address in array
        if (exist(_land.votedAddresses, msg.sender) == false){
            _land.votedAddresses.push(msg.sender);
        }
        // if voted address meet the mini required num, then set to valid
        if (_land.votedAddresses.length >= IManagementCompany(MCBoard).minApprovalRequired()){
            _land.isValid = true;
        }

        // store in getLandByID and change valid to true
        getLandByID[_landID] = _land;
        isLandIDValid[_landID] = true;

        // emit land appraisal approved
        emit LandAppraisalApproved(_landID, _land.isValid);
    } 


    ///@notice delete land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID   LandID
    function deleteLand(
        uint _landID
    ) external override onlyAdmins {
        require(_landID > 0 && _landID <= nextLandID,  "landID should in a valid range");
        
        // set land to invalid
        isLandIDValid[_landID] = false;
        // modify activeLandIDs -> [1, 2, 3, 4] delete 2 -> [1, 4, 3]
        uint _indexOfLand = indexOfLand[_landID];
        uint _lengthOfActive = activeLandIDs.length;
        activeLandIDs[_indexOfLand] = activeLandIDs[_lengthOfActive - 1];
        activeLandIDs.pop();
        // modify indexOfLand
        indexOfLand[_landID] = 0;

        // emit land deleted
        emit LandDeleted(_landID);
    }


    ///@notice helper function to check whether the msg.sender already in the land votedAddress array 
    ///@param   votedAddresses    all voted address array
    ///@param   user              msg.sender address
    function exist (address[] memory votedAddresses, address user) internal pure returns (bool){
      for (uint i = 0; i < votedAddresses.length; i++){
          if (user == votedAddresses[i]){
              return true;
          }
      }
      return false;
    }
}