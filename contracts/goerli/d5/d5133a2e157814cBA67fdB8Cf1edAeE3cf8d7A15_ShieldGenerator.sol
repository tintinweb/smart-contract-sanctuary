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

import './interfaces/IShieldGenerator.sol';
import './interfaces/IShieldSVGs.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @dev Generate Shield SVG
contract ShieldGenerator is IShieldGenerator {
    using Strings for uint16;

    mapping(uint24 => Color) public _colors;

    IShieldSVGs immutable shieldSVGs1;
    IShieldSVGs immutable shieldSVGs2;

    constructor(
        uint24[] memory __colors,
        string[] memory titles,
        IShieldSVGs _shieldSVGs1,
        IShieldSVGs _shieldSVGs2
    ) {
        require(__colors.length == titles.length, 'invalid array lengths');
        for (uint256 i = 0; i < __colors.length; i++) {
            _colors[__colors[i]] = Color({title: titles[i], exists: true});
            emit ColorAdded(__colors[i], titles[i]);
        }
        shieldSVGs1 = _shieldSVGs1;
        shieldSVGs2 = _shieldSVGs2;
    }

    function colorExists(uint24 color) public view returns (bool) {
        return _colors[color].exists;
    }

    function colorTitle(uint24 color) public view returns (string memory) {
        return _colors[color].title;
    }

    function generateShield(uint16 shield, uint24[4] memory colors)
        external
        view
        returns (IShieldSVGs.ShieldData memory)
    {
        if (shield <= 20) {
            return callShieldSVGs(shieldSVGs1, shield, colors);
        }

        if (shield <= 24) {
            return callShieldSVGs(shieldSVGs2, shield, colors);
        }

        revert('invalid shield selection');
    }

    function callShieldSVGs(
        IShieldSVGs target,
        uint16 shield,
        uint24[4] memory colors
    ) internal view returns (IShieldSVGs.ShieldData memory) {
        bytes memory functionSelector = abi.encodePacked('shield_', uint16(shield).toString(), '(uint24[4])');

        bool success;
        bytes memory result;
        (success, result) = address(target).staticcall(
            abi.encodeWithSelector(bytes4(keccak256(functionSelector)), colors)
        );

        return abi.decode(result, (IShieldSVGs.ShieldData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev Generate Shield SVG
interface IColors {
    event ColorAdded(uint24 color, string title);

    struct Color {
        string title;
        bool exists;
    }

    /// @notice Returns true if color exists in contract, else false.
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorExists(uint24 color) external view returns (bool);

    /// @notice Returns the title string corresponding to the 3-byte color
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorTitle(uint24 color) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IShieldSVGs.sol';
import './IColors.sol';

/// @dev Generate Shield SVG
interface IShieldGenerator {
    struct ShieldData {
        string title;
        string svgString;
    }

    /// @notice Generates shield snippet of SVG of the specified colors
    /// @param shield uint representing shield selection
    /// @param colors to be rendered in the shield svg
    /// @return ShieldData containing svg snippet and shield title
    function generateShield(uint16 shield, uint24[4] memory colors)
        external
        view
        returns (IShieldSVGs.ShieldData memory);

    event ColorAdded(uint24 color, string title);

    struct Color {
        string title;
        bool exists;
    }

    /// @notice Returns true if color exists in contract, else false.
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorExists(uint24 color) external view returns (bool);

    /// @notice Returns the title string corresponding to the 3-byte color
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorTitle(uint24 color) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev Generate Shield SVG
interface IShieldSVGs {
    struct ShieldData {
        string title;
        string svgType;
        string svgString;
    }
}