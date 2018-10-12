pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

// File: contracts/ontology/CvcOntologyInterface.sol

/**
 * @title CvcOntologyInterface
 * @dev This contract defines marketplace ontology registry interface.
 */
contract CvcOntologyInterface {

    struct CredentialItem {
        bytes32 id;
        string recordType;
        string recordName;
        string recordVersion;
        string reference;
        string referenceType;
        bytes32 referenceHash;
    }

    /**
     * @dev Adds new Credential Item to the registry.
     * @param _recordType Credential Item type
     * @param _recordName Credential Item name
     * @param _recordVersion Credential Item version
     * @param _reference Credential Item reference URL
     * @param _referenceType Credential Item reference type
     * @param _referenceHash Credential Item reference hash
     */
    function add(
        string _recordType,
        string _recordName,
        string _recordVersion,
        string _reference,
        string _referenceType,
        bytes32 _referenceHash
        ) external;

    /**
    * @dev Deprecates single Credential Item by external ID (type, name and version).
    * @param _type Record type to deprecate
    * @param _name Record name to deprecate
    * @param _version Record version to deprecate
    */
    function deprecate(string _type, string _name, string _version) public;

    /**
    * @dev Deprecates single Credential Item by ID.
    * @param _id Record ID to deprecate
    */
    function deprecateById(bytes32 _id) public;

    /**
     * @dev Returns single Credential Item data up by ontology record ID.
     * @param _id Ontology record ID to search by
     * @return id Ontology record ID
     * @return recordType Credential Item type
     * @return recordName Credential Item name
     * @return recordVersion Credential Item version
     * @return reference Credential Item reference URL
     * @return referenceType Credential Item reference type
     * @return referenceHash Credential Item reference hash
     * @return deprecated Credential Item type deprecation flag
     */
    function getById(bytes32 _id) public view returns (
        bytes32 id,
        string recordType,
        string recordName,
        string recordVersion,
        string reference,
        string referenceType,
        bytes32 referenceHash,
        bool deprecated
        );

    /**
     * @dev Returns single Credential Item of specific type, name and version.
     * @param _type Credential Item type
     * @param _name Credential Item name
     * @param _version Credential Item version
     * @return id Ontology record ID
     * @return recordType Credential Item type
     * @return recordName Credential Item name
     * @return recordVersion Credential Item version
     * @return reference Credential Item reference URL
     * @return referenceType Credential Item reference type
     * @return referenceHash Credential Item reference hash
     * @return deprecated Credential Item type deprecation flag
     */
    function getByTypeNameVersion(
        string _type,
        string _name,
        string _version
        ) public view returns (
            bytes32 id,
            string recordType,
            string recordName,
            string recordVersion,
            string reference,
            string referenceType,
            bytes32 referenceHash,
            bool deprecated
        );

    /**
     * @dev Returns all IDs of registered Credential Items.
     * @return bytes32[]
     */
    function getAllIds() public view returns (bytes32[]);

    /**
     * @dev Returns all registered Credential Items.
     * @return bytes32[]
     */
    function getAll() public view returns (CredentialItem[]);
}

// File: contracts/upgradeability/EternalStorage.sol

/**
 * @title EternalStorage
 * @dev This contract defines the generic storage structure
 * so that it could be re-used to implement any domain specific storage functionality
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => bytes32) internal bytes32Storage;

}

// File: contracts/upgradeability/ImplementationStorage.sol

/**
 * @title ImplementationStorage
 * @dev This contract stores proxy implementation address.
 */
