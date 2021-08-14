// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "IModuleManager.sol";
import "IIdentity.sol";

contract Identity is IIdentity {
    address internal immutable _defaultModuleManager;

    bool internal _isInitialized;
    address public override owner;
    IModuleManager internal _moduleManager;

    modifier onlyModule() {
        require(
            _moduleManager.isModuleEnabled(msg.sender),
            "Identity: caller must be an enabled module"
        );
        _;
    }

    constructor(address defaultModuleManager) {
        require(
            defaultModuleManager != address(0),
            "Identity: module manager must not be the zero address"
        );

        _defaultModuleManager = defaultModuleManager;
    }

    function initialize(address initialOwner) external override {
        require(!_isInitialized, "Identity: contract is already initialized");

        _isInitialized = true;

        _setOwner(initialOwner);
        _setModuleManager(_defaultModuleManager);
    }

    function setOwner(address newOwner) external override onlyModule {
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function moduleManager() external view override returns (address) {
        return address(_moduleManager);
    }

    function setModuleManager(address newModuleManager)
        external
        override
        onlyModule
    {
        _setModuleManager(newModuleManager);
    }

    function _setModuleManager(address newModuleManager) internal {
        address oldModuleManager = address(_moduleManager);
        _moduleManager = IModuleManager(newModuleManager);

        emit ModuleManagerSwitched(oldModuleManager, newModuleManager);
        (oldModuleManager, newModuleManager);
    }

    function isModuleEnabled(address module)
        external
        view
        override
        returns (bool)
    {
        return _moduleManager.isModuleEnabled(module);
    }

    function getDelegate(bytes4 methodID)
        public
        view
        override
        returns (address)
    {
        return _moduleManager.getDelegate(methodID);
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external override onlyModule returns (bytes memory) {
        (bool success, bytes memory result) = to.call{value: value}(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        emit Executed(msg.sender, to, value, data);

        return result;
    }

    fallback() external payable {
        address module = _moduleManager.getDelegate(msg.sig);

        require(module != address(0), "Identity: unsupported method");

        _delegate(module);
    }

    receive() external payable {}

    function _delegate(address module) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := call(gas(), module, 0, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}