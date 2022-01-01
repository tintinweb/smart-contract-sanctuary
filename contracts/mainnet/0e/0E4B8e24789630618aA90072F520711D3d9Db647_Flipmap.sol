// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../blitmaps/contracts/Blitmap.sol";

contract Flipmap is ERC721, ReentrancyGuard {

    uint256 public _tokenId = 1700;

    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }

    struct VariantParents {
        uint256 tokenIdA;
        uint256 tokenIdB;
    }

    mapping(uint256 => VariantParents) private _tokenParentIndex;
    mapping(bytes32 => bool) private _tokenPairs;
    mapping(address => uint256) private _creators;

    address sara    = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;
    address lambo   = 0xafBDEc0ba91FDFf03A91CbdF07392e6D72d43712;
    address dev     = 0xE424E566BFc3f7aDDFfb17862637DD61e2da3bE2;

    Blitmap blitmap;

    address private _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address _blitAddress) ERC721("Flipmap", "FLIP") {
        _owner = msg.sender;
        blitmap = Blitmap(_blitAddress);
    }

    function transferOwner(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenId - 1700;
    }

    function savePairs(uint256[][] memory pairHashes) public onlyOwner {
        for(uint256 i=0; i<pairHashes.length; i++) {
            bytes32 pairHash = keccak256(abi.encodePacked(pairHashes[i][0], '-', pairHashes[i][1]));
            _tokenPairs[pairHash] = true;
        }
    }

    function mintVariant(uint256 tokenIdA, uint256 tokenIdB) public nonReentrant payable {
        require(msg.value == 0.03 ether);
        require(tokenIdA != tokenIdB, "b:08");
        require(blitmap.tokenIsOriginal(tokenIdA) && blitmap.tokenIsOriginal(tokenIdB), "b:10");

        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, '-', tokenIdB));
        require(_tokenPairs[pairHash] == false, "b:11");

        uint256 variantTokenId = _tokenId;
        _tokenId++;

        VariantParents memory parents;
        parents.tokenIdA = tokenIdA;
        parents.tokenIdB = tokenIdB;

        address creatorA = blitmap.tokenCreatorOf(tokenIdA);
        address creatorB = blitmap.tokenCreatorOf(tokenIdB);

        _tokenParentIndex[variantTokenId] = parents;
        _tokenPairs[pairHash] = true;
        _safeMint(msg.sender, variantTokenId);

        _creators[creatorA]     += .0065625 ether;
        _creators[creatorB]     += .0009375 ether;
        _creators[sara]         += .0075 ether;
        _creators[lambo]        += .0075 ether;
        _creators[dev]          += .0075 ether;
    }

    function availableBalanceForCreator(address creatorAddress) public view returns (uint256) {
        return _creators[creatorAddress];
    }

    function withdrawAvailableBalance() public nonReentrant {
        uint256 withdrawAmount = _creators[msg.sender];
        _creators[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawAmount);
    }

    function getByOwner(address owner) view public returns(uint256[] memory result) {
        result = new uint256[](balanceOf(owner));
        uint256 resultIndex = 0;
        for (uint256 t = 0; t < _tokenId; t++) {
            if (_exists(t) && ownerOf(t) == owner) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function pairIsTaken(uint256 tokenIdA, uint256 tokenIdB) public view returns (bool) {
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, '-', tokenIdB));
        return _tokenPairs[pairHash];
    }

    function currentTokenId() public view returns (uint256) {
        return _tokenId;
    }

    function tokenIsOriginal(uint256 tokenId) public view returns (bool) {
        if(tokenId < 1700) {
            return blitmap.tokenIsOriginal(tokenId);
        }
        return false;
    }

    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        if (tokenId < 1700) {
            return blitmap.tokenDataOf(tokenId);
        }

        bytes memory tokenParentData;
        if(_exists(tokenId)) {
            tokenParentData = blitmap.tokenDataOf(_tokenParentIndex[tokenId].tokenIdA);
            bytes memory tokenPaletteData = blitmap.tokenDataOf(_tokenParentIndex[tokenId].tokenIdB);
            for (uint8 i = 0; i < 12; ++i) {
                // overwrite palette data with parent B's palette data
                tokenParentData[i] = tokenPaletteData[i];
            }
        }

        return tokenParentData;
    }

    function tokenParentsOf(uint256 tokenId) public view returns (uint256, uint256) {
        require(!tokenIsOriginal(tokenId));
        return (_tokenParentIndex[tokenId].tokenIdA, _tokenParentIndex[tokenId].tokenIdB);
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    function uintToHexString(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }

    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return uint8(aByte) >> index & 1 == 1;
    }

    function colorIndex(bytes1 aByte, uint8 index1, uint8 index2) internal pure returns (uint) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }

    function pixel4(string[32] memory lookup, SVGCursor memory pos) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<rect fill="', pos.color1, '" x="', lookup[pos.x], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
            '<rect fill="', pos.color2, '" x="', lookup[pos.x + 1], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',

            string(abi.encodePacked(
                '<rect fill="', pos.color3, '" x="', lookup[pos.x + 2], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
                '<rect fill="', pos.color4, '" x="', lookup[pos.x + 3], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />'
            ))
        ));
    }

    function parentSvgDataOf(uint256 tokenIdA, uint256 tokenIdB) public view returns (string memory) {
        bytes memory tokenParentData = blitmap.tokenDataOf(tokenIdA);
        bytes memory tokenPaletteData = blitmap.tokenDataOf(tokenIdB);
        for (uint8 i = 0; i < 12; ++i) {
            // overwrite palette data with parent B's palette data
            tokenParentData[i] = tokenPaletteData[i];
        }
        return tokenSvgData(tokenParentData);
    }

    function tokenSvgDataOf(uint256 tokenId) public view returns (string memory) {
        bytes memory data = tokenDataOf(tokenId);
        return tokenSvgData(data);
    }

    function tokenSvgData(bytes memory data) public pure returns (string memory) {
        string memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 1000 1000"><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32" shape-rendering="crispEdges"><g transform="translate(32, 0) scale(-1,1)">';

        string[32] memory lookup = [
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "10", "11", "12", "13", "14", "15",
        "16", "17", "18", "19", "20", "21", "22", "23",
        "24", "25", "26", "27", "28", "29", "30", "31"
        ];

        SVGCursor memory pos;

        string[4] memory colors = [
        string(abi.encodePacked("#", byteToHexString(data[0]), byteToHexString(data[1]), byteToHexString(data[2]))),
        string(abi.encodePacked("#", byteToHexString(data[3]), byteToHexString(data[4]), byteToHexString(data[5]))),
        string(abi.encodePacked("#", byteToHexString(data[6]), byteToHexString(data[7]), byteToHexString(data[8]))),
        string(abi.encodePacked("#", byteToHexString(data[9]), byteToHexString(data[10]), byteToHexString(data[11])))
        ];

        string[8] memory p;

        for (uint i = 12; i < 268; i += 8) {
            pos.color1 =  colors[colorIndex(data[i], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i], 0, 1)];
            p[0] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 1], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 1], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 1], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 1], 0, 1)];
            p[1] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 2], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 2], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 2], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 2], 0, 1)];
            p[2] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 3], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 3], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 3], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 3], 0, 1)];
            p[3] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 4], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 4], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 4], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 4], 0, 1)];
            p[4] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 5], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 5], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 5], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 5], 0, 1)];
            p[5] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 6], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 6], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 6], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 6], 0, 1)];
            p[6] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 7], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 7], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 7], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 7], 0, 1)];
            p[7] = pixel4(lookup, pos);
            pos.x += 4;

            svgString = string(abi.encodePacked(svgString, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]));

            if (pos.x >= 32) {
                pos.x = 0;
                pos.y += 1;
            }
        }

        svgString = string(abi.encodePacked(svgString, "</g></svg></svg>"));
        return svgString;
    }

    function tokenRGBColorsOf(uint256 tokenId) public view returns (BlitmapAnalysis.Colors memory) {
        return BlitmapAnalysis.tokenRGBColorsOf(tokenDataOf(tokenId));
    }

    function tokenSlabsOf(uint256 tokenId) public view returns (string[4] memory) {
        bytes memory data = tokenDataOf(tokenId);
        BlitmapAnalysis.Colors memory rgb = BlitmapAnalysis.tokenRGBColorsOf(data);

        string[4] memory chars = [unicode"◢", unicode"◣", unicode"◤", unicode"◥"];
        string[4] memory slabs;

        slabs[0] = chars[(rgb.r[0] + rgb.g[0] + rgb.b[0]) % 4];
        slabs[1] = chars[(rgb.r[1] + rgb.g[1] + rgb.b[1]) % 4];
        slabs[2] = chars[(rgb.r[2] + rgb.g[2] + rgb.b[2]) % 4];
        slabs[3] = chars[(rgb.r[3] + rgb.g[3] + rgb.b[3]) % 4];

        return slabs;
    }

    function tokenAffinityOf(uint256 tokenId) public view returns (string[3] memory) {
        return BlitmapAnalysis.tokenAffinityOf(tokenDataOf(tokenId));
    }

    function makeAttributes(uint256 tokenId) public view returns (string memory attributes) {
        string[5] memory traits;

        uint256 parentA = _tokenParentIndex[tokenId].tokenIdA;
        uint256 parentB = _tokenParentIndex[tokenId].tokenIdB;

        traits[0] = '{"trait_type":"Type","value":"Flipling"}';
        traits[1] = string(abi.encodePacked('{"trait_type":"Composition","value":"', blitmap.tokenNameOf(parentA), ' (#', toString(parentA), ')"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"Palette","value":"', blitmap.tokenNameOf(parentB), ' (#', toString(parentB), ')"}'));

        string[3] memory affinity = tokenAffinityOf(tokenId);
        traits[3] = string(abi.encodePacked('{"trait_type":"Affinity","value":"', affinity[0]));
        if(bytes(affinity[1]).length > 0) {
            traits[3] = string(abi.encodePacked(traits[3], ', ', affinity[1]));
        }
        if(bytes(affinity[2]).length > 0) {
            traits[3] = string(abi.encodePacked(traits[3], ', ', affinity[2]));
        }
        traits[3] = string(abi.encodePacked(traits[3], '"}'));

        string[4] memory slabs = tokenSlabsOf(tokenId);
        traits[4] = string(abi.encodePacked('{"trait_type":"Slabs","value":"', slabs[0], ' ', slabs[1], ' ', slabs[2], ' ', slabs[3], '"}'));

        attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2], ',', traits[3], ',', traits[4]));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint256 parentA = _tokenParentIndex[tokenId].tokenIdA;
        uint256 parentB = _tokenParentIndex[tokenId].tokenIdB;

        string memory name = string(abi.encodePacked('#', toString(tokenId), ' - ', blitmap.tokenNameOf(parentA), ' ', blitmap.tokenNameOf(parentB)));
        string memory description = 'Flipmaps are the lost 8,300 Blitmaps, only flipped.';
        string memory image = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(tokenSvgDataOf(tokenId)))));
        string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '", "attributes": [', makeAttributes(tokenId), ']}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function toString(uint256 value) public pure returns (string memory) {
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
}


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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright 2018 James Lockhart <[email protected]>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.8.0;

