/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity ^0.4.17;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account));
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account));
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract ApproverRole {
    using Roles for Roles.Role;

    event ApproverAdded(address indexed account);
    event ApproverRemoved(address indexed account);

    Roles.Role private _approvers;

    address firstSignAddress;
    address secondSignAddress;
    
    mapping(address => bool) signed; // Signed flag

    constructor () internal {
        _addApprover(msg.sender);
        
        firstSignAddress = 0x4019122718f2dBE3B9bA0B3701Ab8F6CEBc5B07B;   // You should change this address to your first sign address
        secondSignAddress = 0x4019122718f2dBE3B9bA0B3701Ab8F6CEBc5B07B;  // You should change this address to your second sign address
    }

    modifier onlyApprover() {
        require(isApprover(msg.sender));
        _;
    }

    function Sign() public {
        require (msg.sender == firstSignAddress || msg.sender == secondSignAddress);
        require (signed[msg.sender] == false);
        signed[msg.sender] = true;
    }

    function isApprover(address account) public view returns (bool) {
        return _approvers.has(account);
    }

    function addApprover(address account) public onlyApprover {
        require (signed[firstSignAddress] == true && signed[secondSignAddress] == true);
        _addApprover(account);
        
        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function removeApprover(address account) public onlyApprover {
        require (signed[firstSignAddress] == true && signed[secondSignAddress] == true);
        _removeApprover(account);
        
        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function renounceApprover() public {
        require (signed[firstSignAddress] == true && signed[secondSignAddress] == true);
        _removeApprover(msg.sender);
        
        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function _addApprover(address account) internal {
        _approvers.add(account);
        emit ApproverAdded(account);
    }

    function _removeApprover(address account) internal {
        _approvers.remove(account);
        emit ApproverRemoved(account);
    }
}

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract IERC20 {
    function totalSupply() public constant returns (uint256);

    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes data
    ) public;
}

contract ARGONToken is IERC20, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        symbol = "ARGON";
        name = "ArgonToken";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0x8CB5b6B0A475e760ed0610AD9cF8403Ec050bc8A] = _totalSupply;
        emit Transfer(
            address(0),
            0x8CB5b6B0A475e760ed0610AD9cF8403Ec050bc8A,
            _totalSupply
        );
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(
        address spender,
        uint256 tokens,
        bytes data
    ) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            tokens,
            this,
            data
        );
        return true;
    }

    function() public payable {
        revert();
    }
}

