/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// Sources flattened with hardhat v2.0.7 https://hardhat.org

// File contracts/lib/ownership/Ownable.sol

pragma solidity ^0.5.1;

contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() public { owner = msg.sender; }

    /// @dev Throws if called by any contract other than latest designated caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


// File contracts/platform/database/DatabaseInterface.sol

pragma solidity ^0.5.1;
contract DatabaseInterface is Ownable {
    function setStorageContract(address _storageContract, bool _allowed) public;
    /*** Bytes32 ***/
    function getBytes32(bytes32 key) external view returns(bytes32);
    function setBytes32(bytes32 key, bytes32 value) external;
    /*** Number **/
    function getNumber(bytes32 key) external view returns(uint256);
    function setNumber(bytes32 key, uint256 value) external;
    /*** Bytes ***/
    function getBytes(bytes32 key) external view returns(bytes memory);
    function setBytes(bytes32 key, bytes calldata value) external;
    /*** String ***/
    function getString(bytes32 key) external view returns(string memory);
    function setString(bytes32 key, string calldata value) external;
    /*** Bytes Array ***/
    function getBytesArray(bytes32 key) external view returns (bytes32[] memory);
    function getBytesArrayIndex(bytes32 key, uint256 index) external view returns (bytes32);
    function getBytesArrayLength(bytes32 key) external view returns (uint256);
    function pushBytesArray(bytes32 key, bytes32 value) external;
    function setBytesArrayIndex(bytes32 key, uint256 index, bytes32 value) external;
    function setBytesArray(bytes32 key, bytes32[] calldata value) external;
    /*** Int Array ***/
    function getIntArray(bytes32 key) external view returns (int[] memory);
    function getIntArrayIndex(bytes32 key, uint256 index) external view returns (int);
    function getIntArrayLength(bytes32 key) external view returns (uint256);
    function pushIntArray(bytes32 key, int value) external;
    function setIntArrayIndex(bytes32 key, uint256 index, int value) external;
    function setIntArray(bytes32 key, int[] calldata value) external;
    /*** Address Array ***/
    function getAddressArray(bytes32 key) external view returns (address[] memory );
    function getAddressArrayIndex(bytes32 key, uint256 index) external view returns (address);
    function getAddressArrayLength(bytes32 key) external view returns (uint256);
    function pushAddressArray(bytes32 key, address value) external;
    function setAddressArrayIndex(bytes32 key, uint256 index, address value) external;
    function setAddressArray(bytes32 key, address[] calldata value) external;
}


// File contracts/platform/database/Database.sol

pragma solidity ^0.5.1;
contract Database is Ownable, DatabaseInterface {
    event StorageModified(address indexed contractAddress, bool allowed);

    mapping (bytes32 => bytes32) data_bytes32;
    mapping (bytes32 => bytes) data_bytes;
    mapping (bytes32 => bytes32[]) data_bytesArray;
    mapping (bytes32 => int[]) data_intArray;
    mapping (bytes32 => address[]) data_addressArray;
    mapping (address => bool) allowed;

    modifier storageOnly {
        require(allowed[msg.sender], "Error: Access not allowed to storage");
        _;
    }

    function setStorageContract(address _storageContract, bool _allowed) public onlyOwner {
        require(_storageContract != address(0), "Error: Address zero is invalid storage contract");
        allowed[_storageContract] = _allowed;
        emit StorageModified(_storageContract, _allowed);
    }

    /*** Bytes32 ***/
    function getBytes32(bytes32 key) external view returns(bytes32) {
        return data_bytes32[key];
    }

    function setBytes32(bytes32 key, bytes32 value) external storageOnly  {
        data_bytes32[key] = value;
    }

    /*** Number **/
    function getNumber(bytes32 key) external view returns(uint256) {
        return uint256(data_bytes32[key]);
    }

    function setNumber(bytes32 key, uint256 value) external storageOnly {
        data_bytes32[key] = bytes32(value);
    }

    /*** Bytes ***/
    function getBytes(bytes32 key) external view returns(bytes memory) {
        return data_bytes[key];
    }

    function setBytes(bytes32 key, bytes calldata value) external storageOnly {
        data_bytes[key] = value;
    }

    /*** String ***/
    function getString(bytes32 key) external view returns(string memory) {
        return string(data_bytes[key]);
    }

    function setString(bytes32 key, string calldata value) external storageOnly {
        data_bytes[key] = bytes(value);
    }

    /*** Bytes Array ***/
    function getBytesArray(bytes32 key) external view returns (bytes32[] memory) {
        return data_bytesArray[key];
    }

    function getBytesArrayIndex(bytes32 key, uint256 index) external view returns (bytes32) {
        return data_bytesArray[key][index];
    }

    function getBytesArrayLength(bytes32 key) external view returns (uint256) {
        return data_bytesArray[key].length;
    }

    function pushBytesArray(bytes32 key, bytes32 value) external {
        data_bytesArray[key].push(value);
    }

    function setBytesArrayIndex(bytes32 key, uint256 index, bytes32 value) external storageOnly {
        data_bytesArray[key][index] = value;
    }

    function setBytesArray(bytes32 key, bytes32[] calldata value) external storageOnly {
        data_bytesArray[key] = value;
    }

    /*** Int Array ***/
    function getIntArray(bytes32 key) external view returns (int[] memory) {
        return data_intArray[key];
    }

    function getIntArrayIndex(bytes32 key, uint256 index) external view returns (int) {
        return data_intArray[key][index];
    }

    function getIntArrayLength(bytes32 key) external view returns (uint256) {
        return data_intArray[key].length;
    }

    function pushIntArray(bytes32 key, int value) external {
        data_intArray[key].push(value);
    }

    function setIntArrayIndex(bytes32 key, uint256 index, int value) external storageOnly {
        data_intArray[key][index] = value;
    }

    function setIntArray(bytes32 key, int[] calldata value) external storageOnly {
        data_intArray[key] = value;
    }

    /*** Address Array ***/
    function getAddressArray(bytes32 key) external view returns (address[] memory) {
        return data_addressArray[key];
    }

    function getAddressArrayIndex(bytes32 key, uint256 index) external view returns (address) {
        return data_addressArray[key][index];
    }

    function getAddressArrayLength(bytes32 key) external view returns (uint256) {
        return data_addressArray[key].length;
    }

    function pushAddressArray(bytes32 key, address value) external {
        data_addressArray[key].push(value);
    }

    function setAddressArrayIndex(bytes32 key, uint256 index, address value) external storageOnly {
        data_addressArray[key][index] = value;
    }

    function setAddressArray(bytes32 key, address[] calldata value) external storageOnly {
        data_addressArray[key] = value;
    }
}