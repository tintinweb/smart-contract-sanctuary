/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

// File: Diamond/LibCallStorage.sol


pragma solidity ^0.7.1;

library LibCallStorage {
  bytes32 constant CALL_STORAGE_POSITION = keccak256(
    "diamond.standard.call.storage"
  );

  struct CallStorage {
    mapping(address => bool) canCall;
    address[] callers;
  }

  function callStorage() internal pure returns (CallStorage storage cs) {
    bytes32 position = CALL_STORAGE_POSITION;
    assembly {
      cs.slot := position
    }
  }
}
// File: Diamond/CallProtection.sol


pragma solidity ^0.7.1;


contract CallProtection {
    modifier protectedCall() {
        require(
            msg.sender == LibDiamond.diamondStorage().contractOwner ||
            msg.sender == address(this), "NOT_ALLOWED"
        );
        _;
    }
}
// File: Diamond/LibReentryProtectionStorage.sol


pragma solidity ^0.7.1;

library LibReentryProtectionStorage {
  bytes32 constant REENTRY_STORAGE_POSITION = keccak256(
    "diamond.standard.reentry.storage"
  );

  struct RPStorage {
    uint256 lockCounter;
  }

  function rpStorage() internal pure returns (RPStorage storage bs) {
    bytes32 position = REENTRY_STORAGE_POSITION;
    assembly {
      bs.slot := position
    }
  }
}
// File: Diamond/ReentryProtection.sol


pragma solidity ^0.7.1;


contract ReentryProtection {
  modifier noReentry {
    // Use counter to only write to storage once
    LibReentryProtectionStorage.RPStorage storage s = LibReentryProtectionStorage.rpStorage();
    s.lockCounter++;
    uint256 lockValue = s.lockCounter;
    _;
    require(
      lockValue == s.lockCounter,
      "ReentryProtectionFacet.noReentry: reentry detected"
    );
  }
}
// File: Interfaces/ICallFacet.sol


pragma solidity ^0.7.1;

interface ICallFacet {

    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    event Call(address indexed caller, address indexed target, bytes data, uint256 value);

    /**
        @notice Lets whitelisted callers execute a batch of arbitrary calls from the pool. Reverts if one of the calls fails
        @param _targets Array of addresses of targets to call
        @param _calldata Array of calldata for each call
        @param _values Array of amounts of ETH to send with the call
    */
    function call(
        address[] memory _targets,
        bytes[] memory _calldata,
        uint256[] memory _values
    ) external;

    /**
        @notice Lets whitelisted callers execute a batch of arbitrary calls from the pool without sending any Ether. Reverts if one of the calls fail
        @param _targets Array of addresses of targets to call
        @param _calldata Array of calldata for each call
    */
    function callNoValue(
        address[] memory _targets,
        bytes[] memory _calldata
    ) external;

    /**
        @notice Lets whitelisted callers execute a single arbitrary call from the pool. Reverts if the call fails
        @param _target Address of the target to call
        @param _calldata Calldata of the call
        @param _value Amount of ETH to send with the call
    */
    function singleCall(
        address _target,
        bytes calldata _calldata,
        uint256 _value
    ) external;

    /**
        @notice Add a whitelisted caller. Can only be called by the contract owner
        @param _caller Caller to add
    */
    function addCaller(address _caller) external;

    /**
        @notice Remove a whitelisted caller. Can only be called by the contract owner
    */
    function removeCaller(address _caller) external;

    /**
        @notice Checks if an address is a whitelisted caller
        @param _caller Address to check
        @return If the address is whitelisted
    */
    function canCall(address _caller) external view returns (bool);

    /**
        @notice Get all whitelisted callers
        @return Array of whitelisted callers
    */
    function getCallers() external view returns (address[] memory);
}
// File: Interfaces/IDiamondCut.sol


pragma solidity ^0.7.1;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

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
// File: Diamond/LibDiamond.sol


pragma solidity ^0.7.1;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
* This is gas optimized by reducing storage reads and storage writes.
* This code is as complex as it is to reduce gas costs.
/******************************************************************************/


