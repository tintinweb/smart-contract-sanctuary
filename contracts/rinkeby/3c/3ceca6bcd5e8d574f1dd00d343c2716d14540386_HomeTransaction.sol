/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

contract Factory {
    HomeTransaction[] contracts;
    string public name;

    event ContracteCreat(string content_contracte, address address_contracte);

    constructor() {
        name = "Creation of real estate contracts SMART CONTRACTS BARCELONA";
    }

    function create(
        string memory _address,
        string memory _zip,
        string memory _city,
        string memory _observacions,
        uint256 _realtorFee,
        uint256 _price,
        uint256 _conversor,
        address payable _realtor,
        address payable _seller,
        address payable _buyer
    ) public returns (HomeTransaction homeTransaction) {
        homeTransaction = new HomeTransaction(
            _address,
            _zip,
            _city,
            _observacions,
            _realtorFee,
            _price,
            _conversor,
            _realtor,
            _seller,
            _buyer
        );
        contracts.push(homeTransaction);
        address _address_contracte = address(homeTransaction);
        string memory _content_contracte =
            "Contracte creat per la immobiliaria";
        emit ContracteCreat(_content_contracte, _address_contracte);
    }

    function getInstance(uint256 index)
        public
        view
        returns (HomeTransaction instance)
    {
        require(index < contracts.length, "index out of range");

        instance = contracts[index];
    }

    function getInstances()
        public
        view
        returns (HomeTransaction[] memory instances)
    {
        instances = contracts;
    }

    function getInstanceCount() public view returns (uint256 count) {
        count = contracts.length;
    }
}

contract HomeTransaction {
    // Constants
    uint256 constant timeBetweenDepositAndFinalization = 5 minutes;
    uint256 constant depositPercentage = 10;

    event ContracteSignatVenedor(
        string content_contracte,
        address address_venedor
    );
    event ContracteSignatCompradorDiposit(
        string content_contracte,
        address address_comprador,
        uint256 diposit_contracte
    );
    event ContracteSignatImmobiliaria(
        string content_contracte,
        address address_immobiliaria
    );
    event ContracteFinalitzatComprador(
        string content_contracte,
        address address_immobiliaria,
        uint256 pagat_contracte
    );

    enum ContractState {
        WaitingSellerSignature,
        WaitingBuyerSignature,
        WaitingRealtorReview,
        WaitingFinalization,
        Finalized,
        Rejected
    }
    ContractState public contractState = ContractState.WaitingSellerSignature;

    // Roles acting on contract
    address payable public realtor;
    address payable public seller;
    address payable public buyer;

    // Contract details
    string public homeAddress;
    string public zip;
    string public city;
    string public observacions;
    uint256 public realtorFee;
    uint256 public price;
    uint256 public conversor;

    // Set when buyer signs and pays deposit
    uint256 public deposit;
    uint256 public finalizeDeadline;

    // Set when realtor reviews closing conditions
    enum ClosingConditionsReview {Pending, Accepted, Rejected}
    ClosingConditionsReview closingConditionsReview =
        ClosingConditionsReview.Pending;

    constructor(
        string memory _address,
        string memory _zip,
        string memory _city,
        string memory _observacions,
        uint256 _realtorFee,
        uint256 _price,
        uint256 _conversor,
        address payable _realtor,
        address payable _seller,
        address payable _buyer
    ) {
        require(
            _price >= _realtorFee,
            "Price needs to be more than realtor fee!"
        );

        realtor = _realtor;
        seller = _seller;
        buyer = _buyer;
        homeAddress = _address;
        zip = _zip;
        city = _city;
        observacions = _observacions;
        price = _price;
        realtorFee = _realtorFee;
        conversor = _conversor;
    }

    function sellerSignContract() public payable {
        // require(seller == msg.sender, "Only seller can sign contract");

        require(
            contractState == ContractState.WaitingSellerSignature,
            "Wrong contract state"
        );

        contractState = ContractState.WaitingBuyerSignature;
        address _address_venedor = msg.sender;
        string memory _content_contracte = "Contracte signat pel venedor";
        emit ContracteSignatVenedor(_content_contracte, _address_venedor);
    }

    function buyerSignContractAndPayDeposit() public payable {
        //  require(buyer == msg.sender, "Only buyer can sign contract");

        require(
            contractState == ContractState.WaitingBuyerSignature,
            "Wrong contract state"
        );

        //  require(msg.value >= price*depositPercentage/100 && msg.value <= price, "Buyer needs to deposit between 10% and 100% to sign contract");

        contractState = ContractState.WaitingRealtorReview;

        deposit = msg.value;
        finalizeDeadline = block.timestamp + timeBetweenDepositAndFinalization;
        address _address_comprador = msg.sender;
        string memory _content_contracte =
            "Contracte signat pel comprador i diposit pagat.";
        uint256 _diposit_contracte = deposit;
        emit ContracteSignatCompradorDiposit(
            _content_contracte,
            _address_comprador,
            _diposit_contracte
        );
    }

    function realtorReviewedClosingConditions(bool accepted) public {
        //  require(realtor == msg.sender, "Only realtor can review closing conditions");

        require(
            contractState == ContractState.WaitingRealtorReview,
            "Wrong contract state"
        );
        address _address_immobiliaria = msg.sender;
        if (accepted) {
            closingConditionsReview = ClosingConditionsReview.Accepted;
            contractState = ContractState.WaitingFinalization;
            string memory _content_contracte =
                "Contracte signat i aprovat per la immobiliaria";
            emit ContracteSignatImmobiliaria(
                _content_contracte,
                _address_immobiliaria
            );
        } else {
            closingConditionsReview = ClosingConditionsReview.Rejected;
            contractState = ContractState.Rejected;
            buyer.transfer(deposit);
            string memory _content_contracte =
                "Contracte rebutjat i cancel.lat per la immobiliaria. Diposit retornat al comprador";
            emit ContracteSignatImmobiliaria(
                _content_contracte,
                _address_immobiliaria
            );
        }
    }

    function buyerFinalizeTransaction() public payable {
        //   require(buyer == msg.sender, "Only buyer can finalize transaction");

        require(
            contractState == ContractState.WaitingFinalization,
            "Wrong contract state"
        );

        //require(msg.value + deposit == price, "Buyer needs to pay the rest of the cost to finalize transaction");

        contractState = ContractState.Finalized;

        seller.transfer(price - realtorFee);
        realtor.transfer(realtorFee);
        uint256 _pagat_contracte = msg.value;
        address _address_comprador = msg.sender;
        string memory _content_contracte =
            "Import de l'immoble pagat pel comprador i contracte finalitzat";
        emit ContracteFinalitzatComprador(
            _content_contracte,
            _address_comprador,
            _pagat_contracte
        );
    }

    function anyWithdrawFromTransaction() public {
        require(
            buyer == msg.sender || finalizeDeadline <= block.timestamp,
            "Only buyer can withdraw before transaction deadline"
        );

        require(
            contractState == ContractState.WaitingFinalization,
            "Wrong contract state"
        );

        contractState = ContractState.Rejected;

        seller.transfer(deposit - realtorFee);
        realtor.transfer(realtorFee);
    }
}