contract ImplementationStorage {

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "cvc.proxy.implementation", and is validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0xa490aab0d89837371982f93f57ffd20c47991f88066ef92475bc8233036969bb;

    /**
    * @dev Constructor
    */
    constructor() public {
        assert(IMPLEMENTATION_SLOT == keccak256("cvc.proxy.implementation"));
    }

    /**
     * @dev Returns the current implementation.
     * @return Address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}

// File: contracts/upgradeability/Initializable.sol

/**
 * @title Initializable
 * @dev This contract provides basic initialization control
 */
contract Initializable is EternalStorage, ImplementationStorage {

    /**
    Data structures and storage layout:
    mapping(bytes32 => bool) initialized;
    **/

    /**
     * @dev Throws if called before contract was initialized.
     */
    modifier onlyInitialized() {
        // require(initialized[implementation()]);
        require(boolStorage[keccak256(abi.encodePacked(implementation(), "initialized"))], "Contract is not initialized");
        _;
    }

    /**
     * @dev Controls the initialization state, allowing to call an initialization function only once.
     */
    modifier initializes() {
        address impl = implementation();
        // require(!initialized[implementation()]);
        require(!boolStorage[keccak256(abi.encodePacked(impl, "initialized"))], "Contract is already initialized");
        _;
        // initialized[implementation()] = true;
        boolStorage[keccak256(abi.encodePacked(impl, "initialized"))] = true;
    }
}

// File: contracts/upgradeability/Ownable.sol

/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {

    /**
    Data structures and storage layout:
    address owner;
    **/

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner(), "Message sender must be contract admin");
        _;
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        // return owner;
        return addressStorage[keccak256("owner")];
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner the address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Contract owner cannot be zero address");
        setOwner(newOwner);
    }

    /**
     * @dev Sets a new owner address
     */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        // owner = newOwner;
        addressStorage[keccak256("owner")] = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/ontology/CvcOntology.sol

/**
 * @title CvcOntology
 * @dev This contract holds the list of all recognized Credential Items available for sale.
 */
