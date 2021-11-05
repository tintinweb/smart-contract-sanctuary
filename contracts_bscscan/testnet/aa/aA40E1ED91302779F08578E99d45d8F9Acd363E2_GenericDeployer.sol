// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

interface IDeployerModule {
    function deployGeneric(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address owner_,
        address presaler
    ) external returns (address);
}

contract GenericDeployer is Ownable {
    struct DeployedContractData {
        uint256 index;
        uint256 _type;
        uint256 timestamp;
        address deployer;
    }

    struct ModuleData {
        uint256 index;
        string name;
        bool deprecated;
    }

    mapping(address => DeployedContractData) public deployedContractData;
    mapping(address => ModuleData) public moduleData;

    address[] public deployedContracts;
    address[] public modules;

    bool public accessIsFree = true;
    mapping(address => bool) public hasAccess;

    modifier restricted() {
        require(accessIsFree || hasAccess[_msgSender()], 'You have no access to use this contract');
        _;
    }

    function deployGeneric(
        uint256 _type,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address owner_,
        address presaler
    ) public restricted returns (address deployed) {
        require(_type < modules.length, 'Unsupported type');
        require(!moduleData[modules[_type]].deprecated || _msgSender() == owner(), 'Module is deprecated');
        deployed = IDeployerModule(modules[_type]).deployGeneric(
            name_,
            symbol_,
            decimals_,
            totalSupply_,
            owner_,
            presaler
        );
        deployedContractData[deployed] = DeployedContractData({
            index: deployedContracts.length,
            _type: _type,
            timestamp: block.timestamp,
            deployer: _msgSender()
        });
        deployedContracts.push(deployed);
    }

    // SETTERS

    function includeModule(address adr, string memory name) public onlyOwner {
        if (modules.length > 0) require(moduleData[adr].index == 0, 'Module already included');
        moduleData[adr] = ModuleData({index: modules.length, name: name, deprecated: false});
        modules.push(adr);
    }

    function setModuleName(address adr, string memory name) public onlyOwner {
        moduleData[adr].name = name;
    }

    function setModuleDeprecated(address adr, bool deprecated) public onlyOwner {
        moduleData[adr].deprecated = deprecated;
    }

    function setAccess(address account, bool allow) public onlyOwner {
        hasAccess[account] = allow;
    }

    function setAccessIsFree(bool allow) public onlyOwner {
        accessIsFree = allow;
    }

    // GETTERS

    function getModules() public view returns (address[] memory) {
        return modules;
    }

    function getModulesFull() public view returns (address[] memory addresses, ModuleData[] memory datas) {
        addresses = modules;
        datas = new ModuleData[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            datas[i] = moduleData[addresses[i]];
        }
    }

    function getDeployedContracts() public view returns (address[] memory) {
        return deployedContracts;
    }

    function getDeployedContractsFull()
        public
        view
        returns (address[] memory addresses, DeployedContractData[] memory datas)
    {
        addresses = deployedContracts;
        datas = new DeployedContractData[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            datas[i] = deployedContractData[addresses[i]];
        }
    }

    function getDeployedContractsBy(address deployer)
        public
        view
        returns (address[] memory addresses, DeployedContractData[] memory datas)
    {
        uint256 length;
        for (uint256 i = 0; i < deployedContracts.length; i++) {
            if (deployedContractData[deployedContracts[i]].deployer == deployer) {
                length++;
            }
        }
        addresses = new address[](length);
        datas = new DeployedContractData[](length);
        uint256 index;
        for (uint256 i = 0; i < deployedContracts.length; i++) {
            if (deployedContractData[deployedContracts[i]].deployer == deployer) {
                addresses[index] = deployedContracts[i];
                datas[index] = deployedContractData[deployedContracts[i]];
                index++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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