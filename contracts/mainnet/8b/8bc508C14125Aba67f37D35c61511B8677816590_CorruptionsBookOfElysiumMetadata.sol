// SPDX-License-Identifier: Unlicense

// all interesting work below is by dom

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

interface ICorruptionsBookOfElysiumMetadata {
    function tokenURI(uint256 tokenId, uint256 style, uint32[] memory chapters, uint256 arete) external view returns (string memory);
}

interface ICorruptionsFont {
    function font() external view returns (string memory);
}

contract CorruptionsBookOfElysiumMetadata is Ownable, ICorruptionsBookOfElysiumMetadata {

    string public description;
    ICorruptionsFont private font;

    struct RandParts {
        string border;
        string corruptor;
        string phrase;
    }

    constructor() Ownable() {
        description = "Unknown";
        font = ICorruptionsFont(0xdf8A48979F33f12952Ab4cF6f960EA4071fc656b);
    }

    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }

    function setFont(address fontAddress) public onlyOwner {
        font = ICorruptionsFont(fontAddress);
    }

    function _blank(string[32] memory canvas) public pure returns (string[32] memory) {
        canvas[0] =  "...............................   COLLECTED:          ";
        canvas[1] =  "...............................                       ";
        canvas[2] =  "...............................                       ";
        canvas[3] =  "...............................                       ";
        canvas[4] =  "...............................                       ";
        canvas[5] =  "...............................                       ";
        canvas[6] =  "...............................                       ";
        canvas[7] =  "...............................                       ";
        canvas[8] =  "...............................                       ";
        canvas[9] =  "............./////////|........                       ";
        canvas[10] = "............/////////.|........                       ";
        canvas[11] = ".........../////////..|........                       ";
        canvas[12] = "........../////////...|........                       ";
        canvas[13] = ".........|~~~~~~~|....|........                       ";
        canvas[14] = ".........|=======|....|........                       ";
        canvas[15] = ".........|...E...|....|........                       ";
        canvas[16] = ".........|...L...|....|........                       ";
        canvas[17] = ".........|...Y...|....|........                       ";
        canvas[18] = ".........|...S...|....|........                       ";
        canvas[19] = ".........|...I...|....|........                       ";
        canvas[20] = ".........|...U...|.../.........                       ";
        canvas[21] = ".........|...M...|../..........                       ";
        canvas[22] = ".........|=======|./...........                       ";
        canvas[23] = ".........|_______|/............                       ";
        canvas[24] = "...............................                       ";
        canvas[25] = "...............................                       ";
        canvas[26] = "...............................                       ";
        canvas[27] = "...............................                       ";
        canvas[28] = "...............................                       ";
        canvas[29] = "...............................                       ";
        canvas[30] = "...............................                       ";
        canvas[31] = "...............................                       ";
        return canvas;
    }

    function _box(string[32] memory canvas, string memory char, uint256 x, uint256 y, uint256 w, uint256 h) public pure returns (string[32] memory) {
        bytes1 byteChar = bytes(char)[0];
        for (uint256 iy = 0; iy < h; iy++) {
            for (uint256 ix = 0; ix < w; ix++) {
                bytes(canvas[iy + y])[ix + x] = byteChar;
            }
        }
        return canvas;
    }

    function _text(string[32] memory canvas, string memory message, uint256 messageLength, uint256 x, uint256 y) public pure returns (string[32] memory) {
        for (uint256 i = 0; i < messageLength; i++) {
            bytes(canvas[y])[x + i] = bytes(message)[i];
        }

        return canvas;
    }

    function draw(uint256 style, uint32[] memory chapters, uint256 arete) public view returns (string memory) {
        string[31] memory lookup = [
            "20",
            "30",
            "40",
            "50",
            "60",
            "70",
            "80",
            "90",
            "100",
            "110",
            "120",
            "130",
            "140",
            "150",
            "160",
            "170",
            "180",
            "190",
            "200",
            "210",
            "220",
            "230",
            "240",
            "250",
            "260",
            "270",
            "280",
            "290",
            "300",
            "310",
            "320"
        ];

        string[33] memory randomStrings = [
            "/",
            "$",
            "|",
            "8",
            "_",
            "?",
            "#",
            "%",
            "^",
            "~",
            ":",

            "#022FB7",
            "#262A36",
            "#A802B7",
            "#3CB702",
            "#B76F02",
            "#B70284",

            "#0D1302",
            "#020A13",
            "#130202",
            "#1A1616",
            "#000000",
            "#040A27",
            
            "GENERATION",
            "INDIVIDUAL",
            "TECHNOLOGY",
            "EVERYTHING",
            "EVERYWHERE",
            "UNDERWORLD",
            "ILLUMINATI",
            "TEMPTATION",
            "REVELATION",
            "CORRUPTION"
        ];

        RandParts memory randParts;

        randParts.border = randomStrings[uint256(keccak256(abi.encodePacked("BORDER", style))) % 11];
        randParts.corruptor = randomStrings[uint256(keccak256(abi.encodePacked("CORRUPTOR", style))) % 11];
        randParts.phrase = randomStrings[23 + uint256(keccak256(abi.encodePacked("PHRASE", style))) % 10];

        string[32] memory canvas;
        canvas = _blank(canvas);

        canvas = _box(canvas, randParts.border, 0, 0, 31, 1);
        canvas = _box(canvas, randParts.border, 0, 30, 31, 1);
        canvas = _box(canvas, randParts.border, 0, 0, 1, 31);
        canvas = _box(canvas, randParts.border, 30, 0, 1, 31);

        uint256 iterations = uint256(keccak256(abi.encodePacked("CORRUPTION", style))) % 1024;
        for (uint256 i = 0; i < iterations; i++) {
            canvas = _box(canvas, randParts.corruptor, uint256(keccak256(abi.encodePacked("X", i, style))) % 30, uint256(keccak256(abi.encodePacked("Y", i, style))) % 30, 1, 1);
        }

        for (uint32 i = 0; i < chapters.length; i++) {
            uint256 length = 10 + bytes(toString(chapters[i])).length;
            canvas = _text(canvas, string(abi.encodePacked("+ CHAPTER ", toString(chapters[i]))), length, 34, 1 + i);
        }

        uint256 areteLength = 6 + bytes(toString(arete)).length;
        canvas = _text(canvas, string(abi.encodePacked("ARETE ", toString(arete))), areteLength, 31 - areteLength, 30);

        string memory output;
        for (uint8 i = 0; i < 31; i++) {
            output = string(abi.encodePacked(
                output, '<text x="10" y="', lookup[i], '" class="base">', canvas[i], '</text>'
            ));
        }

        string[9] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 305 335"><style>@font-face { font-family: CorruptionsFont; src: url("';
        parts[1] = font.font();
        parts[2] = '") format("opentype"); } .base { fill: ';
        parts[3] = randomStrings[11 + uint256(keccak256(abi.encodePacked("BGCOLOR", style))) % 6];
        parts[4] = '; font-family: CorruptionsFont; font-size: 10px; }</style><rect width="100%" height="100%" fill="';
        parts[5] = randomStrings[27 + uint256(keccak256(abi.encodePacked("FGCOLOR", style))) % 6];
        parts[6] = '" />';
        parts[7] = output;
        parts[8] = '</svg>';

        return Base64.encode(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
    }

    function tokenURI(uint256 tokenId, uint256 style, uint32[] memory chapters, uint256 arete) override external view returns (string memory) {
        quickSort(chapters, int32(0), int(chapters.length - 1));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "0x', toHexString(tokenId), '", "description": "', description, '", "image": "data:image/svg+xml;base64,', draw(style, chapters, arete), '", "attributes": [{"trait_type": "Chapters Collected", "value": ', toString(chapters.length), '},{"trait_type": "Arete", "value": ', toString(arete), '}]}'))));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function toHexString(uint i) internal pure returns (string memory) {
        // https://stackoverflow.com/a/69302348/424107
        
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }

}

function quickSort(uint32[] memory arr, int left, int right) pure {
    // https://ethereum.stackexchange.com/a/1518 - MIT License

    int i = left;
    int j = right;
    if (i == j) return;
    uint32 pivot = arr[uint(left + (right - left) / 2)];
    while (i <= j) {
        while (arr[uint(i)] < pivot) i++;
        while (pivot < arr[uint(j)]) j--;
        if (i <= j) {
            (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        quickSort(arr, left, j);
    if (i < right)
        quickSort(arr, i, right);
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}