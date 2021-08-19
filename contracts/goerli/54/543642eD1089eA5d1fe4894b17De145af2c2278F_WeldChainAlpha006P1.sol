// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { WeldChainAlpha006Structs as structs } from "./WeldChainAlpha006Structs.sol";
import { WeldChainAlpha006Registrations as WeldChainRegistrations } from "./WeldChainAlpha006Registrations.sol";
import { WeldChainAlpha006WpsRegistrations as WeldChainWpsRegistrations } from "./WeldChainAlpha006WpsRegistrations.sol";
import { WeldChainAlpha006SetUps as WeldChainSetUps } from "./WeldChainAlpha006SetUps.sol";

/**
 * @title WeldChain release alpha 006 part 1
 * @author Benjamin Roedell (Flexsible LLC)
 * @notice Publishes PII (Personally Identifiable Information) on the blockchain
 * @dev Publishes PII (Personally Identifiable Information) on the blockchain. Structs with the word private need to be removed before go-live
 * @custom:experimental This is an experimental contract.
 */
contract WeldChainAlpha006P1 {

    mapping(address => bool) private contractManagers;

    WeldChainRegistrations weldChainRegistrations;
    WeldChainWpsRegistrations weldChainWpsRegistrations;
    WeldChainSetUps weldChainSetUps;

    constructor() {
        contractManagers[msg.sender] = true;
    }

    /**
     * Initialize contract
     * @dev DO NOT CALL this function, it is only use during initial deployment of the contract
     * @param registrationsContractAddress address to the WeldChainRegistrations contract
     * @param wpsRegistrationsContractAddress address to the WeldChainWpsRegistrations contract
     * @param weldChainSetUpsAddress address to the WeldChainSetUps contract
     */
    function initialize(
        address registrationsContractAddress, 
        address wpsRegistrationsContractAddress, 
        address weldChainSetUpsAddress
        ) public {
        require(contractManagers[msg.sender], "Unauthorized, sender must be contract manager");
        weldChainRegistrations = WeldChainRegistrations(registrationsContractAddress);
        weldChainWpsRegistrations = WeldChainWpsRegistrations(wpsRegistrationsContractAddress);
        weldChainSetUps = WeldChainSetUps(weldChainSetUpsAddress);
    }

    /**
     * Get site specific WPS IDs
     * @dev Returns site specific WPS IDs to be used to retrieve individual WPS information
     * @param siteId Unique id of the site
     * @param page One based page numbering
     * @param itemsPerPage Number of items to include in return
     * @return pagedResults Results with list of site specific WPS IDs and total count
     */
    function getWeldProcedureSpecificationSiteIds(
        string memory siteId,
        uint page,
        uint itemsPerPage
    ) public view returns(structs.PagedStringApprovalResults memory pagedResults) {
        return weldChainSetUps.getWeldProcedureSpecificationSiteIds(msg.sender, siteId, page, itemsPerPage);
    }

    /**
     * WPS set up
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for engineer to set up WPS with a specific site
     * @param siteId Unique id of the site
     * @param wpsId Global WPS ID
     * @param files WPS set up files
     */
    function weldProcedureSpecificationSetUp(
        string memory siteId,
        string memory wpsId,
        structs.FileData[] memory files
    ) public {
        weldChainSetUps.weldProcedureSpecificationSetUp(msg.sender, siteId, wpsId, files);
    }

    /**
     * Get WPS
     * @dev Returns WPS
     * @param wpsId The ID of the WPS
     * @return wps The WPS information
     */
    function getWeldProcedureSpecification(
        string memory wpsId
    ) public view returns(structs.GetWeldProcedureSpecificationResponse memory wps) {
        return weldChainWpsRegistrations.getWeldProcedureSpecification(wpsId);
    }

    /**
     * Get WPS IDs
     * @dev Returns WPS IDs to be used to retrieve individual WPS information
     * @param page One based page numbering
     * @param itemsPerPage Number of items to include in return
     * @return pagedResults Results with list of IDs and total count
     */
    function getWeldProcedureSpecificationIds(
        uint page,
        uint itemsPerPage
    ) public view returns(structs.PagedStringResults memory pagedResults) {
        return weldChainWpsRegistrations.getWeldProcedureSpecificationIds(page, itemsPerPage);
    }

    /**
     * Weld Procedure Specification registration
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for weld procedure specification registration
     * @param wps WeldProcedureSpecification
     */
    function weldProcedureSpecificationRegistration(
        structs.WeldProcedureSpecificationDataInputPrivate memory wps
    ) public {
        weldChainWpsRegistrations.weldProcedureSpecificationRegistration(msg.sender, wps);
    }

    /**
     * Get welder for verification by inspectors. Welders can also request their own data through this function.
     * @dev Used for inspector to get welder information and for welders to view their own data.
     * @param welderAddress Address of welder for whom to get data
     * @return welderData Welder data
     */
    function getWelder(address welderAddress)
    public view 
    returns (structs.WelderDataPrivate memory welderData) {
        return weldChainRegistrations.getWelder(msg.sender, welderAddress, true);
    }

    /**
     * Welder registration
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for welder self registration
     * @param files Welder registration files
     */
    function welderRegistration(
        structs.FileData[] memory files
    ) public {
        weldChainRegistrations.welderRegistration(msg.sender, files);
    }

    /**
     * Set engineer certification information
     * @dev Used for inspectors to set engineer certification information
     * @param engineerCertifications certification data
     */
    function setEngineerCertifications(
        structs.EngineerCertificationData[] memory engineerCertifications
    ) public {
        weldChainRegistrations.setEngineerCertifications(msg.sender, engineerCertifications);
    }

    /**
     * Get engineer for verification by inspectors. Engineers can also request their own data through this function.
     * @dev Used for inspector to get engineer information and for engineers to view their own data.
     * @param engineerAddress Address of engineer for whom to get data
     * @return engineerData Engineer data
     */
    function getEngineer(address engineerAddress)
    public view 
    returns (structs.EngineerDataPrivate memory engineerData) {
        return weldChainRegistrations.getEngineer(msg.sender, engineerAddress, true);
    }

    /**
     * Engineer registration
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for engineer self registration
     * @param certificationNumbers Engineer certification numbers
     */
    function engineerRegistration(
        string[] memory certificationNumbers,
        structs.FileData[] memory files
    ) public {
        weldChainRegistrations.engineerRegistration(msg.sender, certificationNumbers, files);
    }

    /**
     * Admin Decrement balance
     * @dev Decreases balance
     * @param tokenOwner Address of token owner
     * @param decrementAmount Amount to remove from balance
     */
    function adminDecrementBalance(
        address tokenOwner,
        uint decrementAmount
    ) public {
        weldChainSetUps.decrementBalance(msg.sender, tokenOwner, decrementAmount, true);
    }

    /**
     * Admin Increment balance
     * @dev Increases balance
     * @param tokenOwner Address of token owner
     * @param incrementAmount Amount to add to balance
     */
    function adminIncrementBalance(
        address tokenOwner,
        uint incrementAmount
    ) public {
        weldChainSetUps.incrementBalance(msg.sender, tokenOwner, incrementAmount, true);
    }

    /**
     * Remove inspector certification checkers
     * @dev Used for updating list of address allowed to get/set inspector certifications
     * @param inspectorCertificationChecker Address of inspector certification checker
     */
    function removeInspectorCertificationCheckers(address inspectorCertificationChecker) public {
        weldChainRegistrations.removeInspectorCertificationCheckers(msg.sender, inspectorCertificationChecker);
    }

    /**
     * Add inspector certification checkers
     * @dev Used for updating list of address allowed to get/set inspector certifications
     * @param inspectorCertificationChecker Address of inspector certification checker
     */
    function addInspectorCertificationCheckers(address inspectorCertificationChecker) public {
        weldChainRegistrations.addInspectorCertificationCheckers(msg.sender, inspectorCertificationChecker);
    }

    /**
     * Set inspector certification information based on https://cloudweb2.aws.org/Certifications/Search/
     * @dev Used for inspector certification checkers to set inspector certification information
     * @param inspectorCertifications certification data
     */
    function setInspectorCertifications(
        structs.InspectorCertificationData[] memory inspectorCertifications
    ) public {
        weldChainRegistrations.setInspectorCertifications(msg.sender, inspectorCertifications);
    }

    /**
     * Get inspector for verifying against https://cloudweb2.aws.org/Certifications/Search/. Inspectors can also request their own data through this function.
     * @dev Used for inspector certification checkers to get inspector information and for inspectors to view their own data.
     * @param inspectorAddress Address of inspector for whom to get data
     * @return inspectorData Inspector data
     */
    function getInspector(address inspectorAddress)
    public view 
    returns (structs.InspectorDataPrivate memory inspectorData) {
        return weldChainRegistrations.getInspector(msg.sender, inspectorAddress, true);
    }

    /**
     * Inspector registration
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for inspector self registration
     * @param certificationNumbers Inspector certification numbers
     */
    function inspectorRegistration(
        string[] memory certificationNumbers,
        structs.FileData[] memory files
    ) public {
        weldChainRegistrations.inspectorRegistration(msg.sender, certificationNumbers, files);
    }

    /**
     * Get person for verifying against https://cloudweb2.aws.org/Certifications/Search/. Persons can also request their own data through this function.
     * @dev Used for inspector certification checkers to get inspector information and for persons to view their own data.
     * @param personAddress Address of inspector for whom to get data
     * @return personData Person data
     */
    function getPerson(address personAddress)
    public view 
    returns (structs.PersonDataPrivate memory personData) {
        return weldChainRegistrations.getPerson(msg.sender, personAddress);
    }

    /**
     * Person registration
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for person self registration
     * @param firstName Person first name
     * @param lastName Person last name
     * @param email Person email address
     */
    function personRegistration(
        string memory firstName,
        string memory lastName,
        string memory email
    ) public {
        weldChainRegistrations.personRegistration(msg.sender, firstName, lastName, email);
    }

    /**
     * Approve welder
     * @param siteId Unique id of the site
     * @param id Welder ID
     * @param approved Whether or not a welder is approved
     */
    function setWelderApproval(
        string memory siteId,
        string memory id,
        bool approved
    ) public {
        weldChainSetUps.setWelderApproval(msg.sender, siteId, id, approved);
    }

    /**
     * Get welder set up data
     * @param siteId Unique id of the site
     * @param id Welder ID
     * @return welderSetUpData Data related to welder set up
     */
    function getWelderSetUp(
        string memory siteId,
        string memory id
    ) public view returns (structs.GetWelderSetUpResponse memory welderSetUpData) {
        return weldChainSetUps.getWelderSetUp(msg.sender, siteId, id, true);
    }

    /**
     * Get site specific welder IDs
     * @dev Returns site specific welder IDs to be used to retrieve individual welder information
     * @param siteId Unique id of the site
     * @param page One based page numbering
     * @param itemsPerPage Number of items to include in return
     * @return pagedResults Results with list of site specific welder IDs and total count
     */
    function getWelderIds(
        string memory siteId,
        uint page,
        uint itemsPerPage
    ) public view returns(structs.PagedStringResults memory pagedResults) {
        return weldChainSetUps.getWelderIds(msg.sender, siteId, page, itemsPerPage);
    }

    /**
     * Welder set up
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for welder self set up with a specific site
     * @param siteId Unique id of the site
     * @param id Welder ID
     */
    function welderSetUp(
        string memory siteId,
        string memory id,
        structs.FileData[] memory files
    ) public {
        weldChainSetUps.welderSetUp(msg.sender, siteId, id, files);
    }

    /**
     * Engineer set up
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for engineer self set up with a specific site
     * @param siteId Unique id of the site
     * @param id Engineer ID
     */
    function engineerSetUp(
        string memory siteId,
        string memory id
    ) public {
        weldChainSetUps.engineerSetUp(msg.sender, siteId, id);
    }

    /**
     * Inspector set up
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for inspector self set up with a specific site
     * @param siteId Unique id of the site
     * @param id Inspector ID
     */
    function inspectorSetUp(
        string memory siteId,
        string memory id
    ) public {
        weldChainSetUps.inspectorSetUp(msg.sender, siteId, id);
    }

    /**
     * Retrieve balance of tokens owed to the specified address
     * @notice Retrieve balance of tokens owed
     * @dev Returns current number of tokens owed to the specified address
     * @param tokenOwner Address of token owner
     * @return Tokens owed
     */
    function balanceOf(address tokenOwner) public view returns (uint) {
        return weldChainSetUps.balanceOf(tokenOwner);
    }

    /**
     * Site set up
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Initial entry point to starting a new project a site
     * @param siteId Unique site Id, usually a UUID or GUID
     * @param siteData Site data
     */
    function siteSetUp (
        string memory siteId,
        structs.SiteDataPrivate memory siteData
    )
    public {
        weldChainSetUps.siteSetUp(msg.sender, siteId, siteData);
    }

    /**
     * Get all sites
     * @dev Only returns sites for which an inspector or engineer or welder has set themself up
     * @return siteData Array of minimal site data (intended for dropdowns)
     */
    function getAllSites()
    public view 
    returns (structs.SiteDisplayData[] memory siteData) {
        return weldChainSetUps.getAllSites(msg.sender);
    }

    /**
     * Get site
     * @dev Site creator can view site information
     * @param siteId Unique id of the site
     */
    function getSite(string memory siteId) 
    public view 
    returns (structs.SiteDataPrivate memory siteData) {
        return weldChainSetUps.getSite(msg.sender, siteId);
    }
}