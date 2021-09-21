/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

// File: contracts/metadata/MetadataProperties.sol



pragma solidity >=0.7.6 <=0.8.0;

library MetaProps {
    //============================================================================================/
    //================================== PROPERTIES -> BITS Mapping  =============================/
    //============================================================================================/

    uint256 internal constant TYPE_ID_BITS = 247;
    uint256 internal constant BRAND_ID_BITS = 239;
    uint256 internal constant CLASS_ID_BITS = 231;
    uint256 internal constant RARITY_BITS = 223;
    uint256 internal constant VISUALS_BITS = 207;
    uint256 internal constant EDITION_BITS = 199;
    uint256 internal constant MOP_BITS = 191;
    uint256 internal constant COP_BITS = 183;
    uint256 internal constant STRENGHT_BITS = 175;
    uint256 internal constant SPEED_BITS = 167;
    uint256 internal constant BATTERY_BITS = 159;
    uint256 internal constant HP_BITS = 151;
    uint256 internal constant ATTACK_BITS = 143;
    uint256 internal constant DEFENSE_BITS = 135;
    uint256 internal constant CRITICAL_BITS = 127;
    uint256 internal constant LUCK_BITS = 119;
    uint256 internal constant SPECIAL_BITS = 111;
}
// File: contracts/utils/access/IERC173.sol



pragma solidity >=0.7.6 <=0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}

// File: contracts/metatx/ManagedIdentity.sol



pragma solidity >=0.7.6 <=0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}
// File: contracts/utils/access/Ownable.sol



pragma solidity >=0.7.6 <=0.8.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}
// File: contracts/metadata/CoreMetadata.sol



pragma solidity >=0.7.6 <=0.8.0;



contract CoreMetadata is ManagedIdentity, Ownable{
    
    constructor() Ownable(msg.sender){}
    // EVENTS
    event CoreMetadataSet(uint256 id, uint256 properties);
    event PropertyUpdated(uint256 tokenId, uint8 position, uint256 propertyValue);
    // TokenID => properties mapping
    mapping(uint256 => uint256) public metadataRepository;

    // Bitwise operations
    uint constant internal ONE = uint(1);
    uint constant internal ONES = uint(~0);
    uint constant internal bits = 8;
    
    //  Update or insert an item
    function insertMetadata(uint256 id, uint256 properties) private {
        _requireOwnership(_msgSender());
        metadataRepository[id] = properties;
        emit CoreMetadataSet(id, properties);
    }

   function getMetadataForProperty(uint256 id, uint8 position) external view returns (uint256) {
       require(0 < bits && position < 256 && position + bits <= 256);
       uint256 meta = metadataRepository[id];
        return meta >> position & ONES >> 256 - bits;
   }
   
   function getMetadataByTokenId(uint256 tokenId) external view returns (uint256) {
        return metadataRepository[tokenId];   
   }
   
   function upgradeProperty(uint256 tokenId, uint8 position, uint256 propertyValue) public {
       require(0 < bits && position < 256 && position + bits <= 256);
       uint256 meta = metadataRepository[tokenId];
       meta |= (propertyValue << position);
       insertMetadata(tokenId, meta);
       emit PropertyUpdated(tokenId,position,propertyValue);
   }

    struct Metadata {
        uint256 typeId;
        uint256 brandId;
        uint256 classId;
        uint256 rarity;
        uint256 visuals;
        uint256 edition;
        uint256 mop;
        uint256 cop;
        uint256 strength;
        uint256 speed;
        uint256 battery;
        uint256 HP;
        uint256 attack; 
        uint256 defense; 
        uint256 critical; 
        uint256 luck; 
        uint256 special; 
    }
  

    uint256 constant CRATE_TIER_LEGENDARY = 0;
    uint256 constant CRATE_TIER_EPIC = 1;
    uint256 constant CRATE_TIER_RARE = 2;
    uint256 constant CRATE_TIER_COMMON = 3;

    //============================================================================================/
    //================================== Metadata Mappings  ======================================/
    //============================================================================================/

    uint256 internal constant _NF_FLAG = 1 << 255;
    uint256 internal constant _SEASON_ID_2020 = 3;

    


    function makeMetadata(uint256 tokenId) public {
        
        Metadata memory metadata;

        metadata.typeId= 5;         
        metadata.brandId= 1;
        metadata.classId= 4;
        metadata.rarity= 1;
        metadata.visuals= 2;
        metadata.edition= 1;
        metadata.mop= 50;
        metadata.cop= 40;
        metadata.strength= 10;
        metadata.speed= 30;
        metadata.battery= 15;
        metadata.HP= 10;
        metadata.attack= 20;
        metadata.defense= 15;
        metadata.critical= 23;
        metadata.luck = 16;
        metadata.special = 10;

        uint256 metadataId = _makeTokenId(metadata);
        insertMetadata(tokenId, metadataId);
        emit CoreMetadataSet(tokenId, metadataId);
    }


    function _makeTokenId(Metadata memory metadata) private pure returns (uint256 tokenId) {
        tokenId = (metadata.typeId << 247);
        tokenId |= (metadata.brandId << 239);
        tokenId |= (metadata.classId << 231);
        tokenId |= (metadata.rarity << 223);
        tokenId |= (metadata.visuals << 207);
        tokenId |= (metadata.edition << 199);
        tokenId |= (metadata.mop << 191);
        tokenId |= (metadata.cop << 183);
        tokenId |= (metadata.strength << 175);
        tokenId |= (metadata.speed << 167);        
        tokenId |= (metadata.battery << 159);
        tokenId |= (metadata.HP << 151);
        tokenId |= (metadata.attack << 143);
        tokenId |= (metadata.defense << 135);
        tokenId |= (metadata.critical << 127);
        tokenId |= (metadata.luck << 119);
        tokenId |= (metadata.special << 111);
       // tokenId |= metadata.counter;
    }
}