contract MainContract is ApproverRole {
    struct AccountData {
        uint256 accountType; // 0 => Freelancer, 1 => Approver, 2 => Customer
        string personNameSurname;
        address personWalletAddress;
        string personEmail;
        string personResume;
        string personGitHub;
        string personWorkSkills;
        string personLinkedin;
        uint256 personWorkCount;
        uint256[] personPuan; // Rate x/5
        address[] WorkAddresses; // All work addresses
        string personLocation;
        string personLang;
    }

    mapping(address => AccountData[]) accounts;
    mapping(address => bool) personsAddress;
    address[] public deployedWorks;
    address[] public allPersons;
    uint256 private result;
    IERC20 public ArgonToken =
        IERC20(0x851f7a700c5d67db59612b871338a85526752c25); // ArgonToken Contract Address
    address ArgonTokenDeployer = 0x8CB5b6B0A475e760ed0610AD9cF8403Ec050bc8A;
    uint256 public RemainingArgonToken = 5000000000000000000000000;
    uint public approverMinArgonLimit = 100000 * 10 ** 18;
    
    modifier isInAccounts() {
        require(personsAddress[msg.sender]);
        _;
    }
    
    function changeApproverMinArgonLimit(uint _value) public onlyApprover {
        require(msg.sender == ArgonTokenDeployer);
        approverMinArgonLimit = _value;
    }

    function sendArgonTokenDeployer(address _address, uint256 amount) public onlyApprover {
        require(msg.sender == ArgonTokenDeployer);
        ArgonToken.transfer(_address, amount);
    }

    function getAllPersons() public view returns (address[]) {
        return allPersons;
    }

    function addPerson(
        uint _accountType,
        string _personNameSurname,
        string _personEmail,
        string _personResume,
        string _personGitHub,
        string _personWorkSkills,
        string _personLinkedin,
        string _personLocation,
        string _personLang
    ) public {
        if(_accountType == 1) {
            require(ArgonToken.balanceOf(msg.sender) >= approverMinArgonLimit);
        }
        AccountData memory newAccount =
            AccountData({
                accountType: _accountType,
                personNameSurname: _personNameSurname,
                personWalletAddress: msg.sender,
                personEmail: _personEmail,
                personResume: _personResume,
                personGitHub: _personGitHub,
                personWorkSkills: _personWorkSkills,
                personLinkedin: _personLinkedin,
                personWorkCount: 0,
                personPuan: new uint256[](0),
                WorkAddresses: new address[](0),
                personLocation: _personLocation,
                personLang: _personLang
            });

        accounts[msg.sender].push(newAccount); // Adding a new account
        allPersons.push(msg.sender); // Adding a new account
        personsAddress[msg.sender] = true;
    }

    function getPersonInfoData(address _personAddress)
        public
        view
        returns (
            string,
            string,
            string,
            string,
            string
        )
    {
        AccountData storage data = accounts[_personAddress][0];
        return (
            data.personNameSurname,
            data.personEmail,
            data.personResume,
            data.personGitHub,
            data.personWorkSkills
        );
    }

    function getPersonOtherData(address _personAddress)
        public
        view
        returns (
            uint256,
            string,
            uint256,
            uint256[],
            address[],
            string,
            string
        )
    {
        AccountData storage data = accounts[_personAddress][0];
        return (
            data.accountType,
            data.personLinkedin,
            data.personWorkCount,
            data.personPuan,
            data.WorkAddresses,
            data.personLocation,
            data.personLang
        );
    }

    function getPersonWorks(address _personAddress)
        public
        view
        returns (address[])
    {
        AccountData storage data = accounts[_personAddress][0];

        return (data.WorkAddresses);
    }

    function updatePerson(
        uint256 _accountType,
        string _personNameSurname,
        string _personEmail,
        string _personResume,
        string _personGitHub,
        string _personWorkSkills,
        string _personLinkedin,
        string _personLocation,
        string _personLang
    ) public isInAccounts {
        AccountData storage data = accounts[msg.sender][0];
        data.accountType = _accountType;
        data.personNameSurname = _personNameSurname;
        data.personEmail = _personEmail;
        data.personResume = _personResume;
        data.personGitHub = _personGitHub;
        data.personWorkSkills = _personWorkSkills;
        data.personLinkedin = _personLinkedin;
        data.personLocation = _personLocation;
        data.personLang = _personLang;
    }

    function deleteAccount() public isInAccounts {
        delete accounts[msg.sender];
    }

    function createWork(
        string _workTitle,
        string _workCategory,
        string _workDescription,
        string _workAvarageBudget
    ) public {
        address newWork =
            new WorkContract(
                _workTitle,
                _workCategory,
                _workDescription,
                _workAvarageBudget,
                msg.sender,
                this
            );
        AccountData storage data = accounts[msg.sender][0];
        data.WorkAddresses.push(newWork); // Adding Person Works
        deployedWorks.push(newWork); // Adding All Works
    }

    function updateWork(
        string _workTitle,
        string _workCategory,
        string _workDescription,
        string _workAvarageBudget,
        uint256 _index
    ) public {
        AccountData storage data = accounts[msg.sender][0];
        WorkContract deployedWork;
        deployedWork = WorkContract(data.WorkAddresses[_index]);
        deployedWork.updateWork(
            _workTitle,
            _workCategory,
            _workDescription,
            _workAvarageBudget,
            data.WorkAddresses[_index]
        );
    }

    function cancelWork(address _workAddress) public {
        AccountData storage data = accounts[msg.sender][0];
        for (uint256 i = 0; i < data.WorkAddresses.length; i++) {
            if (data.WorkAddresses[i] == _workAddress) {
                delete data.WorkAddresses[i];
            }
        }
        for (uint256 j = 0; j < deployedWorks.length; j++) {
            if (deployedWorks[j] == _workAddress) {
                delete deployedWorks[j];
            }
        }
    }

    function getWorks() public view returns (address[]) {
        return deployedWorks;
    }

    function setPuan(uint256 _puan, address _freelancerAddress) public {
        for (uint256 i = 0; i < deployedWorks.length; i++) {
            if (msg.sender == deployedWorks[i]) {
                AccountData storage data = accounts[_freelancerAddress][0];
                data.personPuan.push(_puan);
            }
        }
    }

    function setApproverWorkAddress(
        address _workAddress,
        address _approveraddress
    ) public {
        for (uint256 i = 0; i < deployedWorks.length; i++) {
            if (msg.sender == deployedWorks[i]) {
                AccountData storage data = accounts[_approveraddress][0];
                data.WorkAddresses.push(_workAddress);
            }
        }
    }

    function deleteApproverWorkAddress(
        address _workAddress,
        address _approveraddress
    ) public {
        for (uint256 y = 0; y < deployedWorks.length; y++) {
            if (msg.sender == deployedWorks[y]) {
                AccountData storage data = accounts[_approveraddress][0];
                for (uint256 i = 0; i < data.WorkAddresses.length; i++) {
                    if (data.WorkAddresses[i] == _workAddress) {
                        delete data.WorkAddresses[i];
                    }
                }
            }
        }
    }

    function checkDeadline(address _workAddress)
        public
        view
        returns (bool, address)
    {
        WorkContract deployedWork;
        deployedWork = WorkContract(_workAddress);
        if (now > deployedWork.deadLine() && deployedWork.deadLine() != 0) {
            return (true, _workAddress);
        } else {
            return (false, _workAddress);
        }
    }

    function sendApproverArgonCoin(address _approveraddress) public onlyApprover{
        for (uint256 i = 0; i < deployedWorks.length; i++) {
            if (msg.sender == deployedWorks[i]) {
                uint256 amount = (RemainingArgonToken * 3) / 1000000;
                ArgonToken.transfer(_approveraddress, amount);
                RemainingArgonToken -= amount;
            }
        }
    }
}

