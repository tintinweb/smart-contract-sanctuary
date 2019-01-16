pragma solidity ^0.4.24;

// File: contracts/interfaces/IModuleRegistry.sol

/**
 * @title Interface for the Polymath Module Registry contract
 */
interface IModuleRegistry {

    /**
     * @notice Called by a security token to notify the registry it is using a module
     * @param _moduleFactory is the address of the relevant module factory
     */
    function useModule(address _moduleFactory) external;

    /**
     * @notice Called by the ModuleFactory owner to register new modules for SecurityToken to use
     * @param _moduleFactory is the address of the module factory to be registered
     */
    function registerModule(address _moduleFactory) external;

    /**
     * @notice Called by the ModuleFactory owner or registry curator to delete a ModuleFactory
     * @param _moduleFactory is the address of the module factory to be deleted
     */
    function removeModule(address _moduleFactory) external;

    /**
    * @notice Called by Polymath to verify modules for SecurityToken to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST - Only if enabled by the FeatureRegistry)
    * @param _moduleFactory is the address of the module factory to be registered
    */
    function verifyModule(address _moduleFactory, bool _verified) external;

    /**
     * @notice Used to get the reputation of a Module Factory
     * @param _factoryAddress address of the Module Factory
     * @return address array which has the list of securityToken&#39;s uses that module factory
     */
    function getReputationByFactory(address _factoryAddress) external view returns(address[]);

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @param _securityToken is the token
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(bytes32[], address[]);

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByType(uint8 _moduleType) external view returns(bytes32[], address[]);

    /**
     * @notice Returns the list of addresses of Module Factory of a particular type
     * @param _moduleType Type of Module
     * @return address array that contains the list of addresses of module factory contracts.
     */
    function getModulesByType(uint8 _moduleType) external view returns(address[]);

    /**
     * @notice Returns the list of available Module factory addresses of a particular type for a given token.
     * @param _moduleType is the module type to look for
     * @param _securityToken is the address of SecurityToken
     * @return address array that contains the list of available addresses of module factory contracts.
     */
    function getModulesByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns (address[]);

    /**
     * @notice Use to get the latest contract address of the regstries
     */
    function updateFromRegistry() external;

    /**
     * @notice Get the owner of the contract
     * @return address owner
     */
    function owner() external view returns(address);

    /**
     * @notice Check whether the contract operations is paused or not
     * @return bool 
     */
    function isPaused() external view returns(bool);

}

// File: contracts/interfaces/IModuleFactory.sol

/**
 * @title Interface that every module factory contract should implement
 */
interface IModuleFactory {

    event ChangeFactorySetupFee(uint256 _oldSetupCost, uint256 _newSetupCost, address _moduleFactory);
    event ChangeFactoryUsageFee(uint256 _oldUsageCost, uint256 _newUsageCost, address _moduleFactory);
    event ChangeFactorySubscriptionFee(uint256 _oldSubscriptionCost, uint256 _newMonthlySubscriptionCost, address _moduleFactory);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _timestamp
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

    //Should create an instance of the Module, or throw
    function deploy(bytes _data) external returns(address);

    /**
     * @notice Type of the Module factory
     */
    function getTypes() external view returns(uint8[]);

    /**
     * @notice Get the name of the Module
     */
    function getName() external view returns(bytes32);

    /**
     * @notice Returns the instructions associated with the module
     */
    function getInstructions() external view returns (string);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() external view returns (bytes32[]);

    /**
     * @notice Used to change the setup fee
     * @param _newSetupCost New setup fee
     */
    function changeFactorySetupFee(uint256 _newSetupCost) external;

    /**
     * @notice Used to change the usage fee
     * @param _newUsageCost New usage fee
     */
    function changeFactoryUsageFee(uint256 _newUsageCost) external;

    /**
     * @notice Used to change the subscription fee
     * @param _newSubscriptionCost New subscription fee
     */
    function changeFactorySubscriptionFee(uint256 _newSubscriptionCost) external;

    /**
     * @notice Function use to change the lower and upper bound of the compatible version st
     * @param _boundType Type of bound
     * @param _newVersion New version array
     */
    function changeSTVersionBounds(string _boundType, uint8[] _newVersion) external;

   /**
     * @notice Get the setup cost of the module
     */
    function getSetupCost() external view returns (uint256);

    /**
     * @notice Used to get the lower bound
     * @return Lower bound
     */
    function getLowerSTVersionBounds() external view returns(uint8[]);

     /**
     * @notice Used to get the upper bound
     * @return Upper bound
     */
    function getUpperSTVersionBounds() external view returns(uint8[]);

}

// File: contracts/interfaces/ISecurityTokenRegistry.sol

/**
 * @title Interface for the Polymath Security Token Registry contract
 */
interface ISecurityTokenRegistry {

