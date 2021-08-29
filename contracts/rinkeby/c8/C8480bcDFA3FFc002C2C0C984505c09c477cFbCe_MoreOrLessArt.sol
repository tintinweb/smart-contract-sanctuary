// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

library MoreOrLessArt {

    using Strings for uint256;

    string public constant _imageFooter = "</svg>";

    function getRectanglePalette() public pure returns(string[5] memory) {
      return ['%23ece0d1', '%23dbc1ac', '%23967259', '%23634832', '%2338220f'];
    }

    function getCirclePalette() public pure returns(string[5] memory) {
      return ['%230F2A38', '%231D3C43', '%232A4930', '%23132F13', '%23092409'];
    }

    function getLinePalette() public pure returns(string[5] memory) {
      return ['%23b3e7dc', '%23a6b401', '%23eff67b', '%23d50102', '%236c0102'];
    }

    function getTrianglePalette() public pure returns(string[5] memory) {
      return ['%237c7b89', '%23f1e4de', '%23f4d75e', '%23e9723d', '%230b7fab'];
    }

    function getDBochmanPalette() public pure returns(string[5] memory) {
      return ['%23000000', '%233d3d3d', '%23848484', '%23bbbbbb', '%23ffffff'];
    }

    function getColorPalette(uint256 seed, uint256 nonce) private view returns(string[5] memory) {
        uint rand = seededRandom(0,3, seed, nonce);
        if (rand == 0) {
            return getCirclePalette();
        } else if (rand == 1) {
            return getTrianglePalette();
        } else if (rand == 2) {
            return getRectanglePalette();
        } else {
            return getDBochmanPalette();
        }
    }

    function random(uint256 nonce) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nonce)));
    }

    function seededRandom(uint low, uint high, uint256 seed, uint256 nonce) public view returns (uint) {
        uint seedR = uint(uint256(keccak256(abi.encodePacked(seed, random(nonce)))));
        uint randomnumber = seedR % high;
        randomnumber = randomnumber + low;
        return randomnumber;
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function addressToString(address _address) public pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function _generateHeader(uint256 seed) public view returns (string memory) {
        string memory header = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' id='moreorless' width='1000' height='1000' viewBox='0 0 1000 1000' style='background-color:";
        string memory color = getColorPalette(seed, seed)[seededRandom(0, 5, seed, seed*seed)];
        return string(abi.encodePacked(
            header,
            color,
            "'>"
        ));
    }

    function _generateCircles(uint256 seed, uint numShapes) public view returns (string memory) {
        string memory circles = '';
        string[5] memory colorPalette = getColorPalette(seed, seed);
        for (uint i = 0; i < numShapes; i++) {
            circles = string(abi.encodePacked(
                circles,
                "<ellipse cx='",
                seededRandom(0,1000,seed, i * i).toString(),
                "' cy='",
                seededRandom(0,1000,seed, i * i + 1).toString(),
                "' rx='",
                seededRandom(0,100,seed, i * i + 2).toString(),
                "' ry='",
                seededRandom(0,100,seed, i * i + 3).toString(),
                "'",
                " fill='",
                colorPalette[seededRandom(0, 5, seed, i*i+4)],
                "'",
            "/>"));
        }

        return string(abi.encodePacked(circles));
    }

    function _generateSLines(uint256 seed, uint256 nonce) public view returns (string memory) {
      return string(abi.encodePacked(
        " S",
        seededRandom(0,1000,seed, nonce).toString(),
        " ",
        seededRandom(0,1000,seed,nonce*2).toString(),
        " ",
        seededRandom(0,1000,seed,nonce*3).toString(),
        " ",
        seededRandom(0,1000,seed,nonce*4).toString()
      ));
    }

    function _generateLines(uint256 seed, uint numShapes) public view returns (string memory) {
        string memory lines = '';
        string[5] memory colorPalette = getColorPalette(seed, seed+1);
        for (uint i = 0; i < numShapes; i++) {
            lines = string(abi.encodePacked(
                lines,
                "<path style='fill:none; stroke:",
                colorPalette[seededRandom(0, 5, seed, i*i+1)],
                "; stroke-width: 10px;' d='M",
                seededRandom(0, 400, seed, i*i+2).toString(),
                " ",
                seededRandom(0, 400, seed, i*i+3).toString(),
                _generateSLines(seed, i*i+4),
                _generateSLines(seed, i*i+5),
                " Z'",
            "/>"));
        }

        return string(abi.encodePacked(lines));
    }

    function getTrianglePoints(uint256 seed, uint256 nonce) private view returns (string memory) {
        return string(abi.encodePacked(
            seededRandom(0, 1000, seed, nonce).toString(),
            ",",
            seededRandom(0, 1000, seed, nonce+2).toString(),
            " ",
            seededRandom(0, 1000, seed, nonce+3).toString(),
            ",",
            seededRandom(0, 1000, seed, nonce+4).toString(),
            " ",
            seededRandom(0, 1000, seed, nonce+5).toString(),
            ",",
            seededRandom(0, 1000, seed, nonce+6).toString(),
            "'"
      ));
    }

    function _generateTriangles(uint256 seed, uint numShapes) public view returns (string memory) {
        string memory triangles = '';
        string[5] memory colorPalette = getColorPalette(seed, seed+2);
        for (uint i = 0; i < numShapes; i++) {
            triangles = string(abi.encodePacked(
                triangles,
                "<polygon points='",
                getTrianglePoints(seed, i*i),
                " fill='",
                colorPalette[seededRandom(0, 5, seed, i*i+7)],
                "'",
            "/>"));
        }

        return string(abi.encodePacked(triangles));
    }

    function _generateRectangles(uint256 seed, uint numShapes) public view returns (string memory) {
        string memory rectangles = '';
        string[5] memory colorPalette = getColorPalette(seed, seed+3);
        for (uint i = 0; i < numShapes; i++) {
            rectangles = string(abi.encodePacked(
                rectangles,
                "<rect width='",
                seededRandom(0, 400, seed, i*i+1).toString(),
                "' height='",
                seededRandom(0, 400, seed, i*i+2).toString(),
                "' x='",
                seededRandom(0, 1000, seed, i*i+3).toString(),
                "' y='",
                seededRandom(0, 1000, seed, i*i+4).toString(),
                "'",
                " fill='",
                colorPalette[seededRandom(0, 5, seed, i*i+5)],
                "'",
            "/>"));
        }

        return string(abi.encodePacked(rectangles));
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}