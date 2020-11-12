// File: @evolutionland/common/contracts/interfaces/ISettingsRegistry.sol

pragma solidity ^0.4.24;

contract ISettingsRegistry {
    enum SettingsValueTypes { NONE, UINT, STRING, ADDRESS, BYTES, BOOL, INT }

    function uintOf(bytes32 _propertyName) public view returns (uint256);

    function stringOf(bytes32 _propertyName) public view returns (string);

    function addressOf(bytes32 _propertyName) public view returns (address);

    function bytesOf(bytes32 _propertyName) public view returns (bytes);

    function boolOf(bytes32 _propertyName) public view returns (bool);

    function intOf(bytes32 _propertyName) public view returns (int);

    function setUintProperty(bytes32 _propertyName, uint _value) public;

    function setStringProperty(bytes32 _propertyName, string _value) public;

    function setAddressProperty(bytes32 _propertyName, address _value) public;

    function setBytesProperty(bytes32 _propertyName, bytes _value) public;

    function setBoolProperty(bytes32 _propertyName, bool _value) public;

    function setIntProperty(bytes32 _propertyName, int _value) public;

    function getValueTypeOf(bytes32 _propertyName) public view returns (uint /* SettingsValueTypes */ );

    event ChangeProperty(bytes32 indexed _propertyName, uint256 _type);
}

// File: @evolutionland/common/contracts/interfaces/IInterstellarEncoderV3.sol

pragma solidity ^0.4.24;

contract IInterstellarEncoderV3 {
    uint256 constant CLEAR_HIGH =  0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256 public constant MAGIC_NUMBER = 42;    // Interstellar Encoding Magic Number.
    uint256 public constant CHAIN_ID = 1; // Ethereum mainet.
    uint256 public constant CURRENT_LAND = 1; // 1 is Atlantis, 0 is NaN.

    enum ObjectClass { 
        NaN,
        LAND,
        APOSTLE,
        OBJECT_CLASS_COUNT
    }

    function registerNewObjectClass(address _objectContract, uint8 objectClass) public;

    function encodeTokenId(address _tokenAddress, uint8 _objectClass, uint128 _objectIndex) public view returns (uint256 _tokenId);

    function encodeTokenIdForObjectContract(
        address _tokenAddress, address _objectContract, uint128 _objectId) public view returns (uint256 _tokenId);

    function encodeTokenIdForOuterObjectContract(
        address _objectContract, address nftAddress, address _originNftAddress, uint128 _objectId, uint16 _producerId, uint8 _convertType) public view returns (uint256);

    function getContractAddress(uint256 _tokenId) public view returns (address);

    function getObjectId(uint256 _tokenId) public view returns (uint128 _objectId);

    function getObjectClass(uint256 _tokenId) public view returns (uint8);

    function getObjectAddress(uint256 _tokenId) public view returns (address);

    function getProducerId(uint256 _tokenId) public view returns (uint16);

    function getOriginAddress(uint256 _tokenId) public view returns (address);

}

// File: @evolutionland/common/contracts/interfaces/IAuthority.sol

pragma solidity ^0.4.24;

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

// File: @evolutionland/common/contracts/DSAuth.sol

pragma solidity ^0.4.24;


contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

/**
 * @title DSAuth
 * @dev The DSAuth contract is reference implement of https://github.com/dapphub/ds-auth
 * But in the isAuthorized method, the src from address(this) is remove for safty concern.
 */
contract DSAuth is DSAuthEvents {
    IAuthority   public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(IAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == owner) {
            return true;
        } else if (authority == IAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

// File: contracts/interfaces/IMintableNFT.sol

pragma solidity ^0.4.24;

contract IMintableNFT {
    function mint(address _to, uint256 _encodedTokenId) public;

    function burn(address _to, uint256 _encodedTokenId) public;
}

// File: contracts/DarwiniaITOBase.sol

pragma solidity ^0.4.24;





contract DarwiniaITOBase is DSAuth {

    uint8 public constant DARWINIA_OBJECT_ID = 254;  // Darwinia

    uint16 public constant DARWINIA_PRODUCER_ID = 258;   // From Darwinia

    uint128 public nftCounter = 0;


    // TODO 1: Register Object ID and Object Class on InterstellarEncoderV3

    // TODO 2: Add this contract to the whitelist of ObjectOwnershipAuthorityV2
    
    // TODO 3: Deploy Itering NFT Contract.

    ISettingsRegistry public registry;

    address public nftAddress;

    event NFTMinted(address _operator, uint256 _tokenId, address _owner, uint256 _mark);
    event NFTBurned(address _operator, address _owner, uint256 _tokenId);

    constructor (ISettingsRegistry _registry, address _nftAddress) public {
        registry = _registry;
        nftAddress = _nftAddress;
    }


    function mintObject(address _user, uint16 grade, uint256 _mark) public auth{
        require(nftCounter < 5192296858534827628530496329220095, "overflow");
        nftCounter += 1;
        uint128 customizedTokenId = (uint128(grade) << 112) + nftCounter;
       
        // bytes32 public constant CONTRACT_INTERSTELLAR_ENCODER = "CONTRACT_INTERSTELLAR_ENCODER";
        // 0x434f4e54524143545f494e5445525354454c4c41525f454e434f444552000000
        uint256 tokenId = IInterstellarEncoderV3(registry.addressOf(0x434f4e54524143545f494e5445525354454c4c41525f454e434f444552000000)).encodeTokenIdForOuterObjectContract(
            address(this), nftAddress, nftAddress, customizedTokenId, DARWINIA_PRODUCER_ID, 0);

        IMintableNFT(nftAddress).mint(_user, tokenId);

        emit NFTMinted(msg.sender, tokenId, _user, _mark);
    }

    function burnObject(address _user, uint256 _tokenId) public auth{
        IMintableNFT(nftAddress).burn(_user, _tokenId);

        emit NFTBurned(msg.sender, _user, _tokenId);
    }
}