   /**
     * @notice Creates a new Security Token and saves it to the registry
     * @param _name Name of the token
     * @param _ticker Ticker ticker of the security token
     * @param _tokenDetails Off-chain details of the token
     * @param _divisible Whether the token is divisible or not
     */
    function generateSecurityToken(string _name, string _ticker, string _tokenDetails, bool _divisible) external;

    /**
     * @notice Adds a new custom Security Token and saves it to the registry. (Token should follow the ISecurityToken interface)
     * @param _name Name of the token
     * @param _ticker Ticker of the security token
     * @param _owner Owner of the token
     * @param _securityToken Address of the securityToken
     * @param _tokenDetails Off-chain details of the token
     * @param _deployedAt Timestamp at which security token comes deployed on the ethereum blockchain
     */
    function modifySecurityToken(
        string _name,
        string _ticker,
        address _owner,
        address _securityToken,
        string _tokenDetails,
        uint256 _deployedAt
    )
        external;

    /**
     * @notice Registers the token ticker for its particular owner
     * @notice once the token ticker is registered to its owner then no other issuer can claim
     * @notice its ownership. If the ticker expires and its issuer hasn&#39;t used it, then someone else can take it.
     * @param _owner Address of the owner of the token
     * @param _ticker Token ticker
     * @param _tokenName Name of the token
     */
    function registerTicker(address _owner, string _ticker, string _tokenName) external;

    /**
    * @notice Changes the protocol version and the SecurityToken contract
    * @notice Used only by Polymath to upgrade the SecurityToken contract and add more functionalities to future versions
    * @notice Changing versions does not affect existing tokens.
    * @param _STFactoryAddress Address of the proxy.
    * @param _major Major version of the proxy.
    * @param _minor Minor version of the proxy.
    * @param _patch Patch version of the proxy
    */
    function setProtocolVersion(address _STFactoryAddress, uint8 _major, uint8 _minor, uint8 _patch) external;

    /**
    * @notice Check that Security Token is registered
    * @param _securityToken Address of the Scurity token
    * @return bool
    */
    function isSecurityToken(address _securityToken) external view returns (bool);

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;

    /**
     * @notice Get security token address by ticker name
     * @param _ticker Symbol of the Scurity token
     * @return address
     */
    function getSecurityTokenAddress(string _ticker) external view returns (address);

     /**
     * @notice Get security token data by its address
     * @param _securityToken Address of the Scurity token.
     * @return string Symbol of the Security Token.
     * @return address Address of the issuer of Security Token.
     * @return string Details of the Token.
     * @return uint256 Timestamp at which Security Token get launched on Polymath platform.
     */
    function getSecurityTokenData(address _securityToken) external view returns (string, address, string, uint256);

    /**
     * @notice Get the current STFactory Address
     */
    function getSTFactoryAddress() external view returns(address);

    /**
     * @notice Get Protocol version
     */
    function getProtocolVersion() external view returns(uint8[]);

    /**
     * @notice Used to get the ticker list as per the owner
     * @param _owner Address which owns the list of tickers
     */
    function getTickersByOwner(address _owner) external view returns(bytes32[]);

    /**
     * @notice Returns the list of tokens owned by the selected address
     * @param _owner is the address which owns the list of tickers
     * @dev Intention is that this is called off-chain so block gas limit is not relevant
     */
    function getTokensByOwner(address _owner) external view returns(address[]);

    /**
     * @notice Returns the owner and timestamp for a given ticker
     * @param _ticker ticker
     * @return address
     * @return uint256
     * @return uint256
     * @return string
     * @return bool
     */
    function getTickerDetails(string _ticker) external view returns (address, uint256, uint256, string, bool);

    /**
     * @notice Modifies the ticker details. Only polymath account has the ability
     * to do so. Only allowed to modify the tickers which are not yet deployed
     * @param _owner Owner of the token
     * @param _ticker Token ticker
     * @param _tokenName Name of the token
     * @param _registrationDate Date on which ticker get registered
     * @param _expiryDate Expiry date of the ticker
     * @param _status Token deployed status
     */
    function modifyTicker(
        address _owner,
        string _ticker,
        string _tokenName,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
    )
        external;

     /**
     * @notice Removes the ticker details and associated ownership & security token mapping
     * @param _ticker Token ticker
     */
    function removeTicker(string _ticker) external;

    /**
     * @notice Transfers the ownership of the ticker
     * @dev _newOwner Address whom ownership to transfer
     * @dev _ticker Ticker
     */
    function transferTickerOwnership(address _newOwner, string _ticker) external;

    /**
     * @notice Changes the expiry time for the token ticker
     * @param _newExpiry New time period for token ticker expiry
     */
    function changeExpiryLimit(uint256 _newExpiry) external;

