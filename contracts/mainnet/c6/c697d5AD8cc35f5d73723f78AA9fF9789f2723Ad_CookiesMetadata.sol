// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libraries/Base64.sol";

import "./IRenderingFortunes.sol";
import "./I_TokenData.sol";

import "./Controllable.sol";

contract CookiesMetadata is Ownable, Controllable, I_TokenData {

    using Strings for uint256;

    uint256 constant MAX_SUPPLY = 20000;
    string constant HEADER = '<svg class="svgBody" width="640" height="640" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg" version="1.1">';
    uint256 indexOffset; //set this for reveal

    IRenderingFortunes public renderer;

    mapping (uint256 => uint32) revealTimestamps;

    string unrevealed_uri = "data:image/svg+xml;base64,PHN2ZyBpZD0iQ3J5cHRvQ29va2llcyIgdmlld0JveD0iMCAwIDIwMCAyMDAiIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHZlcnNpb249IjEuMSIgPjxpbWFnZSB4PSIwIiB5PSIwIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgaW1hZ2UtcmVuZGVyaW5nPSJwaXhlbGF0ZWQiIHByZXNlcnZlQXNwZWN0UmF0aW89InhNaWRZTWlkIiB4bGluazpocmVmPSJkYXRhOmltYWdlL3BuZztiYXNlNjQsaVZCT1J3MEtHZ29BQUFBTlNVaEVVZ0FBQU1nQUFBRElCQU1BQUFCZmRyT3RBQUFBRlZCTVZFWC94SHYvdDFYLzU4ci8vZjc0a2loVkxRQ2NkVHFVNGxMTUFBQUQ4RWxFUVZSNEFlM2JSN0xjUmhBRVVJQm1qNExBQTNUTjM5TzBxRDJnUGdEZDZBQXk5NytDeG1Xb1lrQ2dma1JXdDl6a2l2YS95T3p4cHRNRytYOGdEK1NCSEhMbUVkL0lIM2pFTlhqRU4wN2hFZDhncXZnSWpLcEl6Z2lQdUFaUnhVT3lUU1hrMEFMSndZaGZKSCtvZ3VTNzFHL0NJL1JlQktMeGlGK0ZRQnlsUHFMK1hnSElJUnJ4cTlSQ0RzMlJENVVRWFNOSmJobWpIMGdBa2J2RUl6bkpLbU1Fb3NibzVYdUpSV1FqTEdMMmVpZWJHYU9ROXlLZVFpRHE5WURDSTRKMGlOaE1FWWdSVEhwQkZnTEJvZlRXc0VHUkFPVDlsb0VxaFVmZWJSbG9NZ1VnbXdhYWxLSWNnbHZkWWE4SWoyd2FRQXFMb0VoSElGeVJIc1pDSWdsR1RXUm5yQTRHaTZSbklTT0g3Qms5aktJVWtuWU1GS0VSMlVWZ0xBU0NpNWF6Rm92QTJDOVNsRVk2cHdpTEpBK1pMc2JzSS94YUM0c01lMFVLaVdDdHppOVNsRURjWXk5QnlPQVhLUXVESks5SUVESXdhd0ZoMXBwdXhzd2kvRnBBbkxVY280d3RFQ1VRck9XY1NGa294Qy9DSTFqTE1ZcVNpSE5sUnhFVzhZdU1CSUlqOFlvVXBSRy95TUlpenlreThvaHJGS1dRSk1QT293ZGtvUkdpQ0lXSVc0UkgrbFVSRGhIeGk4dzFFSEdMOElqNFJYaWtoK0ZjRWZtNUpsdUVSd1pIMFFqRXViNHZQSkpFL0VmWlBPTGNySXdWRVF5MmFDMEVpblBKWWhFODV0SW94Sno4NitNblcwVkdqVzl5UE1kV2tmZ21yeS9JSjZ1TUZaQmY4aDkzZzRVangrUFgvQkY3MmNGNDVIWW9PWCs4SXM3Wjg4aHBMb09nQ28zb0RYbVpjejVlQThSVzRSRlpJMWFwak5qQmVBUm5ZaEU3R0kvZ1VMb2IwdDBqRW9hY3NrWlFoVVVTOXJJM0t6WmhpSzNTclJFSlJIQlR2N2NYZ1VpM0UxUWhFSFVSVktHUmdhL2lJMjZWRU1Tck1uSklrcUNqSjVFK0Noa2NaS1FRbFpBcVBvSXFyKzBWSHI5RkZRcEpmMVU1ZGpibWxpd01FWXZnUnZrVEVCRUtVU0RER2Zsa2l2ejJFNnBnTHg2UkUvTDZhSXJrakNxQmlPQVVLaUJKa0RmWEh3cmtOSmRCaEVKVVRCZHpKTmZBY0t1UWlFZ0FrZ3dpM2FjN3BCZUVRZTZPL29hOHZocWZZTkRJYkk5ZVpMQ0kyWEtra0NkWlpianQxWWNoQ1ZWc3JvaUVJVHJKT20vT3htZXg0WkJVMXNnUE9hTUhpNkRLL0Qza2ZleG43cDVLQXlTVnVTcUNLck9QQ0lta3Nob3Nad2xHZElMQ2ZnN1NxVEpYUi9USlYzaEVpNi93eUpPdkNJM281Q3M4a3NvNU5PSVA1cFFaU1FTRG5jSWovbUFvUXlHK3NsR25sTUlqVmpHTm5BL0lPSWl2SUw0QmhGWmdNQWlVcVp5U1RWNWRqVkdqRUZ5U1h4cmtSK0pqUHR1UlVuNitRMllOUkZER0loazF3aERFSXFyL0ZlVERBM0VSbXdjUytaMjlCM0w0anlMNVg0emtGb2cyUWJRSmNtaUJRT0VSWCtFUlg2bVBhQk5FbXlEYUJORW15S0UrQW9WSGZJVkhmS1VGb2swUWJZSWNXaUQ2UUI3SWZ4NzVFeEkxbExleFduM2JBQUFBQUVsRlRrU3VRbUNDIi8+PC9zdmc+";

    bool revealStarted;

    constructor (address rendererAddress) {
        renderer = IRenderingFortunes(rendererAddress);
        SetProvenance();
        controllers[owner()] = true;
    }

    function SetRenderers(address newRenderer) external onlyOwner {
        renderer = IRenderingFortunes(newRenderer);
    }

    function SetProvenance() internal {
        require(indexOffset == 0,"Index already set");

        unchecked {
            uint256 n = uint256(blockhash(block.number - 1));
            if (n == 0)
            {
                n = 7; //if block hash is unavailable for some inexplicable reason
            }

            indexOffset = n % MAX_SUPPLY;
        }

    }

    function setRevealStarted(bool isRevealed) external onlyOwner() {
        revealStarted = isRevealed;
    }

    //offset by amount set using blockhash. This is a bit of fun.
    function getTokenGene(uint256 tokenID) internal view returns (uint256) {
        return (tokenID + indexOffset) % MAX_SUPPLY;
    }

    function setRevealTimestamp(uint256 tokenID, uint32 newTimestamp) external {
        require(controllers[msg.sender] || msg.sender == owner(),"Not Authorized to set timestamp");
        revealTimestamps[tokenID] = newTimestamp;
    }

    function getRevealTimestamp(uint256 tokenID) external view returns (uint32) {
        return revealTimestamps[tokenID];
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory)
    {
        uint256 tokenGene = getTokenGene(tokenID);
        uint32 revealTime = revealTimestamps[tokenID];

        if (block.timestamp < revealTime || revealTime == 0 || !revealStarted) //unrevealed
        {
            string memory json = Base64.encode(
                            bytes(
                                string(
                                    abi.encodePacked(
                                        '{"name":"Cookie #',Strings.toString(tokenID), '",',
                                        '"description": "Your cookie will open and reveal itself after 24 hours.",',
                                        '"image": "',unrevealed_uri,'",',
                                        '"RevealTime":"',Strings.toString(revealTime),'",',
                                        '"attributes": [ ',
                                            '{"trait_type":"Status","value":"Hidden"}', //',',
                                        ']}'
                                    )
                                )
                            )
                        );

            return string(abi.encodePacked("data:application/json;base64,", json));
        }
        else
        {
            //text is based on simple PRNG of tokenID. Tokens don't have rarity traits. 
            string memory imageURI = getFullEncodedSVG(getImageURI(tokenGene));
            string memory luckynumber1 = Strings.toString(1+(((tokenGene + 888) * 193939) % 1000));
            string memory json = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"name":"Cookie #',Strings.toString(tokenID), '",',
                            '"description": "\\\"',renderer.getFullLine(tokenGene), '\\\"",',
                            '"image": "data:image/svg+xml;base64,',imageURI, '",',
                            '"attributes": [ ',
                                '{"trait_type": "Lucky Number", "value": "',luckynumber1, '", "display_type": "number"}', //',',
                            ']}'
                        )
                    )
                )
            );
            
            return string(abi.encodePacked("data:application/json;base64,", json));

        }

    }

    //string constant bg1 = '<defs><pattern id="bg1" width="24" height="24" x="32" y="16" patternUnits="userSpaceOnUse"><polygon opacity="0.15" fill-rule="evenodd" points="8 4 12 6 8 8 6 12 4 8 0 6 4 4 6 0 8 4"/></pattern></defs><rect x="0" y="0" width="640" height="640" rx="32" style="fill: url(#bg1);"/>';

    function getImageURI(uint256 genes) internal view returns (string memory)
    {
        string memory txt = "";

        if (genes % 2 == 0){
            txt = renderer.renderText([renderer.getLine1_A(genes),renderer.getLine2_A(genes),renderer.getLine3_A(genes)]);
        } else{
            txt = renderer.renderText([renderer.getLine1_B(genes),renderer.getLine2_B(genes),renderer.getLine3_B(genes)]);
        }

        uint256 k = uint256(keccak256(abi.encodePacked(genes)));
        uint256 r = k % 256;
        uint256 g = k / 10000000 % 256;
        uint256 b = k / 100000 % 256;

        return string(abi.encodePacked('<rect x="0" y="0" width="640" height="640" style="fill:rgb(',r.toString(),',',g.toString(),',',b.toString(),');" />',
                        // bg1,
                        txt,
                        "</svg>"));
    }

    function getFullEncodedSVG(string memory toWrap) internal pure returns (string memory) {
        toWrap = string(abi.encodePacked(HEADER,toWrap));
        return Base64.encode(
            bytes(
                toWrap
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
pragma solidity ^0.8.7;

interface IRenderingFortunes {
    function getImageURI(uint256, string memory) external pure returns (string memory);
    function getFullLine(uint256) external pure returns (string memory);
    function renderText(string[3] memory) external view returns (string memory);
    function getLine1_A(uint256) external view returns (string memory);
    function getLine2_A(uint256) external view returns (string memory);
    function getLine3_A(uint256) external view returns (string memory);
    function getLine1_B(uint256) external view returns (string memory);
    function getLine2_B(uint256) external view returns (string memory);
    function getLine3_B(uint256) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface I_TokenData
{
    function tokenURI(uint256 tokenID) external view returns (string memory);
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {

    mapping(address => bool) controllers;

    function addControllers(address[] calldata newControllers) external onlyOwner {
        for (uint i=0; i < newControllers.length; i++) {
            controllers[newControllers[i]] = true;
        }
    }

    function removeController(address toDelete) external onlyOwner {
        controllers[toDelete] = false;
    }

    function addController(address newController) external onlyOwner
    {
        controllers[newController] = true;
    }

    modifier onlyControllers() {
        require(controllers[msg.sender], "Not Authorized");
        _;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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