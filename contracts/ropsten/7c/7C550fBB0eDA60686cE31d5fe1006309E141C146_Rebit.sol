/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity >=0.7.0 <0.9.0;

contract Def {
    address creator;

    constructor () {
        creator = msg.sender;
    }

    function checkUserFromStatus(
        Rebit.UserRole role,
        Rebit.Status status
    ) external pure {
        if(role == Rebit.UserRole.Applicant) {
            if(Rebit.Status.REJECTED_BY_BENEFICIARY == status) return;
            if(Rebit.Status.AMENDMENT_SUBMITTED_BENEFICIARY == status) return;
            if(Rebit.Status.REJECTED_AMENDMENT == status) return;
            if(Rebit.Status.ENDORSED_BY_BENEFICIARY == status) return;
            if(Rebit.Status.DRAFT_ISSUE_BANK_REJECT == status) return;
            if(Rebit.Status.FINAL_DC == status) return;
            if(Rebit.Status.REJECTED == status) return;
            if(Rebit.Status.INFORMAL_EMITENT_SEND_TO_APPLICANT == status) return;
            if(Rebit.Status.INFORMAL_CONFIRM_EMITENT_TO_APPLICANT == status) return;
            if(Rebit.Status.INFORMAL_CONFIRM_BENEFECIARY_TO_APPLICANT == status) return;
            if(Rebit.Status.INFORMAL_RETURNED_BENEFECIARY_TO_APPLICANT == status) return;
        } else if(role == Rebit.UserRole.Beneficiary) {
            if(Rebit.Status.SUBMITTED == status) return;
            if(Rebit.Status.WITHOUT_CONFIRMATION == status) return;
            if(Rebit.Status.WITH_CONFIRMATION == status) return;
            if(Rebit.Status.AMENDMENT_APPROVED_NOMINATED_BANK == status) return;
            if(Rebit.Status.ADVISE_WITH_CONFIRMATION_THIRD_BANK == status) return;
            if(Rebit.Status.RETURNED_TO_BENEFICIARY == status) return;
            if(Rebit.Status.INFORMAL_CONFIRM_APPLICANT_TO_BENEFECIARY == status) return;
        } else if(role == Rebit.UserRole.IssuerBank) {
            if(Rebit.Status.ENDORSED_BY_APPLICANT == status) return;
            if(Rebit.Status.SUBMITTED_ISSUE_BANK == status) return;
            if(Rebit.Status.TO_ISSUED == status) return;
            if(Rebit.Status.INFORMAL_APPLICANT_SEND_TO_EMITENT == status) return;
            if(Rebit.Status.INFORMAL_APPLICANT_CONFIRM_TO_EMITENT == status) return;
            if(Rebit.Status.INFORMAL_RETURNED_NOMINATED_TO_EMITENT == status) return;
            if(Rebit.Status.INFORMAL_CONFIRM_NOMINATED_TO_EMITENT == status) return;
            if(Rebit.Status.INFORMAL_CONFIRM_REMBURSE_TO_EMITENT == status) return;
            if(Rebit.Status.INFORMAL_RETURNED_REMBURSE_TO_EMITENT == status) return;
        } else if(role == Rebit.UserRole.ExecutingBank) {
            if(Rebit.Status.ISSUED == status) return;
            if(Rebit.Status.REQUESTING_CONFIRMATION == status) return;
            if(Rebit.Status.AMENDMENT_ISSUED == status) return;
            if(Rebit.Status.INFORMAL_EMITENT_SEND_TO_NOMINATED == status) return;
        } else if(role == Rebit.UserRole.ReimbursingBank) {
            if(status == Rebit.Status.INFORMAL_SEND_EMITENT_TO_REMBURSE) return;
        }

        require(false, "cannot change request from current status");
    }

    function checkFromToStatus(
        Rebit.Status from,
        Rebit.Status to
    ) external pure {
        if (from == Rebit.Status.SUBMITTED){
            if(to == Rebit.Status.ENDORSED_BY_BENEFICIARY) return;
            if(to == Rebit.Status.REJECTED_BY_BENEFICIARY) return;
        } else if (from == Rebit.Status.REJECTED_AMENDMENT || from == Rebit.Status.REJECTED_BY_BENEFICIARY){
            if(to == Rebit.Status.SUBMITTED) return;
        } else if (from == Rebit.Status.ENDORSED_BY_BENEFICIARY) {
            if(to == Rebit.Status.SUBMITTED_ISSUE_BANK) return;
        } else if (from == Rebit.Status.SUBMITTED_ISSUE_BANK) {
            if(to == Rebit.Status.FINAL_DC) return;
            if(to == Rebit.Status.DRAFT_ISSUE_BANK_REJECT) return;
        } else if (from == Rebit.Status.FINAL_DC) {
            if(to == Rebit.Status.TO_ISSUED) return;
        } else if (from == Rebit.Status.TO_ISSUED) {
            if(to == Rebit.Status.ISSUED) return;
        } else if (from == Rebit.Status.DRAFT_ISSUE_BANK_REJECT) {
            if(to == Rebit.Status.SUBMITTED_ISSUE_BANK) return;
        } else if (from == Rebit.Status.ISSUED || from == Rebit.Status.ADVISE_BANK_REJECTED) {
            if(to == Rebit.Status.WITHOUT_CONFIRMATION) return;
            if(to == Rebit.Status.REJECTED) return;
            if(to == Rebit.Status.WITH_CONFIRMATION) return;
            if(to == Rebit.Status.ADVISE_THIRD_BANK) return;
        } else if (from == Rebit.Status.WITHOUT_CONFIRMATION) {
            if(to == Rebit.Status.AMENDMENT_SUBMITTED_BENEFICIARY) return;
            if(to == Rebit.Status.REQUESTING_CONFIRMATION) return;
            if(to == Rebit.Status.SUBMITTED_BENEFICIARY_DOC) return;
        } else if (from == Rebit.Status.REQUESTING_CONFIRMATION) {
            if(to == Rebit.Status.WITH_CONFIRMATION) return;
            if(to == Rebit.Status.REJECTED) return;
        } else if (from == Rebit.Status.WITH_CONFIRMATION || from == Rebit.Status.ADVISE_WITH_CONFIRMATION_THIRD_BANK) {
            if(to == Rebit.Status.AMENDMENT_SUBMITTED_BENEFICIARY) return;
            if(to == Rebit.Status.REQUEST_FOR_TRANSFER_DC) return;
            if(to == Rebit.Status.SUBMITTED_BENEFICIARY_DOC) return;
        }  else if(from == Rebit.Status.AMENDMENT_SUBMITTED_BENEFICIARY) {
            if(to == Rebit.Status.ENDORSED_BY_APPLICANT) return;
        } else if (from == Rebit.Status.ENDORSED_BY_APPLICANT) {
            if(to == Rebit.Status.AMENDMENT_ISSUED) return;
            if(to == Rebit.Status.REJECTED_AMENDMENT) return;
        } else if (from == Rebit.Status.AMENDMENT_ISSUED) {
            if(to == Rebit.Status.AMENDMENT_APPROVED_NOMINATED_BANK) return;
            if(to == Rebit.Status.REJECTED_AMENDMENT) return;
        } else if (from == Rebit.Status.AMENDMENT_APPROVED_NOMINATED_BANK) {
            if(to == Rebit.Status.WITH_CONFIRMATION) return;
            if(to == Rebit.Status.REJECTED_AMENDMENT) return;
        } else if (from == Rebit.Status.ADVISE_THIRD_BANK) {
            if(to == Rebit.Status.ADVISE_WITH_CONFIRMATION_THIRD_BANK) return;
            if(to == Rebit.Status.ADVISE_BANK_REJECTED) return;
        } else if (from == Rebit.Status.REQUEST_FOR_TRANSFER_DC) {
            if(to == Rebit.Status.TRANSFER_FOR_DC) return;
        } else if (from == Rebit.Status.TRANSFER_FOR_DC) {
            if(to == Rebit.Status.SUBMITTED_BENEFICIARY_DOC) return;
        } else if (from == Rebit.Status.INFORMAL_APPLICANT_SEND_TO_EMITENT) {
            if(to == Rebit.Status.INFORMAL_EMITENT_SEND_TO_APPLICANT) return;
        } else if (from == Rebit.Status.INFORMAL_EMITENT_SEND_TO_APPLICANT) {
            if(to == Rebit.Status.INFORMAL_APPLICANT_CONFIRM_TO_EMITENT) return;
            if(to == Rebit.Status.INFORMAL_APPLICANT_SEND_TO_EMITENT) return;
        } else if (from == Rebit.Status.INFORMAL_APPLICANT_CONFIRM_TO_EMITENT) {
            if(to == Rebit.Status.INFORMAL_EMITENT_SEND_TO_NOMINATED) return;
        } else if (from == Rebit.Status.INFORMAL_EMITENT_SEND_TO_NOMINATED) {
            if(to == Rebit.Status.INFORMAL_RETURNED_NOMINATED_TO_EMITENT) return;
            if(to == Rebit.Status.INFORMAL_CONFIRM_NOMINATED_TO_EMITENT) return;
        } else if (from == Rebit.Status.INFORMAL_RETURNED_NOMINATED_TO_EMITENT) {
            if(to == Rebit.Status.INFORMAL_EMITENT_SEND_TO_NOMINATED) return;
            if(to == Rebit.Status.INFORMAL_CONFIRM_NOMINATED_TO_EMITENT) return;
        } else if (from == Rebit.Status.INFORMAL_CONFIRM_REMBURSE_TO_EMITENT) {
            if(to == Rebit.Status.INFORMAL_CONFIRM_EMITENT_TO_APPLICANT) return;
        } else if (from == Rebit.Status.INFORMAL_CONFIRM_NOMINATED_TO_EMITENT) {
            if(to == Rebit.Status.INFORMAL_SEND_EMITENT_TO_REMBURSE) return;
            if(to == Rebit.Status.INFORMAL_CONFIRM_EMITENT_TO_APPLICANT) return;
        } else if (from == Rebit.Status.INFORMAL_SEND_EMITENT_TO_REMBURSE) {
            if(to == Rebit.Status.INFORMAL_RETURNED_REMBURSE_TO_EMITENT) return;
            if(to == Rebit.Status.INFORMAL_CONFIRM_REMBURSE_TO_EMITENT) return;
        } else if (from == Rebit.Status.INFORMAL_RETURNED_REMBURSE_TO_EMITENT) {
            if(to == Rebit.Status.INFORMAL_SEND_EMITENT_TO_REMBURSE) return;
        } else if (from == Rebit.Status.INFORMAL_CONFIRM_EMITENT_TO_APPLICANT) {
            if(to == Rebit.Status.INFORMAL_RETURNED_APPLICANT_TO_EMITENT) return;
            if(to == Rebit.Status.INFORMAL_CONFIRM_APPLICANT_TO_BENEFECIARY) return;
        } else if (from == Rebit.Status.INFORMAL_CONFIRM_APPLICANT_TO_BENEFECIARY) {
            if(to == Rebit.Status.INFORMAL_RETURNED_BENEFECIARY_TO_APPLICANT) return;
            if(to == Rebit.Status.INFORMAL_CONFIRM_BENEFECIARY_TO_APPLICANT) return;
        } else if (from == Rebit.Status.INFORMAL_CONFIRM_BENEFECIARY_TO_APPLICANT) {
            if(to == Rebit.Status.FINAL_DC) return;
        } else if (from == Rebit.Status.INFORMAL_RETURNED_BENEFECIARY_TO_APPLICANT) {
            if(to == Rebit.Status.INFORMAL_RETURNED_BENEFECIARY_TO_APPLICANT) return;
            if(to == Rebit.Status.INFORMAL_CONFIRM_BENEFECIARY_TO_APPLICANT) return;
        } else if (from == Rebit.Status.SUBMITTED_BENEFICIARY_DOC) {
            if(to == Rebit.Status.NOMINATED_BANK_DISCREPANT_DOC) return;
            if(to == Rebit.Status.RETURNED_NOMINATED_DOC) return;
            if(to == Rebit.Status.ADVICE_PAYMENT) return;
        } else if (from == Rebit.Status.AUTH_REIMURSE) {
            if(to == Rebit.Status.PAYMENT) return;
        } else if (from == Rebit.Status.RETURNED_NOMINATED_DOC) {
            if(to == Rebit.Status.SUBMITTED_BENEFICIARY_DOC) return;
        } else if (from == Rebit.Status.ASK_FOR_APPLICANT) {
            if(to == Rebit.Status.RETURNED_NOMINATED_DOC) return;
        } else if (from == Rebit.Status.NOMINATED_BANK_CLEAN_DOC || from == Rebit.Status.NOMINATED_BANK_DISCREPANT_DOC) {
            if(to == Rebit.Status.ACCEPTED_ISSUING_BANK_DOC) return;
            if(to == Rebit.Status.NOTIFY_DISCREPANCIES) return;
        } else if (from == Rebit.Status.ACCEPTED_ISSUING_BANK_DOC || from == Rebit.Status.NOTIFY_DISCREPANCIES) {
            if(to == Rebit.Status.ACCEPTED_APPLICANT_DOC) return;
        } else if (from == Rebit.Status.ACCEPTED_APPLICANT_DOC) {
            if(to == Rebit.Status.PAYMENT) return;
        } else  {
            if(to == Rebit.Status.INFORMAL_APPLICANT_SEND_TO_EMITENT) return;
        }

        require(false, "cannot have this status");
    }

    function getStatus(uint i) external pure returns (Rebit.Status result) {
        if(i == 0)
            result = Rebit.Status.INFORMAL_APPLICANT_SEND_TO_EMITENT;
        else if(i == 1)
            result = Rebit.Status.SUBMITTED;
        else if(i == 2)
            result = Rebit.Status.REJECTED;
        else if(i == 3)
            result = Rebit.Status.REJECTED_BY_BENEFICIARY;
        else if(i == 4)
            result = Rebit.Status.REJECTED_AMENDMENT;
        else if(i == 5)
            result = Rebit.Status.ENDORSED_BY_BENEFICIARY;
        else if(i == 6)
            result = Rebit.Status.ENDORSED_BY_APPLICANT;
        else if(i == 7)
            result = Rebit.Status.RETURNED_TO_BENEFICIARY;
        else if(i == 8)
            result = Rebit.Status.ISSUED;
        else if(i == 9)
            result = Rebit.Status.WITHOUT_CONFIRMATION;
        else if(i == 10)
            result = Rebit.Status.REQUESTING_CONFIRMATION;
        else if(i == 11)
            result = Rebit.Status.REQUESTING_AMENDMENT;
        else if(i == 12)
            result = Rebit.Status.WITH_CONFIRMATION;
        else if(i == 13)
            result = Rebit.Status.AMENDMENT_SUBMITTED_BENEFICIARY;
        else if(i == 14)
            result = Rebit.Status.AMENDMENT_ENDORSED;
        else if(i == 15)
            result = Rebit.Status.AMENDMENT_ISSUED;
        else if(i == 16)
            result = Rebit.Status.AMENDMENT_APPROVED_NOMINATED_BANK;
        else if(i == 17)
            result = Rebit.Status.SUBMITTED_ISSUE_BANK;
        else if(i == 18)
            result = Rebit.Status.FINAL_DC;
        else if(i == 19)
            result = Rebit.Status.DRAFT_ISSUE_BANK_REJECT;
        else if(i == 20)
            result = Rebit.Status.TO_ISSUED;
        else if(i == 21)
            result = Rebit.Status.ADVISE_THIRD_BANK;
        else if(i == 22)
            result = Rebit.Status.ADVISE_BANK_REJECTED;
        else if(i == 23)
            result = Rebit.Status.ADVISE_WITH_CONFIRMATION_THIRD_BANK;
        else if(i == 24)
            result = Rebit.Status.REQUEST_FOR_TRANSFER_DC;
        else if(i == 25)
            result = Rebit.Status.TRANSFER_FOR_DC;
        else if(i == 26)
            result = Rebit.Status.ADVISE_OF_TRANSFER;
        else if(i == 27)
            result = Rebit.Status.ADVICE_PAYMENT;
        else if(i == 28)
            result = Rebit.Status.AUTH_REIMURSE;
        else if(i == 29)
            result = Rebit.Status.PAYMENT;
        else if(i == 30)
            result = Rebit.Status.INFORMAL_EMITENT_SEND_TO_APPLICANT;
        else if(i == 31)
            result = Rebit.Status.INFORMAL_EMITENT_SEND_CANCEL_TO_APPLICANT;
        else if(i == 32)
            result = Rebit.Status.INFORMAL_APPLICANT_CONFIRM_TO_EMITENT;
        else if(i == 33)
            result = Rebit.Status.INFORMAL_EMITENT_SEND_TO_NOMINATED;
        else if(i == 34)
            result = Rebit.Status.INFORMAL_RETURNED_NOMINATED_TO_EMITENT;
        else if(i == 35)
            result = Rebit.Status.INFORMAL_CONFIRM_NOMINATED_TO_EMITENT;
        else if(i == 36)
            result = Rebit.Status.INFORMAL_CONFIRM_EMITENT_TO_APPLICANT;
        else if(i == 37)
            result = Rebit.Status.INFORMAL_RETURNED_APPLICANT_TO_EMITENT;
        else if(i == 38)
            result = Rebit.Status.INFORMAL_CONFIRM_APPLICANT_TO_BENEFECIARY;
        else if(i == 39)
            result = Rebit.Status.INFORMAL_RETURNED_BENEFECIARY_TO_APPLICANT;
        else if(i == 40)
            result = Rebit.Status.INFORMAL_CONFIRM_BENEFECIARY_TO_APPLICANT;
        else if(i == 41)
            result = Rebit.Status.INFORMAL_SEND_EMITENT_TO_REMBURSE;
        else if(i == 42)
            result = Rebit.Status.INFORMAL_CONFIRM_REMBURSE_TO_EMITENT;
        else if(i == 43)
            result = Rebit.Status.INFORMAL_RETURNED_REMBURSE_TO_EMITENT;
        else if(i == 44)
            result = Rebit.Status.SUBMITTED_BENEFICIARY_DOC;
        else if(i == 45)
            result = Rebit.Status.RETURNED_NOMINATED_DOC;
        else if(i == 46)
            result = Rebit.Status.NOMINATED_BANK_CLEAN_DOC;
        else if(i == 47)
            result = Rebit.Status.NOMINATED_BANK_DISCREPANT_DOC;
        else if(i == 48)
            result = Rebit.Status.ACCEPTED_ISSUING_BANK_DOC;
        else if(i == 49)
            result = Rebit.Status.ACCEPTED_APPLICANT_DOC;
        else if(i == 50)
            result = Rebit.Status.NOMINATED_BANK_CLEAN_DOC;
        else if(i == 51)
            result = Rebit.Status.ASK_FOR_APPLICANT;
        else if(i == 52)
            result = Rebit.Status.RESUBMIT;
        else if(i == 53)
            result = Rebit.Status.SEND_CLEAN;
        else if(i == 54)
            result = Rebit.Status.RETURNED_FOR_RESUBMIT;
        else if(i == 55)
            result = Rebit.Status.SEND_DISCREPANT;
        else if(i == 56)
            result = Rebit.Status.NOTIFY_DISCREPANCIES;
        else if(i == 57)
            result = Rebit.Status.CLOSED;
        else
            require(false, 'Status value not found');
    }

    mapping (uint256 => Additionally) AdditionallyForRequest;

    function set(Additionally calldata ad, uint256 id) external {
        require(msg.sender == creator, "transaction can only be done by contract owner");

        Additionally storage st = AdditionallyForRequest[id];
        st.isInitiated = true;

        for (uint i = 0; i < st.invoice.length; i++)
            st.invoice.pop();
        for (uint i = 0; i < st.packingListDoc.length; i++)
            st.packingListDoc.pop();
        for (uint i = 0; i < st.transportDocumentDoc.length; i++)
            st.transportDocumentDoc.pop();

        for (uint i = 0; i < ad.invoice.length; i++)
            st.invoice.push(ad.invoice[i]);
        for (uint i = 0; i < ad.packingListDoc.length; i++)
            st.packingListDoc.push(ad.packingListDoc[i]);
        for (uint i = 0; i < ad.transportDocumentDoc.length; i++)
            st.transportDocumentDoc.push(ad.transportDocumentDoc[i]);




        st.presented_date = ad.presented_date;
        st.payment_due_date = ad.payment_due_date;
        st.drawing_amount = ad.drawing_amount;
        st.drawing_amount_cost = ad.drawing_amount_cost;
        st.amount = ad.amount;
        st.amount_cost = ad.amount_cost;
        st.uploadInvoice = ad.uploadInvoice;
        st.certificate_origin_doc = ad.certificate_origin_doc;
        st.certificate_origin_status = ad.certificate_origin_status;

        // instructions_to_nominated_bank
        st.our_instruction= ad.our_instruction;
        st.other_instruction = ad.other_instruction;
        st.number_to_form = ad.number_to_form;
        st.number_to_credit = ad.number_to_credit;
        st.exchange = ad.exchange;
        st.other_proceeds = ad.other_proceeds;

        // notice_discrepancies_nominated_bank
        st.discrepancies = ad.discrepancies;
        st.upload_advise = ad.upload_advise;

        st.negotiation_terms = ad.negotiation_terms;

        // RemittanceInstructions
        st.principal_amount = ad.principal_amount;
        st.principal_amount_cost = ad.principal_amount_cost;
        st.additional_amount = ad.additional_amount;
        st.additional_amount_cost = ad.additional_amount_cost;
        st.charges = ad.charges;
        st.total_amount = ad.total_amount;
        st.total_amount_cost = ad.total_amount_cost;
        st.account_with_bank = ad.account_with_bank;
        st.beneficiary_bank = ad.beneficiary_bank;

        // BillInstructions
        st.settlement_amount_cost = ad.settlement_amount_cost;
        st.account_debit_payment = ad.account_debit_payment;
        st.other_instructions = ad.other_instructions;
    }

    function get(uint256 id) external view returns (Additionally memory) {
        return AdditionallyForRequest[id];
    }


    struct Additionally {
        bool isInitiated;
        ListDocInput[] packingListDoc;
        ListDocInput[] transportDocumentDoc;
        uint presented_date;
        uint payment_due_date;
        string drawing_amount;
        int drawing_amount_cost;
        string amount;
        int amount_cost;
        string uploadInvoice;
        Invoice[] invoice;
        string certificate_origin_doc;
        bool certificate_origin_status;

        // instructions_to_nominated_bank
        ourInstructionInput our_instruction;
        string other_instruction;
        string number_to_form;
        string number_to_credit;
        string exchange;
        string other_proceeds;

        // notice_discrepancies_nominated_bank
        string discrepancies;
        string upload_advise;

        string negotiation_terms;

        // RemittanceInstructions
        string principal_amount;
        int principal_amount_cost;
        string additional_amount;
        int additional_amount_cost;
        string charges;
        string total_amount;
        int total_amount_cost;
        string account_with_bank;
        string beneficiary_bank;

        // BillInstructions
        string settlement_amount_cost;
        string account_debit_payment;
        string other_instructions;
    }



    enum ourInstructionInput {
        negotiation_under,
        negotiation_after_receipt,
        payment_require,
        payment_not_require
    }

    struct ListDocInput {
        string number;
        uint date;
        string file;
    }

    struct Invoice {
        string invoice_no;
        uint issued_date;
        string description_of_goods_or_services;
        int quantity;
        string amount;
        int amount_cost;
        string uploadInvoice;
    }
}

