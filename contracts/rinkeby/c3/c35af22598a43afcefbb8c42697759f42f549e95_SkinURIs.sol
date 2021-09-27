/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

// credits to Luchadores NFTs for most of the code https://etherscan.io/address/0x8b4616926705Fb61E9C4eeAc07cd946a5D4b0760#code
// svg logic had to be put in a separate contract to fit in contract size limit.
// This has no impact on gas because the only exposed function is only meant for call
contract SkinURIs {
    using Strings for uint256;
    
    struct Item {
		bytes12 name;
		string svg;
	}
	
	struct Art {
		string[] baseColor;
		string[] altColor;
		string[] eyeColor;
		string[] skinColor;
		mapping(uint256 => Item) spirit;
		mapping(uint256 => Item) cape;
		mapping(uint256 => Item) torso;
		mapping(uint256 => Item) arms;
		mapping(uint256 => Item) mask;
		mapping(uint256 => Item) mouth;
		mapping(uint256 => Item) bottoms;
		mapping(uint256 => Item) boots;
	}
	
	Art art;
	uint256 immutable maxSupply;
    
    constructor(uint256 _maxSupply) {
        art.baseColor = ["ebebf7", "1c1d2f", "cc0d3d", "d22f94", "890ec1", "1c49d8", "19b554", "13cac6", "f7c23c", "f18e2f"];
		art.altColor = ["dadae6", "13141f", "ea184d", "e0369f", "9511d2", "2854e6", "1da951", "11b9b5", "e8b63a", "e28327"];
		art.eyeColor = ["3b6ba5", "3b8fa5", "3ba599", "3ba577", "339842", "7fa53b", "a5823b", "a5693b", "844f1d", "4e2906"];
		art.skinColor = ["f9d1b7", "f7b897", "f39c77", "ffcb84", "bd7e47", "b97e4b", "b97a50", "5a3214", "50270e", "3a1b09"];
		art.spirit[0] = Item("Bull", "<path fill='#A9A18A' d='M21 2V1h-1V0h-1v2h1v1h-3v2h2v1h2V5h1V2zM5 3H4V2h1V0H4v1H3v1H2v3h1v1h2V5h2V3H6z'/><g fill='#000' opacity='.15'><path d='M21 4h1v1h-1zM19 5h-1v1h3V5h-1z'/><path d='M2 4h1v1H2zM4 5H3v1h3V5H5z'/></g>");
		art.spirit[1] = Item("Jaguar", "<path class='lucha-base' d='M6 2V1H5v5h1V5h1V3h1V2H7zM18 1v1h-2v1h1v2h1v1h1V1z'/><g fill='#000'><path d='M5 1h1v1H5zM6 2v1h2V2H7zM18 1h1v1h-1zM16 2v1h2V2h-1z' opacity='.3'/><path d='M6 3V2H5v4h1V5h1V3zM18 2v1h-1v2h1v1h1V2z' opacity='.2'/></g>");
		art.cape[0] = Item("Classic", "<path class='lucha-alt' d='M20 11H3v12h1v-1h2v-1h12v1h2v1h1V11z'/><g fill='#000'><path opacity='.2' d='M20 11v12h1V11zM3 12v11h1V11H3z'/><path opacity='.5' d='M19 11H4v11h2v-1h12v1h2V11z'/></g>");
		art.cape[1] = Item("Hooded", "<path class='lucha-alt' d='M20 11H3v12h1v-1h2v-1h12v1h2v1h1V11z'/><g fill='#000'><path opacity='.2' d='M20 11v12h1V11zM3 12v11h1V11H3z'/><path opacity='.5' d='M19 11H4v11h2v-1h12v1h2V11z'/></g>");
		art.torso[0] = Item("Shirt", "<path class='lucha-base' d='M22 12v-1h-1v-1h-1V9H4v1H3v1H2v1H1v5h4v-3h1v1h1v1h1v2h8v-2h1v-1h1v-1h1v3h4v-5z'/><path d='M22 12v-1h-1v-1h-1V9H4v1H3v1H2v1H1v5h4v-3h1v1h1v1h1v2h8v-2h1v-1h1v-1h1v3h4v-5z' fill='#000' opacity='.15'/>");
		art.torso[1] = Item("Open Shirt", "<path class='lucha-base' d='M10 9H4v1H3v1H2v1H1v3h4v-1h1v1h1v1h1v2h3V9zM22 12v-1h-1v-1h-1V9h-7v9h3v-2h1v-1h1v-1h1v1h4v-3z'/><path d='M10 9H4v1H3v1H2v1H1v3h4v-1h1v1h1v1h1v2h3V9zM22 12v-1h-1v-1h-1V9h-7v9h3v-2h1v-1h1v-1h1v1h4v-3z' fill='#000' opacity='.15'/>");
		art.torso[2] = Item("Singlet", "<path class='lucha-base' d='M16 9H7v3h1-1v4h1v1h8v-1h1v-4h-1 1V9z'/><path fill='#000' opacity='.15' d='M16 9H7v7h1v1h8v-1h1V9z'/>");
		art.torso[3] = Item("Suspenders", "<path class='lucha-base' d='M15 9v9h1V9zM8 10v8h1V9H8z'/><path d='M8 10v8h1V9H8zM15 9v9h1V9z' fill='#000' opacity='.15'/>");
		art.arms[0] = Item("Gloves", "<path class='lucha-base' d='M5 16H1v3h4v-1h1v-1H5zM22 16h-3v1h-1v1h1v1h4v-3z'/><path class='lucha-alt' d='M3 16H1v1h4v-1H4zM22 16h-3v1h4v-1z'/>");
		art.arms[1] = Item("Wrist Bands", "<path class='lucha-base' d='M3 15H1v2h4v-2H4zM22 15h-3v2h4v-2z'/>");
		art.arms[2] = Item("Right Band", "<path class='lucha-alt' d='M4 14H1v1h4v-1z'/>");
		art.arms[3] = Item("Left Band", "<path class='lucha-base' d='M22 14h-3v1h4v-1z'/>");
		art.arms[4] = Item("Arm Bands", "<path class='lucha-base' d='M4 14H1v1h4v-1zM22 14h-3v1h4v-1z'/>");
		art.arms[5] = Item("Sleeves", "<path class='lucha-base' d='M22 14h-3v3h4v-3zM3 14H1v3h4v-3H4z'/><path class='lucha-alt' d='M22 14h-3v1h4v-1zM3 14H1v1h4v-1H4z'/>");
		art.mask[0] = Item("Split", "<path d='M11 0H9v1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h3V0z'/>");
		art.mask[1] = Item("Cross", "<path d='M14 2h-1V0h-2v2H9v2h2v4h2V4h2V2zM12 13h-1v2h2v-2z'/>");
		art.mask[2] = Item("Fierce", "<path d='M17 3v1h-2v1h-1v1h-1v3h5V3zM11 8V6h-1V5H9V4H7V3H6v6h5zM11 13v2h2v-2h-1z'/>");
		art.mask[3] = Item("Striped", "<path d='M11 2h2V1h1V0h-4v1h1zM6 10v2h1v-1h1v-1H7zM17 10h-1v1h1v1h1v-2z'/><path d='M16 3h1V2h-1V1h-1v1h-1v1h-1v1h-2V3h-1V2H9V1H8v1H7v1h1v1h1v1h1v1h1v9h2V6h1V5h1V4h1z'/>");
		art.mask[4] = Item("Bolt", "<path d='M13 3h-3V2h1V1h1V0H9v1H8v1H7v1H6v2h3v1H8v2H7v2h1V9h1V8h1V7h1V6h1V5h1V4h1V3z'/>");
		art.mask[5] = Item("Winged", "<path d='M18 5V3h-1V2h-1v1h-1v1h-1v1h-1v1h-2V5h-1V4H9V3H8V2H7v1H6v2H5v5h1v2h1v-1h1v-1h3V9h2v1h3v1h1v1h1v-2h1V5z'/>");
		art.mask[6] = Item("Classic", "<path d='M18 5V3h-1V2h-1v2h-1v1h-1v1h-1v3h-2V6h-1V5H9V4H8V2H7v1H6v2H5v4h1v1h2v3h1v1h6v-1h1v-3h2V9h1V5z'/>");
		art.mask[7] = Item("Arrow", "<path d='M18 5V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h1v-4h1V5H9V3h1V2h1V1h2v1h1v1h1v2h-2v6h1v4h1v-1h1v-1h1v-1h1v-2h1V5z'/>");
		art.mask[8] = Item("Dash", "<path d='M13 3V2h-2v2h2zM13 1V0h-2v1h1zM10 4H9V1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h1v-2H9v-3h2V5h-1zM18 5V3h-1V2h-1V1h-1v3h-1v1h-1v5h2v3h-1v2h1v-1h1v-1h1v-1h1v-2h1V5z'/>");
		art.mouth[0] = Item("Moustache", "<path fill='#421c03' opacity='.9' d='M14 10H9v3h1v-2h4v2h1v-3z'/>");
		art.bottoms[0] = Item("Tights", "<path class='lucha-alt' d='M15 17H8v6h3v-3h2v3h3v-6z'/>");
		art.bottoms[1] = Item("Trunk Tights", "<path class='lucha-base' d='M15 17H8v3h8v-3z'/><path class='lucha-alt' d='M15 18v1h-2v4h3v-5zM9 19v-1H8v5h3v-4h-1z'/>");
		art.boots[0] = Item("Two Tone", "<path class='lucha-alt' d='M9 22H8v1H7v1h4v-2h-1zM16 23v-1h-3v2h4v-1z'/>");
		art.boots[1] = Item("High", "<path class='lucha-alt' d='M9 20H8v1h3v-1h-1zM15 20h-2v1h3v-1z'/>");
		maxSupply = _maxSupply;
    }
    
	function tokenURI(uint256 _tokenId, uint256 _dna) external view returns (string memory) {
		return string(abi.encodePacked('data:application/json;base64,',Base64.encode(bytes(metadata(_tokenId,_dna)))));
	}
	
	// private funcs
	
	function metadata(uint256 _tokenId, uint256 _dna) private view returns (string memory) {
		uint8[12] memory dna = splitNumber(_dna);

		Item[8] memory artItems = [
			art.spirit[dna[0]],
			art.cape[dna[1]],
			art.torso[dna[2]],
			art.arms[dna[3]],
			art.mask[dna[4]],
			art.mouth[dna[5]],
			art.bottoms[dna[6]],
			art.boots[dna[7]]
		];

		string memory attributes;

		string[8] memory traitType = ["Spirit", "Cape", "Torso", "Arms", "Mask", "Mouth", "Bottoms", "Boots"];

		for (uint256 i = 0; i < artItems.length; i++) {
			if (artItems[i].name == "") continue;

			attributes = string(abi.encodePacked(attributes,
				bytes(attributes).length == 0	? '{' : ', {',
					'"trait_type": "', traitType[i],'",',
					'"value": "', bytes12ToString(artItems[i].name), '"',
				'}'
			));
		}

		return string(abi.encodePacked( // todo : change this
			'{',
				'"name": "Luchador #', _tokenId.toString(), '",', 
				'"description": "Luchadores are randomly generated using Chainlink VRF and have 100% on-chain art and metadata - Only ',maxSupply.toString(),' will ever exist!",',
				'"image_data": "', imageData(_tokenId, _dna), '",',
				'"external_url": "https://luchadores.io/luchador/', _tokenId.toString(), '",',
				'"attributes": [', attributes, ']',
			'}'
		));
	}
	
	function imageData(uint256 _tokenId, uint256 _dna) private view returns (string memory) {
		uint8[12] memory dna = splitNumber(_dna);

		string memory capeShoulders = (dna[1] == 0 || dna[1] == 1)? "<path class='lucha-alt' d='M20 10V9h-2v1h-1v1h4v-1zM5 9H4v1H3v1h4v-1H6V9z'/><path fill='#000' opacity='.2' d='M6 9H4v1H3v1h4v-1H6zM20 10V9h-2v1h-1v1h4v-1z'/>" : "";
		string memory capeHood = dna[1] == 1 ? "<path class='lucha-alt' d='M18 4V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1V6h1V5h2V4h1V3h4v1h1v1h2v1h1v4h1V5h-1z'/><g fill='#000'><path d='M18 4V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1V5h1V4h1V3h1V2h6v1h1v1h1v1h1v5h1V5h-1z' opacity='.2'/><path d='M16 4V3h-1V2H9v1H8v1H7v1h2V4h1V3h4v1h1v1h2V4zM6 5h1v1H6zM17 5h1v1h-1z' opacity='.5'/></g>" : "";

		return string(abi.encodePacked(
			"<svg id='luchador", _tokenId.toString(), "' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>",
				styles(_tokenId, dna),
				"<g class='lucha-breathe'>",
					art.spirit[dna[0]].svg,
					art.cape[dna[1]].svg,
					"<path class='lucha-skin' d='M22 12v-1h-1v-1h-1V9h-1V5h-1V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v4H4v1H3v1H2v1H1v8h4v-1h1v-2H5v-3h1v1h1v1h1v2h8v-2h1v-1h1v-1h1v3h-1v2h1v1h4v-8z'/>",
					art.torso[dna[2]].svg,
					art.arms[dna[3]].svg,
					capeShoulders,
					"<path class='lucha-base' d='M18 5V3h-1V2h-1V1h-1V0H9v1H8v1H7v1H6v2H5v5h1v2h1v1h1v1h1v1h6v-1h1v-1h1v-1h1v-2h1V5z'/>",
					"<g class='lucha-alt'>", art.mask[dna[4]].svg, "</g>",
					capeHood,
					"<path fill='#FFF' d='M9 6H6v3h4V6zM17 6h-3v3h4V6z'/><path class='lucha-eyes' d='M16 6h-2v3h3V6zM8 6H7v3h3V6H9z'/><path fill='#FFF' d='M7 6h1v1H7zM16 6h1v1h-1z' opacity='.4'/><path fill='#000' d='M15 7h1v1h-1zM8 7h1v1H8z'/>",
					"<path class='lucha-skin' d='M14 10H9v3h6v-3z'/>",
					"<path fill='#000' opacity='.9' d='M13 11h-3v1h4v-1z'/>",
					art.mouth[dna[5]].svg,
				"</g>",
				"<path class='lucha-skin' d='M16 23v-6H8v6H7v1h4v-4h2v4h4v-1z'/>",
				"<path class='lucha-base' d='M15 17H8v1h1v1h2v1h2v-1h2v-1h1v-1z'/>",
				art.bottoms[dna[6]].svg,
				"<path class='lucha-base' d='M9 21H8v2H7v1h4v-3h-1zM16 23v-2h-3v3h4v-1z'/>",
				art.boots[dna[7]].svg,
			"</svg>"
		));
	}

	function styles(uint256 _tokenId, uint8[12] memory _dna) private view returns (string memory) {
		return string(abi.encodePacked(
			"<style>#luchador", _tokenId.toString(), " .lucha-base { fill: #", art.baseColor[_dna[8]],
				"; } #luchador", _tokenId.toString(), " .lucha-alt { fill: #", art.altColor[_dna[9]],
				"; } #luchador", _tokenId.toString(), " .lucha-eyes { fill: #", art.eyeColor[_dna[10]],
				"; } #luchador", _tokenId.toString(), " .lucha-skin { fill: #", art.skinColor[_dna[11]],
				"; } #luchador", _tokenId.toString(), " .lucha-breathe { animation: 0.5s lucha-breathe infinite alternate ease-in-out; } @keyframes lucha-breathe { from { transform: translateY(0px); } to { transform: translateY(1%); } }</style>"
		));
	}
	
	// utils
	
	function splitNumber(uint256 _number) internal pure returns (uint8[12] memory) {
		uint8[12] memory numbers;

		for (uint256 i = 0; i < numbers.length; i++) {
			numbers[i] = uint8(_number % 10);
			_number /= 10;
		}

		return numbers;
	}

	function bytes12ToString(bytes12 _bytes12) internal pure returns (string memory) {
		uint8 i = 0;
		while(i < 12 && _bytes12[i] != 0) {
			i++;
		}

		bytes memory bytesArray = new bytes(i);
		for (i = 0; i < 12 && _bytes12[i] != 0; i++) {
			bytesArray[i] = _bytes12[i];
		}

		return string(bytesArray);
	}
}