pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public{
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract ERC721Interface {
    // Required methods
    // function totalSupply() public view returns (uint256 total);
    // function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    // function approve(address _to, uint256 _tokenId) external;
    // function transfer(address _to, uint256 _tokenId) external;
    // function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

/** 
 * @dev Name provider contract
 * Allows saving names and descriptons for specified addresses and tokens
 */
contract NameProvider is Ownable {
    
    uint256 public FEE = 1 finney;
    
    //name storage for addresses
    mapping(bytes32 => mapping(address => string)) addressNames;
    
    //marks namespaces as already used on first name save to specified namespace
    mapping(bytes32 => bool) takenNamespaces;
    
    //name storage for tokens
    mapping(address => mapping(uint256 => string)) tokenNames;
    
    //description storage for tokens
    mapping(address => mapping(uint256 => string)) tokenDescriptions;
    
    /* EVENTS */
    
    event NameChanged(bytes32 namespace, address account, string name);
    
    event TokenNameChanged(address tokenProvider, uint256 tokenId, string name);
    
    event TokenDescriptionChanged(address tokenProvider, uint256 tokenId, string description);
    
    function NameProvider(address _owner) public {
        require(_owner != address(0));
        owner = _owner;
    }
    
    modifier setTokenText(address _tokenInterface, uint256 _tokenId, string _text){
        //check fee
        require(msg.value >= FEE);
        //no empty strings allowed
        require(bytes(_text).length > 0);
        
        ERC721Interface tokenInterface = ERC721Interface(_tokenInterface);
        //only token owner can set its name
        require(msg.sender == tokenInterface.ownerOf(_tokenId));
        
        _;//set text code
        
        //return excess
        if (msg.value > FEE) {
            msg.sender.transfer(msg.value - FEE);
        }
    }
    
    //@dev set name for specified token,
    // NB msg.sender must be owner of the specified token.
    //@param _tokenInterface ERC721 protocol provider address
    //@param _tokenId id of the token, whose name will be set
    //@param _name string that will be set as new token name
    function setTokenName(address _tokenInterface, uint256 _tokenId, string _name) 
    setTokenText(_tokenInterface, _tokenId, _name) external payable {
        _setTokenName(_tokenInterface, _tokenId, _name);
    }
    
    //@dev set description for specified token,
    // NB msg.sender must be owner of the specified token.
    //@param _tokenInterface ERC721 protocol provider address
    //@param _tokenId id of the token, whose description will be set
    //@param _description string that will be set as new token description
    function setTokenDescription(address _tokenInterface, uint256 _tokenId, string _description)
    setTokenText(_tokenInterface, _tokenId, _description) external payable {
        _setTokenDescription(_tokenInterface, _tokenId, _description);
    }
    
    //@dev get name of specified token,
    //@param _tokenInterface ERC721 protocol provider address
    //@param _tokenId id of the token, whose name will be returned
    function getTokenName(address _tokenInterface, uint256 _tokenId) external view returns(string) {
        return tokenNames[_tokenInterface][_tokenId];
    }
    
    //@dev get description of specified token,
    //@param _tokenInterface ERC721 protocol provider address
    //@param _tokenId id of the token, whose description will be returned
    function getTokenDescription(address _tokenInterface, uint256 _tokenId) external view returns(string) {
        return tokenDescriptions[_tokenInterface][_tokenId];
    }
    
    //@dev set global name for msg.sender,
    // NB msg.sender must be owner of the specified token.
    //@param _name string that will be set as new address name
    function setName(string _name) external payable {
        setServiceName(bytes32(0), _name);
    }
    
    //@dev set name for msg.sender in cpecified namespace,
    // NB msg.sender must be owner of the specified token.
    //@param _namespace bytes32 service identifier
    //@param _name string that will be set as new address name
    function setServiceName(bytes32 _namespace, string memory _name) public payable {
        //check fee
        require(msg.value >= FEE);
        //set name
        _setName(_namespace, _name);
        //return excess
        if (msg.value > FEE) {
            msg.sender.transfer(msg.value - FEE);
        }
    }
    
    //@dev get global name for specified address,
    //@param _address the address for whom name string will be returned
    function getNameByAddress(address _address) external view returns(string) {
        return addressNames[bytes32(0)][_address];
    }
    
    //@dev get global name for msg.sender,
    function getName() external view returns(string) {
        return addressNames[bytes32(0)][msg.sender];
    }
    
    //@dev get name for specified address and namespace,
    //@param _namespace bytes32 service identifier
    //@param _address the address for whom name string will be returned
    function getServiceNameByAddress(bytes32 _namespace, address _address) external view returns(string) {
        return addressNames[_namespace][_address];
    }
    
    //@dev get name for specified namespace and msg.sender,
    //@param _namespace bytes32 service identifier
    function getServiceName(bytes32 _namespace) external view returns(string) {
        return addressNames[_namespace][msg.sender];
    }
    
    //@dev get names for specified addresses in global namespace (bytes32(0))
    //@param _address address[] array of addresses for whom names will be returned
    //@return namesData bytes32 
    //@return nameLength number of bytes32 in address name, sum of nameLength values equals namesData.length (1 to 1 with _address) 
    function getNames(address[] _address) external view returns(bytes32[] namesData, uint256[] nameLength) {
        return getServiceNames(bytes32(0), _address);
	}
	
	//@dev get names for specified tokens 
    //@param _tokenIds uint256[] array of ids for whom names will be returned
    //@return namesData bytes32 
    //@return nameLength number of bytes32 in token name, sum of nameLength values equals namesData.length (1 to 1 with _tokenIds) 
	function getTokenNames(address _tokenInterface, uint256[] _tokenIds) external view returns(bytes32[] memory namesData, uint256[] memory nameLength) {
        return _getTokenTexts(_tokenInterface, _tokenIds, true);
	}
	
	//@dev get names for specified tokens 
    //@param _tokenIds uint256[] array of ids for whom descriptons will be returned
    //@return descriptonData bytes32 
    //@return descriptionLength number of bytes32 in token name, sum of nameLength values equals namesData.length (1 to 1 with _tokenIds) 
	function getTokenDescriptions(address _tokenInterface, uint256[] _tokenIds) external view returns(bytes32[] memory descriptonData, uint256[] memory descriptionLength) {
        return _getTokenTexts(_tokenInterface, _tokenIds, false);
	}
	
	//@dev get names for specified addresses and namespace
	//@param _namespace bytes32 namespace identifier
    //@param _address address[] array of addresses for whom names will be returned
    //@return namesData bytes32 
    //@return nameLength number of bytes32 in address name, sum of nameLength values equals namesData.length (1 to 1 with _address) 
    function getServiceNames(bytes32 _namespace, address[] _address) public view returns(bytes32[] memory namesData, uint256[] memory nameLength) {
        uint256 length = _address.length;
        nameLength = new uint256[](length);
        
        bytes memory stringBytes;
        uint256 size = 0;
        uint256 i;
        for (i = 0; i < length; i ++) {
            stringBytes = bytes(addressNames[_namespace][_address[i]]);
            size += nameLength[i] = stringBytes.length % 32 == 0 ? stringBytes.length / 32 : stringBytes.length / 32 + 1;
        }
        namesData = new bytes32[](size);
        size = 0;
        for (i = 0; i < length; i ++) {
            size += _stringToBytes32(addressNames[_namespace][_address[i]], namesData, size);
        }
    }
    
    function namespaceTaken(bytes32 _namespace) external view returns(bool) {
        return takenNamespaces[_namespace];
    }
    
    function setFee(uint256 _fee) onlyOwner external {
        FEE = _fee;
    }
    
    function withdraw() onlyOwner external {
        owner.transfer(this.balance);
    }
    
    function _setName(bytes32 _namespace, string _name) internal {
        addressNames[_namespace][msg.sender] = _name;
        if (!takenNamespaces[_namespace]) {
            takenNamespaces[_namespace] = true;
        }
        NameChanged(_namespace, msg.sender, _name);
    }
    
    function _setTokenName(address _tokenInterface, uint256 _tokenId, string _name) internal {
        tokenNames[_tokenInterface][_tokenId] = _name;
        TokenNameChanged(_tokenInterface, _tokenId, _name);
    }
    
    function _setTokenDescription(address _tokenInterface, uint256 _tokenId, string _description) internal {
        tokenDescriptions[_tokenInterface][_tokenId] = _description;
        TokenDescriptionChanged(_tokenInterface, _tokenId, _description);
    }
    
    function _getTokenTexts(address _tokenInterface, uint256[] memory _tokenIds, bool names) internal view returns(bytes32[] memory namesData, uint256[] memory nameLength) {
        uint256 length = _tokenIds.length;
        nameLength = new uint256[](length);
        mapping(address => mapping(uint256 => string)) textMap = names ? tokenNames : tokenDescriptions;
        
        bytes memory stringBytes;
        uint256 size = 0;
        uint256 i;
        for (i = 0; i < length; i ++) {
            stringBytes = bytes(textMap[_tokenInterface][_tokenIds[i]]);
            size += nameLength[i] = stringBytes.length % 32 == 0 ? stringBytes.length / 32 : stringBytes.length / 32 + 1;
        }
        namesData = new bytes32[](size);
        size = 0;
        for (i = 0; i < length; i ++) {
            size += _stringToBytes32(textMap[_tokenInterface][_tokenIds[i]], namesData, size);
        }
    }
    
        
    function _stringToBytes32(string memory source, bytes32[] memory namesData, uint256 _start) internal pure returns (uint256) {
        bytes memory stringBytes = bytes(source);
        uint256 length = stringBytes.length;
        bytes32[] memory result = new bytes32[](length % 32 == 0 ? length / 32 : length / 32 + 1);
        
        bytes32 word;
        uint256 index = 0;
        uint256 limit = 0;
        for (uint256 i = 0; i < length; i += 32) {
            limit = i + 32;
            assembly {
                word := mload(add(source, limit))
            }
            namesData[_start + index++] = word;
        }
        return result.length;
    }
}