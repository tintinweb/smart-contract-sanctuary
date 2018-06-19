pragma solidity ^0.4.24;

/**
 * @title Registrar
 */
contract Registrar {
	address private contractOwner;
	bool public paused;

	struct Manifest {
		address registrant;
		bytes32 name;
		uint256 version;
		uint256 index;
		bytes32 hashTypeName;
		string checksum;
		uint256 createdOn;
	}
	
	struct HashType {
	    bytes32 name;
	    bool active;
	}
	
	uint256 public numHashTypes;
	mapping(bytes32 => Manifest) private manifests;
	mapping(address => bytes32[]) private registrantManifests;
	mapping(bytes32 => bytes32[]) private registrantNameManifests;
	mapping(bytes32 => uint256) private registrantNameVersionCount;
	mapping(bytes32 => uint256) public hashTypeIdLookup;
	mapping(uint256 => HashType) public hashTypes;
	
	 /**
	  * @dev Log when a manifest registration is successful
	  */
	event LogManifest(address indexed registrant, bytes32 indexed name, uint256 indexed version, bytes32 hashTypeName, string checksum);

    /**
	 * @dev Checks if contractOwner addresss is calling
	 */
	modifier onlyContractOwner {
		require(msg.sender == contractOwner);
		_;
	}

    /**
	 * @dev Checks if contract is active
	 */
	modifier contractIsActive {
		require(paused == false);
		_;
	}

    /**
     * @dev Checks if the values provided for this manifest are valid
     */
    modifier manifestIsValid(bytes32 name, bytes32 hashTypeName, string checksum, address registrant) {
        require(name != bytes32(0x0) && 
            hashTypes[hashTypeIdLookup[hashTypeName]].active == true &&
            bytes(checksum).length != 0 &&
            registrant != address(0x0) &&
            manifests[keccak256(abi.encodePacked(registrant, name, nextVersion(registrant, name)))].name == bytes32(0x0)
            );
        _;
    }
    
	/**
	 * Constructor
     */
	constructor() public {
		contractOwner = msg.sender;
		addHashType(&#39;sha256&#39;);
	}

    /******************************************/
    /*           OWNER ONLY METHODS           */
    /******************************************/
    
    /**
     * @dev Allows contractOwner to add hashType
     * @param _name The value to be added
     */
    function addHashType(bytes32 _name) public onlyContractOwner {
        require(hashTypeIdLookup[_name] == 0);
        numHashTypes++;
        hashTypeIdLookup[_name] = numHashTypes;
        HashType storage _hashType = hashTypes[numHashTypes];
        
        // Store info about this hashType
        _hashType.name = _name;
        _hashType.active = true;
    }
    
	/**
	 * @dev Allows contractOwner to activate/deactivate hashType
	 * @param _name The name of the hashType
	 * @param _active The value to be set
	 */
	function setActiveHashType(bytes32 _name, bool _active) public onlyContractOwner {
        require(hashTypeIdLookup[_name] > 0);
        hashTypes[hashTypeIdLookup[_name]].active = _active;
	}

    /**
     * @dev Allows contractOwner to pause the contract
     * @param _paused The value to be set
     */
	function setPaused(bool _paused) public onlyContractOwner {
		paused = _paused;
	}
    
    /**
	 * @dev Allows contractOwner to kill the contract
	 */
    function kill() public onlyContractOwner {
		selfdestruct(contractOwner);
	}

    /******************************************/
    /*            PUBLIC METHODS              */
    /******************************************/
	/**
	 * @dev Function to determine the next version value of a manifest
	 * @param _registrant The registrant address of the manifest
	 * @param _name The name of the manifest
	 * @return The next version value
	 */
	function nextVersion(address _registrant, bytes32 _name) public view returns (uint256) {
	    bytes32 registrantNameIndex = keccak256(abi.encodePacked(_registrant, _name));
	    return (registrantNameVersionCount[registrantNameIndex] + 1);
	}
	
	/**
	 * @dev Function to register a manifest
	 * @param _name The name of the manifest
	 * @param _hashTypeName The hashType of the manifest
	 * @param _checksum The checksum of the manifest
	 */
	function register(bytes32 _name, bytes32 _hashTypeName, string _checksum) public 
	    contractIsActive
	    manifestIsValid(_name, _hashTypeName, _checksum, msg.sender) {

	    // Generate registrant name index
	    bytes32 registrantNameIndex = keccak256(abi.encodePacked(msg.sender, _name));
	    
	    // Increment the version for this manifest
	    registrantNameVersionCount[registrantNameIndex]++;
	    
	    // Generate ID for this manifest
	    bytes32 manifestId = keccak256(abi.encodePacked(msg.sender, _name, registrantNameVersionCount[registrantNameIndex]));
	    
        Manifest storage _manifest = manifests[manifestId];
        
        // Store info about this manifest
        _manifest.registrant = msg.sender;
        _manifest.name = _name;
        _manifest.version = registrantNameVersionCount[registrantNameIndex];
        _manifest.index = registrantNameManifests[registrantNameIndex].length;
        _manifest.hashTypeName = _hashTypeName;
        _manifest.checksum = _checksum;
        _manifest.createdOn = now;
        
        registrantManifests[msg.sender].push(manifestId);
        registrantNameManifests[registrantNameIndex].push(manifestId);

	    emit LogManifest(msg.sender, _manifest.name, _manifest.version, _manifest.hashTypeName, _manifest.checksum);
	}

    /**
     * @dev Function to get a manifest registration based on registrant address, manifest name and version
     * @param _registrant The registrant address of the manifest
     * @param _name The name of the manifest
     * @param _version The version of the manifest
     * @return The registrant address of the manifest
     * @return The name of the manifest
     * @return The version of the manifest
     * @return The index of this manifest in registrantNameManifests
     * @return The hashTypeName of the manifest
     * @return The checksum of the manifest
     * @return The created on date of the manifest
     */
	function getManifest(address _registrant, bytes32 _name, uint256 _version) public view 
	    returns (address, bytes32, uint256, uint256, bytes32, string, uint256) {
	        
	    bytes32 manifestId = keccak256(abi.encodePacked(_registrant, _name, _version));
	    require(manifests[manifestId].name != bytes32(0x0));

	    Manifest memory _manifest = manifests[manifestId];
	    return (
	        _manifest.registrant,
	        _manifest.name,
	        _manifest.version,
	        _manifest.index,
	        _manifest.hashTypeName,
	        _manifest.checksum,
	        _manifest.createdOn
	   );
	}

    /**
     * @dev Function to get a manifest registration based on manifestId
     * @param _manifestId The registration ID of the manifest
     * @return The registrant address of the manifest
     * @return The name of the manifest
     * @return The version of the manifest
     * @return The index of this manifest in registrantNameManifests
     * @return The hashTypeName of the manifest
     * @return The checksum of the manifest
     * @return The created on date of the manifest
     */
	function getManifestById(bytes32 _manifestId) public view
	    returns (address, bytes32, uint256, uint256, bytes32, string, uint256) {
	    require(manifests[_manifestId].name != bytes32(0x0));

	    Manifest memory _manifest = manifests[_manifestId];
	    return (
	        _manifest.registrant,
	        _manifest.name,
	        _manifest.version,
	        _manifest.index,
	        _manifest.hashTypeName,
	        _manifest.checksum,
	        _manifest.createdOn
	   );
	}

    /**
     * @dev Function to get the latest manifest registration based on registrant address and manifest name
     * @param _registrant The registrant address of the manifest
     * @param _name The name of the manifest
     * @return The registrant address of the manifest
     * @return The name of the manifest
     * @return The version of the manifest
     * @return The index of this manifest in registrantNameManifests
     * @return The hashTypeName of the manifest
     * @return The checksum of the manifest
     * @return The created on date of the manifest
     */
	function getLatestManifestByName(address _registrant, bytes32 _name) public view
	    returns (address, bytes32, uint256, uint256, bytes32, string, uint256) {
	        
	    bytes32 registrantNameIndex = keccak256(abi.encodePacked(_registrant, _name));
	    require(registrantNameManifests[registrantNameIndex].length > 0);
	    
	    bytes32 manifestId = registrantNameManifests[registrantNameIndex][registrantNameManifests[registrantNameIndex].length - 1];
	    Manifest memory _manifest = manifests[manifestId];

	    return (
	        _manifest.registrant,
	        _manifest.name,
	        _manifest.version,
	        _manifest.index,
	        _manifest.hashTypeName,
	        _manifest.checksum,
	        _manifest.createdOn
	   );
	}
	
	/**
     * @dev Function to get the latest manifest registration based on registrant address
     * @param _registrant The registrant address of the manifest
     * @return The registrant address of the manifest
     * @return The name of the manifest
     * @return The version of the manifest
     * @return The index of this manifest in registrantNameManifests
     * @return The hashTypeName of the manifest
     * @return The checksum of the manifest
     * @return The created on date of the manifest
     */
	function getLatestManifest(address _registrant) public view
	    returns (address, bytes32, uint256, uint256, bytes32, string, uint256) {
	    require(registrantManifests[_registrant].length > 0);
	    
	    bytes32 manifestId = registrantManifests[_registrant][registrantManifests[_registrant].length - 1];
	    Manifest memory _manifest = manifests[manifestId];

	    return (
	        _manifest.registrant,
	        _manifest.name,
	        _manifest.version,
	        _manifest.index,
	        _manifest.hashTypeName,
	        _manifest.checksum,
	        _manifest.createdOn
	   );
	}
	
	/**
     * @dev Function to get a list of manifest Ids based on registrant address
     * @param _registrant The registrant address of the manifest
     * @return Array of manifestIds
     */
	function getManifestIdsByRegistrant(address _registrant) public view returns (bytes32[]) {
	    return registrantManifests[_registrant];
	}

    /**
     * @dev Function to get a list of manifest Ids based on registrant address and manifest name
     * @param _registrant The registrant address of the manifest
     * @param _name The name of the manifest
     * @return Array of registrationsIds
     */
	function getManifestIdsByName(address _registrant, bytes32 _name) public view returns (bytes32[]) {
	    bytes32 registrantNameIndex = keccak256(abi.encodePacked(_registrant, _name));
	    return registrantNameManifests[registrantNameIndex];
	}
	
	/**
     * @dev Function to get manifest Id based on registrant address, manifest name and version
     * @param _registrant The registrant address of the manifest
     * @param _name The name of the manifest
     * @param _version The version of the manifest
     * @return The manifestId of the manifest
     */
	function getManifestId(address _registrant, bytes32 _name, uint256 _version) public view returns (bytes32) {
	    bytes32 manifestId = keccak256(abi.encodePacked(_registrant, _name, _version));
	    require(manifests[manifestId].name != bytes32(0x0));
	    return manifestId;
	}
}