contract Rebit {
    mapping (uint256 => Request) requests;
    mapping (string => uint256[]) requestsForUser;
    uint256 requestsCounter = 1;
    address creator;
    // first deploy Def and put its address here
    address constant defAddress = 0x848CFE35819bF1a285597Ed393500C229DEfAECF;

    constructor () {
        creator = msg.sender;
    }

    function getUserRequests(
        string calldata id,
        uint256 page
    ) external view returns (uint256 total, Request[10] memory data) {
        total = requestsForUser[id].length;

        uint started = page * 10;
        uint end = started + 10;
        if(end > total)
            end = total;
        require(total > started, "requested page does not exist");

        for (uint served = started; served < end; served++)
            data[served - started] = getRequest(requestsForUser[id][served]);
    }

    function deleteRequest(
        uint256 requestNumber
    ) external {
        require(msg.sender == creator, "transaction can only be done by contract owner");
        Request storage request = requests[requestNumber];
        request.isInitiated = false;
    }

    function modifyOrCreateRequest(
        Request calldata request,
        uint256 editRequestNumber,
        string calldata userId
    ) external returns (uint256 requestNumber) {
        require(msg.sender == creator, "transaction can only be done by contract owner");

        if(editRequestNumber == 0){
            requestsCounter++;
            requestNumber = requestsCounter;

            requests[requestNumber].isInitiated = true;
            requests[requestNumber].status = Status.INFORMAL_APPLICANT_SEND_TO_EMITENT;
//            requests[requestNumber].createDate = request.createDate;


            requestsForUser[request.applicantId].push(requestNumber);
            requestsForUser[request.issuerBankId].push(requestNumber);
            requestsForUser[request.beneficiaryId].push(requestNumber);
            requestsForUser[request.executingBankId].push(requestNumber);
            requestsForUser[request.reimbursingBankId].push(requestNumber);
        } else {
            require(requests[editRequestNumber].isInitiated, "cannot edit this request");
            requestNumber = editRequestNumber;

            if(request.status != requests[requestNumber].status){
//                UserRole role = getUserRole(requestNumber, userId);

                Def(defAddress).checkFromToStatus(requests[requestNumber].status, request.status);
//                Def(defAddress).checkUserFromStatus(role, request.status);
                requests[requestNumber].status = request.status;
            }

            for (uint i = 0; i < requests[requestNumber].payments.length; i++)
                requests[requestNumber].payments.pop();

            for (uint i = 0; i < requests[requestNumber].othersDocuments.length; i++)
                requests[requestNumber].othersDocuments.pop();
        }

        for (uint i = 0; i < request.payments.length; i++)
            requests[requestNumber].payments.push(request.payments[i]);

        for (uint i = 0; i < request.othersDocuments.length; i++)
            requests[requestNumber].othersDocuments.push(request.othersDocuments[i]);


        requests[requestNumber].documentTransport = request.documentTransport;
        requests[requestNumber].placeTaking = request.placeTaking;
        requests[requestNumber].instructionToPaying = request.instructionToPaying;
        requests[requestNumber]._id = requestNumber;
        requests[requestNumber].advisingBank = request.advisingBank;
        requests[requestNumber].advisingBankAddress = request.advisingBankAddress;
        requests[requestNumber].secondaryBeneficiary = request.secondaryBeneficiary;
        requests[requestNumber].secondaryBeneficiaryAddress = request.secondaryBeneficiaryAddress;
        requests[requestNumber].secondaryBeneficiaryBank = request.secondaryBeneficiaryBank;
        requests[requestNumber].secondaryBeneficiaryBankAddress = request.secondaryBeneficiaryBankAddress;
        requests[requestNumber].reimbursingBank = request.reimbursingBank;
        requests[requestNumber].reimbursingBankAddress = request.reimbursingBankAddress;
        requests[requestNumber].isConfirmDC = request.isConfirmDC;
        requests[requestNumber].availabilityDetailsDay = request.availabilityDetailsDay;
        requests[requestNumber].availabilityDetailsNumber = request.availabilityDetailsNumber;
        requests[requestNumber].availabilityDetailsDesc = request.availabilityDetailsDesc;
        requests[requestNumber].availabilityDetailsDate = request.availabilityDetailsDate;
        requests[requestNumber].availabilityDetailsEvent = request.availabilityDetailsEvent;
        requests[requestNumber].isAvailabilityDetails = request.isAvailabilityDetails;
        requests[requestNumber].packingList = request.packingList;
        requests[requestNumber].issuedDcReference = request.issuedDcReference;
        requests[requestNumber].advisedDcReference = request.advisedDcReference;
        requests[requestNumber].formOfDocumentaryCredit = request.formOfDocumentaryCredit;
        requests[requestNumber].applicableRules = request.applicableRules;
        requests[requestNumber].dateOfIssue = request.dateOfIssue;
        requests[requestNumber].expiryDate = request.expiryDate;
        requests[requestNumber].expiryPlace = request.expiryPlace;
        requests[requestNumber].periodOfPresentation = request.periodOfPresentation;
        requests[requestNumber].applicantAddress = request.applicantAddress;
        requests[requestNumber].beneficiaryAddress = request.beneficiaryAddress;
        requests[requestNumber].issuerBankAddress = request.issuerBankAddress;
        requests[requestNumber].executingBankAddress = request.executingBankAddress;
        requests[requestNumber].amount = request.amount;
        requests[requestNumber].amountCost = request.amountCost;
        requests[requestNumber].tolerancePlus = request.tolerancePlus;
        requests[requestNumber].toleranceMinus = request.toleranceMinus;
        requests[requestNumber].availabilityType = request.availabilityType;
        requests[requestNumber].availabilityDetails = request.availabilityDetails;
        requests[requestNumber].partialShipments = request.partialShipments;
        requests[requestNumber].transshipment = request.transshipment;
        requests[requestNumber].latestDateOfShipment = request.latestDateOfShipment;
        requests[requestNumber].locationLoading = request.locationLoading;
        requests[requestNumber].locationDischarge = request.locationDischarge;
        requests[requestNumber].descriptionGoods = request.descriptionGoods;
        requests[requestNumber].documentInvoice = request.documentInvoice;
        requests[requestNumber].certificateOfOrigin = request.certificateOfOrigin;
        requests[requestNumber].documentOther = request.documentOther;
        requests[requestNumber].AdditionalConditionsConditions = request.AdditionalConditionsConditions;
        requests[requestNumber].detailsOfCharges = request.detailsOfCharges;
        requests[requestNumber].confirmationInstruction = request.confirmationInstruction;

        requests[requestNumber].reimbursingBankId = request.reimbursingBankId;
        requests[requestNumber].applicantId = request.applicantId;
        requests[requestNumber].issuerBankId = request.issuerBankId;
        requests[requestNumber].beneficiaryId = request.beneficiaryId;
        requests[requestNumber].executingBankId = request.executingBankId;
    }



//    function getUserRole(
//        uint256 requestNumber,
//        string calldata userId
//    ) internal view returns (UserRole role) {
//        Request memory request = getRequest(requestNumber);
//        bytes32 userIdCode = keccak256(abi.encodePacked(userId));
//        if(keccak256(abi.encodePacked(request.beneficiaryId)) == userIdCode)
//            role = UserRole.Beneficiary;
//        else if(keccak256(abi.encodePacked(request.issuerBankId)) == userIdCode)
//            role = UserRole.IssuerBank;
//        else if(keccak256(abi.encodePacked(request.executingBankId)) == userIdCode)
//            role = UserRole.ExecutingBank;
//        else if(keccak256(abi.encodePacked(request.reimbursingBankId)) == userIdCode)
//            role = UserRole.ReimbursingBank;
//        else if(keccak256(abi.encodePacked(request.applicantId)) == userIdCode)
//            role = UserRole.Applicant;
//        else
//            require(false, 'Given user cannot interact with given request');
//    }



    function getRequest(
        uint256 requestNumber
    ) public view returns (Request memory) {
        //        require(requests[requestNumber].isInitiated, 'request not found');
        return requests[requestNumber];
    }


    struct Request {
        bool isInitiated;
        string applicantId;
        bool documentTransport;
        bool packingList;
        string placeTaking;
        string instructionToPaying;
        uint256 _id;
        string advisingBank;
        string advisingBankAddress;
        string secondaryBeneficiary;
        string secondaryBeneficiaryAddress;
        string secondaryBeneficiaryBank;
        string secondaryBeneficiaryBankAddress;
        string reimbursingBankId;
        string reimbursingBank;
        string reimbursingBankAddress;
        string isConfirmDC;
        string issuerBankId;
        string beneficiaryId;
        string executingBankId;
        string availabilityDetailsDay;
        string availabilityDetailsNumber;
        string availabilityDetailsDesc;
        uint availabilityDetailsDate;
        string availabilityDetailsEvent;
        bool isAvailabilityDetails;
        string issuedDcReference;
        string advisedDcReference;
        string formOfDocumentaryCredit;
        uint dateOfIssue;
        uint expiryDate;
        string expiryPlace;
        int periodOfPresentation;
        string applicantAddress;
        string beneficiaryAddress;
        string issuerBankAddress;
        string executingBankAddress;
        string amount;
        int amountCost;
        int tolerancePlus;
        int toleranceMinus;
        string availabilityDetails;
        bool partialShipments;
        bool transshipment;
        uint latestDateOfShipment;
        string locationLoading;
        string locationDischarge;
        string descriptionGoods;
        bool documentInvoice;
        bool certificateOfOrigin;
        bool documentOther;
        string AdditionalConditionsConditions;
        string detailsOfCharges;

        Payment[] payments;
        othersDocumentsInput[] othersDocuments;
//        uint createDate;

        Status status;
        applicableRulesInput applicableRules;
        availabilityTypeInput availabilityType;
        confirmationInstructionInput confirmationInstruction;
    }

    enum applicableRulesInput {
        eUCP,
        UCP
    }

    enum availabilityTypeInput {
        deferredPayment,
        paymentAtSight,
        acceptance
    }

    enum confirmationInstructionInput {
        withOut,
        with,
        mayAdd
    }

    struct othersDocumentsInput {
        string number;
        uint date;
        string file;
    }

    struct Payment {
        string id;
        string User;
        string Side1type;
        string Side1name;
        string Side2type;
        string Side2name;
        string status;
        string CurrencyName;
        string amount;
        string PaymentDetailId;
        string PaymentDetailType;
        string PaymentDetailCode;
        string PaymentDetailDetail;
        string document;
    }

    enum UserRole {
        Applicant,
        Beneficiary,
        IssuerBank,
        ExecutingBank,
        ReimbursingBank
    }


    enum Status {
        INFORMAL_APPLICANT_SEND_TO_EMITENT,
        SUBMITTED,
        REJECTED,
        REJECTED_BY_BENEFICIARY,
        REJECTED_AMENDMENT,
        ENDORSED_BY_BENEFICIARY,
        ENDORSED_BY_APPLICANT,
        RETURNED_TO_BENEFICIARY,
        ISSUED,
        WITHOUT_CONFIRMATION,
        REQUESTING_CONFIRMATION,
        REQUESTING_AMENDMENT,
        WITH_CONFIRMATION,
        AMENDMENT_SUBMITTED_BENEFICIARY,
        AMENDMENT_ENDORSED,
        AMENDMENT_ISSUED,
        AMENDMENT_APPROVED_NOMINATED_BANK,
        SUBMITTED_ISSUE_BANK,
        FINAL_DC,
        DRAFT_ISSUE_BANK_REJECT,
        TO_ISSUED,
        ADVISE_THIRD_BANK,
        ADVISE_BANK_REJECTED,
        ADVISE_WITH_CONFIRMATION_THIRD_BANK,
        REQUEST_FOR_TRANSFER_DC,
        TRANSFER_FOR_DC,
        ADVISE_OF_TRANSFER,
        ADVICE_PAYMENT,
        AUTH_REIMURSE,
        INFORMAL_EMITENT_SEND_TO_APPLICANT,
        INFORMAL_EMITENT_SEND_CANCEL_TO_APPLICANT,
        INFORMAL_APPLICANT_CONFIRM_TO_EMITENT,
        INFORMAL_EMITENT_SEND_TO_NOMINATED,
        INFORMAL_RETURNED_NOMINATED_TO_EMITENT,
        INFORMAL_CONFIRM_NOMINATED_TO_EMITENT,
        INFORMAL_CONFIRM_EMITENT_TO_APPLICANT,
        INFORMAL_RETURNED_APPLICANT_TO_EMITENT,
        INFORMAL_CONFIRM_APPLICANT_TO_BENEFECIARY,
        INFORMAL_RETURNED_BENEFECIARY_TO_APPLICANT,
        INFORMAL_CONFIRM_BENEFECIARY_TO_APPLICANT,
        INFORMAL_SEND_EMITENT_TO_REMBURSE,
        INFORMAL_CONFIRM_REMBURSE_TO_EMITENT,
        INFORMAL_RETURNED_REMBURSE_TO_EMITENT,
        SUBMITTED_BENEFICIARY_DOC,
        RETURNED_NOMINATED_DOC,
        NOMINATED_BANK_CLEAN_DOC,
        NOMINATED_BANK_DISCREPANT_DOC,
        ACCEPTED_ISSUING_BANK_DOC,
        ACCEPTED_APPLICANT_DOC,
        ASK_FOR_APPLICANT,
        RESUBMIT,
        SEND_CLEAN,
        RETURNED_FOR_RESUBMIT,
        SEND_DISCREPANT,
        NOTIFY_DISCREPANCIES,
        CLOSED,
        PAYMENT
    }
}