library LibDiamond {
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
        // owner of the contract
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
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
   
   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() view internal {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    modifier onlyOwner {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
        _;
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

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
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount % 8 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount / 8];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount % 8 > 0) {
            ds.selectorSlots[selectorCount / 8] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");        
        if (_action == IDiamondCut.FacetCutAction.Add) {
            require(_newFacetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];                
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector                                
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);                
                uint256 selectorInSlotPosition = (_selectorCount % 8) * 32;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount / 8] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if(_action == IDiamondCut.FacetCutAction.Replace) {
            require(_newFacetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
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
        } else if(_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount / 8;
            uint256 selectorInSlotIndex = (_selectorCount % 8) - 1;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex * 32));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount / 8;
                    oldSelectorInSlotPosition = (oldSelectorCount % 8) * 32;
                }
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
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
                selectorInSlotIndex--;
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex + 1;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }       
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
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
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
// File: Diamond/CallFacet.sol



pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;





contract CallFacet is ReentryProtection, ICallFacet {

  uint256 public constant MAX_CALLERS = 50;

  // uses modified call protection modifier to also allow whitelisted addresses to call
  modifier protectedCall() {
    require(
        msg.sender == LibDiamond.diamondStorage().contractOwner ||
        LibCallStorage.callStorage().canCall[msg.sender] ||
        msg.sender == address(this), "NOT_ALLOWED"
    );
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == LibDiamond.diamondStorage().contractOwner, "NOT_ALLOWED");
    _;
  }

  function addCaller(address _caller) external override onlyOwner {
    LibCallStorage.CallStorage storage callStorage = LibCallStorage.callStorage();

    require(callStorage.callers.length < MAX_CALLERS, "TOO_MANY_CALLERS");
    require(!callStorage.canCall[_caller], "IS_ALREADY_CALLER");
    require(_caller != address(0), "INVALID_CALLER");

    callStorage.callers.push(_caller);
    callStorage.canCall[_caller] = true;

    emit CallerAdded(_caller);
  }

  function removeCaller(address _caller) external override onlyOwner {
    LibCallStorage.CallStorage storage callStorage = LibCallStorage.callStorage();

    require(callStorage.canCall[_caller], "IS_NOT_CALLER");

    callStorage.canCall[_caller] = false;

    for(uint256 i = 0; i < callStorage.callers.length; i ++) {
      address currentCaller = callStorage.callers[i];

      // if found remove it
      if(currentCaller == _caller) {
        callStorage.callers[i] = callStorage.callers[callStorage.callers.length - 1];
        callStorage.callers.pop();
        break;
      }
    }

    emit CallerRemoved(_caller);
  }

  function call(address[] memory _targets,bytes[] memory _calldata,uint256[] memory _values) public override noReentry protectedCall {
    require(
      _targets.length == _calldata.length && _values.length == _calldata.length,
      "ARRAY_LENGTH_MISMATCH"
    );

    for (uint256 i = 0; i < _targets.length; i++) {
      _call(_targets[i], _calldata[i], _values[i]);
    }
  }

  function callNoValue(address[] memory _targets,bytes[] memory _calldata) public override noReentry protectedCall {
    require(
      _targets.length == _calldata.length,
      "ARRAY_LENGTH_MISMATCH"
    );

    for (uint256 i = 0; i < _targets.length; i++) {
      _call(_targets[i], _calldata[i], 0);
    }
  }

  function singleCall(address _target,bytes calldata _calldata,uint256 _value) external override noReentry protectedCall {
    _call(_target, _calldata, _value);
  }

  function _call(address _target,bytes memory _calldata,uint256 _value) internal {
    require(address(this).balance >= _value, "ETH_BALANCE_TOO_LOW");
    (bool success, ) = _target.call{ value: _value }(_calldata);
    require(success, "CALL_FAILED");
    emit Call(msg.sender, _target, _calldata, _value);
  }

  function canCall(address _caller) external view override returns (bool) {
    return LibCallStorage.callStorage().canCall[_caller];
  }

  function getCallers() external view override returns (address[] memory) {
    return LibCallStorage.callStorage().callers;
  }
}