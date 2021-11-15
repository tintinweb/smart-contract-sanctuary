// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import { EternalLib } from "../lib/EternalLib.sol";
import { Modifier } from "../lib/Modifier.sol";


contract FuckYousPopulate is Modifier {

  function addVariable(bytes16 key, string memory val) external onlyOwner {
		EternalLib.addVariable(key, val);
	}

	function addVariables(bytes16[] memory keys, string[] memory vals) external onlyOwner {
		EternalLib.addVariables(keys, vals);
	}

	function addSequence(bytes16 key, bytes16[] memory vals) external onlyOwner {
		EternalLib.addSequence(key, vals);
	}

	function addGenotype(bytes16 key, bytes16[] memory vals) external onlyOwner {
		EternalLib.addGenotype(key, vals);
	}

	function addTemplate(
		bytes16 _key,
		bytes16 _name,
		bytes16 _text,
		bytes16 _desc,
		bytes16 _seedhash,
		bytes16 _genotype,
		bytes16 _graphics,
		bytes16 _metadata
	) external onlyOwner {
		EternalLib.addTemplate(_key, _name, _text, _desc, _seedhash, _genotype, _graphics, _metadata);
	}

	function addSeasonal(bytes16 _template, uint _boundary) external onlyOwner {
		EternalLib.addSeasonal(_template, _boundary);
	}

}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import { IFuckYous } from "./interfaces/IFuckYous.sol";

