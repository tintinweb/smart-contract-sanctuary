pragma solidity ^0.4.24;

import './SafeMath.sol';


library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account));
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account));
        role.bearer[account] = false;
    }

    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
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

    constructor() internal {
        _addApprover(msg.sender);

        firstSignAddress = 0x838F5de74f7aCEad668366b97b08Dd1dd2f86dEc; // You should change this address to your first sign address
        secondSignAddress = 0x838F5de74f7aCEad668366b97b08Dd1dd2f86dEc; // You should change this address to your second sign address
    }

    modifier onlyApprover() {
        require(isApprover(msg.sender));
        _;
    }

    function sign() external {
        require(
            msg.sender == firstSignAddress || msg.sender == secondSignAddress
        );
        require(!signed[msg.sender]);
        signed[msg.sender] = true;
    }

    function isApprover(address account) public view returns (bool) {
        return _approvers.has(account);
    }

    function addApprover(address account) external onlyApprover {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
        _addApprover(account);

        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function removeApprover(address account) external onlyApprover {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
        _removeApprover(account);

        signed[firstSignAddress] = false;
        signed[secondSignAddress] = false;
    }

    function renounceApprover() external {
        require(signed[firstSignAddress] && signed[secondSignAddress]);
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


interface IERC20 {
    function totalSupply() external constant returns (uint256);

    function balanceOf(address tokenOwner)
        external
        constant
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        constant
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract MainContract is ApproverRole, ReentrancyGuard {
    using SafeMath for uint256;
    struct AccountData {
        uint8 accountType; // 0 => Freelancer, 1 => Approver, 2 => Customer
        address personWalletAddress;
        uint256 personWorkCount;
        uint256[] personPuan; // Rate x/5
        address[] WorkAddresses; // All work addresses
        string personInfoData;
    }

    mapping(address => AccountData) accounts;
    mapping(address => bool) personsAddress;
    mapping(address => uint256) public feeRates;
    mapping(address => bool) public availableTokens;
    mapping(address => uint256) public approverLockBalances;
    mapping(address => bool) public isDeployedWorks;

    uint256 public bnbFeeRate;
    uint256 public remainingArgonToken;
    uint256 public approverMinArgonLimit;
    address[] public deployedWorks;
    address[] public allPersons;
    address public feeAddress;
    address public argonTokenContractAddress;
    bool public isActive;
    IERC20 public argonToken; // ArgonToken Contract Address

    modifier isInAccounts() {
        require(personsAddress[msg.sender]);
        _;
    }

    modifier mustApprover() {
        require(personsAddress[msg.sender]);
        AccountData storage data = accounts[msg.sender];
        require(data.accountType == 1);
        _;
    }

    modifier mustActive() {
        require(isActive);
        _;
    }

    constructor(
        address _argonTokenAddress,
        uint256 _bnbFeeRate,
        address _feeAddress
    ) public {
        argonToken = IERC20(_argonTokenAddress);
        bnbFeeRate = _bnbFeeRate;
        remainingArgonToken = 5e6 ether;
        approverMinArgonLimit = 20000 * 10**18;
        feeAddress = _feeAddress;
        argonTokenContractAddress = _argonTokenAddress;
    }

    function changeActive(bool _active) external onlyApprover {
        isActive = _active;
    }

    function changeAvailableTokenFee(
        address _tokenAddress,
        uint256 _feeRate,
        bool _available
    ) external onlyApprover {
        feeRates[_tokenAddress] = _feeRate;
        availableTokens[_tokenAddress] = _available;
    }

    function changeSettings(
        uint256 _approverMinArgonLimit,
        uint256 _bnbFeeRate,
        address _feeAddress
    ) external onlyApprover {
        approverMinArgonLimit = _approverMinArgonLimit;
        bnbFeeRate = _bnbFeeRate;
        feeAddress = _feeAddress;
    }

    function sendArgonTokenAdmin(address _address, uint256 amount)
        external
        onlyApprover
        nonReentrant
    {
        argonToken.transfer(_address, amount);
    }

    function unLock() external mustApprover nonReentrant {
        require(approverLockBalances[msg.sender] > 0);
        AccountData storage data = accounts[msg.sender];
        require(data.WorkAddresses.length == 0);
        delete accounts[msg.sender];
        personsAddress[msg.sender] = false;
        for (uint256 x = 0; x < allPersons.length; x++) {
            if (allPersons[x] == msg.sender) {
                delete allPersons[x];
            }
        }
        argonToken.transfer(msg.sender, approverLockBalances[msg.sender]);
        approverLockBalances[msg.sender] = 0;
    }

    function getAllPersons() external view returns (address[]) {
        return allPersons;
    }

    function addPerson(uint8 _accountType, string _personInfoData)
        external
        mustActive
        nonReentrant
    {
        if (_accountType == 1) {
            approverLockBalances[msg.sender] = approverLockBalances[msg.sender]
                .safeAdd(approverMinArgonLimit);
            require(
                argonToken.transferFrom(
                    msg.sender,
                    address(this),
                    approverMinArgonLimit
                )
            );
        }
        require(!personsAddress[msg.sender]);
        AccountData memory newAccount =
            AccountData({
                accountType: _accountType,
                personWalletAddress: msg.sender,
                personWorkCount: 0,
                personPuan: new uint256[](0),
                WorkAddresses: new address[](0),
                personInfoData: _personInfoData
            });

        accounts[msg.sender] = newAccount; // Adding a new account
        allPersons.push(msg.sender); // Adding a new account
        personsAddress[msg.sender] = true;
    }

    function getPersonInfoData(address _personAddress)
        external
        view
        returns (
            uint8,
            uint256,
            uint256[],
            address[],
            string
        )
    {
        AccountData storage data = accounts[_personAddress];
        return (
            data.accountType,
            data.personWorkCount,
            data.personPuan,
            data.WorkAddresses,
            data.personInfoData
        );
    }

    function getPersonAccountType(address _personAddress)
        public
        view
        returns (uint8)
    {
        AccountData storage data = accounts[_personAddress];
        return data.accountType;
    }

    function updatePerson(string _personInfoData)
        external
        isInAccounts
        mustActive
    {
        AccountData storage data = accounts[msg.sender];
        data.personInfoData = _personInfoData;
    }

    // function createWork(
    //     string _workTitle,
    //     string _workCategory,
    //     string _workDescription,
    //     string _workAvarageBudget
    // ) external mustActive {
    //     AccountData storage data = accounts[msg.sender];
    //     require(getPersonAccountType(msg.sender) == 2);
    //     address newWork =
    //         new WorkContract(
    //             _workTitle,
    //             _workCategory,
    //             _workDescription,
    //             _workAvarageBudget,
    //             msg.sender,
    //             address(this)
    //         );
    //     data.WorkAddresses.push(newWork); // Adding Person Works
    //     deployedWorks.push(newWork); // Adding All Works
    //     isDeployedWorks[newWork] = true;
    // }

    function getWorks() external view returns (address[]) {
        return deployedWorks;
    }

    function setPuan(uint256 _puan, address _freelancerAddress) external {
        require(isDeployedWorks[msg.sender]);
        AccountData storage data = accounts[_freelancerAddress];
        data.personPuan.push(_puan);
    }

    function setApproverWorkAddress(
        address _workAddress,
        address _approveraddress
    ) external {
        require(isDeployedWorks[msg.sender]);

        AccountData storage data = accounts[_approveraddress];
        data.WorkAddresses.push(_workAddress);
    }

    function setFreelancerWorkAddress(
        address _workAddress,
        address _freelanceraddress
    ) external {
        require(isDeployedWorks[msg.sender]);

        AccountData storage data = accounts[_freelanceraddress];
        data.WorkAddresses.push(_workAddress);
    }

    function _removeApproverWorkAddressArray(
        uint256 index,
        address _approveraddress
    ) private {
        AccountData storage data = accounts[_approveraddress];

        if (index >= data.WorkAddresses.length) return;

        for (uint256 i = index; i < data.WorkAddresses.length - 1; i++) {
            data.WorkAddresses[i] = data.WorkAddresses[i + 1];
        }
        delete data.WorkAddresses[data.WorkAddresses.length - 1];
        data.WorkAddresses.length--;
    }

    function deleteApproverWorkAddress(
        address _workAddress,
        address _approveraddress
    ) external {
        require(isDeployedWorks[msg.sender]);

        AccountData storage data = accounts[_approveraddress];
        for (uint256 i = 0; i < data.WorkAddresses.length; i++) {
            if (data.WorkAddresses[i] == _workAddress) {
                _removeApproverWorkAddressArray(i, _approveraddress);
            }
        }
    }

    function checkDeadline(address _workAddress)
        external
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

    function sendApproverArgonCoin(address _approveraddress) external {
        require(isDeployedWorks[msg.sender]);

        uint256 amount = (remainingArgonToken.safeMul(3)).safeDiv(1e5);
        argonToken.transfer(_approveraddress, amount);
        remainingArgonToken = remainingArgonToken.safeSub(amount);
    }
}

contract WorkContract is ApproverRole, ReentrancyGuard {
    using SafeMath for uint256;

    MainContract deployedFromContract;
    struct Offer {
        uint256 offerPrice;
        address freelancerAddress;
        string description;
        string title;
        uint256 deadline;
        address offerTokenContract;
        bool tokenContractIsBNB;
        bool ArgonShield;
    }

    string public workTitle;
    string public workCategory;
    string public workDescription;
    string public workAvarageBudget;
    string public workFilesLink;
    string public employerCancelDescription;
    string public approverReport;
    string public employerRemark;

    uint256 public workCreateTime;
    uint256 public deadLine;
    uint256 public freelancerSendFilesDate;
    uint256 public workStartDate;
    uint256 public workEndDate;
    uint256 public approverConfirmStatus;
    uint256 public approverStartDate;
    uint256 public workPrice;
    uint256 public workOfferCount;

    bool public workStatus;
    bool public isBNB;
    bool public argonShield;
    bool public freelancerSendFiles;
    bool public employerReceiveFiles;

    address public employerAddress;
    address public approverAddress;
    address public tokenContractAddress;
    address public freelancerAddress;
    address[] public allFreelancerAddress;

    IERC20 public argonToken; // ***ArgonToken Contract***
    mapping(address => Offer) offers;

    modifier mustActive() {
        require(deployedFromContract.isActive());
        _;
    }

    modifier requireForApprover() {
        require(approverConfirmStatus == 0 && approverStartDate > 0);
        require(argonShield);
        _;
    }

    constructor(
        string _workTitle,
        string _workCategory,
        string _workDescription,
        string _workAvarageBudget,
        address _employerAddress,
        address _t
    ) public {
        require(MainContract(_t).isActive());
        require(MainContract(_t).getPersonAccountType(_employerAddress) == 2);
        workTitle = _workTitle;
        workCategory = _workCategory;
        workDescription = _workDescription;
        workCreateTime = now;
        workAvarageBudget = _workAvarageBudget;
        workOfferCount = 0;
        workStatus = false;
        employerAddress = _employerAddress;
        freelancerSendFiles = false;
        employerReceiveFiles = false;
        deployedFromContract = MainContract(_t);
        argonToken = IERC20(MainContract(_t).argonTokenContractAddress());
    }

    function getWorkData()
        external
        view
        returns (
            string,
            string,
            uint256,
            string,
            uint256,
            bool
        )
    {
        return (
            workTitle,
            workDescription,
            workCreateTime,
            workAvarageBudget,
            workOfferCount,
            workStatus
        );
    }

    function getAllFreelancers() external view returns (address[]) {
        return allFreelancerAddress;
    }

    function updateWork(
        string _workTitle,
        string _workCategory,
        string _workDescription,
        string _workAvarageBudget,
        address _workaddress
    ) external mustActive {
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
        bool _isBNB,
        bool _ArgonShield
    ) external mustActive {
        require(deployedFromContract.getPersonAccountType(msg.sender) == 0);
        if (!_isBNB) {
            require(_tokenContract != address(0));
            require(deployedFromContract.availableTokens(_tokenContract));
        }
        Offer memory newOffer =
            Offer({
                offerPrice: _offerPrice,
                freelancerAddress: msg.sender,
                description: _description,
                deadline: _deadline,
                title: _title,
                offerTokenContract: _tokenContract,
                tokenContractIsBNB: _isBNB,
                ArgonShield: _ArgonShield
            });
        offers[msg.sender] = newOffer;
        allFreelancerAddress.push(msg.sender);
        workOfferCount++;
    }

    function deleteOffer() external mustActive {
        delete offers[msg.sender];
        workOfferCount--;
    }

    function updateOffer(
        uint256 _offerPrice,
        string _description,
        string _title,
        bool _ArgonShield
    ) external mustActive {
        Offer storage data = offers[msg.sender];
        data.offerPrice = _offerPrice;
        data.description = _description;
        data.title = _title;
        data.ArgonShield = _ArgonShield;
    }

    function getOfferData(address _freelancerAddress)
        external
        view
        returns (
            uint256,
            address,
            string,
            string,
            uint256,
            address,
            bool,
            bool
        )
    {
        Offer storage data = offers[_freelancerAddress];
        return (
            data.offerPrice,
            data.freelancerAddress,
            data.description,
            data.title,
            data.deadline,
            data.offerTokenContract,
            data.tokenContractIsBNB,
            data.ArgonShield
        );
    }

    function selectOffer(address _freelancerAddress, address _approveraddress)
        external
        payable
        mustActive
    {
        require(msg.sender == employerAddress);
        Offer storage data = offers[_freelancerAddress];
        require(data.tokenContractIsBNB);
        deployedFromContract.setFreelancerWorkAddress(this, _freelancerAddress);
        if (data.ArgonShield) {
            require(
                deployedFromContract.approverLockBalances(_approveraddress) >=
                    deployedFromContract.approverMinArgonLimit()
            );
            approverAddress = _approveraddress;
            deployedFromContract.setApproverWorkAddress(this, _approveraddress);
        }

        require(msg.value >= data.offerPrice);
        freelancerAddress = data.freelancerAddress;
        workStatus = true;
        workStartDate = now;
        deadLine = data.deadline;
        workPrice = data.offerPrice;
        isBNB = true;
        argonShield = data.ArgonShield;
    }

    function selectOfferWithToken(
        address _freelancerAddress,
        address _approveraddress
    ) external mustActive {
        require(msg.sender == employerAddress);
        Offer storage data = offers[_freelancerAddress];
        require(!data.tokenContractIsBNB);
        deployedFromContract.setFreelancerWorkAddress(this, _freelancerAddress);
        if (data.ArgonShield) {
            require(
                deployedFromContract.approverLockBalances(_approveraddress) >=
                    deployedFromContract.approverMinArgonLimit()
            );

            approverAddress = _approveraddress;
            deployedFromContract.setApproverWorkAddress(this, _approveraddress);
        }
        freelancerAddress = data.freelancerAddress;
        workStatus = true;
        workStartDate = now;
        deadLine = data.deadline;
        workPrice = data.offerPrice;
        isBNB = false;
        tokenContractAddress = data.offerTokenContract;
        require(
            IERC20(data.offerTokenContract).transferFrom(
                msg.sender,
                address(this),
                data.offerPrice
            )
        );
        argonShield = data.ArgonShield;
    }

    function freelancerSendFile(string _workFilesLink) external {
        require(msg.sender == freelancerAddress);
        require(!freelancerSendFiles);
        freelancerSendFiles = true;
        workFilesLink = _workFilesLink;
        freelancerSendFilesDate = now;
    }

    function _payFreelancer() private {
        uint256 amount;

        if (isBNB) {
            amount = workPrice.safeSub(
                (workPrice.safeMul(deployedFromContract.bnbFeeRate())).safeDiv(
                    1e6
                )
            );
            freelancerAddress.transfer(amount);
            deployedFromContract.feeAddress().transfer(
                workPrice.safeSub(amount)
            );
        } else {
            amount = workPrice.safeSub(
                (
                    workPrice.safeMul(
                        deployedFromContract.feeRates(tokenContractAddress)
                    )
                )
                    .safeDiv(1e6)
            );

            IERC20(tokenContractAddress).transfer(freelancerAddress, amount);
            IERC20(tokenContractAddress).transfer(
                deployedFromContract.feeAddress(),
                workPrice.safeSub(amount)
            );
        }
    }

    function _payEmployer() private {
        if (isBNB) {
            employerAddress.transfer(workPrice);
        } else {
            IERC20(tokenContractAddress).transfer(employerAddress, workPrice);
        }
    }

    function employerReceiveFile(uint256 _puan, string _remark)
        external
        nonReentrant
    {
        require(msg.sender == employerAddress);
        require(freelancerSendFiles, "freelancer must be sent files");
        require(!employerReceiveFiles);
        _payFreelancer();
        deployedFromContract.setPuan(_puan, freelancerAddress);
        employerRemark = _remark;
        employerReceiveFiles = true;
        workEndDate = now;
    }

    function employerCancel(string _depscription) external {
        require(msg.sender == employerAddress);
        require(argonShield);
        require(approverStartDate == 0);
        require(!employerReceiveFiles);
        require(freelancerSendFiles, "freelancer must be sent files");

        approverConfirmStatus = 0;
        employerCancelDescription = _depscription;
        approverStartDate = now;
    }

    function confirmApprover(string _description)
        external
        nonReentrant
        requireForApprover
    {
        if (now > approverStartDate.safeAdd(5 days)) {
            require(isApprover(msg.sender));
        } else {
            require(msg.sender == approverAddress);

            deployedFromContract.deleteApproverWorkAddress(
                this,
                approverAddress
            );

            deployedFromContract.sendApproverArgonCoin(approverAddress);
        }

        approverConfirmStatus = 1;
        _payFreelancer();
        approverReport = _description;
        workEndDate = now;
    }

    function cancelApprover(string _description)
        external
        nonReentrant
        requireForApprover
    {
        if (now > approverStartDate.safeAdd(5 days)) {
            require(isApprover(msg.sender));
        } else {
            require(msg.sender == approverAddress);
            deployedFromContract.deleteApproverWorkAddress(
                this,
                approverAddress
            );
            deployedFromContract.sendApproverArgonCoin(approverAddress);
        }
        approverConfirmStatus = 2;
        approverReport = _description;
        _payEmployer();
    }

    function autoConfirm() external nonReentrant {
        require(now > freelancerSendFilesDate.safeAdd(5 days));
        require(!employerReceiveFiles);
        require(freelancerSendFiles);
        _payFreelancer();
        deployedFromContract.setPuan(5, freelancerAddress);
        employerRemark = "Auto Confirmed By Smart Contract";
        workEndDate = now;
    }

    function sendDeadline() external nonReentrant {
        require(now > deadLine);
        require(!freelancerSendFiles);
        _payEmployer();
    }
}

pragma solidity ^0.4.24;

library SafeMath {
    function safeAdd(uint256 a, uint256 b) external pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) external pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) external pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) external pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

