pragma solidity 0.4.21;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);
    function unicornBreedingAddress() external view returns (address);


    function paused() external view returns (bool);
    function locked() external view returns (bool);
    //    function locked() external view returns (bool);

    //service
    function registerInit(address _contract) external;

}


interface LandInit {
    function init() external;
}

contract LandManagement {
    using SafeMath for uint;

    UnicornManagementInterface public unicornManagement;

    //    address public ownerAddress;
    //    address public managerAddress;
    //    address public communityAddress;
    //    address public walletAddress;
    //    address public candyToken;
    //    address public megaCandyToken;
    //    address public dividendManagerAddress; //onlyCommunity
    //address public unicornTokenAddress; //onlyOwner
    address public userRankAddress;
    address public candyLandAddress;
    address public candyLandSaleAddress;

    mapping(address => bool) unicornContracts;//address

    bool public ethLandSaleOpen = true;
    bool public presaleOpen = true;
    bool public firstRankForFree = true;

    uint public landPriceWei = 2412000000000000000;
    uint public landPriceCandy = 720000000000000000000;

    event AddUnicornContract(address indexed _unicornContractAddress);
    event DelUnicornContract(address indexed _unicornContractAddress);
    event NewUserRankAddress(address userRankAddress);
    event NewCandyLandAddress(address candyLandAddress);
    event NewCandyLandSaleAddress(address candyLandSaleAddress);
    event NewLandPrice(uint _price, uint _candyPrice);

    modifier onlyOwner() {
        require(msg.sender == ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == managerAddress());
        _;
    }


    modifier whenNotPaused() {
        require(!unicornManagement.paused());
        _;
    }

    modifier whenPaused {
        require(unicornManagement.paused());
        _;
    }


    modifier onlyUnicornManagement() {
        require(msg.sender == address(unicornManagement));
        _;
    }

    modifier whenUnlocked() {
        require(!unicornManagement.locked());
        _;
    }



    function LandManagement(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
        unicornManagement.registerInit(this);
    }


    function init() onlyUnicornManagement whenPaused external {
        for(uint i = 0; i < initList.length; i++) {
            LandInit(initList[i]).init();
        }
    }


    struct InitItem {
        uint listIndex;
        bool exists;
    }

    mapping (address => InitItem) private initItems;
    address[] private initList;

    function registerInit(address _contract) external whenPaused {
        require(msg.sender == ownerAddress() || tx.origin == ownerAddress());

        if (!initItems[_contract].exists) {
            initItems[_contract] = InitItem({
                listIndex: initList.length,
                exists: true
                });
            initList.push(_contract);
        }
    }

    function unregisterInit(address _contract) external onlyOwner whenPaused {
        require(initItems[_contract].exists && initList.length > 0);
        uint lastIdx = initList.length - 1;
        initItems[initList[lastIdx]].listIndex = initItems[_contract].listIndex;
        initList[initItems[_contract].listIndex] = initList[lastIdx];
        initList.length--;
        delete initItems[_contract];

    }


    function runInit() external onlyOwner whenPaused {
        for(uint i = 0; i < initList.length; i++) {
            LandInit(initList[i]).init();
        }
    }


    function ownerAddress() public view returns (address) {
        return unicornManagement.ownerAddress();
    }

    function managerAddress() public view returns (address) {
        return unicornManagement.managerAddress();
    }

    function communityAddress() public view returns (address) {
        return unicornManagement.communityAddress();
    }

    function walletAddress() public view returns (address) {
        return unicornManagement.walletAddress();
    }

    function candyToken() public view returns (address) {
        return unicornManagement.candyToken();
    }

    function megaCandyToken() public view returns (address) {
        return unicornManagement.candyPowerToken();
    }

    function dividendManagerAddress() public view returns (address) {
        return unicornManagement.dividendManagerAddress();
    }

    function setUnicornContract(address _unicornContractAddress) public onlyOwner whenUnlocked {
        require(_unicornContractAddress != address(0));
        unicornContracts[_unicornContractAddress] = true;
        emit AddUnicornContract(_unicornContractAddress);
    }

    function delUnicornContract(address _unicornContractAddress) external onlyOwner whenUnlocked{
        require(unicornContracts[_unicornContractAddress]);
        unicornContracts[_unicornContractAddress] = false;
        emit DelUnicornContract(_unicornContractAddress);
    }

    function isUnicornContract(address _unicornContractAddress) external view returns (bool) {
        return unicornContracts[_unicornContractAddress];
    }



    function setUserRank(address _userRankAddress) external onlyOwner whenPaused whenUnlocked {
        require(_userRankAddress != address(0));
        userRankAddress = _userRankAddress;
        emit NewUserRankAddress(userRankAddress);
    }

    function setCandyLand(address _candyLandAddress) external onlyOwner whenPaused whenUnlocked {
        require(_candyLandAddress != address(0));
        candyLandAddress = _candyLandAddress;
        setUnicornContract(candyLandAddress);
        emit NewCandyLandAddress(candyLandAddress);
    }

    function setCandyLandSale(address _candyLandSaleAddress) external onlyOwner whenPaused whenUnlocked {
        require(_candyLandSaleAddress != address(0));
        candyLandSaleAddress = _candyLandSaleAddress;
        setUnicornContract(candyLandSaleAddress);
        emit NewCandyLandSaleAddress(candyLandSaleAddress);
    }


    function paused() public view returns(bool) {
        return unicornManagement.paused();
    }


    function stopLandEthSale() external onlyOwner {
        require(ethLandSaleOpen);
        ethLandSaleOpen = false;
    }

    function openLandEthSale() external onlyOwner {
        require(!ethLandSaleOpen);
        ethLandSaleOpen = true;
    }

    function stopPresale() external onlyOwner {
        require(presaleOpen);
        presaleOpen = false;
    }

    function setFirstRankForFree(bool _firstRankForFree) external onlyOwner {
        require(firstRankForFree != _firstRankForFree);
        firstRankForFree = _firstRankForFree;
    }


    //price in weis
    function setLandPrice(uint _price, uint _candyPrice) external onlyManager {
        landPriceWei = _price;
        landPriceCandy = _candyPrice;
        emit NewLandPrice(_price, _candyPrice);
    }

    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }
}