/**
 *Submitted for verification at Etherscan.io on 2021-07-07
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

/// @notice Registry for holding gro protocol contract information on chain
/// *****************************************************************************
/// The registry allows for external entities to verfiy what contracts are active
/// and at which point a contract was deactivated/activated. This will simplify
/// the tracking of statistics for bots etc. Additional meta data can be attached
/// to each contract.
/// *****************************************************************************
/// Contract storage:
///     Deployed contract addresses are stored in an array inside a mapping which
///     key is the name of the contract type, e.g.
///         "VaultAdapter" => ['0x...', '0x...', ...]
///     Each address is in turn mapped to a contract data struct that holds infromation 
///     regarding the contract, e.g.
///         '0x...' => {deployedBlock: x, startBlock: [x, y], endBlock: [z]...}
///
/// Contract data:
///     The following data fields are defined inside the contract data struct:
///        deployedBlock - Which block was deployed
///        startBlock - Array containing the blocks in which the contract was set to active
///        uint256[] endBlock - Array containing the blocks in which the contract was set to inactive
///        string abiVersion - Hash of commit used for the contract deployment
///        string tag - Inidication of what type of contract it is (core, strategy etc)
///        string metaData - additional data used by external actors, provided as a JSON string 
///        bool active - If this contract is the active one, there can only be one active contract per
///         contract group.
///
/// Additional data:
///     The contract contains data regarding exposures (protocols/tokens) that are used to assist 
///     external actors. This data is stored in arrays where the index of item in the array will be
///     used to reference the protocols/tokens in the meta data. The index of a protocol/token can
///     be retrieved by using the protocolMap/tokenMap, a return value of 0 indicates that its
///     not present in the registry.
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

    mapping(string => address[]) contractMap;
    mapping(address => contractData ) contractInfo;

    mapping(string => bool) activeKey;
    mapping(string => uint256) protocolMap;
    mapping(address => uint256) tokenMap;

    string[] keys;
    string[] protocols;
    address[] tokens;

    event LogNewContract(string indexed contractName, address indexed contractAddress, bool contractTypeActivated);
    event LogNewProtocol(string indexed protocol, uint256 index);
    event LogNewToken(address indexed token, uint256 index);
    event LogRemovedContract(string indexed contractName, address indexed contractAddress);
    event LogContractActivated(string indexed contractName, address indexed contractActivated, address contractDeactivated);
    event LogForceUpdate(address indexed contractAddress,  uint256 _deployed, uint256 _startBlock, uint256 _endBlock);
    event LogForceUpdateMeta(address contractAddress, string _abiVersion, string _tag, string _metaData);

    /// @notice returns a list of active Contract keys in the registry
    /// @dev if there are no deployed contracts associated with the key,
    ///     it wont be displayed but rather returned as an empty string
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

    function getProtocol(uint256 index) external view returns (string memory) {
        require(protocols.length > 1, 'getProtocol: No protocols added');
        require(index > 0, 'getProtocol: index = 0');
        return protocols[index - 1];
    }

    function getToken(uint256 index) external view returns (address) {
        require(tokens.length > 1, 'getToken: No tokens added');
        require(index > 0, 'getProtocol: index = 0');
        return tokens[index - 1];
    }

    /// @notice Add a new deployed contract to the registry
    /// @param contractName The Contract type (Controller, WithdrawHandler, DaiVaultAdapter etc)
    /// @param contractAddress Address of the deployed contract
    /// @param _deployed BlockNumber the contract was deployed
    /// @param _abiVersion Hash of commit used for contract deployment
    /// @param _tag Indicator of the contract type
    /// @dev New contractNames will be added to the keys list
    function newContract(string calldata contractName, address contractAddress, uint256 _deployed, string calldata _abiVersion, string calldata _tag) external onlyWhitelist {
        require(contractInfo[contractAddress].deployedBlock == 0, 'newContract: Already in registry');

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
    /// @notice Add a new protocol to the registry
    /// @param _protocol Protocol name
    function addProtocol(string calldata _protocol) external onlyWhitelist {
        require(protocolMap[_protocol] == 0, 'addProtocol: protocol already added');
        protocols.push(_protocol);
        uint256 position = protocols.length;
        protocolMap[_protocol] = position;
        emit LogNewProtocol(_protocol, position);
    }

    /// @notice Add a new token to the registry
    /// @param _token Token address
    function addToken(address _token) external onlyWhitelist {
        require(tokenMap[_token] == 0, 'addToken: token already added');
        tokens.push(_token);
        uint256 position = tokens.length;
        tokenMap[_token] = position;
        emit LogNewToken(_token, position);
    }

    /// @notice Pop last added contract from the contractMap array, removing all associated data
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

    /// @notice Force an update of contract information
    /// @param contractAddress Address of the deployed contract
    /// @param _deployed Block number the contract was deployed
    /// @param _startBlock Block number the contract was activated
    /// @param _endBlock block number the contract was deactivated
    /// @dev start/end blocks of 0 will skip updating those fields, will otherwise pop and replace last value
    function forceUpdate(address contractAddress, uint256 _deployed, uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].deployedBlock = _deployed;  
        if (_startBlock > 0) {
            contractInfo[contractAddress].startBlock.pop();  
            contractInfo[contractAddress].startBlock.push(_startBlock);  
        }
        if (_endBlock > 0) {
            contractInfo[contractAddress].endBlock.pop();  
            contractInfo[contractAddress].endBlock.push(_endBlock);
        }
        emit LogForceUpdate(contractAddress,  _deployed, _startBlock, _endBlock);
    }

    /// @notice Force an updated of contract meta data, effectively overwritting old values
    /// @param contractAddress Address of the deployed contract
    /// @param _abiVersion New ABI version
    /// @param _tag New tag
    /// @param _metaData new MetaData
    function forceUpdateMeta(address contractAddress, string calldata _abiVersion, string calldata _tag, string calldata _metaData) external onlyOwner {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].abiVersion = _abiVersion;  
        contractInfo[contractAddress].tag = _tag;  
        contractInfo[contractAddress].metaData = _metaData;  
        emit LogForceUpdateMeta(contractAddress, _abiVersion, _tag, _metaData);
    }

    /// @notice Designate a new contract as active, disabling the last active one 
    /// @param _contractName Contract group name
    /// @param _contractAddress Address of contract to start
    /// @param _startBlock Block this contract was activated
    function activateContract(string calldata _contractName, address _contractAddress, uint256 _startBlock) external onlyWhitelist {
        address[] memory contracts = contractMap[_contractName];
        uint256 contractLength = contracts.length;
        require(contractLength > 0, 'No addresses for contracts');
        address deactivated;
        bool newActiveExists;
        for(uint256 i; i < contractLength; i++) {
            if (contracts[i] == _contractAddress) {
                newActiveExists = true;
            }
            if (contractInfo[contracts[i]].active) {
                require(contracts[i] != _contractAddress, 'activateContract: !Already active');
                deactivated = contracts[i];
                contractInfo[contracts[i]].active = false;
                contractInfo[contracts[i]].endBlock.push(_startBlock);  
            }
        }
        require(newActiveExists, 'activateContract: contract not added to group'); 
        contractInfo[_contractAddress].startBlock.push(_startBlock);  
        contractInfo[_contractAddress].active = true;
        emit LogContractActivated(_contractName, _contractAddress, deactivated);
    }

    /// @notice Add meta data to contract
    /// @param contractAddress Address of target contract
    /// @param _metaData Meta data JSON string
    function setMetaData(address contractAddress, string calldata _metaData) external onlyWhitelist {
        require(contractInfo[contractAddress].deployedBlock > 0, 'No contract');
        contractInfo[contractAddress].metaData = _metaData;  
    }

    /// @notice Get all deployed contracts in a contract type group
    /// @param contractName Contract type name
    function getContractMap(string calldata contractName) external view returns (address[] memory) {
        return contractMap[contractName];
    }

    /// @notice Get the contract data of the last added contract in a contract type group
    /// @param contractName Contract type name
    function getLatestData(string calldata contractName) external view returns (contractData memory data) {
        address[] memory contracts = contractMap[contractName];
        uint256 contractLength = contracts.length;
        if (contractLength > 0) {
            return contractInfo[contracts[contractLength - 1]];
        }
        return contractInfo[address(0)];
    }

    /// @notice Get the contract data of the last added contract in a contract type group
    /// @param contractName Contract type name
    function getLatest(string calldata contractName) external view returns (address) {
        return contractMap[contractName][contractMap[contractName].length - 1];
    }

    /// @notice Get the contract data of the active contract in a contract type group
    /// @param contractName Contract type name
    function getActiveData(string calldata contractName) external view returns (contractData memory data) {
        address[] memory contracts = contractMap[contractName];
        for(uint256 i; i < contracts.length; i++) {
            if (contractInfo[contracts[i]].active) {
                return contractInfo[contracts[i]];
            }
        }
        return contractInfo[address(0)];
    }

    /// @notice Get the address of the active contract in a contract type group
    /// @param contractName Contract type name
    function getActive(string calldata contractName) external view returns (address) {
        address[] memory contracts = contractMap[contractName];
        for(uint256 i; i < contracts.length; i++) {
            if (contractInfo[contracts[i]].active) {
                return contracts[i];
            }
        }
        return address(0);
    }

    /// @notice Get data for specified contract
    /// @param contractAddress Address of the deployed contract
    function getContractData(address contractAddress) external view returns (contractData memory) {
        return contractInfo[contractAddress];
    }
}