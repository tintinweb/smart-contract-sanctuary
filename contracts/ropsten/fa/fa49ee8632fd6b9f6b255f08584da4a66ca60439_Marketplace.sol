pragma solidity ^0.4.24;



/**
 * @title IRegistry
 * @dev This contract represents the interface of a registry contract
 */
interface IRegistry {
    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);

    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    */
    event VersionAdded(string version, address implementation);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string version, address implementation) external;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string version) external view returns (address);
}

/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
    // Versions registry
    IRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}





/**
 * @title Upgradeable
 * @dev This contract holds all the minimum required functionality for a behavior to be upgradeable.
 * This means, required state variables for owned upgradeability purpose and simple initialization validation.
 */
contract Upgradeable is UpgradeabilityStorage {
    /**
    * @dev Validates the caller is the versions registry.
    * THIS FUNCTION SHOULD BE OVERRIDDEN CALLING SUPER
    * @param sender representing the address deploying the initial behavior of the contract
    */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract TokensContract {
    function balanceOf(address who) public view returns (uint256);
}

contract Marketplace is Upgradeable {
    
    using SafeMath for uint256;

    address public owner;

    // 0.01% = 1, 1% = 100, 100% = 10000
    uint256 public platformCommissionRate;
    uint256 public userCommissionRate;

    address public tokensContractAddress;
    uint256 public tokensDecimals;
    uint256 public tokensMultiplier;    // 1 token * tokensMultiplier = accessible count of user clients

    struct User {
        int256 balance;    // wei
        bool exists;
        bool blocked;
        address[] productContracts; // array of unique addresses
    }
    mapping (address => User) public users;

    struct ProductContract {
        address user;
        uint256 commissionWei;
        bool exists;
        address[] clients;  // array of unique addresses
    }
    mapping (address => ProductContract) productContracts;

    event UserRegistered(address userAddress);
    event UserBlocked(address userAddress);
    event UserUnblocked(address userAddress);
    event ProductContractRegistered(address userAddress, address contractAddress);
    event ClientAdded(address clientAddress, address contractAddress);
    event NintyPercentClientsReached(address userAddress);
    event PlatformIncomingTransactionCommission(address contractAddress, uint256 amount);
    event PlatformOutgoingTransactionCommission(address contractAddress, uint256 amount);
    event UserIncomingTransactionCommission(address contractAddress, uint256 amount);
    event UserOutgoingTransactionCommission(address contractAddress, uint256 amount);
    event SaasUserPaid(address userAddress, uint256 amount);
    event SaasPayment(address userAddress, uint256 amount);
    event UserBalanceBelowZero(address userAddress);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function initialize(address sender) public payable {
        super.initialize(sender);
        owner = sender;
    }

    function setPlatformCommissionRate(uint256 newPlatformCommissionRate) public onlyOwner {
        platformCommissionRate = newPlatformCommissionRate;
    }

    function calculatePlatformCommission(uint256 weiAmount) public view returns (uint256) {
        return weiAmount.mul(platformCommissionRate).div(10000);
    }

    function setUserCommissionRate(uint256 newUserCommissionRate) public onlyOwner {
        userCommissionRate = newUserCommissionRate;
    }

    function calculateUserCommission(uint256 weiAmount) public view returns (uint256) {
        return weiAmount.mul(userCommissionRate).div(10000);
    }

    function registerUser(address userAddress) public returns (bool) {
        // Check for duplicate user
        require(!users[userAddress].exists);
        
        // Add user to mapping
        users[userAddress] = User(0, true, false, new address[](0));
        emit UserRegistered(userAddress);

        return true;
    }

    function isUserBlocked(address userAddress) public view returns (bool) {
        // Check user existance
        require(users[userAddress].exists);

        return users[userAddress].blocked;
    }

    function blockUser(address userAddress) public onlyOwner {
        // Check user existance
        require(users[userAddress].exists);

        users[userAddress].blocked = true;

        emit UserBlocked(userAddress);
    }

    function unblockUser(address userAddress) public onlyOwner {
        // Check user existance
        require(users[userAddress].exists);

        users[userAddress].blocked = false;

        emit UserUnblocked(userAddress);
    }

    function getUserProductContracts(address userAddress) public view returns (address[]) {
        // Check user existance
        require(users[userAddress].exists);

        return users[userAddress].productContracts;
    }

    function getUserBalance(address userAddress) public view returns (int256) {
        // Check user existance
        require(users[userAddress].exists);

        return users[userAddress].balance;
    }

    function registerProductContract(address userAddress, address contractAddress) public returns (bool) {
        // Check user existance, caller should create user first
        require(users[userAddress].exists);

        // Check for duplicate contract
        require(!productContracts[contractAddress].exists);

        // Add contract to user
        users[userAddress].productContracts.push(contractAddress);

        // Add contract to mapping
        productContracts[contractAddress] = ProductContract(userAddress, 0, true, new address[](0));
        emit ProductContractRegistered(userAddress, contractAddress);

        return true;
    }

    function getProductContractUser(address contractAddress) public view returns (address) {
        // Check contract existance
        require(productContracts[contractAddress].exists);

        return productContracts[contractAddress].user;
    }

    function getProductContractCommissionWei(address contractAddress) public view returns (uint256) {
        // Check contract existance
        require(productContracts[contractAddress].exists);

        return productContracts[contractAddress].commissionWei;
    }

    function getProductContractClients(address contractAddress) public view returns (address[]) {
        // Check contract existance
        require(productContracts[contractAddress].exists);

        return productContracts[contractAddress].clients;
    }

    function addClient(address clientAddress, address contractAddress) private returns (bool) {
        // Check contract existance
        require(productContracts[contractAddress].exists);

        ProductContract storage pc = productContracts[contractAddress];

        // Add client to contract
        pc.clients.push(clientAddress);
        
        emit ClientAdded(clientAddress, contractAddress);

        return true;
    }

    function isClientAddedBefore(address clientAddress, address contractAddress) private view returns (bool) {
        ProductContract storage pc = productContracts[contractAddress];
        bool isClientAddedBeforeFlag = false;
        for(uint256 i = 0; i < pc.clients.length; i++) {
            if(pc.clients[i] == clientAddress) {
                isClientAddedBeforeFlag = true;
            }
        }
        return isClientAddedBeforeFlag;
    }

    function addCommissionAmount(uint256 _commissionWei, address contractAddress) private {
        // Check contract existance
        require(productContracts[contractAddress].exists);

        ProductContract storage pc = productContracts[contractAddress];
        pc.commissionWei = pc.commissionWei.add(_commissionWei);
    }

    function getUserClientsCount(address userAddress) public view returns (uint256) {
        // Check user existance
        require(users[userAddress].exists);

        uint256 totalClientsCount = 0;

        address[] memory _productContracts = users[userAddress].productContracts;
        for(uint256 i = 0; i < _productContracts.length; i++) {
            totalClientsCount += productContracts[_productContracts[i]].clients.length;
        }

        return totalClientsCount;
    }

    function setTokensContractAddress(address _address) public onlyOwner {
        tokensContractAddress = _address;
    }

    function setTokensDecimals(uint256 _decimals) public onlyOwner {
        tokensDecimals = _decimals;
    }

    function setTokensMultiplier(uint256 _tokensMultiplier) public onlyOwner {
        tokensMultiplier = _tokensMultiplier;
    }

    function payPlatformIncomingTransactionCommission(address clientAddress) public payable {
        // Check contract existance
        require(productContracts[msg.sender].exists);

        // If new client
        if(!isClientAddedBefore(clientAddress, msg.sender)) {
            if(canAddNewClient(productContracts[msg.sender].user)) {
                addClient(clientAddress, msg.sender);
            } else {
                revert();
            }
        }

        addCommissionAmount(msg.value, msg.sender);

        emit PlatformIncomingTransactionCommission(msg.sender, msg.value);
    }

    function payPlatformOutgoingTransactionCommission() public payable {
        // Check contract existance
        require(productContracts[msg.sender].exists);

        addCommissionAmount(msg.value, msg.sender);

        emit PlatformOutgoingTransactionCommission(msg.sender, msg.value);
    }

    function payUserIncomingTransactionCommission(address clientAddress) public payable {
        // Check contract existance
        require(productContracts[msg.sender].exists);

        // If new client
        if(!isClientAddedBefore(clientAddress, msg.sender)) {
            if(canAddNewClient(productContracts[msg.sender].user)) {
                addClient(clientAddress, msg.sender);
            } else {
                revert();
            }
        }

        addCommissionAmount(msg.value, msg.sender);

        emit UserIncomingTransactionCommission(msg.sender, msg.value);
    }

    function payUserOutgoingTransactionCommission() public payable {
        // Check contract existance
        require(productContracts[msg.sender].exists);

        addCommissionAmount(msg.value, msg.sender);

        emit UserOutgoingTransactionCommission(msg.sender, msg.value);
    }

    function getUserTokensCount(address userAddress) private view returns (uint256) {
        TokensContract tokensContract = TokensContract(tokensContractAddress);

        uint256 tcBalance = tokensContract.balanceOf(userAddress);

        return tcBalance.div(tokensDecimals);
    }

    function canAddNewClient(address userAddress) public returns (bool) {
        // Check user existance
        require(users[userAddress].exists);

        uint256 userClientsCount = getUserClientsCount(userAddress);
        uint256 userTokensCountAvailable = getUserTokensCount(userAddress).mul(tokensMultiplier);

        if(userClientsCount >= userTokensCountAvailable) return false;

        // If current user clients count above 90% of available limit
        if(userClientsCount.mul(10000).div(userTokensCountAvailable) >= 9000) emit NintyPercentClientsReached(userAddress);

        return true;
    }

    function saasPayUser() public payable {
        // Check user existance
        require(users[msg.sender].exists);

        users[msg.sender].balance += int(msg.value);

        emit SaasUserPaid(msg.sender, msg.value);
    }

    function saasPayment(address userAddress, uint256 amount) public onlyOwner {
        // Check user existance
        require(users[userAddress].exists);

        // Generate event if balance < 0
        if(users[userAddress].balance < int(amount)) emit UserBalanceBelowZero(userAddress);

        users[userAddress].balance -= int(amount);

        emit SaasPayment(userAddress, amount);
    }
}