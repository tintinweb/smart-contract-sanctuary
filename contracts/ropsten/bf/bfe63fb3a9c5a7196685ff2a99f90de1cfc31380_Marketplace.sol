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

/**
 * @title Marketplace logic implementation
 */
contract Marketplace is Upgradeable {
    
    using SafeMath for uint256;

    address public owner;
    address public cashout;

    // 0.01% = 1, 1% = 100, 100% = 10000
    uint256 public platformCommissionRate;
    uint256 public userCommissionRate;

    struct User {
        bool exists;
        bool blocked;
        address[] productContracts; // array of unique addresses
    }
    mapping (address => User) public users;

    struct ProductContract {
        bool exists;
        address user;   
    }
    mapping (address => ProductContract) public productContracts;

    event UserRegistered(address userAddress);
    event UserBlocked(address userAddress);
    event UserUnblocked(address userAddress);
    event ProductContractRegistered(address userAddress, address contractAddress);
    event PlatformIncomingTransactionCommission(address contractAddress, uint256 amount, address clientAddress);
    event PlatformOutgoingTransactionCommission(address contractAddress, uint256 amount);
    event UserIncomingTransactionCommission(address contractAddress, uint256 amount, address clientAddress);
    event UserOutgoingTransactionCommission(address contractAddress, uint256 amount);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Init upgradable contract
     */
    function initialize(address sender) public payable {
        super.initialize(sender);
        owner = sender;
        cashout = 0xb9520aD773139c4a127a6a2BF70c3728376194A0;
    }

    /**
     * @dev Default: 0.5%
     * @param newPlatformCommissionRate ex: 0.01% = 1, 1% = 100, 100% = 10000
     */
    function setPlatformCommissionRate(uint256 newPlatformCommissionRate) public onlyOwner {
        platformCommissionRate = newPlatformCommissionRate;
    }

    /**
     * @param weiAmount value
     * @return uint256 calculated commission
     */
    function calculatePlatformCommission(uint256 weiAmount) public view returns (uint256) {
        return weiAmount.mul(platformCommissionRate).div(10000);
    }

    /**
     * @dev Default: 30%
     * @param newUserCommissionRate ex: 0.01% = 1, 1% = 100, 100% = 10000
     */
    function setUserCommissionRate(uint256 newUserCommissionRate) public onlyOwner {
        userCommissionRate = newUserCommissionRate;
    }

    /**
     * @param weiAmount value
     * @return uint256 calculated commission
     */
    function calculateUserCommission(uint256 weiAmount) public view returns (uint256) {
        return weiAmount.mul(userCommissionRate).div(10000);
    }

    /**
     * @dev New marketplace user registration
     * @param userAddress wallet
     */
    function registerUser(address userAddress) public onlyOwner {
        // Check for duplicate user
        require(!users[userAddress].exists);
        
        // Add user to mapping
        users[userAddress] = User(true, false, new address[](0));
        emit UserRegistered(userAddress);
    }

    /**
     * @param userAddress wallet
     * @return bool
     */
    function isUserBlocked(address userAddress) public view returns (bool) {
        // Check user existance
        require(users[userAddress].exists);
        return users[userAddress].blocked;
    }

    /**
     * @param contractAddress product contract
     * @return bool
     */
    function isUserBlockedByContract(address contractAddress) public view returns (bool) {
        // Check contract existance
        require(productContracts[contractAddress].exists);
        return users[productContracts[contractAddress].user].blocked;
    }

    /**
     * @param userAddress wallet
     */
    function blockUser(address userAddress) public onlyOwner {
        // Check user existance
        require(users[userAddress].exists);
        users[userAddress].blocked = true;
        emit UserBlocked(userAddress);
    }

    /**
     * @param userAddress wallet
     */
    function unblockUser(address userAddress) public onlyOwner {
        // Check user existance
        require(users[userAddress].exists);
        users[userAddress].blocked = false;
        emit UserUnblocked(userAddress);
    }

    /**
     * @return array of all user contracts
     */
    function getUserProductContracts(address userAddress) public view onlyOwner returns (address[]) {
        // Check user existance
        require(users[userAddress].exists);
        return users[userAddress].productContracts;
    }

    /**
     * @dev Register contract to user
     * @param userAddress wallet
     * @param contractAddress that belons to user
     */
    function registerProductContract(address userAddress, address contractAddress) public onlyOwner {
        // Check user existance, caller should create user first
        require(users[userAddress].exists);

        // Check for duplicate contract
        require(!productContracts[contractAddress].exists);

        // Add contract to user
        users[userAddress].productContracts.push(contractAddress);

        // Add contract to mapping
        productContracts[contractAddress] = ProductContract(true, userAddress);
        emit ProductContractRegistered(userAddress, contractAddress);
    }

    /**
     * @return user wallet
     */
    function getProductContractUser(address contractAddress) public view onlyOwner returns (address) {
        // Check contract existance
        require(productContracts[contractAddress].exists);
        return productContracts[contractAddress].user;
    }

    /**
     * @dev Commission paid by user clients on incoming transactions
     */
    function payPlatformIncomingTransactionCommission(address clientAddress) public payable {
        // Check contract existance
        require(productContracts[msg.sender].exists);
        emit PlatformIncomingTransactionCommission(msg.sender, msg.value, clientAddress);
    }

    /**
     * @dev Commission paid by user clients on outgoing transactions
     */
    function payPlatformOutgoingTransactionCommission() public payable {
        // Check contract existance
        require(productContracts[msg.sender].exists);
        emit PlatformOutgoingTransactionCommission(msg.sender, msg.value);
    }

    /**
     * @dev Commission paid by users (users contract) on incoming transactions
     */
    function payUserIncomingTransactionCommission(address clientAddress) public payable {
        // Check contract existance
        require(productContracts[msg.sender].exists);
        emit UserIncomingTransactionCommission(msg.sender, msg.value, clientAddress);
    }

    /**
     * @dev Commission paid by users (users contract) on outgoing transactions
     */
    function payUserOutgoingTransactionCommission() public payable {
        // Check contract existance
        require(productContracts[msg.sender].exists);
        emit UserOutgoingTransactionCommission(msg.sender, msg.value);
    }

    /**
     * @dev Send ether to cashout wallet
     */
    function transferEth(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount);
        cashout.transfer(amount);
    }

    /**
     * @dev Transfers the current balance to the cash out wallet and terminates the contract
     */
    function destroy() public onlyOwner {
        selfdestruct(cashout);
    }
}