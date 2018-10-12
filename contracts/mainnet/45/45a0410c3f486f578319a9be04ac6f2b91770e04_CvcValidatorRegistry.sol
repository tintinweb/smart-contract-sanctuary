pragma solidity ^0.4.24;

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

// File: contracts/idv/CvcValidatorRegistry.sol

/**
 * @title CvcValidatorRegistry
 * @dev This contract is a registry for Identity Validators (IDV). It is part of the marketplace access control mechanism.
 * Only registered and authorized Identity Validators can perform certain actions on marketplace.
 */
contract CvcValidatorRegistry is EternalStorage, Initializable, Ownable, CvcValidatorRegistryInterface {

    /**
    Data structures and storage layout:
    struct Validator {
        string name;
        string description;
    }
    mapping(address => Validator) validators;
    **/

    /**
    * @dev Constructor: invokes initialization function
    */
    constructor() public {
        initialize(msg.sender);
    }

    /**
    * @dev Registers a new Validator or updates the existing one.
    * @param _idv Validator address.
    * @param _name Validator name.
    * @param _description Validator description.
    */
    function set(address _idv, string _name, string _description) external onlyInitialized onlyOwner {
        require(_idv != address(0), "Cannot register IDV with zero address");
        require(bytes(_name).length > 0, "Cannot register IDV with empty name");

        setValidatorName(_idv, _name);
        setValidatorDescription(_idv, _description);
    }

    /**
    * @dev Returns Validator data.
    * @param _idv Validator address.
    * @return name Validator name.
    * @return description Validator description.
    */
    function get(address _idv) external view onlyInitialized returns (string name, string description) {
        name = getValidatorName(_idv);
        description = getValidatorDescription(_idv);
    }

    /**
    * @dev Verifies whether Validator is registered.
    * @param _idv Validator address.
    * @return bool
    */
    function exists(address _idv) external view onlyInitialized returns (bool) {
        return bytes(getValidatorName(_idv)).length > 0;
    }

    /**
    * @dev Contract initialization method.
    * @param _owner Owner address
    */
    function initialize(address _owner) public initializes {
        setOwner(_owner);
    }

    /**
    * @dev Returns Validator name.
    * @param _idv Validator address.
    * @return string
    */
    function getValidatorName(address _idv) private view returns (string) {
        // return validators[_idv].name;
        return stringStorage[keccak256(abi.encodePacked("validators.", _idv, ".name"))];
    }

    /**
    * @dev Saves Validator name.
    * @param _idv Validator address.
    * @param _name Validator name.
    */
    function setValidatorName(address _idv, string _name) private {
        // validators[_idv].name = _name;
        stringStorage[keccak256(abi.encodePacked("validators.", _idv, ".name"))] = _name;
    }

    /**
    * @dev Returns Validator description.
    * @param _idv Validator address.
    * @return string
    */
    function getValidatorDescription(address _idv) private view returns (string) {
        // return validators[_idv].description;
        return stringStorage[keccak256(abi.encodePacked("validators.", _idv, ".description"))];
    }

    /**
    * @dev Saves Validator description.
    * @param _idv Validator address.
    * @param _description Validator description.
    */
    function setValidatorDescription(address _idv, string _description) private {
        // validators[_idv].description = _description;
        stringStorage[keccak256(abi.encodePacked("validators.", _idv, ".description"))] = _description;
    }

}