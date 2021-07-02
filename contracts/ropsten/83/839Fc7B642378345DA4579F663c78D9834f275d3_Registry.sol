/**
 *Submitted for verification at Etherscan.io on 2021-07-02
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

pragma experimental ABIEncoderV2;

contract Registry is Whitelist {

    struct contractData {
        uint256 deployedBlock;
        uint256[] startBlock;
        uint256[] endBlock;
        string abiVersion;
        string tag;
        string metaData;
        bool active;
    }

    mapping(string => address[]) public contractMap;
    mapping(address => contractData ) public contractInfo;
    mapping(string => bool) public activeKey;
    string[] public keys;

    event LogNewContract(string indexed contractName, address indexed contractAddress, bool contractTypeActivated);
    event LogRemovedContract(string indexed contractName, address indexed contractAddress);
    event LogContractActivated(string indexed contractName, address indexed contractActivated, address contractDeactivated);
    event LogForceUpdate(address indexed contractAddress,  uint256 _deployed, uint256 _startBlock, uint256 _endBlock);
    event LogForceUpdateMeta(address contractAddress, string _abiVersion, string _tag, string _metaData);

    function newContract(string calldata contractName, address contractAddress, uint256 _deployed, string calldata _abiVersion, string calldata _tag) external onlyWhitelist {
        require(contractInfo[contractAddress].deployedBlock == 0, 'newContract: Alreaddy in registry');

        bool newContractType;
        contractMap[contractName].push(contractAddress);
        contractInfo[contractAddress].deployedBlock = _deployed;  
        contractInfo[contractAddress].abiVersion = _abiVersion;  
        contractInfo[contractAddress].tag = _tag;  
        contractInfo[contractAddress].active = false;  
        if (!activeKey[contractName]) {
            newContractType = true;
            activeKey[contractName] = true;
            keys.push(contractName);
        }
        emit LogNewContract(contractName, contractAddress, newContractType);
    }

    function getKeys() external view returns (string[] memory) {
        uint256 keyLength = keys.length; 
        string[] memory _keys = new string[](keyLength);
        uint256 j;
        for (uint256 i; i < keyLength; i++) {
            if (contractMap[keys[i]].length != 0) {
                _keys[j] = keys[i];
                j++;
            }
        }
        return _keys;
    }

    function removeContract(string calldata contractName) external onlyWhitelist {
        address[] memory contracts = contractMap[contractName];
        require(contracts.length > 0, 'removeContract: No deployed contracts');
        address _contract = contracts[contracts.length - 1];
        contractMap[contractName].pop();
        contractInfo[_contract].deployedBlock = 0;  
        contractInfo[_contract].abiVersion = "";  
        contractInfo[_contract].tag = "";  
        contractInfo[_contract].metaData = "";
        contractInfo[_contract].active = false;
        emit LogRemovedContract(contractName, _contract);
    }

    function forceUpdate(address contractAddress, uint256 _deployed, uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].deployedBlock = _deployed;  
        contractInfo[contractAddress].startBlock.push(_startBlock);  
        contractInfo[contractAddress].endBlock.push(_endBlock);
        emit LogForceUpdate(contractAddress,  _deployed, _startBlock, _endBlock);
    }

    function forceUpdateMeta(address contractAddress, string calldata _abiVersion, string calldata _tag, string calldata _metaData) external onlyOwner {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].abiVersion = _abiVersion;  
        contractInfo[contractAddress].tag = _tag;  
        contractInfo[contractAddress].metaData = _metaData;  
        emit LogForceUpdateMeta(contractAddress, _abiVersion, _tag, _metaData);
    }

    function activateContract(string calldata _contractName, address _contractAddress, uint256 _startBlock) external onlyWhitelist {
        address[] memory contracts = contractMap[_contractName];
        uint256 contractLength = contracts.length;
        require(contractLength > 0, 'No addresses for contracts');
        address deactivated;
        for(uint256 i; i < contractLength; i++) {
            if (contractInfo[contracts[i]].active) {
                require(contracts[i] != _contractAddress, 'activateContract: !Already active');
                deactivated = contracts[i];
                contractInfo[contracts[i]].active = false;
                contractInfo[contracts[i]].endBlock.push(_startBlock);  
            }
        }
        contractInfo[_contractAddress].startBlock.push(_startBlock);  
        contractInfo[_contractAddress].active = true;
        emit LogContractActivated(_contractName, _contractAddress, deactivated);
    }

    function setMetaData(address contractAddress, string calldata _metaData) external onlyWhitelist {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].metaData = _metaData;  
    }

    function getContractMap(string calldata contractName) external view returns (address[] memory) {
        return contractMap[contractName];
    }

    function getLatestData(string calldata contractName) external view returns (contractData memory data) {
        address[] memory contracts = contractMap[contractName];
        uint256 contractLength = contracts.length;
        if (contractLength > 0) {
            return contractInfo[contracts[contractLength]];
        }
        return contractInfo[address(0)];
    }

    function getLatest(string calldata contractName) external view returns (address) {
        return contractMap[contractName][contractMap[contractName].length - 1];
    }

    function getActiveData(string calldata contractName) external view returns (contractData memory data) {
        address[] memory contracts = contractMap[contractName];
        for(uint256 i; i < contracts.length; i++) {
            if (contractInfo[contracts[i]].active) {
                return contractInfo[contracts[i]];
            }
        }
        return contractInfo[address(0)];
    }

    function getActive(string calldata contractName) external view returns (address) {
        address[] memory contracts = contractMap[contractName];
        for(uint256 i; i < contracts.length; i++) {
            if (contractInfo[contracts[i]].active) {
                return contracts[i];
            }
        }
        return address(0);
    }
}