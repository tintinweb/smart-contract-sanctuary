pragma solidity ^0.8.7;
import "./VaccineSystemStorage.sol";
import "./Ownable.sol";

contract VaccineUserAttend is Ownable {
    /* Event Declare */
    event UserUpdate(
        address indexed user,
        string name,
        string contactNo,
        string role,
        bool isActive,
        string profileHash
    );
    event UserRoleUpdate(address indexed user, string role);

    /* Storage Variable */
    VaccineSystemStorage vaccineSystemStorage;

    constructor(address _vaccineSystemAddress) {
        vaccineSystemStorage = VaccineSystemStorage(_vaccineSystemAddress);
    }

    /* Create/Update An User */
    function updateUser(
        string memory _name,
        string memory _contactNo,
        string memory _role,
        bool _isActive,
        string memory _profileHash
    ) public returns (bool) {
        require(msg.sender != address(0), "User Is In Valid");

        /* Call Storage COntract */
        bool status = vaccineSystemStorage.setUser(
            msg.sender,
            _name,
            _contactNo,
            _role,
            _isActive,
            _profileHash
        );

        /* Call Event */
        emit UserUpdate(
            msg.sender,
            _name,
            _contactNo,
            _role,
            _isActive,
            _profileHash
        );

        emit UserRoleUpdate(msg.sender, _role);

        return status;
    }

    /* Create/Update User For Admin */
    function updateUserForAdmin(
        address _userAddress,
        string memory _name,
        string memory _contactNo,
        string memory _role,
        bool _isActive,
        string memory _profileHash
    ) public onlyOwner returns (bool) {
        require(_userAddress != address(0));

        /* Call Storage Contract */
        bool status = vaccineSystemStorage.setUser(
            _userAddress,
            _name,
            _contactNo,
            _role,
            _isActive,
            _profileHash
        );

        /* Call Event */
        /* Call Event */
        emit UserUpdate(
            _userAddress,
            _name,
            _contactNo,
            _role,
            _isActive,
            _profileHash
        );

        emit UserRoleUpdate(msg.sender, _role);

        return status;
    }

    /* Get User */
    function getUser(address _userAddress) public view returns(
        string memory name,
        string memory contactNo,
        string memory role,
        bool isActive,
        string memory profileHash
    ) {
        require(_userAddress != address(0), "User Address Is Invalid");

        /* Getting value from struct */
        (name, contactNo, role, isActive, profileHash) = vaccineSystemStorage.getUser(_userAddress);
        return (name, contactNo, role, isActive, profileHash);
    }
}

pragma solidity ^0.8.7;

import "./Ownable.sol";

