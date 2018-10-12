pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

// File: contracts/pricing/CvcPricingInterface.sol

/**
 * @title CvcPricingInterface
 * @dev This contract defines the pricing service interface.
 */
contract CvcPricingInterface {

    struct CredentialItemPrice {
        bytes32 id;
        uint256 price;
        address idv;
        string credentialItemType;
        string credentialItemName;
        string credentialItemVersion;
        bool deprecated;
    }

    /**
     * @dev The CredentialItemPriceSet event is emitted when Identity Validator sets new price for specific credential item.
     *
     * @param id Price record identifier.
     * @param price Credential Item price in CVC.
     * @param idv The address of Identity Validator who offers Credential Item for sale.
     * @param credentialItemType Credential Item Type.
     * @param credentialItemName Credential Item Name.
     * @param credentialItemVersion Credential Item Version.
     * @param credentialItemId Credential Item ID.
     */
    event CredentialItemPriceSet(
        bytes32 indexed id,
        uint256 price,
        address indexed idv,
        string credentialItemType,
        string credentialItemName,
        string credentialItemVersion,
        bytes32 indexed credentialItemId
    );

    /**
     * @dev The CredentialItemPriceDeleted event is emitted when Identity Validator deletes the price for specific credential item.
     *
     * @param id Price record identifier.
     * @param idv The address of Identity Validator who offers Credential Item for sale
     * @param credentialItemType Credential Item Type.
     * @param credentialItemName Credential Item Name.
     * @param credentialItemVersion Credential Item Version.
     * @param credentialItemId Credential Item ID.
     */
    event CredentialItemPriceDeleted(
        bytes32 indexed id,
        address indexed idv,
        string credentialItemType,
        string credentialItemName,
        string credentialItemVersion,
        bytes32 indexed credentialItemId
    );

    /**
    * @dev Sets the price for Credential Item of specific type, name and version.
    * The price is associated with IDV address (sender).
    * @param _credentialItemType Credential Item type.
    * @param _credentialItemName Credential Item name.
    * @param _credentialItemVersion Credential Item version.
    * @param _price Credential Item price.
    */
    function setPrice(
        string _credentialItemType,
        string _credentialItemName,
        string _credentialItemVersion,
        uint256 _price
        ) external;

    /**
    * @dev Deletes the price for Credential Item of specific type, name and version.
    * @param _credentialItemType Credential Item type.
    * @param _credentialItemName Credential Item name.
    * @param _credentialItemVersion Credential Item version.
    */
    function deletePrice(
        string _credentialItemType,
        string _credentialItemName,
        string _credentialItemVersion
        ) external;

    /**
    * @dev Returns the price set by IDV for Credential Item of specific type, name and version.
    * @param _idv IDV address.
    * @param _credentialItemType Credential Item type.
    * @param _credentialItemName Credential Item name.
    * @param _credentialItemVersion Credential Item version.
    * @return bytes32 Price ID.
    * @return uint256 Price value.
    * @return address IDV address.
    * @return string Credential Item type.
    * @return string Credential Item name.
    * @return string Credential Item version.
    */
    function getPrice(
        address _idv,
        string _credentialItemType,
        string _credentialItemName,
        string _credentialItemVersion
        ) external view returns (
            bytes32 id,
            uint256 price,
            address idv,
            string credentialItemType,
            string credentialItemName,
            string credentialItemVersion,
            bool deprecated
        );

    /**
    * @dev Returns the price by Credential Item ID.
    * @param _idv IDV address.
    * @param _credentialItemId Credential Item ID.
    * @return bytes32 Price ID.
    * @return uint256 Price value.
    * @return address IDV address.
    * @return string Credential Item type.
    * @return string Credential Item name.
    * @return string Credential Item version.
    */
    function getPriceByCredentialItemId(
        address _idv,
        bytes32 _credentialItemId
        ) external view returns (
            bytes32 id,
            uint256 price,
            address idv,
            string credentialItemType,
            string credentialItemName,
            string credentialItemVersion,
            bool deprecated
        );

    /**
    * @dev Returns all Credential Item prices.
    * @return CredentialItemPrice[]
    */
    function getAllPrices() external view returns (CredentialItemPrice[]);

    /**
     * @dev Returns all IDs of registered Credential Item prices.
     * @return bytes32[]
     */
    function getAllIds() external view returns (bytes32[]);

    /**
    * @dev Returns the price by ID.
    * @param _id Price ID
    * @return bytes32 Price ID.
    * @return uint256 Price value.
    * @return address IDV address.
    * @return string Credential Item type.
    * @return string Credential Item name.
    * @return string Credential Item version.
    */
    function getPriceById(
        bytes32 _id
        ) public view returns (
            bytes32 id,
            uint256 price,
            address idv,
            string credentialItemType,
            string credentialItemName,
            string credentialItemVersion,
            bool deprecated
        );
}

