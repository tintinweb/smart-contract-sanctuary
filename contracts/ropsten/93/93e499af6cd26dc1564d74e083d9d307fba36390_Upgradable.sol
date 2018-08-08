pragma solidity ^0.4.19;

// File: contracts/storage/interface/RocketStorageInterface.sol

// Our eternal storage interface
contract RocketStorageInterface {
    // Modifiers
    modifier onlyLatestRocketNetworkContract() {_;}
    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string);
    function getBytes(bytes32 _key) external view returns (bytes);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    // Setters
    function setAddress(bytes32 _key, address _value) onlyLatestRocketNetworkContract external;
    function setUint(bytes32 _key, uint _value) onlyLatestRocketNetworkContract external;
    function setString(bytes32 _key, string _value) onlyLatestRocketNetworkContract external;
    function setBytes(bytes32 _key, bytes _value) onlyLatestRocketNetworkContract external;
    function setBool(bytes32 _key, bool _value) onlyLatestRocketNetworkContract external;
    function setInt(bytes32 _key, int _value) onlyLatestRocketNetworkContract external;
    // Deleters
    function deleteAddress(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteUint(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteString(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteBytes(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteBool(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteInt(bytes32 _key) onlyLatestRocketNetworkContract external;
    // Hash helpers
    function kcck256str(string _key1) external pure returns (bytes32);
    function kcck256strstr(string _key1, string _key2) external pure returns (bytes32);
    function kcck256stradd(string _key1, address _key2) external pure returns (bytes32);
    function kcck256straddadd(string _key1, address _key2, address _key3) external pure returns (bytes32);
}

// File: contracts/storage/RocketBase.sol

/// @title Base settings / modifiers for each contract in Rocket Pool
/// @author David Rugendyke
contract RocketBase {

    /*** Events ****************/

    event ContractAdded (
        address indexed _newContractAddress,                    // Address of the new contract
        uint256 created                                         // Creation timestamp
    );

    event ContractUpgraded (
        address indexed _oldContractAddress,                    // Address of the contract being upgraded
        address indexed _newContractAddress,                    // Address of the new contract
        uint256 created                                         // Creation timestamp
    );

    /**** Properties ************/

    uint8 public version;                                                   // Version of this contract


    /*** Contracts **************/

    RocketStorageInterface rocketStorage = RocketStorageInterface(0);       // The main storage contract where primary persistant storage is maintained


    /*** Modifiers ************/

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        roleCheck("owner", msg.sender);
        _;
    }

    /**
    * @dev Modifier to scope access to admins
    */
    modifier onlyAdmin() {
        roleCheck("admin", msg.sender);
        _;
    }

    /**
    * @dev Modifier to scope access to admins
    */
    modifier onlySuperUser() {
        require(roleHas("owner", msg.sender) || roleHas("admin", msg.sender));
        _;
    }

    /**
    * @dev Reverts if the address doesn&#39;t have this role
    */
    modifier onlyRole(string _role) {
        roleCheck(_role, msg.sender);
        _;
    }

  
    /*** Constructor **********/
   
    /// @dev Set the main Rocket Storage address
    constructor(address _rocketStorageAddress) public {
        // Update the contract address
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
    }


    /*** Role Utilities */

    /**
    * @dev Check if an address is an owner
    * @return bool
    */
    function isOwner(address _address) public view returns (bool) {
        return rocketStorage.getBool(keccak256("access.role", "owner", _address));
    }

    /**
    * @dev Check if an address has this role
    * @return bool
    */
    function roleHas(string _role, address _address) internal view returns (bool) {
        return rocketStorage.getBool(keccak256("access.role", _role, _address));
    }

     /**
    * @dev Check if an address has this role, reverts if it doesn&#39;t
    */
    function roleCheck(string _role, address _address) view internal {
        require(roleHas(_role, _address) == true);
    }

}

// File: contracts/Upgradable.sol

/// Based on Rocket Pool contracts by Davide Rugendyke

/// @title Upgrades for network contracts
/// @author Steven Brendtro
contract Upgradable is RocketBase {

    /*** Events ****************/

    event ContractUpgraded (
        address indexed _oldContractAddress,                    // Address of the contract being upgraded
        address indexed _newContractAddress,                    // Address of the new contract
        uint256 created                                         // Creation timestamp
    );


    /*** Constructor ***********/    

    /// @dev Upgrade constructor
    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
        // Set the version
        version = 1;
    }

    /**** Contract Upgrade Methods ***********/

    /**
    * @dev Add a contract address to the contract storage, allowing it to access storage
    * @param _name Name of the contract to add
    * @param _newContractAddress Address of the contract to add
    */
    function addContract(string _name, address _newContractAddress) onlyOwner external {

        // Make sure the contract name isn&#39;t already in use.  If it is, upgradeContract() is the proper function to use
        address existing_ = rocketStorage.getAddress(keccak256("contract.name", _name));
        require(existing_ == 0x0);
     
        // Add the contract to the storage using a hash of the "contract.name" namespace and the name of the contract that was supplied as the &#39;key&#39; and use the new contract address as the &#39;value&#39;
        // This means we can get the address of the contract later by looking it up using its name eg &#39;rocketUser&#39;
        rocketStorage.setAddress(keccak256("contract.name", _name), _newContractAddress);
        // Add the contract to the storage using a hash of the "contract.address" namespace and the address of the contract that was supplied as the &#39;key&#39; and use the new contract address as the &#39;value&#39;
        // This means we can verify this contract as belonging to the dApp by using it&#39;s address rather than its name.
        // Handy when you need to protect certain methods from being accessed by any contracts that are not part of the dApp using msg.sender (see the modifier onlyLatestRocketNetworkContract() in the RocketStorage code)
        rocketStorage.setAddress(keccak256("contract.address", _newContractAddress), _newContractAddress);
        // Log it
        emit ContractAdded(_newContractAddress, now);
    }

    /// @param _name The name of an existing contract in the network
    /// @param _upgradedContractAddress The new contracts address that will replace the current one
    // TODO: Write unit tests to verify
    function upgradeContract(string _name, address _upgradedContractAddress) onlyOwner external {
        // Get the current contracts address
        address oldContractAddress = rocketStorage.getAddress(keccak256("contract.name", _name));
        // Check it exists
        require(oldContractAddress != 0x0);
        // Check it is not the contract&#39;s current address
        require(oldContractAddress != _upgradedContractAddress);
        // Replace the address for the name lookup - contract addresses can be looked up by their name or verified by a reverse address lookup
        rocketStorage.setAddress(keccak256("contract.name", _name), _upgradedContractAddress);
        // Add the new contract address for a direct verification using the address (used in RocketStorage to verify its a legit contract using only the msg.sender)
        rocketStorage.setAddress(keccak256("contract.address", _upgradedContractAddress), _upgradedContractAddress);
        // Remove the old contract address verification
        rocketStorage.deleteAddress(keccak256("contract.address", oldContractAddress));
        // Log it
        emit ContractUpgraded(oldContractAddress, _upgradedContractAddress, now);
    }

}