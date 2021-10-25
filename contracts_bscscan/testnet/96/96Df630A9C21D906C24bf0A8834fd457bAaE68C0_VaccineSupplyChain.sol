pragma solidity ^0.8.7;
import "./VaccineSystemStorage.sol";
import "./Ownable.sol";

contract VaccineSupplyChain is Ownable {
    event CompleteBasicDetail(address indexed user, address indexed batchNo);
    event CompleteWarehouser(address indexed user, address indexed batchNo);
    event CompleteDistributor(address indexed user, address indexed batchNo);
    event CompleteVaccinationStation(
        address indexed user,
        address indexed batchNo
    );
    event CompleteVaccinatePerson(
        address indexed user,
        address indexed batchNo
    );

    /* Declare Modifier */
    modifier isValidPerformer(address batchNo, string memory role) {
        require(
            keccak256(
                abi.encodePacked(vaccineSystemStorage.getUserRole(msg.sender))
            ) == keccak256(abi.encodePacked(role))
        );
        require(
            keccak256(
                abi.encodePacked(vaccineSystemStorage.getNextAction(batchNo))
            ) == keccak256(abi.encodePacked(role))
        );
        _;
    }

    /* Storage Variables */
    VaccineSystemStorage vaccineSystemStorage;

    constructor(address _vaccineSystemAddress) public {
        vaccineSystemStorage = VaccineSystemStorage(_vaccineSystemAddress);
    }

    function getBalance() public returns (uint256) {
        return (address(this).balance);
    }

    /* Get Next Action */

    function getNextAction(address _batchNo)
        public
        view
        returns (string memory action)
    {
        (action) = vaccineSystemStorage.getNextAction(_batchNo);
        return (action);
    }

    /* Get Basic Details */
    function getBasicDetailsData(address _batchNo)
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
        /* Call Storage Contract */
        (
            producerName,
            storageName,
            distributorName,
            vaccinationStationName,
            totalWeight
        ) = vaccineSystemStorage.getBasicDetails(_batchNo);
        return (
            producerName,
            storageName,
            distributorName,
            vaccinationStationName,
            totalWeight
        );
    }

    /* Add Basic Details */
    function addBasicDetails(
        string memory _producerName,
        string memory _storageName,
        string memory _distributorName,
        string memory _vaccinationStationName,
        uint256 _totalWeight
    ) public onlyOwner returns (address) {
        address batchNo = vaccineSystemStorage.setBasicDetails(
            _producerName,
            _storageName,
            _distributorName,
            _vaccinationStationName,
            _totalWeight
        );

        /* Call Emit Event */
        emit CompleteBasicDetail(msg.sender, batchNo);

        return batchNo;
    }

    /* Get Warehouser */
    function getWarehouserData(address _batchNo)
        public
        view
        returns (
            string memory vaccineName,
            uint256 quantity,
            uint256 price,
            uint256 optimumTemp,
            uint256 optimumHum,
            uint256 storageDate,
            bool isViolation
        )
    {
        /* Call Storage Contract */
        (
            vaccineName,
            quantity,
            price,
            optimumTemp,
            optimumHum,
            storageDate,
            isViolation
        ) = vaccineSystemStorage.getWarehouserData(_batchNo);
        return (
            vaccineName,
            quantity,
            price,
            optimumTemp,
            optimumHum,
            storageDate,
            isViolation
        );
    }

    /* Update Warehouser */
    function updateWarehouser(
        address _batchNo,
        string memory _vaccineName,
        uint256 _quantity,
        uint256 _price,
        uint256 _optimumTemp,
        uint256 _optimumHum,
        uint256 _storageDate,
        bool _isViolation
    ) public isValidPerformer(_batchNo, "WAREHOUSER") returns (bool) {
        bool status = vaccineSystemStorage.setWarehouser(
            _batchNo,
            _vaccineName,
            _quantity,
            _price,
            _storageDate,
            _optimumTemp,
            _optimumHum,
            _isViolation
        );

        emit CompleteWarehouser(msg.sender, _batchNo);
        return (status);
    }

    /* Get Distributor */
    function getDistributorData(address _batchNo)
        public
        view
        returns (
            string memory shippingName,
            string memory shippingNo,
            uint256 quantity,
            uint256 departureDateTime,
            uint256 estimateDateTime,
            uint256 distributorId,
            uint256 optimumTemp,
            uint256 optimumHum
        )
    {
        /* Call Storage Contract */
        (
            shippingName,
            shippingNo,
            quantity,
            departureDateTime,
            estimateDateTime,
            distributorId,
            optimumTemp,
            optimumHum
        ) = vaccineSystemStorage.getDistributorData(_batchNo);
        return (
            shippingName,
            shippingNo,
            quantity,
            departureDateTime,
            estimateDateTime,
            distributorId,
            optimumTemp,
            optimumHum
        );
    }

    /* Update Distributor */
    function updateDistributorData(
        address _batchNo,
        string memory _shippingName,
        string memory _shippingNo,
        uint256 _quantity,
        uint256 _departureDateTime,
        uint256 _estimateDateTime,
        uint256 _distributorId,
        uint256 _optimumTemp,
        uint256 _optimumHum
    ) public isValidPerformer(_batchNo, "DISTRIBUTOR") returns (bool) {
        bool status = vaccineSystemStorage.setDistributor(
            _batchNo,
            _shippingName,
            _shippingNo,
            _quantity,
            _departureDateTime,
            _estimateDateTime,
            _distributorId,
            _optimumTemp,
            _optimumHum
        );
        emit CompleteDistributor(msg.sender, _batchNo);

        return (status);
    }

    /* Get Vaccination Station */
    function getVaccinationStation(address _batchNo)
        public
        view
        returns (
            uint256 quantity,
            uint256 arrivalDateTime,
            uint256 vaccinationStationId,
            string memory shippingName,
            string memory shippingNo
        )
    {
        /* Call Storage Contract */
        (
            quantity,
            arrivalDateTime,
            vaccinationStationId,
            shippingName,
            shippingNo
        ) = vaccineSystemStorage.getVaccinationStationData(_batchNo);

        return (
            quantity,
            arrivalDateTime,
            vaccinationStationId,
            shippingName,
            shippingNo
        );
    }

    /* Update Vaccination Station */
    function updateVaccinationStation(
        address _batchNo,
        uint256 _quantity,
        uint256 _arrivalDateTime,
        uint256 _vaccinationStationId,
        string memory _shippingName,
        string memory _shippingNo
    ) public isValidPerformer(_batchNo, "VACCINATION_STATION") returns (bool) {
        bool status = vaccineSystemStorage.setVaccinationStation(
            _batchNo,
            _quantity,
            _arrivalDateTime,
            _vaccinationStationId,
            _shippingName,
            _shippingNo
        );

        /* Emit Event */
        emit CompleteVaccinationStation(msg.sender, _batchNo);
        return (status);
    }

    /* Get Vaccinate Person Data */
    function getVaccinateData(address _batchNo)
        public
        view
        returns (
            string memory personName,
            uint256 age,
            uint256 identityCard,
            uint256 numberOfVaccinations,
            uint256 vaccinationDate,
            string memory typeOfVaccine
        )
    {
        /* Call Storage Contract */
        (
            personName,
            age,
            identityCard,
            numberOfVaccinations,
            vaccinationDate,
            typeOfVaccine
        ) = vaccineSystemStorage.getVaccinationPersonData(_batchNo);

        return (
            personName,
            age,
            identityCard,
            numberOfVaccinations,
            vaccinationDate,
            typeOfVaccine
        );
    }

    /* Update Vaccinate Person */
    function updateVaccinatePerson(
        address _batchNo,
        string memory _personName,
        uint256 _age,
        uint256 _identityCard,
        uint256 _numberOfVaccinations,
        uint256 _vaccinationDate,
        string memory _typeOfVaccine
    ) public isValidPerformer(_batchNo, "OBJECT_INJECTION") returns (bool) {
        bool status = vaccineSystemStorage.setObjectInjection(
            _batchNo,
            _personName,
            _age,
            _identityCard,
            _numberOfVaccinations,
            _vaccinationDate,
            _typeOfVaccine
        );

        /* Emit Event */
        emit CompleteVaccinatePerson(msg.sender, _batchNo);
        return (status);
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