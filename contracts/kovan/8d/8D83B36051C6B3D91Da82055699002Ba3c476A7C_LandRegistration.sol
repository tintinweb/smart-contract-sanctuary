// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./interfaces/ILandRegistration.sol"; 
import "./interfaces/IManagementCompany.sol";
import "./interfaces/ILoanOriginator.sol";
import "./interfaces/ILoanPool.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
contract LandRegistration is ILandRegistration {
    using SafeMath for uint256;

    address public  MCBoard;            // MCBoard Contract address

    // developer related
    uint    public  nextDeveloperID;     // next developer ID
    uint[]  public  activeDeveloperIDs;  // current active dev ID arrays
    mapping(uint => Developer)  public  getDeveloperByID;        // using developer id -> developer info struct
    mapping(uint => uint)       public  indexOfDeveloper;        // using developer id -> get corresponding index of activeDeveloperIDs
    mapping(uint => bool)       public override isDeveloperIDValid;      // using developer id -> developer valid or not

    // land related
    uint    public  nextLandID;          // next land ID
    uint[]  public  activeLandIDs;       // current active land ID array
    mapping(uint => Land) public  getLandByID;       // using land ID -> land info struct
    mapping(uint => uint) public  indexOfLand;       // using land ID -> get corresponding index of activeLandIDs
    mapping(uint => bool) public override isLandIDValid;     // using landID -> land valid or not

    // CMP related
    // uint    public  nextCMP;         // CMP index
    // uint[]  public  activeCMPIDs;    // since CMP has no valid, this is from [1,nextCMP]
    // mapping(uint => CommitmentMortgagePackage) public  CMPs;    // CMP notes mapping

    // only MC admins can procced
    modifier onlyAdmins {
        require(IManagementCompany(MCBoard).isMCAdmin(msg.sender) == true, "ERR:LR001 FORBIDDEN ONLY ADMIN");
        _;
    }

    // only MC admins can procced
    modifier onlyLOSC {
        require(msg.sender == IManagementCompany(MCBoard).LOSCAddress(), "ERR:LR002 FORBIDDEN ONLY LOSC");
        _;
    }

    // only LPSC can call
    modifier onlyLPSC {
        address LOSCAddress = IManagementCompany(MCBoard).LOSCAddress();
        require(ILoanOriginator(LOSCAddress).isLoanPoolValid(msg.sender) == true, "ERR:LR003 FORBIDDEN ONLY LPSC");
        _;
    }

    constructor(
        address _MCBoard    // MC_Contract Address
    ){
        MCBoard = _MCBoard;
        // set both active array first element to 0, so deleted developers & lands can refer to this
        activeDeveloperIDs.push(0); 
        activeLandIDs.push(0);      
    }
    
    ///@notice register developer to developers, require msg.sender from the MC contract admin address lsit
    ///@param   _companyName    company name
    ///@param   _location    company location
    ///@param   _note   description of company and project
    function addNewDeveloper(
        string calldata _companyName, 
        string calldata _location,
        string calldata _note
    ) external override onlyAdmins {
        require(bytes(_companyName).length > 0, "ERR:LR004 EMPTY COMPANY NAME");
        require(bytes(_location).length > 0,    "ERR:LR005 EMPTY LOCATION");
        require(bytes(_note).length > 0,        "ERR:LR006 EMPTY NOTE");

        // increment next developer ID
        nextDeveloperID++;

        // update info in _developer
        Developer storage _developer = getDeveloperByID[nextDeveloperID];
        _developer.companyName      = _companyName;
        _developer.location      = _location;
        _developer.note   = _note;
        _developer.developerID      = nextDeveloperID;
        _developer.myUniqueLoanEntityID.push(0);
        // store to active developer array
        activeDeveloperIDs.push(nextDeveloperID);
        // getDeveloperByID[nextDeveloperID] = _developer;                  //  index    0  1  2  active[1] = 1  active[2] = 2
        indexOfDeveloper[nextDeveloperID] = activeDeveloperIDs.length - 1;  // active = [0, 1, 2] indexOfDeveloper = [1, 2]        
        getDeveloperByID[nextDeveloperID].myActiveLandIDs.push(0);          // make sure myActiveLandIDs starts from 0
        isDeveloperIDValid[nextDeveloperID] = true; // set developer to valid

        // emit developer registration info
        emit NewDeveloperAdded(
            nextDeveloperID, 
            _companyName,
            _location,
            _note);
    }


    ///@notice update developer's info, require msg.sender from the MC contract admin address lsit
    ///@param   _developerID        developer identification numver should be in range (0, nextDeveloperID]
    ///@param   _companyName        company name
    ///@param   _location           company location
    ///@param   _note           company description
    function updateDeveloper(
        uint _developerID, 
        string calldata _companyName, 
        string calldata _location,
        string calldata _note
    ) external override onlyAdmins {
        require(isDeveloperIDValid[_developerID],   "ERR:LR007 INVALID DEVELOPER ID");
        require(bytes(_companyName).length > 0,     "ERR:LR004 EMPTY COMPANY NAME");
        require(bytes(_location).length > 0,        "ERR:LR005 EMPTY LOCATION");
        require(bytes(_note).length > 0,            "ERR:LR006 EMPTY NOTE");
        // if user do not want to use current address
        Developer storage _developer = getDeveloperByID[_developerID];

        // update info in _developer
        _developer.companyName      = _companyName;
        _developer.location      = _location;
        _developer.note     = _note;

        // emit developer updated info
        emit DeveloperUpdated(
            _developerID, 
            _companyName,
            _location,
            _note);
    }


    ///@notice clear developer's info, require msg.sender from the MC contract admin address lsit
    ///@param   _developerID    developer identification numver should be in range (0, nextDeveloperID]
    function deleteDeveloper(uint _developerID) external override onlyAdmins {
        require(isDeveloperIDValid[_developerID], "ERR:LR007 INVALID DEVELOPER ID");
        require(getDeveloperByID[_developerID].myActiveLandIDs.length == 1, "ERR:LR008 DEVELOPER STILL HAS LAND");
        require(getDeveloperByID[_developerID].myUniqueLoanEntityID.length == 1, "ERR:LR018 DEVELOPER STILL HAS LOAN");

        // set developer to invalid
        isDeveloperIDValid[_developerID] = false;

        // modify activeDeveloperIDs -> [1, 2, 3, 4] delete 2 -> [1, 4, 3]
        uint _indexOfLastDeveloper = activeDeveloperIDs.length - 1;
        uint _lastDeveloperID = activeDeveloperIDs[_indexOfLastDeveloper];
        uint _indexOfRemovedDeveloper = indexOfDeveloper[_developerID];
        // put last developerID to the position where we want to remove 
        activeDeveloperIDs[_indexOfRemovedDeveloper] = _lastDeveloperID;
        // modify indexOfDeveloper of last one and target
        indexOfDeveloper[_lastDeveloperID] = _indexOfRemovedDeveloper;
        indexOfDeveloper[_developerID] = 0; // set it to first element of activeDeveloperIDs
        activeDeveloperIDs.pop();   // pop the last element

        delete getDeveloperByID[_developerID];

        // emit developer deleted event
        emit DeveloperDeleted(_developerID);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address list
    ///@param   _propertyIdentificationNumber   PIN number, official number for a land
    ///@param   _propertyAddress     legal description about the land
    ///@param   _propertyZoning    description of types of zoning information
    ///@param   _note    land description note
    ///@param   _developerID    developer identification numver should be in range (0, nextDeveloperID]
    function addNewLand(
        uint _propertyIdentificationNumber,
        string calldata _propertyAddress,
        string calldata _propertyZoning,
        string calldata _note,
        uint _developerID    
    ) external override onlyAdmins {
        require(_propertyIdentificationNumber != 0, "ERR:LR009 PROPERTY ID SHOULD NOT BE ZERO");
        require(bytes(_propertyAddress).length > 0, "ERR:LR010 EMPTY ADDRESS");
        require(bytes(_propertyZoning).length > 0,  "ERR:LR011 EMPTY ZONE");
        require(bytes(_note).length > 0,            "ERR:LR012 EMPTY NOTE");
        require(isDeveloperIDValid[_developerID],   "ERR:LR007 INVALID DEVELOPER ID");

        // increment developer number
        nextLandID++;

        // update info in _land
        Land storage _land = getLandByID[nextLandID];
        _land.propertyIdentificationNumber = _propertyIdentificationNumber;
        _land.propertyAddress = _propertyAddress;
        _land.propertyZoning = _propertyZoning;
        _land.note = _note;
        _land.isReady = false;
        _land.landID = nextLandID;
        _land.developerID = _developerID;
        // store to active land array
        activeLandIDs.push(nextLandID);
        indexOfLand[nextLandID] = activeLandIDs.length - 1;     // active = [0, 1, 2] indexOfDeveloper = [1, 2]
        isLandIDValid[nextLandID] = true;

        // update corresponding developer's info
        Developer storage _developer = getDeveloperByID[_developerID];
        _developer.myActiveLandIDs.push(nextLandID);
        _developer.myIndexOfLands[nextLandID] = _developer.myActiveLandIDs.length - 1;
        // emit land registration event
        emit NewLandAdded(
            nextLandID, 
            _propertyIdentificationNumber,
            _propertyAddress,
            _propertyZoning,
            _note,
            _developerID);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID                         Land ID
    ///@param   _propertyIdentificationNumber   PIN number, official number for a land
    ///@param   _propertyAddress     legal description about the land
    ///@param   _propertyZoning    description of types of zoning information
    ///@param   _note    land description note
    function updateLandBasicInfo(
        uint _landID,
        uint _propertyIdentificationNumber,
        string calldata _propertyAddress,
        string calldata _propertyZoning,
        string calldata _note
    ) external override onlyAdmins {
        require(isLandIDValid[_landID],             "ERR:LR013 INVALID LANDID");
        require(_propertyIdentificationNumber > 0,  "ERR:LR009 PROPERTY ID SHOULD NOT BE ZERO");
        require(bytes(_propertyAddress).length > 0, "ERR:LR010 EMPTY ADDRESS");
        require(bytes(_propertyZoning).length > 0,  "ERR:LR011 EMPTY ZONE");

        // update info in _land
        Land storage _land = getLandByID[_landID];
        _land.propertyIdentificationNumber = _propertyIdentificationNumber;
        _land.propertyAddress = _propertyAddress;
        _land.propertyZoning = _propertyZoning;
        _land.note = _note;

        // emit land basic info updated event
        emit LandBasicInfoUpdated(
            _landID,
            _propertyIdentificationNumber,
            _propertyAddress,
            _propertyZoning,
            _note);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID                         PIN number, official number for a land
    ///@param   _appraisalAmount                legal description about the land
    ///@param   _appraisalDiscountPercent     description of types of ownership
    function addOrUpdateLandAppraisal(
        uint _landID, 
        uint _appraisalAmount, 
        uint _appraisalDiscountPercent
    ) external override onlyAdmins {
        require(isLandIDValid[_landID], "ERR:LR013 INVALID LANDID");
        require(
            _appraisalDiscountPercent > 0 && _appraisalDiscountPercent <= 100,    
            "ERR:LR018 INVALID APPRAISIAL DISCOUNT"
        );

        // update in lands
        Land storage _land = getLandByID[_landID];
        Developer storage _developer = getDeveloperByID[_land.developerID];

        uint num = 100;
        require(
            // case: 1. update appraisal amount should be higher than amont of money already borrwoed
            // case: 2. update appraisal amount to 0 to be able to call debtVoid
            _appraisalDiscountPercent.mul(_appraisalAmount).div(num) >= _land.amountBorrowedByDeveloper || _appraisalAmount == 0,
            "ERR:LR019 NEW APPRAISAL VALUE INSUFFICIENT."
        );
        if(_land.isReady) {
            _developer.totalBorrowableValue = _developer.totalBorrowableValue.sub(_land.appraisalDiscountPercent.mul(_land.appraisalAmount).div(num));
        }
        _land.appraisalAmount = _appraisalAmount;
        _land.appraisalDiscountPercent = _appraisalDiscountPercent;
        
        // change apprasial record will cause valid -> false
        delete _land.votedAddresses;   // clear voted addresses
        _land.votedAddresses.push(msg.sender);
        _land.isReady = false;

        // emit land appraisal added or updated
        emit LandAppraisalAddedorUpdated(
            _landID, 
            _appraisalAmount, 
            _appraisalDiscountPercent/*, 
            _amountBorrowedByDeveloper*/);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID     land ID
    ///@param   _amount     amount been brrowed out
    ///@param   _decimals   the decimal of token been used
    ///@param   isAdd       is this amount is add or not    
    function updateAmountBorrowedByDeveloper(
        uint _landID, 
        uint _amount,
        uint _decimals,
        bool isAdd
    ) external override onlyLOSC {
        require(isLandIDValid[_landID], "ERR:LR013 INVALID LANDID");
        Land storage _land = getLandByID[_landID];
        Developer storage _developer = getDeveloperByID[_land.developerID];
        require(_land.isReady == true,                          "ERR:LR014 LAND IS NOT READY");
        require(isDeveloperIDValid[_land.developerID] == true,  "ERR:LR007 INVALID DEVELOPER ID");

        uint num = 100;
        uint base = 10;
        uint decimalBase = base**_decimals;
        uint currDebt = _land.amountBorrowedByDeveloper;

        _amount = _amount.div(decimalBase);   // adjust decimals for different currencies
        if (isAdd == true) {
            currDebt = currDebt.add(_amount);
        } else {
            currDebt = currDebt.sub(_amount);
        }
        // check land appraisal
        require(
            _land.appraisalDiscountPercent.mul(_land.appraisalAmount).div(num) >= currDebt,
            "ERR:LR015 OVERUSE APPRAISAL AMOUNT"
        );

        // update in land & developer
        _land.amountBorrowedByDeveloper = currDebt;
        if (isAdd == true) {
            _developer.totalAmountBorrowed = _developer.totalAmountBorrowed.add(_amount);
        } else {
            _developer.totalAmountBorrowed = _developer.totalAmountBorrowed.sub(_amount);
        }

        // emit land appraisal borrowed by developer
        emit AmountBorrowedByDeveloperUpdated(_landID, _amount);
    }


    ///@notice add new land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID   LandID
    function approveLandAppraisal(
        uint _landID
    ) external override onlyAdmins {
        require(isLandIDValid[_landID], "ERR:LR013 INVALID LANDID");

        // update in lands
        Land storage _land = getLandByID[_landID];
        require(!_land.isReady, "ERR:LR014 LAND IS NOT READY");
        Developer storage _developer = getDeveloperByID[_land.developerID];

        // check msg.sender in votedAddresses array or not, if not, then put address in array
        if (exist(_land.votedAddresses, msg.sender) == false){
            _land.votedAddresses.push(msg.sender);
        }
        // if voted address meet the mini required num, then set to valid
        if (IManagementCompany(MCBoard).isVotesSufficient(_land.votedAddresses)){
            uint num = 100;
            _developer.totalBorrowableValue = _developer.totalBorrowableValue.add(_land.appraisalDiscountPercent.mul(_land.appraisalAmount).div(num));
            _land.isReady = true;
            delete _land.votedAddresses;
        }

        // emit land appraisal approved
        emit LandAppraisalApproved(_landID, _land.appraisalAmount);
    } 


    ///@notice delete land's info, require msg.sender from the MC contract admin address lsit
    ///@param   _landID   LandID
    function deleteLand(
        uint _landID
    ) external override onlyAdmins {
        require(isLandIDValid[_landID], "ERR:LR013 INVALID LANDID");
        Land storage _land = getLandByID[_landID]; 
        require(_land.amountBorrowedByDeveloper == 0, "ERR:LR017 DEVELOPER NOT PAID OFF");
        // set land to invalid
        isLandIDValid[_landID] = false;

        // modify activeLandIDs -> [1, 2, 3, 4] delete 2 -> [1, 4, 3]
        uint _indexOfLastLand = activeLandIDs.length - 1;
        uint _lastLandID = activeLandIDs[_indexOfLastLand];
        uint _indexOfRemovedLand = indexOfLand[_landID];
        // put last landID to the position where we want to remvoe 
        activeLandIDs[_indexOfRemovedLand] = _lastLandID;
        // modify indexOfLand of last one and target
        indexOfLand[_lastLandID] = _indexOfRemovedLand;
        indexOfLand[_landID] = 0;   // set it to first element of activeLandIDs
        activeLandIDs.pop();    // pop the last element

        //update developer
        Developer storage _developer = getDeveloperByID[getLandByID[_landID].developerID];
        // modify myActiveLandIDs -> [1, 2, 3, 4] delete 2 -> [1, 4, 3]
        uint _indexOfDeveloperLastActiveLand = _developer.myActiveLandIDs.length - 1;
        uint _lastDeveloperLandID = _developer.myActiveLandIDs[_indexOfDeveloperLastActiveLand];
        uint _indexOfDeveloperRemovedLandID = _developer.myIndexOfLands[_landID];
        // put last landID to the position where we want to remove 
        _developer.myActiveLandIDs[_indexOfDeveloperRemovedLandID] = _lastDeveloperLandID;
        // modify myIndexOfLands of last one and target
        _developer.myIndexOfLands[_lastDeveloperLandID] = _indexOfDeveloperRemovedLandID;
        _developer.myIndexOfLands[_landID] = 0;
        _developer.myActiveLandIDs.pop();
      
        uint num = 100;
        if(_land.isReady) {
            _developer.totalBorrowableValue = _developer.totalBorrowableValue
                                             .sub( _land.appraisalDiscountPercent
                                             .mul(_land.appraisalAmount).div(num));
        }

        // update getLandByID
        delete getLandByID[_landID];

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

    ///@notice necessary ActiveDeveloperIDs getter function for iterable struct mapping
    function getActiveDeveloperIDs() external view returns(uint[] memory result) {
        return activeDeveloperIDs;
    }

    ///@notice necessary ActiveLandIDs getter function for iterable struct mapping
    function getActiveLandIDs() external view returns(uint[] memory result) {
        return activeLandIDs;
    }

    ///@notice necessary vote Address getter function for land Struct
    function getVoteAddressByLandID(uint landID) external view returns(address[] memory result) {
        require(isLandIDValid[landID] == true, "ERR:LR013 INVALID LANDID.");
        Land storage land = getLandByID[landID];
        return land.votedAddresses;
    }

    function getLandAppraisalAmount(uint landID)  external override view returns (uint) {
        require(isLandIDValid[landID] == true, "ERR:LR013 INVALID LANDID.");
        Land storage land = getLandByID[landID];
        return land.appraisalAmount;
    }

    function addUniqueLoanEntityId(uint developerId, uint loanPoolID, uint loanEntityID) override external onlyLPSC {
        require(
            ILoanOriginator(IManagementCompany(MCBoard).LOSCAddress()).getLoanPoolByID(loanPoolID) != address(0),
            "ERR:LR016 LOANPOOL ADDRESS IS 0x0."
        );
        uint uniqueLoanEntityId = getUniqueLoanEntityId(loanPoolID, loanEntityID);
        Developer storage _developer = getDeveloperByID[developerId];
        _developer.myUniqueLoanEntityID.push(uniqueLoanEntityId);
        _developer.myUniqueLoanEntityIDIndex[uniqueLoanEntityId] = _developer.myUniqueLoanEntityID.length - 1;
    }

    function removeUniqueLoanEntityId(uint developerId, uint loanPoolId, uint loanEntityId) override external onlyLPSC {
        require(
            ILoanOriginator(IManagementCompany(MCBoard).LOSCAddress()).getLoanPoolByID(loanPoolId) != address(0),
            "ERR:LR016 LOANPOOL ADDRESS IS 0x0."
        );
        uint uniqueLoanEntityId = getUniqueLoanEntityId(loanPoolId, loanEntityId);
        Developer storage _developer = getDeveloperByID[developerId];

        uint _indexOfLastLoanEntity = _developer.myUniqueLoanEntityID.length - 1;
        uint _lastLoanEntityID = _developer.myUniqueLoanEntityID[_indexOfLastLoanEntity];
        uint _indexOfRemovedLoanEntity = _developer.myUniqueLoanEntityIDIndex[uniqueLoanEntityId];
        // put last loan entity ID to the position where we want to remove
        _developer.myUniqueLoanEntityID[_indexOfRemovedLoanEntity] = _lastLoanEntityID;
        _developer.myUniqueLoanEntityIDIndex[_lastLoanEntityID] = _indexOfRemovedLoanEntity;
        _developer.myUniqueLoanEntityIDIndex[uniqueLoanEntityId] = 0; // move last one to the front and delete last one
        _developer.myUniqueLoanEntityID.pop();
    }

    function getLandRezoningInfo(uint landID) override external view returns (string memory propertyRezonig) {
        require(isLandIDValid[landID] == true, 'ERR:LR013 INVALID LANDID.');
        return getLandByID[landID].propertyZoning;
    }

    function getDeveloperIDByLandID(uint landID) override external view returns (uint developerID) {
        require(isLandIDValid[landID] == true, 'ERR:LR013 INVALID LANDID');
        return getLandByID[landID].developerID;
    }

    function getUniqueLoanEntityId(uint loanPoolId, uint loanEntityId) pure internal returns (uint uniqueLoanEntityId) {
        uniqueLoanEntityId = (loanPoolId << 128) | (loanEntityId);
    }

    function getLoanPoolIDAndEntityIds(uint uniqueLoanEntityId) pure internal returns (uint loanPoolId, uint loanEntityId) {
        loanPoolId = uniqueLoanEntityId >> 128;
        loanEntityId = uniqueLoanEntityId & ((1 << 128) - 1) ;
    }

    ///@notice necessary myActiveLandIDs getter function for iterable struct mapping in the Developer struct
    function getActiveLandIdsByDeveloperId(uint _developerID) external view returns (uint[] memory result) {
        require(isDeveloperIDValid[_developerID], "ERR:LR007 INVALID DEVELOPER ID");

        Developer storage _developer = getDeveloperByID[_developerID];
        return _developer.myActiveLandIDs;
    }

    ///@notice necessary MyUniqueLoanEntityID getter function for iterable struct mapping in the Developer struct
    function getMyUniqueLoanEntityID(uint _developerID) external view returns (uint[] memory result) {
        require(isDeveloperIDValid[_developerID], "ERR:LR007 INVALID DEVELOPER ID");

        Developer storage _developer = getDeveloperByID[_developerID];
        return _developer.myUniqueLoanEntityID;
    }

    ///@notice necessary votedAddresses getter function for iterable struct mapping in the Land struct
    function getVotedAddressByLandID(uint _landID) external view returns (address[] memory result) {
        require(isLandIDValid[_landID], "ERR:LR013 INVALID LANDID");

        Land storage _land = getLandByID[_landID];
        return _land.votedAddresses;
    }

    function getDeveloperNameByID(uint _developerID) override external view returns (string memory) {
        require(isDeveloperIDValid[_developerID], "ERR:LR007 INVALID DEVELOPER ID");
        return getDeveloperByID[_developerID].companyName;
    }

    function getCollateralAddressByID(uint _landID) override external view returns (string memory) {
        require(isLandIDValid[_landID] == true, 'ERR:LR013 INVALID LANDID.');
        return getLandByID[_landID].propertyAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILandRegistration {

    // Land Developer Info
    struct Developer {
        string  companyName;
        string  location;
        string  note;
        uint    developerID;
        uint    totalBorrowableValue;
        uint    totalAmountBorrowed;
        uint[]  myActiveLandIDs;    // active land ID array
        mapping(uint => uint) myIndexOfLands;   // using landID -> index in the above land ID array
        // 128 bits LoanPool ID followed by 128 bits LoanEntity ID, 
        // called unique loan pool id 
        // (assume we have less than 2^128 loan pools and less than 2^128 loan entities per loan pool)
        uint[]  myUniqueLoanEntityID;    
        // unique loanpool ID -> index in the myUniqueLoanEntityID array
        mapping(uint => uint) myUniqueLoanEntityIDIndex;  
    }

    // Land Info
    struct Land {
        // basic info
        uint    propertyIdentificationNumber;
        string  propertyAddress;
        string  propertyZoning;
        string  note;
        bool    isReady;
        // vote related
        address[] votedAddresses;
        uint    landID;
        uint    developerID;
        // appraisal related
        uint    appraisalAmount;
        uint    appraisalDiscountPercent;
        uint    amountBorrowedByDeveloper; 
    }


    /// Developer Related Events
    event NewDeveloperAdded       (uint indexed developerID, string  companyName, string  location, string  note);
    event DeveloperUpdated        (uint indexed developerID, string  companyName, string  location, string  note);
    
    /// Land Related Events
    event NewLandAdded            (
        uint indexed landID, 
        uint propertyIdentificationNumber, 
        string legalDescriptionOfProperty, 
        string typeOfOwnership, 
        string registeredItems, 
        uint developerID);
    event LandBasicInfoUpdated    (
        uint indexed landID, 
        uint propertyIdentificationNumber, 
        string legalDescriptionOfProperty, 
        string typeOfOwnership, 
        string registeredItems);
    event LandAppraisalAddedorUpdated   (
        uint indexed landID, 
        uint appraisalAmount, 
        uint appraisalDiscountInPercent);
    event AmountBorrowedByDeveloperUpdated   (
        uint indexed landID, 
        uint amountBorrowedByDeveloper);
    event LandAppraisalApproved   (
        uint indexed landID, 
        uint newAppraisal);
    /// Developer & Land Delete
    event DeveloperDeleted  (uint indexed developerID); 
    event LandDeleted       (uint indexed landID);

    /// Developer add & update & delete
    /// for developers: no approval needed from MC
    function addNewDeveloper(
        string calldata _companyName, 
        string calldata _location,
        string calldata _note) external;
    function updateDeveloper(
        uint _developerID, 
        string calldata _companyName, 
        string calldata _location,
        string calldata _note) external;

    /// Land add & update & appraisal update
    /// for lands: update basic info and uupdateAppraisalBorrowedByDeveloper() no need to approve
    ///            but for appraisal info update needs approval
    function addNewLand(
        uint _propertyIdentificationNumber, 
        string calldata _legalDescriptionOfProperty, 
        string calldata _typeOfOwnership, 
        string calldata _registeredItems, 
        uint _developerID) external;
    function updateLandBasicInfo(
        uint _landID, 
        uint _propertyIdentificationNumber, 
        string calldata _legalDescriptionOfProperty, 
        string calldata _typeOfOwnership, 
        string calldata _registeredItems) external;
    function addOrUpdateLandAppraisal(
        uint _landID, 
        uint _appraisalAmount, 
        uint _appraisalDiscountInPercent) external;
    // when SPV request draw fund -> accumulate in land info
    function updateAmountBorrowedByDeveloper(uint _landID, uint _amount, uint _decimals, bool isAdd) external;
    function approveLandAppraisal(uint _landID) external;
    
    /// delete developer / land
    function deleteDeveloper(uint _developerID) external;
    function deleteLand(uint _landID) external;

    /// some helper functions to allow other contracts to interact
    function getDeveloperIDByLandID(uint landID) external view returns (uint);
    function isDeveloperIDValid(uint developerID) external view returns (bool);
    function isLandIDValid(uint landID) external view returns (bool);
    function getLandAppraisalAmount(uint landID) external view returns (uint);
    function removeUniqueLoanEntityId(uint developerId, uint myId, uint loanEntityId) external;
    function addUniqueLoanEntityId(uint developerId, uint myId, uint loanEntityId) external;
    function getLandRezoningInfo(uint landID) external view returns (string memory);
    function getDeveloperNameByID(uint developerID) external view returns (string memory);
    function getCollateralAddressByID(uint landID) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IManagementCompany {

    event newAdminProposed              (address indexed proposer, address indexed newPendingAdmin);
    event newSPVWalletAddressProposed   (address indexed proposer, address indexed newSPVWalletAddress);
    event newLRSCAddressProposed        (address indexed proposer, address indexed newLRSCAddress);
    event newLOSCAddressProposed        (address indexed proposer, address indexed newLOSCAddress);
    event newMinApprovalRequiredProposed(address indexed proposer, uint indexed newNumber);
    event newMemberRemovalProposed      (address indexed proposer, address indexed newPendingRemoveMember);

    event newAdminVoted                 (address indexed voter, address indexed newPendingAdmin);
    event newSPVWalletAddressVoted      (address indexed voter, address indexed newSPVWalletAddress);
    event newLRSCAddressVoted           (address indexed voter, address indexed newLRSCAddress);
    event newLOSCAddressVoted           (address indexed voter, address indexed newLOSCAddress);
    event newMinApprovalRequiredVoted   (address indexed voter, uint indexed newNumber);
    event newMemberRemovalVoted         (address indexed voter, address indexed newPendingRemoveMember);

    event newAdminAppended              (address indexed newPendingAdmin);
    event newSPVWalletAddressApproved   (address indexed newSPVWalletAddress);
    event newLRSCAddressApproved        (address indexed newLRSCAddress);
    event newLOSCAddressApproved        (address indexed newLOSCAddress);
    event newMinApprovalRequiredUpdated (uint indexed newNumber);
    event memberRemoved                 (address indexed newPendingRemoveMember);
    event payLoanExecuted               (address indexed proposer, address indexed currency, uint amount, uint loanPoolID, uint loanEntity);
    event debtVoidExecuted              (address indexed proposer, uint indexed payableDebtAmount, uint loanPoolID,uint loanEntity);

    function minApprovalRequired() external view returns (uint);
    function SPVWalletAddress() external view returns (address);
    function LRSCAddress() external view returns (address);
    function LOSCAddress() external view returns (address);
    function isMCAdmin(address admin) external view returns (bool);

    function pendingMinApprovalRequired() external view returns (uint);
    function pendingSPVWalletAddress() external view returns (address);
    function pendingLRSCAddress() external view returns (address);
    function pendingLOSCAddress() external view returns (address);
    function pendingMCBoardMember() external view returns (address);
    function pendingRemoveMember() external view returns (address);

    function proposeNewAdmin(address newAdmin) external;
    function proposeNewSPVWalletAddress(address newAdmin) external;
    function proposeNewLRSCAddress(address newAdmin) external;
    function proposeNewLOSCAddress(address newAdmin) external;
    function proposeNewApprovalRequiredNumber(uint number) external;
    function proposeRemoveAdmin(address adminToBeRemoved) external;
    function payLoanRequest(address currency, uint amount, uint loanPoolID, uint loanEntity) external;
    function debtVoidRequest(uint payableDebtAmount, uint loanPoolID, uint loanEntity) external;

    function voteNewAdmin() external;
    function voteNewSPVWalletAddress() external;
    function voteNewLRSCAddress() external;
    function voteNewLOSCAddress() external;
    function voteNewApprovalRequiredNumber() external;
    function voteRemoveAdmin() external;

    function isVotesSufficient(address[] memory votingFlags) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILoanOriginator {

   event LoanPoolCreated(uint indexed minRate, uint indexed maxRate, address indexed loanPool, uint totalLoanPool);
   event LoanPoolClosed(address indexed loanPool);
   event LoanPoolOpen(address indexed loanPool);
   event LandDrawFund(uint indexed loanPoolID, uint indexed landID, uint closeDate, uint amount, string projectDescription);
   event LoanDebtVoid(uint indexed loanPoolID, uint indexed loanEntityIDuint, uint payableDebtAmount);
  
   function createLoanPool(uint rate1, uint rate2, uint utilizationLimit, address _currency, string calldata _loanPoolName) external;
   function closeLoanPool(uint loanPoolID)  external;
   function openLoanPool(uint loanPoolID)  external;
   
   /// lender operations
   function deposit(uint amount, uint loanPoolID) external;
   function withdraw(uint amountOfPoolToken, uint loanPoolID) external;
   
   /// spv operations
   function drawFund(uint amount, uint loanPoolID, uint landID, uint closeDate, string calldata projectDescription) external;
   function payLoan(uint amount, uint loanPoolID, uint loanEntity) external;
   function debtVoid(uint payableDebtAmount, uint loanPoolID, uint loanEntity) external;

   /// some helper functions to allow other contract to interact with
   function getLoanPoolByID(uint poolID) external view returns (address);
   function isLoanPoolValid(address pool) external view returns (bool);
   function isLoanPoolIDValid(uint poolID) external view returns (bool);
   function getLoanPoolInfoByID(uint poolID) external view returns (string memory, uint, uint, uint, uint, uint, uint, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface ILoanPool {

   // When SPV call drawFund
   struct LoanEntity {
      string loanPoolName;
      uint loanEntityID;
      uint developerID;
      uint landID;
      uint interestRateAPY;
      uint startDate;
      uint closeDate;
      uint lastUpdateDate;
      uint principal;
      uint interestObligated;
      uint totalPaid;
      bool status;
      string projectType;
      string projectDescription;
   }

   // an enum to show the current status
   // once loan origination contract called close loan pool
   // lender cannot deposit anymore but can withdraw
   // spv cannot payLoan and cannot drawFund
   enum poolStatus {Opening, Closed}

   event LoanPoolInitialized(uint minRate, uint maxRate, uint utilizationLimitRate, address indexed currency, address indexed MCBoard, uint myId, string loanPoolName);
   event LenderDeposited(address indexed loanPool_address, address indexed lender, address indexed token, uint amount);
   event LenderWithdrawed(address indexed loanPool_address, address indexed lender, address indexed token, uint amount);
   event SPVDrawed(address indexed loanPool_address, address indexed borrower, address indexed token, uint amount);
   event MCRepayed(address indexed loanPool_address, address indexed borrower, address indexed token, uint amount);

   function initialize(uint _minRate, uint _maxRate, uint _utilizationLimitRate, address _currency, address _MCBoard, uint _myId, string calldata _loanPoolName) external;
   function close() external;
   function open() external;
   
   ///@notice lender operations
   function deposit(address from, uint amount) external;
   function withdraw(address to, uint amount) external;
   
   ///@notice SPV operations, only spv wallet can call
   function payLoan(uint amount, uint loanEntityID, address managementCompany) external returns (uint loanDeduction);
   function drawFund(uint landID, address spvwallet, uint amount, uint closeDate, string calldata projectDescription) external;
   function debtVoid(uint loanEntityID, uint payableDebtAmount, address managementCompany) external returns (uint loanDeduction);

   /// some helper functions to allow other contracts to interact
   function getLengthOfActiveLoanEntityIDs() external returns (uint);
   function callgetLoanEntityIDsByLandID(uint landID) external view returns (uint[] memory);
   function getTotalDebtByLandID(uint landID) external view returns (uint totalDebt);
   function getLoanEntityDebtInfo(uint loanID) external view returns (uint);
   function getloanEntityLandID(uint landID) external view returns (uint);
   function currency() external view returns (address);
   function refreshAllLoansByLandID(uint landID) external returns (uint);
   function getLoanEntityStatus(uint _loanID) external view returns (bool loanStatus);

   function getLoanPoolInfo() external view returns (string memory, uint, uint, uint, uint, uint, uint, address);
   function getLoanEntityViewByLoanEntityID(uint loanID) external view returns (
      string memory loanPoolName_,
      uint landID,
      string memory borrower,
      string memory collateral,
      uint interestRateAPY,
      uint closeDate,
      uint principal,
      string memory projectType);

   function getLoanEntityPaymentInfoByLoanEntityID(uint _loanID) external view returns (
      uint principal,
      uint interestObligated,
      uint totalPaid
   );
}

// SPDX-License-Identifier: MIT

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}