// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {IRideCut} from "../../interfaces/utils/IRideCut.sol";
import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";
import {RideLibCutAndLoupe} from "../../libraries/utils/RideLibCutAndLoupe.sol";

contract RideCut is IRideCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _rideCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function rideCut(
        FacetCut[] calldata _rideCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        RideLibOwnership._requireIsContractOwner();
        RideLibCutAndLoupe.StorageCutAndLoupe storage ds = RideLibCutAndLoupe
            ._storageCutAndLoupe();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _rideCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = RideLibCutAndLoupe
                ._addReplaceRemoveFacetSelectors(
                    selectorCount,
                    selectorSlot,
                    _rideCut[facetIndex].facetAddress,
                    _rideCut[facetIndex].action,
                    _rideCut[facetIndex].functionSelectors
                );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit RideCut(_rideCut, _init, _calldata);
        RideLibCutAndLoupe._initializeRideCut(_init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _rideCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function rideCut(
        FacetCut[] calldata _rideCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event RideCut(FacetCut[] _rideCut, address _init, bytes _calldata);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibOwnership {
    bytes32 constant STORAGE_POSITION_OWNERSHIP = keccak256("ds.ownership");

    struct StorageOwnership {
        address contractOwner;
    }

    function _storageOwnership()
        internal
        pure
        returns (StorageOwnership storage s)
    {
        bytes32 position = STORAGE_POSITION_OWNERSHIP;
        assembly {
            s.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _setContractOwner(address _newOwner) internal {
        StorageOwnership storage s1 = _storageOwnership();
        address previousOwner = s1.contractOwner;
        s1.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _contractOwner() internal view returns (address) {
        return _storageOwnership().contractOwner;
    }

    function _requireIsContractOwner() internal view {
        require(
            msg.sender == _storageOwnership().contractOwner,
            "not contract owner"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {IRideCut} from "../../interfaces/utils/IRideCut.sol";

library RideLibCutAndLoupe {
    bytes32 constant STORAGE_POSITION_CUTANDLOUPE = keccak256("ds.cutandloupe");

    struct StorageCutAndLoupe {
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
    }

    function _storageCutAndLoupe()
        internal
        pure
        returns (StorageCutAndLoupe storage s)
    {
        bytes32 position = STORAGE_POSITION_CUTANDLOUPE;
        assembly {
            s.slot := position
        }
    }

    event RideCut(IRideCut.FacetCut[] _rideCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of rideCut
    // This code is almost the same as the external rideCut,
    // except it is using 'Facet[] memory _rideCut' instead of
    // 'Facet[] calldata _rideCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function rideCut(
        IRideCut.FacetCut[] memory _rideCut,
        address _init,
        bytes memory _calldata
    ) internal {
        StorageCutAndLoupe storage s1 = _storageCutAndLoupe();
        uint256 originalSelectorCount = s1.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = s1.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _rideCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = _addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _rideCut[facetIndex].facetAddress,
                _rideCut[facetIndex].action,
                _rideCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            s1.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            s1.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit RideCut(_rideCut, _init, _calldata);
        _initializeRideCut(_init, _calldata);
    }

    function _addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IRideCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        StorageCutAndLoupe storage s1 = _storageCutAndLoupe();
        require(
            _selectors.length > 0,
            "RideLibCutAndLoupe: No selectors in facet to cut"
        );
        if (_action == IRideCut.FacetCutAction.Add) {
            _requireHasContractCode(
                _newFacetAddress,
                "RideLibCutAndLoupe: Add facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = s1.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "RideLibCutAndLoupe: Can't add function that already exists"
                );
                // add facet for selector
                s1.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    s1.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IRideCut.FacetCutAction.Replace) {
            _requireHasContractCode(
                _newFacetAddress,
                "RideLibCutAndLoupe: Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = s1.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "RideLibCutAndLoupe: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "RideLibCutAndLoupe: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "RideLibCutAndLoupe: Can't replace function that doesn't exist"
                );
                // replace old facet address
                s1.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == IRideCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "RideLibCutAndLoupe: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = s1.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = s1.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "RideLibCutAndLoupe: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "RideLibCutAndLoupe: Can't remove immutable function"
                    );
                    // replace selector with last selector in s1.facets
                    // gets the last selector
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        s1.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(s1.facets[lastSelector]);
                    }
                    delete s1.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = s1.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    s1.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete s1.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("RideLibCutAndLoupe: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function _initializeRideCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "RideLibCutAndLoupe: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "RideLibCutAndLoupe: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                _requireHasContractCode(
                    _init,
                    "RideLibCutAndLoupe: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("RideLibCutAndLoupe: _init function reverted");
                }
            }
        }
    }

    function _requireHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}