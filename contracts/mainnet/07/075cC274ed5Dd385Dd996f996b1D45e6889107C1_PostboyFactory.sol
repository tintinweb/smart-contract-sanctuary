contract PostboyRejectSetting {
   
    address public adminAddress;

    uint256 public minTimeForReject;
    bool public isRejectEnabled;

    modifier isAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    constructor() public {
        adminAddress = msg.sender;
        minTimeForReject = 0;
        isRejectEnabled = false;
    }

    function changeRejectSetting(uint256 rejectTime, bool isEnabled) isAdmin public {
        minTimeForReject = rejectTime;
        isRejectEnabled = isEnabled;
    }
}
contract PostboyAccount {

    struct Mail {
        bytes16 mailText;
        bytes16 responseText;
        uint256 paySum;
        bool isPublic;
        bool isRead;
        address sender;
        bool hasLike;
        bool isDislike;
        bool isRejected;
        uint256 createdTime;
    }

    Mail[] public mails;
    uint256[] public withdraws;

    address public owner;
    address public donateWallet;
    address public serviceWallet;
    PostboyRejectSetting public rejectConfig;
    address public adminWallet;
    uint256 public servicePercent;
    bytes16 public guid;

    bool public isOwnerInitialized;

    uint256 public minPay;
    uint256 public donatePercent;
    uint256 public frozenBalance;

    modifier isOwner() {
        require(isOwnerInitialized);
        require(msg.sender == owner);
        _;
    }

    modifier isAdmin() {
        require(msg.sender == adminWallet);
        _;
    }


    constructor(uint256 _minPay, uint256 _donatePercent, uint256 _servicePercent, bytes16 _guid, address _donateWallet, address _serviceWallet, address _owner, address _admin, PostboyRejectSetting _rejectConfig) public {
        require(_donatePercent < 50);
        
        donateWallet = _donateWallet;
        serviceWallet = _serviceWallet;
        servicePercent = _servicePercent;
        guid = _guid;
        donateWallet = _donateWallet;
        donatePercent = _donatePercent;
        frozenBalance = 0;
        minPay = _minPay;
        adminWallet = _admin;
        rejectConfig = _rejectConfig;

        if(_owner == address(0)) {
            owner = address(0);
            isOwnerInitialized = false;
        } else {
            owner = _owner;
            isOwnerInitialized = true;
        }
    }

    function initOwner(address _owner) isAdmin public {
        require(isOwnerInitialized == false);

        owner = _owner;
        isOwnerInitialized = true;
    }
 
    function sendMail(bytes16 mailText, bool isPublic) payable public {
        require(msg.value >= minPay);

        uint256 serviceSum = (msg.value / 100)*servicePercent;
        serviceWallet.transfer(serviceSum);

        frozenBalance += msg.value - serviceSum;

        mails.push(Mail(mailText, bytes16(0), (msg.value - serviceSum), isPublic, false, msg.sender, false, false, false, now));
    }    
    
    function rejectMail(uint256 mailIndex) public {
        require(mails[mailIndex].sender == msg.sender);
        require(mails[mailIndex].isRead == false);
        require(mails[mailIndex].isRejected == false);

        require(rejectConfig.isRejectEnabled() == true);
        require(mails[mailIndex].createdTime + rejectConfig.minTimeForReject() < now);

        mails[mailIndex].isRejected = true;
        frozenBalance -= mails[mailIndex].paySum;

        msg.sender.transfer(mails[mailIndex].paySum);
    }

    function readMail(uint256 mailIndex, bytes16 responseText) isOwner public {
        require(mails[mailIndex].isRead == false);

        mails[mailIndex].responseText = responseText;
        mails[mailIndex].isRead = true;
        frozenBalance -= mails[mailIndex].paySum;

        uint256 donateSum = (mails[mailIndex].paySum / 100)*donatePercent;
        donateWallet.transfer(donateSum);
    }

    function readMailByAdmin(uint256 mailIndex, bytes16 responseText) isAdmin public {
        require(mails[mailIndex].isRead == false);

        mails[mailIndex].responseText = responseText;
        mails[mailIndex].isRead = true;
        frozenBalance -= mails[mailIndex].paySum;

        uint256 donateSum = (mails[mailIndex].paySum / 100)*donatePercent;
        donateWallet.transfer(donateSum);
    }

    function withdrawMoney(uint256 amount) isOwner public {
        require(address(this).balance - frozenBalance >= amount);
        
        withdraws.push(amount);
        msg.sender.transfer(amount);
    }

    function withdrawMoneyByAdmin(uint256 amount) isAdmin public {
        require(address(this).balance - frozenBalance >= amount);

        withdraws.push(amount);
        owner.transfer(amount);
    }

    function updateConfig(uint256 _minPay, uint256 _donatePercent) isOwner public {
        require(_donatePercent < 50);
        
        minPay = _minPay;
        donatePercent = _donatePercent;
    }

    function addLike(uint256 mailIndex, bool isDislike) public {
        require(mailIndex < mails.length);
        require(mails[mailIndex].sender == msg.sender);
        require(mails[mailIndex].isRead == true);
        require(mails[mailIndex].hasLike == false);

        mails[mailIndex].hasLike = true;
        mails[mailIndex].isDislike = isDislike;
    }
 
    function countMails() constant public returns(uint256 length) {
        return mails.length;
    }

    function countWithdraws() constant public returns(uint256 length) {
        return withdraws.length;
    }

    function getAccountStatus() constant public returns(uint256 donatePercentVal, uint256 minPaySum, uint256 frozenBalanceSum, uint256 fullBalance, uint256 countMails, uint256 counWithdraws, bool ownerInitialized) {
        return (donatePercent, minPay, frozenBalance, address(this).balance, mails.length, withdraws.length, isOwnerInitialized);
    }
}
contract PostboyFactory {
    struct Account {
        address contractAddress;
        address ownerAddress;
    }

    Account[] public accounts;

    address public adminAddress;
    address public factoryAdminAddress;
    address public donateWallet;
    address public serviceWallet;
    PostboyRejectSetting public rejectSettings;
    uint256 public servicePercent;


    modifier isFactoryAdmin() {
        require(msg.sender == factoryAdminAddress);
        _;
    }

    modifier isAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    constructor(address _donateWallet, address _serviceWallet, PostboyRejectSetting _rejectSettings, address _factoryAdminAddress) public {
        donateWallet = _donateWallet;
        serviceWallet = _serviceWallet;
        adminAddress = msg.sender;
        rejectSettings = _rejectSettings;
        servicePercent = 10;
        factoryAdminAddress = _factoryAdminAddress;
    }
 
    function createPostboyAccount(uint256 minPay, uint256 donatePercent, bytes16 guid) public {
        address createdAccount = new PostboyAccount(
                            minPay, 
                            donatePercent,
                            servicePercent, 
                            guid,
                            donateWallet,
                            serviceWallet,
                            msg.sender,
                            address(this),
                            rejectSettings
        );
        accounts.push(Account(createdAccount, msg.sender));
    }

    function createPostboyAccountForSomeone(uint256 minPay, uint256 donatePercent, bytes16 guid) isFactoryAdmin public {
        address createdAccount = new PostboyAccount(
                            minPay, 
                            donatePercent,
                            servicePercent, 
                            guid,
                            donateWallet,
                            serviceWallet,
                            address(0),
                            address(this),
                            rejectSettings
        );
        accounts.push(Account(createdAccount, address(0)));
    }
 
    function countAccounts() public constant returns(uint length) {
        return accounts.length;
    }

    function changeServicePercent(uint256 newPercent) isAdmin public {
        require(newPercent <= 10);
        require(newPercent >= 0);

        servicePercent = newPercent;
    }

    function changeFactoryAdmin(address _admin) isAdmin public {
        factoryAdminAddress = _admin;
    }

    

    function initOwner(address ownerAddress, address contractAddress) isFactoryAdmin public {
        PostboyAccount(contractAddress).initOwner(ownerAddress);
    }

    function readMailByAdmin(uint256 mailIndex, bytes16 responseText, address contractAddress) isFactoryAdmin public {
        PostboyAccount(contractAddress).readMailByAdmin(mailIndex, responseText);
    }

    function withdrawMoneyByAdmin(uint256 amount, address contractAddress) isFactoryAdmin public {
        PostboyAccount(contractAddress).withdrawMoneyByAdmin(amount);
    }

}