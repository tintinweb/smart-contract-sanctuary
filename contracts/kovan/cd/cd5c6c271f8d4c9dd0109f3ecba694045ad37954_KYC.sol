/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity >=0.4.22 <0.7.0;

contract KYC {
    address public admin;

    struct Customer {
        string userName;
        string data;
        uint256 upvotes;
        uint256 downvotes;
        address bank; //validatedBank
        bool kycStatus;
    }

    struct Bank {
        string name;
        string regNumber;
        uint256 kycCount;
        address ethAddress;
        uint256 complaintsReported;
        bool isAllowedToVote;
    }

    struct KycRequest {
        string customerName;
        string customerData;
        address bankAddress;
    }

    enum BankActions {
        AddKYC, //add request
        AddCustomer, //add customer
        RemoveKYC, //remove kyc
        RemoveCustomer, //remove customer
        ViewCustomer, // view customer details
        UpVoteCustomer, // upvote the customer
        DownVoteCustomer,
        ModifyCustomer,
        GetBankComplaint,
        ViewBankDetails,
        ReportSuspectedBank //report the suspected bank
    }

    constructor() public {
        admin = msg.sender;
    }

    address[] bankAddresses; //  To keep list of bank addresses. So that we can loop through when required

    mapping(string => Customer) customers;

    mapping(address => Bank) banks;

    mapping(string => KycRequest) kycRequests;
    mapping(string => Bank) bankVsRegNoMapping;
    mapping(string => mapping(address => uint256)) upvotes; //To track upVotes of all customers vs banks
    mapping(string => mapping(address => uint256)) downvotes; //To track downVotes of all customers vs banks
    mapping(address => mapping(int256 => uint256)) bankActionsAudit; //To track downVotes of all customers vs banks

    /********************************************************************************************************************
     *
     *  Name        :   addNewCustomerRequest
     *  Description :   This function is used to add the KYC request to the requests list. If kycPermission is set to false bank won’t be allowed to add requests for any customer.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer for whom KYC is to be done
     *      @param  {string} custData :  The hash of the customer data as a string.
     *
     *******************************************************************************************************************/

    function addNewCustomerRequest(
        string memory custName,
        string memory custData
    ) public payable returns (int256) {
        require(
            kycRequests[custName].bankAddress != address(0),
            "A KYC Request is already pending with this Customer"
        );

        kycRequests[custName] = KycRequest(custName, custData, msg.sender);
        banks[msg.sender].kycCount++;

        auditBankAction(msg.sender, BankActions.AddKYC);

        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   addCustomer
     *  Description :   This function will add a customer to the customer list. If IsAllowed is false then don't process
     *                  the request.
     *  Parameters  :
     *      param {string} custName :  The name of the customer
     *      param {string} custData :  The hash of the customer data as a string.
     *
     *******************************************************************************************************************/

    function addCustomer(string memory _userName, string memory _customerData)
        public
    {
        require(
            banks[msg.sender].isAllowedToVote,
            "Requested Bank does not have Voting Privilege"
        );
        require(
            customers[_userName].bank == address(0),
            "Customer is already present, please call modifyCustomer to edit the customer data"
        );
        // customers[_userName].userName = _userName;
        // customers[_userName].data = _customerData;
        // customers[_userName].bank = msg.sender;
        customers[_userName] = Customer(
            _userName,
            _customerData,
            0,
            0,
            msg.sender,
            false
        );

        auditBankAction(msg.sender, BankActions.AddCustomer);
    }

    /********************************************************************************************************************
     *
     *  Name        :   removeCustomer
     *  Description :   This function will remove the customer from the customer list. Remove the kyc requests of that customer
     *                  too. Only the bank which added the customer can remove him.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function removeCustomer(string memory custName)
        public
        payable
        returns (int256)
    {
        require(
            customers[custName].bank != address(0),
            "Requested Customer not found"
        );
        require(
            customers[custName].bank == msg.sender,
            "Requested Bank is not authorized to remove this customer as KYC is not initiated by you"
        );

        delete customers[custName];
        removeCustomerRequest(custName);
        auditBankAction(msg.sender, BankActions.RemoveCustomer);
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   viewCustomer
     *  Description :   This function allows allows a bank to view the details of a customer.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function viewCustomer(string memory _userName)
        public
        view
        returns (
            string memory,
            string memory,
            address
        )
    {
        require(
            customers[_userName].bank != address(0),
            "Customer is not present in the database"
        );
        return (
            customers[_userName].userName,
            customers[_userName].data,
            customers[_userName].bank
        );
    }

    /********************************************************************************************************************
     *
     *  Name        :   upVoteCustomer
     *  Description :   This function allows a bank to cast an upvote for a customer. This vote from a bank means that
     *                  it accepts the customer details as well acknowledge the KYC process done by some bank on the customer.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function upVoteCustomer(string memory custName)
        public
        payable
        returns (int256)
    {
        require(
            banks[msg.sender].isAllowedToVote,
            "Requested Bank does not have Voting Privilege"
        );
        require(
            customers[custName].bank != address(0),
            "Requested Customer not found"
        );
        customers[custName].upvotes++;
        customers[custName].kycStatus = (customers[custName].upvotes >
            customers[custName].downvotes &&
            customers[custName].upvotes > bankAddresses.length / 3);
        upvotes[custName][msg.sender] = now;
        auditBankAction(msg.sender, BankActions.UpVoteCustomer);
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   downVoteCustomer
     *  Description :   This function allows a bank to cast an downvote for a customer. This vote from a bank means that
     *                  it does not accept the customer details.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function downVoteCustomer(string memory custName)
        public
        payable
        returns (int256)
    {
        require(
            banks[msg.sender].isAllowedToVote,
            "Requested Bank does not have Voting Privilege"
        );
        require(
            customers[custName].bank != address(0),
            "Requested Customer not found"
        );
        customers[custName].downvotes++;
        customers[custName].kycStatus = (customers[custName].upvotes >
            customers[custName].downvotes &&
            customers[custName].upvotes > bankAddresses.length / 3);
        downvotes[custName][msg.sender] = now;
        auditBankAction(msg.sender, BankActions.DownVoteCustomer);
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   modifyCustomer
     *  Description :   This function allows a bank to modify a customer's data. This will remove the customer from the kyc
     *                  request list and set the number of downvote and upvote to zero.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *      @param  {string} custData :  The hash of the customer data as a string.
     *
     *******************************************************************************************************************/

    function modifyCustomer(
        string memory _userName,
        string memory _newcustomerData
    ) public payable returns (int256) {
        require(
            customers[_userName].bank != address(0),
            "Customer is not present in the database"
        );
        removeCustomerRequest(_userName);

        customers[_userName].data = _newcustomerData;
        customers[_userName].upvotes = 0;
        customers[_userName].downvotes = 0;

        auditBankAction(msg.sender, BankActions.ModifyCustomer);

        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   getReportCountOfBank
     *  Description :   This function is used to fetch bank complaints from the smart contract.
     *  Parameters  :
     *      @param  {string} custName :  The address of the bank which is suspicious
     *
     *******************************************************************************************************************/

    function getReportCountOfBank(address suspiciousBankAddress)
        public
        payable
        returns (uint256)
    {
        require(
            banks[suspiciousBankAddress].ethAddress != address(0),
            "Requested Bank not found"
        );
        return banks[suspiciousBankAddress].complaintsReported;
    }

    /********************************************************************************************************************
     *
     *  Name        :   viewBankData
     *  Description :   This function is used to fetch the bank details.
     *  Parameters  :
     *      @param  {address} bankAddress :  Bank address is passed
     *
     *******************************************************************************************************************/

    // function viewBankData(address bankAddress)
    //     public
    //     payable
    //     returns (string memory)
    // {
    //     require(
    //         banks[bankAddress].ethAddress != address(0),
    //         "Requested bank not found"
    //     );
    //     auditBankAction(msg.sender, BankActions.ViewBankDetails);
    //     return banks[bankAddress];
    // }

    /********************************************************************************************************************
     *
     *  Name        :   reportSuspectedBank
     *  Description :   This function allows a bank to report doubt/suspicion about another bank
     *  Parameters  :
     *      @param  {string} custName :  The address of the bank which is suspicious
     *
     *******************************************************************************************************************/

    function reportSuspectedBank(address suspiciousBankAddress)
        public
        payable
        returns (int256)
    {
        require(
            banks[suspiciousBankAddress].ethAddress != address(0),
            "Requested Bank not found"
        );
        banks[suspiciousBankAddress].complaintsReported++;

        auditBankAction(msg.sender, BankActions.ReportSuspectedBank);
        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   addBank
     *  Description :   This function is used by the admin to add a bank to the KYC Contract. You need to verify if the
     *                  user trying to call this function is admin or not.
     *  Parameters  :
     *      param  {string} bankName :  The name of the bank/organisation.
     *      param  {string} regNumber :   registration number for the bank. This is unique.
     *      param  {address} ethAddress :  The  unique Ethereum address of the bank/organisation
     *
     *******************************************************************************************************************/
    function addBank(
        string memory bankName,
        string memory regNumber,
        address ethAddress
    ) public payable {
        require(msg.sender == admin, "Only admin can add bank");
        require(
            !areBothStringSame(banks[ethAddress].name, bankName),
            "A Bank already exists with same name"
        );
        require(
            bankVsRegNoMapping[bankName].ethAddress != address(0),
            "A Bank already exists with same registration number"
        );

        banks[ethAddress] = Bank(
            bankName,
            regNumber,
            0,
            ethAddress,
            0,
            true
        );
        bankAddresses.push(ethAddress);
    }

    /********************************************************************************************************************
     *
     *  Name        :   removeBank
     *  Description :   This function is used by the admin to remove a bank from the KYC Contract.
     *                  You need to verify if the user trying to call this function is admin or not.
     *  Parameters  :
     *      @param  {address} ethAddress :  The  unique Ethereum address of the bank/organisation
     *
     *******************************************************************************************************************/
    function removeBank(address ethAddress) public payable returns (int256) {
        require(msg.sender == admin, "Only admin can remove bank");
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");

        delete banks[ethAddress];

        return 1;
    }

    /********************************************************************************************************************
     *
     *  Name        :   blockBankFromVoting
     *  Description :   This function can only be used by the admin to change the voting privilege of any of the
     *                  banks at any point of the time.
     *  Parameters  :
     *      @param  {address} ethAddress :  The  unique Ethereum address of the bank/organisation
     *
     *******************************************************************************************************************/
    function blockBankFromVoting(address ethAddress)
        public
        payable
        returns (int256)
    {
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");
        banks[ethAddress].isAllowedToVote = false;
        return 1;
    }


    /********************************************************************************************************************
    *
    *  Name        :   removeCustomerRequest
    *  Description :   This function will remove the request from the requests list.
    *  Parameters  :
    *      @param  {string} custName :  The name of the customer for whom KYC request has to be deleted
    *
    *******************************************************************************************************************/

    function removeCustomerRequest(string memory custName) public payable returns(int){
        require(kycRequests[custName].bankAddress == msg.sender, "Requested Bank is not authorized to remove this customer as KYC is not initiated by you");
        delete kycRequests[custName];
        
        auditBankAction(msg.sender,BankActions.RemoveKYC);
        return 1;
    }

    /********************************************************************************************************************
    *
    *  Name        :   getCustomerKycStatus
    *  Description :   This function is used to fetch customer kyc status from the smart contract. If true then the customer
    *                  is verified.
    *  Parameters  :
    *      @param  {string} custName :  The name of the customer
    *
    *******************************************************************************************************************/

    function getCustomerKycStatus(string memory custName) public payable returns(bool){
        require(customers[custName].bank != address(0), "Requested Customer not found");
        auditBankAction(msg.sender,BankActions.ViewCustomer);
        return (customers[custName].kycStatus);
    }

    /********************************************************************************************************************
     *
     *  Name        :   auditBankAction
     *  Description :   This is an internal function is to track all the actions done by any bank
     *  Parameters  :
     *      param  {address} changesDoneBy :   Ethereum address of the Bank who made the change
     *      param  {BankActions} bankAction :  The ENUM value of action done by the bank
     *
     *******************************************************************************************************************/

    function auditBankAction(address changesDoneBy, BankActions bankAction)
        private
    {
        bankActionsAudit[changesDoneBy][int256(bankAction)] = now;
    }

    /********************************************************************************************************************
     *
     *  Name        :   areBothStringSame
     *  Description :   This is an internal function is verify equality of strings
     *  Parameters  :
     *      @param {string} a :   1st string
     *      @param  {string} b :   2nd string
     *
     *******************************************************************************************************************/
    function areBothStringSame(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
}