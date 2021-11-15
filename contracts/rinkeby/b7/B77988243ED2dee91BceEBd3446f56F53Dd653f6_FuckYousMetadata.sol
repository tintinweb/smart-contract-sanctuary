// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import 'base64-sol/base64.sol';


contract FuckYousMetadata is Ownable {
	using Strings for uint256;

	mapping(bytes16 => string) buildTokens;
	mapping(bytes16 => string) traitTokens;

	mapping(bytes16 => bytes16[]) buildOrders;
	mapping(bytes16 => bytes16[]) traitPools;

	// seasons

	struct Season {
		uint bounds;
		bytes16 text; // text around the circle
		bytes16 graphics; // how to assemble the SVG
		bytes16 metadata; // how to assemble the JSON
	}

	Season[] allSeasons;

	mapping(uint => string) overrideText;
  mapping(uint => uint) overrideHash;

	constructor () {}

	// mgmt

	// withdraw balance
	function getPaid() public payable onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}

	function addTokens(
		bytes16[] memory _keys,
		string[] memory _vals,
		bool _isBuild
	) external onlyOwner {
		if (_isBuild) {
			for (uint i; i < _keys.length; i++) {
				buildTokens[_keys[i]] = _vals[i];
			}
		} else {
			for (uint i; i < _keys.length; i++) {
				traitTokens[_keys[i]] = _vals[i];
			}
		}
	}

	function addOrders(
		bytes16 _key,
		bytes16[] memory _vals,
		bool _isBuild
	) external onlyOwner {
		if (_isBuild) {
			buildOrders[_key] = _vals;
		} else {
			traitPools[_key] = _vals;
		}
	}

	function addSeason(
		uint _bounds,
		bytes16 _text,
		bytes16 _graphics,
		bytes16 _metadata
	) external onlyOwner {
		allSeasons.push(Season({
			bounds: _bounds,
			text: _text,
			graphics: _graphics,
			metadata: _metadata
		}));
	}

	// figure out what season using the tokenId
	function getSeason(uint _tokenId) internal view returns (Season memory) {
		for (uint i = 0; i < allSeasons.length; i++) {
			if (_tokenId < allSeasons[i].bounds) {
				return allSeasons[i];
			}
		}
		return allSeasons[0];
	}

	// assembly

	function assembleBuildOrder(
		uint _tokenId,
		bytes16 _orderKey,
		bytes16[] memory _traits
	)
		public
		view
		returns (string memory)
	{
		return assembleBuildOrder(
			_tokenId,
			buildOrders[_orderKey],
			_traits
		);
	}

	function assembleBuildOrder(
		uint _tokenId,
		bytes16[] memory order,
		bytes16[] memory _traits
	)
		public
		view
		returns (string memory)
	{
		string memory acc;
		
		uint t; // trait index
		uint tv; // trait value index

		/*
		Reference: (tokens starting with)
			[a-z] → just the trait
			_ → build token variable
			# → trait variable
			@ → color variable
			$ → build order
			~ → build master
		*/

		/*
		This long & convoluted loop does these things:
			1. replace '_token_id' with the actual token id
			2. format the trait "name" (ex: "sad") for the JSON attributes array
			3. insert the trait "value" (ex: "<g id="mouth-sad" />) for the SVG
			4. recursively assembles any nested build orders
			5. check for any overrides
			6. joins build orders & encodes into base64
			7. accumulates the build tokens values
		*/

		for (uint i; i < order.length; i++) {
			if (order[i] == bytes16('_token_id')) {
				// 1. replace '_token_id' with the actual token id
				acc = join(acc, _tokenId.toString());
			} else if (order[i] == bytes16('_trait_val')) {
				// 2. format the trait "name" (ex: "sad") for the JSON attributes array
				acc = join(acc, traitTokens[_traits[tv]]);
				tv++;
			} else if (order[i][0] == '#') {
				// 3. insert the trait "value" (ex: "<G id="mouth-sad" />") for the SVG
				acc = join(acc, buildTokens[_traits[t]]);
				t++;
			} else if (order[i][0] == '$') {
				// 4. recursively assemble any nested build orders
				acc = join(acc, assembleBuildOrder(_tokenId, order[i],  _traits));
			} else if (order[i] == bytes16('_override')) {
				// 5. check for any overrides
				if (abi.encodePacked(overrideText[_tokenId]).length > 0) {
					acc = join(acc, overrideText[_tokenId]);
				} else {
					acc = join(acc, assembleBuildOrder(
						_tokenId,
						getSeason(_tokenId).text,
						_traits
					));
				}
			} else if (order[i][0] == '{') {
				// 6. joins build orders & encodes into base64
				uint numEncode;
				// step 1: figure out how many build tokens are to be encoded
				for (uint j = i + 1; j < order.length; j++) {
					if (order[j][0] == '}' && order[j][1] == order[i][1]) {
						break;
					} else {
						numEncode++;
					}
				}
				// step 2: create a new build order
				bytes16[] memory encodeOrder = new bytes16[](numEncode);
				// step 3: populate the new build order
				uint k;
				for (uint j = i + 1; j < order.length; j++) {
					if (k < numEncode) {
						encodeOrder[k] = order[j];
						k++;
						i++; // CRITICAL: this increments the MAIN loop to prevent dups
					} else {
						break;
					}
				}
				// step 4: join the encoded string to the accumulated string
				acc = join(acc, string(
					abi.encodePacked(
						Base64.encode(
							bytes(
								assembleBuildOrder(_tokenId, encodeOrder, _traits)
							)
						)
					)
				));
			} else {
				// 7. accumulates the build tokens values
				acc = join(acc, buildTokens[order[i]]);
			}
		}
		return acc;
	}

	function deriveRandomTraits(uint _tokenId, bytes16[] memory traits) internal view returns (bytes16[] memory) {		
		// step 1: check to see if we have a hash override
		uint hashy;

		if (overrideHash[_tokenId] != 0) {
			hashy = overrideHash[_tokenId];
		} else {
			// step 2: generate a super simple hash
			// (yes, I know this isn't hiding future metadata traits, don't care)
			hashy = uint(keccak256(abi.encodePacked(_tokenId)));
		}
		
		// step 3: split this hash into 32 arrays to seed the attributes
		uint8[32] memory seeds = splitHashIntoTraits(hashy);
		bytes16[] memory layers = new bytes16[](traits.length);

		// step 4: loop through the traits
		for (uint i; i < traits.length; i++) {
			// step 4.a: get the pool of traits
			bytes16[] storage pools = traitPools[traits[i]];
			if (pools.length != 0) {
				// step 4.b: if it exists, select a trait from the pool, using the seed
				uint traitIndex = seeds[i] % pools.length;
				// step 4.c: add the selected trait to the accumulated layers
				layers[i] = pools[traitIndex];
			}
		}
		// step 5: return the layers
		return layers;
	}

	// figures out what traits need to be randomized
	function getTraits(bytes16 _order) internal view returns (bytes16[] memory) {
		bytes16[] storage layers = buildOrders[_order];

		// step 1: determine number of results (how many traits there are)
		uint numTraits;
		for (uint i; i < layers.length; i++) {
			// traits are prefixed with '#'
			if (layers[i][0] == '#') {
				numTraits++;
			}
		}

		// step 2: create the fixed-length array
		bytes16[] memory traits = new bytes16[](numTraits);
		uint j; // traitIndex

		// step 3: fill the array, storing the trait index separately
		for (uint i; i < layers.length; i++) {
			if (layers[i][0] == '#') {
				traits[j] = layers[i];
				j++;
			}
		}

		// step 4: return the array (filtered list of traits)
		return traits;
	}

	// public

	function getMetadata(uint _tokenId)
		public
		view
		returns (string memory)
	{
		Season memory s = getSeason(_tokenId);

		return assembleBuildOrder(
			_tokenId,
			s.metadata,
			deriveRandomTraits(_tokenId, getTraits(s.graphics))
		);
	}

	address internal fuckyous;

	uint public overridePrice = 0.1 ether;

	function setAddress(address _address) external onlyOwner {
		fuckyous = _address;
	}
	function setPrice(uint price) external onlyOwner { overridePrice = price; }
	function setText(uint _tokenId, string memory _text) external onlyOwner {
    overrideText[_tokenId] = _text;
  }
  function setHash(uint _tokenId, uint _traitHash) external onlyOwner {
    overrideHash[_tokenId] = _traitHash;
  }

	modifier canOverride(uint _tokenId) {
		require(
			msg.value >= overridePrice,
			'NOT enough'
		);
		require(
			IFuckYous(fuckyous).ownerOf(_tokenId) == msg.sender,
			'NOT yours'
		);
		_;
	}

	function plsOverrideText(uint _tokenId, string memory _text)
		external payable canOverride(_tokenId)
	{
    overrideText[_tokenId] = _text;
  }
  function plsOverrideHash(uint _tokenId, uint _traitHash)
		external payable canOverride(_tokenId)
	{
    overrideHash[_tokenId] = _traitHash;
  }

	// util

	function join(string memory _a, string memory _b) internal pure returns (string memory) {
		return string(abi.encodePacked(bytes(_a), bytes(_b)));
	}

	function splitHashIntoTraits(uint _hash) internal pure returns (uint8[32] memory numbers) {
		for (uint i; i < numbers.length; i++) {
			numbers[i] = uint8(_hash >> (i * 8));
		}

		return numbers;
	}

	// accept ether sent
	receive() external payable {}
}

interface IFuckYous {
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

