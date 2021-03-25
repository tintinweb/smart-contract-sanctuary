/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// Sources flattened with hardhat v2.0.7 https://hardhat.org

// File contracts/lib/ownership/Ownable.sol

pragma solidity ^0.5.1;

contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() public { owner = msg.sender; }

    /// @dev Throws if called by any contract other than latest designated caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


// File contracts/lib/lifecycle/Destructible.sol

pragma solidity ^0.5.1;
contract Destructible is Ownable {
    function selfDestruct() public onlyOwner {
        selfdestruct(owner);
    }
}


// File contracts/lib/ownership/ZapCoordinatorInterface.sol

pragma solidity ^0.5.1;
contract ZapCoordinatorInterface is Ownable {
    function addImmutableContract(string calldata contractName, address newAddress) external;
    function updateContract(string calldata contractName, address newAddress) external;
    function getContractName(uint index) public view returns (string memory) ;
    function getContract(string memory contractName) public view returns (address);
    function updateAllDependencies() external;
}


// File contracts/lib/ownership/Upgradable.sol

pragma solidity ^0.5.1;
contract Upgradable {

    address coordinatorAddr;
    ZapCoordinatorInterface coordinator;

    constructor(address c) public{
        coordinatorAddr = c;
        coordinator = ZapCoordinatorInterface(c);
    }

    function updateDependencies() external coordinatorOnly {
        _updateDependencies();
    }

    function _updateDependencies() internal;

    modifier coordinatorOnly() {
        require(msg.sender == coordinatorAddr, "Error: Coordinator Only Function");
        _;
    }
}


// File contracts/platform/database/DatabaseInterface.sol

pragma solidity ^0.5.1;
contract DatabaseInterface is Ownable {
    function setStorageContract(address _storageContract, bool _allowed) public;
    /*** Bytes32 ***/
    function getBytes32(bytes32 key) external view returns(bytes32);
    function setBytes32(bytes32 key, bytes32 value) external;
    /*** Number **/
    function getNumber(bytes32 key) external view returns(uint256);
    function setNumber(bytes32 key, uint256 value) external;
    /*** Bytes ***/
    function getBytes(bytes32 key) external view returns(bytes memory);
    function setBytes(bytes32 key, bytes calldata value) external;
    /*** String ***/
    function getString(bytes32 key) external view returns(string memory);
    function setString(bytes32 key, string calldata value) external;
    /*** Bytes Array ***/
    function getBytesArray(bytes32 key) external view returns (bytes32[] memory);
    function getBytesArrayIndex(bytes32 key, uint256 index) external view returns (bytes32);
    function getBytesArrayLength(bytes32 key) external view returns (uint256);
    function pushBytesArray(bytes32 key, bytes32 value) external;
    function setBytesArrayIndex(bytes32 key, uint256 index, bytes32 value) external;
    function setBytesArray(bytes32 key, bytes32[] calldata value) external;
    /*** Int Array ***/
    function getIntArray(bytes32 key) external view returns (int[] memory);
    function getIntArrayIndex(bytes32 key, uint256 index) external view returns (int);
    function getIntArrayLength(bytes32 key) external view returns (uint256);
    function pushIntArray(bytes32 key, int value) external;
    function setIntArrayIndex(bytes32 key, uint256 index, int value) external;
    function setIntArray(bytes32 key, int[] calldata value) external;
    /*** Address Array ***/
    function getAddressArray(bytes32 key) external view returns (address[] memory );
    function getAddressArrayIndex(bytes32 key, uint256 index) external view returns (address);
    function getAddressArrayLength(bytes32 key) external view returns (uint256);
    function pushAddressArray(bytes32 key, address value) external;
    function setAddressArrayIndex(bytes32 key, uint256 index, address value) external;
    function setAddressArray(bytes32 key, address[] calldata value) external;
}


// File contracts/platform/registry/RegistryInterface.sol

pragma solidity ^0.5.1;

