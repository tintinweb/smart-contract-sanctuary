pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED

import "./external/contracts/proxy/OwnedUpgradeabilityProxy.sol";

/**
 * @title RigorProxy
 * @dev This contract provided functionality to update the core Rigor contracts.
 */
contract HomeFiProxy {
    // bytes2 array of upgradable contracts initials
    bytes2[] public allContractNames;

    // boolean which indicates true when all contracts are initialized, else false
    bool public homeFiInitialized;

    // mapping that tell if a particular address is active(latest version of contract)
    mapping(address => bool) internal contractsActive;

    // mapping that maps contract initials with there implementation address
    mapping(bytes2 => address payable) internal contractAddress;

    /// @dev make sure that sender is this contract owner
    modifier onlyProxyOwner() {
        OwnedUpgradeabilityProxy _proxy = OwnedUpgradeabilityProxy(
            payable(address(this))
        );
        require(
            msg.sender == _proxy.proxyOwner(),
            "Sender is not proxy owner."
        );
        _;
    }

    /**
     * @notice initialize all the homeFi contract in the correct sequential order and generate upgradable proxy for them.
     * @dev if more contract are added in homeFi, then their entry can be done here. can only be called by RigorProxy owner.
     * @param _implementations the implementation address of homeFi smart contract in correct sequence.
     */
    function initiateHomeFi(address[] calldata _implementations)
        external
        onlyProxyOwner
    {
        require(!homeFiInitialized);

        //Initial contract names
        allContractNames.push("PL");
        allContractNames.push("CN");
        allContractNames.push("DP");
        allContractNames.push("EN");
        allContractNames.push("TE");
        allContractNames.push("TD");
        allContractNames.push("TU");

        require(
            allContractNames.length == _implementations.length,
            "Implementation length not match"
        );
        contractsActive[address(this)] = true;
        for (uint256 i = 0; i < allContractNames.length; i++) {
            _generateProxy(allContractNames[i], _implementations[i]);
        }
        homeFiInitialized = true;
    }

    /**
     * @notice adds a new contract type/implementation to Rigor
     * @dev can only be called by RigorProxy owner
     * @param _contractName initial of contract to be added
     * @param _contractAddress address of contract implementation to be added.
     */
    function addNewContract(bytes2 _contractName, address _contractAddress)
        external
        onlyProxyOwner
    {
        require(_contractAddress != address(0), "Zero address");
        require(
            contractAddress[_contractName] == address(0),
            "Contract code already available"
        );
        allContractNames.push(_contractName);
        _generateProxy(_contractName, _contractAddress);
    }

    /**
     * @notice upgrades a multiple contract implementations. Replaces old implementation with new
     * @dev can only be called by RigorProxy owner
     * @param _contractNames bytes2 array of contract initials that needs to be upgraded
     * @param _contractAddresses address array of contract implementation address that needs to be upgraded
     */
    function upgradeMultipleImplementations(
        bytes2[] calldata _contractNames,
        address[] calldata _contractAddresses
    ) external onlyProxyOwner {
        require(
            _contractNames.length == _contractAddresses.length,
            "Array length should be equal."
        );
        for (uint256 i = 0; i < _contractNames.length; i++) {
            require(
                _contractAddresses[i] != address(0),
                "null address is not allowed."
            );
            _replaceImplementation(_contractNames[i], _contractAddresses[i]);
        }
    }

    /**
     * @notice To check if we use the particular contract.
     * @param _address The contract address to check if it is active or not.
     * @return true if _address is active else false
     */
    function isInternal(address _address) public view returns (bool) {
        return contractsActive[_address];
    }

    /**
     * @notice Gets latest contract address
     * @param _contractName Contract name to fetch
     * @return current implementation address corresponding to _contractName
     */
    function getLatestAddress(bytes2 _contractName)
        public
        view
        returns (address)
    {
        return contractAddress[_contractName];
    }

    /**
     * @dev Replaces the implementations of the contract.
     * @param _contractsName The name of the contract.
     * @param _contractAddress The address of the contract to replace the implementations for.
     */
    function _replaceImplementation(
        bytes2 _contractsName,
        address _contractAddress
    ) internal {
        OwnedUpgradeabilityProxy tempInstance = OwnedUpgradeabilityProxy(
            contractAddress[_contractsName]
        );
        tempInstance.upgradeTo(_contractAddress);
    }

    /**
     * @dev to generator upgradable proxy
     * @param _contractName initial of the contract
     * @param _contractAddress of the proxy
     */
    function _generateProxy(bytes2 _contractName, address _contractAddress)
        internal
    {
        OwnedUpgradeabilityProxy tempInstance = new OwnedUpgradeabilityProxy(
            _contractAddress
        );
        contractAddress[_contractName] = payable(address(tempInstance));
        contractsActive[address(tempInstance)] = true;
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED
import "./UpgradeabilityProxy.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    // Storage position of the owner of the contract
    bytes32 private constant PROXY_OWNER_POSITION =
        keccak256("org.rigour.proxy.owner");

    /**
     * @dev the constructor sets the original owner of the contract to the sender account.
     */
    constructor(address _implementation) {
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
    }

    /**
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param _implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Sets the address of the owner
     */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED
import "./Proxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant IMPLEMENTATION_POSITION =
        keccak256("org.govblocks.proxy.implementation");

    /**
     * @dev Constructor function
     */
    constructor() {}

    function implementation() public view override returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Sets the address of the current implementation
     * @param _newImplementation address representing the new implementation to be set
     */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    function _fallback() internal {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);



    /**
     * @dev Fallback function that delegates calls to the address returned by `implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }


    /**
     * @dev Fallback function that delegates calls to the address returned by `implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}