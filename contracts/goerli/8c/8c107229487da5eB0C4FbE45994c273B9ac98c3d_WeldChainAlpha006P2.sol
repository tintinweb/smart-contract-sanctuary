// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { WeldChainAlpha006Structs as structs } from "./WeldChainAlpha006Structs.sol";
import { WeldChainAlpha006SetUps as WeldChainSetUps } from "./WeldChainAlpha006SetUps.sol";
import { WeldChainAlpha006WeldRegistration as WeldChainWeldRegistration } from "./WeldChainAlpha006WeldRegistration.sol";
import { WeldChainAlpha006Welding as WeldChainWelding } from "./WeldChainAlpha006Welding.sol";
import { WeldChainAlpha006WeldLog as WeldChainWeldLog } from "./WeldChainAlpha006WeldLog.sol";

/**
 * @title WeldChain release alpha 006 part 2
 * @author Benjamin Roedell (Flexsible LLC)
 * @notice Publishes PII (Personally Identifiable Information) on the blockchain
 * @dev Publishes PII (Personally Identifiable Information) on the blockchain. Structs with the word private need to be removed before go-live
 * @custom:experimental This is an experimental contract.
 */
contract WeldChainAlpha006P2 {

    mapping(address => bool) private contractManagers;

    WeldChainSetUps weldChainSetUps;
    WeldChainWeldRegistration weldChainWeldRegistration;
    WeldChainWelding weldChainWelding;
    WeldChainWeldLog weldChainWeldLog;

    constructor() {
        contractManagers[msg.sender] = true;
    }

    /**
     * Initialize contract
     * @dev DO NOT CALL this function, it is only use during initial deployment of the contract
     * @param weldChainWeldRegistrationAddress address to the WeldChainWeldRegistration contract
     * @param weldChainWeldingAddress address to the WeldChainWelding contract
     */
    function initialize(
        address weldChainSetUpsAddress,
        address weldChainWeldRegistrationAddress,
        address weldChainWeldingAddress,
        address weldChainWeldLogAddress
        ) public {
        require(contractManagers[msg.sender], "Unauthorized, sender must be contract manager");
        weldChainSetUps = WeldChainSetUps(weldChainSetUpsAddress);
        weldChainWeldRegistration = WeldChainWeldRegistration(weldChainWeldRegistrationAddress);
        weldChainWelding = WeldChainWelding(weldChainWeldingAddress);
        weldChainWeldLog = WeldChainWeldLog(weldChainWeldLogAddress);
    }

    /**
     * Get weld log
     * @dev Must be paid for first
     * @param siteId Unique id of the site
     * @param weldId Weld id
     * @return weldLogRecords Results of request
     */
    function getWeldLog(
        string memory siteId,
        string memory weldId
    ) public view returns(structs.WeldLogRecordDataView[] memory weldLogRecords) {
        return weldChainWeldLog.getWeldLog(msg.sender, siteId, weldId);
    }

    /**
     * Pay all weld log fees
     * @param siteId Unique id of the site
     */
    function payAllWeldLogFees(
        string memory siteId
    ) public {
        weldChainWelding.payAllWeldLogFees(msg.sender, siteId);
    }

    /**
     * Pay weld log fee
     * @dev Call this with same parameters as get weld log
     * @param siteId Unique id of the site
     * @param weldId Weld id
     */
    function payWeldLogFee(
        string memory siteId,
        string memory weldId
    ) public {
        weldChainWelding.payWeldLogFee(msg.sender, siteId, weldId);
    }

    /**
     * Get all weld log fees
     * @param siteId Unique id of the site
     * @return tokens Decimal 18 token value
     */
    function getAllWeldLogFees(
        string memory siteId
    ) public view returns(uint tokens) {
        return weldChainWelding.getAllWeldLogFees(siteId);
    }

    /**
     * Get weld log fee
     * @dev Call this with same parameters as get weld log
     * @param siteId Unique id of the site
     * @param weldId Weld id
     * @return tokens Decimal 18 token value
     */
    function getWeldLogFee(
        string memory siteId,
        string memory weldId
    ) public view returns(uint tokens) {
        return weldChainWelding.getWeldLogFee(siteId, weldId);
    }

    /**
     * Inspect weld
     * @param inspectWeldInput Inspect weld information
     */
    function inspectWeld(
        structs.InspectWeldInput memory inspectWeldInput
    ) public {
        weldChainWelding.inspectWeld(msg.sender, inspectWeldInput);
    }

    /**
     * Record weld
     * @dev Used by welder to record a weld against a previously registered weld
     * @param recordWeldInput Record weld information
     */
     function recordWeld(
         structs.RecordWeldInput memory recordWeldInput
     ) public {
        weldChainWelding.recordWeld(msg.sender, recordWeldInput);
     }

    /**
     * Get registered weld files
     * @dev Returns data needed to read files from an existing weld
     * @param siteId Unique id of the site
     * @param weldId Site specific weld id
     * @param page One based page numbering
     * @param itemsPerPage Number of items to include in return
     * @return pagedResults Results with list of site specific weld files and total count
     */
    function getRegisteredWeldFiles(
        string memory siteId,
        string memory weldId,
        uint page,
        uint itemsPerPage
    ) public view returns(structs.PagedFileResults memory pagedResults) {
        return weldChainWeldRegistration.getRegisteredWeldFiles(msg.sender, siteId, weldId, page, itemsPerPage);
    }

    /**
     * Get registered weld data
     * @dev Returns data needed to properly edit an existing weld using the registerWeld function
     * @param siteId Unique id of the site
     * @param weldId Site specific weld id
     * @return registeredWeldData registered weld data needed to edit existing welds using the registerWeld function
     */
    function getRegisteredWeld(
        string memory siteId,
        string memory weldId
    ) public view returns(structs.RegisteredWeldData memory registeredWeldData) {
        return weldChainWeldRegistration.getRegisteredWeld(msg.sender, siteId, weldId);
    }

    /**
     * Get site specific Weld IDs
     * @dev Returns site specific Weld IDs to be used to retrieve individual weld information
     * @param siteId Unique id of the site
     * @param page One based page numbering
     * @param itemsPerPage Number of items to include in return
     * @return pagedResults Results with list of site specific WPS IDs and total count
     */
    function getWeldIds(
        string memory siteId,
        uint page,
        uint itemsPerPage
    ) public view returns(structs.PagedStringResults memory pagedResults) {
        return weldChainWeldRegistration.getWeldIds(siteId, page, itemsPerPage);
    }

    /**
     * Register weld
     * @dev Used by engineer to register a new weld using existing WPS
     * @param siteId Unique id of the site
     * @param registerWeldInput New weld information
     */
     function registerWeld(
         string memory siteId,
         structs.RegisterWeldInput memory registerWeldInput
     ) public {
        weldChainWeldRegistration.registerWeld(msg.sender, siteId, registerWeldInput);
     }

    /**
     * Approve WPS
     * @param siteId Unique id of the site
     * @param wpsId WPS ID
     * @param approved Whether or not a WPS is approved
     */
    function setWeldProcedureSpecificationApproval(
        string memory siteId,
        string memory wpsId,
        bool approved
    ) public {
        weldChainSetUps.setWeldProcedureSpecificationApproval(msg.sender, siteId, wpsId, approved);
    }

    /**
     * Get WPS set up data
     * @param siteId Unique id of the site
     * @param wpsId WPS ID
     * @return weldProcedureSpecificationSetUpData Data related to WPS set up
     */
    function getWeldProcedureSpecificationSetUp(
        string memory siteId,
        string memory wpsId
    ) public view returns (structs.GetWeldProcedureSpecificationSetUpResponse memory weldProcedureSpecificationSetUpData) {
        return weldChainSetUps.getWeldProcedureSpecificationSetUp(msg.sender, siteId, wpsId);
    }
}