contract RegistryInterface {
    function initiateProvider(uint256, bytes32) public returns (bool);
    function initiateProviderCurve(bytes32, int256[] memory, address) public returns (bool);
    function setEndpointParams(bytes32, bytes32[] memory) public;
    function getEndpointParams(address, bytes32) public view returns (bytes32[] memory );
    function getProviderPublicKey(address) public view returns (uint256);
    function getProviderTitle(address) public view returns (bytes32);
    function setProviderParameter(bytes32, bytes memory) public;
    function setProviderTitle(bytes32) public;
    function clearEndpoint(bytes32) public;
    function getProviderParameter(address, bytes32) public view returns (bytes memory);
    function getAllProviderParams(address) public view returns (bytes32[] memory);
    function getProviderCurveLength(address, bytes32) public view returns (uint256);
    function getProviderCurve(address, bytes32) public view returns (int[] memory);
    function isProviderInitiated(address) public view returns (bool);
    function getAllOracles() external view returns (address[] memory);
    function getProviderEndpoints(address) public view returns (bytes32[] memory);
    function getEndpointBroker(address, bytes32) public view returns (address);
}


// File contracts/platform/registry/Registry.sol

pragma solidity ^0.5.1;
// v1.0
contract Registry is Destructible, RegistryInterface, Upgradable {

    event NewProvider(
        address indexed provider,
        bytes32 indexed title
    );

    event NewCurve(
        address indexed provider,
        bytes32 indexed endpoint,
        int[] curve,
        address indexed broker
    );

    DatabaseInterface public db;

    constructor(address c) Upgradable(c) public {
        _updateDependencies();
    }

    function _updateDependencies() internal {
        address databaseAddress = coordinator.getContract("DATABASE");
        db = DatabaseInterface(databaseAddress);
    }

    /// @dev initiates a provider.
    /// If no address->Oracle mapping exists, Oracle object is created
    /// @param publicKey unique id for provider. used for encyrpted key swap for subscription endpoints
    /// @param title name
    function initiateProvider(
        uint256 publicKey,
        bytes32 title
    )
        public
        returns (bool)
    {
        require(!isProviderInitiated(msg.sender), "Error: Provider is already initiated");
        createOracle(msg.sender, publicKey, title);
        addOracle(msg.sender);
        emit NewProvider(msg.sender, title);
        return true;
    }

    /// @dev initiates an endpoint specific provider curve
    /// If oracle[specfifier] is uninitialized, Curve is mapped to endpoint
    /// @param endpoint specifier of endpoint. currently "smart_contract" or "socket_subscription"
    /// @param curve flattened array of all segments, coefficients across all polynomial terms, [e0,l0,c0,c1,c2,...]
    /// @param broker address for endpoint. if non-zero address, only this address will be able to bond/unbond
    function initiateProviderCurve(
        bytes32 endpoint,
        int256[] memory curve,
        address broker
    )
        public
        returns (bool)
    {
        // Provider must be initiated
        require(isProviderInitiated(msg.sender), "Error: Provider is not yet initiated");
        // Can't reset their curve
        require(getCurveUnset(msg.sender, endpoint), "Error: Curve is already set");
        // Can't initiate null endpoint
        require(endpoint != bytes32(0), "Error: Can't initiate null endpoint");

        setCurve(msg.sender, endpoint, curve);
        db.pushBytesArray(keccak256(abi.encodePacked('oracles', msg.sender, 'endpoints')), endpoint);
        db.setBytes32(keccak256(abi.encodePacked('oracles', msg.sender, endpoint, 'broker')), stringToBytes32(string(abi.encodePacked(broker))));

        emit NewCurve(msg.sender, endpoint, curve, broker);

        return true;
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}
    // Sets provider data
    function setProviderParameter(bytes32 key, bytes memory value) public {
        // Provider must be initiated
        require(isProviderInitiated(msg.sender), "Error: Provider is not yet initiated");

        if (!isProviderParamInitialized(msg.sender, key)) {
            // initialize this provider param
            db.setNumber(keccak256(abi.encodePacked('oracles', msg.sender, 'is_param_set', key)), 1);
            db.pushBytesArray(keccak256(abi.encodePacked('oracles', msg.sender, 'providerParams')), key);
        }
        db.setBytes(keccak256(abi.encodePacked('oracles', msg.sender, 'providerParams', key)), value);
    }

    // Gets provider data
    function getProviderParameter(address provider, bytes32 key) public view returns (bytes memory){
        // Provider must be initiated
        require(isProviderInitiated(provider), "Error: Provider is not yet initiated");
        require(isProviderParamInitialized(provider, key), "Error: Provider Parameter is not yet initialized");
        return db.getBytes(keccak256(abi.encodePacked('oracles', provider, 'providerParams', key)));
    }

    // Gets keys of all provider params
    function getAllProviderParams(address provider) public view returns (bytes32[] memory){
        // Provider must be initiated
        require(isProviderInitiated(provider), "Error: Provider is not yet initiated");
        return db.getBytesArray(keccak256(abi.encodePacked('oracles', provider, 'providerParams')));
    }

    // Set endpoint specific parameters for a given endpoint
    function setEndpointParams(bytes32 endpoint, bytes32[] memory endpointParams) public {
        // Provider must be initiated
        require(isProviderInitiated(msg.sender), "Error: Provider is not yet initialized");
        // Can't set endpoint params on an unset provider
        require(!getCurveUnset(msg.sender, endpoint), "Error: Curve is not yet set");

        db.setBytesArray(keccak256(abi.encodePacked('oracles', msg.sender, 'endpointParams', endpoint)), endpointParams);
    }

    //Set title for registered provider account
    function setProviderTitle(bytes32 title) public {
        require(isProviderInitiated(msg.sender), "Error: Provider is not initiated");
        db.setBytes32(keccak256(abi.encodePacked('oracles', msg.sender, "title")), title);
    }

    //Clear an endpoint with no bonds
    function clearEndpoint(bytes32 endpoint) public {
        require(isProviderInitiated(msg.sender), "Error: Provider is not initiated");

        uint256 bound = db.getNumber(keccak256(abi.encodePacked('totalBound', msg.sender, endpoint)));
        require(bound == 0, "Error: Endpoint must have no bonds");

        int256[] memory nullArray = new int256[](0);
        bytes32[] memory endpoints =  db.getBytesArray(keccak256(abi.encodePacked("oracles", msg.sender, "endpoints")));
        for(uint256 i = 0; i < endpoints.length; i++) {
            if(endpoints[i] == endpoint) {
               db.setBytesArrayIndex(keccak256(abi.encodePacked("oracles", msg.sender, "endpoints")), i, bytes32(0));
               break;
            }
        }
        db.pushBytesArray(keccak256(abi.encodePacked('oracles', msg.sender, 'endpoints')), bytes32(0));
        db.setBytes32(keccak256(abi.encodePacked('oracles', msg.sender, endpoint, 'broker')), bytes32(0));
        db.setIntArray(keccak256(abi.encodePacked('oracles', msg.sender, 'curves', endpoint)), nullArray);
    }

    /// @return public key
    function getProviderPublicKey(address provider) public view returns (uint256) {
        return getPublicKey(provider);
    }

    /// @return oracle name
    function getProviderTitle(address provider) public view returns (bytes32) {
        return getTitle(provider);
    }


    /// @dev get curve paramaters from oracle
    function getProviderCurve(
        address provider,
        bytes32 endpoint
    )
        public
        view
        returns (int[] memory)
    {
        require(!getCurveUnset(provider, endpoint), "Error: Curve is not yet set");
        return db.getIntArray(keccak256(abi.encodePacked('oracles', provider, 'curves', endpoint)));
    }

    function getProviderCurveLength(address provider, bytes32 endpoint) public view returns (uint256){
        require(!getCurveUnset(provider, endpoint), "Error: Curve is not yet set");
        return db.getIntArray(keccak256(abi.encodePacked('oracles', provider, 'curves', endpoint))).length;
    }

    /// @dev is provider initiated
    /// @param oracleAddress the provider address
    /// @return Whether or not the provider has initiated in the Registry.
    function isProviderInitiated(address oracleAddress) public view returns (bool) {
        return getProviderTitle(oracleAddress) != 0;
    }

    /*** STORAGE FUNCTIONS ***/
    /// @dev get public key of provider
    function getPublicKey(address provider) public view returns (uint256) {
        return db.getNumber(keccak256(abi.encodePacked("oracles", provider, "publicKey")));
    }

    /// @dev get title of provider
    function getTitle(address provider) public view returns (bytes32) {
        return db.getBytes32(keccak256(abi.encodePacked("oracles", provider, "title")));
    }

    /// @dev get the endpoints of a provider
    function getProviderEndpoints(address provider) public view returns (bytes32[] memory) {
        return db.getBytesArray(keccak256(abi.encodePacked("oracles", provider, "endpoints")));
    }

    /// @dev get all endpoint params
    function getEndpointParams(address provider, bytes32 endpoint) public view returns (bytes32[] memory) {
        return db.getBytesArray(keccak256(abi.encodePacked('oracles', provider, 'endpointParams', endpoint)));
    }

    /// @dev get broker address for endpoint
    function getEndpointBroker(address oracleAddress, bytes32 endpoint) public view returns (address) {
        return address(uint160(uint256(db.getBytes32(keccak256(abi.encodePacked('oracles', oracleAddress, endpoint, 'broker'))))));
    }

    function getCurveUnset(address provider, bytes32 endpoint) public view returns (bool) {
        return db.getIntArrayLength(keccak256(abi.encodePacked('oracles', provider, 'curves', endpoint))) == 0;
    }

    /// @dev get provider address by index
    function getOracleAddress(uint256 index) public view returns (address) {
        return db.getAddressArrayIndex(keccak256(abi.encodePacked('oracleIndex')), index);
    }

    /// @dev get all oracle addresses
    function getAllOracles() external view returns (address[] memory) {
        return db.getAddressArray(keccak256(abi.encodePacked('oracleIndex')));
    }

    ///  @dev add new provider to mapping
    function createOracle(address provider, uint256 publicKey, bytes32 title) private {
        db.setNumber(keccak256(abi.encodePacked('oracles', provider, "publicKey")), uint256(publicKey));
        db.setBytes32(keccak256(abi.encodePacked('oracles', provider, "title")), title);
    }

    /// @dev add new provider address to oracles array
    function addOracle(address provider) private {
        db.pushAddressArray(keccak256(abi.encodePacked('oracleIndex')), provider);
    }

    /// @dev initialize new curve for provider
    /// @param provider address of provider
    /// @param endpoint endpoint specifier
    /// @param curve flattened array of all segments, coefficients across all polynomial terms, [l0,c0,c1,c2,..., ck, e0, ...]
    function setCurve(
        address provider,
        bytes32 endpoint,
        int[] memory curve
    )
        private
    {
        uint prevEnd = 1;
        uint index = 0;

        // Validate the curve
        while (index < curve.length) {
            // Validate the length of the piece
            int len = curve[index];
            require(len > 0, "Error: Invalid Curve");

            // Validate the end index of the piece
            uint endIndex = index + uint(len) + 1;
            require(endIndex < curve.length, "Error: Invalid Curve");

            // Validate that the end is continuous
            int end = curve[endIndex];
            require(uint(end) > prevEnd, "Error: Invalid Curve");

            prevEnd = uint(end);
            index += uint(len) + 2;
        }

        db.setIntArray(keccak256(abi.encodePacked('oracles', provider, 'curves', endpoint)), curve);
    }

    // Determines whether this parameter has been initialized
    function isProviderParamInitialized(address provider, bytes32 key) private view returns (bool){
        uint256 val = db.getNumber(keccak256(abi.encodePacked('oracles', provider, 'is_param_set', key)));
        return (val == 1) ? true : false;
    }

    /*************************************** STORAGE ****************************************
    * 'oracles', provider, 'endpoints' => {bytes32[]} array of endpoints for this oracle
    * 'oracles', provider, 'endpointParams', endpoint => {bytes32[]} array of params for this endpoint
    * 'oracles', provider, 'curves', endpoint => {uint[]} curve array for this endpoint
    * 'oracles', provider, 'broker', endpoint => {bytes32} broker address for this endpoint
    * 'oracles', provider, 'is_param_set', key => {uint} Is this provider parameter set (0/1)
    * 'oracles', provider, "publicKey" => {uint} public key for this oracle
    * 'oracles', provider, "title" => {bytes32} title of this oracle
    ****************************************************************************************/
}