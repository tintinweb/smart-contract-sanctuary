// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondLoupe } from "../../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../../interfaces/IDiamondCut.sol";
import { DiamondLib } from "./DiamondLib.sol";
import { JewelerLib } from "./JewelerLib.sol";

/**
 * @title MarketDiamond
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract MarketDiamond {

    /**
     * @notice Constructor
     *
     * - Store the access controller
     * - Make the initial facet cuts
     * - Declare support for interfaces
     *
     * @param _accessController - the Seen.Haus AccessController
     * @param _facetCuts - the initial facet cuts to make
     * @param _interfaceIds - the initially supported ERC-165 interface ids
     */
    constructor(
        IAccessControlUpgradeable _accessController,
        IDiamondCut.FacetCut[] memory _facetCuts,
        bytes4[] memory _interfaceIds
    ) payable {

        // Get the DiamondStorage struct
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Set the AccessController instance
        ds.accessController = _accessController;

        // Cut the diamond with the given facets
        JewelerLib.diamondCut(_facetCuts, address(0), new bytes(0));

        // Add supported interfaces
        if (_interfaceIds.length > 0) {
            for (uint8 x = 0; x < _interfaceIds.length; x++) {
                DiamondLib.addSupportedInterface(_interfaceIds[x]);
            }
        }

    }

    /**
     * @notice Onboard implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {

        // Get the DiamondStorage struct
        return DiamondLib.supportsInterface(_interfaceId) ;

    }

    /**
     * Fallback function. Called when the specified function doesn't exist
     *
     * Find facet for function that is called and execute the
     * function if a facet is found and returns any value.
     */
    fallback() external payable {

        // Get the DiamondStorage struct
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Make sure the function exists
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");

        // Invoke the function with delagatecall
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
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

    /// Contract can receive ETH
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondLoupe
 *
 * @notice Diamond Facet inspection
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x48e2b093
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondLoupe {

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondCut
 *
 * @notice Diamond Facet management
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x1f931c1c
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondCut {

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and
     * optionally execute a function with delegatecall
     *
     * _calldata is executed with delegatecall on _init
     *
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondCut } from "../../interfaces/IDiamondCut.sol";

/**
 * @title DiamondLib
 *
 * @notice Diamond storage slot and supported interfaces
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. Facet management functions from original `DiamondLib` were refactor/extracted
 * to JewelerLib, since business facets also use this library for access control and
 * managing supported interfaces.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library DiamondLib {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {

        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;

        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;

        // The number of function selectors in selectorSlots
        uint16 selectorCount;

        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;

        // The Seen.Haus AccessController
        IAccessControlUpgradeable accessController;

    }

    /**
     * @notice Get the Diamond storage slot
     *
     * @return ds - Diamond storage slot cast to DiamondStorage
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Add a supported interface to the Diamond
     *
     * @param _interfaceId - the interface to add
     */
    function addSupportedInterface(bytes4 _interfaceId) internal {

        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Flag the interfaces as supported
        ds.supportedInterfaces[_interfaceId] = true;
    }

    /**
     * @notice Implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     */
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {

        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Return the value
        return ds.supportedInterfaces[_interfaceId] || false;
    }

    /**
     * @notice Remove a supported interface from the Diamond
     *
     * @param _interfaceId - the interface to remove
     */
    function removeSupportedInterface(bytes4 _interfaceId) internal {

        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Remove interface supported flag
        delete ds.supportedInterfaces[_interfaceId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DiamondLib } from "./DiamondLib.sol";
import { IDiamondCut } from "../../interfaces/IDiamondCut.sol";

/**
 * @title JewelerLib
 *
 * @notice Facet management functions
 *
 * Based on Nick Mudge's gas-optimized diamond-2 reference.
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. The original `LibDiamond` contract used single-owner security scheme,
 * but this one uses role-based access via the Seen.Haus AccessController.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */

library JewelerLib {

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 internal constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 internal constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    /**
     * @notice Cut facets of the Diamond
     *
     * Add/replace/remove any number of function selectors
     *
     * If populated, _calldata is executed with delegatecall on _init
     *
     * @param _facetCuts Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        IDiamondCut.FacetCut[] memory _facetCuts,
        address _init,
        bytes memory _calldata
    ) internal {

        // Get the diamond storage slot
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Determine how many existing selectors we have
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;

        // Check if last selector slot is full
        // N.B.: selectorCount & 7 is a gas-efficient equivalent to selectorCount % 8
        if (selectorCount & 7 > 0) {

            // get last selectorSlot
            // N.B.: selectorCount >> 3 is a gas-efficient equivalent to selectorCount / 8
            selectorSlot = ds.selectorSlots[selectorCount >> 3];

        }

        // Cut the facets
        for (uint256 facetIndex; facetIndex < _facetCuts.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _facetCuts[facetIndex].facetAddress,
                _facetCuts[facetIndex].action,
                _facetCuts[facetIndex].functionSelectors
            );
        }

        // Update the selector count if it changed
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }

        // Update last selector slot
        // N.B.: selectorCount & 7 is a gas-efficient equivalent to selectorCount % 8
        if (selectorCount & 7 > 0) {

            // N.B.: selectorCount >> 3 is a gas-efficient equivalent to selectorCount / 8
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;

        }

        // Notify listeners of state change
        emit DiamondCut(_facetCuts, _init, _calldata);

        // Initialize the facet
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @notice Maintain the selectors in a FacetCut
     *
     * N.B. This method is unbelievably long and dense.
     * It hails from the diamond-2 reference and works
     * under test.
     *
     * I've added comments to try and reason about it
     * - CLH
     *
     * @param _selectorCount - the current selectorCount
     * @param _selectorSlot - the selector slot
     * @param _newFacetAddress - the facet address of the new or replacement function
     * @param _action - the action to perform. See: {IDiamondCut.FacetCutAction}
     * @param _selectors - the selectors to modify
     */
    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {

        // Make sure there are some selectors to work with
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");

        // Add a selector
        if (_action == IDiamondCut.FacetCutAction.Add) {

            // Make sure facet being added has code
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");

            // Iterate selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {

                // Make sure function doesn't already exist
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");

                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }

                // Increment selector count
                _selectorCount++;
            }

        // Replace a selector
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {

            // Make sure replacement facet has code
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");

            // Iterate selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {

                // Make sure function doesn't already exist
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");

                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);

            }

        // Remove a selector
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {

            // Make sure facet address is zero address
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");

            // Get the selector slot count and index to selector in slot
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;

            // Iterate selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {

                // Get previous selector slot, wrapping around to last from zero
                if (_selectorSlot == 0) {
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // Remove selector, swapping in with last selector in last slot
                // N.B. adding a block here prevents stack too deep error
                {
                    // get selector and facet, making sure it exists
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");

                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");

                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                // Update selector slot if count changed
                if (oldSelectorsSlotCount != selectorSlotCount) {

                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;

                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                // delete selector
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }

            // Update selector count
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;

        }

        // return updated selector count and selector slot for
        return (_selectorCount, _selectorSlot);
    }

    /**
     * @notice Call a facet's initializer
     *
     * @param _init - the address of the facet to be initialized
     * @param _calldata - the
     */
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {

        // If _init is not populated, then _calldata must also be unpopulated
        if (_init == address(0)) {

            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");

        } else {

            // Revert if _calldata is not populated
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");

            // Make sure address to be initialized has code
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }

            // If _init and _calldata are populated, call initializer
            (bool success, bytes memory error) = _init.delegatecall(_calldata);

            // Handle result
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }

        }
    }

    /**
     * @notice make sure the given address has code
     *
     * Reverts if address has no contract code
     *
     * @param _contract - the contract to check
     * @param _errorMessage - the revert reason to throw
     */
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

