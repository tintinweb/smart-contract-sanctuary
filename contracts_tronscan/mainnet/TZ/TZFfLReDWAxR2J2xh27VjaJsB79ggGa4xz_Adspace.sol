//SourceUnit: adspace.sol

pragma solidity 0.5.8;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeMath: division by zero");}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");}
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Adspace {
    using SafeMath for uint;

    mapping (address => bool) _adspaceManager;

    address payable private deployer;
    address payable private feeReceiver;

    // Ad Data Set
    address private adOwner;
    string  private adName;
    string  private adLink;
    string  private adIcon;
    string  private adBody;
    uint256 private adTimestamp;
    uint256 private adSecondsPaidFor;
    
    uint256 private price;
    
    uint256 public totalAdspacesSold;
    
    uint256 public totalFundsPaid;
    uint256 public totalFundsWithdrawn;
    
    uint256 public totalFeesCollected;
    uint256 public totalFeesUsed;
    
    event AdspacePurchased(address _buyer, uint _days, uint _amountPaid, uint _timestamp);
    event AdspacePriceUpdated(uint _oldPrice, uint _newPrice, uint _timestamp);
    
    event AdspaceFundsCollected(address _collector, uint _amountCollected, uint _timestamp);
    event AdspaceFeesPaidOut(address _collector, uint _amountCollected, uint _timestamp);
    
    event AdspaceManagerUpdated(address _oldAddress, address _newAddress, uint _timestamp);
    event AdspaceFeeRecipientUpdated(address _oldAddress, address _newAddress, uint _timestamp);
    
    modifier checkWritable(address _msgSender) {
        require((now - adTimestamp) > 86400 || _adspaceManager[_msgSender] == true, 'CANNOT_WRITE_AD');
        _;
    }
    
    modifier onlyDeployer() {
        require(msg.sender == deployer, 'ONLY_DEPLOYER');
        _;
    }
    
    constructor (address _primeManager, address payable _feeReceiver) public {
        adName = "FUNC Adspace";
        adLink = "https://functionisland.com/";
        adIcon = "https://functionisland.com/assets/img/logo.png";
        adBody = "Site-wide, privacy-respecting advertising spaces";
        price = 1000000;

        _adspaceManager[msg.sender] = true;
        _adspaceManager[_primeManager] = true;
        
        feeReceiver = _feeReceiver;
    }
    
    // READ FUNCTIONS
    function readAdvert() public view returns (string memory _adTitle, string memory _adIcon, string memory _adBody, string memory _adLink) {
        if (adspaceAvailable()) {
            return ("Function Island", "https://functionisland.com/assets/img/logo.png", "Site-wide, privacy-respecting advertising spaces", "https://functionisland.com/");
        }
        return (adName, adIcon, adBody, adLink);
    }
    
    function currentPrice() public view returns (uint _currentPrice) {return price;}
    
    function adspaceAvailable() public view returns (bool _available) {
        if (now < (adTimestamp.add(adSecondsPaidFor))) {return false;}
        return true;
    }
    
    // WRITE FUNCTIONS
    function buyAdspace(string memory _adTitle, string memory _adIcon, string memory _adBody, string memory _adLink, uint _numberOfDays) checkWritable(msg.sender) public payable returns (bool _success) {
        require(msg.value >= price.mul(_numberOfDays));
        
        require(_numberOfDays > 0 && _numberOfDays < 20, 'MUST_BE_ONE_TO_TWENTY_DAYS');

        adName = _adTitle;
        adLink = _adLink;
        adIcon = _adIcon;
        adBody = _adBody;
        adSecondsPaidFor = (_numberOfDays.mul(86400));

        adTimestamp = now;
        
        uint _incomingValue = (msg.value.div(10));
        uint _funds = _incomingValue.mul(9);
        uint _fee = _incomingValue.mul(1);
        
        totalAdspacesSold += 1;
        totalFundsPaid += _funds;
        totalFeesCollected += _fee;
        
        emit AdspacePurchased(msg.sender, _numberOfDays, msg.value, now);
        return true;
    }
    
    function getQuote(uint _numberOfDays) public view returns (uint) {
        if (_numberOfDays > 20) {_numberOfDays = 20;}
        return (price * _numberOfDays);
    }
    
    // MANAGEMENT FUNCTIONS
    function withdrawFunds() public returns (bool _success) {
        require(_adspaceManager[msg.sender] == true, 'ONLY_MANAGER');
        
        uint _funds = address(this).balance;
        uint _forManager = (_funds.div(10)).mul(9);
        uint _forReciever = (_funds.div(10)).mul(1);
        
        (msg.sender).transfer(_forManager);
        (feeReceiver).transfer(_forReciever);
        
        totalFundsWithdrawn += _forManager;
        totalFeesUsed += _forReciever;
        
        emit AdspaceFundsCollected(msg.sender, _forManager, now);
        emit AdspaceFeesPaidOut(feeReceiver, _forReciever, now);
        return true;
    }
    
    function updatePrice(uint _newPrice) public returns (bool _success) {
        require(_adspaceManager[msg.sender] == true, 'ONLY_MANAGER');
        
        uint _currentPrice = price;
        
        price = _newPrice;
        
        emit AdspacePriceUpdated(_currentPrice, _newPrice, now);
        return true;
    }
    
    // DEPLOYER FUNCTIONS
    function updateManager(address _currentAddress, address _newAddress) onlyDeployer() public returns (bool _success) {
        _adspaceManager[_currentAddress] = false;
        _adspaceManager[_newAddress] = true;
        
        emit AdspaceManagerUpdated(_currentAddress, _newAddress, now);
        return true;
    }
    
    function updateFeeCollector(address payable _newRecipient) onlyDeployer() public returns (bool _success) {
        address _currentRecipient = feeReceiver;
        feeReceiver = _newRecipient;
        
        emit AdspaceFeeRecipientUpdated(_currentRecipient, _newRecipient, now);
        return true;
    }
}