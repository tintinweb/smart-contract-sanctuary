//SPDX-License-Identifier: UNLICENSED <SPDX-License>
pragma solidity ^0.8.0;
import {SafeMath} from "./SafeMath.sol";

contract AccepireBT {
    uint256 nonce;
    enum OrderState {
        Negotiation,
        Created,
        Received,
        Cancelled,
        Processed,
        Transit
    }
    enum PaymentState {NA, Initiated, Received, Cancelled, Processed}

    struct Order {
        bytes32 orderID;
        address seller;
        address buyer;
        string item;
        OrderState orderState;
        PaymentState paymentState;
        string description;
        bytes32 quantity;
        bool isVerifiedByInspectionCompany;
        bool isVerifiedBySellerCountryCustoms;
        bool isVerifiedByBuyerCountryCustoms;
        bool isOrder;
    }

    mapping(bytes32 => Order) public orders;

    struct dealer {
        address seller;
        address buyer;
        bytes32 orderID;
        bool isDeal;
    }
    mapping(bytes32 => dealer) public dealers;

    struct Invoice {
        uint256 unitPrice;
        uint256 totalCost;
        uint256 discount;
        uint256 CostAfterDiscount;
        bool isConfirmedByBuyer;
    }
    mapping(bytes32 => Invoice) public invoices;

    event OrderCancelled(string description);
    event OrderConfirmed(string description);
    event OrderDoesntExist(string description);
    event SetSalesContract(bytes32 orderId, address buyer, address seller);
    event Invoices(Invoice);
    //constructor(address _seller){
    //  require(msg.sender != _seller, "Seller and Buyer cannot be same.");
    //seller = _seller;
    //buyer = msg.sender;
    //}

    modifier onlySeller(bytes32 _orderID) {
        require(
            msg.sender == dealers[_orderID].seller,
            "Only seller is permissible to do the required action."
        );
        _;
    }
    modifier onlyBuyer(bytes32 _orderID) {
        require(
            msg.sender == dealers[_orderID].buyer,
            "Only buyer is permissible to do the required action."
        );
        _;
    }
    modifier inOrderState(OrderState _orderstate, bytes32 _orderID) {
        require(
            orders[_orderID].orderState == _orderstate,
            "You are not permitted to do the required action."
        );
        _;
    }

    //CONRACT 1 SALES CONTRACT BETWEEEN APPLICANT AND BENEFICIARY
    //buyer accesses the contract to start a deal with Seller
    function setSalesContract(address _seller)
        public
        returns (
            //uint256 _salt
            bytes32,
            address,
            address
        )
    {
        require(msg.sender != _seller, "Seller and Buyer cannot be same.");
        bytes32 _orderID =
            keccak256(
                abi.encode(
                    //block.timestamp,
                    block.number,
                    //msg.data,
                    nonce++
                )
            );
        require(dealers[_orderID].isDeal == false);
        dealers[_orderID].seller = _seller;
        dealers[_orderID].buyer = msg.sender;
        dealers[_orderID].orderID = _orderID;
        dealers[_orderID].isDeal = true;

        emit SetSalesContract(
            _orderID,
            dealers[_orderID].buyer,
            dealers[_orderID].seller
        );
        return (_orderID, dealers[_orderID].buyer, dealers[_orderID].seller);
    }

    //buyer creates an order
    function addOrder(
        bytes32 _orderID,
        bytes8 _quantity,
        string memory _item,
        string memory _description
    ) public onlyBuyer(_orderID) returns (bool) {
        //require(orders[_orderID].orderstate == OrderState.Negotiation, "Error: Order cannot modified anymore!");
        require(dealers[_orderID].isDeal == true, "The deal has not yet set.");

        if (orderExists(_orderID)) {
            revert("Order already exists");
        }
        orders[_orderID].orderID = _orderID;
        orders[_orderID].isOrder = true;
        orders[_orderID].orderState = OrderState.Negotiation;
        orders[_orderID].seller = dealers[_orderID].seller;
        orders[_orderID].buyer = dealers[_orderID].buyer;
        orders[_orderID].item = _item;
        orders[_orderID].description = _description;
        orders[_orderID].quantity = keccak256(abi.encode(_quantity, _orderID));
        orders[_orderID].paymentState = PaymentState.NA;
        return true;
    }

    //seller sends an invoice to buyer
    function createInvoice(
        bytes32 _orderID,
        uint256 _unitPrice,
        uint256 _discount,
        uint256 _quantity
    ) public onlySeller(_orderID) returns (Invoice memory) {
        require(orders[_orderID].orderState == OrderState.Negotiation);

        if (orderExists(_orderID)) {
            uint256 tc = SafeMath.muliply(_quantity, _unitPrice); //_quantity * _unitPrice;
            invoices[_orderID].unitPrice = _unitPrice;
            invoices[_orderID].discount = _discount;
            invoices[_orderID].totalCost = tc;
            invoices[_orderID].CostAfterDiscount = SafeMath.subtract(
                tc,
                SafeMath.division(SafeMath.muliply(tc, _discount), 100)
            ); //tc - ((tc * _discount) / 100);
            invoices[_orderID].isConfirmedByBuyer = false;
        } else {
            emit OrderDoesntExist("Order Doesn't Exist");
        }
        emit Invoices(invoices[_orderID]);
        return (invoices[_orderID]);
    }

    //buyer confirms the invoice
    function confirmInvoice(bytes32 _orderID) public onlyBuyer(_orderID) {
        invoices[_orderID].isConfirmedByBuyer = true;
    }

    //seller confirms the order
    function confirmOrder(bytes32 _orderID)
        public
        inOrderState(OrderState.Negotiation, _orderID)
        onlySeller(_orderID)
    {
        require(
            invoices[_orderID].isConfirmedByBuyer == true,
            "Invoice not Confirmed. Please confirm the invoice."
        );
        //require(orders[_orderID].orderState != OrderState.Cancelled, "Order has been cancelled.");
        emit OrderConfirmed("Order has been confirmed by the seller");
        orders[_orderID].orderState = OrderState.Created;
    }

    function orderExists(bytes32 _orderID) internal view returns (bool) {
        return orders[_orderID].isOrder;
    }

    function cancelOrder(bytes32 _orderID)
        public
        inOrderState(OrderState.Negotiation, _orderID)
        returns (bool)
    {
        //require(orders[_orderID].orderState == OrderState.Negotiation, "Sorry, Order cannot be cancelled.");
        emit OrderCancelled("Order has been cancelled");
        orders[_orderID].orderState = OrderState.Cancelled;
        return true;
    }

    // function receiveOrder(bytes32 _orderID) public onlyBuyer(_orderID) {
    //     orders[_orderID].orderState = OrderState.Received;
    // }

    function viewInvoices(bytes32 _orderID)
        public
        view
        returns (Invoice memory)
    {
        return (invoices[_orderID]);
    }

    function viewDealers(bytes32 _orderID) public view returns (dealer memory) {
        return (dealers[_orderID]);
    }

    function viewOrders(bytes32 _orderID) public view returns (Order memory) {
        return (orders[_orderID]);
    }

    function checkOrder(bytes32 _orderID) public view returns (bool) {
        return orders[_orderID].isOrder;
    }

    //CONTRACT 2 FINANCIAL CONTRACT BETWEEN APPLICANT AND ISSUING BANK
    address issuingBank;
    struct fParty {
        address buyer;
        address issuingBank;
        bytes32 orderID;
        bool exists;
        bool isConfirmedByIssuingBank;
    }
    mapping(bytes32 => fParty) public financialAgreementParties;

    modifier onlyIssuingBank() {
        require(
            msg.sender == issuingBank,
            "Only issuing Bank is permissible to do the required action."
        );
        _;
    }

    //Set the agreement
    //By Applicant
    function setFinancialAgreementParties(
        bytes32 _orderID,
        address _issuingBank
    )
        public
        onlyBuyer(_orderID)
        returns (
            bytes32,
            address,
            address,
            bool,
            bool
        )
    {
        require(orders[_orderID].isOrder == true, "Order Id doesn't exist.");
        require(
            financialAgreementParties[_orderID].exists == false,
            "The agreement has already been set."
        );

        financialAgreementParties[_orderID].buyer = msg.sender;
        financialAgreementParties[_orderID].issuingBank = _issuingBank;
        financialAgreementParties[_orderID].orderID = _orderID;
        financialAgreementParties[_orderID].exists = true;
        financialAgreementParties[_orderID].isConfirmedByIssuingBank = false;
        issuingBank = _issuingBank;

        return (
            _orderID,
            financialAgreementParties[_orderID].buyer,
            financialAgreementParties[_orderID].issuingBank,
            financialAgreementParties[_orderID].exists,
            financialAgreementParties[_orderID].isConfirmedByIssuingBank
        );
    }

    //Sign the agreement
    //BY issuing bank
    function confirmFinancialAgreement(bytes32 _orderID) public view onlyIssuingBank {
        require(
            financialAgreementParties[_orderID].exists == true,
            "The agreement is not set yet."
        );
        financialAgreementParties[_orderID].isConfirmedByIssuingBank == true;
    }

    //CONTRACT 3 BETWEEN ISSUING BANK AND BENEFICIARY VIA CORRESPONDING BANK

    struct lcparty {
        address seller;
        address issuingBank;
        bytes32 orderID;
        address correspondingBank;
        bytes32 LCID;
        bool exists;
    }
    mapping(bytes32 => lcparty) public lcParties;

    struct document {
        bytes32[] documentID;
    }
    //bytes32[] document;
    mapping(bytes32 => document) documents; //orderID => array of documents
    mapping(bytes32 => bool) documentValidity; //documentID => validity

    modifier onlyIssuingBankByOrderID(bytes32 _orderID) {
        require(
            msg.sender == lcParties[_orderID].issuingBank,
            "You are not permitted to do this action."
        );
        _;
    }

    modifier onlyCorrespondingBank(bytes32 _orderID) {
        require(
            msg.sender == lcParties[_orderID].correspondingBank,
            "You are not permitted to do this action."
        );
        _;
    }

    //By issuing bank

    function setLCAgreement(
        address _seller,
        address _correspondingBank,
        bytes32 _orderID
    )
        public
        //bytes32 _LCID
        onlyIssuingBank
        returns (bool)
    {
        require(orders[_orderID].isOrder == true, "Order doesn't exist.");
        require(
            lcParties[_orderID].exists == false,
            "The agreement has been set."
        );

        lcParties[_orderID].seller = _seller;
        lcParties[_orderID].correspondingBank = _correspondingBank;
        lcParties[_orderID].issuingBank = msg.sender;
        lcParties[_orderID].orderID = _orderID;
        // lcParties[_orderID].LCID = _LCID; //Any ID
        lcParties[_orderID].exists = true;

        return true;
    }

    //assume that we have uploaded LC to IPFS and we have an ID of that document
    //save ipfs id of the document
    //_documentID is the ID from IPFS
    function addDocument(bytes32 _orderID, bytes32 _documentID)
        public
        onlyIssuingBankByOrderID(_orderID)
    {
        require(
            lcParties[_orderID].exists == true,
            "Please set the agreement first."
        );
        documents[_orderID].documentID.push(_documentID);
        documentValidity[_documentID] = false;
    }

    //get number of documents uploaded to ipfs for this order
    function getNumberOfDocuments(bytes32 _orderID)
        public
        view
        returns (uint256)
    {
        return documents[_orderID].documentID.length;
    }

    //get the ipfs id of the document
    function getDocumentID(bytes32 _orderID)
        public
        view
        onlyCorrespondingBank(_orderID)
        returns (bytes32[] memory)
    {
        return documents[_orderID].documentID;
    }

    //check if the document is valid
    function IsDocumentValid(bytes32 _documentID) public view returns (bool) {
        return documentValidity[_documentID];
    }

    function validateDocument(bytes32 _orderID, bytes32 _documentID)
        public
        onlyCorrespondingBank(_orderID)
        returns (
            bytes32,
            bytes32,
            bool
        )
    {
        require(
            documentValidity[_documentID] == false,
            "Document has been validated already."
        );
        documentValidity[_documentID] = true;
        return (_orderID, _documentID, documentValidity[_documentID]);
    }

    //SHIPPING AGREEMENT

    struct shipmentParty {
        bytes32 orderId;
        address buyer;
        address seller;
        address sellerCountryCustoms;
        address buyerCountryCustoms;
        address inspectionCompany;
        address shippingCompany;
        bool exists;
    }
    mapping(bytes32 => shipmentParty) public shipmentParties;

    modifier onlyShippingCompany(bytes32 _orderId) {
        require(shipmentParties[_orderId].shippingCompany == msg.sender);
        _;
    }

    //By beneficiary
    function setShippingAgreement(
        bytes32 _orderId,
        address _buyer,
        address _sellerCountryCustoms,
        address _buyerCountryCustoms,
        address _inspectionCompany,
        address _shippingCompany
    ) public onlySeller(_orderId) {
        require(
            shipmentParties[_orderId].exists == false,
            "The agreement has been set for this order."
        );
        shipmentParties[_orderId].buyer = _buyer;
        shipmentParties[_orderId].orderId = _orderId;
        shipmentParties[_orderId].seller = msg.sender;
        shipmentParties[_orderId].sellerCountryCustoms = _sellerCountryCustoms;
        shipmentParties[_orderId].buyerCountryCustoms = _buyerCountryCustoms;
        shipmentParties[_orderId].shippingCompany = _shippingCompany;
        shipmentParties[_orderId].inspectionCompany = _inspectionCompany;
        shipmentParties[_orderId].exists = true;
        orders[_orderId].orderState = OrderState.Processed;
    }

    //Inspection Company and Customs (both cuntries) will verify the goods
    function verifyGoods(bytes32 _orderId) public {
        if (shipmentParties[_orderId].inspectionCompany == msg.sender)
            orders[_orderId].isVerifiedByInspectionCompany = true;
        else if (msg.sender == shipmentParties[_orderId].buyerCountryCustoms) {
            require(
                orders[_orderId].orderState == OrderState.Transit,
                "The order is not in Transit state."
            );
            orders[_orderId].isVerifiedByBuyerCountryCustoms = true;
        } else if (msg.sender == shipmentParties[_orderId].sellerCountryCustoms)
            orders[_orderId].isVerifiedBySellerCountryCustoms = true;
    }

    //Shipping Company loads the goods
    function initiateShipment(bytes32 _orderId)
        public
        onlyShippingCompany(_orderId)
    {
        require(
            orders[_orderId].orderState == OrderState.Processed,
            "The shipment has not yet processed."
        );
        require(
            orders[_orderId].isVerifiedByInspectionCompany = true,
            "The order is still waiting to be verified by the Inspection Company."
        );
        require(
            orders[_orderId].isVerifiedBySellerCountryCustoms = true,
            "The order is still waiting to be verified by the Customs."
        );
        orders[_orderId].orderState = OrderState.Transit;
    }

    //Accessed by buyer
    function confirmShipment(bytes32 _orderId) public onlyBuyer(_orderId) {
        require(
            orders[_orderId].orderState == OrderState.Transit,
            "The order is not in Transit."
        );
        orders[_orderId].orderState = OrderState.Received;
    }

    //PAYMENT Agreement to initiate the payment to seller

    struct paymentParty {
        bytes32 orderId;
        address buyer;
        address seller;
        address correspondingBank;
        bool exists;
    }
    mapping(bytes32 => paymentParty) public paymentParties;

    //set Agreement parties
    function setPaymentAgreement(
        bytes32 _orderId,
        address _correspondingBank,
        address _seller,
        address _buyer
    ) public onlyIssuingBank {
        paymentParties[_orderId].orderId = _orderId;
        paymentParties[_orderId].buyer = _buyer;
        paymentParties[_orderId].seller = _seller;
        paymentParties[_orderId].correspondingBank = _correspondingBank;
        paymentParties[_orderId].exists = true;
    }

    //For issuing Bank
    function initiatePayment(bytes32 _orderId) public onlyIssuingBank {
        require(orders[_orderId].paymentState == PaymentState.NA);
        require(
            paymentParties[_orderId].exists == true,
            "The agreement has been set."
        );
        orders[_orderId].paymentState = PaymentState.Initiated;
    }

    //for Corresponding Bank
    function processpayment(bytes32 _orderId)
        public
        onlyCorrespondingBank(_orderId)
    {
        require(
            orders[_orderId].paymentState == PaymentState.Initiated,
            "The payment has not been initiated."
        );
        orders[_orderId].paymentState = PaymentState.Processed;
    }

    //for Seller/Beneficiary Bank
    function paymentReceived(bytes32 _orderId) public onlySeller(_orderId) {
        require(
            orders[_orderId].paymentState == PaymentState.Processed,
            "The payment has not yet prcessed by the corresponding bank."
        );
        orders[_orderId].paymentState = PaymentState.Received;
        orders[_orderId].orderState = OrderState.Received;
    }
}