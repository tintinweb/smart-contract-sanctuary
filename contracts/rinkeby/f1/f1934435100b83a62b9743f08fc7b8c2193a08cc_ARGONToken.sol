/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.4.17;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract ApproverRole {
    using Roles for Roles.Role;

    event ApproverAdded(address indexed account);
    event ApproverRemoved(address indexed account);

    Roles.Role private _approvers;

    constructor () internal {
        _addApprover(msg.sender);
    }

    modifier onlyApprover() {
        require(isApprover(msg.sender), "ApproverRole: caller does not have the Approver role");
        _;
    }

    function isApprover(address account) public view returns (bool) {
        return _approvers.has(account);
    }

    function addApprover(address account) public onlyApprover {
        _addApprover(account);
    }

    function removeApprover(address account) public onlyApprover {
        _removeApprover(account);
    }

    function renounceApprover() public {
        _removeApprover(msg.sender);
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

    constructor () {
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

/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
*/
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

/**
Contract function to receive approval and execute function in one call
Borrowed from MiniMeToken
*/
contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes data
    ) public;
}

/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract ARGONToken is IERC20, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
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

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
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

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
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

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function() public payable {
        revert();
    }
}

contract MainContract is ApproverRole, ReentrancyGuard {
    // Variable Definations
    struct AccountData {
        uint256 accountType; // 0 => Freelancer, 1 => Approver, 2 => Customer
        string personNameSurname;
        address personWalletAddress;
        string personEmail;
        string personPhoneNumber;
        string personResume;
        string personGitHub;
        string personPortfoyLink;
        string personWorkSkills;
        string personLinkedin;
        uint256 personWorkCount;
        uint256[] personPuan; // Rate x/5
        address[] WorkAddresses; // All work addresses
        string personLocation;
        string personLang;
        address[] personFavWorks; // Only Freelancer Favorite Works
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
    // ---- END ---- Variable Definations
    uint public approverMinArgonLimit = 100000 * 10 ** 18;
    
    event ChangeApproverMinArgonLimit(address indexed user, uint _approverMinArgonLimit);
    event SendArgonTokenDeployer(address _address, uint256 amount);

    modifier isInAccounts() {
        require(personsAddress[msg.sender]);
        _;
    }
    
    function changeApproverMinArgonLimit(uint _value) public onlyApprover {
        require(msg.sender == ArgonTokenDeployer, "Message sender should be token deployer.");
        approverMinArgonLimit = _value;
        
        emit ChangeApproverMinArgonLimit(msg.sender, approverMinArgonLimit);
    }

    // Sending ArgonToken To Deployer Address
    function sendArgonTokenDeployer(address _address, uint256 amount) public onlyApprover {
        require(msg.sender == ArgonTokenDeployer, "Message sender should be token deployer.");
        ArgonToken.transfer(_address, amount);
        
        emit SendArgonTokenDeployer(_address, amount);
    }

    // Get Person Addresses
    function getAllPersons() public view returns (address[]) {
        return allPersons;
    }

    // Add Person
    function addPerson(
        uint256 _accountType,
        string _personNameSurname,
        string _personEmail,
        string _personPhoneNumber,
        string _personResume,
        string _personGitHub,
        string _personPortfoyLink,
        string _personWorkSkills,
        string _personLinkedin,
        string _personLocation,
        string _personLang
    ) public {
        if(_accountType == 1) {
            require(ArgonToken.balanceOf(msg.sender) >= approverMinArgonLimit, "Incorrect Token balance!");
        }
        AccountData memory newAccount =
            AccountData({
                accountType: _accountType,
                personNameSurname: _personNameSurname,
                personWalletAddress: msg.sender,
                personEmail: _personEmail,
                personPhoneNumber: _personPhoneNumber,
                personResume: _personResume,
                personGitHub: _personGitHub,
                personPortfoyLink: _personPortfoyLink,
                personWorkSkills: _personWorkSkills,
                personLinkedin: _personLinkedin,
                personWorkCount: 0,
                personPuan: new uint256[](0),
                WorkAddresses: new address[](0),
                personLocation: _personLocation,
                personLang: _personLang,
                personFavWorks: new address[](0)
            });

        accounts[msg.sender].push(newAccount); // Adding a new account
        allPersons.push(msg.sender); // Adding a new account
        personsAddress[msg.sender] = true;
    }

    // Get person info data
    function getPersonInfoData(address _personAddress)
        public
        view
        returns (
            string,
            string,
            string,
            string,
            string,
            string,
            string
        )
    {
        AccountData storage data = accounts[_personAddress][0];
        /*
        string personNameSurname;
        string personEmail;
        string personPhoneNumber;
        string personResume;
        string personGitHub;
        string personPortfoyLink;
        string personWorkSkills;
        */

        return (
            data.personNameSurname,
            data.personEmail,
            data.personPhoneNumber,
            data.personResume,
            data.personGitHub,
            data.personPortfoyLink,
            data.personWorkSkills
        );
    }

    // Person Puan Only Freelancer
    function getPersonPuan(address _personAddress)
        public
        view
        returns (uint256)
    {
        AccountData memory data = accounts[_personAddress][0];
        result = 0;
        if (data.personPuan.length != 0) {
            for (uint256 i = 0; i < data.personPuan.length; i++) {
                result += data.personPuan[i];
            }
            result = (result * 100) / (data.personPuan.length); // JS => x/1000
        }
        return result;
    }

    // Person other data
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
            string,
            address[]
        )
    {
        AccountData storage data = accounts[_personAddress][0];
        /* 
        uint accountType;
        string personLinkedin;
        uint personWorkCount;
        uint personPuan;
        string WorkAddresses; 
        string personLocation;
        string personLang;
        address[] personFavWorks;
        */
        return (
            data.accountType,
            data.personLinkedin,
            data.personWorkCount,
            data.personPuan,
            data.WorkAddresses,
            data.personLocation,
            data.personLang,
            data.personFavWorks
        );
    }

    // Get person all works from _personAddress
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
        string _personPhoneNumber,
        string _personResume,
        string _personGitHub,
        string _personPortfoyLink,
        string _personWorkSkills,
        string _personLinkedin,
        string _personLocation,
        string _personLang
    ) public isInAccounts {
        AccountData storage data = accounts[msg.sender][0];
        data.accountType = _accountType;
        data.personNameSurname = _personNameSurname;
        data.personEmail = _personEmail;
        data.personPhoneNumber = _personPhoneNumber;
        data.personResume = _personResume;
        data.personGitHub = _personGitHub;
        data.personPortfoyLink = _personPortfoyLink;
        data.personWorkSkills = _personWorkSkills;
        data.personLinkedin = _personLinkedin;
        data.personLocation = _personLocation;
        data.personLang = _personLang;
    }

    function deleteAccount() public isInAccounts {
        delete accounts[msg.sender];
    }

    function selectFavouriteWork(address _workAddress) public isInAccounts {
        AccountData storage data = accounts[msg.sender][0];
        data.personFavWorks.push(_workAddress);
    }

    function getFavouriteWork(address _personAddress)
        public
        view
        returns (address[])
    {
        AccountData storage data = accounts[_personAddress][0];
        return data.personFavWorks;
    }

    function deleteFavouriteWork(uint256 _index) public isInAccounts {
        AccountData storage data = accounts[msg.sender][0];
        delete data.personFavWorks[_index];
    }

    // Creating A Work Contract
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

    // Delete Work
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

    // Set Puan,
    // If the transfer was made from the contract address
    function setPuan(uint256 _puan, address _freelancerAddress) public {
        for (uint256 i = 0; i < deployedWorks.length; i++) {
            if (msg.sender == deployedWorks[i]) {
                AccountData storage data = accounts[_freelancerAddress][0];
                data.personPuan.push(_puan);
            }
        }
    }

    // Add Approver Work Address
    // If the transfer was made from the contract address
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

    function sendApproverArgonCoin(address _approveraddress) public onlyApprover nonReentrant returns (uint256){
        for (uint256 i = 0; i < deployedWorks.length; i++) {
            if (msg.sender == deployedWorks[i]) {
                uint256 amount = (RemainingArgonToken * 3) / 1000000;
                ArgonToken.transfer(_approveraddress, amount);
                RemainingArgonToken -= amount;
            }
        }
        
        return 2;
    }
}

