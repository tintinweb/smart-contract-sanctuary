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
pragma solidity ^0.8.9;

import './interfaces/IToolGenerator.sol';
import './interfaces/IToolSVGs.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @dev Generate Shield SVG
contract ToolGenerator is IToolGenerator {
    using Strings for uint16;

    IToolSVGs immutable toolSVGs1;
    IToolSVGs immutable toolSVGs2;
    IToolSVGs immutable toolSVGs3;

    constructor(
        IToolSVGs _toolSVGs1,
        IToolSVGs _toolSVGs2,
        IToolSVGs _toolSVGs3
    ) {
        toolSVGs1 = _toolSVGs1;
        toolSVGs2 = _toolSVGs2;
        toolSVGs3 = _toolSVGs3;
    }

    function generateTool(uint16 tool) external view returns (IToolSVGs.ToolData memory) {
        if (tool <= 0) {
            return callToolSVGs(toolSVGs1, tool);
        }

        if (tool <= 1) {
            return callToolSVGs(toolSVGs2, tool);
        }

        if (tool <= 2) {
            return callToolSVGs(toolSVGs3, tool);
        }

        revert('invalid tool selection');
    }

    function callToolSVGs(IToolSVGs target, uint16 tool) internal view returns (IToolSVGs.ToolData memory) {
        bytes memory functionSelector = abi.encodePacked('tool_', uint16(tool).toString(), '()');

        bool success;
        bytes memory result;
        (success, result) = address(target).staticcall(abi.encodeWithSelector(bytes4(keccak256(functionSelector))));

        return abi.decode(result, (IToolSVGs.ToolData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IToolSVGs.sol';

/// @dev Generate Shield SVG
interface IToolGenerator {
    /// @notice Generates tool snippet of SVG
    /// @param tool uint representing tool selection
    /// @return ToolData containing svg snippet and tool title and tool type
    function generateTool(uint16 tool) external view returns (IToolSVGs.ToolData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IToolSVGs {
    struct ToolData {
        string title;
        string toolType;
        string svgString;
    }
}