    /**
    * @notice Sets the ticker registration fee in POLY tokens
    * @param _tickerRegFee Registration fee in POLY tokens (base 18 decimals)
    */
   function changeTickerRegistrationFee(uint256 _tickerRegFee) external;

   /**
    * @notice Sets the ticker registration fee in POLY tokens
    * @param _stLaunchFee Registration fee in POLY tokens (base 18 decimals)
    */
   function changeSecurityLaunchFee(uint256 _stLaunchFee) external;

    /**
     * @notice Change the PolyToken address
     * @param _newAddress Address of the polytoken
     */
    function updatePolyTokenAddress(address _newAddress) external;

    /**
     * @notice Gets the security token launch fee
     * @return Fee amount
     */
    function getSecurityTokenLaunchFee() external view returns(uint256);

    /**
     * @notice Gets the ticker registration fee
     * @return Fee amount
     */
    function getTickerRegistrationFee() external view returns(uint256);

    /**
     * @notice Gets the expiry limit
     * @return Expiry limit
     */
    function getExpiryLimit() external view returns(uint256);

    /**
     * @notice Checks whether the registry is paused or not
     * @return bool
     */
    function isPaused() external view returns(bool);

    /**
     * @notice Gets the owner of the contract
     * @return address owner
     */
    function owner() external view returns(address);

}

// File: contracts/interfaces/IPolymathRegistry.sol

interface IPolymathRegistry {

    /**
     * @notice Returns the contract address
     * @param _nameKey is the key for the contract address mapping
     * @return address
     */
    function getAddress(string _nameKey) external view returns(address);

}

// File: contracts/interfaces/IFeatureRegistry.sol

/**
 * @title Interface for managing polymath feature switches
 */
interface IFeatureRegistry {

    /**
     * @notice Get the status of a feature
     * @param _nameKey is the key for the feature status mapping
     * @return bool
     */
    function getFeatureStatus(string _nameKey) external view returns(bool);

}

// File: contracts/interfaces/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libraries/VersionUtils.sol

/**
 * @title Helper library use to compare or validate the semantic versions
 */

library VersionUtils {

    /**
     * @notice This function is used to validate the version submitted
     * @param _current Array holds the present version of ST
     * @param _new Array holds the latest version of the ST
     * @return bool
     */
    function isValidVersion(uint8[] _current, uint8[] _new) internal pure returns(bool) {
        bool[] memory _temp = new bool[](_current.length);
        uint8 counter = 0;
        for (uint8 i = 0; i < _current.length; i++) {
            if (_current[i] < _new[i])
                _temp[i] = true;
            else
                _temp[i] = false;
        }

        for (i = 0; i < _current.length; i++) {
            if (i == 0) {
                if (_current[i] <= _new[i])
                    if(_temp[0]) {
                        counter = counter + 3;
                        break;
                    } else
                        counter++;
                else
                    return false;
            } else {
                if (_temp[i-1])
                    counter++;
                else if (_current[i] <= _new[i])
                    counter++;
                else
                    return false;
            }
        }
        if (counter == _current.length)
            return true;
    }

    /**
     * @notice Used to compare the lower bound with the latest version
     * @param _version1 Array holds the lower bound of the version
     * @param _version2 Array holds the latest version of the ST
     * @return bool
     */
    function compareLowerBound(uint8[] _version1, uint8[] _version2) internal pure returns(bool) {
        require(_version1.length == _version2.length, "Input length mismatch");
        uint counter = 0;
        for (uint8 j = 0; j < _version1.length; j++) {
            if (_version1[j] == 0)
                counter ++;
        }
        if (counter != _version1.length) {
            counter = 0;
            for (uint8 i = 0; i < _version1.length; i++) {
                if (_version2[i] > _version1[i])
                    return true;
                else if (_version2[i] < _version1[i])
                    return false;
                else
                    counter++;
            }
            if (counter == _version1.length - 1)
                return true;
            else
                return false;
        } else
            return true;
    }

    /**
     * @notice Used to compare the upper bound with the latest version
     * @param _version1 Array holds the upper bound of the version
     * @param _version2 Array holds the latest version of the ST
     * @return bool
     */
    function compareUpperBound(uint8[] _version1, uint8[] _version2) internal pure returns(bool) {
        require(_version1.length == _version2.length, "Input length mismatch");
        uint counter = 0;
        for (uint8 j = 0; j < _version1.length; j++) {
            if (_version1[j] == 0)
                counter ++;
        }
        if (counter != _version1.length) {
            counter = 0;
            for (uint8 i = 0; i < _version1.length; i++) {
                if (_version1[i] > _version2[i])
                    return true;
                else if (_version1[i] < _version2[i])
                    return false;
                else
                    counter++;
            }
            if (counter == _version1.length - 1)
                return true;
            else
                return false;
        } else
            return true;
    }


    /**
     * @notice Used to pack the uint8[] array data into uint24 value
     * @param _major Major version
     * @param _minor Minor version
     * @param _patch Patch version
     */
    function pack(uint8 _major, uint8 _minor, uint8 _patch) internal pure returns(uint24) {
        return (uint24(_major) << 16) | (uint24(_minor) << 8) | uint24(_patch);
    }

    /**
     * @notice Used to convert packed data into uint8 array
     * @param _packedVersion Packed data
     */
    function unpack(uint24 _packedVersion) internal pure returns (uint8[]) {
        uint8[] memory _unpackVersion = new uint8[](3);
        _unpackVersion[0] = uint8(_packedVersion >> 16);
        _unpackVersion[1] = uint8(_packedVersion >> 8);
        _unpackVersion[2] = uint8(_packedVersion);
        return _unpackVersion;
    }


}

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

