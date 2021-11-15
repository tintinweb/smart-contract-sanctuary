// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
* Based on: https://github.com/mudgen/diamond-3-hardhat/commit/d5b14d34b8ce2b7870594d0e6e369986dab90ae7
/******************************************************************************/

import {LibOracle} from "./libraries/LibOracle.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

contract Diamond {
    struct DiamondArgs {
        address owner;
        address oracle;
        address diamondCutFacet;
    }

    constructor(DiamondArgs memory args) payable {
        LibDiamond.setContractOwner(args.owner);
        LibOracle.setOracle(args.oracle);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: args.diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
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
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Based on: https://github.com/mudgen/diamond-3-hardhat/commit/d5b14d34b8ce2b7870594d0e6e369986dab90ae7
/******************************************************************************/

interface IDiamondCut {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Errors {
    // LibOracle
    string constant LORC_CALLER_NOT_ORACLE =
        "LibOracle: Caller is not the oracle";
    string constant LORC_UNKNOWN_REQUEST = "LibOracle: Unknown request";

    // Creation Facet
    string constant CREA_INVALID_INSURANCE_PACKAGE_ID =
        "CreationFacet: Invalid Insurance Package ID";
    string constant CREA_INSURANCE_PACKAGE_ALREADY_ADDED =
        "CreationFacet: Insurance package has already been added";
    string constant CREA_INVALID_DELAY_INTERVAL =
        "CreationFacet: Invalid delay interval";
    string constant CREA_INVALID_POLICY_ID = "CreationFacet: Invalid policy ID";
    string constant CREA_INVALID_INSURANCE_PACKAGE =
        "CreationFacet: Invalid insurance package";
    string constant CREA_POLICY_ALREADY_ADDED =
        "CreationFacet: Policy has already been registered";
    string constant CREA_POLICY_EMPTY = "CreationFacet: Policy is empty";
    string constant CREA_POLICY_HAS_FLIGHT =
        "CreationFacet: Policy has flight already";
    string constant CREA_INVALID_FLIGHT_ID = "CreationFacet: Invalid Flight ID";

    // Keeper Facet
    string constant KEEP_INVALID_PERFORM_DATA =
        "KeeperFacet: Invalid perform data";

    // Flight Updater Facet
    string constant FLUP_FLIGHT_ALREADY_DEPARTED =
        "FlightUpdaterFacet: Flight has already departed";
    // .........................................
    // Insurance Package
    string constant INP_INVALID_INTERVAL =
        "Insurance Package: Invalid interval";

    // Flight.sol
    string constant FL_ALREADY_INITIALIZED = "Flight: Already initialized";
    string constant FL_INVALID_FLIGHT_TIME = "Flight: Invalid flight time";
    string constant FL_ALREADY_DEPARTED =
        "Flight: Flight has already been departed";
    string constant FL_ALREADY_CHECKED =
        "Flight: Flight has already been checked";

    // FlightQueue.sol
    string constant FQ_FLIGHT_NOT_INSERTED =
        "FlightQueue: Flight has not been inserted";
    string constant FQ_COUNT_EXCEEDS_TOTAL =
        "FlightQueue: Count exceeds the total data";

    // OmakaseCore.sol
    string constant OC_CALLER_NOT_ORACLE =
        "OmakaseCore: Caller is not the oracle";
    string constant OC_CALLER_NOT_ADMIN =
        "OmakaseCore: Caller is not the admin";
    string constant OC_FLIGHT_ALREADY_DEPARTED =
        "OmakaseCore: Flight has already been departed";
    string constant OC_NEW_ORACLE_ZERO_ADDRESS =
        "OmakaseCore: New oracle is the zero address";
    string constant OC_NEW_ADMIN_ZERO_ADDRESS =
        "OmakaseCore: New admin is the zero address";
    string constant OC_INVALID_PERFORM_DATA =
        "OmakaseCore: Invalid performData";
    string constant OC_INVALID_INSURANCE_POLICY_ID =
        "OmakaseCore: Invalid insPolicyId";
    string constant OC_POLICY_EMPTY = "OmakaseCore: Policy is empty";
    string constant OC_POLICY_HAS_FLIGHT =
        "OmakaseCore: Policy has flight already";
    string constant OC_INSURANCE_PACKAGE_ALREADY_ADDED =
        "OmakaseCore: Insurance Package has already been added";
    string constant OC_INSURANCE_PACKAGE_ID_ZERO =
        "OmakaseCore: Insurance Package ID cannot be zero";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Based on: https://github.com/mudgen/diamond-3-hardhat/commit/d5b14d34b8ce2b7870594d0e6e369986dab90ae7
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
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

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
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
pragma solidity ^0.8.4;

import {Errors} from "./Errors.sol";
import {LibDiamond} from "./LibDiamond.sol";

library LibOracle {
    bytes32 constant ORACLE_STORAGE_POSITION =
        keccak256("omakase.oracle.oracle_storage");

    struct OracleStorage {
        address oracle;
        uint256 requestCount;
        mapping(bytes32 => bool) pendingRequest;
    }

    event OracleChanged(
        address indexed previousOracle,
        address indexed newOracle
    );

    function oracleStorage() internal pure returns (OracleStorage storage ds) {
        bytes32 position = ORACLE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enforeIsOracle() internal view {
        require(
            msg.sender == oracleStorage().oracle,
            Errors.LORC_CALLER_NOT_ORACLE
        );
    }

    function createRequest() internal returns (bytes32 requestId) {
        OracleStorage storage s = oracleStorage();
        s.requestCount += 1;
        requestId = keccak256(abi.encodePacked(this, s.requestCount));
        s.pendingRequest[requestId] = true;
    }

    function handleOracleCallback(bytes32 requestId) internal {
        OracleStorage storage s = oracleStorage();
        require(s.pendingRequest[requestId], Errors.LORC_UNKNOWN_REQUEST);
        delete s.pendingRequest[requestId];
    }

    /**
     * Request
     */

    event RequestStatusUpdate(bytes32 requestId, bytes32 indexed flightId);
    event RequestPayout(
        bytes32 indexed requestId,
        bytes32 indexed flightId,
        uint256 amount
    );

    function requestStatusUpdate(bytes32 flightId) internal {
        bytes32 requestId = createRequest();
        emit RequestStatusUpdate(requestId, flightId);
    }

    function requestPayout(bytes32 flightId, uint256 amount) internal {
        bytes32 requestId = createRequest();
        emit RequestPayout(requestId, flightId, amount);
    }

    /**
     * Setter
     */

    function setOracle(address newOracle) internal {
        LibDiamond.enforceIsContractOwner();

        OracleStorage storage os = oracleStorage();
        address previousOracle = os.oracle;
        os.oracle = newOracle;

        emit OracleChanged(previousOracle, newOracle);
    }
}

