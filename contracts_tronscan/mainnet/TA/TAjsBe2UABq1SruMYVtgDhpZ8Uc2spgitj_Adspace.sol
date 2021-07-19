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

// USES THE USDJ MEDIANIZER, TO GET THE PRICE OF USDJ IN TRX.
interface Medianizer {
    function read() external view returns (uint);
}

contract Adspace {
    using SafeMath for uint;
    
    Medianizer median = Medianizer(_medianizer);
    
    mapping (address => bool) _adspaceManager;

    address private _medianizer;

    // Ad Data Set
    address private adOwner;
    string  private adName;
    string  private adLink;
    string  private adIcon;
    string  private adBody;
    uint256 private adTimestamp;
    
    uint256 private price;
    
    modifier checkAvailability() {
        require((now - adTimestamp) > 86400, 'CANNOT_WRITE_AD_YET');
        _;
    }
    
    modifier checkPermissionOf(address _msgSender) {
        require(_adspaceManager[_msgSender] == true, 'CANNOT_OVERWRITE_ADSPACE');
        _;
    }
    
    constructor (uint _price, address _firstManager, address _secondManager, address _usdjMedianizer) public {
        adName = "FUNC Adspace";
        adLink = "https://functionisland.com/";
        adIcon = "https://functionisland.com/assets/img/logo.png";
        adBody = "Site-wide, privacy-respecting advertising spaces";
        price = _price;
        
        _medianizer = _usdjMedianizer;
        
        _adspaceManager[_firstManager] = true;
        _adspaceManager[_secondManager] = true;
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
        if (now < (adTimestamp + 86400)) {
            return false;
        }
        return true;
    }
    
    // WRITE FUNCTIONS
    function buyAdspace(string memory _adTitle, string memory _adIcon, string memory _adBody, string memory _adLink, uint _numberOfDays) checkAvailability() public payable returns (bool _success) {
        require(_numberOfDays < 20, 'NO_HOGGING');
        
        uint _finalAmount = 0;
        if (_numberOfDays == 1) {
            _finalAmount = (getPriceForOneDay());
        }
        
        if (_numberOfDays > 1) {
            uint _fullPrice = (getPriceForOneDay() * _numberOfDays);
            uint _discount = ((getPriceForOneDay() / 100) * _numberOfDays); // 1% discount per day, up to 20 days (20% discount)
            _finalAmount = (_fullPrice - _discount);
        }
        
        require(msg.value > ((_finalAmount / 100) * 99), 'ADSPACE_MUST_BE_PAID_FOR_IN_TRX'); // <1% slippage tolerance
        
        adName = _adTitle;
        adLink = _adLink;
        adIcon = _adIcon;
        adBody = _adBody;

        adTimestamp = now;
        return true;
    }
    
    // MANAGEMENT FUNCTIONS
    function withdrawFunds() public returns (bool _success) {
        require(_adspaceManager[msg.sender] == true, 'ONLY_MANAGER');
        (msg.sender).transfer(address(this).balance);
        return true;
    }
    
    function updatePrice(uint _newPrice) public returns (bool _success) {
        require(_adspaceManager[msg.sender] == true, 'ONLY_MANAGER');
        price = (_newPrice * 1e18);
        return true;
    }
    
    // WRITE FUNCTIONS
    function overrideAdspace(string memory _adTitle, string memory _adIcon, string memory _adBody, string memory _adLink) checkPermissionOf(msg.sender) public returns (bool _success) {
        adName = _adTitle;
        adLink = _adLink;
        adIcon = _adIcon;
        adBody = _adBody;

        adTimestamp = now;
        return true;
    }
    
    // INTERNAL FUNCTIONS
    function getPriceForOneDay() internal view returns (uint) {
        uint _oneTronInUSDJ = (median.read());
        uint _oneUSDJInTron = ((1e18) / _oneTronInUSDJ);
        uint _actualPrice = (price * _oneUSDJInTron);
        return _actualPrice;
    }
}