// File: contracts/libraries/Encoder.sol

library Encoder {

    function getKey(string _key) internal pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key)));
    }

    function getKey(string _key1, address _key2) internal pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string _key1, string _key2) internal pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string _key1, uint256 _key2) internal pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string _key1, bytes32 _key2) internal pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function getKey(string _key1, bool _key2) internal pure returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

}

// File: contracts/interfaces/IOwnable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
interface IOwnable {
    /**
    * @dev Returns owner
    */
    function owner() external view returns (address);

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() external;

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;

}

// File: contracts/interfaces/ISecurityToken.sol

/**
 * @title Interface for all security tokens
 */
interface ISecurityToken {

    // Standard ERC20 interface
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //transfer, transferFrom must respect the result of verifyTransfer
    function verifyTransfer(address _from, address _to, uint256 _value) external returns (bool success);

    /**
     * @notice Mints new tokens and assigns them to the target _investor.
     * Can only be called by the STO attached to the token (Or by the ST owner if there&#39;s no STO attached yet)
     * @param _investor Address the tokens will be minted to
     * @param _value is the amount of tokens that will be minted to the investor
     */
    function mint(address _investor, uint256 _value) external returns (bool success);

    /**
     * @notice Mints new tokens and assigns them to the target _investor.
     * Can only be called by the STO attached to the token (Or by the ST owner if there&#39;s no STO attached yet)
     * @param _investor Address the tokens will be minted to
     * @param _value is The amount of tokens that will be minted to the investor
     * @param _data Data to indicate validation
     */
    function mintWithData(address _investor, uint256 _value, bytes _data) external returns (bool success);

    /**
     * @notice Used to burn the securityToken on behalf of someone else
     * @param _from Address for whom to burn tokens
     * @param _value No. of tokens to be burned
     * @param _data Data to indicate validation
     */
    function burnFromWithData(address _from, uint256 _value, bytes _data) external;

    /**
     * @notice Used to burn the securityToken
     * @param _value No. of tokens to be burned
     * @param _data Data to indicate validation
     */
    function burnWithData(uint256 _value, bytes _data) external;

    event Minted(address indexed _to, uint256 _value);
    event Burnt(address indexed _burner, uint256 _value);

    // Permissions this to a Permission module, which has a key of 1
    // If no Permission return false - note that IModule withPerm will allow ST owner all permissions anyway
    // this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns (bool);

    /**
     * @notice Returns module list for a module type
     * @param _module Address of the module
     * @return bytes32 Name
     * @return address Module address
     * @return address Module factory address
     * @return bool Module archived
     * @return uint8 Module type
     * @return uint256 Module index
     * @return uint256 Name index

     */
    function getModule(address _module) external view returns(bytes32, address, address, bool, uint8, uint256, uint256);

    /**
     * @notice Returns module list for a module name
     * @param _name Name of the module
     * @return address[] List of modules with this name
     */
    function getModulesByName(bytes32 _name) external view returns (address[]);

    /**
     * @notice Returns module list for a module type
     * @param _type Type of the module
     * @return address[] List of modules with this type
     */
    function getModulesByType(uint8 _type) external view returns (address[]);

    /**
     * @notice Queries totalSupply at a specified checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) external view returns (uint256);

    /**
     * @notice Queries balance at a specified checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns (uint256);

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() external returns (uint256);

    /**
     * @notice Gets length of investors array
     * NB - this length may differ from investorCount if the list has not been pruned of zero-balance investors
     * @return Length
     */
    function getInvestors() external view returns (address[]);

