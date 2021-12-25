//Arkius Public Benefit Corporation Privileged & Confidential
// SPDX-License-Identifier: None
pragma solidity 0.8.0;
pragma abicoder v2;

import './interfaces/IArkiusAttentionSeekerToken.sol';
import './interfaces/ICertification.sol';
import './utils/Ownable.sol';

/**
 * @dev EntityContract This contract is for the Attention Seekers only.
 *
 * Attention Seekers can create the Entity with the help of this Contract.
 *
 * Entity can be of 3 types:- Product, Company or Campaign
 *
 */

contract EntityContract is Ownable {

    /**
     * @dev Attention Seeker Token interface instance
     *
     * Used to call a function from AttentionSeekerNFT
     * which return the Attention Seeker ID of the caller
     */
    IArkiusAttentionSeekerToken attentionSeekerToken;

    ICertification private certification;

    uint256 immutable private TIMESTAMP;

    /**
     * Emitted when Entity is created.
     */
    event CreateEntity(uint256 indexed id, string title, EntityType types, string description, string metadata);

    /**
     * Emitted when Attention Seeker edit the Entity
     */
    event EditEntity(uint256 indexed id, string title, string metadata, string description);

    event CampaignContractUpdated(address campaignAddress);

    event CertificationContractUpdated(address certificationAddress);

    event SeekerContractUpdated(address seekerAddress );


    /**
     * Emitted when Entity is deleted
     */
    event DeleteEntity(address indexed owner, uint256 indexed id);


    enum EntityType {e_product, e_company, e_campaign}

    /**
     * @dev Contains the info about the Entity
     * @param id          Id of the Entity.
     * @param creator     Address of the Attention Seeker who created the Entity.
     * @param entityType  Product Campaign or product.
     * @param description Description of the Entity.
     * @param metadata    Metadata of the Entity.
     */
    struct Entity {
        uint256    id;
        address    creator;
        EntityType entityType;
        string     title;
        string     description;
        string     metadata;
    }

    /// @dev mapping from entity Id => Entity structure.
    mapping (uint256 => Entity) private entities;

    /// @dev mapping from AttentionSeekerAddress  => AttentionSeeker's created Entities' IDs.
    mapping (address => uint256[]) private attentionSeekerEntities;

    /// @dev mapping from id => index of id's of entities created by an attention seeker.
    mapping(uint256 => uint256) private idIndexAttentionSeeker;


    /// @dev array for all Entities' IDs.
    uint256[] private allEntities;

    /// @dev mapping from id => index of id in allEntities.
    mapping(uint256 => uint256) private idIndexEntity;

    uint256 constant c_invalid = 0;

    /// @dev Contract address of the Campaign Contract.
    address private campaignContractAddress;

    /**
     * @dev initialize the AttentionSeekerContract address.
     *
     * @param attentionSeekerContractAddress Address of Attention Seeker Contract.
     *
     */
    constructor(IArkiusAttentionSeekerToken attentionSeekerContractAddress, address multisigAddress) Ownable(multisigAddress) {
        require(address(attentionSeekerContractAddress) != address(0), "Invalid Seeker Address");
        require(multisigAddress                         != address(0), "Invalid Multisig Address");
        attentionSeekerToken = attentionSeekerContractAddress;
        TIMESTAMP = block.timestamp;
    }

    /**
     * @dev Creates an Entity. This can only be created by Attention Seeker.
     * @param timestamp   Timestamp in seconds.
     * @param title       Title of the Entity.
     * @param types       Product, campaign or company
     * @param description Description about the Entity.
     * @param metadata    Metadata about the Entity.
     */
    function createEntity(uint256       timestamp,
                          string memory title,
                          EntityType    types,
                          string memory description,
                          string memory metadata,
                          address       attentionSeekerAddress
                         ) external {

        require(TIMESTAMP <= timestamp && timestamp <= block.timestamp, "Invalid timestamp");

        require(bytes(title      ).length != 0, "No title provided");
        require(bytes(description).length != 0, "No description provided");
        require(bytes(metadata   ).length != 0, "No metadata provided");

        uint256 id;

        if(_msgSender() == campaignContractAddress){
            id = hash(attentionSeekerAddress, metadata, timestamp);
            createEntityI(id, title, types, description, metadata, attentionSeekerAddress);
        }
        else {
            uint256 attentionSeekerId  = attentionSeekerToken.attentionSeekerIdOf(_msgSender());
            require(attentionSeekerId != c_invalid , "Caller is not the Attention Seeker");
            id = hash(_msgSender(), metadata, timestamp);
            createEntityI(id, title, types, description, metadata, _msgSender());
        }
    }

    function createEntityI(uint256       id,
                           string memory title,
                           EntityType    types,
                           string memory description,
                           string memory metadata,
                           address       attentionSeekerAddress) internal {

        require(entities[id].id != id, "ID already exists!");

        Entity memory newEntity = Entity(id, attentionSeekerAddress, types, title, description, metadata);
        entities[id] = newEntity;

        attentionSeekerEntities[attentionSeekerAddress].push(id);
        allEntities.push(id);

        idIndexEntity[id]          = allEntities.length;
        idIndexAttentionSeeker[id] = attentionSeekerEntities[attentionSeekerAddress].length;

        emit CreateEntity(id, title, types, description, metadata);

    }
    /**
     * @dev Edits an Entity. This can only be done by Attention Seeker who created the particular Entity.
     * @param id          Id of the Entity to be edited.
     * @param title       Title of the Entity.
     * @param description Description about the Entity.
     * @param metadata    Metadata about the Entity.
     */
     function editEntity(uint256       id,
                         string memory title,
                         string memory description,
                         string memory metadata,
                         address       attentionSeekerAddress
                        ) external {
        
        if(_msgSender() == campaignContractAddress){
            editEntityI(id, title, description, metadata, attentionSeekerAddress);
        }
        else {
            uint256 attentionSeekerId  = attentionSeekerToken.attentionSeekerIdOf(_msgSender());
            require(attentionSeekerId != c_invalid , "Caller is not the Attention Seeker");
            editEntityI(id, title, description, metadata, _msgSender());
        }
    }

    function editEntityI(uint256       id,
                         string memory title,
                         string memory description,
                         string memory metadata,
                         address       attentionSeekerAddress) internal {

        require(entities[id].creator == attentionSeekerAddress, "You are not the creator of the Entity");

        if (bytes(metadata   ).length != 0) entities[id].metadata    = metadata;
        if (bytes(title      ).length != 0) entities[id].title       = title;
        if (bytes(description).length != 0) entities[id].description = description;

        emit EditEntity(id, title, description, metadata);
    }

    function hash(address add, string memory data, uint256 timestamp) internal pure returns(uint256 hashId) {
        hashId = uint(keccak256(abi.encodePacked(add, data, timestamp)));
        return hashId;
    }

    /**
     * @dev Returns all IDs of Entities in existence.
     */
    function getAllEntities() external view returns(uint256[] memory){
        return allEntities;
    }

    /**
     * @dev Returns an Entity corresponding to particular EntityID.
     * @param id Id of the entity.
     *
     * @return All the details of an Entity
     */

    function getEntity(uint256 id) external view returns(Entity memory){
        return entities[id];
    }

    /**
     * @dev Returns an Entity corresponding to particular EntityID.
     * @param attentionSeeker Id of the entity.
     *
     * @return allID It contains all the ID's of the Entity created by an Attention Seeker
     */

    function getAttentionSeekerEntities(address attentionSeeker) external view returns(uint256[] memory){
        uint256[] memory allID = attentionSeekerEntities[attentionSeeker];
        return allID;
    }

    /**
     * @dev Deletes an Entity. This can only be deleted by Attention Seeker who created it.
     * @param id Id of the entity.
     */
    function deleteEntity(uint256 id, address attentionSeekerAddress) external {
        if(_msgSender() == campaignContractAddress){
            deleteEntityI(id, attentionSeekerAddress);
        }
        else {
            uint256 attentionSeekerId  = attentionSeekerToken.attentionSeekerIdOf(_msgSender());
            require(attentionSeekerId != c_invalid , "Caller is not the Attention Seeker");
            deleteEntityI(id, _msgSender());
        }
    }

    function deleteEntityI(uint256 id, address attentionSeekerAddress) internal {

        require(entities[id].id != c_invalid, "This Id doesn't exist");
        require(entities[id].creator == attentionSeekerAddress,"You are not the creator of this Entity.");

        uint256 index  = idIndexEntity[id];
        uint256 length = allEntities.length - 1;

        certification.unsubscribeEntity(id);

        if (index > 0) {
            allEntities[index - 1] = allEntities[length];
            idIndexEntity[allEntities[length]] = index;
            idIndexEntity[id] = 0;
            allEntities.pop();
        }

        index  = idIndexAttentionSeeker[id];
        length = attentionSeekerEntities[attentionSeekerAddress].length - 1;

        if (index > 0) {
            attentionSeekerEntities[attentionSeekerAddress][index - 1] =  attentionSeekerEntities[attentionSeekerAddress][length];
            idIndexAttentionSeeker[attentionSeekerEntities[attentionSeekerAddress][length]] = index;
            idIndexAttentionSeeker[id] = 0;
            attentionSeekerEntities[attentionSeekerAddress].pop();
        }

        delete entities[id];

        entities[id].id = id;
        emit DeleteEntity(attentionSeekerAddress, id);
    }

    /**
     * @dev Sets the campaign contract address. This can only be done by the Owner of the contract.
     * @param campaignAddress address campaign contract address
     */
    function setCampaignContractAddress(address campaignAddress) external onlyOwner() {
        require(campaignAddress != address(0),"Invalid Campaign Address.");
        campaignContractAddress = campaignAddress;
        emit CampaignContractUpdated(campaignAddress);
    }

    function setCertification(ICertification certificationAddress) external onlyOwner() {
        require(address(certificationAddress) != address(0), "Invalid Certification address.");
        certification = certificationAddress;
        emit CertificationContractUpdated(address(certificationAddress));
    }

    function updateSeekerContract(IArkiusAttentionSeekerToken seekerAddress) external onlyOwner {
        require(address(seekerAddress) != address(0), "Invalid Seeker address.");
        attentionSeekerToken = seekerAddress;
        emit SeekerContractUpdated(address(seekerAddress));
    }

    function seekerContract() external view returns(IArkiusAttentionSeekerToken) {
        return attentionSeekerToken;
    }

    function campaignContract() external view returns(address) {
        return campaignContractAddress;
    }

    function certificationContract() external view returns(ICertification) {
        return certification;
    }

    function entityExist(uint256 id) external view returns(bool) {
        bool res;
        if (entities[id].id == id) res = true;
        return res;
    }

    modifier onlyAttentionSeeker() {
        uint256 id  = attentionSeekerToken.attentionSeekerIdOf(_msgSender());
        require(id != c_invalid, "Caller is not an Attention Seeker");
        _;
    }
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

interface IArkiusAttentionSeekerToken {
    function attentionSeekerIdOf(address owner) external view returns (uint256);

    function burn(address owner, uint256 value) external;
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;
pragma abicoder v2;

interface ICertification {

    function unsubscribeEntity(uint256 entityId) external;

}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipNominated(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address multisig) {
        _owner = multisig;
        emit OwnershipTransferred(address(0), multisig);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Nominate new Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        _nominatedOwner = newOwner;
        emit OwnershipNominated(_owner,newOwner);
    }

    /**
     * @dev Nominated Owner can accept the Ownership of the contract.
     * Can only be called by the nominated owner.
     */
    function acceptOwnership() external {
        require(msg.sender == _nominatedOwner, "Ownable: You must be nominated before you can accept ownership");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
        _nominatedOwner = address(0);
    }
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {

    /// Empty constructor, to prevent people from mistakenly deploying
    /// an instance of this contract, which should be used via inheritance.

    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {

        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}