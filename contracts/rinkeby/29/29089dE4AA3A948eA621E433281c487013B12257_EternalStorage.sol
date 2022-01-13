//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IEternalStorage.sol";

/**
 * @title Contract for Eternal's shared eternal storage
 * @author Nobody (me)
 * @notice The Eternal Storage contract holds all variables of all other Eternal contracts
 */
contract EternalStorage is IEternalStorage, Context {

/////–––««« Variables: Storage »»»––––\\\\\

    // Scalars
    mapping (bytes32 => mapping (bytes32 => uint256)) private uints;
    mapping (bytes32 => mapping (bytes32 => int256)) private ints;
    mapping (bytes32 => mapping (bytes32 => address)) private addresses;
    mapping (bytes32 => mapping (bytes32 => bool)) private bools;
    mapping (bytes32 => mapping (bytes32 => bytes32)) private bytes32s;

    // Multi-value variables
    mapping(bytes32 => uint256[]) private manyUints;
    mapping(bytes32 => int256[]) private manyInts;
    mapping(bytes32 => address[]) private manyAddresses;
    mapping(bytes32 => bool[]) private manyBools;
    mapping(bytes32 => bytes32[]) private manyBytes;

/////–––««« Constructors & Initializers »»»––––\\\\\

//solhint-disable-next-line no-empty-blocks
constructor () {}

function initialize(address _treasury, address _token, address _factory, address _fund, address _offering) external {
    bytes32 treasury = keccak256(abi.encodePacked(_treasury));
    bytes32 token = keccak256(abi.encodePacked(_token));
    bytes32 factory = keccak256(abi.encodePacked(_factory));
    bytes32 fund = keccak256(abi.encodePacked(_fund));
    bytes32 offering = keccak256(abi.encodePacked(_offering));
    bytes32 eternalStorage = keccak256(abi.encodePacked(address(this)));

    require(addresses[eternalStorage][token] == address(0), "Initial contracts already set");
    addresses[eternalStorage][treasury] = _treasury;
    addresses[eternalStorage][token] = _token;
    addresses[eternalStorage][factory] = _factory;
    addresses[eternalStorage][fund] = _fund;
    addresses[eternalStorage][offering] = _offering;
}

/////–––««« Modifiers »»»––––\\\\\

    /**
     * @notice Ensures that only the latest contracts can modify variables' states
     */
    modifier onlyLatestVersion() {
        bytes32 eternalStorage = keccak256(abi.encodePacked(address(this)));
        bytes32 entity = keccak256(abi.encodePacked(_msgSender()));
        require(_msgSender() == addresses[eternalStorage][entity], "Old contract can't edit storage");
        _;
    }

/////–––««« Setters »»»––––\\\\\

    /**
     * @notice Sets a uint256 value for a given contract and key
     * @param entity The keccak256 hash of the contract's address
     * @param key The specified mapping key
     * @param value The specified uint256 value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setUint(bytes32 entity, bytes32 key, uint256 value) external override onlyLatestVersion {
        uints[entity][key] = value;
    }

    /**
     * @notice Sets an int256 value for a given contract and key
     * @param entity The keccak256 hash of the contract's address
     * @param key The specified mapping key
     * @param value The specified int256 value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setInt(bytes32 entity, bytes32 key, int256 value) external override onlyLatestVersion {
        ints[entity][key] = value;
    }

    /**
     * @notice Sets an address value for a given contract and key
     * @param entity The keccak256 hash of the contract's address
     * @param key The specified mapping key
     * @param value The specified address value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setAddress(bytes32 entity, bytes32 key, address value) external override onlyLatestVersion {
        addresses[entity][key] = value;
    }

    /**
     * @notice Sets a boolean value for a given contract and key
     * @param entity The keccak256 hash of the contract's address
     * @param key The specified mapping key
     * @param value The specified boolean value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setBool(bytes32 entity, bytes32 key, bool value) external override onlyLatestVersion {
        bools[entity][key] = value;
    }    

    /**
     * @notice Sets a bytes32 value for a given contract and key
     * @param entity The keccak256 hash of the contract's address
     * @param key The specified mapping key
     * @param value The specified bytes32 value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setBytes(bytes32 entity, bytes32 key, bytes32 value) external override onlyLatestVersion {
        bytes32s[entity][key] = value;
    }    

    /**
     * @notice Sets or pushes a uint256 array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the array's element being modified
     * @param value The specified uint256 value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setUintArrayValue(bytes32 key, uint256 index, uint256 value) external override onlyLatestVersion {
        if (index == 0) {
            manyUints[key].push(value);
        } else {
            manyUints[key][index] = value;
        }
    }

    /**
     * @notice Sets or pushes an int256 array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the array's element being modified
     * @param value The specified int256 value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setIntArrayValue(bytes32 key, uint256 index, int256 value) external override onlyLatestVersion {
        if (index == 0) {
            manyInts[key].push(value);
        } else {
            manyInts[key][index] = value;
        }
    }

    /**
     * @notice Sets or pushes an address array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the array's element being modified
     * @param value The specified address value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setAddressArrayValue(bytes32 key, uint256 index, address value) external override onlyLatestVersion {
        if (index == 0) {
            manyAddresses[key].push(value);
        } else {
            manyAddresses[key][index] = value;
        }
    }   

    /**
     * @notice Sets or pushes a boolean array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the array's element being modified
     * @param value The specified boolean value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setBoolArrayValue(bytes32 key, uint256 index, bool value) external override onlyLatestVersion {
        if (index == 0) {
            manyBools[key].push(value);
        } else {
            manyBools[key][index] = value;
        }
    }    

    /**
     * @notice Sets or pushes a bytes32 array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the array's element being modified
     * @param value The specified bytes32value
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function setBytesArrayValue(bytes32 key, uint256 index, bytes32 value) external override onlyLatestVersion {
        if (index == 0) {
            manyBytes[key].push(value);
        } else {
            manyBytes[key][index] = value;
        }
    }   

/////–––««« Getters »»»––––\\\\\
    /**
     * @notice Returns a uint256 value for a given contract and key
     * @param entity The keccak256 hash of the specified contract
     * @param key The specified mapping key
     * @return The uint256 value mapped to the key
     */
    function getUint(bytes32 entity, bytes32 key) external view override returns (uint256) {
        return uints[entity][key];
    }

    /**
     * @notice Returns an int256 value for a given contract and key
     * @param entity The keccak256 hash of the specified contract
     * @param key The specified mapping key
     * @return The int256 value mapped to the key
     */
    function getInt(bytes32 entity, bytes32 key) external view override returns (int256) {
        return ints[entity][key];
    }

    /**
     * @notice Returns an address value for a given contract and key
     * @param entity The keccak256 hash of the specified contract
     * @param key The specified mapping key
     * @return The address value mapped to the key
     */
    function getAddress(bytes32 entity, bytes32 key) external view override returns (address) {
        return addresses[entity][key];
    }

    /**
     * @notice Returns a boolean value for a given contract and key
     * @param entity The keccak256 hash of the specified contract
     * @param key The specified mapping key
     * @return The boolean value mapped to the key
     */    
    function getBool(bytes32 entity, bytes32 key) external view override returns (bool) {
        return bools[entity][key];
    }

    /**
     * @notice Returns a bytes32 value for a given contract and key
     * @param entity The keccak256 hash of the specified contract
     * @param key The specified mapping key
     * @return The bytes32 value mapped to the key
     */
    function getBytes(bytes32 entity, bytes32 key) external view override returns (bytes32) {
        return bytes32s[entity][key];
    }  

    /**
     * @notice Returns a uint256 array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * @return The uint256 value at the specified index for the specified array
     */
    function getUintArrayValue(bytes32 key, uint256 index) external view override returns (uint256) {
        return manyUints[key][index];
    }

    /**
     * @notice Returns an int256 array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * @return The int256 value at the specified index for the specified array
     */
    function getIntArrayValue(bytes32 key, uint256 index) external view override returns (int256) {
        return manyInts[key][index];
    }

    /**
     * @notice Returns an address array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * @return The address value at the specified index for the specified array
     */
    function getAddressArrayValue(bytes32 key, uint256 index) external view override returns (address) {
        return manyAddresses[key][index];
    }

    /**
     * @notice Returns a boolean array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * @return The boolean value at the specified index for the specified array
     */
    function getBoolArrayValue(bytes32 key, uint256 index) external view override returns (bool) {
        return manyBools[key][index];
    }

    /**
     * @notice Returns a bytes32 array's element's value for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * @return The bytes32 value at the specified index for the specified array
     */
    function getBytesArrayValue(bytes32 key, uint256 index) external view override returns (bytes32) {
        return manyBytes[key][index];
    }

/////–––««« Array Deleters »»»––––\\\\\

    /** 
     * @notice Deletes a uint256 array's element for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function deleteUint(bytes32 key, uint256 index) external override onlyLatestVersion {
        uint256 length = manyUints[key].length;
        manyUints[key][index] = manyUints[key][length - 1];
        manyUints[key].pop();
    }

    /** 
     * @notice Deletes an int256 array's element for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function deleteInt(bytes32 key, uint256 index) external override onlyLatestVersion {
        uint256 length = manyInts[key].length;
        manyInts[key][index] = manyInts[key][length - 1];
        manyInts[key].pop();
    }

    /** 
     * @notice Deletes an address array's element for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function deleteAddress(bytes32 key, uint256 index) external override onlyLatestVersion {
        uint256 length = manyAddresses[key].length;
        manyAddresses[key][index] = manyAddresses[key][length - 1];
        manyAddresses[key].pop();
    }

    /** 
     * @notice Deletes a boolean array's element for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function deleteBool(bytes32 key, uint256 index) external override onlyLatestVersion {
        uint256 length = manyBools[key].length;
        manyBools[key][index] = manyBools[key][length - 1];
        manyBools[key].pop();
    }

    /** 
     * @notice Deletes a bytes32 array's element for a given key and index
     * @param key The specified mapping key
     * @param index The specified index of the desired element
     * 
     * Requirements:
     *
     * - Only callable by the latest version of any Eternal contract
     */
    function deleteBytes(bytes32 key, uint256 index) external override onlyLatestVersion {
        uint256 length = manyBytes[key].length;
        manyBytes[key][index] = manyBytes[key][length - 1];
        manyBytes[key].pop();
    }

/////–––««« Array Length »»»––––\\\\\

    /**
     * @notice Returns the length of a uint256 array for a given key
     * @param key The specified mapping key
     * @return The length of the array mapped to the key
     */
    function lengthUint(bytes32 key) external view override returns (uint256) {
        return manyUints[key].length;
    }

    /**
     * @notice Returns the length of an int256 array for a given key
     * @param key The specified mapping key
     * @return The length of the array mapped to the key
     */
    function lengthInt(bytes32 key) external view override returns (uint256) {
        return manyInts[key].length;
    }

    /**
     * @notice Returns the length of an address array for a given key
     * @param key The specified mapping key
     * @return The length of the array mapped to the key
     */
    function lengthAddress(bytes32 key) external view override returns (uint256) {
        return manyAddresses[key].length;
    }

    /**
     * @notice Returns the length of a boolean array for a given key
     * @param key The specified mapping key
     * @return The length of the array mapped to the key
     */
    function lengthBool(bytes32 key) external view override returns (uint256) {
        return manyBools[key].length;
    }

    /**
     * @notice Returns the length of a bytes32 array for a given key
     * @param key The specified mapping key
     * @return The length of the array mapped to the key
     */
    function lengthBytes(bytes32 key) external view override returns (uint256) {
        return manyBytes[key].length;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal Storage interface
 * @author Nobody (me)
 * @notice Methods are used for all of Eternal's variable storage
 */
interface IEternalStorage {
    // Scalar setters
    function setUint(bytes32 entity, bytes32 key, uint256 value) external;
    function setInt(bytes32 entity, bytes32 key, int256 value) external;
    function setAddress(bytes32 entity, bytes32 key, address value) external;
    function setBool(bytes32 entity, bytes32 key, bool value) external;
    function setBytes(bytes32 entity, bytes32 key, bytes32 value) external;

    // Scalar getters
    function getUint(bytes32 entity, bytes32 key) external view returns(uint256);
    function getInt(bytes32 entity, bytes32 key) external view returns(int256);
    function getAddress(bytes32 entity, bytes32 key) external view returns(address);
    function getBool(bytes32 entity, bytes32 key) external view returns(bool);
    function getBytes(bytes32 entity, bytes32 key) external view returns(bytes32);

    // Array setters
    function setUintArrayValue(bytes32 key, uint256 index, uint256 value) external;
    function setIntArrayValue(bytes32 key, uint256 index, int256 value) external;
    function setAddressArrayValue(bytes32 key, uint256 index, address value) external;
    function setBoolArrayValue(bytes32 key, uint256 index, bool value) external;
    function setBytesArrayValue(bytes32 key, uint256 index, bytes32 value) external;

    // Array getters
    function getUintArrayValue(bytes32 key, uint256 index) external view returns (uint256);
    function getIntArrayValue(bytes32 key, uint256 index) external view returns (int256);
    function getAddressArrayValue(bytes32 key, uint256 index) external view returns (address);
    function getBoolArrayValue(bytes32 key, uint256 index) external view returns (bool);
    function getBytesArrayValue(bytes32 key, uint256 index) external view returns (bytes32);

    //Array Deleters
    function deleteUint(bytes32 key, uint256 index) external;
    function deleteInt(bytes32 key, uint256 index) external;
    function deleteAddress(bytes32 key, uint256 index) external;
    function deleteBool(bytes32 key, uint256 index) external;
    function deleteBytes(bytes32 key, uint256 index) external;

    //Array Length
    function lengthUint(bytes32 key) external view returns (uint256);
    function lengthInt(bytes32 key) external view returns (uint256);
    function lengthAddress(bytes32 key) external view returns (uint256);
    function lengthBool(bytes32 key) external view returns (uint256);
    function lengthBytes(bytes32 key) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}