    /**
     * @notice returns an array of investors at a given checkpoint
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @return list of investors
     */
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[]);

    /**
     * @notice generates subset of investors
     * NB - can be used in batches if investor list is large
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[]);
    
    /**
     * @notice Gets current checkpoint ID
     * @return Id
     */
    function currentCheckpointId() external view returns (uint256);

    /**
    * @notice Gets an investor at a particular index
    * @param _index Index to return address from
    * @return Investor address
    */
    function investors(uint256 _index) external view returns (address);

   /**
    * @notice Allows the owner to withdraw unspent POLY stored by them on the ST or any ERC20 token.
    * @dev Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
    * @param _tokenContract Address of the ERC20Basic compliance token
    * @param _value Amount of POLY to withdraw
    */
    function withdrawERC20(address _tokenContract, uint256 _value) external;

    /**
    * @notice Allows owner to approve more POLY to one of the modules
    * @param _module Module address
    * @param _budget New budget
    */
    function changeModuleBudget(address _module, uint256 _budget) external;

    /**
     * @notice Changes the tokenDetails
     * @param _newTokenDetails New token details
     */
    function updateTokenDetails(string _newTokenDetails) external;

    /**
    * @notice Allows the owner to change token granularity
    * @param _granularity Granularity level of the token
    */
    function changeGranularity(uint256 _granularity) external;

    /**
    * @notice Removes addresses with zero balances from the investors list
    * @param _start Index in investors list at which to start removing zero balances
    * @param _iters Max number of iterations of the for loop
    * NB - pruning this list will mean you may not be able to iterate over investors on-chain as of a historical checkpoint
    */
    function pruneInvestors(uint256 _start, uint256 _iters) external;

    /**
     * @notice Freezes all the transfers
     */
    function freezeTransfers() external;

    /**
     * @notice Un-freezes all the transfers
     */
    function unfreezeTransfers() external;

    /**
     * @notice Ends token minting period permanently
     */
    function freezeMinting() external;

    /**
     * @notice Mints new tokens and assigns them to the target investors.
     * Can only be called by the STO attached to the token or by the Issuer (Security Token contract owner)
     * @param _investors A list of addresses to whom the minted tokens will be delivered
     * @param _values A list of the amount of tokens to mint to corresponding addresses from _investor[] list
     * @return Success
     */
    function mintMulti(address[] _investors, uint256[] _values) external returns (bool success);

    /**
     * @notice Function used to attach a module to the security token
     * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
     * @dev to control restrictions on transfers.
     * @dev You are allowed to add a new moduleType if:
     * @dev - there is no existing module of that type yet added
     * @dev - the last member of the module list is replacable
     * @param _moduleFactory is the address of the module factory to be added
     * @param _data is data packed into bytes used to further configure the module (See STO usage)
     * @param _maxCost max amount of POLY willing to pay to module. (WIP)
     */
    function addModule(
        address _moduleFactory,
        bytes _data,
        uint256 _maxCost,
        uint256 _budget
    ) external;

    /**
    * @notice Archives a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function archiveModule(address _module) external;

    /**
    * @notice Unarchives a module attached to the SecurityToken
    * @param _module address of module to unarchive
    */
    function unarchiveModule(address _module) external;

    /**
    * @notice Removes a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function removeModule(address _module) external;

    /**
     * @notice Used by the issuer to set the controller addresses
     * @param _controller address of the controller
     */
    function setController(address _controller) external;

    /**
     * @notice Used by a controller to execute a forced transfer
     * @param _from address from which to take tokens
     * @param _to address where to send tokens
     * @param _value amount of tokens to transfer
     * @param _data data to indicate validation
     * @param _log data attached to the transfer by controller to emit in event
     */
    function forceTransfer(address _from, address _to, uint256 _value, bytes _data, bytes _log) external;

    /**
     * @notice Used by a controller to execute a foced burn
     * @param _from address from which to take tokens
     * @param _value amount of tokens to transfer
     * @param _data data to indicate validation
     * @param _log data attached to the transfer by controller to emit in event
     */
    function forceBurn(address _from, uint256 _value, bytes _data, bytes _log) external;

    /**
     * @notice Used by the issuer to permanently disable controller functionality
     * @dev enabled via feature switch "disableControllerAllowed"
     */
     function disableController() external;

     /**
     * @notice Used to get the version of the securityToken
     */
     function getVersion() external view returns(uint8[]);

     /**
     * @notice Gets the investor count
     */
     function getInvestorCount() external view returns(uint256);

     /**
      * @notice Overloaded version of the transfer function
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
     function transferWithData(address _to, uint256 _value, bytes _data) external returns (bool success);

     /**
      * @notice Overloaded version of the transferFrom function
      * @param _from sender of transfer
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
     function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) external returns(bool);

     /**
      * @notice Provides the granularity of the token
      * @return uint256
      */
     function granularity() external view returns(uint256);
}

// File: contracts/ModuleRegistry.sol

