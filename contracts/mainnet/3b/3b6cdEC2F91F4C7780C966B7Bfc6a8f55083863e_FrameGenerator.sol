// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './interfaces/IFrameGenerator.sol';
import './interfaces/IFrameSVGs.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @dev Generate Frame SVG and properties
contract FrameGenerator is IFrameGenerator {
    using Strings for uint16;

    IFrameSVGs immutable frameSVGs1;
    IFrameSVGs immutable frameSVGs2;

    constructor(FrameSVGs memory svgs) {
        frameSVGs1 = svgs.frameSVGs1;
        frameSVGs2 = svgs.frameSVGs2;
    }

    function generateFrame(uint16 frame) external view override returns (IFrameSVGs.FrameData memory) {
        if (frame <= 3) {
            return callFrameSVGs(frameSVGs1, frame);
        }

        if (frame <= 5) {
            return callFrameSVGs(frameSVGs2, frame);
        }

        revert('invalid frame selection');
    }

    function callFrameSVGs(IFrameSVGs target, uint16 frame) internal view returns (IFrameSVGs.FrameData memory) {
        bytes memory functionSelector = abi.encodePacked('frame_', uint16(frame).toString(), '()');

        bool success;
        bytes memory result;
        (success, result) = address(target).staticcall(abi.encodeWithSelector(bytes4(keccak256(functionSelector))));

        return abi.decode(result, (IFrameSVGs.FrameData));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IFrameSVGs.sol';

/// @dev Generate Frame SVG
interface IFrameGenerator {
    struct FrameSVGs {
        IFrameSVGs frameSVGs1;
        IFrameSVGs frameSVGs2;
    }

    /// @param Frame uint representing Frame selection
    /// @return FrameData containing svg snippet and Frame title and Frame type
    function generateFrame(uint16 Frame) external view returns (IFrameSVGs.FrameData memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IFrameSVGs {
    struct FrameData {
        string title;
        uint256 fee;
        string svgString;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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