library EternalLib {

	bytes32 constant ETERNAL_STORAGE_POSITION = keccak256('wtf.fuckyous.eternal.storage');

	struct EternalStorage {
		mapping(bytes16 => string) variables;
		mapping(bytes16 => bytes16[]) sequences;
		mapping(bytes16 => bytes16[]) genotypes;
		mapping(bytes16 => Template) templates;
		Seasonal[] seasonals;
		address fuckyous;
	}

	struct Template {
		bytes16 key;
		bytes16 name; // title of the NFT
		bytes16 text; // text around the circle
		bytes16 desc; // description of the NFT (text under image)

		bytes16 seedhash; // seed the randomness
		bytes16 genotype; // which attributes are selected
		bytes16 graphics; // how to assemble the SVG
		bytes16 metadata; // how to assemble the JSON
	}

	struct Seasonal {
		bytes16 template;
		uint boundary;
	}

	function eternalStorage() internal pure returns (EternalStorage storage es) {
		bytes32 position = ETERNAL_STORAGE_POSITION;
		assembly {
			es.slot := position
		}
	}

	function addVariable(bytes16 key, string memory val) internal {
		EternalStorage storage s = eternalStorage();
		s.variables[key] = val;
	}

	function addVariables(bytes16[] memory keys, string[] memory vals) internal {
		EternalStorage storage s = eternalStorage();
		for (uint i; i < keys.length; i++) {
			s.variables[keys[i]] = vals[i];
		}
	}

	function addSequence(bytes16 key, bytes16[] memory vals) internal {
		EternalStorage storage s = eternalStorage();
		s.sequences[key] = vals;
	}

	// TODO: plural version?

	function addGenotype(bytes16 key, bytes16[] memory vals) internal {
		EternalStorage storage s = eternalStorage();
		s.genotypes[key] = vals;
	}

	function addTemplate(
		bytes16 _key,
		bytes16 _name,
		bytes16 _text,
		bytes16 _desc,
		bytes16 _seedhash,
		bytes16 _genotype,
		bytes16 _graphics,
		bytes16 _metadata
	) internal {
		EternalStorage storage s = eternalStorage();
		Template memory template = Template({
			key: _key,
			name: _name,
			text: _text,
			desc: _desc,
			seedhash: _seedhash,
			genotype: _genotype,
			graphics: _graphics,
			metadata: _metadata
		});

		s.templates[_key] = template;
	}

	function addSeasonal(bytes16 _template, uint _boundary) internal {
		EternalStorage storage s = eternalStorage();
		Seasonal memory seasonal = Seasonal({
			template: _template,
			boundary: _boundary
		});

		s.seasonals.push(seasonal);
	}

	function setFuckYousAddress(address _address) internal {
		EternalStorage storage s = eternalStorage();
		s.fuckyous = _address;
	}

	function enforceTokenExists(uint tokenId) internal view {
		require(
			IFuckYous(eternalStorage().fuckyous).ownerOf(tokenId) != address(0),
			'OOPS: non-existent token'
		);
	}

	function enforceIsTokenOwner(uint tokenId) internal view {
		require(
			msg.sender == IFuckYous(eternalStorage().fuckyous).ownerOf(tokenId),
			'OOPS: you are not the owner of this token.'
		);
	}
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import { DiamondLib } from "./DiamondLib.sol";
import { EternalLib } from "./EternalLib.sol";
import { MutationLib } from "./MutationLib.sol";
import { IFuckYous } from "./interfaces/IFuckYous.sol";

contract Modifier {
	
	modifier onlyOwner {
		DiamondLib.enforceIsContractOwner();
		_;
	}

	modifier onlyFucker(uint tokenId) {
		EternalLib.enforceIsTokenOwner(tokenId);
		_;
	}

	modifier canMutate(uint tokenId) {
    MutationLib.MutationStorage storage s = MutationLib.mutationStorage();
		EternalLib.enforceIsTokenOwner(tokenId);
		require(
			s.mutationStart,
			'OOPS: mutation has not started.'
		);
		require(
			msg.value >= s.mutationPrice,
			'OOPS: send moar ether.'
		);
		_;
	}
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

interface IFuckYous {
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from './interfaces/IDiamondCut.sol';


library DiamondLib {
	bytes32 constant DIAMOND_STORAGE_POSITION = keccak256('diamond.standard.diamond.storage');

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

	function enforceIsContractOwner() internal view {
		require(msg.sender == diamondStorage().contractOwner, 'DiamondLib: Must be contract owner');
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
		// 'selectorCount & 7' is a gas efficient modulo by eight 'selectorCount % 8' 
		if (selectorCount & 7 > 0) {
			// get last selectorSlot
			// 'selectorSlot >> 3' is a gas efficient division by 8 'selectorSlot / 8'
			selectorSlot = ds.selectorSlots[selectorCount >> 3];
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
		// 'selectorCount & 7' is a gas efficient modulo by eight 'selectorCount % 8' 
		if (selectorCount & 7 > 0) {
			// 'selectorSlot >> 3' is a gas efficient division by 8 'selectorSlot / 8'
			ds.selectorSlots[selectorCount >> 3] = selectorSlot;
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
		require(_selectors.length > 0, 'DiamondLib.cut: No selectors in facet to cut');
		if (_action == IDiamondCut.FacetCutAction.Add) {
			enforceHasContractCode(_newFacetAddress, 'DiamondLib.cut: Add facet has no code');
			for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
				bytes4 selector = _selectors[selectorIndex];
				bytes32 oldFacet = ds.facets[selector];
				require(address(bytes20(oldFacet)) == address(0), "DiamondLib.cut: Can't add function that already exists");
				// add facet for selector
				ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
				// '_selectorCount & 7' is a gas efficient modulo by eight '_selectorCount % 8' 
				uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
				// clear selector position in slot and add selector
				_selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
				// if slot is full then write it to storage
				if (selectorInSlotPosition == 224) {
					// '_selectorSlot >> 3' is a gas efficient division by 8 '_selectorSlot / 8'
					ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
					_selectorSlot = 0;
				}
				_selectorCount++;
			}
		} else if (_action == IDiamondCut.FacetCutAction.Replace) {
			enforceHasContractCode(_newFacetAddress, 'DiamondLib.cut: Replace facet has no code');
			for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
				bytes4 selector = _selectors[selectorIndex];
				bytes32 oldFacet = ds.facets[selector];
				address oldFacetAddress = address(bytes20(oldFacet));
				// only useful if immutable functions exist
				require(oldFacetAddress != address(this), "DiamondLib.cut: Can't replace immutable function");
				require(oldFacetAddress != _newFacetAddress, "DiamondLib.cut: Can't replace function with same function");
				require(oldFacetAddress != address(0), "DiamondLib.cut: Can't replace function that doesn't exist");
				// replace old facet address
				ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
			}
		} else if (_action == IDiamondCut.FacetCutAction.Remove) {
			require(_newFacetAddress == address(0), 'DiamondLib.cut: Remove facet address must be address(0)');
			// '_selectorCount >> 3' is a gas efficient division by 8 '_selectorCount / 8'
			uint256 selectorSlotCount = _selectorCount >> 3;
			// '_selectorCount & 7' is a gas efficient modulo by eight '_selectorCount % 8' 
			uint256 selectorInSlotIndex = _selectorCount & 7;
			for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
				if (_selectorSlot == 0) {
					// get last selectorSlot
					selectorSlotCount--;
					_selectorSlot = ds.selectorSlots[selectorSlotCount];
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
					bytes32 oldFacet = ds.facets[selector];
					require(address(bytes20(oldFacet)) != address(0), "DiamondLib.cut: Can't remove function that doesn't exist");
					// only useful if immutable functions exist
					require(address(bytes20(oldFacet)) != address(this), "DiamondLib.cut: Can't remove immutable function");
					// replace selector with last selector in ds.facets
					// gets the last selector
					lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
					if (lastSelector != selector) {
						// update last selector slot position info
						ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
					}
					delete ds.facets[selector];
					uint256 oldSelectorCount = uint16(uint256(oldFacet));
					// 'oldSelectorCount >> 3' is a gas efficient division by 8 'oldSelectorCount / 8'
					oldSelectorsSlotCount = oldSelectorCount >> 3;
					// 'oldSelectorCount & 7' is a gas efficient modulo by eight 'oldSelectorCount % 8' 
					oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
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
			}
			_selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
		} else {
			revert('DiamondLib.cut: Incorrect FacetCutAction');
		}
		return (_selectorCount, _selectorSlot);
	}

	function initializeDiamondCut(address _init, bytes memory _calldata) internal {
		if (_init == address(0)) {
			require(_calldata.length == 0, 'DiamondLib.cut: _init is address(0) but_calldata is not empty');
		} else {
			require(_calldata.length > 0, 'DiamondLib.cut: _calldata is empty but _init is not address(0)');
			if (_init != address(this)) {
				enforceHasContractCode(_init, 'DiamondLib.cut: _init address has no code');
			}
			(bool success, bytes memory error) = _init.delegatecall(_calldata);
			if (!success) {
				if (error.length > 0) {
					// bubble up the error
					revert(string(error));
				} else {
					revert('DiamondLib.cut: _init function reverted');
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

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;


library MutationLib {

	bytes32 constant MUTATION_STORAGE_POSITION = keccak256('wtf.fuckyous.mutation0.storage');

	struct MutationStorage {
		bool mutationStart;
		uint mutationPrice;
		mapping(uint => string) mutationName;
		mapping(uint => string) mutationText;
		mapping(uint => string) mutationDesc;
		mapping(uint => uint) mutationFenotype;
		mapping(uint => bytes16) mutationTemplate;
	}

	function mutationStorage() internal pure returns (MutationStorage storage ms) {
		bytes32 position = MUTATION_STORAGE_POSITION;
		assembly {
			ms.slot := position
		}
	}

  function mutateName(uint tokenId, string memory name) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationName[tokenId] = name;
  }
  function mutateText(uint tokenId, string memory text) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationText[tokenId] = text;
  }
  function mutateDesc(uint tokenId, string memory desc) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationDesc[tokenId] = desc;
  }
  function mutateFenotype(uint tokenId, uint fenotype) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationFenotype[tokenId] = fenotype;
  }
  function mutateTemplate(uint tokenId, bytes16 template) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationTemplate[tokenId] = template;
  }

	function setMutationStart(bool start) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationStart = start;
  }
	function setMutationPrice(uint price) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationPrice = price;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

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

