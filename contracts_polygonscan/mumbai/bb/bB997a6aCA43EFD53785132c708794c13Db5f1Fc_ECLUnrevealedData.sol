// contracts/ECLUnrevealedData.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MaticMikeLibrary.sol";
import "./IMaticMike.sol";
import "./IMikeData.sol";
import "./IECL.sol";

contract ECLUnrevealedData{
    // base64 structures
    struct Base{
        string styles;
        string background;
        string crowd;
    }

    Base encoded;
    // Addresses
    address _owner;
    address nullAddress = 0x0000000000000000000000000000000000000000;
    address mmAddress;
    address eclAddress;
    address dataAddress;

    constructor(){
        _owner = msg.sender;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        uint256 hoursLeft = (IECL(eclAddress).getHoursToReveal(_tokenId) / 60) / 60;
        uint16 mikeId = IECL(eclAddress).mintToMike(_tokenId);

        string memory metadataString;

        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type":"Hours Left","value":"',
                MaticMikeLibrary.toString(hoursLeft),
                '"},',
                '{"trait_type":"Matic Mike Staked","value":"#',
                MaticMikeLibrary.toString(mikeId),
                '"}'
            )
        );
        
        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory hoursLeft = MaticMikeLibrary.toString((IECL(eclAddress).getHoursToReveal(_tokenId) / 60) / 60);
        uint16 mikeId = IECL(eclAddress).mintToMike(_tokenId);

        // pull mike graphic to a base 64
        string memory mikeSvg = IData(dataAddress).hashToSVG(IMaticMike(mmAddress)._tokenIdToHash(mikeId), mikeId);

        string memory svgString;

        svgString = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="Club" viewBox="0 0 96 96" shape-rendering="crispedges">',
                encoded.styles,
                encoded.background,
                '<image x="36" y="39" width="24" height="24" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/svg+xml;base64,',
                mikeSvg,
                '"/>',
                encoded.crowd,
                '<svg width="96" height="18px" x="0" y="3"><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" style="font-size: 8px;fill: #fff;font-family: PixelFont;">',
                hoursLeft,
                ' Hours Remain</text></svg><svg width="96px" height="10px" x="0" y="75"><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" style="font-size: 8px;fill: #fff;font-family: PixelFont;">#',
                MaticMikeLibrary.toString(mikeId),
                '</text></svg><svg width="96px" height="10px" x="0" y="83"><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" style="font-size: 8px;fill: #fff;font-family: PixelFont;">On the stage!</text></svg></svg>'
            )
        );

        return MaticMikeLibrary.encode(bytes(svgString));
    }

    /*********************************
    *   Trait insertion functions
    **********************************/

    /**
     * @dev Add a styles, background, crowd
     * @param _styles styles sheet with encoded font
     * @param _background encoded base64 png
     * @param _crowd encoded base64 png
     */
    function addStylesAndBG(string memory _styles, string memory _background, string memory _crowd)
        public
        onlyOwner
    {
        encoded.styles = _styles;
        encoded.background = _background;
        encoded.crowd = _crowd;

        return;
    }
    
    function setECLAddress(address _address) public onlyOwner{
        eclAddress = _address;
    }
    
    function setMmAddress(address _address) public onlyOwner{
        mmAddress = _address;
    }

    function setMmDataAddress(address _address) public onlyOwner{
        dataAddress = _address;
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MaticMikeLibrary {

    // Originally Anonymice Library utilizing the same functions for encoding as well as generic toString/parseInt
    // We love anonymice.

    // Additional library will be added eventually for storing, drawing, and reading trait struct. This is to prevent
    // out of gas issues during the mapping of pixels to the grid.

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function getPercent(uint part, uint whole) internal pure returns(uint percent) {
        uint numerator = part * 1000;
        if(numerator > part && numerator > whole){
            uint temp = numerator / whole;
            return temp / 10;
        }
        else{
            return 0;
        }
        
    }

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
}

// contracts/IHgh.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IData {
    function hashToMetadata(string memory _hash, uint256 _tokenId) external view returns (string memory);
    function hashToSVG(string memory _hash, uint256 _tokenId) external view returns (string memory);
    function getPowerLevel(string memory _hash, uint256 _tokenId) external view returns (uint16);
}

// contracts/IMaticMike.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface IMaticMike is IERC721Enumerable {    
    function withdrawnTokens(uint256 tokenId) external view returns (bool);
    function getPowerLevel(uint256 tokenId) external view returns (uint16);
    function _tokenIdToHash(uint256 _tokenId) external view returns (string memory);
}

// contracts/IMaticMike.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IECL is IERC721Enumerable {    
    function getHoursToReveal(uint256 _tokenId) external view returns(uint256);
    function _tokenIdToHash(uint256 _tokenId) external view returns (string memory);
    function mintToMike(uint256 tokenId) external view returns (uint16);
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