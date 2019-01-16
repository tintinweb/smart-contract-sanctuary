pragma solidity ^0.4.24;

// File: contracts/storage/EternalStorage.sol

contract EternalStorage {

    /// @notice Internal mappings used to store all kinds on data into the contract
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => bytes32) internal bytes32Storage;

    /// @notice Internal mappings used to store arrays of different data types
    mapping(bytes32 => bytes32[]) internal bytes32ArrayStorage;
    mapping(bytes32 => uint256[]) internal uintArrayStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
    mapping(bytes32 => string[]) internal stringArrayStorage;

    //////////////////
    //// set functions
    //////////////////
    /// @notice Set the key values using the Overloaded `set` functions
    /// Ex- string version = "0.0.1"; replace to
    /// set(keccak256(abi.encodePacked("version"), "0.0.1");
    /// same for the other variables as well some more example listed below
    /// ex1 - address securityTokenAddress = 0x123; replace to
    /// set(keccak256(abi.encodePacked("securityTokenAddress"), 0x123);
    /// ex2 - bytes32 tokenDetails = "I am ST20"; replace to
    /// set(keccak256(abi.encodePacked("tokenDetails"), "I am ST20");
    /// ex3 - mapping(string => address) ownedToken;
    /// set(keccak256(abi.encodePacked("ownedToken", "Chris")), 0x123);
    /// ex4 - mapping(string => uint) tokenIndex;
    /// tokenIndex["TOKEN"] = 1; replace to set(keccak256(abi.encodePacked("tokenIndex", "TOKEN"), 1);
    /// ex5 - mapping(string => SymbolDetails) registeredSymbols; where SymbolDetails is the structure having different type of values as
    /// {uint256 date, string name, address owner} etc.
    /// registeredSymbols["TOKEN"].name = "MyFristToken"; replace to set(keccak256(abi.encodePacked("registeredSymbols_name", "TOKEN"), "MyFirstToken");
    /// More generalized- set(keccak256(abi.encodePacked("registeredSymbols_<struct variable>", "keyname"), "value");

    function set(bytes32 _key, uint256 _value) internal {
        uintStorage[_key] = _value;
    }

    function set(bytes32 _key, address _value) internal {
        addressStorage[_key] = _value;
    }

    function set(bytes32 _key, bool _value) internal {
        boolStorage[_key] = _value;
    }

    function set(bytes32 _key, bytes32 _value) internal {
        bytes32Storage[_key] = _value;
    }

    function set(bytes32 _key, string _value) internal {
        stringStorage[_key] = _value;
    }

    ////////////////////
    /// get functions
    ////////////////////
    /// @notice Get function use to get the value of the singleton state variables
    /// Ex1- string public version = "0.0.1";
    /// string _version = getString(keccak256(abi.encodePacked("version"));
    /// Ex2 - assert(temp1 == temp2); replace to
    /// assert(getUint(keccak256(abi.encodePacked(temp1)) == getUint(keccak256(abi.encodePacked(temp2));
    /// Ex3 - mapping(string => SymbolDetails) registeredSymbols; where SymbolDetails is the structure having different type of values as
    /// {uint256 date, string name, address owner} etc.
    /// string _name = getString(keccak256(abi.encodePacked("registeredSymbols_name", "TOKEN"));

    function getBool(bytes32 _key) internal view returns (bool) {
        return boolStorage[_key];
    }

    function getUint(bytes32 _key) internal view returns (uint256) {
        return uintStorage[_key];
    }

    function getAddress(bytes32 _key) internal view returns (address) {
        return addressStorage[_key];
    }

    function getString(bytes32 _key) internal view returns (string) {
        return stringStorage[_key];
    }

    function getBytes32(bytes32 _key) internal view returns (bytes32) {
        return bytes32Storage[_key];
    }


    ////////////////////////////
    // deleteArray functions
    ////////////////////////////
    /// @notice Function used to delete the array element.
    /// Ex1- mapping(address => bytes32[]) tokensOwnedByOwner;
    /// For deleting the item from array developers needs to create a funtion for that similarly
    /// in this case we have the helper function deleteArrayBytes32() which will do it for us
    /// deleteArrayBytes32(keccak256(abi.encodePacked("tokensOwnedByOwner", 0x1), 3); -- it will delete the index 3


    //Deletes from mapping (bytes32 => array[]) at index _index
    function deleteArrayAddress(bytes32 _key, uint256 _index) internal {
        address[] storage array = addressArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

    //Deletes from mapping (bytes32 => bytes32[]) at index _index
    function deleteArrayBytes32(bytes32 _key, uint256 _index) internal {
        bytes32[] storage array = bytes32ArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

    //Deletes from mapping (bytes32 => uint[]) at index _index
    function deleteArrayUint(bytes32 _key, uint256 _index) internal {
        uint256[] storage array = uintArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

    //Deletes from mapping (bytes32 => string[]) at index _index
    function deleteArrayString(bytes32 _key, uint256 _index) internal {
        string[] storage array = stringArrayStorage[_key];
        require(_index < array.length, "Index should less than length of the array");
        array[_index] = array[array.length - 1];
        array.length = array.length - 1;
    }

    ////////////////////////////
    //// pushArray functions
    ///////////////////////////
    /// @notice Below are the helper functions to facilitate storing arrays of different data types.
    /// Ex1- mapping(address => bytes32[]) tokensOwnedByTicker;
    /// tokensOwnedByTicker[owner] = tokensOwnedByTicker[owner].push("xyz"); replace with
    /// pushArray(keccak256(abi.encodePacked("tokensOwnedByTicker", owner), "xyz");

    /// @notice use to store the values for the array
    /// @param _key bytes32 type
    /// @param _value [uint256, string, bytes32, address] any of the data type in array
    function pushArray(bytes32 _key, address _value) internal {
        addressArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, bytes32 _value) internal {
        bytes32ArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, string _value) internal {
        stringArrayStorage[_key].push(_value);
    }

    function pushArray(bytes32 _key, uint256 _value) internal {
        uintArrayStorage[_key].push(_value);
    }

    /////////////////////////
    //// Set Array functions
    ////////////////////////
    /// @notice used to intialize the array
    /// Ex1- mapping (address => address[]) public reputation;
    /// reputation[0x1] = new address[](0); It can be replaced as
    /// setArray(hash(&#39;reputation&#39;, 0x1), new address[](0)); 
    
    function setArray(bytes32 _key, address[] _value) internal {
        addressArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, uint256[] _value) internal {
        uintArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, bytes32[] _value) internal {
        bytes32ArrayStorage[_key] = _value;
    }

    function setArray(bytes32 _key, string[] _value) internal {
        stringArrayStorage[_key] = _value;
    }

    /////////////////////////
    /// getArray functions
    /////////////////////////
    /// @notice Get functions to get the array of the required data type
    /// Ex1- mapping(address => bytes32[]) tokensOwnedByOwner;
    /// getArrayBytes32(keccak256(abi.encodePacked("tokensOwnedByOwner", 0x1)); It return the bytes32 array
    /// Ex2- uint256 _len =  tokensOwnedByOwner[0x1].length; replace with
    /// getArrayBytes32(keccak256(abi.encodePacked("tokensOwnedByOwner", 0x1)).length;

    function getArrayAddress(bytes32 _key) internal view returns(address[]) {
        return addressArrayStorage[_key];
    }

    function getArrayBytes32(bytes32 _key) internal view returns(bytes32[]) {
        return bytes32ArrayStorage[_key];
    }

    function getArrayString(bytes32 _key) internal view returns(string[]) {
        return stringArrayStorage[_key];
    }

    function getArrayUint(bytes32 _key) internal view returns(uint[]) {
        return uintArrayStorage[_key];
    }

    ///////////////////////////////////
    /// setArrayIndexValue() functions
    ///////////////////////////////////
    /// @notice set the value of particular index of the address array
    /// Ex1- mapping(bytes32 => address[]) moduleList;
    /// general way is -- moduleList[moduleType][index] = temp; 
    /// It can be re-write as -- setArrayIndexValue(keccak256(abi.encodePacked(&#39;moduleList&#39;, moduleType)), index, temp); 

    function setArrayIndexValue(bytes32 _key, uint256 _index, address _value) internal {
        addressArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, uint256 _value) internal {
        uintArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, bytes32 _value) internal {
        bytes32ArrayStorage[_key][_index] = _value;
    }

    function setArrayIndexValue(bytes32 _key, uint256 _index, string _value) internal {
        stringArrayStorage[_key][_index] = _value;
    }

        /////////////////////////////
        /// Public getters functions
        /////////////////////////////

    function getUintValues(bytes32 _variable) public view returns(uint256) {
        return uintStorage[_variable];
    }

    function getBoolValues(bytes32 _variable) public view returns(bool) {
        return boolStorage[_variable];
    }

    function getStringValues(bytes32 _variable) public view returns(string) {
        return stringStorage[_variable];
    }

    function getAddressValues(bytes32 _variable) public view returns(address) {
        return addressStorage[_variable];
    }

    function getBytes32Values(bytes32 _variable) public view returns(bytes32) {
        return bytes32Storage[_variable];
    }

    function getBytesValues(bytes32 _variable) public view returns(bytes) {
        return bytesStorage[_variable];
    }

}

// File: contracts/proxy/Proxy.sol

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function _implementation() internal view returns (address);

    /**
    * @dev Fallback function.
    * Implemented entirely in `_fallback`.
    */
    function _fallback() internal {
        _delegate(_implementation());
    }

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function _delegate(address implementation) internal {
        /*solium-disable-next-line security/no-inline-assembly*/
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)

            // Call the implementation.
            // out and outsize are 0 because we don&#39;t know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

    function () public payable {
        _fallback();
    }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

// File: contracts/proxy/UpgradeabilityProxy.sol

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {

    // Version name of the current implementation
    string internal __version;

    // Address of the current implementation
    address internal __implementation;

    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param _newVersion representing the version name of the upgraded implementation
    * @param _newImplementation representing the address of the upgraded implementation
    */
    event Upgraded(string _newVersion, address indexed _newImplementation);

    /**
    * @dev Upgrades the implementation address
    * @param _newVersion representing the version name of the new implementation to be set
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(string _newVersion, address _newImplementation) internal {
        require(
            __implementation != _newImplementation && _newImplementation != address(0),
            "Old address is not allowed and implementation address should not be 0x"
        );
        require(AddressUtils.isContract(_newImplementation), "Cannot set a proxy implementation to a non-contract address");
        require(bytes(_newVersion).length > 0, "Version should not be empty string");
        require(keccak256(abi.encodePacked(__version)) != keccak256(abi.encodePacked(_newVersion)), "New version equals to current");
        __version = _newVersion;
        __implementation = _newImplementation;
        emit Upgraded(_newVersion, _newImplementation);
    }

}

// File: contracts/proxy/OwnedUpgradeabilityProxy.sol

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {

    // Owner of the contract
    address private __upgradeabilityOwner;

    /**
    * @dev Event to show ownership has been transferred
    * @param _previousOwner representing the address of the previous owner
    * @param _newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address _previousOwner, address _newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier ifOwner() {
        if (msg.sender == _upgradeabilityOwner()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function _upgradeabilityOwner() internal view returns (address) {
        return __upgradeabilityOwner;
    }

    /**
    * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newUpgradeabilityOwner) internal {
        require(_newUpgradeabilityOwner != address(0), "Address should not be 0x");
        __upgradeabilityOwner = _newUpgradeabilityOwner;
    }

    /**
    * @notice Internal function to provide the address of the implementation contract
    */
    function _implementation() internal view returns (address) {
        return __implementation;
    }

    /**
    * @dev Tells the address of the proxy owner
    * @return the address of the proxy owner
    */
    function proxyOwner() external ifOwner returns (address) {
        return _upgradeabilityOwner();
    }

    /**
    * @dev Tells the version name of the current implementation
    * @return string representing the name of the current version
    */
    function version() external ifOwner returns (string) {
        return __version;
    }

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() external ifOwner returns (address) {
        return _implementation();
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) external ifOwner {
        require(_newOwner != address(0), "Address should not be 0x");
        emit ProxyOwnershipTransferred(_upgradeabilityOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

    /**
    * @dev Allows the upgradeability owner to upgrade the current version of the proxy.
    * @param _newVersion representing the version name of the new implementation to be set.
    * @param _newImplementation representing the address of the new implementation to be set.
    */
    function upgradeTo(string _newVersion, address _newImplementation) external ifOwner {
        _upgradeTo(_newVersion, _newImplementation);
    }

    /**
    * @dev Allows the upgradeability owner to upgrade the current version of the proxy and call the new implementation
    * to initialize whatever is needed through a low level call.
    * @param _newVersion representing the version name of the new implementation to be set.
    * @param _newImplementation representing the address of the new implementation to be set.
    * @param _data represents the msg.data to bet sent in the low level call. This parameter may include the function
    * signature of the implementation to be called with the needed payload
    */
    function upgradeToAndCall(string _newVersion, address _newImplementation, bytes _data) external payable ifOwner {
        _upgradeTo(_newVersion, _newImplementation);
        /*solium-disable-next-line security/no-call-value*/
        require(address(this).call.value(msg.value)(_data), "Fail in executing the function of implementation contract");
    }

}

// File: contracts/proxy/SecurityTokenRegistryProxy.sol

/**
 * @title SecurityTokenRegistryProxy
 * @dev This proxy holds the storage of the SecurityTokenRegistry contract and delegates every call to the current implementation set.
 * Besides, it allows to upgrade the SecurityTokenRegistry&#39;s behaviour towards further implementations, and provides basic
 * authorization control functionalities
 */
/*solium-disable-next-line no-empty-blocks*/
contract SecurityTokenRegistryProxy is EternalStorage, OwnedUpgradeabilityProxy {

}