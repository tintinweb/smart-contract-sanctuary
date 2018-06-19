pragma solidity ^0.4.23;

/**
 * @title IngressRegistrar
 */
contract IngressRegistrar {
	address private owner;
	bool public paused;

	struct Manifest {
		address registrant;
		bytes32 name;
		bytes32 version;
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
	mapping(bytes32 => uint256) public hashTypeIdLookup;
	mapping(uint256 => HashType) public hashTypes;
	
	 /**
	  * @dev Log when a manifest registration is successful
	  */
	event LogManifest(address indexed registrant, bytes32 indexed name, bytes32 indexed version, bytes32 hashTypeName, string checksum);

    /**
	 * @dev Checks if owner addresss is calling
	 */
	modifier onlyOwner {
		require(msg.sender == owner);
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
    modifier manifestIsValid(bytes32 name, bytes32 version, bytes32 hashTypeName, string checksum, address registrant) {
        require(name != bytes32(0x0) && 
            version != bytes32(0x0) && 
            hashTypes[hashTypeIdLookup[hashTypeName]].active == true &&
            bytes(checksum).length != 0 &&
            registrant != address(0x0) &&
            manifests[keccak256(registrant, name, version)].name == bytes32(0x0)
            );
        _;
    }
    
	/**
	 * Constructor
     */
	constructor() public {
		owner = msg.sender;
		addHashType(&#39;md5&#39;);
		addHashType(&#39;sha1&#39;);
	}

    /******************************************/
    /*           OWNER ONLY METHODS           */
    /******************************************/
    
    /**
     * @dev Allows owner to add hashType
     * @param name The value to be added
     */
    function addHashType(bytes32 name) public onlyOwner {
        require(hashTypeIdLookup[name] == 0);
        numHashTypes++;
        hashTypeIdLookup[name] = numHashTypes;
        HashType storage _hashType = hashTypes[numHashTypes];
        
        // Store info about this hashType
        _hashType.name = name;
        _hashType.active = true;
    }
    
	/**
	 * @dev Allows owner to activate/deactivate hashType
	 * @param name The name of the hashType
	 * @param active The value to be set
	 */
	function setActiveHashType(bytes32 name, bool active) public onlyOwner {
        require(hashTypeIdLookup[name] > 0);
        hashTypes[hashTypeIdLookup[name]].active = active;
	}
    
    /**
	 * @dev Allows owner to kill the contract
	 */
    function kill() public onlyOwner {
		selfdestruct(owner);
	}

    /**
     * @dev Allows owner to pause the contract
     * @param _paused The value to be set
     */
	function setPaused(bool _paused) public onlyOwner {
		paused = _paused;
	}
	
    /******************************************/
    /*            PUBLIC METHODS              */
    /******************************************/
	
	/**
	 * @dev Function to register a manifest
	 * @param name The name of the manifest
	 * @param version The version of the manifest
	 * @param hashTypeName The hashType of the manifest
	 * @param checksum The checksum of the manifest
	 */
	function register(bytes32 name, bytes32 version, bytes32 hashTypeName, string checksum) public 
	    contractIsActive
	    manifestIsValid(name, version, hashTypeName, checksum, msg.sender) {
	    
	    // Generate ID for this manifest
	    bytes32 manifestId = keccak256(msg.sender, name, version);
	    
	    // Generate registrant name index
	    bytes32 registrantNameIndex = keccak256(msg.sender, name);

        Manifest storage _manifest = manifests[manifestId];
        
        // Store info about this manifest
        _manifest.registrant = msg.sender;
        _manifest.name = name;
        _manifest.version = version;
        _manifest.index = registrantNameManifests[registrantNameIndex].length;
        _manifest.hashTypeName = hashTypeName;
        _manifest.checksum = checksum;
        _manifest.createdOn = now;
        
        registrantManifests[msg.sender].push(manifestId);
        registrantNameManifests[registrantNameIndex].push(manifestId);

	    emit LogManifest(msg.sender, name, version, hashTypeName, checksum);
	}

    /**
     * @dev Function to get a manifest registration based on registrant address, manifest name and version
     * @param registrant The registrant address of the manifest
     * @param name The name of the manifest
     * @param version The version of the manifest
     * @return The registrant address of the manifest
     * @return The name of the manifest
     * @return The version of the manifest
     * @return The index of this manifest in registrantNameManifests
     * @return The hashTypeName of the manifest
     * @return The checksum of the manifest
     * @return The created on date of the manifest
     */
	function getManifest(address registrant, bytes32 name, bytes32 version) public view 
	    returns (address, bytes32, bytes32, uint256, bytes32, string, uint256) {
	        
	    bytes32 manifestId = keccak256(registrant, name, version);
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
     * @param manifestId The registration ID of the manifest
     * @return The registrant address of the manifest
     * @return The name of the manifest
     * @return The version of the manifest
     * @return The index of this manifest in registrantNameManifests
     * @return The hashTypeName of the manifest
     * @return The checksum of the manifest
     * @return The created on date of the manifest
     */
	function getManifestById(bytes32 manifestId) public view
	    returns (address, bytes32, bytes32, uint256, bytes32, string, uint256) {
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
     * @dev Function to get the latest manifest registration based on registrant address and manifest name
     * @param registrant The registrant address of the manifest
     * @param name The name of the manifest
     * @return The registrant address of the manifest
     * @return The name of the manifest
     * @return The version of the manifest
     * @return The index of this manifest in registrantNameManifests
     * @return The hashTypeName of the manifest
     * @return The checksum of the manifest
     * @return The created on date of the manifest
     */
	function getLatestManifestByName(address registrant, bytes32 name) public view
	    returns (address, bytes32, bytes32, uint256, bytes32, string, uint256) {
	        
	    bytes32 registrantNameIndex = keccak256(registrant, name);
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
     * @param registrant The registrant address of the manifest
     * @return The registrant address of the manifest
     * @return The name of the manifest
     * @return The version of the manifest
     * @return The index of this manifest in registrantNameManifests
     * @return The hashTypeName of the manifest
     * @return The checksum of the manifest
     * @return The created on date of the manifest
     */
	function getLatestManifest(address registrant) public view
	    returns (address, bytes32, bytes32, uint256, bytes32, string, uint256) {
	    require(registrantManifests[registrant].length > 0);
	    
	    bytes32 manifestId = registrantManifests[registrant][registrantManifests[registrant].length - 1];
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
     * @param registrant The registrant address of the manifest
     * @return Array of manifestIds
     */
	function getManifestIdsByRegistrant(address registrant) public view returns (bytes32[]) {
	    return registrantManifests[registrant];
	}

    /**
     * @dev Function to get a list of manifest Ids based on registrant address and manifest name
     * @param registrant The registrant address of the manifest
     * @param name The name of the manifest
     * @return Array of registrationsIds
     */
	function getManifestIdsByName(address registrant, bytes32 name) public view returns (bytes32[]) {
	    bytes32 registrantNameIndex = keccak256(registrant, name);
	    return registrantNameManifests[registrantNameIndex];
	}
	
	/**
     * @dev Function to get manifest Id based on registrant address, manifest name and version
     * @param registrant The registrant address of the manifest
     * @param name The name of the manifest
     * @param version The version of the manifest
     * @return The manifestId of the manifest
     */
	function getManifestId(address registrant, bytes32 name, bytes32 version) public view returns (bytes32) {
	    bytes32 manifestId = keccak256(registrant, name, version);
	    require(manifests[manifestId].name != bytes32(0x0));
	    return manifestId;
	}
}