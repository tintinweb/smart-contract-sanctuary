pragma solidity 0.4.19;


contract IConnections {
    // Forward = the connection is from the Connection creator to the specified recipient
    // Backwards = the connection is from the specified recipient to the Connection creator
    enum Direction {NotApplicable, Forwards, Backwards, Invalid}
    function createUser() external returns (address entityAddress);
    function createUserAndConnection(address _connectionTo, bytes32 _connectionType, Direction _direction) external returns (address entityAddress);
    function createVirtualEntity() external returns (address entityAddress);
    function createVirtualEntityAndConnection(address _connectionTo, bytes32 _connectionType, Direction _direction) external returns (address entityAddress);
    function editEntity(address _entity, bool _active, bytes32 _data) external;
    function transferEntityOwnerPush(address _entity, address _newOwner) external;
    function transferEntityOwnerPull(address _entity) external;
    function addConnection(address _entity, address _connectionTo, bytes32 _connectionType, Direction _direction) public;
    function editConnection(address _entity, address _connectionTo, bytes32 _connectionType, Direction _direction, bool _active, bytes32 _data, uint _expiration) external;
    function removeConnection(address _entity, address _connectionTo, bytes32 _connectionType) external;
    function isUser(address _entity) view public returns (bool isUserEntity);
    function getEntity(address _entity) view external returns (bool active, address transferOwnerTo, bytes32 data, address owner);
    function getConnection(address _entity, address _connectionTo, bytes32 _connectionType) view external returns (bool entityActive, bool connectionEntityActive, bool connectionActive, bytes32 data, Direction direction, uint expiration);

    // ################## Events ################## //
    event entityAdded(address indexed entity, address indexed owner);
    event entityModified(address indexed entity, address indexed owner, bool indexed active, bytes32 data);
    event entityOwnerChangeRequested(address indexed entity, address indexed oldOwner, address newOwner);
    event entityOwnerChanged(address indexed entity, address indexed oldOwner, address newOwner);
    event connectionAdded(address indexed entity, address indexed connectionTo, bytes32 connectionType, Direction direction);
    event connectionModified(address indexed entity, address indexed connectionTo, bytes32 indexed connectionType, Direction direction, bool active, uint expiration);
    event connectionRemoved(address indexed entity, address indexed connectionTo, bytes32 indexed connectionType);
    event entityResolved(address indexed entityRequested, address indexed entityResolved);    
}


/**
 * @title Connections v0.2
 * @dev The Connections contract records different connections between different types of entities.
 *
 * The contract has been designed for flexibility and scalability for use by anyone wishing to record different types of connections.
 *
 * Entities can be Users representing People, or Virtual Entities representing abstract types such as companies, objects, devices, robots etc...
 * User entities are special: each Ethereum address that creates or controls a User entity can only ever create one User Entity.
 * Each entity has an address to refer to it.
 *
 * Each entity has a number of connections to other entities, which are refered to using the entities address that the connection is to.
 * Modifying or removing entities, or adding, modifying or removing connections can only be done by the entity owner.
 *
 * Each connection also has a type, a direction and an expiration. The use of these fields is up to the Dapp to define and interprete.
 * Hashing a string of the connection name to create the connection type is suggested to obscure and diffuse types. Example bytes32 connection types:
 *     0x30ed9383ab64b27cb4b70035e743294fe1a1c83eaf57eca05033b523d1fa4261 = keccak256("isAdvisorOf")
 *     0xffe72ffb7d5cc4224f27ea8ad324f4b53b37835a76fc2b627b3d669180b75ecc = keccak256("isPartneredWith")
 *     0xa64b51178a7ee9735fb96d8e7ffdebb455b02beb3b1e17a709b5c1beef797405 = keccak256("isEmployeeOf")
 *     0x0079ca0c877589ba53b2e415a660827390d2c2a62123cef473009d003577b7f6 = keccak256("isColleagueOf")
 *
 */
