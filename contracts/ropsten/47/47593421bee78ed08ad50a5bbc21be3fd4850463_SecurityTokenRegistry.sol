pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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

// File: contracts/interfaces/ISTFactory.sol

/**
 * @title Interface for security token proxy deployment
 */
interface ISTFactory {

    /**
     * @notice Deploys the token and adds default modules like permission manager and transfer manager.
     * Future versions of the proxy can attach different modules or pass some other paramters.
     * @param _name is the name of the Security token
     * @param _symbol is the symbol of the Security Token
     * @param _decimals is the number of decimals of the Security Token
     * @param _tokenDetails is the off-chain data associated with the Security Token
     * @param _issuer is the owner of the Security Token
     * @param _divisible whether the token is divisible or not
     * @param _polymathRegistry is the address of the Polymath Registry contract
     */
    function deployToken(
        string _name,
        string _symbol,
        uint8 _decimals,
        string _tokenDetails,
        address _issuer,
        bool _divisible,
        address _polymathRegistry
    )
        external
        returns (address);
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

// File: contracts/libraries/Util.sol

/**
 * @title Utility contract for reusable code
 */
library Util {

   /**
    * @notice Changes a string to upper case
    * @param _base String to change
    */
    function upper(string _base) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            bytes1 b1 = _baseBytes[i];
            if (b1 >= 0x61 && b1 <= 0x7A) {
                b1 = bytes1(uint8(b1)-32);
            }
            _baseBytes[i] = b1;
        }
        return string(_baseBytes);
    }

    /**
     * @notice Changes the string into bytes32
     * @param _source String that need to convert into bytes32
     */
    /// Notice - Maximum Length for _source will be 32 chars otherwise returned bytes32 value will have lossy value.
    function stringToBytes32(string memory _source) internal pure returns (bytes32) {
        return bytesToBytes32(bytes(_source), 0);
    }

    /**
     * @notice Changes bytes into bytes32
     * @param _b Bytes that need to convert into bytes32
     * @param _offset Offset from which to begin conversion
     */
    /// Notice - Maximum length for _source will be 32 chars otherwise returned bytes32 value will have lossy value.
    function bytesToBytes32(bytes _b, uint _offset) internal pure returns (bytes32) {
        bytes32 result;

        for (uint i = 0; i < _b.length; i++) {
            result |= bytes32(_b[_offset + i] & 0xFF) >> (i * 8);
        }
        return result;
    }

    /**
     * @notice Changes the bytes32 into string
     * @param _source that need to convert into string
     */
    function bytes32ToString(bytes32 _source) internal pure returns (string result) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_source) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    /**
     * @notice Gets function signature from _data
     * @param _data Passed data
     * @return bytes4 sig
     */
    function getSig(bytes _data) internal pure returns (bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
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

// File: contracts/SecurityTokenRegistry.sol

/**
 * @title Registry contract for issuers to register their tickers and security tokens
 */
contract SecurityTokenRegistry is ISecurityTokenRegistry, EternalStorage {

    /**
     * @notice state variables

       address public polyToken;
       uint256 public stLaunchFee;
       uint256 public tickerRegFee;
       uint256 public expiryLimit;
       uint256 public latestProtocolVersion;
       bool public paused;
       address public owner;
       address public polymathRegistry;

       address[] public activeUsers;
       mapping(address => bool) public seenUsers;

       mapping(address => bytes32[]) userToTickers;
       mapping(string => address) tickerToSecurityToken;
       mapping(string => uint) tickerIndex;
       mapping(string => TickerDetails) registeredTickers;
       mapping(address => SecurityTokenData) securityTokens;
       mapping(bytes32 => address) protocolVersionST;
       mapping(uint256 => ProtocolVersion) versionData;

       struct ProtocolVersion {
           uint8 major;
           uint8 minor;
           uint8 patch;
       }

       struct TickerDetails {
           address owner;
           uint256 registrationDate;
           uint256 expiryDate;
           string tokenName;
           bool status;
       }

       struct SecurityTokenData {
           string ticker;
           string tokenDetails;
           uint256 deployedAt;
       }

     */

    using SafeMath for uint256;

    bytes32 constant INITIALIZE = 0x9ef7257c3339b099aacf96e55122ee78fb65a36bd2a6c19249882be9c98633bf;
    bytes32 constant POLYTOKEN = 0xacf8fbd51bb4b83ba426cdb12f63be74db97c412515797993d2a385542e311d7;
    bytes32 constant STLAUNCHFEE = 0xd677304bb45536bb7fdfa6b9e47a3c58fe413f9e8f01474b0a4b9c6e0275baf2;
    bytes32 constant TICKERREGFEE = 0x2fcc69711628630fb5a42566c68bd1092bc4aa26826736293969fddcd11cb2d2;
    bytes32 constant EXPIRYLIMIT = 0x604268e9a73dfd777dcecb8a614493dd65c638bad2f5e7d709d378bd2fb0baee;
    bytes32 constant PAUSED = 0xee35723ac350a69d2a92d3703f17439cbaadf2f093a21ba5bf5f1a53eb2a14d9;
    bytes32 constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    bytes32 constant POLYMATHREGISTRY = 0x90eeab7c36075577c7cc5ff366e389fefa8a18289b949bab3529ab4471139d4d;

    // Emit when network becomes paused
    event Pause(uint256 _timestammp);
     // Emit when network becomes unpaused
    event Unpause(uint256 _timestamp);
    // Emit when the ticker is removed from the registry
    event TickerRemoved(string _ticker, uint256 _removedAt, address _removedBy);
    // Emit when the token ticker expiry is changed
    event ChangeExpiryLimit(uint256 _oldExpiry, uint256 _newExpiry);
     // Emit when changeSecurityLaunchFee is called
    event ChangeSecurityLaunchFee(uint256 _oldFee, uint256 _newFee);
    // Emit when changeTickerRegistrationFee is called
    event ChangeTickerRegistrationFee(uint256 _oldFee, uint256 _newFee);
    // Emit when ownership gets transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // Emit when ownership of the ticker gets changed
    event ChangeTickerOwnership(string _ticker, address indexed _oldOwner, address indexed _newOwner);
    // Emit at the time of launching a new security token
    event NewSecurityToken(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        bool _fromAdmin,
        uint256 _registrationFee
    );
    // Emit after ticker registration
    event RegisterTicker(
        address indexed _owner,
        string _ticker,
        string _name,
        uint256 indexed _registrationDate,
        uint256 indexed _expiryDate,
        bool _fromAdmin,
        uint256 _registrationFee
    );

    /////////////////////////////
    // Modifiers
    /////////////////////////////

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

    /**
     * @notice Initializes instance of STR
     * @param _polymathRegistry is the address of the Polymath Registry
     * @param _STFactory is the address of the Proxy contract for Security Tokens
     * @param _stLaunchFee is the fee in POLY required to launch a token
     * @param _tickerRegFee is the fee in POLY required to register a ticker
     * @param _polyToken is the address of the POLY ERC20 token
     * @param _owner is the owner of the STR
     */
    function initialize(
        address _polymathRegistry,
        address _STFactory,
        uint256 _stLaunchFee,
        uint256 _tickerRegFee,
        address _polyToken,
        address _owner
    )
        external
        payable
    {
        require(!getBool(INITIALIZE),"already initialized");
        require(
            _STFactory != address(0) && _polyToken != address(0) && _owner != address(0) && _polymathRegistry != address(0),
            "Invalid address"
        );
        require(_stLaunchFee != 0 && _tickerRegFee != 0, "Fees should not be 0");
        set(POLYTOKEN, _polyToken);
        set(STLAUNCHFEE, _stLaunchFee);
        set(TICKERREGFEE, _tickerRegFee);
        set(EXPIRYLIMIT, uint256(60 * 1 days));
        set(PAUSED, false);
        set(OWNER, _owner);
        set(POLYMATHREGISTRY, _polymathRegistry);
        _setProtocolVersion(_STFactory, uint8(2), uint8(0), uint8(0));
        set(INITIALIZE, true);
    }

    /////////////////////////////
    // Token Ticker Management
    /////////////////////////////

    /**
     * @notice Registers the token ticker to the selected owner
     * @notice Once the token ticker is registered to its owner then no other issuer can claim
     * @notice its ownership. If the ticker expires and its issuer hasn&#39;t used it, then someone else can take it.
     * @param _owner is address of the owner of the token
     * @param _ticker is unique token ticker
     * @param _tokenName is the name of the token
     */
    function registerTicker(address _owner, string _ticker, string _tokenName) external whenNotPausedOrOwner {
        require(_owner != address(0), "Owner should not be 0x");
        require(bytes(_ticker).length > 0 && bytes(_ticker).length <= 10, "Ticker length range (0,10]");
        // Attempt to charge the reg fee if it is > 0 POLY
        uint256 tickerFee = getTickerRegistrationFee();
        if (tickerFee > 0)
            require(IERC20(getAddress(POLYTOKEN)).transferFrom(msg.sender, address(this), tickerFee), "Insufficent allowance");
        string memory ticker = Util.upper(_ticker);
        require(_tickerAvailable(ticker), "Ticker is reserved");
        // Check whether ticker was previously registered (and expired)
        address previousOwner = _tickerOwner(ticker);
        if (previousOwner != address(0)) {
            _deleteTickerOwnership(previousOwner, ticker);
        }
        /*solium-disable-next-line security/no-block-members*/
        _addTicker(_owner, ticker, _tokenName, now, now.add(getExpiryLimit()), false, false, tickerFee);
    }

    /**
     * @notice Internal - Sets the details of the ticker
     */
    function _addTicker(
        address _owner, 
        string _ticker, 
        string _tokenName, 
        uint256 _registrationDate, 
        uint256 _expiryDate, 
        bool _status, 
        bool _fromAdmin, 
        uint256 _fee
        ) internal {
        _setTickerOwnership(_owner, _ticker);
        _storeTickerDetails(_ticker, _owner, _registrationDate, _expiryDate, _tokenName, _status);
        emit RegisterTicker(_owner, _ticker, _tokenName, _registrationDate, _expiryDate, _fromAdmin, _fee);
    }

    /**
     * @notice Modifies the ticker details. Only Polymath has the ability to do so.
     * @notice Only allowed to modify the tickers which are not yet deployed.
     * @param _owner is the owner of the token
     * @param _ticker is the token ticker
     * @param _tokenName is the name of the token
     * @param _registrationDate is the date at which ticker is registered
     * @param _expiryDate is the expiry date for the ticker
     * @param _status is the token deployment status
     */
    function modifyTicker(
        address _owner,
        string _ticker,
        string _tokenName,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
        ) external onlyOwner {
        require(bytes(_ticker).length > 0 && bytes(_ticker).length <= 10, "Ticker length range (0,10]");
        require(_expiryDate != 0 && _registrationDate != 0, "Dates should not be 0");
        require(_registrationDate <= _expiryDate, "Registration date should < expiry date");
        require(_owner != address(0), "Invalid address");
        string memory ticker = Util.upper(_ticker);
        _modifyTicker(_owner, ticker, _tokenName, _registrationDate, _expiryDate, _status);
    }

    /**
     * @notice Internal -- Modifies the ticker details.
     */
    function _modifyTicker(
        address _owner,
        string _ticker,
        string _tokenName,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
        ) internal {
        address currentOwner = _tickerOwner(_ticker);
        if (currentOwner != address(0)) {
            _deleteTickerOwnership(currentOwner, _ticker);
        }
        if (_tickerStatus(_ticker) && !_status) {
            set(Encoder.getKey("tickerToSecurityToken", _ticker), address(0));
        }
        // If status is true, there must be a security token linked to the ticker already
        if (_status) {
            require(getAddress(Encoder.getKey("tickerToSecurityToken", _ticker)) != address(0), "Token not registered");
        }
        _addTicker(_owner, _ticker, _tokenName, _registrationDate, _expiryDate, _status, true, uint256(0));
    }

    function _tickerOwner(string _ticker) internal view returns(address) {
        return getAddress(Encoder.getKey("registeredTickers_owner", _ticker));
    }

    /**
     * @notice Removes the ticker details, associated ownership & security token mapping
     * @param _ticker is the token ticker
     */
    function removeTicker(string _ticker) external onlyOwner {
        string memory ticker = Util.upper(_ticker);
        address owner = _tickerOwner(ticker);
        require(owner != address(0), "Ticker doesn&#39;t exist");
        _deleteTickerOwnership(owner, ticker);
        set(Encoder.getKey("tickerToSecurityToken", ticker), address(0));
        _storeTickerDetails(ticker, address(0), 0, 0, "", false);
        /*solium-disable-next-line security/no-block-members*/
        emit TickerRemoved(ticker, now, msg.sender);
    }

    /**
     * @notice Internal - Checks if the entered ticker is registered and has not expired
     * @param _ticker is the token ticker
     * @return bool
     */
    function _tickerAvailable(string _ticker) internal view returns(bool) {
        if (_tickerOwner(_ticker) != address(0)) {
            /*solium-disable-next-line security/no-block-members*/
            if ((now > getUint(Encoder.getKey("registeredTickers_expiryDate", _ticker))) && !_tickerStatus(_ticker)) {
                return true;
            } else
                return false;
        }
        return true;
    }

    function _tickerStatus(string _ticker) internal view returns(bool) {
        return getBool(Encoder.getKey("registeredTickers_status", _ticker));
    }

    /**
     * @notice Internal - Sets the ticker owner
     * @param _owner is the address of the owner of the ticker
     * @param _ticker is the ticker symbol
     */
    function _setTickerOwnership(address _owner, string _ticker) internal {
        bytes32 _ownerKey = Encoder.getKey("userToTickers", _owner);
        uint256 length = uint256(getArrayBytes32(_ownerKey).length);
        pushArray(_ownerKey, Util.stringToBytes32(_ticker));
        set(Encoder.getKey("tickerIndex", _ticker), length);
        bytes32 seenKey = Encoder.getKey("seenUsers", _owner);
        if (!getBool(seenKey)) {
            pushArray(Encoder.getKey("activeUsers"), _owner);
            set(seenKey, true);
        }
    }

    /**
     * @notice Internal - Stores the ticker details
     */
    function _storeTickerDetails(
        string _ticker,
        address _owner,
        uint256 _registrationDate,
        uint256 _expiryDate,
        string _tokenName,
        bool _status
        ) internal {
        bytes32 key = Encoder.getKey("registeredTickers_owner", _ticker);
        if (getAddress(key) != _owner)
            set(key, _owner);
        key = Encoder.getKey("registeredTickers_registrationDate", _ticker);
        if (getUint(key) != _registrationDate)
            set(key, _registrationDate);
        key = Encoder.getKey("registeredTickers_expiryDate", _ticker);
        if (getUint(key) != _expiryDate)
            set(key, _expiryDate);
        key = Encoder.getKey("registeredTickers_tokenName", _ticker);
        if (Encoder.getKey(getString(key)) != Encoder.getKey(_tokenName))
            set(key, _tokenName);
        key = Encoder.getKey("registeredTickers_status", _ticker);
        if (getBool(key) != _status)
            set(key, _status);
    }

    /**
     * @notice Transfers the ownership of the ticker
     * @param _newOwner is the address of the new owner of the ticker
     * @param _ticker is the ticker symbol
     */
    function transferTickerOwnership(address _newOwner, string _ticker) external whenNotPausedOrOwner {
        string memory ticker = Util.upper(_ticker);
        require(_newOwner != address(0), "Invalid address");
        bytes32 ownerKey = Encoder.getKey("registeredTickers_owner", ticker);
        require(getAddress(ownerKey) == msg.sender, "Not authorised");
        if (_tickerStatus(ticker))
            require(IOwnable(getAddress(Encoder.getKey("tickerToSecurityToken", ticker))).owner() == _newOwner, "New owner does not match token owner");
        _deleteTickerOwnership(msg.sender, ticker);
        _setTickerOwnership(_newOwner, ticker);
        set(ownerKey, _newOwner);
        emit ChangeTickerOwnership(ticker, msg.sender, _newOwner);
    }

    /**
     * @notice Internal - Removes the owner of a ticker
     */
    function _deleteTickerOwnership(address _owner, string _ticker) internal {
        uint256 index = uint256(getUint(Encoder.getKey("tickerIndex", _ticker)));
        bytes32 ownerKey = Encoder.getKey("userToTickers", _owner);
        bytes32[] memory tickers = getArrayBytes32(ownerKey);
        assert(index < tickers.length);
        assert(_tickerOwner(_ticker) == _owner);
        deleteArrayBytes32(ownerKey, index);
        if (getArrayBytes32(ownerKey).length > index) {
            bytes32 switchedTicker = getArrayBytes32(ownerKey)[index];
            set(Encoder.getKey("tickerIndex", Util.bytes32ToString(switchedTicker)), index);
        }
    }

    /**
     * @notice Changes the expiry time for the token ticker. Only available to Polymath.
     * @param _newExpiry is the new expiry for newly generated tickers
     */
    function changeExpiryLimit(uint256 _newExpiry) external onlyOwner {
        require(_newExpiry >= 1 days, "Expiry should >= 1 day");
        emit ChangeExpiryLimit(getUint(EXPIRYLIMIT), _newExpiry);
        set(EXPIRYLIMIT, _newExpiry);
    }

    /**
     * @notice Returns the list of tickers owned by the selected address
     * @param _owner is the address which owns the list of tickers
     */
    function getTickersByOwner(address _owner) external view returns(bytes32[]) {
        uint counter = 0;
        // accessing the data structure userTotickers[_owner].length
        bytes32[] memory tickers = getArrayBytes32(Encoder.getKey("userToTickers", _owner));
        for (uint i = 0; i < tickers.length; i++) {
            string memory ticker = Util.bytes32ToString(tickers[i]);
            /*solium-disable-next-line security/no-block-members*/
            if (getUint(Encoder.getKey("registeredTickers_expiryDate", ticker)) >= now || _tickerStatus(ticker)) {
                counter ++;
            }
        }
        bytes32[] memory tempList = new bytes32[](counter);
        counter = 0;
        for (i = 0; i < tickers.length; i++) {
            ticker = Util.bytes32ToString(tickers[i]);
            /*solium-disable-next-line security/no-block-members*/
            if (getUint(Encoder.getKey("registeredTickers_expiryDate", ticker)) >= now || _tickerStatus(ticker)) {
                tempList[counter] = tickers[i];
                counter ++;
            }
        }
        return tempList;
    }

    /**
     * @notice Returns the list of tokens owned by the selected address
     * @param _owner is the address which owns the list of tickers
     * @dev Intention is that this is called off-chain so block gas limit is not relevant
     */
    function getTokensByOwner(address _owner) external view returns(address[]) {
        // Loop over all active users, then all associated tickers of those users
        // This ensures we find tokens, even if their owner has been modified
        address[] memory activeUsers = getArrayAddress(Encoder.getKey("activeUsers"));
        bytes32[] memory tickers;
        address token;
        uint256 count = 0;
        uint256 i = 0;
        uint256 j = 0;
        for (i = 0; i < activeUsers.length; i++) {
            tickers = getArrayBytes32(Encoder.getKey("userToTickers", activeUsers[i]));
            for (j = 0; j < tickers.length; j++) {
                token = getAddress(Encoder.getKey("tickerToSecurityToken", Util.bytes32ToString(tickers[j])));
                if (token != address(0)) {
                    if (IOwnable(token).owner() == _owner) {
                        count = count + 1;
                    }
                }
            }
        }
        uint256 index = 0;
        address[] memory result = new address[](count);
        for (i = 0; i < activeUsers.length; i++) {
            tickers = getArrayBytes32(Encoder.getKey("userToTickers", activeUsers[i]));
            for (j = 0; j < tickers.length; j++) {
                token = getAddress(Encoder.getKey("tickerToSecurityToken", Util.bytes32ToString(tickers[j])));
                if (token != address(0)) {
                    if (IOwnable(token).owner() == _owner) {
                        result[index] = token;
                        index = index + 1;
                    }
                }
            }
        }
        return result;
    }

    /**
     * @notice Returns the owner and timestamp for a given ticker
     * @param _ticker is the ticker symbol
     * @return address
     * @return uint256
     * @return uint256
     * @return string
     * @return bool
     */
    function getTickerDetails(string _ticker) external view returns (address, uint256, uint256, string, bool) {
        string memory ticker = Util.upper(_ticker);
        bool tickerStatus = _tickerStatus(ticker);
        uint256 expiryDate = getUint(Encoder.getKey("registeredTickers_expiryDate", ticker));
        /*solium-disable-next-line security/no-block-members*/
        if ((tickerStatus == true) || (expiryDate > now)) {
            return
            (
                _tickerOwner(ticker),
                getUint(Encoder.getKey("registeredTickers_registrationDate", ticker)),
                expiryDate,
                getString(Encoder.getKey("registeredTickers_tokenName", ticker)),
                tickerStatus
            );
        } else
            return (address(0), uint256(0), uint256(0), "", false);
    }

    /////////////////////////////
    // Security Token Management
    /////////////////////////////

    /**
     * @notice Deploys an instance of a new Security Token and records it to the registry
     * @param _name is the name of the token
     * @param _ticker is the ticker symbol of the security token
     * @param _tokenDetails is the off-chain details of the token
     * @param _divisible is whether or not the token is divisible
     */
    function generateSecurityToken(string _name, string _ticker, string _tokenDetails, bool _divisible) external whenNotPausedOrOwner {
        require(bytes(_name).length > 0 && bytes(_ticker).length > 0, "Ticker length > 0");
        string memory ticker = Util.upper(_ticker);
        bytes32 statusKey = Encoder.getKey("registeredTickers_status", ticker);
        require(!getBool(statusKey), "Already deployed");
        set(statusKey, true);
        require(_tickerOwner(ticker) == msg.sender, "Not authorised");
        /*solium-disable-next-line security/no-block-members*/
        require(getUint(Encoder.getKey("registeredTickers_expiryDate", ticker)) >= now, "Ticker gets expired");

        uint256 launchFee = getSecurityTokenLaunchFee();
        if (launchFee > 0)
            require(IERC20(getAddress(POLYTOKEN)).transferFrom(msg.sender, address(this), launchFee), "Insufficient allowance");

        address newSecurityTokenAddress = ISTFactory(getSTFactoryAddress()).deployToken(
            _name,
            ticker,
            18,
            _tokenDetails,
            msg.sender,
            _divisible,
            getAddress(POLYMATHREGISTRY)
        );

        /*solium-disable-next-line security/no-block-members*/
        _storeSecurityTokenData(newSecurityTokenAddress, ticker, _tokenDetails, now);
        set(Encoder.getKey("tickerToSecurityToken", ticker), newSecurityTokenAddress);
        /*solium-disable-next-line security/no-block-members*/
        emit NewSecurityToken(ticker, _name, newSecurityTokenAddress, msg.sender, now, msg.sender, false, launchFee);
    }

    /**
     * @notice Adds a new custom Security Token and saves it to the registry. (Token should follow the ISecurityToken interface)
     * @param _name is the name of the token
     * @param _ticker is the ticker symbol of the security token
     * @param _owner is the owner of the token
     * @param _securityToken is the address of the securityToken
     * @param _tokenDetails is the off-chain details of the token
     * @param _deployedAt is the timestamp at which the security token is deployed
     */
    function modifySecurityToken(
        string _name,
        string _ticker,
        address _owner,
        address _securityToken,
        string _tokenDetails,
        uint256 _deployedAt
    )
        external
        onlyOwner
    {
        require(bytes(_name).length > 0 && bytes(_ticker).length > 0, "String length > 0");
        require(bytes(_ticker).length <= 10, "Ticker length range (0,10]");
        require(_deployedAt != 0 && _owner != address(0), "0 value params not allowed");
        string memory ticker = Util.upper(_ticker);
        require(_securityToken != address(0), "ST address is 0x");
        uint256 registrationTime = getUint(Encoder.getKey("registeredTickers_registrationDate", ticker));
        uint256 expiryTime = getUint(Encoder.getKey("registeredTickers_expiryDate", ticker));
        if (registrationTime == 0) {
            /*solium-disable-next-line security/no-block-members*/
            registrationTime = now;
            expiryTime = registrationTime.add(getExpiryLimit());
        }
        set(Encoder.getKey("tickerToSecurityToken", ticker), _securityToken);
        _modifyTicker(_owner, ticker, _name, registrationTime, expiryTime, true);
        _storeSecurityTokenData(_securityToken, ticker, _tokenDetails, _deployedAt);
        emit NewSecurityToken(ticker, _name, _securityToken, _owner, _deployedAt, msg.sender, true, getSecurityTokenLaunchFee());
    }

    /**
     * @notice Internal - Stores the security token details
     */
    function _storeSecurityTokenData(address _securityToken, string _ticker, string _tokenDetails, uint256 _deployedAt) internal {
        set(Encoder.getKey("securityTokens_ticker", _securityToken), _ticker);
        set(Encoder.getKey("securityTokens_tokenDetails", _securityToken), _tokenDetails);
        set(Encoder.getKey("securityTokens_deployedAt", _securityToken), _deployedAt);
    }

    /**
    * @notice Checks that Security Token is registered
    * @param _securityToken is the address of the security token
    * @return bool
    */
    function isSecurityToken(address _securityToken) external view returns (bool) {
        return (keccak256(bytes(getString(Encoder.getKey("securityTokens_ticker", _securityToken)))) != keccak256(""));
    }

    /**
     * @notice Returns the security token address by ticker symbol
     * @param _ticker is the ticker of the security token
     * @return address
     */
    function getSecurityTokenAddress(string _ticker) external view returns (address) {
        string memory ticker = Util.upper(_ticker);
        return getAddress(Encoder.getKey("tickerToSecurityToken", ticker));
    }

     /**
     * @notice Returns the security token data by address
     * @param _securityToken is the address of the security token.
     * @return string is the ticker of the security Token.
     * @return address is the issuer of the security Token.
     * @return string is the details of the security token.
     * @return uint256 is the timestamp at which security Token was deployed.
     */
    function getSecurityTokenData(address _securityToken) external view returns (string, address, string, uint256) {
        return (
            getString(Encoder.getKey("securityTokens_ticker", _securityToken)),
            IOwnable(_securityToken).owner(),
            getString(Encoder.getKey("securityTokens_tokenDetails", _securityToken)),
            getUint(Encoder.getKey("securityTokens_deployedAt", _securityToken))
        );
    }

    /////////////////////////////
    // Ownership, lifecycle & Utility
    /////////////////////////////

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(getAddress(OWNER), _newOwner);
        set(OWNER, _newOwner);
    }

    /**
    * @notice Called by the owner to pause, triggers stopped state
    */
    function pause() external whenNotPaused onlyOwner {
        set(PAUSED, true);
        /*solium-disable-next-line security/no-block-members*/
        emit Pause(now);
    }

    /**
    * @notice Called by the owner to unpause, returns to normal state
    */
    function unpause() external whenPaused onlyOwner {
        set(PAUSED, false);
        /*solium-disable-next-line security/no-block-members*/
        emit Unpause(now);
    }

    /**
    * @notice Sets the ticker registration fee in POLY tokens. Only Polymath.
    * @param _tickerRegFee is the registration fee in POLY tokens (base 18 decimals)
    */
    function changeTickerRegistrationFee(uint256 _tickerRegFee) external onlyOwner {
        uint256 fee = getUint(TICKERREGFEE);
        require(fee != _tickerRegFee, "Fee not changed");
        emit ChangeTickerRegistrationFee(fee, _tickerRegFee);
        set(TICKERREGFEE, _tickerRegFee);
    }

   /**
    * @notice Sets the ticker registration fee in POLY tokens. Only Polymath.
    * @param _stLaunchFee is the registration fee in POLY tokens (base 18 decimals)
    */
    function changeSecurityLaunchFee(uint256 _stLaunchFee) external onlyOwner {
        uint256 fee = getUint(STLAUNCHFEE);
        require(fee != _stLaunchFee, "Fee not changed");
        emit ChangeSecurityLaunchFee(fee, _stLaunchFee);
        set(STLAUNCHFEE, _stLaunchFee);
    }

    /**
    * @notice Reclaims all ERC20Basic compatible tokens
    * @param _tokenContract is the address of the token contract
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Transfer failed");
    }

    /**
    * @notice Changes the protocol version and the SecurityToken contract
    * @notice Used only by Polymath to upgrade the SecurityToken contract and add more functionalities to future versions
    * @notice Changing versions does not affect existing tokens.
    * @param _STFactoryAddress is the address of the proxy.
    * @param _major Major version of the proxy.
    * @param _minor Minor version of the proxy.
    * @param _patch Patch version of the proxy
    */
    function setProtocolVersion(address _STFactoryAddress, uint8 _major, uint8 _minor, uint8 _patch) external onlyOwner {
        require(_STFactoryAddress != address(0), "0x address is not allowed");
        _setProtocolVersion(_STFactoryAddress, _major, _minor, _patch);
    }

    /**
    * @notice Internal - Changes the protocol version and the SecurityToken contract
    */
    function _setProtocolVersion(address _STFactoryAddress, uint8 _major, uint8 _minor, uint8 _patch) internal {
        uint8[] memory _version = new uint8[](3);
        _version[0] = _major;
        _version[1] = _minor;
        _version[2] = _patch;
        uint24 _packedVersion = VersionUtils.pack(_major, _minor, _patch);
        require(VersionUtils.isValidVersion(getProtocolVersion(), _version),"In-valid version");
        set(Encoder.getKey("latestVersion"), uint256(_packedVersion));
        set(Encoder.getKey("protocolVersionST", getUint(Encoder.getKey("latestVersion"))), _STFactoryAddress);
    }

    /**
     * @notice Returns the current STFactory Address
     */
    function getSTFactoryAddress() public view returns(address) {
        return getAddress(Encoder.getKey("protocolVersionST", getUint(Encoder.getKey("latestVersion"))));
    }

    /**
     * @notice Gets Protocol version
     */
    function getProtocolVersion() public view returns(uint8[]) {
        return VersionUtils.unpack(uint24(getUint(Encoder.getKey("latestVersion"))));
    }

    /**
     * @notice Changes the PolyToken address. Only Polymath.
     * @param _newAddress is the address of the polytoken.
     */
    function updatePolyTokenAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid address");
        set(POLYTOKEN, _newAddress);
    }

    /**
     * @notice Gets the security token launch fee
     * @return Fee amount
     */
    function getSecurityTokenLaunchFee() public view returns(uint256) {
        return getUint(STLAUNCHFEE);
    }

    /**
     * @notice Gets the ticker registration fee
     * @return Fee amount
     */
    function getTickerRegistrationFee() public view returns(uint256) {
        return getUint(TICKERREGFEE);
    }

    /**
     * @notice Gets the expiry limit
     * @return Expiry limit
     */
    function getExpiryLimit() public view returns(uint256) {
        return getUint(EXPIRYLIMIT);
    }

    /**
     * @notice Check whether the registry is paused or not
     * @return bool
     */
    function isPaused() public view returns(bool) {
        return getBool(PAUSED);
    }

    /**
     * @notice Gets the owner of the contract
     * @return address owner
     */
    function owner() public view returns(address) {
        return getAddress(OWNER);
    }

}