contract WorkContract is ApproverRole, ReentrancyGuard {
    MainContract deployedFromContract;
    struct Offer {
        uint256 offerPrice;
        address freelancerAddress;
        bool isArgonShield;
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
        require(_employerAddress != address(0), "employerAddress's address must not be address(0)");
        require(_t != address(0), "deployedFromContract contract's address must not be address(0)");

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
        require(this == _workaddress, "Incorrect workaddress!");
        require(msg.sender == employerAddress, "Incorrect employerAddress!");
        workTitle = _workTitle;
        workCategory = _workCategory;
        workDescription = _workDescription;
        workAvarageBudget = _workAvarageBudget;
    }

    function createOffer(
        uint256 _offerPrice,
        bool _isArgonShield,
        string _description,
        uint256 _deadline,
        string _title,
        address _tokenContract,
        bool _isBNB
    ) public nonReentrant returns (uint256) {
        Offer memory newOffer =
            Offer({
                offerPrice: _offerPrice,
                freelancerAddress: msg.sender,
                isArgonShield: _isArgonShield,
                description: _description,
                deadline: _deadline,
                title: _title,
                offerTokenContract: _tokenContract,
                tokenContractIsBNB: _isBNB
            });
        offers[msg.sender].push(newOffer);
        allFreelancerAddress.push(msg.sender);
        workOfferCount++;
        
        return 2;
    }

    function deleteOffer() public nonReentrant returns (uint256) {
        delete offers[msg.sender];
        workOfferCount--;
        
        return 2;
    }

    function updateOffer(
        uint256 _offerPrice,
        bool _isArgonShield,
        string _description,
        string _title,
        uint256 _index
    ) public nonReentrant returns (uint256) {
        Offer storage data = offers[msg.sender][_index];
        data.offerPrice = _offerPrice;
        data.isArgonShield = _isArgonShield;
        data.description = _description;
        data.title = _title;
        
        return 2;
    }

    function getOfferData(address _freelancerAddress, uint256 _index)
        public
        view
        returns (
            uint256,
            address,
            bool,
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
            data.isArgonShield,
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
        require(ArgonToken.balanceOf(_approveraddress) >= deployedFromContract.approverMinArgonLimit(), "Incorrect Token balance!");
        require(msg.sender == employerAddress, "Incorrect employerAddress!");
        Offer storage data = offers[_freelancerAddress][_index];
        require(msg.value >= data.offerPrice, "Value should be bigger than offer price!");
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
        require(ArgonToken.balanceOf(_approveraddress) >= deployedFromContract.approverMinArgonLimit(), "Incorrect Token balance!");
        require(msg.sender == employerAddress, "Incorrect employerAddress!");
        Offer storage data = offers[_freelancerAddress][_index];
        require(IERC20(data.offerTokenContract).allowance(msg.sender, address(this)) >= data.offerPrice, "Value should be bigger than offer price!");
        require(IERC20(data.offerTokenContract).balanceOf(msg.sender) >= data.offerPrice, "Value should be bigger than offer price!");
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
        require(msg.sender == freelancerAddress, "Incorrect freelancerAddress!");
        freelancerSendFiles = true;
        workFilesLink = _workFilesLink;
        freelancerSendFilesDate = now;
    }

    function employerReceiveFile(uint256 _puan) public onlyApprover {
        require(msg.sender == employerAddress, "Incorrect employerAddress!");
        if (isBNB) {
        freelancerAddress.transfer(workPrice);
        } else {
            IERC20(tokenContractAddress).transfer(freelancerAddress, workPrice);
        }
        deployedFromContract.setPuan(_puan, freelancerAddress);
        workEndDate = now;
    }

    function employerCancel(string _depscription) public {
        require(msg.sender == employerAddress, "Incorrect employerAddress!");
        approverConfirmStatus = 0;
        employerCancelDescription = _depscription;
        deployedFromContract.setApproverWorkAddress(this, approverAddress);
    }

    function confirmApprover(string _description) public onlyApprover {
        require(ArgonToken.balanceOf(msg.sender) >= deployedFromContract.approverMinArgonLimit(), "Incorrect Token balance!");
        require(msg.sender == approverAddress, "User should be approvee address!");
        require(approverConfirmStatus == 0, "ApproverConfirmStatus should be 0!");
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
        require(ArgonToken.balanceOf(msg.sender) >= deployedFromContract.approverMinArgonLimit(), "Incorrect Token balance!");
        require(msg.sender == approverAddress, "User should be approvee address!");
        require(approverConfirmStatus == 0, "ApproverConfirmStatus should be 0!");
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

    function sendDeadline() public onlyApprover nonReentrant returns (uint256) {
        require(now > deadLine, "Before deadLine now!");
        if(isBNB) {
            employerAddress.transfer(workPrice);
        } else {
            IERC20(tokenContractAddress).transfer(employerAddress, workPrice);
        }
        
        return 2;
    }
}