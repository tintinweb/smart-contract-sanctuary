// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

interface ICorruptionsMetadata {
    function tokenURI(uint256 tokenId, uint256 amount) external view returns (string memory);
}

interface ICorruptionsDataMapper {
    function valueFor(uint256 mapIndex, uint256 key) external view returns (uint256);
}

interface ICorruptionsDeviationWriter {
    function drawCanvas(uint256 tokenId, uint256 amount) external pure returns (string[32] memory);
}

struct InsightMap {
    uint256 savedXP;
    uint256 lastSaveBlock;
}

interface ICorruptions {
    function insightMap(uint256 tokenID) external view returns (InsightMap memory);
}

contract CorruptionsMetadata is Ownable, ICorruptionsMetadata {
    string public description;
    ICorruptionsDataMapper private dataMapper;
    ICorruptionsDeviationWriter private roseWriter;

    struct RandParts {
        string border;
        string corruptor;
        string phrase;
        string checker;
        bool omitInsight;
        uint16 reduction;
    }

    constructor() Ownable() {
        description = "Unknown";
        dataMapper = ICorruptionsDataMapper(0x7A96d95a787524a27a4df36b64a96910a2fDCF5B);
    }

    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }

    function setRoseWriter(address addr) public onlyOwner {
        roseWriter = ICorruptionsDeviationWriter(addr);
    }

    function _blank(string[32] memory canvas) public pure returns (string[32] memory) {
        for (uint8 i = 0; i < 32; i++) {
            canvas[i] = "...............................";
        }
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

    function _checkeredBox(string[32] memory canvas, string memory char, string memory char2, uint256 x, uint256 y, uint256 w, uint256 h) public pure returns (string[32] memory) {
        bytes1 byteChar = bytes(char)[0];
        bytes1 byteChar2 = bytes(char2)[0];
        for (uint256 iy = 0; iy < h; iy++) {
            for (uint256 ix = 0; ix < w; ix++) {
                bytes(canvas[iy + y])[ix + x] = ((iy + y) + (ix + x)) % 2 == 0 ? byteChar : byteChar2;
            }
        }
        return canvas;
    }

    function _drawCircle(string[32] memory canvas, string memory char, uint256 xc, uint256 yc, uint256 x, uint256 y) public pure returns (string[32] memory) { 
        bytes1 byteChar = bytes(char)[0];
        bytes(canvas[yc + y])[xc + x] = byteChar;
        bytes(canvas[yc + y])[xc - x] = byteChar;
        bytes(canvas[yc - y])[xc + x] = byteChar;
        bytes(canvas[yc - y])[xc - x] = byteChar;
        bytes(canvas[yc + x])[xc + y] = byteChar;
        bytes(canvas[yc + x])[xc - y] = byteChar;
        bytes(canvas[yc - x])[xc + y] = byteChar;
        bytes(canvas[yc - x])[xc - y] = byteChar;

        return canvas;
    }

    function _circle(string[32] memory canvas, string memory char, uint256 xc, uint256 yc, int8 r) public pure returns (string[32] memory) {
        // https://www.geeksforgeeks.org/bresenhams-circle-drawing-algorithm/

        int256 x = 0;
        int256 y = int256(r);
        int256 d = 3 - 2 * r;
        canvas = _drawCircle(canvas, char, xc, yc, uint256(x), uint256(y));
        while (y >= x) {
            x++;

            if (d > 0) {
                y--;
                d = d + 4 * (x - y) + 10;
            } else {
                d = d + 4 * x + 6;
            }
            canvas = _drawCircle(canvas, char, xc, yc, uint256(x), uint256(y));
        }

        return canvas;
    }

    function _middleBox(string[32] memory canvas, string memory char, string memory char2, uint256 size) public pure returns (string[32] memory) {
        canvas = _checkeredBox(canvas, char, char2, 15 - size, 15 - size, size * 2 + 1, size * 2 + 1);
        return canvas;
    }

    function _text(string[32] memory canvas, string memory message, uint256 messageLength, uint256 x, uint256 y) public pure returns (string[32] memory) {
        for (uint256 i = 0; i < messageLength; i++) {
            bytes(canvas[y])[x + i] = bytes(message)[i];
        }

        return canvas;
    }

    function draw(uint256 tokenId, uint256 amount, string[32] memory oCanvas) public pure returns (string memory) {
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

        string[40] memory randomStrings = [
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
            "CORRUPTION",

            "|",
            "-",
            "=",
            "+",
            "\\",
            ":",
            "~"
        ];

        RandParts memory randParts;

        randParts.border = randomStrings[uint256(keccak256(abi.encodePacked("BORDER", tokenId))) % 11];
        randParts.corruptor = randomStrings[uint256(keccak256(abi.encodePacked("CORRUPTOR", tokenId))) % 11];
        randParts.phrase = randomStrings[23 + uint256(keccak256(abi.encodePacked("PHRASE", tokenId))) % 10];
        randParts.checker = randomStrings[33 + uint256(keccak256(abi.encodePacked("CHECKER", tokenId))) % 7];

        string[32] memory canvas;

        if (bytes(oCanvas[0]).length > 0) {
            canvas = oCanvas;
            randParts.omitInsight = true;
            randParts.reduction = 64;
        } else {
            canvas = _blank(canvas);

            canvas = _box(canvas, randParts.border, 0, 0, 31, 1);
            canvas = _box(canvas, randParts.border, 0, 30, 31, 1);
            canvas = _box(canvas, randParts.border, 0, 0, 1, 31);
            canvas = _box(canvas, randParts.border, 30, 0, 1, 31);

            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[0])), 15, 15, 12);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[1])), 15, 15, 11);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[2])), 15, 15, 10);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[3])), 15, 15, 9);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[4])), 15, 15, 8);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[5])), 15, 15, 7);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[6])), 15, 15, 6);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[7])), 15, 15, 5);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[8])), 15, 15, 4);
            canvas = _circle(canvas, string(abi.encodePacked(bytes(randParts.phrase)[9])), 15, 15, 3);

        }

        uint256 iterations = uint256(keccak256(abi.encodePacked("CORRUPTION", tokenId))) % 1024;
        if (randParts.reduction > 0) {
            iterations = iterations % randParts.reduction;
        }
        for (uint256 i = 0; i < iterations; i++) {
            canvas = _box(canvas, randParts.corruptor, uint256(keccak256(abi.encodePacked("X", i, tokenId))) % 30, uint256(keccak256(abi.encodePacked("Y", i, tokenId))) % 30, 1, 1);
        }

        if (!randParts.omitInsight) {
            uint256 length = 8 + bytes(toString(amount)).length;
            canvas = _text(canvas, string(abi.encodePacked("INSIGHT ", toString(amount))), length, 31 - length, 30);


            for (uint i = 10; i > 0; i--) { 
                if (amount >= i * 2) {
                    canvas = _middleBox(canvas, string(abi.encodePacked(bytes(randParts.phrase)[i - 1])), randParts.checker, i);
                }
            }
        }

        string memory output;
        for (uint8 i = 0; i < 31; i++) {
            output = string(abi.encodePacked(
                output, '<text x="10" y="', lookup[i], '" class="base">', canvas[i], '</text>'
            ));
        }

        string[10] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 820 1340"><style>.base { fill: ';
        parts[1] = randomStrings[11 + uint256(keccak256(abi.encodePacked("BGCOLOR", tokenId))) % 6];
        parts[2] = '; font-family: monospace; font-size: 10px; }</style><g transform=\"scale(4 4)\"><rect width="205" height="335" fill="';
        parts[3] = amount >= 2 ? randomStrings[17 + uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) % 6] : randomStrings[27 + uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) % 6];
        parts[4] = '" />';
        parts[5] = output;
        parts[6] = "";
        parts[7] = "";
        parts[8] = ""; 
        parts[9] = '</g></svg>';

        if (amount >= 2) {
            parts[6] = "<!-- ";
            parts[7] = randomStrings[27 + uint256(keccak256(abi.encodePacked("FGCOLOR", tokenId))) % 6];
            parts[8] = " -->";
        }

        output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8], parts[9]));
        return Base64.encode(bytes(output));
    }

    function tokenURI(uint256 tokenId, uint256 amount) override external view returns (string memory) {
        ICorruptions corruptions = ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E);
        InsightMap memory insightMap = corruptions.insightMap(tokenId);

        if (insightMap.lastSaveBlock <= 13604851 && tokenId != 3193) {
            amount += 1; // fix early transfer bug
        }
        
        string memory json;
        string[32] memory emptyCanvas;
        
        if (dataMapper.valueFor(0, tokenId) == 1) {
            json = Base64.encode(bytes(string(abi.encodePacked('{"name": "0x', toHexString(tokenId), '", "description": "', description, '", "image": "data:image/svg+xml;base64,', draw(tokenId, amount, roseWriter.drawCanvas(tokenId, amount)), '", "attributes": [{"trait_type": "Deviation", "value": "WILTEDROSE"}]}'))));
        } else {
            json = Base64.encode(bytes(string(abi.encodePacked('{"name": "0x', toHexString(tokenId), '", "description": "', description, '", "image": "data:image/svg+xml;base64,', draw(tokenId, amount, emptyCanvas), '", "attributes": [{"trait_type": "Insight", "value": "', toString(amount), '"}]}'))));
        }
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

/// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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