/**
* @title Registry contract to store registered modules
* @notice Only Polymath can register and verify module factories to make them available for issuers to attach.
*/
contract ModuleRegistry is IModuleRegistry, EternalStorage {
    /*
        // Mapping used to hold the type of module factory corresponds to the address of the Module factory contract
        mapping (address => uint8) public registry;

        // Mapping used to hold the reputation of the factory
        mapping (address => address[]) public reputation;

        // Mapping containing the list of addresses of Module Factories of a particular type
        mapping (uint8 => address[]) public moduleList;

        // Mapping to store the index of the Module Factory in the moduleList
        mapping(address => uint8) private moduleListIndex;

        // contains the list of verified modules
        mapping (address => bool) public verified;

    */

    ///////////
    // Events
    //////////

    // Emit when network becomes paused
    event Pause(uint256 _timestammp);
     // Emit when network becomes unpaused
    event Unpause(uint256 _timestamp);
    // Emit when Module is used by the SecurityToken
    event ModuleUsed(address indexed _moduleFactory, address indexed _securityToken);
    // Emit when the Module Factory gets registered on the ModuleRegistry contract
    event ModuleRegistered(address indexed _moduleFactory, address indexed _owner);
    // Emit when the module gets verified by Polymath
    event ModuleVerified(address indexed _moduleFactory, bool _verified);
    // Emit when a ModuleFactory is removed by Polymath
    event ModuleRemoved(address indexed _moduleFactory, address indexed _decisionMaker);
    // Emit when ownership gets transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    ///////////////
    //// Modifiers
    ///////////////

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner(),"sender must be owner");
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPausedOrOwner() {
        if (msg.sender == owner())
            _;
        else {
            require(!isPaused(), "Already paused");
            _;
        }
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused and ignore is msg.sender is owner.
     */
    modifier whenNotPaused() {
        require(!isPaused(), "Already paused");
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(isPaused(), "Should not be paused");
        _;
    }

    /////////////////////////////
    // Initialization
    /////////////////////////////

    // Constructor
    constructor () public
    {

    }

    function initialize(address _polymathRegistry, address _owner) external payable {
        require(!getBool(Encoder.getKey("initialised")),"already initialized");
        require(_owner != address(0) && _polymathRegistry != address(0), "0x address is invalid");
        set(Encoder.getKey("polymathRegistry"), _polymathRegistry);
        set(Encoder.getKey("owner"), _owner);
        set(Encoder.getKey("paused"), false);
        set(Encoder.getKey("initialised"), true);
    }

    /**
     * @notice Called by a SecurityToken to check if the ModuleFactory is verified or appropriate custom module
     * @dev ModuleFactory reputation increases by one every time it is deployed(used) by a ST.
     * @dev Any module can be added during token creation without being registered if it is defined in the token proxy deployment contract
     * @dev The feature switch for custom modules is labelled "customModulesAllowed"
     * @param _moduleFactory is the address of the relevant module factory
     */
    function useModule(address _moduleFactory) external {
        // This if statement is required to be able to add modules from the token proxy contract during deployment
        if (ISecurityTokenRegistry(getAddress(Encoder.getKey("securityTokenRegistry"))).isSecurityToken(msg.sender)) {
            if (IFeatureRegistry(getAddress(Encoder.getKey("featureRegistry"))).getFeatureStatus("customModulesAllowed")) {
                require(getBool(Encoder.getKey("verified", _moduleFactory)) || IOwnable(_moduleFactory).owner() == IOwnable(msg.sender).owner(),"ModuleFactory must be verified or SecurityToken owner must be ModuleFactory owner");
            } else {
                require(getBool(Encoder.getKey("verified", _moduleFactory)), "ModuleFactory must be verified");
            }
            require(_isCompatibleModule(_moduleFactory, msg.sender), "Version should within the compatible range of ST");
            pushArray(Encoder.getKey("reputation", _moduleFactory), msg.sender);
            emit ModuleUsed(_moduleFactory, msg.sender);
        }
    }

    function _isCompatibleModule(address _moduleFactory, address _securityToken) internal view returns(bool) {
        uint8[] memory _latestVersion = ISecurityToken(_securityToken).getVersion();
        uint8[] memory _lowerBound = IModuleFactory(_moduleFactory).getLowerSTVersionBounds();
        uint8[] memory _upperBound = IModuleFactory(_moduleFactory).getUpperSTVersionBounds();
        bool _isLowerAllowed = VersionUtils.compareLowerBound(_lowerBound, _latestVersion);
        bool _isUpperAllowed = VersionUtils.compareUpperBound(_upperBound, _latestVersion);
        return (_isLowerAllowed && _isUpperAllowed);
    }

    /**
     * @notice Called by the ModuleFactory owner to register new modules for SecurityTokens to use
     * @param _moduleFactory is the address of the module factory to be registered
     */
    function registerModule(address _moduleFactory) external whenNotPausedOrOwner {
        if (IFeatureRegistry(getAddress(Encoder.getKey("featureRegistry"))).getFeatureStatus("customModulesAllowed")) {
            require(msg.sender == IOwnable(_moduleFactory).owner() || msg.sender == owner(),"msg.sender must be the Module Factory owner or registry curator");
        } else {
            require(msg.sender == owner(), "Only owner allowed to register modules");
        }
        require(getUint(Encoder.getKey("registry", _moduleFactory)) == 0, "Module factory should not be pre-registered");
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactory);
        //Enforce type uniqueness
        uint256 i;
        uint256 j;
        uint8[] memory moduleTypes = moduleFactory.getTypes();
        for (i = 1; i < moduleTypes.length; i++) {
            for (j = 0; j < i; j++) {
                require(moduleTypes[i] != moduleTypes[j], "Type mismatch");
            }
        }
        require(moduleTypes.length != 0, "Factory must have type");
        // NB - here we index by the first type of the module.
        uint8 moduleType = moduleFactory.getTypes()[0];
        set(Encoder.getKey("registry", _moduleFactory), uint256(moduleType));
        set(
            Encoder.getKey("moduleListIndex", _moduleFactory),
            uint256(getArrayAddress(Encoder.getKey("moduleList", uint256(moduleType))).length)
        );
        pushArray(Encoder.getKey("moduleList", uint256(moduleType)), _moduleFactory);
        emit ModuleRegistered (_moduleFactory, IOwnable(_moduleFactory).owner());
    }

    /**
     * @notice Called by the ModuleFactory owner or registry curator to delete a ModuleFactory from the registry
     * @param _moduleFactory is the address of the module factory to be deleted from the registry
     */
    function removeModule(address _moduleFactory) external whenNotPausedOrOwner {
        uint256 moduleType = getUint(Encoder.getKey("registry", _moduleFactory));

        require(moduleType != 0, "Module factory should be registered");
        require(
            msg.sender == IOwnable(_moduleFactory).owner() || msg.sender == owner(),
            "msg.sender must be the Module Factory owner or registry curator"
        );
        uint256 index = getUint(Encoder.getKey("moduleListIndex", _moduleFactory));
        uint256 last = getArrayAddress(Encoder.getKey("moduleList", moduleType)).length - 1;
        address temp = getArrayAddress(Encoder.getKey("moduleList", moduleType))[last];

        // pop from array and re-order
        if (index != last) {
            // moduleList[moduleType][index] = temp;
            setArrayIndexValue(Encoder.getKey("moduleList", moduleType), index, temp);
            set(Encoder.getKey("moduleListIndex", temp), index);
        }
        deleteArrayAddress(Encoder.getKey("moduleList", moduleType), last);

        // delete registry[_moduleFactory];
        set(Encoder.getKey("registry", _moduleFactory), uint256(0));
        // delete reputation[_moduleFactory];
        setArray(Encoder.getKey("reputation", _moduleFactory), new address[](0));
        // delete verified[_moduleFactory];
        set(Encoder.getKey("verified", _moduleFactory), false);
        // delete moduleListIndex[_moduleFactory];
        set(Encoder.getKey("moduleListIndex", _moduleFactory), uint256(0));
        emit ModuleRemoved(_moduleFactory, msg.sender);
    }

    /**
    * @notice Called by Polymath to verify Module Factories for SecurityTokens to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST)
    * @notice -> Only if Polymath enabled the feature.
    * @param _moduleFactory is the address of the module factory to be verified
    * @return bool
    */
    function verifyModule(address _moduleFactory, bool _verified) external onlyOwner {
        require(getUint(Encoder.getKey("registry", _moduleFactory)) != uint256(0), "Module factory must be registered");
        set(Encoder.getKey("verified", _moduleFactory), _verified);
        emit ModuleVerified(_moduleFactory, _verified);
    }

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @param _securityToken is the token
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(bytes32[], address[]) {
        address[] memory modules = getModulesByTypeAndToken(_moduleType, _securityToken);
        return _tagsByModules(modules);
    }

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByType(uint8 _moduleType) external view returns(bytes32[], address[]) {
        address[] memory modules = getModulesByType(_moduleType);
        return _tagsByModules(modules);
    }

    /**
     * @notice Returns all the tags related to the modules provided
     * @param _modules modules to return tags for
     * @return list of tags
     * @return corresponding list of module factories
     */
    function _tagsByModules(address[] _modules) internal view returns(bytes32[], address[]) {
        uint256 counter = 0;
        uint256 i;
        uint256 j;
        for (i = 0; i < _modules.length; i++) {
            counter = counter + IModuleFactory(_modules[i]).getTags().length;
        }
        bytes32[] memory tags = new bytes32[](counter);
        address[] memory modules = new address[](counter);
        bytes32[] memory tempTags;
        counter = 0;
        for (i = 0; i < _modules.length; i++) {
            tempTags = IModuleFactory(_modules[i]).getTags();
            for (j = 0; j < tempTags.length; j++) {
                tags[counter] = tempTags[j];
                modules[counter] = _modules[i];
                counter++;
            }
        }
        return (tags, modules);
    }

    /**
     * @notice Returns the reputation of the entered Module Factory
     * @param _factoryAddress is the address of the module factory
     * @return address array which contains the list of securityTokens that use that module factory
     */
    function getReputationByFactory(address _factoryAddress) external view returns(address[]) {
        return getArrayAddress(Encoder.getKey("reputation", _factoryAddress));
    }

    /**
     * @notice Returns the list of addresses of Module Factory of a particular type
     * @param _moduleType Type of Module
     * @return address array that contains the list of addresses of module factory contracts.
     */
    function getModulesByType(uint8 _moduleType) public view returns(address[]) {
        return getArrayAddress(Encoder.getKey("moduleList", uint256(_moduleType)));
    }

    /**
     * @notice Returns the list of available Module factory addresses of a particular type for a given token.
     * @param _moduleType is the module type to look for
     * @param _securityToken is the address of SecurityToken
     * @return address array that contains the list of available addresses of module factory contracts.
     */
    function getModulesByTypeAndToken(uint8 _moduleType, address _securityToken) public view returns (address[]) {
        uint256 _len = getArrayAddress(Encoder.getKey("moduleList", uint256(_moduleType))).length;
        address[] memory _addressList = getArrayAddress(Encoder.getKey("moduleList", uint256(_moduleType)));
        bool _isCustomModuleAllowed = IFeatureRegistry(getAddress(Encoder.getKey("featureRegistry"))).getFeatureStatus("customModulesAllowed");
        uint256 counter = 0;
        for (uint256 i = 0; i < _len; i++) {
            if (_isCustomModuleAllowed) {
                if (IOwnable(_addressList[i]).owner() == IOwnable(_securityToken).owner() || getBool(Encoder.getKey("verified", _addressList[i])))
                    if(_isCompatibleModule(_addressList[i], _securityToken))
                        counter++;
            }
            else if (getBool(Encoder.getKey("verified", _addressList[i]))) {
                if(_isCompatibleModule(_addressList[i], _securityToken))
                    counter++;
            }
        }
        address[] memory _tempArray = new address[](counter);
        counter = 0;
        for (uint256 j = 0; j < _len; j++) {
            if (_isCustomModuleAllowed) {
                if (IOwnable(_addressList[j]).owner() == IOwnable(_securityToken).owner() || getBool(Encoder.getKey("verified", _addressList[j]))) {
                    if(_isCompatibleModule(_addressList[j], _securityToken)) {
                        _tempArray[counter] = _addressList[j];
                        counter ++;
                    }
                }
            }
            else if (getBool(Encoder.getKey("verified", _addressList[j]))) {
                if(_isCompatibleModule(_addressList[j], _securityToken)) {
                    _tempArray[counter] = _addressList[j];
                    counter ++;
                }
            }
        }
        return _tempArray;
    }

    /**
    * @notice Reclaims all ERC20Basic compatible tokens
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "0x address is invalid");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance),"token transfer failed");
    }

    /**
     * @notice Called by the owner to pause, triggers stopped state
     */
    function pause() external whenNotPaused onlyOwner {
        set(Encoder.getKey("paused"), true);
        /*solium-disable-next-line security/no-block-members*/
        emit Pause(now);
    }

    /**
     * @notice Called by the owner to unpause, returns to normal state
     */
    function unpause() external whenPaused onlyOwner {
        set(Encoder.getKey("paused"), false);
        /*solium-disable-next-line security/no-block-members*/
        emit Unpause(now);
    }

    /**
     * @notice Stores the contract addresses of other key contracts from the PolymathRegistry
     */
    function updateFromRegistry() external onlyOwner {
        address _polymathRegistry = getAddress(Encoder.getKey("polymathRegistry"));
        set(Encoder.getKey("securityTokenRegistry"), IPolymathRegistry(_polymathRegistry).getAddress("SecurityTokenRegistry"));
        set(Encoder.getKey("featureRegistry"), IPolymathRegistry(_polymathRegistry).getAddress("FeatureRegistry"));
        set(Encoder.getKey("polyToken"), IPolymathRegistry(_polymathRegistry).getAddress("PolyToken"));
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner(), _newOwner);
        set(Encoder.getKey("owner"), _newOwner);
    }

    /**
     * @notice Gets the owner of the contract
     * @return address owner
     */
    function owner() public view returns(address) {
        return getAddress(Encoder.getKey("owner"));
    }

    /**
     * @notice Checks whether the contract operations is paused or not
     * @return bool
     */
    function isPaused() public view returns(bool) {
        return getBool(Encoder.getKey("paused"));
    }
}