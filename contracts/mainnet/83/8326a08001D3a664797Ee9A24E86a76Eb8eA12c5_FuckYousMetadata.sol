// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import { EternalLib } from "../lib/EternalLib.sol";
import { AssembleLib } from "../lib/AssembleLib.sol";
import { GenotypeLib } from "../lib/GenotypeLib.sol";
import { MutationLib } from "../lib/MutationLib.sol";


contract FuckYousMetadata {

	// figure out what season using the tokenId
	function getSeasonal(uint tokenId) public view returns (EternalLib.Seasonal memory) {
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();

		for (uint i = 0; i < s.seasonals.length; i++) {
			if (tokenId < s.seasonals[i].boundary) {
				return s.seasonals[i];
			}
		}
		return s.seasonals[0];
	}

	// this is the external function FuckYous calls
	function getGraphics(uint tokenId)
		public
		view
		returns (string memory)
	{
		EternalLib.enforceTokenExists(tokenId);

		EternalLib.Seasonal memory seasonal = getSeasonal(tokenId);

		return getGraphics(tokenId, seasonal.template);
	}

	function getGraphics(uint tokenId, bytes16 _template)
		public
		view
		returns (string memory)
	{
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		EternalLib.Template storage t = s.templates[_template];
		MutationLib.MutationStorage storage m = MutationLib.mutationStorage();

		// check for template override
		bytes16 _tm = m.mutationTemplate[tokenId];

		if (_tm != '') {
			return AssembleLib.assembleSequence(tokenId, _tm, s.templates[_tm].graphics);
		}

		return AssembleLib.assembleSequence(tokenId, _template, t.graphics);
	}

	// this is the external function FuckYous calls
	function getMetadata(uint tokenId)
		public
		view
		returns (string memory)
	{
		EternalLib.enforceTokenExists(tokenId);

		EternalLib.Seasonal memory seasonal = getSeasonal(tokenId);

		return getMetadata(tokenId, seasonal.template);
	}

	function getMetadata(uint tokenId, bytes16 _template)
		public
		view
		returns (string memory)
	{
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		EternalLib.Template storage t = s.templates[_template];
		MutationLib.MutationStorage storage m = MutationLib.mutationStorage();
		
		bytes16[] memory fenotype = GenotypeLib.deriveFenotype(tokenId, _template);

		// check for template override
		bytes16 _tm = m.mutationTemplate[tokenId];
		if (_tm != '') {
			return AssembleLib.assembleSequence(tokenId, _tm, s.templates[_tm].metadata, fenotype);
		}
		
		return AssembleLib.assembleSequence(tokenId, _template, t.metadata, fenotype);
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

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

import { EternalLib } from "./EternalLib.sol";
import { GenotypeLib } from "./GenotypeLib.sol";
import { MutationLib } from "./MutationLib.sol";



library AssembleLib {
	using Strings for uint256;

	// assembly

	function assembleSequence(
		uint tokenId,
		bytes16 _template,
		bytes16 _sequence
	)
		internal
		view
		returns (string memory)
	{
		bytes16[] memory fenotype = GenotypeLib.deriveFenotype(tokenId, _template);

		return assembleSequence(tokenId, _template, _sequence, fenotype);
	}

	function assembleSequence(
		uint tokenId,
		bytes16 _template,
		bytes16 _sequence,
		bytes16[] memory fenotype
	)
		internal
		view
		returns (string memory)
	{
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		bytes16[] memory sequence = s.sequences[_sequence];
		
		return assembleSequence(tokenId, _template, sequence, fenotype);
	}

	function assembleSequence(
		uint tokenId,
		bytes16 _template,
		bytes16[] memory sequence,
		bytes16[] memory fenotype
	)
		internal
		view
		returns (string memory)
	{
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		EternalLib.Template storage t = s.templates[_template];

		string memory acc;

		// acc = join(acc, 'FENOTYPE_START');
		
		// for (uint i = 0; i < fenotype.length; i++) {
		// 	acc = join(acc, bytes16ToString(fenotype[i]));
		// }

		// acc = join(acc, 'FENOTYPE_END');
		
		uint fi; // fenotype index
		uint fv; // fenotype value index

		/*
		Reference: (tokens starting with)
			[a-z] → just the trait
			_ → build token variable
			# → trait variable
			@ → color variable
			$ → build order
			~ → build master
			^ → get from master
		*/

		/*
		This long & convoluted loop does these things:
			1. replace '_token_id' with the actual token id
			2. format the trait "name" (ex: "sad") for the JSON attributes array
			3. insert the trait "value" (ex: "<g id="mouth-sad" />) for the SVG
			4. check for any overides 
			5. recursively assembles any nested build orders
			6. joins build orders & encodes into base64
			7. accumulates the build tokens values
		*/

		for (uint i; i < sequence.length; i++) {
			if (sequence[i] == bytes16('_token_id')) {
				// 1. replace '_token_id' with the actual token id
				acc = join(acc, tokenId.toString());
			} else if (sequence[i] == bytes16('_trait_val')) {
				// 2. format the trait "name" (ex: "sad") for the JSON attributes array
				bytes16 _fv = replaceFirstByte(fenotype[fv], '%');
				acc = join(acc, s.variables[_fv]);
				fv++;
			} else if (sequence[i][0] == '#') {
				// 3. insert the trait "value" (ex: "<G id="mouth-sad" />") for the SVG
				acc = join(acc, s.variables[fenotype[fi]]);
				fi++;
			} else if (sequence[i][0] == '$') {
				// 4. recursively assemble any nested build sequences
				acc = join(acc, assembleSequence(tokenId, _template, sequence[i], fenotype));
			} else if (sequence[i][0] == '^') {
				// 5. check for any overides
				MutationLib.MutationStorage storage m = MutationLib.mutationStorage();
				
				if (sequence[i] == bytes16('^name')) {
					if (abi.encodePacked(m.mutationName[tokenId]).length > 0) {
						acc = join(acc, m.mutationName[tokenId]);
					} else {
						acc = join(acc, assembleSequence(tokenId, _template, t.name, fenotype));
					}
				} else if (sequence[i] == bytes16('^text')) {
					if (abi.encodePacked(m.mutationText[tokenId]).length > 0) {
						acc = join(acc, m.mutationText[tokenId]);
					} else {
						acc = join(acc, assembleSequence(tokenId, _template, t.text, fenotype));
					}
				} else if (sequence[i] == bytes16('^desc')) {
					if (abi.encodePacked(m.mutationDesc[tokenId]).length > 0) {
						acc = join(acc, m.mutationDesc[tokenId]);
					} else {
						acc = join(acc, assembleSequence(tokenId, _template, t.desc, fenotype));
					}
				} else if (sequence[i] == bytes16('^graphics')) {
					acc = join(acc, assembleSequence(tokenId, _template, t.graphics, fenotype));
				}
			} else if (sequence[i][0] == '{') {
				// 6. joins build sequences & encodes into base64

				string memory ecc;
				uint numEncode;
				// step 1: figure out how many build tokens are to be encoded
				for (uint j = i + 1; j < sequence.length; j++) {
					if (sequence[j][0] == '}' && sequence[j][1] == sequence[i][1]) {
						break;
					} else {
						numEncode++;
					}
				}
				// step 2: create a new build sequence
				bytes16[] memory encodeSequence = new bytes16[](numEncode);
				// step 3: populate the new build sequence
				uint k;
				for (uint j = i + 1; j < sequence.length; j++) {
					if (k < numEncode) {
						encodeSequence[k] = sequence[j];
						k++;
						i++; // CRITICAL: this increments the MAIN loop to prevent dups
					} else {
						break;
					}
				}
				// step 4: encode & assemblbe the new build sequence
				ecc = assembleSequence(tokenId, _template, encodeSequence, fenotype);
				// step 5: join the encoded string to the accumulated string
				acc = join(acc, encodeBase64(ecc));
			} else {
				// 7. accumulates the build tokens values
				acc = join(acc, s.variables[sequence[i]]);
			}
		}
		return acc;
	}

	// util

	function join(string memory _a, string memory _b) internal pure returns (string memory) {
		return string(abi.encodePacked(bytes(_a), bytes(_b)));
	}

	function encodeBase64(string memory _str) internal pure returns (string memory) {
		return string(abi.encodePacked(Base64.encode(bytes(_str))));
	}

	function bytes16ToString(bytes16 _bytes) internal pure returns (string memory) {
		uint j; // length

		// handle colors
		for (uint i; i < _bytes.length; i++) {
			if (_bytes[i] != 0) {
				j++;
			}
		}
		// create new string, because solidity strings are weird
		bytes memory str = new bytes(j);
		for (uint i; i < j; i++) {
			str[i] = _bytes[i];
		}

		return string(str);
	}

	//
	// function replaceBytesAtIndex(
	// 	bytes32 original,
	// 	uint position,
	// 	bytes3 toInsert
	// ) public pure returns (bytes32) {
	// 	bytes3 maskBytes = 0xffffff;
	// 	bytes32 mask = bytes32(maskBytes) >> ((position*3) * 8);         
		
	// 	return (~mask & original) | (bytes32(toInsert) >> ((position*3) * 8));
	// }

	function replaceFirstByte(
		bytes16 original,
		bytes1 toInsert
	) internal pure returns (bytes16) {
		bytes1 maskBytes = 0xff;
		bytes16 mask = bytes16(maskBytes) >> 0;         
		
		return (~mask & original) | (bytes16(toInsert) >> 0);
	}
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import { EternalLib } from "./EternalLib.sol";
import { AssembleLib } from "./AssembleLib.sol";
import { MutationLib } from "./MutationLib.sol";

// import "hardhat/console.sol";

library GenotypeLib {

	// takes tokenId, return a list of layer names
	function deriveFenotype(uint tokenId, bytes16 _template) internal view returns (bytes16[] memory) {
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		bytes16 _genotype = s.templates[_template].genotype;
		bytes16 seedhash = s.templates[_template].seedhash;
		
		//
		bytes16[] memory genotypeKeys = s.genotypes[_genotype];

		// string memory acc;
		// acc = AssembleLib.join(acc, '_template');
		// acc = AssembleLib.join(acc, AssembleLib.bytes16ToString(_template));
		// acc = AssembleLib.join(acc, '_genotype');
		// acc = AssembleLib.join(acc, AssembleLib.bytes16ToString(_genotype));
		// acc = AssembleLib.join(acc, 'GENOTYPE_START');
		
		// for (uint i = 0; i < genotype.length; i++) {
		// 	acc = AssembleLib.join(acc, AssembleLib.bytes16ToString(genotype[i]));
		// }

		// acc = AssembleLib.join(acc, 'GENOTYPE_END');
		// console.log('genotype: ', acc);

		//
		return deriveFenotype(tokenId, seedhash, genotypeKeys);
	}

	// pass in seed
	function deriveFenotype(uint tokenId, bytes16 seedhash, bytes16[] memory genotypeKeys) internal view returns (bytes16[] memory) {		
		//
		EternalLib.EternalStorage storage s = EternalLib.eternalStorage();
		MutationLib.MutationStorage storage m = MutationLib.mutationStorage();

		// step 1: check to see if we have a hash override
		uint hashy;
		if (m.mutationFenotype[tokenId] != 0) {
			hashy = m.mutationFenotype[tokenId];
		} else {
			// step 2: generate a super simple hash
			// (yes, I know this isn't hiding future metadata traits, don't care)
			hashy = uint(keccak256(abi.encodePacked(tokenId, seedhash)));
		}

		// step 3: split this hash into 32 arrays to seed the attributes
		uint8[32] memory seeds = splitHashIntoFenotype(hashy);
		bytes16[] memory fenotype = new bytes16[](genotypeKeys.length);

		// step 4: loop through the traits
		for (uint i; i < genotypeKeys.length; i++) {
			// step 4.a: get the pool of traits
			bytes16 _genotype = genotypeKeys[i];
			bytes16[] storage genotype = s.genotypes[_genotype];
			if (genotype.length != 0) {
				// step 4.b: if it exists, select a trait from the pool, using the seed
				uint genotypeIndex;
				// CHECK FOR PATTERN!
				if (_genotype == bytes16('#s00-pattern')) {
					uint maybeIndex = seeds[i] % 32;
					if (maybeIndex < genotype.length) {
						genotypeIndex = maybeIndex;
					} else {
						genotypeIndex = 0;
					}
				} else {
					genotypeIndex = seeds[i] % genotype.length;
				}
				// step 4.c: add the selected trait to the accumulated layers
				fenotype[i] = genotype[genotypeIndex];
			} else {
				fenotype[i] = '_err';
			}
		}

		// step 5: return the fenotype
		return fenotype;
	}

	function splitHashIntoFenotype(uint _hash) internal pure returns (uint8[32] memory numbers) {
		for (uint i; i < numbers.length; i++) {
			numbers[i] = uint8(_hash >> (i * 8));
		}

		return numbers;
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

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

interface IFuckYous {
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