contract CvcOntology is EternalStorage, Initializable, Ownable, CvcOntologyInterface {

    using SafeMath for uint256;

    /**
    Data structures and storage layout:
    struct CredentialItem {
        string type; // "claim" or "credential"
        string name; // e.g. "proofOfIdentity"
        string version; // e.g. "v1.2"
        string reference; // e.g. "https://example.com/credential-proofOfIdentity-v1_2.json"
        string referenceType; // e.g. "JSON-LD-Context"
        bytes32 referenceHash; // e.g. "0x2cd9bf92c5e20b1b410f5ace94d963a96e89156fbe65b70365e8596b37f1f165"
        bool deprecated; // e.g. false
    }
    uint256 recordsCount;
    bytes32[] recordsIds;
    mapping(bytes32 => CredentialItem) records;
    **/

    /**
     * Constructor to initialize with some default values
     */
    constructor() public {
        initialize(msg.sender);
    }

    /**
     * @dev Adds new Credential Item to the registry.
     * @param _recordType Credential Item type
     * @param _recordName Credential Item name
     * @param _recordVersion Credential Item version
     * @param _reference Credential Item reference URL
     * @param _referenceType Credential Item reference type
     * @param _referenceHash Credential Item reference hash
     */
    function add(
        string _recordType,
        string _recordName,
        string _recordVersion,
        string _reference,
        string _referenceType,
        bytes32 _referenceHash
    ) external onlyInitialized onlyOwner {
        require(bytes(_recordType).length > 0, "Empty credential item type");
        require(bytes(_recordName).length > 0, "Empty credential item name");
        require(bytes(_recordVersion).length > 0, "Empty credential item version");
        require(bytes(_reference).length > 0, "Empty credential item reference");
        require(bytes(_referenceType).length > 0, "Empty credential item type");
        require(_referenceHash != 0x0, "Empty credential item reference hash");

        bytes32 id = calculateId(_recordType, _recordName, _recordVersion);

        require(getReferenceHash(id) == 0x0, "Credential item record already exists");

        setType(id, _recordType);
        setName(id, _recordName);
        setVersion(id, _recordVersion);
        setReference(id, _reference);
        setReferenceType(id, _referenceType);
        setReferenceHash(id, _referenceHash);
        setRecordId(getCount(), id);
        incrementCount();
    }

    /**
     * @dev Contract initialization method.
     * @param _owner Contract owner address
     */
    function initialize(address _owner) public initializes {
        setOwner(_owner);
    }

    /**
    * @dev Deprecates single Credential Item of specific type, name and version.
    * @param _type Record type to deprecate
    * @param _name Record name to deprecate
    * @param _version Record version to deprecate
    */
    function deprecate(string _type, string _name, string _version) public onlyInitialized onlyOwner {
        deprecateById(calculateId(_type, _name, _version));
    }

    /**
    * @dev Deprecates single Credential Item by ontology record ID.
    * @param _id Ontology record ID
    */
    function deprecateById(bytes32 _id) public onlyInitialized onlyOwner {
        require(getReferenceHash(_id) != 0x0, "Cannot deprecate unknown credential item");
        require(getDeprecated(_id) == false, "Credential item is already deprecated");
        setDeprecated(_id);
    }

    /**
     * @dev Returns single Credential Item data up by ontology record ID.
     * @param _id Ontology record ID to search by
     * @return id Ontology record ID
     * @return recordType Credential Item type
     * @return recordName Credential Item name
     * @return recordVersion Credential Item version
     * @return reference Credential Item reference URL
     * @return referenceType Credential Item reference type
     * @return referenceHash Credential Item reference hash
     * @return deprecated Credential Item type deprecation flag
     */
    function getById(
        bytes32 _id
    ) public view onlyInitialized returns (
        bytes32 id,
        string recordType,
        string recordName,
        string recordVersion,
        string reference,
        string referenceType,
        bytes32 referenceHash,
        bool deprecated
    ) {
        referenceHash = getReferenceHash(_id);
        if (referenceHash != 0x0) {
            recordType = getType(_id);
            recordName = getName(_id);
            recordVersion = getVersion(_id);
            reference = getReference(_id);
            referenceType = getReferenceType(_id);
            deprecated = getDeprecated(_id);
            id = _id;
        }
    }

    /**
     * @dev Returns single Credential Item of specific type, name and version.
     * @param _type Credential Item type
     * @param _name Credential Item name
     * @param _version Credential Item version
     * @return id Ontology record ID
     * @return recordType Credential Item type
     * @return recordName Credential Item name
     * @return recordVersion Credential Item version
     * @return reference Credential Item reference URL
     * @return referenceType Credential Item reference type
     * @return referenceHash Credential Item reference hash
     * @return deprecated Credential Item type deprecation flag
     */
    function getByTypeNameVersion(
        string _type,
        string _name,
        string _version
    ) public view onlyInitialized returns (
        bytes32 id,
        string recordType,
        string recordName,
        string recordVersion,
        string reference,
        string referenceType,
        bytes32 referenceHash,
        bool deprecated
    ) {
        return getById(calculateId(_type, _name, _version));
    }

    /**
     * @dev Returns all records. Currently is supported only from internal calls.
     * @return CredentialItem[]
     */
    function getAll() public view onlyInitialized returns (CredentialItem[]) {
        uint256 count = getCount();
        bytes32 id;
        CredentialItem[] memory records = new CredentialItem[](count);
        for (uint256 i = 0; i < count; i++) {
            id = getRecordId(i);
            records[i] = CredentialItem(
                id,
                getType(id),
                getName(id),
                getVersion(id),
                getReference(id),
                getReferenceType(id),
                getReferenceHash(id)
            );
        }

        return records;
    }

    /**
     * @dev Returns all ontology record IDs.
     * Could be used from web3.js to retrieve the list of all records.
     * @return bytes32[]
     */
    function getAllIds() public view onlyInitialized returns(bytes32[]) {
        uint256 count = getCount();
        bytes32[] memory ids = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = getRecordId(i);
        }

        return ids;
    }

    /**
     * @dev Returns the number of registered ontology records.
     * @return uint256
     */
    function getCount() internal view returns (uint256) {
        // return recordsCount;
        return uintStorage[keccak256("records.count")];
    }

    /**
    * @dev Increments total record count.
    */
    function incrementCount() internal {
        // recordsCount = getCount().add(1);
        uintStorage[keccak256("records.count")] = getCount().add(1);
    }

    /**
     * @dev Returns the ontology record ID by numeric index.
     * @return bytes32
     */
    function getRecordId(uint256 _index) internal view returns (bytes32) {
        // return recordsIds[_index];
        return bytes32Storage[keccak256(abi.encodePacked("records.ids.", _index))];
    }

    /**
    * @dev Saves ontology record ID against the index.
    * @param _index Numeric index.
    * @param _id Ontology record ID.
    */
    function setRecordId(uint256 _index, bytes32 _id) internal {
        // recordsIds[_index] = _id;
        bytes32Storage[keccak256(abi.encodePacked("records.ids.", _index))] = _id;
    }

    /**
     * @dev Returns the Credential Item type.
     * @return string
     */
    function getType(bytes32 _id) internal view returns (string) {
        // return records[_id].type;
        return stringStorage[keccak256(abi.encodePacked("records.", _id, ".type"))];
    }

    /**
    * @dev Saves Credential Item type.
    * @param _id Ontology record ID.
    * @param _type Credential Item type.
    */
    function setType(bytes32 _id, string _type) internal {
        // records[_id].type = _type;
        stringStorage[keccak256(abi.encodePacked("records.", _id, ".type"))] = _type;
    }

    /**
     * @dev Returns the Credential Item name.
     * @return string
     */
    function getName(bytes32 _id) internal view returns (string) {
        // records[_id].name;
        return stringStorage[keccak256(abi.encodePacked("records.", _id, ".name"))];
    }

    /**
    * @dev Saves Credential Item name.
    * @param _id Ontology record ID.
    * @param _name Credential Item name.
    */
    function setName(bytes32 _id, string _name) internal {
        // records[_id].name = _name;
        stringStorage[keccak256(abi.encodePacked("records.", _id, ".name"))] = _name;
    }

    /**
     * @dev Returns the Credential Item version.
     * @return string
     */
    function getVersion(bytes32 _id) internal view returns (string) {
        // return records[_id].version;
        return stringStorage[keccak256(abi.encodePacked("records.", _id, ".version"))];
    }

    /**
    * @dev Saves Credential Item version.
    * @param _id Ontology record ID.
    * @param _version Credential Item version.
    */
    function setVersion(bytes32 _id, string _version) internal {
        // records[_id].version = _version;
        stringStorage[keccak256(abi.encodePacked("records.", _id, ".version"))] = _version;
    }

    /**
     * @dev Returns the Credential Item reference URL.
     * @return string
     */
    function getReference(bytes32 _id) internal view returns (string) {
        // return records[_id].reference;
        return stringStorage[keccak256(abi.encodePacked("records.", _id, ".reference"))];
    }

    /**
    * @dev Saves Credential Item reference URL.
    * @param _id Ontology record ID.
    * @param _reference Reference value.
    */
    function setReference(bytes32 _id, string _reference) internal {
        // records[_id].reference = _reference;
        stringStorage[keccak256(abi.encodePacked("records.", _id, ".reference"))] = _reference;
    }

    /**
     * @dev Returns the Credential Item reference type value.
     * @return string
     */
    function getReferenceType(bytes32 _id) internal view returns (string) {
        // return records[_id].referenceType;
        return stringStorage[keccak256(abi.encodePacked("records.", _id, ".referenceType"))];
    }

    /**
    * @dev Saves Credential Item reference type.
    * @param _id Ontology record ID.
    * @param _referenceType Reference type.
    */
    function setReferenceType(bytes32 _id, string _referenceType) internal {
        // records[_id].referenceType = _referenceType;
        stringStorage[keccak256(abi.encodePacked("records.", _id, ".referenceType"))] = _referenceType;
    }

    /**
     * @dev Returns the Credential Item reference hash value.
     * @return bytes32
     */
    function getReferenceHash(bytes32 _id) internal view returns (bytes32) {
        // return records[_id].referenceHash;
        return bytes32Storage[keccak256(abi.encodePacked("records.", _id, ".referenceHash"))];
    }

    /**
    * @dev Saves Credential Item reference hash.
    * @param _id Ontology record ID.
    * @param _referenceHash Reference hash.
    */
    function setReferenceHash(bytes32 _id, bytes32 _referenceHash) internal {
        // records[_id].referenceHash = _referenceHash;
        bytes32Storage[keccak256(abi.encodePacked("records.", _id, ".referenceHash"))] = _referenceHash;
    }

    /**
     * @dev Returns the Credential Item deprecation flag value.
     * @return bool
     */
    function getDeprecated(bytes32 _id) internal view returns (bool) {
        // return records[_id].deprecated;
        return boolStorage[keccak256(abi.encodePacked("records.", _id, ".deprecated"))];
    }

    /**
    * @dev Sets Credential Item deprecation flag value.
    * @param _id Ontology record ID.
    */
    function setDeprecated(bytes32 _id) internal {
        // records[_id].deprecated = true;
        boolStorage[keccak256(abi.encodePacked("records.", _id, ".deprecated"))] = true;
    }

    /**
    * @dev Calculates ontology record ID.
    * @param _type Credential Item type.
    * @param _name Credential Item name.
    * @param _version Credential Item version.
    */
    function calculateId(string _type, string _name, string _version) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_type, ".", _name, ".", _version));
    }
}