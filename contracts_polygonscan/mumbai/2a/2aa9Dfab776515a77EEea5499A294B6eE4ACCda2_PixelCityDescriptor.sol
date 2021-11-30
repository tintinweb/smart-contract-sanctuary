// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./PixelCityLibrary.sol";
import "./interfaces/IPixelCityDescriptor.sol";

contract PixelCityDescriptor is
	IPixelCityDescriptor,
	Initializable,
	OwnableUpgradeable
{
	using StringsUpgradeable for uint256;

	// Link to the unrevealed image.
	string public unrevealedURI;

	// Simple description.
	string public lore;

	// All traits with names and SVGs.
	PixelCityLibrary.Trait[] public accessories;
	PixelCityLibrary.Trait[] public faces;
	PixelCityLibrary.Trait[] public tees;
	PixelCityLibrary.Trait[] public heads;

	function initialize(string memory _unrevealedURI, string memory _lore)
		public
		initializer
	{
		__Ownable_init();

		unrevealedURI = _unrevealedURI;
		lore = _lore;
	}

	/*	___________                .__   __           	*/
	/*	\__    ___/_______ _____   |__|_/  |_   ______	*/
	/*	  |    |   \_  __ \\__  \  |  |\   __\ /  ___/	*/
	/*	  |    |    |  | \/ / __ \_|  | |  |   \___ \ 	*/
	/*	  |____|    |__|   (____  /|__| |__|  /____  >	*/
	/*	                        \/                 \/ 	*/

	function _addAccesory(PixelCityLibrary.Trait calldata _accessory) internal {
		accessories.push(_accessory);
	}

	function _addFace(PixelCityLibrary.Trait calldata _face) internal {
		faces.push(_face);
	}

	function _addTee(PixelCityLibrary.Trait calldata _tee) internal {
		tees.push(_tee);
	}

	function _addHead(PixelCityLibrary.Trait calldata _head) internal {
		heads.push(_head);
	}

	/**
	 * @dev Add an accessory into the contract.
	 */
	function addAccessory(PixelCityLibrary.Trait calldata _accessory)
		external
		onlyOwner
	{
		_addAccesory(_accessory);
	}

	/**
	 * @dev Add a face into the contract.
	 */
	function addFace(PixelCityLibrary.Trait calldata _face) external onlyOwner {
		_addFace(_face);
	}

	/**
	 * @dev Add a tee into the contract.
	 */
	function addTee(PixelCityLibrary.Trait calldata _tee) external onlyOwner {
		_addTee(_tee);
	}

	/**
	 * @dev Add a head into the contract.
	 */
	function addHead(PixelCityLibrary.Trait calldata _head) external onlyOwner {
		_addHead(_head);
	}

	/**
	 * @dev Add many accessories into the contract.
	 */
	function addManyAccessories(PixelCityLibrary.Trait[] calldata _accessories)
		external
		onlyOwner
	{
		for (uint8 i = 0; i < _accessories.length; i++) {
			_addAccesory(_accessories[i]);
		}
	}

	/**
	 * @dev Add many faces into the contract.
	 */
	function addManyFaces(PixelCityLibrary.Trait[] calldata _faces)
		external
		onlyOwner
	{
		for (uint8 i = 0; i < _faces.length; i++) {
			_addFace(_faces[i]);
		}
	}

	/**
	 * @dev Add many tees into the contract.
	 */
	function addManyTees(PixelCityLibrary.Trait[] calldata _tees)
		external
		onlyOwner
	{
		for (uint8 i = 0; i < _tees.length; i++) {
			_addTee(_tees[i]);
		}
	}

	/**
	 * @dev Add many heads into the contract.
	 */
	function addManyHeads(PixelCityLibrary.Trait[] calldata _heads)
		external
		onlyOwner
	{
		for (uint8 i = 0; i < _heads.length; i++) {
			_addHead(_heads[i]);
		}
	}

	/*		________                                           __                   	*/
	/*	 /  _____/   ____    ____    ____  _______ _____   _/  |_   ____  _______ 	*/
	/*	/   \  ___ _/ __ \  /    \ _/ __ \ \_  __ \\__  \  \   __\ /  _ \ \_  __ \	*/
	/*	\    \_\  \\  ___/ |   |  \\  ___/  |  | \/ / __ \_ |  |  (  <_> ) |  | \/	*/
	/*	 \______  / \___  >|___|  / \___  > |__|   (____  / |__|   \____/  |__|   	*/
	/*	        \/      \/      \/      \/              \/                        	*/

	/**
	 * @dev Return a pseudo-random number.
	 */
	function _rand() internal view returns (uint256) {
		return
			uint256(
				keccak256(
					abi.encodePacked(
						msg.sender,
						block.coinbase,
						block.timestamp,
						block.difficulty
					)
				)
			);
	}

	/**
	 * @dev Mix a random number with a nonce and a salt.
	 * @param _seed The original random number.
	 * @param _nonce A dynamic number.
	 * @param _salt A string description.
	 */
	function _randomize(
		uint256 _seed,
		uint256 _nonce,
		string memory _salt
	) internal pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(_seed, _nonce, _salt)));
	}

	/**
	 * @dev Generate a random number between 0 and the
	 * number of accessories.
	 * @param _tokenId Token id to be used as random nonce.
	 */
	function _genAccessory(uint256 _tokenId) internal view returns (uint8) {
		uint256 seed = _randomize(_rand(), _tokenId, "Accessory") %
			accessories.length;
		return uint8(seed);
	}

	/**
	 * @dev Generate a random number between 0 and the
	 * number of faces.
	 * @param _tokenId Token id to be used as random nonce.
	 */
	function _genFace(uint256 _tokenId) internal view returns (uint8) {
		uint256 seed = _randomize(_rand(), _tokenId, "Face") % faces.length;
		return uint8(seed);
	}

	/**
	 * @dev Generate a random number between 0 and the
	 * number of tees.
	 * @param _tokenId Token id to be used as random nonce.
	 */
	function _genTee(uint256 _tokenId) internal view returns (uint8) {
		uint256 seed = _randomize(_rand(), _tokenId, "Tee") % tees.length;
		return uint8(seed);
	}

	/**
	 * @dev Generate a random number between 0 and the
	 * number of heads.
	 * @param _tokenId Token id to be used as random nonce.
	 */
	function _genHead(uint256 _tokenId) internal view returns (uint8) {
		uint256 seed = _randomize(_rand(), _tokenId, "Head") % heads.length;
		return uint8(seed);
	}

	/**
	 * @dev Generate a complete Pixel defined by token Id.
	 * @param _tokenId Token id to be used as random nonce.
	 */
	function genPixel(uint256 _tokenId)
		external
		view
		returns (PixelCityLibrary.Pixel memory)
	{
		return
			PixelCityLibrary.Pixel(
				_genAccessory(_tokenId),
				_genFace(_tokenId),
				_genTee(_tokenId),
				_genHead(_tokenId)
			);
	}

	/*	 ____ ___ __________ .___ 	*/
	/*	|    |   \\______   \|   |	*/
	/*	|    |   / |       _/|   |	*/
	/*	|    |  /  |    |   \|   |	*/
	/*	|______/   |____|_  /|___|	*/
	/*	                  \/      	*/

	/**
	 * @dev Set contract's lore to be used on URIs.
	 * @param _lore The new lore.
	 */
	function setLore(string memory _lore) external onlyOwner {
		lore = _lore;
	}

	/**
	 * @dev Set contract's unrevealed URI.
	 * @param _unrevealedURI The new URI.
	 */
	function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
		unrevealedURI = _unrevealedURI;
	}

	/**
	 * @dev Generate a JSON attribute for the URI.
	 * @param _type The trait's name.
	 * @param _value The trait' value.
	 */
	function _genAttribute(string memory _type, string memory _value)
		internal
		pure
		returns (string memory)
	{
		/* solhint-disable */
		return
			string(
				abi.encodePacked(
					'{"trait_type": "',
					_type,
					'", "value": "',
					_value,
					'"}'
				)
			);
		/* solhint-disable */
	}

	/**
	 * @dev Generate an image element for the final SVG.
	 * @param _png The PNG to be added to the image.
	 */
	function _genImage(string memory _png) internal pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					'<image x="0" y="0" width="16" height="16" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
					_png,
					'"/>'
				)
			);
	}

	/**
	 * @dev Generate an SVG using Pixel traits.
	 * @param _pixel A full Pixel.
	 */
	function genSVG(PixelCityLibrary.Pixel memory _pixel)
		public
		view
		returns (string memory)
	{
		string memory accessory = accessories[_pixel.accessory].png;
		string memory face = faces[_pixel.face].png;
		string memory tee = tees[_pixel.tee].png;
		string memory head = heads[_pixel.head].png;

		/* solhint-disable */
		string memory output = string(
			abi.encodePacked(
				'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="pixel" width="100%" height="100%" version="1.1" viewBox="0 0 16 16">',
				_genImage(head),
				_genImage(face),
				_genImage(tee),
				_genImage(accessory),
				"<style>#pixel{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
			)
		);
		/* solhint-disable */

		output = string(
			abi.encodePacked(
				"data:image/svg+xml;base64,",
				Base64.encode(bytes(output))
			)
		);

		return output;
	}

	/**
	 * @dev Return the URI for an unrevelead Pixel.
	 * @param _tokenId Token id to be used on the name.
	 */
	function baseTokenURI(uint256 _tokenId)
		external
		view
		returns (string memory)
	{
		string memory head = "data:application/json;base64,";

		// solint-disable
		string memory tail = string(
			abi.encodePacked(
				'{"name": "Pixel City #',
				_tokenId.toString(),
				'", "description": "',
				lore,
				'", "image": "',
				unrevealedURI,
				'"}'
			)
		);
		// solint-disable

		return string(abi.encodePacked(head, Base64.encode(bytes(tail))));
	}

	/**
	 * @dev Generate a full token URI with the id and a full Pixel.
	 * @param _tokenId Token id to be used on the name.
	 * @param _pixel A full pixel to generate attributes.
	 */
	function genTokenURI(uint256 _tokenId, PixelCityLibrary.Pixel memory _pixel)
		external
		view
		returns (string memory)
	{
		string memory accessory = accessories[_pixel.accessory].value;
		string memory face = faces[_pixel.face].value;
		string memory tee = tees[_pixel.tee].value;
		string memory head = heads[_pixel.head].value;

		/* solhint-disable */
		string memory output = string(
			abi.encodePacked(
				'{"name":"Pixel City #',
				_tokenId.toString(),
				'","description":"',
				lore,
				'", "attributes": [',
				_genAttribute("Accessory", accessory),
				",",
				_genAttribute("Face", face),
				",",
				_genAttribute("Tee", tee),
				",",
				_genAttribute("Head", head),
				'], "image": "',
				genSVG(_pixel),
				'"}'
			)
		);
		/* solhint-disable */

		output = string(
			abi.encodePacked(
				"data:application/json;base64,",
				Base64.encode(bytes(output))
			)
		);

		return output;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library PixelCityLibrary {
	struct Trait {
		string value;
		string png;
	}

	struct Pixel {
		uint8 accessory;
		uint8 face;
		uint8 tee;
		uint8 head;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../PixelCityLibrary.sol";

interface IPixelCityDescriptor {
	/*	___________                .__   __           	*/
	/*	\__    ___/_______ _____   |__|_/  |_   ______	*/
	/*	  |    |   \_  __ \\__  \  |  |\   __\ /  ___/	*/
	/*	  |    |    |  | \/ / __ \_|  | |  |   \___ \ 	*/
	/*	  |____|    |__|   (____  /|__| |__|  /____  >	*/
	/*	                        \/                 \/ 	*/

	function addAccessory(PixelCityLibrary.Trait memory _accessory) external;

	function addFace(PixelCityLibrary.Trait memory _face) external;

	function addTee(PixelCityLibrary.Trait memory _tee) external;

	function addHead(PixelCityLibrary.Trait memory _head) external;

	function addManyAccessories(PixelCityLibrary.Trait[] memory _accessories)
		external;

	function addManyFaces(PixelCityLibrary.Trait[] memory _faces) external;

	function addManyTees(PixelCityLibrary.Trait[] memory _tees) external;

	function addManyHeads(PixelCityLibrary.Trait[] memory _heads) external;

	/*		________                                           __                   	*/
	/*	 /  _____/   ____    ____    ____  _______ _____   _/  |_   ____  _______ 	*/
	/*	/   \  ___ _/ __ \  /    \ _/ __ \ \_  __ \\__  \  \   __\ /  _ \ \_  __ \	*/
	/*	\    \_\  \\  ___/ |   |  \\  ___/  |  | \/ / __ \_ |  |  (  <_> ) |  | \/	*/
	/*	 \______  / \___  >|___|  / \___  > |__|   (____  / |__|   \____/  |__|   	*/
	/*	        \/      \/      \/      \/              \/                        	*/

	function genPixel(uint256 _tokenId)
		external
		view
		returns (PixelCityLibrary.Pixel memory);

	/*	 ____ ___ __________ .___ 	*/
	/*	|    |   \\______   \|   |	*/
	/*	|    |   / |       _/|   |	*/
	/*	|    |  /  |    |   \|   |	*/
	/*	|______/   |____|_  /|___|	*/
	/*	                  \/      	*/

	function setLore(string memory _lore) external;

	function setUnrevealedURI(string memory _unrevealedURI) external;

	function genSVG(PixelCityLibrary.Pixel memory _pixel)
		external
		view
		returns (string memory);

	function baseTokenURI(uint256 _tokenId) external view returns (string memory);

	function genTokenURI(uint256 _tokenId, PixelCityLibrary.Pixel memory _pixel)
		external
		view
		returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}