/**
 * Strings Library
 *
 * In summary this is a simple library of string functions which make simple
 * string operations less tedious in solidity.
 *
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 *
 * @author James Lockhart <[email protected]>
 */
library StringUtil {

    function titleCase(string memory _base)
    internal
    pure
    returns (string[] memory) {
        string[] memory components = split(_base, " ");
        for (uint8 i = 0; i < components.length; ++i) {
            if (length(components[i]) == 0) {
                continue;
            }
            string memory firstChar = substring(components[i], 1);
            string memory remainingChars = _substring(components[i], int(StringUtil.length(components[i]) - 1), 1);
            components[i] = string(abi.encodePacked(upper(firstChar), remainingChars));
        }

        return components;
    }

    /**
     * Concat (High gas cost)
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
    internal
    pure
    returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
    internal
    pure
    returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
    internal
    pure
    returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     *
     * Extracts the beginning part of a string based on the desired length
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
    internal
    pure
    returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     *
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    /**
     * String Split (Very high gas cost)
     *
     * Splits a string into an array of strings based off the delimiter value.
     * Please note this can be quite a gas expensive function due to the use of
     * storage so only use if really required.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * @param _value The delimiter to split the string on which must be a single
     *               character
     * @return splitArr An array of values split based off the delimiter, but
     *                  do not container the delimiter.
     */
    function split(string memory _base, string memory _value)
    internal
    pure
    returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
    internal
    pure
    returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     *
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
    internal
    pure
    returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string memory _base)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
    private
    pure
    returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
    private
    pure
    returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library BlitmapAnalysis {
    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function tokenRGBColorsOf(bytes memory data) public pure returns (Colors memory) {
        Colors memory rgb;

        rgb.r[0] = byteToUint(data[0]);
        rgb.g[0] = byteToUint(data[1]);
        rgb.b[0] = byteToUint(data[2]);

        rgb.r[1] = byteToUint(data[3]);
        rgb.g[1] = byteToUint(data[4]);
        rgb.b[1] = byteToUint(data[5]);

        rgb.r[2] = byteToUint(data[6]);
        rgb.g[2] = byteToUint(data[7]);
        rgb.b[2] = byteToUint(data[8]);

        rgb.r[3] = byteToUint(data[9]);
        rgb.g[3] = byteToUint(data[10]);
        rgb.b[3] = byteToUint(data[11]);

        return rgb;
    }

    function tokenSlabsOf(bytes memory data) public pure returns (string[4] memory) {
        Colors memory rgb = tokenRGBColorsOf(data);

        string[4] memory chars = ["&#9698;", "&#9699;", "&#9700;", "&#9701;"];
        string[4] memory slabs;

        slabs[0] = chars[(rgb.r[0] + rgb.g[0] + rgb.b[0]) % 4];
        slabs[1] = chars[(rgb.r[1] + rgb.g[1] + rgb.b[1]) % 4];
        slabs[2] = chars[(rgb.r[2] + rgb.g[2] + rgb.b[2]) % 4];
        slabs[3] = chars[(rgb.r[3] + rgb.g[3] + rgb.b[3]) % 4];

        return slabs;
    }

    function tokenAffinityOf(bytes memory data) public pure returns (string[3] memory) {
        Colors memory rgb = tokenRGBColorsOf(data);

        uint r = rgb.r[0] + rgb.r[1] + rgb.r[2];
        uint g = rgb.g[0] + rgb.g[1] + rgb.g[2];
        uint b = rgb.b[0] + rgb.b[1] + rgb.b[2];

        string[3] memory essences;
        uint8 offset;

        if (r >= g && r >= b) {
            essences[offset] = "Fire";
            ++offset;

            if (g > 256) {
                essences[offset] = "Earth";
                ++offset;
            }

            if (b > 256) {
                essences[offset] = "Water";
                ++offset;
            }
        } else if (g >= r && g >= b) {
            essences[offset] = "Earth";
            ++offset;

            if (r > 256) {
                essences[offset] = "Fire";
                ++offset;
            }

            if (b > 256) {
                essences[offset] = "Water";
                ++offset;
            }
        } else if (b >= r && b >= g) {
            essences[offset] = "Water";
            ++offset;

            if (r > 256) {
                essences[offset] = "Fire";
                ++offset;
            }

            if (g > 256) {
                essences[offset] = "Earth";
                ++offset;
            }
        }

        if (offset == 1) {
            essences[0] = string(abi.encodePacked(essences[0], " III"));
        } else if (offset == 2) {
            essences[0] = string(abi.encodePacked(essences[0], " II"));
            essences[1] = string(abi.encodePacked(essences[1], " I"));
        } else if (offset == 3) {
            essences[0] = string(abi.encodePacked(essences[0], " I"));
            essences[1] = string(abi.encodePacked(essences[1], " I"));
            essences[2] = string(abi.encodePacked(essences[2], " I"));
        }

        return essences;
    }
}

