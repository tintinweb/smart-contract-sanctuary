pragma solidity ^0.4.11;

/** @title Decentralized Identification Number (DIN) registry. */
contract DINRegistry {

    struct Record {
        address owner;
        address resolver;  // Address where product information is stored. 
        uint256 updated;   // Unix timestamp.
    }

    // DIN => Record
    mapping (uint256 => Record) records;

    // The address of DINRegistrar.
    address public registrar;

    // The first DIN registered.
    uint256 public genesis;

    modifier only_registrar {
        require(registrar == msg.sender);
        _;
    }

    modifier only_owner(uint256 DIN) {
        require(records[DIN].owner == msg.sender);
        _;
    }

    // Logged when the owner of a DIN transfers ownership to a new account.
    event NewOwner(uint256 indexed DIN, address indexed owner);

    // Logged when the resolver associated with a DIN changes.
    event NewResolver(uint256 indexed DIN, address indexed resolver);

    // Logged when a new DIN is registered.
    event NewRegistration(uint256 indexed DIN, address indexed owner);

    // Logged when the DINRegistrar contract changes.
    event NewRegistrar(address indexed registrar);

    /** @dev Constructor.
      * @param _genesis The first DIN registered.
      */
    function DINRegistry(uint256 _genesis) {
        genesis = _genesis;

        // Register the genesis DIN to the account that deploys this contract.
        records[genesis].owner = msg.sender;
        records[genesis].updated = block.timestamp;
        NewRegistration(genesis, msg.sender);
    }

    // Get the owner of a specified DIN.
    function owner(uint256 DIN) constant returns (address) {
        return records[DIN].owner;
    }

    /**
     * @dev Transfer ownership of a DIN.
     * @param DIN The DIN to transfer.
     * @param owner The address of the new owner.
     */
    function setOwner(uint256 DIN, address owner) only_owner(DIN) {
        records[DIN].owner = owner;
        records[DIN].updated = block.timestamp;
        NewOwner(DIN, owner);
    }

    // Get the resolver of a specified DIN.
    function resolver(uint256 DIN) constant returns (address) {
        return records[DIN].resolver;
    }

    /**
     * @dev Set the resolver of a DIN.
     * @param DIN The DIN to update.
     * @param resolver The address of the resolver.
     */
    function setResolver(uint256 DIN, address resolver) only_owner(DIN) {
        records[DIN].resolver = resolver;
        records[DIN].updated = block.timestamp;
        NewResolver(DIN, resolver);
    }

    // Get the time a specified DIN record was last updated.
    function updated(uint256 DIN) constant returns (uint256) {
        return records[DIN].updated;
    } 

    /**
     * @dev Register a new DIN.
     * @param owner The account that will own the DIN.
     */
    function register(uint256 DIN, address owner) only_registrar {
        records[DIN].owner = owner;
        records[DIN].updated = block.timestamp;
        NewRegistration(DIN, owner);
    }

    /**
     * @dev Change the DINRegistrar contract.
     * @param _registrar The address of the new registrar.
     */
    function setRegistrar(address _registrar) only_owner(genesis) {
        registrar = _registrar;
        NewRegistrar(_registrar);
    }

}