contract VaccineSystemStorage is Ownable {
    address public lastAccess;

    constructor() public {
        authorizedCaller[msg.sender] = 1;
    }

    /* Declare Events */
    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);

    /* Declare Modifiers */
    modifier onlyAuthCaller() {
        lastAccess = msg.sender;
        require(authorizedCaller[msg.sender] == 1);
        _;
    }

    /* Caller Mapping */
    mapping(address => uint8) authorizedCaller;

    /* User Interface */
    struct user {
        string name;
        string contactNo;
        bool isActive;
        string profileHash;
    }

    mapping(address => user) userDetails;
    mapping(address => string) userRole;

    /* Authorized Caller */
    function authorizeCaller(address _caller) public onlyOwner returns (bool) {
        authorizedCaller[_caller] = 1;
        emit AuthorizedCaller(_caller);
        return true;
    }

    /* De-Authorized Caller */
    function deAuthorizeCaller(address _caller)
        public
        onlyOwner
        returns (bool)
    {
        authorizedCaller[_caller] = 0;
        emit DeAuthorizedCaller(_caller);
        return true;
    }

    struct basicDetails {
        string producerName;
        string storageName;
        string distributorName;
        string vaccinationStationName;
        uint256 totalWeight;
    }

    struct warehouser {
        string vaccineName;
        uint256 quantity;
        uint256 price;
        uint256 storageDate;
        uint256 optimumTemp;
        uint256 optimumHum;
        bool isViolation;
        uint256 warehouserId;
    }

    struct distributor {
        string destinationAddress;
        string shippingName;
        string shippingNo;
        uint256 quantity;
        uint256 departureDateTime;
        uint256 estimateDateTime;
        uint256 optimumTemp;
        uint256 optimumHum;
        bool isViolation;
        uint256 distributorId;
    }

    struct vaccinationStation {
        uint256 quantity;
        uint256 arrivalDateTime;
        uint256 vaccinationStationId;
        string shippingName;
        string shippingNo;
    }

    struct vaccinatedPerson {
        string personName;
        uint256 age;
        uint256 identityCard;
        uint256 numberOfVaccinations;
        uint256 vaccinationDate;
        string typeOfVaccine;
    }

    mapping(address => basicDetails) batchBasicDetails;
    mapping(address => warehouser) batchWarehouser;
    mapping(address => distributor) batchDistributor;
    mapping(address => vaccinationStation) batchVaccinationStation;
    mapping(address => vaccinatedPerson) batchVaccinatedPerson;
    mapping(address => string) nextAction;

    /* Init Struct Pointer */
    user userDetail;
    basicDetails basicDetailsData;
    warehouser warehouserData;
    distributor distributorData;
    vaccinationStation vaccinationStationData;
    vaccinatedPerson vaccinatedPersonData;

    /* Get User Role */
    function getUserRole(address _userAddress)
        public
        view
        returns (string memory)
    {
        return userRole[_userAddress];
    }

    /* Get Next Action */
    function getNextAction(address _batchNo)
        public
        view
        returns (string memory)
    {
        return nextAction[_batchNo];
    }

    /* Set User Detail */
    function setUser(
        address _userAddress,
        string memory _name,
        string memory _contactNo,
        string memory _role,
        bool _isActive,
        string memory _profileHash
    ) public onlyAuthCaller returns (bool) {
        /* Store Data User Into Struct - User */
        userDetail.name = _name;
        userDetail.contactNo = _contactNo;
        userDetail.isActive = _isActive;
        userDetail.profileHash = _profileHash;

        /* Store Data User Into Mapping - User */
        userDetails[_userAddress] = userDetail;
        userRole[_userAddress] = _role;

        return true;
    }

    /* Get User details */
    function getUser(address _userAddress)
        public
        view
        returns (
            string memory name,
            string memory contactNo,
            string memory role,
            bool isActive,
            string memory profileHash
        )
    {
        /* Get User Value From Struct */
        user memory tmpData = userDetails[_userAddress];

        return (
            tmpData.name,
            tmpData.contactNo,
            userRole[_userAddress],
            tmpData.isActive,
            tmpData.profileHash
        );
    }

    /* Get Batch Basic Details */
    function getBasicDetails(address _batchNo)
        public
        view
        returns (
            string memory producerName,
            string memory storageName,
            string memory distributorName,
            string memory vaccinationStationName,
            uint256 totalWeight
        )
    {
        basicDetails memory tmpData = batchBasicDetails[_batchNo];

        return (
            tmpData.producerName,
            tmpData.storageName,
            tmpData.distributorName,
            tmpData.vaccinationStationName,
            tmpData.totalWeight
        );
    }

    /* Set Batch Basic Detail */
    function setBasicDetails(
        string memory _producerName,
        string memory _storageName,
        string memory _distributorName,
        string memory _vaccinationStationName,
        uint256 _totalWeight
    ) public onlyAuthCaller returns (address) {
        address batchNo = address(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(msg.sender, block.timestamp))
                )
            )
        );

        basicDetailsData.producerName = _producerName;
        basicDetailsData.storageName = _storageName;
        basicDetailsData.distributorName = _distributorName;
        basicDetailsData.vaccinationStationName = _vaccinationStationName;
        basicDetailsData.totalWeight = _totalWeight;

        batchBasicDetails[batchNo] = basicDetailsData;

        nextAction[batchNo] = "WAREHOUSER";
        return batchNo;
    }

    /* Set Warehouser */
    function setWarehouser(
        address batchNo,
        string memory _vaccineName,
        uint256 _quantity,
        uint256 _price,
        uint256 _storageDate,
        uint256 _optimumTemp,
        uint256 _optimumHum,
        bool _isViolation
    ) public onlyAuthCaller returns (bool) {
        warehouserData.vaccineName = _vaccineName;
        warehouserData.quantity = _quantity;
        warehouserData.price = _price;
        warehouserData.storageDate = _storageDate;
        warehouserData.optimumTemp = _optimumTemp;
        warehouserData.optimumHum = _optimumHum;
        warehouserData.isViolation = _isViolation;

        batchWarehouser[batchNo] = warehouserData;

        nextAction[batchNo] = "DISTRIBUTOR";

        return true;
    }

    /* Get Warehouser */
    function getWarehouserData(address batchNo)
        public
        view
        returns (
            string memory vaccineName,
            uint256 quantity,
            uint256 price,
            uint256 storageDate,
            uint256 optimumTemp,
            uint256 optimumHum,
            bool isViolation
        )
    {
        warehouser memory tmpData = batchWarehouser[batchNo];

        return (
            tmpData.vaccineName,
            tmpData.quantity,
            tmpData.price,
            tmpData.storageDate,
            tmpData.optimumTemp,
            tmpData.optimumHum,
            tmpData.isViolation
        );
    }

    /* Set Distributor */
    function setDistributor(
        address batchNo,
        string memory _shippingName,
        string memory _shippingNo,
        uint256 _quantity,
        uint256 _departureDateTime, 
        uint256 _estimateDateTime,
        uint256 _distributorId,
        uint256 _optimumTemp,
        uint256 _optimumHum
    ) public onlyAuthCaller returns (bool) {
        distributorData.shippingName = _shippingName;
        distributorData.shippingNo = _shippingNo;
        distributorData.quantity = _quantity;
        distributorData.departureDateTime = _departureDateTime;
        distributorData.estimateDateTime = _estimateDateTime;
        distributorData.distributorId = _distributorId;
        distributorData.optimumTemp = _optimumTemp;
        distributorData.optimumHum = _optimumHum;

        batchDistributor[batchNo] = distributorData;

        nextAction[batchNo] = "VACCINATION_STATION";

        return true;
    }

    /* Get Distributor Data */
    function getDistributorData(address batchNo) public view returns(
        string memory shippingName,
        string memory shippingNo,
        uint256 quantity,
        uint256 departureDateTime,
        uint256 estimateDateTime,
        uint256 distributorId,
        uint256 optimumTemp,
        uint256 optimumHum
    ) {
        distributor memory tmpData = batchDistributor[batchNo];

        return (
            tmpData.shippingName,
            tmpData.shippingNo,
            tmpData.quantity,
            tmpData.departureDateTime,
            tmpData.estimateDateTime,
            tmpData.distributorId,
            tmpData.optimumTemp,
            tmpData.optimumHum
        );
    }

    /* Set Vaccination Station */
    function setVaccinationStation(
        address batchNo,
        uint256 _quantity,
        uint256 _arrivalDateTime,
        uint256 _vaccinationStationId,
        string memory _shippingName,
        string memory _shippingNo
    ) public onlyAuthCaller returns(bool) {
        vaccinationStationData.quantity = _quantity;
        vaccinationStationData.arrivalDateTime = _arrivalDateTime;
        vaccinationStationData.vaccinationStationId = _vaccinationStationId;
        vaccinationStationData.shippingName = _shippingName;
        vaccinationStationData.shippingNo = _shippingNo;

        batchVaccinationStation[batchNo] = vaccinationStationData;

        nextAction[batchNo] = "OBJECT_INJECTION";

        return true;
    }

    /* Get Vaccination Station Data */
    function getVaccinationStationData(address batchNo) public view returns (
        uint256 quantity,
        uint256 arrivalDateTime,
        uint256 vaccinationStationId,
        string memory shippingName,
        string memory shippingNo
    ) {
        vaccinationStation memory tmpData = batchVaccinationStation[batchNo];

        return (
            tmpData.quantity,
            tmpData.arrivalDateTime,
            tmpData.vaccinationStationId,
            tmpData.shippingName,
            tmpData.shippingNo
        );
    }

    /* Set Vaccinated Person*/
    function setObjectInjection(
        address batchNo, 
        string memory _personName,
        uint256 _age,
        uint256 _identityCard,
        uint256 _numberOfVaccinations,
        uint256 _vaccinationDate,
        string memory _typeOfVaccine
    ) public onlyAuthCaller returns (bool) {
        vaccinatedPersonData.personName = _personName;
        vaccinatedPersonData.age = _age;
        vaccinatedPersonData.identityCard = _identityCard;
        vaccinatedPersonData.numberOfVaccinations = _numberOfVaccinations;
        vaccinatedPersonData.vaccinationDate = _vaccinationDate;
        vaccinatedPersonData.typeOfVaccine = _typeOfVaccine;

        batchVaccinatedPerson[batchNo] = vaccinatedPersonData;

        nextAction[batchNo] = "DONE";

        return true;
    }

    /* Get Vaccinated Person Data */
    function getVaccinationPersonData(address batchNo) public view returns (
        string memory personName,
        uint256 age,
        uint256 identityCard,
        uint256 numberOfVaccinations,
        uint256 vaccinationDate,
        string memory typeOfVaccine
    ) {
        vaccinatedPerson memory tmpData = batchVaccinatedPerson[batchNo];

        return (
            tmpData.personName,
            tmpData.age,
            tmpData.identityCard,
            tmpData.numberOfVaccinations,
            tmpData.vaccinationDate,
            tmpData.typeOfVaccine
        );
    }
}

pragma solidity ^0.8.7;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}