contract WorkContract is ApproverRole {
    MainContract deployedFromContract;
    struct Offer {
        uint256 offerPrice;
        address freelancerAddress;
        string description;
        string title;
        uint256 deadline;
        address offerTokenContract;
        bool tokenContractIsBNB;
    }

    string public workTitle;
    string public workCategory;
    string public workDescription;
    uint256 public workCreateTime;
    string public workAvarageBudget;
    uint256 public workOfferCount;
    bool public workStatus;
    string public workFilesLink;
    uint256 public deadLine;
    bool public freelancerSendFiles;
    bool public isWorkFreelancer;
    bool public employerReceiveFiles;
    uint256 public freelancerSendFilesDate;
    address public employerAddress;
    address public freelancerAddress;
    string public employerCancelDescription;
    uint256 public workStartDate;
    uint256 public workEndDate;
    mapping(address => Offer[]) offers;
    address[] public allFreelancerAddress;
    address public approverAddress;
    uint256 public approverConfirmStatus;
    string public approverReport;
    bool public approverStatus;
    uint256 public workPrice;
    bool public isBNB;
    address public tokenContractAddress;
    IERC20 public ArgonToken =
        IERC20(0x851f7a700c5d67db59612b871338a85526752c25); // ***ArgonToken Contract***


    constructor(
        string _workTitle,
        string _workCategory,
        string _workDescription,
        string _workAvarageBudget,
        address _employerAddress,
        address _t
    ) public {
        workTitle = _workTitle;
        workCategory = _workCategory;
        workDescription = _workDescription;
        workCreateTime = now;
        workAvarageBudget = _workAvarageBudget;
        workOfferCount = 0;
        workStatus = false;
        employerAddress = _employerAddress;
        isWorkFreelancer = false;
        approverStatus = false;
        freelancerSendFiles = false;
        employerReceiveFiles = false;
        deployedFromContract = MainContract(_t);
    }

    function getAllFreelancers() public view returns (address[]) {
        return allFreelancerAddress;
    }

    function getWorkData()
        public
        view
        returns (
            string,
            string,
            string,
            uint256,
            string,
            uint256,
            bool,
            address
        )
    {
        return (
            workTitle,
            workCategory,
            workDescription,
            workCreateTime,
            workAvarageBudget,
            workOfferCount,
            workStatus,
            employerAddress
        );
    }

    function updateWork(
        string _workTitle,
        string _workCategory,
        string _workDescription,
        string _workAvarageBudget,
        address _workaddress
    ) public {
        require(this == _workaddress);
        require(msg.sender == employerAddress);
        workTitle = _workTitle;
        workCategory = _workCategory;
        workDescription = _workDescription;
        workAvarageBudget = _workAvarageBudget;
    }

    function createOffer(
        uint256 _offerPrice,
        string _description,
        uint256 _deadline,
        string _title,
        address _tokenContract,
        bool _isBNB
    ) public {
        Offer memory newOffer =
            Offer({
                offerPrice: _offerPrice,
                freelancerAddress: msg.sender,
                description: _description,
                deadline: _deadline,
                title: _title,
                offerTokenContract: _tokenContract,
                tokenContractIsBNB: _isBNB
            });
        offers[msg.sender].push(newOffer);
        allFreelancerAddress.push(msg.sender);
        workOfferCount++;
    }

    function deleteOffer() public {
        delete offers[msg.sender];
        workOfferCount--;
    }

    function updateOffer(
        uint256 _offerPrice,
        string _description,
        string _title,
        uint256 _index
    ) public {
        Offer storage data = offers[msg.sender][_index];
        data.offerPrice = _offerPrice;
        data.description = _description;
        data.title = _title;
    }

    function getOfferData(address _freelancerAddress, uint256 _index)
        public
        view
        returns (
            uint256,
            address,
            string,
            string,
            uint256,
            address,
            bool
        )
    {
        Offer storage data = offers[_freelancerAddress][_index];
        return (
            data.offerPrice,
            data.freelancerAddress,
            data.description,
            data.title,
            data.deadline,
            data.offerTokenContract,
            data.tokenContractIsBNB
        );
    }

    function selectOffer(
        address _freelancerAddress,
        uint256 _index,
        address _approveraddress
    ) public payable onlyApprover {
        require(ArgonToken.balanceOf(_approveraddress) >= deployedFromContract.approverMinArgonLimit());
        require(msg.sender == employerAddress);
        Offer storage data = offers[_freelancerAddress][_index];
        require(msg.value >= data.offerPrice);
        freelancerAddress = data.freelancerAddress;
        workStatus = true;
        workStartDate = now;
        deadLine = data.deadline;
        isWorkFreelancer = true;
        workPrice = data.offerPrice;
        approverAddress = _approveraddress;
        approverStatus = true;
        isBNB = true;
    }
    
    function selectOfferWithToken(
        address _freelancerAddress,
        uint256 _index,
        address _approveraddress
    ) public onlyApprover {
        require(ArgonToken.balanceOf(_approveraddress) >= deployedFromContract.approverMinArgonLimit());
        require(msg.sender == employerAddress);
        Offer storage data = offers[_freelancerAddress][_index];
        require(IERC20(data.offerTokenContract).allowance(msg.sender, address(this)) >= data.offerPrice);
        require(IERC20(data.offerTokenContract).balanceOf(msg.sender) >= data.offerPrice);
        freelancerAddress = data.freelancerAddress;
        workStatus = true;
        workStartDate = now;
        deadLine = data.deadline;
        isWorkFreelancer = true;
        workPrice = data.offerPrice;
        approverAddress = _approveraddress;
        approverStatus = true;
        isBNB = false;
        tokenContractAddress = data.offerTokenContract;
        IERC20(data.offerTokenContract).transferFrom(msg.sender, address(this), data.offerPrice);
    }

    function freelancerSendFile(string _workFilesLink) public {
        require(msg.sender == freelancerAddress);
        freelancerSendFiles = true;
        workFilesLink = _workFilesLink;
        freelancerSendFilesDate = now;
    }

    function employerReceiveFile(uint256 _puan) public onlyApprover {
        require(msg.sender == employerAddress);
        if (isBNB) {
        freelancerAddress.transfer(workPrice);
        } else {
            IERC20(tokenContractAddress).transfer(freelancerAddress, workPrice);
        }
        deployedFromContract.setPuan(_puan, freelancerAddress);
        workEndDate = now;
    }

    function employerCancel(string _depscription) public {
        require(msg.sender == employerAddress);
        approverConfirmStatus = 0;
        employerCancelDescription = _depscription;
        deployedFromContract.setApproverWorkAddress(this, approverAddress);
    }

    function confirmApprover(string _description) public onlyApprover {
        require(ArgonToken.balanceOf(msg.sender) >= deployedFromContract.approverMinArgonLimit());
        require(msg.sender == approverAddress);
        require(approverConfirmStatus == 0);
        approverConfirmStatus = 1;
        if(isBNB) {
        freelancerAddress.transfer(workPrice);
        } else {
            IERC20(tokenContractAddress).transfer(freelancerAddress, workPrice);
        }
        deployedFromContract.deleteApproverWorkAddress(this, approverAddress);
        approverReport = _description;
        workEndDate = now;
        deployedFromContract.sendApproverArgonCoin(approverAddress);
    }

    function cancelApprover(string _description) public onlyApprover {
        require(ArgonToken.balanceOf(msg.sender) >= deployedFromContract.approverMinArgonLimit());
        require(msg.sender == approverAddress);
        require(approverConfirmStatus == 0);
        approverConfirmStatus = 2;
        if (isBNB) {
        employerAddress.transfer(workPrice);
        } else {
            IERC20(tokenContractAddress).transfer(employerAddress, workPrice);
        }
        deployedFromContract.deleteApproverWorkAddress(this, approverAddress);
        approverReport = _description;
        deployedFromContract.sendApproverArgonCoin(approverAddress);
    }

    function sendDeadline() public onlyApprover {
        require(now > deadLine);
        if(isBNB) {
            employerAddress.transfer(workPrice);
        } else {
            IERC20(tokenContractAddress).transfer(employerAddress, workPrice);
        }
    }
}