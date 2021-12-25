//Arkius Public Benefit Corporation Privileged & Confidential
// SPDX-License-Identifier: None
pragma solidity 0.8.0;
pragma abicoder v2;

import "./interfaces/IArkiusMembershipToken.sol";
import "./interfaces/IArkiusCertifierToken.sol";
import "./interfaces/IArkiusAttentionSeekerToken.sol";
import "./interfaces/IEntity.sol";
import "./utils/Ownable.sol";

/**
 * @dev CampaignContract This contract is for the certifiers only.
 *
 * Certifier can generate certifications of the entity with this contract.
 *
 * Certification can be of 2 types:- Static and Dynamic.
 *
 */

contract Certifications is Ownable {

    /**
     * @dev Arkius Membership Token instance.
     *
     * Used to call a function from MembershipNFT,
     * which return the member ID of the caller
     */
    IArkiusMembershipToken arkiusMembershipToken;

    /**
     * @dev Arkius Certifier Token instance.
     *
     * Used to call a function from CertifierNFT,
     * which return the certifier ID of the caller
     */
    IArkiusCertifierToken arkiusCertifierToken;

    /**
     * @dev Entity instance.
     *
     * Used to call a functions from Entity.
     */
    IEntity entity;

    uint256 constant INVALID = 0;

    uint256 private immutable TIMESTAMP;

    /// Emitted when static certificate is created by the certifier.
    event CreateStaticCertification(uint256 indexed id, string indexed title, address indexed creator);

    /// Emitted when dynamic certificate is created by the certifier.
    event CreateDynamicCertification(uint256 indexed id, string indexed apiLink);

    /// Emitted when certifier certifies static entity.
    event CertifyStaticEntity(uint256 indexed certificationID, uint256 indexed entityID, uint256 indexed certification);

    /// Emitted when certifier update dynamic certificate.
    event UpdateDynamicEntity(uint256 indexed certificationID, string indexed apiLink);

    /// Emitted when seeker applies for certification.
    event ApplyCertification(uint256 indexed certificationID, uint256 indexed entityID);

    /// Emitted when entity or certification is deleted
    event UnsubscribeEntity(uint256 indexed certificationId, uint256 indexed entityId);

    /// Emitted when user subscribe to a certification.
    event SubscribeCertification(uint256 indexed memberID, uint256 indexed certificationID);

    /// Emitted when user unsubscribe to a certification.
    event UnsubscribeCertification(uint256 indexed memberID, uint256 indexed certificationID);

    /// Emitted when certifiers deletes their certificate.
    event DeleteCertification(uint256[] indexed certificationID, uint256[] deleted, address indexed CertificateCreator);

    event MembershipContractUpdated(address membershipContractAddress);

    event CertifierContractUpdated(address certifierContractAddress);

    event EntityContractUpdated(address entityContractAddress);

    event EditCertification(uint256 indexed id, string title, string description, string metadata);

    enum EntityType {product, company, campaign}

    /**
     * Structure of static certification.
     * @param certificationId Id of the certification.
     * @param certifier       Certifier who created that certification.
     * @param title           Title of the certification.
     * @param description     Description of the certification.
     * @param metadataLink    Metadata Link of the certification.
     * @param entityType      Entity type (Company/Product/Campaign).
     * @param score           Mapping from entity Id => certification values.
     */
    struct StaticCertification {
        uint256     certificationId;
        address     certifier;
        string      title;
        string      description;
        string      metadataLink;
        EntityType  entityType;
        mapping(uint256 => uint256) score;           //  entityid OR campignID     =>   certification_value
    }

    /**
     * Structure of dynamic certification.
     * @param certificationId Id of the certification.
     * @param certifier       Certifier who created that certification.
     * @param title           Title of the certification.
     * @param description     Description of the certification.
     * @param entityType      Entity type (Company/Product/Campaign).
     * @param metadataLink    Metadata Link of the certification.
     * @param apiLink         API Link of the Entity.
     */
    struct DynamicCertification {
        uint256    certificationId;
        address    certifier;
        string     title;
        string     description;
        string     metadataLink;
        string     apiLink;     // dynamic
        EntityType entityType;
    }

    /**
     * Return type of certification.
     * @param certificationId Id of the certification.
     * @param certifier       Certifier who created that certification.
     * @param title           Title of the certification.
     * @param description     Description of the certification.
     * @param metadataLink    Metadata Link of the certification.
     * @param entityType      Entity type (Company/Product/Campaign).
     */
    struct ReturnStaticCertification {
        uint256    certificationId;
        address    certifier;
        string     title;
        string     description;
        string     metadataLink;
        EntityType entityType;
    }

    /// @dev mapping from certification Id => static Certificate.
    mapping(uint256 => StaticCertification) private staticCertifications;

    /// @dev maping from certification Id => dynamic certification.
    mapping(uint256 => DynamicCertification) private dynamicCertifications;

    /// @dev mapping from user address => certifications subscribed by the user.
    mapping(address => uint256[]) private memberSubscriptions;

    /// @dev Keeping record of index of every element of memberSubscriptions, helps in deletion.
    mapping(address => mapping(uint256 => uint256)) private idIndexMemberSubscription;

    /// @dev mapping from certification Id => user address subscribed to that certification.
    mapping(uint256 => address[]) private subscriber;

    /// @dev Keeping record of index of every element of subscriber, helps in deletion.
    mapping(uint256 => mapping(address => uint256)) private idIndexSubscriber;

    /// @dev mapping from Certification  => All certified entities or campaigns' IDs.
    mapping(uint256 => uint256[]) private staticCertifiedEntities;

    /// @dev Keeping record of index of every element of staticCertifiedEntities, helps in deletion.
    mapping(uint256 => mapping(uint256 => uint256)) private idIndexStaticCertifiedEntities;

    /// @dev mapping from EntityID  => Certifictaion IDs.
    mapping(uint256 => uint256[]) private staticEntityCertifications;

    /// @dev Keeping record of index of every element of staticEntityCertifications, helps in deletion.
    mapping(uint256 => mapping(uint256 => uint256)) private idIndexStaticEntityCertifications;

    /// @dev mapping from certifier address => CertificationsId created by that certifier.
    mapping(address => uint256[]) private certifierCertifications;

    /// @dev keeping record of every certification created by a certifier.
    mapping(uint256 => uint256) private idIndexCertifierCertifications;

    /// @dev mapping from certification Id => entities that applied for that certification.
    mapping(uint256 => uint256[]) private appliedForCertifications;

    /// @dev keeping record of entities applied for certifications by the seeker.
    mapping(uint256 => mapping(uint256 => uint256)) private idIndexAppliedForCertifications;

    /// @dev array for all Certifications' IDs.
    uint256[] private allCertifications;

    /// @dev Keeping record of index of every element of allCertifications, helps in deletion.
    mapping(uint256 => uint256) private idIndexAllCertifications;

    modifier onlyCertifier() {
        require(arkiusCertifierToken.certifierIdOf(_msgSender()) != INVALID, 'Caller is not a Certifier');
        _;
    }

    modifier onlyMember() {
        require(arkiusMembershipToken.memberIdOf(_msgSender()) != INVALID, 'Caller is not a Member');
        _;
    }

    modifier staticCertifier(uint256 id) {
        require (staticCertifications[id].certifier == _msgSender(), "Caller is not the certificate creator.");
        _;
    }

    modifier dynamicCertifier(uint256 id) {
        require (dynamicCertifications[id].certifier == _msgSender(), "Caller is not the certificate creator.");
        _;
    }

    /**
     * @dev initialize the addresses of AttentionSeekerNFT, MembershipNFT, CertifierNFT & Entity contract.
     *
     * @param memberContract     Address of the MembershipNFT contract.
     * @param certifierContract  Address of the CertifierrNFT contract.
     * @param entityContract     Address of the Entity Contract.
     * @param multisigAddress    Address of the Owner of the SmartContracts.
     */
    constructor(IArkiusMembershipToken memberContract,
                IArkiusCertifierToken  certifierContract,
                IEntity                entityContract,
                address                multisigAddress) Ownable(multisigAddress) {

        require(address(memberContract)     != address(0), "Invalid Member Address");
        require(address(certifierContract)  != address(0), "Invalid Certifier Address");
        require(address(entityContract)     != address(0), "Invalid Entity Address");
        require(address(memberContract)     != address(0), "Invalid Seeker Address");
        require(multisigAddress             != address(0), "Invalid Multisig Address");

        arkiusMembershipToken = memberContract;
        arkiusCertifierToken  = certifierContract;
        entity                = entityContract;
        TIMESTAMP             = block.timestamp;
    }

    /**
     * this function is for certifier only, to create static certificates.
     * @param timestamp   Current time in second/millisecond.
     * @param types       Entity type (Company/Product/Campaign).
     * @param metadata    Metadata Link of the certification.
     * @param title       Title of the certification.
     * @param description Description of the certification.
     *
     * @return certifiaction ID.
     */
    function createStaticCertification(uint256       timestamp,
                                       EntityType    types,
                                       string calldata metadata,
                                       string calldata title,
                                       string calldata description) onlyCertifier external returns(uint256) {

        require(TIMESTAMP <= timestamp && timestamp <= block.timestamp, "Invalid timestamp");

        uint256 id = hash(_msgSender(), metadata, timestamp);

        require(id != 0 && idIndexAllCertifications[id] == 0, "Invalid Id");
        require(staticCertifications[id].certificationId != id, "ID already exist.");
        require(bytes(title      ).length != 0, "No title provided.");
        require(bytes(description).length != 0, "No description provided.");
        require(bytes(metadata   ).length != 0, "No metadata provided.");

        staticCertifications[id].certificationId = id;
        staticCertifications[id].certifier       = _msgSender();
        staticCertifications[id].title           = title;
        staticCertifications[id].description     = description;
        staticCertifications[id].entityType      = types;
        staticCertifications[id].metadataLink    = metadata;

        certifierCertifications[_msgSender()].push(id);
        idIndexCertifierCertifications[id] = certifierCertifications[_msgSender()].length;

        allCertifications.push(id);
        idIndexAllCertifications[id] = allCertifications.length;

        emit CreateStaticCertification(id, title, _msgSender());

        return id;
    }

    function editCertification(uint256 id,
                               string memory title,
                               string memory description,
                               string memory metadata) onlyCertifier external {

        require(certificationExists(id) == true, "Invalid Id");

        if (staticCertifications[id].certifier == _msgSender()) {
            if (bytes(title      ).length != 0)   staticCertifications[id].title        = title;
            if (bytes(description).length != 0)   staticCertifications[id].description  = description;
            if (bytes(metadata   ).length != 0)   staticCertifications[id].metadataLink = metadata;
        }
        else if (dynamicCertifications[id].certifier == _msgSender()) {
            if (bytes(title      ).length != 0)   dynamicCertifications[id].title        = title;
            if (bytes(description).length != 0)   dynamicCertifications[id].description  = description;
            if (bytes(metadata   ).length != 0)   dynamicCertifications[id].metadataLink = metadata;
        }
        else {
            revert("You are not the certifier of the certification");
        }

        emit EditCertification(id, title, description, metadata);
    }

    /**
     * this function is for certifier only, to create dynamic certificates.
     * @param timestamp   Current time in second/millisecond.
     * @param types       Entity type (Company/Product/Campaign).
     * @param metadata    Metadata Link of the certification.
     * @param title       Title of the certification.
     * @param description Description of the certification.
     * @param apiLink     Link for the dynamic certificate.
     *
     * @return certifiaction ID.
     */
    function createDynamicCertification(uint256       timestamp,
                                        EntityType    types,
                                        string memory metadata,
                                        string memory title,
                                        string memory description,
                                        string memory apiLink) external onlyCertifier returns(uint256) {

        require(TIMESTAMP <= timestamp && timestamp <= block.timestamp, "Invalid timestamp");            

        uint256 id = hash(_msgSender(), metadata, timestamp);

        require(id != 0 && idIndexAllCertifications[id] == 0, "Invalid Id");
        require(dynamicCertifications[id].certificationId != id, "ID already exist.");
        require(bytes(title      ).length != 0, "No title provided.");
        require(bytes(apiLink    ).length != 0, "No API link is provided.");
        require(bytes(description).length != 0, "No description provided.");
        require(bytes(metadata   ).length != 0, "No metadata provided.");

        DynamicCertification memory certification = DynamicCertification(
            id, _msgSender(), title, description, metadata, apiLink, types);

        dynamicCertifications[id] = certification;

        certifierCertifications[_msgSender()].push(id);
        idIndexCertifierCertifications[id] = certifierCertifications[_msgSender()].length;

        allCertifications.push(id);
        idIndexAllCertifications[id] = allCertifications.length;

        emit CreateDynamicCertification(id, apiLink);

        return id;
    }
    
    /** Seeker apply for the certification of the Entities.
     *
     * @param certificationID  ID of the certification
     * @param entityID         ID for the Entity.
     */
    function applyCertification(uint256 certificationID, uint256 entityID) public {
        require(certificationExists(certificationID) == true, "Invalid certificationID");
        require(entity.entityExist(entityID) == true, "Invalid entityID");
        require(staticCertifications[certificationID].score[entityID] == 0, "Already Certified");
        require(idIndexAppliedForCertifications[certificationID][entityID] == 0, "Already Applied");

        IEntity.ReturnEntity memory returnedEntity = entity.getEntity(entityID);

        require(returnedEntity.creator == _msgSender(), "Not Authorised");

        appliedForCertifications[certificationID].push(entityID);
        idIndexAppliedForCertifications[certificationID][entityID] = appliedForCertifications[certificationID].length;

        emit ApplyCertification(certificationID, entityID);
    }

    /**
     * This function is used to certify Static Entity.
     * It can be called by the owner of this certification only.
     *
     * @param certificationId Id of the certification.
     * @param entityIds       Id of the entities.
     * @param scores          Value that is given to the entities.
     */
    function updateStaticEntity(uint256          certificationId,
                                uint256[] memory entityIds,
                                uint256[] memory scores
                                ) external onlyCertifier() staticCertifier(certificationId) returns(bool) {

        require(staticCertifications[certificationId].certifier != address(0), "Invalid Id");
        require(entityIds.length == scores.length, "Length Mismatch");


        for (uint256 idx = 0; idx<entityIds.length; idx++) {

            uint256 typeEntity = uint(entity.getEntity(entityIds[idx]).entityType);
            uint256 typeCerti  = uint(staticCertifications[certificationId].entityType);
            uint256 applied    = idIndexAppliedForCertifications[certificationId][entityIds[idx]];

            if (entity.entityExist(entityIds[idx]) == true && typeCerti == typeEntity) {

                if (staticCertifications[certificationId].score[entityIds[idx]] == 0 && applied != 0) {

                    staticCertifications[certificationId].score[entityIds[idx]] = scores[idx];

                    staticCertifiedEntities[certificationId].push(entityIds[idx]);
                    idIndexStaticCertifiedEntities[certificationId][entityIds[idx]] = staticCertifiedEntities[certificationId].length;

                    staticEntityCertifications[entityIds[idx]].push(certificationId);
                    idIndexStaticEntityCertifications[entityIds[idx]][certificationId] = staticEntityCertifications[entityIds[idx]].length;

                    uint256 len  = idIndexAppliedForCertifications[certificationId][entityIds[idx]];
                    uint256 last = appliedForCertifications[certificationId][appliedForCertifications[certificationId].length - 1];

                    appliedForCertifications[certificationId][len - 1] = last;
                    idIndexAppliedForCertifications[certificationId][last] = len;
                    idIndexAppliedForCertifications[certificationId][entityIds[idx]] = 0;
                    appliedForCertifications[certificationId].pop();

                    emit CertifyStaticEntity(certificationId, entityIds[idx], scores[idx]);
                }
                else if (staticCertifications[certificationId].score[entityIds[idx]] != 0) {
                    staticCertifications[certificationId].score[entityIds[idx]] = scores[idx];
                    emit CertifyStaticEntity(certificationId, entityIds[idx], scores[idx]);
                }
            }
        }


        return true;
    }

    /**
     * updates the API Link of dynamic certificate with id = `certificationID`.
     *
     * @param certificationID Id of the certification.
     * @param apiLink         API Link that is to be updated.
     */
    function updateDynamicEntity(uint256 certificationID,
                                 string memory apiLink
                                ) external onlyCertifier() dynamicCertifier(certificationID) returns(bool) {

        dynamicCertifications[certificationID].apiLink = apiLink;

        emit UpdateDynamicEntity(certificationID, apiLink);

        return true;
    }

    /**
     * This function help the user to subscribe the certification.
     *
     * If the `certificationId` exists, then caller can subscribe that certification.
     *
     * @param certificationID Id of the certificate.
     */
    function subscribeCertification(uint256[] calldata certificationID) external onlyMember {

        for (uint256 idx = 0; idx < certificationID.length; idx++) {
            _subscribeCertification(certificationID[idx], _msgSender());
        }
    }

    /// Internal function for subscribing a certificate
    function _subscribeCertification(uint256 certificationID, address subscriberAddress) internal {

        bool exists;
        uint256 subscribed;

        exists     = certificationExists(certificationID);
        subscribed = idIndexMemberSubscription[subscriberAddress][certificationID];

        if (exists && subscribed == 0) {

            memberSubscriptions[subscriberAddress].push(certificationID);
            idIndexMemberSubscription[subscriberAddress][certificationID] = memberSubscriptions[subscriberAddress].length;

            subscriber[certificationID].push(subscriberAddress);
            idIndexSubscriber[certificationID][subscriberAddress] = subscriber[certificationID].length;

            emit SubscribeCertification(arkiusMembershipToken.memberIdOf(_msgSender()), certificationID);

        }

    }

    /**
     * This function helps the user to unsubscribe the certification.
     *
     * If the `certificationId` exist, then the caller can unsubscribe that certification.
     *
     * @param certificationId Id of the certificate.
     */
    function unsubscribeCertification(uint256[] calldata certificationId) external onlyMember {

        for (uint256 idx = 0; idx < certificationId.length; idx++) {

            _unsubscribeCertification(certificationId[idx], _msgSender());
        }

    }

    /// Internal function for unsubscribing a certificate
    function _unsubscribeCertification(uint256 certificationId, address subscriberAddress) internal {

        bool exists         = certificationExists(certificationId);
        uint256 subscribed  = idIndexSubscriber[certificationId][subscriberAddress];

        if (exists && subscribed > 0) {

            address subscriberLastElement = subscriber[certificationId][subscriber[certificationId].length - 1];
            uint idIndex                  = idIndexSubscriber[certificationId][subscriberAddress];

            idIndexSubscriber[certificationId][subscriberLastElement] = idIndex;
            subscriber[certificationId][idIndex - 1]                  = subscriberLastElement;
            idIndexSubscriber[certificationId][subscriberAddress]     = 0;
            subscriber[certificationId].pop();

            uint memberSubscriptionsLastElement = memberSubscriptions[subscriberAddress][memberSubscriptions[subscriberAddress].length - 1];
            idIndex                             = idIndexMemberSubscription[subscriberAddress][certificationId];

            idIndexMemberSubscription[subscriberAddress][memberSubscriptionsLastElement] = idIndex;
            memberSubscriptions[subscriberAddress][idIndex - 1]                          = memberSubscriptionsLastElement;
            idIndexMemberSubscription[subscriberAddress][certificationId]                = 0;
            memberSubscriptions[subscriberAddress].pop();

            emit UnsubscribeCertification(arkiusMembershipToken.memberIdOf(_msgSender()), certificationId);

        }
    }

    function deleteCertification(uint256[] calldata Id) external onlyCertifier() {

        bool exists;
        bool certificationOwner;

        uint256[] memory deleted = new  uint256[](Id.length);

        for (uint256 idx = 0; idx < Id.length; idx++) {

            certificationOwner = false;

            exists = certificationExists(Id[idx]);
            if (staticCertifications[Id[idx]].certifier  == _msgSender() ||
                dynamicCertifications[Id[idx]].certifier == _msgSender()) {
                certificationOwner = true;
            }

            if (exists && certificationOwner) {

                address[] memory memberSubscriber = getSubscribers(Id[idx]);
                uint256[] memory entitySubscriber = certifiedEntities(Id[idx]);
                deleted[idx] = Id[idx];

                for (uint256 unsubscribe = 0; unsubscribe < memberSubscriber.length; unsubscribe++ ) {
                    _unsubscribeCertification(Id[idx], memberSubscriber[unsubscribe]);
                }

                for (uint256 unsubscribe = 0; unsubscribe < entitySubscriber.length; unsubscribe++ ) {
                    _unsubscribeEntity(Id[idx], entitySubscriber[unsubscribe]);
                }

                if (staticCertifications[Id[idx]].certifier == _msgSender()) {
                    delete staticCertifications[Id[idx]];
                    staticCertifications[Id[idx]].certificationId = Id[idx];
                }
                else {
                    delete dynamicCertifications[Id[idx]];
                    dynamicCertifications[Id[idx]].certificationId = Id[idx];
                }

                uint256 length = certifierCertifications[_msgSender()].length - 1;

                uint256 lastElement = certifierCertifications[_msgSender()][length];
                uint256 index       = idIndexCertifierCertifications[Id[idx]];

                idIndexCertifierCertifications[lastElement]    = index;
                certifierCertifications[_msgSender()][index-1] = lastElement;
                idIndexCertifierCertifications[Id[idx]]        = 0;
                certifierCertifications[_msgSender()].pop();

                lastElement = allCertifications[allCertifications.length - 1];
                index       = idIndexAllCertifications[Id[idx]];

                idIndexAllCertifications[lastElement] = index;
                allCertifications[index-1]            = lastElement;
                idIndexAllCertifications[Id[idx]]     = 0;
                allCertifications.pop();

            }
        }

        emit DeleteCertification(Id, deleted, _msgSender());
    }

    function unsubscribeEntity(uint256 entityId) external {

        require(_msgSender() == address(entity), "Not Authorised");

        uint256[] memory subscribed = entityCertifications(entityId);

        for (uint idx = 0; idx < subscribed.length; idx++) {

            staticCertifications[subscribed[idx]].score[entityId] = 0;
            _unsubscribeEntity(subscribed[idx], entityId);
        }

    }

    function _unsubscribeEntity(uint256 certificationId, uint256 entityId) internal {

        bool exists         = entity.entityExist(entityId);
        uint256 subscribed  = idIndexStaticCertifiedEntities[certificationId][entityId];

        if (exists && subscribed > 0) {

            uint256 subscriberLastElement = staticCertifiedEntities[certificationId][staticCertifiedEntities[certificationId].length - 1];
            uint256 idIndex               = idIndexStaticCertifiedEntities[certificationId][entityId];

            idIndexStaticCertifiedEntities[certificationId][subscriberLastElement] = idIndex;
            staticCertifiedEntities[certificationId][idIndex - 1]                  = subscriberLastElement;
            idIndexStaticCertifiedEntities[certificationId][entityId]              = 0;
            staticCertifiedEntities[certificationId].pop();

            subscriberLastElement = staticEntityCertifications[entityId][staticEntityCertifications[entityId].length - 1];
            idIndex               = idIndexStaticEntityCertifications[entityId][certificationId];

            idIndexStaticEntityCertifications[entityId][subscriberLastElement] = idIndex;
            staticEntityCertifications[entityId][idIndex - 1]               = subscriberLastElement;
            idIndexStaticEntityCertifications[entityId][certificationId]       = 0;
            staticEntityCertifications[entityId].pop();

            emit UnsubscribeEntity(certificationId, entityId);
        }
    }

    function updateMembershipContract(IArkiusMembershipToken membershipContractAddress) external onlyOwner {
        require(address(membershipContractAddress) != address(0), "Invalid Address");
        arkiusMembershipToken = membershipContractAddress;
        emit MembershipContractUpdated(address(membershipContractAddress));
    }

    function updateCertifierContract(IArkiusCertifierToken certifierContractAddress) external onlyOwner {
        require(address(certifierContractAddress) != address(0), "Invalid Address");
        arkiusCertifierToken = certifierContractAddress;
        emit CertifierContractUpdated(address(certifierContractAddress));
    }

    function updateEntityContract(IEntity entityContractAddress) external onlyOwner {
        require(address(entityContractAddress) != address(0), "Invalid Address");
        entity = entityContractAddress;
        emit EntityContractUpdated(address(entityContractAddress));
    }

    function membershipAddress() external view returns(IArkiusMembershipToken) {
        return arkiusMembershipToken;
    }

    function certifierAddress() external view returns(IArkiusCertifierToken) {
        return arkiusCertifierToken;
    }

    function entityAddress() external view returns(IEntity) {
        return entity;
    }

    function hash(address add, string memory data, uint256 timestamp) internal pure returns(uint256 hashId) {
        hashId = uint(keccak256(abi.encodePacked(add, data, timestamp)));
        return hashId;
    }

    /**
     * return true if there is a certificate with id = `id`.
     *
     * @param id Id of the certificate.
     */
    function certificationExists(uint256 id) public view returns(bool) {
        return (staticCertifications[id].certifier != address(0) ||
                dynamicCertifications[id].certifier != address(0)
                );
    }

    /**
     * returns the certificate value of the entity having id = `entityID`.
     * for the certification with Id = `certificationID`.
     *
     * @param certificationID Id of the certificate.
     * @param entityID        Id of the entity.
     */
    function getStaticCertificate(uint256 certificationID, uint256 entityID) external view returns(uint256) {
        return staticCertifications[certificationID].score[entityID];
    }

    /**
     * returns the api Link of the dynamic certificate having id = `certificationID`.
     *
     * @param certificationID Id of the certificate.
     */
    function getDynamicCertificateLink(uint256 certificationID) external view returns(string memory) {
        return dynamicCertifications[certificationID].apiLink;
    }

    /**
     * returns the details(structure) of the static certification.
     *
     * @param certificationID Id of the certificate.
     */
    function getStaticCertification(uint256 certificationID) external view returns(ReturnStaticCertification memory) {
        return ReturnStaticCertification(
            staticCertifications[certificationID].certificationId,
            staticCertifications[certificationID].certifier,
            staticCertifications[certificationID].title,
            staticCertifications[certificationID].description,
            staticCertifications[certificationID].metadataLink,
            staticCertifications[certificationID].entityType
        );
    }

    /**
     * returns the details(structure) of the Dynamic certification.
     *
     * @param certificationID Id of the certificate.
     */
    function getDynamicCertification(uint256 certificationID) external view returns(DynamicCertification memory) {
        return dynamicCertifications[certificationID];
    }

    /**
     * @dev returns the certification subscribed by the `memberAddress`.
     */
    function getMemberSubscriptions(address memberAddress) external view returns (uint256[] memory) {
        return memberSubscriptions[memberAddress];
    }

    /**
     * @dev returns the subscriber of the `certificationID`.
     */
    function getSubscribers(uint256 certificationID) public view returns(address[] memory) {
        return subscriber[certificationID];
    }

    /**
    * @dev Returns all IDs of Entities in existence.
    */
    function getAllCertifications() public view returns(uint256[] memory) {
        return allCertifications;
    }

    function entityCertifications(uint256 entityId) public view returns(uint256[] memory) {
        return staticEntityCertifications[entityId];
    }

    function certifiedEntities(uint256 certificationId) public view returns(uint256[] memory) {
        return staticCertifiedEntities[certificationId];
    }

    function certifications(address certifierAdd) external view returns(uint256[] memory) {
        return certifierCertifications[certifierAdd];
    }

    function appliedCertifications(uint256 certificationID) external view returns(uint256[] memory) {
        return  appliedForCertifications[certificationID];
    }
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

interface IArkiusMembershipToken {
    function memberIdOf(address owner) external view returns (uint256);
}

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

interface IArkiusCertifierToken {
    function certifierIdOf(address owner) external view returns (uint256);

    function burn(address owner, uint256 value) external;
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

interface IEntity {
    enum IEntityType {product, company, campaign}
    
    struct ReturnEntity{
            uint256     id;
            address     creator;
            IEntityType entityType;
            string      title;
            string      description;
            string      metadata;
    }

    function createEntity(uint256       id,
                          string memory title,
                          IEntityType   types,
                          string memory description,
                          string memory metadata,
                          address attentionSeekerAddress) external;

    function getEntity(uint256 id) external view returns(ReturnEntity memory);

    function entityExist(uint256 id) external view returns(bool);

    function deleteEntity(uint256 id, address attentionSeekerAddress) external;

    function editEntity(uint256       id,
                        string memory title,
                        string memory description,
                        string memory metadata,
                        address attentionSeekerAddress) external;
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