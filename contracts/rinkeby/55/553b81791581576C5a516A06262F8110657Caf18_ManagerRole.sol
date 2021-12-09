// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "../RoleStore.sol";

/* LIBRARY IMPORTS */

import "../base/Roles.sol";
import "../../util/ContextLib.sol";

library ManagerRole {
    /* LIBRARY USAGE */
    
    using Roles for Role;

    /* EVENTS */

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    /* MODIFIERS */

    modifier onlyUninitialized(RoleStore storage s) {
        require(!s.initialized, "ManagerRole::onlyUninitialized: ALREADY_INITIALIZED");
        _;
    }

    modifier onlyInitialized(RoleStore storage s) {
        require(s.initialized, "ManagerRole::onlyInitialized: NOT_INITIALIZED");
        _;
    }

    modifier onlyManager(RoleStore storage s) {
        require(s.managers.has(ContextLib._msgSender()), "ManagerRole::onlyManager: NOT_MANAGER");
        _;
    }

    /* INITIALIZE METHODS */
    
    // NOTE: call only in calling contract context initialize function(), do not expose anywhere else
    function initializeManagerRole(
        RoleStore storage s,
        address account
    )
        external
        onlyUninitialized(s)
     {
        _addManager(s, account);
        s.initialized = true;
    }

    /* EXTERNAL STATE CHANGE METHODS */
    
    function addManager(
        RoleStore storage s,
        address account
    )
        external
        onlyManager(s)
        onlyInitialized(s)
    {
        _addManager(s, account);
    }

    function renounceManager(
        RoleStore storage s
    )
        external
        onlyInitialized(s)
    {
        _removeManager(s, ContextLib._msgSender());
    }

    /* EXTERNAL GETTER METHODS */

    function isManager(
        RoleStore storage s,
        address account
    )
        external
        view
        returns (bool)
    {
         return s.managers.has(account);
    }

    /* INTERNAL LOGIC METHODS */

    function _addManager(
        RoleStore storage s,
        address account
    )
        internal
    {
        s.managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(
        RoleStore storage s,
        address account
    )
        internal
    {
        s.managers.safeRemove(account);
        emit ManagerRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./base/RoleStruct.sol";

struct RoleStore {
    bool initialized;
    Role managers;
    Role governance;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "./RoleStruct.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    
    /* GETTER METHODS */

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles.has: ZERO_ADDRESS");
        return role.bearer[account];
    }

    /**
     * @dev Check if this role has at least one account assigned to it.
     * @return bool
     */
    function atLeastOneBearer(uint256 numberOfBearers) internal pure returns (bool) {
        if (numberOfBearers > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Give an account access to this role.
     */
    function add(
        Role storage role,
        address account
    )
        internal
    {
        require(
            !has(role, account),
            "Roles.add: ALREADY_ASSIGNED"
        );

        role.bearer[account] = true;
        role.numberOfBearers += 1;
    }

    /**
     * @dev Remove an account's access to this role. (1 account minimum enforced for safeRemove)
     */
    function safeRemove(
        Role storage role,
        address account
    )
        internal
    {
        require(
            has(role, account),
            "Roles.safeRemove: INVALID_ACCOUNT"
        );
        uint256 numberOfBearers = role.numberOfBearers -= 1; // roles that use safeRemove must implement initializeRole() and onlyIntialized() and must set the contract deployer as the first account, otherwise this can underflow below zero
        require(
            atLeastOneBearer(numberOfBearers),
            "Roles.safeRemove: MINIMUM_ACCOUNTS"
        );
        
        role.bearer[account] = false;
    }

    /**
     * @dev Remove an account's access to this role. (no minimum enforced)
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles.remove: INVALID_ACCOUNT");
        role.numberOfBearers -= 1;
        
        role.bearer[account] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

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
library ContextLib {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* STRUCTS */

struct Role {
    mapping (address => bool) bearer;
    uint256 numberOfBearers;
}