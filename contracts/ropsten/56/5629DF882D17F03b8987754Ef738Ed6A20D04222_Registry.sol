/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: MIT AND AGPLv3
// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/common/Whitelist.sol

pragma solidity >=0.6.0 <0.7.0;


contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event LogAddToWhitelist(address indexed user);
    event LogRemoveFromWhitelist(address indexed user);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "only whitelist");
        _;
    }

    function addToWhitelist(address user) external onlyOwner {
        require(user != address(0), "WhiteList: 0x");
        whitelist[user] = true;
        emit LogAddToWhitelist(user);
    }

    function removeFromWhitelist(address user) external onlyOwner {
        require(user != address(0), "WhiteList: 0x");
        whitelist[user] = false;
        emit LogRemoveFromWhitelist(user);
    }
}

// File: contracts/vaults/yearnv2/v032/Registry.sol

contract Registry is Whitelist {

    struct contractData {
        uint256 deployedBlock;
        uint256 startBlock;
        uint256 endBlock;
        string abiVersion;
        string tag;
        string metaData;
        bool active;
    }

    mapping(string => address[]) public contractMap;
    mapping(address => contractData ) public contractInfo;

    function newContract(string calldata contractName, address contractAddress, uint256 _deployed, string calldata _abiVersion, string calldata _tag) external onlyWhitelist {
        require(contractInfo[contractAddress].deployedBlock == 0, 'Contract already set');
        address[] memory contracts = contractMap[contractName];
        contractMap[contractName].push(contractAddress);
        contractInfo[contractAddress].deployedBlock = _deployed;  
        contractInfo[contractAddress].abiVersion = _abiVersion;  
        contractInfo[contractAddress].tag = _tag;  
        contractInfo[contractAddress].active = false;  
    }

    function removeContract(string calldata contractName) external onlyWhitelist {
        address[] memory contracts = contractMap[contractName];
        address _contract = contracts[contracts.length - 1];
        contractMap[contractName].pop();
        contractInfo[_contract].deployedBlock = 0;  
        contractInfo[_contract].abiVersion = "";  
        contractInfo[_contract].tag = "";  
    }

    function forceUpdate(address contractAddress, uint256 _deployed, uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].deployedBlock = _deployed;  
        contractInfo[contractAddress].startBlock = _startBlock;  
        contractInfo[contractAddress].endBlock = _endBlock;  
    }

    function forceUpdateMeta(address contractAddress, string calldata _abiVersion, string calldata _tag, string calldata _metaData) external onlyOwner {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].abiVersion = _abiVersion;  
        contractInfo[contractAddress].tag = _tag;  
        contractInfo[contractAddress].metaData = _metaData;  
    }

    function setUpdatedContract(string calldata _contractName, uint256 _startBlock) external onlyWhitelist {
        address[] memory contracts = contractMap[_contractName];
        uint256 last = contracts.length;
        require(last > 0, 'No addresses for contracts');
        address latest = contracts[last - 1];
        address previous;
        if (last > 1) {
            previous = contracts[last - 2];
        } else {
            previous = address(0);
        }
        contractInfo[latest].startBlock = _startBlock;  
        contractInfo[latest].active = true;
        contractInfo[previous].endBlock = _startBlock;  
        contractInfo[previous].active = false;
    }

    function setMetaData(address contractAddress, string calldata _metaData) external onlyWhitelist {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].metaData = _metaData;  
    }

    function getContractMap(string calldata contractName) external view returns (address[] memory) {
        return contractMap[contractName];
    }

    function getLatest(string calldata contractName) external view returns (address) {
        return contractMap[contractName][contractMap[contractName].length - 1];
    }
}