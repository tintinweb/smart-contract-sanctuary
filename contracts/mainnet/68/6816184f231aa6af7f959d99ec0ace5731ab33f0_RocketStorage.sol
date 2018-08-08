pragma solidity ^0.4.19;

// File: contracts/storage/RocketStorage.sol

/// @title The primary persistent storage for Rocket Pool
/// @author David Rugendyke
contract RocketStorage {

    /**** Storage Types *******/

    mapping(bytes32 => uint256)    private uIntStorage;
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => bool)       private boolStorage;
    mapping(bytes32 => int256)     private intStorage;


    /*** Modifiers ************/

    /// @dev Only allow access from the latest version of a contract in the Rocket Pool network after deployment
    modifier onlyLatestRocketNetworkContract() {
        // The owner and other contracts are only allowed to set the storage upon deployment to register the initial contracts/settings, afterwards their direct access is disabled
        if (boolStorage[keccak256("contract.storage.initialised")] == true) {
            // Make sure the access is permitted to only contracts in our Dapp
            require(addressStorage[keccak256("contract.address", msg.sender)] != 0x0);
        }
        _;
    }


    /// @dev constructor
    constructor() public {
        // Set the main owner upon deployment
        boolStorage[keccak256("access.role", "owner", msg.sender)] = true;
    }


    /**** Get Methods ***********/
   
    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view returns (uint) {
        return uIntStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }

    /**** Set Methods ***********/

    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyLatestRocketNetworkContract external {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint _value) onlyLatestRocketNetworkContract external {
        uIntStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string _value) onlyLatestRocketNetworkContract external {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes _value) onlyLatestRocketNetworkContract external {
        bytesStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyLatestRocketNetworkContract external {
        boolStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setInt(bytes32 _key, int _value) onlyLatestRocketNetworkContract external {
        intStorage[_key] = _value;
    }

    /**** Delete Methods ***********/
    
    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyLatestRocketNetworkContract external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) onlyLatestRocketNetworkContract external {
        delete uIntStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) onlyLatestRocketNetworkContract external {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) onlyLatestRocketNetworkContract external {
        delete bytesStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyLatestRocketNetworkContract external {
        delete boolStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteInt(bytes32 _key) onlyLatestRocketNetworkContract external {
        delete intStorage[_key];
    }

    /**** Hash Helpers **************/
    function kcck256str(string _key1) external pure returns (bytes32) {
        return keccak256(_key1);
    }

    function kcck256strstr(string _key1, string _key2) external pure returns (bytes32) {
        return keccak256(_key1, _key2);
    }

    function kcck256stradd(string _key1, address _key2) external pure returns (bytes32) {
        return keccak256(_key1, _key2);
    }

    function kcck256straddadd(string _key1, address _key2, address _key3) external pure returns (bytes32) {
        return keccak256(_key1, _key2, _key3);
    }

}