contract Connections is IConnections {

    struct Entity {
        bool active;
        address transferOwnerTo;
        address owner;
        bytes32 data; // optional, this can link to IPFS or another off-chain storage location
        mapping (address => mapping (bytes32 => Connection)) connections;
    }

    // Connection has a type and direction
    struct Connection {
        bool active;
        bytes32 data; // optional, this can link to IPFS or another off-chain storage location
        Direction direction;
        uint expiration; // optional, unix timestamp or latest date to assume this connection is valid, 0 as no expiration
    }

    mapping (address => Entity) public entities;
    mapping (address => address) public entityOfUser;
    uint256 public virtualEntitiesCreated = 0;

    // ################## Constructor and Fallback function ################## //
    /**
     * Constructor
     */
    function Connections() public {}

    /**
     * Fallback function that cannot be called and will not accept Ether
     * Note that Ether can still be forced to this contract with a contract suicide()
     */
    function () external {
        revert();
    }


    // ################## External function ################## //
    /**
     * Creates a new user entity with an address of the msg.sender
     */
    function createUser() external returns (address entityAddress) {
        entityAddress = msg.sender;
        assert(entityOfUser[msg.sender] == address(0));
        createEntity(entityAddress, msg.sender);
        entityOfUser[msg.sender] = entityAddress;
    }

    /**
     * Creates a new user entity and a connection in one transaction
     * @param _connectionTo - the address of the entity to connect to
     * @param _connectionType - hash of the connection type
     * @param _direction - indicates the direction of the connection type
     */
    function createUserAndConnection(
        address _connectionTo,
        bytes32 _connectionType,
        Direction _direction
    )
        external returns (address entityAddress)
    {
        entityAddress = msg.sender;
        assert(entityOfUser[msg.sender] == address(0));
        createEntity(entityAddress, msg.sender);
        entityOfUser[msg.sender] = entityAddress;
        addConnection(entityAddress, _connectionTo, _connectionType, _direction);
    }

    /**
     * Creates a new virtual entity that is assigned to a unique address
     */
    function createVirtualEntity() external returns (address entityAddress) {
        entityAddress = createVirtualAddress();
        createEntity(entityAddress, msg.sender);
    }

    /**
     * Creates a new virtual entity and a connection in one transaction
     * @param _connectionTo - the address of the entity to connect to
     * @param _connectionType - hash of the connection type
     * @param _direction - indicates the direction of the connection type
     */
    function createVirtualEntityAndConnection(
        address _connectionTo,
        bytes32 _connectionType,
        Direction _direction
    )
        external returns (address entityAddress)
    {
        entityAddress = createVirtualAddress();
        createEntity(entityAddress, msg.sender);
        addConnection(entityAddress, _connectionTo, _connectionType, _direction);
    }

    /**
     * Edits data or active boolean of an entity that the msg sender is an owner of
     * This can be used to activate or deactivate an entity
     * @param _entity - the address of the entity to edit
     * @param _active - boolean to indicate if the entity is active or not
     * @param _data - data to be used to locate off-chain information about the user
     */
    function editEntity(address _entity, bool _active, bytes32 _data) external {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        Entity storage entity = entities[resolvedEntity];
        entity.active = _active;
        entity.data = _data;
        entityModified(_entity, msg.sender, _active, _data);
    }

    /**
     * Creates a request to transfer the ownership of an entity which must be accepted.
     * To cancel a request execute this function with _newOwner = address(0)
     * @param _entity - the address of the entity to transfer
     * @param _newOwner - the address of the new owner that will then have the exclusive permissions to control the entity
     */
    function transferEntityOwnerPush(address _entity, address _newOwner) external {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        entities[resolvedEntity].transferOwnerTo = _newOwner;
        entityOwnerChangeRequested(_entity, msg.sender, _newOwner);
    }

    /**
     * Accepts a request to transfer the ownership of an entity
     * @param _entity - the address of the entity to get ownership of
     */
    function transferEntityOwnerPull(address _entity) external {
        address resolvedEntity = resolveEntityAddress(_entity);
        emitEntityResolution(_entity, resolvedEntity);
        Entity storage entity = entities[resolvedEntity];
        require(entity.transferOwnerTo == msg.sender);
        if (isUser(resolvedEntity)) { // This is a user entity
            assert(entityOfUser[msg.sender] == address(0) ||
                   entityOfUser[msg.sender] == resolvedEntity);
            entityOfUser[msg.sender] = resolvedEntity;
        }
        address oldOwner = entity.owner;
        entity.owner = entity.transferOwnerTo;
        entity.transferOwnerTo = address(0);
        entityOwnerChanged(_entity, oldOwner, msg.sender);
    }

    /**
     * Edits a connection to another entity
     * @param _entity - the address of the entity to edit the connection of
     * @param _connectionTo - the address of the entity to connect to
     * @param _connectionType - hash of the connection type
     * @param _active - boolean to indicate if the connection is active or not
     * @param _direction - indicates the direction of the connection type
     * @param _expiration - number to indicate the expiration of the connection
     */
    function editConnection(
        address _entity,
        address _connectionTo,
        bytes32 _connectionType,
        Direction _direction,
        bool _active,
        bytes32 _data,
        uint _expiration
    )
        external
    {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        address resolvedConnectionEntity = resolveEntityAddress(_connectionTo);
        emitEntityResolution(_connectionTo, resolvedConnectionEntity);
        Entity storage entity = entities[resolvedEntity];
        Connection storage connection = entity.connections[resolvedConnectionEntity][_connectionType];
        connection.active = _active;
        connection.direction = _direction;
        connection.data = _data;
        connection.expiration = _expiration;
        connectionModified(_entity, _connectionTo, _connectionType, _direction, _active, _expiration);
    }

    /**
     * Removes a connection from the entities connections mapping.
     * If this is the last connection of any type to the _connectionTo address, then the removeConnection function should also be called to clean up the Entity
     * @param _entity - the address of the entity to edit the connection of
     * @param _connectionTo - the address of the entity to connect to
     * @param _connectionType - hash of the connection type
     */
    function removeConnection(address _entity, address _connectionTo, bytes32 _connectionType) external {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        address resolvedConnectionEntity = resolveEntityAddress(_connectionTo);
        emitEntityResolution(_connectionTo,resolvedConnectionEntity);
        Entity storage entity = entities[resolvedEntity];
        delete entity.connections[resolvedConnectionEntity][_connectionType];
        connectionRemoved(_entity, _connectionTo, _connectionType); // TBD: @haresh should we use resolvedEntity and resolvedConnectionEntity here?
    }

    /**
     * Returns the sha256 hash of a string. Useful for looking up the bytes32 values are for connection types.
     * Note this function is designed to be called off-chain for convenience, it is not used by any functions internally and does not change contract state
     * @param _string - string to hash
     * @return result - the hash of the string
     */
    function sha256ofString(string _string) external pure returns (bytes32 result) {
        result = keccak256(_string);
    }

    /**
     * Returns all the fields of an entity
     * @param _entity - the address of the entity to retrieve
     * @return (active, transferOwnerTo, data, owner) - a tuple containing the active flag, transfer status, data field and owner of an entity
     */
    function getEntity(address _entity) view external returns (bool active, address transferOwnerTo, bytes32 data, address owner) {
        address resolvedEntity = resolveEntityAddress(_entity);
        Entity storage entity = entities[resolvedEntity];
        return (entity.active, entity.transferOwnerTo, entity.data, entity.owner);
    }

    /**
     * Returns details of a connection
     * @param _entity - the address of the entity which created the
     * @return (entityActive, connectionEntityActive, connectionActive, data, direction, expiration)
     *                - tupple containing the entity active and the connection fields
     */
    function getConnection(
        address _entity,
        address _connectionTo,
        bytes32 _connectionType
    )
        view external returns (
            bool entityActive,
            bool connectionEntityActive,
            bool connectionActive,
            bytes32 data,
            Direction direction,
            uint expiration
    ){
        address resolvedEntity = resolveEntityAddress(_entity);
        address resolvedConnectionEntity = resolveEntityAddress(_connectionTo);
        Entity storage entity = entities[resolvedEntity];
        Connection storage connection = entity.connections[resolvedConnectionEntity][_connectionType];
        return (entity.active, entities[resolvedConnectionEntity].active, connection.active, connection.data, connection.direction, connection.expiration);
    }


    // ################## Public function ################## //
    /**
     * Creates a new connection to another entity
     * @param _entity - the address of the entity to add a connection to
     * @param _connectionTo - the address of the entity to connect to
     * @param _connectionType - hash of the connection type
     * @param _direction - indicates the direction of the connection type
     */
    function addConnection(
        address _entity,
        address _connectionTo,
        bytes32 _connectionType,
        Direction _direction
    )
        public
    {
        address resolvedEntity = resolveEntityAddressAndOwner(_entity);
        address resolvedEntityConnection = resolveEntityAddress(_connectionTo);
        emitEntityResolution(_connectionTo, resolvedEntityConnection);
        Entity storage entity = entities[resolvedEntity];
        assert(!entity.connections[resolvedEntityConnection][_connectionType].active);
        Connection storage connection = entity.connections[resolvedEntityConnection][_connectionType];
        connection.active = true;
        connection.direction = _direction;
        connectionAdded(_entity, _connectionTo, _connectionType, _direction);
    }

    /**
     * Returns true if an entity is a user, false if a virtual entity or fails if is not an entity
     * @param _entity - the address of the entity
     * @return isUserEntity - true if the entity was created with createUser(), false if the entity is created using createVirtualEntity()
     */
    function isUser(address _entity) view public returns (bool isUserEntity) {
        address resolvedEntity = resolveEntityAddress(_entity);
        assert(entities[resolvedEntity].active); // Make sure the user is active, otherwise this function call is invalid
        address owner = entities[resolvedEntity].owner;
        isUserEntity = (resolvedEntity == entityOfUser[owner]);
    }


    // ################## Internal functions ################## //
    /**
     * Creates a new entity at a specified address
     */
    function createEntity(address _entityAddress, address _owner) internal {
        require(!entities[_entityAddress].active); // Ensure the new entity address is not in use, prevents forceful takeover off addresses
        Entity storage entity = entities[_entityAddress];
        entity.active = true;
        entity.owner = _owner;
        entityAdded(_entityAddress, _owner);
    }

    /**
     * Returns a new unique deterministic address that has not been used before
     */
    function createVirtualAddress() internal returns (address virtualAddress) {
        virtualAddress = address(keccak256(safeAdd(virtualEntitiesCreated,block.number)));
        virtualEntitiesCreated = safeAdd(virtualEntitiesCreated,1);
    }

    /**
     * Emits an event if an entity resolution took place. Separated out as it would impact
     * view only functions which need entity resolution as well.
     */
    function emitEntityResolution(address _entity, address _resolvedEntity) internal {
        if (_entity != _resolvedEntity)
            entityResolved(_entity,_resolvedEntity);
    }

    /**
     * Returns the correct entity address resolved based on entityOfUser mapping
     */
    function resolveEntityAddress(address _entityAddress) internal view returns (address resolvedAddress) {
        if (entityOfUser[_entityAddress] != address(0) && entityOfUser[_entityAddress] != _entityAddress) {
            resolvedAddress = entityOfUser[_entityAddress];
        } else {
            resolvedAddress = _entityAddress;
        }
    }

    /**
     * Returns the correct entity address resolved based on entityOfUser mapping and also reverts if the
     * resolved if it is owned by the message sender
     * sender.
     */
    function resolveEntityAddressAndOwner(address _entityAddress) internal returns (address entityAddress) {
        entityAddress = resolveEntityAddress(_entityAddress);
        emitEntityResolution(_entityAddress, entityAddress);
        require(entities[entityAddress].owner == msg.sender);
    }

    /**
     * Adds two numbers and returns result throws in case an overflow occurs.
     */
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      assert(z >= x);
      return z;
    }    

}