/*
______ _     _____ _____
| ___ \ |   |_   _|_   _|
| |_/ / |     | |   | |
| ___ \ |     | |   | |
| |_/ / |_____| |_  | |
\____/\_____/\___/  \_/
___  ___  ___  ______
|  \/  | / _ \ | ___ \
| .  . |/ /_\ \| |_/ /
| |\/| ||  _  ||  __/
| |  | || | | || |
\_|  |_/\_| |_/\_|

by dom hofmann and friends
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./blitmap-analysis.sol";
import "./string-util.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Blitmap is ERC721Enumerable {
    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct VariantParents {
        uint256 tokenIdA;
        uint256 tokenIdB;
    }

    struct Creator {
        string name;
        bool isAllowed;
        uint256 availableBalance;
        uint8 remainingMints;
    }

    struct TokenMetadata {
        string name;
        address creator;
        uint8 remainingVariants;
    }

    struct Colors {
        uint[4] r;
        uint[4] g;
        uint[4] b;
    }

    address private _owner;
    mapping (address => Creator) private _allowedList;
    event AddedToAllowedList(address indexed account);
    event RemovedFromAllowedList(address indexed account);
    event Published();
    event MetadataChanged(uint256 indexed tokenId, TokenMetadata indexed newMetadata);

    mapping(uint256 => VariantParents) private _tokenParentIndex;
    mapping(bytes32 => bool) private _tokenPairs;

    bytes[] private _tokenDataIndex;
    TokenMetadata[] private _tokenMetadataIndex;

    string private _uriPrefix;

    uint8 private _numOriginals;
    uint8 private constant _maxNumOriginals = 128;
    uint8 private constant _maxNumVariants = 16;

    bool public published;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier onlyAllowed() {
        require(isAllowed(msg.sender));
        _;
    }

    constructor() ERC721("Blitmap", "BLIT") {
        _owner = msg.sender;

        published = false;

        setBaseURI("https://api.blitmap.com/v1/metadata/");

        addAllowed(msg.sender, "sara", 128);
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _uriPrefix;
    }

    function setBaseURI(string memory prefix) public onlyOwner {
        _uriPrefix = prefix;
    }

    function addAllowed(address _address, string memory name, uint8 allowedMints) public onlyOwner {
        Creator memory creator;
        creator.name = name;
        creator.isAllowed = true;
        creator.remainingMints = allowedMints;
        _allowedList[_address] = creator;
        emit AddedToAllowedList(_address);
    }

    function changeMetadataOf(uint256 tokenId, TokenMetadata memory newMetadata) public onlyOwner {
        require(published == false, "b:01"); // only allow changes prior to publishing
        _tokenMetadataIndex[tokenId] = newMetadata;
        emit MetadataChanged(tokenId, newMetadata);
    }

    function publish() public onlyOwner {
        published = true;
        emit Published();
    }

    /*
    function removeAllowed(address _address) public onlyOwner {
        _allowedList[_address].isAllowed = false;
        emit RemovedFromAllowedList(_address);
    }
    */

    function isAllowed(address _address) public view returns (bool) {
        return _allowedList[_address].isAllowed == true;
    }

    function creatorNameOf(address _address) public view returns (string memory) {
        return _allowedList[_address].name;
    }

    function mintOriginal(bytes memory tokenData, string memory name) public onlyAllowed {
        require(published == false, "b:01");
        require(_numOriginals < _maxNumOriginals, "b:03");
        require(tokenData.length == 268, "b:04"); // any combination of 268 bytes is technically a valid blit
        require(bytes(name).length > 0 && bytes(name).length < 11, "b:05");
        require(_allowedList[msg.sender].remainingMints > 0, "b:06");

        uint256 tokenId = totalSupply();

        _tokenDataIndex.push(tokenData);

        TokenMetadata memory metadata;
        metadata.name = name;
        metadata.remainingVariants = _maxNumVariants;
        metadata.creator = msg.sender;
        _allowedList[msg.sender].remainingMints--;
        _tokenMetadataIndex.push(metadata);

        _numOriginals++;

        _safeMint(msg.sender, tokenId);
    }

    /*
    function remainingNumOriginals() public view returns (uint8) {
        return _maxNumOriginals - _numOriginals;
    }

    function remainingNumMints(address _address) public view returns (uint8) {
        return _allowedList[_address].remainingMints;
    }

    function allowedNumOriginals() public pure returns (uint8) {
        return _maxNumOriginals;
    }

    function allowedNumVariants() public pure returns (uint8) {
        return _maxNumVariants;
    }

    function availableBalanceForCreator(address creatorAddress) public view returns (uint256) {
        return _allowedList[creatorAddress].availableBalance;
    }

    function withdrawAvailableBalance() public onlyAllowed {
        uint256 withdrawAmount = _allowedList[msg.sender].availableBalance;
        _allowedList[msg.sender].availableBalance = 0;
        payable(msg.sender).transfer(withdrawAmount);
    }
    */

    function mintVariant(uint256 tokenIdA, uint256 tokenIdB) public payable {
        require(msg.value == 0.1 ether);
        require(published == true, "b:02");
        require(_exists(tokenIdA) && _exists(tokenIdB), "b:07");
        require(tokenIdA != tokenIdB, "b:08");
        require(tokenRemainingVariantsOf(tokenIdA) > 0, "b:09");
        require(tokenIsOriginal(tokenIdA) && tokenIsOriginal(tokenIdB), "b:10");

        // a given pair can only be minted once
        bytes32 pairHash = keccak256(abi.encodePacked(tokenIdA, tokenIdB));
        require(_tokenPairs[pairHash] == false, "b:11");

        uint256 variantTokenId = totalSupply();

        VariantParents memory parents;
        parents.tokenIdA = tokenIdA;
        parents.tokenIdB = tokenIdB;

        _tokenMetadataIndex[tokenIdA].remainingVariants--;

        // don't need to write real data here since we can assemble sibling data from parent data
        _tokenDataIndex.push(hex"00");

        TokenMetadata memory metadata;
        metadata.name = "";
        metadata.remainingVariants = 0;
        metadata.creator = msg.sender;
        _tokenMetadataIndex.push(metadata);

        _tokenParentIndex[variantTokenId] = parents;
        _tokenPairs[pairHash] = true;
        _safeMint(msg.sender, variantTokenId);

        _allowedList[_tokenMetadataIndex[tokenIdA].creator].availableBalance += 0.0875 ether;
        _allowedList[_tokenMetadataIndex[tokenIdB].creator].availableBalance += 0.0125 ether;
    }

    function tokenNameOf(uint256 tokenId) public view returns (string memory) {
        string memory name;
        if (tokenIsOriginal(tokenId)) {
            name = _tokenMetadataIndex[tokenId].name;
        } else {
            VariantParents memory parents = _tokenParentIndex[tokenId];
            name = string(abi.encodePacked(tokenNameOf(parents.tokenIdA), " ", tokenNameOf(parents.tokenIdB)));
        }

        string[] memory components = StringUtil.titleCase(name);
        string memory titleCaseName;
        for (uint8 i = 0; i < components.length; ++i) {
            if (i == 0) {
                titleCaseName = components[i];
            } else {
                titleCaseName = string(abi.encodePacked(titleCaseName, " ", components[i]));
            }
        }

        return titleCaseName;
    }

    function tokenIsOriginal(uint256 tokenId) public view returns (bool) {
        return (_tokenDataIndex[tokenId].length == 268);
    }

    function tokenParentsOf(uint256 tokenId) public view returns (uint256, uint256) {
        require(!tokenIsOriginal(tokenId));
        return (_tokenParentIndex[tokenId].tokenIdA, _tokenParentIndex[tokenId].tokenIdB);
    }

    function tokenCreatorOf(uint256 tokenId) public view returns (address) {
        return _tokenMetadataIndex[tokenId].creator;
    }

    /*
    function tokenCreatorNameOf(uint256 tokenId) public view returns (string memory) {
        return _allowedList[tokenCreatorOf(tokenId)].name;
    }
    */

    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        bytes memory data = _tokenDataIndex[tokenId];
        if (tokenIsOriginal(tokenId)) {
            return data;
        }

        bytes memory tokenParentData = _tokenDataIndex[_tokenParentIndex[tokenId].tokenIdA];
        bytes memory tokenPaletteData = _tokenDataIndex[_tokenParentIndex[tokenId].tokenIdB];
        for (uint8 i = 0; i < 12; ++i) {
            // overwrite palette data with parent B's palette data
            tokenParentData[i] = tokenPaletteData[i];
        }

        return tokenParentData;
    }

    function tokenRemainingVariantsOf(uint256 tokenId) public view returns (uint256) {
        if (!tokenIsOriginal(tokenId)) {
            return 0;
        }
        return _tokenMetadataIndex[tokenId].remainingVariants;
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    function uintToHexString(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString(byteToUint(b));
    }

    function bitTest(bytes1 aByte, uint8 index) internal pure returns (bool) {
        return uint8(aByte) >> index & 1 == 1;
    }

    function colorIndex(bytes1 aByte, uint8 index1, uint8 index2) internal pure returns (uint) {
        if (bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 3;
        } else if (bitTest(aByte, index2) && !bitTest(aByte, index1)) {
            return 2;
        } else if (!bitTest(aByte, index2) && bitTest(aByte, index1)) {
            return 1;
        }
        return 0;
    }

    function pixel4(string[32] memory lookup, SVGCursor memory pos) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<rect fill="', pos.color1, '" x="', lookup[pos.x], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
                '<rect fill="', pos.color2, '" x="', lookup[pos.x + 1], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',

                string(abi.encodePacked(
                    '<rect fill="', pos.color3, '" x="', lookup[pos.x + 2], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />',
                    '<rect fill="', pos.color4, '" x="', lookup[pos.x + 3], '" y="', lookup[pos.y], '" width="1.5" height="1.5" />'
                ))
            ));
    }

    function tokenSvgDataOf(uint256 tokenId) public view returns (string memory) {
        string memory svgString = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32">';

        string[32] memory lookup = [
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "10", "11", "12", "13", "14", "15",
        "16", "17", "18", "19", "20", "21", "22", "23",
        "24", "25", "26", "27", "28", "29", "30", "31"
        ];

        SVGCursor memory pos;

        bytes memory data = tokenDataOf(tokenId);

        string[4] memory colors = [
        string(abi.encodePacked("#", byteToHexString(data[0]), byteToHexString(data[1]), byteToHexString(data[2]))),
        string(abi.encodePacked("#", byteToHexString(data[3]), byteToHexString(data[4]), byteToHexString(data[5]))),
        string(abi.encodePacked("#", byteToHexString(data[6]), byteToHexString(data[7]), byteToHexString(data[8]))),
        string(abi.encodePacked("#", byteToHexString(data[9]), byteToHexString(data[10]), byteToHexString(data[11])))
        ];

        string[8] memory p;

        for (uint i = 12; i < 268; i += 8) {
            pos.color1 =  colors[colorIndex(data[i], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i], 0, 1)];
            p[0] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 1], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 1], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 1], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 1], 0, 1)];
            p[1] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 2], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 2], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 2], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 2], 0, 1)];
            p[2] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 3], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 3], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 3], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 3], 0, 1)];
            p[3] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 4], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 4], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 4], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 4], 0, 1)];
            p[4] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 5], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 5], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 5], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 5], 0, 1)];
            p[5] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 6], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 6], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 6], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 6], 0, 1)];
            p[6] = pixel4(lookup, pos);
            pos.x += 4;

            pos.color1 =  colors[colorIndex(data[i + 7], 6, 7)];
            pos.color2 =  colors[colorIndex(data[i + 7], 4, 5)];
            pos.color3 =  colors[colorIndex(data[i + 7], 2, 3)];
            pos.color4 =  colors[colorIndex(data[i + 7], 0, 1)];
            p[7] = pixel4(lookup, pos);
            pos.x += 4;

            svgString = string(abi.encodePacked(svgString, p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]));

            if (pos.x >= 32) {
                pos.x = 0;
                pos.y += 1;
            }
        }

        svgString = string(abi.encodePacked(svgString, "</svg>"));
        return svgString;
    }

    function tokenRGBColorsOf(uint256 tokenId) public view returns (BlitmapAnalysis.Colors memory) {
        return BlitmapAnalysis.tokenRGBColorsOf(tokenDataOf(tokenId));
    }

    function tokenSlabsOf(uint256 tokenId) public view returns (string[4] memory) {
        return BlitmapAnalysis.tokenSlabsOf(tokenDataOf(tokenId));
    }

    function tokenAffinityOf(uint256 tokenId) public view returns (string[3] memory) {
        return BlitmapAnalysis.tokenAffinityOf(tokenDataOf(tokenId));
    }
}

/*
errors:
01: This can only be done before the project has been published.
02: This can only be done after the project has been published.
03: The maximum number of originals has been minted.
04: Blitmaps must be exactly 268 bytes.
05: Blitmaps must have a title must be between 1 and 10 characters.
06: You have reached your quota for minted originals.
07: One of the originals in this combination doesn't exist.
08: An original cannot be combined with itself.
09: This original has sold out all of its siblings.
10: Both blitmaps in this combination must be originals.
11: A sibling with this combination already exists.
*/