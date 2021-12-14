// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibOwnership.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibOwnership.enforceIsContractOwner();

        uint256 selectorCount = LibDiamondStorage.diamondStorage().selectors.length;
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            FacetCut memory cut;
            cut.action = _diamondCut[facetIndex].action;
            cut.facetAddress = _diamondCut[facetIndex].facetAddress;
            cut.functionSelectors = _diamondCut[facetIndex].functionSelectors;

            selectorCount = LibDiamond.executeDiamondCut(selectorCount, cut);
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        LibDiamond.initializeDiamondCut(_init, _calldata);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import "./LibDiamondStorage.sol";

library LibDiamond {
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        uint256 selectorCount = LibDiamondStorage.diamondStorage().selectors.length;

        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            selectorCount = executeDiamondCut(selectorCount, _diamondCut[facetIndex]);
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        initializeDiamondCut(_init, _calldata);
    }

    // executeDiamondCut takes one single FacetCut action and executes it
    // if FacetCutAction can't be identified, it reverts
    function executeDiamondCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256) {
        require(cut.functionSelectors.length > 0, "LibDiamond: No selectors in facet to cut");

        if (cut.action == IDiamondCut.FacetCutAction.Add) {
            require(cut.facetAddress != address(0), "LibDiamond: add facet address can't be address(0)");
            enforceHasContractCode(cut.facetAddress, "LibDiamond: add facet must have code");

            return _handleAddCut(selectorCount, cut);
        }

        if (cut.action == IDiamondCut.FacetCutAction.Replace) {
            require(cut.facetAddress != address(0), "LibDiamond: remove facet address can't be address(0)");
            enforceHasContractCode(cut.facetAddress, "LibDiamond: remove facet must have code");

            return _handleReplaceCut(selectorCount, cut);
        }

        if (cut.action == IDiamondCut.FacetCutAction.Remove) {
            require(cut.facetAddress == address(0), "LibDiamond: remove facet address must be address(0)");

            return _handleRemoveCut(selectorCount, cut);
        }

        revert("LibDiamondCut: Incorrect FacetCutAction");
    }

    // _handleAddCut executes a cut with the type Add
    // it reverts if the selector already exists
    function _handleAddCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];

            address oldFacetAddress = ds.facets[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");

            ds.facets[selector] = LibDiamondStorage.Facet(
                cut.facetAddress,
                uint16(selectorCount)
            );
            ds.selectors.push(selector);

            selectorCount++;
        }

        return selectorCount;
    }

    // _handleReplaceCut executes a cut with the type Replace
    // it does not allow replacing immutable functions
    // it does not allow replacing with the same function
    // it does not allow replacing a function that does not exist
    function _handleReplaceCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];

            address oldFacetAddress = ds.facets[selector].facetAddress;

            // only useful if immutable functions exist
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != cut.facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");

            // replace old facet address
            ds.facets[selector].facetAddress = cut.facetAddress;
        }

        return selectorCount;
    }

    // _handleRemoveCut executes a cut with the type Remove
    // for efficiency, the selector to be deleted is replaced with the last one and then the last one is popped
    // it reverts if the function doesn't exist or it's immutable
    function _handleRemoveCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];

            LibDiamondStorage.Facet memory oldFacet = ds.facets[selector];

            require(oldFacet.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            require(oldFacet.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");

            // replace selector with last selector
            if (oldFacet.selectorPosition != selectorCount - 1) {
                bytes4 lastSelector = ds.selectors[selectorCount - 1];
                ds.selectors[oldFacet.selectorPosition] = lastSelector;
                ds.facets[lastSelector].selectorPosition = oldFacet.selectorPosition;
            }

            // delete last selector
            ds.selectors.pop();
            delete ds.facets[selector];

            selectorCount--;
        }

        return selectorCount;
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but _calldata is not empty");
            return;
        }

        require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
        if (_init != address(this)) {
            enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        }

        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up the error
                revert(string(error));
            } else {
                revert("LibDiamondCut: _init function reverted");
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./LibDiamondStorage.sol";

library LibOwnership {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        address previousOwner = ds.contractOwner;
        require(previousOwner != _newOwner, "Previous owner and new owner must be different");

        ds.contractOwner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamondStorage.diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() view internal {
        require(msg.sender == LibDiamondStorage.diamondStorage().contractOwner, "Must be contract owner");
    }

    modifier onlyOwner {
        require(msg.sender == LibDiamondStorage.diamondStorage().contractOwner, "Must be contract owner");
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

library LibDiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct Facet {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => Facet) facets;
        bytes4[] selectors;

        // ERC165
        mapping(bytes4 => bool) supportedInterfaces;

        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}