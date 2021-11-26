// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/// @title PollenDAO
/// @author Jaime Delgado
/// @notice Core implementation of pollen DAO
/// @dev This contract pass call function to modules

import "./PollenDAOStorage.sol";
import "./Modules/addressWhitelist/AddressWhitelistModuleStorage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PollenDAO is
    Initializable,
    PollenDAOStorage,
    AddressWhitelistModuleStorage
{
    event ModuleAdded(address indexed moduleAddr, string moduleName);
    event ModuleUpdated(address indexed newModuleAddr, address oldModuleAddr);
    event AdminRoleTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );
    event PollenTokenSet(address indexed pollenTokenAddr);

    /// @notice pass a call to a  module
    /// @dev the first parameter of the function call is the address of the module
    /* solhint-disable no-complex-fallback, payable-fallback, no-inline-assembly */
    fallback() external {
        DAOStorage storage ds = getPollenDAOStorage();

        assembly {
            // recovers first argument of the calldata (module address)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let module := mload(add(ptr, 4))

            // check in the isRegisteredModule mapping the values of the decoded address
            let ptr_ := add(ptr, calldatasize())
            mstore(ptr_, module)
            mstore(add(ptr_, 32), ds.slot)
            let hash := keccak256(ptr_, 64)
            let status := sload(hash)
            if eq(status, 0) {
                revert(0, 0) // revert if false
            }

            // generic proxy delegate call
            let result := delegatecall(gas(), module, ptr, calldatasize(), 0, 0)
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

    /* solhint-enable no-complex-fallback, payable-fallback, no-inline-assembly */

    /*****************
    EXTERNAL FUNCTIONS
    *****************/

    function initialize() external initializer {
        _setAdmin(msg.sender);
    }

    ///@notice Transfers admin role of the contract to a new account (`newAdmin`)
    ///@param newAdmin new PollenDAO admin
    function transferAdminRole(address newAdmin) external onlyAdmin {
        require(
            newAdmin != address(0),
            "PollenDAO: newAdmin cannot be zero address"
        );
        _setAdmin(newAdmin);
    }

    ///@notice Sets the address of the PollenToken, to be used throughout the protocol
    ///@param pollen address of pollenToken
    function setPollenToken(address pollen) external onlyAdmin {
        require(
            pollen != address(0),
            "PollenDAO: pollenToken cannot be zero address"
        );
        DAOStorage storage ds = getPollenDAOStorage();
        ds.pollenToken = pollen;

        emit PollenTokenSet(pollen);
    }

    /// @notice Register a new module address
    /// @param _moduleAddr address of the module to register
    /// @param _moduleName name of the module to register
    function registerModule(address _moduleAddr, string memory _moduleName)
        external
        onlyAdmin
    {
        DAOStorage storage ds = getPollenDAOStorage();
        require(
            !ds.isRegisteredModule[_moduleAddr],
            "PollenDAO: module exists"
        );
        ds.isRegisteredModule[_moduleAddr] = true;
        ds.moduleByName[_moduleName] = _moduleAddr;
        emit ModuleAdded(_moduleAddr, _moduleName);
    }

    /// @notice update a module address
    /// @param newAddr address of the new module to register
    /// @param oldAddr address of the old module to remove
    function updateModule(
        address newAddr,
        address oldAddr,
        string memory _moduleName
    ) external onlyAdmin {
        DAOStorage storage ds = getPollenDAOStorage();
        require(!ds.isRegisteredModule[newAddr], "PollenDAO: module exists");
        require(
            ds.isRegisteredModule[oldAddr],
            "PollenDAO: module doesn't exist"
        );
        ds.isRegisteredModule[oldAddr] = false;
        ds.isRegisteredModule[newAddr] = true;
        ds.moduleByName[_moduleName] = newAddr;
        emit ModuleUpdated(newAddr, oldAddr);
    }

    /*************
    VIEW FUNCTIONS
    *************/

    ///@return getter for admin address
    function daoAdmin() external view returns (address) {
        DAOStorage storage ds = getPollenDAOStorage();
        return ds.admin;
    }

    ///@notice getter for pollenToken address
    function pollenToken(address) external view returns (address) {
        DAOStorage storage ds = getPollenDAOStorage();
        return ds.pollenToken;
    }

    /****************
    PRIVATE FUNCTIONS
    ****************/

    ///@notice sets the admin of PollenDAO
    ///@param newAdmin new PollenDAO admin
    function _setAdmin(address newAdmin) private {
        DAOStorage storage ds = getPollenDAOStorage();
        address oldAdmin = ds.admin;
        ds.admin = newAdmin;
        emit AdminRoleTransferred(oldAdmin, newAdmin);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/// @title Quoter staorage contract
/// @author Jaime Delgado
/// @notice define the base storage required by the quoter module
/// @dev This contract must be inherited by modules that require access to variables defined here

contract PollenDAOStorage {
    bytes32 internal constant POLLENDAO_STORAGE_SLOT =
        keccak256("PollenDAO.storage");

    struct DAOStorage {
        // Mapping for registered modules (the mapping should always be the first element
        // ...if modified, the fallback must be modified as well)
        mapping(address => bool) isRegisteredModule;
        // mapping for proposalId => voterAddress => numVotes
        mapping(uint256 => mapping(address => uint256)) numVotes;
        // Module adddress by name
        mapping(string => address) moduleByName;
        // system admin
        address admin;
        // Pollen token
        address pollenToken;
    }

    modifier onlyAdmin() {
        DAOStorage storage ds = getPollenDAOStorage();
        require(msg.sender == ds.admin, "PollenDAO: admin access required");
        _;
    }

    /* solhint-disable no-inline-assembly */
    function getPollenDAOStorage()
        internal
        pure
        returns (DAOStorage storage ms)
    {
        bytes32 slot = POLLENDAO_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

/// @title AddressWhitelist storage contract
/// @notice define the storage required by the addressWhitelist module
/// @dev This contract must be inherited by modules that require access to variables defined here

contract AddressWhitelistModuleStorage {
    bytes32 private constant ADDRESS_WHITELIST_STORAGE_SLOT =
        keccak256("PollenDAO.addressWhitelist.storage");

    struct AddressWhitelistStorage {
        // Says if an address is whitelisted or not
        mapping(address => bool) onWhitelist;
    }

    /* solhint-disable no-inline-assembly */
    function getAddressWhitelistStorage()
        internal
        pure
        returns (AddressWhitelistStorage storage aws)
    {
        bytes32 slot = ADDRESS_WHITELIST_STORAGE_SLOT;
        assembly {
            aws.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}