// File: contracts/idv/CvcValidatorRegistryInterface.sol

/**
 * @title CvcValidatorRegistryInterface
 * @dev This contract defines Validator Registry interface.
 */
contract CvcValidatorRegistryInterface {

    /**
    * @dev Adds a new Validator record or updates the existing one.
    * @param _name Validator name.
    * @param _description Validator description.
    */
    function set(address _idv, string _name, string _description) external;

    /**
    * @dev Returns Validator entry.
    * @param _idv Validator address.
    * @return name Validator name.
    * @return description Validator description.
    */
    function get(address _idv) external view returns (string name, string description);

    /**
    * @dev Verifies whether Validator is registered.
    * @param _idv Validator address.
    * @return bool
    */
    function exists(address _idv) external view returns (bool);
}

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

// File: contracts/upgradeability/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable, ImplementationStorage {

    /**
    Data structures and storage layout:
    mapping(bytes32 => bool) paused;
    **/

    event Pause();
    event Unpause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused(), "Contract must be paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        // paused[implementation()] = true;
        boolStorage[keccak256(abi.encodePacked(implementation(), "paused"))] = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        // paused[implementation()] = false;
        boolStorage[keccak256(abi.encodePacked(implementation(), "paused"))] = false;
        emit Unpause();
    }

    /**
     * @dev Returns true when the contract is paused.
     * @return bool
     */
    function paused() public view returns (bool) {
        // return paused[implementation()];
        return boolStorage[keccak256(abi.encodePacked(implementation(), "paused"))];
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

// File: contracts/pricing/CvcPricing.sol

/**
 * @title CvcPricing
 * @dev This contract stores actual prices for Credential Items available for sale.
 * It allows registered Identity Validators to set or delete prices for specific Credential Items.
 *
 * The pricing contract depends on other marketplace contracts, such as:
 * CvcOntology - to verify that Credential Item is available on the market and can be offered for sale.
 * CvcValidatorRegistry - to ensure that only registered Identity Validators can use pricing services.
 *                          Transactions from unknown accounts will be rejected.
 */
contract CvcPricing is EternalStorage, Initializable, Pausable, CvcPricingInterface {

    using SafeMath for uint256;

    /**
    Data structures and storage layout:
    struct Price {
        uint256 value;
        bytes32 credentialItemId;
        address idv;
    }

    address cvcOntology;
    address idvRegistry;
    uint256 pricesCount;
    bytes32[] pricesIds;
    mapping(bytes32 => uint256) pricesIndices;
    mapping(bytes32 => Price) prices;
    **/


    /// Total supply of CVC tokens.
    uint256 constant private CVC_TOTAL_SUPPLY = 1e17;

    /// The fallback price introduced to be returned when credential price is undefined.
    /// The number is greater than CVC total supply, so it makes it impossible to transact with (e.g. place to escrow).
    uint256 constant private FALLBACK_PRICE = CVC_TOTAL_SUPPLY + 1; // solium-disable-line zeppelin/no-arithmetic-operations

    /// As zero price and undefined price are virtually indistinguishable,
    /// a special value is introduced to represent zero price.
    /// It equals to max unsigned integer which makes it impossible to transact with, hence should never be returned.
    uint256 constant private ZERO_PRICE = ~uint256(0);

    /**
    * @dev Constructor
    * @param _ontology CvcOntology contract address.
    * @param _idvRegistry CvcValidatorRegistry contract address.
    */
    constructor(address _ontology, address _idvRegistry) public {
        initialize(_ontology, _idvRegistry, msg.sender);
    }

    /**
     * @dev Throws if called by unregistered IDV.
     */
    modifier onlyRegisteredValidator() {
        require(idvRegistry().exists(msg.sender), "Identity Validator is not registered");
        _;
    }

    /**
    * @dev Sets the price for Credential Item of specific type, name and version.
    * The price is associated with IDV address (sender).
    * @param _credentialItemType Credential Item type.
    * @param _credentialItemName Credential Item name.
    * @param _credentialItemVersion Credential Item version.
    * @param _price Credential Item price.
    */
    function setPrice(
        string _credentialItemType,
        string _credentialItemName,
        string _credentialItemVersion,
        uint256 _price
    )
        external
        onlyRegisteredValidator
        whenNotPaused
    {
        // Check price value upper bound.
        require(_price <= CVC_TOTAL_SUPPLY, "Price value cannot be more than token total supply");

        // Check Credential Item ID to verify existence.
        bytes32 credentialItemId;
        bool deprecated;
        (credentialItemId, , , , , , , deprecated) = ontology().getByTypeNameVersion(
            _credentialItemType,
            _credentialItemName,
            _credentialItemVersion
        );
        // Prevent setting price for unknown credential items.
        require(credentialItemId != 0x0, "Cannot set price for unknown credential item");
        require(deprecated == false, "Cannot set price for deprecated credential item");

        // Calculate price ID.
        bytes32 id = calculateId(msg.sender, credentialItemId);

        // Register new record (when price record has no associated Credential Item ID).
        if (getPriceCredentialItemId(id) == 0x0) {
            registerNewRecord(id);
        }

        // Save the price.
        setPriceIdv(id, msg.sender);
        setPriceCredentialItemId(id, credentialItemId);
        setPriceValue(id, _price);

        emit CredentialItemPriceSet(
            id,
            _price,
            msg.sender,
            _credentialItemType,
            _credentialItemName,
            _credentialItemVersion,
            credentialItemId
        );
    }

    /**
    * @dev Deletes the price for Credential Item of specific type, name and version.
    * @param _credentialItemType Credential Item type.
    * @param _credentialItemName Credential Item name.
    * @param _credentialItemVersion Credential Item version.
    */
    function deletePrice(
        string _credentialItemType,
        string _credentialItemName,
        string _credentialItemVersion
    )
        external
        whenNotPaused
    {
        // Lookup Credential Item.
        bytes32 credentialItemId;
        (credentialItemId, , , , , , ,) = ontology().getByTypeNameVersion(
            _credentialItemType,
            _credentialItemName,
            _credentialItemVersion
        );

        // Calculate Price ID to address individual data items.
        bytes32 id = calculateId(msg.sender, credentialItemId);

        // Ensure the price existence. Check whether Credential Item is associated.
        credentialItemId = getPriceCredentialItemId(id);
        require(credentialItemId != 0x0, "Cannot delete unknown price record");

        // Delete the price data.
        deletePriceIdv(id);
        deletePriceCredentialItemId(id);
        deletePriceValue(id);

        unregisterRecord(id);

        emit CredentialItemPriceDeleted(
            id,
            msg.sender,
            _credentialItemType,
            _credentialItemName,
            _credentialItemVersion,
            credentialItemId
        );
    }

    /**
    * @dev Returns the price set by IDV for Credential Item of specific type, name and version.
    * @param _idv IDV address.
    * @param _credentialItemType Credential Item type.
    * @param _credentialItemName Credential Item name.
    * @param _credentialItemVersion Credential Item version.
    * @return bytes32 Price ID.
    * @return uint256 Price value.
    * @return address IDV address.
    * @return string Credential Item type.
    * @return string Credential Item name.
    * @return string Credential Item version.
    */
    function getPrice(
        address _idv,
        string _credentialItemType,
        string _credentialItemName,
        string _credentialItemVersion
    )
        external
        view
        onlyInitialized
        returns (
            bytes32 id,
            uint256 price,
            address idv,
            string credentialItemType,
            string credentialItemName,
            string credentialItemVersion,
            bool deprecated
        )
    {
        // Lookup Credential Item.
        bytes32 credentialItemId;
        (credentialItemId, credentialItemType, credentialItemName, credentialItemVersion, , , , deprecated) = ontology().getByTypeNameVersion(
            _credentialItemType,
            _credentialItemName,
            _credentialItemVersion
        );
        idv = _idv;
        id = calculateId(idv, credentialItemId);
        price = getPriceValue(id);
        if (price == FALLBACK_PRICE) {
            return (0x0, price, 0x0, "", "", "", false);
        }
    }

    /**
    * @dev Returns the price by Credential Item ID.
    * @param _idv IDV address.
    * @param _credentialItemId Credential Item ID.
    * @return bytes32 Price ID.
    * @return uint256 Price value.
    * @return address IDV address.
    * @return string Credential Item type.
    * @return string Credential Item name.
    * @return string Credential Item version.
    */
    function getPriceByCredentialItemId(address _idv, bytes32 _credentialItemId) external view returns (
        bytes32 id,
        uint256 price,
        address idv,
        string credentialItemType,
        string credentialItemName,
        string credentialItemVersion,
        bool deprecated
    ) {
        return getPriceById(calculateId(_idv, _credentialItemId));
    }

    /**
    * @dev Returns all Credential Item prices.
    * @return CredentialItemPrice[]
    */
    function getAllPrices() external view onlyInitialized returns (CredentialItemPrice[]) {
        uint256 count = getCount();
        CredentialItemPrice[] memory prices = new CredentialItemPrice[](count);
        for (uint256 i = 0; i < count; i++) {
            bytes32 id = getRecordId(i);
            bytes32 credentialItemId = getPriceCredentialItemId(id);
            string memory credentialItemType;
            string memory credentialItemName;
            string memory credentialItemVersion;
            bool deprecated;

            (, credentialItemType, credentialItemName, credentialItemVersion, , , , deprecated) = ontology().getById(credentialItemId);

            prices[i] = CredentialItemPrice(
                id,
                getPriceValue(id),
                getPriceIdv(id),
                credentialItemType,
                credentialItemName,
                credentialItemVersion,
                deprecated
            );
        }

        return prices;
    }

    /**
     * @dev Returns all IDs of registered Credential Item prices.
     * @return bytes32[]
     */
    function getAllIds() external view onlyInitialized returns(bytes32[]) {
        uint256 count = getCount();
        bytes32[] memory ids = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = getRecordId(i);
        }

        return ids;
    }

    /**
    * @dev Contract initialization method.
    * @param _ontology CvcOntology contract address.
    * @param _idvRegistry CvcValidatorRegistry contract address.
    * @param _owner Owner address
    */
    function initialize(address _ontology, address _idvRegistry, address _owner) public initializes {
        require(AddressUtils.isContract(_ontology), "Initialization error: no contract code at ontology contract address");
        require(AddressUtils.isContract(_idvRegistry), "Initialization error: no contract code at IDV registry contract address");
        // cvcOntology = _ontology;
        addressStorage[keccak256("cvc.ontology")] = _ontology;
        // idvRegistry = _idvRegistry;
        addressStorage[keccak256("cvc.idv.registry")] = _idvRegistry;
        // Initialize current implementation owner address.
        setOwner(_owner);
    }

    /**
    * @dev Returns the price by ID.
    * @param _id Price ID
    * @return bytes32 Price ID.
    * @return uint256 Price value.
    * @return address IDV address.
    * @return string Credential Item type.
    * @return string Credential Item name.
    * @return string Credential Item version.
    */
    function getPriceById(bytes32 _id) public view onlyInitialized returns (
        bytes32 id,
        uint256 price,
        address idv,
        string credentialItemType,
        string credentialItemName,
        string credentialItemVersion,
        bool deprecated
    ) {
        // Always return price (could be a fallback price when not set).
        price = getPriceValue(_id);
        // Check whether Credential Item is associated. This is mandatory requirement for all existing prices.
        bytes32 credentialItemId = getPriceCredentialItemId(_id);
        if (credentialItemId != 0x0) {
            // Return ID and IDV address for existing entry only.
            id = _id;
            idv = getPriceIdv(_id);

            (, credentialItemType, credentialItemName, credentialItemVersion, , , , deprecated) = ontology().getById(credentialItemId);
        }
    }

    /**
    * @dev Returns instance of CvcOntologyInterface.
    * @return CvcOntologyInterface
    */
    function ontology() public view returns (CvcOntologyInterface) {
        // return CvcOntologyInterface(cvcOntology);
        return CvcOntologyInterface(addressStorage[keccak256("cvc.ontology")]);
    }

    /**
    * @dev Returns instance of CvcValidatorRegistryInterface.
    * @return CvcValidatorRegistryInterface
    */
    function idvRegistry() public view returns (CvcValidatorRegistryInterface) {
        // return CvcValidatorRegistryInterface(idvRegistry);
        return CvcValidatorRegistryInterface(addressStorage[keccak256("cvc.idv.registry")]);
    }

    /**
    * @dev Returns price record count.
    * @return uint256
    */
    function getCount() internal view returns (uint256) {
        // return pricesCount;
        return uintStorage[keccak256("prices.count")];
    }

    /**
    * @dev Increments price record counter.
    */
    function incrementCount() internal {
        // pricesCount = getCount().add(1);
        uintStorage[keccak256("prices.count")] = getCount().add(1);
    }

    /**
    * @dev Decrements price record counter.
    */
    function decrementCount() internal {
        // pricesCount = getCount().sub(1);
        uintStorage[keccak256("prices.count")] = getCount().sub(1);
    }

    /**
    * @dev Returns price ID by index.
    * @param _index Price record index.
    * @return bytes32
    */
    function getRecordId(uint256 _index) internal view returns (bytes32) {
        // return pricesIds[_index];
        return bytes32Storage[keccak256(abi.encodePacked("prices.ids.", _index))];
    }

    /**
    * @dev Index new price record.
    * @param _id The price ID.
    */
    function registerNewRecord(bytes32 _id) internal {
        bytes32 indexSlot = keccak256(abi.encodePacked("prices.indices.", _id));
        // Prevent from registering same ID twice.
        // require(pricesIndices[_id] == 0);
        require(uintStorage[indexSlot] == 0, "Integrity error: price with the same ID is already registered");

        uint256 index = getCount();
        // Store record ID against index.
        // pricesIds[index] = _id;
        bytes32Storage[keccak256(abi.encodePacked("prices.ids.", index))] = _id;
        // Maintain reversed index to ID mapping to ensure O(1) deletion.
        // Store n+1 value and reserve zero value for not indexed records.
        uintStorage[indexSlot] = index.add(1);
        incrementCount();
    }

    /**
    * @dev Deletes price record from index.
    * @param _id The price ID.
    */
    function unregisterRecord(bytes32 _id) internal {
        // Since the order of price records is not guaranteed, we can make deletion more efficient
        // by replacing record we want to delete with the last record, hence avoid reindex.

        // Calculate deletion record ID slot.
        bytes32 deletionIndexSlot = keccak256(abi.encodePacked("prices.indices.", _id));
        // uint256 deletionIndex = pricesIndices[_id].sub(1);
        uint256 deletionIndex = uintStorage[deletionIndexSlot].sub(1);
        bytes32 deletionIdSlot = keccak256(abi.encodePacked("prices.ids.", deletionIndex));

        // Calculate last record ID slot.
        uint256 lastIndex = getCount().sub(1);
        bytes32 lastIdSlot = keccak256(abi.encodePacked("prices.ids.", lastIndex));

        // Calculate last record index slot.
        bytes32 lastIndexSlot = keccak256(abi.encodePacked("prices.indices.", bytes32Storage[lastIdSlot]));

        // Copy last record ID into the empty slot.
        // pricesIds[deletionIdSlot] = pricesIds[lastIdSlot];
        bytes32Storage[deletionIdSlot] = bytes32Storage[lastIdSlot];
        // Make moved ID index point to the the correct record.
        // pricesIndices[lastIndexSlot] = pricesIndices[deletionIndexSlot];
        uintStorage[lastIndexSlot] = uintStorage[deletionIndexSlot];
        // Delete last record ID.
        // delete pricesIds[lastIndex];
        delete bytes32Storage[lastIdSlot];
        // Delete reversed index.
        // delete pricesIndices[_id];
        delete uintStorage[deletionIndexSlot];
        decrementCount();
    }
    /**
    * @dev Returns price value.
    * @param _id The price ID.
    * @return uint256
    */
    function getPriceValue(bytes32 _id) internal view returns (uint256) {
        // uint256 value = prices[_id].value;
        uint256 value = uintStorage[keccak256(abi.encodePacked("prices.", _id, ".value"))];
        // Return fallback price if price is not set for existing Credential Item.
        // Since we use special (non-zero) value for zero price, actual &#39;0&#39; means the price was never set.
        if (value == 0) {
            return FALLBACK_PRICE;
        }
        // Convert from special zero representation value.
        if (value == ZERO_PRICE) {
            return 0;
        }

        return value;
    }

    /**
    * @dev Saves price value.
    * @param _id The price ID.
    * @param _value The price value.
    */
    function setPriceValue(bytes32 _id, uint256 _value) internal {
        // Save the price (convert to special zero representation value if necessary).
        // prices[_id].value = (_value == 0) ? ZERO_PRICE : _value;
        uintStorage[keccak256(abi.encodePacked("prices.", _id, ".value"))] = (_value == 0) ? ZERO_PRICE : _value;
    }

    /**
    * @dev Deletes price value.
    * @param _id The price ID.
    */
    function deletePriceValue(bytes32 _id) internal {
        // delete prices[_id].value;
        delete uintStorage[keccak256(abi.encodePacked("prices.", _id, ".value"))];
    }

    /**
    * @dev Returns Credential Item ID the price is set for.
    * @param _id The price ID.
    * @return bytes32
    */
    function getPriceCredentialItemId(bytes32 _id) internal view returns (bytes32) {
        // return prices[_id].credentialItemId;
        return bytes32Storage[keccak256(abi.encodePacked("prices.", _id, ".credentialItemId"))];
    }

    /**
    * @dev Saves price Credential Item ID
    * @param _id The price ID.
    * @param _credentialItemId Associated Credential Item ID.
    */
    function setPriceCredentialItemId(bytes32 _id, bytes32 _credentialItemId) internal {
        // prices[_id].credentialItemId = _credentialItemId;
        bytes32Storage[keccak256(abi.encodePacked("prices.", _id, ".credentialItemId"))] = _credentialItemId;
    }

    /**
    * @dev Deletes price Credential Item ID.
    * @param _id The price ID.
    */
    function deletePriceCredentialItemId(bytes32 _id) internal {
        // delete prices[_id].credentialItemId;
        delete bytes32Storage[keccak256(abi.encodePacked("prices.", _id, ".credentialItemId"))];
    }

    /**
    * @dev Returns price IDV address.
    * @param _id The price ID.
    * @return address
    */
    function getPriceIdv(bytes32 _id) internal view returns (address) {
        // return prices[_id].idv;
        return addressStorage[keccak256(abi.encodePacked("prices.", _id, ".idv"))];
    }

    /**
    * @dev Saves price IDV address.
    * @param _id The price ID.
    * @param _idv IDV address.
    */
    function setPriceIdv(bytes32 _id, address _idv) internal {
        // prices[_id].idv = _idv;
        addressStorage[keccak256(abi.encodePacked("prices.", _id, ".idv"))] = _idv;
    }

    /**
    * @dev Deletes price IDV address.
    * @param _id The price ID.
    */
    function deletePriceIdv(bytes32 _id) internal {
        // delete prices[_id].idv;
        delete addressStorage[keccak256(abi.encodePacked("prices.", _id, ".idv"))];
    }

    /**
    * @dev Calculates price ID.
    * @param _idv IDV address.
    * @param _credentialItemId Credential Item ID.
    * @return bytes32
    */
    function calculateId(address _idv, bytes32 _credentialItemId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_idv, ".", _credentialItemId));
    }
}