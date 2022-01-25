// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './interfaces/IHardwareGenerator.sol';
import './interfaces/IHardwareSVGs.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @dev Generate Hardware SVG and properties
contract HardwareGenerator is IHardwareGenerator {
    using Strings for uint16;

    IHardwareSVGs immutable hardwareSVGs1;
    IHardwareSVGs immutable hardwareSVGs2;
    IHardwareSVGs immutable hardwareSVGs3;
    IHardwareSVGs immutable hardwareSVGs4;
    IHardwareSVGs immutable hardwareSVGs5;
    IHardwareSVGs immutable hardwareSVGs6;
    IHardwareSVGs immutable hardwareSVGs7;
    IHardwareSVGs immutable hardwareSVGs8;
    IHardwareSVGs immutable hardwareSVGs9;
    IHardwareSVGs immutable hardwareSVGs10;
    IHardwareSVGs immutable hardwareSVGs11;
    IHardwareSVGs immutable hardwareSVGs12;
    IHardwareSVGs immutable hardwareSVGs13;
    IHardwareSVGs immutable hardwareSVGs14;
    IHardwareSVGs immutable hardwareSVGs15;
    IHardwareSVGs immutable hardwareSVGs16;
    IHardwareSVGs immutable hardwareSVGs17;
    IHardwareSVGs immutable hardwareSVGs18;
    IHardwareSVGs immutable hardwareSVGs19;
    IHardwareSVGs immutable hardwareSVGs20;
    IHardwareSVGs immutable hardwareSVGs21;
    IHardwareSVGs immutable hardwareSVGs22;
    IHardwareSVGs immutable hardwareSVGs23;
    IHardwareSVGs immutable hardwareSVGs24;
    IHardwareSVGs immutable hardwareSVGs25;
    IHardwareSVGs immutable hardwareSVGs26;
    IHardwareSVGs immutable hardwareSVGs27;
    IHardwareSVGs immutable hardwareSVGs28;
    IHardwareSVGs immutable hardwareSVGs29;
    IHardwareSVGs immutable hardwareSVGs30;
    IHardwareSVGs immutable hardwareSVGs31;
    IHardwareSVGs immutable hardwareSVGs32;
    IHardwareSVGs immutable hardwareSVGs33;
    IHardwareSVGs immutable hardwareSVGs34;
    IHardwareSVGs immutable hardwareSVGs35;
    IHardwareSVGs immutable hardwareSVGs36;
    IHardwareSVGs immutable hardwareSVGs37;
    IHardwareSVGs immutable hardwareSVGs38;

    constructor(HardwareSVGs memory svgs) {
        hardwareSVGs1 = svgs.hardwareSVGs1;
        hardwareSVGs2 = svgs.hardwareSVGs2;
        hardwareSVGs3 = svgs.hardwareSVGs3;
        hardwareSVGs4 = svgs.hardwareSVGs4;
        hardwareSVGs5 = svgs.hardwareSVGs5;
        hardwareSVGs6 = svgs.hardwareSVGs6;
        hardwareSVGs7 = svgs.hardwareSVGs7;
        hardwareSVGs8 = svgs.hardwareSVGs8;
        hardwareSVGs9 = svgs.hardwareSVGs9;
        hardwareSVGs10 = svgs.hardwareSVGs10;
        hardwareSVGs11 = svgs.hardwareSVGs11;
        hardwareSVGs12 = svgs.hardwareSVGs12;
        hardwareSVGs13 = svgs.hardwareSVGs13;
        hardwareSVGs14 = svgs.hardwareSVGs14;
        hardwareSVGs15 = svgs.hardwareSVGs15;
        hardwareSVGs16 = svgs.hardwareSVGs16;
        hardwareSVGs17 = svgs.hardwareSVGs17;
        hardwareSVGs18 = svgs.hardwareSVGs18;
        hardwareSVGs19 = svgs.hardwareSVGs19;
        hardwareSVGs20 = svgs.hardwareSVGs20;
        hardwareSVGs21 = svgs.hardwareSVGs21;
        hardwareSVGs22 = svgs.hardwareSVGs22;
        hardwareSVGs23 = svgs.hardwareSVGs23;
        hardwareSVGs24 = svgs.hardwareSVGs24;
        hardwareSVGs25 = svgs.hardwareSVGs25;
        hardwareSVGs26 = svgs.hardwareSVGs26;
        hardwareSVGs27 = svgs.hardwareSVGs27;
        hardwareSVGs28 = svgs.hardwareSVGs28;
        hardwareSVGs29 = svgs.hardwareSVGs29;
        hardwareSVGs30 = svgs.hardwareSVGs30;
        hardwareSVGs31 = svgs.hardwareSVGs31;
        hardwareSVGs32 = svgs.hardwareSVGs32;
        hardwareSVGs33 = svgs.hardwareSVGs33;
        hardwareSVGs34 = svgs.hardwareSVGs34;
        hardwareSVGs35 = svgs.hardwareSVGs35;
        hardwareSVGs36 = svgs.hardwareSVGs36;
        hardwareSVGs37 = svgs.hardwareSVGs37;
        hardwareSVGs38 = svgs.hardwareSVGs38;
    }

    function callHardwareSVGs(IHardwareSVGs target, uint16 hardware)
        internal
        view
        returns (IHardwareSVGs.HardwareData memory)
    {
        bytes memory functionSelector = abi.encodePacked('hardware_', uint16(hardware).toString(), '()');

        bool success;
        bytes memory result;
        (success, result) = address(target).staticcall(abi.encodeWithSelector(bytes4(keccak256(functionSelector))));

        return abi.decode(result, (IHardwareSVGs.HardwareData));
    }

    function generateHardware(uint16 hardware) external view override returns (IHardwareSVGs.HardwareData memory) {
        if (hardware <= 5) {
            return callHardwareSVGs(hardwareSVGs1, hardware);
        }

        if (hardware <= 9) {
            return callHardwareSVGs(hardwareSVGs2, hardware);
        }

        if (hardware <= 14) {
            return callHardwareSVGs(hardwareSVGs3, hardware);
        }

        if (hardware <= 18) {
            return callHardwareSVGs(hardwareSVGs4, hardware);
        }

        if (hardware <= 22) {
            return callHardwareSVGs(hardwareSVGs5, hardware);
        }

        if (hardware <= 25) {
            return callHardwareSVGs(hardwareSVGs6, hardware);
        }

        if (hardware <= 29) {
            return callHardwareSVGs(hardwareSVGs7, hardware);
        }

        if (hardware <= 33) {
            return callHardwareSVGs(hardwareSVGs8, hardware);
        }

        if (hardware <= 37) {
            return callHardwareSVGs(hardwareSVGs9, hardware);
        }

        if (hardware <= 41) {
            return callHardwareSVGs(hardwareSVGs10, hardware);
        }

        if (hardware <= 44) {
            return callHardwareSVGs(hardwareSVGs11, hardware);
        }

        if (hardware <= 47) {
            return callHardwareSVGs(hardwareSVGs12, hardware);
        }

        if (hardware <= 51) {
            return callHardwareSVGs(hardwareSVGs13, hardware);
        }

        if (hardware <= 56) {
            return callHardwareSVGs(hardwareSVGs14, hardware);
        }

        if (hardware <= 60) {
            return callHardwareSVGs(hardwareSVGs15, hardware);
        }

        if (hardware <= 63) {
            return callHardwareSVGs(hardwareSVGs16, hardware);
        }

        if (hardware <= 68) {
            return callHardwareSVGs(hardwareSVGs17, hardware);
        }

        if (hardware <= 72) {
            return callHardwareSVGs(hardwareSVGs18, hardware);
        }

        if (hardware <= 75) {
            return callHardwareSVGs(hardwareSVGs19, hardware);
        }

        if (hardware <= 77) {
            return callHardwareSVGs(hardwareSVGs20, hardware);
        }

        if (hardware <= 79) {
            return callHardwareSVGs(hardwareSVGs21, hardware);
        }

        if (hardware <= 82) {
            return callHardwareSVGs(hardwareSVGs22, hardware);
        }

        if (hardware <= 84) {
            return callHardwareSVGs(hardwareSVGs23, hardware);
        }

        if (hardware <= 86) {
            return callHardwareSVGs(hardwareSVGs24, hardware);
        }

        if (hardware <= 88) {
            return callHardwareSVGs(hardwareSVGs25, hardware);
        }

        if (hardware <= 90) {
            return callHardwareSVGs(hardwareSVGs26, hardware);
        }

        if (hardware <= 92) {
            return callHardwareSVGs(hardwareSVGs27, hardware);
        }

        if (hardware <= 95) {
            return callHardwareSVGs(hardwareSVGs28, hardware);
        }

        if (hardware <= 97) {
            return callHardwareSVGs(hardwareSVGs29, hardware);
        }

        if (hardware <= 99) {
            return callHardwareSVGs(hardwareSVGs30, hardware);
        }

        if (hardware <= 101) {
            return callHardwareSVGs(hardwareSVGs31, hardware);
        }

        if (hardware <= 103) {
            return callHardwareSVGs(hardwareSVGs32, hardware);
        }

        if (hardware <= 106) {
            return callHardwareSVGs(hardwareSVGs33, hardware);
        }

        if (hardware <= 111) {
            return callHardwareSVGs(hardwareSVGs34, hardware);
        }

        if (hardware <= 113) {
            return callHardwareSVGs(hardwareSVGs35, hardware);
        }

        if (hardware <= 115) {
            return callHardwareSVGs(hardwareSVGs36, hardware);
        }

        if (hardware <= 117) {
            return callHardwareSVGs(hardwareSVGs37, hardware);
        }

        if (hardware <= 120) {
            return callHardwareSVGs(hardwareSVGs38, hardware);
        }

        revert('invalid hardware selection');
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IHardwareSVGs.sol';

/// @dev Generate Hardware SVG
interface IHardwareGenerator {

    /// @param hardware uint representing hardware selection
    /// @return HardwareData containing svg snippet and hardware title and hardware type
    function generateHardware(uint16 hardware) external view returns (IHardwareSVGs.HardwareData memory);

    struct HardwareSVGs {
        IHardwareSVGs hardwareSVGs1;
        IHardwareSVGs hardwareSVGs2;
        IHardwareSVGs hardwareSVGs3;
        IHardwareSVGs hardwareSVGs4;
        IHardwareSVGs hardwareSVGs5;
        IHardwareSVGs hardwareSVGs6;
        IHardwareSVGs hardwareSVGs7;
        IHardwareSVGs hardwareSVGs8;
        IHardwareSVGs hardwareSVGs9;
        IHardwareSVGs hardwareSVGs10;
        IHardwareSVGs hardwareSVGs11;
        IHardwareSVGs hardwareSVGs12;
        IHardwareSVGs hardwareSVGs13;
        IHardwareSVGs hardwareSVGs14;
        IHardwareSVGs hardwareSVGs15;
        IHardwareSVGs hardwareSVGs16;
        IHardwareSVGs hardwareSVGs17;
        IHardwareSVGs hardwareSVGs18;
        IHardwareSVGs hardwareSVGs19;
        IHardwareSVGs hardwareSVGs20;
        IHardwareSVGs hardwareSVGs21;
        IHardwareSVGs hardwareSVGs22;
        IHardwareSVGs hardwareSVGs23;
        IHardwareSVGs hardwareSVGs24;
        IHardwareSVGs hardwareSVGs25;
        IHardwareSVGs hardwareSVGs26;
        IHardwareSVGs hardwareSVGs27;
        IHardwareSVGs hardwareSVGs28;
        IHardwareSVGs hardwareSVGs29;
        IHardwareSVGs hardwareSVGs30;
        IHardwareSVGs hardwareSVGs31;
        IHardwareSVGs hardwareSVGs32;
        IHardwareSVGs hardwareSVGs33;
        IHardwareSVGs hardwareSVGs34;
        IHardwareSVGs hardwareSVGs35;
        IHardwareSVGs hardwareSVGs36;
        IHardwareSVGs hardwareSVGs37;
        IHardwareSVGs hardwareSVGs38;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}