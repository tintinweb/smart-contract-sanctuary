// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import '../Documents.sol';

contract DocumentFactory {
    function createDocumentContract(
        address _bconContract,
        string calldata _billOfQuantitiesDocument,
        string calldata _billingPlan,
        string calldata _bimModel,
        string calldata _paperContract
    ) public returns (address) {
        Documents newDocument = new Documents(
            _bconContract,
            _billOfQuantitiesDocument,
            _billingPlan,
            _bimModel,
            _paperContract
        );
        return address(newDocument);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import './interfaces/IBconContract.sol';

// BconContract represents a single legal contractual relation between "client" (Auftraggeber)
// and "contractor" (Auftragnehmer) with multiple BillingUnits (Abrechnungseinheiten) which consists of
// multiple BillingUnitItems (LV-Positionen)
contract Documents {
    // required legal documents as the base for this contract
    string public billOfQuantitiesDocument;
    string public billingPlan;
    string public bimModel;
    string public paperContract;

    address public bconContract;

    constructor(
        address _bconContract,
        string memory _billOfQuantitiesDocument,
        string memory _billingPlan,
        string memory _bimModel,
        string memory _paperContract
    ) {
        bconContract = _bconContract;
        billOfQuantitiesDocument = _billOfQuantitiesDocument;
        billingPlan = _billingPlan;
        bimModel = _bimModel;
        paperContract = _paperContract;
    }

    function getDocuments()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (billOfQuantitiesDocument, billingPlan, bimModel, paperContract);
    }

    function setBillOfQuantitiesDocument(string calldata _billOfQuantitiesDocument) public {
        billOfQuantitiesDocument = _billOfQuantitiesDocument;
        IBconContract(bconContract).throwDocumentsUpdated();
    }

    function setBillingPlan(string calldata _billingPlan) public {
        billingPlan = _billingPlan;
        IBconContract(bconContract).throwDocumentsUpdated();
    }

    function setBimModel(string calldata _bimModel) public {
        bimModel = _bimModel;
        IBconContract(bconContract).throwDocumentsUpdated();
    }

    function setPaperContract(string calldata _paperContract) public {
        paperContract = _paperContract;
        IBconContract(bconContract).throwDocumentsUpdated();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import '../libraries/SharedStates.sol';
import './IConfigurationHandler.sol';
import './IBillingUnits.sol';

abstract contract IBconContract {
    struct Contract {
        string id; // ID of the bconContract
        string projectId; // project ID for the bconContract
        address client; // Client of the bconContract, also called 'Auftraggeber'
        address contractor; // Contractor of the bconContract, also called 'Auftragnehmer'/'Generalunternehmer'
        // global configuration items for the whole contract
        IConfigurationHandler.ConfigurationItem[] configurationItems;
        SharedStates.BconContractState status; // status of bconContract
        IConfigurationHandler.ReportConfig reportConfig;
        IConfigurationHandler.ConfirmConfig confirmConfig;
    }

    struct ContractEventPayload {
        Contract bconContract;
        uint256 timestamp;
    }

    struct BillingUnitEventPayload {
        IBillingUnits.BillingUnit billingUnit;
        uint256 timestamp;
        address sender;
        SharedStates.MessageType reportType;
    }

    struct BillingUnitItemEventPayload {
        IBillingUnits.BillingUnitItem billingUnitItem;
        uint256 timestamp;
        string reportId;
        address sender;
        SharedStates.MessageType reportType;
        string[] fileIds;
    }

    // emit events
    function throwDocumentsUpdated() public virtual;

    function throwNewMessage(IBillingUnits.Message memory payload) public virtual;

    function throwBillingUnitCreated(IBillingUnits.BillingUnit memory billingUnit) public virtual;

    function throwBillingUnitPaymentTriggered(
        BillingUnitEventPayload memory payload,
        uint256 paymentTriggerTimestamp,
        uint256 paymentQuantity,
        uint256 securityDeposit
    ) public virtual;

    function throwBillingUnitPaymentClaimed(
        BillingUnitEventPayload memory payload,
        uint256 paymentClaimed
    ) public virtual;

    function throwBillingUnitSplit(BillingUnitEventPayload memory payload) public virtual;

    function throwBillingUnitItemCreated(IBillingUnits.BillingUnitItem memory billingUnitItem)
        public
        virtual;

    function throwBillingUnitItemReported(
        BillingUnitItemEventPayload memory payload,
        uint256 completionQuantity,
        uint256 completionPrice,
        uint256 completionRate
    ) public virtual;

    function throwBillingUnitItemCompleted(
        BillingUnitItemEventPayload memory payload,
        uint256 completionQuantity,
        uint256 completionPrice,
        uint256 completionRate
    ) public virtual;

    function throwBillingUnitItemConfirmed(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwBillingUnitItemConfirmedWithIssueReductionAmount(
        BillingUnitItemEventPayload memory payload,
        uint256 issueReductionAmount
    ) public virtual;

    function throwBillingUnitItemRejected(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwBillingUnitItemPaymentTriggered(
        BillingUnitItemEventPayload memory payload,
        uint256 paymentTriggerTimestamp,
        uint256 paymentQuantity,
        uint256 paymentPrice,
        uint256 securityDeposit
    ) public virtual;

    function throwRectificationWorkReported(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwRectificationWorkRejected(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    function throwRectificationWorkConfirmed(BillingUnitItemEventPayload memory payload)
        public
        virtual;

    // view functions
    function getId() public view virtual returns (string memory);

    function getProjectId() public view virtual returns (string memory);

    function getStatus() external view virtual returns (SharedStates.BconContractState);

    function getReportConfig()
        public
        view
        virtual
        returns (IConfigurationHandler.ReportConfig memory);

    function getClient() public view virtual returns (address);

    function getContractor() public view virtual returns (address);

    function getHandler() public view virtual returns (address[3] memory);

    function getConfigHandler() public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// this contract is needed to be able to interpret state between different contract types,
// which is needed for having dependant state machines
library SharedStates {
    // Level: BconAdmin > BconContract
    // TODO update
    enum BconContractState {
        Created,
        Signed,
        Finished
    }

    // Level: BconAdmin > BconContract > BillingUnits
    // == transient, i.e., derived state based on all contained BillingUnitItems
    // TODO update
    enum BillingUnitState {
        Open,
        PartiallyCompleted,
        Completed,
        Rectification,
        Paid
    }

    // Level: BconAdmin > BconContract > BillingUnits > BillingUnitItems
    // == actively changed based on progress reporting, progress confirmation and payment handling
    // TODO update
    enum BillingUnitItemState {
        Open,
        CompletionStarted,
        CompletionReady,
        CompletionClaimed,
        RectificationProcess,
        CompletionConfirmed,
        CompletionPartiallyConfirmed,
        FPApproved,
        FPClaimed,
        PPApproved,
        PPClaimed,
        PaymentConfirmed,
        DiscountConfirmed,
        Cancelled
    }

    enum MessageType {
        Notice,
        ReportDone,
        CompletionClaimed,
        ReportRejected,
        ConfirmationOkay,
        ConfirmationNotOkay,
        Issue,
        PaymentRequest,
        PaymentCancelled,
        PaymentConfirmation
    }

    enum Origin {
        Contract, // Ursprungsvertrag
        Issue, // Mängel
        Addition //Nachtrag
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

abstract contract IConfigurationHandler {
    struct ConfigurationItem {
        string configType;
        string configValue;
    }

    struct ReportConfig {
        // Stammdaten
        address bconContract;
        address billingUnits;
        address client;
        address contractor;
        // Konfiguration
        uint256 minStageOfCompletion;
        bool partialPayment;
        uint256 paymentInterval;
        uint256 securityDeposit;
        uint256 maxNumberOfRectifications;
        // Handler basierend auf Konfiguration
        address reportHandler;
        address confirmationHandler;
        address paymentHandler;
    }

    struct ConfirmConfig {
        uint256 minStageOfCompletion;
        bool partialPayment;
    }

    function extractConfig(ConfigurationItem[] memory _configItems)
        public
        virtual
        returns (ReportConfig memory reportConfig);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import '../libraries/SharedStates.sol';
import '../interfaces/IConfigurationHandler.sol';

abstract contract IBillingUnits {
    struct Message {
        string id;
        string billingUnitItemId;
        string relatedMessageId;
        SharedStates.MessageType msgType;
        address sender; // who is sending the message?
        uint256 timestamp;
        // reportDone / confirmationOkay / confirmationNotOkay / paymentRequest
        uint256 completionQuantity;
        uint256 completionPrice;
        uint256 completionRate;
        // issue
        uint256 issueReductionAmount; // "Mängeleinbehalt" which will be considered during payment handling
        string[] fileIds; // file references (e.g. for photos, notes, etc.)
    }

    struct BillingUnitItem {
        string id; // BillingUnitItemId
        string billingUnitId; // ID of parent BilligUnit
        // provided during initialization / update
        uint256 price;
        uint256 quantity;
        // provided during lifecycle (BillingUnitConsensusItem)
        uint256 quantityTotal; // quantityCompleted
        uint256 paymentTotal; // paid
        uint256 completionRateTotal; // completionRate
        uint256 completionRateClaimed; // claimed completionRate = reported but not yet confirmed
        uint256 outstandingReports;
        uint256 rectificationCounter;
        string[] fileIds;
        SharedStates.BillingUnitItemState state;

        // TODO
        // add addresses of customized billing unit handler (report, confirm, payment,...?)
        //ConfirmationHandler confirmationHandler;
    }

    struct BillingUnit {
        // provided by smart contract config
        string id; // BillingUnitId
        //IConfigurationHandler.ConfigurationItem[] configurationItems;
        IConfigurationHandler.ReportConfig config;
        BillingUnitItem[] items; // refers to all BillingUnitItems of this BillingUnit
        SharedStates.Origin origin;
        string issueUnitId;
        uint256 completionRateTotal; // completionRate = number of items * 100%
        uint256 paymentTotal; // paymentTotal = sum of (price * quantitiy) for each subitem
        // provided during lifecycle (BillingUnitConsensus)
        string[] fileIds;
        SharedStates.BillingUnitState state;
        uint256 completionRateClaimed; // completionRate provided during building phase
        uint256 paymentClaimed; // completionRate provided during building phase

        // action handler

        // TODO?
        // address reportHandler;
        // address confirmationHandler;
        // address rectificationHandler;
        // address paymentHandler;
    }

    function getMessageById(string memory messageId, string memory itemId)
        public
        view
        virtual
        returns (Message memory m);

    function getMessageByIndex(uint256 index, string memory itemId)
        public
        view
        virtual
        returns (Message memory m);

    function getBillingUnit(string memory _billingUnitId)
        public
        view
        virtual
        returns (BillingUnit memory);

    function getBillingUnitItem(string memory _billingUnitItemId)
        public
        view
        virtual
        returns (BillingUnitItem memory);

    function getBillingUnitItemIdByIndex(uint256 index) public view virtual returns (string memory);

    function getBillingUnitStageOfCompletion(string memory _billingUnitId)
        public
        view
        virtual
        returns (uint256);

    function getBillingUnitItemLength() public view virtual returns (uint256);

    function getMessageLengthOfBillingUnitItem(string memory itemId)
        public
        view
        virtual
        returns (uint256);

    function splitBillingUnitWithIssue(string memory _itemId, uint256 issueReductionAmount)
        public
        virtual;
}