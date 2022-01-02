// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {RideLibUtils} from "./libraries/RideLibUtils.sol";
import {IRideCut} from "./interfaces/IRideCut.sol";

contract RideHub {
    constructor(address _contractOwner, address _rideCutFacet) payable {
        RideLibUtils.setContractOwner(_contractOwner);

        // Add the rideCut external function from the RideCut.sol
        IRideCut.FacetCut[] memory cut = new IRideCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IRideCut.rideCut.selector;
        cut[0] = IRideCut.FacetCut({
            facetAddress: _rideCutFacet,
            action: IRideCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        RideLibUtils.rideCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        RideLibUtils.RideUtilsStorage storage ds;
        bytes32 position = RideLibUtils.RIDE_UTILS_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "RideHub: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {IRideCut} from "../interfaces/IRideCut.sol";

library RideLibUtils {
    bytes32 constant RIDE_UTILS_STORAGE_POSITION =
        keccak256("diamond.standard.ride.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct RideUtilsStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function rideUtilsStorage()
        internal
        pure
        returns (RideUtilsStorage storage rus)
    {
        bytes32 position = RIDE_UTILS_STORAGE_POSITION;
        assembly {
            rus.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        RideUtilsStorage storage rus = rideUtilsStorage();
        address previousOwner = rus.contractOwner;
        rus.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = rideUtilsStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == rideUtilsStorage().contractOwner,
            "RideUtilsStorage: Must be contract owner"
        );
    }

    event RideCut(IRideCut.FacetCut[] _rideCut, address _init, bytes _calldata);

    // Internal function version of rideCut
    function rideCut(
        IRideCut.FacetCut[] memory _rideCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _rideCut.length; facetIndex++) {
            IRideCut.FacetCutAction action = _rideCut[facetIndex].action;
            if (action == IRideCut.FacetCutAction.Add) {
                addFunctions(
                    _rideCut[facetIndex].facetAddress,
                    _rideCut[facetIndex].functionSelectors
                );
            } else if (action == IRideCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _rideCut[facetIndex].facetAddress,
                    _rideCut[facetIndex].functionSelectors
                );
            } else if (action == IRideCut.FacetCutAction.Remove) {
                removeFunctions(
                    _rideCut[facetIndex].facetAddress,
                    _rideCut[facetIndex].functionSelectors
                );
            } else {
                revert("RideLibUtilsCut: Incorrect FacetCutAction");
            }
        }
        emit RideCut(_rideCut, _init, _calldata);
        initializeRideCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "RideLibUtilsCut: No selectors in facet to cut"
        );
        RideUtilsStorage storage rus = rideUtilsStorage();
        require(
            _facetAddress != address(0),
            "RideLibUtilsCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            rus.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(rus, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = rus
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "RideLibUtilsCut: Can't add function that already exists"
            );
            addFunction(rus, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "RideLibUtilsCut: No selectors in facet to cut"
        );
        RideUtilsStorage storage rus = rideUtilsStorage();
        require(
            _facetAddress != address(0),
            "RideLibUtilsCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            rus.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(rus, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = rus
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "RideLibUtilsCut: Can't replace function with same function"
            );
            removeFunction(rus, oldFacetAddress, selector);
            addFunction(rus, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "RideLibUtilsCut: No selectors in facet to cut"
        );
        RideUtilsStorage storage rus = rideUtilsStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "RideLibUtilsCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = rus
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(rus, oldFacetAddress, selector);
        }
    }

    function addFacet(RideUtilsStorage storage rus, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "RideLibUtilsCut: New facet has no code"
        );
        rus.facetFunctionSelectors[_facetAddress].facetAddressPosition = rus
            .facetAddresses
            .length;
        rus.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        RideUtilsStorage storage rus,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        rus
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        rus.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        rus.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        RideUtilsStorage storage rus,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "RideLibUtilsCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "RideLibUtilsCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = rus
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = rus
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = rus
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            rus.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            rus
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        rus.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete rus.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = rus.facetAddresses.length - 1;
            uint256 facetAddressPosition = rus
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = rus.facetAddresses[
                    lastFacetAddressPosition
                ];
                rus.facetAddresses[facetAddressPosition] = lastFacetAddress;
                rus
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            rus.facetAddresses.pop();
            delete rus
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeRideCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "RideLibUtilsCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "RideLibUtilsCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "RideLibUtilsCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("RideLibUtilsCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
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