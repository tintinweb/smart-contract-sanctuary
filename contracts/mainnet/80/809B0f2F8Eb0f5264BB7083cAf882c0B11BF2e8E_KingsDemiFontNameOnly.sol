// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Sacramento Kings
/// @author: manifold.xyz

import "./fonts/IFontWOFF.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * Kings Demi (only letters ACEGIKMNORST)
 */
contract KingsDemiFontNameOnly is IFontWOFF, ERC165 {

    string private _woff;

    constructor() {
        _woff = "data:application/font-woff;charset=utf-8;base64,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";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IFontWOFF).interfaceId || super.supportsInterface(interfaceId);
    }

    function woff() public view override returns(string memory) {
        return _woff;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Font interface
 */
interface IFontWOFF {
    function woff() external view returns(string memory);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 25
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