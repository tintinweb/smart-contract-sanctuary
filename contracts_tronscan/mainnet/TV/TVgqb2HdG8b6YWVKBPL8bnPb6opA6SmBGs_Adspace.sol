//SourceUnit: Adspace.sol

pragma solidity 0.5.8;

/*
        ___       __                                   ___ 
       /   | ____/ /________  ____ _________     _   _|__ \
      / /| |/ __  / ___/ __ \/ __ `/ ___/ _ \   | | / /_/ /
     / ___ / /_/ (__  ) /_/ / /_/ / /__/  __/   | |/ / __/ 
    /_/  |_\__,_/____/ .___/\__,_/\___/\___/    |___/____/ 
                    /_/                                    

    Version 2.0.1, by Function Island
*/  
    
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

    mapping (address => bool) _adspaceManager; // Keep track of addresses permitted to manage the contract

    address payable private deployer;       // Deployer address, for God-level powers
    address payable private feeReceiver;    // Fee recipient address, for the 10% cut.
    address payable private primeManager;   // The primary manager of the contract.
    
    uint _secondsInADay = 86400; // Seconds in one day.

    // Custom Ad Data Set
    address private adOwner;          // Address which paid for the ad
    string  private adName;           // Name
    string  private adLink;           // Link
    string  private adIcon;           // Icon
    string  private adBody;           // Body
    uint256 private adTimestamp;      // Lease Date
    uint256 private adSecondsPaidFor; // How many days (in seconds) an ad has been set for
    
    // Default Ad Data Set
    string private _defaultName = "Function Adspace";
    string private _defaultLink = "https://functionisland.com/assets/img/function-logos/logo.png";
    string private _defaultIcon = "Site-wide, privacy-respecting advertising spaces";
    string private _defaultBody = "https://functionisland.com/";
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    uint256 private price; // How much TRX per day the Adspace is being leased for
    
    uint256 public totalAdspacesSold; // How many times the Adspace has been leased
    
    uint256 public totalFundsPaid;      // How much has been paid for Adspaces since deployment
    uint256 public totalFundsWithdrawn; // How much of those funds have been collected by managers
    
    uint256 public totalFeesCollected; // How much TRX in fees have been collected since deployment
    uint256 public totalFeesUsed;      // How much TRX has been moved to the recipient of fees
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    event AdspacePurchased(address _buyer, uint _days, uint _amountPaid, uint _timestamp);
    event AdspacePriceUpdated(uint _oldPrice, uint _newPrice, uint _timestamp);
    
    event AdspaceFundsCollected(address _collector, uint _amountCollected, uint _timestamp);
    event AdspaceFeesPaidOut(address _collector, uint _amountCollected, uint _timestamp);
    
    event AdspaceManagerUpdated(address _oldAddress, address _newAddress, uint _timestamp);
    event AdspaceFeeRecipientUpdated(address _oldAddress, address _newAddress, uint _timestamp);
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // MODIFIER: Requires one of the following conditions:
    //  - (now subtract the time the ad was leased) must equal more than the seconds paid for most recently
    
    //    OR
    
    //  - The message sender must be a designated manager of the contract
    modifier checkWritable(address _msgSender) {
        require((now - adTimestamp) > adSecondsPaidFor || _adspaceManager[_msgSender] == true, 'CANNOT_WRITE_AD');
        _;
    }
    
    // MODIFIER: Requires the caller address to match the address of deployer.
    modifier onlyDeployer() {
        require(msg.sender == deployer, 'ONLY_DEPLOYER');
        _;
    }
    
    // MODIFIER: Requires the caller address to be a designated manager of the contract.
    modifier onlyManagers() {
        require(_adspaceManager[msg.sender] == true, 'ONLY_MANAGER');
        _;
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    constructor (address _primeManager, address payable _feeReceiver) public {
        adName = "FUNC Adspace";
        adLink = "https://functionisland.com/";
        adIcon = "https://functionisland.com/assets/img/function-logos/logo.png";
        adBody = "Site-wide, privacy-respecting advertising spaces";
        price = 2000000000;
        adSecondsPaidFor = 0;

        _adspaceManager[msg.sender] = true;
        _adspaceManager[_primeManager] = true;
        
        feeReceiver = _feeReceiver;
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // READ FUNCTIONS
    
    // Get the current advert.
    // If the adspace is available, show the default content.
    // Otherwise, show the content which has been paid to show.
    function readAdvert() public view returns (string memory _adTitle, string memory _adIcon, string memory _adBody, string memory _adLink) {
        if (adspaceAvailable()) {
            return (_defaultName, _defaultIcon, _defaultBody, _defaultLink);
        }
        return (adName, adIcon, adBody, adLink);
    }
    
    // Get the current price of the adspace.
    // Returns price for one day lease.
    function currentPrice() public view returns (uint _currentPrice) {return price;}
    
    // Public function to check if the Adspace is available
    function adspaceAvailable() public view returns (bool _available) {
        if (now < (adTimestamp.add(adSecondsPaidFor))) {return false;}
        return true;
    }
    
    // Get a quote for the cost of _x_ number of days to lease the Adspace.
    // Rate subject to change at discretion of contract managers, when price is altered.
    function getQuote(uint _numberOfDays) public view returns (uint) {
        require(_numberOfDays > 0, 'NO_ZERO_CALCULATIONS');
        require(_numberOfDays < 21, 'MAX_DAYS_REACHED');
        
        if (_numberOfDays >  20) {_numberOfDays = 20;}
        
        return (price * _numberOfDays);
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // WRITE FUNCTIONS
    function buyAdspace(string memory _adTitle, string memory _adIcon, string memory _adBody, string memory _adLink, uint _numberOfDays) checkWritable(msg.sender) public payable returns (bool _success) {
        require(msg.value >= price.mul(_numberOfDays));
        
        // Require between 1 and 20 days
        require(_numberOfDays > 0 && _numberOfDays < 20, 'MUST_BE_ONE_TO_TWENTY_DAYS');
        
        // Set the ad data specified in arguments
        adName = _adTitle;
        adLink = _adLink;
        adIcon = _adIcon;
        adBody = _adBody;
        adSecondsPaidFor = (_numberOfDays.mul(_secondsInADay));
        
        // Set the ad timestamp
        adTimestamp = now;
        
        // Update the funds distribution records
        uint _incomingValue = (msg.value.div(10));
        uint _funds = _incomingValue.mul(9);
        uint _fee = _incomingValue.mul(1);
        
        // Update the contract metrics
        totalAdspacesSold += 1;
        totalFundsPaid += _funds;
        totalFeesCollected += _fee;
        
        // Tell the network...
        emit AdspacePurchased(msg.sender, _numberOfDays, msg.value, now);
        return true; // Function Successful!
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // MANAGEMENT FUNCTIONS
    function withdrawFunds() onlyManagers() public returns (bool _success) {
        
        // Calculate the funds to allocate to each address
        uint _funds = address(this).balance;
        uint _forManager = (_funds.div(10)).mul(9);
        uint _forReciever = (_funds.div(10)).mul(1);
        
        // Transfer funds!
        (primeManager).transfer(_forManager);
        (feeReceiver).transfer(_forReciever);
        
        // Update contract metrics
        totalFundsWithdrawn += _forManager;
        totalFeesUsed += _forReciever;
        
        // Tell the network...
        emit AdspaceFundsCollected(msg.sender, _forManager, now);
        emit AdspaceFeesPaidOut(feeReceiver, _forReciever, now);
        return true; // Function Successful!
    }
    
    // Update the price of the adspace.
    // _newPrice = price in TRX, per day.
    function updatePrice(uint _newPrice) onlyManagers() public returns (bool _success) {
        uint _currentPrice = price;
        price = _newPrice;
        
        // Tell the network...
        emit AdspacePriceUpdated(_currentPrice, _newPrice, now);
        return true; // Function Successful!
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
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